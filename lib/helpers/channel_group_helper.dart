import 'dart:math';

import '../models/channel.dart';
import '../models/channel_group.dart';

class ChannelGroupListEntry {
  const ChannelGroupListEntry._({this.group, this.channel});

  const ChannelGroupListEntry.group(ChannelGroup group) : this._(group: group);

  const ChannelGroupListEntry.channel(Channel channel)
    : this._(channel: channel);

  final ChannelGroup? group;
  final Channel? channel;
}

List<ChannelGroupListEntry> buildManualChannelEntries(
  List<Channel> orderedChannels,
  List<ChannelGroup> groups,
) {
  final groupByChannel = channelGroupByChannel(groups);
  final emittedGroups = <String>{};
  final entries = <ChannelGroupListEntry>[];
  for (final channel in orderedChannels) {
    final group = groupByChannel[channel.index];
    if (group == null) {
      entries.add(ChannelGroupListEntry.channel(channel));
    } else if (emittedGroups.add(group.name)) {
      entries.add(ChannelGroupListEntry.group(group));
    }
  }

  for (final group in groups) {
    if (emittedGroups.add(group.name)) {
      final insertIndex = max(0, min(group.sortOrder, entries.length));
      entries.insert(insertIndex, ChannelGroupListEntry.group(group));
    }
  }
  return entries;
}

List<ChannelGroup> channelGroupsFromManualEntries(
  List<ChannelGroupListEntry> entries,
) {
  return [
    for (var index = 0; index < entries.length; index++)
      if (entries[index].group != null)
        // Empty groups have no channel anchor, so keep their manual
        // top-level position explicitly.
        entries[index].group!.copyWith(sortOrder: index),
  ];
}

List<int> manualChannelOrderFromEntries(List<ChannelGroupListEntry> entries) {
  return [
    for (final entry in entries)
      if (entry.group != null)
        ...entry.group!.channelIndexes
      else if (entry.channel != null)
        entry.channel!.index,
  ];
}

List<ChannelGroup> orderedChannelGroups(List<ChannelGroup> groups) {
  final indexedGroups = [
    for (var index = 0; index < groups.length; index++)
      MapEntry(
        index,
        groups[index].sortOrder < 0
            ? groups[index].copyWith(sortOrder: index)
            : groups[index],
      ),
  ];
  indexedGroups.sort((a, b) {
    final sortCompare = a.value.sortOrder.compareTo(b.value.sortOrder);
    if (sortCompare != 0) return sortCompare;
    return a.key.compareTo(b.key);
  });
  return [for (final entry in indexedGroups) entry.value];
}

Map<int, ChannelGroup> channelGroupByChannel(List<ChannelGroup> groups) {
  return {
    for (final group in groups)
      for (final index in group.channelIndexes) index: group,
  };
}

List<Channel> channelsForGroup(
  ChannelGroup group,
  List<Channel> filteredChannels,
) {
  final byIndex = {
    for (final channel in filteredChannels) channel.index: channel,
  };
  return [
    for (final index in group.channelIndexes)
      if (byIndex[index] != null) byIndex[index]!,
  ];
}

List<int> reorderedChannelIndexesInGroup(
  ChannelGroup group,
  int oldIndex,
  int newIndex,
) {
  final reorderedIndexes = List<int>.from(group.channelIndexes);
  if (oldIndex < 0 || oldIndex >= reorderedIndexes.length) {
    return reorderedIndexes;
  }
  final channelIndex = reorderedIndexes.removeAt(oldIndex);
  final insertIndex = max(0, min(newIndex, reorderedIndexes.length));
  reorderedIndexes.insert(insertIndex, channelIndex);
  return reorderedIndexes;
}

List<int> manualChannelOrderForGroups(
  List<Channel> orderedChannels,
  List<ChannelGroup> groups,
) {
  final groupByChannel = channelGroupByChannel(groups);
  final emittedGroups = <String>{};
  final orderedIndexes = <int>[];
  for (final channel in orderedChannels) {
    final group = groupByChannel[channel.index];
    if (group == null) {
      orderedIndexes.add(channel.index);
    } else if (emittedGroups.add(group.name)) {
      orderedIndexes.addAll(group.channelIndexes);
    }
  }
  return orderedIndexes;
}

List<int> selectedChannelIndexesForGroupEdit(
  ChannelGroup group,
  List<Channel> editableChannels,
  Set<int> selectedIndexes,
) {
  final orderedIndexes = <int>[
    // Preserve the current in-group order when editing membership/name.
    for (final index in group.channelIndexes)
      if (selectedIndexes.contains(index)) index,
  ];
  final existingIndexes = orderedIndexes.toSet();
  for (final channel in editableChannels) {
    if (selectedIndexes.contains(channel.index) &&
        !existingIndexes.contains(channel.index)) {
      orderedIndexes.add(channel.index);
    }
  }
  return orderedIndexes;
}

List<int> selectedChannelIndexesForGroupEditSorted(
  List<Channel> editableChannels,
  Set<int> selectedIndexes,
  Comparator<Channel> compareChannels,
) {
  final selectedChannels = [
    for (final channel in editableChannels)
      if (selectedIndexes.contains(channel.index)) channel,
  ]..sort(compareChannels);
  return [for (final channel in selectedChannels) channel.index];
}
