import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/mention_search.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';

ChannelMessage incoming(String sender, DateTime at) => ChannelMessage(
  senderName: sender,
  text: 'hello',
  timestamp: at,
  isOutgoing: false,
);

Contact contact(
  String name, {
  int type = advTypeChat,
  DateTime? lastMessageAt,
}) => Contact(
  publicKey: Uint8List(32),
  name: name,
  type: type,
  pathLength: -1,
  path: Uint8List(0),
  lastSeen: DateTime(2026, 1, 1),
  lastMessageAt: lastMessageAt,
);

List<String> names(List<MentionCandidate> candidates) =>
    candidates.map((c) => c.name).toList();

void main() {
  final t1 = DateTime(2026, 11, 1, 10);
  final t2 = DateTime(2026, 11, 2, 10);
  final t3 = DateTime(2026, 11, 3, 10);

  test('orders candidates by most recent channel message', () {
    final results = searchMentionCandidates(
      messages: [
        incoming('Bob', t1),
        incoming('Alice', t3),
        incoming('Bob', t2),
      ],
      contacts: [],
    );
    expect(names(results), ['Alice', 'Bob']);
  });

  test('contacts without channel messages sort after senders', () {
    final results = searchMentionCandidates(
      messages: [incoming('Carol', t2)],
      contacts: [
        contact('Zed', lastMessageAt: t3),
        contact('Carol'),
        contact('Ann', lastMessageAt: DateTime(2026, 11, 1)),
      ],
    );
    expect(names(results), ['Carol', 'Zed', 'Ann']);
  });

  test('query filters case-insensitively on substrings', () {
    final results = searchMentionCandidates(
      messages: [
        incoming('Alice', t3),
        incoming('Alan', t2),
        incoming('Bob', t1),
      ],
      contacts: [contact('Aline')],
      query: 'al',
    );
    expect(names(results), ['Alice', 'Alan', 'Aline']);
  });

  test('excludes self, outgoing, and unknown senders', () {
    final results = searchMentionCandidates(
      messages: [
        ChannelMessage(
          senderName: 'Me',
          text: 'x',
          timestamp: t3,
          isOutgoing: true,
        ),
        incoming('Unknown', t2),
        incoming('  ', t1),
      ],
      contacts: [contact('Me'), contact('Bob')],
      selfName: 'Me',
    );
    expect(names(results), ['Bob']);
  });

  test('a contact who posted uses the message time', () {
    final results = searchMentionCandidates(
      messages: [incoming('Bob', t3)],
      contacts: [
        contact('Bob', lastMessageAt: t1),
        contact('Ann', lastMessageAt: t2),
      ],
    );
    expect(names(results), ['Bob', 'Ann']);
    expect(results.first.lastMessageAt, t3);
  });

  test('non-chat contacts are not offered', () {
    final results = searchMentionCandidates(
      messages: [],
      contacts: [
        contact('Relay 1', type: advTypeRepeater),
        contact('Room', type: advTypeRoom),
        contact('Bob'),
      ],
    );
    expect(names(results), ['Bob']);
  });

  test('equal recency falls back to name order', () {
    final results = searchMentionCandidates(
      messages: [incoming('zoe', t1), incoming('amy', t1)],
      contacts: [],
    );
    expect(names(results), ['amy', 'zoe']);
  });
}
