import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_text_scale_service.dart';

/// Gesture wrapper that exposes two-finger pinch-to-zoom for chat scrollables.
/// Double-tap resets the scale, but only while the text is zoomed (or the
/// caller supplies [onDoubleTap]) and [enabled] is true: a double-tap
/// recognizer in the gesture arena makes every single tap on the child wait
/// 300 ms, so it is left out wherever taps must be instant. Only the wrapper
/// itself listens to gestures; child scrollables keep their normal touch
/// handling.
class ChatZoomWrapper extends StatefulWidget {
  const ChatZoomWrapper({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onDoubleTap;

  /// When false (e.g. while selecting messages) no double-tap is recognized,
  /// so taps on the child are never delayed or swallowed.
  final bool enabled;

  @override
  State<ChatZoomWrapper> createState() => _ChatZoomWrapperState();
}

class _ChatZoomWrapperState extends State<ChatZoomWrapper> {
  double? _startScale;

  @override
  Widget build(BuildContext context) {
    final service = context.read<ChatTextScaleService>();
    final zoomed = context.select<ChatTextScaleService, bool>(
      (s) => s.scale != 1.0,
    );
    final allowDoubleTap =
        widget.enabled && (zoomed || widget.onDoubleTap != null);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: allowDoubleTap
          ? () {
              service.reset();
              service.persist();
              widget.onDoubleTap?.call();
            }
          : null,
      onScaleStart: (details) {
        if (details.pointerCount != 2) return;
        _startScale = service.scale;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount != 2) return;
        final baseScale = _startScale ?? service.scale;
        service.setScale(baseScale * details.scale);
      },
      onScaleEnd: (_) {
        _startScale = null;
        service.persist();
      },
      child: widget.child,
    );
  }
}
