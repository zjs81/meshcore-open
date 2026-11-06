import 'dart:typed_data';

import '../models/channel_message.dart';

/// Distinct first-hop repeaters heard echoing [message], across every resend
/// (echoes of all attempts merge into the same message's path variants).
///
/// Each first hop is the leading `pathHashWidth` bytes of an echo's path.
/// Zero-hop echoes and a first hop matching our own key prefix are ignored.
Set<String> distinctFirstHopRepeaters(
  ChannelMessage message, {
  Uint8List? selfPublicKey,
}) {
  final width = (message.pathHashWidth ?? 1).clamp(1, 3).toInt();
  String? selfPrefix;
  if (selfPublicKey != null && selfPublicKey.length >= width) {
    selfPrefix = _hex(selfPublicKey, width);
  }
  final hops = <String>{};
  for (final path in [message.pathBytes, ...message.pathVariants]) {
    if (path.length < width) continue;
    final hop = _hex(path, width);
    if (hop != selfPrefix) hops.add(hop);
  }
  return hops;
}

/// Whether a channel resend has heard [message] travel far enough:
/// an echo through at least [minHops] repeaters, or, when
/// [countDistinctRepeaters] is on, echoes from at least [minHops] different
/// first-hop repeaters.
bool channelResendSatisfied(
  ChannelMessage message, {
  required int minHops,
  required bool countDistinctRepeaters,
  Uint8List? selfPublicKey,
}) {
  if ((message.pathLength ?? 0) >= minHops) return true;
  if (!countDistinctRepeaters) return false;
  return distinctFirstHopRepeaters(
        message,
        selfPublicKey: selfPublicKey,
      ).length >=
      minHops;
}

String _hex(Uint8List bytes, int length) {
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
