import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/mesh_event.dart';
import 'package:meshcore_open/services/local_api/local_api_archive.dart';
import 'package:meshcore_open/services/local_api/local_api_host.dart';
import 'package:meshcore_open/services/local_api/local_api_pairing.dart';
import 'package:meshcore_open/services/local_api/local_api_server.dart';

import 'local_api_test_peer.dart';

void main() {
  late _FakeHost host;
  late MemoryPairingStore store;
  late LocalApiServer server;
  late List<PairingRequest> requests;
  late Directory tempDir;
  late LocalApiArchive archive;
  // null leaves requests unanswered.
  bool? approve;

  Future<void> startServer({
    LocalApiLimits limits = const LocalApiLimits(minSendGap: Duration.zero),
    PairingBroker? broker,
  }) async {
    server = LocalApiServer(
      host: host,
      pairingStore: store,
      pairingBroker: broker,
      archive: archive,
      limits: limits,
      port: 0,
    );
    server.pairingBroker.requests.listen((request) {
      requests.add(request);
      final answer = approve;
      if (answer != null) server.pairingBroker.resolve(request.id, answer);
    });
    await server.start();
  }

  Future<void> restartServer({
    LocalApiLimits limits = const LocalApiLimits(minSendGap: Duration.zero),
    PairingBroker? broker,
  }) async {
    await server.stop();
    await startServer(limits: limits, broker: broker);
  }

  setUp(() async {
    host = _FakeHost();
    store = MemoryPairingStore();
    approve = true;
    requests = [];
    tempDir = await Directory.systemTemp.createTemp('local_api_test');
    archive = LocalApiArchive(
      file: () async => File('${tempDir.path}/local_api/archive.json'),
    );
    await startServer();
  });

  tearDown(() async {
    await server.stop();
    await host.close();
    await tempDir.delete(recursive: true);
  });

  String url() => 'ws://127.0.0.1:${server.boundPort}/api/v1';

  Future<Connection> open() async => Connection(await WebSocket.connect(url()));

  Future<Connection> connect(
    TestPeer peer, {
    String name = 'Roadbeacon',
  }) async {
    final connection = await open();
    connection.send({
      'type': 'hello',
      'client': {
        'name': name,
        'version': '0.4.0',
        'publicKey': peer.publicKeyBase64,
      },
    });
    return connection;
  }

  Future<Map<String, dynamic>> sendPair(
    Connection connection,
    TestPeer peer, {
    bool der = false,
  }) async {
    final challenge = await connection.next();
    expect(challenge['type'], 'pairing.challenge');
    final nonce = challenge['nonce'] as String;
    final message = 'meshcore-open-pair-v1:$nonce';
    expect(challenge['message'], message);
    connection.send({
      'type': 'pair',
      'signature': der ? peer.signDer(message) : peer.signRaw(message),
    });
    return challenge;
  }

  Future<Connection> paired(TestPeer peer) async {
    final connection = await connect(peer);
    await sendPair(connection, peer);
    final hello = await connection.next();
    expect(hello['type'], 'hello');
    return connection;
  }

  Future<Map<String, dynamic>> call(
    Connection connection,
    int id,
    String method, [
    Map<String, Object?> params = const {},
  ]) {
    connection.send({'id': id, 'method': method, 'params': params});
    return connection.next();
  }

  ChannelDataEvent dataEvent(
    List<int> payload, {
    String channel = '#roadstr',
    int dataType = 0xFF52,
    bool outgoing = false,
    DateTime? at,
  }) => ChannelDataEvent(
    channelIndex: channel == '#roadstr' ? 0 : 1,
    channelName: channel,
    dataType: dataType,
    payload: Uint8List.fromList(payload),
    snrRaw: -30,
    outgoing: outgoing,
    receivedAt: at ?? DateTime.now(),
  );

  group('handshake', () {
    test('requires hello before any method', () async {
      final connection = await open();
      connection.send({'id': 1, 'method': 'device.info'});
      final reply = await connection.next();
      expect(reply['type'], 'error');
      expect(reply['error']['code'], 'unauthorized');
      expect(await connection.closeCode(), 4001);
    });

    test('pairs a new app after the user approves', () async {
      final peer = TestPeer.generate(1);
      final connection = await connect(peer);
      final challenge = await sendPair(connection, peer);
      expect(challenge.containsKey('known'), isFalse);
      final hello = await connection.next();
      expect(hello['type'], 'hello');
      expect(hello['protocol'], 1);
      expect(hello['limits']['maxQueuedBytes'], 256 * 1024);

      expect(requests.single.name, 'Roadbeacon');
      expect(requests.single.fingerprint, hasLength(19));
      expect(store.isPaired(peer.publicKeyBase64), isTrue);

      final info = await call(connection, 1, 'device.info');
      expect(info['ok'], true);
      expect(info['result']['name'], 'Test Node');
    });

    test('a paired key gets the same challenge and no prompt', () async {
      final peer = TestPeer.generate(2);
      await (await paired(peer)).close();

      final second = await connect(peer);
      final challenge = await sendPair(second, peer);
      expect(challenge.containsKey('known'), isFalse);
      expect((await second.next())['type'], 'hello');
      expect(requests, hasLength(1));
    });

    test('accepts a DER signature as made by SHA256withECDSA', () async {
      final peer = TestPeer.generate(3);
      final connection = await connect(peer);
      await sendPair(connection, peer, der: true);
      expect((await connection.next())['type'], 'hello');
    });

    test('rejects a signature from a different key', () async {
      final peer = TestPeer.generate(4);
      final impostor = TestPeer.generate(5);
      final connection = await connect(peer);
      final challenge = await connection.next();
      connection.send({
        'type': 'pair',
        'signature': impostor.signRaw(challenge['message'] as String),
      });
      expect((await connection.next())['error']['code'], 'unauthorized');
      expect(await connection.closeCode(), 4003);
      expect(requests, isEmpty);
      expect(store.isPaired(peer.publicKeyBase64), isFalse);
    });

    test('rejects a public key that is not on P-256', () async {
      final connection = await open();
      connection.send({
        'type': 'hello',
        'client': {
          'name': 'Bad',
          'version': '1',
          'publicKey': base64Encode(List<int>.filled(64, 1)),
        },
      });
      final reply = await connection.next();
      expect(reply['error']['code'], 'bad_request');
      expect(reply['error']['message'], 'invalid public key');
      expect(await connection.closeCode(), 4003);
    });

    test('closes when the user denies', () async {
      approve = false;
      final peer = TestPeer.generate(6);
      final connection = await connect(peer);
      await sendPair(connection, peer);
      expect((await connection.next())['error']['code'], 'unauthorized');
      expect(await connection.closeCode(), 4003);
      expect(store.isPaired(peer.publicKeyBase64), isFalse);
    });

    test('a second pair frame on one connection is refused', () async {
      approve = null;
      final peer = TestPeer.generate(7);
      final connection = await connect(peer);
      final challenge = await sendPair(connection, peer);
      connection.send({
        'type': 'pair',
        'signature': peer.signRaw(challenge['message'] as String),
      });
      expect((await connection.next())['error']['code'], 'unauthorized');
      expect(await connection.closeCode(), 4001);
      // Closing cancelled the one prompt that was opened.
      expect(requests, hasLength(1));
      expect(server.pairingBroker.pendingCount, 0);
    });

    test('one key has at most one open prompt', () async {
      approve = null;
      final peer = TestPeer.generate(8);
      final first = await connect(peer);
      await sendPair(first, peer);
      await pumpUntil(() => requests.isNotEmpty);

      final second = await connect(peer);
      await sendPair(second, peer);
      expect((await second.next())['error']['code'], 'pairing_pending');
      expect(requests, hasLength(1));

      server.pairingBroker.resolve(requests.single.id, true);
      expect((await first.next())['type'], 'hello');
    });

    test('a closed socket cancels its prompt', () async {
      approve = null;
      final cancelled = <String>[];
      server.pairingBroker.cancelled.listen(cancelled.add);
      final peer = TestPeer.generate(9);
      final connection = await connect(peer);
      await sendPair(connection, peer);
      await pumpUntil(() => requests.isNotEmpty);

      await connection.close();
      await pumpUntil(() => cancelled.isNotEmpty);
      expect(cancelled.single, requests.single.id);
      expect(server.pairingBroker.resolve(requests.single.id, true), isFalse);
      expect(store.isPaired(peer.publicKeyBase64), isFalse);
    });

    test('the challenge expires with the hello timeout', () async {
      await restartServer(
        limits: const LocalApiLimits(helloTimeout: Duration(milliseconds: 200)),
      );
      final peer = TestPeer.generate(10);
      final connection = await connect(peer);
      await connection.next();
      expect(await connection.closeCode(), 4001);
    });
  });

  group('transport', () {
    test('rejects upgrades that carry an Origin header', () async {
      await expectLater(
        WebSocket.connect(url(), headers: {'Origin': 'https://example.com'}),
        throwsA(isA<WebSocketException>()),
      );
      expect(server.clientCount, 0);
    });

    test('caps unpaired and paired connections', () async {
      await restartServer(
        limits: const LocalApiLimits(maxClients: 1, maxPendingClients: 2),
      );
      final idle = [await open(), await open()];
      await expectLater(open(), throwsA(isA<WebSocketException>()));
      for (final connection in idle) {
        await connection.close();
      }
      await pumpUntil(() => server.clientCount == 0);

      await paired(TestPeer.generate(11));
      final peer = TestPeer.generate(12);
      final second = await connect(peer);
      await sendPair(second, peer);
      expect((await second.next())['error']['code'], 'too_many_clients');
      expect(await second.closeCode(), 4013);
    });

    test('binary frames close the connection', () async {
      final connection = await paired(TestPeer.generate(13));
      connection.socket.add(Uint8List.fromList([1, 2, 3]));
      expect(await connection.closeCode(), 1003);
      expect(server.clientCount, 0);
    });

    test('an oversized message closes the connection', () async {
      await restartServer(limits: const LocalApiLimits(maxMessageBytes: 1024));
      final connection = await open();
      connection.socket.add('x' * 4000);
      expect(await connection.closeCode(), 1009);
      await pumpUntil(() => server.clientCount == 0);
    });

    test('a client that stops reading is closed', () async {
      final slow = await paired(TestPeer.generate(14));
      final reading = await paired(TestPeer.generate(15));
      for (final connection in [slow, reading]) {
        await call(connection, 1, 'events.subscribe', {
          'events': ['channel.data'],
        });
      }
      slow.pause();

      // About 350 bytes per event: well past the 256 KiB queue plus what the
      // OS buffers on loopback. The client that keeps reading stays.
      final payload = List<int>.generate(163, (i) => i);
      for (var i = 0; i < 100000 && server.clientCount > 1; i++) {
        host.emit(dataEvent(payload));
        if (i % 100 == 0) await Future<void>.delayed(Duration.zero);
      }
      expect(server.clientCount, 1);
      expect((await reading.next())['type'], 'event');
    });
  });

  group('subscriptions', () {
    test('delivers only matching channel data', () async {
      final connection = await paired(TestPeer.generate(20));
      final ack = await call(connection, 2, 'events.subscribe', {
        'events': ['channel.data'],
        'channel': '#roadstr',
        'dataTypes': [0xFF52],
      });
      final sub = ack['result']['subscriptionId'];

      host.emit(dataEvent([1, 2], channel: 'other'));
      host.emit(dataEvent([5], dataType: 0xAE1C));
      host.emit(dataEvent([9, 8, 7]));

      final event = await connection.next();
      expect(event['subscriptionId'], sub);
      expect(event['event']['channel'], '#roadstr');
      expect(base64Decode(event['event']['payload'] as String), [9, 8, 7]);
      expect(event['event']['snrDb'], -7.5);
    });

    test('subscription ids are not reused after unsubscribe', () async {
      final connection = await paired(TestPeer.generate(21));
      Future<String> subscribe(int id) async =>
          (await call(
                connection,
                id,
                'events.subscribe',
              ))['result']['subscriptionId']
              as String;
      final first = await subscribe(1);
      final second = await subscribe(2);
      expect(
        (await call(connection, 3, 'events.unsubscribe', {
          'subscriptionId': first,
        }))['ok'],
        true,
      );
      final third = await subscribe(4);
      expect({first, second, third}, hasLength(3));
    });

    test('rejects bad and oversized filters', () async {
      final connection = await paired(TestPeer.generate(22));
      final negative = await call(connection, 1, 'events.subscribe', {
        'dataTypes': [-1],
      });
      expect(negative['error']['code'], 'invalid_data_type');
      final long = await call(connection, 2, 'events.subscribe', {
        'pubkeys': List.filled(33, 'ab'),
      });
      expect(long['error']['code'], 'bad_request');
    });
  });

  group('sending', () {
    Future<Map<String, dynamic>> sendData(
      Connection connection,
      int id,
      List<int> bytes,
    ) => call(connection, id, 'channel.sendData', {
      'channel': '#roadstr',
      'dataType': 0xFF52,
      'payload': base64Encode(bytes),
    });

    test('rejects oversized payloads and enforces the send gap', () async {
      await restartServer(limits: const LocalApiLimits());
      final connection = await paired(TestPeer.generate(30));
      expect((await sendData(connection, 1, [1, 2, 3]))['ok'], true);
      expect(host.sent.single, [1, 2, 3]);
      expect(
        (await sendData(connection, 2, List.filled(164, 0)))['error']['code'],
        'payload_too_large',
      );
      expect(
        (await sendData(connection, 3, [4]))['error']['code'],
        'rate_limited',
      );
    });

    test('allows the configured sends per minute', () async {
      await restartServer(
        limits: const LocalApiLimits(
          minSendGap: Duration.zero,
          sendsPerMinute: 3,
        ),
      );
      final connection = await paired(TestPeer.generate(31));
      for (var i = 0; i < 3; i++) {
        expect((await sendData(connection, i, [i]))['ok'], true);
      }
      expect(
        (await sendData(connection, 9, [9]))['error']['code'],
        'rate_limited',
      );
    });

    test('a send the radio refuses does not spend quota', () async {
      await restartServer(
        limits: const LocalApiLimits(
          minSendGap: Duration.zero,
          sendsPerMinute: 1,
        ),
      );
      final connection = await paired(TestPeer.generate(32));
      host.sendResult = false;
      expect(
        (await sendData(connection, 1, [1]))['error']['code'],
        'not_connected',
      );
      host.throwOnSend = true;
      expect(
        (await sendData(connection, 2, [2]))['error']['code'],
        'radio_error',
      );
      host
        ..sendResult = true
        ..throwOnSend = false;
      expect((await sendData(connection, 3, [3]))['ok'], true);
    });

    test('reports firmware without channel data', () async {
      host.channelData = false;
      final connection = await paired(TestPeer.generate(33));
      expect(
        (await sendData(connection, 1, [1]))['error']['code'],
        'unsupported_firmware',
      );
    });
  });

  group('archive and replay', () {
    Future<Map<String, dynamic>> subscribe(
      Connection connection,
      int id, {
      Object? since,
    }) => call(connection, id, 'events.subscribe', {
      'events': ['channel.data'],
      'channel': '#roadstr',
      'dataTypes': [0xFF52],
      'since': ?since,
    });

    test('replays after the ack, oldest first, then live events', () async {
      final peer = TestPeer.generate(40);
      final first = await paired(peer);
      await subscribe(first, 1);
      await first.close();
      await pumpUntil(() => server.clientCount == 0);

      final start = DateTime.now().toUtc().subtract(
        const Duration(seconds: 10),
      );
      host.emit(dataEvent([1], at: start));
      host.emit(dataEvent([2], at: start.add(const Duration(seconds: 1))));
      host.emit(dataEvent([3], outgoing: true));
      host.emit(dataEvent([4], dataType: 0xAE1C));
      await Future<void>.delayed(Duration.zero);

      final second = await paired(peer);
      second.send({
        'id': 2,
        'method': 'events.subscribe',
        'params': {
          'events': ['channel.data'],
          'channel': '#roadstr',
          'dataTypes': [0xFF52],
          'since': start.toIso8601String(),
        },
      });
      host.emit(dataEvent([5]));

      final ack = await second.next();
      expect(ack['id'], 2);
      final sub = ack['result']['subscriptionId'];
      final payloads = <List<int>>[];
      for (var i = 0; i < 3; i++) {
        final event = await second.next();
        expect(event['subscriptionId'], sub);
        payloads.add(base64Decode(event['event']['payload'] as String));
      }
      expect(payloads, [
        [1],
        [2],
        [5],
      ]);
    });

    test('since is inclusive', () async {
      final peer = TestPeer.generate(41);
      final connection = await paired(peer);
      await subscribe(connection, 1);
      final at = DateTime.utc(2030, 1, 1, 12);
      host.emit(dataEvent([7], at: at));
      await connection.next();
      final ack = await subscribe(
        connection,
        2,
        since: at.millisecondsSinceEpoch,
      );
      expect(ack['ok'], true);
      final replayed = await connection.next();
      expect(base64Decode(replayed['event']['payload'] as String), [7]);
    });

    test('a client only replays what it registered for', () async {
      final interested = TestPeer.generate(42);
      await subscribe(await paired(interested), 1);
      host.emit(dataEvent([1]));
      await Future<void>.delayed(Duration.zero);

      final other = await paired(TestPeer.generate(43));
      final ack = await call(other, 1, 'events.subscribe', {
        'events': ['channel.data'],
        'since': 0,
      });
      expect(ack['ok'], true);
      await expectLater(other.next(), throwsA(isA<TimeoutException>()));
    });

    test('revoke closes live sessions and drops the archive', () async {
      final peer = TestPeer.generate(44);
      final connection = await paired(peer);
      await subscribe(connection, 1);
      host.emit(dataEvent([1]));
      await connection.next();

      await server.revoke(peer.publicKeyBase64);
      expect(await connection.closeCode(), 4003);
      expect(connection.socket.closeReason, 'revoked');
      expect(store.isPaired(peer.publicKeyBase64), isFalse);
      expect(
        archive.replay(peer.publicKeyBase64, since: DateTime.utc(2000)),
        isEmpty,
      );
    });
  });

  group('radio state and channels', () {
    test('pushes device when the radio goes away and comes back', () async {
      final connection = await paired(TestPeer.generate(60));
      host.ready = false;
      host.changed();
      final gone = await connection.next();
      expect(gone['type'], 'device');
      expect(gone['device']['connected'], false);

      host.changed(); // nothing new: not repeated
      host.ready = true;
      host.changed();
      final back = await connection.next();
      expect(back['device']['connected'], true);
      expect(back['channels'], isNotEmpty);
    });

    test('hello reports a radio that is not ready', () async {
      host.ready = false;
      final peer = TestPeer.generate(61);
      final connection = await connect(peer);
      await sendPair(connection, peer);
      final hello = await connection.next();
      expect(hello['device']['connected'], false);
    });

    test('channel data events carry the hop count', () async {
      final connection = await paired(TestPeer.generate(62));
      expect(
        (await call(connection, 1, 'events.subscribe', {
          'events': ['channel.data'],
        }))['ok'],
        true,
      );
      host.emit(
        ChannelDataEvent(
          channelIndex: 0,
          channelName: '#roadstr',
          dataType: 0xFF52,
          payload: Uint8List.fromList([1]),
          snrRaw: -30,
          hops: 3,
          outgoing: false,
          receivedAt: DateTime.now(),
        ),
      );
      final event = await connection.next();
      expect(event['event']['hops'], 3);
    });

    test('joining an existing hashtag channel needs no prompt', () async {
      final connection = await paired(TestPeer.generate(63));
      final reply = await call(connection, 1, 'channels.join', {
        'name': '#roadstr',
      });
      expect(reply['result'], {
        'index': 0,
        'name': '#roadstr',
        'created': false,
      });
      expect(requests, hasLength(1)); // only the pairing
    });

    test('joining a new channel asks the user, then adds it', () async {
      final connection = await paired(TestPeer.generate(64));
      final reply = await call(connection, 1, 'channels.join', {
        'name': '#trains',
      });
      expect(reply['result'], {'index': 5, 'name': '#trains', 'created': true});
      expect(requests.last.channelName, '#trains');
      expect(requests.last.name, 'Roadbeacon');
      expect(host.added, ['#trains']);
    });

    test('a denied join adds nothing', () async {
      final connection = await paired(TestPeer.generate(65));
      approve = false;
      final reply = await call(connection, 1, 'channels.join', {
        'name': '#trains',
      });
      expect(reply['error']['code'], 'denied');
      expect(host.added, isEmpty);
    });

    test('a join is refused without a free slot or a radio', () async {
      final connection = await paired(TestPeer.generate(66));
      host.freeSlot = null;
      expect(
        (await call(connection, 1, 'channels.join', {
          'name': '#trains',
        }))['error']['code'],
        'no_free_slot',
      );
      host.ready = false;
      expect(
        (await call(connection, 2, 'channels.join', {
          'name': '#other',
        }))['error']['code'],
        'not_connected',
      );
    });

    test('only lowercase hashtag names can be joined', () async {
      final connection = await paired(TestPeer.generate(67));
      for (final name in ['roadstr', '#Roadstr', '#', '#a b', 'other']) {
        final reply = await call(connection, 1, 'channels.join', {
          'name': name,
        });
        expect(reply['error']['code'], 'invalid_params', reason: name);
      }
    });

    test(
      'a channel with the same name and another key is a conflict',
      () async {
        host.channelList = [
          ...host.channelList,
          Channel(index: 2, name: '#trains', psk: Uint8List(16)),
        ];
        final connection = await paired(TestPeer.generate(68));
        final reply = await call(connection, 1, 'channels.join', {
          'name': '#trains',
        });
        expect(reply['error']['code'], 'channel_conflict');
      },
    );
  });
}

Future<void> pumpUntil(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class Connection {
  final WebSocket socket;
  final List<String> _queue = [];
  late final StreamSubscription<dynamic> _subscription;
  Completer<String>? _waiter;
  final Completer<void> _done = Completer<void>();

  Connection(this.socket) {
    _subscription = socket.listen((data) {
      final waiter = _waiter;
      if (waiter != null) {
        _waiter = null;
        waiter.complete(data as String);
      } else {
        _queue.add(data as String);
      }
    }, onDone: _done.complete);
  }

  void send(Map<String, Object?> message) => socket.add(jsonEncode(message));

  void pause() => _subscription.pause();

  Future<Map<String, dynamic>> next() async {
    final raw = _queue.isNotEmpty
        ? _queue.removeAt(0)
        : await (_waiter = Completer<String>()).future.timeout(
            const Duration(seconds: 2),
          );
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<int?> closeCode() async {
    await _done.future.timeout(const Duration(seconds: 3));
    return socket.closeCode;
  }

  Future<void> close() => socket.close();
}

class _FakeHost implements LocalApiHost {
  final _controller = StreamController<MeshEvent>.broadcast(sync: true);
  final _changes = StreamController<void>.broadcast(sync: true);
  final List<List<int>> sent = [];
  final List<String> added = [];
  bool channelData = true;
  bool sendResult = true;
  bool throwOnSend = false;
  bool ready = true;
  int? freeSlot = 5;
  List<Channel> channelList = [
    Channel(
      index: 0,
      name: '#roadstr',
      psk: Channel.derivePskFromHashtag('#roadstr'),
    ),
    Channel(index: 1, name: 'other', psk: Uint8List(16)),
  ];

  @override
  Stream<MeshEvent> get events => _controller.stream;

  @override
  Stream<void> get changes => _changes.stream;

  Future<void> close() async {
    await _controller.close();
    await _changes.close();
  }

  void emit(MeshEvent event) => _controller.add(event);

  void changed() => _changes.add(null);

  @override
  bool get isConnected => true;

  @override
  bool get isReady => ready;

  @override
  bool get supportsChannelData => channelData;

  @override
  Map<String, Object?> deviceInfo() => {
    'connected': true,
    'name': 'Test Node',
    'pubkey': 'ab' * 32,
    'firmwareVerCode': 11,
    'batteryMv': 4000,
  };

  @override
  List<Map<String, Object?>> channels() => [
    for (final channel in channelList)
      {'index': channel.index, 'name': channel.name},
  ];

  @override
  List<Map<String, Object?>> contacts({int limit = 200}) => const [];

  @override
  Channel? resolveChannel(String nameOrIndex, {void Function()? onAmbiguous}) {
    final index = int.tryParse(nameOrIndex);
    for (final channel in channelList) {
      if (index != null
          ? channel.index == index
          : channel.name == nameOrIndex) {
        return channel;
      }
    }
    return null;
  }

  @override
  List<Channel> channelsNamed(String name) =>
      channelList.where((channel) => channel.name == name).toList();

  @override
  Future<int?> addHashtagChannel(String name) async {
    final slot = freeSlot;
    if (slot == null) return null;
    added.add(name);
    channelList = [
      ...channelList,
      Channel(index: slot, name: name, psk: Channel.derivePskFromHashtag(name)),
    ];
    return slot;
  }

  @override
  Contact? resolveContact(String pubkeyHex) => null;

  @override
  Future<void> sendChannelText(Channel channel, String text) async {}

  @override
  Future<bool> sendChannelData(
    Channel channel,
    int dataType,
    Uint8List payload,
  ) async {
    if (throwOnSend) throw Exception('Command failed with error code 3');
    if (sendResult) sent.add(payload.toList());
    return sendResult;
  }

  @override
  Future<void> sendDirectText(Contact contact, String text) async {}

  @override
  Future<void> sendAdvert({bool flood = true}) async {}
}
