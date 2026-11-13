import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/utils/advert_signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds an advert payload signed the way MeshCore's Mesh::createAdvert does.
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

/// Wraps an advert payload in a PUSH_CODE_LOG_RX_DATA frame (flood, no path).
List<int> _rxFrame(Uint8List payload) => [
  pushCodeLogRxData,
  0, // snr
  0, // rssi
  (payloadTypeADVERT << 2) | 0x01, // header: flood route
  0, // path length
  ...payload,
];

List<int> _contactFrame(int code, List<int> key, String name) {
  final data = ByteData(1 + 32 + 3 + 64 + 32 + 4 + 12);
  final bytes = data.buffer.asUint8List();
  bytes[0] = code;
  bytes.setRange(1, 33, key);
  bytes[33] = advTypeRepeater;
  bytes[35] = 0xFF;
  bytes.setRange(100, 100 + name.length, name.codeUnits);
  data.setUint32(132, 1700000000, Endian.little);
  return bytes;
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  group('verifyAdvertSignature', () {
    for (final type in [
      advTypeChat,
      advTypeRepeater,
      advTypeRoom,
      advTypeSensor,
    ]) {
      test('accepts a valid advert of type $type', () async {
        final advert = await _signedAdvert(
          type + 10,
          type: type,
          name: 'N$type',
        );
        expect(await verifyAdvertSignature(advert), isTrue);
      });
    }

    test('rejects tampered app data', () async {
      final advert = await _signedAdvert(1, type: advTypeRepeater, name: 'Rpt');
      advert[advert.length - 1] ^= 0x01;
      expect(await verifyAdvertSignature(advert), isFalse);
    });

    test('rejects a swapped public key', () async {
      final advert = await _signedAdvert(2, type: advTypeChat, name: 'Bob');
      final other = await _signedAdvert(3, type: advTypeChat, name: 'Bob');
      advert.setRange(0, 32, other.sublist(0, 32));
      expect(await verifyAdvertSignature(advert), isFalse);
    });

    test('rejects a short payload', () async {
      expect(await verifyAdvertSignature(Uint8List(99)), isFalse);
    });
  });

  group('RX advert handling', () {
    test('valid advert is discovered', () async {
      final connector = MeshCoreConnector();
      final advert = await _signedAdvert(4, type: advTypeRoom, name: 'Room');
      connector.handleFrameForTest(_rxFrame(advert));
      await _settle();
      expect(connector.discoveredContacts.map((c) => c.name), contains('Room'));
    });

    test('forged advert is dropped', () async {
      final connector = MeshCoreConnector();
      final advert = await _signedAdvert(
        5,
        type: advTypeRepeater,
        name: 'Real',
      );
      // Rename without re-signing.
      advert.setRange(advert.length - 4, advert.length, 'Fake'.codeUnits);
      connector.handleFrameForTest(_rxFrame(advert));
      await _settle();
      expect(connector.discoveredContacts, isEmpty);
    });
  });

  test('full contact sync forgets keys the radio dropped', () async {
    final connector = MeshCoreConnector();
    final kept = List<int>.generate(32, (i) => i + 1);
    final dropped = List<int>.generate(32, (i) => 100 + i);

    connector.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    connector.handleFrameForTest(_contactFrame(respCodeContact, kept, 'Kept'));
    connector.handleFrameForTest(
      _contactFrame(respCodeContact, dropped, 'Gone'),
    );
    connector.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    expect(connector.knownContactKeys.length, 2);

    connector.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    connector.handleFrameForTest(_contactFrame(respCodeContact, kept, 'Kept'));
    connector.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    await _settle();

    expect(connector.contacts.map((c) => c.name), ['Kept']);
    expect(connector.knownContactKeys, hasLength(1));
  });
}
