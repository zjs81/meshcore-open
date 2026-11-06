import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
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
    // ...but the list rows (keys and reveal state) must not.
    expect(
      filteredMessageRowId(first, a),
      isNot(filteredMessageRowId(second, b)),
    );
    expect(filteredMessageRowId(first, a), filteredMessageRowId(first, b));
  });

  testWidgets('collapsed cards shorten a whole-message rule pattern', (
    tester,
  ) async {
    const pattern =
        'meshcore.co.uk is not a genuine site, the real one is meshcore.io';
    final message = ChannelMessage(
      senderName: 'SAY NO TO FRAUDS!',
      text: pattern,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      isOutgoing: false,
      filterReason: 'textRule',
      filterDetail: pattern,
    );
    late String collapsed;
    late String revealed;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            collapsed = messageFilterReasonText(context, message);
            revealed = messageFilterReasonText(
              context,
              message,
              revealed: true,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(collapsed, isNot(contains(pattern)));
    expect(collapsed, contains('…'));
    expect(revealed, contains(pattern));
  });
}
