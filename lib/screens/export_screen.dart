import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:meshcore_open/utils/gpx_export.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../theme/theme_icons.dart';
import '../utils/bookmark_markdown_export.dart';
import '../utils/platform_info.dart';
import '../utils/share_origin.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/sync_progress_overlay.dart';

class ExportScreen extends StatelessWidget {
  static const _markdownFileType = XTypeGroup(
    label: 'Markdown',
    extensions: ['md'],
    mimeTypes: ['text/markdown'],
  );

  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.settings_exportData),
        centerTitle: true,
        bottom: const SyncProgressAppBarBottom(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            SectionHeader(
              l10n.export_messagesTitle,
              description: l10n.export_messagesDescription,
            ),
            MeshCard(
              padding: EdgeInsets.zero,
              child: MeshNavTile(
                // The bookmark icon used in chats.
                icon: Icons.bookmark_border,
                title: l10n.settings_exportBookmarks,
                onTap: () => _exportBookmarks(context),
              ),
            ),
            SectionHeader(
              l10n.export_locationsTitle,
              description: l10n.export_locationsDescription,
            ),
            MeshCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Same icons as the contact list and Contact Settings.
                  MeshNavTile(
                    icon: Icons.cell_tower,
                    iconSlot: ThemeIconSlot.repeater,
                    title: l10n.settings_gpxExportRepeaters,
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
                    icon: Icons.person,
                    title: l10n.settings_gpxExportContacts,
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
                    icon: Icons.people_outline,
                    iconSlot: ThemeIconSlot.contacts,
                    title: l10n.settings_gpxExportAll,
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

  Future<void> _exportBookmarks(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final bookmarks = await context
          .read<MeshCoreConnector>()
          .loadBookmarkedMessages();
      if (!context.mounted) return;
      if (bookmarks.isEmpty) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_exportBookmarksNoBookmarks),
        );
        return;
      }

      final exportedAt = DateTime.now();
      final markdown = await buildBookmarksMarkdown(
        bookmarks,
        publicGateway: context
            .read<AppSettingsService>()
            .settings
            .publicIpfsGateway,
        exportedAt: exportedAt,
      );
      if (!context.mounted) return;
      final date =
          '${exportedAt.year.toString().padLeft(4, '0')}'
          '-${exportedAt.month.toString().padLeft(2, '0')}'
          '-${exportedAt.day.toString().padLeft(2, '0')}';
      final filename = 'meshcore-open-bookmarks_$date.md';
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(markdown)),
        name: filename,
        mimeType: 'text/markdown',
      );

      if (PlatformInfo.isWeb) {
        await file.saveTo(filename);
      } else if (PlatformInfo.isDesktop) {
        final location = await getSaveLocation(
          suggestedName: filename,
          acceptedTypeGroups: const [_markdownFileType],
        );
        if (location == null || !context.mounted) return;
        await file.saveTo(location.path);
      } else {
        final result = await SharePlus.instance.share(
          ShareParams(
            subject: l10n.settings_exportBookmarks,
            files: [file],
            fileNameOverrides: [filename],
            sharePositionOrigin: shareOriginOf(context),
          ),
        );
        if (result.status == ShareResultStatus.dismissed) return;
      }
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_exportBookmarksSuccess),
        );
      }
    } catch (error) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text('${l10n.settings_gpxExportError} $error'),
        );
      }
    }
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
