import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/channel_resend_coverage.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/channel_message.dart';

ChannelMessage _echoed(
  List<List<int>> paths, {
  int width = 1,
  int? pathLength,
}) {
  final variants = [for (final p in paths) Uint8List.fromList(p)];
  return ChannelMessage(
    senderName: 'me',
    text: 'hello',
    timestamp: DateTime(2026, 10, 11),
    isOutgoing: true,
    pathHashWidth: width,
    pathLength:
        pathLength ??
        variants.fold<int>(
          0,
          (m, p) => p.length ~/ width > m ? p.length ~/ width : m,
        ),
    pathBytes: variants.isEmpty ? null : variants.first,
    pathVariants: variants,
  );
}

void main() {
  group('channelResendSatisfied', () {
    test('two distinct first-hop repeaters satisfy N=2 only when on', () {
      final message = _echoed([
        [0xAA],
        [0xBB],
      ]);
      expect(
        channelResendSatisfied(
          message,
          minHops: 2,
          countDistinctRepeaters: false,
        ),
        isFalse,
      );
      expect(
        channelResendSatisfied(
          message,
          minHops: 2,
          countDistinctRepeaters: true,
        ),
        isTrue,
      );
    });

    test('the same repeater heard twice does not count twice', () {
      final message = _echoed([
        [0xAA],
        [0xAA],
      ]);
      expect(distinctFirstHopRepeaters(message), {'aa'});
      expect(
        channelResendSatisfied(
          message,
          minHops: 2,
          countDistinctRepeaters: true,
        ),
        isFalse,
      );
    });

    test('consecutive hops still satisfy with the toggle off', () {
      final message = _echoed([
        [0xAA, 0xCC],
      ]);
      expect(
        channelResendSatisfied(
          message,
          minHops: 2,
          countDistinctRepeaters: false,
        ),
        isTrue,
      );
    });

    test('first hop uses the path hash width', () {
      // Same first byte, different 2-byte hashes: two distinct repeaters.
      final message = _echoed([
        [0xAA, 0x01],
        [0xAA, 0x02],
      ], width: 2);
      expect(distinctFirstHopRepeaters(message), {'aa01', 'aa02'});
    });

    test('our own key prefix and zero-hop echoes are ignored', () {
      final self = Uint8List.fromList(List.filled(32, 0x11));
      final message = _echoed([
        [0x11],
        [0xAA],
        [],
      ], pathLength: 1);
      expect(distinctFirstHopRepeaters(message, selfPublicKey: self), {'aa'});
      expect(
        channelResendSatisfied(
          message,
          minHops: 2,
          countDistinctRepeaters: true,
          selfPublicKey: self,
        ),
        isFalse,
      );
    });

    test('an unechoed message is not satisfied', () {
      final message = _echoed([]);
      expect(
        channelResendSatisfied(
          message,
          minHops: 1,
          countDistinctRepeaters: true,
        ),
        isFalse,
      );
    });
  });

  group('channelMinHopsCountRepeaters setting', () {
    test('defaults off, including for old saved settings', () {
      expect(AppSettings().channelMinHopsCountRepeaters, isFalse);
      expect(AppSettings.fromJson({}).channelMinHopsCountRepeaters, isFalse);
    });

    test('round-trips through JSON and copyWith', () {
      final on = AppSettings().copyWith(channelMinHopsCountRepeaters: true);
      expect(on.channelMinHopsCountRepeaters, isTrue);
      expect(
        AppSettings.fromJson(on.toJson()).channelMinHopsCountRepeaters,
        isTrue,
      );
    });
  });
}
