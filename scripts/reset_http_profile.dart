import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run scripts/reset_http_profile.dart <Dart VM service URI>',
    );
    exitCode = 64;
    return;
  }
  try {
    final remaining = await resetHttpProfile(Uri.parse(arguments.single));
    stdout.writeln('HTTP recording stopped; retained HTTP profile cleared.');
    if (remaining > 0) {
      stdout.writeln(
        '$remaining requests remain in a separate HTTP profiling provider.',
      );
    }
  } catch (error) {
    stderr.writeln('Could not reset HTTP profiling: $error');
    exitCode = 1;
  }
}

/// Stops recording before clearing captured bodies; normal networking continues.
/// Returns records still reported by other HTTP profiling providers.
Future<int> resetHttpProfile(Uri serviceUri) async {
  final scheme = switch (serviceUri.scheme) {
    'http' || 'ws' => 'ws',
    'https' || 'wss' => 'wss',
    _ => throw const FormatException(
      'Expected an HTTP or WebSocket service URI',
    ),
  };
  final path = serviceUri.path.endsWith('/ws')
      ? serviceUri.path
      : '${serviceUri.path.endsWith('/') ? serviceUri.path : '${serviceUri.path}/'}ws';
  final socket = await WebSocket.connect(
    serviceUri.replace(scheme: scheme, path: path).toString(),
  ).timeout(const Duration(seconds: 10));
  final messages = StreamIterator<dynamic>(socket);
  var nextId = 0;

  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, Object> parameters = const {},
  ]) async {
    final id = '${++nextId}';
    socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': parameters,
      }),
    );
    while (await messages.moveNext().timeout(const Duration(seconds: 10))) {
      if (messages.current is! String) continue;
      final response = jsonDecode(messages.current as String) as Map;
      if (response['id'] != id) continue;
      if (response['error'] case final Map error) {
        throw StateError('$method: ${error['message']}');
      }
      return Map<String, dynamic>.from(response['result'] as Map);
    }
    throw StateError('The Dart VM service disconnected');
  }

  try {
    final vm = await call('getVM');
    final isolates = (vm['isolates'] as List).cast<Map>();
    final mainIsolates = isolates.where((isolate) => isolate['name'] == 'main');
    if (mainIsolates.length != 1) {
      throw StateError('Expected one running main isolate');
    }
    final parameters = <String, Object>{
      'isolateId': mainIsolates.single['id'] as String,
    };
    await call('ext.dart.io.httpEnableTimelineLogging', {
      ...parameters,
      'enabled': 'false',
    });
    await call('ext.dart.io.clearHttpProfile', parameters);
    final state = await call(
      'ext.dart.io.httpEnableTimelineLogging',
      parameters,
    );
    if (state['enabled'] != false) {
      throw StateError('HTTP recording was enabled again by another client');
    }
    final profile = await call('ext.dart.io.getHttpProfile', parameters);
    return (profile['requests'] as List).length;
  } finally {
    await messages.cancel();
    await socket.close();
  }
}
