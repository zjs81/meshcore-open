import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/screens/repeater_cli_screen.dart';

class _SilentConnector extends MeshCoreConnector {
  final List<Uint8List> sentFrames = [];

  @override
  bool get isConnected => true;

  @override
  Future<PathSelection> preparePathForContactSend(Contact contact) async =>
      const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);

  @override
  int calculateTimeout({
    required int pathLength,
    int messageBytes = 100,
    String? contactKey,
    int? deviceTimeoutMs,
  }) => 30;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
    bool waitForGenericAck = false,
  }) async {
    sentFrames.add(data);
  }
}

Contact _repeater() => Contact(
  publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
  name: 'Repeater',
  type: 2,
  pathLength: -1,
  path: Uint8List(0),
  lastSeen: DateTime.now(),
);

Future<void> _pumpScreen(
  WidgetTester tester,
  _SilentConnector connector,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<MeshCoreConnector>.value(
      value: connector,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepeaterCliScreen(repeater: _repeater(), password: 'pw'),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  const command = 'get freq';

  Future<void> sendCommand(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, command);
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
  }

  String? clipboardText;
  setUp(() {
    clipboardText = null;
  });

  void mockPlatform(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
  }

  testWidgets('a silent repeater gets the initial send plus two resends', (
    tester,
  ) async {
    mockPlatform(tester);
    final connector = _SilentConnector();
    await _pumpScreen(tester, connector);

    await sendCommand(tester);
    // Each attempt times out after 30ms; 200ms covers all three.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));

    expect(connector.sentFrames, hasLength(3));
    expect(find.text(command), findsOneWidget);
    expect(find.textContaining('Command timeout'), findsOneWidget);
  });

  testWidgets('long press on a command offers resend and copy', (tester) async {
    mockPlatform(tester);
    final connector = _SilentConnector();
    await _pumpScreen(tester, connector);
    await sendCommand(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));

    await tester.longPress(find.text(command));
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RepeaterCliScreen)),
    );
    expect(find.text(l10n.repeater_cliResendCommand), findsOneWidget);
    expect(find.text(l10n.common_copy), findsOneWidget);

    await tester.tap(find.text(l10n.common_copy));
    await tester.pump(const Duration(milliseconds: 500));
    expect(clipboardText, command);

    expect(find.text(l10n.repeater_cliCommandCopied), findsOneWidget);
  });

  testWidgets('long press resend re-sends the command', (tester) async {
    mockPlatform(tester);
    final connector = _SilentConnector();
    await _pumpScreen(tester, connector);
    await sendCommand(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(connector.sentFrames, hasLength(3));

    await tester.longPress(find.text(command));
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RepeaterCliScreen)),
    );
    await tester.tap(find.text(l10n.repeater_cliResendCommand));
    await tester.pump();

    // The resend starts its own initial send; it is not counted until its
    // timeouts elapse, so the frame count grows by at least one.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(connector.sentFrames.length, greaterThan(3));
  });
}
