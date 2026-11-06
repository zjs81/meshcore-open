import 'dart:ffi';
import 'dart:io';

import 'package:flserial/flserial_bindings_generated.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String libName = 'flserial';

  /// The dynamic library in which the symbols for [FlserialBindings] can be found.
  final DynamicLibrary dylib = () {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$libName.framework/$libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$libName.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open(
        './build/windows/x64/runner/Release/$libName.dll',
      );
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }();

  /// The bindings to the native functions in [_dylib].
  final FlserialBindings bindings = FlserialBindings(dylib);
  //'/home/runner/work/flserial/flserial/build/linux/x64/release/shared/libflserial.so');

  test('FLSerial status should be closed', () {
    bindings.fl_init(10);

    bindings.fl_free();
  });
}
