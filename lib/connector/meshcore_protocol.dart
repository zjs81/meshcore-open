import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

// Buffer Reader - sequential binary data reader with pointer tracking
class BufferReader {
  int _pointer = 0;
  int _lastPointer = 0;
  final Uint8List _buffer;

  BufferReader(Uint8List data) : _buffer = Uint8List.fromList(data);

  int get remaining => _buffer.length - _pointer;

  int readByte() => readBytes(1)[0];

  Uint8List readBytes(int count) {
    _lastPointer = _pointer;
    if (_pointer + count > _buffer.length) {
      throw RangeError(
        'Attempted to read $count bytes at offset $_pointer, but only $remaining bytes remaining in buffer of length ${_buffer.length}',
      );
    }
    final data = _buffer.sublist(_pointer, _pointer + count);
    _pointer += count;
    return data;
  }

  void skipBytes(int count) {
    _lastPointer = _pointer;
    if (_pointer + count > _buffer.length) {
      throw RangeError(
        'Attempted to skip $count bytes at offset $_pointer, but only $remaining bytes remaining in buffer of length ${_buffer.length}',
      );
    }
    _pointer += count;
  }

  Uint8List readRemainingBytes() => readBytes(remaining);

  String readString() {
    _lastPointer = _pointer;
    final value = readRemainingBytes();
    try {
      return utf8.decode(Uint8List.fromList(value), allowMalformed: true);
    } catch (e) {
      return String.fromCharCodes(value); // Latin-1 fallback
    }
  }

  String readCStringGreedy(int maxLength) {
    final backupPointer = _pointer;
    final value = <int>[];
    int counter = 0;
    while (counter < maxLength && _pointer < _buffer.length) {
      final byte = readByte();
      if (byte == 0) break;
      value.add(byte);
      counter++;
    }
    _lastPointer = backupPointer;
    try {
      return utf8.decode(Uint8List.fromList(value), allowMalformed: true);
    } catch (e) {
      return String.fromCharCodes(value); // Latin-1 fallback
    }
  }

  String readCString(int maxLength) {
    final backupPointer = _pointer;
    final value = <int>[];
    int counter = 0;
    while (counter < maxLength && _pointer < _buffer.length) {
      final byte = readByte();
      if (byte == 0) break;
      value.add(byte);
      counter++;
    }
    _pointer = backupPointer;
    _lastPointer = backupPointer;
    try {
      return utf8.decode(Uint8List.fromList(value), allowMalformed: true);
    } catch (e) {
      return String.fromCharCodes(value); // Latin-1 fallback
    }
  }

  int readUInt8() => readBytes(1).buffer.asByteData().getUint8(0);
  int readInt8() => readBytes(1).buffer.asByteData().getInt8(0);
  int readUInt16LE() =>
      readBytes(2).buffer.asByteData().getUint16(0, Endian.little);
  int readUInt16BE() =>
      readBytes(2).buffer.asByteData().getUint16(0, Endian.big);
  int readUInt32LE() =>
      readBytes(4).buffer.asByteData().getUint32(0, Endian.little);
  int readUInt32BE() =>
      readBytes(4).buffer.asByteData().getUint32(0, Endian.big);
  int readInt16LE() =>
      readBytes(2).buffer.asByteData().getInt16(0, Endian.little);
  int readInt16BE() => readBytes(2).buffer.asByteData().getInt16(0, Endian.big);
  int readInt32LE() =>
      readBytes(4).buffer.asByteData().getInt32(0, Endian.little);

  int readInt24BE() {
    var value = (readByte() << 16) | (readByte() << 8) | readByte();
    if ((value & 0x800000) != 0) value -= 0x1000000;
    return value;
  }

  void resetPointer() => _pointer = 0;
  void rewind() => _pointer = _lastPointer;
}

// Buffer Writer - accumulating binary data builder
class BufferWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List toBytes() => _builder.toBytes();

  void writeByte(int byte) => _builder.addByte(byte);
  void writeBytes(Uint8List bytes) => _builder.add(bytes);

  void writeUInt16LE(int num) {
    final bytes = Uint8List(2)
      ..buffer.asByteData().setUint16(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeUInt32LE(int num) {
    final bytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeInt32LE(int num) {
    final bytes = Uint8List(4)
      ..buffer.asByteData().setInt32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeString(String string) =>
      writeBytes(Uint8List.fromList(utf8.encode(string)));

  void writeCString(String string, int maxLength) {
    final bytes = Uint8List(maxLength);
    final encoded = _truncateUtf8Bytes(string, maxLength - 1);
    for (var i = 0; i < encoded.length; i++) {
      bytes[i] = encoded[i];
    }
    writeBytes(bytes);
  }

  void writeHex(String hex) {
    writeBytes(hex2Uint8List(hex));
  }
}

Uint8List hex2Uint8List(String hex) {
  // Validate hex string length is even and not empty
  if (hex.isEmpty || hex.length % 2 != 0) {
    throw FormatException('Invalid hex string length: ${hex.length}');
  }
  List<int> result = [];
  for (int i = 0; i < hex.length ~/ 2; i++) {
    final hexByte = hex.substring(i * 2, i * 2 + 2);
    final byte = int.tryParse(hexByte, radix: 16);
    if (byte == null) {
      throw FormatException('Invalid hex characters at position $i: $hexByte');
    }
    result.add(byte);
  }
  return Uint8List.fromList(result);
}

// Command codes (to device)
const int cmdAppStart = 1;
const int cmdSendTxtMsg = 2;
const int cmdSendChannelTxtMsg = 3;
const int cmdGetContacts = 4;
const int cmdGetDeviceTime = 5;
const int cmdSetDeviceTime = 6;
const int cmdSendSelfAdvert = 7;
const int cmdSetAdvertName = 8;
const int cmdAddUpdateContact = 9;
const int cmdSyncNextMessage = 10;
const int cmdSetRadioParams = 11;
const int cmdSetRadioTxPower = 12;
const int cmdResetPath = 13;
const int cmdSetAdvertLatLon = 14;
const int cmdRemoveContact = 15;
const int cmdShareContact = 16;
const int cmdExportContact = 17;
const int cmdImportContact = 18;
const int cmdReboot = 19;
const int cmdGetBattAndStorage = 20;
const int cmdDeviceQuery = 22;
const int cmdSendLogin = 26;
const int cmdSendStatusReq = 27;
const int cmdGetContactByKey = 30;
const int cmdGetChannel = 31;
const int cmdSetChannel = 32;
const int cmdSendTracePath = 36;
const int cmdSetOtherParams = 38;
const int cmdSendAnonReq = 57;
const int cmdGetTelemetryReq = 39;
const int cmdGetCustomVar = 40;
const int cmdSetCustomVar = 41;
const int cmdSendBinaryReq = 50;
const int cmdSetAutoAddConfig = 58;
const int cmdGetAutoAddConfig = 59;

// Text message types
const int txtTypePlain = 0;
const int txtTypeCliData = 1;

// Repeater request types (for server requests)
const int reqTypeGetStatus = 0x01;
const int reqTypeKeepAlive = 0x02;
const int reqTypeGetTelemetry = 0x03;
const int reqTypeGetAccessList = 0x05;
const int reqTypeGetNeighbors = 0x06;

// Repeater response codes
const int respServerLoginOk = 0;

// Response codes (from device)
const int respCodeOk = 0;
const int respCodeErr = 1;
const int respCodeContactsStart = 2;
const int respCodeContact = 3;
const int respCodeEndOfContacts = 4;
const int respCodeSelfInfo = 5;
const int respCodeSent = 6;
const int respCodeContactMsgRecv = 7;
const int respCodeChannelMsgRecv = 8;
const int respCodeCurrTime = 9;
const int respCodeNoMoreMessages = 10;
const int respCodeExportContact = 11;
const int respCodeBattAndStorage = 12;
const int respCodeDeviceInfo = 13;
const int respCodeContactMsgRecvV3 = 16;
const int respCodeChannelMsgRecvV3 = 17;
const int respCodeChannelInfo = 18;
const int respCodeCustomVars = 21;
const int respCodeAutoAddConfig = 25;

// Push codes (async from device)
const int pushCodeAdvert = 0x80;
const int pushCodePathUpdated = 0x81;
const int pushCodeSendConfirmed = 0x82;
const int pushCodeMsgWaiting = 0x83;
const int pushCodeLoginSuccess = 0x85;
const int pushCodeLoginFail = 0x86;
const int pushCodeStatusResponse = 0x87;
const int pushCodeLogRxData = 0x88;
const int pushCodeTraceData = 0x89;
const int pushCodeNewAdvert = 0x8A;
const int pushCodeTelemetryResponse = 0x8B;
const int pushCodeBinaryResponse = 0x8C;

const Map<int, Set<int>> _commandResponseCodes = <int, Set<int>>{
  cmdDeviceQuery: <int>{respCodeDeviceInfo},
  cmdAppStart: <int>{respCodeSelfInfo},
  cmdGetBattAndStorage: <int>{respCodeBattAndStorage},
  cmdGetCustomVar: <int>{respCodeCustomVars},
  cmdGetAutoAddConfig: <int>{respCodeAutoAddConfig},
};

String describeProtocolCode(int code, {required bool outgoing}) {
  if (outgoing) {
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
      case cmdSetAdvertLatLon:
        return 'CMD_SET_ADVERT_LATLON';
      case cmdRemoveContact:
        return 'CMD_REMOVE_CONTACT';
      case cmdShareContact:
        return 'CMD_SHARE_CONTACT';
      case cmdExportContact:
        return 'CMD_EXPORT_CONTACT';
      case cmdImportContact:
        return 'CMD_IMPORT_CONTACT';
      case cmdReboot:
        return 'CMD_REBOOT';
      case cmdGetBattAndStorage:
        return 'CMD_GET_BATT_AND_STORAGE';
      case cmdDeviceQuery:
        return 'CMD_DEVICE_QUERY';
      case cmdSendLogin:
        return 'CMD_SEND_LOGIN';
      case cmdSendStatusReq:
        return 'CMD_SEND_STATUS_REQ';
      case cmdGetContactByKey:
        return 'CMD_GET_CONTACT_BY_KEY';
      case cmdGetChannel:
        return 'CMD_GET_CHANNEL';
      case cmdSetChannel:
        return 'CMD_SET_CHANNEL';
      case cmdSendTracePath:
        return 'CMD_SEND_TRACE_PATH';
      case cmdSetOtherParams:
        return 'CMD_SET_OTHER_PARAMS';
      case cmdGetTelemetryReq:
        return 'CMD_GET_TELEMETRY_REQ';
      case cmdGetCustomVar:
        return 'CMD_GET_CUSTOM_VARS';
      case cmdSetCustomVar:
        return 'CMD_SET_CUSTOM_VAR';
      case cmdSendBinaryReq:
        return 'CMD_SEND_BINARY_REQ';
      case cmdSetAutoAddConfig:
        return 'CMD_SET_AUTO_ADD_CONFIG';
      case cmdGetAutoAddConfig:
        return 'CMD_GET_AUTO_ADD_CONFIG';
      default:
        return 'CMD_$code';
    }
  }

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
    case respCodeExportContact:
      return 'RESP_CODE_EXPORT_CONTACT';
    case respCodeBattAndStorage:
      return 'RESP_CODE_BATT_AND_STORAGE';
    case respCodeDeviceInfo:
      return 'RESP_CODE_DEVICE_INFO';
    case respCodeContactMsgRecvV3:
      return 'RESP_CODE_CONTACT_MSG_RECV_V3';
    case respCodeChannelMsgRecvV3:
      return 'RESP_CODE_CHANNEL_MSG_RECV_V3';
    case respCodeChannelInfo:
      return 'RESP_CODE_CHANNEL_INFO';
    case respCodeCustomVars:
      return 'RESP_CODE_CUSTOM_VARS';
    case respCodeAutoAddConfig:
      return 'RESP_CODE_AUTO_ADD_CONFIG';
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
    case pushCodeStatusResponse:
      return 'PUSH_CODE_STATUS_RESPONSE';
    case pushCodeLogRxData:
      return 'PUSH_CODE_LOG_RX_DATA';
    case pushCodeTraceData:
      return 'PUSH_CODE_TRACE_DATA';
    case pushCodeNewAdvert:
      return 'PUSH_CODE_NEW_ADVERT';
    case pushCodeTelemetryResponse:
      return 'PUSH_CODE_TELEMETRY_RESPONSE';
    case pushCodeBinaryResponse:
      return 'PUSH_CODE_BINARY_RESPONSE';
    default:
      return 'CODE_$code';
  }
}

Set<int> expectedResponseCodesForCommand(int commandCode) {
  return _commandResponseCodes[commandCode] ?? const <int>{};
}

bool frameMatchesCommandResponse(int commandCode, Uint8List frame) {
  if (frame.isEmpty) return false;
  return expectedResponseCodesForCommand(commandCode).contains(frame[0]);
}

// Contact/advertisement types
const int advTypeChat = 1;
const int advTypeRepeater = 2;
const int advTypeRoom = 3;
const int advTypeSensor = 4;

// Payload Types
const int payloadTypeREQ =
    0x00; // request (prefixed with dest/src hashes, MAC) (enc data: timestamp, blob)
const int payloadTypeRESPONSE =
    0x01; // response to REQ or ANON_REQ (prefixed with dest/src hashes, MAC) (enc data: timestamp, blob)
const int payloadTypeTXTMSG =
    0x02; // a plain text message (prefixed with dest/src hashes, MAC) (enc data: timestamp, text)
const int payloadTypeACK = 0x03; // a simple ack
const int payloadTypeADVERT = 0x04; // a node advertising its Identity
const int payloadTypeGRPTXT =
    0x05; // an (unverified) group text message (prefixed with channel hash, MAC) (enc data: timestamp, "name: msg")
const int payloadTypeGRPDATA =
    0x06; // an (unverified) group datagram (prefixed with channel hash, MAC) (enc data: timestamp, blob)
const int payloadTypeANONREQ =
    0x07; // generic request (prefixed with dest_hash, ephemeral pub_key, MAC) (enc data: ...)
const int payloadTypePATH =
    0x08; // returned path (prefixed with dest/src hashes, MAC) (enc data: path, extra)
const int payloadTypeTRACE = 0x09; // trace a path, collecting SNI for each hop
const int payloadTypeMULTIPART = 0x0A; // packet is one of a set of packets
const int payloadTypeCONTROL = 0x0B; // a control/discovery packet
//...
const int payloadTypeRawCustom =
    0x0F; // custom packet as raw bytes, for applications with custom encryption, payloads, etc

//auto-add flags
const int autoAddOverwriteOldestFlag =
    1 << 0; // 0x01 - overwrite oldest non-favourite when full
const int autoAddChatFlag =
    1 << 1; // 0x02 - auto-add Chat (Companion) (ADV_TYPE_CHAT)
const int autoAddRepeaterFlag =
    1 << 2; // 0x04 - auto-add Repeater (ADV_TYPE_REPEATER)
const int autoAddRoomServerFlag =
    1 << 3; // 0x08 - auto-add Room Server (ADV_TYPE_ROOM)
const int autoAddSensorFlag =
    1 << 4; // 0x10 - auto-add Sensor (ADV_TYPE_SENSOR)

// Sizes
const int pubKeySize = 32;
const int maxPathSize = 64;
const int pathHashSize = 1;
const int maxNameSize = 32;
const int maxFrameSize = 172;
const int appProtocolVersion = 3;
// Matches firmware MAX_TEXT_LEN (10 * CIPHER_BLOCK_SIZE).
const int maxTextPayloadBytes = 160;
const int _sendTextMsgOverheadBytes =
    1 + 1 + 1 + 4 + 6 + 1 + 2; // +2 safety margin
const int _sendChannelTextMsgOverheadBytes =
    1 + 1 + 1 + 4 + 1 + 2; // +2 safety margin

int maxContactMessageBytes() {
  final byFrame = maxFrameSize - _sendTextMsgOverheadBytes;
  return _minPositive(byFrame, maxTextPayloadBytes);
}

int maxChannelMessageBytes(String? senderName) {
  final nameLength = _senderNameBytes(senderName);
  final prefixBytes = nameLength + 2; // "<name>: "
  final byPayload = maxTextPayloadBytes - prefixBytes;
  final byFrame = maxFrameSize - _sendChannelTextMsgOverheadBytes;
  return _minPositive(byPayload, byFrame);
}

int _senderNameBytes(String? senderName) {
  if (senderName == null || senderName.isEmpty) return maxNameSize - 1;
  final bytes = utf8.encode(senderName);
  final maxBytes = maxNameSize - 1;
  return bytes.length > maxBytes ? maxBytes : bytes.length;
}

int _minPositive(int a, int b) {
  final minValue = a < b ? a : b;
  return minValue < 0 ? 0 : minValue;
}

// Contact frame offsets
const int contactPubKeyOffset = 1;
const int contactTypeOffset = 33;
const int contactFlagsOffset = 34;
const int contactFlagFavorite = 0x01;
const int contactPathLenOffset = 35;
const int contactPathOffset = 36;
const int contactNameOffset = 100;
const int contactTimestampOffset = 132;
const int contactLatOffset = 136;
const int contactLonOffset = 140;
const int contactLastModOffset = 144;
const int contactFrameSize = 148;

// Message frame offsets
const int msgPubKeyOffset = 1;
const int msgTimestampOffset = 33;
const int msgFlagsOffset = 37;
const int msgTextOffset = 38;

class ParsedContactText {
  final Uint8List senderPrefix;
  final String text;

  const ParsedContactText({required this.senderPrefix, required this.text});
}

class BatteryStatusPacket {
  final int levelPercent;
  final int? usedStorageKb;
  final int? totalStorageKb;

  const BatteryStatusPacket({
    required this.levelPercent,
    this.usedStorageKb,
    this.totalStorageKb,
  });
}

BatteryStatusPacket? parseBatteryStatusPacket(Uint8List frame) {
  if (frame.length < 3 || frame[0] != respCodeBattAndStorage) {
    return null;
  }
  if (frame.length != 3 && frame.length != 11) {
    return null;
  }

  final levelPercent = readUint16LE(frame, 1);
  if (levelPercent > 100) {
    return null;
  }
  final hasStorage = frame.length >= 11;
  return BatteryStatusPacket(
    levelPercent: levelPercent,
    usedStorageKb: hasStorage ? readUint32LE(frame, 3) : null,
    totalStorageKb: hasStorage ? readUint32LE(frame, 7) : null,
  );
}

class MessageSentPacket {
  final int messageType;
  final Uint8List expectedAck;
  final int suggestedTimeoutMs;

  const MessageSentPacket({
    required this.messageType,
    required this.expectedAck,
    required this.suggestedTimeoutMs,
  });
}

MessageSentPacket? parseMessageSentPacket(Uint8List frame) {
  if (frame.length != 10 || frame[0] != respCodeSent) {
    return null;
  }

  return MessageSentPacket(
    messageType: frame[1],
    expectedAck: Uint8List.fromList(frame.sublist(2, 6)),
    suggestedTimeoutMs: readUint32LE(frame, 6) * 1000,
  );
}

class AckPacket {
  final Uint8List ackCode;
  final int? tripTimeMs;

  const AckPacket({required this.ackCode, this.tripTimeMs});
}

AckPacket? parseAckPacket(Uint8List frame) {
  if (frame.length < 5 || frame[0] != pushCodeSendConfirmed) {
    return null;
  }

  if (frame.length == 9) {
    return AckPacket(
      ackCode: Uint8List.fromList(frame.sublist(1, 5)),
      tripTimeMs: readUint32LE(frame, 5),
    );
  }

  if (frame.length == 7) {
    return AckPacket(ackCode: Uint8List.fromList(frame.sublist(1, 7)));
  }

  return null;
}

bool? parseLoginOutcome(
  Uint8List frame, {
  Uint8List? targetPrefix,
}) {
  if (frame.isEmpty) return null;

  final code = frame[0];
  if (code != pushCodeLoginSuccess && code != pushCodeLoginFail) {
    return null;
  }

  if (frame.length == 1) {
    return code == pushCodeLoginSuccess;
  }

  if (targetPrefix != null && targetPrefix.isNotEmpty) {
    final prefixOffset = 2;
    final prefixEnd = prefixOffset + targetPrefix.length;
    if (frame.length < prefixEnd) {
      return null;
    }
    for (var i = 0; i < targetPrefix.length; i++) {
      if (frame[prefixOffset + i] != targetPrefix[i]) {
        return null;
      }
    }
  }

  return code == pushCodeLoginSuccess;
}

class BinaryResponsePacket {
  final int status;
  final Uint8List tag;
  final Uint8List payload;

  const BinaryResponsePacket({
    required this.status,
    required this.tag,
    required this.payload,
  });
}

BinaryResponsePacket? parseBinaryResponsePacket(Uint8List frame) {
  if (frame.length < 6 || frame[0] != pushCodeBinaryResponse) {
    return null;
  }

  return BinaryResponsePacket(
    status: frame[1],
    tag: Uint8List.fromList(frame.sublist(2, 6)),
    payload: Uint8List.fromList(frame.sublist(6)),
  );
}

class MeshCoreFrameBuffer {
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  int? _expectedLength;
  int? _bufferedFixedCode;

  bool get hasBufferedData => _buffer.length > 0;
  int get bufferedLength => _buffer.length;
  int? get expectedLength => _expectedLength;

  List<Uint8List> addChunk(Uint8List chunk) {
    if (chunk.isEmpty) {
      return const <Uint8List>[];
    }

    if (_expectedLength != null) {
      _buffer.add(chunk);
      return _drainBufferedFixedFrame();
    }

    final code = chunk[0];
    final frameLength = _fixedFrameLength(code);
    if (frameLength == null) {
      return <Uint8List>[Uint8List.fromList(chunk)];
    }

    if (chunk.length < frameLength) {
      _buffer.add(chunk);
      _expectedLength = frameLength;
      _bufferedFixedCode = code;
      return const <Uint8List>[];
    }

    if (chunk.length == frameLength) {
      return <Uint8List>[Uint8List.fromList(chunk)];
    }

    final firstFrame = Uint8List.fromList(chunk.sublist(0, frameLength));
    final remainder = _normalizeTrailingRemainder(
      frameCode: code,
      remainder: Uint8List.fromList(chunk.sublist(frameLength)),
    );
    if (remainder.isEmpty) {
      return <Uint8List>[firstFrame];
    }
    return <Uint8List>[firstFrame, ...addChunk(remainder)];
  }

  void clear() {
    _buffer.clear();
    _expectedLength = null;
    _bufferedFixedCode = null;
  }

  Uint8List? discardIncompleteFrame() {
    if (!hasBufferedData) {
      return null;
    }
    final data = _buffer.toBytes();
    clear();
    return data;
  }

  List<Uint8List> _drainBufferedFixedFrame() {
    final buffered = _buffer.toBytes();
    final frameLength = _expectedLength;
    final bufferedCode = _bufferedFixedCode;
    if (frameLength == null || buffered.length < frameLength) {
      return const <Uint8List>[];
    }

    clear();
    final firstFrame = Uint8List.fromList(buffered.sublist(0, frameLength));
    if (buffered.length == frameLength) {
      return <Uint8List>[firstFrame];
    }

    final remainder = _normalizeTrailingRemainder(
      frameCode: bufferedCode,
      remainder: Uint8List.fromList(buffered.sublist(frameLength)),
    );
    if (remainder.isEmpty) {
      return <Uint8List>[firstFrame];
    }
    return <Uint8List>[firstFrame, ...addChunk(remainder)];
  }

  Uint8List _normalizeTrailingRemainder({
    required int? frameCode,
    required Uint8List remainder,
  }) {
    if (remainder.isEmpty) {
      return remainder;
    }
    if (frameCode != respCodeContact &&
        frameCode != pushCodeNewAdvert &&
        frameCode != respCodeDeviceInfo) {
      return remainder;
    }
    if (_isKnownIncomingCode(remainder[0])) {
      return remainder;
    }

    final recoveredOffset = _findEmbeddedIncomingCodeOffset(remainder);
    if (recoveredOffset == null) {
      return remainder;
    }

    return Uint8List.fromList(remainder.sublist(recoveredOffset));
  }

  int? _findEmbeddedIncomingCodeOffset(Uint8List data) {
    final maxScan = data.length < 15 ? data.length : 15;
    for (var i = 1; i < maxScan; i++) {
      if (_isKnownIncomingCode(data[i])) {
        return i;
      }
    }
    return null;
  }

  bool _isKnownIncomingCode(int code) {
    return _fixedFrameLength(code) != null ||
        code == respCodeErr ||
        code == respCodeContactMsgRecv ||
        code == respCodeChannelMsgRecv ||
        code == respCodeExportContact ||
        code == respCodeContactMsgRecvV3 ||
        code == respCodeChannelMsgRecvV3 ||
        code == respCodeChannelInfo ||
        code == respCodeCustomVars ||
        code == pushCodeAdvert ||
        code == pushCodeStatusResponse ||
        code == pushCodeLogRxData ||
        code == pushCodeTraceData ||
        code == pushCodeTelemetryResponse ||
        code == pushCodeBinaryResponse;
  }

  int? _fixedFrameLength(int code) {
    switch (code) {
      case respCodeOk:
      case respCodeNoMoreMessages:
      case pushCodeMsgWaiting:
      case pushCodeLoginSuccess:
      case pushCodeLoginFail:
        return 1;
      case respCodeContactsStart:
      case respCodeEndOfContacts:
      case respCodeCurrTime:
        return 5;
      case respCodeBattAndStorage:
        return 11;
      case respCodeDeviceInfo:
        return 81;
      case respCodeSent:
        return 10;
      case respCodeContact:
      case pushCodeNewAdvert:
        return contactFrameSize;
      case pushCodePathUpdated:
        return 33;
      case respCodeAutoAddConfig:
        return 2;
      case pushCodeSendConfirmed:
        return 9;
      default:
        return null;
    }
  }
}
ParsedContactText? parseContactMessageText(Uint8List frame) {
  if (frame.isEmpty) return null;
  final code = frame[0];
  if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
    return null;
  }

  // Companion radio layout:
  // [code][snr?][res?][res?][prefix x6][path_len][txt_type][timestamp x4][extra?][text...]
  final isV3 = code == respCodeContactMsgRecvV3;
  final prefixOffset = isV3 ? 4 : 1;
  const prefixLen = 6;
  final txtTypeOffset = prefixOffset + prefixLen + 1;
  final timestampOffset = txtTypeOffset + 1;
  final baseTextOffset = timestampOffset + 4;
  if (frame.length <= baseTextOffset) return null;

  final flags = frame[txtTypeOffset];
  final shiftedType = flags >> 2;
  final rawType = flags;
  final isPlain = shiftedType == txtTypePlain || rawType == txtTypePlain;
  final isCli = shiftedType == txtTypeCliData || rawType == txtTypeCliData;
  if (!isPlain && !isCli) {
    return null;
  }

  var text = readCString(
    frame,
    baseTextOffset,
    frame.length - baseTextOffset,
  );
  if (text.isEmpty && frame.length > baseTextOffset + 4) {
    text = readCString(
      frame,
      baseTextOffset + 4,
      frame.length - (baseTextOffset + 4),
    );
  }
  if (text.isEmpty) return null;

  final senderPrefix = frame.sublist(prefixOffset, prefixOffset + prefixLen);
  return ParsedContactText(senderPrefix: senderPrefix, text: text);
}

// Helper to read uint32 little-endian
int readUint32LE(Uint8List data, int offset) {
  return data[offset] |
      (data[offset + 1] << 8) |
      (data[offset + 2] << 16) |
      (data[offset + 3] << 24);
}

// Helper to read uint16 little-endian
int readUint16LE(Uint8List data, int offset) {
  return data[offset] | (data[offset + 1] << 8);
}

// Helper to read int32 little-endian
int readInt32LE(Uint8List data, int offset) {
  int val = readUint32LE(data, offset);
  if (val >= 0x80000000) val -= 0x100000000;
  return val;
}

// Helper to read null-terminated UTF-8 string
String readCString(Uint8List data, int offset, int maxLen) {
  if (offset < 0 || maxLen <= 0 || offset >= data.length) {
    return '';
  }
  int end = offset;
  while (end < offset + maxLen && end < data.length && data[end] != 0) {
    end++;
  }
  try {
    return utf8.decode(data.sublist(offset, end), allowMalformed: true);
  } catch (e) {
    // Fallback to Latin-1 if UTF-8 decoding fails
    return String.fromCharCodes(data.sublist(offset, end));
  }
}

// Helper to convert public key to hex string
String pubKeyToHex(Uint8List pubKey) {
  return pubKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// Helper to convert hex string to public key
Uint8List hexToPubKey(String hex) {
  if (hex.length.isOdd) {
    throw FormatException('Public key hex must have an even number of digits');
  }
  if (hex.length > pubKeySize * 2) {
    throw FormatException(
      'Public key hex must not exceed ${pubKeySize * 2} digits',
    );
  }
  final result = Uint8List(pubKeySize);
  for (int i = 0; i < pubKeySize && i * 2 + 1 < hex.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

// Build CMD_GET_CONTACTS frame
Uint8List buildGetContactsFrame({int? since}) {
  final writer = BufferWriter();
  writer.writeByte(cmdGetContacts);
  if (since != null) {
    _requireUInt32(since, context: 'contact sync timestamp');
    writer.writeUInt32LE(since);
  }
  return writer.toBytes();
}

// Build CMD_SEND_LOGIN frame
// Format: [cmd][pub_key x32][password...]\0
Uint8List buildSendLoginFrame(Uint8List recipientPubKey, String password) {
  _requireFullPublicKey(recipientPubKey, context: 'login request');
  final writer = BufferWriter();
  writer.writeByte(cmdSendLogin);
  writer.writeBytes(recipientPubKey);
  writer.writeString(password);
  writer.writeByte(0);
  return _finalizeFrame(writer, context: 'login request');
}

// Build CMD_SEND_STATUS_REQ frame
// Format: [cmd][pub_key x32]
Uint8List buildSendStatusRequestFrame(Uint8List recipientPubKey) {
  _requireFullPublicKey(recipientPubKey, context: 'status request');
  final writer = BufferWriter();
  writer.writeByte(cmdSendStatusReq);
  writer.writeBytes(recipientPubKey);
  return writer.toBytes();
}

// Build CMD_SEND_TXT_MSG frame (companion_radio format)
// Format: [cmd][txt_type][attempt][timestamp x4][pub_key_prefix x6][text...]\0
Uint8List buildSendTextMsgFrame(
  Uint8List recipientPubKey,
  String text, {
  int attempt = 0,
  int? timestampSeconds,
}) {
  _requirePublicKeyPrefix(recipientPubKey, context: 'contact text message');
  final timestamp =
      timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  _requireUInt32(timestamp, context: 'contact text timestamp');
  final writer = BufferWriter();
  writer.writeByte(cmdSendTxtMsg);
  writer.writeByte(txtTypePlain);
  writer.writeByte(attempt.clamp(0, 3));
  writer.writeUInt32LE(timestamp);
  writer.writeBytes(recipientPubKey.sublist(0, 6));
  writer.writeString(text);
  writer.writeByte(0);
  return _finalizeFrame(writer, context: 'contact text message');
}

// Build CMD_SEND_CHANNEL_TXT_MSG frame
// Format: [cmd][txt_type][channel_idx][timestamp x4][text...]
Uint8List buildSendChannelTextMsgFrame(int channelIndex, String text) {
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final writer = BufferWriter();
  writer.writeByte(cmdSendChannelTxtMsg);
  writer.writeByte(txtTypePlain);
  writer.writeByte(channelIndex);
  writer.writeUInt32LE(timestamp);
  writer.writeString(text);
  writer.writeByte(0);
  return _finalizeFrame(writer, context: 'channel text message');
}

// Build CMD_REMOVE_CONTACT frame
Uint8List buildRemoveContactFrame(Uint8List pubKey) {
  _requireFullPublicKey(pubKey, context: 'contact removal');
  final writer = BufferWriter();
  writer.writeByte(cmdRemoveContact);
  writer.writeBytes(pubKey);
  return writer.toBytes();
}

// Build CMD_APP_START frame
// Format: [cmd][app_ver][app_name x9]
Uint8List buildAppStartFrame({
  String appName = 'mccli',
  int appVersion = appProtocolVersion,
}) {
  final writer = BufferWriter();
  writer.writeByte(cmdAppStart);
  writer.writeByte(appVersion);
  writer.writeCString(appName, 9);
  return writer.toBytes();
}

// Build CMD_DEVICE_QUERY frame
Uint8List buildDeviceQueryFrame({int appVersion = appProtocolVersion}) {
  return Uint8List.fromList([cmdDeviceQuery, appVersion]);
}

// Build CMD_GET_DEVICE_TIME frame
Uint8List buildGetDeviceTimeFrame() {
  return Uint8List.fromList([cmdGetDeviceTime]);
}

// Build CMD_GET_BATT_AND_STORAGE frame
Uint8List buildGetBattAndStorageFrame() {
  return Uint8List.fromList([cmdGetBattAndStorage]);
}

// Build CMD_SET_DEVICE_TIME frame
Uint8List buildSetDeviceTimeFrame(int timestamp) {
  _requireUInt32(timestamp, context: 'device timestamp');
  final writer = BufferWriter();
  writer.writeByte(cmdSetDeviceTime);
  writer.writeUInt32LE(timestamp);
  return writer.toBytes();
}

// Build CMD_SEND_SELF_ADVERT frame
// Format: [cmd][flood_flag]
Uint8List buildSendSelfAdvertFrame({bool flood = false}) {
  return Uint8List.fromList([cmdSendSelfAdvert, flood ? 1 : 0]);
}

// Build CMD_SET_ADVERT_NAME frame
// Format: [cmd][name...]
Uint8List buildSetAdvertNameFrame(String name) {
  final writer = BufferWriter();
  writer.writeByte(cmdSetAdvertName);
  writer.writeBytes(Uint8List.fromList(_truncateUtf8Bytes(name, maxNameSize - 1)));
  return writer.toBytes();
}

// Build CMD_SET_ADVERT_LATLON frame
// Format: [cmd][lat x4][lon x4]
Uint8List buildSetAdvertLatLonFrame(double lat, double lon) {
  if (!lat.isFinite || lat < -90 || lat > 90) {
    throw RangeError('latitude must be finite and between -90 and 90');
  }
  if (!lon.isFinite || lon < -180 || lon > 180) {
    throw RangeError('longitude must be finite and between -180 and 180');
  }
  final writer = BufferWriter();
  writer.writeByte(cmdSetAdvertLatLon);
  writer.writeInt32LE((lat * 1000000).round());
  writer.writeInt32LE((lon * 1000000).round());
  return _finalizeFrame(writer, context: 'advert location update');
}

Uint8List buildSetCustomVarFrame(String value) {
  final writer = BufferWriter();
  writer.writeByte(cmdSetCustomVar);
  writer.writeString(value);
  writer.writeByte(0);
  return _finalizeFrame(writer, context: 'custom variable update');
}

// Build local CLI command frame
// Format: [cmdAppStart][command...]\0
Uint8List buildLocalCliCommandFrame(String command) {
  return _finalizeRawFrame(
    Uint8List.fromList([cmdAppStart, ...utf8.encode(command), 0]),
    context: 'local CLI command',
  );
}

// Build CMD_SYNC_NEXT_MESSAGE frame
Uint8List buildSyncNextMessageFrame() {
  return Uint8List.fromList([cmdSyncNextMessage]);
}

// Build CMD_GET_CHANNEL frame
Uint8List buildGetChannelFrame(int channelIndex) {
  return Uint8List.fromList([cmdGetChannel, channelIndex]);
}

// Build CMD_SET_CHANNEL frame
// Format: [cmd][idx][name x32][secret x32]
Uint8List buildSetChannelFrame(int channelIndex, String name, Uint8List psk) {
  final writer = BufferWriter();
  writer.writeByte(cmdSetChannel);
  writer.writeByte(channelIndex);
  writer.writeCString(name, 32);
  writer.writeBytes(_expandChannelSecretForDevice(psk));
  return writer.toBytes();
}

Uint8List _expandChannelSecretForDevice(Uint8List psk) {
  if (psk.length >= 32) {
    return Uint8List.fromList(psk.sublist(0, 32));
  }

  final padded = Uint8List(16);
  final copyLength = psk.length < 16 ? psk.length : 16;
  padded.setRange(0, copyLength, psk);
  if (padded.every((byte) => byte == 0)) {
    return Uint8List(32);
  }

  final digest = crypto.sha512.convert(padded).bytes;
  return Uint8List.fromList(digest.sublist(0, 32));
}

// Build CMD_SET_RADIO_PARAMS frame
// Format: [cmd][freq x4][bw x4][sf][cr] (pre-v9)
//         [cmd][freq x4][bw x4][sf][cr][repeat] (firmware v9+)
// freq: frequency in Hz (300000-2500000)
// bw: bandwidth in Hz (7000-500000)
// sf: spreading factor (5-12)
// cr: coding rate (5-8)
// clientRepeat: enable off-grid packet repeat (firmware v9+, omit for older)
Uint8List buildSetRadioParamsFrame(
  int freqHz,
  int bwHz,
  int sf,
  int cr, {
  bool? clientRepeat,
}) {
  _requireRange(
    freqHz,
    min: 300000,
    max: 2500000,
    context: 'radio frequency',
  );
  _requireRange(
    bwHz,
    min: 7000,
    max: 500000,
    context: 'radio bandwidth',
  );
  _requireRange(sf, min: 5, max: 12, context: 'spreading factor');
  _requireRange(cr, min: 5, max: 8, context: 'coding rate');
  final writer = BufferWriter();
  writer.writeByte(cmdSetRadioParams);
  writer.writeUInt32LE(freqHz);
  writer.writeUInt32LE(bwHz);
  writer.writeByte(sf);
  writer.writeByte(cr);
  if (clientRepeat != null) {
    writer.writeByte(clientRepeat ? 1 : 0);
  }
  return _finalizeFrame(writer, context: 'radio parameter update');
}

// Build CMD_SET_RADIO_TX_POWER frame
// Format: [cmd][power_dbm]
Uint8List buildSetRadioTxPowerFrame(int powerDbm) {
  return Uint8List.fromList([cmdSetRadioTxPower, powerDbm]);
}

// Build CMD_RESET_PATH frame
// Format: [cmd][pub_key x32]
Uint8List buildResetPathFrame(Uint8List pubKey) {
  _requireFullPublicKey(pubKey, context: 'path reset');
  final writer = BufferWriter();
  writer.writeByte(cmdResetPath);
  writer.writeBytes(pubKey);
  return _finalizeFrame(writer, context: 'path reset');
}

// Build CMD_ADD_UPDATE_CONTACT frame to set custom path
// Format: [cmd][pub_key x32][type][flags][path_len][path x64][name x32][timestamp x4]
Uint8List buildUpdateContactPathFrame(
  Uint8List pubKey,
  Uint8List customPath,
  int pathLen, {
  int type = 1, // ADV_TYPE_CHAT
  int flags = 0,
  String name = '',
}) {
  _requireFullPublicKey(pubKey, context: 'contact path update');
  if (pathLen < 0 || pathLen > maxPathSize) {
    throw RangeError('path length must be between 0 and $maxPathSize bytes');
  }
  if (customPath.length < pathLen) {
    throw ArgumentError(
      'custom path must include at least $pathLen bytes, '
      'but only ${customPath.length} were provided',
    );
  }
  final writer = BufferWriter();
  writer.writeByte(cmdAddUpdateContact);
  writer.writeBytes(pubKey);
  writer.writeByte(type);
  writer.writeByte(flags);
  writer.writeByte(pathLen);

  // Path data (64 bytes, zero-padded)
  final pathPadded = Uint8List(maxPathSize);
  if (customPath.isNotEmpty && pathLen > 0) {
    final copyLen = customPath.length < maxPathSize
        ? customPath.length
        : maxPathSize;
    for (int i = 0; i < copyLen; i++) {
      pathPadded[i] = customPath[i];
    }
  }
  writer.writeBytes(pathPadded);

  // Name (32 bytes, null-padded)
  writer.writeCString(name, maxNameSize);

  // Timestamp
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  writer.writeUInt32LE(timestamp);

  return _finalizeFrame(writer, context: 'contact path update');
}

// Build CMD_GET_CONTACT_BY_KEY frame
// Format: [cmd][pub_key x32]
Uint8List buildGetContactByKeyFrame(Uint8List pubKey) {
  _requireFullPublicKey(pubKey, context: 'contact lookup');
  final writer = BufferWriter();
  writer.writeByte(cmdGetContactByKey);
  writer.writeBytes(pubKey);
  return writer.toBytes();
}

//Build CMD_GET_CUSTOM_VARS frame
Uint8List buildGetCustomVarsFrame() {
  return Uint8List.fromList([cmdGetCustomVar]);
}

Uint8List buildGetAutoAddFlagsFrame() {
  return Uint8List.fromList([cmdGetAutoAddConfig]);
}

// Calculate LoRa airtime for a packet
// Based on Semtech SX127x datasheet formula
// Returns airtime in milliseconds
int calculateLoRaAirtime({
  required int payloadBytes,
  required int spreadingFactor,
  required int bandwidthHz,
  required int codingRate,
  int preambleSymbols = 8,
  bool lowDataRateOptimize = false,
  bool explicitHeader = true,
}) {
  _requireRange(payloadBytes, min: 0, max: maxFrameSize, context: 'LoRa payload bytes');
  _requireRange(
    spreadingFactor,
    min: 5,
    max: 12,
    context: 'LoRa spreading factor',
  );
  _requireRange(
    bandwidthHz,
    min: 7000,
    max: 500000,
    context: 'LoRa bandwidth',
  );
  _requireRange(codingRate, min: 5, max: 8, context: 'LoRa coding rate');
  if (preambleSymbols < 0) {
    throw RangeError('LoRa preamble symbols must be non-negative');
  }
  // Symbol duration (Ts) in milliseconds
  final symbolDuration = (1 << spreadingFactor) / (bandwidthHz / 1000.0);

  // Preamble time
  final preambleTime = (preambleSymbols + 4.25) * symbolDuration;

  // Payload symbol count
  final headerBytes = explicitHeader ? 0 : 20;
  final crc = 1; // CRC enabled
  final de = lowDataRateOptimize ? 1 : 0;

  final numerator =
      8 * payloadBytes - 4 * spreadingFactor + 28 + 16 * crc - headerBytes;
  final denominator = 4 * (spreadingFactor - 2 * de);
  var payloadSymbols =
      8 + ((numerator / denominator).ceil()) * (codingRate + 4);

  if (payloadSymbols < 0) {
    payloadSymbols = 8;
  }

  final payloadTime = payloadSymbols * symbolDuration;

  return (preambleTime + payloadTime).ceil();
}

// Calculate timeout for a message based on radio settings
// Returns timeout in milliseconds
int calculateMessageTimeout({
  required int freqHz,
  required int bwHz,
  required int sf,
  required int cr,
  required int pathLength,
  int messageBytes = 100, // Average message size
}) {
  _requireRange(
    freqHz,
    min: 300000,
    max: 2500000,
    context: 'timeout radio frequency',
  );
  _requireRange(
    bwHz,
    min: 7000,
    max: 500000,
    context: 'timeout radio bandwidth',
  );
  _requireRange(sf, min: 5, max: 12, context: 'timeout spreading factor');
  _requireRange(cr, min: 5, max: 8, context: 'timeout coding rate');
  if (messageBytes < 0) {
    throw RangeError('timeout message bytes must be non-negative');
  }
  if (pathLength < -1) {
    throw RangeError('path length must be -1 for flood or >= 0 for routed sends');
  }
  // Calculate airtime for one packet
  final airtime = calculateLoRaAirtime(
    payloadBytes: messageBytes,
    spreadingFactor: sf,
    bandwidthHz: bwHz,
    codingRate: cr,
    lowDataRateOptimize: sf >= 11,
  );

  if (pathLength < 0) {
    // Flood mode: Base delay + 16× airtime
    return 500 + (16 * airtime);
  } else {
    // Direct path: Base delay + ((airtime×6 + 250ms)×(hops+1))
    return 500 + ((airtime * 6 + 250) * (pathLength + 1));
  }
}

// Build CLI command text message frame (companion_radio format)
// Format: [cmd][txt_type][attempt][timestamp x4][pub_key_prefix x6][text...]\0
Uint8List buildSendCliCommandFrame(
  Uint8List repeaterPubKey,
  String command, {
  int attempt = 0,
  int? timestampSeconds,
}) {
  _requirePublicKeyPrefix(repeaterPubKey, context: 'CLI command');
  final timestamp =
      timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  _requireUInt32(timestamp, context: 'CLI command timestamp');
  final writer = BufferWriter();
  writer.writeByte(cmdSendTxtMsg);
  writer.writeByte(txtTypeCliData);
  writer.writeByte(attempt.clamp(0, 3));
  writer.writeUInt32LE(timestamp);
  writer.writeBytes(repeaterPubKey.sublist(0, 6));
  writer.writeString(command);
  writer.writeByte(0);
  return _finalizeFrame(writer, context: 'CLI command');
}

// Build a telemetry request frame
// Format: [cmd][pub_key x32][payload]
Uint8List buildSendBinaryReq(Uint8List repeaterPubKey, {Uint8List? payload}) {
  _requireFullPublicKey(repeaterPubKey, context: 'binary request');
  final writer = BufferWriter();
  writer.writeByte(cmdSendBinaryReq);
  writer.writeBytes(repeaterPubKey);
  if (payload != null && payload.isNotEmpty) {
    writer.writeBytes(payload);
  }
  return _finalizeFrame(writer, context: 'binary request');
}

void _requirePublicKeyPrefix(Uint8List pubKey, {required String context}) {
  if (pubKey.length < 6) {
    throw ArgumentError('$context requires at least a 6-byte public key prefix');
  }
}

void _requireFullPublicKey(Uint8List pubKey, {required String context}) {
  if (pubKey.length != pubKeySize) {
    throw ArgumentError('$context requires a $pubKeySize-byte public key');
  }
}

void _requireUInt32(int value, {required String context}) {
  if (value < 0 || value > 0xFFFFFFFF) {
    throw RangeError('$context must fit in an unsigned 32-bit integer');
  }
}

void _requireRange(
  int value, {
  required int min,
  required int max,
  required String context,
}) {
  if (value < min || value > max) {
    throw RangeError('$context must be between $min and $max');
  }
}

Uint8List _finalizeFrame(BufferWriter writer, {required String context}) {
  return _finalizeRawFrame(writer.toBytes(), context: context);
}

List<int> _truncateUtf8Bytes(String value, int maxBytes) {
  if (maxBytes <= 0 || value.isEmpty) {
    return const <int>[];
  }

  final builder = BytesBuilder(copy: false);
  var usedBytes = 0;
  for (final rune in value.runes) {
    final encodedRune = utf8.encode(String.fromCharCode(rune));
    if (usedBytes + encodedRune.length > maxBytes) {
      break;
    }
    builder.add(encodedRune);
    usedBytes += encodedRune.length;
  }
  return builder.toBytes();
}

Uint8List _finalizeRawFrame(Uint8List frame, {required String context}) {
  if (frame.length > maxFrameSize) {
    throw ArgumentError(
      '$context exceeds max frame size of $maxFrameSize bytes '
      '(got ${frame.length})',
    );
  }
  return frame;
}

//Build a trace request frame
//[cmd][tag x4][auth x4][flag][payload]
Uint8List buildTraceReq(int tag, int auth, int flag, {Uint8List? payload}) {
  _requireUInt32(tag, context: 'trace tag');
  _requireUInt32(auth, context: 'trace auth');
  final pathBytes = payload ?? Uint8List(0);
  final pathSizeShift = flag & 0x03;
  final pathStride = 1 << pathSizeShift;
  final maxPayloadBytes = maxPathSize * pathStride;
  if (pathBytes.isEmpty ||
      pathBytes.length > maxPayloadBytes ||
      pathBytes.length % pathStride != 0) {
    throw ArgumentError(
      'Invalid trace payload length ${pathBytes.length} for flag=$flag '
      '(max=$maxPayloadBytes stride=$pathStride)',
    );
  }

  final writer = BufferWriter();
  writer.writeByte(cmdSendTracePath);
  writer.writeUInt32LE(tag);
  writer.writeUInt32LE(auth);
  writer.writeByte(flag);
  writer.writeBytes(pathBytes);
  return writer.toBytes();
}

// Build a export contact frame
// [cmd][pub_key x32 / if empty exports your contact info]
Uint8List buildExportContactFrame(Uint8List pubKey) {
  final writer = BufferWriter();
  writer.writeByte(cmdExportContact);
  writer.writeBytes(pubKey);
  return writer.toBytes();
}

// Build a import contact frame
// [cmd][contact_frame x98+]
Uint8List buildImportContactFrame(Uint8List contactFrame) {
  final writer = BufferWriter();
  writer.writeByte(cmdImportContact);
  writer.writeBytes(contactFrame);
  return writer.toBytes();
}

// Build a export contact frame
// [cmd][pub_key x32]
Uint8List buildZeroHopContact(Uint8List pubKey) {
  _requireFullPublicKey(pubKey, context: 'contact export');
  final writer = BufferWriter();
  writer.writeByte(cmdShareContact);
  writer.writeBytes(pubKey);
  return _finalizeFrame(writer, context: 'contact export');
}

// Build CMD_SET_OTHER_PARAMS frame
// Format: [cmd][allowTelemetryFlags][advertLocationPolicy][multiAcks]
Uint8List buildSetOtherParamsFrame(
  int allowTelemetryFlags,
  int advertLocationPolicy,
  int multiAcks,
) {
  final writer = BufferWriter();
  writer.writeByte(cmdSetOtherParams);
  //Going forward the app will just set Auto Add Contacts to disabled, and use the filter flags
  //Allow Auto Add Contacts use inverted logic (0x01 = disabled, 0x00 = enabled).
  writer.writeByte(0x01);
  writer.writeByte(allowTelemetryFlags); // Allow Telemetry Flags
  writer.writeByte(advertLocationPolicy); // Advertisement Location Policy
  writer.writeByte(multiAcks); // Multi Acknowledgements
  return writer.toBytes();
}

// Build CMD_SET_AUTO_ADD_CONFIG frame
// Format: [cmd][flags]
Uint8List buildSetAutoAddConfigFrame({
  required bool autoAddChat,
  required bool autoAddRepeater,
  required bool autoAddRoomServer,
  required bool autoAddSensor,
  required bool overwriteOldest,
}) {
  final writer = BufferWriter();
  writer.writeByte(cmdSetAutoAddConfig);
  int flags = 0;
  if (autoAddChat) flags |= autoAddChatFlag;
  if (autoAddRepeater) flags |= autoAddRepeaterFlag;
  if (autoAddRoomServer) flags |= autoAddRoomServerFlag;
  if (autoAddSensor) flags |= autoAddSensorFlag;
  if (overwriteOldest) flags |= autoAddOverwriteOldestFlag;
  writer.writeByte(flags);
  return writer.toBytes();
}
