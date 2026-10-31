import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/coalesced_writes.dart';

const _delay = Duration(milliseconds: 40);

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('repeated schedules for a key run only the latest write once', () async {
    final writes = CoalescedWrites(delay: _delay);
    final ran = <String>[];
    for (var i = 0; i < 100; i++) {
      writes.schedule('channel:a', () async => ran.add('a$i'));
    }
    writes.schedule('contacts', () async => ran.add('contacts'));

    expect(ran, isEmpty);
    await _wait(120);
    expect(ran, ['a99', 'contacts']);
    expect(writes.hasPending, isFalse);
  });

  test('a steady stream of schedules does not push the write back', () async {
    final writes = CoalescedWrites(delay: _delay);
    var count = 0;
    final stop = DateTime.now().add(const Duration(milliseconds: 300));
    while (DateTime.now().isBefore(stop)) {
      writes.schedule('k', () async => count++);
      await _wait(5);
    }
    // Persistence keeps landing while frames keep arriving.
    expect(count, greaterThanOrEqualTo(3));
    await writes.flush();
  });

  test('flush starts every write synchronously and clears the queue', () {
    final writes = CoalescedWrites();
    final ran = <String>[];
    writes.schedule('a', () async => ran.add('a'));
    writes.schedule('b', () async => ran.add('b'));

    final done = writes.flush();
    // Stores read their scoped key on entry, before any await.
    expect(ran, ['a', 'b']);
    expect(writes.hasPending, isFalse);
    return done;
  });

  test('cancel drops a queued write', () async {
    final writes = CoalescedWrites(delay: _delay);
    var ran = false;
    writes.schedule('channel:a', () async => ran = true);
    writes.cancel('channel:a');
    await _wait(120);
    expect(ran, isFalse);
  });

  test('a failing write does not stop the others', () async {
    final writes = CoalescedWrites();
    var ran = false;
    writes.schedule('bad', () => throw StateError('boom'));
    writes.schedule('good', () async => ran = true);
    await writes.flush();
    expect(ran, isTrue);
  });
}
