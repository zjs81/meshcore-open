import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/utf8_length_limiter.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/path_history_service.dart';
import 'channel_message_path_screen.dart';
import 'map_screen.dart';
import '../utils/emoji_utils.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/gif_message.dart';
import '../widgets/gif_picker.dart';
import '../widgets/path_selection_dialog.dart';
import '../utils/app_logger.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MeshCoreConnector>().setActiveContact(widget.contact.publicKeyHex);

      // Scroll to bottom when opening chat use SchedulerBinding for next frame
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    context.read<MeshCoreConnector>().setActiveContact(null);
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
            final unreadCount = connector.getUnreadCountForContactKey(widget.contact.publicKeyHex);
            final unreadLabel = 'Unread: $unreadCount';
            final pathLabel = _currentPathLabel(contact);

            // Show path details if we have path data (from device or override)
            final hasPathData = contact.path.isNotEmpty || contact.pathOverrideBytes != null;
            final effectivePath = contact.pathOverrideBytes ?? contact.path;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contact.name),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasPathData ? () => _showFullPathDialog(context, effectivePath) : null,
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

              return PopupMenuButton<String>(
                icon: Icon(isFloodMode ? Icons.waves : Icons.route),
                tooltip: 'Routing mode',
                onSelected: (mode) async {
                  if (mode == 'flood') {
                    await connector.setPathOverride(contact, pathLen: -1);
                  } else {
                    await connector.setPathOverride(contact, pathLen: null);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'auto',
                    child: Row(
                      children: [
                        Icon(Icons.auto_mode, size: 20, color: !isFloodMode ? Theme.of(context).primaryColor : null),
                        const SizedBox(width: 8),
                        Text(
                          'Auto (use saved path)',
                          style: TextStyle(
                            fontWeight: !isFloodMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'flood',
                    child: Row(
                      children: [
                        Icon(Icons.waves, size: 20, color: isFloodMode ? Theme.of(context).primaryColor : null),
                        const SizedBox(width: 8),
                        Text(
                          'Force Flood Mode',
                          style: TextStyle(
                            fontWeight: isFloodMode ? FontWeight.bold : FontWeight.normal,
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
            tooltip: 'Path management',
            onPressed: () => _showPathHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showContactInfo(context),
          ),
        ],
      ),
      body: Consumer<MeshCoreConnector>(
        builder: (context, connector, child) {
          final messages = connector.getMessages(widget.contact);
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(messages, connector),
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
            'No messages yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.contact.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages, MeshCoreConnector connector) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        Contact contact = widget.contact;
        final message = messages[index];
        String fourByteHex = '';
        if(widget.contact.type == advTypeRoom) {
          contact = _resolveContactFrom4Bytes(
            connector,
            message.fourByteRoomContactKey.isEmpty ? Uint8List.fromList([0, 0, 0, 0]) : message.fourByteRoomContactKey,
          );
          fourByteHex = message.fourByteRoomContactKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
        }

        return _MessageBubble(
          message: message,
          senderName: widget.contact.type == advTypeRoom ? "${contact.name} [$fourByteHex]" : contact.name,
          isRoomServer: widget.contact.type == advTypeRoom,
          onTap: () => _openMessagePath(message, contact),
          onLongPress: () => _showMessageActions(message, contact),
        );
      },
    );
  }

  Widget _buildInputBar(MeshCoreConnector connector) {
    final maxBytes = maxContactMessageBytes();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.gif_box),
              onPressed: () => _showGifPicker(context),
              tooltip: 'Send GIF',
            ),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, child) {
                  final gifId = _parseGifId(value.text);
                  if (gifId != null) {
                    return Row(
                      children: [
                        Expanded(
                          child: GifMessage(
                            url: 'https://media.giphy.com/media/$gifId/giphy.gif',
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            fallbackTextColor:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                            width: 160,
                            height: 110,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _textController.clear(),
                        ),
                      ],
                    );
                  }

                  return TextField(
                    controller: _textController,
                    inputFormatters: [
                      Utf8LengthLimitingTextInputFormatter(maxBytes),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    final maxBytes = maxContactMessageBytes();
    if (utf8.encode(text).length > maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message too long (max $maxBytes bytes).')),
      );
      return;
    }

    connector.sendMessage(
      widget.contact,
      text,
    );
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }


  void _showPathHistory(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Consumer<PathHistoryService>(
        builder: (context, pathService, _) {
          final paths = pathService.getRecentPaths(widget.contact.publicKeyHex);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.timeline),
                SizedBox(width: 8),
                Text('Path Management'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (paths.isNotEmpty) ...[
                    const Text(
                      'Recent ACK Paths (tap to use):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if (paths.length >= 100) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Path history is full. Remove entries to add new ones.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ...paths.map((path) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: path.wasFloodDiscovery ? Colors.blue : Colors.green,
                            child: Text(
                              '${path.hopCount}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(
                            '${path.hopCount} ${path.hopCount == 1 ? 'hop' : 'hops'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${(path.tripTimeMs / 1000).toStringAsFixed(2)}s • ${_formatRelativeTime(path.timestamp)} • ${path.successCount} successes',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                tooltip: 'Remove path',
                                onPressed: () async {
                                  await pathService.removePathRecord(
                                    widget.contact.publicKeyHex,
                                    path.pathBytes,
                                  );
                                },
                              ),
                              path.wasFloodDiscovery
                                  ? const Icon(Icons.waves, size: 16, color: Colors.grey)
                                  : const Icon(Icons.route, size: 16, color: Colors.grey),
                            ],
                          ),
                          onLongPress: () => _showFullPathDialog(context, path.pathBytes),
                          onTap: () async {
                            if (path.pathBytes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Path details not available yet. Try sending a message to refresh.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final pathBytes = Uint8List.fromList(path.pathBytes);
                            final pathLength = path.pathBytes.length;

                            // Set the path override to persist user's choice
                            await connector.setPathOverride(
                              widget.contact,
                              pathLen: pathLength,
                              pathBytes: pathBytes,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            await _notifyPathSet(
                              connector,
                              widget.contact,
                              pathBytes,
                              path.hopCount,
                            );
                          },
                        ),
                      );
                    }),
                    const Divider(),
                  ] else ...[
                    const Text('No path history yet.\nSend a message to discover paths.'),
                    const Divider(),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Path Actions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.edit_road, size: 16),
                    ),
                    title: const Text('Set Custom Path', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Manually specify routing path', style: TextStyle(fontSize: 11)),
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
                    title: const Text('Clear Path', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Force rediscovery on next send', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      await connector.clearContactPath(widget.contact);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Path cleared. Next message will rediscover route.'),
                          duration: Duration(seconds: 2),
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
                    title: const Text('Force Flood Mode', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Use routing toggle in app bar', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      await connector.setPathOverride(widget.contact, pathLen: -1);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Flood mode enabled. Toggle back via routing icon in app bar.'),
                          duration: Duration(seconds: 2),
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
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showFullPathDialog(BuildContext context, List<int> pathBytes) {
    if (pathBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Path details not available yet. Try sending a message to refresh.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final formattedPath = pathBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(',');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Path'),
        content: SelectableText(formattedPath),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Contact _resolveContact(MeshCoreConnector connector) {
    return connector.contacts.firstWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
      orElse: () => widget.contact,
    );
  }

  Contact _resolveContactFrom4Bytes(MeshCoreConnector connector, Uint8List key4Bytes) {
    return connector.contacts.firstWhere(
      (c) => listEquals(c.publicKey.sublist(0, 4), key4Bytes.sublist(0, 4)),
      orElse: () => widget.contact,
    );
  }

  String _currentPathLabel(Contact contact) {
    // Check if user has set a path override
    if (contact.pathOverride != null) {
      if (contact.pathOverride! < 0) return 'Flood (forced)';
      if (contact.pathOverride == 0) return 'Direct (forced)';
      return '${contact.pathOverride} hops (forced)';
    }

    // Use device's path
    if (contact.pathLength < 0) return 'Flood (auto)';
    if (contact.pathLength == 0) return 'Direct';
    return '${contact.pathLength} hops';
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
        ? 'Saved locally. Connect to sync.'
        : (verified ? 'Device confirmed.' : 'Device not confirmed yet.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Path set: $hopCount ${hopCount == 1 ? 'hop' : 'hops'} - $status',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showContactInfo(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.ensureContactSmazSettingLoaded(widget.contact.publicKeyHex);

    showDialog(
      context: context,
      builder: (context) => Consumer<MeshCoreConnector>(
        builder: (context, connector, _) {
          final contact = _resolveContact(connector);
          final smazEnabled = connector.isContactSmazEnabled(contact.publicKeyHex);

          return AlertDialog(
            title: Text(contact.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Type', contact.typeLabel),
                  _buildInfoRow('Path', contact.pathLabel),
                  if (contact.hasLocation)
                    _buildInfoRow(
                      'Location',
                      '${contact.latitude?.toStringAsFixed(4)}, ${contact.longitude?.toStringAsFixed(4)}',
                    ),
                  _buildInfoRow('Public Key', '${contact.publicKeyHex.substring(0, 16)}...'),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('SMAZ compression'),
                    subtitle: const Text('Compress outgoing messages'),
                    value: smazEnabled,
                    onChanged: (value) {
                      connector.setContactSmazEnabled(contact.publicKeyHex, value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
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
          Expanded(child: Text(value)),
        ],
      ),
    );
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
    if (currentContact.pathLength > 0 && currentContact.path.isEmpty && connector.isConnected) {
      connector.getContacts();
    }

    final pathForInput = currentContact.pathIdList;
    final currentPathLabel = _currentPathLabel(currentContact);

    // Filter out the current contact from available contacts
    final availableContacts = connector.contacts
        .where((c) => c != widget.contact)
        .toList();

    final result = await PathSelectionDialog.show(
      context,
      availableContacts: availableContacts,
      initialPath: pathForInput.isEmpty ? null : pathForInput,
      title: 'Set Custom Path',
      currentPathLabel: currentPathLabel,
      onRefresh: connector.isConnected ? connector.getContacts : null,
    );

    appLogger.info('PathSelectionDialog returned: ${result?.length ?? 0} bytes, mounted: $mounted', tag: 'ChatScreen');

    if (result == null) {
      appLogger.info('PathSelectionDialog was cancelled or returned null', tag: 'ChatScreen');
      return;
    }

    if (!mounted) {
      appLogger.warn('Widget not mounted after dialog, cannot set path', tag: 'ChatScreen');
      return;
    }

    appLogger.info('Calling setPathOverride for ${widget.contact.name}', tag: 'ChatScreen');
    await connector.setPathOverride(
      widget.contact,
      pathLen: result.length,
      pathBytes: result,
    );
    appLogger.info('setPathOverride completed', tag: 'ChatScreen');

    if (!mounted) return;
    await _notifyPathSet(connector, widget.contact, result, result.length);
  }


  void _openMessagePath(Message message, Contact contact) {
    final connector = context.read<MeshCoreConnector>();
    final fourByteHex = message.fourByteRoomContactKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    final senderName =
        message.isOutgoing ? (connector.selfName ?? 'Me') : widget.contact.type == advTypeRoom ? "${contact.name} [$fourByteHex]" : widget.contact.name;
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
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEmojiPicker(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyMessageText(message.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _deleteMessage(message);
              },
            ),
            if (message.isOutgoing &&
                message.status == MessageStatus.failed)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _retryMessage(message);
                },
              ),
            if(widget.contact.type == advTypeRoom)
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Open Chat'),
                onTap: () {
                  _openChat(context, contact);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied')),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    await context.read<MeshCoreConnector>().deleteMessage(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message deleted')),
    );
  }

  void _retryMessage(Message message) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    // Retry using the contact's current path override setting
    connector.sendMessage(
      widget.contact,
      message.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retrying message')),
    );
  }

  void _showEmojiPicker(Message message) {
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

  void _sendReaction(Message message, String emoji) {
    final connector = context.read<MeshCoreConnector>();
    // Send reaction with messageId if available, otherwise use lightweight format
    // Parser will extract reactionKey (timestamp_senderPrefix) for deduplication
    final messageId = message.messageId ??
        '${message.timestamp.millisecondsSinceEpoch}_${message.senderKeyHex.substring(0, 8)}';
    final reactionText = 'r:$messageId:$emoji';
    connector.sendMessage(widget.contact, reactionText);
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String senderName;
  final bool isRoomServer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.isRoomServer,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.isOutgoing;
    final colorScheme = Theme.of(context).colorScheme;
    final gifId = _parseGifId(message.text);
    final poi = _parsePoiMessage(message.text);
    final isFailed = message.status == MessageStatus.failed;
    final bubbleColor = isFailed
        ? colorScheme.errorContainer
        : (isOutgoing ? colorScheme.primary : colorScheme.surfaceContainerHighest);
    final textColor = isFailed
        ? colorScheme.onErrorContainer
        : (isOutgoing ? colorScheme.onPrimary : colorScheme.onSurface);
    final metaColor = textColor.withValues(alpha: 0.7);
    String messageText = message.text;
    if (isRoomServer && !isOutgoing) {
      messageText = message.text.substring(4.clamp(0, message.text.length));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Row(
              mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOutgoing) ...[
                  _buildAvatar(senderName, colorScheme),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (poi != null)
                      _buildPoiMessage(context, poi, textColor, metaColor)
                    else if (gifId != null)
                      GifMessage(
                        url: 'https://media.giphy.com/media/$gifId/giphy.gif',
                        backgroundColor: bubbleColor,
                        fallbackTextColor: textColor.withValues(alpha: 0.7),
                      )
                    else
                      if(!isOutgoing)
                        Text(
                          messageText,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      if(isOutgoing)
                        Text(
                          message.text,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                    if (isOutgoing && message.retryCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Retry ${message.retryCount}/4',
                        style: TextStyle(
                          fontSize: 10,
                          color: metaColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
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
                            message.status == MessageStatus.delivered) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.speed,
                            size: 10,
                            color: isOutgoing ? metaColor : Colors.green[700],
                          ),
                          Text(
                            '${(message.tripTimeMs! / 1000).toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 9,
                              color: isOutgoing ? metaColor : Colors.green[700],
                            ),
                          ),
                        ],
                      ],
                    ),
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
    final match = RegExp(r'^m:([\-0-9.]+),([\-0-9.]+)\|([^|]*)\|.*$')
        .firstMatch(trimmed);
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
  ) {
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
                'POI Shared',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (poi.label.isNotEmpty)
                Text(
                  poi.label,
                  style: TextStyle(
                    color: metaColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReactionsDisplay(BuildContext context, Message message, ColorScheme colorScheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
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
            ],
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

    return Icon(
      icon,
      size: 12,
      color: color,
    );
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

  const _PoiInfo({
    required this.lat,
    required this.lon,
    required this.label,
  });
}
