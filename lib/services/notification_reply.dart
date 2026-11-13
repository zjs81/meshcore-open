import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_tag.dart';

/// Name under which the main isolate registers the port that receives
/// notification actions from the plugin's background isolate.
const notificationReplyPortName = 'meshcore.notification_reply';

const notificationReplyActionId = 'reply';
const notificationMarkReadActionId = 'mark_read';
const notificationMuteActionId = 'mute';

/// Preference holding the app's language code, so the background isolate can
/// localize its notices the same way the app does.
const notificationLanguagePrefsKey = 'notification_language';

enum NotificationReplyAction { reply, markRead, mute }

enum NotificationReplyFailure { notConnected, unavailable, tooLong, sendFailed }

/// A reply or mark-as-read action taken on a message notification, e.g. from
/// the notification shade, a watch, or Android Auto.
class NotificationReply {
  final NotificationReplyAction action;
  final String? contactKeyHex;
  final int? channelIndex;
  final String text;

  const NotificationReply._({
    required this.action,
    this.contactKeyHex,
    this.channelIndex,
    this.text = '',
  });

  bool get isChannel => channelIndex != null;

  /// Parses the plugin's action id, notification payload (`message:<keyHex>`
  /// or `channel:<index>`) and reply input. Returns null for taps, unknown
  /// actions, malformed payloads, and empty replies.
  static NotificationReply? parse({
    required String? actionId,
    required String? payload,
    String? input,
  }) {
    final NotificationReplyAction action;
    if (actionId == notificationReplyActionId) {
      action = NotificationReplyAction.reply;
    } else if (actionId == notificationMarkReadActionId) {
      action = NotificationReplyAction.markRead;
    } else if (actionId == notificationMuteActionId) {
      action = NotificationReplyAction.mute;
    } else {
      return null;
    }
    final text = input?.trim() ?? '';
    if (action == NotificationReplyAction.reply && text.isEmpty) return null;
    if (payload == null) return null;
    final sep = payload.indexOf(':');
    if (sep <= 0) return null;
    final kind = payload.substring(0, sep);
    final value = payload.substring(sep + 1);
    if (kind == 'message' &&
        value.isNotEmpty &&
        value != 'null' &&
        action != NotificationReplyAction.mute) {
      return NotificationReply._(
        action: action,
        contactKeyHex: value,
        text: text,
      );
    }
    if (kind == 'channel') {
      final index = int.tryParse(value);
      if (index == null) return null;
      return NotificationReply._(
        action: action,
        channelIndex: index,
        text: text,
      );
    }
    return null;
  }
}

/// Splits [text] at word boundaries into at most [maxParts] pieces that each
/// satisfy [fits]. Words that are too long on their own are split by
/// character. Returns null when the text needs more than [maxParts] pieces,
/// or when a single character doesn't fit.
List<String>? splitMessageToFit(
  String text,
  bool Function(String part) fits, {
  int maxParts = 3,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  if (fits(trimmed)) return [trimmed];

  final parts = <String>[];
  var current = '';
  for (final word in trimmed.split(RegExp(r'\s+'))) {
    final candidate = current.isEmpty ? word : '$current $word';
    if (fits(candidate)) {
      current = candidate;
      continue;
    }
    if (current.isNotEmpty) parts.add(current);
    if (fits(word)) {
      current = word;
      continue;
    }
    current = '';
    for (final char in word.characters) {
      final next = '$current$char';
      if (fits(next)) {
        current = next;
      } else {
        if (current.isEmpty || !fits(char)) return null;
        parts.add(current);
        current = char;
      }
    }
  }
  if (current.isNotEmpty) parts.add(current);
  return parts.length <= maxParts ? parts : null;
}

/// Runs in the plugin's background isolate when a notification action that
/// doesn't open the app is used. Forwards it to the main isolate, which owns
/// the radio connection; if the app isn't running, tells the user.
@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  final port = IsolateNameServer.lookupPortByName(notificationReplyPortName);
  if (port != null) {
    port.send(<String, String?>{
      'actionId': response.actionId,
      'payload': response.payload,
      'input': response.input,
    });
    return;
  }
  if (response.actionId != notificationReplyActionId) return;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(
          '@drawable/ic_stat_notification',
        ),
      ),
    );
    final l10n = await _backgroundLocalizations();
    await plugin.show(
      id: 'reply_failed'.hashCode,
      title: l10n.notification_replyFailedTitle,
      body: l10n.notification_replyAppNotRunning,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: 'New message notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notification',
        ),
      ),
    );
    if (response.id != null) await plugin.cancel(id: response.id!);
  } catch (e) {
    debugPrint('Failed to report unsent notification reply: $e');
  }
}

Future<AppLocalizations> _backgroundLocalizations() async {
  String? code;
  try {
    code = (await SharedPreferences.getInstance()).getString(
      notificationLanguagePrefsKey,
    );
  } catch (_) {}
  for (final locale in [
    if (code != null) localeFromTag(code),
    PlatformDispatcher.instance.locale,
  ]) {
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {}
  }
  return lookupAppLocalizations(const Locale('en'));
}
