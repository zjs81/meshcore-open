import 'dart:typed_data';

/// Parsed result of an official MeshCore channel QR / link:
/// `meshcore://channel/add?name=<name>&secret=<32 hex chars>`.
class ScannedChannel {
  /// Channel name as encoded in the link; never empty.
  final String name;

  /// 16-byte channel secret.
  final Uint8List psk;

  const ScannedChannel({required this.name, required this.psk});
}

const int _channelSecretBytes = 16;

/// Returns null when [data] is not a recognizable MeshCore channel QR/link.
ScannedChannel? parseChannelQr(String data) {
  final trimmed = data.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'meshcore') return null;

  final normalizedPath = '${uri.host}${uri.path}'.toLowerCase().replaceAll(
    RegExp(r'^/+|/+$'),
    '',
  );
  if (normalizedPath != 'channel/add') return null;

  // Decoding throws on malformed percent-encoding (e.g. `name=%FF`); the
  // scanner calls this from its validator, so treat that as not a channel QR.
  final Map<String, String> params;
  try {
    params = uri.queryParameters;
  } on FormatException {
    return null;
  }
  final name = (params['name'] ?? '').trim();
  if (name.isEmpty) return null;

  final psk = _tryHexDecode(params['secret'] ?? '');
  if (psk == null || psk.length != _channelSecretBytes) return null;

  return ScannedChannel(name: name, psk: psk);
}

/// Local hex decoder so this util stays pure-Dart; see `contact_qr.dart`.
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
