import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../review_mode/review_mode_entry.dart';
import '../theme/mesh_theme.dart';
import '../utils/platform_info.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/get_node_banner.dart';
import '../widgets/mesh_ui.dart';
import 'scanner_screen.dart';
import 'tcp_screen.dart';
import 'usb_screen.dart';

/// Connects a radio over Bluetooth, USB or TCP, one tab each. Only the
/// transports the platform offers get a tab: no USB on iOS, no TCP on web.
class ConnectScreen extends StatefulWidget {
  /// The tab to open on; the first tab when the platform lacks it.
  final MeshCoreTransportType initialTransport;

  const ConnectScreen({
    super.key,
    this.initialTransport = MeshCoreTransportType.bluetooth,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late final List<MeshCoreTransportType> _transports;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _transports = [
      MeshCoreTransportType.bluetooth,
      if (PlatformInfo.supportsUsbSerial) MeshCoreTransportType.usb,
      if (!PlatformInfo.isWeb) MeshCoreTransportType.tcp,
    ];
    _tabController = TabController(
      length: _transports.length,
      initialIndex: math.max(0, _transports.indexOf(widget.initialTransport)),
      vsync: this,
    )..addListener(_closeKeyboardLeavingTcp);
  }

  /// A focused field keeps the TCP tab alive and the keyboard open.
  void _closeKeyboardLeavingTcp() {
    final focus = FocusManager.instance.primaryFocus;
    if (_transports[_tabController.previousIndex] ==
            MeshCoreTransportType.tcp &&
        focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) {
      focus!.unfocus();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.select<MeshCoreConnector, MeshCoreConnectionState>(
      (connector) => connector.state,
    );
    // On a short screen, an open keyboard leaves room only for the TCP form.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final cramped =
        keyboard > 0 && MediaQuery.sizeOf(context).height - keyboard < 400;
    // Leaving a tab cancels its connection, so tabs stay put meanwhile.
    final locked =
        state == MeshCoreConnectionState.connecting ||
        state == MeshCoreConnectionState.disconnecting;
    final tabBar = TabBar(
      controller: _tabController,
      tabs: [
        for (final transport in _transports)
          Tab(
            icon: Icon(switch (transport) {
              MeshCoreTransportType.usb => Icons.usb,
              MeshCoreTransportType.tcp => Icons.lan,
              _ => Icons.bluetooth,
            }),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(switch (transport) {
                MeshCoreTransportType.usb => l10n.connectionChoiceUsbLabel,
                MeshCoreTransportType.tcp => l10n.connectionChoiceTcpLabel,
                _ => l10n.connectionChoiceBluetoothLabel,
              }),
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: ReviewModeLongPress(
          child: AdaptiveAppBarTitle(l10n.connectSheet_title),
        ),
        centerTitle: true,
        bottom: cramped
            ? null
            : PreferredSize(
                preferredSize: tabBar.preferredSize,
                child: ExcludeFocus(
                  excluding: locked,
                  child: IgnorePointer(
                    ignoring: locked,
                    child: Opacity(opacity: locked ? 0.5 : 1, child: tabBar),
                  ),
                ),
              ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!cramped)
              Consumer<MeshCoreConnector>(
                builder: (context, connector, _) =>
                    _ConnectionStatusHeader(connector: connector),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: locked ? const NeverScrollableScrollPhysics() : null,
                children: [
                  // Its own messenger lets a tab's snackbar lift its FAB.
                  for (final transport in _transports)
                    ScaffoldMessenger(
                      child: switch (transport) {
                        MeshCoreTransportType.usb => const UsbScreen(),
                        MeshCoreTransportType.tcp => const TcpScreen(),
                        _ => const ScannerScreen(),
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const GetNodeBanner(),
    );
  }
}

/// Connection status header with AnimatedSwitcher between states.
class _ConnectionStatusHeader extends StatelessWidget {
  final MeshCoreConnector connector;

  const _ConnectionStatusHeader({required this.connector});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final connectedName = switch (connector.activeTransport) {
      MeshCoreTransportType.usb =>
        connector.activeUsbPortDisplayLabel ?? l10n.connectionChoiceUsbLabel,
      MeshCoreTransportType.tcp =>
        connector.activeTcpEndpoint ?? l10n.connectionChoiceTcpLabel,
      _ => connector.deviceDisplayName,
    };

    final (String label, Color color, bool pulse) = switch (connector.state) {
      MeshCoreConnectionState.scanning => (
        l10n.scanner_scanning,
        MeshPalette.blue,
        true,
      ),
      MeshCoreConnectionState.connecting => (
        l10n.scanner_connecting,
        MeshPalette.warn,
        true,
      ),
      MeshCoreConnectionState.connected => (
        l10n.scanner_connectedTo(connectedName),
        MeshPalette.signal,
        false,
      ),
      MeshCoreConnectionState.disconnecting => (
        l10n.scanner_disconnecting,
        MeshPalette.warn,
        true,
      ),
      MeshCoreConnectionState.disconnected => (
        l10n.scanner_notConnected,
        scheme.onSurfaceVariant,
        false,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Align(
          key: ValueKey(connector.state),
          alignment: Alignment.centerLeft,
          child: StatusChip(label: label, color: color, pulse: pulse),
        ),
      ),
    );
  }
}
