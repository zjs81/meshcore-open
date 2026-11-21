import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/image_codec_support.dart';
import '../services/image_codec_service.dart';
import '../theme/mesh_theme.dart';
import 'model_download_list.dart';

/// Image-codec registry: one [ModelDownloadList] row per model.
///
/// A preset and the files it installed are the same row. The friendly name is
/// the preset label, never the on-disk graph filename.
class ImageCodecModelsSection extends StatefulWidget {
  const ImageCodecModelsSection({super.key});

  @override
  State<ImageCodecModelsSection> createState() =>
      _ImageCodecModelsSectionState();
}

class _ImageCodecModelsSectionState extends State<ImageCodecModelsSection> {
  String? _failedId;
  String? _failedDetail;

  @override
  Widget build(BuildContext context) {
    final codec = context.watch<ImageCodecService>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reason = codec.unavailableReason;
    final lastError = codec.lastError;
    final showLastError =
        lastError != null &&
        lastError.isNotEmpty &&
        lastError != 'Download stopped.' &&
        lastError != _failedDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.imageMessages_modelSectionTitle,
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(MeshRadii.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ModelDownloadList(items: _items(context, codec)),
        if (showLastError)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              lastError,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }

  List<ModelDownloadItem> _items(
    BuildContext context,
    ImageCodecService codec,
  ) {
    final models = codec.availableModels;
    final used = <ImageCodecModelRecord>{};
    final items = <ModelDownloadItem>[];

    for (final spec in imageCodecPresetModels) {
      final belonging = [
        for (final model in models)
          if (_belongsToSpec(model, spec)) model,
      ];
      used.addAll(belonging);
      final record = _preferredRecord(belonging, spec);
      items.add(_presetItem(context, codec, spec, record));
    }

    for (final model in models) {
      if (used.contains(model)) continue;
      items.add(_customItem(context, codec, model));
    }
    return items;
  }

  ModelDownloadItem _presetItem(
    BuildContext context,
    ImageCodecService codec,
    ImageCodecModelSpec spec,
    ImageCodecModelRecord? record,
  ) {
    final l10n = context.l10n;
    final blocked = spec.urlsArePlaceholders;
    final installedId = record?.id;
    final complete =
        record != null && spec.hasCompleteInstalledRecord([record]);
    final downloading = !blocked && _specIsDownloading(codec, spec);
    final verifying = downloading && _isVerifying(codec);
    final failed = !downloading && !complete && _failedId == spec.id;
    final selectedId = codec.selectedModel?.id;
    final selected =
        complete && (selectedId == spec.id || selectedId == installedId);
    final busy = codec.isBusy || codec.isDownloading;

    final ModelDownloadStatus status;
    String? statusLabel;
    if (downloading) {
      status = ModelDownloadStatus.downloading;
    } else if (complete) {
      status = ModelDownloadStatus.ready;
    } else if (failed) {
      status = ModelDownloadStatus.error;
    } else {
      status = ModelDownloadStatus.notDownloaded;
      if (record != null && !blocked) {
        statusLabel = l10n.modelDownload_incomplete;
      }
    }

    final size = record != null && record.fileSizeBytes > 0
        ? record.fileSizeBytes
        : spec.totalSizeBytes;

    return ModelDownloadItem(
      id: spec.id,
      name: spec.label,
      sizeBytes: size > 0 ? size : null,
      status: status,
      statusLabel: statusLabel,
      selected: selected,
      enabled: !blocked,
      progress: verifying ? null : codec.downloadProgress,
      downloadedBytes: downloading ? codec.downloadedBytes : 0,
      totalBytes: downloading ? codec.downloadTotalBytes : null,
      detail: blocked
          ? l10n.imageMessages_modelNotPublished
          : verifying
          ? l10n.modelDownload_verifying
          : failed
          ? _failedDetail
          : null,
      onDownload: !blocked && !complete && !codec.isDownloading
          ? () => _download(spec)
          : null,
      onCancel: downloading ? codec.cancelDownload : null,
      onDelete: record != null && !busy ? () => _delete(record) : null,
      onSelect: complete && !selected && !busy
          ? () => codec.setSelectedModelId(installedId ?? spec.id)
          : null,
    );
  }

  ModelDownloadItem _customItem(
    BuildContext context,
    ImageCodecService codec,
    ImageCodecModelRecord model,
  ) {
    final l10n = context.l10n;
    final downloading = _recordIsDownloading(codec, model);
    final verifying = downloading && _isVerifying(codec);
    final ready = model.localPath.isNotEmpty && !downloading;
    final busy = codec.isBusy || codec.isDownloading;
    final selected = ready && codec.selectedModel?.id == model.id;

    return ModelDownloadItem(
      id: model.id,
      name: imageCodecModelFriendlyName(model),
      sizeBytes: model.fileSizeBytes > 0 ? model.fileSizeBytes : null,
      status: downloading
          ? ModelDownloadStatus.downloading
          : ready
          ? ModelDownloadStatus.ready
          : ModelDownloadStatus.notDownloaded,
      selected: selected,
      progress: verifying ? null : codec.downloadProgress,
      downloadedBytes: downloading ? codec.downloadedBytes : 0,
      totalBytes: downloading ? codec.downloadTotalBytes : null,
      detail: verifying ? l10n.modelDownload_verifying : null,
      onCancel: downloading ? codec.cancelDownload : null,
      onDelete: !busy ? () => _delete(model) : null,
      onSelect: ready && !selected && !busy
          ? () => codec.setSelectedModelId(model.id)
          : null,
    );
  }

  bool _specIsDownloading(ImageCodecService codec, ImageCodecModelSpec spec) {
    if (!codec.isDownloading) return false;
    final name = _downloadFileName(codec);
    if (name == null) return imageCodecPresetModels.length == 1;
    return spec.assets.any((asset) => asset.fileName == name);
  }

  bool _recordIsDownloading(
    ImageCodecService codec,
    ImageCodecModelRecord model,
  ) {
    if (!codec.isDownloading) return false;
    final name = _downloadFileName(codec);
    if (name == null) return false;
    return model.name == name || model.assetFileNames.contains(name);
  }

  bool _isVerifying(ImageCodecService codec) =>
      codec.downloadFileName?.startsWith('Verifying ') ?? false;

  String? _downloadFileName(ImageCodecService codec) {
    final raw = codec.downloadFileName;
    if (raw == null || raw.isEmpty) return null;
    const prefix = 'Verifying ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  Future<void> _download(ImageCodecModelSpec spec) async {
    setState(() {
      _failedId = null;
      _failedDetail = null;
    });
    final l10n = context.l10n;
    try {
      await context.read<ImageCodecService>().downloadPresetModel(spec);
    } on ImageCodecDownloadCancelled {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.translation_downloadStopped),
      );
    } catch (error) {
      if (!mounted) return;
      final message = l10n.imageMessages_downloadFailedWithError('$error');
      setState(() {
        _failedId = spec.id;
        _failedDetail = message;
      });
      showDismissibleSnackBar(context, content: Text(message));
    }
  }

  Future<void> _delete(ImageCodecModelRecord model) async {
    final l10n = context.l10n;
    try {
      await context.read<ImageCodecService>().removeModel(model);
    } catch (error) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.modelDownload_removeFailed('$error')),
      );
    }
  }
}

bool _belongsToSpec(ImageCodecModelRecord model, ImageCodecModelSpec spec) {
  if (model.id == spec.id || model.name == spec.fileName) return true;
  for (final asset in spec.assets) {
    if (asset.fileName == model.name) return true;
  }
  return false;
}

ImageCodecModelRecord? _preferredRecord(
  List<ImageCodecModelRecord> models,
  ImageCodecModelSpec spec,
) {
  for (final model in models) {
    if (spec.hasCompleteInstalledRecord([model])) return model;
  }
  for (final model in models) {
    if (model.id == spec.id) return model;
  }
  if (models.isEmpty) return null;
  return models.first;
}
