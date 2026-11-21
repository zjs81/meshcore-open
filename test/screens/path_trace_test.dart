import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'dart:typed_data';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/models/path_history.dart';

class _FakeStorageService extends StorageService {
  @override
  Future<void> savePathHistory(
    String contactPubKeyHex,
    ContactPathHistory history,
  ) async {}
  @override
  Future<ContactPathHistory?> loadPathHistory(String contactPubKeyHex) async =>
      null;
  @override
  Future<void> clearPathHistory(String contactPubKeyHex) async {}
}

class _FakeMeshCoreConnector extends MeshCoreConnector {
  final StreamController<Uint8List> _receivedFramesController =
      StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get receivedFrames => _receivedFramesController.stream;

  @override
  Uint8List? get selfPublicKey =>
      Uint8List.fromList(List.generate(32, (i) => i));

  @override
  bool get isConnected => _isConnected;

  @override
  double? get selfLatitude => _selfLat;

  @override
  double? get selfLongitude => _selfLon;

  @override
  List<Contact> get allContactsUnfiltered => _allContacts;

  @override
  List<Contact> get contacts => _peerContacts;

  final bool _isConnected;
  double? _selfLat;
  double? _selfLon;
  double? _pendingLat;
  double? _pendingLon;
  final List<Contact> _allContacts;
  final List<Contact> _peerContacts;

  _FakeMeshCoreConnector({
    bool isConnected = false,
    double? selfLat = 48.8566,
    double? selfLon = 2.3522,
    List<Contact> allContacts = const [],
    List<Contact> peerContacts = const [],
  }) : _isConnected = isConnected,
       _selfLat = selfLat,
       _selfLon = selfLon,
       _allContacts = allContacts,
       _peerContacts = peerContacts;

  @override
  Future<void> setNodeLocation({
    required double lat,
    required double lon,
  }) async {
    _pendingLat = lat;
    _pendingLon = lon;
  }

  @override
  Future<void> refreshDeviceInfo() async {
    if (_pendingLat != null && _pendingLon != null) {
      _selfLat = _pendingLat;
      _selfLon = _pendingLon;
      notifyListeners();
    }
  }

  void emitFrame(Uint8List frame) {
    _receivedFramesController.add(frame);
  }

  final List<Uint8List> sentFrames = [];

  @override
  Future<void> sendFrame(
    Uint8List frame, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
    bool waitForGenericAck = false,
  }) async {
    sentFrames.add(frame);
  }
}

Widget _buildTestApp({
  required MeshCoreConnector connector,
  required Widget child,
}) {
  final appSettingsService = AppSettingsService();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
      ChangeNotifierProvider<AppSettingsService>.value(
        value: appSettingsService,
      ),
      ChangeNotifierProvider<MapTileCacheService>(
        create: (_) =>
            MapTileCacheService(appSettingsService: appSettingsService),
      ),
      ChangeNotifierProvider<PathHistoryService>(
        create: (_) => PathHistoryService(_FakeStorageService()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('PathTraceMapScreen parses response frames correctly', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    final screen = PathTraceMapScreen(
      title: 'Test Trace',
      path: Uint8List.fromList([0x12, 0x34]),
      pathHashByteWidth: 1,
    );

    await tester.pumpWidget(_buildTestApp(connector: connector, child: screen));
    await tester.pump();

    // Verify a send request was made
    expect(connector.sentFrames.length, 1);
    final sentFrame = connector.sentFrames.first;
    expect(sentFrame[0], cmdSendTracePath);

    // Extract the tag sent in the request (bytes 2-5)
    final tag = sentFrame.sublist(2, 6);

    // Emit respCodeSent (6)
    final respCodeSentFrame = Uint8List(10);
    respCodeSentFrame[0] = respCodeSent;
    respCodeSentFrame[1] = 0; // reserved / is_flood
    respCodeSentFrame.setRange(2, 6, tag);
    // timeout milliseconds = 5000 (0x1388)
    respCodeSentFrame[6] = 0x88;
    respCodeSentFrame[7] = 0x13;
    respCodeSentFrame[8] = 0x00;
    respCodeSentFrame[9] = 0x00;

    connector.emitFrame(respCodeSentFrame);
    await tester.pump();

    // Now emit PUSH_CODE_TRACE_DATA (0x89)
    // Structure:
    // Offset 0: pushCodeTraceData (0x89)
    // Offset 1: reserved (0)
    // Offset 2: pathLength (2)
    // Offset 3: flag (0)
    // Offset 4..7: tag
    // Offset 8..11: auth (0)
    // Offset 12..13: pathBytes [0x12, 0x34]
    // Offset 14..16: SNR bytes [12, 16, 20] -> to be mapped to signed 8 bit Snr/4
    final pushTraceFrame = Uint8List(17);
    pushTraceFrame[0] = pushCodeTraceData;
    pushTraceFrame[1] = 0; // reserved
    pushTraceFrame[2] = 2; // pathLength
    pushTraceFrame[3] = 0; // flag
    pushTraceFrame.setRange(4, 8, tag);
    // auth bytes (8..11) = 0
    pushTraceFrame.setRange(12, 14, [0x12, 0x34]); // pathBytes
    pushTraceFrame.setRange(14, 17, [12, 16, 20]); // SNR bytes

    connector.emitFrame(pushTraceFrame);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify it doesn't show "Path trace not available" or similar
    expect(find.text('Path trace not available.'), findsNothing);
  });

  testWidgets(
    'PathTraceMapScreen parses multi-byte encoded path trace response correctly',
    (tester) async {
      final connector = _FakeMeshCoreConnector();

      final screen = PathTraceMapScreen(
        title: 'Test Trace Multi-byte',
        path: Uint8List.fromList([0x12, 0x34]),
        pathHashByteWidth: 2,
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: screen),
      );
      await tester.pump();

      // Verify a send request was made
      expect(connector.sentFrames.length, 1);
      final sentFrame = connector.sentFrames.first;
      expect(sentFrame[0], cmdSendTracePath);

      // Extract the tag sent in the request (bytes 2-5)
      final tag = sentFrame.sublist(2, 6);

      // Emit respCodeSent (6)
      final respCodeSentFrame = Uint8List(10);
      respCodeSentFrame[0] = respCodeSent;
      respCodeSentFrame[1] = 0;
      respCodeSentFrame.setRange(2, 6, tag);
      respCodeSentFrame[6] = 0x88;
      respCodeSentFrame[7] = 0x13;
      respCodeSentFrame[8] = 0x00;
      respCodeSentFrame[9] = 0x00;

      connector.emitFrame(respCodeSentFrame);
      await tester.pump();

      // Now emit PUSH_CODE_TRACE_DATA (0x89)
      // Structure:
      // Offset 0: pushCodeTraceData (0x89)
      // Offset 1: reserved (0)
      // Offset 2: pathLength (65) -> mode 1 (width 2), 1 hop
      // Offset 3: flag (0)
      // Offset 4..7: tag
      // Offset 8..11: auth (0)
      // Offset 12..13: pathBytes [0x12, 0x34]
      // Offset 14..15: SNR bytes [12, 16]
      final pushTraceFrame = Uint8List(16);
      pushTraceFrame[0] = pushCodeTraceData;
      pushTraceFrame[1] = 0; // reserved
      pushTraceFrame[2] = 65; // pathLength encoded (mode 1, 1 hop -> 2 bytes)
      pushTraceFrame[3] = 0; // flag
      pushTraceFrame.setRange(4, 8, tag);
      pushTraceFrame.setRange(12, 14, [0x12, 0x34]); // pathBytes
      pushTraceFrame.setRange(14, 16, [12, 16]); // SNR bytes

      connector.emitFrame(pushTraceFrame);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify it parsed correctly (should not show the unavailable message)
      expect(find.text('Path trace not available.'), findsNothing);
    },
  );

  testWidgets('PathTraceMapScreen buildPath: Direct repeater ping (0-hop)', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();
    final target = Contact(
      publicKey: Uint8List.fromList([0xAA, 0xBB, 0xCC]),
      name: 'Repeater Node',
      type: advTypeRepeater,
      path: Uint8List(0),
      pathLength: 0,
      lastSeen: DateTime.now(),
    );

    final screen = PathTraceMapScreen(
      title: 'Direct Repeater Ping',
      path: Uint8List.fromList([0xAA]),
      targetContact: target,
      flipPathAround: true,
      pathHashByteWidth: 1,
    );

    await tester.pumpWidget(_buildTestApp(connector: connector, child: screen));
    await tester.pump();

    expect(connector.sentFrames.length, 1);
    final sentFrame = connector.sentFrames.first;
    expect(sentFrame[0], cmdSendTracePath);
    final payload = sentFrame.sublist(10);
    expect(payload, Uint8List.fromList([0xAA]));
  });

  testWidgets('PathTraceMapScreen buildPath: 1-hop chat contact trace', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();
    final target = Contact(
      publicKey: Uint8List.fromList([0xCC, 0xDD, 0xEE]),
      name: 'Chat User',
      type: advTypeChat,
      path: Uint8List.fromList([0xBB]),
      pathLength: 1,
      lastSeen: DateTime.now(),
    );

    final screen = PathTraceMapScreen(
      title: '1-Hop Chat Trace',
      path: Uint8List.fromList([0xBB]),
      targetContact: target,
      flipPathAround: true,
      pathHashByteWidth: 1,
    );

    await tester.pumpWidget(_buildTestApp(connector: connector, child: screen));
    await tester.pump();

    expect(connector.sentFrames.length, 1);
    final sentFrame = connector.sentFrames.first;
    expect(sentFrame[0], cmdSendTracePath);
    final payload = sentFrame.sublist(10);
    expect(payload, Uint8List.fromList([0xBB, 0xCC, 0xBB]));
  });

  testWidgets('PathTraceMapScreen buildPath: Multi-hop chat contact trace', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();
    final target = Contact(
      publicKey: Uint8List.fromList([0x33, 0x44, 0x55]),
      name: 'Chat User Multi-hop',
      type: advTypeChat,
      path: Uint8List.fromList([0x11, 0x22]),
      pathLength: 2,
      lastSeen: DateTime.now(),
    );

    final screen = PathTraceMapScreen(
      title: 'Multi-Hop Chat Trace',
      path: Uint8List.fromList([0x11, 0x22]),
      targetContact: target,
      flipPathAround: true,
      pathHashByteWidth: 1,
    );

    await tester.pumpWidget(_buildTestApp(connector: connector, child: screen));
    await tester.pump();

    expect(connector.sentFrames.length, 1);
    final sentFrame = connector.sentFrames.first;
    expect(sentFrame[0], cmdSendTracePath);
    final payload = sentFrame.sublist(10);
    expect(payload, Uint8List.fromList([0x11, 0x22, 0x33, 0x22, 0x11]));
  });

  testWidgets(
    'PathTraceMapScreen buildPath: Map trace with null target contact',
    (tester) async {
      final connector = _FakeMeshCoreConnector();

      final screen = PathTraceMapScreen(
        title: 'Map Trace No Target',
        path: Uint8List.fromList([0x11, 0x22]),
        targetContact: null,
        flipPathAround: true,
        pathHashByteWidth: 1,
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: screen),
      );
      await tester.pump();

      expect(connector.sentFrames.length, 1);
      final sentFrame = connector.sentFrames.first;
      expect(sentFrame[0], cmdSendTracePath);
      final payload = sentFrame.sublist(10);
      expect(payload, Uint8List.fromList([0x11, 0x22, 0x11]));
    },
  );

  testWidgets('PathTraceMapScreen parses raw byte length fallback correctly', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    final screen = PathTraceMapScreen(
      title: 'Test Raw Fallback',
      path: Uint8List.fromList([0x12, 0x34]),
      pathHashByteWidth: 2,
    );

    await tester.pumpWidget(_buildTestApp(connector: connector, child: screen));
    await tester.pump();

    expect(connector.sentFrames.length, 1);
    final sentFrame = connector.sentFrames.first;
    // Extract the tag sent in the request (bytes 2-5)
    final tag = sentFrame.sublist(2, 6);

    // Emit respCodeSent (6)
    final respCodeSentFrame = Uint8List(10);
    respCodeSentFrame[0] = respCodeSent;
    respCodeSentFrame[1] = 0;
    respCodeSentFrame.setRange(2, 6, tag);
    respCodeSentFrame[6] = 0x88;
    respCodeSentFrame[7] = 0x13;
    respCodeSentFrame[8] = 0x00;
    respCodeSentFrame[9] = 0x00;

    connector.emitFrame(respCodeSentFrame);
    await tester.pump();

    // Now emit PUSH_CODE_TRACE_DATA (0x89)
    // Structure:
    // Offset 2: pathLength (1) -> mode 0, hop count 1.
    // Offset 12..13: pathBytes [0x12, 0x34] (1 hop * 2 bytes/hop)
    final pushTraceFrame = Uint8List(16);
    pushTraceFrame[0] = pushCodeTraceData;
    pushTraceFrame[1] = 0; // reserved
    pushTraceFrame[2] = 1; // pathLength encoded (mode 0, 1 hop)
    pushTraceFrame[3] = 0; // flag
    pushTraceFrame.setRange(4, 8, tag);
    pushTraceFrame.setRange(12, 14, [0x12, 0x34]); // pathBytes
    pushTraceFrame.setRange(14, 16, [12, 16]); // SNR bytes

    connector.emitFrame(pushTraceFrame);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify it parsed correctly (should not show the unavailable message)
    expect(find.text('Path trace not available.'), findsNothing);
  });

  testWidgets(
    'PathTraceMapScreen ignores impossible distant repeater and peer inference',
    (tester) async {
      final localHop1 = Contact(
        publicKey: Uint8List(32)..first = 0x48,
        name: 'Local Hop',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.60097,
        longitude: -112.02457,
        lastSeen: DateTime.utc(2026),
      );
      final eastCoastBogus = Contact(
        publicKey: Uint8List(32)..first = 0x9C,
        name: 'East Coast 9C',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 42.3601,
        longitude: -71.0589,
        lastSeen: DateTime.utc(2026),
      );
      final distantPeerSharing9C = Contact(
        publicKey: Uint8List(32)..first = 0xAA,
        name: 'Distant Chat Peer',
        type: advTypeChat,
        path: Uint8List.fromList([0x9C]),
        pathLength: 1,
        latitude: 42.35,
        longitude: -71.06,
        lastSeen: DateTime.utc(2026),
      );
      final connector = _FakeMeshCoreConnector(
        selfLat: 33.4484,
        selfLon: -112.0740,
        allContacts: [localHop1, eastCoastBogus],
        peerContacts: [distantPeerSharing9C],
      );

      final screen = PathTraceMapScreen(
        title: 'Trace Impossible Hop',
        path: Uint8List.fromList([0x48, 0x9C]),
        pathHashByteWidth: 1,
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: screen),
      );
      await tester.pump();

      final sentFrame = connector.sentFrames.first;
      final tag = sentFrame.sublist(1, 5);

      final pushTraceFrame = Uint8List(17);
      pushTraceFrame[0] = pushCodeTraceData;
      pushTraceFrame[1] = 0;
      pushTraceFrame[2] = 2;
      pushTraceFrame[3] = 0;
      pushTraceFrame.setRange(4, 8, tag);
      pushTraceFrame.setRange(12, 14, [0x48, 0x9C]);
      pushTraceFrame.setRange(14, 17, [12, 16, 20]);

      connector.emitFrame(pushTraceFrame);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.textContaining('East Coast 9C'), findsNothing);
      expect(find.textContaining('9C: Unknown Repeater'), findsWidgets);

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      final allPoints = polylineLayer.polylines
          .expand((p) => p.points)
          .toList();
      expect(allPoints, isNotEmpty);
      for (final point in allPoints) {
        expect(point.latitude, inInclusiveRange(33.0, 34.0));
        expect(point.longitude, inInclusiveRange(-113.0, -111.0));
      }
    },
  );

  testWidgets(
    'PathTraceMapScreen ignores impossible distant contact passed via pathContacts',
    (tester) async {
      final localHop1 = Contact(
        publicKey: Uint8List(32)..first = 0x48,
        name: 'Local Hop',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.60097,
        longitude: -112.02457,
        lastSeen: DateTime.utc(2026),
      );
      final eastCoastBogus = Contact(
        publicKey: Uint8List(32)..first = 0x9C,
        name: 'East Coast 9C',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 42.3601,
        longitude: -71.0589,
        lastSeen: DateTime.utc(2026),
      );
      final connector = _FakeMeshCoreConnector(
        selfLat: 33.4484,
        selfLon: -112.0740,
        allContacts: [localHop1, eastCoastBogus],
      );

      final screen = PathTraceMapScreen(
        title: 'Manual Trace Impossible Hop',
        path: Uint8List.fromList([0x48, 0x9C]),
        pathHashByteWidth: 1,
        pathContacts: [localHop1, eastCoastBogus],
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: screen),
      );
      await tester.pump();

      final sentFrame = connector.sentFrames.first;
      final tag = sentFrame.sublist(1, 5);

      final pushTraceFrame = Uint8List(17);
      pushTraceFrame[0] = pushCodeTraceData;
      pushTraceFrame[1] = 0;
      pushTraceFrame[2] = 2;
      pushTraceFrame[3] = 0;
      pushTraceFrame.setRange(4, 8, tag);
      pushTraceFrame.setRange(12, 14, [0x48, 0x9C]);
      pushTraceFrame.setRange(14, 17, [12, 16, 20]);

      connector.emitFrame(pushTraceFrame);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.textContaining('East Coast 9C'), findsNothing);
      expect(find.textContaining('9C: Unknown Repeater'), findsWidgets);

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      final allPoints = polylineLayer.polylines
          .expand((p) => p.points)
          .toList();
      expect(allPoints.length, 2);
      for (final point in allPoints) {
        expect(point.latitude, inInclusiveRange(33.0, 34.0));
        expect(point.longitude, inInclusiveRange(-113.0, -111.0));
      }
    },
  );

  testWidgets(
    'PathTraceMapScreen preserves plausible explicit pathContacts over nearer contact with same prefix',
    (tester) async {
      final nearerCollision = Contact(
        publicKey: Uint8List(32)
          ..[0] = 0x48
          ..[1] = 0x01,
        name: 'Nearer 48',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.4600,
        longitude: -112.0700,
        lastSeen: DateTime.utc(2026, 6),
      );
      final selectedExplicit = Contact(
        publicKey: Uint8List(32)
          ..[0] = 0x48
          ..[1] = 0x02,
        name: 'Selected 48',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.9000,
        longitude: -111.7000,
        lastSeen: DateTime.utc(2026, 1),
      );
      final fallbackHop2 = Contact(
        publicKey: Uint8List(32)..first = 0x53,
        name: 'Fallback 53',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.9500,
        longitude: -111.6500,
        lastSeen: DateTime.utc(2026),
      );
      final connector = _FakeMeshCoreConnector(
        selfLat: 33.4484,
        selfLon: -112.0740,
        allContacts: [nearerCollision, selectedExplicit, fallbackHop2],
      );

      final screen = PathTraceMapScreen(
        title: 'Explicit Contact Priority',
        path: Uint8List.fromList([0x48, 0x53]),
        pathHashByteWidth: 1,
        pathContacts: [selectedExplicit],
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: screen),
      );
      await tester.pump();

      final sentFrame = connector.sentFrames.first;
      final tag = sentFrame.sublist(1, 5);

      final pushTraceFrame = Uint8List(17);
      pushTraceFrame[0] = pushCodeTraceData;
      pushTraceFrame[1] = 0;
      pushTraceFrame[2] = 2;
      pushTraceFrame[3] = 0;
      pushTraceFrame.setRange(4, 8, tag);
      pushTraceFrame.setRange(12, 14, [0x48, 0x53]);
      pushTraceFrame.setRange(14, 17, [12, 16, 20]);

      connector.emitFrame(pushTraceFrame);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.textContaining('Selected 48'), findsWidgets);
      expect(find.textContaining('Fallback 53'), findsWidgets);
      expect(find.textContaining('Nearer 48'), findsNothing);

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      final allPoints = polylineLayer.polylines
          .expand((p) => p.points)
          .toList();
      expect(allPoints.length, 3);
      expect(allPoints[1].latitude, closeTo(33.9000, 1e-4));
      expect(allPoints[1].longitude, closeTo(-111.7000, 1e-4));
      expect(allPoints[2].latitude, closeTo(33.9500, 1e-4));
      expect(allPoints[2].longitude, closeTo(-111.6500, 1e-4));
    },
  );

  testWidgets(
    'PathTraceMapScreen re-resolves primary hops when self location changes via _setMyLocation',
    (tester) async {
      final localHop1 = Contact(
        publicKey: Uint8List(32)..first = 0x48,
        name: 'Phoenix Hop 1',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.60097,
        longitude: -112.02457,
        lastSeen: DateTime.utc(2026),
      );
      final localHop2 = Contact(
        publicKey: Uint8List(32)..first = 0x53,
        name: 'Phoenix Hop 2',
        type: advTypeRepeater,
        path: Uint8List(0),
        pathLength: 0,
        latitude: 33.46300,
        longitude: -111.65000,
        lastSeen: DateTime.utc(2026),
      );
      final connector = _FakeMeshCoreConnector(
        isConnected: true,
        // Incorrect initial self location on the East Coast causes local hops to be rejected.
        selfLat: 42.3601,
        selfLon: -71.0589,
        allContacts: [localHop1, localHop2],
      );

      final screen = PathTraceMapScreen(
        title: 'Relocate Self Trace',
        path: Uint8List.fromList([0x48, 0x53]),
        pathHashByteWidth: 1,
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: screen),
      );
      await tester.pump();

      expect(connector.sentFrames.length, 1);
      final tag = connector.sentFrames.first.sublist(1, 5);

      final pushTraceFrame = Uint8List(17);
      pushTraceFrame[0] = pushCodeTraceData;
      pushTraceFrame[1] = 0;
      pushTraceFrame[2] = 2;
      pushTraceFrame[3] = 0;
      pushTraceFrame.setRange(4, 8, tag);
      pushTraceFrame.setRange(12, 14, [0x48, 0x53]);
      pushTraceFrame.setRange(14, 17, [12, 16, 20]);

      connector.emitFrame(pushTraceFrame);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Initially, both Phoenix hops are rejected as impossibly far from Boston.
      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phoenix Hop 1'), findsNothing);
      expect(find.textContaining('Phoenix Hop 2'), findsNothing);
      expect(find.textContaining('48: Unknown Repeater'), findsWidgets);
      expect(find.textContaining('53: Unknown Repeater'), findsWidgets);

      await tester.tap(find.byIcon(Icons.close_fullscreen));
      await tester.pumpAndSettle();

      expect(find.byType(PolylineLayer), findsNothing);

      // Update self location to Phoenix via the map's long-press action.
      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      flutterMap.options.onLongPress!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(33.4484, -112.0740),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Set location'));
      await tester.pumpAndSettle();

      // Primary hops must now be resolved without waiting for another trace packet.
      expect(connector.sentFrames.length, 1);

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      final allPoints = polylineLayer.polylines
          .expand((p) => p.points)
          .toList();
      expect(allPoints.length, 3);
      expect(allPoints[0].latitude, closeTo(33.4484, 1e-4));
      expect(allPoints[0].longitude, closeTo(-112.0740, 1e-4));
      expect(allPoints[1].latitude, closeTo(33.60097, 1e-4));
      expect(allPoints[1].longitude, closeTo(-112.02457, 1e-4));
      expect(allPoints[2].latitude, closeTo(33.46300, 1e-4));
      expect(allPoints[2].longitude, closeTo(-111.65000, 1e-4));

      final markerLayer = tester.widget<MarkerLayer>(
        find.byType(MarkerLayer).first,
      );
      expect(markerLayer.markers.length, greaterThanOrEqualTo(3));
      for (final marker in markerLayer.markers) {
        expect(marker.point.latitude, inInclusiveRange(33.0, 34.0));
        expect(marker.point.longitude, inInclusiveRange(-113.0, -111.0));
      }

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phoenix Hop 1'), findsWidgets);
      expect(find.textContaining('Phoenix Hop 2'), findsWidgets);
      expect(find.textContaining('Unknown Repeater'), findsNothing);
    },
  );
}
