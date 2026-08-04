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
    if (outgoing) {
      return _commandLabel(code) ?? 'CODE_$code';
    }

    final pushLabel = _pushLabel(code);
    if (pushLabel != null) return pushLabel;
    final responseLabel = _responseLabel(code);
    if (responseLabel != null) return responseLabel;
    return 'CODE_$code';
  }

  String? _commandLabel(int code) {
    switch (code) {
      case cmdAppStart:
        return 'CMD_APP_START';
      case cmdSendTxtMsg:
        return 'CMD_SEND_TXT_MSG';
      case cmdSendChannelTxtMsg:
        return 'CMD_SEND_CHANNEL_TXT_MSG';
      case cmdGetContacts:
        return 'CMD_GET_CONTACTS';
      case cmdGetDeviceTime:
        return 'CMD_GET_DEVICE_TIME';
      case cmdSetDeviceTime:
        return 'CMD_SET_DEVICE_TIME';
      case cmdSendSelfAdvert:
        return 'CMD_SEND_SELF_ADVERT';
      case cmdSetAdvertName:
        return 'CMD_SET_ADVERT_NAME';
      case cmdAddUpdateContact:
        return 'CMD_ADD_UPDATE_CONTACT';
      case cmdSyncNextMessage:
        return 'CMD_SYNC_NEXT_MESSAGE';
      case cmdSetRadioParams:
        return 'CMD_SET_RADIO_PARAMS';
      case cmdSetRadioTxPower:
        return 'CMD_SET_RADIO_TX_POWER';
      case cmdResetPath:
        return 'CMD_RESET_PATH';
      case cmdRemoveContact:
        return 'CMD_REMOVE_CONTACT';
      case cmdReboot:
        return 'CMD_REBOOT';
      case cmdGetBattAndStorage:
        return 'CMD_GET_BATT_AND_STORAGE';
      case cmdSendLogin:
        return 'CMD_SEND_LOGIN';
      case cmdGetChannel:
        return 'CMD_GET_CHANNEL';
      case cmdSetChannel:
        return 'CMD_SET_CHANNEL';
      case cmdSetCustomVar:
        return 'CMD_SET_CUSTOM_VAR';
      case cmdSendTracePath:
        return 'CMD_SEND_TRACE_PATH';
      case cmdSetFloodScope:
        return 'CMD_SET_FLOOD_SCOPE';
      default:
        return null;
    }
  }

  String? _responseLabel(int code) {
    switch (code) {
      case respCodeOk:
        return 'RESP_CODE_OK';
      case respCodeErr:
        return 'RESP_CODE_ERR';
      case respCodeContactsStart:
        return 'RESP_CODE_CONTACTS_START';
      case respCodeContact:
        return 'RESP_CODE_CONTACT';
      case respCodeEndOfContacts:
        return 'RESP_CODE_END_OF_CONTACTS';
      case respCodeSelfInfo:
        return 'RESP_CODE_SELF_INFO';
      case respCodeSent:
        return 'RESP_CODE_SENT';
      case respCodeContactMsgRecv:
        return 'RESP_CODE_CONTACT_MSG_RECV';
      case respCodeChannelMsgRecv:
        return 'RESP_CODE_CHANNEL_MSG_RECV';
      case respCodeCurrTime:
        return 'RESP_CODE_CURR_TIME';
      case respCodeNoMoreMessages:
        return 'RESP_CODE_NO_MORE_MESSAGES';
      case respCodeBattAndStorage:
        return 'RESP_CODE_BATT_AND_STORAGE';
      case respCodeContactMsgRecvV3:
        return 'RESP_CODE_CONTACT_MSG_RECV_V3';
      case respCodeChannelMsgRecvV3:
        return 'RESP_CODE_CHANNEL_MSG_RECV_V3';
      case respCodeChannelInfo:
        return 'RESP_CODE_CHANNEL_INFO';
      case respCodeAutoAddConfig:
        return 'RESP_CODE_AUTO_ADD_CONFIG';
      case pushCodeTraceData:
        return 'PUSH_CODE_TRACE_DATA';
      default:
        return null;
    }
  }

  String? _pushLabel(int code) {
    switch (code) {
      case pushCodeAdvert:
        return 'PUSH_CODE_ADVERT';
      case pushCodePathUpdated:
        return 'PUSH_CODE_PATH_UPDATED';
      case pushCodeSendConfirmed:
        return 'PUSH_CODE_SEND_CONFIRMED';
      case pushCodeMsgWaiting:
        return 'PUSH_CODE_MSG_WAITING';
      case pushCodeLoginSuccess:
        return 'PUSH_CODE_LOGIN_SUCCESS';
      case pushCodeLoginFail:
        return 'PUSH_CODE_LOGIN_FAIL';
      case pushCodeLogRxData:
        return 'PUSH_CODE_LOG_RX_DATA';
      case pushCodeNewAdvert:
        return 'PUSH_CODE_NEW_ADVERT';
      default:
        return null;
    }
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
