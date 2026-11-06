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
import 'package:meshcore_open/storage/region_store.dart';
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
  // Let the version-gated config queries go out.
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
    test('SET_DEFAULT_FLOOD_SCOPE layout', () {
      final frame = buildSetDefaultFloodScopeFrame('#eu-west');
      expect(frame.length, 1 + 31 + 16);
      expect(frame[0], cmdSetDefaultFloodScope);
      expect(String.fromCharCodes(frame.sublist(1, 8)), 'eu-west');
      expect(frame.sublist(8, 32).every((b) => b == 0), isTrue);
      expect(frame.sublist(32), floodScopeKeyForRegion('eu-west'));
    });

    test('empty region clears the default', () {
      expect(buildSetDefaultFloodScopeFrame(''), [cmdSetDefaultFloodScope]);
    });

    test('names of 31+ bytes are rejected', () {
      expect(
        () => buildSetDefaultFloodScopeFrame('a' * 31),
        throwsArgumentError,
      );
      expect(buildSetDefaultFloodScopeFrame('a' * 30).length, 48);
    });

    test('DEFAULT_FLOOD_SCOPE reply parses name and key', () {
      final set = buildSetDefaultFloodScopeFrame('eu');
      final reply = Uint8List.fromList([
        respCodeDefaultFloodScope,
        ...set.sublist(1),
      ]);
      final parsed = parseDefaultFloodScopeFrame(reply)!;
      expect(parsed.name, 'eu');
      expect(parsed.key, floodScopeKeyForRegion('eu'));
    });

    test('empty or short DEFAULT_FLOOD_SCOPE reply means none', () {
      expect(
        parseDefaultFloodScopeFrame(
          Uint8List.fromList([respCodeDefaultFloodScope]),
        ),
        isNull,
      );
      expect(
        parseDefaultFloodScopeFrame(
          Uint8List.fromList([respCodeDefaultFloodScope, 0x65, 0x75]),
        ),
        isNull,
      );
    });

    test('explicit unscoped frame and reply mapping', () {
      expect(buildSetFloodScopeUnscopedFrame(), [cmdSetFloodScope, 1]);
      expect(
        replyCodeForCommand(buildGetDefaultFloodScopeFrame()),
        respCodeDefaultFloodScope,
      );
      expect(
        replyCodeForCommand(buildSetDefaultFloodScopeFrame('eu')),
        respCodeOk,
      );
      expect(
        replyCodeForCommand(buildSetFloodScopeUnscopedFrame()),
        respCodeOk,
      );
    });
  });

  group('version gating', () {
    test('ver 10: no default scope query, "no region" sends plain', () async {
      final (connector, radio) = await _connect(10);
      expect(connector.supportsDefaultFloodScope, isFalse);
      expect(connector.supportsExplicitUnscopedFlood, isFalse);
      expect(radio.withCode(cmdGetDefaultFloodScope), isEmpty);

      final channel = connector.channels.first;
      await connector.setChannelRegion(channel.index, kUnscopedRegion);
      await connector.sendChannelMessage(channel, 'hi');
      expect(radio.withCode(cmdSetFloodScope), isEmpty);
    });

    test('ver 11: queries default but never sends [54,1]', () async {
      final (connector, radio) = await _connect(11);
      expect(connector.supportsDefaultFloodScope, isTrue);
      expect(connector.supportsExplicitUnscopedFlood, isFalse);
      expect(radio.withCode(cmdGetDefaultFloodScope), isNotEmpty);

      await connector.setDefaultFloodScope('eu');
      await _waitFor(() => connector.defaultFloodScopeName == 'eu');

      final channel = connector.channels.first;
      await connector.setChannelRegion(channel.index, kUnscopedRegion);
      expect(connector.channelUsesRadioDefaultScope(channel.index), isTrue);
      await connector.sendChannelMessage(channel, 'hi');
      expect(radio.withCode(cmdSetFloodScope), isEmpty);
    });

    test(
      'ver 14: "no region" forces unscoped, default follows radio',
      () async {
        final (connector, radio) = await _connect(14);
        expect(connector.supportsExplicitUnscopedFlood, isTrue);

        await connector.setDefaultFloodScope('eu');
        await _waitFor(() => connector.defaultFloodScopeName == 'eu');
        expect(connector.defaultFloodScopeKey, floodScopeKeyForRegion('eu'));

        final channel = connector.channels.first;
        // Following the default: no scope command, the radio default applies.
        expect(connector.channelUsesRadioDefaultScope(channel.index), isTrue);
        await connector.sendChannelMessage(channel, 'one');
        expect(radio.withCode(cmdSetFloodScope), isEmpty);
        // The stored label names the region the radio actually applied.
        expect(connector.getChannelMessages(channel).last.region, 'eu');

        // Explicit "no region": [54,1] around the send, then reset [54,0].
        await connector.setChannelRegion(channel.index, kUnscopedRegion);
        expect(connector.channelUsesRadioDefaultScope(channel.index), isFalse);
        expect(connector.getEffectiveChannelRegion(channel.index), '');
        await connector.sendChannelMessage(channel, 'two');
        final scopeFrames = radio.withCode(cmdSetFloodScope).toList();
        expect(scopeFrames.map((f) => f.toList()), [
          [cmdSetFloodScope, 1],
          [cmdSetFloodScope, 0],
        ]);
        expect(
          connector.getChannelMessages(channel).last.region,
          anyOf(isNull, isEmpty),
        );

        // Clearing the radio default.
        await connector.setDefaultFloodScope('');
        await _waitFor(() => connector.defaultFloodScopeName == null);
      },
    );

    test(
      'app default "no region" applies to channels without their own',
      () async {
        final (connector, radio) = await _connect(14);
        final channel = connector.channels.first;
        await connector.setDefaultRegion(kUnscopedRegion);
        await connector.sendChannelMessage(channel, 'hi');
        expect(radio.withCode(cmdSetFloodScope).map((f) => f.toList()).first, [
          cmdSetFloodScope,
          1,
        ]);
        // A channel's own region still wins over the app default.
        await connector.setChannelRegion(channel.index, 'eu');
        expect(connector.getEffectiveChannelRegion(channel.index), 'eu');
      },
    );
  });
}
