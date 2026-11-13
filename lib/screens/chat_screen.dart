import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/app_logger.dart';
import '../utils/platform_info.dart';
import '../utils/radio_guard.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/chat_jump.dart';
import '../helpers/cyr2lat.dart';
import '../helpers/message_url_image_helper.dart';
import '../helpers/path_helper.dart';
import '../helpers/reaction_helper.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/empty_state.dart';
import '../helpers/chat_scroll_controller.dart';
import '../helpers/gif_helper.dart';
import '../helpers/ipfs_link_attach_flow.dart';
import '../helpers/contact_share_message.dart';
import '../helpers/marker_message.dart';
import '../helpers/message_search.dart';
import '../widgets/chat_search_results.dart';
import '../models/channel_message.dart';
import '../models/bookmarked_message.dart';
import '../models/contact.dart';
import '../l10n/contact_localization.dart';
import '../models/message.dart';
import '../services/app_settings_service.dart';
import '../services/chat_text_scale_service.dart';
import '../services/path_history_service.dart';
import '../services/translation_service.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_send_pipeline.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/message_bubble_frame.dart';
import '../widgets/reaction_chips.dart';
import '../widgets/chat_day_separator.dart';
import 'channel_message_path_screen.dart';
import 'contacts_screen.dart' show confirmRemoveContact;
import 'map_screen.dart';
import 'repeater_hub_screen.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/gif_message.dart';
import '../widgets/jump_to_bottom_button.dart';
import '../widgets/routing_sheet.dart';
import '../widgets/room_login_dialog.dart';
import '../widgets/radio_stats_entry.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/translated_message_content.dart';
import '../l10n/l10n.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/unread_divider.dart';
import '../theme/mesh_theme.dart';
import '../widgets/future_timestamp_indicator.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/share_contact_sheet.dart';
import '../widgets/shared_contact_card.dart';
import 'telemetry_screen.dart';
import '../services/chat_background_service.dart';
import '../widgets/chat_background.dart';
import '../widgets/holiday_animations.dart';

// Image messages are deliberately absent from this screen, and there is no
// flag to flip: the AEIC wire format is `CMD_SEND_CHANNEL_DATA` (62) /
// GRP_DATA 0x06, which addresses a channel index rather than a contact key,
// and the companion protocol has no direct-message equivalent (there is no
// CMD_SEND_DATA — see `meshcore_protocol.dart`). Sending a private photo on
// channel 0 to reach one contact would broadcast it to everyone on that
// channel. Channel chats keep the feature; see `channel_chat_screen.dart`.

class ChatScreen extends StatefulWidget {
  final Contact contact;
  final int initialUnreadCount;

  const ChatScreen({
    super.key,
    required this.contact,
    this.initialUnreadCount = 0,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _holidayWatcher = HolidayTriggerWatcher();
  final _messageAreaKey = GlobalKey();
  final _textController = TextEditingController();
  final _scrollController = ChatScrollController();
  final _textFieldFocusNode = FocusNode();
  final GlobalKey _unreadScrollKey = GlobalKey();
  bool _isLoadingOlder = false;
  bool _showBookmarkedOnly = false;
  MeshCoreConnector? _connector;
  Message? _pendingUnreadScrollTarget;
  String? _unreadDividerMessageId;
  final ChatSendGuard _sendGuard = ChatSendGuard();

  /// The chat currently registered as the visible conversation. Screens
  /// register while their route is uncovered and unregister when a page is
  /// pushed over them (a nested room poster chat, a chat opened from a
  /// notification, …), re-registering when it is popped. Only the owner
  /// clears the registration, so a screen disposed after the one underneath
  /// re-registered cannot wipe it out.
  static _ChatScreenState? _activeOwner;
  ModalRoute<dynamic>? _route;

  void _registerActive() {
    final connector = _connector;
    if (connector == null) return;
    _activeOwner = this;
    connector.setActiveContact(widget.contact.publicKeyHex);
  }

  void _unregisterActive() {
    if (!identical(_activeOwner, this)) return;
    _activeOwner = null;
    _connector?.setActiveContact(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      _route?.secondaryAnimation?.removeStatusListener(_onCoveringRouteStatus);
      _route = route;
      route?.secondaryAnimation?.addStatusListener(_onCoveringRouteStatus);
    }
  }

  void _onCoveringRouteStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.dismissed) {
      _registerActive();
    } else {
      // Not just `forward`: a page pushed without a transition jumps
      // straight to `completed`.
      _unregisterActive();
    }
  }

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(_onTextFieldFocusChange);
    _scrollController.onScrollNearTop = _loadOlderMessages;
    _scrollController.showJumpToBottom.addListener(_clearDividerAtBottom);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final connector = context.read<MeshCoreConnector>();
      final settings = context.read<AppSettingsService>().settings;
      final unread = widget.initialUnreadCount;
      final messages = connector.getMessages(widget.contact);
      Message? anchor;
      if (unread > 0) {
        anchor = _findOldestUnreadAnchor(messages, unread);
      }
      setState(() {
        if (anchor != null) _unreadDividerMessageId = anchor.messageId;
        if (anchor != null && settings.jumpToOldestUnread) {
          _pendingUnreadScrollTarget = anchor;
        }
      });
      _connector = connector;
      if (_route?.isCurrent ?? true) _registerActive();
      if (anchor != null && settings.jumpToOldestUnread) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollController.jumpToEstimatedOffset(
            unreadCount: unread,
            totalMessages: messages.length,
            onJumped: () async {
              if (!mounted) return;
              final ctx = _unreadScrollKey.currentContext;
              if (ctx != null) {
                await Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 350),
                  alignment: 0.15,
                );
              }
              if (mounted) {
                setState(() => _pendingUnreadScrollTarget = null);
              }
            },
          );
        });
      }
    });
  }

  Message? _findOldestUnreadAnchor(List<Message> messages, int unreadCount) {
    if (unreadCount <= 0 || messages.isEmpty) return null;
    var n = 0;
    Message? oldest;
    for (final m in messages.reversed) {
      if (m.isOutgoing || m.isCli) continue;
      n++;
      oldest = m;
      if (n >= unreadCount) break;
    }
    return oldest;
  }

  void _clearDividerAtBottom() {
    if (!_scrollController.showJumpToBottom.value &&
        _unreadDividerMessageId != null) {
      setState(() => _unreadDividerMessageId = null);
    }
  }

  void _onTextFieldFocusChange() {
    if (_textFieldFocusNode.hasFocus && mounted) {
      _scrollController.handleKeyboardOpen();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    setState(() => _isLoadingOlder = true);

    final connector = context.read<MeshCoreConnector>();
    await connector.loadOlderMessages(widget.contact.publicKeyHex);

    if (mounted) {
      setState(() => _isLoadingOlder = false);
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onCoveringRouteStatus);
    _unregisterActive();
    _scrollController.showJumpToBottom.removeListener(_clearDividerAtBottom);
    _textFieldFocusNode.removeListener(_onTextFieldFocusChange);
    _textFieldFocusNode.dispose();
    _textController.dispose();
    _searchController.dispose();
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool _searching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool get _showSearchResults => _searching && _searchQuery.trim().isNotEmpty;

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

  Widget _buildSearchResults(
    Future<List<ChatSearchEntry>> Function() loadEntries,
  ) {
    return ChatSearchResults(
      query: _searchQuery.trim(),
      loadEntries: loadEntries,
      textScale: context.watch<ChatTextScaleService>().scale,
      onSelect: (entry) => unawaited(_jumpToSearchResult(entry.id)),
    );
  }

  /// Message briefly highlighted after jumping to it from search.
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  /// Closes search and scrolls the conversation to [messageId], loading
  /// older pages first when the message is further back than what is loaded.
  Future<void> _jumpToSearchResult(String messageId) async {
    FocusScope.of(context).unfocus();
    _closeSearch();
    final connector = context.read<MeshCoreConnector>();
    final keyHex = widget.contact.publicKeyHex;
    int indexOf() => connector
        .getMessages(widget.contact)
        .indexWhere((m) => m.messageId == messageId);
    for (var page = 0; page < 500 && indexOf() < 0; page++) {
      if (!mounted) return;
      if (_isLoadingOlder) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      setState(() => _isLoadingOlder = true);
      final older = await connector.loadOlderMessages(keyHex);
      if (!mounted) return;
      setState(() => _isLoadingOlder = false);
      if (older.isEmpty) break;
    }
    // Let the list (rebuilt after closing search) lay out.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final messages = connector.getMessages(widget.contact);
    final index = indexOf();
    // The list is reversed: newest message is row 0.
    final found =
        index >= 0 &&
        await scrollListToIndex(
          controller: _scrollController,
          targetIndex: messages.length - 1 - index,
          itemCount: messages.length,
          isMounted: () => mounted,
        );
    if (!mounted) return;
    if (!found) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chatSearch_jumpFailed),
      );
      return;
    }
    _highlightTimer?.cancel();
    setState(() => _highlightedMessageId = messageId);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  Future<List<ChatSearchEntry>> _loadSearchEntries() async {
    final connector = context.read<MeshCoreConnector>();
    final contact = _resolveContact(connector);
    final isRoom = contact.type == advTypeRoom;
    final youLabel = context.l10n.notification_you;
    final messages = await connector.allMessagesForSearch(
      widget.contact.publicKeyHex,
    );
    String senderOf(Message m) {
      if (m.isOutgoing) return youLabel;
      if (!isRoom) return contact.name;
      // Room posts name their author by a 4-byte key prefix, as in the list.
      final key = m.fourByteRoomContactKey;
      final hex = key
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
      final author = key.isEmpty
          ? null
          : _resolveContactFrom4Bytes(connector, key);
      return author != null ? '${author.name} [$hex]' : '[$hex]';
    }

    return [
      for (final m in messages)
        if (!m.isCli)
          ChatSearchEntry(
            id: m.messageId,
            sender: senderOf(m),
            text: m.text,
            translatedText: m.translatedText,
            time: m.receivedAt,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searching) _closeSearch();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _searching
            ? IconButton(
                tooltip: context.l10n.chatSearch_close,
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeSearch,
              )
            : null,
        title: _searching
            ? _buildSearchField()
            : Consumer2<PathHistoryService, MeshCoreConnector>(
                builder: (context, pathService, connector, _) {
                  final contact = _resolveContact(connector);
                  final pathLabel = _currentPathLabel(contact);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            ContactRoutingSheet.show(context, contact: contact),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Builder(
                            builder: (context) {
                              // Follows the chat text size, capped so the two-line
                              // title still fits the app bar.
                              final textScale = context
                                  .select<ChatTextScaleService, double>(
                                    (service) => service.scale,
                                  )
                                  .clamp(1.0, 1.3);
                              return Text(
                                pathLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12 * textScale,
                                  fontWeight: FontWeight.normal,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        centerTitle: false,
        bottom: const SyncProgressAppBarBottom(),
        actionsPadding: const EdgeInsetsDirectional.only(end: 4),
        // While searching the field gets the whole bar; the leading arrow
        // closes the search.
        actions: _searching
            ? null
            : [
                const RadioStatsIconButton(),
                IconButton(
                  tooltip: context.l10n.chatSearch_tooltip,
                  icon: const Icon(Icons.search),
                  onPressed: _openSearch,
                ),
                Consumer<MeshCoreConnector>(
                  builder: (context, connector, _) {
                    final contact = _resolveContact(connector);
                    final isRoom = contact.type == advTypeRoom;
                    final readOnly = isRadioReadOnly(connector);

                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'routing':
                            ContactRoutingSheet.show(context, contact: contact);
                          case 'info':
                            _showContactInfo(context);
                          case 'settings':
                            _showContactSettings(context);
                          case 'showBookmarks':
                            setState(
                              () => _showBookmarkedOnly = !_showBookmarkedOnly,
                            );
                          case 'background':
                            showChatBackgroundSheet(
                              context,
                              ChatBackgroundService.contactKey(contact),
                            );
                          case 'telemetry':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TelemetryScreen(contact: widget.contact),
                              ),
                            );
                          case 'roomManagement':
                            _showRoomManagementLogin(contact);
                          case 'clearChat':
                            _confirmClearChat(context, connector);
                          case 'removeContact':
                            confirmRemoveContact(
                              context,
                              connector,
                              contact,
                              onRemoved: () {
                                if (mounted) Navigator.of(context).pop();
                              },
                            );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'routing',
                          child: MeshMenuItemRow(
                            icon: Icons.route,
                            label: context.l10n.routing_title,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'info',
                          child: MeshMenuItemRow(
                            icon: Icons.info_outline,
                            label: context.l10n.contact_info,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'telemetry',
                          enabled: !readOnly,
                          child: MeshMenuItemRow(
                            icon: Icons.bar_chart,
                            label: context.l10n.contact_telemetry,
                          ),
                        ),
                        if (isRoom)
                          PopupMenuItem(
                            value: 'roomManagement',
                            enabled: !readOnly,
                            child: MeshMenuItemRow(
                              icon: Icons.room_preferences,
                              label: context.l10n.room_management,
                            ),
                          ),
                        PopupMenuItem(
                          value: 'settings',
                          child: MeshMenuItemRow(
                            icon: Icons.settings,
                            label: context.l10n.contact_settings,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'showBookmarks',
                          child: MeshMenuItemRow(
                            icon: _showBookmarkedOnly
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: context.l10n.chat_showBookmarks,
                            color: _showBookmarkedOnly
                                ? const Color(0xFFFFE54A)
                                : null,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'background',
                          child: MeshMenuItemRow(
                            icon: Icons.wallpaper,
                            label: context.l10n.chatBackground_title,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clearChat',
                          enabled: !readOnly,
                          child: MeshMenuItemRow(
                            icon: Icons.delete,
                            label: context.l10n.contact_clearChat,
                            color: readOnly
                                ? null
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'removeContact',
                          enabled: !readOnly,
                          child: MeshMenuItemRow(
                            icon: Icons.person_remove,
                            label: context.l10n.contacts_removeFromContacts,
                            color: readOnly
                                ? null
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
      ),
      body: _showSearchResults
          ? _buildSearchResults(_loadSearchEntries)
          : Consumer<MeshCoreConnector>(
              builder: (context, connector, child) {
                final messages = connector.getMessages(widget.contact);
                final newest = messages.isEmpty ? null : messages.last;
                _holidayWatcher.onNewest(
                  context,
                  id: newest?.messageId,
                  texts: [newest?.text, newest?.translatedText],
                  receivedAt: newest?.receivedAt,
                  originOf: () => newestMessageOrigin(
                    _messageAreaKey,
                    isOutgoing: newest?.isOutgoing ?? false,
                  ),
                );
                return Column(
                  children: [
                    Expanded(
                      child: ChatBackdrop(
                        key: _messageAreaKey,
                        chatKey: ChatBackgroundService.contactKey(
                          widget.contact,
                        ),
                        child: Stack(
                          children: [
                            messages.isEmpty
                                ? _buildEmptyState()
                                : _buildMessageList(messages, connector),
                            JumpToBottomButton(
                              scrollController: _scrollController,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildInputBar(connector),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    if (_showBookmarkedOnly) return _buildBookmarkEmptyState();
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: context.l10n.chat_noMessages,
      subtitle: context.l10n.chat_sendMessageTo(
        _resolveContact(context.read<MeshCoreConnector>()).name,
      ),
    );
  }

  Widget _buildBookmarkEmptyState() => EmptyState(
    icon: Icons.bookmark_border,
    title: context.l10n.bookmarks_empty,
  );

  Widget _buildMessageList(
    List<Message> messages,
    MeshCoreConnector connector,
  ) {
    final visibleMessages = _showBookmarkedOnly
        ? messages.where((message) => message.isBookmarked).toList()
        : messages;
    if (_showBookmarkedOnly && visibleMessages.isEmpty) {
      return _buildBookmarkEmptyState();
    }
    // Reverse messages so newest appear at bottom with reverse: true
    final reversedMessages = visibleMessages.reversed.toList();
    final itemCount = reversedMessages.length + (_isLoadingOlder ? 1 : 0);

    // Auto-scroll to bottom if user is already at bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pendingUnreadScrollTarget != null) return;
      _scrollController.scrollToBottomIfAtBottom();
    });

    return ChatZoomWrapper(
      child: ListView.builder(
        reverse: true, // List grows from bottom up
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Loading indicator now appears at end (bottom) of reversed list
          if (_isLoadingOlder && index == itemCount - 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final messageIndex = index;
          Contact contact = _resolveContact(connector);
          final bool isRoom = contact.type == advTypeRoom;
          final message = reversedMessages[messageIndex];
          String fourByteHex = '';
          Contact? roomAuthor;
          if (isRoom) {
            // Room-server messages carry the original author's 4-byte prefix
            // separately from message.text; use it only for resolving the name.
            roomAuthor = _resolveContactFrom4Bytes(
              connector,
              message.fourByteRoomContactKey.isEmpty
                  ? Uint8List.fromList([0, 0, 0, 0])
                  : message.fourByteRoomContactKey,
            );
            fourByteHex = message.fourByteRoomContactKey
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();
            // Only adopt the author identity when we actually know them; never
            // fall back to the room server's own name as the sender.
            if (roomAuthor != null) contact = roomAuthor;
          }

          return Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              final bubble = _MessageBubble(
                message: message,
                senderName: isRoom
                    ? (roomAuthor != null
                          ? "${roomAuthor.name} [$fourByteHex]"
                          : "[$fourByteHex]")
                    : contact.name,
                sourceId: widget.contact.publicKeyHex,
                textScale: textScale,
                isBookmarked: message.isBookmarked || _showBookmarkedOnly,
                onLongPress: () => _showMessageActions(message, contact),
                onRetryReaction: (msg, emoji) =>
                    _sendReaction(msg, contact, emoji),
              );
              final isUnreadAnchor =
                  _unreadDividerMessageId != null &&
                  message.messageId == _unreadDividerMessageId;
              final startsDay =
                  messageIndex == reversedMessages.length - 1 ||
                  !isSameChatDay(
                    reversedMessages[messageIndex + 1].receivedAt,
                    message.receivedAt,
                  );
              final highlighted = message.messageId == _highlightedMessageId;
              final shown = highlighted
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(MeshRadii.md),
                      ),
                      child: bubble,
                    )
                  : bubble;
              final child = isUnreadAnchor || startsDay
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (startsDay)
                          ChatDaySeparator(day: message.receivedAt),
                        if (isUnreadAnchor) const UnreadDivider(),
                        shown,
                      ],
                    )
                  : shown;
              if (identical(message, _pendingUnreadScrollTarget)) {
                return KeyedSubtree(key: _unreadScrollKey, child: child);
              }
              return child;
            },
          );
        },
      ),
    );
  }

  void _markAsUnread(Message message) {
    final connector = context.read<MeshCoreConnector>();
    final messages = connector.getMessages(widget.contact);
    var count = 0;
    var found = false;
    for (final m in messages) {
      if (m.messageId == message.messageId) found = true;
      if (found && !m.isOutgoing && !m.isCli) count++;
    }
    connector.setContactUnreadCount(widget.contact.publicKeyHex, count);
  }

  Widget _buildInputBar(MeshCoreConnector connector) {
    final keyHex = widget.contact.publicKeyHex;
    final useEncoder =
        connector.isContactSmazEnabled(keyHex) ||
        connector.isContactCyr2LatEnabled(keyHex);
    return ChatComposer(
      controller: _textController,
      focusNode: _textFieldFocusNode,
      maxBytes: maxContactMessageBytes(),
      softLimitBytes: maxTextPayloadBytesAfterFullLengthAttempts,
      softLimitNote: context.l10n.chat_longMessageRetryNote(
        maxFullLengthTextAttempt + 1,
      ),
      encoder: useEncoder
          ? (text) => connector.prepareContactOutboundText(widget.contact, text)
          : null,
      onSend: () => _sendMessage(connector),
      sendTooltip: context.l10n.chat_sendMessageTo(
        _resolveContact(connector).name,
      ),
      actionsBuilder: () {
        final showIpfsAction = context
            .read<AppSettingsService>()
            .settings
            .uploadIpfsEndpoint
            .trim()
            .isNotEmpty;
        return [
          ChatComposerAction(
            id: 'gif',
            icon: Icons.gif_box,
            label: context.l10n.chat_sendGif,
          ),
          if (showIpfsAction)
            ChatComposerAction(
              id: 'ipfs-image',
              icon: Icons.cloud_upload_outlined,
              label: context.l10n.chat_sendImageIpfs,
            ),
          ChatComposerAction(
            id: 'send-my-location',
            icon: Icons.my_location,
            label: context.l10n.chat_shareMyLocation,
          ),
          ChatComposerAction(
            id: 'share-contact',
            icon: Icons.person_add_alt,
            label: context.l10n.contactShare_shareAction,
          ),
        ];
      },
      onAction: (action) {
        if (!mounted) return;
        switch (action) {
          case 'gif':
            showChatGifPicker(context, _textController);
          case 'ipfs-image':
            _sendImageViaIpfs();
          case 'send-my-location':
            _shareMyLocation(context.read<MeshCoreConnector>());
          case 'share-contact':
            showShareContactSheet(
              context,
              _textController,
              focusNode: _textFieldFocusNode,
            );
        }
      },
    );
  }

  Future<void> _sendImageViaIpfs() {
    final connector = context.read<MeshCoreConnector>();
    final contact = _resolveContact(connector);
    return attachIpfsLinkToDraft(
      context: context,
      controller: _textController,
      focusNode: _textFieldFocusNode,
      maxBytes: maxContactMessageBytes(),
      encodeOutbound: (text) =>
          connector.prepareContactOutboundText(contact, text),
    );
  }

  /// Shares the radio's own position as a map marker. Shares the text send
  /// guard and cooldown so it can't race or flood alongside typed messages.
  Future<void> _shareMyLocation(MeshCoreConnector connector) async {
    if (!ensureRadioConnected(context)) return;
    return shareMyLocationMarker(
      context: context,
      connector: connector,
      guard: _sendGuard,
      send: (markerText) =>
          connector.sendMessage(_resolveContact(connector), markerText),
    );
  }

  Future<void> _sendMessage(MeshCoreConnector connector) {
    return _sendGuard.runExclusive(() => _sendMessageInner(connector));
  }

  Future<void> _sendMessageInner(MeshCoreConnector connector) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    // Before anything clears the text box: offline the draft must stay.
    if (!ensureRadioConnected(context)) return;
    if (!_sendGuard.checkCooldown(context)) return;

    final translation = await translateOutgoingText(context, text);
    if (translation == null || !mounted) return;
    // The link can drop while the translation runs.
    if (!ensureRadioConnected(context)) return;
    var outgoingText = translation.text;

    final maxBytes = maxContactMessageBytes();
    final outboundText = connector.prepareContactOutboundText(
      _resolveContact(connector),
      outgoingText,
    );
    if (utf8.encode(outboundText).length > maxBytes) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_messageTooLong(maxBytes)),
      );
      return;
    }

    // This is only for cyr2lat compression - to see the message being sent in the same format as the other person will receive
    try {
      if (connector.isContactCyr2LatEnabled(
        _resolveContact(connector).publicKeyHex,
      )) {
        outgoingText = Cyr2Lat.encode(outgoingText);
      }
    } catch (_) {
      // TODO maybe log
    }
    // end transform

    // Keep anything the user typed while translation was running.
    if (_textController.text.trim() == text) {
      _textController.clear();
    }
    _textFieldFocusNode.requestFocus();
    connector.sendMessage(
      _resolveContact(connector),
      outgoingText,
      originalText: translation.originalText,
      translatedLanguageCode: translation.languageCode,
      translationModelId: translation.modelId,
    );
    // Only a dispatched send starts the cooldown.
    _sendGuard.markDispatched();
  }

  Future<void> _confirmClearChat(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final confirmed = await confirmClearChat(
      context,
      message: context.l10n.chat_clearChatConfirm,
    );
    if (!context.mounted) return;
    if (confirmed && ensureRadioConnected(context)) {
      connector.clearMessagesForContact(widget.contact);
    }
  }

  int _resolveContactIndex = -1;

  Contact _resolveContact(MeshCoreConnector connector) {
    if (_resolveContactIndex >= 0 &&
        _resolveContactIndex < connector.contacts.length &&
        connector.contacts[_resolveContactIndex].publicKeyHex ==
            widget.contact.publicKeyHex) {
      return connector.contacts[_resolveContactIndex];
    }
    _resolveContactIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
    );
    if (_resolveContactIndex == -1) {
      return widget.contact;
    }
    return connector.contacts[_resolveContactIndex];
  }

  Contact? _resolveContactFrom4Bytes(
    MeshCoreConnector connector,
    Uint8List key4Bytes,
  ) {
    // Match against saved contacts first, then nodes only seen via discovery —
    // a room poster you haven't saved may still be in the discovered list.
    return connector.allContactsUnfiltered.cast<Contact?>().firstWhere(
      (c) =>
          c != null &&
          listEquals(c.publicKey.sublist(0, 4), key4Bytes.sublist(0, 4)),
      orElse: () => null,
    );
  }

  String _currentPathLabel(Contact contact) {
    final connector = context.read<MeshCoreConnector>();

    // Check if user has set a path override
    if (contact.pathOverride != null) {
      if (contact.pathOverride! < 0) return context.l10n.chat_floodForced;
      if (contact.pathOverride == 0) return context.l10n.chat_directForced;
      final bytes = contact.pathOverrideBytes ?? Uint8List(0);
      final hopCount = _displayHopCount(
        bytes,
        contact.pathOverride!,
        connector.pathHashByteWidth,
      );
      return context.l10n.chat_hopsForced(hopCount);
    }

    // Use device's path
    if (contact.pathLength < 0) return context.l10n.chat_floodAuto;
    if (contact.pathLength == 0) return context.l10n.chat_direct;
    final hopCount = _displayHopCount(
      contact.path,
      contact.pathLength,
      contact.pathHashWidth,
    );
    return context.l10n.chat_hopsCount(hopCount);
  }

  int _displayHopCount(List<int> pathBytes, int storedHopCount, int hashWidth) {
    if (pathBytes.isEmpty) return storedHopCount;
    return PathHelper.splitPathBytes(pathBytes, hashWidth).length;
  }

  /// Room management needs its own login (it may be as admin), as from the
  /// contact list.
  void _showRoomManagementLogin(Contact room) {
    showDialog(
      context: context,
      builder: (_) => RoomLoginDialog(
        room: room,
        onLogin: (password, isAdmin) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RepeaterHubScreen(
                repeater: room,
                password: password,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showContactInfo(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final contact = _resolveContact(connector);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: SelectableText(contact.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                context.l10n.chat_type,
                contact.typeLabel(context.l10n),
              ),
              _buildInfoRow(
                context.l10n.chat_path,
                contact.pathLabel(
                  context.l10n,
                  pathHashByteWidth: connector.pathHashByteWidth,
                ),
              ),
              _buildInfoRow(
                context.l10n.contact_lastSeen,
                _formatContactLastMessage(contact.lastMessageAt),
              ),
              if (contact.hasLocation)
                _buildInfoRow(
                  context.l10n.chat_location,
                  '${contact.latitude?.toStringAsFixed(4)}, ${contact.longitude?.toStringAsFixed(4)}',
                ),
              _buildInfoRow(context.l10n.chat_publicKey, contact.publicKeyHex),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  void _showContactSettings(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final appSettingsService = Provider.of<AppSettingsService>(
      context,
      listen: false,
    );
    connector.ensureContactSmazSettingLoaded(widget.contact.publicKeyHex);
    connector.ensureContactCyr2LatSettingLoaded(widget.contact.publicKeyHex);
    // The live contact carries the current telemetry flags; widget.contact
    // is the snapshot this screen was opened with.
    final contact = _resolveContact(connector);
    bool smazEnabled = connector.isContactSmazEnabled(contact.publicKeyHex);
    bool cyr2latEnabled = connector.isContactCyr2LatEnabled(
      contact.publicKeyHex,
    );
    bool urlImagesEnabled = connector.isContactUrlImagesEnabled(
      contact.publicKeyHex,
    );
    final loadLinkImages = context
        .read<AppSettingsService>()
        .settings
        .loadLinkImages;
    String? selectedCyr2LatProfileId = connector.getContactCyr2LatProfileId(
      contact.publicKeyHex,
    );
    bool teleBaseEnabled = contact.teleBaseEnabled;
    bool teleLocEnabled = contact.teleLocEnabled;
    bool teleEnvEnabled = contact.teleEnvEnabled;
    // Each toggle is committed immediately, like the compression switches,
    // so dismissing the dialog by tapping outside keeps the change. All three
    // flags are sent every time so overlapping writes can't undo each other.
    void commitTelemetryFlags() {
      connector.setContactFlags(
        contact,
        teleBase: teleBaseEnabled,
        teleLoc: teleLocEnabled,
        teleEnv: teleEnvEnabled,
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.contact_settings),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.hasLocation) ...[
                  _buildInfoRow(
                    context.l10n.chat_location,
                    '${contact.latitude?.toStringAsFixed(4)}, ${contact.longitude?.toStringAsFixed(4)}',
                  ),
                  const Divider(height: 8),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.channels_smazCompression),
                  subtitle: Text(context.l10n.chat_compressOutgoingMessages),
                  value: smazEnabled,
                  onChanged: (value) {
                    connector.setContactSmazEnabled(
                      contact.publicKeyHex,
                      value,
                    );
                    connector.setContactCyr2LatEnabled(
                      contact.publicKeyHex,
                      false,
                    );
                    setDialogState(() {
                      smazEnabled = value;
                      if (smazEnabled) {
                        cyr2latEnabled = false;
                      }
                    });
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.channels_cyr2latCompression),
                  subtitle: Text(context.l10n.channels_cyr2latCompressionDscr),
                  value: cyr2latEnabled,
                  onChanged: (value) {
                    connector.setContactCyr2LatEnabled(
                      contact.publicKeyHex,
                      value,
                    );
                    connector.setContactSmazEnabled(
                      contact.publicKeyHex,
                      false,
                    );
                    setDialogState(() {
                      cyr2latEnabled = value;
                      if (cyr2latEnabled) {
                        smazEnabled = false;
                      }
                    });
                  },
                ),
                if (cyr2latEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedCyr2LatProfileId,
                      decoration: InputDecoration(
                        labelText:
                            context.l10n.channels_cyr2latSettingsSubheading,
                        border: const OutlineInputBorder(),
                      ),
                      items: appSettingsService.settings.cyr2latProfiles.map((
                        profile,
                      ) {
                        return DropdownMenuItem(
                          value: profile.id,
                          child: Text(
                            profile.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        connector.setContactCyr2LatProfileId(
                          contact.publicKeyHex,
                          value,
                        );
                        setDialogState(() {
                          selectedCyr2LatProfileId = value;
                        });
                      },
                    ),
                  ),
                ],
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.urlImage_enable),
                  subtitle: loadLinkImages
                      ? null
                      : Text(context.l10n.urlImage_disabledInAppSettings),
                  value: urlImagesEnabled,
                  onChanged: loadLinkImages
                      ? (value) {
                          connector.setContactUrlImagesEnabled(
                            contact.publicKeyHex,
                            value,
                          );
                          setDialogState(() => urlImagesEnabled = value);
                        }
                      : null,
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleBase),
                  subtitle: Text(context.l10n.contact_teleBaseSubtitle),
                  value: teleBaseEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleBaseEnabled = value);
                    commitTelemetryFlags();
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleLoc),
                  subtitle: Text(context.l10n.contact_teleLocSubtitle),
                  value: teleLocEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleLocEnabled = value);
                    commitTelemetryFlags();
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleEnv),
                  subtitle: Text(context.l10n.contact_teleEnvSubtitle),
                  value: teleEnvEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleEnvEnabled = value);
                    commitTelemetryFlags();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.common_close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  String _formatContactLastMessage(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.isNegative || diff.inMinutes < 5) {
      return context.l10n.contacts_lastSeenNow;
    }
    if (diff.inMinutes < 60) {
      return context.l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1
          ? context.l10n.contacts_lastSeenHourAgo
          : context.l10n.contacts_lastSeenHoursAgo(hours);
    }
    final days = diff.inDays;
    return days == 1
        ? context.l10n.contacts_lastSeenDayAgo
        : context.l10n.contacts_lastSeenDaysAgo(days);
  }

  void _openChat(BuildContext context, Contact contact) {
    final connector = context.read<MeshCoreConnector>();
    final unread = connector.getUnreadCountForContactKey(contact.publicKeyHex);
    connector.markContactRead(contact.publicKeyHex);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(contact: contact, initialUnreadCount: unread),
      ),
    );
  }

  void _openMessagePath(
    Message message,
    Contact contact, {
    bool openMap = false,
  }) {
    final connector = context.read<MeshCoreConnector>();
    final fourByteHex = message.fourByteRoomContactKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final String senderName;
    if (message.isOutgoing) {
      senderName = connector.selfName ?? context.l10n.chat_me;
    } else if (_resolveContact(connector).type == advTypeRoom) {
      // An unresolved author leaves `contact` as the room server itself; show
      // only the prefix rather than mislabeling the post with the room's name.
      senderName = contact.type == advTypeRoom
          ? "[$fourByteHex]"
          : "${contact.name} [$fourByteHex]";
    } else {
      senderName = _resolveContact(connector).name;
    }
    final pathMessage = ChannelMessage(
      senderKey: null,
      senderName: senderName,
      text: message.text,
      timestamp: message.timestamp,
      isOutgoing: message.isOutgoing,
      status: ChannelMessageStatus.sent,
      repeatCount: 0,
      pathLength: message.pathLength,
      pathBytes: message.pathBytes,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => openMap
            ? ChannelMessagePathMapScreen(message: pathMessage)
            : ChannelMessagePathScreen(message: pathMessage),
      ),
    );
  }

  void _showMessageActions(Message message, Contact contact) {
    final readOnly = isRadioReadOnly(context.read<MeshCoreConnector>());
    final translationService = context.read<TranslationService>();
    final canTranslateMessage =
        translationService.canTranslateIncoming(
          text: message.text,
          isCli: message.isCli,
          isOutgoing: message.isOutgoing,
        ) &&
        (message.translatedText?.trim().isEmpty ?? true);

    showMeshSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                title: message.text.characters.length > 40
                    ? '${message.text.characters.take(40)}…'
                    : message.text,
              ),
              // Can't react to your own messages
              if (!message.isOutgoing)
                ListTile(
                  enabled: !readOnly,
                  leading: const Icon(Icons.add_reaction_outlined),
                  title: Text(context.l10n.chat_addReaction),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEmojiPicker(message, contact);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.route),
                title: Text(context.l10n.chat_path),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openMessagePath(message, contact);
                },
              ),
              if (message.pathBytes.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(context.l10n.chat_viewPathOnMap),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openMessagePath(message, contact, openMap: true);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(context.l10n.common_copy),
                onTap: () {
                  Navigator.pop(sheetContext);
                  copyChatMessageText(context, message.text);
                },
              ),
              if (canTranslateMessage)
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(context.l10n.translation_translateMessage),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(
                      context.read<MeshCoreConnector>().translateContactMessage(
                        widget.contact.publicKeyHex,
                        message,
                        manualTranslation: true,
                      ),
                    );
                  },
                ),
              if (!message.isOutgoing)
                ListTile(
                  leading: const Icon(Icons.mark_chat_unread_outlined),
                  title: Text(context.l10n.chat_markAsUnread),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _markAsUnread(message);
                  },
                ),
              ListTile(
                leading: Icon(
                  message.isBookmarked
                      ? Icons.bookmark_remove_outlined
                      : Icons.bookmark_add_outlined,
                ),
                title: Text(
                  message.isBookmarked
                      ? context.l10n.chat_removeBookmark
                      : context.l10n.chat_bookmark,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final bookmark = BookmarkedMessage.fromContact(
                    message: message,
                    contactKey: widget.contact.publicKeyHex,
                    contactName: widget.contact.name,
                    senderName: message.isOutgoing
                        ? (context.read<MeshCoreConnector>().selfName ??
                              context.l10n.chat_me)
                        : contact.name,
                  );
                  unawaited(
                    context.read<MeshCoreConnector>().setBookmarkedMessage(
                      bookmark,
                      isBookmarked: !message.isBookmarked,
                    ),
                  );
                },
              ),
              if (message.isOutgoing && message.status == MessageStatus.failed)
                ListTile(
                  enabled: !readOnly,
                  leading: const Icon(Icons.refresh),
                  title: Text(context.l10n.common_retry),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _retryMessage(message);
                  },
                ),
              if (_resolveContact(context.read<MeshCoreConnector>()).type ==
                  advTypeRoom)
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: Text(context.l10n.contacts_openChat),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openChat(context, contact);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                enabled: !readOnly,
                leading: Icon(
                  Icons.delete_outline,
                  color: readOnly ? null : Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  context.l10n.common_delete,
                  style: TextStyle(
                    color: readOnly
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _deleteMessage(message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    if (!ensureRadioConnected(context)) return;
    await context.read<MeshCoreConnector>().deleteMessage(message);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageDeleted),
    );
  }

  void _retryMessage(Message message) {
    if (!ensureRadioConnected(context)) return;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.resendMessage(_resolveContact(connector), message);
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_retryingMessage),
    );
  }

  void _showEmojiPicker(Message message, Contact senderContact) {
    showMeshSheet(
      context,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (emoji) {
          _sendReaction(message, senderContact, emoji);
        },
      ),
    );
  }

  void _sendReaction(Message message, Contact senderContact, String emoji) {
    if (!ensureRadioConnected(context)) return;
    final connector = context.read<MeshCoreConnector>();
    final emojiIndex = ReactionHelper.emojiToIndex(emoji);
    if (emojiIndex == null) return; // Unknown emoji, skip
    final timestampSecs = message.timestamp.millisecondsSinceEpoch ~/ 1000;

    // For room servers, include sender name (like channels) since multiple users
    // For 1:1 chats, sender is implicit (null)
    final liveContact = _resolveContact(connector);
    final senderName = liveContact.type == advTypeRoom
        ? senderContact.name
        : null;
    appLogger.info('Sending reaction using senderName: $senderName');
    final hash = ReactionHelper.computeReactionHash(
      timestampSecs,
      senderName,
      message.text,
    );
    final reactionText = ReactionHelper.encodeReaction(hash, emojiIndex);
    connector.sendMessage(_resolveContact(connector), reactionText);
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String senderName;
  final VoidCallback? onLongPress;
  final void Function(Message message, String emoji)? onRetryReaction;
  final double textScale;
  final String sourceId;
  final bool isBookmarked;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.sourceId,
    required this.textScale,
    required this.isBookmarked,
    this.onLongPress,
    this.onRetryReaction,
  });

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<AppSettingsService>();
    final enableTracing = settingsService.settings.enableMessageTracing;
    final isOutgoing = message.isOutgoing;
    final scheme = Theme.of(context).colorScheme;
    final gifId = GifHelper.parseGif(message.text);
    final poi = parseMarkerText(message.text);
    final contactShare = parseContactShare(message.text);
    final isFailed = message.status == MessageStatus.failed;
    final urlImagesEnabled = context.select<MeshCoreConnector, bool>(
      (connector) => connector.isContactUrlImagesEnabled(sourceId),
    );
    final publicIpfsGateway = settingsService.settings.publicIpfsGateway;

    final colors = MessageBubbleColors.of(
      context,
      isOutgoing: isOutgoing,
      isFailed: isFailed,
    );
    final textColor = colors.text;
    final metaColor = colors.meta;
    const bodyFontSize = 14.0;

    // Do not strip room-server author bytes here: the parser stores them in
    // fourByteRoomContactKey, so message.text is safe to render as-is.
    final messageText = message.text;
    final translatedDisplayText =
        message.translatedText != null &&
            message.translatedText!.trim().isNotEmpty
        ? message.translatedText!.trim()
        : messageText;
    final originalDisplayText = isOutgoing
        ? message.originalText
        : (translatedDisplayText != messageText ? messageText : null);

    Widget buildTextContent() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: TranslatedMessageContent(
              displayText: translatedDisplayText,
              originalText: originalDisplayText,
              style: TextStyle(
                color: textColor,
                fontSize: bodyFontSize * textScale,
              ),
              originalStyle: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: bodyFontSize * textScale,
              ),
              onSecondaryTap: PlatformInfo.isDesktop ? onLongPress : null,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onLongPress: onLongPress,
              onSecondaryTapUp: PlatformInfo.isDesktop
                  ? (_) => onLongPress?.call()
                  : null,
              child: Row(
                mainAxisAlignment: isOutgoing
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isOutgoing) ...[
                    _buildAvatar(senderName),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: MessageBubbleFrame(
                      isOutgoing: isOutgoing,
                      isFailed: isFailed,
                      isBookmarked: isBookmarked,
                      compact: gifId != null,
                      maxWidth: constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isOutgoing) ...[
                            Padding(
                              padding: gifId != null
                                  ? const EdgeInsets.only(
                                      left: 8,
                                      top: 4,
                                      bottom: 4,
                                    )
                                  : EdgeInsets.zero,
                              child: Text(
                                senderName,
                                style: MeshTheme.mono(
                                  fontSize: 13 * textScale,
                                  fontWeight: FontWeight.w700,
                                  color: senderNameColor(senderName),
                                ),
                              ),
                            ),
                            if (gifId == null) const SizedBox(height: 2),
                          ],
                          if (contactShare != null)
                            SharedContactCard(
                              share: contactShare,
                              isOutgoing: isOutgoing,
                              textScale: textScale,
                              textColor: textColor,
                              metaColor: metaColor,
                            )
                          else if (poi != null)
                            _buildPoiMessage(
                              context,
                              poi,
                              textColor,
                              metaColor,
                              textScale,
                              senderName,
                            )
                          else if (gifId != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: GifMessage(
                                    url:
                                        'https://media.giphy.com/media/$gifId/giphy.gif',
                                    backgroundColor: Colors.transparent,
                                    fallbackTextColor: textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else if (urlImagesEnabled)
                            MessageUrlImageFutureBuilder(
                              messageId: message.messageId,
                              text: message.text,
                              publicGateway: publicIpfsGateway,
                              builder: (context, snapshot) {
                                final imageAttachment = snapshot.data;

                                if (imageAttachment != null) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Align(
                                          alignment: isOutgoing
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: MessageUrlImagePreview(
                                            imageUrl: imageAttachment,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TranslatedMessageContent(
                                          displayText: translatedDisplayText,
                                          originalText: originalDisplayText,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: bodyFontSize * textScale,
                                          ),
                                          originalStyle: TextStyle(
                                            color: textColor.withValues(
                                              alpha: 0.72,
                                            ),
                                            fontSize: bodyFontSize * textScale,
                                          ),
                                          onSecondaryTap: PlatformInfo.isDesktop
                                              ? onLongPress
                                              : null,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return buildTextContent();
                              },
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (settingsService.settings.loadLinkImages &&
                                    MessageUrlImageHelper.hasPotentialImageUrl(
                                      message.text,
                                    ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      context.l10n.urlImage_possible,
                                      style: TextStyle(
                                        color: metaColor,
                                        fontSize: 12 * textScale,
                                      ),
                                    ),
                                  ),
                                buildTextContent(),
                              ],
                            ),
                          if (enableTracing &&
                              isOutgoing &&
                              message.retryCount > 0) ...[
                            const SizedBox(height: 3),
                            Padding(
                              padding: gifId != null
                                  ? const EdgeInsets.symmetric(horizontal: 8)
                                  : EdgeInsets.zero,
                              child: Text(
                                context.l10n.chat_retryCount(
                                  message.retryCount,
                                  context
                                      .read<AppSettingsService>()
                                      .settings
                                      .maxMessageRetries,
                                ),
                                style: MeshTheme.mono(
                                  fontSize: 12 * textScale,
                                  color: metaColor,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          // Meta row: timestamp + status icon + optional tracing
                          Padding(
                            padding: gifId != null
                                ? const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    bottom: 4,
                                  )
                                : EdgeInsets.zero,
                            child: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  formatChatTime(context, message.timestamp),
                                  style: MeshTheme.mono(
                                    fontSize: 12 * textScale,
                                    color: metaColor,
                                  ),
                                ),
                                if (message.hasFutureTimestamp)
                                  FutureTimestampIndicator(
                                    size: 16 * textScale,
                                  ),
                                if (isOutgoing) ...[
                                  const SizedBox(width: 2),
                                  MessageStatusIcon(
                                    size: 16 * textScale,
                                    onColor: metaColor,
                                    isAcked:
                                        message.status ==
                                        MessageStatus.delivered,
                                    isPending:
                                        message.status == MessageStatus.pending,
                                    isFailed:
                                        message.status == MessageStatus.failed,
                                  ),
                                ],
                                if (enableTracing &&
                                    message.tripTimeMs != null &&
                                    message.status ==
                                        MessageStatus.delivered) ...[
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.speed,
                                    size: 14 * textScale,
                                    color: isOutgoing
                                        ? metaColor
                                        : scheme.tertiary,
                                  ),
                                  Text(
                                    '${(message.tripTimeMs! / 1000).toStringAsFixed(1)}s',
                                    style: MeshTheme.mono(
                                      fontSize: 12 * textScale,
                                      color: isOutgoing
                                          ? metaColor
                                          : scheme.tertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: isOutgoing ? 0 : 42),
              child: ReactionChips(
                reactions: message.reactions,
                statuses: message.reactionStatuses,
                onRetry: onRetryReaction == null
                    ? null
                    : (emoji) => onRetryReaction!(message, emoji),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPoiMessage(
    BuildContext context,
    MarkerPayload poi,
    Color textColor,
    Color metaColor,
    double textScale,
    String senderName, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.location_on_outlined, color: textColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () async {
            final selfName =
                context.read<MeshCoreConnector>().selfName ??
                context.l10n.chat_me;
            final fromName = message.isOutgoing ? selfName : senderName;
            final key = buildSharedMarkerKey(
              sourceId: sourceId,
              label: poi.label,
              fromName: fromName,
              flags: poi.flags,
              isChannel: false,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  highlightPosition: poi.position,
                  highlightLabel: poi.label,
                  highlightMarkerKey: key,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.chat_poiShared,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14 * textScale,
                ),
              ),
              if (poi.label.isNotEmpty)
                Text(
                  poi.label,
                  style: TextStyle(color: metaColor, fontSize: 12 * textScale),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing],
      ],
    );
  }

  Widget _buildAvatar(String senderName) {
    return AvatarCircle(name: senderName, size: 32);
  }
}
