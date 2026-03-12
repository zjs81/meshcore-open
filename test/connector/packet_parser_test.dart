import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('parseBatteryStatusPacket', () {
    test('rejects truncated storage payloads', () {
      final frame = Uint8List.fromList(<int>[
        respCodeBattAndStorage,
        0x64,
        0x00,
        0x01,
      ]);

      expect(parseBatteryStatusPacket(frame), isNull);
    });
  });

  group('parseMessageSentPacket', () {
    test('parses the minimum documented sent frame', () {
      final frame = Uint8List.fromList(<int>[
        respCodeSent,
        0x02,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0x02,
        0x00,
        0x00,
        0x00,
      ]);

      final packet = parseMessageSentPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.messageType, 0x02);
      expect(packet.expectedAck, orderedEquals(<int>[0xAA, 0xBB, 0xCC, 0xDD]));
      expect(packet.suggestedTimeoutMs, 2000);
    });
  });

  group('parseAckPacket', () {
    test('parses the short ack variant', () {
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

    test('parses the extended ack variant', () {
      final frame = Uint8List.fromList(<int>[
        pushCodeSendConfirmed,
        1,
        2,
        3,
        4,
        0x10,
        0x00,
        0x00,
        0x00,
      ]);

      final packet = parseAckPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.ackCode, orderedEquals(<int>[1, 2, 3, 4]));
      expect(packet.tripTimeMs, 16);
    });

    test('rejects truncated in-between ack lengths', () {
      final frame = Uint8List.fromList(<int>[
        pushCodeSendConfirmed,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);

      expect(parseAckPacket(frame), isNull);
    });
  });
}
