import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:meshcore_open/utils/keys.dart';

import 'channel.dart';

/// Represents a community with a shared secret for deriving channel PSKs.
///
/// A Community is a namespace with a shared secret K (32 random bytes),
/// distributed via QR code. Members can create Community Public Channels
/// and Community Hashtag Channels that are opaque to outsiders.
class Community {
  /// Unique identifier for local storage
  final String id;

  /// Display name for the community
  final String name;

  /// The 32-byte shared secret (K)
  final Uint8List secret;

  /// Timestamp when the community was created/joined
  final DateTime createdAt;

  /// List of hashtag channel names (without #) that have been added
  final List<String> hashtagChannels;

  Community({
    required this.id,
    required this.name,
    required this.secret,
    required this.createdAt,
    List<String>? hashtagChannels,
  }) : hashtagChannels = hashtagChannels ?? [];

  /// Generate a new community with a random 32-byte secret
  factory Community.create({required String id, required String name}) {
    final secret = randomBytes(32);
    return Community(
      id: id,
      name: name,
      secret: secret,
      createdAt: DateTime.now(),
    );
  }

  /// Parse a community from QR code JSON data
  factory Community.fromQrData(String id, String qrData) {
    final json = jsonDecode(qrData) as Map<String, dynamic>;
    if (json['type'] != 'meshcore_community') {
      throw const FormatException('Invalid QR code type');
    }
    if (json['v'] != 1) {
      throw const FormatException('Unsupported QR code version');
    }

    final name = json['name'] as String;
    final secretBase64 = json['k'] as String;
    final secret = base64Url.decode(secretBase64);

    if (secret.length != 32) {
      throw const FormatException('Invalid secret length');
    }

    return Community(
      id: id,
      name: name,
      secret: Uint8List.fromList(secret),
      createdAt: DateTime.now(),
    );
  }

  /// Parse a community from storage JSON
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      secret: base64Decode(json['secret'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      hashtagChannels:
          (json['hashtag_channels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'secret': base64Encode(secret),
      'created_at': createdAt.millisecondsSinceEpoch,
      'hashtag_channels': hashtagChannels,
    };
  }

  /// Generate QR code JSON payload for sharing
  String toQrJson() {
    return jsonEncode({
      'v': 1,
      'type': 'meshcore_community',
      'name': name,
      'k': base64Url.encode(secret),
    });
  }

  /// Derive the public Community ID from the secret.
  /// This is safe to display/log since it's one-way derived.
  /// CID = SHA256("community:v1" || K)
  String get communityId {
    final data = utf8.encode('community:v1') + secret;
    final hash = crypto.sha256.convert(data).bytes;
    return _bytesToHex(Uint8List.fromList(hash));
  }

  /// Short version of community ID for display (first 8 chars)
  String get shortCommunityId => communityId.substring(0, 8);

  /// Derive PSK for community public channel.
  /// PSK = HMAC-SHA256(K, "channel:v1:__public__")[:16]
  Uint8List deriveCommunityPublicPsk() {
    final hmac = crypto.Hmac(crypto.sha256, secret);
    final digest = hmac.convert(utf8.encode('channel:v1:__public__'));
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  /// Derive PSK for community hashtag channel.
  /// PSK = HMAC-SHA256(K, "channel:v1:" + normalized_name)[:16]
  Uint8List deriveCommunityHashtagPsk(String hashtag) {
    final normalized = _normalizeCommunityHashtag(hashtag);
    final hmac = crypto.Hmac(crypto.sha256, secret);
    final digest = hmac.convert(utf8.encode('channel:v1:$normalized'));
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  /// Check if QR data is valid community data
  static bool isValidQrData(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      if (json['type'] != 'meshcore_community') return false;
      if (json['v'] != 1) return false;
      if (json['name'] == null || (json['name'] as String).isEmpty) {
        return false;
      }
      if (json['k'] == null) return false;
      final secret = base64Url.decode(json['k'] as String);
      return secret.length == 32;
    } catch (_) {
      return false;
    }
  }

  /// Normalize a hashtag name for consistent PSK derivation.
  /// Strips leading #, converts to lowercase, trims whitespace.
  static String _normalizeCommunityHashtag(String hashtag) {
    return hashtag.replaceFirst(RegExp(r'^#'), '').toLowerCase().trim();
  }

  /// Returns true if this is the community's public channel
  static bool isCommunityPublicChannel(Channel channel, Community community) {
    final publicPsk = community.deriveCommunityPublicPsk();
    return channel.pskHex == Channel.formatPskHex(publicPsk);
  }

  /// Add a hashtag channel to this community's list
  Community addHashtagChannel(String hashtag) {
    final normalized = _normalizeCommunityHashtag(hashtag);
    if (hashtagChannels.contains(normalized)) {
      return this;
    }
    return Community(
      id: id,
      name: name,
      secret: secret,
      createdAt: createdAt,
      hashtagChannels: [...hashtagChannels, normalized],
    );
  }

  /// Remove a hashtag channel from this community's list
  Community removeHashtagChannel(String hashtag) {
    final normalized = _normalizeCommunityHashtag(hashtag);
    return Community(
      id: id,
      name: name,
      secret: secret,
      createdAt: createdAt,
      hashtagChannels: hashtagChannels.where((h) => h != normalized).toList(),
    );
  }

  /// Create a copy of this community with a new secret
  Community withNewSecret(Uint8List newSecret) {
    return Community(
      id: id,
      name: name,
      secret: newSecret,
      createdAt: createdAt,
      hashtagChannels: hashtagChannels,
    );
  }

  /// Create a copy of this community with a regenerated random secret
  Community withRegeneratedSecret() {
    return withNewSecret(randomBytes(32));
  }

  /// Extract secret from QR data (for updating existing community)
  static Uint8List? extractSecretFromQrData(String qrData) {
    try {
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      if (json['type'] != 'meshcore_community') return null;
      if (json['v'] != 1) return null;
      final secretBase64 = json['k'] as String;
      final secret = base64Url.decode(secretBase64);
      if (secret.length != 32) return null;
      return Uint8List.fromList(secret);
    } catch (_) {
      return null;
    }
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Community && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CommunityPskIndex {
  // Cache of PSK hex -> Community for quick lookup
  final Map<String, Community> _pskToCommunity = {};

  void initialize(List<Community> communities) {
    _pskToCommunity.clear();
    for (final community in communities) {
      // Map the community public channel PSK
      final publicPsk = community.deriveCommunityPublicPsk();
      _pskToCommunity[Channel.formatPskHex(publicPsk)] = community;

      // Map all known hashtag channel PSKs
      for (final hashtag in community.hashtagChannels) {
        final hashtagPsk = community.deriveCommunityHashtagPsk(hashtag);
        _pskToCommunity[Channel.formatPskHex(hashtagPsk)] = community;
      }
    }
  }

  /// Returns the community this channel belongs to, or null if not a community channel
  Community? getCommunityForChannel(Channel channel) {
    return _pskToCommunity[channel.pskHex];
  }
}
