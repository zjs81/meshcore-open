import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/services/message_retry_service.dart';

Contact _contact({int pathLength = -1, List<int> path = const []}) => Contact(
  publicKey: Uint8List.fromList(List<int>.generate(32, (i) => 0xAA + i)),
  name: 'Test',
  type: 1,
  pathLength: pathLength,
  path: Uint8List.fromList(path),
  lastSeen: DateTime.now(),
);

/// Route failures only count once the contact proved reachable: a message
/// that never gets through must not wreck the routes' history.
void main() {
  late MessageRetryService service;
  late Map<String, Message> latest;
  late List<({int attempt, int timestamp})> sends;
  late List<({List<int> path, bool flood, bool success})> results;
  final selfKey = Uint8List(32);

  setUp(() {
    service = MessageRetryService(
      sentWatchdogGrace: const Duration(milliseconds: 10),
    );
    service.setMaxRetries(2);
    latest = {};
    sends = [];
    results = [];
    service.initialize(
      RetryServiceConfig(
        sendMessage: (_, _, attempt, timestamp) async {
          sends.add((attempt: attempt, timestamp: timestamp));
        },
        addMessage: (_, m) => latest[m.messageId] = m,
        updateMessage: (m) => latest[m.messageId] = m,
        getSelfPublicKey: () => selfKey,
        calculateTimeout: (_, _, {String? contactKey, int? deviceTimeoutMs}) =>
            20,
        recordPathResult: (_, PathSelection selection, success, _) =>
            results.add((
              path: List<int>.of(selection.pathBytes),
              flood: selection.useFlood,
              success: success,
            )),
      ),
    );
  });

  tearDown(() => service.dispose());

  // Lists inside records compare by identity, so compare readable strings.
  List<String> recorded() => [
    for (final r in results)
      '${r.flood ? 'flood' : r.path}:${r.success ? 'ok' : 'fail'}',
  ];

  int ackHashFor(int attempt) => MessageRetryService.computeExpectedAckHash(
    sends.firstWhere((s) => s.attempt == attempt).timestamp,
    attempt,
    'hello',
    selfKey,
  );

  test('a message that never gets through blames no route', () async {
    await service.sendMessageWithRetry(
      contact: _contact(pathLength: 2, path: [0x11, 0x22]),
      text: 'hello',
    );
    await pumpEventQueue();

    // Attempt 0 times out, the 1 s backoff runs, attempt 1 times out too.
    await Future<void>.delayed(const Duration(milliseconds: 1300));

    expect(latest.values.single.status, MessageStatus.failed);
    expect(results.where((r) => !r.flood), isEmpty);
  });

  test('once delivered, the routes that timed out are blamed', () async {
    await service.sendMessageWithRetry(
      contact: _contact(pathLength: 2, path: [0x11, 0x22]),
      text: 'hello',
    );
    await pumpEventQueue();

    // Attempt 0 times out; the retry goes out on another route.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    service.updatePendingContact(_contact(pathLength: 1, path: [0x33]));
    // Act as soon as attempt 1 goes out, before its own 30 ms watchdog.
    for (var i = 0; i < 300 && sends.length < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(sends.map((s) => s.attempt), [0, 1]);

    // The radio confirms the send (so the ACK maps to attempt 1), then ACKs.
    expect(service.updateMessageFromSent(ackHashFor(1), 60000), isTrue);
    service.handleAckReceived(ackHashFor(1), 400);

    expect(latest.values.single.status, MessageStatus.delivered);
    expect(recorded(), ['[17, 34]:fail', '[51]:ok']);
  });

  test(
    'a late ACK for a timed-out attempt credits it, not blames it',
    () async {
      await service.sendMessageWithRetry(
        contact: _contact(pathLength: 2, path: [0x11, 0x22]),
        text: 'hello',
      );
      await pumpEventQueue();

      // Attempt 0 times out and its failure is held back...
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(latest.values.single.retryCount, 1);

      // ...then its ACK arrives after all.
      service.handleAckReceived(ackHashFor(0), 900);

      expect(recorded(), ['[17, 34]:ok']);
    },
  );

  test(
    'a late ACK after the final timeout still blames earlier routes',
    () async {
      await service.sendMessageWithRetry(
        contact: _contact(pathLength: 2, path: [0x11, 0x22]),
        text: 'hello',
      );
      await pumpEventQueue();

      // Attempt 0 times out; attempt 1 goes out on another route and also
      // times out, so the message is marked failed.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      service.updatePendingContact(_contact(pathLength: 1, path: [0x33]));
      for (var i = 0; i < 300 && sends.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(service.updateMessageFromSent(ackHashFor(1), 20), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(latest.values.single.status, MessageStatus.failed);
      expect(recorded(), isEmpty);

      // Within the grace period, attempt 1's ACK arrives after all.
      service.handleAckReceived(ackHashFor(1), 1500);

      expect(latest.values.single.status, MessageStatus.delivered);
      expect(recorded(), ['[17, 34]:fail', '[51]:ok']);
    },
  );
}
