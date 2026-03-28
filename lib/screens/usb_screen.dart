import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';
import '../utils/usb_port_labels.dart';
import '../widgets/adaptive_app_bar_title.dart';
import 'contacts_screen.dart';
import 'scanner_screen.dart';
import 'tcp_screen.dart';

class UsbScreen extends StatefulWidget {
  const UsbScreen({super.key});

  @override
  State<UsbScreen> createState() => _UsbScreenState();
}

class _UsbScreenState extends State<UsbScreen> {
  final List<String> _ports = <String>[];
  bool _isLoadingPorts = true;
  bool _navigatedToContacts = false;
  bool _didScheduleInitialLoad = false;
  Timer? _hotPlugTimer;
  late final MeshCoreConnector _connector;
  late final VoidCallback _connectionListener;

  bool get _supportsHotPlug =>
      PlatformInfo.isWindows || PlatformInfo.isLinux || PlatformInfo.isMacOS;

  @override
  void initState() {
    super.initState();
    _connector = context.read<MeshCoreConnector>();
    _connectionListener = () {
      if (!mounted) return;
      if (_connector.state == MeshCoreConnectionState.disconnected) {
        _navigatedToContacts = false;
      }
      if (_connector.state == MeshCoreConnectionState.connected &&
          _connector.isUsbTransportConnected &&
          !_navigatedToContacts) {
        _navigatedToContacts = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ContactsScreen()),
        );
      }
    };
    _connector.addListener(_connectionListener);
    _startHotPlugTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connector.setUsbRequestPortLabel(context.l10n.usbScreenStatus);
    _connector.setUsbFallbackDeviceName(context.l10n.usbFallbackDeviceName);
    if (!_didScheduleInitialLoad) {
      _didScheduleInitialLoad = true;
      unawaited(_loadPorts());
    }
  }

  @override
  void dispose() {
    _hotPlugTimer?.cancel();
    _hotPlugTimer = null;
    _connector.removeListener(_connectionListener);
    if (!_navigatedToContacts &&
        _connector.activeTransport == MeshCoreTransportType.usb &&
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
        title: AdaptiveAppBarTitle(context.l10n.usbScreenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<MeshCoreConnector>(
          builder: (context, connector, child) {
            return Column(
              children: [
                _buildStatusBar(context, connector),
                Expanded(child: _buildPortList(context, connector)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<MeshCoreConnector>(
        builder: (context, connector, child) {
          final isLoading = _isLoadingPorts;
          final showBle = true;
          final showTcp = !PlatformInfo.isWeb;

          return SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showTcp)
                    FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const TcpScreen()),
                        );
                      },
                      heroTag: 'usb_tcp_action',
                      extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      icon: const Icon(Icons.lan),
                      label: Text(context.l10n.connectionChoiceTcpLabel),
                    ),
                  if (showTcp && showBle) const SizedBox(width: 12),
                  if (showBle)
                    FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ScannerScreen(),
                          ),
                        );
                      },
                      heroTag: 'usb_ble_action',
                      extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      icon: const Icon(Icons.bluetooth),
                      label: Text(context.l10n.connectionChoiceBluetoothLabel),
                    ),
                  if ((showTcp || showBle) && !_supportsHotPlug)
                    const SizedBox(width: 12),
                  if (!_supportsHotPlug)
                    FloatingActionButton.extended(
                      onPressed: isLoading ? null : _loadPorts,
                      heroTag: 'usb_refresh_action',
                      extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.usb),
                      label: Text(context.l10n.scanner_scan),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    String statusText;
    Color statusColor;

    if (_isLoadingPorts) {
      statusText = l10n.usbStatus_searching;
      statusColor = Colors.blue;
    } else if (connector.isUsbTransportConnected) {
      switch (connector.state) {
        case MeshCoreConnectionState.connected:
          statusText = l10n.scanner_connectedTo(
            connector.activeUsbPortDisplayLabel ?? 'USB',
          );
          statusColor = Colors.green;
        case MeshCoreConnectionState.disconnecting:
          statusText = l10n.scanner_disconnecting;
          statusColor = Colors.orange;
        default:
          statusText = l10n.usbStatus_notConnected;
          statusColor = Colors.grey;
      }
    } else if (connector.state == MeshCoreConnectionState.connecting &&
        connector.activeTransport == MeshCoreTransportType.usb) {
      statusText = l10n.usbStatus_connecting;
      statusColor = Colors.orange;
    } else {
      statusText = l10n.usbStatus_notConnected;
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

  Widget _buildPortList(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;

    if (_isLoadingPorts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.usb, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.usbStatus_searching,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_ports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.usb, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.usbScreenEmptyState,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final isConnecting =
        connector.state == MeshCoreConnectionState.connecting &&
        connector.activeTransport == MeshCoreTransportType.usb;

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _ports.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final port = _ports[index];
        final displayName = friendlyUsbPortName(port);
        final rawName = normalizeUsbPortName(port);
        final showRawName =
            rawName != displayName && !rawName.startsWith('web:');

        return ListTile(
          leading: const Icon(Icons.usb),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: showRawName ? Text(rawName) : null,
          trailing: ElevatedButton(
            onPressed: isConnecting ? null : () => _connectPort(port),
            child: Text(l10n.common_connect),
          ),
          onTap: isConnecting ? null : () => _connectPort(port),
        );
      },
    );
  }

  void _startHotPlugTimer() {
    if (!_supportsHotPlug) return;
    _hotPlugTimer?.cancel();
    _hotPlugTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollHotPlug();
    });
  }

  Future<void> _pollHotPlug() async {
    if (_isLoadingPorts) return;
    if (!mounted) return;
    // Don't poll while connecting or connected.
    if (_connector.state != MeshCoreConnectionState.disconnected) return;
    try {
      final ports = await _connector.listUsbPorts();
      if (!mounted) return;
      final added = ports.where((p) => !_ports.contains(p)).toList();
      final removed = _ports.where((p) => !ports.contains(p)).toList();
      if (added.isEmpty && removed.isEmpty) return;
      setState(() {
        _ports
          ..clear()
          ..addAll(ports);
      });
    } catch (_) {
      // Silent — hot-plug failures are non-critical.
    }
  }

  Future<void> _loadPorts() async {
    if (!mounted) return;
    _connector.setUsbRequestPortLabel(context.l10n.usbScreenStatus);

    setState(() {
      _isLoadingPorts = true;
    });

    try {
      final ports = await _connector.listUsbPorts();
      if (!mounted) return;
      setState(() {
        _ports
          ..clear()
          ..addAll(ports);
        _isLoadingPorts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ports.clear();
        _isLoadingPorts = false;
      });
      _showError(error);
    }
  }

  Future<void> _connectPort(String port) async {
    if (_connector.state != MeshCoreConnectionState.disconnected) return;

    final rawPortName = normalizeUsbPortName(port);
    appLogger.info(
      'Connect tapped for $port (raw: $rawPortName)',
      tag: 'UsbScreen',
    );

    try {
      await _connector.connectUsb(portName: rawPortName);
    } catch (error, stackTrace) {
      appLogger.error(
        'Connect failed for $rawPortName: $error\n$stackTrace',
        tag: 'UsbScreen',
      );
      if (!mounted) return;
      _showError(error);
      unawaited(_loadPorts());
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_friendlyErrorMessage(error)),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _friendlyErrorMessage(Object error) {
    final l10n = context.l10n;

    if (error is PlatformException) {
      switch (error.code) {
        case 'usb_permission_denied':
          return l10n.usbErrorPermissionDenied;
        case 'usb_device_missing':
        case 'usb_device_detached':
          return l10n.usbErrorDeviceMissing;
        case 'usb_invalid_port':
          return l10n.usbErrorInvalidPort;
        case 'usb_busy':
          return l10n.usbErrorBusy;
        case 'usb_not_connected':
          return l10n.usbErrorNotConnected;
        case 'usb_open_failed':
        case 'usb_driver_missing':
          return l10n.usbErrorOpenFailed;
        case 'usb_connect_failed':
          return l10n.usbErrorConnectFailed;
      }
    }

    if (error is UnsupportedError) {
      return l10n.usbErrorUnsupported;
    }

    if (error is StateError) {
      final msg = error.message;
      if (msg.contains('already active')) return l10n.usbErrorAlreadyActive;
      if (msg.contains('No USB serial device selected')) {
        return l10n.usbErrorNoDeviceSelected;
      }
      if (msg.contains('not open') || msg.contains('closed')) {
        return l10n.usbErrorPortClosed;
      }
      if (msg.contains('Timed out')) return l10n.usbErrorConnectTimedOut;
      if (msg.contains('Failed to open')) return l10n.usbErrorOpenFailed;
    }

    if (error is TimeoutException) {
      return l10n.usbErrorConnectTimedOut;
    }

    return error.toString();
  }
}
