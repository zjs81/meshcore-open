import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../utils/platform_info.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../helpers/snack_bar_builder.dart';
import 'contacts_screen.dart';
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
  bool _navigatedToContacts = false;

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
        _navigatedToContacts = false;
      }
      if (_connector.state == MeshCoreConnectionState.connected &&
          _connector.isTcpTransportConnected &&
          !_navigatedToContacts) {
        context.read<AppSettingsService>().setTcpServerAddress(
          _hostController.text,
        );
        context.read<AppSettingsService>().setTcpServerPort(
          int.tryParse(_portController.text) ?? 0,
        );
        _navigatedToContacts = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ContactsScreen()),
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
    if (!_navigatedToContacts &&
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
            final isButtonDisabled =
                isConnecting ||
                connector.state == MeshCoreConnectionState.scanning;
            return Column(
              children: [
                _buildStatusBar(context, connector),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _hostController,
                        decoration: InputDecoration(
                          labelText: context.l10n.tcpHostLabel,
                          hintText: context.l10n.tcpHostHint,
                          border: const OutlineInputBorder(),
                        ),
                        enabled: !isConnecting,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _portController,
                        decoration: InputDecoration(
                          labelText: context.l10n.tcpPortLabel,
                          hintText: context.l10n.tcpPortHint,
                          border: const OutlineInputBorder(),
                        ),
                        enabled: !isConnecting,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('tcp_connect_button'),
                        onPressed: isButtonDisabled ? null : _connectTcp,
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
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (PlatformInfo.supportsUsbSerial)
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const UsbScreen()),
                    );
                  },
                  heroTag: 'tcp_usb_action',
                  extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
                  icon: const Icon(Icons.usb),
                  label: Text(context.l10n.connectionChoiceUsbLabel),
                ),
              if (PlatformInfo.supportsUsbSerial) const SizedBox(width: 12),
              FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                heroTag: 'tcp_ble_action',
                extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.bluetooth),
                label: Text(context.l10n.connectionChoiceBluetoothLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    String statusText;
    Color statusColor;

    if (connector.isTcpTransportConnected) {
      statusText = l10n.scanner_connectedTo(
        connector.activeTcpEndpoint ?? 'TCP',
      );
      statusColor = Colors.green;
    } else if (connector.state == MeshCoreConnectionState.connecting &&
        connector.activeTransport == MeshCoreTransportType.tcp) {
      statusText = l10n.tcpStatus_connectingTo(
        '${_hostController.text}:${_portController.text}',
      );
      statusColor = Colors.orange;
    } else if (connector.state == MeshCoreConnectionState.disconnecting &&
        connector.activeTransport == MeshCoreTransportType.tcp) {
      statusText = l10n.scanner_disconnecting;
      statusColor = Colors.orange;
    } else {
      statusText = l10n.tcpStatus_notConnected;
      statusColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
    if (host.isEmpty) {
      _showError(context.l10n.tcpErrorHostRequired);
      return;
    }
    if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
      _showError(context.l10n.tcpErrorPortInvalid);
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
      backgroundColor: Colors.red,
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
