import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/cayenne_lpp.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/services/telemetry_location_request.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _contactFrame(
  Uint8List key, {
  required int advertTimestamp,
  required double lat,
  required double lon,
  int type = advTypeChat,
}) {
  final data = ByteData(1 + 32 + 3 + 64 + 32 + 4 + 12);
  final bytes = data.buffer.asUint8List();
  bytes[0] = respCodeContact;
  bytes.setRange(1, 33, key);
  bytes[33] = type;
  bytes[35] = 0xFF; // path unknown
  bytes.setRange(100, 103, 'Bob'.codeUnits);
  data.setUint32(132, advertTimestamp, Endian.little);
  data.setInt32(136, (lat * 1e6).round(), Endian.little);
  data.setInt32(140, (lon * 1e6).round(), Endian.little);
  return bytes;
}

Uint8List _sentFrame(int tag) {
  final data = ByteData(10);
  data.setUint8(0, respCodeSent);
  data.setUint32(2, tag, Endian.little);
  data.setUint32(6, 5000, Endian.little); // est. timeout ms
  return data.buffer.asUint8List();
}

/// A sensor's binary telemetry reply carrying a Cayenne LPP GPS fix.
Uint8List _gpsResponse(int tag, double lat, double lon) {
  int24(double v) {
    final n = v.round() & 0xFFFFFF;
    return [(n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF];
  }

  final tagBytes = ByteData(4)..setUint32(0, tag, Endian.little);
  return Uint8List.fromList([
    pushCodeBinaryResponse,
    0,
    ...tagBytes.buffer.asUint8List(),
    1,
    CayenneLpp.lppGps,
    ...int24(lat * 10000),
    ...int24(lon * 10000),
    ...int24(0),
  ]);
}

/// Replays radio traffic around a telemetry request: an unrelated send ack
/// arrives while the path is prepared, then the request's own ack and reply.
class _RadioConnector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<PathSelection> preparePathForContactSend(Contact contact) async {
    handleFrameForTest(_sentFrame(111)); // a background retry's ack
    return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
  }

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
    bool waitForGenericAck = false,
  }) async {
    handleFrameForTest(_sentFrame(222));
    handleFrameForTest(_gpsResponse(222, 45.5, -122.6));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

  test('telemetry fix survives a refresh of the same advert', () {
    final connector = MeshCoreConnector();
    final frame = _contactFrame(
      key,
      advertTimestamp: 1700000000,
      lat: 10,
      lon: 20,
    );
    connector.handleFrameForTest(frame);
    final keyHex = connector.contacts.single.publicKeyHex;

    connector.updateContactLocationFromTelemetry(keyHex, 11.5, 21.5);
    final fixed = connector.contacts.single;
    expect(fixed.latitude, 11.5);
    expect(fixed.longitude, 21.5);
    // lastSeen stays the advert time the radio holds (path and flag writes
    // send it back); the fix only moves lastHeard.
    final advertTime = DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000);
    expect(fixed.lastSeen, advertTime);
    expect(fixed.lastHeard.isAfter(advertTime), isTrue);

    connector.handleFrameForTest(frame);
    final refreshed = connector.contacts.single;
    expect(refreshed.latitude, 11.5);
    expect(refreshed.longitude, 21.5);
    expect(refreshed.lastSeen, advertTime);
    expect(refreshed.telemetryFixAt, fixed.telemetryFixAt);
  });

  test('telemetry fix survives a full contact sync', () {
    final connector = MeshCoreConnector();
    final frame = _contactFrame(
      key,
      advertTimestamp: 1700000000,
      lat: 10,
      lon: 20,
    );
    connector.handleFrameForTest(frame);
    final keyHex = connector.contacts.single.publicKeyHex;
    connector.updateContactLocationFromTelemetry(keyHex, 11.5, 21.5);

    // A full sync clears the list on CONTACTS_START and the radio resends
    // the same advert record.
    connector.handleFrameForTest([respCodeContactsStart]);
    expect(connector.contacts, isEmpty);
    connector.handleFrameForTest(frame);
    connector.handleFrameForTest([respCodeEndOfContacts]);

    final contact = connector.contacts.single;
    expect(contact.latitude, 11.5);
    expect(contact.longitude, 21.5);
    expect(contact.telemetryFixAt, isNotNull);
  });

  test('a newer advert replaces the telemetry fix', () {
    final connector = MeshCoreConnector();
    connector.handleFrameForTest(
      _contactFrame(key, advertTimestamp: 1700000000, lat: 10, lon: 20),
    );
    final keyHex = connector.contacts.single.publicKeyHex;
    connector.updateContactLocationFromTelemetry(keyHex, 11.5, 21.5);

    connector.handleFrameForTest(
      _contactFrame(key, advertTimestamp: 1700000100, lat: 12, lon: 22),
    );
    final contact = connector.contacts.single;
    expect(contact.latitude, 12);
    expect(contact.longitude, 22);
    expect(contact.telemetryFixAt, isNull);
  });

  test('a send ack during path preparation is not taken as ours', () async {
    final connector = _RadioConnector();
    connector.handleFrameForTest(
      _contactFrame(
        key,
        advertTimestamp: 1700000000,
        lat: 10,
        lon: 20,
        type: advTypeSensor,
      ),
    );
    final sensor = connector.contacts.single;

    final result = await requestTelemetryLocation(connector, sensor);

    expect(result, TelemetryLocationResult.located);
    expect(connector.contacts.single.latitude, closeTo(45.5, 1e-4));
    expect(connector.contacts.single.longitude, closeTo(-122.6, 1e-4));
  });

  test('telemetryGpsFix skips missing and null-island fixes', () {
    expect(telemetryGpsFix([]), isNull);
    expect(
      telemetryGpsFix([
        {
          'channel': 1,
          'values': {
            'gps': {'latitude': 0.0, 'longitude': 0.0, 'altitude': 0.0},
          },
        },
      ]),
      isNull,
    );
    expect(
      telemetryGpsFix([
        {
          'channel': 1,
          'values': {'voltage': 4.1},
        },
        {
          'channel': 2,
          'values': {
            'gps': {'latitude': 45.5, 'longitude': -122.6, 'altitude': 10.0},
          },
        },
      ]),
      (latitude: 45.5, longitude: -122.6),
    );
  });
}
