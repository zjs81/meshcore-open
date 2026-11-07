import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

import '../services/local_api/local_api_pairing.dart';
import '../services/local_api/local_api_service.dart';

/// Settings for the loopback API other apps use to share this radio.
class LocalApiScreen extends StatefulWidget {
  const LocalApiScreen({super.key});

  @override
  State<LocalApiScreen> createState() => _LocalApiScreenState();
}

class _LocalApiScreenState extends State<LocalApiScreen> {
  LocalApiService? get _service => LocalApiService.instance;
  List<PairedClient> _clients = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final service = _service;
    if (service == null) return;
    await service.pairingStore.load();
    if (!mounted) return;
    setState(() => _clients = service.pairedClients);
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final l10n = context.l10n;
    final dateFormat = DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.localApi_title), centerTitle: true),
      body: service == null
          ? Center(child: Text(l10n.localApi_unavailable))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  title: Text(l10n.localApi_title),
                  subtitle: Text(l10n.localApi_enableSubtitle),
                  value: service.isEnabled,
                  onChanged: _busy
                      ? null
                      : (value) async {
                          setState(() => _busy = true);
                          await service.setEnabled(value);
                          if (mounted) setState(() => _busy = false);
                        },
                ),
                ListTile(
                  title: Text(l10n.localApi_address),
                  subtitle: Text(
                    service.isEnabled
                        ? 'ws://127.0.0.1:${service.port}/api/v1'
                        : l10n.localApi_off,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.localApi_allowedApps),
                  subtitle: Text(l10n.localApi_allowedAppsSubtitle),
                ),
                if (_clients.isEmpty)
                  ListTile(
                    title: Text(l10n.localApi_noApps),
                    subtitle: Text(l10n.localApi_noAppsSubtitle),
                  ),
                for (final client in _clients)
                  ListTile(
                    leading: const Icon(Icons.apps),
                    title: Text(client.name),
                    subtitle: Text(
                      '${client.fingerprint}\n'
                      '${l10n.localApi_pairedOn(dateFormat.format(client.pairedAt.toLocal()))}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: l10n.localApi_remove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await service.revoke(client.publicKey);
                        await _reload();
                      },
                    ),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(l10n.localApi_clearData),
                  subtitle: Text(l10n.localApi_clearDataSubtitle),
                  onTap: () async {
                    await service.archive.clear();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.localApi_dataCleared)),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
