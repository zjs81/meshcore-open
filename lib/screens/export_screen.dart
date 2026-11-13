import 'package:flutter/material.dart';
import 'package:meshcore_open/utils/gpx_export.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../utils/share_origin.dart';
import '../widgets/app_bar.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/sync_progress_overlay.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          l10n.settings_export,
          indicators: false,
          subtitle: false,
        ),
        centerTitle: true,
        bottom: const SyncProgressAppBarBottom(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            SectionHeader(l10n.settings_export),
            MeshCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  MeshNavTile(
                    icon: Icons.download_outlined,
                    title: l10n.settings_gpxExportRepeaters,
                    subtitle: l10n.settings_gpxExportRepeatersSubtitle,
                    onTap: () {
                      final exporter = GpxExport(connector)..addRepeaters();
                      _gpxExport(
                        context,
                        exporter,
                        l10n.map_repeater,
                        l10n.settings_gpxExportRepeatersRoom,
                        'meshcore_repeaters_',
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  MeshNavTile(
                    icon: Icons.download_outlined,
                    title: l10n.settings_gpxExportContacts,
                    subtitle: l10n.settings_gpxExportContactsSubtitle,
                    onTap: () {
                      final exporter = GpxExport(connector)..addContacts();
                      _gpxExport(
                        context,
                        exporter,
                        l10n.map_repeater,
                        l10n.settings_gpxExportChat,
                        'meshcore_contacts_',
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  MeshNavTile(
                    icon: Icons.download_outlined,
                    title: l10n.settings_gpxExportAll,
                    subtitle: l10n.settings_gpxExportAllSubtitle,
                    onTap: () {
                      final exporter = GpxExport(connector)..addAll();
                      _gpxExport(
                        context,
                        exporter,
                        l10n.map_repeater,
                        l10n.settings_gpxExportAllContacts,
                        'meshcore_all_',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gpxExport(
    BuildContext context,
    GpxExport exporter,
    String name,
    String description,
    String filename,
  ) async {
    final l10n = context.l10n;
    final result = await exporter.exportGPX(
      name,
      description,
      filename,
      l10n.settings_gpxExportShareText,
      l10n.settings_gpxExportShareSubject,
      sharePositionOrigin: shareOriginOf(context),
    );
    if (!context.mounted) return;
    final message = switch (result) {
      gpxExportSuccess => l10n.settings_gpxExportSuccess,
      gpxExportNoContacts => l10n.settings_gpxExportNoContacts,
      gpxExportNotAvailable => l10n.settings_gpxExportNotAvailable,
      gpxExportFailed => l10n.settings_gpxExportError,
      _ => l10n.settings_gpxExportError,
    };
    showDismissibleSnackBar(context, content: Text(message));
  }
}
