import 'dart:typed_data';
import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';
import 'package:base32/encodings.dart';
import '../widgets/emoji_picker.dart';

enum HashType { ours, mc1 }

class ReactionInfo {
  final String targetHash;
  final String emoji;
  HashType hashType;
  String? senderName; // Who sent the reaction

  ReactionInfo({
    required this.targetHash,
    required this.emoji,
    required this.hashType,
    this.senderName,
  });

  String identifier() {
    return '$targetHash:$emoji:$hashType:${senderName ?? ""}';
  }
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
    required Map<String, List<String?>> Function(T) getReactions,
    required bool Function(T) shouldSkip,
    updateMessage,
  }) {
    final targetHash = reactionInfo.targetHash;
    final hashFunc = switch (reactionInfo.hashType) {
      HashType.ours => computeReactionHash,
      HashType.mc1 => ((ts, senderName, text) => _concatenateHashAndSender(
        computeReactionHashMC1(ts, senderName, text),
        senderName,
      )),
    };
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (shouldSkip(msg)) continue;

      final msgHash = hashFunc(
        getTimestampSecs(msg),
        getSenderName(msg),
        getMessageText(msg),
      );
      if (msgHash == targetHash) {
        final currentReactions = Map<String, List<String?>>.from(
          getReactions(msg),
        );
        (currentReactions[reactionInfo.emoji] ??= []).add(
          reactionInfo.senderName,
        );
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

  // Compute the type of reaction hash used by MeshCoreOne.
  static String computeReactionHashMC1(
    int timestampSeconds,
    String? senderName,
    String messageText,
  ) {
    // raw hash is first 5 bytes of SHA-256(UTF-8 text + uint32-LE sender timestamp)
    Uint8List messageBytes = utf8.encode(messageText);
    ByteData timestampBytes = ByteData(4)
      ..setUint32(0, timestampSeconds, Endian.little);
    final hash = sha256
        .convert(messageBytes + timestampBytes.buffer.asUint8List())
        .bytes
        .sublist(0, 5);

    // encode as 8 chars of Crockford base32
    return base32
        .encode(Uint8List.fromList(hash), encoding: Encoding.crockford)
        .toLowerCase();
    // Note: Crockford32 defines permissive decoding and allows some
    // substitutions (e.g. I, i, l -> 1) but we never decode the hashes, we
    // just compare them. If someone sends a miscoded hash that should be
    // equivalent, we won't match it and it won't work. But it's not worth
    // accommodating, because no one is going to be hand copying hashes.
  }

  // MeshCoreOne-style reaction hashes don't depend on the sender name,
  // and we're expected to check the hash and sender name separately.
  // Our own reaction hashes include it. Rather than store the sender
  // Name in ReactionInfo and complicate the logic in applyReaction(),
  // we just tack the senderName onto the end of the "hash".
  static String _concatenateHashAndSender(String hash, String? senderName) {
    return "$hash:${senderName ?? ''}";
  }

  static ReactionInfo? parseReaction(String text) {
    return parseReactionOurs(text) ??
        parseReactionMC1(text) ??
        parseReactionMC1Legacy(text);
  }

  static bool _looksLikeEmoji(String emoji) {
    // Make sure it's a single grapheme.
    if (Characters(emoji).length > 1) return false;

    // Below are some emoji-validating tests, copied from MeshTrax.
    // https://github.com/venamartin/meshtrax/
    // It's nice to avoid false positives just to save us some processing,
    // but it's not crucial, as we will either apply a reaction or show it
    // as a message. Text that is not actually a hash is unlikely to match
    // a message.
    if (emoji.isEmpty) return false;
    // Emoji, not prose: nearly all emoji start at U+2000 or above; the
    // exceptions (keycaps, ©/®) carry a variation selector U+FE0F or a
    // combining keycap U+20E3. Ordinary ASCII text fails both tests.
    if (!(emoji.runes.first >= 0x2000 ||
        emoji.runes.any((r) => r == 0xFE0F || r == 0x20E3))) {
      return false;
    }
    return true;
  }

  static ReactionInfo? parseReactionMC1(String text) {
    // See https://github.com/Avi0n/MeshCoreOne/blob/main/docs/Reactions.md
    // This regex matches both the channel format, which includes the sender name,
    // and the chat (DM) format, which omits it.
    final regex = RegExp(r'^(?:@\[(.*)])?(.+?)\n([a-tv-zA-TV-Z0-9]{8})$');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final senderName = match.group(1);
    final emoji = match.group(2)!;
    final hash = match.group(3)?.toLowerCase();
    if (!_looksLikeEmoji(emoji)) return null;

    return ReactionInfo(
      targetHash: _concatenateHashAndSender(hash!, senderName),
      emoji: emoji,
      hashType: HashType.mc1,
    );
  }

  static ReactionInfo? parseReactionMC1Legacy(String text) {
    // See https://github.com/Avi0n/MeshCoreOne/blob/main/docs/Reactions.md
    // This regex matches both the channel format, which includes the sender name,
    // and the chat (DM) format, which omits it.
    final regex = RegExp(r'^(.+?)(?:@\[(.*)])?\n([a-tv-zA-TV-Z0-9]{8})$');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final hash = match.group(3)?.toLowerCase();
    final senderName = match.group(2);
    final emoji = match.group(1)!;
    if (!_looksLikeEmoji(emoji)) return null;

    return ReactionInfo(
      targetHash: _concatenateHashAndSender(hash!, senderName),
      emoji: emoji,
      hashType: HashType.mc1,
    );
  }

  /// Parse reaction format: r:HASH:INDEX (where INDEX is 2-char hex emoji index)
  /// Returns null if text is not a valid reaction format
  static ReactionInfo? parseReactionOurs(String text) {
    final regex = RegExp(r'^r:([0-9a-f]{4}):([0-9a-f]{2})$');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final emoji = indexToEmoji(match.group(2)!);
    if (emoji == null) return null;
    return ReactionInfo(
      targetHash: match.group(1)!,
      emoji: emoji,
      hashType: HashType.ours,
    );
  }

  /// Encode a reaction message that parseReaction() can parse.
  static String encodeReaction(String hash, String emojiIndex) {
    return 'r:$hash:$emojiIndex';
  }
}
