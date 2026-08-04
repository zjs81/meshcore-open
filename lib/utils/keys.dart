import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';

Uint8List randomBytes(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

class MCKeyPair {
  final Uint8List public;
  final Uint8List private;
  MCKeyPair(this.public, this.private);
}

Future<MCKeyPair> generateKeyPair() async {
  final algo = Ed25519();
  final seed = randomBytes(32);
  final SimpleKeyPair keys = await algo.newKeyPairFromSeed(seed);
  final Uint8List pubKeyBytes = Uint8List.fromList(
    (await keys.extractPublicKey()).bytes,
  );
  // Ed25519 gives 32-byte public and private keys, but MeshCore
  // uses an expanded 64-byte private key, so we have to make it
  // ourselves. Luckily, we can do it such that it has the same public
  // key, which we'd otherwise be unable to compute, since although the
  // crypto library implements the elliptic curve computations we need,
  // it doesn't make them available.
  final Uint8List hash = Uint8List.fromList((await Sha512().hash(seed)).bytes);
  hash[0] &= 248; // Clamp the scalar. This keeps the chosen point in the
  hash[31] &= 63; // large elliptic curve subgroup, and is demanded both by
  hash[31] |= 64; // Ed25519 and by the MeshCore repeater key validation code.
  return MCKeyPair(pubKeyBytes, hash);
}

class _KeyHashPrefix {
  Uint8List _bytes = Uint8List(0);
  Uint8List _mask = Uint8List(0);
  _KeyHashPrefix(String prefix) {
    final bool lengthIsOdd = (prefix.length % 2 == 1) ? true : false;
    final String decodableString = lengthIsOdd ? "${prefix}0" : prefix;
    _bytes = hex.decoder.convert(decodableString);
    _mask = Uint8List(_bytes.length);
    for (var i = 0; i < _mask.length; i++) {
      _mask[i] = 0xff;
    }
    if (lengthIsOdd) {
      _mask[_mask.length - 1] = 0xf0;
    }
  }

  bool matches(List<int> keyBytes) {
    if (keyBytes.length < _bytes.length) {
      return false;
    }
    for (var i = 0; i < _bytes.length; i++) {
      if (keyBytes[i] & _mask[i] != _bytes[i]) {
        return false;
      }
    }
    return true;
  }
}

class KeyPairSearcher {
  Future<MCKeyPair?> findMatchingKeyPair(
    String prefixStr,
    int maxMilliseconds,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int endTime = now + maxMilliseconds;
    final _KeyHashPrefix keyHashPrefix = _KeyHashPrefix(prefixStr);
    while (DateTime.now().millisecondsSinceEpoch < endTime) {
      final MCKeyPair keys = await generateKeyPair();
      if (keyHashPrefix.matches(keys.public)) {
        return keys;
      }
    }
    return null;
  }
}
