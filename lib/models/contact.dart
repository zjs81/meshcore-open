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
  final DateTime? lastModified;
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
    this.lastModified,
    DateTime? lastMessageAt,
    this.isActive = true,
    this.rawPacket,
  }) : lastMessageAt = lastMessageAt ?? lastSeen;

  String get publicKeyHex => pubKeyToHex(publicKey);

  /// Non-localized type label, intended for logs and non-UI exports
  /// (e.g. GPX). For UI use the `typeLabel(l10n)` extension in
  /// `lib/l10n/contact_localization.dart`.
  String get typeLabelRaw {
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

  bool get hasLocation {
    const double epsilon = 1e-6;
    final lat = latitude ?? 0.0;
    final lon = longitude ?? 0.0;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

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
    DateTime? lastModified,
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
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
      rawPacket: rawPacket ?? this.rawPacket,
    );
  }

  /// Formats path bytes into comma-separated hex groups of [hashByteWidth] bytes.
  String pathFormattedIdList(int hashByteWidth) {
    final pathBytes = pathBytesForDisplay;
    if (pathBytes.isEmpty) return '';
    final w = hashByteWidth.clamp(1, 4);
    final parts = <String>[];
    for (int i = 0; i < pathBytes.length; i += w) {
      final end = (i + w) <= pathBytes.length ? (i + w) : pathBytes.length;
      final chunk = pathBytes.sublist(i, end);
      parts.add(
        chunk
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(),
      );
    }
    return parts.join(',');
  }

  /// Default grouping uses legacy single-byte hop hash width.
  String get pathIdList => pathFormattedIdList(pathHashSize);

  String get shortPubKeyHex {
    return "<${publicKeyHex.substring(0, 8)}...${publicKeyHex.substring(publicKeyHex.length - 8)}>";
  }

  Uint8List get pathBytesForDisplay {
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

      // Guard: reject contacts with zeroed or mostly-zeroed public keys
      // (indicates corrupt flash storage on the firmware side)
      final zeroCount = pubKey.where((b) => b == 0).length;
      if (zeroCount > pubKeySize ~/ 2) return null;

      final type = reader.readByte();
      final flags = reader.readByte();
      final pathLen = reader.readByte();
      int hopCount = 0;
      int byteLen = 0;
      if (pathLen == 0xFF) {
        hopCount = -1;
      } else {
        final mode = (pathLen & 0xC0) >> 6;
        hopCount = pathLen & 0x3F;
        final width = mode + 1;
        byteLen = hopCount * width;
      }
      final safePathLen = byteLen > 0
          ? (byteLen > maxPathSize ? maxPathSize : byteLen)
          : 0;
      final pathBytes = reader.readBytes(maxPathSize).sublist(0, safePathLen);
      final name = reader.readCStringGreedy(maxNameSize);

      // Guard: reject contacts with non-printable names (corrupt flash data)
      if (name.isNotEmpty &&
          name.codeUnits.every((c) => c < 0x20 || c == 0xFFFD)) {
        return null;
      }

      // mandatory last_advert_timestamp
      final lastAdvertTimestamp = reader.readUInt32LE();

      double? lat, lon;
      DateTime? lastModified;
      if (reader.remaining >= 12) {
        final latRaw = reader.readInt32LE();
        final lonRaw = reader.readInt32LE();
        final lastModRaw = reader.readUInt32LE();
        // TODO: should this be &&?
        if (latRaw != 0 || lonRaw != 0) {
          lat = latRaw / 1e6;
          lon = lonRaw / 1e6;
        }
        if (lastModRaw != 0) {
          lastModified = DateTime.fromMillisecondsSinceEpoch(lastModRaw * 1000);
        }
      } else if (reader.remaining >= 8) {
        // Old layout: gps without lastmod
        final latRaw = reader.readInt32LE();
        final lonRaw = reader.readInt32LE();
        if (latRaw != 0 || lonRaw != 0) {
          lat = latRaw / 1e6;
          lon = lonRaw / 1e6;
        }
        appLogger.info(
          'Contact ${pubKeyToHex(pubKey).substring(0, 8)} has gps but no lastmod (legacy firmware layout)',
        );
      }

      return Contact(
        publicKey: pubKey,
        name: name.isEmpty ? 'Unknown' : name,
        type: type,
        flags: flags,
        pathLength: hopCount,
        path: pathBytes,
        latitude: lat,
        longitude: lon,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(
          lastAdvertTimestamp * 1000,
        ),
        lastModified: lastModified,
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
  bool get teleBaseEnabled => (flags & contactFlagTeleBase) != 0;
  bool get teleLocEnabled => (flags & contactFlagTeleLoc) != 0;
  bool get teleEnvEnabled => (flags & contactFlagTeleEnv) != 0;
}
