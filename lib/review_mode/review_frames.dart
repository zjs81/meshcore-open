import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';

/// Pure builders for the radio-to-app companion frames the connector parses.
class ReviewFrames {
  ReviewFrames._();

  /// ERR_CODE_NOT_FOUND in the companion firmware.
  static const int errNotFound = 2;
  static const int errUnsupported = 1;

  static Uint8List ok() => Uint8List.fromList([respCodeOk]);

  static Uint8List err([int code = errUnsupported]) =>
      Uint8List.fromList([respCodeErr, code]);

  static Uint8List selfInfo({
    required Uint8List publicKey,
    required String name,
    required int latitudeE6,
    required int longitudeE6,
    required int frequencyHz,
    required int bandwidthHz,
    required int spreadingFactor,
    required int codingRate,
    required int txPowerDbm,
    required int maxTxPowerDbm,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeSelfInfo);
    writer.writeByte(advTypeChat);
    writer.writeByte(txPowerDbm);
    writer.writeByte(maxTxPowerDbm);
    writer.writeBytes(publicKey);
    writer.writeInt32LE(latitudeE6);
    writer.writeInt32LE(longitudeE6);
    writer.writeByte(0); // multi_acks
    writer.writeByte(0); // advert_loc_policy
    writer.writeByte(0); // telemetry modes
    writer.writeByte(
      1,
    ); // manual_add_contacts: 1 = auto-add controlled by flags
    writer.writeUInt32LE(frequencyHz);
    writer.writeUInt32LE(bandwidthHz);
    writer.writeByte(spreadingFactor);
    writer.writeByte(codingRate);
    writer.writeString(name);
    writer.writeByte(0);
    return writer.toBytes();
  }

  static Uint8List deviceInfo({
    required int firmwareVerCode,
    required int maxContacts,
    required int maxChannels,
    String manufacturer = 'MeshCore Open Review',
    String version = 'review',
    bool clientRepeat = false,
    int pathHashMode = 0,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeDeviceInfo);
    writer.writeByte(firmwareVerCode);
    writer.writeByte(maxContacts ~/ 2);
    writer.writeByte(maxChannels);
    writer.writeUInt32LE(0); // ble pin, bytes 4..7
    writer.writeCString('', 12); // build date, bytes 8..19
    writer.writeCString(manufacturer, 40); // bytes 20..59
    writer.writeCString(version, 20); // bytes 60..79
    writer.writeByte(clientRepeat ? 1 : 0); // byte 80
    writer.writeByte(pathHashMode); // byte 81
    return writer.toBytes();
  }

  static Uint8List contactsStart(int count) {
    final writer = BufferWriter();
    writer.writeByte(respCodeContactsStart);
    writer.writeUInt32LE(count);
    return writer.toBytes();
  }

  static Uint8List contact({
    required Uint8List publicKey,
    required int type,
    required Uint8List path,
    required String name,
    required int lastAdvertSecs,
    required int latitudeE6,
    required int longitudeE6,
    required int lastModSecs,
    int flags = 0,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeContact);
    writer.writeBytes(publicKey);
    writer.writeByte(type);
    writer.writeByte(flags);
    writer.writeByte(path.length); // one-byte hashes: hop count == byte count
    writer.writeBytesPadded(path, maxPathSize);
    writer.writeCString(name, maxNameSize);
    writer.writeUInt32LE(lastAdvertSecs);
    writer.writeInt32LE(latitudeE6);
    writer.writeInt32LE(longitudeE6);
    writer.writeUInt32LE(lastModSecs);
    return writer.toBytes();
  }

  static Uint8List endOfContacts(int mostRecentLastModSecs) {
    final writer = BufferWriter();
    writer.writeByte(respCodeEndOfContacts);
    writer.writeUInt32LE(mostRecentLastModSecs);
    return writer.toBytes();
  }

  static Uint8List channelInfo({
    required int index,
    required String name,
    required Uint8List psk,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeChannelInfo);
    writer.writeByte(index);
    writer.writeCString(name, 32);
    writer.writeBytesPadded(psk, 16);
    return writer.toBytes();
  }

  static Uint8List contactMessage({
    required Uint8List senderPublicKey,
    required String text,
    required int timestampSecs,
    int pathLen = 0xFF,
    int snrQuarterDb = 24,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeContactMsgRecvV3);
    writer.writeByte(snrQuarterDb & 0xFF);
    writer.writeByte(0);
    writer.writeByte(0);
    writer.writeBytes(Uint8List.fromList(senderPublicKey.sublist(0, 6)));
    writer.writeByte(pathLen);
    writer.writeByte(txtTypePlain);
    writer.writeUInt32LE(timestampSecs);
    writer.writeString(text);
    writer.writeByte(0);
    return writer.toBytes();
  }

  /// The on-air text is `sender: message`.
  static Uint8List channelMessage({
    required int channelIndex,
    required String sender,
    required String message,
    required int timestampSecs,
    Uint8List? path,
    int snrQuarterDb = 24,
  }) {
    final hasPath = path != null && path.isNotEmpty;
    final writer = BufferWriter();
    writer.writeByte(respCodeChannelMsgRecvV3);
    writer.writeByte(snrQuarterDb & 0xFF);
    writer.writeByte(hasPath ? 1 : 0);
    writer.writeByte(0);
    writer.writeByte(channelIndex);
    writer.writeByte(hasPath ? path.length : 0xFF);
    if (hasPath) writer.writeBytes(path);
    writer.writeByte(txtTypePlain);
    writer.writeUInt32LE(timestampSecs);
    writer.writeString('$sender: $message');
    writer.writeByte(0);
    return writer.toBytes();
  }

  static Uint8List sent({
    required bool flood,
    required int ackHash,
    required int timeoutMs,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeSent);
    writer.writeByte(flood ? 1 : 0);
    writer.writeUInt32LE(ackHash);
    writer.writeUInt32LE(timeoutMs);
    return writer.toBytes();
  }

  static Uint8List sendConfirmed({
    required int ackHash,
    required int tripTimeMs,
  }) {
    final writer = BufferWriter();
    writer.writeByte(pushCodeSendConfirmed);
    writer.writeUInt32LE(ackHash);
    writer.writeUInt32LE(tripTimeMs);
    return writer.toBytes();
  }

  /// [code][permissions][pub_key_prefix x6][server_time x4][acl][fw_level].
  static Uint8List loginSuccess({
    required Uint8List publicKey,
    required int serverTimeSecs,
    int permissions = 0,
  }) {
    final writer = BufferWriter();
    writer.writeByte(pushCodeLoginSuccess);
    writer.writeByte(permissions);
    writer.writeBytes(Uint8List.fromList(publicKey.sublist(0, 6)));
    writer.writeUInt32LE(serverTimeSecs);
    writer.writeByte(0); // ACL permissions
    writer.writeByte(0); // firmware version level
    return writer.toBytes();
  }

  /// [code][reserved][pub_key_prefix x6].
  static Uint8List loginFail({required Uint8List publicKey}) {
    final writer = BufferWriter();
    writer.writeByte(pushCodeLoginFail);
    writer.writeByte(0);
    writer.writeBytes(Uint8List.fromList(publicKey.sublist(0, 6)));
    return writer.toBytes();
  }

  static Uint8List msgWaiting() => Uint8List.fromList([pushCodeMsgWaiting]);

  static Uint8List noMoreMessages() =>
      Uint8List.fromList([respCodeNoMoreMessages]);

  static Uint8List battAndStorage({
    required int millivolts,
    required int usedKb,
    required int totalKb,
  }) {
    final writer = BufferWriter();
    writer.writeByte(respCodeBattAndStorage);
    writer.writeUInt16LE(millivolts);
    writer.writeUInt32LE(usedKb);
    writer.writeUInt32LE(totalKb);
    return writer.toBytes();
  }

  static Uint8List currTime(int epochSecs) {
    final writer = BufferWriter();
    writer.writeByte(respCodeCurrTime);
    writer.writeUInt32LE(epochSecs);
    return writer.toBytes();
  }

  /// [vars] is the comma separated "key:value" list the connector parses.
  static Uint8List customVars(String vars) {
    final writer = BufferWriter();
    writer.writeByte(respCodeCustomVars);
    writer.writeString(vars);
    writer.writeByte(0);
    return writer.toBytes();
  }

  static Uint8List autoAddConfig({required int flags, int maxHops = 0}) =>
      Uint8List.fromList([respCodeAutoAddConfig, flags, maxHops]);

  static Uint8List allowedRepeatFreq(List<RepeatFreqRange> ranges) {
    final writer = BufferWriter();
    writer.writeByte(respCodeAllowedRepeatFreq);
    for (final range in ranges) {
      writer.writeUInt32LE(range.lowKHz);
      writer.writeUInt32LE(range.highKHz);
    }
    return writer.toBytes();
  }

  /// STATS_TYPE_RADIO: [24][1][noise i16][rssi i8][snr*4 i8][tx u32][rx u32].
  static Uint8List radioStats({
    required int noiseFloorDbm,
    required int lastRssiDbm,
    required int lastSnrQuarterDb,
    required int txAirSecs,
    required int rxAirSecs,
  }) {
    final data = ByteData(14);
    data.setUint8(0, respCodeStats);
    data.setUint8(1, statsTypeRadio);
    data.setInt16(2, noiseFloorDbm, Endian.little);
    data.setInt8(4, lastRssiDbm);
    data.setInt8(5, lastSnrQuarterDb);
    data.setUint32(6, txAirSecs, Endian.little);
    data.setUint32(10, rxAirSecs, Endian.little);
    return data.buffer.asUint8List();
  }
}
