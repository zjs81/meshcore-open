import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/storage/region_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Uint8List> _signedAdvert(
  int seedByte, {
  required int type,
  required String name,
  int timestamp = 1700000000,
}) async {
  final algo = Ed25519();
  final keys = await algo.newKeyPairFromSeed(List<int>.filled(32, seedByte));
  final pub = (await keys.extractPublicKey()).bytes;
  final ts = Uint8List(4)
    ..buffer.asByteData().setUint32(0, timestamp, Endian.little);
  final appData = [0x80 | type, ...name.codeUnits];
  final sig = await algo.sign([...pub, ...ts, ...appData], keyPair: keys);
  return Uint8List.fromList([...pub, ...ts, ...sig.bytes, ...appData]);
}

/// `[0x88][snr][rssi][header][codes?][path_len][advert]` as a transport flood.
Future<List<int>> _transportAdvertFrame(
  Uint8List advert, {
  String? region,
}) async {
  final header = (payloadTypeADVERT << 2) | 0x00; // transport flood
  List<int> codes = const [];
  if (region != null) {
    final code = floodTransportCode(
      scopeKey: floodScopeKeyForRegion(region),
      payloadType: payloadTypeADVERT,
      payload: advert,
    );
    codes = [code[0], code[1], 0x11, 0x22];
  }
  return [
    pushCodeLogRxData,
    40,
    0xA0,
    header,
    ...codes,
    0x00, // no path
    ...advert,
  ];
}

Future<void> _settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector connector;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    connector = MeshCoreConnector();
  });

  tearDown(() => connector.dispose());

  test('transport-flood advert keeps its known region as scope', () async {
    RegionStore().addRegion('eu');
    final advert = await _signedAdvert(7, type: advTypeChat, name: 'Scoped');
    connector.handleFrameForTest(
      await _transportAdvertFrame(advert, region: 'eu'),
    );
    await _settle();
    final contact = connector.discoveredContacts.firstWhere(
      (c) => c.name == 'Scoped',
    );
    expect(contact.advertScope, 'eu');
  });

  test('transport-flood advert with zero code is unscoped', () async {
    RegionStore().addRegion('eu');
    final advert = await _signedAdvert(8, type: advTypeChat, name: 'NullReg');
    connector.handleFrameForTest([
      pushCodeLogRxData,
      40,
      0xA0,
      (payloadTypeADVERT << 2) | 0x00,
      0x00,
      0x00,
      0x11,
      0x22,
      0x00,
      ...advert,
    ]);
    await _settle();
    final contact = connector.discoveredContacts.firstWhere(
      (c) => c.name == 'NullReg',
    );
    expect(contact.advertScope, kUnscopedRegion);
  });

  test('legacy flood advert without codes is unscoped', () async {
    RegionStore().addRegion('eu');
    final advert = await _signedAdvert(10, type: advTypeChat, name: 'Legacy');
    connector.handleFrameForTest([
      pushCodeLogRxData,
      40,
      0xA0,
      (payloadTypeADVERT << 2) | 0x01, // legacy flood: no transport codes
      0x00,
      ...advert,
    ]);
    await _settle();
    final contact = connector.discoveredContacts.firstWhere(
      (c) => c.name == 'Legacy',
    );
    expect(contact.advertScope, kUnscopedRegion);
  });

  test('advert with an unmatchable code stays unknown', () async {
    RegionStore().addRegion('eu');
    final advert = await _signedAdvert(11, type: advTypeChat, name: 'Alien');
    connector.handleFrameForTest([
      pushCodeLogRxData,
      40,
      0xA0,
      (payloadTypeADVERT << 2) | 0x00,
      0xAB,
      0xCD,
      0x11,
      0x22,
      0x00,
      ...advert,
    ]);
    await _settle();
    final contact = connector.discoveredContacts.firstWhere(
      (c) => c.name == 'Alien',
    );
    expect(contact.advertScope, isNull);
  });

  test('direct-route advert keeps the last known scope', () async {
    RegionStore().addRegion('eu');
    final advert = await _signedAdvert(12, type: advTypeChat, name: 'Near');
    connector.handleFrameForTest(
      await _transportAdvertFrame(advert, region: 'eu'),
    );
    await _settle();
    expect(
      connector.discoveredContacts
          .firstWhere((c) => c.name == 'Near')
          .advertScope,
      'eu',
    );
    // Transport-direct advert: carries no flood scope information.
    connector.handleFrameForTest([
      pushCodeLogRxData,
      40,
      0xA0,
      (payloadTypeADVERT << 2) | 0x03,
      0x99,
      0x88,
      0x11,
      0x22,
      0x00,
      ...advert,
    ]);
    await _settle();
    expect(
      connector.discoveredContacts
          .firstWhere((c) => c.name == 'Near')
          .advertScope,
      'eu',
    );
  });

  test('advert scope survives a refresh with a different region', () async {
    RegionStore().addRegion('eu');
    RegionStore().addRegion('us');
    final advert = await _signedAdvert(9, type: advTypeChat, name: 'Move');
    connector.handleFrameForTest(
      await _transportAdvertFrame(advert, region: 'eu'),
    );
    await _settle();
    expect(
      connector.discoveredContacts
          .firstWhere((c) => c.name == 'Move')
          .advertScope,
      'eu',
    );
    connector.handleFrameForTest(
      await _transportAdvertFrame(advert, region: 'us'),
    );
    await _settle();
    expect(
      connector.discoveredContacts
          .firstWhere((c) => c.name == 'Move')
          .advertScope,
      'us',
    );
  });
}
