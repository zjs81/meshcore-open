import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_open/helpers/message_url_image_helper.dart';

void main() {
  group('MessageUrlImageHelper', () {
    tearDown(() => MessageUrlImageHelper.httpClient = null);

    void mockPyxPage(String id) {
      MessageUrlImageHelper.httpClient = MockClient((request) async {
        expect(request.url.toString(), 'https://pyx.li/?i=$id');
        return http.Response(
          '<html><body><img src="/i/$id.jpg"></body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
    }

    test('parses short pyx ids', () async {
      mockPyxPage('RzmdkTsE');
      final attachment = await MessageUrlImageHelper.parse(
        'my picture: https://pyx.li/?i=RzmdkTsE text',
      );

      expect(attachment, 'https://pyx.li/i/RzmdkTsE.jpg');
    });

    test('parses direct pyx image urls', () async {
      mockPyxPage('Cd1KFiwu');
      final attachment = await MessageUrlImageHelper.parse(
        'https://pyx.li/?i=Cd1KFiwu',
      );

      expect(attachment, 'https://pyx.li/i/Cd1KFiwu.jpg');
    });

    test('parses provider-hosted ipfs links', () async {
      final attachment = await MessageUrlImageHelper.parse(
        'my picture: https://uneven-plum-tarantula.myfilebase.com/ipfs/bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly text',
      );

      expect(attachment, isNotNull);
      expect(
        attachment,
        'https://uneven-plum-tarantula.myfilebase.com/ipfs/bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly',
      );
    });

    test('parses direct ipfs cid urls', () async {
      final attachment = await MessageUrlImageHelper.parse(
        'my picture: ipfs://bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly text',
      );

      expect(attachment, isNotNull);
      expect(
        attachment,
        'https://ipfs.io/ipfs/bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly',
      );
    });

    test('parses direct ipfs cid urls without double slashes', () async {
      final attachment = await MessageUrlImageHelper.parse(
        'my picture: ipfs:bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly text',
      );

      expect(
        attachment,
        'https://ipfs.io/ipfs/bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly',
      );
    });

    test('parses http image urls', () async {
      final attachment = await MessageUrlImageHelper.parse(
        'see this image https://example.com/picture.png?size=large additional text',
      );

      expect(attachment, isNotNull);
      expect(attachment, 'https://example.com/picture.png?size=large');
    });

    test('returns null for plain text', () async {
      expect(await MessageUrlImageHelper.parse('hello world'), isNull);
    });

    test('detects supported image URLs without resolving them', () {
      expect(
        MessageUrlImageHelper.hasPotentialImageUrl(
          'https://pyx.li/?i=RzmdkTsE',
        ),
        isTrue,
      );
      expect(
        MessageUrlImageHelper.hasPotentialImageUrl('hello world'),
        isFalse,
      );
    });

    test('returns null for non-image ipfs gateway URL', () async {
      final attachment = await MessageUrlImageHelper.parseVerified(
        'https://lime-famous-rat-748.mypinata.cloud/ipfs/bafybeih3jqv36rsxqx7yw3k3ixhganrevrk7xmcxgkr2zuzjegxdytb3nq',
      );

      expect(attachment, isNull);
    });
  });
}
