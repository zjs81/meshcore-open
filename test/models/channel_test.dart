import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel.dart';

void main() {
  group('Channel community hashtag derivation', () {
    test('normalizes whitespace and leading hash consistently', () {
      final secret = Uint8List.fromList(
        List<int>.generate(16, (index) => index + 1),
      );

      final fromTrimmed = Channel.deriveCommunityHashtagPsk(secret, 'mesh');
      final fromSpacedHash = Channel.deriveCommunityHashtagPsk(
        secret,
        '  #Mesh  ',
      );

      expect(fromSpacedHash, orderedEquals(fromTrimmed));
    });
  });
}
