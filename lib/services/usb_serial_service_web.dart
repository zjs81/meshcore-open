import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'app_debug_log_service.dart';
import '../utils/usb_port_labels.dart';
import 'usb_serial_frame_codec.dart';

class UsbSerialService {
  UsbSerialService();

  static const Map<String, String> _knownUsbNames = <String, String>{
    '2886:1667': 'Seeed Wio Tracker L1',
  };
  static final Map<String, String> _deviceNamesByPortKey = <String, String>{};
  static final Map<String, String> _baseLabelsByPortKey = <String, String>{};
  static final Map<String, JSObject> _authorizedPortsByKey =
      <String, JSObject>{};
  static int _nextAuthorizedPortId = 1;

  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();
  final UsbSerialFrameDecoder _frameDecoder = UsbSerialFrameDecoder();

  UsbSerialStatus _status = UsbSerialStatus.disconnected;
  JSObject? _port;
  JSObject? _reader;
  JSObject? _writer;
  String? _connectedPortName;
  String? _connectedPortKey;
  String _requestPortLabel = 'Choose USB Device';
  String _fallbackDeviceName = 'Web Serial Device';
  AppDebugLogService? _debugLogService;

  UsbSerialStatus get status => _status;
  String? get activePortKey => _connectedPortKey;
  String? get activePortDisplayLabel => _connectedPortName ?? _connectedPortKey;
  Stream<Uint8List> get frameStream => _frameController.stream;
  bool get isConnected => _status == UsbSerialStatus.connected;

  JSObject get _navigator => JSObject.fromInteropObject(web.window.navigator);
  bool get _isSupported => _navigator.has('serial');
  JSObject? get _serial {
    if (!_isSupported) {
      return null;
    }
    final serial = _navigator['serial'];
    return serial == null ? null : serial as JSObject;
  }

  Future<List<String>> listPorts() async {
    if (!_isSupported) {
      return const <String>[];
    }

    _resetPortCache();
    final ports = await _getAuthorizedPorts();
    return <String>[_requestPortListEntry, ...ports.map(_listEntryForPort)];
  }

  Future<void> connect({
    required String portName,
    int baudRate = 115200,
  }) async {
    if (_status == UsbSerialStatus.connected ||
        _status == UsbSerialStatus.connecting) {
      throw StateError('USB serial transport is already active');
    }
    if (!_isSupported) {
      throw UnsupportedError('Web Serial is not supported by this browser.');
    }

    _status = UsbSerialStatus.connecting;
    _frameDecoder.reset();

    try {
      final requestedPortName = normalizeUsbPortName(portName);
      _debugLogService?.info(
        'Web connect: requested=$requestedPortName baud=$baudRate',
        tag: 'USB Serial',
      );
      final selectedPortKey = requestedPortName.startsWith('web:port:')
          ? requestedPortName
          : null;
      _port = _authorizedPortsByKey[requestedPortName];
      final authorizedPorts = await _getAuthorizedPorts();
      _debugLogService?.info(
        'Web connect: ${authorizedPorts.length} authorized port(s), cached=${_port != null}',
        tag: 'USB Serial',
      );
      _port ??= _selectPort(authorizedPorts, requestedPortName);

      _port ??= await _requestPort();
      if (_port == null) {
        throw StateError('No USB serial device selected');
      }

      _debugLogService?.info(
        'Web connect: opening port at $baudRate baud…',
        tag: 'USB Serial',
      );
      await _openPort(_port!, baudRate);
      _connectedPortKey = _cachePort(_port!, preferredKey: selectedPortKey);
      _connectedPortName = _displayLabelForPort(
        _port!,
        portKey: _connectedPortKey,
      );
      _writer = _getWriter(_port!);
      _reader = _getReader(_port!);
      _status = UsbSerialStatus.connected;
      unawaited(_pumpReads());

      _debugLogService?.info(
        'USB serial opened port=$_connectedPortName via Web Serial',
        tag: 'USB Serial',
      );
    } catch (error) {
      _debugLogService?.error('Web connect failed: $error', tag: 'USB Serial');
      await _cleanupFailedConnect();
      _status = UsbSerialStatus.disconnected;
      _connectedPortName = null;
      _connectedPortKey = null;
      rethrow;
    }
  }

  Future<void> writeRaw(Uint8List data) async {
    if (!isConnected || _writer == null) {
      throw StateError('USB serial port is not open');
    }
    final promise = _writer!.callMethod<JSPromise<JSAny?>>(
      'write'.toJS,
      data.toJS,
    );
    await promise.toDart;
  }

  Future<void> write(Uint8List data) async {
    if (!isConnected || _writer == null) {
      throw StateError('USB serial port is not open');
    }

    final packet = wrapUsbSerialTxFrame(data);
    _logFrameSummary('USB TX frame', data);

    final promise = _writer!.callMethod<JSPromise<JSAny?>>(
      'write'.toJS,
      packet.toJS,
    );
    await promise.toDart;
  }

  Future<void> disconnect() async {
    if (_status == UsbSerialStatus.disconnected) return;

    final portLabel = _connectedPortName ?? _connectedPortKey;
    _debugLogService?.info(
      'USB disconnect starting port=${portLabel ?? 'unknown'}',
      tag: 'USB Serial',
    );
    _status = UsbSerialStatus.disconnecting;
    final reader = _reader;
    final writer = _writer;
    final port = _port;

    _reader = null;
    _writer = null;
    _port = null;
    _connectedPortName = null;
    _connectedPortKey = null;
    _frameDecoder.reset();

    if (reader != null) {
      try {
        await reader.callMethod<JSPromise<JSAny?>>('cancel'.toJS).toDart;
      } catch (_) {
        // Ignore errors while closing.
      }
      _releaseLock(reader);
    }

    if (writer != null) {
      _releaseLock(writer);
    }

    if (port != null) {
      try {
        await port.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
      } catch (_) {
        // Ignore errors while closing.
      }
    }

    _status = UsbSerialStatus.disconnected;
    _debugLogService?.info(
      'USB disconnect complete port=${portLabel ?? 'unknown'}',
      tag: 'USB Serial',
    );
  }

  void updateConnectedLabel(String label) {
    final trimmed = label.trim();
    final portKey = _connectedPortKey;
    if (trimmed.isEmpty || portKey == null) {
      return;
    }
    _deviceNamesByPortKey[portKey] = trimmed;
    _connectedPortName = _buildDisplayLabel(portKey);
  }

  void setRequestPortLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _requestPortLabel = trimmed;
  }

  void setFallbackDeviceName(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _fallbackDeviceName = trimmed;
  }

  void setDebugLogService(AppDebugLogService? service) {
    _debugLogService = service;
  }

  void dispose() {
    unawaited(disconnect().whenComplete(_closeFrameController));
  }

  Future<List<JSObject>> _getAuthorizedPorts() async {
    final serial = _serial;
    if (serial == null) {
      return const <JSObject>[];
    }
    final result = await serial
        .callMethod<JSPromise<JSAny?>>('getPorts'.toJS)
        .toDart;
    return _toObjectList(result);
  }

  Future<JSObject?> _requestPort() async {
    final serial = _serial;
    if (serial == null) {
      return null;
    }
    final result = await serial
        .callMethod<JSPromise<JSAny?>>('requestPort'.toJS)
        .toDart;
    return result == null ? null : result as JSObject;
  }

  JSObject? _selectPort(List<JSObject> ports, String requestedPortName) {
    if (ports.isEmpty) {
      return null;
    }
    if (requestedPortName.isEmpty || requestedPortName == _requestPortKey) {
      return ports.first;
    }
    if (requestedPortName.startsWith('web:port:')) {
      return null;
    }
    for (final port in ports) {
      final description = _describePort(port);
      if (description == requestedPortName) {
        return port;
      }
    }
    return null;
  }

  Future<void> _openPort(JSObject port, int baudRate) async {
    final options = JSObject()
      ..['baudRate'] = baudRate.toJS
      ..['flowControl'] = 'none'.toJS;
    await port.callMethod<JSPromise<JSAny?>>('open'.toJS, options).toDart;

    // Prevent ESP32 USB-CDC reset: hold DTR=true, RTS=false after open.
    try {
      final signals = JSObject()
        ..['dataTerminalReady'] = true.toJS
        ..['requestToSend'] = false.toJS;
      await port
          .callMethod<JSPromise<JSAny?>>('setSignals'.toJS, signals)
          .toDart;
    } catch (_) {
      // setSignals may not be supported on all browsers/devices.
    }
  }

  Future<void> _cleanupFailedConnect() async {
    final reader = _reader;
    final writer = _writer;
    final port = _port;

    _reader = null;
    _writer = null;
    _port = null;

    if (reader != null) {
      try {
        await reader.callMethod<JSPromise<JSAny?>>('cancel'.toJS).toDart;
      } catch (_) {
        // Ignore cleanup errors after a failed connect.
      }
      _releaseLock(reader);
    }

    if (writer != null) {
      _releaseLock(writer);
    }

    if (port != null) {
      try {
        await port.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
      } catch (_) {
        // Ignore cleanup errors after a failed connect.
      }
    }
  }

  JSObject? _getReader(JSObject port) {
    final readable = port.getProperty<JSAny?>('readable'.toJS);
    if (readable == null) {
      throw StateError('Web Serial port is not readable');
    }
    final readableObject = readable as JSObject;
    return readableObject.callMethod<JSAny?>('getReader'.toJS) as JSObject;
  }

  JSObject? _getWriter(JSObject port) {
    final writable = port.getProperty<JSAny?>('writable'.toJS);
    if (writable == null) {
      throw StateError('Web Serial port is not writable');
    }
    final writableObject = writable as JSObject;
    return writableObject.callMethod<JSAny?>('getWriter'.toJS) as JSObject;
  }

  Future<void> _pumpReads() async {
    final reader = _reader;
    if (reader == null) {
      _debugLogService?.warn('_pumpReads: reader is null', tag: 'USB Serial');
      return;
    }

    _debugLogService?.info('_pumpReads: started', tag: 'USB Serial');
    try {
      while (_status == UsbSerialStatus.connected &&
          identical(reader, _reader)) {
        final result = await reader
            .callMethod<JSPromise<JSAny?>>('read'.toJS)
            .toDart;
        if (result == null) {
          _debugLogService?.warn('_pumpReads: null result', tag: 'USB Serial');
          break;
        }
        final resultObject = result as JSObject;

        final doneValue = resultObject.getProperty<JSAny?>('done'.toJS);
        final done = doneValue != null && doneValue.dartify() == true;
        if (done) {
          _debugLogService?.info('_pumpReads: done=true', tag: 'USB Serial');
          break;
        }

        final value = resultObject.getProperty<JSAny?>('value'.toJS);
        final bytes = _coerceBytes(value);
        if (bytes != null && bytes.isNotEmpty) {
          _debugLogService?.info(
            'USB RX raw: ${bytes.length} byte(s)',
            tag: 'USB Serial',
          );
          _ingestRawBytes(bytes);
        }
      }
    } catch (error, stackTrace) {
      _debugLogService?.error('_pumpReads error: $error', tag: 'USB Serial');
      if (_status == UsbSerialStatus.connected) {
        _addFrameError(error, stackTrace);
      }
    } finally {
      _debugLogService?.info('_pumpReads: ended', tag: 'USB Serial');
      _releaseLock(reader);
      if (_status == UsbSerialStatus.connected && identical(reader, _reader)) {
        _addFrameError(StateError('USB serial connection closed'));
      }
    }
  }

  Uint8List? _coerceBytes(JSAny? value) {
    if (value == null) return null;
    try {
      return (value as JSUint8Array).toDart;
    } catch (_) {
      // Fall back to array-like coercion below.
    }

    final object = value as JSObject;
    if (object.has('length')) {
      final lengthValue = object.getProperty<JSAny?>('length'.toJS)?.dartify();
      if (lengthValue is num) {
        final length = lengthValue.toInt();
        final bytes = Uint8List(length);
        for (var i = 0; i < length; i++) {
          final item = object.getProperty<JSAny?>(i.toString().toJS)?.dartify();
          if (item is num) {
            bytes[i] = item.toInt();
          }
        }
        return bytes;
      }
    }

    return null;
  }

  List<JSObject> _toObjectList(JSAny? value) {
    if (value == null) {
      return const <JSObject>[];
    }
    final object = value as JSObject;
    if (!object.has('length')) {
      return const <JSObject>[];
    }

    final lengthValue = object.getProperty<JSAny?>('length'.toJS)?.dartify();
    if (lengthValue is! num) {
      return const <JSObject>[];
    }

    final length = lengthValue.toInt();
    final items = <JSObject>[];
    for (var i = 0; i < length; i++) {
      final item = object.getProperty<JSAny?>(i.toString().toJS);
      if (item != null) {
        items.add(item as JSObject);
      }
    }
    return items;
  }

  String _describePort(JSObject port) {
    final info = _portInfo(port);
    if (info == null) {
      return _requestPortLabel;
    }

    final vendorId = info.usbVendorId;
    final productId = info.usbProductId;
    final hasVendor = vendorId != null;
    final hasProduct = productId != null;

    return describeWebUsbPort(
      vendorId: hasVendor ? vendorId : null,
      productId: hasProduct ? productId : null,
      requestPortLabel: _requestPortLabel,
      fallbackDeviceName: _fallbackDeviceName,
      knownUsbNames: _knownUsbNames,
    );
  }

  _WebPortInfo? _portInfo(JSObject port) {
    try {
      final info = port.callMethod<JSAny?>('getInfo'.toJS);
      if (info == null) {
        return null;
      }
      final infoObject = info as JSObject;

      final vendorId = infoObject
          .getProperty<JSAny?>('usbVendorId'.toJS)
          ?.dartify();
      final productId = infoObject
          .getProperty<JSAny?>('usbProductId'.toJS)
          ?.dartify();
      return _WebPortInfo(
        usbVendorId: vendorId is num ? vendorId.toInt() : null,
        usbProductId: productId is num ? productId.toInt() : null,
      );
    } catch (_) {
      return null;
    }
  }

  String _portKeyFor(JSObject port) {
    return _cachePort(port);
  }

  String _cachePort(JSObject port, {String? preferredKey}) {
    final portKey = preferredKey ?? 'web:port:${_nextAuthorizedPortId++}';
    _baseLabelsByPortKey[portKey] = _describePort(port);
    _authorizedPortsByKey[portKey] = port;
    return portKey;
  }

  String _displayLabelForPort(JSObject port, {String? portKey}) =>
      _buildDisplayLabel(portKey ?? _portKeyFor(port));

  String _buildDisplayLabel(String portKey) {
    return buildUsbDisplayLabel(
      basePortLabel: _baseLabelsByPortKey[portKey] ?? portKey,
      deviceName: _deviceNamesByPortKey[portKey],
    );
  }

  String _listEntryForPort(JSObject port) {
    final portKey = _portKeyFor(port);
    return '$portKey - ${_displayLabelForPort(port, portKey: portKey)}';
  }

  String get _requestPortKey => 'web:request';

  String get _requestPortListEntry => '$_requestPortKey - $_requestPortLabel';

  void _resetPortCache() {
    _authorizedPortsByKey.clear();
    _baseLabelsByPortKey.clear();
    _deviceNamesByPortKey.clear();
    _nextAuthorizedPortId = 1;
  }

  void _releaseLock(JSObject resource) {
    try {
      resource.callMethod<JSAny?>('releaseLock'.toJS);
    } catch (_) {
      // Ignore lock release failures.
    }
  }

  void _ingestRawBytes(Uint8List bytes) {
    for (final packet in _frameDecoder.ingest(bytes)) {
      if (!packet.isRxFrame) {
        _debugLogService?.info(
          'USB ignored packet start=0x${packet.frameStart.toRadixString(16).padLeft(2, '0')} len=${packet.payload.length}',
          tag: 'USB Serial',
        );
        continue;
      }
      _addFrame(packet.payload);
    }
  }

  void _addFrame(Uint8List payload) {
    if (_frameController.isClosed) {
      return;
    }
    _frameController.add(payload);
  }

  void _addFrameError(Object error, [StackTrace? stackTrace]) {
    if (_frameController.isClosed) {
      return;
    }
    _frameController.addError(error, stackTrace);
  }

  Future<void> _closeFrameController() async {
    if (_frameController.isClosed) {
      return;
    }
    await _frameController.close();
  }

  void _logFrameSummary(String prefix, Uint8List bytes) {
    if (bytes.isEmpty) {
      _debugLogService?.info('$prefix len=0', tag: 'USB Serial');
      return;
    }
    _debugLogService?.info(
      '$prefix code=${bytes[0]} len=${bytes.length}',
      tag: 'USB Serial',
    );
  }
}

enum UsbSerialStatus { disconnected, connecting, connected, disconnecting }

final class _WebPortInfo {
  const _WebPortInfo({required this.usbVendorId, required this.usbProductId});

  final int? usbVendorId;
  final int? usbProductId;
}
