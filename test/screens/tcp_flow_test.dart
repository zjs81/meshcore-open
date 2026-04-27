import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/widgets/adaptive_app_bar_title.dart';

// ---------------------------------------------------------------------------
// Pure helpers extracted from TcpScreen logic so we can unit-test them
// without pumping the full screen widget tree.
// ---------------------------------------------------------------------------

/// Mirrors the validation in `_TcpScreenState._connectTcp`.
String? validateTcpInputs({required String host, required String portText}) {
  if (host.trim().isEmpty) return 'hostRequired';
  final parsed = int.tryParse(portText.trim());
  if (parsed == null || parsed < 1 || parsed > 65535) return 'portInvalid';
  return null;
}

/// Mirrors `_TcpScreenState._buildStatusBar` text selection.
String tcpStatusText({
  required MeshCoreConnectionState state,
  required MeshCoreTransportType transport,
  required bool isTcpConnected,
  String? activeTcpEndpoint,
  String connectingEndpoint = '',
  required String notConnected,
  required String Function(String) connectedTo,
  required String Function(String) connectingTo,
  required String disconnecting,
}) {
  if (isTcpConnected) return connectedTo(activeTcpEndpoint ?? 'TCP');
  if (state == MeshCoreConnectionState.connecting &&
      transport == MeshCoreTransportType.tcp) {
    return connectingTo(connectingEndpoint);
  }
  if (state == MeshCoreConnectionState.disconnecting &&
      transport == MeshCoreTransportType.tcp) {
    return disconnecting;
  }
  return notConnected;
}

/// Mirrors `_TcpScreenState._friendlyErrorMessage`.
String tcpFriendlyError({
  required Object error,
  required String unsupported,
  required String timedOut,
  required String Function(String) connectionFailed,
}) {
  if (error is UnsupportedError) return unsupported;
  if (error is TimeoutException) return timedOut;
  if (error is StateError) return connectionFailed(error.message);
  if (error is ArgumentError) {
    return connectionFailed(error.message?.toString() ?? error.toString());
  }
  return connectionFailed(error.toString());
}

/// Whether the connect button should be disabled.
bool isTcpConnectButtonDisabled({
  required MeshCoreConnectionState state,
  required MeshCoreTransportType transport,
}) {
  final isConnecting =
      state == MeshCoreConnectionState.connecting &&
      transport == MeshCoreTransportType.tcp;
  return isConnecting || state == MeshCoreConnectionState.scanning;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -- Validation -----------------------------------------------------------

  group('TCP input validation', () {
    test('empty host returns hostRequired', () {
      expect(validateTcpInputs(host: '', portText: '5000'), 'hostRequired');
    });

    test('whitespace-only host returns hostRequired', () {
      expect(validateTcpInputs(host: '   ', portText: '5000'), 'hostRequired');
    });

    test('non-numeric port returns portInvalid', () {
      expect(
        validateTcpInputs(host: '192.168.1.50', portText: 'abc'),
        'portInvalid',
      );
    });

    test('port 0 returns portInvalid', () {
      expect(
        validateTcpInputs(host: '192.168.1.50', portText: '0'),
        'portInvalid',
      );
    });

    test('port > 65535 returns portInvalid', () {
      expect(
        validateTcpInputs(host: '192.168.1.50', portText: '99999'),
        'portInvalid',
      );
    });

    test('valid host and port returns null', () {
      expect(validateTcpInputs(host: '192.168.1.50', portText: '5000'), isNull);
    });

    test('port 1 is valid (lower boundary)', () {
      expect(validateTcpInputs(host: 'h', portText: '1'), isNull);
    });

    test('port 65535 is valid (upper boundary)', () {
      expect(validateTcpInputs(host: 'h', portText: '65535'), isNull);
    });
  });

  // -- Status text ----------------------------------------------------------

  group('TCP status text', () {
    String status({
      MeshCoreConnectionState state = MeshCoreConnectionState.disconnected,
      MeshCoreTransportType transport = MeshCoreTransportType.tcp,
      bool isTcpConnected = false,
      String? activeTcpEndpoint,
      String connectingEndpoint = 'host:5000',
    }) => tcpStatusText(
      state: state,
      transport: transport,
      isTcpConnected: isTcpConnected,
      activeTcpEndpoint: activeTcpEndpoint,
      connectingEndpoint: connectingEndpoint,
      notConnected: 'NOT_CONNECTED',
      connectedTo: (ep) => 'CONNECTED:$ep',
      connectingTo: (ep) => 'CONNECTING:$ep',
      disconnecting: 'DISCONNECTING',
    );

    test('disconnected shows not-connected', () {
      expect(status(), 'NOT_CONNECTED');
    });

    test('connected with endpoint', () {
      expect(
        status(
          state: MeshCoreConnectionState.connected,
          isTcpConnected: true,
          activeTcpEndpoint: 'server.local:5000',
        ),
        'CONNECTED:server.local:5000',
      );
    });

    test('connected with null endpoint falls back to TCP', () {
      expect(
        status(state: MeshCoreConnectionState.connected, isTcpConnected: true),
        'CONNECTED:TCP',
      );
    });

    test('connecting over TCP shows connecting-to', () {
      expect(
        status(
          state: MeshCoreConnectionState.connecting,
          connectingEndpoint: '10.0.0.1:4000',
        ),
        'CONNECTING:10.0.0.1:4000',
      );
    });

    test('disconnecting over TCP shows disconnecting', () {
      expect(
        status(state: MeshCoreConnectionState.disconnecting),
        'DISCONNECTING',
      );
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
  });

  // -- Error mapping --------------------------------------------------------

  group('TCP friendly error messages', () {
    String error(Object e) => tcpFriendlyError(
      error: e,
      unsupported: 'UNSUPPORTED',
      timedOut: 'TIMED_OUT',
      connectionFailed: (msg) => 'FAILED:$msg',
    );

    test('UnsupportedError → unsupported', () {
      expect(error(UnsupportedError('nope')), 'UNSUPPORTED');
    });

    test('TimeoutException → timedOut', () {
      expect(error(TimeoutException('slow')), 'TIMED_OUT');
    });

    test('StateError → connectionFailed with message', () {
      expect(error(StateError('refused')), 'FAILED:refused');
    });

    test('ArgumentError → connectionFailed with message', () {
      expect(error(ArgumentError('bad host')), 'FAILED:bad host');
    });

    test('generic error → connectionFailed with toString', () {
      expect(error(Exception('boom')), 'FAILED:Exception: boom');
    });
  });

  // -- Button disabled state ------------------------------------------------

  group('TCP connect button disabled state', () {
    test('disabled while scanning', () {
      expect(
        isTcpConnectButtonDisabled(
          state: MeshCoreConnectionState.scanning,
          transport: MeshCoreTransportType.bluetooth,
        ),
        isTrue,
      );
    });

    test('disabled while connecting over TCP', () {
      expect(
        isTcpConnectButtonDisabled(
          state: MeshCoreConnectionState.connecting,
          transport: MeshCoreTransportType.tcp,
        ),
        isTrue,
      );
    });

    test('enabled while connecting over bluetooth (not TCP-specific)', () {
      expect(
        isTcpConnectButtonDisabled(
          state: MeshCoreConnectionState.connecting,
          transport: MeshCoreTransportType.bluetooth,
        ),
        isFalse,
      );
    });

    test('enabled when disconnected', () {
      expect(
        isTcpConnectButtonDisabled(
          state: MeshCoreConnectionState.disconnected,
          transport: MeshCoreTransportType.tcp,
        ),
        isFalse,
      );
    });
  });

  // -- Localized strings resolve correctly ----------------------------------

  testWidgets('English TCP localizations resolve without error', (
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

    expect(l10n.tcpScreenTitle, isNotEmpty);
    expect(l10n.tcpHostLabel, isNotEmpty);
    expect(l10n.tcpPortLabel, isNotEmpty);
    expect(l10n.tcpStatus_notConnected, isNotEmpty);
    expect(l10n.tcpErrorHostRequired, isNotEmpty);
    expect(l10n.tcpErrorPortInvalid, isNotEmpty);
    expect(l10n.tcpErrorUnsupported, isNotEmpty);
    expect(l10n.tcpErrorTimedOut, isNotEmpty);
    expect(l10n.tcpConnectionFailed('x'), contains('x'));
    expect(l10n.tcpStatus_connectingTo('host:5000'), contains('host:5000'));
    expect(l10n.scanner_connectedTo('device'), contains('device'));
  });

  // -- Isolated widget: AdaptiveAppBarTitle overflow ------------------------

  testWidgets('AdaptiveAppBarTitle does not overflow with long text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: AdaptiveAppBarTitle(
              'This is a very long title that would normally overflow',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('This is a very long title that would normally overflow'),
      findsOneWidget,
    );
  });

  // -- Isolated widget: status bar Row with FittedBox overflow --------------

  testWidgets('Status bar row with long text does not overflow at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const longText =
        'Connected to meshcore-room-server-very-long-hostname.local:5000';
    const statusColor = Colors.green;

    // Exact widget tree from _buildStatusBar in TcpScreen / UsbScreen.
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
}
