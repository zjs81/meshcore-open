import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';

import '../connector/meshcore_protocol.dart';

/// The app icons a theme can replace. [key] is what themes store, so it must
/// never change once released.
enum ThemeIconSlot {
  contacts('contacts', Icons.people_outline, Icons.people),
  channels('channels', Icons.tag, Icons.tag),
  map('map', Icons.map_outlined, Icons.map),
  send('send', Icons.send, Icons.send),
  settings('settings', Icons.settings, Icons.settings),
  repeater('repeater', Icons.cell_tower, Icons.cell_tower),
  room('room', Icons.meeting_room, Icons.meeting_room),
  sensor('sensor', Icons.sensors, Icons.sensors),

  // Map markers.
  mapChat('map_chat', Icons.person, Icons.person),
  mapRepeater('map_repeater', Icons.router, Icons.router),
  mapRoom('map_room', Icons.meeting_room, Icons.meeting_room),
  mapSensor('map_sensor', Icons.sensors, Icons.sensors),
  mapSelf('map_self', Icons.person_pin_circle, Icons.person_pin_circle);

  /// Whether this slot is a marker on the map (grouped apart in the editor).
  bool get isMapMarker => key.startsWith('map_');

  /// The slot showing the same node type elsewhere: list avatar <-> map
  /// marker. Null when there is none.
  ThemeIconSlot? get partner => switch (this) {
    ThemeIconSlot.repeater => ThemeIconSlot.mapRepeater,
    ThemeIconSlot.room => ThemeIconSlot.mapRoom,
    ThemeIconSlot.sensor => ThemeIconSlot.mapSensor,
    ThemeIconSlot.mapRepeater => ThemeIconSlot.repeater,
    ThemeIconSlot.mapRoom => ThemeIconSlot.room,
    ThemeIconSlot.mapSensor => ThemeIconSlot.sensor,
    _ => null,
  };

  final String key;
  final IconData icon;

  /// Variant shown when the slot is selected (e.g. the active nav tab).
  final IconData selectedIcon;

  const ThemeIconSlot(this.key, this.icon, this.selectedIcon);
}

/// A theme's replacement for one [ThemeIconSlot]: either a named icon from
/// [kThemeIconCatalog] or a small picture (PNG, base64 in JSON).
@immutable
class ThemeIconOverride {
  /// Key in [kThemeIconCatalog].
  final String? icon;

  /// Base64-encoded picture (JPEG XL; older themes may hold PNG).
  final String? image;

  /// Decoded once so the image provider keeps hitting the same cache entry.
  final Uint8List? imageBytes;

  /// A JPEG XL picture bundled with the app (see [isThemeAssetPath]).
  final String? asset;

  const ThemeIconOverride.icon(String this.icon)
    : image = null,
      imageBytes = null,
      asset = null;

  ThemeIconOverride.image(Uint8List bytes)
    : icon = null,
      image = base64Encode(bytes),
      imageBytes = bytes,
      asset = null;

  const ThemeIconOverride.asset(String this.asset)
    : icon = null,
      image = null,
      imageBytes = null;

  const ThemeIconOverride._(this.icon, this.image, this.imageBytes)
    : asset = null;

  Map<String, dynamic> toJson() => image != null
      ? {'image': image}
      : asset != null
      ? {'asset': asset}
      : {'icon': icon};

  /// Returns null for unknown icon names or unreadable pictures, so a bad
  /// entry in a shared code falls back to the default icon.
  static ThemeIconOverride? fromJson(Object? json) {
    if (json is! Map) return null;
    final image = json['image'];
    if (image is String && image.isNotEmpty) {
      try {
        return ThemeIconOverride._(null, image, base64Decode(image));
      } on FormatException {
        return null;
      }
    }
    final asset = json['asset'];
    if (isThemeAssetPath(asset)) {
      return ThemeIconOverride.asset(asset as String);
    }
    final icon = json['icon'];
    if (icon is String && kThemeIconCatalog.containsKey(icon)) {
      return ThemeIconOverride.icon(icon);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeIconOverride &&
      other.icon == icon &&
      other.image == image &&
      other.asset == asset;

  @override
  int get hashCode => Object.hash(icon, image, asset);
}

/// The map marker slot for a node type, or null for unknown types.
ThemeIconSlot? mapMarkerSlotForNodeType(int type) {
  switch (type) {
    case advTypeChat:
      return ThemeIconSlot.mapChat;
    case advTypeRepeater:
      return ThemeIconSlot.mapRepeater;
    case advTypeRoom:
      return ThemeIconSlot.mapRoom;
    case advTypeSensor:
      return ThemeIconSlot.mapSensor;
    default:
      return null;
  }
}

/// Image provider for a picture override, or null for a named icon.
ImageProvider? themePictureOf(ThemeIconOverride? override) {
  final bytes = override?.imageBytes;
  if (bytes != null) return themePictureProvider(bytes);
  final asset = override?.asset;
  if (asset != null) return JxlImageProvider.asset(asset);
  return null;
}

/// Folder holding the pictures of the built-in themes.
const String kThemeAssetDir = 'assets/themes/';

/// Whether [value] names a bundled theme picture. Shared codes may only
/// point inside [kThemeAssetDir], and only at JPEG XL files.
bool isThemeAssetPath(Object? value) =>
    value is String &&
    value.startsWith(kThemeAssetDir) &&
    value.endsWith('.jxl') &&
    !value.contains('..');

/// Image provider for theme picture bytes: JPEG XL, or PNG/JPEG from themes
/// made before pictures were stored as JPEG XL.
ImageProvider themePictureProvider(Uint8List bytes) =>
    looksLikeJxl(bytes) ? JxlImageProvider.memory(bytes) : MemoryImage(bytes);

/// Parses a theme's `icons` JSON object, keeping only known slots.
Map<String, ThemeIconOverride> parseThemeIcons(Object? json) {
  if (json is! Map) return const {};
  final knownKeys = ThemeIconSlot.values.map((s) => s.key).toSet();
  final result = <String, ThemeIconOverride>{};
  json.forEach((key, value) {
    if (key is! String || !knownKeys.contains(key)) return;
    final override = ThemeIconOverride.fromJson(value);
    if (override != null) result[key] = override;
  });
  return result;
}

/// Icons offered in the picker, by the name themes store.
const Map<String, IconData> kThemeIconCatalog = {
  'people': Icons.people,
  'person': Icons.person,
  'groups': Icons.groups,
  'contacts': Icons.contacts,
  'forum': Icons.forum,
  'chat': Icons.chat,
  'chat_bubble': Icons.chat_bubble,
  'mail': Icons.mail,
  'tag': Icons.tag,
  'campaign': Icons.campaign,
  'podcasts': Icons.podcasts,
  'radio': Icons.radio,
  'map': Icons.map,
  'public': Icons.public,
  'explore': Icons.explore,
  'place': Icons.place,
  'near_me': Icons.near_me,
  'terrain': Icons.terrain,
  'send': Icons.send,
  'rocket_launch': Icons.rocket_launch,
  'arrow_upward': Icons.arrow_upward,
  'north_east': Icons.north_east,
  'flight': Icons.flight,
  'bolt': Icons.bolt,
  'settings': Icons.settings,
  'tune': Icons.tune,
  'build': Icons.build,
  'menu': Icons.menu,
  'cell_tower': Icons.cell_tower,
  'router': Icons.router,
  'wifi_tethering': Icons.wifi_tethering,
  'satellite_alt': Icons.satellite_alt,
  'meeting_room': Icons.meeting_room,
  'home': Icons.home,
  'cabin': Icons.cabin,
  'castle': Icons.castle,
  'sensors': Icons.sensors,
  'thermostat': Icons.thermostat,
  'water_drop': Icons.water_drop,
  'eco': Icons.eco,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'pets': Icons.pets,
  'hiking': Icons.hiking,
  'sailing': Icons.sailing,
  'anchor': Icons.anchor,
  'local_fire_department': Icons.local_fire_department,
  'shield': Icons.shield,
  'emoji_emotions': Icons.emoji_emotions,
  'auto_awesome': Icons.auto_awesome,
  'nightlight': Icons.nightlight,
  'wb_sunny': Icons.wb_sunny,
  'park': Icons.park,
  'diamond': Icons.diamond,
};

/// Icon overrides carried by the active theme.
@immutable
class MeshIconTheme extends ThemeExtension<MeshIconTheme> {
  final Map<String, ThemeIconOverride> overrides;

  const MeshIconTheme(this.overrides);

  static const none = MeshIconTheme({});

  static MeshIconTheme of(BuildContext context) =>
      Theme.of(context).extension<MeshIconTheme>() ?? none;

  /// The replacement for [slot]. A node type's list avatar and its map
  /// marker stand for the same thing, so when a theme sets only one of the
  /// pair the other uses it too.
  ThemeIconOverride? operator [](ThemeIconSlot slot) {
    final partner = slot.partner;
    return overrides[slot.key] ??
        (partner == null ? null : overrides[partner.key]);
  }

  /// Whether any of [slots] is replaced by a picture (drawn larger).
  bool hasPictureFor(Iterable<ThemeIconSlot> slots) => slots.any((slot) {
    final o = this[slot];
    return o?.imageBytes != null || o?.asset != null;
  });

  @override
  MeshIconTheme copyWith({Map<String, ThemeIconOverride>? overrides}) =>
      MeshIconTheme(overrides ?? this.overrides);

  @override
  MeshIconTheme lerp(MeshIconTheme? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Shows the active theme's icon or picture for [slot], or the default icon.
///
/// Named icons take [color] / the ambient [IconTheme] like a normal [Icon];
/// pictures are drawn in their own colors at the same size.
class ThemedIcon extends StatelessWidget {
  final ThemeIconSlot slot;
  final bool selected;
  final double? size;
  final Color? color;

  /// Explicit replacement, bypassing the theme (used for editor previews).
  final ThemeIconOverride? forced;
  final bool useForced;

  const ThemedIcon(
    this.slot, {
    super.key,
    this.selected = false,
    this.size,
    this.color,
  }) : forced = null,
       useForced = false;

  const ThemedIcon.preview(
    this.slot,
    this.forced, {
    super.key,
    this.size,
    this.color,
  }) : selected = false,
       useForced = true;

  @override
  Widget build(BuildContext context) {
    final effective = useForced ? forced : MeshIconTheme.of(context)[slot];
    final bytes = effective?.imageBytes;
    final asset = effective?.asset;
    if (bytes != null || asset != null) {
      // Pictures are usually round badges with a rim, so at plain icon size
      // their detail is too small to make out. Draw them well above it.
      final side =
          (size ?? IconTheme.of(context).size ?? 24) * kThemePictureIconScale;
      return SizedBox.square(
        dimension: side,
        child: Image(
          image: bytes != null
              ? themePictureProvider(bytes)
              : JxlImageProvider.asset(asset!),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Icon(slot.icon, size: side, color: color),
        ),
      );
    }
    final named = effective?.icon == null
        ? null
        : kThemeIconCatalog[effective!.icon];
    return Icon(
      named ?? (selected ? slot.selectedIcon : slot.icon),
      size: size,
      color: color,
    );
  }
}

/// How much larger than a plain icon a picture icon is drawn.
const double kThemePictureIconScale = 1.6;

/// Largest side, in pixels, of a picture stored in a theme. Small enough to
/// keep themes and share codes light, big enough for high-DPI icons.
const int kThemeIconImageMaxSide = 128;

/// Decodes any common image format and re-encodes it as lossless JPEG XL
/// (which keeps transparency) no larger than [kThemeIconImageMaxSide] on its
/// longest side. Returns null when [bytes] is not a readable image.
Future<Uint8List?> shrinkThemeIconImage(Uint8List bytes) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (width, height) {
        final longest = width > height ? width : height;
        if (longest <= kThemeIconImageMaxSide) {
          return ui.TargetImageSize(width: width, height: height);
        }
        final scale = kThemeIconImageMaxSide / longest;
        return ui.TargetImageSize(
          width: (width * scale).round().clamp(1, kThemeIconImageMaxSide),
          height: (height * scale).round().clamp(1, kThemeIconImageMaxSide),
        );
      },
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    try {
      return await encodeJxlFromUiImage(frame.image);
    } finally {
      frame.image.dispose();
    }
  } catch (_) {
    return null;
  }
}
