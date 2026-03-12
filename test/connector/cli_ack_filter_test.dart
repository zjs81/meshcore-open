import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  group('shouldIgnoreCliSentAck', () {
    test('ignores zero-hash sent acks when a CLI ack is pending', () {
      final shouldIgnore = shouldIgnoreCliSentAck(
        ackHash: Uint8List(4),
        pendingCliSentAckCount: 1,
      );

      expect(shouldIgnore, isTrue);
    });

    test('does not ignore a non-zero ack hash when a CLI ack is pending', () {
      final shouldIgnore = shouldIgnoreCliSentAck(
        ackHash: Uint8List.fromList(<int>[0x88, 0xFC, 0xCE, 0x4B]),
        pendingCliSentAckCount: 1,
      );

      expect(shouldIgnore, isFalse);
    });

    test('does not ignore zero-hash acks when no CLI ack is pending', () {
      final shouldIgnore = shouldIgnoreCliSentAck(
        ackHash: Uint8List(4),
        pendingCliSentAckCount: 0,
      );

      expect(shouldIgnore, isFalse);
    });
  });
}
