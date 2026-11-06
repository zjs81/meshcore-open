import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/usb_serial_frame_codec.dart';

void main() {
  test('wrapUsbSerialTxFrame prefixes tx header and payload length', () {
    final packet = wrapUsbSerialTxFrame(Uint8List.fromList(<int>[0x16, 0x03]));

    expect(
      packet,
      orderedEquals(<int>[usbSerialTxFrameStart, 0x02, 0x00, 0x16, 0x03]),
    );
  });

  test('wrapUsbSerialTxFrame rejects payloads above protocol maximum', () {
    final payload = Uint8List(usbSerialMaxPayloadLength + 1);

    expect(
      () => wrapUsbSerialTxFrame(payload),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.name,
          'name',
          'payload.length',
        ),
      ),
    );
  });

  test('UsbSerialFrameDecoder buffers partial frames until complete', () {
    final decoder = UsbSerialFrameDecoder();

    final firstChunk = decoder.ingest(
      Uint8List.fromList(<int>[usbSerialRxFrameStart, 0x03]),
    );
    final secondChunk = decoder.ingest(
      Uint8List.fromList(<int>[0x00, 0x05, 0x06, 0x07]),
    );

    expect(firstChunk, isEmpty);
    expect(secondChunk, hasLength(1));
    expect(secondChunk.single.isRxFrame, isTrue);
    expect(secondChunk.single.payload, orderedEquals(<int>[0x05, 0x06, 0x07]));
  });

  test(
    'UsbSerialFrameDecoder drops leading noise and parses multiple frames',
    () {
      final decoder = UsbSerialFrameDecoder();

      final packets = decoder.ingest(
        Uint8List.fromList(<int>[
          0x00,
          0x01,
          usbSerialRxFrameStart,
          0x01,
          0x00,
          0x55,
          usbSerialRxFrameStart,
          0x02,
          0x00,
          0x66,
          0x77,
        ]),
      );

      expect(packets, hasLength(2));
      expect(packets[0].payload, orderedEquals(<int>[0x55]));
      expect(packets[1].payload, orderedEquals(<int>[0x66, 0x77]));
    },
  );

  test(
    'UsbSerialFrameDecoder preserves tx packets so caller can ignore them',
    () {
      final decoder = UsbSerialFrameDecoder();

      final packets = decoder.ingest(
        Uint8List.fromList(<int>[
          usbSerialTxFrameStart,
          0x01,
          0x00,
          0x22,
          usbSerialRxFrameStart,
          0x01,
          0x00,
          0x33,
        ]),
      );

      expect(packets, hasLength(2));
      expect(packets[0].isRxFrame, isFalse);
      expect(packets[0].payload, orderedEquals(<int>[0x22]));
      expect(packets[1].isRxFrame, isTrue);
      expect(packets[1].payload, orderedEquals(<int>[0x33]));
    },
  );

  test(
    'UsbSerialFrameDecoder drops oversized frames and resyncs on the next valid packet',
    () {
      final decoder = UsbSerialFrameDecoder();

      final packets = decoder.ingest(
        Uint8List.fromList(<int>[
          usbSerialRxFrameStart,
          usbSerialMaxRxPayloadLength + 1,
          0x00,
          0x99,
          usbSerialRxFrameStart,
          0x01,
          0x00,
          0x44,
        ]),
      );

      expect(packets, hasLength(1));
      expect(packets.single.isRxFrame, isTrue);
      expect(packets.single.payload, orderedEquals(<int>[0x44]));
    },
  );

  test(
    'UsbSerialFrameDecoder accepts firmware frames up to 176 bytes and keeps the next frame',
    () {
      final decoder = UsbSerialFrameDecoder();
      final payload = Uint8List(usbSerialMaxRxPayloadLength);
      for (var i = 0; i < payload.length; i++) {
        // Include stray frame-start bytes inside the payload.
        payload[i] = i.isEven ? usbSerialTxFrameStart : usbSerialRxFrameStart;
      }

      final packets = decoder.ingest(
        Uint8List.fromList(<int>[
          usbSerialRxFrameStart,
          usbSerialMaxRxPayloadLength & 0xff,
          usbSerialMaxRxPayloadLength >> 8,
          ...payload,
          usbSerialRxFrameStart,
          0x01,
          0x00,
          0x06,
        ]),
      );

      expect(packets, hasLength(2));
      expect(packets[0].payload, orderedEquals(payload));
      expect(packets[1].payload, orderedEquals(<int>[0x06]));
    },
  );

  test('UsbSerialFrameDecoder reset clears buffered partial data', () {
    final decoder = UsbSerialFrameDecoder();

    expect(
      decoder.ingest(Uint8List.fromList(<int>[usbSerialRxFrameStart, 0x02])),
      isEmpty,
    );

    decoder.reset();

    final packets = decoder.ingest(
      Uint8List.fromList(<int>[usbSerialRxFrameStart, 0x01, 0x00, 0x55]),
    );

    expect(packets, hasLength(1));
    expect(packets.single.payload, orderedEquals(<int>[0x55]));
  });

  test('recovers from invalid frame header', () {
    final decoder = UsbSerialFrameDecoder();

    final packets = decoder.ingest(
      Uint8List.fromList(<int>[
        // First, a malformed frame (e.g. from a partial TX echo)
        usbSerialRxFrameStart,
        usbSerialTxFrameStart,
        // Then, a valid frame
        usbSerialRxFrameStart,
        0x01,
        0x00,
        0x88,
      ]),
    );

    expect(packets, hasLength(1));
    expect(packets.single.isRxFrame, isTrue);
    expect(packets.single.payload, orderedEquals(<int>[0x88]));
  });
}
