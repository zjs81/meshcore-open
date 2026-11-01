import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/utils/gpx_export.dart';
import 'package:meshcore_open/widgets/elements_ui.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/app_bar.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/utf8_length_limiter.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/map_location_picker.dart';
import '../widgets/radio_settings_dialog.dart';
import 'app_settings_screen.dart';
import 'app_debug_log_screen.dart';
import 'ble_debug_log_screen.dart';
import '../widgets/radio_stats_entry.dart';
import 'telemetry_screen.dart';
import '../widgets/sync_progress_overlay.dart';
import 'region_management_screen.dart';
import '../utils/share_origin.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showBatteryVoltage = false;
  bool _deviceInfoExpanded = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${packageInfo.version} BETA';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          l10n.settings_title,
          indicators: false,
          subtitle: false,
        ),
        centerTitle: true,
        bottom: const SyncProgressAppBarBottom(),
      ),
      body: SafeArea(
        top: false,
        // Each card selects only the connector fields it renders, so the
        // frequent unrelated connector notifications (frames, contacts,
        // messages) do not rebuild the whole settings list.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            // IDENTITY section
            SectionHeader(l10n.settings_deviceInfo),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _selectConnector(
                (c) => (
                  c.deviceDisplayName,
                  c.isConnected,
                  c.deviceIdLabel,
                  c.batteryPercent,
                  c.batteryMillivolts,
                  c.manufacturerName,
                  c.firmwareVersionString,
                  c.selfName,
                  c.selfPublicKey == null ? null : c.selfPublicKeyHex,
                  c.contacts.length,
                  c.channels.length,
                ),
                _buildIdentityCardContent,
              ),
            ),

            // NODE section
            SectionHeader(l10n.settings_nodeSettings),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _selectConnector(
                (c) => (
                  c.isConnected,
                  c.selfName,
                  c.supportsCompanionRadioStats,
                  c.firmwareVerCode,
                  c.pathHashByteWidth,
                ),
                _buildNodeCardContent,
              ),
            ),

            // LOCATION section
            SectionHeader(l10n.settings_location),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _selectConnector(
                (c) => c.isConnected,
                _buildLocationCardContent,
              ),
            ),

            // APP SETTINGS
            SectionHeader(l10n.settings_appSettings),
            MeshCard(
              padding: EdgeInsets.zero,
              child: MeshNavTile(
                icon: Icons.settings_outlined,
                title: l10n.settings_appSettings,
                subtitle: l10n.settings_appSettingsSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                ),
              ),
            ),

            // ACTIONS section
            SectionHeader(l10n.settings_actions),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _selectConnector(
                (c) => c.isConnected,
                _buildActionsCardContent,
              ),
            ),

            // EXPORT section
            SectionHeader(l10n.settings_gpxExportRepeaters),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _buildExportCardContent(
                context,
                context.read<MeshCoreConnector>(),
              ),
            ),

            // DEBUG section
            SectionHeader(l10n.settings_debug),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _buildDebugCardContent(context),
            ),

            // ABOUT
            SectionHeader(l10n.settings_about),
            MeshCard(
              padding: EdgeInsets.zero,
              child: MeshNavTile(
                icon: Icons.info_outline,
                title: l10n.settings_about,
                subtitle: l10n.settings_aboutVersion(
                  _appVersion.isEmpty ? l10n.common_loading : _appVersion,
                ),
                showChevron: false,
                onTap: () => _showAbout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rebuilds [builder] only when [selector]'s value changes (records compare
  /// field by field) or when this screen itself rebuilds.
  Widget _selectConnector<T>(
    T Function(MeshCoreConnector connector) selector,
    Widget Function(BuildContext context, MeshCoreConnector connector) builder,
  ) {
    return Selector<MeshCoreConnector, T>(
      selector: (_, connector) => selector(connector),
      builder: (context, _, _) =>
          builder(context, context.read<MeshCoreConnector>()),
    );
  }

  /// Guards a radio command: returns false (after telling the user) when the
  /// radio is not connected, because the connector silently ignores commands
  /// sent while disconnected and a success message would be a lie.
  bool _ensureConnected(BuildContext context, MeshCoreConnector connector) {
    if (connector.isConnected) return true;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.settings_notConnectedError),
    );
    return false;
  }

  Widget _buildIdentityCardContent(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: device name + status chip + expand toggle
        InkWell(
          onTap: () {
            setState(() {
              _deviceInfoExpanded = !_deviceInfoExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connector.deviceDisplayName,
                        style: MeshTheme.mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusChip(
                        label: connector.isConnected
                            ? l10n.common_connected
                            : l10n.common_disconnected,
                        color: connector.isConnected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        pulse: connector.isConnected,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _deviceInfoExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable detail rows
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _deviceInfoExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      _infoRow(
                        context,
                        label: l10n.settings_infoId,
                        value: connector.deviceIdLabel,
                      ),
                      _buildBatteryInfoRow(context, connector),
                      if (connector.manufacturerName != null)
                        _infoRow(
                          context,
                          label: l10n.settings_infoHardware,
                          value: connector.manufacturerName!,
                        ),
                      if (connector.firmwareVersionString != null)
                        _infoRow(
                          context,
                          label: l10n.settings_infoFirmware,
                          value: connector.firmwareVersionString!,
                        ),
                      if (connector.selfName != null)
                        _infoRow(
                          context,
                          label: l10n.settings_nodeName,
                          value: connector.selfName!,
                        ),
                      if (connector.selfPublicKey != null)
                        _publicKeyRow(
                          context,
                          label: l10n.settings_infoPublicKey,
                          publicKeyHex: pubKeyToHex(connector.selfPublicKey!),
                        ),
                      _infoRow(
                        context,
                        label: l10n.settings_infoContactsCount,
                        value: '${connector.contacts.length}',
                      ),
                      _infoRow(
                        context,
                        label: l10n.settings_infoChannelCount,
                        value: '${connector.channels.length}',
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Copies the key rendered in the row, not whatever the connector holds when
  /// the tap lands: a disconnect in between clears `selfPublicKey`.
  Widget _publicKeyRow(
    BuildContext context, {
    required String label,
    required String publicKeyHex,
  }) {
    return _infoRow(
      context,
      label: label,
      value: publicKeyHex,
      mono: true,
      semanticsHint: context.l10n.settings_publicKeyCopyHint,
      trailing: Icon(
        Icons.copy_outlined,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: () => _copyPublicKey(context, publicKeyHex),
    );
  }

  Future<void> _copyPublicKey(BuildContext context, String publicKeyHex) async {
    await Clipboard.setData(ClipboardData(text: publicKeyHex));
    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.settings_publicKeyCopied),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool mono = false,
    Widget? leading,
    Color? valueColor,
    Widget? trailing,
    String? semanticsHint,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 6)],
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          mono
              ? Text(
                  value,
                  style: MeshTheme.mono(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? scheme.onSurface,
                  ),
                )
              : Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
        ],
      ),
    );

    if (trailing != null) {
      content = Row(
        children: [
          Expanded(child: content),
          const SizedBox(width: 8),
          trailing,
        ],
      );
    }

    if (onTap != null) {
      return Semantics(
        button: true,
        hint: semanticsHint,
        child: InkWell(
          borderRadius: BorderRadius.circular(MeshRadii.xs),
          onTap: onTap,
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildBatteryInfoRow(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final percent = connector.batteryPercent;
    final millivolts = connector.batteryMillivolts;

    final String displayValue;
    if (millivolts == null) {
      displayValue = l10n.common_notAvailable;
    } else if (_showBatteryVoltage) {
      displayValue = l10n.common_voltageValue(
        (millivolts / 1000.0).toStringAsFixed(2),
      );
    } else {
      displayValue = percent != null
          ? l10n.common_percentValue(percent)
          : l10n.common_notAvailable;
    }

    final IconData icon;
    final Color? iconColor;
    final Color? valueColor;

    if (percent == null) {
      icon = Icons.battery_unknown;
      iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
      valueColor = null;
    } else if (percent <= 15) {
      icon = Icons.battery_alert;
      iconColor = Theme.of(context).colorScheme.tertiary;
      valueColor = Theme.of(context).colorScheme.tertiary;
    } else {
      icon = Icons.battery_full;
      iconColor = null;
      valueColor = null;
    }

    return _infoRow(
      context,
      semanticsHint: millivolts != null
          ? l10n.settings_batteryToggleHint
          : null,
      label: l10n.settings_infoBattery,
      value: displayValue,
      leading: Icon(icon, size: 20, color: iconColor),
      valueColor: valueColor,
      trailing: millivolts != null
          ? Tooltip(
              message: l10n.settings_batteryToggleHint,
              child: Icon(
                Icons.swap_horiz,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      onTap: millivolts != null
          ? () {
              setState(() {
                _showBatteryVoltage = !_showBatteryVoltage;
              });
            }
          : null,
    );
  }

  Widget _buildNodeCardContent(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final connected = connector.isConnected;
    final offline = l10n.settings_requiresConnection;
    return Column(
      children: [
        MeshNavTile(
          icon: Icons.person_outline,
          title: l10n.settings_nodeName,
          subtitle: connected
              ? connector.selfName ?? l10n.settings_nodeNameNotSet
              : offline,
          onTap: connected ? () => _editNodeName(context, connector) : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.radio,
          title: l10n.settings_radioSettings,
          subtitle: connected ? l10n.settings_radioSettingsSubtitle : offline,
          onTap: connected
              ? () => _showRadioSettings(context, connector)
              : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.landscape,
          title: l10n.settings_regionSettings,
          subtitle: l10n.settings_regionSettingsSubtitle,
          onTap: () => pushRegionManagementScreen(context),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.sensors_outlined,
          title: l10n.radioStats_settingsTile,
          subtitle: !connected
              ? offline
              : !connector.supportsCompanionRadioStats
              ? l10n.settings_requiresFirmware('v1.10')
              : l10n.radioStats_settingsSubtitle,
          onTap: connector.isConnected && connector.supportsCompanionRadioStats
              ? () => pushCompanionRadioStatsScreen(context)
              : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.thermostat_outlined,
          title: l10n.contact_telemetry,
          subtitle: connected ? l10n.repeater_telemetrySubtitle : offline,
          onTap: connector.isConnected
              ? () => pushSelfTelemetryScreen(context)
              : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.route_outlined,
          title: l10n.repeater_pathHashMode,
          subtitle: !connected
              ? offline
              : !connector.supportsPathHashMode
              ? l10n.settings_requiresFirmware('v1.14')
              : _pathHashModeSubtitle(context, connector.pathHashByteWidth),
          onTap: connector.isConnected && connector.supportsPathHashMode
              ? () => _editPathHashMode(context, connector)
              : null,
        ),
      ],
    );
  }

  String _pathHashModeSubtitle(BuildContext context, int pathHashByteWidth) {
    final l10n = context.l10n;
    return switch (pathHashByteWidth.clamp(1, 4).toInt()) {
      1 => l10n.repeater_pathHashModeOption0,
      2 => l10n.repeater_pathHashModeOption1,
      3 => l10n.repeater_pathHashModeOption2,
      _ => l10n.repeater_pathHashModeOption3,
    };
  }

  Widget _buildLocationCardContent(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final connected = connector.isConnected;
    final offline = l10n.settings_requiresConnection;
    return Column(
      children: [
        MeshNavTile(
          icon: Icons.location_on_outlined,
          title: l10n.settings_location,
          subtitle: connected ? l10n.settings_locationSubtitle : offline,
          onTap: connected ? () => _editLocation(context, connector) : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.group_add_outlined,
          title: l10n.settings_contactSettings,
          subtitle: connected ? l10n.settings_contactSettingsSubtitle : offline,
          onTap: connected
              ? () => _editAutoAddConfig(context, connector)
              : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.visibility_off_outlined,
          title: l10n.settings_privacy,
          subtitle: connected ? l10n.settings_privacySubtitle : offline,
          onTap: connected ? () => _privacySettings(context, connector) : null,
        ),
      ],
    );
  }

  Widget _buildActionsCardContent(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final connected = connector.isConnected;
    final offline = l10n.settings_requiresConnection;
    return Column(
      children: [
        MeshNavTile(
          icon: Icons.sync,
          title: l10n.settings_syncTime,
          subtitle: connected ? l10n.settings_syncTimeSubtitle : offline,
          onTap: connected ? () => _syncTime(context, connector) : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.refresh,
          title: l10n.settings_refreshContacts,
          subtitle: connected ? l10n.settings_refreshContactsSubtitle : offline,
          onTap: connected ? () => connector.getContacts() : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.restart_alt,
          title: l10n.settings_rebootDevice,
          subtitle: connected ? l10n.settings_rebootDeviceSubtitle : offline,
          titleColor: MeshPalette.warn,
          iconColor: MeshPalette.warn,
          onTap: connected ? () => _confirmReboot(context, connector) : null,
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.delete_outline,
          title: l10n.settings_deleteAllPaths,
          subtitle: l10n.settings_deleteAllPathsSubtitle,
          titleColor: MeshPalette.alert,
          iconColor: MeshPalette.alert,
          onTap: () => _confirmDeleteAllPaths(context, connector),
        ),
      ],
    );
  }

  Widget _buildExportCardContent(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    return Column(
      children: [
        MeshNavTile(
          icon: Icons.download_outlined,
          title: l10n.settings_gpxExportRepeaters,
          subtitle: l10n.settings_gpxExportRepeatersSubtitle,
          onTap: () async {
            final exporter = GpxExport(connector);
            exporter.addRepeaters();
            _gpxExport(
              exporter,
              l10n.map_repeater,
              l10n.settings_gpxExportRepeatersRoom,
              'meshcore_repeaters_',
              l10n.settings_gpxExportShareText,
              l10n.settings_gpxExportShareSubject,
            );
          },
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.download_outlined,
          title: l10n.settings_gpxExportContacts,
          subtitle: l10n.settings_gpxExportContactsSubtitle,
          onTap: () async {
            final exporter = GpxExport(connector);
            exporter.addContacts();
            _gpxExport(
              exporter,
              l10n.map_repeater,
              l10n.settings_gpxExportChat,
              'meshcore_contacts_',
              l10n.settings_gpxExportShareText,
              l10n.settings_gpxExportShareSubject,
            );
          },
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.download_outlined,
          title: l10n.settings_gpxExportAll,
          subtitle: l10n.settings_gpxExportAllSubtitle,
          onTap: () async {
            final exporter = GpxExport(connector);
            exporter.addAll();
            _gpxExport(
              exporter,
              l10n.map_repeater,
              l10n.settings_gpxExportAllContacts,
              'meshcore_all_',
              l10n.settings_gpxExportShareText,
              l10n.settings_gpxExportShareSubject,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDebugCardContent(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        MeshNavTile(
          icon: Icons.bluetooth_outlined,
          title: l10n.settings_companionDebugLog,
          subtitle: l10n.settings_companionDebugLogSubtitle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BleDebugLogScreen(),
              ),
            );
          },
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.code_outlined,
          title: l10n.settings_appDebugLog,
          subtitle: l10n.settings_appDebugLogSubtitle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppDebugLogScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _editNodeName(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NodeNameDialog(initialName: connector.selfName ?? ''),
    );
    if (name == null || !context.mounted) return;
    if (!_ensureConnected(context, connector)) return;
    try {
      await connector.setNodeName(name);
      await connector.refreshDeviceInfo();
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_nodeNameUpdated),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_error(e.toString())),
      );
    }
  }

  void _showRadioSettings(BuildContext context, MeshCoreConnector connector) {
    showDialog(
      context: context,
      builder: (context) => RadioSettingsDialog(connector: connector),
    );
  }

  void _editPathHashMode(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    var selectedMode = (connector.pathHashByteWidth - 1).clamp(0, 2).toInt();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(l10n.repeater_pathHashMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: selectedMode,
                decoration: InputDecoration(
                  labelText: l10n.repeater_pathHashMode,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text(
                      l10n.repeater_pathHashModeOption0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text(
                      l10n.repeater_pathHashModeOption1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(
                      l10n.repeater_pathHashModeOption2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedMode = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                l10n.settings_pathHashModeHelper,
                style: Theme.of(builderContext).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (!_ensureConnected(context, connector)) return;
                try {
                  await connector.setPathHashMode(selectedMode);
                  await connector.refreshDeviceInfo();
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.repeater_settingsSaved),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.settings_error(e.toString())),
                  );
                }
              },
              child: Text(l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLocation(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final l10n = context.l10n;
    final settingsService = context.read<AppSettingsService>();

    // Safe access to custom vars - may be null before device responds
    final customVars = connector.currentCustomVars ?? {};
    final bool hasGPS = customVars.containsKey("gps");
    final bool initialGPSEnabled = customVars["gps"] == "1";

    final edit = await showDialog<_LocationEdit>(
      context: context,
      builder: (_) => _LocationDialog(
        latitude: connector.selfLatitude,
        longitude: connector.selfLongitude,
        hasGPS: hasGPS,
        initialGPSEnabled: initialGPSEnabled,
        initialIntervalSeconds: settingsService.resolvedGpsIntervalSeconds(
          customVars,
        ),
      ),
    );
    if (edit == null || !edit.hasChanges || !context.mounted) return;
    if (!_ensureConnected(context, connector)) return;

    try {
      final gpsEnabled = edit.gpsEnabled;
      if (gpsEnabled != null) {
        await connector.setCustomVar(gpsEnabled ? "gps:1" : "gps:0");
      }
      final interval = edit.intervalSeconds;
      if (interval != null) {
        await settingsService.setGpsIntervalSeconds(
          interval,
          writeToDevice: (value) =>
              connector.setCustomVar("gps_interval:$value"),
        );
      }
      final lat = edit.latitude;
      final lon = edit.longitude;
      if (lat != null && lon != null) {
        await connector.setNodeLocation(lat: lat, lon: lon);
      }
      await connector.refreshDeviceInfo();
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          edit.clearsLocation
              ? l10n.settings_locationCleared
              : l10n.settings_locationUpdated,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_error(e.toString())),
      );
    }
  }

  Future<void> _syncTime(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final l10n = context.l10n;
    if (!_ensureConnected(context, connector)) return;
    try {
      await connector.syncTime();
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_timeSynchronized),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_error(e.toString())),
      );
    }
  }

  void _confirmDeleteAllPaths(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_deleteAllPaths),
        content: Text(l10n.settings_deleteAllPathsSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              connector.deleteAllPaths();
            },
            child: Text(
              l10n.common_deleteAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReboot(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    final screenContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_rebootDevice),
        content: Text(l10n.settings_rebootDeviceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!_ensureConnected(screenContext, connector)) return;
              connector.rebootDevice();
            },
            child: Text(
              l10n.common_reboot,
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final l10n = context.l10n;
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: _appVersion.isEmpty
          ? l10n.common_loading
          : _appVersion,
      applicationLegalese: l10n.settings_aboutLegalese,
      children: [
        const SizedBox(height: 16),
        Text(l10n.settings_aboutDescription),
      ],
    );
  }

  Future<void> _gpxExport(
    GpxExport exporter,
    String name,
    String description,
    String filename,
    String shareText,
    String subject,
  ) async {
    final l10n = context.l10n;
    final result = await exporter.exportGPX(
      name,
      description,
      filename,
      shareText,
      subject,
      sharePositionOrigin: shareOriginOf(context),
    );
    if (!mounted) return;
    switch (result) {
      case gpxExportSuccess:
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_gpxExportSuccess),
        );
      case gpxExportNoContacts:
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_gpxExportNoContacts),
        );
        break;
      case gpxExportNotAvailable:
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_gpxExportNotAvailable),
        );
        break;
      case gpxExportFailed:
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_gpxExportError),
        );
        break;
    }
  }

  void _editAutoAddConfig(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    // The dialog's context is gone once it pops; report through the screen.
    final screenContext = context;
    bool autoAddChat = false;
    bool autoAddRepeater = false;
    bool autoAddRoomServer = false;
    bool autoAddSensor = false;
    bool overwriteOldest = false;
    final appSettingsService = context.read<AppSettingsService>();
    bool evictDiscoveredContactsEnabled =
        appSettingsService.settings.evictDiscoveredContactsEnabled;
    bool saving = false;

    final connector = context.read<MeshCoreConnector>();
    autoAddChat = connector.autoAddUsers ?? false;
    autoAddRepeater = connector.autoAddRepeaters ?? false;
    autoAddRoomServer = connector.autoAddRoomServers ?? false;
    autoAddSensor = connector.autoAddSensors ?? false;
    overwriteOldest = connector.autoAddOverwriteOldest ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.contactsSettings_autoAddTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddUsersTitle,
                  subtitle: l10n.contactsSettings_autoAddUsersSubtitle,
                  value: autoAddChat,
                  onChanged: (value) {
                    setDialogState(() => autoAddChat = value);
                  },
                ),
                const SizedBox(height: 8),
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddRepeatersTitle,
                  subtitle: l10n.contactsSettings_autoAddRepeatersSubtitle,
                  value: autoAddRepeater,
                  onChanged: (value) {
                    setDialogState(() => autoAddRepeater = value);
                  },
                ),
                const SizedBox(height: 8),
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddRoomServersTitle,
                  subtitle: l10n.contactsSettings_autoAddRoomServersSubtitle,
                  value: autoAddRoomServer,
                  onChanged: (value) {
                    setDialogState(() => autoAddRoomServer = value);
                  },
                ),
                const SizedBox(height: 8),
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddSensorsTitle,
                  subtitle: l10n.contactsSettings_autoAddSensorsSubtitle,
                  value: autoAddSensor,
                  onChanged: (value) {
                    setDialogState(() => autoAddSensor = value);
                  },
                ),
                const Divider(height: 4),
                FeatureToggleRow(
                  title: l10n.contactsSettings_overwriteOldestTitle,
                  subtitle: l10n.contactsSettings_overwriteOldestSubtitle,
                  value: overwriteOldest,
                  onChanged: (value) {
                    setDialogState(() => overwriteOldest = value);
                  },
                ),
                const Divider(height: 4),
                FeatureToggleRow(
                  title: l10n.contactsSettings_evictDiscoveredContactsTitle,
                  subtitle: l10n
                      .contactsSettings_evictDiscoveredContactsSubtitle(
                        MeshCoreConnector.maxDiscoveredContacts,
                      ),
                  value: evictDiscoveredContactsEnabled,
                  onChanged: (value) {
                    setDialogState(
                      () => evictDiscoveredContactsEnabled = value,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!_ensureConnected(context, connector)) return;
                      setDialogState(() => saving = true);
                      try {
                        await _sendSettings(
                          connector,
                          autoAddChat,
                          autoAddRepeater,
                          autoAddRoomServer,
                          autoAddSensor,
                          overwriteOldest,
                        );
                        await appSettingsService
                            .setEvictDiscoveredContactsEnabled(
                              evictDiscoveredContactsEnabled,
                            );
                        if (evictDiscoveredContactsEnabled) {
                          await connector.trimDiscoveredContactsToLimit();
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        showDismissibleSnackBar(
                          context,
                          content: Text(l10n.settings_error(e.toString())),
                        );
                        setDialogState(() => saving = false);
                        return;
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      showDismissibleSnackBar(
                        screenContext,
                        content: Text(l10n.settings_contactSettingsSaved),
                      );
                    },
              child: Text(l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSettings(
    MeshCoreConnector connector,
    bool autoAddChat,
    bool autoAddRepeater,
    bool autoAddRoomServer,
    bool autoAddSensor,
    bool overwriteOldest,
  ) async {
    final frame = buildSetAutoAddConfigFrame(
      autoAddChat: autoAddChat,
      autoAddRepeater: autoAddRepeater,
      autoAddRoomServer: autoAddRoomServer,
      autoAddSensor: autoAddSensor,
      overwriteOldest: overwriteOldest,
    );
    await connector.sendFrame(frame);
    await connector.sendFrame(buildGetAutoAddFlagsFrame());
  }
}

void _privacySettings(BuildContext context, MeshCoreConnector connector) {
  final l10n = context.l10n;
  final settingsService = context.read<AppSettingsService>();

  int telemetryMode = connector.telemetryModeBase;
  int telemetryLocMode = connector.telemetryModeLoc;
  int telemetryEnvMode = connector.telemetryModeEnv;
  bool advertLocPolicy = connector.advertLocationPolicy == 0 ? false : true;
  int multiAcks = connector.multiAcks;
  bool autoZeroHopAdvertOnGpsUpdate =
      settingsService.settings.autoSendZeroHopAdvertOnGpsUpdate;

  final telemModeBase = [
    DropdownMenuItem(
      value: teleModeDeny,
      child: Text(
        l10n.settings_denyAll,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    DropdownMenuItem(
      value: teleModeAllowFlags,
      child: Text(
        l10n.settings_allowByContact,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    DropdownMenuItem(
      value: teleModeAllowAll,
      child: Text(
        l10n.settings_allowAll,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ];

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (builderContext, setDialogState) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(l10n.settings_privacy),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings_privacySettingsDescription),
              const SizedBox(height: 16),
              FeatureToggleRow(
                title: l10n.settings_advertLocation,
                subtitle: l10n.settings_advertLocationSubtitle,
                value: advertLocPolicy,
                onChanged: (value) {
                  setDialogState(() => advertLocPolicy = value);
                },
              ),
              const SizedBox(height: 8),
              FeatureToggleRow(
                title: l10n.settings_autoZeroHopAdvertOnGpsUpdate,
                subtitle: l10n.settings_autoZeroHopAdvertOnGpsUpdateSubtitle,
                value: autoZeroHopAdvertOnGpsUpdate,
                enabled: advertLocPolicy,
                onChanged: advertLocPolicy
                    ? (value) {
                        setDialogState(
                          () => autoZeroHopAdvertOnGpsUpdate = value,
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(l10n.settings_multiAck),
                subtitle: Text(l10n.settings_multiAckSubtitle),
                value: multiAcks == 1,
                onChanged: (value) {
                  setDialogState(() => multiAcks = value ? 1 : 0);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: telemetryMode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.settings_telemetryBaseMode,
                  border: const OutlineInputBorder(),
                ),
                items: telemModeBase,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => telemetryMode = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: telemetryLocMode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.settings_telemetryLocationMode,
                  border: const OutlineInputBorder(),
                ),
                items: telemModeBase,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => telemetryLocMode = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: telemetryEnvMode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.settings_telemetryEnvironmentMode,
                  border: const OutlineInputBorder(),
                ),
                items: telemModeBase,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => telemetryEnvMode = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.settings_telemetryPerContactHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!connector.isConnected) {
                showDismissibleSnackBar(
                  context,
                  content: Text(l10n.settings_notConnectedError),
                );
                return;
              }
              try {
                await connector.setTelemetryModeBase(
                  telemetryMode,
                  telemetryLocMode,
                  telemetryEnvMode,
                  advertLocPolicy ? 1 : 0,
                  multiAcks,
                );
                await settingsService.setAutoSendZeroHopAdvertOnGpsUpdate(
                  autoZeroHopAdvertOnGpsUpdate,
                );
                await connector.refreshDeviceInfo();
                if (!context.mounted) return;
                showDismissibleSnackBar(
                  context,
                  content: Text(l10n.settings_telemetryModeUpdated),
                );
              } catch (e) {
                if (!context.mounted) return;
                showDismissibleSnackBar(
                  context,
                  content: Text(l10n.settings_error(e.toString())),
                );
              }
            },
            child: Text(l10n.common_save),
          ),
        ],
      ),
    ),
  );
}

/// Node-name editor. Owns (and disposes) its controller; pops with the
/// trimmed name on Save, or null on Cancel.
class _NodeNameDialog extends StatefulWidget {
  final String initialName;

  const _NodeNameDialog({required this.initialName});

  @override
  State<_NodeNameDialog> createState() => _NodeNameDialogState();
}

class _NodeNameDialogState extends State<_NodeNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.settings_nodeName),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: l10n.settings_nodeNameHint,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: const [
          Utf8LengthLimitingTextInputFormatter(maxRadioNameBytes),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final name = _controller.text.trim();
            return TextButton(
              onPressed: name.isEmpty
                  ? null
                  : () => Navigator.pop(context, name),
              child: Text(l10n.common_save),
            );
          },
        ),
      ],
    );
  }
}

/// What the location dialog asks the screen to apply. Null fields are left
/// unchanged on the device.
class _LocationEdit {
  final bool? gpsEnabled;
  final int? intervalSeconds;
  final double? latitude;
  final double? longitude;
  final bool clearsLocation;

  const _LocationEdit({
    this.gpsEnabled,
    this.intervalSeconds,
    this.latitude,
    this.longitude,
    this.clearsLocation = false,
  });

  bool get hasChanges =>
      gpsEnabled != null ||
      intervalSeconds != null ||
      (latitude != null && longitude != null);
}

/// Location / GPS editor. Owns (and disposes) its controllers and validates
/// every field before closing, reporting each error under the field it
/// belongs to.
class _LocationDialog extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final bool hasGPS;
  final bool initialGPSEnabled;
  final int initialIntervalSeconds;

  const _LocationDialog({
    required this.latitude,
    required this.longitude,
    required this.hasGPS,
    required this.initialGPSEnabled,
    required this.initialIntervalSeconds,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  late final TextEditingController _intervalController;
  late bool _isGPSEnabled = widget.initialGPSEnabled;
  String? _latError;
  String? _lonError;
  String? _intervalError;

  /// Firmware stores "no location" as 0,0 (the default for a fresh node), so
  /// that pair is shown as empty fields rather than a real coordinate.
  bool get _hasLocation {
    final lat = widget.latitude;
    final lon = widget.longitude;
    return lat != null && lon != null && !(lat == 0 && lon == 0);
  }

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: _hasLocation ? widget.latitude!.toStringAsFixed(6) : '',
    );
    _lonController = TextEditingController(
      text: _hasLocation ? widget.longitude!.toStringAsFixed(6) : '',
    );
    _intervalController = TextEditingController(
      text: widget.initialIntervalSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    // Validate every field before closing so a typo doesn't discard the
    // input or leave half the changes applied.
    int? interval;
    String? intervalError;
    if (widget.hasGPS) {
      final intervalText = _intervalController.text.trim();
      if (intervalText.isNotEmpty) {
        interval = int.tryParse(intervalText);
        if (interval == null || interval < 60 || interval >= 86400) {
          intervalError = l10n.settings_locationIntervalInvalid;
        }
      }
    }

    final latText = _latController.text.trim();
    final lonText = _lonController.text.trim();
    double? lat;
    double? lon;
    String? latError;
    String? lonError;
    var clearsLocation = false;
    if (latText.isEmpty && lonText.isEmpty) {
      // Clearing both fields removes the location. Companion firmware has no
      // dedicated "clear" command: CMD_SET_ADVERT_LATLON with 0,0 restores
      // the factory default, which firmware and this app treat as unset.
      if (_hasLocation) {
        lat = 0;
        lon = 0;
        clearsLocation = true;
      }
    } else {
      // One empty field keeps the device's current value for that axis.
      lat = latText.isNotEmpty
          ? double.tryParse(latText)
          : (_hasLocation ? widget.latitude : null);
      lon = lonText.isNotEmpty
          ? double.tryParse(lonText)
          : (_hasLocation ? widget.longitude : null);
      if (lat == null) {
        latError = latText.isEmpty
            ? l10n.settings_locationBothRequired
            : l10n.settings_locationInvalid;
      } else if (lat < -90 || lat > 90) {
        latError = l10n.settings_locationInvalid;
      }
      if (lon == null) {
        lonError = lonText.isEmpty
            ? l10n.settings_locationBothRequired
            : l10n.settings_locationInvalid;
      } else if (lon < -180 || lon > 180) {
        lonError = l10n.settings_locationInvalid;
      }
    }

    if (intervalError != null || latError != null || lonError != null) {
      setState(() {
        _intervalError = intervalError;
        _latError = latError;
        _lonError = lonError;
      });
      return;
    }

    Navigator.pop(
      context,
      _LocationEdit(
        gpsEnabled: widget.hasGPS && _isGPSEnabled != widget.initialGPSEnabled
            ? _isGPSEnabled
            : null,
        intervalSeconds: interval,
        latitude: lat,
        longitude: lon,
        clearsLocation: clearsLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const coordinateKeyboard = TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    );
    return AlertDialog(
      title: Text(l10n.settings_location),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _latController,
              onChanged: (_) {
                if (_latError != null) setState(() => _latError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.settings_latitude,
                border: const OutlineInputBorder(),
                errorText: _latError,
                errorMaxLines: 2,
              ),
              keyboardType: coordinateKeyboard,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lonController,
              onChanged: (_) {
                if (_lonError != null) setState(() => _lonError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.settings_longitude,
                border: const OutlineInputBorder(),
                helperText: l10n.settings_locationClearHelper,
                helperMaxLines: 2,
                errorText: _lonError,
                errorMaxLines: 2,
              ),
              keyboardType: coordinateKeyboard,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final lat = double.tryParse(_latController.text.trim());
                  final lon = double.tryParse(_lonController.text.trim());
                  final initial = lat != null && lon != null
                      ? LatLng(lat, lon)
                      : null;
                  final startCenter = await fetchPhonePosition();
                  if (!context.mounted) return;
                  final picked = await showMapLocationPicker(
                    context,
                    initial: initial,
                    startCenter: startCenter,
                  );
                  if (picked == null || !mounted) return;
                  setState(() {
                    _latController.text = picked.latitude.toStringAsFixed(6);
                    _lonController.text = picked.longitude.toStringAsFixed(6);
                    _latError = null;
                    _lonError = null;
                  });
                },
                icon: const Icon(Icons.map),
                label: Text(l10n.repeater_setFromMap),
              ),
            ),
            if (widget.hasGPS) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _intervalController,
                onChanged: (_) {
                  if (_intervalError != null) {
                    setState(() => _intervalError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.settings_locationIntervalSec,
                  border: const OutlineInputBorder(),
                  errorText: _intervalError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
              ),
              const SizedBox(height: 16),
              FeatureToggleRow(
                title: l10n.settings_locationGPSEnable,
                subtitle: l10n.settings_locationGPSEnableSubtitle,
                value: _isGPSEnabled,
                // Applied on Save so Cancel leaves the device untouched.
                onChanged: (value) => setState(() => _isGPSEnabled = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.common_save)),
      ],
    );
  }
}
