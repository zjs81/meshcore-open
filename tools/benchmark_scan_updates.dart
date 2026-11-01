import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/screens/ble_debug_log_screen.dart';
import 'package:meshcore_open/screens/scanner_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';
import 'package:meshcore_open/services/chat_text_scale_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/utils/scan_update_throttle.dart';

class _ImmediateBleDebugLogService extends BleDebugLogService {
  _ImmediateBleDebugLogService() : super(notifyInterval: Duration.zero);
}

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

double _cpuSeconds(int ticksPerSecond) {
  final stat = File('/proc/self/stat').readAsStringSync();
  final fields = stat.substring(stat.lastIndexOf(')') + 2).split(' ');
  return (int.parse(fields[11]) + int.parse(fields[12])) / ticksPerSecond;
}

Map<String, ({String name, int ticks, String waitChannel})> _threadCpuTicks() {
  final samples = <String, ({String name, int ticks, String waitChannel})>{};
  for (final entry in Directory('/proc/self/task').listSync()) {
    try {
      final stat = File('${entry.path}/stat').readAsStringSync();
      final endName = stat.lastIndexOf(')');
      final fields = stat.substring(endName + 2).split(' ');
      samples[entry.path.split('/').last] = (
        name: stat.substring(stat.indexOf('(') + 1, endName),
        ticks: int.parse(fields[11]) + int.parse(fields[12]),
        waitChannel: File('${entry.path}/wchan').readAsStringSync().trim(),
      );
    } on FileSystemException {
      continue;
    }
  }
  return samples;
}

double _percentile(List<int> values, double fraction) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * fraction).ceil()] / 1000;
}

Future<void> _replay(UiReplayConnector connector, int rate, int seconds) async {
  if (rate == 0) {
    await Future<void>.delayed(Duration(seconds: seconds));
    return;
  }
  final done = Completer<void>();
  var remaining = rate * seconds;
  Timer.periodic(Duration(microseconds: 1000000 ~/ rate), (timer) {
    connector.ingest();
    if (--remaining == 0) {
      timer.cancel();
      done.complete();
    }
  });
  await done.future;
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
          ? BleDebugLogScreen(
              initialRawLogRx: connector.scenario == 'ble-log-raw',
            )
          : const ScannerScreen(),
    ),
  );
}

Future<void> _measureUsb({
  required String port,
  required int seconds,
  required int warmup,
  required int ticksPerSecond,
  required int Function() errorCount,
}) async {
  final connector = MeshCoreConnector();
  final retryService = MessageRetryService();
  connector.initialize(
    retryService: retryService,
    pathHistoryService: PathHistoryService(StorageService()),
  );
  var frames = 0;
  final subscription = connector.receivedFrames.listen((_) => frames++);
  runApp(buildUiBenchmarkApp(connector, usbControl: true));
  await WidgetsBinding.instance.endOfFrame;
  stdout.writeln('USB_CONTROL connecting $port');
  await connector.connectUsb(portName: port);
  final syncElapsed = Stopwatch()..start();
  while (!connector.hasLoadedContacts ||
      !connector.hasLoadedChannels ||
      connector.isLoadingContacts ||
      connector.isSyncingChannels ||
      connector.isSyncingQueuedMessages) {
    if (syncElapsed.elapsed > const Duration(minutes: 3)) {
      throw StateError('USB initial sync did not finish within three minutes');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  stdout.writeln('USB_CONTROL initial sync complete');
  await Future<void>.delayed(Duration(seconds: warmup));
  if (!connector.isConnected || !connector.isUsbTransportConnected) {
    throw StateError('USB control disconnected during warmup');
  }
  var connectionLost = false;
  var notifications = 0;
  void countNotification() => notifications++;
  connector.addListener(countNotification);
  final initialFrames = frames;
  final monitor = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!connector.isConnected || !connector.isUsbTransportConnected) {
      connectionLost = true;
    }
    if (timer.tick % 60 == 0) {
      stdout.writeln(
        'USB_CONTROL elapsed ${timer.tick}s, received ${frames - initialFrames} frames',
      );
    }
  });
  final initialThreads = _threadCpuTicks();
  final cpuStart = _cpuSeconds(ticksPerSecond);
  final elapsed = Stopwatch()..start();
  stdout.writeln('USB_CONTROL measuring $seconds seconds');
  await Future<void>.delayed(Duration(seconds: seconds));
  final cpuSeconds = _cpuSeconds(ticksPerSecond) - cpuStart;
  elapsed.stop();
  final finalThreads = _threadCpuTicks();
  monitor.cancel();
  connector.removeListener(countNotification);
  final connected = connector.isConnected && connector.isUsbTransportConnected;
  final wallSeconds = elapsed.elapsedMicroseconds / 1000000;
  final threadCpu =
      [
        for (final entry in finalThreads.entries)
          {
            'tid': entry.key,
            'name': entry.value.name,
            'cpu_seconds':
                (entry.value.ticks - (initialThreads[entry.key]?.ticks ?? 0)) /
                ticksPerSecond,
            'wait_channel_at_end': entry.value.waitChannel,
          },
      ]..sort(
        (first, second) => (second['cpu_seconds'] as double).compareTo(
          first['cpu_seconds'] as double,
        ),
      );
  final result = {
    'workload': 'usb_connected_idle_static_control',
    'port': port,
    'resolved_port': File(port).resolveSymbolicLinksSync(),
    'baud_rate': 115200,
    'warmup_seconds': warmup,
    'wall_seconds': wallSeconds,
    'cpu_seconds': cpuSeconds,
    'cpu_percent': 100 * cpuSeconds / wallSeconds,
    'rss_bytes': ProcessInfo.currentRss,
    'received_frames': frames - initialFrames,
    'notifications': notifications,
    'connected_at_end': connected,
    'connection_lost': connectionLost,
    'flutter_errors': errorCount(),
    'top_threads': threadCpu.take(8).toList(),
    'valid': connected && !connectionLost && errorCount() == 0,
  };
  stdout.writeln('USB_CONTROL ${jsonEncode(result)}');
  if (!connected || connectionLost || errorCount() != 0) {
    throw StateError('USB control did not remain healthy');
  }
  final requestLatenciesMs = <int>[];
  for (var index = 0; index < 20; index++) {
    final requestElapsed = Stopwatch()..start();
    final response = connector.receivedFrames
        .firstWhere((frame) => frame.isNotEmpty && frame[0] == respCodeCurrTime)
        .timeout(const Duration(seconds: 3));
    await connector.sendFrame(buildGetDeviceTimeFrame());
    await response;
    requestElapsed.stop();
    requestLatenciesMs.add(requestElapsed.elapsedMilliseconds);
  }
  requestLatenciesMs.sort();
  stdout.writeln(
    'USB_REQUEST_LATENCY ${jsonEncode({'command': 'CMD_GET_DEVICE_TIME', 'requests': requestLatenciesMs.length, 'p50_ms': requestLatenciesMs[requestLatenciesMs.length ~/ 2], 'p95_ms': requestLatenciesMs[((requestLatenciesMs.length - 1) * 0.95).ceil()], 'max_ms': requestLatenciesMs.last, 'all_replied': requestLatenciesMs.length == 20})}',
  );
  for (var cycle = 1; cycle <= 3; cycle++) {
    await connector
        .disconnect(manual: true)
        .timeout(const Duration(seconds: 60));
    await connector.connectUsb(portName: port);
    if (!connector.isConnected || !connector.isUsbTransportConnected) {
      throw StateError('USB reconnect $cycle failed');
    }
    stdout.writeln('USB_CONTROL reconnect $cycle passed');
  }
  await connector.disconnect(manual: true).timeout(const Duration(seconds: 60));
  final disconnectedCpuStart = _cpuSeconds(ticksPerSecond);
  final disconnectedElapsed = Stopwatch()..start();
  await Future<void>.delayed(const Duration(seconds: 5));
  final disconnectedCpu = _cpuSeconds(ticksPerSecond) - disconnectedCpuStart;
  disconnectedElapsed.stop();
  final disconnectedResult = {
    'cpu_seconds': disconnectedCpu,
    'wall_seconds': disconnectedElapsed.elapsedMicroseconds / 1000000,
    'cpu_percent':
        100 *
        disconnectedCpu /
        (disconnectedElapsed.elapsedMicroseconds / 1000000),
    'disconnected':
        !connector.isConnected && !connector.isUsbTransportConnected,
  };
  stdout.writeln('USB_AFTER_DISCONNECT ${jsonEncode(disconnectedResult)}');
  await subscription.cancel();
  connector.dispose();
  retryService.dispose();
  exit(errorCount() == 0 ? 0 : 1);
}

Future<void> _runBenchmark(List<String> arguments) async {
  final options = Map.fromEntries(
    arguments.map((argument) {
      final separator = argument.indexOf('=');
      if (!argument.startsWith('--') || separator < 0) {
        throw ArgumentError('Expected --name=value, got $argument');
      }
      return MapEntry(
        argument.substring(2, separator),
        argument.substring(separator + 1),
      );
    }),
  );
  const allowed = {
    'policy',
    'rate',
    'seconds',
    'warmup',
    'devices',
    'usb',
    'scenario',
    'history',
  };
  if (options.keys.any((key) => !allowed.contains(key))) {
    throw ArgumentError('Unknown benchmark options: $options');
  }
  final usbPort = options['usb'];
  if (usbPort != null &&
      (Platform.environment['XDG_CONFIG_HOME'] == null ||
          Platform.environment['XDG_DATA_HOME'] == null)) {
    throw ArgumentError(
      'USB control requires isolated XDG_CONFIG_HOME and XDG_DATA_HOME',
    );
  }
  final policy = options['policy'] ?? 'current';
  final scenario = options['scenario'] ?? 'scanner';
  final history = int.parse(options['history'] ?? '1000');
  final rate = int.parse(options['rate'] ?? (usbPort == null ? '20' : '0'));
  final seconds = int.parse(options['seconds'] ?? '30');
  final warmup = int.parse(options['warmup'] ?? (usbPort == null ? '5' : '60'));
  final devices = int.parse(options['devices'] ?? '12');
  if (!Platform.isLinux ||
      !{'baseline', 'current'}.contains(policy) ||
      rate < 0 ||
      rate > 1000 ||
      seconds < 1 ||
      warmup < 1 ||
      devices < 1 ||
      devices > 255 ||
      history < 1 ||
      history > 10000 ||
      !{
        'scanner',
        'chat-notify',
        'chat-arrival',
        'chat-status',
        'ble-log',
        'ble-log-raw',
      }.contains(scenario)) {
    throw ArgumentError('Invalid Linux scan benchmark options: $options');
  }

  WidgetsFlutterBinding.ensureInitialized();
  var errors = 0;
  FlutterError.onError = (details) {
    errors++;
    stderr.writeln('BENCHMARK_FLUTTER_ERROR ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };
  await PrefsManager.initialize();
  await PrefsManager.instance.setString('node_banner_txt', 'v=1;on=0');
  await PrefsManager.instance.setInt(
    'node_banner_expires_ms',
    DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
  );
  final tickResult = Process.runSync('getconf', ['CLK_TCK']);
  if (tickResult.exitCode != 0) {
    throw StateError('getconf CLK_TCK failed: ${tickResult.stderr}');
  }
  final ticksPerSecond = int.parse((tickResult.stdout as String).trim());
  if (usbPort != null) {
    await _measureUsb(
      port: usbPort,
      seconds: seconds,
      warmup: warmup,
      ticksPerSecond: ticksPerSecond,
      errorCount: () => errors,
    );
    return;
  }
  final connector = UiReplayConnector(
    throttled: policy == 'current',
    devices: devices,
    scenario: scenario,
    history: history,
    bleDebugLogService: scenario.startsWith('ble-log')
        ? (policy == 'baseline'
              ? _ImmediateBleDebugLogService()
              : BleDebugLogService())
        : null,
  );
  runApp(buildUiBenchmarkApp(connector));
  await WidgetsBinding.instance.endOfFrame;
  await _replay(connector, rate, warmup);
  await Future<void>.delayed(const Duration(milliseconds: 400));

  final buildUs = <int>[];
  final rasterUs = <int>[];
  final refreshRate = WidgetsBinding
      .instance
      .platformDispatcher
      .views
      .first
      .display
      .refreshRate;
  final frameBudgetUs = 1000000 / (refreshRate > 0 ? refreshRate : 60);
  var overBudget = 0;
  void recordFrames(List<FrameTiming> timings) {
    for (final timing in timings) {
      buildUs.add(timing.buildDuration.inMicroseconds);
      rasterUs.add(timing.rasterDuration.inMicroseconds);
      if (math.max(buildUs.last, rasterUs.last) > frameBudgetUs) overBudget++;
    }
  }

  SchedulerBinding.instance.addTimingsCallback(recordFrames);
  connector.deliveryAgesUs.clear();
  final initialEvents = connector.events;
  final initialNotifications = connector.notifications;
  final cpuStart = _cpuSeconds(ticksPerSecond);
  final elapsed = Stopwatch()..start();
  await _replay(connector, rate, seconds);
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final cpuSeconds = _cpuSeconds(ticksPerSecond) - cpuStart;
  elapsed.stop();
  SchedulerBinding.instance.removeTimingsCallback(recordFrames);
  final wallSeconds = elapsed.elapsedMicroseconds / 1000000;
  final events = connector.events - initialEvents;
  final valid =
      errors == 0 &&
      events == rate * seconds &&
      connector.lastNotifiedEvent == connector.events &&
      (buildUs.isNotEmpty || (scenario != 'scanner' && rate == 0));
  final result = {
    'schema': 2,
    'workload': scenario == 'scanner'
        ? 'synthetic_scanner_replay'
        : 'synthetic_chat_replay',
    'scenario': scenario,
    'history': history,
    'final_message_count': connector.messages.length,
    'policy': policy,
    'rate_hz': rate,
    'devices': devices,
    'requested_seconds': seconds,
    'warmup_seconds': warmup,
    'wall_seconds': wallSeconds,
    'cpu_seconds': cpuSeconds,
    'cpu_percent': 100 * cpuSeconds / wallSeconds,
    'rss_bytes': ProcessInfo.currentRss,
    'events': events,
    'notifications': connector.notifications - initialNotifications,
    'final_event_notified': connector.lastNotifiedEvent == connector.events,
    'listener_age_p95_ms': _percentile(connector.deliveryAgesUs, 0.95),
    'listener_age_max_ms': _percentile(connector.deliveryAgesUs, 1),
    'frames': buildUs.length,
    'build_p95_ms': _percentile(buildUs, 0.95),
    'raster_p95_ms': _percentile(rasterUs, 0.95),
    'over_budget_frames': overBudget,
    'display_refresh_hz': refreshRate,
    'flutter_errors': errors,
    'valid': valid,
  };
  stdout.writeln('SCAN_BENCHMARK ${jsonEncode(result)}');
  connector.dispose();
  exit(valid ? 0 : 1);
}

Future<void> main(List<String> arguments) async {
  try {
    await _runBenchmark(arguments);
  } catch (error, stack) {
    stderr.writeln('BENCHMARK_FAILED $error\n$stack');
    exit(1);
  }
}
