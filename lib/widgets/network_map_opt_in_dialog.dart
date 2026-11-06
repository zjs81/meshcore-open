import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/network_map/network_map_api_client.dart';

/// Asks once whether to share what the radio hears with the network map.
///
/// Shows nothing when uploading is already on, the prompt was shown before,
/// or the app is in review mode. The prompt counts as shown as soon as it
/// opens, so dismissing it never brings it back.
Future<void> maybeShowNetworkMapOptInDialog(BuildContext context) async {
  final settingsService = context.read<AppSettingsService>();
  final connector = context.read<MeshCoreConnector>();
  final settings = settingsService.settings;
  if (settings.networkMapPromptShown ||
      settings.networkMapUploadEnabled ||
      connector.isReviewMode ||
      !connector.isConnected) {
    return;
  }

  await settingsService.setNetworkMapPromptShown(true);
  if (!context.mounted) return;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => const _NetworkMapOptInDialog(),
  );
  if (accepted == true) {
    await settingsService.setNetworkMapUploadEnabled(true);
  }
}

class _NetworkMapOptInDialog extends StatelessWidget {
  const _NetworkMapOptInDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.public, size: 36, color: scheme.primary),
      title: Text(l10n.networkMap_promptTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.networkMap_promptBody,
              style: textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.networkMap_promptSettingsHint,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.open_in_new, size: 20),
                label: Text(l10n.networkMap_whatWeCollect),
                onPressed: () => launchUrl(
                  Uri.parse('$networkMapBaseUrl/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.networkMap_promptDecline),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.networkMap_promptAccept),
        ),
      ],
    );
  }
}
