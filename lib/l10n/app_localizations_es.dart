// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Contactos';

  @override
  String get nav_channels => 'Canales';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_ok => 'De acuerdo';

  @override
  String get common_connect => 'Conectar';

  @override
  String get common_unknownDevice => 'Dispositivo Desconocido';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_deleteAll => 'Eliminar todo';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_add => 'Añadir';

  @override
  String get common_settings => 'Configuración';

  @override
  String get common_disconnect => 'Desconectar';

  @override
  String get common_connected => 'Conectado';

  @override
  String get common_disconnected => 'Desconectado';

  @override
  String get common_create => 'Crear';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_share => 'Compartir';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_retry => 'Intentar';

  @override
  String get common_hide => 'Ocultar';

  @override
  String get common_remove => 'Eliminar';

  @override
  String get common_enable => 'Activar';

  @override
  String get common_disable => 'Desactivar';

  @override
  String get common_reboot => 'Reiniciar';

  @override
  String get common_loading => 'Cargando...';

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
  String get usbScreenTitle => 'Conecte mediante USB';

  @override
  String get usbScreenSubtitle =>
      'Seleccione el dispositivo de serie detectado y conéctelo directamente a su nodo MeshCore.';

  @override
  String get usbScreenStatus => 'Seleccione un dispositivo USB';

  @override
  String get usbScreenNote =>
      'La comunicación serial a través de USB está activa en dispositivos Android compatibles y en plataformas de escritorio.';

  @override
  String get usbScreenEmptyState =>
      'No se encontraron dispositivos USB. Conecte uno y vuelva a intentar.';

  @override
  String get usbErrorPermissionDenied =>
      'Se denegó el permiso de acceso a través de USB.';

  @override
  String get usbErrorDeviceMissing =>
      'El dispositivo USB seleccionado ya no está disponible.';

  @override
  String get usbErrorInvalidPort => 'Seleccione un dispositivo USB válido.';

  @override
  String get usbErrorBusy =>
      'Ya se ha iniciado una solicitud de conexión USB adicional.';

  @override
  String get usbErrorNotConnected => 'No hay ningún dispositivo USB conectado.';

  @override
  String get usbErrorOpenFailed =>
      'No se pudo abrir el dispositivo USB seleccionado.';

  @override
  String get usbErrorConnectFailed =>
      'No se pudo conectar con el dispositivo USB seleccionado.';

  @override
  String get usbErrorUnsupported =>
      'La comunicación serial a través de USB no está soportada en esta plataforma.';

  @override
  String get usbErrorAlreadyActive => 'La conexión USB ya está activa.';

  @override
  String get usbErrorNoDeviceSelected =>
      'No se ha seleccionado ningún dispositivo USB.';

  @override
  String get usbErrorPortClosed => 'La conexión USB no está activa.';

  @override
  String get usbErrorConnectTimedOut =>
      'La conexión ha caducado. Asegúrese de que el dispositivo tenga el firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Dispositivo de serie web';

  @override
  String get usbStatus_notConnected => 'Seleccione un dispositivo USB';

  @override
  String get usbStatus_connecting => 'Conectándose al dispositivo USB...';

  @override
  String get usbStatus_searching => 'Buscando dispositivos USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Error al conectar mediante USB: $error';
  }

  @override
  String get scanner_scanning => 'Escaneando dispositivos...';

  @override
  String get scanner_connecting => 'Conectando...';

  @override
  String get scanner_disconnecting => 'Desconectando...';

  @override
  String get scanner_notConnected => 'No está conectado';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Buscando dispositivos MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Toca Escanear para encontrar dispositivos MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get scanner_stop => 'Detener';

  @override
  String get scanner_scan => 'Escanea';

  @override
  String get scanner_bluetoothOff => 'Bluetooth está desactivado.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Por favor, active el Bluetooth para escanear dispositivos.';

  @override
  String get scanner_chromeRequired => 'Navegador Chrome requerido';

  @override
  String get scanner_chromeRequiredMessage =>
      'Esta aplicación web requiere Google Chrome o un navegador basado en Chromium para el soporte de Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Habilitar Bluetooth';

  @override
  String get device_quickSwitch => 'Cambiar rápidamente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Configuración';

  @override
  String get settings_deviceInfo => 'Información del dispositivo';

  @override
  String get settings_appSettings => 'Configuración de la App';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificaciones, mensajes y preferencias de mapa';

  @override
  String get settings_nodeSettings => 'Configuración del Nodo';

  @override
  String get settings_nodeName => 'Nombre del nodo';

  @override
  String get settings_nodeNameNotSet => 'No está configurado';

  @override
  String get settings_nodeNameHint => 'Introducir nombre de nodo';

  @override
  String get settings_nodeNameUpdated => 'Nombre actualizado';

  @override
  String get settings_radioSettings => 'Configuración de Radio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frecuencia, potencia, factor de dispersión';

  @override
  String get settings_radioSettingsUpdated => 'Ajustes de radio actualizados';

  @override
  String get settings_location => 'Ubicación';

  @override
  String get settings_locationSubtitle => 'Coordenadas GPS';

  @override
  String get settings_locationUpdated => 'Ubicación actualizada';

  @override
  String get settings_locationBothRequired =>
      'Introduzca tanto la latitud como la longitud.';

  @override
  String get settings_locationInvalid => 'Latitud o longitud inválidos.';

  @override
  String get settings_locationGPSEnable => 'Habilitar GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Habilita la actualización automática de la ubicación mediante GPS.';

  @override
  String get settings_locationIntervalSec => 'Intervalo para GPS (Segundos)';

  @override
  String get settings_locationIntervalInvalid =>
      'El intervalo debe ser de al menos 60 segundos y menor que 86400 segundos.';

  @override
  String get settings_latitude => 'Latitud';

  @override
  String get settings_longitude => 'Longitud';

  @override
  String get settings_contactSettings => 'Configuración de contacto';

  @override
  String get settings_contactSettingsSubtitle =>
      'Configuración de cómo se agregan los contactos.';

  @override
  String get settings_privacyMode => 'Modo Privacidad';

  @override
  String get settings_privacyModeSubtitle =>
      'Ocultar nombre/ubicación en anuncios';

  @override
  String get settings_privacyModeToggle =>
      'Activar el modo de privacidad para ocultar tu nombre y ubicación en los anuncios.';

  @override
  String get settings_privacyModeEnabled => 'Modo de privacidad activado';

  @override
  String get settings_privacyModeDisabled => 'Modo de privacidad desactivado';

  @override
  String get settings_actions => 'Acciones';

  @override
  String get settings_sendAdvertisement => 'Enviar Anuncio';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Presencia de transmisión ahora';

  @override
  String get settings_advertisementSent => 'Anuncio enviado';

  @override
  String get settings_syncTime => 'Tiempo de Sincronización';

  @override
  String get settings_syncTimeSubtitle =>
      'Establecer la hora del dispositivo al tiempo del teléfono';

  @override
  String get settings_timeSynchronized => 'Sincronizado en el tiempo';

  @override
  String get settings_refreshContacts => 'Actualizar Contactos';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recargar lista de contactos del dispositivo';

  @override
  String get settings_rebootDevice => 'Reiniciar Dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Reiniciar el dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      '¿Está seguro de que desea reiniciar el dispositivo? Se desconectará.';

  @override
  String get settings_debug => 'Depurar';

  @override
  String get settings_bleDebugLog => 'Registro de Depuración BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Comandos, respuestas y datos brutos de BLE';

  @override
  String get settings_appDebugLog => 'Registro de Depuración de la App';

  @override
  String get settings_appDebugLogSubtitle =>
      'Mensajes de depuración de la aplicación';

  @override
  String get settings_about => 'Acerca de';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 Proyecto Open Source MeshCore';

  @override
  String get settings_aboutDescription =>
      'Un cliente de código abierto de Flutter para dispositivos de red mesh LoRa de MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Datos de elevación LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nombre';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Estado';

  @override
  String get settings_infoBattery => 'Batería';

  @override
  String get settings_infoPublicKey => 'Clave Pública';

  @override
  String get settings_infoContactsCount => 'Número de contactos';

  @override
  String get settings_infoChannelCount => 'Número de canales';

  @override
  String get settings_presets => 'Preajustes';

  @override
  String get settings_frequency => 'Frecuencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Frecuencia inválida (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Ancho de banda';

  @override
  String get settings_spreadingFactor => 'Factor de propagación';

  @override
  String get settings_codingRate => 'Tasa de Programación';

  @override
  String get settings_txPower => 'TX Potencia (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Potencia de TX inválida (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Repetir sin conexión';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permita que este dispositivo repita los paquetes de red para otros usuarios.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Para la comunicación fuera de la red, se requiere una frecuencia de 433, 869 o 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Error: $message';
  }

  @override
  String get appSettings_title => 'Configuración de la App';

  @override
  String get appSettings_appearance => 'Apariencia';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Valor predeterminado del sistema';

  @override
  String get appSettings_themeLight => 'Luz';

  @override
  String get appSettings_themeDark => 'Oscuro';

  @override
  String get appSettings_language => 'Idioma';

  @override
  String get appSettings_languageSystem => 'Predeterminado del sistema';

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
  String get appSettings_languageRu => 'Ruso';

  @override
  String get appSettings_languageUk => 'Ucraniano';

  @override
  String get appSettings_enableMessageTracing =>
      'Habilitar seguimiento de mensajes';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostrar metadatos detallados de enrutamiento y tiempo para los mensajes';

  @override
  String get appSettings_notifications => 'Notificaciones';

  @override
  String get appSettings_enableNotifications => 'Habilitar Notificaciones';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Recibir notificaciones para mensajes y anuncios';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permiso de notificación denegado';

  @override
  String get appSettings_notificationsEnabled => 'Notificaciones activadas';

  @override
  String get appSettings_notificationsDisabled => 'Notificaciones desactivadas';

  @override
  String get appSettings_messageNotifications => 'Notificaciones de Mensaje';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostrar notificación al recibir nuevos mensajes';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notificaciones de Mensajes del Canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostrar notificación al recibir mensajes del canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notificaciones de Anuncios';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostrar notificación cuando se descubren nuevos nodos';

  @override
  String get appSettings_messaging => 'Mensajería';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Borrar Camino en Max Reintentos';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Restablecer la ruta de contacto después de 5 intentos de envío fallidos';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Los caminos se limpiarán después de 5 intentos fallidos.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Las rutas no se eliminarán automáticamente.';

  @override
  String get appSettings_autoRouteRotation => 'Rotación de Ruta Automática';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Alternar entre las mejores rutas y el modo inundación';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Rotación de ruta automática habilitada';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Rotación de ruta automática desactivada';

  @override
  String get appSettings_battery => 'Batería';

  @override
  String get appSettings_batteryChemistry => 'Química de la batería';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Configuración por dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Conéctate a un dispositivo para elegir';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => 'Visualización del Mapa';

  @override
  String get appSettings_showRepeaters => 'Mostrar Repetidores';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Mostrar nodos de repetidor en el mapa';

  @override
  String get appSettings_showChatNodes => 'Mostrar Nodos de Chat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Mostrar nodos de chat en el mapa';

  @override
  String get appSettings_showOtherNodes => 'Mostrar otros nodos';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mostrar otros tipos de nodo en el mapa';

  @override
  String get appSettings_timeFilter => 'Filtro de Tiempo';

  @override
  String get appSettings_timeFilterShowAll => 'Mostrar todos los nodos';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostrar nodos de las últimas $hours horas';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro de Tiempo del Mapa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostrar nodos descubiertos dentro de:';

  @override
  String get appSettings_allTime => 'Todo el tiempo';

  @override
  String get appSettings_lastHour => 'Última hora';

  @override
  String get appSettings_last6Hours => 'Últimas 6 horas';

  @override
  String get appSettings_last24Hours => 'Últimas 24 horas';

  @override
  String get appSettings_lastWeek => 'La semana pasada';

  @override
  String get appSettings_offlineMapCache => 'Caché de Mapa Offline';

  @override
  String get appSettings_unitsTitle => 'Unidades';

  @override
  String get appSettings_unitsMetric => 'Métrico (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (pies/millas)';

  @override
  String get appSettings_noAreaSelected => 'No se ha seleccionado ningún área';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Área seleccionada (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Depurar';

  @override
  String get appSettings_appDebugLogging => 'Registro de Depuración de la App';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Registrar mensajes de depuración de la app de registro para solucionar problemas';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Registro de depuración de la aplicación habilitado';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'El registro de depuración de la aplicación está desactivado';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_noContacts => 'Aún no hay contactos.';

  @override
  String get contacts_contactsWillAppear =>
      'Los contactos aparecerán cuando los dispositivos anuncien.';

  @override
  String get contacts_unread => 'No leído';

  @override
  String get contacts_searchContactsNoNumber => 'Buscar contactos...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Buscar contactos...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Buscar $number$str Favoritos...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Buscar $number$str Usuarios...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Buscar $number$str Repetidores...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Buscar $number$str servidores de sala...';
  }

  @override
  String get contacts_noUnreadContacts => 'No contactos sin leer';

  @override
  String get contacts_noContactsFound =>
      'No se encontraron contactos ni grupos.';

  @override
  String get contacts_deleteContact => 'Eliminar Contacto';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Eliminar $contactName de los contactos?';
  }

  @override
  String get contacts_manageRepeater => 'Gestionar Repetidor';

  @override
  String get contacts_manageRoom => 'Gestionar Servidor de Habitación';

  @override
  String get contacts_roomLogin => 'Inicio de Sala';

  @override
  String get contacts_openChat => 'Abrir Chat';

  @override
  String get contacts_editGroup => 'Editar Grupo';

  @override
  String get contacts_deleteGroup => 'Eliminar Grupo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eliminar $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nuevo Grupo';

  @override
  String get contacts_groupName => 'Nombre del grupo';

  @override
  String get contacts_groupNameRequired => 'El nombre del grupo es obligatorio';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'El grupo \"$name\" ya existe';
  }

  @override
  String get contacts_filterContacts => 'Filtrar contactos...';

  @override
  String get contacts_noContactsMatchFilter =>
      'No hay contactos que coincidan con tu filtro';

  @override
  String get contacts_noMembers => 'No miembros';

  @override
  String get contacts_lastSeenNow => 'Última vez que se vio ahora';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 hora';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours horas';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 día';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days días';
  }

  @override
  String get channels_title => 'Canales';

  @override
  String get channels_noChannelsConfigured => 'No se han configurado canales';

  @override
  String get channels_addPublicChannel => 'Añadir Canal Público';

  @override
  String get channels_searchChannels => 'Buscar canales...';

  @override
  String get channels_noChannelsFound => 'No se encontraron canales';

  @override
  String channels_channelIndex(int index) {
    return 'Canal $index';
  }

  @override
  String get channels_hashtagChannel => 'Canal con hashtag';

  @override
  String get channels_public => 'Público';

  @override
  String get channels_private => 'Privado';

  @override
  String get channels_publicChannel => 'Canal público';

  @override
  String get channels_privateChannel => 'Canal privado';

  @override
  String get channels_editChannel => 'Editar canal';

  @override
  String get channels_muteChannel => 'Silenciar canal';

  @override
  String get channels_unmuteChannel => 'Activar canal';

  @override
  String get channels_deleteChannel => 'Eliminar canal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Eliminar \"$name\"? Esto no se puede deshacer.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'No se pudo eliminar el canal \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canal \"$name\" eliminado';
  }

  @override
  String get channels_addChannel => 'Añadir Canal';

  @override
  String get channels_channelIndexLabel => 'Índice de Canal';

  @override
  String get channels_channelName => 'Nombre del canal';

  @override
  String get channels_usePublicChannel => 'Usar Canal Público';

  @override
  String get channels_standardPublicPsk => 'PSK estándar público';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Generar PSK aleatorio';

  @override
  String get channels_enterChannelName =>
      'Por favor, introduce un nombre de canal';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK debe ser de 32 caracteres hexadecimales.';

  @override
  String channels_channelAdded(String name) {
    return 'Canal \"$name\" añadido';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Editar Canal $index';
  }

  @override
  String get channels_smazCompression => 'Compresión SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Canal \"$name\" actualizado';
  }

  @override
  String get channels_publicChannelAdded => 'Canal público añadido';

  @override
  String get channels_sortBy => 'Ordenar por';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Últimos mensajes';

  @override
  String get channels_sortUnread => 'Sin leer';

  @override
  String get channels_createPrivateChannel => 'Crear un Canal Privado';

  @override
  String get channels_createPrivateChannelDesc =>
      'Cifrado con una clave secreta.';

  @override
  String get channels_joinPrivateChannel => 'Únete a un Canal Privado';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Introducir manualmente una clave secreta.';

  @override
  String get channels_joinPublicChannel => 'Únete al Canal Público';

  @override
  String get channels_joinPublicChannelDesc =>
      'Cualquiera puede unirse a este canal.';

  @override
  String get channels_joinHashtagChannel => 'Únete a un Canal con Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Cualquiera puede unirse a los canales de hashtag.';

  @override
  String get channels_scanQrCode => 'Escanear un Código QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Próximamente';

  @override
  String get channels_enterHashtag => 'Introducir hashtag';

  @override
  String get channels_hashtagHint => 'ej. #equipo';

  @override
  String get chat_noMessages => 'Aún no hay mensajes';

  @override
  String get chat_sendMessageToStart => 'Enviar un mensaje para comenzar';

  @override
  String get chat_originalMessageNotFound => 'Mensaje original no encontrado';

  @override
  String chat_replyingTo(String name) {
    return 'Responder a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get chat_location => 'Ubicación';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Enviar un mensaje a $contactName';
  }

  @override
  String get chat_typeMessage => 'Escribe un mensaje...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Mensaje demasiado largo (máximo $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Mensaje copiado';

  @override
  String get chat_messageDeleted => 'Mensaje borrado';

  @override
  String get chat_retryingMessage => 'Reintentando…';

  @override
  String chat_retryCount(int current, int max) {
    return 'Reintentar $current/$max';
  }

  @override
  String get chat_sendGif => 'Enviar GIF';

  @override
  String get chat_reply => 'Responder';

  @override
  String get chat_addReaction => 'Añadir Reacción';

  @override
  String get chat_me => 'Yo';

  @override
  String get emojiCategorySmileys => 'Emoticones';

  @override
  String get emojiCategoryGestures => 'Gestos';

  @override
  String get emojiCategoryHearts => 'Corazones';

  @override
  String get emojiCategoryObjects => 'Objetos';

  @override
  String get gifPicker_title => 'Elegir un GIF';

  @override
  String get gifPicker_searchHint => 'Buscar GIFs...';

  @override
  String get gifPicker_poweredBy => 'Powered by GIPHY';

  @override
  String get gifPicker_noGifsFound => 'No se encontraron GIFs';

  @override
  String get gifPicker_failedLoad => 'No se pudo cargar los GIFs';

  @override
  String get gifPicker_failedSearch => 'No se encontraron GIFs';

  @override
  String get gifPicker_noInternet => 'No hay conexión a internet';

  @override
  String get debugLog_appTitle => 'Registro de Depuración de la App';

  @override
  String get debugLog_bleTitle => 'Registro de Depuración BLE';

  @override
  String get debugLog_copyLog => 'Copiar registro';

  @override
  String get debugLog_clearLog => 'Borrar registro';

  @override
  String get debugLog_copied => 'Registro de depuración copiado';

  @override
  String get debugLog_bleCopied => 'Registro BLE copiado';

  @override
  String get debugLog_noEntries => 'Aún no hay registros de depuración.';

  @override
  String get debugLog_enableInSettings =>
      'Habilitar el registro de depuración de la aplicación en la configuración';

  @override
  String get debugLog_frames => 'Marcos';

  @override
  String get debugLog_rawLogRx => 'Registro Crudo-RX';

  @override
  String get debugLog_noBleActivity => 'Aún no hay actividad BLE';

  @override
  String debugFrame_length(int count) {
    return 'Longitud del Marco: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Mensaje de Texto:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destino PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Marca de tiempo: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Banderas: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tipo de texto: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Sencillo';

  @override
  String debugFrame_text(String text) {
    return '- Texto: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Mapeo Hexadecimal:';

  @override
  String get chat_pathManagement => 'Gestión de Rutas';

  @override
  String get chat_ShowAllPaths => 'Mostrar todos los caminos';

  @override
  String get chat_routingMode => 'Modo de enrutamiento';

  @override
  String get chat_autoUseSavedPath => 'Auto (usar la ruta guardada)';

  @override
  String get chat_forceFloodMode => 'Modo Inundación Forzado';

  @override
  String get chat_recentAckPaths => 'Rutas de ACK Recientes (tocar para usar):';

  @override
  String get chat_pathHistoryFull =>
      'El historial de rutas está completo. Eliminar entradas para añadir nuevas.';

  @override
  String get chat_hopSingular => 'salta';

  @override
  String get chat_hopPlural => 'salta';

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
  String get chat_successes => 'Éxitos';

  @override
  String get chat_removePath => 'Eliminar ruta';

  @override
  String get chat_noPathHistoryYet =>
      'Aún no hay historial de rutas.\nEnvía un mensaje para descubrir rutas.';

  @override
  String get chat_pathActions => 'Acciones de Ruta:';

  @override
  String get chat_setCustomPath => 'Establecer Ruta Personalizada';

  @override
  String get chat_setCustomPathSubtitle =>
      'Especificar manualmente la ruta de enrutamiento';

  @override
  String get chat_clearPath => 'Limpiar Ruta';

  @override
  String get chat_clearPathSubtitle =>
      'Forzar redescubrimiento en el próximo envío';

  @override
  String get chat_pathCleared =>
      'Ruta eliminada. El siguiente mensaje redescubrirá la ruta.';

  @override
  String get chat_floodModeSubtitle =>
      'Utilizar el interruptor de enrutamiento en la barra de herramientas';

  @override
  String get chat_floodModeEnabled =>
      'El modo de inundación está habilitado. Desactívalo mediante el icono de enrutamiento en la barra de herramientas de la aplicación.';

  @override
  String get chat_fullPath => 'Ruta completa';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Los detalles de la ruta aún no están disponibles. Intenta enviar un mensaje para refrescar.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Ruta establecida: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Guardado localmente. Conéctate para sincronizar.';

  @override
  String get chat_pathDeviceConfirmed => 'Dispositivo confirmado.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Dispositivo aún no confirmado.';

  @override
  String get chat_type => 'Escribe';

  @override
  String get chat_path => 'Ruta';

  @override
  String get chat_publicKey => 'Clave Pública';

  @override
  String get chat_compressOutgoingMessages => 'Comprimir mensajes salientes';

  @override
  String get chat_floodForced => 'Inundación (forzada)';

  @override
  String get chat_directForced => 'Directo (forzado)';

  @override
  String chat_hopsForced(int count) {
    return '$count saltos (forzados)';
  }

  @override
  String get chat_floodAuto => 'Inundación (automática)';

  @override
  String get chat_direct => 'Guardar';

  @override
  String get chat_poiShared => 'Punto de Interés Compartido';

  @override
  String chat_unread(int count) {
    return 'Sin leer: $count';
  }

  @override
  String get chat_openLink => '¿Abrir enlace?';

  @override
  String get chat_openLinkConfirmation =>
      '¿Quiere abrir este enlace en su navegador?';

  @override
  String get chat_open => 'Abrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'No se pudo abrir el enlace: $url';
  }

  @override
  String get chat_invalidLink => 'Formato de enlace no válido';

  @override
  String get map_title => 'Mapa de Nodos';

  @override
  String get map_lineOfSight => 'Línea de visión';

  @override
  String get map_losScreenTitle => 'Línea de visión';

  @override
  String get map_noNodesWithLocation => 'No hay nodos con datos de ubicación';

  @override
  String get map_nodesNeedGps =>
      'Los nodos necesitan compartir sus coordenadas GPS\npara aparecer en el mapa';

  @override
  String map_nodesCount(int count) {
    return 'Nodos: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Ganchos: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repetidor';

  @override
  String get map_room => 'Habitación';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Bloqueo (Privado)';

  @override
  String get map_pinPublic => 'Clave (Pública)';

  @override
  String get map_lastSeen => 'Última vez que se vio';

  @override
  String get map_disconnectConfirm =>
      '¿Está seguro de que desea desconectarse de este dispositivo?';

  @override
  String get map_from => 'De';

  @override
  String get map_source => 'Fuente';

  @override
  String get map_flags => 'Banderas';

  @override
  String get map_shareMarkerHere => 'Compartir marcador aquí';

  @override
  String get map_pinLabel => 'Etiqueta de marcador';

  @override
  String get map_label => 'Etiqueta';

  @override
  String get map_pointOfInterest => 'Punto de interés';

  @override
  String get map_sendToContact => 'Enviar a contacto';

  @override
  String get map_sendToChannel => 'Enviar a canal';

  @override
  String get map_noChannelsAvailable => 'No hay canales disponibles';

  @override
  String get map_publicLocationShare => 'Compartir ubicación pública';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Estás a punto de compartir una ubicación en $channelLabel. Este canal es público y cualquiera con la PSK puede verlo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Conéctate a un dispositivo para compartir marcadores';

  @override
  String get map_filterNodes => 'Filtrar Nodos';

  @override
  String get map_nodeTypes => 'Tipos de nodo';

  @override
  String get map_chatNodes => 'Nodos de Chat';

  @override
  String get map_repeaters => 'Repetidores';

  @override
  String get map_otherNodes => 'Otros Nodos';

  @override
  String get map_keyPrefix => 'Prefijo de clave';

  @override
  String get map_filterByKeyPrefix => 'Filtrar por prefijo clave';

  @override
  String get map_publicKeyPrefix => 'Prefijo de clave pública';

  @override
  String get map_markers => 'Marcadores';

  @override
  String get map_showSharedMarkers => 'Mostrar marcadores compartidos';

  @override
  String get map_showGuessedLocations =>
      'Mostrar las ubicaciones estimadas de los nodos.';

  @override
  String get map_showDiscoveryContacts => 'Mostrar Contactos de Descubrimiento';

  @override
  String get map_guessedLocation => 'Ubicación estimada';

  @override
  String get map_lastSeenTime => 'Última vez que se vio';

  @override
  String get map_sharedPin => 'Pin compartido';

  @override
  String get map_joinRoom => 'Únete a la sala';

  @override
  String get map_manageRepeater => 'Gestionar Repetidor';

  @override
  String get map_tapToAdd => 'Pulse en los nodos para agregarlos al camino.';

  @override
  String get map_runTrace => 'Ejecutar Rastreo de Ruta';

  @override
  String get map_removeLast => 'Eliminar último';

  @override
  String get map_pathTraceCancelled => 'Rastreo de ruta cancelado.';

  @override
  String get mapCache_title => 'Caché de Mapa Offline';

  @override
  String get mapCache_selectAreaFirst =>
      'Seleccionar un área para cachear primero';

  @override
  String get mapCache_noTilesToDownload =>
      'No hay azulejos para descargar para este área.';

  @override
  String get mapCache_downloadTilesTitle => 'Descargar ficheros';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Descargar $count ficheros para usar sin conexión?';
  }

  @override
  String get mapCache_downloadAction => 'Descargar';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Almacenados $count azulejos';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Archivados $downloaded azulejos ($failed fallidos)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Borrar caché offline';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Eliminar todas las baldosas en caché del mapa?';

  @override
  String get mapCache_offlineCacheCleared =>
      'Almacén en caché sin conexión eliminado';

  @override
  String get mapCache_noAreaSelected => 'No se ha seleccionado ningún área';

  @override
  String get mapCache_cacheArea => 'Área de Caché';

  @override
  String get mapCache_useCurrentView => 'Usar Vista Actual';

  @override
  String get mapCache_zoomRange => 'Rango de Zoom';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Tiles estimados: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Descargados $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Descargar Mosaicos';

  @override
  String get mapCache_clearCacheButton => 'Borrar Caché';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Descargas fallidas: $count';
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
  String get time_justNow => 'Hace un momento';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minutos hace.';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h hace';
  }

  @override
  String time_daysAgo(int days) {
    return '$days días hace';
  }

  @override
  String get time_hour => 'hora';

  @override
  String get time_hours => 'horas';

  @override
  String get time_day => 'día';

  @override
  String get time_days => 'días';

  @override
  String get time_week => 'semana';

  @override
  String get time_weeks => 'semanas';

  @override
  String get time_month => 'mes';

  @override
  String get time_months => 'meses';

  @override
  String get time_minutes => 'minutos';

  @override
  String get time_allTime => 'Todas las veces';

  @override
  String get dialog_disconnect => 'Desconectar';

  @override
  String get dialog_disconnectConfirm =>
      '¿Está seguro de que desea desconectarse de este dispositivo?';

  @override
  String get login_repeaterLogin => 'Iniciar sesión en el Repetidor';

  @override
  String get login_roomLogin => 'Inicio de Sala';

  @override
  String get login_password => 'Contraseña';

  @override
  String get login_enterPassword => 'Introducir contraseña';

  @override
  String get login_savePassword => 'Guardar contraseña';

  @override
  String get login_savePasswordSubtitle =>
      'La contraseña se almacenará de forma segura en este dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Ingrese la contraseña del repetidor para acceder a la configuración y el estado.';

  @override
  String get login_roomDescription =>
      'Ingrese la contraseña de la sala para acceder a la configuración y el estado.';

  @override
  String get login_routing => 'Enrutamiento';

  @override
  String get login_routingMode => 'Modo de enrutamiento';

  @override
  String get login_autoUseSavedPath => 'Auto (usar la ruta guardada)';

  @override
  String get login_forceFloodMode => 'Activar Modo Inundación Forzada';

  @override
  String get login_managePaths => 'Gestionar Rutas';

  @override
  String get login_login => 'Iniciar sesión';

  @override
  String login_attempt(int current, int max) {
    return 'Intentar $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Inicio fallido: $error';
  }

  @override
  String get login_failedMessage =>
      'Inicio fallido. La contraseña es incorrecta o el repetidor no está disponible.';

  @override
  String get common_reload => 'Recargar';

  @override
  String get common_clear => 'Borrar';

  @override
  String path_currentPath(String path) {
    return 'Ruta actual: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Usando $count $_temp0 ruta';
  }

  @override
  String get path_enterCustomPath => 'Introducir Ruta Personalizada';

  @override
  String get path_currentPathLabel => 'Ruta actual';

  @override
  String get path_hexPrefixInstructions =>
      'Introduzca los prefijos hexadecimales de 2 caracteres para cada salto, separados por comas.';

  @override
  String get path_hexPrefixExample =>
      'Ejemplo: A1,F2,3C (cada nodo utiliza el primer byte de su clave pública).';

  @override
  String get path_labelHexPrefixes => 'Prefijos hexadecimales';

  @override
  String get path_helperMaxHops =>
      'Máximo 64 saltos. Cada prefijo tiene 2 caracteres hexadecimales (1 byte).';

  @override
  String get path_selectFromContacts => 'O seleccionar de contactos:';

  @override
  String get path_noRepeatersFound =>
      'No se encontraron repetidores ni servidores de sala.';

  @override
  String get path_customPathsRequire =>
      'Las rutas personalizadas requieren saltos intermedios que pueden transmitir mensajes.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Prefijos hexadecimales inválidos: $prefixes';
  }

  @override
  String get path_tooLong =>
      'La ruta es demasiado larga. Se permiten un máximo de 64 saltos.';

  @override
  String get path_setPath => 'Establecer Ruta';

  @override
  String get repeater_management => 'Gestión de Repetidores';

  @override
  String get room_management => 'Administración del Servidor de Habitación';

  @override
  String get repeater_managementTools => 'Herramientas de Gestión';

  @override
  String get repeater_status => 'Estado';

  @override
  String get repeater_statusSubtitle =>
      'Ver el estado, las estadísticas y los vecinos del repetidor';

  @override
  String get repeater_telemetry => 'Telemetry';

  @override
  String get repeater_telemetrySubtitle =>
      'Ver la telemetría de los sensores y las estadísticas del sistema';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Enviar comandos al repetidor';

  @override
  String get repeater_neighbors => 'Vecinos';

  @override
  String get repeater_neighborsSubtitle => 'Ver vecinos de salto cero.';

  @override
  String get repeater_settings => 'Configuración';

  @override
  String get repeater_settingsSubtitle => 'Configurar parámetros del repetidor';

  @override
  String get repeater_statusTitle => 'Estado del Repetidor';

  @override
  String get repeater_routingMode => 'Modo de enrutamiento';

  @override
  String get repeater_autoUseSavedPath => 'Auto (usar la ruta guardada)';

  @override
  String get repeater_forceFloodMode => 'Modo Inundación Forzado';

  @override
  String get repeater_pathManagement => 'Gestión de rutas';

  @override
  String get repeater_refresh => 'Actualizar';

  @override
  String get repeater_statusRequestTimeout => 'Solicitud de estado caducó.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Error al cargar el estado: $error';
  }

  @override
  String get repeater_systemInformation => 'Información del sistema';

  @override
  String get repeater_battery => 'Batería';

  @override
  String get repeater_clockAtLogin => 'Reloj (al inicio de sesión)';

  @override
  String get repeater_uptime => 'Tiempo de actividad';

  @override
  String get repeater_queueLength => 'Longitud de la cola';

  @override
  String get repeater_debugFlags => 'Marcadores de Depuración';

  @override
  String get repeater_radioStatistics => 'Estadísticas de Radio';

  @override
  String get repeater_lastRssi => 'Último RSSI';

  @override
  String get repeater_lastSnr => 'Último SNR';

  @override
  String get repeater_noiseFloor => 'Nivel de Ruido';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Estadísticas del Paquete';

  @override
  String get repeater_sent => 'Enviado';

  @override
  String get repeater_received => 'Recibido';

  @override
  String get repeater_duplicates => 'Duplicados';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days días ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundación: $flood, Directo: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundación: $flood, Directo: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Inundación: $flood, Directo: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get repeater_settingsTitle => 'Configuración del Repetidor';

  @override
  String get repeater_basicSettings => 'Configuración Básica';

  @override
  String get repeater_repeaterName => 'Nombre del Repetidor';

  @override
  String get repeater_repeaterNameHelper =>
      'Mostrar nombre para este repetidor';

  @override
  String get repeater_adminPassword => 'Contraseña de Administrador';

  @override
  String get repeater_adminPasswordHelper => 'Contraseña de acceso completo';

  @override
  String get repeater_guestPassword => 'Contraseña de invitado';

  @override
  String get repeater_guestPasswordHelper =>
      'Acceso de solo lectura con contraseña';

  @override
  String get repeater_radioSettings => 'Configuración de Radio';

  @override
  String get repeater_frequencyMhz => 'Frecuencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Potencia';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Ancho de banda';

  @override
  String get repeater_spreadingFactor => 'Factor de propagación';

  @override
  String get repeater_codingRate => 'Tasa de Programación';

  @override
  String get repeater_locationSettings => 'Configuración de Ubicación';

  @override
  String get repeater_latitude => 'Latitud';

  @override
  String get repeater_latitudeHelper =>
      'Grados decimales (por ejemplo, 37.7749)';

  @override
  String get repeater_longitude => 'Longitud';

  @override
  String get repeater_longitudeHelper =>
      'Grados decimales (por ejemplo, -122.4194)';

  @override
  String get repeater_features => 'Características';

  @override
  String get repeater_packetForwarding => 'Enrutamiento de Paquetes';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Habilitar el repetidor para reenviar paquetes';

  @override
  String get repeater_guestAccess => 'Acceso de Invitados';

  @override
  String get repeater_guestAccessSubtitle =>
      'Permitir acceso de invitado en solo lectura';

  @override
  String get repeater_privacyMode => 'Modo Privacidad';

  @override
  String get repeater_privacyModeSubtitle =>
      'Ocultar nombre/ubicación en anuncios';

  @override
  String get repeater_advertisementSettings => 'Configuración de Anuncios';

  @override
  String get repeater_localAdvertInterval => 'Intervalo de Anuncio Local';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervalo de Anuncio de Inundación';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Intervalo de Anuncio Cifrado';

  @override
  String get repeater_dangerZone => 'Zona de Peligro';

  @override
  String get repeater_rebootRepeater => 'Reiniciar Repetidor';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reiniciar el dispositivo repetidor';

  @override
  String get repeater_rebootRepeaterConfirm =>
      '¿Está seguro de que desea reiniciar este repetidor?';

  @override
  String get repeater_regenerateIdentityKey => 'Regenerar Clave de Identidad';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generar nueva pareja de clave pública/privada';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Esto generará una nueva identidad para el repetidor. Continuar?';

  @override
  String get repeater_eraseFileSystem => 'Borrar Sistema de Archivos';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatear el sistema de archivos del repetidor';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ADVERTENCIA: Esto borrará todos los datos del repetidor. ¡Esto no se puede deshacer!';

  @override
  String get repeater_eraseSerialOnly =>
      'Borrar solo está disponible a través de la consola serial.';

  @override
  String repeater_commandSent(String command) {
    return 'Comando enviado: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Error al enviar el comando: $error';
  }

  @override
  String get repeater_confirm => 'Confirmar';

  @override
  String get repeater_settingsSaved => 'Guardado de ajustes exitoso';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Error al guardar la configuración: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Actualizar Configuración Básica';

  @override
  String get repeater_refreshRadioSettings => 'Actualizar Ajustes de Radio';

  @override
  String get repeater_refreshTxPower => 'Actualizar TX de energía';

  @override
  String get repeater_refreshLocationSettings =>
      'Actualizar Configuración de Ubicación';

  @override
  String get repeater_refreshPacketForwarding =>
      'Actualizar Enrutamiento de Paquetes';

  @override
  String get repeater_refreshGuestAccess => 'Actualizar Acceso Invitados';

  @override
  String get repeater_refreshPrivacyMode => 'Actualizar Modo Privacidad';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Actualizar Configuración de Anuncios';

  @override
  String repeater_refreshed(String label) {
    return '$label actualizado';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Error al refrescar $label';
  }

  @override
  String get repeater_cliTitle => 'Repetidor CLI';

  @override
  String get repeater_debugNextCommand => 'Siguiente Comando de Depuración';

  @override
  String get repeater_commandHelp => 'Ayuda';

  @override
  String get repeater_clearHistory => 'Borrar historial';

  @override
  String get repeater_noCommandsSent => 'Aún no se han enviado comandos.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Escriba un comando a continuación o use comandos rápidos';

  @override
  String get repeater_enterCommandHint => 'Escribir comando...';

  @override
  String get repeater_previousCommand => 'Comando anterior';

  @override
  String get repeater_nextCommand => 'Siguiente comando';

  @override
  String get repeater_enterCommandFirst => 'Escriba un comando primero';

  @override
  String get repeater_cliCommandFrameTitle => 'Marco de Comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Error: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Obtener Nombre';

  @override
  String get repeater_cliQuickGetRadio => 'Obtener Radio';

  @override
  String get repeater_cliQuickGetTx => 'Obtener TX';

  @override
  String get repeater_cliQuickNeighbors => 'Vecinos';

  @override
  String get repeater_cliQuickVersion => 'Versión';

  @override
  String get repeater_cliQuickAdvertise => 'Anunciar';

  @override
  String get repeater_cliQuickClock => 'Reloj';

  @override
  String get repeater_cliHelpAdvert => 'Envía un paquete de publicidad';

  @override
  String get repeater_cliHelpReboot =>
      'Reinicia el dispositivo. (ten en cuenta, es normal que aparezca \'Timeout\')';

  @override
  String get repeater_cliHelpClock =>
      'Muestra la hora actual según el reloj del dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Establece una nueva contraseña de administrador para el dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Muestra la versión del dispositivo y la fecha de compilación del firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Reinicia varios contadores de estadísticas a cero.';

  @override
  String get repeater_cliHelpSetAf => 'Establece el factor de tiempo de aire.';

  @override
  String get repeater_cliHelpSetTx =>
      'Establece la potencia de transmisión LoRa en dBm (reboot para aplicar).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Habilita o deshabilita el rol del repetidor para este nodo.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Servidor de la sala) Si está \"activado\", entonces el inicio de sesión con una contraseña en blanco estará permitido, pero no se podrá publicar en la sala. (solo lectura).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Establece el número máximo de saltos de paquetes de inundación entrantes (si es >= máximo, el paquete no se enruta).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Establece el Umbral de Interferencia (en dB). El valor predeterminado es 14. Establecerlo en 0 desactiva la detección de interferencias del canal.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Establece el intervalo para restablecer el Control Automático de Ganancia. Establecer en 0 para desactivarlo.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Habilita o deshabilita la función de \'ACKs dobles\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Establece el intervalo del temporizador en minutos para enviar un paquete de anuncio local (sin salto). Establecer en 0 para desactivarlo.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Establece el intervalo del temporizador en horas para enviar un paquete de anuncio masivo. Establecer en 0 para desactivarlo.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Establece/actualiza la contraseña del invitado. (para repetidores, los inicios de sesión de invitado pueden enviar la solicitud \"Obtener Estadísticas\")';

  @override
  String get repeater_cliHelpSetName => 'Establece el nombre del anuncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Establece la latitud del mapa de publicidad. (grados decimales)';

  @override
  String get repeater_cliHelpSetLon =>
      'Establece la longitud del mapa de la publicidad. (grados decimales)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Establece parámetros de radio completamente nuevos y los guarda en las preferencias. Requiere un comando \"reboot\" para aplicarlos.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Configura (experimental) la base para aplicar un ligero retraso a los paquetes recibidos, según la fuerza de la señal/puntuación. Establece en 0 para desactivar.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Establece un factor multiplicado con el tiempo de aire para un paquete de modo de inundación y con un sistema de ranura aleatorio, para retrasar su reenvío (para disminuir la probabilidad de colisiones).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Igual que txdelay, pero para aplicar un retraso aleatorio a la transferencia de paquetes en modo directo.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Habilitar/Deshabilitar puente.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Establecer retraso antes de retransmitir paquetes.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Elige si el puente retransmitirá paquetes recibidos o paquetes transmitidos.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Establecer la velocidad de baudios del enlace serial para los puentes rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Establecer secreto de puente para puentes espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Establece un factor personalizado para ajustar el voltaje de la batería reportado (solo soportado en selectas placas).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Establece parámetros de radio temporales para el número dado de minutos, volviendo a los parámetros de radio originales posteriormente. (no guarda en preferencias).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica el ACL. Elimina la entrada coincidente (por prefijo de pubkey) si \"permissions\" es cero. Añade una nueva entrada si el pubkey-hex tiene longitud completa y no está actualmente en el ACL. Actualiza la entrada mediante el prefijo de pubkey coincidente. Los bits de permiso varían según el rol del firmware, pero los dos bits inferiores son: 0 (Invitado), 1 (Solo lectura), 2 (Lectura/escritura), 3 (Administrador).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Obtiene tipo de puente ninguno, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Inicia el registro de paquetes en el sistema de archivos.';

  @override
  String get repeater_cliHelpLogStop =>
      'Detener el registro de paquetes al sistema de archivos.';

  @override
  String get repeater_cliHelpLogErase =>
      'Elimina los registros del paquete del sistema de archivos.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Muestra una lista de otros nodos repetidores escuchados a través de anuncios de un solo salto. Cada línea es id-prefijo-hex:marca de tiempo:times-snr-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Elimina la primera entrada coincidente (por prefijo de pubkey (hex)) de la lista de vecinos.';

  @override
  String get repeater_cliHelpRegion =>
      '(solo serie) Lista todas las regiones definidas y los permisos de inundación actuales.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: este es un invocación multi-comando especial. Cada comando subsiguiente es un nombre de región (indentado con espacios para indicar la jerarquía padre, con un espacio mínimo). Terminado enviando una línea en blanco/comando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Busca la región con el prefijo de nombre dado (o \"\" para el ámbito global). Responde con \"-> nombre-región (nombre-padre) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Agrega o actualiza una definición de región con el nombre dado.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Elimina una definición de región con el nombre dado. (debe coincidir exactamente y no tener regiones hijas)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Establece el permiso de \'F\'lujo para la región dada. (\'\' para el ámbito global/legado)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Elimina el permiso de \'F\'lood para la región especificada. (NOTA: en esta etapa NO se recomienda utilizarlo en el ámbito global/legado!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Responde con la región \'home\' actual. (Aún no se ha aplicado en ninguna parte, reservado para el futuro).';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Establece la región \'hogar\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persiste la lista/mapa de regiones al almacenamiento.';

  @override
  String get repeater_cliHelpGps =>
      'Muestra el estado del GPS. Cuando el GPS está apagado, responde solo con \"apagado\", si está encendido, responde con \"encendido\", estado, fijación, número de satélites.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Activa o desactiva el modo GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincroniza la hora del nodo con el reloj GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Establece la posición del nodo a las coordenadas GPS y guarda las preferencias.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Da la configuración de la publicidad del nodo de ubicación:\n- ninguno: no incluir la ubicación en las publicidad\n- compartir: compartir la ubicación GPS (del SensorManager)\n- preferencias: publicidad la ubicación almacenada en preferencias';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Configura la configuración de la publicidad de la ubicación.';

  @override
  String get repeater_commandsListTitle => 'Lista de comandos';

  @override
  String get repeater_commandsListNote =>
      'NOTA: para los diversos comandos \"set...\", también existe un comando \"get...\".';

  @override
  String get repeater_general => 'General';

  @override
  String get repeater_settingsCategory => 'Configuración';

  @override
  String get repeater_bridge => 'Puente';

  @override
  String get repeater_logging => 'Registrando';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vecinos (solo repetidor)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gestión de Regiones (solo Repetidor)';

  @override
  String get repeater_regionNote =>
      'Se han introducido los comandos de región para gestionar las definiciones y permisos de la región.';

  @override
  String get repeater_gpsManagement => 'Gestión de GPS';

  @override
  String get repeater_gpsNote =>
      'Se ha introducido un comando GPS para gestionar temas relacionados con la ubicación.';

  @override
  String get telemetry_receivedData => 'Datos de Telemetría Recibidos';

  @override
  String get telemetry_requestTimeout => 'Solicitud de telemetría ha expirado.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Error al cargar la telemetría: $error';
  }

  @override
  String get telemetry_noData => 'No hay datos de telemetría disponibles.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batería';

  @override
  String get telemetry_voltageLabel => 'Voltaje';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura del MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Actual';

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
  String get neighbors_receivedData => 'Recibidas Datos de Vecinos';

  @override
  String get neighbors_requestTimedOut =>
      'Los vecinos solicitan que se desconecte.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Error al cargar vecinos: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Repetidores Vecinos';

  @override
  String get neighbors_noData => 'No hay datos de vecinos disponibles.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Clave pública desconocida $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Escuchado: $time hace atrás';
  }

  @override
  String get channelPath_title => 'Ruta del Paquete';

  @override
  String get channelPath_viewMap => 'Ver mapa';

  @override
  String get channelPath_otherObservedPaths => 'Otros caminos observados';

  @override
  String get channelPath_repeaterHops => 'Saltos del Repetidor';

  @override
  String get channelPath_noHopDetails =>
      'Los detalles del paquete no están disponibles.';

  @override
  String get channelPath_messageDetails => 'Detalles del mensaje';

  @override
  String get channelPath_senderLabel => 'Remitente';

  @override
  String get channelPath_timeLabel => 'Tiempo';

  @override
  String get channelPath_repeatsLabel => 'Repetir';

  @override
  String channelPath_pathLabel(int index) {
    return 'Ruta $index';
  }

  @override
  String get channelPath_observedLabel => 'Observado';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Ruta observada $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'No datos de ubicación';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month a las $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Desconocido';

  @override
  String get channelPath_floodPath => 'Inundación';

  @override
  String get channelPath_directPath => 'Guardar';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 de $total saltos';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed de $total saltos';
  }

  @override
  String get channelPath_mapTitle => 'Mapa de Rutas';

  @override
  String get channelPath_noRepeaterLocations =>
      'No hay ubicaciones disponibles para el repetidor en esta ruta.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Ruta $index (Principal)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Ruta';

  @override
  String get channelPath_observedPathHeader => 'Ruta Observada';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'No hay detalles de salto disponibles para este paquete.';

  @override
  String get channelPath_unknownRepeater => 'Repetidor Desconocido';

  @override
  String get community_title => 'Comunidad';

  @override
  String get community_create => 'Crear Comunidad';

  @override
  String get community_createDesc =>
      'Crear una nueva comunidad y compartir a través de código QR.';

  @override
  String get community_join => 'Únete';

  @override
  String get community_joinTitle => 'Únete a la comunidad';

  @override
  String community_joinConfirmation(String name) {
    return '¿Quieres unirte a la comunidad \"$name\"?';
  }

  @override
  String get community_scanQr => 'Escanear Código QR de la Comunidad';

  @override
  String get community_scanInstructions =>
      'Apunte la cámara a un código QR de la comunidad';

  @override
  String get community_showQr => 'Mostrar Código QR';

  @override
  String get community_publicChannel => 'Comunidad Pública';

  @override
  String get community_hashtagChannel => 'Hashtag de la Comunidad';

  @override
  String get community_name => 'Nombre de la comunidad';

  @override
  String get community_enterName => 'Introducir nombre de comunidad';

  @override
  String community_created(String name) {
    return 'Comunidad \"$name\" creada';
  }

  @override
  String community_joined(String name) {
    return 'Se unió a la comunidad \"$name\"';
  }

  @override
  String get community_qrTitle => 'Compartir Comunidad';

  @override
  String community_qrInstructions(String name) {
    return 'Escanear este código QR para unirte a $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Los canales de hashtag de la comunidad solo son accesibles para los miembros de la comunidad';

  @override
  String get community_invalidQrCode => 'Código QR de comunidad no válido';

  @override
  String get community_alreadyMember => 'Ya eres Miembro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Ya eres miembro de \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Añadir Canal Público de la Comunidad';

  @override
  String get community_addPublicChannelHint =>
      'Añade automáticamente el canal público para esta comunidad.';

  @override
  String get community_noCommunities => 'Aún no se han unido comunidades.';

  @override
  String get community_scanOrCreate =>
      'Escanear un código QR o crear una comunidad para comenzar';

  @override
  String get community_manageCommunities => 'Gestionar Comunidades';

  @override
  String get community_delete => 'Salir de la Comunidad';

  @override
  String community_deleteConfirm(String name) {
    return '¿Salir de \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Esto también eliminará $count canal(es) y sus mensajes.';
  }

  @override
  String community_deleted(String name) {
    return 'Has salido de la comunidad \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerar Contraseña Secreta';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerar la clave secreta para \"$name\"? Todos los miembros deberán escanear el nuevo código QR para seguir comunicándose.';
  }

  @override
  String get community_regenerate => 'Regenerar';

  @override
  String community_secretRegenerated(String name) {
    return 'Código secreto regenerado para \"$name\"';
  }

  @override
  String get community_updateSecret => 'Actualizar Contraseña';

  @override
  String community_secretUpdated(String name) {
    return 'Confidencialidad actualizada para \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Escanear el nuevo código QR para actualizar el secreto de \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Añadir Hashtag de la Comunidad';

  @override
  String get community_addHashtagChannelDesc =>
      'Añadir un canal con hashtag para esta comunidad';

  @override
  String get community_selectCommunity => 'Seleccionar Comunidad';

  @override
  String get community_regularHashtag => 'Etiqueta de Hashtag Regular';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag público (cualquiera puede unirse)';

  @override
  String get community_communityHashtag => 'Hashtag de la Comunidad';

  @override
  String get community_communityHashtagDesc =>
      'Exclusivo para miembros de la comunidad';

  @override
  String community_forCommunity(String name) {
    return 'Para $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrar y ordenar';

  @override
  String get listFilter_sortBy => 'Ordenar por';

  @override
  String get listFilter_latestMessages => 'Últimos mensajes';

  @override
  String get listFilter_heardRecently => 'Escuchado recientemente';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtros';

  @override
  String get listFilter_all => 'Todas';

  @override
  String get listFilter_favorites => 'Favoritos';

  @override
  String get listFilter_addToFavorites => 'Añadir a favoritos';

  @override
  String get listFilter_removeFromFavorites => 'Eliminar de las favoritas';

  @override
  String get listFilter_users => 'Usuarios';

  @override
  String get listFilter_repeaters => 'Repetidores';

  @override
  String get listFilter_roomServers => 'Servidores de la sala';

  @override
  String get listFilter_unreadOnly => 'Solo sin leer';

  @override
  String get listFilter_newGroup => 'Nuevo grupo';

  @override
  String get pathTrace_you => 'Tú';

  @override
  String get pathTrace_failed => 'El trazado de ruta falló.';

  @override
  String get pathTrace_notAvailable => 'El trazado de ruta no está disponible.';

  @override
  String get pathTrace_refreshTooltip => 'Actualizar Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Uno o más de los lúpulos carecen de una ubicación';

  @override
  String get pathTrace_clearTooltip => 'Borrar ruta';

  @override
  String get losSelectStartEnd =>
      'Seleccione los nodos de inicio y fin para LOS.';

  @override
  String losRunFailed(String error) {
    return 'Error en la comprobación de la línea de visión: $error';
  }

  @override
  String get losClearAllPoints => 'Borrar todos los puntos';

  @override
  String get losRunToViewElevationProfile =>
      'Ejecute LOS para ver el perfil de elevación';

  @override
  String get losMenuTitle => 'Menú LOS';

  @override
  String get losMenuSubtitle =>
      'Toque nodos o mantenga presionado el mapa para puntos personalizados';

  @override
  String get losShowDisplayNodes => 'Mostrar nodos de visualización';

  @override
  String get losCustomPoints => 'Puntos personalizados';

  @override
  String losCustomPointLabel(int index) {
    return 'Personalizado $index';
  }

  @override
  String get losPointA => 'Punto A';

  @override
  String get losPointB => 'Punto B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Ejecutar LOS';

  @override
  String get losNoElevationData => 'Sin datos de elevación';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, despejar LOS, autorización mínima $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, bloqueado por $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: comprobando...';

  @override
  String get losStatusNoData => 'LOS: sin datos';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total claro, $blocked bloqueado, $unknown desconocido';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Datos de elevación no disponibles para una o más muestras.';

  @override
  String get losErrorInvalidInput =>
      'Datos de puntos/elevación no válidos para el cálculo de LOS.';

  @override
  String get losRenameCustomPoint =>
      'Cambiar el nombre del punto personalizado';

  @override
  String get losPointName => 'Nombre del punto';

  @override
  String get losShowPanelTooltip => 'Mostrar panel LOS';

  @override
  String get losHidePanelTooltip => 'Ocultar panel LOS';

  @override
  String get losElevationAttribution =>
      'Datos de elevación: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Horizonte radioeléctrico';

  @override
  String get losLegendLosBeam => 'Línea de visión';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losFrequencyLabel => 'Frecuencia';

  @override
  String get losFrequencyInfoTooltip => 'Ver detalles del cálculo';

  @override
  String get losFrequencyDialogTitle => 'Cálculo del horizonte radioeléctrico';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'A partir de k=$baselineK en $baselineFreq MHz, el cálculo ajusta el factor k para la banda actual de $frequencyMHz MHz, que define el límite curvo del horizonte de radio.';
  }

  @override
  String get contacts_pathTrace => 'Rastreo de caminos';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Rastrear ruta al repetidor';

  @override
  String get contacts_repeaterPing => 'Pingar repetidor';

  @override
  String get contacts_roomPathTrace =>
      'Rastreo de ruta al servidor de la habitación';

  @override
  String get contacts_roomPing => 'Pingar servidor de sala';

  @override
  String get contacts_chatTraceRoute => 'Ruta de trazado';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Rastrear ruta a $name';
  }

  @override
  String get contacts_clipboardEmpty => 'El portapapeles está vacío.';

  @override
  String get contacts_invalidAdvertFormat => 'Datos de contacto no válidos';

  @override
  String get contacts_contactImported => 'El contacto ha sido importado.';

  @override
  String get contacts_contactImportFailed =>
      'Contacto no se importó correctamente.';

  @override
  String get contacts_zeroHopAdvert => 'Anuncio de Zero Hop';

  @override
  String get contacts_floodAdvert => 'Anuncio de inundación';

  @override
  String get contacts_copyAdvertToClipboard => 'Copiar anuncio al portapapeles';

  @override
  String get contacts_addContactFromClipboard =>
      'Agregar contacto desde el portapapeles';

  @override
  String get contacts_ShareContact => 'Copiar contacto al Portapapeles';

  @override
  String get contacts_ShareContactZeroHop => 'Compartir contacto por anuncio';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Envió contacto por anuncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'No se pudo enviar el contacto.';

  @override
  String get contacts_contactAdvertCopied => 'Anuncio copiado al Portapapeles.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Copiar anuncio al Portapapeles ha fallado.';

  @override
  String get notification_activityTitle => 'Actividad de MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensajes',
      one: 'mensaje',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensajes de canal',
      one: 'mensaje de canal',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nuevos nodos',
      one: 'nuevo nodo',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nuevo $contactType descubierto';
  }

  @override
  String get notification_receivedNewMessage => 'Nuevo mensaje recibido';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportar repetidores / servidor de sala a GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporta repetidores o roomserver con una ubicación a un archivo GPX.';

  @override
  String get settings_gpxExportContacts => 'Exportar compañeros a GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporta compañeros con una ubicación a archivo GPX.';

  @override
  String get settings_gpxExportAll => 'Exportar todos los contactos a GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporta todos los contactos con una ubicación a un archivo GPX.';

  @override
  String get settings_gpxExportSuccess => 'Archivo GPX exportado con éxito.';

  @override
  String get settings_gpxExportNoContacts => 'No hay contactos para exportar.';

  @override
  String get settings_gpxExportNotAvailable =>
      'No compatible con tu dispositivo/SO';

  @override
  String get settings_gpxExportError => 'Hubo un error al exportar.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Ubicaciones del servidor de repetidor y sala';

  @override
  String get settings_gpxExportChat => 'Ubicaciones de compañero';

  @override
  String get settings_gpxExportAllContacts =>
      'Todas las ubicaciones de contactos';

  @override
  String get settings_gpxExportShareText =>
      'Datos del mapa exportados desde meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open exportación de datos de mapa GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Repetidores cercanos';

  @override
  String get snrIndicator_lastSeen => 'Visto por última vez';

  @override
  String get contactsSettings_title => 'Configuración de contactos';

  @override
  String get contactsSettings_autoAddTitle => 'Detección automática';

  @override
  String get contactsSettings_otherTitle =>
      'Otras configuraciones relacionadas con el contacto';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Agregar usuarios automáticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Permitir que el compañero agregue automáticamente a los usuarios descubiertos.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Agregar repetidores automáticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Permitir que el compañero agregue automáticamente los repetidores descubiertos.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Agregar automáticamente servidores de sala';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Permitir que el compañero agregue automáticamente los servidores de salas descubiertos.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Agregar sensores automáticamente';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Permitir que el compañero agregue automáticamente los sensores descubiertos.';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Sobreescribir el más antiguo';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Cuando la lista de contactos esté llena, se reemplazará el contacto no favorito más antiguo.';

  @override
  String get discoveredContacts_Title => 'Contactos descubiertos';

  @override
  String get discoveredContacts_noMatching =>
      'No se encontraron contactos coincidentes';

  @override
  String get discoveredContacts_searchHint => 'Buscar contactos descubiertos';

  @override
  String get discoveredContacts_contactAdded => 'Contacto agregado';

  @override
  String get discoveredContacts_addContact => 'Agregar contacto';

  @override
  String get discoveredContacts_copyContact =>
      'Copiar contacto al portapapeles';

  @override
  String get discoveredContacts_deleteContact => 'Eliminar contacto';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Eliminar Todos los Contactos Descubiertos';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      '¿Está seguro de que desea eliminar todos los contactos descubiertos!';
}
