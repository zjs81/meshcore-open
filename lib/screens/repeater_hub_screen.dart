import 'package:flutter/material.dart';
import '../models/contact.dart';
import 'repeater_status_screen.dart';
import 'repeater_cli_screen.dart';
import 'repeater_settings_screen.dart';
import 'telemetry_screen.dart';

class RepeaterHubScreen extends StatelessWidget {
  final Contact repeater;
  final String password;

  const RepeaterHubScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Repeater Management'),
            Text(
              repeater.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
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
                        child: const Icon(Icons.cell_tower, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        repeater.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${repeater.latitude?.toStringAsFixed(4)}, ${repeater.longitude?.toStringAsFixed(4)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Management Tools',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Status button
              _buildManagementCard(
                context,
                icon: Icons.analytics,
                title: 'Status',
                subtitle: 'View repeater status, stats, and neighbors',
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
              // Status button
              _buildManagementCard(
                context,
                icon: Icons.bar_chart_sharp,
                title: 'Telemetry',
                subtitle: 'View telemetry of sensors and system stats',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelemetryScreen(
                        repeater: repeater,
                        password: password,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // CLI button
              _buildManagementCard(
                context,
                icon: Icons.terminal,
                title: 'CLI',
                subtitle: 'Send commands to the repeater',
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
              // Settings button
              _buildManagementCard(
                context,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Configure repeater parameters',
                color: Colors.orange,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
