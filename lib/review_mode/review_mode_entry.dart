import 'package:flutter/material.dart';

import 'review_mode.dart';

/// Hidden entry point: long-pressing [child] offers to enter review mode.
class ReviewModeLongPress extends StatelessWidget {
  final Widget child;

  const ReviewModeLongPress({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => enterReviewMode(context),
      child: child,
    );
  }
}
