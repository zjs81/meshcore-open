import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/services/message_retry_service.dart';

Contact _contact({int pathLength = -1, List<int> path = const []}) => Contact(
  publicKey: Uint8List.fromList(List<int>.generate(32, (i) => 0xAA + i)),
  name: 'Test',
  type: 1,
  pathLength: pathLength,
  path: Uint8List.fromList(path),
  lastSeen: DateTime.now(),
);

void main() {
  late MessageRetryService service;
  late Map<String, Message> latest;
  late List<({int attempt, int timestamp})> sends;
  late int timeoutMs;
  late List<({int pathLength, int tripTimeMs})> observed;
  final selfKey = Uint8List(32);

  setUp(() {
    service = MessageRetryService(
      sentWatchdogGrace: const Duration(milliseconds: 10),
    );
    latest = {};
    sends = [];
    timeoutMs = 20;
    observed = [];
    service.initialize(
      RetryServiceConfig(
        sendMessage: (_, _, attempt, timestamp) async {
          sends.add((attempt: attempt, timestamp: timestamp));
        },
        addMessage: (_, m) => latest[m.messageId] = m,
        updateMessage: (m) => latest[m.messageId] = m,
        getSelfPublicKey: () => selfKey,
        calculateTimeout: (_, _, {String? contactKey, int? deviceTimeoutMs}) =>
            timeoutMs,
        onDeliveryObserved: (_, pathLength, _, tripTimeMs) =>
            observed.add((pathLength: pathLength, tripTimeMs: tripTimeMs)),
      ),
    );
  });

  tearDown(() => service.dispose());

  int ackHashFor(int attempt) => MessageRetryService.computeExpectedAckHash(
    sends.first.timestamp,
    attempt,
    'hello',
    selfKey,
  );

  test('missing RESP_CODE_SENT times out and retries', () async {
    await service.sendMessageWithRetry(contact: _contact(), text: 'hello');
    await pumpEventQueue();
    expect(sends.map((s) => s.attempt), [0]);

    // Watchdog (20ms + 10ms grace) fires, then the 1s retry backoff.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(sends.map((s) => s.attempt), [0, 1]);
  });

  test('RESP_CODE_SENT replaces the watchdog without a double retry', () async {
    await service.sendMessageWithRetry(contact: _contact(), text: 'hello');
    await pumpEventQueue();

    timeoutMs = 60000;
    expect(service.updateMessageFromSent(ackHashFor(0), 0), isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sends, hasLength(1));
    expect(latest.values.single.status, MessageStatus.sent);
  });

  test('late ACK for an attempt whose SENT was lost still delivers', () async {
    await service.sendMessageWithRetry(contact: _contact(), text: 'hello');
    await pumpEventQueue();

    // Let the watchdog fire; the retry is now waiting on its backoff.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(latest.values.single.retryCount, 1);

    service.handleAckReceived(ackHashFor(0), 500);

    expect(latest.values.single.status, MessageStatus.delivered);
    expect(service.hasPendingMessages, isFalse);

    // The cancelled backoff must not resend.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(sends, hasLength(1));
  });

  test('late ACK is observed with the path of the attempt it acks', () async {
    final direct = _contact(pathLength: 2, path: [0x11, 0x22]);
    await service.sendMessageWithRetry(contact: direct, text: 'hello');
    await pumpEventQueue();

    // Attempt 0 times out; the retry then goes out as a flood.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    service.updatePendingContact(_contact());
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(sends.map((s) => s.attempt), [0, 1]);

    service.handleAckReceived(ackHashFor(0), 700);

    expect(latest.values.single.status, MessageStatus.delivered);
    expect(observed, [(pathLength: 2, tripTimeMs: 700)]);
  });
}
