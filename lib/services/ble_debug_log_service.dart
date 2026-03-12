import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../connector/meshcore_protocol.dart';

class BleDebugLogEntry {
  final DateTime timestamp;
  final bool outgoing;
  final String description;
  final Uint8List payload;

  BleDebugLogEntry({
    required this.timestamp,
    required this.outgoing,
    required this.description,
    required this.payload,
  });

  String get hexPreview {
    const maxBytes = 64;
    final bytes = payload.length > maxBytes
        ? payload.sublist(0, maxBytes)
        : payload;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return payload.length > maxBytes ? '$hex …' : hex;
  }
}

class BleRawLogRxEntry {
  final DateTime timestamp;
  final Uint8List payload;

  BleRawLogRxEntry({required this.timestamp, required this.payload});

  String get hexPreview {
    const maxBytes = 64;
    final bytes = payload.length > maxBytes
        ? payload.sublist(0, maxBytes)
        : payload;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return payload.length > maxBytes ? '$hex …' : hex;
  }
}

class BleDebugLogService extends ChangeNotifier {
  static const int maxEntries = 500;
  final List<BleDebugLogEntry> _entries = [];
  final List<BleRawLogRxEntry> _rawLogRxEntries = [];
  bool _notifyScheduled = false;

  List<BleDebugLogEntry> get entries => List.unmodifiable(_entries);
  List<BleRawLogRxEntry> get rawLogRxEntries =>
      List.unmodifiable(_rawLogRxEntries);

  void logFrame(Uint8List frame, {required bool outgoing, String? note}) {
    if (frame.isEmpty) return;
    final code = frame[0];
    final description = _describeFrame(code, frame, outgoing, note);
    _entries.add(
      BleDebugLogEntry(
        timestamp: DateTime.now(),
        outgoing: outgoing,
        description: description,
        payload: Uint8List.fromList(frame),
      ),
    );

    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }

    if (!outgoing && code == pushCodeLogRxData && frame.length > 3) {
      _rawLogRxEntries.add(
        BleRawLogRxEntry(
          timestamp: DateTime.now(),
          payload: Uint8List.fromList(frame.sublist(3)),
        ),
      );
      if (_rawLogRxEntries.length > maxEntries) {
        _rawLogRxEntries.removeRange(0, _rawLogRxEntries.length - maxEntries);
      }
    }

    _notifyListenersSafely();
  }

  void clear() {
    _entries.clear();
    _rawLogRxEntries.clear();
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final canNotifyNow =
        phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;
    if (canNotifyNow) {
      notifyListeners();
      return;
    }

    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  String _describeFrame(
    int code,
    Uint8List frame,
    bool outgoing,
    String? note,
  ) {
    final label = _codeLabel(code, outgoing: outgoing);
    final prefix = outgoing ? 'TX' : 'RX';
    final extra = _frameDetail(code, frame);
    final noteText = note != null ? ' • $note' : '';
    return '$prefix $label$extra$noteText';
  }

  String _codeLabel(int code, {required bool outgoing}) {
    return describeProtocolCode(code, outgoing: outgoing);
  }

  String _frameDetail(int code, Uint8List frame) {
    switch (code) {
      case respCodeSent:
        if (frame.length >= 10) {
          final timeoutMs = readUint32LE(frame, 6);
          return ' • timeout=${timeoutMs}ms';
        }
        return '';
      case pushCodeSendConfirmed:
        if (frame.length >= 9) {
          final tripMs = readUint32LE(frame, 5);
          return ' • trip=${tripMs}ms';
        }
        return '';
      case pushCodeLoginSuccess:
        return ' • login ok';
      case pushCodeLoginFail:
        return ' • login fail';
      case respCodeBattAndStorage:
        if (frame.length >= 3) {
          final mv = readUint16LE(frame, 1);
          return ' • ${mv}mV';
        }
        return '';
      default:
        return '';
    }
  }
}
