import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../utils/platform_info.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/reaction_helper.dart';
import '../widgets/message_status_icon.dart';
import '../helpers/chat_scroll_controller.dart';
import '../helpers/link_handler.dart';
import '../helpers/path_helper.dart';
import '../helpers/utf8_length_limiter.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_history.dart';
import '../services/app_settings_service.dart';
import '../services/chat_text_scale_service.dart';
import '../services/path_history_service.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/elements_ui.dart';
import 'channel_message_path_screen.dart';
import 'map_screen.dart';
import '../utils/emoji_utils.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/gif_message.dart';
import '../widgets/jump_to_bottom_button.dart';
import '../widgets/gif_picker.dart';
import '../widgets/path_selection_dialog.dart';
import '../widgets/radio_stats_entry.dart';
import '../utils/app_logger.dart';
import '../l10n/l10n.dart';
import 'telemetry_screen.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

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
  DateTime? _lastTextSendAt;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(_onTextFieldFocusChange);
    _scrollController.onScrollNearTop = _loadOlderMessages;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final connector = context.read<MeshCoreConnector>();
      final settings = context.read<AppSettingsService>().settings;
      final keyHex = widget.contact.publicKeyHex;
      final unread = connector.getUnreadCountForContactKey(keyHex);
      Message? anchor;
      if (settings.jumpToOldestUnread && unread > 0) {
        anchor = _findOldestUnreadAnchor(
          connector.getMessages(widget.contact),
          unread,
        );
      }
      connector.setActiveContact(keyHex);
      _connector = connector;
      if (anchor != null) {
        setState(() => _pendingUnreadScrollTarget = anchor);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ctx = _unreadScrollKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 350),
              alignment: 0.15,
            );
          }
          setState(() => _pendingUnreadScrollTarget = null);
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

            // Show path details if we have non-empty path data (from device or override)
            final effectivePath = contact.pathOverrideBytes ?? contact.path;
            final hasPathData = effectivePath.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contact.name),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasPathData
                      ? () => _showFullPathDialog(context, effectivePath)
                      : null,
                  child: Text(
                    '$pathLabel • $unreadLabel',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      decoration: hasPathData ? TextDecoration.underline : null,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
        actions: [
          Consumer<MeshCoreConnector>(
            builder: (context, connector, _) {
              final contact = _resolveContact(connector);
              final isFloodMode = contact.pathOverride == -1;

              final isDirectMode = contact.pathOverride == 0;
              final activeMode = isFloodMode
                  ? 'flood'
                  : isDirectMode
                  ? 'direct'
                  : 'auto';

              return PopupMenuButton<String>(
                icon: Icon(isFloodMode ? Icons.waves : Icons.route),
                tooltip: context.l10n.chat_routingMode,
                onSelected: (mode) async {
                  if (mode == 'flood') {
                    await connector.setPathOverride(contact, pathLen: -1);
                  } else if (mode == 'direct') {
                    await connector.setPathOverride(
                      contact,
                      pathLen: 0,
                      pathBytes: Uint8List(0),
                    );
                  } else {
                    await connector.setPathOverride(contact, pathLen: null);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'auto',
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_mode,
                          size: 20,
                          color: activeMode == 'auto'
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.chat_autoUseSavedPath,
                          style: TextStyle(
                            fontWeight: activeMode == 'auto'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'direct',
                    child: Row(
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 20,
                          color: activeMode == 'direct'
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.chat_direct,
                          style: TextStyle(
                            fontWeight: activeMode == 'direct'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'flood',
                    child: Row(
                      children: [
                        Icon(
                          Icons.waves,
                          size: 20,
                          color: activeMode == 'flood'
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.chat_forceFloodMode,
                          style: TextStyle(
                            fontWeight: activeMode == 'flood'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: context.l10n.chat_pathManagement,
            onPressed: () => _showPathHistory(context),
          ),
          Consumer<MeshCoreConnector>(
            builder: (context, connector, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'info') {
                    _showContactInfo(context);
                  }
                  if (value == 'settings') {
                    _showContactSettings(context);
                  }
                  if (value == 'telemetry') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TelemetryScreen(contact: widget.contact),
                      ),
                    );
                  }
                  if (value == 'clearChat') {
                    connector.clearMessagesForContact(widget.contact);
                  }
                },
                itemBuilder: (context) => [
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
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.contact_clearChat,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const RadioStatsIconButton(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            context.l10n.chat_noMessages,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.chat_sendMessageTo(
              _resolveContact(context.read<MeshCoreConnector>()).name,
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
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
          final message = reversedMessages[messageIndex];
          String fourByteHex = '';
          if (contact.type == advTypeRoom) {
            contact = _resolveContactFrom4Bytes(
              connector,
              message.fourByteRoomContactKey.isEmpty
                  ? Uint8List.fromList([0, 0, 0, 0])
                  : message.fourByteRoomContactKey,
            );
            fourByteHex = message.fourByteRoomContactKey
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();
          }

          return Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              final resolvedContact = _resolveContact(connector);
              final bubble = _MessageBubble(
                message: message,
                senderName: resolvedContact.type == advTypeRoom
                    ? "${contact.name} [$fourByteHex]"
                    : contact.name,
                isRoomServer: resolvedContact.type == advTypeRoom,
                textScale: textScale,
                onTap: () => _openMessagePath(message, contact),
                onLongPress: () => _showMessageActions(message, contact),
                onRetryReaction: (msg, emoji) =>
                    _sendReaction(msg, contact, emoji),
              );
              if (identical(message, _pendingUnreadScrollTarget)) {
                return KeyedSubtree(key: _unreadScrollKey, child: bubble);
              }
              return bubble;
            },
          );
        },
      ),
    );
  }

  Widget _buildInputBar(MeshCoreConnector connector) {
    final maxBytes = maxContactMessageBytes();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.gif_box),
              onPressed: () => _showGifPicker(context),
              tooltip: context.l10n.chat_sendGif,
            ),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, child) {
                  final gifId = _parseGifId(value.text);
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
                                    colorScheme.surfaceContainerHighest,
                                fallbackTextColor: colorScheme.onSurface
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

                  return TextField(
                    controller: _textController,
                    focusNode: _textFieldFocusNode,
                    inputFormatters: [
                      Utf8LengthLimitingTextInputFormatter(maxBytes),
                    ],
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.chat_typeMessage,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(connector),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: () => _sendMessage(connector),
            ),
          ],
        ),
      ),
    );
  }

  String? _parseGifId(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^g:([A-Za-z0-9_-]+)$').firstMatch(trimmed);
    return match?.group(1);
  }

  void _showGifPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GifPicker(
        onGifSelected: (gifId) {
          _textController.text = 'g:$gifId';
        },
      ),
    );
  }

  void _sendMessage(MeshCoreConnector connector) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastTextSendAt != null &&
        now.difference(_lastTextSendAt!) < const Duration(seconds: 1)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.chat_sendCooldown)));
      return;
    }
    _lastTextSendAt = now;

    final maxBytes = maxContactMessageBytes();
    if (utf8.encode(text).length > maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chat_messageTooLong(maxBytes))),
      );
      return;
    }

    connector.sendMessage(_resolveContact(connector), text);
    _textController.clear();
    _textFieldFocusNode.requestFocus();
  }

  void _showPathHistory(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    bool showAllPaths = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Consumer<PathHistoryService>(
          builder: (context, pathService, _) {
            final paths = pathService.getRecentPaths(
              widget.contact.publicKeyHex,
            );

            final repeatersList = List.of(connector.directRepeaters)
              ..sort((a, b) => b.ranking.compareTo(a.ranking));

            if (repeatersList.isEmpty) {
              showAllPaths = true;
            }

            final directRepeater = repeatersList.isEmpty
                ? null
                : repeatersList.first;
            final secondDirectRepeater = repeatersList.length < 2
                ? null
                : repeatersList.elementAt(1);
            final thirdDirectRepeater = repeatersList.length < 3
                ? null
                : repeatersList.elementAt(2);

            List<MapEntry<int, MapEntry<Color, PathRecord>>>
            pathsWithRepeaters = paths.map((path) {
              final isDirectRepeater =
                  directRepeater != null &&
                  path.pathBytes.isNotEmpty &&
                  directRepeater.pubkeyFirstByte == path.pathBytes.first;
              final isSecondDirectRepeater =
                  secondDirectRepeater != null &&
                  path.pathBytes.isNotEmpty &&
                  secondDirectRepeater.pubkeyFirstByte == path.pathBytes.first;
              final isThirdDirectRepeater =
                  thirdDirectRepeater != null &&
                  path.pathBytes.isNotEmpty &&
                  thirdDirectRepeater.pubkeyFirstByte == path.pathBytes.first;

              int ranking = -1;
              Color color = Colors.grey;
              if (isDirectRepeater) {
                color = Colors.green;
                ranking = 3;
              } else if (isSecondDirectRepeater) {
                color = Colors.yellow;
                ranking = 2;
              } else if (isThirdDirectRepeater) {
                color = Colors.red;
                ranking = 1;
              } else if (path.wasFloodDiscovery) {
                color = Colors.blue;
                ranking = 0;
              }

              return MapEntry(ranking, MapEntry(color, path));
            }).toList();

            pathsWithRepeaters.sort((a, b) => b.key.compareTo(a.key));

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.timeline),
                  const SizedBox(width: 8),
                  Text(context.l10n.chat_pathManagement),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pathsWithRepeaters.isNotEmpty) ...[
                      if (repeatersList.isNotEmpty)
                        FeatureToggleRow(
                          title: context.l10n.chat_ShowAllPaths,
                          subtitle: "",
                          value: showAllPaths,
                          onChanged: (val) {
                            setDialogState(() {
                              showAllPaths = val;
                            });
                          },
                        ),
                      Text(
                        context.l10n.chat_recentAckPaths,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (pathsWithRepeaters.length >= 100) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.l10n.chat_pathHistoryFull,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ...pathsWithRepeaters.map((entry) {
                        final path = entry.value.value;
                        final color = entry.value.key;
                        if (!showAllPaths && entry.key < 1) {
                          return const SizedBox.shrink();
                        } else {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: color,
                                child: Text(
                                  '${path.hopCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(
                                '${path.hopCount} ${path.hopCount == 1 ? context.l10n.chat_hopSingular : context.l10n.chat_hopPlural}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${(path.tripTimeMs / 1000).toStringAsFixed(2)}s • ${_formatRelativeTime(path.timestamp)} • ${path.successCount} ${context.l10n.chat_successes}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    tooltip: context.l10n.chat_removePath,
                                    onPressed: () async {
                                      await pathService.removePathRecord(
                                        widget.contact.publicKeyHex,
                                        path.pathBytes,
                                      );
                                    },
                                  ),
                                  path.wasFloodDiscovery
                                      ? const Icon(
                                          Icons.waves,
                                          size: 16,
                                          color: Colors.grey,
                                        )
                                      : const Icon(
                                          Icons.route,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                ],
                              ),
                              onLongPress: () =>
                                  _showFullPathDialog(context, path.pathBytes),
                              onTap: () async {
                                if (path.pathBytes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context
                                            .l10n
                                            .chat_pathDetailsNotAvailable,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                final pathBytes = Uint8List.fromList(
                                  path.pathBytes,
                                );
                                final pathLength = path.pathBytes.length;

                                // Set the path override to persist user's choice
                                await connector.setPathOverride(
                                  _resolveContact(connector),
                                  pathLen: pathLength,
                                  pathBytes: pathBytes,
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                await _notifyPathSet(
                                  connector,
                                  _resolveContact(connector),
                                  pathBytes,
                                  path.hopCount,
                                );
                              },
                            ),
                          );
                        }
                      }),
                      const Divider(),
                    ] else ...[
                      Text(context.l10n.chat_noPathHistoryYet),
                      const Divider(),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.chat_pathActions,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.edit_road, size: 16),
                      ),
                      title: Text(
                        context.l10n.chat_setCustomPath,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        context.l10n.chat_setCustomPathSubtitle,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomPathDialog(context);
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.clear_all, size: 16),
                      ),
                      title: Text(
                        context.l10n.chat_clearPath,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        context.l10n.chat_clearPathSubtitle,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () async {
                        await connector.clearContactPath(
                          _resolveContact(connector),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.chat_pathCleared),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.waves, size: 16),
                      ),
                      title: Text(
                        context.l10n.chat_forceFloodMode,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        context.l10n.chat_floodModeSubtitle,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () async {
                        await connector.setPathOverride(
                          _resolveContact(connector),
                          pathLen: -1,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.chat_floodModeEnabled),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
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
            );
          },
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return '—';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return context.l10n.time_justNow;
    if (diff.inMinutes < 60) {
      return context.l10n.time_minutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) return context.l10n.time_hoursAgo(diff.inHours);
    return context.l10n.time_daysAgo(diff.inDays);
  }

  void _showFullPathDialog(BuildContext context, List<int> pathBytes) {
    if (pathBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.chat_pathDetailsNotAvailable),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final connector = context.read<MeshCoreConnector>();
    final allContacts = connector.allContacts;

    final formattedPath = PathHelper.formatPathHex(pathBytes);
    final resolvedNames = PathHelper.resolvePathNames(pathBytes, allContacts);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chat_fullPath),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(formattedPath),
            const SizedBox(height: 8),
            SelectableText(
              resolvedNames,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PathTraceMapScreen(
                  title: context.l10n.contacts_repeaterPathTrace,
                  path: Uint8List.fromList(pathBytes),
                  flipPathAround: true,
                  targetContact: widget.contact,
                  pathHashByteWidth: connector.pathHashByteWidth,
                ),
              ),
            ),
            child: Text(context.l10n.contacts_pathTrace),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
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

  Contact _resolveContactFrom4Bytes(
    MeshCoreConnector connector,
    Uint8List key4Bytes,
  ) {
    return connector.contacts.firstWhere(
      (c) => listEquals(c.publicKey.sublist(0, 4), key4Bytes.sublist(0, 4)),
      orElse: () => widget.contact,
    );
  }

  String _currentPathLabel(Contact contact) {
    // Check if user has set a path override
    if (contact.pathOverride != null) {
      if (contact.pathOverride! < 0) return context.l10n.chat_floodForced;
      if (contact.pathOverride == 0) return context.l10n.chat_directForced;
      return context.l10n.chat_hopsForced(contact.pathOverride!);
    }

    // Use device's path
    if (contact.pathLength < 0) return context.l10n.chat_floodAuto;
    if (contact.pathLength == 0) return context.l10n.chat_direct;
    return context.l10n.chat_hopsCount(contact.pathLength);
  }

  Future<void> _notifyPathSet(
    MeshCoreConnector connector,
    Contact contact,
    Uint8List pathBytes,
    int hopCount,
  ) async {
    final verified = connector.isConnected
        ? await connector.verifyContactPathOnDevice(contact, pathBytes)
        : false;
    if (!mounted) return;

    final status = !connector.isConnected
        ? context.l10n.chat_pathSavedLocally
        : (verified
              ? context.l10n.chat_pathDeviceConfirmed
              : context.l10n.chat_pathDeviceNotConfirmed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.chat_pathSetHops(hopCount, status)),
        duration: const Duration(seconds: 3),
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
              _buildInfoRow(context.l10n.chat_type, contact.typeLabel),
              _buildInfoRow(context.l10n.chat_path, contact.pathLabel),
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
    connector.ensureContactSmazSettingLoaded(widget.contact.publicKeyHex);
    final contact = widget.contact;
    bool smazEnabled = connector.isContactSmazEnabled(contact.publicKeyHex);
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
                    setDialogState(() => smazEnabled = value);
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
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
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
    // Check if this is a repeater
    context.read<MeshCoreConnector>().markContactRead(contact.publicKeyHex);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(contact: contact)),
    );
  }

  Future<void> _showCustomPathDialog(BuildContext context) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    final currentContact = _resolveContact(connector);
    if (currentContact.pathLength > 0 &&
        currentContact.path.isEmpty &&
        connector.isConnected) {
      connector.getContacts();
    }

    final pathForInput = currentContact.pathFormattedIdList(
      connector.pathHashByteWidth,
    );
    final currentPathLabel = _currentPathLabel(currentContact);

    // Filter out the current contact from available contacts
    final availableContacts = connector.allContacts
        .where((c) => c != widget.contact)
        .toList();

    final result = await PathSelectionDialog.show(
      context,
      availableContacts: availableContacts,
      initialPath: pathForInput.isEmpty ? null : pathForInput,
      title: context.l10n.chat_setCustomPath,
      currentPathLabel: currentPathLabel,
      onRefresh: connector.isConnected ? connector.getContacts : null,
    );

    appLogger.info(
      'PathSelectionDialog returned: ${result?.length ?? 0} bytes, mounted: $mounted',
      tag: 'ChatScreen',
    );

    if (result == null) {
      return; // Cancelled — keep existing path
    }

    if (!mounted) {
      appLogger.warn(
        'Widget not mounted after dialog, cannot set path',
        tag: 'ChatScreen',
      );
      return;
    }

    appLogger.info(
      'Calling setPathOverride for ${widget.contact.name}',
      tag: 'ChatScreen',
    );
    await connector.setPathOverride(
      _resolveContact(connector),
      pathLen: result.length,
      pathBytes: result,
    );
    appLogger.info('setPathOverride completed', tag: 'ChatScreen');

    if (!mounted) return;
    await _notifyPathSet(
      connector,
      _resolveContact(connector),
      result,
      result.length,
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
      senderName = "${contact.name} [$fourByteHex]";
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
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (PlatformInfo.isDesktop)
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
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.l10n.common_delete),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _deleteMessage(message);
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
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.common_cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.chat_messageCopied)));
  }

  Future<void> _deleteMessage(Message message) async {
    await context.read<MeshCoreConnector>().deleteMessage(message);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.chat_messageDeleted)));
  }

  void _retryMessage(Message message) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    // Retry using the contact's current path override setting
    connector.sendMessage(_resolveContact(connector), message.text);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.chat_retryingMessage)));
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
    final hash = ReactionHelper.computeReactionHash(
      timestampSecs,
      senderName,
      message.text,
    );
    final reactionText = 'r:$hash:$emojiIndex';
    connector.sendMessage(_resolveContact(connector), reactionText);
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String senderName;
  final bool isRoomServer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(Message message, String emoji)? onRetryReaction;
  final double textScale;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.isRoomServer,
    required this.textScale,
    this.onTap,
    this.onLongPress,
    this.onRetryReaction,
  });

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<AppSettingsService>();
    final enableTracing = settingsService.settings.enableMessageTracing;
    final isOutgoing = message.isOutgoing;
    final colorScheme = Theme.of(context).colorScheme;
    final gifId = _parseGifId(message.text);
    final poi = _parsePoiMessage(message.text);
    final isFailed = message.status == MessageStatus.failed;
    final bubbleColor = isFailed
        ? colorScheme.errorContainer
        : (isOutgoing
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest);
    final textColor = isFailed
        ? colorScheme.onErrorContainer
        : (isOutgoing ? colorScheme.onPrimary : colorScheme.onSurface);
    final metaColor = textColor.withValues(alpha: 0.7);
    const bodyFontSize = 14.0;
    String messageText = message.text;
    if (isRoomServer && !isOutgoing) {
      messageText = message.text.substring(4.clamp(0, message.text.length));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: PlatformInfo.isDesktop ? null : onTap,
            onLongPress: onLongPress,
            onSecondaryTapUp: PlatformInfo.isDesktop
                ? (_) => onLongPress?.call()
                : null,
            child: Row(
              mainAxisAlignment: isOutgoing
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOutgoing) ...[
                  _buildAvatar(senderName, colorScheme),
                  const SizedBox(width: 8),
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
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(16),
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          if (gifId == null) const SizedBox(height: 4),
                        ],
                        if (poi != null)
                          _buildPoiMessage(
                            context,
                            poi,
                            textColor,
                            metaColor,
                            textScale,
                            trailing: (!enableTracing && isOutgoing)
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: MessageStatusIcon(
                                      isAcked:
                                          message.status ==
                                              MessageStatus.delivered &&
                                          message.pathBytes.isNotEmpty,
                                      isFailed:
                                          message.status ==
                                          MessageStatus.failed,
                                    ),
                                  )
                                : null,
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
                              if (!enableTracing && isOutgoing)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: MessageStatusIcon(
                                      isAcked:
                                          message.status ==
                                              MessageStatus.delivered &&
                                          message.pathBytes.isNotEmpty,
                                      isFailed:
                                          message.status ==
                                          MessageStatus.failed,
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
                                child: LinkHandler.buildLinkifyText(
                                  context: context,
                                  text: messageText,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: bodyFontSize * textScale,
                                  ),
                                ),
                              ),
                              if (!enableTracing && isOutgoing) ...[
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: MessageStatusIcon(
                                    isAcked:
                                        message.status ==
                                            MessageStatus.delivered &&
                                        message.pathBytes.isNotEmpty,
                                    isFailed:
                                        message.status == MessageStatus.failed,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (enableTracing) ...[
                          if (isOutgoing && message.retryCount > 0) ...[
                            const SizedBox(height: 4),
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
                                style: TextStyle(
                                  fontSize: 10,
                                  color: metaColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: metaColor,
                                  ),
                                ),
                                if (isOutgoing) ...[
                                  const SizedBox(width: 4),
                                  _buildStatusIcon(metaColor),
                                ],
                                if (message.tripTimeMs != null &&
                                    message.status ==
                                        MessageStatus.delivered) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.speed,
                                    size: 10,
                                    color: isOutgoing
                                        ? metaColor
                                        : Colors.green[700],
                                  ),
                                  Text(
                                    '${(message.tripTimeMs! / 1000).toStringAsFixed(1)}s',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isOutgoing
                                          ? metaColor
                                          : Colors.green[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: isOutgoing ? 0 : 48),
              child: _buildReactionsDisplay(context, message, colorScheme),
            ),
          ],
        ],
      ),
    );
  }

  String? _parseGifId(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^g:([A-Za-z0-9_-]+)$').firstMatch(trimmed);
    return match?.group(1);
  }

  _PoiInfo? _parsePoiMessage(String text) {
    final trimmed = text.trim();
    final match = RegExp(
      r'^m:([\-0-9.]+),([\-0-9.]+)\|([^|]*)\|.*$',
    ).firstMatch(trimmed);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1) ?? '');
    final lon = double.tryParse(match.group(2) ?? '');
    if (lat == null || lon == null) return null;
    final label = match.group(3) ?? '';
    return _PoiInfo(lat: lat, lon: lon, label: label);
  }

  Widget _buildPoiMessage(
    BuildContext context,
    _PoiInfo poi,
    Color textColor,
    Color metaColor,
    double textScale, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.location_on_outlined, color: textColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  highlightPosition: LatLng(poi.lat, poi.lon),
                  highlightLabel: poi.label,
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
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;
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
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFailed
                      ? colorScheme.error
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
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
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                  if (isFailed) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.replay, size: 10, color: colorScheme.error),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvatar(String senderName, ColorScheme colorScheme) {
    final initial = _getFirstCharacterOrEmoji(senderName);
    final color = _getColorForName(senderName);

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getFirstCharacterOrEmoji(String name) {
    if (name.isEmpty) return '?';

    final emoji = firstEmoji(name);
    if (emoji != null) return emoji;

    final runes = name.runes.toList();
    if (runes.isEmpty) return '?';
    return String.fromCharCode(runes[0]).toUpperCase();
  }

  Color _getColorForName(String name) {
    // Generate a consistent color based on the name hash
    final hash = name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
    ];

    return colors[hash.abs() % colors.length];
  }

  Widget _buildStatusIcon(Color color) {
    IconData icon;
    switch (message.status) {
      case MessageStatus.pending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.schedule;
        break;
      case MessageStatus.delivered:
        icon = Icons.check;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        break;
    }

    return Icon(icon, size: 12, color: color);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _PoiInfo {
  final double lat;
  final double lon;
  final String label;

  const _PoiInfo({required this.lat, required this.lon, required this.label});
}
