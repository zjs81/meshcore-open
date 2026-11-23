import 'dart:convert';
import 'dart:typed_data';

/// GRP_DATA data type registered to MeshCore Open in the firmware's
/// `docs/number_allocations.md`. Everything inside it is owned by this app;
/// the first payload byte's high nibble says which game (or other app
/// feature) the packet belongs to.
const int meshcoreOpenDataType = 0x0100;

/// Largest GRP_DATA payload a companion can deliver to us: the 172-byte
/// frame minus the 9-byte RESP_CODE_CHANNEL_DATA_RECV header.
const int maxGamePayloadBytes = 163;

/// Size of the encrypted body on air for a payload of [payloadBytes]: the
/// firmware prepends data type (2) and length (1), then pads to the 16-byte
/// AES block.
int encryptedGamePayloadSize(int payloadBytes) =>
    ((payloadBytes + 3 + 15) ~/ 16) * 16;

/// App identifiers carried in the high nibble of a packet's first byte.
abstract final class GameApp {
  static const int chess = 1;
}

/// The 5-byte header every game packet starts with:
/// `[app << 4 | kind][gameId LE16][ply LE16]`.
class GamePacketHeader {
  static const int length = 5;

  final int app;
  final int kind;
  final int gameId;
  final int ply;

  const GamePacketHeader({
    required this.app,
    required this.kind,
    required this.gameId,
    required this.ply,
  });

  void writeTo(BytesBuilder out) {
    out
      ..addByte(((app & 0x0F) << 4) | (kind & 0x0F))
      ..addByte(gameId & 0xFF)
      ..addByte((gameId >> 8) & 0xFF)
      ..addByte(ply & 0xFF)
      ..addByte((ply >> 8) & 0xFF);
  }

  static GamePacketHeader? parse(Uint8List bytes) {
    if (bytes.length < length) return null;
    return GamePacketHeader(
      app: bytes[0] >> 4,
      kind: bytes[0] & 0x0F,
      gameId: bytes[1] | (bytes[2] << 8),
      ply: bytes[3] | (bytes[4] << 8),
    );
  }

  /// The app nibble of [payload], or null when it is too short.
  static int? appOf(Uint8List payload) =>
      payload.isEmpty ? null : payload[0] >> 4;
}

/// Sequential reader over a packet body. Every read returns null (and stays
/// failed) once the data runs out, so decoders can bail out with one check.
class GamePacketReader {
  final Uint8List _bytes;
  int _offset;
  bool _failed = false;

  GamePacketReader(this._bytes, [this._offset = 0]);

  bool get failed => _failed;
  int get remaining => _failed ? 0 : _bytes.length - _offset;
  bool get atEnd => remaining == 0;

  int? u8() {
    if (_failed || _offset + 1 > _bytes.length) return _fail();
    return _bytes[_offset++];
  }

  int? u16() {
    if (_failed || _offset + 2 > _bytes.length) return _fail();
    final v = _bytes[_offset] | (_bytes[_offset + 1] << 8);
    _offset += 2;
    return v;
  }

  int? u32() {
    if (_failed || _offset + 4 > _bytes.length) return _fail();
    final v = ByteData.sublistView(
      _bytes,
      _offset,
      _offset + 4,
    ).getUint32(0, Endian.little);
    _offset += 4;
    return v;
  }

  Uint8List? bytes(int count) {
    if (_failed || count < 0 || _offset + count > _bytes.length) {
      return _fail();
    }
    final v = Uint8List.fromList(_bytes.sublist(_offset, _offset + count));
    _offset += count;
    return v;
  }

  Uint8List? rest() => bytes(remaining);

  /// A length-prefixed UTF-8 string (see [writeShortString]).
  String? shortString() {
    final len = u8();
    if (len == null) return null;
    final raw = bytes(len);
    if (raw == null) return null;
    return utf8.decode(raw, allowMalformed: true);
  }

  Null _fail() {
    _failed = true;
    return null;
  }
}

/// Longest name, in UTF-8 bytes, a game packet carries.
const int maxGameNameBytes = 31;

/// Writes [value] as a 1-byte length plus UTF-8, truncated on a character
/// boundary to [maxGameNameBytes].
void writeShortString(BytesBuilder out, String value) {
  final encoded = truncateUtf8(value, maxGameNameBytes);
  out
    ..addByte(encoded.length)
    ..add(encoded);
}

/// UTF-8 bytes of [value], cut to at most [maxBytes] without splitting a
/// character.
Uint8List truncateUtf8(String value, int maxBytes) {
  final out = BytesBuilder();
  for (final rune in value.runes) {
    final encoded = utf8.encode(String.fromCharCode(rune));
    if (out.length + encoded.length > maxBytes) break;
    out.add(encoded);
  }
  return out.toBytes();
}

void writeU16(BytesBuilder out, int value) {
  out
    ..addByte(value & 0xFF)
    ..addByte((value >> 8) & 0xFF);
}

void writeU32(BytesBuilder out, int value) {
  final b = ByteData(4)..setUint32(0, value & 0xFFFFFFFF, Endian.little);
  out.add(b.buffer.asUint8List());
}
