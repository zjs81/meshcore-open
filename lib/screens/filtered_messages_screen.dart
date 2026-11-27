import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/message_search.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../utils/radio_guard.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/chat_send_pipeline.dart';
import '../widgets/empty_state.dart';
import '../widgets/filtered_message_ghost.dart';
import '../widgets/mesh_ui.dart';

/// Recent filtered channel messages across all channels, newest first, with
/// sender and text. "Not spam" puts a message back in its channel and teaches
/// the filter.
class FilteredMessagesScreen extends StatefulWidget {
  const FilteredMessagesScreen({super.key});

  @override
  State<FilteredMessagesScreen> createState() => _FilteredMessagesScreenState();
}

/// Identity of a row in the Filtered messages list (widget key, selection
/// and pending changes). Message ids do not include the channel and can
/// collide across channels, so they are scoped by the channel's filter id.
String filteredMessageRowId(Channel channel, ChannelMessage message) =>
    '${MeshCoreConnector.messageFilterChannelId(channel)}|${message.messageId}';

/// A change waiting for its Undo snackbar to close.
class _PendingChange {
  final Set<String> rowIds;
  final Future<void> Function() apply;

  _PendingChange(this.rowIds, this.apply);
}

class _FilteredMessagesScreenState extends State<FilteredMessagesScreen> {
  /// Bulk selection: when on, taps toggle rows and the app bar holds the
  /// bulk actions.
  bool _selectMode = false;
  final Set<String> _selected = <String>{};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;
  String _searchQuery = '';

  /// Rows hidden by a change that is waiting for Undo or still being applied.
  final Set<String> _hidden = <String>{};
  _PendingChange? _pending;
  ScaffoldMessengerState? _messenger;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A hidden app draws no frames, so the snackbar would not close.
    _lifecycle = AppLifecycleListener(onHide: _flushPending);
  }

  @override
  void dispose() {
    // Closing the page applies a change still waiting for Undo.
    if (_pending != null) scheduleMicrotask(_flushPending);
    _lifecycle.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

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

  void _bulkNotSpam(List<(Channel, ChannelMessage)> items) {
    if (!ensureRadioConnected(context)) return;
    final connector = context.read<MeshCoreConnector>();
    _deferChange(
      items,
      context.l10n.messageFilter_markedNotSpamCount(items.length),
      () => connector.markChannelMessagesNotSpam(items),
    );
  }

  Future<void> _bulkDelete(List<(Channel, ChannelMessage)> items) async {
    final connector = context.read<MeshCoreConnector>();
    final confirmed = await confirmBulkDelete(context, items.length);
    if (!confirmed || !mounted || !ensureRadioConnected(context)) return;
    _deferChange(
      items,
      context.l10n.chat_messagesDeleted(items.length),
      () => connector.deleteChannelMessages(items.map((e) => e.$2)),
    );
  }

  static String _rowId(Channel channel, ChannelMessage message) =>
      filteredMessageRowId(channel, message);

  void _markNotSpam(Channel channel, ChannelMessage message) {
    if (!ensureRadioConnected(context)) return;
    final connector = context.read<MeshCoreConnector>();
    _deferChange(
      [(channel, message)],
      context.l10n.messageFilter_markedNotSpam,
      () => connector.markChannelMessageNotSpam(channel, message),
    );
  }

  // Focus only on opening, so leaving selection mid-search keeps the
  // keyboard closed.
  void _openSearch() {
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _searchQuery = '';
    });
  }

  Widget _buildSearchField() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
      },
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: context.l10n.chatSearch_hint,
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  List<(Channel, ChannelMessage)> _searchResults(
    List<(Channel, ChannelMessage)> entries,
  ) {
    final needle = normalizeSearchQuery(_searchQuery);
    if (needle.isEmpty) return entries;
    final l10n = context.l10n;
    bool matches(Channel channel, ChannelMessage message) => [
      channel.name.isEmpty
          ? l10n.channels_channelIndex(channel.index)
          : channel.name,
      message.senderName,
      message.text,
    ].any((value) => value.toLowerCase().contains(needle));
    return [
      for (final e in entries)
        if (matches(e.$1, e.$2)) e,
    ];
  }

  /// Hides the rows of [items] and shows [text] with Undo. [apply] runs when
  /// the snackbar closes without Undo, when the page closes or when the app
  /// is hidden.
  void _deferChange(
    List<(Channel, ChannelMessage)> items,
    String text,
    Future<void> Function() apply,
  ) {
    // The new snackbar replaces the previous one, so its change goes now.
    final previous = _pending;
    if (previous != null) unawaited(_apply(previous));
    final change = _PendingChange({
      for (final (channel, message) in items) _rowId(channel, message),
    }, apply);
    _messenger = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _pending = change;
      _hidden.addAll(change.rowIds);
      _selectMode = false;
      _selected.clear();
    });
    // Shown at once: a queued snackbar can be dropped without closing.
    _messenger
      ?..clearSnackBars()
      ..removeCurrentSnackBar();
    final snackBar = showDismissibleSnackBar(
      context,
      content: Text(text),
      action: SnackBarAction(
        label: context.l10n.common_undo,
        onPressed: () => _undo(change),
      ),
    );
    if (snackBar == null) {
      unawaited(_apply(change));
    } else {
      unawaited(snackBar.closed.then((_) => _apply(change)));
    }
  }

  void _undo(_PendingChange change) {
    if (!mounted || !identical(_pending, change)) return;
    setState(() {
      _pending = null;
      _hidden.removeAll(change.rowIds);
    });
  }

  /// Applies [change] unless it was undone or already applied.
  Future<void> _apply(_PendingChange change) async {
    if (!identical(_pending, change)) return;
    _pending = null;
    try {
      await change.apply();
    } finally {
      if (mounted) setState(() => _hidden.removeAll(change.rowIds));
    }
  }

  /// Applies the change waiting for Undo now and closes its snackbar.
  void _flushPending() {
    final change = _pending;
    if (change == null) return;
    if (_messenger?.mounted ?? false) {
      _messenger!
        ..clearSnackBars()
        ..removeCurrentSnackBar();
    }
    unawaited(_apply(change));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final entries = [
      for (final e in connector.recentFilteredChannelMessages())
        if (!_hidden.contains(_rowId(e.$1, e.$2))) e,
    ];
    final visible = _searchResults(entries);
    final selectedEntries = _selectedEntries(visible);
    // Offline the stored history is read-only: no delete or spam marks.
    final readOnly = context.radioReadOnly;

    return PopScope(
      canPop: !_selectMode && !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _flushPending();
        } else if (_selectMode) {
          _exitSelectMode();
        } else if (_searching) {
          _closeSearch();
        }
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
                      _selected.addAll(visible.map((e) => _rowId(e.$1, e.$2)));
                    }),
                  ),
                  IconButton(
                    tooltip: l10n.messageFilter_notSpam,
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: selectedEntries.isEmpty || readOnly
                        ? null
                        : () => _bulkNotSpam(selectedEntries),
                  ),
                  IconButton(
                    tooltip: l10n.common_delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: selectedEntries.isEmpty || readOnly
                        ? null
                        : () => _bulkDelete(selectedEntries),
                  ),
                ],
              )
            : AppBar(
                leading: _searching
                    ? IconButton(
                        tooltip: l10n.chatSearch_close,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _closeSearch,
                      )
                    : null,
                title: _searching
                    ? _buildSearchField()
                    : AdaptiveAppBarTitle(l10n.messageFilter_displayTitle),
                centerTitle: !_searching,
                actions: _searching || entries.isEmpty
                    ? null
                    : [
                        IconButton(
                          tooltip: l10n.chatSearch_tooltip,
                          icon: const Icon(Icons.search),
                          onPressed: _openSearch,
                        ),
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
                  icon: Icons.inbox_outlined,
                  title: l10n.messageFilter_filteredMessagesEmpty,
                )
              : visible.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: l10n.chatSearch_noResults,
                  subtitle: l10n.chatSearch_noResultsHint,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final (channel, message) = visible[index];
                    final id = _rowId(channel, message);
                    return _FilteredMessageCard(
                      key: ValueKey('filtered_$id'),
                      channel: channel,
                      message: message,
                      selectMode: _selectMode,
                      selected: _selected.contains(id),
                      onToggle: () => _toggleSelected(id),
                      onNotSpam: readOnly
                          ? null
                          : () => _markNotSpam(channel, message),
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
  final bool selectMode;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback? onNotSpam;

  const _FilteredMessageCard({
    super.key,
    required this.channel,
    required this.message,
    required this.selectMode,
    required this.selected,
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

    final card = MeshCard(
      onTap: selectMode ? onToggle : null,
      onLongPress: onToggle,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageFilterReasonLabel(
                    l10n,
                    message.filterReason,
                    message.filterDetail,
                    shorten: false,
                  ),
                  style: secondary,
                ),
                const SizedBox(height: 8),
                Text(
                  message.senderName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                // Plain text while selecting, so a tap selects the row.
                selectMode
                    ? Text(message.text, style: theme.textTheme.bodyLarge)
                    : SelectableText(
                        message.text,
                        style: theme.textTheme.bodyLarge,
                      ),
              ],
            ),
          ),
          if (!selectMode)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onNotSpam,
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: Text(l10n.messageFilter_notSpam),
              ),
            ),
        ],
      ),
    );
    if (!selectMode) return card;
    return Semantics(
      selected: selected,
      // The check circle sits outside the card, so it toggles the row too.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onToggle,
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
      ),
    );
  }
}
