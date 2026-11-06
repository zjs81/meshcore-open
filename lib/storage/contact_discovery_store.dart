import 'dart:convert';
import 'dart:typed_data';

import '../models/contact.dart';
import '../utils/app_logger.dart';
import 'legacy_key_migration.dart';
import 'prefs_manager.dart';

class ContactDiscoveryStore {
  static const String _keyPrefix = 'discovered_contacts';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<List<Contact>> loadContacts() async {
    if (publicKeyHex.isEmpty) return [];
    final prefs = PrefsManager.instance;
    var jsonStr = prefs.getString(keyFor);
    if (jsonStr == null && canMigrateLegacyKeys(publicKeyHex)) {
      jsonStr = prefs.getString(_keyPrefix);
      if (jsonStr != null) {
        await prefs.setString(keyFor, jsonStr);
        await prefs.remove(_keyPrefix);
      }
    }
    if (jsonStr == null) return [];

    final List<dynamic> jsonList;
    try {
      jsonList = jsonDecode(jsonStr) as List<dynamic>;
    } catch (e) {
      appLogger.warn('Stored discovered contacts are unreadable: $e');
      return [];
    }
    final contacts = <Contact>[];
    for (final entry in jsonList) {
      try {
        contacts.add(_fromJson(entry as Map<String, dynamic>));
      } catch (e) {
        appLogger.warn('Skipping malformed discovered contact: $e');
      }
    }
    return contacts;
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    if (publicKeyHex.isEmpty) return;
    final prefs = PrefsManager.instance;
    final jsonList = contacts.map(_toJson).toList();
    await prefs.setString(keyFor, jsonEncode(jsonList));
  }

  /// Exports [contacts] for sharing. Routing paths are left out: a path is
  /// the route from this radio and is meaningless on another one.
  String exportContactsJson(List<Contact> contacts) {
    final jsonList = contacts.map((contact) {
      final json = _toJson(contact);
      for (final key in _pathKeys) {
        json.remove(key);
      }
      return json;
    }).toList();
    return jsonEncode(jsonList);
  }

  static const List<String> _pathKeys = [
    'pathLength',
    'path',
    'pathHashWidth',
    'pathOverride',
    'pathOverrideBytes',
  ];

  /// Merges an export file into [existingContacts], each entry on its own:
  /// a malformed entry is counted as invalid instead of failing the file.
  ///
  /// Skips radio contacts ([knownContactKeys]), discovered contacts already
  /// present (they are fresher), duplicates within the file, and the
  /// connected radio's own key. Imported paths are dropped (they belong to the
  /// exporting radio) and timestamps are clamped to [now].
  ///
  /// Throws [FormatException] when the file is not a JSON list.
  DiscoveredContactsImportResult importContactsJson({
    required String json,
    required List<Contact> existingContacts,
    required Set<String> knownContactKeys,
    String? selfPublicKeyHex,
    DateTime? now,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Not valid JSON: $e');
    }
    if (decoded is! List) {
      throw const FormatException('Expected a list of contacts');
    }

    final clampTo = now ?? DateTime.now();
    final seenKeys = {for (final c in existingContacts) c.publicKeyHex};
    var imported = 0;
    var skipped = 0;
    var invalid = 0;

    for (final entry in decoded) {
      final Contact contact;
      try {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Entry is not an object');
        }
        contact = _fromJson(entry, importing: true, clampTo: clampTo);
        if (contact.publicKey.length != _pubKeySize) {
          throw const FormatException('Public key must be 32 bytes');
        }
      } catch (e) {
        appLogger.warn('Skipping invalid imported discovered contact: $e');
        invalid++;
        continue;
      }

      final keyHex = contact.publicKeyHex;
      if (keyHex == selfPublicKeyHex ||
          knownContactKeys.contains(keyHex) ||
          !seenKeys.add(keyHex)) {
        skipped++;
        continue;
      }
      existingContacts.add(contact);
      imported++;
    }

    return DiscoveredContactsImportResult(
      total: decoded.length,
      imported: imported,
      skipped: skipped,
      invalid: invalid,
    );
  }

  static const int _pubKeySize = 32;

  Map<String, dynamic> _toJson(Contact contact) {
    return {
      'publicKey': base64Encode(contact.publicKey),
      'name': contact.name,
      'type': contact.type,
      'flags': contact.flags,
      'pathLength': contact.pathLength,
      'path': base64Encode(contact.path),
      'pathHashWidth': contact.pathHashWidth,
      'pathOverride': contact.pathOverride,
      'pathOverrideBytes': contact.pathOverrideBytes != null
          ? base64Encode(contact.pathOverrideBytes!)
          : null,
      'latitude': contact.latitude,
      'longitude': contact.longitude,
      'lastSeen': contact.lastSeen.millisecondsSinceEpoch,
      'lastModified': contact.lastModified?.millisecondsSinceEpoch,
      'lastMessageAt': contact.lastMessageAt.millisecondsSinceEpoch,
      'isActive': contact.isActive,
      'rawPacket': contact.rawPacket != null
          ? base64Encode(contact.rawPacket!)
          : null,
    };
  }

  Contact _fromJson(
    Map<String, dynamic> json, {
    bool importing = false,
    DateTime? clampTo,
  }) {
    int? clampMs(int? ms) {
      if (ms == null || clampTo == null) return ms;
      final limit = clampTo.millisecondsSinceEpoch;
      return ms > limit ? limit : ms;
    }

    final lastSeenMs = clampMs((json['lastSeen'] as num?)?.toInt()) ?? 0;
    final lastMessageMs = clampMs((json['lastMessageAt'] as num?)?.toInt());
    final lastModifiedMs = clampMs((json['lastModified'] as num?)?.toInt());

    // An imported path is the exporting radio's route: never reuse it.
    final rawPathLength = importing ? -1 : json['pathLength'] as int? ?? -1;
    final rawPath = !importing && json['path'] != null
        ? Uint8List.fromList(base64Decode(json['path'] as String))
        : Uint8List(0);

    int decodedPathLength = rawPathLength;
    Uint8List decodedPath = rawPath;
    int? decodedPathHashWidth = importing
        ? null
        : json['pathHashWidth'] as int?;

    if (rawPathLength == 0xFF || rawPathLength < 0) {
      decodedPathLength = -1;
      decodedPath = Uint8List(0);
    } else if (rawPathLength >= 64) {
      final mode = (rawPathLength & 0xC0) >> 6;
      final hopCount = rawPathLength & 0x3F;
      final width = mode + 1;
      final byteLen = hopCount * width;
      decodedPathLength = hopCount;
      decodedPathHashWidth = width;
      if (byteLen <= rawPath.length) {
        decodedPath = rawPath.sublist(0, byteLen);
      } else {
        decodedPath = Uint8List(0);
      }
    } else if (rawPathLength == 0) {
      decodedPath = Uint8List(0);
    }

    return Contact(
      publicKey: Uint8List.fromList(base64Decode(json['publicKey'] as String)),
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as int? ?? 0,
      flags: json['flags'] as int? ?? 0,
      pathLength: decodedPathLength,
      path: decodedPath,
      pathHashWidth:
          decodedPathHashWidth ??
          Contact.inferPathHashWidth(decodedPathLength, decodedPath.length),
      pathOverride: importing ? null : json['pathOverride'] as int?,
      pathOverrideBytes: !importing && json['pathOverrideBytes'] != null
          ? Uint8List.fromList(
              base64Decode(json['pathOverrideBytes'] as String),
            )
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(lastSeenMs),
      lastModified: lastModifiedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        lastMessageMs ?? lastSeenMs,
      ),
      isActive: false,
      rawPacket: json['rawPacket'] != null
          ? Uint8List.fromList(base64Decode(json['rawPacket'] as String))
          : null,
    );
  }
}

/// Outcome of [ContactDiscoveryStore.importContactsJson].
class DiscoveredContactsImportResult {
  const DiscoveredContactsImportResult({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.invalid,
  });

  static const empty = DiscoveredContactsImportResult(
    total: 0,
    imported: 0,
    skipped: 0,
    invalid: 0,
  );

  /// Entries in the file.
  final int total;

  /// Entries added as new discovered contacts.
  final int imported;

  /// Valid entries already known (contact, discovered, duplicate, or self).
  final int skipped;

  /// Entries that could not be read.
  final int invalid;
}
