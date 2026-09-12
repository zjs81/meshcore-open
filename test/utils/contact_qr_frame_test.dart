import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/utils/contact_qr.dart';
import 'package:meshcore_open/utils/contact_qr_frame.dart';

void main() {
  final publicKey = Uint8List.fromList(List<int>.filled(32, 0xAB));

  Contact contactWith({required String name, required int flags}) {
    return Contact(
      publicKey: publicKey,
      name: name,
      type: advTypeChat,
      flags: flags,
      pathLength: 2,
      path: Uint8List.fromList([1, 2]),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  group('buildContactQrFrame advert packet', () {
    test('replays the advert with CMD_IMPORT_CONTACT', () {
      final advert = Uint8List.fromList(List<int>.filled(98, 7));
      final frame = buildContactQrFrame(
        ScannedContact(advertPacket: advert),
        existing: contactWith(name: 'Old', flags: 0x03),
      );

      expect(frame[0], cmdImportContact);
      expect(frame.sublist(1), advert);
    });
  });

  group('buildContactQrFrame contact card', () {
    test('writes an add/update frame with the unknown-path sentinel', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: 'Alice', type: 2),
      );

      expect(frame[0], cmdAddUpdateContact);
      expect(frame.sublist(1, 33), publicKey);
      expect(frame[33], 2);
      expect(frame[34], 0);
      expect(frame[35], 0xFF, reason: 'path is unknown, not zero-hop');

      final nameStart = 36 + maxPathSize;
      final name = String.fromCharCodes(
        frame
            .sublist(nameStart, nameStart + maxNameSize)
            .takeWhile((b) => b != 0),
      );
      expect(name, 'Alice');
    });

    test('preserves the flags of an existing contact', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: 'Alice'),
        existing: contactWith(name: 'Alice', flags: 0x05),
      );

      expect(frame[34], 0x05);
    });

    test('falls back to the existing name when the card has none', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey),
        existing: contactWith(name: 'Existing', flags: 0),
      );

      final nameStart = 36 + maxPathSize;
      final name = String.fromCharCodes(
        frame
            .sublist(nameStart, nameStart + maxNameSize)
            .takeWhile((b) => b != 0),
      );
      expect(name, 'Existing');
    });

    test('drops whole characters when the name exceeds 31 bytes', () {
      // 16 three-byte characters = 48 encoded bytes; only 10 fit in 31.
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: '☂' * 16),
      );

      final nameStart = 36 + maxPathSize;
      final bytes = frame
          .sublist(nameStart, nameStart + maxNameSize)
          .takeWhile((b) => b != 0)
          .toList();
      expect(bytes.length, 30);
      expect(utf8.decode(bytes), '☂' * 10);
    });
  });

  group('buildContactQrFrame route preservation', () {
    Contact contactWithPath(int pathLength, List<int> path) {
      return Contact(
        publicKey: publicKey,
        name: 'Alice',
        type: advTypeChat,
        pathLength: pathLength,
        path: Uint8List.fromList(path),
        lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    test('keeps the route of a contact the device already knows', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: 'Alice'),
        existing: contactWithPath(2, [0x11, 0x22]),
      );

      expect(frame[35], 0x02, reason: 'two hops, 1-byte hash mode');
      expect(frame.sublist(36, 38), [0x11, 0x22]);
    });

    test('encodes the hash mode in bits 6-7 for wider path hashes', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: 'Alice'),
        existing: contactWithPath(2, [0x11, 0x22, 0x33, 0x44]),
        pathHashByteWidth: 2,
      );

      expect(frame[35], 0x42);
      expect(frame.sublist(36, 40), [0x11, 0x22, 0x33, 0x44]);
    });

    test('uses the unknown sentinel for a flood-only contact', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: 'Alice'),
        existing: contactWithPath(-1, const []),
      );

      expect(frame[35], 0xFF);
      expect(frame.sublist(36, 36 + maxPathSize).every((b) => b == 0), isTrue);
    });

    test('uses the unknown sentinel when the path does not fit the mode', () {
      final frame = buildContactQrFrame(
        ScannedContact(publicKey: publicKey, name: 'Alice'),
        existing: contactWithPath(2, [0x11, 0x22]),
        pathHashByteWidth: 2,
      );

      expect(frame[35], 0xFF);
    });
  });
}
