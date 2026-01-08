import 'dart:convert';
import 'dart:typed_data';

class BufferReader {
  int pointer = 0;
  final Uint8List buffer;

  BufferReader(Uint8List data) : buffer = Uint8List.fromList(data);

  int getRemainingBytesCount() {
    return buffer.length - pointer;
  }

  int readByte() {
    return readBytes(1)[0];
  }

  Uint8List readBytes(int count) {
    final data = buffer.sublist(pointer, pointer + count);
    pointer += count;
    return data;
  }

  Uint8List readRemainingBytes() {
    return readBytes(getRemainingBytesCount());
  }

  String readString() {
    return utf8.decode(readRemainingBytes());
  }

  String readCString(int maxLength) {
    final value = <int>[];
    final bytes = readBytes(maxLength);
    for (final byte in bytes) {
      // if we find a null terminator character, we have reached the end of the cstring
      if (byte == 0) {
        return utf8.decode(Uint8List.fromList(value));
      }
      value.add(byte);
    }
    return utf8.decode(Uint8List.fromList(value));
  }

  int readInt8() {
    final bytes = readBytes(1);
    return ByteData.view(bytes.buffer).getInt8(0);
  }

  int readUInt8() {
    final bytes = readBytes(1);
    return ByteData.view(bytes.buffer).getUint8(0);
  }

  int readUInt16LE() {
    final bytes = readBytes(2);
    return ByteData.view(bytes.buffer).getUint16(0, Endian.little);
  }

  int readUInt16BE() {
    final bytes = readBytes(2);
    return ByteData.view(bytes.buffer).getUint16(0, Endian.big);
  }

  int readUInt32LE() {
    final bytes = readBytes(4);
    return ByteData.view(bytes.buffer).getUint32(0, Endian.little);
  }

  int readUInt32BE() {
    final bytes = readBytes(4);
    return ByteData.view(bytes.buffer).getUint32(0, Endian.big);
  }

  int readInt16LE() {
    final bytes = readBytes(2);
    return ByteData.view(bytes.buffer).getInt16(0, Endian.little);
  }

  int readInt16BE() {
    final bytes = readBytes(2);
    return ByteData.view(bytes.buffer).getInt16(0, Endian.big);
  }

  int readInt32LE() {
    final bytes = readBytes(4);
    return ByteData.view(bytes.buffer).getInt32(0, Endian.little);
  }

  int readInt24BE() {
    // read 24-bit (3 bytes) big endian integer
    var value = (readByte() << 16) | (readByte() << 8) | readByte();

    // convert 24-bit signed integer to 32-bit signed integer
    // 0x800000 is the sign bit for a 24-bit value
    // if it's set, value is negative in 24-bit two's complement
    if ((value & 0x800000) != 0) {
      value -= 0x1000000;
    }

    return value;
  }
}
