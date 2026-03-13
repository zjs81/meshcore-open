import 'dart:convert';
import 'dart:typed_data';

import '../models/channel.dart';
import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ChannelStore {
  static const String _keyPrefix = 'channels';
  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length >= 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<List<Channel>> loadChannels() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load channels.');
      return [];
    }
    final prefs = PrefsManager.instance;
    String? jsonString = prefs.getString(keyFor);
    if (jsonString == null || jsonString.isEmpty) {
      // Attempt migration from legacy unscoped key on first load
      final legacyJsonString = prefs.getString(_keyPrefix);
      prefs.remove(_keyPrefix);
      if (legacyJsonString != null && legacyJsonString.isNotEmpty) {
        appLogger.info(
          'Migrating channel messages from legacy key $_keyPrefix to scoped key $keyFor',
        );
        await prefs.setString(keyFor, legacyJsonString);
        jsonString = legacyJsonString;
      }
    }

    if (jsonString == null || jsonString.isEmpty) {
      jsonString = prefs.getString(keyFor);
    }
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((entry) => _fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChannels(List<Channel> channels) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save channels.');
      return;
    }
    final prefs = PrefsManager.instance;
    final jsonList = channels.map(_toJson).toList();
    await prefs.setString(keyFor, jsonEncode(jsonList));
  }

  Map<String, dynamic> _toJson(Channel channel) {
    return {
      'index': channel.index,
      'name': channel.name,
      'psk': base64Encode(channel.psk),
      'unreadCount': channel.unreadCount,
    };
  }

  Channel _fromJson(Map<String, dynamic> json) {
    return Channel(
      index: json['index'] as int,
      name: json['name'] as String? ?? '',
      psk: json['psk'] != null
          ? Uint8List.fromList(base64Decode(json['psk'] as String))
          : Uint8List(16),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
