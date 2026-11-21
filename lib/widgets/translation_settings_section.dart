import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/translation_service.dart';
import 'mesh_nav_tile.dart';
import 'model_download_list.dart';
import 'settings_reveal.dart';

/// [TranslationService] publishes this as `downloadFileName` while it merges
/// downloaded chunks (see translation_service.dart). The service owns the
/// value and exposes no separate state flag, so it is matched here, in one
/// place, until the service grows a proper "merging" getter.
const String _mergingChunksFileName = 'Merging chunks...';

/// On-device translation settings: feature toggles, target language, and the
/// shared model list.
///
/// [_TranslationModels] watches [TranslationService], so download progress
/// rebuilds the model rows and not the toggles above them.
class TranslationSettingsSection extends StatelessWidget {
  const TranslationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<AppSettingsService>();
    final l10n = context.l10n;
    final settings = settingsService.settings;
    final translationEnabled = settings.translationEnabled;
    final theme = Theme.of(context);
    final disabledColor = translationEnabled ? null : theme.disabledColor;
    const tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: tilePadding,
          secondary: const Icon(Icons.translate, size: 24),
          title: Text(l10n.translation_enableTitle),
          subtitle: Text(l10n.translation_enableSubtitle),
          value: translationEnabled,
          onChanged: settingsService.setTranslationEnabled,
        ),
        SettingsReveal(
          visible: translationEnabled,
          children: [
            SwitchListTile(
              contentPadding: tilePadding,
              secondary: Icon(
                Icons.auto_awesome_outlined,
                size: 24,
                color: disabledColor,
              ),
              title: Text(
                l10n.translation_autoIncomingTitle,
                style: TextStyle(color: disabledColor),
              ),
              subtitle: Text(
                l10n.translation_autoIncomingSubtitle,
                style: TextStyle(color: disabledColor),
              ),
              value: settings.autoTranslateIncomingMessages,
              onChanged: translationEnabled
                  ? settingsService.setAutoTranslateIncomingMessages
                  : null,
            ),
            const Divider(height: 1, indent: 16),
            SwitchListTile(
              contentPadding: tilePadding,
              secondary: Icon(
                Icons.outgoing_mail,
                size: 24,
                color: disabledColor,
              ),
              title: Text(
                l10n.translation_composerTitle,
                style: TextStyle(color: disabledColor),
              ),
              subtitle: Text(
                l10n.translation_composerSubtitle,
                style: TextStyle(color: disabledColor),
              ),
              value: settings.composerTranslationEnabled,
              onChanged: translationEnabled
                  ? settingsService.setComposerTranslationEnabled
                  : null,
            ),
            const Divider(height: 1, indent: 16),
            MeshNavTile(
              icon: Icons.language,
              title: l10n.translation_targetLanguage,
              subtitle: _translationLanguageLabel(
                context,
                settings.translationTargetLanguageCode,
              ),
              onTap: translationEnabled
                  ? () =>
                        _showTranslationLanguageDialog(context, settingsService)
                  : null,
            ),
            const Divider(height: 1, indent: 16),
            const _TranslationModels(),
          ],
        ),
      ],
    );
  }

  void _showTranslationLanguageDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TranslationLanguageDialogContent(
        currentLanguageCode:
            settingsService.settings.translationTargetLanguageCode,
        onLanguageSelected: (value) {
          settingsService.setTranslationTargetLanguageCode(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _translationLanguageLabel(BuildContext context, String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return context.l10n.translation_useAppLanguage;
    }
    for (final option in supportedTranslationLanguages) {
      if (option.code == languageCode) {
        return option.label;
      }
    }
    return languageCode.toUpperCase();
  }
}

class _PendingDownload {
  final String id;
  final String name;
  final String sourceUrl;
  final String? fileName;
  final String? modelId;

  const _PendingDownload({
    required this.id,
    required this.name,
    required this.sourceUrl,
    this.fileName,
    this.modelId,
  });
}

/// Preset rows, installed models, and the manual URL field.
class _TranslationModels extends StatefulWidget {
  const _TranslationModels();

  @override
  State<_TranslationModels> createState() => _TranslationModelsState();
}

class _TranslationModelsState extends State<_TranslationModels> {
  _PendingDownload? _pending;
  String? _failedId;
  String? _failedDetail;

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<AppSettingsService>();
    final translationService = context.watch<TranslationService>();
    final l10n = context.l10n;
    final settings = settingsService.settings;
    final scheme = Theme.of(context).colorScheme;
    final lastError = translationService.lastError;
    final showLastError =
        lastError != null &&
        lastError.isNotEmpty &&
        lastError != 'Download stopped.' &&
        lastError != translationService.failedDownloadError &&
        lastError != _failedDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModelDownloadList(
          items: _items(l10n, settings, settingsService, translationService),
        ),
        const Divider(height: 1, indent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _TranslationUrlField(
            initialValue: settings.translationModelSourceUrl ?? '',
            onChanged: settingsService.setTranslationModelSourceUrl,
            onDownload: translationService.isBusy
                ? null
                : (url) => _download(sourceUrl: url),
            labelText: l10n.translation_manualUrlLabel,
            downloadTooltip: l10n.imageMessages_downloadModel,
          ),
        ),
        if (showLastError)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              lastError,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }

  List<ModelDownloadItem> _items(
    AppLocalizations l10n,
    AppSettings settings,
    AppSettingsService settingsService,
    TranslationService service,
  ) {
    final downloaded = settings.translationDownloadedModels;
    final selectedId = settings.translationSelectedModelId;
    final pending = _pending;
    final used = <TranslationModelRecord>{};
    final items = <ModelDownloadItem>[];
    var pendingShown = false;

    final serviceFailedError = service.failedDownloadError;

    bool targets(String id, String sourceUrl, String name) {
      if (pending == null) return false;
      if (pending.id == id || pending.modelId == id) return true;
      if (sourceUrl.isNotEmpty && pending.sourceUrl == sourceUrl) return true;
      if (name.isNotEmpty && pending.name == name) return true;
      return false;
    }

    bool matchesServiceFailure(
      String id,
      String sourceUrl,
      String? fileName,
      String? installedName,
    ) {
      if (serviceFailedError == null) return false;
      if (service.failedDownloadModelId == id) return true;
      if (sourceUrl.isNotEmpty &&
          service.failedDownloadSourceUrl == sourceUrl) {
        return true;
      }
      final failedFile = service.failedDownloadFileName;
      if (failedFile != null &&
          failedFile.isNotEmpty &&
          (failedFile == fileName || failedFile == installedName)) {
        return true;
      }
      return false;
    }

    ModelDownloadItem buildItem({
      required String id,
      required String name,
      required String sourceUrl,
      required String? fileName,
      required String? modelId,
      required TranslationModelRecord? installed,
    }) {
      if (installed != null) used.add(installed);
      final downloading =
          service.isDownloading &&
          (targets(id, sourceUrl, name) ||
              _fileNamesThisDownload(service, fileName, installed?.name));
      final failed =
          !downloading &&
          (_failedId == id ||
              (_failedId == null &&
                  matchesServiceFailure(
                    id,
                    sourceUrl,
                    fileName,
                    installed?.name,
                  )));
      if (downloading || failed) pendingShown = true;
      final merging = downloading && _isMerging(service);
      final busy = service.isBusy;
      final installedModel = installed;
      final failureDetail = _failedId == id
          ? _failedDetail
          : (serviceFailedError != null
                ? l10n.translation_downloadFailed(serviceFailedError)
                : null);

      return ModelDownloadItem(
        id: id,
        name: name,
        sizeBytes: installedModel != null && installedModel.fileSizeBytes > 0
            ? installedModel.fileSizeBytes
            : null,
        status: downloading
            ? ModelDownloadStatus.downloading
            : failed
            ? ModelDownloadStatus.error
            : installedModel != null
            ? ModelDownloadStatus.ready
            : ModelDownloadStatus.notDownloaded,
        selected:
            installedModel != null &&
            !downloading &&
            installedModel.id == selectedId,
        detail: merging
            ? l10n.translation_mergingChunks
            : failed
            ? failureDetail
            : null,
        progress: downloading && !merging ? service.downloadProgress : null,
        downloadedBytes: downloading ? service.downloadedBytes : 0,
        totalBytes: downloading ? service.downloadTotalBytes : null,
        onDownload: !busy && installedModel == null
            ? () => _download(
                sourceUrl: sourceUrl,
                fileName: fileName,
                id: modelId,
              )
            : null,
        onCancel: downloading ? service.cancelDownload : null,
        onDelete: installedModel != null && !busy
            ? () => _delete(service, installedModel)
            : null,
        onSelect:
            installedModel != null &&
                !downloading &&
                installedModel.id != selectedId &&
                !busy
            ? () => settingsService.setTranslationSelectedModelId(
                installedModel.id,
              )
            : null,
      );
    }

    for (final preset in translationPresetModels) {
      TranslationModelRecord? installed;
      for (final model in downloaded) {
        if (model.id == preset.id ||
            (preset.sourceUrl.isNotEmpty &&
                model.sourceUrl == preset.sourceUrl) ||
            (preset.name.isNotEmpty && model.name == preset.name)) {
          installed = model;
          break;
        }
      }
      items.add(
        buildItem(
          id: preset.id,
          name: translationModelFriendlyName(preset),
          sourceUrl: preset.sourceUrl,
          fileName: preset.name,
          modelId: preset.id,
          installed: installed,
        ),
      );
    }

    for (final model in downloaded) {
      if (used.contains(model)) continue;
      items.add(
        buildItem(
          id: model.id,
          name: translationModelFriendlyName(model),
          sourceUrl: model.sourceUrl,
          fileName: model.name,
          modelId: model.id,
          installed: model,
        ),
      );
    }

    if (!pendingShown && service.isDownloading) {
      items.add(_inProgressItem(l10n, service));
    } else if (pending != null && !pendingShown && _failedId == pending.id) {
      items.add(
        ModelDownloadItem(
          id: pending.id,
          name: pending.name,
          status: ModelDownloadStatus.error,
          detail: _failedDetail,
          onDownload: service.isBusy
              ? null
              : () => _download(
                  sourceUrl: pending.sourceUrl,
                  fileName: pending.fileName,
                  id: pending.modelId,
                ),
        ),
      );
    } else if (!pendingShown &&
        !service.isDownloading &&
        serviceFailedError != null &&
        service.failedDownloadSourceUrl != null) {
      final failedUrl = service.failedDownloadSourceUrl!;
      final failedFile = service.failedDownloadFileName;
      final failedModelId = service.failedDownloadModelId;
      final id = (failedModelId != null && failedModelId.isNotEmpty)
          ? failedModelId
          : failedUrl.isNotEmpty
          ? failedUrl
          : (failedFile ?? 'download');
      items.add(
        ModelDownloadItem(
          id: id,
          name: _displayName(failedUrl, failedFile, failedModelId),
          status: ModelDownloadStatus.error,
          detail: l10n.translation_downloadFailed(serviceFailedError),
          onDownload: service.isBusy
              ? null
              : () => _download(
                  sourceUrl: failedUrl,
                  fileName: failedFile,
                  id: failedModelId,
                ),
        ),
      );
    }

    return items;
  }

  /// True when this row is the file [service] is fetching, including while
  /// its displayed filename is the merge status.
  bool _fileNamesThisDownload(
    TranslationService service,
    String? fileName,
    String? installedName,
  ) {
    bool matches(String? candidate) {
      if (candidate == null || candidate.isEmpty) return false;
      if (candidate == _mergingChunksFileName) return false;
      return candidate == fileName || candidate == installedName;
    }

    return matches(service.downloadFileName) ||
        matches(service.downloadTargetFileName);
  }

  /// Row for a download whose page state was discarded, or that has no
  /// preset or installed row yet. The service keeps the URL and file name.
  ModelDownloadItem _inProgressItem(
    AppLocalizations l10n,
    TranslationService service,
  ) {
    final sourceUrl = service.downloadSourceUrl ?? '';
    final rawName = service.downloadTargetFileName ?? service.downloadFileName;
    final fileName = rawName == _mergingChunksFileName ? null : rawName;
    final modelId = service.downloadModelId;
    final id = (modelId != null && modelId.isNotEmpty)
        ? modelId
        : sourceUrl.isNotEmpty
        ? sourceUrl
        : (fileName ?? 'download');
    final merging = _isMerging(service);
    return ModelDownloadItem(
      id: id,
      name: _displayName(sourceUrl, fileName, modelId),
      status: ModelDownloadStatus.downloading,
      detail: merging ? l10n.translation_mergingChunks : null,
      progress: merging ? null : service.downloadProgress,
      downloadedBytes: service.downloadedBytes,
      totalBytes: service.downloadTotalBytes,
      onCancel: service.cancelDownload,
    );
  }

  bool _isMerging(TranslationService service) =>
      service.downloadFileName == _mergingChunksFileName;

  Future<void> _download({
    required String sourceUrl,
    String? fileName,
    String? id,
  }) async {
    final trimmed = sourceUrl.trim();
    if (trimmed.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.translation_enterUrlFirst),
      );
      return;
    }
    final pending = _PendingDownload(
      id: id ?? trimmed,
      name: _displayName(trimmed, fileName, id),
      sourceUrl: trimmed,
      fileName: fileName,
      modelId: id,
    );
    setState(() {
      _pending = pending;
      _failedId = null;
      _failedDetail = null;
    });
    final settingsService = context.read<AppSettingsService>();
    final translationService = context.read<TranslationService>();
    try {
      await translationService.downloadModel(
        sourceUrl: trimmed,
        fileName: fileName,
        id: id,
      );
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failedId = null;
        _failedDetail = null;
      });
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.translation_modelDownloaded),
      );
      await settingsService.setTranslationEnabled(true);
    } on TranslationDownloadCancelled {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failedId = null;
        _failedDetail = null;
      });
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.translation_downloadStopped),
      );
    } catch (error) {
      if (!mounted) return;
      final message = context.l10n.translation_downloadFailed('$error');
      setState(() {
        _failedId = pending.id;
        _failedDetail = message;
      });
      showDismissibleSnackBar(context, content: Text(message));
    }
  }

  Future<void> _delete(
    TranslationService translationService,
    TranslationModelRecord model,
  ) async {
    try {
      await translationService.removeModel(model);
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.appSettings_translationModelDeleted(
            translationModelFriendlyName(model),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.appSettings_translationModelDeleteFailed('$error'),
        ),
      );
    }
  }

  String _displayName(String sourceUrl, String? fileName, String? id) {
    for (final preset in translationPresetModels) {
      if (preset.id == id || preset.sourceUrl == sourceUrl) {
        return translationModelFriendlyName(preset);
      }
    }
    final name = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : _fileNameFromUrl(sourceUrl);
    return translationModelFriendlyName(
      TranslationModelRecord(
        id: id ?? name,
        name: name,
        sourceUrl: sourceUrl,
        localPath: '',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        fileSizeBytes: 0,
      ),
    );
  }

  String _fileNameFromUrl(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.pathSegments.isEmpty) {
      return context.l10n.translation_defaultModelName;
    }
    final last = uri.pathSegments.last.trim();
    if (last.isEmpty) return context.l10n.translation_defaultModelName;
    return last;
  }
}

/// Owns the [TextEditingController] for the manual model URL field so it
/// survives rebuilds of the parent section.
class _TranslationUrlField extends StatefulWidget {
  const _TranslationUrlField({
    required this.initialValue,
    required this.onChanged,
    required this.onDownload,
    required this.labelText,
    required this.downloadTooltip,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final void Function(String url)? onDownload;
  final String labelText;
  final String downloadTooltip;

  @override
  State<_TranslationUrlField> createState() => _TranslationUrlFieldState();
}

class _TranslationUrlFieldState extends State<_TranslationUrlField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.url,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: widget.downloadTooltip,
          onPressed: widget.onDownload == null
              ? null
              : () => widget.onDownload!(_controller.text.trim()),
          icon: const Icon(Icons.download_outlined),
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onDownload == null
          ? null
          : (value) => widget.onDownload!(value.trim()),
    );
  }
}

/// Dialog content for choosing the translation target language.
/// Owns the search [TextEditingController] so it is properly disposed.
class _TranslationLanguageDialogContent extends StatefulWidget {
  const _TranslationLanguageDialogContent({
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  });

  final String? currentLanguageCode;
  final ValueChanged<String?> onLanguageSelected;

  @override
  State<_TranslationLanguageDialogContent> createState() =>
      _TranslationLanguageDialogContentState();
}

class _TranslationLanguageDialogContentState
    extends State<_TranslationLanguageDialogContent> {
  late final TextEditingController _searchController;
  List<TranslationLanguageOption> _filtered = supportedTranslationLanguages;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.translation_targetLanguage),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final normalized = value.trim().toLowerCase();
                setState(() {
                  _filtered = supportedTranslationLanguages.where((option) {
                    return option.label.toLowerCase().contains(normalized) ||
                        option.code.toLowerCase().contains(normalized);
                  }).toList();
                });
              },
            ),
            const SizedBox(height: 12),
            Flexible(
              child: RadioGroup<String?>(
                groupValue: widget.currentLanguageCode,
                onChanged: (value) {
                  widget.onLanguageSelected(value);
                },
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    RadioListTile<String?>(
                      value: null,
                      title: Text(context.l10n.translation_useAppLanguage),
                    ),
                    for (final option in _filtered)
                      RadioListTile<String?>(
                        value: option.code,
                        title: Text(option.label),
                        subtitle: Text(option.code.toUpperCase()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_close),
        ),
      ],
    );
  }
}
