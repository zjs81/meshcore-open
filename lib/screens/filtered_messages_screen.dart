import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/message_filter.dart';
import '../widgets/filtered_message_ghost.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/chat_send_pipeline.dart';
import '../widgets/empty_state.dart';
import '../widgets/mesh_ui.dart';

/// Recent filtered channel messages across all channels, newest first.
///
/// Message text and sender stay hidden until the row is tapped, so the list
/// can be opened without being shown the spam itself. "Not spam" puts a
/// message back in its channel and teaches the filter.
class FilteredMessagesScreen extends StatefulWidget {
  const FilteredMessagesScreen({super.key});

  @override
  State<FilteredMessagesScreen> createState() => _FilteredMessagesScreenState();
}

/// Identity of a row in the Filtered messages list (widget key and reveal
/// state). Message ids do not include the channel and can collide across
/// channels, so they are scoped by the channel's filter id.
String filteredMessageRowId(Channel channel, ChannelMessage message) =>
    '${MeshCoreConnector.messageFilterChannelId(channel)}|${message.messageId}';

class _FilteredMessagesScreenState extends State<FilteredMessagesScreen> {
  final Set<String> _revealed = <String>{};

  /// Bulk selection: when on, taps toggle rows and the app bar holds the
  /// bulk actions.
  bool _selectMode = false;
  final Set<String> _selected = <String>{};

  void _toggleSelected(String rowId) {
    setState(() {
      _selectMode = true;
      if (!_selected.remove(rowId)) _selected.add(rowId);
    });
  }

  void _exitSelectMode() => setState(() {
    _selectMode = false;
    _selected.clear();
  });

  List<(Channel, ChannelMessage)> _selectedEntries(
    List<(Channel, ChannelMessage)> entries,
  ) => [
    for (final e in entries)
      if (_selected.contains(_rowId(e.$1, e.$2))) e,
  ];

  Future<void> _bulkNotSpam(List<(Channel, ChannelMessage)> items) async {
    final connector = context.read<MeshCoreConnector>();
    final text = context.l10n.messageFilter_markedNotSpamCount(items.length);
    setState(() {
      for (final (channel, message) in items) {
        _revealed.remove(_rowId(channel, message));
      }
      _selectMode = false;
      _selected.clear();
    });
    await connector.markChannelMessagesNotSpam(items);
    if (!mounted) return;
    showDismissibleSnackBar(context, content: Text(text));
  }

  Future<void> _bulkDelete(List<(Channel, ChannelMessage)> items) async {
    final connector = context.read<MeshCoreConnector>();
    final confirmed = await confirmBulkDelete(context, items.length);
    if (!confirmed || !mounted) return;
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
    final removed = await connector.deleteChannelMessages(
      items.map((e) => e.$2),
    );
    if (!mounted || removed == 0) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messagesDeleted(removed)),
    );
  }

  static String _rowId(Channel channel, ChannelMessage message) =>
      filteredMessageRowId(channel, message);

  void _toggle(String rowId) {
    setState(() {
      if (!_revealed.remove(rowId)) _revealed.add(rowId);
    });
  }

  Future<void> _markNotSpam(Channel channel, ChannelMessage message) async {
    final connector = context.read<MeshCoreConnector>();
    final text = context.l10n.messageFilter_markedNotSpam;
    await connector.markChannelMessageNotSpam(channel, message);
    if (!mounted) return;
    _revealed.remove(_rowId(channel, message));
    showDismissibleSnackBar(
      context,
      content: Text(text),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final entries = connector.recentFilteredChannelMessages();
    final selectedEntries = _selectedEntries(entries);

    return PopScope(
      canPop: !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectMode) _exitSelectMode();
      },
      child: Scaffold(
        appBar: _selectMode
            ? AppBar(
                leading: IconButton(
                  tooltip: l10n.chat_clearSelection,
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectMode,
                ),
                title: Text(l10n.chat_selectedCount(selectedEntries.length)),
                actions: [
                  IconButton(
                    tooltip: l10n.chat_selectAll,
                    icon: const Icon(Icons.select_all),
                    onPressed: () => setState(() {
                      _selected.addAll(entries.map((e) => _rowId(e.$1, e.$2)));
                    }),
                  ),
                  IconButton(
                    tooltip: l10n.messageFilter_notSpam,
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: selectedEntries.isEmpty
                        ? null
                        : () => _bulkNotSpam(selectedEntries),
                  ),
                  IconButton(
                    tooltip: l10n.common_delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: selectedEntries.isEmpty
                        ? null
                        : () => _bulkDelete(selectedEntries),
                  ),
                ],
              )
            : AppBar(
                title: AdaptiveAppBarTitle(l10n.messageFilter_displayTitle),
                centerTitle: true,
                actions: [
                  if (entries.isNotEmpty)
                    IconButton(
                      tooltip: l10n.chat_selectMessages,
                      icon: const Icon(Icons.checklist),
                      onPressed: () => setState(() => _selectMode = true),
                    ),
                ],
              ),
        body: SafeArea(
          top: false,
          child: entries.isEmpty
              ? EmptyState(
                  icon: Icons.filter_alt_outlined,
                  title: l10n.messageFilter_filteredMessagesEmpty,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final (channel, message) = entries[index];
                    final id = _rowId(channel, message);
                    return _FilteredMessageCard(
                      key: ValueKey('filtered_$id'),
                      channel: channel,
                      message: message,
                      revealed: _revealed.contains(id),
                      selectMode: _selectMode,
                      selected: _selected.contains(id),
                      onToggle: () =>
                          _selectMode ? _toggleSelected(id) : _toggle(id),
                      onLongPress: () => _toggleSelected(id),
                      onNotSpam: () => _markNotSpam(channel, message),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _FilteredMessageCard extends StatelessWidget {
  final Channel channel;
  final ChannelMessage message;
  final bool revealed;
  final bool selectMode;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onNotSpam;

  const _FilteredMessageCard({
    super.key,
    required this.channel,
    required this.message,
    required this.revealed,
    required this.selectMode,
    required this.selected,
    required this.onToggle,
    required this.onLongPress,
    required this.onNotSpam,
  });

  String _relativeTime(BuildContext context, DateTime t) {
    final diff = DateTime.now().difference(t);
    final l10n = context.l10n;
    if (diff.inMinutes < 1) return l10n.channels_timeNow;
    if (diff.inMinutes < 60) return l10n.channels_timeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.channels_timeHours(diff.inHours);
    return l10n.channels_timeDays(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final channelLabel = channel.name.isEmpty
        ? l10n.channels_channelIndex(channel.index)
        : channel.name;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final card = MeshCard(
      onTap: onToggle,
      onLongPress: onLongPress,
      color: selected ? scheme.primary.withValues(alpha: 0.16) : null,
      padding: EdgeInsets.fromLTRB(16, 12, 8, selectMode ? 12 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    channelLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _relativeTime(context, message.receivedAt),
                  style: secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Text(
              messageFilterReasonText(context, message, revealed: revealed),
              style: secondary,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: revealed
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.senderName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          message.text,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.messageFilter_ghostSingle,
                            style: secondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (!selectMode)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onNotSpam,
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text(l10n.messageFilter_notSpam),
              ),
            ),
        ],
      ),
    );
    if (!selectMode) return card;
    return Semantics(
      selected: selected,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 28,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          Expanded(child: card),
        ],
      ),
    );
  }
}

/// The "Filtered: …" line explaining why [message] was hidden.
///
/// Until the card is [revealed] the rule pattern is shortened like the chat
/// placeholder's (a rule made with "Filter messages like this…" can be the
/// whole spam message); once the message itself is shown, the full pattern is.
String messageFilterReasonText(
  BuildContext context,
  ChannelMessage message, {
  bool revealed = false,
}) {
  final l10n = context.l10n;
  if (!revealed) {
    return messageFilterReasonLabel(
      l10n,
      message.filterReason,
      message.filterDetail,
    );
  }
  final detail = message.filterDetail ?? '';
  return switch (filterReasonFromJson(message.filterReason)) {
    FilterReason.senderRule => l10n.messageFilter_reasonSenderRule(detail),
    FilterReason.textRule => l10n.messageFilter_reasonTextRule(detail),
    FilterReason.repeatedCharacters =>
      l10n.messageFilter_reasonRepeatedCharacters,
    FilterReason.duplicate => l10n.messageFilter_reasonDuplicate,
    FilterReason.crossSenderDuplicate =>
      l10n.messageFilter_reasonCrossSenderDuplicate,
    FilterReason.learned => l10n.messageFilter_reasonLearned,
    FilterReason.manual || null => l10n.messageFilter_reasonManual,
  };
}
