import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/channel_message_path_screen.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:provider/provider.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector(this.hopContacts);

  final List<Contact> hopContacts;

  @override
  List<Contact> get allContacts => hopContacts;

  @override
  double? get selfLatitude => null;

  @override
  double? get selfLongitude => null;
}

void main() {
  testWidgets('hop avatars use the repeater name or the hex prefix', (
    tester,
  ) async {
    final connector = _FakeConnector([
      Contact(
        publicKey: Uint8List(32)..first = 0xAA,
        name: '(Base) Hilltop',
        type: advTypeRepeater,
        pathLength: 0,
        path: Uint8List(0),
        lastSeen: DateTime.utc(2026),
      ),
    ]);
    final message = ChannelMessage(
      senderName: 'Alice',
      text: 'hello',
      timestamp: DateTime.utc(2026),
      isOutgoing: false,
      pathBytes: Uint8List.fromList([0xAA, 0xBC]),
      channelIndex: 0,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: connector,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChannelMessagePathScreen(
            message: message,
            channelMessage: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatarNames = tester
        .widgetList<AvatarCircle>(find.byType(AvatarCircle))
        .map((avatar) => avatar.name)
        .toList();
    expect(avatarNames, containsAll(['(Base) Hilltop', 'BC']));
    expect(
      find.descendant(of: find.byType(AvatarCircle), matching: find.text('BH')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AvatarCircle),
        matching: find.textContaining('('),
      ),
      findsNothing,
    );
  });
}
