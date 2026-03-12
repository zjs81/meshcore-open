import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';

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

  group('buildSetChannelFrame', () {
    test('expands a 16-byte local secret to the documented 32-byte device field', () {
      final psk = Uint8List.fromList(List<int>.generate(16, (index) => index + 1));

      final frame = buildSetChannelFrame(2, 'Ops', psk);
      final expectedSecret = crypto.sha512.convert(psk).bytes.sublist(0, 32);

      expect(frame.length, 66);
      expect(frame[0], cmdSetChannel);
      expect(frame[1], 2);
      expect(frame.sublist(34, 66), orderedEquals(expectedSecret));
    });

    test('keeps the public channel secret as all zeros', () {
      final frame = buildSetChannelFrame(0, 'Public', Uint8List(16));

      expect(frame.length, 66);
      expect(frame.sublist(34, 66), everyElement(0));
    });
  });

  group('Channel.fromFrame', () {
    test('parses truncated channel info responses without a secret', () {
      final data = Uint8List(34)
        ..[0] = respCodeChannelInfo
        ..[1] = 4;
      final nameBytes = 'Scout'.codeUnits;
      data.setRange(2, 2 + nameBytes.length, nameBytes);

      final channel = Channel.fromFrame(data);

      expect(channel, isNotNull);
      expect(channel!.index, 4);
      expect(channel.name, 'Scout');
      expect(channel.psk, orderedEquals(Uint8List(16)));
    });

    test('retains the first 16 bytes when a secret is present', () {
      final data = Uint8List(66)
        ..[0] = respCodeChannelInfo
        ..[1] = 1;
      final nameBytes = 'Field'.codeUnits;
      data.setRange(2, 2 + nameBytes.length, nameBytes);
      final secret = List<int>.generate(32, (index) => index + 11);
      data.setRange(34, 66, secret);

      final channel = Channel.fromFrame(data);

      expect(channel, isNotNull);
      expect(channel!.psk, orderedEquals(secret.sublist(0, 16)));
    });
  });

  group('buildTraceReq', () {
    test('rejects trace payloads larger than firmware path capacity', () {
      expect(
        () => buildTraceReq(
          123,
          0,
          0,
          payload: Uint8List(maxPathSize + 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects trace payloads that do not match the flag path stride', () {
      expect(
        () => buildTraceReq(
          123,
          0,
          1,
          payload: Uint8List(3),
        ),
        throwsArgumentError,
      );
    });

    test('accepts trace payloads within firmware limits', () {
      final frame = buildTraceReq(
        123,
        0,
        0,
        payload: Uint8List(maxPathSize),
      );

      expect(frame.length, 1 + 4 + 4 + 1 + maxPathSize);
      expect(frame.first, cmdSendTracePath);
    });

    test('rejects negative trace tags', () {
      expect(
        () => buildTraceReq(-1, 0, 0, payload: Uint8List(1)),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects negative trace auth values', () {
      expect(
        () => buildTraceReq(1, -1, 0, payload: Uint8List(1)),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('outbound recipient validation', () {
    test('rejects contact text messages with a short recipient key', () {
      expect(
        () => buildSendTextMsgFrame(Uint8List(5), 'hello'),
        throwsArgumentError,
      );
    });

    test('rejects cli command messages with a short recipient key', () {
      expect(
        () => buildSendCliCommandFrame(Uint8List(5), 'status'),
        throwsArgumentError,
      );
    });

    test('rejects binary requests with a short recipient key', () {
      expect(
        () => buildSendBinaryReq(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('rejects login requests with a short recipient key', () {
      expect(
        () => buildSendLoginFrame(Uint8List(31), 'secret'),
        throwsArgumentError,
      );
    });

    test('rejects status requests with a short recipient key', () {
      expect(
        () => buildSendStatusRequestFrame(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('rejects contact-by-key lookups with a short public key', () {
      expect(
        () => buildGetContactByKeyFrame(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('rejects contact removal with a short public key', () {
      expect(
        () => buildRemoveContactFrame(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('rejects path reset with a short public key', () {
      expect(
        () => buildResetPathFrame(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('rejects contact export with a short public key', () {
      expect(
        () => buildZeroHopContact(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('rejects contact path updates with a short public key', () {
      expect(
        () => buildUpdateContactPathFrame(Uint8List(31), Uint8List(1), 1),
        throwsArgumentError,
      );
    });
  });

  group('buildUpdateContactPathFrame', () {
    final pubKey = Uint8List.fromList(List<int>.generate(32, (i) => i));

    test('rejects negative path lengths', () {
      expect(
        () => buildUpdateContactPathFrame(pubKey, Uint8List(0), -1),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects path lengths larger than the firmware capacity', () {
      expect(
        () => buildUpdateContactPathFrame(
          pubKey,
          Uint8List(maxPathSize + 1),
          maxPathSize + 1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects truncated custom paths', () {
      expect(
        () => buildUpdateContactPathFrame(pubKey, Uint8List(2), 3),
        throwsArgumentError,
      );
    });
  });

  group('unsigned timestamp validation', () {
    test('rejects negative contact sync since timestamps', () {
      expect(
        () => buildGetContactsFrame(since: -1),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects negative device timestamps', () {
      expect(
        () => buildSetDeviceTimeFrame(-1),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects negative contact text timestamps', () {
      expect(
        () => buildSendTextMsgFrame(
          Uint8List.fromList(List<int>.generate(32, (i) => i)),
          'hello',
          timestampSeconds: -1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects negative cli timestamps', () {
      expect(
        () => buildSendCliCommandFrame(
          Uint8List.fromList(List<int>.generate(32, (i) => i)),
          'status',
          timestampSeconds: -1,
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('buildSetOtherParamsFrame', () {
    test('forces manual-add disabled in the payload', () {
      final frame = buildSetOtherParamsFrame(0x12, 0x34, 0x56);

      expect(
        frame,
        orderedEquals(<int>[
          cmdSetOtherParams,
          0x01,
          0x12,
          0x34,
          0x56,
        ]),
      );
    });
  });

  group('buildSetAdvertLatLonFrame', () {
    test('rejects non-finite latitude values', () {
      expect(
        () => buildSetAdvertLatLonFrame(double.nan, -87.6298),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects latitude values above 90 degrees', () {
      expect(
        () => buildSetAdvertLatLonFrame(90.000001, -87.6298),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects longitude values below -180 degrees', () {
      expect(
        () => buildSetAdvertLatLonFrame(41.8781, -180.000001),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('buildSetAutoAddConfigFrame', () {
    test('packs the documented bit flags', () {
      final frame = buildSetAutoAddConfigFrame(
        autoAddChat: true,
        autoAddRepeater: false,
        autoAddRoomServer: true,
        autoAddSensor: true,
        overwriteOldest: true,
      );

      expect(
        frame,
        orderedEquals(<int>[
          cmdSetAutoAddConfig,
          autoAddOverwriteOldestFlag |
              autoAddChatFlag |
              autoAddRoomServerFlag |
              autoAddSensorFlag,
        ]),
      );
    });
  });

  group('frame size validation', () {
    final pubKey = Uint8List.fromList(List<int>.generate(32, (i) => i));

    test('rejects contact text messages that exceed the max frame size', () {
      expect(
        () => buildSendTextMsgFrame(pubKey, 'x' * maxFrameSize),
        throwsArgumentError,
      );
    });

    test('rejects channel text messages that exceed the max frame size', () {
      expect(
        () => buildSendChannelTextMsgFrame(0, 'x' * maxFrameSize),
        throwsArgumentError,
      );
    });

    test('rejects cli command messages that exceed the max frame size', () {
      expect(
        () => buildSendCliCommandFrame(pubKey, 'x' * maxFrameSize),
        throwsArgumentError,
      );
    });

    test('rejects binary requests that exceed the max frame size', () {
      expect(
        () => buildSendBinaryReq(pubKey, payload: Uint8List(maxFrameSize)),
        throwsArgumentError,
      );
    });

    test('rejects login requests that exceed the max frame size', () {
      expect(
        () => buildSendLoginFrame(pubKey, 'x' * maxFrameSize),
        throwsArgumentError,
      );
    });

    test('rejects custom variable writes that exceed the max frame size', () {
      expect(
        () => buildSetCustomVarFrame('x' * maxFrameSize),
        throwsArgumentError,
      );
    });

    test('rejects local cli commands that exceed the max frame size', () {
      expect(
        () => buildLocalCliCommandFrame('x' * maxFrameSize),
        throwsArgumentError,
      );
    });

    test('accepts the largest valid contact text payload', () {
      final frame = buildSendTextMsgFrame(
        pubKey,
        'x' * maxContactMessageBytes(),
      );

      expect(frame.length, lessThanOrEqualTo(maxFrameSize));
    });

    test('accepts the largest valid local cli command payload', () {
      final frame = buildLocalCliCommandFrame('x' * (maxFrameSize - 2));

      expect(frame.length, maxFrameSize);
    });
  });

  group('buildSetRadioParamsFrame', () {
    test('rejects frequencies below the supported range', () {
      expect(
        () => buildSetRadioParamsFrame(299999, 125000, 7, 5),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects bandwidths above the supported range', () {
      expect(
        () => buildSetRadioParamsFrame(915000, 500001, 7, 5),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects spreading factors below the supported range', () {
      expect(
        () => buildSetRadioParamsFrame(915000, 125000, 4, 5),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects coding rates above the supported range', () {
      expect(
        () => buildSetRadioParamsFrame(915000, 125000, 7, 9),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('attempt clamping', () {
    final pubKey = Uint8List.fromList(List<int>.generate(32, (i) => i));

    test('clamps contact text attempts into the firmware range', () {
      final low = buildSendTextMsgFrame(pubKey, 'hi', attempt: -10);
      final high = buildSendTextMsgFrame(pubKey, 'hi', attempt: 10);

      expect(low[2], 0);
      expect(high[2], 3);
    });

    test('clamps cli command attempts into the firmware range', () {
      final low = buildSendCliCommandFrame(pubKey, 'status', attempt: -10);
      final high = buildSendCliCommandFrame(pubKey, 'status', attempt: 10);

      expect(low[2], 0);
      expect(high[2], 3);
    });
  });
}
