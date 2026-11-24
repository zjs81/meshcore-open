import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/screens/chat_compression_screen.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

final _profiles = [
  Cyr2LatProfile(id: 'ru', name: 'Russian', charMap: const {'А': 'A'}),
  Cyr2LatProfile(id: 'sr', name: 'Serbian', charMap: const {'З': '3'}),
];

/// Stands in for a chat screen: keeps the "saved" state and applies a change
/// only when the test completes the pending write.
class _Host extends ChangeNotifier {
  ChatCompressionMode mode;
  String? profileId;
  final bool enabled;
  final List<ChatCompressionMode> modeCalls = [];
  final List<String> profileCalls = [];
  final List<Completer<void>> pending = [];

  _Host({
    this.mode = ChatCompressionMode.off,
    this.enabled = true,
    this.profileId,
  });

  ChatCompressionState read() => ChatCompressionState(
    mode: mode,
    enabled: enabled,
    disabledReason: enabled ? null : _l10n.chatCompression_noStorageId,
    profiles: _profiles,
    profileId: profileId,
    defaultProfileId: 'ru',
  );

  Future<void> _write(void Function() apply) async {
    final completer = Completer<void>();
    pending.add(completer);
    await completer.future;
    apply();
    notifyListeners();
  }

  Future<void> setMode(ChatCompressionMode m) {
    modeCalls.add(m);
    return _write(() => mode = m);
  }

  Future<void> setProfile(String id) {
    profileCalls.add(id);
    return _write(() => profileId = id);
  }
}

void main() {
  late _Host host;

  Future<void> pumpPage(
    WidgetTester tester, {
    ChatCompressionMode mode = ChatCompressionMode.off,
    bool enabled = true,
    String? profileId,
    Size size = const Size(400, 800),
    double textScale = 1.0,
  }) async {
    host = _Host(mode: mode, enabled: enabled, profileId: profileId);
    addTearDown(host.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ChatCompressionScreen(
          listenable: host,
          read: host.read,
          onModeChanged: host.setMode,
          onProfileChanged: host.setProfile,
        ),
      ),
    );
  }

  Finder optionRow(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(ListTile));

  bool isSelected(String label) {
    return find
        .descendant(
          of: optionRow(label),
          matching: find.byIcon(Icons.radio_button_checked),
        )
        .evaluate()
        .isNotEmpty;
  }

  testWidgets(
    'lists the three modes with short notes and marks the saved one',
    (tester) async {
      await pumpPage(tester, mode: ChatCompressionMode.smaz);

      expect(find.text(_l10n.chatCompression_title), findsWidgets);
      expect(find.text(_l10n.chatCompression_off), findsOneWidget);
      expect(find.text(_l10n.chatCompression_smaz), findsOneWidget);
      expect(find.text(_l10n.chatCompression_cyr2lat), findsOneWidget);
      expect(find.text(_l10n.chatCompression_offDescription), findsOneWidget);
      expect(find.text(_l10n.chatCompression_smazDescription), findsOneWidget);
      expect(
        find.text(_l10n.chatCompression_cyr2latDescription),
        findsOneWidget,
      );
      expect(isSelected(_l10n.chatCompression_smaz), isTrue);
      expect(isSelected(_l10n.chatCompression_off), isFalse);
      expect(find.text(_l10n.chatCompression_profile), findsNothing);
      for (final mode in [
        _l10n.chatCompression_off,
        _l10n.chatCompression_smaz,
        _l10n.chatCompression_cyr2lat,
      ]) {
        expect(
          tester.getSize(optionRow(mode)).height,
          greaterThanOrEqualTo(48),
          reason: mode,
        );
      }
    },
  );

  testWidgets('a choice shows only after it is saved', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text(_l10n.chatCompression_smaz));
    await tester.pump();
    expect(host.modeCalls, [ChatCompressionMode.smaz]);
    // Still saving: old mode shown, options locked against rapid taps.
    expect(isSelected(_l10n.chatCompression_off), isTrue);
    expect(
      tester.widget<ListTile>(optionRow(_l10n.chatCompression_cyr2lat)).enabled,
      isFalse,
    );
    await tester.tap(find.text(_l10n.chatCompression_cyr2lat));
    await tester.pump();
    expect(host.modeCalls, [ChatCompressionMode.smaz]);

    host.pending.single.complete();
    await tester.pumpAndSettle();
    expect(isSelected(_l10n.chatCompression_smaz), isTrue);
    expect(isSelected(_l10n.chatCompression_off), isFalse);
    expect(
      tester.widget<ListTile>(optionRow(_l10n.chatCompression_cyr2lat)).enabled,
      isTrue,
    );
  });

  testWidgets('Cyr2Lat reveals the profile picker', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text(_l10n.chatCompression_cyr2lat));
    await tester.pump();
    host.pending.removeAt(0).complete();
    await tester.pumpAndSettle();

    expect(isSelected(_l10n.chatCompression_cyr2lat), isTrue);
    expect(find.text(_l10n.chatCompression_profile), findsWidgets);
    // No profile saved for the chat: the app-wide one is what sending uses.
    expect(find.text('Russian'), findsOneWidget);

    await tester.tap(find.text('Russian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serbian').last);
    await tester.pump();
    expect(host.profileCalls, ['sr']);
    host.pending.removeAt(0).complete();
    await tester.pumpAndSettle();
    expect(find.text('Serbian'), findsOneWidget);
  });

  testWidgets('a failed save keeps the saved mode and says so', (tester) async {
    await pumpPage(tester, mode: ChatCompressionMode.smaz);

    await tester.tap(find.text(_l10n.chatCompression_cyr2lat));
    await tester.pump();
    host.pending.single.completeError(StateError('disk full'));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.chatCompression_saveFailed), findsOneWidget);
    expect(isSelected(_l10n.chatCompression_smaz), isTrue);
    expect(isSelected(_l10n.chatCompression_cyr2lat), isFalse);
    expect(
      tester.widget<ListTile>(optionRow(_l10n.chatCompression_off)).enabled,
      isTrue,
    );
  });

  testWidgets('a failed profile save shows the saved profile again', (
    tester,
  ) async {
    await pumpPage(tester, mode: ChatCompressionMode.cyr2lat, profileId: 'ru');

    await tester.tap(find.text('Russian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serbian').last);
    await tester.pump();
    expect(host.profileCalls, ['sr']);
    host.pending.single.completeError(StateError('disk full'));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.chatCompression_saveFailed), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Russian'), 100);
    expect(find.text('Russian'), findsOneWidget);
    expect(find.text('Serbian'), findsNothing);
  });

  testWidgets('disabled shows the saved mode, says why and allows no change', (
    tester,
  ) async {
    await pumpPage(tester, mode: ChatCompressionMode.smaz, enabled: false);

    expect(find.text(_l10n.chatCompression_noStorageId), findsOneWidget);
    expect(isSelected(_l10n.chatCompression_smaz), isTrue);
    for (final mode in [
      _l10n.chatCompression_off,
      _l10n.chatCompression_smaz,
      _l10n.chatCompression_cyr2lat,
    ]) {
      expect(tester.widget<ListTile>(optionRow(mode)).enabled, isFalse);
    }
    await tester.tap(find.text(_l10n.chatCompression_off), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(host.modeCalls, isEmpty);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('fits a 320dp phone at ${scale}x text', (tester) async {
      await pumpPage(
        tester,
        mode: ChatCompressionMode.cyr2lat,
        size: const Size(320, 568),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      // The page scrolls to its last option and the profile picker.
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<String>),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
