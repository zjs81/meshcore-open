import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('expectedResponseCodesForCommand', () {
    test('maps startup commands to documented responses', () {
      expect(
        expectedResponseCodesForCommand(cmdDeviceQuery),
        equals(<int>{respCodeDeviceInfo}),
      );
      expect(
        expectedResponseCodesForCommand(cmdAppStart),
        equals(<int>{respCodeSelfInfo}),
      );
      expect(
        expectedResponseCodesForCommand(cmdGetCustomVar),
        equals(<int>{respCodeCustomVars}),
      );
      expect(
        expectedResponseCodesForCommand(cmdGetBattAndStorage),
        equals(<int>{respCodeBattAndStorage}),
      );
      expect(
        expectedResponseCodesForCommand(cmdGetAutoAddConfig),
        equals(<int>{respCodeAutoAddConfig}),
      );
    });

    test('returns empty set for commands without an expected response map', () {
      expect(expectedResponseCodesForCommand(cmdSendTxtMsg), isEmpty);
    });
  });

  group('frameMatchesCommandResponse', () {
    test('matches documented startup responses', () {
      expect(
        frameMatchesCommandResponse(
          cmdDeviceQuery,
          Uint8List.fromList(<int>[respCodeDeviceInfo, 0x01, 0x08, 0x04]),
        ),
        isTrue,
      );
      expect(
        frameMatchesCommandResponse(
          cmdAppStart,
          Uint8List.fromList(<int>[respCodeSelfInfo, 0x00]),
        ),
        isTrue,
      );
    });

    test('rejects non-matching responses', () {
      expect(
        frameMatchesCommandResponse(
          cmdAppStart,
          Uint8List.fromList(<int>[respCodeDeviceInfo, 0x00]),
        ),
        isFalse,
      );
    });
  });
}
