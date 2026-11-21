import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

Contact _contact({int pathLength = 1, List<int> path = const [0x11]}) =>
    Contact(
      publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      name: 'Test',
      type: 1,
      pathLength: pathLength,
      path: Uint8List.fromList(path),
      lastSeen: DateTime.now(),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
  });

  test('rotation sends direct attempts, then flood, then stops', () async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.updateSettings(
      settings.settings.copyWith(
        autoRouteRotationEnabled: true,
        directRetries: 1,
        floodRetries: 1,
      ),
    );

    final service = MessageRetryService(
      sentWatchdogGrace: const Duration(milliseconds: 5),
    );
    addTearDown(service.dispose);
    final sends = <int>[];
    final thresholds = <int>[];
    service.initialize(
      RetryServiceConfig(
        sendMessage: (_, _, attempt, _) async {
          sends.add(attempt);
        },
        addMessage: (_, _) {},
        updateMessage: (_) {},
        calculateTimeout: (_, _, {String? contactKey, int? deviceTimeoutMs}) =>
            15,
        appSettingsService: settings,
        selectRetryPath: (_, attemptIndex, directRetries, _) {
          thresholds.add(directRetries);
          if (attemptIndex >= directRetries) {
            return const PathSelection(
              pathBytes: [],
              hopCount: -1,
              useFlood: true,
            );
          }
          return const PathSelection(
            pathBytes: [0x22],
            hopCount: 1,
            useFlood: false,
          );
        },
      ),
    );

    await service.sendMessageWithRetry(contact: _contact(), text: 'hello');
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    expect(sends, [0, 1]);
    expect(thresholds, [1, 1]);
  });

  test('rotation off keeps retrying a direct path without flooding', () async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.updateSettings(
      settings.settings.copyWith(
        autoRouteRotationEnabled: false,
        directRetries: 2,
        floodRetries: 5,
      ),
    );

    final service = MessageRetryService(
      sentWatchdogGrace: const Duration(milliseconds: 5),
    );
    addTearDown(service.dispose);
    final sends = <int>[];
    var picked = false;
    service.initialize(
      RetryServiceConfig(
        sendMessage: (_, _, attempt, _) async {
          sends.add(attempt);
        },
        addMessage: (_, _) {},
        updateMessage: (_) {},
        calculateTimeout: (_, _, {String? contactKey, int? deviceTimeoutMs}) =>
            15,
        appSettingsService: settings,
        selectRetryPath: (_, _, _, _) {
          picked = true;
          return const PathSelection(
            pathBytes: [],
            hopCount: -1,
            useFlood: true,
          );
        },
      ),
    );

    await service.sendMessageWithRetry(contact: _contact(), text: 'hello');
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    expect(sends, [0, 1]);
    expect(picked, isFalse);
  });

  test('a flood path without rotation stops after the flood budget', () async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.updateSettings(
      settings.settings.copyWith(
        autoRouteRotationEnabled: false,
        directRetries: 4,
        floodRetries: 1,
      ),
    );

    final service = MessageRetryService(
      sentWatchdogGrace: const Duration(milliseconds: 5),
    );
    addTearDown(service.dispose);
    final latest = <Message>[];
    final sends = <int>[];
    service.initialize(
      RetryServiceConfig(
        sendMessage: (_, _, attempt, _) async {
          sends.add(attempt);
        },
        addMessage: (_, message) => latest.add(message),
        updateMessage: (message) => latest.add(message),
        calculateTimeout: (_, _, {String? contactKey, int? deviceTimeoutMs}) =>
            15,
        appSettingsService: settings,
      ),
    );

    await service.sendMessageWithRetry(
      contact: _contact(pathLength: -1, path: const []),
      text: 'hello',
    );
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sends, [0]);
    expect(latest.last.status, MessageStatus.failed);
  });

  test(
    'flood-only rotation floods saved direct contact even if selector returns null',
    () async {
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.updateSettings(
        settings.settings.copyWith(
          autoRouteRotationEnabled: true,
          directRetries: 0,
          floodRetries: 1,
        ),
      );

      final service = MessageRetryService(
        sentWatchdogGrace: const Duration(milliseconds: 5),
      );
      addTearDown(service.dispose);
      final latest = <Message>[];
      final sends = <int>[];
      var clearedCount = 0;
      var setPathCount = 0;
      service.initialize(
        RetryServiceConfig(
          sendMessage: (_, _, attempt, _) async {
            sends.add(attempt);
          },
          addMessage: (_, message) => latest.add(message),
          updateMessage: (message) => latest.add(message),
          clearContactPath: (_) async {
            clearedCount++;
          },
          setContactPath: (_, _, _) async {
            setPathCount++;
          },
          calculateTimeout:
              (_, _, {String? contactKey, int? deviceTimeoutMs}) => 15,
          appSettingsService: settings,
          selectRetryPath: (_, _, _, _) => null,
        ),
      );

      await service.sendMessageWithRetry(
        contact: _contact(pathLength: 1, path: const [0x11]),
        text: 'hello',
      );
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(sends, [0]);
      expect(clearedCount, 1);
      expect(setPathCount, 0);
      expect(latest.last.pathLength, -1);
      expect(latest.last.pathBytes, isEmpty);
      expect(latest.last.status, MessageStatus.failed);
    },
  );

  test(
    'rotation with direct attempts > 0 tries direct paths before flooding',
    () async {
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.updateSettings(
        settings.settings.copyWith(
          autoRouteRotationEnabled: true,
          directRetries: 2,
          floodRetries: 1,
        ),
      );

      final service = MessageRetryService(
        sentWatchdogGrace: const Duration(milliseconds: 5),
      );
      addTearDown(service.dispose);
      final actions = <String>[];
      final sends = <int>[];
      service.initialize(
        RetryServiceConfig(
          sendMessage: (_, _, attempt, _) async {
            sends.add(attempt);
          },
          addMessage: (_, _) {},
          updateMessage: (_) {},
          clearContactPath: (_) async => actions.add('flood'),
          setContactPath: (_, bytes, _) async =>
              actions.add('direct:${bytes.join(',')}'),
          calculateTimeout:
              (_, _, {String? contactKey, int? deviceTimeoutMs}) => 15,
          appSettingsService: settings,
          selectRetryPath: (_, attemptIndex, directRetries, _) {
            if (attemptIndex >= directRetries) return null;
            return attemptIndex == 0
                ? const PathSelection(
                    pathBytes: [0x22],
                    hopCount: 1,
                    useFlood: false,
                  )
                : const PathSelection(
                    pathBytes: [0x33],
                    hopCount: 1,
                    useFlood: false,
                  );
          },
        ),
      );

      await service.sendMessageWithRetry(
        contact: _contact(pathLength: 1, path: const [0x11]),
        text: 'hello',
      );
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 3500));

      expect(sends, [0, 1, 2]);
      expect(actions, ['direct:34', 'direct:51', 'flood']);
    },
  );
}
