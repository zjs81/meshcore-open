import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/connector/pending_command_replies.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// Review radio that records every frame the app sends.
class _RecordingRadio extends ReviewRadio {
  _RecordingRadio({required super.firmwareVerCode})
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );

  final List<Uint8List> sent = [];

  @override
  void handle(Uint8List frame) {
    sent.add(Uint8List.fromList(frame));
    super.handle(frame);
  }

  Iterable<Uint8List> withCode(int code) =>
      sent.where((f) => f.isNotEmpty && f[0] == code);
}

// NotificationService is a process-wide singleton whose reply stream can be
// listened to once, so every test shares one connector and reconnects it to a
// fresh radio.
late MeshCoreConnector _connector;

Future<(MeshCoreConnector, _RecordingRadio)> _connect(int verCode) async {
  final connector = _connector;
  final radio = _RecordingRadio(firmwareVerCode: verCode);
  connector.reviewRadioFactoryForTest = () => radio;
  await connector.connectReview();
  addTearDown(connector.disconnect);
  await _waitFor(
    () => connector.firmwareVerCode == verCode && connector.channels.isNotEmpty,
  );
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return (connector, radio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    _connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    _connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    addTearDown(() {
      _connector.dispose();
      retryService.dispose();
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  group('frames', () {
    test('RUN_CLI_COMMAND layout', () {
      final frame = buildRunCliCommandFrame('ver');
      expect(frame, [cmdRunCliCommand, ...utf8.encode('ver')]);
    });

    test('empty commands are rejected', () {
      expect(() => buildRunCliCommandFrame(''), throwsArgumentError);
    });

    test('commands longer than one frame are rejected', () {
      expect(
        () => buildRunCliCommandFrame('a' * maxFrameSize),
        throwsArgumentError,
      );
      expect(
        buildRunCliCommandFrame('a' * (maxFrameSize - 1)).length,
        maxFrameSize,
      );
    });

    test('CLI_REPLY frame parses reply text', () {
      final frame = Uint8List.fromList([
        respCodeCliReply,
        ...utf8.encode('> on'),
      ]);
      expect(parseCliReplyFrame(frame), '> on');
      expect(parseCliReplyFrame(Uint8List.fromList([respCodeOk])), isNull);
      expect(parseCliReplyFrame(Uint8List(0)), isNull);
    });

    test('RUN_CLI_COMMAND waits for CLI_REPLY', () {
      expect(
        replyCodeForCommand(buildRunCliCommandFrame('ver')),
        respCodeCliReply,
      );
    });
  });

  group('version gating', () {
    test('ver 13: CLI unsupported and never sent', () async {
      final (connector, radio) = await _connect(13);
      expect(connector.supportsCompanionCli, isFalse);
      await expectLater(connector.runCliCommand('ver'), throwsUnsupportedError);
      expect(radio.withCode(cmdRunCliCommand), isEmpty);
    });

    test('ver 14: CLI commands round-trip', () async {
      final (connector, radio) = await _connect(14);
      expect(connector.supportsCompanionCli, isTrue);

      expect(await connector.runCliCommand('ver'), 'v1.18.0 (review)');
      expect(await connector.runCliCommand('get radio.rxgain'), '> off');
      expect(await connector.runCliCommand('set radio.rxgain on'), 'OK');
      expect(await connector.runCliCommand('get radio.rxgain'), '> on');
      expect(await connector.runCliCommand('bogus'), 'Unknown command');

      final sent = radio.withCode(cmdRunCliCommand).toList();
      expect(sent.length, 5);
      expect(
        parseCliReplyFrame(
          Uint8List.fromList([respCodeCliReply, ...utf8.encode('> on')]),
        ),
        '> on',
      );
    });
  });
}
