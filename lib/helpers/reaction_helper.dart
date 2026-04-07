import '../widgets/emoji_picker.dart';

class ReactionInfo {
  final String targetHash;
  final String emoji;

  ReactionInfo({required this.targetHash, required this.emoji});
}

class ReactionHelper {
  /// Apply a reaction to a list of messages by matching the reaction hash.
  ///
  /// [messages] - the message list to search
  /// [reactionInfo] - the parsed reaction
  /// [getTimestampSecs] - extract timestamp seconds from a message
  /// [getSenderName] - extract sender name for hash (null for 1:1 implicit)
  /// [getMessageText] - extract message text
  /// [getReactions] - extract current reactions map
  /// [shouldSkip] - filter function to skip messages (e.g., skip outgoing for incoming reactions)
  /// [updateMessage] - callback to update the message at index with new reactions
  ///
  /// Returns whether a match was found.
  static bool applyReaction<T>({
    required List<T> messages,
    required ReactionInfo reactionInfo,
    required int Function(T) getTimestampSecs,
    required String? Function(T) getSenderName,
    required String Function(T) getMessageText,
    required Map<String, int> Function(T) getReactions,
    required bool Function(T) shouldSkip,
    required void Function(int index, Map<String, int> newReactions)
    updateMessage,
  }) {
    final targetHash = reactionInfo.targetHash;
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (shouldSkip(msg)) continue;

      final msgHash = computeReactionHash(
        getTimestampSecs(msg),
        getSenderName(msg),
        getMessageText(msg),
      );
      if (msgHash == targetHash) {
        final currentReactions = Map<String, int>.from(getReactions(msg));
        currentReactions[reactionInfo.emoji] =
            (currentReactions[reactionInfo.emoji] ?? 0) + 1;
        updateMessage(i, currentReactions);
        return true;
      }
    }
    return false;
  }

  static List<String>? _cachedEmojis;

  /// Combined list of all reaction emojis in fixed order.
  /// Order must stay stable for index compatibility.
  static List<String> get reactionEmojis {
    return _cachedEmojis ??= [
      ...EmojiPicker.quickEmojis,
      ...EmojiPicker.smileys,
      ...EmojiPicker.gestures,
      ...EmojiPicker.hearts,
      ...EmojiPicker.objects,
    ];
  }

  /// Convert emoji to 2-char hex index. Returns null if emoji not in list.
  static String? emojiToIndex(String emoji) {
    final idx = reactionEmojis.indexOf(emoji);
    if (idx < 0) return null;
    return idx.toRadixString(16).padLeft(2, '0');
  }

  /// Convert 2-char hex index to emoji. Returns null if invalid index.
  static String? indexToEmoji(String hexIndex) {
    final idx = int.tryParse(hexIndex, radix: 16);
    if (idx == null || idx < 0 || idx >= reactionEmojis.length) return null;
    return reactionEmojis[idx];
  }

  /// Compute a 4-char hex hash for a message reaction.
  /// Hash input: timestampSeconds + [senderName] + first 5 chars of text
  /// For 1:1 chats, senderName can be null (sender is implicit).
  static String computeReactionHash(
    int timestampSeconds,
    String? senderName,
    String text,
  ) {
    final first5 = text.length >= 5 ? text.substring(0, 5) : text;
    final input = senderName != null
        ? '$timestampSeconds$senderName$first5'
        : '$timestampSeconds$first5';
    // Use hashCode and take lower 16 bits, format as 4 hex chars
    final hash = input.hashCode & 0xFFFF;
    return hash.toRadixString(16).padLeft(4, '0');
  }

  /// Parse reaction format: r:HASH:INDEX (where INDEX is 2-char hex emoji index)
  /// Returns null if text is not a valid reaction format
  static ReactionInfo? parseReaction(String text) {
    final regex = RegExp(r'^r:([0-9a-f]{4}):([0-9a-f]{2})$');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final emoji = indexToEmoji(match.group(2)!);
    if (emoji == null) return null;

    return ReactionInfo(targetHash: match.group(1)!, emoji: emoji);
  }

  /// Encode a reaction message that parseReaction() can parse.
  static String encodeReaction(String hash, String emojiIndex) {
    return 'r:$hash:$emojiIndex';
  }
}
