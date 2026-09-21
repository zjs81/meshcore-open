import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/repeater_command_service.dart';

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
}
