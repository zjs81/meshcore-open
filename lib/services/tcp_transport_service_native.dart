import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'app_debug_log_service.dart';
import 'usb_serial_frame_codec.dart';

class TcpTransportService {
  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();
  final UsbSerialFrameDecoder _frameDecoder = UsbSerialFrameDecoder();

  StreamSubscription<Uint8List>? _socketSubscription;
  Socket? _socket;
  AppDebugLogService? _debugLogService;
  TcpTransportStatus _status = TcpTransportStatus.disconnected;
  String? _activeHost;
  int? _activePort;
  Future<void> _pendingWrite = Future<void>.value();
  int _connectGeneration = 0;

  TcpTransportStatus get status => _status;
  Stream<Uint8List> get frameStream => _frameController.stream;
  bool get isConnected => _status == TcpTransportStatus.connected;
  String? get activeEndpoint => _activeHost == null || _activePort == null
      ? null
      : '$_activeHost:$_activePort';

  void setDebugLogService(AppDebugLogService? service) {
    _debugLogService = service;
  }

  Future<void> connect({
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_status == TcpTransportStatus.connected ||
        _status == TcpTransportStatus.connecting) {
      throw StateError('TCP transport is already active');
    }
    final trimmedHost = host.trim();
    if (trimmedHost.isEmpty) {
      throw ArgumentError.value(host, 'host', 'Host cannot be empty');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Port must be in 1..65535');
    }

    _status = TcpTransportStatus.connecting;
    final generation = ++_connectGeneration;
    _frameDecoder.reset();

    try {
      final socket = await Socket.connect(trimmedHost, port, timeout: timeout);
      if (generation != _connectGeneration ||
          _status != TcpTransportStatus.connecting) {
        try {
          await socket.close();
        } catch (_) {}
        try {
          socket.destroy();
        } catch (_) {}
        return;
      }
      socket.setOption(SocketOption.tcpNoDelay, true);
      _enableKeepAlive(socket);
      _socket = socket;
      _activeHost = trimmedHost;
      _activePort = port;
      _socketSubscription = socket.listen(
        _handleSocketData,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
      );
      _status = TcpTransportStatus.connected;
      _debugLogService?.info(
        'TCP transport opened endpoint=$activeEndpoint',
        tag: 'TCP',
      );
    } catch (error) {
      await _cleanupFailedConnect();
      _status = TcpTransportStatus.disconnected;
      rethrow;
    }
  }

  Future<void> write(Uint8List data) async {
    if (!isConnected || _socket == null) {
      throw StateError('TCP transport is not connected');
    }

    final packet = wrapUsbSerialTxFrame(data);
    _logFrameSummary('TCP TX frame', data);

    final writeTask = _pendingWrite.then((_) async {
      final socket = _socket;
      if (!isConnected || socket == null) {
        throw StateError('TCP transport is not connected');
      }
      socket.add(packet);
      await socket.flush();
    });

    _pendingWrite = writeTask.catchError((_) {});
    await writeTask;
  }

  Future<void> disconnect() async {
    _connectGeneration += 1;
    if (_status == TcpTransportStatus.disconnected) return;

    final endpoint = activeEndpoint;
    _status = TcpTransportStatus.disconnecting;
    _frameDecoder.reset();
    _activeHost = null;
    _activePort = null;

    final subscription = _socketSubscription;
    _socketSubscription = null;
    await subscription?.cancel();

    final socket = _socket;
    _socket = null;
    try {
      await socket?.close();
    } catch (_) {}
    try {
      socket?.destroy();
    } catch (_) {}

    _status = TcpTransportStatus.disconnected;
    _debugLogService?.info(
      'TCP transport closed endpoint=${endpoint ?? 'unknown'}',
      tag: 'TCP',
    );
  }

  void dispose() {
    unawaited(disconnect().whenComplete(_closeFrameController));
  }

  /// Seconds of silence before the first keepalive probe, the gap between
  /// probes, and how many unanswered probes drop the socket: a dead peer or
  /// a link killed by Wi-Fi power saving surfaces in about a minute instead
  /// of the OS default of two hours, so the connector can reconnect.
  static const int _keepAliveIdleSeconds = 30;
  static const int _keepAliveIntervalSeconds = 10;
  static const int _keepAliveProbeCount = 3;

  /// Dart's [Socket] has no keepalive option, so the raw socket options are
  /// set per platform. Every option is best-effort: a platform that rejects
  /// one keeps a working (if slower to notice a dead peer) connection.
  void _enableKeepAlive(Socket socket) {
    final int soKeepAlive;
    final int? tcpKeepIdle;
    final int? tcpKeepInterval;
    final int? tcpKeepCount;
    if (Platform.isLinux || Platform.isAndroid) {
      soKeepAlive = 9;
      tcpKeepIdle = 4;
      tcpKeepInterval = 5;
      tcpKeepCount = 6;
    } else if (Platform.isMacOS || Platform.isIOS) {
      soKeepAlive = 0x0008;
      tcpKeepIdle = 0x10; // TCP_KEEPALIVE
      tcpKeepInterval = 0x101;
      tcpKeepCount = 0x102;
    } else if (Platform.isWindows) {
      soKeepAlive = 0x0008;
      tcpKeepIdle = null;
      tcpKeepInterval = null;
      tcpKeepCount = null;
    } else {
      return;
    }

    void trySet(String name, RawSocketOption option) {
      try {
        socket.setRawOption(option);
      } catch (error) {
        _debugLogService?.warn('TCP $name not set: $error', tag: 'TCP');
      }
    }

    trySet(
      'SO_KEEPALIVE',
      RawSocketOption.fromBool(RawSocketOption.levelSocket, soKeepAlive, true),
    );
    if (tcpKeepIdle != null) {
      trySet(
        'keepalive idle',
        RawSocketOption.fromInt(
          RawSocketOption.levelTcp,
          tcpKeepIdle,
          _keepAliveIdleSeconds,
        ),
      );
    }
    if (tcpKeepInterval != null) {
      trySet(
        'keepalive interval',
        RawSocketOption.fromInt(
          RawSocketOption.levelTcp,
          tcpKeepInterval,
          _keepAliveIntervalSeconds,
        ),
      );
    }
    if (tcpKeepCount != null) {
      trySet(
        'keepalive count',
        RawSocketOption.fromInt(
          RawSocketOption.levelTcp,
          tcpKeepCount,
          _keepAliveProbeCount,
        ),
      );
    }
  }

  Future<void> _cleanupFailedConnect() async {
    final subscription = _socketSubscription;
    _socketSubscription = null;
    await subscription?.cancel();
    final socket = _socket;
    _socket = null;
    try {
      await socket?.close();
    } catch (_) {}
    try {
      socket?.destroy();
    } catch (_) {}
    _activeHost = null;
    _activePort = null;
    _frameDecoder.reset();
  }

  void _handleSocketData(Uint8List bytes) {
    for (final packet in _frameDecoder.ingest(bytes)) {
      if (!packet.isRxFrame) {
        _debugLogService?.info(
          'TCP ignored packet start=0x${packet.frameStart.toRadixString(16).padLeft(2, '0')} len=${packet.payload.length}',
          tag: 'TCP',
        );
        continue;
      }
      _addFrame(packet.payload);
    }
  }

  void _handleSocketError(Object error, [StackTrace? stackTrace]) {
    _addFrameError(error, stackTrace);
    unawaited(disconnect());
  }

  void _handleSocketDone() {
    if (_status == TcpTransportStatus.disconnecting ||
        _status == TcpTransportStatus.disconnected) {
      return;
    }
    _addFrameError(StateError('TCP socket closed by remote endpoint'));
    unawaited(disconnect());
  }

  void _addFrame(Uint8List payload) {
    if (_frameController.isClosed) return;
    _frameController.add(payload);
  }

  void _addFrameError(Object error, [StackTrace? stackTrace]) {
    if (_frameController.isClosed) return;
    _frameController.addError(error, stackTrace);
  }

  void _logFrameSummary(String prefix, Uint8List payload) {
    final code = payload.isNotEmpty ? payload.first : -1;
    _debugLogService?.info(
      '$prefix code=$code len=${payload.length}',
      tag: 'TCP',
    );
  }

  Future<void> _closeFrameController() async {
    if (_frameController.isClosed) return;
    await _frameController.close();
  }
}

enum TcpTransportStatus { disconnected, connecting, connected, disconnecting }
