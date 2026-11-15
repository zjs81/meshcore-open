import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../connector/pending_command_replies.dart';
import '../models/app_settings.dart';
import 'app_settings_service.dart';
import '../storage/channel_store.dart';
import '../storage/contact_store.dart';
import '../storage/prefs_manager.dart';
import '../storage/history_store.dart';

const int _backupVersion = 1;
const int _pbkdf2Iterations = 310000;
const String _backupFormat = 'meshcore-open-backup';
const String _encryptedBackupFormat = 'meshcore-open-encrypted-backup';

const List<String> _contactPreferencePrefixes = [
  'contacts',
  'contact_groups',
  'contact_smaz_',
  'contact_cyr2lat_',
  'contact_url_images_',
  'contact_unread_count',
  'messages_',
  'path_history_',
];

const List<String> _channelPreferencePrefixes = [
  'channels',
  'channel_slot_ids_',
  'channel_messages_',
  'channel_order_',
  'channel_smaz_',
  'channel_cyr2lat_',
  'channel_url_images_',
  'channel_region_',
  'default_region_',
  'communities_v1',
  'message_filter_',
];

const List<String> _scopedPreferencePrefixes = [
  ..._contactPreferencePrefixes,
  ..._channelPreferencePrefixes,
  'discovered_contacts',
  'message_bookmarks_',
];

enum BackupSection {
  nodeSettings,
  locationSettings,
  appSettings,
  contacts,
  discoveredContacts,
  channels,
}

enum BackupItem {
  deviceName,
  privateKey,
  publicKey,
  radioSettings,
  regions,
  location,
  contactSettings,
  privacySettings,
  appSettings,
  contacts,
  perContactSettings,
  contactGroups,
  contactHistory,
  discoveredContacts,
  bookmarks,
  channels,
  channelFilters,
  ipfsKey,
  stadiaMapKey,
  channelSettings,
  communities,
  channelHistory,
}

class BackupImportInfo {
  const BackupImportInfo({
    required this.availableItems,
    required this.isOfficial,
  });

  final Set<BackupItem> availableItems;
  final bool isOfficial;
}

class BackupService {
  const BackupService();

  Future<BackupImportInfo> inspectImport({
    required String contents,
    required String password,
  }) async {
    final decoded = _decodeJson(contents);
    final bool isOfficial = _isOfficialBackup(decoded);
    final payload = await _decodeImport(contents, password: password);
    return BackupImportInfo(
      availableItems: _availableItems(payload),
      isOfficial: isOfficial,
    );
  }

  Future<Map<String, dynamic>> _decodeImport(
    String contents, {
    required String password,
  }) async {
    final decoded = _decodeJson(contents);
    if (decoded is Map<String, dynamic> &&
        decoded['format'] == _encryptedBackupFormat) {
      return decodeBackup(contents, password: password);
    }
    if (decoded is Map<String, dynamic> && decoded['format'] == _backupFormat) {
      return _validatePayload(decoded);
    }
    if (_isOfficialBackup(decoded)) {
      return _normalizeOfficialBackup(decoded as Map<String, dynamic>);
    }
    throw const FormatException('Invalid or unsupported backup file');
  }

  Future<String> createBackup({
    required Set<BackupItem> items,
    required MeshCoreConnector connector,
    required AppSettings settings,
    required String password,
  }) async {
    if (items.isEmpty) throw StateError('Select at least one backup item');
    await connector.flushPendingWrites();
    final includedItems = Set<BackupItem>.of(items);
    final customVars = connector.currentCustomVars ?? const <String, String>{};
    if (includedItems.isEmpty) {
      throw StateError('No selected settings are available on this radio');
    }
    final publicKey = connector.selfPublicKeyHex;
    final devicePrefix = _devicePrefix(publicKey);
    if (includedItems.any(_requiresRadioConnection)) {
      _requireConnected(connector);
      if (devicePrefix.isEmpty) {
        throw StateError('Wait for radio identity to finish loading');
      }
    }
    final sections = <String, Object?>{};
    final nodeItems = includedItems
        .where((item) => _sectionForItem(item) == BackupSection.nodeSettings)
        .toSet();
    if (nodeItems.isNotEmpty) {
      final node = <String, Object?>{};
      if (includedItems.contains(BackupItem.deviceName)) {
        node['name'] = connector.selfName;
      }
      if (includedItems.contains(BackupItem.publicKey)) {
        node['publicKey'] = publicKey;
      }
      if (includedItems.contains(BackupItem.privateKey)) {
        node['privateKey'] = base64Encode(await connector.exportPrivateKey());
      }
      if (includedItems.contains(BackupItem.radioSettings)) {
        node['radio'] = {
          'frequencyHz': connector.currentFreqHz,
          'bandwidthHz': connector.currentBwHz,
          'spreadingFactor': connector.currentSf,
          'codingRate': connector.currentCr,
          'clientRepeat': connector.clientRepeat,
          'txPowerDbm': connector.currentTxPower,
          'pathHashByteWidth': connector.pathHashByteWidth,
          'defaultFloodScope': connector.defaultFloodScopeName,
        };
      }
      if (includedItems.contains(BackupItem.regions)) {
        node['preferences'] = await _snapshotPreferences(
          (key) => key == 'regions',
        );
      }
      sections[BackupSection.nodeSettings.name] = node;
    }

    final location = <String, Object?>{};
    if (includedItems.contains(BackupItem.location)) {
      location['location'] = {
        'latitude': connector.selfLatitude,
        'longitude': connector.selfLongitude,
      };
      if (customVars.containsKey('gps')) {
        location['gpsEnabled'] = customVars['gps'] == '1';
        final deviceInterval = int.tryParse(customVars['gps_interval'] ?? '');
        location['gpsIntervalSeconds'] =
            deviceInterval != null && deviceInterval >= 0
            ? deviceInterval
            : settings.gpsIntervalSeconds;
      }
    }
    if (includedItems.contains(BackupItem.contactSettings)) {
      location['contactSettings'] = {
        'autoAddChat': connector.autoAddUsers,
        'autoAddRepeater': connector.autoAddRepeaters,
        'autoAddRoomServer': connector.autoAddRoomServers,
        'autoAddSensor': connector.autoAddSensors,
        'overwriteOldest': connector.autoAddOverwriteOldest,
        'maxHops': connector.autoAddMaxHops,
        'evictDiscoveredContactsEnabled':
            settings.evictDiscoveredContactsEnabled,
      };
    }
    if (includedItems.contains(BackupItem.privacySettings)) {
      final privacySettings = <String, Object?>{
        'telemetryBase': connector.telemetryModeBase,
        'telemetryLocation': connector.telemetryModeLoc,
        'telemetryEnvironment': connector.telemetryModeEnv,
        'advertLocation': connector.advertLocationPolicy,
        'multiAcks': connector.multiAcks,
        'autoSendZeroHopAdvertOnGpsUpdate':
            settings.autoSendZeroHopAdvertOnGpsUpdate,
      };
      final appSettingsJson = settings.toJson();
      if (appSettingsJson.containsKey('auto_send_self_advert_as_flood')) {
        privacySettings['autoSendSelfAdvertAsFlood'] =
            appSettingsJson['auto_send_self_advert_as_flood'];
      }
      location['privacySettings'] = privacySettings;
    }
    if (location.isNotEmpty) {
      sections[BackupSection.locationSettings.name] = location;
    }

    for (final section in BackupSection.values) {
      final sectionItems = includedItems
          .where((item) => _sectionForItem(item) == section)
          .toSet();
      if (sectionItems.isEmpty ||
          section == BackupSection.nodeSettings ||
          section == BackupSection.locationSettings) {
        continue;
      }
      sections[section.name] = {
        'preferences': section == BackupSection.appSettings
            ? await _snapshotAppSettingsPreferences(sectionItems)
            : await _snapshotPreferences(
                (key) =>
                    _preferenceBelongsToItems(key, sectionItems, devicePrefix),
              ),
      };
    }

    final payload = <String, Object?>{
      'format': _backupFormat,
      'version': _backupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'sourcePublicKey': publicKey,
      'items': includedItems.map((item) => item.name).toList(),
      'sections': sections,
    };
    return encodeBackup(payload, password: password);
  }

  Future<void> restoreBackup({
    required String contents,
    required String password,
    required Set<BackupItem> items,
    required MeshCoreConnector connector,
    required AppSettingsService appSettingsService,
  }) async {
    if (items.isEmpty) throw StateError('Select at least one item to restore');
    await connector.flushPendingWrites();
    final payload = await _decodeImport(contents, password: password);
    final sectionData = payload['sections'];
    if (sectionData is! Map) throw const FormatException('Missing backup data');
    final sourcePublicKey = _normalizePublicKey(
      payload['sourcePublicKey'] as String? ?? '',
    );
    final availableItems = _availableItems(payload);
    final selectedItems = items.intersection(availableItems);
    if (selectedItems.isEmpty) {
      throw const FormatException('The backup has none of the selected items');
    }
    for (final section in BackupSection.values) {
      final sectionItems = selectedItems
          .where((item) => _sectionForItem(item) == section)
          .toSet();
      if (sectionItems.isEmpty) continue;
      final data = _sectionData(sectionData, section);
      if (data != null) {
        _validatePreferenceSnapshot(
          data['preferences'],
          section,
          _devicePrefix(sourcePublicKey),
        );
      }
    }
    final node = _sectionData(sectionData, BackupSection.nodeSettings);
    final location = _sectionData(sectionData, BackupSection.locationSettings);
    final importingIdentity = selectedItems.contains(BackupItem.privateKey);
    final destinationPublicKey = importingIdentity
        ? sourcePublicKey
        : _normalizePublicKey(connector.selfPublicKeyHex);
    final restoreContacts = selectedItems.any(
      (item) => _sectionForItem(item) == BackupSection.contacts,
    );
    final restoreChannels = selectedItems.any(
      (item) => _sectionForItem(item) == BackupSection.channels,
    );
    final replaceContacts = selectedItems.contains(BackupItem.contacts);
    final replaceChannels = selectedItems.contains(BackupItem.channels);
    if (importingIdentity &&
        (sourcePublicKey.isEmpty ||
            _normalizePublicKey(node?['publicKey'] as String? ?? '') !=
                sourcePublicKey)) {
      throw const FormatException('Backup radio identity is invalid');
    }
    if (selectedItems.any(_requiresRadioConnection)) {
      _requireConnected(connector);
      if ((restoreContacts || restoreChannels) &&
          destinationPublicKey.length < 10) {
        throw StateError('Wait for radio identity to finish loading');
      }
    }
    if (replaceContacts) await _clearRadioContacts(connector);
    if (replaceChannels) await _clearRadioChannels(connector);

    if (node != null) {
      final name = node['name'];
      if (selectedItems.contains(BackupItem.deviceName) && name is String) {
        await connector.setNodeName(name);
      }
      final radio = _asMap(node['radio']);
      if (selectedItems.contains(BackupItem.radioSettings) && radio != null) {
        final frequencyHz = radio['frequencyHz'];
        final bandwidthHz = radio['bandwidthHz'];
        final spreadingFactor = radio['spreadingFactor'];
        final codingRate = radio['codingRate'];
        if (frequencyHz is int &&
            bandwidthHz is int &&
            spreadingFactor is int &&
            codingRate is int) {
          final accepted = await connector.setRadioParams(
            frequencyHz,
            bandwidthHz,
            spreadingFactor,
            codingRate,
            clientRepeat:
                connector.supportsAllowedRepeatFreq &&
                    radio['clientRepeat'] is bool
                ? radio['clientRepeat'] as bool
                : null,
          );
          if (!accepted) throw StateError('The radio rejected its settings');
        }
        final txPowerDbm = radio['txPowerDbm'];
        if (txPowerDbm is int) {
          await connector.sendFrame(
            buildSetRadioTxPowerFrame(txPowerDbm),
            waitForGenericAck: true,
          );
        }
        final pathHashByteWidth = radio['pathHashByteWidth'];
        if (pathHashByteWidth is int && connector.supportsPathHashMode) {
          await connector.setPathHashMode(pathHashByteWidth - 1);
        }
        final defaultFloodScope = radio['defaultFloodScope'];
        if (defaultFloodScope is String &&
            connector.supportsDefaultFloodScope) {
          await connector.setDefaultFloodScope(defaultFloodScope);
        }
      }
      if (selectedItems.contains(BackupItem.privateKey)) {
        await connector.importPrivateKey(_decodePrivateKey(node['privateKey']));
      }
      if (selectedItems.contains(BackupItem.regions)) {
        await _restorePreferences(
          node['preferences'],
          section: BackupSection.nodeSettings,
          items: selectedItems,
          sourcePublicKey: sourcePublicKey,
          destinationPublicKey: destinationPublicKey,
        );
      }
    }

    if (location != null) {
      final locationData = _asMap(location['location']);
      final latitude = locationData?['latitude'];
      final longitude = locationData?['longitude'];
      if (selectedItems.contains(BackupItem.location)) {
        if (latitude is num && longitude is num) {
          await connector.setNodeLocation(
            lat: latitude.toDouble(),
            lon: longitude.toDouble(),
          );
        }
        final gpsEnabled = location['gpsEnabled'];
        if (gpsEnabled is bool) {
          await connector.setCustomVar(gpsEnabled ? 'gps:1' : 'gps:0');
        }
        final gpsInterval = location['gpsIntervalSeconds'];
        if (gpsInterval is int) {
          if (gpsInterval < 0 || gpsInterval >= 86400) {
            throw const FormatException('Invalid GPS interval in backup');
          }
          await appSettingsService.setGpsIntervalSeconds(
            gpsInterval,
            writeToDevice: (value) =>
                connector.setCustomVar('gps_interval:$value'),
          );
        }
      }
      final contactSettings = _asMap(location['contactSettings']);
      if (selectedItems.contains(BackupItem.contactSettings) &&
          contactSettings != null) {
        if (connector.supportsAutoAddConfig) {
          await connector.sendFrame(
            buildSetAutoAddConfigFrame(
              autoAddChat: contactSettings['autoAddChat'] == true,
              autoAddRepeater: contactSettings['autoAddRepeater'] == true,
              autoAddRoomServer: contactSettings['autoAddRoomServer'] == true,
              autoAddSensor: contactSettings['autoAddSensor'] == true,
              overwriteOldest: contactSettings['overwriteOldest'] == true,
              maxHops: contactSettings['maxHops'] is int
                  ? contactSettings['maxHops'] as int
                  : null,
            ),
            waitForGenericAck: true,
          );
        }
        final evict = contactSettings['evictDiscoveredContactsEnabled'];
        if (evict is bool) {
          await appSettingsService.setEvictDiscoveredContactsEnabled(evict);
        }
      }
      final privacy = _asMap(location['privacySettings']);
      if (selectedItems.contains(BackupItem.privacySettings) &&
          privacy != null) {
        await connector.setTelemetryModeBase(
          _intOr(privacy['telemetryBase'], connector.telemetryModeBase),
          _intOr(privacy['telemetryLocation'], connector.telemetryModeLoc),
          _intOr(privacy['telemetryEnvironment'], connector.telemetryModeEnv),
          _intOr(privacy['advertLocation'], connector.advertLocationPolicy),
          _intOr(privacy['multiAcks'], connector.multiAcks),
        );
        final autoZeroHop = privacy['autoSendZeroHopAdvertOnGpsUpdate'];
        if (autoZeroHop is bool) {
          await appSettingsService.setAutoSendZeroHopAdvertOnGpsUpdate(
            autoZeroHop,
          );
        }
        final autoFlood = privacy['autoSendSelfAdvertAsFlood'];
        final appSettingsJson = appSettingsService.settings.toJson();
        if (autoFlood is bool &&
            appSettingsJson.containsKey('auto_send_self_advert_as_flood')) {
          await appSettingsService.updateSettings(
            AppSettings.fromJson({
              ...appSettingsJson,
              'auto_send_self_advert_as_flood': autoFlood,
            }),
          );
        }
      }
    }

    for (final section in BackupSection.values) {
      final sectionItems = selectedItems
          .where((item) => _sectionForItem(item) == section)
          .toSet();
      if (sectionItems.isEmpty ||
          section == BackupSection.nodeSettings ||
          section == BackupSection.locationSettings) {
        continue;
      }
      final data = _sectionData(sectionData, section);
      if (data != null) {
        await _restorePreferences(
          data['preferences'],
          section: section,
          items: sectionItems,
          sourcePublicKey: sourcePublicKey,
          destinationPublicKey: destinationPublicKey,
        );
      }
    }
    if (selectedItems.contains(BackupItem.appSettings)) {
      await appSettingsService.loadSettings();
    }
    if (selectedItems.contains(BackupItem.channelSettings)) {
      await connector.reloadChannelOrder();
    }
    if (!importingIdentity &&
        selectedItems.contains(BackupItem.discoveredContacts)) {
      await connector.reloadDiscoveredContacts();
    }
    if (replaceContacts) {
      await _restoreRadioContacts(connector, destinationPublicKey);
    }
    if (replaceChannels) {
      await _restoreRadioChannels(connector, destinationPublicKey);
    }
    if (!importingIdentity) {
      if (replaceContacts) await _refreshContactsFromRadio(connector);
      if (replaceChannels) await connector.getChannels(force: true);
    }
  }

  Future<void> _clearRadioContacts(MeshCoreConnector connector) async {
    await _refreshContactsFromRadio(connector);
    for (final contact in connector.contacts.toList()) {
      try {
        await connector.sendFrame(
          buildRemoveContactFrame(contact.publicKey),
          waitForGenericAck: true,
        );
      } on FirmwareCommandException {
        // A contact removed on the radio since its last sync is already clear.
      }
    }
  }

  Future<void> _clearRadioChannels(MeshCoreConnector connector) async {
    await connector.getChannels(force: true);
    for (final channel in connector.channels) {
      if (channel.isEmpty) continue;
      await connector.sendFrame(
        buildSetChannelFrame(channel.index, '', Uint8List(16)),
        waitForGenericAck: true,
      );
    }
  }

  Future<void> _refreshContactsFromRadio(MeshCoreConnector connector) async {
    final refreshed = Completer<void>();
    void checkComplete() {
      if (connector.hasLoadedContacts &&
          !connector.isLoadingContacts &&
          !refreshed.isCompleted) {
        refreshed.complete();
      }
    }

    connector.addListener(checkComplete);
    try {
      await connector.getContacts();
      checkComplete();
      await refreshed.future.timeout(const Duration(seconds: 30));
    } finally {
      connector.removeListener(checkComplete);
    }
  }

  Future<void> _restoreRadioContacts(
    MeshCoreConnector connector,
    String publicKey,
  ) async {
    final store = ContactStore()..setPublicKeyHex = publicKey;
    final contacts = await store.loadContacts();
    for (final contact in contacts) {
      if (contact.publicKeyHex.toUpperCase() == publicKey.toUpperCase()) {
        continue;
      }
      final pathLength = contact.pathLength < 0
          ? 0xff
          : (contact.pathLength & 0x3f) |
                (((contact.pathHashWidth - 1) & 0x03) << 6);
      await connector.sendFrame(
        buildUpdateContactPathFrame(
          contact.publicKey,
          contact.path,
          pathLength,
          type: contact.type,
          flags: contact.flags,
          name: contact.name,
          lat: contact.latitude,
          lon: contact.longitude,
          lastAdvert: contact.lastSeen,
          lastModified: contact.lastModified,
        ),
        waitForGenericAck: true,
      );
    }
  }

  Future<void> _restoreRadioChannels(
    MeshCoreConnector connector,
    String publicKey,
  ) async {
    final store = ChannelStore()..setPublicKeyHex = publicKey;
    final channels = await store.loadChannels();
    for (final channel in channels) {
      await connector.sendFrame(
        buildSetChannelFrame(channel.index, channel.name, channel.psk),
        waitForGenericAck: true,
      );
    }
  }

  static String _encodePrettyBackup(Object payload) {
    final pretty = const JsonEncoder.withIndent('  ').convert(payload);
    return pretty.replaceAllMapped(
      RegExp(r'("path_bytes"\s*:\s*)\[\s*([0-9,\s]*?)\s*\]'),
      (match) {
        final values = match[2]!
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty);
        return '${match[1]}[${values.join(', ')}]';
      },
    );
  }

  static Future<String> encodeBackup(
    Map<String, Object?> payload, {
    required String password,
  }) async {
    final plainText = jsonEncode(payload);
    if (password.isEmpty) {
      return _encodePrettyBackup(payload);
    }

    final salt = _secureBytes(16);
    final nonce = _secureBytes(12);
    final key = await _deriveKey(password, salt, _pbkdf2Iterations);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    return const JsonEncoder.withIndent('  ').convert({
      'format': _encryptedBackupFormat,
      'version': _backupVersion,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': _pbkdf2Iterations,
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    });
  }

  static Future<Map<String, dynamic>> decodeBackup(
    String contents, {
    required String password,
  }) async {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file');
    }
    if (decoded['format'] == _encryptedBackupFormat) {
      if (password.isEmpty) throw const FormatException('Password required');
      if (decoded['version'] != _backupVersion ||
          decoded['kdf'] != 'PBKDF2-HMAC-SHA256' ||
          decoded['cipher'] != 'AES-256-GCM') {
        throw const FormatException('Unsupported encrypted backup format');
      }
      final iterations = decoded['iterations'];
      if (iterations is! int || iterations < 100000 || iterations > 1000000) {
        throw const FormatException('Invalid password derivation settings');
      }
      try {
        final salt = base64Decode(decoded['salt'] as String);
        final nonce = base64Decode(decoded['nonce'] as String);
        final ciphertext = base64Decode(decoded['ciphertext'] as String);
        final tag = base64Decode(decoded['tag'] as String);
        if (salt.length != 16 || nonce.length != 12 || tag.length != 16) {
          throw const FormatException('Invalid encrypted backup');
        }
        final key = await _deriveKey(password, salt, iterations);
        final plaintext = await AesGcm.with256bits().decrypt(
          SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
          secretKey: key,
        );
        return _validatePayload(jsonDecode(utf8.decode(plaintext)));
      } on FormatException {
        rethrow;
      } catch (_) {
        throw const FormatException('Wrong password or damaged backup');
      }
    }
    return _validatePayload(decoded);
  }

  static Object? _decodeJson(String contents) {
    try {
      return jsonDecode(contents);
    } on FormatException {
      final repaired = contents.replaceFirstMapped(
        RegExp(r'("name"\s*:\s*"(?:\\.|[^"\\])*"\s*)(?=\s*"public_key"\s*:)'),
        (match) => '${match[1]},',
      );
      if (repaired == contents) rethrow;
      return jsonDecode(repaired);
    }
  }

  static bool _isOfficialBackup(Object? value) =>
      value is Map<String, dynamic> &&
      value.containsKey('public_key') &&
      (value.containsKey('private_key') ||
          value.containsKey('radio_settings') ||
          value.containsKey('channels') ||
          value.containsKey('contacts'));

  static Set<BackupItem> _availableItems(Map<String, dynamic> payload) {
    final rawItems = payload['items'];
    if (rawItems is! List) return {};
    final available = <BackupItem>{};
    for (final name in rawItems.whereType<String>()) {
      for (final item in BackupItem.values) {
        if (item.name == name) available.add(item);
      }
    }
    return available;
  }

  static Map<String, dynamic> _normalizeOfficialBackup(
    Map<String, dynamic> source,
  ) {
    final publicKey = _normalizePublicKey(
      source['public_key'] as String? ?? '',
    );
    if (publicKey.isEmpty) throw const FormatException('Invalid public key');
    final devicePrefix = _devicePrefix(publicKey);
    final sections = <String, Object?>{};
    final items = <BackupItem>{};

    final node = <String, Object?>{};
    if (source['name'] is String) {
      node['name'] = source['name'];
      items.add(BackupItem.deviceName);
    }
    node['publicKey'] = publicKey;
    items.add(BackupItem.publicKey);
    final privateKey = _decodeHex(source['private_key'], length: 64);
    if (privateKey != null) {
      node['privateKey'] = base64Encode(privateKey);
      items.add(BackupItem.privateKey);
    }
    final sourceRadio = _asMap(source['radio_settings']);
    if (sourceRadio != null) {
      final radio = <String, Object?>{};
      final frequency = _asNumber(sourceRadio['frequency']);
      final bandwidth = _asNumber(sourceRadio['bandwidth']);
      final spreadingFactor = _asNumber(sourceRadio['spreading_factor']);
      final codingRate = _asNumber(sourceRadio['coding_rate']);
      final txPower = _asNumber(sourceRadio['tx_power']);
      if (frequency != null) {
        radio['frequencyHz'] = frequency < 10000000
            ? frequency * 1000
            : frequency;
      }
      if (bandwidth != null) radio['bandwidthHz'] = bandwidth;
      if (spreadingFactor != null) radio['spreadingFactor'] = spreadingFactor;
      if (codingRate != null) radio['codingRate'] = codingRate;
      if (txPower != null) radio['txPowerDbm'] = txPower;
      if (radio.isNotEmpty) {
        node['radio'] = radio;
        items.add(BackupItem.radioSettings);
      }
    }
    if (node.isNotEmpty) sections[BackupSection.nodeSettings.name] = node;

    final position = _asMap(source['position_settings']);
    if (position != null) {
      final latitude = _asDouble(position['latitude']);
      final longitude = _asDouble(position['longitude']);
      if (latitude != null && longitude != null) {
        sections[BackupSection.locationSettings.name] = <String, Object?>{
          'location': <String, Object?>{
            'latitude': latitude,
            'longitude': longitude,
          },
        };
        items.add(BackupItem.location);
      }
    }
    final autoAdd = _asMap(source['auto_add_settings']);
    if (autoAdd != null && autoAdd.isNotEmpty) {
      final location =
          _asMap(sections[BackupSection.locationSettings.name]) ?? {};
      location['contactSettings'] = {
        'autoAddChat': autoAdd['auto_add_chat'],
        'autoAddRepeater': autoAdd['auto_add_repeater'],
        'autoAddRoomServer': autoAdd['auto_add_room_server'],
        'autoAddSensor': autoAdd['auto_add_sensor'],
        'overwriteOldest': autoAdd['overwrite_oldest'],
        'maxHops': _asNumber(autoAdd['auto_add_max_hops']),
      };
      sections[BackupSection.locationSettings.name] = location;
      items.add(BackupItem.contactSettings);
    }
    final other = _asMap(source['other_settings']);
    if (other?.containsKey('advert_location_policy') ?? false) {
      final location =
          _asMap(sections[BackupSection.locationSettings.name]) ?? {};
      location['privacySettings'] = {
        'advertLocation': _asNumber(other!['advert_location_policy']),
      };
      sections[BackupSection.locationSettings.name] = location;
      items.add(BackupItem.privacySettings);
    }

    final channels = source['channels'];
    if (channels is List) {
      final stored = <Map<String, Object?>>[];
      for (var i = 0; i < channels.length; i++) {
        final entry = _asMap(channels[i]);
        if (entry == null || entry['name'] is! String) continue;
        final psk = _decodeHex(entry['secret'], length: 16);
        if (psk == null) continue;
        stored.add({
          'index': i,
          'name': entry['name'],
          'psk': base64Encode(psk),
          'unreadCount': 0,
        });
      }
      sections[BackupSection.channels.name] = {
        'preferences': {'channels$devicePrefix': jsonEncode(stored)},
      };
      items.add(BackupItem.channels);
    }

    final contacts = source['contacts'];
    if (contacts is List) {
      final stored = <Map<String, Object?>>[];
      for (final entry in contacts) {
        final contact = _asMap(entry);
        if (contact == null) continue;
        final key = _decodeHex(contact['public_key'], length: 32);
        if (key == null) continue;
        final path = _parseOfficialPath(contact['out_path_list']);
        final advertSeconds = _asNumber(contact['last_advert']) ?? 0;
        final modifiedSeconds = _asNumber(contact['last_modified']);
        final latitude = _asDouble(contact['latitude']);
        final longitude = _asDouble(contact['longitude']);
        final name =
            contact['custom_name'] is String &&
                (contact['custom_name'] as String).isNotEmpty
            ? contact['custom_name'] as String
            : contact['name'] as String? ?? '';
        stored.add({
          'publicKey': base64Encode(key),
          'name': name,
          'type': _asNumber(contact['type']) ?? 0,
          'flags': _asNumber(contact['flags']) ?? 0,
          'pathLength': path.$2,
          'path': base64Encode(path.$1),
          'pathHashWidth': path.$1.isEmpty ? 1 : 2,
          'pathOverride': null,
          'pathOverrideBytes': null,
          'latitude': latitude,
          'longitude': longitude,
          'lastSeen': advertSeconds * 1000,
          'lastModified': modifiedSeconds == null
              ? null
              : modifiedSeconds * 1000,
          'lastMessageAt': advertSeconds * 1000,
          'isActive': true,
          'rawPacket': null,
          'telemetryFixAt': null,
        });
      }
      sections[BackupSection.contacts.name] = {
        'preferences': {'contacts$devicePrefix': jsonEncode(stored)},
      };
      items.add(BackupItem.contacts);
    }

    return {
      'format': _backupFormat,
      'version': _backupVersion,
      'sourcePublicKey': publicKey,
      'items': items.map((item) => item.name).toList(),
      'sections': sections,
    };
  }

  static Uint8List? _decodeHex(Object? value, {required int length}) {
    if (value is! String ||
        value.length != length * 2 ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(value)) {
      return null;
    }
    return Uint8List.fromList([
      for (var i = 0; i < value.length; i += 2)
        int.parse(value.substring(i, i + 2), radix: 16),
    ]);
  }

  static (Uint8List, int) _parseOfficialPath(Object? value) {
    if (value == null) return (Uint8List(0), -1);
    if (value is! String || value.isEmpty) return (Uint8List(0), 0);
    final bytes = <int>[];
    for (final part in value.split(',')) {
      final hash = _decodeHex(part, length: 2);
      if (hash == null) return (Uint8List(0), -1);
      bytes.addAll(hash);
    }
    return (Uint8List.fromList(bytes), bytes.length ~/ 2);
  }

  static int? _asNumber(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, dynamic> _validatePayload(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['format'] != _backupFormat ||
        value['version'] != _backupVersion ||
        value['sections'] is! Map ||
        value['items'] is! List ||
        !(value['items'] as List).every((item) => item is String)) {
      throw const FormatException('Invalid or unsupported backup file');
    }
    return value;
  }

  static void _requireConnected(MeshCoreConnector connector) {
    if (!connector.isConnected) {
      throw StateError(
        'Connect to the radio to back up or restore its settings',
      );
    }
  }

  static Uint8List _decodePrivateKey(Object? value) {
    if (value is! String) {
      throw const FormatException('Backup has no private key');
    }
    final bytes = Uint8List.fromList(base64Decode(value));
    if (bytes.length != 64) throw const FormatException('Invalid private key');
    return bytes;
  }

  static Map<String, dynamic>? _sectionData(
    Map sectionData,
    BackupSection section,
  ) => _asMap(sectionData[section.name]);

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  static Map<String, dynamic>? _asJsonMapPreference(Object? value) {
    final map = _asMap(value);
    if (map != null || value is! String) return map;
    try {
      return _asMap(jsonDecode(value));
    } on FormatException {
      return null;
    }
  }

  static int _intOr(Object? value, int fallback) =>
      value is int ? value : fallback;

  static Future<Map<String, Object?>> _snapshotPreferences(
    bool Function(String) include,
  ) async {
    final prefs = PrefsManager.instance;
    final values = <String, Object?>{};
    for (final key in {
      ...prefs.getKeys(),
      ...await HistoryStore.instance.getKeys(),
    }) {
      if (!include(key)) continue;
      final value = HistoryStore.isHistoryKey(key)
          ? await HistoryStore.instance.getString(key)
          : prefs.get(key);
      if (value is String) {
        values[key] = _expandJsonPreference(value);
      } else if (value is bool || value is int || value is double) {
        values[key] = value;
      } else if (value is List<String>) {
        values[key] = value;
      }
    }
    return values;
  }

  static Object _expandJsonPreference(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map ||
          (decoded is List &&
              decoded.isNotEmpty &&
              decoded.any((item) => item is! String))) {
        return _formatBackupJsonValue(decoded)!;
      }
    } on FormatException {
      return value;
    }
    return value;
  }

  static Object? _formatBackupJsonValue(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _formatBackupJsonValue(entry.value),
      };
    }
    if (value is List) {
      return value.map(_formatBackupJsonValue).toList();
    }
    return value;
  }

  static Future<Map<String, Object?>> _snapshotAppSettingsPreferences(
    Set<BackupItem> items,
  ) async {
    final values = await _snapshotPreferences(
      (key) => _preferenceBelongsToItems(key, items, ''),
    );
    final appSettings = _asMap(values['app_settings']);
    if (values.containsKey('app_settings') && appSettings == null) {
      throw StateError('Cannot safely filter sensitive app settings');
    }
    if (appSettings == null) return values;

    final includesAllSettings = items.contains(BackupItem.appSettings);
    appSettings.removeWhere((key, _) {
      if (key == 'upload_ipfs_api_key') {
        return !items.contains(BackupItem.ipfsKey);
      }
      if (key == 'map_tile_api_key') {
        return !items.contains(BackupItem.stadiaMapKey);
      }
      return !includesAllSettings;
    });
    values['app_settings'] = appSettings;
    return values;
  }

  static BackupSection _sectionForItem(BackupItem item) => switch (item) {
    BackupItem.deviceName ||
    BackupItem.privateKey ||
    BackupItem.publicKey ||
    BackupItem.radioSettings ||
    BackupItem.regions => BackupSection.nodeSettings,
    BackupItem.location ||
    BackupItem.contactSettings ||
    BackupItem.privacySettings => BackupSection.locationSettings,
    BackupItem.appSettings ||
    BackupItem.ipfsKey ||
    BackupItem.stadiaMapKey => BackupSection.appSettings,
    BackupItem.contacts ||
    BackupItem.perContactSettings ||
    BackupItem.contactGroups ||
    BackupItem.contactHistory => BackupSection.contacts,
    BackupItem.discoveredContacts ||
    BackupItem.bookmarks => BackupSection.discoveredContacts,
    BackupItem.channels ||
    BackupItem.channelFilters ||
    BackupItem.channelSettings ||
    BackupItem.communities ||
    BackupItem.channelHistory => BackupSection.channels,
  };

  static bool _requiresRadioConnection(BackupItem item) =>
      _sectionForItem(item) != BackupSection.appSettings &&
      item != BackupItem.channelFilters;

  static bool _preferenceBelongsToItems(
    String key,
    Set<BackupItem> items,
    String devicePrefix,
  ) {
    if (items.contains(BackupItem.regions) && key == 'regions') return true;
    if (key == 'app_settings' &&
        (items.contains(BackupItem.appSettings) ||
            items.contains(BackupItem.ipfsKey) ||
            items.contains(BackupItem.stadiaMapKey))) {
      return true;
    }
    if (items.contains(BackupItem.appSettings) &&
        key != 'app_settings' &&
        _preferenceBelongsToSection(key, BackupSection.appSettings)) {
      return true;
    }
    if (items.contains(BackupItem.contacts) &&
        key.startsWith('contacts$devicePrefix')) {
      return true;
    }
    if (items.contains(BackupItem.perContactSettings) &&
        (key.startsWith('contact_smaz_$devicePrefix') ||
            key.startsWith('contact_cyr2lat_$devicePrefix') ||
            key.startsWith('contact_url_images_$devicePrefix'))) {
      return true;
    }
    if (items.contains(BackupItem.contactGroups) &&
        key.startsWith('contact_groups$devicePrefix')) {
      return true;
    }
    if (items.contains(BackupItem.contactHistory) &&
        (key.startsWith('messages_$devicePrefix') ||
            key.startsWith('path_history_$devicePrefix') ||
            key.startsWith('contact_unread_count$devicePrefix'))) {
      return true;
    }
    if (items.contains(BackupItem.discoveredContacts) &&
        key.startsWith('discovered_contacts$devicePrefix')) {
      return true;
    }
    if (items.contains(BackupItem.bookmarks) &&
        key.startsWith('message_bookmarks_$devicePrefix')) {
      return true;
    }
    if (items.contains(BackupItem.channels) &&
        (key.startsWith('channels$devicePrefix') ||
            key.startsWith('channel_slot_ids_$devicePrefix'))) {
      return true;
    }
    if (items.contains(BackupItem.channelFilters) &&
        key.startsWith('message_filter_')) {
      return true;
    }
    if (items.contains(BackupItem.channelSettings) &&
        (key.startsWith('channel_smaz_$devicePrefix') ||
            key.startsWith('channel_cyr2lat_$devicePrefix') ||
            key.startsWith('channel_url_images_$devicePrefix') ||
            key.startsWith('channel_region_$devicePrefix') ||
            key.startsWith('default_region_$devicePrefix') ||
            key.startsWith('channel_order_$devicePrefix'))) {
      return true;
    }
    if (items.contains(BackupItem.communities) &&
        key.startsWith('communities_v1$devicePrefix')) {
      return true;
    }
    if (items.contains(BackupItem.channelHistory) &&
        key.startsWith('channel_messages_$devicePrefix')) {
      return true;
    }
    return false;
  }

  static bool _preferenceBelongsToSection(
    String key,
    BackupSection section, {
    String devicePrefix = '',
  }) {
    switch (section) {
      case BackupSection.nodeSettings:
        return key == 'regions';
      case BackupSection.locationSettings:
        return false;
      case BackupSection.contacts:
        return _startsWithScopedPrefix(
          key,
          _contactPreferencePrefixes,
          devicePrefix,
        );
      case BackupSection.discoveredContacts:
        return _startsWithScopedPrefix(key, const [
          'discovered_contacts',
          'message_bookmarks_',
        ], devicePrefix);
      case BackupSection.channels:
        return key.startsWith('message_filter_') ||
            _startsWithScopedPrefix(
              key,
              _channelPreferencePrefixes,
              devicePrefix,
            );
      case BackupSection.appSettings:
        return !key.startsWith('flutter.') &&
            key != 'regions' &&
            !_startsWithAny(key, _scopedPreferencePrefixes);
    }
  }

  static bool _startsWithScopedPrefix(
    String key,
    List<String> prefixes,
    String devicePrefix,
  ) =>
      devicePrefix.isNotEmpty &&
      prefixes.any((prefix) => key.startsWith('$prefix$devicePrefix'));

  static bool _startsWithAny(String value, List<String> prefixes) =>
      prefixes.any(value.startsWith);

  static bool _isSupportedPreferenceValue(Object? value) =>
      value is String ||
      value is bool ||
      value is int ||
      value is double ||
      value is Map ||
      value is List;

  static void _validatePreferenceSnapshot(
    Object? rawValues,
    BackupSection section,
    String devicePrefix,
  ) {
    if (rawValues == null) return;
    final values = _asMap(rawValues);
    if (values == null) {
      throw const FormatException('Invalid backup preferences');
    }
    for (final entry in values.entries) {
      if (!_preferenceBelongsToSection(
        entry.key,
        section,
        devicePrefix: devicePrefix,
      )) {
        throw FormatException('Backup preference is outside ${section.name}');
      }
      if (!_isSupportedPreferenceValue(entry.value)) {
        throw FormatException('Invalid preference value for ${entry.key}');
      }
    }
  }

  static Future<void> _restorePreferences(
    Object? rawValues, {
    required BackupSection section,
    required Set<BackupItem> items,
    required String sourcePublicKey,
    required String destinationPublicKey,
  }) async {
    _validatePreferenceSnapshot(
      rawValues,
      section,
      _devicePrefix(sourcePublicKey),
    );
    final values = _asMap(rawValues);
    if (values == null) return;
    final prefs = PrefsManager.instance;
    final sourcePrefix = _devicePrefix(sourcePublicKey);
    final destinationPrefix = _devicePrefix(destinationPublicKey);
    final existingAppSettings = _asJsonMapPreference(
      prefs.getString('app_settings'),
    );
    final matching =
        {...prefs.getKeys(), ...await HistoryStore.instance.getKeys()}.where((
          key,
        ) {
          if (section == BackupSection.appSettings &&
              key == 'app_settings' &&
              !items.contains(BackupItem.appSettings)) {
            return false;
          }
          if (!_preferenceBelongsToSection(
                key,
                section,
                devicePrefix: destinationPrefix,
              ) ||
              !_preferenceBelongsToItems(key, items, destinationPrefix)) {
            return false;
          }
          if (section == BackupSection.appSettings ||
              section == BackupSection.nodeSettings) {
            return true;
          }
          return _hasDevicePrefix(key, section, destinationPrefix) ||
              (section == BackupSection.channels &&
                  key.startsWith('message_filter_'));
        }).toList();
    for (final key in matching) {
      if (HistoryStore.isHistoryKey(key)) {
        await HistoryStore.instance.remove(key);
      } else {
        await prefs.remove(key);
      }
    }
    for (final entry in values.entries) {
      if (!_preferenceBelongsToItems(entry.key, items, sourcePrefix)) {
        continue;
      }
      final key = _remapKey(
        entry.key,
        section,
        sourcePrefix,
        destinationPrefix,
      );
      final value = entry.value;
      if (HistoryStore.isHistoryKey(key)) {
        await HistoryStore.instance.setString(
          key,
          value is String ? value : jsonEncode(value),
        );
      } else if (section == BackupSection.appSettings &&
          key == 'app_settings') {
        final storedIncoming = _asJsonMapPreference(value);
        if (storedIncoming == null) {
          throw const FormatException('Invalid app settings in backup');
        }
        final incoming = Map<String, dynamic>.from(storedIncoming);
        final merged = _mergeSensitiveAppSettings(
          existing: existingAppSettings,
          incoming: incoming,
          items: items,
        );
        await prefs.setString(key, jsonEncode(merged));
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is Map ||
          (value is List && value.any((item) => item is! String))) {
        await prefs.setString(key, jsonEncode(value));
      } else if (value is List && value.every((item) => item is String)) {
        await prefs.setStringList(key, value.cast<String>());
      } else {
        throw FormatException('Invalid preference value for $key');
      }
    }
  }

  static Map<String, dynamic> _mergeSensitiveAppSettings({
    required Map<String, dynamic>? existing,
    required Map<String, dynamic> incoming,
    required Set<BackupItem> items,
  }) {
    final includesAll = items.contains(BackupItem.appSettings);
    final result = Map<String, dynamic>.from(
      includesAll ? incoming : (existing ?? const <String, dynamic>{}),
    );
    const sensitiveKeys = {
      BackupItem.ipfsKey: 'upload_ipfs_api_key',
      BackupItem.stadiaMapKey: 'map_tile_api_key',
    };
    for (final entry in sensitiveKeys.entries) {
      if (items.contains(entry.key)) {
        if (incoming.containsKey(entry.value)) {
          result[entry.value] = incoming[entry.value];
        }
      } else if (includesAll && existing?.containsKey(entry.value) == true) {
        result[entry.value] = existing![entry.value];
      }
    }
    return result;
  }

  static String _remapKey(
    String key,
    BackupSection section,
    String sourcePrefix,
    String destinationPrefix,
  ) {
    if (sourcePrefix.isEmpty || destinationPrefix.isEmpty) return key;
    final prefixes = switch (section) {
      BackupSection.contacts => _contactPreferencePrefixes,
      BackupSection.discoveredContacts => const [
        'discovered_contacts',
        'message_bookmarks_',
      ],
      BackupSection.channels => _channelPreferencePrefixes,
      _ => const <String>[],
    };
    for (final prefix in prefixes) {
      final scopedPrefix = '$prefix$sourcePrefix';
      if (key.startsWith(scopedPrefix)) {
        return '$prefix$destinationPrefix${key.substring(scopedPrefix.length)}';
      }
    }
    return key;
  }

  static bool _hasDevicePrefix(
    String key,
    BackupSection section,
    String devicePrefix,
  ) {
    if (section == BackupSection.channels &&
        key.startsWith('message_filter_')) {
      return true;
    }
    if (devicePrefix.isEmpty) return false;
    final prefixes = switch (section) {
      BackupSection.contacts => _contactPreferencePrefixes,
      BackupSection.discoveredContacts => const [
        'discovered_contacts',
        'message_bookmarks_',
      ],
      BackupSection.channels => _channelPreferencePrefixes,
      _ => const <String>[],
    };
    return prefixes.any((prefix) => key.startsWith('$prefix$devicePrefix'));
  }

  static String _normalizePublicKey(String publicKey) =>
      RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(publicKey)
      ? publicKey.toLowerCase()
      : '';

  static String _devicePrefix(String publicKey) {
    final normalized = _normalizePublicKey(publicKey);
    return normalized.isEmpty ? '' : normalized.substring(0, 10);
  }

  static Uint8List _secureBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) => Pbkdf2.hmacSha256(
    iterations: iterations,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
}
