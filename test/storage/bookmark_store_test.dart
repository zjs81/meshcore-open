import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/bookmarked_message.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/storage/bookmark_store.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _deviceKey = 'abcdef012345';
const _channelId = 'channel-psk-id';

BookmarkedMessage _bookmark(
  String id, {
  BookmarkSourceType type = BookmarkSourceType.contact,
}) => BookmarkedMessage(
  sourceType: type,
  sourceId: type == BookmarkSourceType.channel ? _channelId : 'contact-key',
  sourceName: type == BookmarkSourceType.channel ? 'Channel' : 'Contact',
  messageId: id,
  senderName: 'Alice',
  text: 'saved text $id',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
  receivedAt: DateTime.fromMillisecondsSinceEpoch(2000),
  isOutgoing: false,
);

Future<void> _init() async {
  SharedPreferences.setMockInitialValues({});
  PrefsManager.reset();
  await PrefsManager.initialize();
}

void main() {
  test('bookmarks persist independently of channel history', () async {
    await _init();
    final bookmarks = BookmarkStore()..setPublicKeyHex = _deviceKey;
    final channelHistory = ChannelMessageStore()..setPublicKeyHex = _deviceKey;
    await bookmarks.saveBookmark(
      _bookmark('message-1', type: BookmarkSourceType.channel),
    );
    await channelHistory.saveChannelMessages(_channelId, [
      ChannelMessage(
        senderName: 'Alice',
        text: 'saved text message-1',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
        isOutgoing: false,
        messageId: 'message-1',
      ),
    ]);

    await channelHistory.clearChannelMessages(_channelId);

    final loaded = await bookmarks.loadBookmarks();
    expect(loaded, hasLength(1));
    expect(loaded.single.text, 'saved text message-1');
    expect(loaded.single.sourceName, 'Channel');
  });

  test('bookmarks are isolated by radio and can be removed', () async {
    await _init();
    final store = BookmarkStore()..setPublicKeyHex = _deviceKey;
    final bookmark = _bookmark('message-1');
    await store.saveBookmark(bookmark);

    store.setPublicKeyHex = '123456789abc';
    expect(await store.loadBookmarks(), isEmpty);

    store.setPublicKeyHex = _deviceKey;
    await store.removeBookmark(bookmark);
    expect(await store.loadBookmarks(), isEmpty);
  });

  test('queued saves retain bookmarks added together', () async {
    await _init();
    final store = BookmarkStore()..setPublicKeyHex = _deviceKey;

    await Future.wait([
      store.saveBookmark(_bookmark('one')),
      store.saveBookmark(_bookmark('two')),
    ]);

    expect(
      (await store.loadBookmarks()).map((bookmark) => bookmark.messageId),
      ['one', 'two'],
    );
  });
}
