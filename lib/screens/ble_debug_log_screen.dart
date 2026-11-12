import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n.dart';
import '../services/ble_debug_log_service.dart';
import '../helpers/raw_rx_packet_decoder.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../widgets/mesh_ui.dart';
import '../helpers/snack_bar_builder.dart';

enum _BleLogView { frames, rawLogRx }

class BleDebugLogScreen extends StatefulWidget {
  const BleDebugLogScreen({super.key});

  @override
  State<BleDebugLogScreen> createState() => _BleDebugLogScreenState();
}

class _BleDebugLogScreenState extends State<BleDebugLogScreen> {
  _BleLogView _view = _BleLogView.frames;

  @override
  Widget build(BuildContext context) {
    return Consumer<BleDebugLogService>(
      builder: (context, logService, _) {
        final entries = logService.entries.reversed.toList();
        final rawEntries = logService.rawLogRxEntries.reversed.toList();
        final showingFrames = _view == _BleLogView.frames;
        final hasEntries = showingFrames
            ? entries.isNotEmpty
            : rawEntries.isNotEmpty;
        final scheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final rxColor = isDark ? MeshPalette.signal : MeshPalette.signalDim;
        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.debugLog_bleTitle),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: context.l10n.debugLog_copyLog,
                icon: const Icon(Icons.copy),
                onPressed: hasEntries
                    ? () async {
                        final text = showingFrames
                            ? entries
                                  .map(
                                    (entry) =>
                                        '${entry.description}\n${entry.hexPreview}\n',
                                  )
                                  .join('\n')
                            : rawEntries
                                  .map(
                                    (entry) =>
                                        'RX RAW_LOG_RX_DATA\n${entry.hexPreview}\n',
                                  )
                                  .join('\n');
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        showDismissibleSnackBar(
                          context,
                          content: Text(context.l10n.debugLog_bleCopied),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SegmentedButton<_BleLogView>(
                    segments: [
                      ButtonSegment(
                        value: _BleLogView.frames,
                        label: MeshSegmentLabel(context.l10n.debugLog_frames),
                      ),
                      ButtonSegment(
                        value: _BleLogView.rawLogRx,
                        label: MeshSegmentLabel(context.l10n.debugLog_rawLogRx),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (selection) {
                      setState(() => _view = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: hasEntries
                      ? ListView.separated(
                          itemCount: showingFrames
                              ? entries.length
                              : rawEntries.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: scheme.outlineVariant),
                          itemBuilder: (context, index) {
                            if (showingFrames) {
                              final entry = entries[index];
                              final time =
                                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
                              Future<void> copyHex() async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: entry.payload
                                        .map(
                                          (b) => b
                                              .toRadixString(16)
                                              .padLeft(2, '0'),
                                        )
                                        .join(''),
                                  ),
                                );
                                if (context.mounted) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      context.l10n.debugLog_bleCopied,
                                    ),
                                  );
                                }
                              }

                              return GestureDetector(
                                onTap: copyHex,
                                onLongPress: copyHex,
                                onSecondaryTap: copyHex,
                                child: Container(
                                  color: scheme.surfaceContainerLowest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        entry.outgoing
                                            ? Icons.upload
                                            : Icons.download,
                                        size: 20,
                                        color: entry.outgoing
                                            ? scheme.primary
                                            : rxColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.description,
                                              style: MeshTheme.mono(
                                                fontSize: 13,
                                                color: scheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              entry.hexPreview,
                                              style: MeshTheme.mono(
                                                fontSize: 13,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              time,
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
                                ),
                              );
                            }

                            final entry = rawEntries[index];
                            final info = decodeRawRxPacket(entry.payload);
                            final time =
                                '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
                            return GestureDetector(
                              onTap: () => _showRawDialog(
                                context,
                                'RX RAW_LOG_RX_DATA • ${info.label}',
                                bytesToHex(entry.payload),
                              ),
                              child: Container(
                                color: scheme.surfaceContainerLowest,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.download,
                                      size: 20,
                                      color: rxColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'RX RAW_LOG_RX_DATA • ${info.label}',
                                            style: MeshTheme.mono(
                                              fontSize: 13,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            info.summary,
                                            style: MeshTheme.mono(
                                              fontSize: 13,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            time,
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
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.l10n.debugLog_noBleActivity,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRawDialog(BuildContext context, String title, String rawHex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(rawHex)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }
}
