import '../models/contact.dart';

export 'contact_filter_types.dart';

/// How closely a contact matches a search query. Lower ranks sort first.
enum ContactQueryRank { namePrefix, nameContains, keyPrefix }

/// Rank for [query], or null when the contact does not match.
///
/// Names that start with the query come before other substring matches.
/// A public-key / hop-hash prefix matches only when the name does not.
/// Name-only half of [rankContactQuery], for a label that is not itself a
/// contact (for example the "my contact" alias on the share sheet).
ContactQueryRank? rankNameQuery(String name, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return ContactQueryRank.namePrefix;
  final label = name.toLowerCase();
  if (label.startsWith(normalized)) return ContactQueryRank.namePrefix;
  if (label.contains(normalized)) return ContactQueryRank.nameContains;
  return null;
}

ContactQueryRank? rankContactQuery(Contact contact, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return ContactQueryRank.namePrefix;

  final byName = rankNameQuery(contact.name, normalized);
  if (byName != null) return byName;
  if (_publicKeyPrefixMatches(contact, normalized)) {
    return ContactQueryRank.keyPrefix;
  }
  return null;
}

/// Whether [name], any [aliases], or [publicKeyHex] matches [query] with the
/// same prefix, substring, then hash order as [rankContactQuery].
ContactQueryRank? rankLabeledKeyQuery({
  required String name,
  required String publicKeyHex,
  required String query,
  List<String> aliases = const [],
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return ContactQueryRank.namePrefix;
  ContactQueryRank? best = rankNameQuery(name, normalized);
  for (final alias in aliases) {
    final rank = rankNameQuery(alias, normalized);
    if (rank != null && (best == null || rank.index < best.index)) {
      best = rank;
    }
  }
  if (best != null) return best;
  final hexPrefix = _extractHexPrefix(normalized);
  if (hexPrefix != null && publicKeyHex.toLowerCase().startsWith(hexPrefix)) {
    return ContactQueryRank.keyPrefix;
  }
  return null;
}

bool matchesContactQuery(Contact contact, String query) {
  return rankContactQuery(contact, query) != null;
}

bool matchesDiscoveryContactQuery(Contact contact, String query) {
  return matchesContactQuery(contact, query);
}

/// Sorts prefix matches ahead of other substring matches, then key matches.
///
/// [tieBreak] orders contacts that share a rank. With an empty query every
/// contact shares the top rank, so [tieBreak] is the whole order.
int compareContactQueryRank(
  Contact a,
  Contact b,
  String query, [
  int Function(Contact a, Contact b)? tieBreak,
]) {
  final left = rankContactQuery(a, query);
  final right = rankContactQuery(b, query);
  final byRank = (left?.index ?? 3).compareTo(right?.index ?? 3);
  if (byRank != 0) return byRank;
  return tieBreak?.call(a, b) ??
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

bool _publicKeyPrefixMatches(Contact contact, String normalizedQuery) {
  final hexPrefix = _extractHexPrefix(normalizedQuery);
  if (hexPrefix == null || contact.publicKey.isEmpty) return false;
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
