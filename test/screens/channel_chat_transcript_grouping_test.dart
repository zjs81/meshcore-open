import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/screens/channel_chat_transcript_grouping.dart';

final _day1 = DateTime(2026, 3, 1, 12);
final _day2 = DateTime(2026, 3, 2, 12);

TranscriptRowInfo _msg(String id, {bool filtered = false, DateTime? at}) =>
    TranscriptRowInfo(id: id, receivedAt: at ?? _day1, isFiltered: filtered);

TranscriptRowInfo _img(String id, {bool filtered = false}) => TranscriptRowInfo(
  id: id,
  receivedAt: _day1,
  isImage: true,
  isFiltered: filtered,
);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Compact description: plain rows by id, ghosts as `[ids]`, the header above
/// a revealed run as `^[ids]`.
List<String> _describe(
  List<TranscriptRowInfo> rows,
  List<TranscriptEntry> entries,
) => [
  for (final e in entries)
    e.isGhost
        ? '${e.expanded ? '^' : ''}[${e.rows.map((r) => rows[r].id).join(',')}]'
        : rows[e.row].id,
];

void main() {
  group('groupFilteredRows', () {
    test('no filtered rows leaves every row as its own entry', () {
      final rows = [_msg('a'), _msg('b'), _msg('c')];
      final entries = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.placeholder,
      );
      expect(_describe(rows, entries), ['a', 'b', 'c']);
      expect(entries.every((e) => !e.isGhost), isTrue);
    });

    test('placeholder mode collapses each run into one ghost', () {
      final rows = [
        _msg('a'),
        _msg('s1', filtered: true),
        _msg('s2', filtered: true),
        _msg('s3', filtered: true),
        _msg('b'),
        _msg('s4', filtered: true),
      ];
      final entries = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.placeholder,
      );
      expect(_describe(rows, entries), ['a', '[s1,s2,s3]', 'b', '[s4]']);
      // The ghost id follows its newest member (first in newest-first order).
      expect(entries[1].id, 'ghost:s1');
      expect(entries[3].id, 'ghost:s4');
      expect(entries[0].id, 'a');
    });

    test('hide mode drops filtered rows entirely', () {
      final rows = [
        _msg('a'),
        _msg('s1', filtered: true),
        _msg('s2', filtered: true),
        _msg('b'),
      ];
      final entries = groupFilteredRows(rows, mode: FilterDisplayMode.hide);
      expect(_describe(rows, entries), ['a', 'b']);
    });

    test(
      'revealed ids render as normal rows under a header and split runs',
      () {
        final rows = [
          _msg('s1', filtered: true),
          _msg('s2', filtered: true),
          _msg('s3', filtered: true),
        ];
        final entries = groupFilteredRows(
          rows,
          mode: FilterDisplayMode.placeholder,
          revealedIds: {'s2'},
        );
        expect(_describe(rows, entries), ['[s1]', '^[s2]', '[s3]']);

        final hidden = groupFilteredRows(
          rows,
          mode: FilterDisplayMode.hide,
          revealedIds: {'s2'},
        );
        expect(_describe(rows, hidden), ['s2']);
      },
    );

    test('a fully revealed run stays one entry with a stable id', () {
      final rows = [
        _msg('a'),
        _msg('s1', filtered: true),
        _msg('s2', filtered: true),
        _msg('s3', filtered: true),
        _msg('b'),
      ];
      final collapsed = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.placeholder,
      );
      final expanded = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.placeholder,
        revealedIds: {'s1', 's2', 's3'},
      );
      expect(_describe(rows, expanded), ['a', '^[s1,s2,s3]', 'b']);
      // Same id in both states, so the UI can animate it in place.
      expect(expanded[1].id, collapsed[1].id);
      expect(expanded[1].id, 'ghost:s1');
      expect(collapsed[1].expanded, isFalse);
      expect(expanded[1].expanded, isTrue);
      // Scroll targets inside the run land on the run entry.
      final byRow = entryIndexByRow(expanded, rows.length);
      expect([for (var r = 0; r < rows.length; r++) byRow[r]], [0, 1, 1, 1, 2]);
    });

    test('images are never grouped and break a run', () {
      final rows = [
        _msg('s1', filtered: true),
        _img('aeic:1', filtered: true),
        _msg('s2', filtered: true),
      ];
      final entries = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.placeholder,
      );
      expect(_describe(rows, entries), ['[s1]', 'aeic:1', '[s2]']);
      expect(
        _describe(rows, groupFilteredRows(rows, mode: FilterDisplayMode.hide)),
        ['aeic:1'],
      );
    });

    test('inactive filter shows filtered messages as normal rows', () {
      final rows = [_msg('s1', filtered: true), _msg('a')];
      final entries = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.hide,
        filterActive: false,
      );
      expect(_describe(rows, entries), ['s1', 'a']);
    });

    test('a run is split at a day boundary when sameDay is given', () {
      final rows = [
        _msg('s1', filtered: true, at: _day2),
        _msg('s2', filtered: true, at: _day1),
        _msg('s3', filtered: true, at: _day1),
      ];
      expect(
        _describe(
          rows,
          groupFilteredRows(
            rows,
            mode: FilterDisplayMode.placeholder,
            sameDay: _sameDay,
          ),
        ),
        ['[s1]', '[s2,s3]'],
      );
      expect(
        _describe(
          rows,
          groupFilteredRows(rows, mode: FilterDisplayMode.placeholder),
        ),
        ['[s1,s2,s3]'],
      );
    });

    test('empty input yields no entries', () {
      expect(
        groupFilteredRows(const [], mode: FilterDisplayMode.placeholder),
        isEmpty,
      );
    });
  });

  group('entryIndexByRow', () {
    test('an unread anchor inside a ghost run maps to the ghost', () {
      final rows = [
        _msg('new'),
        _msg('s1', filtered: true),
        _msg('anchor', filtered: true),
        _msg('old'),
      ];
      final entries = groupFilteredRows(
        rows,
        mode: FilterDisplayMode.placeholder,
      );
      final byRow = entryIndexByRow(entries, rows.length);
      expect(byRow[2], 1);
      expect(entries[byRow[2]!].id, 'ghost:s1');
      expect(byRow[0], 0);
      expect(byRow[3], 2);
    });

    test('a row dropped in hide mode maps to the nearest newer entry', () {
      final rows = [
        _msg('new'),
        _msg('s1', filtered: true),
        _msg('s2', filtered: true),
        _msg('old'),
      ];
      final entries = groupFilteredRows(rows, mode: FilterDisplayMode.hide);
      final byRow = entryIndexByRow(entries, rows.length);
      expect(entries[byRow[1]!].id, 'new');
      expect(entries[byRow[2]!].id, 'new');
      expect(entries[byRow[3]!].id, 'old');
    });

    test('with nothing newer visible, hidden rows map to the older entry', () {
      final rows = [
        _msg('s1', filtered: true),
        _msg('s2', filtered: true),
        _msg('old'),
      ];
      final entries = groupFilteredRows(rows, mode: FilterDisplayMode.hide);
      final byRow = entryIndexByRow(entries, rows.length);
      expect(entries[byRow[0]!].id, 'old');
      expect(entries[byRow[1]!].id, 'old');
    });

    test('maps nothing when every row is hidden', () {
      final rows = [_msg('s1', filtered: true)];
      final entries = groupFilteredRows(rows, mode: FilterDisplayMode.hide);
      expect(entryIndexByRow(entries, rows.length), isEmpty);
    });
  });

  group('isReplyPreviewConcealed', () {
    test('hides a quoted filtered message until it is revealed', () {
      expect(
        isReplyPreviewConcealed(
          quotedIsFiltered: true,
          filterActive: true,
          quotedRevealed: false,
        ),
        isTrue,
      );
      expect(
        isReplyPreviewConcealed(
          quotedIsFiltered: true,
          filterActive: true,
          quotedRevealed: true,
        ),
        isFalse,
      );
    });

    test('normal quotes, or filtering off for the channel, show as usual', () {
      expect(
        isReplyPreviewConcealed(
          quotedIsFiltered: false,
          filterActive: true,
          quotedRevealed: false,
        ),
        isFalse,
      );
      expect(
        isReplyPreviewConcealed(
          quotedIsFiltered: true,
          filterActive: false,
          quotedRevealed: false,
        ),
        isFalse,
      );
    });
  });
}
