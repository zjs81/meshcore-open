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
import '../services/app_settings_service.dart';
import '../services/backup_service.dart';
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
