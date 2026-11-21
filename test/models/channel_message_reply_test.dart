import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/bookmarked_message.dart';
import 'package:meshcore_open/models/channel_message.dart';

void main() {
  test('outgoing reply keeps the selected target, not the latest post', () {
    final older = ChannelMessage.outgoing('first post', 'Alice', 0);
    ChannelMessage.outgoing('second post', 'Alice', 0);

    final reply = ChannelMessage.outgoing(
      '@[Alice] answer',
      'Me',
      0,
      replyTo: older,
    );

    expect(reply.replyToMessageId, older.messageId);
    expect(reply.replyToSenderName, 'Alice');
    expect(reply.replyToText, 'first post');
    expect(
      ChannelMessage.parseReplyMention(reply.text)?.actualMessage,
      'answer',
    );
  });

  test('outgoing message without reply has no reply target', () {
    final message = ChannelMessage.outgoing('hello', 'Me', 0);
    expect(message.replyToMessageId, isNull);
    expect(message.fullText, 'hello');
  });

  test('fullText restores @[username] prefix for stored replies', () {
    final storedReply = ChannelMessage(
      senderName: 'Me',
      text: 'answer',
      timestamp: DateTime(2026, 1, 1, 12),
      isOutgoing: true,
      replyToMessageId: 'msg-1',
      replyToSenderName: 'Alice',
      replyToText: 'question',
    );

    expect(storedReply.fullText, '@[Alice] answer');

    final bookmark = BookmarkedMessage.fromChannel(
      message: storedReply,
      channelId: 'ch-0',
      channelName: 'Public',
      senderName: 'Me',
    );
    expect(bookmark.text, '@[Alice] answer');
  });

  test('fullText preserves nested mention and special payloads in replies', () {
    final nestedReply = ChannelMessage(
      senderName: 'Bob',
      text: '@[Alice] nested',
      timestamp: DateTime(2026, 1, 1, 12),
      isOutgoing: false,
      replyToMessageId: 'msg-1',
      replyToSenderName: 'Alice',
      replyToText: 'original',
    );
    expect(nestedReply.fullText, '@[Alice] @[Alice] nested');

    final gifReply = ChannelMessage(
      senderName: 'Bob',
      text: 'g:abc123',
      timestamp: DateTime(2026, 1, 1, 12),
      isOutgoing: false,
      replyToMessageId: 'msg-1',
      replyToSenderName: 'Alice',
      replyToText: 'original',
    );
    expect(gifReply.fullText, '@[Alice] g:abc123');
  });
}
