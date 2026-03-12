import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/widgets/battery_indicator.dart';

void main() {
  group('parseBatteryStatusPacket', () {
    test('parses battery percentage and optional storage fields', () {
      final frame = Uint8List.fromList(<int>[
        respCodeBattAndStorage,
        75,
        0,
        0x34,
        0x12,
        0x00,
        0x00,
        0x78,
        0x56,
        0x00,
        0x00,
      ]);

      final packet = parseBatteryStatusPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.levelPercent, 75);
      expect(packet.usedStorageKb, 0x1234);
      expect(packet.totalStorageKb, 0x5678);
    });

    test('parses the minimal battery frame without storage fields', () {
      final frame = Uint8List.fromList(<int>[
        respCodeBattAndStorage,
        50,
        0,
      ]);

      final packet = parseBatteryStatusPacket(frame);

      expect(packet, isNotNull);
      expect(packet!.levelPercent, 50);
      expect(packet.usedStorageKb, isNull);
      expect(packet.totalStorageKb, isNull);
    });
  });

  testWidgets('BatteryIndicator renders percentage when voltage is unavailable', (
    tester,
  ) async {
    final connector = _FakeConnector(63);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BatteryIndicator(connector: connector),
        ),
      ),
    );

    expect(find.text('63%'), findsOneWidget);
  });
}

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector(this._batteryPercent);

  final int _batteryPercent;

  @override
  int? get batteryPercent => _batteryPercent;

  @override
  int? get batteryMillivolts => null;
}
