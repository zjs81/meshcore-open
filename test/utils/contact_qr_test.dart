import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/contact_qr.dart';

void main() {
  group('parseContactQr official contact card', () {
    test('parses name with + and percent-encoding, key, explicit type', () {
      final key = List.generate(
        32,
        (i) => i.toRadixString(16).padLeft(2, '0'),
      ).join();
      final result = parseContactQr(
        'meshcore://contact/add?name=Jane+D%C3%B6e&public_key=$key&type=2',
      );

      expect(result, isNotNull);
      expect(result!.isAdvertPacket, isFalse);
      expect(result.name, 'Jane Döe');
      expect(result.publicKey!.length, 32);
      expect(result.publicKey![0], 0x00);
      expect(result.publicKey![31], 0x1f);
      expect(result.type, 2);
    });

    test('missing type defaults to 1', () {
      final key = 'ab' * 32;
      final result = parseContactQr(
        'meshcore://contact/add?name=Bob&public_key=$key',
      );

      expect(result, isNotNull);
      expect(result!.type, 1);
    });

    test('garbage type falls back to 1', () {
      final key = 'ab' * 32;
      final result = parseContactQr(
        'meshcore://contact/add?name=Bob&public_key=$key&type=nope',
      );

      expect(result, isNotNull);
      expect(result!.type, 1);
    });

    test('uppercase hex public key is accepted', () {
      final key = 'AB' * 32;
      final result = parseContactQr(
        'meshcore://contact/add?name=Bob&public_key=$key',
      );

      expect(result, isNotNull);
      expect(result!.publicKey!.length, 32);
      expect(result.publicKey![0], 0xAB);
    });

    test('63-char public key is rejected', () {
      final key = '${'ab' * 31}a';
      final result = parseContactQr(
        'meshcore://contact/add?name=Bob&public_key=$key',
      );

      expect(result, isNull);
    });

    test('non-hex public key is rejected', () {
      final key = ('zz' * 32);
      final result = parseContactQr(
        'meshcore://contact/add?name=Bob&public_key=$key',
      );

      expect(result, isNull);
    });

    test('signed public key digits are rejected', () {
      final result = parseContactQr(
        'meshcore://contact/add?name=Bob&public_key=${'+1' * 32}',
      );

      expect(result, isNull);
    });

    test('missing name defaults to empty string', () {
      final key = 'ab' * 32;
      final result = parseContactQr('meshcore://contact/add?public_key=$key');

      expect(result, isNotNull);
      expect(result!.name, '');
    });
  });

  group('parseContactQr legacy advert packet', () {
    test('legacy hex form yields advert packet bytes', () {
      final hex = '0a' * 98;
      final result = parseContactQr('meshcore://$hex');

      expect(result, isNotNull);
      expect(result!.isAdvertPacket, isTrue);
      expect(result.advertPacket!.length, 98);
      expect(result.advertPacket![0], 0x0a);
    });

    test('odd-length hex is rejected', () {
      final result = parseContactQr('meshcore://abc');

      expect(result, isNull);
    });

    test('non-hex payload is rejected', () {
      final result = parseContactQr('meshcore://zz${'00' * 97}');

      expect(result, isNull);
    });

    test('payload shorter than the 98 byte advert minimum is rejected', () {
      final result = parseContactQr('meshcore://${'ab' * 97}');

      expect(result, isNull);
    });

    test('payload longer than the 171 byte frame limit is rejected', () {
      final result = parseContactQr('meshcore://${'ab' * 172}');

      expect(result, isNull);
    });

    test('payload at the 171 byte frame limit is accepted', () {
      final result = parseContactQr('meshcore://${'ab' * 171}');

      expect(result, isNotNull);
      expect(result!.advertPacket!.length, 171);
    });
  });

  group('parseContactQr rejects unsupported input', () {
    test('channel add link is not a contact', () {
      final result = parseContactQr(
        'meshcore://channel/add?name=Public&secret=abcd',
      );

      expect(result, isNull);
    });

    test('non-meshcore scheme is rejected', () {
      final result = parseContactQr('https://example.com/contact/add');

      expect(result, isNull);
    });

    test('empty string is rejected', () {
      expect(parseContactQr(''), isNull);
    });

    test('whitespace-only string is rejected', () {
      expect(parseContactQr('   \n\t  '), isNull);
    });
  });
}
