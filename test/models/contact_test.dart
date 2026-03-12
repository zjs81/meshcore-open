import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';

void main() {
  group('Contact.fromFrame', () {
    test('parses the full 148-byte frame without trailing bytes', () {
      final frame = Uint8List(contactFrameSize)
        ..[0] = respCodeContact
        ..setRange(1, 33, List<int>.generate(32, (index) => index + 1))
        ..[contactTypeOffset] = advTypeChat
        ..[contactFlagsOffset] = contactFlagFavorite
        ..[contactPathLenOffset] = 2
        ..[contactPathOffset] = 0xAA
        ..[contactPathOffset + 1] = 0xBB;

      final nameBytes = 'Alice'.codeUnits;
      frame.setRange(contactNameOffset, contactNameOffset + nameBytes.length, nameBytes);

      frame.buffer
          .asByteData()
          .setUint32(contactTimestampOffset, 1_700_000_000, Endian.little);
      frame.buffer
          .asByteData()
          .setInt32(contactLatOffset, 41_878_113, Endian.little);
      frame.buffer
          .asByteData()
          .setInt32(contactLonOffset, -87_629_799, Endian.little);
      frame.buffer
          .asByteData()
          .setUint32(contactLastModOffset, 1_700_000_123, Endian.little);

      final contact = Contact.fromFrame(frame);

      expect(contact, isNotNull);
      expect(contact!.name, 'Alice');
      expect(contact.type, advTypeChat);
      expect(contact.flags, contactFlagFavorite);
      expect(contact.pathLength, 2);
      expect(contact.path, orderedEquals(<int>[0xAA, 0xBB]));
      expect(contact.latitude, closeTo(41.878113, 0.000001));
      expect(contact.longitude, closeTo(-87.629799, 0.000001));
      expect(
        contact.lastSeen.millisecondsSinceEpoch ~/ 1000,
        1_700_000_123,
      );
    });

    test('keeps direct contacts as pathLength 0', () {
      final frame = Uint8List(contactFrameSize)
        ..[0] = respCodeContact
        ..setRange(1, 33, List<int>.filled(32, 7))
        ..[contactTypeOffset] = advTypeChat
        ..[contactPathLenOffset] = 0;

      final contact = Contact.fromFrame(frame);

      expect(contact, isNotNull);
      expect(contact!.pathLength, 0);
      expect(contact.path, isEmpty);
    });
  });
}
