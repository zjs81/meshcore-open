import 'dart:async';
import 'dart:io';

import 'package:flserial/flserial.dart';
import 'package:flserial/flserial_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_debug_log_service.dart';
import '../utils/macos_usb_device_names.dart';
import '../utils/platform_info.dart';
import '../utils/usb_port_labels.dart';
import 'usb_serial_frame_codec.dart';

/// Wraps the native flserial plugin to expose a stream of raw bytes for the
/// MeshCore connector to consume.
class UsbSerialService {
  UsbSerialService();

  static const MethodChannel _androidMethodChannel = MethodChannel(
    'meshcore_open/android_usb_serial',
  );
  static const EventChannel _androidEventChannel = EventChannel(
    'meshcore_open/android_usb_serial_events',
  );
  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();
  final UsbSerialFrameDecoder _frameDecoder = UsbSerialFrameDecoder();
  StreamSubscription<dynamic>? _androidDataSubscription;
  StreamSubscription<FlSerialEventArgs>? _dataSubscription;
  UsbSerialStatus _status = UsbSerialStatus.disconnected;
  String? _connectedPortKey;
  String? _connectedPortLabel;
  FlSerial? _serial;
  AppDebugLogService? _debugLogService;

  UsbSerialStatus get status => _status;
  String? get activePortKey => _connectedPortKey;
  String? get activePortDisplayLabel =>
      _connectedPortLabel ?? _connectedPortKey;
  Stream<Uint8List> get frameStream => _frameController.stream;
  bool get _useAndroidUsbHost =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _useDesktopFlSerial =>
      PlatformInfo.isWindows || PlatformInfo.isLinux || PlatformInfo.isMacOS;
  bool get _isSupportedPlatform => _useAndroidUsbHost || _useDesktopFlSerial;
  // Always-fresh: do NOT use ??= here – a cached FlSerial retains stale
  // native handle state (flh) from a prior failed open, causing subsequent
  // open attempts to fail with "port not exist" even when the device is present.
  FlSerial _freshSerial() => FlSerial();

  bool get isConnected {
    if (!_isSupportedPlatform) {
      return false;
    }
    // Trust _status as the authoritative connection state. Polling
    // _serial?.isOpen() via the native FL_CTRL_IS_PORT_OPEN query is
    // unreliable during the brief USB re-enumeration window that many
    // microcontrollers (e.g. NRF52) trigger in response to DTR assertion.
    // Actual port drops are handled by the onDone / onError callbacks on the
    // serial data stream subscription, which update _status correctly.
    return _status == UsbSerialStatus.connected;
  }

  Future<List<String>> listPorts() async {
    if (!_isSupportedPlatform) {
      return const <String>[];
    }
    if (_useAndroidUsbHost) {
      final ports = await _androidMethodChannel.invokeListMethod<String>(
        'listPorts',
      );
      return ports ?? <String>[];
    }
    final rawPorts = FlSerial.listPorts();
    // On macOS, flserial's native device-name lookup is broken on macOS
    // 10.15+ because the IOKit class name changed from IOUSBDevice to
    // IOUSBHostDevice. We resolve names ourselves via ioreg and rewrite any
    // "port - n/a" entries with the real product name.
    if (Platform.isMacOS && rawPorts.isNotEmpty) {
      return _annotateMacOsPorts(rawPorts);
    }
    return Future.value(rawPorts);
  }

  /// Rewrites the flserial port list on macOS by substituting real USB device
  /// names (obtained via [ioreg]) for the "n/a" placeholders that flserial
  /// returns when it can't find the deprecated IOUSBDevice parent.
  Future<List<String>> _annotateMacOsPorts(List<String> rawPorts) async {
    final deviceNames = await queryMacOsUsbDeviceNames();
    if (deviceNames.isEmpty) return rawPorts;
    return rawPorts.map((entry) {
      // entry format from fl_ports: "port - description - hardware_id"
      final port = normalizeUsbPortName(entry); // e.g. /dev/cu.usbmodem1101
      final knownName = deviceNames[port]; // e.g. "Nordic NRF52 DK"
      if (knownName == null) return entry; // non-USB port, keep as-is
      // Replace description field only; preserve hardware_id for device
      // identity (used by normalizeUsbPortName).
      final segments = entry.split(' - ');
      final hardwareId = segments.length >= 3 ? segments.last : 'n/a';
      return '$port - $knownName - $hardwareId';
    }).toList();
  }

  void setDebugLogService(AppDebugLogService? service) {
    _debugLogService = service;
  }

  Future<void> connect({
    required String portName,
    int baudRate = 115200,
  }) async {
    if (_status == UsbSerialStatus.connected ||
        _status == UsbSerialStatus.connecting) {
      throw StateError('USB serial transport is already active');
    }
    if (!_isSupportedPlatform) {
      throw UnsupportedError('USB serial is not supported on this platform.');
    }

    _status = UsbSerialStatus.connecting;
    var normalizedPortName = normalizeUsbPortName(portName);
    _frameDecoder.reset();

    if (_useAndroidUsbHost) {
      try {
        await _androidMethodChannel.invokeMethod<void>('connect', {
          'portName': normalizedPortName,
          'baudRate': baudRate,
        });
        _debugLogService?.info(
          'USB serial opened port=$normalizedPortName on Android via USB host bridge',
          tag: 'USB Serial',
        );
      } on PlatformException catch (error) {
        _status = UsbSerialStatus.disconnected;
        final msg = error.message ?? error.code;
        _debugLogService?.error(
          'Android connect failed: $msg',
          tag: 'USB Serial',
        );
        rethrow;
      }
    } else {
      // ── Hot-restart guard ─────────────────────────────────────────────────
      // On hot restart Dart tears down the isolate without calling dispose().
      // The NativeCallable registered by flserial's setCallback() is
      // isolate-local and gets freed when the isolate dies, but the native
      // SerialThread is still alive and will call it → crash.
      //
      // flserial uses process-global native state. Calling fl_free() kills ALL
      // SerialThreads for every open port across all Dart isolates (there is
      // only one in a Flutter app). Then fl_init() re-initialises the slot
      // table so subsequent fl_open() calls work normally.
      //
      // This must happen before we register any new NativeCallable, so it must
      // be the very first thing we do in the desktop branch.
      try {
        bindings.fl_free();
        bindings.fl_init(16);
      } catch (_) {}

      // On macOS, flserial lists both cu.* and tty.* device nodes.
      // When a cu.* open fails with FL_ERROR_PORT_NOT_EXIST, try the tty.*
      // variant as a fallback (and vice-versa) before giving up.
      final candidates = _buildPortCandidates(normalizedPortName);
      FlSerialException? lastError;
      bool opened = false;

      for (final candidate in candidates) {
        // Always create a fresh FlSerial instance — a cached instance retains
        // a stale flh handle from prior failed opens, which causes the native
        // fl_open() to mis-route the request and report port-not-exist even
        // when the device node is physically present.
        final serial = _freshSerial();
        serial.init();
        try {
          final openStatus = serial.openPort(candidate, baudRate);
          if (openStatus != FlOpenStatus.open) {
            final msg =
                'Failed to open USB port $candidate (status: $openStatus)';
            _debugLogService?.error(msg, tag: 'USB Serial');
            // Not a FlSerialException — treat as terminal failure
            _status = UsbSerialStatus.disconnected;
            throw StateError(msg);
          }
          serial.setByteSize8();
          serial.setBitParityNone();
          serial.setStopBits1();
          serial.setFlowControlNone();
          serial.setRTS(false);
          // Toggle DTR low→high so the device sees a fresh connection even
          // if the previous disconnect didn't cleanly signal DTR drop.
          serial.setDTR(false);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          serial.setDTR(true);
          _serial = serial;
          // Update the normalized port name to whichever candidate succeeded.
          normalizedPortName = candidate;
          _debugLogService?.info(
            'USB serial opened port=$candidate cts=${serial.getCTS()} dsr=${serial.getDSR()} dtr=true rts=false',
            tag: 'USB Serial',
          );
          opened = true;
          break;
        } on FlSerialException catch (error) {
          // The native fl_open() already called fl_close() on failure
          // internally, so no extra cleanup is needed here for this candidate.
          _debugLogService?.warn(
            'Failed to open $candidate: ${error.msg} (code ${error.error})',
            tag: 'USB Serial',
          );
          lastError = error;
          // Try next candidate
        } catch (error, stackTrace) {
          _status = UsbSerialStatus.disconnected;
          _debugLogService?.error(
            'Unexpected error opening $candidate: $error\n$stackTrace',
            tag: 'USB Serial',
          );
          rethrow;
        }
      }

      if (!opened) {
        _status = UsbSerialStatus.disconnected;
        final primary = candidates.first;
        final msg = lastError != null
            ? 'Failed to open USB port $primary: ${lastError.msg} (code ${lastError.error})'
            : 'Failed to open USB port $primary';
        _debugLogService?.error(msg, tag: 'USB Serial');
        throw StateError(msg);
      }
    }

    _connectedPortKey = normalizedPortName;
    _connectedPortLabel = normalizedPortName;
    if (_useAndroidUsbHost) {
      _androidDataSubscription = _androidEventChannel
          .receiveBroadcastStream()
          .listen(
            _handleAndroidData,
            onError: _handleSerialError,
            onDone: _handleSerialDone,
          );
    } else {
      _dataSubscription = _serial!.onSerialData.stream.listen(
        _handleSerialData,
        onError: _handleSerialError,
        onDone: _handleSerialDone,
      );
    }
    _status = UsbSerialStatus.connected;
  }

  Future<void> writeRaw(Uint8List data) async {
    if (!isConnected) {
      throw StateError('USB serial port is not open');
    }
    if (_useAndroidUsbHost) {
      try {
        await _androidMethodChannel.invokeMethod<void>('write', {'data': data});
      } on PlatformException catch (error) {
        throw StateError(error.message ?? error.code);
      }
    } else {
      _serial!.write(data);
    }
  }

  Future<void> write(Uint8List data) async {
    if (!isConnected) {
      throw StateError('USB serial port is not open');
    }
    final packet = wrapUsbSerialTxFrame(data);
    // _logFrameSummary('USB TX frame', data);
    if (_useAndroidUsbHost) {
      try {
        await _androidMethodChannel.invokeMethod<void>('write', {
          'data': packet,
        });
      } on PlatformException catch (error) {
        throw StateError(error.message ?? error.code);
      }
    } else {
      _serial!.write(packet);
    }
  }

  Future<void> disconnect() async {
    if (_status == UsbSerialStatus.disconnected) return;

    final portLabel = _connectedPortLabel ?? _connectedPortKey;
    _debugLogService?.info(
      'USB disconnect starting port=${portLabel ?? 'unknown'}',
      tag: 'USB Serial',
    );
    _status = UsbSerialStatus.disconnecting;
    _connectedPortKey = null;
    _connectedPortLabel = null;
    _frameDecoder.reset();

    if (_useAndroidUsbHost) {
      await _androidDataSubscription?.cancel();
      _androidDataSubscription = null;
      try {
        await _androidMethodChannel.invokeMethod<void>('disconnect');
      } catch (_) {
        // Ignore errors while closing.
      }
    } else {
      // IMPORTANT: Close and free the native port FIRST, before cancelling the
      // Dart subscription. The native SerialThread is blocked on a read(); once
      // closePort() is called it unblocks and the thread exits.  If we cancel
      // the Dart subscription first (freeing the FFI callback pointer) and the
      // thread fires one final callback before noticing the port is gone, Dart
      // crashes with "Callback invoked after it has been deleted".
      final serial = _serial;
      _serial = null;
      try {
        if (serial?.isOpen() == FlOpenStatus.open) {
          serial?.setDTR(false);
          serial?.closePort();
        }
      } catch (_) {
        // Ignore errors while closing.
      }
      // Note: we do NOT call free() here; that would globally reset native
      // state for all ports. The global reset is done in connect() instead,
      // before the next open, which is the safer place to do it.

      // Now it is safe to cancel the Dart subscription — the native thread has
      // already seen the port close and will not fire any more callbacks.
      await _dataSubscription?.cancel();
      _dataSubscription = null;
    }
    _status = UsbSerialStatus.disconnected;
    _debugLogService?.info(
      'USB disconnect complete port=${portLabel ?? 'unknown'}',
      tag: 'USB Serial',
    );
  }

  void setRequestPortLabel(String label) {
    // Native implementations do not use a synthetic chooser row.
  }

  void setFallbackDeviceName(String label) {
    // Native implementations use OS-provided device names.
  }

  void updateConnectedLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _connectedPortLabel = buildUsbDisplayLabel(
      basePortLabel: _connectedPortKey ?? trimmed,
      deviceName: trimmed,
    );
  }

  void dispose() {
    // Synchronously close the native port so the SerialThread exits before
    // the Dart isolate is torn down (e.g. on hot restart). The async
    // disconnect() path via unawaited() offers no ordering guarantee — the
    // isolate may die before the Future resolves, leaving the thread alive
    // with a dangling NativeCallable pointer.
    if (_useDesktopFlSerial) {
      final serial = _serial;
      try {
        if (serial?.isOpen() == FlOpenStatus.open) {
          serial?.setDTR(false);
          serial?.closePort(); // synchronous C call — kills the SerialThread
        }
      } catch (_) {}
    }
    // Kick off the full async teardown for anything else (subscription cancel,
    // stream controller close). These are best-effort at dispose time.
    unawaited(disconnect().whenComplete(_closeFrameController));
  }

  void _handleSerialData(FlSerialEventArgs event) {
    try {
      final bytes = event.serial.readList();
      if (bytes.isNotEmpty) {
        _ingestRawBytes(Uint8List.fromList(bytes));
      }
    } catch (error, stack) {
      _addFrameError(error, stack);
    }
  }

  void _handleAndroidData(dynamic data) {
    if (data is Uint8List) {
      _ingestRawBytes(data);
      return;
    }
    if (data is ByteData) {
      _ingestRawBytes(data.buffer.asUint8List());
      return;
    }
    _addFrameError(
      StateError('Unexpected Android USB event payload: ${data.runtimeType}'),
    );
  }

  void _handleSerialError(Object error, [StackTrace? stackTrace]) {
    _addFrameError(error, stackTrace);
  }

  void _handleSerialDone() {
    unawaited(disconnect());
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

  // void _logFrameSummary(String prefix, Uint8List bytes) {
  //   if (bytes.isEmpty) {
  //     _debugLogService?.info('$prefix len=0', tag: 'USB Serial');
  //     return;
  //   }
  //   _debugLogService?.info(
  //     '$prefix code=${bytes[0]} len=${bytes.length}',
  //     tag: 'USB Serial',
  //   );
  // }

  /// Returns an ordered list of port paths to try for [portName].
  ///
  /// On macOS, USB serial devices appear as both `/dev/cu.*` (call-out, the
  /// correct mode for outgoing serial connections) and `/dev/tty.*` (dial-in).
  /// `flserial` may list one variant while only the other is actually openable
  /// at a given moment. We prefer `cu.*` but automatically include the `tty.*`
  /// sibling as a fallback, and vice-versa.
  List<String> _buildPortCandidates(String normalizedPort) {
    if (!Platform.isMacOS) return [normalizedPort];
    const cuPrefix = '/dev/cu.';
    const ttyPrefix = '/dev/tty.';
    if (normalizedPort.startsWith(cuPrefix)) {
      final suffix = normalizedPort.substring(cuPrefix.length);
      return [normalizedPort, '$ttyPrefix$suffix'];
    }
    if (normalizedPort.startsWith(ttyPrefix)) {
      final suffix = normalizedPort.substring(ttyPrefix.length);
      return [normalizedPort, '$cuPrefix$suffix'];
    }
    return [normalizedPort];
  }
}

enum UsbSerialStatus { disconnected, connecting, connected, disconnecting }
