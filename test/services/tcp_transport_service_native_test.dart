import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/tcp_transport_service_native.dart';
import 'package:meshcore_open/services/usb_serial_frame_codec.dart';

final class _DelayedConnectOverrides extends IOOverrides {
  _DelayedConnectOverrides(this.delay);

  final Duration delay;

  @override
  Future<Socket> socketConnect(
    host,
    int port, {
    sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) async {
    await Future<void>.delayed(delay);
    return super.socketConnect(
      host,
      port,
      sourceAddress: sourceAddress,
      sourcePort: sourcePort,
      timeout: timeout,
    );
  }
}

final class _CapturingConnectOverrides extends IOOverrides {
  Socket? socket;

  @override
  Future<Socket> socketConnect(
    host,
    int port, {
    sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) async {
    final connected = await super.socketConnect(
      host,
      port,
      sourceAddress: sourceAddress,
      sourcePort: sourcePort,
      timeout: timeout,
    );
    socket = connected;
    return connected;
  }
}

int _readIntOption(Socket socket, int level, int option) {
  final value = socket.getRawOption(
    RawSocketOption(level, option, Uint8List(4)),
  );
  return ByteData.sublistView(value).getInt32(0, Endian.host);
}

void main() {
  test('connect enables TCP keepalive with short probe timings', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final overrides = _CapturingConnectOverrides();
    final service = TcpTransportService();
    try {
      await IOOverrides.runZoned(
        () => service.connect(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
        ),
        socketConnect: overrides.socketConnect,
      );
      final socket = overrides.socket!;
      // Linux values: SO_KEEPALIVE 9, TCP_KEEPIDLE 4, TCP_KEEPINTVL 5,
      // TCP_KEEPCNT 6.
      expect(_readIntOption(socket, RawSocketOption.levelSocket, 9), 1);
      expect(_readIntOption(socket, RawSocketOption.levelTcp, 4), 30);
      expect(_readIntOption(socket, RawSocketOption.levelTcp, 5), 10);
      expect(_readIntOption(socket, RawSocketOption.levelTcp, 6), 3);
    } finally {
      await service.disconnect();
      await server.close();
    }
  }, skip: Platform.isLinux ? false : 'Option numbers checked are Linux ones');

  test('connect/disconnect updates TCP transport state', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final service = TcpTransportService();

    try {
      await service.connect(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
      );

      expect(service.isConnected, isTrue);
      expect(
        service.activeEndpoint,
        '${InternetAddress.loopbackIPv4.address}:${server.port}',
      );

      await service.disconnect();

      expect(service.isConnected, isFalse);
      expect(service.activeEndpoint, isNull);
    } finally {
      await service.disconnect();
      await server.close();
    }
  });

  test('disconnect is safe when already disconnected', () async {
    final service = TcpTransportService();

    await service.disconnect();
    await service.disconnect();

    expect(service.isConnected, isFalse);
    expect(service.activeEndpoint, isNull);
  });

  test('emits only RX frames from socket stream', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final acceptedSocket = Completer<Socket>();
    final service = TcpTransportService();
    final receivedFrames = <Uint8List>[];

    final serverSub = server.listen((socket) {
      if (!acceptedSocket.isCompleted) {
        acceptedSocket.complete(socket);
      } else {
        socket.destroy();
      }
    });
    final frameSub = service.frameStream.listen(receivedFrames.add);

    try {
      await service.connect(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
      );

      final socket = await acceptedSocket.future.timeout(
        const Duration(seconds: 2),
      );

      socket.add(<int>[usbSerialTxFrameStart, 0x01, 0x00, 0x11]);
      socket.add(<int>[usbSerialRxFrameStart, 0x02, 0x00, 0x33, 0x44]);
      await socket.flush();

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(receivedFrames, hasLength(1));
      expect(receivedFrames.single, orderedEquals(<int>[0x33, 0x44]));
    } finally {
      await service.disconnect();
      await frameSub.cancel();
      await serverSub.cancel();
      await server.close();
    }
  });

  test(
    'disconnect during in-flight connect keeps transport disconnected',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final service = TcpTransportService();
      final host = InternetAddress.loopbackIPv4.address;

      try {
        await IOOverrides.runWithIOOverrides(() async {
          final connectFuture = service.connect(host: host, port: server.port);

          await Future<void>.delayed(const Duration(milliseconds: 10));
          await service.disconnect();
          await connectFuture;

          expect(service.isConnected, isFalse);
          expect(service.status, TcpTransportStatus.disconnected);
          expect(service.activeEndpoint, isNull);
        }, _DelayedConnectOverrides(const Duration(milliseconds: 120)));
      } finally {
        await service.disconnect();
        await server.close();
      }
    },
  );
}
