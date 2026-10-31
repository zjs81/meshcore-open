import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show mergeSort;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../models/community.dart';
import '../storage/community_store.dart';
import '../utils/platform_info.dart';
import '../helpers/chat_scroll_controller.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/cyr2lat.dart';
import '../helpers/gif_helper.dart';
import '../helpers/ipfs_link_attach_flow.dart';
import '../helpers/marker_message.dart';
import '../helpers/message_url_image_helper.dart';
import '../helpers/path_helper.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/image_codec_support.dart' show aeicRatePointForUi;
import '../services/app_settings_service.dart'
    show AppSettingsService, ChannelNotificationMode;
import '../services/chat_text_scale_service.dart';
import '../services/image_chunk_transport.dart';
import '../services/image_codec_service.dart';
import '../services/received_image_store.dart';
import '../services/translation_service.dart';
import '../utils/image_save.dart';
import '../utils/lora_airtime.dart';
import '../widgets/marker_label_dialog.dart';
import '../widgets/received_image_message.dart';
import '../widgets/channel_notification_mode_sheet.dart';
import '../widgets/chat_day_separator.dart';
import '../widgets/empty_state.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_send_pipeline.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/message_bubble_frame.dart';
import '../widgets/reaction_chips.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/gif_message.dart';
import '../widgets/jump_to_bottom_button.dart';
import '../widgets/image_send_codec_binding.dart';
import '../widgets/image_send_preview_sheet.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/radio_stats_entry.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/translated_message_content.dart';
import '../widgets/unread_divider.dart';
import '../theme/mesh_theme.dart';
import '../widgets/future_timestamp_indicator.dart';
import '../widgets/mesh_ui.dart';
import 'app_settings_screen.dart';
import 'channel_message_path_screen.dart';
import 'map_screen.dart';
import 'region_management_screen.dart';
import '../storage/region_store.dart';
import '../utils/share_origin.dart';
import '../services/chat_background_service.dart';
import '../widgets/chat_background.dart';
import '../widgets/holiday_animations.dart';

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
  final _holidayWatcher = HolidayTriggerWatcher();
  final _messageAreaKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  final ChatScrollController _scrollController = ChatScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
  ChannelMessage? _replyingToMessage;
  bool _useReplyRegion = false;
  final CommunityStore _communityStore = CommunityStore();
  final CommunityPskIndex _communityIndex = CommunityPskIndex();
  final Map<String, GlobalKey> _messageKeys = {};
  bool _isLoadingOlder = false;
  bool _communitiesLoaded = false;

  /// Per-screen image-id allocator. The id is 8 bits and the reassembly key also
  /// carries the sender prefix and channel, so a per-screen allocator is enough
  /// to keep two images in the same channel apart.
  final ImageIdAllocator _imageIds = ImageIdAllocator();

  /// Chunks acked so far / total, while an image send is in flight. Both 0 when
  /// nothing is being sent.
  int _imageSendSent = 0;
  int _imageSendTotal = 0;

  MeshCoreConnector? _connector;
  final ChatSendGuard _sendGuard = ChatSendGuard();
  bool _channelSkipNextBottomSnap = false;
  String? _unreadDividerMessageId;
  _TranscriptLayout? _transcriptLayout;
  ReceivedImageStore? _watchedImageStore;
  int _imageStoreVersion = 0;
  ModalRoute<dynamic>? _route;

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

  /// Loads the community list; also re-run whenever a covering route pops
  /// (see [_onCoveringRouteStatus]).
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      _route?.secondaryAnimation?.removeStatusListener(_onCoveringRouteStatus);
      _route = route;
      route?.secondaryAnimation?.addStatusListener(_onCoveringRouteStatus);
    }
  }

  /// Reloads communities when a route pushed on top of this one is popped,
  /// so a community joined or created elsewhere gets its badge and type here.
  void _onCoveringRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      _loadCommunities();
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onCoveringRouteStatus);
    _watchedImageStore?.removeListener(_onImageStoreChanged);
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
      _useReplyRegion = message.region?.isNotEmpty ?? false;
    });
    // Replying means typing next: open the keyboard on the composer.
    _textFieldFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
      _useReplyRegion = false;
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
                color: MeshPalette.magenta,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.people, size: 8, color: MeshPalette.ink),
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
                        // Hashtag channels get no type label: the # icon
                        // and name already say it, and the title needs the
                        // room.
                        final privacy = switch (Channel.getChannelType(
                          widget.channel,
                          _communityIndex,
                        )) {
                          ChannelType.public => context.l10n.channels_public,
                          ChannelType.hashtag => null,
                          ChannelType.private => context.l10n.channels_private,
                          ChannelType.communityPublic =>
                            context.l10n.community_publicChannel,
                          ChannelType.communityHashtag => null,
                        };
                        final ownRegion = connector.getChannelRegion(
                          widget.channel.index,
                        );
                        final region = connector.getEffectiveChannelRegion(
                          widget.channel.index,
                        );
                        final defaultSuffix = ownRegion.isEmpty
                            ? ' ${context.l10n.channels_regionDefaultSuffix}'
                            : '';
                        final radioDefault = connector.defaultFloodScopeName;
                        final regionText = region.isNotEmpty
                            ? '${context.l10n.channels_regionSetTo(region)}$defaultSuffix'
                            : radioDefault != null &&
                                  connector.channelUsesRadioDefaultScope(
                                    widget.channel.index,
                                  )
                            ? '${context.l10n.channels_regionSetTo(radioDefault)} ${context.l10n.channels_regionRadioDefaultSuffix}'
                            : null;
                        final subtitle = [?privacy, ?regionText].join(' • ');
                        if (subtitle.isEmpty) return const SizedBox.shrink();
                        return Text(
                          subtitle,
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
          Consumer<AppSettingsService>(
            builder: (context, settings, _) {
              final muteKey = widget.channel.muteKey;
              final notificationMode = settings.getChannelNotificationMode(
                muteKey,
              );
              return IconButton(
                tooltip: context.l10n.channels_notificationModeTooltip(
                  channelNotificationModeLabel(context, notificationMode),
                ),
                icon: Icon(
                  notificationMode == ChannelNotificationMode.muted
                      ? Icons.notifications_off
                      : notificationMode == ChannelNotificationMode.mentionsOnly
                      ? Icons.notification_important
                      : Icons.notifications,
                ),
                onPressed: () =>
                    showChannelNotificationModeSheet(context, muteKey),
              );
            },
          ),
          const RadioStatsIconButton(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'region') {
                openRegionSelectDialog(widget.channel);
              } else if (value == 'background') {
                showChatBackgroundSheet(
                  context,
                  ChatBackgroundService.channelKey(widget.channel),
                );
              } else if (value == 'clearChat') {
                _confirmClearChat();
              }
            },
            // Region lives here (and on a tap of the title) so the channel
            // name keeps its room in the app bar.
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'region',
                child: Row(
                  children: [
                    const Icon(Icons.landscape, size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.channels_regionSelect_Title),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'background',
                child: Row(
                  children: [
                    const Icon(Icons.wallpaper, size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.chatBackground_title),
                  ],
                ),
              ),
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
              child: ChatBackdrop(
                key: _messageAreaKey,
                chatKey: ChatBackgroundService.channelKey(widget.channel),
                child: Consumer<MeshCoreConnector>(
                  builder: (context, connector, child) {
                    final messages = connector.getChannelMessages(
                      widget.channel,
                    );
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
                    final layout = _transcriptLayoutFor(context, messages);

                    if (layout.length == 0) {
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

                    final urlImagesEnabled = connector
                        .isChannelUrlImagesEnabled(widget.channel.index);
                    final rowCount = layout.length;
                    final itemCount = rowCount + (_isLoadingOlder ? 1 : 0);

                    // Auto-scroll to bottom if user is already at bottom
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
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
                              final row = layout.rowAt(index, messages);
                              final GlobalKey messageKey;
                              if (layout.keyedIndices.contains(index)) {
                                messageKey = _messageKeys.putIfAbsent(
                                  row.id,
                                  GlobalKey.new,
                                );
                              } else {
                                messageKey = GlobalKey();
                              }
                              final isUnreadAnchor =
                                  _unreadDividerMessageId != null &&
                                  row.id == _unreadDividerMessageId;
                              return Container(
                                key: messageKey,
                                child: Builder(
                                  builder: (context) {
                                    final textScale = context
                                        .select<ChatTextScaleService, double>(
                                          (service) => service.scale,
                                        );
                                    final message = row.message;
                                    final bubble = message != null
                                        ? _buildMessageBubble(
                                            message,
                                            textScale,
                                            urlImagesEnabled,
                                          )
                                        : _buildImageBubble(
                                            row.image!,
                                            textScale,
                                          );
                                    final startsDay =
                                        index == rowCount - 1 ||
                                        !isSameChatDay(
                                          layout
                                              .rowAt(index + 1, messages)
                                              .receivedAt,
                                          row.receivedAt,
                                        );
                                    if (isUnreadAnchor || startsDay) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (startsDay)
                                            ChatDaySeparator(
                                              day: row.receivedAt,
                                            ),
                                          if (isUnreadAnchor)
                                            const UnreadDivider(),
                                          bubble,
                                        ],
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
            ),
            _buildInputBar(),
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

  Widget _buildMessageBubble(
    ChannelMessage message,
    double textScale,
    bool urlImagesEnabled,
  ) {
    final settingsService = context.watch<AppSettingsService>();
    final publicIpfsGateway = settingsService.settings.publicIpfsGateway;
    final enableTracing = settingsService.settings.enableMessageTracing;
    final regionOnHopsLine = settingsService.settings.regionOnHopsLine;
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

    final colors = MessageBubbleColors.of(context, isOutgoing: isOutgoing);
    final textColor = colors.text;
    final metaColor = colors.meta;
    const bodyFontSize = 14.0;

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
      );
    }

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
                  child: MessageBubbleFrame(
                    isOutgoing: isOutgoing,
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
                        else if (urlImagesEnabled)
                          MessageUrlImageFutureBuilder(
                            messageId: message.messageId,
                            text: message.text,
                            publicGateway: publicIpfsGateway,
                            builder: (context, snapshot) {
                              final imageAttachment = snapshot.data;

                              if (imageAttachment != null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          fontSize: bodyFontSize * textScale,
                                          fontStyle: FontStyle.italic,
                                          color: textColor.withValues(
                                            alpha: 0.72,
                                          ),
                                        ),
                                        onSecondaryTap: PlatformInfo.isDesktop
                                            ? () => _showMessageActions(message)
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
                        if (displayPath.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Padding(
                            padding: gifId != null
                                ? const EdgeInsets.symmetric(horizontal: 8)
                                : EdgeInsets.zero,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RouteRegionChips(
                                  sameLine: regionOnHopsLine,
                                  children: [
                                    RouteChip(
                                      isDirect: (message.pathLength ?? -1) >= 0,
                                      hops: displayHopCount,
                                    ),
                                    if (message.region?.isNotEmpty ?? false)
                                      Padding(
                                        padding: regionOnHopsLine
                                            ? EdgeInsets.zero
                                            : const EdgeInsets.only(top: 2),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(
                                              MeshRadii.xs,
                                            ),
                                            border: Border.all(
                                              color: scheme.outlineVariant,
                                            ),
                                          ),
                                          child: Text(
                                            _displayRegion(message.region!),
                                            style: MeshTheme.mono(
                                              fontSize: 12 * textScale,
                                              color: metaColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (enableTracing) ...[
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      context.l10n.channels_via(
                                        _formatPathPrefixes(
                                          displayPath,
                                          displayPathHashWidth,
                                        ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: MeshTheme.mono(
                                        fontSize: 12 * textScale,
                                        color: metaColor,
                                      ),
                                    ),
                                  ),
                                ],
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
                                formatChatTime(context, message.timestamp),
                                style: MeshTheme.mono(
                                  fontSize: 12 * textScale,
                                  color: metaColor,
                                ),
                              ),
                              if (message.hasFutureTimestamp) ...[
                                const SizedBox(width: 4),
                                FutureTimestampIndicator(size: 16 * textScale),
                              ],
                              if (enableTracing &&
                                  !isOutgoing &&
                                  message.repeatCount > 0) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.repeat,
                                  size: 14 * textScale,
                                  color: metaColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${message.repeatCount}',
                                  style: MeshTheme.mono(
                                    fontSize: 12 * textScale,
                                    color: metaColor,
                                  ),
                                ),
                              ],
                              if (isOutgoing) ...[
                                const SizedBox(width: 4),
                                MessageStatusIcon(
                                  size: 16 * textScale,
                                  isAcked: false,
                                  isChannel: true,
                                  repeatCount: message.repeatCount,
                                  resendProgress: context
                                      .read<MeshCoreConnector>()
                                      .channelResendProgress(message.messageId),
                                  hopShortfall: context
                                      .read<MeshCoreConnector>()
                                      .channelHopShortfall(message.messageId),
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
              child: ReactionChips(
                reactions: message.reactions,
                onTap: (_) => _showReactionsReport(message),
              ),
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

  /// Decoded preview of quoted text: a GIF thumbnail, a location label, or
  /// the text itself — never the raw `g:`/marker payload. Shared by the reply
  /// quote inside bubbles and the "Replying to" banner above the composer.
  Widget _buildReplyContent(
    String replyText,
    double textScale, {
    required Color color,
    int maxLines = 2,
    double gifSize = 80,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final gifId = GifHelper.parseGif(replyText);
    final poi = parseMarkerText(replyText);
    if (gifId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: GifMessage(
          url: 'https://media.giphy.com/media/$gifId/giphy.gif',
          backgroundColor: colorScheme.surfaceContainerHighest,
          fallbackTextColor: color,
          maxSize: gifSize,
        ),
      );
    }
    if (poi != null) {
      return Row(
        children: [
          Icon(Icons.location_on_outlined, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.l10n.chat_location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12 * textScale, color: color),
            ),
          ),
        ],
      );
    }
    return Text(
      replyText,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12 * textScale,
        color: color,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildReplyPreview(ChannelMessage message, double textScale) {
    final connector = context.read<MeshCoreConnector>();
    final isOwnNode = message.replyToSenderName == connector.selfName;
    final colorScheme = Theme.of(context).colorScheme;
    final contentPreview = _buildReplyContent(
      message.replyToText ?? '',
      textScale,
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    );

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
                fontSize: 12 * textScale,
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

  void _showReactionsReport(ChannelMessage message) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.reaction_report),
        content: SizedBox(
          width: double.maxFinite,
          child: Scrollbar(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: message.reactionList().map((reaction) {
                return Container(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(MeshRadii.pill),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reaction.emoji,
                            style: MeshTheme.emoji(fontSize: 16),
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reaction.senderName ??
                                  context.l10n.reaction_unknownSender,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
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
    final bubble = MeshBubbleTheme.of(context);
    final textColor = isOutgoing ? bubble.meInk : scheme.onSurface;
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

  /// The image codec, or null when it is not registered (screen tests).
  ImageCodecService? get _imageCodec {
    try {
      return context.read<ImageCodecService>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  void _explainImageCodecNotReady(ImageCodecService codec) {
    final l10n = context.l10n;
    final availability = codec.availability;
    final String message;
    switch (availability) {
      case ImageCodecAvailability.downloading:
        message = l10n.imageSend_codecDownloading;
      case ImageCodecAvailability.unavailable:
        message = codec.unavailableReason ?? l10n.imageSend_codecUnavailable;
      case ImageCodecAvailability.disabled:
        message = codec.needsModelDownload
            ? l10n.imageSend_modelNotDownloaded
            : codec.statusReason ?? l10n.imageSend_codecDisabled;
      case ImageCodecAvailability.ready:
        return;
    }
    showDismissibleSnackBar(
      context,
      content: Text(message),
      action: availability == ImageCodecAvailability.disabled
          ? SnackBarAction(
              label: l10n.receivedImage_openSettings,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const AppSettingsScreen(focusImageMessages: true),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _sendImageViaIpfs() {
    final connector = context.read<MeshCoreConnector>();
    return attachIpfsLinkToDraft(
      context: context,
      controller: _textController,
      focusNode: _textFieldFocusNode,
      maxBytes: maxChannelMessageBytes(connector.selfName),
      encodeOutbound: (text) {
        final replyTo = _replyingToMessage;
        return connector.prepareChannelOutboundText(
          widget.channel.index,
          replyTo == null ? text : '${_replyPrefix(replyTo)}$text',
        );
      },
    );
  }

  /// Takes no [BuildContext]: it uses the [State]'s own, so the `mounted`
  /// checks around each `await` are the ones that actually govern it.
  Future<void> _showImageSendPreview() async {
    final codec = _imageCodec;
    if (codec == null) return;
    if (codec.availability != ImageCodecAvailability.ready) {
      _explainImageCodecNotReady(codec);
      return;
    }
    final connector = context.read<MeshCoreConnector>();

    // The picked bytes are kept past the preview on purpose: the sender's own
    // bubble renders from them (see [_registerOutgoingImage]). The bitstream
    // cannot serve — turning it back into pixels is a ~2.16 GiB, ~1 s decode
    // of an image the sender is already holding.
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // The codec centre-crops to 512x512 anyway, so there is nothing to
        // gain from decoding a 12 MP original — but stay well above 512 so the
        // crop still has detail to work with.
        maxWidth: 2048,
        maxHeight: 2048,
      );
    } on Exception catch (e) {
      debugPrint('image pick failed: $e');
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_imagePickFailed),
      );
      return;
    }
    if (picked == null) return; // cancelled at the picker

    final Uint8List sourceBytes;
    final int originalFileBytes;
    try {
      sourceBytes = await picked.readAsBytes();
      // XFile.length() is the on-disk size — what the sheet shows against the
      // transmitted size — and unlike dart:io it also works on web.
      originalFileBytes = await picked.length();
    } on Exception catch (e) {
      debugPrint('image read failed: $e');
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_imagePickFailed),
      );
      return;
    }

    if (!mounted) return;
    final result = await showImageSendPreviewSheet(
      context: context,
      imageBytes: sourceBytes,
      originalFileBytes: originalFileBytes,
      codec: codec,
    );
    if (result == null) return; // cancelled at the preview
    if (!mounted) return;
    await _sendImage(connector, result, sourceBytes: sourceBytes);
  }

  /// Chunks [result] and puts it on the channel as GRP_DATA packets.
  ///
  /// Chunk geometry, CRC and parity all come from [buildImageChunks] \u2014 the
  /// single source of truth for the wire format \u2014 and the blobs go out through
  /// [MeshCoreConnector.sendImageChunks] as one list, so the connector owns the
  /// inter-chunk pacing and the whole image sits inside one scoped send.
  ///
  /// [sourceBytes] is the original picked file. It is only ever used to draw
  /// the sender's own bubble; nothing about the transmission depends on it.
  Future<void> _sendImage(
    MeshCoreConnector connector,
    ImageSendPreviewResult result, {
    required Uint8List sourceBytes,
  }) async {
    final l10n = context.l10n;

    if (!connector.supportsChannelData) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.imageSend_deviceUnsupported),
      );
      return;
    }
    final senderPrefix = connector.imageSenderPrefix;
    if (senderPrefix == null) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.imageSend_deviceUnsupported),
      );
      return;
    }

    final ImageChunkSet chunkSet;
    try {
      chunkSet = buildImageChunks(
        payload: result.payload,
        metadata: ImageStreamMetadata(
          rate: result.rate,
          squareSize: kImageCodecSquareSize,
          // The codec stretched the whole frame into a square, which the
          // receiver cannot undo from pixels alone. Naming the source shape
          // here costs no extra bytes -- it rides in spare bits of the metadata
          // byte -- and lets the receiver letterbox back.
          aspectCode: await _aspectCodeOf(sourceBytes),
        ),
        senderPrefix: senderPrefix,
        imgId: _imageIds.next(),
        parity: result.includeParity,
      );
    } on ArgumentError {
      if (!mounted) return;
      showDismissibleSnackBar(context, content: Text(l10n.imageSend_tooLarge));
      return;
    }
    if (!mounted) return;

    // Pace on the measured per-packet airtime when the radio parameters are
    // known; fall back to the base gap when they are not, rather than
    // hammering the channel back-to-back.
    final total = result.airtime;
    final perPacket = total == null
        ? Duration.zero
        : Duration(
            microseconds:
                total.inMicroseconds ~/
                (result.packetCount == 0 ? 1 : result.packetCount),
          );

    setState(() {
      _imageSendTotal = chunkSet.blobs.length;
      _imageSendSent = 0;
    });
    try {
      final sent = await connector.sendImageChunks(
        chunkSet.blobs,
        channelIndex: widget.channel.index,
        interChunkDelay: imageSendChunkGap(perPacket),
        onProgress: (sentChunks, totalChunks) {
          if (!mounted) return;
          setState(() => _imageSendSent = sentChunks);
        },
      );
      // Register before the snack bar, so the bubble is on screen by the time
      // the confirmation appears rather than a frame behind it.
      if (sent) {
        await _registerOutgoingImage(
          result: result,
          chunkSet: chunkSet,
          senderPrefix: senderPrefix,
          sourceBytes: sourceBytes,
        );
      }
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          sent
              ? l10n.imageSend_sentConfirmation(chunkSet.blobs.length)
              : l10n.imageSend_deviceUnsupported,
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.imageSend_sendFailed('$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _imageSendTotal = 0;
          _imageSendSent = 0;
        });
      }
    }
  }

  /// Puts the image the user just sent into [ReceivedImageStore] so it appears
  /// in their own transcript.
  ///
  /// GRP_DATA is not echoed back to the sender and an image is not a
  /// [ChannelMessage], so without this the sender sees a "sent" snack bar and
  /// an otherwise empty conversation. The entry lands in `decoded` directly —
  /// an outgoing image is never queued for inference, so showing your own
  /// photo costs no model memory.
  ///
  /// Best effort throughout: a failure here has already been preceded by a
  /// successful transmission, so it must not turn into an error the user sees.
  Future<void> _registerOutgoingImage({
    required ImageSendPreviewResult result,
    required ImageChunkSet chunkSet,
    required int senderPrefix,
    required Uint8List sourceBytes,
  }) async {
    final ReceivedImageStore store;
    try {
      store = context.read<ReceivedImageStore>();
    } on ProviderNotFoundException {
      return; // screen test without the store
    }
    final previewPng = await _squarePreviewPng(sourceBytes);
    if (previewPng == null) return;
    try {
      await store.registerOutgoing(
        channelIndex: widget.channel.index,
        channelId: widget.channel.storageId,
        // The same 16 bits the chunk header carries, so the entry keys the
        // same way an inbound one would.
        senderPrefix: senderPrefix,
        imgId: chunkSet.imgId,
        previewPng: previewPng,
        rate: aeicRatePointForUi(result.rate),
        chunkCount: chunkSet.dataChunkCount,
        aspectCode: await _aspectCodeOf(sourceBytes),
      );
    } on Exception catch (error) {
      debugPrint('outgoing image registration failed: $error');
    }
  }

  /// The [kImageAspectCodes] entry matching [imageBytes]'s shape.
  ///
  /// Decodes only to read the dimensions. Falls back to "unknown" (rendered
  /// square) rather than guessing, because asserting the wrong shape would
  /// letterbox the receiver's copy incorrectly and look like a codec bug.
  static Future<int> _aspectCodeOf(Uint8List imageBytes) async {
    ui.Image? image;
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      image = (await codec.getNextFrame()).image;
      return imageAspectCodeFor(image.width, image.height);
    } on Exception catch (error) {
      debugPrint('aspect probe failed: $error');
      return kImageAspectUnknown;
    } finally {
      image?.dispose();
    }
  }

  /// [imageBytes] stretched to 512x512, as PNG.
  ///
  /// This is what the preview sheet showed (`BoxFit.fill` on a 1:1 box is
  /// exactly the stretch the codec applies) and what the codec actually
  /// encoded, so the sender's bubble matches both. Deliberately not a decode of the
  /// bitstream: that would cost ~2.16 GiB and ~1 s to reproduce, less well, an
  /// image this device is already holding in memory.
  ///
  /// Returns null rather than throwing on an undecodable source — the send has
  /// already happened by the time this runs.
  static Future<Uint8List?> _squarePreviewPng(Uint8List imageBytes) async {
    ui.Image? source;
    ui.Image? square;
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      source = (await codec.getNextFrame()).image;
      final dst = kImageCodecSquareSize.toDouble();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        source,
        // Whole frame, matching _toSquareRgb in image_codec_service.dart. If
        // one of these two is a crop and the other a stretch, the sender's
        // bubble silently stops matching what the receiver sees.
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, dst, dst),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      square = await recorder.endRecording().toImage(
        kImageCodecSquareSize,
        kImageCodecSquareSize,
      );
      final data = await square.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } on Exception catch (error) {
      debugPrint('outgoing image preview render failed: $error');
      return null;
    } finally {
      source?.dispose();
      square?.dispose();
    }
  }

  /// The merged, ordered transcript (messages + AEIC images), memoised.
  ///
  /// Sorting the whole transcript and rebuilding the key bookkeeping on every
  /// connector notification is wasted work when this channel did not change
  /// (most notifications are about other chats, contacts or radio state), so
  /// the layout is only recomputed when the message list's identity, length or
  /// ends change, or the image store notified.
  ///
  /// Returns no images when [ReceivedImageStore] is not registered, so a screen
  /// test without the provider still renders. [context] must be the context
  /// of the element currently building (the `Consumer` builder's, not the
  /// `State`'s) — `watch` asserts on that.
  _TranscriptLayout _transcriptLayoutFor(
    BuildContext context,
    List<ChannelMessage> messages,
  ) {
    ReceivedImageStore? store;
    try {
      store = context.watch<ReceivedImageStore>();
    } on ProviderNotFoundException {
      store = null;
    }
    if (!identical(store, _watchedImageStore)) {
      _watchedImageStore?.removeListener(_onImageStoreChanged);
      _watchedImageStore = store;
      store?.addListener(_onImageStoreChanged);
      _imageStoreVersion++;
    }
    final cached = _transcriptLayout;
    if (cached != null &&
        cached.matches(messages, _imageStoreVersion, widget.channel.index)) {
      return cached;
    }
    final images = store == null
        ? const <ReceivedImageEntry>[]
        : store.entriesForChannel(widget.channel.storageId);
    final layout = _TranscriptLayout.build(
      messages: messages,
      images: images,
      imageVersion: _imageStoreVersion,
      channelIndex: widget.channel.index,
    );
    // Prune stale keys (deleted/cleared messages) to avoid unbounded growth.
    final liveIds = layout.ids.toSet();
    _messageKeys.removeWhere((id, _) => !liveIds.contains(id));
    _transcriptLayout = layout;
    return layout;
  }

  void _onImageStoreChanged() => _imageStoreVersion++;

  /// Bubble for one AEIC image, following the GIF-message precedent: minimal
  /// chrome, the renderer owns every state (receiving / decoding / failed) and
  /// the mandatory AI-reconstruction label.
  Widget _buildImageBubble(ReceivedImageEntry entry, double textScale) {
    final scheme = Theme.of(context).colorScheme;
    final isOutgoing = entry.isOutgoing;
    final bubbleTheme = MeshBubbleTheme.of(context);
    final textColor = isOutgoing ? bubbleTheme.meInk : scheme.onSurface;
    final metaColor = textColor.withValues(alpha: 0.65);

    final bubble = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isOutgoing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOutgoing) ...[
            _buildAvatar(_imageSenderLabel(entry), textScale),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isOutgoing ? bubbleTheme.me : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(MeshRadii.lg),
                border: Border.all(
                  color: isOutgoing
                      ? bubbleTheme.meBorder
                      : scheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOutgoing)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        top: 4,
                        bottom: 4,
                      ),
                      child: Text(
                        _imageSenderLabel(entry),
                        style: TextStyle(
                          fontSize: 13 * textScale,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ReceivedImageMessage(
                    streamId: entry.streamId,
                    isOutgoing: isOutgoing,
                    fallbackTextColor: textColor,
                    strings: _receivedImageStrings(context),
                    // The placeholder's "no model installed" tap lands here.
                    // `focusImageMessages` scrolls straight to the image block
                    // — it sits below six other sections, so the plain screen
                    // would open at the top with no sign of what was tapped for.
                    onOpenCodecSettings: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const AppSettingsScreen(focusImageMessages: true),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 4,
                    ),
                    child: Text(
                      formatChatTime(context, entry.firstSeen),
                      style: MeshTheme.mono(
                        fontSize: 12 * textScale,
                        color: metaColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      onLongPress: () => _showImageActions(entry),
      onSecondaryTap: () => _showImageActions(entry),
      child: bubble,
    );
  }

  void _showImageActions(ReceivedImageEntry entry) {
    final l10n = context.l10n;
    final canSave = entry.state == ReceivedImageState.decoded;
    showMeshSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                title: l10n.receivedImage_awaiting(
                  entry.bitstreamByteCount,
                  entry.totalChunks,
                ),
                subtitle: _imageSenderLabel(entry),
              ),
              if (canSave)
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text(l10n.receivedImage_save),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _saveImage(entry);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.receivedImage_packetInfo),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showImagePacketInfo(entry);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.common_delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context.read<ReceivedImageStore>().deleteImage(
                    entry.streamId,
                  );
                  if (!mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.chat_messageDeleted),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage(ReceivedImageEntry entry) async {
    final l10n = context.l10n;
    final shareOrigin = shareOriginOf(context);
    final png = await context.read<ReceivedImageStore>().ensurePng(
      entry.streamId,
    );
    if (!mounted) return;
    final shareText = l10n.receivedImage_shareCaption(entry.bitstreamByteCount);
    if (png == null ||
        !await saveImagePng(
          png,
          entry,
          shareText: shareText,
          sharePositionOrigin: shareOrigin,
        )) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.receivedImage_saveFailed),
      );
    }
  }

  void _showImagePacketInfo(ReceivedImageEntry entry) {
    final l10n = context.l10n;
    final decodeMs = entry.decodeMs;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.receivedImage_packetInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_imageSenderLabel(entry)),
            Text(formatChatTime(context, entry.firstSeen)),
            Text(
              l10n.receivedImage_awaiting(
                entry.bitstreamByteCount,
                entry.totalChunks,
              ),
            ),
            if (entry.recoveredWithParity)
              Text(l10n.receivedImage_parityRecovered),
            if (decodeMs != null) Text(l10n.receivedImage_decodeTime(decodeMs)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  /// GRP_DATA carries no sender name — only the 2-byte public-key prefix the
  /// chunk header stamps — so resolve that against the contact list and fall
  /// back to the raw prefix only when nobody matches.
  ///
  /// Two bytes is 65,536 values, so a collision between two known contacts is
  /// possible. When it happens the sender is genuinely ambiguous and naming
  /// either one would be a guess, so the prefix is shown instead.
  String _imageSenderLabel(ReceivedImageEntry entry) {
    final hex = entry.senderPrefix.toRadixString(16).padLeft(4, '0');
    final connector = context.read<MeshCoreConnector>();
    if (entry.isOutgoing) {
      return connector.selfName ?? context.l10n.receivedImage_senderPrefix(hex);
    }
    final matches = connector.contacts
        .where((c) => c.publicKeyHex.toLowerCase().startsWith(hex))
        .toList();
    if (matches.length == 1) return matches.single.name;
    return context.l10n.receivedImage_senderPrefix(hex);
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
    final replyRegion = message.region;
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
                    fontSize: 12 * textScale,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                _buildReplyContent(
                  message.text,
                  textScale,
                  color: scheme.onSurfaceVariant,
                  maxLines: 1,
                  gifSize: 48,
                ),
              ],
            ),
          ),
          if (replyRegion?.isNotEmpty ?? false)
            InkWell(
              borderRadius: BorderRadius.circular(MeshRadii.xs),
              onTap: () => setState(() => _useReplyRegion = !_useReplyRegion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _useReplyRegion
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(MeshRadii.xs),
                  border: Border.all(
                    color: _useReplyRegion
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  context.l10n.channels_regionSetTo(replyRegion!),
                  style:
                      MeshTheme.mono(
                        fontSize: 12 * textScale,
                        color: _useReplyRegion
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ).copyWith(
                        decoration: _useReplyRegion
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: context.l10n.chat_cancelReply,
            onPressed: _cancelReply,
            color: scheme.onSurfaceVariant,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  /// "Sending image — packet 2 of 3", above the composer.
  ///
  /// A per-chunk figure rather than a spinner because an image occupies the
  /// channel for seconds and the user needs to see it advancing.
  Widget _buildImageSendProgress(ColorScheme scheme) {
    final total = _imageSendTotal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.imageSend_sendingProgress(_imageSendSent, total),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? null : _imageSendSent / total,
          ),
        ],
      ),
    );
  }

  /// The `@[name] ` prefix a reply prepends to the outgoing text.
  static String _replyPrefix(ChannelMessage replyTo) =>
      '@[${replyTo.senderName}] ';

  Widget _buildInputBar() {
    // Only the fields the composer depends on, so unrelated connector
    // notifications (adverts, other chats, radio stats) don't rebuild it.
    final (selfName, useEncoder) = context
        .select<MeshCoreConnector, (String?, bool)>(
          (c) => (
            c.selfName,
            c.isChannelSmazEnabled(widget.channel.index) ||
                c.isChannelCyr2LatEnabled(widget.channel.index),
          ),
        );
    final showImageAction = context.select<AppSettingsService, bool>(
      (s) => s.settings.imageMessagesEnabled,
    );
    final showIpfsAction = context.select<AppSettingsService, bool>(
      (s) => s.settings.uploadIpfsEndpoint.trim().isNotEmpty,
    );
    final replyTo = _replyingToMessage;
    final replyPrefixBytes = replyTo == null
        ? 0
        : utf8.encode(_replyPrefix(replyTo)).length;
    final maxBytes = math.max(
      0,
      maxChannelMessageBytes(selfName) - replyPrefixBytes,
    );
    final scheme = Theme.of(context).colorScheme;
    return ChatComposer(
      controller: _textController,
      focusNode: _textFieldFocusNode,
      maxBytes: maxBytes,
      encoder: useEncoder
          ? (text) => context
                .read<MeshCoreConnector>()
                .prepareChannelOutboundText(widget.channel.index, text)
          : null,
      onSend: _sendMessage,
      sendTooltip: context.l10n.chat_sendMessage,
      header: [
        if (replyTo != null)
          Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              return _buildReplyBanner(textScale);
            },
          ),
        if (_imageSendTotal > 0) _buildImageSendProgress(scheme),
      ],
      actionsBuilder: () {
        final connector = context.read<MeshCoreConnector>();
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
          if (showImageAction)
            ChatComposerAction(
              id: 'meshcore-image',
              icon: Icons.image_outlined,
              label: context.l10n.chat_sendImageLora,
            ),
          if (hasShareableLocation(
            connector.selfLatitude,
            connector.selfLongitude,
          ))
            ChatComposerAction(
              id: 'send-my-location',
              icon: Icons.my_location,
              label: context.l10n.chat_shareMyLocation,
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
          case 'meshcore-image':
            _showImageSendPreview();
          case 'send-my-location':
            _shareMyLocation(context.read<MeshCoreConnector>());
        }
      },
    );
  }

  /// Shares the radio's own position as a map marker on this channel. It is
  /// not a reply, so any reply in progress stays open for the next message;
  /// it shares the text send guard and cooldown.
  Future<void> _shareMyLocation(MeshCoreConnector connector) {
    return shareMyLocationMarker(
      context: context,
      connector: connector,
      guard: _sendGuard,
      logTag: 'ChannelChat',
      send: (markerText) =>
          connector.sendChannelMessage(widget.channel, markerText),
    );
  }

  Future<void> _sendMessage() {
    return _sendGuard.runExclusive(_sendMessageInner);
  }

  Future<void> _sendMessageInner() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    // Capture the reply target now; the user may change it while the
    // outgoing translation runs.
    final replyTo = _replyingToMessage;
    final replyRegion = _useReplyRegion ? replyTo?.region : null;

    if (!_sendGuard.checkCooldown(context)) return;

    final connector = context.read<MeshCoreConnector>();
    final translation = await translateOutgoingText(context, text);
    if (translation == null || !mounted) return;

    String messageText = translation.text;
    if (replyTo != null) {
      messageText = '${_replyPrefix(replyTo)}$messageText';
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

    // Keep anything the user typed or a new reply picked during translation.
    if (_textController.text.trim() == text) {
      _textController.clear();
    }
    if (identical(_replyingToMessage, replyTo)) {
      _cancelReply();
    }
    _textFieldFocusNode.requestFocus();
    connector.sendChannelMessage(
      widget.channel,
      messageText,
      originalText: translation.originalText,
      translatedLanguageCode: translation.languageCode,
      translationModelId: translation.modelId,
      region: replyRegion,
      replyTo: replyTo,
    );
    // Only a dispatched send starts the cooldown.
    _sendGuard.markDispatched();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                title: message.text.characters.length > 40
                    ? '${message.text.characters.take(40)}…'
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
              if (message.pathBytes.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(context.l10n.chat_viewPathOnMap),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChannelMessagePathMapScreen(
                          message: message,
                          channelMessage: true,
                        ),
                      ),
                    );
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
      ),
    );
  }

  void _showEmojiPicker(ChannelMessage message) {
    showMeshSheet(
      context,
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
    final hash = message.computeReactionHash();
    final reactionText = ReactionHelper.encodeReaction(hash, emojiIndex);
    connector.sendChannelMessage(widget.channel, reactionText);
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await confirmClearChat(
      context,
      message: context.l10n.channels_clearChatConfirm,
    );
    if (confirmed) {
      if (!mounted) return;
      context.read<MeshCoreConnector>().clearMessagesForChannel(
        widget.channel.index,
      );
      final channelId = widget.channel.storageId;
      if (channelId == null) return;
      try {
        await context.read<ReceivedImageStore>().deleteImagesForChannelId(
          channelId,
        );
      } on ProviderNotFoundException {
        return;
      }
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

  String _displayRegion(String region) {
    return region.startsWith('#') ? region.substring(1) : region;
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

  bool _canForceUnscoped(BuildContext context) =>
      context.read<MeshCoreConnector>().supportsExplicitUnscopedFlood;

  bool _hasOwnAssignment(BuildContext context) {
    final connector = context.read<MeshCoreConnector>();
    final index = widget.channel.index;
    return connector.hasChannelRegion(index) ||
        connector.isChannelExplicitlyUnscoped(index);
  }

  /// On firmware that cannot force an unscoped flood, explain that floods
  /// without a region still use the radio's default region.
  List<Widget> _buildRadioDefaultNote(BuildContext context) {
    final connector = context.read<MeshCoreConnector>();
    final radioDefault = connector.defaultFloodScopeName;
    if (radioDefault == null || connector.supportsExplicitUnscopedFlood) {
      return const [];
    }
    return [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          context.l10n.channels_regionRadioDefaultApplies(radioDefault),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ];
  }

  Widget _buildUnscopedTile(BuildContext context) {
    final connector = context.read<MeshCoreConnector>();
    final selected = connector.isChannelExplicitlyUnscoped(
      widget.channel.index,
    );
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(Icons.public_off, color: selected ? primary : null),
      title: Text(context.l10n.settings_regionNoRegion),
      trailing: selected ? Icon(Icons.check, color: primary) : null,
      tileColor: selected ? primary.withValues(alpha: 0.16) : null,
      onTap: () {
        // Tapping the already-selected option clears it back to the default.
        connector.setChannelRegion(
          widget.channel.index,
          selected ? '' : kUnscopedRegion,
        );
        Navigator.pop(context);
      },
    );
  }

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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.l10n.channels_regionSelectExplanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ..._buildRadioDefaultNote(context),
            const SizedBox(height: 8),
            if (_canForceUnscoped(context)) _buildUnscopedTile(context),
            if (regions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.channels_regionEmpty),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final selected = selectedIndex == index;
                    final primary = Theme.of(context).colorScheme.primary;
                    return ListTile(
                      leading: Icon(
                        Icons.landscape,
                        color: selected ? primary : null,
                      ),
                      title: Text(regions[index]),
                      trailing: selected
                          ? Icon(Icons.check, color: primary)
                          : null,
                      tileColor: selected
                          ? primary.withValues(alpha: 0.16)
                          : null,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: !_hasOwnAssignment(context)
                      ? null
                      : () {
                          context.read<MeshCoreConnector>().setChannelRegion(
                            widget.channel.index,
                            '',
                          );
                          Navigator.pop(context);
                        },
                  child: Text(context.l10n.common_clear),
                ),
                TextButton(
                  onPressed: () async {
                    await pushRegionManagementScreen(context);
                    if (!mounted) return;
                    loadRegions();
                  },
                  child: Text(context.l10n.channels_manageRegions),
                ),
              ],
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

/// One row of the channel transcript.
///
/// Exactly one of [message] / [image] is non-null. Images cannot be
/// `ChannelMessage`s: they arrive as GRP_DATA chunks with no text frame behind
/// them, are keyed on (sender prefix, img id, channel) rather than a message id,
/// and are persisted by [ReceivedImageStore] instead of the channel message
/// store.
@immutable
class _ChannelChatRow {
  final ChannelMessage? message;
  final ReceivedImageEntry? image;

  const _ChannelChatRow({this.message, this.image});

  /// Local arrival time, used for ordering and day separators so a sender
  /// clock running ahead cannot pin a row to the bottom (#584).
  DateTime get receivedAt => message?.receivedAt ?? image!.firstSeen;

  /// Stable identity for the scroll-to-message [GlobalKey] map. The `aeic:`
  /// prefix keeps a stream id from ever colliding with a message id.
  String get id => message?.messageId ?? 'aeic:${image!.streamId}';
}

/// Memoised ordering of a channel transcript, newest first.
///
/// Rows hold positions, not message objects: the connector replaces messages
/// in place (status, repeats, reactions) without changing their order or id,
/// so [rowAt] always reads the current object from the live list.
class _TranscriptLayout {
  final List<ChannelMessage> _source;
  final int _sourceLength;
  final String? _firstId;
  final String? _lastId;
  final int _imageVersion;
  final int _channelIndex;

  /// Newest first. `>= 0` is a message index; `< 0` is image `-(i + 1)`.
  final List<int> _order;
  final List<ReceivedImageEntry> _images;

  /// Row ids, aligned with [_order].
  final List<String> ids;

  /// Two messages can collide on messageId (same ms + name/text hash). Only
  /// the first occurrence owns the shared GlobalKey used for
  /// scroll-to-message; duplicates get a local key so no two widgets share
  /// one GlobalKey.
  final Set<int> keyedIndices;

  _TranscriptLayout._(
    this._source,
    this._sourceLength,
    this._firstId,
    this._lastId,
    this._imageVersion,
    this._channelIndex,
    this._order,
    this._images,
    this.ids,
    this.keyedIndices,
  );

  factory _TranscriptLayout.build({
    required List<ChannelMessage> messages,
    required List<ReceivedImageEntry> images,
    required int imageVersion,
    required int channelIndex,
  }) {
    DateTime timeOf(int code) =>
        code >= 0 ? messages[code].receivedAt : images[-code - 1].firstSeen;
    // Images are not ChannelMessages: they arrive as GRP_DATA chunks and are
    // owned by ReceivedImageStore, so the two sources are merged here in
    // arrival (receivedAt) order and the list indexes rows, not messages.
    final order = <int>[
      for (var i = 0; i < messages.length; i++) i,
      for (var i = 0; i < images.length; i++) -(i + 1),
    ];
    // Stable ascending sort, then reversed so newest appear at the bottom of
    // the reversed ListView.
    mergeSort<int>(order, compare: (a, b) => timeOf(a).compareTo(timeOf(b)));
    final reversed = order.reversed.toList(growable: false);
    final ids = <String>[
      for (final code in reversed)
        code >= 0
            ? messages[code].messageId
            : 'aeic:${images[-code - 1].streamId}',
    ];
    final seen = <String>{};
    final keyed = <int>{};
    for (var i = 0; i < ids.length; i++) {
      if (seen.add(ids[i])) keyed.add(i);
    }
    return _TranscriptLayout._(
      messages,
      messages.length,
      messages.isEmpty ? null : messages.first.messageId,
      messages.isEmpty ? null : messages.last.messageId,
      imageVersion,
      channelIndex,
      reversed,
      images,
      ids,
      keyed,
    );
  }

  int get length => _order.length;

  bool matches(List<ChannelMessage> messages, int imageVersion, int channel) {
    return identical(messages, _source) &&
        messages.length == _sourceLength &&
        imageVersion == _imageVersion &&
        channel == _channelIndex &&
        (messages.isEmpty ? null : messages.first.messageId) == _firstId &&
        (messages.isEmpty ? null : messages.last.messageId) == _lastId;
  }

  _ChannelChatRow rowAt(int index, List<ChannelMessage> messages) {
    final code = _order[index];
    return code >= 0
        ? _ChannelChatRow(message: messages[code])
        : _ChannelChatRow(image: _images[-code - 1]);
  }
}

/// [ReceivedImageStrings] built from the app's localizations.
///
/// The R6 badge and caption are deliberately absent from this class — they are
/// private consts in `received_image_message.dart` and must stay mandatory.
ReceivedImageStrings _receivedImageStrings(BuildContext context) {
  final l10n = context.l10n;
  return ReceivedImageStrings(
    incoming: l10n.receivedImage_incoming,
    queued: l10n.receivedImage_queued,
    tapToDecode: l10n.receivedImage_tapToDecode,
    awaiting: l10n.receivedImage_awaiting,
    tapToProcess: l10n.receivedImage_tapToProcess,
    decoding: l10n.receivedImage_decoding,
    incomplete: l10n.receivedImage_incomplete,
    corrupt: l10n.receivedImage_corrupt,
    decoderMissing: l10n.receivedImage_decoderMissing,
    evicted: l10n.receivedImage_evicted,
    retry: l10n.receivedImage_retry,
    decodeAgain: l10n.receivedImage_decodeAgain,
    openSettings: l10n.receivedImage_openSettings,
  );
}

/// A message's route chip and region chip: stacked by default, or side by
/// side (wrapping on narrow bubbles) when "Region next to hop count" is on.
class _RouteRegionChips extends StatelessWidget {
  const _RouteRegionChips({required this.sameLine, required this.children});

  final bool sameLine;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (sameLine) {
      // Flexible bounds the Wrap's width inside the bubble's Row so a long
      // region name wraps under the hop chip instead of overflowing.
      return Flexible(
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
