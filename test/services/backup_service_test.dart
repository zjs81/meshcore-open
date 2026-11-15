import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/models/translation_support.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/image_codec_file_store.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/image_codec_settings_store.dart';
import 'package:meshcore_open/services/translation_file_store.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/services/backup_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyTranslationFileStore extends TranslationFileStore {
  @override
  Future<List<TranslationModelRecord>> scanDownloadedModels() async => const [];
}

class _EmptyImageCodecFileStore extends ImageCodecFileStore {
  @override
  Future<List<ImageCodecModelRecord>> scanDownloadedModels() async => const [];
}

class _AppSettingsCodecStore implements ImageCodecSettingsStore {
  _AppSettingsCodecStore(this.service);

  final AppSettingsService service;

  @override
  ImageCodecPreferences get preferences => service.settings.imageCodec;

  @override
  Future<void> load() async {}

  @override
  Future<void> save(ImageCodecPreferences preferences) =>
      service.setImageCodecPreferences(preferences);
}

void main() {
  const payload = <String, Object?>{
    'format': 'meshcore-open-backup',
    'version': 1,
    'sourcePublicKey': '0011223344',
    'items': ['privateKey'],
    'sections': {
      'nodeSettings': {'privateKey': 'private-key-data'},
    },
  };

  group('BackupService creation', () {
    test(
      'expands stored JSON for readability and retains banner preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_settings': jsonEncode({
            'theme_mode': 'dark',
            'map_use_online_map_for_paths': true,
            'upload_ipfs_api_key': 'ipfs-secret',
            'map_tile_api_key': 'stadia-secret',
            'custom_themes': [
              {'name': 'Example'},
            ],
            'path_history_sample': {
              'path_bytes': [1, 16, 255],
            },
          }),
          'node_banner_txt': 'banner text',
          'node_banner_expires_ms': 123,
        });
        PrefsManager.reset();
        await PrefsManager.initialize();
        addTearDown(PrefsManager.reset);
        final connector = MeshCoreConnector();
        addTearDown(connector.dispose);

        final json = await const BackupService().createBackup(
          items: {BackupItem.appSettings},
          connector: connector,
          settings: AppSettings(),
          password: '',
        );
        final payload = jsonDecode(json) as Map<String, dynamic>;
        expect(payload['items'], [BackupItem.appSettings.name]);
        final preferences =
            (payload['sections'] as Map<String, dynamic>)['appSettings']
                as Map<String, dynamic>;
        final values = preferences['preferences'] as Map<String, dynamic>;
        expect(values['app_settings'], isA<Map<String, dynamic>>());
        final appSettings = values['app_settings'] as Map<String, dynamic>;
        expect(appSettings, isNot(contains('upload_ipfs_api_key')));
        expect(appSettings, isNot(contains('map_tile_api_key')));
        expect(appSettings['map_use_online_map_for_paths'], isTrue);
        expect(values['node_banner_txt'], 'banner text');
        expect(values['node_banner_expires_ms'], 123);
        expect(json, contains('"theme_mode": "dark"'));
        expect(json, contains('"path_bytes": [1, 16, 255]'));
        expect(json, isNot(contains('ipfs-secret')));
        expect(json, isNot(contains('stadia-secret')));
        final inspected = await const BackupService().inspectImport(
          contents: json,
          password: '',
        );
        expect(inspected.availableItems, contains(BackupItem.appSettings));
        expect(inspected.availableItems, isNot(contains(BackupItem.ipfsKey)));
        expect(
          inspected.availableItems,
          isNot(contains(BackupItem.stadiaMapKey)),
        );
        final settingsService = AppSettingsService();
        addTearDown(settingsService.dispose);
        await const BackupService().restoreBackup(
          contents: json,
          password: '',
          items: {BackupItem.appSettings},
          connector: connector,
          appSettingsService: settingsService,
        );
        final restored =
            jsonDecode(PrefsManager.instance.getString('app_settings')!)
                as Map<String, dynamic>;
        expect(
          (restored['path_history_sample']
              as Map<String, dynamic>)['path_bytes'],
          [1, 16, 255],
        );
      },
    );

    test('backs up a sensitive key without unrelated app settings', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings': jsonEncode({
          'theme_mode': 'dark',
          'upload_ipfs_api_key': 'ipfs-secret',
          'map_tile_api_key': 'stadia-secret',
        }),
      });
      PrefsManager.reset();
      await PrefsManager.initialize();
      addTearDown(PrefsManager.reset);
      final connector = MeshCoreConnector();
      addTearDown(connector.dispose);

      final json = await const BackupService().createBackup(
        items: {BackupItem.ipfsKey},
        connector: connector,
        settings: AppSettings(),
        password: '',
      );
      final payload = jsonDecode(json) as Map<String, dynamic>;
      expect(payload['items'], [BackupItem.ipfsKey.name]);
      final section =
          (payload['sections'] as Map<String, dynamic>)['appSettings']
              as Map<String, dynamic>;
      final preferences = section['preferences'] as Map<String, dynamic>;
      expect(preferences.keys, {'app_settings'});
      expect(preferences['app_settings'], {
        'upload_ipfs_api_key': 'ipfs-secret',
      });
      expect(json, isNot(contains('stadia-secret')));
    });

    test(
      'restores a selected key without replacing other app preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_settings': jsonEncode({
            'theme_mode': 'light',
            'upload_ipfs_api_key': 'old-ipfs',
            'map_tile_api_key': 'existing-stadia',
          }),
        });
        PrefsManager.reset();
        await PrefsManager.initialize();
        addTearDown(PrefsManager.reset);
        final connector = MeshCoreConnector();
        final settingsService = AppSettingsService();
        addTearDown(connector.dispose);
        addTearDown(settingsService.dispose);

        final backup = await BackupService.encodeBackup({
          'format': 'meshcore-open-backup',
          'version': 1,
          'sourcePublicKey': '',
          'items': [BackupItem.ipfsKey.name],
          'sections': {
            'appSettings': {
              'preferences': {
                'app_settings': {'upload_ipfs_api_key': 'new-ipfs'},
              },
            },
          },
        }, password: '');
        await const BackupService().restoreBackup(
          contents: backup,
          password: '',
          items: {BackupItem.ipfsKey},
          connector: connector,
          appSettingsService: settingsService,
        );

        final restored =
            jsonDecode(PrefsManager.instance.getString('app_settings')!)
                as Map<String, dynamic>;
        expect(restored['theme_mode'], 'light');
        expect(restored['upload_ipfs_api_key'], 'new-ipfs');
        expect(restored['map_tile_api_key'], 'existing-stadia');
      },
    );

    test('applies restored app settings to the live service', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings': jsonEncode({'evict_discovered_contacts_enabled': true}),
      });
      PrefsManager.reset();
      await PrefsManager.initialize();
      addTearDown(PrefsManager.reset);
      final connector = MeshCoreConnector();
      final settingsService = AppSettingsService();
      addTearDown(connector.dispose);
      addTearDown(settingsService.dispose);
      await settingsService.loadSettings();

      final backup = await BackupService.encodeBackup({
        'format': 'meshcore-open-backup',
        'version': 1,
        'sourcePublicKey': '',
        'items': [BackupItem.appSettings.name],
        'sections': {
          'appSettings': {
            'preferences': {
              'app_settings': {'evict_discovered_contacts_enabled': false},
            },
          },
        },
      }, password: '');
      await const BackupService().restoreBackup(
        contents: backup,
        password: '',
        items: {BackupItem.appSettings},
        connector: connector,
        appSettingsService: settingsService,
      );

      expect(settingsService.settings.evictDiscoveredContactsEnabled, isFalse);
    });
  });

  group('UiViewStateService reload', () {
    test('notifies listeners with restored sort preferences', () async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      addTearDown(PrefsManager.reset);
      final viewState = UiViewStateService();
      addTearDown(viewState.dispose);
      await viewState.initialize();
      var notifications = 0;
      viewState.addListener(() => notifications++);

      await PrefsManager.instance.setString('ui_contacts_sort_option', 'name');
      await PrefsManager.instance.setString('ui_channels_sort_option', 'name');
      await viewState.reload();

      expect(viewState.contactsSortOption.name, 'name');
      expect(viewState.channelsSortOption, ChannelSortOption.name);
      expect(notifications, 1);
    });
  });

  group('restored model registry reconciliation', () {
    test(
      'removes model records absent from disk but retains selections',
      () async {
        SharedPreferences.setMockInitialValues({});
        PrefsManager.reset();
        await PrefsManager.initialize();
        addTearDown(PrefsManager.reset);
        final settingsService = AppSettingsService();
        addTearDown(settingsService.dispose);
        final downloadedAt = DateTime(2026);
        await settingsService.updateSettings(
          AppSettings(
            mapUseOnlineMapForPaths: true,
            translationSelectedModelId: 'translation-model',
            translationDownloadedModels: [
              TranslationModelRecord(
                id: 'translation-model',
                name: 'translation.gguf',
                sourceUrl: 'https://example.com/translation.gguf',
                localPath: '/old-device/translation.gguf',
                downloadedAt: downloadedAt,
                fileSizeBytes: 100,
              ),
            ],
            imageCodecSelectedModelId: 'image-model',
            imageCodecDownloadedModels: [
              ImageCodecModelRecord(
                id: 'image-model',
                name: 'image.onnx',
                sourceUrl: 'https://example.com/image.onnx',
                localPath: '/old-device/image.onnx',
                downloadedAt: downloadedAt,
                fileSizeBytes: 100,
              ),
            ],
          ),
        );
        final translationService = TranslationService(
          settingsService,
          fileStore: _EmptyTranslationFileStore(),
        );
        final imageCodecService = ImageCodecService(
          settingsService,
          fileStore: _EmptyImageCodecFileStore(),
          settingsStore: _AppSettingsCodecStore(settingsService),
        );
        addTearDown(translationService.dispose);
        addTearDown(imageCodecService.dispose);

        await translationService.refreshDownloadedModels(clearMissing: true);
        await imageCodecService.refreshDownloadedModels(clearMissing: true);

        expect(settingsService.settings.translationDownloadedModels, isEmpty);
        expect(settingsService.settings.mapUseOnlineMapForPaths, isTrue);
        expect(
          settingsService.settings.translationSelectedModelId,
          'translation-model',
        );
        expect(settingsService.settings.imageCodecDownloadedModels, isEmpty);
        expect(
          settingsService.settings.imageCodecSelectedModelId,
          'image-model',
        );
      },
    );
  });

  group('BackupService import inspection', () {
    test(
      'identifies only the fields present in an official app backup',
      () async {
        final publicKey = List.filled(32, 'a1').join();
        final contactKey = List.filled(32, 'b2').join();
        final privateKey = List.filled(64, 'c3').join();
        final json = jsonEncode({
          'name': 'Test node',
          'public_key': publicKey,
          'private_key': privateKey,
          'radio_settings': {
            'frequency': 869618,
            'bandwidth': 62500,
            'spreading_factor': 8,
            'coding_rate': 8,
            'tx_power': 22,
          },
          'position_settings': {'latitude': '47.5', 'longitude': '7.8'},
          'other_settings': {'advert_location_policy': 0},
          'auto_add_settings': {'auto_add_chat': true},
          'channels': [
            {'name': 'Public', 'secret': List.filled(16, '01').join()},
          ],
          'contacts': [
            {
              'type': 1,
              'name': 'Contact',
              'custom_name': null,
              'public_key': contactKey,
              'flags': 0,
              'latitude': '0.0',
              'longitude': '0.0',
              'last_advert': 1,
              'last_modified': 1,
              'out_path_list': null,
            },
          ],
        }).replaceFirst('"name":"Test node",', '"name":"Test node"');

        final inspected = await const BackupService().inspectImport(
          contents: json,
          password: '',
        );
        expect(inspected.isOfficial, isTrue);
        expect(
          inspected.availableItems,
          containsAll({
            BackupItem.deviceName,
            BackupItem.privateKey,
            BackupItem.publicKey,
            BackupItem.radioSettings,
            BackupItem.location,
            BackupItem.contactSettings,
            BackupItem.privacySettings,
            BackupItem.channels,
            BackupItem.contacts,
          }),
        );
        for (final item in [
          BackupItem.regions,
          BackupItem.appSettings,
          BackupItem.perContactSettings,
          BackupItem.contactGroups,
          BackupItem.contactHistory,
          BackupItem.discoveredContacts,
          BackupItem.bookmarks,
          BackupItem.channelFilters,
          BackupItem.channelSettings,
          BackupItem.communities,
          BackupItem.channelHistory,
        ]) {
          expect(inspected.availableItems, isNot(contains(item)));
        }
      },
    );

    test('reports only selected sections in a MeshCore Open backup', () async {
      final json = await BackupService.encodeBackup({
        ...payload,
        'items': [BackupItem.deviceName.name, BackupItem.channels.name],
      }, password: '');
      final inspected = await const BackupService().inspectImport(
        contents: json,
        password: '',
      );
      expect(inspected.isOfficial, isFalse);
      expect(inspected.availableItems, {
        BackupItem.deviceName,
        BackupItem.channels,
      });
    });
  });

  group('BackupService file encoding', () {
    test('writes readable JSON when the password is empty', () async {
      final file = await BackupService.encodeBackup(payload, password: '');
      expect(jsonDecode(file), payload);
      expect(await BackupService.decodeBackup(file, password: ''), payload);
    });

    test('encrypts and restores payload when a password is provided', () async {
      final file = await BackupService.encodeBackup(
        payload,
        password: 'correct horse battery staple',
      );
      expect(file, contains('meshcore-open-encrypted-backup'));
      expect(file, isNot(contains('private-key-data')));
      expect(
        await BackupService.decodeBackup(
          file,
          password: 'correct horse battery staple',
        ),
        payload,
      );
    });

    test('rejects a wrong password', () async {
      final file = await BackupService.encodeBackup(payload, password: 'right');
      await expectLater(
        BackupService.decodeBackup(file, password: 'wrong'),
        throwsFormatException,
      );
    });
  });

  test(
    'backs up and restores bookmarks separately from discovered contacts',
    () async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      addTearDown(PrefsManager.reset);
      final connector = MeshCoreConnector();
      addTearDown(connector.dispose);
      await connector.connectReview();
      final settingsService = AppSettingsService();
      addTearDown(settingsService.dispose);
      final prefix = connector.selfPublicKeyHex.substring(0, 10);
      final bookmarkKey = 'message_bookmarks_$prefix';
      final discoveredKey = 'discovered_contacts_$prefix';
      final bookmarks = [
        {'messageId': 'saved', 'text': 'saved message'},
      ];
      await PrefsManager.instance.setString(bookmarkKey, jsonEncode(bookmarks));
      await PrefsManager.instance.setString(discoveredKey, 'keep discovered');

      final backup = await const BackupService().createBackup(
        items: {BackupItem.bookmarks},
        connector: connector,
        settings: settingsService.settings,
        password: '',
      );
      final payload = jsonDecode(backup) as Map<String, dynamic>;
      expect(payload['items'], [BackupItem.bookmarks.name]);
      final discoveredSection =
          (payload['sections'] as Map<String, dynamic>)['discoveredContacts']
              as Map<String, dynamic>;
      final preferences =
          discoveredSection['preferences'] as Map<String, dynamic>;
      expect(preferences[bookmarkKey], bookmarks);
      expect(preferences, isNot(contains(discoveredKey)));

      await PrefsManager.instance.setString(bookmarkKey, '[]');
      await const BackupService().restoreBackup(
        contents: backup,
        password: '',
        items: {BackupItem.bookmarks},
        connector: connector,
        appSettingsService: settingsService,
      );
      expect(
        jsonDecode(PrefsManager.instance.getString(bookmarkKey)!),
        bookmarks,
      );
      expect(PrefsManager.instance.getString(discoveredKey), 'keep discovered');
    },
  );
}
