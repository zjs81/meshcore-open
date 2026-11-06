import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/services/repeater_command_service.dart';

class _FakeConnector extends MeshCoreConnector {
  @override
  Future<PathSelection> preparePathForContactSend(Contact contact) async =>
      const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
    bool waitForGenericAck = false,
  }) async {}
}

class _ShortTimeoutConnector extends _FakeConnector {
  final List<Uint8List> sentFrames = [];

  @override
  int calculateTimeout({
    required int pathLength,
    int messageBytes = 100,
    String? contactKey,
    int? deviceTimeoutMs,
  }) => 30;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
    bool waitForGenericAck = false,
  }) async {
    sentFrames.add(data);
  }
}

Contact _repeater(int seed) => Contact(
  publicKey: Uint8List.fromList(List<int>.generate(32, (i) => seed + i)),
  name: 'R$seed',
  type: 2,
  pathLength: -1,
  path: Uint8List(0),
  lastSeen: DateTime.now(),
);

void main() {
  group('normalizeRepeaterClockSyncCommand', () {
    test('translates "clock sync" to explicit time command', () {
      final result = normalizeRepeaterClockSyncCommand(
        'clock sync',
        nowSeconds: 1787900000,
      );
      expect(result, 'time 1787900000');
    });

    test('is case-insensitive and tolerates surrounding whitespace', () {
      expect(
        normalizeRepeaterClockSyncCommand('  Clock Sync ', nowSeconds: 1),
        'time 1',
      );
    });

    test('passes other commands through unchanged', () {
      expect(
        normalizeRepeaterClockSyncCommand('clock', nowSeconds: 1),
        'clock',
      );
      expect(
        normalizeRepeaterClockSyncCommand('get radio', nowSeconds: 1),
        'get radio',
      );
      expect(
        normalizeRepeaterClockSyncCommand('time 123', nowSeconds: 1),
        'time 123',
      );
    });

    test('uses current time when nowSeconds is omitted', () {
      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final result = normalizeRepeaterClockSyncCommand('clock sync');
      final after = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      expect(result, startsWith('time '));
      final epoch = int.parse(result.substring('time '.length));
      expect(epoch, inInclusiveRange(before, after));
    });
  });

  group('RepeaterCommandService.handleResponse', () {
    late RepeaterCommandService service;

    setUp(() => service = RepeaterCommandService(_FakeConnector()));
    tearDown(() => service.dispose());

    test('unknown prefix does not complete the pending command', () async {
      final repeater = _repeater(1);
      String? result;
      unawaited(
        service
            .sendCommand(repeater, 'ver', retries: 1)
            .then((r) => result = r, onError: (_) {}),
      );
      await pumpEventQueue();

      service.handleResponse(repeater, 'FE|late reply');
      await pumpEventQueue();
      expect(result, isNull);

      service.handleResponse(repeater, '00|v1.0');
      await pumpEventQueue();
      expect(result, 'v1.0');
    });

    test('prefix owned by another repeater is ignored', () async {
      final a = _repeater(1);
      final b = _repeater(100);
      String? result;
      unawaited(
        service
            .sendCommand(a, 'ver', retries: 1)
            .then((r) => result = r, onError: (_) {}),
      );
      await pumpEventQueue();

      service.handleResponse(b, '00|wrong');
      await pumpEventQueue();
      expect(result, isNull);

      service.handleResponse(a, 'unprefixed');
      await pumpEventQueue();
      expect(result, 'unprefixed');
    });
  });

  group('RepeaterCommandService retries', () {
    test('late reply to an earlier attempt completes the command', () async {
      final connector = _ShortTimeoutConnector();
      final service = RepeaterCommandService(connector);
      addTearDown(service.dispose);
      final repeater = _repeater(1);
      String? result;
      unawaited(
        service
            .sendCommand(repeater, 'password x', retries: 3)
            .then((r) => result = r, onError: (_) {}),
      );

      // Attempt 1 (00|) times out after 30ms and attempt 2 (01|) is sent.
      await Future<void>.delayed(const Duration(milliseconds: 45));
      expect(connector.sentFrames, hasLength(2));

      service.handleResponse(repeater, '00|OK');
      await pumpEventQueue();
      expect(result, 'OK');

      // No third attempt goes out once the call has completed.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(connector.sentFrames, hasLength(2));
    });

    test('prefixes are released once the command finishes', () async {
      final connector = _ShortTimeoutConnector();
      final service = RepeaterCommandService(connector);
      addTearDown(service.dispose);
      final repeater = _repeater(1);
      Object? error;
      await service.sendCommand(repeater, 'ver', retries: 2).catchError((
        Object e,
      ) {
        error = e;
        return '';
      });
      expect(error, isNotNull);

      String? result;
      unawaited(
        service
            .sendCommand(repeater, 'ver', retries: 1)
            .then((r) => result = r, onError: (_) {}),
      );
      await pumpEventQueue();
      // Replies to the finished call's prefixes are ignored.
      service.handleResponse(repeater, '00|stale');
      service.handleResponse(repeater, '01|stale');
      await pumpEventQueue();
      expect(result, isNull);

      service.handleResponse(repeater, '02|fresh');
      await pumpEventQueue();
      expect(result, 'fresh');
    });
  });
}
