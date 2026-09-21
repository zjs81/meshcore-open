import 'dart:typed_data';

/// Parsed result of a MeshCore contact QR / link.
class ScannedContact {
  /// Raw advert packet bytes (legacy `meshcore://<hex>` form), else null.
  final Uint8List? advertPacket;

  /// 32-byte public key (contact-card form), else null.
  final Uint8List? publicKey;

  /// Contact name from the card form; empty string when unknown.
  final String name;

  /// Advert type: 1 Companion, 2 Repeater, 3 Room Server, 4 Sensor.
  final int type;

  const ScannedContact({
    this.advertPacket,
    this.publicKey,
    this.name = '',
    this.type = 1,
  });

  bool get isAdvertPacket => advertPacket != null;
}

/// Matches the advert packet minimum enforced by `buildImportContactFrame`.
const int _minAdvertPacketBytes = 98;

/// `buildImportContactFrame` prepends one command byte to a `maxFrameSize`
/// (172 byte) frame, so anything longer cannot be sent.
const int _maxAdvertPacketBytes = 171;
const int _contactCardKeyBytes = 32;
const String _legacyPrefix = 'meshcore://';

/// Returns null when [data] is not a recognizable MeshCore contact QR/link.
ScannedContact? parseContactQr(String data) {
  final trimmed = data.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'meshcore') return null;

  final normalizedPath = '${uri.host}${uri.path}'.toLowerCase().replaceAll(
    RegExp(r'^/+|/+$'),
    '',
  );
  if (normalizedPath == 'contact/add') {
    return _parseContactCard(uri);
  }

  if (!trimmed.toLowerCase().startsWith(_legacyPrefix)) return null;
  final hexString = trimmed.substring(_legacyPrefix.length);
  final bytes = _tryHexDecode(hexString);
  if (bytes == null ||
      bytes.length < _minAdvertPacketBytes ||
      bytes.length > _maxAdvertPacketBytes) {
    return null;
  }
  return ScannedContact(advertPacket: bytes);
}

ScannedContact? _parseContactCard(Uri uri) {
  final params = uri.queryParameters;
  final publicKeyHex = params['public_key'];
  if (publicKeyHex == null) return null;

  final publicKey = _tryHexDecode(publicKeyHex);
  if (publicKey == null || publicKey.length != _contactCardKeyBytes) {
    return null;
  }

  final name = (params['name'] ?? '').trim();
  int type = int.tryParse(params['type'] ?? '') ?? 1;
  if (type < 1 || type > 4) type = 1;

  return ScannedContact(publicKey: publicKey, name: name, type: type);
}

/// Local hex decoder: keeps this util pure-Dart. `hex2Uint8List` in
/// `connector/meshcore_protocol.dart` throws on invalid input and that file
/// pulls in `package:flutter/widgets.dart` and `package:crypto`, which this
/// util must not depend on.
Uint8List? _tryHexDecode(String hex) {
  if (hex.isEmpty || hex.length.isOdd) return null;
  final bytes = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < bytes.length; i++) {
    final high = _hexDigit(hex.codeUnitAt(i * 2));
    final low = _hexDigit(hex.codeUnitAt(i * 2 + 1));
    if (high == null || low == null) return null;
    bytes[i] = (high << 4) | low;
  }
  return bytes;
}

int? _hexDigit(int codeUnit) {
  if (codeUnit >= 0x30 && codeUnit <= 0x39) return codeUnit - 0x30;
  if (codeUnit >= 0x61 && codeUnit <= 0x66) return codeUnit - 0x61 + 10;
  if (codeUnit >= 0x41 && codeUnit <= 0x46) return codeUnit - 0x41 + 10;
  return null;
}
