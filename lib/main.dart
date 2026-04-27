import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/channel_chat_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/chrome_required_screen.dart';
import 'screens/discovery_screen.dart';
import 'utils/platform_info.dart';

import 'connector/meshcore_connector.dart';
import 'screens/scanner_screen.dart';
import 'services/storage_service.dart';
import 'services/message_retry_service.dart';
import 'services/path_history_service.dart';
import 'services/app_settings_service.dart';
import 'services/notification_service.dart';
import 'services/ble_debug_log_service.dart';
import 'services/app_debug_log_service.dart';
import 'services/background_service.dart';
import 'services/map_tile_cache_service.dart';
import 'services/chat_text_scale_service.dart';
import 'services/translation_service.dart';
import 'services/ui_view_state_service.dart';
import 'services/timeout_prediction_service.dart';
import 'storage/prefs_manager.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences cache
  await PrefsManager.initialize();

  // Initialize services
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final pathHistoryService = PathHistoryService(storage);
  final retryService = MessageRetryService();
  final appSettingsService = AppSettingsService();
  final bleDebugLogService = BleDebugLogService();
  final appDebugLogService = AppDebugLogService();
  final backgroundService = BackgroundService();
  final mapTileCacheService = MapTileCacheService();
  final chatTextScaleService = ChatTextScaleService();
  final translationService = TranslationService(appSettingsService);
  final uiViewStateService = UiViewStateService();
  final timeoutPredictionService = TimeoutPredictionService(storage);

  // Load settings
  await appSettingsService.loadSettings();

  // Initialize app logger
  appLogger.initialize(
    appDebugLogService,
    enabled: appSettingsService.settings.appDebugLogEnabled,
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await backgroundService.initialize();
  _registerThirdPartyLicenses();

  await chatTextScaleService.initialize();
  await translationService.refreshDownloadedModels();
  await uiViewStateService.initialize();
  await timeoutPredictionService.initialize();

  // Wire up connector with services
  connector.initialize(
    retryService: retryService,
    pathHistoryService: pathHistoryService,
    appSettingsService: appSettingsService,
    translationService: translationService,
    bleDebugLogService: bleDebugLogService,
    appDebugLogService: appDebugLogService,
    backgroundService: backgroundService,
    timeoutPredictionService: timeoutPredictionService,
  );

  await connector.loadContactCache();
  await connector.loadChannelSettings();
  await connector.loadCachedChannels();

  // Load persisted channel messages
  await connector.loadAllChannelMessages();
  await connector.loadUnreadState();

  runApp(
    MeshCoreApp(
      connector: connector,
      retryService: retryService,
      pathHistoryService: pathHistoryService,
      storage: storage,
      appSettingsService: appSettingsService,
      bleDebugLogService: bleDebugLogService,
      appDebugLogService: appDebugLogService,
      mapTileCacheService: mapTileCacheService,
      chatTextScaleService: chatTextScaleService,
      translationService: translationService,
      uiViewStateService: uiViewStateService,
      timeoutPredictionService: timeoutPredictionService,
    ),
  );
}

void _registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['Open-Meteo Elevation API Data'],
      '''
Data used by LOS elevation lookups is provided by Open-Meteo.

Open-Meteo terms and attribution:
https://open-meteo.com/en/terms

Elevation API:
https://open-meteo.com/en/docs/elevation-api

Attribution license reference:
Creative Commons Attribution 4.0 International (CC BY 4.0)
https://creativecommons.org/licenses/by/4.0/
''',
    );
  });
}

class MeshCoreApp extends StatefulWidget {
  final MeshCoreConnector connector;
  final MessageRetryService retryService;
  final PathHistoryService pathHistoryService;
  final StorageService storage;
  final AppSettingsService appSettingsService;
  final BleDebugLogService bleDebugLogService;
  final AppDebugLogService appDebugLogService;
  final MapTileCacheService mapTileCacheService;
  final ChatTextScaleService chatTextScaleService;
  final TranslationService translationService;
  final UiViewStateService uiViewStateService;
  final TimeoutPredictionService timeoutPredictionService;

  const MeshCoreApp({
    super.key,
    required this.connector,
    required this.retryService,
    required this.pathHistoryService,
    required this.storage,
    required this.appSettingsService,
    required this.bleDebugLogService,
    required this.appDebugLogService,
    required this.mapTileCacheService,
    required this.chatTextScaleService,
    required this.translationService,
    required this.uiViewStateService,
    required this.timeoutPredictionService,
  });

  @override
  State<MeshCoreApp> createState() => _MeshCoreAppState();
}

class _MeshCoreAppState extends State<MeshCoreApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<NotificationTapEvent>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    _notificationTapSubscription = NotificationService().onNotificationTapped
        .listen(_handleNotificationTap);
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationTap(NotificationTapEvent event) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    switch (event.type) {
      case NotificationTapEventType.message:
        if (event.id == null) return;
        final contact = widget.connector.findContactByKeyHex(event.id!);
        if (contact == null) return;
        widget.connector.markContactRead(contact.publicKeyHex);
        navigator.push(
          MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)),
        );
        break;
      case NotificationTapEventType.channel:
        if (event.id == null) return;
        final channelIndex = int.tryParse(event.id!);
        if (channelIndex == null) return;
        final channel = widget.connector.findChannelByIndex(channelIndex);
        if (channel == null) return;
        widget.connector.markChannelRead(channelIndex);
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChannelChatScreen(channel: channel),
          ),
        );
        break;
      case NotificationTapEventType.advert:
        // Clear every advert notification — the discovery
        // list the user is about to see contains them all.
        NotificationService().clearAllAdvertNotifications();
        final ids = widget.connector.allContacts
            .map((c) => c.publicKeyHex)
            .toList();
        NotificationService().clearAdvertNotifications(ids);
        navigator.push(
          MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
        );
        break;
      case NotificationTapEventType.batch:
        // Batch summaries have no single target; no-op.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.connector),
        ChangeNotifierProvider.value(value: widget.retryService),
        ChangeNotifierProvider.value(value: widget.pathHistoryService),
        ChangeNotifierProvider.value(value: widget.appSettingsService),
        ChangeNotifierProvider.value(value: widget.bleDebugLogService),
        ChangeNotifierProvider.value(value: widget.appDebugLogService),
        ChangeNotifierProvider.value(value: widget.chatTextScaleService),
        ChangeNotifierProvider.value(value: widget.translationService),
        ChangeNotifierProvider.value(value: widget.uiViewStateService),
        Provider.value(value: widget.storage),
        Provider.value(value: widget.mapTileCacheService),
        ChangeNotifierProvider.value(value: widget.timeoutPredictionService),
      ],
      child: Consumer<AppSettingsService>(
        builder: (context, settingsService, child) {
          return WithForegroundTask(
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'MeshCore Open',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: _localeFromSetting(
                settingsService.settings.languageOverride,
              ),
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
                snackBarTheme: const SnackBarThemeData(
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                snackBarTheme: const SnackBarThemeData(
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              themeMode: _themeModeFromSetting(
                settingsService.settings.themeMode,
              ),
              builder: (context, child) {
                // Update notification service with resolved locale
                final locale = Localizations.localeOf(context);
                NotificationService().setLocale(locale);
                return child ?? const SizedBox.shrink();
              },
              home: (PlatformInfo.isWeb && !PlatformInfo.isChrome)
                  ? const ChromeRequiredScreen()
                  : const ScannerScreen(),
            ),
          );
        },
      ),
    );
  }

  ThemeMode _themeModeFromSetting(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale? _localeFromSetting(String? languageCode) {
    if (languageCode == null) return null;
    return Locale(languageCode);
  }
}
