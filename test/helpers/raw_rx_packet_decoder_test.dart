import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/raw_rx_packet_decoder.dart';

void main() {
  test('decodes a transport-flood group text packet', () {
    // header: version 1 << 6 | payload type 5 (GRP_TXT) << 2 | route 0
    final header = (1 << 6) | (5 << 2) | 0;
    // path length: 1 hash of 2-byte width
    final pathLen = 0x41;
    final packet = Uint8List.fromList([
      header,
      0x11,
      0x22,
      0x33,
      0x44,
      pathLen,
      0xAA,
      0xBB,
      0x5A,
      0x01,
      0x02,
      0xDE,
      0xAD,
    ]);

    final info = decodeRawRxPacket(packet);

    expect(info.label, 'GRP_TXT • TRANS_FLOOD • v1');
    expect(info.hashWidth, 2);
    expect(info.pathBytes, [0xAA, 0xBB]);
    expect(info.summary, contains('GRP_TXT hash=5a mac=01 02 cipher=2'));
    expect(info.summary, contains('Path=aa bb'));
    expect(info.summary, contains('len=13'));
    expect(info.destPrefix, isEmpty);
    expect(info.senderPrefix, isEmpty);
  });

  test('decodes a direct packet destination prefix', () {
    // header: payload type 2 (TXT) << 2 | route 2 (DIRECT)
    final header = (2 << 2) | 2;
    final packet = Uint8List.fromList([
      header,
      0x01, // 1 hash of 1-byte width
      0xAB,
      // Direct payloads start with the 6-byte destination key prefix.
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x01,
      0x02,
    ]);

    final info = decodeRawRxPacket(packet);

    expect(info.label, 'TXT • DIRECT • v0');
    expect(info.destPrefix, [0x11, 0x22, 0x33, 0x44, 0x55, 0x66]);
    expect(info.summary, contains('dest=112233445566'));
    expect(info.senderPrefix, isEmpty);
  });

  test('exposes the advertising node prefix for adverts', () {
    // header: version 1 << 6 | payload type 4 (ADVERT) << 2 | route 1
    final header = (1 << 6) | (4 << 2) | 1;
    final packet = Uint8List.fromList([
      header,
      0x00, // no path
      0xDE,
      0xAD,
      0xBE,
      0xEF,
      0xCA,
      0xFE,
    ]);

    final info = decodeRawRxPacket(packet);

    expect(info.label, 'ADVERT • FLOOD • v1');
    expect(info.senderPrefix, [0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE]);
    expect(info.destPrefix, isEmpty);
  });

  test('decodes an ACK payload with its CRC', () {
    // header: version 0 | payload type 3 (ACK) << 2 | route 1 (FLOOD)
    final header = (3 << 2) | 1;
    final packet = Uint8List.fromList([header, 0x00, 0x12, 0x34, 0x56, 0x78]);

    final info = decodeRawRxPacket(packet);

    expect(info.label, 'ACK • FLOOD • v0');
    expect(info.summary, contains('ACK crc=12 34 56 78'));
  });

  test('flags packets too short for a header', () {
    final info = decodeRawRxPacket(Uint8List.fromList([0x00]));

    expect(info.label, 'invalid');
    expect(info.summary, 'Packet too short');
  });

  test('flags a truncated path', () {
    // header: payload type 2 (TXT) << 2 | route 2 (DIRECT); 3 hashes of
    // 1-byte width but no path bytes follow.
    final header = (2 << 2) | 2;
    final packet = Uint8List.fromList([header, 0x03]);

    final info = decodeRawRxPacket(packet);

    expect(info.label, 'TXT');
    expect(info.summary, 'Truncated path');
  });
}
