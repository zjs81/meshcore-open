import 'dart:typed_data';
import 'buffer_reader.dart';
import 'buffer_writer.dart';

class CayenneLpp {
  static const int lppDigitalInput = 0; // 1 byte
  static const int lppDigitalOutput = 1; // 1 byte
  static const int lppAnalogInput = 2; // 2 bytes, 0.01 signed
  static const int lppAnalogOutput = 3; // 2 bytes, 0.01 signed
  static const int lppGenericSensor = 100; // 4 bytes, unsigned
  static const int lppLuminosity = 101; // 2 bytes, 1 lux unsigned
  static const int lppPresence = 102; // 1 byte, bool
  static const int lppTemperature = 103; // 2 bytes, 0.1°C signed
  static const int lppRelativeHumidity = 104; // 1 byte, 0.5% unsigned
  static const int lppAccelerometer = 113; // 2 bytes per axis, 0.001G
  static const int lppBarometricPressure = 115; // 2 bytes 0.1hPa unsigned
  static const int lppVoltage = 116; // 2 bytes 0.01V unsigned
  static const int lppCurrent = 117; // 2 bytes 0.001A unsigned
  static const int lppFrequency = 118; // 4 bytes 1Hz unsigned
  static const int lppPercentage = 120; // 1 byte 1-100% unsigned
  static const int lppAltitude = 121; // 2 byte 1m signed
  static const int lppConcentration = 125; // 2 bytes, 1 ppm unsigned
  static const int lppPower = 128; // 2 byte, 1W, unsigned
  static const int lppDistance = 130; // 4 byte, 0.001m, unsigned
  static const int lppEnergy = 131; // 4 byte, 0.001kWh, unsigned
  static const int lppDirection = 132; // 2 bytes, 1deg, unsigned
  static const int lppUnixTime = 133; // 4 bytes, unsigned
  static const int lppGyrometer = 134; // 2 bytes per axis, 0.01 °/s
  static const int lppColour = 135; // 1 byte per RGB Color
  static const int lppGps = 136; // 3 byte lon/lat 0.0001 °, 3 bytes alt 0.01 meter
  static const int lppSwitch = 142; // 1 byte, 0/1
  static const int lppPolyline = 240; // 1 byte size, 1 byte delta factor, 3 byte lon/lat 0.0001° * factor, n (size-8) bytes deltas

  final BufferWriter _writer = BufferWriter();

  Uint8List toBytes() {
    return _writer.toBytes();
  }

  void addDigitalInput(int channel, int value) {
    _writer.writeByte(channel);
    _writer.writeByte(lppDigitalInput);
    _writer.writeByte(value);
  }

  void addTemperature(int channel, double value) {
    _writer.writeByte(channel);
    _writer.writeByte(lppTemperature);
    final val = (value * 10).toInt();
    _writer.writeBytes(_int16ToBE(val));
  }

  void addVoltage(int channel, double value) {
    _writer.writeByte(channel);
    _writer.writeByte(lppVoltage);
    final val = (value * 100).toInt();
    _writer.writeBytes(_int16ToBE(val));
  }

  void addGps(int channel, double lat, double lon, double alt) {
    _writer.writeByte(channel);
    _writer.writeByte(lppGps);
    _writer.writeBytes(_int24ToBE((lat * 10000).toInt()));
    _writer.writeBytes(_int24ToBE((lon * 10000).toInt()));
    _writer.writeBytes(_int24ToBE((alt * 100).toInt()));
  }

  Uint8List _int16ToBE(int value) {
    final bytes = Uint8List(2);
    final data = ByteData.view(bytes.buffer);
    data.setInt16(0, value, Endian.big);
    return bytes;
  }

  Uint8List _int24ToBE(int value) {
    final bytes = Uint8List(3);
    bytes[0] = (value >> 16) & 0xFF;
    bytes[1] = (value >> 8) & 0xFF;
    bytes[2] = value & 0xFF;
    return bytes;
  }

  static List<Map<String, dynamic>> parse(Uint8List bytes) {
    final buffer = BufferReader(bytes);
    final telemetry = <Map<String, dynamic>>[];

    while (buffer.getRemainingBytesCount() >= 2) {
      final channel = buffer.readUInt8();
      final type = buffer.readUInt8();

      if (channel == 0 && type == 0) {
        break;
      }

      switch (type) {
        case lppGenericSensor:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt32BE(),
          });
          break;
        case lppLuminosity:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt16BE(),
          });
          break;
        case lppPresence:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt8(),
          });
          break;
        case lppTemperature:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readInt16BE() / 10,
          });
          break;
        case lppRelativeHumidity:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt8() / 2,
          });
          break;
        case lppBarometricPressure:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt16BE() / 10,
          });
          break;
        case lppVoltage:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readInt16BE() / 100,
          });
          break;
        case lppCurrent:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readInt16BE() / 1000,
          });
          break;
        case lppPercentage:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt8(),
          });
          break;
        case lppConcentration:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt16BE(),
          });
          break;
        case lppPower:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': buffer.readUInt16BE(),
          });
          break;
        case lppGps:
          telemetry.add({
            'channel': channel,
            'type': type,
            'value': {
              'latitude': buffer.readInt24BE() / 10000,
              'longitude': buffer.readInt24BE() / 10000,
              'altitude': buffer.readInt24BE() / 100,
            },
          });
          break;
        default:
          return telemetry;
      }
    }

    return telemetry;
  }

  static List<Map<String, dynamic>> parseByChannel(Uint8List bytes) {
    final buffer = BufferReader(bytes);
    final Map<int, Map<String, dynamic>> channels = {};

    while (buffer.getRemainingBytesCount() >= 2) {
      final channel = buffer.readUInt8();
      final type = buffer.readUInt8();

      // Optional: stop on padding (00 00)
      if (channel == 0 && type == 0) {
        break;
      }

      final channelData = channels.putIfAbsent(channel, () => {
        'channel': channel,
        'values': <String, dynamic>{},
      });

      switch (type) {
        case lppGenericSensor:
          channelData['values']['generic'] = buffer.readUInt32BE();
          break;
        case lppLuminosity:
          channelData['values']['luminosity'] = buffer.readUInt16BE();
          break;
        case lppPresence:
          channelData['values']['presence'] = buffer.readUInt8() != 0;
          break;
        case lppTemperature:
          channelData['values']['temperature'] = buffer.readInt16BE() / 10.0;
          break;
        case lppRelativeHumidity:
          channelData['values']['humidity'] = buffer.readUInt8() / 2.0;
          break;
        case lppBarometricPressure:
          channelData['values']['pressure'] = buffer.readUInt16BE() / 10.0;
          break;
        case lppVoltage:
          channelData['values']['voltage'] = buffer.readInt16BE() / 100.0;
          break;
        case lppCurrent:
          channelData['values']['current'] = buffer.readInt16BE() / 1000.0;
          break;
        case lppPercentage:
          channelData['values']['percentage'] = buffer.readUInt8();
          break;
        case lppConcentration:
          channelData['values']['concentration'] = buffer.readUInt16BE();
          break;
        case lppPower:
          channelData['values']['power'] = buffer.readUInt16BE();
          break;
        case lppGps:
          channelData['values']['gps'] = {
            'latitude': buffer.readInt24BE() / 10000.0,
            'longitude': buffer.readInt24BE() / 10000.0,
            'altitude': buffer.readInt24BE() / 100.0,
          };
          break;
        // Add more types as needed...
        default:
          // Unknown type: skip or handle error?
          continue;
      }
    }

  final List<Map<String, dynamic>> channelsOut = channels.values.toList();
  channelsOut.sort((a, b) => a['channel'].compareTo(b['channel']));
  return channelsOut;
  }
}
