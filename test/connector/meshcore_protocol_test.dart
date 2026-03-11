import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('buildAppStartFrame', () {
    test('uses the documented companion protocol layout by default', () {
      final frame = buildAppStartFrame();

      expect(
        frame,
        orderedEquals(<int>[
          cmdAppStart,
          appProtocolVersion,
          0x6d,
          0x63,
          0x63,
          0x6c,
          0x69,
          0x00,
          0x00,
          0x00,
          0x00,
        ]),
      );
    });

    test('null pads or truncates the app identifier to 9 bytes', () {
      final frame = buildAppStartFrame(appName: 'meshcore-open-client');

      expect(frame.length, 11);
      expect(
        frame.sublist(2),
        orderedEquals(<int>[
          0x6d,
          0x65,
          0x73,
          0x68,
          0x63,
          0x6f,
          0x72,
          0x65,
          0x00,
        ]),
      );
    });
  });

  group('buildLocalCliCommandFrame', () {
    test('encodes local cli commands with the documented raw format', () {
      final frame = buildLocalCliCommandFrame('reboot');

      expect(
        frame,
        orderedEquals(<int>[
          cmdAppStart,
          0x72,
          0x65,
          0x62,
          0x6f,
          0x6f,
          0x74,
          0x00,
        ]),
      );
    });

    test('preserves spaces and null-terminates the command', () {
      final frame = buildLocalCliCommandFrame('set privacy on');

      expect(frame.first, cmdAppStart);
      expect(frame.last, 0);
      expect(
        String.fromCharCodes(frame.sublist(1, frame.length - 1)),
        'set privacy on',
      );
    });
  });
}
