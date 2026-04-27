import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/utils/usb_port_labels.dart';

// ---------------------------------------------------------------------------
// Pure helpers extracted from UsbScreen logic.
// ---------------------------------------------------------------------------

/// Mirrors `_UsbScreenState._buildStatusBar` text selection.
///
/// [isLoadingPorts] corresponds to the screen's `_isLoadingPorts` flag.
String usbStatusText({
  required bool isLoadingPorts,
  required bool isUsbTransportConnected,
  required MeshCoreConnectionState state,
  required MeshCoreTransportType transport,
  String? activeUsbPortDisplayLabel,
  // L10n strings passed directly so we don't need BuildContext.
  required String searching,
  required String Function(String) connectedTo,
  required String disconnecting,
  required String connecting,
  required String notConnected,
}) {
  if (isLoadingPorts) return searching;
  if (isUsbTransportConnected) {
    switch (state) {
      case MeshCoreConnectionState.connected:
        return connectedTo(activeUsbPortDisplayLabel ?? 'USB');
      case MeshCoreConnectionState.disconnecting:
        return disconnecting;
      default:
        return notConnected;
    }
  }
  if (state == MeshCoreConnectionState.connecting &&
      transport == MeshCoreTransportType.usb) {
    return connecting;
  }
  return notConnected;
}

/// Mirrors `_UsbScreenState._friendlyErrorMessage`.
///
/// Uses string keys instead of l10n objects so this is a pure function.
String usbFriendlyErrorKey(Object error) {
  if (error is PlatformException) {
    switch (error.code) {
      case 'usb_permission_denied':
        return 'permissionDenied';
      case 'usb_device_missing':
      case 'usb_device_detached':
        return 'deviceMissing';
      case 'usb_invalid_port':
        return 'invalidPort';
      case 'usb_busy':
        return 'busy';
      case 'usb_not_connected':
        return 'notConnected';
      case 'usb_open_failed':
      case 'usb_driver_missing':
        return 'openFailed';
      case 'usb_connect_failed':
        return 'connectFailed';
    }
  }
  if (error is UnsupportedError) return 'unsupported';
  if (error is StateError) {
    final msg = error.message;
    if (msg.contains('already active')) return 'alreadyActive';
    if (msg.contains('No USB serial device selected')) {
      return 'noDeviceSelected';
    }
    if (msg.contains('not open') || msg.contains('closed')) {
      return 'portClosed';
    }
    if (msg.contains('Timed out')) return 'connectTimedOut';
    if (msg.contains('Failed to open')) return 'openFailed';
  }
  if (error is TimeoutException) return 'connectTimedOut';
  return 'unknown';
}

/// Mirrors the guard in `_UsbScreenState._connectPort`:
/// returns true only when the connector is disconnected.
bool shouldAllowUsbConnect(MeshCoreConnectionState state) =>
    state == MeshCoreConnectionState.disconnected;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -- Port name helpers (normalizeUsbPortName / friendlyUsbPortName) -------

  group('USB port name parsing', () {
    test('normalizeUsbPortName extracts raw port before separator', () {
      expect(normalizeUsbPortName('COM6 - USB Serial Device (COM6)'), 'COM6');
    });

    test('normalizeUsbPortName returns input when no separator', () {
      expect(normalizeUsbPortName('/dev/ttyUSB0'), '/dev/ttyUSB0');
    });

    test('normalizeUsbPortName trims whitespace', () {
      expect(normalizeUsbPortName('  COM3  '), 'COM3');
    });

    test('friendlyUsbPortName extracts description field', () {
      expect(
        friendlyUsbPortName('COM6 - USB Serial Device (COM6) - HWID'),
        'USB Serial Device (COM6)',
      );
    });

    test(
      'friendlyUsbPortName falls back to raw name if description is n/a',
      () {
        expect(friendlyUsbPortName('COM6 - n/a'), 'COM6');
      },
    );

    test('friendlyUsbPortName falls back when only one part', () {
      expect(friendlyUsbPortName('/dev/ttyUSB0'), '/dev/ttyUSB0');
    });
  });

  // -- Connect guard --------------------------------------------------------

  group('USB connect guard', () {
    test('allows connect when disconnected', () {
      expect(
        shouldAllowUsbConnect(MeshCoreConnectionState.disconnected),
        isTrue,
      );
    });

    test('blocks connect when connected', () {
      expect(shouldAllowUsbConnect(MeshCoreConnectionState.connected), isFalse);
    });

    test('blocks connect when connecting', () {
      expect(
        shouldAllowUsbConnect(MeshCoreConnectionState.connecting),
        isFalse,
      );
    });

    test('blocks connect when scanning', () {
      expect(shouldAllowUsbConnect(MeshCoreConnectionState.scanning), isFalse);
    });

    test('blocks connect when disconnecting', () {
      expect(
        shouldAllowUsbConnect(MeshCoreConnectionState.disconnecting),
        isFalse,
      );
    });
  });

  // -- Status text ----------------------------------------------------------

  group('USB status text', () {
    String status({
      bool isLoadingPorts = false,
      bool isUsbTransportConnected = false,
      MeshCoreConnectionState state = MeshCoreConnectionState.disconnected,
      MeshCoreTransportType transport = MeshCoreTransportType.usb,
      String? activeUsbPortDisplayLabel,
    }) => usbStatusText(
      isLoadingPorts: isLoadingPorts,
      isUsbTransportConnected: isUsbTransportConnected,
      state: state,
      transport: transport,
      activeUsbPortDisplayLabel: activeUsbPortDisplayLabel,
      searching: 'SEARCHING',
      connectedTo: (label) => 'CONNECTED:$label',
      disconnecting: 'DISCONNECTING',
      connecting: 'CONNECTING',
      notConnected: 'NOT_CONNECTED',
    );

    test('loading ports shows searching', () {
      expect(status(isLoadingPorts: true), 'SEARCHING');
    });

    test('connected USB with label', () {
      expect(
        status(
          isUsbTransportConnected: true,
          state: MeshCoreConnectionState.connected,
          activeUsbPortDisplayLabel: 'COM6 - Device',
        ),
        'CONNECTED:COM6 - Device',
      );
    });

    test('connected USB with null label falls back to USB', () {
      expect(
        status(
          isUsbTransportConnected: true,
          state: MeshCoreConnectionState.connected,
        ),
        'CONNECTED:USB',
      );
    });

    test('USB transport connected but disconnecting', () {
      expect(
        status(
          isUsbTransportConnected: true,
          state: MeshCoreConnectionState.disconnecting,
        ),
        'DISCONNECTING',
      );
    });

    test('USB transport connected but scanning falls to default', () {
      expect(
        status(
          isUsbTransportConnected: true,
          state: MeshCoreConnectionState.scanning,
        ),
        'NOT_CONNECTED',
      );
    });

    test('connecting over USB shows connecting', () {
      expect(status(state: MeshCoreConnectionState.connecting), 'CONNECTING');
    });

    test('connecting over bluetooth falls through to not-connected', () {
      expect(
        status(
          state: MeshCoreConnectionState.connecting,
          transport: MeshCoreTransportType.bluetooth,
        ),
        'NOT_CONNECTED',
      );
    });

    test('disconnected shows not-connected', () {
      expect(status(), 'NOT_CONNECTED');
    });
  });

  // -- Error mapping --------------------------------------------------------

  group('USB friendly error mapping', () {
    test('PlatformException usb_permission_denied', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_permission_denied')),
        'permissionDenied',
      );
    });

    test('PlatformException usb_device_missing', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_device_missing')),
        'deviceMissing',
      );
    });

    test('PlatformException usb_device_detached', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_device_detached')),
        'deviceMissing',
      );
    });

    test('PlatformException usb_invalid_port', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_invalid_port')),
        'invalidPort',
      );
    });

    test('PlatformException usb_busy', () {
      expect(usbFriendlyErrorKey(PlatformException(code: 'usb_busy')), 'busy');
    });

    test('PlatformException usb_not_connected', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_not_connected')),
        'notConnected',
      );
    });

    test('PlatformException usb_open_failed', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_open_failed')),
        'openFailed',
      );
    });

    test('PlatformException usb_driver_missing', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_driver_missing')),
        'openFailed',
      );
    });

    test('PlatformException usb_connect_failed', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_connect_failed')),
        'connectFailed',
      );
    });

    test('PlatformException with unknown code falls through', () {
      expect(
        usbFriendlyErrorKey(PlatformException(code: 'usb_whatever')),
        'unknown',
      );
    });

    test('UnsupportedError → unsupported', () {
      expect(usbFriendlyErrorKey(UnsupportedError('nope')), 'unsupported');
    });

    test('StateError "already active" → alreadyActive', () {
      expect(
        usbFriendlyErrorKey(StateError('already active')),
        'alreadyActive',
      );
    });

    test('StateError "No USB serial device selected" → noDeviceSelected', () {
      expect(
        usbFriendlyErrorKey(StateError('No USB serial device selected')),
        'noDeviceSelected',
      );
    });

    test('StateError "not open" → portClosed', () {
      expect(usbFriendlyErrorKey(StateError('port not open')), 'portClosed');
    });

    test('StateError "closed" → portClosed', () {
      expect(
        usbFriendlyErrorKey(StateError('connection closed')),
        'portClosed',
      );
    });

    test('StateError "Timed out" → connectTimedOut', () {
      expect(
        usbFriendlyErrorKey(StateError('Timed out waiting')),
        'connectTimedOut',
      );
    });

    test('StateError "Failed to open" → openFailed', () {
      expect(
        usbFriendlyErrorKey(StateError('Failed to open device')),
        'openFailed',
      );
    });

    test('TimeoutException → connectTimedOut', () {
      expect(usbFriendlyErrorKey(TimeoutException('slow')), 'connectTimedOut');
    });

    test('generic error → unknown', () {
      expect(usbFriendlyErrorKey(Exception('boom')), 'unknown');
    });
  });

  // -- Localized strings resolve correctly ----------------------------------

  testWidgets('English USB localizations resolve without error', (
    tester,
  ) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(l10n.usbScreenTitle, isNotEmpty);
    expect(l10n.usbScreenStatus, 'Select a USB device');
    expect(l10n.usbStatus_notConnected, isNotEmpty);
    expect(l10n.usbStatus_connecting, isNotEmpty);
    expect(l10n.usbStatus_searching, isNotEmpty);
    expect(l10n.usbErrorPermissionDenied, isNotEmpty);
    expect(l10n.usbErrorDeviceMissing, isNotEmpty);
    expect(l10n.usbErrorInvalidPort, isNotEmpty);
    expect(l10n.usbErrorBusy, isNotEmpty);
    expect(l10n.usbErrorNotConnected, isNotEmpty);
    expect(l10n.usbErrorOpenFailed, isNotEmpty);
    expect(l10n.usbErrorConnectFailed, isNotEmpty);
    expect(l10n.usbErrorUnsupported, isNotEmpty);
    expect(l10n.usbErrorAlreadyActive, isNotEmpty);
    expect(l10n.usbErrorNoDeviceSelected, isNotEmpty);
    expect(l10n.usbErrorPortClosed, isNotEmpty);
    expect(l10n.usbErrorConnectTimedOut, isNotEmpty);
    expect(l10n.scanner_connectedTo('device'), contains('device'));
    expect(l10n.scanner_disconnecting, isNotEmpty);
  });

  // -- Isolated widget: status bar Row with FittedBox overflow --------------

  testWidgets('USB status bar with long text does not overflow at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const longText =
        'Connected to /dev/bus/usb/001/002 - KD3CGK mesh-utility.org very long label';
    const statusColor = Colors.green;

    // Exact widget tree from _buildStatusBar in UsbScreen.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: statusColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 12, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      longText,
                      style: const TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(longText), findsOneWidget);
  });

  // -- Isolated widget: bottom nav FittedBox overflow -----------------------

  testWidgets('Bottom nav row with multiple FABs does not overflow at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Mirrors the bottomNavigationBar structure from ScannerScreen / UsbScreen
    // with all possible buttons visible.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    onPressed: () {},
                    heroTag: 'usb',
                    icon: const Icon(Icons.usb),
                    label: const Text('USB'),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.extended(
                    onPressed: () {},
                    heroTag: 'tcp',
                    icon: const Icon(Icons.lan),
                    label: const Text('TCP'),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.extended(
                    onPressed: () {},
                    heroTag: 'ble',
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Scan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('USB'), findsOneWidget);
    expect(find.text('TCP'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  // -- describeWebUsbPort ---------------------------------------------------

  group('describeWebUsbPort', () {
    test('null vendor and product returns requestPortLabel', () {
      expect(
        describeWebUsbPort(vendorId: null, productId: null),
        'Choose USB Device',
      );
    });

    test('known VID:PID uses knownUsbNames', () {
      expect(
        describeWebUsbPort(
          vendorId: 0x1A86,
          productId: 0x7523,
          knownUsbNames: {'1a86:7523': 'CH340 Serial'},
        ),
        'CH340 Serial (VID:1A86 PID:7523)',
      );
    });

    test('unknown VID:PID uses fallback device name', () {
      expect(
        describeWebUsbPort(
          vendorId: 0x1234,
          productId: 0x5678,
          fallbackDeviceName: 'My Device',
        ),
        'My Device (VID:1234 PID:5678)',
      );
    });
  });

  // -- buildUsbDisplayLabel -------------------------------------------------

  group('buildUsbDisplayLabel', () {
    test('appends device name when present', () {
      expect(
        buildUsbDisplayLabel(
          basePortLabel: 'COM6',
          deviceName: 'MeshCore Node',
        ),
        'COM6 - MeshCore Node',
      );
    });

    test('returns base label when device name is null', () {
      expect(
        buildUsbDisplayLabel(basePortLabel: 'COM6', deviceName: null),
        'COM6',
      );
    });

    test('returns base label when device name is whitespace', () {
      expect(
        buildUsbDisplayLabel(basePortLabel: 'COM6', deviceName: '   '),
        'COM6',
      );
    });
  });
}
