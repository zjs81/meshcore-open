import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/widgets/received_image_message.dart';

const String _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==';

/// A decoder seam whose availability the test controls.
///
/// [decodeBitstream] never returns a picture: every tap-routing test only cares
/// about which of the two branches the bubble took, and a fake that produced
/// pixels would drag PNG decoding into an assertion about routing.
class _FakeDecoder implements ReceivedImageDecoder {
  @override
  final ImageCodecAvailability availability;

  @override
  bool isBusy = false;

  int decodeCalls = 0;
  int cancelCalls = 0;

  _FakeDecoder(this.availability);

  @override
  Future<ImageCodecResult?> decodeBitstream({
    required Uint8List bitstream,
    required AeicRatePoint ratePoint,
    required int resolution,
  }) async {
    decodeCalls++;
    return null;
  }

  @override
  void cancelCodecJob() => cancelCalls++;
}

/// Builds a store holding one entry that is `reassembled + needsManualDecode`,
/// i.e. the "bitstream complete, waiting for the user" placeholder state.
Future<ReceivedImageStore> _awaitingStore({
  ReceivedImageDecoder? decoder,
  int bytes = 156,
  int packets = 2,
}) async {
  final blobs = InMemoryReceivedImageBlobStore();
  await blobs.writeBitstream('await1', Uint8List(bytes));
  await blobs.writeSidecar(
    'await1',
    jsonEncode({
      'streamId': 'await1',
      'senderPrefix': 0x1a2b,
      'imgId': 7,
      'channelIndex': 0,
      'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
      'state': 'reassembled',
      'receivedChunks': packets,
      'totalChunks': packets,
      'needsManualDecode': true,
      'bitstreamStored': true,
      'bitstreamByteCount': bytes,
    }),
  );
  final store = ReceivedImageStore(blobs: blobs, decoder: decoder);
  await store.load();
  return store;
}

Future<void> _pumpBubble(
  WidgetTester tester,
  ReceivedImageStore store, {
  String streamId = 'await1',
  VoidCallback? onOpenCodecSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReceivedImageMessage(
          streamId: streamId,
          isOutgoing: false,
          fallbackTextColor: Colors.black,
          store: store,
          onOpenCodecSettings: onOpenCodecSettings,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('decoded incoming bubble carries the R6 badge and caption', (
    tester,
  ) async {
    final blobs = InMemoryReceivedImageBlobStore();
    final store = ReceivedImageStore(blobs: blobs);
    final png = base64Decode(_png1x1);
    final entry = await store.registerOutgoing(
      channelIndex: 0,
      senderPrefix: 1,
      imgId: 1,
      previewPng: Uint8List.fromList(png),
      rate: AeicRatePoint.ft32,
      chunkCount: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceivedImageMessage(
            streamId: entry.streamId,
            isOutgoing: true,
            fallbackTextColor: Colors.black,
            store: store,
          ),
        ),
      ),
    );
    await tester.pump();
    // Outgoing: real crop, so NO label.
    expect(find.text('AI-reconstructed'), findsNothing);

    // Now an incoming decoded entry.
    final blobs2 = InMemoryReceivedImageBlobStore();
    await blobs2.writeSidecar(
      'incoming',
      jsonEncode({
        'streamId': 'incoming',
        'senderPrefix': 2,
        'imgId': 2,
        'channelIndex': 0,
        'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
        'state': 'decoded',
        'receivedChunks': 1,
        'totalChunks': 1,
      }),
    );
    await blobs2.writePng('incoming', Uint8List.fromList(png));
    final store2 = ReceivedImageStore(blobs: blobs2);
    await store2.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceivedImageMessage(
            streamId: 'incoming',
            isOutgoing: false,
            fallbackTextColor: Colors.black,
            store: store2,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('AI-reconstructed'), findsOneWidget);
    expect(find.textContaining('Fine detail is generated'), findsOneWidget);
  });

  testWidgets('receiving state shows the packet count', (tester) async {
    final store = ReceivedImageStore(decoder: null);
    final reassembler = ImageReassembler(selfPrefix: 0xbeef);
    final set = buildImageChunks(
      payload: Uint8List(kImageChunkFirstCapacity + 1),
      metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
      senderPrefix: 0x1a2b,
      imgId: 5,
    );
    final entry = await store.handleOutcome(
      reassembler.addChunk(set.blobs[0], channelIndex: 0),
      channelIndex: 0,
    );
    expect(entry!.state, ReceivedImageState.receiving);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceivedImageMessage(
            streamId: entry.streamId,
            isOutgoing: false,
            fallbackTextColor: Colors.black,
            store: store,
          ),
        ),
      ),
    );
    expect(find.text('1 of 2 packets'), findsOneWidget);
    expect(find.text('AI-reconstructed'), findsNothing);
  });

  testWidgets(
    'awaiting card shows the bitstream size, the packet count and the '
    'tap-to-process affordance',
    (tester) async {
      final store = await _awaitingStore(bytes: 156, packets: 2);
      final entry = store.entryFor('await1')!;
      expect(entry.state, ReceivedImageState.reassembled);
      expect(entry.needsManualDecode, isTrue);

      await _pumpBubble(tester, store);

      expect(find.text('156 bytes · 2 packets'), findsOneWidget);
      expect(find.text('Tap to process'), findsOneWidget);
      // A placeholder is never dressed up as a picture.
      expect(find.text('AI-reconstructed'), findsNothing);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets('awaiting card honours injected strings', (tester) async {
    final store = await _awaitingStore(bytes: 209, packets: 3);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceivedImageMessage(
            streamId: 'await1',
            isOutgoing: false,
            fallbackTextColor: Colors.black,
            store: store,
            strings: ReceivedImageStrings(
              incoming: (r, t) => 'in $r/$t',
              queued: 'queued',
              tapToDecode: 'tap decode',
              awaiting: (b, p) => 'LOC $b B in $p pkts',
              tapToProcess: 'LOC process',
              decoding: 'decoding',
              incomplete: (r, t) => 'incomplete $r/$t',
              corrupt: 'corrupt',
              decoderMissing: 'missing',
              evicted: 'evicted',
              retry: 'retry',
              decodeAgain: 'again',
              openSettings: 'settings',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LOC 209 B in 3 pkts'), findsOneWidget);
    expect(find.text('LOC process'), findsOneWidget);
  });

  testWidgets('tap with a ready codec requests a decode and does NOT open '
      'settings', (tester) async {
    final decoder = _FakeDecoder(ImageCodecAvailability.ready);
    final store = await _awaitingStore(decoder: decoder);
    var settingsOpened = 0;

    await _pumpBubble(
      tester,
      store,
      onOpenCodecSettings: () => settingsOpened++,
    );

    await tester.tap(find.text('Tap to process'));
    await tester.pump();
    await tester.pump();

    expect(settingsOpened, 0);
    expect(decoder.decodeCalls, 1);
  });

  testWidgets('tap with no model installed opens the image-messages setting '
      'and never asks the store to decode', (tester) async {
    final decoder = _FakeDecoder(ImageCodecAvailability.disabled);
    final store = await _awaitingStore(decoder: decoder);
    var settingsOpened = 0;

    await _pumpBubble(
      tester,
      store,
      onOpenCodecSettings: () => settingsOpened++,
    );

    await tester.tap(find.text('Tap to process'));
    await tester.pump();
    await tester.pump();

    expect(settingsOpened, 1);
    expect(decoder.decodeCalls, 0);
    // The entry is untouched: it stays tappable rather than falling into
    // `decoderUnavailable` behind the user's back.
    expect(store.entryFor('await1')!.state, ReceivedImageState.reassembled);
  });

  testWidgets('tap with no codec and no settings route still asks the store, '
      'so the card is never inert', (tester) async {
    final store = await _awaitingStore(decoder: null);

    await _pumpBubble(tester, store);
    await tester.tap(find.text('Tap to process'));
    await tester.pump();
    await tester.pump();

    // No decoder at all -> the store parks it as decoderUnavailable, which is
    // the state that renders the "Set up" body.
    expect(
      store.entryFor('await1')!.state,
      ReceivedImageState.decoderUnavailable,
    );
  });

  testWidgets('a queued (auto-decode) card is still tappable', (tester) async {
    final blobs = InMemoryReceivedImageBlobStore();
    await blobs.writeBitstream('queued1', Uint8List(120));
    await blobs.writeSidecar(
      'queued1',
      jsonEncode({
        'streamId': 'queued1',
        'senderPrefix': 3,
        'imgId': 3,
        'channelIndex': 0,
        'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
        'state': 'reassembled',
        'receivedChunks': 1,
        'totalChunks': 1,
        'needsManualDecode': false,
        'bitstreamStored': true,
        'bitstreamByteCount': 120,
      }),
    );
    final decoder = _FakeDecoder(ImageCodecAvailability.ready);
    final store = ReceivedImageStore(blobs: blobs, decoder: decoder);
    await store.load();

    await _pumpBubble(tester, store, streamId: 'queued1');
    expect(find.text('Waiting to decode'), findsOneWidget);

    // load() does not enqueue, so without a tap target this card would sit on
    // "Waiting to decode" forever.
    await tester.tap(find.text('Waiting to decode'));
    await tester.pump();
    await tester.pump();
    expect(decoder.decodeCalls, 1);
  });

  testWidgets('every non-decoded state renders a legible label', (
    tester,
  ) async {
    const cases = <String, String>{
      'failedIncomplete': 'Image incomplete — 1 of 3 packets arrived',
      'failedCorrupt': 'Image could not be reconstructed',
      'decoderUnavailable': 'Image received — image decoding is off',
      'evicted': 'Image no longer stored',
      'decoding': 'Reconstructing… about 1 s',
    };
    for (final entry in cases.entries) {
      // A distinct id per case on purpose: the ListView-recycling guard in
      // _ReceivedImageMessageState only re-resolves the store when the
      // streamId changes, so reusing one id would keep showing the first case.
      final id = 'st_${entry.key}';
      final blobs = InMemoryReceivedImageBlobStore();
      await blobs.writeSidecar(
        id,
        jsonEncode({
          'streamId': id,
          'senderPrefix': 4,
          'imgId': 4,
          'channelIndex': 0,
          'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
          'state': entry.key,
          'receivedChunks': 1,
          'totalChunks': 3,
        }),
      );
      final store = ReceivedImageStore(blobs: blobs, decoder: null);
      await store.load();
      await _pumpBubble(tester, store, streamId: id);
      // `decoding` is repaired to failedIncomplete on load (no bitstream on
      // disk), which is exactly the label a user must see after a crash.
      final expected = entry.key == 'decoding'
          ? 'Image incomplete — 1 of 3 packets arrived'
          : entry.value;
      expect(
        find.text(expected),
        findsOneWidget,
        reason: 'state ${entry.key} rendered nothing legible',
      );
    }
  });

  testWidgets('a decoded incoming image always shows the label, whatever '
      'strings the caller injects', (tester) async {
    final blobs = InMemoryReceivedImageBlobStore();
    final png = Uint8List.fromList(base64Decode(_png1x1));
    await blobs.writePng('dec', png);
    await blobs.writeSidecar(
      'dec',
      jsonEncode({
        'streamId': 'dec',
        'senderPrefix': 9,
        'imgId': 9,
        'channelIndex': 0,
        'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
        'state': 'decoded',
        'receivedChunks': 1,
        'totalChunks': 1,
        'pngStored': true,
        'pngByteCount': 68,
      }),
    );
    final store = ReceivedImageStore(blobs: blobs, decoder: null);
    await store.load();

    await _pumpBubble(tester, store, streamId: 'dec');
    await tester.pump();

    expect(find.text('AI-reconstructed'), findsOneWidget);
    expect(find.textContaining('Reconstructed by an AI model'), findsOneWidget);
    expect(find.textContaining('Fine detail is generated'), findsOneWidget);
  });

  testWidgets('the caption quotes the real bitstream size, not a nominal one', (
    tester,
  ) async {
    // It used to hardcode "~156 bytes" under every image, so a 209-byte image
    // and a 110-byte one both claimed 156. The label's whole purpose is
    // honesty about what was actually transmitted.
    for (final bytes in <int>[110, 209]) {
      final id = 'sz$bytes';
      final blobs = InMemoryReceivedImageBlobStore();
      await blobs.writePng(id, Uint8List.fromList(base64Decode(_png1x1)));
      // A real bitstream on disk: load() derives the size by stat rather than
      // trusting the sidecar, which is why this must actually exist.
      await blobs.writeBitstream(id, Uint8List(bytes));
      await blobs.writeSidecar(
        id,
        jsonEncode({
          'streamId': id,
          'senderPrefix': 9,
          'imgId': 9,
          'channelIndex': 0,
          'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
          'state': 'decoded',
          'receivedChunks': 1,
          'totalChunks': 1,
          'pngStored': true,
          'pngByteCount': 68,
          'bitstreamStored': true,
          'bitstreamByteCount': bytes,
        }),
      );
      final store = ReceivedImageStore(blobs: blobs, decoder: null);
      await store.load();

      await _pumpBubble(tester, store, streamId: id);
      await tester.pump();

      expect(
        find.textContaining('$bytes bytes'),
        findsOneWidget,
        reason: 'caption must quote $bytes',
      );
      expect(
        find.textContaining('156 bytes'),
        findsNothing,
        reason: 'no nominal size may leak into the caption',
      );
    }
  });

  testWidgets('the R6 caption is never truncated in a narrow bubble', (
    tester,
  ) async {
    // It used to be maxLines: 2 and clipped mid-sentence — the rendered text
    // read "Details are invented. Not a", cutting off exactly where the
    // warning was. A half-shown warning is worse than none.
    final blobs = InMemoryReceivedImageBlobStore();
    await blobs.writePng('clip', Uint8List.fromList(base64Decode(_png1x1)));
    await blobs.writeBitstream('clip', Uint8List(209));
    await blobs.writeSidecar(
      'clip',
      jsonEncode({
        'streamId': 'clip',
        'senderPrefix': 9,
        'imgId': 9,
        'channelIndex': 0,
        'firstSeenMs': DateTime.now().millisecondsSinceEpoch,
        'state': 'decoded',
        'receivedChunks': 1,
        'totalChunks': 1,
        'pngStored': true,
        'pngByteCount': 68,
        'bitstreamStored': true,
        'bitstreamByteCount': 209,
      }),
    );
    final store = ReceivedImageStore(blobs: blobs, decoder: null);
    await store.load();

    await _pumpBubble(tester, store, streamId: 'clip');
    await tester.pump();

    final caption = tester.widget<Text>(
      find.textContaining('Reconstructed by an AI model'),
    );
    expect(caption.maxLines, isNull, reason: 'the sentence must wrap in full');
    expect(caption.overflow, isNot(TextOverflow.ellipsis));
    // And the tail of the sentence is actually present.
    expect(find.textContaining('not transmitted'), findsOneWidget);
  });
}
