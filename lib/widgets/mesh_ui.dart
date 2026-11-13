import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import '../theme/theme_icons.dart';

/// MeshCore shared design kit.
///
/// Building blocks used across all screens so the app reads as one product:
/// [SectionHeader], [MeshCard], [StatusChip], [StatTile], [AvatarCircle],
/// [SignalBars], [RouteChip], [PulseDot], [BottomSheetHeader] +
/// [showMeshSheet], [ErrorRetryCard], [ListEntrance], [MeshSegmentLabel]
/// and [MeshMenuItemRow].

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
              style: MeshTheme.accentLabel(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
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
/// Contrast ratio between two opaque colors (WCAG definition).
double meshContrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [accent] darkened (on light backgrounds) or lightened (on dark ones) until
/// it reaches [minContrast] against [background]. WCAG asks 4.5 for text and
/// 3 for icons. Accents such as amber are bright enough for the dark theme but
/// unreadable on their own pale tint in the light theme.
Color readableAccent(
  Color accent,
  Color background, {
  double minContrast = 4.5,
}) {
  if (meshContrastRatio(accent, background) >= minContrast) return accent;
  final darken = background.computeLuminance() > 0.18;
  final hsl = HSLColor.fromColor(accent);
  for (var step = 1; step <= 20; step++) {
    final lightness = (hsl.lightness + (darken ? -0.05 : 0.05) * step).clamp(
      0.0,
      1.0,
    );
    final candidate = hsl.withLightness(lightness).toColor();
    if (meshContrastRatio(candidate, background) >= minContrast) {
      return candidate;
    }
  }
  return darken ? Colors.black : Colors.white;
}

/// The background of a [tint] alpha wash of [accent] drawn on a card.
Color _tintedCardBackground(BuildContext context, Color accent, double tint) {
  return Color.alphaBlend(
    accent.withValues(alpha: tint),
    Theme.of(context).colorScheme.surfaceContainerLow,
  );
}

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
    this.fontSize = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    // The label uses the normal text color: colored text on a tint of the
    // same color is hard to read. The icon or dot carries the color, adjusted
    // to stay visible on the tint.
    final background = _tintedCardBackground(context, color, 0.12);
    final markColor = readableAccent(color, background, minContrast: 3);
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
            Icon(icon, size: fontSize + 2, color: markColor)
          else
            PulseDot(color: markColor, size: 7, animate: pulse),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MeshTheme.mono(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
                    fontSize: 14,
                  ),
                  maxLines: 2,
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
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: MeshTheme.mono(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

/// Initials avatar with a deterministic per-name hue, or a fixed [color]
/// for node-type coloring. Optional [icon] or themeable [iconSlot] replaces
/// initials.
class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final IconData? icon;
  final ThemeIconSlot? iconSlot;

  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 40,
    this.color,
    this.icon,
    this.iconSlot,
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
    final background = _tintedCardBackground(context, accent, 0.14);
    // A theme picture (e.g. a holiday marker) fills the whole circle, the
    // same as on the map, rather than sitting small inside the tint.
    final picture = iconSlot == null
        ? null
        : themePictureOf(MeshIconTheme.of(context)[iconSlot!]);
    if (picture != null) {
      return SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: Image(
            image: picture,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => Icon(
              iconSlot!.icon,
              size: size * 0.5,
              color: readableAccent(accent, background, minContrast: 3),
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: iconSlot != null
          ? ThemedIcon(
              iconSlot!,
              size: size * 0.55,
              color: readableAccent(accent, background, minContrast: 3),
            )
          : icon != null
          ? Icon(
              icon,
              size: size * 0.5,
              color: readableAccent(accent, background, minContrast: 3),
            )
          : Text(
              initials,
              style: MeshTheme.mono(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: readableAccent(accent, background),
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
    final l10n = context.l10n;
    final label =
        (isDirect
                ? (hops == null || hops == 0
                      ? l10n.chat_direct
                      : l10n.chat_hopsCount(hops!))
                : l10n.routing_modeFlood)
            .toUpperCase();
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
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: MeshTheme.accentLabel(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
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
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
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
///
/// `useSafeArea` only pads the top and sides, so the bottom is padded here by
/// whichever is larger: the keyboard inset or the system navigation bar
/// (edge-to-edge Android, iOS home indicator). Both are then removed from the
/// content's [MediaQuery] so nested [SafeArea]s don't apply them twice.
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
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final bottom = math.max(
        media.viewInsets.bottom,
        media.viewPadding.bottom,
      );
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: MediaQuery(
          data: media
              .removeViewInsets(removeBottom: true)
              .removeViewPadding(removeBottom: true)
              .removePadding(removeBottom: true),
          child: Builder(builder: builder),
        ),
      );
    },
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

/// Contents of a [PopupMenuItem]: a 20px icon, a 12px gap and a label that
/// wraps to at most [maxLines] lines and then ends in an ellipsis, so long
/// translations are never clipped at the menu edge.
///
/// Pass an [icon], or a [leading] widget for custom icons (sized 20). With
/// neither, a 20px gap keeps the label aligned with rows that have one.
/// [color] tints icon and label (e.g. red for a destructive action);
/// [iconColor] tints only the icon. [selected] bolds the label, for menus
/// that mark the current choice.
class MeshMenuItemRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final Color? color;
  final Color? iconColor;
  final bool selected;
  final int maxLines;

  const MeshMenuItemRow({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    this.color,
    this.iconColor,
    this.selected = false,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? color;
    return Row(
      children: [
        IconTheme.merge(
          data: IconThemeData(size: 20, color: effectiveIconColor),
          child: SizedBox(
            width: 20,
            child:
                leading ??
                (icon == null
                    ? null
                    : Icon(icon, size: 20, color: effectiveIconColor)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Label for a [ButtonSegment] that never breaks a word in the middle.
///
/// Uses the button's text style. If the label does not fit on one line it is
/// scaled down, but not below [minFontSize] (before the user's text scale).
/// Below that, a multi-word label wraps at word boundaries onto up to
/// [maxLines] centred lines, shrunk just enough for its longest word to fit.
/// A single word that still does not fit keeps shrinking on one line, as
/// splitting or clipping it would be harder to read than smaller text.
class MeshSegmentLabel extends LeafRenderObjectWidget {
  final String text;
  final double minFontSize;
  final int maxLines;

  const MeshSegmentLabel(
    this.text, {
    super.key,
    this.minFontSize = 12,
    this.maxLines = 2,
  });

  TextStyle _style(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return MediaQuery.boldTextOf(context)
        ? style.merge(const TextStyle(fontWeight: FontWeight.bold))
        : style;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSegmentLabel(
      text: text,
      style: _style(context),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      minFontSize: minFontSize,
      maxLines: maxLines,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSegmentLabel)
      ..text = text
      ..style = _style(context)
      ..textScaler = MediaQuery.textScalerOf(context)
      ..textDirection = Directionality.of(context)
      ..minFontSize = minFontSize
      ..maxLines = maxLines;
  }
}

class _RenderSegmentLabel extends RenderBox {
  _RenderSegmentLabel({
    required String text,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required double minFontSize,
    required int maxLines,
  }) : _text = text,
       _style = style,
       _textScaler = textScaler,
       _textDirection = textDirection,
       _minFontSize = minFontSize,
       _maxLines = maxLines;

  final TextPainter _painter = TextPainter(textAlign: TextAlign.center);

  String _text;
  set text(String value) {
    if (value == _text) return;
    _text = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextStyle _style;
  set style(TextStyle value) {
    if (value == _style) return;
    _style = value;
    // Layout even for a colour-only change: the painter takes the new style
    // (the selected or disabled colour) in _fit, not in paint.
    markNeedsLayout();
  }

  @visibleForTesting
  Color? get debugPaintedColor => _painter.text?.style?.color;

  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) return;
    _textScaler = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double _minFontSize;
  set minFontSize(double value) {
    if (value == _minFontSize) return;
    _minFontSize = value;
    markNeedsLayout();
  }

  int _maxLines;
  set maxLines(int value) {
    if (value == _maxLines) return;
    _maxLines = value;
    markNeedsLayout();
  }

  double get _fontSize => _style.fontSize ?? 14;

  /// [_textScaler] further multiplied by [factor].
  TextScaler _scaled(double factor) {
    if (factor >= 1) return _textScaler;
    return TextScaler.linear(_textScaler.scale(_fontSize) * factor / _fontSize);
  }

  double _lineWidth(TextPainter painter, String text, TextScaler scaler) {
    painter
      ..text = TextSpan(text: text, style: _style)
      ..textDirection = _textDirection
      ..textScaler = scaler
      ..maxLines = 1
      ..ellipsis = null
      ..layout();
    return painter.width;
  }

  /// Configures [painter] for [maxWidth] and lays it out.
  void _fit(TextPainter painter, double maxWidth) {
    final full = _lineWidth(painter, _text, _textScaler);
    var factor = 1.0;
    var lines = 1;
    if (full > maxWidth) {
      // A little slack: glyph metrics do not scale exactly linearly.
      final fitFactor = maxWidth / full * 0.98;
      final floor = math.min(1.0, _minFontSize / _fontSize);
      final words = _text.trim().split(RegExp(r'\s+'));
      if (fitFactor >= floor || words.length < 2) {
        factor = fitFactor;
      } else {
        final longest = words
            .map((w) => _lineWidth(painter, w, _textScaler))
            .reduce(math.max);
        factor = math.min(1.0, maxWidth / longest * 0.98);
        lines = _maxLines;
      }
    }
    painter
      ..text = TextSpan(text: _text, style: _style)
      ..textDirection = _textDirection
      ..textScaler = _scaled(factor)
      ..maxLines = lines
      ..ellipsis = '\u2026'
      ..layout(maxWidth: maxWidth);
  }

  double _intrinsicHeight(double width) {
    final painter = TextPainter(textAlign: TextAlign.center);
    _fit(painter, width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final painter = TextPainter();
    final floor = math.min(1.0, _minFontSize / _fontSize);
    final longest = _text
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => _lineWidth(painter, w, _scaled(floor)))
        .reduce(math.max);
    painter.dispose();
    return longest.ceilToDouble();
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final painter = TextPainter();
    final width = _lineWidth(painter, _text, _textScaler);
    painter.dispose();
    return width.ceilToDouble();
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final painter = TextPainter(textAlign: TextAlign.center);
    _fit(painter, constraints.maxWidth);
    final size = constraints.constrain(painter.size);
    painter.dispose();
    return size;
  }

  Offset get _paintOffset => Offset(
    (size.width - _painter.width) / 2,
    (size.height - _painter.height) / 2,
  );

  @override
  void performLayout() {
    _fit(_painter, constraints.maxWidth);
    size = constraints.constrain(_painter.size);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return _paintOffset.dy + _painter.computeDistanceToActualBaseline(baseline);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _painter.paint(context.canvas, offset + _paintOffset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..label = _text
      ..textDirection = _textDirection;
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }
}
