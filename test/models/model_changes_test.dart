import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

// Builds a valid contact frame with the given pathLen and optional overrides.
// Frame layout: [respCode(1)][pubKey(32)][type(1)][flags(1)][pathLen(1)][path(64)][name(32)][timestamp(4)][lat(4)][lon(4)]
Uint8List _buildContactFrame({
  int pathLen = 0,
  Uint8List? pubKey,
  String name = 'TestNode',
}) {
  final writer = BytesBuilder();
  writer.addByte(respCodeContact); // 3
  writer.add(
    pubKey ?? Uint8List.fromList(List.generate(32, (i) => i + 1)),
  ); // valid pubkey
  writer.addByte(1); // type
  writer.addByte(0); // flags
  writer.addByte(pathLen);
  writer.add(Uint8List(64)); // path bytes (zeros)
  // name (32 bytes, null-padded)
  final nameBytes = Uint8List(32);
  final encoded = name.codeUnits;
  for (var i = 0; i < encoded.length && i < 31; i++) {
    nameBytes[i] = encoded[i];
  }
  writer.add(nameBytes);
  // timestamp (4 bytes LE) - some nonzero value
  writer.add(Uint8List.fromList([0x01, 0x00, 0x00, 0x00]));
  // lat, lon (4 bytes each)
  writer.add(Uint8List(4)); // lat
  writer.add(Uint8List(4)); // lon
  return Uint8List.fromList(writer.toBytes());
}

void main() {
  group('Contact.fromFrame — pathLen mapping', () {
    test('pathLen == 0 → pathLength == 0 (direct, NOT flood)', () {
      final frame = _buildContactFrame(pathLen: 0);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(0));
    });

    test('pathLen == 1 → pathLength == 1', () {
      final frame = _buildContactFrame(pathLen: 1);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(1));
    });

    test('pathLen == 64 (maxPathSize) → pathLength == 64', () {
      final frame = _buildContactFrame(pathLen: maxPathSize);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(maxPathSize));
    });

    test('pathLen == 0xFF → pathLength == -1 (flood)', () {
      final frame = _buildContactFrame(pathLen: 0xFF);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(-1));
    });

    test('pathLen == 65 (over maxPathSize) → pathLength == -1 (flood)', () {
      final frame = _buildContactFrame(pathLen: 65);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(-1));
    });
  });

  group('Contact.fromFrame — corrupt contact guards', () {
    test('all-zero public key → returns null', () {
      final zeroPubKey = Uint8List(32); // all zeros
      final frame = _buildContactFrame(pubKey: zeroPubKey);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNull);
    });

    test('mostly-zero public key (>16 zeros out of 32) → returns null', () {
      // 17 zeros out of 32 bytes exceeds pubKeySize ~/ 2 == 16
      final pubKey = Uint8List(32);
      pubKey[0] = 0xAB;
      pubKey[1] = 0xCD;
      pubKey[2] = 0xEF;
      pubKey[3] = 0x12;
      pubKey[4] = 0x34;
      pubKey[5] = 0x56;
      pubKey[6] = 0x78;
      pubKey[7] = 0x9A;
      pubKey[8] = 0xBC;
      pubKey[9] = 0xDE;
      pubKey[10] = 0xF0;
      pubKey[11] = 0x11;
      pubKey[12] = 0x22;
      pubKey[13] = 0x33;
      pubKey[14] = 0x44;
      // bytes 15–31 are zero: that is 17 zeros (indices 15..31 inclusive)
      final frame = _buildContactFrame(pubKey: pubKey);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNull);
    });

    test('valid public key (few zeros) → returns Contact', () {
      // Only 1 zero → well below the threshold
      final pubKey = Uint8List.fromList(List.generate(32, (i) => i + 1));
      pubKey[5] = 0; // one zero byte
      final frame = _buildContactFrame(pubKey: pubKey);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
    });

    test('name with all non-printable characters → returns null', () {
      // Build frame with a name composed entirely of control characters (< 0x20)
      final nameBytes = Uint8List(32);
      nameBytes[0] = 0x01;
      nameBytes[1] = 0x02;
      nameBytes[2] = 0x03;
      // remaining are 0x00 (null terminator ends the string after index 2,
      // so readCStringGreedy returns a 3-char string of non-printables)
      final writer = BytesBuilder();
      writer.addByte(respCodeContact);
      writer.add(Uint8List.fromList(List.generate(32, (i) => i + 1)));
      writer.addByte(1); // type
      writer.addByte(0); // flags
      writer.addByte(0); // pathLen
      writer.add(Uint8List(64)); // path
      writer.add(nameBytes);
      writer.add(Uint8List.fromList([0x01, 0x00, 0x00, 0x00])); // timestamp
      writer.add(Uint8List(4)); // lat
      writer.add(Uint8List(4)); // lon
      final frame = Uint8List.fromList(writer.toBytes());
      final contact = Contact.fromFrame(frame);
      expect(contact, isNull);
    });

    test('name with valid printable characters → returns Contact', () {
      final frame = _buildContactFrame(name: 'Alice');
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.name, equals('Alice'));
    });

    test(
      'name with mix of printable and replacement chars → returns Contact (not all bad)',
      () {
        // Build a name with mostly printable chars and one replacement char (0xFFFD in codeUnits).
        // utf8 allowMalformed: true maps invalid sequences to U+FFFD.
        // We embed one invalid UTF-8 byte (0x80) among valid ASCII bytes.
        // The decoded string will be "Hi\uFFFDThere" — not ALL bad, so should be accepted.
        final nameBytes = Uint8List(32);
        nameBytes[0] = 0x48; // 'H'
        nameBytes[1] = 0x69; // 'i'
        nameBytes[2] = 0x80; // invalid UTF-8 → decoded as U+FFFD
        nameBytes[3] = 0x54; // 'T'
        nameBytes[4] = 0x68; // 'h'
        nameBytes[5] = 0x65; // 'e'
        nameBytes[6] = 0x72; // 'r'
        nameBytes[7] = 0x65; // 'e'
        // rest are 0x00 (null terminator)
        final writer = BytesBuilder();
        writer.addByte(respCodeContact);
        writer.add(Uint8List.fromList(List.generate(32, (i) => i + 1)));
        writer.addByte(1); // type
        writer.addByte(0); // flags
        writer.addByte(0); // pathLen
        writer.add(Uint8List(64)); // path
        writer.add(nameBytes);
        writer.add(Uint8List.fromList([0x01, 0x00, 0x00, 0x00])); // timestamp
        writer.add(Uint8List(4)); // lat
        writer.add(Uint8List(4)); // lon
        final frame = Uint8List.fromList(writer.toBytes());
        final contact = Contact.fromFrame(frame);
        expect(contact, isNotNull);
      },
    );
  });

  group('PathRecord — routeWeight field', () {
    test('default routeWeight is 1.0', () {
      final record = PathRecord(
        hopCount: 2,
        tripTimeMs: 500,
        timestamp: DateTime(2024),
        wasFloodDiscovery: false,
        pathBytes: [0x01, 0x02],
        successCount: 1,
        failureCount: 0,
      );
      expect(record.routeWeight, equals(1.0));
    });

    test('custom routeWeight is preserved', () {
      final record = PathRecord(
        hopCount: 3,
        tripTimeMs: 800,
        timestamp: DateTime(2024),
        wasFloodDiscovery: false,
        pathBytes: [0x01],
        successCount: 5,
        failureCount: 2,
        routeWeight: 3.5,
      );
      expect(record.routeWeight, equals(3.5));
    });

    test('toJson includes route_weight', () {
      final record = PathRecord(
        hopCount: 1,
        tripTimeMs: 200,
        timestamp: DateTime(2024),
        wasFloodDiscovery: true,
        pathBytes: [],
        successCount: 0,
        failureCount: 0,
        routeWeight: 2.25,
      );
      final json = record.toJson();
      expect(json.containsKey('route_weight'), isTrue);
      expect(json['route_weight'], equals(2.25));
    });

    test('fromJson reads route_weight', () {
      final json = {
        'hop_count': 2,
        'trip_time_ms': 400,
        'timestamp': DateTime(2024).toIso8601String(),
        'was_flood': false,
        'path_bytes': [1, 2, 3],
        'success_count': 3,
        'failure_count': 1,
        'route_weight': 4.0,
      };
      final record = PathRecord.fromJson(json);
      expect(record.routeWeight, equals(4.0));
    });

    test(
      'fromJson with missing route_weight defaults to 1.0 (backward compat)',
      () {
        final json = {
          'hop_count': 1,
          'trip_time_ms': 100,
          'timestamp': DateTime(2024).toIso8601String(),
          'was_flood': false,
          'path_bytes': [],
          'success_count': 0,
          'failure_count': 0,
          // 'route_weight' intentionally omitted
        };
        final record = PathRecord.fromJson(json);
        expect(record.routeWeight, equals(1.0));
      },
    );
  });

  group('AppSettings — new fields', () {
    test('default values are correct', () {
      final settings = AppSettings();
      expect(settings.maxRouteWeight, equals(5.0));
      expect(settings.initialRouteWeight, equals(3.0));
      expect(settings.routeWeightSuccessIncrement, equals(0.5));
      expect(settings.routeWeightFailureDecrement, equals(0.2));
      expect(settings.maxMessageRetries, equals(5));
    });

    test('toJson includes all new fields', () {
      final settings = AppSettings();
      final json = settings.toJson();
      expect(json.containsKey('max_route_weight'), isTrue);
      expect(json.containsKey('initial_route_weight'), isTrue);
      expect(json.containsKey('route_weight_success_increment'), isTrue);
      expect(json.containsKey('route_weight_failure_decrement'), isTrue);
      expect(json.containsKey('max_message_retries'), isTrue);
      expect(json['max_route_weight'], equals(5.0));
      expect(json['initial_route_weight'], equals(3.0));
      expect(json['route_weight_success_increment'], equals(0.5));
      expect(json['route_weight_failure_decrement'], equals(0.2));
      expect(json['max_message_retries'], equals(5));
    });

    test('fromJson reads all new fields', () {
      final json = {
        'max_route_weight': 10.0,
        'initial_route_weight': 2.0,
        'route_weight_success_increment': 1.0,
        'route_weight_failure_decrement': 1.5,
        'max_message_retries': 8,
      };
      final settings = AppSettings.fromJson(json);
      expect(settings.maxRouteWeight, equals(10.0));
      expect(settings.initialRouteWeight, equals(2.0));
      expect(settings.routeWeightSuccessIncrement, equals(1.0));
      expect(settings.routeWeightFailureDecrement, equals(1.5));
      expect(settings.maxMessageRetries, equals(8));
    });

    test(
      'fromJson with missing new fields uses defaults (backward compat)',
      () {
        // Simulate an old settings JSON with none of the new fields
        final json = <String, dynamic>{};
        final settings = AppSettings.fromJson(json);
        expect(settings.maxRouteWeight, equals(5.0));
        expect(settings.initialRouteWeight, equals(3.0));
        expect(settings.routeWeightSuccessIncrement, equals(0.5));
        expect(settings.routeWeightFailureDecrement, equals(0.2));
        expect(settings.maxMessageRetries, equals(5));
      },
    );

    test('copyWith works for maxRouteWeight', () {
      final settings = AppSettings();
      final updated = settings.copyWith(maxRouteWeight: 8.0);
      expect(updated.maxRouteWeight, equals(8.0));
      // Other fields should be unchanged
      expect(updated.initialRouteWeight, equals(settings.initialRouteWeight));
      expect(updated.maxMessageRetries, equals(settings.maxMessageRetries));
    });

    test('copyWith works for initialRouteWeight', () {
      final settings = AppSettings();
      final updated = settings.copyWith(initialRouteWeight: 3.0);
      expect(updated.initialRouteWeight, equals(3.0));
      expect(updated.maxRouteWeight, equals(settings.maxRouteWeight));
    });

    test('copyWith works for routeWeightSuccessIncrement', () {
      final settings = AppSettings();
      final updated = settings.copyWith(routeWeightSuccessIncrement: 0.25);
      expect(updated.routeWeightSuccessIncrement, equals(0.25));
      expect(
        updated.routeWeightFailureDecrement,
        equals(settings.routeWeightFailureDecrement),
      );
    });

    test('copyWith works for routeWeightFailureDecrement', () {
      final settings = AppSettings();
      final updated = settings.copyWith(routeWeightFailureDecrement: 0.75);
      expect(updated.routeWeightFailureDecrement, equals(0.75));
      expect(
        updated.routeWeightSuccessIncrement,
        equals(settings.routeWeightSuccessIncrement),
      );
    });

    test('copyWith works for maxMessageRetries', () {
      final settings = AppSettings();
      final updated = settings.copyWith(maxMessageRetries: 10);
      expect(updated.maxMessageRetries, equals(10));
      expect(updated.maxRouteWeight, equals(settings.maxRouteWeight));
    });
  });
}
