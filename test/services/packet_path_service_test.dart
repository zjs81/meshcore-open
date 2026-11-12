import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/packet_path.dart';
import 'package:meshcore_open/services/packet_path_service.dart';
import 'package:meshcore_open/services/storage_service.dart';

/// In-memory stand-in for the prefs-backed observed-path storage.
class FakePacketStorage extends StorageService {
  List<ObservedPath>? stored;

  @override
  Future<void> saveObservedPaths(List<ObservedPath> paths) async {
    stored = List.of(paths);
  }

  @override
  Future<List<ObservedPath>> loadObservedPaths() async {
    return stored == null ? const [] : List.of(stored!);
  }
}

void main() {
  group('PacketPathService', () {
    test('records and merges repeats of the same path', () async {
      final storage = FakePacketStorage();
      final service = PacketPathService(storage);
      await service.initialize();

      final t0 = DateTime.now().subtract(const Duration(hours: 2));
      final t1 = DateTime.now();
      service.record([0xAA, 0xBB, 0x11, 0x22], 2, seenAt: t0);
      service.record([0xAA, 0xBB, 0x11, 0x22], 2, seenAt: t1);
      service.record([0xAA, 0xBB, 0x11, 0x22], 2);

      final paths = service.pathsWithin(const Duration(days: 30));
      expect(paths, hasLength(1));
      expect(paths.single.count, 3);
      expect(paths.single.firstSeenMs, t0.millisecondsSinceEpoch);
      expect(
        paths.single.lastSeenMs,
        greaterThanOrEqualTo(t1.millisecondsSinceEpoch),
      );

      service.dispose();
    });

    test('pathsWithin excludes records older than the window', () async {
      final storage = FakePacketStorage();
      final service = PacketPathService(storage);
      await service.initialize();

      final old = DateTime.now().subtract(const Duration(days: 20));
      final recent = DateTime.now().subtract(const Duration(hours: 1));
      service.record([0x01, 0x02], 1, seenAt: old);
      service.record([0x03, 0x04], 1, seenAt: recent);

      final twoWeeks = service.pathsWithin(const Duration(days: 14));
      expect(twoWeeks, hasLength(1));
      expect(twoWeeks.single.pathBytes, [0x03, 0x04]);

      final month = service.pathsWithin(const Duration(days: 30));
      expect(month, hasLength(2));

      service.dispose();
    });

    test('records arriving before load are merged after loading', () async {
      final storage = FakePacketStorage();
      final service = PacketPathService(storage);

      // Recorded before initialize() — queued until the store is read.
      service.record([0xAA, 0xBB], 1);
      await service.initialize();

      final paths = service.pathsWithin(const Duration(minutes: 5));
      expect(paths, hasLength(1));

      service.dispose();
    });

    test('setDevicePublicKey reloads from the scoped store', () async {
      final storage = FakePacketStorage();
      final service = PacketPathService(storage);
      await service.initialize();
      service.record([0xAA, 0xBB], 1);
      await service.flushPendingWrites();
      final saved = storage.stored!;
      expect(saved, hasLength(1));

      service.setDevicePublicKey('abcd0123456789ab');
      await Future<void>.delayed(Duration.zero);
      // The cache is dropped and reloaded from the store on radio switch.
      expect(service.pathsWithin(const Duration(days: 30)), hasLength(1));

      service.dispose();
    });

    test('drops records past the record cap keeping the newest', () async {
      final storage = FakePacketStorage();
      final service = PacketPathService(storage);
      await service.initialize();

      final now = DateTime.now();
      for (var i = 0; i < PacketPathService.maxRecords + 5; i++) {
        service.record(
          [i & 0xFF, (i >> 8) & 0xFF, (i >> 16) & 0xFF],
          1,
          seenAt: now.subtract(Duration(minutes: i)),
        );
      }

      final paths = service.pathsWithin(const Duration(days: 30));
      expect(paths.length, lessThanOrEqualTo(PacketPathService.maxRecords));
      // The newest path survives.
      expect(paths.first.pathBytes, [0x00, 0x00, 0]);

      service.dispose();
    });
  });
}
