import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'dart:typed_data';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/storage/channel_storage_migration.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/backup_service.dart';
import 'package:meshcore_open/review_mode/review_mode_storage.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/storage/history_store.dart';
import 'package:meshcore_open/storage/legacy_key_migration.dart';
import 'package:meshcore_open/storage/history_store_io.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _DelayedHistoryStore extends PreferencesHistoryStore {
  _DelayedHistoryStore(this.delayedKey, this.gate);
  final String delayedKey;
  final Completer<void> gate;
  @override
  Future<String?> getString(String key) async {
    if (key == delayedKey) await gate.future;
    return super.getString(key);
  }
}

class _FailingCleanupPreferences extends InMemorySharedPreferencesStore {
  _FailingCleanupPreferences() : super.withData({'flutter.messages_a': '[1]'});
  bool fail = true;
  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async =>
      fail ? false : super.clearWithParameters(parameters);
}

class _BackupConnector extends MeshCoreConnector {
  _BackupConnector(this.radioKey);
  final String radioKey;
  @override
  bool get isConnected => true;
  @override
  String get selfPublicKeyHex => radioKey;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SqliteHistoryStore store;

  setUp(() async {
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    store = await SqliteHistoryStore.open(
      inMemoryDatabasePath,
      factory: databaseFactoryFfiNoIsolate,
    );
    HistoryStore.use(store);
  });

  tearDown(() async {
    await store.close();
    PrefsManager.reset();
  });

  test('native history writes leave small preferences untouched', () async {
    await PrefsManager.instance.setString('theme', 'dark');
    await store.setString('messages_a', '[{"text":"hello"}]');
    await store.setString('path_history_a', '{"recentPaths":[]}');
    expect(PrefsManager.instance.getKeys(), {'theme'});
    expect(await store.getString('messages_a'), '[{"text":"hello"}]');
    expect(await store.getString('path_history_a'), '{"recentPaths":[]}');
  });

  test('sequence reads return only the requested ordered page', () async {
    await store.setString(
      'channel_messages_a',
      jsonEncode([
        for (var i = 0; i < 1000; i++) {'id': i},
      ]),
    );
    expect(await store.entryCount('channel_messages_a'), 1000);
    expect(
      await store.readEntries('channel_messages_a', offset: 950, limit: 3),
      ['{"id":950}', '{"id":951}', '{"id":952}'],
    );
    expect(
      await store.readEntries('channel_messages_a', offset: 1000, limit: 3),
      isEmpty,
    );
    expect(await store.readEntries('channel_messages_a', limit: 0), isEmpty);
  });

  test(
    'tail replacement preserves history, deletes and storage limits',
    () async {
      await store.setString('messages_a', '[0,1,2,3,4]');
      expect(
        await store.replaceTail('messages_a', 3, ['4', '5'], maxEntries: 4),
        2,
      );
      expect(await store.readEntries('messages_a'), ['1', '2', '4', '5']);
      expect(await store.replaceTail('messages_a', 2, ['6'], maxEntries: 4), 2);
      expect(await store.readEntries('messages_a'), ['1', '2', '6']);
      expect(
        await store.replaceTail('messages_a', 50, ['7'], maxEntries: 4),
        3,
      );
      expect(await store.readEntries('messages_a'), ['1', '2', '6', '7']);
      expect(await store.replaceTail('messages_a', 0, [], maxEntries: 4), 0);
      expect(await store.getString('messages_a'), '[]');
    },
  );

  test('history data survives database reopen', () async {
    final dir = await Directory.systemTemp.createTemp('meshcore-history-test-');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/history_v1.db';
    final disk = await SqliteHistoryStore.open(
      path,
      factory: databaseFactoryFfiNoIsolate,
    );
    await disk.setString('messages_a', '[1,2,3]');
    await disk.setString('path_history_a', '{"sample":true}');
    await disk.close();
    final reopened = await SqliteHistoryStore.open(
      path,
      factory: databaseFactoryFfiNoIsolate,
    );
    addTearDown(reopened.close);
    expect(await reopened.getString('messages_a'), '[1,2,3]');
    expect(await reopened.getString('path_history_a'), '{"sample":true}');
  });

  test('versioned import removes only committed valid histories', () async {
    final prefs = PrefsManager.instance;
    await prefs.setString('messages_a', '[{"text":"hello"},42]');
    await prefs.setString('path_history_a', '{"recentPaths":[]}');
    await prefs.setString('messages_unreadable', '{broken');
    await prefs.setString('path_history_wrong_shape', '[]');
    await prefs.setBool('notification', true);
    await store.migratePreferences();
    expect(prefs.getKeys(), {
      'messages_unreadable',
      'path_history_wrong_shape',
      'notification',
    });
    expect(await store.readEntries('messages_a'), ['{"text":"hello"}', '42']);
    expect(await store.getString('messages_unreadable'), '{broken');
    expect(
      await store.getKeys(),
      containsAll(['messages_a', 'path_history_a', 'messages_unreadable']),
    );
    final metadata = await store.database.query('history_metadata');
    expect(metadata.single['value'], SqliteHistoryStore.schemaVersion);
    // Current versions skip another scan/import.
    await prefs.setString('messages_added_later', '[1]');
    await store.migratePreferences();
    expect(prefs.containsKey('messages_added_later'), isTrue);
    expect(
      await store.database.query(
        'history_keys',
        where: 'key = ?',
        whereArgs: ['messages_added_later'],
      ),
      isEmpty,
    );
  });

  test(
    'interrupted import does not replace committed newer database values',
    () async {
      await store.setString('messages_a', '[2]');
      await PrefsManager.instance.setString('messages_a', '[1]');
      await store.migratePreferences();
      expect(await store.getString('messages_a'), '[2]');
      expect(PrefsManager.instance.containsKey('messages_a'), isFalse);
    },
  );

  test('histories saved by a run without the database are merged', () async {
    final prefs = PrefsManager.instance;
    await store.migratePreferences();
    await store.setString(
      'messages_a',
      '[{"messageId":"1","text":"old"},{"messageId":"2","text":"sent"}]',
    );
    await store.setString('path_history_a', '{"stored":true}');
    // What the fallback run saved: it started from an empty history.
    await prefs.setString(
      'messages_a',
      '[{"messageId":"2","text":"delivered"},{"messageId":"3","text":"new"}]',
    );
    await prefs.setString('messages_b', '[{"messageId":"4"}]');
    await prefs.setString('path_history_a', '{"stored":false}');
    await prefs.setString('messages_unreadable', '{broken');

    await store.adoptFallbackHistories();

    expect(await store.readEntries('messages_a'), [
      '{"messageId":"1","text":"old"}',
      '{"messageId":"2","text":"delivered"}',
      '{"messageId":"3","text":"new"}',
    ]);
    expect(await store.readEntries('messages_b'), ['{"messageId":"4"}']);
    expect(await store.getString('path_history_a'), '{"stored":true}');
    expect(prefs.getKeys(), {'messages_unreadable'});
  });

  test('initialize falls back to preferences and flags the run', () async {
    // No path provider is registered here, so the database cannot be opened.
    await HistoryStore.initialize();
    addTearDown(HistoryStore.reset);
    expect(HistoryStore.instance, isA<PreferencesHistoryStore>());
    expect(PrefsManager.instance.getBool(HistoryStore.fallbackRunKey), isTrue);
  });

  test('a save lands beside an unreadable preference', () async {
    await PrefsManager.instance.setString('messages_a', '{broken');
    await store.migratePreferences();
    expect(await store.replaceTail('messages_a', 0, ['1', '2']), 0);
    expect(await store.readEntries('messages_a'), ['1', '2']);
    expect(await store.replaceTail('messages_a', 2, ['3']), 2);
    expect(await store.getString('messages_a'), '[1,2,3]');
    expect(PrefsManager.instance.getString('messages_a'), '{broken');
  });

  test('the preferences store replaces an unreadable history', () async {
    final prefs = PreferencesHistoryStore();
    await PrefsManager.instance.setString('messages_a', '{broken');
    expect(await prefs.replaceTail('messages_a', 3, ['1', '2']), 0);
    expect(
      await prefs.replaceTail('messages_a', 2, ['3', '4'], maxEntries: 3),
      1,
    );
    expect(await prefs.getString('messages_a'), '[2,3,4]');
    // A value written behind the store's back is read fresh.
    await PrefsManager.instance.setString('messages_a', '[9]');
    expect(await prefs.readEntries('messages_a'), ['9']);
    expect(await prefs.entryCount('messages_a'), 1);
  });

  test('future import versions are left untouched', () async {
    await store.database.insert('history_metadata', {
      'key': 'preferences_import_version',
      'value': 99,
    });
    await PrefsManager.instance.setString('messages_a', '[1]');
    await store.migratePreferences();
    expect(PrefsManager.instance.containsKey('messages_a'), isTrue);
    expect(
      (await store.database.query('history_metadata')).single['value'],
      99,
    );
  });

  test('review cleanup removes only its database histories', () async {
    final prefix = ReviewRadio.storagePrefix;
    await store.setString('messages_${prefix}c1', '[1]');
    await store.setString('channel_messages_${prefix}_id', '[2]');
    await store.setString('messages_real_c1', '[3]');
    await clearReviewModeData();
    expect(await store.getKeys(), {'messages_real_c1'});
  });

  test(
    'path history scoping and clearing work through database storage',
    () async {
      final a = StorageService()..setPublicKeyHex = 'aaaaaaaaaaaa';
      final b = StorageService()..setPublicKeyHex = 'bbbbbbbbbbbb';
      await store.setString(
        'path_history_c1',
        jsonEncode(
          ContactPathHistory(contactPubKeyHex: 'c1', recentPaths: []).toJson(),
        ),
      );
      expect(await a.loadPathHistory('c1'), isNotNull);
      expect(await b.loadPathHistory('c1'), isNull);
      await b.savePathHistory(
        'c1',
        ContactPathHistory(contactPubKeyHex: 'c1', recentPaths: []),
      );
      await a.clearAllPathHistories();
      expect(await store.getKeys(), {'path_history_bbbbbbbbbb_c1'});
    },
  );
  test(
    'backup exports native histories and restores into the destination scope',
    () async {
      final source = _BackupConnector('a' * 64);
      final destination = _BackupConnector('b' * 64);
      final settings = AppSettingsService();
      addTearDown(source.dispose);
      addTearDown(destination.dispose);
      addTearDown(settings.dispose);
      await store.setString('messages_aaaaaaaaaac1', '[{"text":"original"}]');
      await store.setString(
        'channel_messages_aaaaaaaaaa_0123456789abcdef',
        '[{"text":"channel"}]',
      );
      const service = BackupService();
      final backup = await service.createBackup(
        items: {BackupItem.contactHistory, BackupItem.channelHistory},
        connector: source,
        settings: AppSettings(),
        password: '',
      );
      final decoded = jsonDecode(backup) as Map<String, dynamic>;
      final contacts = decoded['sections']['contacts']['preferences'] as Map;
      expect(contacts['messages_aaaaaaaaaac1'], [
        {'text': 'original'},
      ]);
      await store.setString('messages_bbbbbbbbbbc1', '[{"text":"old"}]');
      await service.restoreBackup(
        contents: backup,
        password: '',
        items: {BackupItem.contactHistory, BackupItem.channelHistory},
        connector: destination,
        appSettingsService: settings,
      );
      expect(
        await store.getString('messages_bbbbbbbbbbc1'),
        '[{"text":"original"}]',
      );
      expect(
        await store.getString('channel_messages_bbbbbbbbbb_0123456789abcdef'),
        '[{"text":"channel"}]',
      );
      expect(
        await store.getString('messages_aaaaaaaaaac1'),
        '[{"text":"original"}]',
      );
      expect(
        PrefsManager.instance.getKeys().where(HistoryStore.isHistoryKey),
        isEmpty,
      );
    },
  );
  test(
    'failed preference cleanup leaves source and import version available for retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      final platform = _FailingCleanupPreferences();
      SharedPreferencesStorePlatform.instance = platform;
      PrefsManager.reset();
      await PrefsManager.initialize();
      HistoryStore.use(store);
      await expectLater(store.migratePreferences(), throwsStateError);
      expect(PrefsManager.instance.getString('messages_a'), '[1]');
      expect(await store.getString('messages_a'), '[1]');
      expect(await store.database.query('history_metadata'), isEmpty);
      platform.fail = false;
      await store.migratePreferences();
      expect(PrefsManager.instance.containsKey('messages_a'), isFalse);
      expect(
        (await store.database.query('history_metadata')).single['value'],
        1,
      );
    },
  );

  test(
    'failed database import preserves original preferences and can retry',
    () async {
      await PrefsManager.instance.setString('messages_a', '[1]');
      await PrefsManager.instance.setString('messages_b', '[2]');
      await store.database.execute(
        "CREATE TRIGGER fail_history BEFORE INSERT ON history_entries WHEN NEW.key = 'messages_b' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        store.migratePreferences(),
        throwsA(isA<DatabaseException>()),
      );
      expect(PrefsManager.instance.getString('messages_a'), '[1]');
      expect(PrefsManager.instance.getString('messages_b'), '[2]');
      expect(await store.database.query('history_metadata'), isEmpty);
      await store.database.execute('DROP TRIGGER fail_history');
      await store.migratePreferences();
      expect(await store.readEntries('messages_a'), ['1']);
      expect(await store.readEntries('messages_b'), ['2']);
      expect(PrefsManager.instance.getKeys(), isEmpty);
    },
  );
  test(
    'channel migration removes old database keys after committing the new ID',
    () async {
      const scope = 'aaaaaaaaaa';
      final channel = Channel(
        index: 0,
        name: 'Public',
        psk: Uint8List.fromList(List.filled(16, 1)),
      );
      await (ChannelStore()..setPublicKeyHex = '${scope}xx').saveChannels([
        channel,
      ]);
      final oldKey = 'channel_messages_${scope}0';
      final newKey = 'channel_messages_${scope}_${channel.storageId}';
      await store.setString(oldKey, '[{"messageId":"legacy","text":"keep"}]');

      await ChannelStorageMigration.migrate(scope);

      expect(await store.getKeys(), {newKey});
      expect(
        await store.getString(newKey),
        '[{"messageId":"legacy","text":"keep"}]',
      );
      expect(
        PrefsManager.instance.getBool('channel_storage_v2_$scope'),
        isTrue,
      );
    },
  );

  test(
    'channel migration leaves malformed sources in place and still completes',
    () async {
      const scope = 'aaaaaaaaaa';
      final psk = Uint8List.fromList(List.filled(16, 1));
      final id = Channel.storageIdForPsk(psk)!;
      await PrefsManager.instance.setString(
        'channels$scope',
        jsonEncode([
          {
            'index': 0,
            'name': 'Public',
            'psk': base64Encode(psk),
            'unreadCount': 0,
          },
        ]),
      );
      await PrefsManager.instance.setString(
        'channel_messages_${scope}0',
        '{broken',
      );
      await store.setString(
        'channel_messages_${scope}_$id',
        '[{"messageId":"existing","text":"keep"}]',
      );
      await ChannelStorageMigration.migrate(scope);
      expect(
        PrefsManager.instance.getString('channel_messages_${scope}0'),
        '{broken',
      );
      expect(
        await store.getString('channel_messages_${scope}_$id'),
        '[{"messageId":"existing","text":"keep"}]',
      );
      expect(
        PrefsManager.instance.getBool('channel_storage_v2_$scope'),
        isTrue,
      );
      // An array that cannot be merged safely is left alone as well.
      await PrefsManager.instance.remove('channel_storage_v2_$scope');
      await PrefsManager.instance.setString(
        'channel_messages_${scope}0',
        '[42]',
      );
      await ChannelStorageMigration.migrate(scope);
      expect(
        PrefsManager.instance.getString('channel_messages_${scope}0'),
        '[42]',
      );
      expect(
        await store.getString('channel_messages_${scope}_$id'),
        '[{"messageId":"existing","text":"keep"}]',
      );
      expect(
        PrefsManager.instance.getBool('channel_storage_v2_$scope'),
        isTrue,
      );
    },
  );
  test(
    'path migration keeps the original scope policy while reading asynchronously',
    () async {
      final reviewScope = ReviewRadio.storagePrefix;
      scopesWithoutLegacyMigration.add(reviewScope);
      addTearDown(() => scopesWithoutLegacyMigration.remove(reviewScope));
      await PrefsManager.instance.setString(
        'path_history_c1',
        jsonEncode(
          ContactPathHistory(contactPubKeyHex: 'c1', recentPaths: []).toJson(),
        ),
      );
      final gate = Completer<void>();
      HistoryStore.use(
        _DelayedHistoryStore('path_history_${reviewScope}_c1', gate),
      );
      final service = StorageService()..setPublicKeyHex = '${reviewScope}xx';
      final pending = service.loadPathHistory('c1');
      service.setPublicKeyHex = 'bbbbbbbbbbbb';
      gate.complete();
      expect(await pending, isNull);
      expect(PrefsManager.instance.containsKey('path_history_c1'), isTrue);
      expect(
        PrefsManager.instance.containsKey('path_history_${reviewScope}_c1'),
        isFalse,
      );
    },
  );
}
