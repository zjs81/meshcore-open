import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/services/message_filter/duplicate_tracker.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  test('same sender repeat within 10 minutes is a duplicate', () {
    final tracker = DuplicateTracker();
    expect(
      tracker.check(channelId: 'c', sender: 'Bob', text: 'Hello', at: t0),
      isNull,
    );
    expect(
      tracker.check(
        channelId: 'c',
        sender: 'Bob',
        text: 'hello!',
        at: t0.add(const Duration(minutes: 9)),
      ),
      FilterReason.duplicate,
    );
  });

  test('same sender repeat after the window is not a duplicate', () {
    final tracker = DuplicateTracker();
    tracker.check(channelId: 'c', sender: 'Bob', text: 'Hello', at: t0);
    expect(
      tracker.check(
        channelId: 'c',
        sender: 'Bob',
        text: 'Hello',
        at: t0.add(const Duration(minutes: 11)),
      ),
      isNull,
    );
  });

  test('channels are tracked separately', () {
    final tracker = DuplicateTracker();
    tracker.check(channelId: 'a', sender: 'Bob', text: 'Hello', at: t0);
    expect(
      tracker.check(channelId: 'b', sender: 'Bob', text: 'Hello', at: t0),
      isNull,
    );
  });

  test('short greetings from many senders are never cross-sender', () {
    final tracker = DuplicateTracker();
    // New Year's Eve: everyone sends the same few words at once.
    const greetings = [
      'Happy New Year!',
      'happy new year',
      'HAPPY NEW YEAR!!',
      'Happy new year 🎉',
      'Happy New Year everyone!',
    ];
    for (var i = 0; i < 8; i++) {
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'person$i',
          text: greetings[i % greetings.length],
          at: t0.add(Duration(minutes: i)),
        ),
        isNull,
        reason: 'greeting from person$i must stay visible',
      );
    }
    // Five words is still a greeting, not a campaign.
    for (var i = 0; i < 4; i++) {
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'friend$i',
          text: 'Merry Christmas to you all',
          at: t0.add(Duration(minutes: 10 + i)),
        ),
        isNull,
      );
    }
  });

  test('third distinct sender of the same long text is cross-sender', () {
    final tracker = DuplicateTracker();
    const text = 'Join the best mesh client now, it is free';
    expect(
      tracker.check(channelId: 'c', sender: 'A', text: text, at: t0),
      isNull,
    );
    expect(
      tracker.check(
        channelId: 'c',
        sender: 'B',
        text: text,
        at: t0.add(const Duration(minutes: 5)),
      ),
      isNull,
    );
    expect(
      tracker.check(
        channelId: 'c',
        sender: 'C',
        text: text,
        at: t0.add(const Duration(minutes: 20)),
      ),
      FilterReason.crossSenderDuplicate,
    );
  });

  test('short texts never count as cross-sender duplicates', () {
    final tracker = DuplicateTracker();
    for (final sender in ['A', 'B', 'C', 'D']) {
      expect(
        tracker.check(channelId: 'c', sender: sender, text: 'hi all', at: t0),
        isNull,
      );
    }
  });

  test('cross-sender window is 30 minutes', () {
    final tracker = DuplicateTracker();
    const text = 'Join the best mesh now';
    tracker.check(channelId: 'c', sender: 'A', text: text, at: t0);
    tracker.check(
      channelId: 'c',
      sender: 'B',
      text: text,
      at: t0.add(const Duration(minutes: 1)),
    );
    expect(
      tracker.check(
        channelId: 'c',
        sender: 'C',
        text: text,
        at: t0.add(const Duration(minutes: 31)),
      ),
      isNull,
    );
  });

  test('filtered texts are still recorded so floods keep being caught', () {
    final tracker = DuplicateTracker();
    tracker.check(channelId: 'c', sender: 'Bob', text: 'buy now', at: t0);
    for (var i = 1; i <= 5; i++) {
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'Bob',
          text: 'buy now',
          at: t0.add(Duration(minutes: 8 * i)),
        ),
        FilterReason.duplicate,
      );
    }
  });

  test('allow exempts the text in that channel', () {
    final tracker = DuplicateTracker();
    tracker.check(channelId: 'c', sender: 'Bob', text: 'Hello', at: t0);
    tracker.allow('c', 'HELLO!');
    expect(tracker.isAllowed('c', 'hello'), isTrue);
    expect(tracker.isAllowed('other', 'hello'), isFalse);
    expect(
      tracker.check(channelId: 'c', sender: 'Bob', text: 'Hello', at: t0),
      isNull,
    );
    tracker.clear();
    expect(tracker.isAllowed('c', 'hello'), isFalse);
  });

  test('empty normalized text is ignored', () {
    final tracker = DuplicateTracker();
    tracker.check(channelId: 'c', sender: 'Bob', text: '👍', at: t0);
    expect(
      tracker.check(channelId: 'c', sender: 'Bob', text: '👍', at: t0),
      isNull,
    );
  });

  group('send-time windows', () {
    test('history synced in a burst is not a duplicate', () {
      final tracker = DuplicateTracker();
      // Sent three hours apart, delivered seconds apart after reconnecting.
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'Bob',
          text: 'Heading out now',
          at: t0,
          receivedAt: t0.add(const Duration(hours: 5)),
        ),
        isNull,
      );
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'Bob',
          text: 'Heading out now',
          at: t0.add(const Duration(hours: 3)),
          receivedAt: t0.add(const Duration(hours: 5, seconds: 2)),
        ),
        isNull,
      );
    });

    test('out-of-order delivery is still caught', () {
      final tracker = DuplicateTracker();
      // The newer copy arrives first.
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'Bob',
          text: 'Buy cheap nodes',
          at: t0.add(const Duration(minutes: 5)),
          receivedAt: t0.add(const Duration(minutes: 30)),
        ),
        isNull,
      );
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'Bob',
          text: 'Buy cheap nodes',
          at: t0,
          receivedAt: t0.add(const Duration(minutes: 30, seconds: 1)),
        ),
        FilterReason.duplicate,
      );

      const campaign = 'the meshcore trademark grab is theft, boycott him';
      final now = t0.add(const Duration(hours: 1));
      for (final (i, sender) in ['x', 'y'].indexed) {
        expect(
          tracker.check(
            channelId: 'c',
            sender: sender,
            text: campaign,
            at: t0.add(Duration(minutes: 20 - i * 10)),
            receivedAt: now,
          ),
          isNull,
        );
      }
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'z',
          text: campaign,
          at: t0,
          receivedAt: now,
        ),
        FilterReason.crossSenderDuplicate,
      );
    });

    test('a sender clock years ahead does not evict other entries', () {
      final tracker = DuplicateTracker();
      tracker.check(
        channelId: 'c',
        sender: 'Bob',
        text: 'Morning all, testing my node',
        at: t0,
      );
      tracker.check(
        channelId: 'c',
        sender: 'Wonky',
        text: 'Clock is way off',
        at: t0.add(const Duration(days: 900)),
        receivedAt: t0.add(const Duration(minutes: 1)),
      );
      expect(
        tracker.check(
          channelId: 'c',
          sender: 'Bob',
          text: 'Morning all, testing my node',
          at: t0.add(const Duration(minutes: 2)),
        ),
        FilterReason.duplicate,
      );
    });
  });
}
