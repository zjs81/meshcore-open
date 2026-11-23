import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A one-way hash chain used to authenticate a player's actions without
/// 64-byte signatures.
///
/// `v[length] = seed` and `v[i] = H(v[i + 1])`, where H is SHA-256 cut to
/// [valueBytes]. The player publishes `v[0]` (the commitment) when joining a
/// game and reveals `v[1]`, `v[2]`, … with each later action. Anyone holding
/// an earlier value can check a new one by hashing it forward, but only the
/// seed holder can produce the next one.
class HashChain {
  static const int length = 512;
  static const int valueBytes = 16;

  final Uint8List seed;

  HashChain(this.seed) : assert(seed.length == valueBytes);

  factory HashChain.generate([Random? random]) {
    final rng = random ?? Random.secure();
    return HashChain(
      Uint8List.fromList(List.generate(valueBytes, (_) => rng.nextInt(256))),
    );
  }

  /// `v[index]`, for `0 <= index <= length`.
  Uint8List valueAt(int index) {
    RangeError.checkValueInInterval(index, 0, length, 'index');
    var v = seed;
    for (var i = length; i > index; i--) {
      v = hashChainStep(v);
    }
    return v;
  }

  Uint8List get commitment => valueAt(0);
}

/// One step towards the commitment: SHA-256 cut to [HashChain.valueBytes].
Uint8List hashChainStep(Uint8List value) =>
    Uint8List.fromList(sha256.convert(value).bytes.sublist(0, 16));

/// How many chain steps [candidate] lies beyond [lastVerified]: 0 when it is
/// the same value (a duplicate), a positive count when hashing it forward
/// that many times reaches [lastVerified], or null when it is not on the
/// chain within [maxSteps] (forged, or older than [lastVerified]).
int? hashChainDistance(
  Uint8List candidate,
  Uint8List lastVerified, {
  int maxSteps = HashChain.length,
}) {
  if (candidate.length != HashChain.valueBytes) return null;
  if (bytesEqual(candidate, lastVerified)) return 0;
  var v = candidate;
  for (var steps = 1; steps <= maxSteps; steps++) {
    v = hashChainStep(v);
    if (bytesEqual(v, lastVerified)) return steps;
  }
  return null;
}

bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
