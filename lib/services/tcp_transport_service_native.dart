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
