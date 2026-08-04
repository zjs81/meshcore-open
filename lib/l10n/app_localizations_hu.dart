// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Kapcsolatok';

  @override
  String get nav_channels => 'Csatornák';

  @override
  String get nav_map => 'Térkép';

  @override
  String get common_cancel => 'Mégsem';

  @override
  String get common_ok => 'RENDBEN';

  @override
  String get common_connect => 'Csatlakozás';

  @override
  String get common_unknownDevice => 'Ismeretlen eszköz';

  @override
  String get common_save => 'Megtakarítás';

  @override
  String get common_delete => 'Töröl';

  @override
  String get common_deleteAll => 'Összes törlése';

  @override
  String get common_close => 'Közeli';

  @override
  String get common_done => 'Kész';

  @override
  String get common_edit => 'Szerkesztés';

  @override
  String get common_add => 'Hozzáadás';

  @override
  String get common_settings => 'Beállítások elemre';

  @override
  String get common_disconnect => 'Leválasztás';

  @override
  String get common_connected => 'Csatlakozva';

  @override
  String get common_disconnected => 'Szétkapcsolt';

  @override
  String get common_create => 'Teremt';

  @override
  String get common_continue => 'Folytatás';

  @override
  String get common_share => 'Részesedés';

  @override
  String get common_copy => 'Másolat';

  @override
  String get common_retry => 'Próbálja újra';

  @override
  String get common_hide => 'Elrejt';

  @override
  String get common_remove => 'Távolítsa el';

  @override
  String get common_enable => 'Engedélyezés';

  @override
  String get common_disable => 'Letiltás';

  @override
  String get common_undo => 'Visszavonás';

  @override
  String get messageStatus_sent => 'Küldött';

  @override
  String get messageStatus_delivered => 'Szállítva';

  @override
  String get messageStatus_pending => 'Küldés';

  @override
  String get messageStatus_failed => 'Nem sikerült elküldeni';

  @override
  String get messageStatus_repeated => '– ismételte Heard';

  @override
  String get common_reboot => 'Indítsa újra';

  @override
  String get common_loading => 'Terhelés...';

  @override
  String get common_notAvailable => '—';

  @override
  String common_voltageValue(String volts) {
    return '$volts V';
  }

  @override
  String common_percentValue(int percent) {
    return '$percent%';
  }

  @override
  String get common_autoRefresh => 'Automatikus frissítés';

  @override
  String get common_interval => 'Intervallum';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Csatlakozzon TCP-n keresztül';

  @override
  String get tcpHostLabel => 'Végpont';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => 'Kikötő';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Adja meg a végpontot, és csatlakozzon';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Csatlakozás a következőhöz: $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Házigazda szükséges.';

  @override
  String get tcpErrorPortInvalid => 'A portnak 1 és 65535 között kell lennie.';

  @override
  String get tcpErrorUnsupported =>
      'A TCP-átvitel nem támogatott ezen a platformon.';

  @override
  String get tcpErrorTimedOut => 'A TCP-kapcsolat időtúllépése lejárt.';

  @override
  String tcpConnectionFailed(String error) {
    return 'A TCP-kapcsolat sikertelen: $error';
  }

  @override
  String get usbScreenTitle => 'Csatlakoztassa USB-n keresztül';

  @override
  String get usbScreenSubtitle =>
      'Válasszon egy észlelt soros eszközt, és csatlakozzon közvetlenül a MeshCore csomóponthoz.';

  @override
  String get usbScreenStatus => 'Válasszon ki egy USB-eszközt';

  @override
  String get usbScreenNote =>
      'Az USB-soros aktív a támogatott Android-eszközökön és asztali platformokon.';

  @override
  String get usbScreenEmptyState =>
      'Nem található USB-eszköz. Csatlakoztasson egyet, és frissítse.';

  @override
  String get usbErrorPermissionDenied => 'Az USB-engedély megtagadva.';

  @override
  String get usbErrorDeviceMissing =>
      'A kiválasztott USB-eszköz már nem érhető el.';

  @override
  String get usbErrorInvalidPort => 'Válasszon ki egy érvényes USB-eszközt.';

  @override
  String get usbErrorBusy =>
      'Egy másik USB-csatlakozási kérelem már folyamatban van.';

  @override
  String get usbErrorNotConnected => 'Nincs USB-eszköz csatlakoztatva.';

  @override
  String get usbErrorOpenFailed =>
      'Nem sikerült megnyitni a kiválasztott USB-eszközt.';

  @override
  String get usbErrorConnectFailed =>
      'Nem sikerült csatlakozni a kiválasztott USB-eszközhöz.';

  @override
  String get usbErrorUnsupported =>
      'Az USB-soros nem támogatott ezen a platformon.';

  @override
  String get usbErrorAlreadyActive => 'Az USB-kapcsolat már aktív.';

  @override
  String get usbErrorNoDeviceSelected => 'Nem lett kiválasztva USB-eszköz.';

  @override
  String get usbErrorPortClosed => 'Az USB-csatlakozás nincs nyitva.';

  @override
  String get usbErrorConnectTimedOut =>
      'A kapcsolat időtúllépése lejárt. Győződjön meg arról, hogy az eszköz rendelkezik USB Companion firmware-rel.';

  @override
  String get usbFallbackDeviceName => 'Web soros eszköz';

  @override
  String get usbStatus_notConnected => 'Válasszon ki egy USB-eszközt';

  @override
  String get usbStatus_connecting => 'Csatlakozás USB-eszközhöz...';

  @override
  String get usbStatus_searching => 'USB-eszközök keresése...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB csatlakozás sikertelen: $error';
  }

  @override
  String get scanner_scanning => 'Eszközök keresése...';

  @override
  String get scanner_connecting => 'Csatlakozás...';

  @override
  String get scanner_disconnecting => 'Leválasztás...';

  @override
  String get scanner_notConnected => 'Nincs csatlakoztatva';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Csatlakozva a következőhöz: $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'MeshCore eszközök keresése...';

  @override
  String get scanner_tapToScan =>
      'Koppintson a Scan elemre a MeshCore-eszközök megkereséséhez';

  @override
  String scanner_connectionFailed(String error) {
    return 'A csatlakozás sikertelen: $error';
  }

  @override
  String get scanner_stop => 'Stop';

  @override
  String get scanner_scan => 'Letapogatás';

  @override
  String get scanner_bluetoothOff => 'Bluetooth ki van kapcsolva';

  @override
  String get scanner_bluetoothOffMessage =>
      'Kérjük, kapcsolja be a Bluetooth-t az eszközök kereséséhez';

  @override
  String get scanner_chromeRequired => 'Chrome böngésző szükséges';

  @override
  String get scanner_chromeRequiredMessage =>
      'Ehhez a webes alkalmazáshoz Google Chrome vagy Chromium-alapú böngésző szükséges a Bluetooth támogatásához.';

  @override
  String get scanner_enableBluetooth => 'Bluetooth engedélyezése';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'A Bluetooth nem érhető el a böngészőben. Inkább csatlakoztasson USB-n keresztül.';

  @override
  String get device_quickSwitch => 'Gyors váltás';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Beállítások elemre';

  @override
  String get settings_deviceInfo => 'Készülék Info';

  @override
  String get settings_appSettings => 'Alkalmazásbeállítások';

  @override
  String get settings_appSettingsSubtitle =>
      'Értesítések, üzenetküldés és térképbeállítások';

  @override
  String get settings_nodeSettings => 'Csomópont beállításai';

  @override
  String get settings_nodeName => 'Csomópont neve';

  @override
  String get settings_nodeNameNotSet => 'Nincs beállítva';

  @override
  String get settings_nodeNameHint => 'Írja be a csomópont nevét';

  @override
  String get settings_nodeNameUpdated => 'Név frissítve';

  @override
  String get settings_radioSettings => 'Rádióbeállítások';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvencia, teljesítmény, szórási tényező';

  @override
  String get settings_radioSettingsUpdated => 'A rádió beállításai frissítve';

  @override
  String get settings_regionSettings => 'Regions';

  @override
  String get settings_regionSettingsSubtitle => 'Manage stored regions';

  @override
  String get settings_regionManagement_screenTitle => 'Region Management';

  @override
  String get settings_regionNameHint => 'Enter region name';

  @override
  String get settings_regionAddRegion => 'Add region';

  @override
  String get settings_regionFetchRegions => 'Fetch regions from repeaters';

  @override
  String get settings_regionFetchRegionsFail => 'No regions were found';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'This region has already been added';

  @override
  String get settings_regionName => 'Region Name';

  @override
  String get settings_regionDeleted => 'Region deleted';

  @override
  String get settings_deleteRegion => 'Delete Region';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Remove \"$region\" from region list?';
  }

  @override
  String get settings_location => 'hely';

  @override
  String get settings_locationSubtitle => 'GPS koordináták';

  @override
  String get settings_locationUpdated => 'A hely- és GPS-beállítások frissítve';

  @override
  String get settings_locationBothRequired =>
      'Adja meg a szélességi és hosszúsági fokokat is.';

  @override
  String get settings_locationInvalid =>
      'Érvénytelen szélesség vagy hosszúság.';

  @override
  String get settings_locationGPSEnable => 'GPS engedélyezése';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Lehetővé teszi a GPS számára a hely automatikus frissítését.';

  @override
  String get settings_locationIntervalSec => 'GPS intervallum (másodperc)';

  @override
  String get settings_locationIntervalInvalid =>
      'Az intervallumnak legalább 60 másodpercnek kell lennie, és kevesebbnek kell lennie 86 400 másodpercnél.';

  @override
  String get settings_latitude => 'Szélesség';

  @override
  String get settings_longitude => 'Hosszúság';

  @override
  String get settings_contactSettings => 'Kapcsolati beállítások';

  @override
  String get settings_contactSettingsSubtitle =>
      'A névjegyek hozzáadásának beállításai.';

  @override
  String get settings_privacyMode => 'Adatvédelmi mód';

  @override
  String get settings_privacyModeSubtitle =>
      'Név/hely elrejtése a hirdetésekben';

  @override
  String get settings_privacyModeToggle =>
      'Kapcsolja be az adatvédelmi módot, hogy elrejtse nevét és tartózkodási helyét a hirdetésekben.';

  @override
  String get settings_privacyModeEnabled => 'Az adatvédelmi mód engedélyezve';

  @override
  String get settings_privacyModeDisabled => 'Az adatvédelmi mód letiltva';

  @override
  String get settings_privacy => 'Adatvédelmi beállítások';

  @override
  String get settings_privacySubtitle =>
      'Szabályozza, hogy milyen információkat osztanak meg.';

  @override
  String get settings_privacySettingsDescription =>
      'Válassza ki, hogy eszköze milyen információkat ossza meg másokkal.';

  @override
  String get settings_denyAll => 'Mindent tagadni';

  @override
  String get settings_allowByContact => 'Engedélyezés kapcsolatjelző jelzőkkel';

  @override
  String get settings_allowAll => 'Minden engedélyezése';

  @override
  String get settings_telemetryBaseMode => 'Telemetriai alapmód';

  @override
  String get settings_telemetryLocationMode =>
      'Telemetriás helymeghatározási mód';

  @override
  String get settings_telemetryEnvironmentMode => 'Telemetriás környezeti mód';

  @override
  String get settings_advertLocation => 'Hirdetés helye';

  @override
  String get settings_advertLocationSubtitle =>
      'A hirdetésben szerepeljen a helyszín.';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Automatikus zero-hop hirdetés GPS-frissítéskor';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Ha a GPS-helyzet megváltozik, küldjön zero-hop hirdetést (a hirdetésben helymegadás szükséges).';

  @override
  String get settings_multiAck => 'Multi-ACK';

  @override
  String get settings_telemetryModeUpdated => 'Telemetriai mód frissítve';

  @override
  String get settings_actions => 'Akciók';

  @override
  String get settings_deleteAllPaths => 'Az összes elérési út törlése';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Törölje az összes elérési utat a névjegyekből.';

  @override
  String get settings_sendAdvertisement => 'Hirdetés küldése';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Jelenlét a közvetítésben most';

  @override
  String get settings_advertisementSent => 'Reklám elküldve';

  @override
  String get settings_syncTime => 'Szinkronizálási idő';

  @override
  String get settings_syncTimeSubtitle =>
      'Az eszköz órájának beállítása a telefon idejére';

  @override
  String get settings_timeSynchronized => 'Idő szinkronizálva';

  @override
  String get settings_refreshContacts => 'Névjegyek frissítése';

  @override
  String get settings_refreshContactsSubtitle =>
      'Névjegylista újratöltése az eszközről';

  @override
  String get settings_rebootDevice => 'Eszköz újraindítása';

  @override
  String get settings_rebootDeviceSubtitle => 'Indítsa újra a MeshCore eszközt';

  @override
  String get settings_rebootDeviceConfirm =>
      'Biztosan újra akarja indítani az eszközt? Megszakad a kapcsolat.';

  @override
  String get settings_debug => 'Hibakeresés';

  @override
  String get settings_companionDebugLog => 'Companion Debug Log';

  @override
  String get settings_companionDebugLogSubtitle =>
      'BLE/TCP/USB parancsok, válaszok és nyers adatok';

  @override
  String get settings_appDebugLog => 'Alkalmazás hibakeresési naplója';

  @override
  String get settings_appDebugLogSubtitle => 'Alkalmazás hibakeresési üzenetei';

  @override
  String get settings_about => 'Körülbelül';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore nyílt forráskódú projekt';

  @override
  String get settings_aboutDescription =>
      'Nyílt forráskódú Flutter kliens MeshCore LoRa mesh hálózati eszközökhöz.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS magassági adatok: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Név';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Állapot';

  @override
  String get settings_infoBattery => 'Akkumulátor';

  @override
  String get settings_infoPublicKey => 'Nyilvános kulcs';

  @override
  String get settings_infoContactsCount => 'Névjegyek száma';

  @override
  String get settings_infoChannelCount => 'Csatornaszám';

  @override
  String get settings_presets => 'Előbeállítások';

  @override
  String get settings_frequency => 'Frekvencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid =>
      'Érvénytelen frekvencia (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Sávszélesség';

  @override
  String get settings_spreadingFactor => 'Spreading Factor';

  @override
  String get settings_codingRate => 'Kódolási sebesség';

  @override
  String get settings_txPower => 'TX teljesítmény (dBm)';

  @override
  String get settings_txPowerHelper => '0-22';

  @override
  String get settings_txPowerInvalid =>
      'Érvénytelen TX teljesítmény (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Hálózaton kívüli ismétlés';

  @override
  String get settings_clientRepeatSubtitle =>
      'Engedélyezze az eszköznek, hogy megismételje a mesh-csomagokat mások számára';

  @override
  String get settings_clientRepeatFreqWarning =>
      'A hálózaton kívüli ismétlés 433, 869 vagy 918 MHz frekvenciát igényel';

  @override
  String settings_error(String message) {
    return 'Hiba: $message';
  }

  @override
  String get appSettings_title => 'Alkalmazásbeállítások';

  @override
  String get appSettings_appearance => 'Megjelenés';

  @override
  String get appSettings_theme => 'Téma';

  @override
  String get appSettings_themeSystem => 'Rendszer alapértelmezett';

  @override
  String get appSettings_themeLight => 'Fény';

  @override
  String get appSettings_themeDark => 'Sötét';

  @override
  String get appSettings_language => 'Nyelv';

  @override
  String get appSettings_languageSystem => 'Rendszer alapértelmezett';

  @override
  String get appSettings_languageEn => 'angol';

  @override
  String get appSettings_languageFr => 'Français';

  @override
  String get appSettings_languageEs => 'Español';

  @override
  String get appSettings_languageDe => 'Deutsch';

  @override
  String get appSettings_languagePl => 'Polski';

  @override
  String get appSettings_languageSl => 'Slovenščina';

  @override
  String get appSettings_languagePt => 'Português';

  @override
  String get appSettings_languageIt => 'Italiano';

  @override
  String get appSettings_languageZh => '中文';

  @override
  String get appSettings_languageSv => 'Svenska';

  @override
  String get appSettings_languageNl => 'Nederlands';

  @override
  String get appSettings_languageSk => 'Slovenčina';

  @override
  String get appSettings_languageBg => 'Български';

  @override
  String get appSettings_languageRu => 'Русский';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 byte';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 bytes';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 bytes';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 bytes';

  @override
  String get appSettings_enableMessageTracing => 'Üzenetkövetés engedélyezése';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Az üzenetek részletes útválasztási és időzítési metaadatainak megjelenítése';

  @override
  String get appSettings_notifications => 'Értesítések';

  @override
  String get appSettings_enableNotifications => 'Értesítések engedélyezése';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Értesítések fogadása üzenetekről és hirdetésekről';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Értesítési engedély megtagadva';

  @override
  String get appSettings_notificationsEnabled => 'Értesítések engedélyezve';

  @override
  String get appSettings_notificationsDisabled => 'Az értesítések letiltva';

  @override
  String get appSettings_messageNotifications => 'Üzenetértesítések';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Értesítés megjelenítése új üzenetek fogadásakor';

  @override
  String get appSettings_channelMessageNotifications =>
      'Csatorna üzenetek értesítései';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Értesítés megjelenítése csatornaüzenetek fogadásakor';

  @override
  String get appSettings_advertisementNotifications => 'Reklám Értesítések';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Értesítés megjelenítése új csomópontok felfedezésekor';

  @override
  String get appSettings_messaging => 'Üzenetküldés';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Útvonal törlése a Max. újrapróbálkozásnál';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Állítsa vissza a kapcsolati elérési utat 5 sikertelen küldési kísérlet után';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Az elérési utak 5 sikertelen újrapróbálkozás után törlődnek';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Az útvonalak nem törlődnek automatikusan';

  @override
  String get appSettings_autoRouteRotation => 'Auto Route Rotation';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Váltson a legjobb útvonalak és az elárasztási mód között';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Az automatikus útvonalforgatás engedélyezve';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Az automatikus útvonalforgatás letiltva';

  @override
  String get appSettings_maxRouteWeight => 'Maximális útvonalsúly';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Maximális súly, amelyet egy útvonal felhalmozhat a sikeres szállításokból';

  @override
  String get appSettings_initialRouteWeight => 'Az útvonal kezdeti súlya';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Kezdősúly az újonnan felfedezett utakhoz';

  @override
  String get appSettings_routeWeightSuccessIncrement => 'Siker súlynövekedés';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Súly hozzáadva egy útvonalhoz a sikeres szállítás után';

  @override
  String get appSettings_routeWeightFailureDecrement => 'Hiba súlycsökkentés';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Sikertelen szállítás után eltávolított súly az útvonalról';

  @override
  String get appSettings_maxMessageRetries =>
      'Üzenet újrapróbálkozások maximális száma';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Az üzenet sikertelenként való megjelölése előtti újrapróbálkozások száma';

  @override
  String get appSettings_battery => 'Akkumulátor';

  @override
  String get appSettings_batteryChemistry => 'Akkumulátor kémia';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Beállítás eszközenként ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'A választáshoz csatlakozzon egy eszközhöz';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2 V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2 V)';

  @override
  String get appSettings_mapDisplay => 'Térkép megjelenítése';

  @override
  String get appSettings_showRepeaters => 'Ismétlők megjelenítése';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Az átjátszó csomópontok megjelenítése a térképen';

  @override
  String get appSettings_showChatNodes => 'Chat csomópontok megjelenítése';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'A csevegési csomópontok megjelenítése a térképen';

  @override
  String get appSettings_showOtherNodes => 'Más csomópontok megjelenítése';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Más csomóponttípusok megjelenítése a térképen';

  @override
  String get appSettings_timeFilter => 'Időszűrő';

  @override
  String get appSettings_timeFilterShowAll =>
      'Az összes csomópont megjelenítése';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Az elmúlt $hours óra csomópontjainak megjelenítése';
  }

  @override
  String get appSettings_mapTimeFilter => 'Térkép időszűrő';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Itt talált csomópontok megjelenítése:';

  @override
  String get appSettings_allTime => 'Minden alkalommal';

  @override
  String get appSettings_lastHour => 'Utolsó óra';

  @override
  String get appSettings_last6Hours => 'Utolsó 6 óra';

  @override
  String get appSettings_last24Hours => 'Az elmúlt 24 óra';

  @override
  String get appSettings_lastWeek => 'Múlt héten';

  @override
  String get appSettings_rasterTileSource => 'Raszteres csempeforrás';

  @override
  String get appSettings_stadiaEndpoint => 'Stadia végpont';

  @override
  String get appSettings_stadiaApiKey => 'Stadia API-kulcs';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'A Stadia Maps használatához kötelező';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Konfigurálva: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Adja meg a Stadia Maps API-kulcsát. Az alkalmazás ezt használja raszteres csempekérésekhez.';

  @override
  String get appSettings_offlineMapCache => 'Offline térképgyorsítótár';

  @override
  String get appSettings_unitsTitle => 'Egységek';

  @override
  String get appSettings_unitsMetric => 'Metrikus (m/km)';

  @override
  String get appSettings_unitsImperial => 'birodalmi (ft/mi)';

  @override
  String get appSettings_noAreaSelected => 'Nincs kiválasztott terület';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Kijelölt terület (nagyítás $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Hibakeresés';

  @override
  String get appSettings_appDebugLogging =>
      'Alkalmazások hibakeresési naplózása';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'A hibaelhárításhoz naplózza az alkalmazás hibakeresési üzeneteit';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Alkalmazások hibakeresési naplózása engedélyezve';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Az alkalmazáshibakeresési naplózás letiltva';

  @override
  String get contacts_title => 'Kapcsolatok';

  @override
  String get contacts_noContacts => 'Még nincsenek elérhetőségek';

  @override
  String get contacts_contactsWillAppear =>
      'A névjegyek akkor jelennek meg, amikor az eszközök hirdetnek';

  @override
  String get contacts_unread => 'Nem olvasott';

  @override
  String get contacts_searchContactsNoNumber => 'Névjegyek keresése...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Keresés a $number$str névjegyekben...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Keresés a $number$str Kedvencek között...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Keresés a $number$str felhasználók között...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Keresés a $number$str átjátszók között...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Keresés a $number$str szobaszervereken...';
  }

  @override
  String get contacts_noUnreadContacts => 'Nincsenek olvasatlan névjegyek';

  @override
  String get contacts_noContactsFound => 'Nem található névjegy vagy csoport';

  @override
  String get contacts_deleteContact => 'Névjegy törlése';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Eltávolítja a $contactName alkalmazást a névjegyek közül?';
  }

  @override
  String get contacts_manageRepeater => 'Repeater kezelése';

  @override
  String get contacts_manageRoom => 'Szobaszerver kezelése';

  @override
  String get contacts_roomLogin => 'Szobaszerver bejelentkezés';

  @override
  String get contacts_openChat => 'Nyissa meg a Chat lehetőséget';

  @override
  String get contacts_editGroup => 'Csoport szerkesztése';

  @override
  String get contacts_deleteGroup => 'Csoport törlése';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eltávolítja a következőt: \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Új csoport';

  @override
  String get contacts_moreOptions => 'További lehetőségek';

  @override
  String get contacts_searchOpen => 'Névjegyek keresése';

  @override
  String get contacts_searchClose => 'Keresés bezárása';

  @override
  String get contacts_groupName => 'Csoport neve';

  @override
  String get contacts_groupNameRequired => 'A csoportnév megadása kötelező';

  @override
  String get contacts_groupNameReserved => 'Ez a csoportnév fenntartva';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'A \"$name\" csoport már létezik';
  }

  @override
  String get contacts_filterContacts => 'Névjegyek szűrése...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Egyetlen névjegy sem felel meg a szűrőnek';

  @override
  String get contacts_noMembers => 'Nincsenek tagok';

  @override
  String get contacts_lastSeenNow => 'nemrég';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 óra';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours óra';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 nap';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days nap';
  }

  @override
  String get contact_info => 'Elérhetőségi adatok';

  @override
  String get contact_settings => 'Kapcsolati beállítások';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Utoljára látott';

  @override
  String get contact_clearChat => 'Csevegés törlése';

  @override
  String get contact_teleBase => 'Telemetriai bázis';

  @override
  String get contact_teleBaseSubtitle =>
      'Az akkumulátor töltöttségi szintjének és az alapvető telemetria megosztásának engedélyezése';

  @override
  String get contact_teleLoc => 'Telemetriás hely';

  @override
  String get contact_teleLocSubtitle =>
      'Helyadatok megosztásának engedélyezése';

  @override
  String get contact_teleEnv => 'Telemetriai környezet';

  @override
  String get contact_teleEnvSubtitle =>
      'A környezetérzékelő adatainak megosztásának engedélyezése';

  @override
  String get channels_title => 'Csatornák';

  @override
  String get channels_noChannelsConfigured =>
      'Nincsenek konfigurálva csatornák';

  @override
  String get channels_addPublicChannel => 'Nyilvános csatorna hozzáadása';

  @override
  String get channels_searchChannels => 'Csatornák keresése...';

  @override
  String get channels_noChannelsFound => 'Nem található csatorna';

  @override
  String channels_channelIndex(int index) {
    return 'Csatorna $index';
  }

  @override
  String get channels_public => 'Nyilvános';

  @override
  String channels_via(String path) {
    return 'ezen keresztül: $path';
  }

  @override
  String get channels_private => 'Magán';

  @override
  String get channels_editChannel => 'Csatorna szerkesztése';

  @override
  String get channels_muteChannel => 'Csatorna némítása';

  @override
  String get channels_unmuteChannel => 'Csatorna némításának feloldása';

  @override
  String get channels_deleteChannel => 'Csatorna törlése';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Törli a következőt: \"$name\"? Ezt nem lehet visszavonni.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Nem sikerült törölni a \"$name\" csatornát';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'A \"$name\" csatorna törölve';
  }

  @override
  String get channels_addChannel => 'Csatorna hozzáadása lehetőségre';

  @override
  String get channels_channelIndexLabel => 'Csatorna indexe';

  @override
  String get channels_channelName => 'Csatorna neve';

  @override
  String get channels_usePublicChannel => 'Nyilvános csatorna használata';

  @override
  String get channels_standardPublicPsk => 'Normál nyilvános PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Véletlenszerű PSK generálása';

  @override
  String get channels_enterChannelName => 'Kérjük, adja meg a csatorna nevét';

  @override
  String get channels_pskMustBe32Hex =>
      'A PSK-nak 32 hexadecimális karakterből kell állnia';

  @override
  String channels_channelAdded(String name) {
    return 'A \"$name\" csatorna hozzáadva';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Csatorna szerkesztése $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ tömörítés';

  @override
  String get channels_cyr2latCompression => 'Cyr2Lat tömörítés';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Küldéskor egyes cirill karaktereket latin karakterekre cserél.';

  @override
  String get channels_cyr2latSettingsHeading => 'Cyr2Lat beállítás';

  @override
  String get channels_cyr2latSettingsSubheading => 'A helyettesítők listája';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Szerkessze a karaktercsere JSON-konfigurációját';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON cseretérkép';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'Érvénytelen JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'A \"$name\" csatorna frissítve';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Cyr2Lat profil hozzáadása';

  @override
  String get settings_cyr2latProfileName => 'Profil neve';

  @override
  String get settings_cyr2latProfileNameEmpty => 'A profilnév nem lehet üres';

  @override
  String get settings_cyr2latProfileAdded => 'A profil sikeresen hozzáadva';

  @override
  String get settings_cyr2latProfileUpdated => 'A profil sikeresen frissítve';

  @override
  String get settings_cyr2latProfileEdit => 'Szerkessze a Cyr2Lat profilt';

  @override
  String get settings_cyr2latProfileDelete => 'Cyr2Lat profil törlése';

  @override
  String get settings_cyr2latProfileDeleted => 'A profil sikeresen törölve';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Biztos benne, hogy törölni kívánja a(z) \"$name\" profilt?';
  }

  @override
  String get channels_publicChannelAdded => 'Nyilvános csatorna hozzáadva';

  @override
  String get channels_sortBy => 'Rendezés';

  @override
  String get channels_sortManual => 'Kézikönyv';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Legújabb üzenetek';

  @override
  String get channels_sortUnread => 'Nem olvasott';

  @override
  String get channels_createPrivateChannel =>
      'Hozzon létre egy privát csatornát';

  @override
  String get channels_createPrivateChannelDesc => 'Titkos kulccsal biztosítva.';

  @override
  String get channels_joinPrivateChannel => 'Csatlakozz egy privát csatornához';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Adjon meg kézzel egy titkos kulcsot.';

  @override
  String get channels_joinPublicChannel =>
      'Csatlakozzon a nyilvános csatornához';

  @override
  String get channels_joinPublicChannelDesc =>
      'Bárki csatlakozhat ehhez a csatornához.';

  @override
  String get channels_joinHashtagChannel =>
      'Csatlakozz egy Hashtag csatornához';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Bárki csatlakozhat a hashtag csatornákhoz.';

  @override
  String get channels_scanQrCode => 'QR-kód beolvasása';

  @override
  String get channels_scanQrCodeComingSoon => 'Hamarosan';

  @override
  String get channels_enterHashtag => 'Írja be a hashtaget';

  @override
  String get channels_hashtagHint => 'például #csapat';

  @override
  String channels_regionSetTo(String region) {
    return 'Region: $region';
  }

  @override
  String get channels_regionNotSet => 'Region: none';

  @override
  String get channels_regionSelect_Title => 'Select a region';

  @override
  String get channels_clearRegion => 'Clear region';

  @override
  String get chat_noMessages => 'Még nincsenek üzenetek';

  @override
  String get chat_sendMessage => 'Üzenet küldése';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Üzenet küldése a következő címre: $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'A kezdéshez küldjön üzenetet';

  @override
  String get chat_originalMessageNotFound => 'Az eredeti üzenet nem található';

  @override
  String chat_replyingTo(String name) {
    return 'Válasz erre: $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Válasz erre: $name';
  }

  @override
  String get chat_location => 'hely';

  @override
  String get chat_typeMessage => 'Írjon be egy üzenetet...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Az üzenet túl hosszú (max. $maxBytes bájt).';
  }

  @override
  String get chat_messageCopied => 'Üzenet másolva';

  @override
  String get chat_messageDeleted => 'Üzenet törölve';

  @override
  String get chat_retryingMessage => 'Üzenet újrapróbálkozása';

  @override
  String chat_retryCount(int current, int max) {
    return 'Próbálja újra $current/$max';
  }

  @override
  String get chat_sendGif => 'GIF küldése';

  @override
  String get chat_receivedGif => 'Received a GIF';

  @override
  String get chat_reply => 'Válasz';

  @override
  String get chat_addReaction => 'Reakció hozzáadása';

  @override
  String get chat_me => 'Nekem';

  @override
  String get emojiCategorySmileys => 'Hangulatjelek';

  @override
  String get emojiCategoryGestures => 'Gesztusok';

  @override
  String get emojiCategoryHearts => 'Szívek';

  @override
  String get emojiCategoryObjects => 'Objektumok';

  @override
  String get gifPicker_title => 'Válassz egy GIF-et';

  @override
  String get gifPicker_searchHint => 'GIF-ek keresése...';

  @override
  String get gifPicker_poweredBy => 'Üzemeltető: GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nem található GIF';

  @override
  String get gifPicker_failedLoad => 'Nem sikerült betölteni a GIF-eket';

  @override
  String get gifPicker_failedSearch => 'Nem sikerült a GIF-ek keresése';

  @override
  String get gifPicker_noInternet => 'Nincs internet kapcsolat';

  @override
  String get debugLog_appTitle => 'Alkalmazás hibakeresési naplója';

  @override
  String get debugLog_bleTitle => 'BLE hibakeresési napló';

  @override
  String get debugLog_copyLog => 'Napló másolása';

  @override
  String get debugLog_clearLog => 'Napló törlése';

  @override
  String get debugLog_copied => 'Hibakeresési napló másolva';

  @override
  String get debugLog_bleCopied => 'BLE napló másolva';

  @override
  String get debugLog_noEntries => 'Még nincsenek hibakeresési naplók';

  @override
  String get debugLog_enableInSettings =>
      'Engedélyezze az alkalmazás hibakeresési bejelentkezési beállításait';

  @override
  String get debugLog_frames => 'Keretek';

  @override
  String get debugLog_rawLogRx => 'Nyers Log-RX';

  @override
  String get debugLog_noBleActivity => 'Még nincs BLE tevékenység';

  @override
  String debugFrame_length(int count) {
    return 'Keret hossza: $count bájt';
  }

  @override
  String debugFrame_command(String value) {
    return 'Parancs: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Szöveges üzenet keret:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Cél PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Időbélyeg: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Zászlók: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Szöveg típusa: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Egyszerű';

  @override
  String debugFrame_text(String text) {
    return '- Szöveg: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex dump:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ugrások',
      one: 'ugrás',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Távolítsa el az útvonalat';

  @override
  String get chat_noPathHistoryYet =>
      'Még nincs úttörténet.\nÜzenet küldése utak felfedezéséhez.';

  @override
  String get chat_pathCleared =>
      'Út megtisztítva. A következő üzenet újra felfedezi az útvonalat.';

  @override
  String get chat_fullPath => 'Teljes útvonal';

  @override
  String get routing_title => 'Útválasztás';

  @override
  String get routing_modeAuto => 'Auto';

  @override
  String get routing_modeFlood => 'Árvíz';

  @override
  String get routing_modeManual => 'Kézikönyv';

  @override
  String get routing_modeAutoHint =>
      'Automatikusan kiválasztja a legismertebb utat, és elárasztja, ha nem ismert.';

  @override
  String get routing_modeFloodHint =>
      'Minden átjátszón keresztül sugároz. A legmegbízhatóbb, de több műsoridőt használ.';

  @override
  String get routing_modeManualHint =>
      'Mindig pontosan az Ön által megadott útvonalon küld.';

  @override
  String get routing_currentRoute => 'Jelenlegi útvonal';

  @override
  String get routing_directNoHops => 'Közvetlen – nincs átjátszó ugrás';

  @override
  String get routing_noPathYet =>
      'Még nincs út. A következő üzenet elárasztja az útvonalat.';

  @override
  String get routing_floodBroadcast => 'Minden átjátszón keresztül sugározd';

  @override
  String get routing_editPath => 'Útvonal szerkesztése';

  @override
  String get routing_forgetPath => 'Felejtsd el az utat';

  @override
  String get routing_knownPaths => 'Ismert utak';

  @override
  String get routing_knownPathsHint =>
      'Koppintson egy elérési útra a váltáshoz.';

  @override
  String get routing_inUse => 'Használatban';

  @override
  String get routing_qualityStrong => 'Erős első ugrás';

  @override
  String get routing_qualityGood => 'Jó első ugrás';

  @override
  String get routing_qualityFair => 'Tisztességes első ugrás';

  @override
  String get routing_qualityWorked => 'Szállított';

  @override
  String get routing_qualityFlood => 'Árvízen keresztül hallatszott';

  @override
  String get routing_qualityUntested => 'Nem tesztelt';

  @override
  String routing_lastWorked(String when) {
    return 'dolgozott $when';
  }

  @override
  String get routing_neverWorked => 'soha nem erősítették meg';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes kézbesítve, $failures sikertelen';
  }

  @override
  String get routing_floodDelivery => 'Árvízi szállítás';

  @override
  String get pathEditor_title => 'Építsd meg az útvonalat';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count 64 ugrásból';
  }

  @override
  String get pathEditor_noHops =>
      'Még nincs ugrás. Koppintson az alábbi ismétlőkre, ha sorrendben szeretné felvenni őket, vagy mentse ugrás nélkül a közvetlen küldéshez.';

  @override
  String get pathEditor_addHops => 'Sorrendben adjuk hozzá a komlót';

  @override
  String get pathEditor_searchRepeaters => 'Ismétlő keresése';

  @override
  String get pathEditor_advancedHex => 'Haladó: nyers hexadecimális útvonal';

  @override
  String get pathEditor_hexLabel => 'Hexadecimális előtagok';

  @override
  String get pathEditor_hexHelper =>
      'Két hexadecimális karakter ugrásonként, vesszővel elválasztva';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Érvénytelen: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Maximum 64 ugrás';

  @override
  String get pathEditor_usePath => 'Használja ezt az utat';

  @override
  String get pathEditor_removeHop => 'Távolítsa el az ugrást';

  @override
  String get pathEditor_unknownHop => 'Ismeretlen átjátszó';

  @override
  String get chat_pathSavedLocally =>
      'Helyben mentve. Csatlakozás a szinkronizáláshoz.';

  @override
  String get chat_pathDeviceConfirmed => 'Az eszköz megerősítve.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Az eszköz még nincs megerősítve.';

  @override
  String get chat_type => 'Írja be';

  @override
  String get chat_path => 'Útvonal';

  @override
  String get chat_publicKey => 'Nyilvános kulcs';

  @override
  String get chat_compressOutgoingMessages => 'A kimenő üzenetek tömörítése';

  @override
  String get chat_floodForced => 'Árvíz (kényszerített)';

  @override
  String get chat_directForced => 'Közvetlen (kényszerített)';

  @override
  String chat_hopsForced(int count) {
    return '$count ugrás (kényszerített)';
  }

  @override
  String get chat_floodAuto => 'Árvíz (automatikus)';

  @override
  String get chat_direct => 'Közvetlen';

  @override
  String get chat_poiShared => 'POI megosztva';

  @override
  String chat_unread(int count) {
    return 'Olvasatlan: $count';
  }

  @override
  String get chat_markAsUnread => 'Megjelölés olvasatlanként';

  @override
  String get chat_newMessages => 'Új üzenetek';

  @override
  String get chat_openLink => 'Link megnyitása?';

  @override
  String get chat_openLinkConfirmation =>
      'Meg akarja nyitni ezt a hivatkozást a böngészőjében?';

  @override
  String get chat_open => 'Nyitott';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Nem sikerült megnyitni a linket: $url';
  }

  @override
  String get chat_invalidLink => 'Érvénytelen linkformátum';

  @override
  String get map_title => 'Csomópont térkép';

  @override
  String get map_searchHint =>
      'Keresés a csomópont nevében vagy azonosítójában';

  @override
  String get map_activity => 'Tevékenység';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Legutóbbi';

  @override
  String get map_stale => 'Állott';

  @override
  String get map_visible => 'Látható';

  @override
  String get map_hidden => 'Rejtett';

  @override
  String get map_centerOnNode => 'Középre a csomóponton';

  @override
  String get map_details => 'Részletek';

  @override
  String get map_noGps => 'Nincs GPS';

  @override
  String get map_noResults => 'Nincsenek megfelelő csomópontok';

  @override
  String get map_lineOfSight => 'Látóvonal';

  @override
  String get map_losScreenTitle => 'Látóvonal';

  @override
  String get map_noNodesWithLocation =>
      'Nincsenek helyadatokkal rendelkező csomópontok';

  @override
  String get map_nodesNeedGps =>
      'A csomópontoknak meg kell osztaniuk GPS-koordinátáikat\nhogy megjelenjen a térképen';

  @override
  String map_nodesCount(int count) {
    return 'Csomópontok: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pins: $count';
  }

  @override
  String get map_chat => 'Csevegés';

  @override
  String get map_repeater => 'Ismétlő';

  @override
  String get map_room => 'Szoba';

  @override
  String get map_sensor => 'Érzékelő';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Pin (privát)';

  @override
  String get map_pinPublic => 'Pin (nyilvános)';

  @override
  String get map_lastSeen => 'Utoljára látott';

  @override
  String get map_disconnectConfirm =>
      'Biztosan le akarja kapcsolni ezt az eszközt?';

  @override
  String get map_from => 'Tól';

  @override
  String get map_source => 'Forrás';

  @override
  String get map_flags => 'Zászlók';

  @override
  String get map_type => 'Írja be';

  @override
  String get map_path => 'Útvonal';

  @override
  String get map_location => 'hely';

  @override
  String get map_estLocation => 'Becsült hely';

  @override
  String get map_publicKey => 'Nyilvános kulcs';

  @override
  String get map_publicKeyPrefixHint => 'pl. ab12';

  @override
  String get map_shareMarkerHere => 'Oszd meg a jelölőt itt';

  @override
  String get map_setAsMyLocation => 'Beállítás helyemként';

  @override
  String get map_pinLabel => 'Kitűzött címke';

  @override
  String get map_label => 'Címke';

  @override
  String get map_pointOfInterest => 'Érdekes pont';

  @override
  String get map_sendToContact => 'Elküldés a kapcsolattartónak';

  @override
  String get map_sendToChannel => 'Küldés a csatornára';

  @override
  String get map_noChannelsAvailable => 'Nincs elérhető csatorna';

  @override
  String get map_publicLocationShare => 'Nyilvános helymegosztás';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Arra készül, hogy megosszon egy helyet itt: $channelLabel. Ez a csatorna nyilvános, és a PSK birtokában bárki láthatja.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Csatlakozzon egy eszközhöz a jelölők megosztásához';

  @override
  String get map_filterNodes => 'Csomópontok szűrése';

  @override
  String get map_nodeTypes => 'Csomópont típusok';

  @override
  String get map_chatNodes => 'Chat csomópontok';

  @override
  String get map_repeaters => 'Ismétlők';

  @override
  String get map_otherNodes => 'Egyéb csomópontok';

  @override
  String get map_showOverlaps => 'Repeater Key átfedések';

  @override
  String get map_keyPrefix => 'Kulcselőtag';

  @override
  String get map_filterByKeyPrefix => 'Szűrés kulcs előtagja szerint';

  @override
  String get map_publicKeyPrefix => 'Nyilvános kulcs előtagja';

  @override
  String get map_markers => 'Jelölők';

  @override
  String get map_showSharedMarkers => 'Megosztott jelölők megjelenítése';

  @override
  String get map_showGuessedLocations =>
      'Talált csomópont-helyek megjelenítése';

  @override
  String get map_showDiscoveryContacts => 'Felfedezési névjegyek megjelenítése';

  @override
  String get map_guessedLocation => 'Talált hely';

  @override
  String get map_lastSeenTime => 'Utoljára látott időpont';

  @override
  String get map_sharedPin => 'Megosztott gombostű';

  @override
  String get map_sharedAt => 'Megosztva';

  @override
  String get map_joinRoom => 'Csatlakozz a szobához';

  @override
  String get map_manageRepeater => 'Repeater kezelése';

  @override
  String get map_tapToAdd =>
      'Érintse meg a csomópontokat, hogy hozzáadja őket az útvonalhoz.';

  @override
  String get map_runTrace => 'Futtatási útvonal nyomkövetése';

  @override
  String get map_runTraceWithReturnPath => 'Térj vissza ugyanazon az úton.';

  @override
  String get map_removeLast => 'Utolsó eltávolítása';

  @override
  String get map_pathTraceCancelled => 'Útvonal nyomkövetés törölve.';

  @override
  String get mapCache_title => 'Offline térképgyorsítótár';

  @override
  String get mapCache_selectAreaFirst =>
      'Válassza ki a gyorsítótárba helyezendő területet';

  @override
  String get mapCache_noTilesToDownload =>
      'Ehhez a területhez nem lehet letölteni csempét';

  @override
  String get mapCache_downloadTilesTitle => 'Csempe letöltése';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Letölti a $count csempét offline használatra?';
  }

  @override
  String get mapCache_downloadAction => 'Letöltés';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Gyorsítótárazott $count csempe';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Gyorsítótárazott $downloaded csempe ($failed sikertelen)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Offline gyorsítótár törlése';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Eltávolítja az összes gyorsítótárazott térképcsempét?';

  @override
  String get mapCache_offlineCacheCleared => 'Offline gyorsítótár törölve';

  @override
  String get mapCache_noAreaSelected => 'Nincs kiválasztott terület';

  @override
  String get mapCache_cacheArea => 'Gyorsítótár terület';

  @override
  String get mapCache_useCurrentView => 'Az aktuális nézet használata';

  @override
  String get mapCache_zoomRange => 'Zoom tartomány';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Becsült csempék: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Letöltve $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Letöltés csempe';

  @override
  String get mapCache_clearCacheButton => 'Törölje a gyorsítótárat';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Sikertelen letöltések: $count';
  }

  @override
  String get mapCache_cachedTilesLabel => 'Cached tiles';

  @override
  String get mapCache_cachedTileSummaryLabel => 'Cached tile summary';

  @override
  String mapCache_bulkDownloadDisabledForSource(String source) {
    return 'Offline bulk downloads are disabled for $source.';
  }

  @override
  String mapCache_bulkDownloadDisabledInConfig(String source) {
    return 'Offline bulk downloads are disabled for $source in this app configuration.';
  }

  @override
  String mapCache_summarySource(String source) {
    return 'Source: $source';
  }

  @override
  String mapCache_summaryCachedTilesForSource(int count) {
    return 'Cached tiles for source: $count';
  }

  @override
  String mapCache_summaryCachedInSelection(int count) {
    return 'Cached in selected area/zoom: $count';
  }

  @override
  String mapCache_summaryApproxCacheSize(String size) {
    return 'Approx cache size: $size';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'É $north, D $south, K $east, Ny $west';
  }

  @override
  String get time_justNow => 'Éppen most';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes perce';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hoursórája';
  }

  @override
  String time_daysAgo(int days) {
    return '${days}napja';
  }

  @override
  String get time_hour => 'óra';

  @override
  String get time_hours => 'óra';

  @override
  String get time_day => 'nap';

  @override
  String get time_days => 'napokon';

  @override
  String get time_week => 'hét';

  @override
  String get time_weeks => 'hét';

  @override
  String get time_month => 'hónap';

  @override
  String get time_months => 'hónap';

  @override
  String get time_minutes => 'jegyzőkönyv';

  @override
  String get time_allTime => 'Minden idők';

  @override
  String get dialog_disconnect => 'Leválasztás';

  @override
  String get dialog_disconnectConfirm =>
      'Biztosan le akarja kapcsolni ezt az eszközt?';

  @override
  String get login_repeaterLogin => 'Ismétlő bejelentkezés';

  @override
  String get login_roomLogin => 'Szobaszerver bejelentkezés';

  @override
  String get login_password => 'Jelszó';

  @override
  String get login_enterPassword => 'Adja meg a jelszót';

  @override
  String get login_savePassword => 'Jelszó mentése';

  @override
  String get login_savePasswordSubtitle =>
      'A jelszó biztonságosan lesz tárolva ezen az eszközön';

  @override
  String get login_repeaterDescription =>
      'Adja meg az ismétlő jelszavát a vendég vagy adminisztrátori hozzáféréshez.';

  @override
  String get login_roomDescription =>
      'Adja meg a szoba jelszavát a vendég vagy adminisztrátori hozzáféréshez.';

  @override
  String get login_routing => 'Útválasztás';

  @override
  String get login_routingMode => 'Útválasztási mód';

  @override
  String get login_autoUseSavedPath =>
      'Automatikus (mentett útvonal használata)';

  @override
  String get login_forceFloodMode => 'Force Flood mód';

  @override
  String get login_managePaths => 'Útvonalak kezelése';

  @override
  String get login_login => 'Bejelentkezés';

  @override
  String login_attempt(int current, int max) {
    return 'Kísérlet $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Sikertelen bejelentkezés: $error';
  }

  @override
  String get login_failedMessage =>
      'Sikertelen bejelentkezés. Vagy hibás a jelszó, vagy az átjátszó nem érhető el.';

  @override
  String get common_reload => 'Újratöltés';

  @override
  String get common_clear => 'Világos';

  @override
  String get path_currentPathLabel => 'Jelenlegi útvonal';

  @override
  String get path_noRepeatersFound =>
      'Nem található átjátszó vagy szobaszerver.';

  @override
  String get repeater_management => 'Repeater Management';

  @override
  String get room_management => 'Szobaszerver-kezelés';

  @override
  String get repeater_guest => 'Ismétlő információ';

  @override
  String get room_guest => 'Szobaszerver információ';

  @override
  String get repeater_managementTools => 'Kezelőeszközök';

  @override
  String get repeater_guestTools => 'Vendégeszközök';

  @override
  String get repeater_status => 'Állapot';

  @override
  String get repeater_statusSubtitle =>
      'Tekintse meg az átjátszó állapotát, a statisztikákat és a szomszédokat';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Tekintse meg az érzékelők telemetriáját és a rendszerstatisztikát';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Parancsok küldése az átjátszónak';

  @override
  String get repeater_neighbors => 'Szomszédok';

  @override
  String get repeater_neighborsSubtitle =>
      'Tekintse meg a zero hop szomszédokat.';

  @override
  String get repeater_settings => 'Beállítások elemre';

  @override
  String get repeater_settingsSubtitle => 'Állítsa be az ismétlő paramétereit';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Óra szinkronizálás bejelentkezés után';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      '„Óraszinkronizálás” automatikus küldése sikeres bejelentkezés után';

  @override
  String get repeater_statusTitle => 'Repeater állapota';

  @override
  String get repeater_routingMode => 'Útválasztási mód';

  @override
  String get repeater_refresh => 'Frissítés';

  @override
  String get repeater_statusRequestTimeout =>
      'Az állapotkérelem időtúllépése lejárt.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Hiba az állapot betöltésekor: $error';
  }

  @override
  String get repeater_systemInformation => 'Rendszerinformációk';

  @override
  String get repeater_battery => 'Akkumulátor';

  @override
  String get repeater_clockAtLogin => 'Óra (bejelentkezéskor)';

  @override
  String get repeater_uptime => 'Üzemidő';

  @override
  String get repeater_queueLength => 'Sor hossza';

  @override
  String get repeater_debugFlags => 'Debug Flags';

  @override
  String get repeater_radioStatistics => 'Rádióstatisztika';

  @override
  String get repeater_lastRssi => 'Utolsó RSSI';

  @override
  String get repeater_lastSnr => 'Utolsó SNR';

  @override
  String get repeater_noiseFloor => 'Zajpadló';

  @override
  String get repeater_txAirtime => 'TX műsoridő';

  @override
  String get repeater_rxAirtime => 'RX műsoridő';

  @override
  String get repeater_chanUtil => 'Csatornahasználat';

  @override
  String get repeater_packetStatistics => 'Csomagstatisztika';

  @override
  String get repeater_sent => 'Küldött';

  @override
  String get repeater_received => 'Fogadva';

  @override
  String get repeater_duplicates => 'Ismétlődések';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days nap $hoursó ${minutes}p ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Összesen: $total, Árvíz: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Összesen: $total, Árvíz: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Árvíz: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Összesen: $total';
  }

  @override
  String get repeater_settingsTitle => 'Repeater beállítások';

  @override
  String get repeater_basicSettings => 'Alapbeállítások';

  @override
  String get repeater_repeaterName => 'Ismétlő neve';

  @override
  String get repeater_repeaterNameHelper => 'Az átjátszó megjelenítési neve';

  @override
  String get repeater_adminPassword => 'Admin jelszó';

  @override
  String get repeater_adminPasswordHelper => 'Teljes hozzáférési jelszó';

  @override
  String get repeater_guestPassword => 'Vendégjelszó';

  @override
  String get repeater_guestPasswordHelper =>
      'Csak olvasható hozzáférési jelszó';

  @override
  String get repeater_radioSettings => 'Rádióbeállítások';

  @override
  String get repeater_frequencyMhz => 'Frekvencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX teljesítmény';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Sávszélesség';

  @override
  String get repeater_spreadingFactor => 'Spreading Factor';

  @override
  String get repeater_codingRate => 'Kódolási sebesség';

  @override
  String get repeater_locationSettings => 'Helybeállítások';

  @override
  String get repeater_latitude => 'Szélesség';

  @override
  String get repeater_latitudeHelper => 'Tizedes fokozatok (pl. 37,7749)';

  @override
  String get repeater_longitude => 'Hosszúság';

  @override
  String get repeater_longitudeHelper => 'Tizedes fokok (pl. -122,4194)';

  @override
  String get repeater_features => 'Jellemzők';

  @override
  String get repeater_packetForwarding => 'Csomagtovábbítás';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Ismétlő engedélyezése a csomagok továbbításához';

  @override
  String get repeater_guestAccess => 'Vendég hozzáférés';

  @override
  String get repeater_guestAccessSubtitle =>
      'Csak olvasási hozzáférés engedélyezése a vendégek számára';

  @override
  String get repeater_privacyMode => 'Adatvédelmi mód';

  @override
  String get repeater_privacyModeSubtitle =>
      'Név/hely elrejtése a hirdetésekben';

  @override
  String get repeater_advertisementSettings => 'Reklámbeállítások';

  @override
  String get repeater_localAdvertInterval => 'Helyi hirdetési intervallum';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes perc';
  }

  @override
  String get repeater_floodAdvertInterval => 'Árvízi hirdetési intervallum';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours óra';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Titkosított hirdetési időköz';

  @override
  String get repeater_dangerZone => 'Veszélyzóna';

  @override
  String get repeater_rebootRepeater => 'Reboot Repeater';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Indítsa újra az átjátszó eszközt';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Biztosan újraindítja ezt az átjátszót?';

  @override
  String get repeater_regenerateIdentityKey => 'Identitáskulcs újragenerálása';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Új nyilvános/privát kulcspár létrehozása';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Ez új identitást generál az átjátszó számára. Folytatja?';

  @override
  String get repeater_eraseFileSystem => 'Fájlrendszer törlése';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formázza meg az átjátszó fájlrendszert';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'FIGYELMEZTETÉS: Ezzel törli az átjátszón lévő összes adatot. Ezt nem lehet visszavonni!';

  @override
  String get repeater_eraseSerialOnly =>
      'A törlés csak soros konzolon érhető el.';

  @override
  String repeater_commandSent(String command) {
    return 'Parancs elküldve: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Hiba a parancs küldésekor: $error';
  }

  @override
  String get repeater_confirm => 'Erősítse meg';

  @override
  String get repeater_settingsSaved => 'A beállítások sikeresen elmentve';

  @override
  String get repeater_rxGain => 'Megnövelt RX nyereség';

  @override
  String get repeater_rxGainHelper =>
      'Nagyobb érzékenység, nagyobb áramfelvétel (csak SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain => 'Frissítse a megnövelt RX-erősítést';

  @override
  String get repeater_multiAcks => 'Multi-ACK';

  @override
  String get repeater_multiAcksSubtitle =>
      'Nyugtázza az üzeneteket több úton a jobb kézbesítés érdekében';

  @override
  String get repeater_refreshMultiAcks => 'Többszörös ACK-ek frissítése';

  @override
  String get repeater_networkHealth => 'Hálózat állapota';

  @override
  String get repeater_loopDetect => 'Hurokérzékelés';

  @override
  String get repeater_loopDetectHelper =>
      'Dobd el az útválasztó huroknak tűnő árvízcsomagokat';

  @override
  String get repeater_loopDetectOff => 'Le';

  @override
  String get repeater_loopDetectMinimal => 'Minimális';

  @override
  String get repeater_loopDetectModerate => 'Mérsékelt';

  @override
  String get repeater_loopDetectStrict => 'Szigorú';

  @override
  String get repeater_dutyCycle => 'Üzemi ciklus';

  @override
  String get repeater_dutyCycleHelper => 'A műsoridő maximális százaléka';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Üzemeltető információ';

  @override
  String get repeater_ownerInfoHelper =>
      'Nyilvános metaadatok ehhez az átjátszóhoz';

  @override
  String get repeater_refreshOwnerInfo => 'Frissítse az operátor adatait';

  @override
  String get repeater_floodMax => 'Árvíz max ugrás';

  @override
  String get repeater_floodMaxHelper =>
      'Maximum ugrások, amelyeket egy árvízcsomag utazhat (0-64)';

  @override
  String get repeater_advancedSettings => 'Fejlett';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Hangológombok tapasztalt kezelőknek';

  @override
  String get repeater_pathHashMode => 'Útvonal hash mód';

  @override
  String get repeater_pathHashModeHelper =>
      'Az átjátszó azonosítójának elárasztási útvonal/hurokészlelési címkékbe való kódolására használt bájtok. 0 = 1 bájt (256 azonosító, legfeljebb 64 ugrás), 1 = 2 bájt (65 000 azonosító, legfeljebb 32 ugrás), 2 = 3 bájt (16 millió azonosító, legfeljebb 21 ugrás). A v1.13 és régebbi firmware eldobja a többbájtos elérési utat – csak akkor emelje meg, ha a hálózat a v1.14+ verziót használja.';

  @override
  String get repeater_keySettings => 'Change Identity Keys';

  @override
  String get repeater_keySettingsSubtitle =>
      'Change the public/private keypair';

  @override
  String get repeater_prvKey => 'Private key';

  @override
  String get repeater_prvKeyHelper =>
      'A new private key for the repeater, a 128-character hex string.';

  @override
  String get repeater_generatePrvKey => 'Generate a random keypair';

  @override
  String get repeater_stopGeneratingPrvKey => 'Interrupt search for keypair';

  @override
  String get repeater_pubKey => 'Public key';

  @override
  String get repeater_pubKeyHelper =>
      'This is the public key that goes with the generated private key. You can\'t set this directly.';

  @override
  String get repeater_pubKeyPrefix => 'Desired prefix';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Find a public key that starts with these hex digits. Expected tries needed: $tries.';
  }

  @override
  String get repeater_txDelay => 'Áradási TX késleltetés';

  @override
  String get repeater_txDelayHelper =>
      'Újraküldési térköz az árvízi forgalomhoz, a csomag sugárzási idejének szorzójaként (0-2, alapértelmezett 0,5). Magasabb = kevesebb ütközés, de lassabb szállítás.';

  @override
  String get repeater_directTxDelay => 'Közvetlen TX késleltetés';

  @override
  String get repeater_directTxDelayHelper =>
      'A közvetlen (nem elárasztásos) forgalom újraküldési távolsága a csomag sugárzási idejének szorzójaként (0-2, alapértelmezett 0,3).';

  @override
  String get repeater_intThresh => 'Interferencia küszöb';

  @override
  String get repeater_intThreshHelper =>
      'A küszöbérték átkerült a rádió zajszint-kalibrációjához, így az e szint feletti interferenciát elutasítja. 0 letilt – csak akkor emel, ha zajos sávban RX hibákat lát.';

  @override
  String get repeater_agcResetInterval => 'AGC reset intervallum';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Milyen gyakran kell visszaállítani a rádió automatikus erősítésszabályozását, hogy helyreálljon a beragadt erősítési állapotból. A másodpercek, 4 többszörösére csökkentve. 0 letiltja az időszakos visszaállításokat.';

  @override
  String get repeater_actionsTitle => 'Akciók';

  @override
  String get repeater_sendAdvert => 'Árvízhirdetés küldése';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Adjon árvízreklámot a hálózaton keresztül';

  @override
  String get repeater_sendAdvertZeroHop => 'Zéró ugrású hirdetés küldése';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Egyugrásos hirdetés sugárzása (közvetítés nélkül)';

  @override
  String get repeater_clockSync => 'Óra szinkronizálása most';

  @override
  String get repeater_clockSyncSubtitle =>
      'Tolja a telefon idejét az átjátszóhoz';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action sikerült';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action sikertelen: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'A beállítások mentve – az átjátszó újraindítása az alkalmazáshoz';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Néhány beállítás nem sikerült: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Hiba a beállítások mentésekor: $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Frissítse az alapvető beállításokat';

  @override
  String get repeater_refreshRadioSettings => 'Frissítse a rádióbeállításokat';

  @override
  String get repeater_refreshTxPower => 'TX teljesítmény frissítése';

  @override
  String get repeater_refreshPacketForwarding => 'Csomagtovábbítás frissítése';

  @override
  String get repeater_refreshGuestAccess => 'Vendég hozzáférés frissítése';

  @override
  String get repeater_refreshPrivacyMode => 'Frissítse az adatvédelmi módot';

  @override
  String repeater_refreshed(String label) {
    return '$label frissítve';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Hiba a $label frissítésekor';
  }

  @override
  String get repeater_cliTitle => 'Repeater CLI';

  @override
  String get repeater_debugNextCommand => 'Debug Next Command';

  @override
  String get repeater_commandHelp => 'Command Help';

  @override
  String get repeater_clearHistory => 'Törölje az előzményeket';

  @override
  String get repeater_noCommandsSent => 'Még nem küldtek parancsot';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Írjon be egy parancsot alább, vagy használjon gyorsparancsokat';

  @override
  String get repeater_enterCommandHint => 'Írja be a parancsot...';

  @override
  String get repeater_previousCommand => 'Előző parancs';

  @override
  String get repeater_nextCommand => 'Következő parancs';

  @override
  String get repeater_enterCommandFirst => 'Először írjon be egy parancsot';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI parancskeret';

  @override
  String repeater_cliCommandError(String error) {
    return 'Hiba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Get Name';

  @override
  String get repeater_cliQuickGetRadio => 'Szerezz rádiót';

  @override
  String get repeater_cliQuickGetTx => 'Szerezd meg a TX-et';

  @override
  String get repeater_cliQuickNeighbors => 'Szomszédok';

  @override
  String get repeater_cliQuickVersion => 'Változat';

  @override
  String get repeater_cliQuickAdvertise => 'Hirdet';

  @override
  String get repeater_cliQuickClock => 'Óra';

  @override
  String get repeater_cliQuickClockSync => 'Óra szinkronizálás';

  @override
  String get repeater_cliQuickDiscovery => 'Fedezze fel a szomszédokat';

  @override
  String get repeater_cliHelpAdvert => 'Reklámcsomagot küld';

  @override
  String get repeater_cliHelpReboot =>
      'Újraindítja az eszközt. (megjegyzendő, hogy \"Időtúllépés\" jelenik meg, ami normális)';

  @override
  String get repeater_cliHelpClock =>
      'Megjeleníti az aktuális időt az eszköz órájánként.';

  @override
  String get repeater_cliHelpPassword =>
      'Új rendszergazdai jelszót állít be az eszközhöz.';

  @override
  String get repeater_cliHelpVersion =>
      'Megmutatja az eszköz verzióját és a firmware felépítési dátumát.';

  @override
  String get repeater_cliHelpClearStats =>
      'Nullára állítja a különböző statisztikai számlálókat.';

  @override
  String get repeater_cliHelpSetAf => 'Beállítja a műsoridő-tényezőt.';

  @override
  String get repeater_cliHelpSetTx =>
      'A LoRa adási teljesítményét dBm-ben állítja be. (újraindítás az alkalmazáshoz)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Engedélyezi vagy letiltja a csomópont ismétlő szerepét.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Szobaszerver) Ha \'be\', akkor az üres jelszó bejelentkezés engedélyezett, de nem lehet postázni a szobába. (csak olvasható)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Beállítja a bejövő árvízcsomag ugrásainak maximális számát (ha >= max, a csomag nem kerül továbbításra)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Beállítja az interferencia küszöböt (DB-ben). Az alapértelmezett érték 14. Állítsa 0-ra a csatornainterferencia-érzékelés letiltásához.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Beállítja az Auto Gain Controller alaphelyzetbe állításának intervallumát. A letiltáshoz állítsa 0-ra.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Engedélyezi vagy letiltja a „dupla ACK” funkciót.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Beállítja a helyi (nulla ugrású) hirdetési csomag küldésének időzítési időközét percekben. A letiltáshoz állítsa 0-ra.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Beállítja az időzítő intervallumát órákban az árvízhirdetési csomag küldéséhez. A letiltáshoz állítsa 0-ra.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Beállítja/frissíti a vendég jelszavát. (Repeaterek esetén a vendégbejelentkezés elküldheti a \"Statisztikák lekérése\" kérést)';

  @override
  String get repeater_cliHelpSetName => 'Beállítja a hirdetés nevét.';

  @override
  String get repeater_cliHelpSetLat =>
      'Beállítja a hirdetéstérkép szélességi fokát. (tizedes fok)';

  @override
  String get repeater_cliHelpSetLon =>
      'Beállítja a hirdetési térkép hosszúsági fokát. (tizedes fok)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Teljesen új rádióparamétereket állít be, és elmenti a beállításokhoz. Az alkalmazáshoz \"reboot\" parancs szükséges.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Beállítja a (kísérleti) bázist (az effektushoz > 1-nek kell lennie) a fogadott csomagok enyhe késleltetéséhez, a jelerősség/pontszám alapján. A letiltáshoz állítsa 0-ra.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Beállít egy tényezőt, megszorozva az adásidővel egy elárasztásos módú csomaghoz és egy véletlenszerű résrendszerhez, hogy késleltesse a továbbítását. (az ütközések valószínűségének csökkentése érdekében)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Ugyanaz, mint a txdelay, de véletlenszerű késleltetés alkalmazására a közvetlen módú csomagok továbbítására.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Bridge engedélyezése/letiltása.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Állítsa be a késleltetést a csomagok újraküldése előtt.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Válassza ki, hogy a híd újraküldje-e a fogadott vagy továbbított csomagokat.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Soros kapcsolat átviteli sebességének beállítása rs232 hidakhoz.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Állítsa be a hídtitkot espnow hidakhoz.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Egyéni tényezőt állít be a jelentett akkumulátorfeszültség beállításához (csak bizonyos kártyákon támogatott).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Ideiglenes rádióparamétereket állít be a megadott számú percre, majd visszaáll az eredeti rádióparaméterekre. (NEM menti a beállításokba).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Módosítja az ACL-t. Eltávolítja a megfelelő bejegyzést (pubkey előtag alapján), ha az „engedélyek” értéke nulla. Új bejegyzést ad hozzá, ha a pubkey-hex teljes hosszúságú, és jelenleg nincs az ACL-ben. Frissíti a bejegyzést a pubkey előtag egyeztetésével. Az engedélybitek firmware-szerepkörönként változnak, de az alacsony 2 bit a következő: 0 (Vendég), 1 (Csak olvasható), 2 (Olvasás, írás), 3 (Adminisztrátor)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Hidatípust nem kap, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Elindítja a csomagnaplózást a fájlrendszerbe.';

  @override
  String get repeater_cliHelpLogStop =>
      'Leállítja a csomagok naplózását a fájlrendszerbe.';

  @override
  String get repeater_cliHelpLogErase =>
      'Törli a csomagnaplókat a fájlrendszerből.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Megjeleníti a nulla ugrású hirdetéseken keresztül hallható egyéb átjátszó csomópontok listáját. Minden sor id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Eltávolítja az első egyező bejegyzést (a pubkey előtag (hex) alapján) a szomszédok listájából.';

  @override
  String get repeater_cliHelpRegion =>
      '(csak soros) Felsorolja az összes meghatározott régiót és az aktuális árvízi engedélyeket.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'MEGJEGYZÉS: ez egy speciális többparancsos hívás. Minden következő parancs egy régiónév (szóközökkel behúzva a szülőhierarchiát jelölve, legalább egy szóközzel). Üres sor/parancs küldésével megszűnik.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Régiót keres adott név előtaggal (vagy \"*\" a globális hatókörhöz). A válasz a következővel: \"-> régiónév (szülőnév) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Adott névvel rendelkező régiódefiníció hozzáadása vagy frissítése.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Eltávolítja a megadott nevű régiódefiníciót. (pontosan meg kell egyeznie, és nem lehetnek alárendelt régiók)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Beállítja az \'F\'lood engedélyt az adott régióhoz. (\"*\" a globális/örökölt hatókörre)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Eltávolítja az \'F\'lood engedélyt az adott régióhoz. (MEGJEGYZÉS: ebben a szakaszban NEM tanácsos ezt használni a globális/örökölt hatókörön!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Az aktuális „otthoni” régióval válaszol. (A megjegyzés még bárhol érvényes, jövőre fenntartva)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Beállítja az „otthoni” régiót.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Megőrzi a régiólistát/leképezést a tárhelyen.';

  @override
  String get repeater_cliHelpGps =>
      'Megadja a gps állapotát. Ha a gps ki van kapcsolva, akkor csak kikapcsolva válaszol, ha be van kapcsolva, akkor válaszol: be, állapot, javítás, sat count';

  @override
  String get repeater_cliHelpGpsOnOff =>
      'Bekapcsolja a gps tápellátási állapotát.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Szinkronizálja a csomópont idejét a gps órával.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Beállítja a csomópont pozícióját a gps koordinátákra és menti a beállításokat.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Megadja a csomópont helyhirdetési konfigurációját:\n- nincs: ne adja meg a helyet a hirdetésekben\n- megosztás: GPS hely megosztása (a SensorManagerből)\n- preferenciák: a beállításokban tárolt hely hirdetése';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Beállítja a helyhirdetés konfigurációját.';

  @override
  String get repeater_commandsListTitle => 'Parancslista';

  @override
  String get repeater_commandsListNote =>
      'MEGJEGYZÉS: a különféle \"set ...\" parancsokhoz van egy \"get ...\" parancs is.';

  @override
  String get repeater_general => 'Általános';

  @override
  String get repeater_settingsCategory => 'Beállítások elemre';

  @override
  String get repeater_bridge => 'Híd';

  @override
  String get repeater_logging => 'Fakitermelés';

  @override
  String get repeater_neighborsRepeaterOnly => 'Szomszédok (csak átjátszó)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Régiókezelés (csak ismétlő)';

  @override
  String get repeater_regionNote =>
      'Régióparancsok kerültek bevezetésre a régiódefiníciók és engedélyek kezelésére.';

  @override
  String get repeater_gpsManagement => 'GPS kezelés';

  @override
  String get repeater_gpsNote =>
      'A gps parancs bevezetésre került a helyhez kapcsolódó témák kezeléséhez.';

  @override
  String get repeater_getCategory => 'Szerezzen értékeket';

  @override
  String get repeater_powerMgmt => 'Energiagazdálkodás';

  @override
  String get repeater_sensors => 'Érzékelők';

  @override
  String get repeater_cliHelpPowerOff =>
      'Kikapcsolja a készüléket. (nem várható válasz)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Visszaállítja az órát egy ismert korszakra, és újraindítja az eszközt.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Zéró ugrású hirdetést küld (csak a közvetlen szomszédok számára).';

  @override
  String get repeater_cliHelpStartOta =>
      'Elindít egy vezeték nélküli firmware-frissítést a támogatott kártyákon.';

  @override
  String get repeater_cliHelpTime =>
      'Beállítja az eszköz óráját a megadott Unix korszak másodpercekre. Az óra nem tud visszafelé mozogni.';

  @override
  String get repeater_cliHelpBoard =>
      'Megmutatja a kártya gyártóját/hardver azonosítóját.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Csomópont-felderítési kérelmet küld a közeli szomszédoknak. (Csak ismétlő)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Megmutatja, hogy az energiatakarékos mód be vagy ki van-e kapcsolva.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Engedélyezi vagy letiltja az energiatakarékos módot (ahol támogatott).';

  @override
  String get repeater_cliHelpErase =>
      '(Csak soros) Formázza az eszköz fájlrendszerét. Törli az összes beállítást és névjegyet.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Beállítja a maximális megengedett átviteli munkaciklust százalékban (1-100). Belsőleg állítja be a műsoridőtényezőt.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(Csak soros) Lecseréli az eszközazonosító privát kulcsot. Újraindítás szükséges az alkalmazáshoz. Új nyilvános kulcsot generál.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(csak SX126x) Bekapcsolja a megnövelt RX-erősítést a jobb érzékenység érdekében nagyobb áramfelvétel mellett.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Beállítja a hirdetésekben szereplő tulajdonos elérhetőségi adatait. A \'|\' használata újsorokhoz.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Beállítja az útvonal-kivonat módot. 0 = örökölt, 1 = szabványos, 2 = szigorú. Befolyásolja az útválasztási útvonalak egyeztetését.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Beállítja az útválasztási hurok észlelésének érzékenységét: ki, minimális, közepes vagy szigorú.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Csak soros) Gyorsan beállítja csak a frekvenciát. Újraindítás szükséges. A „rádió beállítása” előnyben részesítse a teljes rádióparamétereket.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Csak ESPNow bridge) Beállítja a híd által használt WiFi csatornát (1-14).';

  @override
  String get repeater_cliHelpGetName =>
      'Megjeleníti a konfigurált csomópont nevét.';

  @override
  String get repeater_cliHelpGetRole =>
      'Megmutatja a firmware szerepkörét (Repeater, Room Server stb.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Megjeleníti az eszköz nyilvános kulcsát.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Csak soros) Az eszköz privát kulcsát mutatja. Kezelje titokként.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Megmutatja, hogy a csomagtovábbítás (ismétlő szerepkör) be vagy ki van-e kapcsolva.';

  @override
  String get repeater_cliHelpGetTx =>
      'Az aktuális TX teljesítményt mutatja dBm-ben.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Megjeleníti a beállított rádiófrekvenciát MHz-ben.';

  @override
  String get repeater_cliHelpGetRadio =>
      'A teljes rádióparamétereket mutatja: frekvencia, sávszélesség, szórási tényező, kódolási sebesség.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(csak SX126x) Megjeleníti az RX megnövelt erősítési állapotát.';

  @override
  String get repeater_cliHelpGetAf => 'Megmutatja az aktuális műsoridőt.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Megjeleníti az aktuális megengedett munkaciklust százalékban.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'A csatorna interferencia küszöbértékét mutatja dB-ben.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Az AGC reset intervallumát mutatja másodpercben.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Megmutatja, hogy a dupla ACK mód be van-e kapcsolva (1) vagy ki (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Megmutatja, hogy a vendég csak olvasási hozzáférés engedélyezett-e.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'A helyi hirdetési intervallumot mutatja percben.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Megjeleníti az árvízhirdetés intervallumát órákban.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Megjeleníti a beállított vendégjelszót.';

  @override
  String get repeater_cliHelpGetLat =>
      'Megjeleníti a beállított szélességi fokot.';

  @override
  String get repeater_cliHelpGetLon => 'A beállított hosszúságot mutatja.';

  @override
  String get repeater_cliHelpGetRxDelay => 'Az rxdelay alapértékét mutatja.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Megjeleníti az elárasztási mód txdelay tényezőjét.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'A közvetlen módú txdelay tényezőt mutatja.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Megmutatja a maximális elárasztási ugrás számát.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Megjeleníti a tulajdonos kapcsolatfelvételi adatait.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Az elérési út-kivonat módot mutatja (0/1/2).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'A hurokérzékelés érzékenységét mutatja.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Csak soros) Felsorolja a hozzáférés-vezérlési bejegyzéseket az átjátszón.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Megmutatja, hogy a híd engedélyezve van-e.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'A híd késleltetését mutatja ms-ban.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Megmutatja, hogy a híd RX vagy TX csomagokat naplóz-e.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(csak RS232 híd) A híd adatátviteli sebességét mutatja.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(csak ESPNow bridge) A híd WiFi csatornáját mutatja.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Csak ESPNow bridge) Megjeleníti a híd megosztott titkát.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Csak NRF52) A rendszerbetöltő verzióját mutatja.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Az ADC szorzót mutatja (akkumulátor-feszültség skálázás).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Beszámol arról, hogy a testület rendelkezik-e hatalomkezelési támogatással.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Az aktuális áramforrást mutatja: külső vagy akkumulátor.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Megmutatja a legutóbbi alaphelyzetbe állítás és leállítás okait.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Megmutatja a rendszerindítási akkumulátorfeszültséget mV-ban.';

  @override
  String get repeater_cliHelpSensorGet =>
      'Kulcs segítségével beolvassa az egyéni szenzorbeállítást.';

  @override
  String get repeater_cliHelpSensorSet => 'Egyéni szenzorbeállítást ír.';

  @override
  String get repeater_cliHelpSensorList =>
      'Felsorolja az összes egyéni érzékelőbeállítást, oldalszámozással az opcionális kezdőindexből.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Megjeleníti az aktuális alapértelmezett régióhatókört.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Beállítja az alapértelmezett régió hatókört. A törléshez használja a \"<null>\" parancsot.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Felsorolja azokat a régiókat, amelyek lehetővé teszik az árvízi forgalmat.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Felsorolja azokat a régiókat, amelyek megtagadják az árvízi forgalmat.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Csak soros) Csomag szintű statisztikákat jelenít meg.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Csak soros) Rádióstatisztikák megjelenítése.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Csak soros) Az alapvető firmware-statisztikák megjelenítése.';

  @override
  String get telemetry_receivedData => 'Fogadott telemetriai adatok';

  @override
  String get telemetry_requestTimeout =>
      'A telemetriai kérés időtúllépése lejárt.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Hiba a telemetria betöltésekor: $error';
  }

  @override
  String get telemetry_noData => 'Nincsenek telemetriai adatok.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Csatorna $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Akkumulátor';

  @override
  String get telemetry_voltageLabel => 'Feszültség';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU hőmérséklet';

  @override
  String get telemetry_temperatureLabel => 'Hőmérséklet';

  @override
  String get telemetry_currentLabel => 'Jelenlegi';

  @override
  String telemetry_batteryValue(int percent, String volts) {
    return '$percent% / ${volts}V';
  }

  @override
  String telemetry_voltageValue(String volts) {
    return '${volts}V';
  }

  @override
  String telemetry_currentValue(String amps) {
    return '${amps}A';
  }

  @override
  String telemetry_temperatureValue(String celsius, String fahrenheit) {
    return '$celsius°C / $fahrenheit°F';
  }

  @override
  String get telemetry_digitalInputLabel => 'Digitális bemenet';

  @override
  String get telemetry_digitalOutputLabel => 'Digitális kimenet';

  @override
  String get telemetry_analogInputLabel => 'Analóg bemenet';

  @override
  String get telemetry_analogOutputLabel => 'Analóg kimenet';

  @override
  String get telemetry_genericLabel => 'Általános érzékelő';

  @override
  String get telemetry_luminosityLabel => 'Fényesség';

  @override
  String get telemetry_presenceLabel => 'Jelenlét';

  @override
  String get telemetry_humidityLabel => 'Nedvesség';

  @override
  String get telemetry_accelerometerLabel => 'Gyorsulásmérő';

  @override
  String get telemetry_pressureLabel => 'Nyomás';

  @override
  String get telemetry_altitudeLabel => 'Magasság';

  @override
  String get telemetry_frequencyLabel => 'Frekvencia';

  @override
  String get telemetry_percentageLabel => 'Százalék';

  @override
  String get telemetry_concentrationLabel => 'Koncentráció';

  @override
  String get telemetry_powerLabel => 'Hatalom';

  @override
  String get telemetry_distanceLabel => 'Távolság';

  @override
  String get telemetry_energyLabel => 'Energia';

  @override
  String get telemetry_directionLabel => 'Irány';

  @override
  String get telemetry_timeLabel => 'Idő';

  @override
  String get telemetry_gyrometerLabel => 'Girométer';

  @override
  String get telemetry_colourLabel => 'Szín';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Kapcsoló';

  @override
  String get telemetry_polylineLabel => 'Vonallánc';

  @override
  String telemetry_altitudeValue(String meters) {
    return '$meters m';
  }

  @override
  String telemetry_frequencyValue(String hertz) {
    return '$hertz Hz';
  }

  @override
  String telemetry_pressureValue(String hpa) {
    return '$hpa hPa';
  }

  @override
  String telemetry_luminosityValue(String lux) {
    return '$lux lx';
  }

  @override
  String telemetry_powerValue(String watts) {
    return '$watts W';
  }

  @override
  String telemetry_distanceValue(String meters) {
    return '$meters m';
  }

  @override
  String telemetry_energyValue(String kilowattHours) {
    return '$kilowattHours kWh';
  }

  @override
  String telemetry_directionValue(String degrees) {
    return '$degrees°';
  }

  @override
  String telemetry_concentrationValue(String ppm) {
    return '$ppm ppm';
  }

  @override
  String telemetry_percentageValue(String percent) {
    return '$percent%';
  }

  @override
  String telemetry_analogValue(String value) {
    return '$value';
  }

  @override
  String get telemetry_autoFetchQuantity => 'Mennyiséget kér';

  @override
  String get telemetry_error => 'Nem sikerült lekérni az adatokat';

  @override
  String get neighbors_receivedData => 'Szomszédok adatok fogadása';

  @override
  String get neighbors_requestTimedOut => 'A szomszédok kérése lejárt.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Hiba a szomszédok betöltésekor: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ismétlők Szomszédok';

  @override
  String get neighbors_noData =>
      'A szomszédokról nem állnak rendelkezésre adatok.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Ismeretlen $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Hallva: $time ezelőtt';
  }

  @override
  String get channelPath_title => 'Csomag elérési útja';

  @override
  String get channelPath_viewMap => 'Térkép megtekintése';

  @override
  String get channelPath_otherObservedPaths => 'Egyéb megfigyelt utak';

  @override
  String get channelPath_repeaterHops => 'Repeater Hops';

  @override
  String get channelPath_noHopDetails =>
      'Ennél a csomagnál a komlórészletek nincsenek megadva.';

  @override
  String get channelPath_messageDetails => 'Üzenet részletei';

  @override
  String get channelPath_senderLabel => 'Feladó';

  @override
  String get channelPath_timeLabel => 'Idő';

  @override
  String get channelPath_repeatsLabel => 'Ismétlődik';

  @override
  String channelPath_pathLabel(int index) {
    return '$index elérési út';
  }

  @override
  String get channelPath_observedLabel => 'Megfigyelt';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Megfigyelt útvonal $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nincsenek helyadatok';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Ismeretlen';

  @override
  String get channelPath_floodPath => 'Árvíz';

  @override
  String get channelPath_directPath => 'Közvetlen';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 / $total ugrás';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed / $total ugrás';
  }

  @override
  String get channelPath_mapTitle => 'Útvonal térkép';

  @override
  String get channelPath_noRepeaterLocations =>
      'Nincs elérhető átjátszó hely ehhez az útvonalhoz.';

  @override
  String channelPath_primaryPath(int index) {
    return '$index elérési út (elsődleges)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Útvonal';

  @override
  String get channelPath_observedPathHeader => 'Megfigyelt ösvény';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Ehhez a csomaghoz nem állnak rendelkezésre ugrási részletek.';

  @override
  String get channelPath_unknownRepeater => 'Ismeretlen Repeater';

  @override
  String get community_title => 'Közösség';

  @override
  String get community_create => 'Közösség létrehozása';

  @override
  String get community_createDesc =>
      'Hozzon létre egy új közösséget, és ossza meg QR-kóddal.';

  @override
  String get community_join => 'Csatlakozik';

  @override
  String get community_joinTitle => 'Csatlakozz a közösséghez';

  @override
  String community_joinConfirmation(String name) {
    return 'Szeretnél csatlakozni a \"$name\" közösséghez?';
  }

  @override
  String get community_scanQr => 'Scan Community QR';

  @override
  String get community_scanInstructions =>
      'Irányítsa a kamerát egy közösségi QR-kódra';

  @override
  String get community_showQr => 'QR-kód megjelenítése';

  @override
  String get community_publicChannel => 'Közösségi Nyilvános';

  @override
  String get community_hashtagChannel => 'Közösségi hashtag';

  @override
  String get community_name => 'Közösség neve';

  @override
  String get community_enterName => 'Adja meg a közösség nevét';

  @override
  String community_created(String name) {
    return 'A \"$name\" közösség létrehozva';
  }

  @override
  String community_joined(String name) {
    return 'Csatlakozott a \"$name\" közösséghez';
  }

  @override
  String get community_qrTitle => 'Közösség megosztása';

  @override
  String community_qrInstructions(String name) {
    return 'Olvassa be ezt a QR-kódot a \"$name\" csoporthoz való csatlakozáshoz';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'A közösségi hashtag csatornákhoz csak a közösség tagjai csatlakozhatnak';

  @override
  String get community_invalidQrCode => 'Érvénytelen közösségi QR-kód';

  @override
  String get community_alreadyMember => 'Már tag';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Ön már tagja a(z) \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Közösségi nyilvános csatorna hozzáadása';

  @override
  String get community_addPublicChannelHint =>
      'Nyilvános csatorna automatikus hozzáadása ehhez a közösséghez';

  @override
  String get community_noCommunities => 'Még nem csatlakozott közösség';

  @override
  String get community_scanOrCreate =>
      'Olvassa be a QR-kódot, vagy hozzon létre egy közösséget a kezdéshez';

  @override
  String get community_manageCommunities => 'Közösségek kezelése';

  @override
  String get community_delete => 'Kilépés a közösségből';

  @override
  String community_deleteConfirm(String name) {
    return 'Kilép a(z) „$name” programból?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Ezzel $count csatornát és azok üzeneteit is törli.';
  }

  @override
  String community_deleted(String name) {
    return 'Kilépett a \"$name\" közösségből';
  }

  @override
  String get community_regenerateSecret => 'Regeneráld a Titkot';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Újragenerálja a titkos kulcsot a következőhöz: \"$name\"? A kommunikáció folytatásához minden tagnak be kell olvasnia az új QR-kódot.';
  }

  @override
  String get community_regenerate => 'Regenerátum';

  @override
  String community_secretRegenerated(String name) {
    return 'Titok újra létrehozva a következőhöz: \"$name\"';
  }

  @override
  String get community_updateSecret => 'Frissítse a Titkot';

  @override
  String community_secretUpdated(String name) {
    return 'Titok frissítve a következőhöz: \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Olvassa be az új QR-kódot a „$name” titkának frissítéséhez';
  }

  @override
  String get community_addHashtagChannel => 'Közösségi hashtag hozzáadása';

  @override
  String get community_addHashtagChannelDesc =>
      'Adj hozzá egy hashtag-csatornát ehhez a közösséghez';

  @override
  String get community_selectCommunity => 'Válassza a Közösség lehetőséget';

  @override
  String get community_regularHashtag => 'Rendszeres hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Nyilvános hashtag (bárki csatlakozhat)';

  @override
  String get community_communityHashtag => 'Közösségi hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Privát a közösség tagjai számára';

  @override
  String community_forCommunity(String name) {
    return '$name';
  }

  @override
  String get listFilter_tooltip => 'Szűrés és rendezés';

  @override
  String get listFilter_sortBy => 'Rendezés';

  @override
  String get listFilter_latestMessages => 'Legújabb üzenetek';

  @override
  String get listFilter_heardRecently => 'Nemrég hallottam';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Szűrők';

  @override
  String get listFilter_all => 'Minden';

  @override
  String get listFilter_favorites => 'Kedvencek';

  @override
  String get listFilter_addToFavorites => 'Hozzáadás a kedvencekhez';

  @override
  String get listFilter_removeFromFavorites => 'Eltávolítás a kedvencek közül';

  @override
  String get listFilter_users => 'Felhasználók';

  @override
  String get listFilter_repeaters => 'Ismétlők';

  @override
  String get listFilter_roomServers => 'Szobaszerverek';

  @override
  String get listFilter_unreadOnly => 'Csak olvasatlan';

  @override
  String get listFilter_newGroup => 'Új csoport';

  @override
  String get pathTrace_you => 'Te';

  @override
  String get pathTrace_failed => 'Az útvonal nyomon követése nem sikerült.';

  @override
  String get pathTrace_notAvailable => 'Útvonal nyomkövetés nem érhető el.';

  @override
  String get pathTrace_refreshTooltip => 'Path Trace frissítése.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Egy vagy több komló helye hiányzik!';

  @override
  String get pathTrace_clearTooltip => 'Tiszta útvonal.';

  @override
  String get losSelectStartEnd =>
      'Válassza ki a LOS kezdő és záró csomópontját.';

  @override
  String losRunFailed(String error) {
    return 'A rálátás ellenőrzése sikertelen: $error';
  }

  @override
  String get losClearAllPoints => 'Törölje az összes pontot';

  @override
  String get losRunToViewElevationProfile =>
      'Futtassa a LOS-t a magassági profil megtekintéséhez';

  @override
  String get losMenuTitle => 'LOS menü';

  @override
  String get losMenuSubtitle =>
      'Érintse meg a csomópontokat, vagy tartsa lenyomva a térképet az egyéni pontokhoz';

  @override
  String get losShowDisplayNodes => 'Megjelenítési csomópontok megjelenítése';

  @override
  String get losCustomPoints => 'Egyedi pontok';

  @override
  String losCustomPointLabel(int index) {
    return 'Egyéni $index';
  }

  @override
  String get losPointA => 'A pont';

  @override
  String get losPointB => 'B pont';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenna A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'B antenna: $value $unit';
  }

  @override
  String get losRun => 'Futtassa a LOS-t';

  @override
  String get losNoElevationData => 'Nincsenek magassági adatok';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, tiszta LOS, minimális távolság $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blokkolta: $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: ellenőrzés...';

  @override
  String get losStatusNoData => 'LOS: nincs adat';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total tiszta, $blocked blokkolva, $unknown ismeretlen';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Egy vagy több mintához nem állnak rendelkezésre magassági adatok.';

  @override
  String get losErrorInvalidInput =>
      'Érvénytelen pontok/emelkedési adatok a LOS számításhoz.';

  @override
  String get losRenameCustomPoint => 'Egyéni pont átnevezése';

  @override
  String get losPointName => 'Pont neve';

  @override
  String get losShowPanelTooltip => 'LOS panel megjelenítése';

  @override
  String get losHidePanelTooltip => 'LOS panel elrejtése';

  @override
  String get losElevationAttribution =>
      'Magassági adatok: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Rádióhorizont';

  @override
  String get losLegendLosBeam => 'LOS gerenda';

  @override
  String get losLegendTerrain => 'Terep';

  @override
  String get losBlockedSpotsTitle => 'Blokkolt helyek';

  @override
  String get losBlockedSpotsHint =>
      'Koppintson egy blokkolt helyre, hogy kijelölje azt a térképen.';

  @override
  String losBlockedSpotChip(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit • $obstruction $heightUnit';
  }

  @override
  String get losSelectedObstructionTitle => 'Kiválasztott akadály';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Letiltja: $obstruction $heightUnit, $distanceFromA A-tól és $distanceFromB B-től ($distanceUnit).';
  }

  @override
  String get losFrequencyLabel => 'Frekvencia';

  @override
  String get losFrequencyInfoTooltip => 'Tekintse meg a számítás részleteit';

  @override
  String get losFrequencyDialogTitle => 'Rádióhorizont számítás';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'A k=$baselineK értéktől kezdve $baselineFreq MHz-en a számítás az aktuális $frequencyMHz MHz-es sávhoz igazítja a k-tényezőt, amely meghatározza az ívelt rádióhorizont-sapkát.';
  }

  @override
  String get contacts_pathTrace => 'Út nyom';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace =>
      'Útvonal nyomkövetése az átjátszóhoz';

  @override
  String get contacts_repeaterPing => 'Ping átjátszó';

  @override
  String get contacts_roomPathTrace => 'Útvonal nyomkövetése a szobaszerverhez';

  @override
  String get contacts_roomPing => 'Ping szoba szerver';

  @override
  String get contacts_chatTraceRoute => 'Út nyomvonala';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Útvonal nyomon követése ide: $name';
  }

  @override
  String get contacts_clipboardEmpty => 'A vágólap üres.';

  @override
  String get contacts_invalidAdvertFormat =>
      'Érvénytelen kapcsolattartási adatok';

  @override
  String get contacts_contactImported => 'A névjegy importálása megtörtént.';

  @override
  String get contacts_contactImportFailed =>
      'Nem sikerült importálni a névjegyet.';

  @override
  String get discoveredContacts_export => 'Felfedezett kapcsolatok exportálása';

  @override
  String get discoveredContacts_import => 'Felfedezett kapcsolatok importálása';

  @override
  String discoveredContacts_exported(String path) {
    return 'A felfedezett kapcsolatok exportálva ide: $path.';
  }

  @override
  String discoveredContacts_exportFailed(String error) {
    return 'A felfedezett kapcsolatok exportálása nem sikerült: $error';
  }

  @override
  String discoveredContacts_imported(int count) {
    return '$count felfedezett kapcsolat importálva.';
  }

  @override
  String get discoveredContacts_importNoContacts =>
      'Az importfájlban nem találhatók kapcsolatok.';

  @override
  String discoveredContacts_importFailed(String error) {
    return 'A felfedezett kapcsolatok importálása nem sikerült: $error';
  }

  @override
  String get contacts_zeroHopAdvert => 'Zero Hop hirdetés';

  @override
  String get contacts_floodAdvert => 'Árvíz hirdetés';

  @override
  String get contacts_copyAdvertToClipboard => 'Hirdetés másolása a vágólapra';

  @override
  String get contacts_addContactFromClipboard =>
      'Névjegy hozzáadása a vágólapról';

  @override
  String get contacts_ShareContact => 'Névjegy másolása a vágólapra';

  @override
  String get contacts_ShareContactZeroHop => 'Kapcsolat megosztása hirdetéssel';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Az elérhetőséget hirdetéssel küldték el.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Nem sikerült elküldeni a névjegyet.';

  @override
  String get contacts_contactAdvertCopied => 'A hirdetés a vágólapra másolva.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'A hirdetés vágólapra másolása nem sikerült.';

  @override
  String get notification_activityTitle => 'MeshCore tevékenység';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'üzenetek',
      one: 'üzenet',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'csatornaüzenetek',
      one: 'csatornaüzenet',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'új csomópontok',
      one: 'új csomópont',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Új $contactType felfedezve';
  }

  @override
  String get notification_receivedNewMessage => 'Új üzenet érkezett';

  @override
  String get settings_gpxExportRepeaters =>
      'Ismétlők / szobaszerver exportálása GPX-be';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportálja az átjátszókat / szobaszervereket a hellyel GPX-fájlba.';

  @override
  String get settings_gpxExportContacts => 'Exportáljon társokat a GPX-be';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'A hellyel rendelkező kísérőket GPX-fájlba exportálja.';

  @override
  String get settings_gpxExportAll => 'Az összes névjegy exportálása a GPX-be';

  @override
  String get settings_gpxExportAllSubtitle =>
      'A hellyel rendelkező összes névjegyet GPX-fájlba exportálja.';

  @override
  String get settings_gpxExportSuccess => 'A GPX fájl sikeresen exportálva.';

  @override
  String get settings_gpxExportNoContacts =>
      'Nincsenek exportálandó névjegyek.';

  @override
  String get settings_gpxExportNotAvailable => 'Az Ön eszköze/OS nem támogatja';

  @override
  String get settings_gpxExportError => 'Hiba történt az exportálás során.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Repeater és szobaszerver helyei';

  @override
  String get settings_gpxExportChat => 'Társ helyek';

  @override
  String get settings_gpxExportAllContacts => 'Minden kapcsolattartó hely';

  @override
  String get settings_gpxExportShareText =>
      'A térképadatok a meshcore-openből exportálva';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open GPX térképadatok exportálása';

  @override
  String get snrIndicator_nearByRepeaters => 'Közeli átjátszók';

  @override
  String get snrIndicator_lastSeen => 'Utoljára látott';

  @override
  String get contactsSettings_title => 'Névjegyek beállításai';

  @override
  String get contactsSettings_autoAddTitle => 'Automatikus felfedezés';

  @override
  String get contactsSettings_otherTitle =>
      'Egyéb kapcsolattartási beállítások';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Felhasználók automatikus hozzáadása';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Engedélyezze a társ számára, hogy automatikusan hozzáadja a felfedezett felhasználókat.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Ismétlők automatikus hozzáadása';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Engedélyezze a társnak, hogy automatikusan hozzáadja a felfedezett ismétlőket.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Szobaszerverek automatikus hozzáadása';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Engedélyezze a társ számára, hogy automatikusan hozzáadja a felfedezett szobaszervereket.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Érzékelők automatikus hozzáadása';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Engedélyezze a társ számára a felfedezett érzékelők automatikus hozzáadását.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'A legrégebbi felülírása';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Amikor a névjegylista megtelik, a legrégebbi, nem kedvenc névjegy lecserélődik.';

  @override
  String get discoveredContacts_Title => 'Felfedezett kapcsolatok';

  @override
  String get discoveredContacts_noMatching => 'Nincsenek megfelelő névjegyek';

  @override
  String get discoveredContacts_searchHint =>
      'Keresés a talált névjegyek között';

  @override
  String get discoveredContacts_contactAdded => 'Kapcsolat hozzáadva';

  @override
  String get discoveredContacts_addContact => 'Névjegy hozzáadása elemre';

  @override
  String get discoveredContacts_copyContact => 'Névjegy másolása a vágólapra';

  @override
  String get discoveredContacts_deleteContact =>
      'A felfedezett névjegy törlése';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Törölje az összes felfedezett névjegyet';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Biztosan törli az összes felfedezett névjegyet?';

  @override
  String get chat_sendCooldown =>
      'Kérjük, várjon egy pillanatot, mielőtt újra elküldi.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Ugrás a legrégebbi olvasatlanra';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Ha olvasatlan üzeneteket tartalmazó csevegést nyit meg, görgessen az első olvasatlanra a legutóbbi helyett.';

  @override
  String get appSettings_languageHu => 'magyar';

  @override
  String get appSettings_languageJa => 'japán';

  @override
  String get appSettings_languageKo => 'koreai';

  @override
  String get radioStats_tooltip => 'Rádió és mesh statisztika';

  @override
  String get radioStats_screenTitle => 'Rádió statisztika';

  @override
  String get radioStats_notConnected =>
      'Csatlakozzon egy eszközhöz a rádióstatisztikák megtekintéséhez.';

  @override
  String get radioStats_firmwareTooOld =>
      'A rádióstatisztikákhoz v8-as vagy újabb firmware szükséges.';

  @override
  String get radioStats_waiting => 'Várakozás az adatokra…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Zajszint: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Utolsó RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Utolsó SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX műsoridő (összesen): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX műsoridő (összesen): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Zajszint (dBm) a legutóbbi mintákhoz képest.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Zajszint: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Rádióstatisztikák lekérése…';

  @override
  String get radioStats_settingsTile => 'Rádió statisztika';

  @override
  String get radioStats_settingsSubtitle => 'Zajszint, RSSI, SNR és műsoridő';

  @override
  String get translation_title => 'Fordítás';

  @override
  String get translation_enableTitle => 'Fordítás engedélyezése';

  @override
  String get translation_enableSubtitle =>
      'Fordítsa le a bejövő üzeneteket, és engedélyezze a küldés előtti fordítást.';

  @override
  String get translation_composerTitle => 'Küldés előtt fordítsa le';

  @override
  String get translation_composerSubtitle =>
      'Szabályozza a zeneszerző fordítási ikonjának alapértelmezett állapotát.';

  @override
  String get translation_autoIncomingTitle =>
      'A bejövő üzenetek automatikus fordítása';

  @override
  String get translation_autoIncomingSubtitle =>
      'Automatikusan lefordítja az üzeneteket értesítésekhez, csevegéshez vagy csatornához.';

  @override
  String get translation_translateMessage => 'Üzenet fordítása';

  @override
  String get translation_targetLanguage => 'Célnyelv';

  @override
  String get translation_useAppLanguage => 'Használja az alkalmazás nyelvét';

  @override
  String get translation_downloadedModelLabel => 'Letöltött modell';

  @override
  String get translation_presetModelLabel =>
      'Előre beállított átölelő arc modell';

  @override
  String get translation_manualUrlLabel => 'Kézi modell URL';

  @override
  String get translation_downloadModel => 'Modell letöltése';

  @override
  String get translation_downloading => 'Letöltés...';

  @override
  String get translation_working => 'Dolgozó...';

  @override
  String get translation_stop => 'Stop';

  @override
  String get translation_mergingChunks =>
      'Letöltött darabok egyesítése a végső fájlba...';

  @override
  String get translation_downloadedModels => 'Letöltött modellek';

  @override
  String get translation_deleteModel => 'Modell törlése';

  @override
  String get translation_modelDownloaded => 'Fordítási modell letöltve.';

  @override
  String get translation_downloadStopped => 'A letöltés leállt.';

  @override
  String translation_downloadFailed(String error) {
    return 'Letöltés sikertelen: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Először adja meg a modell URL-jét.';

  @override
  String get scanner_linuxPairingShowPin => 'PIN-kód megjelenítése';

  @override
  String get scanner_linuxPairingHidePin => 'PIN elrejtése';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth párosítási PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Írja be a $deviceName PIN-kódját (ha nincs, hagyja üresen).';
  }

  @override
  String get translation_messageTranslation => 'Üzenet fordítás';

  @override
  String get translation_translateBeforeSending => 'Küldés előtt fordítsa le';

  @override
  String get translation_composerEnabledHint =>
      'Az üzeneteket elküldés előtt lefordítják.';

  @override
  String get translation_composerDisabledHint =>
      'Üzeneteket küldhet az eredeti gépelt nyelven.';

  @override
  String translation_translateTo(String language) {
    return 'Fordítás $language';
  }

  @override
  String get translation_translationOptions => 'Fordítási lehetőségek';

  @override
  String get translation_systemLanguage => 'Rendszer nyelve';

  @override
  String get background_serviceTitle => 'MeshCore fut';

  @override
  String get background_serviceText => 'A BLE-kapcsolat fenntartása';

  @override
  String appSettings_translationModelDeleted(String name) {
    return 'Törölve $name';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Nem sikerült törölni: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Nem sikerült frissíteni a csatornát: $error';
  }

  @override
  String get contact_typeChat => 'Csevegés';

  @override
  String get contact_typeRepeater => 'Ismétlő';

  @override
  String get contact_typeRoom => 'Szoba';

  @override
  String get contact_typeSensor => 'Érzékelő';

  @override
  String get contact_typeUnknown => 'Ismeretlen';

  @override
  String get map_zoomIn => 'Nagyítás';

  @override
  String get map_zoomOut => 'Kicsinyítés';

  @override
  String get map_centerMap => 'Középső térkép';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'A Web Bluetooth használatához Chromium böngésző szükséges';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS megerősítve';

  @override
  String get pathTrace_legendInferred => 'Kikövetkeztetett pozíció';

  @override
  String get pathMap_viewSingle => 'Egyetlen';

  @override
  String get pathMap_viewCombined => 'Kombinált';

  @override
  String get pathMap_play => 'Játék';

  @override
  String get pathMap_pause => 'Szünet';

  @override
  String get pathMap_replay => 'Visszajátszás';

  @override
  String get pathMap_stepBack => 'Előző ugrás';

  @override
  String get pathMap_stepForward => 'Következő ugrás';

  @override
  String get pathMap_animationOn => 'Csomaganimáció megjelenítése';

  @override
  String get pathMap_animationOff => 'Csomaganimáció elrejtése';

  @override
  String pathMap_hopOf(int current, int total) {
    return '$current ugrás / $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Megfigyelt útvonalak: $count';
  }

  @override
  String get pathMap_primary => 'Elsődleges';

  @override
  String pathMap_alternate(int index) {
    return 'Alt $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ugrás',
      one: '1 ugrás',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Megosztott szegmens';

  @override
  String get pathMap_legendEstimated => 'Becsült szegmens';

  @override
  String pathMap_sharedNodeCount(int count) {
    return '$count elérési út használja';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ugrásnak nincs helyadata — a megjelenített útvonal részleges',
      one: '1 ugrásnak nincs helyadata — a megjelenített útvonal részleges',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Összes megjelenítése';

  @override
  String get pathMap_hidePath => 'Útvonal elrejtése';

  @override
  String get pathMap_showPath => 'Útvonal megjelenítése';

  @override
  String get pathMap_collapsePanel => 'Panel összecsukása';

  @override
  String get pathMap_expandPanel => 'Panel kibontása';

  @override
  String get pathMap_noLocation => 'Nincs hely';

  @override
  String get pathMap_followPacket => 'Nézet zárolása a csomaghoz';

  @override
  String get pathMap_unfollowPacket => 'A nézet feloldása a csomagból';
}
