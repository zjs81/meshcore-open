import 'dart:typed_data';

import '../services/app_debug_log_service.dart';
import '../services/usb_serial_service.dart';

/// Manages USB serial transport for MeshCore devices.
///
/// Owns the [UsbSerialService] and USB-specific connection state.
/// The main [MeshCoreConnector] delegates all USB operations here.
class MeshCoreUsbManager {
  MeshCoreUsbManager();

  final UsbSerialService _service = UsbSerialService();
  AppDebugLogService? _debugLog;
  String? _activePortKey;
  String? _activePortLabel;

  // --- Getters ---
  String? get activePortKey => _activePortKey;
  String? get activePortDisplayLabel => _activePortLabel ?? _activePortKey;
  bool get isConnected => _service.isConnected;
  Stream<Uint8List> get frameStream => _service.frameStream;

  // --- Configuration ---
  Future<List<String>> listPorts() => _service.listPorts();

  void setRequestPortLabel(String label) => _service.setRequestPortLabel(label);

  void setFallbackDeviceName(String label) =>
      _service.setFallbackDeviceName(label);

  void setDebugLogService(AppDebugLogService? service) {
    _debugLog = service;
    _service.setDebugLogService(service);
  }

  // --- Connection lifecycle ---
  Future<void> connect({
    required String portName,
    int baudRate = 115200,
  }) async {
    _debugLog?.info(
      'UsbManager.connect: portName=$portName baud=$baudRate',
      tag: 'USB',
    );
    await _service.connect(portName: portName, baudRate: baudRate);
    _activePortKey = _service.activePortKey ?? portName;
    _activePortLabel = _service.activePortDisplayLabel ?? portName;
    _debugLog?.info(
      'UsbManager.connect: done, key=$_activePortKey label=$_activePortLabel',
      tag: 'USB',
    );
  }

  Future<void> disconnect() async {
    if (!_service.isConnected && _activePortKey == null) {
      return;
    }
    _debugLog?.info('UsbManager.disconnect', tag: 'USB');
    await _service.disconnect();
    _activePortKey = null;
    _activePortLabel = null;
  }

  Future<void> write(Uint8List data) => _service.write(data);

  Future<void> writeRaw(Uint8List data) => _service.writeRaw(data);

  // --- Label management ---
  void updateConnectedLabel(String selfName) {
    _service.updateConnectedLabel(selfName);
    _activePortLabel = _service.activePortDisplayLabel ?? _activePortLabel;
  }

  void dispose() {
    _service.dispose();
  }
}
