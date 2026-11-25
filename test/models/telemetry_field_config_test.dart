import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/models/telemetry_field_config.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  group('TelemetryFieldConfig', () {
    test('loads empty when nothing is stored', () {
      final config = TelemetryFieldConfig.load('aabbcc');
      expect(config.overrides, isEmpty);
      expect(config.overrideFor(2, 'temperature'), isNull);
    });

    test('keyFor combines channel and field', () {
      expect(TelemetryFieldConfig.keyFor(2, 'analogInput'), '2:analogInput');
    });

    test('save persists label and unit overrides as JSON', () async {
      final config = TelemetryFieldConfig.load('aabbcc');
      await config.save({
        '2:analogInput': const TelemetryFieldOverride(
          label: 'Tank level',
          unit: '%',
        ),
      });

      final reloaded = TelemetryFieldConfig.load('aabbcc');
      final override = reloaded.overrideFor(2, 'analogInput');
      expect(override, isNotNull);
      expect(override!.label, 'Tank level');
      expect(override.unit, '%');
    });

    test('same field on another channel is stored separately', () async {
      final config = TelemetryFieldConfig.load('aabbcc');
      await config.save({
        '1:temperature': const TelemetryFieldOverride(label: 'MCU'),
        '3:temperature': const TelemetryFieldOverride(label: 'Outside'),
      });

      final reloaded = TelemetryFieldConfig.load('aabbcc');
      expect(reloaded.overrideFor(1, 'temperature')!.label, 'MCU');
      expect(reloaded.overrideFor(3, 'temperature')!.label, 'Outside');
    });

    test('saving an empty override removes the entry', () async {
      final config = TelemetryFieldConfig.load('aabbcc');
      await config.save({
        '2:analogInput': const TelemetryFieldOverride(
          label: 'Tank level',
          unit: '%',
        ),
      });
      await config.save({'2:analogInput': const TelemetryFieldOverride()});

      final reloaded = TelemetryFieldConfig.load('aabbcc');
      expect(reloaded.overrideFor(2, 'analogInput'), isNull);
    });

    test('removing the last entry drops the storage key', () async {
      final config = TelemetryFieldConfig.load('aabbcc');
      await config.save({
        '2:analogInput': const TelemetryFieldOverride(label: 'Tank level'),
      });
      await config.save({'2:analogInput': const TelemetryFieldOverride()});
      expect(
        PrefsManager.instance.getString(
          TelemetryFieldConfig.storageKeyFor('aabbcc'),
        ),
        isNull,
      );
    });

    test('malformed stored JSON loads as empty', () {
      PrefsManager.instance.setString(
        TelemetryFieldConfig.storageKeyFor('aabbcc'),
        'not json',
      );
      final config = TelemetryFieldConfig.load('aabbcc');
      expect(config.overrides, isEmpty);
    });
  });
}
