import 'dart:convert';

import '../services/app_settings_service.dart'
    show AppSettingsService, ChannelNotificationMode;
import '../services/storage_service.dart';
import '../services/timeout_prediction_service.dart';
import '../storage/legacy_key_migration.dart';
import '../storage/prefs_manager.dart';
import 'review_radio.dart';

/// Channel notification modes (JSON map of channel name to mode name) as they
/// were when review mode started. Persisted so an interrupted session (crash,
/// app killed) is still undone on the next launch.
const _savedChannelModesKey = 'review_mode_saved_channel_modes';

/// Prefix for snapshots of app-wide repeater keys (saved passwords, clock sync
/// toggles) taken when review mode starts. An empty snapshot means the key did
/// not exist.
const _savedGlobalKeyPrefix = 'review_mode_saved_global_';

/// Deletes every persisted per-radio preference written while review mode was
/// active. All per-radio stores (contacts, channels, messages, unread counts,
/// channel/contact settings, regions, discovery cache, path history, ...) embed
/// the first 10 hex characters of the radio's public key in their key, so the
/// simulated radio's fixed prefix identifies exactly its data and nothing else.
Future<void> clearReviewModeData() async {
  final prefs = PrefsManager.instance;
  final prefix = ReviewRadio.storagePrefix;
  final keys = prefs.getKeys().where((key) => key.contains(prefix)).toList();
  for (final key in keys) {
    await prefs.remove(key);
  }
}

/// Starts a review session from a clean slate.
///
/// The simulated radio's scope never adopts legacy unscoped keys, so real
/// radio data cannot be pulled into it. Channel notification modes are
/// app-wide and keyed by channel name (muting the simulated "Public" would
/// mute the real one), so the current modes are saved for
/// [endReviewModeSession] to put back, as are the app-wide repeater keys.
/// Delivery timing is not recorded meanwhile.
Future<void> beginReviewModeSession(AppSettingsService? settings) async {
  scopesWithoutLegacyMigration.add(ReviewRadio.storagePrefix);
  TimeoutPredictionService.recordingSuspended = true;
  await clearReviewModeData();
  final prefs = PrefsManager.instance;
  for (final key in StorageService.globalRepeaterKeys) {
    final savedKey = '$_savedGlobalKeyPrefix$key';
    // An earlier interrupted session's snapshot holds the real state.
    if (prefs.containsKey(savedKey)) continue;
    await prefs.setString(savedKey, prefs.getString(key) ?? '');
  }
  // An earlier interrupted session's record holds the real pre-review state.
  if (settings != null && !prefs.containsKey(_savedChannelModesKey)) {
    final modes = settings.settings.channelNotificationModes.map(
      (channel, mode) => MapEntry(channel, mode.name),
    );
    await prefs.setString(_savedChannelModesKey, jsonEncode(modes));
  }
}

/// Deletes the review session's data and restores the channel notification
/// modes and repeater keys saved by [beginReviewModeSession]. Also called at startup to finish a session that
/// was interrupted; it does nothing when no session was left behind.
Future<void> endReviewModeSession(AppSettingsService? settings) async {
  TimeoutPredictionService.recordingSuspended = false;
  await clearReviewModeData();
  final prefs = PrefsManager.instance;
  for (final key in StorageService.globalRepeaterKeys) {
    final savedKey = '$_savedGlobalKeyPrefix$key';
    final saved = prefs.getString(savedKey);
    if (saved == null) continue;
    if (saved.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, saved);
    }
    await prefs.remove(savedKey);
  }
  final savedModes = prefs.getString(_savedChannelModesKey);
  if (savedModes == null || settings == null) return;
  final restored = <String, ChannelNotificationMode>{};
  final decoded = jsonDecode(savedModes);
  if (decoded is Map) {
    final byName = ChannelNotificationMode.values.asNameMap();
    for (final entry in decoded.entries) {
      final mode = byName[entry.value];
      if (mode != null) restored[entry.key.toString()] = mode;
    }
  }
  await settings.updateSettings(
    settings.settings.copyWith(channelNotificationModes: restored),
  );
  await prefs.remove(_savedChannelModesKey);
}
