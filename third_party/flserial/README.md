# flserial
Flutter Serial Port Plugin FFI based on great C library. Useful to communicate with RS232 devices.

Based on great serial library: https://github.com/wjwwood/serial

Supported platforms:
- Linux
- Windows
- Android
- MacOS

Example of usage:

```
    FlSerial serial = FlSerial();
    serial.init();
    serial.openPort("COM3", 9600);
    serial.onSerialData.stream.listen(
      (args) {
        if (args.len > 0) {
          print(args.serial.readList());
        }
      },
    );

    serial.setByteSize8();
    serial.setBitParityNone(); 
    serial.setStopBits1();
    serial.setFlowControlNone();

    String msg = "Hello World!";
    var list = msg.codeUnits;
    serial.write(Uint8List.fromList(list));

    serial.closePort();
    serial.free();


```



MIT License

Copyright (c) 2024 Grzegorz Leśniak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
