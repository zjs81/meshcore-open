import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/network_map/network_map_api_client.dart';
import '../services/network_map/network_map_upload_service.dart';
import 'mesh_nav_tile.dart';
import 'network_map_online_layer.dart';

/// Opt-in toggle, plain-language explanation and status for network map
/// uploads.
class NetworkMapSettingsSection extends StatelessWidget {
  const NetworkMapSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NetworkMapUploadService>();
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.public, size: 24),
          title: Text(l10n.networkMap_uploadTitle),
          subtitle: Text(_status(context, service)),
          value: service.enabled,
          onChanged: service.setEnabled,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            l10n.networkMap_uploadExplanation,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.networkMap_whatWeCollect,
          trailing: const Icon(Icons.open_in_new, size: 22),
          showChevron: false,
          onTap: () => launchUrl(
            Uri.parse('$networkMapBaseUrl/privacy'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  String _status(BuildContext context, NetworkMapUploadService service) {
    final l10n = context.l10n;
    if (!service.enabled) return l10n.networkMap_statusOff;
    final last = service.lastUploadAt;
    if (last != null) {
      return l10n.networkMap_statusLastSent(
        networkMapTimeAgo(context, last),
        service.packetsSentToday,
      );
    }
    if (!service.isActive) return l10n.networkMap_statusWaiting;
    return l10n.networkMap_statusNothingSent;
  }
}
