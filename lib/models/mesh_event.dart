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

  /// Flood hops the packet took; 0 when heard from the sender's radio. Null
  /// when it came by a direct path, and for our own sends.
  final int? hops;
  final bool outgoing;

  /// `flood`, `direct`, `tflood` or `tdirect` (the `t` forms carry a
  /// flood-scope transport code). Null when unknown and for our own sends.
  final String? routeType;

  /// Repeater hashes in the order the packet travelled, as the radio heard it
  /// (empty for a direct packet at its last hop). Null when the raw packet
  /// was not heard, e.g. for frames drained from the radio's offline queue.
  final Uint8List? path;

  /// Bytes per hash in [path] (1-3), null when unknown.
  final int? pathHashSize;

  /// RSSI of the received packet in dBm, null when unknown.
  final int? rssiDbm;

  /// The first transport code (`code[0]`, little-endian) of a `tflood` or
  /// `tdirect` packet: the flood scope it was sent in. Null otherwise.
  final int? transportCode;

  /// The flood-scope name whose key gives [transportCode], when the app
  /// knows exactly one (without a leading `#`).
  final String? scope;

  /// The radio held this frame in its offline queue while no app was reading
  /// it (drained after a connect, and not heard live), so [receivedAt] is
  /// the time the app fetched it, not the time the radio heard it.
  final bool queued;

  ChannelDataEvent({
    required this.channelIndex,
    required this.channelName,
    required this.dataType,
    required this.payload,
    required this.snrRaw,
    this.hops,
    required this.outgoing,
    required DateTime receivedAt,
    this.routeType,
    this.path,
    this.pathHashSize,
    this.rssiDbm,
    this.transportCode,
    this.scope,
    this.queued = false,
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
