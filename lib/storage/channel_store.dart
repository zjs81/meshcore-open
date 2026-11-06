import 'dart:convert';
import 'dart:typed_data';

import '../models/channel.dart';
import '../utils/app_logger.dart';
import 'legacy_key_migration.dart';
import 'prefs_manager.dart';

class ChannelStore {
  static const String _keyPrefix = 'channels';
  static const String _slotIdsKeyPrefix = 'channel_slot_ids_';
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
    if ((jsonString == null || jsonString.isEmpty) &&
        canMigrateLegacyKeys(publicKeyHex)) {
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

    final List<dynamic> jsonList;
    try {
      jsonList = jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      appLogger.warn('Stored channels are unreadable: $e');
      return [];
    }
    final channels = <Channel>[];
    for (final entry in jsonList) {
      try {
        channels.add(_fromJson(entry as Map<String, dynamic>));
      } catch (e) {
        appLogger.warn('Skipping malformed stored channel: $e');
      }
    }
    return channels;
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

  String get _slotIdsKey => '$_slotIdsKeyPrefix$publicKeyHex';

  /// The slot -> [Channel.storageId] map confirmed by the last channel sync,
  /// used to spot slots another app changed while we were away.
  Future<Map<int, String>> loadSlotChannelIds() async {
    if (publicKeyHex.isEmpty) return {};
    final jsonString = PrefsManager.instance.getString(_slotIdsKey);
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return {};
      final ids = <int, String>{};
      for (final entry in decoded.entries) {
        final slot = int.tryParse('${entry.key}');
        final id = entry.value;
        if (slot != null && id is String && id.isNotEmpty) ids[slot] = id;
      }
      return ids;
    } catch (e) {
      appLogger.warn('Stored channel slot map is unreadable: $e');
      return {};
    }
  }

  Future<void> saveSlotChannelIds(Map<int, String> ids) async {
    if (publicKeyHex.isEmpty) return;
    await PrefsManager.instance.setString(
      _slotIdsKey,
      jsonEncode({for (final e in ids.entries) '${e.key}': e.value}),
    );
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
