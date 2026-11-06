import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_open/helpers/ipfs_upload_helper.dart';

void main() {
  group('IpfsUploadHelper', () {
    tearDown(() => IpfsUploadHelper.httpClient = null);

    test('does not upload when the upload endpoint is empty', () async {
      var requestCount = 0;
      IpfsUploadHelper.httpClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      await expectLater(
        IpfsUploadHelper.uploadImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'image.png',
          mimeType: 'image/png',
          uploadEndpoint: '',
          uploadApiKey: '',
        ),
        throwsException,
      );
      expect(requestCount, 0);
    });

    for (final endpoint in [
      'not a url',
      'ftp://host/api/v0/add',
      'https://host/ipfs-upload',
      'https://uploads.example.com/v1/files',
    ]) {
      test('rejects $endpoint before uploading', () async {
        var requestCount = 0;
        IpfsUploadHelper.httpClient = MockClient((request) async {
          requestCount++;
          return http.Response('{"Hash":"bafytest"}', 200);
        });

        await expectLater(
          IpfsUploadHelper.uploadImage(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'image.png',
            mimeType: 'image/png',
            uploadEndpoint: endpoint,
            uploadApiKey: 'token',
          ),
          throwsA(isA<Exception>()),
        );
        expect(requestCount, 0);
      });
    }

    test('copies to MFS through a proxied Kubo endpoint', () async {
      final urls = <Uri>[];
      IpfsUploadHelper.httpClient = MockClient((request) async {
        urls.add(request.url);
        return http.Response('{"Hash":"bafytest"}', 200);
      });

      final message = await IpfsUploadHelper.uploadImage(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: 'image.png',
        mimeType: 'image/png',
        uploadEndpoint: 'https://host/ipfs-upload/api/v0/add',
        uploadApiKey: '',
      );

      expect(message, 'ipfs://bafytest');
      expect(urls.map((url) => url.path), [
        '/ipfs-upload/api/v0/add',
        '/ipfs-upload/api/v0/files/cp',
      ]);
      expect(urls.last.queryParametersAll['arg'], [
        '/ipfs/bafytest',
        '/meshcore_uploads/bafytest-image.png',
      ]);
    });

    test(
      'uploads and returns an ipfs scheme when upload gateway is empty',
      () async {
        final requests = <http.BaseRequest>[];
        IpfsUploadHelper.httpClient = MockClient((request) async {
          requests.add(request);
          expect(request.method, 'POST');
          return http.Response(
            '{"Hash":"bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly"}',
            200,
          );
        });

        final message = await IpfsUploadHelper.uploadImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'image.png',
          mimeType: 'image/png',
          uploadEndpoint: 'http://127.0.0.1:5001/api/v0/add',
          uploadApiKey: '',
        );

        expect(
          message,
          'ipfs://bafybeibq75ws6nwk6wi473dch42wwy6woyj4dwdfy7nfz3buqx2caieoly',
        );
        expect(requests.first.url.path, '/api/v0/add');
        expect(requests.first.url.queryParameters, {
          'cid-version': '1',
          'pin': 'true',
        });
      },
    );

    test(
      're-sharing a file already in Kubo MFS still returns the link',
      () async {
        final paths = <String>[];
        IpfsUploadHelper.httpClient = MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/files/cp')) {
            return http.Response(
              '{"Message":"cp: cannot put node in path /meshcore_uploads/bafytest-image.png: directory already has entry by that name","Code":0,"Type":"error"}',
              500,
            );
          }
          return http.Response('{"Hash":"bafytest"}', 200);
        });

        final message = await IpfsUploadHelper.uploadImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'image.png',
          mimeType: 'image/png',
          uploadEndpoint: 'http://127.0.0.1:5001/api/v0/add',
          uploadApiKey: '',
        );

        expect(message, 'ipfs://bafytest');
        expect(paths, ['/api/v0/add', '/api/v0/files/cp']);
      },
    );

    test('other Kubo MFS errors still fail the upload', () async {
      IpfsUploadHelper.httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/files/cp')) {
          return http.Response('{"Message":"permission denied"}', 500);
        }
        return http.Response('{"Hash":"bafytest"}', 200);
      });

      await expectLater(
        IpfsUploadHelper.uploadImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'image.png',
          mimeType: 'image/png',
          uploadEndpoint: 'http://127.0.0.1:5001/api/v0/add',
          uploadApiKey: '',
        ),
        throwsException,
      );
    });

    test('sends the Pinata request to the endpoint unchanged', () async {
      late http.BaseRequest upload;
      IpfsUploadHelper.httpClient = MockClient((request) async {
        upload = request;
        return http.Response('{"IpfsHash":"bafytest"}', 200);
      });

      final message = await IpfsUploadHelper.uploadImage(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: 'image.png',
        mimeType: 'image/png',
        uploadEndpoint: 'https://api.pinata.cloud/pinning/pinFileToIPFS',
        uploadApiKey: 'jwt',
        uploadGateway: 'https://gateway.example.com',
      );

      expect(
        upload.url.toString(),
        'https://api.pinata.cloud/pinning/pinFileToIPFS',
      );
      expect(upload.headers['Authorization'], 'Bearer jwt');
      expect(message, 'https://gateway.example.com/ipfs/bafytest');
    });
  });
}
