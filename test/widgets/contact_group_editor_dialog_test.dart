import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/contact_group.dart';
import 'package:meshcore_open/storage/contact_group_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/contact_group_editor_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contact _contact(int seed, String name) => Contact(
  publicKey: Uint8List.fromList(List<int>.filled(32, seed)),
  name: name,
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
);

final _alice = _contact(1, 'Alice');
final _bob = _contact(2, 'Bob');
final _carol = _contact(3, 'Carol');
final _dave = _contact(4, 'Dave');

Finder _member(Contact c) =>
    find.byKey(ValueKey('group-member-${c.publicKeyHex}'));
Finder _candidate(Contact c) =>
    find.byKey(ValueKey('group-candidate-${c.publicKeyHex}'));

/// The whole IconButton, including its 48dp tap-target padding.
Finder _button(String tooltip) => find.ancestor(
  of: find.byTooltip(tooltip),
  matching: find.byType(IconButton),
);

/// Opens the editor and returns the groups passed to onSave.
Future<List<ContactGroup>> _open(
  WidgetTester tester, {
  required List<Contact> contacts,
  ContactGroup? group,
  double textScale = 1.0,
}) async {
  final saved = <ContactGroup>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ContactGroupEditorDialog(
                contacts: contacts,
                group: group,
                validateName: (name) => name.isEmpty ? 'required' : null,
                onSave: (g) async => saved.add(g),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return saved;
}

void main() {
  final contacts = [_dave, _carol, _bob, _alice];
  final group = ContactGroup(
    name: 'Team',
    memberKeys: [_carol.publicKeyHex, _alice.publicKeyHex],
  );

  testWidgets('current members are listed first, before the add list', (
    tester,
  ) async {
    await _open(tester, contacts: contacts, group: group);

    expect(find.text('CURRENT MEMBERS (2)'), findsOneWidget);
    final membersHeaderY = tester
        .getTopLeft(find.text('CURRENT MEMBERS (2)'))
        .dy;
    final addHeaderY = tester.getTopLeft(find.text('ADD CONTACTS')).dy;
    final aliceY = tester.getTopLeft(_member(_alice)).dy;
    final carolY = tester.getTopLeft(_member(_carol)).dy;
    expect(membersHeaderY, lessThan(aliceY));
    expect(aliceY, lessThan(carolY));
    expect(carolY, lessThan(addHeaderY));
    expect(tester.getTopLeft(_candidate(_bob)).dy, greaterThan(addHeaderY));
  });

  testWidgets('members never appear again in the add list', (tester) async {
    await _open(tester, contacts: contacts, group: group);

    expect(_candidate(_alice), findsNothing);
    expect(_candidate(_carol), findsNothing);
    expect(_candidate(_bob), findsOneWidget);
    expect(_candidate(_dave), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('remove button drops the member and saves the rest', (
    tester,
  ) async {
    final saved = await _open(tester, contacts: contacts, group: group);

    final remove = _button('Remove Alice from group');
    expect(remove, findsOneWidget);
    expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));

    await tester.tap(remove);
    await tester.pumpAndSettle();

    expect(find.text('CURRENT MEMBERS (1)'), findsOneWidget);
    expect(_member(_alice), findsNothing);
    // Still a contact: it moves back to the add list.
    expect(_candidate(_alice), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved.single.name, 'Team');
    expect(saved.single.memberKeys, [_carol.publicKeyHex]);
    expect(contacts, hasLength(4));
    expect(contacts, contains(_alice));
  });

  testWidgets('search filters the add list and tapping adds a contact', (
    tester,
  ) async {
    final saved = await _open(tester, contacts: contacts, group: group);

    await tester.enterText(find.byType(TextField).last, 'da');
    await tester.pumpAndSettle();
    expect(_candidate(_dave), findsOneWidget);
    expect(_candidate(_bob), findsNothing);
    // Members stay visible while searching.
    expect(_member(_alice), findsOneWidget);

    await tester.tap(find.text('Dave'));
    await tester.pumpAndSettle();

    expect(_member(_dave), findsOneWidget);
    expect(_candidate(_dave), findsNothing);
    expect(find.text('CURRENT MEMBERS (3)'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved.single.memberKeys, [
      _carol.publicKeyHex,
      _alice.publicKeyHex,
      _dave.publicKeyHex,
    ]);
    expect(saved.single.memberKeys.toSet(), hasLength(3));
  });

  testWidgets('keys of contacts not on the radio are kept on save', (
    tester,
  ) async {
    final stale = 'ff' * 32;
    final saved = await _open(
      tester,
      contacts: contacts,
      group: ContactGroup(name: 'Team', memberKeys: [stale]),
    );

    await tester.tap(find.byTooltip('Add Bob to group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved.single.memberKeys, [stale, _bob.publicKeyHex]);
  });

  testWidgets('edited membership persists through the group store', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    final store = ContactGroupStore()..setPublicKeyHex = 'abcdef0123456789';

    final saved = await _open(tester, contacts: contacts, group: group);
    await tester.tap(find.byTooltip('Remove Carol from group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.runAsync(() => store.saveGroups(saved));
    final loaded = await tester.runAsync(store.loadGroups);
    expect(loaded!.single.name, 'Team');
    expect(loaded.single.memberKeys, [_alice.publicKeyHex]);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('fits a 320dp screen at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _open(tester, contacts: contacts, group: group, textScale: scale);

      expect(tester.takeException(), isNull);
      final remove = _button('Remove Alice from group');
      expect(remove, findsOneWidget);
      expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(_member(_alice), findsNothing);
    });
  }
}
