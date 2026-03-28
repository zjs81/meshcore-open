import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/companion_radio_stats.dart';

void main() {
  test('CompanionRadioStats.tryParse golden 14-byte radio frame', () {
    // noise -90 (0xA6FF LE), rssi -70 (0xBA), snr raw 8 -> 2.0 dB,
    // tx_air 1000 LE, rx_air 2000 LE
    final frame = Uint8List.fromList([
      respCodeStats,
      statsTypeRadio,
      0xA6,
      0xFF,
      0xBA,
      0x08,
      0xE8,
      0x03,
      0x00,
      0x00,
      0xD0,
      0x07,
      0x00,
      0x00,
    ]);
    final s = CompanionRadioStats.tryParse(frame);
    expect(s, isNotNull);
    expect(s!.noiseFloorDbm, -90);
    expect(s.lastRssiDbm, -70);
    expect(s.lastSnrDb, 2.0);
    expect(s.txAirSecs, 1000);
    expect(s.rxAirSecs, 2000);
  });

  test('CompanionRadioStats.tryParse rejects short frame', () {
    expect(CompanionRadioStats.tryParse(Uint8List(10)), isNull);
  });
}
