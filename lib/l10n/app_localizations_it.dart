// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Contatti';

  @override
  String get nav_channels => 'Canali';

  @override
  String get nav_map => 'Mappa';

  @override
  String get common_cancel => 'Annulla';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Connetti';

  @override
  String get common_unknownDevice => 'Dispositivo sconosciuto';

  @override
  String get common_save => 'Salva';

  @override
  String get common_delete => 'Elimina';

  @override
  String get common_deleteAll => 'Elimina tutto';

  @override
  String get common_close => 'Chiudi';

  @override
  String get common_done => 'Fatto';

  @override
  String get common_edit => 'Modifica';

  @override
  String get common_add => 'Aggiungi';

  @override
  String get common_settings => 'Impostazioni';

  @override
  String get common_disconnect => 'Disconnetti';

  @override
  String get common_connected => 'Connesso';

  @override
  String get common_disconnected => 'Disconnesso';

  @override
  String get common_create => 'Crea';

  @override
  String get common_continue => 'Continua';

  @override
  String get common_share => 'Condividi';

  @override
  String get common_copy => 'Copia';

  @override
  String get common_retry => 'Riprova';

  @override
  String get common_hide => 'Nascondi';

  @override
  String get common_remove => 'Elimina';

  @override
  String get common_enable => 'Abilita';

  @override
  String get common_disable => 'Disattiva';

  @override
  String get common_undo => 'Annulla';

  @override
  String get messageStatus_sent => 'Inviato';

  @override
  String get messageStatus_delivered => 'Consegnato';

  @override
  String get messageStatus_pending => 'Invio';

  @override
  String get messageStatus_failed => 'Impossibile inviare';

  @override
  String get messageStatus_repeated => 'Ricevuto ripetutamente';

  @override
  String get urlImage_enable => 'Enable URL images';

  @override
  String get urlImage_possible => 'Possible URL image; enable it in Settings.';

  @override
  String get common_reboot => 'Riavvia';

  @override
  String get common_loading => 'Caricamento...';

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
  String get common_autoRefresh => 'Aggiornamento automatico';

  @override
  String get common_interval => 'Intervallo';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Stabilire una connessione tramite TCP';

  @override
  String get tcpHostLabel => 'Indirizzo IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Porta';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Inserisci l\'endpoint e connettiti.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Connessione a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'È necessario fornire un indirizzo IP.';

  @override
  String get tcpErrorPortInvalid =>
      'La dimensione della porta deve essere compresa tra 1 e 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Il protocollo TCP non è supportato su questa piattaforma.';

  @override
  String get tcpErrorTimedOut => 'La connessione TCP è scaduta.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Impossibile stabilire la connessione TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Connessione tramite USB';

  @override
  String get usbScreenSubtitle =>
      'Seleziona il dispositivo seriale rilevato e connettilo direttamente al tuo nodo MeshCore.';

  @override
  String get usbScreenStatus => 'Seleziona un dispositivo USB';

  @override
  String get usbScreenNote =>
      'La comunicazione seriale USB è attiva sui dispositivi Android supportati e sulle piattaforme desktop.';

  @override
  String get usbScreenEmptyState =>
      'Nessun dispositivo USB rilevato. Collegare uno e aggiornare.';

  @override
  String get usbErrorPermissionDenied =>
      'È stato negato l\'accesso tramite USB.';

  @override
  String get usbErrorDeviceMissing =>
      'Il dispositivo USB selezionato non è più disponibile.';

  @override
  String get usbErrorInvalidPort => 'Seleziona un dispositivo USB valido.';

  @override
  String get usbErrorBusy =>
      'Un\'altra richiesta di connessione tramite USB è già in corso.';

  @override
  String get usbErrorNotConnected => 'Non è collegato alcun dispositivo USB.';

  @override
  String get usbErrorOpenFailed =>
      'Impossibile aprire il dispositivo USB selezionato.';

  @override
  String get usbErrorConnectFailed =>
      'Impossibile connettersi al dispositivo USB selezionato.';

  @override
  String get usbErrorUnsupported =>
      'La comunicazione seriale tramite USB non è supportata su questa piattaforma.';

  @override
  String get usbErrorAlreadyActive => 'La connessione USB è già attiva.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Non è stato selezionato alcun dispositivo USB.';

  @override
  String get usbErrorPortClosed => 'La connessione USB non è attiva.';

  @override
  String get usbErrorConnectTimedOut =>
      'La connessione è scaduta. Assicurarsi che il dispositivo abbia il firmware USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Dispositivo per comunicazione seriale su rete';

  @override
  String get usbStatus_notConnected => 'Seleziona un dispositivo USB';

  @override
  String get usbStatus_connecting => 'Connessione al dispositivo USB...';

  @override
  String get usbStatus_searching => 'Ricerca di dispositivi USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Errore nella connessione USB: $error';
  }

  @override
  String get scanner_scanning => 'Scansione in corso per i dispositivi...';

  @override
  String get scanner_connecting => 'Connessione...';

  @override
  String get scanner_disconnecting => 'Disconnessione...';

  @override
  String get scanner_notConnected => 'Non connesso';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Connesso a $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Ricerca dispositivi MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Tocca Scansiona per trovare i dispositivi MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Connessione fallita: $error';
  }

  @override
  String get scanner_stop => 'Ferma';

  @override
  String get scanner_scan => 'Scansiona';

  @override
  String get scanner_bluetoothOff => 'Il Bluetooth è disattivato.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Si prega di attivare il Bluetooth per effettuare la scansione dei dispositivi.';

  @override
  String get scanner_chromeRequired => 'Browser Chrome richiesto';

  @override
  String get scanner_chromeRequiredMessage =>
      'Questa applicazione web richiede Google Chrome o un browser basato su Chromium per il supporto Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Abilita il Bluetooth';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'La funzionalità Bluetooth non è disponibile nel browser. Connettetevi tramite USB invece.';

  @override
  String get device_quickSwitch => 'Passa rapidamente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Impostazioni';

  @override
  String get settings_deviceInfo => 'Informazioni dispositivo';

  @override
  String get settings_appSettings => 'Impostazioni App';

  @override
  String get settings_appSettingsSubtitle =>
      'Notifiche, messaggi e preferenze della mappa';

  @override
  String get settings_nodeSettings => 'Impostazioni Nodo';

  @override
  String get settings_nodeName => 'Nome Nodo';

  @override
  String get settings_nodeNameNotSet => 'Non impostato';

  @override
  String get settings_nodeNameHint => 'Inserisci nome nodo';

  @override
  String get settings_nodeNameUpdated => 'Nome aggiornato';

  @override
  String get settings_radioSettings => 'Impostazioni Radio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequenza, potenza, fattore di diffusione';

  @override
  String get settings_radioSettingsUpdated => 'Impostazioni radio aggiornate';

  @override
  String get settings_regionSettings => 'Regioni';

  @override
  String get settings_regionSettingsSubtitle =>
      'Gestione delle regioni salvate';

  @override
  String get settings_regionManagement_screenTitle => 'Gestione Regionale';

  @override
  String get settings_regionNameHint => 'Inserisci il nome della regione';

  @override
  String get settings_regionAddRegion => 'Aggiungi regione';

  @override
  String get settings_regionFetchRegions =>
      'Recupera le regioni dai ripetitori';

  @override
  String get settings_regionFetchRegionsFail =>
      'Non sono state trovate regioni';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Questa regione è già stata aggiunta';

  @override
  String get settings_regionName => 'Nome della Regione';

  @override
  String get settings_regionDeleted => 'Regione cancellata';

  @override
  String get settings_deleteRegion => 'Elimina Regione';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Rimuovere \"$region\" dalla lista delle regioni?';
  }

  @override
  String get settings_location => 'Posizione';

  @override
  String get settings_locationSubtitle => 'Coordinate GPS';

  @override
  String get settings_locationUpdated =>
      'Posizione e impostazioni GPS aggiornate';

  @override
  String get settings_locationBothRequired =>
      'Inserire sia la latitudine che la longitudine.';

  @override
  String get settings_locationInvalid => 'Latitudine o longitudine non valide.';

  @override
  String get settings_locationGPSEnable => 'Abilita GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Abilita l\'aggiornamento automatico della posizione tramite GPS.';

  @override
  String get settings_locationIntervalSec => 'Intervallo GPS (Secondi)';

  @override
  String get settings_locationIntervalInvalid =>
      'L\'intervallo deve essere di almeno 60 secondi e inferiore a 86400 secondi.';

  @override
  String get settings_latitude => 'Latitudine';

  @override
  String get settings_longitude => 'Longitudine';

  @override
  String get settings_contactSettings => 'Impostazioni di contatto';

  @override
  String get settings_contactSettingsSubtitle =>
      'Impostazioni per l\'aggiunta dei contatti';

  @override
  String get settings_privacyMode => 'Modalità Privacy';

  @override
  String get settings_privacyModeSubtitle =>
      'Nascondere nome/luogo negli annunci';

  @override
  String get settings_privacyModeToggle =>
      'Attiva la modalità privacy per nascondere il tuo nome e la tua posizione negli annunci.';

  @override
  String get settings_privacyModeEnabled => 'Modalità privacy abilitata';

  @override
  String get settings_privacyModeDisabled => 'Modalità privacy disabilitata';

  @override
  String get settings_privacy => 'Impostazioni sulla privacy';

  @override
  String get settings_privacySubtitle =>
      'Controlla le informazioni che vengono condivise.';

  @override
  String get settings_privacySettingsDescription =>
      'Scegli le informazioni che il tuo dispositivo condivide con gli altri.';

  @override
  String get settings_denyAll => 'Negare tutto';

  @override
  String get settings_allowByContact => 'Consenti in base ai flag di contatto';

  @override
  String get settings_allowAll => 'Consenti tutto';

  @override
  String get settings_telemetryBaseMode => 'Modalità di base di telemetria';

  @override
  String get settings_telemetryLocationMode =>
      'Modalità di posizionamento telemetrico';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Modalità di ambiente di telemetria';

  @override
  String get settings_advertLocation => 'Posizione dell\'annuncio';

  @override
  String get settings_advertLocationSubtitle =>
      'Includi la posizione nell\'annuncio';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Annuncio zero-hop automatico all\'aggiornamento GPS';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Quando la posizione GPS cambia, invia un annuncio zero-hop (richiede la posizione nell\'annuncio).';

  @override
  String get settings_multiAck => 'ACK multipli';

  @override
  String get settings_telemetryModeUpdated => 'Modalità telemetria aggiornata';

  @override
  String get settings_actions => 'Azioni';

  @override
  String get settings_deleteAllPaths => 'Elimina tutti i percorsi';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Cancella tutti i dati di percorso dai contatti.';

  @override
  String get settings_sendAdvertisement => 'Invia annuncio';

  @override
  String get settings_sendAdvertisementSubtitle => 'Trasmetti ora la presenza';

  @override
  String get settings_advertisementSent => 'Annuncio inviato';

  @override
  String get settings_syncTime => 'Sincronizza ora';

  @override
  String get settings_syncTimeSubtitle =>
      'Imposta l\'orologio del dispositivo sull\'ora del telefono';

  @override
  String get settings_timeSynchronized => 'Ora sincronizzata';

  @override
  String get settings_refreshContacts => 'Aggiorna contatti';

  @override
  String get settings_refreshContactsSubtitle =>
      'Ricarica l\'elenco dei contatti dal dispositivo';

  @override
  String get settings_rebootDevice => 'Riavvia dispositivo';

  @override
  String get settings_rebootDeviceSubtitle => 'Riavvia il dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Sei sicuro di voler riavviare il dispositivo? Sarai disconnesso.';

  @override
  String get settings_debug => 'Risoluzione dei problemi';

  @override
  String get settings_companionDebugLog => 'Registro di debug per il supporto';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Comandi, risposte e dati grezzi per protocolli BLE/TCP/USB';

  @override
  String get settings_appDebugLog => 'Log di Debug dell\'App';

  @override
  String get settings_appDebugLogSubtitle =>
      'Messaggi di debug dell\'applicazione';

  @override
  String get settings_about => 'Informazioni';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 Progetto open source MeshCore';

  @override
  String get settings_aboutDescription =>
      'Un client Flutter open source per i dispositivi MeshCore di rete mesh LoRa.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Dati di elevazione LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nome';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Stato';

  @override
  String get settings_infoBattery => 'Batteria';

  @override
  String get settings_infoPublicKey => 'Chiave Pubblica';

  @override
  String get settings_infoContactsCount => 'Numero di contatti';

  @override
  String get settings_infoChannelCount => 'Numero di canali';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

  @override
  String get settings_presets => 'Preset';

  @override
  String get settings_frequency => 'Frequenza (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Frequenza non valida (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Larghezza di banda';

  @override
  String get settings_spreadingFactor => 'Fattore di diffusione';

  @override
  String get settings_codingRate => 'Tasso di Codifica';

  @override
  String get settings_txPower => 'Potenza TX (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Potenza TX non valida (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Ripetizione \"fuori dalla rete\"';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permetti a questo dispositivo di ripetere i pacchetti di rete per gli altri.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Per la comunicazione fuori rete, è necessario utilizzare frequenze di 433, 869 o 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Errore: $message';
  }

  @override
  String get appSettings_title => 'Impostazioni App';

  @override
  String get appSettings_appearance => 'Aspetto';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Predefinito del sistema';

  @override
  String get appSettings_themeLight => 'Chiaro';

  @override
  String get appSettings_themeDark => 'Scuro';

  @override
  String get appSettings_language => 'Lingua';

  @override
  String get appSettings_languageSystem => 'Predefinito del sistema';

  @override
  String get appSettings_languageEn => 'Inglese';

  @override
  String get appSettings_languageFr => 'Francese';

  @override
  String get appSettings_languageEs => 'Spagnolo';

  @override
  String get appSettings_languageDe => 'Tedesco';

  @override
  String get appSettings_languagePl => 'Polacco';

  @override
  String get appSettings_languageSl => 'Sloveno';

  @override
  String get appSettings_languagePt => 'Portoghese';

  @override
  String get appSettings_languageIt => 'Italiano';

  @override
  String get appSettings_languageZh => 'Cinese';

  @override
  String get appSettings_languageSv => 'Svedese';

  @override
  String get appSettings_languageNl => 'Olandese';

  @override
  String get appSettings_languageSk => 'Sloveno';

  @override
  String get appSettings_languageBg => 'Bulgaro';

  @override
  String get appSettings_languageRu => 'Russo';

  @override
  String get appSettings_languageUk => 'Ucraino';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 byte';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 byte';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 byte';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 byte';

  @override
  String get appSettings_enableMessageTracing =>
      'Abilita tracciamento messaggi';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostra metadati dettagliati su instradamento e tempi per i messaggi';

  @override
  String get appSettings_notifications => 'Notifiche';

  @override
  String get appSettings_enableNotifications => 'Abilita Notifiche';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Ricevi notifiche per messaggi e annunci';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permesso di notifica negato';

  @override
  String get appSettings_notificationsEnabled => 'Notifiche abilitate';

  @override
  String get appSettings_notificationsDisabled => 'Notifiche disattivate';

  @override
  String get appSettings_messageNotifications => 'Notifiche Messaggi';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostra notifica all\'arrivo di nuovi messaggi';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notifiche Messaggi Canale';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostra notifica all\'arrivo di messaggi nel canale';

  @override
  String get appSettings_advertisementNotifications =>
      'Notifiche Pubblicitarie';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostra notifica quando vengono scoperti nuovi nodi';

  @override
  String get appSettings_messaging => 'Messaggi';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Cancella percorso al massimo dei tentativi';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Reimposta il percorso di contatto dopo 5 tentativi di invio falliti';

  @override
  String get appSettings_pathsWillBeCleared =>
      'I percorsi verranno cancellati dopo 5 tentativi falliti.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'I percorsi non verranno cancellati automaticamente.';

  @override
  String get appSettings_autoRouteRotation => 'Rotazione Percorso Automatico';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Alterna tra i percorsi migliori e la modalità flood';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Rotazione percorso automatico abilitata';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Rotazione del percorso automatico disabilitata';

  @override
  String get appSettings_maxRouteWeight =>
      'Massimo peso consentito per il percorso';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Il peso massimo che un percorso può accumulare grazie a consegne di successo.';

  @override
  String get appSettings_initialRouteWeight => 'Peso iniziale del percorso';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Peso di partenza per nuovi percorsi';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Aumento del peso del successo';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Peso aggiunto a un percorso dopo una consegna riuscita.';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Riduzione del peso associato al fallimento';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Peso rimosso da un percorso dopo un tentativo di consegna fallito.';

  @override
  String get appSettings_maxMessageRetries =>
      'Numero massimo di tentativi di invio del messaggio';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Numero di tentativi di riprova prima di considerare un messaggio come fallito.';

  @override
  String get appSettings_battery => 'Batteria';

  @override
  String get appSettings_batteryChemistry => 'Chimica della batteria';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Impostazione per dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Connetti a un dispositivo per scegliere';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_batteryLipoHv => 'LiPo HV (3,0-4,35 V)';

  @override
  String get appSettings_mapDisplay => 'Visualizzazione Mappa';

  @override
  String get appSettings_showRepeaters => 'Mostra Ripetitori';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Mostra i nodi ripetitori sulla mappa';

  @override
  String get appSettings_showChatNodes => 'Mostra Nodi Chat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Mostra i nodi di chat sulla mappa';

  @override
  String get appSettings_showOtherNodes => 'Mostra altri nodi';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mostra altri tipi di nodo sulla mappa';

  @override
  String get appSettings_timeFilter => 'Filtro Temporale';

  @override
  String get appSettings_timeFilterShowAll => 'Mostra tutti i nodi';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostra i nodi delle ultime $hours ore';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro Tempo Mappa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostra i nodi scoperti all\'interno di:';

  @override
  String get appSettings_allTime => 'Tutto il tempo';

  @override
  String get appSettings_lastHour => 'Ultima ora';

  @override
  String get appSettings_last6Hours => 'Ultimi 6 ore';

  @override
  String get appSettings_last24Hours => 'Ultime 24 ore';

  @override
  String get appSettings_lastWeek => 'La settimana scorsa';

  @override
  String get appSettings_rasterTileSource => 'Sorgente tile raster';

  @override
  String get appSettings_stadiaEndpoint => 'Endpoint Stadia';

  @override
  String get appSettings_stadiaApiKey => 'Chiave API Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Obbligatoria per usare Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Configurata: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Inserisci la chiave API di Stadia Maps. Questa app la usa per le richieste di tile raster.';

  @override
  String get appSettings_offlineMapCache => 'Cache Mappa Offline';

  @override
  String get appSettings_unitsTitle => 'Unità';

  @override
  String get appSettings_unitsMetric => 'Metrico (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiale (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Nessun\'area selezionata';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Area selezionata (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Risoluzione dei problemi';

  @override
  String get appSettings_appDebugLogging => 'Registrazione Debug App';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Registra i messaggi di debug dell\'app per la risoluzione dei problemi';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Registrazione di debug dell\'app abilitata';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Registrazione di debug dell\'app disabilitata';

  @override
  String get contacts_title => 'Contatti';

  @override
  String get contacts_noContacts => 'Nessun contatto ancora';

  @override
  String get contacts_contactsWillAppear =>
      'I contatti appariranno quando i dispositivi si annunciano.';

  @override
  String get contacts_unread => 'Non letti';

  @override
  String get contacts_searchContactsNoNumber => 'Cerca contatti...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Cerca contatti...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Cerca $number$str preferiti...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Cerca $number$str utenti...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Cerca $number$str ripetitori...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Cerca $number$str server stanza...';
  }

  @override
  String get contacts_noUnreadContacts => 'Nessun contatto non letto';

  @override
  String get contacts_noContactsFound => 'Nessun contatto o gruppo trovato.';

  @override
  String get contacts_deleteContact => 'Elimina Contatto';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Eliminare $contactName dai contatti?';
  }

  @override
  String get contacts_manageRepeater => 'Gestisci ripetitore';

  @override
  String get contacts_manageRoom => 'Gestisci server stanza';

  @override
  String get contacts_roomLogin => 'Accesso server stanza';

  @override
  String get contacts_openChat => 'Apri chat';

  @override
  String get contacts_editGroup => 'Modifica gruppo';

  @override
  String get contacts_deleteGroup => 'Elimina gruppo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eliminare \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Nuovo gruppo';

  @override
  String get contacts_moreOptions => 'Ulteriori opzioni';

  @override
  String get contacts_searchOpen => 'Apri ricerca';

  @override
  String get contacts_searchClose => 'Chiudi ricerca';

  @override
  String get contacts_groupName => 'Nome gruppo';

  @override
  String get contacts_groupNameRequired => 'Il nome del gruppo è obbligatorio.';

  @override
  String get contacts_groupNameReserved => 'Questo nome del gruppo è riservato';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Il gruppo \"$name\" esiste già.';
  }

  @override
  String get contacts_filterContacts => 'Filtra i contatti...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Nessun contatto corrisponde al tuo filtro';

  @override
  String get contacts_noMembers => 'Nessun membro';

  @override
  String get contacts_lastSeenNow => 'Poco fa';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Ultimo visto $minutes minuti fa';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Ultimo visto 1 ora fa';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Ultimo visto $hours ore fa';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Ultimo visto 1 giorno fa';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Ultimo visto $days giorni fa';
  }

  @override
  String get contact_info => 'Informazioni di Contatto';

  @override
  String get contact_settings => 'Impostazioni di contatto';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Ultimo accesso';

  @override
  String get contact_clearChat => 'Cancella chat';

  @override
  String get contact_teleBase => 'Base di telemetria';

  @override
  String get contact_teleBaseSubtitle =>
      'Consenti la condivisione del livello della batteria e della telemetria di base';

  @override
  String get contact_teleLoc => 'Posizione telemetria';

  @override
  String get contact_teleLocSubtitle =>
      'Consenti la condivisione dei dati di posizione';

  @override
  String get contact_teleEnv => 'Ambiente di telemetria';

  @override
  String get contact_teleEnvSubtitle =>
      'Consenti la condivisione dei dati del sensore ambientale';

  @override
  String get channels_title => 'Canali';

  @override
  String get channels_noChannelsConfigured => 'Nessun canale configurato';

  @override
  String get channels_addPublicChannel => 'Aggiungi Canale Pubblico';

  @override
  String get channels_searchChannels => 'Cerca canali...';

  @override
  String get channels_noChannelsFound => 'Nessun canale trovato';

  @override
  String channels_channelIndex(int index) {
    return 'Canale $index';
  }

  @override
  String get channels_public => 'Pubblico';

  @override
  String channels_via(String path) {
    return 'tramite $path';
  }

  @override
  String get channels_private => 'Privato';

  @override
  String get channels_editChannel => 'Modifica canale';

  @override
  String get channels_muteChannel => 'Silenzia canale';

  @override
  String get channels_unmuteChannel => 'Attiva notifiche canale';

  @override
  String get channels_deleteChannel => 'Elimina canale';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Eliminare \"$name\"? Non può essere annullato.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Impossibile eliminare il canale \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canale \"$name\" eliminato';
  }

  @override
  String get channels_addChannel => 'Aggiungi canale';

  @override
  String get channels_channelIndexLabel => 'Indice canale';

  @override
  String get channels_channelName => 'Nome canale';

  @override
  String get channels_usePublicChannel => 'Usa il canale pubblico';

  @override
  String get channels_standardPublicPsk => 'PSK pubblico standard';

  @override
  String get channels_pskHex => 'PSK (esadecimale)';

  @override
  String get channels_generateRandomPsk => 'Genera una PSK casuale';

  @override
  String get channels_enterChannelName => 'Inserisci un nome per il canale';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK deve essere composto da 32 caratteri esadecimali.';

  @override
  String channels_channelAdded(String name) {
    return 'Canale \"$name\" aggiunto';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Modifica Canale $index';
  }

  @override
  String get channels_smazCompression => 'Compressione SMAZ';

  @override
  String get channels_cyr2latCompression => 'Compressione Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Sostituisce alcuni caratteri cirillici con caratteri latini durante l\'invio.';

  @override
  String get channels_cyr2latSettingsHeading => 'Impostazioni Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Elenco delle sostituzioni';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Modifica la configurazione JSON delle sostituzioni dei caratteri';

  @override
  String get channels_cyr2latSettingsDialogHint =>
      'Mappa JSON delle sostituzioni';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'JSON non corretto: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Canale \"$name\" aggiornato';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Aggiungi profilo Cyr2Lat';

  @override
  String get settings_cyr2latProfileName => 'Nome profilo';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'Il nome del profilo non può essere vuoto';

  @override
  String get settings_cyr2latProfileAdded => 'Profilo aggiunto con successo';

  @override
  String get settings_cyr2latProfileUpdated =>
      'Profilo aggiornato con successo';

  @override
  String get settings_cyr2latProfileEdit => 'Modifica profilo Cyr2Lat';

  @override
  String get settings_cyr2latProfileDelete => 'Elimina profilo Cyr2Lat';

  @override
  String get settings_cyr2latProfileDeleted => 'Profilo eliminato con successo';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Sei sicuro di voler eliminare il profilo \"$name\"?';
  }

  @override
  String get channels_publicChannelAdded => 'Canale pubblico aggiunto';

  @override
  String get channels_sortBy => 'Ordina per';

  @override
  String get channels_sortManual => 'Manuale';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Ultimi messaggi';

  @override
  String get channels_sortUnread => 'Non letto';

  @override
  String get channels_createPrivateChannel => 'Crea un Canale Privato';

  @override
  String get channels_createPrivateChannelDesc =>
      'Protetta con una chiave segreta.';

  @override
  String get channels_joinPrivateChannel => 'Unisciti a un Canale Privato';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Inserire manualmente una chiave segreta.';

  @override
  String get channels_joinPublicChannel => 'Unisciti al Canale Pubblico';

  @override
  String get channels_joinPublicChannelDesc =>
      'Chiunque può unirsi a questo canale.';

  @override
  String get channels_joinHashtagChannel => 'Unisciti a un Canale con Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Chiunque può unirsi ai canali hashtag.';

  @override
  String get channels_scanQrCode => 'Scansiona un codice QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Arriverà presto';

  @override
  String get channels_enterHashtag => 'Inserisci hashtag';

  @override
  String get channels_hashtagHint => 'es. #team';

  @override
  String channels_regionSetTo(String region) {
    return 'Regione: $region';
  }

  @override
  String get channels_regionNotSet => 'Regione: nessuna';

  @override
  String get channels_regionSelect_Title => 'Scegli una regione';

  @override
  String get channels_clearRegion => 'Zona chiara';

  @override
  String get chat_noMessages => 'Nessun messaggio ancora';

  @override
  String get chat_sendMessage => 'Invia messaggio';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Invia un messaggio a $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Invia un messaggio per iniziare';

  @override
  String get chat_originalMessageNotFound => 'Messaggio originale non trovato';

  @override
  String chat_replyingTo(String name) {
    return 'Rispondere a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Rispondi a $name';
  }

  @override
  String get chat_location => 'Posizione';

  @override
  String get chat_typeMessage => 'Digita un messaggio...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Messaggio troppo lungo (massimo $maxBytes byte).';
  }

  @override
  String get chat_messageCopied => 'Messaggio copiato';

  @override
  String get chat_messageDeleted => 'Messaggio eliminato';

  @override
  String get chat_retryingMessage => 'Riprovo';

  @override
  String chat_retryCount(int current, int max) {
    return 'Riprova $current/$max';
  }

  @override
  String get chat_sendGif => 'Invia GIF';

  @override
  String get chat_sendImage => 'Invia immagine';

  @override
  String get chat_imagePickFailed =>
      'Non sono riuscito ad aprire quell\'immagine';

  @override
  String get chat_receivedGif => 'Ricevuto un GIF';

  @override
  String get chat_reply => 'Rispondi';

  @override
  String get chat_addReaction => 'Aggiungi Reazione';

  @override
  String get chat_me => 'Io';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gesti';

  @override
  String get emojiCategoryHearts => 'Cuori';

  @override
  String get emojiCategoryObjects => 'Oggetti';

  @override
  String get gifPicker_title => 'Scegli un GIF';

  @override
  String get gifPicker_searchHint => 'Cerca GIF...';

  @override
  String get gifPicker_poweredBy => 'Potenziato da GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nessun GIF trovato';

  @override
  String get gifPicker_failedLoad => 'Impossibile caricare i GIF';

  @override
  String get gifPicker_failedSearch => 'Impossibile trovare GIF';

  @override
  String get gifPicker_noInternet => 'Nessuna connessione internet';

  @override
  String get debugLog_appTitle => 'Log di Debug dell\'App';

  @override
  String get debugLog_bleTitle => 'Log di Debug BLE';

  @override
  String get debugLog_copyLog => 'Copia log';

  @override
  String get debugLog_clearLog => 'Cancella log';

  @override
  String get debugLog_copied => 'Log di debug copiato';

  @override
  String get debugLog_bleCopied => 'Log BLE copiato';

  @override
  String get debugLog_noEntries => 'Non ci sono ancora log di debug.';

  @override
  String get debugLog_enableInSettings =>
      'Abilita il logging di debug dell\'app nelle impostazioni';

  @override
  String get debugLog_frames => 'Frame';

  @override
  String get debugLog_rawLogRx => 'Log Raw-RX';

  @override
  String get debugLog_noBleActivity => 'Nessuna attività BLE rilevata ancora.';

  @override
  String debugFrame_length(int count) {
    return 'Lunghezza del Frame: $count byte';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Messaggio di testo:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Chiave pubblica di destinazione: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Marca temporale: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flag: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return 'Tipo di testo: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Semplice';

  @override
  String debugFrame_text(String text) {
    return '- Testo: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Dumpa Esadecimale:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'salti',
      one: 'salto',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Rimuovi percorso';

  @override
  String get chat_noPathHistoryYet =>
      'Non c\'è ancora una cronologia del percorso.\nInvia un messaggio per scoprire i percorsi.';

  @override
  String get chat_pathCleared =>
      'Percorso cancellato. Il prossimo messaggio riscoprirà il percorso.';

  @override
  String get chat_fullPath => 'Percorso Completo';

  @override
  String get routing_title => 'Instradamento';

  @override
  String get routing_modeAuto => 'Automatico';

  @override
  String get routing_modeFlood => 'Flood';

  @override
  String get routing_modeManual => 'Manuale';

  @override
  String get routing_modeAutoHint =>
      'Seleziona automaticamente il percorso migliore noto, ricorrendo al flood quando non ne è noto nessuno.';

  @override
  String get routing_modeFloodHint =>
      'Trasmette tramite ogni ripetitore. È il più affidabile, ma usa più airtime.';

  @override
  String get routing_modeManualHint =>
      'Invia sempre lungo il percorso esatto che hai definito.';

  @override
  String get routing_currentRoute => 'Percorso attuale';

  @override
  String get routing_directNoHops =>
      'Diretto — nessun salto tramite ripetitore';

  @override
  String get routing_noPathYet =>
      'Nessun percorso ancora. Il prossimo messaggio userà il flood finché non viene scoperto un percorso.';

  @override
  String get routing_floodBroadcast => 'Trasmissione tramite ogni ripetitore';

  @override
  String get routing_editPath => 'Modifica percorso';

  @override
  String get routing_forgetPath => 'Dimentica percorso';

  @override
  String get routing_knownPaths => 'Percorsi noti';

  @override
  String get routing_knownPathsHint =>
      'Tocca un percorso per passare a quello.';

  @override
  String get routing_inUse => 'In uso';

  @override
  String get routing_qualityStrong => 'Primo hop forte';

  @override
  String get routing_qualityGood => 'Primo hop buono';

  @override
  String get routing_qualityFair => 'Primo hop discreto';

  @override
  String get routing_qualityWorked => 'Ha consegnato';

  @override
  String get routing_qualityFlood => 'Ricevuto via flood';

  @override
  String get routing_qualityUntested => 'Non testato';

  @override
  String routing_lastWorked(String when) {
    return 'ha funzionato $when';
  }

  @override
  String get routing_neverWorked => 'mai confermato';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes consegnati, $failures falliti';
  }

  @override
  String get routing_floodDelivery => 'Consegna flood';

  @override
  String get pathEditor_title => 'Crea percorso';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count su 64 salti';
  }

  @override
  String get pathEditor_noHops =>
      'Nessun salto ancora. Tocca i ripetitori qui sotto per aggiungerli in ordine, oppure salva senza salti per inviare direttamente.';

  @override
  String get pathEditor_addHops => 'Aggiungi salti in ordine';

  @override
  String get pathEditor_searchRepeaters => 'Cerca ripetitori';

  @override
  String get pathEditor_advancedHex => 'Avanzato: percorso esadecimale grezzo';

  @override
  String get pathEditor_hexLabel => 'Prefissi esadecimali';

  @override
  String get pathEditor_hexHelper =>
      'Due caratteri esadecimali per ogni salto, separati da virgole.';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Non valido: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Massimo 64 salti';

  @override
  String get pathEditor_usePath => 'Utilizza questo percorso';

  @override
  String get pathEditor_removeHop => 'Rimuovi salto';

  @override
  String get pathEditor_unknownHop => 'Ripetitore sconosciuto';

  @override
  String get chat_pathSavedLocally =>
      'Salvato localmente. Connettiti per sincronizzare.';

  @override
  String get chat_pathDeviceConfirmed => 'Dispositivo confermato.';

  @override
  String get chat_pathDeviceNotConfirmed =>
      'Dispositivo non confermato ancora.';

  @override
  String get chat_type => 'Tipo';

  @override
  String get chat_path => 'Percorso';

  @override
  String get chat_publicKey => 'Chiave pubblica';

  @override
  String get chat_compressOutgoingMessages => 'Comprimi messaggi in uscita';

  @override
  String get chat_floodForced => 'Flood (forzato)';

  @override
  String get chat_directForced => 'Diretto (forzato)';

  @override
  String chat_hopsForced(int count) {
    return '$count salti (forzati)';
  }

  @override
  String get chat_floodAuto => 'Flood (automatico)';

  @override
  String get chat_direct => 'Diretto';

  @override
  String get chat_poiShared => 'POI condiviso';

  @override
  String chat_unread(int count) {
    return 'Non letti: $count';
  }

  @override
  String get chat_markAsUnread => 'Segna come non letto';

  @override
  String get chat_newMessages => 'Nuovi messaggi';

  @override
  String get chat_openLink => 'Apri il link?';

  @override
  String get chat_openLinkConfirmation =>
      'Vuoi aprire questo link nel tuo browser?';

  @override
  String get chat_open => 'Apri';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Impossibile aprire il link: $url';
  }

  @override
  String get chat_invalidLink => 'Formato di link non valido';

  @override
  String get map_title => 'Mappa nodi';

  @override
  String get map_searchHint => 'Cerca il nome o l\'ID del nodo';

  @override
  String get map_activity => 'Attività';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Recente';

  @override
  String get map_stale => 'Obsoleto';

  @override
  String get map_visible => 'Visibile';

  @override
  String get map_hidden => 'Nascosto';

  @override
  String get map_centerOnNode => 'Centra sul nodo';

  @override
  String get map_details => 'Dettagli';

  @override
  String get map_noGps => 'Senza GPS';

  @override
  String get map_noResults => 'Nessun nodo corrispondente trovato.';

  @override
  String get map_lineOfSight => 'Linea di vista';

  @override
  String get map_losScreenTitle => 'Linea di vista';

  @override
  String get map_noNodesWithLocation => 'Nessun nodo con dati di posizione';

  @override
  String get map_nodesNeedGps =>
      'I nodi devono condividere le loro coordinate GPS\nper apparire sulla mappa';

  @override
  String map_nodesCount(int count) {
    return 'Nodi: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pin: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Ripetitore';

  @override
  String get map_room => 'Stanza';

  @override
  String get map_sensor => 'Sensore';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Pin (Privato)';

  @override
  String get map_pinPublic => 'Pin (Pubblico)';

  @override
  String get map_lastSeen => 'Ultimo visto';

  @override
  String get map_disconnectConfirm =>
      'Sei sicuro di voler disconnetterti da questo dispositivo?';

  @override
  String get map_from => 'Da';

  @override
  String get map_source => 'Fonte';

  @override
  String get map_flags => 'Bandiere';

  @override
  String get map_type => 'Tipo';

  @override
  String get map_path => 'Percorso';

  @override
  String get map_location => 'Posizione';

  @override
  String get map_estLocation => 'Posizione stimata';

  @override
  String get map_publicKey => 'Chiave pubblica';

  @override
  String get map_publicKeyPrefixHint => 'es. ab12';

  @override
  String get map_shareMarkerHere => 'Condividi segnaposto qui';

  @override
  String get map_setAsMyLocation => 'Imposta come la mia posizione';

  @override
  String get map_pinLabel => 'Etichetta pin';

  @override
  String get map_label => 'Etichetta';

  @override
  String get map_pointOfInterest => 'Punto di interesse';

  @override
  String get map_sendToContact => 'Invia a contatto';

  @override
  String get map_sendToChannel => 'Invia al canale';

  @override
  String get map_noChannelsAvailable => 'Nessun canale disponibile';

  @override
  String get map_publicLocationShare => 'Condivisione pubblica della posizione';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Stai per condividere una posizione in $channelLabel. Questo canale è pubblico e chiunque abbia la PSK può vederlo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Connettiti a un dispositivo per condividere i segnaposti';

  @override
  String get map_filterNodes => 'Filtra nodi';

  @override
  String get map_nodeTypes => 'Tipi di nodo';

  @override
  String get map_chatNodes => 'Nodi chat';

  @override
  String get map_repeaters => 'Ripetitori';

  @override
  String get map_otherNodes => 'Altri nodi';

  @override
  String get map_showOverlaps => 'Sovrapposizioni chiave ripetitore';

  @override
  String get map_keyPrefix => 'Prefisso chiave';

  @override
  String get map_filterByKeyPrefix => 'Filtra per prefisso chiave';

  @override
  String get map_publicKeyPrefix => 'Prefisso chiave pubblica';

  @override
  String get map_markers => 'Segnaposti';

  @override
  String get map_showSharedMarkers => 'Mostra segnaposti condivisi';

  @override
  String get map_showGuessedLocations => 'Mostra le posizioni stimate dei nodi';

  @override
  String get map_showDiscoveryContacts => 'Mostra contatti di scoperta';

  @override
  String get map_guessedLocation => 'Posizione stimata';

  @override
  String get map_lastSeenTime => 'Ora dell\'ultimo visto';

  @override
  String get map_sharedPin => 'Pin condiviso';

  @override
  String get map_sharedAt => 'Condiviso';

  @override
  String get map_joinRoom => 'Unisciti alla stanza';

  @override
  String get map_manageRepeater => 'Gestisci ripetitore';

  @override
  String get map_tapToAdd => 'Tocca i nodi per aggiungerli al percorso.';

  @override
  String get map_runTrace => 'Esegui tracciamento percorso';

  @override
  String get map_runTraceWithReturnPath => 'Ritorna lungo lo stesso percorso.';

  @override
  String get map_removeLast => 'Rimuovi ultimo';

  @override
  String get map_pathTraceCancelled => 'Tracciamento del percorso annullato.';

  @override
  String get mapCache_title => 'Cache mappa offline';

  @override
  String get mapCache_selectAreaFirst =>
      'Seleziona un\'area da memorizzare nella cache per prima.';

  @override
  String get mapCache_noTilesToDownload =>
      'Nessun tile da scaricare per questa area';

  @override
  String get mapCache_downloadTilesTitle => 'Scarica tessere';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Scarica $count tile per l\'uso offline?';
  }

  @override
  String get mapCache_downloadAction => 'Scarica';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Tessere memorizzate nella cache: $count';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Tessere memorizzate nella cache $downloaded ($failed fallite)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Cancella cache offline';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Eliminare tutte le tile di mappa memorizzate nella cache?';

  @override
  String get mapCache_offlineCacheCleared => 'Cache offline eliminata';

  @override
  String get mapCache_noAreaSelected => 'Nessun\'area selezionata';

  @override
  String get mapCache_cacheArea => 'Area cache';

  @override
  String get mapCache_useCurrentView => 'Utilizza la visualizzazione corrente';

  @override
  String get mapCache_zoomRange => 'Intervallo zoom';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Tessere stimate: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Scaricati $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Scarica tessere';

  @override
  String get mapCache_clearCacheButton => 'Svuota cache';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Download falliti: $count';
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
  String get time_justNow => 'Proprio ora';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minuti fa';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String time_daysAgo(int days) {
    return '$days giorni fa';
  }

  @override
  String get time_hour => 'ora';

  @override
  String get time_hours => 'ore';

  @override
  String get time_day => 'giorno';

  @override
  String get time_days => 'giorni';

  @override
  String get time_week => 'settimana';

  @override
  String get time_weeks => 'settimane';

  @override
  String get time_month => 'mese';

  @override
  String get time_months => 'mesi';

  @override
  String get time_minutes => 'minuti';

  @override
  String get time_allTime => 'Sempre';

  @override
  String get dialog_disconnect => 'Disconnetti';

  @override
  String get dialog_disconnectConfirm =>
      'Sei sicuro di voler disconnetterti da questo dispositivo?';

  @override
  String get login_repeaterLogin => 'Accesso ripetitore';

  @override
  String get login_roomLogin => 'Accesso server stanza';

  @override
  String get login_password => 'Password';

  @override
  String get login_enterPassword => 'Inserisci password';

  @override
  String get login_savePassword => 'Salva password';

  @override
  String get login_savePasswordSubtitle =>
      'La password verrà memorizzata in modo sicuro su questo dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Inserisci la password del ripetitore per accedere alle impostazioni e allo stato.';

  @override
  String get login_roomDescription =>
      'Inserisci la password della stanza per accedere alle impostazioni e allo stato.';

  @override
  String get login_routing => 'Instradamento';

  @override
  String get login_routingMode => 'Modalità di routing';

  @override
  String get login_autoUseSavedPath => 'Utilizza il percorso salvato';

  @override
  String get login_forceFloodMode => 'Modalità flood forzata';

  @override
  String get login_managePaths => 'Gestisci percorsi';

  @override
  String get login_login => 'Accedi';

  @override
  String login_attempt(int current, int max) {
    return 'Prova $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Accesso fallito: $error';
  }

  @override
  String get login_failedMessage =>
      'Accesso fallito. La password non è corretta oppure il ripetitore non è raggiungibile.';

  @override
  String get common_reload => 'Ricarica';

  @override
  String get common_clear => 'Cancella';

  @override
  String get path_currentPathLabel => 'Percorso corrente';

  @override
  String get path_noRepeatersFound =>
      'Non sono stati trovati ripetitori o server stanza.';

  @override
  String get repeater_management => 'Gestione ripetitori';

  @override
  String get room_management => 'Gestione del Server di Camera';

  @override
  String get repeater_guest => 'Informazioni sul ripetitore';

  @override
  String get room_guest => 'Informazioni sul server';

  @override
  String get repeater_managementTools => 'Strumenti di gestione';

  @override
  String get repeater_guestTools => 'Strumenti per gli ospiti';

  @override
  String get repeater_status => 'Stato';

  @override
  String get repeater_statusSubtitle =>
      'Visualizza lo stato, le statistiche e i vicini del ripetitore';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Visualizza i dati di telemetria dei sensori e le statistiche di sistema';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Invia comandi al ripetitore';

  @override
  String get repeater_neighbors => 'Vicini';

  @override
  String get repeater_neighborsSubtitle => 'Visualizza vicini a salto zero.';

  @override
  String get repeater_settings => 'Impostazioni';

  @override
  String get repeater_settingsSubtitle =>
      'Configura i parametri del ripetitore';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Sincronizzazione dell\'orologio dopo il login';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Invia automaticamente il comando \"sincronizzazione dell\'orologio\" dopo un login riuscito.';

  @override
  String get repeater_statusTitle => 'Stato del ripetitore';

  @override
  String get repeater_routingMode => 'Modalità di routing';

  @override
  String get repeater_refresh => 'Aggiorna';

  @override
  String get repeater_statusRequestTimeout => 'Richiesta stato scaduta.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Errore nel caricamento dello stato: $error';
  }

  @override
  String get repeater_systemInformation => 'Informazioni di sistema';

  @override
  String get repeater_battery => 'Batteria';

  @override
  String get repeater_clockAtLogin => 'Orologio (all\'accesso)';

  @override
  String get repeater_uptime => 'Tempo di attività';

  @override
  String get repeater_queueLength => 'Lunghezza coda';

  @override
  String get repeater_debugFlags => 'Flag di debug';

  @override
  String get repeater_radioStatistics => 'Statistiche radio';

  @override
  String get repeater_lastRssi => 'Ultimo RSSI';

  @override
  String get repeater_lastSnr => 'Ultimo SNR';

  @override
  String get repeater_noiseFloor => 'Rumore di fondo';

  @override
  String get repeater_txAirtime => 'Tempo d\'aria TX';

  @override
  String get repeater_rxAirtime => 'Tempo d\'aria RX';

  @override
  String get repeater_chanUtil => 'Utilizzo del canale';

  @override
  String get repeater_packetStatistics => 'Statistiche pacchetti';

  @override
  String get repeater_sent => 'Inviato';

  @override
  String get repeater_received => 'Ricevuto';

  @override
  String get repeater_duplicates => 'Duplicati';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days giorni ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Totale: $total, Flood: $flood, Diretto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Totale: $total, Flood: $flood, Diretto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Diretto: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Totale: $total';
  }

  @override
  String get repeater_settingsTitle => 'Impostazioni Ripetitore';

  @override
  String get repeater_basicSettings => 'Impostazioni di Base';

  @override
  String get repeater_repeaterName => 'Nome Ripetitore';

  @override
  String get repeater_repeaterNameHelper =>
      'Nome visualizzato per questo ripetitore';

  @override
  String get repeater_adminPassword => 'Password amministratore';

  @override
  String get repeater_adminPasswordHelper => 'Password per accesso completo';

  @override
  String get repeater_guestPassword => 'Password ospite';

  @override
  String get repeater_guestPasswordHelper =>
      'Password per accesso in sola lettura';

  @override
  String get repeater_radioSettings => 'Impostazioni Radio';

  @override
  String get repeater_frequencyMhz => 'Frequenza (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'Potenza TX';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Larghezza di banda';

  @override
  String get repeater_spreadingFactor => 'Fattore di diffusione';

  @override
  String get repeater_codingRate => 'Tasso di Codifica';

  @override
  String get repeater_locationSettings => 'Impostazioni posizione';

  @override
  String get repeater_latitude => 'Latitudine';

  @override
  String get repeater_latitudeHelper => 'Grado decimale (ad esempio, 37.7749)';

  @override
  String get repeater_longitude => 'Longitudine';

  @override
  String get repeater_longitudeHelper =>
      'Grado decimale (ad esempio, -122,4194)';

  @override
  String get repeater_features => 'Caratteristiche';

  @override
  String get repeater_packetForwarding => 'Inoltro pacchetti';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Abilita il ripetitore per inoltrare i pacchetti';

  @override
  String get repeater_guestAccess => 'Accesso ospite';

  @override
  String get repeater_guestAccessSubtitle =>
      'Consenti l\'accesso ospite in sola lettura';

  @override
  String get repeater_privacyMode => 'Modalità Privacy';

  @override
  String get repeater_privacyModeSubtitle =>
      'Nascondi nome/posizione negli annunci';

  @override
  String get repeater_advertisementSettings => 'Impostazioni annuncio';

  @override
  String get repeater_localAdvertInterval => 'Intervallo annuncio locale';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minuti';
  }

  @override
  String get repeater_floodAdvertInterval => 'Intervallo annuncio flood';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours ore';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervallo annuncio crittografato';

  @override
  String get repeater_dangerZone => 'Zona Pericolosa';

  @override
  String get repeater_rebootRepeater => 'Riavvia Ripetitore';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Riavvia il dispositivo ripetitore';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Sei sicuro di voler riavviare questo ripetitore?';

  @override
  String get repeater_regenerateIdentityKey => 'Rigenera Chiave Identità';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Genera una nuova coppia di chiavi pubblica/privata';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Questo genererà una nuova identità per il ripetitore. Procedere?';

  @override
  String get repeater_eraseFileSystem => 'Elimina File System';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatta il file system del ripetitore';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ATTENZIONE: Ciò cancellerà tutti i dati sul ripetitore. Non può essere annullato!';

  @override
  String get repeater_eraseSerialOnly =>
      'Elimina è disponibile solo tramite console seriale.';

  @override
  String repeater_commandSent(String command) {
    return 'Comando inviato: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Errore nell\'invio del comando: $error';
  }

  @override
  String get repeater_confirm => 'Conferma';

  @override
  String get repeater_settingsSaved => 'Impostazioni salvate con successo';

  @override
  String get repeater_rxGain => 'Aumento del guadagno RX';

  @override
  String get repeater_rxGainHelper =>
      'Maggiore sensibilità, maggiore assorbimento di corrente (solo per SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain => 'Rafforza l\'effetto di RX';

  @override
  String get repeater_multiAcks => 'ACK multipli';

  @override
  String get repeater_multiAcksSubtitle =>
      'Riconoscere i messaggi attraverso percorsi multipli per una migliore consegna.';

  @override
  String get repeater_refreshMultiAcks => 'Riaffermare più ACK';

  @override
  String get repeater_networkHealth => 'Salute della rete';

  @override
  String get repeater_loopDetect => 'Rilevamento di cicli';

  @override
  String get repeater_loopDetectHelper =>
      'Crea pacchetti di dati che simulano loop di routing.';

  @override
  String get repeater_loopDetectOff => 'Offerte';

  @override
  String get repeater_loopDetectMinimal => 'Essenziale';

  @override
  String get repeater_loopDetectModerate => 'Moderato';

  @override
  String get repeater_loopDetectStrict => 'Rigido';

  @override
  String get repeater_dutyCycle => 'Ciclo di lavoro';

  @override
  String get repeater_dutyCycleHelper =>
      'Percentuale massima di utilizzo dello spazio pubblicitario';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Informazioni sull\'operatore';

  @override
  String get repeater_ownerInfoHelper =>
      'Metadati pubblici per questo ripetitore';

  @override
  String get repeater_refreshOwnerInfo =>
      'Aggiorna le informazioni sull\'operatore';

  @override
  String get repeater_floodMax =>
      'Massimo numero di salti in caso di inondazione';

  @override
  String get repeater_floodMaxHelper =>
      'Numero massimo di pacchetti che un flusso può attraversare (0-64)';

  @override
  String get repeater_advancedSettings => 'Avanzato';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Manopole di regolazione per operatori esperti';

  @override
  String get repeater_pathHashMode => 'Modalità di hashing del percorso';

  @override
  String get repeater_pathHashModeHelper =>
      'Byte utilizzati per codificare l\'ID di questo ripetitore nei tag di percorso flood/rilevamento loop. 0=1 byte (256 ID, fino a 64 salti), 1=2 byte (65.000 ID, fino a 32 salti), 2=3 byte (16 milioni di ID, fino a 21 salti). Il firmware precedente alla v1.14 usava sempre percorsi a 1 byte; v1.14 e versioni successive possono essere configurate per percorsi a 2 o 3 byte.';

  @override
  String get repeater_keySettings => 'Cambia le Chiavi di Identità';

  @override
  String get repeater_keySettingsSubtitle =>
      'Cambia la coppia di chiavi pubblica/privata';

  @override
  String get repeater_prvKey => 'Chiave privata';

  @override
  String get repeater_prvKeyHelper =>
      'Una nuova chiave privata per il ripetitore, una stringa esadecimale di 128 caratteri.';

  @override
  String get repeater_generatePrvKey => 'Genera una coppia di chiavi casuale';

  @override
  String get repeater_stopGeneratingPrvKey =>
      'Interrompi la ricerca della coppia di chiavi';

  @override
  String get repeater_pubKey => 'Chiave pubblica';

  @override
  String get repeater_pubKeyHelper =>
      'Questa è la chiave pubblica che accompagna la chiave privata generata. Non è possibile impostarla direttamente.';

  @override
  String get repeater_pubKeyPrefix => 'Prefisso desiderato';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Trova una chiave pubblica che inizia con queste cifre esadecimali. Tentativi necessari previsti: $tries.';
  }

  @override
  String get repeater_txDelay => 'Ritardo a Flood, TX';

  @override
  String get repeater_txDelayHelper =>
      'Riassegnare lo spazio tra i pacchetti per gestire il traffico intenso, come un moltiplicatore del tempo di trasmissione (da 0 a 2, valore predefinito 0,5). Un valore più alto significa meno collisioni, ma una trasmissione più lenta.';

  @override
  String get repeater_directTxDelay => 'Ritardo diretto TX';

  @override
  String get repeater_directTxDelayHelper =>
      'Riassegnare lo spazio per il traffico diretto (non di massa), come un moltiplicatore del tempo di trasmissione del pacchetto (da 0 a 2, valore predefinito 0,3).';

  @override
  String get repeater_intThresh => 'Soglia di interferenza';

  @override
  String get repeater_intThreshHelper =>
      'Il limite è stato impostato per la calibrazione del livello di rumore del ricevitore, in modo che esso rifiuti i segnali di interferenza superiori a questo livello. 0 disabilita – aumentalo solo se si verificano errori nel ricevitore in una banda di frequenza rumorosa.';

  @override
  String get repeater_agcResetInterval => 'Intervallo di ripristino di AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Con quale frequenza è necessario resettare il controllo automatico del guadagno per ripristinare il funzionamento dopo un\'interruzione. Impostare su secondi, ridotti a multipli di 4. Disattivare la reimpostazione periodica.';

  @override
  String get repeater_actionsTitle => 'Azioni';

  @override
  String get repeater_sendAdvert =>
      'Inviare annuncio relativo alle inondazioni';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Trasmettere un annuncio pubblicitario relativo alle inondazioni attraverso la rete.';

  @override
  String get repeater_sendAdvertZeroHop =>
      'Inviare un annuncio senza intermediari';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Trasmettere un annuncio a un solo hop (senza ripetitori)';

  @override
  String get repeater_clockSync => 'Sincronizza l\'orologio ora';

  @override
  String get repeater_clockSyncSubtitle =>
      'Imposta l\'ora del tuo telefono sul ripetitore.';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action ha avuto successo';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action failed: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Impostazioni salvate — riavviare il ripetitore per applicare le modifiche';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Alcune impostazioni non sono state salvate: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Errore durante il salvataggio delle impostazioni: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Aggiorna Impostazioni Base';

  @override
  String get repeater_refreshRadioSettings => 'Aggiorna le Impostazioni Radio';

  @override
  String get repeater_refreshTxPower => 'Aggiorna TX potenza';

  @override
  String get repeater_refreshPacketForwarding =>
      'Aggiorna il inoltro pacchetti';

  @override
  String get repeater_refreshGuestAccess => 'Aggiorna Accesso Ospite';

  @override
  String get repeater_refreshPrivacyMode => 'Aggiorna Modalità Privacy';

  @override
  String repeater_refreshed(String label) {
    return '$label aggiornato';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Errore durante il ricaricamento di $label';
  }

  @override
  String get repeater_cliTitle => 'CLI del ripetitore';

  @override
  String get repeater_debugNextCommand => 'Riavvia Comando Prossimo';

  @override
  String get repeater_commandHelp => 'Aiuto';

  @override
  String get repeater_clearHistory => 'Cancella Cronologia';

  @override
  String get repeater_noCommandsSent => 'Nessun comando inviato ancora';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Digita un comando qui sotto o usa comandi rapidi';

  @override
  String get repeater_enterCommandHint => 'Inserisci comando...';

  @override
  String get repeater_previousCommand => 'Comando precedente';

  @override
  String get repeater_nextCommand => 'Prossimo comando';

  @override
  String get repeater_enterCommandFirst => 'Inserisci un comando prima';

  @override
  String get repeater_cliCommandFrameTitle => 'Finestra Comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Errore: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Ottieni Nome';

  @override
  String get repeater_cliQuickGetRadio => 'Ottieni Radio';

  @override
  String get repeater_cliQuickGetTx => 'Ottieni TX';

  @override
  String get repeater_cliQuickNeighbors => 'Vicini';

  @override
  String get repeater_cliQuickVersion => 'Versione';

  @override
  String get repeater_cliQuickAdvertise => 'Annuncia';

  @override
  String get repeater_cliQuickClock => 'Orologio';

  @override
  String get repeater_cliQuickClockSync => 'Sincronizza orologio';

  @override
  String get repeater_cliQuickDiscovery => 'Scopri vicini';

  @override
  String get repeater_cliHelpAdvert => 'Invia un pacchetto pubblicitario';

  @override
  String get repeater_cliHelpReboot =>
      'Riavvia il dispositivo. (nota, potresti ottenere \'Timeout\' che è normale)';

  @override
  String get repeater_cliHelpClock =>
      'Mostra l\'ora corrente per l\'orologio di ciascun dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Imposta una nuova password di amministratore per il dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Mostra la versione del dispositivo e la data di costruzione del firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resetta vari numerosi contatori di statistiche a zero.';

  @override
  String get repeater_cliHelpSetAf =>
      'Imposta il fattore di tempo di trasmissione.';

  @override
  String get repeater_cliHelpSetTx =>
      'Imposta la potenza di trasmissione LoRa in dBm (riavvia per applicare).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Abilita o disabilita il ruolo del ripetitore per questo nodo.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Server stanza) Se \'on\', allora l\'accesso con una password vuota sarà consentito, ma non sarà possibile pubblicare nella stanza. (solo lettura).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Imposta il numero massimo di salti per i pacchetti di inondazione in entrata (se >= max, il pacchetto non viene inoltrato)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Imposta il Limite di Interferenza (in dB). Il valore predefinito è 14. Imposta su 0 per disabilitare il rilevamento delle interferenze del canale.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Imposta l\'intervallo per resettare il controllore Automatico del Guadagno. Imposta su 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Abilita o disabilita la funzione \'double ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Imposta l\'intervallo del timer in minuti per inviare un pacchetto di pubblicità locale (senza salto). Imposta su 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Imposta l\'intervallo del timer in ore per inviare un pacchetto pubblicitario di massa. Imposta su 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Imposta/aggiorna la password dell\'ospite. (per ripetitori, gli accessi degli ospiti possono inviare la richiesta \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Imposta il nome dell\'annuncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Imposta la latitudine della mappa pubblicitaria. (gradi decimali)';

  @override
  String get repeater_cliHelpSetLon =>
      'Imposta la longitudine della mappa pubblicitaria. (gradi decimali)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Imposta completamente nuovi parametri radio e li salva nelle preferenze. Richiede un comando \"reboot\" per l\'applicazione.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Impostazioni (experimental) base (deve essere > 1 per l\'effetto) per applicare un leggero ritardo ai pacchetti ricevuti, in base alla forza del segnale/punteggio. Imposta a 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Imposta un fattore moltiplicativo sul tempo di trasmissione dei pacchetti in modalità flood e su un sistema a slot casuali, per ritardarne l\'inoltro (riducendo la probabilità di collisioni).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Uguale a txdelay, ma per applicare un ritardo casuale alla inoltrata di pacchetti in modalità diretta.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Abilita/disabilita il bridge.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Imposta il ritardo prima di ritrasmettere i pacchetti.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Scegli se il bridge ritrasmette i pacchetti ricevuti o trasmessi.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Imposta la velocità di trasmissione per i ponti rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Imposta il segreto per i ponti espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Imposta un fattore personalizzato per regolare la tensione della batteria riportata (supportato solo su schede selezionate).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Imposta parametri radio temporanei per il numero specificato di minuti, per poi tornare ai parametri radio originali. (non salva nelle preferenze).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica l\'ACL. Rimuove l\'entrata corrispondente (per prefisso di pubkey) se \"permissions\" è zero. Aggiunge una nuova entrata se il pubkey-hex ha lunghezza completa e non è attualmente nell\'ACL. Aggiorna l\'entrata per corrispondenza del prefisso di pubkey. I bit di permesso variano per ogni ruolo di firmware, ma i primi 2 bit sono: 0 (Guest), 1 (solo lettura), 2 (lettura/scrittura), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Mostra il tipo di bridge: nessuno, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Avvia registrazione pacchetti nel file system.';

  @override
  String get repeater_cliHelpLogStop =>
      'Interrompi la registrazione dei pacchetti al file system.';

  @override
  String get repeater_cliHelpLogErase =>
      'Elimina i log del pacchetto dal file system.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mostra un elenco di altri nodi repeater ricevuti tramite annunci zero-hop. Ogni riga è id-prefisso-esadecimale:timestamp:snr-volte-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Rimuove la prima corrispondenza in base al prefisso (esadecimale) della pubkey, dalla lista dei vicini.';

  @override
  String get repeater_cliHelpRegion =>
      '(solo serie) Elenca tutte le regioni definite e le autorizzazioni di allagamento correnti.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: questo è un\'invocazione multi-comando speciale. Ogni comando successivo è un nome di regione (indentato con spazi per indicare la gerarchia parentale, con almeno uno spazio). Terminata inviando una riga vuota/comando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Cerca la regione con il prefisso del nome dato (o \"\" per l\'ambito globale). Risponde con \"-> nome-regione (nome-genitore) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Aggiunge o aggiorna una definizione di regione con il nome specificato.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Rimuove una definizione di regione con il dato nome. (deve corrispondere esattamente e non avere regioni figlio)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Imposta il permesso \'F\'lood per la regione specificata. (\'*\' per lo scope globale/legacy)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Rimuove il permesso \'F\'lood per la regione specificata. (NOTA: al momento non è consigliato usarlo sullo scope globale/legacy!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Risponde con la regione \'home\' corrente. (Nota non ancora applicata, riservata per il futuro)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Imposta la regione \'home\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persiste l\'elenco/mappa delle regioni all\'archiviazione.';

  @override
  String get repeater_cliHelpGps =>
      'Mostra lo stato del GPS. Quando il GPS è spento, risponde solo \"spento\", se è acceso risponde con \"acceso\", \"stato\", \"fix\" e numero di satelliti.';

  @override
  String get repeater_cliHelpGpsOnOff =>
      'Attiva/disattiva l\'alimentazione del GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincronizza l\'orario del nodo con l\'orologio GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Imposta la posizione del nodo alle coordinate GPS e salva le preferenze.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Fornisce la configurazione dell\'annuncio per il nodo:\n- nessuno: non includere la posizione negli annunci\n- condividi: condividi la posizione GPS (dal SensorManager)\n- preferenze: annuncia la posizione memorizzata nelle preferenze';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Imposta la configurazione dell\'annuncio sulla posizione.';

  @override
  String get repeater_commandsListTitle => 'Elenco Comandi';

  @override
  String get repeater_commandsListNote =>
      'NOTA: per i vari comandi \"set...\", esiste anche un comando \"get...\".';

  @override
  String get repeater_general => 'Generale';

  @override
  String get repeater_settingsCategory => 'Impostazioni';

  @override
  String get repeater_bridge => 'Ponte';

  @override
  String get repeater_logging => 'Registrazione';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vicini (solo ripetitore)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gestione Regione (solo Ripetitore)';

  @override
  String get repeater_regionNote =>
      'Sono state introdotte le comandi di regione per gestire le definizioni e le autorizzazioni delle regioni.';

  @override
  String get repeater_gpsManagement => 'Gestione GPS';

  @override
  String get repeater_gpsNote =>
      'è stata introdotta una funzione gps per gestire le tematiche relative alla posizione.';

  @override
  String get repeater_getCategory => 'Ottenere valori';

  @override
  String get repeater_powerMgmt => 'Gestione dell\'energia';

  @override
  String get repeater_sensors => 'Sensori';

  @override
  String get repeater_cliHelpPowerOff =>
      'Disattiva il dispositivo. (non ci si aspetta alcuna risposta)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Riporta l\'orologio a un\'epoca nota e riavvia il dispositivo.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Invia un annuncio che raggiunge solo i vicini immediati (senza passaggi intermedi).';

  @override
  String get repeater_cliHelpStartOta =>
      'Avvia un aggiornamento del firmware tramite la trasmissione radio su schede supportate.';

  @override
  String get repeater_cliHelpTime =>
      'Imposta l\'orario del dispositivo sui secondi dell\'epoca Unix specificati. L\'orario non può andare indietro.';

  @override
  String get repeater_cliHelpBoard =>
      'Indica il produttore della scheda e l\'identificatore hardware.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Invia una richiesta di scoperta di nodi ai vicini. (Solo per ripetitori)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Indica se la modalità di risparmio energetico è attiva o disattivata.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Abilita o disabilita la modalità di risparmio energetico (se supportata).';

  @override
  String get repeater_cliHelpErase =>
      '(Solo per sistemi di serializzazione) Formatta il file system del dispositivo. Elimina tutte le impostazioni e i contatti.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Imposta il ciclo di trasmissione massimo consentito in percentuale (da 1 a 100). Regola internamente il fattore di tempo di trasmissione.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(Solo per serie) Sostituisce la chiave privata di identificazione del dispositivo. È necessario riavviare il dispositivo per applicare la modifica. Genera una nuova chiave pubblica.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Solo per SX126x) Permette di attivare un guadagno RX potenziato per una maggiore sensibilità a correnti più elevate.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Definisce la stringa contenente le informazioni di contatto del proprietario, presente negli annunci. Utilizzare \'|\' per i newline.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Imposta la modalità di hashing del percorso. 0 = modalità legacy, 1 = modalità standard, 2 = modalità rigorosa. Influisce su come vengono abbinati i percorsi di routing.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Imposta il livello di sensibilità per il rilevamento dei loop di routing: disattivato, minimo, moderato o rigoroso.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Solo per la funzione di regolazione della frequenza) Imposta rapidamente la frequenza desiderata. È necessario riavviare il dispositivo. Si consiglia di utilizzare la funzione \"imposta radio\" per impostare tutti i parametri radio.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Solo per il bridge ESPNow) Imposta il canale Wi-Fi (da 1 a 14) utilizzato dal bridge.';

  @override
  String get repeater_cliHelpGetName => 'Mostra il nome del nodo configurato.';

  @override
  String get repeater_cliHelpGetRole =>
      'Indica il ruolo del firmware (ripetitore, server per stanza, ecc.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Mostra la chiave pubblica del dispositivo.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Solo per serie) Visualizza la chiave privata del dispositivo. Trattala come una informazione riservata.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Indica se la funzione di inoltro dei pacchetti (funzione di ripetitore) è attiva o disattivata.';

  @override
  String get repeater_cliHelpGetTx => 'Mostra la potenza attuale in dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Mostra la frequenza radio configurata in MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Visualizza tutti i parametri radio: frequenza, larghezza di banda, fattore di spreading, tasso di codifica.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Solo per i moduli SX126x) Mostra lo stato del guadagno potenziato del RX.';

  @override
  String get repeater_cliHelpGetAf =>
      'Mostra il fattore di trasmissione attuale.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Mostra il ciclo di lavoro attuale consentito in percentuale.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Mostra il limite di interferenza del canale in dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Indica l\'intervallo di reset dell\'AGC in secondi.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Indica se la modalità \"ACK doppio\" è attiva (1) o disattivata (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Indica se è consentito l\'accesso in sola lettura per gli ospiti.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Indica l\'intervallo pubblicitario locale in minuti.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Indica l\'intervallo dell\'annuncio flood, espresso in ore.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Visualizza la password del guest configurata.';

  @override
  String get repeater_cliHelpGetLat => 'Mostra la latitudine configurata.';

  @override
  String get repeater_cliHelpGetLon => 'Mostra la longitudine impostata.';

  @override
  String get repeater_cliHelpGetRxDelay => 'Mostra il valore base di rxdelay.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Mostra il fattore txdelay in modalità flood.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Mostra il fattore di ritardo in modalità diretta.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Mostra il numero massimo di salti del flood.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Visualizza la stringa contenente le informazioni di contatto del proprietario.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Mostra la modalità \"hash del percorso\" (0/1/2).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Indica la sensibilità alla rilevazione di loop.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Solo per serie) Elenca le voci di controllo degli accessi su un ripetitore.';

  @override
  String get repeater_cliHelpGetBridgeEnabled => 'Indica se il ponte è attivo.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Mostra il ritardo del ponte in millisecondi.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Indica se il bridge sta inviando pacchetti RX o TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Solo per l\'adattatore RS232) Visualizza la velocità di trasmissione del bridge.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Solo per il bridge ESPNow) Visualizza il canale WiFi del bridge.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Solo per il bridge ESPNow) Visualizza la chiave segreta condivisa.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Solo per NRF52) Visualizza la versione del bootloader.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Mostra il moltiplicatore ADC (adattamento della tensione della batteria).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Indica se il sistema dispone di funzionalità di gestione dell\'energia.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Indica la fonte di alimentazione attuale: esterna o batteria.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Mostra le ragioni più recenti per il ripristino e lo spegnimento.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Mostra la tensione della batteria al momento dell\'accensione, misurata in millivolt (mV).';

  @override
  String get repeater_cliHelpSensorGet =>
      'Legge un valore di configurazione personalizzato per un sensore tramite un tasto.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Definisce una configurazione personalizzata per un sensore.';

  @override
  String get repeater_cliHelpSensorList =>
      'Elenca tutte le impostazioni personalizzate dei sensori, organizzate in pagine a partire da un indice di inizio opzionale.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Mostra l\'ambito predefinito corrente.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Definisce l\'ambito regionale predefinito. Utilizzare \"<null>\" per cancellare.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Elenca le regioni che consentono il traffico flood.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Elenca le regioni che negano il traffico flood.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Solo per la visualizzazione dei dati seriali) Mostra statistiche a livello di pacchetto.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Solo per serie TV) Visualizza statistiche relative alla trasmissione radiofonica.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Solo per serie) Visualizza le statistiche del firmware di base.';

  @override
  String get telemetry_receivedData => 'Dati Telemetria Ricevuti';

  @override
  String get telemetry_requestTimeout => 'Richiesta di telemetria scaduta.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Errore nel caricamento della telemetria: $error';
  }

  @override
  String get telemetry_noData => 'Nessun dato di telemetria disponibile.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canale $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batteria';

  @override
  String get telemetry_voltageLabel => 'Tensione';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Attuale';

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
  String get telemetry_digitalInputLabel => 'Ingresso digitale';

  @override
  String get telemetry_digitalOutputLabel => 'Uscita digitale';

  @override
  String get telemetry_analogInputLabel => 'Ingresso analogico';

  @override
  String get telemetry_analogOutputLabel => 'Uscita analogica';

  @override
  String get telemetry_genericLabel => 'Sensore generico';

  @override
  String get telemetry_luminosityLabel => 'Luminosità';

  @override
  String get telemetry_presenceLabel => 'Presenza';

  @override
  String get telemetry_humidityLabel => 'Umidità';

  @override
  String get telemetry_accelerometerLabel => 'Accelerometro';

  @override
  String get telemetry_pressureLabel => 'Pressione';

  @override
  String get telemetry_altitudeLabel => 'Altitudine';

  @override
  String get telemetry_frequencyLabel => 'Frequenza';

  @override
  String get telemetry_percentageLabel => 'Percentuale';

  @override
  String get telemetry_concentrationLabel => 'Concentrazione';

  @override
  String get telemetry_powerLabel => 'Potenza';

  @override
  String get telemetry_distanceLabel => 'Distanza';

  @override
  String get telemetry_energyLabel => 'Energia';

  @override
  String get telemetry_directionLabel => 'Direzione';

  @override
  String get telemetry_timeLabel => 'Ora';

  @override
  String get telemetry_gyrometerLabel => 'Giroscopio';

  @override
  String get telemetry_colourLabel => 'Colore';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Interruttore';

  @override
  String get telemetry_polylineLabel => 'Polilinea';

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
  String get telemetry_autoFetchQuantity => 'Numero di richieste';

  @override
  String get telemetry_error => 'Impossibile recuperare i dati';

  @override
  String get neighbors_receivedData => 'Dati dei vicini ricevuti';

  @override
  String get neighbors_requestTimedOut => 'Richiesta dei vicini scaduta.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Errore nel caricamento dei vicini: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Vicini dei ripetitori';

  @override
  String get neighbors_noData => 'Nessun dato sui vicini disponibile.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Chiave pubblica sconosciuta $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Sentito: $time fa';
  }

  @override
  String get channelPath_title => 'Percorso Pacchetto';

  @override
  String get channelPath_viewMap => 'Visualizza mappa';

  @override
  String get channelPath_otherObservedPaths => 'Altri percorsi osservati';

  @override
  String get channelPath_repeaterHops => 'Salti del ripetitore';

  @override
  String get channelPath_noHopDetails =>
      'I dettagli relativi a questo pacchetto non sono forniti.';

  @override
  String get channelPath_messageDetails => 'Dettagli messaggio';

  @override
  String get channelPath_senderLabel => 'Mittente';

  @override
  String get channelPath_timeLabel => 'Ora';

  @override
  String get channelPath_repeatsLabel => 'Ripetizioni';

  @override
  String channelPath_pathLabel(int index) {
    return 'Percorso $index';
  }

  @override
  String get channelPath_observedLabel => 'Osservato';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Percorso osservato $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nessun dato di posizione';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Sconosciuto';

  @override
  String get channelPath_floodPath => 'Flood';

  @override
  String get channelPath_directPath => 'Diretto';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 di $total salti';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed di $total salti';
  }

  @override
  String get channelPath_mapTitle => 'Mappa del percorso';

  @override
  String get channelPath_noRepeaterLocations =>
      'Non sono disponibili posizioni dei ripetitori per questo percorso.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Percorso $index (Primario)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Percorso';

  @override
  String get channelPath_observedPathHeader => 'Percorso Osservato';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Non sono disponibili i dettagli del salto per questo pacchetto.';

  @override
  String get channelPath_unknownRepeater => 'Ripetitore sconosciuto';

  @override
  String get community_title => 'Comunità';

  @override
  String get community_create => 'Crea Comunità';

  @override
  String get community_createDesc =>
      'Crea una nuova comunità e condividila tramite codice QR.';

  @override
  String get community_join => 'Unisciti';

  @override
  String get community_joinTitle => 'Unisciti alla Community';

  @override
  String community_joinConfirmation(String name) {
    return 'Vuoi unirti alla community \"$name\"?';
  }

  @override
  String get community_scanQr => 'Scansiona il QR Code della Community';

  @override
  String get community_scanInstructions =>
      'Punta la fotocamera su un codice QR della comunità';

  @override
  String get community_showQr => 'Mostra il codice QR';

  @override
  String get community_publicChannel => 'Comunità Pubblica';

  @override
  String get community_hashtagChannel => 'Hashtag della Comunità';

  @override
  String get community_name => 'Nome della Comunità';

  @override
  String get community_enterName => 'Inserisci il nome della comunità';

  @override
  String community_created(String name) {
    return 'Comunità \"$name\" creata';
  }

  @override
  String community_joined(String name) {
    return 'Unito alla comunità \"$name\"';
  }

  @override
  String get community_qrTitle => 'Condividi Comunità';

  @override
  String community_qrInstructions(String name) {
    return 'Scansiona questo codice QR per unirti a $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'I canali hashtag della community sono accessibili solo ai membri della community';

  @override
  String get community_invalidQrCode => 'Codice QR della community non valido';

  @override
  String get community_alreadyMember => 'Già membro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Sei già un membro di \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Aggiungi Canale Pubblico della Comunità';

  @override
  String get community_addPublicChannelHint =>
      'Aggiungi automaticamente il canale pubblico per questa community';

  @override
  String get community_noCommunities => 'Nessun gruppo aggiunto finora';

  @override
  String get community_scanOrCreate =>
      'Scansiona un codice QR o crea una community per iniziare.';

  @override
  String get community_manageCommunities => 'Gestisci Comunità';

  @override
  String get community_delete => 'Lascia la Comunità';

  @override
  String community_deleteConfirm(String name) {
    return 'Uscire da \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Questo eliminerà anche $count canale/i e i loro messaggi.';
  }

  @override
  String community_deleted(String name) {
    return 'Hai lasciato la comunità \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Ri genera la chiave segreta';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenera la chiave segreta per \"$name\"? Tutti i membri dovranno scansionare il nuovo codice QR per continuare a comunicare.';
  }

  @override
  String get community_regenerate => 'Rigenera';

  @override
  String community_secretRegenerated(String name) {
    return 'Codice segreto rigenerato per \"$name\"';
  }

  @override
  String get community_updateSecret => 'Aggiorna Segreto';

  @override
  String community_secretUpdated(String name) {
    return 'Segreto aggiornato per \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scansiona il nuovo codice QR per aggiornare il segreto di \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Aggiungi Hashtag della Community';

  @override
  String get community_addHashtagChannelDesc =>
      'Aggiungi un canale con hashtag per questa community';

  @override
  String get community_selectCommunity => 'Seleziona Comunità';

  @override
  String get community_regularHashtag => 'Hashtag regolare';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag pubblico (chiunque può unirsi)';

  @override
  String get community_communityHashtag => 'Hashtag della Comunità';

  @override
  String get community_communityHashtagDesc =>
      'Visibile solo ai membri della comunità';

  @override
  String community_forCommunity(String name) {
    return 'Per $name';
  }

  @override
  String get listFilter_tooltip => 'Filtra e ordina';

  @override
  String get listFilter_sortBy => 'Ordina per';

  @override
  String get listFilter_latestMessages => 'Ultimi messaggi';

  @override
  String get listFilter_heardRecently => 'Rilevato di recente';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtri';

  @override
  String get listFilter_all => 'Tutti';

  @override
  String get listFilter_favorites => 'Preferiti';

  @override
  String get listFilter_addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get listFilter_removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String get listFilter_users => 'Utenti';

  @override
  String get listFilter_repeaters => 'Ripetitori';

  @override
  String get listFilter_roomServers => 'Server stanza';

  @override
  String get listFilter_unreadOnly => 'Solo non letti';

  @override
  String get listFilter_newGroup => 'Nuovo gruppo';

  @override
  String get pathTrace_you => 'Tu';

  @override
  String get pathTrace_failed => 'Tracciamento del percorso fallito.';

  @override
  String get pathTrace_notAvailable =>
      'Tracciamento del percorso non disponibile.';

  @override
  String get pathTrace_refreshTooltip => 'Aggiorna tracciamento percorso.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Uno o più hop non hanno una posizione!';

  @override
  String get pathTrace_clearTooltip => 'Cancella percorso';

  @override
  String get losSelectStartEnd =>
      'Seleziona i nodi iniziali e finali per la LOS.';

  @override
  String losRunFailed(String error) {
    return 'Controllo della linea di vista fallito: $error';
  }

  @override
  String get losClearAllPoints => 'Cancella tutti i punti';

  @override
  String get losRunToViewElevationProfile =>
      'Eseguire LOS per visualizzare il profilo altimetrico';

  @override
  String get losMenuTitle => 'Menù LOS';

  @override
  String get losMenuSubtitle =>
      'Tocca i nodi o premi a lungo la mappa per punti personalizzati';

  @override
  String get losShowDisplayNodes => 'Mostra i nodi di visualizzazione';

  @override
  String get losCustomPoints => 'Punti personalizzati';

  @override
  String losCustomPointLabel(int index) {
    return 'Personalizzato $index';
  }

  @override
  String get losPointA => 'Punto A';

  @override
  String get losPointB => 'Punto B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenna A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenna B: $value $unit';
  }

  @override
  String get losRun => 'Esegui LOS';

  @override
  String get losNoElevationData => 'Nessun dato di elevazione';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, libera LOS, distanza minima $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, bloccato da $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: controllo...';

  @override
  String get losStatusNoData => 'LOS: nessun dato';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total libera, $blocked bloccato, $unknown sconosciuto';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Dati di elevazione non disponibili per uno o più campioni.';

  @override
  String get losErrorInvalidInput =>
      'Dati punti/elevazione non validi per il calcolo della LOS.';

  @override
  String get losRenameCustomPoint => 'Rinomina punto personalizzato';

  @override
  String get losPointName => 'Nome del punto';

  @override
  String get losShowPanelTooltip => 'Mostra il pannello LOS';

  @override
  String get losHidePanelTooltip => 'Nascondi il pannello LOS';

  @override
  String get losElevationAttribution =>
      'Dati di elevazione: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Orizzonte radio';

  @override
  String get losLegendLosBeam => 'Linea di vista';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losBlockedSpotsTitle => 'Posti occupati';

  @override
  String get losBlockedSpotsHint =>
      'Tocca un punto bloccato sulla mappa per evidenziarlo.';

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
  String get losSelectedObstructionTitle => 'Ostacolo selezionato';

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
  String get losFrequencyLabel => 'Frequenza';

  @override
  String get losFrequencyInfoTooltip => 'Visualizza i dettagli del calcolo';

  @override
  String get losFrequencyDialogTitle => 'Calcolo dell’orizzonte radio';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Partendo da k=$baselineK a $baselineFreq MHz, il calcolo regola il fattore k per l\'attuale banda $frequencyMHz MHz, che definisce il limite curvo dell\'orizzonte radio.';
  }

  @override
  String get contacts_pathTrace => 'Traccia Percorso';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Traccia percorso al ripetitore';

  @override
  String get contacts_repeaterPing => 'Ripetitore ping';

  @override
  String get contacts_roomPathTrace =>
      'Traccia del percorso al server della stanza';

  @override
  String get contacts_roomPing => 'Ping al server della stanza';

  @override
  String get contacts_chatTraceRoute => 'Traccia percorso path';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Traccia percorso verso $name';
  }

  @override
  String get contacts_clipboardEmpty => 'La clipboard è vuota.';

  @override
  String get contacts_invalidAdvertFormat => 'Dati di contatto non validi';

  @override
  String get contacts_contactImported => 'Il contatto è stato importato.';

  @override
  String get contacts_contactImportFailed =>
      'Contatto non importato con successo.';

  @override
  String get contacts_zeroHopAdvert => 'Annuncio Zero Hop';

  @override
  String get contacts_floodAdvert => 'Annuncio alluvionale';

  @override
  String get contacts_copyAdvertToClipboard => 'Copia Annuncio negli Appunti';

  @override
  String get contacts_addContactFromClipboard =>
      'Aggiungere contatto dalla clipboard';

  @override
  String get contacts_ShareContact => 'Copia contatto negli Appunti';

  @override
  String get contacts_ShareContactZeroHop =>
      'Condividi contatto tramite annuncio';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Inviato contatto tramite annuncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Invio del contatto non riuscito.';

  @override
  String get contacts_contactAdvertCopied => 'Annuncio copiato negli Appunti.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Copia dell\'annuncio nella Clipboard non riuscita.';

  @override
  String get notification_activityTitle => 'Attività MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messaggi',
      one: 'messaggio',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messaggi del canale',
      one: 'messaggio del canale',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nuovi nodi',
      one: 'nuovo nodo',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nuovo $contactType scoperto';
  }

  @override
  String get notification_receivedNewMessage => 'Nuovo messaggio ricevuto';

  @override
  String get settings_gpxExportRepeaters =>
      'Esporta ripetitori / server di stanza in GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Esporta ripetitori / roomserver con una posizione in un file GPX.';

  @override
  String get settings_gpxExportContacts => 'Esporta compagni in GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Esporta i compagni con una posizione in un file GPX.';

  @override
  String get settings_gpxExportAll => 'Esporta tutti i contatti in GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Esporta tutti i contatti con una posizione in un file GPX.';

  @override
  String get settings_gpxExportSuccess =>
      'Esportazione del file GPX completata con successo.';

  @override
  String get settings_gpxExportNoContacts => 'Nessun contatto da esportare.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Non supportato sul tuo dispositivo/Sistema Operativo';

  @override
  String get settings_gpxExportError =>
      'Si è verificato un errore durante l\'esportazione.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Posizioni del server ripetitore e della stanza';

  @override
  String get settings_gpxExportChat => 'Posizioni dei compagni';

  @override
  String get settings_gpxExportAllContacts => 'Tutte le posizioni dei contatti';

  @override
  String get settings_gpxExportShareText =>
      'Dati mappa esportati da meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open esportazione dati mappa GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Ripetitori vicini';

  @override
  String get snrIndicator_lastSeen => 'Ultimo accesso';

  @override
  String get contactsSettings_title => 'Impostazioni dei contatti';

  @override
  String get contactsSettings_autoAddTitle => 'Scoperta automatica';

  @override
  String get contactsSettings_otherTitle =>
      'Altre impostazioni relative ai contatti';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Aggiungere utenti automaticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Consenti al compagno di aggiungere automaticamente gli utenti scoperti.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Aggiungere ripetitori automaticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Consenti al compagno di aggiungere automaticamente i ripetitori scoperti.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Aggiungere automaticamente i server delle stanze';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Consenti al compagno di aggiungere automaticamente i server delle stanze scoperte.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Aggiungere automaticamente i sensori';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Consenti al compagno di aggiungere automaticamente i sensori scoperti';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Sostituisci il più vecchio';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Quando l\'elenco dei contatti è pieno, il contatto più vecchio non tra i preferiti verrà sostituito.';

  @override
  String get discoveredContacts_Title => 'Contatti scoperti';

  @override
  String get discoveredContacts_noMatching => 'Nessun contatto corrispondente';

  @override
  String get discoveredContacts_searchHint => 'Cerca contatti scoperti';

  @override
  String get discoveredContacts_contactAdded => 'Contatto aggiunto';

  @override
  String get discoveredContacts_addContact => 'Aggiungi contatto';

  @override
  String get discoveredContacts_copyContact => 'Copia contatto negli appunti';

  @override
  String get discoveredContacts_deleteContact => 'Elimina Contatto';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Eliminare tutti i contatti scoperti';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Sei sicuro di voler eliminare tutti i contatti scoperti?';

  @override
  String get chat_sendCooldown =>
      'Si prega di attendere un momento prima di inviare nuovamente.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Vai al messaggio più vecchio non letto';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Quando si apre una chat con messaggi non letti, scorrete verso l\'alto fino al primo messaggio non letto, invece che al più recente.';

  @override
  String get appSettings_languageHu => 'Ungherese';

  @override
  String get appSettings_languageJa => 'Giapponese';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_tooltip => 'Statistiche per radio e reti';

  @override
  String get radioStats_screenTitle => 'Statistiche radio';

  @override
  String get radioStats_notConnected =>
      'Connettiti a un dispositivo per visualizzare le statistiche radio.';

  @override
  String get radioStats_firmwareTooOld =>
      'Le statistiche radio richiedono il firmware versione 8 o successiva.';

  @override
  String get radioStats_waiting => 'In attesa dei dati…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Livello di rumore: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Ultimo valore RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Ultimo SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Tempo di trasmissione in diretta (totale): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tempo di trasmissione RX (totale): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Livello di rumore (dBm) misurato su campioni recenti.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Livello di rumore: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Recupero delle statistiche radio…';

  @override
  String get radioStats_settingsTile => 'Statistiche radio';

  @override
  String get radioStats_settingsSubtitle =>
      'Livello di rumore, RSSI, rapporto segnale/rumore (SNR) e tempo di trasmissione';

  @override
  String get translation_title => 'Traduzione';

  @override
  String get imageMessages_enableTitle => 'Messaggi con immagini';

  @override
  String get imageMessages_enableSubtitle =>
      'Invia le immagini tramite la mesh. È necessario scaricare il modello dell\'immagine una tantum.';

  @override
  String get imageMessages_modelSectionTitle => 'Modello di immagine';

  @override
  String get imageMessages_downloadModel => 'Scarica';

  @override
  String get imageMessages_cancelDownload => 'Annullare';

  @override
  String get imageMessages_removeModel => 'Rimuovi il modello';

  @override
  String get imageMessages_modelReady => 'Pronto';

  @override
  String get imageMessages_modelNotPublished =>
      'Non pubblicato ancora — questa versione non può scaricarlo.';

  @override
  String get imageMessages_downloadFailed =>
      'Il modello di immagine non può essere scaricato.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Elabora automaticamente le immagini';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Ricostruisci ogni immagine non appena arriva. Utilizza circa 2 GB di memoria per un secondo ogni volta; disattiva la ricostruzione con un semplice tocco.';

  @override
  String get translation_enableTitle => 'Abilitare la traduzione';

  @override
  String get translation_enableSubtitle =>
      'Tradurre i messaggi in arrivo e consentire la traduzione preventiva prima dell\'invio.';

  @override
  String get translation_composerTitle => 'Tradurre prima di inviare';

  @override
  String get translation_composerSubtitle =>
      'Controlla lo stato predefinito dell\'icona di traduzione del compositore.';

  @override
  String get translation_autoIncomingTitle =>
      'Traduci automaticamente i messaggi';

  @override
  String get translation_autoIncomingSubtitle =>
      'Traduce automaticamente i messaggi per le notifiche e per le chat o i canali.';

  @override
  String get translation_translateMessage => 'Traduci messaggio';

  @override
  String get translation_targetLanguage => 'Lingua di destinazione';

  @override
  String get translation_useAppLanguage => 'Utilizza la lingua dell\'app';

  @override
  String get translation_downloadedModelLabel => 'Modello scaricato';

  @override
  String get translation_presetModelLabel =>
      'Modello predefinito di Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL del modello manuale';

  @override
  String get translation_downloadModel => 'Scarica il modello';

  @override
  String get translation_downloading => 'Inizio download...';

  @override
  String get translation_working => 'Lavoro...';

  @override
  String get translation_stop => 'Smetta';

  @override
  String get translation_mergingChunks =>
      'Unione dei frammenti scaricati in un unico file...';

  @override
  String get translation_downloadedModels => 'Modelli scaricati';

  @override
  String get translation_deleteModel => 'Elimina modello';

  @override
  String get translation_modelDownloaded => 'Modello di traduzione scaricato.';

  @override
  String get translation_downloadStopped => 'Il download è stato interrotto.';

  @override
  String translation_downloadFailed(String error) {
    return 'Download fallito: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Inserite innanzitutto l\'URL del modello.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostra PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Nascondi il PIN';

  @override
  String get scanner_linuxPairingPinTitle =>
      'PIN per l\'accoppiamento Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Inserire il codice PIN per $deviceName (lasciare vuoto se non presente).';
  }

  @override
  String get translation_messageTranslation => 'Traduzione del messaggio';

  @override
  String get translation_translateBeforeSending => 'Tradurre prima di inviare';

  @override
  String get translation_composerEnabledHint =>
      'I messaggi verranno tradotti prima di essere inviati.';

  @override
  String get translation_composerDisabledHint =>
      'Invia messaggi utilizzando la lingua originale, scritta.';

  @override
  String translation_translateTo(String language) {
    return 'Tradurre in $language';
  }

  @override
  String get translation_translationOptions => 'Opzioni di traduzione';

  @override
  String get translation_systemLanguage => 'Lingua del sistema';

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
    return 'Impossibile aggiornare il canale: $error';
  }

  @override
  String get contact_typeChat => 'Chat';

  @override
  String get contact_typeRepeater => 'Ripetitore';

  @override
  String get contact_typeRoom => 'Stanza';

  @override
  String get contact_typeSensor => 'Sensore';

  @override
  String get contact_typeUnknown => 'Sconosciuto';

  @override
  String get map_zoomIn => 'Ingrandisci';

  @override
  String get map_zoomOut => 'Riduci la visualizzazione';

  @override
  String get map_centerMap => 'Centra mappa';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth richiede un browser basato su Chromium.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'Il GPS conferma';

  @override
  String get pathTrace_legendInferred => 'Posizione dedotta';

  @override
  String get pathMap_viewSingle => 'Singola';

  @override
  String get pathMap_viewCombined => 'Combinata';

  @override
  String get pathMap_play => 'Riproduci';

  @override
  String get pathMap_pause => 'Pausa';

  @override
  String get pathMap_replay => 'Ripeti';

  @override
  String get pathMap_stepBack => 'Salto precedente';

  @override
  String get pathMap_stepForward => 'Salto successivo';

  @override
  String get pathMap_animationOn => 'Mostra l\'animazione del pacchetto';

  @override
  String get pathMap_animationOff => 'Nascondi l\'animazione del pacchetto';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Salto $current di $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Percorsi osservati: $count';
  }

  @override
  String get pathMap_primary => 'Primario';

  @override
  String pathMap_alternate(int index) {
    return 'Alternativo $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salti',
      one: '1 salto',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Segmento condiviso';

  @override
  String get pathMap_legendEstimated => 'Segmento stimato';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Utilizzato da $count percorsi';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count salti non hanno una posizione specifica — il percorso mostrato è parziale',
      one:
          '1 salto non ha una posizione specifica — il percorso mostrato è parziale',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Mostra tutti';

  @override
  String get pathMap_hidePath => 'Nascondi percorso';

  @override
  String get pathMap_showPath => 'Mostra percorso';

  @override
  String get pathMap_collapsePanel => 'Comprimi pannello';

  @override
  String get pathMap_expandPanel => 'Espandi pannello';

  @override
  String get pathMap_noLocation => 'Nessuna posizione';

  @override
  String get pathMap_followPacket => 'Blocca la vista sul pacchetto';

  @override
  String get pathMap_unfollowPacket => 'Sblocca la vista dal pacchetto';

  @override
  String get imageSend_title => 'Invia immagine';

  @override
  String get imageSend_cropNote =>
      'Ridimensionato a 512 × 512 · rapporto d\'aspetto non conservato';

  @override
  String get imageSend_originalSize =>
      'Traduzione:\n\nOriginal text:\n\nPlease translate the following English text into Italian:\n\nOriginal text:\n\n(No original English text provided)';

  @override
  String get imageSend_onAirSize => 'In onda';

  @override
  String get imageSend_quality => 'Qualità';

  @override
  String get imageSend_qualityStandard => 'Standard';

  @override
  String get imageSend_qualityHigh => 'Alto';

  @override
  String get imageSend_packetsLabel => 'Pacchetti';

  @override
  String get imageSend_airtimeLabel => 'Tempo in onda';

  @override
  String get imageSend_sizeLabel => 'Carico utile';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pacchetti',
      one: 'pacchetto',
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
  String get imageSend_radioUnknownTitle => 'Impostazioni radio sconosciute';

  @override
  String get imageSend_radioUnknownBody =>
      'Collegati a un dispositivo in modo che si possa calcolare l\'orario di trasmissione.';

  @override
  String get imageSend_longSendTitle => 'Lunga trasmissione';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Questo manterrà il canale per circa $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Instradamento delle inondazioni: ogni ripetitore nel raggio ritrasmette ogni pacchetto, quindi il canale rimane occupato più a lungo.';

  @override
  String get imageSend_parityTitle => 'Pacchetto di recupero';

  @override
  String get imageSend_paritySubtitle =>
      'Un pacchetto aggiuntivo. I messaggi di gruppo non vengono riconosciuti, quindi questo permette al destinatario di ricostruire l\'immagine se un singolo pacchetto viene perso.';

  @override
  String get imageSend_send => 'Invia';

  @override
  String get imageSend_cancel => 'Annullare';

  @override
  String get imageSend_encodeFailed =>
      'Questa immagine non può essere codificata.';

  @override
  String get imageSend_codecDownloading =>
      'Il modello di immagine sta ancora scaricando.';

  @override
  String get imageSend_codecUnavailable =>
      'L\'invio di immagini non è disponibile su questo dispositivo.';

  @override
  String get imageSend_codecDisabled =>
      'I messaggi immagine sono disattivati nelle impostazioni.';

  @override
  String get imageSend_deviceUnsupported =>
      'Questa radio non può inviare pacchetti di immagini. Collegare un dispositivo con firmware companion versione 13 o successiva.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'Le immagini viaggiano come dati di gruppo, quindi possono essere inviate solo a un canale — non tramite messaggio diretto.';

  @override
  String get imageSend_tooLarge =>
      'Quella immagine è stata codificata in un numero di pacchetti superiore a quello consentito dal formato mesh.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pacchetti',
      one: 'pacchetto',
    );
    return 'Immagine inviata come $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'L\'immagine non può essere inviata: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Invio immagine — pacchetto $sent di $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Nodo $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$received di $total pacchetti';
  }

  @override
  String get receivedImage_queued => 'In attesa di decodificare';

  @override
  String get receivedImage_tapToDecode => 'Tocca per decodificare';

  @override
  String get receivedImage_decoding => 'Ricostruire… circa 1 s';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Immagine incompleta — $received su $total pacchetti ricevuti';
  }

  @override
  String get receivedImage_corrupt =>
      'L\'immagine non potrebbe essere ricostruita';

  @override
  String get receivedImage_decoderMissing =>
      'Immagine ricevuta — decodifica dell\'immagine non funzionante';

  @override
  String get receivedImage_evicted => 'Immagine non più memorizzata';

  @override
  String get receivedImage_retry => 'Prova ancora';

  @override
  String get receivedImage_decodeAgain => 'Decodifica di nuovo';

  @override
  String get receivedImage_openSettings => 'Imposta';

  @override
  String get receivedImage_tapToProcess => 'Premi per elaborare';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'pacchetti',
      one: 'pacchetto',
    );
    return '$bytes byte · $packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds secondi';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }
}
