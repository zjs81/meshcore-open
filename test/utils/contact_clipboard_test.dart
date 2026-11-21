import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/contact_clipboard.dart';
import 'package:meshcore_open/utils/contact_qr.dart';

void main() {
  final validLowerHex = List.generate(
    32,
    (i) => i.toRadixString(16).padLeft(2, '0'),
  ).join();
  final validUpperHex = validLowerHex.toUpperCase();

  group('normalizeContactPublicKeyHex & decodeContactPublicKeyHex', () {
    test('accepts lowercase 64-char hex', () {
      expect(normalizeContactPublicKeyHex(validLowerHex), validLowerHex);
      final bytes = decodeContactPublicKeyHex(validLowerHex);
      expect(bytes, isNotNull);
      expect(bytes!.length, 32);
      expect(bytes[0], 0x00);
      expect(bytes[31], 0x1f);
    });

    test('trims whitespace, strips 0x/0X prefix, and normalizes case', () {
      expect(
        normalizeContactPublicKeyHex('  0x$validUpperHex \n\t '),
        validLowerHex,
      );
      expect(normalizeContactPublicKeyHex('0X$validUpperHex'), validLowerHex);
    });

    test(
      'rejects invalid lengths, non-hex characters, and internal spaces',
      () {
        expect(normalizeContactPublicKeyHex(''), isNull);
        expect(normalizeContactPublicKeyHex('   '), isNull);
        expect(
          normalizeContactPublicKeyHex(validLowerHex.substring(0, 63)),
          isNull,
        );
        expect(normalizeContactPublicKeyHex('${validLowerHex}aa'), isNull);
        expect(normalizeContactPublicKeyHex('0x $validLowerHex'), isNull);
        expect(normalizeContactPublicKeyHex('zz' * 32), isNull);
        expect(decodeContactPublicKeyHex('zz' * 32), isNull);
      },
    );
  });

  group('parseContactClipboard', () {
    test('parses official meshcore://contact/add URI', () {
      final result = parseContactClipboard(
        '  meshcore://contact/add?name=Alice&public_key=$validLowerHex&type=2  ',
      );
      expect(result.kind, ContactClipboardKind.contact);
      expect(result.contact, isNotNull);
      expect(result.contact!.name, 'Alice');
      expect(result.contact!.type, 2);
      expect(result.contact!.publicKey!.length, 32);
    });

    test('parses legacy meshcore://<advert> URI', () {
      final advertHex = '0a' * 98;
      final result = parseContactClipboard('meshcore://$advertHex');
      expect(result.kind, ContactClipboardKind.contact);
      expect(result.contact!.isAdvertPacket, isTrue);
      expect(result.contact!.advertPacket!.length, 98);
    });

    test('parses contact share token', () {
      final result = parseContactClipboard('Bob: <$validUpperHex:3:Bob Node>');
      expect(result.kind, ContactClipboardKind.contact);
      expect(result.contact!.name, 'Bob Node');
      expect(result.contact!.type, 3);
      expect(result.contact!.publicKey!.length, 32);
    });

    test('parses bare 64-char hex key with whitespace, 0x, and uppercase', () {
      final result = parseContactClipboard('\n  0x$validUpperHex  ');
      expect(result.kind, ContactClipboardKind.publicKey);
      expect(result.publicKeyHex, validLowerHex);
      expect(result.contact, isNull);
    });

    test('returns empty for null or whitespace-only text', () {
      expect(parseContactClipboard(null).kind, ContactClipboardKind.empty);
      expect(parseContactClipboard('').kind, ContactClipboardKind.empty);
      expect(parseContactClipboard('  \n\t ').kind, ContactClipboardKind.empty);
    });

    test('returns invalid for malformed URIs, short keys, and random text', () {
      expect(
        parseContactClipboard('meshcore://not-valid').kind,
        ContactClipboardKind.invalid,
      );
      expect(
        parseContactClipboard(
          'meshcore://channel/add?name=Public&secret=abcd',
        ).kind,
        ContactClipboardKind.invalid,
      );
      expect(
        parseContactClipboard(validLowerHex.substring(0, 62)).kind,
        ContactClipboardKind.invalid,
      );
      expect(
        parseContactClipboard('hello world').kind,
        ContactClipboardKind.invalid,
      );
    });
  });
}
