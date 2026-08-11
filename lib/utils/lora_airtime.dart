import 'dart:math' as math;

import '../models/radio_settings.dart';
// image_chunk_transport is the single source of truth for chunk geometry: it is
// what actually writes the bytes. This file used to declare rival constants
// (payload 163 / header 2), which both disagreed with the wire format AND
// collided by name -- any library importing both failed to compile. Import and
// re-export instead, so there is exactly one declaration in the program.
import '../services/image_chunk_transport.dart'
    show
        imageDataChunkCount,
        kImageChunkBlobBytes,
        kImageChunkCapacity,
        kImageChunkFirstCapacity,
        kImageChunkHeaderBytes,
        kImageChunkZeroMetadataBytes;

export '../services/image_chunk_transport.dart'
    show
        imageDataChunkCount,
        kImageChunkBlobBytes,
        kImageChunkBodyBytes,
        kImageChunkCapacity,
        kImageChunkFirstCapacity,
        kImageChunkHeaderBytes,
        kImageChunkZeroMetadataBytes,
        kImageParityLengthBytes;

/// Extra on-air bytes added by the MeshCore transport/routing header around a
/// GRP_DATA packet.
///
/// This value is NOT derivable from this repository, so it defaults to 0 and
/// the resulting airtime is therefore a lower bound for the chunk frame itself
/// (header + payload). Callers may pass a measured value to
/// [estimateSend] once the real overhead is known. Do not guess it here.
const int kMeshCoreOnAirOverheadBytes = 0;

/// MeshCore MAX_TRANS_UNIT — the largest packet that can go on air.
/// Useful as a worst-case airtime reference.
const int kMeshCoreMaxTransUnit = 255;

/// Standard LoRa time-on-air.
///
/// ## Relationship to `connector/meshcore_protocol.dart:calculateLoRaAirtime()`
///
/// That function exists and is used for *retry timeouts*; it is deliberately NOT
/// reused here, and the two must not be conflated:
///
///  * **Coding-rate domain.** `calculateLoRaAirtime()` takes the coding rate in
///    the firmware's 1..4 domain and computes `(codingRate + 4)` internally.
///    This file takes it in the 5..8 domain, matching [LoRaCodingRate.value]
///    (`cr4_5 == 5`). A raw device value may arrive in *either* domain, so
///    [normalizeCodingRate] maps 1..4 -> 5..8 before use. Passing a 5..8 value
///    to `calculateLoRaAirtime()` would silently overstate airtime by up to 60%
///    (it would compute CR 4/9..4/12), and passing a 1..4 value to
///    [loraTimeOnAir] trips its assert in debug and understates airtime in
///    release. Always normalise at the boundary.
///  * **Low-data-rate optimise.** `calculateLoRaAirtime()` takes `DE` as a
///    parameter and its one caller passes the `sf >= 11` shortcut, which is
///    wrong for SF11/BW250 and SF12/BW500 (Tsym is 8.192 ms there, below the
///    16 ms threshold). This file derives `DE` from `Tsym > 16 ms`, per the
///    datasheet. See the LDRO tests in `test/lora_airtime_test.dart`.
///  * **Precision and guards.** `calculateLoRaAirtime()` returns whole
///    milliseconds and will throw `Unsupported operation: Infinity or NaN
///    toInt` on `sf == 0` / `bw == 0`, which a half-initialised device does
///    report. This file keeps microseconds (2 packets x rounding is visible in
///    a 1-2 s figure) and forces callers through [areLoRaParamsValid].
///
/// The *flood cost* model in `calculateMessageTimeout()` — `500 ms + 16 x
/// airtime` — is a retry deadline, i.e. a deliberate upper bound on when a reply
/// could still arrive. It is not a wall-clock estimate and is not reused as one;
/// see [kImageSendChunkGapBase] for the pacing model this file uses instead.
///
///   Tsym = 2^SF / BW
///   lowDataRateOptimize (DE) = 1 if Tsym > 16 ms else 0
///   payloadSymbols = max(ceil((8*PL - 4*SF + 28 + 16*CRC - 20*IH)
///                             / (4*(SF - 2*DE))) * (CR + 4), 0)
///   ToA = (preamble + 4.25) * Tsym + (8 + payloadSymbols) * Tsym
///
/// [codingRate] is given in the 5..8 domain (5 = 4/5 … 8 = 4/8), matching
/// [LoRaCodingRate.value]. If you hold a raw firmware coding rate, normalise it
/// with [normalizeCodingRate] first.
///
/// The result is returned at microsecond precision; no rounding to whole
/// milliseconds is applied.
Duration loraTimeOnAir({
  required int payloadBytes,
  required int spreadingFactor,
  required int bandwidthHz,
  required int codingRate,
  int preambleSymbols = 8,
  bool crc = true,
  bool explicitHeader = true,
}) {
  assert(spreadingFactor >= 5 && spreadingFactor <= 12);
  assert(bandwidthHz > 0);
  assert(codingRate >= 5 && codingRate <= 8);

  final pl = math.max(payloadBytes, 0);
  final sf = spreadingFactor;

  // Symbol time in milliseconds.
  final tsymMs = (1 << sf) / (bandwidthHz / 1000.0);

  // Low data rate optimisation is mandated when a symbol lasts over 16 ms.
  final de = tsymMs > 16.0 ? 1 : 0;
  final ih = explicitHeader ? 0 : 1;

  final numerator = 8 * pl - 4 * sf + 28 + 16 * (crc ? 1 : 0) - 20 * ih;
  final denominator = 4 * (sf - 2 * de);

  final payloadSymbols = math.max(
    (numerator / denominator).ceil() * codingRate,
    0,
  );

  final preambleMs = (preambleSymbols + 4.25) * tsymMs;
  final payloadMs = (8 + payloadSymbols) * tsymMs;

  return Duration(microseconds: ((preambleMs + payloadMs) * 1000).round());
}

/// Normalises a raw firmware coding rate into the 5..8 domain used by
/// [loraTimeOnAir] and [LoRaCodingRate.value]. Some firmwares report 1..4.
int normalizeCodingRate(int deviceCodingRate) =>
    deviceCodingRate <= 4 ? deviceCodingRate + 4 : deviceCodingRate;

/// Whether [loraTimeOnAir] can safely be called with these parameters.
///
/// The radio values reaching us are raw bytes off the wire (`currentSf`,
/// `currentBwHz`, `currentCr`), so a disconnected or half-initialised device
/// can hand us zeroes. Those are not merely wrong, they are fatal: `sf == 0`
/// drives the `4 * (SF - 2*DE)` denominator to zero and the subsequent
/// `.ceil()` throws "Unsupported operation: Infinity or NaN toInt", and
/// `bandwidthHz == 0` makes the symbol time infinite. Asserts alone do not help
/// in release builds, so callers must gate on this.
///
/// [codingRate] is checked in the 5..8 domain; normalise first.
bool areLoRaParamsValid({
  required int? spreadingFactor,
  required int? bandwidthHz,
  required int? codingRate,
}) {
  if (spreadingFactor == null || bandwidthHz == null || codingRate == null) {
    return false;
  }
  if (spreadingFactor < 5 || spreadingFactor > 12) return false;
  if (bandwidthHz <= 0) return false;
  if (codingRate < 5 || codingRate > 8) return false;
  return true;
}

/// Fixed part of the gap the sender must leave between two chunk packets.
///
/// Raw airtime is only the time our own transmitter is modulating. A multi-chunk
/// image is paced: the app hands chunk *i+1* to the companion radio only after
/// chunk *i* has been queued, transmitted and the local channel has cleared, so
/// wall clock is substantially longer than the sum of the airtimes. Two numbers
/// in this repository bound that gap:
///
///  * `connector/meshcore_protocol.dart:calculateMessageTimeout()` uses a
///    **500 ms base delay** for "the companion radio has dealt with this
///    packet", independent of airtime. That is where this constant comes from.
///  * MeshCore repeaters default to a flood retransmit spacing of **0.5 x
///    airtime** (see `repeater_txDelayHelper`), and a packet is retransmitted by
///    every repeater in range, so at least one full airtime of quiet is needed
///    before the next chunk to avoid colliding with the first hop. That is
///    [kImageSendChunkGapAirtimeFactor].
///
/// This is a MODEL, not a measurement: confirming it needs real radios, which is
/// out of scope here. It is deliberately derived from numbers already shipped in
/// this app rather than invented, and it is applied only *between* packets, so a
/// single-chunk send shows raw airtime unchanged.
const Duration kImageSendChunkGapBase = Duration(milliseconds: 500);

/// Airtime-proportional part of the inter-chunk gap. See
/// [kImageSendChunkGapBase].
const double kImageSendChunkGapAirtimeFactor = 1.0;

/// The pacing gap left after transmitting a packet whose airtime is
/// [packetAirtime], before the next chunk is queued.
Duration imageSendChunkGap(Duration packetAirtime) => Duration(
  microseconds:
      kImageSendChunkGapBase.inMicroseconds +
      (packetAirtime.inMicroseconds * kImageSendChunkGapAirtimeFactor).round(),
);

/// Result of estimating an image (or any chunked payload) send.
///
/// [perPacketAirtime] and [totalAirtime] are null when the radio parameters are
/// unknown — in that case the packet count is still meaningful and should be
/// shown, but no airtime may be fabricated.
class SendEstimate {
  /// Number of packets that will be transmitted, including the parity packet
  /// when [includesParity] is true.
  final int chunkCount;

  /// Total on-air bytes across all packets (chunk headers + payload + any
  /// configured transport overhead), including the parity packet.
  final int totalBytes;

  /// Airtime of one maximally-filled chunk packet, or null if the radio
  /// parameters are unknown.
  final Duration? perPacketAirtime;

  /// Sum of the airtime of every packet actually sent, or null if the radio
  /// parameters are unknown.
  ///
  /// This is transmitter occupancy only. For anything the user is asked to wait
  /// for, show [pacedWallClock] instead.
  final Duration? totalAirtime;

  /// Realistic wall clock for the whole send: [totalAirtime] plus the
  /// inter-chunk pacing gap ([imageSendChunkGap]) after every packet but the
  /// last. Null exactly when [totalAirtime] is null.
  ///
  /// Equal to [totalAirtime] for a single-packet send.
  final Duration? pacedWallClock;

  /// Whether a XOR parity packet is included in [chunkCount] / [totalBytes].
  final bool includesParity;

  const SendEstimate({
    required this.chunkCount,
    required this.totalBytes,
    required this.perPacketAirtime,
    required this.totalAirtime,
    required this.pacedWallClock,
    required this.includesParity,
  });

  /// True when airtime could be computed (radio parameters were known).
  bool get hasAirtime => totalAirtime != null;

  @override
  String toString() =>
      'SendEstimate(chunks: $chunkCount, bytes: $totalBytes, '
      'perPacket: $perPacketAirtime, total: $totalAirtime, '
      'wallClock: $pacedWallClock, parity: $includesParity)';

  @override
  bool operator ==(Object other) =>
      other is SendEstimate &&
      other.chunkCount == chunkCount &&
      other.totalBytes == totalBytes &&
      other.perPacketAirtime == perPacketAirtime &&
      other.totalAirtime == totalAirtime &&
      other.pacedWallClock == pacedWallClock &&
      other.includesParity == includesParity;

  @override
  int get hashCode => Object.hash(
    chunkCount,
    totalBytes,
    perPacketAirtime,
    totalAirtime,
    pacedWallClock,
    includesParity,
  );
}

/// Number of data chunks needed for [payloadBytes], excluding parity.
///
/// Delegates to the transport so the estimate shown in the preview can never
/// disagree with what the chunker actually emits. Differs from
/// [imageDataChunkCount] in one respect only: a zero-byte payload needs zero
/// chunks here (there is nothing to estimate), whereas the transport still
/// emits one chunk so a receiver can observe an empty image.
int imageChunkCount(int payloadBytes) {
  if (payloadBytes <= 0) return 0;
  return imageDataChunkCount(payloadBytes);
}

/// Payload bytes carried by each data chunk, in order.
List<int> imageChunkPayloadSizes(int payloadBytes) {
  final count = imageChunkCount(payloadBytes);
  if (count == 0) return const [];
  final sizes = <int>[];
  var remaining = payloadBytes;
  for (var i = 0; i < count; i++) {
    final capacity = i == 0 ? kImageChunkFirstCapacity : kImageChunkCapacity;
    final take = remaining < capacity ? remaining : capacity;
    sizes.add(take);
    remaining -= take;
  }
  return sizes;
}

/// Estimates packet count and airtime for sending [payloadBytes] of chunked
/// image data.
///
/// [radio] may be null (radio settings not yet read from the device). In that
/// case the packet count and byte totals are still returned but both airtime
/// fields are null — no default SF/BW is substituted, because a fabricated ETA
/// is worse than none for a feature whose purpose is informed consent.
///
/// [parity] adds exactly one XOR parity packet (GRP_DATA is unacknowledged, so
/// parity allows recovery of a single lost chunk). No parity packet is added
/// for an empty payload.
SendEstimate estimateSend({
  required int payloadBytes,
  required RadioSettings? radio,
  bool parity = true,
  int onAirOverheadBytes = kMeshCoreOnAirOverheadBytes,
}) {
  return estimateSendFromRadioParams(
    payloadBytes: payloadBytes,
    spreadingFactor: radio?.spreadingFactor.value,
    bandwidthHz: radio?.bandwidth.hz,
    codingRate: radio?.codingRate.value,
    parity: parity,
    onAirOverheadBytes: onAirOverheadBytes,
  );
}

/// Same as [estimateSend] but takes the raw, individually-nullable radio
/// parameters exposed by the connector (`currentSf`, `currentBwHz`,
/// `currentCr`). [codingRate] may be in either the 1..4 or 5..8 firmware
/// encoding; it is normalised via [normalizeCodingRate].
SendEstimate estimateSendFromRadioParams({
  required int payloadBytes,
  required int? spreadingFactor,
  required int? bandwidthHz,
  required int? codingRate,
  bool parity = true,
  int onAirOverheadBytes = kMeshCoreOnAirOverheadBytes,
}) {
  final payload = math.max(payloadBytes, 0);
  final sizes = imageChunkPayloadSizes(payload);
  final dataChunks = sizes.length;
  final withParity = parity && dataChunks > 0;

  // On-air bytes per packet: chunk header + payload (+ chunk 0 metadata)
  // + any transport overhead.
  // On-air blob layout, taken from buildImageChunks() rather than assumed:
  //   data chunk : header + body            (chunk 0's body opens with metadata)
  //   parity     : header + len byte + a FULL kImageChunkBodyBytes XOR body
  // The parity-length byte belongs to the PARITY chunk only — charging it to
  // every data chunk, and sizing parity from the largest data body, understated
  // a 110-byte payload as 232 on-air bytes when the real total is 278.
  final packetBytes = <int>[];
  for (var i = 0; i < sizes.length; i++) {
    final meta = i == 0 ? kImageChunkZeroMetadataBytes : 0;
    packetBytes.add(
      kImageChunkHeaderBytes + meta + sizes[i] + onAirOverheadBytes,
    );
  }
  if (withParity) {
    // Always the full blob: the XOR body is zero-padded to kImageChunkBodyBytes
    // regardless of how short the data chunks are.
    packetBytes.add(kImageChunkBlobBytes + onAirOverheadBytes);
  }

  final totalBytes = packetBytes.fold<int>(0, (a, b) => a + b);
  final chunkCount = packetBytes.length;

  // Only non-null AND in-range parameters are safe: see [areLoRaParamsValid].
  // Anything else yields an estimate with packet counts but no airtime, which
  // the UI must render as "unknown" rather than fabricating a number.
  final cr = codingRate == null ? null : normalizeCodingRate(codingRate);
  final known = areLoRaParamsValid(
    spreadingFactor: spreadingFactor,
    bandwidthHz: bandwidthHz,
    codingRate: cr,
  );
  if (!known) {
    return SendEstimate(
      chunkCount: chunkCount,
      totalBytes: totalBytes,
      perPacketAirtime: null,
      totalAirtime: null,
      pacedWallClock: null,
      includesParity: withParity,
    );
  }

  // Safe to force: areLoRaParamsValid() above proved all three are non-null
  // and in range.
  Duration airtimeFor(int bytes) => loraTimeOnAir(
    payloadBytes: bytes,
    spreadingFactor: spreadingFactor!,
    bandwidthHz: bandwidthHz!,
    codingRate: cr!,
  );

  // Airtime of a maximally-filled chunk packet, i.e. the cost of one "typical"
  // packet in the stream. A full blob is the whole kImageChunkBlobBytes.
  final perPacket = airtimeFor(kImageChunkBlobBytes + onAirOverheadBytes);

  var totalMicros = 0;
  // Wall clock adds a pacing gap after every packet except the last, so a
  // single-packet send is unaffected. See [kImageSendChunkGapBase].
  var wallClockMicros = 0;
  for (var i = 0; i < packetBytes.length; i++) {
    final airtime = airtimeFor(packetBytes[i]);
    totalMicros += airtime.inMicroseconds;
    wallClockMicros += airtime.inMicroseconds;
    if (i != packetBytes.length - 1) {
      wallClockMicros += imageSendChunkGap(airtime).inMicroseconds;
    }
  }

  return SendEstimate(
    chunkCount: chunkCount,
    totalBytes: totalBytes,
    perPacketAirtime: perPacket,
    totalAirtime: Duration(microseconds: totalMicros),
    pacedWallClock: Duration(microseconds: wallClockMicros),
    includesParity: withParity,
  );
}
