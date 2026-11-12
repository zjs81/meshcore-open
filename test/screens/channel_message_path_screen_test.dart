import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/channel_message_path_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector(this.hopContacts);

  final List<Contact> hopContacts;

  @override
  List<Contact> get allContacts => hopContacts;

  @override
  List<Contact> get allContactsUnfiltered => hopContacts;

  @override
  double? get selfLatitude => null;

  @override
  double? get selfLongitude => null;
}

Contact _repeater(int firstByte, String name) {
  return Contact(
    publicKey: Uint8List.fromList([
      firstByte,
      ...List.filled(31, firstByte == 0xAA ? 1 : 2),
    ]),
    name: name,
    type: advTypeRepeater,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime.utc(2026, 1, 1),
  );
}

ChannelMessage _buildMessage() {
  final primary = Uint8List.fromList([0xAA, 0xBB]);
  final variant = Uint8List.fromList([0xCC]);
  return ChannelMessage(
    senderName: 'Alice',
    text: 'hello mesh',
    timestamp: DateTime.utc(2026, 1, 1),
    isOutgoing: false,
    pathBytes: primary,
    pathVariants: [variant],
    snrDb: 7.2,
    rssiDbm: -103,
    pathSignals: {
      ChannelMessage.pathKey(variant): PathSignal(snrDb: 3.0, rssiDbm: -110),
    },
    channelIndex: 1,
  );
}

Widget _buildApp({required MeshCoreConnector connector}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
      ChangeNotifierProvider<AppSettingsService>(
        create: (_) => AppSettingsService(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChannelMessagePathScreen(
        message: _buildMessage(),
        channelMessage: true,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'path page shows the last repeater heard and its signal for each path',
    (tester) async {
      final connector = _FakeConnector([
        _repeater(0xAA, 'RepeaterA'),
        _repeater(0xBB, 'RepeaterB'),
        _repeater(0xCC, 'RepeaterC'),
      ]);

      await tester.pumpWidget(_buildApp(connector: connector));
      await tester.pumpAndSettle();

      // Primary path: last hop (BB) with the signal that copy arrived on,
      // each measurement coloured on its own.
      expect(find.text('LAST HOP'), findsOneWidget);
      expect(find.textContaining('(BB) RepeaterB'), findsWidgets);
      expect(find.textContaining('-103dBm'), findsWidgets);
      expect(find.textContaining('7.2dB'), findsWidgets);

      // Variant path: last hop (CC) with its own observed signal.
      expect(find.textContaining('Last hop: (CC) RepeaterC'), findsOneWidget);
      expect(find.textContaining('-110dBm'), findsOneWidget);
      expect(find.textContaining('3.0dB'), findsOneWidget);
    },
  );

  testWidgets('copy button puts comma-separated prefixes on the clipboard', (
    tester,
  ) async {
    final connector = _FakeConnector([
      _repeater(0xAA, 'RepeaterA'),
      _repeater(0xBB, 'RepeaterB'),
      _repeater(0xCC, 'RepeaterC'),
    ]);
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_buildApp(connector: connector));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byTooltip('Copy path'),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(copied, ['AA,BB']);
    expect(find.text('Path copied to clipboard'), findsOneWidget);

    // Each observed path card carries its own copy button too.
    final copyButtons = find
        .descendant(
          of: find.byType(MeshCard),
          matching: find.byIcon(Icons.copy),
        )
        .evaluate()
        .length;
    expect(copyButtons, 1);
    await tester.tap(
      find
          .descendant(
            of: find.byType(MeshCard),
            matching: find.byIcon(Icons.copy),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(copied.last, 'CC');
  });
}
