import 'dart:io';

import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';

class BatteryUi {
  final IconData icon;
  final Color? color;
  const BatteryUi(this.icon, this.color);
}

BatteryUi batteryUiForPercent(int? percent) {
  if (percent == null) {
    return const BatteryUi(Icons.battery_unknown, Colors.grey);
  }

  final p = percent.clamp(0, 100);

  return switch (p) {
    <= 5 => const BatteryUi(Icons.battery_alert, Colors.redAccent),
    <= 15 => const BatteryUi(Icons.battery_0_bar, Colors.redAccent),
    <= 30 => const BatteryUi(Icons.battery_1_bar, Colors.orange),
    <= 45 => const BatteryUi(Icons.battery_2_bar, Colors.amber),
    <= 60 => const BatteryUi(Icons.battery_3_bar, Colors.lightGreen),
    <= 80 => const BatteryUi(Icons.battery_5_bar, Colors.green),
    _ => const BatteryUi(Icons.battery_full, Colors.green),
  };
}

class BatteryIndicator extends StatefulWidget {
  final MeshCoreConnector connector;

  const BatteryIndicator({
    super.key,
    required this.connector,
  });

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> {
  bool _showBatteryVoltage = false;

  @override
  Widget build(BuildContext context) {
    // Hide battery indicator on macOS as it shows incorrect values
    if (Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final percent = widget.connector.batteryPercent;
    final millivolts = widget.connector.batteryMillivolts;

    if (millivolts == null) {
      return const SizedBox.shrink();
    }

    final String displayText;
    if (_showBatteryVoltage) {
      displayText = '${(millivolts / 1000.0).toStringAsFixed(2)}V';
    } else {
      displayText = percent != null ? '$percent%' : '—';
    }

    final batteryUi = batteryUiForPercent(percent);

    return InkWell(
      onTap: () {
        setState(() {
          _showBatteryVoltage = !_showBatteryVoltage;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(batteryUi.icon, size: 18, color: batteryUi.color),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: batteryUi.color,
                ),
                overflow: TextOverflow.visible,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
