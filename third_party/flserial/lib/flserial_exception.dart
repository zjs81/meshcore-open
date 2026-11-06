/// Exception class for serial port
class FlSerialException implements Exception {
  FlSerialException(this.error, {required this.msg});
  final int error;
  final String msg;
}
