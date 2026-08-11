import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/services/received_image_blob_store_io.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';

/// Deterministic stand-in for `ImageCodecService`.
class _FakeDecoder implements ReceivedImageDecoder {
  @override
  ImageCodecAvailability availability;

  @override
  bool isBusy;

  /// null  -> `decodeBitstream` returns null (codec cannot decode at all)
  /// 'fail'-> returns a result with status failed
  /// 'throw'-> throws
  /// 'ok'  -> returns a PNG
  String mode;

  Uint8List png;
  int calls = 0;
  int cancels = 0;

  /// Concurrency witness: a decode peaks at ~2.16 GiB, so `maxConcurrent > 1`
  /// is an out-of-memory kill on a phone, not a performance note.
  int _inFlight = 0;
  int maxConcurrent = 0;

  /// Forces a real suspension inside the decode so a second caller has a
  /// chance to overlap.
  Duration delay = Duration.zero;

  _FakeDecoder({
    this.availability = ImageCodecAvailability.ready,
    this.isBusy = false,
    this.mode = 'ok',
    Uint8List? png,
  }) : png = png ?? Uint8List.fromList(List<int>.filled(4096, 7));

  @override
  Future<ImageCodecResult?> decodeBitstream({
    required Uint8List bitstream,
    required AeicRatePoint ratePoint,
    required int resolution,
  }) async {
    calls++;
    _inFlight++;
    if (_inFlight > maxConcurrent) maxConcurrent = _inFlight;
    try {
      return await _run(ratePoint, resolution);
    } finally {
      _inFlight--;
    }
  }

  Future<ImageCodecResult?> _run(
    AeicRatePoint ratePoint,
    int resolution,
  ) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    switch (mode) {
      case 'null':
        return null;
      case 'throw':
        throw StateError('decoder exploded');
      case 'fail':
        return ImageCodecResult(
          ratePoint: ratePoint,
          resolution: resolution,
          durationMs: 5,
          status: ImageCodecStatus.failed,
        );
      default:
        return ImageCodecResult(
          ratePoint: ratePoint,
          resolution: resolution,
          durationMs: 11,
          status: ImageCodecStatus.completed,
          pngBytes: png,
        );
    }
  }

  @override
  void cancelCodecJob() => cancels++;
}

const int kSender = 0x1a2b;
const int kSelf = 0xbeef;

Uint8List _payload(int length, [int seed = 0]) {
  return Uint8List.fromList(
    List<int>.generate(length, (i) => (i * 31 + seed) & 0xFF),
  );
}

typedef _Rig = ({
  ReceivedImageStore store,
  _FakeDecoder decoder,
  InMemoryReceivedImageBlobStore blobs,
  ImageReassembler reassembler,
  DateTime Function() clock,
  void Function(Duration) advance,
});

/// Builds a store wired to a fake decoder, an in-memory blob store and a
/// reassembler that all share one injected clock.
_Rig _build({
  int burstCap = 3,
  int maxImages = 200,
  int maxBytes = 64 * 1024 * 1024,
  Duration maxAge = const Duration(days: 30),
  _FakeDecoder? decoder,
  InMemoryReceivedImageBlobStore? blobs,
  bool processAutomatically = true,
}) {
  var now = DateTime.utc(2026, 1, 1);
  final dec = decoder ?? _FakeDecoder();
  final blobStore = blobs ?? InMemoryReceivedImageBlobStore();
  final reassembler = ImageReassembler(selfPrefix: kSelf, clock: () => now);
  final store = ReceivedImageStore(
    blobs: blobStore,
    decoder: dec,
    processAutomatically: processAutomatically,
    burstCap: burstCap,
    maxImages: maxImages,
    maxBytes: maxBytes,
    maxAge: maxAge,
    clock: () => now,
  );
  return (
    store: store,
    decoder: dec,
    blobs: blobStore,
    reassembler: reassembler,
    clock: () => now,
    advance: (Duration d) => now = now.add(d),
  );
}

void main() {
  group('ReceivedImageRef', () {
    test('round-trips a stream id', () {
      final id = ReceivedImageRef.streamIdFor(
        senderPrefix: 0x1a2b,
        imgId: 7,
        firstSeen: DateTime.fromMillisecondsSinceEpoch(0x693F21 * 1000),
      );
      expect(
        id,
        '1a2b07'
        '00693f21',
      );
      expect(id.length, 14);
      expect(ReceivedImageRef.parse(ReceivedImageRef.encode(id)), id);
    });

    test('rejects everything that is not an image sentinel', () {
      expect(ReceivedImageRef.parse('g:abc123'), isNull);
      expect(ReceivedImageRef.parse('hello world'), isNull);
      expect(ReceivedImageRef.parse('aeic:1:short'), isNull);
      expect(ReceivedImageRef.parse('aeic:1:1A2B0700693F21'), isNull);
      expect(ReceivedImageRef.parse('aeic:2:1a2b0700693f21'), isNull);
      expect(ReceivedImageRef.parse('@[Bob] hi'), isNull);
      expect(
        ReceivedImageRef.parse('  aeic:1:1a2b0700693f21 '),
        '1a2b0700693f21',
      );
    });
  });

  group('intake and state machine', () {
    test('one-chunk image goes receiving -> reassembled -> decoded', () async {
      final h = _build();
      final payload = _payload(140);
      final set = buildImageChunks(
        payload: payload,
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 9,
      );
      expect(set.dataChunkCount, 1);

      final outcome = h.reassembler.addChunk(set.blobs[0], channelIndex: 3);
      final entry = await h.store.handleOutcome(outcome, channelIndex: 3);
      expect(entry, isNotNull);
      expect(entry!.state, ReceivedImageState.reassembled);
      expect(entry.rate, AeicRatePoint.ft32);
      expect(entry.metadataAssumed, isFalse);
      expect(
        h.blobs.hasBitstream(entry.streamId),
        isTrue,
        reason: 'bitstream must be written before the state changes',
      );

      await h.store.settle();
      final decoded = h.store.entryFor(entry.streamId)!;
      expect(decoded.state, ReceivedImageState.decoded);
      expect(decoded.synthesized, isTrue);
      expect(decoded.decodeMs, 11);
      expect(await h.store.ensurePng(entry.streamId), isNotNull);
      expect(h.decoder.calls, 1);
    });

    test('two-chunk image reports 1 of 2 while incomplete', () async {
      final h = _build();
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      expect(set.dataChunkCount, 2);

      final first = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      expect(first!.state, ReceivedImageState.receiving);
      expect(first.receivedChunks, 1);
      expect(first.totalChunks, 2);

      final second = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[1], channelIndex: 3),
        channelIndex: 3,
      );
      expect(
        second!.streamId,
        first.streamId,
        reason: 'the sentinel must not change as chunks arrive',
      );
      expect(second.state, ReceivedImageState.reassembled);
      await h.store.settle();
      expect(
        h.store.entryFor(first.streamId)!.state,
        ReceivedImageState.decoded,
      );
    });

    test('duplicate delivery does not double-count chunks', () async {
      final h = _build();
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      final first = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      // Same blob three more times (repeaters flood).
      for (var i = 0; i < 3; i++) {
        await h.store.handleOutcome(
          h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
          channelIndex: 3,
        );
      }
      final entry = h.store.entryFor(first!.streamId)!;
      expect(entry.receivedChunks, 1);
      expect(entry.state, ReceivedImageState.receiving);
      expect(h.store.entries.length, 1);
    });

    test('parity chunks never count towards progress', () async {
      final h = _build();
      // Three data chunks: chunk 0 + parity leaves one hole, so the image
      // cannot complete and we can observe the progress count.
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + kImageChunkCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      expect(set.dataChunkCount, 3);
      expect(set.hasParity, isTrue);
      // Parity first, then chunk 0: 1 data chunk received, not 2.
      await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs.last, channelIndex: 3),
        channelIndex: 3,
      );
      final entry = h.store.entries.single;
      expect(entry.receivedChunks, 0);
      final after = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      expect(after!.receivedChunks, 1);
      expect(after.state, ReceivedImageState.receiving);
    });

    test('parity recovery still lands on decoded', () async {
      final h = _build();
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      // Drop chunk 1, deliver 0 + parity.
      await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      final entry = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs.last, channelIndex: 3),
        channelIndex: 3,
      );
      expect(entry!.state, ReceivedImageState.reassembled);
      expect(entry.recoveredWithParity, isTrue);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoded,
      );
    });

    test('loopback and malformed blobs create nothing', () async {
      final h = _build();
      final own = buildImageChunks(
        payload: _payload(120),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSelf,
        imgId: 1,
      );
      await h.store.handleOutcome(
        h.reassembler.addChunk(own.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      await h.store.handleOutcome(
        h.reassembler.addChunk(Uint8List.fromList([1, 2]), channelIndex: 3),
        channelIndex: 3,
      );
      expect(h.store.entries, isEmpty);
    });

    test('TTL expiry moves a partial image to failedIncomplete', () async {
      final h = _build();
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      final entry = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      h.advance(kImageReassemblyTtl + const Duration(seconds: 1));
      final failures = <ImageReassemblyFailure>[];
      final expiring = ImageReassembler(
        selfPrefix: kSelf,
        onFailed: failures.add,
      );
      // Rebuild the failure the transport would emit for this stream.
      failures.add(
        ImageReassemblyFailure(
          key: entry!.key,
          total: 2,
          receivedDataChunks: 1,
          hadParity: false,
          firstSeen: entry.firstSeen,
          expiredAt: h.clock(),
        ),
      );
      expiring.clear();
      await h.store.handleFailure(failures.single);
      final failed = h.store.entryFor(entry.streamId)!;
      expect(failed.state, ReceivedImageState.failedIncomplete);
      expect(failed.receivedChunks, 1);
      expect(failed.totalChunks, 2);
      expect(failed.canRetryDecode, isFalse);
    });

    test('a corrupt-payload failure reports corrupt, not incomplete', () async {
      final h = _build();
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      final entry = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      await h.store.handleFailure(
        ImageReassemblyFailure(
          key: entry!.key,
          total: 2,
          receivedDataChunks: 2,
          hadParity: true,
          firstSeen: entry.firstSeen,
          expiredAt: h.clock(),
          reason: ImageReassemblyFailureReason.unsupportedFormat,
        ),
      );
      final failed = h.store.entryFor(entry.streamId)!;
      expect(failed.state, ReceivedImageState.failedCorrupt);
      expect(failed.pngStored, isFalse);
      expect(await h.store.ensurePng(entry.streamId), isNull);
    });
  });

  group('decode outcomes never present as decoded', () {
    test('decoder failure -> failedCorrupt and no pixels', () async {
      final h = _build(decoder: _FakeDecoder(mode: 'fail'));
      final entry = await _completeOne(h);
      await h.store.settle();
      final after = h.store.entryFor(entry.streamId)!;
      expect(after.state, ReceivedImageState.failedCorrupt);
      expect(after.pngStored, isFalse);
      expect(after.pngBytes, isNull);
      expect(await h.store.ensurePng(entry.streamId), isNull);
      // Retryable, because the bitstream survived.
      expect(after.canRetryDecode, isTrue);
    });

    test('decoder throw -> failedCorrupt', () async {
      final h = _build(decoder: _FakeDecoder(mode: 'throw'));
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.failedCorrupt,
      );
    });

    test('decodeBitstream null -> decoderUnavailable', () async {
      final h = _build(decoder: _FakeDecoder(mode: 'null'));
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoderUnavailable,
      );
    });

    test('availability != ready at dequeue -> decoderUnavailable, and the '
        'image decodes once the codec comes back', () async {
      final decoder = _FakeDecoder(
        availability: ImageCodecAvailability.disabled,
      );
      final h = _build(decoder: decoder);
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoderUnavailable,
      );
      expect(decoder.calls, 0);

      decoder.availability = ImageCodecAvailability.ready;
      h.store.notifyDecoderChanged();
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoded,
      );
    });

    test('a busy codec parks the queue instead of failing it', () async {
      final decoder = _FakeDecoder(isBusy: true);
      final h = _build(decoder: decoder);
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.reassembled,
      );
      expect(h.store.decodeQueue, [entry.streamId]);
      expect(decoder.calls, 0);

      decoder.isBusy = false;
      h.store.notifyDecoderChanged();
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoded,
      );
    });

    test('retry after failure re-runs the decoder', () async {
      final decoder = _FakeDecoder(mode: 'fail');
      final h = _build(decoder: decoder);
      final entry = await _completeOne(h);
      await h.store.settle();
      decoder.mode = 'ok';
      await h.store.requestDecode(entry.streamId);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoded,
      );
      expect(decoder.calls, 2);
    });

    test('failedIncomplete is never retryable', () async {
      final h = _build();
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 4,
      );
      final entry = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      await h.store.handleFailure(
        ImageReassemblyFailure(
          key: entry!.key,
          total: 2,
          receivedDataChunks: 1,
          hadParity: false,
          firstSeen: entry.firstSeen,
          expiredAt: h.clock(),
        ),
      );
      await h.store.requestDecode(entry.streamId);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.failedIncomplete,
      );
      expect(h.decoder.calls, 0);
    });
  });

  group('decode gates', () {
    test('backgrounded: nothing decodes until the app resumes', () async {
      final h = _build();
      h.store.setForeground(false);
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(h.decoder.calls, 0);
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.reassembled,
      );
      h.store.setForeground(true);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoded,
      );
    });

    test('burst cap parks all but the newest few behind a tap', () async {
      final h = _build(burstCap: 3);
      h.store.setForeground(false);
      final ids = <String>[];
      for (var i = 0; i < 5; i++) {
        ids.add((await _completeOne(h, imgId: 20 + i, seed: i)).streamId);
        h.advance(const Duration(seconds: 2));
      }
      expect(h.store.decodeQueue.length, 3);
      expect(h.store.entryFor(ids[0])!.needsManualDecode, isTrue);
      expect(h.store.entryFor(ids[1])!.needsManualDecode, isTrue);
      expect(h.store.entryFor(ids[4])!.needsManualDecode, isFalse);

      h.store.setForeground(true);
      await h.store.settle();
      expect(h.decoder.calls, 3);
      expect(h.store.entryFor(ids[0])!.state, ReceivedImageState.reassembled);
      expect(h.store.entryFor(ids[4])!.state, ReceivedImageState.decoded);

      // A tap on a parked image decodes it.
      await h.store.requestDecode(ids[0]);
      await h.store.settle();
      expect(h.store.entryFor(ids[0])!.state, ReceivedImageState.decoded);
    });

    test('memory pressure cancels and parks, never fails', () async {
      final h = _build();
      h.store.setForeground(false);
      final entry = await _completeOne(h);
      await h.store.handleMemoryPressure();
      expect(h.decoder.cancels, greaterThanOrEqualTo(1));
      expect(h.store.decodeQueue, isEmpty);
      final after = h.store.entryFor(entry.streamId)!;
      expect(after.state, ReceivedImageState.reassembled);
      expect(after.needsManualDecode, isTrue);
    });
  });

  group('eviction', () {
    test(
      'byte budget drops the oldest PNG first and keeps the bitstream',
      () async {
        final decoder = _FakeDecoder(
          png: Uint8List.fromList(List<int>.filled(1000, 3)),
        );
        final h = _build(decoder: decoder, maxBytes: 2500);
        final ids = <String>[];
        for (var i = 0; i < 3; i++) {
          final entry = await _completeOne(h, imgId: 40 + i, seed: i);
          await h.store.settle();
          ids.add(entry.streamId);
          h.advance(const Duration(seconds: 5));
        }
        // 3 x 1000 B PNG > 2500 B, so the oldest PNG must have gone.
        expect(h.store.entryFor(ids[0])!.state, ReceivedImageState.evicted);
        expect(h.store.entryFor(ids[0])!.pngStored, isFalse);
        expect(h.blobs.hasPng(ids[0]), isFalse);
        expect(
          h.blobs.hasBitstream(ids[0]),
          isTrue,
          reason: 'a ~156 B bitstream is cheap; keep it so we can re-decode',
        );
        expect(h.store.entryFor(ids[0])!.canRetryDecode, isTrue);
        expect(h.store.entryFor(ids[2])!.state, ReceivedImageState.decoded);
        expect(h.store.totalBytes, lessThanOrEqualTo(2500));

        // "Decode again" works off the surviving bitstream, and the image we just
        // decoded is never the budget's own victim (that would thrash forever).
        await h.store.requestDecode(ids[0]);
        await h.store.settle();
        expect(h.store.entryFor(ids[0])!.state, ReceivedImageState.decoded);
        expect(h.store.entryFor(ids[1])!.state, ReceivedImageState.evicted);
        expect(h.store.totalBytes, lessThanOrEqualTo(2500));
      },
    );

    test('image-count budget evicts oldest first', () async {
      final h = _build(maxImages: 2);
      final ids = <String>[];
      for (var i = 0; i < 4; i++) {
        final entry = await _completeOne(h, imgId: 60 + i, seed: i);
        await h.store.settle();
        ids.add(entry.streamId);
        h.advance(const Duration(seconds: 5));
      }
      expect(h.store.storedImageCount, lessThanOrEqualTo(2));
      expect(h.store.entryFor(ids[0])!.state, ReceivedImageState.evicted);
      expect(h.store.entryFor(ids[1])!.state, ReceivedImageState.evicted);
      expect(h.store.entryFor(ids[3])!.state, ReceivedImageState.decoded);
    });

    test('age budget removes both files', () async {
      final h = _build(maxAge: const Duration(minutes: 10));
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(
        h.store.entryFor(entry.streamId)!.state,
        ReceivedImageState.decoded,
      );
      h.advance(const Duration(minutes: 11));
      final evicted = await h.store.evictToBudget();
      expect(evicted, contains(entry.streamId));
      final after = h.store.entryFor(entry.streamId)!;
      expect(after.state, ReceivedImageState.evicted);
      expect(after.canRetryDecode, isFalse);
      expect(h.blobs.hasBitstream(entry.streamId), isFalse);
      expect(h.blobs.hasPng(entry.streamId), isFalse);
    });

    test('deleteImage reaps all three files', () async {
      final h = _build();
      final entry = await _completeOne(h);
      await h.store.settle();
      expect(h.blobs.hasSidecar(entry.streamId), isTrue);
      await h.store.deleteImage(entry.streamId);
      expect(h.store.entryFor(entry.streamId), isNull);
      expect(h.blobs.hasSidecar(entry.streamId), isFalse);
      expect(h.blobs.hasPng(entry.streamId), isFalse);
      expect(h.blobs.hasBitstream(entry.streamId), isFalse);
    });
  });

  group('persistence and startup repair', () {
    test('sidecars survive a restart and decoded images reload', () async {
      final blobs = InMemoryReceivedImageBlobStore();
      final h = _build(blobs: blobs);
      final entry = await _completeOne(h);
      await h.store.settle();

      final reborn = ReceivedImageStore(
        blobs: blobs,
        decoder: _FakeDecoder(),
        clock: h.clock,
      );
      await reborn.load();
      final loaded = reborn.entryFor(entry.streamId)!;
      expect(loaded.state, ReceivedImageState.decoded);
      expect(loaded.pngBytes, isNull, reason: 'pixels are read lazily');
      expect(await reborn.ensurePng(entry.streamId), isNotNull);
      reborn.dispose();
    });

    test('receiving and decoding are repaired on load', () async {
      final blobs = InMemoryReceivedImageBlobStore();
      const receivingId = 'aaaa010000000001';
      await blobs.writeSidecar(
        'partial',
        jsonEncode({
          'streamId': 'partial00000001',
          'senderPrefix': 1,
          'imgId': 1,
          'channelIndex': 0,
          'firstSeenMs': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
          'state': 'receiving',
          'receivedChunks': 1,
          'totalChunks': 2,
        }),
      );
      await blobs.writeSidecar(
        'midDecode',
        jsonEncode({
          'streamId': 'midDecode',
          'senderPrefix': 2,
          'imgId': 2,
          'channelIndex': 0,
          'firstSeenMs': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
          'state': 'decoding',
          'receivedChunks': 1,
          'totalChunks': 1,
        }),
      );
      await blobs.writeBitstream('midDecode', _payload(150));
      await blobs.writeSidecar(
        'lostPng',
        jsonEncode({
          'streamId': 'lostPng',
          'senderPrefix': 3,
          'imgId': 3,
          'channelIndex': 0,
          'firstSeenMs': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
          'state': 'decoded',
          'receivedChunks': 1,
          'totalChunks': 1,
        }),
      );
      expect(receivingId.length, 16); // sanity: not a valid sentinel id

      final store = ReceivedImageStore(
        blobs: blobs,
        decoder: _FakeDecoder(availability: ImageCodecAvailability.disabled),
        clock: () => DateTime.utc(2026, 1, 1, 1),
      );
      await store.load();
      expect(
        store.entryFor('partial00000001')!.state,
        ReceivedImageState.failedIncomplete,
      );
      expect(
        store.entryFor('midDecode')!.state,
        ReceivedImageState.reassembled,
      );
      expect(store.entryFor('lostPng')!.state, ReceivedImageState.evicted);
      store.dispose();
    });
  });

  group('outgoing', () {
    test('registerOutgoing is decoded, not synthesized', () async {
      final h = _build();
      final entry = await h.store.registerOutgoing(
        channelIndex: 1,
        senderPrefix: kSelf,
        imgId: 3,
        previewPng: Uint8List.fromList(List<int>.filled(64, 1)),
        rate: AeicRatePoint.ft32,
        chunkCount: 2,
      );
      expect(entry.state, ReceivedImageState.decoded);
      expect(entry.isOutgoing, isTrue);
      expect(entry.synthesized, isFalse);
      expect(await h.store.ensurePng(entry.streamId), isNotNull);
      expect(h.decoder.calls, 0);
    });
  });

  group('processAutomatically (tap to process)', () {
    test('an arrival is parked, not decoded, and a tap still works', () async {
      final h = _build(processAutomatically: false);
      final entry = await _completeOne(h);
      await h.store.settle();

      expect(entry.state, ReceivedImageState.reassembled);
      expect(entry.needsManualDecode, isTrue);
      expect(h.store.decodeQueue, isEmpty);
      expect(
        h.decoder.calls,
        0,
        reason: 'a radio packet must never start a 2.16 GiB decode by itself',
      );
      // Everything the placeholder card needs is already on the entry.
      expect(entry.senderPrefix, kSender);
      expect(entry.bitstreamByteCount, greaterThan(0));
      expect(entry.receivedChunks, 1);
      expect(entry.totalChunks, 1);
      expect(h.blobs.hasBitstream(entry.streamId), isTrue);

      await h.store.requestDecode(entry.streamId);
      await h.store.settle();
      final after = h.store.entryFor(entry.streamId)!;
      expect(after.state, ReceivedImageState.decoded);
      expect(after.needsManualDecode, isFalse);
      expect(h.decoder.calls, 1);
    });

    test(
      'a finished model download does not decode the whole backlog',
      () async {
        final decoder = _FakeDecoder(
          availability: ImageCodecAvailability.disabled,
        );
        final h = _build(decoder: decoder, processAutomatically: false);
        final ids = <String>[];
        for (var i = 0; i < 4; i++) {
          ids.add((await _completeOne(h, imgId: 80 + i, seed: i)).streamId);
          h.advance(const Duration(seconds: 2));
        }
        // The model lands.
        decoder.availability = ImageCodecAvailability.ready;
        h.store.notifyDecoderChanged();
        await h.store.settle();
        expect(decoder.calls, 0);
        expect(h.store.decodeQueue, isEmpty);
        for (final id in ids) {
          expect(h.store.entryFor(id)!.state, ReceivedImageState.reassembled);
          expect(h.store.entryFor(id)!.needsManualDecode, isTrue);
        }
      },
    );

    test('turning the setting on affects future arrivals only', () async {
      final h = _build(processAutomatically: false);
      final parked = await _completeOne(h, imgId: 90);
      h.advance(const Duration(seconds: 2));

      h.store.processAutomatically = true;
      await h.store.settle();
      expect(h.decoder.calls, 0, reason: 'no retro-decode of the backlog');
      expect(
        h.store.entryFor(parked.streamId)!.state,
        ReceivedImageState.reassembled,
      );

      final fresh = await _completeOne(h, imgId: 91, seed: 5);
      await h.store.settle();
      expect(
        h.store.entryFor(fresh.streamId)!.state,
        ReceivedImageState.decoded,
      );
      expect(
        h.store.entryFor(parked.streamId)!.state,
        ReceivedImageState.reassembled,
      );
    });

    test('a reassembled entry restored from disk is always tappable', () async {
      final blobs = InMemoryReceivedImageBlobStore();
      // Written by a session that had auto-processing ON.
      final h = _build(blobs: blobs);
      h.store.setForeground(false);
      final entry = await _completeOne(h);
      expect(entry.needsManualDecode, isFalse);

      final reborn = ReceivedImageStore(
        blobs: blobs,
        decoder: _FakeDecoder(),
        processAutomatically: false,
        clock: h.clock,
      );
      await reborn.load();
      final loaded = reborn.entryFor(entry.streamId)!;
      expect(loaded.state, ReceivedImageState.reassembled);
      expect(loaded.needsManualDecode, isTrue);
      expect(reborn.decodeQueue, isEmpty);
      reborn.dispose();
    });

    test('decoderAvailability is exposed for the tap target', () async {
      final h = _build();
      expect(h.store.decoderAvailability, ImageCodecAvailability.ready);
      h.decoder.availability = ImageCodecAvailability.disabled;
      expect(h.store.decoderAvailability, ImageCodecAvailability.disabled);
      final noDecoder = ReceivedImageStore(decoder: null);
      expect(noDecoder.decoderAvailability, ImageCodecAvailability.unavailable);
      noDecoder.dispose();
    });
  });

  group('decode concurrency', () {
    test('ten taps run ten decodes strictly one at a time', () async {
      final decoder = _FakeDecoder()..delay = const Duration(milliseconds: 5);
      final h = _build(decoder: decoder, processAutomatically: false);
      final ids = <String>[];
      for (var i = 0; i < 10; i++) {
        ids.add((await _completeOne(h, imgId: 100 + i, seed: i)).streamId);
        h.advance(const Duration(seconds: 2));
      }
      // Fire every tap without awaiting: this is a user hammering the list.
      final taps = <Future<void>>[
        for (final id in ids) h.store.requestDecode(id),
      ];
      await Future.wait(taps);
      await h.store.settle();

      expect(decoder.calls, 10);
      expect(
        decoder.maxConcurrent,
        1,
        reason: 'two concurrent decodes is ~4.3 GiB and an OOM kill',
      );
      for (final id in ids) {
        expect(h.store.entryFor(id)!.state, ReceivedImageState.decoded);
      }
    });

    test('an arrival during a decode does not start a second one', () async {
      final decoder = _FakeDecoder()..delay = const Duration(milliseconds: 5);
      final h = _build(decoder: decoder);
      await _completeOne(h, imgId: 120);
      h.advance(const Duration(seconds: 2));
      // Do NOT settle: the first decode is still in flight.
      await _completeOne(h, imgId: 121, seed: 1);
      await h.store.settle();
      expect(decoder.calls, 2);
      expect(decoder.maxConcurrent, 1);
    });
  });

  group('deletion hooks', () {
    test(
      'deleteImagesForChannel reclaims every image of one conversation',
      () async {
        final h = _build();
        final a = await _completeOne(h, imgId: 130);
        h.advance(const Duration(seconds: 2));
        final b = await _completeOne(h, imgId: 131, seed: 1);
        await h.store.settle();
        // A third image on another channel must survive.
        final other = await h.store.registerOutgoing(
          channelIndex: 9,
          senderPrefix: kSelf,
          imgId: 5,
          previewPng: Uint8List.fromList(List<int>.filled(32, 2)),
          rate: AeicRatePoint.ft32,
          chunkCount: 1,
        );

        final removed = await h.store.deleteImagesForChannel(3);
        expect(removed, containsAll(<String>[a.streamId, b.streamId]));
        expect(h.store.entryFor(a.streamId), isNull);
        expect(h.store.entryFor(b.streamId), isNull);
        expect(h.blobs.hasPng(a.streamId), isFalse);
        expect(h.blobs.hasBitstream(a.streamId), isFalse);
        expect(h.blobs.hasSidecar(a.streamId), isFalse);
        expect(h.store.entryFor(other.streamId), isNotNull);
        expect(h.store.totalBytes, other.storedBytes);
      },
    );

    test('deleteImageForSentinel takes the message text', () async {
      final h = _build();
      final entry = await _completeOne(h);
      await h.store.settle();
      await h.store.deleteImageForSentinel('not an image');
      expect(h.store.entryFor(entry.streamId), isNotNull);
      await h.store.deleteImageForSentinel(
        ReceivedImageRef.encode(entry.streamId),
      );
      expect(h.store.entryFor(entry.streamId), isNull);
      expect(h.blobs.hasPng(entry.streamId), isFalse);
    });
  });

  group('FileReceivedImageBlobStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aeic_blobs_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    FileReceivedImageBlobStore newStore() =>
        FileReceivedImageBlobStore(baseDirectory: () async => tempDir);

    test('round-trips bytes and sidecars through real files', () async {
      final blobs = newStore();
      await blobs.writeBitstream('1a2b0700693f21', _payload(155));
      await blobs.writePng('1a2b0700693f21', _payload(4096, 3));
      await blobs.writeSidecar('1a2b0700693f21', '{"streamId":"x"}');

      expect(await blobs.readBitstream('1a2b0700693f21'), _payload(155));
      expect(await blobs.readPng('1a2b0700693f21'), _payload(4096, 3));
      expect(await blobs.bitstreamSize('1a2b0700693f21'), 155);
      expect(await blobs.pngSize('1a2b0700693f21'), 4096);
      expect(await blobs.readSidecars(), {
        '1a2b0700693f21': '{"streamId":"x"}',
      });
      expect(blobs.pngPath('1a2b0700693f21'), endsWith('1a2b0700693f21.png'));
      expect(File(blobs.pngPath('1a2b0700693f21')!).existsSync(), isTrue);

      // A fresh instance over the same directory sees the same bytes: this is
      // the whole point of the class.
      final second = newStore();
      expect(await second.readBitstream('1a2b0700693f21'), _payload(155));
      expect((await second.readSidecars()).keys, ['1a2b0700693f21']);

      await blobs.deletePng('1a2b0700693f21');
      await blobs.deleteBitstream('1a2b0700693f21');
      await blobs.deleteSidecar('1a2b0700693f21');
      expect(await blobs.readPng('1a2b0700693f21'), isNull);
      expect(await blobs.pngSize('1a2b0700693f21'), isNull);
      expect(await blobs.readSidecars(), isEmpty);
      // Deletes are idempotent.
      await blobs.deletePng('1a2b0700693f21');
    });

    test('missing files read as null and unsafe ids are refused', () async {
      final blobs = newStore();
      expect(await blobs.readPng('deadbeefdeadbe'), isNull);
      expect(await blobs.bitstreamSize('deadbeefdeadbe'), isNull);
      await blobs.writePng('../../escape', _payload(8));
      expect(blobs.pngPath('../../escape'), isNull);
      await blobs.ensureReady();
      expect(
        Directory(tempDir.path).listSync(recursive: true).length,
        1,
        reason: 'only the received_images directory itself',
      );
    });

    test('readSidecars reaps orphaned bytes and stale tmp files', () async {
      final blobs = newStore();
      final dir = await blobs.ensureReady();
      // A crash between "write bitstream" and "write sidecar".
      await blobs.writeBitstream('orphan00000001', _payload(150));
      await blobs.writePng('orphan00000001', _payload(64));
      // A crash mid sidecar write.
      await File('$dir/halfwrit0000001.json.tmp').writeAsString('{"a":');
      await blobs.writeSidecar('keeper000000001', '{"streamId":"keeper"}');
      await blobs.writeBitstream('keeper000000001', _payload(150));

      final sidecars = await blobs.readSidecars();
      expect(sidecars.keys, ['keeper000000001']);
      expect(await blobs.readBitstream('orphan00000001'), isNull);
      expect(await blobs.readPng('orphan00000001'), isNull);
      expect(File('$dir/halfwrit0000001.json.tmp').existsSync(), isFalse);
      expect(await blobs.readBitstream('keeper000000001'), isNotNull);
    });

    test('a truncated sidecar is skipped, not surfaced as an entry', () async {
      final blobs = newStore();
      final dir = await blobs.ensureReady();
      await File('$dir/broken000000001.json').writeAsString('{"streamId":');
      expect(await blobs.readSidecars(), isEmpty);
    });

    test('a received image survives a restart end to end', () async {
      var now = DateTime.utc(2026, 1, 1);
      final reassembler = ImageReassembler(selfPrefix: kSelf, clock: () => now);
      final store = ReceivedImageStore(
        blobs: newStore(),
        decoder: _FakeDecoder(),
        clock: () => now,
      );
      final set = buildImageChunks(
        payload: _payload(140),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 12,
      );
      final entry = await store.handleOutcome(
        reassembler.addChunk(set.blobs[0], channelIndex: 3, now: now),
        channelIndex: 3,
        at: now,
      );
      await store.settle();
      expect(
        store.entryFor(entry!.streamId)!.state,
        ReceivedImageState.decoded,
      );
      store.dispose();

      final reborn = ReceivedImageStore(
        blobs: newStore(),
        decoder: _FakeDecoder(),
        clock: () => now,
      );
      await reborn.load();
      final loaded = reborn.entryFor(entry.streamId);
      expect(
        loaded,
        isNotNull,
        reason: 'the whole point: images outlive the process',
      );
      expect(loaded!.state, ReceivedImageState.decoded);
      expect(loaded.pngStored, isTrue);
      expect(loaded.pngBytes, isNull, reason: 'pixels are read lazily');
      expect(loaded.bitstreamByteCount, greaterThan(0));
      expect(await reborn.ensurePng(entry.streamId), isNotNull);
      expect(reborn.pngPath(entry.streamId), isNotNull);
      reborn.dispose();
    });

    test('the age budget deletes the real files', () async {
      var now = DateTime.utc(2026, 1, 1);
      final blobs = newStore();
      final reassembler = ImageReassembler(selfPrefix: kSelf, clock: () => now);
      final store = ReceivedImageStore(
        blobs: blobs,
        decoder: _FakeDecoder(),
        maxAge: const Duration(minutes: 10),
        clock: () => now,
      );
      final set = buildImageChunks(
        payload: _payload(140),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 13,
      );
      final entry = await store.handleOutcome(
        reassembler.addChunk(set.blobs[0], channelIndex: 3, now: now),
        channelIndex: 3,
        at: now,
      );
      await store.settle();
      final png = blobs.pngPath(entry!.streamId)!;
      expect(File(png).existsSync(), isTrue);
      now = now.add(const Duration(minutes: 11));
      await store.evictToBudget();
      expect(File(png).existsSync(), isFalse);
      expect(await blobs.readBitstream(entry.streamId), isNull);
      store.dispose();
    });
  });

  test(
    'listeners fire for the message list and for the single bubble',
    () async {
      final h = _build();
      var storeNotifications = 0;
      h.store.addListener(() => storeNotifications++);
      final set = buildImageChunks(
        payload: _payload(kImageChunkFirstCapacity + 1),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: kSender,
        imgId: 77,
      );
      final first = await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[0], channelIndex: 3),
        channelIndex: 3,
      );
      final listenable = h.store.listenableFor(first!.streamId);
      var bubbleNotifications = 0;
      listenable.addListener(() => bubbleNotifications++);
      await h.store.handleOutcome(
        h.reassembler.addChunk(set.blobs[1], channelIndex: 3),
        channelIndex: 3,
      );
      await h.store.settle();
      expect(storeNotifications, greaterThan(1));
      expect(bubbleNotifications, greaterThan(1));
      expect(listenable.value!.state, ReceivedImageState.decoded);
    },
  );
}

/// Delivers a whole single-chunk image and returns its entry (state
/// `reassembled`; the caller decides whether to `settle()`).
Future<ReceivedImageEntry> _completeOne(
  _Rig h, {
  int imgId = 11,
  int seed = 0,
}) async {
  final set = buildImageChunks(
    payload: _payload(140, seed),
    metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
    senderPrefix: kSender,
    imgId: imgId,
  );
  final entry = await h.store.handleOutcome(
    h.reassembler.addChunk(set.blobs[0], channelIndex: 3, now: h.clock()),
    channelIndex: 3,
    at: h.clock(),
  );
  return entry!;
}
