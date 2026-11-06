import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/connector/pending_command_replies.dart';

void main() {
  Uint8List frame(List<int> bytes) => Uint8List.fromList(bytes);
  final keyA = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  final keyB = Uint8List.fromList(List<int>.generate(32, (i) => i + 100));

  PendingCommandReplies newQueue() =>
      PendingCommandReplies(staleAfter: const Duration(seconds: 10));

  test('ERR goes to the oldest pending command (firmware order)', () {
    final queue = newQueue();
    final time = queue.track(buildSetDeviceTimeFrame(1));
    queue.track(buildSetAdvertNameFrame('x'));

    final failed = queue.takeErr(6);
    expect(failed, same(time));
    expect(queue.takeOk()?.commandCode, cmdSetAdvertName);
    expect(queue.length, 0);
  });

  test('OK skips commands whose success is a specific RESP_CODE', () {
    final queue = newQueue();
    queue.track(buildSendTextMsgFrame(keyA, 'hi'));
    queue.track(buildRemoveContactFrame(keyA));

    expect(queue.takeOk()?.commandCode, cmdRemoveContact);
    expect(queue.completeReply(frame([respCodeSent, 0, 0, 0, 0, 0])), isTrue);
    expect(queue.length, 0);
  });

  test('specific replies clear their entry so a later ERR is not misread', () {
    final queue = newQueue();
    queue.track(buildGetChannelFrame(0));
    queue.track(buildSetChannelFrame(1, 'c', Uint8List(16)));

    expect(queue.completeReply(frame([respCodeChannelInfo, 0])), isTrue);
    expect(queue.takeErr(2)?.commandCode, cmdSetChannel);
  });

  test('CONTACT only completes GET_CONTACT_BY_KEY for the same key', () {
    final queue = newQueue();
    queue.track(buildGetContactByKeyFrame(keyA));

    expect(queue.completeReply(frame([respCodeContact, ...keyB])), isFalse);
    expect(queue.completeReply(frame([respCodeContact, ...keyA])), isTrue);
    expect(queue.length, 0);
  });

  test('untracked commands are not enrolled', () {
    final queue = newQueue();
    expect(queue.track(buildSyncNextMessageFrame()), isNull);
    expect(queue.track(buildRebootFrame()), isNull);
    expect(queue.takeErr(1), isNull);
  });

  test('awaited command completes with error on ERR', () async {
    final queue = newQueue();
    final pending = queue.track(
      buildSetRadioParamsFrame(869525, 250000, 11, 5),
      waitForReply: true,
    );
    queue.takeErr(6);
    await expectLater(
      pending!.completer!.future,
      throwsA(
        isA<FirmwareCommandException>().having((e) => e.errCode, 'errCode', 6),
      ),
    );
  });

  group('timed-out entries', () {
    late DateTime now;
    PendingCommandReplies clockedQueue() => PendingCommandReplies(
      staleAfter: const Duration(seconds: 10),
      tombstoneLifetime: const Duration(seconds: 5),
      clock: () => now,
    );

    setUp(() => now = DateTime(2026, 1, 1));

    test('late OK is absorbed instead of completing the next command', () {
      final queue = clockedQueue();
      final scope = queue.track(
        buildSetFloodScopeFrame(''),
        waitForReply: true,
      );
      final text = queue.track(
        buildSendChannelTextMsgFrame(0, 'hi'),
        channelSendQueueId: 'msg-1',
      );
      queue.markTimedOut(scope!);

      expect(queue.takeOk(), isNull); // the late OK for SET_FLOOD_SCOPE
      expect(queue.takeOk(), same(text));
      expect(queue.length, 0);
    });

    test('late ERR is absorbed by the oldest timed-out entry', () {
      final queue = clockedQueue();
      final first = queue.track(buildSetDeviceTimeFrame(1), waitForReply: true);
      final second = queue.track(buildSetAdvertNameFrame('x'));
      queue.markTimedOut(first!);

      expect(queue.takeErr(2), isNull);
      expect(queue.takeErr(2), same(second));
    });

    test('a timed-out entry expires after its lifetime', () {
      final queue = clockedQueue();
      final first = queue.track(buildSetDeviceTimeFrame(1), waitForReply: true);
      queue.markTimedOut(first!);
      now = now.add(const Duration(seconds: 6));
      final next = queue.track(buildSetAdvertNameFrame('x'));

      expect(queue.takeOk(), same(next));
    });
  });
}
