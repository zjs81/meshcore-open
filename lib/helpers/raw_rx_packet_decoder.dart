import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';

/// Decoded view of one raw radio packet from `PUSH_CODE_LOG_RX_DATA`,
/// stripped of the 3-byte BLE header (code, SNR, RSSI).
class RawRxPacketInfo {
  /// Core label like `ADVERT • TRANS_FLOOD • v1`, just the payload type when
  /// parsing stopped early, or `invalid` when no header could be read.
  final String label;

  /// Payload-specific summary plus path and length, or the parse error.
  final String summary;

  final Uint8List raw;
  final Uint8List pathBytes;
  final int hashWidth;

  /// Public-key prefix of the advertising node for ADVERT payloads, empty
  /// otherwise.
  final List<int> senderPrefix;

  /// Public-key prefix of the destination for DIRECT/TRANS_DIRECT payloads,
  /// empty for broadcasts and when the packet is too short to carry it.
  final List<int> destPrefix;

  const RawRxPacketInfo({
    required this.label,
    required this.summary,
    required this.raw,
    required this.pathBytes,
    required this.hashWidth,
    this.senderPrefix = const <int>[],
    this.destPrefix = const <int>[],
  });
}

/// Length of the destination public-key prefix carried by direct messages
/// (MeshCore `initDirectMessage`).
const int destPrefixSize = 6;

RawRxPacketInfo decodeRawRxPacket(Uint8List raw) {
  if (raw.length < 2) {
    return RawRxPacketInfo(
      label: 'invalid',
      summary: 'Packet too short',
      raw: raw,
      pathBytes: Uint8List(0),
      hashWidth: 0,
    );
  }

  var index = 0;
  final header = raw[index++];
  final routeType = header & 0x03;
  final payloadType = (header >> 2) & 0x0F;
  final payloadVer = (header >> 6) & 0x03;
  final payloadLabel = payloadTypeLabel(payloadType);
  final routeLabel = routeTypeLabel(routeType);
  if (routeType == 0 || routeType == 3) {
    if (raw.length < index + 4) {
      return RawRxPacketInfo(
        label: payloadLabel,
        summary: 'Missing transport codes',
        raw: raw,
        pathBytes: Uint8List(0),
        hashWidth: 0,
      );
    }
    index += 4;
  }
  if (raw.length <= index) {
    return RawRxPacketInfo(
      label: payloadLabel,
      summary: 'Missing path length',
      raw: raw,
      pathBytes: Uint8List(0),
      hashWidth: 0,
    );
  }
  final pathLenRaw = raw[index++];
  final pathByteLen = decodeRawPathByteLen(pathLenRaw);
  final hashWidth = decodeRawPathHashWidth(pathLenRaw);
  if (raw.length < index + pathByteLen) {
    return RawRxPacketInfo(
      label: payloadLabel,
      summary: 'Truncated path',
      raw: raw,
      pathBytes: Uint8List(0),
      hashWidth: hashWidth,
    );
  }
  final pathBytes = raw.sublist(index, index + pathByteLen);
  index += pathByteLen;
  if (raw.length <= index) {
    return RawRxPacketInfo(
      label: payloadLabel,
      summary: 'Missing payload',
      raw: raw,
      pathBytes: pathBytes,
      hashWidth: hashWidth,
    );
  }
  final payload = raw.sublist(index);

  final label = '$payloadLabel • $routeLabel • v$payloadVer';
  var detail = decodePayloadSummary(payloadType, payload);
  var senderPrefix = Uint8List(0);
  var destPrefix = Uint8List(0);
  if (payloadType == 0x04 && payload.length >= destPrefixSize) {
    senderPrefix = payload.sublist(0, destPrefixSize);
  }
  if ((routeType == 2 || routeType == 3) && payload.length > destPrefixSize) {
    destPrefix = payload.sublist(0, destPrefixSize);
    detail = '$detail dest=${bytesToHex(destPrefix, spaced: false)}';
  }
  final pathSummary = pathByteLen > 0
      ? 'Path=${bytesToHex(pathBytes)}'
      : 'Path=none';
  return RawRxPacketInfo(
    label: label,
    summary: '$detail • $pathSummary • len=${raw.length}',
    raw: raw,
    pathBytes: pathBytes,
    hashWidth: hashWidth,
    senderPrefix: senderPrefix,
    destPrefix: destPrefix,
  );
}

int decodeRawPathByteLen(int pathLenRaw) {
  if (pathLenRaw == 0xFF || pathLenRaw == 0) return 0;
  final hashCount = pathLenRaw & 0x3F;
  final hashWidth = ((pathLenRaw >> 6) & 0x03) + 1;
  return hashCount * hashWidth;
}

int decodeRawPathHashWidth(int pathLenRaw) {
  if (pathLenRaw == 0xFF || pathLenRaw == 0) return 0;
  return ((pathLenRaw >> 6) & 0x03) + 1;
}

String decodePayloadSummary(int payloadType, Uint8List payload) {
  switch (payloadType) {
    case 0x00: // REQ
      return 'REQ payload=${payload.length} bytes';
    case 0x01: // RESP
      return 'RESP payload=${payload.length} bytes';
    case 0x02: // TXT
      return 'TXT payload=${payload.length} bytes';
    case 0x03: // ACK
      if (payload.length < 4) return 'ACK (short)';
      return 'ACK crc=${bytesToHex(payload.sublist(0, 4))}';
    case 0x04: // ADVERT
      return _decodeAdvertSummary(payload);
    case 0x05: // GROUP_TXT
      if (payload.length < 3) return 'GRP_TXT (short)';
      final channelHash = payload[0].toRadixString(16).padLeft(2, '0');
      final mac = bytesToHex(payload.sublist(1, 3));
      final cipherLen = payload.length - 3;
      return 'GRP_TXT hash=$channelHash mac=$mac cipher=$cipherLen';
    case 0x06: // GROUP_DATA
      return 'GRP_DATA payload=${payload.length} bytes';
    case 0x07: // ANON_REQ
      return 'ANON_REQ payload=${payload.length} bytes';
    case 0x08: // PATH
      return 'PATH payload=${payload.length} bytes';
    case 0x09: // TRACE
      return 'TRACE payload=${payload.length} bytes';
    case 0x0A: // MULTIPART
      return 'MULTIPART payload=${payload.length} bytes';
    case 0x0B: // CONTROL
      return _decodeControlSummary(payload);
    case 0x0F: // RAW
      return 'RAW payload=${payload.length} bytes';
    default:
      return 'TYPE_$payloadType payload=${payload.length} bytes';
  }
}

String _decodeAdvertSummary(Uint8List payload) {
  if (payload.length < 101) {
    return 'ADVERT (short)';
  }
  final reader = BufferReader(payload);
  try {
    final pubKey = bytesToHex(reader.readBytes(pubKeySize), spaced: false);

    final timestamp = reader.readUInt32LE();
    reader.skipBytes(signatureSize);
    final flags = reader.readByte();
    final role = deviceRoleLabel(flags & 0x0F);
    final hasLocation = (flags & 0x10) != 0;
    final hasFeature1 = (flags & 0x20) != 0;
    final hasFeature2 = (flags & 0x40) != 0;
    final hasName = (flags & 0x80) != 0;
    String? name;
    double? lat;
    double? lon;
    if (hasLocation) {
      lat = reader.readInt32LE() / 1000000.0;
      lon = reader.readInt32LE() / 1000000.0;
    }
    if (hasFeature1) reader.skipBytes(2);
    if (hasFeature2) reader.skipBytes(2);
    if (hasName) {
      name = reader.readCStringGreedy(maxNameSize);
    }
    final namePart = (name != null && name.isNotEmpty) ? ' name="$name"' : '';
    final locPart = (lat != null && lon != null)
        ? ' loc=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}'
        : '';
    return 'ADVERT role=$role ts=$timestamp$namePart$locPart key=${pubKey.substring(0, 12)}…';
  } catch (e) {
    return 'ADVERT (invalid)';
  }
}

String _decodeControlSummary(Uint8List payload) {
  final reader = BufferReader(payload);
  try {
    final flags = reader.readByte();
    final subType = flags & 0xF0;
    if (subType == 0x80) {
      if (payload.length < 6) return 'CONTROL DISCOVER_REQ (short)';
      final typeFilter = reader.readByte();
      final tag = reader.readInt32LE();
      final since = payload.length >= 10 ? reader.readInt32LE() : 0;
      return 'CONTROL DISCOVER_REQ filter=0x${typeFilter.toRadixString(16).padLeft(2, '0')} tag=$tag since=$since';
    }
    if (subType == 0x90) {
      if (payload.length < 14) return 'CONTROL DISCOVER_RESP (short)';
      final nodeType = flags & 0x0F;
      final snrRaw = payload[1];
      final snrSigned = snrRaw > 127 ? snrRaw - 256 : snrRaw;
      final snr = snrSigned / 4.0;
      final tag = reader.readInt32LE();
      final keyLen = payload.length - 6;
      return 'CONTROL DISCOVER_RESP node=${deviceRoleLabel(nodeType)} snr=${snr.toStringAsFixed(2)} tag=$tag key=$keyLen';
    }
    return 'CONTROL subtype=0x${subType.toRadixString(16).padLeft(2, '0')}';
  } catch (e) {
    return 'CONTROL (invalid)';
  }
}

String payloadTypeLabel(int payloadType) {
  switch (payloadType) {
    case 0x00:
      return 'REQ';
    case 0x01:
      return 'RESP';
    case 0x02:
      return 'TXT';
    case 0x03:
      return 'ACK';
    case 0x04:
      return 'ADVERT';
    case 0x05:
      return 'GRP_TXT';
    case 0x06:
      return 'GRP_DATA';
    case 0x07:
      return 'ANON_REQ';
    case 0x08:
      return 'PATH';
    case 0x09:
      return 'TRACE';
    case 0x0A:
      return 'MULTIPART';
    case 0x0B:
      return 'CONTROL';
    case 0x0F:
      return 'RAW';
    default:
      return 'TYPE_$payloadType';
  }
}

String routeTypeLabel(int routeType) {
  switch (routeType) {
    case 0:
      return 'TRANS_FLOOD';
    case 1:
      return 'FLOOD';
    case 2:
      return 'DIRECT';
    case 3:
      return 'TRANS_DIRECT';
    default:
      return 'ROUTE_$routeType';
  }
}

String deviceRoleLabel(int role) {
  switch (role) {
    case 0x01:
      return 'Chat';
    case 0x02:
      return 'Repeater';
    case 0x03:
      return 'Room';
    case 0x04:
      return 'Sensor';
    default:
      return 'Unknown';
  }
}

String bytesToHex(List<int> bytes, {bool spaced = true}) {
  if (bytes.isEmpty) return '';
  if (!spaced) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
