import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/path_helper.dart';
import '../helpers/raw_rx_packet_decoder.dart';
import '../l10n/l10n.dart';
import '../helpers/snack_bar_builder.dart';
import '../services/ble_debug_log_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../widgets/signal_ui.dart';

/// Live log of every packet the radio has seen, with the raw bytes and every
/// field the app can decode from them.
class RxLogScreen extends StatelessWidget {
  const RxLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BleDebugLogService, MeshCoreConnector>(
      builder: (context, logService, connector, _) {
        final entries = logService.rawLogRxEntries.reversed.toList();
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.rxLog_title),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: context.l10n.debugLog_copyLog,
                icon: const Icon(Icons.copy),
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        final text = entries
                            .map(
                              (entry) =>
                                  '${_formatTime(entry.timestamp)} ${entry.snrDb != null ? '${entry.snrDb!.toStringAsFixed(1)}dB ' : ''}'
                                  '${decodeRawRxPacket(entry.payload).label}\n'
                                  '${bytesToHex(entry.payload)}\n',
                            )
                            .join('\n');
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        showDismissibleSnackBar(
                          context,
                          content: Text(context.l10n.rxLog_copied),
                        );
                      },
              ),
              IconButton(
                tooltip: context.l10n.debugLog_clearLog,
                icon: const Icon(Icons.delete_outline),
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        final confirmed = await showConfirmClearDialog(
                          context,
                          title: context.l10n.debugLog_clearLog,
                          message: context.l10n.debugLog_clearConfirm,
                        );
                        if (confirmed) logService.clear();
                      },
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.rxLog_empty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: scheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final info = decodeRawRxPacket(entry.payload);
                      final signal = _signalText(context, entry);
                      final signalColor = MeshTheme.signalColor(
                        snrDb: entry.snrDb,
                        rssiDbm: entry.rssiDbm,
                      );
                      return GestureDetector(
                        onTap: () =>
                            _showEntryDialog(context, connector, entry),
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
                                color: signalColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info.label,
                                      style: MeshTheme.mono(
                                        fontSize: 13,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      info.summary,
                                      style: MeshTheme.mono(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (signal != null)
                                      SignalText(
                                        snrDb: entry.snrDb,
                                        rssiDbm: entry.rssiDbm,
                                        fontSize: 12,
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTime(entry.timestamp),
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
                  ),
          ),
        );
      },
    );
  }

  String? _signalText(BuildContext context, BleRawLogRxEntry entry) {
    if (entry.snrDb == null && entry.rssiDbm == null) return null;
    if (entry.snrDb != null && entry.rssiDbm != null) {
      return context.l10n.chat_signalChip(
        entry.rssiDbm!,
        entry.snrDb!.toStringAsFixed(1),
      );
    }
    return context.l10n.chat_snrChip(entry.snrDb!.toStringAsFixed(1));
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  String _resolvePrefix(MeshCoreConnector connector, List<int> prefix) {
    final hex = bytesToHex(prefix, spaced: false);
    final matches = connector.allContacts
        .where(
          (c) =>
              c.publicKey.length >= prefix.length &&
              c.publicKey
                  .sublist(0, prefix.length)
                  .asMap()
                  .entries
                  .every((e) => e.value == prefix[e.key]),
        )
        .map((c) => c.name)
        .toList();
    if (matches.isEmpty) return hex;
    return '${matches.join(' | ')} ($hex)';
  }

  void _showEntryDialog(
    BuildContext context,
    MeshCoreConnector connector,
    BleRawLogRxEntry entry,
  ) {
    final l10n = context.l10n;
    final info = decodeRawRxPacket(entry.payload);
    final signal = _signalText(context, entry);
    final resolvedPath = info.pathBytes.isEmpty
        ? null
        : PathHelper.resolvePathNames(
            info.pathBytes,
            connector.allContacts,
            info.hashWidth,
          );
    final decoded = StringBuffer()
      ..writeln('${l10n.rxLog_title}: ${info.label}')
      ..writeln(info.summary);
    if (signal != null) decoded.writeln(signal);
    if (info.senderPrefix.isNotEmpty) {
      decoded.writeln(
        '${l10n.rxLog_senderLabel}: '
        '${_resolvePrefix(connector, info.senderPrefix)}',
      );
    }
    if (info.destPrefix.isNotEmpty) {
      decoded.writeln(
        '${l10n.rxLog_destLabel}: '
        '${_resolvePrefix(connector, info.destPrefix)}',
      );
    }
    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      decoded.writeln('Path: $resolvedPath');
    }
    decoded
      ..writeln()
      ..writeln(bytesToHex(entry.payload));

    Future<void> copyHex() async {
      await Clipboard.setData(
        ClipboardData(text: bytesToHex(entry.payload, spaced: false)),
      );
      if (context.mounted) {
        showDismissibleSnackBar(context, content: Text(l10n.rxLog_copied));
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${info.label} • ${_formatTime(entry.timestamp)}'),
        content: SingleChildScrollView(
          child: SelectableText(decoded.toString()),
        ),
        actions: [
          TextButton(onPressed: copyHex, child: Text(l10n.debugLog_copyLog)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}
