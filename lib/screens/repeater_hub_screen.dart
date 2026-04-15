import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import 'repeater_status_screen.dart';
import 'repeater_cli_screen.dart';
import 'repeater_settings_screen.dart';
import 'telemetry_screen.dart';
import 'neighbors_screen.dart';

class RepeaterHubScreen extends StatelessWidget {
  final Contact repeater;
  final String password;
  final bool isAdmin;

  const RepeaterHubScreen({
    super.key,
    required this.repeater,
    required this.password,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settingsService = context.watch<AppSettingsService>();
    final chemistry = settingsService.batteryChemistryForRepeater(
      repeater.publicKeyHex,
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              Text(
                repeater.type == advTypeRepeater
                    ? l10n.repeater_management
                    : l10n.room_management,
              ),
            if (!isAdmin)
              Text(
                repeater.type == advTypeRepeater
                    ? l10n.repeater_guest
                    : l10n.room_guest,
              ),
            Text(
              repeater.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Repeater info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.orange,
                      child: const Icon(
                        Icons.cell_tower,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      repeater.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repeater.shortPubKeyHex,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repeater.pathLabel,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (repeater.hasLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${repeater.latitude?.toStringAsFixed(4)}, ${repeater.longitude?.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isAdmin)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.battery_full),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.appSettings_batteryChemistry,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: chemistry,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          settingsService.setBatteryChemistryForRepeater(
                            repeater.publicKeyHex,
                            value,
                          );
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'nmc',
                            child: Text(l10n.appSettings_batteryNmc),
                          ),
                          DropdownMenuItem(
                            value: 'lifepo4',
                            child: Text(l10n.appSettings_batteryLifepo4),
                          ),
                          DropdownMenuItem(
                            value: 'lipo',
                            child: Text(l10n.appSettings_batteryLipo),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              isAdmin
                  ? l10n.repeater_managementTools
                  : l10n.repeater_guestTools,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Status button
            _buildManagementCard(
              context,
              icon: Icons.analytics,
              title: l10n.repeater_status,
              subtitle: l10n.repeater_statusSubtitle,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RepeaterStatusScreen(
                      repeater: repeater,
                      password: password,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Telemetry button
            _buildManagementCard(
              context,
              icon: Icons.bar_chart_sharp,
              title: l10n.repeater_telemetry,
              subtitle: l10n.repeater_telemetrySubtitle,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelemetryScreen(contact: repeater),
                  ),
                );
              },
            ),
            if (isAdmin) const SizedBox(height: 12),
            // CLI button
            if (isAdmin)
              _buildManagementCard(
                context,
                icon: Icons.terminal,
                title: l10n.repeater_cli,
                subtitle: l10n.repeater_cliSubtitle,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RepeaterCliScreen(
                        repeater: repeater,
                        password: password,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            // Neighbors button
            _buildManagementCard(
              context,
              icon: Icons.group,
              title: l10n.repeater_neighbors,
              subtitle: l10n.repeater_neighborsSubtitle,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NeighborsScreen(repeater: repeater, password: password),
                  ),
                );
              },
            ),
            if (isAdmin) const SizedBox(height: 12),
            // Settings button
            if (isAdmin)
              _buildManagementCard(
                context,
                icon: Icons.settings,
                title: l10n.repeater_settings,
                subtitle: l10n.repeater_settingsSubtitle,
                color: Colors.deepOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RepeaterSettingsScreen(
                        repeater: repeater,
                        password: password,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
