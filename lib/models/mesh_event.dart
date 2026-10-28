import 'dart:typed_data';

/// A live mesh event: something this client just received or sent.
///
/// History loading does not produce these; only traffic that crossed the radio
/// while the app was running (including the radio's offline queue as it is
/// drained on connect) does.
sealed class MeshEvent {
  final DateTime receivedAt;

  MeshEvent(this.receivedAt);
}

class ChannelTextEvent extends MeshEvent {
  final int channelIndex;
  final String channelName;
  final String senderName;
  final String? senderKeyHex;
  final String text;
  final DateTime sentAt;
  final String messageId;
  final bool outgoing;

  ChannelTextEvent({
    required this.channelIndex,
    required this.channelName,
    required this.senderName,
    required this.senderKeyHex,
    required this.text,
    required this.sentAt,
    required this.messageId,
    required this.outgoing,
    required DateTime receivedAt,
  }) : super(receivedAt);
}

class ChannelDataEvent extends MeshEvent {
  final int channelIndex;
  final String channelName;

  /// Application namespace (`data_type`); `0` is rejected by the firmware.
  final int dataType;
  final Uint8List payload;

  /// Signed SNR of the last hop, quarter-dB units.
  final int snrRaw;
  final bool outgoing;

  ChannelDataEvent({
    required this.channelIndex,
    required this.channelName,
    required this.dataType,
    required this.payload,
    required this.snrRaw,
    required this.outgoing,
    required DateTime receivedAt,
  }) : super(receivedAt);

  double get snrDb => snrRaw / 4.0;
}

class DirectTextEvent extends MeshEvent {
  final String pubkeyHex;
  final String? name;
  final String text;
  final DateTime sentAt;
  final String messageId;
  final bool outgoing;

  DirectTextEvent({
    required this.pubkeyHex,
    required this.name,
    required this.text,
    required this.sentAt,
    required this.messageId,
    required this.outgoing,
    required DateTime receivedAt,
  }) : super(receivedAt);
}

class AdvertEvent extends MeshEvent {
  final String pubkeyHex;
  final String? name;
  final int type;
  final DateTime? lastSeen;

  AdvertEvent({
    required this.pubkeyHex,
    required this.name,
    required this.type,
    required this.lastSeen,
    required DateTime receivedAt,
  }) : super(receivedAt);
}
