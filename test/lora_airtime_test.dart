import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';
import 'package:meshcore_open/models/radio_settings.dart';
import 'package:meshcore_open/utils/lora_airtime.dart';

double _ms(Duration d) => d.inMicroseconds / 1000.0;

RadioSettings _radio({
  LoRaSpreadingFactor sf = LoRaSpreadingFactor.sf10,
  LoRaBandwidth bw = LoRaBandwidth.bw250,
  LoRaCodingRate cr = LoRaCodingRate.cr4_5,
}) => RadioSettings(
  frequencyMHz: 869.525,
  bandwidth: bw,
  spreadingFactor: sf,
  codingRate: cr,
  txPowerDbm: 22,
);

void main() {
  group('loraTimeOnAir reference values (255-byte packet)', () {
    test('SF9, CR 4/8, BW 250 kHz -> 975 ms', () {
      final toa = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: 8,
      );
      expect(_ms(toa), closeTo(975, 1));
    });

    test('SF10, CR 4/5, BW 250 kHz -> 1148 ms', () {
      final toa = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 10,
        bandwidthHz: 250000,
        codingRate: 5,
      );
      expect(_ms(toa), closeTo(1148, 1));
    });
  });

  group('low data rate optimize', () {
    test('SF12 / BW 125 kHz engages LDRO (Tsym = 32.768 ms > 16 ms)', () {
      final toa = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 12,
        bandwidthHz: 125000,
        codingRate: 5,
      );
      // DE = 1 -> denominator 4*(12-2) = 40 -> 51 * 5 = 255 payload symbols
      // ToA = (12.25 + 263) * 32.768 ms
      expect(_ms(toa), closeTo(9019.392, 1));
    });

    test('SF12 / BW 500 kHz does NOT engage LDRO (Tsym = 8.192 ms)', () {
      final toa = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 12,
        bandwidthHz: 500000,
        codingRate: 5,
      );
      // DE = 0 -> denominator 48 -> 43 * 5 = 215 payload symbols
      // ToA = (12.25 + 223) * 8.192 ms
      expect(_ms(toa), closeTo(1927.9296, 1));
    });

    test('SF11 / BW 250 kHz does NOT engage LDRO (Tsym = 8.192 ms)', () {
      // Guards against the common `sf >= 11` shortcut, which is wrong here.
      final withSf11 = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 11,
        bandwidthHz: 250000,
        codingRate: 5,
      );
      // DE = 0 -> denominator 44 -> 47 * 5 = 235 payload symbols
      // ToA = (12.25 + 243) * 8.192 ms
      expect(_ms(withSf11), closeTo(2091.008, 1));
    });
  });

  group('airtime monotonicity / sanity', () {
    test('longer payload never takes less airtime', () {
      Duration at(int pl) => loraTimeOnAir(
        payloadBytes: pl,
        spreadingFactor: 10,
        bandwidthHz: 250000,
        codingRate: 5,
      );
      var previous = at(0);
      for (var pl = 1; pl <= 255; pl++) {
        final current = at(pl);
        expect(
          current.inMicroseconds,
          greaterThanOrEqualTo(previous.inMicroseconds),
        );
        previous = current;
      }
    });

    test('zero and one byte payloads do not crash and are positive', () {
      for (final pl in [0, 1]) {
        final toa = loraTimeOnAir(
          payloadBytes: pl,
          spreadingFactor: 9,
          bandwidthHz: 250000,
          codingRate: 5,
        );
        expect(toa.inMicroseconds, greaterThan(0));
      }
    });
  });

  group('normalizeCodingRate', () {
    test('maps both firmware encodings to 5..8', () {
      expect(normalizeCodingRate(1), 5);
      expect(normalizeCodingRate(4), 8);
      expect(normalizeCodingRate(5), 5);
      expect(normalizeCodingRate(8), 8);
    });

    test('raw 1..4 and 5..8 produce identical airtime after normalisation', () {
      final a = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: normalizeCodingRate(4),
      );
      final b = loraTimeOnAir(
        payloadBytes: 255,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: normalizeCodingRate(8),
      );
      expect(a, b);
      expect(_ms(a), closeTo(975, 1));
    });
  });

  group('chunk counts for measured codec payload sizes', () {
    test('ft32 "standard" (110 / 155.8 / 209 bytes) -> 1-2 chunks', () {
      // Derived from kImageChunkFirstCapacity, never hardcoded: that constant
      // has already moved twice (2->4 byte header, then a 2-byte CRC added to
      // chunk 0), and each time a hardcoded expectation here would have hidden
      // the estimator drifting away from the chunker.
      expect(imageChunkCount(110), 1);
      expect(imageChunkCount(209), 2);
      expect(imageChunkCount(156), 156 <= kImageChunkFirstCapacity ? 1 : 2);
      for (final pl in [110, 156, 209]) {
        expect(imageChunkCount(pl), inInclusiveRange(1, 2));
      }
    });

    test('ft16 "high" (176 / 288 / 409 bytes) -> 2-3 chunks', () {
      expect(imageChunkCount(176), 2);
      expect(imageChunkCount(288), 2);
      expect(imageChunkCount(409), 3);
      for (final pl in [176, 288, 409]) {
        expect(imageChunkCount(pl), inInclusiveRange(2, 3));
      }
    });

    test('chunk 0 carries one fewer payload byte (boundary handling)', () {
      // Derived from the transport's constants, never hardcoded: these numbers
      // moved once already when the header grew from 2 to 4 bytes to carry the
      // sender prefix, and a hardcoded test hid the estimator disagreeing with
      // the chunker.
      const first = kImageChunkFirstCapacity;
      const rest = kImageChunkCapacity;
      expect(first, rest - kImageChunkZeroMetadataBytes);
      expect(imageChunkCount(first), 1);
      expect(imageChunkCount(first + 1), 2);
      expect(imageChunkCount(first + rest), 2);
      expect(imageChunkCount(first + rest + 1), 3);
      expect(imageChunkCount(0), 0);
      expect(imageChunkCount(1), 1);
    });

    test('chunk payload sizes sum to the payload', () {
      for (final pl in [0, 1, 110, 162, 163, 209, 288, 409, 1000]) {
        expect(imageChunkPayloadSizes(pl).fold<int>(0, (a, b) => a + b), pl);
      }
    });
  });

  group('estimateSend', () {
    test('parity adds exactly one packet', () {
      final radio = _radio();
      for (final pl in [110, 209, 288, 409]) {
        final without = estimateSend(
          payloadBytes: pl,
          radio: radio,
          parity: false,
        );
        final with_ = estimateSend(payloadBytes: pl, radio: radio);
        expect(with_.chunkCount, without.chunkCount + 1);
        expect(without.includesParity, isFalse);
        expect(with_.includesParity, isTrue);
        expect(
          with_.totalAirtime!.inMicroseconds,
          greaterThan(without.totalAirtime!.inMicroseconds),
        );
      }
    });

    test('unknown radio settings -> packet count kept, airtime null', () {
      final est = estimateSend(payloadBytes: 288, radio: null);
      expect(est.chunkCount, 3); // 2 data chunks + parity
      expect(est.totalBytes, greaterThan(288));
      expect(est.perPacketAirtime, isNull);
      expect(est.totalAirtime, isNull);
      expect(est.hasAirtime, isFalse);
    });

    test('partially unknown radio params also yield a null airtime', () {
      final est = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 10,
        bandwidthHz: null,
        codingRate: 5,
      );
      expect(est.chunkCount, 3);
      expect(est.hasAirtime, isFalse);
    });

    test('raw firmware coding rate 1..4 is normalised', () {
      final a = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: 4, // firmware 1..4 encoding for 4/8
      );
      final b = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: 8, // 5..8 encoding for 4/8
      );
      expect(a, b);
    });

    test('zero-byte payload does not crash and adds no parity', () {
      final est = estimateSend(payloadBytes: 0, radio: _radio());
      expect(est.chunkCount, 0);
      expect(est.totalBytes, 0);
      expect(est.includesParity, isFalse);
      expect(est.totalAirtime, Duration.zero);
    });

    test('one-byte payload is a single chunk plus parity', () {
      final est = estimateSend(payloadBytes: 1, radio: _radio());
      expect(est.chunkCount, 2);
      expect(est.totalAirtime!.inMicroseconds, greaterThan(0));
    });

    test('total bytes account for chunk headers and metadata', () {
      final est = estimateSend(
        payloadBytes: 209,
        radio: _radio(),
        parity: false,
      );
      // A data blob is header + body (chunk 0's body opens with the metadata
      // byte). Only the PARITY blob carries the length byte, and it is always a
      // full kImageChunkBlobBytes because the XOR body is zero-padded.
      final sizes = imageChunkPayloadSizes(209);
      var expected = 0;
      for (var i = 0; i < sizes.length; i++) {
        expected +=
            kImageChunkHeaderBytes +
            (i == 0 ? kImageChunkZeroMetadataBytes : 0) +
            sizes[i];
      }
      expect(est.chunkCount, 2);
      expect(est.totalBytes, expected);
      // Sanity: payload + per-chunk header + the one metadata byte.
      expect(
        expected,
        209 + 2 * kImageChunkHeaderBytes + kImageChunkZeroMetadataBytes,
      );
    });

    test('total airtime equals the sum of the per-chunk airtimes', () {
      final est = estimateSend(
        payloadBytes: 409,
        radio: _radio(sf: LoRaSpreadingFactor.sf9, cr: LoRaCodingRate.cr4_8),
        parity: false,
      );
      final sizes = imageChunkPayloadSizes(409);
      var expected = 0;
      for (var i = 0; i < sizes.length; i++) {
        expected += loraTimeOnAir(
          payloadBytes:
              kImageChunkHeaderBytes +
              (i == 0 ? kImageChunkZeroMetadataBytes : 0) +
              sizes[i],
          spreadingFactor: 9,
          bandwidthHz: 250000,
          codingRate: 8,
        ).inMicroseconds;
      }
      expect(est.totalAirtime!.inMicroseconds, expected);
    });

    test('per-packet airtime is the airtime of a full chunk packet', () {
      final est = estimateSend(
        payloadBytes: 409,
        radio: _radio(sf: LoRaSpreadingFactor.sf10, cr: LoRaCodingRate.cr4_5),
      );
      final full = loraTimeOnAir(
        payloadBytes: kImageChunkBlobBytes,
        spreadingFactor: 10,
        bandwidthHz: 250000,
        codingRate: 5,
      );
      expect(est.perPacketAirtime, full);
    });

    test('a realistic ft16 image on SF10/BW250/CR4-5 stays under ~5 s', () {
      final est = estimateSend(payloadBytes: 288, radio: _radio());
      expect(est.chunkCount, 3);
      expect(est.totalAirtime!.inMilliseconds, greaterThan(1000));
      expect(est.totalAirtime!.inMilliseconds, lessThan(5000));
    });
  });

  group('paced wall clock', () {
    test('single-packet send has no pacing gap', () {
      final est = estimateSend(
        payloadBytes: 110,
        radio: _radio(),
        parity: false,
      );
      expect(est.chunkCount, 1);
      expect(est.pacedWallClock, est.totalAirtime);
    });

    test('multi-packet send adds one gap per inter-packet boundary', () {
      final est = estimateSend(payloadBytes: 209, radio: _radio());
      expect(est.chunkCount, 3); // 2 data + parity
      final sizes = imageChunkPayloadSizes(209);
      const framing = kImageChunkHeaderBytes + kImageParityLengthBytes;
      final packetBytes = <int>[
        framing + kImageChunkZeroMetadataBytes + sizes[0],
        framing + sizes[1],
        // parity body is as large as the largest data body
        framing +
            (sizes[0] + kImageChunkZeroMetadataBytes > sizes[1]
                ? sizes[0] + kImageChunkZeroMetadataBytes
                : sizes[1]),
      ];
      var airtime = 0;
      var wall = 0;
      for (var i = 0; i < packetBytes.length; i++) {
        final toa = loraTimeOnAir(
          payloadBytes: packetBytes[i],
          spreadingFactor: 10,
          bandwidthHz: 250000,
          codingRate: 5,
        );
        airtime += toa.inMicroseconds;
        wall += toa.inMicroseconds;
        if (i != packetBytes.length - 1) {
          wall += imageSendChunkGap(toa).inMicroseconds;
        }
      }
      expect(est.totalAirtime!.inMicroseconds, airtime);
      expect(est.pacedWallClock!.inMicroseconds, wall);
      // Two boundaries, so at least two base delays of extra wall clock.
      expect(
        wall - airtime,
        greaterThanOrEqualTo(2 * kImageSendChunkGapBase.inMicroseconds),
      );
    });

    test('the gap is the documented base plus airtime factor', () {
      const toa = Duration(milliseconds: 300);
      expect(
        imageSendChunkGap(toa),
        Duration(
          microseconds:
              kImageSendChunkGapBase.inMicroseconds +
              (toa.inMicroseconds * kImageSendChunkGapAirtimeFactor).round(),
        ),
      );
    });

    test('unknown radio settings leave the wall clock null too', () {
      final est = estimateSend(payloadBytes: 156, radio: null);
      expect(est.pacedWallClock, isNull);
      expect(est.totalAirtime, isNull);
      expect(est.chunkCount, imageChunkCount(156) + 1); // + parity
    });

    test('a realistic ft32 image on SF10/BW250/CR4-5 is a few seconds', () {
      // 110-209 B measured => 1-2 data chunks + parity. The paced figure is
      // what the compose sheet shows, so it must stay plausible.
      for (final pl in [110, 156, 209]) {
        final est = estimateSend(payloadBytes: pl, radio: _radio());
        expect(est.chunkCount, inInclusiveRange(2, 3));
        expect(est.pacedWallClock!.inMilliseconds, greaterThan(1000));
        expect(est.pacedWallClock!.inMilliseconds, lessThan(10000));
        expect(
          est.pacedWallClock!.inMicroseconds,
          greaterThan(est.totalAirtime!.inMicroseconds),
        );
      }
    });
  });

  group('malformed radio parameters from the wire', () {
    // currentSf/currentBwHz/currentCr are raw bytes off the device. A
    // disconnected or half-initialised radio reports zeroes, which used to
    // reach the ToA maths and throw "Unsupported operation: Infinity or NaN
    // toInt" in release builds. Packet counts must survive; airtime must go
    // null rather than be invented.
    test('zero spreading factor yields packet counts but no airtime', () {
      final est = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 0,
        bandwidthHz: 250000,
        codingRate: 5,
      );
      expect(est.chunkCount, greaterThan(0));
      expect(est.totalBytes, greaterThan(0));
      expect(est.totalAirtime, isNull);
      expect(est.perPacketAirtime, isNull);
    });

    test('zero bandwidth yields no airtime', () {
      final est = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 9,
        bandwidthHz: 0,
        codingRate: 8,
      );
      expect(est.totalAirtime, isNull);
    });

    test('zero coding rate yields no airtime', () {
      // normalizeCodingRate(0) == 4, which is still outside the legal 5..8.
      final est = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: 0,
      );
      expect(est.totalAirtime, isNull);
    });

    test('out-of-range spreading factors are rejected at both ends', () {
      for (final sf in [4, 13, 255]) {
        final est = estimateSendFromRadioParams(
          payloadBytes: 288,
          spreadingFactor: sf,
          bandwidthHz: 250000,
          codingRate: 5,
        );
        expect(
          est.totalAirtime,
          isNull,
          reason: 'sf=$sf must not produce airtime',
        );
      }
    });

    test('valid params still produce airtime after the guard', () {
      final est = estimateSendFromRadioParams(
        payloadBytes: 288,
        spreadingFactor: 9,
        bandwidthHz: 250000,
        codingRate: 4, // 1..4 firmware encoding -> normalises to 4/8
      );
      expect(est.totalAirtime, isNotNull);
      expect(est.totalAirtime!.inMilliseconds, greaterThan(0));
    });

    test('areLoRaParamsValid accepts the boundary values', () {
      expect(
        areLoRaParamsValid(
          spreadingFactor: 5,
          bandwidthHz: 7800,
          codingRate: 5,
        ),
        isTrue,
      );
      expect(
        areLoRaParamsValid(
          spreadingFactor: 12,
          bandwidthHz: 500000,
          codingRate: 8,
        ),
        isTrue,
      );
      expect(
        areLoRaParamsValid(
          spreadingFactor: null,
          bandwidthHz: 250000,
          codingRate: 5,
        ),
        isFalse,
      );
    });
  });

  group('estimator agrees with the real chunker', () {
    // The estimator used to charge the parity-length byte to every data chunk
    // and size the parity blob from the largest data body. Both were wrong:
    // only parity carries that byte, and its XOR body is always zero-padded to
    // full. A 110-byte payload was reported as 232 on-air bytes against a real
    // 278 — a 17% understatement of airtime on the smallest, most common image.
    // Compare against buildImageChunks() rather than restating the arithmetic.
    for (final payload in <int>[1, 110, 156, 157, 158, 209, 288, 409]) {
      test('$payload-byte payload matches buildImageChunks byte for byte', () {
        for (final parity in <bool>[false, true]) {
          final set = buildImageChunks(
            payload: Uint8List(payload),
            metadata: const ImageStreamMetadata(
              rate: ImageCodecRatePoint.standard,
            ),
            senderPrefix: 0x1234,
            imgId: 7,
            parity: parity,
          );
          final actual = set.blobs.fold<int>(0, (a, b) => a + b.length);
          final est = estimateSend(
            payloadBytes: payload,
            radio: _radio(),
            parity: parity,
          );
          expect(
            est.totalBytes,
            actual,
            reason: 'payload $payload, parity $parity',
          );
          expect(
            est.chunkCount,
            set.blobs.length,
            reason: 'payload $payload, parity $parity',
          );
        }
      });
    }
  });
}
