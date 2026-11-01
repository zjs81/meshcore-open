import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/mesh_event.dart';
import 'package:meshcore_open/services/local_api/local_api_archive.dart';
import 'package:meshcore_open/services/local_api/local_api_crypto.dart';
import 'package:meshcore_open/services/local_api/local_api_pairing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_api_test_peer.dart';

ChannelDataEvent _event(
  List<int> payload, {
  int dataType = 0xB652,
  bool outgoing = false,
}) => ChannelDataEvent(
  channelIndex: 0,
  channelName: '#roadstr',
  dataType: dataType,
  payload: Uint8List.fromList(payload),
  snrRaw: -8,
  outgoing: outgoing,
  receivedAt: DateTime.now().toUtc(),
);

void main() {
  group('PrefsPairingStore', () {
    test('persists paired keys across loads', () async {
      SharedPreferences.setMockInitialValues({});
      final store = PrefsPairingStore();
      await store.load();
      await store.add(
        PairedClient(
          name: 'Roadbeacon',
          publicKey: 'key-a',
          fingerprint: 'AAAA BBBB CCCC DDDD',
          pairedAt: DateTime.utc(2026, 10, 27),
        ),
      );

      final reloaded = PrefsPairingStore();
      await reloaded.load();
      expect(reloaded.isPaired('key-a'), isTrue);
      expect(reloaded.clients.single.name, 'Roadbeacon');

      await reloaded.remove('key-a');
      final empty = PrefsPairingStore();
      await empty.load();
      expect(empty.clients, isEmpty);
    });
  });

  group('LocalApiArchive', () {
    late Directory dir;
    late File file;
    final since = DateTime.utc(2000);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('local_api_archive');
      file = File('${dir.path}/local_api/archive.json');
    });

    tearDown(() => dir.delete(recursive: true));

    LocalApiArchive archive() => LocalApiArchive(file: () async => file);

    test('keeps only received frames someone registered for', () async {
      final a = archive();
      a.record(_event([0]));
      a.noteInterest('key-a', '#roadstr', {0xB652});
      a.record(_event([1]));
      a.record(_event([2], outgoing: true));
      a.record(_event([3], dataType: 0xAE1C));
      expect(a.replay('key-a', since: since).map((e) => e.payload), [
        [1],
      ]);
    });

    test('survives a reload', () async {
      final a = archive();
      await a.load();
      a.noteInterest('key-a', '#roadstr', {});
      a.record(_event([4, 5]));
      await a.flush();

      final b = archive();
      await b.load();
      final entry = b.replay('key-a', since: since).single;
      expect(entry.payload, [4, 5]);
      expect(entry.channelIndex, 0);
      expect(entry.snrRaw, -8);
      // The interest survived too: new frames are still kept.
      b.record(_event([6]));
      expect(b.replay('key-a', since: since), hasLength(2));
    });

    test('forgetting a client drops frames only it wanted', () async {
      final a = archive();
      a.noteInterest('key-a', '#roadstr', {0xB652});
      a.noteInterest('key-b', '#roadstr', {0x0001});
      a.record(_event([1]));
      a.record(_event([2], dataType: 0x0001));

      a.forgetClient('key-a');
      expect(a.replay('key-a', since: since), isEmpty);
      expect(a.replay('key-b', since: since).single.payload, [2]);
      a.record(_event([3]));
      expect(a.replay('key-b', since: since), hasLength(1));
    });
  });

  group('PairingBroker', () {
    Future<bool> ask(PairingBroker broker, String key) =>
        broker.ask(name: 'App', version: '1', publicKey: key, fingerprint: 'F');

    test('one open prompt per key and a bounded queue', () {
      final broker = PairingBroker(maxPending: 2, promptsPerMinute: 10);
      expect(broker.refusal('a'), isNull);
      ask(broker, 'a');
      expect(broker.refusal('a'), 'pairing_pending');
      ask(broker, 'b');
      expect(broker.refusal('c'), 'rate_limited');
    });

    test('limits prompts per key and per minute', () async {
      final broker = PairingBroker(promptsPerMinute: 2);
      final ids = <String>[];
      broker.requests.listen((request) => ids.add(request.id));
      ask(broker, 'a');
      await Future<void>.delayed(Duration.zero);
      broker.resolve(ids.single, false);
      expect(broker.refusal('a'), 'rate_limited');
      ask(broker, 'b');
      expect(broker.refusal('c'), 'rate_limited');
    });

    test('an unanswered prompt times out and is cancelled', () async {
      final broker = PairingBroker(timeout: const Duration(milliseconds: 20));
      final cancelled = <String>[];
      final requests = <PairingRequest>[];
      broker.cancelled.listen(cancelled.add);
      broker.requests.listen(requests.add);
      expect(await ask(broker, 'a'), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(cancelled, [requests.single.id]);
      expect(broker.resolve(requests.single.id, true), isFalse);
    });
  });

  group('LocalApiCrypto', () {
    final peer = TestPeer.generate(7);
    const message = 'meshcore-open-pair-v1:nonce';

    test('verifies DER and raw signatures', () {
      expect(
        LocalApiCrypto.verify(
          peer.publicKeyRaw,
          message,
          peer.signDer(message),
        ),
        isTrue,
      );
      expect(
        LocalApiCrypto.verify(
          peer.publicKeyRaw,
          message,
          peer.signRaw(message),
        ),
        isTrue,
      );
      expect(
        LocalApiCrypto.verify(
          peer.publicKeyRaw,
          'other',
          peer.signDer(message),
        ),
        isFalse,
      );
    });

    test('rejects DER with trailing or padded bytes', () {
      final der = TestPeer.derSignature(peer.sign(message));
      expect(LocalApiCrypto.parseDerSignature(der), isNotNull);

      final trailing = Uint8List.fromList([...der, 0]);
      expect(LocalApiCrypto.parseDerSignature(trailing), isNull);
      // Even with the outer length adjusted to cover the extra byte.
      trailing[1] = trailing[1] + 1;
      expect(LocalApiCrypto.parseDerSignature(trailing), isNull);
      expect(
        LocalApiCrypto.verify(
          peer.publicKeyRaw,
          message,
          base64Encode(trailing),
        ),
        isFalse,
      );

      // A redundant leading zero on r.
      final rLength = der[3];
      final padded = Uint8List.fromList([
        0x30,
        der[1] + 1,
        0x02,
        rLength + 1,
        0,
        ...der.sublist(4),
      ]);
      expect(LocalApiCrypto.parseDerSignature(padded), isNull);
    });

    test('accepts only public keys on P-256', () {
      expect(LocalApiCrypto.decodePublicKey(peer.publicKeyBase64), isNotNull);
      final offCurve = peer.publicKeyRaw..[63] ^= 1;
      expect(LocalApiCrypto.decodePublicKey(base64Encode(offCurve)), isNull);
      expect(LocalApiCrypto.decodePublicKey(base64Encode([1, 2, 3])), isNull);
      expect(LocalApiCrypto.decodePublicKey('not base64!'), isNull);
    });
  });
}
