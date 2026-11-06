import 'dart:typed_data';
import '../connector/meshcore_protocol.dart';
import '../helpers/reaction_helper.dart';
import 'translation_support.dart';

enum MessageStatus { pending, sent, delivered, failed }

/// How far a sender timestamp may run ahead of the local receive time before
/// the UI flags it as a wrong clock.
const Duration futureTimestampTolerance = Duration(minutes: 5);

/// Receive time for a persisted message JSON record. Records written before
/// `receivedAt` existed fall back to the sender timestamp, capped at now so a
/// stored future-dated message stops sorting below everything received later.
DateTime legacyAwareReceivedAt(Map<String, dynamic> json) {
  final stored = json['receivedAt'];
  if (stored is int) return DateTime.fromMillisecondsSinceEpoch(stored);
  final timestamp = DateTime.fromMillisecondsSinceEpoch(
    json['timestamp'] as int,
  );
  final now = DateTime.now();
  return timestamp.isAfter(now) ? now : timestamp;
}

class Message {
  static const Object _unset = Object();

  final Uint8List senderKey; // For outgoing msgs, gets used as recipientKey
  final String text;
  final DateTime timestamp;

  /// Local clock time when this message was added (received or sent). Feeds
  /// are ordered by it so a sender clock running ahead cannot pin a message
  /// to the bottom; [timestamp] stays the sender's identity time.
  final DateTime receivedAt;
  final bool isOutgoing;
  final bool isCli;
  final MessageStatus status;
  final String? originalText;
  final String? translatedText;
  final String? translatedLanguageCode;
  final MessageTranslationStatus translationStatus;
  final String? translationModelId;

  // NEW: Retry logic fields
  final String messageId;
  final int retryCount;
  final int? estimatedTimeoutMs;
  final int? expectedAckHash;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final int? tripTimeMs;
  final int? pathLength;
  final Uint8List pathBytes;
  final Map<String, List<String?>> reactions;
  final Map<String, MessageStatus> reactionStatuses;
  final Uint8List fourByteRoomContactKey;

  Message({
    required this.senderKey,
    required this.text,
    required this.timestamp,
    DateTime? receivedAt,
    required this.isOutgoing,
    this.isCli = false,
    this.status = MessageStatus.pending,
    String? messageId,
    this.originalText,
    this.translatedText,
    this.translatedLanguageCode,
    this.translationStatus = MessageTranslationStatus.none,
    this.translationModelId,
    this.retryCount = 0,
    this.estimatedTimeoutMs,
    this.expectedAckHash,
    this.sentAt,
    this.deliveredAt,
    this.tripTimeMs,
    this.pathLength,
    Uint8List? pathBytes,
    Uint8List? fourByteRoomContactKey,
    Map<String, List<String?>>? reactions,
    Map<String, MessageStatus>? reactionStatuses,
  }) : messageId =
           messageId ??
           '${timestamp.millisecondsSinceEpoch}_${pubKeyToHex(senderKey)}_${text.hashCode}',
       receivedAt = receivedAt ?? timestamp,
       pathBytes = pathBytes ?? Uint8List(0),
       fourByteRoomContactKey = fourByteRoomContactKey ?? Uint8List(0),
       reactions = reactions ?? {},
       reactionStatuses = reactionStatuses ?? {};

  String get senderKeyHex => pubKeyToHex(senderKey);

  /// True when the sender's clock put [timestamp] clearly ahead of the time
  /// this device received the message.
  bool get hasFutureTimestamp =>
      timestamp.difference(receivedAt) > futureTimestampTolerance;

  Message copyWith({
    MessageStatus? status,
    int? retryCount,
    int? estimatedTimeoutMs,
    int? expectedAckHash,
    DateTime? sentAt,
    DateTime? deliveredAt,
    int? tripTimeMs,
    int? pathLength,
    Uint8List? pathBytes,
    bool? isCli,
    Object? originalText = _unset,
    Object? translatedText = _unset,
    Object? translatedLanguageCode = _unset,
    MessageTranslationStatus? translationStatus,
    Object? translationModelId = _unset,
    Map<String, List<String?>>? reactions,
    Map<String, MessageStatus>? reactionStatuses,
    Uint8List? fourByteRoomContactKey,
  }) {
    return Message(
      senderKey: senderKey,
      text: text,
      timestamp: timestamp,
      receivedAt: receivedAt,
      isOutgoing: isOutgoing,
      isCli: isCli ?? this.isCli,
      status: status ?? this.status,
      messageId: messageId,
      originalText: originalText == _unset
          ? this.originalText
          : originalText as String?,
      translatedText: translatedText == _unset
          ? this.translatedText
          : translatedText as String?,
      translatedLanguageCode: translatedLanguageCode == _unset
          ? this.translatedLanguageCode
          : translatedLanguageCode as String?,
      translationStatus: translationStatus ?? this.translationStatus,
      translationModelId: translationModelId == _unset
          ? this.translationModelId
          : translationModelId as String?,
      retryCount: retryCount ?? this.retryCount,
      estimatedTimeoutMs: estimatedTimeoutMs ?? this.estimatedTimeoutMs,
      expectedAckHash: expectedAckHash ?? this.expectedAckHash,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      tripTimeMs: tripTimeMs ?? this.tripTimeMs,
      pathLength: pathLength ?? this.pathLength,
      pathBytes: pathBytes ?? this.pathBytes,
      reactions: reactions ?? this.reactions,
      reactionStatuses: reactionStatuses ?? this.reactionStatuses,
      fourByteRoomContactKey:
          fourByteRoomContactKey ?? this.fourByteRoomContactKey,
    );
  }

  static Message? fromFrame(Uint8List frame, Uint8List selfPubKey) {
    if (frame.length < msgTextOffset + 1) return null;
    final reader = BufferReader(frame);
    try {
      final code = reader.readByte();
      if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
        return null;
      }

      final senderKey = reader.readBytes(pubKeySize);
      final timestampRaw = reader.readInt32LE();
      final flags = reader.readByte();
      if ((flags >> 2) != txtTypePlain) {
        return null;
      }
      final text = reader.readCString();

      return Message(
        senderKey: senderKey,
        text: text,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
        receivedAt: DateTime.now(),
        isOutgoing: false,
        isCli: false,
        status: MessageStatus.delivered,
        pathBytes: Uint8List(0),
      );
    } catch (e) {
      return null;
    }
  }

  static Message outgoing(
    Uint8List recipientKey,
    String text, {
    String? originalText,
    String? translatedLanguageCode,
    String? translationModelId,
    int? pathLength,
    Uint8List? pathBytes,
  }) {
    return Message(
      senderKey: recipientKey,
      text: text,
      originalText: originalText,
      translatedLanguageCode: translatedLanguageCode,
      translationModelId: translationModelId,
      timestamp: DateTime.now(),
      isOutgoing: true,
      isCli: false,
      status: MessageStatus.pending,
      pathLength: pathLength,
      pathBytes: pathBytes,
    );
  }

  static ReactionInfo? parseReaction(String text) {
    return ReactionHelper.parseReaction(text);
  }
}
