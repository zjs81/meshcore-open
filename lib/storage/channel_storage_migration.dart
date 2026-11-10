import 'dart:convert';

import '../utils/app_logger.dart';
import 'channel_message_store.dart';
import 'channel_store.dart';
import 'legacy_key_migration.dart';
import 'prefs_manager.dart';
import 'history_store.dart';

/// One-shot move of a radio's per-channel data from slot-index keys
/// (`<prefix><scope><slot>`) to channel-ID keys (`<prefix><scope>_<id>`).
///
/// The slot -> PSK mapping comes from the radio's cached channel list, which is
/// the mapping the legacy data was written under. Legacy keys of slots with no
/// cached PSK are left alone and never read again, and so is a legacy history
/// that cannot be parsed.
class ChannelStorageMigration {
  static const String _doneKeyPrefix = 'channel_storage_v2_';

  static const String _messagesPrefix = 'channel_messages_';
  static const String _smazPrefix = 'channel_smaz_';
  static const String _cyr2latPrefix = 'channel_cyr2lat_';
  static const String _urlImagesPrefix = 'channel_url_images_';
  static const String _regionPrefix = 'channel_region_';
  static const String _orderPrefix = 'channel_order_';

  /// Migrates [scope] (first 10 hex chars of the radio's public key) and
  /// returns the slot -> channel ID mapping it used. Returns an empty map when
  /// the scope was already migrated or must not adopt legacy data.
  ///
  /// [beforeDone] runs with that mapping before the migration is marked done,
  /// so data kept elsewhere (images) is moved on the same one-shot terms: an
  /// interrupted run repeats it on the next launch.
  static Future<Map<int, String>> migrate(
    String scope, {
    Future<void> Function(Map<int, String> slotIds)? beforeDone,
  }) async {
    if (scope.isEmpty || !canMigrateLegacyKeys(scope)) return {};
    final prefs = PrefsManager.instance;
    final doneKey = '$_doneKeyPrefix$scope';
    if (prefs.getBool(doneKey) == true) return {};

    final channelStore = ChannelStore()..setPublicKeyHex = scope;
    final cached = await channelStore.loadChannels();
    final slotIds = <int, String>{};
    for (final channel in cached) {
      final id = channel.storageId;
      if (id != null) slotIds[channel.index] = id;
    }

    final slots = slotIds.keys.toList()..sort();
    for (final slot in slots) {
      final id = slotIds[slot]!;
      await _moveMessages(scope, slot, id);
      await _moveBool(
        '$_smazPrefix$scope',
        slot,
        id,
        legacyPrefix: _smazPrefix,
      );
      await _moveBool('$_cyr2latPrefix$scope', slot, id);
      await _moveBool('$_urlImagesPrefix$scope', slot, id);
      await _moveString(
        '$_cyr2latPrefix${scope}profile_$slot',
        '$_cyr2latPrefix${scope}_profile_$id',
      );
      await _moveString(
        '$_regionPrefix$scope$slot',
        '$_regionPrefix${scope}_$id',
      );
    }
    await _migrateOrder(scope, slotIds);
    if (slotIds.isNotEmpty) await beforeDone?.call(slotIds);

    await channelStore.saveSlotChannelIds(slotIds);
    await _requireWrite(prefs.setBool(doneKey, true));
    if (slotIds.isNotEmpty) {
      appLogger.info(
        'Moved channel data for ${slotIds.length} slots of $scope to channel IDs',
      );
    }
    return slotIds;
  }

  static Future<void> _moveMessages(String scope, int slot, String id) async {
    final prefs = HistoryStore.instance;
    final oldKey = '$_messagesPrefix$scope$slot';
    final legacyKey = '$_messagesPrefix$slot';
    final newKey = '$_messagesPrefix${scope}_$id';
    var json = await prefs.getString(oldKey);
    if (json == null || json.isEmpty) json = await prefs.getString(legacyKey);
    if (json != null && json.isNotEmpty) {
      final String moved;
      try {
        if (jsonDecode(json) is! List) {
          throw const FormatException('Channel history is not an array');
        }
        final existing = await prefs.getString(newKey);
        // Two slots holding the same PSK now share one history.
        moved = existing == null || existing.isEmpty
            ? json
            : _mergeMessages(existing, json);
      } on FormatException catch (error) {
        // One unreadable history must not hold back the other slots. It
        // stays under its old key, which nothing reads again.
        appLogger.warn(
          'Leaving unreadable channel history of slot $slot in place: $error',
        );
        return;
      }
      await _requireWrite(prefs.setString(newKey, moved));
    }
    // Old keys go only after the new one is written, so an interrupted run
    // loses nothing; the next launch repeats it.
    await _requireWrite(prefs.remove(oldKey));
    await _requireWrite(prefs.remove(legacyKey));
  }

  static String _mergeMessages(String a, String b) {
    try {
      // A rerun after an interrupted migration merges a history into
      // itself, so drop entries already present.
      final existing = jsonDecode(a);
      final incoming = jsonDecode(b);
      if (existing is! List ||
          incoming is! List ||
          ![
            ...existing,
            ...incoming,
          ].every((entry) => entry is Map<String, dynamic>)) {
        throw const FormatException(
          'Cannot merge unreadable channel histories',
        );
      }
      final seen = <String>{};
      final merged = [...existing, ...incoming]
          .cast<Map<String, dynamic>>()
          .where((m) => seen.add(_mergeKey(m)))
          .toList();
      merged.sort(
        (x, y) => ((x['timestamp'] as int?) ?? 0).compareTo(
          (y['timestamp'] as int?) ?? 0,
        ),
      );
      final overflow = merged.length - ChannelMessageStore.maxStoredMessages;
      if (overflow > 0) merged.removeRange(0, overflow);
      return jsonEncode(merged);
    } catch (_) {
      throw const FormatException('Cannot merge unreadable channel histories');
    }
  }

  static String _mergeKey(Map<String, dynamic> json) {
    final messageId = json['messageId'];
    if (messageId is String && messageId.isNotEmpty) return 'id:$messageId';
    return 'fallback:${json['timestamp']}:${json['senderName']}:${json['text']}';
  }

  static Future<void> _moveBool(
    String scopedPrefix,
    int slot,
    String id, {
    String? legacyPrefix,
  }) async {
    final prefs = PrefsManager.instance;
    final oldKey = '$scopedPrefix$slot';
    final newKey = '${scopedPrefix}_$id';
    final legacyKey = legacyPrefix == null ? null : '$legacyPrefix$slot';
    var value = prefs.get(oldKey);
    if (value == null && legacyKey != null) value = prefs.get(legacyKey);
    if (value is bool && !prefs.containsKey(newKey)) {
      await _requireWrite(prefs.setBool(newKey, value));
    }
    await _removeIfPresent(oldKey);
    if (legacyKey != null) await _removeIfPresent(legacyKey);
  }

  static Future<void> _moveString(String oldKey, String newKey) async {
    final prefs = PrefsManager.instance;
    final value = prefs.get(oldKey);
    if (value is String && !prefs.containsKey(newKey)) {
      await _requireWrite(prefs.setString(newKey, value));
    }
    await _removeIfPresent(oldKey);
  }

  static Future<void> _migrateOrder(
    String scope,
    Map<int, String> slotIds,
  ) async {
    final prefs = PrefsManager.instance;
    final key = '$_orderPrefix$scope';
    var raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) raw = prefs.getString(_orderPrefix);
    if (raw == null || raw.isEmpty) return;
    final slots = <int>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        // String entries are channel IDs from an interrupted earlier run.
        if (decoded.any((value) => value is String)) return;
        slots.addAll(decoded.whereType<int>());
      } else if (decoded is int) {
        // A one-slot legacy comma-separated list parses as a bare number.
        slots.add(decoded);
      }
    } catch (_) {
      slots.addAll(raw.split(',').map(int.tryParse).whereType<int>());
    }
    final ids = <String>[];
    for (final slot in slots) {
      final id = slotIds[slot];
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    await _requireWrite(prefs.setString(key, jsonEncode(ids)));
    await _removeIfPresent(_orderPrefix);
  }

  static Future<void> _removeIfPresent(String key) async {
    final prefs = PrefsManager.instance;
    if (prefs.containsKey(key)) await prefs.remove(key);
  }

  static Future<void> _requireWrite(Future<bool> write) async {
    if (!await write) {
      throw StateError('Could not persist channel storage migration');
    }
  }
}
