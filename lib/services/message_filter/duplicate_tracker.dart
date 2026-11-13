import 'dart:collection';

import '../../models/message_filter.dart';
import 'message_filter_text.dart';

class _SeenMessage {
  final String sender;
  final String key;

  /// When the sender sent it (their clock). Windows compare these.
  final DateTime sentAt;

  /// When this device saw it (local clock). Only used to forget entries.
  final DateTime receivedAt;

  /// How many sends of this text by this sender, each within the
  /// same-sender window of the previous one, end with this one (1 = first).
  final int sends;
  const _SeenMessage(
    this.sender,
    this.key,
    this.sentAt,
    this.receivedAt, {
    this.sends = 1,
  });
}

/// In-memory, per-channel tracker of recently seen channel texts used to catch
/// repeated messages (same sender) and floods (same text from several senders).
///
/// Every checked text is recorded, including ones that end up filtered, so a
/// flood keeps being caught.
///
/// Windows are measured between the messages' own send times, as an absolute
/// difference, so history downloaded in a burst after reconnecting (sent
/// hours apart, delivered seconds apart, possibly out of order) is not
/// mistaken for a flood. Entries are forgotten by local receive time instead,
/// so a sender whose clock is far off cannot push everyone else's entries
/// out early or keep its own around forever.
///
/// A copy with the same sender, text and send second as an entry already
/// recorded is the same message seen again (another companion syncing it,
/// a mesh repeat that slipped past storage dedup), never a repeat, and is
/// not recorded twice.
///
/// The same-sender rule flags the [sameSenderSends]th send of a text in a
/// row, each send within [sameSenderWindow] of the previous one (2 = the
/// first re-send). Higher values tolerate people re-sending when they see
/// no repeat or reply.
///
/// The same-sender rule applies to texts of any length, so one word sent
/// over and over ("hello", "test") is caught at the same count as a
/// sentence.
///
/// The cross-sender rule only applies to sentence-length texts (at least
/// [crossSenderMinWords] words): short greetings like "Happy New Year!" or
/// "Good morning everyone" are naturally sent by many people at once, while
/// copy-paste campaigns from rotating identities are whole sentences.
class DuplicateTracker {
  DuplicateTracker({
    this.sameSenderWindow = const Duration(minutes: 10),
    this.sameSenderSends = 2,
    this.crossSenderWindow = const Duration(minutes: 30),
    this.crossSenderMinSenders = 3,
    this.crossSenderMinLength = 10,
    this.crossSenderMinWords = 6,
    this.maxEntriesPerChannel = 1000,
  });

  final Duration sameSenderWindow;

  /// Which send in a row of the same text is flagged; can be overridden per
  /// call so a settings change applies immediately.
  final int sameSenderSends;
  final Duration crossSenderWindow;
  final int crossSenderMinSenders;
  final int crossSenderMinLength;

  /// Minimum word count for the cross-sender rule (see class docs).
  final int crossSenderMinWords;
  final int maxEntriesPerChannel;

  final Map<String, ListQueue<_SeenMessage>> _seen = {};
  final Map<String, Set<String>> _allowed = {};

  Duration get _retention => sameSenderWindow > crossSenderWindow
      ? sameSenderWindow
      : crossSenderWindow;

  static String _senderKey(String sender) =>
      MessageFilterText.normalize(sender);

  void _prune(ListQueue<_SeenMessage> entries, DateTime receivedAt) {
    // Entries are appended in receive order, so the oldest are at the front.
    final cutoff = receivedAt.subtract(_retention);
    while (entries.isNotEmpty && entries.first.receivedAt.isBefore(cutoff)) {
      entries.removeFirst();
    }
    while (entries.length > maxEntriesPerChannel) {
      entries.removeFirst();
    }
  }

  /// Records the text and returns [FilterReason.duplicate],
  /// [FilterReason.crossSenderDuplicate] or null.
  ///
  /// [at] is when the message was sent (the sender's timestamp); windows are
  /// compared on it. [receivedAt] (default [at]) is the local time it arrived,
  /// used only to forget old entries.
  FilterReason? check({
    required String channelId,
    required String sender,
    required String text,
    required DateTime at,
    DateTime? receivedAt,
    int? sameSenderSends,
  }) {
    final flagAt = (sameSenderSends ?? this.sameSenderSends) < 2
        ? 2
        : (sameSenderSends ?? this.sameSenderSends);
    final arrived = receivedAt ?? at;
    final key = MessageFilterText.normalizeForDuplicates(text);
    if (key.isEmpty) return null;
    final senderKey = _senderKey(sender);
    final entries = _seen.putIfAbsent(channelId, ListQueue<_SeenMessage>.new);
    _prune(entries, arrived);

    final atSecond = _second(at);
    for (final entry in entries) {
      if (entry.key == key &&
          entry.sender == senderKey &&
          _second(entry.sentAt) == atSecond) {
        // The same message seen again, not a new send.
        return null;
      }
    }

    // The longest run of sends this one continues: earlier sends of this
    // text by this sender within the window, each already carrying its run.
    var sends = 1;
    for (final entry in entries) {
      if (entry.key != key || entry.sender != senderKey) continue;
      if (entry.sentAt.difference(at).abs() <= sameSenderWindow &&
          entry.sends + 1 > sends) {
        sends = entry.sends + 1;
      }
    }

    FilterReason? result;
    if (!isAllowed(channelId, text)) {
      final senders = <String>{senderKey};
      for (final entry in entries) {
        if (entry.key != key || entry.sender == senderKey) continue;
        // Absolute gap between send times: delivery order does not matter.
        if (entry.sentAt.difference(at).abs() <= crossSenderWindow) {
          senders.add(entry.sender);
        }
      }
      if (sends >= flagAt) {
        result = FilterReason.duplicate;
      } else if (key.length >= crossSenderMinLength &&
          _wordCount(key) >= crossSenderMinWords &&
          senders.length >= crossSenderMinSenders) {
        result = FilterReason.crossSenderDuplicate;
      }
    }

    entries.addLast(_SeenMessage(senderKey, key, at, arrived, sends: sends));
    if (entries.length > maxEntriesPerChannel) entries.removeFirst();
    return result;
  }

  static int _second(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

  /// [key] is already whitespace-collapsed by `normalizeForDuplicates`.
  static int _wordCount(String key) => key.isEmpty ? 0 : key.split(' ').length;

  /// Exempts this text in this channel from duplicate hits for the session
  /// (used after "Not spam").
  void allow(String channelId, String text) {
    final key = MessageFilterText.normalizeForDuplicates(text);
    if (key.isEmpty) return;
    _allowed.putIfAbsent(channelId, () => <String>{}).add(key);
  }

  bool isAllowed(String channelId, String text) {
    final allowed = _allowed[channelId];
    if (allowed == null || allowed.isEmpty) return false;
    return allowed.contains(MessageFilterText.normalizeForDuplicates(text));
  }

  /// Forgets everything (seen texts and the allow-set).
  void clear() {
    _seen.clear();
    _allowed.clear();
  }
}
