import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Keeps the rows a reader is looking at in place when messages are added
/// below them in a reversed chat list.
///
/// In a `reverse: true` list the newest message is index 0, so every new
/// message moves the older ones up an index. The list keeps layout offsets by
/// index, which leaves the scroll offset unchanged and shifts what is on
/// screen up by the new rows' height. Call [rowsInsertedBelow] while building
/// the list, before it lays out the new rows; [AnchoredChatListView] then
/// scrolls by however far the lowest row on screen moved, in the same layout
/// pass, so nothing visibly jumps.
class ChatScrollAnchor {
  _RenderAnchorSliver? _sliver;
  _Anchor? _pending;

  /// Notes that [count] rows are being added at index 0, below every row
  /// currently laid out, and remembers the lowest row on screen.
  void rowsInsertedBelow(int count) {
    _pending = null;
    final list = _sliver?.child;
    if (count <= 0 || list is! RenderSliverMultiBoxAdaptor) return;
    if (list.geometry == null) return;
    final start = list.constraints.scrollOffset;
    final end = start + list.constraints.remainingPaintExtent;
    for (var row = list.firstChild; row != null; row = list.childAfter(row)) {
      final offset = list.childScrollOffset(row);
      if (offset == null || !row.hasSize) continue;
      if (offset >= end) break;
      if (offset + _extentOf(row, list) > start) {
        _pending = _Anchor(list.indexOf(row) + count, offset);
        // Rows of equal height would not relayout the list on their own.
        _sliver!.markNeedsLayout();
        return;
      }
    }
  }

  /// The scroll correction that puts the remembered row back where it was,
  /// or null when none is needed (yet).
  double? _correctionAfterLayout(
    RenderSliverMultiBoxAdaptor list,
    double? listCorrection,
  ) {
    final pending = _pending;
    if (pending == null) return null;
    if (listCorrection != null) {
      // The list shifts every row by this itself; measure on the next pass.
      pending.offset += listCorrection;
      return null;
    }
    double? target;
    final first = list.firstChild;
    final last = list.lastChild;
    if (first == null || last == null) {
      _pending = null;
      return null;
    }
    for (RenderBox? row = first; row != null; row = list.childAfter(row)) {
      if (list.indexOf(row) == pending.index) {
        target = list.childScrollOffset(row);
        break;
      }
    }
    if (target != null) {
      _pending = null;
      final delta = target - pending.offset;
      return delta.abs() < 0.5 ? null : delta;
    }
    // The row is not laid out at this offset: scroll to an estimate of where
    // it is, which lays out the rows there, and correct exactly next pass.
    if (++pending.passes > 3) {
      _pending = null;
      return null;
    }
    final firstIndex = list.indexOf(first);
    final lastIndex = list.indexOf(last);
    final firstOffset = list.childScrollOffset(first);
    final lastOffset = list.childScrollOffset(last);
    if (firstOffset == null || lastOffset == null) {
      _pending = null;
      return null;
    }
    // Child sizes are off limits here, so space rows by their mean pitch.
    final average = lastIndex > firstIndex
        ? (lastOffset - firstOffset) / (lastIndex - firstIndex)
        : 50.0;
    final estimate = pending.index > lastIndex
        ? lastOffset + (pending.index - lastIndex) * average
        : firstOffset - (firstIndex - pending.index) * average;
    final delta = estimate - pending.offset;
    pending.offset = estimate;
    return delta.abs() < 0.5 ? null : delta;
  }

  static double _extentOf(RenderBox row, RenderSliver list) =>
      list.constraints.axis == Axis.vertical ? row.size.height : row.size.width;
}

class _Anchor {
  _Anchor(this.index, this.offset);

  /// The remembered row's index once the new rows are in.
  final int index;

  /// Where the row has to be laid out for the reader to see no movement.
  double offset;
  int passes = 0;
}

/// A [ListView.builder] whose on-screen rows stay put when a
/// [ChatScrollAnchor] is told rows were added below them.
class AnchoredChatListView extends ListView {
  AnchoredChatListView.builder({
    super.key,
    required this.scrollAnchor,
    super.reverse,
    super.controller,
    super.padding,
    required super.itemBuilder,
    super.itemCount,
  }) : super.builder();

  final ChatScrollAnchor scrollAnchor;

  @override
  Widget buildChildLayout(BuildContext context) => _AnchorSliver(
    anchor: scrollAnchor,
    child: super.buildChildLayout(context),
  );
}

class _AnchorSliver extends SingleChildRenderObjectWidget {
  const _AnchorSliver({required this.anchor, required Widget super.child});

  final ChatScrollAnchor anchor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAnchorSliver(anchor);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAnchorSliver renderObject,
  ) {
    renderObject.anchor = anchor;
  }
}

class _RenderAnchorSliver extends RenderProxySliver {
  _RenderAnchorSliver(this._anchor);

  ChatScrollAnchor _anchor;
  set anchor(ChatScrollAnchor value) {
    if (identical(value, _anchor)) return;
    if (attached) {
      if (identical(_anchor._sliver, this)) _anchor._sliver = null;
      value._sliver = this;
    }
    _anchor = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _anchor._sliver = this;
  }

  @override
  void detach() {
    if (identical(_anchor._sliver, this)) _anchor._sliver = null;
    super.detach();
  }

  @override
  void performLayout() {
    final list = child!;
    list.layout(constraints, parentUsesSize: true);
    final listGeometry = list.geometry!;
    final correction = list is RenderSliverMultiBoxAdaptor
        ? _anchor._correctionAfterLayout(
            list,
            listGeometry.scrollOffsetCorrection,
          )
        : null;
    geometry = correction == null
        ? listGeometry
        : SliverGeometry(scrollOffsetCorrection: correction);
  }
}
