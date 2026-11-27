import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_tag.dart';
import '../utils/platform_info.dart';

class BackgroundService {
  /// Options for the service that keeps the link with the radio alive in
  /// the background.
  ///
  /// The link with the radio lives in the app's Flutter engine. Swiping the
  /// app away keeps the service (`android:stopWithTask="false"` in
  /// AndroidManifest.xml), and MainActivity keeps the engine while the
  /// service runs, so the link stays up until the user disconnects. An
  /// automatic restart would have no link, so it stays off, and a service
  /// that Android restarts on its own stops itself (see
  /// [MeshCoreTaskHandler.onStart]).
  ///
  /// `stopWithTask` must stay unset here: in flutter_foreground_task (9.2 to
  /// 11.0 at least) the option does not watch the task but stops the service
  /// as soon as no activity is resumed, which is every time the app goes to
  /// the background or the screen turns off. Android then caches and freezes
  /// the process, the Bluetooth link drops and the low-memory killer ends it.
  @visibleForTesting
  static final ForegroundTaskOptions taskOptions = ForegroundTaskOptions(
    // The service only has to exist; the task handler has no periodic work.
    eventAction: ForegroundTaskEventAction.nothing(),
    autoRunOnBoot: false,
    allowWifiLock: false,
    allowAutoRestart: false,
  );

  bool _initialized = false;
  String? Function()? _languageOverrideProvider;

  /// Allows the app to expose its current language override (e.g. from
  /// AppSettingsService) so the foreground notification matches the app UI
  /// language instead of only the system locale.
  void setLanguageOverrideProvider(String? Function()? provider) {
    _languageOverrideProvider = provider;
  }

  Future<void> initialize() async {
    if (!PlatformInfo.isAndroid || _initialized) return;
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
      foregroundTaskOptions: taskOptions,
    );
    _initialized = true;
  }

  Future<void> start() async {
    if (!PlatformInfo.isAndroid) return;
    if (!_initialized) {
      await initialize();
    }
    final running = await FlutterForegroundTask.isRunningService;
    if (running) return;
    final l10n = await _loadLocalizations();
    await FlutterForegroundTask.startService(
      notificationTitle: l10n.background_serviceTitle,
      notificationText: l10n.background_serviceText,
      notificationIcon: const NotificationIcon(
        metaDataName: 'org.meshcore.open.NOTIFICATION_ICON',
      ),
      callback: startCallback,
    );
  }

  Future<AppLocalizations> _loadLocalizations() async {
    final supported = AppLocalizations.supportedLocales;
    final override = _languageOverrideProvider?.call();
    if (override != null && override.isNotEmpty) {
      final overrideLocale = localeFromTag(override);
      final isSupported = supported.any(
        (l) => l.languageCode == overrideLocale.languageCode,
      );
      if (isSupported) {
        return AppLocalizations.delegate.load(overrideLocale);
      }
    }
    final preferred = WidgetsBinding.instance.platformDispatcher.locales;
    final match = basicLocaleListResolution(preferred, supported);
    return AppLocalizations.delegate.load(match);
  }

  static Future<void> openBatteryOptimizationSettings() async {
    if (!PlatformInfo.isAndroid) return;
    await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
  }

  Future<void> stop() async {
    if (!PlatformInfo.isAndroid) return;
    final running = await FlutterForegroundTask.isRunningService;
    if (!running) return;
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MeshCoreTaskHandler());
}

@visibleForTesting
class MeshCoreTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Android restarted the service after the app process died: there is no
    // link with the radio, so stop instead of showing a stale notification.
    if (starter == TaskStarter.system) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
