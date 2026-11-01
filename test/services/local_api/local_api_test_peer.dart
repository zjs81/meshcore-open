import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// A client key pair, signing the way the Android client does.
class TestPeer {
  final ECPrivateKey _private;
  final ECPublicKey _public;

  TestPeer._(this._private, this._public);

  static TestPeer generate(int seed) {
    final random = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(List.filled(32, seed))));
    final generator = ECKeyGenerator()
      ..init(
        ParametersWithRandom(
          ECKeyGeneratorParameters(ECCurve_secp256r1()),
          random,
        ),
      );
    final pair = generator.generateKeyPair();
    return TestPeer._(pair.privateKey, pair.publicKey);
  }

  Uint8List get publicKeyRaw {
    final q = _public.Q!;
    return Uint8List.fromList([
      ..._fixed(q.x!.toBigInteger()!),
      ..._fixed(q.y!.toBigInteger()!),
    ]);
  }

  String get publicKeyBase64 => base64Encode(publicKeyRaw);

  ECSignature sign(String message) {
    final random = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(List.filled(32, 9))));
    final signer = ECDSASigner(SHA256Digest())
      ..init(
        true,
        ParametersWithRandom(
          PrivateKeyParameter<ECPrivateKey>(_private),
          random,
        ),
      );
    return signer.generateSignature(utf8.encode(message)) as ECSignature;
  }

  /// Raw `r||s`, 32 bytes each.
  String signRaw(String message) {
    final signature = sign(message);
    return base64Encode([..._fixed(signature.r), ..._fixed(signature.s)]);
  }

  /// DER, as `Signature.getInstance("SHA256withECDSA")` returns it.
  String signDer(String message) => base64Encode(derSignature(sign(message)));

  static Uint8List derSignature(ECSignature signature) {
    List<int> integer(BigInt value) {
      var bytes = _fixed(value).toList();
      while (bytes.length > 1 && bytes[0] == 0) {
        bytes = bytes.sublist(1);
      }
      if (bytes[0] & 0x80 != 0) bytes = [0, ...bytes];
      return [0x02, bytes.length, ...bytes];
    }

    final body = [...integer(signature.r), ...integer(signature.s)];
    return Uint8List.fromList([0x30, body.length, ...body]);
  }

  static Uint8List _fixed(BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(
      List<int>.generate(
        32,
        (index) =>
            int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
      ),
    );
  }
}
