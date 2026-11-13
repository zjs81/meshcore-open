import 'dart:convert';
import 'dart:typed_data';

import '../models/message.dart';
import '../models/translation_support.dart';
import '../helpers/smaz.dart';
import '../utils/app_logger.dart';
import 'legacy_key_migration.dart';
import 'history_archive.dart';
import 'history_store.dart';

class MessageStore {
  static const String _keyPrefix = 'messages_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  /// Upper bound on persisted messages per conversation. The oldest entries
  /// beyond it are dropped on save.
  static const int maxStoredMessages = 1000;

  static final HistoryArchive _archive = HistoryArchive(
    mergeKey: _storedMergeKey,
    maxEntries: maxStoredMessages,
  );

  Future<void> saveMessages(String contactKeyHex, List<Message> messages) {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save messages.');
      return Future<void>.value();
    }
    final key = '$keyFor$contactKeyHex';
    final scope = publicKeyHex;
    return _archive.save(
      key,
      [for (final message in messages) jsonEncode(_messageToJson(message))],
      readStored: (store) =>
          _readStored(store, key, '$_keyPrefix$contactKeyHex', scope),
    );
  }

  /// The stored prefix stays in the database, rather than another JSON cache.
  void setArchivedCount(String contactKeyHex, int count) =>
      _archive.setArchivedCount('$keyFor$contactKeyHex', count);

  void archive(String contactKeyHex, List<Message> messages) =>
      _archive.archive(
        '$keyFor$contactKeyHex',
        messages.map((message) => jsonEncode(_messageToJson(message))),
      );

  int? archivedCount(String contactKeyHex) =>
      _archive.archivedCount('$keyFor$contactKeyHex');

  void forgetArchive([String? contactKeyHex]) =>
      _archive.forget(contactKeyHex == null ? null : '$keyFor$contactKeyHex');

  static String _storedMergeKey(Map<String, dynamic> json) {
    final messageId = json['messageId'];
    if (messageId is String && messageId.isNotEmpty) return 'id:$messageId';
    return 'fallback:${json['timestamp']}:${json['isOutgoing']}:${json['text']}';
  }

  Future<String?> _readStored(
    HistoryStore store,
    String key,
    String oldKey,
    String scope,
  ) async {
    final raw = await store.getString(key);
    if ((raw == null || raw.isEmpty) && canMigrateLegacyKeys(scope)) {
      final legacy = await store.getString(oldKey);
      if (legacy != null && legacy.isNotEmpty) {
        if (await store.setString(key, legacy)) await store.remove(oldKey);
      }
      return legacy;
    }
    return raw;
  }

  Future<({String key, int count})> _storedHistory(String contactKeyHex) async {
    final store = HistoryStore.instance;
    final scope = publicKeyHex;
    final key = '$keyFor$contactKeyHex';
    var count = await store.entryCount(key);
    if (count > 0) return (key: key, count: count);
    final raw = await store.getString(key);
    if ((raw == null || raw.isEmpty) && canMigrateLegacyKeys(scope)) {
      final oldKey = '$_keyPrefix$contactKeyHex';
      final legacy = await store.getString(oldKey);
      if (legacy != null && legacy.isNotEmpty) {
        if (await store.setString(key, legacy)) {
          await store.remove(oldKey);
          count = await store.entryCount(key);
        } else {
          throw StateError('Could not migrate stored message history');
        }
      }
    }
    if (raw == null && count == 0) {
      final fallback = '$_keyPrefix$scope';
      final fallbackCount = await store.entryCount(fallback);
      if (fallbackCount > 0) {
        final fallbackJson = await store.getString(fallback);
        if (fallbackJson == null || !await store.setString(key, fallbackJson)) {
          throw StateError('Could not migrate fallback message history');
        }
        return (key: key, count: fallbackCount);
      }
    }
    return (key: key, count: count);
  }

  Future<List<Message>> loadMessages(
    String contactKeyHex, {
    int offset = 0,
    int? limit,
  }) async {
    if (publicKeyHex.isEmpty) return [];
    try {
      final history = await _storedHistory(contactKeyHex);
      final entries = await HistoryStore.instance.readEntries(
        history.key,
        offset: offset,
        limit: limit,
      );
      return _decodeMessages(entries);
    } catch (error) {
      appLogger.warn(
        'Stored messages for $contactKeyHex are unreadable: $error',
      );
      return [];
    }
  }

  /// Reads a page backwards using physical stored-row offsets. Malformed
  /// records are skipped without making earlier valid history unreachable.
  Future<({List<Message> messages, int start, int end, int total})>
  loadMessagePage(String contactKeyHex, {int? before, int limit = 50}) async {
    RangeError.checkNotNegative(limit, 'limit');
    if (publicKeyHex.isEmpty) {
      return (messages: <Message>[], start: 0, end: 0, total: 0);
    }
    try {
      final history = await _storedHistory(contactKeyHex);
      return await _archive.readPage(
        history.key,
        history.count,
        _decodeMessages,
        before: before,
        limit: limit,
      );
    } on FormatException catch (error) {
      appLogger.warn(
        'Stored messages for $contactKeyHex are unreadable: $error',
      );
      return (messages: <Message>[], start: 0, end: 0, total: 0);
    }
  }

  List<Message> _decodeMessages(List<String> entries) {
    final messages = <Message>[];
    for (final entry in entries) {
      try {
        messages.add(
          _messageFromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (error) {
        appLogger.warn('Skipping malformed stored message: $error');
      }
    }
    return messages;
  }

  Future<void> clearMessages(String contactKeyHex) {
    if (publicKeyHex.isEmpty) return Future<void>.value();
    return _archive.clear(HistoryStore.instance, '$keyFor$contactKeyHex');
  }

  Map<String, dynamic> _messageToJson(Message msg) {
    return {
      'senderKey': base64Encode(msg.senderKey),
      'text': msg.text,
      'timestamp': msg.timestamp.millisecondsSinceEpoch,
      'receivedAt': msg.receivedAt.millisecondsSinceEpoch,
      'isOutgoing': msg.isOutgoing,
      'isCli': msg.isCli,
      'status': msg.status.index,
      'messageId': msg.messageId,
      'originalText': msg.originalText,
      'translatedText': msg.translatedText,
      'translatedLanguageCode': msg.translatedLanguageCode,
      'translationStatus': msg.translationStatus.value,
      'translationModelId': msg.translationModelId,
      'retryCount': msg.retryCount,
      'estimatedTimeoutMs': msg.estimatedTimeoutMs,
      'expectedAckHash': msg.expectedAckHash,
      'sentAt': msg.sentAt?.millisecondsSinceEpoch,
      'deliveredAt': msg.deliveredAt?.millisecondsSinceEpoch,
      'tripTimeMs': msg.tripTimeMs,
      'pathLength': msg.pathLength,
      'pathBytes': msg.pathBytes.isNotEmpty
          ? base64Encode(msg.pathBytes)
          : null,
      'reactions': msg.reactions,
      'reactionStatuses': msg.reactionStatuses.map(
        (key, value) => MapEntry(key, value.index),
      ),
      'fourByteRoomContactKey': base64Encode(msg.fourByteRoomContactKey),
      // `text` is stored decoded; legacy records without this flag may still
      // hold a Smaz payload.
      'plainText': true,
    };
  }

  Message _messageFromJson(Map<String, dynamic> json) {
    final rawText = json['text'] as String;
    final isCli = json['isCli'] as bool? ?? false;
    final decodedText = isCli || json['plainText'] == true
        ? rawText
        : (Smaz.tryDecodePrefixed(rawText) ?? rawText);

    final rawPathLength = json['pathLength'] as int?;
    final rawPathBytes = json['pathBytes'] != null
        ? Uint8List.fromList(base64Decode(json['pathBytes'] as String))
        : Uint8List(0);

    int? decodedPathLength = rawPathLength;
    Uint8List decodedPathBytes = rawPathBytes;

    if (rawPathLength != null) {
      if (rawPathLength == 0xFF || rawPathLength < 0) {
        decodedPathLength = -1;
        decodedPathBytes = Uint8List(0);
      } else if (rawPathLength >= 64) {
        final mode = (rawPathLength & 0xC0) >> 6;
        final hopCount = rawPathLength & 0x3F;
        final width = mode + 1;
        final byteLen = hopCount * width;
        decodedPathLength = hopCount;
        if (byteLen <= rawPathBytes.length) {
          decodedPathBytes = rawPathBytes.sublist(0, byteLen);
        } else {
          decodedPathBytes = Uint8List(0);
        }
      } else if (rawPathLength == 0) {
        decodedPathBytes = Uint8List(0);
      }
    }

    return Message(
      senderKey: Uint8List.fromList(base64Decode(json['senderKey'] as String)),
      text: decodedText,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      receivedAt: legacyAwareReceivedAt(json),
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      isCli: isCli,
      status: _statusAt(json['status']) ?? MessageStatus.failed,
      messageId: json['messageId'] as String?,
      originalText: json['originalText'] as String?,
      translatedText: json['translatedText'] as String?,
      translatedLanguageCode: json['translatedLanguageCode'] as String?,
      translationStatus: parseMessageTranslationStatus(
        json['translationStatus'],
      ),
      translationModelId: json['translationModelId'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      estimatedTimeoutMs: json['estimatedTimeoutMs'] as int?,
      expectedAckHash: json['expectedAckHash'] as int? ?? 0,
      sentAt: json['sentAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['sentAt'] as int)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt'] as int)
          : null,
      tripTimeMs: json['tripTimeMs'] as int?,
      pathLength: decodedPathLength,
      pathBytes: decodedPathBytes,
      reactions:
          (json['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value is int)
                  ? List<String?>.filled(value, null)
                  : List<String?>.from(value),
            ),
          ) ??
          {},
      reactionStatuses: <String, MessageStatus>{
        for (final entry
            in (json['reactionStatuses'] as Map<String, dynamic>? ??
                    const <String, dynamic>{})
                .entries)
          entry.key: ?_statusAt(entry.value),
      },
      fourByteRoomContactKey: json['fourByteRoomContactKey'] != null
          ? Uint8List.fromList(
              base64Decode(json['fourByteRoomContactKey'] as String),
            )
          : null,
    );
  }

  /// Out-of-range or non-int values yield null; `elementAtOrNull` throws on
  /// negative indexes.
  static MessageStatus? _statusAt(Object? value) {
    if (value is! int || value < 0 || value >= MessageStatus.values.length) {
      return null;
    }
    return MessageStatus.values[value];
  }
}
