import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mesh_theme.dart';
import 'mesh_ui.dart';
import 'signal_ui.dart';

/// A MeshCard row for a radio to connect to: an AvatarCircle, the name, a
/// mono id and, for a scanned BLE device, its signal ([rssi]) on the right.
/// While connecting, shows a small progress ring instead of the signal.
class DeviceTile extends StatelessWidget {
  final String name;
  final String? id;
  final IconData icon;
  final Color? color;
  final int? rssi;
  final VoidCallback? onTap;
  final bool isConnecting;

  const DeviceTile({
    super.key,
    required this.name,
    this.id,
    required this.icon,
    this.color,
    this.rssi,
    required this.onTap,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trailing = isConnecting
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          )
        : rssi == null
        ? null
        : _signal(rssi!);

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
          AvatarCircle(name: name, size: 42, icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (id != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    id!,
                    style: MeshTheme.mono(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }

  Widget _signal(int rssi) {
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
    return Column(
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
    );
  }
}
