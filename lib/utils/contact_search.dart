import '../models/contact.dart';

bool matchesContactQuery(Contact contact, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  if (contact.name.toLowerCase().contains(normalizedQuery)) {
    return true;
  }

  final hexPrefix = _extractHexPrefix(normalizedQuery);
  if (hexPrefix == null) return false;

  return contact.publicKeyHex.toLowerCase().startsWith(hexPrefix);
}

bool matchesDiscoveryContactQuery(Contact contact, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  if (contact.name.toLowerCase().contains(normalizedQuery)) {
    return true;
  }

  final hexPrefix = _extractHexPrefix(normalizedQuery);
  if (hexPrefix == null) return false;

  return contact.publicKeyHex.toLowerCase().startsWith(hexPrefix);
}

String? _extractHexPrefix(String query) {
  var cleaned = query;
  if (cleaned.startsWith('<')) {
    cleaned = cleaned.substring(1).replaceAll(">", "");
  }
  if (cleaned.startsWith('0x')) {
    cleaned = cleaned.substring(2);
  }
  cleaned = cleaned.replaceAll(' ', '');
  if (cleaned.length < 2) return null;
  if (!RegExp(r'^[0-9a-f]+$').hasMatch(cleaned)) return null;
  return cleaned;
}
