// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Contactos';

  @override
  String get nav_channels => 'Canais';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_ok => 'Tudo bem';

  @override
  String get common_connect => 'Conectar';

  @override
  String get common_unknownDevice => 'Dispositivo Desconhecido';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_deleteAll => 'Excluir Tudo';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_done => 'Done';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_add => 'Adicionar';

  @override
  String get common_settings => 'Configurações';

  @override
  String get common_disconnect => 'Desconectar';

  @override
  String get common_connected => 'Conectado';

  @override
  String get common_disconnected => 'Desconectado';

  @override
  String get common_create => 'Criar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_share => 'Compartilhar';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_hide => 'Esconder';

  @override
  String get common_remove => 'Remover';

  @override
  String get common_enable => 'Ativar';

  @override
  String get common_disable => 'Desativar';

  @override
  String get common_undo => 'Desfazer';

  @override
  String get messageStatus_sent => 'Enviado';

  @override
  String get messageStatus_delivered => 'Entregue';

  @override
  String get messageStatus_pending => 'Enviar';

  @override
  String get messageStatus_failed => 'Falhou ao enviar';

  @override
  String get messageStatus_repeated => 'Ouvi repetidamente';

  @override
  String get urlImage_enable => 'Enable URL images';

  @override
  String get urlImage_possible => 'Possible URL image; enable it in Settings.';

  @override
  String get common_reboot => 'Reiniciar';

  @override
  String get common_loading => 'Carregando...';

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
  String get common_autoRefresh => 'Atualização automática';

  @override
  String get common_interval => 'Intervalo';

  @override
  String get scanner_title => 'MeshCore: Versão aberta';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Estabelecer conexão via TCP';

  @override
  String get tcpHostLabel => 'Endereço IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Porta';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Insira o endereço final e conecte-se.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Conectando a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'É necessário fornecer um endereço IP.';

  @override
  String get tcpErrorPortInvalid =>
      'O valor do porto deve estar entre 1 e 65535.';

  @override
  String get tcpErrorUnsupported =>
      'O protocolo TCP não é suportado nesta plataforma.';

  @override
  String get tcpErrorTimedOut => 'A conexão TCP expirou.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Falha na conexão TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Conecte via USB';

  @override
  String get usbScreenSubtitle =>
      'Selecione um dispositivo serial detectado e conecte-o diretamente ao seu nó MeshCore.';

  @override
  String get usbScreenStatus => 'Selecione um dispositivo USB';

  @override
  String get usbScreenNote =>
      'A comunicação serial via USB está ativa em dispositivos Android e plataformas de desktop compatíveis.';

  @override
  String get usbScreenEmptyState =>
      'Nenhum dispositivo USB encontrado. Conecte um e atualize.';

  @override
  String get usbErrorPermissionDenied =>
      'A permissão para acesso via USB foi negada.';

  @override
  String get usbErrorDeviceMissing =>
      'O dispositivo USB selecionado não está mais disponível.';

  @override
  String get usbErrorInvalidPort => 'Selecione um dispositivo USB válido.';

  @override
  String get usbErrorBusy =>
      'Já existe uma solicitação de conexão USB em andamento.';

  @override
  String get usbErrorNotConnected => 'Não há nenhum dispositivo USB conectado.';

  @override
  String get usbErrorOpenFailed =>
      'Não foi possível abrir o dispositivo USB selecionado.';

  @override
  String get usbErrorConnectFailed =>
      'Não foi possível conectar ao dispositivo USB selecionado.';

  @override
  String get usbErrorUnsupported =>
      'A comunicação serial via USB não é suportada nesta plataforma.';

  @override
  String get usbErrorAlreadyActive => 'A conexão USB já está ativa.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Nenhum dispositivo USB foi selecionado.';

  @override
  String get usbErrorPortClosed => 'A conexão USB não está ativa.';

  @override
  String get usbErrorConnectTimedOut =>
      'A conexão expirou. Verifique se o dispositivo possui o firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Dispositivo de Serial para a Web';

  @override
  String get usbStatus_notConnected => 'Selecione um dispositivo USB';

  @override
  String get usbStatus_connecting => 'Conectando ao dispositivo USB...';

  @override
  String get usbStatus_searching => 'Procurando por dispositivos USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Falha na conexão USB: $error';
  }

  @override
  String get scanner_scanning => 'Procurando por dispositivos...';

  @override
  String get scanner_connecting => 'Conectando...';

  @override
  String get scanner_disconnecting => 'Desconectando...';

  @override
  String get scanner_notConnected => 'Não está conectado';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Procurando dispositivos MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Toque em \"Escanear\" para encontrar dispositivos MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Falha na conexão: $error';
  }

  @override
  String get scanner_stop => 'Pare';

  @override
  String get scanner_scan => 'Digitalizar';

  @override
  String get scanner_bluetoothOff => 'Bluetooth está desativado';

  @override
  String get scanner_bluetoothOffMessage =>
      'Por favor, ative o Bluetooth para escanear por dispositivos.';

  @override
  String get scanner_chromeRequired => 'Navegador Chrome necessário';

  @override
  String get scanner_chromeRequiredMessage =>
      'Esta aplicação web requer o Google Chrome ou um navegador baseado no Chromium para suporte de Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Ative o Bluetooth';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'A funcionalidade Bluetooth não está disponível no navegador. Conecte-se via USB em vez disso.';

  @override
  String get device_quickSwitch => 'Mudar rapidamente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Configurações';

  @override
  String get settings_deviceInfo => 'Informações do Dispositivo';

  @override
  String get settings_appSettings => 'Configurações do App';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificações, mensagens e preferências de mapa';

  @override
  String get settings_nodeSettings => 'Configurações do Nó';

  @override
  String get settings_nodeName => 'Nome do Nó';

  @override
  String get settings_nodeNameNotSet => 'Não definido';

  @override
  String get settings_nodeNameHint => 'Insira o nome do nó';

  @override
  String get settings_nodeNameUpdated => 'Nome atualizado';

  @override
  String get settings_radioSettings => 'Configurações de Rádio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequência, potência, fator de espalhamento';

  @override
  String get settings_radioSettingsUpdated =>
      'Configurações de rádio atualizadas';

  @override
  String get settings_regionSettings => 'Regiões';

  @override
  String get settings_regionSettingsSubtitle => 'Gerenciar regiões armazenadas';

  @override
  String get settings_regionManagement_screenTitle => 'Gestão de Região';

  @override
  String get settings_regionNameHint => 'Nome da região';

  @override
  String get settings_regionAddRegion => 'Adicionar região';

  @override
  String get settings_regionFetchRegions =>
      'Regiões de obtenção a partir de repetidores';

  @override
  String get settings_regionFetchRegionsFail => 'Nenhuma região foi encontrada';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Esta região já foi adicionada';

  @override
  String get settings_regionName => 'Nome da Região';

  @override
  String get settings_regionDeleted => 'Região excluída';

  @override
  String get settings_deleteRegion => 'Excluir Região';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Remover \"$region\" da lista de regiões?';
  }

  @override
  String get settings_location => 'Localização';

  @override
  String get settings_locationSubtitle => 'Coordenadas GPS';

  @override
  String get settings_locationUpdated => 'Localização atualizada';

  @override
  String get settings_locationBothRequired =>
      'Insira a latitude e a longitude.';

  @override
  String get settings_locationInvalid => 'Latitude ou longitude inválidos.';

  @override
  String get settings_locationGPSEnable => 'Ativar GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Habilita a atualização automática da localização via GPS.';

  @override
  String get settings_locationIntervalSec => 'Intervalo para GPS (Segundos)';

  @override
  String get settings_locationIntervalInvalid =>
      'O intervalo deve ser de pelo menos 60 segundos e inferior a 86400 segundos.';

  @override
  String get settings_latitude => 'Latitude';

  @override
  String get settings_longitude => 'Longitude';

  @override
  String get settings_contactSettings => 'Configurações de Contato';

  @override
  String get settings_contactSettingsSubtitle =>
      'Configurações para como os contatos são adicionados';

  @override
  String get settings_privacyMode => 'Modo de Privacidade';

  @override
  String get settings_privacyModeSubtitle =>
      'Esconder nome/localização em anúncios';

  @override
  String get settings_privacyModeToggle =>
      'Ative o modo de privacidade para ocultar seu nome e localização em anúncios.';

  @override
  String get settings_privacyModeEnabled => 'Modo de privacidade ativado';

  @override
  String get settings_privacyModeDisabled => 'Modo de privacidade desativado';

  @override
  String get settings_privacy => 'Configurações de Privacidade';

  @override
  String get settings_privacySubtitle => 'Controle o que é compartilhado.';

  @override
  String get settings_privacySettingsDescription =>
      'Escolha quais informações o seu dispositivo compartilha com os outros.';

  @override
  String get settings_denyAll => 'Negar todos';

  @override
  String get settings_allowByContact => 'Permitir por bandeiras de contato';

  @override
  String get settings_allowAll => 'Permitir todos';

  @override
  String get settings_telemetryBaseMode => 'Modo Base de Telemetria';

  @override
  String get settings_telemetryLocationMode =>
      'Modo de Localização de Telemetria';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Modo de Ambiente de Telemetria';

  @override
  String get settings_advertLocation => 'Localização do Anúncio';

  @override
  String get settings_advertLocationSubtitle =>
      'Incluir localização no anúncio';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Anúncio zero-hop automático na atualização do GPS';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Quando a localização GPS mudar, enviar um anúncio zero-hop (requer localização no anúncio).';

  @override
  String get settings_multiAck => 'Multi-ACKs';

  @override
  String get settings_telemetryModeUpdated => 'Modo de telemetria atualizado';

  @override
  String get settings_actions => 'Ações';

  @override
  String get settings_deleteAllPaths => 'Delete All Paths';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Clear all path data from contacts.';

  @override
  String get settings_sendAdvertisement => 'Enviar Publicidade';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Presença de transmissão agora';

  @override
  String get settings_advertisementSent => 'Anúncio enviado';

  @override
  String get settings_syncTime => 'Tempo de Sincronização';

  @override
  String get settings_syncTimeSubtitle =>
      'Definir o relógio do dispositivo para o horário do telefone';

  @override
  String get settings_timeSynchronized => 'Sincronizado com o tempo';

  @override
  String get settings_refreshContacts => 'Atualizar Contatos';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recarregar a lista de contatos do dispositivo';

  @override
  String get settings_rebootDevice => 'Reiniciar Dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Reiniciar o dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Tem certeza de que deseja reiniciar o dispositivo? Você será desconectado.';

  @override
  String get settings_debug => 'Depurar';

  @override
  String get settings_companionDebugLog => 'Registro de depuração auxiliar';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Comandos, respostas e dados brutos para protocolos BLE/TCP/USB';

  @override
  String get settings_appDebugLog => 'Log de Depuração do Aplicativo';

  @override
  String get settings_appDebugLogSubtitle =>
      'Mensagens de depuração do aplicativo';

  @override
  String get settings_about => 'Sobre';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => 'Projeto MeshCore de Código Aberto 2024';

  @override
  String get settings_aboutDescription =>
      'Um cliente Flutter de código aberto para dispositivos de rede mesh LoRa Core da MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Dados de elevação LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nome';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Estado';

  @override
  String get settings_infoBattery => 'Bateria';

  @override
  String get settings_infoPublicKey => 'Chave Pública';

  @override
  String get settings_infoContactsCount => 'Número de Contatos';

  @override
  String get settings_infoChannelCount => 'Número do Canal';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

  @override
  String get settings_presets => 'Configurações pré-definidas';

  @override
  String get settings_frequency => 'Frequência (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Frequência inválida (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Largura de banda';

  @override
  String get settings_spreadingFactor => 'Fator de Dispersão';

  @override
  String get settings_codingRate => 'Taxa de Codificação';

  @override
  String get settings_txPower => 'TX Potência (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Potência de TX inválida (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Repetição sem rede';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permita que este dispositivo repita pacotes de rede para outros dispositivos.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'A repetição fora da rede requer frequências de 433, 869 ou 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Erro: $message';
  }

  @override
  String get appSettings_title => 'Configurações do App';

  @override
  String get appSettings_appearance => 'Aparência';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Padrão do sistema';

  @override
  String get appSettings_themeLight => 'Luz';

  @override
  String get appSettings_themeDark => 'Escuro';

  @override
  String get appSettings_language => 'Idioma';

  @override
  String get appSettings_languageSystem => 'Padrão do sistema';

  @override
  String get appSettings_languageEn => 'Inglês';

  @override
  String get appSettings_languageFr => 'Francês';

  @override
  String get appSettings_languageEs => 'Espanhol';

  @override
  String get appSettings_languageDe => 'Alemão';

  @override
  String get appSettings_languagePl => 'Polonês';

  @override
  String get appSettings_languageSl => 'Esloveno';

  @override
  String get appSettings_languagePt => 'Português';

  @override
  String get appSettings_languageIt => 'Italiano';

  @override
  String get appSettings_languageZh => 'Chinês';

  @override
  String get appSettings_languageSv => 'Sueco';

  @override
  String get appSettings_languageNl => 'Holandês';

  @override
  String get appSettings_languageSk => 'Esloveno';

  @override
  String get appSettings_languageBg => 'Búlgaro';

  @override
  String get appSettings_languageRu => 'Russo';

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
      'Ativar rastreamento de mensagens';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostrar metadados detalhados de roteamento e tempo para as mensagens';

  @override
  String get appSettings_notifications => 'Notificações';

  @override
  String get appSettings_enableNotifications => 'Ativar Notificações';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Receber notificações para mensagens e anúncios';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permissão de notificação negada';

  @override
  String get appSettings_notificationsEnabled => 'Notificações ativadas';

  @override
  String get appSettings_notificationsDisabled => 'Notificações desativadas';

  @override
  String get appSettings_messageNotifications => 'Notificações de Mensagem';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostrar notificação ao receber novas mensagens';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notificações de Mensagens do Canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostrar notificação ao receber mensagens do canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notificações de Anúncios';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostrar notificação quando novos nós forem descobertos';

  @override
  String get appSettings_messaging => 'Mensagens';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Limpar Caminho em Tentativas Máximas';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Redefinir o caminho de contato após 5 tentativas de envio falhas';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Os caminhos serão limpos após 5 tentativas falhas.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Os caminhos não serão limpos automaticamente.';

  @override
  String get appSettings_autoRouteRotation => 'Rotação de Rota Automática';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Alternar entre os melhores caminhos e o modo inundação';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Rotação de roteamento automático habilitada';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Rotação de roteamento automático desativada';

  @override
  String get appSettings_maxRouteWeight => 'Peso Máximo da Rota';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Peso máximo que um determinado percurso pode acumular com entregas bem-sucedidas.';

  @override
  String get appSettings_initialRouteWeight => 'Peso Inicial da Rota';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Peso inicial para novos caminhos descobertos';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Aumento do peso para indicar sucesso';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Peso adicionado a um caminho após a entrega bem-sucedida.';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Redução do peso da falha';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Peso removido de um caminho após uma tentativa de entrega malsucedida.';

  @override
  String get appSettings_maxMessageRetries =>
      'Número máximo de tentativas de envio de mensagens';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Número de tentativas de reenvio antes de classificar uma mensagem como falha.';

  @override
  String get appSettings_battery => 'Bateria';

  @override
  String get appSettings_batteryChemistry => 'Química da Bateria';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Definir por dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Conecte-se a um dispositivo para escolher';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_batteryLipoHv => 'LiPo HV (3,0-4,35V)';

  @override
  String get appSettings_mapDisplay => 'Exibição do Mapa';

  @override
  String get appSettings_showRepeaters => 'Mostrar Repetidores';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Exibir nós de repetidor no mapa';

  @override
  String get appSettings_showChatNodes => 'Mostrar Nós de Chat';

  @override
  String get appSettings_showChatNodesSubtitle => 'Exibir nós de chat no mapa';

  @override
  String get appSettings_showOtherNodes => 'Mostrar Outros Nós';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Exibir outros tipos de nó no mapa';

  @override
  String get appSettings_timeFilter => 'Filtro de Tempo';

  @override
  String get appSettings_timeFilterShowAll => 'Mostrar todos os nós';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostrar nós das últimas $hours horas';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro de Tempo do Mapa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostrar nós descobertos dentro de:';

  @override
  String get appSettings_allTime => 'Todos os tempos';

  @override
  String get appSettings_lastHour => 'Última hora';

  @override
  String get appSettings_last6Hours => 'Últimos 6 horas';

  @override
  String get appSettings_last24Hours => 'Últimas 24 horas';

  @override
  String get appSettings_lastWeek => 'Da última semana';

  @override
  String get appSettings_rasterTileSource => 'Fonte de blocos raster';

  @override
  String get appSettings_stadiaEndpoint => 'Endpoint da Stadia';

  @override
  String get appSettings_stadiaApiKey => 'Chave da API Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Obrigatório para usar o Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Configurado: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Insira sua chave da API Stadia Maps. O aplicativo a usa para solicitações de blocos raster.';

  @override
  String get appSettings_offlineMapCache => 'Cache de Mapa Offline';

  @override
  String get appSettings_unitsTitle => 'Unidades';

  @override
  String get appSettings_unitsMetric => 'Métrico (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (ft/mi)';

  @override
  String get appSettings_noAreaSelected => 'Nenhuma área selecionada';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Área selecionada (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Depurar';

  @override
  String get appSettings_appDebugLogging =>
      'Rastreamento de Depuração do Aplicativo';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Registrar mensagens de depuração do aplicativo Log para solucionar problemas';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Log de depuração do aplicativo habilitado';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'O registro de depuração do aplicativo está desativado.';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_noContacts => 'Ainda não existem contatos.';

  @override
  String get contacts_contactsWillAppear =>
      'Os contatos serão exibidos quando os dispositivos anunciarem.';

  @override
  String get contacts_unread => 'Não lido';

  @override
  String get contacts_searchContactsNoNumber => 'Pesquisar Contatos...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Pesquisar contatos...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Pesquisar $number$str Favoritos...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Pesquisar $number$str Usuários...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Pesquisar $number$str Repetidores...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Pesquisar $number$str servidores de sala...';
  }

  @override
  String get contacts_noUnreadContacts => 'Sem contatos não lidos.';

  @override
  String get contacts_noContactsFound =>
      'Não foram encontrados contatos ou grupos.';

  @override
  String get contacts_deleteContact => 'Excluir Contato';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Remover $contactName dos contatos?';
  }

  @override
  String get contacts_manageRepeater => 'Gerenciar Repetidor';

  @override
  String get contacts_manageRoom => 'Gerenciar Servidor de Sala';

  @override
  String get contacts_roomLogin => 'Login no Quarto';

  @override
  String get contacts_openChat => 'Abrir Chat';

  @override
  String get contacts_editGroup => 'Editar Grupo';

  @override
  String get contacts_deleteGroup => 'Excluir Grupo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Remover $groupName?';
  }

  @override
  String get contacts_newGroup => 'Novo Grupo';

  @override
  String get contacts_moreOptions => 'Mais opções';

  @override
  String get contacts_searchOpen => 'Pesquisar contatos';

  @override
  String get contacts_searchClose => 'Pesquisa avançada';

  @override
  String get contacts_groupName => 'Nome do grupo';

  @override
  String get contacts_groupNameRequired => 'O nome do grupo é obrigatório.';

  @override
  String get contacts_groupNameReserved => 'Este nome de grupo está reservado';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'O grupo \"$name\" já existe';
  }

  @override
  String get contacts_filterContacts => 'Filtrar contatos...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Não existem contatos que correspondam ao seu filtro';

  @override
  String get contacts_noMembers => 'Nenhum membro';

  @override
  String get contacts_lastSeenNow => 'Última vez que foi visto agora';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Última vez que foi visto $minutes minutos atrás';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Última vez que foi visto há 1 hora.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Última vez visto $hours horas atrás';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Última vez que foi visto 1 dia atrás';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Última vez visto $days dias atrás';
  }

  @override
  String get contact_info => 'Informações de Contato';

  @override
  String get contact_settings => 'Configurações de Contato';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Visto pela última vez';

  @override
  String get contact_clearChat => 'Limpar Chat';

  @override
  String get contact_teleBase => 'Base de Telemetria';

  @override
  String get contact_teleBaseSubtitle =>
      'Permitir compartilhamento do nível da bateria e telemetria básica';

  @override
  String get contact_teleLoc => 'Localização de Telemetria';

  @override
  String get contact_teleLocSubtitle =>
      'Permitir compartilhamento de dados de localização';

  @override
  String get contact_teleEnv => 'Ambiente de Telemetria';

  @override
  String get contact_teleEnvSubtitle =>
      'Permitir compartilhamento de dados do sensor de ambiente';

  @override
  String get channels_title => 'Canais';

  @override
  String get channels_noChannelsConfigured => 'Nenhuma canalização configurada';

  @override
  String get channels_addPublicChannel => 'Adicionar Canal Público';

  @override
  String get channels_searchChannels => 'Pesquisar canais...';

  @override
  String get channels_noChannelsFound => 'Nenhum canal encontrado';

  @override
  String channels_channelIndex(int index) {
    return 'Canal $index';
  }

  @override
  String get channels_public => 'Público';

  @override
  String channels_via(String path) {
    return 'via $path';
  }

  @override
  String get channels_private => 'Privado';

  @override
  String get channels_editChannel => 'Editar canal';

  @override
  String get channels_muteChannel => 'Silenciar canal';

  @override
  String get channels_unmuteChannel => 'Ativar canal';

  @override
  String get channels_deleteChannel => 'Excluir canal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Excluir \"$name\"? Não pode ser desfeito.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Falha ao excluir o canal \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canal \"$name\" excluído';
  }

  @override
  String get channels_addChannel => 'Adicionar Canal';

  @override
  String get channels_channelIndexLabel => 'Índice do Canal';

  @override
  String get channels_channelName => 'Nome do Canal';

  @override
  String get channels_usePublicChannel => 'Usar Canal Público';

  @override
  String get channels_standardPublicPsk => 'PSK público padrão';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Gerar PSK aleatório';

  @override
  String get channels_enterChannelName => 'Por favor, insira um nome de canal';

  @override
  String get channels_pskMustBe32Hex =>
      'O PSK deve ter 32 caracteres hexadecimais.';

  @override
  String channels_channelAdded(String name) {
    return 'Canal \"$name\" adicionado';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Editar Canal $index';
  }

  @override
  String get channels_smazCompression => 'Compressão SMAZ';

  @override
  String get channels_cyr2latCompression => 'Compressão Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Substitui alguns caracteres cirílicos por caracteres latinos ao enviar.';

  @override
  String get channels_cyr2latSettingsHeading => 'Configuração do Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Lista de substituições';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Editar a configuração JSON de substituição de caracteres';

  @override
  String get channels_cyr2latSettingsDialogHint => 'Mapa de substituições JSON';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'JSON incorreto: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Canal \"$name\" atualizado';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Adicionar perfil Cyr2Lat';

  @override
  String get settings_cyr2latProfileName => 'Nome do perfil';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'O nome do perfil não pode estar vazio';

  @override
  String get settings_cyr2latProfileAdded => 'Perfil adicionado com sucesso';

  @override
  String get settings_cyr2latProfileUpdated => 'Perfil atualizado com sucesso';

  @override
  String get settings_cyr2latProfileEdit => 'Editar perfil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDelete => 'Eliminar perfil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDeleted => 'Perfil eliminado com sucesso';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Tem a certeza de que deseja eliminar o perfil \"$name\"?';
  }

  @override
  String get channels_publicChannelAdded => 'Canal público adicionado';

  @override
  String get channels_sortBy => 'Ordenar por';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'De A a Z';

  @override
  String get channels_sortLatestMessages => 'Últimas mensagens';

  @override
  String get channels_sortUnread => 'Não lido';

  @override
  String get channels_createPrivateChannel => 'Criar um Canal Privado';

  @override
  String get channels_createPrivateChannelDesc =>
      'Protegido com uma chave secreta.';

  @override
  String get channels_joinPrivateChannel => 'Junte-se a um Canal Privado';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Inserir uma chave secreta manualmente.';

  @override
  String get channels_joinPublicChannel => 'Junte-se ao Canal Público';

  @override
  String get channels_joinPublicChannelDesc =>
      'Qualquer pessoa pode entrar neste canal.';

  @override
  String get channels_joinHashtagChannel => 'Junte-se a um Canal com Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Qualquer pessoa pode participar de canais com hashtag.';

  @override
  String get channels_scanQrCode => 'Digitalizar um Código QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Em breve';

  @override
  String get channels_enterHashtag => 'Insira hashtag';

  @override
  String get channels_hashtagHint => 'ex. #equipe';

  @override
  String channels_regionSetTo(String region) {
    return 'Região: $region';
  }

  @override
  String get channels_regionNotSet => 'Região: nenhuma';

  @override
  String get channels_regionSelect_Title => 'Escolha uma região';

  @override
  String get channels_clearRegion => 'Região desimpedida';

  @override
  String get chat_noMessages => 'Ainda não existem mensagens.';

  @override
  String get chat_sendMessage => 'Enviar mensagem';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Enviar uma mensagem para $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Enviar uma mensagem para começar';

  @override
  String get chat_originalMessageNotFound => 'Mensagem original não encontrada';

  @override
  String chat_replyingTo(String name) {
    return 'Responder a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get chat_location => 'Localização';

  @override
  String get chat_typeMessage => 'Digite uma mensagem...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Mensagem muito longa (máximo $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Mensagem copiada';

  @override
  String get chat_messageDeleted => 'Mensagem excluída';

  @override
  String get chat_retryingMessage => 'Tentando novamente';

  @override
  String chat_retryCount(int current, int max) {
    return 'Tentar $current/$max';
  }

  @override
  String get chat_selectSendAction => 'Selecionar ação de envio';

  @override
  String get chat_sendGif => 'Enviar GIF';

  @override
  String get chat_sendImageLora => 'Enviar imagem via MeshCore';

  @override
  String get chat_imagePickFailed => 'Não consegui abrir essa imagem';

  @override
  String get chat_receivedGif => 'Recebi um GIF';

  @override
  String get chat_reply => 'Responder';

  @override
  String get chat_addReaction => 'Adicionar Reação';

  @override
  String get chat_me => 'Eu';

  @override
  String get reaction_report => 'Emoji Reactions';

  @override
  String get emojiCategorySmileys => 'Emojis';

  @override
  String get emojiCategoryGestures => 'Gestos';

  @override
  String get emojiCategoryHearts => 'Corações';

  @override
  String get emojiCategoryObjects => 'Objetos';

  @override
  String get gifPicker_title => 'Escolher um GIF';

  @override
  String get gifPicker_searchHint => 'Pesquisar GIFs...';

  @override
  String get gifPicker_poweredBy => 'Desenvolvido por GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nenhum GIF encontrado';

  @override
  String get gifPicker_failedLoad => 'Não foi possível carregar os GIFs';

  @override
  String get gifPicker_failedSearch => 'Falha na pesquisa de GIFs';

  @override
  String get gifPicker_noInternet => 'Sem conexão com a internet';

  @override
  String get debugLog_appTitle => 'Log de Depuração do Aplicativo';

  @override
  String get debugLog_bleTitle => 'Log de Depuração BLE';

  @override
  String get debugLog_copyLog => 'Copiar log';

  @override
  String get debugLog_clearLog => 'Limpar log';

  @override
  String get debugLog_copied => 'Log de depuração copiado';

  @override
  String get debugLog_bleCopied => 'Log BLE copiado';

  @override
  String get debugLog_noEntries => 'Ainda não existem logs de depuração.';

  @override
  String get debugLog_enableInSettings =>
      'Ativar o log de depuração do aplicativo nas configurações';

  @override
  String get debugLog_frames => 'Estruturas';

  @override
  String get debugLog_rawLogRx => 'Log Raw-RX';

  @override
  String get debugLog_noBleActivity => 'Ainda não há atividade BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Comprimento do Quadro: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Mensagem de Texto:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destino PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Carimbo: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Bandeiras: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tipo de Texto: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'Interface de Linha de Comando';

  @override
  String get debugFrame_textTypePlain => 'Simples';

  @override
  String debugFrame_text(String text) {
    return '- Texto: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Espaço Hexadecimal:';

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
  String get chat_removePath => 'Remover caminho';

  @override
  String get chat_noPathHistoryYet =>
      'Ainda não há histórico de caminhos.\nEnvie uma mensagem para descobrir caminhos.';

  @override
  String get chat_pathCleared =>
      'Caminho limpo. A próxima mensagem redescobrirá a rota.';

  @override
  String get chat_fullPath => 'Caminho Completo';

  @override
  String get routing_title => 'Rotas';

  @override
  String get routing_modeAuto => 'Carro';

  @override
  String get routing_modeFlood => 'Inundação';

  @override
  String get routing_modeManual => 'Manual';

  @override
  String get routing_modeAutoHint =>
      'Seleciona automaticamente o caminho mais conhecido, e, se nenhum caminho conhecido for encontrado, utiliza a estratégia de \"inundação\".';

  @override
  String get routing_modeFloodHint =>
      'Transmissão através de todos os repetidores. É a opção mais confiável, mas utiliza mais tempo de transmissão.';

  @override
  String get routing_modeManualHint =>
      'Sempre segue exatamente o caminho que você define.';

  @override
  String get routing_currentRoute => 'Rota atual';

  @override
  String get routing_directNoHops => 'Direto – sem saltos de repetidor';

  @override
  String get routing_noPathYet =>
      'Ainda não há um caminho definido. A mensagem continua a ser enviada até que uma rota seja encontrada.';

  @override
  String get routing_floodBroadcast =>
      'Transmissão através de todos os repetidores';

  @override
  String get routing_editPath => 'Editar caminho';

  @override
  String get routing_forgetPath => 'Esqueça o caminho';

  @override
  String get routing_knownPaths => 'Rotas conhecidas';

  @override
  String get routing_knownPathsHint =>
      'Toque em um caminho para alternar para ele.';

  @override
  String get routing_inUse => 'Em uso';

  @override
  String get routing_qualityStrong => 'Primeiro salto notável';

  @override
  String get routing_qualityGood => 'Primeiro salto bem-sucedido';

  @override
  String get routing_qualityFair => 'Primeira etapa bem-sucedida';

  @override
  String get routing_qualityWorked => 'Foi entregue';

  @override
  String get routing_qualityFlood =>
      'Informação obtida através de relatos generalizados.';

  @override
  String get routing_qualityUntested => 'Não testado';

  @override
  String routing_lastWorked(String when) {
    return 'worked $when';
  }

  @override
  String get routing_neverWorked => 'nunca confirmado';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes delivered, $failures failed';
  }

  @override
  String get routing_floodDelivery =>
      'Entrega em áreas afetadas por inundações';

  @override
  String get pathEditor_title => 'Criar Caminho';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count de 64 gramas de lúpulo';
  }

  @override
  String get pathEditor_noHops =>
      'Ainda não há lúpulos adicionados. Clique nos repetidores abaixo para adicioná-los na ordem desejada, ou salve sem adicionar lúpulos para enviar diretamente.';

  @override
  String get pathEditor_addHops => 'Adicione os lúpulos na seguinte ordem.';

  @override
  String get pathEditor_searchRepeaters => 'Encontrar repetidores';

  @override
  String get pathEditor_advancedHex => 'Avançado: caminho hexadecimal bruto';

  @override
  String get pathEditor_hexLabel => 'Prefixos hexadecimais';

  @override
  String get pathEditor_hexHelper =>
      'Dois caracteres hexadecimais por salto, separados por vírgulas.';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Inválido: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Máximo de 64 saltos';

  @override
  String get pathEditor_usePath => 'Utilize este caminho.';

  @override
  String get pathEditor_removeHop => 'Remova o lúpulo';

  @override
  String get pathEditor_unknownHop => 'Repetidor desconhecido';

  @override
  String get chat_pathSavedLocally =>
      'Salvo localmente. Conectar para sincronizar.';

  @override
  String get chat_pathDeviceConfirmed => 'Dispositivo confirmado.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Dispositivo ainda não confirmado.';

  @override
  String get chat_type => 'Digite';

  @override
  String get chat_path => 'Caminho';

  @override
  String get chat_publicKey => 'Chave Pública';

  @override
  String get chat_compressOutgoingMessages => 'Comprimir mensagens enviadas';

  @override
  String get chat_floodForced => 'Inundação (forçada)';

  @override
  String get chat_directForced => 'Direto (forçado)';

  @override
  String chat_hopsForced(int count) {
    return '$count saltos (forçado)';
  }

  @override
  String get chat_floodAuto => 'Inundação (automática)';

  @override
  String get chat_direct => 'Salvar';

  @override
  String get chat_poiShared => 'Ponto de Interesse Compartilhado';

  @override
  String chat_unread(int count) {
    return 'Não lido: $count';
  }

  @override
  String get chat_markAsUnread => 'Marcar como não lido';

  @override
  String get chat_newMessages => 'Novas mensagens';

  @override
  String get chat_openLink => 'Abrir link?';

  @override
  String get chat_openLinkConfirmation =>
      'Deseja abrir este link no seu navegador?';

  @override
  String get chat_open => 'Abrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Não foi possível abrir o link: $url';
  }

  @override
  String get chat_invalidLink => 'Formato de link inválido';

  @override
  String get map_title => 'Mapa de Nós';

  @override
  String get map_searchHint => 'Pesquisar por nome ou ID do nó';

  @override
  String get map_activity => 'Atividade';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Recente';

  @override
  String get map_stale => 'Vencido';

  @override
  String get map_visible => 'Visível';

  @override
  String get map_hidden => 'Escondido';

  @override
  String get map_centerOnNode => 'Centralizar no nó';

  @override
  String get map_details => 'Detalhes';

  @override
  String get map_noGps => 'Sem GPS';

  @override
  String get map_noResults => 'Nenhum nó encontrado';

  @override
  String get map_lineOfSight => 'Linha de visão';

  @override
  String get map_losScreenTitle => 'Linha de visão';

  @override
  String get map_noNodesWithLocation =>
      'Não existem nós com dados de localização.';

  @override
  String get map_nodesNeedGps =>
      'Os nós precisam partilhar as suas coordenadas GPS\npara aparecerem no mapa';

  @override
  String map_nodesCount(int count) {
    return 'Nós: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pinos: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repetidor';

  @override
  String get map_room => 'Quarto';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Gatilho (DM)';

  @override
  String get map_pinPrivate => 'Bloquear (Privado)';

  @override
  String get map_pinPublic => 'Pin (Público)';

  @override
  String get map_lastSeen => 'Última Visão';

  @override
  String get map_disconnectConfirm =>
      'Tem certeza de que deseja desconectar deste dispositivo?';

  @override
  String get map_from => 'De';

  @override
  String get map_source => 'Fonte';

  @override
  String get map_flags => 'Bandeiras';

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
  String get map_shareMarkerHere => 'Compartilhar marcador aqui';

  @override
  String get map_setAsMyLocation => 'Defina minha localização';

  @override
  String get map_pinLabel => 'Rótulo de marcador';

  @override
  String get map_label => 'Rótulo';

  @override
  String get map_pointOfInterest => 'Ponto de interesse';

  @override
  String get map_sendToContact => 'Enviar para o contato';

  @override
  String get map_sendToChannel => 'Enviar para o canal';

  @override
  String get map_noChannelsAvailable => 'Não existem canais disponíveis.';

  @override
  String get map_publicLocationShare => 'Compartilhar local público';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Você está prestes a compartilhar uma localização em $channelLabel. Este canal é público e qualquer pessoa com a PSK pode visualizá-lo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Conecte-se a um dispositivo para compartilhar marcadores';

  @override
  String get map_filterNodes => 'Filtrar Nós';

  @override
  String get map_nodeTypes => 'Tipos de Nó';

  @override
  String get map_chatNodes => 'Nós de Chat';

  @override
  String get map_repeaters => 'Repetidores';

  @override
  String get map_otherNodes => 'Outros Nós';

  @override
  String get map_showOverlaps => 'Sobreposições da Chave Repeater';

  @override
  String get map_keyPrefix => 'Prefixo Chave';

  @override
  String get map_filterByKeyPrefix => 'Filtrar por prefixo-chave';

  @override
  String get map_publicKeyPrefix => 'Prefixo de chave pública';

  @override
  String get map_markers => 'Marcadores';

  @override
  String get map_showSharedMarkers => 'Mostrar marcadores compartilhados';

  @override
  String get map_showGuessedLocations =>
      'Mostrar as localizações dos nós estimados';

  @override
  String get map_showDiscoveryContacts => 'Mostrar Contatos de Descoberta';

  @override
  String get map_guessedLocation => 'Localização estimada';

  @override
  String get map_lastSeenTime => 'Último Tempo de Visualização';

  @override
  String get map_sharedPin => 'Pin compartilhado';

  @override
  String get map_sharedAt => 'Compartilhado';

  @override
  String get map_joinRoom => 'Junte-se à Sala';

  @override
  String get map_manageRepeater => 'Gerenciar Repetidor';

  @override
  String get map_tapToAdd => 'Toque nos nós para adicioná-los ao caminho.';

  @override
  String get map_runTrace => 'Executar Traçado de Caminho';

  @override
  String get map_runTraceWithReturnPath => 'Retornar ao mesmo caminho.';

  @override
  String get map_removeLast => 'Remover Último';

  @override
  String get map_pathTraceCancelled => 'Rastreamento de caminho cancelado.';

  @override
  String get mapCache_title => 'Cache de Mapa Offline';

  @override
  String get mapCache_selectAreaFirst =>
      'Selecione uma área para armazenar em cache primeiro';

  @override
  String get mapCache_noTilesToDownload =>
      'Não há tiles para baixar para esta área.';

  @override
  String get mapCache_downloadTilesTitle => 'Baixar tiles';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Baixar $count tiles para uso offline?';
  }

  @override
  String get mapCache_downloadAction => 'Baixar';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Armazenados $count azulejos';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Tiles em cache ($downloaded) ($failed falhou)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Limpar cache offline';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Remover todas as telhas de mapa em cache?';

  @override
  String get mapCache_offlineCacheCleared => 'Cache offline limpa';

  @override
  String get mapCache_noAreaSelected => 'Nenhuma área selecionada';

  @override
  String get mapCache_cacheArea => 'Área de Cache';

  @override
  String get mapCache_useCurrentView => 'Usar a Visualização Atual';

  @override
  String get mapCache_zoomRange => 'Intervalo de Zoom';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Estimados azulejos: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Baixado $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Baixar Tiles';

  @override
  String get mapCache_clearCacheButton => 'Limpar Cache';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Downloads falhas: $count';
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
  String get time_justNow => 'Agora';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minutos atrás';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h atrás';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dias atrás';
  }

  @override
  String get time_hour => 'hora';

  @override
  String get time_hours => 'horas';

  @override
  String get time_day => 'dia';

  @override
  String get time_days => 'dias';

  @override
  String get time_week => 'semana';

  @override
  String get time_weeks => 'semanas';

  @override
  String get time_month => 'mês';

  @override
  String get time_months => 'meses';

  @override
  String get time_minutes => 'minutos';

  @override
  String get time_allTime => 'Todos os tempos';

  @override
  String get dialog_disconnect => 'Desconectar';

  @override
  String get dialog_disconnectConfirm =>
      'Tem certeza de que deseja desconectar deste dispositivo?';

  @override
  String get login_repeaterLogin => 'Login ao Repetidor';

  @override
  String get login_roomLogin => 'Login de Sala';

  @override
  String get login_password => 'Senha';

  @override
  String get login_enterPassword => 'Insira a senha';

  @override
  String get login_savePassword => 'Salvar senha';

  @override
  String get login_savePasswordSubtitle =>
      'A senha será armazenada com segurança neste dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Insira a senha do repetidor para acessar as configurações e o status.';

  @override
  String get login_roomDescription =>
      'Insira a senha da sala para acessar as configurações e o status.';

  @override
  String get login_routing => 'Rotas';

  @override
  String get login_routingMode => 'Modo de roteamento';

  @override
  String get login_autoUseSavedPath => 'Auto (usar caminho salvo)';

  @override
  String get login_forceFloodMode => 'Modo de Inundação Forçado';

  @override
  String get login_managePaths => 'Gerenciar Caminhos';

  @override
  String get login_login => 'Entrar';

  @override
  String login_attempt(int current, int max) {
    return 'Tentar $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Login falhou: $error';
  }

  @override
  String get login_failedMessage =>
      'Falha no login. A senha está incorreta ou o repetidor está inacessível.';

  @override
  String get common_reload => 'Recarregar';

  @override
  String get common_clear => 'Limpar';

  @override
  String get path_currentPathLabel => 'Caminho atual';

  @override
  String get path_noRepeatersFound =>
      'Não foram encontrados repetidores ou servidores de sala.';

  @override
  String get repeater_management => 'Gerenciamento de Repetidor';

  @override
  String get room_management => 'Gerenciamento de Servidor de Sala';

  @override
  String get repeater_guest => 'Informações sobre repetidores';

  @override
  String get room_guest => 'Informações do Servidor';

  @override
  String get repeater_managementTools => 'Ferramentas de Gerenciamento';

  @override
  String get repeater_guestTools => 'Ferramentas para hóspedes';

  @override
  String get repeater_status => 'Estado';

  @override
  String get repeater_statusSubtitle =>
      'Visualizar status do repetidor, estatísticas e vizinhos.';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Visualizar telemetria de sensores e estatísticas do sistema';

  @override
  String get repeater_cli => 'Interface de Linha de Comando';

  @override
  String get repeater_cliSubtitle => 'Enviar comandos ao repetidor';

  @override
  String get repeater_neighbors => 'Vizinhos';

  @override
  String get repeater_neighborsSubtitle => 'Visualizar vizinhos de salto zero.';

  @override
  String get repeater_settings => 'Configurações';

  @override
  String get repeater_settingsSubtitle => 'Configurar parâmetros do repetidor';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Sincronização do relógio após o login';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Enviar automaticamente a sincronização do \"relógio\" após um login bem-sucedido.';

  @override
  String get repeater_statusTitle => 'Status do Repetidor';

  @override
  String get repeater_routingMode => 'Modo de roteamento';

  @override
  String get repeater_refresh => 'Atualizar';

  @override
  String get repeater_statusRequestTimeout => 'Solicitação de status expirou.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Erro ao carregar o status: $error';
  }

  @override
  String get repeater_systemInformation => 'Informações do Sistema';

  @override
  String get repeater_battery => 'Bateria';

  @override
  String get repeater_clockAtLogin => 'Relógio (no login)';

  @override
  String get repeater_uptime => 'Disponibilidade';

  @override
  String get repeater_queueLength => 'Comprimento da Fila';

  @override
  String get repeater_debugFlags => 'Marcar Flags de Depuração';

  @override
  String get repeater_radioStatistics => 'Estatísticas de Rádio';

  @override
  String get repeater_lastRssi => 'Último RSSI';

  @override
  String get repeater_lastSnr => 'Último SNR';

  @override
  String get repeater_noiseFloor => 'Nível de Ruído';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_chanUtil => 'Utilização do canal';

  @override
  String get repeater_packetStatistics => 'Estatísticas de Pacote';

  @override
  String get repeater_sent => 'Enviado';

  @override
  String get repeater_received => 'Recebido';

  @override
  String get repeater_duplicates => 'Duplicatas';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dias ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundação: $flood, Direto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundação: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Inundação: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get repeater_settingsTitle => 'Configurações do Repetidor';

  @override
  String get repeater_basicSettings => 'Configurações Básicas';

  @override
  String get repeater_repeaterName => 'Nome do Repetidor';

  @override
  String get repeater_repeaterNameHelper => 'Exibir nome para este repetidor';

  @override
  String get repeater_adminPassword => 'Senha de Administrador';

  @override
  String get repeater_adminPasswordHelper => 'Acesso completo de senha';

  @override
  String get repeater_guestPassword => 'Senha de convidado';

  @override
  String get repeater_guestPasswordHelper =>
      'Acesso com senha de leitura somente';

  @override
  String get repeater_radioSettings => 'Configurações de Rádio';

  @override
  String get repeater_frequencyMhz => 'Frequência (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'Energia da TX';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Largura de banda';

  @override
  String get repeater_spreadingFactor => 'Fator de Dispersão';

  @override
  String get repeater_codingRate => 'Taxa de Codificação';

  @override
  String get repeater_locationSettings => 'Configurações de Localização';

  @override
  String get repeater_latitude => 'Latitude';

  @override
  String get repeater_latitudeHelper => 'Graus decimais (por exemplo, 37,7749)';

  @override
  String get repeater_longitude => 'Longitude';

  @override
  String get repeater_longitudeHelper =>
      'Graus decimais (por exemplo, -122,4194)';

  @override
  String get repeater_features => 'Recursos';

  @override
  String get repeater_packetForwarding => 'Encaminhamento de Pacotes';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Habilitar o repetidor para encaminhar pacotes';

  @override
  String get repeater_guestAccess => 'Acesso de Convidado';

  @override
  String get repeater_guestAccessSubtitle =>
      'Permitir acesso de convidado somente leitura';

  @override
  String get repeater_privacyMode => 'Modo de Privacidade';

  @override
  String get repeater_privacyModeSubtitle =>
      'Esconder nome/localização em anúncios';

  @override
  String get repeater_advertisementSettings => 'Configurações de Anúncios';

  @override
  String get repeater_localAdvertInterval => 'Intervalo de Anúncio Local';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervalo de Anúncio de Inundação';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervalo de Anúncio Criptografado';

  @override
  String get repeater_dangerZone => 'Zona de Perigo';

  @override
  String get repeater_rebootRepeater => 'Reiniciar Repetidor';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reiniciar o dispositivo repetidor';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Tem certeza de que deseja reiniciar este repetidor?';

  @override
  String get repeater_regenerateIdentityKey => 'Gerar Chave de Identidade';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Gerar nova chave pública/privada';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Isso gerará uma nova identidade para o repetidor. Continuar?';

  @override
  String get repeater_eraseFileSystem => 'Excluir Sistema de Arquivos';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatar o sistema de arquivos do repetidor';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'AVISO: Isso apagará todos os dados no repetidor. Isso não pode ser desfeito!';

  @override
  String get repeater_eraseSerialOnly =>
      'Apagar está disponível apenas via console serial.';

  @override
  String repeater_commandSent(String command) {
    return 'Comando enviado: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Erro ao enviar comando: $error';
  }

  @override
  String get repeater_confirm => 'Confirmar';

  @override
  String get repeater_settingsSaved => 'Configurações salvas com sucesso';

  @override
  String get repeater_rxGain => 'Aumento do ganho do RX';

  @override
  String get repeater_rxGainHelper =>
      'Maior sensibilidade, maior consumo de corrente (apenas para SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain => 'Reforçar o ganho do RX';

  @override
  String get repeater_multiAcks => 'Múltiplas respostas de confirmação';

  @override
  String get repeater_multiAcksSubtitle =>
      'Reconheça mensagens através de múltiplos caminhos para uma melhor entrega.';

  @override
  String get repeater_refreshMultiAcks => 'Reiniciar múltiplas confirmações';

  @override
  String get repeater_networkHealth => 'Saúde da rede';

  @override
  String get repeater_loopDetect => 'Detecção de loops';

  @override
  String get repeater_loopDetectHelper =>
      'Envie pacotes que pareçam ser loops de roteamento.';

  @override
  String get repeater_loopDetectOff => 'Desligado';

  @override
  String get repeater_loopDetectMinimal => 'Mínimo';

  @override
  String get repeater_loopDetectModerate => 'Moderado';

  @override
  String get repeater_loopDetectStrict => 'Rígido';

  @override
  String get repeater_dutyCycle => 'Ciclo de operação';

  @override
  String get repeater_dutyCycleHelper =>
      'Porcentagem máxima de tempo de transmissão';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Informações sobre o operador';

  @override
  String get repeater_ownerInfoHelper =>
      'Metadados públicos para este repetidor';

  @override
  String get repeater_refreshOwnerInfo => 'Atualizar informações do operador';

  @override
  String get repeater_floodMax =>
      'Número máximo de saltos em caso de inundação';

  @override
  String get repeater_floodMaxHelper =>
      'Número máximo de saltos que um pacote de inundação pode percorrer (0-64)';

  @override
  String get repeater_advancedSettings => 'Avançado';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Controles de ajuste para operadores experientes';

  @override
  String get repeater_pathHashMode => 'Modo de hash de caminho';

  @override
  String get repeater_pathHashModeHelper =>
      'Bytes usados para codificar o ID deste repetidor nas tags de caminho flood/detecção de loop. 0=1 byte (256 IDs, até 64 saltos), 1=2 bytes (65.000 IDs, até 32 saltos), 2=3 bytes (16 milhões de IDs, até 21 saltos). O firmware anterior à v1.14 sempre usava caminhos de 1 byte; v1.14 e versões mais recentes podem ser configuradas para caminhos de 2 ou 3 bytes.';

  @override
  String get repeater_keySettings => 'Alterar Chaves de Identidade';

  @override
  String get repeater_keySettingsSubtitle =>
      'Altere a chave pública/chave privada';

  @override
  String get repeater_prvKey => 'Chave privada';

  @override
  String get repeater_prvKeyHelper =>
      'Uma nova chave privada para o repetidor, uma string hexadecimal de 128 caracteres.';

  @override
  String get repeater_generatePrvKey => 'Gere um par de chaves aleatório';

  @override
  String get repeater_stopGeneratingPrvKey =>
      'Interrompa a busca por par de chaves';

  @override
  String get repeater_pubKey => 'Chave pública';

  @override
  String get repeater_pubKeyHelper =>
      'Esta é a chave pública que acompanha a chave privada gerada. Você não pode definir isso diretamente.';

  @override
  String get repeater_pubKeyPrefix => 'Prefixo desejado';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Encontre uma chave pública que comece com esses dígitos hexadecimais. Número esperado de tentativas: $tries.';
  }

  @override
  String get repeater_txDelay => 'Atraso na entrega em Flood, TX';

  @override
  String get repeater_txDelayHelper =>
      'Ajuste de espaçamento para tráfego de inundações, como um multiplicador do tempo de transmissão (0-2, padrão 0,5). Quanto maior, menos colisões, mas uma entrega mais lenta.';

  @override
  String get repeater_directTxDelay => 'Atraso direto no sinal TX';

  @override
  String get repeater_directTxDelayHelper =>
      'Intervalo de retransmissão para tráfego direto (não em enxame), como um multiplicador do tempo de transmissão do pacote (0-2, padrão 0,3).';

  @override
  String get repeater_intThresh => 'Limite de interferência';

  @override
  String get repeater_intThreshHelper =>
      'O limite é definido para o nível de ruído do rádio, de modo que ele rejeite interferências acima desse nível. 0 desativa – aumente apenas se você observar erros de RX em uma faixa de frequência com ruído.';

  @override
  String get repeater_agcResetInterval => 'Intervalo de reinicialização do AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Com que frequência redefinir o controle automático de ganho do rádio para recuperar de um estado em que o ganho está travado. Segundos, reduzidos a um múltiplo de 4. 0 desativa as redefinições periódicas.';

  @override
  String get repeater_actionsTitle => 'Ações';

  @override
  String get repeater_sendAdvert => 'Envie anúncio sobre inundações';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Transmita um anúncio sobre inundações pela rede.';

  @override
  String get repeater_sendAdvertZeroHop => 'Enviar anúncio sem intermediários';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Transmita um anúncio de um único salto (sem repetição).';

  @override
  String get repeater_clockSync => 'Sincronize o relógio agora';

  @override
  String get repeater_clockSyncSubtitle =>
      'Envie a hora do seu telefone para o repetidor.';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action succeeded';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action failed: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Configurações salvas — reinicie o repetidor para aplicar as alterações.';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Algumas configurações falharam: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Erro ao salvar as configurações: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Atualizar Configurações Básicas';

  @override
  String get repeater_refreshRadioSettings =>
      'Atualizar Configurações de Rádio';

  @override
  String get repeater_refreshTxPower => 'Atualizar TX de energia';

  @override
  String get repeater_refreshPacketForwarding =>
      'Atualizar Roteamento de Pacotes';

  @override
  String get repeater_refreshGuestAccess => 'Atualizar Acesso de Convidados';

  @override
  String get repeater_refreshPrivacyMode => 'Atualizar Modo Privacidade';

  @override
  String repeater_refreshed(String label) {
    return '$label atualizado';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Erro ao atualizar $label';
  }

  @override
  String get repeater_cliTitle => 'Repetidor CLI';

  @override
  String get repeater_debugNextCommand => 'Depurar Próximo Comando';

  @override
  String get repeater_commandHelp => 'Ajuda';

  @override
  String get repeater_clearHistory => 'Limpar Histórico';

  @override
  String get repeater_noCommandsSent => 'Ainda não foram enviadas comandos.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Digite um comando abaixo ou use comandos rápidos';

  @override
  String get repeater_enterCommandHint => 'Insira o comando...';

  @override
  String get repeater_previousCommand => 'Comando anterior';

  @override
  String get repeater_nextCommand => 'Próxima ação';

  @override
  String get repeater_enterCommandFirst => 'Insira um comando primeiro';

  @override
  String get repeater_cliCommandFrameTitle => 'Frame de Comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Erro: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Obter Nome';

  @override
  String get repeater_cliQuickGetRadio => 'Obter Rádio';

  @override
  String get repeater_cliQuickGetTx => 'Obter TX';

  @override
  String get repeater_cliQuickNeighbors => 'Vizinhos';

  @override
  String get repeater_cliQuickVersion => 'Versão';

  @override
  String get repeater_cliQuickAdvertise => 'Anunciar';

  @override
  String get repeater_cliQuickClock => 'Relógio';

  @override
  String get repeater_cliQuickClockSync => 'Sincronização do Relógio';

  @override
  String get repeater_cliQuickDiscovery => 'Descobrir Vizinhos';

  @override
  String get repeater_cliHelpAdvert => 'Envia um pacote de anúncios';

  @override
  String get repeater_cliHelpReboot =>
      'Reinicia o dispositivo. (note, você pode obter \'Timeout\' que é normal)';

  @override
  String get repeater_cliHelpClock =>
      'Exibe a hora atual de cada dispositivo, de acordo com o relógio do dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Define uma nova senha de administrador para o dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Mostra a versão do dispositivo e a data de construção do firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Reseta vários contadores de estatísticas para zero.';

  @override
  String get repeater_cliHelpSetAf => 'Define o fator de tempo de ar.';

  @override
  String get repeater_cliHelpSetTx =>
      'Define a potência de transmissão LoRa em dBm (redefinir para aplicar).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Habilita ou desabilita o papel do repetidor para este nó.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Servidor de sala) Se \'ligado\', então o login com senha em branco será permitido, mas não poderá Postar na sala. (apenas ler).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Define o número máximo de saltos de pacotes de inundação de entrada (se for >= máximo, o pacote não é encaminhado)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Define o Limite de Interferência (em dB). O valor padrão é 14. Defina como 0 para desativar a detecção de interferência de canal.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Define o intervalo para resetar o Controlador de Ganho Automático. Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Habilita ou desabilita a funcionalidade de \"double ACKs\".';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Define o intervalo do timer em minutos para enviar um pacote de anúncio local (sem salto). Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Define o intervalo do timer em horas para enviar um pacote de anúncio em massa. Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Define/atualiza a senha do convidado. (para repetidores, os logins de convidados podem enviar a solicitação \"Obter Estatísticas\")';

  @override
  String get repeater_cliHelpSetName => 'Define o nome do anúncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Define a latitude do mapa de anúncios. (graus decimais)';

  @override
  String get repeater_cliHelpSetLon =>
      'Define a longitude do mapa de anúncios. (graus decimais)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Define completamente novos parâmetros de rádio e salva nas preferências. Requer um comando \"reboot\" para aplicar.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Configurações (experimental) base (deve ser > 1 para efeito) para aplicar um pequeno atraso aos pacotes recebidos, com base na força do sinal/pontuação. Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Define um fator multiplicado com o tempo-em-ar para um pacote de modo de inundação e com um sistema de slot aleatório, para atrasar seu encaminhamento. (para diminuir a probabilidade de colisões)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Igual a txdelay, mas para aplicar um atraso aleatório à encaminhamento de pacotes em modo direto.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Ativar/Desativar ponte.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Definir atraso antes de retransmitir pacotes.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Escolha se a ponte retransmitirá pacotes recebidos ou pacotes transmitidos.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Definir a taxa de baud para as pontes rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Definir segredo de ponte para pontes espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Define um fator personalizado para ajustar a voltagem de bateria relatada (apenas suportado em placas selecionadas).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Define parâmetros de rádio temporários para o número especificado de minutos, revertendo para os parâmetros de rádio originais posteriormente. (não salva nas preferências).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica o ACL. Remove a entrada correspondente (pelo prefixo de pubkey) se \"permissions\" for zero. Adiciona uma nova entrada se o pubkey-hex for de comprimento total e não estiver atualmente no ACL. Atualiza a entrada por correspondência de prefixo de pubkey. Os bits de permissão variam conforme o papel do firmware, mas os 2 bits inferiores são: 0 (Guest), 1 (Read only), 2 (Read write), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Obtém tipo de ponte nenhum, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Inicia o registro de pacotes no sistema de arquivos.';

  @override
  String get repeater_cliHelpLogStop =>
      'Para interromper o registro de pacotes no sistema de arquivos.';

  @override
  String get repeater_cliHelpLogErase =>
      'Apaga os logs do pacote do sistema de arquivos.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mostra uma lista de outros nós de repetição ouvidos através de anúncios zero-hop. Cada linha é id-prefixo-hexadecimal:timestamp:snr-vezes-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Remove a primeira entrada correspondente (por prefixo de chave pública (hexadecimal)) da lista de vizinhos.';

  @override
  String get repeater_cliHelpRegion =>
      '(série apenas) Lista todas as regiões definidas e as permissões de inundação atuais.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: isto é uma invocação multi-comando especial. Cada comando subsequente é um nome de região (indentado com espaços para indicar a hierarquia pai, com um espaço mínimo). Terminado enviando uma linha em branco/comando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Procura região com o prefixo de nome dado (ou \"\\\" para o âmbito global). Responde com \"-> nome-região (nome-pai) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Adiciona ou atualiza uma definição de região com o nome fornecido.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Remove uma definição de região com o nome fornecido. (deve corresponder exatamente e não ter regiões filhas)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Define a permissão de \'F\'luido para a região especificada. (\'\' para o escopo global/legado)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Remove a permissão de \"F\"luido para a região especificada. (NOTA: neste momento NÃO é aconselhável usar isso no escopo global/legado!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Responde com a região \'home\' atual. (Observação aplicada em nenhum lugar ainda, reservado para o futuro)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Define a região \'casa\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persiste a lista/mapa de regiões para o armazenamento.';

  @override
  String get repeater_cliHelpGps =>
      'Mostra o status do GPS. Quando o GPS estiver desligado, responde apenas com \"off\", se estiver ligado, responde com \"on\", status, fix, contagem de satélites.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Alterna o estado de energia do GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincroniza o tempo do nó com o relógio GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Define a posição do nó para coordenadas GPS e salvar preferências.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Define a configuração de anúncio da localização do nó:\n- nenhum: não incluir a localização nos anúncios\n- compartilhar: compartilhar a localização GPS (do SensorManager)\n- preferências: anunciar a localização armazenada nas preferências';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Define a configuração do anúncio de localização.';

  @override
  String get repeater_commandsListTitle => 'Lista de Comandos';

  @override
  String get repeater_commandsListNote =>
      'NOTA: para os diversos comandos \"set...\", também existe um comando \"get...\".';

  @override
  String get repeater_general => 'Geral';

  @override
  String get repeater_settingsCategory => 'Configurações';

  @override
  String get repeater_bridge => 'Ponte';

  @override
  String get repeater_logging => 'Registrar';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vizinhos (apenas repetidor)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gerenciamento de Região (Apenas Repetidor)';

  @override
  String get repeater_regionNote =>
      'Os comandos de região foram introduzidos para gerenciar definições e permissões de região.';

  @override
  String get repeater_gpsManagement => 'Gerenciamento GPS';

  @override
  String get repeater_gpsNote =>
      'O comando GPS foi introduzido para gerenciar tópicos relacionados à localização.';

  @override
  String get repeater_getCategory => 'Obter valores';

  @override
  String get repeater_powerMgmt => 'Gerenciamento de energia';

  @override
  String get repeater_sensors => 'Sensores';

  @override
  String get repeater_cliHelpPowerOff =>
      'Desliga o dispositivo. (não se espera resposta)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Redefine o relógio para uma data conhecida e reinicia o dispositivo.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Envia um anúncio sem \"salto\" (apenas para vizinhos próximos).';

  @override
  String get repeater_cliHelpStartOta =>
      'Inicia uma atualização de firmware via rádio em placas compatíveis.';

  @override
  String get repeater_cliHelpTime =>
      'Define o relógio do dispositivo para os segundos da época Unix especificados. O relógio não pode retroceder.';

  @override
  String get repeater_cliHelpBoard =>
      'Indica o fabricante da placa / identificador de hardware.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Envia uma solicitação de descoberta de nós para os vizinhos próximos. (Apenas para repetidores)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Indica se o modo de economia de energia está ativado ou desativado.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Habilita ou desabilita o modo de economia de energia (quando disponível).';

  @override
  String get repeater_cliHelpErase =>
      '(Apenas para dispositivos) Formata o sistema de arquivos do dispositivo. Apaga todas as configurações e contatos.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Define o ciclo de transmissão máximo permitido como uma porcentagem (1-100). Ajusta internamente o fator de tempo de transmissão.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(Apenas para uso em série) Substitui a chave privada de identificação do dispositivo. É necessário reiniciar o dispositivo para aplicar a alteração. Gera uma nova chave pública.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Apenas para SX126x) Alterna o ganho amplificado do receptor (RX) para melhorar a sensibilidade em condições de corrente mais elevada.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Define a string com as informações de contato do proprietário, que será incluída nos anúncios. Utilize \'|\' para indicar novas linhas.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Define o modo de hash de caminho. 0 = modo legado, 1 = modo padrão, 2 = modo rigoroso. Afeta a forma como os caminhos de roteamento são correspondidos.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Define o nível de sensibilidade para a detecção de loops de roteamento: desligado, mínimo, moderado ou estrito.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Apenas para rádio) Define rapidamente a frequência. É necessário reiniciar o dispositivo. Recomenda-se usar a opção \"configurar rádio\" para definir todos os parâmetros do rádio.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Apenas para a ponte ESPNow) Define o canal Wi-Fi (1-14) utilizado pela ponte.';

  @override
  String get repeater_cliHelpGetName => 'Mostra o nome do nó configurado.';

  @override
  String get repeater_cliHelpGetRole =>
      'Mostra o papel do firmware (Repetidor, Servidor de Sala, etc.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Exibe a chave pública do dispositivo.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Apenas para uso em série) Exibe a chave privada do dispositivo. Trate-a como uma informação confidencial.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Indica se a função de encaminhamento de pacotes (função de repetidor) está ativada ou desativada.';

  @override
  String get repeater_cliHelpGetTx => 'Mostra a potência atual em dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Mostra a frequência de rádio configurada em MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Exibe todos os parâmetros de rádio: frequência, largura de banda, fator de espalhamento, taxa de codificação.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Apenas para SX126x) Mostra o estado do ganho amplificado do RX.';

  @override
  String get repeater_cliHelpGetAf =>
      'Mostra o fator de tempo de transmissão atual.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Mostra o ciclo de trabalho atual permitido em porcentagem.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Mostra o limite de interferência do canal em dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Mostra o intervalo de reinicialização do AGC em segundos.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Indica se o modo de confirmação dupla está ativado (1) ou desativado (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Indica se o acesso somente de leitura para os convidados está habilitado.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Indica o intervalo de publicidade local em minutos.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Mostra o intervalo de tempo da publicidade relacionada às inundações, em horas.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Mostra a senha de convidado configurada.';

  @override
  String get repeater_cliHelpGetLat => 'Mostra a latitude configurada.';

  @override
  String get repeater_cliHelpGetLon => 'Mostra a longitude configurada.';

  @override
  String get repeater_cliHelpGetRxDelay =>
      'Mostra o valor base do atraso de resposta.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Mostra o fator de atraso em modo de inundação.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Mostra o fator de atraso direto.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Mostra o número máximo de saltos devido às inundações.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Exibe a string de informações de contato do proprietário.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Mostra o modo de hash de caminho (0/1/2).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Demonstra a sensibilidade na detecção de loops.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Apenas para séries) Lista as entradas de controle de acesso em um repetidor.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Indica se a ponte está habilitada.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Mostra o atraso da ponte em milissegundos.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Indica se a ponte está enviando ou recebendo pacotes RX ou TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Apenas para ponte RS232) Exibe a taxa de baud da ponte.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Apenas para a ponte ESPNow) Exibe o canal WiFi da ponte.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Apenas para a ponte ESPNow) Exibe o segredo compartilhado pela ponte.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Apenas para NRF52) Exibe a versão do bootloader.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Mostra o multiplicador do ADC (escalonamento da tensão da bateria).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Indica se o sistema possui suporte para gerenciamento de energia.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Indica a fonte de energia atual: externa ou bateria.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Mostra as razões mais recentes para a reinicialização e desligamento.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Mostra a tensão da bateria no momento da inicialização, em milivolts (mV).';

  @override
  String get repeater_cliHelpSensorGet =>
      'Lê uma configuração de sensor personalizada através de uma chave.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Cria uma configuração personalizada para um sensor.';

  @override
  String get repeater_cliHelpSensorList =>
      'Lista todas as configurações de sensores personalizadas, organizadas em páginas a partir de um índice de início opcional.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Mostra o escopo de região padrão atual.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Define o escopo regional padrão. Use \"<null>\" para limpar.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Lista as regiões que permitem o tráfego em áreas de risco de inundações.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Lista as regiões que restringem o tráfego em áreas de risco de inundações.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Apenas para séries) Apresenta estatísticas em nível de pacotes.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Apenas para transmissões em série) Exibe estatísticas de rádio.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Apenas para dispositivos em série) Exibe estatísticas básicas do firmware.';

  @override
  String get telemetry_receivedData => 'Dados de Telemetria Recebidos';

  @override
  String get telemetry_requestTimeout =>
      'Solicitação de telemetria expirou o tempo.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Erro ao carregar a telemetria: $error';
  }

  @override
  String get telemetry_noData => 'Não estão disponíveis dados de telemetria.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Bateria';

  @override
  String get telemetry_voltageLabel => 'Tensão';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura do MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Atual';

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
  String get telemetry_digitalOutputLabel => 'Saída digital';

  @override
  String get telemetry_analogInputLabel => 'Entrada analógica';

  @override
  String get telemetry_analogOutputLabel => 'Saída analógica';

  @override
  String get telemetry_genericLabel => 'Sensor genérico';

  @override
  String get telemetry_luminosityLabel => 'Luminosidade';

  @override
  String get telemetry_presenceLabel => 'Presença';

  @override
  String get telemetry_humidityLabel => 'Humidade';

  @override
  String get telemetry_accelerometerLabel => 'Acelerómetro';

  @override
  String get telemetry_pressureLabel => 'Pressão';

  @override
  String get telemetry_altitudeLabel => 'Altitude';

  @override
  String get telemetry_frequencyLabel => 'Frequência';

  @override
  String get telemetry_percentageLabel => 'Percentagem';

  @override
  String get telemetry_concentrationLabel => 'Concentração';

  @override
  String get telemetry_powerLabel => 'Potência';

  @override
  String get telemetry_distanceLabel => 'Distância';

  @override
  String get telemetry_energyLabel => 'Energia';

  @override
  String get telemetry_directionLabel => 'Direção';

  @override
  String get telemetry_timeLabel => 'Hora';

  @override
  String get telemetry_gyrometerLabel => 'Girómetro';

  @override
  String get telemetry_colourLabel => 'Cor';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Interruptor';

  @override
  String get telemetry_polylineLabel => 'Polilinha';

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
  String get telemetry_autoFetchQuantity => 'Número de solicitações';

  @override
  String get telemetry_error => 'Não foi possível obter os dados';

  @override
  String get neighbors_receivedData => 'Dados dos Vizinhos Recebidos';

  @override
  String get neighbors_requestTimedOut =>
      'Vizinhos solicitam tempo limite esgotado.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Erro ao carregar vizinhos: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Repetidores Vizinhos';

  @override
  String get neighbors_noData => 'Não estão disponíveis dados de vizinhos.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '$pubkey Desconhecido';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Ouvido: $time atrás';
  }

  @override
  String get channelPath_title => 'Rótulo de Caminho de Pacote';

  @override
  String get channelPath_viewMap => 'Ver mapa';

  @override
  String get channelPath_otherObservedPaths => 'Outros Caminhos Observados';

  @override
  String get channelPath_repeaterHops => 'Saltos do Repetidor';

  @override
  String get channelPath_noHopDetails =>
      'Os detalhes do pacote não estão disponíveis.';

  @override
  String get channelPath_messageDetails => 'Detalhes da Mensagem';

  @override
  String get channelPath_senderLabel => 'Remetente';

  @override
  String get channelPath_timeLabel => 'Tempo';

  @override
  String get channelPath_repeatsLabel => 'Repete';

  @override
  String channelPath_pathLabel(int index) {
    return 'Caminho $index';
  }

  @override
  String get channelPath_observedLabel => 'Observado';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Rastreamento observado $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Não há dados de localização.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Desconhecido';

  @override
  String get channelPath_floodPath => 'Inundação';

  @override
  String get channelPath_directPath => 'Salvar';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 de $total saltos';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed de $total saltos';
  }

  @override
  String get channelPath_mapTitle => 'Mapa de Caminhos';

  @override
  String get channelPath_noRepeaterLocations =>
      'Não estão disponíveis localizações de repetidores para este caminho.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Caminho $index (Primário)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Caminho';

  @override
  String get channelPath_observedPathHeader => 'Rastreamento Observado';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Não estão disponíveis detalhes de voo para este pacote.';

  @override
  String get channelPath_unknownRepeater => 'Repetidor Desconhecido';

  @override
  String get community_title => 'Comunidade';

  @override
  String get community_create => 'Criar Comunidade';

  @override
  String get community_createDesc =>
      'Crie uma nova comunidade e compartilhe via código QR.';

  @override
  String get community_join => 'Junte-se';

  @override
  String get community_joinTitle => 'Junte-se à Comunidade';

  @override
  String community_joinConfirmation(String name) {
    return 'Você gostaria de se juntar à comunidade \"$name\"?';
  }

  @override
  String get community_scanQr => 'Digitalizar a QR Code da Comunidade';

  @override
  String get community_scanInstructions =>
      'Aponte a câmera para um código QR da comunidade';

  @override
  String get community_showQr => 'Mostrar Código QR';

  @override
  String get community_publicChannel => 'Comunidade Pública';

  @override
  String get community_hashtagChannel => 'Hashtag da Comunidade';

  @override
  String get community_name => 'Nome da Comunidade';

  @override
  String get community_enterName => 'Insira o nome da comunidade';

  @override
  String community_created(String name) {
    return 'Comunidade \"$name\" criada';
  }

  @override
  String community_joined(String name) {
    return 'Juntou-se à comunidade \"$name\"';
  }

  @override
  String get community_qrTitle => 'Partilhar Comunidade';

  @override
  String community_qrInstructions(String name) {
    return 'Escanear este código QR para juntar-se a $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Os canais de hashtag da comunidade só podem ser acessados por membros da comunidade';

  @override
  String get community_invalidQrCode => 'Código QR da comunidade inválido';

  @override
  String get community_alreadyMember => 'Já é Membro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Você já é membro de \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Adicionar Canal Público da Comunidade';

  @override
  String get community_addPublicChannelHint =>
      'Adicionar automaticamente o canal público para esta comunidade';

  @override
  String get community_noCommunities =>
      'Ainda não foram adicionadas comunidades.';

  @override
  String get community_scanOrCreate =>
      'Escaneie um código QR ou crie uma comunidade para começar.';

  @override
  String get community_manageCommunities => 'Gerenciar Comunidades';

  @override
  String get community_delete => 'Deixar Comunidade';

  @override
  String community_deleteConfirm(String name) {
    return 'Sair de \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Isso também excluirá $count canal/canais e suas mensagens.';
  }

  @override
  String community_deleted(String name) {
    return 'Saiu da comunidade \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerar Senha Segura';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerar a chave secreta para \"$name\"? Todos os membros precisarão escanear o novo código QR para continuar a comunicação.';
  }

  @override
  String get community_regenerate => 'Regenerar';

  @override
  String community_secretRegenerated(String name) {
    return 'Senha secreta regenerada para \"$name\"';
  }

  @override
  String get community_updateSecret => 'Atualizar Segredo';

  @override
  String community_secretUpdated(String name) {
    return 'Segredo atualizado para \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scanar o novo código QR para atualizar o segredo para \"$name\"\n\n\n+++++';
  }

  @override
  String get community_addHashtagChannel => 'Adicionar Hashtag da Comunidade';

  @override
  String get community_addHashtagChannelDesc =>
      'Adicionar um canal de hashtag para esta comunidade';

  @override
  String get community_selectCommunity => 'Selecione Comunidade';

  @override
  String get community_regularHashtag => 'Hashtag Regular';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag público (qualquer pessoa pode participar)';

  @override
  String get community_communityHashtag => 'Hashtag da Comunidade';

  @override
  String get community_communityHashtagDesc =>
      'Apenas para membros da comunidade';

  @override
  String community_forCommunity(String name) {
    return 'Para $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrar e ordenar';

  @override
  String get listFilter_sortBy => 'Ordenar por';

  @override
  String get listFilter_latestMessages => 'Últimas mensagens';

  @override
  String get listFilter_heardRecently => 'Ouvido recentemente';

  @override
  String get listFilter_az => 'De A a Z';

  @override
  String get listFilter_filters => 'Filtros';

  @override
  String get listFilter_all => 'Tudo';

  @override
  String get listFilter_favorites => 'Favoritos';

  @override
  String get listFilter_addToFavorites => 'Adicionar aos favoritos';

  @override
  String get listFilter_removeFromFavorites => 'Remover da lista de favoritos';

  @override
  String get listFilter_users => 'Usuários';

  @override
  String get listFilter_repeaters => 'Repetidores';

  @override
  String get listFilter_roomServers => 'Servidores de sala';

  @override
  String get listFilter_unreadOnly => 'Apenas não lido';

  @override
  String get listFilter_newGroup => 'Novo grupo';

  @override
  String get pathTrace_you => 'Você';

  @override
  String get pathTrace_failed => 'Falha no rastreamento de caminho.';

  @override
  String get pathTrace_notAvailable => 'Traçado de caminho não disponível.';

  @override
  String get pathTrace_refreshTooltip => 'Atualizar Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Um ou mais dos lúpulos estão sem localização!';

  @override
  String get pathTrace_clearTooltip => 'Limpar caminho';

  @override
  String get losSelectStartEnd => 'Selecione nós iniciais e finais para LOS.';

  @override
  String losRunFailed(String error) {
    return 'Falha na verificação da linha de visão: $error';
  }

  @override
  String get losClearAllPoints => 'Limpe todos os pontos';

  @override
  String get losRunToViewElevationProfile =>
      'Execute o LOS para visualizar o perfil de elevação';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Toque nos nós ou mantenha pressionado o mapa para obter pontos personalizados';

  @override
  String get losShowDisplayNodes => 'Mostrar nós de exibição';

  @override
  String get losCustomPoints => 'Pontos personalizados';

  @override
  String losCustomPointLabel(int index) {
    return '$index personalizado';
  }

  @override
  String get losPointA => 'Ponto A';

  @override
  String get losPointB => 'Ponto B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Executar LOS';

  @override
  String get losNoElevationData => 'Sem dados de elevação';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, limpar LOS, liberação mínima $clearance $heightUnit';
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
  String get losStatusChecking => 'LOS: verificando...';

  @override
  String get losStatusNoData => 'LOS: sem dados';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total limpo, $blocked bloqueado, $unknown desconhecido';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Dados de elevação indisponíveis para uma ou mais amostras.';

  @override
  String get losErrorInvalidInput =>
      'Dados de pontos/elevação inválidos para cálculo de LOS.';

  @override
  String get losRenameCustomPoint => 'Renomear ponto personalizado';

  @override
  String get losPointName => 'Nome do ponto';

  @override
  String get losShowPanelTooltip => 'Mostrar painel LOS';

  @override
  String get losHidePanelTooltip => 'Ocultar painel LOS';

  @override
  String get losElevationAttribution =>
      'Dados de elevação: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Horizonte de rádio';

  @override
  String get losLegendLosBeam => 'Linha de visada';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losBlockedSpotsTitle => 'Locais ocupados';

  @override
  String get losBlockedSpotsHint =>
      'Toque em um ponto bloqueado para destacá-lo no mapa.';

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
  String get losSelectedObstructionTitle => 'Obstrução selecionada';

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
  String get losFrequencyLabel => 'Frequência';

  @override
  String get losFrequencyInfoTooltip => 'Ver detalhes do cálculo';

  @override
  String get losFrequencyDialogTitle => 'Cálculo do horizonte de rádio';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Começando em k=$baselineK em $baselineFreq MHz, o cálculo ajusta o fator k para a banda atual de $frequencyMHz MHz, que define o limite do horizonte de rádio curvo.';
  }

  @override
  String get contacts_pathTrace => 'Traçado de Caminho';

  @override
  String get contacts_ping => 'Pingar';

  @override
  String get contacts_repeaterPathTrace => 'Traçar caminho para repetidor';

  @override
  String get contacts_repeaterPing => 'Pingar repetidor';

  @override
  String get contacts_roomPathTrace => 'Traçar caminho para o servidor da sala';

  @override
  String get contacts_roomPing => 'Pingar servidor da sala';

  @override
  String get contacts_chatTraceRoute => 'Rastrear rota do caminho';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Rastrear rota para $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Área de Transferência Está Vazia.';

  @override
  String get contacts_invalidAdvertFormat => 'Dados de Contato Inválidos';

  @override
  String get contacts_contactImported => 'Contato foi importado.';

  @override
  String get contacts_contactImportFailed => 'Contato falhou ao ser importado.';

  @override
  String get contacts_zeroHopAdvert => 'Anúncio Zero Hop';

  @override
  String get contacts_floodAdvert => 'Anúncio de Inundação';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Copiar Anúncio para Área de Transferência';

  @override
  String get contacts_addContactFromClipboard =>
      'Adicionar Contato da Área de Transferência';

  @override
  String get contacts_ShareContact =>
      'Copiar contato para Área de Transferência';

  @override
  String get contacts_ShareContactZeroHop => 'Compartilhar contato por anúncio';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Enviou contato por anúncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed => 'Falha ao enviar contato.';

  @override
  String get contacts_contactAdvertCopied =>
      'Anúncio copiado para a Área de Transferência.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Cópia do anúncio para a Área de Transferência falhou.';

  @override
  String get notification_activityTitle => 'Atividade MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensagens',
      one: 'mensagem',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensagens de canal',
      one: 'mensagem de canal',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'novos nós',
      one: 'novo nó',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Novo $contactType descoberto';
  }

  @override
  String get notification_receivedNewMessage => 'Nova mensagem recebida';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportar repetidores / servidor de sala para GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporta repetidores / roomserver com localização para arquivo GPX.';

  @override
  String get settings_gpxExportContacts => 'Exportar companheiros para GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporta companheiros com uma localização para um arquivo GPX.';

  @override
  String get settings_gpxExportAll => 'Exportar todos os contatos para GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporta todos os contatos com uma localização para um arquivo GPX.';

  @override
  String get settings_gpxExportSuccess => 'Arquivo GPX exportado com sucesso.';

  @override
  String get settings_gpxExportNoContacts => 'Nenhum contato para exportar.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Não suportado no seu dispositivo/SO';

  @override
  String get settings_gpxExportError => 'Ocorreu um erro ao exportar.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Localizações do servidor de repetidor e sala';

  @override
  String get settings_gpxExportChat => 'Localizações de companheiros';

  @override
  String get settings_gpxExportAllContacts => 'Todos os locais de contatos';

  @override
  String get settings_gpxExportShareText =>
      'Dados do mapa exportados do meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open exportação de dados de mapa GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Repetidores Próximos';

  @override
  String get snrIndicator_lastSeen => 'Visto pela última vez';

  @override
  String get contactsSettings_title => 'Configurações de contatos';

  @override
  String get contactsSettings_autoAddTitle => 'Descoberta Automática';

  @override
  String get contactsSettings_otherTitle =>
      'Outras configurações relacionadas a contatos';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Adicionar usuários automaticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Permitir que o companheiro adicione automaticamente os usuários descobertos.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Adicionar repetidores automaticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Permitir que o companheiro adicione automaticamente os repetidores descobertos.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Adicionar automaticamente servidores de sala';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Permitir que o companheiro adicione automaticamente os servidores de salas descobertos.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Adicionar sensores automaticamente';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Permitir que o companheiro adicione automaticamente sensores descobertos.';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Sobrescrever o Mais Antigo';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Quando a lista de contatos estiver cheia, o contato mais antigo não favoritado será substituído.';

  @override
  String get discoveredContacts_Title => 'Contatos Descobertos';

  @override
  String get discoveredContacts_noMatching => 'Nenhum contato correspondente';

  @override
  String get discoveredContacts_searchHint => 'Pesquisar contatos descobertos';

  @override
  String get discoveredContacts_contactAdded => 'Contato adicionado';

  @override
  String get discoveredContacts_addContact => 'Adicionar Contato';

  @override
  String get discoveredContacts_copyContact =>
      'Copiar Contato para a área de transferência';

  @override
  String get discoveredContacts_deleteContact => 'Excluir Contato';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Excluir Todos os Contatos Descobertos';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Tem certeza de que deseja excluir todos os contatos descobertos?';

  @override
  String get chat_sendCooldown =>
      'Por favor, aguarde um momento antes de reenviar.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Vá para a mensagem mais antiga não lida';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Ao abrir uma conversa com mensagens não lidas, role para a primeira mensagem não lida, em vez da mais recente.';

  @override
  String get appSettings_languageHu => 'Húngaro';

  @override
  String get appSettings_languageJa => 'Japonês';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_tooltip => 'Estatísticas de rádio e malha';

  @override
  String get radioStats_screenTitle => 'Estatísticas de rádio';

  @override
  String get radioStats_notConnected =>
      'Conecte-se a um dispositivo para visualizar estatísticas de rádio.';

  @override
  String get radioStats_firmwareTooOld =>
      'As estatísticas de rádio exigem o firmware v8 ou uma versão mais recente.';

  @override
  String get radioStats_waiting => 'Aguardando dados…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Nível de ruído: $noiseDbm dBm';
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
    return 'Tempo de transmissão da TX (total): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tempo de uso do RX (total): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Nível de ruído (dBm) em amostras recentes.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Nível de ruído: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Obtendo estatísticas de rádio…';

  @override
  String get radioStats_settingsTile => 'Estatísticas de rádio';

  @override
  String get radioStats_settingsSubtitle =>
      'Nível de ruído, RSSI, SNR e tempo de transmissão';

  @override
  String get translation_title => 'Tradução';

  @override
  String get imageMessages_enableTitle => 'Mensagens de imagem';

  @override
  String get imageMessages_enableSubtitle =>
      'Envie as imagens pela malha. Requer o download de um modelo de imagem único.';

  @override
  String get imageMessages_modelSectionTitle => 'Modelo de imagem';

  @override
  String get imageMessages_downloadModel => 'Download';

  @override
  String get imageMessages_cancelDownload => 'Cancelar';

  @override
  String get imageMessages_removeModel => 'Remover modelo';

  @override
  String get imageMessages_modelReady => 'Pronto';

  @override
  String get imageMessages_modelNotPublished =>
      'Ainda não publicado — esta versão não pode baixá-lo.';

  @override
  String get imageMessages_downloadFailed =>
      'O modelo de imagem não pôde ser baixado.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Processar imagens automaticamente';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Reconstrua cada imagem assim que ela chegar. Utiliza cerca de 2 GB de memória por segundo; dispense a reconstrução com um toque.';

  @override
  String get translation_enableTitle => 'Ativar a tradução';

  @override
  String get translation_enableSubtitle =>
      'Traduzir mensagens recebidas e permitir a tradução antes do envio.';

  @override
  String get translation_composerTitle => 'Traduza antes de enviar';

  @override
  String get translation_composerSubtitle =>
      'Controla o estado padrão do ícone de tradução do compositor.';

  @override
  String get translation_autoIncomingTitle =>
      'Traduzir mensagens automaticamente';

  @override
  String get translation_autoIncomingSubtitle =>
      'Traduz automaticamente mensagens para notificações e para chats ou canais.';

  @override
  String get translation_translateMessage => 'Traduzir mensagem';

  @override
  String get translation_targetLanguage => 'Língua-alvo';

  @override
  String get translation_useAppLanguage => 'Utilize o idioma da aplicação';

  @override
  String get translation_downloadedModelLabel => 'Modelo baixado';

  @override
  String get translation_presetModelLabel =>
      'Modelo pré-definido da Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL do modelo manual';

  @override
  String get translation_downloadModel => 'Baixar modelo';

  @override
  String get translation_downloading => 'Baixando...';

  @override
  String get translation_working => 'Trabalhando...';

  @override
  String get translation_stop => 'Pare';

  @override
  String get translation_mergingChunks =>
      'Combinando os fragmentos baixados em um único arquivo...';

  @override
  String get translation_downloadedModels => 'Modelos baixados';

  @override
  String get translation_deleteModel => 'Excluir modelo';

  @override
  String get translation_modelDownloaded => 'Modelo de tradução baixado.';

  @override
  String get translation_downloadStopped => 'Download interrompido.';

  @override
  String translation_downloadFailed(String error) {
    return 'Falha na descarga: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Insira primeiro a URL do modelo.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostrar PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Ocultar PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN de emparelhamento Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Insira o PIN para $deviceName (deixe em branco se não houver).';
  }

  @override
  String get translation_messageTranslation => 'Tradução da mensagem';

  @override
  String get translation_translateBeforeSending => 'Traduzir antes de enviar';

  @override
  String get translation_composerEnabledHint =>
      'As mensagens serão traduzidas antes de serem enviadas.';

  @override
  String get translation_composerDisabledHint =>
      'Envie mensagens no idioma original, conforme digitado.';

  @override
  String translation_translateTo(String language) {
    return 'Traduzir para $language';
  }

  @override
  String get translation_translationOptions => 'Opções de tradução';

  @override
  String get translation_systemLanguage => 'Idioma do sistema';

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
  String get map_zoomIn => 'Ampliar';

  @override
  String get map_zoomOut => 'Ampliar';

  @override
  String get map_centerMap => 'Mapa do centro';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'O Web Bluetooth requer um navegador Chromium.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS confirmado';

  @override
  String get pathTrace_legendInferred => 'Posição inferida';

  @override
  String get pathMap_viewSingle => 'Único';

  @override
  String get pathMap_viewCombined => 'Combinado';

  @override
  String get pathMap_play => 'Reproduzir';

  @override
  String get pathMap_pause => 'Pausa';

  @override
  String get pathMap_replay => 'Repetir';

  @override
  String get pathMap_stepBack => 'Salto anterior';

  @override
  String get pathMap_stepForward => 'Próximo salto';

  @override
  String get pathMap_animationOn => 'Exibir animação do pacote';

  @override
  String get pathMap_animationOff => 'Ocultar a animação do pacote';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Salto $current de $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Caminhos observados: $count';
  }

  @override
  String get pathMap_primary => 'Primário';

  @override
  String pathMap_alternate(int index) {
    return 'Alt $index';
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
  String get pathMap_legendShared => 'Segmento compartilhado';

  @override
  String get pathMap_legendEstimated => 'Segmento estimado';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Utilizado em $count caminhos';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saltos não têm localização — o caminho mostrado é parcial',
      one: '1 salto não tem localização — o caminho mostrado é parcial',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Mostrar tudo';

  @override
  String get pathMap_hidePath => 'Esconder caminho';

  @override
  String get pathMap_showPath => 'Mostrar o caminho';

  @override
  String get pathMap_collapsePanel => 'Recolher painel';

  @override
  String get pathMap_expandPanel => 'Expandir painel';

  @override
  String get pathMap_noLocation => 'Sem localização';

  @override
  String get pathMap_followPacket => 'Fixar vista no pacote';

  @override
  String get pathMap_unfollowPacket => 'Liberar vista do pacote';

  @override
  String get imageSend_title => 'Enviar imagem';

  @override
  String get imageSend_cropNote =>
      'Redimensionado para 512 × 512 · a proporção de aspecto não foi preservada';

  @override
  String get imageSend_originalSize => 'Texto Original';

  @override
  String get imageSend_onAirSize => 'Ao ar';

  @override
  String get imageSend_quality => 'Qualidade';

  @override
  String get imageSend_qualityStandard => 'Padrão';

  @override
  String get imageSend_qualityHigh => 'Alto';

  @override
  String get imageSend_packetsLabel => 'Pacotes';

  @override
  String get imageSend_airtimeLabel => 'Tempo em transmissão';

  @override
  String get imageSend_sizeLabel => 'Carga útil';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pacotes',
      one: 'pacote',
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
      'Configurações de rádio desconhecidas';

  @override
  String get imageSend_radioUnknownBody =>
      'Conecte-se a um dispositivo para que o horário de transmissão possa ser calculado.';

  @override
  String get imageSend_longSendTitle => 'Transmissão longa';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Isso manterá o canal por cerca de $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Roteamento de inundação: cada repetidor na faixa retransmite cada pacote, fazendo com que o canal permaneça ocupado por mais tempo do que isso.';

  @override
  String get imageSend_parityTitle => 'Pacote de recuperação';

  @override
  String get imageSend_paritySubtitle =>
      'Um pacote extra. As mensagens em grupo não são reconhecidas, assim permitindo que o destinatário reconstrua a imagem caso um pacote seja perdido.';

  @override
  String get imageSend_send => 'Enviar';

  @override
  String get imageSend_cancel => 'Cancelar';

  @override
  String get imageSend_encodeFailed => 'Esta imagem não pode ser codificada.';

  @override
  String get imageSend_codecDownloading =>
      'O modelo de imagem ainda está baixando.';

  @override
  String get imageSend_codecUnavailable =>
      'O envio de imagem não está disponível neste dispositivo.';

  @override
  String get imageSend_codecDisabled =>
      'As mensagens de imagem estão desativadas nas configurações.';

  @override
  String get imageSend_deviceUnsupported =>
      'Este rádio não pode enviar pacotes de imagem. Conecte um dispositivo com firmware companheiro versão 13 ou superior.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'As imagens viajam como dados em grupo, portanto, só podem ser enviadas para um canal — não em mensagem direta.';

  @override
  String get imageSend_tooLarge =>
      'Essa imagem foi codificada em mais pacotes do que o formato de malha permite.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pacotes',
      one: 'pacote',
    );
    return 'Imagem enviada como $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'A imagem não pôde ser enviada: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Envio da imagem — pacote $sent de $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Nó $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$received de $total pacotes';
  }

  @override
  String get receivedImage_queued => 'Aguardando para decodificar';

  @override
  String get receivedImage_tapToDecode => 'Toque para decodificar';

  @override
  String get receivedImage_decoding => 'Reconstruindo… cerca de 1 segundo';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Imagem incompleta — $received de $total pacotes chegaram';
  }

  @override
  String get receivedImage_corrupt => 'A imagem não pôde ser reconstruída';

  @override
  String get receivedImage_decoderMissing =>
      'Imagem recebida — decodificação de imagem incorreta';

  @override
  String get receivedImage_evicted => 'Imagem não armazenada';

  @override
  String get receivedImage_retry => 'Tente novamente';

  @override
  String get receivedImage_decodeAgain => 'Decodifique novamente';

  @override
  String get receivedImage_openSettings => 'Configurar';

  @override
  String get receivedImage_tapToProcess => 'Toque para processar';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'pacotes',
      one: 'pacote',
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
