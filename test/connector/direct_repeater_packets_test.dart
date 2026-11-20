import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  final now = DateTime(2026, 11, 3, 12, 0, 0);

  DirectRepeater buildRepeater() => DirectRepeater(
    pubkeyPrefix: const [0xAB, 0xCD],
    pathHashWidth: 2,
    snr: -10,
    lastUpdated: now,
  );

  group('recordPacket', () {
    test('counts packets recorded inside the window', () {
      final repeater = buildRepeater();
      repeater.recordPacket(-5, at: now.subtract(const Duration(minutes: 2)));
      repeater.recordPacket(-7, at: now.subtract(const Duration(minutes: 5)));
      repeater.recordPacket(-9, at: now.subtract(const Duration(minutes: 5)));
      expect(repeater.packetCount, 3);
    });

    test('drops events older than the window', () {
      final repeater = buildRepeater();
      repeater.recordPacket(-5, at: now);
      repeater.recordPacket(-6, at: now.subtract(const Duration(minutes: 90)));
      expect(repeater.packetCount, 1);
    });

    test('caps stored samples at maxPacketSamples', () {
      final repeater = buildRepeater();
      final start = now.subtract(
        const Duration(minutes: DirectRepeater.packetWindowMinutes - 1),
      );
      for (var i = 0; i < DirectRepeater.maxPacketSamples + 10; i++) {
        repeater.recordPacket(
          -5,
          at: start.add(
            Duration(seconds: i ~/ 20, milliseconds: (i % 20) * 50),
          ),
        );
      }
      expect(repeater.packetCount, DirectRepeater.maxPacketSamples);
    });
  });

  group('recentEvents', () {
    test('returns events inside the window oldest first', () {
      final repeater = buildRepeater();
      repeater.recordPacket(-4, at: now.subtract(const Duration(minutes: 2)));
      repeater.recordPacket(-8, at: now.subtract(const Duration(minutes: 5)));

      final events = repeater.recentEvents(now: now);
      expect(events.length, 2);
      expect(events.first.at, now.subtract(const Duration(minutes: 5)));
      expect(events.first.snr, -8);
      expect(events.last.at, now.subtract(const Duration(minutes: 2)));
      expect(events.last.snr, -4);
    });

    test('ignores events outside the window', () {
      final repeater = buildRepeater();
      repeater.recordPacket(
        -5,
        at: now.subtract(
          const Duration(minutes: DirectRepeater.packetWindowMinutes + 5),
        ),
      );
      expect(repeater.recentEvents(now: now), isEmpty);
    });
  });
}
