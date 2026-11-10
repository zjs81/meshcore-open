import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/storage/channel_storage_migration.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/community_store.dart';
import 'package:meshcore_open/storage/contact_discovery_store.dart';
import 'package:meshcore_open/storage/contact_group_store.dart';
import 'package:meshcore_open/storage/contact_settings_store.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/legacy_key_migration.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/storage/unread_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _device = 'aaaaaaaaaa012345';
const _scope = 'aaaaaaaaaa';

class _RecordingPreferences extends InMemorySharedPreferencesStore {
  _RecordingPreferences(Map<String, Object> values)
    : super.withData({
        for (final e in values.entries) 'flutter.${e.key}': e.value,
      });

  final calls = <(String, String)>[];
  final failedKeys = <String>{};
  Completer<void>? writeGate;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    calls.add(('set', key));
    if (failedKeys.contains(key)) return false;
    await writeGate?.future;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    calls.add(('remove', key));
    return super.remove(key);
  }
}

Future<_RecordingPreferences> _init([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues({});
  final platform = _RecordingPreferences(values);
  SharedPreferencesStorePlatform.instance = platform;
  PrefsManager.reset();
  await PrefsManager.initialize();
  return platform;
}

String _cachedChannel(Uint8List psk) => jsonEncode([
  {'index': 0, 'name': 'Public', 'psk': base64Encode(psk), 'unreadCount': 0},
]);

void main() {
  tearDown(() {
    scopesWithoutLegacyMigration.clear();
    PrefsManager.reset();
    SharedPreferences.setMockInitialValues({});
  });

  test('loading absent legacy data performs no platform writes', () async {
    final platform = await _init();
    await (MessageStore()..setPublicKeyHex = _device).loadMessages('c1');
    await (ContactSettingsStore()..setPublicKeyHex = _device).loadSmazEnabled(
      'c1',
    );
    await (ContactStore()..setPublicKeyHex = _device).loadContacts();
    await (ChannelStore()..setPublicKeyHex = _device).loadChannels();
    await (CommunityStore()..setPublicKeyHex = _device).loadCommunities();
    await (ContactGroupStore()..setPublicKeyHex = _device).loadGroups();
    await (UnreadStore()..setPublicKeyHex = _device).loadContactUnreadCount();
    await (ContactDiscoveryStore()..setPublicKeyHex = _device).loadContacts();
    expect(platform.calls, isEmpty);
  });

  test(
    'string migration waits for persistence before deleting the source',
    () async {
      final platform = await _init({'messages_c1': '[]'});
      final gate = Completer<void>();
      platform.writeGate = gate;
      final pending = (MessageStore()..setPublicKeyHex = _device).loadMessages(
        'c1',
      );
      await Future<void>.delayed(Duration.zero);
      expect(platform.calls, [('set', 'flutter.messages_${_scope}c1')]);
      expect((await platform.getAll())['flutter.messages_c1'], '[]');
      gate.complete();
      await pending;
      expect(platform.calls, [
        ('set', 'flutter.messages_${_scope}c1'),
        ('remove', 'flutter.messages_c1'),
      ]);
      await (MessageStore()..setPublicKeyHex = _device).loadMessages('c1');
      expect(platform.calls, hasLength(2));
    },
  );

  test('a failed string migration retains persisted legacy data', () async {
    final platform = await _init({'messages_c1': '[]'});
    platform.failedKeys.add('flutter.messages_${_scope}c1');
    await (MessageStore()..setPublicKeyHex = _device).loadMessages('c1');
    expect(platform.calls, [('set', 'flutter.messages_${_scope}c1')]);
    final persisted = await platform.getAll();
    expect(persisted['flutter.messages_c1'], '[]');
    expect(persisted, isNot(contains('flutter.messages_${_scope}c1')));
  });

  test(
    'false legacy settings migrate, but stay persisted when writing fails',
    () async {
      final platform = await _init({'contact_smaz_c1': false});
      platform.failedKeys.add('flutter.contact_smaz_${_scope}c1');
      expect(
        await (ContactSettingsStore()..setPublicKeyHex = _device)
            .loadSmazEnabled('c1'),
        isFalse,
      );
      expect(platform.calls, [('set', 'flutter.contact_smaz_${_scope}c1')]);
      expect((await platform.getAll())['flutter.contact_smaz_c1'], isFalse);
    },
  );

  test('review scopes never adopt legacy strings or settings', () async {
    final platform = await _init({
      'messages_c1': '[]',
      'contact_smaz_c1': true,
    });
    scopesWithoutLegacyMigration.add(_scope);
    expect(
      await (MessageStore()..setPublicKeyHex = _device).loadMessages('c1'),
      isEmpty,
    );
    expect(
      await (ContactSettingsStore()..setPublicKeyHex = _device).loadSmazEnabled(
        'c1',
      ),
      isFalse,
    );
    expect(platform.calls, isEmpty);
  });

  test('channel migration skips removals of absent old keys', () async {
    final psk = Uint8List.fromList(List.filled(16, 1));
    final platform = await _init({'channels$_scope': _cachedChannel(psk)});
    await ChannelStorageMigration.migrate(_scope);
    expect(platform.calls.where((c) => c.$1 == 'remove'), isEmpty);
    expect(PrefsManager.instance.getBool('channel_storage_v2_$_scope'), isTrue);
  });

  test(
    'channel migration keeps sources and stays unfinished when a write fails',
    () async {
      final psk = Uint8List.fromList(List.filled(16, 1));
      final id = Channel.storageIdForPsk(psk)!;
      final sourceKey = 'channel_messages_${_scope}0';
      final platform = await _init({
        'channels$_scope': _cachedChannel(psk),
        sourceKey: '[]',
      });
      platform.failedKeys.add('flutter.channel_messages_${_scope}_$id');
      await expectLater(
        ChannelStorageMigration.migrate(_scope),
        throwsStateError,
      );
      expect((await platform.getAll())['flutter.$sourceKey'], '[]');
      expect(
        PrefsManager.instance.getBool('channel_storage_v2_$_scope'),
        isNull,
      );
      expect(platform.calls.where((c) => c.$1 == 'remove'), isEmpty);
    },
  );

  test(
    'false legacy settings migrate successfully without extra writes',
    () async {
      final platform = await _init({'contact_smaz_c1': false});
      final store = ContactSettingsStore()..setPublicKeyHex = _device;
      expect(await store.loadSmazEnabled('c1'), isFalse);
      expect(await store.loadSmazEnabled('c1'), isFalse);
      expect(platform.calls, [
        ('set', 'flutter.contact_smaz_${_scope}c1'),
        ('remove', 'flutter.contact_smaz_c1'),
      ]);
      final persisted = await platform.getAll();
      expect(persisted['flutter.contact_smaz_${_scope}c1'], isFalse);
      expect(persisted, isNot(contains('flutter.contact_smaz_c1')));
    },
  );

  test(
    'channel migration is not marked done before its slot map is durable',
    () async {
      final psk = Uint8List.fromList(List.filled(16, 1));
      final platform = await _init({'channels$_scope': _cachedChannel(psk)});
      platform.failedKeys.add('flutter.channel_slot_ids_$_scope');
      await expectLater(
        ChannelStorageMigration.migrate(_scope),
        throwsStateError,
      );
      expect(
        PrefsManager.instance.getBool('channel_storage_v2_$_scope'),
        isNull,
      );
    },
  );
}
