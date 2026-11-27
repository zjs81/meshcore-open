import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/screens/filtered_messages_screen.dart';

ChannelMessage _msg() => ChannelMessage(
  senderName: 'Twin',
  text: 'Same words posted to two channels at once',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  isOutgoing: false,
);

void main() {
  test('rows for colliding message ids in two channels stay distinct', () {
    final first = Channel(
      index: 1,
      name: 'One',
      psk: Uint8List.fromList(List.filled(16, 1)),
    );
    final second = Channel(
      index: 2,
      name: 'Two',
      psk: Uint8List.fromList(List.filled(16, 2)),
    );
    final a = _msg();
    final b = _msg();
    // Message ids do not include the channel, so these collide...
    expect(a.messageId, b.messageId);
    // ...but the list rows (keys, selection, pending changes) must not.
    expect(
      filteredMessageRowId(first, a),
      isNot(filteredMessageRowId(second, b)),
    );
    expect(filteredMessageRowId(first, a), filteredMessageRowId(first, b));
  });
}
