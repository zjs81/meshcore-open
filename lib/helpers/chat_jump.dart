import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scrolls a lazily built chat list until the row at [targetIndex] is built,
/// then animates it to the middle of the viewport. Returns whether it got
/// there.
///
/// A `ListView.builder` only builds rows near the viewport and only estimates
/// the extent of the rest, so a target far away has no widget yet. This jumps
/// to a proportional estimate, then reads which rows the list actually built
/// and steps toward the target until it is among them. Works for reversed
/// chat lists too: it only compares list indices, never pixel directions.
Future<bool> scrollListToIndex({
  required ScrollController controller,
  required int targetIndex,
  required int itemCount,
  required bool Function() isMounted,
}) async {
  if (!controller.hasClients || itemCount <= 0) return false;
  if (targetIndex < 0 || targetIndex >= itemCount) return false;

  // First guess: the target's share of the estimated extent.
  final start = controller.position;
  final guess = start.maxScrollExtent * ((targetIndex + 0.5) / itemCount);
  controller.jumpTo(guess.clamp(start.minScrollExtent, start.maxScrollExtent));

  var pinnedFrames = 0;
  for (var attempt = 0; attempt < 120; attempt++) {
    await WidgetsBinding.instance.endOfFrame;
    if (!isMounted() || !controller.hasClients) return false;
    final position = controller.position;
    final sliver = _findListSliver(position);
    if (sliver == null) return false;

    final child = _childAt(sliver, targetIndex);
    if (child != null) {
      final viewport = RenderAbstractViewport.maybeOf(child);
      if (viewport == null) return false;
      final reveal = viewport.getOffsetToReveal(child, 0.5).offset;
      await controller.animateTo(
        reveal.clamp(position.minScrollExtent, position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return true;
    }

    final first = sliver.firstChild;
    final last = sliver.lastChild;
    if (first == null || last == null) return false;
    final lowest = sliver.indexOf(first);
    final highest = sliver.indexOf(last);
    // Step by the rows still to go times the measured height of the rows
    // built around here, so the walk converges even when distant rows are
    // much taller or shorter than the ones the extent estimate was based on.
    // Larger indices sit further along the scroll axis.
    final rowsToGo = targetIndex > highest
        ? targetIndex - highest
        : targetIndex < lowest
        ? targetIndex - lowest
        : 0;
    final step = rowsToGo == 0
        ? 0.0
        : rowsToGo * _averageExtent(sliver, position.axis) +
              rowsToGo.sign * position.viewportDimension * 0.5;
    final next = position.pixels + step;
    final clamped = next.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (clamped == position.pixels) {
      // Pinned at an end with the target still beyond it. The extent is an
      // estimate that grows as rows get built, so only give up once it has
      // stopped growing for a few frames. Otherwise wait a frame for layout.
      if (next != clamped && ++pinnedFrames >= 3) return false;
      continue;
    }
    pinnedFrames = 0;
    controller.jumpTo(clamped);
  }
  return false;
}

/// Mean main-axis size of the rows [sliver] has built.
double _averageExtent(RenderSliverMultiBoxAdaptor sliver, Axis axis) {
  var total = 0.0;
  var count = 0;
  var child = sliver.firstChild;
  while (child != null) {
    if (child.hasSize) {
      total += axis == Axis.vertical ? child.size.height : child.size.width;
      count++;
    }
    child = sliver.childAfter(child);
  }
  return count == 0 ? 50 : total / count;
}

RenderBox? _childAt(RenderSliverMultiBoxAdaptor sliver, int index) {
  var child = sliver.firstChild;
  while (child != null) {
    if (sliver.indexOf(child) == index) return child;
    child = sliver.childAfter(child);
  }
  return null;
}

/// The list sliver inside the scrollable that [position] belongs to.
RenderSliverMultiBoxAdaptor? _findListSliver(ScrollPosition position) {
  final context = position.context.storageContext;
  if (context is! Element) return null;
  RenderSliverMultiBoxAdaptor? found;
  void visit(Element element) {
    if (found != null) return;
    final renderObject = element is RenderObjectElement
        ? element.renderObject
        : null;
    if (renderObject is RenderSliverMultiBoxAdaptor) {
      found = renderObject;
      return;
    }
    element.visitChildren(visit);
  }

  context.visitChildren(visit);
  return found;
}
