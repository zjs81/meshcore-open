import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/widgets/battery_indicator.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import 'connect_sheet.dart';
import 'radio_stats_entry.dart';
import 'snr_indicator.dart';

class AppBarTitle extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool indicators;
  final bool showBatteryIndicator;
  final bool subtitle;
  const AppBarTitle(
    this.title, {
    this.leading,
    this.trailing,
    this.indicators = true,
    this.showBatteryIndicator = true,
    this.subtitle = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();
    final selfName = connector.selfName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = availableWidth < 170;
        final connected = connector.isConnected;
        final reconnecting =
            !connected &&
            (connector.state == MeshCoreConnectionState.connecting ||
                connector.isAutoReconnectScheduled);
        final offlineName = connector.lastRadioName;
        final subtitleText = !subtitle || compact
            ? null
            : connected
            ? selfName
            : offlineName != null && offlineName.isNotEmpty
            ? context.l10n.appBar_offlineSubtitle(offlineName)
            : context.l10n.appBar_offline;
        final showBattery = showBatteryIndicator && availableWidth >= 60;
        final showSnr = availableWidth >= 110;
        final showIndicators =
            connected && (showBattery || showSnr) && indicators;
        final showConnect = !connected && indicators;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            leading ?? const SizedBox.shrink(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitleText != null)
                    Text(
                      subtitleText,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (showIndicators) const SizedBox(width: 6),
            if (showIndicators)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBattery) BatteryIndicator(connector: connector),
                  if (showSnr) SNRIndicator(connector: connector),
                  if (connector.supportsCompanionRadioStats)
                    const RadioStatsIconButton(compact: true),
                ],
              ),
            if (showConnect) const SizedBox(width: 6),
            if (showConnect)
              reconnecting
                  ? _ReconnectingChip(compact: availableWidth < 220)
                  : ConnectButton(iconOnly: availableWidth < 220),
            trailing ?? const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class _ReconnectingChip extends StatelessWidget {
  final bool compact;

  const _ReconnectingChip({required this.compact});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.appBar_reconnecting;
    final scheme = Theme.of(context).colorScheme;
    const spinner = SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
    // Tapping still opens the sheet, which offers "Stop reconnecting".
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showConnectSheet(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                spinner,
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
