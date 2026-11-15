import 'dart:convert';
import 'dart:typed_data';
import 'package:meshcore_open/utils/app_logger.dart';

import '../models/channel_message.dart';
import '../models/message.dart' show legacyAwareReceivedAt;
import '../models/translation_support.dart';
import '../helpers/smaz.dart';
import 'history_archive.dart';
import 'history_store.dart';

class ChannelMessageStore {
  static const String _keyPrefix = 'channel_messages_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  /// Upper bound on persisted messages per channel. The oldest entries
  /// beyond it are dropped on save.
  static const int maxStoredMessages = 1000;

  static final HistoryArchive _archive = HistoryArchive(
    mergeKey: _storedMergeKey,
    maxEntries: maxStoredMessages,
  );

  String _keyForChannel(String channelId) => '${keyFor}_$channelId';

  Future<void> saveChannelMessages(
    String channelId,
    List<ChannelMessage> messages,
  ) {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save messages.');
      return Future<void>.value();
    }
    return _archive.save(_keyForChannel(channelId), [
      for (final message in messages) jsonEncode(_messageToJson(message)),
    ]);
  }

  /// The stored prefix stays in the database, rather than another JSON cache.
  void setArchivedCount(String channelId, int count) =>
      _archive.setArchivedCount(_keyForChannel(channelId), count);

  void archive(String channelId, List<ChannelMessage> messages) =>
      _archive.archive(
        _keyForChannel(channelId),
        messages.map((message) => jsonEncode(_messageToJson(message))),
      );

  int? archivedCount(String channelId) =>
      _archive.archivedCount(_keyForChannel(channelId));

  void forgetArchive([String? channelId]) =>
      _archive.forget(channelId == null ? null : _keyForChannel(channelId));

  static String _storedMergeKey(Map<String, dynamic> json) {
    final messageId = json['messageId'];
    if (messageId is String && messageId.isNotEmpty) return 'id:$messageId';
    return 'fallback:${json['timestamp']}:${json['senderName']}:${json['text']}';
  }

  Future<List<ChannelMessage>> loadChannelMessages(
    String channelId, {
    int offset = 0,
    int? limit,
  }) async {
    if (publicKeyHex.isEmpty) return [];
    final key = _keyForChannel(channelId);
    try {
      final entries = await HistoryStore.instance.readEntries(
        key,
        offset: offset,
        limit: limit,
      );
      return _decodeMessages(entries);
    } catch (error) {
      appLogger.warn(
        'Stored messages for channel $channelId are unreadable: $error',
      );
      return [];
    }
  }

  Future<({List<ChannelMessage> messages, int start, int end, int total})>
  loadMessagePage(String channelId, {int? before, int limit = 50}) async {
    RangeError.checkNotNegative(limit, 'limit');
    if (publicKeyHex.isEmpty) {
      return (messages: <ChannelMessage>[], start: 0, end: 0, total: 0);
    }
    final key = _keyForChannel(channelId);
    try {
      return await _archive.readPage(
        key,
        await HistoryStore.instance.entryCount(key),
        _decodeMessages,
        before: before,
        limit: limit,
      );
    } on FormatException catch (error) {
      appLogger.warn(
        'Stored messages for channel $channelId are unreadable: $error',
      );
      return (messages: <ChannelMessage>[], start: 0, end: 0, total: 0);
    }
  }

  List<ChannelMessage> _decodeMessages(List<String> entries) {
    final messages = <ChannelMessage>[];
    for (final entry in entries) {
      try {
        messages.add(
          _messageFromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (error) {
        appLogger.warn('Skipping malformed stored channel message: $error');
      }
    }
    return messages;
  }

  Future<void> updateBookmarkFlag(
    String channelId,
    String messageId,
    bool isBookmarked,
  ) => _archive.updateBookmarkFlag(
    _keyForChannel(channelId),
    messageId,
    isBookmarked,
  );

  Future<void> clearChannelMessages(String channelId) =>
      _archive.clear(HistoryStore.instance, _keyForChannel(channelId));

  Future<void> clearAllChannelMessages() async {
    final store = HistoryStore.instance;
    final prefix = keyFor;
    final keys = (await store.getKeys())
        .where((key) => key.startsWith(prefix))
        .toList();
    await Future.wait(keys.map((key) => _archive.clear(store, key)));
  }

  /// Convert ChannelMessage to JSON map
  Map<String, dynamic> _messageToJson(ChannelMessage msg) {
    return {
      'senderKey': msg.senderKey != null ? base64Encode(msg.senderKey!) : null,
      'senderName': msg.senderName,
      'text': msg.text,
      'originalText': msg.originalText,
      'translatedText': msg.translatedText,
      'translatedLanguageCode': msg.translatedLanguageCode,
      'translationStatus': msg.translationStatus.value,
      'translationModelId': msg.translationModelId,
      'timestamp': msg.timestamp.millisecondsSinceEpoch,
      'receivedAt': msg.receivedAt.millisecondsSinceEpoch,
      'isOutgoing': msg.isOutgoing,
      'isBookmarked': msg.isBookmarked,
      'status': msg.status.index,
      'channelIndex': msg.channelIndex,
      'region': msg.region,
      'repeatCount': msg.repeatCount,
      'pathLength': msg.pathLength,
      'pathHashWidth': msg.pathHashWidth,
      'pathBytes': base64Encode(msg.pathBytes),
      'pathVariants': msg.pathVariants.map(base64Encode).toList(),
      'repeats': msg.repeats.map(_repeatToJson).toList(),
      'messageId': msg.messageId,
      'packetHash': msg.packetHash,
      'replyToMessageId': msg.replyToMessageId,
      'replyToSenderName': msg.replyToSenderName,
      'replyToText': msg.replyToText,
      'reactions': msg.reactions,
      if (msg.filterReason != null) 'filterReason': msg.filterReason,
      if (msg.filterDetail != null) 'filterDetail': msg.filterDetail,
      // `text` is stored decoded; legacy records without this flag may still
      // hold a Smaz payload.
      'plainText': true,
    };
  }

  /// Convert JSON map to ChannelMessage
  ChannelMessage _messageFromJson(Map<String, dynamic> json) {
    final rawText = json['text'] as String;
    final decodedText = json['plainText'] == true
        ? rawText
        : (Smaz.tryDecodePrefixed(rawText) ?? rawText);

    final rawPathLength = json['pathLength'] as int?;
    final rawPathBytes = json['pathBytes'] != null
        ? Uint8List.fromList(base64Decode(json['pathBytes'] as String))
        : Uint8List(0);
    final rawPathHashWidth = json['pathHashWidth'] as int?;

    int? decodedPathLength = rawPathLength;
    Uint8List decodedPathBytes = rawPathBytes;
    int? decodedPathHashWidth = rawPathHashWidth;

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
        decodedPathHashWidth = width;
        if (byteLen <= rawPathBytes.length) {
          decodedPathBytes = rawPathBytes.sublist(0, byteLen);
        } else {
          decodedPathBytes = Uint8List(0);
        }
      } else if (rawPathLength == 0) {
        decodedPathBytes = Uint8List(0);
      }
    }

    return ChannelMessage(
      senderKey: json['senderKey'] != null
          ? Uint8List.fromList(base64Decode(json['senderKey']))
          : null,
      senderName: json['senderName'] as String? ?? 'Unknown',
      text: decodedText,
      originalText: json['originalText'] as String?,
      translatedText: json['translatedText'] as String?,
      translatedLanguageCode: json['translatedLanguageCode'] as String?,
      translationStatus: parseMessageTranslationStatus(
        json['translationStatus'],
      ),
      translationModelId: json['translationModelId'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      receivedAt: legacyAwareReceivedAt(json),
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      status: _statusAt(json['status']) ?? ChannelMessageStatus.failed,
      repeatCount: (json['repeatCount'] as int?) ?? 0,
      pathLength: decodedPathLength,
      pathHashWidth: decodedPathHashWidth,
      pathBytes: decodedPathBytes,
      pathVariants: (json['pathVariants'] as List<dynamic>?)
          ?.map((entry) => Uint8List.fromList(base64Decode(entry as String)))
          .toList(),
      repeats:
          (json['repeats'] as List<dynamic>?)
              ?.map((entry) => _repeatFromJson(entry as Map<String, dynamic>))
              .toList() ??
          const [],
      channelIndex: json['channelIndex'] as int?,
      region: json['region'] as String?,
      messageId: json['messageId'] as String?,
      packetHash: json['packetHash'] as String?,
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToText: json['replyToText'] as String?,
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
      filterReason: json['filterReason'] as String?,
      filterDetail: json['filterDetail'] as String?,
    );
  }

  Map<String, dynamic> _repeatToJson(Repeat repeat) {
    return {
      'repeaterKey': repeat.repeaterKey != null
          ? base64Encode(repeat.repeaterKey!)
          : null,
      'repeaterName': repeat.repeaterName,
      'tripTimeMs': repeat.tripTimeMs,
      'path': repeat.path?.map((bytes) => base64Encode(bytes)).toList() ?? [],
    };
  }

  Repeat _repeatFromJson(Map<String, dynamic> json) {
    return Repeat(
      repeaterKey: json['repeaterKey'] != null
          ? Uint8List.fromList(base64Decode(json['repeaterKey']))
          : null,
      repeaterName: json['repeaterName'] as String? ?? 'Unknown',
      tripTimeMs: json['tripTimeMs'] as int? ?? 0,
      path: (json['path'] as List<dynamic>?)
          ?.map((entry) => Uint8List.fromList(base64Decode(entry as String)))
          .toList(),
    );
  }

  /// Out-of-range or non-int values yield null; `elementAtOrNull` throws on
  /// negative indexes.
  static ChannelMessageStatus? _statusAt(Object? value) {
    if (value is! int ||
        value < 0 ||
        value >= ChannelMessageStatus.values.length) {
      return null;
    }
    return ChannelMessageStatus.values[value];
  }
}
