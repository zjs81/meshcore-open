import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/smaz.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/chat_compression_mode.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/history_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _deviceScope = 'abcdef012345';
const _contactHex =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _channelId = '0123456789abcdef';
const _compressibleText =
    'This is a long enough English sentence that SMAZ compresses smaller.';

Uint8List _legacyDmFrame(Uint8List senderPubKey, String text, int timestamp) {
  final writer = BufferWriter();
  writer.writeByte(respCodeContactMsgRecv);
  writer.writeBytes(senderPubKey);
  writer.writeInt32LE(timestamp);
  writer.writeByte(txtTypePlain << 2);
  writer.writeString(text);
  writer.writeByte(0);
  return writer.toBytes();
}

Future<void> _waitFor(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettings.showCompressionIndicator', () {
    test('defaults to false, including for stored JSON without the key', () {
      expect(AppSettings().showCompressionIndicator, isFalse);
      final legacy = AppSettings().toJson()
        ..remove('show_compression_indicator');
      expect(AppSettings.fromJson(legacy).showCompressionIndicator, isFalse);
    });

    test(
      'round-trips through JSON, copyWith, and AppSettingsService',
      () async {
        SharedPreferences.setMockInitialValues({});
        PrefsManager.reset();
        await PrefsManager.initialize();

        final enabled = AppSettings().copyWith(showCompressionIndicator: true);
        expect(
          AppSettings.fromJson(enabled.toJson()).showCompressionIndicator,
          isTrue,
        );
        expect(
          enabled.copyWith(enableMessageTracing: true).showCompressionIndicator,
          isTrue,
        );

        final service = AppSettingsService();
        await service.loadSettings();
        expect(service.settings.showCompressionIndicator, isFalse);

        await service.setShowCompressionIndicator(true);
        expect(service.settings.showCompressionIndicator, isTrue);

        final reloaded = AppSettingsService();
        await reloaded.loadSettings();
        expect(reloaded.settings.showCompressionIndicator, isTrue);
      },
    );
  });

  group('Message & MessageStore SMAZ flag', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      HistoryStore.reset();
      MessageStore().forgetArchive();
    });

    test('Message.fromFrame decodes SMAZ and sets isSmazCompressed', () {
      final sender = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final encoded = Smaz.encodeIfSmaller(_compressibleText);
      expect(encoded, startsWith('s:'));

      final compressedMsg = Message.fromFrame(
        _legacyDmFrame(sender, encoded, 1700000000),
        Uint8List(32),
      )!;
      expect(compressedMsg.text, _compressibleText);
      expect(compressedMsg.isSmazCompressed, isTrue);
      expect(compressedMsg.copyWith(retryCount: 1).isSmazCompressed, isTrue);

      final plainMsg = Message.fromFrame(
        _legacyDmFrame(sender, 'plain hello', 1700000001),
        Uint8List(32),
      )!;
      expect(plainMsg.text, 'plain hello');
      expect(plainMsg.isSmazCompressed, isFalse);
    });

    test(
      'MessageStore persists flag and defaults legacy rows to false',
      () async {
        final store = MessageStore()..setPublicKeyHex = _deviceScope;
        final key = Uint8List.fromList(List.generate(32, (i) => i + 2));
        final compressed = Message.outgoing(
          key,
          _compressibleText,
          isSmazCompressed: true,
        );
        final plain = Message.outgoing(key, 'hi', isSmazCompressed: false);

        await store.saveMessages(_contactHex, [compressed, plain]);
        final loaded = await store.loadMessages(_contactHex);
        expect(loaded, hasLength(2));
        expect(loaded[0].isSmazCompressed, isTrue);
        expect(loaded[1].isSmazCompressed, isFalse);

        // Legacy persisted message without `isSmazCompressed` key defaults to false.
        await HistoryStore.instance.setString(
          '${store.keyFor}$_contactHex',
          jsonEncode([
            {
              'senderKey': base64Encode(key),
              'text': 'legacy plain',
              'timestamp': 1700000002000,
              'receivedAt': 1700000002000,
              'isOutgoing': false,
              'status': MessageStatus.delivered.index,
              'plainText': true,
            },
          ]),
        );
        final legacyLoaded = await store.loadMessages(_contactHex);
        expect(legacyLoaded, hasLength(1));
        expect(legacyLoaded.first.isSmazCompressed, isFalse);
      },
    );
  });

  group('ChannelMessage & ChannelMessageStore SMAZ flag', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      HistoryStore.reset();
      ChannelMessageStore().forgetArchive();
    });

    test('ChannelMessage.fromFrame decodes SMAZ and sets isSmazCompressed', () {
      final encoded = Smaz.encodeIfSmaller(_compressibleText);
      expect(encoded, startsWith('s:'));

      final compressed = ChannelMessage.fromFrame(
        ReviewFrames.channelMessage(
          channelIndex: 0,
          sender: 'Maya',
          message: encoded,
          timestampSecs: 1700000000,
        ),
      )!;
      expect(compressed.text, _compressibleText);
      expect(compressed.isSmazCompressed, isTrue);
      expect(compressed.copyWith(repeatCount: 2).isSmazCompressed, isTrue);

      final plain = ChannelMessage.fromFrame(
        ReviewFrames.channelMessage(
          channelIndex: 0,
          sender: 'Maya',
          message: 'hello camp',
          timestampSecs: 1700000001,
        ),
      )!;
      expect(plain.text, 'hello camp');
      expect(plain.isSmazCompressed, isFalse);
    });

    test(
      'ChannelMessageStore persists flag and defaults legacy rows to false',
      () async {
        final store = ChannelMessageStore()..setPublicKeyHex = _deviceScope;
        final compressed = ChannelMessage.outgoing(
          _compressibleText,
          'Me',
          0,
          isSmazCompressed: true,
        );
        final plain = ChannelMessage.outgoing(
          'short',
          'Me',
          0,
          isSmazCompressed: false,
        );

        await store.saveChannelMessages(_channelId, [compressed, plain]);
        final loaded = await store.loadChannelMessages(_channelId);
        expect(loaded, hasLength(2));
        expect(loaded[0].isSmazCompressed, isTrue);
        expect(loaded[1].isSmazCompressed, isFalse);

        await HistoryStore.instance.setString(
          '${store.keyFor}_$_channelId',
          jsonEncode([
            {
              'senderName': 'Maya',
              'text': 'legacy channel msg',
              'timestamp': 1700000002000,
              'receivedAt': 1700000002000,
              'isOutgoing': false,
              'status': ChannelMessageStatus.sent.index,
              'channelIndex': 0,
              'plainText': true,
            },
          ]),
        );
        final legacyLoaded = await store.loadChannelMessages(_channelId);
        expect(legacyLoaded, hasLength(1));
        expect(legacyLoaded.first.isSmazCompressed, isFalse);
      },
    );
  });

  group('MeshCoreConnector SMAZ tracking', () {
    late MeshCoreConnector connector;
    late MessageRetryService retryService;
    late ReviewRadio radio;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      HistoryStore.reset();
      connector = MeshCoreConnector();
      retryService = MessageRetryService();
      connector.initialize(
        retryService: retryService,
        pathHistoryService: PathHistoryService(StorageService()),
      );
      connector.reviewRadioFactoryForTest = () {
        radio = ReviewRadio(
          scheduledMessageInterval: const Duration(hours: 1),
          ackDelay: const Duration(hours: 1),
          replyDelay: const Duration(hours: 1),
        );
        return radio;
      };
      await connector.connectReview();
      await _waitFor(
        () =>
            connector.channelMapConfirmed &&
            connector.contacts.isNotEmpty &&
            connector.channels.isNotEmpty,
      );
      addTearDown(() async {
        await connector.disconnect();
        connector.dispose();
        retryService.dispose();
      });
    });

    test(
      'records isSmazCompressed on outgoing DM and channel messages',
      () async {
        final contact = connector.contacts.first;
        final channel = connector.channels.first;

        // Mode off: not SMAZ compressed.
        await connector.setContactCompressionMode(
          contact.publicKeyHex,
          ChatCompressionMode.off,
        );
        await connector.sendMessage(contact, _compressibleText);

        // Mode SMAZ: compressible text sets flag, tiny uncompressible text does not.
        await connector.setContactCompressionMode(
          contact.publicKeyHex,
          ChatCompressionMode.smaz,
        );
        await connector.sendMessage(contact, _compressibleText);
        await connector.sendMessage(contact, 'ok');

        // Mode Cyr2Lat: not SMAZ compressed.
        await connector.setContactCompressionMode(
          contact.publicKeyHex,
          ChatCompressionMode.cyr2lat,
        );
        await connector.sendMessage(contact, 'Привет мир');

        final dmMessages = connector.getMessages(contact);
        final recentDms = dmMessages.sublist(dmMessages.length - 4);
        expect(recentDms[0].isSmazCompressed, isFalse);
        expect(recentDms[1].isSmazCompressed, isTrue);
        expect(recentDms[2].isSmazCompressed, isFalse);
        expect(recentDms[3].isSmazCompressed, isFalse);

        // Channel outgoing messages.
        await connector.setChannelCompressionMode(
          channel.index,
          ChatCompressionMode.off,
        );
        await connector.sendChannelMessage(channel, _compressibleText);

        await connector.setChannelCompressionMode(
          channel.index,
          ChatCompressionMode.smaz,
        );
        await connector.sendChannelMessage(channel, _compressibleText);
        await connector.sendChannelMessage(channel, 'ok');

        await connector.setChannelCompressionMode(
          channel.index,
          ChatCompressionMode.cyr2lat,
        );
        await connector.sendChannelMessage(channel, 'Привет мир');

        final chMessages = connector.getChannelMessages(channel);
        final recentCh = chMessages.sublist(chMessages.length - 4);
        expect(recentCh[0].isSmazCompressed, isFalse);
        expect(recentCh[1].isSmazCompressed, isTrue);
        expect(recentCh[2].isSmazCompressed, isFalse);
        expect(recentCh[3].isSmazCompressed, isFalse);

        // Ensure radio reference stays live without lint warnings.
        expect(radio, isNotNull);
      },
    );
  });
}
