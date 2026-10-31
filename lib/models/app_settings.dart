import 'image_codec_support.dart';
import 'translation_support.dart';

enum UnitSystem { metric, imperial }

String normalizeIpfsGateway(String value) {
  var gateway = value.trim();
  if (gateway.isEmpty) return gateway;
  if (!gateway.startsWith('http://') && !gateway.startsWith('https://')) {
    gateway = 'https://$gateway';
  }
  gateway = gateway.replaceAll('{cid}', '');
  if (gateway.endsWith('/ipfs')) gateway = '$gateway/';
  if (!gateway.endsWith('/ipfs/')) {
    gateway = '${gateway.endsWith('/') ? gateway : '$gateway/'}ipfs/';
  }
  return gateway;
}

enum ChannelNotificationMode { all, mentionsOnly, muted }

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
  static const String defaultPublicIpfsGateway = 'https://ipfs.io/ipfs/';

  // Routing algorithm default values
  static const double defaultMaxRouteWeight = 5.0;
  static const double defaultInitialRouteWeight = 3.0;
  static const double defaultRouteWeightSuccessIncrement = 0.5;
  static const double defaultRouteWeightFailureDecrement = 0.2;
  static const int defaultMaxMessageRetries = 5;

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
  final bool mapClusterNodes;
  final bool enableMessageTracing;
  final bool regionOnHopsLine;
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
  final int gpsIntervalSeconds;
  final bool autoRouteRotationEnabled;
  final double maxRouteWeight;
  final double initialRouteWeight;
  final double routeWeightSuccessIncrement;
  final double routeWeightFailureDecrement;
  final int maxMessageRetries;
  final bool channelMinHopsEnabled;
  final int channelMinHops;
  final int channelMinHopsRetries;

  /// When on, hearing the message repeated by at least [channelMinHops]
  /// different first-hop repeaters also satisfies the channel resend.
  final bool channelMinHopsCountRepeaters;
  final String themeMode;
  final String? languageOverride; // null = system default
  final bool appDebugLogEnabled;
  final Map<String, String> batteryChemistryByDeviceId;
  final Map<String, String> batteryChemistryByRepeaterId;
  final UnitSystem unitSystem;
  final Map<String, ChannelNotificationMode> channelNotificationModes;
  final bool mapShowDiscoveryContacts;
  final bool evictDiscoveredContactsEnabled;
  final String tcpServerAddress;
  final int tcpServerPort;
  final bool jumpToOldestUnread;
  final bool autoFetchRepeaterSettings;
  final bool imageMessagesEnabled;

  /// Master switch for fetching images behind links in messages.
  final bool loadLinkImages;

  /// Chats with no saved link-image choice load link images when true.
  final bool showLinkImagesByDefault;
  final String publicIpfsGateway;
  final String uploadIpfsGateway;
  final String uploadIpfsEndpoint;
  final String uploadIpfsApiKey;

  /// Opt-in upload of header-only packet records to the network map.
  final bool networkMapUploadEnabled;

  /// Whether the one-time network map opt-in dialog has been shown.
  final bool networkMapPromptShown;

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

  String get effectiveUploadIpfsGateway {
    return uploadIpfsGateway.trim();
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
    this.mapTimeFilterHours = 168,
    this.mapKeyPrefixEnabled = false,
    this.mapKeyPrefix = '',
    this.mapShowMarkers = true,
    this.mapShowGuessedLocations = true,
    this.mapClusterNodes = true,
    this.enableMessageTracing = false,
    this.regionOnHopsLine = false,
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
    this.gpsIntervalSeconds = 900,
    this.autoRouteRotationEnabled = true,
    this.maxRouteWeight = defaultMaxRouteWeight,
    this.initialRouteWeight = defaultInitialRouteWeight,
    this.routeWeightSuccessIncrement = defaultRouteWeightSuccessIncrement,
    this.routeWeightFailureDecrement = defaultRouteWeightFailureDecrement,
    this.maxMessageRetries = defaultMaxMessageRetries,
    this.channelMinHopsEnabled = false,
    this.channelMinHops = 2,
    this.channelMinHopsRetries = 1,
    this.channelMinHopsCountRepeaters = false,
    this.themeMode = 'system',
    this.languageOverride,
    this.appDebugLogEnabled = false,
    Map<String, String>? batteryChemistryByDeviceId,
    Map<String, String>? batteryChemistryByRepeaterId,
    this.unitSystem = UnitSystem.metric,
    Map<String, ChannelNotificationMode>? channelNotificationModes,
    this.mapShowDiscoveryContacts = true,
    this.evictDiscoveredContactsEnabled = true,
    this.tcpServerAddress = '',
    this.tcpServerPort = 0,
    this.jumpToOldestUnread = false,
    this.autoFetchRepeaterSettings = false,
    this.networkMapUploadEnabled = false,
    this.networkMapPromptShown = false,
    this.loadLinkImages = true,
    this.showLinkImagesByDefault = false,
    this.publicIpfsGateway = defaultPublicIpfsGateway,
    this.uploadIpfsGateway = '',
    this.uploadIpfsEndpoint = '',
    this.uploadIpfsApiKey = '',
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
       channelNotificationModes = channelNotificationModes ?? {},
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
      'map_cluster_nodes': mapClusterNodes,
      'enable_message_tracing': enableMessageTracing,
      'region_on_hops_line': regionOnHopsLine,
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
      'gps_interval_seconds': gpsIntervalSeconds,
      'auto_route_rotation_enabled': autoRouteRotationEnabled,
      'max_route_weight': maxRouteWeight,
      'initial_route_weight': initialRouteWeight,
      'route_weight_success_increment': routeWeightSuccessIncrement,
      'route_weight_failure_decrement': routeWeightFailureDecrement,
      'max_message_retries': maxMessageRetries,
      'channel_min_hops_enabled': channelMinHopsEnabled,
      'channel_min_hops': channelMinHops,
      'channel_min_hops_retries': channelMinHopsRetries,
      'channel_min_hops_count_repeaters': channelMinHopsCountRepeaters,
      'theme_mode': themeMode,
      'language_override': languageOverride,
      'app_debug_log_enabled': appDebugLogEnabled,
      'battery_chemistry_by_device_id': batteryChemistryByDeviceId,
      'battery_chemistry_by_repeater_id': batteryChemistryByRepeaterId,
      'unit_system': unitSystem.value,
      // Written for older builds that only read the muted set.
      'muted_channels': [
        for (final entry in channelNotificationModes.entries)
          if (entry.value == ChannelNotificationMode.muted) entry.key,
      ],
      'channel_notification_modes': channelNotificationModes.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'map_show_discovery_contacts': mapShowDiscoveryContacts,
      'evict_discovered_contacts_enabled': evictDiscoveredContactsEnabled,
      'tcp_server_address': tcpServerAddress,
      'tcp_server_port': tcpServerPort,
      'jump_to_oldest_unread': jumpToOldestUnread,
      'auto_fetch_repeater_settings': autoFetchRepeaterSettings,
      'network_map_upload_enabled': networkMapUploadEnabled,
      'network_map_prompt_shown': networkMapPromptShown,
      'load_link_images': loadLinkImages,
      'show_link_images_by_default': showLinkImagesByDefault,
      'public_ipfs_gateway': publicIpfsGateway,
      'upload_ipfs_gateway': uploadIpfsGateway,
      'upload_ipfs_endpoint': uploadIpfsEndpoint,
      'upload_ipfs_api_key': uploadIpfsApiKey,
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

    Map<String, ChannelNotificationMode> parseChannelNotificationModes(
      Map<String, dynamic> json,
    ) {
      // Migration from old muted_channels (Set<String>) to new system
      final mutedList = json['muted_channels'] as List?;
      final newModes = json['channel_notification_modes'] as Map?;

      final result = <String, ChannelNotificationMode>{};

      // Migrate old muted channels
      if (mutedList != null) {
        for (final channelName in mutedList) {
          result[channelName.toString()] = ChannelNotificationMode.muted;
        }
      }

      // Load new modes (overrides old muted channels if present)
      if (newModes != null) {
        for (final entry in newModes.entries) {
          final value = entry.value;
          if (value is! String) continue;
          final mode = ChannelNotificationMode.values.asNameMap()[value];
          if (mode != null) result[entry.key.toString()] = mode;
        }
      }

      return result;
    }

    return AppSettings(
      clearPathOnMaxRetry: json['clear_path_on_max_retry'] as bool? ?? false,
      mapShowRepeaters: json['map_show_repeaters'] as bool? ?? true,
      mapShowChatNodes: json['map_show_chat_nodes'] as bool? ?? true,
      mapShowOtherNodes: json['map_show_other_nodes'] as bool? ?? true,
      mapShowOverlaps: json['map_show_overlaps'] as bool? ?? false,
      mapTimeFilterHours:
          (json['map_time_filter_hours'] as num?)?.toDouble() ?? 168,
      mapKeyPrefixEnabled: json['map_key_prefix_enabled'] as bool? ?? false,
      mapKeyPrefix: json['map_key_prefix'] as String? ?? '',
      mapShowMarkers: json['map_show_markers'] as bool? ?? true,
      mapShowGuessedLocations:
          json['map_show_guessed_locations'] as bool? ?? true,
      mapClusterNodes: json['map_cluster_nodes'] as bool? ?? true,
      enableMessageTracing: json['enable_message_tracing'] as bool? ?? false,
      regionOnHopsLine: json['region_on_hops_line'] as bool? ?? false,
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
      gpsIntervalSeconds:
          (json['gps_interval_seconds'] as num?)?.toInt() ?? 900,
      autoRouteRotationEnabled:
          json['auto_route_rotation_enabled'] as bool? ?? true,
      maxRouteWeight:
          (json['max_route_weight'] as num?)?.toDouble() ??
          defaultMaxRouteWeight,
      initialRouteWeight:
          (json['initial_route_weight'] as num?)?.toDouble() ??
          defaultInitialRouteWeight,
      routeWeightSuccessIncrement:
          (json['route_weight_success_increment'] as num?)?.toDouble() ??
          defaultRouteWeightSuccessIncrement,
      routeWeightFailureDecrement:
          (json['route_weight_failure_decrement'] as num?)?.toDouble() ??
          defaultRouteWeightFailureDecrement,
      maxMessageRetries:
          json['max_message_retries'] as int? ?? defaultMaxMessageRetries,
      channelMinHopsEnabled: json['channel_min_hops_enabled'] as bool? ?? false,
      channelMinHops: json['channel_min_hops'] as int? ?? 2,
      channelMinHopsRetries: json['channel_min_hops_retries'] as int? ?? 1,
      channelMinHopsCountRepeaters:
          json['channel_min_hops_count_repeaters'] as bool? ?? false,
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
      channelNotificationModes: parseChannelNotificationModes(json),
      mapShowDiscoveryContacts:
          json['map_show_discovery_contacts'] as bool? ?? true,
      evictDiscoveredContactsEnabled:
          json['evict_discovered_contacts_enabled'] as bool? ?? true,
      tcpServerAddress: json['tcp_server_address'] as String? ?? '',
      tcpServerPort: json['tcp_server_port'] as int? ?? 0,
      jumpToOldestUnread: json['jump_to_oldest_unread'] as bool? ?? false,
      autoFetchRepeaterSettings:
          json['auto_fetch_repeater_settings'] as bool? ?? false,
      networkMapUploadEnabled:
          json['network_map_upload_enabled'] as bool? ?? false,
      networkMapPromptShown: json['network_map_prompt_shown'] as bool? ?? false,
      loadLinkImages: json['load_link_images'] as bool? ?? true,
      showLinkImagesByDefault:
          json['show_link_images_by_default'] as bool? ?? false,
      publicIpfsGateway:
          json['public_ipfs_gateway'] as String? ?? defaultPublicIpfsGateway,
      uploadIpfsGateway: json['upload_ipfs_gateway'] as String? ?? '',
      uploadIpfsEndpoint: json['upload_ipfs_endpoint'] as String? ?? '',
      uploadIpfsApiKey: json['upload_ipfs_api_key'] as String? ?? '',
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
    bool? mapClusterNodes,
    bool? enableMessageTracing,
    bool? regionOnHopsLine,
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
    int? gpsIntervalSeconds,
    bool? autoRouteRotationEnabled,
    double? maxRouteWeight,
    double? initialRouteWeight,
    double? routeWeightSuccessIncrement,
    double? routeWeightFailureDecrement,
    int? maxMessageRetries,
    bool? channelMinHopsEnabled,
    int? channelMinHops,
    int? channelMinHopsRetries,
    bool? channelMinHopsCountRepeaters,
    String? themeMode,
    Object? languageOverride = _unset,
    bool? appDebugLogEnabled,
    Map<String, String>? batteryChemistryByDeviceId,
    Map<String, String>? batteryChemistryByRepeaterId,
    UnitSystem? unitSystem,
    Map<String, ChannelNotificationMode>? channelNotificationModes,
    bool? mapShowDiscoveryContacts,
    bool? evictDiscoveredContactsEnabled,
    String? tcpServerAddress,
    int? tcpServerPort,
    bool? jumpToOldestUnread,
    bool? autoFetchRepeaterSettings,
    bool? networkMapUploadEnabled,
    bool? networkMapPromptShown,
    bool? loadLinkImages,
    bool? showLinkImagesByDefault,
    String? publicIpfsGateway,
    String? uploadIpfsGateway,
    String? uploadIpfsEndpoint,
    String? uploadIpfsApiKey,
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
      mapClusterNodes: mapClusterNodes ?? this.mapClusterNodes,
      enableMessageTracing: enableMessageTracing ?? this.enableMessageTracing,
      regionOnHopsLine: regionOnHopsLine ?? this.regionOnHopsLine,
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
      channelMinHopsEnabled:
          channelMinHopsEnabled ?? this.channelMinHopsEnabled,
      channelMinHops: channelMinHops ?? this.channelMinHops,
      channelMinHopsRetries:
          channelMinHopsRetries ?? this.channelMinHopsRetries,
      channelMinHopsCountRepeaters:
          channelMinHopsCountRepeaters ?? this.channelMinHopsCountRepeaters,
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
      channelNotificationModes:
          channelNotificationModes ?? this.channelNotificationModes,
      mapShowDiscoveryContacts:
          mapShowDiscoveryContacts ?? this.mapShowDiscoveryContacts,
      evictDiscoveredContactsEnabled:
          evictDiscoveredContactsEnabled ?? this.evictDiscoveredContactsEnabled,
      tcpServerAddress: tcpServerAddress ?? this.tcpServerAddress,
      tcpServerPort: tcpServerPort ?? this.tcpServerPort,
      jumpToOldestUnread: jumpToOldestUnread ?? this.jumpToOldestUnread,
      autoFetchRepeaterSettings:
          autoFetchRepeaterSettings ?? this.autoFetchRepeaterSettings,
      networkMapUploadEnabled:
          networkMapUploadEnabled ?? this.networkMapUploadEnabled,
      networkMapPromptShown:
          networkMapPromptShown ?? this.networkMapPromptShown,
      loadLinkImages: loadLinkImages ?? this.loadLinkImages,
      showLinkImagesByDefault:
          showLinkImagesByDefault ?? this.showLinkImagesByDefault,
      publicIpfsGateway: publicIpfsGateway ?? this.publicIpfsGateway,
      uploadIpfsGateway: uploadIpfsGateway ?? this.uploadIpfsGateway,
      uploadIpfsEndpoint: uploadIpfsEndpoint ?? this.uploadIpfsEndpoint,
      uploadIpfsApiKey: uploadIpfsApiKey ?? this.uploadIpfsApiKey,
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
