import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import '../utils/app_logger.dart';

/// Parsed `RESP_CODE_STATS` + `STATS_TYPE_RADIO` (14 bytes total).
class CompanionRadioStats {
  final int noiseFloorDbm;
  final int lastRssiDbm;
  final double lastSnrDb;
  final int txAirSecs;
  final int rxAirSecs;
  final DateTime receivedAt;

  const CompanionRadioStats({
    required this.noiseFloorDbm,
    required this.lastRssiDbm,
    required this.lastSnrDb,
    required this.txAirSecs,
    required this.rxAirSecs,
    required this.receivedAt,
  });

  static CompanionRadioStats? tryParse(Uint8List frame) {
    if (frame.length < 14) return null;
    if (frame[0] != respCodeStats || frame[1] != statsTypeRadio) return null;
    try {
      final reader = BufferReader(frame);
      reader.skipBytes(2);
      final noise = reader.readInt16LE();
      final rssi = reader.readInt8();
      final snrRaw = reader.readInt8();
      final txAir = reader.readUInt32LE();
      final rxAir = reader.readUInt32LE();
      return CompanionRadioStats(
        noiseFloorDbm: noise,
        lastRssiDbm: rssi,
        lastSnrDb: snrRaw / 4.0,
        txAirSecs: txAir,
        rxAirSecs: rxAir,
        receivedAt: DateTime.now(),
      );
    } catch (e) {
      appLogger.warn('CompanionRadioStats parse error: $e');
      return null;
    }
  }
}
