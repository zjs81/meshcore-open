import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/screens/scanner_screen.dart';
import 'package:meshcore_open/screens/usb_screen.dart';
import 'package:meshcore_open/utils/platform_info.dart';

class _FakeMeshCoreConnector extends MeshCoreConnector {
  _FakeMeshCoreConnector({
    this.initialState = MeshCoreConnectionState.disconnected,
    List<String>? ports,
  }) : _ports = ports ?? <String>[];

  final MeshCoreConnectionState initialState;
  final List<String> _ports;

  String? requestPortLabel;
  String? fallbackDeviceName;
  int connectUsbCalls = 0;
  String? lastConnectPortName;
  String? fakeActiveUsbPort;
  String? fakeActiveUsbPortDisplayLabel;
  bool fakeUsbTransportConnected = false;
  Future<List<String>> Function()? listUsbPortsImpl;
  Future<void> Function({required String portName})? connectUsbImpl;

  @override
  MeshCoreConnectionState get state => initialState;

  @override
  MeshCoreTransportType get activeTransport => MeshCoreTransportType.usb;

  @override
  String? get activeUsbPort => fakeActiveUsbPort;

  @override
  String? get activeUsbPortDisplayLabel =>
      fakeActiveUsbPortDisplayLabel ?? fakeActiveUsbPort;

  @override
  bool get isUsbTransportConnected => fakeUsbTransportConnected;

  @override
  Future<List<String>> listUsbPorts() async {
    if (listUsbPortsImpl != null) {
      return listUsbPortsImpl!();
    }
    return List<String>.from(_ports);
  }

  @override
  Future<void> connectUsb({
    required String portName,
    int baudRate = 115200,
  }) async {
    if (connectUsbImpl != null) {
      return connectUsbImpl!(portName: portName);
    }
    connectUsbCalls += 1;
    lastConnectPortName = portName;
  }

  @override
  void setUsbRequestPortLabel(String label) {
    requestPortLabel = label;
  }

  @override
  void setUsbFallbackDeviceName(String label) {
    fallbackDeviceName = label;
  }
}

Widget _buildTestApp({
  required MeshCoreConnector connector,
  required Widget child,
}) {
  return ChangeNotifierProvider<MeshCoreConnector>.value(
    value: connector,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('UsbScreen passes localized chooser label to connector', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const UsbScreen()),
    );
    await tester.pumpAndSettle();

    expect(connector.requestPortLabel, 'Select a USB device');
  });

  testWidgets(
    'UsbScreen does not call connectUsb when connector is not disconnected',
    (tester) async {
      final connector = _FakeMeshCoreConnector(
        initialState: MeshCoreConnectionState.connected,
        ports: <String>['COM6 - USB Serial Device (COM6)'],
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: const UsbScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pump();

      expect(connector.connectUsbCalls, 0);

      // UsbScreen.dispose() schedules disconnect work that debounces notify.
      // Drain that debounce timer before test teardown.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 60));
    },
  );

  testWidgets('UsbScreen sends raw port name when tapping Connect', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector(
      ports: <String>['COM6 - USB Serial Device (COM6)'],
    );

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const UsbScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile).first);
    await tester.pump();

    expect(connector.connectUsbCalls, 1);
    expect(connector.lastConnectPortName, 'COM6');
  });

  testWidgets('ScannerScreen USB action reflects platform support', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const ScannerScreen()),
    );
    await tester.pumpAndSettle();

    if (PlatformInfo.supportsUsbSerial) {
      expect(find.widgetWithText(FloatingActionButton, 'USB'), findsOneWidget);
    } else {
      expect(find.widgetWithText(FloatingActionButton, 'USB'), findsNothing);
    }

    // ScannerScreen.dispose() schedules disconnect work that debounces notify.
    // Drain that debounce timer before test teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('ScannerScreen narrow width keeps actions without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const ScannerScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(ScannerScreen));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.scanner_scan), findsOneWidget);

    if (PlatformInfo.supportsUsbSerial) {
      expect(find.text(l10n.connectionChoiceUsbLabel), findsOneWidget);
    }
    if (!PlatformInfo.isWeb) {
      expect(find.text(l10n.connectionChoiceTcpLabel), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('UsbScreen narrow width long status text does not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final connector =
        _FakeMeshCoreConnector(initialState: MeshCoreConnectionState.connected)
          ..fakeUsbTransportConnected = true
          ..fakeActiveUsbPortDisplayLabel =
              '/dev/bus/usb/001/002 - KD3CGK mesh-utility.org very long label';

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const UsbScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(UsbScreen));
    final l10n = AppLocalizations.of(context);
    expect(
      find.text(
        l10n.scanner_connectedTo(connector.fakeActiveUsbPortDisplayLabel!),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 60));
  });

  group('Error Handling', () {
    testWidgets('shows error SnackBar when listing ports fails', (
      tester,
    ) async {
      final connector = _FakeMeshCoreConnector();
      connector.listUsbPortsImpl = () async {
        throw PlatformException(
          code: 'usb_permission_denied',
          message: 'Permission denied',
        );
      };

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: const UsbScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('USB permission was denied.'), findsOneWidget);
    });

    testWidgets('connection failure shows SnackBar error', (tester) async {
      final connector = _FakeMeshCoreConnector(ports: <String>['COM1']);
      var connectAttempted = false;
      connector.connectUsbImpl = ({required String portName}) async {
        connectAttempted = true;
        throw PlatformException(code: 'usb_busy', message: 'Device is busy');
      };

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: const UsbScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(connectAttempted, isTrue);
      expect(
        find.text('Another USB connection request is already in progress.'),
        findsOneWidget,
      );
    });
  });
}
