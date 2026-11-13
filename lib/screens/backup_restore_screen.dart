import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/image_codec_support.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/backup_service.dart';
import '../services/image_codec_service.dart';
import '../services/translation_service.dart';
import '../services/message_filter/message_filter_service.dart';
import '../utils/platform_info.dart';
import '../utils/share_origin.dart';
import '../widgets/app_bar.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/sync_progress_overlay.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  static const int _maxImportBytes = 100 * 1024 * 1024;
  static const _backupService = BackupService();
  static const _fileType = XTypeGroup(
    label: 'MeshCore backup',
    extensions: ['json'],
    mimeTypes: ['application/json'],
  );
  static const Set<BackupItem> _defaultUncheckedItems = {
    BackupItem.privateKey,
    BackupItem.ipfsKey,
    BackupItem.stadiaMapKey,
  };
  static const Set<BackupItem> _deviceStoredItems = {
    BackupItem.deviceName,
    BackupItem.publicKey,
    BackupItem.radioSettings,
    BackupItem.location,
    BackupItem.contactSettings,
    BackupItem.privacySettings,
    BackupItem.contacts,
    BackupItem.channels,
  };
  static const Set<BackupItem> _defaultUncheckedOnRestore = {
    ..._defaultUncheckedItems,
    ..._deviceStoredItems,
  };
  final _passwordController = TextEditingController();
  final Set<BackupItem> _selectedItems = BackupItem.values
      .where((item) => !_defaultUncheckedItems.contains(item))
      .toSet();
  Set<BackupItem>? _availableItems;
  String? _importContents;
  String? _importFileName;
  Timer? _inspectionTimer;
  int _inspectionGeneration = 0;
  bool _hasInitializedImportSelection = false;
  bool _busy = false;

  @override
  void dispose() {
    _inspectionTimer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          l10n.backupRestore_title,
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
            SectionHeader(l10n.backupRestore_import),
            MeshCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _selectImportFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _importFileName ?? l10n.backupRestore_selectImportFile,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) => _scheduleImportInspection(),
                    decoration: InputDecoration(
                      labelText: l10n.backupRestore_password,
                      helperText:
                          _importContents != null &&
                              _availableItems?.isEmpty == true
                          ? l10n.backupRestore_importUnavailable
                          : l10n.backupRestore_passwordHelp,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(l10n.backupRestore_items),
            MeshCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _groupTile(
                    title: l10n.backupRestore_nodeSettings,
                    icon: Icons.router_outlined,
                    items: [
                      (BackupItem.deviceName, l10n.backupRestore_deviceName),
                      (BackupItem.privateKey, l10n.backupRestore_privateKey),
                      (BackupItem.publicKey, l10n.backupRestore_publicKey),
                      (
                        BackupItem.radioSettings,
                        l10n.backupRestore_radioSettings,
                      ),
                      (BackupItem.regions, l10n.backupRestore_regions),
                    ],
                  ),
                  const Divider(height: 1, indent: 16),
                  _groupTile(
                    title: l10n.backupRestore_locationSettings,
                    icon: Icons.location_on_outlined,
                    items: [
                      (BackupItem.location, l10n.backupRestore_location),
                      (
                        BackupItem.contactSettings,
                        l10n.backupRestore_contactSettings,
                      ),
                      (
                        BackupItem.privacySettings,
                        l10n.backupRestore_privacySettings,
                      ),
                    ],
                  ),
                  const Divider(height: 1, indent: 16),
                  _groupTile(
                    title: l10n.backupRestore_appSettings,
                    icon: Icons.settings_outlined,
                    items: [
                      (BackupItem.appSettings, l10n.backupRestore_appSettings),
                      (BackupItem.ipfsKey, l10n.backupRestore_ipfsKey),
                      (
                        BackupItem.stadiaMapKey,
                        l10n.backupRestore_stadiaMapKey,
                      ),
                    ],
                  ),
                  const Divider(height: 1, indent: 16),
                  _groupTile(
                    title: l10n.backupRestore_contacts,
                    icon: Icons.contacts_outlined,
                    items: [
                      (BackupItem.contacts, l10n.backupRestore_contactsData),
                      (
                        BackupItem.perContactSettings,
                        l10n.backupRestore_perContactSettings,
                      ),
                      (
                        BackupItem.contactGroups,
                        l10n.backupRestore_contactGroups,
                      ),
                      (
                        BackupItem.contactHistory,
                        l10n.backupRestore_contactHistory,
                      ),
                    ],
                  ),
                  const Divider(height: 1, indent: 16),
                  _itemTile(
                    BackupItem.discoveredContacts,
                    l10n.backupRestore_discoveredContacts,
                    Icons.person_search_outlined,
                  ),
                  const Divider(height: 1, indent: 16),
                  _groupTile(
                    title: l10n.backupRestore_channels,
                    icon: Icons.forum_outlined,
                    items: [
                      (BackupItem.channels, l10n.backupRestore_channelsData),
                      (
                        BackupItem.channelFilters,
                        l10n.backupRestore_channelFilters,
                      ),
                      (
                        BackupItem.channelSettings,
                        l10n.backupRestore_channelSettings,
                      ),
                      (BackupItem.communities, l10n.backupRestore_communities),
                      (
                        BackupItem.channelHistory,
                        l10n.backupRestore_channelHistory,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FilledButton.icon(
                onPressed:
                    _busy ||
                        _selectedItems.isEmpty ||
                        (_importContents != null && _availableItems == null)
                    ? null
                    : _runAction,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _importContents == null
                            ? Icons.backup_outlined
                            : Icons.restore_outlined,
                      ),
                label: Text(
                  _importContents == null
                      ? l10n.backupRestore_backup
                      : l10n.backupRestore_restore,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTile({
    required String title,
    required IconData icon,
    required List<(BackupItem, String)> items,
  }) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: true,
      visualDensity: VisualDensity.compact,
      children: [for (final item in items) _itemTile(item.$1, item.$2)],
    );
  }

  Widget _itemTile(BackupItem item, String title, [IconData? icon]) {
    final available =
        _availableItems == null || _availableItems!.contains(item);
    return CheckboxListTile(
      value: _selectedItems.contains(item),
      dense: true,
      visualDensity: VisualDensity.compact,
      onChanged: _busy || !available
          ? null
          : (selected) => setState(() {
              if (selected == true) {
                _selectedItems.add(item);
              } else {
                _selectedItems.remove(item);
              }
            }),
      secondary: icon == null ? null : Icon(icon),
      title: Text(title),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Future<void> _selectImportFile() async {
    final l10n = context.l10n;
    try {
      final file = await openFile(acceptedTypeGroups: const [_fileType]);
      if (file == null) return;
      if (await file.length() > _maxImportBytes) {
        _showMessage(l10n.backupRestore_fileTooLarge);
        return;
      }
      final contents = utf8.decode(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _importContents = contents;
        _importFileName = file.name;
        _availableItems = null;
        _selectedItems.clear();
        _hasInitializedImportSelection = false;
      });
      await _inspectImport();
    } catch (error) {
      if (mounted) {
        _showMessage(l10n.backupRestore_failed(error.toString()));
      }
    }
  }

  void _scheduleImportInspection() {
    _inspectionTimer?.cancel();
    _inspectionTimer = Timer(const Duration(milliseconds: 350), _inspectImport);
  }

  Future<void> _inspectImport() async {
    final contents = _importContents;
    if (contents == null) return;
    final generation = ++_inspectionGeneration;
    try {
      final info = await _backupService.inspectImport(
        contents: contents,
        password: _passwordController.text,
      );
      if (!mounted || generation != _inspectionGeneration) return;
      setState(() {
        _availableItems = info.availableItems;
        if (!_hasInitializedImportSelection) {
          _selectedItems
            ..clear()
            ..addAll(
              info.availableItems.where(
                (item) => !_defaultUncheckedOnRestore.contains(item),
              ),
            );
          _hasInitializedImportSelection = true;
        } else {
          _selectedItems.retainAll(info.availableItems);
        }
      });
    } catch (_) {
      if (!mounted || generation != _inspectionGeneration) return;
      setState(() {
        _availableItems = <BackupItem>{};
        _selectedItems.clear();
      });
    }
  }

  Future<void> _runAction() async {
    if (_selectedItems.isEmpty) {
      _showMessage(context.l10n.backupRestore_selectAtLeastOne);
      return;
    }
    if (_importContents != null) {
      await _restore();
    } else {
      await _createBackup();
    }
  }

  Future<void> _createBackup() async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    final shareOrigin = shareOriginOf(context);
    setState(() => _busy = true);
    try {
      final contents = await _backupService.createBackup(
        items: Set<BackupItem>.of(_selectedItems),
        connector: connector,
        settings: context.read<AppSettingsService>().settings,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final deviceName = (connector.selfName ?? '')
          .trim()
          .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'^\.+'), '')
          .replaceAll(RegExp(r'[. ]+$'), '');
      final filename =
          'meshcore-open_${deviceName.isEmpty ? 'radio' : deviceName}_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(contents)),
        name: filename,
        mimeType: 'application/json',
      );
      if (PlatformInfo.isWeb) {
        await file.saveTo(filename);
      } else if (PlatformInfo.isDesktop) {
        final location = await getSaveLocation(
          suggestedName: filename,
          acceptedTypeGroups: const [_fileType],
        );
        if (location == null) return;
        await file.saveTo(location.path);
      } else {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [file],
            fileNameOverrides: [filename],
            sharePositionOrigin: shareOrigin,
          ),
        );
        if (result.status == ShareResultStatus.dismissed) return;
      }
      if (mounted) _showMessage(l10n.backupRestore_backupComplete);
    } catch (error) {
      if (mounted) {
        _showMessage(l10n.backupRestore_failed(error.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    final appSettingsService = context.read<AppSettingsService>();
    final messageFilterService = context.read<MessageFilterService>();
    final translationService = context.read<TranslationService>();
    final imageCodecService = context.read<ImageCodecService>();
    final needsKeyConfirmation = _selectedItems.contains(BackupItem.privateKey);
    if (needsKeyConfirmation && !await _confirmIdentityReplacement()) return;
    setState(() => _busy = true);
    try {
      await _backupService.restoreBackup(
        contents: _importContents!,
        password: _passwordController.text,
        items: Set<BackupItem>.of(_selectedItems),
        connector: connector,
        appSettingsService: appSettingsService,
      );
      if (_selectedItems.any(
        (item) =>
            item == BackupItem.appSettings ||
            item == BackupItem.ipfsKey ||
            item == BackupItem.stadiaMapKey,
      )) {
        await appSettingsService.loadSettings();
        if (_selectedItems.contains(BackupItem.appSettings)) {
          await _offerMissingModels(
            appSettingsService,
            translationService,
            imageCodecService,
          );
        }
      }
      if (_selectedItems.contains(BackupItem.channelFilters)) {
        await messageFilterService.load();
      }
      if (mounted) {
        _showMessage(l10n.backupRestore_restoreComplete);
        setState(() {
          _importContents = null;
          _importFileName = null;
          _availableItems = null;
          _selectedItems
            ..clear()
            ..addAll(
              BackupItem.values.where(
                (item) => !_defaultUncheckedItems.contains(item),
              ),
            );
          _hasInitializedImportSelection = false;
        });
      }
    } catch (error) {
      if (mounted) {
        _showMessage(l10n.backupRestore_failed(error.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerMissingModels(
    AppSettingsService appSettingsService,
    TranslationService translationService,
    ImageCodecService imageCodecService,
  ) async {
    if (PlatformInfo.isWeb) return;
    final settings = appSettingsService.settings;
    final translationId = settings.translationSelectedModelId;
    final imageCodecId = settings.imageCodecSelectedModelId;

    TranslationModelRecord? translationModel;
    for (final model in settings.translationDownloadedModels) {
      if (model.id == translationId) {
        translationModel = model;
        break;
      }
    }
    for (final model in translationPresetModels) {
      if (model.id == translationId) {
        translationModel ??= model;
        break;
      }
    }
    if (translationModel == null &&
        translationId != null &&
        settings.translationModelSourceUrl != null) {
      final uri = Uri.tryParse(settings.translationModelSourceUrl!);
      final pathSegments = uri?.pathSegments ?? const <String>[];
      final fileName = pathSegments.isEmpty ? null : pathSegments.last;
      translationModel = TranslationModelRecord(
        id: translationId,
        name: fileName?.isNotEmpty == true ? fileName! : translationId,
        sourceUrl: settings.translationModelSourceUrl!,
        localPath: '',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        fileSizeBytes: 0,
      );
    }

    ImageCodecModelRecord? imageCodecModel;
    for (final model in settings.imageCodecDownloadedModels) {
      if (model.id == imageCodecId) {
        imageCodecModel = model;
        break;
      }
    }
    ImageCodecModelSpec? imageCodecSpec;
    for (final spec in imageCodecPresetModels) {
      if (spec.id == imageCodecId) {
        imageCodecSpec = spec;
        break;
      }
    }
    if (imageCodecModel == null && imageCodecSpec != null) {
      final graph = imageCodecSpec.graph;
      imageCodecModel = ImageCodecModelRecord(
        id: imageCodecSpec.id,
        name: graph.fileName,
        sourceUrl: graph.sourceUrl,
        localPath: '',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        fileSizeBytes: imageCodecSpec.totalSizeBytes,
        assetFileNames: [
          for (final asset in imageCodecSpec.assets) asset.fileName,
        ],
        bundleVersion: kImageCodecBundleVersion,
      );
    } else if (imageCodecModel == null &&
        imageCodecId != null &&
        settings.imageCodecModelSourceUrl != null) {
      final uri = Uri.tryParse(settings.imageCodecModelSourceUrl!);
      final pathSegments = uri?.pathSegments ?? const <String>[];
      final fileName = pathSegments.isEmpty ? null : pathSegments.last;
      imageCodecModel = ImageCodecModelRecord(
        id: imageCodecId,
        name: fileName?.isNotEmpty == true ? fileName! : imageCodecId,
        sourceUrl: settings.imageCodecModelSourceUrl!,
        localPath: '',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        fileSizeBytes: 0,
      );
    }

    await translationService.refreshDownloadedModels(clearMissing: true);
    await imageCodecService.refreshDownloadedModels(clearMissing: true);

    final translationRequest = translationModel;
    final translationMissing =
        translationRequest != null &&
        !translationService.availableModels.any(
          (model) =>
              model.id == translationRequest.id ||
              model.name == translationRequest.name,
        );
    ImageCodecModelRecord? installedCodec;
    if (imageCodecModel != null) {
      for (final model in imageCodecService.availableModels) {
        if (model.id == imageCodecModel.id ||
            model.name == imageCodecModel.name) {
          installedCodec = model;
          break;
        }
      }
    }
    final codecRequest = imageCodecModel;
    final installedCodecForCheck = installedCodec;
    final imageCodecMissing =
        codecRequest != null &&
        (imageCodecSpec != null
            ? !imageCodecSpec.hasCompleteInstalledRecord(
                imageCodecService.availableModels,
              )
            : installedCodecForCheck == null);
    if (!translationMissing && !imageCodecMissing) return;
    if (!mounted) return;

    await _showModelDownloadDialog(
      translationModel: translationMissing ? translationRequest : null,
      imageCodecModel: imageCodecMissing ? codecRequest : null,
      imageCodecSpec: imageCodecMissing ? imageCodecSpec : null,
      translationService: translationService,
      imageCodecService: imageCodecService,
    );
  }

  Future<void> _showModelDownloadDialog({
    required TranslationModelRecord? translationModel,
    required ImageCodecModelRecord? imageCodecModel,
    required ImageCodecModelSpec? imageCodecSpec,
    required TranslationService translationService,
    required ImageCodecService imageCodecService,
  }) async {
    final l10n = context.l10n;
    final modelNames = [
      if (translationModel != null)
        translationModelFriendlyName(translationModel),
      if (imageCodecModel != null)
        imageCodecSpec?.label ?? imageCodecModel.name,
    ];
    var starting = false;
    var cancelRequested = false;
    var translationDone = translationModel == null;
    var imageCodecDone = imageCodecModel == null;
    String? currentModel;
    String? downloadError;
    final servicesListenable = Listenable.merge([
      translationService,
      imageCodecService,
    ]);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AnimatedBuilder(
          animation: servicesListenable,
          builder: (context, _) {
            final isDownloading =
                starting ||
                translationService.isDownloading ||
                imageCodecService.isDownloading;
            final currentProgress = currentModel == translationModel?.name
                ? translationService.downloadProgress
                : currentModel == imageCodecModel?.name
                ? imageCodecService.downloadProgress
                : null;
            final currentFile = currentModel == translationModel?.name
                ? translationService.downloadFileName
                : currentModel == imageCodecModel?.name
                ? imageCodecService.downloadFileName
                : null;

            void requestDownloadCancel() {
              cancelRequested = true;
              translationService.cancelDownload();
              imageCodecService.cancelDownload();
            }

            return PopScope<void>(
              canPop: !isDownloading,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && isDownloading) requestDownloadCancel();
              },
              child: AlertDialog(
                title: Text(l10n.backupRestore_missingModelsTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backupRestore_missingModelsMessage(
                        modelNames.join('\n'),
                      ),
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: 16),
                      Text(currentFile ?? currentModel ?? ''),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: currentProgress),
                    ],
                    if (downloadError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.backupRestore_failed(downloadError!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (isDownloading) {
                        requestDownloadCancel();
                      } else {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: Text(
                      isDownloading
                          ? l10n.backupRestore_cancelDownload
                          : l10n.common_cancel,
                    ),
                  ),
                  FilledButton(
                    onPressed: isDownloading
                        ? null
                        : () async {
                            setDialogState(() {
                              starting = true;
                              currentModel = translationDone
                                  ? imageCodecModel?.name
                                  : translationModel?.name;
                              downloadError = null;
                            });
                            try {
                              if (!translationDone) {
                                final model = translationModel!;
                                if (model.sourceUrl.isEmpty) {
                                  throw StateError(
                                    'No download address is available for ${model.name}',
                                  );
                                }
                                await translationService.downloadModel(
                                  sourceUrl: model.sourceUrl,
                                  fileName: model.name,
                                  id: model.id,
                                );
                                translationDone = true;
                                setDialogState(() {
                                  currentModel = imageCodecModel?.name;
                                });
                              }
                              if (!imageCodecDone) {
                                final model = imageCodecModel!;
                                final spec = imageCodecSpec;
                                if (spec != null) {
                                  await imageCodecService.downloadPresetModel(
                                    spec,
                                  );
                                } else if (model.sourceUrl.isNotEmpty) {
                                  await imageCodecService.downloadModel(
                                    sourceUrl: model.sourceUrl,
                                    fileName: model.name,
                                    id: model.id,
                                  );
                                } else {
                                  throw StateError(
                                    'No download address is available for ${model.name}',
                                  );
                                }
                                imageCodecDone = true;
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (error) {
                              if (dialogContext.mounted) {
                                if (cancelRequested) {
                                  Navigator.pop(dialogContext);
                                } else {
                                  setDialogState(() {
                                    starting = false;
                                    downloadError = error.toString();
                                  });
                                }
                              }
                            }
                          },
                    child: Text(
                      isDownloading
                          ? l10n.backupRestore_downloading
                          : l10n.backupRestore_downloadModels,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _confirmIdentityReplacement() async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.backupRestore_replaceIdentityTitle),
            content: Text(l10n.backupRestore_replaceIdentityMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.backupRestore_restore),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showDismissibleSnackBar(context, content: Text(message));
  }
}
