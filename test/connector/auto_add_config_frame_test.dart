import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  // CMD_SET_AUTOADD_CONFIG: [cmd][flags][autoadd_max_hops?]. Firmware stores
  // the third byte (capped at 64) only when it is present.
  group('buildSetAutoAddConfigFrame', () {
    Iterable<int> frame({int? maxHops}) => buildSetAutoAddConfigFrame(
      autoAddChat: true,
      autoAddRepeater: false,
      autoAddRoomServer: true,
      autoAddSensor: false,
      overwriteOldest: true,
      maxHops: maxHops,
    );

    const flags =
        autoAddChatFlag | autoAddRoomServerFlag | autoAddOverwriteOldestFlag;

    test('omits the hop limit when not given', () {
      expect(frame(), [cmdSetAutoAddConfig, flags]);
    });

    test('appends the hop limit, including 0 (no limit)', () {
      expect(frame(maxHops: 8), [cmdSetAutoAddConfig, flags, 8]);
      expect(frame(maxHops: 0), [cmdSetAutoAddConfig, flags, 0]);
    });

    test('caps the hop limit at 64', () {
      expect(frame(maxHops: 200), [cmdSetAutoAddConfig, flags, 64]);
    });
  });
}
