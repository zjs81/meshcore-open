import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/message.dart';

void main() {
  group('Message.fromFrame', () {
    test('parses a plain contact message frame with BufferReader layout', () {
      final frame = Uint8List(1 + pubKeySize + 4 + 1 + 6)
        ..[0] = respCodeContactMsgRecv;
      frame.setRange(1, 1 + pubKeySize, List<int>.generate(pubKeySize, (i) => i + 1));
      frame.buffer.asByteData().setUint32(1 + pubKeySize, 1_700_000_111, Endian.little);
      frame[1 + pubKeySize + 4] = txtTypePlain << 2;
      frame.setRange(
        1 + pubKeySize + 5,
        frame.length,
        <int>[...('hello'.codeUnits), 0],
      );

      final message = Message.fromFrame(frame, Uint8List(pubKeySize));

      expect(message, isNotNull);
      expect(message!.text, 'hello');
      expect(message.senderKey, orderedEquals(List<int>.generate(pubKeySize, (i) => i + 1)));
      expect(message.timestamp.millisecondsSinceEpoch ~/ 1000, 1_700_000_111);
    });

    test('rejects non-plain text message types', () {
      final frame = Uint8List(1 + pubKeySize + 4 + 2)
        ..[0] = respCodeContactMsgRecv
        ..[1 + pubKeySize + 4] = txtTypeCliData << 2
        ..[1 + pubKeySize + 5] = 0;

      expect(Message.fromFrame(frame, Uint8List(pubKeySize)), isNull);
    });
  });
}
