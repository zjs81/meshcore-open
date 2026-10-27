import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../connector/meshcore_connector.dart';
import '../../utils/app_logger.dart';
import 'local_api_archive.dart';
import 'local_api_host.dart';
import 'local_api_pairing.dart';
import 'local_api_server.dart';
import 'mesh_regions.dart';

/// Lifecycle for the local API: off unless the user enables it in Settings.
///
/// `--dart-define=LOCAL_API_ENABLED=true` turns it on by default for builds
/// made for API development; the saved setting still wins. Not available on
/// web.
class LocalApiService {
  static const String _enabledKey = 'local_api_enabled';
  static const bool _defaultEnabled = bool.fromEnvironment('LOCAL_API_ENABLED');

  static LocalApiService? instance;

  LocalApiService() {
    instance = this;
  }

  final PairingStore pairingStore = PrefsPairingStore();
  final PairingBroker pairingBroker = PairingBroker();
  final LocalApiArchive archive = LocalApiArchive();
  MeshRegionCatalog? _regions;
  LocalApiServer? _server;
  MeshCoreConnector? _connector;
  bool _enabled = _defaultEnabled;

  bool get isEnabled => _enabled;

  bool get isRunning => _server?.isRunning ?? false;

  int get port => _server?.boundPort ?? LocalApiServer.defaultPort;

  Future<void> start(MeshCoreConnector connector) async {
    if (kIsWeb) return;
    _connector = connector;
    await _loadSettings();
    await pairingStore.load();
    await archive.load();
    _regions ??= await MeshRegionCatalog.load();
    if (_enabled) await _startServer(connector);
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (value) {
      final connector = _connector;
      if (connector != null) await _startServer(connector);
    } else {
      await _server?.stop();
      _server = null;
    }
  }

  /// Forgets the app and ends its open connections.
  Future<void> revoke(String publicKey) async {
    final server = _server;
    if (server != null) {
      await server.revoke(publicKey);
    } else {
      await pairingStore.remove(publicKey);
      archive.forgetClient(publicKey);
    }
  }

  List<PairedClient> get pairedClients => pairingStore.clients;

  List<MeshRegion> get regions => _regions?.regions ?? const [];

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? _defaultEnabled;
  }

  Future<void> _startServer(MeshCoreConnector connector) async {
    if (_server != null) return;
    var version = '';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Only for diagnostics in hello.server.
    }
    if (_server != null) return;
    final server = LocalApiServer(
      host: ConnectorLocalApiHost(connector),
      pairingStore: pairingStore,
      pairingBroker: pairingBroker,
      archive: archive,
      serverVersion: version,
      regions: _regions,
    );
    try {
      await server.start();
      _server = server;
    } catch (error) {
      appLogger.warn('Local API did not start: $error', tag: 'LocalApi');
    }
  }
}
