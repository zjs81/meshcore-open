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

    test('splits 5-byte contacts-start frame from following contact payload', () {
      final buffer = MeshCoreFrameBuffer();
      final payload = Uint8List.fromList(<int>[
        respCodeContactsStart,
        0x03,
        0x00,
        0x00,
        0x00,
        respCodeContact,
        ...List<int>.filled(contactFrameSize - 1, 0),
      ]);

      final frames = buffer.addChunk(payload);
      expect(frames, hasLength(2));
      expect(frames[0], orderedEquals(payload.sublist(0, 5)));
      expect(frames[1], orderedEquals(payload.sublist(5)));
    });

    test('splits 5-byte end-of-contacts frame from following payload', () {
      final buffer = MeshCoreFrameBuffer();
      final payload = Uint8List.fromList(<int>[
        respCodeEndOfContacts,
        0x99,
        0x13,
        0xB2,
        0x69,
        respCodeNoMoreMessages,
      ]);

      final frames = buffer.addChunk(payload);
      expect(frames, hasLength(2));
      expect(frames[0], orderedEquals(payload.sublist(0, 5)));
      expect(frames[1], orderedEquals(<int>[respCodeNoMoreMessages]));
    });

    test('splits leading ok frame from following payload bytes', () {
      final buffer = MeshCoreFrameBuffer();
      final payload = Uint8List.fromList(<int>[
        respCodeOk,
        respCodeContact,
        ...List<int>.filled(contactFrameSize - 1, 0),
      ]);

      final frames = buffer.addChunk(payload);
      expect(frames, hasLength(2));
      expect(frames[0], orderedEquals(<int>[respCodeOk]));
      expect(frames[1], orderedEquals(payload.sublist(1)));
    });

    test('passes variable-length notifications through immediately', () {
      final buffer = MeshCoreFrameBuffer();
      final frame = Uint8List.fromList(<int>[
        respCodeCustomVars,
        ...'k=v'.codeUnits,
      ]);

      final frames = buffer.addChunk(frame);
      expect(frames, hasLength(1));
      expect(frames.single, orderedEquals(frame));
      expect(buffer.hasBufferedData, isFalse);
    });

    test('discards incomplete fixed-length frames instead of emitting them', () {
      final buffer = MeshCoreFrameBuffer();
      final partial = Uint8List.fromList(<int>[respCodeSent, 1, 2, 3]);

      expect(buffer.addChunk(partial), isEmpty);
      expect(buffer.hasBufferedData, isTrue);

      final discarded = buffer.discardIncompleteFrame();
      expect(discarded, orderedEquals(partial));
      expect(buffer.hasBufferedData, isFalse);
    });

    test('recovers embedded known frame after contact trailer bytes', () {
      final buffer = MeshCoreFrameBuffer();
      final contact = Uint8List(contactFrameSize)..[0] = respCodeContact;
      final payload = Uint8List.fromList(<int>[
        ...contact,
        0xD3,
        0xAC,
        0x69,
        0x94,
        0xDD,
        pushCodePathUpdated,
        ...List<int>.filled(32, 0x11),
      ]);

      final frames = buffer.addChunk(payload);
      expect(frames, hasLength(2));
      expect(frames[0], orderedEquals(contact));
      expect(frames[1][0], pushCodePathUpdated);
      expect(frames[1].length, 33);
    });
  });
}
