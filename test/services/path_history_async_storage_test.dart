import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';

class _Load {
  _Load(this.scope, this.contact);
  final String scope;
  final String contact;
  final result = Completer<ContactPathHistory?>();
}

class _Storage extends StorageService {
  String scope = 'a';
  bool delayLoads = true;
  Completer<void>? saveGate;
  bool failClears = false;
  final loads = <_Load>[];
  final saved = <String, ContactPathHistory>{};

  @override
  set setPublicKeyHex(String value) => scope = value;

  @override
  Future<ContactPathHistory?> loadPathHistory(String contactPubKeyHex) async {
    final load = _Load(scope, contactPubKeyHex);
    loads.add(load);
    if (delayLoads) return load.result.future;
    return saved['${load.scope}:$contactPubKeyHex'];
  }

  @override
  Future<void> savePathHistory(
    String contactPubKeyHex,
    ContactPathHistory history,
  ) async {
    final key = '$scope:$contactPubKeyHex';
    await saveGate?.future;
    saved[key] = history;
  }

  @override
  Future<void> clearPathHistory(String contactPubKeyHex) async {
    if (failClears) throw StateError('clear failed');
    saved.remove('$scope:$contactPubKeyHex');
  }

  @override
  Future<void> clearAllPathHistories() async {
    if (failClears) throw StateError('clear failed');
    saved.removeWhere((key, value) => key.startsWith('$scope:'));
  }
}

ContactPathHistory _history(String key, int hop) => ContactPathHistory(
  contactPubKeyHex: key,
  recentPaths: [
    PathRecord(
      hopCount: 1,
      tripTimeMs: 1,
      timestamp: DateTime(2026),
      wasFloodDiscovery: true,
      pathBytes: [hop],
      successCount: 1,
      failureCount: 0,
    ),
  ],
);

Contact _contact(int hop) => Contact(
  publicKey: Uint8List(32),
  name: 'Test',
  type: 1,
  pathLength: 1,
  path: Uint8List.fromList([hop]),
  lastSeen: DateTime(2026),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Storage storage;
  late PathHistoryService service;
  setUp(() {
    storage = _Storage();
    service = PathHistoryService(storage);
  });
  tearDown(() => service.dispose());

  test(
    'an old load cannot populate the next radio or remove its pending load',
    () async {
      service.getRecentPaths('contact');
      await _settle();
      service.setDevicePublicKey('b');
      service.getRecentPaths('contact');
      await _settle();
      expect(storage.loads.map((load) => load.scope), ['a', 'b']);
      storage.loads[0].result.complete(_history('contact', 1));
      await _settle();
      expect(service.isCached('contact'), isFalse);
      service.getRecentPaths('contact');
      await _settle();
      expect(storage.loads, hasLength(2));
      storage.loads[1].result.complete(_history('contact', 2));
      await _settle();
      expect(service.peekRecentPaths('contact').single.pathBytes, [2]);
    },
  );

  test('an old pending path event cannot be added to the next radio', () async {
    final contact = _contact(1);
    service.handlePathUpdated(contact);
    await _settle();
    service.setDevicePublicKey('b');
    service.getRecentPaths(contact.publicKeyHex);
    await _settle();
    storage.loads[1].result.complete(_history(contact.publicKeyHex, 2));
    await _settle();
    storage.loads[0].result.complete(null);
    await _settle();
    expect(service.peekRecentPaths(contact.publicKeyHex).single.pathBytes, [2]);
  });

  test('clearing a contact invalidates an outstanding read', () async {
    service.getRecentPaths('contact');
    await _settle();
    await service.clearPathHistory('contact');
    storage.loads.single.result.complete(_history('contact', 1));
    await _settle();
    expect(service.isCached('contact'), isFalse);
  });

  for (final dispose in [false, true]) {
    test(
      '${dispose ? 'disposing' : 'clearing all'} prevents delayed load notifications',
      () async {
        var notifications = 0;
        service.addListener(() => notifications++);
        service.getRecentPaths('contact');
        await _settle();
        if (dispose) {
          service.dispose();
        } else {
          service.clearAllHistories();
        }
        final before = notifications;
        storage.loads.single.result.complete(_history('contact', 1));
        await _settle();
        expect(service.isCached('contact'), isFalse);
        expect(notifications, before);
      },
    );
  }

  test('reads wait for an already-started history save', () async {
    storage.delayLoads = false;
    service.handlePathUpdated(_contact(1));
    await _settle();
    storage.saveGate = Completer<void>();
    final save = service.flushPendingWrites();
    await _settle();
    final read = service.readStoredPaths('other');
    await _settle();
    expect(storage.loads.where((load) => load.contact == 'other'), isEmpty);
    storage.saveGate!.complete();
    await save;
    expect(await read, isEmpty);
    expect(
      storage.loads.where((load) => load.contact == 'other'),
      hasLength(1),
    );
  });

  test(
    'clearing all waits for in-flight saves before allowing a new read',
    () async {
      storage.delayLoads = false;
      final contact = _contact(1);
      service.handlePathUpdated(contact);
      await _settle();
      storage.saveGate = Completer<void>();
      final save = service.flushPendingWrites();
      await _settle();
      service.clearAllHistories();
      final read = service.readStoredPaths(contact.publicKeyHex);
      storage.saveGate!.complete();
      await save;
      expect(await read, isEmpty);
      expect(storage.saved, isEmpty);
    },
  );

  test('a scope switch while waiting for saves skips the old read', () async {
    storage.delayLoads = false;
    service.handlePathUpdated(_contact(1));
    await _settle();
    storage.saveGate = Completer<void>();
    final save = service.flushPendingWrites();
    final read = service.readStoredPaths('other');
    service.setDevicePublicKey('b');
    storage.saveGate!.complete();
    await save;
    expect(await read, isEmpty);
    expect(storage.loads.where((load) => load.contact == 'other'), isEmpty);
    expect(storage.saved.keys.single, startsWith('a:'));
  });

  test(
    'a failed clear does not break later loads, clears or flushes',
    () async {
      storage.delayLoads = false;
      storage.failClears = true;
      await expectLater(service.clearPathHistory('contact'), throwsStateError);
      service.clearAllHistories();
      await _settle();

      storage.failClears = false;
      storage.saved['a:contact'] = _history('contact', 3);
      await service.flushPendingWrites();
      expect((await service.readStoredPaths('contact')).single.pathBytes, [3]);
      await service.clearPathHistory('contact');
      expect(storage.saved, isEmpty);
    },
  );
}
