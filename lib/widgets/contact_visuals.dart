import 'package:flutter/material.dart';

import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../theme/mesh_theme.dart';
import '../theme/theme_icons.dart';
import '../utils/emoji_utils.dart';

/// Shared node-type visuals and last-seen formatting for contact lists
/// (contacts, discovery, nearby-node scan).

/// Accent used for sensor nodes.
const Color meshSensorTeal = Color(0xFF4ACCC4);

/// Node-type accent colour per design language.
Color contactTypeColor(int type) {
  switch (type) {
    case advTypeRepeater:
      return MeshPalette.warn;
    case advTypeRoom:
      return MeshPalette.magenta;
    case advTypeSensor:
      return meshSensorTeal;
    default:
      return MeshPalette.blue;
  }
}

/// Node-type avatar icon slot (themes can replace these). Returns null for
/// chat nodes so [AvatarCircle] shows initials.
ThemeIconSlot? contactTypeIconSlot(int type) {
  switch (type) {
    case advTypeRepeater:
      return ThemeIconSlot.repeater;
    case advTypeRoom:
      return ThemeIconSlot.room;
    case advTypeSensor:
      return ThemeIconSlot.sensor;
    default:
      return null;
  }
}

final RegExp _letterOrDigit = RegExp(r'^[\p{L}\p{N}]', unicode: true);

/// Avatar initials for a display name, or null when the name has nothing
/// usable so the caller can show an icon or key prefix instead.
///
/// Only letters and digits count: punctuation such as `-`, `(` or `[` splits
/// words but never becomes an initial, so "(Base) Node" gives "BN" and
/// "- Relay" gives "RE". Characters are whole grapheme clusters, so accented
/// letters and emoji are never cut in half. A name with no letters or digits
/// but an emoji shows that emoji.
String? avatarInitials(String name) {
  final words = <String>[];
  final current = StringBuffer();
  String? emoji;
  for (final cluster in name.characters) {
    if (_letterOrDigit.hasMatch(cluster)) {
      current.write(cluster);
      continue;
    }
    if (current.isNotEmpty) {
      words.add(current.toString());
      current.clear();
    }
    emoji ??= firstEmoji(cluster);
  }
  if (current.isNotEmpty) words.add(current.toString());

  if (words.isEmpty) return emoji;
  if (words.length == 1) {
    return words.first.characters.take(2).toString().toUpperCase();
  }
  return (words[0].characters.first + words[1].characters.first).toUpperCase();
}

/// The most recent activity for [contact]: for chat nodes this includes the
/// last message, for other node types only the last advert or telemetry fix.
/// [addedAt] (the phone time the contact was added from a card) stands in
/// while the radio has no advert time for it.
DateTime resolveContactLastSeen(Contact contact, {DateTime? addedAt}) {
  final heard =
      addedAt != null &&
          contact.lastSeen.millisecondsSinceEpoch == 0 &&
          addedAt.isAfter(contact.lastHeard)
      ? addedAt
      : contact.lastHeard;
  if (contact.type != advTypeChat) return heard;
  return contact.lastMessageAt.isAfter(heard) ? contact.lastMessageAt : heard;
}

/// Short relative "last seen" label ("now", "5 mins ago", "2 days ago").
String formatContactLastSeen(AppLocalizations l10n, DateTime lastSeen) {
  if (lastSeen.millisecondsSinceEpoch == 0) return l10n.contacts_lastSeenNever;
  final diff = DateTime.now().difference(lastSeen);

  if (diff.isNegative || diff.inMinutes < 5) {
    return l10n.contacts_lastSeenNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return hours == 1
        ? l10n.contacts_lastSeenHourAgo
        : l10n.contacts_lastSeenHoursAgo(hours);
  }
  final days = diff.inDays;
  return days == 1
      ? l10n.contacts_lastSeenDayAgo
      : l10n.contacts_lastSeenDaysAgo(days);
}

/// Memoizes a derived list (filtered/sorted contacts) so it is only
/// recomputed when the input elements or the filter key change. Contacts are
/// immutable, so element identity is a sufficient change check even though
/// the connector hands out a fresh list copy on every read.
class DerivedListCache<T> {
  List<T>? _inputs;
  List<Object?>? _key;
  List<T>? _result;

  List<T> get(List<T> inputs, List<Object?> key, List<T> Function() compute) {
    final cached = _result;
    if (cached != null &&
        _sameElements(_inputs!, inputs) &&
        _sameKey(_key!, key)) {
      return cached;
    }
    final result = compute();
    _inputs = List<T>.of(inputs);
    _key = key;
    _result = result;
    return result;
  }

  void invalidate() => _result = null;

  static bool _sameElements<E>(List<E> a, List<E> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _sameKey(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x is List && y is List) {
        if (x.length != y.length) return false;
        for (var j = 0; j < x.length; j++) {
          if (x[j] != y[j]) return false;
        }
      } else if (x != y) {
        return false;
      }
    }
    return true;
  }
}
