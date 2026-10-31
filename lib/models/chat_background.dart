import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../theme/theme_icons.dart' show isThemeAssetPath;
import 'custom_theme.dart';

/// Background drawn behind a chat's messages: a color or a picture.
///
/// [fade] blends the theme's normal background over it (0 = full strength,
/// 1 = invisible) so text drawn outside bubbles stays readable.
@immutable
class ChatBackground {
  static const double defaultFade = 0.4;
  static const double minFade = 0.1;
  static const double maxFade = 0.9;

  final Color? color;

  /// ID of a picture in the chat background image store.
  final String? imageId;

  /// Picture bytes carried inside a share code or `.jsonl` file, before it
  /// has been written to the image store. Never persisted in settings.
  final Uint8List? inlineImage;

  /// A JPEG XL picture bundled with the app (built-in themes).
  final String? asset;

  final double fade;

  const ChatBackground.color(Color this.color, {this.fade = defaultFade})
    : imageId = null,
      inlineImage = null,
      asset = null;

  const ChatBackground.image(String this.imageId, {this.fade = defaultFade})
    : color = null,
      inlineImage = null,
      asset = null;

  const ChatBackground.asset(String this.asset, {this.fade = defaultFade})
    : color = null,
      imageId = null,
      inlineImage = null;

  const ChatBackground._({
    this.color,
    this.imageId,
    this.inlineImage,
    this.asset,
    required this.fade,
  });

  bool get isImage => imageId != null || inlineImage != null || asset != null;

  ChatBackground withFade(double value) => ChatBackground._(
    color: color,
    imageId: imageId,
    inlineImage: inlineImage,
    asset: asset,
    fade: value.clamp(minFade, maxFade).toDouble(),
  );

  /// A copy whose picture lives in the image store under [id].
  ChatBackground withStoredImage(String id) =>
      ChatBackground._(imageId: id, fade: fade);

  /// A copy carrying the picture bytes for sharing.
  ChatBackground withInlineImage(Uint8List bytes) =>
      ChatBackground._(imageId: imageId, inlineImage: bytes, fade: fade);

  /// Storage form: a color or an image-store ID.
  Map<String, dynamic> toJson() => {
    if (color != null) 'color': colorToHex(color!),
    if (imageId != null) 'image': imageId,
    if (asset != null) 'asset': asset,
    'fade': fade,
  };

  /// Sharing form: a color or the picture itself. Null when this is a
  /// picture whose bytes were not attached.
  Map<String, dynamic>? toShareJson() {
    if (color != null) return {'color': colorToHex(color!), 'fade': fade};
    // Bundled pictures exist in every install, so the path is enough.
    if (asset != null) return {'asset': asset, 'fade': fade};
    if (inlineImage != null) {
      return {'imageData': base64Encode(inlineImage!), 'fade': fade};
    }
    return null;
  }

  static ChatBackground? fromJson(Object? json) {
    if (json is! Map) return null;
    final rawFade = json['fade'];
    final fade = (rawFade is num ? rawFade.toDouble() : defaultFade)
        .clamp(minFade, maxFade)
        .toDouble();
    final color = parseHexColor(json['color']);
    if (color != null) return ChatBackground.color(color, fade: fade);
    final asset = json['asset'];
    if (isThemeAssetPath(asset)) {
      return ChatBackground.asset(asset as String, fade: fade);
    }
    final imageId = json['image'];
    if (imageId is String && imageId.isNotEmpty) {
      return ChatBackground.image(imageId, fade: fade);
    }
    final data = json['imageData'];
    if (data is String && data.isNotEmpty) {
      try {
        return ChatBackground._(inlineImage: base64Decode(data), fade: fade);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ChatBackground &&
      other.color == color &&
      other.imageId == imageId &&
      other.asset == asset &&
      other.fade == fade &&
      identical(other.inlineImage, inlineImage);

  @override
  int get hashCode => Object.hash(color, imageId, asset, fade, inlineImage);
}
