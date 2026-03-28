import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/platform_info.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/linux_ble_error_classifier.dart';
import '../utils/app_logger.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/device_tile.dart';
import 'contacts_screen.dart';
import 'tcp_screen.dart';
import 'usb_screen.dart';

/// Screen for scanning and connecting to MeshCore devices
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _changedNavigation = false;
  late final MeshCoreConnector _connector;
  late final VoidCallback _connectionListener;
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _bluetoothStateSubscription;

  @override
  void initState() {
    super.initState();
    _connector = Provider.of<MeshCoreConnector>(context, listen: false);

    _connectionListener = () {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
      if (_connector.state == MeshCoreConnectionState.disconnected) {
        _changedNavigation = false;
      } else if (_connector.state == MeshCoreConnectionState.connected &&
          _connector.activeTransport == MeshCoreTransportType.bluetooth &&
          isCurrentRoute &&
          !_changedNavigation) {
        _changedNavigation = true;
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        }
      }
    };

    _connector.addListener(_connectionListener);

    _bluetoothStateSubscription = FlutterBluePlus.adapterState.listen(
      (state) {
        if (mounted) {
          setState(() {
            _bluetoothState = state;
          });
          // Cancel scan if Bluetooth turns off while scanning
          if (state != BluetoothAdapterState.on) {
            unawaited(_connector.stopScan());
          }
        }
      },
      onError: (Object e) {
        appLogger.warn('Adapter state stream error: $e', tag: 'ScannerScreen');
      },
    );
  }

  @override
  void dispose() {
    _connector.removeListener(_connectionListener);
    unawaited(_bluetoothStateSubscription.cancel());
    if (!_changedNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_connector.disconnect(manual: true));
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  appLogger.info('Back button pressed', tag: 'ScannerScreen');
                  Navigator.of(context).maybePop();
                },
              )
            : null,
        title: AdaptiveAppBarTitle(context.l10n.scanner_title),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<MeshCoreConnector>(
          builder: (context, connector, child) {
            return Column(
              children: [
                // Bluetooth off warning
                if (_bluetoothState == BluetoothAdapterState.off)
                  _bluetoothOffWarning(context),

                // Status bar
                _buildStatusBar(context, connector),

                // Device list
                Expanded(child: _buildDeviceList(context, connector)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<MeshCoreConnector>(
        builder: (context, connector, child) {
          final isScanning =
              connector.state == MeshCoreConnectionState.scanning;
          final isBluetoothOff = _bluetoothState == BluetoothAdapterState.off;
          final usbSupported = PlatformInfo.supportsUsbSerial;
          final tcpSupported = !PlatformInfo.isWeb;

          return SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (usbSupported)
                    FloatingActionButton.extended(
                      onPressed: () {
                        appLogger.info(
                          'USB selected, opening UsbScreen',
                          tag: 'ScannerScreen',
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UsbScreen()),
                        );
                      },
                      heroTag: 'scanner_usb_action',
                      icon: const Icon(Icons.usb),
                      label: Text(context.l10n.connectionChoiceUsbLabel),
                    ),
                  if (usbSupported) const SizedBox(width: 12),
                  if (tcpSupported)
                    FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TcpScreen()),
                        );
                      },
                      heroTag: 'scanner_tcp_action',
                      icon: const Icon(Icons.lan),
                      label: Text(context.l10n.connectionChoiceTcpLabel),
                    ),
                  if (tcpSupported) const SizedBox(width: 12),
                  FloatingActionButton.extended(
                    heroTag: 'scanner_ble_action',
                    onPressed: isBluetoothOff
                        ? null
                        : () {
                            if (isScanning) {
                              connector.stopScan();
                            } else {
                              unawaited(
                                connector.startScan().catchError((e) {
                                  appLogger.warn(
                                    'startScan error: $e',
                                    tag: 'ScannerScreen',
                                  );
                                }),
                              );
                            }
                          },
                    icon: isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bluetooth_searching),
                    label: Text(
                      isScanning
                          ? context.l10n.scanner_stop
                          : context.l10n.scanner_scan,
                    ),
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
    String statusText;
    Color statusColor;

    final l10n = context.l10n;
    switch (connector.state) {
      case MeshCoreConnectionState.scanning:
        statusText = l10n.scanner_scanning;
        statusColor = Colors.blue;
        break;
      case MeshCoreConnectionState.connecting:
        statusText = l10n.scanner_connecting;
        statusColor = Colors.orange;
        break;
      case MeshCoreConnectionState.connected:
        statusText = l10n.scanner_connectedTo(connector.deviceDisplayName);
        statusColor = Colors.green;
        break;
      case MeshCoreConnectionState.disconnecting:
        statusText = l10n.scanner_disconnecting;
        statusColor = Colors.orange;
        break;
      case MeshCoreConnectionState.disconnected:
        statusText = l10n.scanner_notConnected;
        statusColor = Colors.grey;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, MeshCoreConnector connector) {
    if (connector.scanResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              connector.state == MeshCoreConnectionState.scanning
                  ? context.l10n.scanner_searchingDevices
                  : context.l10n.scanner_tapToScan,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: connector.scanResults.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final result = connector.scanResults[index];
        return DeviceTile(
          scanResult: result,
          onTap: () => _connectToDevice(context, connector, result),
        );
      },
    );
  }

  Future<void> _connectToDevice(
    BuildContext context,
    MeshCoreConnector connector,
    ScanResult result,
  ) async {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;
    try {
      await connector.connect(
        result.device,
        displayName: name,
        linuxPairingPinProvider: PlatformInfo.isLinux
            ? () async {
                if (!context.mounted) return null;
                return _promptLinuxPairingPin(context, name);
              }
            : null,
      );
    } catch (e) {
      final errorText = e.toString();
      final suppressTransientLinuxConnectError =
          PlatformInfo.isLinux &&
          connector.isAutoReconnectScheduled &&
          isLinuxBleConnectFailureText(errorText);
      if (suppressTransientLinuxConnectError) {
        appLogger.info(
          'Suppressing transient Linux connect error while auto-reconnect is active: $e',
          tag: 'ScannerScreen',
        );
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.scanner_connectionFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _promptLinuxPairingPin(
    BuildContext context,
    String deviceName,
  ) async {
    final l10n = context.l10n;
    var pinValue = '';
    var obscure = true;
    appLogger.info(
      'Showing Linux BLE pairing PIN prompt for $deviceName',
      tag: 'ScannerScreen',
    );
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.scanner_linuxPairingPinTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.scanner_linuxPairingPinPrompt(deviceName)),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      obscureText: obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: (value) {
                        pinValue = value.trim();
                      },
                      onSubmitted: (value) {
                        Navigator.of(dialogContext).pop(value.trim());
                      },
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscure = !obscure;
                            });
                          },
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          tooltip: obscure
                              ? l10n.scanner_linuxPairingShowPin
                              : l10n.scanner_linuxPairingHidePin,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(l10n.common_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(pinValue),
                  child: Text(l10n.common_connect),
                ),
              ],
            );
          },
        );
      },
    );
    if (pin == null) {
      appLogger.info(
        'Linux BLE pairing PIN prompt cancelled for $deviceName',
        tag: 'ScannerScreen',
      );
      return null;
    }
    appLogger.info(
      'Linux BLE pairing PIN prompt completed for $deviceName',
      tag: 'ScannerScreen',
    );
    return pin;
  }

  Widget _bluetoothOffWarning(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: errorColor.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.bluetooth_disabled, size: 24, color: errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.scanner_bluetoothOff,
                  style: TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.scanner_bluetoothOffMessage,
                  style: TextStyle(
                    color: errorColor.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (PlatformInfo.isAndroid)
            TextButton(
              onPressed: () => FlutterBluePlus.turnOn(),
              child: Text(context.l10n.scanner_enableBluetooth),
            ),
        ],
      ),
    );
  }
}
