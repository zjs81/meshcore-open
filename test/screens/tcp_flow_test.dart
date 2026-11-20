import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/screens/scanner_screen.dart';
import 'package:meshcore_open/screens/tcp_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

class _FakeMeshCoreConnector extends MeshCoreConnector {
  _FakeMeshCoreConnector();

  MeshCoreConnectionState initialState = MeshCoreConnectionState.disconnected;
  MeshCoreTransportType initialTransport = MeshCoreTransportType.bluetooth;
  String? initialEndpoint;
  int connectTcpCalls = 0;
  String? lastHost;
  int? lastPort;

  @override
  MeshCoreConnectionState get state => initialState;

  @override
  MeshCoreTransportType get activeTransport => initialTransport;

  @override
  bool get isTcpTransportConnected =>
      initialState == MeshCoreConnectionState.connected &&
      initialTransport == MeshCoreTransportType.tcp;

  @override
  String? get activeTcpEndpoint => initialEndpoint;

  @override
  Future<void> connectTcp({required String host, required int port}) async {
    connectTcpCalls += 1;
    lastHost = host;
    lastPort = port;
  }
}

Widget _buildTestApp({
  required MeshCoreConnector connector,
  required Widget child,
  Locale? locale,
  AppSettingsService? settings,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
      if (settings != null)
        ChangeNotifierProvider<AppSettingsService>.value(value: settings)
      else
        ChangeNotifierProvider<AppSettingsService>(
          create: (_) => AppSettingsService(),
        ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('TcpScreen uses localized TCP copy', (tester) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(
        connector: connector,
        child: const TcpScreen(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TcpScreen));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.tcpScreenTitle), findsOneWidget);
    expect(find.text(l10n.tcpHostLabel), findsOneWidget);
    expect(find.text(l10n.tcpPortLabel), findsOneWidget);
    expect(find.text(l10n.tcpStatus_notConnected), findsOneWidget);
  });

  testWidgets('TcpScreen validation errors are localized', (tester) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(
        connector: connector,
        child: const TcpScreen(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TcpScreen));
    final l10n = AppLocalizations.of(context);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byKey(const Key('tcp_connect_button')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tcpErrorHostRequired), findsOneWidget);
    expect(connector.connectTcpCalls, 0);

    await tester.enterText(find.byType(TextField).first, '192.168.1.50');
    await tester.enterText(find.byType(TextField).at(1), '99999');
    await tester.tap(find.byKey(const Key('tcp_connect_button')));
    await tester.pumpAndSettle();

    expect(connector.connectTcpCalls, 0);
  });

  testWidgets('TCP Bluetooth action returns to existing scanner route', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const ScannerScreen()),
    );
    await tester.pumpAndSettle();

    final scannerContext = tester.element(find.byType(ScannerScreen));
    final scannerL10n = AppLocalizations.of(scannerContext);
    await tester.tap(find.byTooltip(scannerL10n.connectionChoiceTcpLabel));
    await tester.pumpAndSettle();
    expect(find.byType(TcpScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Bluetooth'));
    await tester.pumpAndSettle();

    expect(find.byType(TcpScreen), findsNothing);
    expect(find.byType(ScannerScreen), findsOneWidget);
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigatorState.canPop(), isFalse);

    // ScannerScreen.dispose() schedules disconnect work that debounces notify.
    // Drain that debounce timer before test teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('TcpScreen disables connect button while connector is scanning', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector()
      ..initialState = MeshCoreConnectionState.scanning;

    await tester.pumpWidget(
      _buildTestApp(
        connector: connector,
        child: const TcpScreen(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('tcp_connect_button')),
    );
    expect(button.onPressed, isNull);
    expect(connector.connectTcpCalls, 0);
  });

  testWidgets('TcpScreen narrow width long status text does not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final connector = _FakeMeshCoreConnector()
      ..initialState = MeshCoreConnectionState.connected
      ..initialTransport = MeshCoreTransportType.tcp
      ..initialEndpoint = 'meshcore-room-server-very-long-hostname.local:5000';

    await tester.pumpWidget(
      _buildTestApp(
        connector: connector,
        child: const TcpScreen(),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(TcpScreen));
    final l10n = AppLocalizations.of(context);
    expect(
      find.text(l10n.scanner_connectedTo(connector.initialEndpoint!)),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets(
    'TcpScreen lists connection history and can reconnect or delete',
    (tester) async {
      PrefsManager.reset();
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
      final settings = AppSettingsService();
      await settings.addTcpConnectionHistory('room.local:5000');
      await settings.addTcpConnectionHistory('192.168.1.50:6000');

      final connector = _FakeMeshCoreConnector();
      await tester.pumpWidget(
        _buildTestApp(
          connector: connector,
          child: const TcpScreen(),
          locale: const Locale('en'),
          settings: settings,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('room.local:5000'), findsOneWidget);
      expect(find.text('192.168.1.50:6000'), findsOneWidget);

      // Tapping a saved endpoint fills the form and connects.
      await tester.tap(find.text('192.168.1.50:6000'));
      await tester.pumpAndSettle();
      expect(connector.connectTcpCalls, 1);
      expect(connector.lastHost, '192.168.1.50');
      expect(connector.lastPort, 6000);

      // The delete button removes only that entry. History is most recent
      // first, so the newest endpoint's button is the first one.
      final context = tester.element(find.byType(TcpScreen));
      final l10n = AppLocalizations.of(context);
      final deleteButtons = find.descendant(
        of: find.byType(MeshCard),
        matching: find.byTooltip(l10n.common_remove),
      );
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('192.168.1.50:6000'), findsNothing);
      expect(find.text('room.local:5000'), findsOneWidget);
      expect(settings.settings.tcpConnectionHistory, ['room.local:5000']);
    },
  );
}
