import 'image_codec_support.dart';
import 'translation_support.dart';

enum UnitSystem { metric, imperial }

extension UnitSystemValue on UnitSystem {
  String get value {
    switch (this) {
      case UnitSystem.imperial:
        return 'imperial';
      case UnitSystem.metric:
        return 'metric';
    }
  }
}

const Map<String, String> defaultCyr2LatCharMap = {
  'А': 'A',
  'В': 'B',
  'Е': 'E',
  'Ё': 'E',
  'З': '3',
  'К': 'K',
  'М': 'M',
  'Н': 'H',
  'О': 'O',
  'Р': 'P',
  'С': 'C',
  'Т': 'T',
  'Х': 'X',
  'Ь': 'b',
  'а': 'a',
  'е': 'e',
  'ё': 'e',
  'о': 'o',
  'р': 'p',
  'с': 'c',
  'у': 'y',
  'х': 'x',
};

class Cyr2LatProfile {
  final String id;
  final String name;
  final Map<String, String> charMap;

  Cyr2LatProfile({required this.id, required this.name, required this.charMap});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'char_map': charMap};
  }

  factory Cyr2LatProfile.fromJson(Map<String, dynamic> json) {
    return Cyr2LatProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      charMap:
          (json['char_map'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
    );
  }

  Cyr2LatProfile copyWith({
    String? id,
    String? name,
    Map<String, String>? charMap,
  }) {
    return Cyr2LatProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      charMap: charMap ?? this.charMap,
    );
  }
}

class AppSettings {
  static const Object _unset = Object();
  static const String stadiaDemo = '51bd0381-4685-4666-bae8-48940f6d77c0';

  final bool clearPathOnMaxRetry;
  final bool mapShowRepeaters;
  final bool mapShowChatNodes;
  final bool mapShowOtherNodes;
  final bool mapShowOverlaps;
  final double mapTimeFilterHours; // 0 = all time
  final bool mapKeyPrefixEnabled;
  final String mapKeyPrefix;
  final bool mapShowMarkers;
  final bool mapShowGuessedLocations;
  final bool enableMessageTracing;
  final Map<String, double>? mapCacheBounds;
  final int mapCacheMinZoom;
  final int mapCacheMaxZoom;
  final String mapRasterSourceId;
  final String mapTileEndpointId;
  final String? mapTileApiKey;
  final bool notificationsEnabled;
  final bool notifyOnNewMessage;
  final bool notifyOnNewChannelMessage;
  final bool notifyOnNewAdvert;
  final bool autoSendZeroHopAdvertOnGpsUpdate;
  final bool autoSendSelfAdvertAsFlood;
  final int gpsIntervalSeconds;
  final bool autoRouteRotationEnabled;
  final double maxRouteWeight;
  final double initialRouteWeight;
  final double routeWeightSuccessIncrement;
  final double routeWeightFailureDecrement;
  final int maxMessageRetries;
  final String themeMode;
  final String? languageOverride; // null = system default
  final bool appDebugLogEnabled;
  final Map<String, String> batteryChemistryByDeviceId;
  final Map<String, String> batteryChemistryByRepeaterId;
  final UnitSystem unitSystem;
  final Set<String> mutedChannels;
  final bool mapShowDiscoveryContacts;
  final String tcpServerAddress;
  final int tcpServerPort;
  final bool jumpToOldestUnread;
  final bool imageMessagesEnabled;

  /// Whether a received image is decoded as soon as it is reassembled.
  ///
  /// Off by default and deliberately so: a decode peaks around 2.16 GiB
  /// resident and takes about a second, so an unattended chat must not be able
  /// to trigger one per arriving image. When false, `ReceivedImageStore` parks
  /// the arrival as a "Tap to process" placeholder instead of queueing it.
  final bool imageProcessAutomatically;

  // ---- neural image codec (AEIC-SE) ---------------------------------------
  // Structural twins of the translation block above; the JSON keys match
  // ImageCodecPreferences.toJson so ImageCodecService reads them unchanged.
  final bool imageCodecEnabled;
  final String? imageCodecSelectedModelId;
  final String? imageCodecModelSourceUrl;

  /// [AeicRatePoint.wireValue] of the composer's default rate point.
  /// 4 == ft32, the only rate point this build ships.
  final int imageCodecRatePoint;

  final List<ImageCodecModelRecord> imageCodecDownloadedModels;

  final bool translationEnabled;
  final bool autoTranslateIncomingMessages;
  final String? translationTargetLanguageCode;
  final bool composerTranslationEnabled;
  final String? translationModelSourceUrl;
  final String? translationSelectedModelId;
  final List<TranslationModelRecord> translationDownloadedModels;
  final List<Cyr2LatProfile> cyr2latProfiles;
  final String selectedCyr2latProfileId;

  /// The five `imageCodec*` fields as the value object `ImageCodecService`
  /// consumes. Assembled rather than stored so the settings blob stays flat.
  ImageCodecPreferences get imageCodec => ImageCodecPreferences(
    enabled: imageCodecEnabled,
    selectedModelId: imageCodecSelectedModelId,
    modelSourceUrl: imageCodecModelSourceUrl,
    ratePoint: imageCodecRatePoint,
    downloadedModels: imageCodecDownloadedModels,
  );

  String get effectiveMapTileApiKey {
    final apiKey = mapTileApiKey?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      return stadiaDemo;
    }
    return apiKey;
  }

  bool get usesstadiaDemo => effectiveMapTileApiKey == stadiaDemo;

  Map<String, String> get cyr2latCharMap {
    final profile = cyr2latProfiles.firstWhere(
      (p) => p.id == selectedCyr2latProfileId,
      orElse: () => cyr2latProfiles.first,
    );
    return profile.charMap;
  }

  AppSettings({
    this.clearPathOnMaxRetry = false,
    this.mapShowRepeaters = true,
    this.mapShowChatNodes = true,
    this.mapShowOtherNodes = true,
    this.mapShowOverlaps = false,
    this.mapTimeFilterHours = 0, // Default to all time
    this.mapKeyPrefixEnabled = false,
    this.mapKeyPrefix = '',
    this.mapShowMarkers = true,
    this.mapShowGuessedLocations = true,
    this.enableMessageTracing = true,
    this.mapCacheBounds,
    this.mapCacheMinZoom = 10,
    this.mapCacheMaxZoom = 15,
    this.mapRasterSourceId = 'osm_auto',
    this.mapTileEndpointId = 'standard_2x',
    this.mapTileApiKey,
    this.notificationsEnabled = true,
    this.notifyOnNewMessage = true,
    this.notifyOnNewChannelMessage = true,
    this.notifyOnNewAdvert = true,
    this.autoSendZeroHopAdvertOnGpsUpdate = false,
    this.autoSendSelfAdvertAsFlood = false,
    this.gpsIntervalSeconds = 900,
    this.autoRouteRotationEnabled = true,
    this.maxRouteWeight = 5.0,
    this.initialRouteWeight = 3.0,
    this.routeWeightSuccessIncrement = 0.5,
    this.routeWeightFailureDecrement = 0.2,
    this.maxMessageRetries = 5,
    this.themeMode = 'system',
    this.languageOverride,
    this.appDebugLogEnabled = false,
    Map<String, String>? batteryChemistryByDeviceId,
    Map<String, String>? batteryChemistryByRepeaterId,
    this.unitSystem = UnitSystem.metric,
    Set<String>? mutedChannels,
    this.mapShowDiscoveryContacts = true,
    this.tcpServerAddress = '',
    this.tcpServerPort = 0,
    this.jumpToOldestUnread = false,
    this.imageMessagesEnabled = false,
    this.imageProcessAutomatically = false,
    this.imageCodecEnabled = false,
    this.imageCodecSelectedModelId,
    this.imageCodecModelSourceUrl,
    this.imageCodecRatePoint = 4,
    List<ImageCodecModelRecord>? imageCodecDownloadedModels,
    this.translationEnabled = false,
    this.autoTranslateIncomingMessages = true,
    this.translationTargetLanguageCode,
    this.composerTranslationEnabled = false,
    this.translationModelSourceUrl,
    this.translationSelectedModelId,
    List<TranslationModelRecord>? translationDownloadedModels,
    List<Cyr2LatProfile>? cyr2latProfiles,
    String? selectedCyr2latProfileId,
  }) : batteryChemistryByDeviceId = batteryChemistryByDeviceId ?? {},
       batteryChemistryByRepeaterId = batteryChemistryByRepeaterId ?? {},
       mutedChannels = mutedChannels ?? {},
       imageCodecDownloadedModels = imageCodecDownloadedModels ?? const [],
       translationDownloadedModels = translationDownloadedModels ?? const [],
       cyr2latProfiles =
           cyr2latProfiles ??
           [
             Cyr2LatProfile(
               id: 'default',
               name: 'Default',
               charMap: defaultCyr2LatCharMap,
             ),
           ],
       selectedCyr2latProfileId = selectedCyr2latProfileId ?? 'default';

  Map<String, dynamic> toJson() {
    return {
      'clear_path_on_max_retry': clearPathOnMaxRetry,
      'map_show_repeaters': mapShowRepeaters,
      'map_show_chat_nodes': mapShowChatNodes,
      'map_show_other_nodes': mapShowOtherNodes,
      'map_show_overlaps': mapShowOverlaps,
      'map_time_filter_hours': mapTimeFilterHours,
      'map_key_prefix_enabled': mapKeyPrefixEnabled,
      'map_key_prefix': mapKeyPrefix,
      'map_show_markers': mapShowMarkers,
      'map_show_guessed_locations': mapShowGuessedLocations,
      'enable_message_tracing': enableMessageTracing,
      'map_cache_bounds': mapCacheBounds,
      'map_cache_min_zoom': mapCacheMinZoom,
      'map_cache_max_zoom': mapCacheMaxZoom,
      'map_raster_source_id': mapRasterSourceId,
      'map_tile_endpoint_id': mapTileEndpointId,
      'map_tile_api_key': mapTileApiKey,
      'notifications_enabled': notificationsEnabled,
      'notify_on_new_message': notifyOnNewMessage,
      'notify_on_new_channel_message': notifyOnNewChannelMessage,
      'notify_on_new_advert': notifyOnNewAdvert,
      'auto_send_zero_hop_advert_on_gps_update':
          autoSendZeroHopAdvertOnGpsUpdate,
      'auto_send_self_advert_as_flood': autoSendSelfAdvertAsFlood,
      'gps_interval_seconds': gpsIntervalSeconds,
      'auto_route_rotation_enabled': autoRouteRotationEnabled,
      'max_route_weight': maxRouteWeight,
      'initial_route_weight': initialRouteWeight,
      'route_weight_success_increment': routeWeightSuccessIncrement,
      'route_weight_failure_decrement': routeWeightFailureDecrement,
      'max_message_retries': maxMessageRetries,
      'theme_mode': themeMode,
      'language_override': languageOverride,
      'app_debug_log_enabled': appDebugLogEnabled,
      'battery_chemistry_by_device_id': batteryChemistryByDeviceId,
      'battery_chemistry_by_repeater_id': batteryChemistryByRepeaterId,
      'unit_system': unitSystem.value,
      'muted_channels': mutedChannels.toList(),
      'map_show_discovery_contacts': mapShowDiscoveryContacts,
      'tcp_server_address': tcpServerAddress,
      'tcp_server_port': tcpServerPort,
      'jump_to_oldest_unread': jumpToOldestUnread,
      'image_messages_enabled': imageMessagesEnabled,
      'image_process_automatically': imageProcessAutomatically,
      'image_codec_enabled': imageCodecEnabled,
      'image_codec_selected_model_id': imageCodecSelectedModelId,
      'image_codec_model_source_url': imageCodecModelSourceUrl,
      'image_codec_rate_point': imageCodecRatePoint,
      'image_codec_downloaded_models': imageCodecDownloadedModels
          .map((model) => model.toJson())
          .toList(),
      'translation_enabled': translationEnabled,
      'auto_translate_incoming_messages': autoTranslateIncomingMessages,
      'translation_target_language_code': translationTargetLanguageCode,
      'composer_translation_enabled': composerTranslationEnabled,
      'translation_model_source_url': translationModelSourceUrl,
      'translation_selected_model_id': translationSelectedModelId,
      'translation_downloaded_models': translationDownloadedModels
          .map((model) => model.toJson())
          .toList(),
      'cyr2lat_profiles': cyr2latProfiles
          .map((profile) => profile.toJson())
          .toList(),
      'selected_cyr2lat_profile_id': selectedCyr2latProfileId,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    UnitSystem parseUnitSystem(dynamic value) {
      if (value is String && value.toLowerCase() == 'imperial') {
        return UnitSystem.imperial;
      }
      return UnitSystem.metric;
    }

    return AppSettings(
      clearPathOnMaxRetry: json['clear_path_on_max_retry'] as bool? ?? false,
      mapShowRepeaters: json['map_show_repeaters'] as bool? ?? true,
      mapShowChatNodes: json['map_show_chat_nodes'] as bool? ?? true,
      mapShowOtherNodes: json['map_show_other_nodes'] as bool? ?? true,
      mapShowOverlaps: json['map_show_overlaps'] as bool? ?? false,
      mapTimeFilterHours:
          (json['map_time_filter_hours'] as num?)?.toDouble() ?? 0,
      mapKeyPrefixEnabled: json['map_key_prefix_enabled'] as bool? ?? false,
      mapKeyPrefix: json['map_key_prefix'] as String? ?? '',
      mapShowMarkers: json['map_show_markers'] as bool? ?? true,
      mapShowGuessedLocations:
          json['map_show_guessed_locations'] as bool? ?? true,
      enableMessageTracing: json['enable_message_tracing'] as bool? ?? true,
      mapCacheBounds: (json['map_cache_bounds'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
      mapCacheMinZoom: json['map_cache_min_zoom'] as int? ?? 10,
      mapCacheMaxZoom: json['map_cache_max_zoom'] as int? ?? 15,
      mapRasterSourceId: json['map_raster_source_id'] as String? ?? 'osm_auto',
      mapTileEndpointId: json['map_tile_endpoint_id'] as String? ?? 'standard',
      mapTileApiKey: json['map_tile_api_key'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      notifyOnNewMessage: json['notify_on_new_message'] as bool? ?? true,
      notifyOnNewChannelMessage:
          json['notify_on_new_channel_message'] as bool? ?? true,
      notifyOnNewAdvert: json['notify_on_new_advert'] as bool? ?? true,
      autoSendZeroHopAdvertOnGpsUpdate:
          json['auto_send_zero_hop_advert_on_gps_update'] as bool? ?? false,
      autoSendSelfAdvertAsFlood:
          json['auto_send_self_advert_as_flood'] as bool? ?? false,
      gpsIntervalSeconds:
          (json['gps_interval_seconds'] as num?)?.toInt() ?? 900,
      autoRouteRotationEnabled:
          json['auto_route_rotation_enabled'] as bool? ?? true,
      maxRouteWeight: (json['max_route_weight'] as num?)?.toDouble() ?? 5.0,
      initialRouteWeight:
          (json['initial_route_weight'] as num?)?.toDouble() ?? 3.0,
      routeWeightSuccessIncrement:
          (json['route_weight_success_increment'] as num?)?.toDouble() ?? 0.5,
      routeWeightFailureDecrement:
          (json['route_weight_failure_decrement'] as num?)?.toDouble() ?? 0.2,
      maxMessageRetries: json['max_message_retries'] as int? ?? 5,
      themeMode: json['theme_mode'] as String? ?? 'system',
      languageOverride: json['language_override'] as String?,
      appDebugLogEnabled: json['app_debug_log_enabled'] as bool? ?? false,
      batteryChemistryByDeviceId:
          (json['battery_chemistry_by_device_id'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
      batteryChemistryByRepeaterId:
          (json['battery_chemistry_by_repeater_id'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
      unitSystem: parseUnitSystem(json['unit_system']),
      mutedChannels:
          ((json['muted_channels'] as List?)
              ?.map((e) => e.toString())
              .toSet()) ??
          {},
      mapShowDiscoveryContacts:
          json['map_show_discovery_contacts'] as bool? ?? true,
      tcpServerAddress: json['tcp_server_address'] as String? ?? '',
      tcpServerPort: json['tcp_server_port'] as int? ?? 0,
      jumpToOldestUnread: json['jump_to_oldest_unread'] as bool? ?? false,
      imageMessagesEnabled: json['image_messages_enabled'] as bool? ?? false,
      imageProcessAutomatically:
          json['image_process_automatically'] as bool? ?? false,
      imageCodecEnabled: json['image_codec_enabled'] as bool? ?? false,
      imageCodecSelectedModelId:
          json['image_codec_selected_model_id'] as String?,
      imageCodecModelSourceUrl: json['image_codec_model_source_url'] as String?,
      imageCodecRatePoint: json['image_codec_rate_point'] as int? ?? 4,
      imageCodecDownloadedModels:
          (json['image_codec_downloaded_models'] as List<dynamic>?)
              ?.map(
                (entry) => ImageCodecModelRecord.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
      translationEnabled: json['translation_enabled'] as bool? ?? false,
      autoTranslateIncomingMessages:
          json['auto_translate_incoming_messages'] as bool? ?? true,
      translationTargetLanguageCode:
          json['translation_target_language_code'] as String?,
      composerTranslationEnabled:
          json['composer_translation_enabled'] as bool? ?? false,
      translationModelSourceUrl:
          json['translation_model_source_url'] as String?,
      translationSelectedModelId:
          json['translation_selected_model_id'] as String?,
      translationDownloadedModels:
          (json['translation_downloaded_models'] as List<dynamic>?)
              ?.map(
                (entry) => TranslationModelRecord.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
      cyr2latProfiles:
          (json['cyr2lat_profiles'] as List<dynamic>?)
              ?.map(
                (entry) => Cyr2LatProfile.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          // Backward compatibility: if old cyr2lat_char_map exists, create a profile from it
          (json['cyr2lat_char_map'] != null
              ? [
                  Cyr2LatProfile(
                    id: 'migrated',
                    name: 'Migrated Profile',
                    charMap:
                        (json['cyr2lat_char_map'] as Map?)?.map(
                          (key, value) =>
                              MapEntry(key.toString(), value.toString()),
                        ) ??
                        defaultCyr2LatCharMap,
                  ),
                ]
              : [
                  Cyr2LatProfile(
                    id: 'default',
                    name: 'Default',
                    charMap: defaultCyr2LatCharMap,
                  ),
                ]),
      selectedCyr2latProfileId:
          json['selected_cyr2lat_profile_id'] as String? ??
          (json['cyr2lat_char_map'] != null ? 'migrated' : 'default'),
    );
  }

  AppSettings copyWith({
    bool? clearPathOnMaxRetry,
    bool? mapShowRepeaters,
    bool? mapShowChatNodes,
    bool? mapShowOtherNodes,
    bool? mapShowOverlaps,
    double? mapTimeFilterHours,
    bool? mapKeyPrefixEnabled,
    String? mapKeyPrefix,
    bool? mapShowMarkers,
    bool? mapShowGuessedLocations,
    bool? enableMessageTracing,
    Object? mapCacheBounds = _unset,
    int? mapCacheMinZoom,
    int? mapCacheMaxZoom,
    String? mapRasterSourceId,
    String? mapTileEndpointId,
    Object? mapTileApiKey = _unset,
    bool? notificationsEnabled,
    bool? notifyOnNewMessage,
    bool? notifyOnNewChannelMessage,
    bool? notifyOnNewAdvert,
    bool? autoSendZeroHopAdvertOnGpsUpdate,
    bool? autoSendSelfAdvertAsFlood,
    int? gpsIntervalSeconds,
    bool? autoRouteRotationEnabled,
    double? maxRouteWeight,
    double? initialRouteWeight,
    double? routeWeightSuccessIncrement,
    double? routeWeightFailureDecrement,
    int? maxMessageRetries,
    String? themeMode,
    Object? languageOverride = _unset,
    bool? appDebugLogEnabled,
    Map<String, String>? batteryChemistryByDeviceId,
    Map<String, String>? batteryChemistryByRepeaterId,
    UnitSystem? unitSystem,
    Set<String>? mutedChannels,
    bool? mapShowDiscoveryContacts,
    String? tcpServerAddress,
    int? tcpServerPort,
    bool? jumpToOldestUnread,
    bool? imageMessagesEnabled,
    bool? imageProcessAutomatically,
    bool? imageCodecEnabled,
    Object? imageCodecSelectedModelId = _unset,
    Object? imageCodecModelSourceUrl = _unset,
    int? imageCodecRatePoint,
    List<ImageCodecModelRecord>? imageCodecDownloadedModels,
    bool? translationEnabled,
    bool? autoTranslateIncomingMessages,
    Object? translationTargetLanguageCode = _unset,
    bool? composerTranslationEnabled,
    Object? translationModelSourceUrl = _unset,
    Object? translationSelectedModelId = _unset,
    List<TranslationModelRecord>? translationDownloadedModels,
    List<Cyr2LatProfile>? cyr2latProfiles,
    String? selectedCyr2latProfileId,
  }) {
    return AppSettings(
      clearPathOnMaxRetry: clearPathOnMaxRetry ?? this.clearPathOnMaxRetry,
      mapShowRepeaters: mapShowRepeaters ?? this.mapShowRepeaters,
      mapShowChatNodes: mapShowChatNodes ?? this.mapShowChatNodes,
      mapShowOtherNodes: mapShowOtherNodes ?? this.mapShowOtherNodes,
      mapShowOverlaps: mapShowOverlaps ?? this.mapShowOverlaps,
      mapTimeFilterHours: mapTimeFilterHours ?? this.mapTimeFilterHours,
      mapKeyPrefixEnabled: mapKeyPrefixEnabled ?? this.mapKeyPrefixEnabled,
      mapKeyPrefix: mapKeyPrefix ?? this.mapKeyPrefix,
      mapShowMarkers: mapShowMarkers ?? this.mapShowMarkers,
      mapShowGuessedLocations:
          mapShowGuessedLocations ?? this.mapShowGuessedLocations,
      enableMessageTracing: enableMessageTracing ?? this.enableMessageTracing,
      mapCacheBounds: mapCacheBounds == _unset
          ? this.mapCacheBounds
          : mapCacheBounds as Map<String, double>?,
      mapCacheMinZoom: mapCacheMinZoom ?? this.mapCacheMinZoom,
      mapCacheMaxZoom: mapCacheMaxZoom ?? this.mapCacheMaxZoom,
      mapRasterSourceId: mapRasterSourceId ?? this.mapRasterSourceId,
      mapTileEndpointId: mapTileEndpointId ?? this.mapTileEndpointId,
      mapTileApiKey: mapTileApiKey == _unset
          ? this.mapTileApiKey
          : mapTileApiKey as String?,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyOnNewMessage: notifyOnNewMessage ?? this.notifyOnNewMessage,
      notifyOnNewChannelMessage:
          notifyOnNewChannelMessage ?? this.notifyOnNewChannelMessage,
      notifyOnNewAdvert: notifyOnNewAdvert ?? this.notifyOnNewAdvert,
      autoSendZeroHopAdvertOnGpsUpdate:
          autoSendZeroHopAdvertOnGpsUpdate ??
          this.autoSendZeroHopAdvertOnGpsUpdate,
      autoSendSelfAdvertAsFlood:
          autoSendSelfAdvertAsFlood ?? this.autoSendSelfAdvertAsFlood,
      gpsIntervalSeconds: gpsIntervalSeconds ?? this.gpsIntervalSeconds,
      autoRouteRotationEnabled:
          autoRouteRotationEnabled ?? this.autoRouteRotationEnabled,
      maxRouteWeight: maxRouteWeight ?? this.maxRouteWeight,
      initialRouteWeight: initialRouteWeight ?? this.initialRouteWeight,
      routeWeightSuccessIncrement:
          routeWeightSuccessIncrement ?? this.routeWeightSuccessIncrement,
      routeWeightFailureDecrement:
          routeWeightFailureDecrement ?? this.routeWeightFailureDecrement,
      maxMessageRetries: maxMessageRetries ?? this.maxMessageRetries,
      themeMode: themeMode ?? this.themeMode,
      languageOverride: languageOverride == _unset
          ? this.languageOverride
          : languageOverride as String?,
      appDebugLogEnabled: appDebugLogEnabled ?? this.appDebugLogEnabled,
      batteryChemistryByDeviceId:
          batteryChemistryByDeviceId ?? this.batteryChemistryByDeviceId,
      batteryChemistryByRepeaterId:
          batteryChemistryByRepeaterId ?? this.batteryChemistryByRepeaterId,
      unitSystem: unitSystem ?? this.unitSystem,
      mutedChannels: mutedChannels ?? this.mutedChannels,
      mapShowDiscoveryContacts:
          mapShowDiscoveryContacts ?? this.mapShowDiscoveryContacts,
      tcpServerAddress: tcpServerAddress ?? this.tcpServerAddress,
      tcpServerPort: tcpServerPort ?? this.tcpServerPort,
      jumpToOldestUnread: jumpToOldestUnread ?? this.jumpToOldestUnread,
      imageMessagesEnabled: imageMessagesEnabled ?? this.imageMessagesEnabled,
      imageProcessAutomatically:
          imageProcessAutomatically ?? this.imageProcessAutomatically,
      imageCodecEnabled: imageCodecEnabled ?? this.imageCodecEnabled,
      imageCodecSelectedModelId: imageCodecSelectedModelId == _unset
          ? this.imageCodecSelectedModelId
          : imageCodecSelectedModelId as String?,
      imageCodecModelSourceUrl: imageCodecModelSourceUrl == _unset
          ? this.imageCodecModelSourceUrl
          : imageCodecModelSourceUrl as String?,
      imageCodecRatePoint: imageCodecRatePoint ?? this.imageCodecRatePoint,
      imageCodecDownloadedModels:
          imageCodecDownloadedModels ?? this.imageCodecDownloadedModels,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      autoTranslateIncomingMessages:
          autoTranslateIncomingMessages ?? this.autoTranslateIncomingMessages,
      translationTargetLanguageCode: translationTargetLanguageCode == _unset
          ? this.translationTargetLanguageCode
          : translationTargetLanguageCode as String?,
      composerTranslationEnabled:
          composerTranslationEnabled ?? this.composerTranslationEnabled,
      translationModelSourceUrl: translationModelSourceUrl == _unset
          ? this.translationModelSourceUrl
          : translationModelSourceUrl as String?,
      translationSelectedModelId: translationSelectedModelId == _unset
          ? this.translationSelectedModelId
          : translationSelectedModelId as String?,
      translationDownloadedModels:
          translationDownloadedModels ?? this.translationDownloadedModels,
      cyr2latProfiles: cyr2latProfiles ?? this.cyr2latProfiles,
      selectedCyr2latProfileId:
          selectedCyr2latProfileId ?? this.selectedCyr2latProfileId,
    );
  }
}
