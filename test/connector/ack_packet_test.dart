import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('parseMessageSentPacket', () {
    test('converts documented timeout seconds to milliseconds', () {
      final frame = Uint8List.fromList(<int>[
        respCodeSent,
        1,
        0x11,
        0x22,
        0x33,
        0x44,
        5,
        0,
        0,
        0,
      ]);

      final packet = parseMessageSentPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.messageType, 1);
      expect(packet.expectedAck, orderedEquals(<int>[0x11, 0x22, 0x33, 0x44]));
      expect(packet.suggestedTimeoutMs, 5000);
    });
  });

  group('parseAckPacket', () {
    test('parses the documented 6-byte ack code variant', () {
      final frame = Uint8List.fromList(<int>[
        pushCodeSendConfirmed,
        1,
        2,
        3,
        4,
        5,
        6,
      ]);

      final packet = parseAckPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.ackCode, orderedEquals(<int>[1, 2, 3, 4, 5, 6]));
      expect(packet.tripTimeMs, isNull);
    });

    test('parses the extended ack variant with trip time', () {
      final frame = Uint8List.fromList(<int>[
        pushCodeSendConfirmed,
        0xaa,
        0xbb,
        0xcc,
        0xdd,
        0x10,
        0x27,
        0x00,
        0x00,
      ]);

      final packet = parseAckPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.ackCode, orderedEquals(<int>[0xaa, 0xbb, 0xcc, 0xdd]));
      expect(packet.tripTimeMs, 10000);
    });
  });
}
