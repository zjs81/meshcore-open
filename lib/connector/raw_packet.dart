import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Decodes the firmware's encoded path_len byte into actual byte length.
/// Bits 0-5: hash count (0-63), Bits 6-7: hash size code (0=1byte ... 3=4bytes).
int decodePathByteLen(int pathLenRaw) {
  if (pathLenRaw == 0xFF || pathLenRaw == 0) return 0;
  final hashCount = pathLenRaw & 63;
  final hashSize = decodePathHashWidth(pathLenRaw);
  return hashCount * hashSize;
}

int decodePathHashWidth(int pathLenRaw) {
  if (pathLenRaw == 0xFF) return 1;
  return ((pathLenRaw >> 6) & 0x03) + 1;
}

/// Firmware-compatible packet hash: SHA256(payloadType + payload) -> first 8 bytes as hex.
String computePacketHash(int payloadType, Uint8List payload) {
  final input = Uint8List(1 + payload.length);
  input[0] = payloadType;
  input.setRange(1, input.length, payload);
  final digest = crypto.sha256.convert(input).bytes;
  return digest
      .sublist(0, 8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
