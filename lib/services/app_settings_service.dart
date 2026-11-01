import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/custom_theme.dart';
import '../models/holiday_schedule.dart';
import '../models/image_codec_support.dart';
import '../models/translation_support.dart';

export '../models/app_settings.dart' show ChannelNotificationMode;
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';
import '../helpers/cyr2lat.dart';

class AppSettingsService extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';

  /// [clock] supplies "now" for the holiday theme schedule; tests inject one.
  AppSettingsService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  int resolvedGpsIntervalSeconds(Map<String, String>? deviceCustomVars) {
    final deviceValue = int.tryParse(deviceCustomVars?['gps_interval'] ?? '');
    if (deviceValue != null && deviceValue >= 0) {
      return deviceValue;
    }
    return _settings.gpsIntervalSeconds;
  }

  String batteryChemistryForDevice(String deviceId) {
    final stored = _settings.batteryChemistryByDeviceId[deviceId];
    if (stored == 'liion') return 'nmc';
    return stored ?? 'nmc';
  }

  String batteryChemistryForRepeater(String repeaterPubKeyHex) {
    final stored = _settings.batteryChemistryByRepeaterId[repeaterPubKeyHex];
    if (stored == 'liion') return 'nmc';
    return stored ?? 'nmc';
  }

  Future<void> loadSettings() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_settingsKey);

    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
        Cyr2Lat.setCharMap(_settings.cyr2latCharMap);
        notifyListeners();
      } catch (e) {
        // If parsing fails, use defaults
        _settings = AppSettings();
        Cyr2Lat.setCharMap(_settings.cyr2latCharMap);
      }
    } else {
      _settings = AppSettings();
      Cyr2Lat.setCharMap(_settings.cyr2latCharMap);
    }
    _syncDateTimer();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    Cyr2Lat.setCharMap(_settings.cyr2latCharMap);
    _lastAutoHolidayKey = autoHoliday?.occurrenceKey;
    _syncDateTimer();
    notifyListeners();

    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(_settings.toJson());
    await prefs.setString(_settingsKey, jsonStr);
  }

  Future<void> setClearPathOnMaxRetry(bool value) async {
    await updateSettings(_settings.copyWith(clearPathOnMaxRetry: value));
  }

  Future<void> setMapShowRepeaters(bool value) async {
    await updateSettings(_settings.copyWith(mapShowRepeaters: value));
  }

  Future<void> setMapShowChatNodes(bool value) async {
    await updateSettings(_settings.copyWith(mapShowChatNodes: value));
  }

  Future<void> setMapShowOtherNodes(bool value) async {
    await updateSettings(_settings.copyWith(mapShowOtherNodes: value));
  }

  Future<void> setMapShowOnlineLinks(bool value) async {
    await updateSettings(_settings.copyWith(mapShowOnlineLinks: value));
  }

  Future<void> setMapUseOnlineMapForPaths(bool value) async {
    await updateSettings(_settings.copyWith(mapUseOnlineMapForPaths: value));
  }

  Future<void> setMapShowOverlaps(bool value) async {
    await updateSettings(_settings.copyWith(mapShowOverlaps: value));
  }

  Future<void> setMapTimeFilterHours(double value) async {
    await updateSettings(_settings.copyWith(mapTimeFilterHours: value));
  }

  Future<void> setMapKeyPrefixEnabled(bool value) async {
    await updateSettings(_settings.copyWith(mapKeyPrefixEnabled: value));
  }

  Future<void> setMapKeyPrefix(String value) async {
    await updateSettings(_settings.copyWith(mapKeyPrefix: value));
  }

  Future<void> setMapShowMarkers(bool value) async {
    await updateSettings(_settings.copyWith(mapShowMarkers: value));
  }

  Future<void> setMapShowGuessedLocations(bool value) async {
    await updateSettings(_settings.copyWith(mapShowGuessedLocations: value));
  }

  Future<void> setMapClusterNodes(bool value) async {
    await updateSettings(_settings.copyWith(mapClusterNodes: value));
  }

  Future<void> setEnableMessageTracing(bool value) async {
    await updateSettings(_settings.copyWith(enableMessageTracing: value));
  }

  Future<void> setRegionOnHopsLine(bool value) async {
    await updateSettings(_settings.copyWith(regionOnHopsLine: value));
  }

  Future<void> setMapCacheBounds(Map<String, double>? value) async {
    await updateSettings(_settings.copyWith(mapCacheBounds: value));
  }

  Future<void> setMapCacheZoomRange(int minZoom, int maxZoom) async {
    final safeMin = minZoom <= maxZoom ? minZoom : maxZoom;
    final safeMax = minZoom <= maxZoom ? maxZoom : minZoom;
    await updateSettings(
      _settings.copyWith(mapCacheMinZoom: safeMin, mapCacheMaxZoom: safeMax),
    );
  }

  Future<void> setMapRasterSourceId(String value) async {
    await updateSettings(_settings.copyWith(mapRasterSourceId: value));
  }

  Future<void> setMapTileEndpointId(String value) async {
    await updateSettings(_settings.copyWith(mapTileEndpointId: value));
  }

  Future<void> setMapTileApiKey(String? value) async {
    final normalized = value?.trim();
    await updateSettings(
      _settings.copyWith(
        mapTileApiKey: (normalized == null || normalized.isEmpty)
            ? null
            : normalized,
      ),
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await updateSettings(_settings.copyWith(notificationsEnabled: value));
  }

  Future<void> setNotifyOnNewMessage(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnNewMessage: value));
  }

  Future<void> setNotifyOnNewChannelMessage(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnNewChannelMessage: value));
  }

  Future<void> setNotifyOnNewAdvert(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnNewAdvert: value));
  }

  Future<void> setAutoSendZeroHopAdvertOnGpsUpdate(bool value) async {
    await updateSettings(
      _settings.copyWith(autoSendZeroHopAdvertOnGpsUpdate: value),
    );
  }

  Future<void> setGpsIntervalSeconds(
    int value, {
    Future<void> Function(int value)? writeToDevice,
  }) async {
    await updateSettings(_settings.copyWith(gpsIntervalSeconds: value));
    if (writeToDevice == null) return;
    try {
      await writeToDevice(value);
    } catch (e) {
      appLogger.warn(
        'Failed to write GPS interval to device: $e',
        tag: 'AppSettings',
      );
    }
  }

  Future<void> setAutoRouteRotationEnabled(bool value) async {
    await updateSettings(_settings.copyWith(autoRouteRotationEnabled: value));
  }

  Future<void> setMaxRouteWeight(double value) async {
    await updateSettings(_settings.copyWith(maxRouteWeight: value));
  }

  Future<void> setInitialRouteWeight(double value) async {
    await updateSettings(_settings.copyWith(initialRouteWeight: value));
  }

  Future<void> setRouteWeightSuccessIncrement(double value) async {
    await updateSettings(
      _settings.copyWith(routeWeightSuccessIncrement: value),
    );
  }

  Future<void> setRouteWeightFailureDecrement(double value) async {
    await updateSettings(
      _settings.copyWith(routeWeightFailureDecrement: value),
    );
  }

  Future<void> setMaxMessageRetries(int value) async {
    await updateSettings(_settings.copyWith(maxMessageRetries: value));
  }

  Future<void> setChannelMinHopsEnabled(bool value) async {
    await updateSettings(_settings.copyWith(channelMinHopsEnabled: value));
  }

  Future<void> setChannelMinHops(int value) async {
    await updateSettings(_settings.copyWith(channelMinHops: value));
  }

  Future<void> setChannelMinHopsRetries(int value) async {
    await updateSettings(_settings.copyWith(channelMinHopsRetries: value));
  }

  Future<void> setChannelMinHopsCountRepeaters(bool value) async {
    await updateSettings(
      _settings.copyWith(channelMinHopsCountRepeaters: value),
    );
  }

  /// Picks a stock light/dark/system mode and leaves any custom theme.
  ///
  /// Counts as a manual choice: an automatically applied holiday theme is
  /// skipped for the rest of that holiday.
  Future<void> setThemeMode(String value) async {
    await updateSettings(
      _dismissAutoHoliday(
        _settings.copyWith(themeMode: value, activeThemeId: null),
      ),
    );
  }

  Future<void> setHolidayAnimationsEnabled(bool value) async {
    await updateSettings(_settings.copyWith(holidayAnimationsEnabled: value));
  }

  /// The theme in use, or null for the stock theme: the automatic holiday
  /// theme while one applies ([autoHolidayTheme]), otherwise the user's own
  /// choice ([AppSettings.activeThemeId]).
  CustomTheme? get activeCustomTheme =>
      autoHolidayTheme ?? _themeById(_settings.activeThemeId);

  /// The user's own chosen theme, ignoring any automatic holiday theme.
  CustomTheme? get chosenCustomTheme => _themeById(_settings.activeThemeId);

  CustomTheme? _themeById(String? id) {
    if (id == null) return null;
    return CustomTheme.presetById(id) ??
        _settings.customThemes.where((t) => t.id == id).firstOrNull;
  }

  /// The holiday within its window today, if auto-switching is on and the
  /// user has not overridden this occurrence. Null otherwise.
  ActiveHoliday? get autoHoliday {
    if (!_settings.holidayAutoSwitch) return null;
    final holiday = activeHolidayFor(_clock());
    if (holiday == null) return null;
    if (_settings.holidayThemeDismissed == holiday.occurrenceKey) return null;
    // The user picked this holiday's theme themselves: nothing to override.
    if (_settings.activeThemeId == holiday.themeId) return null;
    return holiday;
  }

  /// The holiday preset being applied automatically in place of the user's
  /// own theme, or null when none is.
  CustomTheme? get autoHolidayTheme {
    final holiday = autoHoliday;
    return holiday == null ? null : CustomTheme.presetById(holiday.themeId);
  }

  /// Marks the automatically applied holiday (if any) as overridden for this
  /// occurrence, so a manual theme choice sticks until the holiday is over.
  AppSettings _dismissAutoHoliday(AppSettings next) {
    final holiday = autoHoliday;
    if (holiday == null) return next;
    return next.copyWith(holidayThemeDismissed: holiday.occurrenceKey);
  }

  /// Applies a custom or preset theme; null returns to the stock theme.
  ///
  /// Picking a theme while a holiday theme is applied automatically keeps
  /// the pick for the rest of that holiday. Picking the automatic holiday
  /// theme itself changes nothing, so the user's own theme still returns
  /// after the holiday.
  Future<void> setActiveTheme(String? themeId) async {
    final holiday = autoHoliday;
    if (holiday != null && themeId == holiday.themeId) return;
    await updateSettings(
      _dismissAutoHoliday(_settings.copyWith(activeThemeId: themeId)),
    );
  }

  /// Turns automatic holiday themes on or off. Turning it on also forgets an
  /// earlier override, so the current holiday's theme shows again.
  Future<void> setHolidayAutoSwitch(bool value) async {
    await updateSettings(
      _settings.copyWith(
        holidayAutoSwitch: value,
        holidayThemeDismissed: value ? null : _settings.holidayThemeDismissed,
      ),
    );
  }

  // ---- date-change refresh --------------------------------------------------
  // The automatic holiday theme depends on the date. Once [startDateWatch] has
  // been called (the app does so at startup; tests normally don't), a timer
  // wakes at the next local midnight, or after an hour at most in case the
  // device slept through it, and tells listeners if the holiday theme
  // changed. It only runs while auto-switching is on.

  static const Duration _maxDateCheckInterval = Duration(hours: 1);

  Timer? _dateTimer;
  bool _dateWatchStarted = false;
  String? _lastAutoHolidayKey;

  /// Starts re-checking the automatic holiday theme when the date changes.
  void startDateWatch() {
    _dateWatchStarted = true;
    _lastAutoHolidayKey = autoHoliday?.occurrenceKey;
    _syncDateTimer();
  }

  void _syncDateTimer() {
    final wanted = _dateWatchStarted && _settings.holidayAutoSwitch;
    if (!wanted) {
      _dateTimer?.cancel();
      _dateTimer = null;
    } else if (_dateTimer == null) {
      _scheduleDateTimer();
    }
  }

  void _scheduleDateTimer() {
    final now = _clock();
    // A second past midnight so a slightly early wake-up still sees the new
    // day.
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    var delay = nextMidnight.difference(now);
    if (delay > _maxDateCheckInterval) delay = _maxDateCheckInterval;
    _dateTimer = Timer(delay, () {
      _dateTimer = null;
      checkDateChange();
      _syncDateTimer();
    });
  }

  /// Notifies listeners if the automatic holiday theme differs from the one
  /// last seen. Called by the date timer; public so tests can drive it.
  @visibleForTesting
  void checkDateChange() {
    final key = autoHoliday?.occurrenceKey;
    if (key == _lastAutoHolidayKey) return;
    _lastAutoHolidayKey = key;
    notifyListeners();
  }

  @visibleForTesting
  bool get hasDateTimer => _dateTimer != null;

  @override
  void dispose() {
    _dateTimer?.cancel();
    _dateTimer = null;
    super.dispose();
  }

  /// Adds [theme] or replaces the saved theme with the same ID.
  Future<void> saveCustomTheme(CustomTheme theme, {bool apply = false}) async {
    final themes = List<CustomTheme>.from(_settings.customThemes);
    final index = themes.indexWhere((t) => t.id == theme.id);
    if (index >= 0) {
      themes[index] = theme;
    } else {
      themes.add(theme);
    }
    final next = _settings.copyWith(
      customThemes: themes,
      activeThemeId: apply ? theme.id : _settings.activeThemeId,
    );
    // Applying a theme is a manual choice, like [setActiveTheme].
    await updateSettings(apply ? _dismissAutoHoliday(next) : next);
  }

  Future<void> deleteCustomTheme(String themeId) async {
    final themes = _settings.customThemes
        .where((t) => t.id != themeId)
        .toList();
    await updateSettings(
      _settings.copyWith(
        customThemes: themes,
        activeThemeId: _settings.activeThemeId == themeId
            ? null
            : _settings.activeThemeId,
      ),
    );
  }

  /// A fresh ID for a new custom theme.
  /// The counter keeps IDs unique when several are made in the same tick
  /// (bulk imports; web clocks only tick in milliseconds).
  String newCustomThemeId() =>
      'custom:${DateTime.now().microsecondsSinceEpoch}-${_themeIdCounter++}';
  int _themeIdCounter = 0;

  /// Adds [themes], skipping any identical (apart from ID) to a saved one.
  /// Returns how many were added.
  Future<int> importCustomThemes(List<CustomTheme> themes) async {
    final existing = List<CustomTheme>.from(_settings.customThemes);
    var added = 0;
    for (final theme in themes) {
      final duplicate = existing.any((t) => t == theme.copyWith(id: t.id));
      if (duplicate) continue;
      existing.add(theme);
      added++;
    }
    if (added > 0) {
      await updateSettings(_settings.copyWith(customThemes: existing));
    }
    return added;
  }

  Future<void> setLanguageOverride(String? value) async {
    await updateSettings(_settings.copyWith(languageOverride: value));
  }

  Future<void> setAppDebugLogEnabled(bool value) async {
    await updateSettings(_settings.copyWith(appDebugLogEnabled: value));
    // Update the global logger
    appLogger.setEnabled(value);
  }

  Future<void> setMapShowDiscoveryContacts(bool value) async {
    await updateSettings(_settings.copyWith(mapShowDiscoveryContacts: value));
  }

  Future<void> setEvictDiscoveredContactsEnabled(bool value) async {
    await updateSettings(
      _settings.copyWith(evictDiscoveredContactsEnabled: value),
    );
  }

  Future<void> setBatteryChemistryForDevice(
    String deviceId,
    String chemistry,
  ) async {
    final updated = Map<String, String>.from(
      _settings.batteryChemistryByDeviceId,
    );
    updated[deviceId] = chemistry;
    await updateSettings(
      _settings.copyWith(batteryChemistryByDeviceId: updated),
    );
  }

  Future<void> setBatteryChemistryForRepeater(
    String repeaterPubKeyHex,
    String chemistry,
  ) async {
    final updated = Map<String, String>.from(
      _settings.batteryChemistryByRepeaterId,
    );
    updated[repeaterPubKeyHex] = chemistry;
    await updateSettings(
      _settings.copyWith(batteryChemistryByRepeaterId: updated),
    );
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    await updateSettings(_settings.copyWith(unitSystem: value));
  }

  ChannelNotificationMode getChannelNotificationMode(String channelName) {
    return _settings.channelNotificationModes[channelName] ??
        ChannelNotificationMode.all;
  }

  Future<void> setChannelNotificationMode(
    String channelName,
    ChannelNotificationMode mode,
  ) async {
    final updated = Map<String, ChannelNotificationMode>.from(
      _settings.channelNotificationModes,
    );
    if (mode == ChannelNotificationMode.all) {
      updated.remove(channelName);
    } else {
      updated[channelName] = mode;
    }
    await updateSettings(_settings.copyWith(channelNotificationModes: updated));
  }

  Future<void> setTcpServerAddress(String value) async {
    await updateSettings(_settings.copyWith(tcpServerAddress: value));
  }

  Future<void> setTcpServerPort(int value) async {
    await updateSettings(_settings.copyWith(tcpServerPort: value));
  }

  Future<void> setJumpToOldestUnread(bool value) async {
    await updateSettings(_settings.copyWith(jumpToOldestUnread: value));
  }

  Future<void> setAutoFetchRepeaterSettings(bool value) async {
    await updateSettings(_settings.copyWith(autoFetchRepeaterSettings: value));
  }

  Future<void> setNetworkMapUploadEnabled(bool value) async {
    await updateSettings(_settings.copyWith(networkMapUploadEnabled: value));
  }

  Future<void> setNetworkMapPromptShown(bool value) async {
    await updateSettings(_settings.copyWith(networkMapPromptShown: value));
  }

  Future<void> setLoadLinkImages(bool value) async {
    await updateSettings(_settings.copyWith(loadLinkImages: value));
  }

  Future<void> setShowLinkImagesByDefault(bool value) async {
    await updateSettings(_settings.copyWith(showLinkImagesByDefault: value));
  }

  Future<void> setIpfsImageSettings({
    required String publicGateway,
    required String uploadGateway,
    required String uploadEndpoint,
    required String uploadApiKey,
  }) async {
    final normalizedPublicGateway = normalizeIpfsGateway(publicGateway);
    final normalizedUploadGateway = normalizeIpfsGateway(uploadGateway);
    await updateSettings(
      _settings.copyWith(
        publicIpfsGateway: normalizedPublicGateway,
        uploadIpfsGateway: normalizedUploadGateway,
        uploadIpfsEndpoint: uploadEndpoint.trim(),
        uploadIpfsApiKey: uploadApiKey.trim(),
      ),
    );
  }

  Future<void> setImageMessagesEnabled(bool value) async {
    await updateSettings(_settings.copyWith(imageMessagesEnabled: value));
  }

  /// See [AppSettings.imageProcessAutomatically]. `main.dart` mirrors this into
  /// `ReceivedImageStore.processAutomatically` on every settings change; the
  /// store applies it to future arrivals only, so flipping it does not
  /// retroactively decode a backlog.
  Future<void> setImageProcessAutomatically(bool value) async {
    await updateSettings(_settings.copyWith(imageProcessAutomatically: value));
  }

  // ---- neural image codec (AEIC-SE) ---------------------------------------

  Future<void> setImageCodecEnabled(bool value) async {
    await updateSettings(_settings.copyWith(imageCodecEnabled: value));
  }

  Future<void> setImageCodecSelectedModelId(String? value) async {
    await updateSettings(_settings.copyWith(imageCodecSelectedModelId: value));
  }

  Future<void> setImageCodecModelSourceUrl(String? value) async {
    await updateSettings(_settings.copyWith(imageCodecModelSourceUrl: value));
  }

  /// [value] is an [AeicRatePoint.wireValue], not an enum index.
  Future<void> setImageCodecRatePoint(int value) async {
    await updateSettings(_settings.copyWith(imageCodecRatePoint: value));
  }

  Future<void> setImageCodecDownloadedModels(
    List<ImageCodecModelRecord> value,
  ) async {
    await updateSettings(_settings.copyWith(imageCodecDownloadedModels: value));
  }

  /// Writes the whole block in one persist, which is what
  /// `ImageCodecService` does on every preference change.
  Future<void> setImageCodecPreferences(ImageCodecPreferences value) async {
    await updateSettings(
      _settings.copyWith(
        imageCodecEnabled: value.enabled,
        imageCodecSelectedModelId: value.selectedModelId,
        imageCodecModelSourceUrl: value.modelSourceUrl,
        imageCodecRatePoint: value.ratePoint,
        imageCodecDownloadedModels: value.downloadedModels,
      ),
    );
  }

  Future<void> setTranslationEnabled(bool value) async {
    await updateSettings(_settings.copyWith(translationEnabled: value));
  }

  Future<void> setAutoTranslateIncomingMessages(bool value) async {
    await updateSettings(
      _settings.copyWith(autoTranslateIncomingMessages: value),
    );
  }

  Future<void> setTranslationTargetLanguageCode(String? value) async {
    await updateSettings(
      _settings.copyWith(translationTargetLanguageCode: value),
    );
  }

  Future<void> setComposerTranslationEnabled(bool value) async {
    await updateSettings(_settings.copyWith(composerTranslationEnabled: value));
  }

  Future<void> setTranslationModelSourceUrl(String? value) async {
    await updateSettings(_settings.copyWith(translationModelSourceUrl: value));
  }

  Future<void> setTranslationSelectedModelId(String? value) async {
    await updateSettings(_settings.copyWith(translationSelectedModelId: value));
  }

  Future<void> setTranslationDownloadedModels(
    List<TranslationModelRecord> value,
  ) async {
    await updateSettings(
      _settings.copyWith(translationDownloadedModels: value),
    );
  }

  Cyr2LatProfile getSelectedCyr2LatProfile() {
    return _settings.cyr2latProfiles.firstWhere(
      (p) => p.id == _settings.selectedCyr2latProfileId,
      orElse: () => _settings.cyr2latProfiles.first,
    );
  }

  Cyr2LatProfile? getCyr2LatProfileById(String profileId) {
    return _settings.cyr2latProfiles.cast<Cyr2LatProfile?>().firstWhere(
      (p) => p?.id == profileId,
      orElse: () => null,
    );
  }

  Future<void> setSelectedCyr2LatProfile(String profileId) async {
    await updateSettings(
      _settings.copyWith(selectedCyr2latProfileId: profileId),
    );
  }

  Future<void> addCyr2LatProfile(Cyr2LatProfile profile) async {
    final updated = List<Cyr2LatProfile>.from(_settings.cyr2latProfiles)
      ..add(profile);
    await updateSettings(_settings.copyWith(cyr2latProfiles: updated));
  }

  Future<void> updateCyr2LatProfile(Cyr2LatProfile updatedProfile) async {
    final updated = _settings.cyr2latProfiles
        .map((p) => p.id == updatedProfile.id ? updatedProfile : p)
        .toList();
    await updateSettings(_settings.copyWith(cyr2latProfiles: updated));
  }

  Future<void> removeCyr2LatProfile(String profileId) async {
    if (_settings.cyr2latProfiles.length <= 1) {
      return; // Don't remove the last profile
    }
    final updated = _settings.cyr2latProfiles
        .where((p) => p.id != profileId)
        .toList();
    var newSelectedId = _settings.selectedCyr2latProfileId;
    if (newSelectedId == profileId) {
      newSelectedId = updated.first.id;
    }
    await updateSettings(
      _settings.copyWith(
        cyr2latProfiles: updated,
        selectedCyr2latProfileId: newSelectedId,
      ),
    );
  }
}
