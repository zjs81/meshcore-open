import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meshcore_open/utils/gpx_export.dart';
import 'package:meshcore_open/widgets/elements_ui.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/radio_settings.dart';
import '../services/app_debug_log_service.dart';
import '../widgets/app_bar.dart';
import '../helpers/snack_bar_builder.dart';
import 'app_settings_screen.dart';
import 'app_debug_log_screen.dart';
import 'ble_debug_log_screen.dart';
import '../widgets/radio_stats_entry.dart';

/// Convert device coding-rate value (1-4 on some firmware, 5-8 on others)
/// to the UI enum range (always 5-8).
int _toUiCodingRate(int deviceCr) {
  return deviceCr <= 4 ? deviceCr + 4 : deviceCr;
}

/// Convert UI coding-rate value (5-8) back to firmware encoding.
/// Uses the current device CR to detect which encoding the firmware expects.
int _toDeviceCodingRate(int uiCr, int? deviceCr) {
  if (deviceCr != null && deviceCr <= 4) {
    return uiCr - 4;
  }
  return uiCr;
}

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
    setState(() {
      _appVersion = packageInfo.version;
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
      ),
      body: SafeArea(
        top: false,
        child: Consumer<MeshCoreConnector>(
          builder: (context, connector, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDeviceInfoCard(context, connector),
                const SizedBox(height: 16),
                _buildAppSettingsCard(context),
                const SizedBox(height: 16),
                _buildNodeSettingsCard(context, connector),
                const SizedBox(height: 16),
                _buildActionsCard(context, connector),
                const SizedBox(height: 16),
                _buildDebugCard(context),
                const SizedBox(height: 16),
                _buildExportCard(connector),
                const SizedBox(height: 16),
                _buildAboutCard(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _deviceInfoExpanded = !_deviceInfoExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settings_deviceInfo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _deviceInfoExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    l10n.settings_infoName,
                    connector.deviceDisplayName,
                  ),
                  _buildInfoRow(l10n.settings_infoId, connector.deviceIdLabel),
                  _buildInfoRow(
                    l10n.settings_infoStatus,
                    connector.isConnected
                        ? l10n.common_connected
                        : l10n.common_disconnected,
                  ),
                  _buildBatteryInfoRow(context, connector),
                  if (connector.selfName != null)
                    _buildInfoRow(l10n.settings_nodeName, connector.selfName!),
                  if (connector.selfPublicKey != null)
                    _buildInfoRow(
                      l10n.settings_infoPublicKey,
                      '${pubKeyToHex(connector.selfPublicKey!).substring(0, 16)}...',
                    ),
                  _buildInfoRow(
                    l10n.settings_infoContactsCount,
                    '${connector.contacts.length}',
                  ),
                  _buildInfoRow(
                    l10n.settings_infoChannelCount,
                    '${connector.channels.length}',
                  ),
                ],
              ),
            ),
            crossFadeState: _deviceInfoExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryInfoRow(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final percent = connector.batteryPercent;
    final millivolts = connector.batteryMillivolts;

    // figure out display value
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
      iconColor = Colors.grey;
      valueColor = null;
    } else if (percent <= 15) {
      icon = Icons.battery_alert;
      iconColor = Colors.orange;
      valueColor = Colors.orange;
    } else {
      icon = Icons.battery_full;
      iconColor = null;
      valueColor = null;
    }

    return _buildInfoRow(
      l10n.settings_infoBattery,
      displayValue,
      leading: Icon(icon, size: 18, color: iconColor),
      valueColor: valueColor,
      onTap: millivolts != null
          ? () {
              setState(() {
                _showBatteryVoltage = !_showBatteryVoltage;
              });
            }
          : null,
    );
  }

  Widget _buildAppSettingsCard(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: Text(l10n.settings_appSettings),
        subtitle: Text(l10n.settings_appSettingsSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildNodeSettingsCard(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settings_nodeSettings,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settings_nodeName),
            subtitle: Text(connector.selfName ?? l10n.settings_nodeNameNotSet),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNodeName(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.radio),
            title: Text(l10n.settings_radioSettings),
            subtitle: Text(l10n.settings_radioSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRadioSettings(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sensors_outlined),
            title: Text(l10n.radioStats_settingsTile),
            subtitle: Text(l10n.radioStats_settingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            enabled:
                connector.isConnected && connector.supportsCompanionRadioStats,
            onTap: () => pushCompanionRadioStatsScreen(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.settings_location),
            subtitle: Text(l10n.settings_locationSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editLocation(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: Text(l10n.settings_contactSettings),
            subtitle: Text(l10n.settings_contactSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editAutoAddConfig(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text(l10n.settings_privacy),
            subtitle: Text(l10n.settings_privacySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _privacySettings(context, connector),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settings_actions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text("Delete All Paths"),
            subtitle: Text(
              "Clear all path data from contacts.",
              style: TextStyle(color: Colors.red[700]),
            ),
            onTap: () => connector.deleteAllPaths(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.settings_syncTime),
            subtitle: Text(l10n.settings_syncTimeSubtitle),
            onTap: () => _syncTime(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.settings_refreshContacts),
            subtitle: Text(l10n.settings_refreshContactsSubtitle),
            onTap: () => connector.getContacts(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.orange),
            title: Text(l10n.settings_rebootDevice),
            subtitle: Text(l10n.settings_rebootDeviceSubtitle),
            onTap: () => _confirmReboot(context, connector),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.settings_about),
        subtitle: Text(
          l10n.settings_aboutVersion(
            _appVersion.isEmpty ? l10n.common_loading : _appVersion,
          ),
        ),
        onTap: () => _showAbout(context),
      ),
    );
  }

  Widget _buildDebugCard(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settings_debug,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth_outlined),
            title: Text(l10n.settings_bleDebugLog),
            subtitle: Text(l10n.settings_bleDebugLogSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BleDebugLogScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: Text(l10n.settings_appDebugLog),
            subtitle: Text(l10n.settings_appDebugLogSubtitle),
            trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Widget? leading,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: row,
      );
    }

    return row;
  }

  void _editNodeName(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: connector.selfName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_nodeName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.settings_nodeNameHint,
            border: const OutlineInputBorder(),
          ),
          maxLength: 31,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await connector.setNodeName(controller.text);
              await connector.refreshDeviceInfo();
              if (!context.mounted) return;
              showDismissibleSnackBar(
                context,
                content: Text(l10n.settings_nodeNameUpdated),
              );
            },
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
  }

  void _showRadioSettings(BuildContext context, MeshCoreConnector connector) {
    showDialog(
      context: context,
      builder: (context) => _RadioSettingsDialog(connector: connector),
    );
  }

  void _editLocation(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final intervalController = TextEditingController();
    latController.text = connector.selfLatitude?.toStringAsFixed(6) ?? '';
    lonController.text = connector.selfLongitude?.toStringAsFixed(6) ?? '';

    // Safe access to custom vars - may be null before device responds
    final customVars = connector.currentCustomVars ?? {};
    final bool hasGPS = customVars.containsKey("gps");
    bool isGPSEnabled = customVars["gps"] == "1";

    // Read current interval or default to 900 (15 minutes)
    final currentInterval =
        int.tryParse(customVars["gps_interval"] ?? "") ?? 900;
    intervalController.text = currentInterval.toString();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.settings_location),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: InputDecoration(
                  labelText: l10n.settings_latitude,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lonController,
                decoration: InputDecoration(
                  labelText: l10n.settings_longitude,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              if (hasGPS) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: intervalController,
                  decoration: InputDecoration(
                    labelText: l10n.settings_locationIntervalSec,
                    border: const OutlineInputBorder(),
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
                  value: isGPSEnabled,
                  onChanged: (value) async {
                    setDialogState(() => isGPSEnabled = value);
                    if (value) {
                      await connector.setCustomVar("gps:1");
                    } else {
                      await connector.setCustomVar("gps:0");
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                if (hasGPS) {
                  final intervalText = intervalController.text.trim();
                  if (intervalText.isEmpty) {
                    return;
                  }

                  final interval = int.tryParse(intervalText);
                  if (interval == null || interval < 60 || interval >= 86400) {
                    if (!context.mounted) return;
                    showDismissibleSnackBar(
                      context,
                      content: Text(l10n.settings_locationIntervalInvalid),
                    );
                    return;
                  }

                  await connector.setCustomVar("gps_interval:$interval");
                  await connector.refreshDeviceInfo();
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.settings_locationUpdated),
                  );
                }

                final latText = latController.text.trim();
                final lonText = lonController.text.trim();
                if (latText.isEmpty && lonText.isEmpty) {
                  return;
                }

                final currentLat = connector.selfLatitude;
                final currentLon = connector.selfLongitude;
                final lat = latText.isNotEmpty
                    ? double.tryParse(latText)
                    : currentLat;
                final lon = lonText.isNotEmpty
                    ? double.tryParse(lonText)
                    : currentLon;
                if (lat == null || lon == null) {
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.settings_locationBothRequired),
                  );
                  return;
                }
                if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(l10n.settings_locationInvalid),
                  );
                  return;
                }

                await connector.setNodeLocation(lat: lat, lon: lon);
                await connector.refreshDeviceInfo();
                if (!context.mounted) return;
                showDismissibleSnackBar(
                  context,
                  content: Text(l10n.settings_locationUpdated),
                );
              },
              child: Text(l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _syncTime(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    connector.syncTime();
    showDismissibleSnackBar(
      context,
      content: Text(l10n.settings_timeSynchronized),
    );
  }

  void _confirmReboot(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
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
              connector.rebootDevice();
            },
            child: Text(
              l10n.common_reboot,
              style: const TextStyle(color: Colors.orange),
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

  Widget _buildExportCard(MeshCoreConnector connector) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settings_gpxExportRepeaters),
            subtitle: Text(l10n.settings_gpxExportRepeatersSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final exporter = GpxExport(connector);
              exporter.addRepeaters();
              _gpxExport(
                exporter,
                l10n.map_repeater,
                l10n.settings_gpxExportRepeatersRoom,
                "meshcore_repeaters_",
                l10n.settings_gpxExportShareText,
                l10n.settings_gpxExportShareSubject,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settings_gpxExportContacts),
            subtitle: Text(l10n.settings_gpxExportContactsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final exporter = GpxExport(connector);
              exporter.addContacts();
              _gpxExport(
                exporter,
                l10n.map_repeater,
                l10n.settings_gpxExportChat,
                "meshcore_contacts_",
                l10n.settings_gpxExportShareText,
                l10n.settings_gpxExportShareSubject,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settings_gpxExportAll),
            subtitle: Text(l10n.settings_gpxExportAllSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final exporter = GpxExport(connector);
              exporter.addAll();
              _gpxExport(
                exporter,
                l10n.map_repeater,
                l10n.settings_gpxExportAllContacts,
                "meshcore_all_",
                l10n.settings_gpxExportShareText,
                l10n.settings_gpxExportShareSubject,
              );
            },
          ),
        ],
      ),
    );
  }

  void _editAutoAddConfig(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    bool autoAddChat = false;
    bool autoAddRepeater = false;
    bool autoAddRoomServer = false;
    bool autoAddSensor = false;
    bool overwriteOldest = false;

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
                SizedBox(height: 8),
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddRepeatersTitle,
                  subtitle: l10n.contactsSettings_autoAddRepeatersSubtitle,
                  value: autoAddRepeater,
                  onChanged: (value) {
                    setDialogState(() => autoAddRepeater = value);
                  },
                ),
                SizedBox(height: 8),
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddRoomServersTitle,
                  subtitle: l10n.contactsSettings_autoAddRoomServersSubtitle,
                  value: autoAddRoomServer,
                  onChanged: (value) {
                    setDialogState(() => autoAddRoomServer = value);
                  },
                ),
                SizedBox(height: 8),
                FeatureToggleRow(
                  title: l10n.contactsSettings_autoAddSensorsTitle,
                  subtitle: l10n.contactsSettings_autoAddSensorsSubtitle,
                  value: autoAddSensor,
                  onChanged: (value) {
                    setDialogState(() => autoAddSensor = value);
                  },
                ),
                Divider(height: 4),
                FeatureToggleRow(
                  title: l10n.contactsSettings_overwriteOldestTitle,
                  subtitle: l10n.contactsSettings_overwriteOldestSubtitle,
                  value: overwriteOldest,
                  onChanged: (value) {
                    setDialogState(() => overwriteOldest = value);
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
              onPressed: () {
                _sendSettings(
                  connector,
                  autoAddChat,
                  autoAddRepeater,
                  autoAddRoomServer,
                  autoAddSensor,
                  overwriteOldest,
                );
                Navigator.pop(context);
              },
              child: Text(l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _sendSettings(
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

  int telemetryMode = connector.telemetryModeBase;
  int telemetryLocMode = connector.telemetryModeLoc;
  int telemetryEnvMode = connector.telemetryModeEnv;
  bool advertLocPolicy = connector.advertLocationPolicy == 0 ? false : true;
  int multiAcks = connector.multiAcks;

  final telemModeBase = [
    DropdownMenuItem(value: teleModeDeny, child: Text(l10n.settings_denyAll)),
    DropdownMenuItem(
      value: teleModeAllowFlags,
      child: Text(l10n.settings_allowByContact),
    ),
    DropdownMenuItem(
      value: teleModeAllowAll,
      child: Text(l10n.settings_allowAll),
    ),
  ];

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
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
              DropdownButtonFormField<int>(
                initialValue: telemetryMode,
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
              const SizedBox(height: 16),
              Text(
                l10n.settings_multiAck(multiAcks.toString()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                value: multiAcks.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: multiAcks.toString(),
                onChanged: (value) {
                  setDialogState(() => multiAcks = value.round());
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
            onPressed: () async {
              Navigator.pop(context);
              await connector.setTelemetryModeBase(
                telemetryMode,
                telemetryLocMode,
                telemetryEnvMode,
                advertLocPolicy ? 1 : 0,
                multiAcks,
              );
              await connector.refreshDeviceInfo();
              if (!context.mounted) return;
              showDismissibleSnackBar(
                context,
                content: Text(l10n.settings_telemetryModeUpdated),
              );
            },
            child: Text(l10n.common_save),
          ),
        ],
      ),
    ),
  );
}

class _RadioSettingsDialog extends StatefulWidget {
  final MeshCoreConnector connector;

  const _RadioSettingsDialog({required this.connector});

  @override
  State<_RadioSettingsDialog> createState() => _RadioSettingsDialogState();
}

class _RadioSettingsDialogState extends State<_RadioSettingsDialog> {
  final _frequencyController = TextEditingController();
  LoRaBandwidth _bandwidth = LoRaBandwidth.bw125;
  LoRaSpreadingFactor _spreadingFactor = LoRaSpreadingFactor.sf7;
  LoRaCodingRate _codingRate = LoRaCodingRate.cr4_5;
  final _txPowerController = TextEditingController(text: '20');
  bool _clientRepeat = false;
  int? _selectedPresetIndex;
  _RadioSettingsSnapshot? _lastNonRepeatSnapshot;

  AppDebugLogService get _appLog =>
      Provider.of<AppDebugLogService>(context, listen: false);

  @override
  void initState() {
    super.initState();

    // Populate with current settings if available
    if (widget.connector.currentFreqHz != null) {
      _frequencyController.text = (widget.connector.currentFreqHz! / 1000.0)
          .toStringAsFixed(3);
    } else {
      _frequencyController.text = '915.0';
    }

    if (widget.connector.currentBwHz != null) {
      // Find matching bandwidth enum
      final bwValue = widget.connector.currentBwHz!;
      for (var bw in LoRaBandwidth.values) {
        if (bw.hz == bwValue) {
          _bandwidth = bw;
          break;
        }
      }
    }

    if (widget.connector.currentSf != null) {
      // Find matching spreading factor enum
      final sfValue = widget.connector.currentSf!;
      for (var sf in LoRaSpreadingFactor.values) {
        if (sf.value == sfValue) {
          _spreadingFactor = sf;
          break;
        }
      }
    }

    if (widget.connector.currentCr != null) {
      // Find matching coding rate enum
      final crValue = _toUiCodingRate(widget.connector.currentCr!);
      for (var cr in LoRaCodingRate.values) {
        if (cr.value == crValue) {
          _codingRate = cr;
          break;
        }
      }
    }

    if (widget.connector.currentTxPower != null) {
      _txPowerController.text = widget.connector.currentTxPower.toString();
    }

    _clientRepeat = widget.connector.clientRepeat ?? false;
    _selectedPresetIndex = _findMatchingPresetIndex();
    if (_clientRepeat) {
      _lastNonRepeatSnapshot =
          _sessionRememberedNonRepeatSnapshot() ??
          _inferNonRepeatSnapshotForRepeatEnabled();
      _selectedPresetIndex = _findMatchingPresetIndexForSnapshot(
        _lastNonRepeatSnapshot!,
      );
    } else {
      _lastNonRepeatSnapshot = _nonRepeatSnapshotForCurrentSelection();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _logRadioSettingsState('Dialog initialized');
    });
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _txPowerController.dispose();
    super.dispose();
  }

  void _applyPreset(int index) {
    setState(() {
      _applyPresetState(index);
    });
    _logRadioSettingsState(
      'Applied preset ${RadioSettings.presets[index].$1} (#$index)',
    );
  }

  int? _findMatchingPresetIndex() {
    return _findMatchingPresetIndexForSnapshot(_currentSnapshot());
  }

  int? _findMatchingPresetIndexForSnapshot(_RadioSettingsSnapshot snapshot) {
    for (final i in _visiblePresetIndexes()) {
      final preset = RadioSettings.presets[i].$2;
      if (preset.frequencyHz == snapshot.frequencyHz &&
          preset.bandwidth == snapshot.bandwidth &&
          preset.spreadingFactor == snapshot.spreadingFactor &&
          preset.codingRate == snapshot.codingRate &&
          preset.txPowerDbm == snapshot.txPowerDbm) {
        return i;
      }
    }
    return null;
  }

  Iterable<int> _visiblePresetIndexes() sync* {
    for (var i = 0; i < RadioSettings.presets.length; i++) {
      if (_isOffGridPresetIndex(i)) {
        continue;
      }
      yield i;
    }
  }

  _RadioSettingsSnapshot _currentSnapshot() {
    final frequencyMHz = double.tryParse(_frequencyController.text) ?? 915.0;
    final txPowerDbm = int.tryParse(_txPowerController.text) ?? 20;
    return _RadioSettingsSnapshot(
      frequencyMHz: frequencyMHz,
      bandwidth: _bandwidth,
      spreadingFactor: _spreadingFactor,
      codingRate: _codingRate,
      txPowerDbm: txPowerDbm,
    );
  }

  bool _isOffGridPresetIndex(int? index) {
    if (index == null) return false;
    return RadioSettings.presets[index].$1.startsWith('Off-Grid ');
  }

  double _offGridFrequencyForBaseFrequency(double baseFrequencyMHz) {
    if (baseFrequencyMHz < 500) return 433.0;
    if (baseFrequencyMHz < 900) return 869.0;
    return 918.0;
  }

  double _normalFrequencyForBand(double frequencyMHz) {
    if (frequencyMHz < 500) return 433.650;
    if (frequencyMHz < 900) return 869.432;
    return 915.8;
  }

  _RadioSettingsSnapshot _fallbackNonRepeatSnapshot(
    double currentFrequencyMHz,
  ) {
    return _RadioSettingsSnapshot(
      frequencyMHz: _normalFrequencyForBand(currentFrequencyMHz),
      bandwidth: _bandwidth,
      spreadingFactor: _spreadingFactor,
      codingRate: _codingRate,
      txPowerDbm: int.tryParse(_txPowerController.text) ?? 20,
    );
  }

  _RadioSettingsSnapshot _nonRepeatSnapshotForCurrentSelection() {
    final current = _currentSnapshot();
    if (!_isOffGridPresetIndex(_selectedPresetIndex)) {
      return current;
    }
    return _fallbackNonRepeatSnapshot(current.frequencyMHz);
  }

  _RadioSettingsSnapshot? _sessionRememberedNonRepeatSnapshot() {
    final snapshot = widget.connector.rememberedNonRepeatRadioState;
    if (snapshot == null) return null;
    return _RadioSettingsSnapshot.fromMeshCoreSnapshot(snapshot);
  }

  _RadioSettingsSnapshot _inferNonRepeatSnapshotForRepeatEnabled() {
    final current = _currentSnapshot();
    for (final i in _visiblePresetIndexes()) {
      final preset = RadioSettings.presets[i].$2;
      final offGridFreqHz =
          (_offGridFrequencyForBaseFrequency(preset.frequencyMHz) * 1000)
              .round();
      if (offGridFreqHz == current.frequencyHz &&
          preset.bandwidth == current.bandwidth &&
          preset.spreadingFactor == current.spreadingFactor &&
          preset.codingRate == current.codingRate &&
          preset.txPowerDbm == current.txPowerDbm) {
        return _RadioSettingsSnapshot(
          frequencyMHz: preset.frequencyMHz,
          bandwidth: preset.bandwidth,
          spreadingFactor: preset.spreadingFactor,
          codingRate: preset.codingRate,
          txPowerDbm: preset.txPowerDbm,
        );
      }
    }
    return _fallbackNonRepeatSnapshot(current.frequencyMHz);
  }

  void _applySnapshot(_RadioSettingsSnapshot snapshot) {
    _frequencyController.text = snapshot.frequencyMHz.toStringAsFixed(3);
    _bandwidth = snapshot.bandwidth;
    _spreadingFactor = snapshot.spreadingFactor;
    _codingRate = snapshot.codingRate;
    _txPowerController.text = snapshot.txPowerDbm.toString();
  }

  void _applyPresetState(int index) {
    final preset = RadioSettings.presets[index].$2;
    final baseSnapshot = _RadioSettingsSnapshot(
      frequencyMHz: preset.frequencyMHz,
      bandwidth: preset.bandwidth,
      spreadingFactor: preset.spreadingFactor,
      codingRate: preset.codingRate,
      txPowerDbm: preset.txPowerDbm,
    );
    final frequencyMHz = _clientRepeat
        ? _offGridFrequencyForBaseFrequency(baseSnapshot.frequencyMHz)
        : baseSnapshot.frequencyMHz;
    _frequencyController.text = frequencyMHz.toString();
    _bandwidth = preset.bandwidth;
    _spreadingFactor = preset.spreadingFactor;
    _codingRate = preset.codingRate;
    _txPowerController.text = preset.txPowerDbm.toString();
    _selectedPresetIndex = index;
    _lastNonRepeatSnapshot = baseSnapshot;
  }

  void _syncPresetSelection() {
    final previousPresetIndex = _selectedPresetIndex;
    final previousLastNonRepeat = _lastNonRepeatSnapshot;
    if (_clientRepeat) {
      final baseSnapshot =
          previousLastNonRepeat ?? _inferNonRepeatSnapshotForRepeatEnabled();
      if (_bandwidth != baseSnapshot.bandwidth ||
          _spreadingFactor != baseSnapshot.spreadingFactor ||
          _codingRate != baseSnapshot.codingRate ||
          (int.tryParse(_txPowerController.text) ?? 20) !=
              baseSnapshot.txPowerDbm) {
        _lastNonRepeatSnapshot = _RadioSettingsSnapshot(
          frequencyMHz: baseSnapshot.frequencyMHz,
          bandwidth: _bandwidth,
          spreadingFactor: _spreadingFactor,
          codingRate: _codingRate,
          txPowerDbm: int.tryParse(_txPowerController.text) ?? 20,
        );
      }
      _selectedPresetIndex = _findMatchingPresetIndexForSnapshot(
        _lastNonRepeatSnapshot ?? baseSnapshot,
      );
      if (previousPresetIndex != _selectedPresetIndex ||
          previousLastNonRepeat != _lastNonRepeatSnapshot) {
        _logRadioSettingsState(
          'Preset match updated while repeat enabled: ${_presetLabel(previousPresetIndex)} -> ${_presetLabel(_selectedPresetIndex)}',
        );
      }
      return;
    }
    _lastNonRepeatSnapshot = _nonRepeatSnapshotForCurrentSelection();
    _selectedPresetIndex = _findMatchingPresetIndexForSnapshot(
      _lastNonRepeatSnapshot!,
    );
    if (previousPresetIndex != _selectedPresetIndex ||
        previousLastNonRepeat != _lastNonRepeatSnapshot) {
      _logRadioSettingsState(
        'Preset sync updated state from ${_presetLabel(previousPresetIndex)} to ${_presetLabel(_selectedPresetIndex)}',
      );
    }
  }

  void _handleManualSettingsChanged(String source) {
    _logRadioSettingsState('Manual settings edit: $source');
    setState(_syncPresetSelection);
  }

  void _handleClientRepeatChanged(bool enabled) {
    _logRadioSettingsState(
      'Off-grid repeat toggle requested: $_clientRepeat -> $enabled',
    );
    setState(() {
      final currentSnapshot = _currentSnapshot();
      if (enabled) {
        if (!_clientRepeat) {
          _syncPresetSelection();
        }
        final baseSnapshot = _lastNonRepeatSnapshot ?? currentSnapshot;
        _clientRepeat = true;
        _frequencyController.text = _offGridFrequencyForBaseFrequency(
          baseSnapshot.frequencyMHz,
        ).toStringAsFixed(3);
        return;
      }

      _clientRepeat = false;
      _applySnapshot(
        _lastNonRepeatSnapshot ??
            _fallbackNonRepeatSnapshot(currentSnapshot.frequencyMHz),
      );
      _syncPresetSelection();
    });
    _logRadioSettingsState('Off-grid repeat toggle applied');
  }

  Future<void> _saveSettings() async {
    final l10n = context.l10n;
    final freqMHz = double.tryParse(_frequencyController.text);
    final txPower = int.tryParse(_txPowerController.text);

    if (freqMHz == null || freqMHz < 300 || freqMHz > 2500) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_frequencyInvalid),
      );
      return;
    }

    final maxTxPower = widget.connector.maxTxPower ?? 22;
    if (txPower == null || txPower < 0 || txPower > maxTxPower) {
      showDismissibleSnackBar(
        context,
        content: Text('${l10n.settings_txPowerInvalid} (0-$maxTxPower dBm)'),
      );
      return;
    }

    final freqHz = (freqMHz * 1000).round();
    final bwHz = _bandwidth.hz;
    final sf = _spreadingFactor.value;
    final cr = _toDeviceCodingRate(
      _codingRate.value,
      widget.connector.currentCr,
    );

    // if the client repeat isnt null then we know its supported
    //otherwise we leave it out of the frame to avoid accidentally enabling
    final knownRepeat = widget.connector.clientRepeat != null;

    if (knownRepeat) {
      const validRepeatFreqsKHz = {433000, 869000, 918000};
      if (_clientRepeat && !validRepeatFreqsKHz.contains(freqHz)) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_clientRepeatFreqWarning),
        );
        return;
      }
    }

    try {
      _logRadioSettingsState('Saving radio settings');
      await widget.connector.sendFrame(
        buildSetRadioParamsFrame(
          freqHz,
          bwHz,
          sf,
          cr,
          clientRepeat: knownRepeat ? _clientRepeat : null,
        ),
      );
      await widget.connector.sendFrame(buildSetRadioTxPowerFrame(txPower));
      await widget.connector.refreshDeviceInfo();
      final rememberedSnapshot = _clientRepeat
          ? _lastNonRepeatSnapshot
          : _currentSnapshot();
      if (rememberedSnapshot != null) {
        widget.connector.rememberNonRepeatRadioState(
          rememberedSnapshot.toMeshCoreSnapshot(widget.connector.currentCr),
        );
      }

      if (!mounted) return;
      _logRadioSettingsState('Radio settings saved successfully');
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_radioSettingsUpdated),
      );
    } catch (e) {
      _appLog.warn('Radio settings save failed: $e', tag: 'RadioSettings');
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_error(e.toString())),
      );
    }
    Navigator.pop(context);
  }

  String _presetLabel(int? index) {
    if (index == null) {
      return 'custom';
    }
    return '${RadioSettings.presets[index].$1} (#$index)';
  }

  String _formatSnapshot(_RadioSettingsSnapshot? snapshot) {
    if (snapshot == null) {
      return 'null';
    }
    return '${snapshot.frequencyMHz.toStringAsFixed(3)}MHz/'
        '${snapshot.bandwidth.label}/'
        '${snapshot.spreadingFactor.label}/'
        '${snapshot.codingRate.label}/'
        '${snapshot.txPowerDbm}dBm';
  }

  void _logRadioSettingsState(String message) {
    if (!kDebugMode) return;
    _appLog.info(
      '$message | '
      'freq=${_frequencyController.text}MHz '
      'bw=${_bandwidth.label} '
      'sf=${_spreadingFactor.label} '
      'cr=${_codingRate.label} '
      'tx=${_txPowerController.text}dBm '
      'repeat=$_clientRepeat '
      'preset=${_presetLabel(_selectedPresetIndex)} '
      'lastNonRepeat=${_formatSnapshot(_lastNonRepeatSnapshot)}',
      tag: 'RadioSettings',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.settings_radioSettings),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey<int?>(_selectedPresetIndex),
              initialValue: _selectedPresetIndex,
              decoration: InputDecoration(
                labelText: l10n.settings_presets,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final i in _visiblePresetIndexes())
                  DropdownMenuItem(
                    value: i,
                    child: Text(RadioSettings.presets[i].$1),
                  ),
              ],
              onChanged: (index) {
                if (index != null) {
                  _applyPreset(index);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _frequencyController,
              onChanged: (_) => _handleManualSettingsChanged('frequency'),
              decoration: InputDecoration(
                labelText: l10n.settings_frequency,
                border: const OutlineInputBorder(),
                helperText: l10n.settings_frequencyHelper,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaBandwidth>(
              initialValue: _bandwidth,
              decoration: InputDecoration(
                labelText: l10n.settings_bandwidth,
                border: const OutlineInputBorder(),
              ),
              items: LoRaBandwidth.values
                  .map(
                    (bw) => DropdownMenuItem(value: bw, child: Text(bw.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _bandwidth = value;
                    _syncPresetSelection();
                  });
                  _logRadioSettingsState('Manual settings edit: bandwidth');
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaSpreadingFactor>(
              initialValue: _spreadingFactor,
              decoration: InputDecoration(
                labelText: l10n.settings_spreadingFactor,
                border: const OutlineInputBorder(),
              ),
              items: LoRaSpreadingFactor.values
                  .map(
                    (sf) => DropdownMenuItem(value: sf, child: Text(sf.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _spreadingFactor = value;
                    _syncPresetSelection();
                  });
                  _logRadioSettingsState(
                    'Manual settings edit: spreading factor',
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaCodingRate>(
              initialValue: _codingRate,
              decoration: InputDecoration(
                labelText: l10n.settings_codingRate,
                border: const OutlineInputBorder(),
              ),
              items: LoRaCodingRate.values
                  .map(
                    (cr) => DropdownMenuItem(value: cr, child: Text(cr.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _codingRate = value;
                    _syncPresetSelection();
                  });
                  _logRadioSettingsState('Manual settings edit: coding rate');
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _txPowerController,
              onChanged: (_) => _handleManualSettingsChanged('tx power'),
              decoration: InputDecoration(
                labelText: l10n.settings_txPower,
                border: const OutlineInputBorder(),
                helperText: widget.connector.maxTxPower != null
                    ? '${l10n.settings_txPowerHelper} (max: ${widget.connector.maxTxPower} dBm)'
                    : l10n.settings_txPowerHelper,
              ),
              keyboardType: TextInputType.number,
            ),
            if (widget.connector.clientRepeat != null) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.settings_clientRepeat),
                subtitle: Text(l10n.settings_clientRepeatSubtitle),
                value: _clientRepeat,
                onChanged: _handleClientRepeatChanged,
                contentPadding: EdgeInsets.zero,
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
        FilledButton(onPressed: _saveSettings, child: Text(l10n.common_save)),
      ],
    );
  }
}

class _RadioSettingsSnapshot {
  final double frequencyMHz;
  final LoRaBandwidth bandwidth;
  final LoRaSpreadingFactor spreadingFactor;
  final LoRaCodingRate codingRate;
  final int txPowerDbm;

  const _RadioSettingsSnapshot({
    required this.frequencyMHz,
    required this.bandwidth,
    required this.spreadingFactor,
    required this.codingRate,
    required this.txPowerDbm,
  });

  /// Frequency in integer Hz — avoids floating-point comparison issues.
  int get frequencyHz => (frequencyMHz * 1000).round();

  /// Convert from the connector's raw-int snapshot to UI-enum snapshot.
  static _RadioSettingsSnapshot? fromMeshCoreSnapshot(
    MeshCoreRadioStateSnapshot snapshot,
  ) {
    final bw = LoRaBandwidth.values
        .where((b) => b.hz == snapshot.bwHz)
        .firstOrNull;
    final sf = LoRaSpreadingFactor.values
        .where((s) => s.value == snapshot.sf)
        .firstOrNull;
    final cr = LoRaCodingRate.values
        .where((c) => c.value == _toUiCodingRate(snapshot.cr))
        .firstOrNull;
    if (bw == null || sf == null || cr == null) return null;
    return _RadioSettingsSnapshot(
      frequencyMHz: snapshot.freqHz / 1000.0,
      bandwidth: bw,
      spreadingFactor: sf,
      codingRate: cr,
      txPowerDbm: snapshot.txPowerDbm,
    );
  }

  /// Convert back to the connector's raw-int snapshot.
  MeshCoreRadioStateSnapshot toMeshCoreSnapshot(int? deviceCr) {
    return MeshCoreRadioStateSnapshot(
      freqHz: frequencyHz,
      bwHz: bandwidth.hz,
      sf: spreadingFactor.value,
      cr: _toDeviceCodingRate(codingRate.value, deviceCr),
      txPowerDbm: txPowerDbm,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _RadioSettingsSnapshot &&
        frequencyHz == other.frequencyHz &&
        bandwidth == other.bandwidth &&
        spreadingFactor == other.spreadingFactor &&
        codingRate == other.codingRate &&
        txPowerDbm == other.txPowerDbm;
  }

  @override
  int get hashCode => Object.hash(
    frequencyHz,
    bandwidth,
    spreadingFactor,
    codingRate,
    txPowerDbm,
  );
}
