import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/review_mode/review_script.dart';
import 'package:meshcore_open/services/message_filter/message_filter_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Uint8List _psk(int slot) =>
    Channel.parsePskHex(ReviewScript.channels[slot].pskHex);

class _TestRadio extends ReviewRadio {
  _TestRadio()
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );
}

Uint8List _logRxGroupText(Uint8List psk, String text, int timestampSecs) {
  final plain = BytesBuilder()
    ..add(
      Uint8List(4)
        ..buffer.asByteData().setUint32(0, timestampSecs, Endian.little),
    )
    ..addByte(0)
    ..add(utf8.encode(text))
    ..addByte(0);
  final padded = Uint8List(((plain.length + 15) ~/ 16) * 16)
    ..setRange(0, plain.length, plain.toBytes());
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(psk));
  final encrypted = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, encrypted, i);
  }
  final key32 = Uint8List(32)..setRange(0, 16, psk);
  final mac = crypto.Hmac(crypto.sha256, key32).convert(encrypted).bytes;
  final channelHash = crypto.sha256.convert(psk).bytes[0];
  return Uint8List.fromList([
    pushCodeLogRxData,
    40, // snr
    0xA0, // rssi
    0x15, // flood route, GRP_TXT payload
    0x00, // no path
    channelHash,
    mac[0],
    mac[1],
    ...encrypted,
  ]);
}

late MeshCoreConnector _connector;
late MessageFilterService _filter;

Future<void> _connect() async {
  final radio = _TestRadio();
  _connector.reviewRadioFactoryForTest = () => radio;
  await _connector.connectReview();
  addTearDown(_connector.disconnect);
  await _waitFor(() => _connector.channelMapConfirmed);
}

Channel _channelAt(int slot) =>
    _connector.channels.firstWhere((c) => c.index == slot);

ChannelMessage? _find(int slot, String text) {
  for (final m in _connector.getChannelMessages(_channelAt(slot))) {
    if (m.text == text) return m;
  }
  return null;
}

int _nowSecs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    _filter = MessageFilterService();
    await _filter.load();
    await _filter.addRule(
      FilterRule(id: MessageFilterService.newRuleId(), pattern: 'meshos'),
    );
    _connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    _connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
      messageFilterService: _filter,
    );
    addTearDown(() {
      _connector.dispose();
      retryService.dispose();
      _filter.dispose();
    });
  });

  test('applyFilterVerdict tags the message, or leaves it alone', () {
    final message = ChannelMessage(
      senderKey: null,
      senderName: 'Sam',
      text: 'hello',
      timestamp: DateTime(2026),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
    );
    expect(
      identical(MeshCoreConnector.applyFilterVerdict(message, null), message),
      isTrue,
    );
    final tagged = MeshCoreConnector.applyFilterVerdict(
      message,
      const FilterVerdict(reason: FilterReason.textRule, detail: 'meshos'),
    );
    expect(tagged.isFiltered, isTrue);
    expect(tagged.filterReason, 'textRule');
    expect(tagged.filterDetail, 'meshos');
  });

  test('a channel message matching a rule is stored tagged and does not '
      'count as unread', () async {
    await _connect();
    final channel = _channelAt(2);
    final unreadBefore = channel.unreadCount;

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Spammer',
        message: 'Try MeshOS today, free download',
        timestampSecs: _nowSecs(),
      ),
    );
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Sam',
        message: 'Anyone up for a hike on Sunday?',
        timestampSecs: _nowSecs() + 1,
      ),
    );
    await _waitFor(() => _find(2, 'Anyone up for a hike on Sunday?') != null);

    final spam = _find(2, 'Try MeshOS today, free download')!;
    expect(spam.filterReason, filterReasonToJson(FilterReason.textRule));
    expect(spam.filterDetail, 'meshos');
    final clean = _find(2, 'Anyone up for a hike on Sunday?')!;
    expect(clean.isFiltered, isFalse);
    // Only the clean message counts as unread.
    expect(channel.unreadCount, unreadBefore + 1);

    expect(_connector.latestVisibleChannelMessage(channel)?.text, clean.text);
    final filtered = _connector.recentFilteredChannelMessages();
    expect(filtered.map((e) => e.$2.messageId), contains(spam.messageId));
    expect(
      filtered.firstWhere((e) => e.$2.messageId == spam.messageId).$1.index,
      2,
    );
  });

  test('an RX-log message matching a rule is stored tagged', () async {
    await _connect();
    final channel = _channelAt(2);
    final unreadBefore = channel.unreadCount;
    _connector.handleFrameForTest(
      _logRxGroupText(_psk(2), 'Bot: get meshos now', _nowSecs()),
    );
    await _waitFor(() => _find(2, 'get meshos now') != null);
    final message = _find(2, 'get meshos now')!;
    expect(message.filterReason, filterReasonToJson(FilterReason.textRule));
    expect(channel.unreadCount, unreadBefore);
    expect(
      _connector.latestVisibleChannelMessage(channel)?.text,
      isNot('get meshos now'),
    );
  });

  test('mark spam and not spam update the stored message', () async {
    await _connect();
    const text = 'Selling radios cheap, message me';
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Trader',
        message: text,
        timestampSecs: _nowSecs(),
      ),
    );
    await _waitFor(() => _find(2, text) != null);
    final message = _find(2, text)!;
    expect(message.isFiltered, isFalse);
    final spamBefore = _filter.spamExampleCount;

    await _connector.markChannelMessageSpam(_channelAt(2), message);
    expect(_find(2, text)!.filterReason, 'manual');
    expect(_find(2, text)!.filterDetail, isNull);
    expect(_filter.spamExampleCount, spamBefore + 1);

    final notSpamBefore = _filter.notSpamExampleCount;
    await _connector.markChannelMessageNotSpam(_channelAt(2), _find(2, text)!);
    expect(_find(2, text)!.isFiltered, isFalse);
    expect(_filter.notSpamExampleCount, notSpamBefore + 1);
  });

  test('spam on a reply whose target is not loaded replaces its clean '
      'example', () async {
    await _connect();
    // Nobody called "Ghost" has posted, so the reply keeps its mention.
    const text = '@[Ghost] cheap radios for sale, message me today';
    const filterText = 'cheap radios for sale, message me today';
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Seller',
        message: text,
        timestampSecs: _nowSecs(),
      ),
    );
    await _waitFor(
      () => _find(2, text) != null && _filter.hasRecentCleanExample(filterText),
    );
    final message = _find(2, text)!;
    expect(message.text, startsWith('@[Ghost]'));

    final spamBefore = _filter.spamExampleCount;
    await _connector.markChannelMessageSpam(_channelAt(2), message);
    expect(_filter.spamExampleCount, spamBefore + 1);
    // The clean example recorded on arrival is gone, not contradicted. Check
    // this example directly: other queued messages can teach the filter while
    // this async test is awaiting the retrain.
    expect(_filter.hasRecentCleanExample(filterText), isFalse);
  });

  test('spam actions only touch the message in the chosen channel', () async {
    await _connect();
    // Any two configured channels.
    final channels = _connector.channels.where((c) => !c.isEmpty).toList();
    expect(channels.length, greaterThanOrEqualTo(2));
    final first = channels[0];
    final second = channels[1];
    const text = 'Same words posted to two channels at once';
    final ts = _nowSecs();
    for (final channel in [first, second]) {
      _connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: channel.index,
          sender: 'Twin',
          message: text,
          timestampSecs: ts,
        ),
      );
    }
    await _waitFor(
      () =>
          _find(first.index, text) != null && _find(second.index, text) != null,
    );
    final inFirst = _find(first.index, text)!;
    final inSecond = _find(second.index, text)!;
    // Message ids do not include the channel, so these collide.
    expect(inSecond.messageId, inFirst.messageId);

    await _connector.markChannelMessageSpam(second, inSecond);
    expect(_find(second.index, text)!.filterReason, 'manual');
    expect(_find(first.index, text)!.isFiltered, isFalse);

    // Not spam on the first channel must not un-hide the second.
    await _connector.markChannelMessageSpam(first, _find(first.index, text)!);
    await _connector.markChannelMessageNotSpam(
      first,
      _find(first.index, text)!,
    );
    expect(_find(first.index, text)!.isFiltered, isFalse);
    expect(_find(second.index, text)!.filterReason, 'manual');
  });

  test('channels excluded from filtering keep every message visible', () async {
    await _connect();
    final channel = _channelAt(2);
    await _filter.setChannelExcluded(
      MeshCoreConnector.messageFilterChannelId(channel),
      true,
    );
    addTearDown(
      () => _filter.setChannelExcluded(
        MeshCoreConnector.messageFilterChannelId(channel),
        false,
      ),
    );
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Spammer',
        message: 'meshos in an excluded channel',
        timestampSecs: _nowSecs(),
      ),
    );
    await _waitFor(() => _find(2, 'meshos in an excluded channel') != null);
    expect(_find(2, 'meshos in an excluded channel')!.isFiltered, isFalse);
  });

  test(
    'an exact rule matches a reply by its text without the mention',
    () async {
      await _connect();
      const text = 'exact spam phrase here';
      await _filter.addRule(
        const FilterRule(
          id: 'exact-reply',
          pattern: text,
          match: FilterRuleMatch.exact,
        ),
      );
      addTearDown(() => _filter.removeRule('exact-reply'));
      _connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: 2,
          sender: 'Replier',
          message: '@[Sam] $text',
          timestampSecs: _nowSecs(),
        ),
      );
      // The stored text drops the mention only when the reply target is
      // known; either way the rule sees the text without it.
      ChannelMessage? reply() => _find(2, text) ?? _find(2, '@[Sam] $text');
      await _waitFor(() => reply() != null);
      expect(reply()!.filterReason, 'textRule');
    },
  );

  test('previews include filtered messages when the channel is not '
      'filtered', () async {
    await _connect();
    final channel = _channelAt(2);
    const text = 'meshos preview check';
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Spammer',
        message: text,
        timestampSecs: _nowSecs() + 5,
      ),
    );
    await _waitFor(() => _find(2, text) != null);
    expect(_find(2, text)!.isFiltered, isTrue);
    expect(_connector.latestVisibleChannelMessage(channel)?.text, isNot(text));

    final channelId = MeshCoreConnector.messageFilterChannelId(channel);
    await _filter.setChannelExcluded(channelId, true);
    addTearDown(() => _filter.setChannelExcluded(channelId, false));
    expect(_connector.latestVisibleChannelMessage(channel)?.text, text);
  });

  test('rule changes apply to messages already in the chat', () async {
    await _connect();
    const text = 'Cheap antennas at the swap meet, ask me';
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Vendor',
        message: text,
        timestampSecs: _nowSecs(),
      ),
    );
    await _waitFor(() => _find(2, text) != null);
    expect(_find(2, text)!.isFiltered, isFalse);

    // A new rule hides the message that already arrived...
    await _filter.addRule(const FilterRule(id: 'retro', pattern: 'antennas'));
    expect(
      _find(2, text)!.filterReason,
      filterReasonToJson(FilterReason.textRule),
    );
    expect(_find(2, text)!.filterDetail, 'antennas');

    // ...and deleting it shows the message again.
    await _filter.removeRule('retro');
    expect(_find(2, text)!.isFiltered, isFalse);

    // Other filter reasons are not touched by rule changes.
    await _connector.markChannelMessageSpam(_channelAt(2), _find(2, text)!);
    await _filter.addRule(const FilterRule(id: 'retro2', pattern: 'swap'));
    await _filter.removeRule('retro2');
    expect(_find(2, text)!.filterReason, 'manual');
  });

  test('mesh copies of one message are stored and filtered once', () async {
    await _connect();
    const text = 'Weather net starts at seven tonight on the hill';
    final ts = _nowSecs();
    final cleanBefore = _filter.recentCleanCount;
    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Relay',
        message: text,
        timestampSecs: ts,
      ),
    );
    _connector.handleFrameForTest(_logRxGroupText(_psk(2), 'Relay: $text', ts));
    _connector.handleFrameForTest(_logRxGroupText(_psk(2), 'Relay: $text', ts));
    await _waitFor(() => _find(2, text) != null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final copies = _connector
        .getChannelMessages(_channelAt(2))
        .where((m) => m.text == text)
        .toList();
    expect(copies, hasLength(1));
    // Not mistaken for the sender repeating themselves.
    expect(copies.single.isFiltered, isFalse);
    expect(_filter.recentCleanCount, cleanBefore + 1);
  });
}
