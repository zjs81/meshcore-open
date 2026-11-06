import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/cyr2lat.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/review_mode/review_mode_storage.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/timeout_prediction_service.dart';
import 'package:meshcore_open/storage/channel_region_store.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/contact_discovery_store.dart';
import 'package:meshcore_open/storage/legacy_key_migration.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/storage/region_store.dart';
import 'package:meshcore_open/storage/unread_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _radioA = 'aaaaaaaaaa';
const _radioB = 'bbbbbbbbbb';

Future<void> _init(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  PrefsManager.reset();
  await PrefsManager.initialize();
}

void main() {
  tearDown(() {
    scopesWithoutLegacyMigration.clear();
    TimeoutPredictionService.recordingSuspended = false;
  });

  test(
    'channel store skips a malformed channel instead of dropping all',
    () async {
      await _init({
        'channels$_radioA': jsonEncode([
          {'index': 0, 'name': 'Public'},
          {'index': 'bad', 'name': 'Broken'},
          {'index': 2, 'name': 'Second'},
        ]),
      });
      final store = ChannelStore()..setPublicKeyHex = _radioA;
      final channels = await store.loadChannels();
      expect(channels.map((c) => c.name), ['Public', 'Second']);
    },
  );

  test('unread store keeps valid counts when one is malformed', () async {
    await _init({
      'contact_unread_count$_radioA': jsonEncode({'a': 3, 'b': 'oops', 'c': 1}),
    });
    final store = UnreadStore()..setPublicKeyHex = _radioA;
    expect(await store.loadContactUnreadCount(), {'a': 3, 'c': 1});
  });

  test(
    'discovery store does not migrate legacy data into review scope',
    () async {
      await _init({'discovered_contacts': '[]'});
      final reviewScope = ReviewRadio.storagePrefix;
      scopesWithoutLegacyMigration.add(reviewScope);
      final store = ContactDiscoveryStore()
        ..setPublicKeyHex = '${reviewScope}00';
      expect(await store.loadContacts(), isEmpty);
      expect(PrefsManager.instance.getString('discovered_contacts'), '[]');
      expect(PrefsManager.instance.getKeys(), isNot(contains(store.keyFor)));
    },
  );

  group('path history scoping', () {
    final history = jsonEncode(
      ContactPathHistory(contactPubKeyHex: 'c1', recentPaths: []).toJson(),
    );

    test('clearAllPathHistories only clears the connected radio', () async {
      await _init({
        'path_history_${_radioA}_c1': history,
        'path_history_${_radioB}_c1': history,
        'path_history_c2': history,
      });
      final storage = StorageService()..setPublicKeyHex = '${_radioA}xx';
      await storage.clearAllPathHistories();
      final keys = PrefsManager.instance.getKeys();
      expect(keys, contains('path_history_${_radioB}_c1'));
      expect(keys, isNot(contains('path_history_${_radioA}_c1')));
      expect(keys, isNot(contains('path_history_c2')));
    });

    test('legacy history migrates once into the first radio', () async {
      await _init({'path_history_c1': history});
      final a = StorageService()..setPublicKeyHex = '${_radioA}xx';
      expect(await a.loadPathHistory('c1'), isNotNull);
      final keys = PrefsManager.instance.getKeys();
      expect(keys, contains('path_history_${_radioA}_c1'));
      expect(keys, isNot(contains('path_history_c1')));
      final b = StorageService()..setPublicKeyHex = '${_radioB}xx';
      expect(await b.loadPathHistory('c1'), isNull);
    });

    test('review scope does not adopt legacy history', () async {
      await _init({'path_history_c1': history});
      scopesWithoutLegacyMigration.add(_radioA);
      final a = StorageService()..setPublicKeyHex = '${_radioA}xx';
      expect(await a.loadPathHistory('c1'), isNull);
      expect(PrefsManager.instance.getKeys(), contains('path_history_c1'));
    });
  });

  test('removing a region clears assignments on every radio', () async {
    await _init({
      'regions': ['EU', 'US'],
      'channel_region_${_radioA}1': 'EU',
      'channel_region_${_radioB}3': 'EU',
      'channel_region_${_radioB}4': 'US',
      'default_region_$_radioB': 'EU',
    });
    final store = RegionStore()..setPublicKeyHex = '${_radioA}xx';
    await store.removeRegion('EU');
    final prefs = PrefsManager.instance;
    expect(prefs.getStringList('regions'), ['US']);
    expect(prefs.getString('channel_region_${_radioA}1'), '');
    expect(prefs.getString('channel_region_${_radioB}3'), '');
    expect(prefs.getString('channel_region_${_radioB}4'), 'US');
    expect(prefs.getString('default_region_$_radioB'), '');
    final regionB = ChannelRegionStore()..setPublicKeyHex = '${_radioB}xx';
    expect(regionB.loadDefaultRegion(), '');
  });

  group('review mode session', () {
    test('restores repeater keys and suspends delivery recording', () async {
      await _init({
        'repeater_passwords': jsonEncode({'real': 'secret'}),
      });
      await beginReviewModeSession(null);
      expect(TimeoutPredictionService.recordingSuspended, isTrue);

      final storage = StorageService();
      await storage.saveRepeaterPassword('fake', 'pw');
      await storage.setRepeaterAutoClockSyncAfterLoginEnabled('fake', true);
      final predictor = TimeoutPredictionService.noStorage();
      predictor.recordObservation(
        contactKey: 'fake',
        pathLength: 1,
        messageBytes: 10,
        tripTimeMs: 1500,
      );
      expect(predictor.observationCount, 0);

      await endReviewModeSession(null);
      expect(TimeoutPredictionService.recordingSuspended, isFalse);
      expect(await storage.loadRepeaterPasswords(), {'real': 'secret'});
      expect(
        PrefsManager.instance.containsKey(
          'repeater_auto_clock_sync_after_login',
        ),
        isFalse,
      );
    });

    test('interrupted session snapshot survives a second begin', () async {
      await _init({
        'repeater_passwords': jsonEncode({'real': 'secret'}),
      });
      await beginReviewModeSession(null);
      await StorageService().saveRepeaterPassword('fake', 'pw');
      // App killed, review started again before startup cleanup ran.
      await beginReviewModeSession(null);
      await endReviewModeSession(null);
      expect(await StorageService().loadRepeaterPasswords(), {
        'real': 'secret',
      });
    });
  });

  group('Cyr2Lat sender prefix', () {
    test('only the leading mention is kept untransliterated', () {
      // Uses the default char map (р→p, о→o, с→c).
      expect(Cyr2Lat.encode('@[Bob] рос [x] рос'), '@[Bob] poc [x] poc');
      expect(Cyr2Lat.extractSenderName('@[Bob] рос [x] рос'), '@[Bob] ');
    });
  });
}
