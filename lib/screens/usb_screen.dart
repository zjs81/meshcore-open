import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';
import '../utils/usb_port_labels.dart';
import '../widgets/device_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/mesh_ui.dart';
import '../helpers/snack_bar_builder.dart';
import '../utils/main_navigation.dart';

class UsbScreen extends StatefulWidget {
  const UsbScreen({super.key});

  @override
  State<UsbScreen> createState() => _UsbScreenState();
}

class _UsbScreenState extends State<UsbScreen> with WidgetsBindingObserver {
  final List<String> _ports = <String>[];
  bool _isLoadingPorts = true;
  String? _connectingPort;
  bool _navigatedToChannels = false;
  bool _didScheduleInitialLoad = false;
  Timer? _hotPlugTimer;
  late final MeshCoreConnector _connector;
  late final VoidCallback _connectionListener;

  bool get _supportsHotPlug =>
      PlatformInfo.isWindows || PlatformInfo.isLinux || PlatformInfo.isMacOS;

  /// Desktop hot-plugs automatically; web uses the port-picker button.
  bool get _showRefreshButton => !_supportsHotPlug && !PlatformInfo.isWeb;

  /// Web Serial lists a synthetic "request a port" entry plus ports the user
  /// already authorised; the request entry opens the browser's port picker.
  static const String _webRequestPortName = 'web:request';

  bool _isWebRequestEntry(String port) =>
      normalizeUsbPortName(port) == _webRequestPortName;

  @override
  void initState() {
    super.initState();
    _connector = context.read<MeshCoreConnector>();
    _connectionListener = () {
      if (!mounted) return;
      if (_connector.state == MeshCoreConnectionState.disconnected) {
        _navigatedToChannels = false;
      }
      if (_connector.state == MeshCoreConnectionState.connected &&
          _connector.isUsbTransportConnected &&
          !_navigatedToChannels) {
        _navigatedToChannels = true;
        navigateToMainAfterConnect(context);
      }
    };
    _connector.addListener(_connectionListener);
    WidgetsBinding.instance.addObserver(this);
    _startHotPlugTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Polling the serial ports in the background wastes power; stop while
    // the app isn't in the foreground and resume when it returns.
    if (state == AppLifecycleState.resumed) {
      if (_supportsHotPlug && _hotPlugTimer == null) {
        _startHotPlugTimer();
        unawaited(_pollHotPlug());
      }
    } else {
      _hotPlugTimer?.cancel();
      _hotPlugTimer = null;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _hotPlugTimer?.cancel();
    _hotPlugTimer = null;
    _connector.removeListener(_connectionListener);
    if (!_navigatedToChannels &&
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
      body: SafeArea(
        top: false,
        child: Consumer<MeshCoreConnector>(
          builder: (context, connector, child) =>
              _buildPortList(context, connector),
        ),
      ),
      floatingActionButton: _showRefreshButton
          ? FloatingActionButton.extended(
              onPressed: _isLoadingPorts ? null : _loadPorts,
              heroTag: 'usb_refresh_action',
              icon: _isLoadingPorts
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(context.l10n.repeater_refresh),
            )
          : null,
    );
  }

  Widget _buildPortList(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;

    final isConnecting =
        connector.state == MeshCoreConnectionState.connecting &&
        connector.activeTransport == MeshCoreTransportType.usb;

    if (PlatformInfo.isWeb) {
      return _buildWebPortPicker(context, connector, isConnecting);
    }

    if (_isLoadingPorts) {
      return EmptyState(icon: Icons.usb, title: l10n.usbStatus_searching);
    }

    if (_ports.isEmpty) {
      return EmptyState(
        icon: Icons.usb,
        title: _supportsHotPlug
            ? l10n.usbScreenEmptyStateAuto
            : l10n.usbScreenEmptyState,
      );
    }

    return _buildPortListView(context, _ports, isConnecting);
  }

  /// Web: one prominent button opens the browser's serial-port picker;
  /// ports the user already authorised are listed below it for reconnects.
  Widget _buildWebPortPicker(
    BuildContext context,
    MeshCoreConnector connector,
    bool isConnecting,
  ) {
    final authorizedPorts = _ports
        .where((port) => !_isWebRequestEntry(port))
        .toList();
    final canConnect =
        !isConnecting &&
        connector.state == MeshCoreConnectionState.disconnected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            key: const Key('usb_choose_serial_port_button'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: canConnect
                ? () {
                    HapticFeedback.selectionClick();
                    _connectPort(_webRequestPortName);
                  }
                : null,
            icon: isConnecting && _connectingPort == _webRequestPortName
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.usb),
            label: Text(
              context.l10n.usbChooseSerialPort,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (authorizedPorts.isNotEmpty)
          Expanded(
            child: _buildPortListView(context, authorizedPorts, isConnecting),
          ),
      ],
    );
  }

  Widget _buildPortListView(
    BuildContext context,
    List<String> ports,
    bool isConnecting,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: _showRefreshButton ? 88 : 32),
      itemCount: ports.length,
      itemBuilder: (context, index) {
        final port = ports[index];
        final displayName = friendlyUsbPortName(port);
        final rawName = normalizeUsbPortName(port);
        final showRawName =
            rawName != displayName && !rawName.startsWith('web:');

        return ListEntrance(
          index: index,
          child: DeviceTile(
            name: displayName,
            id: showRawName ? rawName : null,
            icon: Icons.usb,
            color: Theme.of(context).colorScheme.primary,
            isConnecting: isConnecting && _connectingPort == port,
            onTap: isConnecting ? null : () => _connectPort(port),
          ),
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
    // Skip while another screen covers this one.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
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

    setState(() => _connectingPort = port);
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
    } finally {
      if (mounted) setState(() => _connectingPort = null);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    // Cancelling the browser's serial port picker is a normal user action, not
    // an error — don't show a scary red toast (and never leak the raw
    // DOMException text).
    if (_isUserCancelledPortPicker(error)) return;
    showDismissibleSnackBar(
      context,
      content: Text(_friendlyErrorMessage(error)),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  bool _isUserCancelledPortPicker(Object error) {
    if (error is StateError &&
        error.message.contains('No USB serial device selected')) {
      return true;
    }
    final text = error.toString();
    return text.contains('No port selected by the user') ||
        text.contains("Failed to execute 'requestPort'");
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
