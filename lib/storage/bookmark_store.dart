import 'dart:convert';

import '../models/bookmarked_message.dart';
import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class BookmarkStore {
  static const String _keyPrefix = 'message_bookmarks_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<void> _pendingWrites = Future<void>.value();

  Future<List<BookmarkedMessage>> loadBookmarks() async {
    final writes = _pendingWrites;
    await writes;
    return _readBookmarks(keyFor);
  }

  Future<void> saveBookmark(BookmarkedMessage bookmark) {
    if (publicKeyHex.isEmpty) return Future<void>.value();
    final key = keyFor;
    return _enqueue(() async {
      final bookmarks = await _readBookmarks(key);
      bookmarks.removeWhere(
        (existing) => existing.storageId == bookmark.storageId,
      );
      bookmarks.add(bookmark);
      await _writeBookmarks(key, bookmarks);
    });
  }

  Future<void> removeBookmark(BookmarkedMessage bookmark) {
    if (publicKeyHex.isEmpty) return Future<void>.value();
    final key = keyFor;
    return _enqueue(() async {
      final bookmarks = await _readBookmarks(key);
      bookmarks.removeWhere(
        (existing) => existing.storageId == bookmark.storageId,
      );
      await _writeBookmarks(key, bookmarks);
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _pendingWrites.then((_) => operation());
    _pendingWrites = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  Future<List<BookmarkedMessage>> _readBookmarks(String key) async {
    if (key == _keyPrefix) return [];
    final raw = PrefsManager.instance.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final bookmarks = <BookmarkedMessage>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          bookmarks.add(BookmarkedMessage.fromJson(value));
        } on Object catch (error) {
          appLogger.warn('Skipping malformed bookmark: $error');
        }
      }
      return bookmarks;
    } on FormatException catch (error) {
      appLogger.warn('Stored bookmarks are unreadable: $error');
      return [];
    }
  }

  Future<void> _writeBookmarks(
    String key,
    List<BookmarkedMessage> bookmarks,
  ) async {
    if (!await PrefsManager.instance.setString(
      key,
      jsonEncode(bookmarks.map((bookmark) => bookmark.toJson()).toList()),
    )) {
      throw StateError('Could not save bookmarks');
    }
  }
}
