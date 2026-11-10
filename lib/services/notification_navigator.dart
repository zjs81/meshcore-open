import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../screens/channel_chat_screen.dart';
import '../screens/chat_screen.dart';
import 'notification_service.dart';

/// Opens the conversation behind a tapped message notification instead of
/// leaving the user on whatever screen they last had open.
///
/// Only acts while a radio is connected: chats need its contacts/channels, and
/// a cold start goes through the scanner anyway, so a stale tap is dropped.
class NotificationNavigator {
  final GlobalKey<NavigatorState> navigatorKey;
  final MeshCoreConnector connector;
  final NotificationService notifications;

  NotificationNavigator({
    required this.navigatorKey,
    required this.connector,
    required this.notifications,
  });

  void attach() {
    notifications.pendingTap.addListener(_handleTap);
    _handleTap();
  }

  void dispose() {
    notifications.pendingTap.removeListener(_handleTap);
  }

  void _handleTap() {
    final payload = notifications.pendingTap.value;
    if (payload == null) return;
    notifications.pendingTap.value = null;
    final navigator = navigatorKey.currentState;
    // Offline the last radio's saved chats still open (read-only).
    if (navigator == null || !connector.hasRadioData) return;

    final sep = payload.indexOf(':');
    if (sep <= 0) return;
    final kind = payload.substring(0, sep);
    final value = payload.substring(sep + 1);

    if (kind == 'message') {
      if (connector.activeContactKey == value) return;
      final contact = connector.getContactByPubKeyHex(value);
      if (contact == null ||
          (contact.type != advTypeChat && contact.type != advTypeRoom)) {
        return;
      }
      final unread = connector.getUnreadCountForContactKey(value);
      connector.markContactRead(value);
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(contact: contact, initialUnreadCount: unread),
        ),
      );
    } else if (kind == 'channel') {
      final index = int.tryParse(value);
      if (index == null || connector.activeChannelIndex == index) return;
      final channel = connector.channels
          .where((c) => c.index == index)
          .firstOrNull;
      if (channel == null) return;
      final unread = connector.getUnreadCountForChannelIndex(index);
      connector.markChannelRead(index);
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ChannelChatScreen(channel: channel, initialUnreadCount: unread),
        ),
      );
    }
  }
}
