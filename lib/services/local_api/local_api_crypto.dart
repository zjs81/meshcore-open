import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/ecc/ecc_fp.dart' as fp;
import 'package:pointycastle/export.dart';

/// A P-256 client identity: raw X||Y public key (64 bytes) plus an ECDSA
/// signature over a server nonce.
class LocalApiCrypto {
  static final ECCurve_secp256r1 _domain = ECCurve_secp256r1();

  static String newNonce() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return base64UrlEncode(bytes);
  }

  static String fingerprint(Uint8List publicKeyRaw) {
    final digest = SHA256Digest().process(publicKeyRaw);
    final hex = digest
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return '${hex.substring(0, 4)} ${hex.substring(4, 8)} '
        '${hex.substring(8, 12)} ${hex.substring(12, 16)}';
  }

  /// The raw key, or null unless [base64Value] is 64 bytes encoding a point
  /// on P-256.
  static Uint8List? decodePublicKey(String base64Value) {
    final Uint8List raw;
    try {
      raw = base64Decode(base64Value);
    } on FormatException {
      return null;
    }
    return _point(raw) == null ? null : raw;
  }

  /// `SHA256withECDSA` over [message]; the signature is DER (as produced by
  /// Java/Kotlin) or the raw 64-byte `r||s` form.
  static bool verify(
    Uint8List publicKeyRaw,
    String message,
    String signatureBase64,
  ) {
    final point = _point(publicKeyRaw);
    if (point == null) return false;
    final Uint8List bytes;
    try {
      bytes = base64Decode(signatureBase64);
    } on FormatException {
      return false;
    }
    final signature = bytes.length == 64
        ? ECSignature(
            _unsigned(bytes.sublist(0, 32)),
            _unsigned(bytes.sublist(32)),
          )
        : parseDerSignature(bytes);
    if (signature == null) return false;
    final n = _domain.n;
    if (signature.r <= BigInt.zero || signature.r >= n) return false;
    if (signature.s <= BigInt.zero || signature.s >= n) return false;

    final verifier = ECDSASigner(SHA256Digest())
      ..init(
        false,
        PublicKeyParameter<ECPublicKey>(ECPublicKey(point, _domain)),
      );
    return verifier.verifySignature(
      Uint8List.fromList(utf8.encode(message)),
      signature,
    );
  }

  /// Strict DER `SEQUENCE { INTEGER r, INTEGER s }` with nothing after it.
  static ECSignature? parseDerSignature(Uint8List der) {
    if (der.length < 8 || der[0] != 0x30 || der[1] != der.length - 2) {
      return null;
    }
    var offset = 2;
    BigInt? readInteger() {
      if (offset + 2 > der.length || der[offset] != 0x02) return null;
      final length = der[offset + 1];
      final start = offset + 2;
      if (length == 0 || length > 33 || start + length > der.length) {
        return null;
      }
      final value = der.sublist(start, start + length);
      // Positive and minimally encoded.
      if (value[0] & 0x80 != 0) return null;
      if (length > 1 && value[0] == 0 && value[1] & 0x80 == 0) return null;
      offset = start + length;
      return _unsigned(value);
    }

    final r = readInteger();
    final s = readInteger();
    if (r == null || s == null || offset != der.length) return null;
    return ECSignature(r, s);
  }

  static ECPoint? _point(Uint8List raw) {
    if (raw.length != 64) return null;
    final x = _unsigned(raw.sublist(0, 32));
    final y = _unsigned(raw.sublist(32));
    final curve = _domain.curve as fp.ECCurve;
    final p = curve.q!;
    if (x >= p || y >= p) return null;
    final a = curve.a!.toBigInteger()!;
    final b = curve.b!.toBigInteger()!;
    if ((y * y - (x * x * x + a * x + b)) % p != BigInt.zero) return null;
    return curve.createPoint(x, y);
  }

  static BigInt _unsigned(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}
