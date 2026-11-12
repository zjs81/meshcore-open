import 'dart:convert';
import 'dart:typed_data';
import '../connector/meshcore_protocol.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/smaz.dart';
import 'message.dart' show futureTimestampTolerance;
import 'translation_support.dart';
import '../utils/app_logger.dart';

enum ChannelMessageStatus { pending, sent, failed }

/// Signal our radio reported when it heard one copy of a packet. The final
/// repeater in the path (or the sender when there is none) transmitted the
/// copy we received, so these measurements describe that last leg.
class PathSignal {
  final double? snrDb;
  final int? rssiDbm;

  const PathSignal({this.snrDb, this.rssiDbm});

  bool get isEmpty => snrDb == null && rssiDbm == null;

  /// Compares signal strength: higher SNR wins, then higher RSSI. Missing
  /// measurements rank below present ones.
  int compareTo(PathSignal other) {
    final snr = (snrDb ?? double.negativeInfinity).compareTo(
      other.snrDb ?? double.negativeInfinity,
    );
    if (snr != 0) return snr;
    return (rssiDbm?.toDouble() ?? double.negativeInfinity).compareTo(
      other.rssiDbm?.toDouble() ?? double.negativeInfinity,
    );
  }

  /// The strongest signal in [signals], or null when it is empty.
  static PathSignal? strongest(Iterable<PathSignal> signals) {
    PathSignal? best;
    for (final signal in signals) {
      if (best == null || signal.compareTo(best) > 0) best = signal;
    }
    return best;
  }
}

class Repeat {
  final Uint8List? repeaterKey;
  final String repeaterName;
  final int tripTimeMs;
  final List<Uint8List>? path;

  Repeat({
    this.repeaterKey,
    required this.repeaterName,
    required this.tripTimeMs,
    this.path,
  });

  String? get repeaterKeyHex =>
      repeaterKey != null ? pubKeyToHex(repeaterKey!) : null;
}

class ChannelMessage {
  static const Object _unset = Object();

  final Uint8List? senderKey;
  final String senderName;
  final String text;
  final String? originalText;
  final String? translatedText;
  final String? translatedLanguageCode;
  final MessageTranslationStatus translationStatus;
  final String? translationModelId;
  final DateTime timestamp;

  /// Local clock time when this message was added (received or sent). Feeds
  /// are ordered by it so a sender clock running ahead cannot pin a message
  /// to the bottom; [timestamp] stays the sender's identity time.
  final DateTime receivedAt;

  /// True when the app received this message while connected to the radio, so
  /// [receivedAt] is the real arrival time and [displayTime] uses it. Backlog
  /// messages synced from the offline queue keep their packet timestamp.
  final bool receivedLive;
  final bool isOutgoing;
  final ChannelMessageStatus status;
  final List<Repeat> repeats;
  final int repeatCount;
  final int? pathLength;
  final int? pathHashWidth;
  final Uint8List pathBytes;
  final List<Uint8List> pathVariants;

  /// SNR (dB) our radio measured for the strongest copy heard. Until repeats
  /// merge it is the copy carried by [pathBytes].
  final double? snrDb;

  /// RSSI (dBm) our radio measured for the strongest copy heard, from the
  /// same copy as [snrDb].
  final int? rssiDbm;

  /// Signals keyed by base64 of each observed path's bytes, so every variant
  /// can show the strongest signal heard for that variant.
  final Map<String, PathSignal> pathSignals;

  final int? channelIndex;
  final String? region;
  final String messageId;
  final String? packetHash;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToText;
  final Map<String, List<String?>> reactions;

  /// Set when the message filter hid this message (a FilterReason JSON name).
  final String? filterReason;

  /// Extra context for [filterReason], e.g. the matching rule pattern.
  final String? filterDetail;

  ChannelMessage({
    this.senderKey,
    required this.senderName,
    required this.text,
    this.originalText,
    this.translatedText,
    this.translatedLanguageCode,
    this.translationStatus = MessageTranslationStatus.none,
    this.translationModelId,
    required this.timestamp,
    DateTime? receivedAt,
    this.receivedLive = false,
    required this.isOutgoing,
    this.status = ChannelMessageStatus.pending,
    this.repeats = const [],
    this.repeatCount = 0,
    this.pathLength,
    this.pathHashWidth,
    Uint8List? pathBytes,
    List<Uint8List>? pathVariants,
    this.snrDb,
    this.rssiDbm,
    Map<String, PathSignal>? pathSignals,
    this.channelIndex,
    this.region,
    String? messageId,
    this.packetHash,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToText,
    Map<String, List<String?>>? reactions,
    this.filterReason,
    this.filterDetail,
  }) : messageId =
           messageId ??
           '${timestamp.millisecondsSinceEpoch}_${senderName.hashCode}_${text.hashCode}',
       receivedAt = receivedAt ?? timestamp,
       reactions = reactions ?? {},
       pathBytes = pathBytes ?? Uint8List(0),
       pathVariants = _mergePathVariants(
         pathBytes ?? Uint8List(0),
         pathVariants,
       ),
       pathSignals = _withPrimarySignal(
         pathBytes ?? Uint8List(0),
         snrDb,
         rssiDbm,
         pathSignals,
       );

  bool get isFiltered => filterReason != null;

  String? get senderKeyHex =>
      senderKey != null ? pubKeyToHex(senderKey!) : null;

  static String pathKey(List<int> pathBytes) => base64Encode(pathBytes);

  PathSignal? signalFor(List<int> pathBytes) => pathSignals[pathKey(pathBytes)];

  /// True when the UI should label this message with [receivedAt]: an
  /// incoming message that arrived while the app was connected.
  bool get showsReceiveTime => !isOutgoing && receivedLive;

  /// Time the UI labels this message with: the real arrival time for live
  /// receives, otherwise the sender's packet timestamp.
  DateTime get displayTime => showsReceiveTime ? receivedAt : timestamp;

  /// True when the sender's clock put [timestamp] clearly ahead of the time
  /// this device received the message. Live receives show [receivedAt], so
  /// the packet clock no longer affects what the user reads.
  bool get hasFutureTimestamp =>
      !showsReceiveTime &&
      timestamp.difference(receivedAt) > futureTimestampTolerance;

  ChannelMessage copyWith({
    ChannelMessageStatus? status,
    List<Repeat>? repeats,
    int? repeatCount,
    int? pathLength,
    int? pathHashWidth,
    Uint8List? pathBytes,
    List<Uint8List>? pathVariants,
    double? snrDb,
    int? rssiDbm,
    Map<String, PathSignal>? pathSignals,
    Object? region = _unset,
    String? packetHash,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToText,
    Object? originalText = _unset,
    Object? translatedText = _unset,
    Object? translatedLanguageCode = _unset,
    MessageTranslationStatus? translationStatus,
    Object? translationModelId = _unset,
    Map<String, List<String?>>? reactions,
    int? channelIndex,
    String? filterReason,
    String? filterDetail,
    bool clearFilter = false,
  }) {
    return ChannelMessage(
      senderKey: senderKey,
      senderName: senderName,
      text: text,
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
      timestamp: timestamp,
      receivedAt: receivedAt,
      receivedLive: receivedLive,
      isOutgoing: isOutgoing,
      status: status ?? this.status,
      repeats: repeats ?? this.repeats,
      repeatCount: repeatCount ?? this.repeatCount,
      pathLength: pathLength ?? this.pathLength,
      pathHashWidth: pathHashWidth ?? this.pathHashWidth,
      pathBytes: pathBytes ?? this.pathBytes,
      pathVariants: pathVariants ?? this.pathVariants,
      snrDb: snrDb ?? this.snrDb,
      rssiDbm: rssiDbm ?? this.rssiDbm,
      pathSignals: pathSignals ?? this.pathSignals,
      channelIndex: channelIndex ?? this.channelIndex,
      region: region == _unset ? this.region : region as String?,
      messageId: messageId,
      packetHash: packetHash ?? this.packetHash,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToText: replyToText ?? this.replyToText,
      reactions: reactions ?? this.reactions,
      filterReason: clearFilter ? null : (filterReason ?? this.filterReason),
      filterDetail: clearFilter ? null : (filterDetail ?? this.filterDetail),
    );
  }

  static ChannelMessage? fromFrame(Uint8List frame, {bool live = false}) {
    // CHANNEL_MSG_RECV format varies by version:
    // V3: [0]=code [1]=SNR [2]=rsv1 [3]=rsv2 [4]=channel_idx [5]=path_len [path... optional] [txt_type] [timestamp x4] [text...]
    // Non-V3: [0]=code [1]=channel_idx [2]=path_len [3]=txt_type [4-7]=timestamp [8+]=text
    if (frame.length < 8) return null;
    try {
      final reader = BufferReader(frame);
      final code = reader.readByte();
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return null;
      }

      int? pathLen;
      int txtType;
      int? packetPathHashWidth;
      double? packetSnrDb;
      Uint8List pathBytes = Uint8List(0);
      int channelIdx;
      if (code == respCodeChannelMsgRecvV3) {
        packetSnrDb = reader.readInt8() / 4.0;
        final flags = reader.readByte();
        final hasPath = (flags & 0x01) != 0;
        reader.skipBytes(1); // Skip reserved byte
        channelIdx = reader.readByte();
        final pathByte = reader.readUInt8();
        // 0xFF = direct-routed; hop count is not reported.
        if (pathByte != 0xFF) {
          // pathByte packs: top 2 bits = hash width mode, low 6 bits = hop count
          packetPathHashWidth = ((pathByte & 0xC0) >> 6) + 1;
          final hopCount = pathByte & 0x3F;
          pathLen = hopCount;
          // If a path is present, read hopCount * width bytes
          if (hasPath && hopCount > 0) {
            final totalPathBytes = hopCount * packetPathHashWidth;
            pathBytes = reader.readBytes(totalPathBytes);
          }
        }
        // After consuming optional path bytes, read the text type byte.
        txtType = reader.readByte();
      } else {
        channelIdx = reader.readByte();
        final pathByte = reader.readUInt8();
        pathLen = pathByte == 0xFF ? null : pathByte & 0x3F;
        txtType = reader.readByte();
      }
      final timestampRaw = reader.readUInt32LE();

      if (txtType != txtTypePlain) {
        return null;
      }

      final text = reader.readCString();

      // Extract sender name and actual message from "name: msg" format
      String senderName = 'Unknown';
      String actualText = text;

      final colonIndex = text.indexOf(':');
      if (colonIndex > 0 && colonIndex < text.length - 1 && colonIndex < 50) {
        final potentialSender = text.substring(0, colonIndex);
        if (!RegExp(r'[:\[\]]').hasMatch(potentialSender)) {
          senderName = potentialSender;
          final offset =
              (colonIndex + 1 < text.length && text[colonIndex + 1] == ' ')
              ? colonIndex + 2
              : colonIndex + 1;
          actualText = text.substring(offset);
        }
      }

      final decodedText = Smaz.tryDecodePrefixed(actualText) ?? actualText;

      return ChannelMessage(
        senderKey: null,
        senderName: senderName,
        text: decodedText,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
        receivedAt: DateTime.now(),
        receivedLive: live,
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        pathLength: pathLen,
        pathHashWidth: packetPathHashWidth,
        pathBytes: pathBytes,
        snrDb: packetSnrDb,
        channelIndex: channelIdx,
      );
    } catch (e) {
      appLogger.error('Error parsing channel message frame: $e');
      // If parsing fails, return null to avoid crashes
      return null;
    }
  }

  static ChannelMessage outgoing(
    String text,
    String senderName,
    int channelIndex, {
    String? originalText,
    String? translatedLanguageCode,
    String? translationModelId,
    String? region,
    ChannelMessage? replyTo,
  }) {
    return ChannelMessage(
      senderKey: null,
      senderName: senderName,
      text: text,
      originalText: originalText,
      translatedLanguageCode: translatedLanguageCode,
      translationModelId: translationModelId,
      replyToMessageId: replyTo?.messageId,
      replyToSenderName: replyTo?.senderName,
      replyToText: replyTo?.text,
      timestamp: DateTime.now(),
      isOutgoing: true,
      status: ChannelMessageStatus.pending,
      pathLength: null,
      pathBytes: Uint8List(0),
      pathVariants: const [],
      channelIndex: channelIndex,
      region: region,
    );
  }

  static Map<String, PathSignal> _withPrimarySignal(
    Uint8List pathBytes,
    double? snrDb,
    int? rssiDbm,
    Map<String, PathSignal>? pathSignals,
  ) {
    if (pathBytes.isEmpty || (snrDb == null && rssiDbm == null)) {
      return pathSignals ?? const {};
    }
    final merged = Map<String, PathSignal>.from(pathSignals ?? const {});
    merged.putIfAbsent(
      pathKey(pathBytes),
      () => PathSignal(snrDb: snrDb, rssiDbm: rssiDbm),
    );
    return merged;
  }

  static List<Uint8List> _mergePathVariants(
    Uint8List pathBytes,
    List<Uint8List>? pathVariants,
  ) {
    final merged = <Uint8List>[];

    void addPath(Uint8List bytes) {
      if (bytes.isEmpty) return;
      for (final existing in merged) {
        if (_pathsEqual(existing, bytes)) return;
      }
      merged.add(bytes);
    }

    if (pathVariants != null) {
      for (final variant in pathVariants) {
        addPath(variant);
      }
    }
    addPath(pathBytes);
    return merged;
  }

  static bool _pathsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static ReplyInfo? parseReplyMention(String text) {
    final regex = RegExp(r'^@\[([^\]]+)\]\s+(.+)$', dotAll: true);
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final actualMessage = match.group(2)!;
    // A second leading mention makes this a multi-mention post, not a reply
    // to one node. Keep the full text so every `@[name]` renders individually.
    if (RegExp(r'^@\[([^\]]+)\]\s').hasMatch(actualMessage)) return null;
    return ReplyInfo(
      mentionedNode: match.group(1)!,
      actualMessage: actualMessage,
    );
  }

  ReactionInfo? parseReaction() {
    final reactionInfo = ReactionHelper.parseReaction(text);
    reactionInfo?.senderName = senderName;
    return reactionInfo;
  }

  String computeReactionHash() {
    return ReactionHelper.computeReactionHash(
      timestamp.millisecondsSinceEpoch ~/ 1000,
      senderName,
      text,
    );
  }

  List<ReactionInfo> reactionList() {
    final String hash = computeReactionHash();
    List<ReactionInfo> reactionList = [];
    for (final entry in reactions.entries) {
      final emoji = entry.key;
      for (final senderName in entry.value) {
        reactionList.add(
          ReactionInfo(
            targetHash: hash, // won't be used for anything
            emoji: emoji,
            senderName: senderName,
            hashType: HashType.ours, // also not used for anything
          ),
        );
      }
    }
    return reactionList;
  }
}

class ReplyInfo {
  final String mentionedNode;
  final String actualMessage;

  ReplyInfo({required this.mentionedNode, required this.actualMessage});
}
