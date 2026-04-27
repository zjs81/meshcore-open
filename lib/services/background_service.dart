import 'package:flutter/widgets.dart';
import '../utils/platform_info.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Manages a foreground service (Android) and app lifecycle awareness
/// (Android + iOS) to keep the BLE connection alive when the app is
/// backgrounded or swiped away from the recents drawer.
class BackgroundService with WidgetsBindingObserver {
  bool _initialized = false;
  bool _serviceRunning = false;

  /// Optional callback invoked when the OS resumes the app after it was
  /// paused or detached.  The connector hooks this to trigger a reconnect
  /// check so the BLE link is restored promptly.
  VoidCallback? onResume;

  /// Optional callback invoked when the app is about to be suspended.
  /// The connector can use this to persist critical state.
  VoidCallback? onPause;

  Future<void> initialize() async {
    if (_initialized) return;

    // Register for app lifecycle events on all mobile platforms.
    WidgetsBinding.instance.addObserver(this);

    if (PlatformInfo.isAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'meshcore_background',
          channelName: 'MeshCore Background',
          channelDescription: 'Keeps MeshCore running in the background.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          allowWifiLock: false,
        ),
      );
    }
    _initialized = true;
  }

  Future<void> start() async {
    if (!PlatformInfo.isMobile) return;
    if (!_initialized) {
      await initialize();
    }

    // Android: start the foreground service so the OS keeps the process alive
    // even when the user swipes the app away.
    if (PlatformInfo.isAndroid) {
      final running = await FlutterForegroundTask.isRunningService;
      if (!running) {
        await FlutterForegroundTask.startService(
          notificationTitle: 'MeshCore running',
          notificationText: 'Keeping BLE connected',
          callback: startCallback,
        );
      }
    }

    // iOS: the bluetooth-central UIBackgroundMode (Info.plist) combined with
    // CoreBluetooth state restoration (handled by flutter_blue_plus) keeps the
    // BLE connection alive.  No additional service is needed, but we track
    // the logical "running" state so callers behave consistently.
    _serviceRunning = true;
  }

  Future<void> stop() async {
    if (!PlatformInfo.isMobile) return;

    if (PlatformInfo.isAndroid) {
      final running = await FlutterForegroundTask.isRunningService;
      if (running) {
        await FlutterForegroundTask.stopService();
      }
    }
    _serviceRunning = false;
  }

  bool get isRunning => _serviceRunning;

  // ---------------------------------------------------------------------------
  // WidgetsBindingObserver – app lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume?.call();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        onPause?.call();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

// ---------------------------------------------------------------------------
// Foreground-service isolate entry point (Android)
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_MeshCoreTaskHandler());
}

class _MeshCoreTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // The handler runs in a separate isolate.  Its purpose is to keep the
    // foreground-service notification alive so that Android does not kill
    // the main isolate (where the BLE connection lives).
    //
    // Heavy BLE work stays in the main isolate; we just need the service
    // to exist.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodically update the notification so the system considers the
    // service active.  This also acts as a heartbeat.
    FlutterForegroundTask.updateService(
      notificationTitle: 'MeshCore running',
      notificationText:
          'Connected · ${timestamp.toLocal().hour.toString().padLeft(2, '0')}:${timestamp.toLocal().minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
