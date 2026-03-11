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
  String get common_disable => 'Disattivare';

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
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

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
  String get scanner_stop => 'Interrompere';

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
  String get device_quickSwitch => 'Passa velocemente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Impostazioni';

  @override
  String get settings_deviceInfo => 'Informazioni Dispositivo';

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
      'Frequenza, potenza, fattore di dispersione';

  @override
  String get settings_radioSettingsUpdated => 'Impostazioni radio aggiornate';

  @override
  String get settings_location => 'Posizione';

  @override
  String get settings_locationSubtitle => 'coordinate GPS';

  @override
  String get settings_locationUpdated => 'Posizione aggiornata';

  @override
  String get settings_locationBothRequired =>
      'Inserire sia la latitudine che la longitudine.';

  @override
  String get settings_locationInvalid => 'Latitudine o longitudine non valida.';

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
  String get settings_actions => 'Azioni';

  @override
  String get settings_sendAdvertisement => 'Invia Annuncio';

  @override
  String get settings_sendAdvertisementSubtitle => 'Presenza trasmessa ora';

  @override
  String get settings_advertisementSent => 'Annuncio inviato';

  @override
  String get settings_syncTime => 'Tempo di sincronizzazione';

  @override
  String get settings_syncTimeSubtitle =>
      'Imposta l\'orologio del dispositivo sull\'ora del telefono';

  @override
  String get settings_timeSynchronized => 'Sincronizzato nel tempo';

  @override
  String get settings_refreshContacts => 'Aggiorna Contatti';

  @override
  String get settings_refreshContactsSubtitle =>
      'Ricaricare l\'elenco dei contatti dal dispositivo';

  @override
  String get settings_rebootDevice => 'Riavvia Dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Riavviare il dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Sei sicuro di voler riavviare il dispositivo? Sarai disconnesso.';

  @override
  String get settings_debug => 'Risoluzione dei problemi';

  @override
  String get settings_bleDebugLog => 'Log di Debug BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Comandi, risposte e dati grezzi BLE';

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
  String get settings_aboutLegalese => 'Progetto Open Source MeshCore 2024';

  @override
  String get settings_aboutDescription =>
      'Un client Flutter open-source per i dispositivi di rete mesh LoRa Core di MeshCore.';

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
  String get settings_infoContactsCount => 'Numero contatti';

  @override
  String get settings_infoChannelCount => 'Numero Canale';

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
  String get settings_spreadingFactor => 'Fattore di Spettro';

  @override
  String get settings_codingRate => 'Tasso di Codifica';

  @override
  String get settings_txPower => 'TX Potenza (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Potere TX non valido (0-22 dBm)';

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
  String get appSettings_themeSystem => 'Impostazione predefinita del sistema';

  @override
  String get appSettings_themeLight => 'Luce';

  @override
  String get appSettings_themeDark => 'Scuro';

  @override
  String get appSettings_language => 'Lingua';

  @override
  String get appSettings_languageSystem => 'Predefinito di sistema';

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
  String get appSettings_languageRu => 'Russo';

  @override
  String get appSettings_languageUk => 'Ucraino';

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
      'Cancella Percorso su Massimo Riprovo';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Reimposta il percorso di contatto dopo 5 tentativi di invio falliti';

  @override
  String get appSettings_pathsWillBeCleared =>
      'I percorsi verranno puliti dopo 5 tentativi falliti.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'I percorsi non verranno eliminati automaticamente.';

  @override
  String get appSettings_autoRouteRotation => 'Rotazione Percorso Automatico';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Alterna tra i percorsi migliori e la modalità alluvione';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Rotazione percorso automatico abilitata';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Rotazione del percorso automatico disabilitata';

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
  String get appSettings_offlineMapCache => 'Cache Mappa Offline';

  @override
  String get appSettings_unitsTitle => 'Unità';

  @override
  String get appSettings_unitsMetric => 'Metrico (m/km)';

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
      'Messaggi di debug dell\'app Log per la risoluzione dei problemi';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Logging di debug dell\'app abilitato';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Logging del debug dell\'app disabilitato';

  @override
  String get contacts_title => 'Contatti';

  @override
  String get contacts_noContacts => 'Nessun contatto ancora';

  @override
  String get contacts_contactsWillAppear =>
      'I contatti appariranno quando i dispositivi pubblicizzano.';

  @override
  String get contacts_unread => 'Non letti';

  @override
  String get contacts_searchContactsNoNumber => 'Cerca Contatti...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Cerca contatti...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Cerca $number$str Preferiti...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Cerca $number$str Utenti...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Cerca $number$str Ripetitori...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Cerca $number$str server Room...';
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
  String get contacts_manageRepeater => 'Gestisci Ripetitore';

  @override
  String get contacts_manageRoom => 'Gestisci Server Camera';

  @override
  String get contacts_roomLogin => 'Login Camera';

  @override
  String get contacts_openChat => 'Apri Chat';

  @override
  String get contacts_editGroup => 'Modifica Gruppo';

  @override
  String get contacts_deleteGroup => 'Elimina Gruppo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eliminare \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Nuovo Gruppo';

  @override
  String get contacts_groupName => 'Nome gruppo';

  @override
  String get contacts_groupNameRequired => 'Il nome del gruppo è obbligatorio.';

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
  String get contacts_lastSeenNow => 'Ultimo avvistamento ora';

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
  String get channels_hashtagChannel => 'Canale hashtag';

  @override
  String get channels_public => 'Pubblico';

  @override
  String get channels_private => 'Privato';

  @override
  String get channels_publicChannel => 'Canale pubblico';

  @override
  String get channels_privateChannel => 'Canale privato';

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
  String get channels_addChannel => 'Aggiungi Canale';

  @override
  String get channels_channelIndexLabel => 'Indice Canale';

  @override
  String get channels_channelName => 'Nome canale';

  @override
  String get channels_usePublicChannel => 'Utilizza il canale pubblico';

  @override
  String get channels_standardPublicPsk => 'PSK pubblico standard';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk =>
      'Genera una chiave di permutazione casuale';

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
  String channels_channelUpdated(String name) {
    return 'Canale \"$name\" aggiornato';
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
  String get chat_noMessages => 'Nessun messaggio ancora';

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
  String chat_sendMessageTo(String contactName) {
    return 'Invia un messaggio a $contactName';
  }

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
  String get chat_reply => 'Rispondi';

  @override
  String get chat_addReaction => 'Aggiungi Reazione';

  @override
  String get chat_me => 'Me';

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
    return '- Destinazione PubChiave: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Timestamp: $timestamp';
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
  String get chat_pathManagement => 'Gestione Percorsi';

  @override
  String get chat_ShowAllPaths => 'Mostra tutti i percorsi';

  @override
  String get chat_routingMode => 'Modalità di routing';

  @override
  String get chat_autoUseSavedPath => 'Utilizza il percorso salvato';

  @override
  String get chat_forceFloodMode => 'Modalità Inondamento Forzato';

  @override
  String get chat_recentAckPaths => 'Percorsi ACK Recenti (tocca per usare):';

  @override
  String get chat_pathHistoryFull =>
      'La cronologia del percorso è piena. Rimuovi gli elementi per aggiungere nuovi.';

  @override
  String get chat_hopSingular => 'salta';

  @override
  String get chat_hopPlural => 'salta';

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
  String get chat_successes => 'successi';

  @override
  String get chat_removePath => 'Rimuovi percorso';

  @override
  String get chat_noPathHistoryYet =>
      'Non c\'è ancora una cronologia del percorso.\nInvia un messaggio per scoprire i percorsi.';

  @override
  String get chat_pathActions => 'Azioni Percorso:';

  @override
  String get chat_setCustomPath => 'Imposta Percorso Personalizzato';

  @override
  String get chat_setCustomPathSubtitle =>
      'Specifica manualmente il percorso di routing';

  @override
  String get chat_clearPath => 'Cancella Percorso';

  @override
  String get chat_clearPathSubtitle =>
      'Riprova la scoperta alla prossima invio';

  @override
  String get chat_pathCleared =>
      'Percorso sgomberato. Il prossimo messaggio riidentifierà il percorso.';

  @override
  String get chat_floodModeSubtitle =>
      'Utilizza l\'interruttore di routing nella barra delle applicazioni';

  @override
  String get chat_floodModeEnabled =>
      'Modalità alluvione abilitata. Disattivala tramite l\'icona di routing nella barra in alto.';

  @override
  String get chat_fullPath => 'Percorso Completo';

  @override
  String get chat_pathDetailsNotAvailable =>
      'I dettagli del percorso non sono ancora disponibili. Prova a inviare un messaggio per ricaricare.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Percorso impostato: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Salvatato localmente. Connetti per sincronizzare.';

  @override
  String get chat_pathDeviceConfirmed => 'Dispositivo confermato.';

  @override
  String get chat_pathDeviceNotConfirmed =>
      'Dispositivo non confermato ancora.';

  @override
  String get chat_type => 'Digita';

  @override
  String get chat_path => 'Percorso';

  @override
  String get chat_publicKey => 'Chiave Pubblica';

  @override
  String get chat_compressOutgoingMessages => 'Comprimi messaggi in uscita';

  @override
  String get chat_floodForced => 'Inondazione (forzata)';

  @override
  String get chat_directForced => 'Riavvia (forzato)';

  @override
  String chat_hopsForced(int count) {
    return '$count salti (forzati)';
  }

  @override
  String get chat_floodAuto => 'Inondazione (auto)';

  @override
  String get chat_direct => 'Salva';

  @override
  String get chat_poiShared => 'Punti di Interesse Condivisi';

  @override
  String chat_unread(int count) {
    return 'Non letti: $count';
  }

  @override
  String get chat_openLink => 'Aprire il link?';

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
  String get map_title => 'Mappa Nodi';

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
    return 'Puntatori: $count';
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
  String get map_pinDm => 'Codice PIN (DM)';

  @override
  String get map_pinPrivate => 'Blocco (Privato)';

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
  String get map_shareMarkerHere => 'Condividi marcatore qui';

  @override
  String get map_pinLabel => 'Etichetta PIN';

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
  String get map_publicLocationShare => 'Condividi in una posizione pubblica';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Stai per condividere una posizione in $channelLabel. Questo canale è pubblico e chiunque abbia la PSK può vederlo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Connetti a un dispositivo per condividere i segnaposti';

  @override
  String get map_filterNodes => 'Filtra Nodi';

  @override
  String get map_nodeTypes => 'Tipi di Nodo';

  @override
  String get map_chatNodes => 'Nodi di Chat';

  @override
  String get map_repeaters => 'Ripetitori';

  @override
  String get map_otherNodes => 'Altri Nodi';

  @override
  String get map_keyPrefix => 'Prefisso Chiave';

  @override
  String get map_filterByKeyPrefix => 'Filtra per prefisso chiave';

  @override
  String get map_publicKeyPrefix => 'Prefisso chiave pubblica';

  @override
  String get map_markers => 'Segnaposto';

  @override
  String get map_showSharedMarkers => 'Mostra i segnaposto condivisi';

  @override
  String get map_showGuessedLocations => 'Mostra le posizioni stimate dei nodi';

  @override
  String get map_showDiscoveryContacts => 'Mostra Contatti di Discovery';

  @override
  String get map_guessedLocation => 'Località indovinata';

  @override
  String get map_lastSeenTime => 'Ultimo Tempo di Visualizzazione';

  @override
  String get map_sharedPin => 'Condividi PIN';

  @override
  String get map_joinRoom => 'Unisciti alla stanza';

  @override
  String get map_manageRepeater => 'Gestisci Ripetitore';

  @override
  String get map_tapToAdd => 'Tocca i nodi per aggiungerli al percorso.';

  @override
  String get map_runTrace => 'Esegui Path Trace';

  @override
  String get map_removeLast => 'Rimuovi ultimo';

  @override
  String get map_pathTraceCancelled => 'Tracciamento del percorso annullato.';

  @override
  String get mapCache_title => 'Cache Mappa Offline';

  @override
  String get mapCache_selectAreaFirst =>
      'Seleziona un\'area da memorizzare nella cache per prima.';

  @override
  String get mapCache_noTilesToDownload =>
      'Nessun tile da scaricare per questa area';

  @override
  String get mapCache_downloadTilesTitle => 'Scarica mattoncini';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Scarica $count tile per l\'uso offline?';
  }

  @override
  String get mapCache_downloadAction => 'Scarica';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Cacheggiate $count tile';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Tile memorizzati $downloaded ($failed falliti)';
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
  String get mapCache_cacheArea => 'Area Cache';

  @override
  String get mapCache_useCurrentView => 'Utilizza la visualizzazione corrente';

  @override
  String get mapCache_zoomRange => 'Intervallo Zoom';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Stima dei mattoni: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Scaricati $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Scarica Tessere';

  @override
  String get mapCache_clearCacheButton => 'Svuota Cache';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Download falliti: $count';
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
  String get time_allTime => 'Tutto il Tempo';

  @override
  String get dialog_disconnect => 'Disconnetti';

  @override
  String get dialog_disconnectConfirm =>
      'Sei sicuro di voler disconnetterti da questo dispositivo?';

  @override
  String get login_repeaterLogin => 'Login Ripetitore';

  @override
  String get login_roomLogin => 'Login Camera';

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
  String get login_forceFloodMode => 'Modalità Inondamento Forzato';

  @override
  String get login_managePaths => 'Gestisci Percorsi';

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
  String get common_reload => 'Ricaricare';

  @override
  String get common_clear => 'Cancella';

  @override
  String path_currentPath(String path) {
    return 'Percorso corrente: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Utilizzare $count $_temp0 percorso';
  }

  @override
  String get path_enterCustomPath => 'Inserisci percorso personalizzato';

  @override
  String get path_currentPathLabel => 'Percorso corrente';

  @override
  String get path_hexPrefixInstructions =>
      'Inserire i prefissi esadecimali a 2 caratteri per ogni salto, separati da virgole.';

  @override
  String get path_hexPrefixExample =>
      'Esempio: A1,F2,3C (ogni nodo utilizza il primo byte della sua chiave pubblica)';

  @override
  String get path_labelHexPrefixes => 'Prefisso esadecimale (percorso)';

  @override
  String get path_helperMaxHops =>
      'Massimo 64 salti. Ogni prefisso è composto da 2 caratteri esadecimali (1 byte)';

  @override
  String get path_selectFromContacts => 'Seleziona da contatti:';

  @override
  String get path_noRepeatersFound =>
      'Non sono stati trovati ripetitori o server di stanza.';

  @override
  String get path_customPathsRequire =>
      'I percorsi personalizzati richiedono salti intermedi che possono inoltrare messaggi.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Prefissi esadecimali non validi: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Il percorso è troppo lungo. Massimo 64 salti consentiti.';

  @override
  String get path_setPath => 'Imposta Percorso';

  @override
  String get repeater_management => 'Gestione Ripetitori';

  @override
  String get room_management => 'Gestione del Server di Camera';

  @override
  String get repeater_managementTools => 'Strumenti di Gestione';

  @override
  String get repeater_status => 'Stato';

  @override
  String get repeater_statusSubtitle =>
      'Visualizza lo stato, le statistiche e i vicini del ripetitore';

  @override
  String get repeater_telemetry => 'Telemetry';

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
  String get repeater_neighborsSubtitle =>
      'Visualizza vicini di salto pari a zero.';

  @override
  String get repeater_settings => 'Impostazioni';

  @override
  String get repeater_settingsSubtitle =>
      'Configura i parametri del ripetitore';

  @override
  String get repeater_statusTitle => 'Stato del Ripetitore';

  @override
  String get repeater_routingMode => 'Modalità di routing';

  @override
  String get repeater_autoUseSavedPath => 'Percorso salvato automatico';

  @override
  String get repeater_forceFloodMode => 'Modalità Inondamento Forzato';

  @override
  String get repeater_pathManagement => 'Gestione dei percorsi';

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
  String get repeater_uptime => 'Disponibilità';

  @override
  String get repeater_queueLength => 'Lunghezza della coda';

  @override
  String get repeater_debugFlags => 'Impostazioni Debug';

  @override
  String get repeater_radioStatistics => 'Statistiche Radio';

  @override
  String get repeater_lastRssi => 'Ultimo RSSI';

  @override
  String get repeater_lastSnr => 'Ultimo SNR';

  @override
  String get repeater_noiseFloor => 'Livello del Rumore';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistiche del Pacchetto';

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
    return 'Totale: $total, Inondazione: $flood, Diretto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Totale: $total, Inondazione: $flood, Diretto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Inondazione: $flood, Diretto: $direct';
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
      'Visualizza il nome di questo ripetitore';

  @override
  String get repeater_adminPassword => 'Password Amministratore';

  @override
  String get repeater_adminPasswordHelper => 'Accesso completo password';

  @override
  String get repeater_guestPassword => 'Password Ospite';

  @override
  String get repeater_guestPasswordHelper =>
      'Accesso in sola lettura con password';

  @override
  String get repeater_radioSettings => 'Impostazioni Radio';

  @override
  String get repeater_frequencyMhz => 'Frequenza (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Potenza';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Larghezza di banda';

  @override
  String get repeater_spreadingFactor => 'Spreading Factor';

  @override
  String get repeater_codingRate => 'Tasso di Codifica';

  @override
  String get repeater_locationSettings => 'Impostazioni Luogo';

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
  String get repeater_packetForwarding => 'Instradamento Pacchetti';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Abilita il ripetitore per inoltrare i pacchetti';

  @override
  String get repeater_guestAccess => 'Accesso Ospite';

  @override
  String get repeater_guestAccessSubtitle =>
      'Consenti l\'accesso ospite in sola lettura';

  @override
  String get repeater_privacyMode => 'Modalità Privacy';

  @override
  String get repeater_privacyModeSubtitle =>
      'Nascondere nome/luogo negli annunci';

  @override
  String get repeater_advertisementSettings => 'Impostazioni Annuncio';

  @override
  String get repeater_localAdvertInterval => 'Intervallo Pubblicità Locale';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minuti';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervallo Pubblicità Inondazione';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours ore';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervallo Pubblicitario Crittografato';

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
  String get repeater_refreshLocationSettings =>
      'Aggiorna le Impostazioni della Posizione';

  @override
  String get repeater_refreshPacketForwarding =>
      'Aggiorna il inoltro pacchetti';

  @override
  String get repeater_refreshGuestAccess => 'Aggiorna Accesso Ospite';

  @override
  String get repeater_refreshPrivacyMode => 'Aggiorna Modalità Privacy';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Aggiorna le Impostazioni dell\'Annuncio';

  @override
  String repeater_refreshed(String label) {
    return '$label aggiornato';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Errore durante il ricaricamento di $label';
  }

  @override
  String get repeater_cliTitle => 'Riprova CLI';

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
  String get repeater_cliQuickAdvertise => 'Pubblicare';

  @override
  String get repeater_cliQuickClock => 'Orologio';

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
      '(Server della stanza) Se \'on\', allora l\'accesso con una password vuota sarà consentito, ma non sarà possibile pubblicare nella stanza. (solo lettura).';

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
      'Imposta un fattore moltiplicato con il tempo di mantenimento per un pacchetto di modalità allagamento e con un sistema di slot casuale, per ritardarne la trasmissione (per diminuire la probabilità di collisioni).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Uguale a txdelay, ma per applicare un ritardo casuale alla inoltrata di pacchetti in modalità diretta.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Abilita/Disabilita ponte.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Imposta il ritardo prima di ritrasmettere i pacchetti.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Scegliere se il ponte dovrà ritrasmettere i pacchetti ricevuti o i pacchetti trasmessi.';

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
      'Ottiene tipo ponte nessuno, rs232, espnow';

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
      'Imposta il permesso di \'F\'lood per la regione specificata. (\'\' per lo scope globale/legacy)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Rimuove il permesso \'F\'lood per la regione specificata. (NOTA: a questo stadio non è consigliato utilizzarlo sullo scope globale/legacy!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Risposte con la regione \'home\' corrente. (Nota applicata finora, riservata per il futuro)';

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
  String get neighbors_receivedData => 'Ricevute dati vicini';

  @override
  String get neighbors_requestTimedOut => 'I vicini richiedono un timeout.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Errore nel caricamento dei vicini: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ripetitori Vicini';

  @override
  String get neighbors_noData => 'Nessun dato sugli vicini disponibile.';

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
  String get channelPath_viewMap => 'Visualizza la mappa';

  @override
  String get channelPath_otherObservedPaths => 'Altri Percorsi Osservati';

  @override
  String get channelPath_repeaterHops => 'Passaggi Ripetitore';

  @override
  String get channelPath_noHopDetails =>
      'I dettagli relativi a questo pacchetto non sono forniti.';

  @override
  String get channelPath_messageDetails => 'Dettagli Messaggio';

  @override
  String get channelPath_senderLabel => 'Mittente';

  @override
  String get channelPath_timeLabel => 'Tempo';

  @override
  String get channelPath_repeatsLabel => 'Ripeti';

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
  String get channelPath_floodPath => 'Inondazione';

  @override
  String get channelPath_directPath => 'Salva';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 di $total salti';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed di $total salti';
  }

  @override
  String get channelPath_mapTitle => 'Mappa del Percorso';

  @override
  String get channelPath_noRepeaterLocations =>
      'Non sono disponibili posizioni per i ripetitori per questo percorso.';

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
  String get listFilter_heardRecently => 'Sentito di recente';

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
  String get listFilter_roomServers => 'Server della stanza';

  @override
  String get listFilter_unreadOnly => 'Solo non letto';

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
  String get pathTrace_refreshTooltip => 'Aggiorna Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Uno o più dei luppoli mancano di una posizione!';

  @override
  String get pathTrace_clearTooltip => 'Pulisci percorso';

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
}
