import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/app_logger.dart';
import '../utils/platform_info.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/cyr2lat.dart';
import '../helpers/message_url_image_helper.dart';
import '../helpers/path_helper.dart';
import '../helpers/reaction_helper.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/empty_state.dart';
import '../helpers/chat_scroll_controller.dart';
import '../helpers/gif_helper.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../l10n/contact_localization.dart';
import '../models/message.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/chat_text_scale_service.dart';
import '../services/path_history_service.dart';
import '../services/translation_service.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/byte_count_input.dart';
import 'channel_message_path_screen.dart';
import 'map_screen.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/gif_message.dart';
import '../widgets/jump_to_bottom_button.dart';
import '../widgets/gif_picker.dart';
import '../widgets/message_translation_button.dart';
import '../widgets/routing_sheet.dart';
import '../widgets/radio_stats_entry.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/translated_message_content.dart';
import '../l10n/l10n.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/unread_divider.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';
import 'telemetry_screen.dart';

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
  final _textController = TextEditingController();
  final _scrollController = ChatScrollController();
  final _textFieldFocusNode = FocusNode();
  final GlobalKey _unreadScrollKey = GlobalKey();
  bool _isLoadingOlder = false;
  MeshCoreConnector? _connector;
  Message? _pendingUnreadScrollTarget;
  String? _unreadDividerMessageId;
  DateTime? _lastTextSendAt;

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
      final keyHex = widget.contact.publicKeyHex;
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
      connector.setActiveContact(keyHex);
      _connector = connector;
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
    _connector?.setActiveContact(null);
    _scrollController.showJumpToBottom.removeListener(_clearDividerAtBottom);
    _textFieldFocusNode.removeListener(_onTextFieldFocusChange);
    _textFieldFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer2<PathHistoryService, MeshCoreConnector>(
          builder: (context, pathService, connector, _) {
            final contact = _resolveContact(connector);
            final unreadCount = connector.getUnreadCountForContactKey(
              widget.contact.publicKeyHex,
            );
            final unreadLabel = context.l10n.chat_unread(unreadCount);
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
                    child: Text(
                      '$pathLabel • $unreadLabel',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
        bottom: const SyncProgressAppBarBottom(),
        actions: [
          const RadioStatsIconButton(),
          Consumer<MeshCoreConnector>(
            builder: (context, connector, _) {
              final contact = _resolveContact(connector);

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
                    case 'telemetry':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TelemetryScreen(contact: widget.contact),
                        ),
                      );
                    case 'clearChat':
                      _confirmClearChat(context, connector);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'routing',
                    child: Row(
                      children: [
                        const Icon(Icons.route, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.routing_title),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.contact_info),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'telemetry',
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.contact_telemetry),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.contact_settings),
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
              );
            },
          ),
        ],
      ),
      body: Consumer<MeshCoreConnector>(
        builder: (context, connector, child) {
          final messages = connector.getMessages(widget.contact);
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(messages, connector),
                    JumpToBottomButton(scrollController: _scrollController),
                  ],
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
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: context.l10n.chat_noMessages,
      subtitle: context.l10n.chat_sendMessageTo(
        _resolveContact(context.read<MeshCoreConnector>()).name,
      ),
    );
  }

  Widget _buildMessageList(
    List<Message> messages,
    MeshCoreConnector connector,
  ) {
    // Reverse messages so newest appear at bottom with reverse: true
    final reversedMessages = messages.reversed.toList();
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
                onLongPress: () => _showMessageActions(message, contact),
                onRetryReaction: (msg, emoji) =>
                    _sendReaction(msg, contact, emoji),
              );
              final isUnreadAnchor =
                  _unreadDividerMessageId != null &&
                  message.messageId == _unreadDividerMessageId;
              final child = isUnreadAnchor
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [const UnreadDivider(), bubble],
                    )
                  : bubble;
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
    final maxBytes = maxContactMessageBytes();
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettingsService>().settings;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_circle_outline),
                position: PopupMenuPosition.over,
                offset: const Offset(0, -64),
                tooltip: context.l10n.chat_selectSendAction,
                onSelected: (action) {
                  if (action == 'gif') _showGifPicker(context);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'gif',
                    child: Row(
                      children: [
                        const Icon(Icons.gif_box),
                        const SizedBox(width: 12),
                        Text(context.l10n.chat_sendGif),
                      ],
                    ),
                  ),
                ],
              ),
              if (settings.translationEnabled)
                MessageTranslationButton(
                  enabled: settings.composerTranslationEnabled,
                  languageCode: settings.translationTargetLanguageCode,
                  onPressed: _showTranslationOptions,
                ),
              // No image button here: the image wire format is GRP_DATA, a
              // channel primitive with no DM equivalent (see the note at the
              // top of this file).
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
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.numpadEnter)) {
                            _sendMessage(connector);
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
                      onSubmitted: (_) => _sendMessage(connector),
                      encoder:
                          (connector.isContactSmazEnabled(
                                widget.contact.publicKeyHex,
                              ) ||
                              connector.isContactCyr2LatEnabled(
                                widget.contact.publicKeyHex,
                              ))
                          ? (text) => connector.prepareContactOutboundText(
                              widget.contact,
                              text,
                            )
                          : null,
                      decoration: InputDecoration(
                        hintText: context.l10n.chat_typeMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MeshRadii.md),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MeshRadii.md),
                          borderSide: BorderSide(color: scheme.outlineVariant),
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
                      tooltip: context.l10n.chat_sendMessageTo(
                        _resolveContact(connector).name,
                      ),
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
                              _sendMessage(connector);
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

  Future<void> _sendMessage(MeshCoreConnector connector) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastTextSendAt != null &&
        now.difference(_lastTextSendAt!) < const Duration(seconds: 1)) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_sendCooldown),
      );
      return;
    }
    _lastTextSendAt = now;

    final settings = context.read<AppSettingsService>().settings;
    final translationService = context.read<TranslationService>();
    var outgoingText = text;
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
          outgoingText = result.translatedText;
          originalText = text;
          translatedLanguageCode = result.targetLanguageCode;
          translationModelId = result.modelId;
        }
      }
    }
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

    _textController.clear();
    _textFieldFocusNode.requestFocus();
    connector.sendMessage(
      _resolveContact(connector),
      outgoingText,
      originalText: originalText,
      translatedLanguageCode: translatedLanguageCode,
      translationModelId: translationModelId,
    );
  }

  Future<void> _confirmClearChat(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
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
      connector.pathHashByteWidth,
    );
    return context.l10n.chat_hopsCount(hopCount);
  }

  int _displayHopCount(List<int> pathBytes, int storedHopCount, int hashWidth) {
    if (pathBytes.isEmpty) return storedHopCount;
    return PathHelper.splitPathBytes(pathBytes, hashWidth).length;
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
    final contact = widget.contact;
    bool smazEnabled = connector.isContactSmazEnabled(contact.publicKeyHex);
    bool cyr2latEnabled = connector.isContactCyr2LatEnabled(
      contact.publicKeyHex,
    );
    bool urlImagesEnabled = connector.isContactUrlImagesEnabled(
      contact.publicKeyHex,
    );
    String? selectedCyr2LatProfileId = connector.getContactCyr2LatProfileId(
      contact.publicKeyHex,
    );
    bool teleBaseEnabled = contact.teleBaseEnabled;
    bool teleLocEnabled = contact.teleLocEnabled;
    bool teleEnvEnabled = contact.teleEnvEnabled;
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
                          child: Text(profile.name),
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
                  value: urlImagesEnabled,
                  onChanged: (value) {
                    connector.setContactUrlImagesEnabled(
                      contact.publicKeyHex,
                      value,
                    );
                    setDialogState(() => urlImagesEnabled = value);
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleBase),
                  subtitle: Text(context.l10n.contact_teleBaseSubtitle),
                  value: teleBaseEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleBaseEnabled = value);
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
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                connector.setContactFlags(
                  contact,
                  teleBase: teleBaseEnabled,
                  teleLoc: teleLocEnabled,
                  teleEnv: teleEnvEnabled,
                );
                Navigator.pop(context);
              },
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

  void _openMessagePath(Message message, Contact contact) {
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
        builder: (context) => ChannelMessagePathScreen(message: pathMessage),
      ),
    );
  }

  void _showMessageActions(Message message, Contact contact) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              title: message.text.length > 40
                  ? '${message.text.substring(0, 40)}…'
                  : message.text,
            ),
            // Can't react to your own messages
            if (!message.isOutgoing)
              ListTile(
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
            if (message.isOutgoing && message.status == MessageStatus.failed)
              ListTile(
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

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageCopied),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    await context.read<MeshCoreConnector>().deleteMessage(message);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageDeleted),
    );
  }

  void _retryMessage(Message message) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.resendMessage(_resolveContact(connector), message);
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_retryingMessage),
    );
  }

  void _showEmojiPicker(Message message, Contact senderContact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (emoji) {
          _sendReaction(message, senderContact, emoji);
        },
      ),
    );
  }

  void _sendReaction(Message message, Contact senderContact, String emoji) {
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

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.sourceId,
    required this.textScale,
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
    final isFailed = message.status == MessageStatus.failed;
    final urlImagesEnabled = context.select<MeshCoreConnector, bool>(
      (connector) => connector.isContactUrlImagesEnabled(sourceId),
    );

    // Bubble colors — outgoing uses MeshPalette.me / meBorder / meInk.
    final bubbleColor = isFailed
        ? scheme.errorContainer
        : isOutgoing
        ? MeshPalette.me
        : scheme.surfaceContainerLow;
    final bubbleBorder = isFailed
        ? scheme.error
        : isOutgoing
        ? MeshPalette.meBorder
        : scheme.outlineVariant;
    final textColor = isFailed
        ? scheme.onErrorContainer
        : isOutgoing
        ? MeshPalette.meInk
        : scheme.onSurface;
    final metaColor = textColor.withValues(alpha: 0.65);
    const bodyFontSize = 14.0;

    // Asymmetric radius: outgoing — top-left large, others also large; outgoing bottom-right tight.
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
                                senderName,
                                style: MeshTheme.mono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _colorForName(senderName),
                                ),
                              ),
                            ),
                            if (gifId == null) const SizedBox(height: 2),
                          ],
                          if (poi != null)
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
                                if (MessageUrlImageHelper.hasPotentialImageUrl(
                                  message.text,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      context.l10n.urlImage_possible,
                                      style: TextStyle(
                                        color: metaColor,
                                        fontSize: 11 * textScale,
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
                                  fontSize: 9.5 * textScale,
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
                                  _formatTime(message.timestamp),
                                  style: MeshTheme.mono(
                                    fontSize: 10 * textScale,
                                    color: metaColor,
                                  ),
                                ),
                                if (isOutgoing) ...[
                                  const SizedBox(width: 2),
                                  MessageStatusIcon(
                                    size: 12 * textScale,
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
                                    size: 10 * textScale,
                                    color: isOutgoing
                                        ? metaColor
                                        : scheme.tertiary,
                                  ),
                                  Text(
                                    '${(message.tripTimeMs! / 1000).toStringAsFixed(1)}s',
                                    style: MeshTheme.mono(
                                      fontSize: 9 * textScale,
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
              child: _buildReactionsDisplay(context, message, scheme),
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

  Widget _buildReactionsDisplay(
    BuildContext context,
    Message message,
    ColorScheme scheme,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value.length;
        final status = message.reactionStatuses[emoji];
        final isPending =
            status == MessageStatus.pending || status == MessageStatus.sent;
        final isFailed = status == MessageStatus.failed;

        return GestureDetector(
          onTap: isFailed && onRetryReaction != null
              ? () => onRetryReaction!(message, emoji)
              : null,
          child: Opacity(
            opacity: isPending ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isFailed
                    ? scheme.errorContainer
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(MeshRadii.pill),
                border: Border.all(
                  color: isFailed ? scheme.error : scheme.outlineVariant,
                  width: 1,
                ),
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
                  if (isPending) ...[
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                  if (isFailed) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.replay, size: 10, color: scheme.error),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvatar(String senderName) {
    return AvatarCircle(name: senderName, size: 32);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Deterministic name-to-hue mapping consistent with [AvatarCircle].
Color _colorForName(String name) {
  const hues = [
    MeshPalette.blue,
    MeshPalette.magenta,
    MeshPalette.signal,
    MeshPalette.warn,
    Color(0xFF8FA8F0),
    Color(0xFF6FD9CE),
  ];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return hues[h % hues.length];
}
