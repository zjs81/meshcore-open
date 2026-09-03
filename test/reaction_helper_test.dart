import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/reaction_helper.dart';
import 'package:meshcore_open/widgets/emoji_picker.dart';

void main() {
  group('ReactionHelper', () {
    group('reactionEmojis', () {
      test('should contain all emoji categories', () {
        final emojis = ReactionHelper.reactionEmojis;

        // Should contain quickEmojis
        for (final emoji in EmojiPicker.quickEmojis) {
          expect(
            emojis.contains(emoji),
            isTrue,
            reason: 'Missing quick emoji: $emoji',
          );
        }

        // Should contain smileys
        for (final emoji in EmojiPicker.smileys) {
          expect(
            emojis.contains(emoji),
            isTrue,
            reason: 'Missing smiley: $emoji',
          );
        }

        // Should contain gestures
        for (final emoji in EmojiPicker.gestures) {
          expect(
            emojis.contains(emoji),
            isTrue,
            reason: 'Missing gesture: $emoji',
          );
        }

        // Should contain hearts
        for (final emoji in EmojiPicker.hearts) {
          expect(
            emojis.contains(emoji),
            isTrue,
            reason: 'Missing heart: $emoji',
          );
        }

        // Should contain objects
        for (final emoji in EmojiPicker.objects) {
          expect(
            emojis.contains(emoji),
            isTrue,
            reason: 'Missing object: $emoji',
          );
        }
      });

      test('should fit in 1 byte (max 256 emojis)', () {
        expect(ReactionHelper.reactionEmojis.length, lessThanOrEqualTo(256));
      });
    });

    group('emojiToIndex', () {
      test('should return 2-char hex for valid emoji', () {
        // First emoji (thumbs up) should be index 0
        expect(ReactionHelper.emojiToIndex('👍'), equals('00'));

        // Second emoji (heart) should be index 1
        expect(ReactionHelper.emojiToIndex('❤️'), equals('01'));
      });

      test('should return null for unknown emoji', () {
        expect(ReactionHelper.emojiToIndex('🦄'), isNull); // Not in list
        expect(ReactionHelper.emojiToIndex('invalid'), isNull);
        expect(ReactionHelper.emojiToIndex(''), isNull);
      });

      test('should return lowercase hex', () {
        final index = ReactionHelper.emojiToIndex('👍');
        expect(index, matches(RegExp(r'^[0-9a-f]{2}$')));
      });
    });

    group('indexToEmoji', () {
      test('should return emoji for valid index', () {
        expect(ReactionHelper.indexToEmoji('00'), equals('👍'));
        expect(ReactionHelper.indexToEmoji('01'), equals('❤️'));
      });

      test('should return null for invalid index', () {
        expect(
          ReactionHelper.indexToEmoji('ff'),
          isNull,
        ); // Index 255, out of range
        expect(ReactionHelper.indexToEmoji('zz'), isNull); // Invalid hex
        expect(ReactionHelper.indexToEmoji(''), isNull); // Empty string
        // Note: indexToEmoji parses any valid hex; length validation is done by parseReaction's regex
      });

      test('should handle case insensitivity', () {
        // Both uppercase and lowercase should work
        expect(ReactionHelper.indexToEmoji('0a'), isNotNull);
        expect(ReactionHelper.indexToEmoji('0A'), isNotNull);
      });
    });

    group('emoji round-trip', () {
      test('all emojis should round-trip correctly', () {
        for (int i = 0; i < ReactionHelper.reactionEmojis.length; i++) {
          final emoji = ReactionHelper.reactionEmojis[i];
          final index = ReactionHelper.emojiToIndex(emoji);
          expect(index, isNotNull, reason: 'emojiToIndex failed for $emoji');

          final decoded = ReactionHelper.indexToEmoji(index!);
          expect(
            decoded,
            equals(emoji),
            reason: 'Round-trip failed for $emoji (index $index)',
          );
        }
      });
    });

    group('computeReactionHash', () {
      test('should return 4-char hex hash', () {
        final hash = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello world',
        );
        expect(hash, matches(RegExp(r'^[0-9a-f]{4}$')));
      });

      test('should be deterministic', () {
        final hash1 = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello',
        );
        final hash2 = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello',
        );
        expect(hash1, equals(hash2));
      });

      test('should differ for different inputs', () {
        final hash1 = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello',
        );
        final hash2 = ReactionHelper.computeReactionHash(
          1234567890,
          'Bob',
          'Hello',
        );
        final hash3 = ReactionHelper.computeReactionHash(
          1234567891,
          'Alice',
          'Hello',
        );
        final hash4 = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'World',
        );

        expect(hash1, isNot(equals(hash2))); // Different sender
        expect(hash1, isNot(equals(hash3))); // Different timestamp
        expect(hash1, isNot(equals(hash4))); // Different text
      });

      test('should use first 5 chars of text', () {
        final hash1 = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello world',
        );
        final hash2 = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello there',
        );
        expect(hash1, equals(hash2)); // Same first 5 chars
      });

      test('should handle short text', () {
        final hash = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hi',
        );
        expect(hash, matches(RegExp(r'^[0-9a-f]{4}$')));
      });

      test('should handle empty text', () {
        final hash = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          '',
        );
        expect(hash, matches(RegExp(r'^[0-9a-f]{4}$')));
      });
    });

    group('computeReactionHash with null sender (1:1 chats)', () {
      test('should return 4-char hex hash', () {
        final hash = ReactionHelper.computeReactionHash(
          1234567890,
          null,
          'Hello world',
        );
        expect(hash, matches(RegExp(r'^[0-9a-f]{4}$')));
      });

      test('should be deterministic', () {
        final hash1 = ReactionHelper.computeReactionHash(
          1234567890,
          null,
          'Hello',
        );
        final hash2 = ReactionHelper.computeReactionHash(
          1234567890,
          null,
          'Hello',
        );
        expect(hash1, equals(hash2));
      });

      test('should differ for different inputs', () {
        final hash1 = ReactionHelper.computeReactionHash(
          1234567890,
          null,
          'Hello',
        );
        final hash2 = ReactionHelper.computeReactionHash(
          1234567891,
          null,
          'Hello',
        );
        final hash3 = ReactionHelper.computeReactionHash(
          1234567890,
          null,
          'World',
        );

        expect(hash1, isNot(equals(hash2))); // Different timestamp
        expect(hash1, isNot(equals(hash3))); // Different text
      });

      test('should differ from hash with sender name', () {
        // Null sender hash doesn't include sender, so should differ
        final nullSenderHash = ReactionHelper.computeReactionHash(
          1234567890,
          null,
          'Hello',
        );
        final withSenderHash = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello',
        );
        expect(nullSenderHash, isNot(equals(withSenderHash)));
      });

      test('1:1 chat flow: sender and receiver compute same hash', () {
        // Alice sends "Hello" at timestamp 1234567890
        // Bob receives it and wants to react
        // Bob computes hash the same way Alice's app will match it
        const timestamp = 1234567890;
        const messageText = 'Hello there!';

        // Bob (sender of reaction) computes hash with null sender
        final bobHash = ReactionHelper.computeReactionHash(
          timestamp,
          null,
          messageText,
        );

        // Alice (receiver of reaction) computes hash for her outgoing message
        final aliceHash = ReactionHelper.computeReactionHash(
          timestamp,
          null,
          messageText,
        );

        expect(bobHash, equals(aliceHash));
      });
    });

    group('parseReaction', () {
      test('should parse valid reaction format', () {
        final info = ReactionHelper.parseReaction('r:a1b2:00');
        expect(info, isNotNull);
        expect(info!.targetHash, equals('a1b2'));
        expect(info.emoji, equals('👍'));
      });

      test('should return null for invalid format', () {
        expect(ReactionHelper.parseReaction('invalid'), isNull);
        expect(
          ReactionHelper.parseReaction('r:abc:00'),
          isNull,
        ); // Hash too short
        expect(
          ReactionHelper.parseReaction('r:abcde:00'),
          isNull,
        ); // Hash too long
        expect(
          ReactionHelper.parseReaction('r:a1b2:0'),
          isNull,
        ); // Index too short
        expect(
          ReactionHelper.parseReaction('r:a1b2:000'),
          isNull,
        ); // Index too long
        expect(
          ReactionHelper.parseReaction('R:a1b2:00'),
          isNull,
        ); // Uppercase R
        expect(
          ReactionHelper.parseReaction('r:A1B2:00'),
          isNull,
        ); // Uppercase hash
        expect(ReactionHelper.parseReaction(''), isNull);
      });

      test('should return null for invalid emoji index', () {
        // Index ff (255) is likely out of range
        expect(ReactionHelper.parseReaction('r:a1b2:ff'), isNull);
      });

      test('should decode emoji correctly', () {
        // Encode thumbs up and verify decode
        final index = ReactionHelper.emojiToIndex('👍');
        final info = ReactionHelper.parseReaction('r:dead:$index');
        expect(info, isNotNull);
        expect(info!.emoji, equals('👍'));
      });
    });

    group('MeshCoreOne Reactions', () {
      test('regex for matching emoji char', () {
        // This is more a test of expectations than of app code, but it was
        // a good place to get this sorted out cleanly, and I leave it for
        // anyone interested in understanding the regex in the parsing.
        final regex = RegExp(r'^(.{1,4})$');
        expect(regex.firstMatch('🥳'), isNotNull);
        expect(regex.firstMatch('😀'), isNotNull);
        expect(regex.firstMatch('\u{1F642}'), isNotNull);
        expect(regex.firstMatch('\u{1f44c}\u{1f3ff}'), isNotNull);
      });

      test('parse MeshCoreOne reaction', () {
        final emoji = '🥳';
        final senderName = 'entropy 📓';
        final hash = 'b3je6qf7';
        final info = ReactionHelper.parseReactionMC1(
          '$emoji@[$senderName]\n$hash',
        );
        expect(info, isNotNull);
        expect(info!.targetHash, equals('$hash:$senderName'));
        expect(info.emoji, equals(emoji));
      });

      test('parse MeshCoreOne reaction - main entry', () {
        final emoji = '🥳';
        final senderName = 'entropy 📓';
        final hash = 'b3je6qf7';
        final info = ReactionHelper.parseReaction(
          '$emoji@[$senderName]\n$hash',
        );
        expect(info, isNotNull);
        expect(info!.targetHash, equals('$hash:$senderName'));
        expect(info.emoji, equals(emoji));
      });

      test('parse MeshCoreOne reaction for DM chats', () {
        final emoji = '🥳';
        final hash = 'b3je6qf7';
        final info = ReactionHelper.parseReaction('$emoji\n$hash');
        expect(info, isNotNull);
        expect(info!.targetHash, equals('$hash:'));
        expect(info.emoji, equals(emoji));
      });

      test('compute MeshCoreOne reaction hash', () {
        const timestamp = 1234567890;
        const senderName = 'Alice';
        const messageText = 'Hello world!';
        final hash = ReactionHelper.computeReactionHashMC1(
          timestamp,
          senderName,
          messageText,
        );
        expect(hash, equals('tyvbkb33'));
      });
    });

    group('full reaction flow', () {
      test('should encode and decode reaction correctly', () {
        // Simulate sending a reaction
        const timestamp = 1234567890;
        const senderName = 'Alice';
        const messageText = 'Hello world!';
        const emoji = '🎉';

        // Compute hash (sender side)
        final hash = ReactionHelper.computeReactionHash(
          timestamp,
          senderName,
          messageText,
        );

        // Encode emoji (sender side)
        final emojiIndex = ReactionHelper.emojiToIndex(emoji);
        expect(emojiIndex, isNotNull);

        // Build reaction text (sender side)
        final reactionText = 'r:$hash:$emojiIndex';

        // Parse reaction (receiver side)
        final info = ReactionHelper.parseReaction(reactionText);
        expect(info, isNotNull);
        expect(info!.targetHash, equals(hash));
        expect(info.emoji, equals(emoji));

        // Verify receiver can match the hash
        final receiverHash = ReactionHelper.computeReactionHash(
          timestamp,
          senderName,
          messageText,
        );
        expect(receiverHash, equals(info.targetHash));
      });

      test('reaction text should be 9 bytes', () {
        final hash = ReactionHelper.computeReactionHash(
          1234567890,
          'Alice',
          'Hello',
        );
        final index = ReactionHelper.emojiToIndex('👍')!;
        final reactionText = 'r:$hash:$index';

        // r: (2) + hash (4) + : (1) + index (2) = 9 bytes
        expect(reactionText.length, equals(9));
      });

      test('1:1 chat: Bob reacts to Alice message', () {
        // Alice sends "Hello" to Bob at timestamp 1234567890
        const timestamp = 1234567890;
        const aliceName = 'Alice';
        const messageText = 'Hello';
        const emoji = '👍';

        // On Bob's device: message.isOutgoing = false, so senderName = contact.name = Alice
        final bobSideHash = ReactionHelper.computeReactionHash(
          timestamp,
          aliceName,
          messageText,
        );
        final emojiIndex = ReactionHelper.emojiToIndex(emoji)!;
        final reactionText = 'r:$bobSideHash:$emojiIndex';

        // Alice receives the reaction
        final info = ReactionHelper.parseReaction(reactionText);
        expect(info, isNotNull);

        // On Alice's device: message.isOutgoing = true, so senderName = selfName = Alice
        final aliceSideHash = ReactionHelper.computeReactionHash(
          timestamp,
          aliceName,
          messageText,
        );

        // Hashes should match!
        expect(info!.targetHash, equals(aliceSideHash));
        expect(info.emoji, equals(emoji));
      });

      test('1:1 chat: Alice reacts to Bob message', () {
        // Bob sends "Hi there" to Alice at timestamp 9876543210
        const timestamp = 9876543210;
        const bobName = 'Bob';
        const messageText = 'Hi there';
        const emoji = '❤️';

        // On Alice's device: message.isOutgoing = false, so senderName = contact.name = Bob
        final aliceSideHash = ReactionHelper.computeReactionHash(
          timestamp,
          bobName,
          messageText,
        );
        final emojiIndex = ReactionHelper.emojiToIndex(emoji)!;
        final reactionText = 'r:$aliceSideHash:$emojiIndex';

        // Bob receives the reaction
        final info = ReactionHelper.parseReaction(reactionText);
        expect(info, isNotNull);

        // On Bob's device: message.isOutgoing = true, so senderName = selfName = Bob
        final bobSideHash = ReactionHelper.computeReactionHash(
          timestamp,
          bobName,
          messageText,
        );

        // Hashes should match!
        expect(info!.targetHash, equals(bobSideHash));
        expect(info.emoji, equals(emoji));
      });

      test('room server: user reacts to message from another user', () {
        // In a room server, Charlie sends "Hello room" at timestamp 1111111111
        // Alice wants to react to it
        const timestamp = 1111111111;
        const charlieName = 'Charlie';
        const messageText = 'Hello room';
        const emoji = '🎉';

        // Alice computes hash including sender name (room servers are multi-user)
        final aliceHash = ReactionHelper.computeReactionHash(
          timestamp,
          charlieName,
          messageText,
        );
        final emojiIndex = ReactionHelper.emojiToIndex(emoji)!;
        final reactionText = 'r:$aliceHash:$emojiIndex';

        // Verify format
        expect(reactionText.length, equals(9));
        expect(reactionText, matches(RegExp(r'^r:[0-9a-f]{4}:[0-9a-f]{2}$')));

        // Bob (another user in the room) receives the reaction
        final info = ReactionHelper.parseReaction(reactionText);
        expect(info, isNotNull);

        // Bob computes hash for Charlie's message the same way
        final bobHash = ReactionHelper.computeReactionHash(
          timestamp,
          charlieName,
          messageText,
        );

        // Hashes should match!
        expect(info!.targetHash, equals(bobHash));
        expect(info.emoji, equals(emoji));
      });

      test(
        'room server: hash differs from 1:1 hash for same message content',
        () {
          // Same timestamp and text, but room server includes sender name
          const timestamp = 1234567890;
          const senderName = 'Dave';
          const messageText = 'Hello';

          // Room server hash (with sender name)
          final roomHash = ReactionHelper.computeReactionHash(
            timestamp,
            senderName,
            messageText,
          );

          // 1:1 hash (without sender name)
          final directHash = ReactionHelper.computeReactionHash(
            timestamp,
            null,
            messageText,
          );

          // They should be different!
          expect(roomHash, isNot(equals(directHash)));
        },
      );

      test('room server: different senders produce different hashes', () {
        // Two users send the exact same message at the same time in a room
        const timestamp = 1234567890;
        const messageText = 'Hello';

        final aliceHash = ReactionHelper.computeReactionHash(
          timestamp,
          'Alice',
          messageText,
        );
        final bobHash = ReactionHelper.computeReactionHash(
          timestamp,
          'Bob',
          messageText,
        );

        // Different senders = different hashes (even with same content)
        expect(aliceHash, isNot(equals(bobHash)));
      });

      test('room server: self message reaction works', () {
        // Alice sends "My message" at timestamp 2222222222
        // Bob wants to react to it
        const timestamp = 2222222222;
        const aliceName = 'Alice';
        const messageText = 'My message';
        const emoji = '👍';

        // Bob computes hash for Alice's message
        final bobHash = ReactionHelper.computeReactionHash(
          timestamp,
          aliceName,
          messageText,
        );
        final emojiIndex = ReactionHelper.emojiToIndex(emoji)!;
        final reactionText = 'r:$bobHash:$emojiIndex';

        // Alice receives the reaction and matches against her outgoing message
        final info = ReactionHelper.parseReaction(reactionText);
        expect(info, isNotNull);

        // Alice computes hash using her selfName
        final aliceHash = ReactionHelper.computeReactionHash(
          timestamp,
          aliceName,
          messageText,
        );

        // Hashes should match!
        expect(info!.targetHash, equals(aliceHash));
      });

      test('channel: same logic as room server', () {
        // Channel messages also use sender name in hash
        const timestamp = 3333333333;
        const senderName = 'Eve';
        const messageText = 'Channel msg';
        const emoji = '🔥';

        // Compute hash with sender name
        final hash = ReactionHelper.computeReactionHash(
          timestamp,
          senderName,
          messageText,
        );
        final emojiIndex = ReactionHelper.emojiToIndex(emoji)!;
        final reactionText = 'r:$hash:$emojiIndex';

        // Parse and verify
        final info = ReactionHelper.parseReaction(reactionText);
        expect(info, isNotNull);
        expect(info!.emoji, equals(emoji));

        // Another user computes the same hash
        final otherUserHash = ReactionHelper.computeReactionHash(
          timestamp,
          senderName,
          messageText,
        );
        expect(info.targetHash, equals(otherUserHash));
      });
    });
  });
}
