import 'package:flutter_test/flutter_test.dart';
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
  });
}
