import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import '../storage/contact_discovery_store.dart';

/// Manages the app-side list of passively discovered contacts.
///
/// Discovered contacts are heard over the air but have not yet been added to
/// the device's contact list. This service owns the in-memory list and all
/// persistence, import, and export operations so that none of that logic
/// needs to live inside [MeshCoreConnector].
class ContactDiscoveryService extends ChangeNotifier {
  final ContactDiscoveryStore _store;

  final List<Contact> _contacts = [];

  ContactDiscoveryService({ContactDiscoveryStore? store})
    : _store = store ?? ContactDiscoveryStore();

  /// All currently discovered contacts (unfiltered).
  List<Contact> get contacts => List.unmodifiable(_contacts);

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Load the persisted discovered contacts from storage.
  Future<void> load() async {
    final cached = await _store.loadContacts();
    _contacts
      ..clear()
      ..addAll(cached);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mutations called by the connector (BLE-driven)
  // ---------------------------------------------------------------------------

  /// Upsert a contact that was just heard over the air.
  ///
  /// Called by [MeshCoreConnector._handleDiscovery] whenever a new or updated
  /// advert arrives via [PUSH_CODE_LOG_RX_DATA].
  void upsertFromAdvert(Contact contact) {
    final index = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (index >= 0) {
      _contacts[index] = contact;
    } else {
      _contacts.add(contact);
    }
    notifyListeners();
    unawaited(_store.saveContacts(_contacts));
  }

  /// Mark contacts that are now in the device's known-contact list as active.
  ///
  /// Called after [MeshCoreConnector] finishes loading contacts from the
  /// device so the discovery screen can hide already-imported entries.
  void syncActiveFlags(Set<String> knownContactKeys) {
    var changed = false;
    for (int i = 0; i < _contacts.length; i++) {
      final shouldBeActive = knownContactKeys.contains(
        _contacts[i].publicKeyHex,
      );
      if (_contacts[i].isActive != shouldBeActive) {
        _contacts[i] = _contacts[i].copyWith(isActive: shouldBeActive);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      unawaited(_store.saveContacts(_contacts));
    }
  }

  /// Mark a single contact as active after it has been imported to the device.
  void markActive(String publicKeyHex) {
    final index = _contacts.indexWhere((c) => c.publicKeyHex == publicKeyHex);
    if (index >= 0 && !_contacts[index].isActive) {
      _contacts[index] = _contacts[index].copyWith(isActive: true);
      notifyListeners();
      unawaited(_store.saveContacts(_contacts));
    }
  }

  /// Clear the in-memory list on disconnect so stale entries are not shown
  /// when connecting to a different device.
  void clear() {
    if (_contacts.isEmpty) return;
    _contacts.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // User-initiated mutations (deletions)
  // ---------------------------------------------------------------------------

  /// Remove a single discovered contact.
  void remove(Contact contact) {
    _contacts.removeWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    notifyListeners();
    unawaited(_store.saveContacts(_contacts));
  }

  /// Remove all discovered contacts.
  void removeAll() {
    _contacts.clear();
    notifyListeners();
    unawaited(_store.saveContacts(_contacts));
  }

  // ---------------------------------------------------------------------------
  // Import / Export as JSON
  // ---------------------------------------------------------------------------

  /// Serialise the current list to a JSON string for export.
  String exportJson() => _store.exportContactsJson(_contacts);

  /// Merge contacts from a JSON string into the current list.
  ///
  /// Skips contacts that are already in [knownContactKeys] (device contacts)
  /// or already present in the discovered list. Returns the number of newly
  /// added contacts.
  Future<int> importJson(String json, Set<String> knownContactKeys) async {
    final newCount = _store.importContactsJson(
      json: json,
      existingContacts: _contacts,
      knownContactKeys: knownContactKeys,
    );
    if (newCount > 0) {
      notifyListeners();
      await _store.saveContacts(_contacts);
    }
    return newCount;
  }
}
