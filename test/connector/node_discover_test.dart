import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Uint8List _discoverResp({
  required int type,
  required int tag,
  required List<int> key,
  int snrQuarterDb = 20,
  int remoteSnrQuarterDb = -8,
}) {
  final tagBytes = ByteData(4)..setUint32(0, tag, Endian.little);
  return Uint8List.fromList([
    pushCodeControlData,
    snrQuarterDb & 0xFF,
    (-70) & 0xFF,
    0,
    (controlSubtypeDiscoverResp << 4) | type,
    remoteSnrQuarterDb & 0xFF,
    ...tagBytes.buffer.asUint8List(),
    ...key,
  ]);
}

/// Review radio that records sent frames and can inject extra responses.
class _ScanRadio extends ReviewRadio {
  _ScanRadio({required super.firmwareVerCode})
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );

  final List<Uint8List> sent = [];
  void Function(int tag)? onDiscoverRequest;

  @override
  void handle(Uint8List frame) {
    sent.add(Uint8List.fromList(frame));
    super.handle(frame);
    if (frame.isNotEmpty && frame[0] == cmdSendControlData) {
      final tag = ByteData.sublistView(frame, 3, 7).getUint32(0, Endian.little);
      onDiscoverRequest?.call(tag);
    }
  }
}

late MeshCoreConnector _connector;

Future<(MeshCoreConnector, _ScanRadio)> _connect(int verCode) async {
  final radio = _ScanRadio(firmwareVerCode: verCode);
  _connector.reviewRadioFactoryForTest = () => radio;
  await _connector.connectReview();
  addTearDown(_connector.disconnect);
  await _waitFor(
    () =>
        _connector.firmwareVerCode == verCode && _connector.channels.isNotEmpty,
  );
  return (_connector, radio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    _connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    _connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    addTearDown(() {
      _connector.dispose();
      retryService.dispose();
    });
  });

  group('frames', () {
    test('scan request asks repeaters, rooms and sensors for full keys', () {
      final payload = buildDiscoveryRequestPayload(
        0x11223344,
        typeMask: nodeDiscoverScanTypeMask,
      );
      expect(payload[0], 0x80); // DISCOVER_REQ, full keys
      expect(payload[1], (1 << 2) | (1 << 3) | (1 << 4));
      expect(
        ByteData.sublistView(payload, 2, 6).getUint32(0, Endian.little),
        0x11223344,
      );
      expect(payload.length, 10); // + since
      expect(buildSendControlDataFrame(payload)[0], cmdSendControlData);
    });

    test('parses a full-key DISCOVER_RESP', () {
      final key = List<int>.generate(32, (i) => i + 1);
      final parsed = parseNodeDiscoverResponse(
        _discoverResp(type: advTypeRepeater, tag: 0xDEADBEEF, key: key),
      )!;
      expect(parsed.nodeType, advTypeRepeater);
      expect(parsed.tag, 0xDEADBEEF);
      expect(parsed.snr, 5.0);
      expect(parsed.remoteSnr, -2.0);
      expect(parsed.rssi, -70);
      expect(parsed.hasFullKey, isTrue);
      expect(parsed.publicKey, key);
    });

    test('parses a prefix-only DISCOVER_RESP', () {
      final parsed = parseNodeDiscoverResponse(
        _discoverResp(type: advTypeSensor, tag: 1, key: List.filled(8, 0xAB)),
      )!;
      expect(parsed.hasFullKey, isFalse);
      expect(parsed.publicKeyHex, 'ab' * 8);
    });

    test('rejects other control data and short frames', () {
      final notResp = _discoverResp(
        type: advTypeRepeater,
        tag: 1,
        key: List.filled(32, 1),
      )..[4] = (controlSubtypeDiscoverReq << 4);
      expect(parseNodeDiscoverResponse(notResp), isNull);
      expect(
        parseNodeDiscoverResponse(
          _discoverResp(type: advTypeRepeater, tag: 1, key: [1, 2, 3]),
        ),
        isNull,
      );
      expect(parseNodeDiscoverResponse(Uint8List.fromList([0x80])), isNull);
    });
  });

  group('connector', () {
    test(
      'collects tagged responses, ignoring other tags and duplicates',
      () async {
        final (connector, radio) = await _connect(14);
        expect(connector.supportsNodeDiscover, isTrue);
        final stranger = List<int>.generate(32, (i) => 0xF0 ^ i);
        radio.onDiscoverRequest = (tag) {
          // A reply to someone else's scan, then a stranger answering twice.
          radio.emitForTest(
            _discoverResp(type: advTypeRepeater, tag: tag ^ 1, key: stranger),
          );
          radio.emitForTest(
            _discoverResp(type: advTypeSensor, tag: tag, key: stranger),
          );
          radio.emitForTest(
            _discoverResp(type: advTypeSensor, tag: tag, key: stranger),
          );
        };

        final results = await connector
            .discoverNearbyNodes(timeout: const Duration(milliseconds: 600))
            .toList();

        final keys = results.map((r) => r.publicKeyHex).toList();
        expect(keys.toSet().length, keys.length, reason: 'no duplicates');
        expect(keys, contains(pubKeyToHex(Uint8List.fromList(stranger))));
        // The scripted Hilltop Repeater answers too, and is a known contact.
        final repeater = results.firstWhere(
          (r) => r.nodeType == advTypeRepeater,
        );
        expect(
          connector.contactForDiscoverResponse(repeater).name,
          'Hilltop Repeater',
        );
        // An unknown node gets a direct-path placeholder named by its key.
        final unknown = connector.contactForDiscoverResponse(
          results.firstWhere((r) => r.nodeType == advTypeSensor),
        );
        expect(unknown.pathLength, 0);
        expect(unknown.name, 'F0F1F2F3');
      },
    );

    test('older firmware gets no scan request', () async {
      final (connector, radio) = await _connect(7);
      expect(connector.supportsNodeDiscover, isFalse);
      final results = await connector
          .discoverNearbyNodes(timeout: const Duration(milliseconds: 200))
          .toList();
      expect(results, isEmpty);
      expect(radio.sent.where((f) => f[0] == cmdSendControlData), isEmpty);
    });
  });
}
