import 'dart:convert';
import 'dart:typed_data';
import 'package:meshcore_open/utils/app_logger.dart';

import '../models/channel_message.dart';
import '../models/message.dart' show legacyAwareReceivedAt;
import '../models/translation_support.dart';
import '../helpers/smaz.dart';
import 'prefs_manager.dart';

class ChannelMessageStore {
  static const String _keyPrefix = 'channel_messages_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  /// Upper bound on persisted messages per channel. The oldest entries
  /// beyond it are dropped on save.
  static const int maxStoredMessages = 1000;

  /// Encoded entries persisted ahead of the connector's in-memory window,
  /// keyed by scoped storage key. A missing entry means the window has not
  /// been reconciled with storage yet, so the next save keeps what is already
  /// stored instead of replacing it. Shared across instances so a store
  /// created by a screen to clear a key also resets the connector's view.
  static final Map<String, List<String>> _archived = {};

  String _keyForChannel(String channelId) => '${keyFor}_$channelId';

  /// Save messages for a specific channel: [messages] is the in-memory
  /// window (oldest first) and is written after the archived entries that
  /// sit ahead of it in storage.
  Future<void> saveChannelMessages(
    String channelId,
    List<ChannelMessage> messages,
  ) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel messages.',
      );
      return;
    }
    final prefs = PrefsManager.instance;
    final key = _keyForChannel(channelId);
    final visibleJson = messages.map(_messageToJson).toList();
    final archived =
        _archived[key] ??
        _unreconciledArchive(prefs.getString(key), visibleJson);
    final overflow = archived.length + visibleJson.length - maxStoredMessages;
    if (overflow > 0) {
      archived.removeRange(0, overflow.clamp(0, archived.length));
    }
    _archived[key] = archived;
    final entries = [...archived, ...visibleJson.map(jsonEncode)];
    await prefs.setString(key, '[${entries.join(',')}]');
  }

  /// Records [olderMessages] as the stored entries that precede the
  /// in-memory window for [channelId].
  void setArchived(String channelId, List<ChannelMessage> olderMessages) {
    _archived[_keyForChannel(channelId)] = olderMessages
        .map((message) => jsonEncode(_messageToJson(message)))
        .toList();
  }

  /// Number of stored entries ahead of the in-memory window, or null when
  /// the window has not been reconciled with storage.
  int? archivedCount(String channelId) =>
      _archived[_keyForChannel(channelId)]?.length;

  /// Removes the newest [count] archived entries after they were paged back
  /// into the in-memory window.
  void unarchiveNewest(String channelId, int count) {
    final archived = _archived[_keyForChannel(channelId)];
    if (archived == null || count <= 0) return;
    archived.removeRange(
      (archived.length - count).clamp(0, archived.length),
      archived.length,
    );
  }

  /// Drops the archive bookkeeping, for one channel or all of them, when the
  /// matching in-memory window is discarded.
  void forgetArchive([String? channelId]) {
    if (channelId == null) {
      _archived.clear();
    } else {
      _archived.remove(_keyForChannel(channelId));
    }
  }

  List<String> _unreconciledArchive(
    String? storedJson,
    List<Map<String, dynamic>> visibleJson,
  ) {
    if (storedJson == null || storedJson.isEmpty) return [];
    final List<dynamic> stored;
    try {
      stored = jsonDecode(storedJson) as List<dynamic>;
    } catch (_) {
      return [];
    }
    final visibleKeys = visibleJson.map(_storedMergeKey).toSet();
    return [
      for (final entry in stored)
        if (entry is Map<String, dynamic> &&
            !visibleKeys.contains(_storedMergeKey(entry)))
          jsonEncode(entry),
    ];
  }

  static String _storedMergeKey(Map<String, dynamic> json) {
    final messageId = json['messageId'];
    if (messageId is String && messageId.isNotEmpty) return 'id:$messageId';
    return 'fallback:${json['timestamp']}:${json['senderName']}:${json['text']}';
  }

  /// Load messages for a specific channel
  Future<List<ChannelMessage>> loadChannelMessages(String channelId) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel messages.',
      );
      return [];
    }
    final jsonString = PrefsManager.instance.getString(
      _keyForChannel(channelId),
    );
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> jsonList;
    try {
      jsonList = jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      appLogger.warn(
        'Stored messages for channel $channelId are unreadable: $e',
      );
      return [];
    }
    final messages = <ChannelMessage>[];
    for (final json in jsonList) {
      try {
        messages.add(_messageFromJson(json as Map<String, dynamic>));
      } catch (e) {
        appLogger.warn('Skipping malformed stored channel message: $e');
      }
    }
    return messages;
  }

  /// Clear messages for a specific channel
  Future<void> clearChannelMessages(String channelId) async {
    final prefs = PrefsManager.instance;
    final key = _keyForChannel(channelId);
    _archived[key] = [];
    await prefs.remove(key);
  }

  /// Clear all channel messages
  Future<void> clearAllChannelMessages() async {
    final prefs = PrefsManager.instance;
    final keys = prefs.getKeys().where((k) => k.startsWith(keyFor)).toList();
    _archived.clear();
    for (var key in keys) {
      await prefs.remove(key);
    }
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
