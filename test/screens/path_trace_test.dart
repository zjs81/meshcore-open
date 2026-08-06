import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  double? get selfLatitude => 48.8566;

  @override
  double? get selfLongitude => 2.3522;

  @override
  List<Contact> get allContactsUnfiltered => [];

  @override
  List<Contact> get contacts => [];

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
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
      ChangeNotifierProvider<AppSettingsService>(
        create: (_) => AppSettingsService(),
      ),
      Provider<MapTileCacheService>(
        create: (context) => MapTileCacheService(
          appSettingsService: context.read<AppSettingsService>(),
        ),
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
}
