import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/usb_serial_frame_codec.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(
  bool Function() condition, {
  int seconds = 10,
  Duration pollInterval = const Duration(milliseconds: 25),
}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(pollInterval);
  }
}

/// A companion reachable over loopback TCP: each accepted socket gets its own
/// [ReviewRadio] answering the app's frames with the serial framing.
class _FakeTcpCompanion {
  late final ServerSocket _server;
  final List<Socket> _clients = [];
  final List<ReviewRadio> _radios = [];
  int accepted = 0;

  int get port => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((socket) {
      accepted += 1;
      _clients.add(socket);
      // Writes after the app hangs up fail with a broken pipe; that is
      // expected here and must not fail the test.
      var closed = false;
      unawaited(
        socket.done.catchError((_) {}).whenComplete(() => closed = true),
      );
      final radio = ReviewRadio(
        scheduledMessageInterval: const Duration(hours: 1),
        replyDelay: const Duration(hours: 1),
      );
      _radios.add(radio);
      radio.frames.listen((payload) {
        if (closed) return;
        final length = payload.length;
        try {
          socket.add([
            usbSerialRxFrameStart,
            length & 0xFF,
            (length >> 8) & 0xFF,
            ...payload,
          ]);
        } catch (_) {}
      });
      final decoder = UsbSerialFrameDecoder();
      socket.listen(
        (bytes) {
          for (final packet in decoder.ingest(Uint8List.fromList(bytes))) {
            radio.handle(packet.payload);
          }
        },
        onError: (_) {},
        onDone: () => closed = true,
        cancelOnError: true,
      );
    });
  }

  /// Simulates the link dying under the app (e.g. Wi-Fi power saving).
  void dropClients() {
    for (final socket in _clients) {
      socket.destroy();
    }
    _clients.clear();
  }

  Future<void> close() async {
    dropClients();
    for (final radio in _radios) {
      radio.dispose();
    }
    await _server.close();
  }
}

// NotificationService is a process-wide singleton whose reply stream can be
// listened to once, so every test shares one connector.
late MeshCoreConnector _connector;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    _connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    _connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    addTearDown(() {
      _connector.dispose();
      retryService.dispose();
    });
  });

  tearDown(() async {
    await _connector.disconnect();
  });

  test('a dropped TCP link reconnects to the same endpoint', () async {
    final companion = _FakeTcpCompanion();
    await companion.start();
    addTearDown(companion.close);

    await _connector.connectTcp(
      host: InternetAddress.loopbackIPv4.address,
      port: companion.port,
    );
    expect(_connector.isTcpTransportConnected, isTrue);
    expect(companion.accepted, 1);

    companion.dropClients();
    await _waitFor(
      () => _connector.state == MeshCoreConnectionState.disconnected,
    );
    expect(_connector.isAutoReconnectScheduled, isTrue);

    // Wait for the reconnect's handshake to finish (SELF_INFO), not just the
    // socket, so tearDown does not race a half-finished attempt.
    await _waitFor(
      () =>
          companion.accepted == 2 &&
          _connector.isTcpTransportConnected &&
          _connector.selfPublicKey != null,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      _connector.activeTcpEndpoint,
      '${InternetAddress.loopbackIPv4.address}:${companion.port}',
    );
  });

  test('a manual disconnect does not reconnect', () async {
    final companion = _FakeTcpCompanion();
    await companion.start();
    addTearDown(companion.close);

    await _connector.connectTcp(
      host: InternetAddress.loopbackIPv4.address,
      port: companion.port,
    );
    expect(_connector.isTcpTransportConnected, isTrue);

    await _connector.disconnect();
    expect(_connector.isAutoReconnectScheduled, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(companion.accepted, 1);
    expect(_connector.state, MeshCoreConnectionState.disconnected);
  });

  test('a first connect that fails does not start reconnecting', () async {
    final unused = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = unused.port;
    await unused.close();

    await expectLater(
      _connector.connectTcp(
        host: InternetAddress.loopbackIPv4.address,
        port: port,
      ),
      throwsA(anything),
    );
    expect(_connector.state, MeshCoreConnectionState.disconnected);
    expect(_connector.isAutoReconnectScheduled, isFalse);
  });

  test(
    'reconnect keeps retrying with backoff while the endpoint is down',
    () async {
      final companion = _FakeTcpCompanion();
      await companion.start();
      final port = companion.port;

      await _connector.connectTcp(
        host: InternetAddress.loopbackIPv4.address,
        port: port,
      );
      expect(_connector.isTcpTransportConnected, isTrue);

      // The companion goes away entirely: attempts fail and are rescheduled.
      await companion.close();
      await _waitFor(
        () =>
            _connector.state == MeshCoreConnectionState.disconnected &&
            _connector.isAutoReconnectScheduled,
      );
      await _waitFor(
        () => !_connector.isAutoReconnectScheduled,
        pollInterval: const Duration(milliseconds: 1),
      );
      // The timer firing proves an attempt started; wait for its failure to
      // finish and the next backoff to become active.
      await _waitFor(
        () =>
            _connector.state == MeshCoreConnectionState.disconnected &&
            _connector.isAutoReconnectScheduled,
      );
      expect(_connector.isTcpTransportConnected, isFalse);
    },
  );
}
