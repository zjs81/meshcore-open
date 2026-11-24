import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/chat_jump.dart';
import '../helpers/message_search.dart';
import '../helpers/message_url_image_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/bookmarked_message.dart';
import '../services/app_settings_service.dart';
import '../services/chat_text_scale_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/chat_search_results.dart';
import '../widgets/chat_send_pipeline.dart';
import '../widgets/empty_state.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/translated_message_content.dart';

class BookmarksScreen extends StatefulWidget {
  final BookmarkSourceType? initialSourceType;
  final String? initialSourceId;
  final List<String> sourceIdAliases;
  final String? initialSourceName;

  const BookmarksScreen({
    super.key,
    this.initialSourceType,
    this.initialSourceId,
    this.sourceIdAliases = const [],
    this.initialSourceName,
  });

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<BookmarkedMessage>> _bookmarks;
  List<BookmarkedMessage> _loadedBookmarks = const [];
  late bool _filterToInitialSource;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String _searchQuery = '';
  String? _highlightedStorageId;
  Timer? _highlightTimer;

  final Set<String> _selectedIds = <String>{};

  bool get _hasInitialSource => widget.initialSourceId != null;
  bool get _selecting => _selectedIds.isNotEmpty;
  bool get _showSearchResults => _searching && _searchQuery.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _filterToInitialSource = widget.initialSourceId != null;
    _bookmarks = _fetchBookmarks();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<BookmarkedMessage>> _fetchBookmarks() async {
    final loaded = await context
        .read<MeshCoreConnector>()
        .loadBookmarkedMessages();
    if (mounted) {
      _loadedBookmarks = loaded;
    }
    return loaded;
  }

  void _reload() {
    setState(() {
      _bookmarks = _fetchBookmarks();
    });
  }

  bool _matchesInitialSource(
    BookmarkedMessage bookmark,
    MeshCoreConnector connector,
  ) {
    final sourceId = widget.initialSourceId;
    if (sourceId == null) return true;
    if (widget.initialSourceType != null &&
        bookmark.sourceType != widget.initialSourceType) {
      return false;
    }
    final validIds = <String>{sourceId, ...widget.sourceIdAliases};
    if (bookmark.sourceType == BookmarkSourceType.channel) {
      for (final channel in connector.channels) {
        final slotId = 'slot:${channel.index}';
        final storageId = channel.storageId;
        if (validIds.contains(slotId) ||
            (storageId != null && validIds.contains(storageId))) {
          validIds.add(slotId);
          if (storageId != null) validIds.add(storageId);
        }
      }
    }
    return validIds.contains(bookmark.sourceId);
  }

  List<BookmarkedMessage> _filteredBookmarks(
    List<BookmarkedMessage> all,
    MeshCoreConnector connector,
  ) {
    final filtered = [
      for (final bookmark in all)
        if (!_hasInitialSource ||
            !_filterToInitialSource ||
            _matchesInitialSource(bookmark, connector))
          bookmark,
    ];
    filtered.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return filtered;
  }

  void _openSearch() => setState(() => _searching = true);

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
        autofocus: true,
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

  Future<List<ChatSearchEntry>> _loadSearchEntries() async {
    final connector = context.read<MeshCoreConnector>();
    final all = await connector.loadBookmarkedMessages();
    if (mounted) {
      _loadedBookmarks = all;
    }
    final visible = _filteredBookmarks(all, connector);
    return [
      for (final bookmark in visible)
        ChatSearchEntry(
          id: bookmark.storageId,
          sender: '${bookmark.senderName} · ${bookmark.sourceName}',
          text: bookmark.text,
          translatedText: bookmark.translatedText,
          time: bookmark.receivedAt,
          matchSender: true,
        ),
    ];
  }

  Future<void> _jumpToSearchResult(String storageId) async {
    FocusScope.of(context).unfocus();
    _closeSearch();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final connector = context.read<MeshCoreConnector>();
    final visible = _filteredBookmarks(_loadedBookmarks, connector);
    final index = visible.indexWhere((b) => b.storageId == storageId);
    if (index < 0) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chatSearch_jumpFailed),
      );
      return;
    }
    final targetIndex = visible.length - 1 - index;
    if (_scrollController.hasClients) {
      await scrollListToIndex(
        controller: _scrollController,
        targetIndex: targetIndex,
        itemCount: visible.length,
        isMounted: () => mounted,
      );
    }
    if (!mounted) return;
    _highlightTimer?.cancel();
    setState(() => _highlightedStorageId = storageId);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedStorageId = null);
    });
  }

  void _toggleSelected(BookmarkedMessage bookmark) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.remove(bookmark.storageId)) {
        _selectedIds.add(bookmark.storageId);
      }
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  Future<void> _remove(BookmarkedMessage bookmark) async {
    final confirmed = await confirmRemoveBookmarks(context);
    if (!confirmed || !mounted) return;
    await context.read<MeshCoreConnector>().setBookmarkedMessage(
      bookmark,
      isBookmarked: false,
    );
    if (!mounted) return;
    _selectedIds.remove(bookmark.storageId);
    _reload();
  }

  Future<void> _removeSelected() async {
    if (_selectedIds.isEmpty) return;
    final connector = context.read<MeshCoreConnector>();
    final visible = _filteredBookmarks(_loadedBookmarks, connector);
    final toRemove = [
      for (final bookmark in visible)
        if (_selectedIds.contains(bookmark.storageId)) bookmark,
    ];
    final count = toRemove.isNotEmpty ? toRemove.length : _selectedIds.length;
    final confirmed = await confirmRemoveBookmarks(context, count: count);
    if (!confirmed || !mounted) return;
    final targets = toRemove.isNotEmpty
        ? toRemove
        : [
            for (final bookmark in _loadedBookmarks)
              if (_selectedIds.contains(bookmark.storageId)) bookmark,
          ];
    _clearSelection();
    for (final bookmark in targets) {
      await connector.setBookmarkedMessage(bookmark, isBookmarked: false);
    }
    if (mounted) _reload();
  }

  PreferredSizeWidget _buildSelectionAppBar(BuildContext context) {
    final l10n = context.l10n;
    return AppBar(
      leading: IconButton(
        tooltip: l10n.chat_clearSelection,
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text(l10n.chat_selectedCount(_selectedIds.length)),
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: l10n.bookmarks_remove,
          icon: const Icon(Icons.delete_outline),
          onPressed: _selectedIds.isEmpty ? null : _removeSelected,
        ),
      ],
    );
  }

  Widget _buildScopePill(BuildContext context) {
    final sourceLabel =
        (widget.initialSourceName != null &&
            widget.initialSourceName!.trim().isNotEmpty)
        ? widget.initialSourceName!
        : widget.initialSourceId!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MeshRadii.pill),
            ),
          ),
          segments: [
            ButtonSegment<bool>(
              value: false,
              label: MeshSegmentLabel(context.l10n.listFilter_all),
            ),
            ButtonSegment<bool>(
              value: true,
              label: MeshSegmentLabel(sourceLabel),
            ),
          ],
          selected: {_filterToInitialSource},
          onSelectionChanged: (selection) {
            setState(() {
              _filterToInitialSource = selection.first;
              _selectedIds.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildSelectableRow(BookmarkedMessage bookmark, Widget cardBody) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedIds.contains(bookmark.storageId);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(MeshRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          onTap: () => _toggleSelected(bookmark),
          onLongPress: () => _toggleSelected(bookmark),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 28,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: AbsorbPointer(child: cardBody)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final publicIpfsGateway =
        context.watch<AppSettingsService?>()?.settings.publicIpfsGateway ?? '';
    final textScale = context.watch<ChatTextScaleService?>()?.scale ?? 1.0;

    return PopScope(
      canPop: !_searching && !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selecting) {
          _clearSelection();
        } else if (_searching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: _selecting
            ? _buildSelectionAppBar(context)
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
                    : Text(l10n.bookmarks_title),
                centerTitle: !_searching,
                actions: _searching
                    ? null
                    : [
                        IconButton(
                          tooltip: l10n.chatSearch_tooltip,
                          icon: const Icon(Icons.search),
                          onPressed: _openSearch,
                        ),
                      ],
              ),
        body: Column(
          children: [
            if (_hasInitialSource) _buildScopePill(context),
            Expanded(
              child: _showSearchResults
                  ? ChatSearchResults(
                      key: ValueKey<bool>(_filterToInitialSource),
                      query: _searchQuery.trim(),
                      loadEntries: _loadSearchEntries,
                      textScale: textScale,
                      onSelect: (entry) =>
                          unawaited(_jumpToSearchResult(entry.id)),
                    )
                  : FutureBuilder<List<BookmarkedMessage>>(
                      future: _bookmarks,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final connector = context.watch<MeshCoreConnector>();
                        final allBookmarks =
                            snapshot.data ?? const <BookmarkedMessage>[];
                        _loadedBookmarks = allBookmarks;
                        final bookmarks = _filteredBookmarks(
                          allBookmarks,
                          connector,
                        );
                        if (bookmarks.isEmpty) {
                          return EmptyState(
                            icon: Icons.bookmark_border,
                            title: l10n.bookmarks_empty,
                          );
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark =
                                bookmarks[bookmarks.length - 1 - index];
                            final sourceType =
                                bookmark.sourceType ==
                                    BookmarkSourceType.channel
                                ? l10n.bookmarks_channel
                                : l10n.bookmarks_contact;
                            final receivedAt = bookmark.receivedAt.toLocal();
                            final localizations = MaterialLocalizations.of(
                              context,
                            );
                            final time = localizations.formatTimeOfDay(
                              TimeOfDay.fromDateTime(receivedAt),
                              alwaysUse24HourFormat:
                                  MediaQuery.alwaysUse24HourFormatOf(context),
                            );
                            final dateTime =
                                '${localizations.formatShortDate(receivedAt)} $time';
                            final translation = bookmark.translatedText?.trim();
                            final displayText = translation?.isNotEmpty == true
                                ? translation!
                                : bookmark.text;
                            final textStyle =
                                Theme.of(context).textTheme.bodyMedium ??
                                const TextStyle();
                            final scheme = Theme.of(context).colorScheme;
                            final baseCardColor =
                                Theme.of(context).cardTheme.color ??
                                scheme.surfaceContainerLow;
                            final highlighted =
                                bookmark.storageId == _highlightedStorageId;
                            final cardColor = highlighted
                                ? Color.alphaBlend(
                                    scheme.primary.withValues(alpha: 0.18),
                                    baseCardColor,
                                  )
                                : baseCardColor;
                            final textContent = TranslatedMessageContent(
                              displayText: displayText,
                              originalText: displayText == bookmark.text
                                  ? null
                                  : bookmark.text,
                              style: textStyle,
                              originalStyle: textStyle.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              backgroundColor: cardColor,
                              selectable: false,
                            );
                            final card = Card(
                              margin: EdgeInsets.zero,
                              color: cardColor,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  MeshRadii.md,
                                ),
                                onLongPress: _selecting
                                    ? null
                                    : () => _toggleSelected(bookmark),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    8,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              top: 2,
                                              right: 8,
                                            ),
                                            child: Icon(
                                              Icons.bookmark,
                                              size: 20,
                                              color: Color(0xFFFFE54A),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$sourceType · ${bookmark.sourceName}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleSmall,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${bookmark.senderName} · $dateTime',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: l10n.common_copy,
                                            onPressed: () =>
                                                copyChatMessageText(
                                                  context,
                                                  bookmark.text,
                                                ),
                                            icon: const Icon(Icons.copy),
                                          ),
                                          IconButton(
                                            tooltip: l10n.bookmarks_remove,
                                            onPressed: () => _remove(bookmark),
                                            icon: const Icon(
                                              Icons.bookmark_remove_outlined,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (MessageUrlImageHelper.hasPotentialImageUrl(
                                        bookmark.text,
                                      ))
                                        MessageUrlImageFutureBuilder(
                                          messageId: bookmark.messageId,
                                          text: bookmark.text,
                                          publicGateway: publicIpfsGateway,
                                          builder: (context, snapshot) {
                                            final imageUrl = snapshot.data;
                                            if (imageUrl == null) {
                                              return textContent;
                                            }
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: MessageUrlImagePreview(
                                                    imageUrl: imageUrl,
                                                  ),
                                                ),
                                                textContent,
                                              ],
                                            );
                                          },
                                        )
                                      else
                                        textContent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                            final highlightedCard = highlighted
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        MeshRadii.md,
                                      ),
                                    ),
                                    child: card,
                                  )
                                : card;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _selecting
                                  ? _buildSelectableRow(
                                      bookmark,
                                      highlightedCard,
                                    )
                                  : highlightedCard,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
