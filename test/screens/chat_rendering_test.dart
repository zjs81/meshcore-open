import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/chat_composer.dart';
import 'package:meshcore_open/widgets/message_status_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tools/benchmark_scan_updates.dart';

class _EncodingConnector extends UiReplayConnector {
  _EncodingConnector({super.history = 6})
    : super(throttled: false, devices: 1, scenario: 'chat-notify');

  bool smazEnabled = false;
  bool cyr2LatEnabled = false;

  @override
  bool isContactSmazEnabled(String keyHex) => smazEnabled;

  @override
  bool isContactCyr2LatEnabled(String keyHex) => cyr2LatEnabled;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<_EncodingConnector> mount(
    WidgetTester tester, {
    int history = 6,
  }) async {
    final connector = _EncodingConnector(history: history);
    addTearDown(connector.dispose);
    await tester.pumpWidget(buildUiBenchmarkApp(connector));
    await tester.pumpAndSettle();
    return connector;
  }

  Future<void> notify(WidgetTester tester, UiReplayConnector connector) async {
    connector.notifyListeners();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
  }

  testWidgets('unrelated notifications retain composer, draft and focus', (
    tester,
  ) async {
    final connector = await mount(tester);
    final before = tester.widget<ChatComposer>(find.byType(ChatComposer));
    before.controller.text = 'unsent draft';
    before.focusNode.requestFocus();
    await tester.pumpAndSettle();

    await notify(tester, connector);

    final after = tester.widget<ChatComposer>(find.byType(ChatComposer));
    expect(identical(before, after), isTrue);
    expect(after.controller.text, 'unsent draft');
    expect(after.focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('same-count replacement and new messages still refresh', (
    tester,
  ) async {
    final connector = await mount(tester);
    final composer = tester.widget<ChatComposer>(find.byType(ChatComposer));
    final previous = connector.messages.last;
    connector.messages[connector.messages.length - 1] = Message(
      senderKey: previous.senderKey,
      text: 'replacement text',
      timestamp: previous.timestamp,
      isOutgoing: previous.isOutgoing,
      status: MessageStatus.delivered,
      messageId: previous.messageId,
    );
    await notify(tester, connector);
    expect(find.text('replacement text'), findsOneWidget);
    expect(
      identical(
        composer,
        tester.widget<ChatComposer>(find.byType(ChatComposer)),
      ),
      isTrue,
    );

    connector.messages.add(
      Message(
        senderKey: connector.contact.publicKey,
        text: 'new incoming message',
        timestamp: DateTime(2026, 1, 2),
        isOutgoing: false,
      ),
    );
    await notify(tester, connector);
    expect(find.text('new incoming message'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'contact rename refreshes composer tooltip without losing draft',
    (tester) async {
      final connector = await mount(tester);
      final before = tester.widget<ChatComposer>(find.byType(ChatComposer));
      before.controller.text = 'retained draft';
      connector.contact = connector.contact.copyWith(name: 'Renamed contact');
      await notify(tester, connector);
      final after = tester.widget<ChatComposer>(find.byType(ChatComposer));
      expect(after.sendTooltip, contains('Renamed contact'));
      expect(after.controller, same(before.controller));
      expect(after.controller.text, 'retained draft');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('encoding mode changes refresh the composer', (tester) async {
    final connector = await mount(tester);
    final original = tester.widget<ChatComposer>(find.byType(ChatComposer));
    expect(original.encoder, isNull);
    connector.smazEnabled = true;
    await notify(tester, connector);
    final smaz = tester.widget<ChatComposer>(find.byType(ChatComposer));
    expect(smaz.encoder, isNotNull);
    connector.smazEnabled = false;
    connector.cyr2LatEnabled = true;
    await notify(tester, connector);
    final cyr2Lat = tester.widget<ChatComposer>(find.byType(ChatComposer));
    expect(cyr2Lat.encoder, isNotNull);
    expect(identical(smaz, cyr2Lat), isFalse);
    connector.cyr2LatEnabled = false;
    await notify(tester, connector);
    expect(
      tester.widget<ChatComposer>(find.byType(ChatComposer)).encoder,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('status-only updates refresh delivery icons', (tester) async {
    final connector = await mount(tester);
    expect(
      tester
          .widgetList<MessageStatusIcon>(find.byType(MessageStatusIcon))
          .any((icon) => icon.isAcked),
      isFalse,
    );
    connector.messages[connector.messages.length - 1] = connector.messages.last
        .copyWith(status: MessageStatus.delivered);
    await notify(tester, connector);
    expect(
      tester
          .widgetList<MessageStatusIcon>(find.byType(MessageStatusIcon))
          .any((icon) => icon.isAcked),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('incoming messages preserve a scrolled reading position', (
    tester,
  ) async {
    final connector = await mount(tester, history: 100);
    final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
    scroll.jumpTo(500);
    await tester.pumpAndSettle();
    final offset = scroll.offset;
    connector.messages.add(
      Message(
        senderKey: connector.contact.publicKey,
        text: 'arrived while reading history',
        timestamp: DateTime(2026, 1, 2),
        isOutgoing: false,
      ),
    );
    await notify(tester, connector);
    expect(scroll.offset, offset);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
