// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Kontakte';

  @override
  String get nav_channels => 'Kanäle';

  @override
  String get nav_map => 'Karte';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Verbinden';

  @override
  String get common_unknownDevice => 'Unbekanntes Gerät';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_deleteAll => 'Alles löschen';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_done => 'Fertig';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_add => 'Hinzufügen';

  @override
  String get common_settings => 'Einstellungen';

  @override
  String get common_disconnect => 'Trennen';

  @override
  String get common_connected => 'Verbunden';

  @override
  String get common_disconnected => 'Getrennt';

  @override
  String get common_create => 'Erstellen';

  @override
  String get common_continue => 'Fortfahren';

  @override
  String get common_share => 'Teilen';

  @override
  String get common_copy => 'Kopieren';

  @override
  String get common_retry => 'Wiederholen';

  @override
  String get common_hide => 'Ausblenden';

  @override
  String get common_remove => 'Entfernen';

  @override
  String get common_enable => 'Aktivieren';

  @override
  String get common_disable => 'Deaktivieren';

  @override
  String get common_undo => 'Rückgängig machen';

  @override
  String get messageStatus_sent => 'Gesendet';

  @override
  String get messageStatus_delivered => 'Zugestellt';

  @override
  String get messageStatus_pending => 'Wird gesendet';

  @override
  String get messageStatus_failed => 'Senden fehlgeschlagen';

  @override
  String get messageStatus_repeated => 'Mehrfach gehört';

  @override
  String get common_reboot => 'Neustart';

  @override
  String get common_loading => 'Lädt...';

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
  String get common_autoRefresh => 'Automatische Aktualisierung';

  @override
  String get common_interval => 'Intervall';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Verbinden über TCP';

  @override
  String get tcpHostLabel => 'Endpunkt';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Endpunkt eingeben und verbinden';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Verbindung zu $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Ein Endpunkt ist erforderlich.';

  @override
  String get tcpErrorPortInvalid =>
      'Die Portnummer muss zwischen 1 und 65535 liegen.';

  @override
  String get tcpErrorUnsupported =>
      'TCP wird auf dieser Plattform nicht unterstützt.';

  @override
  String get tcpErrorTimedOut => 'Die TCP-Verbindung ist abgelaufen.';

  @override
  String tcpConnectionFailed(String error) {
    return 'TCP-Verbindung fehlgeschlagen: $error';
  }

  @override
  String get usbScreenTitle => 'Über USB verbinden';

  @override
  String get usbScreenSubtitle =>
      'Wählen Sie ein erkanntes serielles Gerät aus und verbinden Sie es direkt mit Ihrem MeshCore-Knoten.';

  @override
  String get usbScreenStatus => 'Wählen Sie ein USB-Gerät aus';

  @override
  String get usbScreenNote =>
      'USB-Seriell ist auf unterstützten Android-Geräten und Desktop-Plattformen verfügbar.';

  @override
  String get usbScreenEmptyState =>
      'Keine USB-Geräte gefunden. Schließen Sie eines an und aktualisieren Sie.';

  @override
  String get usbErrorPermissionDenied =>
      'Die USB-Berechtigung wurde abgelehnt.';

  @override
  String get usbErrorDeviceMissing =>
      'Das ausgewählte USB-Gerät ist nicht mehr verfügbar.';

  @override
  String get usbErrorInvalidPort => 'Wählen Sie ein gültiges USB-Gerät aus.';

  @override
  String get usbErrorBusy =>
      'Eine weitere Anfrage für eine USB-Verbindung ist bereits in Bearbeitung.';

  @override
  String get usbErrorNotConnected => 'Es ist kein USB-Gerät angeschlossen.';

  @override
  String get usbErrorOpenFailed =>
      'Das ausgewählte USB-Gerät konnte nicht geöffnet werden.';

  @override
  String get usbErrorConnectFailed =>
      'Mit dem ausgewählten USB-Gerät konnte keine Verbindung hergestellt werden.';

  @override
  String get usbErrorUnsupported =>
      'USB-Seriell wird auf dieser Plattform nicht unterstützt.';

  @override
  String get usbErrorAlreadyActive =>
      'Eine USB-Verbindung ist bereits hergestellt.';

  @override
  String get usbErrorNoDeviceSelected => 'Kein USB-Gerät wurde ausgewählt.';

  @override
  String get usbErrorPortClosed => 'Die USB-Verbindung ist nicht aktiv.';

  @override
  String get usbErrorConnectTimedOut =>
      'Verbindung konnte nicht hergestellt werden. Stellen Sie sicher, dass das Gerät über USB-Companion-Firmware verfügt.';

  @override
  String get usbFallbackDeviceName => 'Web-Serial-Gerät';

  @override
  String get usbStatus_notConnected => 'Wählen Sie ein USB-Gerät aus';

  @override
  String get usbStatus_connecting =>
      'Verbindung zum USB-Gerät wird hergestellt...';

  @override
  String get usbStatus_searching => 'Suche nach USB-Geräten...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB-Verbindung fehlgeschlagen: $error';
  }

  @override
  String get scanner_scanning => 'Suche nach Geräten...';

  @override
  String get scanner_connecting => 'Verbinde...';

  @override
  String get scanner_disconnecting => 'Trenne...';

  @override
  String get scanner_notConnected => 'Nicht verbunden';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Verbunden mit $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Suche nach MeshCore-Geräten...';

  @override
  String get scanner_tapToScan =>
      'Tippen Sie auf Scannen, um MeshCore-Geräte zu finden.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String get scanner_stop => 'Stopp';

  @override
  String get scanner_scan => 'Scannen';

  @override
  String get scanner_bluetoothOff => 'Bluetooth ist deaktiviert.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Bitte aktivieren Sie Bluetooth, um nach Geräten zu suchen.';

  @override
  String get scanner_chromeRequired => 'Chrome Browser erforderlich';

  @override
  String get scanner_chromeRequiredMessage =>
      'Diese Webanwendung erfordert Google Chrome oder einen Chromium-basierten Browser für die Bluetooth-Unterstützung.';

  @override
  String get scanner_enableBluetooth => 'Bluetooth aktivieren';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'Bluetooth ist im Browser nicht verfügbar. Verwenden Sie stattdessen eine USB-Verbindung.';

  @override
  String get device_quickSwitch => 'Schnellwechsel';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Einstellungen';

  @override
  String get settings_deviceInfo => 'Geräteinformationen';

  @override
  String get settings_appSettings => 'App-Einstellungen';

  @override
  String get settings_appSettingsSubtitle =>
      'Benachrichtigungen, Nachrichten und Karten-Einstellungen';

  @override
  String get settings_nodeSettings => 'Knoteneinstellungen';

  @override
  String get settings_nodeName => 'Knotenname';

  @override
  String get settings_nodeNameNotSet => 'Nicht festgelegt';

  @override
  String get settings_nodeNameHint => 'Geben Sie den Knotennamen ein';

  @override
  String get settings_nodeNameUpdated => 'Name aktualisiert';

  @override
  String get settings_radioSettings => 'Funk-Einstellungen';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequenz, Leistung, Spreading-Faktor';

  @override
  String get settings_radioSettingsUpdated => 'Funkparameter aktualisiert';

  @override
  String get settings_regionSettings => 'Regionen';

  @override
  String get settings_regionSettingsSubtitle =>
      'Gespeicherte Regionen verwalten';

  @override
  String get settings_regionManagement_screenTitle => 'Regions-Verwaltung';

  @override
  String get settings_regionNameHint => 'Regions-Namen eingeben';

  @override
  String get settings_regionAddRegion => 'Region hinzufügen';

  @override
  String get settings_regionFetchRegions => 'Fetch regions from repeaters';

  @override
  String get settings_regionFetchRegionsFail => 'No regions were found';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'This region has already been added';

  @override
  String get settings_regionName => 'Regions-Name';

  @override
  String get settings_regionDeleted => 'Region entfernt';

  @override
  String get settings_deleteRegion => 'Region entfernen';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Region \"$region\" aus der Liste entfernen?';
  }

  @override
  String get settings_location => 'Ort';

  @override
  String get settings_locationSubtitle => 'GPS-Koordinaten';

  @override
  String get settings_locationUpdated =>
      'Standort und GPS-Einstellungen aktualisiert';

  @override
  String get settings_locationBothRequired =>
      'Bitte geben Sie sowohl Breiten- als auch Längengrad ein.';

  @override
  String get settings_locationInvalid => 'Ungültiger Breiten- oder Längengrad.';

  @override
  String get settings_locationGPSEnable => 'GPS aktivieren';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Ermöglicht GPS, den Standort automatisch zu aktualisieren.';

  @override
  String get settings_locationIntervalSec => 'GPS-Intervall (Sekunden)';

  @override
  String get settings_locationIntervalInvalid =>
      'Das Intervall muss mindestens 60 Sekunden und weniger als 86400 Sekunden betragen.';

  @override
  String get settings_latitude => 'Breitengrad';

  @override
  String get settings_longitude => 'Längengrad';

  @override
  String get settings_contactSettings => 'Kontakteinstellungen';

  @override
  String get settings_contactSettingsSubtitle =>
      'Einstellungen für das Hinzufügen von Kontakten';

  @override
  String get settings_privacyMode => 'Privatsphärenmodus';

  @override
  String get settings_privacyModeSubtitle =>
      'Name und Standort in Ankündigungen verbergen';

  @override
  String get settings_privacyModeToggle =>
      'Privatsphärenmodus aktivieren, um Namen und Standort in Ankündigungen zu verbergen.';

  @override
  String get settings_privacyModeEnabled => 'Privatsphärenmodus aktiviert';

  @override
  String get settings_privacyModeDisabled => 'Privatsphärenmodus deaktiviert';

  @override
  String get settings_privacy => 'Datenschutzeinstellungen';

  @override
  String get settings_privacySubtitle =>
      'Steuern Sie, welche Informationen freigegeben werden.';

  @override
  String get settings_privacySettingsDescription =>
      'Wählen Sie aus, welche Informationen Ihr Gerät mit anderen teilt.';

  @override
  String get settings_denyAll => 'Alles verweigern';

  @override
  String get settings_allowByContact => 'Nach Kontakt-Flags zulassen';

  @override
  String get settings_allowAll => 'Alles zulassen';

  @override
  String get settings_telemetryBaseMode => 'Telemetrie-Basismodus';

  @override
  String get settings_telemetryLocationMode => 'Telemetrie-Standortmodus';

  @override
  String get settings_telemetryEnvironmentMode => 'Telemetrie-Umgebungsmodus';

  @override
  String get settings_advertLocation => 'Standort in Ankündigung';

  @override
  String get settings_advertLocationSubtitle =>
      'Standort in die Ankündigung einschließen.';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Automatische Zero-Hop-Ankündigung bei GPS-Update';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Wenn sich der GPS-Standort ändert, eine Zero-Hop-Ankündigung senden (erfordert Standort in der Ankündigung).';

  @override
  String get settings_multiAck => 'Mehrfach-ACKs';

  @override
  String get settings_telemetryModeUpdated => 'Telemetriemodus aktualisiert';

  @override
  String get settings_actions => 'Aktionen';

  @override
  String get settings_deleteAllPaths => 'Alle Pfade löschen';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Alle Pfaddaten aus den Kontakten entfernen.';

  @override
  String get settings_sendAdvertisement => 'Ankündigung senden';

  @override
  String get settings_sendAdvertisementSubtitle => 'Präsenz jetzt senden';

  @override
  String get settings_advertisementSent => 'Ankündigung gesendet';

  @override
  String get settings_syncTime => 'Zeit synchronisieren';

  @override
  String get settings_syncTimeSubtitle =>
      'Geräteuhr auf die Zeit des Telefons setzen';

  @override
  String get settings_timeSynchronized => 'Zeit synchronisiert';

  @override
  String get settings_refreshContacts => 'Kontakte aktualisieren';

  @override
  String get settings_refreshContactsSubtitle =>
      'Kontaktliste vom Gerät neu laden';

  @override
  String get settings_rebootDevice => 'Gerät neu starten';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore-Gerät neu starten';

  @override
  String get settings_rebootDeviceConfirm =>
      'Sind Sie sicher, dass Sie das Gerät neu starten möchten? Sie werden getrennt.';

  @override
  String get settings_debug => 'Fehlerbehebung';

  @override
  String get settings_companionDebugLog =>
      'Debug-Protokoll für die Begleitsoftware';

  @override
  String get settings_companionDebugLogSubtitle =>
      'BLE/TCP/USB-Befehle, Antworten und Rohdaten';

  @override
  String get settings_appDebugLog => 'App-Debug-Protokoll';

  @override
  String get settings_appDebugLogSubtitle => 'App-Debug-Nachrichten';

  @override
  String get settings_about => 'Über';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore Open-Source-Projekt';

  @override
  String get settings_aboutDescription =>
      'Ein Open-Source-Flutter-Client für MeshCore LoRa-Meshnetzwerkgeräte.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS-Höhendaten: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Name';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Akku';

  @override
  String get settings_infoPublicKey => 'Öffentlicher Schlüssel';

  @override
  String get settings_infoContactsCount => 'Kontakte';

  @override
  String get settings_infoChannelCount => 'Kanäle';

  @override
  String get settings_presets => 'Voreinstellungen';

  @override
  String get settings_frequency => 'Frequenz (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Ungültige Frequenz (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bandbreite';

  @override
  String get settings_spreadingFactor => 'Spreading-Faktor';

  @override
  String get settings_codingRate => 'Kodierungsrate';

  @override
  String get settings_txPower => 'Sendeleistung (dBm)';

  @override
  String get settings_txPowerHelper => '0 – 22';

  @override
  String get settings_txPowerInvalid => 'Ungültige Sendeleistung (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Weiterleitung ohne Netzstrom';

  @override
  String get settings_clientRepeatSubtitle =>
      'Dieses Gerät kann Mesh-Pakete für andere weiterleiten';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Weiterleitung ohne Netzstrom erfordert 433, 869 oder 918 MHz';

  @override
  String settings_error(String message) {
    return 'Fehler: $message';
  }

  @override
  String get appSettings_title => 'App-Einstellungen';

  @override
  String get appSettings_appearance => 'Erscheinungsbild';

  @override
  String get appSettings_theme => 'Design';

  @override
  String get appSettings_themeSystem => 'Systemstandard';

  @override
  String get appSettings_themeLight => 'Hell';

  @override
  String get appSettings_themeDark => 'Dunkel';

  @override
  String get appSettings_language => 'Sprache';

  @override
  String get appSettings_languageSystem => 'Systemstandard';

  @override
  String get appSettings_languageEn => 'Englisch';

  @override
  String get appSettings_languageFr => 'Französisch';

  @override
  String get appSettings_languageEs => 'Spanisch';

  @override
  String get appSettings_languageDe => 'Deutsch';

  @override
  String get appSettings_languagePl => 'Polnisch';

  @override
  String get appSettings_languageSl => 'Slowenisch';

  @override
  String get appSettings_languagePt => 'Portugiesisch';

  @override
  String get appSettings_languageIt => 'Italienisch';

  @override
  String get appSettings_languageZh => 'Chinesisch';

  @override
  String get appSettings_languageSv => 'Schwedisch';

  @override
  String get appSettings_languageNl => 'Niederländisch';

  @override
  String get appSettings_languageSk => 'Slowakisch';

  @override
  String get appSettings_languageBg => 'Bulgarisch';

  @override
  String get appSettings_languageRu => 'Russisch';

  @override
  String get appSettings_languageUk => 'Ukrainisch';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 byte';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 bytes';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 bytes';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 bytes';

  @override
  String get appSettings_enableMessageTracing =>
      'Nachrichtenverfolgung aktivieren';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Detaillierte Routing- und Zeitmetadaten für Nachrichten anzeigen';

  @override
  String get appSettings_notifications => 'Benachrichtigungen';

  @override
  String get appSettings_enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Benachrichtigungen für Nachrichten und Ankündigungen erhalten';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Benachrichtigungsberechtigung verweigert';

  @override
  String get appSettings_notificationsEnabled => 'Benachrichtigungen aktiviert';

  @override
  String get appSettings_notificationsDisabled =>
      'Benachrichtigungen deaktiviert';

  @override
  String get appSettings_messageNotifications =>
      'Direktnachrichten-Benachrichtigungen';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Benachrichtigung anzeigen, wenn neue Direktnachrichten eingehen';

  @override
  String get appSettings_channelMessageNotifications =>
      'Kanalnachrichten-Benachrichtigungen';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Benachrichtigung anzeigen, wenn neue Kanalnachrichten eingehen';

  @override
  String get appSettings_advertisementNotifications =>
      'Ankündigungsbenachrichtigungen';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Benachrichtigung anzeigen, wenn neue Knoten entdeckt werden';

  @override
  String get appSettings_messaging => 'Nachrichten';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Pfad bei maximalen Wiederholungsversuchen löschen';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Kontaktpfade nach 5 fehlgeschlagenen Sendeversuchen zurücksetzen';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Pfade werden nach 5 fehlgeschlagenen Wiederholungen gelöscht.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Pfade werden nicht automatisch gelöscht.';

  @override
  String get appSettings_autoRouteRotation => 'Automatische Routenrotation';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Zwischen den besten Pfaden und dem Flood-Modus wechseln';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Automatische Routenrotation aktiviert';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Automatische Routenrotation deaktiviert';

  @override
  String get appSettings_maxRouteWeight => 'Maximale Gesamtstreckenlänge';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Maximales Gewicht, das ein Weg durch erfolgreiche Lieferungen erreichen kann.';

  @override
  String get appSettings_initialRouteWeight => 'Anfangs-Streckengewicht';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Ausgangsgewicht für neu entdeckte Pfade';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Erhöhung des Erfolgsgewichts';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Gewicht, das einem Pfad nach erfolgreicher Lieferung hinzugefügt wird.';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Reduzierung des Gewichts bei Fehlern';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Gewicht, das nach einem fehlgeschlagenen Versand von einem Weg entfernt wurde';

  @override
  String get appSettings_maxMessageRetries =>
      'Maximale Anzahl an Wiederholungsversuchen';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Anzahl der Versuche, eine Nachricht erneut zu senden, bevor sie als fehlgeschlagen markiert wird.';

  @override
  String get appSettings_battery => 'Akku';

  @override
  String get appSettings_batteryChemistry => 'Batteriechemie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Pro Gerät festgelegt ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Zum Auswählen mit einem Gerät verbinden';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0–4,2 V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0–4,2V)';

  @override
  String get appSettings_mapDisplay => 'Kartendarstellung';

  @override
  String get appSettings_showRepeaters => 'Repeater anzeigen';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Repeater-Knoten auf der Karte anzeigen';

  @override
  String get appSettings_showChatNodes => 'Chat-Knoten anzeigen';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Chat-Knoten auf der Karte anzeigen';

  @override
  String get appSettings_showOtherNodes => 'Andere Knoten anzeigen';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Andere Knotentypen auf der Karte anzeigen';

  @override
  String get appSettings_timeFilter => 'Zeitfilter';

  @override
  String get appSettings_timeFilterShowAll => 'Alle Knoten anzeigen';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Knoten der letzten $hours Stunden anzeigen';
  }

  @override
  String get appSettings_mapTimeFilter => 'Karten-Zeitfilter';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Zeige Knoten, die innerhalb von:';

  @override
  String get appSettings_allTime => 'Gesamter Zeitraum';

  @override
  String get appSettings_lastHour => 'Letzte Stunde';

  @override
  String get appSettings_last6Hours => 'Letzte 6 Stunden';

  @override
  String get appSettings_last24Hours => 'Letzte 24 Stunden';

  @override
  String get appSettings_lastWeek => 'Letzte Woche';

  @override
  String get appSettings_rasterTileSource => 'Quelle für Rasterkacheln';

  @override
  String get appSettings_stadiaEndpoint => 'Stadia-Endpunkt';

  @override
  String get appSettings_stadiaApiKey => 'Stadia-API-Schlüssel';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Für die Nutzung von Stadia Maps erforderlich';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Konfiguriert: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Geben Sie Ihren Stadia-Maps-API-Schlüssel ein. Die App verwendet ihn für Rasterkachel-Anfragen.';

  @override
  String get appSettings_offlineMapCache => 'Offline-Karten-Cache';

  @override
  String get appSettings_unitsTitle => 'Einheiten';

  @override
  String get appSettings_unitsMetric => 'Metrisch (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (ft/mi)';

  @override
  String get appSettings_noAreaSelected => 'Kein Bereich ausgewählt';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Bereich ausgewählt (Zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Debug';

  @override
  String get appSettings_appDebugLogging => 'App-Debug-Protokollierung';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'App-Debug-Nachrichten zur Fehlerbehebung protokollieren';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'App-Debug-Protokollierung aktiviert';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'App-Debug-Protokollierung deaktiviert';

  @override
  String get contacts_title => 'Kontakte';

  @override
  String get contacts_noContacts => 'Noch keine Kontakte';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakte werden angezeigt, wenn Geräte Ankündigungen senden.';

  @override
  String get contacts_unread => 'Ungelesen';

  @override
  String get contacts_searchContactsNoNumber => 'Kontakte suchen...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Kontakte suchen...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Suche $number$str Favoriten...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Suche $number$str Benutzer...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Suche $number$str Repeater...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Suche $number$str Raumserver...';
  }

  @override
  String get contacts_noUnreadContacts => 'Keine ungelesenen Kontakte';

  @override
  String get contacts_noContactsFound =>
      'Keine Kontakte oder Gruppen gefunden.';

  @override
  String get contacts_storageFull =>
      'Contact storage on the node is full. New nodes cannot be added until contacts are removed.';

  @override
  String get contacts_deleteContact => 'Kontakt löschen';

  @override
  String contacts_removeConfirm(String contactName) {
    return '$contactName aus den Kontakten entfernen?';
  }

  @override
  String get contacts_manageRepeater => 'Repeater verwalten';

  @override
  String get contacts_manageRoom => 'Raumserver verwalten';

  @override
  String get contacts_roomLogin => 'Raumserver-Login';

  @override
  String get contacts_openChat => 'Chat öffnen';

  @override
  String get contacts_editGroup => 'Gruppe bearbeiten';

  @override
  String get contacts_deleteGroup => 'Gruppe löschen';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Gruppe \"$groupName\" löschen?';
  }

  @override
  String get contacts_newGroup => 'Neue Gruppe';

  @override
  String get contacts_moreOptions => 'Weitere Optionen';

  @override
  String get contacts_searchOpen => 'Suche öffnen';

  @override
  String get contacts_searchClose => 'Suche schließen';

  @override
  String get contacts_groupName => 'Gruppenname';

  @override
  String get contacts_groupNameRequired => 'Der Gruppenname ist erforderlich.';

  @override
  String get contacts_groupNameReserved => 'Dieser Gruppenname ist reserviert';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Die Gruppe \"$name\" existiert bereits.';
  }

  @override
  String get contacts_filterContacts => 'Kontakte filtern...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Keine Kontakte passen zu Ihrem Filter';

  @override
  String get contacts_noMembers => 'Keine Mitglieder';

  @override
  String get contacts_lastSeenNow => 'gerade eben';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes Min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 Std.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours Std.';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 Tag';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days Tage';
  }

  @override
  String get contact_info => 'Kontaktinformationen';

  @override
  String get contact_settings => 'Kontakteinstellungen';

  @override
  String get contact_telemetry => 'Telemetrie';

  @override
  String get contact_lastSeen => 'Zuletzt gesehen';

  @override
  String get contact_clearChat => 'Chat löschen';

  @override
  String get contact_teleBase => 'Telemetriebasis';

  @override
  String get contact_teleBaseSubtitle =>
      'Erlauben des Freigebens des Batteriestands und der grundlegenden Telemetrie';

  @override
  String get contact_teleLoc => 'Telemetrieort';

  @override
  String get contact_teleLocSubtitle => 'Teilen von Standortdaten zulassen';

  @override
  String get contact_teleEnv => 'Telemetrieumgebung';

  @override
  String get contact_teleEnvSubtitle =>
      'Teilen von Umgebungsensordaten zulassen';

  @override
  String get channels_title => 'Kanäle';

  @override
  String get channels_noChannelsConfigured => 'Keine Kanäle konfiguriert';

  @override
  String get channels_addPublicChannel => 'Öffentlichen Kanal hinzufügen';

  @override
  String get channels_searchChannels => 'Kanäle suchen...';

  @override
  String get channels_noChannelsFound => 'Keine Kanäle gefunden';

  @override
  String channels_channelIndex(int index) {
    return 'Kanal $index';
  }

  @override
  String get channels_public => 'Öffentlich';

  @override
  String channels_via(String path) {
    return 'über $path';
  }

  @override
  String get channels_private => 'Privat';

  @override
  String get channels_editChannel => 'Kanal bearbeiten';

  @override
  String get channels_muteChannel => 'Kanal stummschalten';

  @override
  String get channels_unmuteChannel => 'Kanal Stummschaltung aufheben';

  @override
  String get channels_deleteChannel => 'Kanal löschen';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Kanal \"$name\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanal $name konnte nicht gelöscht werden';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanal \"$name\" gelöscht';
  }

  @override
  String get channels_addChannel => 'Kanal hinzufügen';

  @override
  String get channels_channelIndexLabel => 'Kanalindex';

  @override
  String get channels_channelName => 'Kanalname';

  @override
  String get channels_usePublicChannel => 'Öffentlichen Kanal verwenden';

  @override
  String get channels_standardPublicPsk => 'Öffentlicher Standard-PSK';

  @override
  String get channels_pskHex => 'PSK (Hexadezimal)';

  @override
  String get channels_generateRandomPsk => 'Zufälligen PSK generieren';

  @override
  String get channels_enterChannelName =>
      'Bitte geben Sie einen Kanalnamen ein';

  @override
  String get channels_pskMustBe32Hex =>
      'Der PSK muss 32 hexadezimale Zeichen haben.';

  @override
  String channels_channelAdded(String name) {
    return 'Kanal \"$name\" hinzugefügt';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Kanal $index bearbeiten';
  }

  @override
  String get channels_smazCompression => 'SMAZ-Komprimierung';

  @override
  String get channels_cyr2latCompression => 'Cyr2Lat-Komprimierung';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Ersetzt beim Senden einige kyrillische Zeichen durch lateinische Zeichen.';

  @override
  String get channels_cyr2latSettingsHeading => 'Cyr2Lat-Einstellungen';

  @override
  String get channels_cyr2latSettingsSubheading => 'Ersetzungsliste';

  @override
  String get channels_cyr2latSettingsDscr =>
      'JSON-Konfiguration für Zeichenersetzungen bearbeiten';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON-Ersetzungstabelle';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'Ungültiges JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Kanal \"$name\" aktualisiert';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Cyr2Lat-Profil hinzufügen';

  @override
  String get settings_cyr2latProfileName => 'Profilname';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'Der Profilname darf nicht leer sein';

  @override
  String get settings_cyr2latProfileAdded => 'Profil erfolgreich hinzugefügt';

  @override
  String get settings_cyr2latProfileUpdated =>
      'Profil erfolgreich aktualisiert';

  @override
  String get settings_cyr2latProfileEdit => 'Cyr2Lat-Profil bearbeiten';

  @override
  String get settings_cyr2latProfileDelete => 'Cyr2Lat-Profil löschen';

  @override
  String get settings_cyr2latProfileDeleted => 'Profil erfolgreich gelöscht';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Möchten Sie das Profil \"$name\" wirklich löschen?';
  }

  @override
  String get channels_publicChannelAdded => 'Öffentlicher Kanal hinzugefügt';

  @override
  String get channels_sortBy => 'Sortieren nach';

  @override
  String get channels_sortManual => 'Manuell';

  @override
  String get channels_sortAZ => 'A bis Z';

  @override
  String get channels_sortLatestMessages => 'Neueste Nachrichten';

  @override
  String get channels_sortUnread => 'Ungelesen';

  @override
  String get channels_createPrivateChannel => 'Erstelle einen privaten Kanal';

  @override
  String get channels_createPrivateChannelDesc =>
      'Verschlüsselt mit einem geheimen Schlüssel.';

  @override
  String get channels_joinPrivateChannel =>
      'Treten Sie einem privaten Kanal bei';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Manuelle Eingabe eines geheimen Schlüssels.';

  @override
  String get channels_joinPublicChannel => 'Tritt dem öffentlichen Kanal bei';

  @override
  String get channels_joinPublicChannelDesc =>
      'Jeder kann diesem Kanal beitreten.';

  @override
  String get channels_joinHashtagChannel =>
      'Treten Sie einem Hashtag-Kanal bei';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Jeder kann sich bei Hashtag-Kanälen beteiligen.';

  @override
  String get channels_scanQrCode => 'Scannen Sie einen QR-Code';

  @override
  String get channels_scanQrCodeComingSoon => 'Bald verfügbar';

  @override
  String get channels_enterHashtag => 'Gib Hashtag ein';

  @override
  String get channels_hashtagHint => 'z.B. #team';

  @override
  String channels_regionSetTo(String region) {
    return 'Region: $region';
  }

  @override
  String get channels_regionNotSet => 'Region: keine';

  @override
  String get channels_regionSelect_Title => 'Region auswählen';

  @override
  String get channels_clearRegion => 'Region zurücksetzen';

  @override
  String get chat_noMessages => 'Noch keine Nachrichten.';

  @override
  String get chat_sendMessage => 'Nachricht senden';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Nachricht an $contactName senden';
  }

  @override
  String get chat_sendMessageToStart =>
      'Senden Sie eine Nachricht, um zu beginnen.';

  @override
  String get chat_originalMessageNotFound => 'Originalnachricht nicht gefunden';

  @override
  String chat_replyingTo(String name) {
    return 'Antworten an $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Antwort an $name';
  }

  @override
  String get chat_location => 'Ort';

  @override
  String get chat_typeMessage => 'Nachricht eingeben...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Nachricht zu lang (max. $maxBytes Bytes).';
  }

  @override
  String get chat_messageCopied => 'Nachricht kopiert';

  @override
  String get chat_messageDeleted => 'Nachricht gelöscht';

  @override
  String get chat_retryingMessage => 'Nachricht wird erneut gesendet.';

  @override
  String chat_retryCount(int current, int max) {
    return 'Wiederholen $current/$max';
  }

  @override
  String get chat_sendGif => 'GIF senden';

  @override
  String get chat_receivedGif => 'Received a GIF';

  @override
  String get chat_reply => 'Antworten';

  @override
  String get chat_addReaction => 'Reaktion hinzufügen';

  @override
  String get chat_me => 'Ich';

  @override
  String get emojiCategorySmileys => 'Emoticons';

  @override
  String get emojiCategoryGestures => 'Gesten';

  @override
  String get emojiCategoryHearts => 'Herz';

  @override
  String get emojiCategoryObjects => 'Objekte';

  @override
  String get gifPicker_title => 'Wähle ein GIF';

  @override
  String get gifPicker_searchHint => 'Suche nach GIFs...';

  @override
  String get gifPicker_poweredBy => 'Bereitgestellt von GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Keine GIFs gefunden';

  @override
  String get gifPicker_failedLoad => 'GIF-Datei konnten nicht geladen werden.';

  @override
  String get gifPicker_failedSearch => 'Suche nach GIFs fehlgeschlagen';

  @override
  String get gifPicker_noInternet => 'Keine Internetverbindung';

  @override
  String get debugLog_appTitle => 'App-Debug-Protokoll';

  @override
  String get debugLog_bleTitle => 'BLE-Debug-Protokoll';

  @override
  String get debugLog_copyLog => 'Kopieren des Protokolls';

  @override
  String get debugLog_clearLog => 'Protokoll löschen';

  @override
  String get debugLog_copied => 'Debug-Protokoll kopiert';

  @override
  String get debugLog_bleCopied => 'BLE-Protokoll kopiert';

  @override
  String get debugLog_noEntries => 'Noch keine Debug-Protokolle vorhanden';

  @override
  String get debugLog_enableInSettings =>
      'App-Debug-Protokollierung in den Einstellungen aktivieren';

  @override
  String get debugLog_frames => 'Rahmen';

  @override
  String get debugLog_rawLogRx => 'Roh-Log-RX';

  @override
  String get debugLog_noBleActivity => 'Bisher keine BLE-Aktivität';

  @override
  String debugFrame_length(int count) {
    return 'Rahmenlänge: $count Bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Befehl: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Textnachrichten Frame:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Ziel-Public-Schlüssel: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Zeitstempel: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flaggen: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Textart: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'Befehlszeilen-Schnittstelle';

  @override
  String get debugFrame_textTypePlain => 'Einfach';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex-Dump:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprünge',
      one: 'Sprung',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Pfad entfernen';

  @override
  String get chat_noPathHistoryYet =>
      'Keine Pfadhistorie vorhanden.\nSende eine Nachricht, um Pfade zu entdecken.';

  @override
  String get chat_pathCleared =>
      'Pfad zurückgesetzt. Nächste Nachricht wird Route neu entdecken.';

  @override
  String get chat_fullPath => 'Vollständiger Pfad';

  @override
  String get routing_title => 'Routenplanung';

  @override
  String get routing_modeAuto => 'Automatisch';

  @override
  String get routing_modeFlood => 'Flut';

  @override
  String get routing_modeManual => 'Manuell';

  @override
  String get routing_modeAutoHint =>
      'Wählt automatisch den besten bekannten Pfad und wechselt auf Flut, wenn keiner bekannt ist.';

  @override
  String get routing_modeFloodHint =>
      'Über alle Repeater senden. Am zuverlässigsten, aber mit höherem Funkzeitbedarf.';

  @override
  String get routing_modeManualHint =>
      'Sendet immer genau den von Ihnen festgelegten Pfad.';

  @override
  String get routing_currentRoute => 'Aktuelle Route';

  @override
  String get routing_directNoHops => 'Direkt - keine Repeater-Sprünge';

  @override
  String get routing_noPathYet =>
      'Noch kein Pfad gefunden. Die nächste Nachricht wird geflutet, bis eine Route entdeckt ist.';

  @override
  String get routing_floodBroadcast => 'Über alle Repeater senden';

  @override
  String get routing_editPath => 'Pfad bearbeiten';

  @override
  String get routing_forgetPath => 'Pfad vergessen';

  @override
  String get routing_knownPaths => 'Bekannte Pfade';

  @override
  String get routing_knownPathsHint =>
      'Tippen Sie auf einen Pfad, um zu ihm zu wechseln.';

  @override
  String get routing_inUse => 'In Verwendung';

  @override
  String get routing_qualityStrong => 'Starker erster Hop';

  @override
  String get routing_qualityGood => 'Guter erster Hop';

  @override
  String get routing_qualityFair => 'Ausreichender erster Hop';

  @override
  String get routing_qualityWorked => 'Hat zugestellt';

  @override
  String get routing_qualityFlood => 'Per Flood gehört';

  @override
  String get routing_qualityUntested => 'Nicht getestet';

  @override
  String routing_lastWorked(String when) {
    return 'funktionierte $when';
  }

  @override
  String get routing_neverWorked => 'nie bestätigt';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes zugestellt, $failures fehlgeschlagen';
  }

  @override
  String get routing_floodDelivery => 'Flood-Zustellung';

  @override
  String get pathEditor_title => 'Pfad erstellen';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count von 64 Sprüngen';
  }

  @override
  String get pathEditor_noHops =>
      'Noch keine Sprünge hinzugefügt. Tippen Sie unten auf Repeater, um sie in Reihenfolge hinzuzufügen, oder speichern Sie ohne Sprünge, um direkt zu senden.';

  @override
  String get pathEditor_addHops => 'Sprünge in Reihenfolge hinzufügen';

  @override
  String get pathEditor_searchRepeaters => 'Repeater suchen';

  @override
  String get pathEditor_advancedHex => 'Erweitert: roher Hex-Pfad';

  @override
  String get pathEditor_hexLabel => 'Hex-Präfixe';

  @override
  String get pathEditor_hexHelper =>
      'Zwei Hex-Zeichen pro Sprung, durch Kommas getrennt';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Ungültig: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Maximal 64 Sprünge';

  @override
  String get pathEditor_usePath => 'Diesen Pfad verwenden';

  @override
  String get pathEditor_removeHop => 'Sprung entfernen';

  @override
  String get pathEditor_unknownHop => 'Unbekannter Repeater';

  @override
  String get chat_pathSavedLocally =>
      'Lokal Gespeichert. Bitte Verbinden zum Synchronisieren.';

  @override
  String get chat_pathDeviceConfirmed => 'Gerät bestätigt.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Gerät noch nicht bestätigt.';

  @override
  String get chat_type => 'Gebe ein';

  @override
  String get chat_path => 'Pfad';

  @override
  String get chat_publicKey => 'Öffentlicher Schlüssel';

  @override
  String get chat_compressOutgoingMessages =>
      'Komprimieren ausgehender Nachrichten';

  @override
  String get chat_floodForced => 'Geflutet (erzwungen)';

  @override
  String get chat_directForced => 'Direkt (erzwungen)';

  @override
  String chat_hopsForced(int count) {
    return '$count Sprünge (erzwungen)';
  }

  @override
  String get chat_floodAuto => 'Geflutet (automatisch)';

  @override
  String get chat_direct => 'Direkt';

  @override
  String get chat_poiShared => 'Geteilter POI';

  @override
  String chat_unread(int count) {
    return 'Ungelesen: $count';
  }

  @override
  String get chat_markAsUnread => 'Als ungelesen markieren';

  @override
  String get chat_newMessages => 'Neue Nachrichten';

  @override
  String get chat_openLink => 'Link öffnen?';

  @override
  String get chat_openLinkConfirmation =>
      'Möchten Sie diesen Link in Ihrem Browser öffnen?';

  @override
  String get chat_open => 'Öffnen';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Link konnte nicht geöffnet werden: $url';
  }

  @override
  String get chat_invalidLink => 'Ungültiges Link-Format';

  @override
  String get map_title => 'Karte';

  @override
  String get map_searchHint => 'Nach Knotenname oder ID suchen';

  @override
  String get map_activity => 'Aktivität';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Kürzlich';

  @override
  String get map_stale => 'Veraltet';

  @override
  String get map_visible => 'Sichtbar';

  @override
  String get map_hidden => 'Versteckt';

  @override
  String get map_centerOnNode => 'Auf Knoten zentrieren';

  @override
  String get map_details => 'Details';

  @override
  String get map_noGps => 'Kein GPS';

  @override
  String get map_noResults => 'Keine passenden Knoten gefunden';

  @override
  String get map_lineOfSight => 'Sichtlinie';

  @override
  String get map_losScreenTitle => 'Sichtlinie';

  @override
  String get map_noNodesWithLocation => 'Keine Knoten mit Standortdaten';

  @override
  String get map_nodesNeedGps =>
      'Knoten müssen ihre GPS-Koordinaten teilen,\num auf der Karte zu erscheinen.';

  @override
  String map_nodesCount(int count) {
    return 'Knoten: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Nadeln: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repeater';

  @override
  String get map_room => 'Raumserver';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (Kontakt)';

  @override
  String get map_pinPrivate => 'Pin (Channel)';

  @override
  String get map_pinPublic => 'Kennzeichnung (Öffentlich)';

  @override
  String get map_lastSeen => 'Zuletzt gesehen';

  @override
  String get map_disconnectConfirm =>
      'Sind Sie sicher, dass Sie sich von diesem Gerät trennen möchten?';

  @override
  String get map_from => 'Von';

  @override
  String get map_source => 'Quelle';

  @override
  String get map_flags => 'Flaggen';

  @override
  String get map_type => 'Typ';

  @override
  String get map_path => 'Pfad';

  @override
  String get map_location => 'Standort';

  @override
  String get map_estLocation => 'Geschätzter Standort';

  @override
  String get map_publicKey => 'Öffentlicher Schlüssel';

  @override
  String get map_publicKeyPrefixHint => 'z. B. ab12';

  @override
  String get map_shareMarkerHere => 'Marker hier teilen';

  @override
  String get map_setAsMyLocation => 'Als meine aktuelle Position festlegen';

  @override
  String get map_pinLabel => 'Pin-Beschriftung';

  @override
  String get map_label => 'Beschriftung';

  @override
  String get map_pointOfInterest => 'Punkt von Interesse';

  @override
  String get map_sendToContact => 'An Kontakt senden';

  @override
  String get map_sendToChannel => 'An Kanal senden';

  @override
  String get map_noChannelsAvailable => 'Keine Kanäle verfügbar';

  @override
  String get map_publicLocationShare => 'Öffentliche Standortfreigabe';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Sie sind dabei, einen Standort in $channelLabel zu teilen. Dieser Kanal ist öffentlich und jeder mit dem PSK kann ihn sehen.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Mit einem Gerät verbinden, um Marker zu teilen';

  @override
  String get map_filterNodes => 'Knoten filtern';

  @override
  String get map_nodeTypes => 'Knotentypen';

  @override
  String get map_chatNodes => 'Chat-Knoten';

  @override
  String get map_repeaters => 'Repeater';

  @override
  String get map_otherNodes => 'Andere Knoten';

  @override
  String get map_showOverlaps => 'Repeater-Schlüsselüberlappungen';

  @override
  String get map_keyPrefix => 'Schlüsselpräfix';

  @override
  String get map_filterByKeyPrefix => 'Nach Schlüsselpräfix filtern';

  @override
  String get map_publicKeyPrefix => 'Präfix des öffentlichen Schlüssels';

  @override
  String get map_markers => 'Marker';

  @override
  String get map_showSharedMarkers => 'Gemeinsam genutzte Marker anzeigen';

  @override
  String get map_showGuessedLocations => 'Vermutete Knotenstandorte anzeigen';

  @override
  String get map_showDiscoveryContacts => 'Entdeckte Kontakte anzeigen';

  @override
  String get map_guessedLocation => 'Vermuteter Standort';

  @override
  String get map_lastSeenTime => 'Letzte Sichtung';

  @override
  String get map_sharedPin => 'Gemeinsamer Pin';

  @override
  String get map_sharedAt => 'Geteilt am';

  @override
  String get map_joinRoom => 'Raum beitreten';

  @override
  String get map_manageRepeater => 'Repeater verwalten';

  @override
  String get map_tapToAdd =>
      'Tippen Sie auf Knoten, um sie zum Pfad hinzuzufügen.';

  @override
  String get map_runTrace => 'Pfadverlauf ausführen';

  @override
  String get map_runTraceWithReturnPath =>
      'Auf dem gleichen Pfad zurückkehren.';

  @override
  String get map_removeLast => 'Letztes entfernen';

  @override
  String get map_pathTraceCancelled => 'Pfadverfolgung abgebrochen.';

  @override
  String get mapCache_title => 'Offline-Karten-Cache';

  @override
  String get mapCache_selectAreaFirst =>
      'Wählen Sie zuerst einen Bereich zum Zwischenspeichern aus.';

  @override
  String get mapCache_noTilesToDownload =>
      'Keine Kacheln für diese Region zum Herunterladen verfügbar.';

  @override
  String get mapCache_downloadTilesTitle => 'Kacheln herunterladen';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return '$count Kacheln für die Offline-Nutzung herunterladen?';
  }

  @override
  String get mapCache_downloadAction => 'Herunterladen';

  @override
  String mapCache_cachedTiles(int count) {
    return '$count Kacheln zwischengespeichert';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return '$downloaded Kacheln zwischengespeichert ($failed fehlgeschlagen)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Offline-Cache leeren';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Alle zwischengespeicherten Kartenkacheln entfernen?';

  @override
  String get mapCache_offlineCacheCleared => 'Offline-Cache gelöscht';

  @override
  String get mapCache_noAreaSelected => 'Kein Bereich ausgewählt';

  @override
  String get mapCache_cacheArea => 'Bereich zwischenspeichern';

  @override
  String get mapCache_useCurrentView => 'Aktuelle Ansicht verwenden';

  @override
  String get mapCache_zoomRange => 'Zoombereich';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Geschätzte Kacheln: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Heruntergeladen $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Kacheln herunterladen';

  @override
  String get mapCache_clearCacheButton => 'Cache leeren';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Fehlgeschlagene Downloads: $count';
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
  String get time_justNow => 'Gerade eben';

  @override
  String time_minutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String time_hoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String time_daysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String get time_hour => 'Stunde';

  @override
  String get time_hours => 'Stunden';

  @override
  String get time_day => 'Tag';

  @override
  String get time_days => 'Tage';

  @override
  String get time_week => 'Woche';

  @override
  String get time_weeks => 'Wochen';

  @override
  String get time_month => 'Monat';

  @override
  String get time_months => 'Monate';

  @override
  String get time_minutes => 'Minuten';

  @override
  String get time_allTime => 'Ganzer Zeitraum';

  @override
  String get dialog_disconnect => 'Trennen';

  @override
  String get dialog_disconnectConfirm =>
      'Sind Sie sicher, dass Sie sich von diesem Gerät trennen möchten?';

  @override
  String get login_repeaterLogin => 'Beim Repeater anmelden';

  @override
  String get login_roomLogin => 'Raum-Login';

  @override
  String get login_password => 'Passwort';

  @override
  String get login_enterPassword => 'Passwort eingeben';

  @override
  String get login_savePassword => 'Passwort speichern';

  @override
  String get login_savePasswordSubtitle =>
      'Das Passwort wird auf diesem Gerät sicher gespeichert.';

  @override
  String get login_repeaterDescription =>
      'Geben Sie das Repeater-Passwort ein, um auf Einstellungen und Status zuzugreifen.';

  @override
  String get login_roomDescription =>
      'Geben Sie das Raumkennwort ein, um auf die Einstellungen und den Status zuzugreifen.';

  @override
  String get login_routing => 'Routen';

  @override
  String get login_routingMode => 'Routenmodus';

  @override
  String get login_autoUseSavedPath =>
      'Automatisch (gespeicherten Pfad verwenden)';

  @override
  String get login_forceFloodMode => 'Flut-Modus erzwingen';

  @override
  String get login_managePaths => 'Pfadverwaltung';

  @override
  String get login_login => 'Anmelden';

  @override
  String login_attempt(int current, int max) {
    return 'Versuche $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get login_failedMessage =>
      'Anmeldung fehlgeschlagen. Entweder ist das Passwort falsch oder der Repeater ist nicht erreichbar.';

  @override
  String get common_reload => 'Neu laden';

  @override
  String get common_clear => 'Leeren';

  @override
  String get path_currentPathLabel => 'Aktueller Pfad';

  @override
  String get path_noRepeatersFound =>
      'Keine Repeater oder Raumserver gefunden.';

  @override
  String get repeater_management => 'Repeater-Verwaltung';

  @override
  String get room_management => 'Raum-Server-Verwaltung';

  @override
  String get repeater_guest => 'Informationen zu Repeatern';

  @override
  String get room_guest => 'Informationen zum Room Server';

  @override
  String get repeater_managementTools => 'Verwaltungstools';

  @override
  String get repeater_guestTools => 'Gastwerkzeuge';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Repeater-Status, Statistiken und Nachbarn anzeigen';

  @override
  String get repeater_telemetry => 'Telemetrie';

  @override
  String get repeater_telemetrySubtitle =>
      'Telemetriedaten und Systemstatistiken anzeigen';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Befehle an den Repeater senden';

  @override
  String get repeater_neighbors => 'Nachbarn';

  @override
  String get repeater_neighborsSubtitle => 'Anzahl der Hop-Nachbarn anzeigen.';

  @override
  String get repeater_settings => 'Einstellungen';

  @override
  String get repeater_settingsSubtitle => 'Repeater-Parameter konfigurieren';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Uhrzeit-Synchronisation nach dem Anmelden';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatisch \"Uhrzeit-Synchronisierung\" nach erfolgreicher Anmeldung senden.';

  @override
  String get repeater_statusTitle => 'Repeater-Status';

  @override
  String get repeater_routingMode => 'Routing-Modus';

  @override
  String get repeater_refresh => 'Aktualisieren';

  @override
  String get repeater_statusRequestTimeout => 'Statusanfrage abgelaufen.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Fehler beim Laden des Status: $error';
  }

  @override
  String get repeater_systemInformation => 'Systeminformationen';

  @override
  String get repeater_battery => 'Akku';

  @override
  String get repeater_clockAtLogin => 'Uhr (bei Anmeldung)';

  @override
  String get repeater_uptime => 'Betriebszeit';

  @override
  String get repeater_queueLength => 'Warteschlangenlänge';

  @override
  String get repeater_debugFlags => 'Debug-Flags';

  @override
  String get repeater_radioStatistics => 'Funkstatistiken';

  @override
  String get repeater_lastRssi => 'Letzter RSSI';

  @override
  String get repeater_lastSnr => 'Letzter SNR';

  @override
  String get repeater_noiseFloor => 'Rauschpegel';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_chanUtil => 'Nutzung des Kanals';

  @override
  String get repeater_packetStatistics => 'Paketstatistiken';

  @override
  String get repeater_sent => 'Gesendet';

  @override
  String get repeater_received => 'Empfangen';

  @override
  String get repeater_duplicates => 'Duplikate';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days Tage ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Gesamt: $total, Flood: $flood, Direkt: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Gesamt: $total, Flood: $flood, Direkt: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Direkt: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Gesamt: $total';
  }

  @override
  String get repeater_settingsTitle => 'Repeater-Einstellungen';

  @override
  String get repeater_basicSettings => 'Grundeinstellungen';

  @override
  String get repeater_repeaterName => 'Repeatername';

  @override
  String get repeater_repeaterNameHelper => 'Anzeigename für diesen Repeater';

  @override
  String get repeater_adminPassword => 'Admin-Passwort';

  @override
  String get repeater_adminPasswordHelper => 'Passwort für Vollzugriff';

  @override
  String get repeater_guestPassword => 'Gast-Passwort';

  @override
  String get repeater_guestPasswordHelper => 'Passwort für Lesezugriff';

  @override
  String get repeater_radioSettings => 'Funk-Einstellungen';

  @override
  String get repeater_frequencyMhz => 'Frequenz (MHz)';

  @override
  String get repeater_frequencyHelper => '300–2500 MHz';

  @override
  String get repeater_txPower => 'Sendeleistung';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Bandbreite';

  @override
  String get repeater_spreadingFactor => 'Spreading-Faktor';

  @override
  String get repeater_codingRate => 'Kodierungsrate';

  @override
  String get repeater_locationSettings => 'Standorteinstellungen';

  @override
  String get repeater_latitude => 'Breitengrad';

  @override
  String get repeater_latitudeHelper => 'Dezimalgrad (z.B. 37,7749)';

  @override
  String get repeater_longitude => 'Längengrad';

  @override
  String get repeater_longitudeHelper => 'Dezimalgrad (z.B. -122,4194)';

  @override
  String get repeater_features => 'Funktionen';

  @override
  String get repeater_packetForwarding => 'Paketweiterleitung';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Den Repeater aktivieren, um Pakete weiterzuleiten';

  @override
  String get repeater_guestAccess => 'Gastzugriff';

  @override
  String get repeater_guestAccessSubtitle => 'Nur-Lese-Gastzugriff erlauben';

  @override
  String get repeater_privacyMode => 'Privatsphärenmodus';

  @override
  String get repeater_privacyModeSubtitle =>
      'Name und Standort in Ankündigungen verbergen';

  @override
  String get repeater_advertisementSettings => 'Ankündigungseinstellungen';

  @override
  String get repeater_localAdvertInterval => 'Lokales Ankündigungsintervall';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes Minuten';
  }

  @override
  String get repeater_floodAdvertInterval => 'Flood-Ankündigungsintervall';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours Stunden';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Verschlüsseltes Ankündigungsintervall';

  @override
  String get repeater_dangerZone => 'Gefahrenzone';

  @override
  String get repeater_rebootRepeater => 'Repeater neu starten';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Repeater-Gerät neu starten';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Sind Sie sicher, dass Sie diesen Repeater neu starten möchten?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Identitätsschlüssel neu erzeugen';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Neues öffentlich-privates Schlüsselpaar erzeugen';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Dies erzeugt eine neue Identität für den Repeater. Fortfahren?';

  @override
  String get repeater_eraseFileSystem => 'Dateisystem löschen';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Das Dateisystem des Repeaters formatieren';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'WARNUNG: Dies löscht alle Daten auf dem Repeater. Dies kann nicht rückgängig gemacht werden!';

  @override
  String get repeater_eraseSerialOnly =>
      'Löschen ist nur über die serielle Konsole verfügbar.';

  @override
  String repeater_commandSent(String command) {
    return 'Befehl gesendet: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Fehler beim Senden des Befehls: $error';
  }

  @override
  String get repeater_confirm => 'Bestätigen';

  @override
  String get repeater_settingsSaved => 'Einstellungen erfolgreich gespeichert';

  @override
  String get repeater_rxGain => 'Verstärkter RX-Gewinn';

  @override
  String get repeater_rxGainHelper =>
      'Höhere Empfindlichkeit, höherer Stromverbrauch (nur SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain => 'Verstärkten RX-Gewinn aktualisieren';

  @override
  String get repeater_multiAcks => 'Mehrfach-ACKs';

  @override
  String get repeater_multiAcksSubtitle =>
      'Nachrichten über mehrere Pfade bestätigen, um die Zustellung zu verbessern';

  @override
  String get repeater_refreshMultiAcks => 'Mehrfach-ACKs aktualisieren';

  @override
  String get repeater_networkHealth => 'Netzwerkzustand';

  @override
  String get repeater_loopDetect => 'Schleifenerkennung';

  @override
  String get repeater_loopDetectHelper =>
      'Flood-Pakete verwerfen, die wie Routing-Schleifen aussehen';

  @override
  String get repeater_loopDetectOff => 'Aus';

  @override
  String get repeater_loopDetectMinimal => 'Minimal';

  @override
  String get repeater_loopDetectModerate => 'mäßig';

  @override
  String get repeater_loopDetectStrict => 'Streng';

  @override
  String get repeater_dutyCycle => 'Duty-Cycle';

  @override
  String get repeater_dutyCycleHelper =>
      'Höchster zulässiger Prozentsatz der Sendefläche';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Betreiberinformationen';

  @override
  String get repeater_ownerInfoHelper =>
      'Öffentliche Metadaten für diesen Repeater';

  @override
  String get repeater_refreshOwnerInfo =>
      'Betreiberinformationen aktualisieren';

  @override
  String get repeater_floodMax => 'Maximale Flood-Sprünge';

  @override
  String get repeater_floodMaxHelper =>
      'Maximale Anzahl von Sprüngen, die ein Flood-Paket zurücklegen darf (0-64)';

  @override
  String get repeater_advancedSettings => 'Erweitert';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Feinabstimmung für erfahrene Betreiber';

  @override
  String get repeater_pathHashMode => 'Hash-Modus für Pfade';

  @override
  String get repeater_pathHashModeHelper =>
      'Bytes, die zur Kodierung der ID dieses Repeaters in Flood-Pfad-/Schleifen-Erkennung-Tags verwendet werden. 0 = 1 Byte (256 IDs, bis zu 64 Hops), 1 = 2 Bytes (65.000 IDs, bis zu 32 Hops), 2 = 3 Bytes (16 Millionen IDs, bis zu 21 Hops). Firmware-Versionen 1.13 und älter verwenden mehrstellige Pfade – ab Version 1.14+ wird nur ein Pfad erstellt, sobald das Netzwerk aktiv ist.';

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
  String get repeater_txDelay => 'Flood-TX-Verzögerung';

  @override
  String get repeater_txDelayHelper =>
      'Abstand für Flood-Verkehr als Faktor der Paket-Sendezeit (0-2, Standard 0,5). Höher = weniger Kollisionen, aber langsamere Zustellung.';

  @override
  String get repeater_directTxDelay => 'Direkte TX-Verzögerung';

  @override
  String get repeater_directTxDelayHelper =>
      'Abstand für direkten (Nicht-Flood-)Verkehr als Faktor der Paket-Sendezeit (0-2, Standard 0,3).';

  @override
  String get repeater_intThresh => 'Interferenzschwelle';

  @override
  String get repeater_intThreshHelper =>
      'Schwelle für die Rauschboden-Kalibrierung des Radios; ignoriert Interferenzen oberhalb dieses Werts. 0 deaktiviert - nur erhöhen, wenn in einem lauten Band RX-Fehler auftreten.';

  @override
  String get repeater_agcResetInterval => 'AGC-Reset-Intervall';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Wie oft die automatische Verstärkungsregelung zurückgesetzt werden soll, um aus einem festgefahrenen Verstärkungszustand zu kommen. Sekunden, auf ein Vielfaches von 4 abgerundet. 0 deaktiviert periodische Resets.';

  @override
  String get repeater_actionsTitle => 'Aktionen';

  @override
  String get repeater_sendAdvert => 'Flood-Ankündigung senden';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Eine Flood-Ankündigung über das Netzwerk senden';

  @override
  String get repeater_sendAdvertZeroHop => 'Zero-Hop-Ankündigung senden';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Eine Ein-Hop-Ankündigung ohne Weiterleiter senden';

  @override
  String get repeater_clockSync => 'Uhr jetzt synchronisieren';

  @override
  String get repeater_clockSyncSubtitle =>
      'Die Zeit Ihres Telefons an den Repeater übertragen';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action erfolgreich';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action fehlgeschlagen: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Einstellungen gespeichert - starten Sie den Repeater neu, um sie anzuwenden';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Einige Einstellungen sind fehlgeschlagen: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Fehler beim Speichern der Einstellungen: $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Grundeinstellungen aktualisieren';

  @override
  String get repeater_refreshRadioSettings =>
      'Funk-Einstellungen aktualisieren';

  @override
  String get repeater_refreshTxPower => 'Sendeleistung aktualisieren';

  @override
  String get repeater_refreshPacketForwarding =>
      'Paketweiterleitung aktualisieren';

  @override
  String get repeater_refreshGuestAccess => 'Gastzugriff aktualisieren';

  @override
  String get repeater_refreshPrivacyMode => 'Privatsphärenmodus aktualisieren';

  @override
  String repeater_refreshed(String label) {
    return '$label aktualisiert';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Fehler beim Aktualisieren von $label';
  }

  @override
  String get repeater_cliTitle => 'Repeater-CLI';

  @override
  String get repeater_debugNextCommand => 'Nächsten Befehl debuggen';

  @override
  String get repeater_commandHelp => 'Befehls-Hilfe';

  @override
  String get repeater_clearHistory => 'Verlauf löschen';

  @override
  String get repeater_noCommandsSent => 'Noch keine Befehle gesendet';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Geben Sie unten einen Befehl ein oder verwenden Sie die Schnellbefehle';

  @override
  String get repeater_enterCommandHint => 'Befehl eingeben...';

  @override
  String get repeater_previousCommand => 'Vorheriger Befehl';

  @override
  String get repeater_nextCommand => 'Nächster Befehl';

  @override
  String get repeater_enterCommandFirst => 'Geben Sie zuerst einen Befehl ein';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI-Befehlsframe';

  @override
  String repeater_cliCommandError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Name abrufen';

  @override
  String get repeater_cliQuickGetRadio => 'Funkdaten abrufen';

  @override
  String get repeater_cliQuickGetTx => 'TX abrufen';

  @override
  String get repeater_cliQuickNeighbors => 'Nachbarn';

  @override
  String get repeater_cliQuickVersion => 'Version';

  @override
  String get repeater_cliQuickAdvertise => 'Ankündigen';

  @override
  String get repeater_cliQuickClock => 'Uhr';

  @override
  String get repeater_cliQuickClockSync => 'Uhr synchronisieren';

  @override
  String get repeater_cliQuickDiscovery => 'Nachbarn entdecken';

  @override
  String get repeater_cliHelpAdvert => 'Sendet eine Ankündigung';

  @override
  String get repeater_cliHelpReboot =>
      'Startet das Gerät neu. (Beachten Sie, dass es möglicherweise zu einer \'Timeout\'-Situation kommt, was normal ist.)';

  @override
  String get repeater_cliHelpClock =>
      'Zeigt die aktuelle Uhrzeit pro Gerät an.';

  @override
  String get repeater_cliHelpPassword =>
      'Legt ein neues Administrator-Passwort für das Gerät fest.';

  @override
  String get repeater_cliHelpVersion =>
      'Zeigt die Geräteversion und das Datum des Firmware-Builds an.';

  @override
  String get repeater_cliHelpClearStats =>
      'Setzt verschiedene Statistikberechnungen auf Null zurück.';

  @override
  String get repeater_cliHelpSetAf => 'Legt den Luftzeitfaktor fest.';

  @override
  String get repeater_cliHelpSetTx =>
      'Legt die LoRa-Sendeleistung in dBm fest. (Neustart erforderlich, um die Änderungen anzuwenden)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Aktiviert oder deaktiviert die Repeater-Rolle für diesen Knoten.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Raumspeicher) Wenn \'an\', dann wird die Anmeldung mit einem leeren Passwort erlaubt sein, aber es kann nicht in den Raum gesendet werden. (nur lesen möglich).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Legt die maximale Anzahl an Sprüngen für eingehende Flood-Pakete fest (wenn >= max, wird das Paket nicht weitergeleitet)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Legt den Interferenzeniveau (in dB) fest. Der Standardwert ist 14. Auf 0 setzen, um die Erkennung von Kanalinterferenzen zu deaktivieren.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Legt das Intervall für das Zurücksetzen des Auto Gain Controllers fest. Auf 0 setzen, um die Funktion zu deaktivieren.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Aktiviert oder deaktiviert die Funktion \'Doppel-ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Legt das Timer-Intervall in Minuten fest, um ein lokales (ohne-Weiterleitung) Ankündigungspaket zu senden. Auf 0 setzen, um die Funktion zu deaktivieren.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Legt das Timer-Intervall in Stunden für den Versand eines Flut-Ankündigungspacket fest. Auf 0 setzen, um es zu deaktivieren.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Legt/aktualisiert das Gastpasswort fest. (für Repeater können Gast-Logins die \"Get Stats\"-Anfrage senden)';

  @override
  String get repeater_cliHelpSetName => 'Legt den Anzeigenamen fest.';

  @override
  String get repeater_cliHelpSetLat =>
      'Legt die Breitengrad der Ankündigung fest. (dezimale Grad)';

  @override
  String get repeater_cliHelpSetLon =>
      'Legt die Längengrade der Ankündigung fest. (dezimale Grad)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Legt komplett neue Radio-Parameter fest und speichert diese als Präferenzen. Benötigt einen \"Reboot\"-Befehl, um sie anzuwenden.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Fügt eine leichte Verzögerung bei empfangenen Paketen hinzu, basierend auf Signalstärke/Punktzahl. Auf 0 setzen, um die Funktion zu deaktivieren.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Legt einen Faktor fest, der mit der Sendezeit eines Flood-Mode-Pakets und mit einem zufälligen Slot-System multipliziert wird, um dessen Weiterleitung zu verzögern (um Kollisionen zu vermeiden).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Ähnlich wie txdelay, aber zum Anwenden einer zufälligen Verzögerung bei der Weiterleitung von Direktmodus-Paketen.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Brücke aktivieren/deaktivieren.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Setze Verzögerung vor erneuter Übertragung von Paketen.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Wählen Sie, ob über die Brücke empfangene oder gesendete Pakete erneut übertragen soll.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Setze die serielle Link-Baudrate für RS232-Brücken.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Richte das Brückenpassword ein.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Legt einen benutzerdefinierten Faktor zur Anpassung der gemeldeten Batteriewirkspannung fest (nur auf ausgewählten Boards unterstützt).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Legt vorübergehende Funkparameter für die angegebene Anzahl von Minuten fest und kehrt anschließend zu den ursprünglichen Funkparametern zurück (wird nicht in den Einstellungen gespeichert).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Ändert die ACL. Entfernt das passende Eintragen (durch Pubkey-Präfix), wenn \"permissions\" auf 0 steht. Fügt ein neues Eintragen hinzu, wenn die Pubkey-Hex-Länge vollständig ist und nicht bereits in der ACL vorhanden ist. Aktualisiert das Eintragen anhand des übereinstimmenden Pubkey-Präfix. Berechtigungsbits variieren je nach Firmware-Rolle, aber die unteren 2 Bits sind: 0 (Gast), 1 (Nur Lesen), 2 (Lesen/Schreiben), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Ruft Brückentyp: none, rs232, espnow ab.';

  @override
  String get repeater_cliHelpLogStart =>
      'Beginnt die Paketprotokollierung in das Dateisystem.';

  @override
  String get repeater_cliHelpLogStop =>
      'Stoppt das Paketprotokollieren in das Dateisystem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Löscht die Paketprotokolle aus dem Dateisystem.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Zeigt eine Liste anderer Repeater-Knoten an, die über Zero-Hop-Ankündigung gehört wurden. Jede Zeile ist id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Entfernt das erste übereinstimmende Element (über Pubkey-Präfix (hex)) aus der Liste der Nachbarn.';

  @override
  String get repeater_cliHelpRegion => 'Listet alle definierten Regionen auf.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Hinweis: Dies ist ein spezieller Mehrbefehl-Aufruf. Jeder nachfolgende Befehl ist ein Regionsname (eingerückt mit Leerzeichen zur Angabe der übergeordneten Hierarchie, mit mindestens einem Leerzeichen). Beendet durch das Senden einer Leerzeile.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Sucht die Region mit dem gegebenen Namenspräfix (oder \"\\\" für den globalen Scope) und antwortet mit \"-> region-name (parent-name) \'F\'\".';

  @override
  String get repeater_cliHelpRegionPut =>
      'Fügt eine Region-Definition mit dem angegebenen Namen hinzu oder aktualisiert diese.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Löscht eine Regiondefinition mit dem angegebenen Namen. (muss genau übereinstimmen und keine Kindregionen haben)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Legt die \'Flut\'-Berechtigung für die angegebene Region fest. (\'\' für den globalen/legacy-Bereich)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Entfernt die \"F\"lood-Berechtigung für die angegebene Region. (ANMERKUNG: in dieser Phase wird nicht empfohlen, dies auf dem globalen/legacy-Bereich zu verwenden!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Antwortet mit der aktuellen \'Home\'-Region. (Hinweis wurde bisher nirgendwo angewendet, für zukünftige Zwecke reserviert)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Legt die \'Home\'-Region fest.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Speichert die Regionenliste/Karte in den Speicher.';

  @override
  String get repeater_cliHelpGps =>
      'Zeigt GPS-Status an. Wenn GPS deaktiviert ist, antwortet es nur mit \"aus\", wenn es eingeschaltet ist, antwortet es mit \"an\", \"Status\", \"Fix\" und Satellitenanzahl.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Schaltet die GPS-Leistung ein/aus.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronisiert die Knotenzeit mit der GPS-Uhr.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Setze die Position des Knotens auf GPS-Koordinaten und speichere die Präferenzen.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Gibt Konfiguration für die Standortanzeige des Knotens:\n- none: Standort nicht in Anzeigen einbeziehen\n- share: GPS-Standort teilen (von SensorManager)\n- prefs: Standort aus Einstellungen anzeigen';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Legt die Standort-Anzeigekonfiguration fest.';

  @override
  String get repeater_commandsListTitle => 'Befehlsliste';

  @override
  String get repeater_commandsListNote =>
      'ACHTUNG: Für die verschiedenen „set ...“-Befehle gibt es auch einen „get ...“-Befehl.';

  @override
  String get repeater_general => 'Allgemein';

  @override
  String get repeater_settingsCategory => 'Einstellungen';

  @override
  String get repeater_bridge => 'Brücke';

  @override
  String get repeater_logging => 'Protokollierung';

  @override
  String get repeater_neighborsRepeaterOnly => 'Nachbarn (nur Repeater)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regionenverwaltung (nur Repeater)';

  @override
  String get repeater_regionNote =>
      'Region-Befehle wurden eingeführt, um Region-Definitionen und Berechtigungen zu verwalten.';

  @override
  String get repeater_gpsManagement => 'GPS-Verwaltung';

  @override
  String get repeater_gpsNote =>
      'Der GPS-Befehl wurde eingeführt, um Standortbezogene Themen zu verwalten.';

  @override
  String get repeater_getCategory => 'Werte erhalten';

  @override
  String get repeater_powerMgmt => 'Energieverwaltung';

  @override
  String get repeater_sensors => 'Sensoren';

  @override
  String get repeater_cliHelpPowerOff =>
      'Schaltet das Gerät aus. (keine Antwort erwartet)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Setzt die Uhr auf einen bekannten Zeitpunkt zurück und startet das Gerät neu.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Sendet eine Werbeanzeige, die nur an unmittelbare Nachbarn gesendet wird (ohne Zwischenstation).';

  @override
  String get repeater_cliHelpStartOta =>
      'Startet ein Firmware-Update über Funk, das auf unterstützten Boards durchgeführt wird.';

  @override
  String get repeater_cliHelpTime =>
      'Stellt die Gerätuhr auf die angegebene Unix-Epoche in Sekunden ein. Die Uhr kann nicht rückwärts laufen.';

  @override
  String get repeater_cliHelpBoard =>
      'Zeigt den Hersteller/die Hardware-Kennung an.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Sendet eine Anfrage zur Entdeckung von Nachbarn in der Nähe. (Nur bei Repeatern)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Zeigt an, ob der Energiesparmodus aktiviert oder deaktiviert ist.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Aktiviert oder deaktiviert den Energiesparmodus (falls unterstützt).';

  @override
  String get repeater_cliHelpErase =>
      '(Nur für serielle Schnittstellen) Formatiert das Dateisystem des Geräts. Löscht alle Einstellungen und Kontakte.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Legt den maximal zulässigen Übertragungszyklus als Prozentsatz fest (1-100). Passt den Zeitfaktor intern an.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(Nur für serielle Anwendungen) Ersetzt den privaten Schlüssel zur Geräteidentifizierung. Nach der Anwendung ist ein Neustart erforderlich. Generiert einen neuen öffentlichen Schlüssel.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Nur für SX126x) Schaltet die verstärkte RX-Verstärkung ein, um die Empfindlichkeit bei höherem Stromverbrauch zu verbessern.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Definiert den String mit den Kontaktinformationen des Eigentümers, der in den Anzeigen enthalten ist. Verwenden Sie \'|\' für Zeilenumbrüche.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Legt den Modus für die Pfad-Hashes fest. 0 = ältere Version, 1 = Standard, 2 = streng. Beeinflusst, wie Routing-Pfade abgeglichen werden.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Legt die Empfindlichkeit der Schleifenerkennung fest: aus, minimal, moderat oder streng.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Nur für die serielle Schnittstelle) Ermöglicht die schnelle Einstellung der Frequenz. Nach der Einstellung ist ein Neustart erforderlich. Für die vollständige Einstellung aller Radio-Parameter wird die Option \"Radio einstellen\" empfohlen.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Nur für ESPNow-Brücke) Legt den verwendeten WLAN-Kanal (1-14) für die Brücke fest.';

  @override
  String get repeater_cliHelpGetName =>
      'Zeigt den konfigurierten Knotenamen an.';

  @override
  String get repeater_cliHelpGetRole =>
      'Zeigt die Funktion der Firmware an (Repeater, Raumserver usw.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Zeigt den öffentlichen Schlüssel des Geräts an.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Nur für serielle Kommunikation) Zeigt den privaten Schlüssel des Geräts an. Behandeln Sie diesen als ein Geheimnis.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Zeigt an, ob die Weiterleitung von Paketen (als Repeater) aktiviert oder deaktiviert ist.';

  @override
  String get repeater_cliHelpGetTx =>
      'Zeigt die aktuelle Sendeleistung in dBm an.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Zeigt die konfigurierte Funkfrequenz in MHz an.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Zeigt alle Funkparameter an: Frequenz, Bandbreite, Spreading-Faktor, Codierungsrate.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Nur für SX126x) Zeigt den Zustand des verstärkten Empfangs (RX).';

  @override
  String get repeater_cliHelpGetAf => 'Zeigt den aktuellen Zeitfaktor an.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Zeigt den aktuellen zulässigen Schaltzyklus als Prozentsatz an.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Zeigt den Grenzwert für Kanalüberlagerung in dB an.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Zeigt das Intervall für die Rücksetzung des AGC in Sekunden an.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Zeigt an, ob der Modus \"doppelte ACK\"-Funktion aktiviert (1) oder deaktiviert (0) ist.';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Zeigt an, ob der Zugriff für Gäste nur in Lesemodus erlaubt ist.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Zeigt die Dauer des lokalen Werbeintervalls in Minuten an.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Zeigt die Dauer der Werbeunterbrechung in Stunden an.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Zeigt das konfigurierte Gast-Passwort an.';

  @override
  String get repeater_cliHelpGetLat => 'Zeigt die konfigurierte Breitengrade.';

  @override
  String get repeater_cliHelpGetLon => 'Zeigt die konfigurierte Länge an.';

  @override
  String get repeater_cliHelpGetRxDelay =>
      'Zeigt den Basiswert für die Verzögerungszeit an.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Zeigt den Faktor für die Übertragungsverzögerung im Notfallmodus an.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Zeigt den Faktor für die Verzögerung im Direktmodus an.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Zeigt die maximale Anzahl von Sprüngen für Flood-Pakete an.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Zeigt die Zeichenkette mit den Kontaktinformationen des Eigentümers an.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Zeigt den Pfad-Hash-Modus (0/1/2) an.';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Zeigt die Empfindlichkeit der Schleifenerkennung an.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Nur für serielle Kommunikation) Zeigt die Zugriffskontrolleinträge auf einem Repeater an.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Zeigt an, ob die Brücke aktiviert ist.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Zeigt die Verzögerung der Brücke in Millisekunden an.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Zeigt, ob die Brücke RX- oder TX-Pakete empfängt oder sendet.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Nur für RS232-Verbindungen) Zeigt die Baudrate der Verbindung an.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Nur für ESPNow-Brücke) Zeigt den WLAN-Kanal der Brücke an.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Nur für ESPNow-Brücke) Zeigt das gemeinsam genutzte Geheimnis der Brücke.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Nur für NRF52) Zeigt die Version des Bootloaders an.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Zeigt den ADC-Verstärker (Spannungs-Skalierung) an.';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Gibt an, ob der Verwaltungsrat die Funktion zur Energieverwaltung unterstützt.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Zeigt die aktuelle Stromquelle an: extern oder Batterie.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Zeigt die aktuellsten Gründe für einen Neustart und Herunterfahren an.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Zeigt die Batteriespannung beim Start in Millivolt (mV) an.';

  @override
  String get repeater_cliHelpSensorGet =>
      'Liest eine benutzerdefinierte Sensoreinstellung über eine Taste.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Erstellt eine benutzerdefinierte Sensoreinstellung.';

  @override
  String get repeater_cliHelpSensorList =>
      'Zeigt alle benutzerdefinierten Sensoreinstellungen an, wobei die Seitennummerierung optional von einem Startindex abhängt.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Zeigt den aktuellen Standard-Region-Bereich an.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Definiert den Standard-Regionenbereich. Verwenden Sie \"<null>\", um diesen zu löschen.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Nennt die Regionen, die Flood-Verkehr zulassen.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Nennt die Regionen, die Flood-Verkehr verbieten.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Nur für serielle Verbindungen) Zeigt Statistiken auf Paketebene.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Nur für Serien) Zeigt Radiostatistiken an.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Nur für serielle Schnittstellen) Zeigt grundlegende Firmware-Statistiken.';

  @override
  String get telemetry_receivedData => 'Empfangene Telemetriedaten';

  @override
  String get telemetry_requestTimeout =>
      'Telemetry-Anfrage hat zu lange gedauert.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Fehler beim Laden der Telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Keine Telemetriedaten verfügbar.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Akku';

  @override
  String get telemetry_voltageLabel => 'Spannung';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU Temperatur';

  @override
  String get telemetry_temperatureLabel => 'Temperatur';

  @override
  String get telemetry_currentLabel => 'Aktuell';

  @override
  String telemetry_batteryValue(int percent, String volts) {
    return '$percent% / ${volts}V';
  }

  @override
  String telemetry_voltageValue(String volts) {
    return '$volts Volt';
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
  String get telemetry_digitalInputLabel => 'Digitaleingang';

  @override
  String get telemetry_digitalOutputLabel => 'Digitalausgang';

  @override
  String get telemetry_analogInputLabel => 'Analogeingang';

  @override
  String get telemetry_analogOutputLabel => 'Analogausgang';

  @override
  String get telemetry_genericLabel => 'Allgemeiner Sensor';

  @override
  String get telemetry_luminosityLabel => 'Helligkeit';

  @override
  String get telemetry_presenceLabel => 'Anwesenheit';

  @override
  String get telemetry_humidityLabel => 'Luftfeuchtigkeit';

  @override
  String get telemetry_accelerometerLabel => 'Beschleunigungsmesser';

  @override
  String get telemetry_pressureLabel => 'Druck';

  @override
  String get telemetry_altitudeLabel => 'Höhe';

  @override
  String get telemetry_frequencyLabel => 'Frequenz';

  @override
  String get telemetry_percentageLabel => 'Prozentsatz';

  @override
  String get telemetry_concentrationLabel => 'Konzentration';

  @override
  String get telemetry_powerLabel => 'Leistung';

  @override
  String get telemetry_distanceLabel => 'Entfernung';

  @override
  String get telemetry_energyLabel => 'Energie';

  @override
  String get telemetry_directionLabel => 'Richtung';

  @override
  String get telemetry_timeLabel => 'Zeit';

  @override
  String get telemetry_gyrometerLabel => 'Gyroskop';

  @override
  String get telemetry_colourLabel => 'Farbe';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Schalter';

  @override
  String get telemetry_polylineLabel => 'Polylinie';

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
  String get telemetry_autoFetchQuantity => 'Anzahl der Anfragen';

  @override
  String get telemetry_error => 'Daten konnten nicht abgerufen werden';

  @override
  String get neighbors_receivedData => 'Empfangene Nachbarsdaten';

  @override
  String get neighbors_requestTimedOut =>
      'Anfrage durch Timeout fehlgeschlagen.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Fehler beim Laden der Nachbarn: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Nachbarn';

  @override
  String get neighbors_noData => 'Keine Nachbarsdaten verfügbar.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Unbekannt $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Gehört vor: $time';
  }

  @override
  String get channelPath_title => 'Paketpfad';

  @override
  String get channelPath_viewMap => 'Karte anzeigen';

  @override
  String get channelPath_otherObservedPaths => 'Sonstige beobachtete Pfade';

  @override
  String get channelPath_repeaterHops => 'Repeater-Sprünge';

  @override
  String get channelPath_noHopDetails =>
      'Die Detailangaben für dieses Paket sind nicht verfügbar.';

  @override
  String get channelPath_messageDetails => 'Nachrichtendetails';

  @override
  String get channelPath_senderLabel => 'Sender';

  @override
  String get channelPath_timeLabel => 'Zeit';

  @override
  String get channelPath_repeatsLabel => 'Wiederholungen';

  @override
  String channelPath_pathLabel(int index) {
    return 'Pfad $index';
  }

  @override
  String get channelPath_observedLabel => 'Beobachtet';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Beobachteter Pfad $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Keine Standortdaten';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Unbekannt';

  @override
  String get channelPath_floodPath => 'Geflutet';

  @override
  String get channelPath_directPath => 'Direkt';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 von $total Sprüngen';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed von $total Sprüngen';
  }

  @override
  String get channelPath_mapTitle => 'Pfadkarte';

  @override
  String get channelPath_noRepeaterLocations =>
      'Für diesen Pfad stehen keine Repeater-Positionen zur Verfügung.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Pfad $index (Primär)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Pfad';

  @override
  String get channelPath_observedPathHeader => 'Beobachteter Pfad';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Keine Informationen zu dieser Paketroute verfügbar.';

  @override
  String get channelPath_unknownRepeater => 'Unbekannter Repeater';

  @override
  String get community_title => 'Gemeinschaft';

  @override
  String get community_create => 'Erstelle Community';

  @override
  String get community_createDesc =>
      'Erstelle eine neue Community und teile sie über den QR-Code.';

  @override
  String get community_join => 'Beitreten';

  @override
  String get community_joinTitle => 'Tritt der Community bei';

  @override
  String community_joinConfirmation(String name) {
    return 'Möchten Sie sich der Community \"$name\" anschließen?';
  }

  @override
  String get community_scanQr => 'Scannen Sie die Community QR-Code';

  @override
  String get community_scanInstructions =>
      'Richten Sie die Kamera auf einen Community-QR-Code.';

  @override
  String get community_showQr => 'Zeige QR-Code';

  @override
  String get community_publicChannel => 'Community Öffentlich';

  @override
  String get community_hashtagChannel => 'Gemeinschaftlicher Hashtag';

  @override
  String get community_name => 'Name der Gemeinde';

  @override
  String get community_enterName => 'Bitte Community-Name eingeben';

  @override
  String community_created(String name) {
    return 'Community \"$name\" wurde erstellt';
  }

  @override
  String community_joined(String name) {
    return 'Community \"$name\" beigetreten';
  }

  @override
  String get community_qrTitle => 'Teile Community';

  @override
  String community_qrInstructions(String name) {
    return 'Scannen Sie diesen QR-Code, um sich \"$name\" anzuschließen.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Community-Hashtag-Kanäle können nur von Mitgliedern der Community betreten werden';

  @override
  String get community_invalidQrCode => 'Ungültiger Community-QR-Code';

  @override
  String get community_alreadyMember => 'Bereits registriert';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Sie sind bereits Mitglied von \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Füge einen öffentlichen Community-Kanal hinzu';

  @override
  String get community_addPublicChannelHint =>
      'Automatisch den öffentlichen Kanal für diese Community hinzufügen';

  @override
  String get community_noCommunities => 'Noch keiner Community beigetreten';

  @override
  String get community_scanOrCreate =>
      'Scannen Sie einen QR-Code oder eine Community erstellen, um loszulegen.';

  @override
  String get community_manageCommunities => 'Verwalten von Communities';

  @override
  String get community_delete => 'Verlasse Community';

  @override
  String community_deleteConfirm(String name) {
    return '\"$name\" verlassen?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Dies löscht auch $count Kanal/Kanäle und deren Nachrichten.';
  }

  @override
  String community_deleted(String name) {
    return 'Community \"$name\" verlassen';
  }

  @override
  String get community_regenerateSecret => 'Neugenerierung des Schlüssels';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Nehmen Sie den geheimen Schlüssel für \"$name\" neu auf? Alle Mitglieder müssen den neuen QR-Code scannen, um die Kommunikation fortzusetzen.';
  }

  @override
  String get community_regenerate => 'Neu generieren';

  @override
  String community_secretRegenerated(String name) {
    return 'Wiederherstellung des Schlüssels für \"$name\" erfolgreich';
  }

  @override
  String get community_updateSecret => 'Aktualisieren Sie den Schlüssel';

  @override
  String community_secretUpdated(String name) {
    return 'Schlüssel für \"$name\" aktualisiert';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scannen Sie den neuen QR-Code, um das Geheimnis für \"$name\" zu aktualisieren.';
  }

  @override
  String get community_addHashtagChannel =>
      'Füge einen Community-Hashtag hinzu';

  @override
  String get community_addHashtagChannelDesc =>
      'Füge einen Hashtag-Kanal für diese Community hinzu';

  @override
  String get community_selectCommunity => 'Wählen Sie eine Community';

  @override
  String get community_regularHashtag => 'Regulärer Hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Öffentlicher Hashtag (jeder kann teilnehmen)';

  @override
  String get community_communityHashtag => 'Gemeinschaftlicher Hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Nur für Mitglieder der Community';

  @override
  String community_forCommunity(String name) {
    return 'Für $name';
  }

  @override
  String get listFilter_tooltip => 'Filteren und sortieren';

  @override
  String get listFilter_sortBy => 'Sortiere nach';

  @override
  String get listFilter_latestMessages => 'Letzte Nachrichten';

  @override
  String get listFilter_heardRecently => 'Kürzlich gehört';

  @override
  String get listFilter_az => 'Von A bis Z';

  @override
  String get listFilter_filters => 'Filtere';

  @override
  String get listFilter_all => 'Alle';

  @override
  String get listFilter_favorites => 'Favoriten';

  @override
  String get listFilter_addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get listFilter_removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get listFilter_users => 'Benutzer';

  @override
  String get listFilter_repeaters => 'Repeater';

  @override
  String get listFilter_roomServers => 'Raumserver';

  @override
  String get listFilter_unreadOnly => 'Nicht gelesen';

  @override
  String get listFilter_newGroup => 'Neue Gruppe';

  @override
  String get pathTrace_you => 'Du';

  @override
  String get pathTrace_failed => 'Pfadverfolgung fehlgeschlagen.';

  @override
  String get pathTrace_notAvailable => 'Pfadverfolgung nicht verfügbar.';

  @override
  String get pathTrace_refreshTooltip => 'Path Trace aktualisieren.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Bei einer oder mehreren Knoten fehlt der Standort!';

  @override
  String get pathTrace_clearTooltip => 'Pfad löschen';

  @override
  String get losSelectStartEnd =>
      'Wählen Sie Start- und Endknoten für LOS aus.';

  @override
  String losRunFailed(String error) {
    return 'Sichtlinienprüfung fehlgeschlagen: $error';
  }

  @override
  String get losClearAllPoints => 'Löschen Sie alle Punkte';

  @override
  String get losRunToViewElevationProfile =>
      'Führen Sie LOS aus, um das Höhenprofil anzuzeigen';

  @override
  String get losMenuTitle => 'LOS-Menü';

  @override
  String get losMenuSubtitle =>
      'Tippen Sie auf Knoten oder drücken Sie lange auf die Karte, um benutzerdefinierte Punkte anzuzeigen';

  @override
  String get losShowDisplayNodes => 'Anzeigeknoten anzeigen';

  @override
  String get losCustomPoints => 'Benutzerdefinierte Punkte';

  @override
  String losCustomPointLabel(int index) {
    return 'Benutzerdefiniert $index';
  }

  @override
  String get losPointA => 'Punkt A';

  @override
  String get losPointB => 'Punkt B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenne A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenne B: $value $unit';
  }

  @override
  String get losRun => 'Führen Sie LOS aus';

  @override
  String get losNoElevationData => 'Keine Höhendaten';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, freie Sichtlinie, Mindestabstand $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blockiert durch $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: Überprüfen...';

  @override
  String get losStatusNoData => 'LOS: keine Daten';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'Sichtlinie: $clear/$total frei, $blocked blockiert, $unknown unbekannt';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Für eine oder mehrere Proben sind keine Höhendaten verfügbar.';

  @override
  String get losErrorInvalidInput =>
      'Ungültige Punkte/Höhendaten für die LOS-Berechnung.';

  @override
  String get losRenameCustomPoint =>
      'Benennen Sie den benutzerdefinierten Punkt um';

  @override
  String get losPointName => 'Punktname';

  @override
  String get losShowPanelTooltip => 'LOS-Panel anzeigen';

  @override
  String get losHidePanelTooltip => 'LOS-Panel ausblenden';

  @override
  String get losElevationAttribution => 'Höhendaten: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Funkhorizont';

  @override
  String get losLegendLosBeam => 'Sichtlinie';

  @override
  String get losLegendTerrain => 'Gelände';

  @override
  String get losBlockedSpotsTitle => 'Reservierte Plätze';

  @override
  String get losBlockedSpotsHint =>
      'Klicken Sie auf einen blockierten Bereich, um ihn auf der Karte hervorzuheben.';

  @override
  String losBlockedSpotChip(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance • $distanceUnit • $obstruction $heightUnit';
  }

  @override
  String get losSelectedObstructionTitle => 'Ausgewählte Behinderung';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Blockiert durch $obstruction in einer Höhe von $heightUnit, $distanceFromA von A und $distanceFromB von B ($distanceUnit).';
  }

  @override
  String get losFrequencyLabel => 'Frequenz';

  @override
  String get losFrequencyInfoTooltip => 'Details zur Berechnung anzeigen';

  @override
  String get losFrequencyDialogTitle => 'Berechnung des Funkhorizonts';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Ausgehend von k=$baselineK bei $baselineFreq MHz passt die Berechnung den k-Faktor für das aktuelle $frequencyMHz MHz-Band an, das die gekrümmte Funkhorizontobergrenze definiert.';
  }

  @override
  String get contacts_pathTrace => 'Pfadverfolgung';

  @override
  String get contacts_ping => 'Pingen';

  @override
  String get contacts_repeaterPathTrace => 'Pfadverfolgung zum Repeater';

  @override
  String get contacts_repeaterPing => 'Repeater pingen';

  @override
  String get contacts_roomPathTrace => 'Pfadverfolgung zum Raumserver';

  @override
  String get contacts_roomPing => 'Raumserver anpingen';

  @override
  String get contacts_chatTraceRoute => 'Pfadverfolgungsroute';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Route nach $name verfolgen';
  }

  @override
  String get contacts_clipboardEmpty => 'Die Zwischenablage ist leer.';

  @override
  String get contacts_invalidAdvertFormat => 'Ungültige Kontaktdaten';

  @override
  String get contacts_contactImported => 'Kontakt wurde importiert.';

  @override
  String get contacts_contactImportFailed =>
      'Kontakt konnte nicht importiert werden';

  @override
  String get contacts_zeroHopAdvert => 'Zero-Hop-Ankündigung';

  @override
  String get contacts_floodAdvert => 'Flut-Ankündigung';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Ankündigung in die Zwischenablage kopieren';

  @override
  String get contacts_addContactFromClipboard =>
      'Kontakt aus Zwischenablage hinzufügen';

  @override
  String get contacts_ShareContact => 'Kontakt in die Zwischenablage kopieren';

  @override
  String get contacts_ShareContactZeroHop => 'Kontakt über Anzeige teilen';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Kontakt über Anzeige gesendet';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Kontakt konnte nicht gesendet werden.';

  @override
  String get contacts_contactAdvertCopied =>
      'Anzeige in die Zwischenablage kopiert.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopieren der Ankündigung in die Zwischenablage fehlgeschlagen.';

  @override
  String get notification_activityTitle => 'MeshCore Aktivität';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nachrichten',
      one: 'Nachricht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kanalnachrichten',
      one: 'Kanalnachricht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'neue Knoten',
      one: 'neuer Knoten',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Neuer $contactType entdeckt';
  }

  @override
  String get notification_receivedNewMessage => 'Neue Nachricht empfangen';

  @override
  String get settings_gpxExportRepeaters =>
      'Repeater und Raumserver als GPX exportieren';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportiert Repeater und Raumserver mit einem Standort in eine GPX-Datei.';

  @override
  String get settings_gpxExportContacts => 'Kontakte als GPX exportieren';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exportiert Kontakte mit einem Ort in eine GPX-Datei.';

  @override
  String get settings_gpxExportAll => 'Alle Knoten als GPX exportieren';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exportiert alle Knoten mit einem Standort in eine GPX-Datei.';

  @override
  String get settings_gpxExportSuccess => 'GPX-Datei erfolgreich exportiert.';

  @override
  String get settings_gpxExportNoContacts => 'Keine Kontakte zum Exportieren.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nicht auf Ihrem Gerät/Betriebssystem unterstützt';

  @override
  String get settings_gpxExportError =>
      'Beim Export ist ein Fehler aufgetreten.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Repeater- und Raumserver-Standorte';

  @override
  String get settings_gpxExportChat => 'Kontaktstandorte';

  @override
  String get settings_gpxExportAllContacts => 'Alle Kontaktstandorte';

  @override
  String get settings_gpxExportShareText =>
      'GPX-Kartendaten aus meshcore-open exportiert';

  @override
  String get settings_gpxExportShareSubject =>
      'GPX-Kartendaten aus meshcore-open exportieren';

  @override
  String get snrIndicator_nearByRepeaters => 'In der Nähe befindliche Repeater';

  @override
  String get snrIndicator_lastSeen => 'Zuletzt gesehen';

  @override
  String get contactsSettings_title => 'Kontakteinstellungen';

  @override
  String get contactsSettings_autoAddTitle => 'Automatische Erkennung';

  @override
  String get contactsSettings_otherTitle =>
      'Weitere Einstellungen zu Kontakten';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automatische Hinzufügung von Benutzern';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Ermöglichen Sie dem Begleiter, automatisch entdeckte Benutzer hinzuzufügen';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automatisch Repeater hinzufügen';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Ermöglichen Sie dem Begleiter, automatisch entdeckte Repeater hinzuzufügen.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automatisch Raumservers hinzufügen';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Ermöglichen Sie dem Begleiter, entdeckte Raumserver automatisch hinzuzufügen';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatisch Sensoren hinzufügen';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Ermöglichen Sie dem Begleiter, automatisch entdeckte Sensoren hinzuzufügen';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Überschreiben des Ältesten';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Wenn die Kontaktliste voll ist, wird der älteste nicht favorisierte Kontakt ersetzt.';

  @override
  String get discoveredContacts_Title => 'Entdeckte Kontakte';

  @override
  String get discoveredContacts_noMatching => 'Keine passenden Kontakte';

  @override
  String get discoveredContacts_searchHint => 'Entdeckte Kontakte suchen';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt hinzugefügt';

  @override
  String get discoveredContacts_addContact => 'Kontakt hinzufügen';

  @override
  String get discoveredContacts_copyContact =>
      'Kontakt in die Zwischenablage kopieren';

  @override
  String get discoveredContacts_deleteContact => 'Kontakt löschen';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Alle entdeckten Kontakte löschen';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Sind Sie sicher, dass Sie alle gefundenen Kontakte löschen möchten?';

  @override
  String get chat_sendCooldown =>
      'Bitte warten Sie einen Moment, bevor Sie erneut senden.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Zum ältesten, nicht gelesenen Eintrag springen';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Wenn Sie ein Chatfenster öffnen, in dem Nachrichten vorhanden sind, die noch nicht gelesen wurden, scrollen Sie zu der ersten unlesenen Nachricht, anstatt zur neuesten.';

  @override
  String get appSettings_languageHu => 'Ungarisch';

  @override
  String get appSettings_languageJa => 'Japanisch';

  @override
  String get appSettings_languageKo => 'Koreanisch';

  @override
  String get radioStats_tooltip => 'Daten zu Radio- und Mesh-Netzwerken';

  @override
  String get radioStats_screenTitle => 'Senderinformationen';

  @override
  String get radioStats_notConnected =>
      'Verbinden Sie ein Gerät, um Radiostatistiken anzuzeigen.';

  @override
  String get radioStats_firmwareTooOld =>
      'Für die Verwendung der Funkstatistiken ist die Firmware-Version 8 oder höher erforderlich.';

  @override
  String get radioStats_waiting => 'Warte auf Daten…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Rauschpegel: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Letzter RSSI-Wert: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Letzter SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Gesamt-TX-Zeit: $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Gesamt-RX-Zeit: $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Rauschpegel (dBm) basierend auf den letzten Messwerten.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Rauschpegel: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Abrufen von Radiostatus…';

  @override
  String get radioStats_settingsTile => 'Senderinformationen';

  @override
  String get radioStats_settingsSubtitle =>
      'Rauschpegel, RSSI, Signal-Rausch-Verhältnis (SNR) und Nutzzeit';

  @override
  String get translation_title => 'Übersetzung';

  @override
  String get translation_enableTitle => 'Aktivieren Sie die Übersetzung';

  @override
  String get translation_enableSubtitle =>
      'Nachrichten empfangen und übersetzen sowie die Möglichkeit bieten, Nachrichten vor dem Versenden zu übersetzen.';

  @override
  String get translation_composerTitle => 'Übersetzen Sie vor dem Versenden';

  @override
  String get translation_composerSubtitle =>
      'Steuert den Standardzustand des Icons für die Übersetzung des Komponisten.';

  @override
  String get translation_autoIncomingTitle =>
      'Nachrichten automatisch übersetzen';

  @override
  String get translation_autoIncomingSubtitle =>
      'Übersetzt Nachrichten für Benachrichtigungen sowie für Chats oder Kanäle automatisch.';

  @override
  String get translation_translateMessage => 'Nachricht übersetzen';

  @override
  String get translation_targetLanguage => 'Zielsprache';

  @override
  String get translation_useAppLanguage => 'Verwenden Sie die App-Sprache';

  @override
  String get translation_downloadedModelLabel => 'Heruntergeladenes Modell';

  @override
  String get translation_presetModelLabel =>
      'Vordefinierter Hugging Face-Modell';

  @override
  String get translation_manualUrlLabel => 'URL für das manuelle Modell';

  @override
  String get translation_downloadModel => 'Modell herunterladen';

  @override
  String get translation_downloading => 'Herunterladen...';

  @override
  String get translation_working => 'Arbeiten...';

  @override
  String get translation_stop => 'Stopp';

  @override
  String get translation_mergingChunks =>
      'Zusammenführen der heruntergeladenen Teile in die finale Datei...';

  @override
  String get translation_downloadedModels => 'Heruntergeladene Modelle';

  @override
  String get translation_deleteModel => 'Modell löschen';

  @override
  String get translation_modelDownloaded =>
      'Übersetzungsmotor heruntergeladen.';

  @override
  String get translation_downloadStopped => 'Herunterladen abgebrochen.';

  @override
  String translation_downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Geben Sie zunächst die URL eines Modells ein.';

  @override
  String get scanner_linuxPairingShowPin => 'PIN anzeigen';

  @override
  String get scanner_linuxPairingHidePin => 'PIN ausblenden';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth-Paarungs-PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Geben Sie die PIN für $deviceName ein (leer lassen, falls keine).';
  }

  @override
  String get translation_messageTranslation => 'Nachricht übersetzen';

  @override
  String get translation_translateBeforeSending =>
      'Übersetzen Sie vor dem Versenden';

  @override
  String get translation_composerEnabledHint =>
      'Die Nachrichten werden vor dem Versenden übersetzt.';

  @override
  String get translation_composerDisabledHint =>
      'Nachrichten in der ursprünglichen, getippten Sprache senden.';

  @override
  String translation_translateTo(String language) {
    return 'Übersetzen Sie auf $language';
  }

  @override
  String get translation_translationOptions => 'Übersetzungsmöglichkeiten';

  @override
  String get translation_systemLanguage => 'Sprache des Systems';

  @override
  String get background_serviceTitle => 'MeshCore läuft';

  @override
  String get background_serviceText => 'BLE-Verbindung bleibt aktiv';

  @override
  String appSettings_translationModelDeleted(String name) {
    return 'Übersetzungsmodell $name gelöscht';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Kanal konnte nicht aktualisiert werden: $error';
  }

  @override
  String get contact_typeChat => 'Chat';

  @override
  String get contact_typeRepeater => 'Repeater';

  @override
  String get contact_typeRoom => 'Raumserver';

  @override
  String get contact_typeSensor => 'Sensor';

  @override
  String get contact_typeUnknown => 'Unbekannt';

  @override
  String get map_zoomIn => 'Vergrößern';

  @override
  String get map_zoomOut => 'Verkleinern';

  @override
  String get map_centerMap => 'Karte zentrieren';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth benötigt einen Chromium-Browser.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id…';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS bestätigt';

  @override
  String get pathTrace_legendInferred => 'Abgeleitete Position';

  @override
  String get pathMap_viewSingle => 'Einzeln';

  @override
  String get pathMap_viewCombined => 'Kombiniert';

  @override
  String get pathMap_play => 'Abspielen';

  @override
  String get pathMap_pause => 'Pause';

  @override
  String get pathMap_replay => 'Erneut abspielen';

  @override
  String get pathMap_stepBack => 'Vorheriger Sprung';

  @override
  String get pathMap_stepForward => 'Nächster Sprung';

  @override
  String get pathMap_animationOn => 'Paketanimation anzeigen';

  @override
  String get pathMap_animationOff => 'Paketanimation ausblenden';

  @override
  String pathMap_hopOf(int current, int total) {
    return '$current von $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Beobachtete Pfade: $count';
  }

  @override
  String get pathMap_primary => 'Primär';

  @override
  String pathMap_alternate(int index) {
    return 'Alternative $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprünge',
      one: '1 Sprung',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Gemeinsamer Abschnitt';

  @override
  String get pathMap_legendEstimated => 'Geschätzter Abschnitt';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Verwendet von $count Pfaden';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Sprünge haben keinen Standort - der angezeigte Pfad ist unvollständig',
      one:
          '1 Sprung hat keinen Standort - der angezeigte Pfad ist unvollständig',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Alle anzeigen';

  @override
  String get pathMap_hidePath => 'Pfad ausblenden';

  @override
  String get pathMap_showPath => 'Pfad anzeigen';

  @override
  String get pathMap_collapsePanel => 'Panel einklappen';

  @override
  String get pathMap_expandPanel => 'Panel ausklappen';

  @override
  String get pathMap_noLocation => 'Keine Standortdaten';

  @override
  String get pathMap_followPacket => 'Ansicht auf Paket fixieren';

  @override
  String get pathMap_unfollowPacket => 'Fixierung aufheben';
}
