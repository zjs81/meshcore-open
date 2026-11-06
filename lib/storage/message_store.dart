import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../models/translation_support.dart';
import '../helpers/smaz.dart';
import '../utils/app_logger.dart';
import 'legacy_key_migration.dart';
import 'prefs_manager.dart';

class MessageStore {
  static const String _keyPrefix = 'messages_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  /// Upper bound on persisted messages per conversation. The oldest entries
  /// beyond it are dropped on save.
  static const int maxStoredMessages = 1000;

  /// Encoded entries persisted ahead of the connector's in-memory window,
  /// keyed by scoped storage key. A missing entry means the window has not
  /// been reconciled with storage yet, so the next save keeps what is already
  /// stored instead of replacing it. Shared across instances so a store
  /// created by a screen to clear a key also resets the connector's view.
  static final Map<String, List<String>> _archived = {};

  /// Persists [messages] (the in-memory window, oldest first) after the
  /// archived entries that sit ahead of it in storage.
  Future<void> saveMessages(
    String contactKeyHex,
    List<Message> messages,
  ) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save messages.');
      return;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$contactKeyHex';
    final visibleJson = messages.map(_messageToJson).toList();
    final archived =
        _archived[key] ??
        _unreconciledArchive(_readStored(prefs, contactKeyHex), visibleJson);
    final overflow = archived.length + visibleJson.length - maxStoredMessages;
    if (overflow > 0) {
      archived.removeRange(0, overflow.clamp(0, archived.length));
    }
    _archived[key] = archived;
    final entries = [...archived, ...visibleJson.map(jsonEncode)];
    await prefs.setString(key, '[${entries.join(',')}]');
  }

  /// Records [olderMessages] as the stored entries that precede the
  /// in-memory window for [contactKeyHex].
  void setArchived(String contactKeyHex, List<Message> olderMessages) {
    _archived['$keyFor$contactKeyHex'] = olderMessages
        .map((message) => jsonEncode(_messageToJson(message)))
        .toList();
  }

  /// Moves [messages], just trimmed from the front of the in-memory window,
  /// into the archive so the next save keeps them.
  void archive(String contactKeyHex, List<Message> messages) {
    final archived = _archived['$keyFor$contactKeyHex'];
    // Unreconciled saves keep everything already stored anyway.
    if (archived == null) return;
    archived.addAll(
      messages.map((message) => jsonEncode(_messageToJson(message))),
    );
  }

  /// Number of stored entries ahead of the in-memory window, or null when
  /// the window has not been reconciled with storage.
  int? archivedCount(String contactKeyHex) =>
      _archived['$keyFor$contactKeyHex']?.length;

  /// Removes the newest [count] archived entries after they were paged back
  /// into the in-memory window.
  void unarchiveNewest(String contactKeyHex, int count) {
    final archived = _archived['$keyFor$contactKeyHex'];
    if (archived == null || count <= 0) return;
    archived.removeRange(
      (archived.length - count).clamp(0, archived.length),
      archived.length,
    );
  }

  /// Drops the archive bookkeeping, for one conversation or all of them,
  /// when the matching in-memory window is discarded.
  void forgetArchive([String? contactKeyHex]) {
    if (contactKeyHex == null) {
      _archived.clear();
    } else {
      _archived.remove('$keyFor$contactKeyHex');
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
    return 'fallback:${json['timestamp']}:${json['isOutgoing']}:${json['text']}';
  }

  /// Reads the stored JSON for [contactKeyHex], migrating the legacy unscoped
  /// key on first access.
  String? _readStored(SharedPreferences prefs, String contactKeyHex) {
    final key = '$keyFor$contactKeyHex';
    final oldKey = '$_keyPrefix$contactKeyHex';
    final jsonString = prefs.getString(key);
    if ((jsonString == null || jsonString.isEmpty) &&
        canMigrateLegacyKeys(publicKeyHex)) {
      // Attempt migration from legacy unscoped key on first load
      final legacyJsonString = prefs.getString(oldKey);
      prefs.remove(oldKey);
      if (legacyJsonString != null && legacyJsonString.isNotEmpty) {
        appLogger.info(
          'Migrating messages from legacy key $oldKey to scoped key $key',
        );
        prefs.setString(key, legacyJsonString);
        return legacyJsonString;
      }
    }
    return jsonString;
  }

  Future<List<Message>> loadMessages(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load messages.');
      return [];
    }
    final prefs = PrefsManager.instance;
    String? jsonString = _readStored(prefs, contactKeyHex);
    if (jsonString == null || jsonString.isEmpty) {
      jsonString = prefs.getString(keyFor);
    }
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList;
    try {
      jsonList = jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      appLogger.warn('Stored messages for $contactKeyHex are unreadable: $e');
      return [];
    }
    final messages = <Message>[];
    for (final json in jsonList) {
      try {
        messages.add(_messageFromJson(json as Map<String, dynamic>));
      } catch (e) {
        appLogger.warn('Skipping malformed stored message: $e');
      }
    }
    return messages;
  }

  Future<void> clearMessages(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot clear messages.');
      return;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$contactKeyHex';
    _archived[key] = [];
    await prefs.remove(key);
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
