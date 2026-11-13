import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Advert payload layout (MeshCore `Mesh::createAdvert`):
/// `[pub_key 32][timestamp u32 LE][signature 64][app_data …]`.
const int _pubKeyLen = 32;
const int _timestampLen = 4;
const int _signatureLen = 64;
const int advertSignedHeaderLen = _pubKeyLen + _timestampLen + _signatureLen;

final Ed25519 _ed25519 = Ed25519();

/// Verified results keyed by signature, so the same advert heard over
/// several paths is only checked once.
final Map<String, bool> _verifiedCache = <String, bool>{};
const int _verifiedCacheMax = 256;

/// Returns true when [payload] is an advert whose Ed25519 signature over
/// `pub_key || timestamp || app_data` verifies against its own public key.
/// Applies to every advert type (chat, repeater, room, sensor).
Future<bool> verifyAdvertSignature(Uint8List payload) async {
  if (payload.length < advertSignedHeaderLen) return false;

  final publicKey = Uint8List.sublistView(payload, 0, _pubKeyLen);
  final timestamp = Uint8List.sublistView(
    payload,
    _pubKeyLen,
    _pubKeyLen + _timestampLen,
  );
  final signature = Uint8List.sublistView(
    payload,
    _pubKeyLen + _timestampLen,
    advertSignedHeaderLen,
  );
  final appData = Uint8List.sublistView(payload, advertSignedHeaderLen);

  final cacheKey =
      String.fromCharCodes(publicKey) + String.fromCharCodes(signature);
  final cached = _verifiedCache[cacheKey];
  if (cached != null) return cached;

  final message = Uint8List(_pubKeyLen + _timestampLen + appData.length)
    ..setRange(0, _pubKeyLen, publicKey)
    ..setRange(_pubKeyLen, _pubKeyLen + _timestampLen, timestamp)
    ..setRange(
      _pubKeyLen + _timestampLen,
      _pubKeyLen + _timestampLen + appData.length,
      appData,
    );

  bool valid;
  try {
    valid = await _ed25519.verify(
      message,
      signature: Signature(
        Uint8List.fromList(signature),
        publicKey: SimplePublicKey(
          Uint8List.fromList(publicKey),
          type: KeyPairType.ed25519,
        ),
      ),
    );
  } catch (_) {
    valid = false;
  }

  if (_verifiedCache.length >= _verifiedCacheMax) {
    _verifiedCache.remove(_verifiedCache.keys.first);
  }
  _verifiedCache[cacheKey] = valid;
  return valid;
}
