import 'dart:typed_data';

import 'app_debug_log_service.dart';

class TcpTransportService {
  AppDebugLogService? _debugLogService;

  Stream<Uint8List> get frameStream => const Stream<Uint8List>.empty();
  bool get isConnected => false;
  String? get activeEndpoint => null;

  void setDebugLogService(AppDebugLogService? service) {
    _debugLogService = service;
  }

  Future<void> connect({
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _debugLogService?.warn(
      'TCP transport requested on web for $host:$port',
      tag: 'TCP',
    );
    throw UnsupportedError('TCP transport is not supported on web.');
  }

  Future<void> write(Uint8List data) async {
    throw UnsupportedError('TCP transport is not supported on web.');
  }

  Future<void> disconnect() async {}

  void dispose() {}
}
