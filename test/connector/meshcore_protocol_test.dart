import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';

void main() {
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
}
