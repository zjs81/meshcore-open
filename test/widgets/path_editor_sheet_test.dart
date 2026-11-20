import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/widgets/path_editor_sheet.dart';

Contact _repeater(String name, List<int> prefix) {
  final key = Uint8List(32);
  for (var i = 0; i < prefix.length; i++) {
    key[i] = prefix[i];
  }
  return Contact(
    publicKey: key,
    name: name,
    type: advTypeRepeater,
    pathLength: -1,
    path: Uint8List(0),
    lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

final _contacts = [
  _repeater('100 Acre', [0x11, 0x22]),
  _repeater('Acreage North', [0x33, 0x44]),
  _repeater('My Acre Site', [0x55, 0x66]),
  _repeater('2E0HQR-R', [0x2E, 0x0A]),
  _repeater('CR1', [0x60, 0x60]),
  for (var i = 0; i < 24; i++) _repeater('Repeater $i', [0xA0, i]),
];

Future<void> _pumpSheet(
  WidgetTester tester, {
  Size size = const Size(400, 700),
  double keyboard = 0,
  List<int> initialPath = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height - keyboard,
            child: PathEditorSheet(
              availableContacts: _contacts,
              initialPath: initialPath,
              pathHashByteWidth: 2,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _repeaterNames(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('path-editor-repeater-list')),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data)
      .whereType<String>()
      .where((text) => !text.contains('•'))
      .toList();
}

void main() {
  testWidgets('prefix matches are listed before other substring matches', (
    tester,
  ) async {
    await _pumpSheet(tester);
    await tester.enterText(
      find.byKey(const Key('path-editor-search-field')),
      'acre',
    );
    await tester.pumpAndSettle();

    final visible = _repeaterNames(tester);
    expect(visible.first, 'Acreage North');
    expect(visible[1], '100 Acre');
    await tester.scrollUntilVisible(
      find.text('My Acre Site'),
      80,
      scrollable: find.descendant(
        of: find.byKey(const Key('path-editor-repeater-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('My Acre Site'), findsOneWidget);
  });

  testWidgets('search matches a hop hash the name does not contain', (
    tester,
  ) async {
    await _pumpSheet(tester);
    await tester.enterText(
      find.byKey(const Key('path-editor-search-field')),
      '6060',
    );
    await tester.pumpAndSettle();

    expect(find.text('No repeaters or room servers found.'), findsNothing);
    expect(_repeaterNames(tester), ['CR1']);
  });

  testWidgets('hex entry is reachable without scrolling the repeater list', (
    tester,
  ) async {
    await _pumpSheet(tester, size: const Size(400, 900));
    expect(
      find.byKey(const Key('path-editor-hex-field')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Hex prefixes'), findsOneWidget);
    expect(
      find.text('4 hex characters per hop, separated by commas'),
      findsOneWidget,
    );
  });

  testWidgets('an added hop stays fully visible with the keyboard open', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      size: const Size(390, 640),
      keyboard: 320,
      initialPath: [0x60, 0x60],
    );

    final tile = find.ancestor(
      of: find.byIcon(Icons.remove_circle_outline),
      matching: find.byType(ListTile),
    );
    expect(tile.hitTestable(), findsOneWidget);
    final title = tester.getRect(find.text('Build Path'));
    final hopRect = tester.getRect(tile);
    final sheet = tester.getRect(find.byType(PathEditorSheet));
    expect(hopRect.top, greaterThanOrEqualTo(title.bottom));
    expect(hopRect.bottom, lessThanOrEqualTo(sheet.bottom));
    expect(hopRect.height, greaterThanOrEqualTo(48));
    expect(find.text('CR1').hitTestable(), findsWidgets);
    expect(find.text('6060').hitTestable(), findsWidgets);
    expect(
      find.byKey(const Key('path-editor-hex-field')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an invalid hex path does not overflow a keyboard-height sheet', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      size: const Size(390, 640),
      keyboard: 320,
      initialPath: [0x60, 0x60, 0x11, 0x22],
    );
    await tester.enterText(
      find.byKey(const Key('path-editor-hex-field')),
      'ZZ',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      find.byIcon(Icons.remove_circle_outline).hitTestable(),
      findsWidgets,
    );
    final button = tester.getRect(find.text('Use this path'));
    final sheet = tester.getRect(find.byType(PathEditorSheet));
    expect(button.bottom, lessThanOrEqualTo(sheet.bottom + 1));
  });

  testWidgets('action buttons stay below the repeater list on a short sheet', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      size: const Size(400, 560),
      initialPath: [0x60, 0x60, 0x11, 0x22],
    );

    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.text('Use this path'));
    final list = tester.getRect(
      find.byKey(const Key('path-editor-repeater-list')),
    );
    expect(button.top, greaterThanOrEqualTo(list.bottom - 1));
  });

  testWidgets('the title sits at the top of the sheet', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    // A phone status bar. The sheet may pad for it, and must not add another
    // empty band above the handle.
    tester.view.padding = const FakeViewPadding(top: 47);
    tester.view.viewPadding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PathEditorSheet.show(
                context,
                availableContacts: _contacts,
                pathHashByteWidth: 2,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheetTop = tester.getTopLeft(find.byType(BottomSheet)).dy;
    final titleTop = tester.getTopLeft(find.text('Build Path')).dy;
    // Header only: 8px padding, a 4px handle, and a 10px gap. The status-bar
    // inset stays outside the sheet, and there is no extra empty band.
    expect(titleTop - sheetTop, inInclusiveRange(16, 36));
  });

  testWidgets('tapping a repeater adds a visible hop', (tester) async {
    await _pumpSheet(tester);
    await tester.enterText(
      find.byKey(const Key('path-editor-search-field')),
      '6060',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'CR1'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 64 hops'), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    expect(find.text('CR1').hitTestable(), findsWidgets);
  });
}
