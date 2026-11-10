import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/reset_http_profile.dart';

void main() {
  test('stops recording before clearing and verifies the result', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final calls = <Map<String, dynamic>>[];
    final paths = <String>[];
    var recording = true;
    var requests = <Object>[
      {'id': 'captured-request'},
    ];
    final subscription = server.listen((request) async {
      paths.add(request.uri.path);
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((data) {
        final call = jsonDecode(data as String) as Map<String, dynamic>;
        calls.add(call);
        final parameters = call['params'] as Map;
        Map<String, dynamic> result;
        switch (call['method']) {
          case 'getVM':
            result = {
              'isolates': [
                {'name': 'worker', 'id': 'worker'},
                {'name': 'main', 'id': 'main-isolate'},
              ],
            };
          case 'ext.dart.io.httpEnableTimelineLogging':
            if (parameters['enabled'] == 'false') recording = false;
            result = {'enabled': recording};
          case 'ext.dart.io.clearHttpProfile':
            expect(recording, isFalse);
            requests = [];
            result = {'type': 'Success'};
          case 'ext.dart.io.getHttpProfile':
            result = {'requests': requests};
          default:
            fail('Unexpected service method ${call['method']}');
        }
        socket.add(jsonEncode({'id': call['id'], 'result': result}));
      });
    });
    addTearDown(() async {
      await subscription.cancel();
      await server.close(force: true);
    });

    expect(
      await resetHttpProfile(
        Uri.parse('http://127.0.0.1:${server.port}/service-token=/'),
      ),
      0,
    );
    expect(paths, ['/service-token=/ws']);
    expect(calls.map((call) => call['method']), [
      'getVM',
      'ext.dart.io.httpEnableTimelineLogging',
      'ext.dart.io.clearHttpProfile',
      'ext.dart.io.httpEnableTimelineLogging',
      'ext.dart.io.getHttpProfile',
    ]);
    for (final call in calls.skip(1)) {
      expect((call['params'] as Map)['isolateId'], 'main-isolate');
    }
  });

  test('rejects unsupported URIs before connecting', () async {
    await expectLater(
      resetHttpProfile(Uri.parse('file:///tmp/service')),
      throwsFormatException,
    );
  });
}
