import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import 'mesh_nav_tile.dart';

/// Install state of one on-device model row.
enum ModelDownloadStatus { notDownloaded, downloading, ready, error }

/// One model in a [ModelDownloadList].
///
/// Callers own the download. This only describes what the row should show
/// and which action to offer.
class ModelDownloadItem {
  final String id;
  final String name;

  /// Bytes on disk, or the expected download size before anything is fetched.
  /// Zero and null both mean "size unknown" and are omitted.
  final int? sizeBytes;
  final ModelDownloadStatus status;

  /// True when this installed model is the one the feature will use.
  final bool selected;

  /// False dims the row and drops its actions, same as a disabled settings tile.
  final bool enabled;

  /// 0–1 while [status] is [ModelDownloadStatus.downloading]. Null is an
  /// indeterminate bar (size unknown, merging, or verifying).
  final double? progress;
  final int downloadedBytes;
  final int? totalBytes;

  /// Extra line under the status: a failure, a "not published" note, or
  /// "merging" / "verifying" while a download finishes.
  final String? detail;

  /// Replaces the default status word. Used for an install that started but
  /// did not finish ("Incomplete").
  final String? statusLabel;

  final VoidCallback? onDownload;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;

  const ModelDownloadItem({
    required this.id,
    required this.name,
    required this.status,
    this.sizeBytes,
    this.selected = false,
    this.enabled = true,
    this.progress,
    this.downloadedBytes = 0,
    this.totalBytes,
    this.detail,
    this.statusLabel,
    this.onDownload,
    this.onCancel,
    this.onDelete,
    this.onSelect,
  });

  bool get isActive => selected && status == ModelDownloadStatus.ready;
}

/// Shared list of on-device models: name, size, status, selection, and one
/// action (download, cancel, or remove).
///
/// Sits inside an existing card. It does not scroll; the page or dialog does.
class ModelDownloadList extends StatelessWidget {
  final List<ModelDownloadItem> items;

  /// When null, a row with an action keeps the button's own padding on the
  /// right, and a row without one uses 16.
  final EdgeInsets? rowPadding;

  const ModelDownloadList({super.key, required this.items, this.rowPadding});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 16),
          _ModelDownloadRow(item: items[i], padding: rowPadding),
        ],
      ],
    );
  }
}

class _ModelDownloadRow extends StatelessWidget {
  final ModelDownloadItem item;
  final EdgeInsets? padding;

  const _ModelDownloadRow({required this.item, required this.padding});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onTap = _rowTap();
    final actions = _actions(l10n);
    final statusWord = _statusWord(l10n);
    final sizeLabel = _sizeLabel(l10n);
    final caption = _progressCaption(l10n);

    final row = Padding(
      padding:
          padding ??
          (actions.isEmpty
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : const EdgeInsets.fromLTRB(16, 12, 4, 12)),
      child: Row(
        children: [
          _leading(scheme),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: meshTileTitleStyle(theme)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    children: [
                      if (sizeLabel != null) ...[
                        TextSpan(
                          text: sizeLabel,
                          style: MeshTheme.mono(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const TextSpan(text: ' · '),
                      ],
                      TextSpan(text: statusWord),
                      if (item.isActive) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: l10n.modelDownload_active,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.detail != null && item.detail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: item.status == ModelDownloadStatus.error
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (item.status == ModelDownloadStatus.downloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: item.progress),
                  if (caption != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: MeshTheme.mono(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );

    return Opacity(
      opacity: item.enabled ? 1 : 0.5,
      child: Semantics(
        button: onTap != null,
        enabled: item.enabled,
        selected: item.isActive,
        hint: item.status == ModelDownloadStatus.ready && item.onSelect != null
            ? l10n.modelDownload_useModel
            : null,
        child: IgnorePointer(
          ignoring: !item.enabled,
          child: InkWell(
            key: ValueKey('model-row-${item.id}'),
            onTap: onTap,
            child: row,
          ),
        ),
      ),
    );
  }

  VoidCallback? _rowTap() {
    if (!item.enabled) return null;
    if (item.status == ModelDownloadStatus.ready) return item.onSelect;
    if (item.status == ModelDownloadStatus.downloading) return null;
    return item.onDownload;
  }

  Widget _leading(ColorScheme scheme) {
    switch (item.status) {
      case ModelDownloadStatus.downloading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ModelDownloadStatus.error:
        return Icon(Icons.error_outline, size: 24, color: scheme.error);
      case ModelDownloadStatus.ready:
        return Icon(
          item.isActive ? Icons.check_circle : Icons.check_circle_outline,
          size: 24,
          color: item.isActive ? scheme.primary : scheme.onSurfaceVariant,
        );
      case ModelDownloadStatus.notDownloaded:
        return Icon(
          Icons.memory_outlined,
          size: 24,
          color: scheme.onSurfaceVariant,
        );
    }
  }

  List<Widget> _actions(AppLocalizations l10n) {
    if (!item.enabled) return const [];
    if (item.status == ModelDownloadStatus.downloading) {
      if (item.onCancel == null) return const [];
      return [
        IconButton(
          key: ValueKey('model-cancel-${item.id}'),
          tooltip: l10n.imageMessages_cancelDownload,
          onPressed: item.onCancel,
          iconSize: 24,
          icon: const Icon(Icons.close),
        ),
      ];
    }
    final actions = <Widget>[];
    if (item.status != ModelDownloadStatus.ready && item.onDownload != null) {
      actions.add(
        IconButton(
          key: ValueKey('model-download-${item.id}'),
          tooltip: l10n.imageMessages_downloadModel,
          onPressed: item.onDownload,
          iconSize: 24,
          icon: const Icon(Icons.download_outlined),
        ),
      );
    }
    if (item.onDelete != null) {
      actions.add(
        IconButton(
          key: ValueKey('model-remove-${item.id}'),
          tooltip: l10n.imageMessages_removeModel,
          onPressed: item.onDelete,
          iconSize: 24,
          icon: const Icon(Icons.delete_outline),
        ),
      );
    }
    return actions;
  }

  String _statusWord(AppLocalizations l10n) {
    final override = item.statusLabel;
    if (override != null && override.isNotEmpty) return override;
    switch (item.status) {
      case ModelDownloadStatus.notDownloaded:
        return l10n.modelDownload_notDownloaded;
      case ModelDownloadStatus.downloading:
        return l10n.modelDownload_downloading;
      case ModelDownloadStatus.ready:
        return l10n.imageMessages_modelReady;
      case ModelDownloadStatus.error:
        return l10n.modelDownload_failed;
    }
  }

  String? _sizeLabel(AppLocalizations l10n) {
    final bytes = item.sizeBytes;
    if (bytes == null || bytes <= 0) return null;
    if (bytes >= 1024 * 1024 * 1024) {
      return l10n.mapCache_sizeGigabytes(
        (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2),
      );
    }
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      final digits = mb >= 100 ? 0 : 1;
      return l10n.mapCache_sizeMegabytes(mb.toStringAsFixed(digits));
    }
    if (bytes >= 1024) {
      return l10n.mapCache_sizeKilobytes((bytes / 1024).toStringAsFixed(0));
    }
    return l10n.mapCache_sizeBytes('$bytes');
  }

  String? _progressCaption(AppLocalizations l10n) {
    if (item.status != ModelDownloadStatus.downloading) return null;
    if (item.detail != null && item.detail!.isNotEmpty) return null;
    final currentMb = item.downloadedBytes / (1024 * 1024);
    final total = item.totalBytes;
    if (total == null || total <= 0) {
      return l10n.mapCache_sizeMegabytes(currentMb.toStringAsFixed(1));
    }
    final totalMb = total / (1024 * 1024);
    final fraction = item.progress ?? (item.downloadedBytes / total);
    final percent = (fraction * 100).clamp(0, 100).toStringAsFixed(0);
    return l10n.modelDownload_progress(
      currentMb.toStringAsFixed(1),
      totalMb.toStringAsFixed(1),
      percent,
    );
  }
}
