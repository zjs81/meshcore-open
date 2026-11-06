import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('batches listener updates without dropping captured frames', () async {
    final service = BleDebugLogService();
    addTearDown(service.dispose);
    var notifications = 0;
    service.addListener(() => notifications++);
    final frame = Uint8List.fromList([respCodeOk]);

    for (var index = 0; index < 120; index++) {
      service.logFrame(frame, outgoing: false);
    }

    expect(service.entries, hasLength(120));
    expect(notifications, 0);
    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(service.entries, hasLength(120));
    expect(notifications, 1);
  });

  test('retains the entry cap and notifies clear once per batch', () async {
    final service = BleDebugLogService();
    addTearDown(service.dispose);
    var notifications = 0;
    service.addListener(() => notifications++);
    final frame = Uint8List.fromList([respCodeOk]);

    for (var index = 0; index < BleDebugLogService.maxEntries + 40; index++) {
      service.logFrame(frame, outgoing: true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(service.entries, hasLength(BleDebugLogService.maxEntries));
    expect(notifications, 1);

    service.clear();
    expect(service.entries, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(notifications, 2);
  });

  test('does not schedule listener notifications without listeners', () async {
    final service = BleDebugLogService();
    addTearDown(service.dispose);
    service.logFrame(Uint8List.fromList([respCodeOk]), outgoing: false);

    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(service.entries, hasLength(1));
  });

  test('zero notify interval preserves immediate debug-log notifications', () {
    final service = BleDebugLogService(notifyInterval: Duration.zero);
    addTearDown(service.dispose);
    var notifications = 0;
    service.addListener(() => notifications++);

    service.logFrame(Uint8List.fromList([respCodeOk]), outgoing: false);

    expect(notifications, 1);
  });

  test('dispose cancels a pending batched notification', () async {
    final service = BleDebugLogService();
    var notifications = 0;
    service.addListener(() => notifications++);
    service.logFrame(Uint8List.fromList([respCodeOk]), outgoing: false);

    service.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(notifications, 0);
  });

  test('raw RX entries keep only the packet bytes from log-data frames', () {
    final service = BleDebugLogService();
    addTearDown(service.dispose);
    service.logFrame(
      Uint8List.fromList([respCodeOk, 1, 2, 3, 4]),
      outgoing: false,
    );
    expect(service.rawLogRxEntries, isEmpty);

    service.logFrame(
      Uint8List.fromList([pushCodeLogRxData, 1, 2, 0xA1, 0xB2]),
      outgoing: false,
    );
    expect(service.rawLogRxEntries, hasLength(1));
    expect(service.rawLogRxEntries.single.payload, <int>[0xA1, 0xB2]);
  });

  test('raw RX entries enforce their own oldest-first cap', () {
    final service = BleDebugLogService();
    addTearDown(service.dispose);

    for (var index = 0; index < BleDebugLogService.maxEntries + 3; index++) {
      service.logFrame(
        Uint8List.fromList([
          pushCodeLogRxData,
          0,
          0,
          index & 0xFF,
          (index >> 8) & 0xFF,
        ]),
        outgoing: false,
      );
    }

    expect(service.rawLogRxEntries, hasLength(BleDebugLogService.maxEntries));
    expect(service.rawLogRxEntries.first.payload, <int>[3, 0]);
    expect(service.rawLogRxEntries.last.payload, <int>[0xF6, 0x01]);
  });
}
