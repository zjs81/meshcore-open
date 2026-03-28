import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  group('shouldIgnoreLateTcpConnectError', () {
    test('returns true for manual cancel during disconnecting state', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: true,
        state: MeshCoreConnectionState.disconnecting,
        activeTransport: MeshCoreTransportType.bluetooth,
        tcpManagerConnected: false,
      );

      expect(result, isTrue);
    });

    test(
      'returns true for manual cancel after reaching disconnected state',
      () {
        final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
          manualDisconnect: true,
          state: MeshCoreConnectionState.disconnected,
          activeTransport: MeshCoreTransportType.bluetooth,
          tcpManagerConnected: false,
        );

        expect(result, isTrue);
      },
    );

    test('returns false when not a manual disconnect', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: false,
        state: MeshCoreConnectionState.disconnecting,
        activeTransport: MeshCoreTransportType.bluetooth,
        tcpManagerConnected: false,
      );

      expect(result, isFalse);
    });

    test('returns false for connected state handshake failures', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: true,
        state: MeshCoreConnectionState.connected,
        activeTransport: MeshCoreTransportType.tcp,
        tcpManagerConnected: true,
      );

      expect(result, isFalse);
    });

    test('returns false when TCP is still active while disconnecting', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: true,
        state: MeshCoreConnectionState.disconnecting,
        activeTransport: MeshCoreTransportType.tcp,
        tcpManagerConnected: true,
      );

      expect(result, isFalse);
    });
  });

  group('shouldResetStateAfterTcpConnectAbort', () {
    test('returns true when TCP connect is still in connecting state', () {
      final result = MeshCoreConnector.shouldResetStateAfterTcpConnectAbort(
        state: MeshCoreConnectionState.connecting,
        activeTransport: MeshCoreTransportType.tcp,
      );

      expect(result, isTrue);
    });

    test('returns false when state is already disconnected', () {
      final result = MeshCoreConnector.shouldResetStateAfterTcpConnectAbort(
        state: MeshCoreConnectionState.disconnected,
        activeTransport: MeshCoreTransportType.tcp,
      );

      expect(result, isFalse);
    });

    test('returns false when transport switched away from TCP', () {
      final result = MeshCoreConnector.shouldResetStateAfterTcpConnectAbort(
        state: MeshCoreConnectionState.connecting,
        activeTransport: MeshCoreTransportType.bluetooth,
      );

      expect(result, isFalse);
    });
  });
}
