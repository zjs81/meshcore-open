import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/contact_discovery_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<int> _key(int seed) => List<int>.generate(32, (i) => (seed + i) & 0xFF);

Map<String, dynamic> _entry(
  int seed, {
  List<int>? key,
  int lastSeen = 1000,
  Map<String, dynamic> extra = const {},
}) => {
  'publicKey': base64Encode(key ?? _key(seed)),
  'name': 'Node $seed',
  'type': advTypeRepeater,
  'lastSeen': lastSeen,
  ...extra,
};

Contact _existing(int seed) => Contact(
  publicKey: Uint8List.fromList(_key(seed)),
  name: 'Existing $seed',
  type: advTypeRepeater,
  pathLength: -1,
  path: Uint8List(0),
  lastSeen: DateTime.fromMillisecondsSinceEpoch(5000),
);

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContactDiscoveryStore.importContactsJson', () {
    final store = ContactDiscoveryStore()..setPublicKeyHex = 'aabbccddeeff';
    final now = DateTime.fromMillisecondsSinceEpoch(1000000);

    DiscoveredContactsImportResult run(
      Object fileContent, {
      List<Contact>? existing,
      Set<String> known = const {},
      String? self,
    }) => store.importContactsJson(
      json: fileContent is String ? fileContent : jsonEncode(fileContent),
      existingContacts: existing ?? [],
      knownContactKeys: known,
      selfPublicKeyHex: self,
      now: now,
    );

    test('an invalid entry is skipped, not the whole file', () {
      final existing = <Contact>[];
      final result = run([
        _entry(1),
        'not an object',
        {'name': 'no key'},
        {'publicKey': '%%%not base64', 'name': 'bad'},
        _entry(2, extra: {'lastSeen': 'yesterday'}),
        _entry(3),
      ], existing: existing);
      expect(result.total, 6);
      expect(result.imported, 2);
      expect(result.invalid, 4);
      expect(existing.map((c) => c.name), ['Node 1', 'Node 3']);
    });

    test('a public key that is not 32 bytes is rejected', () {
      final existing = <Contact>[];
      final result = run([
        _entry(1, key: List<int>.filled(5, 7)),
        _entry(2, key: List<int>.filled(40, 7)),
        _entry(3),
      ], existing: existing);
      expect(result.imported, 1);
      expect(result.invalid, 2);
      expect(existing.single.publicKey.length, pubKeySize);
    });

    test('imported routing paths are stripped', () {
      final existing = <Contact>[];
      run([
        _entry(
          1,
          extra: {
            'pathLength': 2,
            'path': base64Encode([0xA1, 0xB2]),
            'pathHashWidth': 1,
            'pathOverride': 1,
            'pathOverrideBytes': base64Encode([0xC3]),
          },
        ),
      ], existing: existing);
      final contact = existing.single;
      expect(contact.pathLength, -1);
      expect(contact.path, isEmpty);
      expect(contact.pathOverride, isNull);
      expect(contact.pathOverrideBytes, isNull);
    });

    test('duplicates in the file, known contacts and self are skipped', () {
      final existing = [_existing(9)];
      final selfHex = pubKeyToHex(Uint8List.fromList(_key(4)));
      final knownHex = pubKeyToHex(Uint8List.fromList(_key(5)));
      final result = run(
        [_entry(1), _entry(1), _entry(4), _entry(5), _entry(9), _entry(2)],
        existing: existing,
        known: {knownHex},
        self: selfHex,
      );
      expect(result.imported, 2);
      expect(result.skipped, 4);
      expect(result.invalid, 0);
      expect(existing.length, 3);
      // An existing discovered contact is fresher and is kept as is.
      expect(existing.first.name, 'Existing 9');
    });

    test('future timestamps are clamped to now', () {
      final existing = <Contact>[];
      run([
        _entry(
          1,
          lastSeen: now.millisecondsSinceEpoch + 999999,
          extra: {'lastMessageAt': now.millisecondsSinceEpoch + 5},
        ),
      ], existing: existing);
      expect(existing.single.lastSeen, now);
      expect(existing.single.lastMessageAt, now);
    });

    test('a file that is not a JSON list throws FormatException', () {
      expect(() => run('{"publicKey": "x"}'), throwsFormatException);
      expect(() => run('not json at all'), throwsFormatException);
      expect(() => run(''), throwsFormatException);
    });

    test('an empty list reports zero entries', () {
      final result = run(<Object>[]);
      expect(result.total, 0);
      expect(result.imported, 0);
    });

    test('exports leave out routing paths but stay importable', () {
      final source = Contact(
        publicKey: Uint8List.fromList(_key(1)),
        name: 'Pathy',
        type: advTypeRepeater,
        pathLength: 2,
        path: Uint8List.fromList([0xA1, 0xB2]),
        lastSeen: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final exported = store.exportContactsJson([source]);
      final decoded = (jsonDecode(exported) as List).single as Map;
      expect(decoded.containsKey('path'), isFalse);
      expect(decoded.containsKey('pathLength'), isFalse);
      final existing = <Contact>[];
      final result = run(exported, existing: existing);
      expect(result.imported, 1);
      expect(existing.single.name, 'Pathy');
    });
  });

  group('MeshCoreConnector.importDiscoveredContactsJson', () {
    late MeshCoreConnector connector;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      connector = MeshCoreConnector();
      final retryService = MessageRetryService();
      connector.initialize(
        retryService: retryService,
        pathHistoryService: PathHistoryService(StorageService()),
      );
      addTearDown(() {
        connector.dispose();
        retryService.dispose();
      });
    });

    test('does nothing while disconnected', () async {
      final result = await connector.importDiscoveredContactsJson(
        jsonEncode([_entry(1)]),
      );
      expect(result.imported, 0);
      expect(connector.discoveredContacts, isEmpty);
    });

    test('an import is trimmed to the discovered-contacts cap', () async {
      connector.reviewRadioFactoryForTest = () => ReviewRadio(
        scheduledMessageInterval: const Duration(hours: 1),
        replyDelay: const Duration(hours: 1),
      );
      await connector.connectReview();
      addTearDown(connector.disconnect);
      await _waitFor(() => connector.channels.isNotEmpty);

      const count = MeshCoreConnector.maxDiscoveredContacts + 50;
      final entries = [
        for (var i = 0; i < count; i++)
          _entry(
            0,
            key: [i & 0xFF, (i >> 8) & 0xFF, ...List<int>.filled(30, 0x5A)],
            lastSeen: 1000 + i,
          ),
      ];
      final result = await connector.importDiscoveredContactsJson(
        jsonEncode(entries),
      );
      expect(result.imported, count);
      expect(
        connector.discoveredContacts.length,
        lessThanOrEqualTo(MeshCoreConnector.maxDiscoveredContacts),
      );
    });
  });
}
