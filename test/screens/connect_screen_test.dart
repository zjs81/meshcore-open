import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/screens/connect_screen.dart';
import 'package:meshcore_open/screens/scanner_screen.dart';
import 'package:meshcore_open/screens/tcp_screen.dart';
import 'package:meshcore_open/screens/usb_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/utils/platform_info.dart';
import 'package:meshcore_open/widgets/connect_sheet.dart';

class _FakeMeshCoreConnector extends MeshCoreConnector {
  MeshCoreConnectionState fakeState = MeshCoreConnectionState.disconnected;
  LastRadio? fakeLastRadio;
  Object? listUsbPortsError;
  int stopScanCalls = 0;

  @override
  MeshCoreConnectionState get state => fakeState;

  @override
  LastRadio? get lastRadio => fakeLastRadio;

  @override
  Future<List<String>> listUsbPorts() async {
    if (listUsbPortsError != null) throw listUsbPortsError!;
    return <String>[];
  }

  @override
  Future<void> stopScan() async => stopScanCalls++;
}

LastRadio _lastRadio(String transport) => LastRadio(
  publicKeyHex: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4',
  name: 'Radio',
  transport: transport,
  savedAt: DateTime(2026),
);

Widget _buildTestApp(MeshCoreConnector connector, {Widget? home}) {
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
      home: home ?? const Scaffold(body: Center(child: ConnectButton())),
    ),
  );
}

Future<void> _openConnectScreen(WidgetTester tester) async {
  await tester.tap(find.byType(ConnectButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose a radio'));
  await tester.pumpAndSettle();
}

/// Runs a second of frames; a pulsing status chip never lets
/// pumpAndSettle finish.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Tears the tree down and drains the scanner's post-frame disconnect work.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 60));
}

void main() {
  testWidgets('a USB last radio opens the USB tab, and Bluetooth is a tap '
      'away', (tester) async {
    final connector = _FakeMeshCoreConnector()
      ..fakeLastRadio = _lastRadio(LastRadio.transportUsb);
    await tester.pumpWidget(_buildTestApp(connector));

    await _openConnectScreen(tester);
    expect(find.byType(UsbScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Bluetooth'));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerScreen), findsOneWidget);
    expect(find.byType(UsbScreen), findsNothing);
    await _unmount(tester);
  });

  testWidgets('a TCP last radio opens the TCP tab', (tester) async {
    final connector = _FakeMeshCoreConnector()
      ..fakeLastRadio = _lastRadio(LastRadio.transportTcp);
    await tester.pumpWidget(_buildTestApp(connector));

    await _openConnectScreen(tester);

    expect(find.byType(TcpScreen), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('tabs stay put while connecting', (tester) async {
    final connector = _FakeMeshCoreConnector()
      ..fakeState = MeshCoreConnectionState.connecting;
    await tester.pumpWidget(
      _buildTestApp(connector, home: const ConnectScreen()),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(Tab, 'TCP'), warnIfMissed: false);
    await _pumpFrames(tester);

    expect(find.byType(ScannerScreen), findsOneWidget);
    expect(find.byType(TcpScreen), findsNothing);
    await _unmount(tester);
  });

  testWidgets('leaving the Bluetooth tab stops a scan', (tester) async {
    final connector = _FakeMeshCoreConnector()
      ..fakeState = MeshCoreConnectionState.scanning;
    await tester.pumpWidget(
      _buildTestApp(connector, home: const ConnectScreen()),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(Tab, 'TCP'));
    await _pumpFrames(tester);

    expect(find.byType(TcpScreen), findsOneWidget);
    expect(connector.stopScanCalls, 1);
    await _unmount(tester);
  });

  testWidgets('a tab shows its snackbars inside the tab', (tester) async {
    final connector = _FakeMeshCoreConnector()
      ..listUsbPortsError = StateError('Failed to open the port');
    await tester.pumpWidget(
      _buildTestApp(
        connector,
        home: const ConnectScreen(initialTransport: MeshCoreTransportType.usb),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(UsbScreen),
        matching: find.byType(SnackBar),
      ),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('leaving the TCP tab closes the keyboard and the tab', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();
    await tester.pumpWidget(
      _buildTestApp(
        connector,
        home: const ConnectScreen(initialTransport: MeshCoreTransportType.tcp),
      ),
    );
    await _pumpFrames(tester);
    await tester.tap(find.byType(TextField).first);
    await _pumpFrames(tester);

    await tester.tap(find.widgetWithText(Tab, 'Bluetooth'));
    await _pumpFrames(tester);

    expect(find.byType(TcpScreen, skipOffstage: false), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    await _unmount(tester);
  });

  testWidgets('a landscape phone with the keyboard open keeps the TCP form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.reset);
    final connector = _FakeMeshCoreConnector();
    await tester.pumpWidget(
      _buildTestApp(
        connector,
        home: const ConnectScreen(initialTransport: MeshCoreTransportType.tcp),
      ),
    );
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TabBarView)).height,
      greaterThanOrEqualTo(80),
    );
    await _unmount(tester);
  });

  testWidgets('a landscape phone keeps the tabs while no keyboard is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _buildTestApp(_FakeMeshCoreConnector(), home: const ConnectScreen()),
    );
    await _pumpFrames(tester);

    expect(find.byType(TabBar), findsOneWidget);
    await _unmount(tester);
  });

  group('Need a new node? banner', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'node_banner_txt': 'v=1;on=1;url=https://example.com/node',
        'node_banner_expires_ms': DateTime(2100).millisecondsSinceEpoch,
      });
      PrefsManager.reset();
    });

    testWidgets('Close keeps it hidden on every tab until the page closes', (
      tester,
    ) async {
      await tester.runAsync(PrefsManager.initialize);
      final connector = _FakeMeshCoreConnector();
      await tester.pumpWidget(_buildTestApp(connector));

      await _openConnectScreen(tester);
      expect(find.text('Need a new node?'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Need a new node?'), findsNothing);

      final tabs = ['TCP', 'Bluetooth'];
      if (PlatformInfo.supportsUsbSerial) tabs.insert(0, 'USB');
      for (final tab in tabs) {
        await tester.tap(find.widgetWithText(Tab, tab));
        await tester.pumpAndSettle();
        expect(find.text('Need a new node?'), findsNothing);
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _openConnectScreen(tester);
      expect(find.text('Need a new node?'), findsOneWidget);
      await _unmount(tester);
    });
  });
}
