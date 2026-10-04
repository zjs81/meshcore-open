// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Contacten';

  @override
  String get nav_channels => 'Kanalen';

  @override
  String get nav_map => 'Kaart';

  @override
  String get common_cancel => 'Annuleren';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Verbinden';

  @override
  String get common_unknownDevice => 'Onbekend apparaat';

  @override
  String get common_save => 'Opslaan';

  @override
  String get common_delete => 'Verwijderen';

  @override
  String get common_deleteAll => 'Alles verwijderen';

  @override
  String get common_close => 'Sluiten';

  @override
  String get common_done => 'Klaar';

  @override
  String get common_edit => 'Bewerken';

  @override
  String get common_add => 'Toevoegen';

  @override
  String get common_settings => 'Instellingen';

  @override
  String get common_disconnect => 'Verbinding verbreken';

  @override
  String get common_connected => 'Verbonden';

  @override
  String get common_disconnected => 'Verbinding verbroken';

  @override
  String get common_create => 'Aanmaken';

  @override
  String get common_continue => 'Doorgaan';

  @override
  String get common_share => 'Delen';

  @override
  String get common_copy => 'Kopiëren';

  @override
  String get common_retry => 'Nogmaals proberen';

  @override
  String get common_hide => 'Verbergen';

  @override
  String get common_remove => 'Verwijderen';

  @override
  String get common_enable => 'Inschakelen';

  @override
  String get common_disable => 'Uitschakelen';

  @override
  String get common_undo => 'Ongedaan maken';

  @override
  String get messageStatus_sent => 'Verzonden';

  @override
  String get messageStatus_delivered =>
      'Afgeleverd. Het contact heeft de ontvangst bevestigd.';

  @override
  String get messageStatus_pending => 'Verzenden';

  @override
  String get messageStatus_failed => 'Niet verzonden';

  @override
  String get messageStatus_repeated => 'Herhaald gehoord';

  @override
  String get messageStatus_failedChannel =>
      'Je radio kon dit bericht niet verzenden.';

  @override
  String messageStatus_resending(int resends, int maxResends) {
    return 'Nog niet via genoeg repeaters gehoord. $resends van $maxResends keer opnieuw verzonden.';
  }

  @override
  String messageStatus_hopsNotReached(int hops, int required) {
    return 'Verzonden, maar slechts via $hops van $required repeaters teruggehoord. Het kan verder zijn gekomen dan je radio kan horen.';
  }

  @override
  String get messageStatus_sentChannel =>
      'Verzonden. Kanalen bevestigen geen aflevering, dus dit betekent alleen dat je radio het heeft verzonden.';

  @override
  String get messageStatus_sentDirect =>
      'Verzonden. Wachten op bevestiging van het contact.';

  @override
  String messageStatus_heardRepeatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keer',
      one: 'Eén keer',
    );
    return '$_temp0 herhaald gehoord. Repeaters in de buurt hebben het doorgestuurd.';
  }

  @override
  String get urlImage_enable => 'URL-afbeeldingen inschakelen';

  @override
  String get urlImage_possible =>
      'Mogelijke URL-afbeelding; schakel dit in bij Instellingen.';

  @override
  String get common_reboot => 'Herstarten';

  @override
  String get common_loading => 'Laden...';

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
  String get common_autoRefresh => 'Automatisch vernieuwen';

  @override
  String get common_interval => 'Tijdsinterval';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Verbind via TCP';

  @override
  String get tcpHostLabel => 'Eindpunt';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => 'Poort';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Voer het eindpunt in en verbind';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Verbinding maken met $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Host is vereist.';

  @override
  String get tcpErrorPortInvalid =>
      'De poortwaarde moet tussen 1 en 65535 liggen.';

  @override
  String get tcpErrorUnsupported =>
      'TCP-transport wordt niet ondersteund op dit platform.';

  @override
  String get tcpErrorTimedOut => 'Time-out bij TCP-verbinding.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Verbinding met TCP mislukt: $error';
  }

  @override
  String get usbScreenTitle => 'Verbind via USB';

  @override
  String get usbScreenSubtitle =>
      'Selecteer een gedetecteerd serieel apparaat en maak direct verbinding met je MeshCore-node.';

  @override
  String get usbScreenStatus => 'Selecteer een USB-apparaat';

  @override
  String get usbScreenNote =>
      'USB-serieel is actief op ondersteunde Android-apparaten en desktop-platforms.';

  @override
  String get usbScreenEmptyState =>
      'Geen USB-apparaten gevonden. Sluit er een aan en herlaad.';

  @override
  String get usbErrorPermissionDenied => 'Toegang via USB is geweigerd.';

  @override
  String get usbErrorDeviceMissing =>
      'Het geselecteerde USB-apparaat is niet meer beschikbaar.';

  @override
  String get usbErrorInvalidPort => 'Selecteer een geldig USB-apparaat.';

  @override
  String get usbErrorBusy => 'Er loopt al een ander USB-verbindingsverzoek.';

  @override
  String get usbErrorNotConnected => 'Er is geen USB-apparaat aangesloten.';

  @override
  String get usbErrorOpenFailed =>
      'Kon het geselecteerde USB-apparaat niet openen.';

  @override
  String get usbErrorConnectFailed =>
      'Kon geen verbinding maken met het geselecteerde USB-apparaat.';

  @override
  String get usbErrorUnsupported =>
      'USB-serieel wordt niet ondersteund op dit platform.';

  @override
  String get usbErrorAlreadyActive => 'Een USB-verbinding is al actief.';

  @override
  String get usbErrorNoDeviceSelected => 'Geen USB-apparaat is geselecteerd.';

  @override
  String get usbErrorPortClosed => 'De USB-verbinding is niet actief.';

  @override
  String get usbErrorConnectTimedOut =>
      'Time-out bij verbinden. Zorg dat het apparaat USB Companion-firmware heeft.';

  @override
  String get usbFallbackDeviceName => 'Web Serial-apparaat';

  @override
  String get usbStatus_notConnected => 'Selecteer een USB-apparaat';

  @override
  String get usbStatus_connecting => 'Verbinding maken met USB-apparaat...';

  @override
  String get usbStatus_searching => 'Zoeken naar USB-apparaten...';

  @override
  String usbConnectionFailed(String error) {
    return 'Fout bij de USB-verbinding: $error';
  }

  @override
  String get scanner_scanning => 'Scannen naar apparaten...';

  @override
  String get scanner_connecting => 'Verbinden...';

  @override
  String get scanner_disconnecting => 'Verbinding verbreken...';

  @override
  String get scanner_notConnected => 'Niet verbonden';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Verbonden met $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Zoeken naar MeshCore apparaten...';

  @override
  String get scanner_tapToScan => 'Tik Scan om MeshCore apparaten te vinden';

  @override
  String scanner_connectionFailed(String error) {
    return 'Verbinding mislukt: $error';
  }

  @override
  String get scanner_stop => 'Stoppen';

  @override
  String get scanner_scan => 'Scannen';

  @override
  String get scanner_bluetoothOff => 'Bluetooth is uitgeschakeld';

  @override
  String get scanner_bluetoothOffMessage =>
      'Zorg ervoor dat Bluetooth is ingeschakeld om naar apparaten te zoeken.';

  @override
  String get scanner_chromeRequired => 'Chrome-browser vereist';

  @override
  String get scanner_chromeRequiredMessage =>
      'Deze webapplicatie vereist Google Chrome of een op Chromium gebaseerde browser voor Bluetooth-ondersteuning.';

  @override
  String get scanner_enableBluetooth => 'Activeer Bluetooth';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'Bluetooth is niet beschikbaar in de browser. Verbind in plaats daarvan via USB.';

  @override
  String get device_quickSwitch => 'Snel wisselen';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Instellingen';

  @override
  String get settings_deviceInfo => 'Apparaatinformatie';

  @override
  String get settings_appSettings => 'App Instellingen';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificaties, berichten en kaartinstellingen';

  @override
  String get settings_nodeSettings => 'Node Instellingen';

  @override
  String get settings_nodeName => 'Nodenaam';

  @override
  String get settings_nodeNameNotSet => 'Niet ingesteld';

  @override
  String get settings_nodeNameHint => 'Voer nodenaam in';

  @override
  String get settings_nodeNameUpdated => 'Naam bijgewerkt';

  @override
  String get settings_radioSettings => 'Radio Instellingen';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequentie, vermogen, spreadingfactor';

  @override
  String get settings_radioSettingsUpdated => 'Radio instellingen bijgewerkt';

  @override
  String get settings_radioSettingsNotApplied =>
      'De radio heeft deze instellingen niet toegepast';

  @override
  String get settings_regionSettings => 'Regio\'s';

  @override
  String get settings_regionSettingsSubtitle =>
      'Beperk kanaal-floods tot een gebied';

  @override
  String get settings_regionEmptyExplanation =>
      'Regio\'s beperken flood-berichten tot repeaters in een gebied. Haal ze op bij repeaters in de buurt of voeg er een toe op naam.';

  @override
  String get settings_regionFetchFromRepeaters => 'Ophalen bij repeaters';

  @override
  String get settings_regionDefault => 'Standaardregio';

  @override
  String get settings_regionDefaultSubtitle =>
      'Gebruikt door kanalen zonder eigen regio';

  @override
  String get settings_regionDefaultNone => 'Geen';

  @override
  String get settings_regionManagement_screenTitle => 'Regiobeheer';

  @override
  String get settings_regionNameHint => 'Voer regionaam in';

  @override
  String get settings_regionAddRegion => 'Regio toevoegen';

  @override
  String get settings_regionFetchRegions => 'Regio\'s ophalen bij repeaters';

  @override
  String get settings_regionFetchRegionsFail =>
      'Er zijn geen regio\'s gevonden';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Deze regio is al toegevoegd.';

  @override
  String get settings_regionName => 'Regionaam';

  @override
  String get settings_regionDeleted => 'Regio verwijderd';

  @override
  String get settings_deleteRegion => 'Regio verwijderen';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Verwijder \"$region\" uit de regio-lijst?';
  }

  @override
  String get settings_location => 'Locatie';

  @override
  String get settings_locationSubtitle => 'GPS coördinaten';

  @override
  String get settings_locationUpdated =>
      'Locatie- en GPS-instellingen bijgewerkt';

  @override
  String get settings_locationBothRequired =>
      'Voer zowel breedte- als lengtegraad in.';

  @override
  String get settings_locationInvalid =>
      'Ongeldige breedtegraad of lengtegraad.';

  @override
  String get settings_locationGPSEnable => 'GPS inschakelen';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Activeer automatisch locatieupdates via GPS.';

  @override
  String get settings_locationIntervalSec => 'Interval voor GPS (Seconden)';

  @override
  String get settings_locationIntervalInvalid =>
      'Het interval moet minstens 60 seconden en minder dan 86400 seconden zijn.';

  @override
  String get settings_latitude => 'Breedtegraad';

  @override
  String get settings_longitude => 'Lengtegraad';

  @override
  String get settings_contactSettings => 'Contactinstellingen';

  @override
  String get settings_contactSettingsSubtitle =>
      'Instellingen voor het toevoegen van contacten';

  @override
  String get settings_privacyMode => 'Privacy-modus';

  @override
  String get settings_privacyModeSubtitle =>
      'Naam/locatie verbergen in adverts';

  @override
  String get settings_privacyModeToggle =>
      'Schakel privacy modus in om je naam en locatie in adverts te verbergen.';

  @override
  String get settings_privacyModeEnabled => 'Privacy modus is ingeschakeld';

  @override
  String get settings_privacyModeDisabled => 'Privacy modus is uitgeschakeld';

  @override
  String get settings_privacy => 'Privacyinstellingen';

  @override
  String get settings_privacySubtitle =>
      'Beheer welke informatie wordt gedeeld';

  @override
  String get settings_privacySettingsDescription =>
      'Kies welke informatie je apparaat met anderen deelt.';

  @override
  String get settings_denyAll => 'Weiger alles';

  @override
  String get settings_allowByContact => 'Alleen contacten die ik toesta';

  @override
  String get settings_allowAll => 'Alles toestaan';

  @override
  String get settings_telemetryBaseMode =>
      'Wie mag batterij en status opvragen';

  @override
  String get settings_telemetryLocationMode => 'Wie mag mijn locatie opvragen';

  @override
  String get settings_telemetryEnvironmentMode => 'Wie mag sensordata opvragen';

  @override
  String get settings_telemetryPerContactHint =>
      'Om een contact toe te staan, open je de chat en kies je Contactinstellingen in het menu.';

  @override
  String get settings_advertLocation => 'Advert-locatie';

  @override
  String get settings_advertLocationSubtitle => 'Locatie opnemen in advert';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Automatische zero-hop-advert bij GPS-update';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Wanneer de GPS-locatie verandert, een zero-hop-advert verzenden (vereist locatie in advert).';

  @override
  String get settings_multiAck => 'Multi-ACKs';

  @override
  String get settings_multiAckSubtitle =>
      'Stuur extra ACKs voor betere aflevering; gebruikt meer zendtijd';

  @override
  String get settings_telemetryModeUpdated => 'Telemetrie-modus bijgewerkt';

  @override
  String get settings_actions => 'Acties';

  @override
  String get settings_deleteAllPaths => 'Alle paden verwijderen';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Wis alle padgegevens van contacten.';

  @override
  String get settings_sendAdvertisement => 'Advert verzenden';

  @override
  String get settings_sendAdvertisementSubtitle => 'Nu aanwezigheid uitzenden';

  @override
  String get settings_advertisementSent => 'Advert verzonden';

  @override
  String get settings_syncTime => 'Tijd Synchroniseren';

  @override
  String get settings_syncTimeSubtitle =>
      'Stel de apparaatklok in op de tijd van de telefoon.';

  @override
  String get settings_timeSynchronized => 'Tijd gesynchroniseerd';

  @override
  String get settings_refreshContacts => 'Contacten vernieuwen';

  @override
  String get settings_refreshContactsSubtitle =>
      'Contactlijst opnieuw laden van het apparaat';

  @override
  String get settings_rebootDevice => 'Apparaat opnieuw opstarten';

  @override
  String get settings_rebootDeviceSubtitle => 'Herstart het MeshCore-apparaat';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ben je er zeker van dat je het apparaat opnieuw wilt opstarten? Je wordt losgekoppeld.';

  @override
  String get settings_debug => 'Foutopsporing';

  @override
  String get settings_companionDebugLog => 'Companion-debuglog';

  @override
  String get settings_companionDebugLogSubtitle =>
      'BLE/TCP/USB commando\'s, antwoorden en ruwe data';

  @override
  String get settings_appDebugLog => 'Debuglog van de app';

  @override
  String get settings_appDebugLogSubtitle => 'Toepassingsdebugberichten';

  @override
  String get settings_about => 'Over';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open versie $version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore Open Source Project';

  @override
  String get settings_aboutDescription =>
      'Een open-source Flutter client voor MeshCore LoRa mesh netwerkapparaten.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS-hoogtegegevens: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Naam';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Batterij';

  @override
  String get settings_infoPublicKey => 'Openbare Sleutel';

  @override
  String get settings_publicKeyCopied => 'Openbare sleutel gekopieerd';

  @override
  String get settings_infoContactsCount => 'Aantal Contacten';

  @override
  String get settings_infoChannelCount => 'Aantal Kanalen';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

  @override
  String get settings_presets => 'Voorinstellingen';

  @override
  String get settings_presetCustom => 'Aangepast';

  @override
  String get settings_radioMatchWarning =>
      'Alle nodes waarmee je communiceert moeten dezelfde frequentie, bandbreedte, SF en CR gebruiken.';

  @override
  String get settings_frequency => 'Frequentie (MHz)';

  @override
  String get settings_frequencyHelper => '150.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Ongeldige frequentie (150-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bandbreedte';

  @override
  String get settings_spreadingFactor => 'Spreadingfactor';

  @override
  String get settings_codingRate => 'Coding rate';

  @override
  String get settings_txPower => 'TX-Vermogen (dBm)';

  @override
  String settings_txPowerRangeHelper(int min, int max) {
    return '$min tot $max dBm';
  }

  @override
  String get settings_txPowerInvalid => 'Ongeldig TX-vermogen';

  @override
  String get settings_clientRepeat => 'Off-Grid Herhalen';

  @override
  String settings_clientRepeatFrequencyNote(String freq) {
    return 'Frequentie ingesteld op $freq MHz voor off-grid herhalen';
  }

  @override
  String get settings_clientRepeatSubtitle =>
      'Laat dit apparaat meshpakketten doorsturen voor anderen';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Off-grid herhalen vereist een frequentie van 433, 869,495 of 918 MHz';

  @override
  String settings_error(String message) {
    return 'Fout: $message';
  }

  @override
  String get appSettings_title => 'App Instellingen';

  @override
  String get appSettings_appearance => 'Uiterlijk';

  @override
  String get appSettings_theme => 'Thema';

  @override
  String get appSettings_themeSystem => 'Systeemstandaard';

  @override
  String get appSettings_themeLight => 'Licht';

  @override
  String get appSettings_themeDark => 'Donker';

  @override
  String get appSettings_language => 'Taal';

  @override
  String get appSettings_languageSystem => 'Systeemstandaard';

  @override
  String get appSettings_languageEn => 'Engels';

  @override
  String get appSettings_languageFr => 'Frans';

  @override
  String get appSettings_languageEs => 'Spaans';

  @override
  String get appSettings_languageDe => 'Duits';

  @override
  String get appSettings_languagePl => 'Pools';

  @override
  String get appSettings_languageSl => 'Sloveens';

  @override
  String get appSettings_languagePt => 'Portugees';

  @override
  String get appSettings_languageIt => 'Italiaans';

  @override
  String get appSettings_languageZh => 'Chinees';

  @override
  String get appSettings_languageSv => 'Zweeds';

  @override
  String get appSettings_languageNl => 'Nederlands';

  @override
  String get appSettings_languageSk => 'Slowaaks';

  @override
  String get appSettings_languageBg => 'Bulgaars';

  @override
  String get appSettings_languageRu => 'Russisch';

  @override
  String get appSettings_languageUk => 'Oekraïens';

  @override
  String get repeater_pathHashModeOption0 => '1 byte';

  @override
  String get repeater_pathHashModeOption1 => '2 bytes';

  @override
  String get repeater_pathHashModeOption2 => '3 bytes';

  @override
  String get repeater_pathHashModeOption3 => '4 bytes';

  @override
  String get settings_pathHashModeHelper =>
      'Grootte van elke node-ID die wordt vastgelegd in het pad van flood-pakketten die deze radio verzendt: 1 byte (256 ID\'s, tot 64 hops), 2 bytes (65K ID\'s, tot 32 hops), 3 bytes (16M ID\'s, tot 21 hops). Grotere ID\'s verminderen botsingen, maar repeaters met firmware ouder dan v1.14 laten pakketten met 2- of 3-byte-ID\'s vallen.';

  @override
  String settings_requiresFirmware(String version) {
    return 'Vereist firmware $version of nieuwer';
  }

  @override
  String get appSettings_channelMinHops =>
      'Kanaalberichten opnieuw verzenden tot ze ver genoeg komen';

  @override
  String get appSettings_channelMinHopsSubtitle =>
      'Als je bericht niet via genoeg repeaters terug wordt gehoord, verstuur het dan opnieuw. Gebruikt meer zendtijd.';

  @override
  String appSettings_channelMinHopsCount(int count) {
    return 'Vereiste hops: $count';
  }

  @override
  String appSettings_channelMinHopsRetries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keer',
      one: '1 keer',
    );
    return 'Maximaal $_temp0 opnieuw verzenden';
  }

  @override
  String get appSettings_enableMessageTracing =>
      'Volledig repeaterpad in berichten tonen';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Toont ook herhalingsaantallen en reistijden. Houd een bericht ingedrukt en kies Pad voor alle details.';

  @override
  String get appSettings_notifications => 'Notificaties';

  @override
  String get appSettings_enableNotifications => 'Notificaties inschakelen';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Ontvang meldingen voor berichten en adverts';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Toestemming voor notificaties geweigerd';

  @override
  String get appSettings_notificationsEnabled =>
      'Notificaties zijn ingeschakeld';

  @override
  String get appSettings_notificationsDisabled =>
      'Notificaties zijn uitgeschakeld';

  @override
  String get appSettings_messageNotifications => 'Berichtnotificaties';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Toon notificatie bij het ontvangen van nieuwe berichten';

  @override
  String get appSettings_batteryOptimization => 'Achtergrondactiviteit';

  @override
  String get appSettings_batteryOptimizationSubtitle =>
      'Zet MeshCore Open op \"Niet optimaliseren\" in de batterij-instellingen zodat berichten op de achtergrond blijven binnenkomen';

  @override
  String get appSettings_channelMessageNotifications =>
      'Kanaalberichtnotificaties';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Toon notificatie bij het ontvangen van kanaalberichten';

  @override
  String get appSettings_advertisementNotifications => 'Advert-notificaties';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Toon notificatie wanneer nieuwe nodes worden ontdekt';

  @override
  String get appSettings_messaging => 'Berichten';

  @override
  String get appSettings_clearPathOnMaxRetry => 'Pad wissen na max. pogingen';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Reset contactpad na 5 mislukte verzendpogingen';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Paden worden gewist na 5 mislukte pogingen';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Paden worden niet automatisch gewist';

  @override
  String get appSettings_autoRouteRotation => 'Route Automatisch Roteren';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Wissel tussen beste paden en floodmodus';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Automatische route rotatie ingeschakeld';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Automatische route rotatie is uitgeschakeld';

  @override
  String get appSettings_maxRouteWeight => 'Maximaal routegewicht';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Het maximale gewicht dat een route kan bereiken door succesvolle leveringen.';

  @override
  String get appSettings_initialRouteWeight => 'Initieel routegewicht';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Startgewicht voor nieuwe, ontdekte routes';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Gewichtstoename bij succes';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Gewicht wordt toegevoegd aan een route na een succesvolle levering.';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Gewichtsafname bij mislukking';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Gewicht verwijderd van een pad na een mislukte levering';

  @override
  String get appSettings_maxMessageRetries => 'Max. aantal nieuwe pogingen';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Aantal pogingen om een bericht opnieuw te versturen voordat het als mislukt wordt gemarkeerd';

  @override
  String get appSettings_battery => 'Batterij';

  @override
  String get appSettings_batteryChemistry => 'Batterijchemie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Instellen per apparaat ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Verbind met een apparaat om te selecteren';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_batteryLipoHv => 'LiPo HV (3,0-4,35 V)';

  @override
  String get appSettings_mapDisplay => 'Kaartweergave';

  @override
  String get appSettings_showRepeaters => 'Toon Repeaters';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Toon repeaternodes op de kaart';

  @override
  String get appSettings_showChatNodes => 'Chat Nodes tonen';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Chatnodes weergeven op de kaart';

  @override
  String get appSettings_showOtherNodes => 'Toon Andere Nodes';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Toon andere nodetypes op de kaart';

  @override
  String get appSettings_timeFilter => 'Filter op tijd';

  @override
  String get appSettings_timeFilterShowAll => 'Alle nodes tonen';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Toon nodes van de laatste $hours uur';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filter tijd op kaart';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Toon nodes ontdekt binnen:';

  @override
  String get appSettings_allTime => 'Altijd';

  @override
  String get appSettings_lastHour => 'Afgelopen uur';

  @override
  String get appSettings_last6Hours => 'Afgelopen 6 uur';

  @override
  String get appSettings_last24Hours => 'Afgelopen 24 uur';

  @override
  String get appSettings_lastWeek => 'Afgelopen week';

  @override
  String get appSettings_rasterTileSource => 'Rastertegelbron';

  @override
  String get appSettings_stadiaEndpoint => 'Stadia-eindpunt';

  @override
  String get appSettings_stadiaApiKey => 'Stadia API-sleutel';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Vereist voor gebruik van Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Geconfigureerd: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Voer je Stadia Maps API-sleutel in. De app gebruikt die voor rastertegelverzoeken.';

  @override
  String get appSettings_offlineMapCache => 'Offline Kaartcache';

  @override
  String get appSettings_unitsTitle => 'Eenheden';

  @override
  String get appSettings_unitsMetric => 'Metrisch (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiaal (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Geen gebied geselecteerd';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Geselecteerd gebied (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Foutopsporing';

  @override
  String get appSettings_appDebugLogging => 'App-debuglogging';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Log app debugberichten voor probleemoplossing';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'App debug logging is ingeschakeld';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'App debug logging is uitgeschakeld';

  @override
  String get contacts_title => 'Contacten';

  @override
  String get contacts_noContacts => 'Nog geen contacten.';

  @override
  String get contacts_contactsWillAppear =>
      'Contacten verschijnen wanneer apparaten een advert uitzenden';

  @override
  String get contacts_unread => 'Ongelezen';

  @override
  String get contacts_searchContactsNoNumber => 'Zoek contacten...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Zoek $number$str contacten...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Zoek $number$str favorieten...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Zoek $number$str gebruikers...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Zoek $number$str Repeaters...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Zoek $number$str Room servers...';
  }

  @override
  String get contacts_noUnreadContacts => 'Geen ongelezen contacten';

  @override
  String get contacts_noContactsFound => 'Geen contacten of groepen gevonden.';

  @override
  String get contacts_storageFull =>
      'De contactopslag op de node is vol. Nieuwe nodes kunnen pas worden toegevoegd als er contacten zijn verwijderd.';

  @override
  String get contacts_deleteContact => 'Verwijder Contact';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Verwijder $contactName uit de contacten?';
  }

  @override
  String get contacts_removeFromContacts => 'Verwijderen uit contacten';

  @override
  String contacts_removeFromContactsConfirm(String contactName) {
    return '$contactName wordt verplaatst naar Ontdekte contacten. De chatgeschiedenis wordt verwijderd.';
  }

  @override
  String get contacts_keepChatHistory => 'Chatgeschiedenis behouden';

  @override
  String get contacts_remove => 'Verwijderen';

  @override
  String contacts_discoveredNearby(int count) {
    return 'In de buurt ontdekt ($count)';
  }

  @override
  String get contacts_noContactsDiscoveredHint =>
      'Nodes die je radio hoort maar nog niet heeft toegevoegd, staan bij Ontdekte contacten';

  @override
  String get contacts_manageRepeater => 'Beheer Repeater';

  @override
  String get contacts_manageRoom => 'Roomserver beheren';

  @override
  String get contacts_roomLogin => 'Inloggen op roomserver';

  @override
  String get contacts_openChat => 'Open gesprek';

  @override
  String get contacts_editGroup => 'Groep bewerken';

  @override
  String get contacts_deleteGroup => 'Groep verwijderen';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '\"$groupName\" verwijderen?';
  }

  @override
  String get contacts_newGroup => 'Nieuwe Groep';

  @override
  String get contacts_moreOptions => 'Meer opties';

  @override
  String get contacts_searchOpen => 'Zoek contactpersonen';

  @override
  String get contacts_searchClose => 'Zoeken sluiten';

  @override
  String get contacts_groupName => 'Groepnaam';

  @override
  String get contacts_groupNameRequired => 'De groepnaam is verplicht.';

  @override
  String get contacts_groupNameReserved => 'Deze groepsnaam is gereserveerd';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'De groep \"$name\" bestaat al.';
  }

  @override
  String get contacts_filterContacts => 'Contacten filteren...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Geen contacten komen overeen met je filter';

  @override
  String get contacts_noMembers => 'Geen leden';

  @override
  String get contacts_lastSeenNow => 'recent';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 uur';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours uur';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 dag';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days dagen';
  }

  @override
  String get contact_info => 'Contactinformatie';

  @override
  String get contact_settings => 'Contactinstellingen';

  @override
  String get contact_telemetry => 'Telemetrie';

  @override
  String get contact_lastSeen => 'Laatst gezien';

  @override
  String get contact_clearChat => 'Chat leegmaken';

  @override
  String get contact_teleBase => 'Basistelemetrie';

  @override
  String get contact_teleBaseSubtitle =>
      'Delen van batterijniveau en basistelemetrie toestaan';

  @override
  String get contact_teleLoc => 'Telemetrielocatie';

  @override
  String get contact_teleLocSubtitle => 'Locatiegegevens delen toestaan';

  @override
  String get contact_teleEnv => 'Telemetrieomgeving';

  @override
  String get contact_teleEnvSubtitle => 'Delen van omgevingsensordata toestaan';

  @override
  String get channels_title => 'Kanalen';

  @override
  String get channels_noChannelsConfigured => 'Geen kanalen geconfigureerd';

  @override
  String get channels_addPublicChannel => 'Openbaar kanaal toevoegen';

  @override
  String get channels_searchChannels => 'Zoek kanalen...';

  @override
  String get channels_noChannelsFound => 'Geen kanalen gevonden';

  @override
  String channels_channelIndex(int index) {
    return 'Kanaal $index';
  }

  @override
  String get channels_public => 'Openbaar';

  @override
  String channels_via(String path) {
    return 'via $path';
  }

  @override
  String get channels_private => 'Privé';

  @override
  String get channels_hashtag => 'Hashtag';

  @override
  String get channels_addSectionJoin => 'Deelnemen aan bestaand';

  @override
  String get channels_addSectionCreate => 'Nieuw aanmaken';

  @override
  String get channels_dragToReorder => 'Sleep om te herschikken';

  @override
  String get channels_editChannel => 'Kanaal bewerken';

  @override
  String get channels_muteChannel => 'Kanaal dempen';

  @override
  String get channels_unmuteChannel => 'Kanaal dempen opheffen';

  @override
  String get channels_deleteChannel => 'Kanaal verwijderen';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Verwijderen \"$name\"? Dit kan niet worden teruggedraaid.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kan kanaal \"$name\" niet verwijderen';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanaal \"$name\" verwijderd';
  }

  @override
  String get channels_addChannel => 'Kanaal toevoegen';

  @override
  String get channels_channelIndexLabel => 'Kanaalindex';

  @override
  String get channels_channelName => 'Kanaalnaam';

  @override
  String get channels_usePublicChannel => 'Openbaar kanaal gebruiken';

  @override
  String get channels_standardPublicPsk => 'Standaard openbare PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Willekeurige PSK genereren';

  @override
  String get channels_enterChannelName => 'Voer een kanaalnaam in';

  @override
  String get channels_pskMustBe32Hex =>
      'De PSK moet 32 hexadecimale tekens zijn.';

  @override
  String channels_channelAdded(String name) {
    return 'Kanaal \"$name\" toegevoegd';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Bewerk Kanaal $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ compressie';

  @override
  String get channels_cyr2latCompression => 'Cyr2Lat compressie';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Vervangt sommige Cyrillische tekens door Latijnse tekens bij het verzenden.';

  @override
  String get channels_cyr2latSettingsHeading => 'Instellingen Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Lijst met vervangingen';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Bewerk de JSON-configuratie voor tekenvervanging';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON-vervangingskaart';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'Onjuiste JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Kanaal \"$name\" is bijgewerkt';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Cyr2Lat-profiel toevoegen';

  @override
  String get settings_cyr2latProfileName => 'Profielnaam';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'Profielnaam mag niet leeg zijn';

  @override
  String get settings_cyr2latProfileAdded => 'Profiel succesvol toegevoegd';

  @override
  String get settings_cyr2latProfileUpdated => 'Profiel succesvol bijgewerkt';

  @override
  String get settings_cyr2latProfileEdit => 'Cyr2Lat-profiel bewerken';

  @override
  String get settings_cyr2latProfileDelete => 'Cyr2Lat-profiel verwijderen';

  @override
  String get settings_cyr2latProfileDeleted => 'Profiel succesvol verwijderd';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Weet je zeker dat je het profiel \"$name\" wilt verwijderen?';
  }

  @override
  String get channels_publicChannelAdded => 'Openbaar kanaal toegevoegd';

  @override
  String get channels_noFreeSlots => 'Alle kanaalslots zijn bezet';

  @override
  String get channels_sortBy => 'Sorteren op';

  @override
  String get channels_sortManual => 'Handmatig';

  @override
  String get channels_sortAZ => 'Alfabetisch';

  @override
  String get channels_sortLatestMessages => 'Recente berichten';

  @override
  String get channels_sortUnread => 'Ongelezen';

  @override
  String get channels_createPrivateChannel => 'Privékanaal aanmaken';

  @override
  String get channels_createPrivateChannelDesc =>
      'Beveiligd met een geheime sleutel.';

  @override
  String get channels_joinPrivateChannel => 'Deelnemen aan privékanaal';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Voer handmatig een geheime sleutel in.';

  @override
  String get channels_joinPublicChannel => 'Deelnemen aan openbaar kanaal';

  @override
  String get channels_joinPublicChannelDesc =>
      'Iedereen kan toetreden tot dit kanaal.';

  @override
  String get channels_joinHashtagChannel => 'Deelnemen aan hashtagkanaal';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Iedereen kan toetreden tot hashtag-kanalen.';

  @override
  String get channels_scanQrCode => 'Scan een QR-code';

  @override
  String get channels_scanQrCodeComingSoon => 'Binnenkort beschikbaar';

  @override
  String get channels_enterHashtag => 'Voer hashtag in';

  @override
  String get channels_hashtagHint => 'bijv. #team';

  @override
  String channels_regionSetTo(String region) {
    return 'Regio: $region';
  }

  @override
  String get channels_regionNotSet => 'Regio: geen';

  @override
  String get channels_regionSelect_Title => 'Kies een regio';

  @override
  String get channels_clearRegion => 'Regio wissen';

  @override
  String get channels_regionDefaultSuffix => '(standaard)';

  @override
  String get channels_regionSelectExplanation =>
      'Flood-berichten op dit kanaal worden alleen doorgestuurd door repeaters in de geselecteerde regio.';

  @override
  String get channels_regionEmpty => 'Nog geen regio\'s.';

  @override
  String get channels_manageRegions => 'Regio\'s beheren';

  @override
  String get chat_noMessages => 'Nog geen berichten.';

  @override
  String get chat_sendMessage => 'Verzend bericht';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Verstuur een bericht naar $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Stuur een bericht om te beginnen';

  @override
  String get chat_originalMessageNotFound => 'Originele bericht niet gevonden';

  @override
  String chat_replyingTo(String name) {
    return 'Reageren op $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Reageer op $name';
  }

  @override
  String get chat_location => 'Locatie';

  @override
  String get chat_typeMessage => 'Typ een bericht...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Bericht is te lang (max $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Bericht gekopieerd';

  @override
  String get chat_messageDeleted => 'Bericht verwijderd';

  @override
  String get chat_retryingMessage => 'Bericht opnieuw verzenden';

  @override
  String chat_retryCount(int current, int max) {
    return 'Poging $current/$max';
  }

  @override
  String get chat_selectSendAction => 'Verzendactie selecteren';

  @override
  String get chat_sendGif => 'GIF verzenden';

  @override
  String get chat_removeGif => 'GIF verwijderen';

  @override
  String get chat_cancelReply => 'Antwoord annuleren';

  @override
  String get chat_sendImageLora =>
      'Afbeelding in lage resolutie via radio verzenden';

  @override
  String get chat_imagePickFailed => 'Kon die afbeelding niet openen';

  @override
  String get chat_receivedGif => 'GIF ontvangen';

  @override
  String get chat_reply => 'Reageren';

  @override
  String get chat_addReaction => 'Reactie toevoegen';

  @override
  String get chat_me => 'Ik';

  @override
  String get reaction_report => 'Emoji-reacties';

  @override
  String get emojiCategorySmileys => 'Smileys';

  @override
  String get emojiCategoryGestures => 'Gebaren';

  @override
  String get emojiCategoryHearts => 'Hartjes';

  @override
  String get emojiCategoryObjects => 'Objecten';

  @override
  String get gifPicker_title => 'Kies een GIF';

  @override
  String get gifPicker_searchHint => 'Zoek GIFs...';

  @override
  String get gifPicker_poweredBy => 'Mogelijk gemaakt door GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Geen GIFs gevonden';

  @override
  String get gifPicker_failedLoad => 'GIF\'s konden niet worden geladen';

  @override
  String get gifPicker_failedSearch => 'Zoeken naar GIF\'s mislukt';

  @override
  String get gifPicker_noInternet => 'Geen internetverbinding';

  @override
  String get debugLog_appTitle => 'Debuglog van de app';

  @override
  String get debugLog_bleTitle => 'BLE Debug Log';

  @override
  String get debugLog_copyLog => 'Kopieer log';

  @override
  String get debugLog_clearLog => 'Log wissen';

  @override
  String get debugLog_copied => 'Debuglog gekopieerd';

  @override
  String get debugLog_bleCopied => 'BLE log gekopieerd';

  @override
  String get debugLog_noEntries => 'Nog geen debug logs beschikbaar.';

  @override
  String get debugLog_enableInSettings =>
      'Schakel app-debuglogging in via de instellingen';

  @override
  String get debugLog_frames => 'Frames';

  @override
  String get debugLog_rawLogRx => 'Ruwe log-RX';

  @override
  String get debugLog_noBleActivity => 'Geen BLE-activiteit nog.';

  @override
  String debugFrame_length(int count) {
    return 'Frame Lengte: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Commando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Tekstbericht-frame:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Bestemming PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Tijdstempel: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Vlaggen: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Teksttype: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Platte tekst';

  @override
  String debugFrame_text(String text) {
    return '- Tekst: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex-dump:';

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
  String get chat_removePath => 'Pad verwijderen';

  @override
  String get chat_noPathHistoryYet =>
      'Nog geen padgeschiedenis.\nStuur een bericht om paden te ontdekken.';

  @override
  String get chat_pathCleared =>
      'Pad gewist. Het volgende bericht zoekt de route opnieuw.';

  @override
  String get chat_fullPath => 'Volledig pad';

  @override
  String get routing_title => 'Routering';

  @override
  String get routing_modeAuto => 'Auto';

  @override
  String get routing_modeFlood => 'Flood';

  @override
  String get routing_modeManual => 'Handmatig';

  @override
  String get routing_modeAutoHint =>
      'Kiest automatisch het beste bekende pad en gebruikt flood als er geen bekend is.';

  @override
  String get routing_modeFloodHint =>
      'Zendt uit via elke repeater. Meest betrouwbaar, maar gebruikt meer zendtijd.';

  @override
  String get routing_modeManualHint =>
      'Verstuurt altijd via het exacte pad dat je hebt ingesteld.';

  @override
  String get routing_currentRoute => 'Huidige route';

  @override
  String get routing_directNoHops => 'Direct — geen repeater-hops';

  @override
  String get routing_noPathYet =>
      'Nog geen pad. Het volgende bericht gebruikt flood totdat een route is gevonden.';

  @override
  String get routing_floodBroadcast => 'Uitzenden via elke repeater';

  @override
  String get routing_editPath => 'Pad bewerken';

  @override
  String get routing_forgetPath => 'Vergeet het pad';

  @override
  String get routing_knownPaths => 'Bekende paden';

  @override
  String get routing_knownPathsHint =>
      'Tik op een pad om ernaar over te schakelen.';

  @override
  String get routing_inUse => 'In gebruik';

  @override
  String get routing_qualityStrong => 'Sterke eerste hop';

  @override
  String get routing_qualityGood => 'Goede eerste hop';

  @override
  String get routing_qualityFair => 'Redelijke eerste hop';

  @override
  String get routing_qualityWorked => 'Heeft afgeleverd';

  @override
  String get routing_qualityFlood => 'Gehoord via flood';

  @override
  String get routing_qualityUntested => 'Niet getest';

  @override
  String routing_lastWorked(String when) {
    return 'werkte $when';
  }

  @override
  String get routing_neverWorked => 'nooit bevestigd';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes afgeleverd, $failures mislukt';
  }

  @override
  String get routing_floodDelivery => 'Flood-levering';

  @override
  String get pathEditor_title => 'Pad samenstellen';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count van 64 hops';
  }

  @override
  String get pathEditor_noHops =>
      'Nog geen hops. Tik hieronder op repeaters om ze op volgorde toe te voegen, of sla op zonder hops om direct te verzenden.';

  @override
  String get pathEditor_addHops => 'Hops op volgorde toevoegen';

  @override
  String get pathEditor_searchRepeaters => 'Repeaters zoeken';

  @override
  String get pathEditor_advancedHex => 'Geavanceerd: ruwe hex-pad';

  @override
  String get pathEditor_hexLabel => 'Hex-prefixen';

  @override
  String get pathEditor_hexHelper =>
      'Twee hex-tekens per hop, gescheiden door komma\'s';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Ongeldig: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Maximaal 64 hops';

  @override
  String get pathEditor_usePath => 'Dit pad gebruiken';

  @override
  String get pathEditor_removeHop => 'Hop verwijderen';

  @override
  String get pathEditor_unknownHop => 'Onbekende repeater';

  @override
  String get chat_pathSavedLocally =>
      'Lokaal opgeslagen. Verbind om te synchroniseren.';

  @override
  String get chat_pathDeviceConfirmed => 'Apparaat bevestigd.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Apparaat nog niet bevestigd.';

  @override
  String get chat_type => 'Type';

  @override
  String get chat_path => 'Pad';

  @override
  String get chat_viewPathOnMap => 'Pad op kaart bekijken';

  @override
  String get chat_publicKey => 'Openbare Sleutel';

  @override
  String get chat_compressOutgoingMessages => 'Uitgaande berichten comprimeren';

  @override
  String get chat_floodForced => 'Flood (afgedwongen)';

  @override
  String get chat_directForced => 'Direct (afgedwongen)';

  @override
  String chat_hopsForced(int count) {
    return '$count hops (afgedwongen)';
  }

  @override
  String get chat_floodAuto => 'Flood (automatisch)';

  @override
  String get chat_direct => 'Direct';

  @override
  String get chat_poiShared => 'Gedeelde POI';

  @override
  String chat_unread(int count) {
    return 'Ongelezen: $count';
  }

  @override
  String get chat_markAsUnread => 'Markeer als ongelezen';

  @override
  String get chat_newMessages => 'Nieuwe berichten';

  @override
  String get chat_today => 'Vandaag';

  @override
  String get chat_yesterday => 'Gisteren';

  @override
  String get chat_openLink => 'Link openen?';

  @override
  String get chat_openLinkConfirmation =>
      'Wil je deze link in je browser openen?';

  @override
  String get chat_open => 'Openen';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Kan link niet openen: $url';
  }

  @override
  String get chat_invalidLink => 'Ongeldig linkformaat';

  @override
  String get map_title => 'Nodekaart';

  @override
  String get map_searchHint => 'Zoek op nodenaam of ID';

  @override
  String get map_activity => 'Activiteit';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Recent';

  @override
  String get map_stale => 'Verouderd';

  @override
  String get map_visible => 'Zichtbaar';

  @override
  String get map_hidden => 'Verborgen';

  @override
  String get map_centerOnNode => 'Centreer op node';

  @override
  String get map_centerOnMe => 'Centreren op mijn locatie';

  @override
  String get map_details => 'Details';

  @override
  String get map_noGps => 'Geen GPS';

  @override
  String get map_noResults => 'Geen overeenkomende nodes';

  @override
  String get map_lineOfSight => 'Zichtlijn';

  @override
  String get map_losScreenTitle => 'Zichtlijn';

  @override
  String get map_noNodesWithLocation => 'Geen nodes met locatiegegevens';

  @override
  String get map_noNodesLocationHint =>
      'Geen nodes met een recente locatie. Verruim het tijdfilter of stel je eigen locatie in bij Instellingen.';

  @override
  String get map_nodesNeedGps =>
      'Nodes moeten hun GPS-coördinaten delen\nom op de kaart te verschijnen';

  @override
  String map_nodesCount(int count) {
    return 'Nodes: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pins: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repeater';

  @override
  String get map_room => 'Room';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Pin (privé)';

  @override
  String get map_pinPublic => 'Pin (openbaar)';

  @override
  String get map_lastSeen => 'Laatst gezien';

  @override
  String get map_disconnectConfirm =>
      'Ben je er zeker van dat je verbinding met dit apparaat wilt verbreken?';

  @override
  String get map_from => 'Van';

  @override
  String get map_source => 'Bron';

  @override
  String get map_flags => 'Vlaggen';

  @override
  String get map_type => 'Type';

  @override
  String get map_path => 'Pad';

  @override
  String get map_location => 'Locatie';

  @override
  String get map_estLocation => 'Geschatte locatie';

  @override
  String get map_publicKey => 'Openbare sleutel';

  @override
  String get map_publicKeyPrefixHint => 'bijv. ab12';

  @override
  String get map_shareMarkerHere => 'Deel marker hier';

  @override
  String get map_setAsMyLocation => 'Stel dit in als mijn locatie';

  @override
  String get map_pinLabel => 'Pinlabel';

  @override
  String get map_label => 'Label';

  @override
  String get map_pointOfInterest => 'Interessepunt';

  @override
  String get map_sendToContact => 'Verzenden naar contact';

  @override
  String get map_sendToChannel => 'Verzenden naar kanaal';

  @override
  String get map_noChannelsAvailable => 'Geen kanalen beschikbaar';

  @override
  String get map_publicLocationShare => 'Openbare locatie delen';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Je gaat een locatie delen in $channelLabel. Dit kanaal is openbaar en iedereen met de PSK kan het zien.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Verbind met een apparaat om markers te delen';

  @override
  String get map_filterNodes => 'Nodes filteren';

  @override
  String get map_nodeTypes => 'Nodetypes';

  @override
  String get map_chatNodes => 'Chatnodes';

  @override
  String get map_repeaters => 'Repeaters';

  @override
  String get map_otherNodes => 'Andere Nodes';

  @override
  String get map_showOverlaps => 'Overlappende repeatersleutels';

  @override
  String get map_keyPrefix => 'Sleutelprefix';

  @override
  String get map_filterByKeyPrefix => 'Filteren op sleutelprefix';

  @override
  String get map_publicKeyPrefix => 'Prefix openbare sleutel';

  @override
  String get map_markers => 'Markeringen';

  @override
  String get map_showSharedMarkers => 'Toon gedeelde markeringen';

  @override
  String get map_showGuessedLocations => 'Geschatte nodelocaties tonen';

  @override
  String get map_clusterNodes => 'Nodes in de buurt groeperen';

  @override
  String get map_groupChip => 'Groep';

  @override
  String get map_clusterNodesSubtitle =>
      'Toon nodes in de buurt bij uitzoomen als één genummerde cirkel';

  @override
  String get map_showDiscoveryContacts => 'Ontdekte contacten tonen';

  @override
  String get map_guessedLocation => 'Geschatte locatie';

  @override
  String get map_lastSeenTime => 'Laatst gezien';

  @override
  String get map_sharedPin => 'Gedeelde pin';

  @override
  String get map_sharedAt => 'Gedeeld';

  @override
  String get map_joinRoom => 'Room betreden';

  @override
  String get map_manageRepeater => 'Beheer Repeater';

  @override
  String get map_manageServer => 'Server beheren';

  @override
  String get map_tapToAdd => 'Tik op nodes om ze aan het pad toe te voegen.';

  @override
  String get map_runTrace => 'Padtrace uitvoeren';

  @override
  String get map_runTraceWithReturnPath => 'Terugkeren op hetzelfde pad.';

  @override
  String get map_removeLast => 'Verwijder Laatste';

  @override
  String get map_pathTraceCancelled => 'Pad traceren geannuleerd';

  @override
  String get mapCache_title => 'Offline Kaarten Cache';

  @override
  String get mapCache_selectAreaFirst =>
      'Selecteer eerst een gebied om te cachen';

  @override
  String get mapCache_noTilesToDownload =>
      'Geen tegels te downloaden voor dit gebied.';

  @override
  String get mapCache_downloadTilesTitle => 'Tegels downloaden';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Download $count tegels voor offline gebruik?';
  }

  @override
  String get mapCache_downloadAction => 'Downloaden';

  @override
  String mapCache_cachedTiles(int count) {
    return '$count tegels gecachet';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return '$downloaded tegels gecachet ($failed mislukt)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Offline cache wissen';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Alle gecachete kaarttegels verwijderen?';

  @override
  String get mapCache_offlineCacheCleared => 'Offline cache gewist';

  @override
  String get mapCache_noAreaSelected => 'Geen gebied geselecteerd';

  @override
  String get mapCache_cacheArea => 'Cache-gebied';

  @override
  String get mapCache_useCurrentView => 'Gebruik Huidige Weergave';

  @override
  String get mapCache_zoomRange => 'Zoom Bereik';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Geschatte tegels: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Gedownload $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Tegels downloaden';

  @override
  String get mapCache_clearCacheButton => 'Cache legen';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Mislukte downloads: $count';
  }

  @override
  String get mapCache_cachedTilesLabel => 'Gecachete tegels';

  @override
  String get mapCache_cachedTileSummaryLabel => 'Overzicht gecachete tegels';

  @override
  String mapCache_bulkDownloadDisabledForSource(String source) {
    return 'Offline bulkdownloads zijn uitgeschakeld voor $source.';
  }

  @override
  String mapCache_bulkDownloadDisabledInConfig(String source) {
    return 'Offline bulkdownloads zijn uitgeschakeld voor $source in deze app-configuratie.';
  }

  @override
  String mapCache_summarySource(String source) {
    return 'Bron: $source';
  }

  @override
  String mapCache_summaryCachedTilesForSource(int count) {
    return 'Gecachete tegels voor bron: $count';
  }

  @override
  String mapCache_summaryCachedInSelection(int count) {
    return 'Gecachet in geselecteerd gebied/zoom: $count';
  }

  @override
  String mapCache_summaryApproxCacheSize(String size) {
    return 'Geschatte cachegrootte: $size';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'N $north, Z $south, O $east, W $west';
  }

  @override
  String get time_justNow => 'Net nu';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minuten geleden';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours uur geleden';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dagen geleden';
  }

  @override
  String get time_hour => 'uur';

  @override
  String get time_hours => 'uren';

  @override
  String get time_day => 'dag';

  @override
  String get time_days => 'dagen';

  @override
  String get time_week => 'week';

  @override
  String get time_weeks => 'weken';

  @override
  String get time_month => 'maand';

  @override
  String get time_months => 'maanden';

  @override
  String get time_minutes => 'minuten';

  @override
  String get time_allTime => 'Altijd';

  @override
  String get dialog_disconnect => 'Verbinding verbreken';

  @override
  String get dialog_disconnectConfirm =>
      'Ben je er zeker van dat je verbinding met dit apparaat wilt verbreken?';

  @override
  String get login_repeaterLogin => 'Inloggen Repeater';

  @override
  String get login_roomLogin => 'Inloggen op roomserver';

  @override
  String get login_password => 'Wachtwoord';

  @override
  String get login_enterPassword => 'Wachtwoord invoeren';

  @override
  String get login_showPassword => 'Wachtwoord tonen';

  @override
  String get login_hidePassword => 'Wachtwoord verbergen';

  @override
  String get login_savePassword => 'Wachtwoord opslaan';

  @override
  String get login_savePasswordSubtitle =>
      'Het wachtwoord wordt veilig op dit apparaat opgeslagen.';

  @override
  String get login_repeaterDescription =>
      'Het beheerderswachtwoord geeft toegang tot instellingen en de CLI. Een gastwachtwoord (of leeg) toont alleen de status.';

  @override
  String get login_roomDescription =>
      'Voer het wachtwoord van de room in voor gast- of beheerderstoegang.';

  @override
  String get login_advanced => 'Geavanceerd';

  @override
  String get login_routing => 'Routering';

  @override
  String get login_routingMode => 'Routeerwijze';

  @override
  String get login_autoUseSavedPath => 'Automatisch (gebruik opgeslagen pad)';

  @override
  String get login_forceFloodMode => 'Floodmodus afdwingen';

  @override
  String get login_managePaths => 'Padbeheer';

  @override
  String get login_login => 'Inloggen';

  @override
  String login_attempt(int current, int max) {
    return 'Poging $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Inloggen mislukt: $error';
  }

  @override
  String get login_failedMessage =>
      'Inloggen mislukt. Het wachtwoord is onjuist of de repeater is niet bereikbaar.';

  @override
  String get common_reload => 'Opnieuw laden';

  @override
  String get common_clear => 'Wissen';

  @override
  String get common_clearSearch => 'Zoekopdracht wissen';

  @override
  String get path_currentPathLabel => 'Huidig pad';

  @override
  String get path_noRepeatersFound => 'Geen repeaters of roomservers gevonden.';

  @override
  String get repeater_management => 'Repeaterbeheer';

  @override
  String get room_management => 'Roomserverbeheer';

  @override
  String get repeater_guest => 'Repeaterinformatie';

  @override
  String get room_guest => 'Roomserverinformatie';

  @override
  String get repeater_managementTools => 'Beheerfuncties';

  @override
  String get repeater_guestTools => 'Gastenfuncties';

  @override
  String get repeater_roleAdmin => 'ADMIN';

  @override
  String get repeater_roleGuest => 'GAST';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Status, statistieken en buren bekijken';

  @override
  String get repeater_telemetry => 'Telemetrie';

  @override
  String get repeater_telemetrySubtitle =>
      'Bekijk telemetrie van sensoren en systeemgegevens';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Verzend commando\'s naar de repeater';

  @override
  String get repeater_neighbors => 'Buren';

  @override
  String get repeater_neighborsSubtitle => 'Bekijk zero-hop-buren.';

  @override
  String get repeater_settings => 'Instellingen';

  @override
  String get repeater_settingsSubtitle => 'Configureer repeaterparameters';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Na het inloggen, klok synchroniseren';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatisch een \"klok synchroniseren\" bericht versturen na een succesvolle inlog.';

  @override
  String get repeater_statusTitle => 'Status repeater';

  @override
  String get repeater_routingMode => 'Routeerwijze';

  @override
  String get repeater_refresh => 'Vernieuwen';

  @override
  String get repeater_statusRequestTimeout => 'Time-out bij statusverzoek.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Fout bij het laden van de status: $error';
  }

  @override
  String get repeater_systemInformation => 'Systeeminformatie';

  @override
  String get repeater_battery => 'Batterij';

  @override
  String get repeater_clockAtLogin => 'Tijd (bij aanmelden)';

  @override
  String get repeater_uptime => 'Uptime';

  @override
  String get repeater_queueLength => 'Wachtrijlengte';

  @override
  String get repeater_debugFlags => 'Debugvlaggen';

  @override
  String get repeater_radioStatistics => 'Radiostatistieken';

  @override
  String get repeater_lastRssi => 'Laatste RSSI';

  @override
  String get repeater_lastSnr => 'Laatste SNR';

  @override
  String get repeater_noiseFloor => 'Ruisvloer';

  @override
  String get repeater_txAirtime => 'TX-zendtijd';

  @override
  String get repeater_rxAirtime => 'RX-tijd';

  @override
  String get repeater_chanUtil => 'Kanaalbezetting';

  @override
  String get repeater_packetStatistics => 'Pakketstatistieken';

  @override
  String get repeater_sent => 'Verzonden';

  @override
  String get repeater_received => 'Ontvangen';

  @override
  String get repeater_duplicates => 'Duplicaten';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dagen $hours uur $minutes minuten $seconds seconden';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Totaal: $total, Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Totaal: $total, Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Totaal: $total';
  }

  @override
  String get repeater_settingsTitle => 'Repeaterinstellingen';

  @override
  String get repeater_basicSettings => 'Basisinstellingen';

  @override
  String get repeater_repeaterName => 'Repeaternaam';

  @override
  String get repeater_repeaterNameHelper => 'Weergavenaam voor deze repeater';

  @override
  String get repeater_adminPassword => 'Admin wachtwoord';

  @override
  String get repeater_adminPasswordHelper =>
      'Wachtwoord voor volledige toegang';

  @override
  String get repeater_guestPassword => 'Gast wachtwoord';

  @override
  String get repeater_guestPasswordHelper =>
      'Wachtwoord voor alleen-lezen toegang';

  @override
  String get repeater_radioSettings => 'Radio Instellingen';

  @override
  String get repeater_frequencyMhz => 'Frequentie (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX-vermogen';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Bandbreedte';

  @override
  String get repeater_spreadingFactor => 'Spreadingfactor';

  @override
  String get repeater_codingRate => 'Coding rate';

  @override
  String get repeater_locationSettings => 'Locatie-instellingen';

  @override
  String get repeater_latitude => 'Breedtegraad';

  @override
  String get repeater_latitudeHelper => 'Decimale graden (bijv. 37.7749)';

  @override
  String get repeater_longitude => 'Lengtegraad';

  @override
  String get repeater_longitudeHelper => 'Decimale graden (bijv. -122.4194)';

  @override
  String get repeater_features => 'Kenmerken';

  @override
  String get repeater_packetForwarding => 'Pakketten doorsturen';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Laat de repeater pakketten doorsturen';

  @override
  String get repeater_guestAccess => 'Toegang voor Gasten';

  @override
  String get repeater_guestAccessSubtitle =>
      'Alleen-lezen toegang voor gasten toestaan';

  @override
  String get repeater_privacyMode => 'Privacymodus';

  @override
  String get repeater_privacyModeSubtitle =>
      'Naam/locatie verbergen in adverts';

  @override
  String get repeater_advertisementSettings => 'Advert-instellingen';

  @override
  String get repeater_localAdvertInterval => 'Lokaal advert-interval';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minuten';
  }

  @override
  String get repeater_floodAdvertInterval => 'Flood-advert-interval';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours uur';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Versleuteld advert-interval';

  @override
  String get repeater_dangerZone => 'Gevaarzone';

  @override
  String get repeater_rebootRepeater => 'Herstart Repeater';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Herstart het repeaterapparaat';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ben je er zeker van dat je deze repeater opnieuw wilt opstarten?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Identiteitssleutel opnieuw genereren';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Nieuw openbaar/privé-sleutelpaar genereren';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Dit genereert een nieuwe identiteit voor de repeater. Doorgaan?';

  @override
  String get repeater_eraseFileSystem => 'Bestandssysteem wissen';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatteer het bestandssysteem van de repeater';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'WAARSCHUWING: Dit zal alle gegevens op de repeater wissen. Dit kan niet worden teruggedraaid!';

  @override
  String get repeater_eraseSerialOnly =>
      'Verwijderen is alleen beschikbaar via de seriële console.';

  @override
  String repeater_commandSent(String command) {
    return 'Commando verzonden: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Fout bij het verzenden van de opdracht: $error';
  }

  @override
  String get repeater_confirm => 'Bevestigen';

  @override
  String get repeater_settingsSaved => 'Instellingen succesvol opgeslagen';

  @override
  String get repeater_rxGain => 'Verhoogde RX-versterking';

  @override
  String get repeater_rxGainHelper =>
      'Hogere gevoeligheid, meer stroomverbruik (alleen SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain => 'Verhoogde RX-versterking vernieuwen';

  @override
  String get repeater_multiAcks => 'Multi-ACKs';

  @override
  String get repeater_multiAcksSubtitle =>
      'Bevestig berichten via meerdere paden voor betere aflevering';

  @override
  String get repeater_refreshMultiAcks => 'Multi-ACKs vernieuwen';

  @override
  String get repeater_networkHealth => 'Netwerkgezondheid';

  @override
  String get repeater_loopDetect => 'Lusdetectie';

  @override
  String get repeater_loopDetectHelper =>
      'Flood-pakketten negeren die op routeringslussen lijken';

  @override
  String get repeater_loopDetectOff => 'Uit';

  @override
  String get repeater_loopDetectMinimal => 'Minimaal';

  @override
  String get repeater_loopDetectModerate => 'Matig';

  @override
  String get repeater_loopDetectStrict => 'Strikt';

  @override
  String get repeater_dutyCycle => 'Duty cycle';

  @override
  String get repeater_dutyCycleHelper => 'Maximaal percentage zendtijd';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Informatie over de operator';

  @override
  String get repeater_ownerInfoHelper => 'Openbare metadata voor deze repeater';

  @override
  String get repeater_refreshOwnerInfo => 'Operatorinformatie vernieuwen';

  @override
  String get repeater_floodMax => 'Max. flood-hops';

  @override
  String get repeater_floodMaxHelper =>
      'Maximaal aantal hops dat een flood-pakket mag afleggen (0-64)';

  @override
  String get repeater_advancedSettings => 'Geavanceerd';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Afstelopties voor ervaren operators';

  @override
  String get repeater_pathHashMode => 'Node-ID-grootte in paden';

  @override
  String get repeater_pathHashModeHelper =>
      'Grootte van de ID van deze repeater in de paden van de adverts die hij verzendt: 1 byte (256 ID\'s, tot 64 hops), 2 bytes (65K ID\'s, tot 32 hops), 3 bytes (16M ID\'s, tot 21 hops). Heeft geen invloed op doorsturen; repeaters met v1.14+ sturen alle groottes door, maar oudere firmware laat pakketten met 2- of 3-byte-ID\'s vallen.';

  @override
  String get repeater_keySettings => 'Identiteitssleutels wijzigen';

  @override
  String get repeater_keySettingsSubtitle =>
      'Wijzig het openbare/privé-sleutelpaar';

  @override
  String get repeater_prvKey => 'Privésleutel';

  @override
  String get repeater_prvKeyHelper =>
      'Een nieuwe privésleutel voor de repeater: een hexadecimale string van 128 tekens.';

  @override
  String get repeater_generatePrvKey => 'Willekeurig sleutelpaar genereren';

  @override
  String get repeater_stopGeneratingPrvKey =>
      'Zoeken naar sleutelpaar onderbreken';

  @override
  String get repeater_pubKey => 'Openbare sleutel';

  @override
  String get repeater_pubKeyHelper =>
      'Dit is de openbare sleutel die bij de gegenereerde privésleutel hoort. Je kunt deze niet direct instellen.';

  @override
  String get repeater_pubKeyPrefix => 'Gewenst prefix';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Zoek een openbare sleutel die begint met deze hexadecimale cijfers. Verwacht aantal pogingen: $tries.';
  }

  @override
  String get repeater_txDelay => 'Flood-TX-vertraging';

  @override
  String get repeater_txDelayHelper =>
      'Tussenruimte bij het herzenden van flood-verkeer, als veelvoud van de zendtijd van het pakket (0-2, standaard 0,5). Hoger = minder botsingen maar tragere aflevering.';

  @override
  String get repeater_directTxDelay => 'Direct-TX-vertraging';

  @override
  String get repeater_directTxDelayHelper =>
      'Tussenruimte bij het herzenden van direct (niet-flood) verkeer, als veelvoud van de zendtijd van het pakket (0-2, standaard 0,3).';

  @override
  String get repeater_intThresh => 'Grenswaarde voor interferentie';

  @override
  String get repeater_intThreshHelper =>
      'Drempel die aan de ruisvloerkalibratie van de radio wordt doorgegeven, zodat interferentie boven dit niveau wordt geweigerd. 0 schakelt dit uit — verhoog alleen als je RX-fouten ziet in een drukke band.';

  @override
  String get repeater_agcResetInterval => 'AGC-resetinterval';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Hoe vaak de automatische versterkingsregeling (AGC) van de radio wordt gereset om te herstellen van een vastgelopen versterking. In seconden, naar beneden afgerond op een veelvoud van 4. 0 schakelt periodieke resets uit.';

  @override
  String get repeater_actionsTitle => 'Acties';

  @override
  String get repeater_sendAdvert => 'Verzend flood-advert';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Zend een flood-advert uit via het netwerk.';

  @override
  String get repeater_sendAdvertZeroHop => 'Zero-hop-advert verzenden';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Zend een advert over één hop uit (geen doorgifte)';

  @override
  String get repeater_clockSync => 'Synchroniseer klok nu';

  @override
  String get repeater_clockSyncSubtitle =>
      'Stuur de tijd van je telefoon naar de repeater';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action is gelukt';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action mislukt: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Instellingen opgeslagen — herstart de repeater om ze toe te passen';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Sommige instellingen zijn mislukt: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Fout bij het opslaan van de instellingen: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Basisinstellingen vernieuwen';

  @override
  String get repeater_refreshRadioSettings => 'Radio-instellingen vernieuwen';

  @override
  String get repeater_refreshTxPower => 'TX-vermogen vernieuwen';

  @override
  String get repeater_refreshPacketForwarding =>
      'Pakketten doorsturen vernieuwen';

  @override
  String get repeater_refreshGuestAccess => 'Gasttoegang vernieuwen';

  @override
  String get repeater_refreshPrivacyMode => 'Privacymodus vernieuwen';

  @override
  String get repeater_refreshAll => 'Alles vernieuwen';

  @override
  String get repeater_settingsNotLoaded =>
      'De instellingen van deze repeater zijn nog niet geladen.';

  @override
  String get repeater_settingsLoadIncomplete =>
      'Sommige instellingen konden niet worden geladen. Gebruik de vernieuwknoppen om het opnieuw te proberen.';

  @override
  String repeater_refreshed(String label) {
    return '$label is vernieuwd';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Fout bij het vernieuwen van $label';
  }

  @override
  String get repeater_cliTitle => 'Repeater-CLI';

  @override
  String get repeater_debugNextCommand => 'Debug Volgende Commando';

  @override
  String get repeater_commandHelp => 'Commandohulp';

  @override
  String get repeater_clearHistory => 'Geschiedenis Verwijderen';

  @override
  String get repeater_noCommandsSent => 'Nog geen commando\'s verzonden.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Typ een opdracht hieronder of gebruik snelle commando\'s';

  @override
  String get repeater_enterCommandHint => 'Voer commando in...';

  @override
  String get repeater_previousCommand => 'Vorige opdracht';

  @override
  String get repeater_nextCommand => 'Volgende opdracht';

  @override
  String get repeater_enterCommandFirst => 'Voer eerst een commando in';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI Commando Frame';

  @override
  String repeater_cliCommandError(String error) {
    return 'Fout: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Naam opvragen';

  @override
  String get repeater_cliQuickGetRadio => 'Radio-instellingen opvragen';

  @override
  String get repeater_cliQuickGetTx => 'TX opvragen';

  @override
  String get repeater_cliQuickNeighbors => 'Buren';

  @override
  String get repeater_cliQuickVersion => 'Versie';

  @override
  String get repeater_cliQuickAdvertise => 'Advert';

  @override
  String get repeater_cliQuickClock => 'Klok';

  @override
  String get repeater_cliQuickClockSync => 'Kloksynchronisatie';

  @override
  String get repeater_cliQuickDiscovery => 'Ontdek Buren';

  @override
  String get repeater_cliHelpAdvert => 'Advert uitzenden';

  @override
  String get repeater_cliHelpReboot =>
      'Herstart het apparaat. (let op, je krijgt mogelijk een \'Timeout\', wat normaal is)';

  @override
  String get repeater_cliHelpClock =>
      'Toont de huidige tijd volgens de klok van het apparaat.';

  @override
  String get repeater_cliHelpPassword =>
      'Stelt een nieuw beheerderswachtwoord in voor het apparaat.';

  @override
  String get repeater_cliHelpVersion =>
      'Toont de apparaatversie en firmware-bouwdatum.';

  @override
  String get repeater_cliHelpClearStats =>
      'Reset verschillende statistiek-tellers naar nul.';

  @override
  String get repeater_cliHelpSetAf => 'Stelt de airtime-factor in.';

  @override
  String get repeater_cliHelpSetTx =>
      'Stelt het LoRa-zendvermogen in dBm in. (herstart om toe te passen)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Activeert of deactiveert de repeater rol van deze node.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Roomserver) Indien \'on\' is inloggen met een leeg wachtwoord toegestaan, maar kan er niet in de room gepost worden. (alleen lezen)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Stelt het maximale aantal hops van een inkomend floodpakket in (indien >= max, wordt het pakket niet doorgestuurd)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Stelt de Interferentiewaarde (in dB) in. Standaardwaarde is 14. Stel in op 0 om het detecteren van kanaalinterferentie uit te schakelen.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Stelt het interval in om de Auto Gain Controller te resetten. Stel in op 0 om dit uit te schakelen.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Schakelt de functie \'double ACKs\' in of uit.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Stelt het timerinterval in minuten in om een lokaal (zero-hop) advertpakket te versturen. Stel in op 0 om uit te schakelen.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Stelt het timerinterval in uren in om een flood-advertpakket te versturen. Stel in op 0 om dit uit te schakelen.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Stelt het gastwachtwoord in of werkt het bij. (bij repeaters kunnen gastlogins het verzoek \"Get Stats\" versturen)';

  @override
  String get repeater_cliHelpSetName => 'Stelt de advert-naam in.';

  @override
  String get repeater_cliHelpSetLat =>
      'Stelt de breedtegraad voor de advert-kaart in. (decimale graden)';

  @override
  String get repeater_cliHelpSetLon =>
      'Stelt de lengtegraad voor de advert-kaart in. (decimale graden)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Stelt volledig nieuwe radio parameters in en slaat deze op in de instellingen. Vereist een \"reboot\" commando om toe te passen.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Stelt (experimenteel) de basis in (moet > 1 zijn voor effect) voor een lichte vertraging van ontvangen pakketten, op basis van signaalsterkte/score. Stel in op 0 om uit te schakelen.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Stelt een factor in die wordt vermenigvuldigd met de zendtijd van een flood-pakket en met een willekeurig slotsysteem, om het doorsturen te vertragen (om de kans op botsingen te verkleinen).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Vergelijkbaar met txdelay, maar voor het toepassen van een willekeurige vertraging bij het doorsturen van pakketten in directe modus.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Brug in-/uitschakelen.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Stel de vertraging in voordat pakketten opnieuw worden verzonden.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Kies of de brug ontvangen pakketten of verzonden pakketten opnieuw moet versturen.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Stel de seriële link baudrate in voor rs232 bruggen.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Stel het brug-geheim in voor ESP-NOW-bruggen.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Stelt een aangepaste factor in om de gerapporteerde batterijspanning aan te passen (alleen ondersteund op bepaalde boards).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Stelt tijdelijke radio parameters in voor het opgegeven aantal minuten, en keert daarna terug naar de originele radio parameters. (wordt niet opgeslagen in de voorkeuren).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Wijzigt de ACL. Verwijdert de overeenkomende entry (op pubkey-prefix) als \"permissions\" nul is. Voegt een nieuwe entry toe als pubkey-hex de volledige lengte heeft en nog niet in de ACL staat. Werkt de entry bij op overeenkomend pubkey-prefix. Rechtenbits verschillen per firmwarerol, maar de laagste 2 bits zijn: 0 (Gast), 1 (Alleen lezen), 2 (Lezen/schrijven), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Toont het brugtype: none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Start pakketlogging naar het bestandssysteem.';

  @override
  String get repeater_cliHelpLogStop =>
      'Stoppen met het loggen van pakketten naar het bestandssysteem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Verwijdert de pakketlogs uit het bestandssysteem.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Toont een lijst met andere repeater-nodes die via zero-hop-adverts zijn gehoord. Elke regel is id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Verwijdert de eerste overeenkomende vermelding (via pubkey prefix (hex)) uit de lijst van buren.';

  @override
  String get repeater_cliHelpRegion =>
      '(Alleen serieel) Lijst alle gedefinieerde regio\'s en huidige floodrechten.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'LET OP: dit is een speciale multi-command-aanroep. Elk volgend commando is een regionaam (ingesprongen met spaties om de bovenliggende hiërarchie aan te geven, met minimaal één spatie). Beëindigd door een lege regel/commando te sturen.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Zoekt naar een regio met het opgegeven naamprefix (of \"*\" voor de globale scope). Antwoordt met \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Voegt of wijzigt een regio-definitie met de gegeven naam.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Verwijdert een regio-definitie met de gegeven naam. (moet exact overeenkomen en geen kindregio\'s hebben)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Stelt de \'F\'lood-toestemming in voor de opgegeven regio. (\'*\' voor de globale/oude scope)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Verwijdert de \'F\'lood-toestemming voor de gegeven regio. (LET OP: op dit moment niet aanbevolen om dit op de globale/oude scope te gebruiken!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Antwoordt met de huidige \'thuis\'-regio. (Nog nergens toegepast, gereserveerd voor de toekomst)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Stelt de \'thuis\'-regio in.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Slaat de regiolijst/-kaart op in de opslag.';

  @override
  String get repeater_cliHelpGps =>
      'Geeft de status van de GPS. Wanneer de GPS uit staat, antwoordt het alleen met \"uit\", als het aan staat, antwoordt het met \"aan\", status, fix, sat count.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Schakelt de GPS in of uit.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchroniseert de nodetijd met de GPS-klok.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Stel de positie van de node vast als GPS-coördinaten en sla de voorkeuren op.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Geeft de locatie advert-configuratie van de node:\n- none: locatie niet in adverts opnemen\n- share: gps locatie delen (van SensorManager)\n- prefs: locatie adverteren die in de voorkeuren is opgeslagen';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Stelt advert locatie configuratie in.';

  @override
  String get repeater_commandsListTitle => 'Commandolijst';

  @override
  String get repeater_commandsListNote =>
      'LET OP: voor de verschillende \"set ...\" commando\'s is er ook een \"get ...\" commando.';

  @override
  String get repeater_frequencyRangeHelper => '150-2500 MHz';

  @override
  String get repeater_frequencyInvalid => 'Ongeldige frequentie (150-2500 MHz)';

  @override
  String get repeater_txPowerRangeHelper => '-9 tot 30 dBm';

  @override
  String get repeater_recvErrors => 'Ontvangstfouten';

  @override
  String get room_postsStored => 'Opgeslagen posts';

  @override
  String get room_postsPushed => 'Verzonden posts';

  @override
  String get repeater_cliRegionLoadActive =>
      'Regio-laadmodus: verstuur per regel één regionaam, ingesprongen met spaties onder de bovenliggende regio (voeg F toe na de naam om flood toe te staan). Regels krijgen geen antwoord. Verstuur een lege regel om te voltooien en dan \"region save\" om het resultaat te bewaren.';

  @override
  String get repeater_cliRegionLoadHint =>
      'Regioregel, of leeg om te voltooien';

  @override
  String get repeater_cliRegionLoadEnd => '(einde van regio-laadmodus)';

  @override
  String get repeater_cliHelpRegionDef =>
      'Definieert een keten van regio\'s in één commando: elke naam wordt onder de vorige toegevoegd; \"name,parent\" voegt de naam toe en gaat dan verder onder de opgegeven bovenliggende regio. Antwoordt met de regiolijst.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Stelt het maximale aantal hops in voor het doorsturen van flood-pakketten zonder regio-scope (0-64).';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Stelt het maximale aantal hops in voor het doorsturen van flood-adverts (0-64).';

  @override
  String get repeater_cliHelpGetFloodMaxUnscoped =>
      'Toont het maximale aantal hops voor flood-pakketten zonder regio-scope.';

  @override
  String get repeater_cliHelpGetFloodMaxAdvert =>
      'Toont het maximale aantal hops voor flood-adverts.';

  @override
  String get repeater_cliHelpSetRadioFemRxGain =>
      'Schakelt de RX-versterking (LNA) van de LoRa-frontendmodule. Boards zonder deze module antwoorden met \"Error: unsupported\".';

  @override
  String get repeater_cliHelpSetRadioFemTxGain =>
      'Schakelt de TX-versterking (PA) van de LoRa-frontendmodule. Boards zonder deze module antwoorden met \"Error: unsupported\".';

  @override
  String get repeater_cliHelpGetRadioFemRxGain =>
      'Toont of de RX-versterking van de LoRa-frontendmodule aan staat.';

  @override
  String get repeater_cliHelpGetRadioFemTxGain =>
      'Toont of de TX-versterking van de LoRa-frontendmodule aan staat.';

  @override
  String get repeater_bridgeNote =>
      'Alleen beschikbaar op firmware die met een brug (RS232 of ESP-NOW) is gebouwd.';

  @override
  String get repeater_general => 'Algemeen';

  @override
  String get repeater_settingsCategory => 'Instellingen';

  @override
  String get repeater_bridge => 'Brug';

  @override
  String get repeater_logging => 'Loggen';

  @override
  String get repeater_neighborsRepeaterOnly => 'Buren (Alleen repeaters)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regiobeheer (Alleen Repeater)';

  @override
  String get repeater_regionNote =>
      'Regio-commando\'s zijn geïntroduceerd om regio-definities en permissies te beheren.';

  @override
  String get repeater_gpsManagement => 'Beheer GPS';

  @override
  String get repeater_gpsNote =>
      'Het gps-commando is geïntroduceerd om locatiegerelateerde zaken te beheren.';

  @override
  String get repeater_getCategory => 'Waarden verkrijgen';

  @override
  String get repeater_powerMgmt => 'Energiebeheer';

  @override
  String get repeater_sensors => 'Sensoren';

  @override
  String get repeater_cliHelpPowerOff =>
      'Zorgt ervoor dat het apparaat wordt uitgeschakeld. (geen reactie verwacht)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Stelt de klok terug naar een bekende tijd en start het apparaat opnieuw op.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Verstuurt een advert die alleen naar directe buren wordt gericht (geen tussenliggende stops).';

  @override
  String get repeater_cliHelpStartOta =>
      'Start een firmware-update via de lucht op ondersteunde boards.';

  @override
  String get repeater_cliHelpTime =>
      'Stelt de klok van het apparaat in op de gegeven Unix-tijd (aantal seconden vanaf de Unix-epoch). De klok kan niet teruggedraaid worden.';

  @override
  String get repeater_cliHelpBoard =>
      'Geeft de fabrikant van het bord en/of de hardware-identificatie weer.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Stuurt een verzoek om buren in de buurt te ontdekken. (Alleen van toepassing op een repeater)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Geeft aan of de energiebesparingsmodus is ingeschakeld of uitgeschakeld.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Activeert of deactiveert de energiebesparingsmodus (indien ondersteund).';

  @override
  String get repeater_cliHelpErase =>
      '(Alleen serieel) Formateert het bestandssysteem van het apparaat. Verwijdert alle instellingen en contacten.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Stelt de maximaal toegestane zend-duty-cycle in als percentage (1-100). Past intern de airtime-factor aan.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'Vervangt de privésleutel van de apparaatidentiteit. Herstart vereist om toe te passen. Genereert een nieuwe openbare sleutel.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Alleen voor SX126x-chips) Schakelt de versterkte RX-gain in om de gevoeligheid te verbeteren bij een hoger stroomverbruik.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Definieert de string met contactgegevens van de eigenaar, die in de adverts wordt opgenomen. Gebruik \'|\' voor nieuwe regels.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Stelt de node-ID-grootte in die in de adverts van deze repeater wordt gebruikt: 0 = 1 byte (tot 64 hops), 1 = 2 bytes (tot 32 hops), 2 = 3 bytes (tot 21 hops). 3 is gereserveerd. Heeft geen invloed op welke groottes worden doorgestuurd. Vereist firmware v1.14+.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Stelt de gevoeligheid voor het detecteren van een lus in de routing in: uit, minimaal, matig of strikt.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Alleen serieel) Stelt snel alleen de frequentie in. Herstart vereist. Gebruik bij voorkeur \"set radio\" voor alle radioparameters.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Alleen voor ESPNow-brug) Stelt het WiFi-kanaal (1-14) in dat door de brug wordt gebruikt.';

  @override
  String get repeater_cliHelpGetName => 'Toont de ingestelde nodenaam.';

  @override
  String get repeater_cliHelpGetRole =>
      'Toont de firmwarerol (Repeater, Room Server, enz.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Toont de openbare sleutel van het apparaat.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Alleen serieel) Toont de private sleutel van het apparaat. Behandel dit als een geheim.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Geeft aan of het doorsturen van pakketten (als repeater) is ingeschakeld of uitgeschakeld.';

  @override
  String get repeater_cliHelpGetTx => 'Toont het huidige zendvermogen in dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Toont de geconfigureerde frequentie in MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Toont alle radioparameters: frequentie, bandbreedte, spreadingfactor, coding rate.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Alleen SX126x) Toont de status van de verhoogde RX-versterking.';

  @override
  String get repeater_cliHelpGetAf => 'Toont de huidige airtime-factor.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Toont de huidige toegestane duty cycle als een percentage.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Toont de drempelwaarde voor kanaalinterferentie in dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Geeft het interval in seconden aan voor het resetten van de AGC (Automatic Gain Control).';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Geeft aan of de modus \"dubbele bevestiging\" is ingeschakeld (1) of uitgeschakeld (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Toont of alleen-lezen toegang voor gasten is toegestaan.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Geeft de duur van het lokale advert-interval in minuten aan.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Geeft de duur van het flood-advert-interval in uren aan.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Toont het ingestelde gastwachtwoord.';

  @override
  String get repeater_cliHelpGetLat => 'Toont de ingestelde breedtegraad.';

  @override
  String get repeater_cliHelpGetLon => 'Toont de ingestelde lengtegraad.';

  @override
  String get repeater_cliHelpGetRxDelay =>
      'Toont de basiswaarde van de rx-vertraging.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Geeft de factor weer die de vertraging in de flood-modus bepaalt.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Geeft de factor voor de vertraging in de directe modus weer.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Toont het maximale aantal hops voor flood-pakketten.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Toont de string met contactgegevens van de eigenaar.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Toont de node-ID-groottemodus die in adverts wordt gebruikt (0 = 1 byte, 1 = 2 bytes, 2 = 3 bytes).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Geeft de gevoeligheid voor het detecteren van lusvorming weer.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Alleen serieel) Geeft de toegangscontroles weer op een repeater.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Geeft aan of de brug is ingeschakeld.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Geeft de vertraging van de brug in milliseconden weer.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Toont of de brug RX- of TX-pakketten logt.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Alleen RS232-brug) Toont de baud-snelheid van de brug.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Alleen voor ESPNow-brug) Toont het WiFi-kanaal van de brug.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Alleen ESP-NOW-brug) Toont het gedeelde geheim van de brug.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Alleen voor NRF52) Toont de versie van de bootloader.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Toont de ADC-vermenigvuldiging (schalen van de batterijspanning).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Meldt of het board ondersteuning heeft voor energiebeheer.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Geeft de huidige stroombron aan: extern of batterij.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Geeft de meest recente redenen voor het opnieuw opstarten en afsluiten weer.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Geeft de batterijspanning in mV weer, direct na het opstarten.';

  @override
  String get repeater_cliHelpSensorGet =>
      'Leest een aangepaste sensorinstelling op sleutel.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Schrijft een aangepaste sensorinstelling.';

  @override
  String get repeater_cliHelpSensorList =>
      'Toont alle aangepaste sensorinstellingen, gepagineerd vanaf een optionele startindex.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Toont het huidige standaard regio-bereik.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Stelt de standaard regio-omvang in. Gebruik \"<null>\" om deze te resetten.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Geeft een lijst van regio\'s die flood-verkeer toestaan.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Geeft een lijst van regio\'s die flood-verkeer verbieden.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Alleen serieel) Toont statistieken op pakketniveau.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Alleen serieel) Toont radio-statistieken.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Alleen serieel) Toont de belangrijkste firmware-statistieken.';

  @override
  String get telemetry_receivedData => 'Ontvangen Telemetriedata';

  @override
  String get telemetry_requestTimeout => 'Time-out bij telemetrieverzoek.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Fout bij het laden van de telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Geen telemetriedata beschikbaar.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanaal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batterij';

  @override
  String get telemetry_voltageLabel => 'Spanning';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU-temperatuur';

  @override
  String get telemetry_temperatureLabel => 'Temperatuur';

  @override
  String get telemetry_currentLabel => 'Stroom';

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
  String get telemetry_digitalInputLabel => 'Digitale ingang';

  @override
  String get telemetry_digitalOutputLabel => 'Digitale uitgang';

  @override
  String get telemetry_analogInputLabel => 'Analoge ingang';

  @override
  String get telemetry_analogOutputLabel => 'Analoge uitgang';

  @override
  String get telemetry_genericLabel => 'Algemene sensor';

  @override
  String get telemetry_luminosityLabel => 'Lichtsterkte';

  @override
  String get telemetry_presenceLabel => 'Aanwezigheid';

  @override
  String get telemetry_humidityLabel => 'Luchtvochtigheid';

  @override
  String get telemetry_accelerometerLabel => 'Versnellingsmeter';

  @override
  String get telemetry_pressureLabel => 'Druk';

  @override
  String get telemetry_altitudeLabel => 'Hoogte';

  @override
  String get telemetry_frequencyLabel => 'Frequentie';

  @override
  String get telemetry_percentageLabel => 'Percentage';

  @override
  String get telemetry_concentrationLabel => 'Concentratie';

  @override
  String get telemetry_powerLabel => 'Vermogen';

  @override
  String get telemetry_distanceLabel => 'Afstand';

  @override
  String get telemetry_energyLabel => 'Energie';

  @override
  String get telemetry_directionLabel => 'Richting';

  @override
  String get telemetry_timeLabel => 'Tijd';

  @override
  String get telemetry_gyrometerLabel => 'Gyrometer';

  @override
  String get telemetry_colourLabel => 'Kleur';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Schakelaar';

  @override
  String get telemetry_polylineLabel => 'Polylijn';

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
  String get telemetry_autoFetchQuantity => 'Aantal aanvragen';

  @override
  String get telemetry_error => 'Kan gegevens niet ophalen';

  @override
  String get neighbors_receivedData => 'Ontvangen burengegevens';

  @override
  String get neighbors_requestTimedOut => 'Time-out bij burenverzoek.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Fout bij het laden van buren: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Buren van repeaters';

  @override
  String get neighbors_noData => 'Geen gegevens van buren beschikbaar.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Onbekende $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Gehoord: $time geleden';
  }

  @override
  String get channelPath_title => 'Pakketpad';

  @override
  String get channelPath_viewMap => 'Kaart bekijken';

  @override
  String get channelPath_otherObservedPaths => 'Overige Waargenomen Paden';

  @override
  String get channelPath_repeaterHops => 'Repeater-hops';

  @override
  String get channelPath_noHopDetails =>
      'Voor dit pakket zijn geen hopdetails beschikbaar.';

  @override
  String get channelPath_messageDetails => 'Details Bericht';

  @override
  String get channelPath_senderLabel => 'Afzender';

  @override
  String get channelPath_timeLabel => 'Tijd';

  @override
  String get channelPath_repeatsLabel => 'Herhalingen';

  @override
  String channelPath_pathLabel(int index) {
    return 'Pad $index';
  }

  @override
  String get channelPath_observedLabel => 'Waargenomen';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Waargenomen pad $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Geen locatiegegevens';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Onbekend';

  @override
  String get channelPath_floodPath => 'Flood';

  @override
  String get channelPath_directPath => 'Direct';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 van $total hops';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed van $total hops';
  }

  @override
  String get channelPath_mapTitle => 'Padkaart';

  @override
  String get channelPath_noRepeaterLocations =>
      'Geen repeaterlocaties beschikbaar voor dit pad.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Pad $index (primair)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Pad';

  @override
  String get channelPath_observedPathHeader => 'Waargenomen Pad';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Geen details beschikbaar voor dit pakket.';

  @override
  String get channelPath_unknownRepeater => 'Onbekende repeater';

  @override
  String get community_title => 'Community';

  @override
  String get community_create => 'Community aanmaken';

  @override
  String get community_createDesc =>
      'Maak een nieuwe community en deel deze via QR-code.';

  @override
  String get community_join => 'Deelnemen';

  @override
  String get community_joinTitle => 'Deelnemen aan community';

  @override
  String community_joinConfirmation(String name) {
    return 'Wil je je aansluiten bij de community \"$name\"?';
  }

  @override
  String get community_scanQr => 'Community-QR scannen';

  @override
  String get community_scanInstructions =>
      'Richt de camera op een community-QR-code';

  @override
  String get community_showQr => 'Toon QR-code';

  @override
  String get community_publicChannel => 'Community openbaar';

  @override
  String get community_hashtagChannel => 'Community-hashtag';

  @override
  String get community_name => 'Communitynaam';

  @override
  String get community_enterName => 'Voer de communitynaam in';

  @override
  String community_created(String name) {
    return 'Community \"$name\" aangemaakt';
  }

  @override
  String community_joined(String name) {
    return 'Deelgenomen aan community \"$name\"';
  }

  @override
  String get community_qrTitle => 'Community delen';

  @override
  String community_qrInstructions(String name) {
    return 'Scan deze QR-code om deel te nemen aan \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Community hashtag-kanalen zijn alleen toegankelijk voor leden van de community';

  @override
  String get community_invalidQrCode => 'Ongeldige community QR-code';

  @override
  String get community_alreadyMember => 'Al lid';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Je bent al lid van \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Openbaar communitykanaal toevoegen';

  @override
  String get community_addPublicChannelHint =>
      'Voeg automatisch het openbare kanaal van deze community toe';

  @override
  String get community_noCommunities => 'Nog geen communities';

  @override
  String get community_scanOrCreate =>
      'Scan een QR-code of maak een community aan om te beginnen';

  @override
  String get community_manageCommunities => 'Communities beheren';

  @override
  String get community_delete => 'Community verlaten';

  @override
  String community_deleteConfirm(String name) {
    return '\"$name\" verlaten?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Dit verwijdert ook $count kanaal/kanalen en hun berichten.';
  }

  @override
  String community_deleted(String name) {
    return 'Community \"$name\" verlaten';
  }

  @override
  String get community_regenerateSecret => 'Geheim opnieuw genereren';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'De geheime sleutel voor \"$name\" opnieuw genereren? Alle leden moeten de nieuwe QR-code scannen om te blijven communiceren.';
  }

  @override
  String get community_regenerate => 'Opnieuw genereren';

  @override
  String community_secretRegenerated(String name) {
    return 'Geheim opnieuw gegenereerd voor \"$name\"';
  }

  @override
  String get community_updateSecret => 'Geheim bijwerken';

  @override
  String community_secretUpdated(String name) {
    return 'Geheim gewijzigd voor \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scan de nieuwe QR-code om het geheim voor \"$name\" bij te werken';
  }

  @override
  String get community_addHashtagChannel => 'Voeg Community Hashtag toe';

  @override
  String get community_addHashtagChannelDesc =>
      'Voeg een hashtag-kanaal toe aan deze community';

  @override
  String get community_selectCommunity => 'Community selecteren';

  @override
  String get community_regularHashtag => 'Gewone Hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Open hashtag (iedereen kan deelnemen)';

  @override
  String get community_communityHashtag => 'Community-hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Alleen zichtbaar voor leden van de community';

  @override
  String community_forCommunity(String name) {
    return 'Voor $name';
  }

  @override
  String get listFilter_tooltip => 'Filteren en sorteren';

  @override
  String get listFilter_sortBy => 'Sorteren op';

  @override
  String get listFilter_latestMessages => 'Recente berichten';

  @override
  String get listFilter_heardRecently => 'Recent gehoord';

  @override
  String get listFilter_az => 'Alfabetisch';

  @override
  String get listFilter_filters => 'Filters';

  @override
  String get listFilter_all => 'Alles';

  @override
  String get listFilter_favorites => 'Favorieten';

  @override
  String get listFilter_addToFavorites => 'Toevoegen aan favorieten';

  @override
  String get listFilter_removeFromFavorites => 'Verwijderen uit favorieten';

  @override
  String get listFilter_users => 'Gebruikers';

  @override
  String get listFilter_repeaters => 'Repeaters';

  @override
  String get listFilter_roomServers => 'Roomservers';

  @override
  String get listFilter_unreadOnly => 'Alleen ongelezen';

  @override
  String get listFilter_newGroup => 'Nieuwe groep';

  @override
  String get pathTrace_you => 'Jij';

  @override
  String get pathTrace_failed => 'Padtrace mislukt.';

  @override
  String get pathTrace_notAvailable => 'Padtrace niet beschikbaar.';

  @override
  String get pathTrace_refreshTooltip => 'Padtrace vernieuwen.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Van een of meer hops ontbreekt de locatie!';

  @override
  String get pathTrace_clearTooltip => 'Pad wissen.';

  @override
  String get losSelectStartEnd => 'Selecteer begin- en eindnode voor LOS.';

  @override
  String losRunFailed(String error) {
    return 'Zichtlijncontrole mislukt: $error';
  }

  @override
  String get losClearAllPoints => 'Wis alle punten';

  @override
  String get losRunToViewElevationProfile =>
      'Voer LOS uit om het hoogteprofiel te bekijken';

  @override
  String get losMenuTitle => 'LOS-menu';

  @override
  String get losMenuSubtitle =>
      'Tik op nodes of druk lang op de kaart voor aangepaste punten';

  @override
  String get losShowDisplayNodes => 'Weergavenodes tonen';

  @override
  String get losCustomPoints => 'Aangepaste punten';

  @override
  String losCustomPointLabel(int index) {
    return 'Aangepast $index';
  }

  @override
  String get losPointA => 'Punt A';

  @override
  String get losPointB => 'Punt B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenne A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenne B: $value $unit';
  }

  @override
  String get losRun => 'Voer LOS uit';

  @override
  String get losNoElevationData => 'Geen hoogtegegevens';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, vrije LOS, min. vrije ruimte $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, geblokkeerd door $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: controleren...';

  @override
  String get losStatusNoData => 'LOS: geen gegevens';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total vrij, $blocked geblokkeerd, $unknown onbekend';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Hoogtegegevens niet beschikbaar voor een of meer meetpunten.';

  @override
  String get losErrorInvalidInput =>
      'Ongeldige punten/hoogtegegevens voor LOS-berekening.';

  @override
  String get losRenameCustomPoint => 'Hernoem aangepast punt';

  @override
  String get losPointName => 'Puntnaam';

  @override
  String get losShowPanelTooltip => 'Toon LOS-paneel';

  @override
  String get losHidePanelTooltip => 'LOS-paneel verbergen';

  @override
  String get losElevationAttribution =>
      'Hoogtegegevens: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radiohorizon';

  @override
  String get losLegendLosBeam => 'Zichtlijn';

  @override
  String get losLegendTerrain => 'Terrein';

  @override
  String get losBlockedSpotsTitle => 'Geblokkeerde punten';

  @override
  String get losBlockedSpotsHint =>
      'Tik op een geblokkeerd punt om het op de kaart te markeren.';

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
  String get losSelectedObstructionTitle => 'Geselecteerd obstakel';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Geblokkeerd door $obstruction $heightUnit, $distanceFromA van A en $distanceFromB van B ($distanceUnit).';
  }

  @override
  String get losFrequencyLabel => 'Frequentie';

  @override
  String get losFrequencyInfoTooltip => 'Bekijk details van de berekening';

  @override
  String get losFrequencyDialogTitle => 'Berekening van de radiohorizon';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Beginnend met k=$baselineK bij $baselineFreq MHz, wordt bij de berekening de k-factor aangepast voor de huidige $frequencyMHz MHz-band, die de gebogen radiohorizonkap definieert.';
  }

  @override
  String get contacts_pathTrace => 'Padtrace';

  @override
  String get contacts_ping => 'Pingen';

  @override
  String get contacts_repeaterPathTrace => 'Pad traceren naar repeater';

  @override
  String get contacts_repeaterPing => 'Ping repeater';

  @override
  String get contacts_roomPathTrace => 'Padtrace naar roomserver';

  @override
  String get contacts_roomPing => 'Ping roomserver';

  @override
  String get contacts_chatTraceRoute => 'Route traceren';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Route traceren naar $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Klembord is leeg.';

  @override
  String get contacts_invalidAdvertFormat => 'Ongeldige contactgegevens';

  @override
  String get contacts_contactImported => 'Contact is geïmporteerd.';

  @override
  String get contacts_contactImportFailed =>
      'Contact kon niet geïmporteerd worden.';

  @override
  String get contacts_zeroHopAdvert => 'Zero-hop-advert';

  @override
  String get contacts_floodAdvert => 'Flood-advert';

  @override
  String get contacts_copyAdvertToClipboard => 'Advert naar klembord kopiëren';

  @override
  String get contacts_addContactFromClipboard =>
      'Contact uit klembord toevoegen';

  @override
  String get contacts_scanQrCode => 'QR-code scannen';

  @override
  String get contacts_scanQrInstructions =>
      'Richt de camera op een QR-code van een MeshCore-contact';

  @override
  String get contacts_qrFromGallery => 'QR scannen uit galerij';

  @override
  String get contacts_noQrCodeFound =>
      'Geen QR-code gevonden in de geselecteerde afbeelding.';

  @override
  String get contacts_qrGalleryFailed => 'Kon de galerij niet openen.';

  @override
  String get contacts_ShareContact => 'Contact naar klembord kopiëren';

  @override
  String get contacts_ShareContactZeroHop => 'Contact delen via advert';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Contact verzonden via advert';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Contact verzenden mislukt.';

  @override
  String get contacts_contactAdvertCopied => 'Advert gekopieerd naar klembord.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopiëren van advert naar klembord is mislukt.';

  @override
  String get notification_activityTitle => 'MeshCore Activiteit';

  @override
  String get notification_lowBatteryTitle => 'Low battery';

  @override
  String notification_lowBatteryBody(int percent) {
    return 'Device battery is at $percent%';
  }

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'berichten',
      one: 'bericht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kanaalberichten',
      one: 'kanaalbericht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nieuwe nodes',
      one: 'nieuwe node',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nieuw $contactType ontdekt';
  }

  @override
  String get notification_receivedNewMessage => 'Nieuw bericht ontvangen';

  @override
  String get notification_actionReply => 'Reageren';

  @override
  String get notification_actionMarkRead => 'Markeer als gelezen';

  @override
  String get notification_actionMuteChannel => 'Kanaal dempen';

  @override
  String get notification_replyHint => 'Bericht';

  @override
  String get notification_you => 'Jij';

  @override
  String get notification_replyFailedTitle => 'Antwoord niet verzonden';

  @override
  String get notification_replyNotConnected =>
      'Niet verbonden met een radio. Maak opnieuw verbinding in MeshCore Open en verzend je antwoord opnieuw.';

  @override
  String get notification_replyTooLong =>
      'Je antwoord is te lang om vanuit een melding te verzenden. Verzend het vanuit MeshCore Open.';

  @override
  String get notification_replyUnavailable =>
      'Dit gesprek staat niet meer op de verbonden radio.';

  @override
  String get notification_replySendFailed =>
      'Je antwoord is mogelijk niet verzonden. Controleer dit in MeshCore Open en probeer het opnieuw.';

  @override
  String get notification_replyAppNotRunning =>
      'MeshCore Open is niet actief. Open de app en verzend je antwoord opnieuw.';

  @override
  String get settings_gpxExportRepeaters =>
      'Exporteer repeaters / roomserver naar GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporteert repeaters / roomserver met een locatie naar GPX-bestand.';

  @override
  String get settings_gpxExportContacts => 'Companions exporteren naar GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporteert companions met een locatie naar een GPX-bestand.';

  @override
  String get settings_gpxExportAll => 'Alle contacten exporteren naar GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporteert alle contacten met een locatie naar een GPX-bestand.';

  @override
  String get settings_gpxExportSuccess => 'GPX-bestand succesvol geëxporteerd.';

  @override
  String get settings_gpxExportNoContacts => 'Geen contacten om te exporteren.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Niet ondersteund op je apparaat/besturingssysteem';

  @override
  String get settings_gpxExportError => 'Er was een fout bij het exporteren.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Locaties van repeaters en roomservers';

  @override
  String get settings_gpxExportChat => 'Locaties van companions';

  @override
  String get settings_gpxExportAllContacts => 'Alle contactlocaties';

  @override
  String get settings_gpxExportShareText =>
      'Kaartgegevens geëxporteerd uit meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open GPX kaartgegevens exporteren';

  @override
  String get snrIndicator_nearByRepeaters => 'Repeaters in de buurt';

  @override
  String get snrIndicator_lastSeen => 'Laatst gezien';

  @override
  String get snrIndicator_nearByRepeatersDescription =>
      'Repeaters die je radio rechtstreeks heeft gehoord, meest recent gehoord eerst.';

  @override
  String get contactsSettings_title => 'Instellingen voor contacten';

  @override
  String get contactsSettings_autoAddTitle => 'Automatische detectie';

  @override
  String get contactsSettings_otherTitle =>
      'Andere instellingen voor contactgerelateerde zaken';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Gebruikers automatisch toevoegen';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Sta toe dat de companion automatisch ontdekte gebruikers toevoegt';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Repeaters automatisch toevoegen';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Sta toe dat de companion automatisch ontdekte repeaters toevoegt';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Roomservers automatisch toevoegen';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Sta toe dat de companion automatisch ontdekte roomservers toevoegt.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatisch sensoren toevoegen';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Sta toe dat de companion automatisch ontdekte sensoren toevoegt';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Overschrijf Oudste';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Wanneer de contactenlijst vol is, wordt de oudste niet-favoriete contactpersoon vervangen.';

  @override
  String get discoveredContacts_Title => 'Ontdekte contacten';

  @override
  String get discoveredContacts_noMatching => 'Geen overeenkomende contacten';

  @override
  String get discoveredContacts_searchHint => 'Ontdekte contacten zoeken';

  @override
  String get discoveredContacts_contactAdded => 'Contact toegevoegd';

  @override
  String get discoveredContacts_addContact => 'Contact toevoegen';

  @override
  String get discoveredContacts_copyContact => 'Kopieer contact naar klembord';

  @override
  String get discoveredContacts_deleteContact => 'Ontdekt contact verwijderen';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Verwijder alle ontdekte contacten';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Weet je zeker dat je alle ontdekte contacten wilt verwijderen?';

  @override
  String get chat_sendCooldown => 'Wacht even voordat je opnieuw verzendt.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Ga naar het oudste ongelezen bericht';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Bij het openen van een chat met ongelezen berichten, scroll dan naar het eerste ongelezen bericht, in plaats van naar het meest recente.';

  @override
  String get appSettings_languageHu => 'Hongaars';

  @override
  String get appSettings_languageJa => 'Japans';

  @override
  String get appSettings_languageKo => 'Koreaans';

  @override
  String get radioStats_tooltip => 'Radio- en meshstatistieken';

  @override
  String get radioStats_screenTitle => 'Radiostatistieken';

  @override
  String get radioStats_sectionSignal => 'Signaal';

  @override
  String get radioStats_sectionAirtime => 'Zendtijd';

  @override
  String get radioStats_notConnected =>
      'Verbind met een apparaat om radio-statistieken te bekijken.';

  @override
  String get radioStats_firmwareTooOld =>
      'Radiostatistieken vereisen companion-firmware v8 of nieuwer.';

  @override
  String get radioStats_waiting => 'Wachten op gegevens…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Ruisvloer: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Laatste RSSI-waarde: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Laatste SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX-zendtijd (totaal): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX-tijd (totaal): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Ruisvloer (dBm) over recente metingen.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Ruisvloer: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Radio-statistieken ophalen…';

  @override
  String get radioStats_settingsTile => 'Radiostatistieken';

  @override
  String get radioStats_settingsSubtitle => 'Ruisvloer, RSSI, SNR en zendtijd';

  @override
  String get translation_title => 'Vertaling';

  @override
  String get imageMessages_enableTitle => 'Afbeeldingsberichten inschakelen';

  @override
  String get imageMessages_enableSubtitle =>
      'Verstuur afbeeldingen via de mesh. Vereist een eenmalige download van een afbeeldingsmodel.';

  @override
  String get imageMessages_modelSectionTitle => 'Afbeeldingsmodel';

  @override
  String get imageMessages_downloadModel => 'Download';

  @override
  String get imageMessages_cancelDownload => 'Annuleren';

  @override
  String get imageMessages_removeModel => 'Model verwijderen';

  @override
  String get imageMessages_modelReady => 'Klaar';

  @override
  String get imageMessages_modelNotPublished =>
      'Nog niet gepubliceerd — deze versie kan dit niet downloaden.';

  @override
  String get imageMessages_downloadFailed =>
      'Het afbeeldingsmodel kon niet worden gedownload.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Afbeeldingen automatisch verwerken';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Reconstrueer elke afbeelding zodra deze binnenkomt. Gebruikt elke keer ongeveer een seconde lang zo\'n 2 GB geheugen; laat uit om in plaats daarvan met een tik te reconstrueren.';

  @override
  String get translation_enableTitle => 'Activeer vertaling';

  @override
  String get translation_enableSubtitle =>
      'Vertaal inkomende berichten en maak het mogelijk om berichten vooraf te vertalen.';

  @override
  String get translation_composerTitle => 'Vertaal voor verzending';

  @override
  String get translation_composerSubtitle =>
      'Bepaalt de standaardstatus van het vertaalpictogram in het invoerveld.';

  @override
  String get translation_autoIncomingTitle => 'Berichten automatisch vertalen';

  @override
  String get translation_autoIncomingSubtitle =>
      'Vertaalt berichten automatisch voor meldingen en voor chats of kanalen.';

  @override
  String get translation_translateMessage => 'Bericht vertalen';

  @override
  String get translation_targetLanguage => 'Doeltaal';

  @override
  String get translation_useAppLanguage => 'Gebruik de taal van de app';

  @override
  String get translation_downloadedModelLabel => 'Gedownload model';

  @override
  String get translation_presetModelLabel =>
      'Vooraf ingesteld Hugging Face-model';

  @override
  String get translation_manualUrlLabel => 'Handmatige model-URL';

  @override
  String get translation_downloadModel => 'Download het model';

  @override
  String get translation_downloading => 'Downloaden...';

  @override
  String get translation_working => 'Bezig...';

  @override
  String get translation_stop => 'Stoppen';

  @override
  String get translation_mergingChunks =>
      'Het samenvoegen van de gedownloade stukken tot één eindbestand...';

  @override
  String get translation_downloadedModels => 'Gedownloade modellen';

  @override
  String get translation_deleteModel => 'Model verwijderen';

  @override
  String get translation_modelDownloaded => 'Vertaalmodel gedownload.';

  @override
  String get translation_downloadStopped => 'Download is afgebroken.';

  @override
  String translation_downloadFailed(String error) {
    return 'Download mislukt: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Voer eerst een URL van een model in.';

  @override
  String get scanner_linuxPairingShowPin => 'Toon PIN';

  @override
  String get scanner_linuxPairingHidePin => 'PIN verbergen';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth‑koppelings‑PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Voer PIN in voor $deviceName (laat leeg als er geen is).';
  }

  @override
  String get translation_messageTranslation => 'Berichtvertaling';

  @override
  String get translation_translateBeforeSending => 'Vertaal voor verzending';

  @override
  String get translation_composerEnabledHint =>
      'De berichten worden vertaald voordat ze verzonden worden.';

  @override
  String get translation_composerDisabledHint =>
      'Stuur berichten in de oorspronkelijke, getypte taal.';

  @override
  String translation_translateTo(String language) {
    return 'Vertalen naar $language';
  }

  @override
  String get translation_translationOptions => 'Opties voor vertaling';

  @override
  String get translation_systemLanguage => 'Taal van het systeem';

  @override
  String get background_serviceTitle => 'MeshCore actief';

  @override
  String get background_serviceText => 'BLE-verbinding actief houden';

  @override
  String appSettings_translationModelDeleted(String name) {
    return '$name verwijderd';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Verwijderen mislukt: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Kanaal bijwerken mislukt: $error';
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
  String get contact_typeUnknown => 'Onbekend';

  @override
  String get map_zoomIn => 'Inzoomen';

  @override
  String get map_zoomOut => 'Uitzoomen';

  @override
  String get map_centerMap => 'Kaart centreren';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth vereist een Chromium-browser.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS-locatie bevestigd';

  @override
  String get pathTrace_legendInferred => 'Afgeleide positie';

  @override
  String get pathMap_viewSingle => 'Enkel';

  @override
  String get pathMap_viewCombined => 'Gezamenlijk';

  @override
  String get pathMap_play => 'Afspelen';

  @override
  String get pathMap_pause => 'Pauze';

  @override
  String get pathMap_replay => 'Herhalen';

  @override
  String get pathMap_stepBack => 'Vorige hop';

  @override
  String get pathMap_stepForward => 'Volgende hop';

  @override
  String get pathMap_animationOn => 'Pakketanimatie tonen';

  @override
  String get pathMap_animationOff => 'Pakketanimatie verbergen';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Hop $current van $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Waargenomen paden: $count';
  }

  @override
  String get pathMap_primary => 'Primair';

  @override
  String pathMap_alternate(int index) {
    return 'Alternatief $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hops',
      one: '1 hop',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Gedeeld segment';

  @override
  String get pathMap_legendEstimated => 'Geschat segment';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Gebruikt door $count paden';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count hops hebben geen locatie — het weergegeven pad is onvolledig',
      one: '1 hop heeft geen locatie — het weergegeven pad is onvolledig',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Toon alles';

  @override
  String get pathMap_hidePath => 'Verberg pad';

  @override
  String get pathMap_showPath => 'Toon pad';

  @override
  String get pathMap_collapsePanel => 'Paneel inklappen';

  @override
  String get pathMap_expandPanel => 'Paneel uitklappen';

  @override
  String get pathMap_noLocation => 'Geen locatie';

  @override
  String get pathMap_followPacket => 'Weergave vergrendelen op pakket';

  @override
  String get pathMap_unfollowPacket => 'Weergave ontgrendelen van pakket';

  @override
  String get imageSend_title => 'Afbeelding verzenden';

  @override
  String get imageSend_cropNote =>
      'Geschaald naar 512 × 512 · beeldverhouding niet behouden';

  @override
  String imageSend_lossyNote(int bytes) {
    return 'Gecomprimeerd tot ongeveer $bytes bytes. Het model van de ontvanger reconstrueert de afbeelding, dus details zullen afwijken.';
  }

  @override
  String get imageSend_viewOriginal => 'Origineel';

  @override
  String get imageSend_viewReconstruction => 'Wat ontvangers zien';

  @override
  String get imageSend_reconstructionUnavailable =>
      'Dit apparaat kan geen voorbeeld van de reconstructie tonen.';

  @override
  String get imageSend_modelNotDownloaded =>
      'Het afbeeldingsmodel is nog niet gedownload. Download het in Instellingen om afbeeldingen te verzenden.';

  @override
  String get imageSend_originalSize => 'Origineel';

  @override
  String get imageSend_onAirSize => 'Via radio';

  @override
  String get imageSend_quality => 'Kwaliteit';

  @override
  String get imageSend_qualityStandard => 'Standaard';

  @override
  String get imageSend_qualityHigh => 'Hoog';

  @override
  String get imageSend_packetsLabel => 'Pakketten';

  @override
  String get imageSend_airtimeLabel => 'Zendtijd';

  @override
  String get imageSend_sizeLabel => 'Payload';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pakketten',
      one: 'pakket',
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
  String get imageSend_radioUnknownTitle => 'Radio-instellingen onbekend';

  @override
  String get imageSend_radioUnknownBody =>
      'Verbinding maken met een apparaat zodat de uitzendtijd kan worden berekend.';

  @override
  String get imageSend_longSendTitle => 'Lange transmissie';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Dit bezet het kanaal ongeveer $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Flood-routing: elke repeater binnen bereik herzendt elk pakket, waardoor het kanaal langer bezet blijft dan dit.';

  @override
  String get imageSend_parityTitle => 'Herstelpakket toevoegen';

  @override
  String get imageSend_paritySubtitle =>
      'Eén extra pakket. Groepsberichten worden niet bevestigd, dus zo kan de ontvanger de afbeelding herstellen als één pakket verloren gaat.';

  @override
  String get imageSend_send => 'Verzenden';

  @override
  String get imageSend_cancel => 'Annuleren';

  @override
  String get imageSend_encodeFailed =>
      'Deze afbeelding kon niet worden gecodeerd.';

  @override
  String get imageSend_codecDownloading =>
      'Het afbeeldingsmodel wordt nog gedownload.';

  @override
  String get imageSend_codecUnavailable =>
      'Afbeeldingen verzenden is niet beschikbaar op dit apparaat.';

  @override
  String get imageSend_codecDisabled =>
      'Afbeeldingsberichten zijn uitgeschakeld in de instellingen.';

  @override
  String get imageSend_deviceUnsupported =>
      'Deze radio kan geen afbeeldingspakketten verzenden. Verbind een apparaat met companion-firmware 13 of nieuwer.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'Afbeeldingen worden verzonden als groepsgegevens, dus ze kunnen alleen naar een kanaal worden gestuurd — niet in een direct bericht.';

  @override
  String get imageSend_tooLarge =>
      'Die afbeelding werd gecodeerd in meer pakketten dan het mesh-formaat toelaat.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pakketten',
      one: 'pakket',
    );
    return 'Afbeelding verzonden als $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'De afbeelding kon niet worden verzonden: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Afbeelding verzenden — pakket $sent van $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Node $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$received van $total pakketten';
  }

  @override
  String get receivedImage_queued => 'Wachten op decoderen';

  @override
  String get receivedImage_tapToDecode => 'Tik om te decoderen';

  @override
  String get receivedImage_decoding => 'Reconstrueren… ongeveer 1 s';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Afbeelding onvolledig — $received van $total pakketten ontvangen';
  }

  @override
  String get receivedImage_corrupt =>
      'Afbeelding kon niet worden gereconstrueerd';

  @override
  String get receivedImage_decoderMissing =>
      'Afbeelding ontvangen — afbeeldingsdecodering staat uit';

  @override
  String get receivedImage_evicted => 'Afbeelding niet langer opgeslagen';

  @override
  String get receivedImage_retry => 'Probeer het opnieuw';

  @override
  String get receivedImage_decodeAgain => 'Opnieuw decoderen';

  @override
  String get receivedImage_openSettings => 'Instellen';

  @override
  String get receivedImage_tapToProcess => 'Tik om te verwerken';

  @override
  String get receivedImage_save => 'Afbeelding opslaan';

  @override
  String receivedImage_shareCaption(int bytes) {
    return 'Door AI gereconstrueerd uit $bytes bytes; fijne details zijn gegenereerd, niet verzonden.';
  }

  @override
  String get receivedImage_packetInfo => 'Pakketinfo';

  @override
  String get receivedImage_parityRecovered =>
      'Eén pakket is hersteld met het herstelpakket.';

  @override
  String receivedImage_decodeTime(int ms) {
    return 'Gereconstrueerd in $ms ms';
  }

  @override
  String get receivedImage_saveFailed => 'Kon de afbeelding niet opslaan';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'pakketten',
      one: 'pakket',
    );
    return '$bytes bytes · $packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds s';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes m $seconds s';
  }

  @override
  String chat_longMessageRetryNote(int count) {
    return 'Meer dan 158 bytes: maximaal $count keer verzonden';
  }
}
