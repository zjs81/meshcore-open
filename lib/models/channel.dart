import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../connector/meshcore_protocol.dart';

class Channel {
  final int index;
  final String name;
  final Uint8List psk; // 16 bytes
  int unreadCount;

  Channel({
    required this.index,
    required this.name,
    required this.psk,
    this.unreadCount = 0,
  });

  String get pskHex => _bytesToHex(psk);

  bool get isEmpty => name.isEmpty && psk.every((b) => b == 0);

  bool get isPublicChannel => pskHex == publicChannelPsk;

  static Channel? fromFrame(Uint8List frame) {
    // CHANNEL_INFO format:
    // [0] = RESP_CODE_CHANNEL_INFO (18)
    // [1] = channel_idx
    // [2-33] = name (32 bytes, null-terminated)
    // [34-49] = psk (16 bytes)
    if (frame.length < 50) return null;
    final reader = BufferReader(frame);
    try {
      if (reader.readByte() != respCodeChannelInfo) return null;
      final index = reader.readByte();
      final name = reader.readCStringGreedy(32);
      final psk = reader.readBytes(16);
      return Channel(index: index, name: name, psk: psk);
    } catch (e) {
      return null;
    }
  }

  static Channel empty(int index) {
    return Channel(index: index, name: '', psk: Uint8List(16));
  }

  static Channel fromHex(int index, String name, String pskHex) {
    final psk = parsePskHex(pskHex);
    return Channel(index: index, name: name, psk: psk);
  }

  static Uint8List parsePskHex(String hex) {
    final cleaned = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.length != 32) {
      throw const FormatException('PSK must be 32 hex characters');
    }
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      final start = i * 2;
      bytes[i] = int.parse(cleaned.substring(start, start + 2), radix: 16);
    }
    return bytes;
  }

  /// Derive PSK from hashtag name using SHA256.
  /// The hashtag is normalized to include '#' prefix.
  /// Returns first 16 bytes of SHA256 hash as PSK.
  static Uint8List derivePskFromHashtag(String hashtag) {
    final name = hashtag.startsWith('#') ? hashtag : '#$hashtag';
    final hash = crypto.sha256.convert(utf8.encode(name)).bytes;
    return Uint8List.fromList(hash.sublist(0, 16));
  }

  /// Derive PSK for community public channel using HMAC-SHA256.
  /// PSK = HMAC-SHA256(K, "channel:v1:__public__")[:16]
  ///
  /// This creates a channel that is "public" only to members who have
  /// the community secret. Outsiders see only opaque IDs.
  static Uint8List deriveCommunityPublicPsk(Uint8List secret) {
    final hmac = crypto.Hmac(crypto.sha256, secret);
    final digest = hmac.convert(utf8.encode('channel:v1:__public__'));
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  /// Derive PSK for community hashtag channel using HMAC-SHA256.
  /// PSK = HMAC-SHA256(K, "channel:v1:" + normalized_name)[:16]
  ///
  /// Community hashtag channels are deterministic for all members
  /// (same name => same id) but impossible to enumerate/guess without K.
  static Uint8List deriveCommunityHashtagPsk(Uint8List secret, String hashtag) {
    final normalized = _normalizeCommunityHashtag(hashtag);
    final hmac = crypto.Hmac(crypto.sha256, secret);
    final digest = hmac.convert(utf8.encode('channel:v1:$normalized'));
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  /// Normalize a hashtag name for consistent community PSK derivation.
  /// Strips leading #, converts to lowercase, trims whitespace.
  static String _normalizeCommunityHashtag(String hashtag) {
    return hashtag.replaceFirst(RegExp(r'^#'), '').toLowerCase().trim();
  }

  static String formatPskHex(Uint8List psk) {
    return _bytesToHex(psk);
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static const String publicChannelPsk = '8b3387e9c5cdea6ac9e5edbaa115cd72';
}
