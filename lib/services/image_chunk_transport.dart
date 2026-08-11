/// Chunked image transport over MeshCore `PAYLOAD_TYPE_GRP_DATA` (0x06),
/// carried by the companion command `CMD_SEND_CHANNEL_DATA` (62) and received
/// as `RESP_CODE_CHANNEL_DATA_RECV` (27).
///
/// This file is the SINGLE SOURCE OF TRUTH for the on-air chunk framing: the
/// blob size, header layout, per-chunk capacities and the XOR parity scheme.
/// `lib/utils/lora_airtime.dart` re-exports the constants below rather than
/// declaring rivals, so the airtime estimator cannot drift from the chunker;
/// anything else that needs chunk geometry must do the same.
///
/// Everything above the "protocol glue" section is pure Dart: no Flutter, no
/// BLE, no connector. It is directly unit-testable.
///
/// ## Wire format
///
/// One MeshCore GRP_DATA blob per chunk, at most [kImageChunkBlobBytes] bytes:
///
/// ```
///   off  size  field
///   0    2     sender_prefix  selfPublicKey[0..1] — the firmware supplies no
///                             sender identity on RESP_CODE_CHANNEL_DATA_RECV,
///                             so it must be in-band in EVERY chunk (chunk 0
///                             may be the one that is lost).
///   2    1     img_id         uint8, random-ish per image
///   3    1     idx<<4 | total idx 0..15, total 1..15.
///                             idx == total  =>  XOR parity chunk.
///   4    ..    body           see below
/// ```
///
/// Data chunk body:
///   * chunk 0: `[meta]` + image bytes. `meta` is [ImageStreamMetadata] packed
///     as `aspect(4) | resolution(2) | rate(2)`. The aspect nibble names the
///     source photo's shape so the receiver can undo the stretch into the
///     square — see [kImageAspectCodes]. It costs no extra bytes.
///   * others : image bytes
///   * at most [kImageChunkBodyBytes] bytes.
///
/// Parity chunk body:
///   * `[len_xor]` + XOR of every data chunk body, each zero-padded to
///     [kImageChunkBodyBytes].
///   * `len_xor` is the XOR of every data chunk's body LENGTH. It is what makes
///     recovery self-describing: a lost chunk's length is recovered as
///     `len_xor ^ XOR(lengths of the bodies that did arrive)`, so the last
///     (short) chunk can be rebuilt without transmitting a total length.
///
/// Body capacity is [kImageChunkBodyBytes] = blob(163) - header(4) - the
/// parity chunk's 1 length byte, so that the parity chunk itself still fits in
/// a single blob. The cost is exactly one wasted byte in each data chunk; that
/// is the price of self-describing single-loss recovery.
///
/// ## Integrity
///
/// There is deliberately NO app-level checksum. Two layers below already cover
/// corruption of a delivered chunk: the LoRa PHY CRCs every packet (`setCRC(1)`
/// in each radio driver, and a failing packet is dropped by the modem), and
/// MeshCore verifies a 2-byte HMAC-SHA256 per packet and rejects on mismatch
/// (`Utils::MACThenDecrypt` returns 0 for a bad tag). What no lower layer can
/// see is a cross-image MERGE — two senders colliding on senderPrefix + imgId +
/// channel inside one TTL, ~1/65536 per concurrent pair — which produces a
/// corrupt image rather than a clean failure. That residual risk is accepted:
/// paying 2 bytes to detect it cost far more than it was worth, because it
/// pushed the measured ft32 mean past the single-chunk capacity.
///
/// ## Capacity check against measured codec output
///   chunk 0: 157 data bytes (158 body - 1 meta), other chunks: 158.
///   ft32 mean 155.8 B -> 1 chunk (2 packets with parity).
///   ft32 max  209   B -> 2 chunks (157+158 = 315).
///   ft16 max  409   B -> 3 chunks (157+158+158 = 473).
///   Design goals (ft32 1-2 chunks, ft16 2-3 chunks) hold.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../widgets/image_send_codec_binding.dart' show ImageCodecRatePoint;

// ---------------------------------------------------------------------------
// Protocol constants (firmware-derived; see the transport investigation)
// ---------------------------------------------------------------------------

/// `CMD_SEND_CHANNEL_DATA` — companion command that emits a GRP_DATA packet.
const int cmdSendChannelData = 62;

/// `RESP_CODE_CHANNEL_DATA_RECV` — inbound frame carrying a GRP_DATA blob.
const int respCodeChannelDataRecv = 27;

/// `OUT_PATH_UNKNOWN` — request flood routing.
const int outPathUnknown = 0xFF;

/// Our application data type. `0x0000` is rejected by the firmware.
const int dataTypeAeicImage = 0xAE1C;

/// Maximum blob we will ever put in one GRP_DATA packet.
///
/// Binding limits, smallest first:
///   * app  `maxFrameSize` 172 - 9 byte RESP header = **163**  <- used
///   * BLE  ATT_MTU 176 - 3 notify - 9 resp header  = 164
///   * radio `MAX_GROUP_DATA_LENGTH` 184 - 16 - 3   = 165
///   * serial `MAX_CHANNEL_DATA_LENGTH` 176 - 9     = 167
const int kImageChunkBlobBytes = 163;

/// Per-chunk header: sender_prefix(2) + img_id(1) + idx/total(1).
const int kImageChunkHeaderBytes = 4;

/// The parity chunk spends one body byte on the XOR of the data body lengths.
const int kImageParityLengthBytes = 1;

/// Maximum body bytes in any chunk (data or parity payload region).
const int kImageChunkBodyBytes =
    kImageChunkBlobBytes - kImageChunkHeaderBytes - kImageParityLengthBytes;

/// The single [ImageStreamMetadata] byte carried by chunk 0.
const int kImageChunkMetadataBytes = 1;

/// Body bytes of chunk 0 that are NOT image data: just the metadata byte.
///
/// A CRC-16 briefly lived here. It was removed: the LoRa PHY already CRCs every
/// packet (`setCRC(1)` in every radio driver) and MeshCore verifies a 2-byte
/// HMAC per packet (`Utils::MACThenDecrypt`, which returns 0 on mismatch), so a
/// corrupted chunk never reaches this layer. The only thing an app-level CRC
/// added was detection of a cross-image merge (two senders colliding on
/// senderPrefix + imgId + channel inside one TTL, ~1/65536), and it cost 2 of
/// chunk 0's bytes -- which pushed the measured ft32 mean of 155.8 B past the
/// single-chunk capacity and turned half of all images from 1 packet into 3.
const int kImageChunkZeroMetadataBytes = kImageChunkMetadataBytes;

/// Image bytes carried by chunk 0.
const int kImageChunkFirstCapacity =
    kImageChunkBodyBytes - kImageChunkZeroMetadataBytes;

/// Image bytes carried by every chunk after chunk 0.
const int kImageChunkCapacity = kImageChunkBodyBytes;

/// `total` is 4 bits and must be >= 1, so at most 15 data chunks.
const int kImageMaxDataChunks = 15;

/// Largest image bitstream this framing can carry.
const int kImageMaxPayloadBytes =
    kImageChunkFirstCapacity + (kImageMaxDataChunks - 1) * kImageChunkCapacity;

/// Bytes of the sender public key repeated in every chunk.
const int kImageSenderPrefixBytes = 2;

/// How long a partially received image is kept before it is abandoned.
const Duration kImageReassemblyTtl = Duration(seconds: 60);

// ---------------------------------------------------------------------------
// Rate point <-> wire code
// ---------------------------------------------------------------------------

/// Wire code for `ft32` in the low nibble of the chunk-0 metadata byte.
const int kImageRateWireStandard = 0;

/// Wire code for `ft16`. Reserved: ft16 is NOT a shipping rate point, but the
/// code stays allocated so an ft32-only build and a future ft16-capable build
/// agree on the nibble.
const int kImageRateWireHigh = 1;

/// Number of rate codes this build knows how to name.
const int kImageRateWireCodeCount = 2;

/// Maps a UI rate point to the wire code written into the metadata byte.
///
/// THIS IS NOT `AeicRatePoint.wireValue`. There are two rate enumerations in
/// this codebase and they do not share an ordinal space:
///
///   * `AeicRatePoint` (`lib/models/image_codec_support.dart`) is
///     `{ft2, ft4, ft8, ft16, ft32}` and its `wireValue` is that ordinal, 0..4.
///     It selects a MODEL from the registry. `ft32` is 4 there.
///   * [ImageCodecRatePoint] is `{standard, high}`, 0..1, and is what the
///     chunk-0 nibble names. `ft32` is [kImageRateWireStandard] == 0 here.
///
/// Writing an `AeicRatePoint.wireValue` into the nibble would put 4 on the wire
/// for the only shipping rate, which [imageRatePointFromWireCode] rejects
/// outright rather than silently landing on a rate point that decodes to the
/// wrong model. The switch is exhaustive on purpose: adding a rate point is a
/// compile error here, not a silent ordinal shift.
int imageRateWireCode(ImageCodecRatePoint rate) {
  switch (rate) {
    case ImageCodecRatePoint.standard:
      return kImageRateWireStandard;
    case ImageCodecRatePoint.high:
      return kImageRateWireHigh;
  }
}

/// Inverse of [imageRateWireCode]; null for a code this build cannot decode.
ImageCodecRatePoint? imageRatePointFromWireCode(int code) {
  switch (code) {
    case kImageRateWireStandard:
      return ImageCodecRatePoint.standard;
    case kImageRateWireHigh:
      return ImageCodecRatePoint.high;
    default:
      return null;
  }
}

// ---------------------------------------------------------------------------
// Stream metadata (the single byte carried by chunk 0)
// ---------------------------------------------------------------------------

/// Square sizes addressable by the 2-bit resolution code in the metadata byte.
///
/// Index == wire code. 512 is code 0 because it is the only size the current
/// decoder supports; the rest exist so a future model can be signalled without
/// a format change.
const List<int> kImageResolutionCodes = <int>[512, 256, 768, 1024];

/// Source aspect ratios addressable by the 4-bit aspect code, as `w:h`.
///
/// The codec encodes a 512x512 SQUARE — the whole frame stretched to fit, not a
/// crop, so nothing outside the frame is discarded. That stretch is not
/// invertible from the pixels alone, so the sender names the original shape
/// here and the receiver letterboxes back to it.
///
/// This costs ZERO extra bytes: the metadata byte previously spent 4 bits on a
/// resolution with 4 legal values and 4 bits on a rate with 2, so the byte was
/// repacked (2 + 2 + 4) rather than widened. Adding a byte would have cost far
/// more than it looks — the measured ft32 mean of 155.8 B sits just under
/// chunk 0's 157-byte capacity, so one more byte pushes a chunk of the
/// distribution from 1 data chunk to 2, i.e. from 2 packets on air to 3. That
/// is exactly what the CRC did before it was removed.
///
/// Index == wire code. Code 0 is 1:1 (no letterboxing). Code 15 means "not one
/// of these" and is rendered square, unstretched — a graceful degradation, not
/// an error. The rest are the shapes phone cameras actually produce, so the
/// common cases restore EXACTLY rather than approximately.
const List<List<int>> kImageAspectCodes = <List<int>>[
  <int>[1, 1], // 0  square
  <int>[5, 4], // 1  landscape
  <int>[4, 3], // 2
  <int>[3, 2], // 3
  <int>[16, 10], // 4
  <int>[16, 9], // 5
  <int>[2, 1], // 6
  <int>[21, 9], // 7
  <int>[4, 5], // 8  portrait
  <int>[3, 4], // 9
  <int>[2, 3], // 10
  <int>[10, 16], // 11
  <int>[9, 16], // 12
  <int>[1, 2], // 13
  <int>[9, 21], // 14
  <int>[1, 1], // 15 unknown -> render square
];

/// Wire code for "shape unknown"; the receiver renders it square.
const int kImageAspectUnknown = 15;

/// The [kImageAspectCodes] entry closest to `width / height`, in log space so
/// that 4:3 and 3:4 are equally far from square.
///
/// Returns [kImageAspectUnknown] for a ratio outside roughly 21:9..9:21, rather
/// than snapping a panorama onto 21:9 and letterboxing it wrongly.
int imageAspectCodeFor(int width, int height) {
  if (width <= 0 || height <= 0) return kImageAspectUnknown;
  final target = math.log(width / height);
  var best = kImageAspectUnknown;
  var bestErr = double.infinity;
  for (var i = 0; i < kImageAspectCodes.length; i++) {
    if (i == kImageAspectUnknown) continue; // duplicate of 1:1
    final e = kImageAspectCodes[i];
    final err = (math.log(e[0] / e[1]) - target).abs();
    if (err < bestErr) {
      bestErr = err;
      best = i;
    }
  }
  // Half a step between 21:9 and the next ratio out; beyond that we would be
  // asserting a shape the sender never had.
  return bestErr <= 0.18 ? best : kImageAspectUnknown;
}

/// Contents of the chunk-0 metadata byte: `resolution_code << 4 | rate_index`.
class ImageStreamMetadata {
  /// Codec rate point. Reuses the UI enum — there is deliberately no second
  /// rate-point enum in this codebase.
  final ImageCodecRatePoint rate;

  /// Square edge length in pixels the sender encoded at.
  final int squareSize;

  /// Index into [kImageAspectCodes]: the shape the source photo was BEFORE it
  /// was stretched into the square. The receiver letterboxes back to it.
  final int aspectCode;

  /// Original `width / height`, or 1.0 when the sender said "unknown".
  double get aspectRatio {
    final e = kImageAspectCodes[aspectCode & 0x0F];
    return e[0] / e[1];
  }

  /// True when the image should be rendered square, unstretched.
  bool get isSquare => aspectCode == 0 || aspectCode == kImageAspectUnknown;

  const ImageStreamMetadata({
    required this.rate,
    this.squareSize = 512,
    this.aspectCode = 0,
  });

  /// Encodes to the single wire byte.
  ///
  /// Throws [ArgumentError] if [squareSize] is not one of
  /// [kImageResolutionCodes].
  int encode() {
    final code = kImageResolutionCodes.indexOf(squareSize);
    if (code < 0) {
      throw ArgumentError.value(
        squareSize,
        'squareSize',
        'not representable; must be one of $kImageResolutionCodes',
      );
    }
    // Repacked: aspect(4) | resolution(2) | rate(2). Lossless for every value
    // the old 4+4 layout could express, because resolution has 4 legal codes
    // and rate has 2.
    return ((aspectCode & 0x0F) << 4) |
        ((code & 0x03) << 2) |
        (imageRateWireCode(rate) & 0x03);
  }

  /// Decodes the wire byte, or returns null if it names a rate point or
  /// resolution this build does not know.
  ///
  /// Deliberately never falls back to a default rate: an unknown code means the
  /// sender is running a format we cannot decode, and guessing `standard` would
  /// hand the wrong model a bitstream it will happily turn into garbage. The
  /// caller surfaces null as [ImageChunkStatus.unsupportedFormat].
  static ImageStreamMetadata? decode(int byte) {
    final rate = imageRatePointFromWireCode(byte & 0x03);
    final code = (byte >> 2) & 0x03;
    final aspect = (byte >> 4) & 0x0F;
    if (rate == null) return null;
    if (code >= kImageResolutionCodes.length) return null;
    return ImageStreamMetadata(
      rate: rate,
      squareSize: kImageResolutionCodes[code],
      aspectCode: aspect,
    );
  }

  @override
  String toString() =>
      'ImageStreamMetadata(${rate.name}, ${squareSize}px, '
      'aspect ${kImageAspectCodes[aspectCode & 0x0F].join(":")})';

  @override
  bool operator ==(Object other) =>
      other is ImageStreamMetadata &&
      other.rate == rate &&
      other.squareSize == squareSize &&
      other.aspectCode == aspectCode;

  @override
  int get hashCode => Object.hash(rate, squareSize, aspectCode);
}

// ---------------------------------------------------------------------------
// Chunk header
// ---------------------------------------------------------------------------

/// Parsed 4-byte chunk header.
class ImageChunkHeader {
  /// First [kImageSenderPrefixBytes] bytes of the sender's public key.
  final int senderPrefix;

  final int imgId;

  /// 0-based chunk index. Equals [total] for the parity chunk.
  final int index;

  /// Number of DATA chunks in this image (parity not counted). 1..15.
  final int total;

  const ImageChunkHeader({
    required this.senderPrefix,
    required this.imgId,
    required this.index,
    required this.total,
  });

  bool get isParity => index == total;

  @override
  String toString() =>
      'ImageChunkHeader(sender: 0x'
      '${senderPrefix.toRadixString(16).padLeft(4, '0')}, img: $imgId, '
      'idx: $index/$total${isParity ? ' parity' : ''})';
}

/// Packs [senderPrefix] (2 bytes, big-endian as an int) into a header.
Uint8List _writeHeader(int senderPrefix, int imgId, int index, int total) {
  return Uint8List.fromList(<int>[
    (senderPrefix >> 8) & 0xFF,
    senderPrefix & 0xFF,
    imgId & 0xFF,
    ((index & 0x0F) << 4) | (total & 0x0F),
  ]);
}

/// Reads the first two bytes of a public key as the sender prefix integer.
///
/// Returns null when [publicKey] is too short to identify a sender.
int? senderPrefixFromKey(List<int>? publicKey) {
  if (publicKey == null || publicKey.length < kImageSenderPrefixBytes) {
    return null;
  }
  return ((publicKey[0] & 0xFF) << 8) | (publicKey[1] & 0xFF);
}

/// Parses the header of a received blob, or null if it cannot be a chunk.
ImageChunkHeader? parseImageChunkHeader(Uint8List blob) {
  if (blob.length < kImageChunkHeaderBytes) return null;
  if (blob.length > kImageChunkBlobBytes) return null;
  final total = blob[3] & 0x0F;
  if (total == 0) return null;
  final index = (blob[3] >> 4) & 0x0F;
  if (index > total) return null; // index == total is the parity chunk
  return ImageChunkHeader(
    senderPrefix: ((blob[0] & 0xFF) << 8) | (blob[1] & 0xFF),
    imgId: blob[2] & 0xFF,
    index: index,
    total: total,
  );
}

// ---------------------------------------------------------------------------
// Chunking (send side)
// ---------------------------------------------------------------------------

/// Number of DATA chunks needed for a [payloadBytes]-long bitstream.
///
/// A zero-length payload still needs one chunk: chunk 0 carries the metadata
/// byte, and a receiver must be able to observe an empty image rather than
/// nothing at all.
int imageDataChunkCount(int payloadBytes) {
  final n = math.max(payloadBytes, 0);
  if (n <= kImageChunkFirstCapacity) return 1;
  final remaining = n - kImageChunkFirstCapacity;
  return 1 + (remaining / kImageChunkCapacity).ceil();
}

/// The blobs of one image, ready to hand to `CMD_SEND_CHANNEL_DATA`.
class ImageChunkSet {
  /// Every blob in send order; the parity blob, if any, is last.
  final List<Uint8List> blobs;

  /// Number of data chunks (excludes parity).
  final int dataChunkCount;

  final bool hasParity;

  final int imgId;

  final int senderPrefix;

  const ImageChunkSet({
    required this.blobs,
    required this.dataChunkCount,
    required this.hasParity,
    required this.imgId,
    required this.senderPrefix,
  });

  int get totalBytes => blobs.fold<int>(0, (a, b) => a + b.length);
}

/// Splits an encoded image bitstream into chunk blobs.
///
/// Chunk 0's body opens with the metadata byte; the rest is image bytes.
///
/// [senderPrefix] must come from the local node's public key (see
/// [senderPrefixFromKey]); receivers key reassembly on it and drop chunks whose
/// prefix equals their own.
///
/// [parity] appends one XOR parity chunk (GRP_DATA is unacknowledged, so this
/// buys recovery of exactly one lost chunk).
///
/// Throws [ArgumentError] when [payload] exceeds [kImageMaxPayloadBytes].
ImageChunkSet buildImageChunks({
  required Uint8List payload,
  required ImageStreamMetadata metadata,
  required int senderPrefix,
  required int imgId,
  bool parity = true,
}) {
  if (payload.length > kImageMaxPayloadBytes) {
    throw ArgumentError.value(
      payload.length,
      'payload',
      'exceeds kImageMaxPayloadBytes ($kImageMaxPayloadBytes)',
    );
  }
  final total = imageDataChunkCount(payload.length);

  // Build the bodies first; parity is a pure function of them.
  final bodies = <Uint8List>[];
  var offset = 0;
  for (var i = 0; i < total; i++) {
    final capacity = i == 0 ? kImageChunkFirstCapacity : kImageChunkCapacity;
    final take = math.min(capacity, payload.length - offset);
    final body = BytesBuilder();
    if (i == 0) body.addByte(metadata.encode());
    if (take > 0) body.add(payload.sublist(offset, offset + take));
    offset += take;
    bodies.add(body.toBytes());
  }

  final blobs = <Uint8List>[];
  for (var i = 0; i < total; i++) {
    final blob = BytesBuilder()
      ..add(_writeHeader(senderPrefix, imgId, i, total))
      ..add(bodies[i]);
    blobs.add(blob.toBytes());
  }

  if (parity) {
    final xor = Uint8List(kImageChunkBodyBytes);
    var lenXor = 0;
    for (final body in bodies) {
      lenXor ^= body.length;
      for (var j = 0; j < body.length; j++) {
        xor[j] ^= body[j];
      }
    }
    final blob = BytesBuilder()
      ..add(_writeHeader(senderPrefix, imgId, total, total))
      ..addByte(lenXor & 0xFF)
      ..add(xor);
    blobs.add(blob.toBytes());
  }

  return ImageChunkSet(
    blobs: blobs,
    dataChunkCount: total,
    hasParity: parity,
    imgId: imgId,
    senderPrefix: senderPrefix,
  );
}

/// Hands out per-image ids, avoiding immediate reuse.
///
/// The id is only 8 bits, so it wraps; the reassembly key also includes the
/// sender prefix and channel, and entries expire after
/// [kImageReassemblyTtl], which bounds the damage of a wrap.
class ImageIdAllocator {
  int _next;

  ImageIdAllocator({int? seed, math.Random? random})
    : _next = seed ?? (random ?? math.Random()).nextInt(256);

  int next() {
    final id = _next & 0xFF;
    _next = (_next + 1) & 0xFF;
    return id;
  }
}

// ---------------------------------------------------------------------------
// Reassembly (receive side)
// ---------------------------------------------------------------------------

/// Identity of one in-flight image.
class ImageStreamKey {
  final int senderPrefix;
  final int imgId;
  final int channelIndex;

  const ImageStreamKey({
    required this.senderPrefix,
    required this.imgId,
    required this.channelIndex,
  });

  @override
  bool operator ==(Object other) =>
      other is ImageStreamKey &&
      other.senderPrefix == senderPrefix &&
      other.imgId == imgId &&
      other.channelIndex == channelIndex;

  @override
  int get hashCode => Object.hash(senderPrefix, imgId, channelIndex);

  @override
  String toString() =>
      'ImageStreamKey(0x'
      '${senderPrefix.toRadixString(16).padLeft(4, '0')}/$imgId@$channelIndex)';
}

/// What happened to a single received blob.
enum ImageChunkStatus {
  /// Not a well-formed chunk of ours; ignored.
  malformed,

  /// Chunk claims our own sender prefix — a loopback of something we sent.
  fromSelf,

  /// Stored; the image is still incomplete.
  accepted,

  /// Already had this chunk; ignored.
  duplicate,

  /// Conflicted with what we already held for this key (different `total`, or
  /// a different body for the same index). The stream was reset and restarted
  /// from this chunk.
  conflicting,

  /// Reassembled, but chunk 0's metadata byte names a rate point or resolution
  /// this build cannot decode. Also discarded — see
  /// [ImageStreamMetadata.decode].
  unsupportedFormat,

  /// This chunk completed the image; [ImageChunkOutcome.result] is set.
  completed,
}

/// Why an image was given up on.
enum ImageReassemblyFailureReason {
  /// TTL elapsed with chunks still missing.
  expired,

  /// Evicted to keep the pending map inside its size cap.
  overflow,

  /// Reassembled but the metadata byte was undecodable
  /// ([ImageChunkStatus.unsupportedFormat]).
  unsupportedFormat,
}

/// A fully reassembled image.
class ImageReassemblyResult {
  final ImageStreamKey key;

  /// Null when chunk 0 was recovered but carried an unknown metadata byte.
  final ImageStreamMetadata? metadata;

  /// The encoded image bitstream, exactly as the sender produced it.
  final Uint8List data;

  /// True when one chunk was rebuilt from the XOR parity chunk.
  final bool recoveredWithParity;

  /// Number of data chunks in the image.
  final int chunkCount;

  const ImageReassemblyResult({
    required this.key,
    required this.metadata,
    required this.data,
    required this.recoveredWithParity,
    required this.chunkCount,
  });
}

/// A stream that was given up on: expired, evicted, corrupt or undecodable.
class ImageReassemblyFailure {
  final ImageStreamKey key;
  final int total;
  final int receivedDataChunks;
  final bool hadParity;
  final DateTime firstSeen;
  final DateTime expiredAt;

  /// Why it was given up on. Defaults to [ImageReassemblyFailureReason.expired]
  /// so existing call sites keep compiling.
  final ImageReassemblyFailureReason reason;

  const ImageReassemblyFailure({
    required this.key,
    required this.total,
    required this.receivedDataChunks,
    required this.hadParity,
    required this.firstSeen,
    required this.expiredAt,
    this.reason = ImageReassemblyFailureReason.expired,
  });

  int get missingChunks => total - receivedDataChunks;

  /// True when every chunk arrived but the bytes were unusable — the UI should
  /// say "corrupt", not "incomplete".
  bool get isCorrupt =>
      reason == ImageReassemblyFailureReason.unsupportedFormat;

  @override
  String toString() =>
      'ImageReassemblyFailure($key, '
      '$receivedDataChunks/$total, parity: $hadParity, ${reason.name})';
}

/// Result of feeding one blob to [ImageReassembler.addChunk].
class ImageChunkOutcome {
  final ImageChunkStatus status;
  final ImageChunkHeader? header;
  final ImageReassemblyResult? result;

  const ImageChunkOutcome(this.status, {this.header, this.result});

  bool get isComplete => status == ImageChunkStatus.completed;
}

/// A recently-delivered image, kept for [kImageReassemblyTtl] so late chunks can
/// be distinguished from a new image that reuses the same img_id.
class _CompletedImage {
  final DateTime at;
  final int total;
  final Map<int, Uint8List> bodies;
  final Uint8List? parityBody;

  _CompletedImage({
    required this.at,
    required this.total,
    required this.bodies,
    required this.parityBody,
  });

  /// True when [header]/[body] is a re-send of something already delivered.
  ///
  /// Conservative by design: anything that does not byte-match what we
  /// delivered is treated as new, because dropping a real image is far worse
  /// than re-opening a stream for a straggler.
  bool matches(ImageChunkHeader header, List<int> body) {
    if (header.total != total) return false;
    // In the loss-free case the image completes on its last DATA chunk, so the
    // parity chunk arrives afterwards and we never stored one. Parity is a pure
    // function of the delivered bodies, so recompute it rather than guessing:
    // that keeps the trailing parity a duplicate while still letting a genuinely
    // different image through.
    final known = header.isParity
        ? (parityBody ?? _expectedParityBody())
        : bodies[header.index];
    if (known == null) return false;
    if (known.length != body.length) return false;
    for (var i = 0; i < known.length; i++) {
      if (known[i] != body[i]) return false;
    }
    return true;
  }

  /// The parity body this image would have produced, mirroring
  /// [buildImageChunks]: `[len_xor] + XOR(bodies zero-padded)`.
  Uint8List? _expectedParityBody() {
    if (bodies.length != total) return null;
    final xor = Uint8List(kImageChunkBodyBytes);
    var lenXor = 0;
    for (var i = 0; i < total; i++) {
      final b = bodies[i];
      if (b == null) return null;
      lenXor ^= b.length;
      for (var j = 0; j < b.length; j++) {
        xor[j] ^= b[j];
      }
    }
    return Uint8List.fromList(<int>[lenXor & 0xFF, ...xor]);
  }
}

class _PendingImage {
  final ImageStreamKey key;
  final int total;
  final DateTime firstSeen;
  final Map<int, Uint8List> bodies = <int, Uint8List>{};
  Uint8List? parityBody;
  DateTime lastSeen;

  _PendingImage({
    required this.key,
    required this.total,
    required this.firstSeen,
  }) : lastSeen = firstSeen;

  bool get hasParity => parityBody != null;

  bool get isComplete => bodies.length == total;

  bool get isRecoverable => bodies.length == total - 1 && hasParity;
}

/// Collects chunks into whole images. Pure Dart, no IO, injectable clock.
///
/// Out-of-order and duplicate tolerant. Entries older than [ttl] (measured
/// from the first chunk seen for that image) are evicted and reported through
/// [onFailed].
class ImageReassembler {
  /// Prefix of the local node's own public key; chunks bearing it are dropped
  /// as loopback. Null disables the check.
  final int? selfPrefix;

  final Duration ttl;

  /// Hard cap on concurrently tracked images; the oldest is evicted (and
  /// reported as failed) when exceeded.
  final int maxConcurrentStreams;

  /// Hard cap on remembered COMPLETED images; the oldest is dropped when
  /// exceeded.
  ///
  /// Without this the map was bounded only by [ttl] times the packet rate. A
  /// lone parity chunk with `total == 1, idx == 1` completes a whole image by
  /// itself, so every single received packet — noise, a fuzzer, a hostile
  /// neighbour — could mint one entry, each retaining up to
  /// [kImageMaxDataChunks] * [kImageChunkBodyBytes] of bodies. [_pending] was
  /// already capped; this is the same cap on the other map.
  final int maxCompletedStreams;

  final void Function(ImageReassemblyResult result)? onImage;
  final void Function(ImageReassemblyFailure failure)? onFailed;

  final DateTime Function() _clock;

  final Map<ImageStreamKey, _PendingImage> _pending =
      <ImageStreamKey, _PendingImage>{};

  /// Keys completed within the last [ttl]. Needed because in the loss-free
  /// case the parity chunk arrives AFTER the image is already complete; without
  /// this it would open a fresh stream that could never finish and would later
  /// be reported as a failure.
  ///
  /// The delivered bodies are retained (a completed image is at most
  /// [kImageMaxDataChunks] * [kImageChunkBodyBytes], a couple of KiB) so a late
  /// chunk can be told apart from a genuinely NEW image that happens to reuse
  /// the same img_id. Keying on time alone silently swallowed the latter:
  /// [ImageIdAllocator] seeds from `Random().nextInt(256)`, so a restart can
  /// re-roll onto an id used seconds earlier.
  final Map<ImageStreamKey, _CompletedImage> _recentlyCompleted =
      <ImageStreamKey, _CompletedImage>{};

  ImageReassembler({
    this.selfPrefix,
    this.ttl = kImageReassemblyTtl,
    this.maxConcurrentStreams = 8,
    this.maxCompletedStreams = 8,
    this.onImage,
    this.onFailed,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Number of images currently being reassembled.
  int get pendingCount => _pending.length;

  /// Keys of the images currently being reassembled (test/debug aid).
  Iterable<ImageStreamKey> get pendingKeys => _pending.keys;

  /// Number of recently-completed images remembered for straggler detection.
  int get completedCount => _recentlyCompleted.length;

  /// Keys of the remembered completed images (test/debug aid).
  Iterable<ImageStreamKey> get completedKeys => _recentlyCompleted.keys;

  /// Drops everything (e.g. on disconnect). Does not fire [onFailed].
  void clear() {
    _pending.clear();
    _recentlyCompleted.clear();
  }

  /// Feeds one received GRP_DATA blob.
  ///
  /// [now] overrides the clock for tests. Expired entries are swept first, so
  /// a caller that only ever calls [addChunk] still gets TTL behaviour.
  ImageChunkOutcome addChunk(
    Uint8List blob, {
    int channelIndex = 0,
    DateTime? now,
  }) {
    final at = now ?? _clock();
    evictExpired(now: at);

    final header = parseImageChunkHeader(blob);
    if (header == null) {
      return const ImageChunkOutcome(ImageChunkStatus.malformed);
    }
    if (selfPrefix != null && header.senderPrefix == selfPrefix) {
      return ImageChunkOutcome(ImageChunkStatus.fromSelf, header: header);
    }

    final body = Uint8List.sublistView(blob, kImageChunkHeaderBytes);
    if (header.isParity && body.isEmpty) {
      // A parity chunk must carry at least its length byte.
      return ImageChunkOutcome(ImageChunkStatus.malformed, header: header);
    }

    final key = ImageStreamKey(
      senderPrefix: header.senderPrefix,
      imgId: header.imgId,
      channelIndex: channelIndex,
    );

    final completed = _recentlyCompleted[key];
    if (completed != null) {
      if (completed.matches(header, body)) {
        // Trailing chunk (usually parity) for an image we already delivered.
        return ImageChunkOutcome(ImageChunkStatus.duplicate, header: header);
      }
      // Same key but different content: this is a NEW image reusing the id, not
      // a straggler. Forget the completed one and fall through so the normal
      // pending/conflict path can start a fresh stream. Dropping this as a
      // duplicate would lose the image with no diagnostic at all.
      _recentlyCompleted.remove(key);
    }

    var conflicted = false;
    var entry = _pending[key];
    if (entry != null && entry.total != header.total) {
      // Same key, different shape: an id wrap or a new image reusing the id.
      _pending.remove(key);
      entry = null;
      conflicted = true;
    }
    if (entry == null) {
      entry = _PendingImage(key: key, total: header.total, firstSeen: at);
      _pending[key] = entry;
      _evictOverflow(at);
    }
    entry.lastSeen = at;

    if (header.isParity) {
      if (entry.parityBody != null) {
        return ImageChunkOutcome(ImageChunkStatus.duplicate, header: header);
      }
      entry.parityBody = Uint8List.fromList(body);
    } else {
      final existing = entry.bodies[header.index];
      if (existing != null) {
        if (_sameBytes(existing, body)) {
          return ImageChunkOutcome(ImageChunkStatus.duplicate, header: header);
        }
        // Same index, different content: treat as a new image on a reused id.
        _pending.remove(key);
        final fresh = _PendingImage(
          key: key,
          total: header.total,
          firstSeen: at,
        );
        fresh.bodies[header.index] = Uint8List.fromList(body);
        _pending[key] = fresh;
        return ImageChunkOutcome(ImageChunkStatus.conflicting, header: header);
      }
      entry.bodies[header.index] = Uint8List.fromList(body);
    }

    final finish = _tryFinish(entry);
    if (finish != null) {
      _pending.remove(key);
      // Remembered even when the bytes were bad: a verbatim re-send of the same
      // damaged chunks must not re-open the stream, while a genuine
      // retransmission (different bytes) still fails `matches` and starts a
      // fresh one.
      _remember(key, at, entry);
      final result = finish.result;
      if (result != null) {
        onImage?.call(result);
      } else {
        onFailed?.call(
          ImageReassemblyFailure(
            key: key,
            total: entry.total,
            receivedDataChunks: entry.bodies.length,
            hadParity: entry.hasParity,
            firstSeen: entry.firstSeen,
            expiredAt: at,
            reason: finish.reason!,
          ),
        );
      }
      return ImageChunkOutcome(finish.status, header: header, result: result);
    }
    return ImageChunkOutcome(
      conflicted ? ImageChunkStatus.conflicting : ImageChunkStatus.accepted,
      header: header,
    );
  }

  /// Removes streams whose first chunk is older than [ttl], reporting each
  /// through [onFailed]. Returns the failures, oldest first.
  List<ImageReassemblyFailure> evictExpired({DateTime? now}) {
    final at = now ?? _clock();
    _recentlyCompleted.removeWhere((_, c) => at.difference(c.at) >= ttl);
    final expired = <ImageReassemblyFailure>[];
    _pending.removeWhere((key, entry) {
      if (at.difference(entry.firstSeen) < ttl) return false;
      expired.add(
        ImageReassemblyFailure(
          key: key,
          total: entry.total,
          receivedDataChunks: entry.bodies.length,
          hadParity: entry.hasParity,
          firstSeen: entry.firstSeen,
          expiredAt: at,
        ),
      );
      return true;
    });
    expired.sort((a, b) => a.firstSeen.compareTo(b.firstSeen));
    for (final failure in expired) {
      onFailed?.call(failure);
    }
    return expired;
  }

  /// Records a finished (delivered OR rejected) image and keeps
  /// [_recentlyCompleted] inside [maxCompletedStreams], oldest first.
  void _remember(ImageStreamKey key, DateTime at, _PendingImage entry) {
    _recentlyCompleted[key] = _CompletedImage(
      at: at,
      total: entry.total,
      bodies: Map<int, Uint8List>.from(entry.bodies),
      parityBody: entry.parityBody,
    );
    while (_recentlyCompleted.length > maxCompletedStreams) {
      ImageStreamKey? oldestKey;
      DateTime? oldest;
      _recentlyCompleted.forEach((k, c) {
        if (oldest == null || c.at.isBefore(oldest!)) {
          oldest = c.at;
          oldestKey = k;
        }
      });
      if (oldestKey == null) return;
      _recentlyCompleted.remove(oldestKey);
    }
  }

  void _evictOverflow(DateTime at) {
    while (_pending.length > maxConcurrentStreams) {
      ImageStreamKey? oldestKey;
      DateTime? oldest;
      _pending.forEach((key, entry) {
        if (oldest == null || entry.firstSeen.isBefore(oldest!)) {
          oldest = entry.firstSeen;
          oldestKey = key;
        }
      });
      if (oldestKey == null) return;
      final victim = _pending.remove(oldestKey)!;
      onFailed?.call(
        ImageReassemblyFailure(
          key: victim.key,
          total: victim.total,
          receivedDataChunks: victim.bodies.length,
          hadParity: victim.hasParity,
          firstSeen: victim.firstSeen,
          expiredAt: at,
          reason: ImageReassemblyFailureReason.overflow,
        ),
      );
    }
  }

  _FinishOutcome? _tryFinish(_PendingImage entry) {
    if (entry.isComplete) {
      return _assemble(entry, recovered: false);
    }
    if (!entry.isRecoverable) return null;

    // Exactly one data chunk missing and we hold parity: rebuild it.
    final missing = List<int>.generate(
      entry.total,
      (i) => i,
    ).firstWhere((i) => !entry.bodies.containsKey(i));
    final parity = entry.parityBody!;
    var lengthXor = parity[0] & 0xFF;
    final xor = Uint8List(kImageChunkBodyBytes);
    final parityData = parity.length - kImageParityLengthBytes;
    for (var i = 0; i < parityData && i < xor.length; i++) {
      xor[i] = parity[kImageParityLengthBytes + i];
    }
    for (final body in entry.bodies.values) {
      lengthXor ^= body.length;
      for (var i = 0; i < body.length; i++) {
        xor[i] ^= body[i];
      }
    }
    if (lengthXor > kImageChunkBodyBytes) return null; // corrupt parity
    if (missing == 0 && lengthXor < kImageChunkZeroMetadataBytes) return null;
    // Only the LAST data chunk may be short; every earlier one is full by
    // construction. Without this, a single flipped bit in the parity length
    // byte silently yields a truncated image reported as `completed` (a
    // 3-chunk image recovering as 398 bytes instead of 400), which is worse
    // than failing: the caller has no way to know the bytes are wrong.
    if (missing < entry.total - 1 && lengthXor != kImageChunkBodyBytes) {
      return null;
    }
    entry.bodies[missing] = Uint8List.sublistView(xor, 0, lengthXor);
    return _assemble(entry, recovered: true);
  }

  _FinishOutcome? _assemble(_PendingImage entry, {required bool recovered}) {
    final first = entry.bodies[0];
    // Chunk 0 must hold the metadata byte; anything shorter cannot
    // be a chunk 0 from this framing, so keep waiting rather than guessing.
    if (first == null || first.length < kImageChunkZeroMetadataBytes) {
      return null;
    }
    final metadata = ImageStreamMetadata.decode(first[0]);
    final out = BytesBuilder();
    out.add(Uint8List.sublistView(first, kImageChunkZeroMetadataBytes));
    for (var i = 1; i < entry.total; i++) {
      final body = entry.bodies[i];
      if (body == null) return null;
      out.add(body);
    }
    final data = out.toBytes();
    if (metadata == null) {
      return const _FinishOutcome.failed(
        ImageChunkStatus.unsupportedFormat,
        ImageReassemblyFailureReason.unsupportedFormat,
      );
    }
    return _FinishOutcome.delivered(
      ImageReassemblyResult(
        key: entry.key,
        metadata: metadata,
        data: data,
        recoveredWithParity: recovered,
        chunkCount: entry.total,
      ),
    );
  }
}

/// A terminal verdict on a fully-arrived image: delivered, or rejected with a
/// reason. `null` (never an instance of this) means "still waiting".
class _FinishOutcome {
  final ImageChunkStatus status;
  final ImageReassemblyResult? result;
  final ImageReassemblyFailureReason? reason;

  const _FinishOutcome.failed(this.status, this.reason) : result = null;

  const _FinishOutcome.delivered(ImageReassemblyResult this.result)
    : status = ImageChunkStatus.completed,
      reason = null;
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Protocol glue — still pure Dart, but MeshCore-frame shaped
// ---------------------------------------------------------------------------

/// Builds a `CMD_SEND_CHANNEL_DATA` (62) frame.
///
/// Flood case (the default) emits exactly
/// `[0x3E][channel_idx][0xFF][type_lo][type_hi][...blob...]`.
/// When [pathLen] != [outPathUnknown] the packed path bytes are inserted
/// before the data type, per MyMesh.cpp:1147-1186.
///
/// The firmware replies with `RESP_CODE_OK` (0x00) — NOT `RESP_CODE_SENT` —
/// or `[0x01][err]`.
Uint8List buildSendChannelDataFrame({
  required int channelIndex,
  required int dataType,
  required Uint8List payload,
  int pathLen = outPathUnknown,
  Uint8List? path,
}) {
  final out = BytesBuilder()
    ..addByte(cmdSendChannelData)
    ..addByte(channelIndex & 0xFF)
    ..addByte(pathLen & 0xFF);
  if (pathLen != outPathUnknown && path != null) out.add(path);
  out
    ..addByte(dataType & 0xFF)
    ..addByte((dataType >> 8) & 0xFF)
    ..add(payload);
  return out.toBytes();
}

/// A parsed `RESP_CODE_CHANNEL_DATA_RECV` (27) frame.
///
/// Fixed 9-byte header, no path bytes and no sender identity — which is why
/// the sender prefix lives inside the chunk itself.
class ParsedChannelData {
  /// Signed; divide by 4.0 for dB.
  final int snrRaw;
  final int channelIndex;

  /// 0xFF means the packet arrived via a known/direct path; anything else is
  /// the packed flood path_len byte.
  final int pathLenByte;

  final int dataType;
  final Uint8List payload;

  const ParsedChannelData({
    required this.snrRaw,
    required this.channelIndex,
    required this.pathLenByte,
    required this.dataType,
    required this.payload,
  });

  bool get arrivedByFlood => pathLenByte != 0xFF;

  double get snrDb => snrRaw / 4.0;

  int? get hopCount => arrivedByFlood ? pathLenByte & 0x3F : null;

  int? get pathHashWidth =>
      arrivedByFlood ? ((pathLenByte >> 6) & 0x03) + 1 : null;
}

/// Parses a `RESP_CODE_CHANNEL_DATA_RECV` frame, or null if it is not one.
ParsedChannelData? parseChannelDataFrame(Uint8List frame) {
  if (frame.length < 9) return null;
  if (frame[0] != respCodeChannelDataRecv) return null;
  final dataLen = frame[8];
  if (frame.length < 9 + dataLen) return null;
  final snr = frame[1] >= 128 ? frame[1] - 256 : frame[1];
  return ParsedChannelData(
    snrRaw: snr,
    channelIndex: frame[4],
    pathLenByte: frame[5],
    dataType: frame[6] | (frame[7] << 8),
    payload: Uint8List.fromList(frame.sublist(9, 9 + dataLen)),
  );
}

/// Sends one blob on a channel and completes when the device acknowledges it.
///
/// Implemented by the connector-facing adapter; kept as a typedef so the
/// transport itself never imports the connector (and stays testable).
typedef ChannelBlobSender =
    Future<void> Function(Uint8List blob, int channelIndex);

/// Progress report while an image is going out.
class ImageSendProgress {
  final int sentChunks;
  final int totalChunks;
  final bool isParityChunk;

  const ImageSendProgress({
    required this.sentChunks,
    required this.totalChunks,
    required this.isParityChunk,
  });

  double get fraction => totalChunks == 0 ? 1 : sentChunks / totalChunks;
}

/// Thin IO glue: chunk an image, send its blobs strictly one at a time, and
/// route inbound frames into an [ImageReassembler].
///
/// Serialisation is not optional. `_pendingGenericAckQueue` in the connector is
/// a strict FIFO keyed only on arrival order — there is no request id in the
/// companion protocol — so two concurrent `CMD_SEND_CHANNEL_DATA` frames would
/// cross their acknowledgements.
class ImageChunkTransport {
  final ChannelBlobSender send;
  final ImageReassembler reassembler;
  final ImageIdAllocator _ids;

  /// Prefix of the local public key, stamped into every outgoing chunk.
  int senderPrefix;

  ImageChunkTransport({
    required this.send,
    required this.reassembler,
    required this.senderPrefix,
    ImageIdAllocator? idAllocator,
  }) : _ids = idAllocator ?? ImageIdAllocator();

  Future<void> _sendQueue = Future<void>.value();

  /// Chunks and transmits [payload]. Chunks go out strictly sequentially, and
  /// concurrent calls are serialised behind each other.
  ///
  /// Returns the chunk set that was sent.
  Future<ImageChunkSet> sendImage({
    required Uint8List payload,
    required ImageStreamMetadata metadata,
    int channelIndex = 0,
    bool parity = true,
    int? imgId,
    void Function(ImageSendProgress progress)? onProgress,
  }) {
    final set = buildImageChunks(
      payload: payload,
      metadata: metadata,
      senderPrefix: senderPrefix,
      imgId: imgId ?? _ids.next(),
      parity: parity,
    );
    final completed = _sendQueue.then((_) async {
      for (var i = 0; i < set.blobs.length; i++) {
        await send(set.blobs[i], channelIndex);
        onProgress?.call(
          ImageSendProgress(
            sentChunks: i + 1,
            totalChunks: set.blobs.length,
            isParityChunk: set.hasParity && i == set.blobs.length - 1,
          ),
        );
      }
      return set;
    });
    // Keep the queue alive even if this send fails.
    _sendQueue = completed.then((_) {}, onError: (Object _) {});
    return completed;
  }

  /// Feeds a raw inbound companion frame. Non-image frames are ignored.
  ///
  /// NOTE: the queued-message sync advance (`_handleQueuedMessageReceived`)
  /// still has to happen inside `_handleFrame`; a `receivedFrames` listener
  /// alone will not prevent the 5 s CMD_SYNC_NEXT_MESSAGE stall.
  ImageChunkOutcome? handleFrame(Uint8List frame) {
    final parsed = parseChannelDataFrame(frame);
    if (parsed == null) return null;
    if (parsed.dataType != dataTypeAeicImage) return null;
    return reassembler.addChunk(
      parsed.payload,
      channelIndex: parsed.channelIndex,
    );
  }
}
