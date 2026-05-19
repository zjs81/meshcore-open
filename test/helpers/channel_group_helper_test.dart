import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/channel_group_helper.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_group.dart';

void main() {
  Channel channel(int index, String name) {
    return Channel(index: index, name: name, psk: Uint8List(16));
  }

  int compareByName(Channel a, Channel b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  group('ChannelGroupHelper', () {
    test('keeps empty groups at their manual top-level position', () {
      final entries = buildManualChannelEntries(
        [channel(1, 'Alpha'), channel(2, 'Beta')],
        const [ChannelGroup(name: 'Empty', channelIndexes: [], sortOrder: 1)],
      );

      expect(entries[0].channel?.index, 1);
      expect(entries[1].group?.name, 'Empty');
      expect(entries[2].channel?.index, 2);
    });

    test('updates group sort order from manually reordered entries', () {
      final first = ChannelGroup(name: 'First', channelIndexes: [1]);
      final second = ChannelGroup(name: 'Second', channelIndexes: [2]);

      final groups = channelGroupsFromManualEntries([
        ChannelGroupListEntry.group(second),
        ChannelGroupListEntry.group(first),
      ]);

      expect(groups[0].name, 'Second');
      expect(groups[0].sortOrder, 0);
      expect(groups[1].name, 'First');
      expect(groups[1].sortOrder, 1);
    });

    test(
      'preserves selected in-group order when manual ordering is enabled',
      () {
        final group = ChannelGroup(name: 'Group', channelIndexes: [3, 1, 2]);
        final editableChannels = [
          channel(1, 'Beta'),
          channel(2, 'Gamma'),
          channel(3, 'Alpha'),
        ];

        final selected = selectedChannelIndexesForGroupEdit(
          group,
          editableChannels,
          {1, 2, 3},
        );

        expect(selected, [3, 1, 2]);
      },
    );

    test(
      'sorts selected channels by name when manual ordering is disabled',
      () {
        final selected = selectedChannelIndexesForGroupEditSorted(
          [channel(1, 'Beta'), channel(2, 'Gamma'), channel(3, 'Alpha')],
          {1, 2, 3},
          compareByName,
        );

        expect(selected, [3, 1, 2]);
      },
    );

    test('reorders channels using the adjusted onReorderItem index', () {
      final group = ChannelGroup(name: 'Group', channelIndexes: [1, 2, 3]);

      final reordered = reorderedChannelIndexesInGroup(group, 0, 2);

      expect(reordered, [2, 3, 1]);
    });
  });
}
