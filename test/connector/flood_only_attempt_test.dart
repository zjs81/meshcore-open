import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

Contact _directContact() {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
    name: 'Hill',
    type: 1,
    pathLength: 1,
    path: Uint8List.fromList(const [0x11]),
    lastSeen: DateTime.now(),
  );
}

class _ControllablePathStorage extends StorageService {
  Completer<ContactPathHistory?>? loadGate;

  @override
  Future<ContactPathHistory?> loadPathHistory(String contactPubKeyHex) {
    final gate = loadGate;
    if (gate != null && !gate.isCompleted) {
      return gate.future;
    }
    return Future<ContactPathHistory?>.value(null);
  }
}

class _RecordingReviewRadio extends ReviewRadio {
  final List<Uint8List> sent = [];

  _RecordingReviewRadio()
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        // Long ACK delay so retry attempts run on timeout in tests.
        ackDelay: const Duration(hours: 1),
      );

  @override
  void handle(Uint8List frame) {
    sent.add(frame);
    super.handle(frame);
  }
}

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

// NotificationService is a process-wide singleton whose reply stream can be
// listened to once, so every test shares one connector and reconnects it to a
// fresh radio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector connector;
  late _ControllablePathStorage storage;
  late PathHistoryService history;
  late MessageRetryService retries;
  late AppSettingsService settings;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    settings = AppSettingsService();
    await settings.loadSettings();
    connector = MeshCoreConnector();
    storage = _ControllablePathStorage();
    history = PathHistoryService(storage);
    retries = MessageRetryService(
      sentWatchdogGrace: const Duration(milliseconds: 5),
    );
    connector.initialize(
      retryService: retries,
      pathHistoryService: history,
      appSettingsService: settings,
    );
  });

  tearDownAll(() {
    connector.dispose();
    history.dispose();
    retries.dispose();
  });

  setUp(() async {
    storage.loadGate = null;
    await settings.resetRoutingSettingsToDefault();
  });

  test('flood attempts do not wait for route history', () async {
    await settings.updateSettings(
      settings.settings.copyWith(
        autoRouteRotationEnabled: true,
        directRetries: 0,
        floodRetries: 1,
      ),
    );

    final flooded = await connector.preparePathForContactSend(_directContact());
    expect(flooded.useFlood, isTrue);

    await settings.updateSettings(
      settings.settings.copyWith(directRetries: 2, floodRetries: 1),
    );
    final direct = await connector.preparePathForContactSend(_directContact());
    expect(direct.useFlood, isFalse);
    expect(direct.hopCount, 1);
    expect(direct.pathBytes, [0x11]);

    await settings.updateSettings(
      settings.settings.copyWith(directRetries: 0, floodRetries: 0),
    );
    final zeroBudget = await connector.preparePathForContactSend(
      _directContact(),
    );
    expect(zeroBudget.useFlood, isFalse);
    expect(zeroBudget.hopCount, 1);
    expect(zeroBudget.pathBytes, [0x11]);
  });

  test(
    'sendMessage with directRetries 0 and floodRetries 1 floods even when route history is loading',
    () async {
      final gate = Completer<ContactPathHistory?>();
      storage.loadGate = gate;

      final radio = _RecordingReviewRadio();
      connector.reviewRadioFactoryForTest = () => radio;
      await connector.connectReview();
      addTearDown(connector.disconnect);
      await _waitFor(() => connector.contacts.isNotEmpty);

      final directContact = connector.contacts.firstWhere(
        (c) => c.pathLength > 0,
      );
      await settings.updateSettings(
        settings.settings.copyWith(
          autoRouteRotationEnabled: true,
          directRetries: 0,
          floodRetries: 1,
        ),
      );

      radio.sent.clear();
      await connector.sendMessage(directContact, 'flood only');
      await _waitFor(
        () => radio.sent.any((frame) => frame[0] == cmdSendTxtMsg),
      );

      final opCodes = radio.sent
          .map((frame) => frame[0])
          .where(
            (code) =>
                code == cmdResetPath ||
                code == cmdAddUpdateContact ||
                code == cmdSendTxtMsg,
          )
          .toList();
      expect(opCodes, [cmdResetPath, cmdSendTxtMsg]);

      gate.complete(null);
      storage.loadGate = null;
    },
  );

  test(
    'sendMessage with directRetries > 0 rotates through cached paths before flooding',
    () async {
      final radio = _RecordingReviewRadio();
      connector.reviewRadioFactoryForTest = () => radio;
      await connector.connectReview();
      addTearDown(connector.disconnect);
      await _waitFor(() => connector.contacts.isNotEmpty);

      final directContact = connector.contacts.firstWhere(
        (c) => c.pathLength > 0,
      );
      history.recordPathResult(
        directContact.publicKeyHex,
        const PathSelection(pathBytes: [0x22], hopCount: 1, useFlood: false),
        success: true,
      );
      await pumpEventQueue();
      history.recordPathResult(
        directContact.publicKeyHex,
        const PathSelection(pathBytes: [0x33], hopCount: 1, useFlood: false),
        success: true,
      );
      await pumpEventQueue();

      await settings.updateSettings(
        settings.settings.copyWith(
          autoRouteRotationEnabled: true,
          directRetries: 2,
          floodRetries: 1,
        ),
      );

      radio.sent.clear();
      await connector.sendMessage(directContact, 'rotate then flood');
      await _waitFor(
        () =>
            radio.sent.where((frame) => frame[0] == cmdSendTxtMsg).length == 3,
        seconds: 25,
      );

      final pathOps = radio.sent
          .where(
            (frame) =>
                frame[0] == cmdResetPath || frame[0] == cmdAddUpdateContact,
          )
          .map((frame) => frame[0])
          .toList();
      expect(pathOps, [cmdAddUpdateContact, cmdAddUpdateContact, cmdResetPath]);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
