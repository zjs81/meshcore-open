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
  String get common_ok => 'Aceptar';

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
  String get common_done => 'Hecho';

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
  String get common_retry => 'Reintentar';

  @override
  String get common_hide => 'Ocultar';

  @override
  String get common_remove => 'Eliminar';

  @override
  String get common_enable => 'Activar';

  @override
  String get common_disable => 'Desactivar';

  @override
  String get common_undo => 'Deshacer';

  @override
  String get messageStatus_sent => 'Enviado';

  @override
  String get messageStatus_delivered => 'Entregado';

  @override
  String get messageStatus_pending => 'Enviando';

  @override
  String get messageStatus_failed => 'No se pudo enviar';

  @override
  String get messageStatus_repeated => 'Escuchado repetidamente';

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
  String get common_autoRefresh => 'Actualización automática';

  @override
  String get common_interval => 'Intervalo';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Establecer conexión a través de TCP';

  @override
  String get tcpHostLabel => 'Dirección IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Puerto';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Ingrese la dirección final y conecte.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Conectándose a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Se requiere la dirección IP.';

  @override
  String get tcpErrorPortInvalid => 'El puerto debe estar entre 1 y 65535.';

  @override
  String get tcpErrorUnsupported =>
      'El protocolo de transporte TCP no está soportado en esta plataforma.';

  @override
  String get tcpErrorTimedOut => 'La conexión TCP ha caducado.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Error en la conexión TCP: $error';
  }

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
  String get scanner_notConnected => 'No conectado';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Buscando dispositivos MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Pulsa Escanear para encontrar dispositivos MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get scanner_stop => 'Detener';

  @override
  String get scanner_scan => 'Escanear';

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
  String get scanner_bluetoothWebUnsupported =>
      'La funcionalidad Bluetooth no está disponible en el navegador. Conéctese mediante USB en su lugar.';

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
  String get settings_regionSettings => 'Regiones';

  @override
  String get settings_regionSettingsSubtitle =>
      'Gestionar regiones almacenadas';

  @override
  String get settings_regionManagement_screenTitle => 'Gestión de Regiones';

  @override
  String get settings_regionNameHint => 'Nombre de la región';

  @override
  String get settings_regionAddRegion => 'Añadir región';

  @override
  String get settings_regionFetchRegions => 'Obtener regiones de repetidores';

  @override
  String get settings_regionFetchRegionsFail => 'No se encontraron regiones';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Esta región ya ha sido agregada';

  @override
  String get settings_regionName => 'Nombre de la Región';

  @override
  String get settings_regionDeleted => 'Región eliminada';

  @override
  String get settings_deleteRegion => 'Eliminar Región';

  @override
  String settings_deleteRegionConfirm(String region) {
    return '¿Eliminar \"$region\" de la lista de regiones?';
  }

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
  String get settings_privacyMode => 'Modo de privacidad';

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
  String get settings_privacy => 'Configuración de privacidad';

  @override
  String get settings_privacySubtitle =>
      'Controlar qué información se comparte.';

  @override
  String get settings_privacySettingsDescription =>
      'Elige qué información comparte tu dispositivo con otros.';

  @override
  String get settings_denyAll => 'Denegar todo';

  @override
  String get settings_allowByContact => 'Permitir por banderas de contacto';

  @override
  String get settings_allowAll => 'Permitir todo';

  @override
  String get settings_telemetryBaseMode => 'Modo base de telemetría';

  @override
  String get settings_telemetryLocationMode =>
      'Modo de ubicación de telemetría';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Modo de entorno de telemetría';

  @override
  String get settings_advertLocation => 'Ubicación de anuncio';

  @override
  String get settings_advertLocationSubtitle => 'Incluir ubicación en anuncio';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Anuncio de cero saltos automático al actualizar GPS';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Cuando cambie la ubicación GPS, enviar un anuncio de cero saltos (requiere ubicación en anuncio).';

  @override
  String get settings_autoSelfAdvertAsFlood =>
      'Enviar anuncio propio automático como flood';

  @override
  String get settings_autoSelfAdvertAsFloodSubtitle =>
      'Cuando está activado, los anuncios propios automatizados se envían como flood en lugar de zero-hop.';

  @override
  String get settings_multiAck => 'Múltiples respuestas de confirmación';

  @override
  String get settings_telemetryModeUpdated => 'Modo de telemetría actualizado';

  @override
  String get settings_actions => 'Acciones';

  @override
  String get settings_deleteAllPaths => 'Eliminar todas las rutas';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Borrar todos los datos de ruta de los contactos.';

  @override
  String get settings_sendAdvertisement => 'Enviar anuncio';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Difundir la presencia ahora';

  @override
  String get settings_advertisementSent => 'Anuncio enviado';

  @override
  String get settings_syncTime => 'Sincronizar hora';

  @override
  String get settings_syncTimeSubtitle =>
      'Establecer la hora del dispositivo con la del teléfono';

  @override
  String get settings_timeSynchronized => 'Hora sincronizada';

  @override
  String get settings_refreshContacts => 'Actualizar contactos';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recargar lista de contactos del dispositivo';

  @override
  String get settings_rebootDevice => 'Reiniciar dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Reiniciar el dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      '¿Está seguro de que desea reiniciar el dispositivo? Se desconectará.';

  @override
  String get settings_debug => 'Depurar';

  @override
  String get settings_companionDebugLog => 'Registro de depuración asociado';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Comandos, respuestas y datos brutos para protocolos BLE/TCP/USB';

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
  String get settings_aboutLegalese => 'Proyecto MeshCore Open Source 2026';

  @override
  String get settings_aboutDescription =>
      'Un cliente Flutter de código abierto para dispositivos MeshCore de malla LoRa.';

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
  String get settings_infoPublicKey => 'Clave pública';

  @override
  String get settings_infoContactsCount => 'Número de contactos';

  @override
  String get settings_infoChannelCount => 'Número de canales';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

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
  String get settings_codingRate => 'Tasa de codificación';

  @override
  String get settings_txPower => 'Potencia TX (dBm)';

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
  String get appSettings_themeLight => 'Claro';

  @override
  String get appSettings_themeDark => 'Oscuro';

  @override
  String get appSettings_language => 'Idioma';

  @override
  String get appSettings_languageSystem => 'Predeterminado del sistema';

  @override
  String get appSettings_languageEn => 'Inglés';

  @override
  String get appSettings_languageFr => 'Francés';

  @override
  String get appSettings_languageEs => 'Español';

  @override
  String get appSettings_languageDe => 'Alemán';

  @override
  String get appSettings_languagePl => 'Polaco';

  @override
  String get appSettings_languageSl => 'Esloveno';

  @override
  String get appSettings_languagePt => 'Portugués';

  @override
  String get appSettings_languageIt => 'Italiano';

  @override
  String get appSettings_languageZh => 'Chino';

  @override
  String get appSettings_languageSv => 'Sueco';

  @override
  String get appSettings_languageNl => 'Neerlandés';

  @override
  String get appSettings_languageSk => 'Eslovaco';

  @override
  String get appSettings_languageBg => 'Búlgaro';

  @override
  String get appSettings_languageRu => 'Ruso';

  @override
  String get appSettings_languageUk => 'Ucraniano';

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
      'Habilitar seguimiento de mensajes';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostrar metadatos detallados de enrutamiento y tiempo para los mensajes';

  @override
  String get appSettings_notifications => 'Notificaciones';

  @override
  String get appSettings_enableNotifications => 'Habilitar notificaciones';

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
  String get appSettings_messageNotifications => 'Notificaciones de mensajes';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostrar notificación al recibir nuevos mensajes';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notificaciones de mensajes del canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostrar notificación al recibir mensajes del canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notificaciones de anuncios';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostrar notificación cuando se descubren nuevos nodos';

  @override
  String get appSettings_messaging => 'Mensajería';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Borrar ruta al máximo de reintentos';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Restablecer la ruta de contacto después de 5 intentos de envío fallidos';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Las rutas se borrarán después de 5 intentos fallidos.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Las rutas no se eliminarán automáticamente.';

  @override
  String get appSettings_autoRouteRotation => 'Rotación automática de rutas';

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
  String get appSettings_maxRouteWeight => 'Peso máximo permitido para la ruta';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Peso máximo que una ruta puede acumular gracias a entregas exitosas.';

  @override
  String get appSettings_initialRouteWeight => 'Peso inicial de la ruta';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Peso inicial para rutas recién descubiertas';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Incremento de peso para el éxito';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Peso añadido a una ruta después de una entrega exitosa.';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Reducción del peso asociado al fallo';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Peso retirado de una ruta después de un intento de entrega fallido.';

  @override
  String get appSettings_maxMessageRetries =>
      'Número máximo de reintentos de envío de mensajes';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Número de intentos de reintento antes de marcar un mensaje como fallido.';

  @override
  String get appSettings_battery => 'Batería';

  @override
  String get appSettings_batteryChemistry => 'Química de la batería';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Configurar por dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Conéctate a un dispositivo para elegirlo';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2 V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2 V)';

  @override
  String get appSettings_batteryLipoHv => 'LiPo HV (3.0-4.35V)';

  @override
  String get appSettings_mapDisplay => 'Visualización del mapa';

  @override
  String get appSettings_showRepeaters => 'Mostrar repetidores';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Mostrar nodos de repetidor en el mapa';

  @override
  String get appSettings_showChatNodes => 'Mostrar nodos de chat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Mostrar nodos de chat en el mapa';

  @override
  String get appSettings_showOtherNodes => 'Mostrar otros nodos';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mostrar otros tipos de nodo en el mapa';

  @override
  String get appSettings_timeFilter => 'Filtro de tiempo';

  @override
  String get appSettings_timeFilterShowAll => 'Mostrar todos los nodos';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostrar nodos de las últimas $hours horas';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro de tiempo del mapa';

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
  String get appSettings_rasterTileSource => 'Fuente de teselas ráster';

  @override
  String get appSettings_stadiaEndpoint => 'Punto de acceso de Stadia';

  @override
  String get appSettings_stadiaApiKey => 'Clave API de Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Obligatorio para usar Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Configurado: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Introduce tu clave API de Stadia Maps. La aplicación la usa para solicitar teselas ráster.';

  @override
  String get appSettings_offlineMapCache => 'Caché de mapa sin conexión';

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
      'Registrar mensajes de depuración de la app para solucionar problemas';

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
    return 'Buscar $number$str contactos...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Buscar $number$str favoritos...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Buscar $number$str usuarios...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Buscar $number$str repetidores...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Buscar $number$str servidores de sala...';
  }

  @override
  String get contacts_noUnreadContacts => 'No hay contactos sin leer';

  @override
  String get contacts_noContactsFound =>
      'No se encontraron contactos ni grupos.';

  @override
  String get contacts_deleteContact => 'Eliminar contacto';

  @override
  String contacts_removeConfirm(String contactName) {
    return '¿Eliminar $contactName de los contactos?';
  }

  @override
  String get contacts_manageRepeater => 'Gestionar repetidor';

  @override
  String get contacts_manageRoom => 'Gestionar servidor de sala';

  @override
  String get contacts_roomLogin => 'Inicio de sesión en sala';

  @override
  String get contacts_openChat => 'Abrir chat';

  @override
  String get contacts_editGroup => 'Editar grupo';

  @override
  String get contacts_deleteGroup => 'Eliminar grupo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eliminar $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nuevo Grupo';

  @override
  String get contacts_moreOptions => 'Más opciones';

  @override
  String get contacts_searchOpen => 'Buscar contactos';

  @override
  String get contacts_searchClose => 'Cerrar búsqueda';

  @override
  String get contacts_groupName => 'Nombre del grupo';

  @override
  String get contacts_groupNameRequired => 'El nombre del grupo es obligatorio';

  @override
  String get contacts_groupNameReserved =>
      'Este nombre de grupo está reservado';

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
    return '~ $minutes minutos';
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
  String get contact_info => 'Información de contacto';

  @override
  String get contact_settings => 'Configuración de contacto';

  @override
  String get contact_telemetry => 'Telemetría';

  @override
  String get contact_lastSeen => 'Visto por última vez';

  @override
  String get contact_clearChat => 'Borrar chat';

  @override
  String get contact_teleBase => 'Base de Telemetría';

  @override
  String get contact_teleBaseSubtitle =>
      'Permitir el intercambio de nivel de batería y telemetría básica';

  @override
  String get contact_teleLoc => 'Ubicación de telemetría';

  @override
  String get contact_teleLocSubtitle =>
      'Permitir el intercambio de datos de ubicación';

  @override
  String get contact_teleEnv => 'Entorno de Telemetría';

  @override
  String get contact_teleEnvSubtitle =>
      'Permitir el intercambio de datos de sensores de entorno';

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
  String get channels_public => 'Público';

  @override
  String channels_via(String path) {
    return 'vía $path';
  }

  @override
  String get channels_private => 'Privado';

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
  String get channels_cyr2latCompression => 'Compresión Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Reemplaza algunos caracteres cirílicos con caracteres latinos al enviar.';

  @override
  String get channels_cyr2latSettingsHeading => 'Configuración de Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Lista de sustituciones';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Editar la configuración JSON de sustitución de caracteres';

  @override
  String get channels_cyr2latSettingsDialogHint => 'Mapa JSON de sustituciones';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'JSON incorrecto: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Canal \"$name\" actualizado';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Añadir perfil Cyr2Lat';

  @override
  String get settings_cyr2latProfileName => 'Nombre del perfil';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'El nombre del perfil no puede estar vacío';

  @override
  String get settings_cyr2latProfileAdded => 'Perfil añadido correctamente';

  @override
  String get settings_cyr2latProfileUpdated =>
      'Perfil actualizado correctamente';

  @override
  String get settings_cyr2latProfileEdit => 'Editar perfil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDelete => 'Eliminar perfil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDeleted => 'Perfil eliminado correctamente';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return '¿Está seguro de que desea eliminar el perfil \"$name\"?';
  }

  @override
  String get channels_publicChannelAdded => 'Canal público añadido';

  @override
  String get channels_sortBy => 'Ordenar por';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'De la A a la Z';

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
  String channels_regionSetTo(String region) {
    return 'Región: $region';
  }

  @override
  String get channels_regionNotSet => 'Región: ninguna';

  @override
  String get channels_regionSelect_Title => 'Seleccione una región';

  @override
  String get channels_clearRegion => 'Zona despejada';

  @override
  String get chat_noMessages => 'Aún no hay mensajes';

  @override
  String get chat_sendMessage => 'Enviar mensaje';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Enviar un mensaje a $contactName';
  }

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
  String get chat_sendImage => 'Enviar imagen';

  @override
  String get chat_imagePickFailed => 'No pude abrir esa imagen';

  @override
  String get chat_receivedGif => 'Recibido un GIF';

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
  String get gifPicker_poweredBy => 'Con tecnología de GIPHY';

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
  String get debugLog_rawLogRx => 'Registro bruto RX';

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
  String get debugFrame_textTypePlain => 'Plano';

  @override
  String debugFrame_text(String text) {
    return '- Texto: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Volcado hexadecimal:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saltos',
      one: 'salto',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Eliminar ruta';

  @override
  String get chat_noPathHistoryYet =>
      'Aún no hay historial de rutas.\nEnvía un mensaje para descubrir rutas.';

  @override
  String get chat_pathCleared =>
      'Ruta borrada. El siguiente mensaje redescubrirá la ruta.';

  @override
  String get chat_fullPath => 'Ruta completa';

  @override
  String get routing_title => 'Enrutamiento';

  @override
  String get routing_modeAuto => 'Automático';

  @override
  String get routing_modeFlood => 'Inundación';

  @override
  String get routing_modeManual => 'Manual';

  @override
  String get routing_modeAutoHint =>
      'Selecciona automáticamente la mejor ruta conocida y, si no hay ninguna, usa el modo de inundación.';

  @override
  String get routing_modeFloodHint =>
      'Transmite por todos los repetidores. Es la opción más fiable, pero usa más tiempo de aire.';

  @override
  String get routing_modeManualHint =>
      'Siempre sigue exactamente la ruta que has definido.';

  @override
  String get routing_currentRoute => 'Ruta actual';

  @override
  String get routing_directNoHops => 'Directo — sin saltos de repetidor';

  @override
  String get routing_noPathYet =>
      'Aún no hay una ruta. El siguiente mensaje se enviará por inundación hasta que se descubra una ruta.';

  @override
  String get routing_floodBroadcast => 'Transmisión por todos los repetidores';

  @override
  String get routing_editPath => 'Editar ruta';

  @override
  String get routing_forgetPath => 'Olvidar ruta';

  @override
  String get routing_knownPaths => 'Rutas conocidas';

  @override
  String get routing_knownPathsHint => 'Toca una ruta para cambiar a ella.';

  @override
  String get routing_inUse => 'En uso';

  @override
  String get routing_qualityStrong => 'Primer salto fuerte';

  @override
  String get routing_qualityGood => 'Primer salto bueno';

  @override
  String get routing_qualityFair => 'Primer salto aceptable';

  @override
  String get routing_qualityWorked => 'Ha entregado';

  @override
  String get routing_qualityFlood => 'Escuchado por inundación';

  @override
  String get routing_qualityUntested => 'Sin probar';

  @override
  String routing_lastWorked(String when) {
    return 'funcionó $when';
  }

  @override
  String get routing_neverWorked => 'nunca confirmado';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes entregados, $failures fallidos';
  }

  @override
  String get routing_floodDelivery => 'Entrega por inundación';

  @override
  String get pathEditor_title => 'Crear ruta';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count de 64 saltos';
  }

  @override
  String get pathEditor_noHops =>
      'Aún no se han añadido saltos. Toca los repetidores de abajo para añadirlos en orden, o guarda la ruta sin saltos para enviarla directamente.';

  @override
  String get pathEditor_addHops => 'Añadir los saltos en orden';

  @override
  String get pathEditor_searchRepeaters => 'Buscar repetidores';

  @override
  String get pathEditor_advancedHex =>
      'Avanzado: ruta hexadecimal sin procesar';

  @override
  String get pathEditor_hexLabel => 'Prefijos hexadecimales';

  @override
  String get pathEditor_hexHelper =>
      'Dos caracteres hexadecimales por salto, separados por comas.';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Inválido: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Máximo 64 saltos';

  @override
  String get pathEditor_usePath => 'Usar esta ruta';

  @override
  String get pathEditor_removeHop => 'Eliminar salto';

  @override
  String get pathEditor_unknownHop => 'Repetidor desconocido';

  @override
  String get chat_pathSavedLocally =>
      'Guardado localmente. Conéctate para sincronizar.';

  @override
  String get chat_pathDeviceConfirmed => 'Dispositivo confirmado.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Dispositivo aún no confirmado.';

  @override
  String get chat_type => 'Tipo';

  @override
  String get chat_path => 'Ruta';

  @override
  String get chat_publicKey => 'Clave pública';

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
  String get chat_direct => 'Directo';

  @override
  String get chat_poiShared => 'Punto de interés compartido';

  @override
  String chat_unread(int count) {
    return 'Sin leer: $count';
  }

  @override
  String get chat_markAsUnread => 'Marcar como no leído';

  @override
  String get chat_newMessages => 'Nuevos mensajes';

  @override
  String get chat_openLink => '¿Abrir enlace?';

  @override
  String get chat_openLinkConfirmation =>
      '¿Quieres abrir este enlace en tu navegador?';

  @override
  String get chat_open => 'Abrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'No se pudo abrir el enlace: $url';
  }

  @override
  String get chat_invalidLink => 'Formato de enlace no válido';

  @override
  String get map_title => 'Mapa de nodos';

  @override
  String get map_searchHint => 'Buscar por nombre o ID del nodo';

  @override
  String get map_activity => 'Actividad';

  @override
  String get map_online => 'En línea';

  @override
  String get map_recent => 'Reciente';

  @override
  String get map_stale => 'Antiguo; pasado de fecha';

  @override
  String get map_visible => 'Visible';

  @override
  String get map_hidden => 'Oculto';

  @override
  String get map_centerOnNode => 'Enfocar en el nodo';

  @override
  String get map_details => 'Detalles';

  @override
  String get map_noGps => 'Sin GPS';

  @override
  String get map_noResults => 'No se encontraron nodos coincidentes.';

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
    return 'Pines: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repetidor';

  @override
  String get map_room => 'Sala';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Pin (privado)';

  @override
  String get map_pinPublic => 'Pin (público)';

  @override
  String get map_lastSeen => 'Última vez visto';

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
  String get map_shareMarkerHere => 'Compartir marcador aquí';

  @override
  String get map_setAsMyLocation => 'Establecer mi ubicación';

  @override
  String get map_pinLabel => 'Etiqueta del pin';

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
    return 'Estás a punto de compartir una ubicación en $channelLabel. Este canal es público y cualquiera con la PSK puede verla.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Conéctate a un dispositivo para compartir marcadores';

  @override
  String get map_filterNodes => 'Filtrar nodos';

  @override
  String get map_nodeTypes => 'Tipos de nodo';

  @override
  String get map_chatNodes => 'Nodos de chat';

  @override
  String get map_repeaters => 'Repetidores';

  @override
  String get map_otherNodes => 'Otros nodos';

  @override
  String get map_showOverlaps => 'Superposiciones de tecla repetidora';

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
  String get map_showDiscoveryContacts => 'Mostrar contactos de descubrimiento';

  @override
  String get map_guessedLocation => 'Ubicación estimada';

  @override
  String get map_lastSeenTime => 'Hora de última vez visto';

  @override
  String get map_sharedPin => 'Pin compartido';

  @override
  String get map_sharedAt => 'Compartido';

  @override
  String get map_joinRoom => 'Unirse a la sala';

  @override
  String get map_manageRepeater => 'Gestionar repetidor';

  @override
  String get map_tapToAdd => 'Toque los nodos para añadirlos a la ruta.';

  @override
  String get map_runTrace => 'Ejecutar traza de ruta';

  @override
  String get map_runTraceWithReturnPath => 'Volver por la misma ruta.';

  @override
  String get map_removeLast => 'Eliminar último';

  @override
  String get map_pathTraceCancelled => 'Traza de ruta cancelada.';

  @override
  String get mapCache_title => 'Caché de mapa sin conexión';

  @override
  String get mapCache_selectAreaFirst =>
      'Selecciona primero un área para almacenar en caché';

  @override
  String get mapCache_noTilesToDownload =>
      'No hay teselas para descargar para esta área.';

  @override
  String get mapCache_downloadTilesTitle => 'Descargar teselas';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return '¿Descargar $count teselas para uso sin conexión?';
  }

  @override
  String get mapCache_downloadAction => 'Descargar';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Teselas almacenadas: $count';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Teselas almacenadas: $downloaded ($failed fallidas)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Borrar caché sin conexión';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      '¿Eliminar todas las teselas del mapa almacenadas en caché?';

  @override
  String get mapCache_offlineCacheCleared => 'Caché sin conexión borrada';

  @override
  String get mapCache_noAreaSelected => 'No se ha seleccionado ningún área';

  @override
  String get mapCache_cacheArea => 'Área de caché';

  @override
  String get mapCache_useCurrentView => 'Usar vista actual';

  @override
  String get mapCache_zoomRange => 'Rango de zoom';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Teselas estimadas: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Descargados $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Descargar teselas';

  @override
  String get mapCache_clearCacheButton => 'Borrar caché';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Descargas fallidas: $count';
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
  String get time_justNow => 'Justo ahora';

  @override
  String time_minutesAgo(int minutes) {
    return 'hace $minutes min.';
  }

  @override
  String time_hoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String time_daysAgo(int days) {
    return 'hace $days días';
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
  String get time_allTime => 'Todo el tiempo';

  @override
  String get dialog_disconnect => 'Desconectar';

  @override
  String get dialog_disconnectConfirm =>
      '¿Está seguro de que desea desconectarse de este dispositivo?';

  @override
  String get login_repeaterLogin => 'Inicio de sesión del repetidor';

  @override
  String get login_roomLogin => 'Inicio de sesión en la sala';

  @override
  String get login_password => 'Contraseña';

  @override
  String get login_enterPassword => 'Introduce la contraseña';

  @override
  String get login_savePassword => 'Guardar contraseña';

  @override
  String get login_savePasswordSubtitle =>
      'La contraseña se almacenará de forma segura en este dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Introduce la contraseña del repetidor para acceder como invitado o administrador.';

  @override
  String get login_roomDescription =>
      'Introduce la contraseña de la sala para acceder como invitado o administrador.';

  @override
  String get login_routing => 'Enrutamiento';

  @override
  String get login_routingMode => 'Modo de enrutamiento';

  @override
  String get login_autoUseSavedPath => 'Auto (usar la ruta guardada)';

  @override
  String get login_forceFloodMode => 'Forzar modo inundación';

  @override
  String get login_managePaths => 'Gestionar rutas';

  @override
  String get login_login => 'Iniciar sesión';

  @override
  String login_attempt(int current, int max) {
    return 'Intento $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Error de inicio de sesión: $error';
  }

  @override
  String get login_failedMessage =>
      'El inicio de sesión ha fallado. La contraseña es incorrecta o el repetidor no está disponible.';

  @override
  String get common_reload => 'Recargar';

  @override
  String get common_clear => 'Borrar';

  @override
  String get path_currentPathLabel => 'Ruta actual';

  @override
  String get path_noRepeatersFound =>
      'No se encontraron repetidores ni servidores de sala.';

  @override
  String get repeater_management => 'Gestión de repetidores';

  @override
  String get room_management => 'Administración del servidor de sala';

  @override
  String get repeater_guest => 'Información sobre repetidores';

  @override
  String get room_guest => 'Información del servidor';

  @override
  String get repeater_managementTools => 'Herramientas de gestión';

  @override
  String get repeater_guestTools => 'Herramientas para invitados';

  @override
  String get repeater_status => 'Estado';

  @override
  String get repeater_statusSubtitle =>
      'Ver el estado, las estadísticas y los vecinos del repetidor';

  @override
  String get repeater_telemetry => 'Telemetría';

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
  String get repeater_clockSyncAfterLogin =>
      'Sincronización del reloj después de iniciar sesión';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Enviar automáticamente la función de \"sincronización de reloj\" después de un inicio de sesión exitoso.';

  @override
  String get repeater_statusTitle => 'Estado del Repetidor';

  @override
  String get repeater_routingMode => 'Modo de enrutamiento';

  @override
  String get repeater_refresh => 'Actualizar';

  @override
  String get repeater_statusRequestTimeout =>
      'Se agotó el tiempo de espera de la solicitud de estado.';

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
  String get repeater_debugFlags => 'Banderas de depuración';

  @override
  String get repeater_radioStatistics => 'Estadísticas de radio';

  @override
  String get repeater_lastRssi => 'Último RSSI';

  @override
  String get repeater_lastSnr => 'Último SNR';

  @override
  String get repeater_noiseFloor => 'Nivel de ruido';

  @override
  String get repeater_txAirtime => 'Tiempo de aire TX';

  @override
  String get repeater_rxAirtime => 'Tiempo de aire RX';

  @override
  String get repeater_chanUtil => 'Utilización del canal';

  @override
  String get repeater_packetStatistics => 'Estadísticas de paquetes';

  @override
  String get repeater_sent => 'Enviados';

  @override
  String get repeater_received => 'Recibidos';

  @override
  String get repeater_duplicates => 'Duplicados';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days días ${hours}h $minutes min $seconds s';
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
  String get repeater_settingsTitle => 'Ajustes del repetidor';

  @override
  String get repeater_basicSettings => 'Ajustes básicos';

  @override
  String get repeater_repeaterName => 'Nombre del repetidor';

  @override
  String get repeater_repeaterNameHelper =>
      'Nombre visible para este repetidor';

  @override
  String get repeater_adminPassword => 'Contraseña de administrador';

  @override
  String get repeater_adminPasswordHelper => 'Contraseña de acceso completo';

  @override
  String get repeater_guestPassword => 'Contraseña de invitado';

  @override
  String get repeater_guestPasswordHelper =>
      'Contraseña de acceso de solo lectura';

  @override
  String get repeater_radioSettings => 'Ajustes de radio';

  @override
  String get repeater_frequencyMhz => 'Frecuencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'Potencia TX';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Ancho de banda';

  @override
  String get repeater_spreadingFactor => 'Factor de propagación';

  @override
  String get repeater_codingRate => 'Tasa de codificación';

  @override
  String get repeater_locationSettings => 'Ajustes de ubicación';

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
  String get repeater_features => 'Funciones';

  @override
  String get repeater_packetForwarding => 'Reenvío de paquetes';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Permitir que el repetidor reenvíe paquetes';

  @override
  String get repeater_guestAccess => 'Acceso de invitado';

  @override
  String get repeater_guestAccessSubtitle =>
      'Permitir acceso de invitado de solo lectura';

  @override
  String get repeater_privacyMode => 'Modo de privacidad';

  @override
  String get repeater_privacyModeSubtitle =>
      'Ocultar nombre/ubicación en anuncios';

  @override
  String get repeater_advertisementSettings => 'Ajustes de anuncios';

  @override
  String get repeater_localAdvertInterval => 'Intervalo de anuncio local';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervalo de anuncio por inundación';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Intervalo de anuncio cifrado';

  @override
  String get repeater_dangerZone => 'Zona de peligro';

  @override
  String get repeater_rebootRepeater => 'Reiniciar repetidor';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reiniciar el dispositivo repetidor';

  @override
  String get repeater_rebootRepeaterConfirm =>
      '¿Está seguro de que desea reiniciar este repetidor?';

  @override
  String get repeater_regenerateIdentityKey => 'Regenerar clave de identidad';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generar una nueva pareja de claves pública/privada';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Esto generará una nueva identidad para el repetidor. ¿Continuar?';

  @override
  String get repeater_eraseFileSystem => 'Borrar sistema de archivos';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatear el sistema de archivos del repetidor';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ADVERTENCIA: Esto borrará todos los datos del repetidor. ¡Esto no se puede deshacer!';

  @override
  String get repeater_eraseSerialOnly =>
      'Borrar solo está disponible a través de la consola serie.';

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
  String get repeater_settingsSaved => 'Ajustes guardados correctamente';

  @override
  String get repeater_rxGain => 'Ganancia RX';

  @override
  String get repeater_rxGainHelper =>
      'Mayor sensibilidad, mayor consumo de corriente (solo para SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain =>
      'Mejora el rendimiento de RX con la nueva versión.';

  @override
  String get repeater_multiAcks => 'ACK múltiples';

  @override
  String get repeater_multiAcksSubtitle =>
      'Reconocer mensajes a través de múltiples rutas para una mejor entrega.';

  @override
  String get repeater_refreshMultiAcks => 'Actualizar ACK múltiples';

  @override
  String get repeater_networkHealth => 'Salud de la red';

  @override
  String get repeater_loopDetect => 'Detección de bucles';

  @override
  String get repeater_loopDetectHelper =>
      'Crea paquetes de \"flujo\" que parezcan bucles de enrutamiento.';

  @override
  String get repeater_loopDetectOff => 'Desactivado';

  @override
  String get repeater_loopDetectMinimal => 'Mínimo';

  @override
  String get repeater_loopDetectModerate => 'Moderado';

  @override
  String get repeater_loopDetectStrict => 'Estricto';

  @override
  String get repeater_dutyCycle => 'Ciclo de trabajo';

  @override
  String get repeater_dutyCycleHelper => 'Porcentaje máximo de tiempo de aire';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Información del propietario';

  @override
  String get repeater_ownerInfoHelper =>
      'Metadatos públicos para este repetidor';

  @override
  String get repeater_refreshOwnerInfo =>
      'Actualizar información del propietario';

  @override
  String get repeater_floodMax => 'Máximo de saltos por inundación';

  @override
  String get repeater_floodMaxHelper =>
      'Número máximo de paquetes de inundación que un nodo puede enviar (0-64)';

  @override
  String get repeater_advancedSettings => 'Ajustes avanzados';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Controles de ajuste para operadores experimentados';

  @override
  String get repeater_pathHashMode => 'Modo de hash de ruta';

  @override
  String get repeater_pathHashModeHelper =>
      'Bytes utilizados para codificar el ID de este repetidor en las etiquetas de ruta/detección de bucles. 0=1 byte (256 IDs, hasta 64 saltos), 1=2 bytes (65.000 IDs, hasta 32 saltos), 2=3 bytes (16 millones de IDs, hasta 21 saltos). Las versiones 1.13 y anteriores de firmware eliminan rutas de múltiples bytes; solo se detectan una vez que la red está activa en la versión 1.14 o posterior.';

  @override
  String get repeater_keySettings => 'Cambiar Claves de Identidad';

  @override
  String get repeater_keySettingsSubtitle =>
      'Cambiar la pareja de claves pública/privada';

  @override
  String get repeater_prvKey => 'Clave privada';

  @override
  String get repeater_prvKeyHelper =>
      'Una nueva clave privada para el repetidor, una cadena hexadecimal de 128 caracteres.';

  @override
  String get repeater_generatePrvKey => 'Genera un par de claves aleatorias';

  @override
  String get repeater_stopGeneratingPrvKey =>
      'Interrumpir la búsqueda de par de claves';

  @override
  String get repeater_pubKey => 'Clave pública';

  @override
  String get repeater_pubKeyHelper =>
      'Esta es la clave pública que corresponde a la clave privada generada. No se puede establecer directamente.';

  @override
  String get repeater_pubKeyPrefix => 'Prefijo deseado';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Encuentre una clave pública que comience con estos dígitos hexadecimales. Se esperan $tries intentos.';
  }

  @override
  String get repeater_txDelay => 'Retraso TX por inundación';

  @override
  String get repeater_txDelayHelper =>
      'Ajuste de retransmisión para el tráfico de inundación, como un multiplicador del tiempo de transmisión del paquete (0-2, valor predeterminado 0.5). Un valor más alto significa menos colisiones, pero una entrega más lenta.';

  @override
  String get repeater_directTxDelay => 'Retraso TX directo';

  @override
  String get repeater_directTxDelayHelper =>
      'Reenvío de espacios para el tráfico directo (no masivo), como un multiplicador del tiempo de transmisión del paquete (0-2, valor predeterminado 0.3).';

  @override
  String get repeater_intThresh => 'Límite de interferencia';

  @override
  String get repeater_intThreshHelper =>
      'Se establece un umbral para la calibración del nivel de ruido de la radio, de modo que rechaza las interferencias que superen este nivel. 0 deshabilita: solo aumente este valor si observa errores en una banda de frecuencia con mucho ruido.';

  @override
  String get repeater_agcResetInterval => 'Intervalo de reinicio de AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      '¿Con qué frecuencia se debe restablecer el control automático de ganancia del radio para recuperarse de un estado de ganancia bloqueada? Se puede restablecer cada pocos segundos o cada 4 segundos. Desactiva la función de restablecimiento periódico.';

  @override
  String get repeater_actionsTitle => 'Acciones';

  @override
  String get repeater_sendAdvert => 'Enviar anuncio por inundación';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Transmitir un anuncio por inundación a través de la red.';

  @override
  String get repeater_sendAdvertZeroHop => 'Enviar anuncio sin saltos';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Transmite un anuncio de un solo salto (sin retransmisiones).';

  @override
  String get repeater_clockSync => 'Sincronizar reloj ahora';

  @override
  String get repeater_clockSyncSubtitle =>
      'Envía la hora de tu teléfono al repetidor.';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action completado correctamente';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return 'Error en $action: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Configuración guardada — reinicie el repetidor para aplicar los cambios.';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Algunas configuraciones no se pudieron aplicar: $failures';
  }

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
  String get repeater_refreshPacketForwarding =>
      'Actualizar Enrutamiento de Paquetes';

  @override
  String get repeater_refreshGuestAccess => 'Actualizar Acceso Invitados';

  @override
  String get repeater_refreshPrivacyMode => 'Actualizar Modo Privacidad';

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
  String get repeater_cliQuickClockSync => 'Sincronización del reloj';

  @override
  String get repeater_cliQuickDiscovery => 'Descubrir Vecinos';

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
  String get repeater_getCategory => 'Obtener valores';

  @override
  String get repeater_powerMgmt => 'Gestión de la energía';

  @override
  String get repeater_sensors => 'Sensores';

  @override
  String get repeater_cliHelpPowerOff =>
      'Apaga el dispositivo. (no se espera respuesta)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Restablece el reloj a una fecha conocida y reinicia el dispositivo.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Envía un anuncio que no requiere saltos (solo para los vecinos inmediatos).';

  @override
  String get repeater_cliHelpStartOta =>
      'Inicia una actualización de firmware por aire en las placas compatibles.';

  @override
  String get repeater_cliHelpTime =>
      'Establece la hora del dispositivo en los segundos correspondientes a la época Unix. La hora no puede retroceder.';

  @override
  String get repeater_cliHelpBoard =>
      'Muestra el fabricante de la placa base / identificador de hardware.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Envía una solicitud de descubrimiento de nodos a los vecinos cercanos. (Solo para repetidores)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Indica si el modo de ahorro de energía está activado o desactivado.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Activa o desactiva el modo de ahorro de energía (si está disponible).';

  @override
  String get repeater_cliHelpErase =>
      '(Solo para dispositivos) Formatea el sistema de archivos del dispositivo. Elimina todas las configuraciones y contactos.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Establece el ciclo de transmisión máximo permitido como un porcentaje (1-100). Ajusta internamente el factor de tiempo de aire.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(Solo para series) Reemplaza la clave privada de identificación del dispositivo. Se requiere reiniciar para aplicar. Genera una nueva clave pública.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Solo para SX126x) Activa/desactiva el amplificador de la RX para mejorar la sensibilidad a corrientes más altas.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Define la cadena de información de contacto del propietario que se incluye en los anuncios. Utilice \'|\' para indicar nuevas líneas.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Establece el modo de hash de la ruta. 0 = antiguo, 1 = estándar, 2 = estricto. Afecta la forma en que se comparan las rutas.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Establece la sensibilidad para la detección de bucles de enrutamiento: apagado, mínimo, moderado o estricto.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Solo para la configuración de frecuencia) Establece rápidamente la frecuencia deseada. Se requiere reiniciar. Se recomienda utilizar la opción \"configurar radio\" para obtener todos los parámetros de la radio.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Solo para el puente ESPNow) Establece el canal de WiFi (1-14) que utiliza el puente.';

  @override
  String get repeater_cliHelpGetName =>
      'Muestra el nombre del nodo configurado.';

  @override
  String get repeater_cliHelpGetRole =>
      'Muestra el rol del firmware (Repetidor, Servidor de habitación, etc.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Muestra la clave pública del dispositivo.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Solo para uso en serie) Muestra la clave privada del dispositivo. Trátala como una información confidencial.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Indica si el enrutamiento de paquetes (función de repetidor) está activado o desactivado.';

  @override
  String get repeater_cliHelpGetTx => 'Muestra la potencia actual en dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Muestra la frecuencia de radio configurada en MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Muestra todos los parámetros de radio: frecuencia, ancho de banda, factor de dispersión, tasa de codificación.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Solo para SX126x) Muestra el estado de ganancia amplificada del receptor.';

  @override
  String get repeater_cliHelpGetAf => 'Muestra el factor de tiempo actual.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Muestra el ciclo de trabajo actual permitido como un porcentaje.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Muestra el umbral de interferencia del canal en dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Muestra el intervalo de reinicio del AGC en segundos.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Indica si el modo de confirmación doble está activado (1) o desactivado (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Indica si se permite el acceso de solo lectura para los usuarios invitados.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Muestra el intervalo de publicidad local en minutos.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Muestra el intervalo de publicidad para la emisión de la señal de inundación, expresado en horas.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Muestra la contraseña de invitado configurada.';

  @override
  String get repeater_cliHelpGetLat => 'Muestra la latitud configurada.';

  @override
  String get repeater_cliHelpGetLon => 'Muestra la longitud configurada.';

  @override
  String get repeater_cliHelpGetRxDelay => 'Muestra el valor base de rxdelay.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Muestra el factor de retardo en modo de inundación.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Muestra el factor de retardo en modo directo.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Muestra el número máximo de saltos por inundación.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Muestra la cadena de información de contacto del propietario.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Muestra el modo de hash de ruta (0/1/2).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Muestra la sensibilidad en la detección de bucles.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Solo para series) Enumera las entradas de control de acceso en un repetidor.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Indica si el puente está habilitado.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Muestra el retardo del puente en milisegundos.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Indica si el puente está enviando o recibiendo paquetes RX o TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Solo puente RS232) Muestra la velocidad de transmisión del puente.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Solo para el puente ESPNow) Muestra el canal WiFi del puente.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Solo para el puente ESPNow) Muestra el secreto compartido por el puente.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Solo NRF52) Muestra la versión del cargador.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Muestra el multiplicador del ADC (escalado de voltaje de la batería).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Indica si el sistema cuenta con funciones de gestión de energía.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Indica la fuente de energía actual: externa o batería.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Muestra las razones más recientes de reinicio y apagado.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Muestra el voltaje de la batería al encender el sistema en milivoltios (mV).';

  @override
  String get repeater_cliHelpSensorGet =>
      'Lee una configuración de sensor personalizada mediante una tecla.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Crea una configuración personalizada para un sensor.';

  @override
  String get repeater_cliHelpSensorList =>
      'Muestra todas las configuraciones de sensores personalizadas, paginadas a partir de un índice de inicio opcional.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Muestra el ámbito predeterminado actual.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Establece el ámbito regional predeterminado. Utilice \"<null>\" para restablecer a la configuración predeterminada.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Enumera las regiones que permiten el paso de vehículos debido a inundaciones.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Enumera las regiones que prohíben el tráfico debido a las inundaciones.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Solo para series) Muestra estadísticas a nivel de paquetes.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Solo para transmisiones en serie) Muestra estadísticas de radio.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Solo para series) Muestra estadísticas clave del firmware.';

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
  String get telemetry_currentLabel => 'Corriente';

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
  String get telemetry_digitalInputLabel => 'Entrada digital';

  @override
  String get telemetry_digitalOutputLabel => 'Salida digital';

  @override
  String get telemetry_analogInputLabel => 'Entrada analógica';

  @override
  String get telemetry_analogOutputLabel => 'Salida analógica';

  @override
  String get telemetry_genericLabel => 'Sensor genérico';

  @override
  String get telemetry_luminosityLabel => 'Luminosidad';

  @override
  String get telemetry_presenceLabel => 'Presencia';

  @override
  String get telemetry_humidityLabel => 'Humedad';

  @override
  String get telemetry_accelerometerLabel => 'Acelerómetro';

  @override
  String get telemetry_pressureLabel => 'Presión';

  @override
  String get telemetry_altitudeLabel => 'Altitud';

  @override
  String get telemetry_frequencyLabel => 'Frecuencia';

  @override
  String get telemetry_percentageLabel => 'Porcentaje';

  @override
  String get telemetry_concentrationLabel => 'Concentración';

  @override
  String get telemetry_powerLabel => 'Potencia';

  @override
  String get telemetry_distanceLabel => 'Distancia';

  @override
  String get telemetry_energyLabel => 'Energía';

  @override
  String get telemetry_directionLabel => 'Dirección';

  @override
  String get telemetry_timeLabel => 'Hora';

  @override
  String get telemetry_gyrometerLabel => 'Giroscopio';

  @override
  String get telemetry_colourLabel => 'Color';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Interruptor';

  @override
  String get telemetry_polylineLabel => 'Polilínea';

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
  String get telemetry_autoFetchQuantity => 'Número de solicitudes';

  @override
  String get telemetry_error => 'No se pudieron obtener los datos';

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
    return 'Escuchado hace $time';
  }

  @override
  String get channelPath_title => 'Ruta del paquete';

  @override
  String get channelPath_viewMap => 'Ver mapa';

  @override
  String get channelPath_otherObservedPaths => 'Otras rutas observadas';

  @override
  String get channelPath_repeaterHops => 'Saltos del repetidor';

  @override
  String get channelPath_noHopDetails =>
      'Los detalles del paquete no están disponibles.';

  @override
  String get channelPath_messageDetails => 'Detalles del mensaje';

  @override
  String get channelPath_senderLabel => 'Remitente';

  @override
  String get channelPath_timeLabel => 'Hora';

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
  String get listFilter_az => 'De la A a la Z';

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
  String get pathTrace_refreshTooltip => 'Actualizar trazado de ruta';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Uno o más de los saltos carecen de una ubicación';

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
  String get losBlockedSpotsTitle => 'Espacios ocupados';

  @override
  String get losBlockedSpotsHint =>
      'Seleccione un punto bloqueado para resaltarlo en el mapa.';

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
  String get losSelectedObstructionTitle => 'Obstrucción seleccionada';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Bloqueado por $obstruction a una altura de $heightUnit, a $distanceFromA metros de A y a $distanceFromB metros de B ($distanceUnit).';
  }

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
  String get contacts_pathTrace => 'Traza de ruta';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Traza de ruta al repetidor';

  @override
  String get contacts_repeaterPing => 'Hacer ping al repetidor';

  @override
  String get contacts_roomPathTrace => 'Traza de ruta al servidor de sala';

  @override
  String get contacts_roomPing => 'Hacer ping al servidor de sala';

  @override
  String get contacts_chatTraceRoute => 'Ruta de trazado';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Traza de ruta a $name';
  }

  @override
  String get contacts_clipboardEmpty => 'El portapapeles está vacío.';

  @override
  String get contacts_invalidAdvertFormat => 'Formato de anuncio no válido';

  @override
  String get contacts_contactImported => 'El contacto ha sido importado.';

  @override
  String get contacts_contactImportFailed =>
      'Contacto no se importó correctamente.';

  @override
  String get contacts_zeroHopAdvert => 'Anuncio de un solo salto';

  @override
  String get contacts_floodAdvert => 'Anuncio de inundación';

  @override
  String get contacts_copyAdvertToClipboard => 'Copiar anuncio al portapapeles';

  @override
  String get contacts_addContactFromClipboard =>
      'Agregar contacto desde el portapapeles';

  @override
  String get contacts_ShareContact => 'Copiar contacto al portapapeles';

  @override
  String get contacts_ShareContactZeroHop =>
      'Compartir contacto por anuncio de un solo salto';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Contacto enviado por anuncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'No se pudo enviar el contacto.';

  @override
  String get contacts_contactAdvertCopied => 'Anuncio copiado al portapapeles.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'No se pudo copiar el anuncio al portapapeles.';

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
      'Exportar repetidores / servidores de sala a GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporta repetidores o servidores de sala con una ubicación a un archivo GPX.';

  @override
  String get settings_gpxExportContacts => 'Exportar compañeros a GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporta compañeros con una ubicación a un archivo GPX.';

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
      'No compatible con tu dispositivo o sistema operativo';

  @override
  String get settings_gpxExportError => 'Hubo un error al exportar.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Ubicaciones de repetidores y servidores de sala';

  @override
  String get settings_gpxExportChat => 'Ubicaciones de compañeros';

  @override
  String get settings_gpxExportAllContacts =>
      'Todas las ubicaciones de contactos';

  @override
  String get settings_gpxExportShareText =>
      'Datos del mapa exportados desde meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'Exportación GPX de datos de mapa de meshcore-open';

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

  @override
  String get chat_sendCooldown =>
      'Por favor, espere un momento antes de reenviar.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Salta a los mensajes más antiguos sin leer';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Cuando abras una conversación con mensajes sin leer, desplázate hacia el primer mensaje sin leer en lugar del más reciente.';

  @override
  String get appSettings_languageHu => 'Húngaro';

  @override
  String get appSettings_languageJa => 'Japonés';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_tooltip => 'Estadísticas de radio y malla';

  @override
  String get radioStats_screenTitle => 'Estadísticas de radio';

  @override
  String get radioStats_notConnected =>
      'Conéctese a un dispositivo para visualizar estadísticas de radio.';

  @override
  String get radioStats_firmwareTooOld =>
      'Las estadísticas de radio requieren un firmware compatible v8 o posterior.';

  @override
  String get radioStats_waiting => 'Esperando datos…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Nivel de ruido: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Último RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Último SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Tiempo de emisión en Texas (total): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tiempo de transmisión de RX (total): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Nivel de ruido (dBm) en muestras recientes.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Nivel de ruido: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Obteniendo estadísticas de la radio…';

  @override
  String get radioStats_settingsTile => 'Estadísticas de radio';

  @override
  String get radioStats_settingsSubtitle =>
      'Nivel de ruido, RSSI, SNR y tiempo de transmisión';

  @override
  String get translation_title => 'Traducción';

  @override
  String get imageMessages_enableTitle => 'Mensajes de imagen';

  @override
  String get imageMessages_enableSubtitle =>
      'Enviar imágenes a través de la malla. Requiere la descarga de un modelo de imagen único.';

  @override
  String get imageMessages_modelSectionTitle => 'Modelo de imagen';

  @override
  String get imageMessages_downloadModel => 'Descargar';

  @override
  String get imageMessages_cancelDownload => 'Cancelar';

  @override
  String get imageMessages_removeModel => 'Eliminar modelo';

  @override
  String get imageMessages_modelReady => 'Listo';

  @override
  String get imageMessages_modelNotPublished =>
      'Aún no publicado — esta versión no puede descargarlo.';

  @override
  String get imageMessages_downloadFailed =>
      'El modelo de imagen no pudo ser descargado.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Procesar imágenes automáticamente';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Reconstruya cada imagen tan pronto como llegue. Utiliza aproximadamente 2 GB de memoria durante un segundo cada vez; desactívelo para reconstruir con un toque.';

  @override
  String get translation_enableTitle => 'Habilitar la traducción';

  @override
  String get translation_enableSubtitle =>
      'Traducir los mensajes entrantes y permitir la traducción previa al envío.';

  @override
  String get translation_composerTitle => 'Traducir antes de enviar';

  @override
  String get translation_composerSubtitle =>
      'Controla el estado predeterminado del icono de traducción del compositor.';

  @override
  String get translation_autoIncomingTitle =>
      'Traducir mensajes automáticamente';

  @override
  String get translation_autoIncomingSubtitle =>
      'Traduce mensajes para notificaciones y para chats o canales automáticamente.';

  @override
  String get translation_translateMessage => 'Traducir mensaje';

  @override
  String get translation_targetLanguage => 'Idioma de destino';

  @override
  String get translation_useAppLanguage =>
      'Utilizar el idioma de la aplicación';

  @override
  String get translation_downloadedModelLabel => 'Modelo descargado';

  @override
  String get translation_presetModelLabel =>
      'Modelo predefinido de Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL del modelo manual';

  @override
  String get translation_downloadModel => 'Descargar el modelo';

  @override
  String get translation_downloading => 'Descargando...';

  @override
  String get translation_working => 'Trabajando...';

  @override
  String get translation_stop => '¡Detente!';

  @override
  String get translation_mergingChunks =>
      'Combinando los fragmentos descargados en el archivo final...';

  @override
  String get translation_downloadedModels => 'Modelos descargados';

  @override
  String get translation_deleteModel => 'Eliminar modelo';

  @override
  String get translation_modelDownloaded => 'Modelo de traducción descargado.';

  @override
  String get translation_downloadStopped => 'La descarga se ha detenido.';

  @override
  String translation_downloadFailed(String error) {
    return 'No se pudo descargar: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Primero, introduzca la URL del modelo.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostrar código PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Ocultar PIN';

  @override
  String get scanner_linuxPairingPinTitle =>
      'PIN para emparejar dispositivos Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Introduzca el código PIN para $deviceName (deje en blanco si no hay ninguno).';
  }

  @override
  String get translation_messageTranslation => 'Traducción del mensaje';

  @override
  String get translation_translateBeforeSending => 'Traducir antes de enviar';

  @override
  String get translation_composerEnabledHint =>
      'Los mensajes serán traducidos antes de ser enviados.';

  @override
  String get translation_composerDisabledHint =>
      'Envía mensajes utilizando el lenguaje escrito original.';

  @override
  String translation_translateTo(String language) {
    return 'Traducir a $language';
  }

  @override
  String get translation_translationOptions => 'Opciones de traducción';

  @override
  String get translation_systemLanguage => 'Idioma del sistema';

  @override
  String get background_serviceTitle => 'MeshCore en ejecución';

  @override
  String get background_serviceText => 'Manteniendo BLE conectado';

  @override
  String appSettings_translationModelDeleted(String name) {
    return 'Eliminado $name';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'No se pudo actualizar el canal: $error';
  }

  @override
  String get contact_typeChat => 'Chat';

  @override
  String get contact_typeRepeater => 'Repetidor';

  @override
  String get contact_typeRoom => 'Sala';

  @override
  String get contact_typeSensor => 'Sensor';

  @override
  String get contact_typeUnknown => 'Desconocido';

  @override
  String get map_zoomIn => 'Acercar';

  @override
  String get map_zoomOut => 'Alejar';

  @override
  String get map_centerMap => 'Centrar mapa';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth requiere un navegador Chromium.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'Confirmado mediante GPS';

  @override
  String get pathTrace_legendInferred => 'Posición estimada';

  @override
  String get pathMap_viewSingle => 'Individual';

  @override
  String get pathMap_viewCombined => 'Combinado';

  @override
  String get pathMap_play => 'Reproducir';

  @override
  String get pathMap_pause => 'Pausa';

  @override
  String get pathMap_replay => 'Repetir';

  @override
  String get pathMap_stepBack => 'Salto anterior';

  @override
  String get pathMap_stepForward => 'Siguiente salto';

  @override
  String get pathMap_animationOn => 'Mostrar animación del paquete';

  @override
  String get pathMap_animationOff => 'Ocultar la animación del paquete';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Saltar $current de $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Rutas observadas: $count';
  }

  @override
  String get pathMap_primary => 'Principal';

  @override
  String pathMap_alternate(int index) {
    return 'Alternativo $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saltos',
      one: '1 salto',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Segmento compartido';

  @override
  String get pathMap_legendEstimated => 'Segmento estimado';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Utilizado en $count rutas.';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saltos no tienen ubicación — la ruta mostrada es parcial',
      one: '1 salto no tiene ubicación — la ruta mostrada es parcial',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Mostrar todas';

  @override
  String get pathMap_hidePath => 'Ocultar ruta';

  @override
  String get pathMap_showPath => 'Mostrar ruta';

  @override
  String get pathMap_collapsePanel => 'Cerrar panel';

  @override
  String get pathMap_expandPanel => 'Ampliar panel';

  @override
  String get pathMap_noLocation => 'Sin ubicación';

  @override
  String get pathMap_followPacket => 'Seguir paquete';

  @override
  String get pathMap_unfollowPacket => 'Dejar de seguir el paquete';

  @override
  String get imageSend_title => 'Enviar imagen';

  @override
  String get imageSend_cropNote =>
      'Redimensionado a 512 × 512 · la relación de aspecto no se conservó';

  @override
  String get imageSend_originalSize => 'Texto original';

  @override
  String get imageSend_onAirSize => 'En emisión';

  @override
  String get imageSend_quality => 'Calidad';

  @override
  String get imageSend_qualityStandard => 'Estándar';

  @override
  String get imageSend_qualityHigh => 'Alto';

  @override
  String get imageSend_packetsLabel => 'Paquetes';

  @override
  String get imageSend_airtimeLabel => 'Tiempo en pantalla';

  @override
  String get imageSend_sizeLabel => 'Carga útil';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paquetes',
      one: 'paquete',
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
  String get imageSend_radioUnknownTitle =>
      'Configuración de radio desconocida';

  @override
  String get imageSend_radioUnknownBody =>
      'Conéctese a un dispositivo para que se pueda calcular la hora de transmisión.';

  @override
  String get imageSend_longSendTitle => 'Larga transmisión';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Esto mantendrá el canal durante aproximadamente $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Enrutamiento de inundación: cada repetidor dentro del rango retransmite cada paquete, por lo que el canal permanece ocupado durante más tiempo que esto.';

  @override
  String get imageSend_parityTitle => 'Paquete de recuperación';

  @override
  String get imageSend_paritySubtitle =>
      'Un paquete adicional. Los mensajes grupales no son reconocidos, por lo que esto permite al receptor reconstruir la imagen si se pierde un solo paquete.';

  @override
  String get imageSend_send => 'Enviar';

  @override
  String get imageSend_cancel => 'Cancelar';

  @override
  String get imageSend_encodeFailed => 'Esta imagen no pudo ser codificada.';

  @override
  String get imageSend_codecDownloading =>
      'El modelo de imagen todavía se está descargando.';

  @override
  String get imageSend_codecUnavailable =>
      'El envío de imágenes no está disponible en este dispositivo.';

  @override
  String get imageSend_codecDisabled =>
      'Los mensajes de imagen están desactivados en la configuración.';

  @override
  String get imageSend_deviceUnsupported =>
      'Esta radio no puede enviar paquetes de imagen. Conecte un dispositivo con el firmware Companion versión 13 o superior.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'Las imágenes se transmiten como datos grupales, por lo que solo se pueden enviar a un canal, no mediante mensajes directos.';

  @override
  String get imageSend_tooLarge =>
      'Esa imagen se codificó en más paquetes de los que permite el formato de malla.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paquetes',
      one: 'paquete',
    );
    return 'Imagen enviada como $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'La imagen no pudo ser enviada: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Envío de imagen — paquete $sent de $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Nodo $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$received de $total paquetes';
  }

  @override
  String get receivedImage_queued => 'Esperando descifrar';

  @override
  String get receivedImage_tapToDecode => 'Toque para decodificar';

  @override
  String get receivedImage_decoding =>
      'Reconstruyendo… aproximadamente 1 segundo';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Imagen incompleta — $received de $total paquetes llegados';
  }

  @override
  String get receivedImage_corrupt => 'La imagen no pudo ser reconstruida';

  @override
  String get receivedImage_decoderMissing =>
      'Imagen recibida — la decodificación de la imagen no funciona';

  @override
  String get receivedImage_evicted => 'Imagen ya no almacenada';

  @override
  String get receivedImage_retry => 'Inténtalo de nuevo';

  @override
  String get receivedImage_decodeAgain => 'Decodificar de nuevo';

  @override
  String get receivedImage_openSettings => 'Configurar';

  @override
  String get receivedImage_tapToProcess => 'Toque para procesar';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'paquetes',
      one: 'paquete',
    );
    return '$bytes bytes · $packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds segundos';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }
}
