import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flserial/flserial_exception.dart';

import 'flserial_bindings_generated.dart';

const String _libName = 'flserial';
const int _serialIOBuffLen = 1024 * 8;

/// The dynamic library in which the symbols for [FlserialBindings] can be found.
final DynamicLibrary dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final FlserialBindings bindings = FlserialBindings(dylib);

/// Native pointer to string conversion
String nativeInt8ToString(Pointer<Int8> pointer, {bool allowMalformed = true}) {
  var ptrName = pointer.cast<Utf8>();
  final ptrNameCodeUnits = pointer.cast<Uint8>();
  var list = ptrNameCodeUnits.asTypedList(ptrName.length);
  return utf8.decode(list, allowMalformed: allowMalformed);
}

/// String conversion to native pointer, memory should be free outside function
Pointer<Char> stringToNativeInt8(String str, {Allocator allocator = calloc}) {
  final units = utf8.encode(str);
  final result = allocator<Uint8>(units.length + 1);
  final nativeString = result.asTypedList(units.length + 1);
  nativeString.setAll(0, units);
  nativeString[units.length] = 0;

  return result.cast<Char>();
}

/// List conversion to native pointer, memory should be free outside function
Pointer<Char> int8ListToPointerInt8(
  Uint8List units,
  Pointer<Uint8> pointer, {
  Allocator allocator = calloc,
}) {
  final nativeString = pointer.asTypedList(units.length + 1); //blobBytes
  nativeString.setAll(0, units);
  nativeString[units.length] = 0;
  return pointer.cast<Char>();
}

Pointer<Double> listToPointerDouble(List<double> sample) {
  final Pointer<Double> pointer = calloc.allocate<Double>(
    sample.length,
    alignment: 8,
  );
  final nativeSamples = pointer.asTypedList(sample.length);
  nativeSamples.setAll(0, sample);
  return pointer.cast<Double>();
}

/// Native pointer conversion to list
Int8List nativeInt8ToInt8List(Pointer<Int8> pointer) {
  var ptrName = pointer.cast<Utf8>();
  final ptrNameCodeUnits = pointer.cast<Int8>();
  var list = ptrNameCodeUnits.asTypedList(ptrName.length);
  return list;
}

/// Open serial port status
enum FlOpenStatus { open, closed, error }

/// Class for incoming data handling
class FlSerialEventArgs {
  FlSerialEventArgs(this.serial, this.len, this.cts, this.dsr);
  final FlSerial serial;
  final int len;
  final bool cts, dsr;
}

/// Main serial wrapper class over ffi
class FlSerial {
  int flh = -1;
  bool prevCTS = false;
  bool prevDSR = false;
  var onSerialData = StreamController<FlSerialEventArgs>();
  Pointer<Char> serialReadBuff = Pointer.fromAddress(0);
  Pointer<Uint8> serialWriteBuff = Pointer.fromAddress(0);

  /// Init should be called at program start, after FlSerial creation
  /// Function is used to make array of internal port structs for 16 parallel processing ports
  int init() {
    return bindings.fl_init(16);
  }

  /// Setting callback to native code. Used for incoming data signal
  void setCallback(int flh, {required DartflcallbackFunction callback}) {
    final nativeCallable = NativeCallable<flcallbackFunction>.listener(
      callback,
    );
    bindings.fl_set_callback(flh, nativeCallable.nativeFunction);
  }

  /// Listing serial ports. Platform depend
  static List<String> listPorts() {
    List<String> list = List<String>.empty(growable: true);

    Allocator allocator = calloc;
    var result = allocator<Char>(1024);

    for (int i = 0; i < 255; i++) {
      int len = bindings.fl_ports(i, 1024, result);
      if (len > 0) {
        String resultStr = result.cast<Utf8>().toDartString(length: len);
        list.add(resultStr);
      } else {
        break;
      }
    }

    allocator.free(result);
    return list;
  }

  /// Internal function for serial port handler checking
  int _checkFLH(int handler) {
    if (handler >= 0 && handler < MAX_PORT_COUNT) {
      return FlError.FL_ERROR_OK;
    }
    throw FlSerialException(FlError.FL_ERROR_HANDLER, msg: "$handler");
  }

  /// Function for openning serial port
  FlOpenStatus openPort(String portname, int baudrate) {
    prevCTS = false;
    prevDSR = false;
    Pointer<Char> ptr = stringToNativeInt8(portname);
    flh = bindings.fl_open(flh, ptr, baudrate);
    calloc.free(ptr);
    int error = bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_LAST_ERROR, -1);
    int flerror = FlError.FL_ERROR_UNKNOW;
    if (error > 0) {
      /// error mapping
      String msg = "Port open error: $portname";
      switch (error) {
        case 1:
        case 3:
          flerror = FlError.FL_ERROR_PORT_NOT_EXIST;
          msg += " port not exist";
          break;
        case 2:
          flerror = FlError.FL_ERROR_PORT_ALLREADY_OPEN;
          msg += " port allready open";
          break;
      }

      bindings.fl_close(flh);
      flh = -1;
      throw FlSerialException(flerror, msg: msg);
    }

    onSerialData = StreamController<FlSerialEventArgs>();

    Allocator allocator = calloc;
    serialReadBuff = allocator<Char>(_serialIOBuffLen);
    serialWriteBuff = allocator<Uint8>(_serialIOBuffLen);

    setCallback(
      flh,
      callback: (cflh, len) async {
        if (len > 0) {
          onSerialData.add(FlSerialEventArgs(this, len, prevCTS, prevDSR));
        }
      },
    );

    return isOpen();
  }

  /// Function check is serial port opened
  FlOpenStatus isOpen() {
    if (flh < 0) {
      return FlOpenStatus.closed;
    }

    int error = bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_LAST_ERROR, -1);
    if (error > 0) {
      return FlOpenStatus.error;
    }
    int nres = bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_IS_PORT_OPEN, -1);
    if (nres == 0) {
      return FlOpenStatus.closed;
    }
    return FlOpenStatus.open;
  }

  /// Get last error message. Return empty string if no error
  String getLastError() {
    _checkFLH(flh);

    int res = bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_LAST_ERROR, -1);
    String strres = "";

    switch (res) {
      case FlError.FL_ERROR_OK:
        strres = "0: None";
        break;
      case FlError.FL_ERROR_PORT_ALLREADY_OPEN:
        strres = "$res: Port allready open";
        break;
      case FlError.FL_ERROR_PORT_NOT_EXIST:
        strres = "$res: Port not exist";
        break;
      default:
        strres = "-1: Unknow error";
        break;
    }
    return strres;
  }

  /*
  Future<int> _readLineStatus() async {

    _checkFLH(flh);

    bool currCTS = getCTS();
    bool currDSR = getDSR();
    if(currCTS != prevCTS || prevDSR != currDSR)
    {
      prevCTS = currCTS;
      prevDSR = currDSR;

      onSerialData.broadcast(FlSerialEventArgs(
              readBuff.length, Uint8List(0), currCTS, currDSR));
    }
    return 0;
  }*/

  /// Internal function to read serial data from lower layer with desired len. If no data is present, empty list is returned
  Uint8List _readList(int len) {
    _checkFLH(flh);

    if (len > _serialIOBuffLen) {
      len = _serialIOBuffLen;
    }

    int intres = bindings.fl_read(flh, len, serialReadBuff);

    if (intres <= 0) {
      return Uint8List(0);
    }

    final ptrNameCodeUnits = serialReadBuff.cast<Uint8>();
    var list = ptrNameCodeUnits.asTypedList(intres);

    return list;
  }

  /// Read full read bufer from serial port
  Uint8List readList() {
    _checkFLH(flh);

    return readListLen(1024 * 8);
  }

  /// Read desired len from serial port buffer
  Uint8List readListLen(int len) {
    _checkFLH(flh);

    return _readList(len);
  }

  /// Read single byte
  int read() {
    _checkFLH(flh);

    Uint8List data = _readList(1);

    if (data.isNotEmpty) {
      return data.first;
    }
    return -1;
  }

  /// Write list data to serial port
  int write(Uint8List data) {
    _checkFLH(flh);

    Pointer<Char> ptr = int8ListToPointerInt8(data, serialWriteBuff);
    int res = bindings.fl_write(flh, data.length, ptr);

    return res;
  }

  /// Close serial port and free resources
  int closePort() {
    _checkFLH(flh);
    bindings.fl_close(flh);
    onSerialData.close();
    Allocator allocator = calloc;
    if (serialReadBuff.value != 0) {
      allocator.free(serialReadBuff);
    }
    if (serialWriteBuff.value != 0) {
      allocator.free(serialWriteBuff);
    }
    flh = -1;
    return flh;
  }

  /// Uniwersal function to control serial port
  int ctrl(int cmd, int value) {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, cmd, value);
  }

  /// Function set RTS line in serial port
  int setRTS(bool value) {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_RTS, value ? 1 : 0);
  }

  /// Function set CTS line in serial port
  bool getCTS() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_GET_CTS, 0) > 0 ? true : false;
  }

  /// Get status of DTR line
  int setDTR(bool value) {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_DTR, value ? 1 : 0);
  }

  /// Get status of DSR line
  bool getDSR() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_GET_DSR, 0) > 0 ? true : false;
  }

  /// Set byte size to 5 bits
  int setByteSize5() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_BYTESIZE_5, 0);
  }

  /// Set byte size to 6 bits
  int setByteSize6() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_BYTESIZE_6, 0);
  }

  /// Set byte size to 7 bits
  int setByteSize7() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_BYTESIZE_7, 0);
  }

  /// Set byte size to 8 bits
  int setByteSize8() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_BYTESIZE_8, 0);
  }

  /// Set bit parity to none
  int setBitParityNone() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_PARITY_NONE, 0);
  }

  /// Set bit parity to odd
  int setBitParityOdd() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_PARITY_ODD, 0);
  }

  // Set bit parity to even
  int setBitParityEven() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_PARITY_EVEN, 0);
  }

  // Set bit parity to mark
  int setBitParityMark() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_PARITY_MARK, 0);
  }

  // Set bit parity to space
  int setBitParitySpace() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_PARITY_SPACE, 0);
  }

  /// Set stop bits to one
  int setStopBits1() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_STOPBITS_ONE, 0);
  }

  /// Set stop bits to one and half
  int setStopBits1_5() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_STOPBITS_ONE_POINT_FIVE, 0);
  }

  /// Set stop bits to two
  int setStopBits2() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_STOPBITS_TWO, 0);
  }

  /// Disable flow control
  int setFlowControlNone() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_FLOWCONTROL_NONE, 0);
  }

  /// Set hardware flow control
  int setFlowControlHardware() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_FLOWCONTROL_HARDWARE, 0);
  }

  /// Set xon/xoff flow control (software)
  int setFlowControlSoftware() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_SET_FLOWCONTROL_SOFTWARE, 0);
  }

  /// Waiting for status line change
  int setWaitStatusChange() {
    _checkFLH(flh);
    return bindings.fl_ctrl(flh, FlCtrl.FL_CTRL_GET_STATUS_CHANGE, 0);
  }

  /// Free resources. Serial port should not be used after calling this function
  int free() {
    return bindings.fl_free();
  }
}
