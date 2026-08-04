import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../models/community.dart';
import '../storage/community_store.dart';
import '../utils/platform_info.dart';
import '../helpers/chat_scroll_controller.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/cyr2lat.dart';
import '../helpers/gif_helper.dart';
import '../helpers/path_helper.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/chat_text_scale_service.dart';
import '../services/translation_service.dart';
import '../widgets/byte_count_input.dart';
import '../widgets/empty_state.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/gif_message.dart';
import '../widgets/jump_to_bottom_button.dart';
import '../widgets/gif_picker.dart';
import '../widgets/message_translation_button.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/radio_stats_entry.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/translated_message_content.dart';
import '../widgets/unread_divider.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';
import 'channel_message_path_screen.dart';
import 'map_screen.dart';
import 'region_management_screen.dart';
import '../storage/region_store.dart';

class ChannelChatScreen extends StatefulWidget {
  final Channel channel;
  final int initialUnreadCount;

  const ChannelChatScreen({
    super.key,
    required this.channel,
    this.initialUnreadCount = 0,
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatScrollController _scrollController = ChatScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
  ChannelMessage? _replyingToMessage;
  final CommunityStore _communityStore = CommunityStore();
  final CommunityPskIndex _communityIndex = CommunityPskIndex();
  final Map<String, GlobalKey> _messageKeys = {};
  bool _isLoadingOlder = false;
  bool _communitiesLoaded = false;

  MeshCoreConnector? _connector;
  DateTime? _lastChannelSendAt;
  bool _channelSkipNextBottomSnap = false;
  String? _unreadDividerMessageId;

  String? _cachedFormatLocale;
  late DateFormat _hmFormat;
  late DateFormat _mdFormat;

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
      final idx = widget.channel.index;
      final unread = widget.initialUnreadCount;
      final messages = connector.getChannelMessages(widget.channel);
      _loadCommunities();
      ChannelMessage? anchor;
      if (unread > 0) {
        anchor = _findOldestUnreadChannelAnchor(messages, unread);
      }
      setState(() {
        if (anchor != null) _unreadDividerMessageId = anchor.messageId;
      });
      connector.setActiveChannel(idx);
      _connector = connector;
      if (anchor != null && settings.jumpToOldestUnread) {
        _channelSkipNextBottomSnap = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollController.jumpToEstimatedOffset(
            unreadCount: unread,
            totalMessages: messages.length,
            onJumped: () {
              if (!mounted) return;
              _scrollToMessage(anchor!.messageId, quiet: true);
            },
          );
        });
      }
    });
  }

  // TODO: Reload communities when returning from another screen
  Future<void> _loadCommunities() async {
    final connector = context.read<MeshCoreConnector>();
    _communityStore.setPublicKeyHex = connector.selfPublicKeyHex;
    final communities = await _communityStore.loadCommunities();
    if (mounted) {
      setState(() {
        _communityIndex.initialize(communities);
        _communitiesLoaded = true;
      });
    }
  }

  ChannelMessage? _findOldestUnreadChannelAnchor(
    List<ChannelMessage> messages,
    int unreadCount,
  ) {
    if (unreadCount <= 0 || messages.isEmpty) return null;
    var n = 0;
    ChannelMessage? oldest;
    for (final m in messages.reversed) {
      if (m.isOutgoing) continue;
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
    await connector.loadOlderChannelMessages(widget.channel.index);

    if (mounted) {
      setState(() => _isLoadingOlder = false);
    }
  }

  @override
  void dispose() {
    _connector?.setActiveChannel(null);
    _scrollController.showJumpToBottom.removeListener(_clearDividerAtBottom);
    _textFieldFocusNode.removeListener(_onTextFieldFocusChange);
    _textFieldFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setReplyingTo(ChannelMessage message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  Future<void> _scrollToMessage(String messageId, {bool quiet = false}) async {
    final key = _messageKeys[messageId];
    if (key == null) {
      // The auto unread-jump can resolve a frame after navigating away;
      // a deactivated context can't host a snackbar.
      if (quiet || !mounted || !context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_originalMessageNotFound),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final targetContext = key.currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  Widget _channelIcon(Channel channel) {
    // Determine icon based on channel type
    final ChannelType channelType = Channel.getChannelType(
      channel,
      _communityIndex,
    );
    final bool isCommunityChannel = Channel.isCommunityChannel(channelType);
    IconData icon;
    switch (channelType) {
      case ChannelType.communityPublic:
        icon = Icons.groups;
      case ChannelType.communityHashtag:
        icon = Icons.tag;
      case ChannelType.public:
        icon = Icons.public;
      case ChannelType.hashtag:
        icon = Icons.tag;
      case ChannelType.private:
        icon = Icons.lock;
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _communitiesLoaded
              ? Icon(icon, size: 20)
              : SizedBox.square(dimension: 20),
        ),
        if (isCommunityChannel)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.people, size: 8, color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openRegionSelectDialog(widget.channel),
          child: Row(
            children: [
              _channelIcon(widget.channel),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name.isEmpty
                          ? context.l10n.channels_channelIndex(
                              widget.channel.index,
                            )
                          : widget.channel.name,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Consumer<MeshCoreConnector>(
                      builder: (context, connector, _) {
                        final unreadCount = connector
                            .getUnreadCountForChannelIndex(
                              widget.channel.index,
                            );
                        final privacy = widget.channel.isPublicChannel
                            ? context.l10n.channels_public
                            : context.l10n.channels_private;
                        final region = connector.getChannelRegion(
                          widget.channel.index,
                        );
                        final regionText = region.isNotEmpty
                            ? ' • ${context.l10n.channels_regionSetTo(region)}'
                            : '';
                        return Text(
                          '$privacy • ${context.l10n.chat_unread(unreadCount)}$regionText',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        bottom: const SyncProgressAppBarBottom(),
        actions: [
          IconButton(
            tooltip: context.l10n.channels_regionSelect_Title,
            icon: const Icon(Icons.landscape),
            onPressed: () => openRegionSelectDialog(widget.channel),
          ),
          const RadioStatsIconButton(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clearChat') {
                _confirmClearChat();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clearChat',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.contact_clearChat,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Consumer<MeshCoreConnector>(
                builder: (context, connector, child) {
                  final messages = connector.getChannelMessages(widget.channel);

                  if (messages.isEmpty) {
                    return EmptyState(
                      icon: widget.channel.isPublicChannel
                          ? Icons.public
                          : Icons.tag,
                      title: context.l10n.chat_noMessages,
                      subtitle: context.l10n.chat_sendMessageTo(
                        widget.channel.name.isEmpty
                            ? context.l10n.channels_channelIndex(
                                widget.channel.index,
                              )
                            : widget.channel.name,
                      ),
                    );
                  }

                  // Reverse messages so newest appear at bottom with reverse: true
                  final reversedMessages = messages.reversed.toList();
                  final itemCount =
                      reversedMessages.length + (_isLoadingOlder ? 1 : 0);

                  // Prune stale keys (deleted/cleared messages) to avoid
                  // unbounded growth.
                  final liveIds = reversedMessages
                      .map((m) => m.messageId)
                      .toSet();
                  _messageKeys.removeWhere((id, _) => !liveIds.contains(id));

                  // Two messages can collide on messageId (same ms + name/text
                  // hash). Only the first occurrence owns the shared GlobalKey
                  // used for scroll-to-message; duplicates get a local key so
                  // no two widgets share one GlobalKey.
                  final seenIds = <String>{};
                  final keyedIndices = <int>{};
                  for (var i = 0; i < reversedMessages.length; i++) {
                    if (seenIds.add(reversedMessages[i].messageId)) {
                      keyedIndices.add(i);
                    }
                  }

                  // Auto-scroll to bottom if user is already at bottom
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_channelSkipNextBottomSnap) {
                      _channelSkipNextBottomSnap = false;
                      return;
                    }
                    _scrollController.scrollToBottomIfAtBottom();
                  });

                  return Stack(
                    children: [
                      ChatZoomWrapper(
                        child: ListView.builder(
                          reverse: true, // List grows from bottom up
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final messageIndex = index;
                            final message = reversedMessages[messageIndex];
                            final GlobalKey messageKey;
                            if (keyedIndices.contains(messageIndex)) {
                              messageKey = _messageKeys.putIfAbsent(
                                message.messageId,
                                GlobalKey.new,
                              );
                            } else {
                              messageKey = GlobalKey();
                            }
                            final isUnreadAnchor =
                                _unreadDividerMessageId != null &&
                                message.messageId == _unreadDividerMessageId;
                            return Container(
                              key: messageKey,
                              child: Builder(
                                builder: (context) {
                                  final textScale = context
                                      .select<ChatTextScaleService, double>(
                                        (service) => service.scale,
                                      );
                                  final bubble = _buildMessageBubble(
                                    message,
                                    textScale,
                                  );
                                  if (isUnreadAnchor) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [const UnreadDivider(), bubble],
                                    );
                                  }
                                  return bubble;
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      JumpToBottomButton(scrollController: _scrollController),
                    ],
                  );
                },
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  void _markAsUnread(ChannelMessage message) {
    final connector = context.read<MeshCoreConnector>();
    final messages = connector.getChannelMessages(widget.channel);
    var count = 0;
    var found = false;
    for (final m in messages) {
      if (m.messageId == message.messageId) found = true;
      if (found && !m.isOutgoing) count++;
    }
    connector.setChannelUnreadCount(widget.channel.index, count);
  }

  Widget _buildMessageBubble(ChannelMessage message, double textScale) {
    final settingsService = context.watch<AppSettingsService>();
    final enableTracing = settingsService.settings.enableMessageTracing;
    final isOutgoing = message.isOutgoing;
    final scheme = Theme.of(context).colorScheme;
    final gifId = GifHelper.parseGif(message.text);
    final poi = parseMarkerText(message.text);
    final translatedDisplayText =
        message.translatedText != null &&
            message.translatedText!.trim().isNotEmpty
        ? message.translatedText!.trim()
        : message.text;
    final originalDisplayText = message.isOutgoing
        ? message.originalText
        : (translatedDisplayText != message.text ? message.text : null);
    final displayPath = message.pathBytes.isNotEmpty
        ? message.pathBytes
        : (message.pathVariants.isNotEmpty
              ? message.pathVariants.first
              : Uint8List(0));
    final displayPathHashWidth =
        message.pathHashWidth ??
        context.read<MeshCoreConnector>().pathHashByteWidth;
    final displayHopCount = _displayHopCount(
      displayPath,
      displayPathHashWidth,
      message.pathLength,
    );

    // Bubble colors — outgoing uses MeshPalette.me / meBorder / meInk.
    final bubbleColor = isOutgoing
        ? MeshPalette.me
        : scheme.surfaceContainerLow;
    final bubbleBorder = isOutgoing
        ? MeshPalette.meBorder
        : scheme.outlineVariant;
    final textColor = isOutgoing ? MeshPalette.meInk : scheme.onSurface;
    final metaColor = textColor.withValues(alpha: 0.65);
    const bodyFontSize = 14.0;

    // Asymmetric radius matching chat_screen bubbles.
    final borderRadius = isOutgoing
        ? const BorderRadius.only(
            topLeft: Radius.circular(MeshRadii.lg),
            topRight: Radius.circular(MeshRadii.lg),
            bottomLeft: Radius.circular(MeshRadii.lg),
            bottomRight: Radius.circular(MeshRadii.xs),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(MeshRadii.xs),
            topRight: Radius.circular(MeshRadii.lg),
            bottomLeft: Radius.circular(MeshRadii.lg),
            bottomRight: Radius.circular(MeshRadii.lg),
          );

    const maxSwipeOffset = 64.0;
    const replySwipeThreshold = 64.0;
    final messageBody = LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isOutgoing
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOutgoing) ...[
                _buildAvatar(message.senderName, textScale),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageActions(message),
                  onSecondaryTapUp: PlatformInfo.isDesktop
                      ? (_) => _showMessageActions(message)
                      : null,
                  child: Container(
                    padding: gifId != null
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: borderRadius,
                      border: Border.all(color: bubbleBorder, width: 1),
                    ),
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
                              message.senderName,
                              style: TextStyle(
                                fontSize: 13 * textScale,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (gifId == null) const SizedBox(height: 2),
                        ],
                        if (message.replyToMessageId != null) ...[
                          _buildReplyPreview(message, textScale),
                          const SizedBox(height: 8),
                        ],
                        if (poi != null)
                          _buildPoiMessage(
                            context,
                            poi,
                            isOutgoing,
                            textScale,
                            message.senderName,
                          )
                        else if (gifId != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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
                        else
                          Row(
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
                                    fontSize: bodyFontSize * textScale,
                                    fontStyle: FontStyle.italic,
                                    color: textColor.withValues(alpha: 0.72),
                                  ),
                                  onSecondaryTap: PlatformInfo.isDesktop
                                      ? () => _showMessageActions(message)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        if (enableTracing && displayPath.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Padding(
                            padding: gifId != null
                                ? const EdgeInsets.symmetric(horizontal: 8)
                                : EdgeInsets.zero,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RouteChip(
                                  isDirect: (message.pathLength ?? -1) >= 0,
                                  hops: displayHopCount,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    context.l10n.channels_via(
                                      _formatPathPrefixes(
                                        displayPath,
                                        displayPathHashWidth,
                                      ),
                                    ),
                                    style: MeshTheme.mono(
                                      fontSize: 9.5 * textScale,
                                      color: metaColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Padding(
                          padding: gifId != null
                              ? const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 4,
                                )
                              : EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(context, message.timestamp),
                                style: MeshTheme.mono(
                                  fontSize: 10 * textScale,
                                  color: metaColor,
                                ),
                              ),
                              if (enableTracing && message.repeatCount > 0) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.repeat,
                                  size: 11 * textScale,
                                  color: metaColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${message.repeatCount}',
                                  style: MeshTheme.mono(
                                    fontSize: 10 * textScale,
                                    color: metaColor,
                                  ),
                                ),
                              ],
                              if (isOutgoing) ...[
                                const SizedBox(width: 4),
                                MessageStatusIcon(
                                  isAcked:
                                      message.status ==
                                      ChannelMessageStatus.sent,
                                  isRepeated:
                                      message.status ==
                                          ChannelMessageStatus.sent &&
                                      displayPath.isNotEmpty,
                                  isPending:
                                      message.status ==
                                      ChannelMessageStatus.pending,
                                  isFailed:
                                      message.status ==
                                      ChannelMessageStatus.failed,
                                  onColor: metaColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: isOutgoing ? 0 : 42),
              child: _buildReactionsDisplay(message),
            ),
          ],
        ],
      ),
    );

    if (!isOutgoing && !PlatformInfo.isDesktop) {
      return _SwipeReplyBubble(
        maxSwipeOffset: maxSwipeOffset,
        replySwipeThreshold: replySwipeThreshold,
        onReplyTriggered: () => _setReplyingTo(message),
        hintBuilder: ({required isStart}) =>
            _buildReplySwipeHint(isStart: isStart),
        child: messageBody,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: messageBody,
      );
    }
  }

  Widget _buildReplySwipeHint({required bool isStart}) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.reply, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          context.l10n.chat_reply,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Container(
      alignment: isStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: isStart
          ? content
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.chat_reply,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.reply, color: colorScheme.primary),
              ],
            ),
    );
  }

  Widget _buildReplyPreview(ChannelMessage message, double textScale) {
    final connector = context.read<MeshCoreConnector>();
    final isOwnNode = message.replyToSenderName == connector.selfName;
    final replyText = message.replyToText ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final previewTextColor = colorScheme.onSurface.withValues(alpha: 0.7);

    final gifId = GifHelper.parseGif(replyText);
    final poi = parseMarkerText(replyText);

    Widget contentPreview;
    if (gifId != null) {
      contentPreview = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: GifMessage(
          url: 'https://media.giphy.com/media/$gifId/giphy.gif',
          backgroundColor: colorScheme.surfaceContainerHighest,
          fallbackTextColor: previewTextColor,
          maxSize: 80,
        ),
      );
    } else if (poi != null) {
      contentPreview = Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: previewTextColor),
          const SizedBox(width: 4),
          Text(
            context.l10n.chat_location,
            style: TextStyle(fontSize: 12 * textScale, color: previewTextColor),
          ),
        ],
      );
    } else {
      contentPreview = Text(
        replyText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12 * textScale,
          color: previewTextColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _scrollToMessage(message.replyToMessageId!),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(MeshRadii.sm),
          border: Border(
            left: BorderSide(color: colorScheme.primary, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_replyTo(message.replyToSenderName ?? ''),
              style: TextStyle(
                fontSize: 11 * textScale,
                fontWeight: FontWeight.bold,
                color: isOwnNode ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            contentPreview,
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsDisplay(ChannelMessage message) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(MeshRadii.pill),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: MeshTheme.emoji(fontSize: 16),
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: MeshTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPoiMessage(
    BuildContext context,
    MarkerPayload poi,
    bool isOutgoing,
    double textScale,
    String senderName, {
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = isOutgoing ? MeshPalette.meInk : scheme.onSurface;
    final metaColor = textColor.withValues(alpha: 0.7);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.location_on_outlined, color: scheme.primary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            final selfName =
                context.read<MeshCoreConnector>().selfName ??
                context.l10n.chat_me;
            final fromName = isOutgoing ? selfName : senderName;
            final key = buildSharedMarkerKey(
              sourceId: 'channel:${widget.channel.index}',
              label: poi.label,
              fromName: fromName,
              flags: poi.flags,
              isChannel: true,
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

  void _showGifPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GifPicker(
        onGifSelected: (gifId) {
          _textController.text = GifHelper.encodeGif(gifId);
        },
      ),
    );
  }

  Widget _buildAvatar(String senderName, double textScale) {
    return AvatarCircle(
      name: senderName,
      size: (32 * textScale).clamp(28.0, 56.0),
    );
  }

  Widget _buildReplyBanner(double textScale) {
    final message = _replyingToMessage!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.chat_replyingTo(message.senderName),
                  style: MeshTheme.mono(
                    fontSize: 11 * textScale,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  message.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11 * textScale,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
            color: scheme.onSurfaceVariant,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    final connector = context.watch<MeshCoreConnector>();
    final maxBytes = maxChannelMessageBytes(connector.selfName);
    final settings = context.watch<AppSettingsService>().settings;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToMessage != null)
          Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              return _buildReplyBanner(textScale);
            },
          ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.gif_box),
                    onPressed: () => _showGifPicker(context),
                    tooltip: context.l10n.chat_sendGif,
                  ),
                  if (settings.translationEnabled)
                    MessageTranslationButton(
                      enabled: settings.composerTranslationEnabled,
                      languageCode: settings.translationTargetLanguageCode,
                      onPressed: _showTranslationOptions,
                    ),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, child) {
                        final gifId = GifHelper.parseGif(value.text);
                        if (gifId != null) {
                          return Focus(
                            autofocus: true,
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent &&
                                  (event.logicalKey ==
                                          LogicalKeyboardKey.enter ||
                                      event.logicalKey ==
                                          LogicalKeyboardKey.numpadEnter)) {
                                _sendMessage();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GifMessage(
                                      url:
                                          'https://media.giphy.com/media/$gifId/giphy.gif',
                                      backgroundColor:
                                          scheme.surfaceContainerHighest,
                                      fallbackTextColor: scheme.onSurface
                                          .withValues(alpha: 0.6),
                                      maxSize: 160,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _textController.clear();
                                    _textFieldFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                        return ByteCountedTextField(
                          maxBytes: maxBytes,
                          controller: _textController,
                          focusNode: _textFieldFocusNode,
                          hintText: context.l10n.chat_typeMessage,
                          onSubmitted: (_) => _sendMessage(),
                          encoder:
                              (connector.isChannelSmazEnabled(
                                    widget.channel.index,
                                  ) ||
                                  connector.isChannelCyr2LatEnabled(
                                    widget.channel.index,
                                  ))
                              ? (text) => connector.prepareChannelOutboundText(
                                  widget.channel.index,
                                  text,
                                )
                              : null,
                          decoration: InputDecoration(
                            hintText: context.l10n.chat_typeMessage,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(MeshRadii.md),
                              borderSide: BorderSide(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(MeshRadii.md),
                              borderSide: BorderSide(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(MeshRadii.md),
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: scheme.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        child: IconButton.filled(
                          icon: const Icon(Icons.send, size: 20),
                          tooltip: context.l10n.chat_sendMessage,
                          style: IconButton.styleFrom(
                            backgroundColor: hasText
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            foregroundColor: hasText
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                            minimumSize: const Size(40, 40),
                            shape: const CircleBorder(),
                          ),
                          onPressed: hasText
                              ? () {
                                  HapticFeedback.lightImpact();
                                  _sendMessage();
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTranslationOptions() async {
    final settingsService = context.read<AppSettingsService>();
    final settings = settingsService.settings;
    await showMessageTranslationSheet(
      context: context,
      enabled: settings.composerTranslationEnabled,
      selectedLanguageCode: settings.translationTargetLanguageCode,
      onEnabledChanged: settingsService.setComposerTranslationEnabled,
      onLanguageSelected: settingsService.setTranslationTargetLanguageCode,
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastChannelSendAt != null &&
        now.difference(_lastChannelSendAt!) < const Duration(seconds: 1)) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_sendCooldown),
      );
      return;
    }
    _lastChannelSendAt = now;

    final connector = context.read<MeshCoreConnector>();
    final settings = context.read<AppSettingsService>().settings;
    final translationService = context.read<TranslationService>();

    String messageText = text;
    String? originalText;
    String? translatedLanguageCode;
    String? translationModelId;
    if (settings.translationEnabled) {
      final targetLanguageCode = translationService.resolvedTargetLanguageCode(
        Localizations.localeOf(context).languageCode,
      );
      if (translationService.shouldTranslateOutgoing(
        text: text,
        targetLanguageCode: targetLanguageCode,
      )) {
        final result = await translationService.translateOutgoingText(
          text: text,
          targetLanguageCode: targetLanguageCode,
        );
        if (!mounted) return;
        if (result != null &&
            result.status == MessageTranslationStatus.completed &&
            result.translatedText.isNotEmpty) {
          messageText = result.translatedText;
          originalText = text;
          translatedLanguageCode = result.targetLanguageCode;
          translationModelId = result.modelId;
        }
      }
    }
    if (_replyingToMessage != null) {
      messageText = '@[${_replyingToMessage!.senderName}] $messageText';
    }

    final maxBytes = maxChannelMessageBytes(connector.selfName);
    final outboundText = connector.prepareChannelOutboundText(
      widget.channel.index,
      messageText,
    );
    if (utf8.encode(outboundText).length > maxBytes) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_messageTooLong(maxBytes)),
      );
      return;
    }

    // When messageText is transformed with cyr2lat, it (generally) hasn't visual differences,
    // but we getting messages doubles in chat screen (source text and transformed).
    // To prevent, we'll perform transform of source before pass to main sender logic.
    // We can pass whole text, senderName will be kept intact
    if (connector.isChannelCyr2LatEnabled(widget.channel.index)) {
      messageText = Cyr2Lat.encode(messageText);
    }
    // end transform

    _textController.clear();
    _cancelReply();
    _textFieldFocusNode.requestFocus();
    connector.sendChannelMessage(
      widget.channel,
      messageText,
      originalText: originalText,
      translatedLanguageCode: translatedLanguageCode,
      translationModelId: translationModelId,
    );
  }

  String _formatTime(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final locale = Localizations.localeOf(context).toString();
    if (locale != _cachedFormatLocale) {
      _cachedFormatLocale = locale;
      _hmFormat = DateFormat.Hm(locale);
      _mdFormat = DateFormat.Md(locale);
    }
    final hm = _hmFormat.format(time);

    if (diff.inDays > 0) {
      return '${_mdFormat.format(time)} $hm';
    } else {
      return hm;
    }
  }

  void _showMessagePathInfo(ChannelMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChannelMessagePathScreen(message: message, channelMessage: true),
      ),
    );
  }

  void _showMessageActions(ChannelMessage message) {
    final translationService = context.read<TranslationService>();
    final canTranslateMessage =
        translationService.canTranslateIncoming(
          text: message.text,
          isCli: false,
          isOutgoing: message.isOutgoing,
        ) &&
        (message.translatedText?.trim().isEmpty ?? true);

    showMeshSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              title: message.text.length > 40
                  ? '${message.text.substring(0, 40)}…'
                  : message.text,
              subtitle: message.senderName.isNotEmpty
                  ? message.senderName
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(context.l10n.chat_reply),
              onTap: () {
                Navigator.pop(sheetContext);
                _setReplyingTo(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: Text(context.l10n.chat_path),
              onTap: () {
                Navigator.pop(sheetContext);
                _showMessagePathInfo(message);
              },
            ),
            // Can't react to your own messages
            if (!message.isOutgoing)
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: Text(context.l10n.chat_addReaction),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEmojiPicker(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.common_copy),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyMessageText(message.text);
              },
            ),
            if (canTranslateMessage)
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(context.l10n.translation_translateMessage),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(
                    context.read<MeshCoreConnector>().translateChannelMessage(
                      widget.channel.index,
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
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.l10n.common_delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    );
  }

  void _showEmojiPicker(ChannelMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (emoji) {
          _sendReaction(message, emoji);
        },
      ),
    );
  }

  void _sendReaction(ChannelMessage message, String emoji) {
    final connector = context.read<MeshCoreConnector>();
    final emojiIndex = ReactionHelper.emojiToIndex(emoji);
    if (emojiIndex == null) return; // Unknown emoji, skip
    final timestampSecs = message.timestamp.millisecondsSinceEpoch ~/ 1000;
    final hash = ReactionHelper.computeReactionHash(
      timestampSecs,
      message.senderName,
      message.text,
    );
    final reactionText = ReactionHelper.encodeReaction(hash, emojiIndex);
    connector.sendChannelMessage(widget.channel, reactionText);
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageCopied),
    );
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.contact_clearChat),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      context.read<MeshCoreConnector>().clearMessagesForChannel(
        widget.channel.index,
      );
    }
  }

  Future<void> _deleteMessage(ChannelMessage message) async {
    await context.read<MeshCoreConnector>().deleteChannelMessage(message);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageDeleted),
    );
  }

  String _formatPathPrefixes(Uint8List pathBytes, int pathHashByteWidth) {
    return PathHelper.splitPathBytes(
      pathBytes,
      pathHashByteWidth,
    ).map(PathHelper.formatHopHex).join(',');
  }

  int? _displayHopCount(
    Uint8List pathBytes,
    int pathHashByteWidth,
    int? fallbackPathLength,
  ) {
    if ((fallbackPathLength ?? -1) < 0) return null;
    if (pathBytes.isEmpty) return fallbackPathLength;
    return PathHelper.splitPathBytes(pathBytes, pathHashByteWidth).length;
  }

  Future<void> openRegionSelectDialog(Channel channel) async {
    // The AppBar subtitle reads the region from the connector inside a
    // Consumer, so setChannelRegion's notifyListeners refreshes it directly —
    // no post-dialog setState needed.
    await showDialog(
      context: context,
      builder: (BuildContext context) => _RegionSelectDialog(channel: channel),
    );
  }
}

class _RegionSelectDialog extends StatefulWidget {
  final Channel channel;

  const _RegionSelectDialog({required this.channel});

  @override
  State<_RegionSelectDialog> createState() => _RegionSelectDialogState();
}

class _RegionSelectDialogState extends State<_RegionSelectDialog> {
  final RegionStore regionStore = RegionStore();

  List<Region> regions = [];
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    loadRegions();
  }

  void loadRegions() {
    setState(() {
      regions = regionStore.loadRegions();
      final channelRegion = context.read<MeshCoreConnector>().getChannelRegion(
        widget.channel.index,
      );
      selectedIndex = regions.indexOf(channelRegion);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: Text(context.l10n.channels_regionSelect_Title),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: context.l10n.channels_clearRegion,
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: () {
                    context.read<MeshCoreConnector>().setChannelRegion(
                      widget.channel.index,
                      '',
                    );
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  tooltip: context.l10n.settings_regionSettingsSubtitle,
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await pushRegionManagementScreen(context);
                    if (!mounted) return;
                    loadRegions();
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final selected = selectedIndex == index;
                  return ListTile(
                    leading: Icon(
                      Icons.landscape,
                      color: selected ? MeshPalette.blue : null,
                    ),
                    title: Text(regions[index]),
                    trailing: selected
                        ? const Icon(Icons.check, color: MeshPalette.blue)
                        : null,
                    tileColor: selected ? MeshPalette.blueBg : null,
                    onTap: () {
                      // Tapping the already-selected region clears it.
                      context.read<MeshCoreConnector>().setChannelRegion(
                        widget.channel.index,
                        selected ? '' : regions[index],
                      );
                      Navigator.pop(context);
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

class _SwipeReplyBubble extends StatefulWidget {
  final double maxSwipeOffset;
  final double replySwipeThreshold;
  final VoidCallback onReplyTriggered;
  final Widget Function({required bool isStart}) hintBuilder;
  final Widget child;

  const _SwipeReplyBubble({
    required this.maxSwipeOffset,
    required this.replySwipeThreshold,
    required this.onReplyTriggered,
    required this.hintBuilder,
    required this.child,
  });

  @override
  State<_SwipeReplyBubble> createState() => _SwipeReplyBubbleState();
}

class _SwipeReplyBubbleState extends State<_SwipeReplyBubble> {
  Offset? _swipeStartPosition;
  double _swipeOffset = 0;
  double _maxSwipeDistance = 0;
  int? _swipePointerId;
  bool _swipeLockedToHorizontal = false;
  bool _isRtl = false;

  void _handleSwipeStart(Offset position) {
    _swipeStartPosition = position;
    _maxSwipeDistance = 0;
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
  }

  void _handleSwipePointerDown(PointerDownEvent event) {
    _swipePointerId = event.pointer;
    _swipeLockedToHorizontal = false;
    _handleSwipeStart(event.position);
  }

  void _handleSwipePointerMove(PointerMoveEvent event) {
    if (_swipePointerId != event.pointer || _swipeStartPosition == null) {
      return;
    }

    final rawDx = event.position.dx - _swipeStartPosition!.dx;
    // In LTR swipe left (rawDx < 0) triggers reply; in RTL swipe right (rawDx > 0).
    final signedDx = _isRtl ? rawDx : -rawDx;

    const axisLockThreshold = 12.0;
    if (!_swipeLockedToHorizontal) {
      if (signedDx < axisLockThreshold) {
        return;
      }
      _swipeLockedToHorizontal = true;
    }

    _handleSwipeUpdate(event.position);
  }

  void _handleSwipeUpdate(Offset position) {
    if (_swipeStartPosition == null) return;

    final rawDx = position.dx - _swipeStartPosition!.dx;
    final signedDx = _isRtl ? rawDx : -rawDx;
    if (signedDx <= 0) return;

    if (signedDx < 6) return;

    if (signedDx > _maxSwipeDistance) {
      _maxSwipeDistance = signedDx;
    }

    final double clamped = signedDx.clamp(0.0, widget.maxSwipeOffset);
    final adjusted = _applySwipeResistance(clamped, widget.maxSwipeOffset);
    // Translate in the gesture direction: negative for LTR (left), positive for RTL (right).
    final translationOffset = _isRtl ? adjusted : -adjusted;
    if (translationOffset != _swipeOffset) {
      setState(() => _swipeOffset = translationOffset);
    }
  }

  void _handleSwipePointerUp(Offset position) {
    if (_swipeLockedToHorizontal && _swipeStartPosition != null) {
      final rawDx = position.dx - _swipeStartPosition!.dx;
      final signedDx = _isRtl ? rawDx : -rawDx;
      final peak = math.max(
        _maxSwipeDistance,
        signedDx.clamp(0.0, double.infinity),
      );
      if (peak >= widget.replySwipeThreshold) {
        widget.onReplyTriggered();
        HapticFeedback.selectionClick();
      }
    }
    _resetSwipe();
  }

  void _resetSwipe() {
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
    _swipeStartPosition = null;
    _maxSwipeDistance = 0;
    _swipePointerId = null;
    _swipeLockedToHorizontal = false;
  }

  double _applySwipeResistance(double rawOffset, double maxOffset) {
    final abs = rawOffset.abs();
    if (abs <= 0) return 0;
    final norm = (abs / maxOffset).clamp(0.0, 1.0);
    const deadZone = 0.18;
    if (norm <= deadZone) {
      return rawOffset.sign * maxOffset * (norm * 0.08);
    }
    final t = ((norm - deadZone) / (1 - deadZone)).clamp(0.0, 1.0);
    final curved = t < 0.5
        ? 16 * math.pow(t, 5)
        : 1 - math.pow(-2 * t + 2, 5) / 2;
    const deadZoneEnd = 0.0144;
    return rawOffset.sign *
        maxOffset *
        (deadZoneEnd + curved * (1 - deadZoneEnd));
  }

  @override
  Widget build(BuildContext context) {
    _isRtl = Directionality.of(context) == TextDirection.rtl;
    // In LTR, the bubble slides left and the hint appears on the right (isStart: false).
    // In RTL, the bubble slides right and the hint appears on the left (isStart: true).
    final hintIsStart = _isRtl;
    return Listener(
      onPointerDown: _handleSwipePointerDown,
      onPointerMove: _handleSwipePointerMove,
      onPointerUp: (event) => _handleSwipePointerUp(event.position),
      onPointerCancel: (_) => _resetSwipe(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _swipeOffset.abs() / widget.maxSwipeOffset,
                child: widget.hintBuilder(isStart: hintIsStart),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(_swipeOffset, 0, 0),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
