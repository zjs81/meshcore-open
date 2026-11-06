import 'package:flutter/widgets.dart';

/// The on-screen rect of [context]'s widget, for share_plus'
/// `sharePositionOrigin`. iPad anchors the share popover to it and throws
/// without one; other platforms ignore it.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
