import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_debug_log_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../helpers/snack_bar_builder.dart';

class AppDebugLogScreen extends StatelessWidget {
  const AppDebugLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDebugLogService>(
      builder: (context, logService, _) {
        final entries = logService.entries.reversed.toList();
        final hasEntries = entries.isNotEmpty;
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.debugLog_appTitle),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: context.l10n.debugLog_copyLog,
                icon: const Icon(Icons.copy),
                onPressed: hasEntries
                    ? () async {
                        final text = entries
                            .map(
                              (entry) =>
                                  '[${entry.formattedTime}] [${entry.levelLabel}] [${entry.tag}] ${entry.message}',
                            )
                            .join('\n');
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        showDismissibleSnackBar(
                          context,
                          content: Text(context.l10n.debugLog_copied),
                        );
                      }
                    : null,
              ),
              IconButton(
                tooltip: context.l10n.debugLog_clearLog,
                icon: const Icon(Icons.delete_outline),
                onPressed: hasEntries
                    ? () async {
                        final confirmed = await showConfirmClearDialog(
                          context,
                          title: context.l10n.debugLog_clearLog,
                          message: context.l10n.debugLog_clearConfirm,
                        );
                        if (confirmed) logService.clear();
                      }
                    : null,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: hasEntries
                ? ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: scheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Container(
                        color: scheme.surfaceContainerLowest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLevelIcon(context, entry.level),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '[${entry.tag}] ',
                                          style: MeshTheme.mono(
                                            fontSize: 13,
                                            color: _levelColor(
                                              context,
                                              entry.level,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text: entry.message,
                                          style: MeshTheme.mono(
                                            fontSize: 13,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.formattedTime,
                                    style: MeshTheme.mono(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 64,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.debugLog_noEntries,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.debugLog_enableInSettings,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Color _levelColor(BuildContext context, AppDebugLogLevel level) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case AppDebugLogLevel.info:
        return scheme.primary;
      case AppDebugLogLevel.warning:
        return isDark ? MeshPalette.warn : MeshPalette.warnDim;
      case AppDebugLogLevel.error:
        return scheme.error;
    }
  }

  Widget _buildLevelIcon(BuildContext context, AppDebugLogLevel level) {
    switch (level) {
      case AppDebugLogLevel.info:
        return Icon(
          Icons.info_outline,
          size: 20,
          color: _levelColor(context, level),
        );
      case AppDebugLogLevel.warning:
        return Icon(
          Icons.warning_amber_outlined,
          size: 20,
          color: _levelColor(context, level),
        );
      case AppDebugLogLevel.error:
        return Icon(
          Icons.error_outline,
          size: 20,
          color: _levelColor(context, level),
        );
    }
  }
}
