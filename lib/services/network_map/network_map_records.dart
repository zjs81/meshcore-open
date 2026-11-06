import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../connector/meshcore_protocol.dart';
import '../../connector/raw_packet.dart';
import '../../utils/location_grid.dart';

/// Records uploaded to the network map (see the server's API contract).
///
/// Everything here is built from the packet header, path and signal values
/// only. Payloads, MACs, channel hashes, DM hashes, transport codes and exact
/// coordinates never make it into a record.

const String hiddenNodeMarker = '\u{1F6AB}';
const int _maxUploadPathBytes = 64;
const int _maxAdvertNameBytes = 32;
const int _advertPubKeySize = 32;
const int _advertSignatureSize = 64;
const int _maxAdvertDataSize = 32;

class NetworkMapLoc {
  final double lat;
  final double lon;

  const NetworkMapLoc(this.lat, this.lon);

  factory NetworkMapLoc.snapped(double lat, double lon) {
    final snapped = snapToLocationGrid(lat, lon);
    return NetworkMapLoc(snapped.lat, snapped.lon);
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};
}

class NetworkMapPreset {
  final int freqKhz;
  final double bwKhz;
  final int sf;
  final int cr;

  const NetworkMapPreset({
    required this.freqKhz,
    required this.bwKhz,
    required this.sf,
    required this.cr,
  });

  static const List<double> _allowedBwKhz = [
    7.8,
    10.4,
    15.6,
    20.8,
    31.25,
    41.7,
    62.5,
    125,
    250,
    500,
  ];

  /// From the radio's self-info values; null when any is missing or outside
  /// what the server accepts. Firmware reports frequency in kHz, bandwidth in
  /// Hz and coding rate as 1–4 or 5–8.
  static NetworkMapPreset? fromRadio({
    int? freqKhz,
    int? bwHz,
    int? sf,
    int? cr,
  }) {
    if (freqKhz == null || bwHz == null || sf == null || cr == null) {
      return null;
    }
    final bwKhz = _allowedBwKhz.where((bw) => (bw * 1000 - bwHz).abs() < 1);
    final codingRate = cr <= 4 ? cr + 4 : cr;
    if (freqKhz < 100000 ||
        freqKhz > 1100000 ||
        bwKhz.isEmpty ||
        sf < 5 ||
        sf > 12 ||
        codingRate < 5 ||
        codingRate > 8) {
      return null;
    }
    return NetworkMapPreset(
      freqKhz: freqKhz,
      bwKhz: bwKhz.first,
      sf: sf,
      cr: codingRate,
    );
  }

  Map<String, dynamic> toJson() => {
    'freqKhz': freqKhz,
    'bwKhz': bwKhz,
    'sf': sf,
    'cr': cr,
  };
}

class NetworkMapPacketRecord {
  final int t;
  final int pt;
  final int rt;
  final int hw;
  final String path;
  final double snr;
  final int rssi;
  final int size;
  final String h;
  final bool scoped;

  const NetworkMapPacketRecord({
    required this.t,
    required this.pt,
    required this.rt,
    required this.hw,
    required this.path,
    required this.snr,
    required this.rssi,
    required this.size,
    required this.h,
    required this.scoped,
  });

  Map<String, dynamic> toJson() => {
    't': t,
    'pt': pt,
    'rt': rt,
    'hw': hw,
    'path': path,
    'snr': snr,
    'rssi': rssi,
    'size': size,
    'h': h,
    'scoped': scoped,
  };
}

class NetworkMapAdvertRecord {
  final int t;
  final String key;
  final int type;
  final String? name;
  final NetworkMapLoc? loc;
  final bool hidden;
  final double snr;
  final int rssi;
  final int rt;
  final int hw;
  final String path;

  const NetworkMapAdvertRecord({
    required this.t,
    required this.key,
    required this.type,
    required this.name,
    required this.loc,
    required this.hidden,
    required this.snr,
    required this.rssi,
    required this.rt,
    required this.hw,
    required this.path,
  });

  Map<String, dynamic> toJson() => {
    't': t,
    'key': key,
    'type': type,
    'name': name,
    'loc': loc?.toJson(),
    'hidden': hidden,
    'snr': snr,
    'rssi': rssi,
    'rt': rt,
    'hw': hw,
    'path': path,
  };
}

/// Header, path and signal fields of a `PUSH_CODE_LOG_RX_DATA` frame.
class _RxFrame {
  final double snr;
  final int rssi;
  final int rawLength;
  final int routeType;
  final int payloadType;
  final int hashWidth;
  final Uint8List pathBytes;
  final Uint8List payload;

  _RxFrame({
    required this.snr,
    required this.rssi,
    required this.rawLength,
    required this.routeType,
    required this.payloadType,
    required this.hashWidth,
    required this.pathBytes,
    required this.payload,
  });

  bool get scoped => routeType == 0 || routeType == 3;

  String get pathHex => _hex(pathBytes);
}

_RxFrame? _parseRxFrame(Uint8List frame) {
  if (frame.isEmpty || frame[0] != pushCodeLogRxData) return null;
  try {
    final reader = BufferReader(frame);
    reader.skipBytes(1);
    final snr = reader.readInt8() / 4.0;
    final rssi = reader.readInt8();
    final rawLength = reader.remaining;
    final header = reader.readByte();
    final routeType = header & 0x03;
    final payloadType = (header >> 2) & 0x0F;
    if (routeType == 0 || routeType == 3) {
      reader.skipBytes(4); // transport codes: never uploaded
    }
    final pathLenRaw = reader.readByte();
    final hashWidth = decodePathHashWidth(pathLenRaw);
    final pathBytes = reader.readBytes(decodePathByteLen(pathLenRaw));
    final payload = reader.readBytes(reader.remaining);
    if (hashWidth > 3 || pathBytes.length > _maxUploadPathBytes) return null;
    return _RxFrame(
      snr: snr.clamp(-32.0, 32.0).toDouble(),
      rssi: rssi.clamp(-200, 0).toInt(),
      rawLength: rawLength,
      routeType: routeType,
      payloadType: payloadType,
      hashWidth: hashWidth,
      pathBytes: pathBytes,
      payload: payload,
    );
  } catch (_) {
    return null;
  }
}

/// Unix seconds rounded down to the minute.
int networkMapMinute(DateTime time) {
  final seconds = time.millisecondsSinceEpoch ~/ 1000;
  return seconds - seconds % 60;
}

/// Raw packet length rounded up to a multiple of 16, capped at 256.
int roundUpPacketSize(int length) {
  final rounded = ((length + 15) ~/ 16) * 16;
  return rounded > 256 ? 256 : rounded;
}

/// Header-only packet record for a received 0x88 frame, or null when the
/// frame is malformed or outside what the server accepts.
NetworkMapPacketRecord? buildPacketRecord(
  Uint8List frame,
  DateTime receivedAt,
) {
  final rx = _parseRxFrame(frame);
  if (rx == null) return null;
  return NetworkMapPacketRecord(
    t: networkMapMinute(receivedAt),
    pt: rx.payloadType,
    rt: rx.routeType,
    hw: rx.hashWidth,
    path: rx.pathHex,
    snr: rx.snr,
    rssi: rx.rssi,
    size: roundUpPacketSize(rx.rawLength),
    h: computePacketHash(rx.payloadType, rx.payload),
    scoped: rx.scoped,
  );
}

/// Advert record for a received repeater or room server advert whose Ed25519
/// signature verifies. Chat and sensor adverts, unsigned or malformed adverts
/// and anything that isn't an advert return null.
Future<NetworkMapAdvertRecord?> buildAdvertRecord(
  Uint8List frame,
  DateTime receivedAt,
) async {
  final rx = _parseRxFrame(frame);
  if (rx == null || rx.payloadType != payloadTypeADVERT) return null;
  final payload = rx.payload;
  const appDataStart = _advertPubKeySize + 4 + _advertSignatureSize;
  if (payload.length <= appDataStart) return null;

  // Only the first 32 app-data bytes are signed (firmware Mesh.cpp truncates
  // to MAX_ADVERT_DATA_SIZE before verifying and parsing), so bytes appended
  // after them must never reach the name, location or 🚫 check.
  final appData = payload.sublist(
    appDataStart,
    min(payload.length, appDataStart + _maxAdvertDataSize),
  );
  final flags = appData[0];
  final type = flags & 0x0F;
  if (type != advTypeRepeater && type != advTypeRoom) return null;

  final publicKey = payload.sublist(0, _advertPubKeySize);
  if (!await _verifyAdvertSignature(payload, publicKey)) return null;

  // Same layout as the firmware's AdvertDataParser.
  var i = 1;
  NetworkMapLoc? loc;
  if (flags & 0x10 != 0) {
    if (appData.length < i + 8) return null;
    final view = ByteData.sublistView(appData);
    final lat = view.getInt32(i, Endian.little) / 1e6;
    final lon = view.getInt32(i + 4, Endian.little) / 1e6;
    i += 8;
    if (_isPlausibleLocation(lat, lon)) loc = NetworkMapLoc.snapped(lat, lon);
  }
  if (flags & 0x20 != 0) i += 2;
  if (flags & 0x40 != 0) i += 2;
  String? name;
  if (flags & 0x80 != 0 && appData.length > i) {
    var nameBytes = appData.sublist(i);
    final nul = nameBytes.indexOf(0);
    if (nul >= 0) nameBytes = nameBytes.sublist(0, nul);
    final decoded = utf8.decode(nameBytes, allowMalformed: true);
    if (decoded.isNotEmpty) name = decoded;
  }

  final hidden = name != null && name.contains(hiddenNodeMarker);
  return NetworkMapAdvertRecord(
    t: networkMapMinute(receivedAt),
    key: _hex(publicKey),
    type: type,
    name: hidden || name == null
        ? null
        : _truncateUtf8(name, _maxAdvertNameBytes),
    loc: hidden ? null : loc,
    hidden: hidden,
    snr: rx.snr,
    rssi: rx.rssi,
    rt: rx.routeType,
    hw: rx.hashWidth,
    path: rx.pathHex,
  );
}

/// The firmware signs pubkey ‖ timestamp ‖ app_data (app_data capped at
/// MAX_ADVERT_DATA_SIZE), see Mesh::createAdvert.
Future<bool> _verifyAdvertSignature(
  Uint8List payload,
  Uint8List publicKey,
) async {
  const sigStart = _advertPubKeySize + 4;
  const appDataStart = sigStart + _advertSignatureSize;
  var appDataEnd = payload.length;
  if (appDataEnd - appDataStart > _maxAdvertDataSize) {
    appDataEnd = appDataStart + _maxAdvertDataSize;
  }
  final message = <int>[
    ...payload.sublist(0, sigStart),
    ...payload.sublist(appDataStart, appDataEnd),
  ];
  try {
    return await Ed25519().verify(
      message,
      signature: Signature(
        payload.sublist(sigStart, appDataStart),
        publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
      ),
    );
  } catch (_) {
    return false;
  }
}

bool _isPlausibleLocation(double lat, double lon) {
  const epsilon = 1e-6;
  return (lat.abs() > epsilon || lon.abs() > epsilon) &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180;
}

String _truncateUtf8(String value, int maxBytes) {
  if (utf8.encode(value).length <= maxBytes) return value;
  final buffer = StringBuffer();
  var used = 0;
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final length = utf8.encode(char).length;
    if (used + length > maxBytes) break;
    buffer.write(char);
    used += length;
  }
  return buffer.toString();
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// The `POST /v1/upload` body. Field names and nesting follow the contract
/// exactly; the server rejects unknown fields.
Map<String, dynamic> buildUploadBody({
  required String installId,
  required String app,
  required NetworkMapLoc? loc,
  required NetworkMapPreset? preset,
  required int listenSeconds,
  required List<NetworkMapPacketRecord> packets,
  required List<NetworkMapAdvertRecord> adverts,
}) => {
  'v': 1,
  'installId': installId,
  'token': null,
  'app': app,
  'loc': loc?.toJson(),
  'preset': preset?.toJson(),
  'listenSeconds': listenSeconds.clamp(0, 600),
  'packets': [for (final p in packets) p.toJson()],
  'adverts': [for (final a in adverts) a.toJson()],
};
