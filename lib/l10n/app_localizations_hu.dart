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
  String get common_cancel => 'Át kell venni';

  @override
  String get common_ok => 'Rendben';

  @override
  String get common_connect => 'Kapcsolódj';

  @override
  String get common_unknownDevice => 'Tudatlan eszköz';

  @override
  String get common_save => 'Mentés';

  @override
  String get common_delete => 'Töröl';

  @override
  String get common_deleteAll => 'Minden törlés';

  @override
  String get common_close => 'Bezárás';

  @override
  String get common_edit => 'Szerkesztés';

  @override
  String get common_add => 'Hozzáad';

  @override
  String get common_settings => 'Beállítások';

  @override
  String get common_disconnect => 'Csatlakozást megszakasztani';

  @override
  String get common_connected => 'Kapcsolódó';

  @override
  String get common_disconnected => 'Elválasztva';

  @override
  String get common_create => 'Készítsd';

  @override
  String get common_continue => 'Folytatás';

  @override
  String get common_share => 'Ossza meg';

  @override
  String get common_copy => 'Másolat';

  @override
  String get common_retry => 'Újrapróbálja';

  @override
  String get common_hide => 'Elrejt';

  @override
  String get common_remove => 'Eltávolít';

  @override
  String get common_enable => 'Engedélyezés';

  @override
  String get common_disable => 'Leteteszt';

  @override
  String get common_reboot => 'Újraindítás';

  @override
  String get common_loading => 'Betöltés...';

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
  String get scanner_title => 'MeshCore nyitott';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP-n keresztül kapcsolódjon';

  @override
  String get tcpHostLabel => 'IP-cím';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Múzeum';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected =>
      'Adja meg a célpontot, majd kapcsolja össze.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Kapcsolat a $endpoint-hez...';
  }

  @override
  String get tcpErrorHostRequired => 'Az IP-címet meg kell adni.';

  @override
  String get tcpErrorPortInvalid => 'Az érték 1 és 65535 között kell lennie.';

  @override
  String get tcpErrorUnsupported =>
      'A TCP-protokoll nem támogatott ez a platformon.';

  @override
  String get tcpErrorTimedOut => 'A TCP-kapcsolat időtúllépett.';

  @override
  String tcpConnectionFailed(String error) {
    return 'A TCP-kapcsolat sikertelen: $error';
  }

  @override
  String get usbScreenTitle => 'USB-en keresztül csatlakoztassuk';

  @override
  String get usbScreenSubtitle =>
      'Válasszon egy azonosított soros eszközt, és közvetlenül csatlakoztassa a MeshCore-hoz.';

  @override
  String get usbScreenStatus => 'Válasszon egy USB-es eszközt';

  @override
  String get usbScreenNote =>
      'Az USB-es soros kommunikáció a támogatott Android eszközökön és asztali rendszereken is elérhető.';

  @override
  String get usbScreenEmptyState =>
      'Nincs USB eszköz megtalálva. Csatlakoztasson egyet, majd frissítse a rendszert.';

  @override
  String get usbErrorPermissionDenied => 'A USB-es hozzáférés megtagadva.';

  @override
  String get usbErrorDeviceMissing =>
      'Az kiválasztott USB eszköz már nem elérhető.';

  @override
  String get usbErrorInvalidPort => 'Válasszon egy érvényes USB-eszközt.';

  @override
  String get usbErrorBusy =>
      'Egy másik USB-csatlakozás kérése már folyamatban van.';

  @override
  String get usbErrorNotConnected => 'Nincs csatlakoztatott USB eszköz.';

  @override
  String get usbErrorOpenFailed =>
      'Nem sikerült megnyitni a kiválasztott USB-eszközöt.';

  @override
  String get usbErrorConnectFailed =>
      'Nem sikerült kapcsolatot létesíteni a kiválasztott USB-eszközhöz.';

  @override
  String get usbErrorUnsupported =>
      'Ez a platform nem támogat USB-es soros kommunikációt.';

  @override
  String get usbErrorAlreadyActive => 'Az USB-kapcsolat már be van állítva.';

  @override
  String get usbErrorNoDeviceSelected => 'Nincs kiválasztva USB eszköz.';

  @override
  String get usbErrorPortClosed => 'Az USB-kapcsolat nem aktív.';

  @override
  String get usbErrorConnectTimedOut =>
      'Kapcsolódás sikertelen. Ellenőrizze, hogy a eszköz rendelkezik-e USB-hez tartozó firmware-rel.';

  @override
  String get usbFallbackDeviceName => 'Web-szériás eszköz';

  @override
  String get usbStatus_notConnected => 'Válasszon egy USB-es eszközt';

  @override
  String get usbStatus_connecting => 'USB eszközhez való csatlakozás...';

  @override
  String get usbStatus_searching => 'USB eszközök keresése...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB-kapcsolat sikertelen: $error';
  }

  @override
  String get scanner_scanning => 'Készülékek keresése...';

  @override
  String get scanner_connecting => 'Kapcsolódás...';

  @override
  String get scanner_disconnecting => 'Kapcsolat megszakad...';

  @override
  String get scanner_notConnected => 'Nem csatlakozva';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Kapcsolódik a $deviceName-hez';
  }

  @override
  String get scanner_searchingDevices => 'MeshCore eszközök keresése...';

  @override
  String get scanner_tapToScan =>
      'A Tap Scan funkció segítségével kereshet MeshCore eszközöket.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Kapcsolódás sikertelen: $error';
  }

  @override
  String get scanner_stop => 'Megállj';

  @override
  String get scanner_scan => 'Szkenálás';

  @override
  String get scanner_bluetoothOff => 'A Bluetooth kikapcsolva';

  @override
  String get scanner_bluetoothOffMessage =>
      'Kérjük, kapcsolja be a Bluetooth-ot, hogy eszközök keresése lehessen.';

  @override
  String get scanner_chromeRequired => 'Chrome böngésző szükséges';

  @override
  String get scanner_chromeRequiredMessage =>
      'Ez az alkalmazás a Bluetooth funkcióhoz Google Chrome-ot vagy Chromium alapú böngészőt igényel.';

  @override
  String get scanner_enableBluetooth => 'Engedje be a Bluetooth funkciót';

  @override
  String get device_quickSwitch => 'Gyors váltás';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Beállítások';

  @override
  String get settings_deviceInfo => 'A készülék információi';

  @override
  String get settings_appSettings => 'Alkalmazási beállítások';

  @override
  String get settings_appSettingsSubtitle =>
      'Értesítések, üzenetküldés és térképi beállítások';

  @override
  String get settings_nodeSettings => 'Műközép beállítások';

  @override
  String get settings_nodeName => 'Vonal neve';

  @override
  String get settings_nodeNameNotSet => 'Nem megállapított';

  @override
  String get settings_nodeNameHint => 'Adja meg a csomópont nevét';

  @override
  String get settings_nodeNameUpdated => 'Neve frissítve';

  @override
  String get settings_radioSettings => 'Rádióbeállítások';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvencia, teljesítmény, szélesítési tényező';

  @override
  String get settings_radioSettingsUpdated => 'A rádió beállítások frissítve';

  @override
  String get settings_location => 'Helyszín';

  @override
  String get settings_locationSubtitle => 'GPS koordináták';

  @override
  String get settings_locationUpdated =>
      'A helyzet és a GPS beállítások frissítve';

  @override
  String get settings_locationBothRequired =>
      'Kérjük, adja meg a földrajzi szélességet és hosszúságot.';

  @override
  String get settings_locationInvalid =>
      'Érvénytelen szélesszög vagy hosszszög.';

  @override
  String get settings_locationGPSEnable => 'GPS engedélyezve';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Lehetővé teszi, hogy a GPS automatikusan frissítse a helyzetet.';

  @override
  String get settings_locationIntervalSec =>
      'GPS-számolási intervallum (másodpercek)';

  @override
  String get settings_locationIntervalInvalid =>
      'Az intervallum legalább 60 másodpercnek, de legfeljebb 86400 másodpercnak kell lennie.';

  @override
  String get settings_latitude => 'Nyugat-–––––––––––––––––––––––––––––––';

  @override
  String get settings_longitude => 'hosszúság';

  @override
  String get settings_contactSettings => 'Kapcsolat beállítások';

  @override
  String get settings_contactSettingsSubtitle =>
      'Beállítások, amelyek meghatározzák, hogyan lehet új kapcsolatokat hozzáadni.';

  @override
  String get settings_privacyMode => 'Adatvédelem mód';

  @override
  String get settings_privacyModeSubtitle =>
      'Elrejtsük a nevét/a helyszínt az űrianyagokban';

  @override
  String get settings_privacyModeToggle =>
      'Engedje be a privát üzemmódot, hogy elrejtse a nevét és a helyét az online hirdetésekben.';

  @override
  String get settings_privacyModeEnabled => 'Adatvédelem mód beállítva';

  @override
  String get settings_privacyModeDisabled => 'Adatvédelem mód kikapcsolva';

  @override
  String get settings_privacy => 'Adatvédelem beállítások';

  @override
  String get settings_privacySubtitle =>
      'Ellenőrizd, hogy milyen információkat osztanak meg.';

  @override
  String get settings_privacySettingsDescription =>
      'Válassza ki, hogy az eszközének melyik információkat oszt meg másokkal.';

  @override
  String get settings_denyAll => 'Elutasítom';

  @override
  String get settings_allowByContact =>
      'Lehetővé teszi a kapcsolatok kezelését';

  @override
  String get settings_allowAll => 'Engedje meg mindent';

  @override
  String get settings_telemetryBaseMode => 'Adatkapcsolati alapállapot';

  @override
  String get settings_telemetryLocationMode => 'Adatkapcsolási helyszín mód';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Adatkapcsolati környezeti mód';

  @override
  String get settings_advertLocation => 'Reklám megjelenési hely';

  @override
  String get settings_advertLocationSubtitle =>
      'A hirdetés tartalmazza a helyszínt.';

  @override
  String settings_multiAck(String value) {
    return 'Többszöri visszaigazolások: $value';
  }

  @override
  String get settings_telemetryModeUpdated => 'A telemetriamód frissítve';

  @override
  String get settings_actions => 'Tevékenységek';

  @override
  String get settings_sendAdvertisement => 'Hirdetés küldése';

  @override
  String get settings_sendAdvertisementSubtitle => 'A nyilvános megjelenés';

  @override
  String get settings_advertisementSent => 'Hirdetés elküldve';

  @override
  String get settings_syncTime => 'Szinkronizációs idő';

  @override
  String get settings_syncTimeSubtitle =>
      'Állítsa a készülék időzítését a telefon időjére';

  @override
  String get settings_timeSynchronized => 'Időben szinkronizált';

  @override
  String get settings_refreshContacts => 'Újraindítsd a kapcsolatok listát';

  @override
  String get settings_refreshContactsSubtitle =>
      'Újra töltse a kontaktlista-adatokat a készülékről';

  @override
  String get settings_rebootDevice => 'Újraindítás';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Indítsa újra a MeshCore eszközt.';

  @override
  String get settings_rebootDeviceConfirm =>
      'Biztosan szeretné újraindítani a készüléket? Ebben az esetben a kapcsolat megszűnik.';

  @override
  String get settings_debug => 'Hibakeresés';

  @override
  String get settings_bleDebugLog => 'BLE hibaelhárítási napló';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE parancsok, válaszok és alapvető adatok';

  @override
  String get settings_appDebugLog => 'App-debug log';

  @override
  String get settings_appDebugLogSubtitle => 'Programozási hibajelzések';

  @override
  String get settings_about => 'Ról';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open $version verzió';
  }

  @override
  String get settings_aboutLegalese =>
      '2026-os MeshCore nyílt forráskódú projekt';

  @override
  String get settings_aboutDescription =>
      'Egy nyílt forráskódú Flutter kliens a MeshCore LoRa hálózati eszközök számára.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS magassági adatok: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Név';

  @override
  String get settings_infoId => 'Az azonosító';

  @override
  String get settings_infoStatus => 'Állapot';

  @override
  String get settings_infoBattery => 'Akku';

  @override
  String get settings_infoPublicKey => 'Nyelvkönyv';

  @override
  String get settings_infoContactsCount => 'Kapcsolatok száma';

  @override
  String get settings_infoChannelCount => 'Csatorna száma';

  @override
  String get settings_presets => 'Előre beállított beállítások';

  @override
  String get settings_frequency => 'Frekvencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 – 2500,0';

  @override
  String get settings_frequencyInvalid =>
      'Érvénytelen frekvencia (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Kapacitás';

  @override
  String get settings_spreadingFactor => 'Terjesztési tényező';

  @override
  String get settings_codingRate => 'Kódolási sebesség';

  @override
  String get settings_txPower => 'TX teljesítmény (dBm)';

  @override
  String get settings_txPowerHelper => '0 – 22';

  @override
  String get settings_txPowerInvalid =>
      'Érvénytelen TX teljesítmény (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Autonóm rendszer újra';

  @override
  String get settings_clientRepeatSubtitle =>
      'Engedje, hogy ez a eszköz mások számára is ismételje a hálózati csomagokat.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'A hálózat nélküli kommunikációhoz 433, 869 vagy 918 MHz frekvenciát igényel.';

  @override
  String settings_error(String message) {
    return 'Hiba: $message';
  }

  @override
  String get appSettings_title => 'Alkalmazási beállítások';

  @override
  String get appSettings_appearance => 'Megjelenés';

  @override
  String get appSettings_theme => 'Téma';

  @override
  String get appSettings_themeSystem => 'Alapértékek';

  @override
  String get appSettings_themeLight => 'Világítás';

  @override
  String get appSettings_themeDark => 'Sötét';

  @override
  String get appSettings_language => 'Nyelv';

  @override
  String get appSettings_languageSystem => 'Alapértékek';

  @override
  String get appSettings_languageEn => 'Angol';

  @override
  String get appSettings_languageFr => 'Francia';

  @override
  String get appSettings_languageEs => 'Spanyol';

  @override
  String get appSettings_languageDe => 'Német';

  @override
  String get appSettings_languagePl => 'Lengyel';

  @override
  String get appSettings_languageSl => 'szlovén nyelv';

  @override
  String get appSettings_languagePt => 'Portugál';

  @override
  String get appSettings_languageIt => 'Olasz';

  @override
  String get appSettings_languageZh => 'Kínai';

  @override
  String get appSettings_languageSv => 'Svéd';

  @override
  String get appSettings_languageNl => 'Hollandi';

  @override
  String get appSettings_languageSk => 'Szlovén nyelvre fordítás';

  @override
  String get appSettings_languageBg => 'Bulgár';

  @override
  String get appSettings_languageRu => 'Orosz';

  @override
  String get appSettings_languageUk => 'Украинский';

  @override
  String get appSettings_enableMessageTracing =>
      'Engedje meg a üzenetek nyomon követését';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Adja meg a üzenetek részletes útvonal- és időzítési adatokat.';

  @override
  String get appSettings_notifications => 'Értesítések';

  @override
  String get appSettings_enableNotifications => 'Engedélyezze az értesítéseket';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Kapjon értesítéseket üzenetekről és hirdetésekről.';

  @override
  String get appSettings_notificationPermissionDenied =>
      'A értesítési engedély megtagadva';

  @override
  String get appSettings_notificationsEnabled =>
      'A figyelmeztetések engedélyezve';

  @override
  String get appSettings_notificationsDisabled =>
      'A figyelmeztetések kikapcsolva';

  @override
  String get appSettings_messageNotifications => 'Üzenet értesítések';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'A figyelmeztetést megjelenítve, amikor új üzenet érkezik';

  @override
  String get appSettings_channelMessageNotifications =>
      'Csatorna-üzenetek értesítése';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'A figyelmeztetést megjelenítve, amikor új üzenet érkezik a csatornáról';

  @override
  String get appSettings_advertisementNotifications => 'Reklám értesítések';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'A figyelmeztetést megjelenítve, amikor új csomópontok kerülnek felfedezésre.';

  @override
  String get appSettings_messaging => 'Üzenetek küldése';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Egyértelmű út a Max Retry funkció használatával';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'A kapcsolat visszaállítás 5 sikertelen továbbítás után';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Ha 5-szer sikertelenül próbálunk, a útvonalat automatikusan tisztítjuk.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'A utak automatikusan nem tisztítódnak.';

  @override
  String get appSettings_autoRouteRotation => 'Autóútok forgása';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Válasszon a legjobb útvonalak között, vagy válassza a vízözön-módot.';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Az automatikus útvonalváltás engedélyezve';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Az automatikus útvonal-választás funkció kikapcsolva.';

  @override
  String get appSettings_maxRouteWeight => 'Maximális útvonal súly';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'A lehető legnagyobb súly, amit egy útvonal sikeres szállítmányok során összegyűjthet.';

  @override
  String get appSettings_initialRouteWeight => 'A kezdeti útvonal súlya';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Az új, felfedezett útvonalakhoz tartozó kezdeti súly';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Sikerhez vezető növelés';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'A sikeresen teljesített útvonalhoz hozzáadott súly.';

  @override
  String get appSettings_routeWeightFailureDecrement => 'Hibás súly csökkenése';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'A jártatásból eltávolított súly, ami a sikertelen szállítás következménye.';

  @override
  String get appSettings_maxMessageRetries =>
      'Maximális üzenetek újraküldési próbálkozások';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'A próbálkozások száma, mielőtt egy üzenetet hibásnak jelölünk.';

  @override
  String path_routeWeight(String weight, String max) {
    return '$weight/$max';
  }

  @override
  String get appSettings_battery => 'Akku';

  @override
  String get appSettings_batteryChemistry => 'Aakkum töltés kémia';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Beállítások $deviceName-hez';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Csatlakozzon egy eszközhez, hogy kiválassza';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2 V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2 V)';

  @override
  String get appSettings_mapDisplay => 'Térkép megjelenítése';

  @override
  String get appSettings_showRepeaters => 'Megismétlés';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'A térképen megjelenítsük a repeater-eket.';

  @override
  String get appSettings_showChatNodes => 'Megjeleníts kommunikációs pontokat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'A chat-szobákat megjelenítsük a térképen';

  @override
  String get appSettings_showOtherNodes => 'Mutasson további csomópontokat';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mutassa meg a többi hálózati elemet a térképen';

  @override
  String get appSettings_timeFilter => 'Időbeli szűrés';

  @override
  String get appSettings_timeFilterShowAll =>
      'Mutassa meg az összes csomópontot';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mutasson az utolsó $hours órából származó adatokat.';
  }

  @override
  String get appSettings_mapTimeFilter => 'Térkép időszűrő';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Megjeleníts olyan węzveket, amelyek a következő területen lettek felfedezve:';

  @override
  String get appSettings_allTime => 'Minden időpont';

  @override
  String get appSettings_lastHour => 'Az utolsó óra';

  @override
  String get appSettings_last6Hours => 'Az utóban 6 óra';

  @override
  String get appSettings_last24Hours => 'Az utóbbi 24 óra';

  @override
  String get appSettings_lastWeek => 'A múlt héten';

  @override
  String get appSettings_offlineMapCache => 'Offline térkép tárolás';

  @override
  String get appSettings_unitsTitle => 'Egységek';

  @override
  String get appSettings_unitsMetric => 'Méter (m / kilométer)';

  @override
  String get appSettings_unitsImperial => 'Királyi (láb / mérföld)';

  @override
  String get appSettings_noAreaSelected => 'Nincs kiválasztott terület.';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Kiválasztott terület (zoom: $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Hibakeresés';

  @override
  String get appSettings_appDebugLogging =>
      'App-ban történő hibakereséshez használt naplózás';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Log alkalmazás hibaelhárítási üzenetek';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Az alkalmazás hibaelhárítási naplózás engedélyezve';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Az alkalmazás hibaelhárítási naplózatának bekapcsolása kiküszöbölve';

  @override
  String get contacts_title => 'Kapcsolatok';

  @override
  String get contacts_noContacts => 'Jelenleg még nincs kapcsolat.';

  @override
  String get contacts_contactsWillAppear =>
      'A kapcsolatok megjelennek, amikor a eszközök hirdetnek.';

  @override
  String get contacts_unread => 'Olvasatlan';

  @override
  String get contacts_searchContactsNoNumber => 'Kapcsolatok keresése...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Keresés $number-ban $str…';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Keresés $number$str... Kedvencek';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Search $number$str Users...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Keresés $number-on, $str típusú adóállomások között...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Keresés $number-ban $str...';
  }

  @override
  String get contacts_noUnreadContacts => 'Nincs olvasatlan üzenetek';

  @override
  String get contacts_noContactsFound =>
      'Nincs megtalálva semmilyen kapcsolat vagy csoport.';

  @override
  String get contacts_deleteContact => 'Kapcsolattól töröl';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Hogy töröljem a $contactName nevű személyt a kontaktlistából?';
  }

  @override
  String get contacts_manageRepeater => 'Ellenőriző eszköz kezelése';

  @override
  String get contacts_manageRoom => 'A szobai szerver kezelése';

  @override
  String get contacts_roomLogin => 'Szoba szerverbe való bejelentkezés';

  @override
  String get contacts_openChat => 'Nyitott beszélgetés';

  @override
  String get contacts_editGroup => 'Edit csoport';

  @override
  String get contacts_deleteGroup => 'Csoport törlése';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Hogy töröljem a \"$groupName\"-t?';
  }

  @override
  String get contacts_newGroup => 'Új csoport';

  @override
  String get contacts_groupName => 'Csoport neve';

  @override
  String get contacts_groupNameRequired =>
      'A csoportnak meg kell adni a nevét.';

  @override
  String get contacts_groupNameReserved => 'Ez a csoportnév foglalt';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'A \"$name\" nevű csoport már létezik.';
  }

  @override
  String get contacts_filterContacts => 'Szűrj kontaktokat...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Nincs találat a megadott szűrés alapján.';

  @override
  String get contacts_noMembers => 'Nincsenek tagok';

  @override
  String get contacts_lastSeenNow => 'utóbbi időben';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes perc';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Kb. 1 óra';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours óra';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Kb. 1 nap';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days days';
  }

  @override
  String get contact_info => 'Kapcsolattartási információk';

  @override
  String get contact_settings => 'Kapcsolat beállítások';

  @override
  String get contact_telemetry => 'Adatvisszaadás';

  @override
  String get contact_lastSeen => 'Utoljára, amikor látták';

  @override
  String get contact_clearChat => 'Tiszta beszélgetés';

  @override
  String get contact_teleBase => 'Adatgyűjtő központ';

  @override
  String get contact_teleBaseSubtitle =>
      'Engedje meg a akkumulátor töltöttségi szintjének és alapvető adatoknak megosztását.';

  @override
  String get contact_teleLoc => 'Adatkapcsolati helyszín';

  @override
  String get contact_teleLocSubtitle => 'Engedje meg a helyadatok megosztását';

  @override
  String get contact_teleEnv => 'Adatkapcsolati környezet';

  @override
  String get contact_teleEnvSubtitle =>
      'Engedje meg az érzékelő adatok megosztását';

  @override
  String get channels_title => 'Csatornák';

  @override
  String get channels_noChannelsConfigured => 'Nincs konfigurált csatorna.';

  @override
  String get channels_addPublicChannel => 'Hozzon létre nyilvános csatornát';

  @override
  String get channels_searchChannels => 'Keresési opciók...';

  @override
  String get channels_noChannelsFound => 'Nincs megtalálható csatorna';

  @override
  String channels_channelIndex(int index) {
    return '$index-os csatorna';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag-ok közössége';

  @override
  String get channels_public => 'A nyilvánosság számára';

  @override
  String get channels_private => 'Személyes';

  @override
  String get channels_publicChannel => 'Össztávos csatorna';

  @override
  String get channels_privateChannel => 'Személyes csatorna';

  @override
  String get channels_editChannel => 'Csatorna szerkesztése';

  @override
  String get channels_muteChannel => 'Csendes csatorna';

  @override
  String get channels_unmuteChannel => 'Engedje be a hangot';

  @override
  String get channels_deleteChannel => 'Mozdony törlése';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Törlés $name? Ez nem visszafordítható.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Nem sikerült törölni a \"$name\" nevű csatornát.';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'A \"$name\" nevű csatorna törölve';
  }

  @override
  String get channels_addChannel => 'Csatorna hozzáadása';

  @override
  String get channels_channelIndexLabel => 'Csatorna index';

  @override
  String get channels_channelName => 'Csatorna neve';

  @override
  String get channels_usePublicChannel => 'Használja a nyilvános csatornát';

  @override
  String get channels_standardPublicPsk =>
      'Általános, állami által finanszírozott PSK';

  @override
  String get channels_pskHex => 'PSK (Hexadecimális kód)';

  @override
  String get channels_generateRandomPsk => 'Véletlenszerűen generáljon PSK-t';

  @override
  String get channels_enterChannelName => 'Kérjük, adja meg egy csatorna nevét';

  @override
  String get channels_pskMustBe32Hex =>
      'A PSK 32-bázisú hexadecimális karakterből áll.';

  @override
  String channels_channelAdded(String name) {
    return 'A \"$name\" csatorna hozzáadva';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Módosítsd a csatornát $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ kompresszió';

  @override
  String channels_channelUpdated(String name) {
    return 'A $name csatorna frissítve';
  }

  @override
  String get channels_publicChannelAdded => 'A nyilvános csatorna hozzáadva';

  @override
  String get channels_sortBy => 'Szűrés';

  @override
  String get channels_sortManual => 'Használati útmutató';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Legfrissebb üzenetek';

  @override
  String get channels_sortUnread => 'Olvasatlan';

  @override
  String get channels_createPrivateChannel => 'Létrehoz egy privát csatornát';

  @override
  String get channels_createPrivateChannelDesc =>
      'Titkos kulcs segítségével védelem.';

  @override
  String get channels_joinPrivateChannel =>
      'Csatlakozzon egy privát csatornához';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Kézzel adja meg a titkos kulcsot.';

  @override
  String get channels_joinPublicChannel =>
      'Csatlakozzon a nyilvános csatornához';

  @override
  String get channels_joinPublicChannelDesc =>
      'Bárki csatlakozhat ehhez a csatornához.';

  @override
  String get channels_joinHashtagChannel =>
      'Csatlakozzon egy hashtage-os csatornához';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Bárkinek lehet csatlakoznia a hashtagekhez tartozó csatornához.';

  @override
  String get channels_scanQrCode => 'Scanned egy QR-kódot';

  @override
  String get channels_scanQrCodeComingSoon => 'Hamarosan';

  @override
  String get channels_enterHashtag => 'Írja be a hashtaget';

  @override
  String get channels_hashtagHint => 'pl. #csapat';

  @override
  String get chat_noMessages => 'Még nincs üzenet.';

  @override
  String get chat_sendMessageToStart => 'Küldj egy üzenetet, hogy elindulj!';

  @override
  String get chat_originalMessageNotFound => 'A eredeti üzenet nem található.';

  @override
  String chat_replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get chat_location => 'Helyszín';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Küldj üzenetet $contactName-nek';
  }

  @override
  String get chat_typeMessage => 'Írjon üzenetet...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'A üzenet túl hosszú (a maximális $maxBytes bájt).';
  }

  @override
  String get chat_messageCopied => 'Üzenet másolva';

  @override
  String get chat_messageDeleted => 'Üzenet törölve';

  @override
  String get chat_retryingMessage => 'Újrapróbálási üzenet';

  @override
  String chat_retryCount(int current, int max) {
    return 'Újrapróbál $current/$max';
  }

  @override
  String get chat_sendGif => 'Küldj GIF-ot';

  @override
  String get chat_reply => 'Válasz';

  @override
  String get chat_addReaction => 'Hozzon létre reakciót';

  @override
  String get chat_me => 'Én';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Testmozgások';

  @override
  String get emojiCategoryHearts => 'Szívak';

  @override
  String get emojiCategoryObjects => 'Tárgyak';

  @override
  String get gifPicker_title => 'Válasszon egy GIF-et';

  @override
  String get gifPicker_searchHint => 'GIF-ek keresése...';

  @override
  String get gifPicker_poweredBy => 'Forrás: GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nincsenek GIF-ek megtalálva.';

  @override
  String get gifPicker_failedLoad => 'Nem sikerült betölteni a GIF-fájlokat.';

  @override
  String get gifPicker_failedSearch => 'Nem sikerült a GIF-eket megtalálni.';

  @override
  String get gifPicker_noInternet => 'Nincs internetkapcsolat.';

  @override
  String get debugLog_appTitle => 'App-debug log';

  @override
  String get debugLog_bleTitle => 'BLE hibajelentő napló';

  @override
  String get debugLog_copyLog => 'Másolat napló';

  @override
  String get debugLog_clearLog => 'Jelzett napló';

  @override
  String get debugLog_copied => 'Hibajelentő napló másolva';

  @override
  String get debugLog_bleCopied => 'BLE-log másolva';

  @override
  String get debugLog_noEntries =>
      'Jelenleg még nem léteznek hibaelhárítási naplókat.';

  @override
  String get debugLog_enableInSettings =>
      'Engedje be az alkalmazás hibaelhárítási naplózását a beállítások menüben.';

  @override
  String get debugLog_frames => 'Keretek';

  @override
  String get debugLog_rawLogRx => 'Az eredeti Log-RX';

  @override
  String get debugLog_noBleActivity =>
      'Jelenleg nincs BLE-hez kapcsolódó tevékenység.';

  @override
  String debugFrame_length(int count) {
    return 'Keret hossza: $count bájt';
  }

  @override
  String debugFrame_command(String value) {
    return 'Parancs: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Címzett:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Célhely: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Időbélyeg: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Jelvények: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tartalom típusa: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'Parancssori felület (CLI)';

  @override
  String get debugFrame_textTypePlain => 'Egyszerű, alap, hagyományos';

  @override
  String debugFrame_text(String text) {
    return '- Tartalom: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex-dump:';

  @override
  String get chat_pathManagement => 'Útvonal-kezelés';

  @override
  String get chat_ShowAllPaths => 'Mutasson meg minden útvonalat';

  @override
  String get chat_routingMode => 'Útvonal-kezelési mód';

  @override
  String get chat_autoUseSavedPath =>
      'Automatikus (az eddigi útvonal használata)';

  @override
  String get chat_forceFloodMode => 'Erőforrás-alapú áramlás mód';

  @override
  String get chat_recentAckPaths =>
      'Legutóbbi használt útvonalak (gombra kattintva):';

  @override
  String get chat_pathHistoryFull =>
      'Az előző lépések listája teljes. Törölj ki a bejegyzéseket, hogy újokat hozzáadhatsd.';

  @override
  String get chat_hopSingular => 'ugor';

  @override
  String get chat_hopPlural => 'babér';

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
  String get chat_successes => 'sikerek';

  @override
  String get chat_removePath => 'Törölje a elérési útvonalat';

  @override
  String get chat_noPathHistoryYet =>
      'Még nincs útvonal-történet.\nKüldjön egy üzenetet, hogy megtudja a lehetséges útvonalakat.';

  @override
  String get chat_pathActions => 'Céltúrások:';

  @override
  String get chat_setCustomPath => 'Beállítsd a saját útvonalat';

  @override
  String get chat_setCustomPathSubtitle => 'Kézzel megadott útvonal';

  @override
  String get chat_clearPath => 'Egyértelmű út';

  @override
  String get chat_clearPathSubtitle =>
      'A parancs új küldéskor újra kell aktivizálnia.';

  @override
  String get chat_pathCleared =>
      'Útvonal cleared. A következő üzenet újból feltérképezheti az útvonalat.';

  @override
  String get chat_floodModeSubtitle =>
      'Használja a \"útvonal\" kapcsolót az alkalmazás sávjában.';

  @override
  String get chat_floodModeEnabled =>
      'Árvízvédelmi mód bekapcsolva. A visszaállítás a alkalmazásban található útvonal ikon segítségével.';

  @override
  String get chat_fullPath => 'Teljes elérési út';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Az útvonal részletei még nem elérhetők. Próbálja meg küldeni egy üzenetet, hogy frissítse az információkat.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Path set: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Helyileg mentve. Kapcsolódjon a szinkronizáláshoz.';

  @override
  String get chat_pathDeviceConfirmed => 'A készülék megvan.';

  @override
  String get chat_pathDeviceNotConfirmed => 'A készülék még nem bizonyított.';

  @override
  String get chat_type => 'Típus';

  @override
  String get chat_path => 'Út';

  @override
  String get chat_publicKey => 'Nyelvkönyv';

  @override
  String get chat_compressOutgoingMessages => 'A küldött üzenetek tömörítése';

  @override
  String get chat_floodForced => 'Áradás (kényszerített)';

  @override
  String get chat_directForced => 'Közvetlen (erélyes)';

  @override
  String chat_hopsForced(int count) {
    return '$count ánusz (erővel)';
  }

  @override
  String get chat_floodAuto => 'Vízosztás (autó)';

  @override
  String get chat_direct => 'Közvetlen';

  @override
  String get chat_poiShared => 'Közös erőforrás';

  @override
  String chat_unread(int count) {
    return 'Olvasatlan: $count';
  }

  @override
  String get chat_openLink => 'Nyisd meg a linket?';

  @override
  String get chat_openLinkConfirmation =>
      'Szeretnéd megnyitni ezt a linket a böngésződben?';

  @override
  String get chat_open => 'Nyitott';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Nem sikerült megnyitni a hivat: $url';
  }

  @override
  String get chat_invalidLink => 'Érvénytelen hivatkozás formátum';

  @override
  String get map_title => 'Grafikus ábrázás';

  @override
  String get map_lineOfSight => 'Látási vonal';

  @override
  String get map_losScreenTitle => 'Látási vonal';

  @override
  String get map_noNodesWithLocation =>
      'Nincs olyan adatpont, amelyhez helyszín-információk tartoznak.';

  @override
  String get map_nodesNeedGps =>
      'A pontoknak meg kell osztaniuk GPS koordinátáikat, hogy megjelenjenek a térképen.';

  @override
  String map_nodesCount(int count) {
    return 'Csúcsok: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Csapok: $count';
  }

  @override
  String get map_chat => 'Csevegés';

  @override
  String get map_repeater => 'Ismétlő';

  @override
  String get map_room => 'szoba';

  @override
  String get map_sensor => 'Érzékelő';

  @override
  String get map_pinDm => 'Jel (DM)';

  @override
  String get map_pinPrivate => 'Titkos (privát)';

  @override
  String get map_pinPublic => 'Jelmez (nyilvános)';

  @override
  String get map_lastSeen => 'Utoljára látva';

  @override
  String get map_disconnectConfirm =>
      'Biztosan szeretné kiírni ezt a készüléket?';

  @override
  String get map_from => 'Attól';

  @override
  String get map_source => 'Forrás';

  @override
  String get map_flags => 'Zászló';

  @override
  String get map_shareMarkerHere => 'Osztja ezt a tartalmat itt';

  @override
  String get map_setAsMyLocation => 'Állítsa be a jelenlegi helyzetemként';

  @override
  String get map_pinLabel => 'Címkét ragasztani';

  @override
  String get map_label => 'Címke';

  @override
  String get map_pointOfInterest => 'Érdekes hely';

  @override
  String get map_sendToContact => 'Kapcsolatfelvételi űrlap';

  @override
  String get map_sendToChannel => 'Küldés a csatornán';

  @override
  String get map_noChannelsAvailable => 'Nincs elérhető csatorna.';

  @override
  String get map_publicLocationShare => 'Térköz, nyilvános hely';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Most egy helyszínt megosztasz a $channelLabel csatornán. Ez a csatorna nyilvános, és bárki, aki rendelkezik a PSK-val, megtekintheti.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Kapcsolódjon egy eszközhöz, hogy megoszthassa a vonalzókat.';

  @override
  String get map_filterNodes => 'Szűrési pontok';

  @override
  String get map_nodeTypes => 'Vonalak típusai';

  @override
  String get map_chatNodes => 'Csevegési pontok';

  @override
  String get map_repeaters => 'Újraküldők';

  @override
  String get map_otherNodes => 'Egyéb csomópontok';

  @override
  String get map_showOverlaps => 'Az ismétlő kulcsok ütköznek';

  @override
  String get map_keyPrefix => 'Kulcsfontosságú előtag';

  @override
  String get map_filterByKeyPrefix => 'Szűrj a kulcsos előtér szerint';

  @override
  String get map_publicKeyPrefix => 'Névfelhasználó kulc-prefix';

  @override
  String get map_markers => 'Jelölők';

  @override
  String get map_showSharedMarkers => 'Mutassa meg a közös jeleket';

  @override
  String get map_showGuessedLocations =>
      'Megjelenítsa a megjósolt csomópontok helyét';

  @override
  String get map_showDiscoveryContacts =>
      'Megjelenítse a Discovery-nál elérhet kontaktokat';

  @override
  String get map_guessedLocation => 'Tippolt hely';

  @override
  String get map_lastSeenTime => 'Utoljára megjelent idő';

  @override
  String get map_sharedPin => 'Gemeinsames PIN-kód';

  @override
  String get map_joinRoom => 'Csatlakozás a szobához';

  @override
  String get map_manageRepeater => 'Ellenőriző eszköz kezelése';

  @override
  String get map_tapToAdd =>
      'Nyomj meg a csomópontokhoz, hogy hozzáadd őket az útvonalhoz.';

  @override
  String get map_runTrace => 'Útvonal követés';

  @override
  String get map_runTraceWithReturnPath => 'Visszaforduljon az eredeti úton.';

  @override
  String get map_removeLast => 'Törölj utolsó';

  @override
  String get map_pathTraceCancelled => 'Az útvonal követés megszakadt.';

  @override
  String get mapCache_title => 'Offline térkép tárolás';

  @override
  String get mapCache_selectAreaFirst =>
      'Válasszon egy területet, amelyet először cache-oljon.';

  @override
  String get mapCache_noTilesToDownload =>
      'Nincsenek letölthető tile-ok ebben a területben.';

  @override
  String get mapCache_downloadTilesTitle => 'Letöltsd a tile-okat';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Töltse le $count darab tile-t offline használatra?';
  }

  @override
  String get mapCache_downloadAction => 'Letöltés';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Tárolt $count darab';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Cached $downloaded tiles ($failed failed)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Tiszta offline tárhely';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Távolítsa el az összes tárolt térképmegjelenítőt?';

  @override
  String get mapCache_offlineCacheCleared => 'A helyi memóriát töröltük.';

  @override
  String get mapCache_noAreaSelected => 'Nincs kiválasztott terület.';

  @override
  String get mapCache_cacheArea => 'Tároló terület';

  @override
  String get mapCache_useCurrentView => 'Használja a jelenlegi nézetet';

  @override
  String get mapCache_zoomRange => 'Zoom tartomány';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Becsült kerámiák: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Letöltve $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Letöltsd a tile-okat';

  @override
  String get mapCache_clearCacheButton => 'Ósztótt adatokat';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Sikertelen letöltések: $count';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'N $north, S $south, E $east, W $west';
  }

  @override
  String get time_justNow => 'Most';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes perckel ezelőtt';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours óva';
  }

  @override
  String time_daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get time_hour => 'óra';

  @override
  String get time_hours => 'órák';

  @override
  String get time_day => 'nap';

  @override
  String get time_days => 'napok';

  @override
  String get time_week => 'het';

  @override
  String get time_weeks => 'het, hetek';

  @override
  String get time_month => 'hónap';

  @override
  String get time_months => 'hónapok';

  @override
  String get time_minutes => 'percek';

  @override
  String get time_allTime => 'Bármely időpont';

  @override
  String get dialog_disconnect => 'Csatlakozást megszakasztani';

  @override
  String get dialog_disconnectConfirm =>
      'Biztosan szeretné kiírni ezt a készüléket?';

  @override
  String get login_repeaterLogin => 'Ismételt bejelentkezés';

  @override
  String get login_roomLogin => 'Szoba szerverbe való bejelentkezés';

  @override
  String get login_password => 'Jelszó';

  @override
  String get login_enterPassword => 'Adja meg a jelszót';

  @override
  String get login_savePassword => 'Mentse el a jelszót';

  @override
  String get login_savePasswordSubtitle =>
      'A jelszó biztonságosan tárolódik ezen a készüléken.';

  @override
  String get login_repeaterDescription =>
      'Adja meg a repeater (ismétítő) jelszót, hogy hozzáférhessen a beállításokhoz és az állapot információkhoz.';

  @override
  String get login_roomDescription =>
      'Adja meg a belépési kódot, hogy hozzáférhessen a beállításokhoz és az állapot információkhoz.';

  @override
  String get login_routing => 'Útvonal meghatározás';

  @override
  String get login_routingMode => 'Útvonal-kezelési mód';

  @override
  String get login_autoUseSavedPath =>
      'Automatikus (az eddigi útvonal használata)';

  @override
  String get login_forceFloodMode => 'Erőforrás-alapú áramlás mód';

  @override
  String get login_managePaths => 'Útvonalak kezelése';

  @override
  String get login_login => 'Bejelentkezés';

  @override
  String login_attempt(int current, int max) {
    return 'Megpróbálás $current/$max-adik';
  }

  @override
  String login_failed(String error) {
    return 'Belépés sikertelen: $error';
  }

  @override
  String get login_failedMessage =>
      'Belépés sikertelen. Vagy a jelszó helytelen, vagy a hálózati kapcsolat nem létesül.';

  @override
  String get common_reload => 'Újra töltés';

  @override
  String get common_clear => 'Egyértelmű';

  @override
  String path_currentPath(String path) {
    return 'Jelenlegi útvonal: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ugrások',
      one: 'ugrás',
    );
    return '$count $_temp0 útvonal használata';
  }

  @override
  String get path_enterCustomPath => 'Adja meg a saját elérési útvonalat';

  @override
  String get path_currentPathLabel => 'Jelenlegi útvonal';

  @override
  String get path_hexPrefixInstructions =>
      'Adja meg a 2 karakteres hexadecimális előtagokat minden lépéshez, tagolva kommával.';

  @override
  String get path_hexPrefixExample =>
      'Példa: A1, F2, 3C (minden csomó az első részét használja a nyilvános kulcsából)';

  @override
  String get path_labelHexPrefixes => 'Út (hex-prefixek)';

  @override
  String get path_helperMaxHops =>
      'A maximális hossz 64 karakter. Minden előző rész 2 hatos számjegyből áll (1 bájt).';

  @override
  String get path_selectFromContacts =>
      'Válasszon a kontaktlista elembek közül:';

  @override
  String get path_noRepeatersFound =>
      'Nincs megtalálva semmilyen ismétlődő vagy helyiség-szolgáltató szervert.';

  @override
  String get path_customPathsRequire =>
      'Az egyedi útvonalaknak szükségük van átjáró pontokra, amelyek képesek üzeneteket továbbítani.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Érvénytelen hexadecimális előtagok: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Az út túl hosszú. A maximális engedélyezett lépések száma 64.';

  @override
  String get path_setPath => 'Útvonal meghatározása';

  @override
  String get repeater_management => 'Adatkapcsolás kezelése';

  @override
  String get room_management => 'Szoba-szerver kezelés';

  @override
  String get repeater_managementTools => 'Menedzsmentes eszközök';

  @override
  String get repeater_status => 'Állapot';

  @override
  String get repeater_statusSubtitle =>
      'Megtekintheted a repeater állapotát, statisztikáit és a környező eszközök adatait.';

  @override
  String get repeater_telemetry => 'Adatvisszaadás';

  @override
  String get repeater_telemetrySubtitle =>
      'Tekintsük a szenzorok és a rendszer állapotának adatát';

  @override
  String get repeater_cli => 'Parancssori felület (CLI)';

  @override
  String get repeater_cliSubtitle => 'Küldj parancsokat a repeaternek.';

  @override
  String get repeater_neighbors => 'Szomszédok';

  @override
  String get repeater_neighborsSubtitle =>
      'Tekintsük a nullás lépésű szomszédokat.';

  @override
  String get repeater_settings => 'Beállítások';

  @override
  String get repeater_settingsSubtitle => 'Állítsa be a repeater paramétereket';

  @override
  String get repeater_statusTitle => 'Adatkapcsolódás állapot';

  @override
  String get repeater_routingMode => 'Útvonal-kezelési mód';

  @override
  String get repeater_autoUseSavedPath =>
      'Automatikus (az eddigi útvonal használata)';

  @override
  String get repeater_forceFloodMode => 'Erőforrás-alapú áramlás mód';

  @override
  String get repeater_pathManagement => 'Útvonal-kezelés';

  @override
  String get repeater_refresh => 'Újrafriszol';

  @override
  String get repeater_statusRequestTimeout => 'Az állapotkérés időtúlt.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Hiba a státusz betöltés közben: $error';
  }

  @override
  String get repeater_systemInformation => 'Rendszerinformációk';

  @override
  String get repeater_battery => 'Akku';

  @override
  String get repeater_clockAtLogin => 'Óra (bejelentkezéskor)';

  @override
  String get repeater_uptime => 'A rendszer elérhetősége';

  @override
  String get repeater_queueLength => 'Várakozási sor hossza';

  @override
  String get repeater_debugFlags => 'Hibakeresési beállítások';

  @override
  String get repeater_radioStatistics => 'Rádió statisztika';

  @override
  String get repeater_lastRssi => 'Utolsó RSSI érték';

  @override
  String get repeater_lastSnr => 'Utolsó SNR';

  @override
  String get repeater_noiseFloor => 'Háttérzaj szint';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Csomagok statisztikája';

  @override
  String get repeater_sent => 'Elküldve';

  @override
  String get repeater_received => 'Megérkezett';

  @override
  String get repeater_duplicates => 'Duplák';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days days ${hours}h ${minutes}m ${seconds}s';
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
    return 'Áradás: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Összesen: $total';
  }

  @override
  String get repeater_settingsTitle => 'Adatátvisszaadási beállítások';

  @override
  String get repeater_basicSettings => 'Alapbeállítások';

  @override
  String get repeater_repeaterName => 'Adóállomás neve';

  @override
  String get repeater_repeaterNameHelper => 'Ez a repeater neve';

  @override
  String get repeater_adminPassword => 'Adminisztrátori jelszó';

  @override
  String get repeater_adminPasswordHelper => 'Teljes jogosultságú jelszó';

  @override
  String get repeater_guestPassword => 'Vendég felhasználói név/jelszó';

  @override
  String get repeater_guestPasswordHelper =>
      'Csak olvasási jogosítást biztosító jelszó';

  @override
  String get repeater_radioSettings => 'Rádióbeállítások';

  @override
  String get repeater_frequencyMhz => 'Frekvencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300–2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Adatkapacitás';

  @override
  String get repeater_spreadingFactor => 'Terjesztési tényező';

  @override
  String get repeater_codingRate => 'Kódolási sebesség';

  @override
  String get repeater_locationSettings => 'Helyszínbeállítások';

  @override
  String get repeater_latitude => 'Nyugat–keleti szélesség';

  @override
  String get repeater_latitudeHelper => 'Desztes fokok (pl. 37,7749)';

  @override
  String get repeater_longitude => 'hosszúság';

  @override
  String get repeater_longitudeHelper => 'Desztes fokok (pl. -122.4194)';

  @override
  String get repeater_features => 'Jellemzők';

  @override
  String get repeater_packetForwarding => 'Csomagok továbbítás';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Engedje, hogy a repeater továbbítsa a csomagokat.';

  @override
  String get repeater_guestAccess => 'Vendégek számára elérhető';

  @override
  String get repeater_guestAccessSubtitle =>
      'Engedje meg a vendégek számára, hogy csak olvassák a tartalmat';

  @override
  String get repeater_privacyMode => 'Adatvédelem mód';

  @override
  String get repeater_privacyModeSubtitle =>
      'Elrejtse a nevét/a helyszínt az űrlapon';

  @override
  String get repeater_advertisementSettings => 'Reklámbeállítások';

  @override
  String get repeater_localAdvertInterval => 'Helyi hirdetés időtartama';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes perc';
  }

  @override
  String get repeater_floodAdvertInterval => 'Vízosztály-hirdetés időtartama';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours óra';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Kódolt hirdetés-szünet';

  @override
  String get repeater_dangerZone => 'Veszélyzóna';

  @override
  String get repeater_rebootRepeater => 'Újraindítás';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Indítsa újra a repeater-t.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Biztosan szeretné újraindítani ezt a repeatert?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Újra generálja az azonosító kulcsot';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Új nyilvános/személyes kulcs-párt generáljon';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Ez új azonosítást fog létrehozni a repeater számára. Folytatni?';

  @override
  String get repeater_eraseFileSystem => 'Törölje a fájlrendszert';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formázza a duplázó fájlrendszert.';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'FIGYELEM: Ez törli az összes adatot a repeater-en. Ez nem visszafordítható!';

  @override
  String get repeater_eraseSerialOnly =>
      'Az Erase funkció csak a soros konzolon érhető el.';

  @override
  String repeater_commandSent(String command) {
    return 'Parancs elküldve: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Hibás parancs küldés: $error';
  }

  @override
  String get repeater_confirm => 'Beküldve';

  @override
  String get repeater_settingsSaved => 'Beállítások sikeresen mentve';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Hibás beállítások mentése: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Visszaállítás az alapértékekre';

  @override
  String get repeater_refreshRadioSettings => 'Frissítse a rádió beállításait';

  @override
  String get repeater_refreshTxPower => 'Újraindítás TX-támogatással';

  @override
  String get repeater_refreshLocationSettings =>
      'Újraindítás helyszín beállításokkal';

  @override
  String get repeater_refreshPacketForwarding =>
      'Csomagok továbbításának frissítése';

  @override
  String get repeater_refreshGuestAccess => 'Újraindítás vendégHozzáférés';

  @override
  String get repeater_refreshPrivacyMode =>
      'Visszaállítás a magánéletvédő módra';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Újraindítás hirdetés beállítások';

  @override
  String repeater_refreshed(String label) {
    return '$label frissítve';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Hiba a $label frissítés közben';
  }

  @override
  String get repeater_cliTitle => 'CLI (parancssori felület)';

  @override
  String get repeater_debugNextCommand => 'Hibakeresés, következő parancs';

  @override
  String get repeater_commandHelp => 'Segítség';

  @override
  String get repeater_clearHistory => 'Egyértelmű történet';

  @override
  String get repeater_noCommandsSent => 'Még egyik parancsot sem küldtünk.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Írja be a parancsot alább, vagy használja a gyors parancsokat.';

  @override
  String get repeater_enterCommandHint => 'Írja be a parancsot...';

  @override
  String get repeater_previousCommand => 'Előző parancs';

  @override
  String get repeater_nextCommand => 'Következő parancs';

  @override
  String get repeater_enterCommandFirst => 'Add meg először egy parancsot';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI parancssor felépítése';

  @override
  String repeater_cliCommandError(String error) {
    return 'Hiba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Kapcsold össze a nevet';

  @override
  String get repeater_cliQuickGetRadio => 'Szerezd a rádiót';

  @override
  String get repeater_cliQuickGetTx => 'Szerezd a TX-t';

  @override
  String get repeater_cliQuickNeighbors => 'Szomszédok';

  @override
  String get repeater_cliQuickVersion => 'Verzió';

  @override
  String get repeater_cliQuickAdvertise => 'Hirdetés';

  @override
  String get repeater_cliQuickClock => 'óra';

  @override
  String get repeater_cliHelpAdvert => 'Elküldi egy hirdetési csomagot';

  @override
  String get repeater_cliHelpReboot =>
      'Újraindítja a készüléket. (Kérjük, vegye figyelembe, hogy valószínűleg \"Időhiba\" üzenetet fog kapni, ami normális)';

  @override
  String get repeater_cliHelpClock =>
      'A jelenlegi időt mutatja az egyes eszközök karórája alapján.';

  @override
  String get repeater_cliHelpPassword =>
      'Új adminisztrációs jelszót állít be a eszköz számára.';

  @override
  String get repeater_cliHelpVersion =>
      'Megjeleníti a készülék verzióját és a szoftver verziószámát.';

  @override
  String get repeater_cliHelpClearStats =>
      'Visszaállítja a különböző statisztikai mérőszámokat a nullára.';

  @override
  String get repeater_cliHelpSetAf => 'Beállítja az idő-szabályozási tényezőt.';

  @override
  String get repeater_cliHelpSetTx =>
      'Beállítja a LoRa átviteli teljesítményt dBm-ben (a rendszer újraindításával alkalmazható).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Engedélyezi vagy tiltja meg a repeater szerepet ezen a csomón.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Szoba szerver) Ha \"igen\", akkor üres jelszóval történő bejelentkezés engedélyezett lesz, de nem lehet üzeneteket küldeni a szobában. (Csak olvasási funkció)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Beállítja a bejövő adatcsomagok maximális számát (ha ez a érték nagyobb vagy egyenlő a maximális értékkel, a csomag nem továbbítódik).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Beállítja az interferencia határértéket (dB-ben). Az alapérték 14. Ha 0-ra állítja, kiküntheti a csatornák közötti interferencia detektálást.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Beállítja az intervallumot, amely a \"Automatikus gain\" szabályozó újraindításához szükséges. Beállítás értéke 0, ha a funkciót le kell tiltani.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Engedélyezi vagy kikapcsolja a „dupla visszaigazolás” funkciót.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Beállítja az időzítő intervallumot percenként, hogy egy helyi (nincs átjáró) hirdetési csomagot küldjen. Beállítás értéke 0, ha a funkciót le szeretné tiltani.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Beállítja az időzítő intervallumot órában, hogy egy \"áramló\" hirdetési üzenetet küldjön. Beállítás értéke 0, ha a funkciót kikapcsolni kell.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Beállítja/frissíti a vendég felhasználói fiókot. (Ez lehetővé teszi a visszatérő felhasználók számára, hogy a \"Statistika lekérdezése\" kérést elküldjék)';

  @override
  String get repeater_cliHelpSetName => 'Megadja az űrlap neve.';

  @override
  String get repeater_cliHelpSetLat =>
      'Beállítja az hirdetés térképen megjelenő pont koordinátájának (tizedes fokokban) a latitude-ját.';

  @override
  String get repeater_cliHelpSetLon =>
      'Beállítja az hirdetés térképen megjelenő hosszúság koordinátát (tizedes fokokban).';

  @override
  String get repeater_cliHelpSetRadio =>
      'Teljesen új rádióparamétereket állít be, és azokat a beállításokba menti. Az alkalmazásához \"újraindítás\" parancs szükséges.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Beállítások (kísérleti): Alapérték (legalább 1 értékre kell állítani, hogy hatás legyen), amely alapján a fogadott csomagokhoz enyhe késést alkalmazunk, a jelet ereje/pontszám alapján. 0-ra állítva a funkciót lekapcsoljuk.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Beállítja egy tényezőt, amely a légköri idővel szorozva, egy áramlás-üzem módú csomaghoz, valamint egy véletlenszerű slot-rendszerhez, hogy késleltesse a továbbítását. (az ütközések valószínűségének csökkentése érdekében)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Hasonló a txdelay-hez, de ebben az esetben egy véletlenszerű késést alkalmazunk a közvetlen módú csomagok továbbításakor.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Engedélyez/Tiltás a híd funkciójának.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Állíts be egy késleztatást a csomagok újbóli továbbításakor.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Döntse el, hogy a híd fogadott vagy elküldött csomagokat fogja-e továbbítani.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Állítsa be a soros kommunikáció sebességét az RS232 hídok számára.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Állítsa be a titkos kapcsolatot az ESPNOW hídokhoz.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Lehetővé teszi a felhasználónak, hogy egyedi tényezőt állíts be a riportolt akkumulátor feszültségének módosításához (ez csak bizonyos alkatrészeken támogatott).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Időjárás szerinti rádióparamétereket állít be a megadott időtartamra, majd visszaállítja az eredeti beállításokat. (Nem menti a beállításokat a beállítások részben).';

  @override
  String get repeater_cliHelpSetPerm =>
      'A ACL-t módosítja. Ha a \"permissions\" érték 0, akkor eltávolítja a megfelelő bejegyzést (a pubkey előtag alapján). Új bejegyzést hoz létre, ha a pubkey-hex teljes hossza, és jelenleg nem szerepel az ACL-ben. A bejegyzést frissíti a megfelelő pubkey előtag alapján. A engedélyek különbözőek a különböző firmware szerepek között, de az alsó 2 bit a következő értékeket képviseli: 0 (Vendég), 1 (Csak olvasás), 2 (Olvasás és írás), 3 (Adminisztrátor)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Kapcsolatok: hid típusú, RS232, ESPNOW';

  @override
  String get repeater_cliHelpLogStart =>
      'Elindítja a csomagok naplózását a fájlrendszerbe.';

  @override
  String get repeater_cliHelpLogStop =>
      'Megállítja a csomagok naplózását a fájlrendszerbe.';

  @override
  String get repeater_cliHelpLogErase =>
      'Törli a fájlrendszerből a csomagok log-fájljait.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mutat egy listát, amely tartalmazza a más repeater-ek által hallott adatok listáját, amelyek 0-hop hirdetések révén érhetők el. Minden sor az alábbi formát követi: id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Törli az első, a megadott kulcs-prefix (hexadecimális formában) alapján megegyező bejegyzést a szomszédok listájából.';

  @override
  String get repeater_cliHelpRegion =>
      '(sorozat) Lista az összes meghatározott területet és a jelenlegi árvízvédelmi engedélyeket.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'FIGYELEM: ez egy speciális, több parancsot tartalmazó futtatás. Minden következő parancs egy területtel kapcsolatos, amely egyenletes szóközökkel (a szülő-gyermek kapcsolatot jelző) megkülönböztethető. A parancs végrehajtása egy üres sor/parancs küldésével történik.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Keresések egy adott név előtérrel (vagy \"*\" globális hatókörre). Válasz: \"-> region-név (szülő-név) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Hozzáad vagy frissíti egy régió definíciót megadott néven.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Eltávolítja a megadott nevet használó régió-definíciót. (pontosan meg kell egyeznie, és nem lehet gyermekrégiója)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Beállítja a megadott területre vonatkozó \"víz\" jogosultságot. (A globális/régi beállítások esetén a \"*\" jelölő)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Eltávolítja a megadott területre vonatkozó \"F\"lood (víz) engedélyt. (FIGYELEM: jelenleg nem javasolt ezt a globális/régi verzióban használni!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Visszaállítja a jelenlegi „otthoni” régiót. (Ez a beállítás még nem került alkalmazásra, csak jövőbeli használatra fenyelve)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Beállítja a \"házi\" régiót.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Megőrzi a régió listát/térképet a tárolóban.';

  @override
  String get repeater_cliHelpGps =>
      'Megadja a GPS állapotát. Ha a GPS kikapcsolva van, akkor csak \"ki\" választot ad, ha be van, akkor \"be\", \"állapot\", \"pozíció\", \"satellitok száma\" értékeket ad.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Engedi a GPS működés állapotát.';

  @override
  String get repeater_cliHelpGpsSync =>
      'A hálózati időt az GPS óra időjével szinkronizálja.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Beállítja a węsz pozícióját GPS koordináták alapján, és menti a beállításokat.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Adja meg a hirdetés konfigurációjának helyszín-információját:\n- none: ne tartalmazza a helyszínt a hirdetésekben\n- share: megosztja a GPS-helyszínt (SensorManager-ből)\n- prefs: hirdeti a beállításokban tárolt helyszínt';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Beállítja a hirdetés helyszín-specifikus beállításait.';

  @override
  String get repeater_commandsListTitle => 'Parancsok listája';

  @override
  String get repeater_commandsListNote =>
      'FIGYELEM: a különböző \"set ...\" parancsok mellett létezik egy \"get ...\" parancs is.';

  @override
  String get repeater_general => 'Általános';

  @override
  String get repeater_settingsCategory => 'Beállítások';

  @override
  String get repeater_bridge => 'Híd';

  @override
  String get repeater_logging => 'Naplózás';

  @override
  String get repeater_neighborsRepeaterOnly =>
      'Szomszédok (Csak ismétlő funkció)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regionális menedzsment (Csak egyirányú kommunikáció)';

  @override
  String get repeater_regionNote =>
      'Region-specifikus parancsokat vezettek be a régiók definiálására és a hozzájuk tartozó engedélyek kezelésére.';

  @override
  String get repeater_gpsManagement => 'GPS-vezérlés';

  @override
  String get repeater_gpsNote =>
      'Az GPS-al kapcsolatos funkciók lehetővé teszik a helyszín-személyesítéssel kapcsolatos feladatok kezelését.';

  @override
  String get telemetry_receivedData => 'Kapott adatokat a szenzorokról';

  @override
  String get telemetry_requestTimeout => 'Az adatkapcsolati kérés sikertelen.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Hiba az adatok begyűjtésében: $error';
  }

  @override
  String get telemetry_noData => 'Nincsenek elérhető telemetriadatok.';

  @override
  String telemetry_channelTitle(int channel) {
    return '$channel csatorna';
  }

  @override
  String get telemetry_batteryLabel => 'Akku';

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
    return '$celsius °C / $fahrenheit °F';
  }

  @override
  String get neighbors_receivedData => 'Kapott szomszédok adatait';

  @override
  String get neighbors_requestTimedOut =>
      'A szomszédok kérik, hogy tiltsák le a kamerát.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Hiba a szomszédok betöltésében: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ismétlő eszközök, szomszédok';

  @override
  String get neighbors_noData => 'Nincsenek elérhető szomszédokról adatok.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Tudatlan $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Értsd: $time sitten';
  }

  @override
  String get channelPath_title => 'Csomagok útvonala';

  @override
  String get channelPath_viewMap => 'Megtekinthető térkép';

  @override
  String get channelPath_otherObservedPaths => 'Egyéb megfigyelt utak';

  @override
  String get channelPath_repeaterHops => 'Adat továbbító lépések';

  @override
  String get channelPath_noHopDetails =>
      'Ez a csomag nem tartalmaz részletes információkat a \"hop\" (vagy más hasonló) szót használó kifejezésekről.';

  @override
  String get channelPath_messageDetails => 'Üzenet részletei';

  @override
  String get channelPath_senderLabel => 'Megküldő';

  @override
  String get channelPath_timeLabel => 'Idő';

  @override
  String get channelPath_repeatsLabel => 'Ismétli';

  @override
  String channelPath_pathLabel(int index) {
    return 'Útvonal $index';
  }

  @override
  String get channelPath_observedLabel => 'Megfigyelt';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Megfigyelt útvonal: $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nincs helyszínadat.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Megfejt';

  @override
  String get channelPath_floodPath => 'Árvíz';

  @override
  String get channelPath_directPath => 'Közvetlen';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0-ból $total';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed of $total hops';
  }

  @override
  String get channelPath_mapTitle => 'Útvonal térkép';

  @override
  String get channelPath_noRepeaterLocations =>
      'Ez a útvonal nem támogat repeater-t.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Útvonal $index (Elsődleges)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Út';

  @override
  String get channelPath_observedPathHeader => 'Megfigyelt útvonal';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Ez a csomag nem tartalmaz részletes információkat a szállításhoz.';

  @override
  String get channelPath_unknownRepeater => 'Tudatlan erősítő';

  @override
  String get community_title => 'Helyi közösség';

  @override
  String get community_create => 'Teremtsd meg a közösséget';

  @override
  String get community_createDesc =>
      'Légyon létre egy új közösséget, és osszák meg QR-kód segítségével.';

  @override
  String get community_join => 'Csatlakozjon';

  @override
  String get community_joinTitle => 'Csatlakozzon a közösséghez';

  @override
  String community_joinConfirmation(String name) {
    return 'Szeretne csatlakozni a közösséghez, $name?';
  }

  @override
  String get community_scanQr => 'QR-kód olvasó a közösség számára';

  @override
  String get community_scanInstructions =>
      'Fordítsa a kamerát egy közösségi QR-kód irányába.';

  @override
  String get community_showQr => 'Megjelenítse a QR-kódot';

  @override
  String get community_publicChannel => 'Összetartó, közösségi';

  @override
  String get community_hashtagChannel => 'Helyi hashtaget';

  @override
  String get community_name => 'Helyi közösség neve';

  @override
  String get community_enterName => 'Kérjük, a közösség nevét írja be.';

  @override
  String community_created(String name) {
    return 'A \"$name\" nevű közösség létrehozva';
  }

  @override
  String community_joined(String name) {
    return 'Csatlakozott a $name közösséghez';
  }

  @override
  String get community_qrTitle => 'Osszpontosítás a közösségben';

  @override
  String community_qrInstructions(String name) {
    return 'Scanned this QR-kódot, hogy csatlakozhat a $name csoporthoz.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'A közösségi hashtagekhez tartozó csatornák csak a közösség tagjai számára érhetők el.';

  @override
  String get community_invalidQrCode => 'Érvénytelen közösségi QR-kód';

  @override
  String get community_alreadyMember => 'Már tag vagy';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Már tagja $name-nek.';
  }

  @override
  String get community_addPublicChannel =>
      'Hozzon létre egy közösségi nyilvános csatornát';

  @override
  String get community_addPublicChannelHint =>
      'Automatikusan hozzon létre ezt a csatornát a közösség számára.';

  @override
  String get community_noCommunities => 'Még egyik közösség sem csatlakozott.';

  @override
  String get community_scanOrCreate =>
      'Scelle egy QR-kódot, vagy hozzon létre egy közösséget, hogy elinduljon.';

  @override
  String get community_manageCommunities => 'Közösségek kezelése';

  @override
  String get community_delete => 'Hagyományos közösségi élet';

  @override
  String community_deleteConfirm(String name) {
    return 'Hagyom $name-et?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Ezem törli is $count csatornát és a hozzá tartozó üzeneteket.';
  }

  @override
  String community_deleted(String name) {
    return 'A közösség, amely $name';
  }

  @override
  String get community_regenerateSecret => 'Titkos visszaállítás';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Újra kell generálni a titkos kulcsot $name számára? Minden tagnak be kell szkennelnie az új QR-kódot, hogy továbbra is kommunikálhasson.';
  }

  @override
  String get community_regenerate => 'Újraalakítás';

  @override
  String community_secretRegenerated(String name) {
    return 'Titkos kulcs megújult $name számára.';
  }

  @override
  String get community_updateSecret => 'Frissítési titok';

  @override
  String community_secretUpdated(String name) {
    return 'Titkos információ frissítve $name számára';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scanned a új QR-kódot, hogy frissítsük a $name számára megőrzött titkos információt.';
  }

  @override
  String get community_addHashtagChannel => 'Adjon egy közösségi hashtaget';

  @override
  String get community_addHashtagChannelDesc =>
      'Hozz létre egy hashtage-os csatornát ennek a közösségnek';

  @override
  String get community_selectCommunity => 'Válasszon közösséget';

  @override
  String get community_regularHashtag => 'Rendszeres hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Önmagas szintű hashtaget (bárki csatlakozhat)';

  @override
  String get community_communityHashtag => 'Helyi hashtaget';

  @override
  String get community_communityHashtagDesc => 'Csak a közösség tagjai számára';

  @override
  String community_forCommunity(String name) {
    return '$name számára';
  }

  @override
  String get listFilter_tooltip => 'Szűrés és rendezés';

  @override
  String get listFilter_sortBy => 'Szűrés';

  @override
  String get listFilter_latestMessages => 'Legfrissebb üzenetek';

  @override
  String get listFilter_heardRecently => 'Úgy hallottam, hogy...';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Szűrők';

  @override
  String get listFilter_all => 'Mind';

  @override
  String get listFilter_favorites => 'Kedvencek';

  @override
  String get listFilter_addToFavorites => 'Megerősítés kívánságlistára';

  @override
  String get listFilter_removeFromFavorites => 'Törölj a kedvencekből';

  @override
  String get listFilter_users => 'Felhasználók';

  @override
  String get listFilter_repeaters => 'Újraküldők';

  @override
  String get listFilter_roomServers => 'Szoba-szolgálatok';

  @override
  String get listFilter_unreadOnly => 'Csak olvasatlan';

  @override
  String get listFilter_newGroup => 'Új csoport';

  @override
  String get pathTrace_you => 'Te';

  @override
  String get pathTrace_failed => 'A útvonal követése sikertelen.';

  @override
  String get pathTrace_notAvailable =>
      'Az útvonal követési funkció nem elérhető.';

  @override
  String get pathTrace_refreshTooltip => 'Út mentesség frissítése.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Egy vagy több búzavirág hiányozik a helyszínéről!';

  @override
  String get pathTrace_clearTooltip => 'Egyértelmű út.';

  @override
  String get losSelectStartEnd =>
      'Válassza ki a kezdő és a végpontokat a LOS-hoz.';

  @override
  String losRunFailed(String error) {
    return 'A látószög ellenőrzése sikertelen: $error';
  }

  @override
  String get losClearAllPoints => 'Teljesen tisztázzuk az összes pontot';

  @override
  String get losRunToViewElevationProfile =>
      'Használja a LOS-t, hogy megtekinthesse a magasságkülönbségek diagramját.';

  @override
  String get losMenuTitle => 'LOS menü';

  @override
  String get losMenuSubtitle =>
      'A térképen található pontok kiválasztására vagy a térképen hosszúra nyomva, hogy egyedi pontokat definiálhassunk.';

  @override
  String get losShowDisplayNodes => 'Megjelenítsen a megjelenítési egységeket';

  @override
  String get losCustomPoints => 'Egyedi pontok';

  @override
  String losCustomPointLabel(int index) {
    return 'Egyedi $index';
  }

  @override
  String get losPointA => 'A pont A';

  @override
  String get losPointB => 'Pont B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenna A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenna B: $value $unit';
  }

  @override
  String get losRun => 'Futtass a LOS-on';

  @override
  String get losNoElevationData => 'Nincsenek emelkedési adatok.';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, clear LOS, min clearance $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, amelyet $obstruction akadályoz meg $heightUnit-ban';
  }

  @override
  String get losStatusChecking => 'LOS: ellenőrzés...';

  @override
  String get losStatusNoData => 'LOS: nincs adat';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total tisztított, $blocked blokkolt, $unknown ismeretlen';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Az alábbi minták esetében nem áll rendelkezésre magasságadat.';

  @override
  String get losErrorInvalidInput =>
      'Hibás vagy hiányos táblázatok a LOS (Loss of Signal) számításához.';

  @override
  String get losRenameCustomPoint => 'Állítsa meg a saját pont nevét';

  @override
  String get losPointName => 'Pont neve';

  @override
  String get losShowPanelTooltip => 'Megjelenítse a LOS paneelt';

  @override
  String get losHidePanelTooltip => 'Rejtse el a LOS paneelt';

  @override
  String get losElevationAttribution =>
      'Magasságadatok: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radio Horizont';

  @override
  String get losLegendLosBeam => 'LOS jelzés';

  @override
  String get losLegendTerrain => 'Terület';

  @override
  String get losFrequencyLabel => 'Hatósság';

  @override
  String get losFrequencyInfoTooltip => 'Lásd a számítás részleteit';

  @override
  String get losFrequencyDialogTitle =>
      'A rádióhullámok hatótávolságának kiszámítása';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'A $baselineK értékből kezdve, $baselineFreq MHz-os frekvencián, a számítás az aktuális $frequencyMHz MHz-os sávhoz igazítja a k-tényezőt, amely meghatározza a görbös rádióhatótávolság határát.';
  }

  @override
  String get contacts_pathTrace => 'Útvonal követése';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Az útvonal követése a repeaterig';

  @override
  String get contacts_repeaterPing => 'Ping-szinkronizáló';

  @override
  String get contacts_roomPathTrace => 'Kapcsolat a szobai szerverrel';

  @override
  String get contacts_roomPing => 'Ping-szolgáló szerver';

  @override
  String get contacts_chatTraceRoute => 'Útvonal meghatározása';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Keresse meg a $name címét.';
  }

  @override
  String get contacts_clipboardEmpty => 'A kiválasztott szöveg üres.';

  @override
  String get contacts_invalidAdvertFormat => 'Érvénytelen kontaktinformáció';

  @override
  String get contacts_contactImported => 'Kapcsolat létrejött.';

  @override
  String get contacts_contactImportFailed =>
      'Nem sikerült a kapcsolatot importálni.';

  @override
  String get contacts_zeroHopAdvert => 'Zero Hop reklám';

  @override
  String get contacts_floodAdvert => 'Árvízre vonatkozó hirdetés';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Másolja a hirdetést a kiválasztási ablakba';

  @override
  String get contacts_addContactFromClipboard =>
      'Adjon hozzá egy kapcsolatot a kiválasztott listából';

  @override
  String get contacts_ShareContact => 'Másolja a kapcsolatot a kiválasztóba';

  @override
  String get contacts_ShareContactZeroHop =>
      'Ossza meg a kapcsolatot hirdetés segítségével';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Kapcsolatot a hirdetésen keresztül.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Nem sikerült a kapcsolatot elküldeni.';

  @override
  String get contacts_contactAdvertCopied => 'A hirdetés másolva a vágólapra.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Az hirdetés másolása a vágólapra sikertelen.';

  @override
  String get notification_activityTitle => 'MeshCore tevékenységek';

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
    return 'Új $contactType megtalálva';
  }

  @override
  String get notification_receivedNewMessage => 'Új üzenetet kaptam';

  @override
  String get settings_gpxExportRepeaters =>
      'Külső eszközök / helyi szerver a GPX formátumba';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportálható repeater/szobaterm-szerver, amely egy GPX fájlban tárolja a helyzetet.';

  @override
  String get settings_gpxExportContacts => 'GPX export funkciók';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Az export funkció lehetővé teszi, hogy a GPS fájlban megadott helyszínen is megőrizzük az útvonalat.';

  @override
  String get settings_gpxExportAll =>
      'Exportálja az összes kapcsolatot GPX formátumban.';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Az összes elérhetőséget, amelyekhez egy helyszín tartozik, egy GPX fájlba exportálja.';

  @override
  String get settings_gpxExportSuccess =>
      'A GPX fájl sikeresen exportálva lett.';

  @override
  String get settings_gpxExportNoContacts => 'Nincs exportálható kapcsolatok.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nem támogatott a jelenlegi eszközön/rendszeren.';

  @override
  String get settings_gpxExportError => 'Hiba történt az export során.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Adatátvisszaadó eszközök és helyiségi szerverek helyei';

  @override
  String get settings_gpxExportChat => 'Kapcsolódó helyszínek';

  @override
  String get settings_gpxExportAllContacts => 'Az összes kapcsolat helyszíne';

  @override
  String get settings_gpxExportShareText =>
      'A meshcore-open-ból exportált térkéadatumok';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open GPX formátumú térképi adatok export';

  @override
  String get snrIndicator_nearByRepeaters => 'Helyszíni erősítők';

  @override
  String get snrIndicator_lastSeen => 'Utoljára, amikor látták';

  @override
  String get contactsSettings_title => 'Kapcsolatok beállításai';

  @override
  String get contactsSettings_autoAddTitle => 'Automatikus felfedezés';

  @override
  String get contactsSettings_otherTitle =>
      'Egyéb kapcsolattal kapcsolatos beállítások';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automatikus felhasználói hozzáadás';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Engedje, hogy a segítő automatikusan hozzáadja az új felhasználókat.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automatikus visszatöltés';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Engedje, hogy a segítő eszköz automatikusan hozzáadja az új, megtalált jelzőállomásokat.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automatikus szobák szerverek hozzáadása';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Engedje, hogy a segítő automatikusan hozzáadja az új, megtalált hálózati szervereket.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatikus érzékelők hozzáadása';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Engedje, hogy a kísérő automatikusan hozzáadja az új, megtalált szenzorokat.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Felülírja a legrégebbet';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Amikor a névsor telítődik, a legidősebb, de még nem kedvencként jelölt személyt helyettesíti egy újabb.';

  @override
  String get discoveredContacts_Title => 'Megtalált kapcsolatok';

  @override
  String get discoveredContacts_noMatching => 'Nincs megegyező kapcsolat.';

  @override
  String get discoveredContacts_searchHint => 'Keress új kapcsolatokat';

  @override
  String get discoveredContacts_contactAdded => 'Kapcsolat hozzáadva';

  @override
  String get discoveredContacts_addContact => 'Adjon személyhez';

  @override
  String get discoveredContacts_copyContact =>
      'Másolja a kapcsolatot a vágólapra';

  @override
  String get discoveredContacts_deleteContact =>
      'Törölj a feltalált kapcsolatot';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Törölj minden megtalált kapcsolatot';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Biztos, hogy szeretné törölni az összes eddig megtalált kapcsolatot?';

  @override
  String get chat_sendCooldown =>
      'Kérjük, várjon egy pillanatot, mielőtt újra elküldené.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Jelentkezzen az legörebb, olvasatlan üzenetre';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Amikor egy új csevet indítunk, amelyben vannak olvashatatlan üzenetek, görgessük a listát, hogy a legelső, olvashatatlan üzenet megjelenjen, nem pedig az utolsó.';

  @override
  String get appSettings_languageHu => 'Magyar';

  @override
  String get appSettings_languageJa => 'Japán';

  @override
  String get appSettings_languageKo => 'Koreai';

  @override
  String get radioStats_tooltip => 'Rádió és hálózati statisztikák';

  @override
  String get radioStats_screenTitle => 'Rádió statisztikák';

  @override
  String get radioStats_notConnected =>
      'Csatlakozzon egy eszközhöz, hogy megtekinthesse a rádió adatok statisztikáit.';

  @override
  String get radioStats_firmwareTooOld =>
      'A rádió statisztikákhoz v8 vagy újabb verziójú szoftver szükséges.';

  @override
  String get radioStats_waiting => 'Adatokra vár…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Háttérzaj szint: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Utolsó RSSI érték: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Utolsó SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX-es idő (összesen): $seconds másodperc';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX használat időtartama (összesen): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Háttérzaj szint (dBm) a legutóbbi minták alapján.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Háttérzaj szint: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Rádió adatok begyűjtése…';

  @override
  String get radioStats_settingsTile => 'Rádió statisztikák';

  @override
  String get radioStats_settingsSubtitle =>
      'Háttérzaj, RSSI, zaj-sűrűség, és a használat időtartama';

  @override
  String get scanner_linuxPairingShowPin => 'PIN megjelenítése';

  @override
  String get scanner_linuxPairingHidePin => 'PIN elrejtése';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth párosítási PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Adja meg a(z) $deviceName PIN-kódját (hagyja üresen, ha nincs).';
  }
}
