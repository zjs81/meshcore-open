import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

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
const int cmdGetRadioSettings = 57;
const int cmdGetTelemetryReq = 39;
const int cmdSendBinaryReq = 50;

// Text message types
const int txtTypePlain = 0;
const int txtTypeCliData = 1;

// Repeater request types (for server requests)
const int reqTypeGetStatus = 0x01;
const int reqTypeKeepAlive = 0x02;
const int reqTypeGetTelemetry = 0x03;
const int reqTypeGetAccessList = 0x05;
const int reqTypeGetNeighbours = 0x06;

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
const int respCodeBattAndStorage = 12;
const int respCodeDeviceInfo = 13;
const int respCodeContactMsgRecvV3 = 16;
const int respCodeChannelMsgRecvV3 = 17;
const int respCodeChannelInfo = 18;
const int respCodeRadioSettings = 25;

// Push codes (async from device)
const int pushCodeAdvert = 0x80;
const int pushCodePathUpdated = 0x81;
const int pushCodeSendConfirmed = 0x82;
const int pushCodeMsgWaiting = 0x83;
const int pushCodeLoginSuccess = 0x85;
const int pushCodeLoginFail = 0x86;
const int pushCodeStatusResponse = 0x87;
const int pushCodeLogRxData = 0x88;
const int pushCodeNewAdvert = 0x8A;
const int pushCodeTelemetryResponse = 0x8B;
const int pushCodeBinaryResponse = 0x8C;


// Contact/advertisement types
const int advTypeChat = 1;
const int advTypeRepeater = 2;
const int advTypeRoom = 3;
const int advTypeSensor = 4;

// Sizes
const int pubKeySize = 32;
const int maxPathSize = 64;
const int pathHashSize = 1;
const int maxNameSize = 32;
const int maxFrameSize = 172;
const int appProtocolVersion = 3;
// Matches firmware MAX_TEXT_LEN (10 * CIPHER_BLOCK_SIZE).
const int maxTextPayloadBytes = 160;
const int _sendTextMsgOverheadBytes = 1 + 1 + 1 + 4 + 6 + 1;
const int _sendChannelTextMsgOverheadBytes = 1 + 1 + 1 + 4 + 1;

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
const int contactPathLenOffset = 35;
const int contactPathOffset = 36;
const int contactNameOffset = 100;
const int contactTimestampOffset = 132;
const int contactLatOffset = 136;
const int contactLonOffset = 140;
const int contactLastmodOffset = 144;
const int contactFrameSize = 148;

// Message frame offsets
const int msgPubKeyOffset = 1;
const int msgTimestampOffset = 33;
const int msgFlagsOffset = 37;
const int msgTextOffset = 38;

class ParsedContactText {
  final Uint8List senderPrefix;
  final String text;

  const ParsedContactText({
    required this.senderPrefix,
    required this.text,
  });
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

  var text = readCString(frame, baseTextOffset, frame.length - baseTextOffset).trim();
  if (text.isEmpty && frame.length > baseTextOffset + 4) {
    text =
        readCString(frame, baseTextOffset + 4, frame.length - (baseTextOffset + 4)).trim();
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

// Helper to write uint32 little-endian
void writeUint32LE(Uint8List data, int offset, int value) {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >> 8) & 0xFF;
  data[offset + 2] = (value >> 16) & 0xFF;
  data[offset + 3] = (value >> 24) & 0xFF;
}

// Helper to write int32 little-endian
void writeInt32LE(Uint8List data, int offset, int value) {
  writeUint32LE(data, offset, value & 0xFFFFFFFF);
}

// Helper to read null-terminated UTF-8 string
String readCString(Uint8List data, int offset, int maxLen) {
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
  final result = Uint8List(pubKeySize);
  for (int i = 0; i < pubKeySize && i * 2 + 1 < hex.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

// Build CMD_GET_CONTACTS frame
Uint8List buildGetContactsFrame({int? since}) {
  if (since != null) {
    final frame = Uint8List(5);
    frame[0] = cmdGetContacts;
    writeUint32LE(frame, 1, since);
    return frame;
  }
  return Uint8List.fromList([cmdGetContacts]);
}

// Build CMD_SEND_LOGIN frame
// Format: [cmd][pub_key x32][password...]\0
Uint8List buildSendLoginFrame(Uint8List recipientPubKey, String password) {
  final passwordBytes = utf8.encode(password);
  final frame = Uint8List(1 + pubKeySize + passwordBytes.length + 1);
  frame[0] = cmdSendLogin;
  frame.setRange(1, 1 + pubKeySize, recipientPubKey);
  frame.setRange(1 + pubKeySize, 1 + pubKeySize + passwordBytes.length, passwordBytes);
  frame[frame.length - 1] = 0;
  return frame;
}

// Build CMD_SEND_STATUS_REQ frame
// Format: [cmd][pub_key x32]
Uint8List buildSendStatusRequestFrame(Uint8List recipientPubKey) {
  final frame = Uint8List(1 + pubKeySize);
  frame[0] = cmdSendStatusReq;
  frame.setRange(1, 1 + pubKeySize, recipientPubKey);
  return frame;
}

// Build CMD_SEND_TXT_MSG frame (companion_radio format)
// Format: [cmd][txt_type][attempt][timestamp x4][pub_key_prefix x6][text...]\0
Uint8List buildSendTextMsgFrame(
  Uint8List recipientPubKey,
  String text, {
  int attempt = 0,
  int? timestampSeconds,
}) {
  final textBytes = utf8.encode(text);
  final timestamp = timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  const prefixSize = 6;
  final safeAttempt = attempt.clamp(0, 3);
  final frame = Uint8List(1 + 1 + 1 + 4 + prefixSize + textBytes.length + 1);
  int offset = 0;

  frame[offset++] = cmdSendTxtMsg;
  frame[offset++] = txtTypePlain;
  frame[offset++] = safeAttempt;
  writeUint32LE(frame, offset, timestamp);
  offset += 4;

  frame.setRange(offset, offset + prefixSize, recipientPubKey.sublist(0, prefixSize));
  offset += prefixSize;

  frame.setRange(offset, offset + textBytes.length, textBytes);
  frame[frame.length - 1] = 0; // null terminator
  return frame;
}

// Build CMD_SEND_CHANNEL_TXT_MSG frame
// Format: [cmd][txt_type][channel_idx][timestamp x4][text...]
Uint8List buildSendChannelTextMsgFrame(int channelIndex, String text) {
  final textBytes = utf8.encode(text);
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final frame = Uint8List(1 + 1 + 1 + 4 + textBytes.length + 1);
  frame[0] = cmdSendChannelTxtMsg;
  frame[1] = 0; // TXT_TYPE_PLAIN
  frame[2] = channelIndex;
  writeUint32LE(frame, 3, timestamp);
  frame.setRange(7, 7 + textBytes.length, textBytes);
  frame[frame.length - 1] = 0; // null terminator
  return frame;
}

// Build CMD_REMOVE_CONTACT frame
Uint8List buildRemoveContactFrame(Uint8List pubKey) {
  final frame = Uint8List(1 + pubKeySize);
  frame[0] = cmdRemoveContact;
  frame.setRange(1, 1 + pubKeySize, pubKey);
  return frame;
}

// Build CMD_APP_START frame
// Format: [cmd][app_ver][reserved x6][app_name...]
Uint8List buildAppStartFrame({
  String appName = 'MeshCoreOpen',
  int appVersion = 1,
}) {
  final nameBytes = utf8.encode(appName);
  final frame = Uint8List(8 + nameBytes.length + 1);
  frame[0] = cmdAppStart;
  frame[1] = appVersion;
  // bytes 2-7 are reserved (zeros)
  frame.setRange(8, 8 + nameBytes.length, nameBytes);
  frame[frame.length - 1] = 0; // null terminator
  return frame;
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
  final frame = Uint8List(5);
  frame[0] = cmdSetDeviceTime;
  writeUint32LE(frame, 1, timestamp);
  return frame;
}

// Build CMD_SEND_SELF_ADVERT frame
// Format: [cmd][flood_flag]
Uint8List buildSendSelfAdvertFrame({bool flood = false}) {
  return Uint8List.fromList([cmdSendSelfAdvert, flood ? 1 : 0]);
}

// Build CMD_SET_ADVERT_NAME frame
// Format: [cmd][name...]
Uint8List buildSetAdvertNameFrame(String name) {
  final nameBytes = utf8.encode(name);
  final nameLen = nameBytes.length < maxNameSize ? nameBytes.length : maxNameSize - 1;
  final frame = Uint8List(1 + nameLen);
  frame[0] = cmdSetAdvertName;
  frame.setRange(1, 1 + nameLen, nameBytes.sublist(0, nameLen));
  return frame;
}

// Build CMD_SET_ADVERT_LATLON frame
// Format: [cmd][lat x4][lon x4]
Uint8List buildSetAdvertLatLonFrame(double lat, double lon) {
  final frame = Uint8List(9);
  frame[0] = cmdSetAdvertLatLon;
  writeInt32LE(frame, 1, (lat * 1000000).round());
  writeInt32LE(frame, 5, (lon * 1000000).round());
  return frame;
}

// Build CMD_REBOOT frame
// Format: [cmd]["reboot"]
Uint8List buildRebootFrame() {
  return Uint8List.fromList([cmdReboot, ...utf8.encode('reboot')]);
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
// Format: [cmd][idx][name x32][psk x16]
Uint8List buildSetChannelFrame(int channelIndex, String name, Uint8List psk) {
  final frame = Uint8List(2 + 32 + 16);
  frame[0] = cmdSetChannel;
  frame[1] = channelIndex;
  // Write name (max 32 bytes UTF-8, null-padded)
  final nameBytes = utf8.encode(name);
  final nameLen = nameBytes.length < 32 ? nameBytes.length : 31; // Reserve 1 byte for null
  for (int i = 0; i < nameLen; i++) {
    frame[2 + i] = nameBytes[i];
  }
  // frame[2 + nameLen] is already 0 (null terminator)
  // Write PSK (16 bytes)
  for (int i = 0; i < 16 && i < psk.length; i++) {
    frame[34 + i] = psk[i];
  }
  return frame;
}

// Build CMD_SET_RADIO_PARAMS frame
// Format: [cmd][freq x4][bw x4][sf][cr]
// freq: frequency in Hz (300000-2500000)
// bw: bandwidth in Hz (7000-500000)
// sf: spreading factor (5-12)
// cr: coding rate (5-8)
Uint8List buildSetRadioParamsFrame(int freqHz, int bwHz, int sf, int cr) {
  final frame = Uint8List(11);
  frame[0] = cmdSetRadioParams;
  writeUint32LE(frame, 1, freqHz);
  writeUint32LE(frame, 5, bwHz);
  frame[9] = sf;
  frame[10] = cr;
  return frame;
}

// Build CMD_SET_RADIO_TX_POWER frame
// Format: [cmd][power_dbm]
Uint8List buildSetRadioTxPowerFrame(int powerDbm) {
  return Uint8List.fromList([cmdSetRadioTxPower, powerDbm]);
}

// Build CMD_RESET_PATH frame
// Format: [cmd][pub_key x32]
Uint8List buildResetPathFrame(Uint8List pubKey) {
  final frame = Uint8List(1 + pubKeySize);
  frame[0] = cmdResetPath;
  frame.setRange(1, 1 + pubKeySize, pubKey);
  return frame;
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
  // Frame size: 1 + 32 + 1 + 1 + 1 + 64 + 32 + 4 = 136 bytes minimum
  final frame = Uint8List(1 + pubKeySize + 1 + 1 + 1 + maxPathSize + maxNameSize + 4);
  int offset = 0;

  frame[offset++] = cmdAddUpdateContact;

  // Public key (32 bytes)
  frame.setRange(offset, offset + pubKeySize, pubKey);
  offset += pubKeySize;

  // Type and flags
  frame[offset++] = type;
  frame[offset++] = flags;

  // Path length and path data
  frame[offset++] = pathLen;
  if (customPath.isNotEmpty && pathLen > 0) {
    final copyLen = customPath.length < maxPathSize ? customPath.length : maxPathSize;
    frame.setRange(offset, offset + copyLen, customPath.sublist(0, copyLen));
  }
  offset += maxPathSize;

  // Name (32 bytes, null-padded)
  if (name.isNotEmpty) {
    final nameBytes = utf8.encode(name);
    final nameLen = nameBytes.length < maxNameSize ? nameBytes.length : maxNameSize - 1;
    frame.setRange(offset, offset + nameLen, nameBytes.sublist(0, nameLen));
  }
  offset += maxNameSize;

  // Timestamp (current time)
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  writeUint32LE(frame, offset, timestamp);

  return frame;
}

// Build CMD_GET_CONTACT_BY_KEY frame
// Format: [cmd][pub_key x32]
Uint8List buildGetContactByKeyFrame(Uint8List pubKey) {
  final frame = Uint8List(1 + pubKeySize);
  frame[0] = cmdGetContactByKey;
  frame.setRange(1, 1 + pubKeySize, pubKey);
  return frame;
}

// Build CMD_GET_RADIO_SETTINGS frame
Uint8List buildGetRadioSettingsFrame() {
  return Uint8List.fromList([cmdGetRadioSettings]);
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
  // Symbol duration (Ts) in milliseconds
  final symbolDuration = (1 << spreadingFactor) / (bandwidthHz / 1000.0);

  // Preamble time
  final preambleTime = (preambleSymbols + 4.25) * symbolDuration;

  // Payload symbol count
  final headerBytes = explicitHeader ? 0 : 20;
  final crc = 1; // CRC enabled
  final de = lowDataRateOptimize ? 1 : 0;

  final numerator = 8 * payloadBytes - 4 * spreadingFactor + 28 + 16 * crc - headerBytes;
  final denominator = 4 * (spreadingFactor - 2 * de);
  var payloadSymbols = 8 + ((numerator / denominator).ceil()) * (codingRate + 4);

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
  final textBytes = utf8.encode(command);
  final timestamp = timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  const prefixSize = 6;
  final safeAttempt = attempt.clamp(0, 3);
  final frame = Uint8List(1 + 1 + 1 + 4 + prefixSize + textBytes.length + 1);
  int offset = 0;

  frame[offset++] = cmdSendTxtMsg;
  frame[offset++] = txtTypeCliData;
  frame[offset++] = safeAttempt;
  writeUint32LE(frame, offset, timestamp);
  offset += 4;

  frame.setRange(offset, offset + prefixSize, repeaterPubKey.sublist(0, prefixSize));
  offset += prefixSize;

  frame.setRange(offset, offset + textBytes.length, textBytes);
  frame[frame.length - 1] = 0; // null terminator
  return frame;
}

//Build a telemetry request frame
//Format: [cmd][pub_key x32][req_type][payload]
Uint8List buildSendBinaryReq(
  Uint8List repeaterPubKey,
  {
    int attempt = 0,
    int? timestampSeconds,
    Uint8List? payload,
  }) {
  int offset = 0;
  final frame = Uint8List(1 + 32 + 1 + (payload?.length ?? 0));
  frame[offset++] = cmdSendBinaryReq;
  frame.setRange(offset, offset + 32, repeaterPubKey);
  if (payload != null && payload.isNotEmpty) {
    offset += 32;
    frame.setRange(offset, offset + payload.length, payload);
  }
  return frame;
}