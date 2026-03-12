import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel_message.dart';

void main() {
  group('ChannelMessage.fromFrame', () {
    test('parses legacy channel frames with sequential reads', () {
      final textBytes = <int>[...('Alice: hello'.codeUnits), 0];
      final frame = Uint8List(8 + textBytes.length)
        ..[0] = respCodeChannelMsgRecv
        ..[1] = 3
        ..[2] = 0
        ..[3] = txtTypePlain;
      frame.buffer.asByteData().setUint32(4, 1_700_000_222, Endian.little);
      frame.setRange(8, frame.length, textBytes);

      final message = ChannelMessage.fromFrame(frame);

      expect(message, isNotNull);
      expect(message!.channelIndex, 3);
      expect(message.senderName, 'Alice');
      expect(message.text, 'hello');
      expect(message.pathBytes, isEmpty);
    });

    test('parses v3 frames with path bytes before text type', () {
      final textBytes = <int>[...('Bob: ping'.codeUnits), 0];
      final frame = Uint8List(1 + 1 + 1 + 1 + 1 + 1 + 2 + 1 + 4 + textBytes.length)
        ..[0] = respCodeChannelMsgRecvV3
        ..[1] = 0
        ..[2] = 0x01
        ..[3] = 0
        ..[4] = 7
        ..[5] = 2
        ..[6] = 0xAA
        ..[7] = 0xBB
        ..[8] = txtTypePlain;
      frame.buffer.asByteData().setUint32(9, 1_700_000_333, Endian.little);
      frame.setRange(13, frame.length, textBytes);

      final message = ChannelMessage.fromFrame(frame);

      expect(message, isNotNull);
      expect(message!.channelIndex, 7);
      expect(message.pathBytes, orderedEquals(<int>[0xAA, 0xBB]));
      expect(message.senderName, 'Bob');
      expect(message.text, 'ping');
    });
  });
}
