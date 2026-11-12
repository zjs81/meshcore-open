import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delivers [pending] on the initial queue drain, then answers every later
/// sync with no-more-messages like an empty queue.
class _BacklogRadio extends ReviewRadio {
  _BacklogRadio(this.pending)
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );

  final List<Uint8List> pending;

  @override
  void handle(Uint8List frame) {
    if (frame.isNotEmpty &&
        frame[0] == cmdSyncNextMessage &&
        pending.isNotEmpty) {
      emitForTest(pending.removeAt(0));
      return;
    }
    super.handle(frame);
  }
}

late MeshCoreConnector _connector;

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Channel _channelAt(int slot) =>
    _connector.channels.firstWhere((c) => c.index == slot);

List<ChannelMessage> _messages(int slot) =>
    _connector.getChannelMessages(_channelAt(slot));

ChannelMessage? _find(int slot, String text) {
  for (final m in _messages(slot)) {
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

  test(
    'drain backlog keeps packet time, later arrivals show receive time',
    () async {
      final backlogTs = _nowSecs() - 3600;
      final radio = _BacklogRadio([
        ReviewFrames.channelMessage(
          channelIndex: 2,
          sender: 'Alice',
          message: 'Drained backlog',
          timestampSecs: backlogTs,
        ),
      ]);
      _connector.reviewRadioFactoryForTest = () => radio;
      await _connector.connectReview();
      addTearDown(_connector.disconnect);
      await _waitFor(() => _connector.channelMapConfirmed);
      await _waitFor(() => _find(2, 'Drained backlog') != null);

      final backlog = _find(2, 'Drained backlog')!;
      expect(backlog.receivedLive, isFalse);
      expect(backlog.displayTime.millisecondsSinceEpoch ~/ 1000, backlogTs);

      await _waitFor(() => _connector.queueDrainedForTest);

      final liveTs = _nowSecs();
      _connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: 2,
          sender: 'Alice',
          message: 'Live arrival',
          timestampSecs: liveTs,
        ),
      );
      await _waitFor(() => _find(2, 'Live arrival') != null);

      final live = _find(2, 'Live arrival')!;
      expect(live.receivedLive, isTrue);
      expect(
        live.displayTime.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    },
  );
}
