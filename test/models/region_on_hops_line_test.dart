import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/app_settings.dart';

void main() {
  group('AppSettings.regionOnHopsLine', () {
    test('defaults to off, including for stored settings without the key', () {
      expect(AppSettings().regionOnHopsLine, isFalse);
      final legacy = AppSettings().toJson()..remove('region_on_hops_line');
      expect(AppSettings.fromJson(legacy).regionOnHopsLine, isFalse);
    });

    test('round-trips through JSON and survives copyWith', () {
      final enabled = AppSettings().copyWith(regionOnHopsLine: true);
      expect(AppSettings.fromJson(enabled.toJson()).regionOnHopsLine, isTrue);
      expect(
        enabled.copyWith(enableMessageTracing: true).regionOnHopsLine,
        isTrue,
      );
    });
  });
}
