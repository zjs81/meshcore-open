import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('MeshCoreFrameBuffer', () {
    test('reassembles a split fixed-length sent packet', () {
      final buffer = MeshCoreFrameBuffer();
      final frame = Uint8List.fromList(<int>[
        respCodeSent,
        1,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0x10,
        0x00,
        0x00,
        0x00,
      ]);

      expect(buffer.addChunk(frame.sublist(0, 4)), isEmpty);

      final frames = buffer.addChunk(frame.sublist(4));
      expect(frames, hasLength(1));
      expect(frames.single, orderedEquals(frame));
    });

    test('splits multiple fixed-length packets from one chunk', () {
      final buffer = MeshCoreFrameBuffer();
      final payload = Uint8List.fromList(<int>[
        respCodeCurrTime,
        0x78,
        0x56,
        0x34,
        0x12,
        pushCodeMsgWaiting,
      ]);

      final frames = buffer.addChunk(payload);
      expect(frames, hasLength(2));
      expect(frames[0], orderedEquals(payload.sublist(0, 5)));
      expect(frames[1], orderedEquals(<int>[pushCodeMsgWaiting]));
    });

    test('flushes buffered variable-length data as a single frame', () {
      final buffer = MeshCoreFrameBuffer();
      final frame = Uint8List.fromList(<int>[
        respCodeCustomVars,
        ...'k=v'.codeUnits,
      ]);

      expect(buffer.addChunk(frame.sublist(0, 2)), isEmpty);
      expect(buffer.addChunk(frame.sublist(2)), isEmpty);

      final flushed = buffer.flush();
      expect(flushed, isNotNull);
      expect(flushed!, orderedEquals(frame));
      expect(buffer.hasBufferedData, isFalse);
    });
  });
}
