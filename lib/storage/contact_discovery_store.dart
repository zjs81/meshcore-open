import 'dart:convert';
import 'dart:typed_data';

import '../models/contact.dart';
import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ContactDiscoveryImportResult {
  final List<Contact> mergedContacts;
  final int newContactCount;

  const ContactDiscoveryImportResult({
    required this.mergedContacts,
    required this.newContactCount,
  });
}

class ContactDiscoveryStore {
  static const String _keyPrefix = 'discovered_contacts';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length >= 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  List<Contact> decodeContacts(String jsonStr) {
    try {
      final jsonList = jsonDecode(jsonStr) as List<dynamic>;
      return jsonList
          .map((entry) => _fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Contact>> loadContacts() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load contacts.');
      return [];
    }
    final prefs = PrefsManager.instance;
    var jsonStr = prefs.getString(keyFor);
    if ((jsonStr == null || jsonStr.isEmpty) && publicKeyHex.isNotEmpty) {
      // One-time migration from legacy unscoped key.
      final legacy = prefs.getString(_keyPrefix);
      prefs.remove(_keyPrefix);
      if (legacy != null && legacy.isNotEmpty) {
        await prefs.setString(keyFor, legacy);
        jsonStr = legacy;
      }
    }
    if (jsonStr == null) return [];
    return decodeContacts(jsonStr);
  }

  String encodeContacts(List<Contact> contacts) {
    final jsonList = contacts.map(_toJson).toList();
    return jsonEncode(jsonList);
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save contacts.');
      return;
    }
    final prefs = PrefsManager.instance;
    await prefs.setString(keyFor, encodeContacts(contacts));
  }

  ContactDiscoveryImportResult importContactsJson({
    required String json,
    required List<Contact> existingContacts,
    required Set<String> knownContactKeys,
  }) {
    final importedContacts = decodeContacts(json);
    if (importedContacts.isEmpty) {
      return const ContactDiscoveryImportResult(
        mergedContacts: <Contact>[],
        newContactCount: 0,
      );
    }

    final byPublicKey = <String, Contact>{
      for (final contact in existingContacts) contact.publicKeyHex: contact,
    };
    var newContactCount = 0;

    for (final contact in importedContacts) {
      final existing = byPublicKey[contact.publicKeyHex];
      if (existing == null) {
        newContactCount++;
      }
      byPublicKey[contact.publicKeyHex] = existing == null
          ? contact
          : _mergeImportedContact(existing, contact, knownContactKeys);
    }

    return ContactDiscoveryImportResult(
      mergedContacts: byPublicKey.values.toList(),
      newContactCount: newContactCount,
    );
  }

  String exportContactsJson(List<Contact> discoveredContacts) {
    return encodeContacts(
      discoveredContacts.where((contact) => !contact.isActive).toList(),
    );
  }

  Contact _mergeImportedContact(
    Contact existing,
    Contact imported,
    Set<String> knownContactKeys,
  ) {
    final isKnownContact = knownContactKeys.contains(imported.publicKeyHex);
    return existing.copyWith(
      isActive: existing.isActive || isKnownContact,
      rawPacket: existing.rawPacket ?? imported.rawPacket,
      lastSeen: imported.lastSeen.isAfter(existing.lastSeen)
          ? imported.lastSeen
          : existing.lastSeen,
      lastMessageAt: imported.lastMessageAt.isAfter(existing.lastMessageAt)
          ? imported.lastMessageAt
          : existing.lastMessageAt,
    );
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
      'lastMessageAt': contact.lastMessageAt.millisecondsSinceEpoch,
      'rawPacket': contact.rawPacket != null
          ? base64Encode(contact.rawPacket!)
          : null,
    };
  }

  Contact _fromJson(Map<String, dynamic> json) {
    final lastSeenMs = json['lastSeen'] as int? ?? 0;
    final lastMessageMs = json['lastMessageAt'] as int?;
    final name = json['name'] as String?;
    return Contact(
      publicKey: Uint8List.fromList(base64Decode(json['publicKey'] as String)),
      name: name == null || name.isEmpty ? 'Unknown' : name,
      type: json['type'] as int? ?? 0,
      flags: json['flags'] as int? ?? 0,
      pathLength: json['pathLength'] as int? ?? -1,
      path: json['path'] != null
          ? Uint8List.fromList(base64Decode(json['path'] as String))
          : Uint8List(0),
      pathOverride: json['pathOverride'] as int?,
      pathOverrideBytes: json['pathOverrideBytes'] != null
          ? Uint8List.fromList(
              base64Decode(json['pathOverrideBytes'] as String),
            )
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(lastSeenMs),
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
