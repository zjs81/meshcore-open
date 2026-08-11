/// Receive-side state, persistence and decode scheduling for AEIC images that
/// arrive over `PAYLOAD_TYPE_GRP_DATA` (see `image_chunk_transport.dart`).
///
/// This file holds the whole receive model:
///   * [ReceivedImageRef]   the sentinel that a channel message carries in its
///                          `text` field instead of the pixels.
///   * [ReceivedImageState] the state machine every incoming image walks.
///   * [ReceivedImageEntry] one immutable snapshot of an image's state.
///   * [ReceivedImageStore] the `ChangeNotifier` the message list listens to:
///                          intake, persistence, eviction and the decode queue.
///
/// ## Deliberate dependency shape
///
/// There is no `dart:io` here and no `package:flutter/material.dart`. Bytes go
/// through the [ReceivedImageBlobStore] seam (default:
/// [InMemoryReceivedImageBlobStore]) and decoding goes through the
/// [ReceivedImageDecoder] seam, which `ImageCodecService` satisfies
/// member-for-member (the wiring agent supplies the one-class adapter — this
/// file deliberately does not import the service, so a broken edit over there
/// cannot break the receive tests). That keeps the store unit-testable with no
/// temp directories, no `path_provider` and no 872 MB model, and it keeps the
/// file compilable on web where neither seam has an implementation.
///
/// `FileReceivedImageBlobStore` (`received_image_blob_store_io.dart`) is the
/// file-backed implementation; pass it as `blobs:` and received images survive
/// a restart. With the default in-memory store everything below works exactly
/// as specified but forgets its bytes on restart. Nothing else changes.
///
/// ## Decode policy (four gates)
///
/// The bitstream is ~156 B and already in hand, so decoding is only ever gated
/// on memory, never on bandwidth. Gates, all enforced here:
///   0. [processAutomatically] — when false, an arrival is parked as
///                               `reassembled + needsManualDecode` and waits
///                               for a tap. Mirrors the "Process images
///                               automatically" setting, which ships OFF.
///   1. foreground only        — [setForeground]; background decode is a ~2.7 GiB
///                               peak and an OOM kill waiting to happen.
///   2. strictly one at a time — and never while the codec is busy encoding for
///                               the compose UI.
///   3. burst cap              — at most [burstCap] auto-decodes are queued; the
///                               rest wait for a tap ([ReceivedImageEntry.needsManualDecode]).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/image_codec_support.dart';
import '../widgets/image_send_codec_binding.dart';
import 'image_chunk_transport.dart';

// ---------------------------------------------------------------------------
// Sentinel
// ---------------------------------------------------------------------------

/// Encodes/parses the sentinel string a `ChannelMessage.text` carries in place
/// of an image.
///
/// Mirrors `GifHelper.encodeGif` (`lib/helpers/gif_helper.dart`): the message
/// record stays a short string, the bytes live beside it. The sentinel never
/// changes for the life of the image, so `ChannelMessage`'s `text.hashCode`
/// derived id stays stable and a per-chunk state change does not rewrite the
/// channel's whole prefs blob.
class ReceivedImageRef {
  ReceivedImageRef._();

  /// Versioned on purpose: a future wire-format change ships `aeic:2:`.
  static const String scheme = 'aeic:1:';

  static final RegExp _pattern = RegExp(r'^aeic:1:([0-9a-f]{14})$');

  static String encode(String streamId) => '$scheme$streamId';

  /// Returns the stream id, or null when [text] is not an image sentinel.
  static String? parse(String text) =>
      _pattern.firstMatch(text.trim())?.group(1);

  /// `%04x%02x%08x` — 4 hex sender prefix, 2 hex img id, 8 hex epoch seconds.
  ///
  /// 14 lowercase hex characters, unique in practice, and it doubles as the
  /// on-disk filename stem.
  static String streamIdFor({
    required int senderPrefix,
    required int imgId,
    required DateTime firstSeen,
  }) {
    final seconds = firstSeen.millisecondsSinceEpoch ~/ 1000;
    return (senderPrefix & 0xFFFF).toRadixString(16).padLeft(4, '0') +
        (imgId & 0xFF).toRadixString(16).padLeft(2, '0') +
        (seconds & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Lifecycle of one received image. Legal transitions are enforced by
/// [ReceivedImageStore]; see the class doc there.
enum ReceivedImageState {
  /// Chunks are arriving; nothing is on disk yet.
  receiving,

  /// The bitstream is complete and persisted, but not decoded.
  reassembled,

  /// A decode is running right now.
  decoding,

  /// A PNG exists. This is the ONLY state that shows synthesized pixels, and
  /// therefore the only state that carries the R6 provenance label.
  decoded,

  /// The stream expired with chunks missing. Never retryable — the partial
  /// bodies only ever lived in the reassembler's memory.
  failedIncomplete,

  /// The bitstream arrived whole but the decoder rejected it. User-retryable.
  failedCorrupt,

  /// No usable decoder (feature off, no weights, web, or no backend).
  decoderUnavailable,

  /// The PNG was reclaimed by the disk budget. Re-decodable while the
  /// bitstream survives.
  evicted,
}

extension ReceivedImageStateValue on ReceivedImageState {
  String get value => name;

  /// True when the UI must show the R6 synthesized-content label.
  bool get showsSynthesizedPixels => this == ReceivedImageState.decoded;

  bool get isFailure =>
      this == ReceivedImageState.failedIncomplete ||
      this == ReceivedImageState.failedCorrupt;
}

ReceivedImageState _parseState(Object? raw) {
  if (raw is String) {
    for (final state in ReceivedImageState.values) {
      if (state.name == raw) return state;
    }
  }
  return ReceivedImageState.failedIncomplete;
}

/// Immutable snapshot of one image. Handed to the widget layer; every mutation
/// goes through [ReceivedImageStore].
@immutable
class ReceivedImageEntry {
  /// 14 hex chars; see [ReceivedImageRef.streamIdFor]. Also the filename stem.
  final String streamId;

  final int senderPrefix;
  final int imgId;
  final int channelIndex;

  /// Local clock at the first chunk — code 27 carries no timestamp.
  final DateTime firstSeen;

  final ReceivedImageState state;

  /// Data chunks accepted so far (parity chunks never counted).
  final int receivedChunks;

  /// Data chunks the sender announced (`total` in the chunk header).
  final int totalChunks;

  final AeicRatePoint rate;
  final int resolution;

  /// Index into [kImageAspectCodes]: the shape the sender's photo was before
  /// the codec stretched it into a square. Used to letterbox back on render.
  /// Defaults to 0 (square) when the sender said nothing.
  final int aspectCode;

  /// The source `width / height` to render at, or null to render square.
  double? get displayAspectRatio {
    final e = kImageAspectCodes[aspectCode & 0x0F];
    final r = e[0] / e[1];
    return r == 1.0 ? null : r;
  }

  /// True when chunk 0's metadata byte was unknown/unavailable and [rate] and
  /// [resolution] are the shipped defaults rather than the sender's word.
  final bool metadataAssumed;

  /// One chunk was rebuilt from the XOR parity chunk.
  final bool recoveredWithParity;

  /// This is the local user's own send. Its PNG is their real 512x512 crop, so
  /// [synthesized] is false and the R6 label must NOT be shown.
  final bool isOutgoing;

  /// Whether the pixels are generative-model output. Derived, never supplied:
  /// `synthesized == !isOutgoing`.
  bool get synthesized => !isOutgoing;

  final int? decodeMs;
  final String? error;

  /// Auto-decode was skipped (burst cap); the bubble offers "Tap to decode".
  final bool needsManualDecode;

  final bool bitstreamStored;
  final bool pngStored;
  final int bitstreamByteCount;
  final int pngByteCount;

  /// Decoded PNG, cached in memory once read. Not persisted in the sidecar and
  /// not part of [==]; callers must not hand these bytes onward without the R6
  /// caption (see `received_image_message.dart`).
  final Uint8List? pngBytes;

  const ReceivedImageEntry({
    required this.streamId,
    required this.senderPrefix,
    required this.imgId,
    required this.channelIndex,
    required this.firstSeen,
    required this.state,
    required this.receivedChunks,
    required this.totalChunks,
    this.rate = AeicRatePoint.ft32,
    this.resolution = kImageCodecSquareSize,
    this.aspectCode = 0,
    this.metadataAssumed = true,
    this.recoveredWithParity = false,
    this.isOutgoing = false,
    this.decodeMs,
    this.error,
    this.needsManualDecode = false,
    this.bitstreamStored = false,
    this.pngStored = false,
    this.bitstreamByteCount = 0,
    this.pngByteCount = 0,
    this.pngBytes,
  });

  ImageStreamKey get key => ImageStreamKey(
    senderPrefix: senderPrefix,
    imgId: imgId,
    channelIndex: channelIndex,
  );

  /// Bytes this entry is currently costing on disk.
  int get storedBytes =>
      (bitstreamStored ? bitstreamByteCount : 0) +
      (pngStored ? pngByteCount : 0);

  /// `evicted`/`failedCorrupt` can be decoded again only while the ~156 B
  /// bitstream survives.
  bool get canRetryDecode => bitstreamStored;

  static const Object _unset = Object();

  ReceivedImageEntry copyWith({
    ReceivedImageState? state,
    int? receivedChunks,
    int? totalChunks,
    AeicRatePoint? rate,
    int? resolution,
    int? aspectCode,
    bool? metadataAssumed,
    bool? recoveredWithParity,
    Object? decodeMs = _unset,
    Object? error = _unset,
    bool? needsManualDecode,
    bool? bitstreamStored,
    bool? pngStored,
    int? bitstreamByteCount,
    int? pngByteCount,
    Object? pngBytes = _unset,
  }) {
    return ReceivedImageEntry(
      streamId: streamId,
      senderPrefix: senderPrefix,
      imgId: imgId,
      channelIndex: channelIndex,
      firstSeen: firstSeen,
      state: state ?? this.state,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      rate: rate ?? this.rate,
      resolution: resolution ?? this.resolution,
      aspectCode: aspectCode ?? this.aspectCode,
      metadataAssumed: metadataAssumed ?? this.metadataAssumed,
      recoveredWithParity: recoveredWithParity ?? this.recoveredWithParity,
      isOutgoing: isOutgoing,
      decodeMs: identical(decodeMs, _unset) ? this.decodeMs : decodeMs as int?,
      error: identical(error, _unset) ? this.error : error as String?,
      needsManualDecode: needsManualDecode ?? this.needsManualDecode,
      bitstreamStored: bitstreamStored ?? this.bitstreamStored,
      pngStored: pngStored ?? this.pngStored,
      bitstreamByteCount: bitstreamByteCount ?? this.bitstreamByteCount,
      pngByteCount: pngByteCount ?? this.pngByteCount,
      pngBytes: identical(pngBytes, _unset)
          ? this.pngBytes
          : pngBytes as Uint8List?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'streamId': streamId,
    'senderPrefix': senderPrefix,
    'imgId': imgId,
    'channelIndex': channelIndex,
    'firstSeenMs': firstSeen.millisecondsSinceEpoch,
    'state': state.name,
    'receivedChunks': receivedChunks,
    'totalChunks': totalChunks,
    'rate': rate.wireValue,
    'resolution': resolution,
    'aspect_code': aspectCode,
    'metadataAssumed': metadataAssumed,
    'recoveredWithParity': recoveredWithParity,
    'isOutgoing': isOutgoing,
    'synthesized': synthesized,
    'needsManualDecode': needsManualDecode,
    'bitstreamStored': bitstreamStored,
    'pngStored': pngStored,
    'bitstreamByteCount': bitstreamByteCount,
    'pngByteCount': pngByteCount,
    if (decodeMs != null) 'decodeMs': decodeMs,
    if (error != null) 'error': error,
  };

  factory ReceivedImageEntry.fromJson(Map<String, dynamic> json) {
    return ReceivedImageEntry(
      streamId: json['streamId'] as String? ?? '',
      senderPrefix: json['senderPrefix'] as int? ?? 0,
      imgId: json['imgId'] as int? ?? 0,
      channelIndex: json['channelIndex'] as int? ?? 0,
      firstSeen: DateTime.fromMillisecondsSinceEpoch(
        json['firstSeenMs'] as int? ?? 0,
      ),
      state: _parseState(json['state']),
      receivedChunks: json['receivedChunks'] as int? ?? 0,
      totalChunks: json['totalChunks'] as int? ?? 1,
      rate: parseAeicRatePoint(json['rate'] as int? ?? 4),
      resolution: json['resolution'] as int? ?? kImageCodecSquareSize,
      aspectCode: json['aspect_code'] as int? ?? 0,
      metadataAssumed: json['metadataAssumed'] as bool? ?? true,
      recoveredWithParity: json['recoveredWithParity'] as bool? ?? false,
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      decodeMs: json['decodeMs'] as int?,
      error: json['error'] as String?,
      needsManualDecode: json['needsManualDecode'] as bool? ?? false,
      bitstreamStored: json['bitstreamStored'] as bool? ?? false,
      pngStored: json['pngStored'] as bool? ?? false,
      bitstreamByteCount: json['bitstreamByteCount'] as int? ?? 0,
      pngByteCount: json['pngByteCount'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'ReceivedImageEntry($streamId, ${state.name}, '
      '$receivedChunks/$totalChunks, ${rate.name})';
}

// ---------------------------------------------------------------------------
// Byte persistence seam
// ---------------------------------------------------------------------------

/// Where the three files of an image live. One implementation per platform.
///
/// Layout the file-backed implementation uses (application *support* dir, not
/// documents — these are derived caches, not user files):
/// `received_images/<streamId>.aeic|.png|.json`. See
/// `received_image_blob_store_io.dart`.
abstract class ReceivedImageBlobStore {
  Future<void> writeBitstream(String streamId, Uint8List bytes);
  Future<Uint8List?> readBitstream(String streamId);
  Future<void> deleteBitstream(String streamId);

  Future<void> writePng(String streamId, Uint8List bytes);
  Future<Uint8List?> readPng(String streamId);
  Future<void> deletePng(String streamId);

  /// Byte length of the stored bitstream, or null when there is none.
  ///
  /// Concrete on purpose: [load] only needs to know whether the bytes exist and
  /// how big they are, and the default below would read every 400 KB PNG on the
  /// device into memory at startup (200 images => ~80 MB of pointless I/O) just
  /// to call `.length` on it. A file-backed store overrides both with `stat`.
  Future<int?> bitstreamSize(String streamId) async =>
      (await readBitstream(streamId))?.length;

  /// Byte length of the stored PNG, or null when there is none.
  Future<int?> pngSize(String streamId) async =>
      (await readPng(streamId))?.length;

  /// Sidecar write must be atomic (tmp + rename) so a kill cannot leave a
  /// half-written record that `readSidecars` then discards.
  Future<void> writeSidecar(String streamId, String json);
  Future<void> deleteSidecar(String streamId);

  /// streamId -> raw sidecar JSON, for the startup scan.
  Future<Map<String, String>> readSidecars();

  /// Absolute path of the PNG, or null where the platform has no file system.
  String? pngPath(String streamId);
}

/// Default implementation: keeps everything in RAM.
///
/// Used by tests, by web (where there is no decoder either, so nothing ever
/// reaches [ReceivedImageState.decoded]) and as the fallback until the
/// file-backed store is wired in.
class InMemoryReceivedImageBlobStore implements ReceivedImageBlobStore {
  final Map<String, Uint8List> _bitstreams = <String, Uint8List>{};
  final Map<String, Uint8List> _pngs = <String, Uint8List>{};
  final Map<String, String> _sidecars = <String, String>{};

  @override
  Future<void> writeBitstream(String streamId, Uint8List bytes) async {
    _bitstreams[streamId] = bytes;
  }

  @override
  Future<Uint8List?> readBitstream(String streamId) async =>
      _bitstreams[streamId];

  @override
  Future<void> deleteBitstream(String streamId) async {
    _bitstreams.remove(streamId);
  }

  @override
  Future<int?> bitstreamSize(String streamId) async =>
      _bitstreams[streamId]?.length;

  @override
  Future<int?> pngSize(String streamId) async => _pngs[streamId]?.length;

  @override
  Future<void> writePng(String streamId, Uint8List bytes) async {
    _pngs[streamId] = bytes;
  }

  @override
  Future<Uint8List?> readPng(String streamId) async => _pngs[streamId];

  @override
  Future<void> deletePng(String streamId) async {
    _pngs.remove(streamId);
  }

  @override
  Future<void> writeSidecar(String streamId, String json) async {
    _sidecars[streamId] = json;
  }

  @override
  Future<void> deleteSidecar(String streamId) async {
    _sidecars.remove(streamId);
  }

  @override
  Future<Map<String, String>> readSidecars() async =>
      Map<String, String>.from(_sidecars);

  @override
  String? pngPath(String streamId) => null;

  // Test/debug helpers.
  bool hasBitstream(String streamId) => _bitstreams.containsKey(streamId);
  bool hasPng(String streamId) => _pngs.containsKey(streamId);
  bool hasSidecar(String streamId) => _sidecars.containsKey(streamId);
}

// ---------------------------------------------------------------------------
// Decoder seam
// ---------------------------------------------------------------------------

/// The slice of `ImageCodecService` the receive path needs.
///
/// `ImageCodecService` satisfies this shape member-for-member, so the adapter
/// the wiring agent writes is pure delegation:
///
/// ```dart
/// class ImageCodecServiceDecoder implements ReceivedImageDecoder {
///   final ImageCodecService service;
///   const ImageCodecServiceDecoder(this.service);
///   @override ImageCodecAvailability get availability => service.availability;
///   @override bool get isBusy => service.isBusy;
///   @override Future<ImageCodecResult?> decodeBitstream({
///     required Uint8List bitstream,
///     required AeicRatePoint ratePoint,
///     required int resolution,
///   }) => service.decodeBitstream(
///         bitstream: bitstream, ratePoint: ratePoint, resolution: resolution);
///   @override void cancelCodecJob() => service.cancelCodecJob();
/// }
/// ```
///
/// The interface also exists so the store can be tested without a 872 MB ONNX
/// graph.
abstract class ReceivedImageDecoder {
  ImageCodecAvailability get availability;

  /// True while an encode (compose UI) or another decode is running.
  bool get isBusy;

  /// Returns null when the codec cannot decode at all; a result with
  /// `status == failed` when the bitstream was rejected.
  Future<ImageCodecResult?> decodeBitstream({
    required Uint8List bitstream,
    required AeicRatePoint ratePoint,
    required int resolution,
  });

  /// Cooperative cancel, used when we background mid-decode.
  void cancelCodecJob();
}

// ---------------------------------------------------------------------------
// The store
// ---------------------------------------------------------------------------

/// Owns every received image: its state, its bytes, its place in the decode
/// queue and its share of the disk budget.
///
/// Legal transitions (nothing else is performed):
/// ```
///   (none)             -> receiving           first non-duplicate chunk
///   receiving          -> receiving           another data chunk
///   receiving          -> reassembled         completed; bitstream written FIRST
///   receiving          -> failedIncomplete    TTL/overflow eviction
///   reassembled        -> decoding            dequeued
///   reassembled        -> decoderUnavailable  no usable decoder at dequeue
///   decoding           -> decoded             completed && pngBytes != null
///   decoding           -> failedCorrupt       failed / throw / bad resolution
///   decoding           -> decoderUnavailable  decodeBitstream returned null
///   decoding           -> reassembled         cancelled (background / pressure)
///   decoderUnavailable -> decoding            retry, or availability recovered
///   failedCorrupt      -> decoding            explicit user retry only
///   decoded            -> evicted             budget reclaimed the PNG
///   evicted            -> decoding            "Decode again", bitstream survives
/// ```
/// `failedIncomplete` is terminal: the partial bodies are gone.
class ReceivedImageStore extends ChangeNotifier {
  final ReceivedImageBlobStore blobs;
  ReceivedImageDecoder? decoder;

  /// Hard cap on stored PNGs.
  final int maxImages;

  /// Hard cap on total bytes across all stored files.
  final int maxBytes;

  /// Images older than this are dropped from disk entirely.
  final Duration maxAge;

  /// How many auto-decodes may be queued before the rest need a tap.
  final int burstCap;

  /// When false, a completed bitstream is parked as
  /// `reassembled + needsManualDecode` and waits for a tap. Mirrors the
  /// "Process images automatically" app setting.
  ///
  /// Defaults to TRUE at the store level on purpose: that is this class's
  /// documented eager contract and what its unit tests assert. Production is
  /// off-by-default because `main.dart` passes the (false-by-default) setting
  /// explicitly and re-assigns this field whenever the setting changes.
  ///
  /// Assignment affects FUTURE arrivals only. It deliberately does not kick the
  /// queue and does not backfill: turning the setting on must not retro-decode
  /// a backlog, which would be an unbounded burst of ~2.16 GiB jobs.
  bool processAutomatically;

  final DateTime Function() _clock;

  final Map<String, ReceivedImageEntry> _entries =
      <String, ReceivedImageEntry>{};
  final Map<ImageStreamKey, String> _byKey = <ImageStreamKey, String>{};
  final Map<String, ValueNotifier<ReceivedImageEntry?>> _listenables =
      <String, ValueNotifier<ReceivedImageEntry?>>{};

  final List<String> _queue = <String>[];
  Future<void>? _pump;

  /// Set synchronously for as long as [_drain]'s body is running. A plain
  /// `_pump != null` check is NOT enough: the future stays non-null for one
  /// extra microtask after the body has finished, and a chunk arriving in that
  /// window used to be dropped on the floor with the queue non-empty and
  /// nothing running.
  bool _draining = false;

  /// True when the queue stopped because the codec was busy encoding. Cleared
  /// by anything that could plausibly have freed it.
  bool _parkedOnBusyDecoder = false;
  bool _foreground = true;
  bool _disposed = false;

  ReceivedImageStore({
    ReceivedImageBlobStore? blobs,
    this.decoder,
    this.maxImages = 200,
    this.maxBytes = 64 * 1024 * 1024,
    this.maxAge = const Duration(days: 30),
    this.burstCap = 3,
    this.processAutomatically = true,
    DateTime Function()? clock,
  }) : blobs = blobs ?? InMemoryReceivedImageBlobStore(),
       _clock = clock ?? DateTime.now;

  // ---- reads ---------------------------------------------------------------

  /// Newest first.
  List<ReceivedImageEntry> get entries {
    final list = _entries.values.toList()
      ..sort((a, b) => b.firstSeen.compareTo(a.firstSeen));
    return List<ReceivedImageEntry>.unmodifiable(list);
  }

  ReceivedImageEntry? entryFor(String streamId) => _entries[streamId];

  ReceivedImageEntry? entryForKey(ImageStreamKey key) {
    final id = _byKey[key];
    return id == null ? null : _entries[id];
  }

  /// Per-image listenable so one arriving chunk rebuilds one bubble instead of
  /// the whole reversed `ListView`.
  ValueListenable<ReceivedImageEntry?> listenableFor(String streamId) {
    return _listenables.putIfAbsent(
      streamId,
      () => ValueNotifier<ReceivedImageEntry?>(_entries[streamId]),
    );
  }

  /// Bytes currently held on disk by all entries.
  int get totalBytes =>
      _entries.values.fold<int>(0, (sum, e) => sum + e.storedBytes);

  int get storedImageCount => _entries.values.where((e) => e.pngStored).length;

  /// Stream ids waiting for an automatic decode, oldest request first.
  List<String> get decodeQueue => List<String>.unmodifiable(_queue);

  bool get isForeground => _foreground;

  /// Availability of the decoder seam, or `unavailable` when none is wired.
  ///
  /// Read-only passthrough so a bubble can pick its tap action (decode now vs.
  /// send the user to the model download) without importing
  /// `ImageCodecService`.
  ImageCodecAvailability get decoderAvailability =>
      decoder?.availability ?? ImageCodecAvailability.unavailable;

  /// True while a decode is running or queued. Callers that want to grey out a
  /// "Tap to process" affordance can use it; decodes are strictly serial, so a
  /// second tap only lengthens the wall clock, never the peak RSS.
  bool get isDecoding => _draining || _queue.isNotEmpty;

  // ---- startup -------------------------------------------------------------

  /// Loads sidecars and repairs states that cannot survive a process death.
  ///
  ///   receiving -> failedIncomplete   (partials were never persisted)
  ///   decoding  -> reassembled if the bitstream is there, else failedIncomplete
  ///   decoded   -> evicted if the PNG is gone
  Future<void> load() async {
    final sidecars = await blobs.readSidecars();
    for (final raw in sidecars.values) {
      Map<String, dynamic> json;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        json = decoded;
      } catch (_) {
        continue;
      }
      var entry = ReceivedImageEntry.fromJson(json);
      if (entry.streamId.isEmpty) continue;

      // Sizes, not bytes: reattaching 200 images must not read ~80 MB of PNG
      // into RAM on the startup path. The pixels are read lazily by
      // [ensurePng] when a bubble actually scrolls into view.
      final bitstreamBytes = await blobs.bitstreamSize(entry.streamId);
      final pngBytes = await blobs.pngSize(entry.streamId);
      entry = entry.copyWith(
        bitstreamStored: bitstreamBytes != null,
        bitstreamByteCount: bitstreamBytes ?? 0,
        pngStored: pngBytes != null,
        pngByteCount: pngBytes ?? entry.pngByteCount,
      );

      switch (entry.state) {
        case ReceivedImageState.receiving:
          entry = entry.copyWith(state: ReceivedImageState.failedIncomplete);
        case ReceivedImageState.decoding:
          entry = entry.copyWith(
            state: entry.bitstreamStored
                ? ReceivedImageState.reassembled
                : ReceivedImageState.failedIncomplete,
          );
        case ReceivedImageState.decoded:
          if (!entry.pngStored) {
            entry = entry.copyWith(state: ReceivedImageState.evicted);
          }
        case ReceivedImageState.reassembled:
          if (!entry.bitstreamStored) {
            entry = entry.copyWith(state: ReceivedImageState.failedIncomplete);
          } else if (!processAutomatically) {
            // load() never enqueues, so a `reassembled` entry restored with
            // needsManualDecode == false (written by a session that had the
            // setting on, or by an older build) would sit on "Waiting to
            // decode" forever with no tap target. Give it one.
            entry = entry.copyWith(needsManualDecode: true);
          }
        case ReceivedImageState.evicted:
        case ReceivedImageState.failedIncomplete:
        case ReceivedImageState.failedCorrupt:
        case ReceivedImageState.decoderUnavailable:
          break;
      }

      _entries[entry.streamId] = entry;
      _byKey[entry.key] = entry.streamId;
      _publish(entry);
      await _persist(entry);
    }
    await evictToBudget();
    _notify();
  }

  // ---- intake --------------------------------------------------------------

  /// Feeds one [ImageReassembler] outcome.
  ///
  /// The caller owns the reassembler (the send path already builds one) and is
  /// responsible for having dropped nothing: `malformed` and `fromSelf` are
  /// ignored here too, so an unfiltered firehose is safe.
  Future<ReceivedImageEntry?> handleOutcome(
    ImageChunkOutcome outcome, {
    required int channelIndex,
    DateTime? at,
  }) async {
    final now = at ?? _clock();
    switch (outcome.status) {
      case ImageChunkStatus.malformed:
      case ImageChunkStatus.fromSelf:
        return null;

      case ImageChunkStatus.duplicate:
        final header = outcome.header;
        if (header == null) return null;
        return entryForKey(
          ImageStreamKey(
            senderPrefix: header.senderPrefix,
            imgId: header.imgId,
            channelIndex: channelIndex,
          ),
        );

      case ImageChunkStatus.accepted:
      case ImageChunkStatus.conflicting:
        final header = outcome.header;
        if (header == null) return null;
        final key = ImageStreamKey(
          senderPrefix: header.senderPrefix,
          imgId: header.imgId,
          channelIndex: channelIndex,
        );
        final counts = header.isParity ? 0 : 1;
        final existing = entryForKey(key);

        // `conflicting` means the reassembler threw the old stream away and
        // restarted from this chunk. A stream that had already been surfaced
        // keeps its id (and therefore its message) only if it was still
        // receiving; anything else gets a fresh entry.
        final resets = outcome.status == ImageChunkStatus.conflicting;
        if (existing != null &&
            (!resets || existing.state == ReceivedImageState.receiving)) {
          final updated = existing.copyWith(
            state: ReceivedImageState.receiving,
            receivedChunks: resets
                ? counts
                : (existing.receivedChunks + counts)
                      .clamp(0, header.total)
                      .toInt(),
            totalChunks: header.total,
            error: null,
          );
          return _store(updated);
        }
        if (existing != null) {
          _byKey.remove(key);
        }
        final streamId = _uniqueStreamId(
          senderPrefix: header.senderPrefix,
          imgId: header.imgId,
          firstSeen: now,
        );
        final created = ReceivedImageEntry(
          streamId: streamId,
          senderPrefix: header.senderPrefix,
          imgId: header.imgId,
          channelIndex: channelIndex,
          firstSeen: now,
          state: ReceivedImageState.receiving,
          receivedChunks: counts,
          totalChunks: header.total,
        );
        return _store(created);

      case ImageChunkStatus.unsupportedFormat:
        // Every chunk arrived but chunk 0 names a rate point or resolution this
        // build cannot decode. The transport has already DISCARDED the bytes,
        // and there is nothing to retry, so no bitstream is stored.
        final header = outcome.header;
        if (header == null) return null;
        final entry = entryForKey(
          ImageStreamKey(
            senderPrefix: header.senderPrefix,
            imgId: header.imgId,
            channelIndex: channelIndex,
          ),
        );
        if (entry == null) return null;
        _queue.remove(entry.streamId);
        return _store(
          entry.copyWith(
            state: ReceivedImageState.failedCorrupt,
            bitstreamStored: false,
            error: 'Unsupported image format.',
          ),
        );

      case ImageChunkStatus.completed:
        final result = outcome.result;
        if (result == null) return null;
        return _handleCompleted(result, now);
    }
  }

  Future<ReceivedImageEntry> _handleCompleted(
    ImageReassemblyResult result,
    DateTime now,
  ) async {
    final key = result.key;
    var entry = entryForKey(key);
    if (entry == null) {
      final streamId = _uniqueStreamId(
        senderPrefix: key.senderPrefix,
        imgId: key.imgId,
        firstSeen: now,
      );
      entry = ReceivedImageEntry(
        streamId: streamId,
        senderPrefix: key.senderPrefix,
        imgId: key.imgId,
        channelIndex: key.channelIndex,
        firstSeen: now,
        state: ReceivedImageState.receiving,
        receivedChunks: result.chunkCount,
        totalChunks: result.chunkCount,
      );
    }

    final metadata = result.metadata;
    // Bitstream first, state second: a kill between the two must be
    // recoverable, and `reassembled` with no file on disk is a lie.
    await blobs.writeBitstream(entry.streamId, result.data);

    final updated = entry.copyWith(
      state: ReceivedImageState.reassembled,
      receivedChunks: result.chunkCount,
      totalChunks: result.chunkCount,
      rate: metadata == null
          ? AeicRatePoint.ft32
          : aeicRatePointForUi(metadata.rate),
      aspectCode: metadata?.aspectCode ?? 0,
      resolution: metadata?.squareSize ?? kImageCodecSquareSize,
      metadataAssumed: metadata == null,
      recoveredWithParity: result.recoveredWithParity,
      bitstreamStored: true,
      bitstreamByteCount: result.data.length,
      error: null,
    );
    if (!processAutomatically) {
      // Park it: the card shows "N bytes · M packets" and "Tap to process".
      // A 2.16 GiB decode is never started off the back of a radio packet
      // unless the user asked for that.
      return _store(updated.copyWith(needsManualDecode: true));
    }
    final stored = await _store(updated);
    _enqueue(stored.streamId);
    return stored;
  }

  /// A stream the reassembler gave up on (TTL or concurrency overflow).
  Future<ReceivedImageEntry?> handleFailure(
    ImageReassemblyFailure failure,
  ) async {
    final entry = entryForKey(failure.key);
    if (entry == null) return null;
    if (entry.state != ReceivedImageState.receiving) {
      // Already completed by a later chunk; the failure is stale.
      return entry;
    }
    return _store(
      entry.copyWith(
        // `isCorrupt` means every chunk arrived but the bytes were unusable
        // (CRC-16 mismatch or an undecodable metadata byte). The UI must say
        // "corrupt", not "incomplete".
        state: failure.isCorrupt
            ? ReceivedImageState.failedCorrupt
            : ReceivedImageState.failedIncomplete,
        receivedChunks: failure.receivedDataChunks,
        totalChunks: failure.total,
        error: failure.isCorrupt ? failure.reason.name : null,
      ),
    );
  }

  /// Records the local user's own send so the outgoing bubble can show the real
  /// 512x512 crop. [previewPng] is a photograph, not a decode, so the entry is
  /// never [ReceivedImageEntry.synthesized] and carries no R6 label.
  ///
  /// The send path must call this BEFORE it posts the message, and put the
  /// returned id in the message text — that sentinel is the only link between
  /// the `ChannelMessage` and these pixels:
  ///
  /// ```dart
  /// final entry = await receivedImageStore.registerOutgoing(
  ///   channelIndex: channelIndex,
  ///   senderPrefix: selfPrefix,      // same 16 bits the chunk header carries
  ///   imgId: chunkSet.imgId,
  ///   previewPng: preview.croppedPngBytes,  // the 512x512 crop, NOT a decode
  ///   rate: kImageSendRatePoint,
  ///   chunkCount: chunkSet.dataChunkCount,
  /// );
  /// await connector.sendChannelMessage(
  ///   channelIndex, ReceivedImageRef.encode(entry.streamId));
  /// ```
  ///
  /// Nothing is ever decoded for an outgoing entry: it lands in `decoded`
  /// directly and never enters the queue, so sending an image costs no model
  /// memory beyond the encode that already ran.
  Future<ReceivedImageEntry> registerOutgoing({
    required int channelIndex,
    required int senderPrefix,
    required int imgId,
    required Uint8List previewPng,
    required AeicRatePoint rate,
    required int chunkCount,
    DateTime? at,
  }) async {
    final now = at ?? _clock();
    final streamId = _uniqueStreamId(
      senderPrefix: senderPrefix,
      imgId: imgId,
      firstSeen: now,
    );
    await blobs.writePng(streamId, previewPng);
    final entry = ReceivedImageEntry(
      streamId: streamId,
      senderPrefix: senderPrefix,
      imgId: imgId,
      channelIndex: channelIndex,
      firstSeen: now,
      state: ReceivedImageState.decoded,
      receivedChunks: chunkCount,
      totalChunks: chunkCount,
      rate: rate,
      metadataAssumed: false,
      isOutgoing: true,
      pngStored: true,
      pngByteCount: previewPng.length,
      pngBytes: previewPng,
    );
    final stored = await _store(entry);
    await evictToBudget(protect: stored.streamId);
    return stored;
  }

  // ---- decode scheduling ---------------------------------------------------

  /// App lifecycle gate. Backgrounding cancels an in-flight decode and returns
  /// the entry to `reassembled` — never to a failure state.
  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    if (!value) {
      decoder?.cancelCodecJob();
    } else {
      _parkedOnBusyDecoder = false;
      _kick();
    }
    _notify();
  }

  /// Call when the codec's availability or busy flag changes: a queue parked on
  /// a busy encoder resumes, and images that were parked as
  /// `decoderUnavailable` get another go now that a decoder exists.
  void notifyDecoderChanged() {
    _parkedOnBusyDecoder = false;
    final decoder = this.decoder;
    if (decoder != null &&
        decoder.availability == ImageCodecAvailability.ready) {
      for (final entry in _entries.values.toList()) {
        if (entry.state != ReceivedImageState.decoderUnavailable) continue;
        if (!entry.bitstreamStored) continue;
        _storeSync(
          entry.copyWith(
            state: ReceivedImageState.reassembled,
            needsManualDecode: !processAutomatically,
          ),
        );
        // Without this guard, finishing an 835 MB download would immediately
        // fire one decode per image received while the model was missing —
        // exactly what the setting exists to prevent.
        if (processAutomatically) _queue.add(entry.streamId);
      }
    }
    _kick();
  }

  /// Cancels the running decode and stops the queue; the entry goes back to
  /// `reassembled` and will be picked up again later.
  Future<void> handleMemoryPressure() async {
    decoder?.cancelCodecJob();
    _queue.clear();
    for (final entry in _entries.values.toList()) {
      if (entry.state == ReceivedImageState.reassembled &&
          !entry.needsManualDecode) {
        await _store(entry.copyWith(needsManualDecode: true));
      }
    }
  }

  /// User tapped "Decode" / "Try again" / "Decode again".
  Future<void> requestDecode(String streamId) async {
    final entry = _entries[streamId];
    if (entry == null) return;
    switch (entry.state) {
      case ReceivedImageState.reassembled:
      case ReceivedImageState.failedCorrupt:
      case ReceivedImageState.decoderUnavailable:
      case ReceivedImageState.evicted:
        break;
      case ReceivedImageState.receiving:
      case ReceivedImageState.decoding:
      case ReceivedImageState.decoded:
      case ReceivedImageState.failedIncomplete:
        return;
    }
    if (!entry.bitstreamStored) return;
    await _store(
      entry.copyWith(
        state: ReceivedImageState.reassembled,
        needsManualDecode: false,
        error: null,
      ),
    );
    _parkedOnBusyDecoder = false;
    _enqueue(streamId, force: true);
    await settle();
  }

  /// Completes when the decode queue has stopped making progress. Test hook;
  /// production code never needs to await it.
  Future<void> settle() async {
    var guard = 0;
    while (guard++ < 1000) {
      final pump = _pump;
      if (pump != null) {
        await pump;
        continue;
      }
      if (_disposed ||
          _queue.isEmpty ||
          _draining ||
          _parkedOnBusyDecoder ||
          !_foreground) {
        return;
      }
      _kick();
      if (_pump == null) return;
    }
  }

  void _enqueue(String streamId, {bool force = false}) {
    if (_queue.contains(streamId)) return;
    // A new arrival is worth one more look at a codec that was busy.
    _parkedOnBusyDecoder = false;
    _queue.add(streamId);
    if (!force) {
      // Burst cap: keep the newest `burstCap` requests, park the rest behind a
      // tap so a repeater storm cannot spend minutes of CPU.
      while (_queue.length > burstCap) {
        final dropped = _queue.removeAt(0);
        final entry = _entries[dropped];
        if (entry != null && entry.state == ReceivedImageState.reassembled) {
          _storeSync(entry.copyWith(needsManualDecode: true));
        }
      }
    }
    _kick();
  }

  void _kick() {
    if (_disposed) return;
    if (_queue.isEmpty) return;
    if (_draining) return;
    if (_parkedOnBusyDecoder) return;
    _draining = true;
    _pump = _drain().whenComplete(() {
      _pump = null;
    });
  }

  Future<void> _drain() async {
    try {
      while (_queue.isNotEmpty && _foreground && !_disposed) {
        final decoder = this.decoder;
        final streamId = _queue.first;
        final entry = _entries[streamId];
        if (entry == null || entry.state != ReceivedImageState.reassembled) {
          _queue.removeAt(0);
          continue;
        }
        if (decoder == null ||
            decoder.availability != ImageCodecAvailability.ready) {
          _queue.removeAt(0);
          await _store(
            entry.copyWith(state: ReceivedImageState.decoderUnavailable),
          );
          continue;
        }
        if (decoder.isBusy) {
          // The compose UI is encoding. Leave the queue intact; the next
          // notifyDecoderChanged()/chunk resumes it.
          _parkedOnBusyDecoder = true;
          return;
        }
        _queue.removeAt(0);
        await _decodeOne(entry, decoder);
      }
    } finally {
      // Synchronous with the end of the body, unlike the future's completion.
      _draining = false;
    }
  }

  /// Belt to [_draining]'s braces. A decode peaks around 2.16 GiB, so two at
  /// once is not a slow app, it is an OOM kill. If this ever trips, the queue
  /// invariant is broken somewhere and the right answer is still to run one.
  bool _decodeInFlight = false;

  Future<void> _decodeOne(
    ReceivedImageEntry entry,
    ReceivedImageDecoder decoder,
  ) async {
    if (_decodeInFlight) {
      assert(false, 'ReceivedImageStore: concurrent decode attempted');
      debugPrint('received_image_store: refusing a concurrent decode');
      _queue.remove(entry.streamId);
      return;
    }
    _decodeInFlight = true;
    try {
      await _decodeOneExclusive(entry, decoder);
    } finally {
      _decodeInFlight = false;
    }
  }

  Future<void> _decodeOneExclusive(
    ReceivedImageEntry entry,
    ReceivedImageDecoder decoder,
  ) async {
    final bitstream = await blobs.readBitstream(entry.streamId);
    if (bitstream == null || bitstream.isEmpty) {
      await _store(
        entry.copyWith(
          state: ReceivedImageState.failedCorrupt,
          bitstreamStored: false,
          error: 'Bitstream missing.',
        ),
      );
      return;
    }
    final started = _clock();
    await _store(entry.copyWith(state: ReceivedImageState.decoding));

    ImageCodecResult? result;
    try {
      result = await decoder.decodeBitstream(
        bitstream: bitstream,
        ratePoint: entry.rate,
        resolution: entry.resolution,
      );
    } catch (error) {
      final current = _entries[entry.streamId] ?? entry;
      if (!_foreground) {
        await _store(current.copyWith(state: ReceivedImageState.reassembled));
      } else {
        await _store(
          current.copyWith(
            state: ReceivedImageState.failedCorrupt,
            error: error.toString(),
          ),
        );
      }
      return;
    }

    final current = _entries[entry.streamId] ?? entry;
    if (result == null) {
      // canDecode false — the codec cannot run at all.
      await _store(
        current.copyWith(state: ReceivedImageState.decoderUnavailable),
      );
      return;
    }
    final png = result.pngBytes;
    if (result.status != ImageCodecStatus.completed || png == null) {
      await _store(
        current.copyWith(
          state: ReceivedImageState.failedCorrupt,
          error: 'Decoder rejected the bitstream.',
        ),
      );
      return;
    }
    if (!_foreground) {
      // Backgrounded mid-decode: keep the pixels, but do not claim a decode we
      // may have half-cancelled.
      await _store(current.copyWith(state: ReceivedImageState.reassembled));
      return;
    }

    await blobs.writePng(current.streamId, png);
    await _store(
      current.copyWith(
        state: ReceivedImageState.decoded,
        pngStored: true,
        pngByteCount: png.length,
        pngBytes: png,
        decodeMs: result.durationMs > 0
            ? result.durationMs
            : _clock().difference(started).inMilliseconds,
        needsManualDecode: false,
        error: null,
      ),
    );
    // Without `protect` the freshly decoded image is the budget's own victim
    // whenever it is also the oldest: decode -> evict -> "Decode again" ->
    // evict, forever.
    await evictToBudget(protect: current.streamId);
  }

  // ---- pixels --------------------------------------------------------------

  /// Reads (and caches) the decoded PNG for a `decoded` entry. Returns null for
  /// every other state, so a failed or corrupt image can never present as
  /// decoded pixels.
  Future<Uint8List?> ensurePng(String streamId) async {
    final entry = _entries[streamId];
    if (entry == null) return null;
    if (entry.state != ReceivedImageState.decoded) return null;
    final cached = entry.pngBytes;
    if (cached != null) return cached;
    if (!entry.pngStored) return null;
    final bytes = await blobs.readPng(streamId);
    if (bytes == null) {
      await _store(
        entry.copyWith(state: ReceivedImageState.evicted, pngStored: false),
      );
      return null;
    }
    await _store(entry.copyWith(pngBytes: bytes, pngByteCount: bytes.length));
    return bytes;
  }

  /// Absolute PNG path, for a share/save action. Null on platforms with no file
  /// system, and null unless the entry is decoded.
  String? pngPath(String streamId) {
    final entry = _entries[streamId];
    if (entry == null || entry.state != ReceivedImageState.decoded) return null;
    return blobs.pngPath(streamId);
  }

  // ---- deletion and eviction ----------------------------------------------

  /// Removes an image and all three of its files. Called when the user deletes
  /// the message (or clears the conversation), otherwise ~400 KB is orphaned
  /// forever.
  Future<void> deleteImage(String streamId) async {
    final entry = _entries.remove(streamId);
    _queue.remove(streamId);
    if (entry != null) {
      _byKey.remove(entry.key);
    }
    await blobs.deletePng(streamId);
    await blobs.deleteBitstream(streamId);
    await blobs.deleteSidecar(streamId);
    final listenable = _listenables[streamId];
    if (listenable != null) {
      listenable.value = null;
    }
    _notify();
  }

  /// Deletes every image of one channel. Call this when the conversation is
  /// cleared or the channel removed, otherwise each image leaks ~400 KB until
  /// the 30-day age budget finally reaps it.
  ///
  /// Returns the stream ids that were removed, so the caller can strip their
  /// sentinels from the channel's message list in one pass.
  Future<List<String>> deleteImagesForChannel(int channelIndex) async {
    final doomed = _entries.values
        .where((e) => e.channelIndex == channelIndex)
        .map((e) => e.streamId)
        .toList();
    for (final streamId in doomed) {
      await deleteImage(streamId);
    }
    return doomed;
  }

  /// Deletes an image for each sentinel that is still present in a channel's
  /// message list, and drops everything else this store holds for that channel.
  ///
  /// Convenience for the single-message delete path: the caller has a
  /// `ChannelMessage.text`, not a stream id.
  Future<void> deleteImageForSentinel(String text) async {
    final streamId = ReceivedImageRef.parse(text);
    if (streamId == null) return;
    await deleteImage(streamId);
  }

  /// Brings the store back inside [maxImages] / [maxBytes] / [maxAge].
  ///
  /// Order matters: PNGs (~400 KB) go before bitstreams (~156 B), and oldest
  /// `firstSeen` first. An evicted entry keeps its message and its
  /// `evicted` state so the bubble can offer "Decode again".
  Future<List<String>> evictToBudget({String? protect}) async {
    final evicted = <String>[];
    final now = _clock();

    // 1. Age budget: nothing survives, not even the bitstream.
    for (final entry in _entries.values.toList()) {
      if (now.difference(entry.firstSeen) <= maxAge) continue;
      if (!entry.pngStored && !entry.bitstreamStored) continue;
      await blobs.deletePng(entry.streamId);
      await blobs.deleteBitstream(entry.streamId);
      await _store(
        entry.copyWith(
          state: ReceivedImageState.evicted,
          pngStored: false,
          bitstreamStored: false,
          pngBytes: null,
        ),
      );
      _queue.remove(entry.streamId);
      evicted.add(entry.streamId);
    }

    // 2. Size/count budget.
    var guard = 0;
    while ((storedImageCount > maxImages || totalBytes > maxBytes) &&
        guard++ < 10000) {
      final pngHolders =
          _entries.values
              .where((e) => e.pngStored && e.streamId != protect)
              .toList()
            ..sort((a, b) => a.firstSeen.compareTo(b.firstSeen));
      if (pngHolders.isNotEmpty) {
        final victim = pngHolders.first;
        await blobs.deletePng(victim.streamId);
        await _store(
          victim.copyWith(
            state: victim.state == ReceivedImageState.decoded
                ? ReceivedImageState.evicted
                : victim.state,
            pngStored: false,
            pngBytes: null,
          ),
        );
        evicted.add(victim.streamId);
        continue;
      }
      // Only bitstreams of already-evicted entries may go; a `reassembled`
      // entry still needs its bytes to decode.
      final bitstreamHolders =
          _entries.values
              .where(
                (e) =>
                    e.bitstreamStored &&
                    (e.state == ReceivedImageState.evicted ||
                        e.state == ReceivedImageState.failedCorrupt),
              )
              .toList()
            ..sort((a, b) => a.firstSeen.compareTo(b.firstSeen));
      if (bitstreamHolders.isEmpty) break;
      final victim = bitstreamHolders.first;
      await blobs.deleteBitstream(victim.streamId);
      await _store(
        victim.copyWith(
          state: ReceivedImageState.evicted,
          bitstreamStored: false,
        ),
      );
      evicted.add(victim.streamId);
    }

    if (evicted.isNotEmpty) _notify();
    return evicted;
  }

  // ---- plumbing ------------------------------------------------------------

  String _uniqueStreamId({
    required int senderPrefix,
    required int imgId,
    required DateTime firstSeen,
  }) {
    // Second-resolution ids collide when the same sender reuses an img_id
    // inside one second (id wrap, or a restart re-rolling the allocator seed).
    var at = firstSeen;
    var id = ReceivedImageRef.streamIdFor(
      senderPrefix: senderPrefix,
      imgId: imgId,
      firstSeen: at,
    );
    var bump = 0;
    while (_entries.containsKey(id) && bump++ < 64) {
      at = at.add(const Duration(seconds: 1));
      id = ReceivedImageRef.streamIdFor(
        senderPrefix: senderPrefix,
        imgId: imgId,
        firstSeen: at,
      );
    }
    return id;
  }

  Future<ReceivedImageEntry> _store(ReceivedImageEntry entry) async {
    _storeSync(entry);
    await _persist(entry);
    return entry;
  }

  void _storeSync(ReceivedImageEntry entry) {
    _entries[entry.streamId] = entry;
    _byKey[entry.key] = entry.streamId;
    _publish(entry);
    _notify();
  }

  Future<void> _persist(ReceivedImageEntry entry) async {
    try {
      await blobs.writeSidecar(entry.streamId, jsonEncode(entry.toJson()));
    } catch (error) {
      debugPrint('received_image_store: sidecar write failed: $error');
    }
  }

  void _publish(ReceivedImageEntry entry) {
    final listenable = _listenables[entry.streamId];
    if (listenable != null) {
      listenable.value = entry;
    }
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.clear();
    for (final listenable in _listenables.values) {
      listenable.dispose();
    }
    _listenables.clear();
    super.dispose();
  }
}
