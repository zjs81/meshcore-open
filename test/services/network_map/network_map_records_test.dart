import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/connector/raw_packet.dart';
import 'package:meshcore_open/services/network_map/network_map_records.dart';

const _packetFields = {
  't',
  'pt',
  'rt',
  'hw',
  'path',
  'snr',
  'rssi',
  'size',
  'h',
  'scoped',
};

const _advertFields = {
  't',
  'key',
  'type',
  'name',
  'loc',
  'hidden',
  'snr',
  'rssi',
  'rt',
  'hw',
  'path',
};

final _receivedAt = DateTime.utc(2026, 10, 11, 18, 41, 37);
const _transportCodes = [0xDE, 0xAD, 0xBE, 0xEF];

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// `[0x88][snr*4][rssi][header][transport?][path_len][path][payload]`.
Uint8List _rxFrame({
  required int payloadType,
  int routeType = 1,
  int snrQuarters = 29,
  int rssi = -92,
  int pathLenRaw = 0,
  List<int> path = const [],
  required List<int> payload,
}) {
  return Uint8List.fromList([
    pushCodeLogRxData,
    snrQuarters & 0xFF,
    rssi & 0xFF,
    (payloadType << 2) | routeType,
    if (routeType == 0 || routeType == 3) ..._transportCodes,
    pathLenRaw,
    ...path,
    ...payload,
  ]);
}

/// Payload whose every 3-byte window is distinctive, so any leak of it into
/// a record would show up as a substring.
List<int> _secretPayload(int length) =>
    List<int>.generate(length, (i) => (0x5A + i * 37) & 0xFF);

Future<List<int>> _signedAdvertPayload({
  required SimpleKeyPair keyPair,
  required int type,
  double? lat,
  double? lon,
  String? name,
  bool corruptSignature = false,
  List<int> unsignedSuffix = const [],
}) async {
  final publicKey = (await keyPair.extractPublicKey()).bytes;
  final timestamp = [0x10, 0x20, 0x30, 0x40];
  var flags = type;
  final appData = <int>[];
  if (lat != null && lon != null) {
    flags |= 0x10;
    final loc = ByteData(8)
      ..setInt32(0, (lat * 1e6).round(), Endian.little)
      ..setInt32(4, (lon * 1e6).round(), Endian.little);
    appData.addAll(loc.buffer.asUint8List());
  }
  if (name != null) {
    flags |= 0x80;
    appData.addAll(utf8.encode(name));
  }
  appData.insert(0, flags);
  final signature = await Ed25519().sign([
    ...publicKey,
    ...timestamp,
    ...appData,
  ], keyPair: keyPair);
  final sigBytes = List<int>.from(signature.bytes);
  if (corruptSignature) sigBytes[10] ^= 0x01;
  return [
    ...publicKey,
    ...timestamp,
    ...sigBytes,
    ...appData,
    ...unsignedSuffix,
  ];
}

void main() {
  group('packet records', () {
    test('every payload type yields header-only fields', () {
      for (var pt = 0; pt < 16; pt++) {
        for (final rt in [0, 1, 2, 3]) {
          final payload = _secretPayload(40);
          final frame = _rxFrame(
            payloadType: pt,
            routeType: rt,
            pathLenRaw: 0x42, // 2 hops, 2-byte hashes
            path: const [0xA1, 0xA2, 0xB1, 0xB2],
            payload: payload,
          );
          final record = buildPacketRecord(frame, _receivedAt)!;
          final json = record.toJson();
          expect(json.keys.toSet(), _packetFields);
          expect(json['pt'], pt);
          expect(json['rt'], rt);
          expect(json['hw'], 2);
          expect(json['path'], 'a1a2b1b2');
          expect(json['scoped'], rt == 0 || rt == 3);
          expect(json['h'], computePacketHash(pt, Uint8List.fromList(payload)));

          // Nothing outside the hash may carry payload or transport bytes.
          final withoutHash = jsonEncode({...json}..remove('h'));
          expect(withoutHash, isNot(contains('dead')));
          expect(withoutHash, isNot(contains('beef')));
          for (var i = 0; i + 3 <= payload.length; i++) {
            expect(
              withoutHash,
              isNot(contains(_hex(payload.sublist(i, i + 3)))),
            );
          }
        }
      }
    });

    test('group text: channel hash and MAC never appear', () {
      // [channel_hash][MAC x2][ciphertext]
      final payload = [0x7C, 0x3E, 0x91, ..._secretPayload(32)];
      final record = buildPacketRecord(
        _rxFrame(payloadType: payloadTypeGRPTXT, payload: payload),
        _receivedAt,
      )!;
      final json = jsonEncode(record.toJson()..remove('h'));
      expect(json, isNot(contains('7c')));
      expect(json, isNot(contains('3e91')));
      expect(record.path, '');
    });

    test('direct message: source and destination hashes never appear', () {
      // [dest_hash][src_hash][MAC x2][ciphertext]
      final payload = [0xD7, 0x5C, 0x11, 0x22, ..._secretPayload(24)];
      final record = buildPacketRecord(
        _rxFrame(
          payloadType: payloadTypeTXTMSG,
          routeType: 2,
          payload: payload,
        ),
        _receivedAt,
      )!;
      final json = jsonEncode(record.toJson()..remove('h'));
      expect(json, isNot(contains('d7')));
      expect(json, isNot(contains('5c')));
    });

    test('snr is reported in quarter-dB steps and rssi passes through', () {
      final record = buildPacketRecord(
        _rxFrame(payloadType: 2, snrQuarters: -23, rssi: -110, payload: [1]),
        _receivedAt,
      )!;
      expect(record.snr, -5.75);
      expect(record.rssi, -110);
    });

    test('t is rounded down to the minute', () {
      final record = buildPacketRecord(
        _rxFrame(payloadType: 2, payload: [1]),
        _receivedAt,
      )!;
      expect(record.t % 60, 0);
      expect(
        record.t,
        DateTime.utc(2026, 10, 11, 18, 41).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('size is the raw packet length rounded up to 16', () {
      expect(roundUpPacketSize(0), 0);
      expect(roundUpPacketSize(1), 16);
      expect(roundUpPacketSize(16), 16);
      expect(roundUpPacketSize(17), 32);
      expect(roundUpPacketSize(48), 48);
      expect(roundUpPacketSize(49), 64);
      expect(roundUpPacketSize(255), 256);

      // header + path_len + 30 payload bytes = 32 raw bytes.
      final record = buildPacketRecord(
        _rxFrame(payloadType: 2, payload: _secretPayload(30)),
        _receivedAt,
      )!;
      expect(record.size, 32);
      final scoped = buildPacketRecord(
        _rxFrame(payloadType: 2, routeType: 0, payload: _secretPayload(30)),
        _receivedAt,
      )!;
      expect(scoped.size, 48); // + 4 transport bytes = 36
    });

    test('hash matches the firmware packet hash', () {
      final payload = Uint8List.fromList(_secretPayload(20));
      final digest = crypto.sha256.convert([5, ...payload]).bytes;
      final record = buildPacketRecord(
        _rxFrame(payloadType: 5, payload: payload),
        _receivedAt,
      )!;
      expect(record.h, _hex(digest.sublist(0, 8)));
      expect(record.h, computePacketHash(5, payload));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(record.h), isTrue);
    });

    test('unsupported hash width, oversized path and other frames dropped', () {
      // Hash width code 3 -> 4-byte hashes.
      expect(
        buildPacketRecord(
          _rxFrame(
            payloadType: 2,
            pathLenRaw: 0xC1,
            path: const [1, 2, 3, 4],
            payload: [1],
          ),
          _receivedAt,
        ),
        isNull,
      );
      // 22 hops of 3 bytes = 66 bytes > 64.
      expect(
        buildPacketRecord(
          _rxFrame(
            payloadType: 2,
            pathLenRaw: 0x80 | 22,
            path: List<int>.filled(66, 7),
            payload: [1],
          ),
          _receivedAt,
        ),
        isNull,
      );
      expect(
        buildPacketRecord(Uint8List.fromList([0x80, 1, 2, 3]), _receivedAt),
        isNull,
      );
      expect(
        buildPacketRecord(
          Uint8List.fromList([pushCodeLogRxData, 1]),
          _receivedAt,
        ),
        isNull,
      );
    });
  });

  group('advert records', () {
    late SimpleKeyPair keyPair;
    late String keyHex;

    setUpAll(() async {
      keyPair = await Ed25519().newKeyPairFromSeed(List<int>.filled(32, 7));
      keyHex = _hex((await keyPair.extractPublicKey()).bytes);
    });

    Future<Uint8List> advertFrame({
      required int type,
      double? lat,
      double? lon,
      String? name,
      bool corrupt = false,
      List<int> unsignedSuffix = const [],
    }) async {
      return _rxFrame(
        payloadType: payloadTypeADVERT,
        pathLenRaw: 0x01,
        path: const [0xA1],
        payload: await _signedAdvertPayload(
          keyPair: keyPair,
          type: type,
          lat: lat,
          lon: lon,
          name: name,
          corruptSignature: corrupt,
          unsignedSuffix: unsignedSuffix,
        ),
      );
    }

    test('verified repeater advert: snapped location, name, key', () async {
      final frame = await advertFrame(
        type: advTypeRepeater,
        lat: 33.448376,
        lon: -112.074036,
        name: 'Hilltop RPT',
      );
      final advert = (await buildAdvertRecord(frame, _receivedAt))!;
      final json = advert.toJson();
      expect(json.keys.toSet(), _advertFields);
      expect(json['key'], keyHex);
      expect(json['type'], 2);
      expect(json['name'], 'Hilltop RPT');
      expect(json['loc'], {'lat': 33.45, 'lon': -112.080261});
      expect(json['hidden'], false);
      expect(json['snr'], 7.25);
      expect(json['rssi'], -92);
      expect(json['rt'], 1);
      expect(json['hw'], 1);
      expect(json['path'], 'a1');
      expect(json['t'] % 60, 0);
      // Exact coordinates never leave the phone.
      expect(jsonEncode(json), isNot(contains('448376')));

      // The same frame still produces a header-only packet record.
      expect(buildPacketRecord(frame, _receivedAt)!.pt, payloadTypeADVERT);
    });

    test('room server adverts are uploaded too', () async {
      final frame = await advertFrame(type: advTypeRoom, name: 'Room');
      final advert = (await buildAdvertRecord(frame, _receivedAt))!;
      expect(advert.type, 3);
      expect(advert.loc, isNull);
    });

    test('chat and sensor adverts are packet records only', () async {
      for (final type in [advTypeChat, advTypeSensor]) {
        final frame = await advertFrame(
          type: type,
          lat: 47.6,
          lon: -122.3,
          name: 'Alice',
        );
        expect(await buildAdvertRecord(frame, _receivedAt), isNull);
        final packet = buildPacketRecord(frame, _receivedAt)!;
        final json = jsonEncode(packet.toJson());
        expect(json, isNot(contains(keyHex.substring(0, 6))));
        expect(json, isNot(contains('Alice')));
      }
    });

    test('names containing the no-entry sign are hidden', () async {
      final frame = await advertFrame(
        type: advTypeRepeater,
        lat: 47.6,
        lon: -122.3,
        name: 'Secret \u{1F6AB}',
      );
      final advert = (await buildAdvertRecord(frame, _receivedAt))!;
      final json = advert.toJson();
      expect(json['hidden'], true);
      expect(json['name'], isNull);
      expect(json['loc'], isNull);
      expect(json['key'], keyHex);
    });

    test('bytes after the signed 32 app-data bytes are ignored', () async {
      // flags (1) + location (8) + 23-byte name fill the signed 32 bytes.
      const name = 'Hilltop Repeater North1';
      expect(utf8.encode(name).length, 23);
      final frame = await advertFrame(
        type: advTypeRepeater,
        lat: 47.6,
        lon: -122.3,
        name: name,
        unsignedSuffix: utf8.encode(' \u{1F6AB} evil'),
      );
      final advert = (await buildAdvertRecord(frame, _receivedAt))!;
      final json = advert.toJson();
      expect(json['hidden'], false);
      expect(json['name'], name);
      expect(json['loc'], isNotNull);
    });

    test('adverts with a bad signature are dropped', () async {
      final frame = await advertFrame(
        type: advTypeRepeater,
        name: 'Forged',
        corrupt: true,
      );
      expect(await buildAdvertRecord(frame, _receivedAt), isNull);
    });

    test('non-advert packets never produce adverts', () async {
      final frame = _rxFrame(payloadType: 5, payload: _secretPayload(120));
      expect(await buildAdvertRecord(frame, _receivedAt), isNull);
    });
  });
}
