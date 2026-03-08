import 'dart:typed_data';
import 'package:meshcore_open/utils/app_logger.dart';

import '../connector/meshcore_protocol.dart';

class Contact {
  final Uint8List publicKey;
  final String name;
  final int type;
  final int flags;
  final int pathLength; // -1 = flood, 0+ = direct hops (from device)
  final Uint8List path; // Path bytes from device
  final int?
  pathOverride; // User's path override: -1 = force flood, null = auto
  final Uint8List? pathOverrideBytes; // User's path override bytes
  final double? latitude;
  final double? longitude;
  final DateTime lastSeen;
  final DateTime lastMessageAt;
  final bool isActive;
  final Uint8List? rawPacket;

  Contact({
    required this.publicKey,
    required this.name,
    required this.type,
    this.flags = 0,
    required this.pathLength,
    required this.path,
    this.pathOverride,
    this.pathOverrideBytes,
    this.latitude,
    this.longitude,
    required this.lastSeen,
    DateTime? lastMessageAt,
    this.isActive = true,
    this.rawPacket,
  }) : lastMessageAt = lastMessageAt ?? lastSeen;

  String get publicKeyHex => pubKeyToHex(publicKey);

  String get typeLabel {
    switch (type) {
      case advTypeChat:
        return 'Chat';
      case advTypeRepeater:
        return 'Repeater';
      case advTypeRoom:
        return 'Room';
      case advTypeSensor:
        return 'Sensor';
      default:
        return 'Unknown';
    }
  }

  String get pathLabel {
    if (pathOverride != null) {
      if (pathOverride! < 0) return 'Flood (forced)';
      if (pathOverride == 0) return 'Direct (forced)';
      return '$pathOverride hops (forced)';
    }
    if (pathLength < 0) return 'Flood';
    if (pathLength == 0) return 'Direct';
    return '$pathLength hops';
  }

  bool get hasLocation => latitude != null && longitude != null;
  bool get isFavorite => (flags & contactFlagFavorite) != 0;

  Contact copyWith({
    Uint8List? publicKey,
    String? name,
    int? type,
    int? flags,
    int? pathLength,
    Uint8List? path,
    int? pathOverride,
    Uint8List? pathOverrideBytes,
    bool clearPathOverride = false,
    double? latitude,
    double? longitude,
    DateTime? lastSeen,
    DateTime? lastMessageAt,
    bool? isActive,
    Uint8List? rawPacket,
  }) {
    return Contact(
      publicKey: publicKey ?? this.publicKey,
      name: name ?? this.name,
      type: type ?? this.type,
      flags: flags ?? this.flags,
      pathLength: pathLength ?? this.pathLength,
      path: path ?? this.path,
      pathOverride: clearPathOverride
          ? null
          : (pathOverride ?? this.pathOverride),
      pathOverrideBytes: clearPathOverride
          ? null
          : (pathOverrideBytes ?? this.pathOverrideBytes),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      rawPacket: rawPacket ?? this.rawPacket,
    );
  }

  String get pathIdList {
    final pathBytes = _pathBytesForDisplay;
    if (pathBytes.isEmpty) return '';
    final parts = <String>[];
    final groupSize = pathHashSize;
    for (int i = 0; i < pathBytes.length; i += groupSize) {
      final end = (i + groupSize) <= pathBytes.length
          ? (i + groupSize)
          : pathBytes.length;
      final chunk = pathBytes.sublist(i, end);
      parts.add(
        chunk
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(),
      );
    }
    return parts.join(',');
  }

  String get shortPubKeyHex {
    return "<${publicKeyHex.substring(0, 8)}...${publicKeyHex.substring(publicKeyHex.length - 8)}>";
  }

  Uint8List? get traceRouteBytes {
    final pathBytes = _pathBytesForDisplay;
    Uint8List? traceBytes;

    if (pathBytes.isEmpty) {
      traceBytes = Uint8List(1);
      traceBytes[0] = publicKey[0];
      return traceBytes;
    }

    if (type == advTypeRepeater || type == advTypeRoom) {
      final len = (pathBytes.length + pathBytes.length + 1);
      traceBytes = Uint8List(len);
      traceBytes[pathBytes.length] = publicKey[0];
      for (int i = 0; i < pathBytes.length; i++) {
        traceBytes[i] = pathBytes[i];
        if (i < pathBytes.length) {
          traceBytes[len - 1 - i] = pathBytes[i];
        }
      }
    } else {
      if (pathBytes.length < 2) {
        return pathBytes[0] == 0 ? null : pathBytes;
      }
      final len = (pathBytes.length + pathBytes.length - 1);
      traceBytes = Uint8List(len);
      for (int i = 0; i < pathBytes.length; i++) {
        traceBytes[i] = pathBytes[i];
        if (i < pathBytes.length - 1) {
          traceBytes[len - 1 - i] = pathBytes[i];
        }
      }
    }
    return traceBytes;
  }

  Uint8List get _pathBytesForDisplay {
    if (pathOverride != null) {
      if (pathOverride! < 0) return Uint8List(0);
      return pathOverrideBytes ?? Uint8List(0);
    }
    return path;
  }

  static Contact? fromFrame(Uint8List data) {
    if (data.isEmpty) return null;
    final reader = BufferReader(data);
    try {
      final respCode = reader.readByte();
      if (respCode != respCodeContact && respCode != pushCodeNewAdvert) {
        return null;
      }
      final pubKey = reader.readBytes(pubKeySize);
      final type = reader.readByte();
      final flags = reader.readByte();
      final pathLen = reader.readByte();
      final safePathLen = pathLen > 0
          ? (pathLen > maxPathSize ? maxPathSize : pathLen)
          : 0;
      final pathBytes = reader.readBytes(maxPathSize).sublist(0, safePathLen);
      final name = reader.readCStringGreedy(maxNameSize);

      final lastMod = reader.readUInt32LE();

      double? lat, lon;
      final latRaw = reader.readInt32LE();
      final lonRaw = reader.readInt32LE();
      if (latRaw != 0 || lonRaw != 0) {
        lat = latRaw / 1e6;
        lon = lonRaw / 1e6;
      }

      return Contact(
        publicKey: pubKey,
        name: name.isEmpty ? 'Unknown' : name,
        type: type,
        flags: flags,
        pathLength: pathLen > 0 ? (pathLen > maxPathSize ? -1 : pathLen) : -1,
        path: pathBytes,
        latitude: lat,
        longitude: lon,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(lastMod * 1000),
        isActive: true,
        rawPacket: null,
      );
    } catch (e) {
      appLogger.error('Failed to parse contact frame: $e');
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Contact && publicKeyHex == other.publicKeyHex;

  @override
  int get hashCode => publicKeyHex.hashCode;
}
