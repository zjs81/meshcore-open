import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/local_api/local_api_crypto.dart';
import 'package:meshcore_open/services/local_api/local_api_host.dart';
import 'package:meshcore_open/services/local_api/local_api_server.dart';

/// The shared conformance vectors of the MeshCore Local API
/// (https://github.com/jooray/meshcore-local-api, vectors/), copied here.
Map<String, dynamic> _load(String name) =>
    jsonDecode(
          File('test/services/local_api/vectors/$name.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  group('pairing vectors', () {
    final vectors = _load('pairing');
    final testKey = vectors['testKey'] as Map<String, dynamic>;
    final raw = LocalApiCrypto.decodePublicKey(testKey['publicKey'] as String)!;
    final other = LocalApiCrypto.decodePublicKey(
      vectors['otherKey']['publicKey'] as String,
    )!;

    test('fingerprint', () {
      expect(LocalApiCrypto.fingerprint(raw), testKey['fingerprint']);
    });

    test('valid signatures verify in every encoding, only for their key', () {
      for (final entry in vectors['validSignatures'] as List) {
        final message = entry['message'] as String;
        expect(
          message,
          '${LocalApiServer.pairingMessagePrefix}${entry['nonce']}',
        );
        for (final form in [
          'derBase64',
          'rawBase64',
          'highSDerBase64',
          'highSRawBase64',
        ]) {
          final signature = entry[form] as String;
          expect(LocalApiCrypto.verify(raw, message, signature), isTrue);
          expect(LocalApiCrypto.verify(other, message, signature), isFalse);
        }
      }
    });

    test('invalid signatures fail', () {
      final invalid = vectors['invalidSignatures'] as Map<String, dynamic>;
      for (final entry in invalid['cases'] as List) {
        expect(
          LocalApiCrypto.verify(
            raw,
            invalid['message'] as String,
            entry['signatureBase64'] as String,
          ),
          isFalse,
          reason: entry['why'] as String,
        );
      }
    });

    test('invalid public keys are refused', () {
      for (final entry in vectors['invalidPublicKeys'] as List) {
        expect(
          LocalApiCrypto.decodePublicKey(entry['publicKey'] as String),
          isNull,
          reason: entry['why'] as String,
        );
      }
    });

    test('server nonces have the required shape', () {
      final shape = RegExp(vectors['nonceShape']['regex'] as String);
      for (var i = 0; i < 20; i++) {
        expect(shape.hasMatch(LocalApiCrypto.newNonce()), isTrue);
      }
    });
  });

  group('validator vectors', () {
    final vectors = _load('validators');

    test('since', () {
      for (final entry in vectors['since']['cases'] as List) {
        final parsed = LocalApiValidation.parseSince(entry['since']);
        final reason = jsonEncode(entry['since']);
        if (entry.containsKey('error')) {
          expect(parsed, isNull, reason: reason);
        } else {
          expect(
            parsed?.millisecondsSinceEpoch,
            entry['epochMs'],
            reason: reason,
          );
        }
      }
    });

    test('client identity', () {
      for (final entry in vectors['clientIdentity']['cases'] as List) {
        final name = LocalApiValidation.clientName(entry['name']);
        final ok =
            name != null &&
            LocalApiValidation.isClientVersion(entry['version']);
        final reason = jsonEncode(entry);
        expect(ok, entry['expect'] == 'ok', reason: reason);
        if (entry.containsKey('storedName')) {
          expect(name, entry['storedName'], reason: reason);
        }
      }
    });
  });

  group('matchPubkey', () {
    final keys = [
      'ab' * 32,
      'abcdef012345${'0' * 52}',
      'abcdef012345${'1' * 52}',
    ];
    String? match(String query) => matchPubkey(keys, (key) => key, query);

    test('compares case-insensitively', () {
      expect(match('AB' * 32), 'ab' * 32);
    });

    test('takes a unique prefix of at least 12 characters', () {
      expect(match('abcdef0123450'), keys[1]);
      expect(match('ABCDEF0123451'), keys[2]);
      expect(match('abcdef012345'), isNull); // two match
      expect(match('ababab'), isNull); // too short
      expect(match('not hex'), isNull);
    });
  });
}
