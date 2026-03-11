// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Kontakty';

  @override
  String get nav_channels => 'Kanály';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Zrušiť';

  @override
  String get common_ok => 'OK\nDobre';

  @override
  String get common_connect => 'Pripojiť';

  @override
  String get common_unknownDevice => 'Neznáme zariadenie';

  @override
  String get common_save => 'Uložiť';

  @override
  String get common_delete => 'Odstrániť';

  @override
  String get common_deleteAll => 'Zmazať všetko';

  @override
  String get common_close => 'Zavrieť';

  @override
  String get common_edit => 'Upraviť';

  @override
  String get common_add => 'Pridať';

  @override
  String get common_settings => 'Nastavenia';

  @override
  String get common_disconnect => 'Odpojiť';

  @override
  String get common_connected => 'Pripojené';

  @override
  String get common_disconnected => 'Odpojené';

  @override
  String get common_create => 'Vytvoriť';

  @override
  String get common_continue => 'Pokračovať';

  @override
  String get common_share => 'Zdieľať';

  @override
  String get common_copy => 'Kopírovať';

  @override
  String get common_retry => 'Pokusť znova';

  @override
  String get common_hide => 'Skryť';

  @override
  String get common_remove => 'Odstrániť';

  @override
  String get common_enable => 'Povolit';

  @override
  String get common_disable => 'Zakázať';

  @override
  String get common_reboot => 'Restartovať';

  @override
  String get common_loading => 'Načítavanie...';

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
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get usbScreenTitle => 'Pripojte cez USB';

  @override
  String get usbScreenSubtitle =>
      'Vyberte detekovaný sériový zariadenie a pripojte ho priamo k vašej MeshCore uzlu.';

  @override
  String get usbScreenStatus => 'Vyberte USB zariadenie';

  @override
  String get usbScreenNote =>
      'USB sériová komunikácia je aktívna na podporovaných zariadeniach s Androidom a na desktopových platformách.';

  @override
  String get usbScreenEmptyState =>
      'Nenašli sa žiadne USB zariadenia. Pripojte jedno a obnovte.';

  @override
  String get usbErrorPermissionDenied =>
      'Žiadosť o prístup cez USB bola zamietnutá.';

  @override
  String get usbErrorDeviceMissing =>
      'Vybrané USB zariadenie už nie je dostupné.';

  @override
  String get usbErrorInvalidPort => 'Vyberte platné USB zariadenie.';

  @override
  String get usbErrorBusy =>
      'Ďalšia požiadavka na pripojenie cez USB je aktuálne v procese.';

  @override
  String get usbErrorNotConnected => 'Nie je pripojené žiadne USB zariadenie.';

  @override
  String get usbErrorOpenFailed =>
      'Nepodarilo sa otvoriť vybrané USB zariadenie.';

  @override
  String get usbErrorConnectFailed =>
      'Nepodarilo sa sa sa pripojiť k vybranému USB zariadeniu.';

  @override
  String get usbErrorUnsupported =>
      'Podpora USB sériového rozhrania nie je na tejto platforme dostupná.';

  @override
  String get usbErrorAlreadyActive => 'Pripojenie cez USB je už aktivované.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Nebolo vybrané žiadne USB zariadenie.';

  @override
  String get usbErrorPortClosed => 'Pripojenie cez USB nie je aktivované.';

  @override
  String get usbErrorConnectTimedOut =>
      'Pripojenie nebolo úspešné. Uistite sa, že zariadenie má nainštalovaný firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Webový sériový zariadenie';

  @override
  String get usbStatus_notConnected => 'Vyberte USB zariadenie';

  @override
  String get usbStatus_connecting => 'Pripojenie k USB zariadeniu...';

  @override
  String get usbStatus_searching => 'Hľadanie USB zariadení...';

  @override
  String usbConnectionFailed(String error) {
    return 'Neúspešné pripojenie cez USB: $error';
  }

  @override
  String get scanner_scanning => 'Skrívania zariadení...';

  @override
  String get scanner_connecting => 'Pripojujem sa...';

  @override
  String get scanner_disconnecting => 'Odpojuje sa...';

  @override
  String get scanner_notConnected => 'Nezriadené';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Pripojené k $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Hľadám zariadenia MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Stlač skenovanie na nájdenie zariadení MeshCore.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Pripojenie zlyhalo: $error';
  }

  @override
  String get scanner_stop => 'Zastavte';

  @override
  String get scanner_scan => 'Skončiť';

  @override
  String get scanner_bluetoothOff => 'Bluetooth je vypnutý';

  @override
  String get scanner_bluetoothOffMessage =>
      'Prosím, zapnite Bluetooth, aby ste mohli skenovať pre zariadenia.';

  @override
  String get scanner_chromeRequired => 'Vyžaduje sa prehliadač Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Táto webová aplikácia vyžaduje Google Chrome alebo prehliadač založený na Chromium pre podporu Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Povolte Bluetooth';

  @override
  String get device_quickSwitch => 'Rýchle prepínač';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Nastavenia';

  @override
  String get settings_deviceInfo => 'Informácie o zariadení';

  @override
  String get settings_appSettings => 'Nastavenia aplikácie';

  @override
  String get settings_appSettingsSubtitle =>
      'Upozornenia, správy a nastavenia mapy';

  @override
  String get settings_nodeSettings => 'Nastavenia uzla';

  @override
  String get settings_nodeName => 'Názov uzla';

  @override
  String get settings_nodeNameNotSet => 'Nezriadené';

  @override
  String get settings_nodeNameHint => 'Zadajte názov uzla';

  @override
  String get settings_nodeNameUpdated => 'Meno aktualizované';

  @override
  String get settings_radioSettings => 'Nastavenia rádia';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvencia, výkon, rozptylovací faktor';

  @override
  String get settings_radioSettingsUpdated => 'Nastavenia rádia aktualizované';

  @override
  String get settings_location => 'Lokalita';

  @override
  String get settings_locationSubtitle => 'GPS súradnice';

  @override
  String get settings_locationUpdated => 'Lokalita aktualizovaná';

  @override
  String get settings_locationBothRequired =>
      'Zadajte obidve zložky zemyslenia a zložky meracieho kruhu.';

  @override
  String get settings_locationInvalid => 'Neplatná šírka alebo dĺžka.';

  @override
  String get settings_locationGPSEnable => 'Aktivovať GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Povolí automatické aktualizovanie polohy pomocou GPS.';

  @override
  String get settings_locationIntervalSec => 'Interval pre GPS (Sekundy)';

  @override
  String get settings_locationIntervalInvalid =>
      'Interval musí byť aspoň 60 sekúnd a menej ako 86400 sekúnd.';

  @override
  String get settings_latitude => 'Súradnica';

  @override
  String get settings_longitude => 'Dĺžka';

  @override
  String get settings_contactSettings => 'Nastavenia kontaktov';

  @override
  String get settings_contactSettingsSubtitle =>
      'Nastavenia pre pridávanie kontaktov.';

  @override
  String get settings_privacyMode => 'Režim ochrany súkromia';

  @override
  String get settings_privacyModeSubtitle => 'Skryť meno/poloha v reklamách';

  @override
  String get settings_privacyModeToggle =>
      'Prepínač súkromného režimu skryje vaše meno a polohu v reklamách.';

  @override
  String get settings_privacyModeEnabled => 'Ochranný režim je povolený.';

  @override
  String get settings_privacyModeDisabled => 'Ochranný režim je vypnutý';

  @override
  String get settings_actions => 'Možné akcie';

  @override
  String get settings_sendAdvertisement => 'Odoslať reklamu';

  @override
  String get settings_sendAdvertisementSubtitle => 'Momentálne priezornejšie.';

  @override
  String get settings_advertisementSent => 'Reklama odeslaná';

  @override
  String get settings_syncTime => 'Čas synchronizácie';

  @override
  String get settings_syncTimeSubtitle =>
      'Nastaviť hodiny zariadenia na čas telefónu';

  @override
  String get settings_timeSynchronized => 'Čas synchronizovaný';

  @override
  String get settings_refreshContacts => 'Načítať Kontakty';

  @override
  String get settings_refreshContactsSubtitle =>
      'Načítať zoznam kontaktov z zariadenia';

  @override
  String get settings_rebootDevice => 'Restartovať zariadenie';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Restartujte zariadenie MeshCore.';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ste si istý, že chcete zariadenie reštartovať? Budete odpojení.';

  @override
  String get settings_debug => 'Ladenie';

  @override
  String get settings_bleDebugLog => 'Log BLE Debug';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Príkazy BLE, odpovede a surové dáta';

  @override
  String get settings_appDebugLog => 'Záznam ladenia aplikácie';

  @override
  String get settings_appDebugLogSubtitle => 'Správy z ladenia aplikácie';

  @override
  String get settings_about => 'O nás';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => 'MeshCore Open Source Projekt 2024';

  @override
  String get settings_aboutDescription =>
      'Otvorený zdrojový Flutter klient pre MeshCore LoRa sieťové zariadenia.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Údaje o nadmorskej výške LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Meno';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Batéria';

  @override
  String get settings_infoPublicKey => 'Verejný kľúč';

  @override
  String get settings_infoContactsCount => 'Počet kontaktov';

  @override
  String get settings_infoChannelCount => 'Počet kanálov';

  @override
  String get settings_presets => 'Prednastavenia';

  @override
  String get settings_frequency => 'Frekvencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 – 2500,0';

  @override
  String get settings_frequencyInvalid => 'Neplatná frekvencia (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Šírka pásma';

  @override
  String get settings_spreadingFactor => 'Rozptýľovací faktor';

  @override
  String get settings_codingRate => 'Cenový kurz pre programovanie';

  @override
  String get settings_txPower => 'TX Výkon (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Neplatná hodnota výkonu TX (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Opätovné použitie bez elektrickej siete';

  @override
  String get settings_clientRepeatSubtitle =>
      'Umožnite, aby toto zariadenie opakovávalo siete pre ostatných.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Použitie off-grid systému vyžaduje frekvencie 433, 869 alebo 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Chyba: $message';
  }

  @override
  String get appSettings_title => 'Nastavenia aplikácie';

  @override
  String get appSettings_appearance => 'Vzhľad';

  @override
  String get appSettings_theme => 'Téma';

  @override
  String get appSettings_themeSystem => 'Predvolený systém';

  @override
  String get appSettings_themeLight => 'Svetlo';

  @override
  String get appSettings_themeDark => 'Tmavé';

  @override
  String get appSettings_language => 'Jazyk';

  @override
  String get appSettings_languageSystem => 'Predvolený systém';

  @override
  String get appSettings_languageEn => 'English';

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
  String get appSettings_languageRu => 'Ruština';

  @override
  String get appSettings_languageUk => 'Ukrajinská';

  @override
  String get appSettings_enableMessageTracing => 'Povoliť sledovanie správ';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Zobraziť podrobné metadáta o smerovaní a časovaní správ';

  @override
  String get appSettings_notifications => 'Upozornenia';

  @override
  String get appSettings_enableNotifications => 'Povolte Notifikácie';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Zísť o upozornenia na správy a inzeráty';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Odmietená povolenie notifikácií';

  @override
  String get appSettings_notificationsEnabled => 'Upozornenia povolené';

  @override
  String get appSettings_notificationsDisabled => 'Upozornenia sú vypnuté';

  @override
  String get appSettings_messageNotifications => 'Správy od upozornení';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Zobraziť upozornenie pri prijímaní nových správ';

  @override
  String get appSettings_channelMessageNotifications => 'Notifikácie z kanálov';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Zobraziť upozornenie pri prijímaní správ z kanálu';

  @override
  String get appSettings_advertisementNotifications => 'Upozornenia na reklamy';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Zobraziť upozornenie, keď sa objavia nové uzly.';

  @override
  String get appSettings_messaging => 'Správy';

  @override
  String get appSettings_clearPathOnMaxRetry => 'Vyčisti cestu na Max Retry';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Resetovať kontaktný priebeh po 5 neúspešných pokusoch o doručenie';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Cesty budú vymazané po 5 neúspešných pokusoch.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Cesty sa automaticky nevymazávajú.';

  @override
  String get appSettings_autoRouteRotation => 'Automatické prechodové trasy';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Striedajte sa medzi najlepšími trasami a režimom povodňovej analýzy.';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Automatické otáčanie trasy povolené';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Automatické prekladanie trás pozastavené';

  @override
  String get appSettings_battery => 'Batéria';

  @override
  String get appSettings_batteryChemistry => 'Chemická zloženie batérie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Nastavenie pre $deviceName';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Pripojte sa k zariadeniu na výber';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Zobrazenie mapy';

  @override
  String get appSettings_showRepeaters => 'Zobraziť opakovače';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Zobraziť opakujúce sa uzly na mape';

  @override
  String get appSettings_showChatNodes => 'Zobraziť uzly chatových správ';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Zobraziť chatové uzly na mape';

  @override
  String get appSettings_showOtherNodes => 'Zobraziť ďalšie uzly';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Zobraziť ostatné typy uzlov na mape';

  @override
  String get appSettings_timeFilter => 'Filtrovacie Časové Obdoby';

  @override
  String get appSettings_timeFilterShowAll => 'Zobraziť všetky uzly';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Zobraziť uzly z posledných $hours hodín';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtračný čas mapy';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Zobraziť uzly objavené v:';

  @override
  String get appSettings_allTime => 'Všetky časy';

  @override
  String get appSettings_lastHour => 'Posledná hodina';

  @override
  String get appSettings_last6Hours => 'Posledné 6 hodín';

  @override
  String get appSettings_last24Hours => 'Posledných 24 hodín';

  @override
  String get appSettings_lastWeek => 'Minul týždeň';

  @override
  String get appSettings_offlineMapCache => 'Offline Mapa Pamäť';

  @override
  String get appSettings_unitsTitle => 'Jednotky';

  @override
  String get appSettings_unitsMetric => 'Metrické (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiálne (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Neoznačila sa žiadna oblasť';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Vyberená oblasť (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Ladenie';

  @override
  String get appSettings_appDebugLogging => 'Záznamy ladenia aplikácie';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Logovací správy aplikácie pre ladenie';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Aplikácia povolila ladenie protokolmi';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Zabudované ladenie aplikácie je vypnuté.';

  @override
  String get contacts_title => 'Kontakty';

  @override
  String get contacts_noContacts => 'Zatiaľ žiadne kontakty.';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakty sa zobrazia, keď zariadenia spúšťajú reklamu.';

  @override
  String get contacts_unread => 'Neprečítané';

  @override
  String get contacts_searchContactsNoNumber => 'Hľadať kontakty...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Vyhľadávajte kontakty...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Hľadať $number$str obľúbené...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Hľadať $number$str používateľov...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Hľadať $number$str opakovače...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Hľadaj $number$str serverov miestností...';
  }

  @override
  String get contacts_noUnreadContacts => 'Žiadne neprečítané kontakty';

  @override
  String get contacts_noContactsFound =>
      'Neboli nájdených žiadnych kontaktov ani skupiny.';

  @override
  String get contacts_deleteContact => 'Odstrániť kontakt';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Odstrániť $contactName z kontaktov?';
  }

  @override
  String get contacts_manageRepeater => 'Spravovať opakované zoznamy';

  @override
  String get contacts_manageRoom => 'Spravovať server miestnosti';

  @override
  String get contacts_roomLogin => 'Prihlásenie do miestnosti';

  @override
  String get contacts_openChat => 'Otvorené Chat';

  @override
  String get contacts_editGroup => 'Upraviť skupinu';

  @override
  String get contacts_deleteGroup => 'Vymažť skupinu';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Odstrániť \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Nová skupina';

  @override
  String get contacts_groupName => 'Názov skupiny';

  @override
  String get contacts_groupNameRequired => 'Skupina musí mať názov.';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Skupina \"$name\" už existuje';
  }

  @override
  String get contacts_filterContacts => 'Filtrovať kontakty...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Žiadne kontakty neodídu vášmu filtru.';

  @override
  String get contacts_noMembers => 'Žiadni členovia';

  @override
  String get contacts_lastSeenNow => 'Posledné zreteľné zobrazenie teraz';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Posledné zobrazenie $minutes min. dozadu';
  }

  @override
  String get contacts_lastSeenHourAgo =>
      'Zobral/Zabral poslednýkrát pred hodinou.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Posledné zobrazenie $hours hodín dozadu';
  }

  @override
  String get contacts_lastSeenDayAgo =>
      'Zobral/Zabral posledný raz pred 1 dňom.';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Posledné zobrazenie $days dní dozadu';
  }

  @override
  String get channels_title => 'Kanály';

  @override
  String get channels_noChannelsConfigured => 'Neobsiahnuté žiadne kanály';

  @override
  String get channels_addPublicChannel => 'Pridať verejný kanál';

  @override
  String get channels_searchChannels => 'Vyhľadávajte kanály...';

  @override
  String get channels_noChannelsFound => 'Neobsiahlo sa žiadnych kanálov.';

  @override
  String channels_channelIndex(int index) {
    return 'Kanál $index';
  }

  @override
  String get channels_hashtagChannel => 'Kanál s hashtagom';

  @override
  String get channels_public => 'Veľké verejné';

  @override
  String get channels_private => 'Osobné';

  @override
  String get channels_publicChannel => 'Veľké verejne kanály';

  @override
  String get channels_privateChannel => 'Osobné kanál';

  @override
  String get channels_editChannel => 'Upraviť kanál';

  @override
  String get channels_muteChannel => 'Stlmiť kanál';

  @override
  String get channels_unmuteChannel => 'Zrušiť stlmenie kanála';

  @override
  String get channels_deleteChannel => 'Odstrániť kanál';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Odstrániť \"$name\"? To sa nedá zrušiť.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanál \"$name\" sa nepodarilo odstrániť';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanál \"$name\" bol odstránený';
  }

  @override
  String get channels_addChannel => 'Pridať kanál';

  @override
  String get channels_channelIndexLabel => 'Index kanála';

  @override
  String get channels_channelName => 'Názov kanálu';

  @override
  String get channels_usePublicChannel => 'Použite verejný kanál';

  @override
  String get channels_standardPublicPsk => 'Štandardný verejný PSK';

  @override
  String get channels_pskHex => 'PSK (Šifrovacia kľúčik)';

  @override
  String get channels_generateRandomPsk => 'Generovať náhodný PSK';

  @override
  String get channels_enterChannelName => 'Prosím, zadajte názov kanála.';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK musí mať 32 hexadecimálových znakov.';

  @override
  String channels_channelAdded(String name) {
    return 'Kanál \"$name\" pridaný';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Upraviť kanál $index';
  }

  @override
  String get channels_smazCompression => 'Odstránenie kompresie SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanál \"$name\" bol aktualizovaný';
  }

  @override
  String get channels_publicChannelAdded => 'Veľký kanál pridaný';

  @override
  String get channels_sortBy => 'Triediť podľa';

  @override
  String get channels_sortManual => 'Ručne';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Posledné správy';

  @override
  String get channels_sortUnread => 'Nezriadené';

  @override
  String get channels_createPrivateChannel => 'Vytvorte súkromný kanál';

  @override
  String get channels_createPrivateChannelDesc =>
      'Zabezpečené pomocou tajného kľúča.';

  @override
  String get channels_joinPrivateChannel => 'Pripojiť sa k súkromnému kanálu';

  @override
  String get channels_joinPrivateChannelDesc => 'Ručne zadajte tajný kľúč.';

  @override
  String get channels_joinPublicChannel => 'Pripojte sa k verejnému kanálu';

  @override
  String get channels_joinPublicChannelDesc =>
      'Któvek sátó na tutó kanalizovát.';

  @override
  String get channels_joinHashtagChannel => 'Pripojte sa k Hashtag Kanálu';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Ktoekolikoľvek sa môže pridať do hashtag kanálov.';

  @override
  String get channels_scanQrCode => 'Skenujte QR kód';

  @override
  String get channels_scanQrCodeComingSoon => 'Čoskoro';

  @override
  String get channels_enterHashtag => 'Zadajte hashtag';

  @override
  String get channels_hashtagHint => 'napr. #tím';

  @override
  String get chat_noMessages => 'Zatiaľ žiadne správy.';

  @override
  String get chat_sendMessageToStart => 'Pošlite správu na začiatok';

  @override
  String get chat_originalMessageNotFound => 'Neznámy pôvodný odkaz.';

  @override
  String chat_replyingTo(String name) {
    return 'Odpovedám $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Odpovedať $name';
  }

  @override
  String get chat_location => 'Lokalita';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Pošli správu $contactName';
  }

  @override
  String get chat_typeMessage => 'Napište správu...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Správa je príliš dlhá (max $maxBytes bytov).';
  }

  @override
  String get chat_messageCopied => 'Správa skopírovaná';

  @override
  String get chat_messageDeleted => 'Posolstvo odstránené';

  @override
  String get chat_retryingMessage => 'Pokus o obnovenie';

  @override
  String chat_retryCount(int current, int max) {
    return 'Skúsiť $current/$max';
  }

  @override
  String get chat_sendGif => 'Odoslať GIF';

  @override
  String get chat_reply => 'Odpovedať';

  @override
  String get chat_addReaction => 'Pridať Reakciu';

  @override
  String get chat_me => 'Mne';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gestá';

  @override
  String get emojiCategoryHearts => 'Srdcia';

  @override
  String get emojiCategoryObjects => 'Objekty';

  @override
  String get gifPicker_title => 'Vyberte GIF';

  @override
  String get gifPicker_searchHint => 'Vyhľadávajte GIFy...';

  @override
  String get gifPicker_poweredBy => 'Napájané spoločnosťou GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Neboli nájdené žiadne GIFy.';

  @override
  String get gifPicker_failedLoad => 'Nepodarilo sa načítať GIFy';

  @override
  String get gifPicker_failedSearch => 'Nepodarilo sa vyhľadať GIFy';

  @override
  String get gifPicker_noInternet => 'Žiadna internetová konektivita';

  @override
  String get debugLog_appTitle => 'Záznam ladenia aplikácie';

  @override
  String get debugLog_bleTitle => 'Log BLE Debug';

  @override
  String get debugLog_copyLog => 'Kopírovať záznam';

  @override
  String get debugLog_clearLog => 'Vymažať záznam';

  @override
  String get debugLog_copied => 'Záznam ladenia skopírovaný';

  @override
  String get debugLog_bleCopied => 'Kopírovaný záznam z BLE.';

  @override
  String get debugLog_noEntries =>
      'Zatiaľ neboli zaznamenané žiadne debug logy.';

  @override
  String get debugLog_enableInSettings =>
      'Povolte ladicové logy v nastaveniach';

  @override
  String get debugLog_frames => 'Rámce';

  @override
  String get debugLog_rawLogRx => 'Raw Log-RX';

  @override
  String get debugLog_noBleActivity => 'Zatiaľ žiadna aktivita BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Dĺžka rámca: $count bajtov';
  }

  @override
  String debugFrame_command(String value) {
    return 'Prikáž: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Textová zvesť:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Cieľový PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Časové označenie: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Žiadne vlajky: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Typ textu: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Jednoduché';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex Dump:';

  @override
  String get chat_pathManagement => 'Správa ciest';

  @override
  String get chat_ShowAllPaths => 'Zobraziť všetky cesty';

  @override
  String get chat_routingMode => 'Režim trasy';

  @override
  String get chat_autoUseSavedPath => 'Použiť uloženú cestu';

  @override
  String get chat_forceFloodMode =>
      'Zavrieť režim núdzového povodňového režimu';

  @override
  String get chat_recentAckPaths => 'Nedávne cesty ACK (klepni na použitie):';

  @override
  String get chat_pathHistoryFull =>
      'História ciest je plná. Odstráňte záznamy, aby ste mohli pridať nové.';

  @override
  String get chat_hopSingular => 'Skok';

  @override
  String get chat_hopPlural => 'Skákať';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_successes => 'Úspechy';

  @override
  String get chat_removePath => 'Odstrániť cestu';

  @override
  String get chat_noPathHistoryYet =>
      'Zatiaľ žiadna história trás.\nPošlite správu a objavte trasy.';

  @override
  String get chat_pathActions => 'Cesty:';

  @override
  String get chat_setCustomPath => 'Nastaviť vlastnú cestu';

  @override
  String get chat_setCustomPathSubtitle => 'Ručne zadajte trasu.';

  @override
  String get chat_clearPath => 'Vyčistiš cestu';

  @override
  String get chat_clearPathSubtitle =>
      'Znovu nájsť vynútene pri nasledujúcej pošlite';

  @override
  String get chat_pathCleared =>
      'Cesta vyčistená. Nasledujúce prepočetné získa trasu znova.';

  @override
  String get chat_floodModeSubtitle =>
      'Použite prepínanie trasy v navigačnom paneli.';

  @override
  String get chat_floodModeEnabled =>
      'Odosporňovacia prevádzka je zapnutá. Vypnite ju znova cez ikonu routovania v navigačnom páse.';

  @override
  String get chat_fullPath => 'Celá cesta';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Podrobnosti o ceste zatiaľ dostupné nie sú. Skúste poslať správu na obnovenie.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Cesta nastavená: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Uložené lokálne. Spojte sa na synchronizáciu.';

  @override
  String get chat_pathDeviceConfirmed => 'Zariadenie potvrdené.';

  @override
  String get chat_pathDeviceNotConfirmed =>
      'Zariadenie zatiaľ nebolo potvrdené.';

  @override
  String get chat_type => 'Napište';

  @override
  String get chat_path => 'Cesta';

  @override
  String get chat_publicKey => 'Verejný kľúč';

  @override
  String get chat_compressOutgoingMessages => 'Komprimovať odoslané správy';

  @override
  String get chat_floodForced => 'Povodňová (nutená)';

  @override
  String get chat_directForced => 'Priame (donútené)';

  @override
  String chat_hopsForced(int count) {
    return '$count skokov (nutené)';
  }

  @override
  String get chat_floodAuto => 'Povod (automaticky)';

  @override
  String get chat_direct => 'Priamo';

  @override
  String get chat_poiShared => 'Zdieľané body záujmu';

  @override
  String chat_unread(int count) {
    return 'Nezriadené: $count';
  }

  @override
  String get chat_openLink => 'Otvoriť odkaz?';

  @override
  String get chat_openLinkConfirmation =>
      'Chcete otvoriť tento odkaz v prehliadači?';

  @override
  String get chat_open => 'Otvoriť';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Nepodarilo sa otvoriť odkaz: $url';
  }

  @override
  String get chat_invalidLink => 'Neplatný formát odkazu';

  @override
  String get map_title => 'Mapa uzlov';

  @override
  String get map_lineOfSight => 'Line of Sight';

  @override
  String get map_losScreenTitle => 'Line of Sight';

  @override
  String get map_noNodesWithLocation => 'Žiadne uzly s údajmi o polohe';

  @override
  String get map_nodesNeedGps =>
      'Uholníky musia zdieľať svoje GPS súradnice, aby sa zobrazili na mape.';

  @override
  String map_nodesCount(int count) {
    return 'Uzly: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Krúžky: $count';
  }

  @override
  String get map_chat => 'Rozhovor';

  @override
  String get map_repeater => 'Opakovanie';

  @override
  String get map_room => 'Izba';

  @override
  String get map_sensor => 'Senzor';

  @override
  String get map_pinDm => 'Zabudka (DM)';

  @override
  String get map_pinPrivate => 'Zabudka (Osobná)';

  @override
  String get map_pinPublic => 'Zablokovať (verejne)';

  @override
  String get map_lastSeen => 'Posledné zreteľné zobrazenie';

  @override
  String get map_disconnectConfirm =>
      'Ste si istý/á, že chcete odpojiť od tohto zariadenia?';

  @override
  String get map_from => 'Od';

  @override
  String get map_source => 'Zdroj';

  @override
  String get map_flags => 'Zástavy';

  @override
  String get map_shareMarkerHere => 'Zdieľte značku tu';

  @override
  String get map_pinLabel => 'Označka upozornenia';

  @override
  String get map_label => 'Značka';

  @override
  String get map_pointOfInterest => 'Bod záujmu';

  @override
  String get map_sendToContact => 'Pošleť na kontakt';

  @override
  String get map_sendToChannel => 'Poslať do kanálu';

  @override
  String get map_noChannelsAvailable => 'Неexistujú žiadne kanály.';

  @override
  String get map_publicLocationShare => 'Zdieľiť verejnú lokalitu';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Čoskoro budete zdieľať polohu v $channelLabel. Tento kanál je verejný a môže ho vidieť každý s PSK.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Pripojte sa k zariadeniu na zdieľanie značiek';

  @override
  String get map_filterNodes => 'Filtrovať uzly';

  @override
  String get map_nodeTypes => 'Typy uzlov';

  @override
  String get map_chatNodes => 'Chatové uzly';

  @override
  String get map_repeaters => 'Opakovadlá';

  @override
  String get map_otherNodes => 'Ostatné uzly';

  @override
  String get map_keyPrefix => 'Päťciferné predpona';

  @override
  String get map_filterByKeyPrefix => 'Filtrovať podľa predponového kľúča';

  @override
  String get map_publicKeyPrefix => 'Prefix verejného kľúča';

  @override
  String get map_markers => 'Označkovače';

  @override
  String get map_showSharedMarkers => 'Zobraziť zdieľané značky';

  @override
  String get map_showGuessedLocations =>
      'Zobraziť umiestnenia odhadnutých uzlov';

  @override
  String get map_showDiscoveryContacts => 'Zobraziť kontakty objavov';

  @override
  String get map_guessedLocation => 'Odhadnutá lokalita';

  @override
  String get map_lastSeenTime => 'Posledný čas sledovania';

  @override
  String get map_sharedPin => 'Zdieľaný PIN';

  @override
  String get map_joinRoom => 'Pripojiť miestnosť';

  @override
  String get map_manageRepeater => 'Spravovať Opakovanie';

  @override
  String get map_tapToAdd => 'Kliknite na uzly, aby ste ich pridali k ceste.';

  @override
  String get map_runTrace => 'Spustiť trasovaním cesty';

  @override
  String get map_removeLast => 'Odstrániť posledný';

  @override
  String get map_pathTraceCancelled => 'Zrušenie stopáže cesty bolo zrušené.';

  @override
  String get mapCache_title => 'Offline Mapa Pamäť';

  @override
  String get mapCache_selectAreaFirst => 'Vyberte si oblasť na predprerúčenie.';

  @override
  String get mapCache_noTilesToDownload =>
      'Žiadne dlaždice na stiahnutie pre toto zóna';

  @override
  String get mapCache_downloadTilesTitle => 'Stiahnuť dlaždice';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Stiahnuť $count dlaždíc na offline použitie?';
  }

  @override
  String get mapCache_downloadAction => 'Stiahnuť';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Zabudené $count dlaždíc';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Uložené $downloaded dlaždice ($failed neúspešné)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Vymazať offline uloženie';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Odstrániť všetky uložené mapové dlaždice?';

  @override
  String get mapCache_offlineCacheCleared => 'Offline polia vymazaná';

  @override
  String get mapCache_noAreaSelected => 'Neoznačila sa žiadna oblasť';

  @override
  String get mapCache_cacheArea => 'Obdĺžková oblasť';

  @override
  String get mapCache_useCurrentView => 'Použite aktuálny zobrazenie';

  @override
  String get mapCache_zoomRange => 'Rozsah zväčšenia';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Odhadnuté dlaždice: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Stiahnuté $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Stiahnuť dlaždice';

  @override
  String get mapCache_clearCacheButton => 'Vyprázdniť Vädsť';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Neúspešné stiahnutia: $count';
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
  String get time_justNow => 'Príbeh';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes min dozadu';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours h dozadu';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dní dozadu';
  }

  @override
  String get time_hour => 'hodina';

  @override
  String get time_hours => 'hodiny';

  @override
  String get time_day => 'deň';

  @override
  String get time_days => 'dni';

  @override
  String get time_week => 'týždeň';

  @override
  String get time_weeks => 'týždne';

  @override
  String get time_month => 'mesiac';

  @override
  String get time_months => 'mesiace';

  @override
  String get time_minutes => 'minúty';

  @override
  String get time_allTime => 'Všetko Časom';

  @override
  String get dialog_disconnect => 'Odpojiť';

  @override
  String get dialog_disconnectConfirm =>
      'Ste si istý/á, že chcete odpojiť od tohto zariadenia?';

  @override
  String get login_repeaterLogin => 'Opätovné prihlásenie';

  @override
  String get login_roomLogin => 'Prihlásenie do miestnosti';

  @override
  String get login_password => 'Heslo';

  @override
  String get login_enterPassword => 'Zadajte heslo';

  @override
  String get login_savePassword => 'Uložiť heslo';

  @override
  String get login_savePasswordSubtitle =>
      'Heslo bude bezpečne uložené na tomto zariadení.';

  @override
  String get login_repeaterDescription =>
      'Zadajte heslo opakovača, aby ste získali prístup k nastaveniam a stavu.';

  @override
  String get login_roomDescription =>
      'Zadajte heslo do miestnosti na prístup k nastaveniam a stavu.';

  @override
  String get login_routing => 'Rútiace';

  @override
  String get login_routingMode => 'Režim trasy';

  @override
  String get login_autoUseSavedPath => 'Použiť uloženú cestu';

  @override
  String get login_forceFloodMode =>
      'Zavrieť režim núdzového povodňového režimu';

  @override
  String get login_managePaths => 'Spravovať Cesty';

  @override
  String get login_login => 'Prihlásiť';

  @override
  String login_attempt(int current, int max) {
    return 'Skúšaj $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Prihlásenie zlyhalo: $error';
  }

  @override
  String get login_failedMessage =>
      'Prihlásenie zlyhalo. Heslo je nesprávne alebo je opakovač nedostupný.';

  @override
  String get common_reload => 'Načítať';

  @override
  String get common_clear => 'Zmazať';

  @override
  String path_currentPath(String path) {
    return 'Aktívna cesta: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Používa $count $_temp0 cestu';
  }

  @override
  String get path_enterCustomPath => 'Zadajte vlastný priebeh';

  @override
  String get path_currentPathLabel => 'Aktuálny priebeh';

  @override
  String get path_hexPrefixInstructions =>
      'Zadajte 2-miestne hexové predpony pre každú fázu, oddelené čiarkami.';

  @override
  String get path_hexPrefixExample =>
      'A1,F2,3C (každý uzel používa prvý bajt svojho verejného kľúča)';

  @override
  String get path_labelHexPrefixes => 'Cesty (hexové predpony)';

  @override
  String get path_helperMaxHops =>
      'Max 64 skokov. Každý prefix je 2 hexadecimálne znaky (1 bajt).';

  @override
  String get path_selectFromContacts => 'Vyberte sa z kontaktov:';

  @override
  String get path_noRepeatersFound =>
      'Nenašli sa žiadne opakovače ani serverové miestnosti.';

  @override
  String get path_customPathsRequire =>
      'Vlastné cesty vyžadujú medziletoch, ktoré môžu prenášať správky.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Neplatné hexové predpony: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Cesta je príliš dlhá. Umožnené je maximum 64 skokov.';

  @override
  String get path_setPath => 'Nastaviť cestu';

  @override
  String get repeater_management => 'Správa opakérov';

  @override
  String get room_management => 'Správa servera miestnosti';

  @override
  String get repeater_managementTools => 'Nástroje na správu';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Zobraziť stav, štatistiky a susedov repeatera';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Zobraziť telemetriu senzorov a systémových štatistík';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Pošlite príkazy opakovaču';

  @override
  String get repeater_neighbors => 'Súsezný';

  @override
  String get repeater_neighborsSubtitle => 'Zobraziť susedné body bez skokov.';

  @override
  String get repeater_settings => 'Nastavenia';

  @override
  String get repeater_settingsSubtitle => 'Konfigurujte parametre opakovača';

  @override
  String get repeater_statusTitle => 'Status opakého zboru';

  @override
  String get repeater_routingMode => 'Režim trasy';

  @override
  String get repeater_autoUseSavedPath => 'Použiť uloženú cestu';

  @override
  String get repeater_forceFloodMode =>
      'Zavrieť režim núdzového povodňového režimu';

  @override
  String get repeater_pathManagement => 'Správa trás';

  @override
  String get repeater_refresh => 'Obnoviť';

  @override
  String get repeater_statusRequestTimeout => 'Požiadavka stavu zlyhala.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Chyba pri načítaní stavu: $error';
  }

  @override
  String get repeater_systemInformation => 'Informácie o systéme';

  @override
  String get repeater_battery => 'Batéria';

  @override
  String get repeater_clockAtLogin => 'Čas (při přihlášení)';

  @override
  String get repeater_uptime => 'Dostupnosť';

  @override
  String get repeater_queueLength => 'Dĺžka fronty';

  @override
  String get repeater_debugFlags => 'Kontrolné značky';

  @override
  String get repeater_radioStatistics => 'Rádio Štatistiky';

  @override
  String get repeater_lastRssi => 'Posledná RSSI';

  @override
  String get repeater_lastSnr => 'Posledný SNR';

  @override
  String get repeater_noiseFloor => 'Hladina šumu';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistiky balíka';

  @override
  String get repeater_sent => 'Odoslané';

  @override
  String get repeater_received => 'Prišlo';

  @override
  String get repeater_duplicates => 'Duplikáty';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dní ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Celkem: $total, Povodňový režim: $flood, Priamy: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Celkem: $total, Povodňový režim: $flood, Priamy: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Pond: $flood, Priamy: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Celkem: $total';
  }

  @override
  String get repeater_settingsTitle => 'Nastavenia Opakovača';

  @override
  String get repeater_basicSettings => 'Základné nastavenia';

  @override
  String get repeater_repeaterName => 'Opakovacia názov';

  @override
  String get repeater_repeaterNameHelper => 'Zobrazenie názvu tohto opakovača';

  @override
  String get repeater_adminPassword => 'Heslo administrátora';

  @override
  String get repeater_adminPasswordHelper => 'Celý prístupový heslo';

  @override
  String get repeater_guestPassword => 'Heslo hosťa';

  @override
  String get repeater_guestPasswordHelper => 'Prístupový heslo iba na čítanie';

  @override
  String get repeater_radioSettings => 'Nastavenia rádia';

  @override
  String get repeater_frequencyMhz => 'Frekvencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Šírka pásma';

  @override
  String get repeater_spreadingFactor => 'Šírenie faktoru';

  @override
  String get repeater_codingRate => 'Rýchlosť kódovania';

  @override
  String get repeater_locationSettings => 'Nastavenia polohy';

  @override
  String get repeater_latitude => 'Súradnica';

  @override
  String get repeater_latitudeHelper => 'Desatinné zložky (napr. 37.7749)';

  @override
  String get repeater_longitude => 'Dĺžka';

  @override
  String get repeater_longitudeHelper => 'Desatinné zložky (napr. -122.4194)';

  @override
  String get repeater_features => 'Funkcie';

  @override
  String get repeater_packetForwarding => 'Riadenie prienikov';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Povolte opakovač na smerovanie paketov.';

  @override
  String get repeater_guestAccess => 'Prístup pre hostí';

  @override
  String get repeater_guestAccessSubtitle =>
      'Umožniť prístup hosta iba na čítanie.';

  @override
  String get repeater_privacyMode => 'Režim ochrany súkromia';

  @override
  String get repeater_privacyModeSubtitle => 'Skryť meno/poloha v reklamách';

  @override
  String get repeater_advertisementSettings => 'Nastavenia reklamy';

  @override
  String get repeater_localAdvertInterval => 'Lokálna reklamná časová obdoba';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minút';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Interval reklamnej povodňovej reklamy';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours hodín';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Šifrovaný reklamný interval';

  @override
  String get repeater_dangerZone => 'Nebezpečná zóna';

  @override
  String get repeater_rebootRepeater => 'Restart Repetér';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Resetovať vysielací prístroj';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ste si istý, že chcete tento opakovač restartovať?';

  @override
  String get repeater_regenerateIdentityKey => 'Generovať kľúč identity';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generovať nový pár verejných/privátnych kľúčov';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Toto vytvorí nový identitu pre opakovač. Pokračovať?';

  @override
  String get repeater_eraseFileSystem => 'Vymažať Systémový Reťazec';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formátovať systém opakujúcich sa súborov';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'VAROVANIE: Toto zmaže všetky dáta na opakovači. To sa nedá zrušiť!';

  @override
  String get repeater_eraseSerialOnly =>
      'Odstránenie je dostupné len cez sériové rozhranie.';

  @override
  String repeater_commandSent(String command) {
    return 'Poforovaný príkaz: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Chyba pri odeslaní príkazu: $error';
  }

  @override
  String get repeater_confirm => 'Potvrdiť';

  @override
  String get repeater_settingsSaved => 'Nastavenia boli uložené úspešne.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Chyba pri ukladaní nastavení: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Obnoviť základné nastavenia';

  @override
  String get repeater_refreshRadioSettings => 'Obnoviť Nastavenia Rádií';

  @override
  String get repeater_refreshTxPower => 'Obnoviť TX napájanie';

  @override
  String get repeater_refreshLocationSettings => 'Obnoviť Nastavenia Miesta';

  @override
  String get repeater_refreshPacketForwarding => 'Obnoviť smerovanie paketov';

  @override
  String get repeater_refreshGuestAccess => 'Obnoviť prístup hosťa';

  @override
  String get repeater_refreshPrivacyMode => 'Obnoviť Ochranný režim';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Obnoviť nastavenia reklamy';

  @override
  String repeater_refreshed(String label) {
    return '$label sa znova načítalo';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Chyba pri obnovení $label';
  }

  @override
  String get repeater_cliTitle => 'Opakovacia CLI';

  @override
  String get repeater_debugNextCommand => 'Oprava Nasledujúceho Príkaz';

  @override
  String get repeater_commandHelp => 'Pomoc';

  @override
  String get repeater_clearHistory => 'Vymazať históriu';

  @override
  String get repeater_noCommandsSent =>
      'Zatiaľ neboli odeslané žiadne príkazy.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Zadajte príkaz nižšie alebo použite rýchle príkazy';

  @override
  String get repeater_enterCommandHint => 'Zadajte príkaz...';

  @override
  String get repeater_previousCommand => 'Predchádzajúci príkaz';

  @override
  String get repeater_nextCommand => 'Nasledujúci príkaz';

  @override
  String get repeater_enterCommandFirst => 'Zadajte najprv príkaz';

  @override
  String get repeater_cliCommandFrameTitle => 'Rámok Príkaz CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Zísť meno';

  @override
  String get repeater_cliQuickGetRadio => 'Zísť po rádiu';

  @override
  String get repeater_cliQuickGetTx => 'Zísť TX';

  @override
  String get repeater_cliQuickNeighbors => 'Súsezný';

  @override
  String get repeater_cliQuickVersion => 'Verzia';

  @override
  String get repeater_cliQuickAdvertise => 'Reklama';

  @override
  String get repeater_cliQuickClock => 'Hodiny';

  @override
  String get repeater_cliHelpAdvert => 'Odosiela reklamnú balíček.';

  @override
  String get repeater_cliHelpReboot =>
      'Resetuje zariadenie. (pozor, môže dôjsť k \'Timeoutu\', čo je normálne)';

  @override
  String get repeater_cliHelpClock =>
      'Zobrazuje aktuálny čas podľa hodiniek zariadenia.';

  @override
  String get repeater_cliHelpPassword =>
      'Nastaví nový administrátorský prístupový údaj pre zariadenie.';

  @override
  String get repeater_cliHelpVersion =>
      'Zobrazuje verziu zariadenia a dátum zostavenia firmvéru.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resetuje rôzne štatistické počítadlá na nulu.';

  @override
  String get repeater_cliHelpSetAf => 'Nastavuje časový faktor.';

  @override
  String get repeater_cliHelpSetTx =>
      'Nastavenie vysielacej sily LoRa v dBm. (potrebuje sa reštart na aplikáciu)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Umožňuje alebo vypína zopakovaný príspevok pre tento uzol.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Server miestnosti) Ak je \'zapnuté\', potom bude povolený prístup s prázdnym heslom, ale nebude možné posielať správu do miestnosti. (iba čítať).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Nastavuje maximálny počet skokov pre vstupný povelový paket (ak je >= max, paket nie je preposlaný)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Nastavuje hranicu ruživeho ladenia (v dB). Predvolené je 14. Nastavením na 0 sa vypne detekcia ruživeho ladenia kanálu.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Nastavuje interval na reštartovanie Auto Gain Controlleru. Nastavenie na 0 vypne funkciu.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Povolí alebo pozastaví funkciiu \"dvojité potvrdenia\".';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Nastavuje interval časovača v minútach na odošle miestny (bezprostredný) reklamný paket. Nastavenie na 0 vypne funkciu.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Nastavuje interval časovača v hodinách na odeslanie reklamnej vlne. Nastavenie na 0 vypne.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Nastavuje/aktualizuje heslo hosťa. (pre opakované pripojenia môžu hosťovské prihlásenia posielať požadanie \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Nastaví názov reklamy.';

  @override
  String get repeater_cliHelpSetLat =>
      'Nastaví geografickú šírku reklamnej mapy. (desatinné stupne)';

  @override
  String get repeater_cliHelpSetLon =>
      'Nastavuje longitudinu reklamnej mapy. (desatinné stupne)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Nastavuje úplne nové parametre rádia a uloží ich do preferencií. Požaduje príkaz \"reboot\" na aplikáciu.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Nastavenia (experimentálne) základné (musi byť > 1 pre účel) na aplikáciu mierneho onesenia prijatých paketov, na základe signálu/skóre. Nastavenie na 0 vypne.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Nastavuje faktor násobený časom na vzduchu pre paket v režime povodňovej vlny a s náhodným systémom slotov, aby sa oneskorene jeho prenosovanie (s cieľom znížiť pravdepodobnosť kolízii).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Podobne ako txdelay, ale pre aplikáciu náhodného oneskorenia pri preposlaní paketov v režime priameho prenosu.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Aktivovať/Zatvárať most.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Nastaviť odklad pred retransmisiou paketov.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Zvolte, či bude most retransmitovať prijaté alebo vysielané balíčky.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Nastavte sériový link baudrate pre rs232 mosty.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Nastaviť tajomstvo mosta pre eshnow mosty.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Nastavuje vlastný faktor na úpravu nahlásenej batériovej napätia (podporované len na vybraných doskách).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Nastaví dočasné rádiové parametre pre zadaný počet minút, po skončení sa vráti k pôvodným rádiovým parametrom. (nepočuva sa do preferencií).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Zmení ACL. Odstráni zodpovedný záznam (podľa prefixa pubkey), ak je \"permissions\" rovné 0. Pridá nový záznam, ak je pubkey-hex plnej dĺžky a momentálne sa nenachádza v ACL. Aktualizuje záznam podľa zodpovedajúceho prefixa pubkey. Bitové oprávnenia sa líšia podľa funkčnej roly, ale nízke 2 bity sú: 0 (Hostiteľ), 1 (Čítanie len), 2 (Čítanie a zápis), 3 (Správca).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Zísť typ mosta: žiadny, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Začína protokolovanie balíkov do systému súborov.';

  @override
  String get repeater_cliHelpLogStop =>
      'Zastaví protokolovanie paketov do systémového súboru.';

  @override
  String get repeater_cliHelpLogErase =>
      'Odstráni záznamy z balíkov z systému súborov.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Zobrazuje zoznam iných repeaterových uzlov zasielaných cez zero-hop reklamy. Každý riadok je id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Odstráni prvú zhodujúcu položku (podľa prefixu pubkey (hex)) z zoznamu susedov.';

  @override
  String get repeater_cliHelpRegion =>
      '(len sériál) Zobrazuje všetky definované regióny a aktuálne povolenia pre povodňové situácie.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Poznámka: toto je špeciálna multi-príkázová inštancia. Každé nasledujúce príkaza je názov oblasti (zapustený s medzerami na indikáciu hierarchického pomeru, s minimálne jednou medzerou). Ukončené odeslaním prázdnej platnej linky/príkazu.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Hľadá región s daným príponou názvu (alebo \"\\\" pre globálny rozsah). Odpovedá \"-> región-název (rodič-název) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Pridá alebo aktualizuje definíciu regiónu s daným menom.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Odstráni definíciu oblasti s daným názvom. (musí zodpovedať presne a nemala by mať podoblasti)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Nastavuje povolenie \'P\'lávu pre zadanú oblasť. (\'\' pre globálny/dedičský rozsah)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Odstráni povolenie \'F\'lood\' pre zadanú oblasť. (UPOZORNENIE: v tejto fáze nie je odporúčané ho používať na globálnom/dedskom rozsahu!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odpovedá s aktuálnou \'domovskou\' oblasťou. (Poznámka aplikovaná zatiaľ nikde, vyhradené na budúce)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Nastaví \'domovskú\' oblasť.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Uloží zoznam/mapu regiónov do úložiska.';

  @override
  String get repeater_cliHelpGps =>
      'Zobrazuje stav GPS. Ak je GPS vypnutý, odpovedá len \"off\", ak je zapnutý, odpovedá s \"on\", stavom, fixom a počtom satelitov.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Prepínač stavu GPS napájania.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronizuje čas uzla s GPS hodinami.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Nastaví polohu uzla na GPS súradnice a uloží preferencie.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Poskytuje konfiguráciu reklamy pre uzol:\n- žiadna: nezahrňte polohu do reklám\n- zdieľať: zdieľajte GPS polohu (z SensorManager)\n- nastavenia: zobrazujte polohu uloženú v nastaveniach';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Nastavuje konfiguráciu reklamy na zadané miesto.';

  @override
  String get repeater_commandsListTitle => 'Zoznam príkazov';

  @override
  String get repeater_commandsListNote =>
      'Poznámka: pre rôzne príkazy \"set ...\" existuje aj príkaz \"get ...\".';

  @override
  String get repeater_general => 'Obecné';

  @override
  String get repeater_settingsCategory => 'Nastavenia';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Záznamy';

  @override
  String get repeater_neighborsRepeaterOnly => 'Súseznýci (iba opakovač)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Správa regiónov (iba opakovač)';

  @override
  String get repeater_regionNote =>
      'Regionové príkazy boli zavádzané na správu regionálnych definícií a oprávnení.';

  @override
  String get repeater_gpsManagement => 'Správa GPS';

  @override
  String get repeater_gpsNote =>
      'GPS príkaz bol zavádzaný na riadenie lokalitných tém.';

  @override
  String get telemetry_receivedData => 'Obdolené Telemetrické dáta';

  @override
  String get telemetry_requestTimeout => 'Požiadavka telemetrie zlyhala.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Chyba pri načítaní telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Nejsú dostupné žiadne údaje z telemetrie.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanál $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batéria';

  @override
  String get telemetry_voltageLabel => 'Napätie';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU teplota';

  @override
  String get telemetry_temperatureLabel => 'Teplota';

  @override
  String get telemetry_currentLabel => 'Aktuálne';

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
  String get neighbors_receivedData => 'Obdielo dáta suseda';

  @override
  String get neighbors_requestTimedOut => 'Súďia žiadajú o časové ukončenie.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Chyba pri načítaní susedov: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Opakovadlá Súsezná';

  @override
  String get neighbors_noData =>
      'Nie je dostupná žiadna informácia o susedoch.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Neznáma $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Počuli sme to: $time dozadu';
  }

  @override
  String get channelPath_title => 'Cesta balíka';

  @override
  String get channelPath_viewMap => 'Zobraziť mapu';

  @override
  String get channelPath_otherObservedPaths => 'Ostatné pozorovacie cesty';

  @override
  String get channelPath_repeaterHops => 'Skoky opakovača';

  @override
  String get channelPath_noHopDetails =>
      'Podrobnosti o balíčku zatiaľ nie sú dostupné.';

  @override
  String get channelPath_messageDetails => 'Podrobnosti o zprávach';

  @override
  String get channelPath_senderLabel => 'Posielateľ';

  @override
  String get channelPath_timeLabel => 'Čas';

  @override
  String get channelPath_repeatsLabel => 'Opakovanie';

  @override
  String channelPath_pathLabel(int index) {
    return 'Cesta $index';
  }

  @override
  String get channelPath_observedLabel => 'Pozorované';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Sledovaný postup $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Žiadne údaje o polohe';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Neznáme';

  @override
  String get channelPath_floodPath => 'Povodňová';

  @override
  String get channelPath_directPath => 'Priamo';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 z $total skokov';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed z $total skokov';
  }

  @override
  String get channelPath_mapTitle => 'Mapa Trasy';

  @override
  String get channelPath_noRepeaterLocations =>
      'Pre túto cestu nie je dostupných žiadne polohy opakovačov.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Cesta $index (Hlavná)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Cesta';

  @override
  String get channelPath_observedPathHeader => 'Sledovaná cesta';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Pre toto balíček nie sú dostupné údaje o skokoch.';

  @override
  String get channelPath_unknownRepeater => 'Neznáme opakovače';

  @override
  String get community_title => 'Komunita';

  @override
  String get community_create => 'Vytvoriť komunitu';

  @override
  String get community_createDesc =>
      'Vytvorte novú komunitu a zdieľajte cez QR kód.';

  @override
  String get community_join => 'Pripojiť';

  @override
  String get community_joinTitle => 'Pripojiť sa k spoločenstvu';

  @override
  String community_joinConfirmation(String name) {
    return 'Chceš sa pridať do komunity \"$name\"?';
  }

  @override
  String get community_scanQr => 'Skontrolujte komunitný QR kód';

  @override
  String get community_scanInstructions =>
      'Zamerte kameru na komunitný QR kód.';

  @override
  String get community_showQr => 'Zobraziť QR kód';

  @override
  String get community_publicChannel => 'Komunita verejná';

  @override
  String get community_hashtagChannel => 'Komunitný Hashtag';

  @override
  String get community_name => 'Komunita';

  @override
  String get community_enterName => 'Zadajte názov komunity';

  @override
  String community_created(String name) {
    return 'Komunita \"$name\" vytvorená';
  }

  @override
  String community_joined(String name) {
    return 'Pripojená komunita \"$name\"';
  }

  @override
  String get community_qrTitle => 'Zdieľť komunitu';

  @override
  String community_qrInstructions(String name) {
    return 'Skenejte tento QR kód, aby ste sa pripojili k $name.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Hashtagové kanály komunity sú prístupné len členom komunity';

  @override
  String get community_invalidQrCode => 'Neplatná QR kód komunity.';

  @override
  String get community_alreadyMember => 'Už ste členom.';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Vy ste už členom \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Pridať verejný komunikačný kanál';

  @override
  String get community_addPublicChannelHint =>
      'Automaticky prida verejný kanál pre túto komunitu.';

  @override
  String get community_noCommunities =>
      'Zatiaľ ste sa nepripojili k žiadnej komunite';

  @override
  String get community_scanOrCreate =>
      'Skene QR kód alebo vytvor komunitu na začiatok.';

  @override
  String get community_manageCommunities => 'Spravovať komunity';

  @override
  String get community_delete => 'Nechajte komunitu';

  @override
  String community_deleteConfirm(String name) {
    return 'Opustiť \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Tým sa tiež vymaže $count kanál/kanálov a ich správy.';
  }

  @override
  String community_deleted(String name) {
    return 'Opustená komunita \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Zobraziť nový tajný kód';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Znovu vygenerovať tajný kľúč pre \"$name\"? Všetci členovia budú musieť skanovať nový QR kód, aby mohli nadviazať komunikáciu.';
  }

  @override
  String get community_regenerate => 'Znovu vygenerovať';

  @override
  String community_secretRegenerated(String name) {
    return 'Záznam pre \"$name\" bol regenerovaný tajne';
  }

  @override
  String get community_updateSecret => 'Aktualizovať tajné heslo';

  @override
  String community_secretUpdated(String name) {
    return 'Zmena tajnej slova pre \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Skáňte nový QR kód na aktualizáciu tajného hesla pre \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Pridať komunitný hashtag';

  @override
  String get community_addHashtagChannelDesc =>
      'Pridajte hashtagový kanál pre túto komunitu.';

  @override
  String get community_selectCommunity => 'Vyberte komunitu';

  @override
  String get community_regularHashtag => 'Zvyčajný hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Veľký hashtag (ktočokoľvek sa môže pridať)';

  @override
  String get community_communityHashtag => 'Komunitný Hashtag';

  @override
  String get community_communityHashtagDesc => 'Špecifické pre členov komunity';

  @override
  String community_forCommunity(String name) {
    return 'Pre $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrovať a triediť';

  @override
  String get listFilter_sortBy => 'Triediť podľa';

  @override
  String get listFilter_latestMessages => 'Posledné správy';

  @override
  String get listFilter_heardRecently => 'Nedávno počuli.';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtre';

  @override
  String get listFilter_all => 'Všetko';

  @override
  String get listFilter_favorites => 'Obľúbené';

  @override
  String get listFilter_addToFavorites => 'Pridaj do obľúbených';

  @override
  String get listFilter_removeFromFavorites => 'Odstrániť z označení';

  @override
  String get listFilter_users => 'Používatelia';

  @override
  String get listFilter_repeaters => 'Opakovadlá';

  @override
  String get listFilter_roomServers => 'Servéry miestnosti';

  @override
  String get listFilter_unreadOnly => 'Nezaregistrované len';

  @override
  String get listFilter_newGroup => 'Nová skupina';

  @override
  String get pathTrace_you => 'Vy';

  @override
  String get pathTrace_failed => 'Sledovanie cesty zlyhalo.';

  @override
  String get pathTrace_notAvailable => 'Path trace nie je k dispozícii.';

  @override
  String get pathTrace_refreshTooltip => 'Obnoviť Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Jedna alebo viac chmeľov chýba lokalita!';

  @override
  String get pathTrace_clearTooltip => 'Zmazať cestu';

  @override
  String get losSelectStartEnd => 'Vyberte počiatočný a koncový uzol pre LOS.';

  @override
  String losRunFailed(String error) {
    return 'Kontrola priamej viditeľnosti zlyhala: $error';
  }

  @override
  String get losClearAllPoints => 'Vymazať všetky body';

  @override
  String get losRunToViewElevationProfile =>
      'Ak chcete zobraziť výškový profil, spustite LOS';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Klepnutím na uzly alebo dlhým stlačením mapy získate vlastné body';

  @override
  String get losShowDisplayNodes => 'Zobraziť uzly zobrazenia';

  @override
  String get losCustomPoints => 'Vlastné body';

  @override
  String losCustomPointLabel(int index) {
    return 'Vlastné $index';
  }

  @override
  String get losPointA => 'Bod A';

  @override
  String get losPointB => 'Bod B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Anténa A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Anténa B: $value $unit';
  }

  @override
  String get losRun => 'Spustite LOS';

  @override
  String get losNoElevationData => 'Žiadne údaje o nadmorskej výške';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, vymazať LOS, min. vôľa $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blokovaný $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: kontrolujem...';

  @override
  String get losStatusNoData => 'LOS: žiadne údaje';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total vymazané, $blocked blokované, $unknown neznáme';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Údaje o nadmorskej výške nie sú k dispozícii pre jednu alebo viacero vzoriek.';

  @override
  String get losErrorInvalidInput =>
      'Neplatné body/údaje o nadmorskej výške pre výpočet LOS.';

  @override
  String get losRenameCustomPoint => 'Premenovať vlastný bod';

  @override
  String get losPointName => 'Názov bodu';

  @override
  String get losShowPanelTooltip => 'Zobraziť panel LOS';

  @override
  String get losHidePanelTooltip => 'Skryť panel LOS';

  @override
  String get losElevationAttribution =>
      'Údaje o nadmorskej výške: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Rádiový horizont';

  @override
  String get losLegendLosBeam => 'Priama viditeľnosť';

  @override
  String get losLegendTerrain => 'Terén';

  @override
  String get losFrequencyLabel => 'Frekvencia';

  @override
  String get losFrequencyInfoTooltip => 'Zobraziť podrobnosti výpočtu';

  @override
  String get losFrequencyDialogTitle => 'Výpočet rádiového horizontu';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Počnúc od k=$baselineK pri $baselineFreq MHz výpočet upraví k-faktor pre aktuálne pásmo $frequencyMHz MHz, ktorý definuje zakrivený strop rádiového horizontu.';
  }

  @override
  String get contacts_pathTrace => 'Sledovanie lúčov';

  @override
  String get contacts_ping => 'Pingovať';

  @override
  String get contacts_repeaterPathTrace => 'Sledovanie cesty k opakovaču';

  @override
  String get contacts_repeaterPing => 'Pingovať opakovač';

  @override
  String get contacts_roomPathTrace => 'Sledovanie cesty k serveru miestnosti';

  @override
  String get contacts_roomPing => 'Ping server miestnosti';

  @override
  String get contacts_chatTraceRoute => 'Sledovať trasu lúča';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Sledovať trasu k $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Schránka je prázdna.';

  @override
  String get contacts_invalidAdvertFormat => 'Neplatné kontaktné údaje';

  @override
  String get contacts_contactImported => 'Kontakt bol importovaný.';

  @override
  String get contacts_contactImportFailed =>
      'Kontakt sa nepodarilo importovať.';

  @override
  String get contacts_zeroHopAdvert => 'Inzerát Zero Hop';

  @override
  String get contacts_floodAdvert => 'Inzerát povodní';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopírovať reklamu do schránky';

  @override
  String get contacts_addContactFromClipboard => 'Pridať kontakt z schránky';

  @override
  String get contacts_ShareContact => 'Kopírovať kontakt do schránky';

  @override
  String get contacts_ShareContactZeroHop => 'Zdieľať kontakt cez inzerát';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Poslal kontakt cez inzerát.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Zlyhalo odoslanie kontaktu.';

  @override
  String get contacts_contactAdvertCopied =>
      'Inzerát bol skopírovaný do schránky.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopírovanie inzerátu do schránky zlyhalo.';

  @override
  String get notification_activityTitle => 'Aktivita MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'správ',
      few: 'správy',
      one: 'správa',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'správ kanálu',
      few: 'správy kanálu',
      one: 'správa kanálu',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nových uzlov',
      few: 'nové uzly',
      one: 'nový uzol',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nový $contactType objavený';
  }

  @override
  String get notification_receivedNewMessage => 'Prijatá nová správa';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportovať repeater / server miestnosti do GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportuje repeater / roomserver s lokalitou do súboru GPX.';

  @override
  String get settings_gpxExportContacts => 'Export sprievodcov do GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exportuje sprievodcov s umiestnením do súboru GPX.';

  @override
  String get settings_gpxExportAll => 'Exportovať všetky kontakty do GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exportuje všetky kontakty s lokalitou do súboru GPX.';

  @override
  String get settings_gpxExportSuccess => 'Úspešne exportovaný súbor GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Žiadne kontakty na export.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nie je podporované na vašom zariadení/operáciomnom systéme';

  @override
  String get settings_gpxExportError => 'Vyskytol sa chyba počas exportu.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Umiestnenia opakovačov a serverov miestností';

  @override
  String get settings_gpxExportChat => 'Lokácie sprievodcov';

  @override
  String get settings_gpxExportAllContacts => 'Všetky kontaktné lokality';

  @override
  String get settings_gpxExportShareText =>
      'Mapové údaje exportované z meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open export dát GPX mapových údajov';

  @override
  String get snrIndicator_nearByRepeaters => 'Miestne opakovače';

  @override
  String get snrIndicator_lastSeen => 'Naposledy videný';

  @override
  String get contactsSettings_title => 'Nastavenia kontaktov';

  @override
  String get contactsSettings_autoAddTitle => 'Automatické zisťovanie';

  @override
  String get contactsSettings_otherTitle =>
      'Ďalšie nastavenia súvisiace s kontaktami';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automaticky pridávať užívateľov';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Povoliť spoločníkovi automaticky pridávať objavených užívateľov.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automaticky pridávať opakovače';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Povoliť spoločníkovi automaticky pridávať objavené repeater.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automaticky pridávať server miestnosti';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Povoliť spoločníkovi automaticky pridať objavené serverové miestnosti.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automaticky pridávať senzory';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Povoliť spoločníkovi automaticky pridávať objavené senzory.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Prepísať najstaršie';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Keď je zoznam kontaktov plný, bude nahradený najstarší neoznačený kontakt.';

  @override
  String get discoveredContacts_Title => 'Objavené kontakty';

  @override
  String get discoveredContacts_noMatching => 'Žiadne zhodné kontakty';

  @override
  String get discoveredContacts_searchHint => 'Vyhľadať objavené kontakty';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt bol pridaný';

  @override
  String get discoveredContacts_addContact => 'Pridať kontakt';

  @override
  String get discoveredContacts_copyContact => 'Kopírovať kontakt do schránky';

  @override
  String get discoveredContacts_deleteContact => 'Zmazať kontakt';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Zmazať všetky objavené kontakty';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Ste si istí, že chcete zmazať všetky objavené kontakty?';
}
