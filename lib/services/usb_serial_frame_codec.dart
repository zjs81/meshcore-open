import 'dart:typed_data';

const int usbSerialTxFrameStart = 0x3c;
const int usbSerialRxFrameStart = 0x3e;
const int usbSerialHeaderLength = 3;
// Outgoing (app → radio) payload cap; matches the app's TX frame budget.
const int usbSerialMaxPayloadLength = 172;
// Incoming (radio → app) payload cap; firmware MAX_FRAME_SIZE is 176 (it
// grew by 4 bytes for region transport codes).
const int usbSerialMaxRxPayloadLength = 176;

Uint8List wrapUsbSerialTxFrame(Uint8List payload) {
  if (payload.length > usbSerialMaxPayloadLength) {
    throw ArgumentError.value(
      payload.length,
      'payload.length',
      'USB serial payload exceeds $usbSerialMaxPayloadLength bytes',
    );
  }
  final packet = Uint8List(usbSerialHeaderLength + payload.length);
  packet[0] = usbSerialTxFrameStart;
  packet[1] = payload.length & 0xff;
  packet[2] = (payload.length >> 8) & 0xff;
  packet.setRange(usbSerialHeaderLength, packet.length, payload);
  return packet;
}

class UsbSerialDecodedPacket {
  const UsbSerialDecodedPacket({
    required this.frameStart,
    required this.payload,
  });

  final int frameStart;
  final Uint8List payload;

  bool get isRxFrame => frameStart == usbSerialRxFrameStart;
}

class UsbSerialFrameDecoder {
  final List<int> _rxBuffer = <int>[];
  int _startIndex = 0;

  void reset() {
    _rxBuffer.clear();
    _startIndex = 0;
  }

  List<UsbSerialDecodedPacket> ingest(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const <UsbSerialDecodedPacket>[];
    }

    _rxBuffer.addAll(bytes);
    final packets = <UsbSerialDecodedPacket>[];

    while (true) {
      if (_startIndex >= _rxBuffer.length) {
        _rxBuffer.clear();
        _startIndex = 0;
        return packets;
      }

      if (_rxBuffer[_startIndex] != usbSerialRxFrameStart &&
          _rxBuffer[_startIndex] != usbSerialTxFrameStart) {
        _startIndex++;
        _compactBufferIfNeeded();
        continue;
      }

      final availableLength = _rxBuffer.length - _startIndex;
      if (availableLength < usbSerialHeaderLength) {
        _compactBufferIfNeeded(force: true);
        return packets;
      }

      final payloadLength =
          _rxBuffer[_startIndex + 1] | (_rxBuffer[_startIndex + 2] << 8);
      if (payloadLength > usbSerialMaxRxPayloadLength) {
        _startIndex++;
        _compactBufferIfNeeded();
        continue;
      }
      final packetLength = usbSerialHeaderLength + payloadLength;
      if (availableLength < packetLength) {
        _compactBufferIfNeeded(force: true);
        return packets;
      }

      final frameStart = _rxBuffer[_startIndex];
      final payload = Uint8List.fromList(
        _rxBuffer.sublist(
          _startIndex + usbSerialHeaderLength,
          _startIndex + packetLength,
        ),
      );
      _startIndex += packetLength;
      _compactBufferIfNeeded();
      packets.add(
        UsbSerialDecodedPacket(frameStart: frameStart, payload: payload),
      );
    }
  }

  void _compactBufferIfNeeded({bool force = false}) {
    if (_startIndex == 0) {
      return;
    }
    if (!force && _startIndex < 1024 && _startIndex < (_rxBuffer.length ~/ 2)) {
      return;
    }
    _rxBuffer.removeRange(0, _startIndex);
    _startIndex = 0;
  }
}
