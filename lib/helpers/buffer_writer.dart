import 'dart:convert';
import 'dart:typed_data';

class BufferWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List toBytes() {
    return _builder.toBytes();
  }

  void writeBytes(Uint8List bytes) {
    _builder.add(bytes);
  }

  void writeByte(int byte) {
    _builder.addByte(byte);
  }

  void writeUInt16LE(int num) {
    final bytes = Uint8List(2);
    final data = ByteData.view(bytes.buffer);
    data.setUint16(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeUInt32LE(int num) {
    final bytes = Uint8List(4);
    final data = ByteData.view(bytes.buffer);
    data.setUint32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeInt32LE(int num) {
    final bytes = Uint8List(4);
    final data = ByteData.view(bytes.buffer);
    data.setInt32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeString(String string) {
    writeBytes(Uint8List.fromList(utf8.encode(string)));
  }

  void writeCString(String string, int maxLength) {
    final bytes = Uint8List(maxLength);
    final encodedString = utf8.encode(string);

    for (var i = 0; i < maxLength && i < encodedString.length; i++) {
      bytes[i] = encodedString[i];
    }

    // ensure the last byte is always a null terminator
    bytes[maxLength - 1] = 0;

    writeBytes(bytes);
  }
}
