import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/platform_info.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_ui.dart';
import '../helpers/snack_bar_builder.dart';
import 'channels_screen.dart';
import 'usb_screen.dart';

class TcpScreen extends StatefulWidget {
  const TcpScreen({super.key});

  @override
  State<TcpScreen> createState() => _TcpScreenState();
}

class _TcpScreenState extends State<TcpScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final MeshCoreConnector _connector;
  late final VoidCallback _connectionListener;
  bool _navigatedToChannels = false;
  String? _hostError;
  String? _portError;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(
      text: context.read<AppSettingsService>().settings.tcpServerAddress,
    );
    _portController = TextEditingController(
      text: context.read<AppSettingsService>().settings.tcpServerPort > 0
          ? context.read<AppSettingsService>().settings.tcpServerPort.toString()
          : '',
    );
    _connector = context.read<MeshCoreConnector>();

    _connectionListener = () {
      if (!mounted) return;
      if (_connector.state == MeshCoreConnectionState.disconnected) {
        _navigatedToChannels = false;
      }
      // Only navigate while this route is on top; otherwise a reconnect
      // would replace whatever screen the user has pushed above it.
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
      if (_connector.state == MeshCoreConnectionState.connected &&
          _connector.isTcpTransportConnected &&
          isCurrentRoute &&
          !_navigatedToChannels) {
        context.read<AppSettingsService>().setTcpServerAddress(
          _hostController.text,
        );
        context.read<AppSettingsService>().setTcpServerPort(
          int.tryParse(_portController.text) ?? 0,
        );
        _navigatedToChannels = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChannelsScreen()),
        );
      }
    };
    _connector.addListener(_connectionListener);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _connector.removeListener(_connectionListener);
    if (!_navigatedToChannels &&
        _connector.activeTransport == MeshCoreTransportType.tcp &&
        _connector.state != MeshCoreConnectionState.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_connector.disconnect(manual: true));
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AdaptiveAppBarTitle(context.l10n.tcpScreenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<MeshCoreConnector>(
          builder: (context, connector, child) {
            final isConnecting =
                connector.state == MeshCoreConnectionState.connecting &&
                connector.activeTransport == MeshCoreTransportType.tcp;
            // Connect is only available from a fully disconnected state —
            // scanning, connecting, or an active session must settle first.
            final isButtonDisabled =
                connector.state != MeshCoreConnectionState.disconnected;
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Status header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Align(
                      key: ValueKey(connector.state),
                      alignment: Alignment.centerLeft,
                      child: _buildStatusChip(context, connector),
                    ),
                  ),
                ),

                // Transport switcher
                _buildTransportLinks(context),

                // Connection form
                SectionHeader(context.l10n.tcpSectionTitle),
                MeshCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _hostController,
                        decoration: InputDecoration(
                          labelText: context.l10n.tcpHostLabel,
                          hintText: context.l10n.tcpHostHint,
                          errorText: _hostError,
                          errorMaxLines: 3,
                        ),
                        enabled: !isConnecting,
                        keyboardType: TextInputType.url,
                        onChanged: (_) {
                          if (_hostError != null) {
                            setState(() => _hostError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _portController,
                        decoration: InputDecoration(
                          labelText: context.l10n.tcpPortLabel,
                          hintText: context.l10n.tcpPortHint,
                          errorText: _portError,
                          errorMaxLines: 3,
                        ),
                        enabled: !isConnecting,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_portError != null) {
                            setState(() => _portError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('tcp_connect_button'),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _connectTcp();
                              },
                        icon: isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lan),
                        label: Text(
                          isConnecting
                              ? context.l10n.scanner_connecting
                              : context.l10n.common_connect,
                        ),
                      ),
                    ],
                  ),
                ),

                // Last used endpoint
                if (connector.activeTcpEndpoint != null &&
                    connector.isTcpTransportConnected) ...[
                  SectionHeader(context.l10n.tcpConnectedToHeader),
                  MeshCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lan,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            connector.activeTcpEndpoint!,
                            style: MeshTheme.mono(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;

    if (connector.isTcpTransportConnected) {
      return StatusChip(
        label: l10n.scanner_connectedTo(connector.activeTcpEndpoint ?? 'TCP'),
        color: MeshPalette.signal,
      );
    } else if (connector.state == MeshCoreConnectionState.connecting &&
        connector.activeTransport == MeshCoreTransportType.tcp) {
      return StatusChip(
        label: l10n.tcpStatus_connectingTo(
          '${_hostController.text}:${_portController.text}',
        ),
        color: MeshPalette.warn,
        pulse: true,
      );
    } else if (connector.state == MeshCoreConnectionState.disconnecting &&
        connector.activeTransport == MeshCoreTransportType.tcp) {
      return StatusChip(
        label: l10n.scanner_disconnecting,
        color: MeshPalette.warn,
        pulse: true,
      );
    } else {
      return StatusChip(
        label: l10n.tcpStatus_notConnected,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
  }

  Widget _buildTransportLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (PlatformInfo.supportsUsbSerial)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const UsbScreen()),
                );
              },
              icon: const Icon(Icons.usb),
              label: Text(context.l10n.connectionChoiceUsbLabel),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.bluetooth),
            label: Text(context.l10n.connectionChoiceBluetoothLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _connectTcp() async {
    if (_connector.state == MeshCoreConnectionState.connecting ||
        _connector.state == MeshCoreConnectionState.connected ||
        _connector.state == MeshCoreConnectionState.disconnecting) {
      return;
    }

    final host = _hostController.text.trim();
    final parsedPort = int.tryParse(_portController.text.trim());
    final hostError = host.isEmpty ? context.l10n.tcpErrorHostRequired : null;
    final portError = parsedPort == null || parsedPort < 1 || parsedPort > 65535
        ? context.l10n.tcpErrorPortInvalid
        : null;
    setState(() {
      _hostError = hostError;
      _portError = portError;
    });
    if (hostError != null || portError != null || parsedPort == null) {
      return;
    }

    try {
      await _connector.connectTcp(host: host, port: parsedPort);
    } catch (error) {
      if (!mounted) return;
      _showError(_friendlyErrorMessage(error));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is UnsupportedError) {
      return context.l10n.tcpErrorUnsupported;
    }
    if (error is TimeoutException) {
      return context.l10n.tcpErrorTimedOut;
    }
    if (error is StateError) {
      return context.l10n.tcpConnectionFailed(error.message);
    }
    if (error is ArgumentError) {
      return context.l10n.tcpConnectionFailed(
        error.message?.toString() ?? error.toString(),
      );
    }
    return context.l10n.tcpConnectionFailed(error.toString());
  }
}
