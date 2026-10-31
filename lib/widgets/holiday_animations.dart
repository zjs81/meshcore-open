import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/holiday_triggers.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';

/// How long each holiday animation runs.
Duration holidayAnimationDuration(HolidayAnimation animation) =>
    switch (animation) {
      HolidayAnimation.halloween => const Duration(milliseconds: 4200),
      HolidayAnimation.thanksgiving => const Duration(milliseconds: 4800),
      HolidayAnimation.christmas => const Duration(milliseconds: 5200),
      HolidayAnimation.newYear => const Duration(milliseconds: 5600),
    };

/// Plays [animation] over the whole screen, starting from [origin] (global
/// coordinates of the message it came from). Touches pass through, and the
/// overlay removes itself when done.
///
/// Skipped when the user turned holiday animations off or the platform asks
/// for reduced motion.
void playHolidayAnimation(
  BuildContext context,
  HolidayAnimation animation, {
  required Offset origin,
}) {
  final settings = context.read<AppSettingsService>().settings;
  if (!settings.holidayAnimationsEnabled) return;
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => HolidayAnimationView(
      animation: animation,
      origin: origin,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// Watches a chat's newest message and plays its holiday animation when a
/// new triggering message arrives. Messages already there when the chat
/// opens never play, and each message plays at most once.
class HolidayTriggerWatcher {
  String? _newestId;
  bool _primed = false;

  /// Messages older than this when first seen (e.g. synced backlog) stay
  /// quiet.
  static const freshness = Duration(minutes: 2);

  /// Call on every build with the chat's newest message. [originOf] gives
  /// the global point the animation starts from, once the frame is laid
  /// out.
  void onNewest(
    BuildContext context, {
    required String? id,
    required Iterable<String?> texts,
    required DateTime? receivedAt,
    required Offset? Function() originOf,
  }) {
    if (!_primed) {
      _primed = true;
      _newestId = id;
      return;
    }
    if (id == null || id == _newestId) return;
    _newestId = id;
    if (receivedAt == null ||
        DateTime.now().difference(receivedAt).abs() > freshness) {
      return;
    }
    HolidayAnimation? animation;
    for (final text in texts) {
      if (text == null) continue;
      animation = holidayAnimationFor(text);
      if (animation != null) break;
    }
    if (animation == null) return;
    final found = animation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final origin = originOf();
      if (origin == null) return;
      playHolidayAnimation(context, found, origin: origin);
    });
    // Normally called mid-build, but make sure a frame follows either way.
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

/// The global point a chat's newest message sits at: the bottom of the
/// message list, on the sender's side.
Offset? newestMessageOrigin(GlobalKey listKey, {required bool isOutgoing}) {
  final box = listKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final local = Offset(
    isOutgoing ? box.size.width - 72 : 72,
    box.size.height - 48,
  );
  return box.localToGlobal(local);
}

class HolidayAnimationView extends StatefulWidget {
  final HolidayAnimation animation;
  final Offset origin;
  final VoidCallback onDone;

  const HolidayAnimationView({
    super.key,
    required this.animation,
    required this.origin,
    required this.onDone,
  });

  @override
  State<HolidayAnimationView> createState() => _HolidayAnimationViewState();
}

class _HolidayAnimationViewState extends State<HolidayAnimationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: holidayAnimationDuration(widget.animation),
  );
  // Fixed seed per play keeps a run smooth; a new seed each play keeps it
  // from looking canned.
  late final int _seed = DateTime.now().microsecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The overlay sits above the app's Material, so without one of its own
    // every emoji Text gets Flutter's yellow "missing Material" underline.
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              // Played in the root overlay, which covers the whole screen
              // from its top-left, so global coordinates are local ones.
              // (Converting here would read parents not yet laid out.)
              final origin = Offset(
                widget.origin.dx.clamp(0, size.width).toDouble(),
                widget.origin.dy.clamp(0, size.height).toDouble(),
              );
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  return switch (widget.animation) {
                    HolidayAnimation.halloween => _Bats(
                      t: t,
                      size: size,
                      origin: origin,
                      seed: _seed,
                    ),
                    HolidayAnimation.thanksgiving => _Turkey(
                      t: t,
                      size: size,
                      seed: _seed,
                    ),
                    HolidayAnimation.christmas => _Santa(
                      t: t,
                      size: size,
                      seed: _seed,
                    ),
                    HolidayAnimation.newYear => CustomPaint(
                      size: size,
                      painter: _FireworksPainter(t: t, seed: _seed),
                    ),
                  };
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// An emoji glyph placed by its center.
Widget _sprite(
  String emoji, {
  required Offset at,
  required double size,
  double opacity = 1,
  double rotation = 0,
  bool flip = false,
  double scaleY = 1,
}) {
  return Positioned(
    left: at.dx - size / 2,
    top: at.dy - size / 2,
    child: Opacity(
      opacity: opacity.clamp(0, 1).toDouble(),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(rotation)
          ..scaleByDouble(flip ? -1.0 : 1.0, scaleY, 1, 1),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              emoji,
              style: MeshTheme.emoji(fontSize: size * 0.8),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Drops sprites that are invisible or entirely off-screen (e.g. the sleigh
/// before it flies in), and empty placeholders, so each frame only lays out
/// what can be seen.
List<Widget> _onScreen(Size size, List<Widget> children) {
  const margin = 160.0;
  bool hidden(Widget child) {
    if (child is! Positioned) return child is SizedBox && child.width == 0;
    final left = child.left, top = child.top;
    if (left != null &&
        top != null &&
        (left > size.width + margin ||
            top > size.height + margin ||
            left < -margin * 2 ||
            top < -margin * 2)) {
      return true;
    }
    final inner = child.child;
    return inner is Opacity && inner.opacity <= 0;
  }

  return [
    for (final child in children)
      if (!hidden(child)) child,
  ];
}

double _fadeOut(double t, {double from = 0.75}) =>
    t < from ? 1 : 1 - (t - from) / (1 - from);

/// 0 → 1 → 0 over the run: in quickly, hold, out slowly.
double _envelope(double t, {double rise = 0.12, double fall = 0.3}) {
  if (t < rise) return t / rise;
  if (t > 1 - fall) return (1 - t) / fall;
  return 1;
}

/// Full-screen wash of [color], e.g. Halloween dusk or a firework flash.
Widget _wash(Color color, double opacity) => Positioned.fill(
  child: ColoredBox(color: color.withValues(alpha: opacity.clamp(0, 1))),
);

/// Halloween: the screen dims to a purple dusk and a swarm of bats bursts
/// out of the message, flapping off in every direction.
class _Bats extends StatelessWidget {
  final double t;
  final Size size;
  final Offset origin;
  final int seed;

  const _Bats({
    required this.t,
    required this.size,
    required this.origin,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    final rand = math.Random(seed);
    final reach = size.longestSide * 1.3;
    final dusk = _envelope(t, rise: 0.1, fall: 0.35);
    // Expand: the scene must fill the screen whatever its children are
    // (a lone zero-size child would otherwise shrink it to nothing).
    return Stack(
      fit: StackFit.expand,
      children: _onScreen(size, [
        _wash(const Color(0xFF14002A), 0.45 * dusk),
        // A moon peeks in at the top corner.
        _sprite(
          '🌕',
          at: Offset(size.width - 70, 90 - (1 - dusk) * 60),
          size: 110,
          opacity: 0.9 * dusk,
        ),
        for (var i = 0; i < 46; i++)
          () {
            // Mostly upward, but the swarm fans out wide.
            final angle =
                -math.pi / 2 + (rand.nextDouble() - 0.5) * math.pi * 1.6;
            final speed = 0.5 + rand.nextDouble() * 0.8;
            final delay = rand.nextDouble() * 0.35;
            final wobble = 20 + rand.nextDouble() * 40;
            final phase = rand.nextDouble() * math.pi * 2;
            final batSize = 34 + rand.nextDouble() * 46;
            final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
            final eased = Curves.easeIn.transform(local);
            final distance = eased * reach * speed;
            final dir = Offset(math.cos(angle), math.sin(angle));
            final side = Offset(-dir.dy, dir.dx);
            final at =
                origin +
                dir * distance +
                side * math.sin(local * 14 + phase) * wobble;
            return _sprite(
              '🦇',
              at: at,
              size: batSize * (0.4 + 0.6 * math.min(1, local * 5)),
              opacity: local == 0 ? 0 : _fadeOut(local, from: 0.75),
              // Wing beat.
              scaleY: 0.55 + 0.45 * math.sin(local * 46 + phase).abs(),
              flip: dir.dx < 0,
            );
          }(),
      ]),
    );
  }
}

/// Thanksgiving: a stampede of turkeys hops across the screen in a storm of
/// autumn leaves.
class _Turkey extends StatelessWidget {
  final double t;
  final Size size;
  final int seed;

  const _Turkey({required this.t, required this.size, required this.seed});

  @override
  Widget build(BuildContext context) {
    final rand = math.Random(seed);
    final warm = _envelope(t, rise: 0.1, fall: 0.3);
    // (size, lane as a fraction of height, lag behind the leader, hop phase)
    const flock = [
      (130.0, 0.70, 0.00, 0.0),
      (86.0, 0.56, 0.10, 1.3),
      (96.0, 0.84, 0.17, 2.1),
      (70.0, 0.46, 0.26, 0.7),
    ];
    final span = size.width + 320;
    // Expand: the scene must fill the screen whatever its children are
    // (a lone zero-size child would otherwise shrink it to nothing).
    return Stack(
      fit: StackFit.expand,
      children: _onScreen(size, [
        _wash(const Color(0xFF5A2A00), 0.22 * warm),
        for (var i = 0; i < 44; i++)
          () {
            final startX = rand.nextDouble() * size.width * 1.2;
            final delay = rand.nextDouble() * 0.45;
            final fall = 0.5 + rand.nextDouble() * 0.6;
            final sway = 24 + rand.nextDouble() * 50;
            final leaf = ['🍂', '🍁', '🍂', '🌾'][rand.nextInt(4)];
            final leafSize = 26 + rand.nextDouble() * 26;
            final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
            return _sprite(
              leaf,
              at: Offset(
                startX + math.sin(local * 9 + i) * sway - local * 120,
                -40 + local * size.height * fall * 1.5,
              ),
              size: leafSize,
              rotation: local * 8 + i,
              opacity: local == 0 ? 0 : _fadeOut(local),
            );
          }(),
        for (final (turkeySize, lane, lag, phase) in flock)
          ...() {
            final p = ((t - lag) / (1 - lag)).clamp(0.0, 1.0);
            // Emoji turkeys face left, so they run right to left.
            final x = size.width + 160 - p * span;
            final ground = size.height * lane;
            final stride = math.sin(p * math.pi * 16 + phase).abs();
            return [
              for (var d = 1; d <= 3; d++)
                _sprite(
                  '💨',
                  at: Offset(
                    x + turkeySize * 0.55 + d * turkeySize * 0.3,
                    ground + turkeySize * 0.3,
                  ),
                  size: turkeySize * (0.42 - d * 0.08),
                  opacity: p == 0 ? 0 : (0.8 - d * 0.2) * stride,
                ),
              _sprite(
                '🦃',
                at: Offset(x, ground - stride * turkeySize * 0.32),
                size: turkeySize,
                rotation: math.sin(p * math.pi * 16 + phase) * 0.12,
              ),
            ];
          }(),
      ]),
    );
  }
}

/// Christmas: a blizzard rolls in while Santa's sleigh and a team of
/// reindeer swoop across the sky, trailing sparkles and dropping presents.
class _Santa extends StatelessWidget {
  final double t;
  final Size size;
  final int seed;

  const _Santa({required this.t, required this.size, required this.seed});

  static const _spacing = 58.0;
  static const _team = 4;

  Offset _sleighAt(double p) {
    // Right to left (emoji reindeer face left), swooping low then up.
    final x = size.width + 360 - p * (size.width + 760);
    final y =
        size.height * 0.34 -
        math.sin(p * math.pi) * size.height * 0.2 +
        math.sin(p * math.pi * 3) * 18;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final rand = math.Random(seed);
    final p = Curves.easeInOut.transform(t);
    final head = _sleighAt(p);
    final sleighOffset = Offset((_team + 0.7) * _spacing, 12);
    final night = _envelope(t, rise: 0.12, fall: 0.3);
    // Expand: the scene must fill the screen whatever its children are
    // (a lone zero-size child would otherwise shrink it to nothing).
    return Stack(
      fit: StackFit.expand,
      children: _onScreen(size, [
        _wash(const Color(0xFF02142E), 0.4 * night),
        for (var i = 0; i < 60; i++)
          () {
            final x = rand.nextDouble() * size.width * 1.3;
            final delay = rand.nextDouble() * 0.5;
            final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
            return _sprite(
              '❄️',
              at: Offset(
                x + math.sin(local * 7 + i) * 26 - local * 140,
                -30 + local * size.height * 1.1,
              ),
              size: 14 + rand.nextDouble() * 22,
              rotation: local * 4 + i,
              opacity: local == 0 ? 0 : 0.95 * _fadeOut(local),
            );
          }(),
        // Sparkle trail where the sleigh just was.
        for (var i = 1; i <= 26; i++)
          () {
            final back = (p - i * 0.018).clamp(0.0, 1.0);
            final at =
                _sleighAt(back) +
                sleighOffset +
                Offset(20, 8 + math.sin(i * 1.7) * 14 + i * 2.5);
            return _sprite(
              i.isEven ? '✨' : '⭐',
              at: at,
              size: 30 - i * 0.8,
              opacity: (1 - i / 27) * _fadeOut(t, from: 0.85),
              rotation: i * 0.6 + t * 6,
            );
          }(),
        // Presents tumbling out behind the sleigh.
        for (var g = 0; g < 5; g++)
          () {
            final drop = 0.18 + g * 0.13;
            final local = ((p - drop) / 0.35).clamp(0.0, 1.0);
            if (local == 0) return const SizedBox.shrink();
            final from = _sleighAt(drop) + sleighOffset;
            return _sprite(
              '🎁',
              at: from + Offset(local * 40, local * local * size.height * 0.7),
              size: 40,
              rotation: local * 5 * (g.isEven ? 1 : -1),
              opacity: _fadeOut(local, from: 0.7),
            );
          }(),
        for (var i = 0; i < _team; i++)
          _sprite(
            '🦌',
            at: head + Offset(i * _spacing, math.sin(t * 36 + i * 0.9) * 6),
            size: 62,
          ),
        _sprite('🛷', at: head + sleighOffset, size: 80),
        _sprite('🎅', at: head + sleighOffset + const Offset(4, -30), size: 60),
      ]),
    );
  }
}

/// New Year: a barrage of rockets bursts into big double rings of colored
/// sparks that crackle, with the screen flashing on each burst.
class _FireworksPainter extends CustomPainter {
  final double t;
  final int seed;

  _FireworksPainter({required this.t, required this.seed});

  static const _colors = [
    Color(0xFFFFD54F),
    Color(0xFFFF5252),
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFFF80AB),
    Color(0xFFE040FB),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    const bursts = 16;
    const rise = 0.12;
    const life = 0.36;

    // Night sky behind the show.
    final sky = _envelope(t, rise: 0.08, fall: 0.25);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000814).withValues(alpha: 0.5 * sky),
    );

    var flash = 0.0;
    for (var b = 0; b < bursts; b++) {
      final start = b * 0.038 + rand.nextDouble() * 0.04;
      final target = Offset(
        size.width * (0.08 + rand.nextDouble() * 0.84),
        size.height * (0.08 + rand.nextDouble() * 0.5),
      );
      final launch = Offset(
        target.dx + (rand.nextDouble() - 0.5) * 120,
        size.height + 10,
      );
      final color = _colors[rand.nextInt(_colors.length)];
      final inner = _colors[rand.nextInt(_colors.length)];
      final radius = 110 + rand.nextDouble() * 110;
      final sparks = 48 + rand.nextInt(24);
      final angles = [
        for (var i = 0; i < sparks; i++)
          i / sparks * math.pi * 2 + rand.nextDouble() * 0.15,
      ];
      final glitter = [
        for (var i = 0; i < 24; i++)
          (rand.nextDouble() * math.pi * 2, rand.nextDouble()),
      ];
      final local = t - start;
      if (local < 0) continue;

      if (local < rise) {
        final p = Curves.easeOut.transform(local / rise);
        final at = Offset.lerp(launch, target, p)!;
        final tail = Offset.lerp(launch, target, math.max(0, p - 0.18))!;
        canvas.drawLine(
          tail,
          at,
          Paint()
            ..shader = LinearGradient(
              colors: [color.withValues(alpha: 0), color],
            ).createShader(Rect.fromPoints(tail, at))
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(at, 4, Paint()..color = Colors.white);
        continue;
      }

      final p = ((local - rise) / life).clamp(0.0, 1.0);
      if (p >= 1) continue;
      if (p < 0.12) flash = math.max(flash, 1 - p / 0.12);
      final spread = Curves.easeOutCubic.transform(p) * radius;
      final gravity = p * p * 90;
      final alpha = 1 - p;

      if (p < 0.2) {
        canvas.drawCircle(
          target,
          radius * 0.5 * (1 - p / 0.2),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7 * (1 - p / 0.2))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
        );
      }
      // Outer ring with streaks, inner ring in a second color.
      for (final (ringColor, scale, dot) in [
        (color, 1.0, 3.0),
        (inner, 0.55, 2.4),
      ]) {
        final spark = Paint()..color = ringColor.withValues(alpha: alpha);
        final glow = Paint()
          ..color = ringColor.withValues(alpha: alpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final streak = Paint()
          ..color = ringColor.withValues(alpha: alpha * 0.6)
          ..strokeWidth = dot * 0.8
          ..strokeCap = StrokeCap.round;
        for (final a in angles) {
          final dir = Offset(math.cos(a), math.sin(a));
          final at = target + dir * spread * scale + Offset(0, gravity);
          final behind =
              target + dir * spread * scale * 0.82 + Offset(0, gravity * 0.8);
          canvas.drawLine(behind, at, streak);
          canvas.drawCircle(at, dot * 2.4 * (1 - p * 0.6), glow);
          canvas.drawCircle(at, dot * (1 - p * 0.5), spark);
        }
      }
      // Crackling glitter that twinkles as it falls.
      if (p > 0.35) {
        final twinkle = Paint()..color = Colors.white.withValues(alpha: alpha);
        for (final (a, r) in glitter) {
          if (math.sin((p * 60) + a * 10) < 0.2) continue;
          final at =
              target +
              Offset(math.cos(a), math.sin(a)) * radius * (0.3 + r * 0.8) +
              Offset(0, gravity * 1.3);
          canvas.drawCircle(at, 1.8, twinkle);
        }
      }
    }
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.18 * flash),
      );
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t || old.seed != seed;
}
