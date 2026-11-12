import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/repeater_acl_screen.dart';
import 'package:meshcore_open/screens/repeater_settings_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

Contact makeContact(String name, List<int> prefixBytes) {
  final key = Uint8List(32);
  for (var i = 0; i < prefixBytes.length; i++) {
    key[i] = prefixBytes[i];
  }
  for (var i = prefixBytes.length; i < 32; i++) {
    key[i] = i;
  }
  return Contact(
    publicKey: key,
    name: name,
    type: 1,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime(2026),
  );
}

void main() {
  group('parseAclPayload', () {
    test('decodes 6-byte prefix + permissions records', () {
      final contacts = [
        makeContact('Alice', [0x11, 0x11, 0x11, 0x11, 0x11, 0x11]),
        makeContact('Bob', [0x22, 0x22, 0x22, 0x22, 0x22, 0x22]),
        makeContact('Cari', [0x22, 0x22, 0x22, 0x22, 0x22, 0x22]),
      ];
      final payload = Uint8List.fromList([
        0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 3,
        0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 2,
        // Trailing partial record must be ignored.
        0x33, 0x33, 0x33,
      ]);

      final entries = parseAclPayload(payload, contacts);

      expect(entries.length, 2);
      expect(entries[0].prefixHex, '111111111111');
      expect(entries[0].permissions, 3);
      expect(entries[0].names, ['Alice']);
      expect(entries[1].prefixHex, '222222222222');
      expect(entries[1].permissions, 2);
      expect(entries[1].names, ['Bob', 'Cari']);
    });

    test('unresolvable prefix yields no names', () {
      final payload = Uint8List.fromList([
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        1,
      ]);
      final entries = parseAclPayload(payload, []);
      expect(entries.length, 1);
      expect(entries.single.names, isEmpty);
    });

    test('empty payload yields no entries', () {
      expect(parseAclPayload(Uint8List(0), []), isEmpty);
    });
  });

  testWidgets('repeater settings show the ACL entry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    tester.view.physicalSize = const Size(1080, 24000);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MeshCoreConnector()),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepeaterSettingsScreen(
            repeater: Contact(
              publicKey: Uint8List(32),
              name: 'Repeater',
              type: 2,
              pathLength: 0,
              path: Uint8List(0),
              lastSeen: DateTime(2026),
            ),
            password: 'x',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RepeaterSettingsScreen)),
    );
    expect(find.text(l10n.repeater_aclTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ACL screen reports a hint before the first load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MeshCoreConnector(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepeaterAclScreen(
            repeater: Contact(
              publicKey: Uint8List(32),
              name: 'Repeater',
              type: 2,
              pathLength: 0,
              path: Uint8List(0),
              lastSeen: DateTime(2026),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RepeaterAclScreen)),
    );
    // Disconnected radio: the load aborts and the hint stays visible.
    expect(find.text(l10n.repeater_aclLoadHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
