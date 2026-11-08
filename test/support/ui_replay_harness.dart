// Shared by widget tests and tools/benchmark_scan_updates.dart. Keep this
// file free of dart:io and process control so tests can import it anywhere.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/screens/ble_debug_log_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/screens/scanner_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';
import 'package:meshcore_open/services/chat_text_scale_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/utils/scan_update_throttle.dart';

class UiReplayConnector extends MeshCoreConnector {
  UiReplayConnector({
    required this.throttled,
    required int devices,
    this.scenario = 'scanner',
    this.bleDebugLogService,
    int history = 1000,
  }) {
    _devices = List.generate(
      devices,
      (index) => BluetoothDevice.fromId(
        '02:00:00:00:00:${index.toRadixString(16).padLeft(2, '0')}',
      ),
    );
    _throttle = ScanUpdateThrottle(onNotify: notifyListeners);
    if (scenario.startsWith('chat-')) {
      messages.addAll(List.generate(history, _message));
    }
    void recordNotification() {
      notifications++;
      lastNotifiedEvent = events;
      deliveryAgesUs.add(_clock.elapsedMicroseconds - lastEventUs);
    }

    if (bleDebugLogService != null) {
      bleDebugLogService!.addListener(recordNotification);
      _bleLogListener = recordNotification;
    } else {
      addListener(recordNotification);
    }
    ingest();
  }

  final bool throttled;
  final String scenario;
  final BleDebugLogService? bleDebugLogService;
  VoidCallback? _bleLogListener;
  Contact contact = Contact(
    publicKey: Uint8List.fromList(List.filled(32, 1)),
    name: 'Benchmark contact',
    type: 1,
    pathLength: -1,
    path: Uint8List(0),
    lastSeen: DateTime(2026, 1, 1),
  );
  final List<Message> messages = [];
  final Stopwatch _clock = Stopwatch()..start();
  late final List<BluetoothDevice> _devices;
  late final ScanUpdateThrottle _throttle;
  List<ScanResult> _results = [];
  int events = 0;
  int notifications = 0;
  int lastNotifiedEvent = 0;
  int lastEventUs = 0;
  final List<int> deliveryAgesUs = [];

  @override
  MeshCoreConnectionState get state => scenario == 'scanner'
      ? MeshCoreConnectionState.scanning
      : MeshCoreConnectionState.connected;

  @override
  bool get isConnected => scenario != 'scanner';

  @override
  List<Contact> get contacts => [contact];

  @override
  Contact? getContactByPubKeyHex(String contactPubKeyHex) =>
      contact.publicKeyHex == contactPubKeyHex ? contact : null;

  @override
  List<Message> getMessages(Contact contact) => messages;

  @override
  void setActiveContact(String? keyHex) {}

  Message _message(int index) => Message(
    senderKey: contact.publicKey,
    text: 'Benchmark message $index',
    timestamp: DateTime(2026, 1, 1).add(Duration(seconds: index)),
    isOutgoing: index.isOdd,
    status: MessageStatus.sent,
    messageId: 'benchmark-$index',
  );

  @override
  List<ScanResult> get scanResults => List.unmodifiable(_results);

  void ingest() {
    events++;
    lastEventUs = _clock.elapsedMicroseconds;
    if (scenario.startsWith('ble-log')) {
      final frame = scenario == 'ble-log-raw'
          ? Uint8List.fromList([
              pushCodeLogRxData,
              32,
              96,
              0x15,
              0,
              1,
              2,
              events & 0xFF,
            ])
          : Uint8List.fromList([respCodeOk, events & 0xFF]);
      bleDebugLogService!.logFrame(frame, outgoing: false);
      return;
    }
    if (scenario != 'scanner') {
      if (scenario == 'chat-arrival') {
        messages.add(_message(messages.length));
      } else if (scenario == 'chat-status' && messages.isNotEmpty) {
        messages[messages.length - 1] = messages.last.copyWith(
          status: events.isEven ? MessageStatus.sent : MessageStatus.delivered,
        );
      }
      notifyListeners();
      return;
    }
    _results = List.generate(
      _devices.length,
      (index) => ScanResult(
        device: _devices[index],
        advertisementData: AdvertisementData(
          advName: 'MeshCore benchmark $index',
          txPowerLevel: null,
          appearance: null,
          connectable: true,
          manufacturerData: const {},
          serviceData: const {},
          serviceUuids: const [],
        ),
        rssi: -50 - (events + index) % 40,
        timeStamp: DateTime.now(),
      ),
    );
    if (throttled) {
      _throttle.schedule();
    } else {
      notifyListeners();
    }
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {}

  @override
  Future<void> stopScan() async {}

  @override
  void dispose() {
    _throttle.dispose();
    final listener = _bleLogListener;
    if (listener != null) bleDebugLogService?.removeListener(listener);
    super.dispose();
  }
}

Widget buildUiBenchmarkApp(
  MeshCoreConnector connector, {
  bool usbControl = false,
}) {
  final chatConnector =
      connector is UiReplayConnector && connector.scenario.startsWith('chat-')
      ? connector
      : null;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
      if (connector is UiReplayConnector &&
          connector.bleDebugLogService != null)
        ChangeNotifierProvider<BleDebugLogService>.value(
          value: connector.bleDebugLogService!,
        ),
      if (chatConnector != null) ...[
        ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ChangeNotifierProvider(create: (_) => ChatTextScaleService()),
        ChangeNotifierProvider(
          create: (_) => PathHistoryService(StorageService()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TranslationService(context.read<AppSettingsService>()),
        ),
      ],
    ],
    child: MaterialApp(
      theme: MeshTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: usbControl
          ? const Scaffold(body: Center(child: Icon(Icons.usb, size: 48)))
          : chatConnector != null
          ? ChatScreen(contact: chatConnector.contact)
          : connector is UiReplayConnector &&
                connector.scenario.startsWith('ble-log')
          ? const BleDebugLogScreen()
          : const ScannerScreen(),
    ),
  );
}
