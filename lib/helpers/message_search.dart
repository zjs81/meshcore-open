/// One searchable message, independent of DM or channel model.
class ChatSearchEntry {
  final String id;
  final String sender;
  final String text;
  final String? translatedText;
  final DateTime time;

  /// Whether [sender] is part of the searchable text (channels only).
  final bool matchSender;

  const ChatSearchEntry({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.translatedText,
    this.matchSender = false,
  });
}

String normalizeSearchQuery(String query) => query.trim().toLowerCase();

bool searchEntryMatches(ChatSearchEntry entry, String query) {
  final needle = normalizeSearchQuery(query);
  if (needle.isEmpty) return false;
  if (entry.text.toLowerCase().contains(needle)) return true;
  final translated = entry.translatedText;
  if (translated != null && translated.toLowerCase().contains(needle)) {
    return true;
  }
  return entry.matchSender && entry.sender.toLowerCase().contains(needle);
}

/// Matches for [query], newest first. [entries] must be oldest first.
List<ChatSearchEntry> searchEntries(
  List<ChatSearchEntry> entries,
  String query,
) {
  if (normalizeSearchQuery(query).isEmpty) return const [];
  return [
    for (final entry in entries.reversed)
      if (searchEntryMatches(entry, query)) entry,
  ];
}
