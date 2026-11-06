import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/translation_service.dart';
import '../theme/mesh_theme.dart';
import 'mesh_nav_tile.dart';

/// [TranslationService] publishes this as `downloadFileName` while it merges
/// downloaded chunks (see translation_service.dart). The service owns the
/// value and exposes no separate state flag, so it is matched here, in one
/// place, until the service grows a proper "merging" getter.
const String _mergingChunksFileName = 'Merging chunks...';

/// On-device translation settings: feature toggles, target language, model
/// selection, model downloads and the downloaded-model list.
///
/// Watches only [AppSettingsService] and [TranslationService], so download
/// progress ticks rebuild this card and nothing else on the settings screen.
class TranslationSettingsSection extends StatelessWidget {
  const TranslationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<AppSettingsService>();
    final translationService = context.watch<TranslationService>();
    final l10n = context.l10n;
    final settings = settingsService.settings;
    final translationEnabled = settings.translationEnabled;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
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
          value: settings.translationEnabled,
          onChanged: settingsService.setTranslationEnabled,
        ),
        const Divider(height: 1, indent: 16),
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
          secondary: Icon(Icons.outgoing_mail, size: 24, color: disabledColor),
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
          onTap: () => _showTranslationLanguageDialog(context, settingsService),
        ),
        const Divider(height: 1, indent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String>(
            initialValue: settings.translationSelectedModelId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.translation_downloadedModelLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final model in settings.translationDownloadedModels)
                DropdownMenuItem(
                  value: model.id,
                  child: Text(
                    translationModelFriendlyName(model),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: settings.translationDownloadedModels.isEmpty
                ? null
                : (value) {
                    settingsService.setTranslationSelectedModelId(value);
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String>(
            initialValue: null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.translation_presetModelLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final preset in translationPresetModels)
                DropdownMenuItem(
                  value: preset.sourceUrl,
                  child: Text(
                    translationModelFriendlyName(preset),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: translationService.isBusy
                ? null
                : (value) async {
                    if (value == null) return;
                    final preset = translationPresetModels.firstWhere(
                      (entry) => entry.sourceUrl == value,
                    );
                    await _downloadTranslationModel(
                      context,
                      translationService,
                      settingsService,
                      sourceUrl: preset.sourceUrl,
                      fileName: preset.name,
                      id: preset.id,
                    );
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TranslationUrlField(
                initialValue: settings.translationModelSourceUrl ?? '',
                onChanged: settingsService.setTranslationModelSourceUrl,
                onDownload: translationService.isBusy
                    ? null
                    : (url) => _downloadTranslationModel(
                        context,
                        translationService,
                        settingsService,
                        sourceUrl: url,
                      ),
                downloadLabel: translationService.isDownloading
                    ? l10n.translation_downloading
                    : translationService.isBusy
                    ? l10n.translation_working
                    : l10n.translation_downloadModel,
                isDownloading: translationService.isDownloading,
                onCancel: translationService.cancelDownload,
                labelText: l10n.translation_manualUrlLabel,
                stopLabel: l10n.translation_stop,
              ),
              if (translationService.isDownloading) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _isMerging(translationService)
                        ? null
                        : translationService.downloadProgress,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _downloadProgressLabel(context, translationService),
                    style: MeshTheme.mono(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (settings.translationDownloadedModels.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.translation_downloadedModels,
                    style: textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                for (final model in settings.translationDownloadedModels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          model.id == settings.translationSelectedModelId
                              ? Icons.check_circle
                              : Icons.memory_outlined,
                          size: 24,
                          color: model.id == settings.translationSelectedModelId
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(MeshRadii.xs),
                            onTap: () => settingsService
                                .setTranslationSelectedModelId(model.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  translationModelFriendlyName(model),
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _downloadedModelLabel(context, model),
                                  style: MeshTheme.mono(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.translation_deleteModel,
                          onPressed: translationService.isBusy
                              ? null
                              : () => _deleteTranslationModel(
                                  context,
                                  translationService,
                                  model,
                                ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
              ],
              if (translationService.lastError != null) ...[
                const SizedBox(height: 8),
                Text(
                  translationService.lastError!,
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static bool _isMerging(TranslationService service) =>
      service.downloadFileName == _mergingChunksFileName;

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

  Future<void> _downloadTranslationModel(
    BuildContext context,
    TranslationService translationService,
    AppSettingsService settingsService, {
    required String sourceUrl,
    String? fileName,
    String? id,
  }) async {
    if (sourceUrl.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.translation_enterUrlFirst),
      );
      return;
    }
    try {
      await translationService.downloadModel(
        sourceUrl: sourceUrl,
        fileName: fileName,
        id: id,
      );
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.translation_modelDownloaded),
      );
      await settingsService.setTranslationEnabled(true);
    } on TranslationDownloadCancelled {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.translation_downloadStopped),
      );
    } catch (error) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.translation_downloadFailed(error.toString()),
        ),
      );
    }
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

  String _downloadProgressLabel(
    BuildContext context,
    TranslationService translationService,
  ) {
    final l10n = context.l10n;
    if (_isMerging(translationService)) {
      return l10n.translation_mergingChunks;
    }
    final fileName =
        translationService.downloadFileName ??
        l10n.translation_defaultModelName;
    final currentMb = translationService.downloadedBytes / (1024 * 1024);
    final totalBytes = translationService.downloadTotalBytes;
    if (totalBytes == null || totalBytes <= 0) {
      return l10n.translation_downloadProgressBytes(
        fileName,
        currentMb.toStringAsFixed(1),
      );
    }
    final totalMb = totalBytes / (1024 * 1024);
    final percent = ((translationService.downloadProgress ?? 0) * 100)
        .toStringAsFixed(0);
    return l10n.translation_downloadProgressTotal(
      fileName,
      currentMb.toStringAsFixed(1),
      totalMb.toStringAsFixed(1),
      percent,
    );
  }

  Future<void> _deleteTranslationModel(
    BuildContext context,
    TranslationService translationService,
    TranslationModelRecord model,
  ) async {
    try {
      await translationService.removeModel(model);
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.appSettings_translationModelDeleted(
            translationModelFriendlyName(model),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.appSettings_translationModelDeleteFailed('$error'),
        ),
      );
    }
  }

  String _downloadedModelLabel(
    BuildContext context,
    TranslationModelRecord model,
  ) {
    final sizeMb = model.fileSizeBytes / (1024 * 1024);
    final source = model.sourceUrl.isEmpty ? model.name : model.sourceUrl;
    return context.l10n.translation_downloadedModelDetails(
      sizeMb.toStringAsFixed(1),
      source,
    );
  }
}

/// Owns the [TextEditingController] for the manual model URL field so it
/// survives rebuilds of the parent section.
class _TranslationUrlField extends StatefulWidget {
  const _TranslationUrlField({
    required this.initialValue,
    required this.onChanged,
    required this.onDownload,
    required this.downloadLabel,
    required this.isDownloading,
    required this.onCancel,
    required this.labelText,
    required this.stopLabel,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final void Function(String url)? onDownload;
  final String downloadLabel;
  final bool isDownloading;
  final VoidCallback onCancel;
  final String labelText;
  final String stopLabel;

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
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onDownload == null
                    ? null
                    : () => widget.onDownload!(_controller.text.trim()),
                icon: const Icon(Icons.download),
                label: Text(widget.downloadLabel),
              ),
            ),
            if (widget.isDownloading) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(widget.stopLabel),
              ),
            ],
          ],
        ),
      ],
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
