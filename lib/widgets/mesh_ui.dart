import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mesh_theme.dart';

/// MeshCore shared design kit.
///
/// Building blocks used across all screens so the app reads as one product:
/// [SectionHeader], [MeshCard], [StatusChip], [StatTile], [AvatarCircle],
/// [SignalBars], [RouteChip], [PulseDot], [BottomSheetHeader] +
/// [showMeshSheet], [ErrorRetryCard], and [ListEntrance].

/// Small-caps mono section label, optionally with a trailing widget.
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.label, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: MeshTheme.accentLabel(color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Bordered surface card with press feedback. The standard container for
/// grouped content and tappable list entries.
class MeshCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double radius;

  const MeshCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.color,
    this.borderColor,
    this.radius = MeshRadii.md,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? scheme.outlineVariant),
    );
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? scheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onLongPress!();
                },
          onSecondaryTap: onSecondaryTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Tinted pill chip for statuses: a dot or icon plus a short label.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool pulse;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.pulse = false,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MeshRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: fontSize + 2, color: color)
          else
            PulseDot(color: color, size: 7, animate: pulse),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MeshTheme.mono(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact metric tile: icon, mono value (+ optional unit), small label.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return MeshCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: MeshTheme.accentLabel(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: value,
              style: MeshTheme.mono(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: MeshTheme.mono(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Initials avatar with a deterministic per-name hue, or a fixed [color]
/// for node-type coloring. Optional [icon] replaces initials.
class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final IconData? icon;

  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 40,
    this.color,
    this.icon,
  });

  static const _hues = [
    MeshPalette.blue,
    MeshPalette.magenta,
    MeshPalette.signal,
    MeshPalette.warn,
    Color(0xFF8FA8F0),
    Color(0xFF6FD9CE),
  ];

  Color _colorFor(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _hues[h % _hues.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = color ?? _colorFor(name);
    final initials = _initials(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: accent)
          : Text(
              initials,
              style: MeshTheme.mono(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
    );
  }

  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return (words.first.characters.take(1).toString() +
            words[1].characters.take(1).toString())
        .toUpperCase();
  }
}

/// Four-bar signal strength indicator driven by an SNR value (dB), colored
/// with the shared [MeshTheme.snrColor] ramp.
class SignalBars extends StatelessWidget {
  final double? snr;
  final double height;

  const SignalBars({super.key, required this.snr, this.height = 14});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = MeshTheme.snrColor(snr, blocked: false);
    final active = snr == null
        ? 0
        : snr! > 0
        ? 4
        : snr! > -5
        ? 3
        : snr! > -12
        ? 2
        : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final on = i < active;
        return Container(
          width: 3,
          height: height * (0.4 + i * 0.2),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: on ? color : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

/// Chip describing how a message was routed: direct (with hop count) vs flood.
class RouteChip extends StatelessWidget {
  final bool isDirect;
  final int? hops;

  const RouteChip({super.key, required this.isDirect, this.hops});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = isDirect
        ? (hops == null || hops == 0
              ? 'DIRECT'
              : '$hops HOP${hops == 1 ? '' : 'S'}')
        : 'FLOOD';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(MeshRadii.xs),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDirect ? Icons.trending_flat : Icons.podcasts,
            size: 11,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: MeshTheme.accentLabel(
              color: scheme.onSurfaceVariant,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status dot, optionally with a soft breathing animation.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const PulseDot({
    super.key,
    required this.color,
    this.size = 8,
    this.animate = false,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  // Created eagerly: a lazy `late final` initializer would run on first
  // access — which can be dispose(), where ticker creation throws.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animate
          ? Tween(begin: 0.35, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            )
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.45),
              blurRadius: widget.size * 0.7,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard modal sheet header: drag handle, title, optional subtitle and
/// trailing action, and a close button.
class BottomSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const BottomSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: scheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet with the app-standard shape, scroll behavior
/// and safe-area handling. Pair the content with [BottomSheetHeader].
Future<T?> showMeshSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    showDragHandle: false,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// Inline error surface with an optional retry action.
class ErrorRetryCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorRetryCard({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MeshCard(
      color: scheme.error.withValues(alpha: 0.08),
      borderColor: scheme.error.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(retryLabel ?? 'Retry')),
        ],
      ),
    );
  }
}

/// Staggered fade + slide entrance for list items. Wrap each item and pass
/// its [index]; animation only plays once per widget lifecycle.
class ListEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const ListEntrance({super.key, required this.index, required this.child});

  @override
  State<ListEntrance> createState() => _ListEntranceState();
}

class _ListEntranceState extends State<ListEntrance>
    with SingleTickerProviderStateMixin {
  // Created eagerly: a lazy `late final` initializer would run on first
  // access — which can be dispose(), where ticker creation throws.
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final delay = Duration(milliseconds: 24 * widget.index.clamp(0, 12));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
