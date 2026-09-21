import 'dart:convert';
import 'dart:typed_data';

import '../models/contact.dart';
import 'prefs_manager.dart';

class ContactDiscoveryStore {
  static const String _keyPrefix = 'discovered_contacts';

  Future<List<Contact>> loadContacts() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_keyPrefix);
    if (jsonStr == null) return [];

    try {
      final jsonList = jsonDecode(jsonStr) as List<dynamic>;
      return jsonList
          .map((entry) => _fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = PrefsManager.instance;
    final jsonList = contacts.map(_toJson).toList();
    await prefs.setString(_keyPrefix, jsonEncode(jsonList));
  }

  String exportContactsJson(List<Contact> contacts) {
    final jsonList = contacts.map(_toJson).toList();
    return jsonEncode(jsonList);
  }

  int importContactsJson({
    required String json,
    required List<Contact> existingContacts,
    required Set<String> knownContactKeys,
  }) {
    try {
      final jsonList = jsonDecode(json) as List<dynamic>;
      final importedContacts = jsonList
          .map((entry) => _fromJson(entry as Map<String, dynamic>))
          .toList();

      int newCount = 0;

      // Create a set of existing discovered contact keys for deduplication
      final existingKeySet = <String>{};
      for (final contact in existingContacts) {
        existingKeySet.add(contact.publicKeyHex);
      }

      // Process imported contacts
      for (final imported in importedContacts) {
        final keyHex = imported.publicKeyHex;

        // Skip if already in device's contact list
        if (knownContactKeys.contains(keyHex)) {
          continue;
        }

        // Skip if already in discovered contacts (existing is always fresher)
        if (existingKeySet.contains(keyHex)) {
          continue;
        }

        // Add as new discovered contact
        existingContacts.add(imported);
        newCount++;
      }

      return newCount;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> _toJson(Contact contact) {
    return {
      'publicKey': base64Encode(contact.publicKey),
      'name': contact.name,
      'type': contact.type,
      'flags': contact.flags,
      'pathLength': contact.pathLength,
      'path': base64Encode(contact.path),
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

  Contact _fromJson(Map<String, dynamic> json) {
    final lastSeenMs = json['lastSeen'] as int? ?? 0;
    final lastMessageMs = json['lastMessageAt'] as int?;
    final lastModifiedMs = json['lastModified'] as int?;

    final rawPathLength = json['pathLength'] as int? ?? -1;
    final rawPath = json['path'] != null
        ? Uint8List.fromList(base64Decode(json['path'] as String))
        : Uint8List(0);

    int decodedPathLength = rawPathLength;
    Uint8List decodedPath = rawPath;

    if (rawPathLength == 0xFF || rawPathLength < 0) {
      decodedPathLength = -1;
      decodedPath = Uint8List(0);
    } else if (rawPathLength >= 64) {
      final mode = (rawPathLength & 0xC0) >> 6;
      final hopCount = rawPathLength & 0x3F;
      final width = mode + 1;
      final byteLen = hopCount * width;
      decodedPathLength = hopCount;
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
      pathOverride: json['pathOverride'] as int?,
      pathOverrideBytes: json['pathOverrideBytes'] != null
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
