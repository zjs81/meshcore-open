// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Stiki';

  @override
  String get nav_channels => 'Kanali';

  @override
  String get nav_map => 'Karta';

  @override
  String get common_cancel => 'Prekliči';

  @override
  String get common_ok => 'V redu';

  @override
  String get common_connect => 'Poveži se';

  @override
  String get common_unknownDevice => 'Nepoznano naprave';

  @override
  String get common_save => 'Shrani';

  @override
  String get common_delete => 'Izbrisati';

  @override
  String get common_deleteAll => 'Izbriši vse';

  @override
  String get common_close => 'Zapri';

  @override
  String get common_edit => 'Uredi';

  @override
  String get common_add => 'Dodaj';

  @override
  String get common_settings => 'Nastavitve';

  @override
  String get common_disconnect => 'Odklopiti';

  @override
  String get common_connected => 'Povezano';

  @override
  String get common_disconnected => 'Odprto';

  @override
  String get common_create => 'Ustvari';

  @override
  String get common_continue => 'Poudarki';

  @override
  String get common_share => 'Deliti';

  @override
  String get common_copy => 'Kopiraj';

  @override
  String get common_retry => 'Ponoviti';

  @override
  String get common_hide => 'Skrita';

  @override
  String get common_remove => 'Izbrisati';

  @override
  String get common_enable => 'Omogoči';

  @override
  String get common_disable => 'Izklopiti';

  @override
  String get common_reboot => 'Ponoviti';

  @override
  String get common_loading => 'Naložanje...';

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
  String get usbScreenTitle => 'Povežite preko USB';

  @override
  String get usbScreenSubtitle =>
      'Izberite zaznano serijsko napravo in se neposredno povežite z vašo MeshCore napravo.';

  @override
  String get usbScreenStatus => 'Izberite USB naprave';

  @override
  String get usbScreenNote =>
      'USB serijska povezava je aktivna na podprtih napravah Android in na desktop platformah.';

  @override
  String get usbScreenEmptyState =>
      'Niti en USB naprave niso najdeni. Povežite eno in posodobite.';

  @override
  String get usbErrorPermissionDenied =>
      'Dovoljenje za dostop preko USB-ja je bilo zavrnjeno.';

  @override
  String get usbErrorDeviceMissing => 'Izbrani USB napravej je več ne.';

  @override
  String get usbErrorInvalidPort => 'Izberite veljavno USB naprave.';

  @override
  String get usbErrorBusy => 'Že je v teku zahteva za povezavo preko USB.';

  @override
  String get usbErrorNotConnected => 'Ni priklopljenih USB naprave.';

  @override
  String get usbErrorOpenFailed =>
      'Uspešno ni bilo mogo, da se odpre izbran naprave USB.';

  @override
  String get usbErrorConnectFailed =>
      'Niso bilo mogoče uskladiti povezave z izbranim USB napom.';

  @override
  String get usbErrorUnsupported =>
      'USB serijska komunikacija ni podprta na tej platformi.';

  @override
  String get usbErrorAlreadyActive => 'USB povezava je že aktivirana.';

  @override
  String get usbErrorNoDeviceSelected => 'Ni bilo izbranega USB naprave.';

  @override
  String get usbErrorPortClosed => 'USB povezava ni aktivirana.';

  @override
  String get usbErrorConnectTimedOut =>
      'Vzpostavitve ni bilo mogo. Prosimo, da se prepričate, da ima naprave trenutno nameštan firmware USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Naprave za serijsko komunikacijo preko spleta';

  @override
  String get usbStatus_notConnected => 'Izberite USB naprave.';

  @override
  String get usbStatus_connecting => 'Povezava z USB napravo...';

  @override
  String get usbStatus_searching => 'Iskanje USB naprav...';

  @override
  String usbConnectionFailed(String error) {
    return 'Napaka pri povezavi preko USB: $error';
  }

  @override
  String get scanner_scanning => 'Skeniram za naprave...';

  @override
  String get scanner_connecting => 'Povezujem se...';

  @override
  String get scanner_disconnecting => 'Odklapljam se...';

  @override
  String get scanner_notConnected => 'Nezavezan';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Povezan s $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Iskanje naprav MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Nagneš na skeniranje za najdene naprave MeshCore.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Pošlo je z povezavo: $error';
  }

  @override
  String get scanner_stop => 'Prekliči';

  @override
  String get scanner_scan => 'Skeniraj';

  @override
  String get scanner_bluetoothOff => 'Bluetooth je izklopljen';

  @override
  String get scanner_bluetoothOffMessage =>
      'Prosimo, vklopite Bluetooth, da lahko poiščete naprave.';

  @override
  String get scanner_chromeRequired => 'Zahtevan brskalnik Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Ta spletna aplikacija za podporo Bluetooth zahteva Google Chrome ali brskalnik na osnovi Chromiuma.';

  @override
  String get scanner_enableBluetooth => 'Omogočite Bluetooth';

  @override
  String get device_quickSwitch => 'Hitro preklop';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Nastavitve';

  @override
  String get settings_deviceInfo => 'Informacije o napravei';

  @override
  String get settings_appSettings => 'Nastavitve aplikacije';

  @override
  String get settings_appSettingsSubtitle =>
      'Obveščanja, sporoščanje in zemljevidi.';

  @override
  String get settings_nodeSettings => 'Nastavitev časa';

  @override
  String get settings_nodeName => 'Ime node-a';

  @override
  String get settings_nodeNameNotSet => 'Ni nastavljeno';

  @override
  String get settings_nodeNameHint => 'Vnesite ime node-a';

  @override
  String get settings_nodeNameUpdated => 'Ime posodobljeno';

  @override
  String get settings_radioSettings => 'Nastavitve radija';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvenca, moč, razširitveni faktor';

  @override
  String get settings_radioSettingsUpdated => 'Radio nastavitve posodobljene';

  @override
  String get settings_location => 'Lokacija';

  @override
  String get settings_locationSubtitle => 'GPS koordinate';

  @override
  String get settings_locationUpdated => 'Lokacija posodobljena';

  @override
  String get settings_locationBothRequired => 'Vnesite širino in dolžino.';

  @override
  String get settings_locationInvalid =>
      'Neveljavna zemeljska širina ali dolžina.';

  @override
  String get settings_locationGPSEnable => 'Omogoči GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Omogoči samodejno posodabljanje lokacije z GPS-jem.';

  @override
  String get settings_locationIntervalSec => 'Interval za GPS (Sekunde)';

  @override
  String get settings_locationIntervalInvalid =>
      'Intervallo mora biti vsaj 60 sekund in manj kot 86400 sekund.';

  @override
  String get settings_latitude => 'Širina';

  @override
  String get settings_longitude => 'Dolžina';

  @override
  String get settings_contactSettings => 'Nastavitve stika';

  @override
  String get settings_contactSettingsSubtitle =>
      'Nastavitve za dodajanje stikov.';

  @override
  String get settings_privacyMode => 'Zasebnost';

  @override
  String get settings_privacyModeSubtitle => 'Skrita imena/lokacije v oglasih';

  @override
  String get settings_privacyModeToggle =>
      'Omogoči način zasebnosti, da skrijemo tvoje ime in lokacijo v oglasih.';

  @override
  String get settings_privacyModeEnabled => 'Privatni način je omogočen.';

  @override
  String get settings_privacyModeDisabled => 'Privatni način je onemogočen.';

  @override
  String get settings_actions => 'Akcije';

  @override
  String get settings_sendAdvertisement => 'Pošlji Oglas';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Trenutna prisotnost v oddajah';

  @override
  String get settings_advertisementSent => 'Oglas poslan';

  @override
  String get settings_syncTime => 'Nastavi uro';

  @override
  String get settings_syncTimeSubtitle => 'Nastavi uro naprave na čas telefona';

  @override
  String get settings_timeSynchronized => 'Ura sinhronizirana';

  @override
  String get settings_refreshContacts => 'Ponovno obišči kontakte';

  @override
  String get settings_refreshContactsSubtitle =>
      'Ponovno naloži seznam stikov v napravi';

  @override
  String get settings_rebootDevice => 'Ponovni zagon naprave';

  @override
  String get settings_rebootDeviceSubtitle => 'Ponovno zaženi MeshCore napravo';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ste prepričani, da želite ponovno zagnati napravo? Povezava bo prekinjena.';

  @override
  String get settings_debug => 'Debug';

  @override
  String get settings_bleDebugLog => 'BLE debug log (razhroščevanje)';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE ukazi, odgovori in surovi podatki';

  @override
  String get settings_appDebugLog => 'Logi aplikacije';

  @override
  String get settings_appDebugLogSubtitle => 'Debug sporočila aplikacije';

  @override
  String get settings_about => 'Oglejte si';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => 'Odprtokodni projekt MeshCore 2024';

  @override
  String get settings_aboutDescription =>
      'Odprtokodni Flutter klient za naprave za LoRa omrežje MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Podatki o višini LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Ime';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Baterija';

  @override
  String get settings_infoPublicKey => 'Javni ključ';

  @override
  String get settings_infoContactsCount => 'Število stikov';

  @override
  String get settings_infoChannelCount => 'Število kanalov';

  @override
  String get settings_presets => 'Prednastavitve';

  @override
  String get settings_frequency => 'Frekvenca (MHz)';

  @override
  String get settings_frequencyHelper => '300,00 - 2500,00';

  @override
  String get settings_frequencyInvalid => 'Neveljavna frekvenca (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Pasovna širina';

  @override
  String get settings_spreadingFactor => 'Razširitveni faktor';

  @override
  String get settings_codingRate => 'Programska hitrost';

  @override
  String get settings_txPower => 'TX Moč (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Neveljavna TX moč (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Neovadno ponavljanje';

  @override
  String get settings_clientRepeatSubtitle =>
      'Omogočite temu naprave, da ponavlja paketne sporočila za druge.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Za ponovni prenos na brezžični način so potrebne frekvence 433, 869 ali 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Napaka: $message';
  }

  @override
  String get appSettings_title => 'Nastavitve aplikacije';

  @override
  String get appSettings_appearance => 'Prikaži';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Sistemska tema';

  @override
  String get appSettings_themeLight => 'Svetlo';

  @override
  String get appSettings_themeDark => 'Temno';

  @override
  String get appSettings_language => 'Jezik';

  @override
  String get appSettings_languageSystem => 'Sistemska privzeta vrednost';

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
  String get appSettings_languageRu => 'Ruščina';

  @override
  String get appSettings_languageUk => 'Ukrajinsko';

  @override
  String get appSettings_enableMessageTracing => 'Omogoči sledenje sporočilom';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Prikaži podrobne metapodatke o usmerjanju in časovnem usklajevanju sporočil';

  @override
  String get appSettings_notifications => 'Obvestila';

  @override
  String get appSettings_enableNotifications => 'Omogoči obvestila';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Prejmite obvestila o sporočilih in oglasih';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Odobritev obvestila zavrnjena';

  @override
  String get appSettings_notificationsEnabled => 'Obvestila omogočena';

  @override
  String get appSettings_notificationsDisabled => 'Obvestila so izklopljena';

  @override
  String get appSettings_messageNotifications => 'Obvestila';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Pokaži obvestilo ob prejemu novih sporočil.';

  @override
  String get appSettings_channelMessageNotifications =>
      'Obvestila o sporočilih kanala';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Pokaži obvestilo ob prejemanju sporočil kanala';

  @override
  String get appSettings_advertisementNotifications => 'Opozorila o oglasih';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Pokaži obvestilo, ko so najdene nove naprave.';

  @override
  String get appSettings_messaging => 'Komuniciranje';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Ponovite pot do cilja na največjem štetju';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Ponovi pot zimske obveščevalne poti po 5 neuspešnih poskusih pošiljanja';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Počisti pot po 5 neuspešnih poskusih.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Poti ne bodo samodejno čiščene.';

  @override
  String get appSettings_autoRouteRotation =>
      'Avtomatsko rotacija prenosne poti';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Menjaj med boljšo potjo in flood načinom';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Samodejno krmilno rotiranje omogočeno';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Samodejno krmilno rotiranje je onemogočeno';

  @override
  String get appSettings_battery => 'Baterija';

  @override
  String get appSettings_batteryChemistry => 'Kemija baterije';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Nastavitev za napravo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Za izbiro se poveži z napravo';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Prikaz zemljevida';

  @override
  String get appSettings_showRepeaters => 'Prikaži repetitorje';

  @override
  String get appSettings_showRepeatersSubtitle => 'Prikaži repetitorje na mapi';

  @override
  String get appSettings_showChatNodes => 'Prikaži naprave za klepet';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Prikaži naprave na zemljevidu';

  @override
  String get appSettings_showOtherNodes => 'Pokaži druge naprave';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Pokaži druge vrste naprav na zemljevidu.';

  @override
  String get appSettings_timeFilter => 'Filter po času';

  @override
  String get appSettings_timeFilterShowAll => 'Pokaži vse naprave';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Pokaži naprave v zadnjih $hours urah';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filter časa na zemljevidu';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Pokaži naprave odkrite v:';

  @override
  String get appSettings_allTime => 'Brez omejitev';

  @override
  String get appSettings_lastHour => 'V zadnji uri';

  @override
  String get appSettings_last6Hours => 'Zadnjih 6 ur';

  @override
  String get appSettings_last24Hours => 'Zadnjih 24 ur';

  @override
  String get appSettings_lastWeek => 'Prejšnji teden';

  @override
  String get appSettings_offlineMapCache => 'Shramba zemljevidov brez povezave';

  @override
  String get appSettings_unitsTitle => 'Enote';

  @override
  String get appSettings_unitsMetric => 'Metrična (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperialno (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Območje ni izbrano';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Izbrano območje (povečava $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Razhroščevanje';

  @override
  String get appSettings_appDebugLogging => 'Programski dnevnik';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Dnevnik debug sporočil za odpravljanje težav';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Beleženje napak v aplikaciji omogočeno';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Beleženje napak v aplikacije onemogočeno.';

  @override
  String get contacts_title => 'Stiki';

  @override
  String get contacts_noContacts => 'Ni stikov.';

  @override
  String get contacts_contactsWillAppear =>
      'Stiki se bodo prikazali, ko se naprave oglasijo.';

  @override
  String get contacts_unread => 'Neprebrano';

  @override
  String get contacts_searchContactsNoNumber => 'Iskanje stikov...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Iskanje stikov...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Iskanje $number$str priljubljenih...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Išči $number$str uporabnikov...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Išči $number$str ponavljalnike...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Išči $number$str strežnikov sob...';
  }

  @override
  String get contacts_noUnreadContacts => 'Ne prebrani stiki.';

  @override
  String get contacts_noContactsFound => 'Stiki niso najdeni.';

  @override
  String get contacts_deleteContact => 'Izbriši stik';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Izbrišem $contactName iz stikov?';
  }

  @override
  String get contacts_manageRepeater => 'Upravljaj Ponovitve';

  @override
  String get contacts_manageRoom => 'Upravljajte strežnik sobe';

  @override
  String get contacts_roomLogin => 'Prijava v sobo';

  @override
  String get contacts_openChat => 'Odpri klepet';

  @override
  String get contacts_editGroup => 'Uredi skupino';

  @override
  String get contacts_deleteGroup => 'Izbriši skupino';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Izbriši $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nova skupina';

  @override
  String get contacts_groupName => 'Ime skupine';

  @override
  String get contacts_groupNameRequired => 'Ime skupine je obvezno.';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Skupina \"$name\" že obstaja';
  }

  @override
  String get contacts_filterContacts => 'Filtriraj stik\\,...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Noben stik ne ustreza vašemu kriteriju.';

  @override
  String get contacts_noMembers => 'Ni članov.';

  @override
  String get contacts_lastSeenNow => 'Nazadnje viden zdaj';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Zadnjič viden pred $minutes minutami';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Zadnjič viden pred 1 uro.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Zadnjič viden pred $hours urami';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Zadnjič viden pred 1 dnem';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Zadnjič viden pred $days dnem';
  }

  @override
  String get channels_title => 'Kanali';

  @override
  String get channels_noChannelsConfigured => 'Kanali še niso konfigurirani';

  @override
  String get channels_addPublicChannel => 'Dodaj javni kanal';

  @override
  String get channels_searchChannels => 'Poišči kanale...';

  @override
  String get channels_noChannelsFound => 'Ne najdem kanalov.';

  @override
  String channels_channelIndex(int index) {
    return 'Kanal $index';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag kanal';

  @override
  String get channels_public => 'Javni';

  @override
  String get channels_private => 'Zasebni';

  @override
  String get channels_publicChannel => 'Javni kanal';

  @override
  String get channels_privateChannel => 'Zasebni kanal';

  @override
  String get channels_editChannel => 'Uredi kanal';

  @override
  String get channels_muteChannel => 'Utišaj kanal';

  @override
  String get channels_unmuteChannel => 'Vklopi obvestila kanala';

  @override
  String get channels_deleteChannel => 'Pošlji kanal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Izbrišem \"$name\"? To se ne da povrniti.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanala $name ni bilo mogoče izbrisati';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanal \"$name\" izbrisan.';
  }

  @override
  String get channels_addChannel => 'Dodaj Kanal';

  @override
  String get channels_channelIndexLabel => 'Indeks kanala';

  @override
  String get channels_channelName => 'Ime kanala';

  @override
  String get channels_usePublicChannel => 'Uporabi javni kanal';

  @override
  String get channels_standardPublicPsk => 'Standardni javni PSK';

  @override
  String get channels_pskHex => 'PSK (Šestnajstbinska)';

  @override
  String get channels_generateRandomPsk => 'Generiraj naključni PSK';

  @override
  String get channels_enterChannelName => 'Vnesi ime kanala';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK mora biti 32 heksadecimalnih znakov.';

  @override
  String channels_channelAdded(String name) {
    return 'Kanal \"$name\" dodan';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Uredi Kanal $index';
  }

  @override
  String get channels_smazCompression => 'Kompresija SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanal $name je bil posodobljen';
  }

  @override
  String get channels_publicChannelAdded => 'javna skupnost dodana';

  @override
  String get channels_sortBy => 'Sortiraj po';

  @override
  String get channels_sortManual => 'Ročno';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Najnovejše sporočilo';

  @override
  String get channels_sortUnread => 'Nerešeno';

  @override
  String get channels_createPrivateChannel => 'Ustvari zasebno kanal.';

  @override
  String get channels_createPrivateChannelDesc =>
      'Varno zaklenjeno s skrivnim ključem.';

  @override
  String get channels_joinPrivateChannel => 'Pridružite se zasebni skupini';

  @override
  String get channels_joinPrivateChannelDesc => 'Ročno vnesite zaporni ključ.';

  @override
  String get channels_joinPublicChannel => 'Pridružite se javnemu kanalu';

  @override
  String get channels_joinPublicChannelDesc =>
      'Kdor karkoli je, lahko se pridruži tej skupini.';

  @override
  String get channels_joinHashtagChannel => 'Pridružite se Kanalu z Hashtagom';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Kdor karkoli, lahko se pridruži hashtag kanalom.';

  @override
  String get channels_scanQrCode => 'Skeniraj QR kodo';

  @override
  String get channels_scanQrCodeComingSoon => 'Prihajajoča';

  @override
  String get channels_enterHashtag => 'Vnesite hashtag';

  @override
  String get channels_hashtagHint => 'npr. #ekipa';

  @override
  String get chat_noMessages => 'Še ni sporočil.';

  @override
  String get chat_sendMessageToStart => 'Pošlji sporočilo za začetek.';

  @override
  String get chat_originalMessageNotFound =>
      'Opozorilo: Sporočilo ni bilo najdeno';

  @override
  String chat_replyingTo(String name) {
    return 'Odgovarjanje $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Odpošlji odgovor $name';
  }

  @override
  String get chat_location => 'Lokacija';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Pošlji sporočilo $contactName';
  }

  @override
  String get chat_typeMessage => 'Vnesi sporočilo...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Pošiljanje sporočila je onemogočeno, saj je preveliko (maksimalno $maxBytes byte-ov).';
  }

  @override
  String get chat_messageCopied => 'Sporočilo poslano';

  @override
  String get chat_messageDeleted => 'Sporočilo izbrisano';

  @override
  String get chat_retryingMessage => 'Ponovni poskus.';

  @override
  String chat_retryCount(int current, int max) {
    return 'Ponovit $current/$max';
  }

  @override
  String get chat_sendGif => 'Pošlji GIF';

  @override
  String get chat_reply => 'Odgovori';

  @override
  String get chat_addReaction => 'Dodaj reakcijo';

  @override
  String get chat_me => 'jaz';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gestikulacije';

  @override
  String get emojiCategoryHearts => 'Srce';

  @override
  String get emojiCategoryObjects => 'Predmeti';

  @override
  String get gifPicker_title => 'Izberi GIF';

  @override
  String get gifPicker_searchHint => 'Išči GIF-e...';

  @override
  String get gifPicker_poweredBy => 'Napredno z GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Ne najdem GIF-ov.';

  @override
  String get gifPicker_failedLoad => 'Neuspešno nalaganje GIF-a';

  @override
  String get gifPicker_failedSearch => 'Iskanje neuspešno.';

  @override
  String get gifPicker_noInternet => 'Ni internetne povezave';

  @override
  String get debugLog_appTitle => 'Log zapiske aplikacije';

  @override
  String get debugLog_bleTitle => 'Log zapis BLE';

  @override
  String get debugLog_copyLog => 'Kopiraj dnevnik';

  @override
  String get debugLog_clearLog => 'Briši log';

  @override
  String get debugLog_copied => 'Beležka kopirana.';

  @override
  String get debugLog_bleCopied => 'Kopirana beležka iz BLE';

  @override
  String get debugLog_noEntries => 'Ni ustvarjenih debug zapisov.';

  @override
  String get debugLog_enableInSettings =>
      'Omogoči beleženje napak v nastavitvah aplikacije';

  @override
  String get debugLog_frames => 'Okvirji';

  @override
  String get debugLog_rawLogRx => 'Svež Log-RX';

  @override
  String get debugLog_noBleActivity => 'Ni BLE aktivnosti.';

  @override
  String debugFrame_length(int count) {
    return 'Izhodni rob: $count bajtov';
  }

  @override
  String debugFrame_command(String value) {
    return 'Navodilo: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Obvestilo:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destinirano Ključno Besedilo: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Časovnik: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Ploki: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tip besedila: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Preprosto';

  @override
  String debugFrame_text(String text) {
    return '- Tekst: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex Dump:';

  @override
  String get chat_pathManagement => 'Upravljanje poti';

  @override
  String get chat_ShowAllPaths => 'Prikaži vse poti';

  @override
  String get chat_routingMode => 'Navodilo za usmerjevalni način';

  @override
  String get chat_autoUseSavedPath => 'Avto (uporabi shranjeno pot)';

  @override
  String get chat_forceFloodMode => 'Nasilje obvezati v način';

  @override
  String get chat_recentAckPaths => 'Nedavni poti ACK (tap za uporabo):';

  @override
  String get chat_pathHistoryFull =>
      'Zapiske o poti so popolni. Izbriši vnose, da dodaš nove.';

  @override
  String get chat_hopSingular => 'skok';

  @override
  String get chat_hopPlural => 'skokov';

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
  String get chat_successes => 'Uspešni';

  @override
  String get chat_removePath => 'Izbriši pot';

  @override
  String get chat_noPathHistoryYet =>
      'Ni shranjenih poti.\nPošlji sporočilo za odkrivanje poti.';

  @override
  String get chat_pathActions => 'Potni ukazi:';

  @override
  String get chat_setCustomPath => 'Nastavi Prilozeno Pot';

  @override
  String get chat_setCustomPathSubtitle => 'Ročno določite potniško pot.';

  @override
  String get chat_clearPath => 'Počisti pot';

  @override
  String get chat_clearPathSubtitle => 'Ob naslednji pošiljanju znova zbrati.';

  @override
  String get chat_pathCleared =>
      'Pot je očiščena. Naslednje sporočilo bo ponovno odkril pot.';

  @override
  String get chat_floodModeSubtitle =>
      'Uporabi tipko usmerjevanja v meniju aplikacije.';

  @override
  String get chat_floodModeEnabled =>
      'Narejena je bila omrežna modaliteta. Vklopi jo znova preko ikone v meniju aplikacije.';

  @override
  String get chat_fullPath => 'Polna pot';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Podrobnosti poti zaenkrat niso na voljo. Poskusite poslati sporočilo za osvežitev.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Pot nastavljen: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Shrano lokalno. Povežite se za sinhronizacijo.';

  @override
  String get chat_pathDeviceConfirmed => 'Naprave potrjeno.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Naprave še niso potrdile.';

  @override
  String get chat_type => 'Vnesite';

  @override
  String get chat_path => 'Pot';

  @override
  String get chat_publicKey => 'Ključ javnega tipa';

  @override
  String get chat_compressOutgoingMessages => 'Stisnite izhodne sporočila';

  @override
  String get chat_floodForced => 'Porolni (nasilje).';

  @override
  String get chat_directForced => 'Nezglašen (nasilje)';

  @override
  String chat_hopsForced(int count) {
    return '$count skoki (nasilje)';
  }

  @override
  String get chat_floodAuto => 'Preplavljenje (avtomatizirano)';

  @override
  String get chat_direct => 'Neposredni';

  @override
  String get chat_poiShared => 'Deljeno točke MN';

  @override
  String chat_unread(int count) {
    return 'Nerešeno: $count';
  }

  @override
  String get chat_openLink => 'Odpreti povezavo?';

  @override
  String get chat_openLinkConfirmation =>
      'Ali želite odpreti to povezavo v brskalniku?';

  @override
  String get chat_open => 'Odpri';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Povezave ni bilo mogoče odpreti: $url';
  }

  @override
  String get chat_invalidLink => 'Neveljavna oblika povezave';

  @override
  String get map_title => 'Mapa omrežja';

  @override
  String get map_lineOfSight => 'Linija vida';

  @override
  String get map_losScreenTitle => 'Linija vida';

  @override
  String get map_noNodesWithLocation =>
      'Nihče od notranjih elementov nima podatkov o lokaciji.';

  @override
  String get map_nodesNeedGps =>
      'Omrežje morajo deliti svoje GPS koordinate,\nda se prikazao na zemljeobrazniku.';

  @override
  String map_nodesCount(int count) {
    return 'Omize: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Žigovi: $count';
  }

  @override
  String get map_chat => 'Čistemar';

  @override
  String get map_repeater => 'Ponovitelj';

  @override
  String get map_room => 'Soba';

  @override
  String get map_sensor => 'Senzor';

  @override
  String get map_pinDm => 'Zavežite (DM)';

  @override
  String get map_pinPrivate => 'Zasebno označit';

  @override
  String get map_pinPublic => 'Oznaka (javna)';

  @override
  String get map_lastSeen => 'Zadnjič Zazet';

  @override
  String get map_disconnectConfirm =>
      'Ste prepričani, da želite se odklopiti s tega naprave?';

  @override
  String get map_from => 'Od';

  @override
  String get map_source => 'Vir';

  @override
  String get map_flags => 'Zapestnice';

  @override
  String get map_shareMarkerHere => 'Delite točke tukaj.';

  @override
  String get map_pinLabel => 'Oznaka za pritrditev';

  @override
  String get map_label => 'Oznaka';

  @override
  String get map_pointOfInterest => 'Točka zanimivosti';

  @override
  String get map_sendToContact => 'Pošlji v kontakt';

  @override
  String get map_sendToChannel => 'Pošlji v kanal';

  @override
  String get map_noChannelsAvailable => 'Nihče kanalov na voljo.';

  @override
  String get map_publicLocationShare => 'Deljenje javne lokacije';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Kljubite boste delili lokacijo v $channelLabel. Ta kanal je javno dostopen in vsak, ki ima PSK, ga lahko vidi.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Povežite se z napravo za deljenje oznak.';

  @override
  String get map_filterNodes => 'Filtirirajte člene';

  @override
  String get map_nodeTypes => 'Vrste knope';

  @override
  String get map_chatNodes => 'Čuti zvezde';

  @override
  String get map_repeaters => 'Ponovljalniki';

  @override
  String get map_otherNodes => 'Druge vozlišča';

  @override
  String get map_keyPrefix => 'Predpona ključa';

  @override
  String get map_filterByKeyPrefix => 'Filtri po predpomniku ključa';

  @override
  String get map_publicKeyPrefix => 'Predifika javnega ključa';

  @override
  String get map_markers => 'Označitelji';

  @override
  String get map_showSharedMarkers => 'Pokaži skupno označenja';

  @override
  String get map_showGuessedLocations => 'Pokaži lokacije domnevnih not.';

  @override
  String get map_showDiscoveryContacts => 'Prikaži odkritja kontaktov';

  @override
  String get map_guessedLocation => 'Predpostavljena lokacija';

  @override
  String get map_lastSeenTime => 'Datum zadnjega vpogleda';

  @override
  String get map_sharedPin => 'Deljeno naslovno geslo';

  @override
  String get map_joinRoom => 'Pridružiti sobo';

  @override
  String get map_manageRepeater => 'Upravljajte Ponovitve';

  @override
  String get map_tapToAdd => 'Pritisnite na vozlišča, da jih dodate poti.';

  @override
  String get map_runTrace => 'Zaženi sledenje poti';

  @override
  String get map_removeLast => 'Odstrani Zadnji';

  @override
  String get map_pathTraceCancelled => 'Spremljanje poti je prekinjeno.';

  @override
  String get mapCache_title =>
      'Omrezni predpomnilnik zemljeških zemljejevskih slik';

  @override
  String get mapCache_selectAreaFirst =>
      'Izberite območje za prvo predpomnilnik.';

  @override
  String get mapCache_noTilesToDownload =>
      'Nihče slik ne bo naložil za to območje.';

  @override
  String get mapCache_downloadTilesTitle => 'Naloži ploščice';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Naložiť $count plošč za uporabo v režimu brez povezave?';
  }

  @override
  String get mapCache_downloadAction => 'Naloži';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Pospešeno shranjeni $count plošč';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Shranjeni $downloaded ploščad ($failed neuspešno)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle =>
      'Ponovite arhiv za offline način';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Izbriši vse predpomnilnikovane kartografske ploščice?';

  @override
  String get mapCache_offlineCacheCleared =>
      'Omrezni predpomnik je bil izbrisal.';

  @override
  String get mapCache_noAreaSelected => 'Nizona označena površina';

  @override
  String get mapCache_cacheArea => 'Omanski prostor';

  @override
  String get mapCache_useCurrentView => 'Uporabi trenutni prikaz';

  @override
  String get mapCache_zoomRange => 'Občutek razpona';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Predvideni ploščadi: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Naloženo $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Naloži ploščice';

  @override
  String get mapCache_clearCacheButton => 'Ponoviti arhiv';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Poslovniški izniki: $count';
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
  String get time_justNow => 'Takoj';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minut nazaj';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h nazaj';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dni nazaj';
  }

  @override
  String get time_hour => 'ure';

  @override
  String get time_hours => 'ure';

  @override
  String get time_day => 'dan';

  @override
  String get time_days => 'dani';

  @override
  String get time_week => 'teden';

  @override
  String get time_weeks => 'tedne';

  @override
  String get time_month => 'mesec';

  @override
  String get time_months => 'mesi';

  @override
  String get time_minutes => 'minute';

  @override
  String get time_allTime => 'Vse časovno obdobje';

  @override
  String get dialog_disconnect => 'Odklopiti';

  @override
  String get dialog_disconnectConfirm =>
      'Ste prepričani, da želite se odklopiti s tega naprave?';

  @override
  String get login_repeaterLogin => 'Ponovni vnos';

  @override
  String get login_roomLogin => 'Vnos v sobo';

  @override
  String get login_password => 'Geslo';

  @override
  String get login_enterPassword => 'Vnesite geslo';

  @override
  String get login_savePassword => 'Shrani geslo';

  @override
  String get login_savePasswordSubtitle =>
      'Geslo bo shranjeno varno na tem pripravem.';

  @override
  String get login_repeaterDescription =>
      'Vnesite geslo za ponovljalnik, da dostopite do nastavitev in statusa.';

  @override
  String get login_roomDescription =>
      'Vnesite geslo v sobo za dostop do nastavitev in statusa.';

  @override
  String get login_routing => 'Usmerjanje';

  @override
  String get login_routingMode => 'Navodilo za usmerjevalni način';

  @override
  String get login_autoUseSavedPath => 'Avto (uporabi shranjeno pot)';

  @override
  String get login_forceFloodMode => 'Nasilje obvezati v način';

  @override
  String get login_managePaths => 'Upravljajte Potniške Proti';

  @override
  String get login_login => 'Prijava';

  @override
  String login_attempt(int current, int max) {
    return 'Poskušajo $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Prijava je bila neuspešna: $error';
  }

  @override
  String get login_failedMessage =>
      'Prijava je bila neuspešna. Geslo je napačno ali pa je repetitor nedosegljiv.';

  @override
  String get common_reload => 'Ponovno naloži';

  @override
  String get common_clear => 'Ponoviti';

  @override
  String path_currentPath(String path) {
    return 'Trenutna pot: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Uporablja $count $_temp0 pot';
  }

  @override
  String get path_enterCustomPath => 'Vnesite prilagojeno pot';

  @override
  String get path_currentPathLabel => 'Trenutna pot';

  @override
  String get path_hexPrefixInstructions =>
      'Vnesite 2-karakterne heksadecimalne prefixe za vsako skopo, ločeno z zvezekami.';

  @override
  String get path_hexPrefixExample =>
      'Primer: A1,F2,3C (vsak notranji element uporablja prvi bajt svojega javnega ključa)';

  @override
  String get path_labelHexPrefixes => 'Pot (heksafixne skrajšave)';

  @override
  String get path_helperMaxHops =>
      'Maksimalno 64 skokov. Vsak prefiks je 2 heksadecimalna znamenja (1 bajt).';

  @override
  String get path_selectFromContacts => 'Izberi iz kontaktov:';

  @override
  String get path_noRepeatersFound =>
      'Ne najdenih ponoviteljev ali strežnikov sob.';

  @override
  String get path_customPathsRequire =>
      'Prilojene poti zahtevajo medhodne prenose, ki lahko prenašajo sporočila.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Neveljačni šesteročlenski prefiksi: $prefixes';
  }

  @override
  String get path_tooLong => 'Pot je prevelika. Dovoljeno največ 64 skokov.';

  @override
  String get path_setPath => 'Nastavi Pot';

  @override
  String get repeater_management => 'Upravljanje ponovitve';

  @override
  String get room_management => 'Upravljanje stremlišča';

  @override
  String get repeater_managementTools => 'Upravne orodje';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Pogledati stanje, statistike in sosede repeatera';

  @override
  String get repeater_telemetry => 'Telemetrija';

  @override
  String get repeater_telemetrySubtitle =>
      'Pogledate telemetrijo senzorjev in sistemske statistike';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle =>
      'Pošlji ukazne povelje na ponovitveno enoto.';

  @override
  String get repeater_neighbors => 'Sosedi';

  @override
  String get repeater_neighborsSubtitle => 'Pogledati nič sosednjih hopjev.';

  @override
  String get repeater_settings => 'Nastavitve';

  @override
  String get repeater_settingsSubtitle =>
      'Konfigurirajte parametre ponovitelja';

  @override
  String get repeater_statusTitle => 'Status ponovitelja';

  @override
  String get repeater_routingMode => 'Navodilo za usmerjevalni način';

  @override
  String get repeater_autoUseSavedPath => 'Avto (uporabi shranjeno pot)';

  @override
  String get repeater_forceFloodMode => 'Nasilje obvezati v način';

  @override
  String get repeater_pathManagement => 'Upravljanje poti';

  @override
  String get repeater_refresh => 'Ponovno obnavljati';

  @override
  String get repeater_statusRequestTimeout => 'Zahtev statusa je iztekla.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Napaka pri obnašanju: $error';
  }

  @override
  String get repeater_systemInformation => 'Informacije o sistemu';

  @override
  String get repeater_battery => 'Baterija';

  @override
  String get repeater_clockAtLogin => 'Ure (pri prijavi)';

  @override
  String get repeater_uptime => 'Čas delovanja';

  @override
  String get repeater_queueLength => 'Dolžina čakalne vrste';

  @override
  String get repeater_debugFlags => 'Nastavitve odpravilnosti';

  @override
  String get repeater_radioStatistics => 'Radio Statistika';

  @override
  String get repeater_lastRssi => 'Potredno RSSI';

  @override
  String get repeater_lastSnr => 'Nazadnje zabeležena SNR';

  @override
  String get repeater_noiseFloor => 'Šumovita raven';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistika paketa';

  @override
  String get repeater_sent => 'Pošljeno';

  @override
  String get repeater_received => 'Prejeto';

  @override
  String get repeater_duplicates => 'Duplikati';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dni ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Skupno: $total, Poplava: $flood, Neposredno: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Skupno: $total, Poplava: $flood, Neposredno: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Prah: $flood, Neposredni: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Skupno: $total';
  }

  @override
  String get repeater_settingsTitle => 'Nastavitve ponovitelja';

  @override
  String get repeater_basicSettings => 'Osnovne nastavitve';

  @override
  String get repeater_repeaterName => 'Ime ponovitelja';

  @override
  String get repeater_repeaterNameHelper => 'Prikaz imena za ta ponovitelj.';

  @override
  String get repeater_adminPassword => 'Admin geslo';

  @override
  String get repeater_adminPasswordHelper => 'Polni dostopno geslo';

  @override
  String get repeater_guestPassword => 'Geslo gostača';

  @override
  String get repeater_guestPasswordHelper => 'Odpovedni dostopni geslo';

  @override
  String get repeater_radioSettings => 'Nastavitve Radija';

  @override
  String get repeater_frequencyMhz => 'Frekvenca (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Moč';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Pasovna širina';

  @override
  String get repeater_spreadingFactor => 'Razširitveni faktor';

  @override
  String get repeater_codingRate => 'Programska hitrost';

  @override
  String get repeater_locationSettings => 'Nastavitve lokacije';

  @override
  String get repeater_latitude => 'Širina';

  @override
  String get repeater_latitudeHelper => 'Desetbinske protiure (npr. 37.7749)';

  @override
  String get repeater_longitude => 'Dolžina';

  @override
  String get repeater_longitudeHelper =>
      'Desetbinske protiure (npr. -122,4194)';

  @override
  String get repeater_features => 'Značilnosti';

  @override
  String get repeater_packetForwarding => 'Usmerjanje paketa';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Omogoči ponovitelja za usmerjanje paketov.';

  @override
  String get repeater_guestAccess => 'Prijemnik';

  @override
  String get repeater_guestAccessSubtitle =>
      'Omogoči dostop gostom v samo bralni načinu.';

  @override
  String get repeater_privacyMode => 'Privatni način';

  @override
  String get repeater_privacyModeSubtitle => 'Skrita imena/lokacije v oglasih';

  @override
  String get repeater_advertisementSettings => 'Nastavitve oglasnika';

  @override
  String get repeater_localAdvertInterval => 'Lokalen Oglasovni Razpon';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minut';
  }

  @override
  String get repeater_floodAdvertInterval => 'Razpon Obvestil o Poplavah';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours ur';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Šifrirana Oglasovalska Trajanje';

  @override
  String get repeater_dangerZone => 'Opozorilo';

  @override
  String get repeater_rebootRepeater => 'Ponovni zagon Repeaterja';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Ponovni zagon ponovitelja.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ste prepričani, da želite ponovno zagon tega ponovitelja?';

  @override
  String get repeater_regenerateIdentityKey => 'Ponovite Ključ Identnosti';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Ustvarite novo par javnih/zasebnih ključev';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'To bo ustvaril novo identiteto za ponavljalnik. Prijavite se?';

  @override
  String get repeater_eraseFileSystem => 'Počisti Sustav Vajah';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Oblikuj datoteko ponovitve sistema';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'OPOZORILO: To bo izbrisal/a vsa dejstva na ponovilu. To ni mogoče povzvrniti!';

  @override
  String get repeater_eraseSerialOnly =>
      'Brisanje je na voljo samo preko serijske konzole.';

  @override
  String repeater_commandSent(String command) {
    return 'Navodilo poslano: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Napaka pri pošiljanju ukaznega: $error';
  }

  @override
  String get repeater_confirm => 'Potrdit';

  @override
  String get repeater_settingsSaved => 'Nastavitve so shranjene uspešno.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Napaka pri shranjevanju nastavitev: $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Ponovno nastavi osnovne nastavitve';

  @override
  String get repeater_refreshRadioSettings => 'Ponovno Nastavitve Radija';

  @override
  String get repeater_refreshTxPower => 'Ponovno nastavi TX moč';

  @override
  String get repeater_refreshLocationSettings =>
      'Ponovno Nastavi Nastavitve Lokacije';

  @override
  String get repeater_refreshPacketForwarding =>
      'Ponovno nastavitve usmerjevanja paketa';

  @override
  String get repeater_refreshGuestAccess => 'Ponovno nastavitve dostopa gostov';

  @override
  String get repeater_refreshPrivacyMode =>
      'Ponovno aktiviraj način zasebnosti';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Ponovno nastavi Oglede Oglasi';

  @override
  String repeater_refreshed(String label) {
    return '$label je bil/a posodobljen/a';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Napaka pri osveževanju $label';
  }

  @override
  String get repeater_cliTitle => 'Ponovitelj CLI';

  @override
  String get repeater_debugNextCommand => 'Popravi naslednje ukazne možnosti';

  @override
  String get repeater_commandHelp => 'Pomoc';

  @override
  String get repeater_clearHistory => 'Ponovi zgodovino';

  @override
  String get repeater_noCommandsSent =>
      'Niti ena ukazne povratne informacije še ni poslana.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Vnesite ukaz spodaj ali uporabite hitre ukaze';

  @override
  String get repeater_enterCommandHint => 'Vnesite ukaz...';

  @override
  String get repeater_previousCommand => 'Prejšnji ukaz';

  @override
  String get repeater_nextCommand => 'Naslednja ukazna';

  @override
  String get repeater_enterCommandFirst => 'Vnesite ukaz najprej';

  @override
  String get repeater_cliCommandFrameTitle => 'Okno ukazne vrstice';

  @override
  String repeater_cliCommandError(String error) {
    return 'Napaka: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Pridobi ime';

  @override
  String get repeater_cliQuickGetRadio => 'Dobiti Radiopravo';

  @override
  String get repeater_cliQuickGetTx => 'Pridobi TX';

  @override
  String get repeater_cliQuickNeighbors => 'Sosedi';

  @override
  String get repeater_cliQuickVersion => 'Različica';

  @override
  String get repeater_cliQuickAdvertise => 'Oglasite';

  @override
  String get repeater_cliQuickClock => 'Ura';

  @override
  String get repeater_cliHelpAdvert => 'Pošlje paket oglasov';

  @override
  String get repeater_cliHelpReboot =>
      'Ponastavi naprave. (Opomba, lahko pride do \'Timeouta\', kar je normalno)';

  @override
  String get repeater_cliHelpClock => 'Prikaže trenutno uro po uri naprave.';

  @override
  String get repeater_cliHelpPassword =>
      'Nastavi novo administracijsko geslo za naprave.';

  @override
  String get repeater_cliHelpVersion =>
      'Prikaže različico naprave in datum izrabe strojne opreme.';

  @override
  String get repeater_cliHelpClearStats =>
      'Ponastavi različne statistične števke na nič.';

  @override
  String get repeater_cliHelpSetAf => 'Nastavi časovni koeficient.';

  @override
  String get repeater_cliHelpSetTx =>
      'Nastavi moč LoRa oddajanja v dBm. (za ponovni zagon za uporabo)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Omogoči ali onemogoči vlogo ponovitelja za tono.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Osebni strežnik) Če je \'vklopljeno\', potem bo dovoljeno prijavo z praznim geslom, vendar ne bo mogoče objaviti v sobo. (samo branje).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Nastavi največjo število skokov za vstopne poplave (če je >= maks, paket ni usmerjen)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Nastavi Prag Interferencij (v dB). Privzeto je 14. Nastavi na 0 za onemogočitev zaznavanja interferenc kanalov.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Nastavi časovno razdaljo za ponovni zagon nadzornika Avtomatske uteži. Nastavi na 0 za onemogočanje.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Omogoči ali onemogoči funkcijo \"dvojakih potrdil\".';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Nastavi časovno obmesto v minutah za pošiljanje lokalnega (brezposrednega) napovednega paketa. Nastavi na 0 za onemogočiti.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Nastavi časovno obmesto v urah za pošiljanje plovilnega oglasnega paketa. Nastavi na 0 za onemogočanje.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Nastavi/posodobi geslo gosta. (za ponovitve lahko gostov prijavi pošiljajo zahtevo \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Nastavi ime oglasnika.';

  @override
  String get repeater_cliHelpSetLat =>
      'Nastavi zemljepisno širino oglaševalskega zemljevida (desetdeljne).';

  @override
  String get repeater_cliHelpSetLon =>
      'Nastavi zemljevidno širino oglasnika. (desetdelne stopnje)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Nastavi popolnoma nove radijske parametre in jih shranjuje v nastavitve. Za uporabo je potrebna \"restart\" ukaz.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Nastavitve (eksperimentalne) osnova (mora biti > 1 za učinkovanje) za uporabo rahle zakasnitve prejetih paketov, glede na moč signala/rezultat. Nastavite na 0 za onemogočanje.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Nastavi faktor, ki se množi s časom delovanja za paket v načinu poplavnega režima in z randomiziranim sistemom slotov, da odvrne njegovo posredovanje. (da se zmanjša verjetnost kolizij)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Ima podobno vrednost kot txdelay, vendar jo lahko uporabite za dodajanje naknadnega zamika pri posredovanju paketov v režimu neposredne prevodi.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Omogoči/Preklopi most.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Nastavi zamik pred ponovnim poslanjem paketov.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Izberite, ali bodo most ponavljali prejeto ali poslan paket.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Nastavi hitrost serijske povezave za mostove rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Nastavi skrivni dostop za mostove ESPNOW.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Nastavi prilagoditev faktorja za prilagoditev poravnalnega napetosti baterije (podprt le na izbranih ploščah).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Nastavi začasne radio parametre za določeno časovno obdobje, kar po preteku časa vrne originalne radio parametre. (ne shranjuje v preferencije).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modificira ACL. Odstrani ustrezen vnos (po predponi pubkeyja), če je \"permissions\" enako nič. Dodaja nov vnos, če je pubkey-hex v celoti in trenutno ni v ACL. Posodobi vnos po ustreznem predponi pubkeyja. Bitje dovoljenj se razlikuje glede na firmware vlogo, vendar so prvi dve bitki: 0 (Gost), 1 (Lezenje samo), 2 (Lezenje in pisanje), 3 (Administrator).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Dobrodošli pri izbiri vrste mostu: brez, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Začnete beleženje paketov v datotekovni sistem.';

  @override
  String get repeater_cliHelpLogStop =>
      'Ustavite beleženje paketov v datotečno sistem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Izbriše pakete zapisov iz datotek sistema.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Prikaže seznam drugih ponovnih knopov, do katerih je prišlo preko brezposrednih oglasov. Vsaka vrstica je id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Izbriše prvo ustreznu postavko (po predpomnilku pubkey (heks),) iz seznama sosedov.';

  @override
  String get repeater_cliHelpRegion =>
      '(Serija samo) Navaja vse definirane regije in trenutne poplave dovolilnosti.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Opomba: to je posebna več ukazna pozivna operacija. Vsak naslednji ukaz je ime regije (z lezijami za prikaz hierarhije, z enim ustvarjenim razmislom). Zaključena s pošiljanjem praznega reda/ukaza.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Išče regijo s podanimi imenimi prefiksom (ali \"\\\" za globalni obseg). Odgovori se s \"-> regija-ime (rodič-ime) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Dodaja ali posodobi regijsko definicijo s podanim imenom.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Izbriše definicijo regije s podanim imenom. (mora se popolnoma ujemati in ne sme imeti podregij)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Nastavi dovoljenje \'Nere\' za podano regijo. (\'\' za globalni/dedni obseg)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Odstrani dovoljenje \'F\'lood\' za podano regijo. (OPOZORILO: na tem koraku ni priporočljivo ga uporabljati na globalnem/dednem obsegu!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odgovori z trenutnim \'domovim\' območjem. (Opomba je bila še nujno uporabljena, rezervirano za prihodnost)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Nastavi regijo \'domov\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Shrani seznam/ zemljevzemi regij v shranjevanje.';

  @override
  String get repeater_cliHelpGps =>
      'Pokaže status GPS-ja. Če je GPS izklopljen, odgovarja samo \"off\", če je vklopljen, odgovarja z \"on\", statusom, \"fix\" in štetjem satelitiv.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Omogoči/onameni GPS način delovanja.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sinhronizira čas časa ničala z gps uro.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Nastavi položaj časa na GPS koordinate in shranjevanje preferencij.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Omogoča konfiguracijo oglasi za notranjost člana:\n- none: ne vključevati lokacije v oglasih\n- share: deliti gps lokacijo (iz SensorManager)\n- prefs: oglaševati lokacijo shranjeno v preferencah';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Nastavi konfiguracijo oglasa na določenem mestu.';

  @override
  String get repeater_commandsListTitle => 'Seznam ukazov';

  @override
  String get repeater_commandsListNote =>
      'Opomba: za različne ukaze \"nastavi ...\" obstaja tudi ukaz \"dobi ...\".';

  @override
  String get repeater_general => 'Općenito';

  @override
  String get repeater_settingsCategory => 'Nastavitve';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Logiranje';

  @override
  String get repeater_neighborsRepeaterOnly => 'Sosedi (le za repetitorje)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Upravljanje regij (zgolj za repetitorje)';

  @override
  String get repeater_regionNote =>
      'Regionske ukazi so bili uvedeni za upravljanje z regijskimi definicijami in dovolili.';

  @override
  String get repeater_gpsManagement => 'Upravljanje GPS';

  @override
  String get repeater_gpsNote =>
      'GPS ukaz je bil uveden za upravljanje z vprašanji, povezanimi z lokacijo.';

  @override
  String get telemetry_receivedData => 'Prejeto Telemetrično podatke';

  @override
  String get telemetry_requestTimeout => 'Zahtev telemetrije je iztekla.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Napaka pri obnašanju telemetrije: $error';
  }

  @override
  String get telemetry_noData => 'Niso na voljo podatki o telemetriji.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Baterija';

  @override
  String get telemetry_voltageLabel => 'Napetost';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU Temperatura';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Trenutno';

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
  String get neighbors_receivedData => 'Prejeto podatke o sosedih';

  @override
  String get neighbors_requestTimedOut =>
      'Sosedi zahtevajo izklop po dogovoru.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Napaka pri obnašanju sosedov: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ponovitve Sosedi';

  @override
  String get neighbors_noData => 'Niso na voljo podatki o sosedih.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Nepoznano $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Udeleženec je prejel sporočilo $time nazaj.';
  }

  @override
  String get channelPath_title => 'Pot do paketa';

  @override
  String get channelPath_viewMap => 'Prikaži zemljeznico';

  @override
  String get channelPath_otherObservedPaths => 'Drugi opazovani poti';

  @override
  String get channelPath_repeaterHops => 'Skoki ponovitelja';

  @override
  String get channelPath_noHopDetails =>
      'Podrobnosti o paketu za dostavo niso navedene.';

  @override
  String get channelPath_messageDetails => 'Podrobnosti sporočila';

  @override
  String get channelPath_senderLabel => 'Pošiljatelj';

  @override
  String get channelPath_timeLabel => 'Ura';

  @override
  String get channelPath_repeatsLabel => 'Ponovitve';

  @override
  String channelPath_pathLabel(int index) {
    return 'Pot $index';
  }

  @override
  String get channelPath_observedLabel => 'Opazovani';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Opazovana pot $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nihče ni določil lokacije.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Neznano';

  @override
  String get channelPath_floodPath => 'Prebivalstvo';

  @override
  String get channelPath_directPath => 'Neposredni';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 iz $total skokov';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed iz $total skokov';
  }

  @override
  String get channelPath_mapTitle => 'Potni zemljevid';

  @override
  String get channelPath_noRepeaterLocations =>
      'Ni na voljo nobenih lokacij za ponovitelja za to pot.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Pot $index (Glavni)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Pot';

  @override
  String get channelPath_observedPathHeader => 'Opazovana pot';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Niso na voljo podrobnosti o letu.';

  @override
  String get channelPath_unknownRepeater => 'Nepoznati ponovitelj';

  @override
  String get community_title => 'Skupnost';

  @override
  String get community_create => 'Ustvari skupnost';

  @override
  String get community_createDesc =>
      'Ustvari novo skupnost in jo deli preko QR kode.';

  @override
  String get community_join => 'Pridružiti se';

  @override
  String get community_joinTitle => 'Pridružite se skupnosti';

  @override
  String community_joinConfirmation(String name) {
    return 'Želiš se pridružiti skupnosti \"$name\"?';
  }

  @override
  String get community_scanQr => 'Skeniraj QR kode skupnosti';

  @override
  String get community_scanInstructions =>
      'Nasmerite kamero s skupnostnim QR kodom.';

  @override
  String get community_showQr => 'Pokaži QR kodo';

  @override
  String get community_publicChannel => 'Skupnostna javna';

  @override
  String get community_hashtagChannel => 'Skupnostni hashtag';

  @override
  String get community_name => 'Komunitarne ime';

  @override
  String get community_enterName => 'Vnesite ime skupnosti';

  @override
  String community_created(String name) {
    return 'Skupnost \"$name\" je bila ustvarila.';
  }

  @override
  String community_joined(String name) {
    return 'Prilojen k skupnosti \"$name\"';
  }

  @override
  String get community_qrTitle => 'Delite skupnost';

  @override
  String community_qrInstructions(String name) {
    return 'Skenirajte to QR kodo za vključitev $name.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Hashtag kanali skupnosti so dostopni samo članom skupnosti';

  @override
  String get community_invalidQrCode => 'Neveljaven QR koden skupnosti';

  @override
  String get community_alreadyMember => 'Že član';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Kljub temu ste že član/ka $name.';
  }

  @override
  String get community_addPublicChannel => 'Dodaj Objavni Kanal Komunitarja';

  @override
  String get community_addPublicChannelHint =>
      'Samodejno dodaj javni kanal za to skupnost.';

  @override
  String get community_noCommunities => 'Še nobena skupnost se ni pridružila.';

  @override
  String get community_scanOrCreate =>
      'Skeniraj QR kodo ali ustvari skupnost za začetek.';

  @override
  String get community_manageCommunities => 'Upravljanje skupnosti';

  @override
  String get community_delete => 'Opusti skupnost';

  @override
  String community_deleteConfirm(String name) {
    return 'Zapusti \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'To bo izbrisalo tudi $count kanal/kanalov in njihova sporočila.';
  }

  @override
  String community_deleted(String name) {
    return 'Zapustil skupnost \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Ponovno ustvari geslo';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Preberite novo tajno geslo za \"$name\"? Vsi članici morajo prebrati novo QR kodo, da lahko nadaljujejo s komunikacijo.';
  }

  @override
  String get community_regenerate => 'Preberi znova';

  @override
  String community_secretRegenerated(String name) {
    return 'Geslo za \"$name\" ponovno ustvarjeno';
  }

  @override
  String get community_updateSecret => 'Ažuriraj ključ';

  @override
  String community_secretUpdated(String name) {
    return 'Skrivnostno spremembo za \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Skeniraj novo QR kodo za posodabljanje ključa za $name';
  }

  @override
  String get community_addHashtagChannel => 'Dodaj hashtag kanal';

  @override
  String get community_addHashtagChannelDesc =>
      'Dodajte hashtag kanal za to skupnost.';

  @override
  String get community_selectCommunity => 'Izberi skupnost';

  @override
  String get community_regularHashtag => 'Oznaka s hashtagom';

  @override
  String get community_regularHashtagDesc =>
      'javna oznaka (kdorkoli lahko sodeluje)';

  @override
  String get community_communityHashtag => 'Skupnostni hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Izključeno za uporabnike skupnosti';

  @override
  String community_forCommunity(String name) {
    return 'Za $name';
  }

  @override
  String get listFilter_tooltip => 'Filtri in vrstiči';

  @override
  String get listFilter_sortBy => 'Sortiraj po';

  @override
  String get listFilter_latestMessages => 'Najnovejše sporočilo';

  @override
  String get listFilter_heardRecently => 'Nedavno slišan';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtri';

  @override
  String get listFilter_all => 'Vse';

  @override
  String get listFilter_favorites => 'Priljubljene';

  @override
  String get listFilter_addToFavorites => 'Dodaj v priljubljene';

  @override
  String get listFilter_removeFromFavorites => 'Odstrani iz priljubljenih';

  @override
  String get listFilter_users => 'Uporabniki';

  @override
  String get listFilter_repeaters => 'Ponovitve';

  @override
  String get listFilter_roomServers => 'Smeti za prostore';

  @override
  String get listFilter_unreadOnly => 'Nezbrani samo';

  @override
  String get listFilter_newGroup => 'Nova skupina';

  @override
  String get pathTrace_you => 'Ti';

  @override
  String get pathTrace_failed => 'Sledenje poti ni uspelo.';

  @override
  String get pathTrace_notAvailable => 'Potni sled ni na voljo.';

  @override
  String get pathTrace_refreshTooltip => 'Osveži Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Ena ali več hmelju manjka lokacija!';

  @override
  String get pathTrace_clearTooltip => 'Počisti pot';

  @override
  String get losSelectStartEnd => 'Izberite začetno in končno vozlišče za LOS.';

  @override
  String losRunFailed(String error) {
    return 'Preverjanje vidnega polja ni uspelo: $error';
  }

  @override
  String get losClearAllPoints => 'Počisti vse točke';

  @override
  String get losRunToViewElevationProfile =>
      'Zaženite LOS za ogled višinskega profila';

  @override
  String get losMenuTitle => 'LOS meni';

  @override
  String get losMenuSubtitle =>
      'Tapnite vozlišča ali dolgo pritisnite na zemljevid za točke po meri';

  @override
  String get losShowDisplayNodes => 'Pokaži prikazna vozlišča';

  @override
  String get losCustomPoints => 'Točke po meri';

  @override
  String losCustomPointLabel(int index) {
    return 'Po meri $index';
  }

  @override
  String get losPointA => 'Točka A';

  @override
  String get losPointB => 'Točka B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Zaženi LOS';

  @override
  String get losNoElevationData => 'Ni podatkov o višini';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, čisti LOS, najmanjša razdalja $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blokiral $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: preverjam ...';

  @override
  String get losStatusNoData => 'LOS: ni podatkov';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total jasno, $blocked blokirano, $unknown neznano';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Podatki o nadmorski višini niso na voljo za enega ali več vzorcev.';

  @override
  String get losErrorInvalidInput =>
      'Neveljavni podatki o točkah/višini za izračun LOS.';

  @override
  String get losRenameCustomPoint => 'Preimenujte točko po meri';

  @override
  String get losPointName => 'Ime točke';

  @override
  String get losShowPanelTooltip => 'Pokaži ploščo LOS';

  @override
  String get losHidePanelTooltip => 'Skrij ploščo LOS';

  @override
  String get losElevationAttribution =>
      'Podatki o višini: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radijski horizont';

  @override
  String get losLegendLosBeam => 'Linija vidnosti';

  @override
  String get losLegendTerrain => 'Teren';

  @override
  String get losFrequencyLabel => 'Frekvenca';

  @override
  String get losFrequencyInfoTooltip => 'Prikaži podrobnosti izračuna';

  @override
  String get losFrequencyDialogTitle => 'Izračun radijskega horizonta';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Začenši od k=$baselineK pri $baselineFreq MHz, izračun prilagodi k-faktor za trenutni pas $frequencyMHz MHz, ki določa ukrivljeno zgornjo mejo radijskega horizonta.';
  }

  @override
  String get contacts_pathTrace => 'Sledenje poti';

  @override
  String get contacts_ping => 'Pingati';

  @override
  String get contacts_repeaterPathTrace => 'Sledi poti do ponavljalnika';

  @override
  String get contacts_repeaterPing => 'Pinguj ponavljalnik';

  @override
  String get contacts_roomPathTrace => 'Sledenje poti do strežnika sobe';

  @override
  String get contacts_roomPing => 'Ping strežnik sobe';

  @override
  String get contacts_chatTraceRoute => 'Slediti poti žarkov';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Trace route to $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Odložišče je prazno.';

  @override
  String get contacts_invalidAdvertFormat => 'Neveljavni kontaktne podatke';

  @override
  String get contacts_contactImported => 'Kontakt je bil uvožen.';

  @override
  String get contacts_contactImportFailed => 'Kontakt ni bil uspešno uvožen.';

  @override
  String get contacts_zeroHopAdvert => 'Reklama brez posrednikov';

  @override
  String get contacts_floodAdvert => 'Poplavna oglás';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopiraj oglas v odložišče';

  @override
  String get contacts_addContactFromClipboard => 'Dodaj stik iz odložišča';

  @override
  String get contacts_ShareContact => 'Kopiraj stik v Odložišče';

  @override
  String get contacts_ShareContactZeroHop => 'Deliti kontakt prek oglasa';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Poslano po oglasu.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Pošiljanje kontakta ni uspelo.';

  @override
  String get contacts_contactAdvertCopied =>
      'Oglas je bil kopiran v odložišče.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopiranje oglasa v odložišče je spodletelo.';

  @override
  String get notification_activityTitle => 'Aktivnost MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sporočil',
      few: 'sporočila',
      two: 'sporočili',
      one: 'sporočilo',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sporočil kanala',
      few: 'sporočila kanala',
      two: 'sporočili kanala',
      one: 'sporočilo kanala',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'novih vozlišč',
      few: 'nova vozlišča',
      two: 'novi vozlišči',
      one: 'novo vozlišče',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Odkrito novo $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Prejeto novo sporočilo';

  @override
  String get settings_gpxExportRepeaters =>
      'Izvoz ponoviteljev / strežnika sobe v GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Izvozi ponovljene oddajnike / strežnik sobe z lokacijo v datoteko GPX.';

  @override
  String get settings_gpxExportContacts => 'Izvoz spremljevalcev v GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Izvozi spremljevalce z lokacijo v datoteko GPX.';

  @override
  String get settings_gpxExportAll => 'Izvozi vse kontakte v GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Izvozi vse kontakte z lokacijo v datoteko GPX.';

  @override
  String get settings_gpxExportSuccess => 'Uspešno izvoz GPX datoteke.';

  @override
  String get settings_gpxExportNoContacts => 'Ni stikov za izvoz.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Ni podprto na vašem napravi/operacijskem sistemu';

  @override
  String get settings_gpxExportError => 'Pri izvozu je prišlo do napake.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Lokacije ponovljivca in strežnika sobe';

  @override
  String get settings_gpxExportChat => 'Lokacije spremljevalcev';

  @override
  String get settings_gpxExportAllContacts => 'Lokacije vseh stikov';

  @override
  String get settings_gpxExportShareText =>
      'Podatki kart izvoženi iz meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open izvoz podatkov GPX karte';

  @override
  String get snrIndicator_nearByRepeaters => 'Bližnji ponovitelji';

  @override
  String get snrIndicator_lastSeen => 'Zadnjič videno';

  @override
  String get contactsSettings_title => 'Nastavitve stikov';

  @override
  String get contactsSettings_autoAddTitle => 'Avtomatsko odkrivanje';

  @override
  String get contactsSettings_otherTitle => 'Druge nastavitve v zvezi s stiki';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Avtomatsko dodaj uporabnike';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite uporabnike.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Avtomatsko dodaj ponovitelje';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite ponovitelje.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Avtomatsko dodaj strežnike sob';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite strežnike sob.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Avtomatsko dodaj senzorje';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite senzorje.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Prepiši najstarejše';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Ko je seznam stikov poln, bo najstarejši nestarševski stik zamenjan.';

  @override
  String get discoveredContacts_Title => 'Odkriti stiki';

  @override
  String get discoveredContacts_noMatching => 'Ni ujemajočih stikov';

  @override
  String get discoveredContacts_searchHint => 'Najdeni stiki po iskanju';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt dodan';

  @override
  String get discoveredContacts_addContact => 'Dodaj stik';

  @override
  String get discoveredContacts_copyContact => 'Kopiraj stik v odložišče';

  @override
  String get discoveredContacts_deleteContact => 'Izbriši stik';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Izbriši vse odkrite kontakte';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Ste prepričani, da želite izbrisati vse odkrite kontakte?';
}
