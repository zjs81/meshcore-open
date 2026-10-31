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
  String get common_done => 'Done';

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
  String get common_undo => 'Zrušiť';

  @override
  String get messageStatus_sent => 'Odoslané';

  @override
  String get messageStatus_delivered => 'Doručené';

  @override
  String get messageStatus_pending => 'Odoslanie';

  @override
  String get messageStatus_failed => 'Neúspešné odeslanie';

  @override
  String get messageStatus_repeated => 'Slyšal som to opakovane';

  @override
  String get messageStatus_failedChannel =>
      'Toto rádio nedokázalo odoslať túto správu.';

  @override
  String messageStatus_resending(int resends, int maxResends) {
    return 'Zatiaľ nebolo počuť cez dostatok opakovačov. Odoslané $resends z $maxResends krát.';
  }

  @override
  String messageStatus_hopsNotReached(int hops, int required) {
    return 'Odoslané, ale počuť späť iba cez $hops z $required opakovačov. Mohlo sa to dostať aj ďalej, než dokáže toto rádio počuť.';
  }

  @override
  String get messageStatus_sentChannel =>
      'Odoslané. Kanály nepotvrdzujú doručenie, takže to znamená iba to, že toto rádio správu odoslalo.';

  @override
  String get messageStatus_sentDirect =>
      'Odoslané. Čaká sa na potvrdenie od kontaktu.';

  @override
  String messageStatus_heardRepeatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count krát',
      few: '$count krát',
      one: '1-krát',
    );
    return 'Počuté opakovane $_temp0. Blízke opakovače ich poslali ďalej.';
  }

  @override
  String get urlImage_enable => 'Povoliť obrázky z URL';

  @override
  String get urlImage_possible =>
      'Možný obrázok z URL; povoľte ho v Nastaveniach.';

  @override
  String get urlImage_disabledInAppSettings =>
      'Vypnuté v nastaveniach aplikácie';

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
  String get common_autoRefresh => 'Automatické obnovenie';

  @override
  String get common_interval => 'Časový interval';

  @override
  String get scanner_title => 'MeshCore – Verzia pre verejnosť';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Spojte sa pomocou protokolu TCP';

  @override
  String get tcpHostLabel => 'IP adresa';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Prístav';

  @override
  String get tcpPortHint => '5 000';

  @override
  String get tcpStatus_notConnected => 'Zadajte cieľovú adresu a pripojte sa.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Pripojenie k $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Je potrebné zadať IP adresu.';

  @override
  String get tcpErrorPortInvalid => 'Číslo portu musí byť medzi 1 a 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Prevoz prostredníctvom protokolu TCP nie je na tejto platforme podporovaný.';

  @override
  String get tcpErrorTimedOut => 'Pripojenie TCP vypršalo.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Neúspešné vytvorenie TCP spojenia: $error';
  }

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
  String get scanner_getNodeTitle => 'Potrebujete nový uzol?';

  @override
  String get scanner_getNodeBody =>
      'Veľkosti peňaženky, beží na MeshCore, dvojpásmové GPS, vodotesný, batéria vydrží 5 dní.';

  @override
  String get scanner_getNodeAction => 'Kúpte si ho tu';

  @override
  String get scanner_getNodeDisclosure =>
      'Partnerský odkaz: každý nákup podporuje MeshCore Open.';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'Funkcia Bluetooth nie je dostupná v prehliadači. Prepojte sa pomocou USB.';

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
  String get settings_radioSettingsNotApplied =>
      'Rádio tieto nastavenia neuplatnilo';

  @override
  String get settings_pathHashModeNotApplied =>
      'Nastavenia rádia boli použité, ale rádio nepotvrdilo novú veľkosť hashu cesty';

  @override
  String get settings_regionSettings => 'Regiony';

  @override
  String get settings_regionSettingsSubtitle => 'Zohľať uložené regiony';

  @override
  String get settings_regionEmptyExplanation =>
      'Regióny obmedzujú flood správy na opakovače v danej oblasti. Načítajte ich z blízkych opakovačov alebo pridajte región podľa názvu.';

  @override
  String get settings_regionFetchFromRepeaters => 'Načítať z opakovačov';

  @override
  String get settings_regionDefault => 'Predvolený región';

  @override
  String get settings_regionDefaultSubtitle =>
      'Používa sa kanálmi bez vlastného regiónu';

  @override
  String get settings_regionDefaultNone => 'Žiadny';

  @override
  String settings_regionUseRadioDefault(String region) {
    return 'Predvolené rádia ($region)';
  }

  @override
  String get settings_regionNoRegion => 'Bez regiónu (bez obmedzenia)';

  @override
  String get settings_regionRadioDefault => 'Predvolený región rádia';

  @override
  String get settings_regionRadioDefaultSubtitle =>
      'Uložené v rádiu. Používajú ho flood správy odoslané bez regiónu, z tejto aplikácie aj z každej inej aplikácie pripojenej k rádiu.';

  @override
  String get settings_regionRadioDefaultUpdated =>
      'Predvolený región rádia bol aktualizovaný';

  @override
  String get settings_regionRadioDefaultFailed =>
      'Predvolený región rádia sa nepodarilo aktualizovať';

  @override
  String get settings_regionManagement_screenTitle => 'Regiónne vedenie';

  @override
  String get settings_regionNameHint => 'Vstuptejte název regionu';

  @override
  String get settings_regionAddRegion => 'Dodajte region';

  @override
  String get settings_regionFetchRegions => 'Odberanie regionov z repeaterov';

  @override
  String get settings_regionFetchRegionsFail => 'Nebylo našli žiadné regiony';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Tento oblast je už dodán';

  @override
  String get settings_regionName => 'Regionné název';

  @override
  String get settings_regionDeleted => 'Regionu zníteno';

  @override
  String get settings_deleteRegion => 'Vyniknúcia regionu';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Odstraniť $region z listy regionov?';
  }

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
  String get settings_privacyModeSubtitle => 'Skryť meno/poloha v inzerátoch';

  @override
  String get settings_privacyModeToggle =>
      'Prepínač súkromného režimu skryje vaše meno a polohu v inzerátoch.';

  @override
  String get settings_privacyModeEnabled => 'Ochranný režim je povolený.';

  @override
  String get settings_privacyModeDisabled => 'Ochranný režim je vypnutý';

  @override
  String get settings_privacy => 'Nastavenia súkromia';

  @override
  String get settings_privacySubtitle => 'Ovládni, aké informácie sa zdieľajú.';

  @override
  String get settings_privacySettingsDescription =>
      'Vyberte, ktoré informácie váš zariadenie zdieľa s ostatnými.';

  @override
  String get settings_denyAll => 'Zamietnuť všetko';

  @override
  String get settings_allowByContact => 'Povoliť podľa kontaktových vlajok';

  @override
  String get settings_allowAll => 'Povoliť všetko';

  @override
  String get settings_telemetryBaseMode => 'Základný režim telemetrie';

  @override
  String get settings_telemetryLocationMode => 'Režim umiestnenia telemetrie';

  @override
  String get settings_telemetryEnvironmentMode => 'Režim prostredia telemetrie';

  @override
  String get settings_telemetryPerContactHint =>
      'Ak chcete povoliť kontaktu, otvorte jeho chat a v ponuke vyberte Nastavenia kontaktov.';

  @override
  String get settings_advertLocation => 'Umiestnenie inzerátu';

  @override
  String get settings_advertLocationSubtitle => 'Zahrnúť polohu do inzerátu';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Automatický zero-hop inzerát pri aktualizácii GPS';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Keď sa GPS poloha zmení, odoslať zero-hop inzerát (vyžaduje polohu v inzeráte).';

  @override
  String get settings_multiAck => 'Viaceré ACK';

  @override
  String get settings_multiAckSubtitle =>
      'Odosielajte ďalšie ACK pre lepšie doručenie; spotrebuje viac času vysielania';

  @override
  String get settings_telemetryModeUpdated =>
      'Režim telemetrie bol aktualizovaný';

  @override
  String get settings_actions => 'Možné akcie';

  @override
  String get settings_deleteAllPaths => 'Delete All Paths';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Clear all path data from contacts.';

  @override
  String get settings_sendAdvertisement => 'Odoslať inzerát';

  @override
  String get settings_sendAdvertisementSubtitle => 'Momentálne priezornejšie.';

  @override
  String get settings_advertisementSent => 'Inzerát odoslaný';

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
  String get settings_companionDebugLog =>
      'Logovanie pre ladenie (sprievodný log)';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Príkazy, odpovede a surové dáta pre protokoly BLE/TCP/USB';

  @override
  String get settings_appDebugLog => 'Záznam ladenia aplikácie';

  @override
  String get settings_appDebugLogSubtitle => 'Správy z ladenia aplikácie';

  @override
  String get settings_about => 'O nás';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore, verzia $version';
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
  String get settings_infoId => 'Identifikátor';

  @override
  String get settings_infoStatus => 'Stav';

  @override
  String get settings_infoBattery => 'Batéria';

  @override
  String get settings_infoPublicKey => 'Verejný kľúč';

  @override
  String get settings_publicKeyCopied => 'Verejný kľúč skopírovaný';

  @override
  String get settings_infoContactsCount => 'Počet kontaktov';

  @override
  String get settings_infoChannelCount => 'Počet kanálov';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

  @override
  String get settings_presets => 'Prednastavenia';

  @override
  String get settings_presetCustom => 'Vlastné';

  @override
  String get settings_radioMatchWarning =>
      'Všetky uzly, s ktorými komunikujete, musia používať rovnakú frekvenciu, šírku pásma a SF. Rýchlosť kódovania (CR) sa môže líšiť.';

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
  String settings_txPowerRangeHelper(int min, int max) {
    return '$min až $max dBm';
  }

  @override
  String get settings_txPowerInvalid => 'Neplatná hodnota výkonu TX (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Opätovné použitie bez elektrickej siete';

  @override
  String settings_clientRepeatFrequencyNote(String freq) {
    return 'Frekvencia nastavená na $freq MHz pre opakovanie mimo siete';
  }

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
  String get appSettings_languageEn => 'Anglicky';

  @override
  String get appSettings_languageFr => 'Francúzština';

  @override
  String get appSettings_languageEs => 'Španielsky';

  @override
  String get appSettings_languageDe => 'Nemecky';

  @override
  String get appSettings_languagePl => 'Poľský';

  @override
  String get appSettings_languageSl => 'Slovinčina';

  @override
  String get appSettings_languagePt => 'Portugalčina';

  @override
  String get appSettings_languageIt => 'Taliančina';

  @override
  String get appSettings_languageZh => 'Čínština';

  @override
  String get appSettings_languageSv => 'Švédčina';

  @override
  String get appSettings_languageNl => 'Niderlandsky';

  @override
  String get appSettings_languageSk => 'Slovenčina';

  @override
  String get appSettings_languageBg => 'Bulharčina';

  @override
  String get appSettings_languageRu => 'Ruština';

  @override
  String get appSettings_languageUk => 'Ukrajinčina';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 byt';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 bity';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 bity';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 bity';

  @override
  String get settings_pathHashModeHelper =>
      'Veľkosť ID uzla zaznamenávaného v ceste odosielaných flood paketov: 1 bajt (256 ID, až 64 skokov), 2 bajty (65 tis., až 32 skokov), 3 bajty (16 mil., až 21 skokov). Väčšie ID znižujú kolízie, ale opakovače s firmvérom starším ako v1.14 odhadzujú pakety s 2- alebo 3-bajtovými ID.';

  @override
  String settings_requiresFirmware(String version) {
    return 'Vyžaduje firmvér $version alebo novší';
  }

  @override
  String get appSettings_channelMinHops =>
      'Odosielajte kanálové správy, kým nedôjdú dostatočne ďaleko';

  @override
  String get appSettings_channelMinHopsSubtitle =>
      'Ak sa vaša správa nevráti cez dostatočný počet opakovačov, pošlite ju znova. Spotrebuje viac času vysielania.';

  @override
  String appSettings_channelMinHopsCount(int count) {
    return 'Potrebné skoky: $count';
  }

  @override
  String appSettings_channelMinHopsRetries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-krát',
      few: '$count-krát',
      one: '1-krát',
    );
    return 'Odoslať znova najviac $_temp0';
  }

  @override
  String get appSettings_channelMinHopsCountRepeaters =>
      'Počítať aj rôzne blízke opakovače';

  @override
  String appSettings_channelMinHopsCountRepeatersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rôznych blízkych opakovačov',
      many: '$count rôznych blízkych opakovačov',
      few: '$count rôzne blízke opakovače',
      one: '1 blízky opakovač',
    );
    return 'Správu považovať za odoslanú, keď ju zopakuje $_temp0, aj keď nepočujete, ako putuje ďalej.';
  }

  @override
  String get appSettings_enableMessageTracing =>
      'Zobraziť celú trasu cez opakovače v správach';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Zobrazí aj počty opakovaní a časy cesty. Dlho stlačte správu a vyberte Trasa pre všetky podrobnosti.';

  @override
  String get appSettings_regionOnHopsLine => 'Región vedľa počtu skokov';

  @override
  String get appSettings_regionOnHopsLineSubtitle =>
      'Zobraziť región správy kanála v rovnakom riadku ako počet skokov namiesto pod ním.';

  @override
  String get appSettings_notifications => 'Upozornenia';

  @override
  String get appSettings_enableNotifications => 'Povoliť upozornenia';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Dostávať upozornenia na správy a inzeráty';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Povolenie upozornení bolo odmietnuté';

  @override
  String get appSettings_notificationsEnabled => 'Upozornenia povolené';

  @override
  String get appSettings_notificationsDisabled => 'Upozornenia sú vypnuté';

  @override
  String get appSettings_messageNotifications => 'Upozornenia na správy';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Zobraziť upozornenie pri prijímaní nových správ';

  @override
  String get appSettings_batteryOptimization => 'Aktivita na pozadí';

  @override
  String get appSettings_batteryOptimizationSubtitle =>
      'V nastaveniach batérie nastavte MeshCore Open na „Nie optimalizovať“, aby správy naďalej prichádzali na pozadí';

  @override
  String get appSettings_channelMessageNotifications =>
      'Upozornenia na správy z kanálov';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Zobraziť upozornenie pri prijímaní správ z kanálu';

  @override
  String get appSettings_advertisementNotifications =>
      'Upozornenia na inzeráty';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Zobraziť upozornenie, keď sa objavia nové uzly.';

  @override
  String get appSettings_messaging => 'Správy';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Vymazať cestu pri maximálnom počte pokusov';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Resetovať cestu kontaktu po 5 neúspešných pokusoch o odoslanie';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Cesty budú vymazané po 5 neúspešných pokusoch.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Cesty sa automaticky nevymazávajú.';

  @override
  String get appSettings_autoRouteRotation => 'Automatické striedanie trás';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Striedajte sa medzi najlepšími trasami a flood režimom.';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Automatické striedanie trás je zapnuté';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Automatické striedanie trás je vypnuté';

  @override
  String get appSettings_maxRouteWeight => 'Maximálna váha trasy';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Maximálna váha, ktorú môže cesta nazbierať z úspešných doručení';

  @override
  String get appSettings_initialRouteWeight => 'Počiatočná váha trasy';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Počiatočná váha pre nové, objavené cesty';

  @override
  String get appSettings_routeWeightSuccessIncrement => 'Zvyšenie váhy úspechu';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Váha pridaná k ceste po úspešnom doručení';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Zníženie váhy pri neúspechu';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Váha odobraná z cesty po neúspešnom doručení';

  @override
  String get appSettings_maxMessageRetries =>
      'Maximálny počet pokusov o odoslanie správy';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Počet opakovaných pokusov pred označením správy ako neúspešnej';

  @override
  String get appSettings_ipfsImageLinks => 'Konfigurácia poskytovateľa IPFS';

  @override
  String get appSettings_ipfsImageLinksSubtitle =>
      'Nahrávanie obrázkov (alebo súborov) cez URL pomocou poskytovateľa IPFS a predvolenej brány na príjem';

  @override
  String get appSettings_loadLinkImages => 'Načítať obrázky z odkazov';

  @override
  String get appSettings_loadLinkImagesSubtitle =>
      'Zobrazovať obrázky z odkazov v správach. Načítaním obrázka sa vaša IP adresa zdieľa so stránkou, ktorá ho hostuje.';

  @override
  String get appSettings_showLinkImagesByDefault =>
      'Predvolene zobrazovať obrázky z odkazov vo všetkých chatoch';

  @override
  String get appSettings_showLinkImagesByDefaultSubtitle =>
      'Načítať obrázky z odkazov v každom chate, ak ste ich tam nevypli. Vaša IP adresa sa tak zdieľa s hostiteľmi obrázkov vo všetkých chatoch.';

  @override
  String get appSettings_publicIpfsGateway => 'Verejná brána';

  @override
  String get appSettings_ipfsGatewayDeactivated => 'Deaktivované';

  @override
  String get appSettings_ipfsGatewayIpfsIo => 'ipfs.io';

  @override
  String get appSettings_ipfsGatewayPinata => 'Pinata';

  @override
  String get appSettings_ipfsGatewayFilebase => 'Filebase';

  @override
  String get appSettings_ipfsGatewayCustom => 'Vlastná (Kubo)';

  @override
  String get appSettings_uploadIpfsProvider => 'Poskytovateľ nahrávania';

  @override
  String get appSettings_uploadIpfsGateway => 'Brána nahrávania';

  @override
  String get appSettings_uploadIpfsGatewaySubtitle =>
      'Brána na zdieľanie obrázka alebo súboru ako URL odkazu. Nechajte prázdne, ak chcete použiť formát ipfs:, ktorý iní klienti nemusia vedieť otvoriť.';

  @override
  String get appSettings_uploadIpfsEndpoint => 'Koncový bod nahrávania';

  @override
  String get appSettings_uploadIpfsEndpointSubtitle =>
      'API koncový bod používaný na nahrávanie súborov';

  @override
  String get appSettings_uploadIpfsApiKey => 'API kľúč nahrávania';

  @override
  String get appSettings_ipfsImageLinksDescription =>
      'Verejná brána sťahuje obrázky vo formáte ipfs:. Brána nahrávania sa používa na vytváranie odkazov na zdieľanie nahraných obrázkov alebo súborov.';

  @override
  String get appSettings_battery => 'Batéria';

  @override
  String get appSettings_batteryChemistry => 'Chemické zloženie batérie';

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
  String get appSettings_batteryLipoHv => 'LiPo HV (3.0-4.35V)';

  @override
  String get appSettings_mapDisplay => 'Zobrazenie mapy';

  @override
  String get appSettings_showRepeaters => 'Zobraziť opakovače';

  @override
  String get appSettings_showRepeatersSubtitle => 'Zobraziť opakovače na mape';

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
  String get appSettings_timeFilter => 'Časový filter';

  @override
  String get appSettings_timeFilterShowAll => 'Zobraziť všetky uzly';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Zobraziť uzly z posledných $hours hodín';
  }

  @override
  String get appSettings_mapTimeFilter => 'Časový filter mapy';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Zobraziť uzly objavené v:';

  @override
  String get appSettings_allTime => 'Celý čas';

  @override
  String get appSettings_lastHour => 'Posledná hodina';

  @override
  String get appSettings_last6Hours => 'Posledné 6 hodín';

  @override
  String get appSettings_last24Hours => 'Posledných 24 hodín';

  @override
  String get appSettings_lastWeek => 'Minulý týždeň';

  @override
  String get appSettings_rasterTileSource => 'Zdroj rastrových dlaždíc';

  @override
  String get appSettings_stadiaEndpoint => 'Koncový bod Stadia';

  @override
  String get appSettings_stadiaApiKey => 'Kľúč API Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Vyžaduje sa na používanie Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Nakonfigurované: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Zadajte svoj kľúč API pre Stadia Maps. Aplikácia ho používa na požiadavky na rastrové dlaždice.';

  @override
  String get appSettings_offlineMapCache => 'Offline vyrovnávacia pamäť máp';

  @override
  String get appSettings_unitsTitle => 'Jednotky';

  @override
  String get appSettings_unitsMetric => 'Metrické (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiálne (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Nie je vybraná žiadna oblasť';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Vybraná oblasť (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Ladenie';

  @override
  String get appSettings_appDebugLogging => 'Záznamy ladenia aplikácie';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Zaznamenávať ladiace správy aplikácie na riešenie problémov';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Záznam ladenia aplikácie je zapnutý';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Záznam ladenia aplikácie je vypnutý';

  @override
  String get contacts_title => 'Kontakty';

  @override
  String get contacts_noContacts => 'Zatiaľ žiadne kontakty.';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakty sa zobrazia, keď zariadenia vysielajú inzerát.';

  @override
  String get contacts_unread => 'Neprečítané';

  @override
  String get contacts_searchContactsNoNumber => 'Hľadať kontakty...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Hľadať v $number$str kontaktoch...';
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
  String get contacts_storageFull =>
      'Úložisko kontaktov v uzle je plné. Nové uzly nemožno pridať, kým neodstránite kontakty.';

  @override
  String get contacts_deleteContact => 'Odstrániť kontakt';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Odstrániť $contactName z kontaktov?';
  }

  @override
  String get contacts_removeFromContacts => 'Odstrániť z kontaktov';

  @override
  String contacts_removeFromContactsConfirm(String contactName) {
    return '$contactName sa presunie medzi objavené kontakty. História chatu bude vymazaná.';
  }

  @override
  String get contacts_keepChatHistory => 'Zachovať históriu chatu';

  @override
  String get contacts_remove => 'Odstrániť';

  @override
  String get contacts_removeAutoAddNote =>
      'Vaše rádio tento typ kontaktu pridáva automaticky, preto sa vráti pri jeho ďalšom inzeráte. Ak ho chcete ponechať odstránený, vypnite automatické pridávanie v nastaveniach kontaktov.';

  @override
  String get contacts_removeFailed =>
      'Rádio odstránenie nepotvrdilo. Kontakt nebol odstránený.';

  @override
  String contacts_discoveredNearby(int count) {
    return 'Objavené v blízkosti ($count)';
  }

  @override
  String get contacts_noContactsDiscoveredHint =>
      'Uzly, ktoré vaše rádio počuje, ale ktoré ste ešte nepridali, nájdete v zozname objavených kontaktov';

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
  String get contacts_moreOptions => 'Ďalšie možnosti';

  @override
  String get contacts_searchOpen => 'Vyhľadajte kontakty';

  @override
  String get contacts_searchClose => 'Zavrieť vyhľadávanie';

  @override
  String get contacts_groupName => 'Názov skupiny';

  @override
  String get contacts_groupNameRequired => 'Skupina musí mať názov.';

  @override
  String get contacts_groupNameReserved => 'Tento názov skupiny je rezervovaný';

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
  String get contact_info => 'Kontaktné informácie';

  @override
  String get contact_settings => 'Nastavenia kontaktov';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Naposledy videný';

  @override
  String get contact_clearChat => 'Vymazať chat';

  @override
  String get contact_teleBase => 'Báza telemetrie';

  @override
  String get contact_teleBaseSubtitle =>
      'Povoliť zdieľanie úrovne batérie a základnej telemetrie';

  @override
  String get contact_teleLoc => 'Lokácia telemetrie';

  @override
  String get contact_teleLocSubtitle => 'Povoliť zdieľanie údajov o lokalite';

  @override
  String get contact_teleEnv => 'Prostredie telemetrie';

  @override
  String get contact_teleEnvSubtitle =>
      'Povoliť zdieľanie údajov senzorov prostredia';

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
  String get channels_public => 'Veľké verejné';

  @override
  String channels_via(String path) {
    return 'via $path';
  }

  @override
  String get channels_private => 'Osobné';

  @override
  String get channels_hashtag => 'Hashtag';

  @override
  String get channels_addSectionJoin => 'Pripojiť existujúci';

  @override
  String get channels_addSectionCreate => 'Vytvoriť nový';

  @override
  String get channels_dragToReorder => 'Zmeniť poradie potiahnutím';

  @override
  String get channels_editChannel => 'Upraviť kanál';

  @override
  String get channels_notificationSettings => 'Nastavenia notifikácií';

  @override
  String get channels_notifyAll => 'Všetky správy';

  @override
  String get channels_notifyMentionsOnly => 'Iba zmienky';

  @override
  String get channels_notifyNone => 'Stíšené';

  @override
  String channels_notificationModeTooltip(String mode) {
    return 'Upozornenia: $mode';
  }

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
  String get channels_cyr2latCompression => 'Odstránenie kompresie Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Pri odosielaní nahradí niektoré znaky cyriliky latinskými znakmi.';

  @override
  String get channels_cyr2latSettingsHeading => 'Nastavenia Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Zoznam nahradení';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Upravte konfiguráciu JSON pre nahradenie znakov';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON mapa nahradení';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'Nesprávny JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Kanál \"$name\" bol aktualizovaný';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Pridať profil Cyr2Lat';

  @override
  String get settings_cyr2latProfileName => 'Názov profilu';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'Názov profilu nesmie byť prázdny';

  @override
  String get settings_cyr2latProfileAdded => 'Profil bol úspešne pridaný';

  @override
  String get settings_cyr2latProfileUpdated =>
      'Profil bol úspešne aktualizovaný';

  @override
  String get settings_cyr2latProfileEdit => 'Upraviť profil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDelete => 'Odstrániť profil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDeleted => 'Profil bol úspešne odstránený';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Naozaj chcete odstrániť profil \"$name\"?';
  }

  @override
  String get channels_publicChannelAdded => 'Veľký kanál pridaný';

  @override
  String get channels_noFreeSlots => 'Všetky miesta pre kanály sú obsadené';

  @override
  String get channels_sortBy => 'Triediť podľa';

  @override
  String get channels_sortManual => 'Ručne';

  @override
  String get channels_sortAZ => 'Od A po Z';

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
  String get channels_scanQrCodeDesc =>
      'Pripojte sa ku kanálu alebo komunite pomocou QR kódu.';

  @override
  String get channels_scanQrInstructions =>
      'Namierte kameru na QR kód kanála alebo komunity';

  @override
  String get channels_invalidQrCode =>
      'Toto nie je QR kód kanála ani komunity MeshCore';

  @override
  String get channels_joinChannelTitle => 'Pripojiť sa ku kanálu';

  @override
  String channels_joinChannelConfirm(String name) {
    return 'Pridať „$name“ do vášho rádia?';
  }

  @override
  String channels_alreadyOnRadio(String name) {
    return '„$name“ je už vo vašom rádiu';
  }

  @override
  String get channels_enterHashtag => 'Zadajte hashtag';

  @override
  String get channels_hashtagHint => 'napr. #tím';

  @override
  String channels_regionSetTo(String region) {
    return 'Region: $region';
  }

  @override
  String get channels_regionNotSet => 'Region: žiadné';

  @override
  String get channels_regionSelect_Title => 'Vyberte region';

  @override
  String get channels_clearRegion => 'Jasný údajný oblasť';

  @override
  String get channels_regionDefaultSuffix => '(predvolený)';

  @override
  String get channels_regionRadioDefaultSuffix => '(predvolený pre rádio)';

  @override
  String channels_regionRadioDefaultApplies(String region) {
    return 'Toto rádio odosiela flood správy bez regiónu vo svojom predvolenom regióne: $region.';
  }

  @override
  String get channels_regionSelectExplanation =>
      'Flood správy na tomto kanáli budú preposielané iba opakovačmi z vybraného regiónu.';

  @override
  String get channels_regionEmpty => 'Zatiaľ žiadne regióny.';

  @override
  String get channels_manageRegions => 'Spravovať regióny';

  @override
  String get chat_noMessages => 'Zatiaľ žiadne správy.';

  @override
  String get chat_sendMessage => 'Odoslať správu';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Pošli správu $contactName';
  }

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
  String get chat_typeMessage => 'Napište správu...';

  @override
  String get chat_futureTimestampWarning =>
      'Čas tejto správy je v budúcnosti, takže hodiny odosielateľa môžu byť nesprávne. Zobrazuje sa v poradí, v akom prišla.';

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
  String get chat_selectSendAction => 'Vybrať akciu odoslania';

  @override
  String get chat_sendGif => 'Odoslať GIF';

  @override
  String get chat_shareMyLocation => 'Zdieľať moju polohu';

  @override
  String get chat_noRadioLocation => 'Vaše rádio nemá nastavenú polohu';

  @override
  String get chat_removeGif => 'Odstrániť GIF';

  @override
  String get chat_cancelReply => 'Zrušiť odpoveď';

  @override
  String get chat_sendImageLora => 'Odoslať obrázok cez MeshCore';

  @override
  String get chat_sendImageIpfs => 'Odoslať obrázok alebo súbor cez IPFS';

  @override
  String chat_ipfsUploadFailed(String error) {
    return 'Nahrávanie do IPFS zlyhalo: $error';
  }

  @override
  String get chat_ipfsUploadNotConfigured =>
      'Najprv nastavte poskytovateľa nahrávania IPFS v nastaveniach aplikácie.';

  @override
  String get chat_ipfsSelectedFileEmpty => 'Vybraný súbor je prázdny.';

  @override
  String get chat_ipfsEndpointInvalid =>
      'Koncový bod nahrávania IPFS musí byť úplná adresa http:// alebo https://. Skontrolujte ho v nastaveniach aplikácie.';

  @override
  String get chat_ipfsPinataTokenMissing =>
      'Pinata vyžaduje API kľúč alebo JWT. Pridajte ho v nastaveniach aplikácie.';

  @override
  String get chat_ipfsFilebaseTokenMissing =>
      'Filebase vyžaduje API token. Pridajte ho v nastaveniach aplikácie.';

  @override
  String get chat_ipfsKuboPathInvalid =>
      'Koncový bod nahrávania Kubo musí končiť na /api/v0/add. Skontrolujte ho v nastaveniach aplikácie.';

  @override
  String get chat_ipfsLinkNoRoom =>
      'Nie je dosť miesta na odkaz na obrázok. Skráťte správu a skúste to znova.';

  @override
  String get chat_ipfsLinkOverLimit =>
      'Odkaz na obrázok bol pridaný, ale správa je teraz príliš dlhá. Pred odoslaním ju skráťte.';

  @override
  String get chat_imagePickFailed => 'Nesmiela jsem otvoriť tento obrázok';

  @override
  String get chat_receivedGif => 'Odeslaný GIF';

  @override
  String get chat_reply => 'Odpovedať';

  @override
  String get chat_addReaction => 'Pridať Reakciu';

  @override
  String get chat_me => 'Mne';

  @override
  String get reaction_report => 'Emoji reakcie';

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
  String get debugLog_rawLogRx => 'Čistý log – RX';

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
  String get debugFrame_textTypeCli => 'CLI (Command Line Interface)';

  @override
  String get debugFrame_textTypePlain => 'Jednoduché';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hexová analýza:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skoky',
      one: 'skok',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Odstrániť cestu';

  @override
  String get chat_noPathHistoryYet =>
      'Zatiaľ žiadna história trás.\nPošlite správu a objavte trasy.';

  @override
  String get chat_pathCleared =>
      'Cesta vyčistená. Nasledujúce prepočetné získa trasu znova.';

  @override
  String get chat_fullPath => 'Celá cesta';

  @override
  String get routing_title => 'Navigácia';

  @override
  String get routing_modeAuto => 'Auto';

  @override
  String get routing_modeFlood => 'Flood';

  @override
  String get routing_modeManual => 'Ručná príručka';

  @override
  String get routing_modeAutoHint =>
      'Automaticky vyberá najznámejší trasa, a ak žiadna nie je známa, použije náhodnú trasu.';

  @override
  String get routing_modeFloodHint =>
      'Prenos prostredníctvom všetkých opakovačov. Najspoľahlivejší spôsob, ale vyžaduje viac času vysielania.';

  @override
  String get routing_modeManualHint =>
      'Vždy dodáva presne podľa zadaného trasy.';

  @override
  String get routing_currentRoute => 'Aktuálna trasa';

  @override
  String get routing_directNoHops => 'Priamo – bez prechodných trás';

  @override
  String get routing_noPathYet =>
      'Zatiaľ neexistuje žiadna cesta. Nasledujúce správy budú pokračovať, kým sa nenájde trasa.';

  @override
  String get routing_floodBroadcast =>
      'Prenos prostredníctvom každého opakovača';

  @override
  String get routing_editPath => 'Upraviť trasu';

  @override
  String get routing_forgetPath => 'Zabudnite na trasu';

  @override
  String get routing_knownPaths => 'Známe cesty';

  @override
  String get routing_knownPathsHint =>
      'Kliknite na cestu, aby ste sa k nej presunuli.';

  @override
  String get routing_inUse => 'V prevádzke';

  @override
  String get routing_qualityStrong => 'Silný prvý krok';

  @override
  String get routing_qualityGood => 'Úspešný prvý krok';

  @override
  String get routing_qualityFair => 'Prvá, spravodlivá fáza';

  @override
  String get routing_qualityWorked => 'Dosiahnutý úspech';

  @override
  String get routing_qualityFlood =>
      'Zistil som to z informácií, ktoré som získal cez flood.';

  @override
  String get routing_qualityUntested => 'Neotestované';

  @override
  String routing_lastWorked(String when) {
    return 'worked $when';
  }

  @override
  String get routing_neverWorked => 'nikedy nebolo potvrdené';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes delivered, $failures failed';
  }

  @override
  String get routing_floodDelivery => 'Doručenie cez flood';

  @override
  String get pathEditor_title => 'Vytvorenie cesty';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count z 64 skokov';
  }

  @override
  String get pathEditor_noHops =>
      'Zatiaľ žiadne skoky. Kliknite na opakovače nižšie, aby ste ich pridali postupne, alebo uložte bez skokov, aby ste správu mohli poslať priamo.';

  @override
  String get pathEditor_addHops => 'Pridávajte skoky podľa zadaného poriadku.';

  @override
  String get pathEditor_searchRepeaters => 'Hľadať opakované';

  @override
  String get pathEditor_advancedHex => 'Pokročilé: pôvodná hexová cesta';

  @override
  String get pathEditor_hexLabel => 'Prefiksy pre hexadecimálne čísla';

  @override
  String get pathEditor_hexHelper =>
      'Dve hexové čísla na každý krok, oddelené čiarkami';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Neplatné: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Maximálne 64 krokov';

  @override
  String get pathEditor_usePath => 'Použite túto cestu';

  @override
  String get pathEditor_removeHop => 'Odstráňte skok';

  @override
  String get pathEditor_unknownHop =>
      'Neznáme zariadenie na opakované vysielanie';

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
  String get chat_viewPathOnMap => 'Zobraziť cestu na mape';

  @override
  String get chat_publicKey => 'Verejný kľúč';

  @override
  String get chat_compressOutgoingMessages => 'Komprimovať odoslané správy';

  @override
  String get chat_floodForced => 'Flood (vynútený)';

  @override
  String get chat_directForced => 'Priame (donútené)';

  @override
  String chat_hopsForced(int count) {
    return '$count skokov (nutené)';
  }

  @override
  String get chat_floodAuto => 'Flood (automaticky)';

  @override
  String get chat_direct => 'Priamo';

  @override
  String get chat_poiShared => 'Zdieľané body záujmu';

  @override
  String chat_unread(int count) {
    return 'Nezriadené: $count';
  }

  @override
  String get chat_markAsUnread => 'Označenie ako neprečítané';

  @override
  String get chat_newMessages => 'Nové správy';

  @override
  String get chat_today => 'Dnes';

  @override
  String get chat_yesterday => 'Včera';

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
  String get map_searchHint => 'Vyhľadajte podľa názvu alebo ID uzla';

  @override
  String get map_activity => 'Aktivita';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Nedávne';

  @override
  String get map_stale => 'Neaktuálne';

  @override
  String get map_visible => 'Viditeľný';

  @override
  String get map_hidden => 'Skrytý';

  @override
  String get map_centerOnNode => 'Nacentrovať na uzol';

  @override
  String get map_centerOnMe => 'Vycentrovať na moju polohu';

  @override
  String get map_details => 'Podrobnosti';

  @override
  String get map_noGps => 'Bez GPS';

  @override
  String get map_noResults => 'Nenašli sa žiadne zodpovedajúce uzly.';

  @override
  String get map_lineOfSight => 'Úroveň výhľadu';

  @override
  String get map_losScreenTitle => 'Úroveň výhľadu';

  @override
  String get map_noNodesWithLocation => 'Žiadne uzly s údajmi o polohe';

  @override
  String get map_noNodesLocationHint =>
      'Žiadne uzly s poslednou polohou. Rozšírite časový filter alebo nastavte vlastnú polohu v Nastaveniach.';

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
  String get map_type => 'Type';

  @override
  String get map_path => 'Path';

  @override
  String get map_location => 'Location';

  @override
  String get map_estLocation => 'Est. Location';

  @override
  String get map_publicKey => 'Public Key';

  @override
  String get map_publicKeyPrefixHint => 'e.g. ab12';

  @override
  String get map_shareMarkerHere => 'Zdieľte značku tu';

  @override
  String get map_setAsMyLocation => 'Nastavte ako moju polohu';

  @override
  String get map_pinLabel => 'Označka upozornenia';

  @override
  String get map_label => 'Značka';

  @override
  String get map_labelUpdateHint =>
      'Ak použijete rovnaký štítok ako predtým, značka sa aktualizuje u príjemcov MeshCore Open.';

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
  String get map_showOverlaps => 'Prekrývanie opakovača kľúča';

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
  String get map_clusterNodes => 'Zoskupiť blízke uzly';

  @override
  String get map_groupChip => 'Skupiny';

  @override
  String get map_clusterNodesSubtitle =>
      'Pri oddialenom priblížení zobrazte blízke uzly ako jeden očíslovaný kruh';

  @override
  String get map_showDiscoveryContacts => 'Zobraziť kontakty objavov';

  @override
  String get map_guessedLocation => 'Odhadnutá lokalita';

  @override
  String get map_lastSeenTime => 'Posledný čas sledovania';

  @override
  String get map_sharedPin => 'Zdieľaný PIN';

  @override
  String get map_sharedAt => 'Zdieľané';

  @override
  String get map_joinRoom => 'Pripojiť miestnosť';

  @override
  String get map_manageRepeater => 'Spravovať Opakovanie';

  @override
  String get map_manageServer => 'Spravovať server';

  @override
  String get map_tapToAdd => 'Kliknite na uzly, aby ste ich pridali k ceste.';

  @override
  String get map_runTrace => 'Spustiť trasovaním cesty';

  @override
  String get map_runTraceWithReturnPath => 'Vráťte sa späť po tej istej ceste.';

  @override
  String get map_removeLast => 'Odstrániť posledný';

  @override
  String get map_pathTraceCancelled => 'Zrušenie stopáže cesty bolo zrušené.';

  @override
  String get map_pathTraceAddMoreHint =>
      'Ťuknutím na ďalšie uzly pridajte skoky, vyberte, ako sa sledovanie vráti, a potom ťuknite na Spustiť sledovanie cesty.';

  @override
  String get map_pathTraceModeRoundTrip => 'Tam a späť';

  @override
  String get map_pathTraceModeRoundTripHint =>
      'Sledovanie prejde cez tieto skoky a vráti sa rovnakou cestou.';

  @override
  String get map_pathTraceModeAsEntered => 'Podľa zadania';

  @override
  String get map_pathTraceModeAsEnteredHint =>
      'Sledovanie presne prejde cez tieto skoky. Skoky späť k sebe pridajte sami.';

  @override
  String get map_pathTraceViewLast => 'Zobraziť posledný výsledok';

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
  String get login_showPassword => 'Zobraziť heslo';

  @override
  String get login_hidePassword => 'Skryť heslo';

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
  String get login_advanced => 'Pokročilé';

  @override
  String get login_routing => 'Rútiace';

  @override
  String get login_routingMode => 'Režim trasy';

  @override
  String get login_autoUseSavedPath => 'Použiť uloženú cestu';

  @override
  String get login_forceFloodMode => 'Zavrieť núdzový flood režim';

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
  String get common_clearSearch => 'Zmazať vyhľadávanie';

  @override
  String get path_currentPathLabel => 'Aktuálny priebeh';

  @override
  String get path_noRepeatersFound =>
      'Nenašli sa žiadne opakovače ani serverové miestnosti.';

  @override
  String get repeater_management => 'Správa opakovača';

  @override
  String get room_management => 'Správa servera miestnosti';

  @override
  String get repeater_guest => 'Informácie o opakovači';

  @override
  String get room_guest => 'Informácie o serveri';

  @override
  String get repeater_managementTools => 'Nástroje na správu';

  @override
  String get repeater_guestTools => 'Nástroje pre hostí';

  @override
  String get repeater_roleAdmin => 'ADMIN';

  @override
  String get repeater_roleGuest => 'HOSŤ';

  @override
  String get repeater_status => 'Stav';

  @override
  String get repeater_statusSubtitle =>
      'Zobraziť stav, štatistiky a susedov opakovača';

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
  String get repeater_neighbors => 'Susedia';

  @override
  String get repeater_neighborsSubtitle =>
      'Zobraziť susedov bez medziskokov (zero-hop).';

  @override
  String get repeater_settings => 'Nastavenia';

  @override
  String get repeater_settingsSubtitle => 'Konfigurujte parametre opakovača';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Synchronizácia hodín po prihlásení';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Po úspešnom prihlásení automaticky odoslať „synchronizáciu hodín“';

  @override
  String get repeater_statusTitle => 'Stav opakovača';

  @override
  String get repeater_routingMode => 'Režim trasy';

  @override
  String get repeater_refresh => 'Obnoviť';

  @override
  String get repeater_statusRequestTimeout => 'Požiadavka na stav vypršala.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Chyba pri načítaní stavu: $error';
  }

  @override
  String get repeater_systemInformation => 'Informácie o systéme';

  @override
  String get repeater_battery => 'Batéria';

  @override
  String get repeater_clockAtLogin => 'Čas (pri prihlásení)';

  @override
  String get repeater_uptime => 'Doba prevádzky';

  @override
  String get repeater_queueLength => 'Dĺžka fronty';

  @override
  String get repeater_debugFlags => 'Ladiace príznaky';

  @override
  String get repeater_radioStatistics => 'Štatistiky rádia';

  @override
  String get repeater_lastRssi => 'Posledný RSSI';

  @override
  String get repeater_lastSnr => 'Posledný SNR';

  @override
  String get repeater_noiseFloor => 'Hladina šumu';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_chanUtil => 'Využitie kanálu';

  @override
  String get repeater_packetStatistics => 'Štatistiky paketov';

  @override
  String get repeater_sent => 'Odoslané';

  @override
  String get repeater_received => 'Prijaté';

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
    return 'Celkom: $total, Flood: $flood, Priame: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Celkom: $total, Flood: $flood, Priame: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Priame: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Celkom: $total';
  }

  @override
  String get repeater_settingsTitle => 'Nastavenia opakovača';

  @override
  String get repeater_basicSettings => 'Základné nastavenia';

  @override
  String get repeater_repeaterName => 'Názov opakovača';

  @override
  String get repeater_repeaterNameHelper => 'Zobrazovaný názov tohto opakovača';

  @override
  String get repeater_adminPassword => 'Heslo administrátora';

  @override
  String get repeater_adminPasswordHelper => 'Heslo s plným prístupom';

  @override
  String get repeater_guestPassword => 'Heslo hosťa';

  @override
  String get repeater_guestPasswordHelper => 'Heslo s prístupom iba na čítanie';

  @override
  String get repeater_radioSettings => 'Nastavenia rádia';

  @override
  String get repeater_frequencyMhz => 'Frekvencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300–2500 MHz';

  @override
  String get repeater_txPower => 'Výkon TX';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Šírka pásma';

  @override
  String get repeater_spreadingFactor => 'Rozprestierací faktor';

  @override
  String get repeater_codingRate => 'Rýchlosť kódovania';

  @override
  String get repeater_locationSettings => 'Nastavenia polohy';

  @override
  String get repeater_latitude => 'Zemepisná šírka';

  @override
  String get repeater_latitudeHelper => 'Desatinné stupne (napr. 37.7749)';

  @override
  String get repeater_longitude => 'Zemepisná dĺžka';

  @override
  String get repeater_longitudeHelper => 'Desatinné stupne (napr. -122.4194)';

  @override
  String get repeater_features => 'Funkcie';

  @override
  String get repeater_packetForwarding => 'Preposielanie paketov';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Povoliť opakovaču preposielať pakety';

  @override
  String get repeater_guestAccess => 'Prístup pre hostí';

  @override
  String get repeater_guestAccessSubtitle =>
      'Umožniť prístup hosta iba na čítanie.';

  @override
  String get repeater_privacyMode => 'Režim ochrany súkromia';

  @override
  String get repeater_privacyModeSubtitle => 'Skryť meno/poloha v inzerátoch';

  @override
  String get repeater_advertisementSettings => 'Nastavenia inzerátov';

  @override
  String get repeater_localAdvertInterval => 'Interval lokálnych inzerátov';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minút';
  }

  @override
  String get repeater_floodAdvertInterval => 'Interval flood inzerátu';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours hodín';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Interval šifrovaných inzerátov';

  @override
  String get repeater_dangerZone => 'Nebezpečná zóna';

  @override
  String get repeater_rebootRepeater => 'Reštartovať opakovač';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reštartovať zariadenie opakovača';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ste si istý, že chcete tento opakovač restartovať?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Znovu vygenerovať kľúč identity';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Vygenerovať nový pár verejného/súkromného kľúča';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Týmto sa vytvorí nová identita opakovača. Pokračovať?';

  @override
  String get repeater_eraseFileSystem => 'Vymazať súborový systém';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formátovať súborový systém opakovača';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'VAROVANIE: Týmto sa vymažú všetky dáta v opakovači. Túto akciu nie je možné vrátiť späť!';

  @override
  String get repeater_eraseSerialOnly =>
      'Odstránenie je dostupné len cez sériové rozhranie.';

  @override
  String repeater_commandSent(String command) {
    return 'Príkaz odoslaný: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Chyba pri odosielaní príkazu: $error';
  }

  @override
  String get repeater_confirm => 'Potvrdiť';

  @override
  String get repeater_settingsSaved => 'Nastavenia boli uložené úspešne.';

  @override
  String get repeater_rxGain => 'Zvýšený zisk RX';

  @override
  String get repeater_rxGainHelper =>
      'Vyššia citlivosť, vyšší príkon (platí len pre modely SX1262/SX1268)';

  @override
  String get repeater_multiAcks => 'Viacnásobné ACK';

  @override
  String get repeater_multiAcksSubtitle =>
      'Potvrdzovať správy cez viaceré trasy pre lepšie doručenie';

  @override
  String get repeater_networkHealth => 'Zdravie siete';

  @override
  String get repeater_loopDetect => 'Detekcia slučiek';

  @override
  String get repeater_loopDetectHelper =>
      'Zahodiť flood pakety, ktoré vyzerajú ako slučky v smerovaní.';

  @override
  String get repeater_loopDetectOff => 'Vypnuté';

  @override
  String get repeater_loopDetectMinimal => 'Minimálna';

  @override
  String get repeater_loopDetectModerate => 'Stredná';

  @override
  String get repeater_loopDetectStrict => 'Prísna';

  @override
  String get repeater_dutyCycle => 'Cyklus činnosti';

  @override
  String get repeater_dutyCycleHelper =>
      'Maximálny percentuálny podiel vysielacieho času';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Informácie o prevádzkovateľovi';

  @override
  String get repeater_ownerInfoHelper => 'Verejné metadáta tohto opakovača';

  @override
  String get repeater_floodMax => 'Maximálny počet skokov flood';

  @override
  String get repeater_floodMaxHelper =>
      'Maximálny počet skokov, ktoré môže prejsť flood paket (0-64)';

  @override
  String get repeater_advancedSettings => 'Pokročilé';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Doladenie pre skúsených prevádzkovateľov';

  @override
  String get repeater_pathHashMode => 'Veľkosť ID uzla v cestách';

  @override
  String get repeater_pathHashModeHelper =>
      'Veľkosť ID tohto opakovača v cestách inzerátov, ktoré odosiela: 1 bajt (256 ID, až 64 skokov), 2 bajty (65 tisíc ID, až 32 skokov), 3 bajty (16 miliónov ID, až 21 skokov). Neovplyvňuje preposielanie; opakovače v1.14+ preposielajú všetky veľkosti, staršie firmvéry však zahadzujú pakety s 2- alebo 3-bajtovými ID.';

  @override
  String get repeater_keySettings => 'Zmeniť kľúče identity';

  @override
  String get repeater_keySettingsSubtitle =>
      'Zmeniť pár verejného/súkromného kľúča';

  @override
  String get repeater_prvKey => 'Súkromný kľúč';

  @override
  String get repeater_prvKeyHelper =>
      'Nový súkromný kľúč opakovača, 128-znakový hexadecimálny reťazec.';

  @override
  String get repeater_generatePrvKey => 'Vygenerovať náhodný pár kľúčov';

  @override
  String get repeater_stopGeneratingPrvKey => 'Prerušiť hľadanie páru kľúčov';

  @override
  String get repeater_pubKey => 'Verejný kľúč';

  @override
  String get repeater_pubKeyHelper =>
      'Toto je verejný kľúč patriaci k vygenerovanému súkromnému kľúču. Nie je možné ho nastaviť priamo.';

  @override
  String get repeater_pubKeyPrefix => 'Požadovaný prefiks';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Nájsť verejný kľúč, ktorý začína týmito hexadecimálnymi číslicami. Očakávaný počet pokusov: $tries.';
  }

  @override
  String get repeater_txDelay => 'Oneskorenie Flood TX';

  @override
  String get repeater_txDelayHelper =>
      'Rozostup opakovaného vysielania pre flood prevádzku ako násobok vysielacieho času paketu (0-2, predvolene 0,5). Vyššia hodnota = menej kolízií, ale pomalšie doručovanie.';

  @override
  String get repeater_directTxDelay => 'Priame oneskorenie TX';

  @override
  String get repeater_directTxDelayHelper =>
      'Rozostup opakovaného vysielania pre priamu (nie flood) prevádzku ako násobok vysielacieho času paketu (0-2, predvolene 0,3).';

  @override
  String get repeater_intThresh => 'Prah rušenia';

  @override
  String get repeater_intThreshHelper =>
      'Prah odovzdaný kalibrácii úrovne šumu rádia, aby odmietalo rušenie nad touto úrovňou. 0 vypne – zvýšte len vtedy, ak v zašumenom pásme vidíte chyby RX.';

  @override
  String get repeater_agcResetInterval => 'Interval reštartu AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Ako často sa má resetovať automatické riadenie zosilnenia rádia, aby sa zotavilo zo zaseknutého stavu zosilnenia. V sekundách, zaokrúhlené nadol na násobok 4. 0 vypne pravidelné resety.';

  @override
  String get repeater_actionsTitle => 'Akcie';

  @override
  String get repeater_sendAdvert => 'Odoslať flood inzerát';

  @override
  String get repeater_sendAdvertSubtitle => 'Rozoslať flood inzerát cez sieť.';

  @override
  String get repeater_sendAdvertZeroHop => 'Odoslať zero-hop inzerát';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Rozoslať inzerát s jedným skokom (bez opakovačov)';

  @override
  String get repeater_clockSync => 'Synchronizovať hodiny teraz';

  @override
  String get repeater_clockSyncSubtitle =>
      'Odoslať čas vášho telefónu do opakovača';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action bolo úspešné';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action zlyhalo: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Nastavenia uložené – na uplatnenie reštartujte opakovač';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Niektoré nastavenia sa nepodarilo uložiť: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Chyba pri ukladaní nastavení: $error';
  }

  @override
  String get repeater_refreshRadioSettings => 'Obnoviť nastavenia rádia';

  @override
  String get repeater_refreshPrivacyMode => 'Obnoviť režim súkromia';

  @override
  String get repeater_refreshAll => 'Obnoviť všetko';

  @override
  String get repeater_settingsNotLoaded =>
      'Nastavenia zatiaľ neboli načítané z tohto opakovača.';

  @override
  String get repeater_settingsLoadIncomplete =>
      'Niektoré nastavenia sa nepodarilo načítať. Na opakovanie použite tlačidlá obnovenia.';

  @override
  String repeater_refreshed(String label) {
    return '$label sa znova načítalo';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Chyba pri obnovení $label';
  }

  @override
  String get repeater_cliTitle => 'CLI opakovača';

  @override
  String get repeater_debugNextCommand => 'Ladiť nasledujúci príkaz';

  @override
  String get repeater_commandHelp => 'Pomocník k príkazom';

  @override
  String get repeater_clearHistory => 'Vymazať históriu';

  @override
  String get repeater_noCommandsSent =>
      'Zatiaľ neboli odoslané žiadne príkazy.';

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
  String get repeater_cliCommandFrameTitle => 'Rámec príkazu CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Získať názov';

  @override
  String get repeater_cliQuickGetRadio => 'Získať rádio';

  @override
  String get repeater_cliQuickGetTx => 'Získať TX';

  @override
  String get repeater_cliQuickNeighbors => 'Susedia';

  @override
  String get repeater_cliQuickVersion => 'Verzia';

  @override
  String get repeater_cliQuickAdvertise => 'Inzerovať';

  @override
  String get repeater_cliQuickClock => 'Hodiny';

  @override
  String get repeater_cliQuickClockSync => 'Synchronizácia hodín';

  @override
  String get repeater_cliQuickDiscovery => 'Objaviť susedov';

  @override
  String get repeater_cliHelpAdvert => 'Odosiela inzertný balíček.';

  @override
  String get repeater_cliHelpReboot =>
      'Reštartuje zariadenie. (pozn.: pravdepodobne dostanete \'Timeout\', čo je normálne)';

  @override
  String get repeater_cliHelpClock =>
      'Zobrazuje aktuálny čas podľa hodiniek zariadenia.';

  @override
  String get repeater_cliHelpPassword =>
      'Nastaví nové administrátorské heslo pre zariadenie.';

  @override
  String get repeater_cliHelpVersion =>
      'Zobrazuje verziu zariadenia a dátum zostavenia firmvéru.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resetuje rôzne štatistické počítadlá na nulu.';

  @override
  String get repeater_cliHelpSetAf =>
      'Nastaví faktor vysielacieho času (air-time factor).';

  @override
  String get repeater_cliHelpSetTx =>
      'Nastaví vysielací výkon LoRa v dBm. (na uplatnenie je potrebný reštart)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Zapne alebo vypne rolu opakovača pre tento uzol.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Server miestnosti) Ak je \'zapnuté\', potom bude povolený prístup s prázdnym heslom, ale nebude možné posielať správu do miestnosti. (iba čítať).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Nastaví maximálny počet skokov prichádzajúceho flood paketu (ak je >= max, paket sa nepreposiela)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Nastaví prah rušenia (v dB). Predvolená hodnota je 14. Nastavením na 0 sa vypne detekcia rušenia kanála.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Nastaví interval resetu automatického riadenia zosilnenia (AGC). Nastavenie na 0 funkciu vypne.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Zapne alebo vypne funkciu „dvojitých ACK“.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Nastavuje interval časovača v minútach na odoslanie miestneho (bezprostredného) inzertného paketu. Nastavenie na 0 vypne funkciu.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Nastavuje interval časovača v hodinách na odoslanie flood inzerátu. Nastavenie na 0 vypne.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Nastaví/aktualizuje heslo hosťa. (pri opakovačoch môžu prihlásenia hostí posielať požiadavku \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Nastaví názov inzerátu.';

  @override
  String get repeater_cliHelpSetLat =>
      'Nastaví geografickú šírku mapy inzerátu. (desatinné stupne)';

  @override
  String get repeater_cliHelpSetLon =>
      'Nastavuje longitúdu mapy inzerátu. (desatinné stupne)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Nastavuje úplne nové parametre rádia a uloží ich do preferencií. Požaduje príkaz \"reboot\" na aplikáciu.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Nastaví (experimentálny) základ (aby mal účinok, musí byť > 1) pre mierne oneskorenie prijatých paketov podľa sily signálu/skóre. Nastavenie na 0 funkciu vypne.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Nastaví faktor, ktorým sa násobí čas vysielania (time-on-air) paketu v režime flood a náhodný systém slotov, aby sa oneskorilo jeho preposlanie. (na zníženie pravdepodobnosti kolízií)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Podobne ako txdelay, ale pre aplikáciu náhodného oneskorenia pri preposlaní paketov v režime priameho prenosu.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Zapnúť/vypnúť most.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Nastaví oneskorenie pred opätovným odoslaním paketov.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Vyberte, či bude most opakovane vysielať prijaté alebo odoslané pakety.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Nastaví prenosovú rýchlosť (baud) sériového spojenia pre mosty rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Nastaví tajomstvo mosta pre mosty espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Nastaví vlastný faktor na úpravu hlásenej hodnoty napätia batérie (podporované len na vybraných doskách).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Nastaví dočasné rádiové parametre na zadaný počet minút, potom sa vráti k pôvodným rádiovým parametrom. (NEUKLADÁ do preferencií).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Upraví ACL. Odstráni zodpovedajúci záznam (podľa prefixu pubkey), ak je \"permissions\" rovné 0. Pridá nový záznam, ak je pubkey-hex plnej dĺžky a momentálne nie je v ACL. Aktualizuje záznam podľa zodpovedajúceho prefixu pubkey. Bity oprávnení sa líšia podľa roly firmvéru, ale nižšie 2 bity sú: 0 (hosť), 1 (iba čítanie), 2 (čítanie a zápis), 3 (administrátor)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Zobrazí typ mosta: none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Spustí zaznamenávanie paketov do súborového systému.';

  @override
  String get repeater_cliHelpLogStop =>
      'Zastaví zaznamenávanie paketov do súborového systému.';

  @override
  String get repeater_cliHelpLogErase =>
      'Odstráni záznamy paketov zo súborového systému.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Zobrazí zoznam ostatných opakovačov zachytených cez zero-hop inzeráty. Každý riadok je id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Odstráni prvú zhodujúcu položku (podľa prefixu pubkey (hex)) z zoznamu susedov.';

  @override
  String get repeater_cliHelpRegion =>
      '(iba sériovo) Zobrazí všetky definované regióny a aktuálne povolenia pre flood.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'POZNÁMKA: toto je špeciálne volanie s viacerými príkazmi. Každý ďalší príkaz je názov regiónu (odsadený medzerami na vyznačenie nadradenej hierarchie, minimálne jednou medzerou). Ukončí sa odoslaním prázdneho riadka/príkazu.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Vyhľadá región podľa zadanej predpony názvu (alebo \"*\" pre globálny rozsah). Odpovie \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Pridá alebo aktualizuje definíciu regiónu s daným menom.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Odstráni definíciu oblasti s daným názvom. (musí zodpovedať presne a nemala by mať podoblasti)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Nastaví povolenie \'F\'lood pre zadaný región. (\'*\' pre globálny/starý rozsah)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Odstráni povolenie \'F\'lood pre zadaný región. (POZNÁMKA: v tejto fáze sa NEODPORÚČA používať ho na globálnom/starom rozsahu!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odpovie aktuálnym \'domovským\' regiónom. (Poznámka: zatiaľ sa nikde nepoužíva, vyhradené pre budúcnosť)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Nastaví \'domovskú\' oblasť.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Uloží zoznam/mapu regiónov do úložiska.';

  @override
  String get repeater_cliHelpGps =>
      'Zobrazuje stav GPS. Ak je GPS vypnutý, odpovedá len \"off\", ak je zapnutý, odpovedá s \"on\", stavom, fixom a počtom satelitov.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Prepne stav napájania GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronizuje čas uzla s GPS hodinami.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Nastaví polohu uzla na GPS súradnice a uloží preferencie.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Zobrazí konfiguráciu inzerovania polohy uzla:\n- none: nezahrnúť polohu do inzerátov\n- share: zdieľať polohu GPS (zo SensorManager)\n- prefs: inzerovať polohu uloženú v nastaveniach';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Nastaví konfiguráciu inzerovania polohy.';

  @override
  String get repeater_commandsListTitle => 'Zoznam príkazov';

  @override
  String get repeater_commandsListNote =>
      'Poznámka: pre rôzne príkazy \"set ...\" existuje aj príkaz \"get ...\".';

  @override
  String get repeater_frequencyRangeHelper => '150-2500 MHz';

  @override
  String get repeater_frequencyInvalid => 'Neplatná frekvencia (150-2500 MHz)';

  @override
  String get repeater_txPowerRangeHelper => '-9 až 30 dBm';

  @override
  String get repeater_recvErrors => 'Chyby príjmu';

  @override
  String get room_postsStored => 'Príspevky';

  @override
  String get room_postsPushed => 'Odoslané príspevky';

  @override
  String get repeater_cliRegionLoadActive =>
      'Režim načítania regiónov: pošlite po jednom názve regiónu na riadok, odsadenom medzerami pod jeho nadradeným regiónom (pridaním F za názov povolíte flood). Riadky nedostanú odpoveď. Prázdnym riadkom ukončite a potom príkazom \"region save\" výsledok uložte.';

  @override
  String get repeater_cliRegionLoadHint =>
      'Riadok regiónu, alebo prázdny na ukončenie';

  @override
  String get repeater_cliRegionLoadEnd => '(koniec načítania regiónov)';

  @override
  String get repeater_cliHelpRegionDef =>
      'Definuje reťazec regiónov v jednom príkaze: každý názov sa pridá pod predchádzajúci; \"name,parent\" pridá názov a potom pokračuje pod zadaným nadradeným regiónom. Odpovie zoznamom regiónov.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Nastavuje maximálny počet skokov pri preposielaní flood paketov bez priradeného regiónu (0-64).';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Nastavuje maximálny počet skokov pri preposielaní flood inzerátov (0-64).';

  @override
  String get repeater_cliHelpGetFloodMaxUnscoped =>
      'Zobrazuje maximálny počet skokov pre flood pakety bez priradeného regiónu.';

  @override
  String get repeater_cliHelpGetFloodMaxAdvert =>
      'Zobrazuje maximálny počet skokov pre flood inzeráty.';

  @override
  String get repeater_cliHelpSetRadioFemRxGain =>
      'Prepína RX zosilnenie (LNA) LoRa front-end modulu. Dosky bez neho odpovedia \"Error: unsupported\".';

  @override
  String get repeater_cliHelpSetRadioFemTxGain =>
      'Prepína TX zosilnenie (PA) LoRa front-end modulu. Dosky bez neho odpovedia \"Error: unsupported\".';

  @override
  String get repeater_cliHelpGetRadioFemRxGain =>
      'Zobrazuje, či je zapnuté RX zosilnenie LoRa front-end modulu.';

  @override
  String get repeater_cliHelpGetRadioFemTxGain =>
      'Zobrazuje, či je zapnuté TX zosilnenie LoRa front-end modulu.';

  @override
  String get repeater_bridgeNote =>
      'Dostupné len vo firmvéri zostavenom s mostom (RS232 alebo ESP-NOW).';

  @override
  String get repeater_general => 'Všeobecné';

  @override
  String get repeater_settingsCategory => 'Nastavenia';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Zaznamenávanie';

  @override
  String get repeater_neighborsRepeaterOnly => 'Susedia (iba opakovač)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Správa regiónov (iba opakovač)';

  @override
  String get repeater_regionNote =>
      'Príkazy pre regióny boli zavedené na správu definícií regiónov a povolení.';

  @override
  String get repeater_gpsManagement => 'Správa GPS';

  @override
  String get repeater_gpsNote =>
      'Príkaz gps bol zavedený na správu tém súvisiacich s polohou.';

  @override
  String get repeater_getCategory => 'Získať hodnoty';

  @override
  String get repeater_powerMgmt => 'Správa energie';

  @override
  String get repeater_sensors => 'Senzory';

  @override
  String get repeater_cliHelpPowerOff =>
      'Vypína zariadenie. (neočakáva sa žiadna odpoveď)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Resetuje hodiny na známu epochu a reštartuje zariadenie.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Odošle zero-hop inzerát (iba bezprostrední susedia).';

  @override
  String get repeater_cliHelpStartOta =>
      'Spustí aktualizáciu firmvéru cez vzduch (OTA) na podporovaných doskách.';

  @override
  String get repeater_cliHelpTime =>
      'Nastaví hodiny zariadenia na zadaný počet sekúnd od Unix epochy. Hodiny sa nemôžu posunúť späť.';

  @override
  String get repeater_cliHelpBoard =>
      'Zobrazí výrobcu dosky / identifikátor hardvéru.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Odosiela požiadavku na nájdenie susedných uzlov. (Len pre opakovače)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Ukazuje, či je režim úspory energie zapnutý alebo vypnutý.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Umožňuje alebo vypína režim úspory energie (ak je podporovaný).';

  @override
  String get repeater_cliHelpErase =>
      '(Používa sa len pre sériové zariadenia) Formátuje systém súborov zariadenia. Vymaže všetky nastavenia a kontakty.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Nastaví maximálny povolený pracovný cyklus vysielania v percentách (1-100). Interne upraví faktor vysielacieho času.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'Nahradí súkromný kľúč identity zariadenia. Na uplatnenie je potrebný reštart. Vygeneruje nový verejný kľúč.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Iba SX126x) Zapína/vypína zosilnený príjem RX pre lepšiu citlivosť pri vyššom odbere prúdu.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Nastaví reťazec s kontaktnými údajmi vlastníka zahrnutý v inzerátoch. Pre nové riadky použite \'|\'.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Nastaví veľkosť ID uzla použitého v inzerátoch tohto opakovača: 0 = 1 bajt (až 64 skokov), 1 = 2 bajty (až 32 skokov), 2 = 3 bajty (až 21 skokov).';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Nastavuje citlivosť detekcie slučky routovania: vypnutá, minimálna, stredná alebo prísna.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Iba sériovo) Rýchlo nastaví len frekvenciu. Vyžaduje reštart. Pre všetky rádiové parametre uprednostnite \"set radio\".';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Iba most ESPNow) Nastaví kanál WiFi (1-14), ktorý most používa.';

  @override
  String get repeater_cliHelpGetName => 'Zobrazí nastavený názov uzla.';

  @override
  String get repeater_cliHelpGetRole =>
      'Zobrazí rolu firmvéru (opakovač, server miestnosti atď.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Zobrazuje verejný kľúč zariadenia.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Iba sériovo) Zobrazí súkromný kľúč zariadenia. Považujte ho za tajný.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Zobrazí, či je preposielanie paketov (rola opakovača) zapnuté alebo vypnuté.';

  @override
  String get repeater_cliHelpGetTx =>
      'Zobrazuje aktuálnu výkonovú hodnotu TX v dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Zobrazuje nakonfigurovanú frekvenciu v MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Zobrazí všetky rádiové parametre: frekvencia, šírka pásma, spreading factor, coding rate.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Iba SX126x) Zobrazí stav zosilneného príjmu RX.';

  @override
  String get repeater_cliHelpGetAf =>
      'Zobrazí aktuálny faktor vysielacieho času.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Zobrazí aktuálne povolený pracovný cyklus v percentách.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Zobrazí prah rušenia kanála v dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Zobrazuje interval reštartovania AGC v sekundách.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Zobrazí, či je režim dvojitých ACK zapnutý (1) alebo vypnutý (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Zobrazí, či je povolený prístup hostí iba na čítanie.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Zobrazí interval lokálnych inzerátov v minútach.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Zobrazuje časový interval flood inzerátu v hodinách.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Zobrazuje nastavené heslo pre hosta.';

  @override
  String get repeater_cliHelpGetLat => 'Zobrazuje nastavenú šírku.';

  @override
  String get repeater_cliHelpGetLon => 'Zobrazuje nastavenú dĺžku.';

  @override
  String get repeater_cliHelpGetRxDelay =>
      'Zobrazuje základnú hodnotu rxdelay.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Zobrazí faktor txdelay pre režim flood.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Zobrazí faktor txdelay pre priamy režim.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Zobrazuje maximálny počet skokov flood.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Zobrazí reťazec s kontaktnými údajmi vlastníka.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Zobrazí veľkosť ID uzla použitého v inzerátoch (0 = 1 bajt, 1 = 2 bajty, 2 = 3 bajty).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Ukazuje citlivosť na detekciu slučiek.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Iba sériovo) Zobrazí záznamy riadenia prístupu na opakovači.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Ukazuje, či je most povolený.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Zobrazí oneskorenie mosta v ms.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Zobrazí, či most zaznamenáva pakety RX alebo TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Iba most RS232) Zobrazí prenosovú rýchlosť (baud) mosta.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Iba most ESPNow) Zobrazí kanál WiFi mosta.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Iba most ESPNow) Zobrazí zdieľané tajomstvo mosta.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Iba NRF52) Zobrazí verziu bootloaderu.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Zobrazuje násobič ADC (škálovanie napätia batérie).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Oznámi, či doska podporuje správu napájania.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Ukazuje aktuálny zdroj napájania: externý alebo batéria.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Zobrazí najnovšie dôvody reštartu a vypnutia.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Zobrazuje napätie batérie pri spustení systému v milivoltov (mV).';

  @override
  String get repeater_cliHelpSensorGet =>
      'Prečíta vlastné nastavenie senzora podľa kľúča.';

  @override
  String get repeater_cliHelpSensorSet => 'Zapíše vlastné nastavenie senzora.';

  @override
  String get repeater_cliHelpSensorList =>
      'Zobrazí všetky vlastné nastavenia senzorov, stránkované od voliteľného počiatočného indexu.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Zobrazí aktuálny predvolený rozsah regiónu.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Nastaví predvolený rozsah regiónu. Na vymazanie použite \"<null>\".';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Zobrazí regióny, ktoré povoľujú flood prevádzku.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Zobrazí regióny, ktoré zakazujú flood prevádzku.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Iba sériovo) Zobrazí štatistiky na úrovni paketov.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Iba sériovo) Zobrazí štatistiky rádia.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Iba sériovo) Zobrazí základné štatistiky firmvéru.';

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
  String get telemetry_digitalInputLabel => 'Digitálny vstup';

  @override
  String get telemetry_digitalOutputLabel => 'Digitálny výstup';

  @override
  String get telemetry_analogInputLabel => 'Analógový vstup';

  @override
  String get telemetry_analogOutputLabel => 'Analógový výstup';

  @override
  String get telemetry_genericLabel => 'Všeobecný senzor';

  @override
  String get telemetry_luminosityLabel => 'Osvetlenie';

  @override
  String get telemetry_presenceLabel => 'Prítomnosť';

  @override
  String get telemetry_humidityLabel => 'Vlhkosť';

  @override
  String get telemetry_accelerometerLabel => 'Akcelerometer';

  @override
  String get telemetry_pressureLabel => 'Tlak';

  @override
  String get telemetry_altitudeLabel => 'Nadmorská výška';

  @override
  String get telemetry_frequencyLabel => 'Frekvencia';

  @override
  String get telemetry_percentageLabel => 'Percento';

  @override
  String get telemetry_concentrationLabel => 'Koncentrácia';

  @override
  String get telemetry_powerLabel => 'Výkon';

  @override
  String get telemetry_distanceLabel => 'Vzdialenosť';

  @override
  String get telemetry_energyLabel => 'Energia';

  @override
  String get telemetry_directionLabel => 'Smer';

  @override
  String get telemetry_timeLabel => 'Čas';

  @override
  String get telemetry_gyrometerLabel => 'Gyrometer';

  @override
  String get telemetry_colourLabel => 'Farba';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Prepínač';

  @override
  String get telemetry_polylineLabel => 'Lomená čiara';

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
  String get telemetry_autoFetchQuantity => 'Počet požiadaviek';

  @override
  String get telemetry_error => 'Nepodarilo sa získať údaje';

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
  String get channelPath_floodPath => 'Flood';

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
  String get listFilter_az => 'Od A po Z';

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
      'Jedna alebo viac skokov chýba lokalita!';

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
  String get losBlockedSpotsTitle => 'Zablokované miesta';

  @override
  String get losBlockedSpotsHint =>
      'Kliknite na zablokované miesto, aby ste ho zvýraznili na mape.';

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
  String get losSelectedObstructionTitle => 'Vybraná prekážka';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Blocked by $obstruction $heightUnit, $distanceFromA from A and $distanceFromB from B ($distanceUnit).';
  }

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
  String get discoveredContacts_export => 'Exportovať objavené kontakty';

  @override
  String get discoveredContacts_import => 'Importovať objavené kontakty';

  @override
  String discoveredContacts_exported(String path) {
    return 'Objavené kontakty boli exportované do $path.';
  }

  @override
  String discoveredContacts_exportFailed(String error) {
    return 'Export objavených kontaktov zlyhal: $error';
  }

  @override
  String discoveredContacts_imported(int count) {
    return 'Bolo importovaných $count objavených kontaktov.';
  }

  @override
  String get discoveredContacts_importNoContacts =>
      'V importovanom súbore sa nenašli žiadne kontakty.';

  @override
  String discoveredContacts_importSummary(
    int imported,
    int skipped,
    int invalid,
  ) {
    return 'Importované: $imported, preskočené (už známe): $skipped, nečitateľné záznamy: $invalid.';
  }

  @override
  String get discoveredContacts_importInvalidFile =>
      'Súbor nie je exportom objavených kontaktov.';

  @override
  String discoveredContacts_importTooLarge(int maxMb) {
    return 'Importovaný súbor je príliš veľký (maximum $maxMb MB).';
  }

  @override
  String discoveredContacts_importFailed(String error) {
    return 'Import objavených kontaktov zlyhal: $error';
  }

  @override
  String get contacts_zeroHopAdvert => 'Inzerát Zero Hop';

  @override
  String get contacts_floodAdvert => 'Flood inzerát';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopírovať inzerát do schránky';

  @override
  String get contacts_addContactFromClipboard => 'Pridať kontakt z schránky';

  @override
  String get contacts_scanQrCode => 'Skenovať QR kód';

  @override
  String get contacts_scanQrInstructions =>
      'Namerte kameru na QR kód kontaktu MeshCore';

  @override
  String get contacts_qrFromGallery => 'Skenovať QR kód z galérie';

  @override
  String get contacts_noQrCodeFound =>
      'Vo vybranom obrázku sa nenašiel žiadny QR kód.';

  @override
  String get contacts_qrGalleryFailed => 'Galériu sa nepodarilo otvoriť.';

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
  String get notification_lowBatteryTitle => 'Slabá batéria';

  @override
  String notification_lowBatteryBody(String deviceName, int percent) {
    return 'Batéria zariadenia $deviceName je na $percent %';
  }

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
  String get notification_sharedLocation => 'Zdieľal(a) polohu';

  @override
  String notification_sharedLocationNamed(String label) {
    return 'Zdieľal(a) polohu: $label';
  }

  @override
  String notification_reacted(String emoji) {
    return 'Reakcia $emoji';
  }

  @override
  String get notification_sentGif => 'Odoslal(a) GIF';

  @override
  String get notification_sentImage => 'Odoslal(a) obrázok';

  @override
  String get notification_actionReply => 'Odpovedať';

  @override
  String get notification_actionMarkRead => 'Označiť ako prečítané';

  @override
  String get notification_actionMuteChannel => 'Stlmiť kanál';

  @override
  String get notification_replyHint => 'Správa';

  @override
  String get notification_you => 'Vy';

  @override
  String get notification_replyFailedTitle => 'Odpoveď nebola odoslaná';

  @override
  String get notification_replyNotConnected =>
      'Nie je pripojené k rádiu. Znova sa pripojte v MeshCore Open a odošlite odpoveď ešte raz.';

  @override
  String get notification_replyTooLong =>
      'Vaša odpoveď je príliš dlhá na odoslanie z upozornenia. Pošlite ju namiesto toho z MeshCore Open.';

  @override
  String get notification_replyUnavailable =>
      'Táto konverzácia už nie je na pripojenom rádiu.';

  @override
  String get notification_replySendFailed =>
      'Vaša odpoveď možno nebola odoslaná. Skontrolujte to v MeshCore Open a skúste to znova.';

  @override
  String get notification_replyAppNotRunning =>
      'MeshCore Open nebeží. Otvorte ho a odošlite odpoveď ešte raz.';

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
  String get snrIndicator_nearByRepeatersDescription =>
      'Opakovače, ktoré vaše rádio počulo priamo, najskôr tie naposledy počuté.';

  @override
  String get snrIndicator_unknownRepeater => 'Neznámy opakovač';

  @override
  String get snrIndicator_unknownRepeaterHint =>
      'Tento opakovač zatiaľ nie je vo vašich kontaktoch. Jeho názov, poloha a možnosti sa zobrazia, keď rádio prijme jeho inzerát.';

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
  String get contactsSettings_evictDiscoveredContactsTitle =>
      'Odstraňovať objavené kontakty';

  @override
  String contactsSettings_evictDiscoveredContactsSubtitle(int limit) {
    return 'Keď je táto možnosť zapnutá, aplikácia odstráni najstaršie objavené kontakty, keď zoznam objavených dosiahne limit $limit záznamov.';
  }

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

  @override
  String get discoveredContacts_scan => 'Vyhľadať blízke uzly';

  @override
  String get discoveredContacts_scanTitle => 'Blízke uzly';

  @override
  String get discoveredContacts_scanExplanation =>
      'Požiada uzly v priamom dosahu rádia, aby sa identifikovali. Odpovedajú opakovače a senzory. Room servery a companiony zvyčajne nie.';

  @override
  String get discoveredContacts_scanning => 'Vyhľadávam…';

  @override
  String discoveredContacts_scanFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nájdených $count uzlov',
      many: 'Nájdených $count uzlov',
      few: 'Nájdené $count uzly',
      one: 'Nájdený 1 uzol',
    );
    return '$_temp0';
  }

  @override
  String get discoveredContacts_scanNoResults =>
      'Žiadny uzol neodpovedal. Opakovače obmedzujú frekvenciu odpovedí, skúste to znova o minútu.';

  @override
  String get discoveredContacts_scanAgain => 'Vyhľadať znova';

  @override
  String get discoveredContacts_scanFailed =>
      'Požiadavku na vyhľadávanie sa nepodarilo odoslať.';

  @override
  String discoveredContacts_scanSignal(String snr, String remoteSnr) {
    return 'Signál $snr dB · oni nás počuli na $remoteSnr dB';
  }

  @override
  String get discoveredContacts_scanInContacts => 'Už v kontaktoch';

  @override
  String get discoveredContacts_scanNameLater =>
      'Meno sa zobrazí po jeho ďalšom inzeráte';

  @override
  String get chat_sendCooldown => 'Prosím, počkajte chvíľu, než zašlete znova.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Prejsť na najstaršiu neprečítanú';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Pri otvorení chatu s neprečítanými správami prejsť na prvú neprečítanú namiesto poslednej.';

  @override
  String get appSettings_autoFetchRepeaterSettings =>
      'Automaticky načítať nastavenia opakovača';

  @override
  String get appSettings_autoFetchRepeaterSettingsSubtitle =>
      'Pri otvorení nastavení opakovača vyžiadať každé nastavenie. Každé je samostatná požiadavka cez LoRa, takže je to pomalé a spotrebúva vysielací čas. Keď je vypnuté, klepnite na Obnoviť všetko alebo obnovte jednotlivé sekcie.';

  @override
  String get appSettings_languageHu => 'Maďarský';

  @override
  String get appSettings_languageJa => 'Japonský';

  @override
  String get appSettings_languageKo => 'Kórejský';

  @override
  String get radioStats_tooltip => 'Statistiky rádiových a sieťových kanálov';

  @override
  String get radioStats_screenTitle => 'Štatistiky rádiových vysielaní';

  @override
  String get radioStats_sectionSignal => 'Signál';

  @override
  String get radioStats_sectionAirtime => 'Čas vysielania';

  @override
  String get radioStats_notConnected =>
      'Pripojte sa k zariadeniu, aby ste mohli sledovať štatistiky rádiového vysielania.';

  @override
  String get radioStats_firmwareTooOld =>
      'Statistické údaje z rádia vyžadujú sprievodný softvér verzie v8 alebo novšej.';

  @override
  String get radioStats_waiting => 'Čakám na údaje…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Úroveň hluku: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Posledný údaj RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Posledná hodnota SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Čas vysielania na TX (celkový): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Čas RX (celkový): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Úroveň šumu (dBm) pre posledné vzorky.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Úroveň hluku: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Získavanie údajov o rádiu…';

  @override
  String get radioStats_settingsTile => 'Štatistiky rádiových vysielaní';

  @override
  String get radioStats_settingsSubtitle =>
      'Úroveň hluku, RSSI, SNR a časové rozloženie';

  @override
  String get translation_title => 'Preklad';

  @override
  String get imageMessages_enableTitle => 'Zabezpečte zobrazi';

  @override
  String get imageMessages_enableSubtitle =>
      'Odeslanie obrazov pre mšťanie. Potrebujete jednorazové stáhnutie modelu obrazov.';

  @override
  String get imageMessages_modelSectionTitle => 'Model v kínajme';

  @override
  String get imageMessages_downloadModel => 'Stáhnie';

  @override
  String get imageMessages_cancelDownload => 'Zastavenie';

  @override
  String get imageMessages_removeModel => 'Vyhniť model';

  @override
  String get imageMessages_modelReady => 'Čiačný';

  @override
  String get imageMessages_modelNotPublished =>
      'Nesprávne vypisáné — tento prechovka nie môže jej stáhnuť.';

  @override
  String get imageMessages_downloadFailed =>
      'Model s obrázkom nemôžno sťažovať.';

  @override
  String get imageMessages_autoProcessTitle => 'Automaticky prepojiť slučaje.';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Rekonstruujte každý obraz tak, ako pridá. Používajete okolo 2 GB pamäti pre drugú hodinu; odložte rekonstrukciu tým kliknutím.';

  @override
  String get translation_enableTitle => 'Aktivovať preklad';

  @override
  String get translation_enableSubtitle =>
      'Prekladajte prichádzajúce správy a umožnite ich preklad pred odoslaním.';

  @override
  String get translation_composerTitle => 'Preložte pred odeslaním';

  @override
  String get translation_composerSubtitle =>
      'Riadi výchoce stav ikony pre preklad, ktorú používa program.';

  @override
  String get translation_autoIncomingTitle => 'Automaticky prekladať správy';

  @override
  String get translation_autoIncomingSubtitle =>
      'Automaticky prekladá správy pre upozornenia aj pre čet alebo kanál.';

  @override
  String get translation_translateMessage => 'Preložiť správu';

  @override
  String get translation_targetLanguage => 'Cieľový jazyk';

  @override
  String get translation_useAppLanguage => 'Použite jazyk aplikácie';

  @override
  String get translation_downloadedModelLabel => 'Stiahnutý model';

  @override
  String get translation_presetModelLabel =>
      'Prednastavený model od Hugging Face';

  @override
  String get translation_manualUrlLabel =>
      'Odkaz na manuál (v elektronickej forme)';

  @override
  String get translation_downloadModel => 'Stiahnuť model';

  @override
  String get translation_downloading => 'Stiahnutie...';

  @override
  String get translation_working => 'Práca...';

  @override
  String get translation_stop => 'Zastavte';

  @override
  String get translation_mergingChunks =>
      'Sliečenie stiahnutých častí do konečného súboru...';

  @override
  String get translation_downloadedModels => 'Stiahnuté modely';

  @override
  String get translation_deleteModel => 'Odstrániť model';

  @override
  String get translation_modelDownloaded => 'Model pre preklad bol stiahnutý.';

  @override
  String get translation_downloadStopped => 'Stiahnutie bolo prerušené.';

  @override
  String translation_downloadFailed(String error) {
    return 'Neúspešné stiahnutie: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Najprv zadajte URL pre konkrétny model.';

  @override
  String get scanner_linuxPairingShowPin => 'Zobraziť PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Skryť PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN pre párovanie cez Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Zadajte PIN pre $deviceName (ak neexistuje, nechajte prázdne).';
  }

  @override
  String get translation_messageTranslation => 'Preklad textu';

  @override
  String get translation_translateBeforeSending => 'Preložte pred odeslaním';

  @override
  String get translation_composerEnabledHint =>
      'Správy budú preložené, než budú odoslané.';

  @override
  String get translation_composerDisabledHint =>
      'Posielajte správy v pôvodnej písanom jazyku.';

  @override
  String translation_translateTo(String language) {
    return 'Preložte do $language';
  }

  @override
  String get translation_translationOptions => 'Možnosti prekladania';

  @override
  String get translation_systemLanguage => 'Jazyk systému';

  @override
  String get background_serviceTitle => 'MeshCore running';

  @override
  String get background_serviceText => 'Keeping BLE connected';

  @override
  String appSettings_translationModelDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Failed to update channel: $error';
  }

  @override
  String get contact_typeChat => 'Chat';

  @override
  String get contact_typeRepeater => 'Repeater';

  @override
  String get contact_typeRoom => 'Room';

  @override
  String get contact_typeSensor => 'Sensor';

  @override
  String get contact_typeUnknown => 'Unknown';

  @override
  String get map_zoomIn => 'Zväčšiť';

  @override
  String get map_zoomOut => 'Zmenť zamer zblízka';

  @override
  String get map_centerMap => 'Mapa centra';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth vyžaduje prehliadač Chromium.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS potvrdilo';

  @override
  String get pathTrace_legendInferred => 'Odvodená poloha';

  @override
  String get pathMap_viewSingle => 'Jednotlivý';

  @override
  String get pathMap_viewCombined => 'Spojené';

  @override
  String get pathMap_play => 'Prehrať';

  @override
  String get pathMap_pause => 'Pozastaviť';

  @override
  String get pathMap_replay => 'Prehrať znova';

  @override
  String get pathMap_stepBack => 'Predchádzajúci skok';

  @override
  String get pathMap_stepForward => 'Nasledujúci skok';

  @override
  String get pathMap_animationOn => 'Zobraziť animáciu paketu';

  @override
  String get pathMap_animationOff => 'Skryť animáciu paketu';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Skok $current z $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Pozorované cesty: $count';
  }

  @override
  String get pathMap_primary => 'Primárna';

  @override
  String pathMap_alternate(int index) {
    return 'Alternatívny $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skokov',
      few: '$count skoky',
      one: '1 skok',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Spoločný segment';

  @override
  String get pathMap_legendEstimated => 'Odhadovaný segment';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Používané $count cestami';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skokov nemá polohu — zobrazená trasa je neúplná',
      few: '$count skoky nemajú polohu — zobrazená trasa je neúplná',
      one: '1 skok nemá polohu — zobrazená trasa je neúplná',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Zobraziť všetky';

  @override
  String get pathMap_hidePath => 'Skryť cestu';

  @override
  String get pathMap_showPath => 'Zobraziť trasu';

  @override
  String get pathMap_collapsePanel => 'Zatvoriť panel';

  @override
  String get pathMap_expandPanel => 'Rozbaliť panel';

  @override
  String get pathMap_noLocation => 'Bez polohy';

  @override
  String get pathMap_followPacket => 'Uzamknúť pohľad na paket';

  @override
  String get pathMap_unfollowPacket => 'Odomknúť pohľad od paketu';

  @override
  String get imageSend_title => 'Vyslat obraz';

  @override
  String get imageSend_cropNote =>
      'Zmeneno na 512 × 512 · vzorýst nie byl zachovan';

  @override
  String imageSend_lossyNote(int bytes) {
    return 'Komprimované približne na $bytes bajtov. Model príjemcu obraz zrekonštruuje, takže detaily sa budú líšiť.';
  }

  @override
  String get imageSend_viewOriginal => 'Originál';

  @override
  String get imageSend_viewReconstruction => 'Čo vidia príjemcovia';

  @override
  String get imageSend_reconstructionUnavailable =>
      'Toto zariadenie nedokáže zobraziť náhľad rekonštrukcie.';

  @override
  String get imageSend_modelNotDownloaded =>
      'Model obrazu ešte nie je stiahnutý. Stiahnite ho v Nastaveniach, aby ste mohli posielať obrázky.';

  @override
  String get imageSend_originalSize =>
      'Výborný text:\n\n\"Language is the road map of a culture. It tells us where to go as a society and helps us understand the world around us. Learning a new language opens up new perspectives and opportunities, allowing us to connect with people from different backgrounds and build bridges between cultures.\"\n\nSlovenská preklada:\n\n\"Jazyk je cesta pre zručnosti a odráža kultúru. Dá nám uvedomi, dokádať, kúdy sa pohladneme a pomáha našej společnosti poradiť sa v rôznych okolnosti a porozumieť o svetu kolem nás. Nauka nového jazyka otviera nové perspektívy a možnosti, čo pohybuje našu schopnosť sa spoluprávať s ľudmi z rôznych okolnosti a budovať mosty medzi kultúry.\"';

  @override
  String get imageSend_onAirSize => 'V prúce';

  @override
  String get imageSend_quality => 'Kvalita';

  @override
  String get imageSend_qualityStandard => 'Stándard';

  @override
  String get imageSend_qualityHigh => 'Vysoká';

  @override
  String get imageSend_packetsLabel => 'Pakety';

  @override
  String get imageSend_airtimeLabel => 'Čas na anteni';

  @override
  String get imageSend_sizeLabel => 'Základ';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paketov',
      one: 'paket',
    );
    return '$count $_temp0';
  }

  @override
  String imageSend_range(String min, String max) {
    return '$min–$max';
  }

  @override
  String get imageSend_unknownValue => '—';

  @override
  String get imageSend_radioUnknownTitle => 'Nastavenia radio nezná';

  @override
  String get imageSend_radioUnknownBody =>
      'Zkonečte s určým prijemcem, aby sa mohlo výpočet času, ktorý je v prúbežu.';

  @override
  String get imageSend_longSendTitle => 'Dlouhá transmisia';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Tento dôvod udrží kanál priamo na $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Flood routing: každý repeater v rozsahu zrňa každý paket, takže kanál zostá zajetší dlouše, než tu.';

  @override
  String get imageSend_parityTitle => 'Poučný paket pre očudenie';

  @override
  String get imageSend_paritySubtitle =>
      'Jedný dodatný paket. Skúsené súhlasy nie sa uznávaú, takže to umožňuje prechovávaču opraviť obraz, pokiaľ sa jedný paket niebyl ztrácený.';

  @override
  String get imageSend_send => 'Odeslať';

  @override
  String get imageSend_cancel => 'Zastavenie';

  @override
  String get imageSend_encodeFailed => 'Tento obráz nie byla byla schována.';

  @override
  String get imageSend_codecDownloading =>
      'Model prehľadovania prebeža stále stále stále prechádza.';

  @override
  String get imageSend_codecUnavailable =>
      'Zobrazenie nie je dostupný na tomto zariadení.';

  @override
  String get imageSend_codecDisabled =>
      'Zobrazy s prešteľkami sú v nastavení vypnené.';

  @override
  String get imageSend_deviceUnsupported =>
      'Tento radiok nie môže odeslať obrazové pakety. Podeďte správne určité zařízení s oprogramovaním spolupráce 13 alebo novším.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'Obrazy sa prechádzajú jako skupinové údaje, preto sa ich môžu odeslať len na kanál — nie v príbeh sa.';

  @override
  String get imageSend_tooLarge =>
      'Tento obraz byl skodyrovany do viac paketov, ako umožňuje si sítka format.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paketov',
      one: 'paket',
    );
    return 'Obrázok odoslaný ako $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'Obraz nemôžlo odeslať: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Vysyťanie obrazu — pakét $sent z $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Vęzlo $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return 'Otrzymané $received z $total pakotí';
  }

  @override
  String get receivedImage_queued => 'Čekanie na dekódovanie';

  @override
  String get receivedImage_tapToDecode => 'Kliknite, aby dekódovať';

  @override
  String get receivedImage_decoding => 'Rekonstrukcia… o čoľve 1 s';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Obraz nieješťajný — $received z $total paciek príšlo';
  }

  @override
  String get receivedImage_corrupt => 'Obraz nemôžu byť prepojený';

  @override
  String get receivedImage_decoderMissing =>
      'Otrzymaná slúba — dekódovanie slúby je vypadejce';

  @override
  String get receivedImage_evicted => 'Obraz nemá uložený';

  @override
  String get receivedImage_retry => 'Zkôr to opítajte';

  @override
  String get receivedImage_decodeAgain => 'Zdeľte sa znovu';

  @override
  String get receivedImage_openSettings => 'Založte';

  @override
  String get receivedImage_tapToProcess => 'Ukliknite, aby sa príjomili';

  @override
  String get receivedImage_save => 'Uložiť obrázok';

  @override
  String receivedImage_shareCaption(int bytes) {
    return 'Zrekonštruované umelou inteligenciou z $bytes bajtov; jemné detaily sú generované, nie prenášané.';
  }

  @override
  String get receivedImage_packetInfo => 'Informácie o pakete';

  @override
  String get receivedImage_parityRecovered =>
      'Jeden paket bol zrekonštruovaný z paketu na obnovu.';

  @override
  String receivedImage_decodeTime(int ms) {
    return 'Zrekonštruované za $ms ms';
  }

  @override
  String get receivedImage_saveFailed => 'Nepodarilo sa uložiť obrázok';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'paketov',
      one: 'paket',
    );
    return '$bytes bajtov · $packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds s';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String chat_longMessageRetryNote(int count) {
    return 'Nad 158 bajtov: odoslané najviac $count-krát';
  }

  @override
  String get reviewMode_dialogTitle => 'Vstúpiť do režimu kontroly?';

  @override
  String get reviewMode_dialogBody =>
      'Režim kontroly sa pripojí k simulovanému rádiu s ukážkovými kontaktmi, kanálmi a správami. Skutočné rádio nie je potrebné.';

  @override
  String get reviewMode_confirm => 'Vstúpiť';

  @override
  String get reviewMode_cancel => 'Zrušiť';

  @override
  String get reviewMode_banner => 'Režim kontroly — simulované údaje';

  @override
  String get reviewMode_sendTest => 'Poslať testovaciu správu';

  @override
  String get reviewMode_testSent => 'Čoskoro príde testovacia správa.';

  @override
  String get reviewMode_exit => 'Ukončiť';

  @override
  String reviewMode_connectFailed(String error) {
    return 'Režim kontroly sa nepodarilo spustiť: $error';
  }

  @override
  String get channels_waitForSync =>
      'Kanály sa ešte načítavajú z rádia. Skúste to znova po dokončení synchronizácie.';

  @override
  String channels_nameTooLong(int maxBytes) {
    return 'Názov je príliš dlhý (max. $maxBytes bajtov).';
  }

  @override
  String repeater_valueRequired(String field) {
    return '$field: zadajte hodnotu';
  }

  @override
  String get repeater_floodMaxAdvert =>
      'Maximálny počet skokov flood pre advert';

  @override
  String get repeater_floodMaxAdvertHelper =>
      'Maximálny počet skokov, ktoré môže prejsť rozosielaný advert (0-64, predvolene 8)';

  @override
  String get repeater_floodMaxUnscoped =>
      'Maximálny počet skokov flood bez regiónu';

  @override
  String get repeater_floodMaxUnscopedHelper =>
      'Maximálny počet skokov pre flood bez regiónu (0-64, predvolene 64). Nízka hodnota, napríklad 3, udrží premávku bez regiónu lokálnu.';

  @override
  String get repeater_floodMaxUnscopedUnset => 'Rovnaké ako flood max';

  @override
  String get repeater_rxDelay => 'Oneskorenie príjmu';

  @override
  String get repeater_rxDelayHelper =>
      'Pozdrží flood pakety zachytené so slabým signálom pred preposlaním, aby cesty so silným signálom išli prvé a odosielalo sa menej duplikátov (0-20, 0 to vypne).';

  @override
  String get repeater_cad => 'Detekcia aktivity kanála';

  @override
  String get repeater_cadHelper =>
      'Pred vysielaním počúva, či na kanáli nie je aktivita, a počká, kým je kanál obsadený. Funguje spolu s hranicou rušenia.';

  @override
  String get repeater_adcMultiplier => 'Kalibrácia napätia batérie';

  @override
  String get repeater_adcMultiplierHelper =>
      'Násobiteľ pre meranie napätia batérie (0-10). 0 použije predvolenú hodnotu dosky.';

  @override
  String get repeater_boardSupportNote =>
      'Nie každá doska to podporuje. Nepodporované dosky zmenu odmietnu.';

  @override
  String get repeater_extraSf => 'Ďalšie spreading faktory';

  @override
  String get repeater_extraSfHelper =>
      'Až 3 ďalšie spreading faktory, na ktorých sa súčasne počúva, oddelené čiarkami (napríklad 9,10). Ak chcete vypnúť, nechajte prázdne.';

  @override
  String get repeater_lr2021Only =>
      'Len pre opakovače s rádiom LR2021. Ostatné opakovače toto nastavenie nemajú a odmietnu ho.';

  @override
  String get losMapDetailTooltip => 'Detail mapy';

  @override
  String get losUnitsTooltip => 'Jednotky';

  @override
  String get losDistance => 'Vzdialenosť';

  @override
  String get losClearance => 'Voľný priestor';

  @override
  String get losBlockedBy => 'Blokované';

  @override
  String get losObstruction => 'Prekážka';

  @override
  String losDistanceFromA(String distance) {
    return '$distance od A';
  }

  @override
  String get losWorstBadge => 'NAJHORŠIA';

  @override
  String losBlockedAmount(String amount) {
    return 'Blokované $amount';
  }

  @override
  String get losFromA => 'Od A';

  @override
  String get losFromB => 'Od B';

  @override
  String get losElevation => 'Výška';

  @override
  String get losCenterOnMap => 'Vycentrovať na mape';

  @override
  String get losStatusClear => 'Voľné';

  @override
  String get losStatusMarginal => 'Hraničné';

  @override
  String get losStatusBlocked => 'Blokované';

  @override
  String get losStatusCheckingShort => 'Kontrola';

  @override
  String get losStatusNoResult => 'Žiadny výsledok';

  @override
  String get losSelectedPill => 'Vybrané';

  @override
  String get gif_tapToLoad => 'Klepnutím načítate GIF';

  @override
  String get gif_loadFailedRetry =>
      'GIF sa nepodarilo načítať\nKlepnutím skúste znova';

  @override
  String get qr_cameraPermissionDenied =>
      'Povolenie kamery bolo zamietnuté.\nPovoľte prístup ku kamere v nastaveniach.';

  @override
  String get qr_cameraUnsupported =>
      'Kamera nie je na tomto zariadení podporovaná.';

  @override
  String qr_cameraStartFailed(String details) {
    return 'Kameru sa nepodarilo spustiť.\n$details';
  }

  @override
  String imageMessages_downloadFailedWithError(String error) {
    return 'Model obrázkov sa nepodarilo stiahnuť: $error';
  }

  @override
  String get map_nodeId => 'ID';

  @override
  String get map_markerHideHint =>
      'Skryť: značka zostane skrytá, kým neopustíte mapu.';

  @override
  String get map_markerRemoveHint =>
      'Odstrániť: značka zostane skrytá, kým ju neobnovíte v ponuke filtra.';

  @override
  String get map_markerRemoved => 'Značka bola odstránená';

  @override
  String get map_restoreRemovedMarkers => 'Obnoviť odstránené značky';

  @override
  String map_restoreRemovedMarkersSubtitle(int count) {
    return 'Odstránené: $count';
  }

  @override
  String map_markersRestored(int count) {
    return 'Obnovené značky: $count';
  }

  @override
  String get map_setLocationConfirmTitle => 'Nastaviť ako vašu polohu?';

  @override
  String map_setLocationConfirmBody(String lat, String lon) {
    return 'Váš uzol bude oznamovať túto polohu:\n$lat, $lon';
  }

  @override
  String get map_setLocationAction => 'Nastaviť polohu';

  @override
  String get map_locationSetSuccess => 'Poloha uzla bola aktualizovaná';

  @override
  String get map_locationSetFailed =>
      'Zariadenie nepotvrdilo novú polohu. Skúste to znova.';

  @override
  String map_poiClusterTitle(int count) {
    return 'Značiek tu: $count';
  }

  @override
  String map_poiClusterSemantics(int count) {
    return 'Zdieľané značky: $count. Klepnutím ich zobrazíte.';
  }

  @override
  String map_youWithMarkers(int count) {
    return 'Vy a značky: $count';
  }

  @override
  String map_sharedMarkerSemantics(String label) {
    return 'Zdieľaná značka: $label';
  }

  @override
  String map_nodeMarkerSemantics(String name, String type, String status) {
    return '$name, $type, $status';
  }

  @override
  String get map_requestLocation => 'Aktualizovať polohu';

  @override
  String get map_locationUpdated => 'Poloha aktualizovaná';

  @override
  String map_locationNotShared(String name) {
    return '$name odpovedal bez polohy';
  }

  @override
  String map_locationRequestFailed(String name) {
    return 'Žiadna odpoveď od $name';
  }

  @override
  String mapCache_zoomLevel(int zoom) {
    return 'Priblíženie $zoom';
  }

  @override
  String mapCache_sizeBytes(String size) {
    return '$size B';
  }

  @override
  String mapCache_sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String mapCache_sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String mapCache_sizeGigabytes(String size) {
    return '$size GB';
  }

  @override
  String mapCache_downloadCancelled(int count) {
    return 'Sťahovanie bolo zrušené. Uložených dlaždíc: $count.';
  }

  @override
  String get mapCache_tooManyTilesTitle => 'Oblasť je príliš veľká';

  @override
  String mapCache_tooManyTiles(int count, int max) {
    return 'Táto oblasť vyžaduje $count dlaždíc, čo je viac ako limit $max. Vyberte menšiu oblasť alebo znížte maximálne priblíženie.';
  }

  @override
  String get chat_clearChatConfirm =>
      'Týmto sa z tohto zariadenia vymažú všetky správy v tejto konverzácii. Túto akciu nie je možné vrátiť späť.';

  @override
  String get channels_clearChatConfirm =>
      'Týmto sa z tohto zariadenia vymažú všetky správy v tomto kanáli vrátane prijatých obrázkov. Túto akciu nie je možné vrátiť späť.';

  @override
  String get channels_timeNow => 'teraz';

  @override
  String channels_timeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String channels_timeHours(int hours) {
    return '${hours}h';
  }

  @override
  String channels_timeDays(int days) {
    return '${days}d';
  }

  @override
  String channels_indexChip(int index) {
    return 'KAN $index';
  }

  @override
  String get reaction_unknownSender => 'Neznámy';

  @override
  String get pathMap_noSelfGpsFix => 'Lokálny uzol nemá GPS fix';

  @override
  String pathTrace_sendFailed(String error) {
    return 'Sledovanie cesty sa nepodarilo odoslať: $error';
  }

  @override
  String get losErrorNoInternet =>
      'Údaje o nadmorskej výške vyžadujú pripojenie k internetu';

  @override
  String get losResultStale => 'Zastarané: výška antény sa zmenila';

  @override
  String losSnrValue(String snr) {
    return '$snr dB';
  }

  @override
  String losFrequencyValue(String frequency) {
    return '$frequency MHz';
  }

  @override
  String losKFactorValue(String kFactor) {
    return 'k=$kFactor';
  }

  @override
  String get losEndpointA => 'A';

  @override
  String get losEndpointB => 'B';

  @override
  String get units_km => 'km';

  @override
  String get units_mi => 'mi';

  @override
  String get units_m => 'm';

  @override
  String get units_ft => 'ft';

  @override
  String get telemetry_loading => 'Načítavajú sa telemetrické údaje…';

  @override
  String telemetry_axisValue(String x, String y, String z) {
    return 'X: $x, Y: $y, Z: $z';
  }

  @override
  String telemetry_colourValue(String red, String green, String blue) {
    return 'R: $red, G: $green, B: $blue';
  }

  @override
  String telemetry_altitudeValueFeet(String feet) {
    return '$feet ft';
  }

  @override
  String telemetry_distanceValueFeet(String feet) {
    return '$feet ft';
  }

  @override
  String get settings_notConnectedError =>
      'Nie ste pripojení k rádiu. Pripojte sa a skúste to znova.';

  @override
  String get settings_requiresConnection => 'Na použitie pripojte rádio';

  @override
  String settings_txPowerInvalidRange(int min, int max) {
    return 'Neplatný výkon TX ($min až $max dBm)';
  }

  @override
  String get settings_contactSettingsSaved =>
      'Nastavenia kontaktu boli uložené';

  @override
  String get settings_batteryToggleHint =>
      'Klepnutím prepnete medzi percentami a napätím';

  @override
  String get settings_publicKeyCopyHint => 'Kopírovať verejný kľúč';

  @override
  String get settings_locationClearHelper =>
      'Ak chcete odstrániť svoju polohu, nechajte obe polia prázdne.';

  @override
  String get settings_locationCleared => 'Poloha bola odstránená';

  @override
  String get settings_regionFetchDiscovering => 'Hľadajú sa blízke opakovače…';

  @override
  String settings_regionFetchProgress(int current, int total) {
    return 'Dopytuje sa opakovač $current z $total…';
  }

  @override
  String get settings_regionFetchNoRepeaters =>
      'Zatiaľ nie sú známe žiadne opakovače. Pridajte opakovač medzi kontakty alebo počkajte na jeho oznam a skúste to znova.';

  @override
  String get settings_regionFetchNoneResponded =>
      'Blízke opakovače neodpovedali. Priblížte sa k opakovaču a skúste to znova.';

  @override
  String appSettings_sourceSummary(String label, String description) {
    return '$label - $description';
  }

  @override
  String get appSettings_routingSection => 'Smerovanie';

  @override
  String get appSettings_resetRoutingToDefault =>
      'Obnoviť algoritmus smerovania na predvolené';

  @override
  String get appSettings_resetRoutingToDefaultSubtitle =>
      'Obnoviť nastavenia algoritmu smerovania na továrne predvolené hodnoty';

  @override
  String get appSettings_routingResetToDefault =>
      'Nastavenia algoritmu smerovania obnovené na predvolené';

  @override
  String get appSettings_imageMessagesSection => 'Obrazové správy';

  @override
  String get appSettings_showApiKey => 'Zobraziť API kľúč';

  @override
  String get appSettings_hideApiKey => 'Skryť API kľúč';

  @override
  String get translation_defaultModelName => 'Model';

  @override
  String translation_downloadProgressBytes(String fileName, String current) {
    return '$fileName: $current MB';
  }

  @override
  String translation_downloadProgressTotal(
    String fileName,
    String current,
    String total,
    String percent,
  ) {
    return '$fileName: $current / $total MB ($percent%)';
  }

  @override
  String translation_downloadedModelDetails(String size, String source) {
    return '$size MB • $source';
  }

  @override
  String get repeater_radioDisconnected => 'Rádio je odpojené';

  @override
  String get repeater_radioDisconnectedHint =>
      'Znova sa pripojte k rádiu, aby ste mohli odosielať príkazy, obnovovať alebo ukladať zmeny.';

  @override
  String get repeater_cliSend => 'Odoslať príkaz';

  @override
  String get repeater_cliCopyTranscript => 'Kopírovať prepis';

  @override
  String get repeater_cliShareTranscript => 'Zdieľať prepis';

  @override
  String get repeater_cliTranscriptCopied => 'Prepis bol skopírovaný';

  @override
  String get repeater_cliClearHistoryConfirm =>
      'Vymazať históriu príkazov? Túto akciu nie je možné vrátiť späť.';

  @override
  String get repeater_cliSearchCommands => 'Hľadať príkazy';

  @override
  String get repeater_cliNoMatchingCommands => 'Žiadne zodpovedajúce príkazy';

  @override
  String get debugLog_clearConfirm =>
      'Vymazať všetky záznamy denníka? Túto akciu nie je možné vrátiť späť.';

  @override
  String get repeater_unsavedChangesTitle => 'Neuložené zmeny';

  @override
  String get repeater_unsavedChangesMessage =>
      'Máte zmeny, ktoré neboli uložené do opakovača.';

  @override
  String get repeater_discardChanges => 'Zahodiť';

  @override
  String repeater_actionSentNoReply(String action) {
    return '$action: príkaz bol odoslaný. Opakovač na tento príkaz neodpovedá.';
  }

  @override
  String repeater_invalidSettingValue(String setting, String value) {
    return '$setting: hodnota $value nie je platná';
  }

  @override
  String repeater_prvKeyLengthError(int length) {
    return 'Súkromný kľúč musí mať presne $length hexadecimálnych znakov';
  }

  @override
  String get contacts_advertFailed => 'Oznam sa nepodarilo odoslať';

  @override
  String get contacts_manageGroups => 'Spravovať skupiny';

  @override
  String contacts_keyPrefixSemantics(String prefix) {
    return 'Prefix kľúča $prefix';
  }

  @override
  String community_shortId(String id) {
    return 'ID: $id…';
  }

  @override
  String get tcpSectionTitle => 'TCP / IP';

  @override
  String get tcpConnectedToHeader => 'Pripojené k';

  @override
  String get usbChooseSerialPort => 'Vyberte sériový port';

  @override
  String neighbors_durationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String neighbors_durationMinutes(int minutes, String seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String neighbors_durationHours(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get networkMap_settingsSection => 'Sieťová mapa';

  @override
  String get networkMap_uploadTitle => 'Zdieľať, čo počuje moje rádio';

  @override
  String get networkMap_uploadExplanation =>
      'Keď je to zapnuté a rádio je pripojené, aplikácia odosiela na sieťovú mapu MeshCore Open stručný súhrn paketov, ktoré vaše rádio počuje, aby každý videl, aké opakovače existujú a ako sú prepojené. Odosiela typ, trasu, počet skokov, silu signálu a veľkosť každého paketu, ako aj názvy opakovačov a ich približnú polohu z ich vlastných inzerátov. Nikdy neodosiela text správ, kto s kým komunikuje, názvy kanálov, vaše kontakty ani vašu presnú polohu: polohy sa zaokrúhľujú na približne 2 km a aplikácia dostáva nové náhodné ID každý deň.';

  @override
  String get networkMap_whatWeCollect => 'Čo zbierame';

  @override
  String get networkMap_promptTitle => 'Pomôcť budovať sieťovú mapu?';

  @override
  String get networkMap_promptBody =>
      'MeshCore Open môže zdieľať, čo vaše rádio počuje, s verejnou sieťovou mapou na map.meshcoreopen.org, aby každý videl, aké opakovače existujú a ako sú prepojené.\n\nNikdy neodosiela text správ, kto s kým komunikuje, názvy kanálov, vaše kontakty ani vašu presnú polohu. Polohy sa zaokrúhľujú na približne 2 km.';

  @override
  String get networkMap_promptSettingsHint =>
      'Môžete to kedykoľvek zmeniť v Nastavenia → Nastavenia aplikácie → Sieťová mapa.';

  @override
  String get networkMap_promptAccept => 'Zdieľať';

  @override
  String get networkMap_promptDecline => 'Nie, ďakujem';

  @override
  String get networkMap_statusOff => 'Vypnuté. Nič sa neodosiela.';

  @override
  String get networkMap_statusWaiting =>
      'Zapnuté. Čaká sa na pripojenie rádia.';

  @override
  String get networkMap_statusNothingSent => 'Zapnuté. Zatiaľ nič neodoslané.';

  @override
  String networkMap_statusLastSent(String time, int count) {
    return 'Naposledy odoslané $time. Dnes paketov: $count.';
  }

  @override
  String get networkMap_sourceLocal => 'Lokálna';

  @override
  String get networkMap_sourceOnline => 'Online';

  @override
  String get networkMap_sourceBoth => 'Obe';

  @override
  String get networkMap_sourceLocalHint => 'Uzly, ktoré vaše rádio zachytilo';

  @override
  String get networkMap_sourceOnlineHint => 'Opakovače z online mapy siete';

  @override
  String get networkMap_sourceBothHint =>
      'Uzly vášho rádia a online mapa siete';

  @override
  String get networkMap_zoomInHint =>
      'Priblížte, aby ste videli online sieťovú mapu';

  @override
  String get networkMap_loadFailed =>
      'Online sieťovú mapu sa nepodarilo načítať';

  @override
  String get networkMap_inYourContacts => 'Vo vašich kontaktoch';

  @override
  String get networkMap_status => 'Stav';

  @override
  String get networkMap_statusActive => 'Aktívny za poslednú hodinu';

  @override
  String get networkMap_statusRecent => 'Počuť za posledný deň';

  @override
  String get networkMap_statusStale => 'Dlho nepočuť';

  @override
  String get networkMap_confirmed => 'Potvrdený';

  @override
  String get networkMap_singleSource => 'Jeden zdroj, zatiaľ nepotvrdený';

  @override
  String get networkMap_reports => 'Hlásenia';

  @override
  String get networkMap_locationEstimated =>
      'Približná poloha, odhadnutá podľa toho, kto ho počul';

  @override
  String get networkMap_locationAdvertised =>
      'Približná poloha, z vlastného inzerátu';

  @override
  String get networkMap_heardByRadio => 'Počuté vaším rádiom';

  @override
  String get networkMap_inYourArea => 'Vo vašej oblasti';

  @override
  String get networkMap_farAway => 'Ďaleko. Správa ho nedosiahne.';

  @override
  String get networkMap_addToContacts => 'Pridať do kontaktov';

  @override
  String get networkMap_manage => 'Spravovať';

  @override
  String get networkMap_addedToContacts => 'Pridané do kontaktov';

  @override
  String get networkMap_addFailed => 'Nepodarilo sa pridať do kontaktov';

  @override
  String get networkMap_unnamed => 'Nepomenovaný opakovač';
}
