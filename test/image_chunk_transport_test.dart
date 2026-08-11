import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';

Uint8List payloadOf(int length, {int seed = 7}) => Uint8List.fromList(
  List<int>.generate(length, (i) => (i * 37 + seed * 11) & 0xFF),
);

const ImageStreamMetadata stdMeta = ImageStreamMetadata(
  rate: ImageCodecRatePoint.standard,
);
const ImageStreamMetadata highMeta = ImageStreamMetadata(
  rate: ImageCodecRatePoint.high,
);

const int senderA = 0x1234;
const int senderB = 0xBEEF;

/// A copy of [blob] with the byte at [offset] flipped by [mask].
Uint8List flipByte(Uint8List blob, int offset, {int mask = 0x01}) {
  final copy = Uint8List.fromList(blob);
  copy[offset] ^= mask;
  return copy;
}

/// Feeds [blobs] to [r] in the given order and returns the completed image, if
/// any completed.
ImageReassemblyResult? feed(
  ImageReassembler r,
  List<Uint8List> blobs, {
  int channelIndex = 0,
  DateTime? now,
}) {
  ImageReassemblyResult? result;
  for (final blob in blobs) {
    final outcome = r.addChunk(blob, channelIndex: channelIndex, now: now);
    result ??= outcome.result;
  }
  return result;
}

void main() {
  group('constants', () {
    test('every blob fits the binding transport limit', () {
      expect(kImageChunkBlobBytes, 163);
      expect(kImageChunkHeaderBytes, 4);
      expect(kImageChunkBodyBytes, 158);
      // Chunk 0 spends 1 byte on metadata and nothing else: the CRC-16 that
      // briefly lived here was removed once it turned out the LoRa PHY CRC and
      // MeshCore's per-packet HMAC already cover a delivered chunk.
      expect(kImageChunkMetadataBytes, 1);
      expect(kImageChunkZeroMetadataBytes, 1);
      expect(kImageChunkFirstCapacity, 157);
      expect(kImageChunkCapacity, 158);
      expect(kImageMaxPayloadBytes, 157 + 14 * 158);
    });

    test('measured codec worst cases hit the design chunk counts', () {
      // ft32 (standard) max 209 B, ft16 (high) max 409 B.
      expect(imageDataChunkCount(209), 2);
      expect(imageDataChunkCount(409), 3);
      // With chunk 0 back at 157 data bytes the measured ft32 MEAN fits in a
      // single data chunk (2 packets with parity), which is the whole point of
      // dropping the CRC.
      expect(ImageCodecRateStats.standard.meanBytes, 156);
      expect(imageDataChunkCount(ImageCodecRateStats.standard.meanBytes), 1);
      expect(imageDataChunkCount(157), 1);
      expect(imageDataChunkCount(158), 2);
      expect(imageDataChunkCount(ImageCodecRateStats.standard.minBytes), 1);
      expect(imageDataChunkCount(ImageCodecRateStats.high.meanBytes), 2);
    });
  });

  group('metadata byte', () {
    test('round-trips both rate points', () {
      for (final rate in ImageCodecRatePoint.values) {
        final meta = ImageStreamMetadata(rate: rate);
        expect(ImageStreamMetadata.decode(meta.encode()), meta);
      }
    });

    test('rejects an unrepresentable resolution', () {
      expect(
        () => const ImageStreamMetadata(
          rate: ImageCodecRatePoint.standard,
          squareSize: 999,
        ).encode(),
        throwsArgumentError,
      );
    });

    test('an unknown RATE code is what signals a format break', () {
      // The byte is aspect(4) | resolution(2) | rate(2). Resolution is now a
      // closed 2-bit field: all four codes are legal, so an unknown resolution
      // is no longer expressible. Rate keeps two spare codes (2 and 3), and
      // that is the channel a future incompatible format must use so older
      // receivers reject it instead of guessing.
      expect(ImageStreamMetadata.decode(0x02), isNull); // rate code 2
      expect(ImageStreamMetadata.decode(0x03), isNull); // rate code 3
      // 0xF0 is aspect 15 (unknown shape), resolution 0, rate 0 — all legal.
      final legal = ImageStreamMetadata.decode(0xF0);
      expect(legal, isNotNull);
      expect(legal!.aspectCode, kImageAspectUnknown);
      expect(legal.isSquare, isTrue);
    });
  });

  group('chunking', () {
    test('one, two and three chunk payloads produce the right blob shapes', () {
      final cases = <int, int>{
        1: 1,
        kImageChunkFirstCapacity: 1,
        kImageChunkFirstCapacity + 1: 2,
        kImageChunkFirstCapacity + kImageChunkCapacity: 2,
        kImageChunkFirstCapacity + kImageChunkCapacity + 1: 3,
      };
      cases.forEach((length, expectedChunks) {
        final set = buildImageChunks(
          payload: payloadOf(length),
          metadata: stdMeta,
          senderPrefix: senderA,
          imgId: 3,
        );
        expect(set.dataChunkCount, expectedChunks, reason: 'len $length');
        expect(set.blobs.length, expectedChunks + 1); // + parity
        for (final blob in set.blobs) {
          expect(blob.length, lessThanOrEqualTo(kImageChunkBlobBytes));
        }
      });
    });

    test('header fields are on the wire where the spec says', () {
      final set = buildImageChunks(
        payload: payloadOf(400),
        metadata: highMeta,
        senderPrefix: senderA,
        imgId: 0x5A,
      );
      expect(set.dataChunkCount, 3);
      for (var i = 0; i < set.blobs.length; i++) {
        final blob = set.blobs[i];
        expect(blob[0], 0x12);
        expect(blob[1], 0x34);
        expect(blob[2], 0x5A);
        expect((blob[3] >> 4) & 0x0F, i);
        expect(blob[3] & 0x0F, 3);
      }
      expect(parseImageChunkHeader(set.blobs.last)!.isParity, isTrue);
      expect(set.blobs[4 - 1].length, greaterThan(kImageChunkHeaderBytes));
      // Chunk 0 carries the metadata byte first.
      expect(set.blobs[0][kImageChunkHeaderBytes], highMeta.encode());
    });

    test('rejects a payload larger than the framing can address', () {
      expect(
        () => buildImageChunks(
          payload: payloadOf(kImageMaxPayloadBytes + 1),
          metadata: stdMeta,
          senderPrefix: senderA,
          imgId: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('round trip', () {
    for (final length in <int>[
      100, // 1 chunk
      300, // 2 chunks
      460, // 3 chunks
    ]) {
      test('$length bytes round-trips in order', () {
        final payload = payloadOf(length);
        final set = buildImageChunks(
          payload: payload,
          metadata: highMeta,
          senderPrefix: senderA,
          imgId: 11,
        );
        final r = ImageReassembler(selfPrefix: senderB);
        final result = feed(r, set.blobs);
        expect(result, isNotNull);
        expect(result!.data, payload);
        expect(result.metadata, highMeta);
        expect(result.recoveredWithParity, isFalse);
        expect(result.chunkCount, set.dataChunkCount);
        expect(r.pendingCount, 0, reason: 'trailing parity must not linger');
      });
    }

    test('completion callback fires exactly once', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 4,
      );
      final results = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: results.add);
      feed(r, set.blobs);
      expect(results.length, 1);
      expect(results.single.data, payload);
    });

    test('out-of-order arrival still reassembles', () {
      final payload = payloadOf(460, seed: 3);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 9,
      );
      // All three data chunks arrive out of order, parity last (so this
      // exercises reordering, not parity recovery).
      final shuffled = <Uint8List>[
        set.blobs[2],
        set.blobs[0],
        set.blobs[1],
        set.blobs[3], // parity
      ];
      final r = ImageReassembler();
      final result = feed(r, shuffled);
      expect(result, isNotNull);
      expect(result!.data, payload);
      expect(result.recoveredWithParity, isFalse);
    });

    test('duplicate chunks are ignored', () {
      final payload = payloadOf(460); // 3 data chunks + parity
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 2,
      );
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.duplicate);
      expect(r.addChunk(set.blobs[2]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[2]).status, ImageChunkStatus.duplicate);
      final done = r.addChunk(set.blobs[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payload);
      expect(done.result!.recoveredWithParity, isFalse);
      // Trailing parity and late duplicates are ignored, not restarted.
      expect(r.addChunk(set.blobs[3]).status, ImageChunkStatus.duplicate);
      expect(r.addChunk(set.blobs[1]).status, ImageChunkStatus.duplicate);
      expect(r.pendingCount, 0);
    });

    test('a duplicate parity chunk is ignored', () {
      final set = buildImageChunks(
        payload: payloadOf(460),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 15,
      );
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[3]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[3]).status, ImageChunkStatus.duplicate);
      expect(r.pendingCount, 1);
    });

    test('parity completes an image that is one chunk short', () {
      final payload = payloadOf(300); // 2 data chunks
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 16,
      );
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.accepted);
      final done = r.addChunk(set.blobs[2]); // parity rebuilds chunk 1
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payload);
      expect(done.result!.recoveredWithParity, isTrue);
    });

    test('two senders interleaved on one channel do not mix', () {
      final a = payloadOf(300, seed: 1);
      final b = payloadOf(300, seed: 2);
      final setA = buildImageChunks(
        payload: a,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 5,
      );
      final setB = buildImageChunks(
        payload: b,
        metadata: highMeta,
        senderPrefix: senderB,
        imgId: 5, // same img_id on purpose
      );
      final got = <int, Uint8List>{};
      final r = ImageReassembler(
        onImage: (res) => got[res.key.senderPrefix] = res.data,
      );
      feed(r, <Uint8List>[
        setA.blobs[0],
        setB.blobs[1],
        setA.blobs[1],
        setB.blobs[0],
      ]);
      expect(got[senderA], a);
      expect(got[senderB], b);
    });

    test('the same img_id on different channels stays separate', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 8,
      );
      final r = ImageReassembler();
      expect(
        r.addChunk(set.blobs[0], channelIndex: 0).status,
        ImageChunkStatus.accepted,
      );
      expect(
        r.addChunk(set.blobs[1], channelIndex: 1).status,
        ImageChunkStatus.accepted,
      );
      expect(r.pendingCount, 2);
    });
  });

  group('parity recovery', () {
    test('recovers any single lost data chunk (2 and 3 chunk images)', () {
      for (final length in <int>[300, 460]) {
        final payload = payloadOf(length, seed: length);
        final set = buildImageChunks(
          payload: payload,
          metadata: stdMeta,
          senderPrefix: senderA,
          imgId: 6,
        );
        for (var lost = 0; lost < set.dataChunkCount; lost++) {
          final blobs = <Uint8List>[
            for (var i = 0; i < set.blobs.length; i++)
              if (i != lost) set.blobs[i],
          ];
          final r = ImageReassembler();
          final result = feed(r, blobs);
          expect(result, isNotNull, reason: 'len $length lost $lost');
          expect(result!.data, payload, reason: 'len $length lost $lost');
          expect(result.metadata, stdMeta);
          expect(result.recoveredWithParity, isTrue);
        }
      }
    });

    test('recovers the short final chunk (length is carried by parity)', () {
      // 158 + 1 => final chunk is a single byte long.
      final payload = payloadOf(kImageChunkFirstCapacity + 1);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 12,
      );
      expect(set.dataChunkCount, 2);
      final r = ImageReassembler();
      final result = feed(r, <Uint8List>[set.blobs[0], set.blobs[2]]);
      expect(result, isNotNull);
      expect(result!.data, payload);
      expect(result.recoveredWithParity, isTrue);
    });

    test('total=1 with parity recovers the only data chunk', () {
      final payload = payloadOf(100);
      final set = buildImageChunks(
        payload: payload,
        metadata: highMeta,
        senderPrefix: senderA,
        imgId: 1,
      );
      expect(set.dataChunkCount, 1);
      expect(set.blobs.length, 2);
      final r = ImageReassembler();
      final result = feed(r, <Uint8List>[set.blobs[1]]); // parity only
      expect(result, isNotNull);
      expect(result!.data, payload);
      expect(result.metadata, highMeta);
      expect(result.recoveredWithParity, isTrue);
    });

    test('losing two chunks fails and never yields a wrong image', () {
      final payload = payloadOf(460);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 7,
      );
      final r = ImageReassembler();
      // Deliver only chunk 1 and parity: two data chunks are missing.
      final result = feed(r, <Uint8List>[set.blobs[1], set.blobs[3]]);
      expect(result, isNull);
      expect(r.pendingCount, 1);
    });

    test('parity is optional', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 3,
        parity: false,
      );
      expect(set.hasParity, isFalse);
      expect(set.blobs.length, 2);
      final r = ImageReassembler();
      expect(feed(r, set.blobs)!.data, payload);
    });
  });

  group('TTL and eviction', () {
    test('a stalled image expires and is reported as failed', () {
      final set = buildImageChunks(
        payload: payloadOf(460),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 21,
      );
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1, 12);
      final r = ImageReassembler(
        ttl: const Duration(seconds: 60),
        onFailed: failures.add,
      );
      r.addChunk(set.blobs[0], now: start);
      r.addChunk(set.blobs[1], now: start.add(const Duration(seconds: 30)));
      expect(r.pendingCount, 1);

      expect(
        r.evictExpired(now: start.add(const Duration(seconds: 59))),
        isEmpty,
      );
      expect(r.pendingCount, 1);

      final expired = r.evictExpired(
        now: start.add(const Duration(minutes: 2)),
      );
      expect(expired.length, 1);
      expect(expired.single.total, 3);
      expect(expired.single.receivedDataChunks, 2);
      expect(expired.single.hadParity, isFalse);
      expect(expired.single.missingChunks, 1);
      expect(failures.length, 1);
      expect(r.pendingCount, 0);
    });

    test('addChunk sweeps expired streams', () {
      final setOld = buildImageChunks(
        payload: payloadOf(460),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 30,
      );
      final setNew = buildImageChunks(
        payload: payloadOf(300),
        metadata: stdMeta,
        senderPrefix: senderB,
        imgId: 31,
      );
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1);
      final r = ImageReassembler(onFailed: failures.add);
      r.addChunk(setOld.blobs[0], now: start);
      r.addChunk(setNew.blobs[0], now: start.add(const Duration(minutes: 5)));
      expect(failures.length, 1);
      expect(failures.single.key.imgId, 30);
      expect(r.pendingCount, 1);
    });

    test('an unrelated chunk after expiry does not resurrect the old data', () {
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 40,
      );
      final start = DateTime(2026, 5, 5);
      final r = ImageReassembler();
      r.addChunk(set.blobs[0], now: start);
      final late = r.addChunk(
        set.blobs[1],
        now: start.add(const Duration(minutes: 2)),
      );
      // Chunk 0 expired, so chunk 1 alone cannot complete anything.
      expect(late.status, ImageChunkStatus.accepted);
      expect(late.result, isNull);
    });

    test('too many concurrent streams evicts the oldest', () {
      final start = DateTime(2026, 2, 2);
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(
        maxConcurrentStreams: 2,
        onFailed: failures.add,
      );
      for (var i = 0; i < 3; i++) {
        final set = buildImageChunks(
          payload: payloadOf(300),
          metadata: stdMeta,
          senderPrefix: senderA,
          imgId: 50 + i,
        );
        r.addChunk(set.blobs[0], now: start.add(Duration(seconds: i)));
      }
      expect(r.pendingCount, 2);
      expect(failures.length, 1);
      expect(failures.single.key.imgId, 50);
    });
  });

  group('boundary cases', () {
    test('empty payload round-trips as one chunk', () {
      final set = buildImageChunks(
        payload: Uint8List(0),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 0,
      );
      expect(set.dataChunkCount, 1);
      expect(
        set.blobs[0].length,
        kImageChunkHeaderBytes + kImageChunkZeroMetadataBytes,
      );
      final r = ImageReassembler();
      final result = feed(r, set.blobs);
      expect(result, isNotNull);
      expect(result!.data, isEmpty);
      expect(result.metadata, stdMeta);
    });

    test('empty payload recovers from parity alone', () {
      final set = buildImageChunks(
        payload: Uint8List(0),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 0,
      );
      final r = ImageReassembler();
      final result = feed(r, <Uint8List>[set.blobs[1]]);
      expect(result, isNotNull);
      expect(result!.data, isEmpty);
    });

    test('maximum addressable payload round-trips', () {
      final payload = payloadOf(kImageMaxPayloadBytes);
      final set = buildImageChunks(
        payload: payload,
        metadata: highMeta,
        senderPrefix: senderA,
        imgId: 255,
      );
      expect(set.dataChunkCount, kImageMaxDataChunks);
      expect(set.blobs.length, kImageMaxDataChunks + 1);
      for (final blob in set.blobs) {
        expect(blob.length, lessThanOrEqualTo(kImageChunkBlobBytes));
      }
      final r = ImageReassembler();
      expect(feed(r, set.blobs.reversed.toList())!.data, payload);
    });

    test('maximum payload still recovers a single loss', () {
      final payload = payloadOf(kImageMaxPayloadBytes, seed: 5);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 254,
      );
      final blobs = <Uint8List>[
        for (var i = 0; i < set.blobs.length; i++)
          if (i != kImageMaxDataChunks - 1) set.blobs[i],
      ];
      final r = ImageReassembler();
      final result = feed(r, blobs);
      expect(result!.data, payload);
      expect(result.recoveredWithParity, isTrue);
    });

    test('img_id wraps around 255 -> 0', () {
      final alloc = ImageIdAllocator(seed: 254);
      expect(alloc.next(), 254);
      expect(alloc.next(), 255);
      expect(alloc.next(), 0);
      expect(alloc.next(), 1);
    });

    test('img_id wraparound reusing a key restarts the stream', () {
      final first = buildImageChunks(
        payload: payloadOf(460, seed: 1),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 77,
      );
      final second = payloadOf(300, seed: 2);
      final secondSet = buildImageChunks(
        payload: second,
        metadata: highMeta,
        senderPrefix: senderA,
        imgId: 77, // wrapped back onto the same id
      );
      final r = ImageReassembler();
      // Partially deliver the first image (3 data chunks), then the second
      // image (2 data chunks) arrives under the same key.
      expect(r.addChunk(first.blobs[0]).status, ImageChunkStatus.accepted);
      expect(
        r.addChunk(secondSet.blobs[0]).status,
        ImageChunkStatus.conflicting,
      );
      final done = r.addChunk(secondSet.blobs[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, second);
    });

    test('chunks bearing our own prefix are dropped as loopback', () {
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 1,
      );
      final r = ImageReassembler(selfPrefix: senderA);
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.fromSelf);
      expect(r.pendingCount, 0);
    });

    test('malformed blobs are rejected, not stored', () {
      final r = ImageReassembler();
      expect(
        r.addChunk(Uint8List.fromList(<int>[1, 2, 3])).status,
        ImageChunkStatus.malformed,
      );
      // total == 0 is illegal.
      expect(
        r.addChunk(Uint8List.fromList(<int>[0, 1, 2, 0x00, 9])).status,
        ImageChunkStatus.malformed,
      );
      // index > total is illegal.
      expect(
        r.addChunk(Uint8List.fromList(<int>[0, 1, 2, 0x32, 9])).status,
        ImageChunkStatus.malformed,
      );
      // Over-long blob cannot have come from this framing.
      expect(
        r.addChunk(Uint8List(kImageChunkBlobBytes + 1)).status,
        ImageChunkStatus.malformed,
      );
      expect(r.pendingCount, 0);
    });

    test('senderPrefixFromKey needs two bytes', () {
      expect(senderPrefixFromKey(null), isNull);
      expect(senderPrefixFromKey(<int>[0x12]), isNull);
      expect(senderPrefixFromKey(<int>[0x12, 0x34, 0x56]), 0x1234);
    });
  });

  group('protocol glue', () {
    test('CMD_SEND_CHANNEL_DATA flood frame matches the wire spec', () {
      final frame = buildSendChannelDataFrame(
        channelIndex: 0,
        dataType: dataTypeAeicImage,
        payload: Uint8List.fromList(<int>[0xAA, 0xBB]),
      );
      expect(frame, <int>[0x3E, 0x00, 0xFF, 0x1C, 0xAE, 0xAA, 0xBB]);
    });

    test('a direct-path frame inserts the path bytes before the data type', () {
      final frame = buildSendChannelDataFrame(
        channelIndex: 2,
        dataType: dataTypeAeicImage,
        payload: Uint8List.fromList(<int>[0x01]),
        pathLen: 0x02,
        path: Uint8List.fromList(<int>[0x11, 0x22]),
      );
      expect(frame, <int>[0x3E, 0x02, 0x02, 0x11, 0x22, 0x1C, 0xAE, 0x01]);
    });

    test('RESP_CODE_CHANNEL_DATA_RECV parses, snr is signed', () {
      final frame = Uint8List.fromList(<int>[
        0x1B,
        0xF8,
        0,
        0,
        3,
        0xFF,
        0x1C,
        0xAE,
        2,
        0x42,
        0x43,
      ]);
      final parsed = parseChannelDataFrame(frame)!;
      expect(parsed.snrRaw, -8);
      expect(parsed.snrDb, -2.0);
      expect(parsed.channelIndex, 3);
      expect(parsed.arrivedByFlood, isFalse);
      expect(parsed.hopCount, isNull);
      expect(parsed.dataType, dataTypeAeicImage);
      expect(parsed.payload, <int>[0x42, 0x43]);
    });

    test('a flooded frame exposes hop count and hash width', () {
      final frame = Uint8List.fromList(<int>[
        0x1B,
        0x04,
        0,
        0,
        0,
        0x43,
        0x1C,
        0xAE,
        0,
      ]);
      final parsed = parseChannelDataFrame(frame)!;
      expect(parsed.arrivedByFlood, isTrue);
      expect(parsed.hopCount, 3);
      expect(parsed.pathHashWidth, 2);
      expect(parsed.payload, isEmpty);
    });

    test('truncated or foreign frames parse as null', () {
      expect(parseChannelDataFrame(Uint8List(4)), isNull);
      expect(
        parseChannelDataFrame(
          Uint8List.fromList(<int>[0x1B, 0, 0, 0, 0, 0xFF, 0x1C, 0xAE, 5, 1]),
        ),
        isNull,
      );
      expect(
        parseChannelDataFrame(
          Uint8List.fromList(<int>[0x10, 0, 0, 0, 0, 0xFF, 0x1C, 0xAE, 0]),
        ),
        isNull,
      );
    });

    test(
      'transport sends chunks strictly sequentially and reassembles',
      () async {
        final sent = <Uint8List>[];
        var inFlight = 0;
        var maxInFlight = 0;
        final received = <ImageReassemblyResult>[];
        final rxWithCallback = ImageReassembler(
          selfPrefix: senderB,
          onImage: received.add,
        );

        final tx = ImageChunkTransport(
          senderPrefix: senderA,
          reassembler: rxWithCallback,
          idAllocator: ImageIdAllocator(seed: 60),
          send: (blob, channelIndex) async {
            inFlight++;
            maxInFlight = maxInFlight > inFlight ? maxInFlight : inFlight;
            await Future<void>.delayed(const Duration(milliseconds: 1));
            sent.add(blob);
            inFlight--;
          },
        );

        final payload = payloadOf(460, seed: 9);
        final set = await tx.sendImage(
          payload: payload,
          metadata: highMeta,
          channelIndex: 1,
        );
        expect(set.imgId, 60);
        expect(sent.length, 4);
        expect(maxInFlight, 1);

        // Loop the blobs back through the receive path as real frames.
        for (final blob in sent) {
          final frame = BytesBuilder()
            ..add(<int>[0x1B, 0x10, 0, 0, 1, 0xFF, 0x1C, 0xAE, blob.length])
            ..add(blob);
          tx.handleFrame(frame.toBytes());
        }
        expect(received.length, 1);
        expect(received.single.data, payload);
        expect(received.single.key.channelIndex, 1);
      },
    );

    test('handleFrame ignores other data types and other frames', () {
      final rx = ImageReassembler();
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: rx,
        send: (_, _) async {},
      );
      expect(
        tx.handleFrame(
          Uint8List.fromList(<int>[0x1B, 0, 0, 0, 0, 0xFF, 0x01, 0x00, 0]),
        ),
        isNull,
      );
      expect(tx.handleFrame(Uint8List.fromList(<int>[0x00])), isNull);
      expect(rx.pendingCount, 0);
    });

    test('concurrent sendImage calls do not interleave on the wire', () async {
      final order = <String>[];
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: ImageReassembler(),
        idAllocator: ImageIdAllocator(seed: 100),
        send: (blob, _) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          order.add('${blob[2]}:${(blob[3] >> 4) & 0x0F}');
        },
      );
      final a = tx.sendImage(payload: payloadOf(300), metadata: stdMeta);
      final b = tx.sendImage(payload: payloadOf(300), metadata: stdMeta);
      await Future.wait(<Future<ImageChunkSet>>[a, b]);
      expect(order, <String>[
        '100:0',
        '100:1',
        '100:2',
        '101:0',
        '101:1',
        '101:2',
      ]);
    });
  });

  group('regressions confirmed by adversarial review', () {
    // PROBE A: an image completes; a DIFFERENT image reusing the same img_id
    // arrives within the TTL. The recently-completed shortcut used to report
    // every chunk of it as `duplicate`, so onImage never fired, onFailed never
    // fired, and the image was lost with no diagnostic. ImageIdAllocator seeds
    // from Random().nextInt(256), so a restart really can re-roll a live id.
    test('a new image reusing a just-completed img_id is not swallowed', () {
      final delivered = <ImageReassemblyResult>[];
      final failed = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onImage: delivered.add, onFailed: failed.add);

      final first = buildImageChunks(
        payload: payloadOf(200, seed: 1),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 42,
      );
      feed(r, first.blobs);
      expect(delivered, hasLength(1), reason: 'first image should complete');

      // Same sender, same img_id, different content and a different length.
      final second = buildImageChunks(
        payload: payloadOf(300, seed: 99),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 42,
      );
      feed(r, second.blobs);

      expect(delivered, hasLength(2), reason: 'second image must not be lost');
      expect(delivered.last.data, equals(payloadOf(300, seed: 99)));
      expect(failed, isEmpty);
    });

    test('a genuine re-send of a delivered chunk is still a duplicate', () {
      final delivered = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: delivered.add);
      final set = buildImageChunks(
        payload: payloadOf(200, seed: 1),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 42,
      );
      feed(r, set.blobs);
      expect(delivered, hasLength(1));

      // Replay every blob verbatim: none may open a new stream.
      for (final blob in set.blobs) {
        final outcome = r.addChunk(blob, channelIndex: 0);
        expect(outcome.status, ImageChunkStatus.duplicate);
      }
      expect(delivered, hasLength(1));
      expect(r.pendingCount, 0);
    });

    // PROBE B/C: a flipped bit in the parity length byte used to yield a
    // silently TRUNCATED image reported as `completed`. Only the last data
    // chunk may be short.
    test(
      'corrupt parity length is rejected rather than silently truncating',
      () {
        for (final payloadLen in [300, 400]) {
          final set = buildImageChunks(
            payload: payloadOf(payloadLen, seed: 3),
            metadata: stdMeta,
            senderPrefix: senderA,
            imgId: 7,
          );
          final data = set.blobs.sublist(0, set.dataChunkCount);
          final parity = Uint8List.fromList(set.blobs.last);
          // Corrupt the len_xor byte (first body byte, just after the header).
          parity[kImageChunkHeaderBytes] ^= 0x02;

          final delivered = <ImageReassemblyResult>[];
          final r = ImageReassembler(onImage: delivered.add);
          // Drop a NON-FINAL chunk (index 1 of >=3, else index 0) and supply
          // the corrupted parity.
          final dropIndex = data.length >= 3 ? 1 : 0;
          final kept = <Uint8List>[
            for (var i = 0; i < data.length; i++)
              if (i != dropIndex) data[i],
            parity,
          ];
          feed(r, kept);
          expect(
            delivered,
            isEmpty,
            reason: 'payload $payloadLen: truncated recovery must not complete',
          );
        }
      },
    );

    test('parity still recovers a genuinely lost non-final chunk', () {
      final payload = payloadOf(400, seed: 5);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 8,
      );
      final data = set.blobs.sublist(0, set.dataChunkCount);
      expect(data.length, greaterThanOrEqualTo(3));

      final delivered = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: delivered.add);
      feed(r, <Uint8List>[
        for (var i = 0; i < data.length; i++)
          if (i != 1) data[i],
        set.blobs.last,
      ]);
      expect(delivered, hasLength(1));
      expect(delivered.single.data, equals(payload));
      expect(delivered.single.recoveredWithParity, isTrue);
    });
  });

  group('completed-image map is capped', () {
    /// A lone parity chunk of a `total == 1` image completes that image by
    /// itself — one packet, one remembered entry. That is the amplification the
    /// cap exists to bound.
    List<Uint8List> loneParity(int imgId) => buildImageChunks(
      payload: payloadOf(20, seed: imgId),
      metadata: stdMeta,
      senderPrefix: senderA,
      imgId: imgId,
    ).blobs;

    test('one packet per img_id can complete an image (the attack)', () {
      final r = ImageReassembler();
      final done = r.addChunk(loneParity(1)[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(r.completedCount, 1);
      expect(r.pendingCount, 0);
    });

    test(
      'the map never exceeds maxCompletedStreams and evicts oldest first',
      () {
        final start = DateTime(2026, 3, 3);
        final r = ImageReassembler(maxCompletedStreams: 3);
        for (var i = 0; i < 20; i++) {
          r.addChunk(
            loneParity(100 + i)[1],
            now: start.add(Duration(seconds: i)),
          );
          expect(r.completedCount, lessThanOrEqualTo(3));
        }
        expect(r.completedCount, 3);
        expect(r.completedKeys.map((k) => k.imgId).toList()..sort(), <int>[
          117,
          118,
          119,
        ]);
      },
    );

    test('default cap matches the pending cap', () {
      final start = DateTime(2026, 3, 4);
      final r = ImageReassembler();
      expect(r.maxCompletedStreams, 8);
      expect(r.maxConcurrentStreams, 8);
      for (var i = 0; i < 30; i++) {
        r.addChunk(loneParity(i)[1], now: start.add(Duration(seconds: i)));
      }
      expect(r.completedCount, 8);
    });

    test('capping does not break straggler suppression for recent images', () {
      final start = DateTime(2026, 3, 5);
      final r = ImageReassembler(maxCompletedStreams: 2);
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 200,
      );
      feed(r, set.blobs.sublist(0, 2), now: start);
      // Trailing parity of the newest image is still recognised as a duplicate.
      expect(
        r.addChunk(set.blobs[2], now: start).status,
        ImageChunkStatus.duplicate,
      );
      expect(r.pendingCount, 0);
    });

    test('clear() empties the completed map too', () {
      final r = ImageReassembler();
      r.addChunk(loneParity(9)[1]);
      expect(r.completedCount, 1);
      r.clear();
      expect(r.completedCount, 0);
    });
  });

  group('rate point wire codes', () {
    test('the chunk-0 nibble is not the AeicRatePoint ordinal', () {
      // The trap: AeicRatePoint.wireValue is 0..4 and selects a MODEL; ft32 is 4
      // there but 0 in the chunk-0 metadata nibble. If the two were ever
      // conflated, ft32 would go on air as 4.
      expect(AeicRatePoint.values.length, 5);
      expect(AeicRatePoint.ft32.wireValue, 4);
      expect(
        aeicRatePointForUi(ImageCodecRatePoint.standard),
        AeicRatePoint.ft32,
      );
      expect(
        imageRateWireCode(ImageCodecRatePoint.standard),
        kImageRateWireStandard,
      );
      expect(kImageRateWireStandard, 0);
      expect(kImageRateWireHigh, 1);
      expect(
        const ImageStreamMetadata(rate: ImageCodecRatePoint.standard).encode() &
            0x0F,
        0,
      );
      // ...and an AeicRatePoint ordinal on the wire is refused outright.
      expect(imageRatePointFromWireCode(AeicRatePoint.ft32.wireValue), isNull);
      expect(imageRatePointFromWireCode(AeicRatePoint.ft8.wireValue), isNull);
    });

    test('every wire code round-trips and unknown codes are null', () {
      for (final rate in ImageCodecRatePoint.values) {
        final code = imageRateWireCode(rate);
        expect(code, lessThan(kImageRateWireCodeCount));
        expect(imageRatePointFromWireCode(code), rate);
      }
      expect(
        ImageCodecRatePoint.values.map(imageRateWireCode).toSet(),
        hasLength(ImageCodecRatePoint.values.length),
      );
      for (var code = kImageRateWireCodeCount; code < 16; code++) {
        expect(imageRatePointFromWireCode(code), isNull, reason: 'code $code');
      }
    });

    test('an unknown rate code fails cleanly instead of decoding wrong', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 80,
      );
      // Overwrite the 2-bit rate field with 2 — a code no shipping build
      // emits. Without an explicit rate table this would have decoded as a
      // valid rate point and fed the wrong model.
      final bad = Uint8List.fromList(set.blobs[0]);
      bad[kImageChunkHeaderBytes] = (bad[kImageChunkHeaderBytes] & 0xFC) | 0x02;

      final delivered = <ImageReassemblyResult>[];
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(
        onImage: delivered.add,
        onFailed: failures.add,
      );
      expect(r.addChunk(bad).status, ImageChunkStatus.accepted);
      final done = r.addChunk(set.blobs[1]);
      expect(done.status, ImageChunkStatus.unsupportedFormat);
      expect(done.result, isNull);
      expect(delivered, isEmpty);
      expect(failures, hasLength(1));
      expect(
        failures.single.reason,
        ImageReassemblyFailureReason.unsupportedFormat,
      );
      expect(failures.single.isCorrupt, isTrue);
      expect(r.pendingCount, 0);
    });

    test('a reserved rate code fails the same way through reassembly', () {
      // Resolution is a closed 2-bit field now, so it cannot carry an unknown
      // value; the reserved RATE codes are what a future format must use to be
      // rejected rather than misread. This asserts the rejection survives the
      // whole reassembly path, not just ImageStreamMetadata.decode.
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: stdMeta,
        senderPrefix: senderA,
        imgId: 81,
      );
      final bad = Uint8List.fromList(set.blobs[0]);
      bad[kImageChunkHeaderBytes] =
          (bad[kImageChunkHeaderBytes] & 0xFC) | 0x03; // reserved rate code 3
      final r = ImageReassembler();
      r.addChunk(bad);
      expect(
        r.addChunk(set.blobs[1]).status,
        ImageChunkStatus.unsupportedFormat,
      );
    });
  });

  group('metadata byte: aspect ratio', () {
    // The codec stretches the WHOLE frame into 512x512 rather than cropping, so
    // nothing outside the frame is lost — but the stretch is not invertible
    // from pixels alone. The sender names the source shape in spare bits of the
    // metadata byte and the receiver letterboxes back.
    test('round-trips every aspect code with rate and resolution intact', () {
      for (var code = 0; code < kImageAspectCodes.length; code++) {
        final m = ImageStreamMetadata(
          rate: ImageCodecRatePoint.standard,
          squareSize: 512,
          aspectCode: code,
        );
        final decoded = ImageStreamMetadata.decode(m.encode());
        expect(decoded, isNotNull, reason: 'aspect code $code');
        expect(decoded!.aspectCode, code);
        expect(decoded.rate, ImageCodecRatePoint.standard);
        expect(decoded.squareSize, 512);
      }
    });

    test('the whole byte still fits in 8 bits for every legal combination', () {
      for (final size in kImageResolutionCodes) {
        for (final rate in ImageCodecRatePoint.values) {
          for (var code = 0; code < kImageAspectCodes.length; code++) {
            final byte = ImageStreamMetadata(
              rate: rate,
              squareSize: size,
              aspectCode: code,
            ).encode();
            expect(byte, inInclusiveRange(0, 255));
            final back = ImageStreamMetadata.decode(byte)!;
            expect(back.squareSize, size);
            expect(back.rate, rate);
            expect(back.aspectCode, code);
          }
        }
      }
    });

    test('common phone shapes snap exactly, not approximately', () {
      expect(imageAspectCodeFor(4032, 3024), 2); // 4:3
      expect(imageAspectCodeFor(3024, 4032), 9); // 3:4
      expect(imageAspectCodeFor(1920, 1080), 5); // 16:9
      expect(imageAspectCodeFor(1080, 1920), 12); // 9:16
      expect(imageAspectCodeFor(1000, 1000), 0); // 1:1
      // A ratio between table entries still picks the nearest.
      expect(kImageAspectCodes[imageAspectCodeFor(1500, 1000)], <int>[3, 2]);
    });

    test('extremes and nonsense degrade to unknown, not a wrong shape', () {
      expect(imageAspectCodeFor(4000, 500), kImageAspectUnknown); // 8:1 pano
      expect(imageAspectCodeFor(500, 4000), kImageAspectUnknown);
      expect(imageAspectCodeFor(0, 100), kImageAspectUnknown);
      expect(imageAspectCodeFor(100, 0), kImageAspectUnknown);
      expect(imageAspectCodeFor(-4, 3), kImageAspectUnknown);
      final m = ImageStreamMetadata(
        rate: ImageCodecRatePoint.standard,
        aspectCode: kImageAspectUnknown,
      );
      expect(m.isSquare, isTrue);
      expect(m.aspectRatio, 1.0);
    });

    test('aspectRatio reconstructs the source shape', () {
      final m = ImageStreamMetadata(
        rate: ImageCodecRatePoint.standard,
        aspectCode: imageAspectCodeFor(1920, 1080),
      );
      expect(m.aspectRatio, closeTo(16 / 9, 1e-9));
      expect(m.isSquare, isFalse);
    });
  });
}
