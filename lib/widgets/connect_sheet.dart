import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../screens/connect_screen.dart';
import '../screens/settings_screen.dart';
import '../storage/last_radio_store.dart';
import '../theme/theme_icons.dart';
import '../utils/dialog_utils.dart';
import '../utils/platform_info.dart';
import 'mesh_ui.dart';

/// Ways to get a radio connected: reconnect to the last one, pick another,
/// or stop a pending automatic reconnect.
Future<void> showConnectSheet(BuildContext context) {
  return showMeshSheet<void>(
    context,
    builder: (sheetContext) => _ConnectSheet(hostContext: context),
  );
}

class _ConnectSheet extends StatelessWidget {
  /// Context of the screen that opened the sheet; it outlives the sheet.
  final BuildContext hostContext;

  const _ConnectSheet({required this.hostContext});

  Future<void> _reconnect(BuildContext context, String name) async {
    final connector = context.read<MeshCoreConnector>();
    Navigator.of(context).pop();
    final connected = await connector.reconnectToLastRadio();
    if (connected || !hostContext.mounted) return;
    showDismissibleSnackBar(
      hostContext,
      content: Text(hostContext.l10n.connectSheet_reconnectFailed(name)),
    );
  }

  void _chooseRadio(BuildContext context, LastRadio? lastRadio) {
    Navigator.of(context).pop();
    if (!hostContext.mounted) return;
    final transport = switch (lastRadio?.transport) {
      _ when PlatformInfo.isWeb => MeshCoreTransportType.usb,
      LastRadio.transportUsb => MeshCoreTransportType.usb,
      LastRadio.transportTcp => MeshCoreTransportType.tcp,
      _ => MeshCoreTransportType.bluetooth,
    };
    Navigator.of(hostContext).push(
      MaterialPageRoute(
        builder: (_) => ConnectScreen(initialTransport: transport),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final connector = context.watch<MeshCoreConnector>();
    final lastRadio = connector.lastRadio;
    final name = connector.lastRadioName ?? '';
    final connecting = connector.state == MeshCoreConnectionState.connecting;
    final canReconnect =
        !PlatformInfo.isWeb &&
        lastRadio != null &&
        name.isNotEmpty &&
        (lastRadio.canReconnectBle || lastRadio.canReconnectTcp);
    final titleStyle = textTheme.titleMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottomSheetHeader(title: l10n.connectSheet_title),
        if (canReconnect)
          ListTile(
            minTileHeight: 64,
            leading: connecting
                ? const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    lastRadio.canReconnectTcp ? Icons.lan : Icons.bluetooth,
                    size: 28,
                  ),
            title: Text(l10n.connectSheet_reconnect(name), style: titleStyle),
            enabled: !connecting,
            onTap: () => _reconnect(context, name),
          ),
        ListTile(
          minTileHeight: 64,
          leading: const Icon(Icons.radio, size: 28),
          title: Text(l10n.connectSheet_chooseRadio, style: titleStyle),
          subtitle: Text(l10n.connectSheet_chooseRadioSubtitle),
          onTap: () => _chooseRadio(context, lastRadio),
        ),
        if (connector.isAutoReconnectScheduled)
          ListTile(
            minTileHeight: 64,
            leading: const Icon(Icons.sync_disabled, size: 28),
            title: Text(l10n.connectSheet_stopReconnecting, style: titleStyle),
            onTap: () {
              connector.cancelAutoReconnect();
              Navigator.of(context).pop();
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Compact Connect button for app bars and read-only bars.
class ConnectButton extends StatelessWidget {
  /// Icon only, for narrow app bars.
  final bool iconOnly;

  const ConnectButton({super.key, this.iconOnly = false});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.common_connect;
    if (iconOnly) {
      return IconButton(
        icon: const Icon(Icons.link),
        tooltip: label,
        onPressed: () => showConnectSheet(context),
      );
    }
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        visualDensity: VisualDensity.standard,
      ),
      icon: const Icon(Icons.link, size: 20),
      label: Text(label),
      onPressed: () => showConnectSheet(context),
    );
  }
}

/// Overflow-menu entry of the main screens: Disconnect (after confirming,
/// staying on the screen offline) while connected, Connect otherwise.
/// [screenContext] must outlive the menu, as onTap runs after it closes.
PopupMenuItem<T> connectionMenuItem<T>(
  BuildContext screenContext,
  BuildContext menuContext,
) {
  final connector = screenContext.read<MeshCoreConnector>();
  final l10n = menuContext.l10n;
  if (connector.isConnected) {
    return PopupMenuItem<T>(
      child: MeshMenuItemRow(
        icon: Icons.logout,
        iconColor: Theme.of(menuContext).colorScheme.error,
        label: l10n.common_disconnect,
      ),
      onTap: () => showDisconnectDialog(screenContext, connector),
    );
  }
  return PopupMenuItem<T>(
    child: MeshMenuItemRow(icon: Icons.link, label: l10n.common_connect),
    onTap: () => showConnectSheet(screenContext),
  );
}

/// Overflow-menu entry that opens [SettingsScreen].
/// [screenContext] must outlive the menu, as onTap runs after it closes.
PopupMenuItem<T> settingsMenuItem<T>(
  BuildContext screenContext,
  BuildContext menuContext,
) {
  return PopupMenuItem<T>(
    child: MeshMenuItemRow(
      leading: const ThemedIcon(ThemeIconSlot.settings, size: 20),
      label: menuContext.l10n.settings_title,
    ),
    onTap: () => Navigator.push(
      screenContext,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ),
  );
}

/// Trailing app-level section shared by the main views' overflow menus:
/// an optional [PopupMenuDivider] (omitted when [hasPrecedingItems] is false)
/// followed by [connectionMenuItem] and [settingsMenuItem].
List<PopupMenuEntry<T>> mainOverflowTrailingItems<T>(
  BuildContext screenContext,
  BuildContext menuContext, {
  bool hasPrecedingItems = true,
}) {
  return <PopupMenuEntry<T>>[
    if (hasPrecedingItems) const PopupMenuDivider(),
    connectionMenuItem<T>(screenContext, menuContext),
    settingsMenuItem<T>(screenContext, menuContext),
  ];
}
