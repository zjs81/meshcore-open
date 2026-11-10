import 'dart:convert';

import '../utils/app_logger.dart';
import 'prefs_manager.dart';

/// The radio that last completed a handshake, so its saved data can be shown
/// while no radio is connected.
class LastRadio {
  static const String transportBle = 'ble';
  static const String transportUsb = 'usb';
  static const String transportTcp = 'tcp';

  /// Full public key hex of the radio.
  final String publicKeyHex;
  final String name;

  /// One of [transportBle], [transportUsb] or [transportTcp].
  final String transport;
  final String? bleRemoteId;
  final String? bleDisplayName;
  final String? tcpHost;
  final int? tcpPort;
  final DateTime savedAt;

  const LastRadio({
    required this.publicKeyHex,
    required this.name,
    required this.transport,
    this.bleRemoteId,
    this.bleDisplayName,
    this.tcpHost,
    this.tcpPort,
    required this.savedAt,
  });

  bool get canReconnectBle =>
      transport == transportBle && (bleRemoteId?.isNotEmpty ?? false);

  bool get canReconnectTcp =>
      transport == transportTcp &&
      (tcpHost?.isNotEmpty ?? false) &&
      tcpPort != null;

  Map<String, dynamic> toJson() => {
    'publicKeyHex': publicKeyHex,
    'name': name,
    'transport': transport,
    if (bleRemoteId != null) 'bleRemoteId': bleRemoteId,
    if (bleDisplayName != null) 'bleDisplayName': bleDisplayName,
    if (tcpHost != null) 'tcpHost': tcpHost,
    if (tcpPort != null) 'tcpPort': tcpPort,
    'savedAt': savedAt.millisecondsSinceEpoch,
  };

  /// Returns null when [json] does not hold a usable record.
  static LastRadio? fromJson(Object? json) {
    if (json is! Map) return null;
    final key = json['publicKeyHex'];
    if (key is! String || key.length < 10) return null;
    String? optString(String field) {
      final value = json[field];
      return value is String && value.isNotEmpty ? value : null;
    }

    final port = json['tcpPort'];
    final savedAt = json['savedAt'];
    final transport = optString('transport');
    return LastRadio(
      publicKeyHex: key,
      name: optString('name') ?? '',
      transport: transport == transportUsb || transport == transportTcp
          ? transport!
          : transportBle,
      bleRemoteId: optString('bleRemoteId'),
      bleDisplayName: optString('bleDisplayName'),
      tcpHost: optString('tcpHost'),
      tcpPort: port is num ? port.toInt() : null,
      savedAt: savedAt is num
          ? DateTime.fromMillisecondsSinceEpoch(savedAt.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// App-wide (not per-radio) record of the last connected radio.
class LastRadioStore {
  static const String prefsKey = 'last_radio';

  LastRadio? load() {
    final raw = PrefsManager.instance.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return LastRadio.fromJson(jsonDecode(raw));
    } catch (e) {
      appLogger.warn('Stored last radio is unreadable: $e');
      return null;
    }
  }

  Future<void> save(LastRadio radio) =>
      PrefsManager.instance.setString(prefsKey, jsonEncode(radio.toJson()));

  Future<void> clear() => PrefsManager.instance.remove(prefsKey);
}
