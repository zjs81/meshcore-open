import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _init([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  PrefsManager.reset();
  await PrefsManager.initialize();
}

const _key = 'aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899';

void main() {
  test('save and load round-trip a BLE radio', () async {
    await _init();
    final store = LastRadioStore();
    final saved = LastRadio(
      publicKeyHex: _key,
      name: 'Base',
      transport: LastRadio.transportBle,
      bleRemoteId: 'AA:BB:CC:DD:EE:FF',
      bleDisplayName: 'MeshCore-Base',
      savedAt: DateTime.fromMillisecondsSinceEpoch(1234),
    );
    await store.save(saved);

    final loaded = store.load()!;
    expect(loaded.publicKeyHex, _key);
    expect(loaded.name, 'Base');
    expect(loaded.transport, LastRadio.transportBle);
    expect(loaded.bleRemoteId, 'AA:BB:CC:DD:EE:FF');
    expect(loaded.bleDisplayName, 'MeshCore-Base');
    expect(loaded.tcpHost, isNull);
    expect(loaded.savedAt.millisecondsSinceEpoch, 1234);
    expect(loaded.canReconnectBle, isTrue);
    expect(loaded.canReconnectTcp, isFalse);
  });

  test('TCP radio keeps host and port', () async {
    await _init();
    final store = LastRadioStore();
    await store.save(
      LastRadio(
        publicKeyHex: _key,
        name: 'Roof',
        transport: LastRadio.transportTcp,
        tcpHost: '192.168.1.5',
        tcpPort: 5000,
        savedAt: DateTime.now(),
      ),
    );
    final loaded = store.load()!;
    expect(loaded.tcpHost, '192.168.1.5');
    expect(loaded.tcpPort, 5000);
    expect(loaded.canReconnectTcp, isTrue);
    expect(loaded.canReconnectBle, isFalse);
  });

  test('clear removes the record', () async {
    await _init();
    final store = LastRadioStore();
    await store.save(
      LastRadio(
        publicKeyHex: _key,
        name: 'x',
        transport: LastRadio.transportUsb,
        savedAt: DateTime.now(),
      ),
    );
    await store.clear();
    expect(store.load(), isNull);
  });

  test('tolerates missing, corrupt and partial records', () async {
    await _init();
    expect(LastRadioStore().load(), isNull);

    await _init({LastRadioStore.prefsKey: '{not json'});
    expect(LastRadioStore().load(), isNull);

    await _init({
      LastRadioStore.prefsKey: jsonEncode([1, 2, 3]),
    });
    expect(LastRadioStore().load(), isNull);

    await _init({
      LastRadioStore.prefsKey: jsonEncode({'publicKeyHex': 'abc'}),
    });
    expect(LastRadioStore().load(), isNull);

    await _init({
      LastRadioStore.prefsKey: jsonEncode({
        'publicKeyHex': _key,
        'transport': 'carrier-pigeon',
        'tcpPort': '80',
        'savedAt': 'yesterday',
      }),
    });
    final loaded = LastRadioStore().load()!;
    expect(loaded.publicKeyHex, _key);
    expect(loaded.name, '');
    expect(loaded.transport, LastRadio.transportBle);
    expect(loaded.tcpPort, isNull);
    expect(loaded.canReconnectBle, isFalse);
  });
}
