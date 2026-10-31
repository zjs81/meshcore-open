import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/channel_qr.dart';

void main() {
  group('parseChannelQr', () {
    test('parses the official channel link', () {
      final result = parseChannelQr(
        'meshcore://channel/add?name=Public&secret=8b3387e9c5cdea6ac9e5edbaa115cd72',
      );

      expect(result, isNotNull);
      expect(result!.name, 'Public');
      expect(result.psk.length, 16);
      expect(result.psk[0], 0x8b);
      expect(result.psk[15], 0x72);
    });

    test('decodes URL-encoded names and uppercase hex', () {
      final result = parseChannelQr(
        'meshcore://channel/add?name=%23ipnet%20test&secret=${'AB' * 16}',
      );

      expect(result, isNotNull);
      expect(result!.name, '#ipnet test');
      expect(result.psk.every((b) => b == 0xab), isTrue);
    });

    test('ignores the optional region_scope parameter', () {
      final result = parseChannelQr(
        'meshcore://channel/add?name=Test&secret=${'00' * 16}&region_scope=gb-est',
      );

      expect(result, isNotNull);
      expect(result!.name, 'Test');
    });

    test('rejects missing name, bad secret and other links', () {
      expect(
        parseChannelQr('meshcore://channel/add?secret=${'00' * 16}'),
        isNull,
      );
      expect(
        parseChannelQr('meshcore://channel/add?name=X&secret=abcd'),
        isNull,
      );
      expect(
        parseChannelQr('meshcore://channel/add?name=X&secret=${'zz' * 16}'),
        isNull,
      );
      expect(
        parseChannelQr('meshcore://contact/add?name=X&public_key=${'00' * 32}'),
        isNull,
      );
      expect(parseChannelQr('https://ipnt.uk/channels'), isNull);
      expect(
        parseChannelQr(
          'meshcore://channel/add?name=%FF&secret=8b3387e9c5cdea6ac9e5edbaa115cd72',
        ),
        isNull,
      );
      expect(parseChannelQr('{"type":"meshcore_community"}'), isNull);
      expect(parseChannelQr(''), isNull);
    });
  });
}
