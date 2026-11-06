import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChannelMessage _msg({String? reason, String? detail}) => ChannelMessage(
  senderName: 'Alice',
  text: 'hello',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
  isOutgoing: false,
  messageId: 'm1',
  filterReason: reason,
  filterDetail: detail,
);

void main() {
  test('isFiltered reflects filterReason', () {
    expect(_msg().isFiltered, isFalse);
    expect(_msg(reason: 'manual').isFiltered, isTrue);
  });

  test('copyWith sets, keeps and clears filter fields', () {
    final filtered = _msg().copyWith(
      filterReason: 'textRule',
      filterDetail: 'spam',
    );
    expect(filtered.filterReason, 'textRule');
    expect(filtered.filterDetail, 'spam');
    final kept = filtered.copyWith(repeatCount: 2);
    expect(kept.filterReason, 'textRule');
    expect(kept.filterDetail, 'spam');
    final cleared = filtered.copyWith(clearFilter: true);
    expect(cleared.isFiltered, isFalse);
    expect(cleared.filterDetail, isNull);
  });

  test('store round-trips filter fields and omits them when null', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    final store = ChannelMessageStore()..setPublicKeyHex = 'abcdef012345';
    store.forgetArchive();
    await store.saveChannelMessages('c1', [
      _msg(reason: 'textRule', detail: 'spam'),
    ]);
    var loaded = await store.loadChannelMessages('c1');
    expect(loaded.single.filterReason, 'textRule');
    expect(loaded.single.filterDetail, 'spam');

    store.forgetArchive();
    await store.saveChannelMessages('c2', [_msg()]);
    loaded = await store.loadChannelMessages('c2');
    expect(loaded.single.filterReason, isNull);
    expect(loaded.single.filterDetail, isNull);
  });
}
