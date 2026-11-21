import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/chat_compression_selector.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

final _profiles = [
  Cyr2LatProfile(id: 'ru', name: 'Russian', charMap: const {'А': 'A'}),
  Cyr2LatProfile(id: 'sr', name: 'Serbian', charMap: const {'З': '3'}),
];

/// Stands in for a chat screen: keeps the "saved" state and applies a change
/// only when the test completes the pending write.
class _Host extends StatefulWidget {
  final ChatCompressionMode initialMode;
  final bool enabled;
  final String? initialProfileId;
  final List<ChatCompressionMode> modeCalls;
  final List<String> profileCalls;
  final List<Completer<void>> pending;

  const _Host({
    this.initialMode = ChatCompressionMode.off,
    this.enabled = true,
    this.initialProfileId,
    required this.modeCalls,
    required this.profileCalls,
    required this.pending,
  });

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late ChatCompressionMode _mode = widget.initialMode;
  late String? _profileId = widget.initialProfileId;

  Future<void> _write(void Function() apply) async {
    final completer = Completer<void>();
    widget.pending.add(completer);
    await completer.future;
    if (mounted) setState(apply);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          ChatCompressionSelector(
            mode: _mode,
            enabled: widget.enabled,
            disabledReason: widget.enabled
                ? null
                : _l10n.chatCompression_noStorageId,
            profiles: _profiles,
            profileId: _profileId,
            defaultProfileId: 'ru',
            onModeChanged: (mode) {
              widget.modeCalls.add(mode);
              return _write(() => _mode = mode);
            },
            onProfileChanged: (id) {
              widget.profileCalls.add(id);
              return _write(() => _profileId = id);
            },
          ),
          const Expanded(child: Placeholder()),
        ],
      ),
    );
  }
}

void main() {
  late List<ChatCompressionMode> modeCalls;
  late List<String> profileCalls;
  late List<Completer<void>> pending;

  setUp(() {
    modeCalls = [];
    profileCalls = [];
    pending = [];
  });

  Future<void> pumpHost(
    WidgetTester tester, {
    ChatCompressionMode mode = ChatCompressionMode.off,
    bool enabled = true,
    String? profileId,
    Size size = const Size(400, 800),
    double textScale = 1.0,
  }) async {
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
        home: _Host(
          initialMode: mode,
          enabled: enabled,
          initialProfileId: profileId,
          modeCalls: modeCalls,
          profileCalls: profileCalls,
          pending: pending,
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(ChatCompressionSelector));
    await tester.pumpAndSettle();
  }

  Finder optionRow(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(ListTile));

  bool isSelected(WidgetTester tester, String label) {
    final row = optionRow(label);
    return find
        .descendant(of: row, matching: find.byIcon(Icons.radio_button_checked))
        .evaluate()
        .isNotEmpty;
  }

  testWidgets('shows the saved mode and announces it', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHost(tester, mode: ChatCompressionMode.smaz);

    expect(find.text(_l10n.chatCompression_label('SMAZ')), findsOneWidget);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(_l10n.chatCompression_label('SMAZ')),
      ),
      isSemantics(
        label: _l10n.chatCompression_label('SMAZ'),
        hint: _l10n.chatCompression_changeHint,
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSize(find.byType(ChatCompressionSelector)).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets('one sheet lists the three modes with their explanations', (
    tester,
  ) async {
    await pumpHost(tester);
    await openSheet(tester);

    expect(find.text(_l10n.chatCompression_title), findsOneWidget);
    expect(find.text(_l10n.chatCompression_off), findsOneWidget);
    expect(find.text(_l10n.chatCompression_smaz), findsOneWidget);
    expect(find.text(_l10n.chatCompression_cyr2lat), findsOneWidget);
    expect(find.text(_l10n.chatCompression_offDescription), findsOneWidget);
    expect(find.text(_l10n.chatCompression_smazDescription), findsOneWidget);
    expect(find.text(_l10n.chatCompression_cyr2latDescription), findsOneWidget);
    expect(isSelected(tester, _l10n.chatCompression_off), isTrue);
    expect(isSelected(tester, _l10n.chatCompression_smaz), isFalse);
    // No profile picker unless Cyr2Lat is chosen.
    expect(find.text(_l10n.chatCompression_profile), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('a choice shows only after it is saved, then the sheet closes', (
    tester,
  ) async {
    await pumpHost(tester);
    await openSheet(tester);

    await tester.tap(find.text(_l10n.chatCompression_smaz));
    await tester.pump();
    expect(modeCalls, [ChatCompressionMode.smaz]);
    // Still saving: old mode shown, options locked against rapid taps.
    expect(isSelected(tester, _l10n.chatCompression_off), isTrue);
    expect(
      tester.widget<ListTile>(optionRow(_l10n.chatCompression_cyr2lat)).enabled,
      isFalse,
    );
    await tester.tap(find.text(_l10n.chatCompression_cyr2lat));
    await tester.pump();
    expect(modeCalls, [ChatCompressionMode.smaz]);

    pending.single.complete();
    await tester.pumpAndSettle();
    expect(find.text(_l10n.chatCompression_title), findsNothing);
    expect(find.text(_l10n.chatCompression_label('SMAZ')), findsOneWidget);
  });

  testWidgets('Cyr2Lat keeps the sheet open with its profile picker', (
    tester,
  ) async {
    await pumpHost(tester);
    await openSheet(tester);

    await tester.tap(find.text(_l10n.chatCompression_cyr2lat));
    await tester.pump();
    pending.removeAt(0).complete();
    await tester.pumpAndSettle();

    expect(find.text(_l10n.chatCompression_title), findsOneWidget);
    expect(isSelected(tester, _l10n.chatCompression_cyr2lat), isTrue);
    expect(find.text(_l10n.chatCompression_profile), findsOneWidget);
    // No profile saved for the chat: the app-wide one is what sending uses.
    expect(find.text('Russian'), findsOneWidget);

    await tester.ensureVisible(find.text('Russian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Russian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serbian').last);
    await tester.pump();
    expect(profileCalls, ['sr']);
    pending.removeAt(0).complete();
    await tester.pumpAndSettle();
    expect(find.text('Serbian'), findsOneWidget);
    expect(find.text(_l10n.chatCompression_label('Cyr2Lat')), findsOneWidget);
  });

  testWidgets('a failed save keeps the saved mode and says so', (tester) async {
    await pumpHost(tester, mode: ChatCompressionMode.smaz);
    await openSheet(tester);

    await tester.tap(find.text(_l10n.chatCompression_cyr2lat));
    await tester.pump();
    pending.single.completeError(StateError('disk full'));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.chatCompression_saveFailed), findsOneWidget);
    expect(isSelected(tester, _l10n.chatCompression_smaz), isTrue);
    expect(isSelected(tester, _l10n.chatCompression_cyr2lat), isFalse);
    expect(
      tester.widget<ListTile>(optionRow(_l10n.chatCompression_off)).enabled,
      isTrue,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.chatCompression_label('SMAZ')), findsOneWidget);
  });

  testWidgets('a failed profile save shows the saved profile again', (
    tester,
  ) async {
    await pumpHost(tester, mode: ChatCompressionMode.cyr2lat, profileId: 'ru');
    await openSheet(tester);

    await tester.ensureVisible(find.text('Russian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Russian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serbian').last);
    await tester.pump();
    expect(profileCalls, ['sr']);
    pending.single.completeError(StateError('disk full'));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.chatCompression_saveFailed), findsOneWidget);
    expect(find.text('Russian'), findsOneWidget);
    expect(find.text('Serbian'), findsNothing);
  });

  testWidgets('disabled shows the saved mode, and the sheet says why and '
      'allows no change', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHost(tester, mode: ChatCompressionMode.smaz, enabled: false);

    final label = _l10n.chatCompression_label('SMAZ');
    expect(find.text(label), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(
      find.bySemanticsLabel('$label. ${_l10n.chatCompression_noStorageId}'),
      findsOneWidget,
    );

    await openSheet(tester);
    expect(find.text(_l10n.chatCompression_noStorageId), findsOneWidget);
    expect(isSelected(tester, _l10n.chatCompression_smaz), isTrue);
    for (final mode in [
      _l10n.chatCompression_off,
      _l10n.chatCompression_smaz,
      _l10n.chatCompression_cyr2lat,
    ]) {
      expect(tester.widget<ListTile>(optionRow(mode)).enabled, isFalse);
    }
    await tester.tap(find.text(_l10n.chatCompression_off), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(modeCalls, isEmpty);
    semantics.dispose();
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('fits a 320dp phone at ${scale}x text', (tester) async {
      await pumpHost(
        tester,
        mode: ChatCompressionMode.cyr2lat,
        enabled: true,
        size: const Size(320, 568),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      await openSheet(tester);
      expect(tester.takeException(), isNull);
      // The sheet scrolls to its last option and the profile picker.
      await tester.scrollUntilVisible(
        find.text(_l10n.chatCompression_profile),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
