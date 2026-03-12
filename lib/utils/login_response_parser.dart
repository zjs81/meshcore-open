import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';

bool? parseTerminalLoginResponse(
  Uint8List frame, {
  required Uint8List targetPrefix,
}) {
  if (frame.isEmpty) return null;
  if (frame[0] == respCodeErr) {
    return null;
  }
  return parseLoginOutcome(frame, targetPrefix: targetPrefix);
}
