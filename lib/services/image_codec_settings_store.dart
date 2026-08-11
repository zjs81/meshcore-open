import 'dart:convert';

import '../models/image_codec_support.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

/// Persistence seam for [ImageCodecPreferences].
///
/// WHY THIS EXISTS. The app stack spec puts these five fields on `AppSettings`
/// (`imageCodecEnabled`, `imageCodecSelectedModelId`, `imageCodecModelSourceUrl`,
/// `imageCodecRatePoint`, `imageCodecDownloadedModels`) with matching setters on
/// `AppSettingsService` — exactly like the translation block. That is still the
/// right end state, but `app_settings.dart` and `app_settings_service.dart` are
/// outside this workstream's file set, so the service talks to this interface
/// instead of `AppSettingsService`.
///
/// Migration is mechanical: add the fields to `AppSettings` (the JSON keys in
/// [ImageCodecPreferences.toJson] are already the `image_codec_*` snake_case
/// names), then replace [PrefsImageCodecSettingsStore] with a thin adapter over
/// `AppSettingsService`. No `ImageCodecService` code changes.
abstract class ImageCodecSettingsStore {
  ImageCodecPreferences get preferences;

  /// Loads persisted preferences. Safe to call more than once.
  Future<void> load();

  Future<void> save(ImageCodecPreferences preferences);
}

/// Default store: one SharedPreferences key holding the whole block as JSON.
class PrefsImageCodecSettingsStore implements ImageCodecSettingsStore {
  static const String _key = 'image_codec_settings';

  ImageCodecPreferences _preferences = const ImageCodecPreferences();
  bool _loaded = false;

  @override
  ImageCodecPreferences get preferences => _preferences;

  @override
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = PrefsManager.instance.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        _preferences = ImageCodecPreferences.fromJson(json);
      }
    } catch (error) {
      // Matches AppSettingsService.loadSettings: a corrupt blob falls back to
      // defaults rather than blocking startup.
      appLogger.warn('Image codec settings load failed: $error');
      _preferences = const ImageCodecPreferences();
    }
  }

  @override
  Future<void> save(ImageCodecPreferences preferences) async {
    _preferences = preferences;
    _loaded = true;
    try {
      await PrefsManager.instance.setString(
        _key,
        jsonEncode(preferences.toJson()),
      );
    } catch (error) {
      appLogger.warn('Image codec settings save failed: $error');
    }
  }
}

/// Non-persisting store for tests and widget previews.
class InMemoryImageCodecSettingsStore implements ImageCodecSettingsStore {
  ImageCodecPreferences _preferences;

  InMemoryImageCodecSettingsStore([
    this._preferences = const ImageCodecPreferences(),
  ]);

  @override
  ImageCodecPreferences get preferences => _preferences;

  @override
  Future<void> load() async {}

  @override
  Future<void> save(ImageCodecPreferences preferences) async {
    _preferences = preferences;
  }
}
