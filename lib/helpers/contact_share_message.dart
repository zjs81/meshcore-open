import 'dart:typed_data';

import '../utils/contact_qr.dart';

/// A contact shared as a chat message: `<PUBKEYHEX:TYPE:NAME>`.
class ContactShare {
  final Uint8List publicKey;
  final String publicKeyHex;
  final int type;
  final String name;

  const ContactShare({
    required this.publicKey,
    required this.publicKeyHex,
    required this.type,
    required this.name,
  });

  /// First 6 + "..." + last 6 hex chars, as the official app shows it.
  String get shortKey => shortContactKey(publicKeyHex);

  ScannedContact toScannedContact() =>
      ScannedContact(publicKey: publicKey, name: name, type: type);
}

String shortContactKey(String hex) => hex.length <= 12
    ? hex
    : '${hex.substring(0, 6)}...${hex.substring(hex.length - 6)}';

const int _keyBytes = 32;
const String _tokenBody = r'<([0-9a-fA-F]{64}):([1-4]):([^<>\r\n]*)>';
final RegExp _tokenPattern = RegExp('^$_tokenBody\$');
final RegExp _embeddedTokenPattern = RegExp(_tokenBody);

/// Builds the share token for a contact. [publicKey] must be 32 bytes.
String encodeContactShare({
  required Uint8List publicKey,
  required int type,
  required String name,
}) {
  assert(publicKey.length == _keyBytes);
  final hex = StringBuffer();
  for (final b in publicKey) {
    hex.write(b.toRadixString(16).padLeft(2, '0'));
  }
  final cleanName = name.replaceAll(RegExp(r'[<>\r\n]'), '').trim();
  return '<$hex:$type:$cleanName>';
}

/// Returns null unless the whole trimmed [text] is a valid share token.
ContactShare? parseContactShare(String text) =>
    _shareFromMatch(_tokenPattern.firstMatch(text.trim()));

/// Finds a share token anywhere in [text], e.g. a copied chat message that
/// also carries a sender prefix (`Name: <...>`) or surrounding words.
ContactShare? findContactShare(String text) =>
    _shareFromMatch(_embeddedTokenPattern.firstMatch(text));

ContactShare? _shareFromMatch(RegExpMatch? match) {
  if (match == null) return null;
  final hex = match.group(1)!.toLowerCase();
  final bytes = Uint8List(_keyBytes);
  for (var i = 0; i < _keyBytes; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return ContactShare(
    publicKey: bytes,
    publicKeyHex: hex,
    type: int.parse(match.group(2)!),
    name: match.group(3)!.trim(),
  );
}
