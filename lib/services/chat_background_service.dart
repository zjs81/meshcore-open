import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';

import '../models/channel.dart';
import '../models/chat_background.dart';
import '../models/contact.dart';
import '../models/custom_theme.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';
import 'app_settings_service.dart';
import 'chat_background_image_store.dart';

/// Chat backgrounds: one per channel or DM, plus the active theme's.
///
/// A chat's own background wins over the theme's, unless the theme turns on
/// [CustomTheme.chatBackgroundEverywhere]. Settings are global (not per
/// radio): channels are keyed by their PSK-derived storage ID and DMs by the
/// contact's public key, both of which identify the chat on any radio.
class ChatBackgroundService extends ChangeNotifier {
  static const _prefsKey = 'chat_backgrounds_v1';

  /// Longest side of a stored picture, in pixels.
  static const int maxImageSide = 1080;

  /// JPEG XL lossy "distance" (cjxl-style; 1 is visually lossless). A chat
  /// background is shown faded behind messages, so 2 keeps it sharp at a
  /// fraction of the size.
  static const double jxlDistance = 2.0;

  final AppSettingsService _settings;
  final ChatBackgroundImageStore _images;
  final Map<String, ChatBackground> _byChat = {};
  final Map<String, Uint8List> _imageCache = {};
  final Set<String> _loading = {};

  ChatBackgroundService(this._settings, {ChatBackgroundImageStore? imageStore})
    : _images = imageStore ?? createChatBackgroundImageStore() {
    _load();
    _settings.addListener(notifyListeners);
  }

  static String channelKey(Channel channel) =>
      'channel:${channel.storageId ?? 'slot${channel.index}'}';

  static String contactKey(Contact contact) =>
      'contact:${contact.publicKeyHex}';

  void _load() {
    final raw = PrefsManager.instance.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        final background = ChatBackground.fromJson(value);
        if (key is! String || background == null) return;
        if (background.color != null || background.imageId != null) {
          _byChat[key] = background;
        }
      });
    } catch (e) {
      appLogger.warn('Could not read chat backgrounds: $e');
    }
  }

  Future<void> _save() async {
    await PrefsManager.instance.setString(
      _prefsKey,
      jsonEncode(_byChat.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }

  /// The background this chat has been given itself (ignoring the theme).
  ChatBackground? chatBackground(String chatKey) => _byChat[chatKey];

  /// The theme background that will override [chatKey]'s own, if any.
  CustomTheme? get overridingTheme {
    final theme = _settings.activeCustomTheme;
    if (theme?.chatBackground == null || !theme!.chatBackgroundEverywhere) {
      return null;
    }
    return theme;
  }

  /// What to draw behind [chatKey]'s messages, or null for none.
  ChatBackground? resolve(String chatKey) {
    final theme = _settings.activeCustomTheme;
    final themed = theme?.chatBackground;
    if (themed != null && theme!.chatBackgroundEverywhere) return themed;
    return _byChat[chatKey] ?? themed;
  }

  Future<void> setChatBackground(
    String chatKey,
    ChatBackground? background,
  ) async {
    if (background == null) {
      _byChat.remove(chatKey);
    } else {
      _byChat[chatKey] = background;
    }
    notifyListeners();
    await _save();
  }

  /// Cached picture bytes, or null while they load (listeners are notified
  /// once they arrive).
  Uint8List? imageBytes(String imageId) {
    final cached = _imageCache[imageId];
    if (cached != null) return cached;
    if (_loading.add(imageId)) {
      unawaited(
        _images.read(imageId).then((bytes) {
          _loading.remove(imageId);
          if (bytes == null) return;
          _imageCache[imageId] = bytes;
          notifyListeners();
        }),
      );
    }
    return null;
  }

  /// Shrinks a picture (any format Flutter or JPEG XL decodes), re-encodes
  /// it as JPEG XL and stores it. Returns its ID, or null when [bytes] is not
  /// a readable image.
  Future<String?> addImage(Uint8List bytes) async {
    final jxl = await encodeChatBackgroundJxl(bytes);
    if (jxl == null) return null;
    final id = crypto.sha256.convert(jxl).toString().substring(0, 20);
    _imageCache[id] = jxl;
    await _images.write(id, jxl);
    return id;
  }

  /// Writes any picture carried inline by [theme] (from a share code or
  /// file) to the image store, so the theme can be saved in settings.
  Future<CustomTheme> storeThemeImages(CustomTheme theme) async {
    final background = theme.chatBackground;
    final inline = background?.inlineImage;
    if (background == null || inline == null) return theme;
    // Re-encode untrusted input rather than storing it verbatim.
    final id = await addImage(inline);
    return id == null
        ? theme.copyWith(chatBackground: null)
        : theme.copyWith(chatBackground: background.withStoredImage(id));
  }

  /// Attaches the picture bytes to [theme] so its share code or file
  /// carries the picture.
  Future<CustomTheme> embedThemeImages(CustomTheme theme) async {
    final background = theme.chatBackground;
    final id = background?.imageId;
    if (background == null || id == null) return theme;
    final bytes = _imageCache[id] ?? await _images.read(id);
    if (bytes == null) return theme;
    return theme.copyWith(chatBackground: background.withInlineImage(bytes));
  }

  /// Deletes stored pictures no chat or saved theme uses any more.
  Future<void> collectGarbage() async {
    final inUse = <String>{
      for (final background in _byChat.values)
        if (background.imageId != null) background.imageId!,
      for (final theme in _settings.settings.customThemes)
        if (theme.chatBackground?.imageId != null)
          theme.chatBackground!.imageId!,
    };
    try {
      for (final id in await _images.listIds()) {
        if (inUse.contains(id)) continue;
        await _images.delete(id);
        _imageCache.remove(id);
      }
    } catch (e) {
      appLogger.warn('Chat background cleanup failed: $e');
    }
  }

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Decodes [bytes], shrinks the picture to fit
/// [ChatBackgroundService.maxImageSide] and encodes it as lossy JPEG XL.
/// Returns null for unreadable input.
///
/// Non-JXL input goes through Flutter's decoder, which also applies a
/// photo's EXIF rotation.
Future<Uint8List?> encodeChatBackgroundJxl(Uint8List bytes) async {
  const maxSide = ChatBackgroundService.maxImageSide;
  ui.Image? image;
  try {
    if (looksLikeJxl(bytes)) {
      image = await decodeJxlToUiImage(
        bytes,
        cacheWidth: maxSide,
        cacheHeight: maxSide,
      );
    } else {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (width, height) {
          final longest = width > height ? width : height;
          if (longest <= maxSide) {
            return ui.TargetImageSize(width: width, height: height);
          }
          final scale = maxSide / longest;
          return ui.TargetImageSize(
            width: (width * scale).round().clamp(1, maxSide),
            height: (height * scale).round().clamp(1, maxSide),
          );
        },
      );
      image = (await codec.getNextFrame()).image;
      codec.dispose();
    }
    return await encodeJxlLossyFromUiImage(
      image,
      distance: ChatBackgroundService.jxlDistance,
    );
  } catch (e) {
    appLogger.warn('Could not encode chat background: $e');
    return null;
  } finally {
    image?.dispose();
  }
}
