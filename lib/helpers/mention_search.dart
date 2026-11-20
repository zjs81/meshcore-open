import '../connector/meshcore_protocol.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';

/// A name the composer can offer for a `@[name]` mention.
class MentionCandidate {
  final String name;

  /// Latest time this sender posted in the channel, or null when no incoming
  /// message from them was found there.
  final DateTime? lastMessageAt;

  /// Recency fallback used only to order candidates with no [lastMessageAt].
  final DateTime fallbackAt;

  MentionCandidate({
    required this.name,
    this.lastMessageAt,
    required this.fallbackAt,
  });
}

/// Names matching [query] (case-insensitive substring) for the composer's
/// `@` mention picker: chat-type contacts plus incoming channel senders,
/// ordered by most recent channel message first, then by [MentionCandidate.fallbackAt]
/// and finally by name.
List<MentionCandidate> searchMentionCandidates({
  required Iterable<ChannelMessage> messages,
  required Iterable<Contact> contacts,
  String query = '',
  String? selfName,
}) {
  final latestBySender = <String, DateTime>{};
  for (final message in messages) {
    if (message.isOutgoing) continue;
    final name = message.senderName.trim();
    if (name.isEmpty || name.toLowerCase() == 'unknown') continue;
    final previous = latestBySender[name];
    if (previous == null || message.receivedAt.isAfter(previous)) {
      latestBySender[name] = message.receivedAt;
    }
  }

  final q = query.trim().toLowerCase();
  final self = selfName?.trim().toLowerCase();
  final byName = <String, MentionCandidate>{};

  bool matches(String name) {
    final lower = name.toLowerCase();
    if (lower == self) return false;
    return q.isEmpty || lower.contains(q);
  }

  latestBySender.forEach((name, at) {
    if (matches(name)) {
      byName[name.toLowerCase()] = MentionCandidate(
        name: name,
        lastMessageAt: at,
        fallbackAt: at,
      );
    }
  });
  for (final contact in contacts) {
    if (contact.type != advTypeChat) continue;
    final name = contact.name.trim();
    if (name.isEmpty || !matches(name)) continue;
    byName.putIfAbsent(
      name.toLowerCase(),
      () => MentionCandidate(name: name, fallbackAt: contact.lastMessageAt),
    );
  }

  final results = byName.values.toList();
  results.sort((a, b) {
    if (a.lastMessageAt != null || b.lastMessageAt != null) {
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      final byTime = b.lastMessageAt!.compareTo(a.lastMessageAt!);
      if (byTime != 0) return byTime;
    } else {
      final byFallback = b.fallbackAt.compareTo(a.fallbackAt);
      if (byFallback != 0) return byFallback;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return results;
}
