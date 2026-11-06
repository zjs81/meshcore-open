import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/network_map/network_map_records.dart';
import 'package:meshcore_open/services/network_map/network_map_upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

NetworkMapPacketRecord _packet(int t) => NetworkMapPacketRecord(
  t: t,
  pt: 5,
  rt: 1,
  hw: 1,
  path: 'a1b2c3',
  snr: 7.25,
  rssi: -92,
  size: 48,
  h: '0123456789abcdef',
  scoped: false,
);

NetworkMapAdvertRecord _advert(int t, String key) => NetworkMapAdvertRecord(
  t: t,
  key: key,
  type: 2,
  name: 'Hilltop RPT',
  loc: const NetworkMapLoc(33.47, -112.068234),
  hidden: false,
  snr: 9.5,
  rssi: -80,
  rt: 1,
  hw: 1,
  path: 'a1',
);

void main() {
  group('upload body', () {
    test('matches the contract field-for-field', () {
      final body = buildUploadBody(
        installId: 'AAAAAAAAAAAAAAAAAAAAAA',
        app: 'meshcore-open/9.5.0',
        loc: NetworkMapLoc.snapped(33.448376, -112.074036),
        preset: NetworkMapPreset.fromRadio(
          freqKhz: 910525,
          bwHz: 62500,
          sf: 7,
          cr: 5,
        ),
        listenSeconds: 60,
        packets: [_packet(1791770400)],
        adverts: [_advert(1791770400, 'ab' * 32)],
      );
      final decoded =
          jsonDecode(jsonEncode(body)) as Map<String, dynamic>; // round trip
      expect(decoded, {
        'v': 1,
        'installId': 'AAAAAAAAAAAAAAAAAAAAAA',
        'token': null,
        'app': 'meshcore-open/9.5.0',
        'loc': {'lat': 33.45, 'lon': -112.080261},
        'preset': {'freqKhz': 910525, 'bwKhz': 62.5, 'sf': 7, 'cr': 5},
        'listenSeconds': 60,
        'packets': [
          {
            't': 1791770400,
            'pt': 5,
            'rt': 1,
            'hw': 1,
            'path': 'a1b2c3',
            'snr': 7.25,
            'rssi': -92,
            'size': 48,
            'h': '0123456789abcdef',
            'scoped': false,
          },
        ],
        'adverts': [
          {
            't': 1791770400,
            'key': 'ab' * 32,
            'type': 2,
            'name': 'Hilltop RPT',
            'loc': {'lat': 33.47, 'lon': -112.068234},
            'hidden': false,
            'snr': 9.5,
            'rssi': -80,
            'rt': 1,
            'hw': 1,
            'path': 'a1',
          },
        ],
      });
    });

    test('heartbeat has null loc/preset and empty lists', () {
      final body = buildUploadBody(
        installId: 'x',
        app: 'meshcore-open',
        loc: null,
        preset: null,
        listenSeconds: 900,
        packets: const [],
        adverts: const [],
      );
      expect(body['loc'], isNull);
      expect(body['preset'], isNull);
      expect(body['listenSeconds'], 600);
      expect(body['packets'], isEmpty);
      expect(body['adverts'], isEmpty);
    });

    test('preset maps radio units and rejects unknown values', () {
      final preset = NetworkMapPreset.fromRadio(
        freqKhz: 869525,
        bwHz: 250000,
        sf: 11,
        cr: 1,
      )!;
      expect(preset.toJson(), {
        'freqKhz': 869525,
        'bwKhz': 250,
        'sf': 11,
        'cr': 5,
      });
      expect(
        NetworkMapPreset.fromRadio(
          freqKhz: 869525,
          bwHz: 41700,
          sf: 8,
          cr: 8,
        )!.bwKhz,
        41.7,
      );
      expect(
        NetworkMapPreset.fromRadio(freqKhz: 869525, bwHz: 12345, sf: 7, cr: 5),
        isNull,
      );
      expect(
        NetworkMapPreset.fromRadio(freqKhz: 50, bwHz: 62500, sf: 7, cr: 5),
        isNull,
      );
      expect(NetworkMapPreset.fromRadio(), isNull);
    });
  });

  group('install ID', () {
    test('random, 16 bytes, rotated every 24 h', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime(2026, 10, 11, 12);
      final installId = NetworkMapInstallId(prefs, now: () => now);

      final first = installId.current();
      expect(first.contains('='), isFalse);
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(first), isTrue);
      expect(base64Url.decode('$first=='), hasLength(16));

      now = now.add(const Duration(hours: 23, minutes: 59));
      expect(installId.current(), first);

      now = now.add(const Duration(minutes: 2));
      final second = installId.current();
      expect(second, isNot(first));
      expect(base64Url.decode('$second=='), hasLength(16));

      now = now.add(const Duration(hours: 1));
      expect(installId.current(), second);
    });
  });

  group('upload queue', () {
    final now = DateTime.utc(2026, 10, 11, 18, 41, 30);
    final minute = networkMapMinute(now);

    test('batches respect the contract caps', () {
      final queue = NetworkMapUploadQueue();
      for (var i = 0; i < 2500; i++) {
        queue.addPacket(_packet(minute), now);
      }
      for (var i = 0; i < 250; i++) {
        queue.addAdvert(
          _advert(minute, i.toRadixString(16).padLeft(64, '0')),
          now,
        );
      }
      final batch = queue.peekBatch();
      expect(batch.packets, hasLength(2000));
      expect(batch.adverts, hasLength(200));

      queue.remove(batch.packets.length, batch.adverts.length);
      final rest = queue.peekBatch();
      expect(rest.packets, hasLength(500));
      expect(rest.adverts, hasLength(50));
    });

    test('one advert per key is kept', () {
      final queue = NetworkMapUploadQueue();
      queue.addAdvert(_advert(minute - 60, 'a' * 64), now);
      queue.addAdvert(_advert(minute, 'a' * 64), now);
      expect(queue.advertCount, 1);
      expect(queue.peekBatch().adverts.single.t, minute);
    });

    test('drops data the server would reject or older than an hour', () {
      final queue = NetworkMapUploadQueue();
      queue.addPacket(_packet(minute), now);
      queue.addPacket(_packet(minute - 61 * 60), now);
      queue.addPacket(
        _packet(minute),
        now.subtract(const Duration(hours: 1, minutes: 1)),
      );
      queue.dropExpired(now);
      expect(queue.packetCount, 1);
      expect(queue.peekBatch().packets.single.t, minute);
    });
  });
}
