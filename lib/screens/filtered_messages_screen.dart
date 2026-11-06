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

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.messageFilter_displayTitle),
        centerTitle: true,
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
                    onToggle: () => _toggle(id),
                    onNotSpam: () => _markNotSpam(channel, message),
                  );
                },
              ),
      ),
    );
  }
}

class _FilteredMessageCard extends StatelessWidget {
  final Channel channel;
  final ChannelMessage message;
  final bool revealed;
  final VoidCallback onToggle;
  final VoidCallback onNotSpam;

  const _FilteredMessageCard({
    super.key,
    required this.channel,
    required this.message,
    required this.revealed,
    required this.onToggle,
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

    return MeshCard(
      onTap: onToggle,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
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
