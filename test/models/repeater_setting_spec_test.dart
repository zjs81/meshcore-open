import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/repeater_setting_spec.dart';

void main() {
  test('every spec is well formed', () {
    final keys = repeaterSettingSpecs.map((s) => s.key).toList();
    expect(keys.toSet().length, keys.length, reason: 'duplicate keys');
    for (final spec in repeaterSettingSpecs) {
      switch (spec.input) {
        case RepeaterSettingInput.slider:
          expect(spec.min, isNotNull, reason: spec.key);
          expect(spec.max, isNotNull, reason: spec.key);
          expect(spec.min! < spec.max!, isTrue, reason: spec.key);
        case RepeaterSettingInput.choice:
          expect(spec.choices, isNotEmpty, reason: spec.key);
        case RepeaterSettingInput.number:
          expect(
            spec.min != null && spec.max != null,
            isTrue,
            reason: spec.key,
          );
        case RepeaterSettingInput.toggle:
        case RepeaterSettingInput.text:
          break;
      }
    }
  });

  group('extra.sf', () {
    final spec = repeaterSettingSpecsByKey['extra.sf']!;

    test('reads the prefix-less reply', () {
      expect(spec.parseRawReply!('9,10'), '9,10');
      expect(spec.parseRawReply!('No extra SF configured'), '');
      // Firmware built without LR2021 support.
      expect(spec.parseRawReply!('unknown config: extra.sf'), isNull);
    });

    test('accepts up to three spreading factors from 5 to 12', () {
      expect(spec.validate!(''), isTrue);
      expect(spec.validate!('9, 10'), isTrue);
      expect(spec.validate!('5,6,7,8'), isFalse);
      expect(spec.validate!('13'), isFalse);
      expect(spec.encode!('9, 10'), '9,10');
    });
  });

  test('owner info round-trips newlines through the firmware form', () {
    final spec = repeaterSettingSpecsByKey['owner.info']!;
    expect(spec.encode!('a\nb'), 'a|b');
    expect(spec.decode!('a|b'), 'a\nb');
  });
}
