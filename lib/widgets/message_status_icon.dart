import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';

class MessageStatusIcon extends StatefulWidget {
  final bool isAcked;
  final bool isFailed;
  final bool isPending;

  /// Channel messages have no delivery ACK. Instead of a delivered tick they
  /// show how many times the mesh was heard repeating the message.
  final bool isChannel;
  final int repeatCount;

  /// While the app is resending a channel message to reach more repeaters:
  /// how many resends so far and the limit.
  final ({int resends, int maxResends})? resendProgress;

  /// Set when resending gave up before the message was heard through the
  /// required number of repeaters.
  final ({int hops, int required})? hopShortfall;
  final double size;

  /// Base tint for the sent/sending state. On a colored (outgoing) bubble a
  /// plain grey tick is nearly invisible, so callers can pass the bubble's own
  /// meta/text color for contrast. Falls back to [ColorScheme.onSurfaceVariant].
  final Color? onColor;

  const MessageStatusIcon({
    super.key,
    required this.isAcked,
    this.isFailed = false,
    this.isPending = false,
    this.isChannel = false,
    this.repeatCount = 0,
    this.resendProgress,
    this.hopShortfall,
    this.size = 16,
    this.onColor,
  });

  @override
  State<MessageStatusIcon> createState() => _MessageStatusIconState();
}

class _MessageStatusIconState extends State<MessageStatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPending) _controller.repeat();
  }

  @override
  void didUpdateWidget(MessageStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPending && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPending && _controller.isAnimating) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final double size = widget.size;
    final Color baseColor = widget.onColor ?? colorScheme.onSurfaceVariant;
    final Color confirmedColor = MeshPalette.signal.withValues(alpha: 0.9);

    final String label;
    final Widget icon;
    if (widget.isFailed) {
      label = widget.isChannel
          ? l10n.messageStatus_failedChannel
          : l10n.messageStatus_failed;
      icon = Icon(Icons.cancel, size: size, color: colorScheme.error);
    } else if (widget.isPending) {
      label = l10n.messageStatus_pending;
      icon = _SendingDots(
        controller: _controller,
        color: baseColor,
        size: size,
      );
    } else if (widget.isChannel && widget.hopShortfall != null) {
      final shortfall = widget.hopShortfall!;
      label = l10n.messageStatus_hopsNotReached(
        shortfall.hops,
        shortfall.required,
      );
      icon = Icon(
        Icons.warning_amber_rounded,
        size: size,
        color: MeshPalette.warn,
      );
    } else if (widget.isChannel && (widget.resendProgress?.resends ?? 0) > 0) {
      final progress = widget.resendProgress!;
      label = l10n.messageStatus_resending(
        progress.resends,
        progress.maxResends,
      );
      icon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.autorenew, size: size, color: MeshPalette.warn),
          const SizedBox(width: 2),
          Text(
            '${progress.resends}/${progress.maxResends}',
            style: MeshTheme.mono(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: MeshPalette.warn,
            ),
          ),
        ],
      );
    } else if (widget.isChannel && widget.repeatCount > 0) {
      label = l10n.messageStatus_heardRepeatedCount(widget.repeatCount);
      icon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: size, color: confirmedColor),
          const SizedBox(width: 2),
          Text(
            '${widget.repeatCount}',
            style: MeshTheme.mono(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: confirmedColor,
            ),
          ),
        ],
      );
    } else if (widget.isChannel) {
      label = l10n.messageStatus_sentChannel;
      icon = Icon(Icons.done, size: size, color: baseColor);
    } else if (widget.isAcked) {
      label = l10n.messageStatus_delivered;
      icon = SvgPicture.asset(
        'assets/icons/done_all.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(confirmedColor, BlendMode.srcIn),
      );
    } else {
      label = l10n.messageStatus_sentDirect;
      icon = Icon(Icons.done, size: size, color: baseColor);
    }

    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: icon,
    );
  }
}

/// Three dots that pulse left-to-right while a message is in flight.
class _SendingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double size;

  const _SendingDots({
    required this.controller,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double dot = (size * 0.24).clamp(2.0, 4.0);
    return SizedBox(
      height: size,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (i) {
              final double phase = (controller.value - i * 0.18) % 1.0;
              final double t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
              final double opacity = 0.25 + 0.75 * t.clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: dot * 0.28),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
