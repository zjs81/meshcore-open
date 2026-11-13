import 'package:flutter/foundation.dart';

import 'channel_message.dart';
import 'message.dart';

enum BookmarkSourceType { contact, channel }

@immutable
class BookmarkedMessage {
  final BookmarkSourceType sourceType;
  final String sourceId;
  final String sourceName;
  final String messageId;
  final String senderName;
  final String text;
  final String? translatedText;
  final DateTime timestamp;
  final DateTime receivedAt;
  final bool isOutgoing;

  const BookmarkedMessage({
    required this.sourceType,
    required this.sourceId,
    required this.sourceName,
    required this.messageId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.receivedAt,
    required this.isOutgoing,
    this.translatedText,
  });

  factory BookmarkedMessage.fromContact({
    required Message message,
    required String contactKey,
    required String contactName,
    required String senderName,
  }) => BookmarkedMessage(
    sourceType: BookmarkSourceType.contact,
    sourceId: contactKey,
    sourceName: contactName,
    messageId: message.messageId,
    senderName: senderName,
    text: message.text,
    translatedText: message.translatedText,
    timestamp: message.timestamp,
    receivedAt: message.receivedAt,
    isOutgoing: message.isOutgoing,
  );

  factory BookmarkedMessage.fromChannel({
    required ChannelMessage message,
    required String channelId,
    required String channelName,
    required String senderName,
  }) => BookmarkedMessage(
    sourceType: BookmarkSourceType.channel,
    sourceId: channelId,
    sourceName: channelName,
    messageId: message.messageId,
    senderName: senderName,
    text: message.text,
    translatedText: message.translatedText,
    timestamp: message.timestamp,
    receivedAt: message.receivedAt,
    isOutgoing: message.isOutgoing,
  );

  String get storageId => storageIdFor(sourceType, sourceId, messageId);

  static String storageIdFor(
    BookmarkSourceType sourceType,
    String sourceId,
    String messageId,
  ) => '${sourceType.name}:$sourceId:$messageId';

  Map<String, Object?> toJson() => {
    'sourceType': sourceType.name,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'messageId': messageId,
    'senderName': senderName,
    'text': text,
    'translatedText': translatedText,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'receivedAt': receivedAt.millisecondsSinceEpoch,
    'isOutgoing': isOutgoing,
  };

  factory BookmarkedMessage.fromJson(Map<String, dynamic> json) {
    final type = BookmarkSourceType.values.firstWhere(
      (value) => value.name == json['sourceType'],
    );
    return BookmarkedMessage(
      sourceType: type,
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      messageId: json['messageId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      translatedText: json['translatedText'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        json['receivedAt'] as int? ?? json['timestamp'] as int,
      ),
      isOutgoing: json['isOutgoing'] as bool? ?? false,
    );
  }
}
