import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('parseBinaryResponsePacket', () {
    test('parses status, tag, and payload', () {
      final frame = Uint8List.fromList(<int>[
        pushCodeBinaryResponse,
        0x01,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0x10,
        0x20,
        0x30,
      ]);

      final packet = parseBinaryResponsePacket(frame);

      expect(packet, isNotNull);
      expect(packet!.status, 0x01);
      expect(packet.tag, orderedEquals(<int>[0xAA, 0xBB, 0xCC, 0xDD]));
      expect(packet.payload, orderedEquals(<int>[0x10, 0x20, 0x30]));
    });

    test('rejects undersized frames', () {
      final frame = Uint8List.fromList(<int>[
        pushCodeBinaryResponse,
        0x00,
        0xAA,
        0xBB,
        0xCC,
      ]);

      expect(parseBinaryResponsePacket(frame), isNull);
    });
  });
}
