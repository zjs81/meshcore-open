/// Pure grouping of a channel transcript into visible entries, collapsing
/// messages hidden by the message filter.
///
/// Kept free of widgets and connector state so the rules (runs, hide mode,
/// revealed messages, images, anchors) can be unit tested directly.
library;

import 'package:flutter/foundation.dart' show immutable, listEquals;

import '../models/message_filter.dart';

/// What the grouping needs to know about one transcript row.
@immutable
class TranscriptRowInfo {
  /// Row identity: a message id, or an `aeic:` image stream id.
  final String id;

  /// The message filter tagged this row.
  final bool isFiltered;

  /// Image rows are never filtered, whatever [isFiltered] says.
  final bool isImage;

  /// Local arrival time; a ghost run never spans two chat days when the
  /// grouping is given a `sameDay` test.
  final DateTime receivedAt;

  const TranscriptRowInfo({
    required this.id,
    required this.receivedAt,
    this.isFiltered = false,
    this.isImage = false,
  });
}

/// One visible entry of the transcript: a single row, or a ghost standing in
/// for a run of consecutive hidden rows. A revealed run stays ONE entry (with
/// [expanded] set) so its id never changes and the chat can animate it open
/// and closed in place.
@immutable
class TranscriptEntry {
  /// Indices into the row list given to [groupFilteredRows], in the same
  /// (newest-first) order. Exactly one for a plain row.
  final List<int> rows;

  /// Whether this entry is a run of filtered messages.
  final bool isGhost;

  /// For a ghost: the run is revealed (its messages are shown under the
  /// "tap to hide" header).
  final bool expanded;

  /// Stable identity: the row id, or `ghost:<newest member id>` for a run in
  /// either state.
  final String id;

  const TranscriptEntry._(this.rows, this.isGhost, this.id, this.expanded);

  factory TranscriptEntry.row(int row, String id) =>
      TranscriptEntry._(List<int>.unmodifiable([row]), false, id, false);

  factory TranscriptEntry.ghost(
    List<int> rows,
    String newestId, {
    bool expanded = false,
  }) => TranscriptEntry._(
    List<int>.unmodifiable(rows),
    true,
    'ghost:$newestId',
    expanded,
  );

  /// The single row of a non-ghost entry.
  int get row => rows.first;

  @override
  bool operator ==(Object other) =>
      other is TranscriptEntry &&
      other.isGhost == isGhost &&
      other.expanded == expanded &&
      other.id == id &&
      listEquals(other.rows, rows);

  @override
  int get hashCode => Object.hash(isGhost, expanded, id, Object.hashAll(rows));

  @override
  String toString() => !isGhost
      ? 'TranscriptEntry.row($row)'
      : 'TranscriptEntry.ghost($rows${expanded ? ', expanded' : ''})';
}

/// Groups [rows] (newest first, as displayed by the reversed chat list) into
/// visible entries.
///
/// A row is filtered-out when [filterActive] is true and it is a filtered
/// message (not an image). With [FilterDisplayMode.hide] such rows are dropped
/// unless their id is in [revealedIds]. With [FilterDisplayMode.placeholder]
/// consecutive filtered rows form runs, split wherever the revealed state
/// changes (and, when [sameDay] is given, where the chat day changes):
/// each run becomes one [TranscriptEntry.ghost], `expanded` when revealed.
/// Its id depends only on the newest member, so revealing or hiding a run
/// keeps the same entry (and lets the UI animate between the two states).
List<TranscriptEntry> groupFilteredRows(
  List<TranscriptRowInfo> rows, {
  required FilterDisplayMode mode,
  Set<String> revealedIds = const <String>{},
  bool filterActive = true,
  bool Function(DateTime a, DateTime b)? sameDay,
}) {
  bool isFilteredRow(TranscriptRowInfo row) =>
      filterActive && row.isFiltered && !row.isImage;

  final entries = <TranscriptEntry>[];
  var run = <int>[];
  var runRevealed = false;

  void flushRun() {
    if (run.isEmpty) return;
    entries.add(
      TranscriptEntry.ghost(run, rows[run.first].id, expanded: runRevealed),
    );
    run = <int>[];
  }

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (!isFilteredRow(row)) {
      flushRun();
      entries.add(TranscriptEntry.row(i, row.id));
      continue;
    }
    final revealed = revealedIds.contains(row.id);
    if (mode == FilterDisplayMode.hide) {
      if (revealed) entries.add(TranscriptEntry.row(i, row.id));
      continue;
    }
    if (run.isNotEmpty &&
        (revealed != runRevealed ||
            (sameDay != null &&
                !sameDay(rows[run.last].receivedAt, row.receivedAt)))) {
      flushRun();
    }
    if (run.isEmpty) runRevealed = revealed;
    run.add(i);
  }
  flushRun();
  return entries;
}

/// Maps every row index to the index of the entry that represents it on
/// screen, for scroll targets and the unread divider.
///
/// A row inside a ghost (collapsed or expanded) maps to that ghost. A row
/// dropped in hide mode maps
/// to the nearest newer visible entry (the one shown just below it), or, when
/// nothing newer is visible, the nearest older one. Rows map to nothing only
/// when [entries] is empty.
Map<int, int> entryIndexByRow(List<TranscriptEntry> entries, int rowCount) {
  final result = <int, int>{};
  for (var e = 0; e < entries.length; e++) {
    for (final row in entries[e].rows) {
      result[row] = e;
    }
  }
  if (entries.isEmpty || result.length == rowCount) return result;
  // Rows are newest first, so the newer neighbour has the smaller index.
  int? newerEntry;
  for (var row = 0; row < rowCount; row++) {
    final own = result[row];
    if (own != null) {
      newerEntry = own;
    } else if (newerEntry != null) {
      result[row] = newerEntry;
    }
  }
  int? olderEntry;
  for (var row = rowCount - 1; row >= 0; row--) {
    final own = result[row];
    if (own != null) {
      olderEntry = own;
    } else if (olderEntry != null) {
      result[row] = olderEntry;
    }
  }
  return result;
}

/// Whether a reply's quoted preview must be concealed: the quoted message
/// ([quotedIsFiltered]) was hidden by the message filter, filtering is on for
/// the channel ([filterActive]) and the user has not revealed it
/// ([quotedRevealed]). Replies copy the quoted text when they arrive, so
/// without this a reply would show hidden spam in an ordinary bubble.
bool isReplyPreviewConcealed({
  required bool quotedIsFiltered,
  required bool filterActive,
  required bool quotedRevealed,
}) => filterActive && quotedIsFiltered && !quotedRevealed;
