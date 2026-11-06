import 'package:flutter/material.dart';

import '../theme/mesh_theme.dart';

/// Colours shared by the direct-message and channel chat bubbles.
@immutable
class MessageBubbleColors {
  final Color background;
  final Color border;
  final Color text;
  final Color meta;

  const MessageBubbleColors({
    required this.background,
    required this.border,
    required this.text,
    required this.meta,
  });

  /// Outgoing bubbles use the theme's [MeshBubbleTheme]; a failed send
  /// switches to the error container.
  factory MessageBubbleColors.of(
    BuildContext context, {
    required bool isOutgoing,
    bool isFailed = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = MeshBubbleTheme.of(context);
    final text = isFailed
        ? scheme.onErrorContainer
        : isOutgoing
        ? bubble.meInk
        : scheme.onSurface;
    return MessageBubbleColors(
      background: isFailed
          ? scheme.errorContainer
          : isOutgoing
          ? bubble.me
          : scheme.surfaceContainerLow,
      border: isFailed
          ? scheme.error
          : isOutgoing
          ? bubble.meBorder
          : scheme.outlineVariant,
      text: text,
      meta: text.withValues(alpha: 0.65),
    );
  }
}

/// Asymmetric bubble radius: the corner nearest the sender is tight.
BorderRadius messageBubbleRadius({required bool isOutgoing}) {
  return isOutgoing
      ? const BorderRadius.only(
          topLeft: Radius.circular(MeshRadii.lg),
          topRight: Radius.circular(MeshRadii.lg),
          bottomLeft: Radius.circular(MeshRadii.lg),
          bottomRight: Radius.circular(MeshRadii.xs),
        )
      : const BorderRadius.only(
          topLeft: Radius.circular(MeshRadii.xs),
          topRight: Radius.circular(MeshRadii.lg),
          bottomLeft: Radius.circular(MeshRadii.lg),
          bottomRight: Radius.circular(MeshRadii.lg),
        );
}

/// Extra sender-name hues beyond the [MeshPalette] accents. They match the
/// two extra hues [AvatarCircle] uses, so a name and its avatar agree.
const Color kSenderHuePeriwinkle = Color(0xFF8FA8F0);
const Color kSenderHueAqua = Color(0xFF6FD9CE);

const List<Color> _senderHues = [
  MeshPalette.blue,
  MeshPalette.magenta,
  MeshPalette.signal,
  MeshPalette.warn,
  kSenderHuePeriwinkle,
  kSenderHueAqua,
];

/// Deterministic name-to-hue mapping consistent with [AvatarCircle].
Color senderNameColor(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _senderHues[h % _senderHues.length];
}

/// The bubble container shared by both chat screens: colour, border,
/// asymmetric radius, padding and the 72% max width.
class MessageBubbleFrame extends StatelessWidget {
  final bool isOutgoing;
  final bool isFailed;

  /// Tighter padding for media (GIF) content.
  final bool compact;
  final double maxWidth;
  final Widget child;

  const MessageBubbleFrame({
    super.key,
    required this.isOutgoing,
    required this.maxWidth,
    required this.child,
    this.isFailed = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MessageBubbleColors.of(
      context,
      isOutgoing: isOutgoing,
      isFailed: isFailed,
    );
    return Container(
      padding: compact
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(maxWidth: maxWidth * 0.72),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: messageBubbleRadius(isOutgoing: isOutgoing),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: child,
    );
  }
}
