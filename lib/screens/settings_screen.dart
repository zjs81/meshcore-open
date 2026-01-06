import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/radio_settings.dart';
import 'app_settings_screen.dart';
import 'app_debug_log_screen.dart';
import 'ble_debug_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showBatteryVoltage = false;
  String _appVersion = '...';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<MeshCoreConnector>(
          builder: (context, connector, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDeviceInfoCard(connector),
                const SizedBox(height: 16),
                _buildAppSettingsCard(context),
                const SizedBox(height: 16),
                _buildNodeSettingsCard(context, connector),
                const SizedBox(height: 16),
                _buildActionsCard(context, connector),
                const SizedBox(height: 16),
                _buildDebugCard(context),
                const SizedBox(height: 16),
                _buildAboutCard(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(MeshCoreConnector connector) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', connector.deviceDisplayName),
            _buildInfoRow('ID', connector.deviceIdLabel),
            _buildInfoRow('Status', connector.isConnected ? 'Connected' : 'Disconnected'),
            if (!Platform.isMacOS) _buildBatteryInfoRow(connector),
            if (connector.selfName != null)
              _buildInfoRow('Node Name', connector.selfName!),
            if (connector.selfPublicKey != null)
              _buildInfoRow('Public Key', '${pubKeyToHex(connector.selfPublicKey!).substring(0, 16)}...'),
            _buildInfoRow('Contacts Count', '${connector.contacts.length}'),
            _buildInfoRow('Channel Count', '${connector.channels.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryInfoRow(MeshCoreConnector connector) {
    final percent = connector.batteryPercent;
    final millivolts = connector.batteryMillivolts;

    // figure out display value
    final String displayValue;
    if (millivolts == null) {
      displayValue = '—';
    } else if (_showBatteryVoltage) {
      displayValue = '${(millivolts / 1000.0).toStringAsFixed(2)} V';
    } else {
      displayValue = percent != null ? '$percent%' : '—';
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
      'Battery',
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: const Text('App Settings'),
        subtitle: const Text('Notifications, messaging, and map preferences'),
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

  Widget _buildNodeSettingsCard(BuildContext context, MeshCoreConnector connector) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Node Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Node Name'),
            subtitle: Text(connector.selfName ?? 'Not set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNodeName(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.radio),
            title: const Text('Radio Settings'),
            subtitle: const Text('Frequency, power, spreading factor'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRadioSettings(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Location'),
            subtitle: const Text('GPS coordinates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editLocation(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Privacy Mode'),
            subtitle: const Text('Hide name/location in advertisements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _togglePrivacy(context, connector),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, MeshCoreConnector connector) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cell_tower),
            title: const Text('Send Advertisement'),
            subtitle: const Text('Broadcast presence now'),
            onTap: () => _sendAdvert(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Time'),
            subtitle: const Text('Set device clock to phone time'),
            onTap: () => _syncTime(context, connector),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Contacts'),
            subtitle: const Text('Reload contact list from device'),
            onTap: () => connector.getContacts(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.orange),
            title: const Text('Reboot Device'),
            subtitle: const Text('Restart the MeshCore device'),
            onTap: () => _confirmReboot(context, connector),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About'),
        subtitle: Text('MeshCore Open v$_appVersion'),
        onTap: () => _showAbout(context),
      ),
    );
  }

  Widget _buildDebugCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Debug',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth_outlined),
            title: const Text('BLE Debug Log'),
            subtitle: const Text('BLE commands, responses, and raw data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BleDebugLogScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('App Debug Log'),
            subtitle: const Text('Application debug messages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppDebugLogScreen()),
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
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: row,
      );
    }
    return row;
  }

  void _editNodeName(BuildContext context, MeshCoreConnector connector) {
    final controller = TextEditingController(text: connector.selfName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Node Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter node name',
            border: OutlineInputBorder(),
          ),
          maxLength: 31,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await connector.setNodeName(controller.text);
              await connector.refreshDeviceInfo();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name updated')),
              );
            },
            child: const Text('Save'),
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
    final latController = TextEditingController();
    final lonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lonController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final latText = latController.text.trim();
              final lonText = lonController.text.trim();
              if (latText.isEmpty && lonText.isEmpty) {
                return;
              }

              final currentLat = connector.selfLatitude;
              final currentLon = connector.selfLongitude;
              final lat = latText.isNotEmpty ? double.tryParse(latText) : currentLat;
              final lon = lonText.isNotEmpty ? double.tryParse(lonText) : currentLon;
              if (lat == null || lon == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter both latitude and longitude.')),
                );
                return;
              }
              if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid latitude or longitude.')),
                );
                return;
              }

              await connector.setNodeLocation(lat: lat, lon: lon);
              await connector.refreshDeviceInfo();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _togglePrivacy(BuildContext context, MeshCoreConnector connector) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Mode'),
        content: const Text('Toggle privacy mode to hide your name and location in advertisements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await connector.setPrivacyMode(true);
              await connector.refreshDeviceInfo();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy mode enabled')),
              );
            },
            child: const Text('Enable'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await connector.setPrivacyMode(false);
              await connector.refreshDeviceInfo();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy mode disabled')),
              );
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _sendAdvert(BuildContext context, MeshCoreConnector connector) {
    connector.sendSelfAdvert(flood: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advertisement sent')),
    );
  }

  void _syncTime(BuildContext context, MeshCoreConnector connector) {
    connector.syncTime();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time synchronized')),
    );
  }

  void _confirmReboot(BuildContext context, MeshCoreConnector connector) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reboot Device'),
        content: const Text('Are you sure you want to reboot the device? You will be disconnected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              connector.rebootDevice();
            },
            child: const Text('Reboot', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MeshCore Open',
      applicationVersion: _appVersion,
      applicationLegalese: '2024 MeshCore Open Source Project',
      children: [
        const SizedBox(height: 16),
        const Text(
          'An open-source Flutter client for MeshCore LoRa mesh networking devices.',
        ),
      ],
    );
  }
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

  @override
  void initState() {
    super.initState();

    // Populate with current settings if available
    if (widget.connector.currentFreqHz != null) {
      _frequencyController.text = (widget.connector.currentFreqHz! / 1000.0).toStringAsFixed(3);
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
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _txPowerController.dispose();
    super.dispose();
  }

  void _applyPreset(RadioSettings preset) {
    setState(() {
      _frequencyController.text = preset.frequencyMHz.toString();
      _bandwidth = preset.bandwidth;
      _spreadingFactor = preset.spreadingFactor;
      _codingRate = preset.codingRate;
      _txPowerController.text = preset.txPowerDbm.toString();
    });
  }

  Future<void> _saveSettings() async {
    final freqMHz = double.tryParse(_frequencyController.text);
    final txPower = int.tryParse(_txPowerController.text);

    if (freqMHz == null || freqMHz < 300 || freqMHz > 2500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid frequency (300-2500 MHz)')),
      );
      return;
    }

    if (txPower == null || txPower < 0 || txPower > 22) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid TX power (0-22 dBm)')),
      );
      return;
    }

    final freqHz = (freqMHz * 1000).round();
    final bwHz = _bandwidth.hz;
    final sf = _spreadingFactor.value;
    final cr = _toDeviceCodingRate(_codingRate.value, widget.connector.currentCr);

    try {
      await widget.connector.sendFrame(buildSetRadioParamsFrame(freqHz, bwHz, sf, cr));
      await widget.connector.sendFrame(buildSetRadioTxPowerFrame(txPower));
      await widget.connector.refreshDeviceInfo();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Radio settings updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  int _toUiCodingRate(int deviceCr) {
    return deviceCr <= 4 ? deviceCr + 4 : deviceCr;
  }

  int _toDeviceCodingRate(int uiCr, int? deviceCr) {
    if (deviceCr != null && deviceCr <= 4) {
      return uiCr - 4;
    }
    return uiCr;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Radio Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Presets', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _PresetChip(
                  label: '915 MHz',
                  onTap: () => _applyPreset(RadioSettings.preset915MHz),
                ),
                _PresetChip(
                  label: '868 MHz',
                  onTap: () => _applyPreset(RadioSettings.preset868MHz),
                ),
                _PresetChip(
                  label: '433 MHz',
                  onTap: () => _applyPreset(RadioSettings.preset433MHz),
                ),
                _PresetChip(
                  label: 'Long Range',
                  onTap: () => _applyPreset(RadioSettings.presetLongRange),
                ),
                _PresetChip(
                  label: 'Fast Speed',
                  onTap: () => _applyPreset(RadioSettings.presetFastSpeed),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency (MHz)',
                border: OutlineInputBorder(),
                helperText: '300.0 - 2500.0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaBandwidth>(
              initialValue: _bandwidth,
              decoration: const InputDecoration(
                labelText: 'Bandwidth',
                border: OutlineInputBorder(),
              ),
              items: LoRaBandwidth.values
                  .map((bw) => DropdownMenuItem(
                        value: bw,
                        child: Text(bw.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _bandwidth = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaSpreadingFactor>(
              initialValue: _spreadingFactor,
              decoration: const InputDecoration(
                labelText: 'Spreading Factor',
                border: OutlineInputBorder(),
              ),
              items: LoRaSpreadingFactor.values
                  .map((sf) => DropdownMenuItem(
                        value: sf,
                        child: Text(sf.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _spreadingFactor = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaCodingRate>(
              initialValue: _codingRate,
              decoration: const InputDecoration(
                labelText: 'Coding Rate',
                border: OutlineInputBorder(),
              ),
              items: LoRaCodingRate.values
                  .map((cr) => DropdownMenuItem(
                        value: cr,
                        child: Text(cr.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _codingRate = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _txPowerController,
              decoration: const InputDecoration(
                labelText: 'TX Power (dBm)',
                border: OutlineInputBorder(),
                helperText: '0 - 22',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
