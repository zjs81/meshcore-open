import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import 'mesh_ui.dart';
import 'signal_ui.dart';

/// A MeshCard-based row for displaying a scanned BLE device.
/// Shows an AvatarCircle (router icon, deterministic hue from device name),
/// device name, mono MAC address, mono RSSI dBm, and SignalBars on the right.
/// While connecting, shows a small progress ring instead of signal bars.
class DeviceTile extends StatelessWidget {
  final ScanResult scanResult;
  final VoidCallback? onTap;
  final bool isConnecting;

  const DeviceTile({
    super.key,
    required this.scanResult,
    required this.onTap,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final device = scanResult.device;
    final rssi = scanResult.rssi;
    final name = device.platformName.isNotEmpty
        ? device.platformName
        : scanResult.advertisementData.advName;
    final displayName = name.isNotEmpty
        ? name
        : context.l10n.common_unknownDevice;
    final mac = device.remoteId.toString();
    final scheme = Theme.of(context).colorScheme;

    final tier = rssi >= -60
        ? 0
        : rssi >= -70
        ? 1
        : rssi >= -80
        ? 2
        : rssi >= -90
        ? 3
        : 4;
    final signalUi = signalUiForStrengthTier(tier);

    return MeshCard(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AvatarCircle(name: displayName, size: 42, icon: Icons.router),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  mac,
                  style: MeshTheme.mono(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isConnecting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(signalUi.icon, size: 20, color: signalUi.color),
                const SizedBox(height: 3),
                Text(
                  '$rssi dBm',
                  style: MeshTheme.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: signalUi.color,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
