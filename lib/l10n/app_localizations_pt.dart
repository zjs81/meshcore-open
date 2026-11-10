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
  String get nav_contacts => 'Contatos';

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
  String get common_done => 'Concluído';

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
  String get messageStatus_failedChannel =>
      'O seu rádio não conseguiu enviar esta mensagem.';

  @override
  String messageStatus_resending(int resends, int maxResends) {
    return 'Ainda não foi ouvido por repetidores suficientes. Reenviado $resends de $maxResends vezes.';
  }

  @override
  String messageStatus_hopsNotReached(int hops, int required) {
    return 'Enviado, mas ouvido de volta por apenas $hops de $required repetidores. Pode ter chegado mais longe do que o seu rádio consegue ouvir.';
  }

  @override
  String get messageStatus_sentChannel =>
      'Enviado. Os canais não confirmam a entrega, portanto isto significa apenas que o seu rádio o enviou.';

  @override
  String get messageStatus_sentDirect =>
      'Enviado. À espera da confirmação do contato.';

  @override
  String messageStatus_heardRepeatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: 'uma vez',
    );
    return 'Ouvido $_temp0. Os repetidores próximos repassaram-no.';
  }

  @override
  String get urlImage_enable => 'Ativar imagens de URL';

  @override
  String get urlImage_possible =>
      'Possível imagem de URL; ative-a em Configurações.';

  @override
  String get urlImage_disabledInAppSettings =>
      'Desativado nas configurações do app';

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
  String get scanner_scan => 'Escanear';

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
  String get scanner_getNodeTitle => 'Precisa de um novo nó?';

  @override
  String get scanner_getNodeBody =>
      'Do tamanho de uma carteira, roda MeshCore, GPS dual-band, à prova d\'água, bateria para 5 dias.';

  @override
  String get scanner_getNodeAction => 'Compre aqui';

  @override
  String get scanner_getNodeDisclosure =>
      'Link de afiliado: cada compra apoia o MeshCore Open.';

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
  String get settings_export => 'Exportar';

  @override
  String get settings_exportSubtitle =>
      'Exportar contatos e repetidores como GPX';

  @override
  String get backupRestore_title => 'Backup e restauração';

  @override
  String get backupRestore_subtitle =>
      'Salve ou restaure dados do app e configurações do rádio';

  @override
  String get backupRestore_import => 'Importar';

  @override
  String get backupRestore_selectImportFile => 'Importar arquivo';

  @override
  String get backupRestore_password => 'Senha (opcional)';

  @override
  String get backupRestore_passwordHelp =>
      'Uma senha criptografa o arquivo. Em branco, salva em texto simples, que pode incluir chaves privadas/de canal, histórico e credenciais.';

  @override
  String get backupRestore_importUnavailable =>
      'Verifique a senha ou escolha um arquivo de backup compatível.';

  @override
  String get backupRestore_items => 'Itens de backup e restauração';

  @override
  String get backupRestore_nodeSettings => 'Configurações do nó';

  @override
  String get backupRestore_nodeSettingsDescription =>
      'Nome do dispositivo, chaves privada e pública, configurações de rádio e regiões';

  @override
  String get backupRestore_deviceName => 'Nome do dispositivo';

  @override
  String get backupRestore_privateKey => 'Chave privada (sensível)';

  @override
  String get backupRestore_publicKey => 'Chave pública';

  @override
  String get backupRestore_radioSettings => 'Configurações de rádio';

  @override
  String get backupRestore_regions => 'Regiões';

  @override
  String get backupRestore_location => 'Localização';

  @override
  String get backupRestore_contactSettings => 'Configurações de contatos';

  @override
  String get backupRestore_privacySettings => 'Configurações de privacidade';

  @override
  String get backupRestore_contactsData => 'Contatos';

  @override
  String get backupRestore_perContactSettings =>
      'Configurações e filtros por contato';

  @override
  String get backupRestore_contactGroups => 'Grupos de contatos';

  @override
  String get backupRestore_contactHistory => 'Histórico de contatos';

  @override
  String get backupRestore_channelsData => 'Canais';

  @override
  String get backupRestore_channelFilters =>
      'Configurações do filtro de mensagens';

  @override
  String get backupRestore_channelSettings => 'Configurações de canais';

  @override
  String get backupRestore_communities => 'Comunidades';

  @override
  String get backupRestore_channelHistory => 'Histórico de canais';

  @override
  String get backupRestore_locationSettings => 'Configurações de localização';

  @override
  String get backupRestore_locationSettingsDescription =>
      'Localização, configurações de contatos e de privacidade';

  @override
  String get backupRestore_appSettings => 'Configurações do app';

  @override
  String get backupRestore_appSettingsDescription =>
      'Preferências do app e configurações de aparência';

  @override
  String get backupRestore_ipfsKey => 'Chave de API do IPFS (sensível)';

  @override
  String get backupRestore_stadiaMapKey =>
      'Chave de API do Stadia Maps (sensível)';

  @override
  String get backupRestore_contacts => 'Contatos';

  @override
  String get backupRestore_contactsDescription =>
      'Contatos, filtros e configurações por contato, grupos e histórico de mensagens';

  @override
  String get backupRestore_discoveredContacts => 'Contatos descobertos';

  @override
  String get backupRestore_discoveredContactsDescription =>
      'Contatos descobertos e seus detalhes salvos';

  @override
  String get backupRestore_channels => 'Canais';

  @override
  String get backupRestore_channelsDescription =>
      'Canais, filtros de canal, comunidades e histórico de mensagens';

  @override
  String get backupRestore_backup => 'Criar backup';

  @override
  String get backupRestore_restore => 'Restaurar selecionados';

  @override
  String get backupRestore_backupComplete => 'Arquivo de backup criado.';

  @override
  String get backupRestore_restoreComplete =>
      'Restauração concluída. Reconecte se você restaurou a identidade do rádio.';

  @override
  String get backupRestore_missingModelsTitle => 'Modelos não baixados';

  @override
  String backupRestore_missingModelsMessage(String models) {
    return 'As configurações restauradas selecionam modelos que não estão disponíveis neste dispositivo:\n$models\n\nBaixar agora?';
  }

  @override
  String get backupRestore_downloadModels => 'Baixar modelos';

  @override
  String get backupRestore_downloading => 'Baixando…';

  @override
  String get backupRestore_cancelDownload => 'Cancelar download';

  @override
  String backupRestore_failed(String error) {
    return 'Falha na operação de backup: $error';
  }

  @override
  String get backupRestore_fileTooLarge =>
      'O arquivo de backup é maior que o limite de 100 MB.';

  @override
  String get backupRestore_selectAtLeastOne => 'Selecione pelo menos um item.';

  @override
  String get backupRestore_replaceIdentityTitle =>
      'Substituir a identidade do rádio?';

  @override
  String get backupRestore_replaceIdentityMessage =>
      'Restaurar as configurações do nó substitui a chave privada do rádio conectado e muda sua identidade. Continue apenas se for essa a intenção.';

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
  String get settings_radioSettingsNotApplied =>
      'O rádio não aplicou estas configurações';

  @override
  String get settings_pathHashModeNotApplied =>
      'As configurações do rádio foram aplicadas, mas o rádio não confirmou o novo tamanho do hash de caminho';

  @override
  String get settings_regionSettings => 'Regiões';

  @override
  String get settings_regionSettingsSubtitle => 'Limitar floods a uma área';

  @override
  String get settings_regionEmptyExplanation =>
      'As regiões limitam as mensagens Flood aos repetidores de uma área. Obtenha-as dos repetidores próximos ou adicione uma pelo nome.';

  @override
  String get settings_regionFetchFromRepeaters =>
      'Obter a partir de repetidores';

  @override
  String get settings_regionDefault => 'Região padrão';

  @override
  String get settings_regionDefaultSubtitle =>
      'Usada pelos canais sem região própria';

  @override
  String get settings_regionDefaultNone => 'Nenhuma';

  @override
  String settings_regionUseRadioDefault(String region) {
    return 'Padrão do rádio ($region)';
  }

  @override
  String get settings_regionNoRegion => 'Sem região (sem escopo)';

  @override
  String get settings_regionRadioDefault => 'Região padrão do rádio';

  @override
  String get settings_regionRadioDefaultSubtitle =>
      'Salva no rádio. Floods enviados sem região a utilizam, a partir deste app e de qualquer outro app conectado ao rádio.';

  @override
  String get settings_regionRadioDefaultUpdated =>
      'Região padrão do rádio atualizada';

  @override
  String get settings_regionRadioDefaultFailed =>
      'Não foi possível atualizar a região padrão do rádio';

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
  String get settings_telemetryPerContactHint =>
      'Para permitir um contato, abra o chat dele e escolha Configurações de Contato no menu.';

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
  String get settings_multiAck => 'ACKs múltiplos';

  @override
  String get settings_multiAckSubtitle =>
      'Enviar confirmações adicionais para melhorar a entrega; usa mais tempo de transmissão';

  @override
  String get settings_telemetryModeUpdated => 'Modo de telemetria atualizado';

  @override
  String get settings_actions => 'Ações';

  @override
  String get settings_deleteAllPaths => 'Excluir todos os caminhos';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Limpar todos os dados de caminhos dos contatos.';

  @override
  String get settings_sendAdvertisement => 'Enviar Anúncio';

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
  String get settings_publicKeyCopied => 'Chave pública copiada';

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
  String get settings_presetCustom => 'Personalizado';

  @override
  String get settings_radioMatchWarning =>
      'Todos os nós com os quais você fala devem usar a mesma frequência, largura de banda e SF. A taxa de codificação (CR) pode ser diferente.';

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
  String settings_txPowerRangeHelper(int min, int max) {
    return '$min a $max dBm';
  }

  @override
  String get settings_txPowerInvalid => 'Potência de TX inválida (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Repetição sem rede';

  @override
  String settings_clientRepeatFrequencyNote(String freq) {
    return 'Frequência definida em $freq MHz para a repetição sem rede';
  }

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
  String get appSettings_themeLight => 'Claro';

  @override
  String get appSettings_themeDark => 'Escuro';

  @override
  String get appSettings_colorTheme => 'Tema de cores';

  @override
  String get appSettings_holidayAnimations => 'Animações de mensagens festivas';

  @override
  String get appSettings_holidayAnimationsSubtitle =>
      'Morcegos, um peru, o Papai Noel ou fogos de artifício quando alguém envia uma saudação festiva';

  @override
  String get themes_title => 'Temas';

  @override
  String get themes_default => 'MeshCore';

  @override
  String get themes_defaultSubtitle =>
      'Cores padrão, segue a configuração Claro / Escuro';

  @override
  String get themes_builtIn => 'Incluídos';

  @override
  String get themes_holidays => 'Feriados';

  @override
  String get themes_holidayAutoSwitch => 'Mudar automaticamente';

  @override
  String get themes_holidayAutoSwitchSubtitle =>
      'Usa o tema de cada feriado de 17 dias antes até o próprio dia';

  @override
  String themes_holidayAutoApplied(String holiday) {
    return 'O tema de $holiday foi ativado automaticamente. Seu próprio tema volta depois do feriado.';
  }

  @override
  String get themes_holidayAutoAppliedTag => 'Ativado automaticamente';

  @override
  String get themes_myThemes => 'Meus temas';

  @override
  String get themes_myThemesEmpty =>
      'Crie seu próprio tema escolhendo um fundo e uma cor de destaque.';

  @override
  String get themes_create => 'Criar tema';

  @override
  String get themes_import => 'Importar tema';

  @override
  String get themes_importHint => 'Cole um código de tema';

  @override
  String get themes_importInvalid => 'Esse não é um código de tema válido';

  @override
  String themes_imported(String name) {
    return 'Tema \"$name\" adicionado';
  }

  @override
  String get themes_customize => 'Personalizar uma cópia';

  @override
  String get themes_copyCode => 'Copiar código do tema';

  @override
  String get themes_codeCopied => 'Código do tema copiado';

  @override
  String themes_deleteConfirm(String name) {
    return 'Excluir o tema \"$name\"?';
  }

  @override
  String themes_copyName(String name) {
    return 'Cópia de $name';
  }

  @override
  String get themes_newTitle => 'Novo tema';

  @override
  String get themes_editTitle => 'Editar tema';

  @override
  String get themes_name => 'Nome';

  @override
  String get themes_nameRequired => 'Dê um nome ao seu tema';

  @override
  String get themes_background => 'Fundo';

  @override
  String get themes_backgroundHelp => 'Um fundo escuro cria um tema escuro';

  @override
  String get themes_accent => 'Destaque';

  @override
  String get themes_accentHelp => 'Botões, realces e seus balões de conversa';

  @override
  String get themes_hexColor => 'Cor hexadecimal';

  @override
  String get themes_preview => 'Pré-visualização';

  @override
  String get themes_previewIncoming => 'Alguém na malha esta noite?';

  @override
  String get themes_previewOutgoing => 'Alto e claro!';

  @override
  String get themes_previewSwitch => 'Notificações';

  @override
  String get themes_lowContrast => 'O destaque quase não aparece neste fundo';

  @override
  String get themes_saveAndUse => 'Salvar e usar';

  @override
  String get themes_icons => 'Ícones';

  @override
  String get themes_iconsHelp =>
      'Toque em um ícone para trocá-lo por outro ícone ou por uma imagem sua';

  @override
  String get themes_iconChanged => 'Alterado';

  @override
  String get themes_iconSend => 'Botão de enviar';

  @override
  String get themes_iconRepeater => 'Repetidores';

  @override
  String get themes_iconRoom => 'Salas';

  @override
  String get themes_iconSensor => 'Sensores';

  @override
  String get themes_mapMarkers => 'Marcadores do mapa';

  @override
  String get themes_mapMarkersHelp =>
      'Troque os marcadores dos nós e o seu no mapa';

  @override
  String get themes_iconUsePicture => 'Usar uma imagem';

  @override
  String get themes_iconReset => 'Usar o ícone padrão';

  @override
  String get themes_iconPictureFailed => 'Não foi possível usar essa imagem';

  @override
  String get themes_exportFile => 'Exportar para arquivo';

  @override
  String get themes_exportAll => 'Exportar meus temas';

  @override
  String get themes_importFile => 'Importar de arquivo';

  @override
  String get themes_pasteCode => 'Colar código do tema';

  @override
  String get themes_exportFailed => 'Não foi possível exportar os temas';

  @override
  String themes_importFileResult(int count) {
    return '$count temas importados';
  }

  @override
  String get themes_importFileNone => 'Nenhum tema encontrado nesse arquivo';

  @override
  String get chatBackground_title => 'Fundo da conversa';

  @override
  String get chatBackground_thisChatOnly => 'Somente para esta conversa';

  @override
  String chatBackground_themeOverrides(String name) {
    return 'Seu tema \"$name\" define o fundo em todas as conversas. Desative isso no tema para usar este.';
  }

  @override
  String get chatBackground_none => 'Nenhum';

  @override
  String get chatBackground_picture => 'Imagem';

  @override
  String get chatBackground_choosePicture => 'Escolher uma imagem';

  @override
  String get chatBackground_pictureFailed =>
      'Não foi possível usar essa imagem';

  @override
  String get chatBackground_fade => 'Esmaecer';

  @override
  String get themes_chatBackground => 'Fundo da conversa';

  @override
  String get themes_chatBackgroundHelp =>
      'Mostrado nas conversas que não têm fundo próprio';

  @override
  String get themes_chatBackgroundEverywhere => 'Usar em todas as conversas';

  @override
  String get themes_chatBackgroundEverywhereHelp =>
      'Também substitui os fundos definidos em conversas individuais';

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
  String get appSettings_languagePt => 'Português (Brasil)';

  @override
  String get appSettings_languagePtPt => 'Português (Portugal)';

  @override
  String get appSettings_languageIt => 'Italiano';

  @override
  String get appSettings_languageZh => 'Chinês';

  @override
  String get appSettings_languageSv => 'Sueco';

  @override
  String get appSettings_languageNl => 'Holandês';

  @override
  String get appSettings_languageSk => 'Eslovaco';

  @override
  String get appSettings_languageBg => 'Búlgaro';

  @override
  String get appSettings_languageRu => 'Russo';

  @override
  String get appSettings_languageUk => 'Ucraniano';

  @override
  String get appSettings_languageCs => 'Tcheco';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 byte';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 bytes';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 bytes';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 bytes';

  @override
  String get settings_pathHashModeHelper =>
      'Tamanho de cada ID de nó registado no caminho dos pacotes Flood que este rádio envia: 1 byte (256 IDs, até 64 saltos), 2 bytes (65.000 IDs, até 32 saltos), 3 bytes (16 milhões de IDs, até 21 saltos). IDs maiores reduzem as colisões, mas os repetidores com firmware anterior à v1.14 descartam os pacotes com IDs de 2 ou 3 bytes.';

  @override
  String settings_requiresFirmware(String version) {
    return 'Requer o firmware $version ou mais recente';
  }

  @override
  String get appSettings_channelMinHops =>
      'Reenviar as mensagens de canal até atravessarem repetidores suficientes';

  @override
  String get appSettings_channelMinHopsSubtitle =>
      'Se a sua mensagem não for ouvida de volta por repetidores suficientes, envie-a de novo. Usa mais tempo de transmissão.';

  @override
  String appSettings_channelMinHopsCount(int count) {
    return 'Saltos necessários: $count';
  }

  @override
  String appSettings_channelMinHopsRetries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: '1 vez',
    );
    return 'Reenviar até $_temp0';
  }

  @override
  String get appSettings_channelMinHopsCountRepeaters =>
      'Contar também repetidores próximos diferentes';

  @override
  String appSettings_channelMinHopsCountRepeatersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repetidores próximos diferentes',
      one: '1 repetidor próximo',
    );
    return 'Considerar a mensagem como enviada quando $_temp0 a repetirem, mesmo que você não a ouça avançar mais.';
  }

  @override
  String get appSettings_enableMessageTracing =>
      'Ativar rastreamento de mensagens';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostrar metadados detalhados de roteamento e tempo para as mensagens';

  @override
  String get appSettings_regionOnHopsLine =>
      'Região ao lado da contagem de saltos';

  @override
  String get appSettings_regionOnHopsLineSubtitle =>
      'Mostra a região de uma mensagem de canal na mesma linha da contagem de saltos, em vez de abaixo dela.';

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
  String get appSettings_batteryOptimization => 'Atividade em segundo plano';

  @override
  String get appSettings_batteryOptimizationSubtitle =>
      'Defina o MeshCore Open como \"Não otimizar\" nas configurações de bateria para que as mensagens continuem a chegar em segundo plano';

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
      'Alternar entre os melhores caminhos e o modo Flood';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Rotação de roteamento automático habilitada';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Rotação de roteamento automático desativada';

  @override
  String get appSettings_maxMessageRetries =>
      'Número máximo de tentativas de envio de mensagens';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Número de tentativas de reenvio antes de classificar uma mensagem como falha.';

  @override
  String get appSettings_ipfsImageLinks => 'Configuração do provedor IPFS';

  @override
  String get appSettings_ipfsImageLinksSubtitle =>
      'Envio de imagens (ou arquivos) por URL através de um provedor IPFS e do gateway padrão para receber';

  @override
  String get appSettings_loadLinkImages => 'Carregar imagens de links';

  @override
  String get appSettings_loadLinkImagesSubtitle =>
      'Mostra as imagens dos links nas mensagens. Ao carregar uma imagem, o seu endereço IP é partilhado com o site que a hospeda.';

  @override
  String get appSettings_showLinkImagesByDefault =>
      'Mostrar imagens de links em todos os chats por padrão';

  @override
  String get appSettings_showLinkImagesByDefaultSubtitle =>
      'Carrega as imagens de links em cada chat, a menos que as tenha desativado lá. Isto partilha o seu endereço IP com os servidores de imagens em todos os chats.';

  @override
  String get appSettings_publicIpfsGateway => 'Gateway público';

  @override
  String get appSettings_ipfsGatewayDeactivated => 'Desativado';

  @override
  String get appSettings_ipfsGatewayCustom => 'Personalizado (Kubo)';

  @override
  String get appSettings_uploadIpfsProvider => 'Provedor de envio';

  @override
  String get appSettings_uploadIpfsGateway => 'Gateway de envio';

  @override
  String get appSettings_uploadIpfsGatewaySubtitle =>
      'Gateway para partilhar a imagem ou o arquivo como link URL. Deixe vazio para usar o formato ipfs:, que outros clientes podem não conseguir abrir.';

  @override
  String get appSettings_uploadIpfsEndpoint => 'Endpoint de envio';

  @override
  String get appSettings_uploadIpfsEndpointSubtitle =>
      'O endpoint da API usado para enviar arquivos';

  @override
  String get appSettings_uploadIpfsApiKey => 'Chave API de envio';

  @override
  String get appSettings_ipfsImageLinksDescription =>
      'O gateway público baixa as imagens no formato ipfs:. O gateway de envio é usado para gerar os links das imagens ou arquivos enviados por URL.';

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
  String get appSettings_showOnlineLinks => 'Mostrar conexões do mapa online';

  @override
  String get appSettings_showOnlineLinksSubtitle =>
      'Exibe linhas de conexão entre nós do mapa online';

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
  String get contacts_title => 'Contatos';

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
    return 'Pesquisar $number$str contatos...';
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
  String get contacts_storageFull =>
      'O armazenamento de contatos no nó está cheio. Não é possível adicionar novos nós até que contatos sejam removidos.';

  @override
  String get contacts_deleteContact => 'Excluir Contato';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Remover $contactName dos contatos?';
  }

  @override
  String get contacts_removeFromContacts => 'Remover dos contatos';

  @override
  String contacts_removeFromContactsConfirm(String contactName) {
    return '$contactName passará para os contatos descobertos. O histórico do chat será excluído.';
  }

  @override
  String get contacts_keepChatHistory => 'Manter o histórico do chat';

  @override
  String get contacts_remove => 'Remover';

  @override
  String get contacts_removeAutoAddNote =>
      'O seu rádio adiciona automaticamente este tipo de contato, por isso ele voltará na próxima vez que enviar um anúncio. Desative a adição automática nas configurações de Contatos para mantê-lo removido.';

  @override
  String get contacts_removeFailed =>
      'O rádio não confirmou a remoção. O contato não foi removido.';

  @override
  String contacts_discoveredNearby(int count) {
    return 'Descobertos nas proximidades ($count)';
  }

  @override
  String get contacts_noContactsDiscoveredHint =>
      'Os nós que o seu rádio ouve mas que ainda não adicionou estão listados em Contatos descobertos';

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
  String get contacts_lastSeenNow => 'Recente';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 hora';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours horas';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 dia';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days dias';
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
  String get channels_hashtag => 'Hashtag';

  @override
  String get channels_addSectionJoin => 'Entrar numa existente';

  @override
  String get channels_addSectionCreate => 'Criar nova';

  @override
  String get channels_dragToReorder => 'Arraste para reordenar';

  @override
  String get channels_editChannel => 'Editar canal';

  @override
  String get channels_notificationSettings => 'Configurações de notificação';

  @override
  String get channels_notifyAll => 'Todas as mensagens';

  @override
  String get channels_notifyMentionsOnly => 'Apenas menções';

  @override
  String get channels_notifyNone => 'Silenciado';

  @override
  String channels_notificationModeTooltip(String mode) {
    return 'Notificações: $mode';
  }

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
  String get channels_noFreeSlots => 'Todos os slots de canal estão em uso';

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
  String get channels_scanQrCode => 'Escanear um Código QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Em breve';

  @override
  String get channels_scanQrCodeDesc =>
      'Entre num canal ou comunidade com o respetivo código QR.';

  @override
  String get channels_scanQrInstructions =>
      'Aponte a câmera para um código QR de canal ou comunidade';

  @override
  String get channels_invalidQrCode =>
      'Não é um código QR de canal ou comunidade do MeshCore';

  @override
  String get channels_joinChannelTitle => 'Entrar no canal';

  @override
  String channels_joinChannelConfirm(String name) {
    return 'Adicionar \"$name\" ao seu rádio?';
  }

  @override
  String channels_alreadyOnRadio(String name) {
    return '\"$name\" já está no seu rádio';
  }

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
  String get channels_regionDefaultSuffix => '(padrão)';

  @override
  String get channels_regionRadioDefaultSuffix => '(padrão do rádio)';

  @override
  String channels_regionRadioDefaultApplies(String region) {
    return 'Este rádio envia floods sem região na sua região padrão: $region.';
  }

  @override
  String get channels_regionSelectExplanation =>
      'As mensagens Flood deste canal só serão encaminhadas por repetidores da região selecionada.';

  @override
  String get channels_regionEmpty => 'Ainda não há regiões.';

  @override
  String get channels_manageRegions => 'Gerenciar regiões';

  @override
  String get chat_noMessages => 'Ainda não existem mensagens.';

  @override
  String get chatSearch_tooltip => 'Pesquisar mensagens';

  @override
  String get chatSearch_hint => 'Pesquisar mensagens';

  @override
  String get chatSearch_close => 'Fechar pesquisa';

  @override
  String chatSearch_resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get chatSearch_noResults => 'Nenhuma mensagem correspondente';

  @override
  String get chatSearch_noResultsHint =>
      'Tente outra palavra ou verifique a ortografia';

  @override
  String get chatSearch_jumpFailed =>
      'Não foi possível encontrar essa mensagem na conversa';

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
  String get chat_futureTimestampWarning =>
      'O horário desta mensagem está no futuro, então o relógio do remetente pode estar errado. Ela é exibida na ordem em que chegou.';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Mensagem muito longa (máximo $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Mensagem copiada';

  @override
  String get chat_messageDeleted => 'Mensagem excluída';

  @override
  String get chat_selectMessages => 'Selecionar mensagens';

  @override
  String chat_selectedCount(int count) {
    return '$count selecionadas';
  }

  @override
  String get chat_selectAll => 'Selecionar tudo';

  @override
  String get chat_clearSelection => 'Limpar seleção';

  @override
  String get chat_deleteSelectedTitle => 'Excluir mensagens?';

  @override
  String chat_deleteSelectedConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count mensagens deste dispositivo?',
      one: 'Excluir 1 mensagem deste dispositivo?',
    );
    return '$_temp0';
  }

  @override
  String chat_messagesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens excluídas',
      one: '1 mensagem excluída',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_markedSpamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens marcadas como spam',
      one: '1 mensagem marcada como spam',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_markedNotSpamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens marcadas como não spam',
      one: '1 mensagem marcada como não spam',
    );
    return '$_temp0';
  }

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
  String get chat_shareMyLocation => 'Compartilhar minha localização';

  @override
  String get chat_noRadioLocation => 'O seu rádio não tem localização definida';

  @override
  String get chat_removeGif => 'Remover GIF';

  @override
  String get chat_cancelReply => 'Cancelar resposta';

  @override
  String get chat_sendImageLora => 'Enviar imagem via MeshCore';

  @override
  String get chat_sendImageIpfs => 'Enviar imagem ou arquivo via IPFS';

  @override
  String chat_ipfsUploadFailed(String error) {
    return 'Falha no envio para o IPFS: $error';
  }

  @override
  String get chat_ipfsUploadNotConfigured =>
      'Configure primeiro um provedor de envio IPFS nas Configurações do app.';

  @override
  String get chat_ipfsSelectedFileEmpty => 'O arquivo selecionado está vazio.';

  @override
  String get chat_ipfsEndpointInvalid =>
      'O endpoint de envio IPFS deve ser um endereço completo http:// ou https://. Verifique-o nas Configurações do app.';

  @override
  String get chat_ipfsPinataTokenMissing =>
      'O Pinata precisa de uma chave API ou JWT. Adicione-a nas Configurações do app.';

  @override
  String get chat_ipfsFilebaseTokenMissing =>
      'O Filebase precisa de um token de API. Adicione-o nas Configurações do app.';

  @override
  String get chat_ipfsKuboPathInvalid =>
      'O endpoint de envio do Kubo deve terminar em /api/v0/add. Verifique-o nas Configurações do app.';

  @override
  String get chat_ipfsLinkNoRoom =>
      'Não há espaço suficiente para o link da imagem. Encurte a sua mensagem e tente novamente.';

  @override
  String get chat_ipfsLinkOverLimit =>
      'Link da imagem adicionado, mas a mensagem agora está muito longa. Encurte-a antes de enviar.';

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
  String get reaction_report => 'Reações com Emoji';

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
  String get routing_modeAuto => 'Auto';

  @override
  String get routing_modeFlood => 'Flood';

  @override
  String get routing_modeManual => 'Manual';

  @override
  String get routing_modeDirect => 'Direto';

  @override
  String get routing_modeAutoHint =>
      'Seleciona automaticamente o caminho mais conhecido, e, se nenhum caminho conhecido for encontrado, utiliza a estratégia de \"Flood\".';

  @override
  String get routing_modeFloodHint =>
      'Transmissão através de todos os repetidores. É a opção mais confiável, mas utiliza mais tempo de transmissão.';

  @override
  String get routing_modeManualHint =>
      'Sempre segue exatamente o caminho que você define.';

  @override
  String get routing_modeDirectHint =>
      'Envia sempre diretamente a este contato, sem saltos de repetidor. Use quando ele estiver ao alcance do rádio.';

  @override
  String get routing_currentRoute => 'Rota atual';

  @override
  String get routing_directNoHops => 'Direto – sem saltos de repetidor';

  @override
  String get routing_noPathYet =>
      'Ainda não há caminho. A próxima mensagem usa Flood até uma rota ser descoberta.';

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
  String get routing_qualityStrong => 'Primeiro salto forte';

  @override
  String get routing_qualityGood => 'Primeiro salto bom';

  @override
  String get routing_qualityFair => 'Primeiro salto razoável';

  @override
  String get routing_qualityWorked => 'Foi entregue';

  @override
  String get routing_qualityFlood => 'Ouvido via Flood';

  @override
  String get routing_qualityUntested => 'Não testado';

  @override
  String routing_lastWorked(String when) {
    return 'funcionou $when';
  }

  @override
  String get routing_neverWorked => 'nunca confirmado';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes entregues, $failures falharam';
  }

  @override
  String get routing_floodDelivery => 'Entrega Flood';

  @override
  String get pathEditor_title => 'Criar Caminho';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count de 64 saltos';
  }

  @override
  String get pathEditor_noHops =>
      'Ainda não há saltos adicionados. Clique nos repetidores abaixo para adicioná-los na ordem desejada, ou salve sem adicionar saltos para enviar diretamente.';

  @override
  String get pathEditor_addHops => 'Adicione os saltos na seguinte ordem.';

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
  String get pathEditor_removeHop => 'Remova o salto';

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
  String get chat_viewPathOnMap => 'Ver o caminho no mapa';

  @override
  String get chat_publicKey => 'Chave Pública';

  @override
  String get chat_compressOutgoingMessages => 'Comprimir mensagens enviadas';

  @override
  String get chat_floodForced => 'Flood (forçado)';

  @override
  String get chat_directForced => 'Direto (forçado)';

  @override
  String chat_hopsForced(int count) {
    return '$count saltos (forçado)';
  }

  @override
  String get chat_floodAuto => 'Flood (automático)';

  @override
  String get chat_direct => 'Salvar';

  @override
  String get chat_poiShared => 'Ponto de Interesse Compartilhado';

  @override
  String get contactShare_headerOutgoing => 'Você compartilhou um contato';

  @override
  String get contactShare_headerIncoming => 'Compartilhou um contato';

  @override
  String get contactShare_add => 'Adicionar contato';

  @override
  String get contactShare_adding => 'Adicionando contato...';

  @override
  String get contactShare_saved => 'Salvo';

  @override
  String get contactShare_addAgain => 'Adicionar novamente';

  @override
  String get contactShare_isYou => 'Este é você';

  @override
  String get contactShare_shareAction => 'Compartilhar contato';

  @override
  String get contactShare_pickerTitle => 'Compartilhar um contato';

  @override
  String get contactShare_myContact => 'Meu contato';

  @override
  String get contactShare_searchHint => 'Pesquisar contatos';

  @override
  String get contactShare_noContacts => 'Nenhum contato encontrado';

  @override
  String contactShare_preview(String name) {
    return 'Contato compartilhado: $name';
  }

  @override
  String contactShare_notification(String name) {
    return 'Compartilhou um contato: $name';
  }

  @override
  String chat_unread(int count) {
    return 'Não lido: $count';
  }

  @override
  String get chat_markAsUnread => 'Marcar como não lido';

  @override
  String get chat_newMessages => 'Novas mensagens';

  @override
  String get chat_today => 'Hoje';

  @override
  String get chat_yesterday => 'Ontem';

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
  String get map_centerOnMe => 'Centralizar na minha localização';

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
  String get map_noNodesLocationHint =>
      'Nenhum nó com uma localização recente. Amplie o filtro de tempo ou defina a sua localização nas Configurações.';

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
  String get map_from => 'De';

  @override
  String get map_source => 'Fonte';

  @override
  String get map_flags => 'Bandeiras';

  @override
  String get map_type => 'Type';

  @override
  String get map_path => 'Caminho';

  @override
  String get map_location => 'Localização';

  @override
  String get map_estLocation => 'Localização est.';

  @override
  String get map_publicKey => 'Chave pública';

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
  String get map_labelUpdateHint =>
      'Usar o mesmo rótulo de antes atualizará o marcador para os destinatários do MeshCore Open.';

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
  String get map_showOnlineLinks => 'Mostrar conexões do mapa online';

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
  String get map_clusterNodes => 'Agrupar os nós próximos';

  @override
  String get map_groupChip => 'Agrupar';

  @override
  String get map_clusterNodesSubtitle =>
      'Ao afastar o zoom, mostrar os nós próximos como um único círculo numerado';

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
  String get map_manageServer => 'Gerenciar o servidor';

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
  String get map_pathTraceAddMoreHint =>
      'Toque em mais nós para adicionar saltos, escolha como o rastreamento retorna e toque em Executar rastreamento de caminho.';

  @override
  String get map_pathTraceModeRoundTrip => 'Ida e volta';

  @override
  String get map_pathTraceModeRoundTripHint =>
      'O rastreamento sai por estes saltos e volta pelo mesmo caminho.';

  @override
  String get map_pathTraceModeAsEntered => 'Como inserido';

  @override
  String get map_pathTraceModeAsEnteredHint =>
      'O rastreamento segue exatamente estes saltos. Adicione você mesmo os saltos de volta até si.';

  @override
  String get map_pathTraceViewLast => 'Ver último resultado';

  @override
  String get manualTrace_menuItem => 'Rastreamento de caminho por hashes';

  @override
  String get manualTrace_inputLabel => 'Hashes de repetidores';

  @override
  String manualTrace_helper(String example) {
    return 'Exemplo: $example. Separe com vírgulas ou espaços.';
  }

  @override
  String manualTrace_previewTitle(int count) {
    return 'Saltos ($count)';
  }

  @override
  String get manualTrace_unknownNode => 'Nó desconhecido';

  @override
  String get manualTrace_enterHashes => 'Insira os hashes';

  @override
  String get manualTrace_run => 'Executar rastreamento de caminho';

  @override
  String get manualTrace_notConnected =>
      'Conecte-se a um rádio para executar um rastreamento';

  @override
  String get manualTrace_errorInvalidHex =>
      'Somente caracteres hexadecimais (0-9, A-F) são permitidos';

  @override
  String get manualTrace_errorOddLength =>
      'Cada hash precisa de um número par de caracteres hexadecimais, de acordo com o tamanho do salto';

  @override
  String get manualTrace_errorMixedWidths =>
      'Todos os hashes devem ter o mesmo comprimento';

  @override
  String get manualTrace_errorUnsupportedWidth =>
      'Os hashes devem ter 1, 2 ou 3 bytes (2, 4 ou 6 caracteres hexadecimais)';

  @override
  String manualTrace_errorTooManyHops(int max) {
    return 'O caminho é muito longo (máximo de $max bytes)';
  }

  @override
  String get manualTrace_errorTraceTooLong =>
      'Saltos demais para rastrear em uma única solicitação. Remova alguns saltos ou escolha “Como inserido”.';

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
  String get login_showPassword => 'Mostrar senha';

  @override
  String get login_hidePassword => 'Esconder a senha';

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
  String get login_advanced => 'Avançado';

  @override
  String get login_routing => 'Rotas';

  @override
  String get login_routingMode => 'Modo de roteamento';

  @override
  String get login_autoUseSavedPath => 'Auto (usar caminho salvo)';

  @override
  String get login_forceFloodMode => 'Modo Flood Forçado';

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
  String get common_clearSearch => 'Limpar pesquisa';

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
  String get repeater_roleAdmin => 'ADMIN';

  @override
  String get repeater_roleGuest => 'CONVIDADO';

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
  String get repeater_neighborsSubtitle => 'Ver vizinhos Zero Hop.';

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
  String get repeater_txAirtime => 'Airtime TX';

  @override
  String get repeater_rxAirtime => 'Airtime RX';

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
  String repeater_hoursMinsSecs(int hours, int minutes, int seconds) {
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Flood: $flood, Direto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Flood: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Direto: $direct';
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
  String get repeater_floodAdvertInterval => 'Intervalo de Anúncio de Flood';

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
  String get repeater_multiAcks => 'Múltiplas respostas de confirmação';

  @override
  String get repeater_multiAcksSubtitle =>
      'Reconheça mensagens através de múltiplos caminhos para uma melhor entrega.';

  @override
  String get repeater_networkHealth => 'Saúde da rede';

  @override
  String get repeater_loopDetect => 'Detecção de loops';

  @override
  String get repeater_loopDetectHelper =>
      'Descarta pacotes Flood que pareçam loops de roteamento';

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
  String get repeater_floodMax => 'Máximo de saltos Flood';

  @override
  String get repeater_floodMaxHelper =>
      'Número máximo de saltos que um pacote Flood pode percorrer (0-64)';

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
  String get repeater_txDelay => 'Atraso de TX Flood';

  @override
  String get repeater_txDelayHelper =>
      'Ajuste de espaçamento para tráfego Flood, como um multiplicador do tempo de transmissão (0-2, padrão 0,5). Quanto maior, menos colisões, mas uma entrega mais lenta.';

  @override
  String get repeater_directTxDelay => 'Atraso direto no sinal TX';

  @override
  String get repeater_directTxDelayHelper =>
      'Intervalo de retransmissão para tráfego direto (não Flood), como um multiplicador do tempo de transmissão do pacote (0-2, padrão 0,3).';

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
  String get repeater_sendAdvert => 'Envie anúncio Flood';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Transmita um anúncio Flood pela rede.';

  @override
  String get repeater_sendAdvertZeroHop => 'Enviar anúncio Zero Hop';

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
    return '$action concluído com sucesso';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action falhou: $error';
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
  String get repeater_refreshRadioSettings =>
      'Atualizar Configurações de Rádio';

  @override
  String get repeater_refreshPrivacyMode => 'Atualizar Modo Privacidade';

  @override
  String get repeater_refreshAll => 'Atualizar tudo';

  @override
  String get repeater_settingsNotLoaded =>
      'As configurações ainda não foram carregadas deste repetidor.';

  @override
  String get repeater_settingsLoadIncomplete =>
      'Algumas configurações não puderam ser carregadas. Use os botões de atualização para tentar novamente.';

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
      'Define o número máximo de saltos de pacotes Flood de entrada (se for >= máximo, o pacote não é encaminhado)';

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
      'Define o intervalo do timer em horas para enviar um pacote de anúncio Flood. Defina como 0 para desativar.';

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
      'Define um fator multiplicado com o tempo-em-ar para um pacote de modo Flood e com um sistema de slot aleatório, para atrasar seu encaminhamento. (para diminuir a probabilidade de colisões)';

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
      '(apenas serial) Lista todas as regiões definidas e as permissões Flood atuais.';

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
      'Define a permissão de \'F\'lood para a região especificada. (\'\' para o escopo global/legado)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Remove a permissão de \"F\"lood para a região especificada. (NOTA: neste momento NÃO é aconselhável usar isso no escopo global/legado!!)';

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
  String get repeater_frequencyRangeHelper => '150-2500 MHz';

  @override
  String get repeater_frequencyInvalid => 'Frequência inválida (150-2500 MHz)';

  @override
  String get repeater_txPowerRangeHelper => '-9 a 30 dBm';

  @override
  String get repeater_recvErrors => 'Erros de Recepção';

  @override
  String get room_postsStored => 'Publicações';

  @override
  String get room_postsPushed => 'Publicações Enviadas';

  @override
  String get repeater_cliRegionLoadActive =>
      'Modo de carregamento de regiões: envie um nome de região por linha, indentado com espaços sob sua região pai (adicione F após o nome para permitir Flood). As linhas não recebem resposta. Envie uma linha vazia para terminar e depois \"region save\" para salvar o resultado.';

  @override
  String get repeater_cliRegionLoadHint =>
      'Linha de região, ou vazia para terminar';

  @override
  String get repeater_cliRegionLoadEnd => '(fim do carregamento de regiões)';

  @override
  String get repeater_cliHelpRegionDef =>
      'Define uma cadeia de regiões em um único comando: cada nome é adicionado sob o anterior; \"name,parent\" adiciona o nome e continua sob o pai indicado. Responde com a lista de regiões.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Define o número máximo de saltos para encaminhar pacotes Flood sem escopo regional (0-64).';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Define o número máximo de saltos para encaminhar anúncios Flood (0-64).';

  @override
  String get repeater_cliHelpGetFloodMaxUnscoped =>
      'Mostra o número máximo de saltos para pacotes Flood sem escopo regional.';

  @override
  String get repeater_cliHelpGetFloodMaxAdvert =>
      'Mostra o número máximo de saltos para os anúncios Flood.';

  @override
  String get repeater_cliHelpSetRadioFemRxGain =>
      'Ativa ou desativa o ganho RX (LNA) do módulo frontal de LoRa. Placas sem esse módulo respondem \"Error: unsupported\".';

  @override
  String get repeater_cliHelpSetRadioFemTxGain =>
      'Ativa ou desativa o ganho TX (PA) do módulo frontal de LoRa. Placas sem esse módulo respondem \"Error: unsupported\".';

  @override
  String get repeater_cliHelpGetRadioFemRxGain =>
      'Mostra se o ganho RX do módulo frontal de LoRa está ativado.';

  @override
  String get repeater_cliHelpGetRadioFemTxGain =>
      'Mostra se o ganho TX do módulo frontal de LoRa está ativado.';

  @override
  String get repeater_bridgeNote =>
      'Disponível apenas em firmware compilado com uma ponte (RS232 ou ESP-NOW).';

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
      'Envia um anúncio Zero Hop (apenas para vizinhos imediatos).';

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
      'Indica o intervalo de anúncio local em minutos.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Mostra o intervalo do anúncio Flood, em horas.';

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
      'Mostra o fator de atraso em modo Flood.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Mostra o fator de atraso direto.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Mostra o número máximo de saltos Flood.';

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
      'Lista as regiões que permitem o tráfego Flood.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Lista as regiões que negam o tráfego Flood.';

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
    return 'Caminho observado $index • $hops';
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
  String get channelPath_floodPath => 'Flood';

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
      'Não estão disponíveis detalhes de salto para este pacote.';

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
  String get community_scanQr => 'Escanear QR Code da comunidade';

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
    return 'Escaneie o novo código QR para atualizar o segredo de \"$name\"';
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
      'Um ou mais dos saltos estão sem localização!';

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
  String get discoveredContacts_export => 'Exportar contatos descobertos';

  @override
  String get discoveredContacts_import => 'Importar contatos descobertos';

  @override
  String discoveredContacts_exported(String path) {
    return 'Contatos descobertos exportados para $path.';
  }

  @override
  String discoveredContacts_exportFailed(String error) {
    return 'Falha ao exportar contatos descobertos: $error';
  }

  @override
  String discoveredContacts_imported(int count) {
    return '$count contatos descobertos importados.';
  }

  @override
  String get discoveredContacts_importNoContacts =>
      'Nenhum contato encontrado no arquivo de importação.';

  @override
  String discoveredContacts_importSummary(
    int imported,
    int skipped,
    int invalid,
  ) {
    return '$imported contatos descobertos importados. $skipped já conhecidos e $invalid entradas ilegíveis foram ignorados.';
  }

  @override
  String get discoveredContacts_importInvalidFile =>
      'O arquivo não é uma exportação de contatos descobertos.';

  @override
  String discoveredContacts_importTooLarge(int maxMb) {
    return 'O arquivo de importação é grande demais (máximo $maxMb MB).';
  }

  @override
  String discoveredContacts_importFailed(String error) {
    return 'Falha ao importar contatos descobertos: $error';
  }

  @override
  String get contacts_zeroHopAdvert => 'Anúncio Zero Hop';

  @override
  String get contacts_floodAdvert => 'Anúncio de Flood';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Copiar Anúncio para Área de Transferência';

  @override
  String get contacts_addContactFromClipboard =>
      'Adicionar Contato da Área de Transferência';

  @override
  String get contacts_scanQrCode => 'Escanear um Código QR';

  @override
  String get contacts_scanQrInstructions =>
      'Aponte a câmera para um código QR de contato do MeshCore';

  @override
  String get contacts_qrFromGallery => 'Escanear QR da galeria';

  @override
  String get contacts_noQrCodeFound =>
      'Nenhum código QR encontrado na imagem selecionada.';

  @override
  String get contacts_qrGalleryFailed => 'Não foi possível abrir a galeria.';

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
  String get notification_lowBatteryTitle => 'Bateria fraca';

  @override
  String notification_lowBatteryBody(String deviceName, int percent) {
    return 'A bateria de $deviceName está em $percent%';
  }

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
  String get notification_sharedLocation => 'Partilhou uma localização';

  @override
  String notification_sharedLocationNamed(String label) {
    return 'Partilhou uma localização: $label';
  }

  @override
  String notification_reacted(String emoji) {
    return 'Reagiu $emoji';
  }

  @override
  String get notification_sentGif => 'Enviou um GIF';

  @override
  String get notification_sentImage => 'Enviou uma imagem';

  @override
  String get notification_actionReply => 'Responder';

  @override
  String get notification_actionMarkRead => 'Marcar como lido';

  @override
  String get notification_actionMuteChannel => 'Silenciar canal';

  @override
  String get notification_replyHint => 'Mensagem';

  @override
  String get notification_you => 'Você';

  @override
  String get notification_replyFailedTitle => 'Resposta não enviada';

  @override
  String get notification_replyNotConnected =>
      'Não conectado a um rádio. Reconecte no MeshCore Open e envie a sua resposta novamente.';

  @override
  String get notification_replyTooLong =>
      'A sua resposta é demasiado longa para ser enviada a partir de uma notificação. Envie-a pelo MeshCore Open.';

  @override
  String get notification_replyUnavailable =>
      'Esta conversa já não está no rádio conectado.';

  @override
  String get notification_replySendFailed =>
      'A sua resposta pode não ter sido enviada. Verifique no MeshCore Open e tente novamente.';

  @override
  String get notification_replyAppNotRunning =>
      'O MeshCore Open não está em execução. Abra-o e envie a sua resposta novamente.';

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
  String get snrIndicator_nearByRepeatersDescription =>
      'Repetidores que o seu rádio ouviu diretamente, do mais recente para o mais antigo.';

  @override
  String get snrIndicator_unknownRepeater => 'Repetidor desconhecido';

  @override
  String get snrIndicator_unknownRepeaterHint =>
      'Este repetidor ainda não está nos seus contatos. O nome, a localização e as opções aparecem quando o seu rádio receber o respetivo anúncio.';

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
  String get contactsSettings_evictDiscoveredContactsTitle =>
      'Remover contatos descobertos';

  @override
  String contactsSettings_evictDiscoveredContactsSubtitle(int limit) {
    return 'Quando ativado, o aplicativo remove os contatos descobertos mais antigos assim que a lista de descobertos atingir o limite de $limit entradas.';
  }

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
  String get discoveredContacts_scan => 'Buscar nós próximos';

  @override
  String get discoveredContacts_scanTitle => 'Nós próximos';

  @override
  String get discoveredContacts_scanExplanation =>
      'Pede aos nós ao alcance direto do rádio que se identifiquem. Repetidores e sensores respondem. Servidores de sala e companheiros geralmente não.';

  @override
  String get discoveredContacts_scanning => 'Buscando…';

  @override
  String discoveredContacts_scanFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nós encontrados',
      one: '1 nó encontrado',
    );
    return '$_temp0';
  }

  @override
  String get discoveredContacts_scanNoResults =>
      'Nenhum nó respondeu. Os repetidores limitam a frequência das respostas, então tente novamente em um minuto.';

  @override
  String get discoveredContacts_scanAgain => 'Buscar novamente';

  @override
  String get discoveredContacts_scanFailed =>
      'Não foi possível enviar a solicitação de busca.';

  @override
  String discoveredContacts_scanSignal(String snr, String remoteSnr) {
    return 'Sinal $snr dB · eles nos ouviram a $remoteSnr dB';
  }

  @override
  String get discoveredContacts_scanInContacts => 'Já está nos contatos';

  @override
  String get discoveredContacts_scanNameLater =>
      'O nome aparece após o próximo anúncio';

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
  String get appSettings_autoFetchRepeaterSettings =>
      'Buscar automaticamente as configurações do repetidor';

  @override
  String get appSettings_autoFetchRepeaterSettingsSubtitle =>
      'Solicita todas as configurações ao abrir as configurações de um repetidor. Cada uma é uma solicitação separada via LoRa, então é lento e consome tempo de transmissão. Quando desativado, toque em Atualizar tudo ou atualize seções individuais.';

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
  String get radioStats_sectionSignal => 'Sinal';

  @override
  String get radioStats_sectionAirtime => 'Tempo de transmissão';

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
  String get imageMessages_downloadModel => 'Baixar';

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
  String get background_serviceTitle => 'MeshCore em execução';

  @override
  String get background_serviceText => 'Mantendo o BLE conectado';

  @override
  String appSettings_translationModelDeleted(String name) {
    return '$name excluído';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Falha ao atualizar o canal: $error';
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
  String get contact_typeUnknown => 'Desconhecido';

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
    return 'Alt. $index';
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
  String get pathMap_expandHopList => 'Expandir lista de saltos';

  @override
  String get pathMap_showMap => 'Mostrar mapa';

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
  String imageSend_lossyNote(int bytes) {
    return 'Comprimido para cerca de $bytes bytes. O modelo do receptor reconstrói-o, por isso os detalhes serão diferentes.';
  }

  @override
  String get imageSend_viewOriginal => 'Original';

  @override
  String get imageSend_viewReconstruction => 'O que os destinatários veem';

  @override
  String get imageSend_reconstructionUnavailable =>
      'Este dispositivo não pode pré-visualizar a reconstrução.';

  @override
  String get imageSend_modelNotDownloaded =>
      'O modelo de imagem ainda não foi transferido. Transfira-o nas Configurações para enviar imagens.';

  @override
  String get imageSend_originalSize => 'Original';

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
      'Roteamento Flood: cada repetidor na faixa retransmite cada pacote, fazendo com que o canal permaneça ocupado por mais tempo do que isso.';

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
  String get receivedImage_save => 'Guardar imagem';

  @override
  String receivedImage_shareCaption(int bytes) {
    return 'Reconstruído por IA a partir de $bytes bytes; os detalhes finos são gerados, não transmitidos.';
  }

  @override
  String get receivedImage_syntheticBadge => 'Reconstruída por IA';

  @override
  String get receivedImage_packetInfo => 'Informações do pacote';

  @override
  String get receivedImage_parityRecovered =>
      'Um pacote foi reconstruído a partir do pacote de recuperação.';

  @override
  String receivedImage_decodeTime(int ms) {
    return 'Reconstruído em $ms ms';
  }

  @override
  String get receivedImage_saveFailed => 'Não foi possível guardar a imagem';

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

  @override
  String chat_longMessageRetryNote(int count) {
    return 'Mais de 158 bytes: enviado no máximo $count vezes';
  }

  @override
  String get reviewMode_dialogTitle => 'Entrar no modo de revisão?';

  @override
  String get reviewMode_dialogBody =>
      'O modo de revisão conecta-se a um rádio simulado com contatos, canais e mensagens de exemplo. Não é necessário um rádio real.';

  @override
  String get reviewMode_confirm => 'Entrar';

  @override
  String get reviewMode_cancel => 'Cancelar';

  @override
  String get reviewMode_banner => 'Modo de revisão — dados simulados';

  @override
  String get reviewMode_sendTest => 'Enviar mensagem de teste';

  @override
  String get reviewMode_testSent => 'Uma mensagem de teste chegará em breve.';

  @override
  String get reviewMode_exit => 'Sair';

  @override
  String reviewMode_connectFailed(String error) {
    return 'Não foi possível iniciar o modo de revisão: $error';
  }

  @override
  String get channels_waitForSync =>
      'Os canais ainda estão sendo carregados do rádio. Tente novamente quando a sincronização terminar.';

  @override
  String channels_nameTooLong(int maxBytes) {
    return 'O nome é muito longo (máx. $maxBytes bytes).';
  }

  @override
  String repeater_valueRequired(String field) {
    return '$field: insira um valor';
  }

  @override
  String get repeater_floodMaxAdvert => 'Máximo de saltos Flood de anúncios';

  @override
  String get repeater_floodMaxAdvertHelper =>
      'Número máximo de saltos que um anúncio Flood pode percorrer (0-64, padrão 8)';

  @override
  String get repeater_floodMaxUnscoped => 'Máximo de saltos Flood sem escopo';

  @override
  String get repeater_floodMaxUnscopedHelper =>
      'Número máximo de saltos para pacotes Flood sem escopo de região (0-64, padrão 64). Um valor baixo, como 3, mantém o tráfego sem escopo local.';

  @override
  String get repeater_floodMaxUnscopedUnset => 'Igual ao máximo Flood';

  @override
  String get repeater_rxDelay => 'Atraso de recepção';

  @override
  String get repeater_rxDelayHelper =>
      'Retém pacotes Flood ouvidos com sinal fraco antes de encaminhá-los, para que os caminhos com sinal forte tenham prioridade e menos duplicatas sejam enviadas (0-20, 0 desativa).';

  @override
  String get repeater_cad => 'Detecção de atividade do canal';

  @override
  String get repeater_cadHelper =>
      'Escuta a atividade antes de transmitir e aguarda enquanto o canal estiver ocupado. Funciona em conjunto com o limite de interferência.';

  @override
  String get repeater_adcMultiplier => 'Calibração da tensão da bateria';

  @override
  String get repeater_adcMultiplierHelper =>
      'Multiplicador da leitura da tensão da bateria (0-10). 0 usa o padrão da placa.';

  @override
  String get repeater_boardSupportNote =>
      'Nem toda placa oferece suporte a isso. Placas sem suporte rejeitam a alteração.';

  @override
  String get repeater_extraSf => 'Fatores de dispersão extras';

  @override
  String get repeater_extraSfHelper =>
      'Até 3 fatores de dispersão adicionais para escutar ao mesmo tempo, separados por vírgulas (por exemplo, 9,10). Deixe vazio para desativar.';

  @override
  String get repeater_lr2021Only =>
      'Somente para repetidores com rádio LR2021. Os demais repetidores não têm esta configuração e a rejeitam.';

  @override
  String get losMapDetailTooltip => 'Detalhe do mapa';

  @override
  String get losUnitsTooltip => 'Unidades';

  @override
  String get losDistance => 'Distância';

  @override
  String get losClearance => 'Folga';

  @override
  String get losBlockedBy => 'Bloqueado por';

  @override
  String get losObstruction => 'Obstrução';

  @override
  String losDistanceFromA(String distance) {
    return '$distance de A';
  }

  @override
  String get losWorstBadge => 'PIOR';

  @override
  String losBlockedAmount(String amount) {
    return 'Bloqueado $amount';
  }

  @override
  String get losFromA => 'De A';

  @override
  String get losFromB => 'De B';

  @override
  String get losElevation => 'Elevação';

  @override
  String get losCenterOnMap => 'Centralizar no mapa';

  @override
  String get losStatusClear => 'Livre';

  @override
  String get losStatusMarginal => 'Marginal';

  @override
  String get losStatusBlocked => 'Bloqueado';

  @override
  String get losStatusCheckingShort => 'Verificando';

  @override
  String get losStatusNoResult => 'Sem resultado';

  @override
  String get losSelectedPill => 'Selecionado';

  @override
  String get gif_tapToLoad => 'Toque para carregar o GIF';

  @override
  String get gif_loadFailedRetry =>
      'Não foi possível carregar o GIF\nToque para tentar novamente';

  @override
  String get qr_cameraPermissionDenied =>
      'Permissão da câmera negada.\nAtive o acesso à câmera nas configurações.';

  @override
  String get qr_cameraUnsupported =>
      'Câmera não compatível com este dispositivo.';

  @override
  String qr_cameraStartFailed(String details) {
    return 'Falha ao iniciar a câmera.\n$details';
  }

  @override
  String imageMessages_downloadFailedWithError(String error) {
    return 'Não foi possível baixar o modelo de imagem: $error';
  }

  @override
  String get map_nodeId => 'ID';

  @override
  String get map_markerHideHint =>
      'Ocultar: fica oculto até você sair do mapa.';

  @override
  String get map_markerRemoveHint =>
      'Remover: continua oculto até você restaurá-lo no menu de filtros.';

  @override
  String get map_markerRemoved => 'Marcador removido';

  @override
  String get map_restoreRemovedMarkers => 'Restaurar marcadores removidos';

  @override
  String map_restoreRemovedMarkersSubtitle(int count) {
    return '$count removidos';
  }

  @override
  String map_markersRestored(int count) {
    return '$count marcadores restaurados';
  }

  @override
  String get map_setLocationConfirmTitle => 'Definir como sua localização?';

  @override
  String map_setLocationConfirmBody(String lat, String lon) {
    return 'Seu nó vai anunciar esta posição:\n$lat, $lon';
  }

  @override
  String get map_setLocationAction => 'Definir localização';

  @override
  String get map_locationSetSuccess => 'Localização do nó atualizada';

  @override
  String get map_locationSetFailed =>
      'O dispositivo não confirmou a nova localização. Tente novamente.';

  @override
  String map_poiClusterTitle(int count) {
    return '$count marcadores aqui';
  }

  @override
  String map_poiClusterSemantics(int count) {
    return '$count marcadores compartilhados. Toque para listá-los.';
  }

  @override
  String map_youWithMarkers(int count) {
    return 'Você e $count marcadores';
  }

  @override
  String map_sharedMarkerSemantics(String label) {
    return 'Marcador compartilhado: $label';
  }

  @override
  String map_nodeMarkerSemantics(String name, String type, String status) {
    return '$name, $type, $status';
  }

  @override
  String get map_requestLocation => 'Atualizar localização';

  @override
  String get map_locationUpdated => 'Localização atualizada';

  @override
  String map_locationNotShared(String name) {
    return '$name respondeu sem localização';
  }

  @override
  String map_locationRequestFailed(String name) {
    return 'Sem resposta de $name';
  }

  @override
  String mapCache_zoomLevel(int zoom) {
    return 'Zoom $zoom';
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
    return 'Download cancelado. $count blocos em cache.';
  }

  @override
  String get mapCache_tooManyTilesTitle => 'Área muito grande';

  @override
  String mapCache_tooManyTiles(int count, int max) {
    return 'Esta área precisa de $count blocos, mais do que o limite de $max. Escolha uma área menor ou reduza o zoom máximo.';
  }

  @override
  String get chat_clearChatConfirm =>
      'Isto apaga todas as mensagens desta conversa deste dispositivo. Não é possível desfazer.';

  @override
  String get channels_clearChatConfirm =>
      'Isto apaga todas as mensagens deste canal deste dispositivo, incluindo as imagens recebidas. Não é possível desfazer.';

  @override
  String get channels_timeNow => 'agora';

  @override
  String channels_timeMinutes(int minutes) {
    return '${minutes}min';
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
    return 'CH $index';
  }

  @override
  String get reaction_unknownSender => 'Desconhecido';

  @override
  String get pathMap_noSelfGpsFix => 'O nó local não tem sinal de GPS';

  @override
  String pathTrace_sendFailed(String error) {
    return 'Não foi possível enviar o rastreamento de caminho: $error';
  }

  @override
  String get losErrorNoInternet =>
      'Os dados de elevação precisam de conexão com a internet';

  @override
  String get losResultStale => 'Desatualizado: a altura da antena mudou';

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
  String get telemetry_loading => 'Carregando telemetria…';

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
      'Sem conexão com um rádio. Conecte e tente novamente.';

  @override
  String get settings_requiresConnection =>
      'Conecte-se a um rádio para usar isto';

  @override
  String settings_txPowerInvalidRange(int min, int max) {
    return 'Potência de TX inválida ($min a $max dBm)';
  }

  @override
  String get settings_contactSettingsSaved => 'Configurações do contato salvas';

  @override
  String get settings_batteryToggleHint =>
      'Toque para alternar entre porcentagem e tensão';

  @override
  String get settings_publicKeyCopyHint => 'Copiar chave pública';

  @override
  String get settings_locationClearHelper =>
      'Deixe ambos os campos vazios para remover sua localização.';

  @override
  String get settings_locationCleared => 'Localização removida';

  @override
  String get settings_regionFetchDiscovering =>
      'Procurando repetidores próximos…';

  @override
  String settings_regionFetchProgress(int current, int total) {
    return 'Consultando o repetidor $current de $total…';
  }

  @override
  String get settings_regionFetchNoRepeaters =>
      'Ainda não há repetidores conhecidos. Adicione um repetidor como contato ou aguarde um anunciar, e tente novamente.';

  @override
  String get settings_regionFetchNoneResponded =>
      'Nenhum repetidor próximo respondeu. Aproxime-se de um repetidor e tente novamente.';

  @override
  String appSettings_sourceSummary(String label, String description) {
    return '$label - $description';
  }

  @override
  String get appSettings_routingSection => 'Roteamento';

  @override
  String get appSettings_resetRoutingToDefault =>
      'Redefinir algoritmo de roteamento para o padrão';

  @override
  String get appSettings_resetRoutingToDefaultSubtitle =>
      'Restaurar as configurações do algoritmo de roteamento para os valores padrão de fábrica';

  @override
  String get appSettings_routingResetToDefault =>
      'Configurações do algoritmo de roteamento redefinidas para o padrão';

  @override
  String get appSettings_imageMessagesSection => 'Mensagens de imagem';

  @override
  String get appSettings_showApiKey => 'Mostrar chave de API';

  @override
  String get appSettings_hideApiKey => 'Ocultar chave de API';

  @override
  String get translation_defaultModelName => 'Modelo';

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
  String get repeater_radioDisconnected => 'Rádio desconectado';

  @override
  String get repeater_radioDisconnectedHint =>
      'Reconecte-se ao seu rádio para enviar comandos, atualizar ou salvar alterações.';

  @override
  String get repeater_cliSend => 'Enviar comando';

  @override
  String get repeater_cliCopyTranscript => 'Copiar transcrição';

  @override
  String get repeater_cliShareTranscript => 'Compartilhar transcrição';

  @override
  String get repeater_cliTranscriptCopied => 'Transcrição copiada';

  @override
  String get repeater_cliClearHistoryConfirm =>
      'Limpar o histórico de comandos? Não é possível desfazer.';

  @override
  String get repeater_cliSearchCommands => 'Pesquisar comandos';

  @override
  String get repeater_cliNoMatchingCommands => 'Nenhum comando correspondente';

  @override
  String get debugLog_clearConfirm =>
      'Limpar todas as entradas do registro? Não é possível desfazer.';

  @override
  String get repeater_unsavedChangesTitle => 'Alterações não salvas';

  @override
  String get repeater_unsavedChangesMessage =>
      'Você tem alterações que não foram salvas no repetidor.';

  @override
  String get repeater_discardChanges => 'Descartar';

  @override
  String repeater_actionSentNoReply(String action) {
    return '$action: comando enviado. O repetidor não responde a este comando.';
  }

  @override
  String repeater_invalidSettingValue(String setting, String value) {
    return '$setting: $value não é válido';
  }

  @override
  String repeater_prvKeyLengthError(int length) {
    return 'A chave privada deve ter exatamente $length caracteres hexadecimais';
  }

  @override
  String get contacts_advertFailed => 'Não foi possível enviar o anúncio';

  @override
  String get contacts_manageGroups => 'Gerenciar grupos';

  @override
  String contacts_keyPrefixSemantics(String prefix) {
    return 'Prefixo da chave $prefix';
  }

  @override
  String community_shortId(String id) {
    return 'ID: $id…';
  }

  @override
  String get tcpSectionTitle => 'TCP / IP';

  @override
  String get tcpConnectedToHeader => 'Conectado a';

  @override
  String get usbChooseSerialPort => 'Escolher porta serial';

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
  String get networkMap_settingsSection => 'Mapa da rede';

  @override
  String get networkMap_uploadTitle => 'Compartilhar o que meu rádio ouve';

  @override
  String get networkMap_uploadExplanation =>
      'Quando isto está ativado e o seu rádio está conectado, o app envia um breve resumo dos pacotes que o seu rádio ouve para o mapa da rede do MeshCore Open, para que todos possam ver quais repetidores existem e como se conectam. Ele envia o tipo, a rota, os saltos, a intensidade do sinal e o tamanho de cada pacote, além dos nomes e localizações aproximadas dos repetidores, obtidos dos próprios anúncios. Nunca envia o texto das mensagens, quem fala com quem, nomes de canais, seus contatos nem a sua posição exata: as localizações são arredondadas para cerca de 2 km, e o seu app recebe um novo ID aleatório todos os dias.';

  @override
  String get networkMap_whatWeCollect => 'O que coletamos';

  @override
  String get networkMap_promptTitle => 'Ajudar a construir o mapa da rede?';

  @override
  String get networkMap_promptBody =>
      'O MeshCore Open pode compartilhar o que o seu rádio ouve com o mapa público da rede em map.meshcoreopen.org, para que todos possam ver quais repetidores existem e como se conectam.\n\nNunca envia o texto das mensagens, quem fala com quem, nomes de canais, seus contatos nem a sua posição exata. As localizações são arredondadas para cerca de 2 km.';

  @override
  String get networkMap_promptSettingsHint =>
      'Você pode mudar isso a qualquer momento em Configurações → Configurações do App → Mapa da rede.';

  @override
  String get networkMap_promptAccept => 'Compartilhar';

  @override
  String get networkMap_promptDecline => 'Não, obrigado';

  @override
  String get networkMap_statusOff => 'Desativado. Nada é enviado.';

  @override
  String get networkMap_statusWaiting =>
      'Ativado. Aguardando conexão com o rádio.';

  @override
  String get networkMap_statusNothingSent => 'Ativado. Nada enviado ainda.';

  @override
  String networkMap_statusLastSent(String time, int count) {
    return 'Último envio $time. $count pacotes hoje.';
  }

  @override
  String get networkMap_sourceLocal => 'Local';

  @override
  String get networkMap_sourceOnline => 'Online';

  @override
  String get networkMap_sourceBoth => 'Ambos';

  @override
  String get networkMap_sourceLocalHint => 'Nós que o seu rádio ouviu';

  @override
  String get networkMap_sourceOnlineHint =>
      'Repetidores do mapa de rede online';

  @override
  String get networkMap_sourceBothHint =>
      'Os nós do seu rádio mais o mapa de rede online';

  @override
  String get networkMap_zoomInHint =>
      'Aproxime o zoom para ver o mapa da rede online';

  @override
  String get networkMap_loadFailed =>
      'Não foi possível carregar o mapa da rede online';

  @override
  String get networkMap_inYourContacts => 'Nos seus contatos';

  @override
  String get networkMap_status => 'Estado';

  @override
  String get networkMap_statusActive => 'Ativo na última hora';

  @override
  String get networkMap_statusRecent => 'Ouvido no último dia';

  @override
  String get networkMap_statusStale => 'Não ouvido recentemente';

  @override
  String get networkMap_confirmed => 'Confirmado';

  @override
  String get networkMap_singleSource => 'Fonte única, ainda não confirmado';

  @override
  String get networkMap_reports => 'Relatórios';

  @override
  String get networkMap_locationEstimated =>
      'Localização aproximada, estimada a partir de quem o ouviu';

  @override
  String get networkMap_locationAdvertised =>
      'Localização aproximada, do próprio anúncio';

  @override
  String get networkMap_heardByRadio => 'Ouvido pelo seu rádio';

  @override
  String get networkMap_inYourArea => 'Na sua área';

  @override
  String get networkMap_farAway => 'Muito longe. A gestão não chegará até ele.';

  @override
  String get networkMap_addToContacts => 'Adicionar aos contatos';

  @override
  String get networkMap_manage => 'Gerenciar';

  @override
  String get networkMap_addedToContacts => 'Adicionado aos contatos';

  @override
  String get networkMap_addFailed => 'Não foi possível adicionar aos contatos';

  @override
  String get networkMap_unnamed => 'Repetidor sem nome';

  @override
  String get holidayGreeting_halloween =>
      'Feliz Halloween|Feliz Dia das Bruxas|Feliz Dia de Halloween|Doce ou travessura';

  @override
  String get holidayGreeting_thanksgiving =>
      'Feliz Dia de Ação de Graças|Feliz Thanksgiving|Feliz Ação de Graças|Feliz Dia de Graças';

  @override
  String get holidayGreeting_christmas =>
      'Feliz Natal|Boas Festas|Boas Festas de Natal|Feliz Natal e Boas Festas|Merry Christmas';

  @override
  String get holidayGreeting_newYear =>
      'Feliz Ano Novo|Próspero Ano Novo|Feliz Ano|Feliz Réveillon|Boas Festas e Feliz Ano Novo|Happy New Year';

  @override
  String get chat_loadOlderMessages => 'Carregar mensagens mais antigas';

  @override
  String get messageFilter_title => 'Filtro de mensagens';

  @override
  String get messageFilter_settingsSubtitle =>
      'Oculta mensagens de spam e repetidas';

  @override
  String get messageFilter_enabled => 'Filtrar mensagens';

  @override
  String get messageFilter_enabledSubtitle => 'Aplica-se às mensagens de canal';

  @override
  String get messageFilter_displayTitle => 'Mensagens filtradas';

  @override
  String get messageFilter_displayPlaceholder => 'Mostrar um aviso pequeno';

  @override
  String get messageFilter_displayHide => 'Ocultar completamente';

  @override
  String get messageFilter_displayHideHelp =>
      'As mensagens ocultas continuam na lista de Mensagens filtradas.';

  @override
  String get messageFilter_rulesSection => 'Suas regras';

  @override
  String get messageFilter_rulesEmpty =>
      'Ainda não há regras. Adicione uma palavra, frase ou nome de remetente para ocultar as mensagens que correspondam.';

  @override
  String get messageFilter_addRule => 'Adicionar regra';

  @override
  String get messageFilter_editRule => 'Editar regra';

  @override
  String get messageFilter_rulePattern => 'Palavra, frase ou nome';

  @override
  String get messageFilter_rulePatternHint => 'ex.: meshos';

  @override
  String get messageFilter_ruleWhere => 'Procurar em';

  @override
  String get messageFilter_ruleFieldText => 'Texto da mensagem';

  @override
  String get messageFilter_ruleFieldSender => 'Nome do remetente';

  @override
  String get messageFilter_ruleFieldBoth => 'Ambos';

  @override
  String get messageFilter_ruleMatch => 'Correspondência';

  @override
  String get messageFilter_ruleMatchContains => 'Contém';

  @override
  String get messageFilter_ruleMatchWholeWord => 'Palavra inteira';

  @override
  String get messageFilter_ruleMatchExact => 'Exata';

  @override
  String get messageFilter_ruleDeleted => 'Regra excluída';

  @override
  String get messageFilter_ruleSaved => 'Regra salva';

  @override
  String get messageFilter_automaticSection => 'Automático';

  @override
  String get messageFilter_duplicates => 'Mensagens repetidas';

  @override
  String get messageFilter_duplicatesSubtitle =>
      'A mesma mensagem enviada de novo, ou por vários remetentes';

  @override
  String get messageFilter_repeatSends => 'Envios que contam como repetição';

  @override
  String messageFilter_repeatSendsSubtitle(int count) {
    return 'Ocultar uma mensagem quando o mesmo remetente a envia $count vezes em 10 minutos';
  }

  @override
  String get messageFilter_repeatedCharacters => 'Caracteres repetidos';

  @override
  String get messageFilter_repeatedCharactersSubtitle =>
      'Sequências longas de um mesmo caractere, como \"aaaaaaaaaaaaaaaaaaaa\"';

  @override
  String get messageFilter_learning => 'Aprender com os toques em Spam';

  @override
  String messageFilter_learningSubtitle(int spam, int notSpam) {
    return '$spam exemplos de spam e $notSpam de não spam';
  }

  @override
  String get messageFilter_resetLearning => 'Redefinir aprendizado';

  @override
  String get messageFilter_resetLearningConfirm =>
      'Esquecer tudo o que foi aprendido com seus toques em Spam e Não é spam? Suas regras são mantidas.';

  @override
  String messageFilter_filteredMessages(int count) {
    return 'Mensagens filtradas ($count)';
  }

  @override
  String get messageFilter_filteredMessagesEmpty => 'Nada foi filtrado.';

  @override
  String get messageFilter_ghostSingle => 'Mensagem oculta · Toque para ver';

  @override
  String messageFilter_ghostMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens ocultas · Toque para ver',
      one: '$count mensagem oculta · Toque para ver',
    );
    return '$_temp0';
  }

  @override
  String get messageFilter_ghostSingleExpanded =>
      'Mostrando mensagem oculta · Toque para ocultar';

  @override
  String messageFilter_ghostManyExpanded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrando $count mensagens ocultas · Toque para ocultar',
      one: 'Mostrando 1 mensagem oculta · Toque para ocultar',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_reasonTextRule(String pattern) {
    return 'Filtrada: corresponde a \"$pattern\"';
  }

  @override
  String messageFilter_reasonSenderRule(String pattern) {
    return 'Filtrada: remetente \"$pattern\"';
  }

  @override
  String get messageFilter_reasonRepeatedCharacters =>
      'Filtrada: caracteres repetidos';

  @override
  String get messageFilter_reasonDuplicate => 'Filtrada: mensagem repetida';

  @override
  String get messageFilter_reasonCrossSenderDuplicate =>
      'Filtrada: a mesma mensagem de vários remetentes';

  @override
  String get messageFilter_reasonLearned =>
      'Filtrada: parece mensagens que você marcou como spam';

  @override
  String get messageFilter_reasonManual => 'Filtrada: você a marcou como spam';

  @override
  String get messageFilter_notSpam => 'Não é spam';

  @override
  String get messageFilter_hideAgain => 'Ocultar';

  @override
  String get messageFilter_markSpam => 'Marcar como spam';

  @override
  String get messageFilter_markedSpam => 'Marcada como spam';

  @override
  String get messageFilter_markedNotSpam => 'Marcada como não spam';

  @override
  String get messageFilter_filterSender => 'Filtrar este remetente';

  @override
  String messageFilter_filterSenderConfirm(String name) {
    return 'Ocultar todas as mensagens de \"$name\"?';
  }

  @override
  String get messageFilter_filterLikeThis => 'Filtrar mensagens como esta…';

  @override
  String get messageFilter_channelToggle => 'Filtrar mensagens neste canal';

  @override
  String get messageFilter_ghostIconTooltip =>
      'Oculta pelo seu filtro de mensagens';

  @override
  String appBar_offlineSubtitle(String name) {
    return 'Offline · $name';
  }

  @override
  String get appBar_offline => 'Offline';

  @override
  String get appBar_reconnecting => 'Reconectando…';

  @override
  String get connectSheet_title => 'Conectar um rádio';

  @override
  String connectSheet_reconnect(String name) {
    return 'Reconectar a $name';
  }

  @override
  String get connectSheet_chooseRadio => 'Escolher um rádio';

  @override
  String get connectSheet_chooseRadioSubtitle => 'Bluetooth, USB ou TCP';

  @override
  String get connectSheet_stopReconnecting => 'Parar de reconectar';

  @override
  String connectSheet_reconnectFailed(String name) {
    return 'Não foi possível alcançar $name. Verifique se está ligado e por perto.';
  }

  @override
  String get chat_composerOffline =>
      'Conecte-se a um rádio para enviar mensagens';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class AppLocalizationsPtPt extends AppLocalizationsPt {
  AppLocalizationsPtPt() : super('pt_PT');

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
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Ligar';

  @override
  String get common_unknownDevice => 'Dispositivo desconhecido';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_deleteAll => 'Eliminar tudo';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_done => 'Concluído';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_add => 'Adicionar';

  @override
  String get common_settings => 'Definições';

  @override
  String get common_disconnect => 'Desligar';

  @override
  String get common_connected => 'Ligado';

  @override
  String get common_disconnected => 'Desligado';

  @override
  String get common_create => 'Criar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_share => 'Partilhar';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_retry => 'Repetir';

  @override
  String get common_hide => 'Ocultar';

  @override
  String get common_remove => 'Remover';

  @override
  String get common_enable => 'Ativar';

  @override
  String get common_disable => 'Desativar';

  @override
  String get common_undo => 'Anular';

  @override
  String get messageStatus_sent => 'Enviada';

  @override
  String get messageStatus_delivered =>
      'Entregue. O contacto confirmou a receção.';

  @override
  String get messageStatus_pending => 'A enviar';

  @override
  String get messageStatus_failed => 'Falha no envio';

  @override
  String get messageStatus_repeated => 'Repetição ouvida';

  @override
  String get messageStatus_failedChannel =>
      'O seu rádio não conseguiu enviar esta mensagem.';

  @override
  String messageStatus_resending(int resends, int maxResends) {
    return 'Ainda não foi ouvida através de repetidores suficientes. Reenviada $resends de $maxResends vezes.';
  }

  @override
  String messageStatus_hopsNotReached(int hops, int required) {
    return 'Enviada, mas só ouvida de volta através de $hops de $required repetidores. Pode ter chegado mais longe do que o seu rádio consegue ouvir.';
  }

  @override
  String get messageStatus_sentChannel =>
      'Enviada. Os canais não confirmam a entrega, por isso isto só significa que o seu rádio a enviou.';

  @override
  String get messageStatus_sentDirect =>
      'Enviada. A aguardar confirmação do contacto.';

  @override
  String messageStatus_heardRepeatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: 'uma vez',
    );
    return 'Repetição ouvida $_temp0. Os repetidores próximos retransmitiram-na.';
  }

  @override
  String get urlImage_enable => 'Ativar imagens de URL';

  @override
  String get urlImage_possible =>
      'Possível imagem de URL; ative-a nas Definições.';

  @override
  String get urlImage_disabledInAppSettings =>
      'Desativado nas definições da app';

  @override
  String get common_reboot => 'Reiniciar';

  @override
  String get common_loading => 'A carregar...';

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
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Ligar por TCP';

  @override
  String get tcpHostLabel => 'Endereço';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => 'Porta';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Introduza o endereço e ligue';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'A ligar a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'O anfitrião é obrigatório.';

  @override
  String get tcpErrorPortInvalid => 'A porta tem de estar entre 1 e 65535.';

  @override
  String get tcpErrorUnsupported =>
      'O transporte TCP não é suportado nesta plataforma.';

  @override
  String get tcpErrorTimedOut => 'A ligação TCP excedeu o tempo limite.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Falha na ligação TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Ligar por USB';

  @override
  String get usbScreenSubtitle =>
      'Escolha um dispositivo série detetado e ligue-se diretamente ao seu nó MeshCore.';

  @override
  String get usbScreenStatus => 'Selecione um dispositivo USB';

  @override
  String get usbScreenNote =>
      'O USB série está ativo em dispositivos Android compatíveis e em plataformas de computador.';

  @override
  String get usbScreenEmptyState =>
      'Nenhum dispositivo USB encontrado. Ligue um e atualize.';

  @override
  String get usbErrorPermissionDenied => 'A permissão USB foi recusada.';

  @override
  String get usbErrorDeviceMissing =>
      'O dispositivo USB selecionado já não está disponível.';

  @override
  String get usbErrorInvalidPort => 'Selecione um dispositivo USB válido.';

  @override
  String get usbErrorBusy => 'Já existe outro pedido de ligação USB em curso.';

  @override
  String get usbErrorNotConnected => 'Nenhum dispositivo USB está ligado.';

  @override
  String get usbErrorOpenFailed =>
      'Falha ao abrir o dispositivo USB selecionado.';

  @override
  String get usbErrorConnectFailed =>
      'Falha ao ligar ao dispositivo USB selecionado.';

  @override
  String get usbErrorUnsupported =>
      'O USB série não é suportado nesta plataforma.';

  @override
  String get usbErrorAlreadyActive => 'Já existe uma ligação USB ativa.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Nenhum dispositivo USB foi selecionado.';

  @override
  String get usbErrorPortClosed => 'A ligação USB não está aberta.';

  @override
  String get usbErrorConnectTimedOut =>
      'A ligação excedeu o tempo limite. Confirme que o dispositivo tem firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Dispositivo Web Serial';

  @override
  String get usbStatus_notConnected => 'Selecione um dispositivo USB';

  @override
  String get usbStatus_connecting => 'A ligar ao dispositivo USB...';

  @override
  String get usbStatus_searching => 'A procurar dispositivos USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Falha na ligação USB: $error';
  }

  @override
  String get scanner_scanning => 'A procurar dispositivos...';

  @override
  String get scanner_connecting => 'A ligar...';

  @override
  String get scanner_disconnecting => 'A desligar...';

  @override
  String get scanner_notConnected => 'Não ligado';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Ligado a $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'A procurar dispositivos MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Toque em Procurar para encontrar dispositivos MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Falha na ligação: $error';
  }

  @override
  String get scanner_stop => 'Parar';

  @override
  String get scanner_scan => 'Procurar';

  @override
  String get scanner_bluetoothOff => 'O Bluetooth está desligado';

  @override
  String get scanner_bluetoothOffMessage =>
      'Ative o Bluetooth para procurar dispositivos';

  @override
  String get scanner_chromeRequired => 'Browser Chrome necessário';

  @override
  String get scanner_chromeRequiredMessage =>
      'Esta aplicação web requer o Google Chrome ou um browser baseado em Chromium para suporte Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Ativar Bluetooth';

  @override
  String get scanner_getNodeTitle => 'Precisa de um novo nó?';

  @override
  String get scanner_getNodeBody =>
      'Tamanho de carteira, corre MeshCore, GPS dual-band, à prova de água, bateria para 5 dias.';

  @override
  String get scanner_getNodeAction => 'Obtenha um aqui';

  @override
  String get scanner_getNodeDisclosure =>
      'Ligação de afiliado: cada compra apoia o MeshCore Open.';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'O Bluetooth não está disponível no browser. Ligue por USB.';

  @override
  String get device_quickSwitch => 'Troca rápida';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Definições';

  @override
  String get settings_deviceInfo => 'Info do dispositivo';

  @override
  String get settings_appSettings => 'Definições da app';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificações, mensagens e preferências do mapa';

  @override
  String get settings_export => 'Exportar';

  @override
  String get settings_exportSubtitle =>
      'Exportar contactos e repetidores como GPX';

  @override
  String get backupRestore_title => 'Cópia e restauro';

  @override
  String get backupRestore_subtitle =>
      'Guardar ou restaurar dados da app e definições do rádio';

  @override
  String get backupRestore_import => 'Importar';

  @override
  String get backupRestore_selectImportFile => 'Importar ficheiro';

  @override
  String get backupRestore_password => 'Palavra-passe (opcional)';

  @override
  String get backupRestore_passwordHelp =>
      'Uma palavra-passe cifra o ficheiro. Em branco, guarda texto simples que pode incluir chaves privadas/de canais, histórico e credenciais.';

  @override
  String get backupRestore_importUnavailable =>
      'Verifique a palavra-passe ou escolha um ficheiro de cópia compatível.';

  @override
  String get backupRestore_items => 'Itens da cópia e do restauro';

  @override
  String get backupRestore_nodeSettings => 'Definições do nó';

  @override
  String get backupRestore_nodeSettingsDescription =>
      'Nome do dispositivo, chaves privada e pública, definições de rádio e regiões';

  @override
  String get backupRestore_deviceName => 'Nome do dispositivo';

  @override
  String get backupRestore_privateKey => 'Chave privada (sensível)';

  @override
  String get backupRestore_publicKey => 'Chave pública';

  @override
  String get backupRestore_radioSettings => 'Definições de rádio';

  @override
  String get backupRestore_regions => 'Regiões';

  @override
  String get backupRestore_location => 'Localização';

  @override
  String get backupRestore_contactSettings => 'Definições de contactos';

  @override
  String get backupRestore_privacySettings => 'Definições de privacidade';

  @override
  String get backupRestore_contactsData => 'Contactos';

  @override
  String get backupRestore_perContactSettings =>
      'Definições e filtros de contactos';

  @override
  String get backupRestore_contactGroups => 'Grupos de contactos';

  @override
  String get backupRestore_contactHistory => 'Histórico de contactos';

  @override
  String get backupRestore_channelsData => 'Canais';

  @override
  String get backupRestore_channelFilters =>
      'Definições do filtro de mensagens';

  @override
  String get backupRestore_channelSettings => 'Definições de canais';

  @override
  String get backupRestore_communities => 'Comunidades';

  @override
  String get backupRestore_channelHistory => 'Histórico de canais';

  @override
  String get backupRestore_locationSettings => 'Definições de localização';

  @override
  String get backupRestore_locationSettingsDescription =>
      'Localização, definições de contactos e de privacidade';

  @override
  String get backupRestore_appSettings => 'Definições da app';

  @override
  String get backupRestore_appSettingsDescription =>
      'Preferências e definições de aparência da app';

  @override
  String get backupRestore_ipfsKey => 'Chave API IPFS (sensível)';

  @override
  String get backupRestore_stadiaMapKey => 'Chave API Stadia Maps (sensível)';

  @override
  String get backupRestore_contacts => 'Contactos';

  @override
  String get backupRestore_contactsDescription =>
      'Contactos, filtros e definições por contacto, grupos e histórico de mensagens';

  @override
  String get backupRestore_discoveredContacts => 'Contactos descobertos';

  @override
  String get backupRestore_discoveredContactsDescription =>
      'Contactos descobertos e os seus detalhes guardados';

  @override
  String get backupRestore_channels => 'Canais';

  @override
  String get backupRestore_channelsDescription =>
      'Canais, filtros de canais, comunidades e histórico de mensagens';

  @override
  String get backupRestore_backup => 'Criar cópia';

  @override
  String get backupRestore_restore => 'Restaurar selecionados';

  @override
  String get backupRestore_backupComplete => 'Ficheiro de cópia criado.';

  @override
  String get backupRestore_restoreComplete =>
      'Restauro concluído. Volte a ligar se restaurou a identidade do rádio.';

  @override
  String get backupRestore_missingModelsTitle => 'Modelos não transferidos';

  @override
  String backupRestore_missingModelsMessage(String models) {
    return 'As definições restauradas selecionam modelos que não estão disponíveis neste dispositivo:\n$models\n\nTransferi-los agora?';
  }

  @override
  String get backupRestore_downloadModels => 'Transferir modelos';

  @override
  String get backupRestore_downloading => 'A transferir…';

  @override
  String get backupRestore_cancelDownload => 'Cancelar transferência';

  @override
  String backupRestore_failed(String error) {
    return 'Falha na operação de cópia: $error';
  }

  @override
  String get backupRestore_fileTooLarge =>
      'O ficheiro de cópia excede o limite de 100 MB.';

  @override
  String get backupRestore_selectAtLeastOne => 'Selecione pelo menos um item.';

  @override
  String get backupRestore_replaceIdentityTitle =>
      'Substituir a identidade do rádio?';

  @override
  String get backupRestore_replaceIdentityMessage =>
      'Restaurar as Definições do nó substitui a chave privada do rádio ligado e altera a sua identidade. Continue apenas se for essa a intenção.';

  @override
  String get settings_nodeSettings => 'Definições do nó';

  @override
  String get settings_nodeName => 'Nome do nó';

  @override
  String get settings_nodeNameNotSet => 'Não definido';

  @override
  String get settings_nodeNameHint => 'Introduza o nome do nó';

  @override
  String get settings_nodeNameUpdated => 'Nome atualizado';

  @override
  String get settings_radioSettings => 'Definições de rádio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequência, potência, fator de espalhamento';

  @override
  String get settings_radioSettingsUpdated => 'Definições de rádio atualizadas';

  @override
  String get settings_radioSettingsNotApplied =>
      'O rádio não aplicou estas definições';

  @override
  String get settings_pathHashModeNotApplied =>
      'As definições de rádio foram aplicadas, mas o rádio não confirmou o novo tamanho do hash do caminho';

  @override
  String get settings_regionSettings => 'Regiões';

  @override
  String get settings_regionSettingsSubtitle =>
      'Limitar os floods de canais a uma área';

  @override
  String get settings_regionEmptyExplanation =>
      'As regiões limitam as mensagens flood a repetidores de uma área. Obtenha-as de repetidores próximos ou adicione uma pelo nome.';

  @override
  String get settings_regionFetchFromRepeaters => 'Obter de repetidores';

  @override
  String get settings_regionDefault => 'Região predefinida';

  @override
  String get settings_regionDefaultSubtitle =>
      'Usada por canais sem região própria';

  @override
  String get settings_regionDefaultNone => 'Nenhuma';

  @override
  String settings_regionUseRadioDefault(String region) {
    return 'Predefinição do rádio ($region)';
  }

  @override
  String get settings_regionNoRegion => 'Sem região (sem âmbito)';

  @override
  String get settings_regionRadioDefault => 'Região predefinida do rádio';

  @override
  String get settings_regionRadioDefaultSubtitle =>
      'Guardada no rádio. Os floods enviados sem região usam-na, a partir desta app e de qualquer outra app ligada ao rádio.';

  @override
  String get settings_regionRadioDefaultUpdated =>
      'Região predefinida do rádio atualizada';

  @override
  String get settings_regionRadioDefaultFailed =>
      'Não foi possível atualizar a região predefinida do rádio';

  @override
  String get settings_regionManagement_screenTitle => 'Gestão de regiões';

  @override
  String get settings_regionNameHint => 'Introduza o nome da região';

  @override
  String get settings_regionAddRegion => 'Adicionar região';

  @override
  String get settings_regionFetchRegions => 'Obter regiões de repetidores';

  @override
  String get settings_regionFetchRegionsFail => 'Nenhuma região encontrada';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Esta região já foi adicionada';

  @override
  String get settings_regionName => 'Nome da região';

  @override
  String get settings_regionDeleted => 'Região eliminada';

  @override
  String get settings_deleteRegion => 'Eliminar região';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Remover \"$region\" da lista de regiões?';
  }

  @override
  String get settings_location => 'Localização';

  @override
  String get settings_locationSubtitle => 'Coordenadas GPS';

  @override
  String get settings_locationUpdated =>
      'Localização e definições de GPS atualizadas';

  @override
  String get settings_locationBothRequired =>
      'Introduza a latitude e a longitude.';

  @override
  String get settings_locationInvalid => 'Latitude ou longitude inválida.';

  @override
  String get settings_locationGPSEnable => 'Ativar GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Ativa o GPS para atualizar a localização automaticamente.';

  @override
  String get settings_locationIntervalSec => 'Intervalo do GPS (segundos)';

  @override
  String get settings_locationIntervalInvalid =>
      'O intervalo tem de ser de pelo menos 60 segundos e inferior a 86400 segundos.';

  @override
  String get settings_latitude => 'Latitude';

  @override
  String get settings_longitude => 'Longitude';

  @override
  String get settings_contactSettings => 'Definições de contactos';

  @override
  String get settings_contactSettingsSubtitle =>
      'Definições de como os contactos são adicionados.';

  @override
  String get settings_privacyMode => 'Modo de privacidade';

  @override
  String get settings_privacyModeSubtitle =>
      'Ocultar nome/localização nos anúncios';

  @override
  String get settings_privacyModeToggle =>
      'Alterne o modo de privacidade para ocultar o seu nome e localização nos anúncios.';

  @override
  String get settings_privacyModeEnabled => 'Modo de privacidade ativado';

  @override
  String get settings_privacyModeDisabled => 'Modo de privacidade desativado';

  @override
  String get settings_privacy => 'Definições de privacidade';

  @override
  String get settings_privacySubtitle =>
      'Controle que informações são partilhadas.';

  @override
  String get settings_privacySettingsDescription =>
      'Escolha que informações o seu dispositivo partilha com outros.';

  @override
  String get settings_denyAll => 'Recusar todos';

  @override
  String get settings_allowByContact => 'Só contactos permitidos';

  @override
  String get settings_allowAll => 'Permitir todos';

  @override
  String get settings_telemetryBaseMode => 'Quem pode pedir bateria e estado';

  @override
  String get settings_telemetryLocationMode =>
      'Quem pode pedir a minha localização';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Quem pode pedir dados de sensores';

  @override
  String get settings_telemetryPerContactHint =>
      'Para permitir um contacto, abra a conversa e escolha Definições do contacto no menu.';

  @override
  String get settings_advertLocation => 'Localização no anúncio';

  @override
  String get settings_advertLocationSubtitle =>
      'Incluir localização no anúncio.';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Anúncio Zero Hop automático ao atualizar GPS';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Definição da app: quando a sua posição GPS muda, anuncia automaticamente a nova localização apenas a nós próximos (requer Localização no anúncio).';

  @override
  String get settings_multiAck => 'ACKs múltiplos';

  @override
  String get settings_multiAckSubtitle =>
      'Envia ACKs extra para melhor entrega; usa mais airtime';

  @override
  String get settings_telemetryModeUpdated => 'Modo de telemetria atualizado';

  @override
  String get settings_actions => 'Ações';

  @override
  String get settings_deleteAllPaths => 'Eliminar todos os caminhos';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Limpar todos os dados de caminhos dos contactos.';

  @override
  String get settings_sendAdvertisement => 'Enviar anúncio';

  @override
  String get settings_sendAdvertisementSubtitle => 'Difundir presença agora';

  @override
  String get settings_advertisementSent => 'Anúncio enviado';

  @override
  String get settings_syncTime => 'Sincronizar hora';

  @override
  String get settings_syncTimeSubtitle =>
      'Acertar o relógio do dispositivo pela hora do telemóvel';

  @override
  String get settings_timeSynchronized => 'Hora sincronizada';

  @override
  String get settings_refreshContacts => 'Atualizar contactos';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recarregar a lista de contactos do dispositivo';

  @override
  String get settings_rebootDevice => 'Reiniciar dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Reiniciar o dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Tem a certeza de que quer reiniciar o dispositivo? Será desligado.';

  @override
  String get settings_debug => 'Depuração';

  @override
  String get settings_companionDebugLog => 'Registo de depuração do Companion';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Comandos BLE/TCP/USB, respostas e dados brutos';

  @override
  String get settings_appDebugLog => 'Registo de depuração da app';

  @override
  String get settings_appDebugLogSubtitle =>
      'Mensagens de depuração da aplicação';

  @override
  String get settings_about => 'Acerca de';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore Open Source Project';

  @override
  String get settings_aboutDescription =>
      'Um cliente Flutter de código aberto para dispositivos de rede mesh LoRa MeshCore.';

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
  String get settings_infoPublicKey => 'Chave pública';

  @override
  String get settings_publicKeyCopied => 'Chave pública copiada';

  @override
  String get settings_infoContactsCount => 'N.º de contactos';

  @override
  String get settings_infoChannelCount => 'N.º de canais';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

  @override
  String get settings_presets => 'Predefinições';

  @override
  String get settings_presetCustom => 'Personalizado';

  @override
  String get settings_radioMatchWarning =>
      'Todos os nós com que comunica têm de usar a mesma frequência, largura de banda e SF. O coding rate (CR) pode ser diferente.';

  @override
  String get settings_frequency => 'Frequência (MHz)';

  @override
  String get settings_frequencyHelper => '150.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Frequência inválida (150-2500 MHz)';

  @override
  String get settings_bandwidth => 'Largura de banda';

  @override
  String get settings_spreadingFactor => 'Fator de espalhamento';

  @override
  String get settings_codingRate => 'Coding Rate';

  @override
  String get settings_txPower => 'Potência TX (dBm)';

  @override
  String settings_txPowerRangeHelper(int min, int max) {
    return '$min a $max dBm';
  }

  @override
  String get settings_txPowerInvalid => 'Potência TX inválida';

  @override
  String get settings_clientRepeat => 'Repetição off-grid';

  @override
  String settings_clientRepeatFrequencyNote(String freq) {
    return 'Frequência definida para $freq MHz para repetição off-grid';
  }

  @override
  String get settings_clientRepeatSubtitle =>
      'Permitir que este dispositivo repita pacotes mesh para outros';

  @override
  String get settings_clientRepeatFreqWarning =>
      'A repetição off-grid requer a frequência 433, 869.495 ou 918 MHz';

  @override
  String settings_error(String message) {
    return 'Erro: $message';
  }

  @override
  String get appSettings_title => 'Definições da app';

  @override
  String get appSettings_appearance => 'Aparência';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Predefinição do sistema';

  @override
  String get appSettings_themeLight => 'Claro';

  @override
  String get appSettings_themeDark => 'Escuro';

  @override
  String get appSettings_colorTheme => 'Tema de cores';

  @override
  String get appSettings_holidayAnimations => 'Animações de mensagens festivas';

  @override
  String get appSettings_holidayAnimationsSubtitle =>
      'Morcegos, um peru, o Pai Natal ou fogo de artifício quando alguém envia uma saudação festiva';

  @override
  String get themes_title => 'Temas';

  @override
  String get themes_default => 'MeshCore';

  @override
  String get themes_defaultSubtitle =>
      'Cores padrão, segue a definição Claro / Escuro';

  @override
  String get themes_builtIn => 'Incluídos';

  @override
  String get themes_holidays => 'Festividades';

  @override
  String get themes_holidayAutoSwitch => 'Mudar automaticamente';

  @override
  String get themes_holidayAutoSwitchSubtitle =>
      'Usa o tema de cada festividade desde 17 dias antes até ao próprio dia';

  @override
  String themes_holidayAutoApplied(String holiday) {
    return 'O tema $holiday está ativo automaticamente. O seu tema volta depois da festividade.';
  }

  @override
  String get themes_holidayAutoAppliedTag => 'Automático';

  @override
  String get themes_myThemes => 'Os meus temas';

  @override
  String get themes_myThemesEmpty =>
      'Crie o seu tema escolhendo um fundo e uma cor de destaque.';

  @override
  String get themes_create => 'Criar tema';

  @override
  String get themes_import => 'Importar tema';

  @override
  String get themes_importHint => 'Cole um código de tema';

  @override
  String get themes_importInvalid => 'Esse não é um código de tema válido';

  @override
  String themes_imported(String name) {
    return 'Tema \"$name\" adicionado';
  }

  @override
  String get themes_customize => 'Personalizar uma cópia';

  @override
  String get themes_copyCode => 'Copiar código do tema';

  @override
  String get themes_codeCopied => 'Código do tema copiado';

  @override
  String themes_deleteConfirm(String name) {
    return 'Eliminar o tema \"$name\"?';
  }

  @override
  String themes_copyName(String name) {
    return 'Cópia de $name';
  }

  @override
  String get themes_newTitle => 'Novo tema';

  @override
  String get themes_editTitle => 'Editar tema';

  @override
  String get themes_name => 'Nome';

  @override
  String get themes_nameRequired => 'Dê um nome ao seu tema';

  @override
  String get themes_background => 'Fundo';

  @override
  String get themes_backgroundHelp => 'Um fundo escuro cria um tema escuro';

  @override
  String get themes_accent => 'Destaque';

  @override
  String get themes_accentHelp =>
      'Botões, realces e os seus balões de conversa';

  @override
  String get themes_hexColor => 'Cor hexadecimal';

  @override
  String get themes_preview => 'Pré-visualização';

  @override
  String get themes_previewIncoming => 'Alguém na mesh esta noite?';

  @override
  String get themes_previewOutgoing => 'Alto e claro!';

  @override
  String get themes_previewSwitch => 'Notificações';

  @override
  String get themes_lowContrast => 'O destaque vê-se mal neste fundo';

  @override
  String get themes_saveAndUse => 'Guardar e usar';

  @override
  String get themes_icons => 'Ícones';

  @override
  String get themes_iconsHelp =>
      'Toque num ícone para o trocar por outro ícone ou pela sua própria imagem';

  @override
  String get themes_iconChanged => 'Alterado';

  @override
  String get themes_iconSend => 'Botão de enviar';

  @override
  String get themes_iconRepeater => 'Repetidores';

  @override
  String get themes_iconRoom => 'Salas';

  @override
  String get themes_iconSensor => 'Sensores';

  @override
  String get themes_mapMarkers => 'Marcadores do mapa';

  @override
  String get themes_mapMarkersHelp =>
      'Troque os marcadores dos nós e o seu próprio no mapa';

  @override
  String get themes_iconUsePicture => 'Usar uma imagem';

  @override
  String get themes_iconReset => 'Usar o ícone predefinido';

  @override
  String get themes_iconPictureFailed => 'Não foi possível usar essa imagem';

  @override
  String get themes_exportFile => 'Exportar para ficheiro';

  @override
  String get themes_exportAll => 'Exportar os meus temas';

  @override
  String get themes_importFile => 'Importar de ficheiro';

  @override
  String get themes_pasteCode => 'Colar código do tema';

  @override
  String get themes_exportFailed => 'Não foi possível exportar os temas';

  @override
  String themes_importFileResult(int count) {
    return '$count temas importados';
  }

  @override
  String get themes_importFileNone => 'Nenhum tema encontrado nesse ficheiro';

  @override
  String get chatBackground_title => 'Fundo da conversa';

  @override
  String get chatBackground_thisChatOnly => 'Só para esta conversa';

  @override
  String chatBackground_themeOverrides(String name) {
    return 'O seu tema \"$name\" define o fundo em todas as conversas. Desative isso no tema para usar este.';
  }

  @override
  String get chatBackground_none => 'Nenhum';

  @override
  String get chatBackground_picture => 'Imagem';

  @override
  String get chatBackground_choosePicture => 'Escolher uma imagem';

  @override
  String get chatBackground_pictureFailed =>
      'Não foi possível usar essa imagem';

  @override
  String get chatBackground_fade => 'Esbatimento';

  @override
  String get themes_chatBackground => 'Fundo da conversa';

  @override
  String get themes_chatBackgroundHelp =>
      'Mostrado nas conversas sem fundo próprio';

  @override
  String get themes_chatBackgroundEverywhere => 'Usar em todas as conversas';

  @override
  String get themes_chatBackgroundEverywhereHelp =>
      'Também substitui os fundos definidos em conversas individuais';

  @override
  String get appSettings_language => 'Idioma';

  @override
  String get appSettings_languageSystem => 'Predefinição do sistema';

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
  String get appSettings_languagePt => 'Português (Brasil)';

  @override
  String get appSettings_languagePtPt => 'Português (Portugal)';

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
  String get appSettings_languageRu => 'Русский';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get appSettings_languageCs => 'Čeština';

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
      'Tamanho de cada ID de nó registado no caminho dos pacotes flood enviados por este rádio: 1 byte (256 IDs, até 64 hops), 2 bytes (65K IDs, até 32 hops), 3 bytes (16M IDs, até 21 hops). IDs maiores reduzem colisões, mas os repetidores com firmware anterior à v1.14 descartam pacotes com IDs de 2 ou 3 bytes.';

  @override
  String settings_requiresFirmware(String version) {
    return 'Requer firmware $version ou posterior';
  }

  @override
  String get appSettings_channelMinHops =>
      'Reenviar mensagens de canal até viajarem o suficiente';

  @override
  String get appSettings_channelMinHopsSubtitle =>
      'Se a sua mensagem não for ouvida de volta através de repetidores suficientes, é enviada novamente. Usa mais airtime.';

  @override
  String appSettings_channelMinHopsCount(int count) {
    return 'Hops necessários: $count';
  }

  @override
  String appSettings_channelMinHopsRetries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: '1 vez',
    );
    return 'Reenviar até $_temp0';
  }

  @override
  String get appSettings_channelMinHopsCountRepeaters =>
      'Contar também repetidores próximos diferentes';

  @override
  String appSettings_channelMinHopsCountRepeatersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repetidores próximos diferentes',
      one: '1 repetidor próximo',
    );
    return 'Considera a mensagem enviada quando $_temp0 a repetem, mesmo que não a ouça viajar mais longe.';
  }

  @override
  String get appSettings_enableMessageTracing =>
      'Mostrar caminho completo de repetidores nas mensagens';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostra também contagens de repetições e tempos de viagem. Prima longamente uma mensagem e escolha Caminho para ver todos os detalhes.';

  @override
  String get appSettings_regionOnHopsLine => 'Região junto aos hops';

  @override
  String get appSettings_regionOnHopsLineSubtitle =>
      'Mostra a região de uma mensagem de canal na mesma linha que o número de hops, em vez de por baixo.';

  @override
  String get appSettings_notifications => 'Notificações';

  @override
  String get appSettings_enableNotifications => 'Ativar notificações';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Receber notificações de mensagens e anúncios';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permissão de notificações recusada';

  @override
  String get appSettings_notificationsEnabled => 'Notificações ativadas';

  @override
  String get appSettings_notificationsDisabled => 'Notificações desativadas';

  @override
  String get appSettings_messageNotifications => 'Notificações de mensagens';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostrar notificação ao receber novas mensagens';

  @override
  String get appSettings_batteryOptimization => 'Atividade em segundo plano';

  @override
  String get appSettings_batteryOptimizationSubtitle =>
      'Defina o MeshCore Open como \"Não otimizar\" nas definições de bateria para as mensagens continuarem a chegar em segundo plano';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notificações de mensagens de canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostrar notificação ao receber mensagens de canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notificações de anúncios';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostrar notificação quando são descobertos novos nós';

  @override
  String get appSettings_messaging => 'Mensagens';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Limpar caminho no máx. de tentativas';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Repor o caminho do contacto após 5 tentativas de envio falhadas';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Os caminhos serão limpos após 5 tentativas falhadas';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Os caminhos não serão limpos automaticamente';

  @override
  String get appSettings_autoRouteRotation => 'Rotação automática de rotas';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Alterna entre os melhores caminhos e o modo flood';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Rotação automática de rotas ativada';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Rotação automática de rotas desativada';

  @override
  String get appSettings_maxMessageRetries => 'Máx. de tentativas por mensagem';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Número de tentativas antes de marcar uma mensagem como falhada';

  @override
  String get appSettings_ipfsImageLinks => 'Configuração do fornecedor IPFS';

  @override
  String get appSettings_ipfsImageLinksSubtitle =>
      'Carregar imagens (ou ficheiros) por URL através de um fornecedor IPFS e gateway predefinido para receber';

  @override
  String get appSettings_loadLinkImages => 'Carregar imagens de ligações';

  @override
  String get appSettings_loadLinkImagesSubtitle =>
      'Mostra imagens de ligações nas mensagens. Carregar uma imagem partilha o seu endereço IP com o site que a aloja.';

  @override
  String get appSettings_showLinkImagesByDefault =>
      'Mostrar imagens de ligações em todas as conversas por predefinição';

  @override
  String get appSettings_showLinkImagesByDefaultSubtitle =>
      'Carrega imagens de ligações em todas as conversas, exceto onde as desativou. Isto partilha o seu endereço IP com os anfitriões das imagens em todas as conversas.';

  @override
  String get appSettings_publicIpfsGateway => 'Gateway público';

  @override
  String get appSettings_ipfsGatewayDeactivated => 'Desativado';

  @override
  String get appSettings_ipfsGatewayCustom => 'Personalizado (Kubo)';

  @override
  String get appSettings_uploadIpfsProvider => 'Fornecedor de carregamento';

  @override
  String get appSettings_uploadIpfsGateway => 'Gateway de carregamento';

  @override
  String get appSettings_uploadIpfsGatewaySubtitle =>
      'Gateway para partilhar imagem ou ficheiro como ligação URL. Deixe vazio para usar o formato ipfs:, que outros clientes podem não abrir.';

  @override
  String get appSettings_uploadIpfsEndpoint => 'Endpoint de carregamento';

  @override
  String get appSettings_uploadIpfsEndpointSubtitle =>
      'O endpoint da API usado para carregar ficheiros';

  @override
  String get appSettings_uploadIpfsApiKey => 'Chave API de carregamento';

  @override
  String get appSettings_ipfsImageLinksDescription =>
      'O gateway público transfere imagens no formato ipfs:. O gateway de carregamento é usado para gerar ligações de partilha de imagens ou ficheiros por URL carregados.';

  @override
  String get appSettings_battery => 'Bateria';

  @override
  String get appSettings_batteryChemistry => 'Química da bateria';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Definido por dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Ligue a um dispositivo para escolher';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_batteryLipoHv => 'LiPo HV (3.0-4.35V)';

  @override
  String get appSettings_mapDisplay => 'Apresentação do mapa';

  @override
  String get appSettings_showRepeaters => 'Mostrar repetidores';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Mostrar nós repetidores no mapa';

  @override
  String get appSettings_showChatNodes => 'Mostrar nós de chat';

  @override
  String get appSettings_showChatNodesSubtitle => 'Mostrar nós de chat no mapa';

  @override
  String get appSettings_showOtherNodes => 'Mostrar outros nós';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mostrar outros tipos de nós no mapa';

  @override
  String get appSettings_showOnlineLinks => 'Mostrar ligações do mapa online';

  @override
  String get appSettings_showOnlineLinksSubtitle =>
      'Mostrar linhas de ligação entre nós do mapa online';

  @override
  String get appSettings_timeFilter => 'Filtro de tempo';

  @override
  String get appSettings_timeFilterShowAll => 'Mostrar todos os nós';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostrar nós das últimas $hours horas';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro de tempo do mapa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostrar nós descobertos nos últimos:';

  @override
  String get appSettings_allTime => 'Sempre';

  @override
  String get appSettings_lastHour => 'Última hora';

  @override
  String get appSettings_last6Hours => 'Últimas 6 horas';

  @override
  String get appSettings_last24Hours => 'Últimas 24 horas';

  @override
  String get appSettings_lastWeek => 'Última semana';

  @override
  String get appSettings_rasterTileSource => 'Origem dos tiles raster';

  @override
  String get appSettings_stadiaEndpoint => 'Endpoint Stadia';

  @override
  String get appSettings_stadiaApiKey => 'Chave API Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Necessária para usar o Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Configurada: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Introduza a sua chave API do Stadia Maps. Esta app usa-a para pedidos de tiles raster.';

  @override
  String get appSettings_offlineMapCache => 'Cache do mapa offline';

  @override
  String get appSettings_unitsTitle => 'Unidades';

  @override
  String get appSettings_unitsMetric => 'Métrico (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Nenhuma área selecionada';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Área selecionada (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Depuração';

  @override
  String get appSettings_appDebugLogging => 'Registo de depuração da app';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Registar mensagens de depuração da app para resolução de problemas';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Registo de depuração da app ativado';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Registo de depuração da app desativado';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_noContacts => 'Ainda sem contactos';

  @override
  String get contacts_contactsWillAppear =>
      'Os contactos aparecem quando os dispositivos enviarem anúncios';

  @override
  String get contacts_unread => 'Não lidas';

  @override
  String get contacts_searchContactsNoNumber => 'Pesquisar contactos...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Pesquisar $number$str contactos...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Pesquisar $number$str favoritos...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Pesquisar $number$str utilizadores...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Pesquisar $number$str repetidores...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Pesquisar $number$str room servers...';
  }

  @override
  String get contacts_noUnreadContacts => 'Nenhum contacto por ler';

  @override
  String get contacts_noContactsFound => 'Nenhum contacto ou grupo encontrado';

  @override
  String get contacts_storageFull =>
      'O armazenamento de contactos do nó está cheio. Não é possível adicionar novos nós até remover contactos.';

  @override
  String get contacts_deleteContact => 'Eliminar contacto';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Remover $contactName dos contactos?';
  }

  @override
  String get contacts_removeFromContacts => 'Remover dos contactos';

  @override
  String contacts_removeFromContactsConfirm(String contactName) {
    return '$contactName passará para os contactos descobertos. O histórico de conversa será eliminado.';
  }

  @override
  String get contacts_keepChatHistory => 'Manter histórico de conversa';

  @override
  String get contacts_remove => 'Remover';

  @override
  String get contacts_removeAutoAddNote =>
      'O seu rádio adiciona automaticamente este tipo de contacto, por isso voltará na próxima vez que enviar um anúncio. Desative a adição automática nas definições de Contactos para o manter removido.';

  @override
  String get contacts_removeFailed =>
      'O rádio não confirmou a remoção. O contacto não foi removido.';

  @override
  String contacts_discoveredNearby(int count) {
    return 'Descobertos nas proximidades ($count)';
  }

  @override
  String get contacts_noContactsDiscoveredHint =>
      'Os nós que o seu rádio ouve mas ainda não adicionou aparecem em Contactos descobertos';

  @override
  String get contacts_manageRepeater => 'Gerir repetidor';

  @override
  String get contacts_manageRoom => 'Gerir room server';

  @override
  String get contacts_roomLogin => 'Início de sessão no room server';

  @override
  String get contacts_openChat => 'Abrir conversa';

  @override
  String get contacts_editGroup => 'Editar grupo';

  @override
  String get contacts_deleteGroup => 'Eliminar grupo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Remover \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Novo grupo';

  @override
  String get contacts_moreOptions => 'Mais opções';

  @override
  String get contacts_searchOpen => 'Pesquisar contactos';

  @override
  String get contacts_searchClose => 'Fechar pesquisa';

  @override
  String get contacts_groupName => 'Nome do grupo';

  @override
  String get contacts_groupNameRequired => 'O nome do grupo é obrigatório';

  @override
  String get contacts_groupNameReserved => 'Este nome de grupo está reservado';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'O grupo \"$name\" já existe';
  }

  @override
  String get contacts_filterContacts => 'Filtrar contactos...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Nenhum contacto corresponde ao filtro';

  @override
  String get contacts_noMembers => 'Sem membros';

  @override
  String get contacts_lastSeenNow => 'recentemente';

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
  String get contacts_lastSeenDayAgo => '~ 1 dia';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days dias';
  }

  @override
  String get contact_info => 'Info do contacto';

  @override
  String get contact_settings => 'Definições do contacto';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Visto pela última vez';

  @override
  String get contact_clearChat => 'Limpar conversa';

  @override
  String get contact_teleBase => 'Telemetria base';

  @override
  String get contact_teleBaseSubtitle =>
      'Permitir partilhar o nível da bateria e telemetria básica';

  @override
  String get contact_teleLoc => 'Telemetria de localização';

  @override
  String get contact_teleLocSubtitle =>
      'Permitir partilhar dados de localização';

  @override
  String get contact_teleEnv => 'Telemetria ambiental';

  @override
  String get contact_teleEnvSubtitle =>
      'Permitir partilhar dados de sensores ambientais';

  @override
  String get channels_title => 'Canais';

  @override
  String get channels_noChannelsConfigured => 'Nenhum canal configurado';

  @override
  String get channels_addPublicChannel => 'Adicionar canal público';

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
  String get channels_hashtag => 'Hashtag';

  @override
  String get channels_addSectionJoin => 'Aderir a existente';

  @override
  String get channels_addSectionCreate => 'Criar novo';

  @override
  String get channels_dragToReorder => 'Arraste para reordenar';

  @override
  String get channels_editChannel => 'Editar canal';

  @override
  String get channels_notificationSettings => 'Definições de notificações';

  @override
  String get channels_notifyAll => 'Todas as mensagens';

  @override
  String get channels_notifyMentionsOnly => 'Só menções';

  @override
  String get channels_notifyNone => 'Silenciado';

  @override
  String channels_notificationModeTooltip(String mode) {
    return 'Notificações: $mode';
  }

  @override
  String get channels_muteChannel => 'Silenciar canal';

  @override
  String get channels_unmuteChannel => 'Reativar som do canal';

  @override
  String get channels_deleteChannel => 'Eliminar canal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Eliminar \"$name\"? Esta ação não pode ser anulada.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Falha ao eliminar o canal \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canal \"$name\" eliminado';
  }

  @override
  String get channels_addChannel => 'Adicionar canal';

  @override
  String get channels_channelIndexLabel => 'Índice do canal';

  @override
  String get channels_channelName => 'Nome do canal';

  @override
  String get channels_usePublicChannel => 'Usar canal público';

  @override
  String get channels_standardPublicPsk => 'PSK público padrão';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Gerar PSK aleatória';

  @override
  String get channels_enterChannelName => 'Introduza um nome para o canal';

  @override
  String get channels_pskMustBe32Hex =>
      'A PSK tem de ter 32 caracteres hexadecimais';

  @override
  String channels_channelAdded(String name) {
    return 'Canal \"$name\" adicionado';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Editar canal $index';
  }

  @override
  String get channels_smazCompression => 'Compressão SMAZ';

  @override
  String get channels_cyr2latCompression => 'Compressão Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Substitui alguns caracteres cirílicos por latinos ao enviar.';

  @override
  String get channels_cyr2latSettingsHeading => 'Configuração Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Lista de substituições';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Editar a configuração JSON da substituição de caracteres';

  @override
  String get channels_cyr2latSettingsDialogHint => 'Mapa de substituição JSON';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'JSON inválido: $error';
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
    return 'Tem a certeza de que quer eliminar o perfil \"$name\"?';
  }

  @override
  String get channels_publicChannelAdded => 'Canal público adicionado';

  @override
  String get channels_noFreeSlots => 'Todas as posições de canal estão em uso';

  @override
  String get channels_sortBy => 'Ordenar por';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Mensagens recentes';

  @override
  String get channels_sortUnread => 'Não lidas';

  @override
  String get channels_createPrivateChannel => 'Criar um canal privado';

  @override
  String get channels_createPrivateChannelDesc =>
      'Protegido por uma chave secreta.';

  @override
  String get channels_joinPrivateChannel => 'Aderir a um canal privado';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Introduzir uma chave secreta manualmente.';

  @override
  String get channels_joinPublicChannel => 'Aderir ao canal público';

  @override
  String get channels_joinPublicChannelDesc =>
      'Qualquer pessoa pode aderir a este canal.';

  @override
  String get channels_joinHashtagChannel => 'Aderir a um canal hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Qualquer pessoa pode aderir a canais hashtag.';

  @override
  String get channels_scanQrCode => 'Ler código QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Em breve';

  @override
  String get channels_scanQrCodeDesc =>
      'Aderir a um canal ou comunidade através do código QR.';

  @override
  String get channels_scanQrInstructions =>
      'Aponte a câmara para um código QR de canal ou comunidade';

  @override
  String get channels_invalidQrCode =>
      'Não é um código QR de canal ou comunidade MeshCore';

  @override
  String get channels_joinChannelTitle => 'Aderir ao canal';

  @override
  String channels_joinChannelConfirm(String name) {
    return 'Adicionar \"$name\" ao seu rádio?';
  }

  @override
  String channels_alreadyOnRadio(String name) {
    return '\"$name\" já está no seu rádio';
  }

  @override
  String get channels_enterHashtag => 'Introduza a hashtag';

  @override
  String get channels_hashtagHint => 'ex.: #equipa';

  @override
  String channels_regionSetTo(String region) {
    return 'Região: $region';
  }

  @override
  String get channels_regionNotSet => 'Região: nenhuma';

  @override
  String get channels_regionSelect_Title => 'Selecionar uma região';

  @override
  String get channels_clearRegion => 'Limpar região';

  @override
  String get channels_regionDefaultSuffix => '(predefinida)';

  @override
  String get channels_regionRadioDefaultSuffix => '(predefinida do rádio)';

  @override
  String channels_regionRadioDefaultApplies(String region) {
    return 'Este rádio envia floods sem região na sua região predefinida: $region.';
  }

  @override
  String get channels_regionSelectExplanation =>
      'As mensagens flood neste canal só serão reencaminhadas por repetidores da região selecionada.';

  @override
  String get channels_regionEmpty => 'Ainda sem regiões.';

  @override
  String get channels_manageRegions => 'Gerir regiões';

  @override
  String get chat_noMessages => 'Ainda sem mensagens';

  @override
  String get chatSearch_tooltip => 'Pesquisar mensagens';

  @override
  String get chatSearch_hint => 'Pesquisar mensagens';

  @override
  String get chatSearch_close => 'Fechar pesquisa';

  @override
  String chatSearch_resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get chatSearch_noResults => 'Nenhuma mensagem encontrada';

  @override
  String get chatSearch_noResultsHint =>
      'Tente outra palavra ou verifique a ortografia';

  @override
  String get chatSearch_jumpFailed =>
      'Não foi possível encontrar essa mensagem na conversa';

  @override
  String get chat_sendMessage => 'Enviar mensagem';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Enviar uma mensagem a $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Envie uma mensagem para começar';

  @override
  String get chat_originalMessageNotFound => 'Mensagem original não encontrada';

  @override
  String chat_replyingTo(String name) {
    return 'A responder a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get chat_location => 'Localização';

  @override
  String get chat_typeMessage => 'Escreva uma mensagem...';

  @override
  String get chat_futureTimestampWarning =>
      'A hora desta mensagem está no futuro, pelo que o relógio do remetente pode estar errado. É mostrada pela ordem de chegada.';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Mensagem demasiado longa (máx. $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Mensagem copiada';

  @override
  String get chat_messageDeleted => 'Mensagem eliminada';

  @override
  String get chat_selectMessages => 'Selecionar mensagens';

  @override
  String chat_selectedCount(int count) {
    return '$count selecionadas';
  }

  @override
  String get chat_selectAll => 'Selecionar tudo';

  @override
  String get chat_clearSelection => 'Limpar seleção';

  @override
  String get chat_deleteSelectedTitle => 'Eliminar mensagens?';

  @override
  String chat_deleteSelectedConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count mensagens deste dispositivo?',
      one: 'Eliminar 1 mensagem deste dispositivo?',
    );
    return '$_temp0';
  }

  @override
  String chat_messagesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens eliminadas',
      one: '1 mensagem eliminada',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_markedSpamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens marcadas como spam',
      one: '1 mensagem marcada como spam',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_markedNotSpamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens marcadas como não spam',
      one: '1 mensagem marcada como não spam',
    );
    return '$_temp0';
  }

  @override
  String get chat_retryingMessage => 'A tentar reenviar a mensagem';

  @override
  String chat_retryCount(int current, int max) {
    return 'Tentativa $current/$max';
  }

  @override
  String get chat_selectSendAction => 'Selecionar ação de envio';

  @override
  String get chat_sendGif => 'Enviar GIF';

  @override
  String get chat_shareMyLocation => 'Partilhar a minha localização';

  @override
  String get chat_noRadioLocation => 'O seu rádio não tem localização definida';

  @override
  String get chat_removeGif => 'Remover GIF';

  @override
  String get chat_cancelReply => 'Cancelar resposta';

  @override
  String get chat_sendImageLora => 'Enviar imagem de baixa resolução por rádio';

  @override
  String get chat_sendImageIpfs => 'Enviar imagem ou ficheiro via IPFS';

  @override
  String chat_ipfsUploadFailed(String error) {
    return 'Falha no envio para IPFS: $error';
  }

  @override
  String get chat_ipfsUploadNotConfigured =>
      'Configure primeiro um fornecedor de envio IPFS nas Definições da app.';

  @override
  String get chat_ipfsSelectedFileEmpty => 'O ficheiro selecionado está vazio.';

  @override
  String get chat_ipfsEndpointInvalid =>
      'O endpoint de envio IPFS tem de ser um endereço http:// ou https:// completo. Verifique-o nas Definições da app.';

  @override
  String get chat_ipfsPinataTokenMissing =>
      'O Pinata precisa de uma chave API ou JWT. Adicione-a nas Definições da app.';

  @override
  String get chat_ipfsFilebaseTokenMissing =>
      'O Filebase precisa de um token API. Adicione-o nas Definições da app.';

  @override
  String get chat_ipfsKuboPathInvalid =>
      'O endpoint de envio Kubo tem de terminar em /api/v0/add. Verifique-o nas Definições da app.';

  @override
  String get chat_ipfsLinkNoRoom =>
      'Sem espaço para a ligação da imagem. Encurte a mensagem e tente novamente.';

  @override
  String get chat_ipfsLinkOverLimit =>
      'Ligação da imagem adicionada, mas a mensagem ficou demasiado longa. Encurte-a antes de enviar.';

  @override
  String get chat_imagePickFailed => 'Não foi possível abrir essa imagem';

  @override
  String get chat_receivedGif => 'Recebeu um GIF';

  @override
  String get chat_reply => 'Responder';

  @override
  String get chat_addReaction => 'Adicionar reação';

  @override
  String get chat_me => 'Eu';

  @override
  String get reaction_report => 'Reações com emojis';

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
  String get gifPicker_failedLoad => 'Falha ao carregar GIFs';

  @override
  String get gifPicker_failedSearch => 'Falha ao pesquisar GIFs';

  @override
  String get gifPicker_noInternet => 'Sem ligação à internet';

  @override
  String get debugLog_appTitle => 'Registo de depuração da app';

  @override
  String get debugLog_bleTitle => 'Registo de depuração BLE';

  @override
  String get debugLog_copyLog => 'Copiar registo';

  @override
  String get debugLog_clearLog => 'Limpar registo';

  @override
  String get debugLog_copied => 'Registo de depuração copiado';

  @override
  String get debugLog_bleCopied => 'Registo BLE copiado';

  @override
  String get debugLog_noEntries => 'Ainda sem registos de depuração';

  @override
  String get debugLog_enableInSettings =>
      'Ative o registo de depuração da app nas definições';

  @override
  String get debugLog_frames => 'Frames';

  @override
  String get debugLog_rawLogRx => 'Registo bruto RX';

  @override
  String get debugLog_noBleActivity => 'Ainda sem atividade BLE';

  @override
  String debugFrame_length(int count) {
    return 'Tamanho da frame: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Frame de mensagem de texto:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- PubKey de destino: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Data/hora: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flags: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tipo de texto: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Simples';

  @override
  String debugFrame_text(String text) {
    return '- Texto: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Dump hexadecimal:';

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
  String get chat_removePath => 'Remover caminho';

  @override
  String get chat_noPathHistoryYet =>
      'Ainda sem histórico de caminhos.\nEnvie uma mensagem para descobrir caminhos.';

  @override
  String get chat_pathCleared =>
      'Caminho limpo. A próxima mensagem voltará a descobrir a rota.';

  @override
  String get chat_fullPath => 'Caminho completo';

  @override
  String get routing_title => 'Encaminhamento';

  @override
  String get routing_modeAuto => 'Auto';

  @override
  String get routing_modeFlood => 'Flood';

  @override
  String get routing_modeManual => 'Manual';

  @override
  String get routing_modeDirect => 'Direto';

  @override
  String get routing_modeAutoHint =>
      'Escolhe automaticamente o melhor caminho conhecido, usando flood quando não há nenhum.';

  @override
  String get routing_modeFloodHint =>
      'Difunde por todos os repetidores. Mais fiável, mas usa mais airtime.';

  @override
  String get routing_modeManualHint =>
      'Envia sempre pelo caminho exato que definir.';

  @override
  String get routing_modeDirectHint =>
      'Envia sempre diretamente para este contacto, sem hops de repetidores. Use quando estiver no alcance de rádio.';

  @override
  String get routing_currentRoute => 'Rota atual';

  @override
  String get routing_directNoHops => 'Direto — sem hops de repetidores';

  @override
  String get routing_noPathYet =>
      'Ainda sem caminho. A próxima mensagem usa flood até ser descoberta uma rota.';

  @override
  String get routing_floodBroadcast => 'Difusão por todos os repetidores';

  @override
  String get routing_editPath => 'Editar caminho';

  @override
  String get routing_forgetPath => 'Esquecer caminho';

  @override
  String get routing_knownPaths => 'Caminhos conhecidos';

  @override
  String get routing_knownPathsHint => 'Toque num caminho para mudar para ele.';

  @override
  String get routing_inUse => 'Em uso';

  @override
  String get routing_qualityStrong => 'Primeiro hop forte';

  @override
  String get routing_qualityGood => 'Primeiro hop bom';

  @override
  String get routing_qualityFair => 'Primeiro hop razoável';

  @override
  String get routing_qualityWorked => 'Já entregou';

  @override
  String get routing_qualityFlood => 'Ouvido via flood';

  @override
  String get routing_qualityUntested => 'Não testado';

  @override
  String routing_lastWorked(String when) {
    return 'funcionou $when';
  }

  @override
  String get routing_neverWorked => 'nunca confirmado';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes entregues, $failures falhadas';
  }

  @override
  String get routing_floodDelivery => 'Entrega por flood';

  @override
  String get pathEditor_title => 'Criar caminho';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count de 64 hops';
  }

  @override
  String get pathEditor_noHops =>
      'Ainda sem hops. Toque nos repetidores abaixo para os adicionar por ordem, ou guarde sem hops para enviar diretamente.';

  @override
  String get pathEditor_addHops => 'Adicionar hops por ordem';

  @override
  String get pathEditor_searchRepeaters => 'Pesquisar repetidores';

  @override
  String get pathEditor_advancedHex => 'Avançado: caminho hex em bruto';

  @override
  String get pathEditor_hexLabel => 'Prefixos hex';

  @override
  String get pathEditor_hexHelper =>
      'Dois caracteres hex por hop, separados por vírgulas';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Inválido: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Máximo de 64 hops';

  @override
  String get pathEditor_usePath => 'Usar este caminho';

  @override
  String get pathEditor_removeHop => 'Remover hop';

  @override
  String get pathEditor_unknownHop => 'Repetidor desconhecido';

  @override
  String get chat_pathSavedLocally =>
      'Guardado localmente. Ligue para sincronizar.';

  @override
  String get chat_pathDeviceConfirmed => 'Dispositivo confirmou.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Dispositivo ainda não confirmou.';

  @override
  String get chat_type => 'Tipo';

  @override
  String get chat_path => 'Caminho';

  @override
  String get chat_viewPathOnMap => 'Ver caminho no mapa';

  @override
  String get chat_publicKey => 'Chave pública';

  @override
  String get chat_compressOutgoingMessages => 'Comprimir mensagens enviadas';

  @override
  String get chat_floodForced => 'Flood (forçado)';

  @override
  String get chat_directForced => 'Direto (forçado)';

  @override
  String chat_hopsForced(int count) {
    return '$count hops (forçado)';
  }

  @override
  String get chat_floodAuto => 'Flood (auto)';

  @override
  String get chat_direct => 'Direto';

  @override
  String get chat_poiShared => 'POI partilhado';

  @override
  String get contactShare_headerOutgoing => 'Partilhou um contacto';

  @override
  String get contactShare_headerIncoming => 'Partilhou um contacto';

  @override
  String get contactShare_add => 'Adicionar contacto';

  @override
  String get contactShare_adding => 'A adicionar contacto...';

  @override
  String get contactShare_saved => 'Guardado';

  @override
  String get contactShare_addAgain => 'Adicionar novamente';

  @override
  String get contactShare_isYou => 'Este é o seu contacto';

  @override
  String get contactShare_shareAction => 'Partilhar contacto';

  @override
  String get contactShare_pickerTitle => 'Partilhar um contacto';

  @override
  String get contactShare_myContact => 'O meu contacto';

  @override
  String get contactShare_searchHint => 'Pesquisar contactos';

  @override
  String get contactShare_noContacts => 'Nenhum contacto encontrado';

  @override
  String contactShare_preview(String name) {
    return 'Contacto partilhado: $name';
  }

  @override
  String contactShare_notification(String name) {
    return 'Partilhou um contacto: $name';
  }

  @override
  String chat_unread(int count) {
    return 'Não lidas: $count';
  }

  @override
  String get chat_markAsUnread => 'Marcar como não lida';

  @override
  String get chat_newMessages => 'Novas mensagens';

  @override
  String get chat_today => 'Hoje';

  @override
  String get chat_yesterday => 'Ontem';

  @override
  String get chat_openLink => 'Abrir ligação?';

  @override
  String get chat_openLinkConfirmation =>
      'Quer abrir esta ligação no navegador?';

  @override
  String get chat_open => 'Abrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Não foi possível abrir a ligação: $url';
  }

  @override
  String get chat_invalidLink => 'Formato de ligação inválido';

  @override
  String get map_title => 'Mapa de nós';

  @override
  String get map_searchHint => 'Pesquisar nome ou ID do nó';

  @override
  String get map_activity => 'Atividade';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Recente';

  @override
  String get map_stale => 'Inativo';

  @override
  String get map_visible => 'Visível';

  @override
  String get map_hidden => 'Oculto';

  @override
  String get map_centerOnNode => 'Centrar no nó';

  @override
  String get map_centerOnMe => 'Centrar na minha localização';

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
  String get map_noNodesWithLocation => 'Nenhum nó com dados de localização';

  @override
  String get map_noNodesLocationHint =>
      'Nenhum nó com localização recente. Alargue o filtro de tempo ou defina a sua localização nas Definições.';

  @override
  String get map_nodesNeedGps =>
      'Os nós têm de partilhar as suas coordenadas GPS\npara aparecerem no mapa';

  @override
  String map_nodesCount(int count) {
    return 'Nós: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Marcadores: $count';
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
  String get map_pinDm => 'Marcador (DM)';

  @override
  String get map_pinPrivate => 'Marcador (privado)';

  @override
  String get map_pinPublic => 'Marcador (público)';

  @override
  String get map_lastSeen => 'Visto pela última vez';

  @override
  String get map_from => 'De';

  @override
  String get map_source => 'Origem';

  @override
  String get map_flags => 'Flags';

  @override
  String get map_type => 'Tipo';

  @override
  String get map_path => 'Caminho';

  @override
  String get map_location => 'Localização';

  @override
  String get map_estLocation => 'Localização est.';

  @override
  String get map_publicKey => 'Chave pública';

  @override
  String get map_publicKeyPrefixHint => 'ex.: ab12';

  @override
  String get map_shareMarkerHere => 'Partilhar marcador aqui';

  @override
  String get map_setAsMyLocation => 'Definir como a minha localização';

  @override
  String get map_pinLabel => 'Etiqueta do marcador';

  @override
  String get map_label => 'Etiqueta';

  @override
  String get map_labelUpdateHint =>
      'Usar a mesma etiqueta de antes atualizará o marcador para os destinatários do MeshCore Open.';

  @override
  String get map_pointOfInterest => 'Ponto de interesse';

  @override
  String get map_sendToContact => 'Enviar para contacto';

  @override
  String get map_sendToChannel => 'Enviar para canal';

  @override
  String get map_noChannelsAvailable => 'Nenhum canal disponível';

  @override
  String get map_publicLocationShare => 'Partilha de localização pública';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Está prestes a partilhar uma localização em $channelLabel. Este canal é público e qualquer pessoa com a PSK pode vê-la.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Ligue a um dispositivo para partilhar marcadores';

  @override
  String get map_filterNodes => 'Filtrar nós';

  @override
  String get map_nodeTypes => 'Tipos de nó';

  @override
  String get map_chatNodes => 'Nós de chat';

  @override
  String get map_repeaters => 'Repetidores';

  @override
  String get map_otherNodes => 'Outros nós';

  @override
  String get map_showOnlineLinks => 'Mostrar ligações do mapa online';

  @override
  String get map_showOverlaps => 'Sobreposições de chaves de repetidores';

  @override
  String get map_keyPrefix => 'Prefixo da chave';

  @override
  String get map_filterByKeyPrefix => 'Filtrar por prefixo da chave';

  @override
  String get map_publicKeyPrefix => 'Prefixo da chave pública';

  @override
  String get map_markers => 'Marcadores';

  @override
  String get map_showSharedMarkers => 'Mostrar marcadores partilhados';

  @override
  String get map_showGuessedLocations =>
      'Mostrar localizações estimadas de nós';

  @override
  String get map_clusterNodes => 'Agrupar nós próximos';

  @override
  String get map_groupChip => 'Grupo';

  @override
  String get map_clusterNodesSubtitle =>
      'Ao afastar o zoom, mostra nós próximos como um círculo numerado';

  @override
  String get map_showDiscoveryContacts => 'Mostrar contactos descobertos';

  @override
  String get map_guessedLocation => 'Localização estimada';

  @override
  String get map_lastSeenTime => 'Hora da última vez visto';

  @override
  String get map_sharedPin => 'Marcador partilhado';

  @override
  String get map_sharedAt => 'Partilhado';

  @override
  String get map_joinRoom => 'Entrar na sala';

  @override
  String get map_manageRepeater => 'Gerir repetidor';

  @override
  String get map_manageServer => 'Gerir servidor';

  @override
  String get map_tapToAdd => 'Toque nos nós para os adicionar ao caminho.';

  @override
  String get map_runTrace => 'Executar trace do caminho';

  @override
  String get map_runTraceWithReturnPath => 'Regressar pelo mesmo caminho.';

  @override
  String get map_removeLast => 'Remover último';

  @override
  String get map_pathTraceCancelled => 'Trace do caminho cancelado.';

  @override
  String get map_pathTraceAddMoreHint =>
      'Toque em mais nós para adicionar hops, escolha como o trace regressa e toque em Executar trace do caminho.';

  @override
  String get map_pathTraceModeRoundTrip => 'Ida e volta';

  @override
  String get map_pathTraceModeRoundTripHint =>
      'O trace segue por estes hops e regressa pelo mesmo caminho.';

  @override
  String get map_pathTraceModeAsEntered => 'Como introduzido';

  @override
  String get map_pathTraceModeAsEnteredHint =>
      'O trace segue exatamente estes hops. Adicione os hops de regresso manualmente.';

  @override
  String get map_pathTraceViewLast => 'Ver último resultado';

  @override
  String get manualTrace_menuItem => 'Trace do caminho por hashes';

  @override
  String get manualTrace_inputLabel => 'Hashes dos repetidores';

  @override
  String manualTrace_helper(String example) {
    return 'Exemplo: $example. Separe com vírgulas ou espaços.';
  }

  @override
  String manualTrace_previewTitle(int count) {
    return 'Hops ($count)';
  }

  @override
  String get manualTrace_unknownNode => 'Nó desconhecido';

  @override
  String get manualTrace_enterHashes => 'Introduza hashes';

  @override
  String get manualTrace_run => 'Executar trace do caminho';

  @override
  String get manualTrace_notConnected =>
      'Ligue a um rádio para executar um trace';

  @override
  String get manualTrace_errorInvalidHex =>
      'Só são permitidos caracteres hex (0-9, A-F)';

  @override
  String get manualTrace_errorOddLength =>
      'Cada hash precisa de um número par de caracteres hex, correspondente ao tamanho do hop';

  @override
  String get manualTrace_errorMixedWidths =>
      'Todos os hashes têm de ter o mesmo comprimento';

  @override
  String get manualTrace_errorUnsupportedWidth =>
      'Os hashes têm de ter 1, 2 ou 3 bytes (2, 4 ou 6 caracteres hex)';

  @override
  String manualTrace_errorTooManyHops(int max) {
    return 'O caminho é demasiado longo (máximo $max bytes)';
  }

  @override
  String get manualTrace_errorTraceTooLong =>
      'Demasiados hops para um trace num só pedido. Remova alguns hops ou escolha Como introduzido.';

  @override
  String get mapCache_title => 'Cache de mapa offline';

  @override
  String get mapCache_selectAreaFirst =>
      'Selecione primeiro uma área para guardar em cache';

  @override
  String get mapCache_noTilesToDownload =>
      'Sem tiles para transferir nesta área';

  @override
  String get mapCache_downloadTilesTitle => 'Transferir tiles';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Transferir $count tiles para uso offline?';
  }

  @override
  String get mapCache_downloadAction => 'Transferir';

  @override
  String mapCache_cachedTiles(int count) {
    return '$count tiles em cache';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return '$downloaded tiles em cache ($failed falharam)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Limpar cache offline';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Remover todos os tiles de mapa em cache?';

  @override
  String get mapCache_offlineCacheCleared => 'Cache offline limpa';

  @override
  String get mapCache_noAreaSelected => 'Nenhuma área selecionada';

  @override
  String get mapCache_cacheArea => 'Área da cache';

  @override
  String get mapCache_useCurrentView => 'Usar vista atual';

  @override
  String get mapCache_zoomRange => 'Intervalo de zoom';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Tiles estimados: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Transferidos $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Transferir tiles';

  @override
  String get mapCache_clearCacheButton => 'Limpar cache';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Transferências falhadas: $count';
  }

  @override
  String get mapCache_cachedTilesLabel => 'Tiles em cache';

  @override
  String get mapCache_cachedTileSummaryLabel => 'Resumo de tiles em cache';

  @override
  String mapCache_bulkDownloadDisabledForSource(String source) {
    return 'As transferências offline em massa estão desativadas para $source.';
  }

  @override
  String mapCache_bulkDownloadDisabledInConfig(String source) {
    return 'As transferências offline em massa estão desativadas para $source nesta configuração da app.';
  }

  @override
  String mapCache_summarySource(String source) {
    return 'Origem: $source';
  }

  @override
  String mapCache_summaryCachedTilesForSource(int count) {
    return 'Tiles em cache para a origem: $count';
  }

  @override
  String mapCache_summaryCachedInSelection(int count) {
    return 'Em cache na área/zoom selecionados: $count';
  }

  @override
  String mapCache_summaryApproxCacheSize(String size) {
    return 'Tamanho aprox. da cache: $size';
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
  String get time_justNow => 'Agora mesmo';

  @override
  String time_minutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String time_hoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String time_daysAgo(int days) {
    return 'há $days d';
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
  String get time_allTime => 'Sempre';

  @override
  String get dialog_disconnect => 'Desligar';

  @override
  String get dialog_disconnectConfirm =>
      'Tem a certeza de que quer desligar deste dispositivo?';

  @override
  String get login_repeaterLogin => 'Início de sessão do repetidor';

  @override
  String get login_roomLogin => 'Início de sessão do room server';

  @override
  String get login_password => 'Palavra-passe';

  @override
  String get login_enterPassword => 'Introduza a palavra-passe';

  @override
  String get login_showPassword => 'Mostrar palavra-passe';

  @override
  String get login_hidePassword => 'Ocultar palavra-passe';

  @override
  String get login_savePassword => 'Guardar palavra-passe';

  @override
  String get login_savePasswordSubtitle =>
      'A palavra-passe será guardada de forma segura neste dispositivo';

  @override
  String get login_repeaterDescription =>
      'A palavra-passe de admin desbloqueia as definições e o CLI. Uma palavra-passe de convidado (ou vazia) mostra apenas o estado.';

  @override
  String get login_roomDescription =>
      'Introduza a palavra-passe da sala para acesso de convidado ou admin.';

  @override
  String get login_advanced => 'Avançado';

  @override
  String get login_routing => 'Encaminhamento';

  @override
  String get login_routingMode => 'Modo de encaminhamento';

  @override
  String get login_autoUseSavedPath => 'Auto (usar caminho guardado)';

  @override
  String get login_forceFloodMode => 'Forçar modo Flood';

  @override
  String get login_managePaths => 'Gerir caminhos';

  @override
  String get login_login => 'Entrar';

  @override
  String login_attempt(int current, int max) {
    return 'Tentativa $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Falha ao iniciar sessão: $error';
  }

  @override
  String get login_failedMessage =>
      'Falha ao iniciar sessão. A palavra-passe está incorreta ou o repetidor está inacessível.';

  @override
  String get common_reload => 'Recarregar';

  @override
  String get common_clear => 'Limpar';

  @override
  String get common_clearSearch => 'Limpar pesquisa';

  @override
  String get path_currentPathLabel => 'Caminho atual';

  @override
  String get path_noRepeatersFound =>
      'Nenhum repetidor ou room server encontrado.';

  @override
  String get repeater_management => 'Gestão do repetidor';

  @override
  String get room_management => 'Gestão do room server';

  @override
  String get repeater_guest => 'Informações do repetidor';

  @override
  String get room_guest => 'Informações do room server';

  @override
  String get repeater_managementTools => 'Ferramentas de gestão';

  @override
  String get repeater_guestTools => 'Ferramentas de convidado';

  @override
  String get repeater_roleAdmin => 'ADMIN';

  @override
  String get repeater_roleGuest => 'CONVIDADO';

  @override
  String get repeater_status => 'Estado';

  @override
  String get repeater_statusSubtitle =>
      'Ver estado, estatísticas e vizinhos do repetidor';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Ver telemetria de sensores e estatísticas do sistema';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Enviar comandos ao repetidor';

  @override
  String get repeater_neighbors => 'Vizinhos';

  @override
  String get repeater_neighborsSubtitle => 'Ver vizinhos zero hop.';

  @override
  String get repeater_settings => 'Definições';

  @override
  String get repeater_settingsSubtitle => 'Configurar parâmetros do repetidor';

  @override
  String get repeater_clockSyncAfterLogin => 'Sincronizar relógio após login';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Enviar automaticamente \"clock sync\" após um login bem-sucedido';

  @override
  String get repeater_statusTitle => 'Estado do repetidor';

  @override
  String get repeater_routingMode => 'Modo de encaminhamento';

  @override
  String get repeater_refresh => 'Atualizar';

  @override
  String get repeater_statusRequestTimeout => 'O pedido de estado expirou.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Erro ao carregar o estado: $error';
  }

  @override
  String get repeater_systemInformation => 'Informações do sistema';

  @override
  String get repeater_battery => 'Bateria';

  @override
  String get repeater_clockAtLogin => 'Relógio (no login)';

  @override
  String get repeater_uptime => 'Tempo ativo';

  @override
  String get repeater_queueLength => 'Tamanho da fila';

  @override
  String get repeater_debugFlags => 'Flags de depuração';

  @override
  String get repeater_radioStatistics => 'Estatísticas de rádio';

  @override
  String get repeater_lastRssi => 'Último RSSI';

  @override
  String get repeater_lastSnr => 'Último SNR';

  @override
  String get repeater_noiseFloor => 'Noise floor';

  @override
  String get repeater_txAirtime => 'Airtime TX';

  @override
  String get repeater_rxAirtime => 'Airtime RX';

  @override
  String get repeater_chanUtil => 'Utilização do canal';

  @override
  String get repeater_packetStatistics => 'Estatísticas de pacotes';

  @override
  String get repeater_sent => 'Enviados';

  @override
  String get repeater_received => 'Recebidos';

  @override
  String get repeater_duplicates => 'Duplicados';

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
  String repeater_hoursMinsSecs(int hours, int minutes, int seconds) {
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Flood: $flood, Direto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Flood: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get repeater_settingsTitle => 'Definições do repetidor';

  @override
  String get repeater_basicSettings => 'Definições básicas';

  @override
  String get repeater_repeaterName => 'Nome do repetidor';

  @override
  String get repeater_repeaterNameHelper =>
      'Nome de apresentação deste repetidor';

  @override
  String get repeater_adminPassword => 'Palavra-passe de admin';

  @override
  String get repeater_adminPasswordHelper => 'Palavra-passe de acesso total';

  @override
  String get repeater_guestPassword => 'Palavra-passe de convidado';

  @override
  String get repeater_guestPasswordHelper =>
      'Palavra-passe de acesso só de leitura';

  @override
  String get repeater_radioSettings => 'Definições de rádio';

  @override
  String get repeater_frequencyMhz => 'Frequência (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'Potência TX';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Largura de banda';

  @override
  String get repeater_spreadingFactor => 'Spreading Factor';

  @override
  String get repeater_codingRate => 'Coding Rate';

  @override
  String get repeater_locationSettings => 'Definições de localização';

  @override
  String get repeater_latitude => 'Latitude';

  @override
  String get repeater_latitudeHelper => 'Graus decimais (ex.: 37.7749)';

  @override
  String get repeater_longitude => 'Longitude';

  @override
  String get repeater_longitudeHelper => 'Graus decimais (ex.: -122.4194)';

  @override
  String get repeater_features => 'Funcionalidades';

  @override
  String get repeater_packetForwarding => 'Reencaminhamento de pacotes';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Permitir que o repetidor reencaminhe pacotes';

  @override
  String get repeater_guestAccess => 'Acesso de convidado';

  @override
  String get repeater_guestAccessSubtitle =>
      'Permitir acesso de convidado só de leitura';

  @override
  String get repeater_privacyMode => 'Modo de privacidade';

  @override
  String get repeater_privacyModeSubtitle =>
      'Ocultar nome/localização nos anúncios';

  @override
  String get repeater_advertisementSettings => 'Definições de anúncios';

  @override
  String get repeater_localAdvertInterval => 'Intervalo de anúncio local';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get repeater_floodAdvertInterval => 'Intervalo de anúncio Flood';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Intervalo de anúncio cifrado';

  @override
  String get repeater_dangerZone => 'Zona de perigo';

  @override
  String get repeater_rebootRepeater => 'Reiniciar repetidor';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reiniciar o dispositivo repetidor';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Tem a certeza de que quer reiniciar este repetidor?';

  @override
  String get repeater_regenerateIdentityKey => 'Regenerar chave de identidade';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Gerar um novo par de chaves pública/privada';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Isto vai gerar uma nova identidade para o repetidor. Continuar?';

  @override
  String get repeater_eraseFileSystem => 'Apagar sistema de ficheiros';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatar o sistema de ficheiros do repetidor';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'AVISO: Isto apaga todos os dados do repetidor. Não pode ser anulado!';

  @override
  String get repeater_eraseSerialOnly =>
      'Só é possível apagar através da consola série.';

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
  String get repeater_settingsSaved => 'Definições guardadas com sucesso';

  @override
  String get repeater_rxGain => 'Ganho RX reforçado';

  @override
  String get repeater_rxGainHelper =>
      'Maior sensibilidade, maior consumo de corrente (só SX1262/SX1268)';

  @override
  String get repeater_multiAcks => 'ACKs múltiplos';

  @override
  String get repeater_multiAcksSubtitle =>
      'Confirmar mensagens por vários caminhos para melhor entrega';

  @override
  String get repeater_networkHealth => 'Estado da rede';

  @override
  String get repeater_loopDetect => 'Deteção de ciclos';

  @override
  String get repeater_loopDetectHelper =>
      'Descartar pacotes Flood que pareçam ciclos de encaminhamento';

  @override
  String get repeater_loopDetectOff => 'Desativada';

  @override
  String get repeater_loopDetectMinimal => 'Mínima';

  @override
  String get repeater_loopDetectModerate => 'Moderada';

  @override
  String get repeater_loopDetectStrict => 'Estrita';

  @override
  String get repeater_dutyCycle => 'Duty cycle';

  @override
  String get repeater_dutyCycleHelper => 'Percentagem máxima de airtime';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Info do operador';

  @override
  String get repeater_ownerInfoHelper => 'Metadados públicos deste repetidor';

  @override
  String get repeater_floodMax => 'Máx. hops Flood';

  @override
  String get repeater_floodMaxHelper =>
      'Máximo de hops que um pacote Flood pode percorrer (0-64)';

  @override
  String get repeater_advancedSettings => 'Avançado';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Ajustes para operadores experientes';

  @override
  String get repeater_pathHashMode => 'Tamanho do ID do nó nos caminhos';

  @override
  String get repeater_pathHashModeHelper =>
      'Tamanho do ID deste repetidor nos caminhos dos anúncios que envia: 1 byte (256 IDs, até 64 hops), 2 bytes (65K IDs, até 32 hops), 3 bytes (16M IDs, até 21 hops). Não afeta o reencaminhamento; os repetidores v1.14+ reencaminham todos os tamanhos, mas o firmware mais antigo descarta pacotes com IDs de 2 ou 3 bytes.';

  @override
  String get repeater_keySettings => 'Alterar chaves de identidade';

  @override
  String get repeater_keySettingsSubtitle =>
      'Alterar o par de chaves pública/privada';

  @override
  String get repeater_prvKey => 'Chave privada';

  @override
  String get repeater_prvKeyHelper =>
      'Uma nova chave privada para o repetidor, uma cadeia hexadecimal de 128 caracteres.';

  @override
  String get repeater_generatePrvKey => 'Gerar um par de chaves aleatório';

  @override
  String get repeater_stopGeneratingPrvKey => 'Interromper a procura de chaves';

  @override
  String get repeater_pubKey => 'Chave pública';

  @override
  String get repeater_pubKeyHelper =>
      'Esta é a chave pública correspondente à chave privada gerada. Não pode ser definida diretamente.';

  @override
  String get repeater_pubKeyPrefix => 'Prefixo pretendido';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Procura uma chave pública que comece com estes dígitos hexadecimais. Tentativas esperadas: $tries.';
  }

  @override
  String get repeater_txDelay => 'Atraso TX Flood';

  @override
  String get repeater_txDelayHelper =>
      'Espaçamento de retransmissão do tráfego Flood, como multiplicador do airtime do pacote (0-2, predefinição 0.5). Mais alto = menos colisões mas entrega mais lenta.';

  @override
  String get repeater_directTxDelay => 'Atraso TX direto';

  @override
  String get repeater_directTxDelayHelper =>
      'Espaçamento de retransmissão do tráfego direto (não Flood), como multiplicador do airtime do pacote (0-2, predefinição 0.3).';

  @override
  String get repeater_intThresh => 'Limiar de interferência';

  @override
  String get repeater_intThreshHelper =>
      'Limiar passado à calibração do ruído de fundo do rádio para rejeitar interferência acima deste nível. 0 desativa — aumente só se vir erros RX numa banda ruidosa.';

  @override
  String get repeater_agcResetInterval => 'Intervalo de reset do AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Frequência com que o controlo automático de ganho do rádio é reposto para recuperar de um estado de ganho bloqueado. Segundos, arredondado para baixo para múltiplo de 4. 0 desativa os resets periódicos.';

  @override
  String get repeater_actionsTitle => 'Ações';

  @override
  String get repeater_sendAdvert => 'Enviar anúncio Flood';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Difundir um anúncio Flood pela rede';

  @override
  String get repeater_sendAdvertZeroHop => 'Enviar anúncio Zero Hop';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Difundir um anúncio de um hop (sem retransmissão)';

  @override
  String get repeater_clockSync => 'Sincronizar relógio agora';

  @override
  String get repeater_clockSyncSubtitle =>
      'Enviar a hora do telemóvel para o repetidor';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action concluído com sucesso';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action falhou: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Definições guardadas — reinicie o repetidor para aplicar';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Algumas definições falharam: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Erro ao guardar definições: $error';
  }

  @override
  String get repeater_refreshRadioSettings => 'Atualizar definições de rádio';

  @override
  String get repeater_refreshPrivacyMode => 'Atualizar modo de privacidade';

  @override
  String get repeater_refreshAll => 'Atualizar tudo';

  @override
  String get repeater_settingsNotLoaded =>
      'As definições ainda não foram carregadas deste repetidor.';

  @override
  String get repeater_settingsLoadIncomplete =>
      'Não foi possível carregar algumas definições. Use os botões de atualizar para tentar novamente.';

  @override
  String repeater_refreshed(String label) {
    return '$label atualizado';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Erro ao atualizar $label';
  }

  @override
  String get repeater_cliTitle => 'CLI do repetidor';

  @override
  String get repeater_debugNextCommand => 'Depurar próximo comando';

  @override
  String get repeater_commandHelp => 'Ajuda de comandos';

  @override
  String get repeater_clearHistory => 'Limpar histórico';

  @override
  String get repeater_noCommandsSent => 'Ainda não foram enviados comandos';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Escreva um comando abaixo ou use os comandos rápidos';

  @override
  String get repeater_enterCommandHint => 'Introduza o comando...';

  @override
  String get repeater_previousCommand => 'Comando anterior';

  @override
  String get repeater_nextCommand => 'Comando seguinte';

  @override
  String get repeater_enterCommandFirst => 'Introduza primeiro um comando';

  @override
  String get repeater_cliCommandFrameTitle => 'Trama de comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Erro: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Obter nome';

  @override
  String get repeater_cliQuickGetRadio => 'Obter rádio';

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
  String get repeater_cliQuickClockSync => 'Sincr. relógio';

  @override
  String get repeater_cliQuickDiscovery => 'Descobrir vizinhos';

  @override
  String get repeater_cliHelpAdvert => 'Envia um pacote de anúncio';

  @override
  String get repeater_cliHelpReboot =>
      'Reinicia o dispositivo. (nota: provavelmente receberá \'Timeout\', o que é normal)';

  @override
  String get repeater_cliHelpClock =>
      'Mostra a hora atual segundo o relógio do dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Define uma nova palavra-passe de administrador para o dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Mostra a versão do dispositivo e a data de compilação do firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Repõe a zero vários contadores de estatísticas.';

  @override
  String get repeater_cliHelpSetAf => 'Define o air-time-factor.';

  @override
  String get repeater_cliHelpSetTx =>
      'Define a potência de transmissão LoRa em dBm. (reiniciar para aplicar)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Ativa ou desativa a função de repetidor neste nó.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Room server) Se \'on\', o início de sessão com palavra-passe em branco é permitido, mas não pode publicar na sala. (só leitura)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Define o número máximo de hops de um pacote Flood recebido (se >= máx., o pacote não é reencaminhado)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Define o limiar de interferência (em dB). A predefinição é 14. Defina 0 para desativar a deteção de interferência no canal.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Define o intervalo para repor o controlador automático de ganho. Defina 0 para desativar.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Ativa ou desativa a funcionalidade de \'ACKs duplos\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Define o intervalo do temporizador, em minutos, para enviar um anúncio local (zero-hop). Defina 0 para desativar.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Define o intervalo do temporizador, em horas, para enviar um anúncio Flood. Defina 0 para desativar.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Define/atualiza a palavra-passe de convidado. (nos repetidores, os convidados podem enviar o pedido \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Define o nome do anúncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Define a latitude do anúncio no mapa. (graus decimais)';

  @override
  String get repeater_cliHelpSetLon =>
      'Define a longitude do anúncio no mapa. (graus decimais)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Define novos parâmetros de rádio completos e guarda-os nas preferências. Requer o comando \"reboot\" para aplicar.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Define a base (experimental; tem de ser > 1 para ter efeito) para aplicar um ligeiro atraso aos pacotes recebidos, com base na intensidade/pontuação do sinal. Defina 0 para desativar.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Define um fator multiplicado pelo time-on-air de um pacote em modo Flood e por um sistema de slots aleatórios, para atrasar o seu reencaminhamento. (para diminuir a probabilidade de colisões)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Igual a txdelay, mas aplica um atraso aleatório ao reencaminhamento de pacotes em modo direto.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Ativar/desativar bridge.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Define o atraso antes de retransmitir pacotes.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Escolhe se a bridge retransmite pacotes recebidos ou transmitidos.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Define o baudrate da ligação série para bridges rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Define o segredo da bridge para bridges espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Define um fator personalizado para ajustar a tensão de bateria reportada (só suportado em algumas placas).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Define parâmetros de rádio temporários durante o número de minutos indicado, voltando depois aos parâmetros originais. (NÃO guarda nas preferências).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica a ACL. Remove a entrada correspondente (por prefixo de pubkey) se \"permissions\" for zero. Adiciona uma nova entrada se pubkey-hex tiver o comprimento total e não estiver na ACL. Atualiza a entrada por correspondência do prefixo de pubkey. Os bits de permissão variam consoante a função do firmware, mas os 2 bits mais baixos são: 0 (Convidado), 1 (Só leitura), 2 (Leitura e escrita), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Obtém o tipo de bridge: none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Inicia o registo de pacotes no sistema de ficheiros.';

  @override
  String get repeater_cliHelpLogStop =>
      'Pára o registo de pacotes no sistema de ficheiros.';

  @override
  String get repeater_cliHelpLogErase =>
      'Apaga os registos de pacotes do sistema de ficheiros.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mostra uma lista de outros nós repetidores ouvidos através de anúncios zero-hop. Cada linha é id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Remove a primeira entrada correspondente (por prefixo de pubkey (hex)) da lista de vizinhos.';

  @override
  String get repeater_cliHelpRegion =>
      '(só série) Lista todas as regiões definidas e as permissões Flood atuais.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: esta é uma invocação especial de vários comandos. Cada comando seguinte é um nome de região (indentado com espaços para indicar a hierarquia do pai, com pelo menos um espaço). Termina ao enviar uma linha/comando em branco.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Procura a região com o prefixo de nome indicado (ou \"*\" para o âmbito global). Responde com \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Adiciona ou atualiza a definição de uma região com o nome indicado.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Remove a definição de uma região com o nome indicado. (tem de corresponder exatamente e não ter regiões filhas)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Define a permissão \'F\'lood para a região indicada. (\'*\' para o âmbito global/legado)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Remove a permissão \'F\'lood da região indicada. (NOTA: nesta fase NÃO é aconselhável usar isto no âmbito global/legado!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Responde com a região \'home\' atual. (Ainda não aplicada em lado nenhum, reservada para o futuro)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Define a região \'home\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Guarda a lista/mapa de regiões no armazenamento.';

  @override
  String get repeater_cliHelpGps =>
      'Indica o estado do gps. Com o gps desligado, responde apenas off; se ligado, responde com on, estado, fix, número de satélites';

  @override
  String get repeater_cliHelpGpsOnOff => 'Alterna o estado de energia do gps.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincroniza a hora do nó com o relógio do gps.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Define a posição do nó para as coordenadas do gps e guarda as preferências.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Indica a configuração de anúncio de localização do nó:\n- none: não incluir a localização nos anúncios\n- share: partilhar a localização gps (do SensorManager)\n- prefs: anunciar a localização guardada nas preferências';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Define a configuração de anúncio de localização.';

  @override
  String get repeater_commandsListTitle => 'Lista de comandos';

  @override
  String get repeater_commandsListNote =>
      'NOTA: para os vários comandos \"set ...\", existe também um comando \"get ...\".';

  @override
  String get repeater_frequencyRangeHelper => '150-2500 MHz';

  @override
  String get repeater_frequencyInvalid => 'Frequência inválida (150-2500 MHz)';

  @override
  String get repeater_txPowerRangeHelper => '-9 a 30 dBm';

  @override
  String get repeater_recvErrors => 'Erros de receção';

  @override
  String get room_postsStored => 'Publicações';

  @override
  String get room_postsPushed => 'Publicações enviadas';

  @override
  String get repeater_cliRegionLoadActive =>
      'Modo de carregamento de regiões: envie um nome de região por linha, indentado com espaços sob o respetivo pai (acrescente F após o nome para permitir Flood). As linhas não têm resposta. Envie uma linha vazia para terminar e depois \"region save\" para manter o resultado.';

  @override
  String get repeater_cliRegionLoadHint =>
      'Linha de região, ou vazia para terminar';

  @override
  String get repeater_cliRegionLoadEnd => '(fim do carregamento de regiões)';

  @override
  String get repeater_cliHelpRegionDef =>
      'Define uma cadeia de regiões num só comando: cada nome é adicionado sob o anterior; \"name,parent\" adiciona o nome e depois continua sob o pai indicado. Responde com a lista de regiões.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Define o número máximo de hops para reencaminhar pacotes Flood sem âmbito de região (0-64).';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Define o número máximo de hops para reencaminhar anúncios Flood (0-64).';

  @override
  String get repeater_cliHelpGetFloodMaxUnscoped =>
      'Mostra o número máximo de hops para pacotes Flood sem âmbito.';

  @override
  String get repeater_cliHelpGetFloodMaxAdvert =>
      'Mostra o número máximo de hops para anúncios Flood.';

  @override
  String get repeater_cliHelpSetRadioFemRxGain =>
      'Alterna o ganho RX (LNA) do módulo front-end LoRa. As placas sem um respondem \"Error: unsupported\".';

  @override
  String get repeater_cliHelpSetRadioFemTxGain =>
      'Alterna o ganho TX (PA) do módulo front-end LoRa. As placas sem um respondem \"Error: unsupported\".';

  @override
  String get repeater_cliHelpGetRadioFemRxGain =>
      'Mostra se o ganho RX do módulo front-end LoRa está ativo.';

  @override
  String get repeater_cliHelpGetRadioFemTxGain =>
      'Mostra se o ganho TX do módulo front-end LoRa está ativo.';

  @override
  String get repeater_bridgeNote =>
      'Só disponível em firmware compilado com bridge (RS232 ou ESP-NOW).';

  @override
  String get repeater_general => 'Geral';

  @override
  String get repeater_settingsCategory => 'Definições';

  @override
  String get repeater_bridge => 'Ponte';

  @override
  String get repeater_logging => 'Registo';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vizinhos (só repetidor)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gestão de regiões (só repetidor)';

  @override
  String get repeater_regionNote =>
      'Foram introduzidos comandos de região para gerir definições e permissões de regiões.';

  @override
  String get repeater_gpsManagement => 'Gestão de GPS';

  @override
  String get repeater_gpsNote =>
      'O comando gps foi introduzido para gerir tudo o que está relacionado com localização.';

  @override
  String get repeater_getCategory => 'Obter valores';

  @override
  String get repeater_powerMgmt => 'Gestão de energia';

  @override
  String get repeater_sensors => 'Sensores';

  @override
  String get repeater_cliHelpPowerOff =>
      'Desliga o dispositivo. (não se espera resposta)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Repõe o relógio para uma época conhecida e reinicia o dispositivo.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Envia um anúncio zero-hop (só vizinhos imediatos).';

  @override
  String get repeater_cliHelpStartOta =>
      'Inicia uma atualização de firmware over-the-air em placas compatíveis.';

  @override
  String get repeater_cliHelpTime =>
      'Define o relógio do dispositivo para o Unix epoch em segundos indicado. O relógio não pode andar para trás.';

  @override
  String get repeater_cliHelpBoard =>
      'Mostra o fabricante da placa / identificador de hardware.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Envia um pedido de descoberta de nós aos vizinhos próximos. (só repetidor)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Mostra se o modo de poupança de energia está ligado ou desligado.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Ativa ou desativa o modo de poupança de energia (onde suportado).';

  @override
  String get repeater_cliHelpErase =>
      '(Só série) Formata o sistema de ficheiros do dispositivo. Apaga todas as definições e contactos.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Define o duty cycle de transmissão máximo permitido, em percentagem (1-100). Ajusta internamente o fator de airtime.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'Substitui a chave privada de identidade do dispositivo. É necessário reiniciar para aplicar. Gera uma nova chave pública.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(só SX126x) Alterna o ganho RX reforçado para maior sensibilidade com maior consumo de corrente.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Define a cadeia de contacto do proprietário incluída nos anúncios. Use \'|\' para novas linhas.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Define o tamanho do ID do nó usado nos anúncios deste repetidor: 0 = 1 byte (até 64 hops), 1 = 2 bytes (até 32 hops), 2 = 3 bytes (até 21 hops). 3 está reservado. Não afeta os tamanhos que são reencaminhados. Requer firmware v1.14+.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Define a sensibilidade da deteção de ciclos de encaminhamento: off, minimal, moderate ou strict.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Só série) Define rapidamente apenas a frequência. É necessário reiniciar. Prefira \"set radio\" para os parâmetros de rádio completos.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(só bridge ESPNow) Define o canal WiFi (1-14) usado pela bridge.';

  @override
  String get repeater_cliHelpGetName => 'Mostra o nome do nó configurado.';

  @override
  String get repeater_cliHelpGetRole =>
      'Mostra a função do firmware (Repetidor, Room Server, etc.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Mostra a chave pública do dispositivo.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Só série) Mostra a chave privada do dispositivo. Trate-a como segredo.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Mostra se o reencaminhamento de pacotes (função de repetidor) está ligado ou desligado.';

  @override
  String get repeater_cliHelpGetTx => 'Mostra a potência TX atual em dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Mostra a frequência de rádio configurada em MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Mostra os parâmetros de rádio completos: frequência, largura de banda, spreading factor, coding rate.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(só SX126x) Mostra o estado do ganho RX reforçado.';

  @override
  String get repeater_cliHelpGetAf => 'Mostra o fator de airtime atual.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Mostra o duty cycle permitido atual em percentagem.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Mostra o limiar de interferência do canal em dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Mostra o intervalo de reset do AGC em segundos.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Mostra se o modo de ACK duplo está ligado (1) ou desligado (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Mostra se o acesso de convidado só de leitura é permitido.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Mostra o intervalo do anúncio local em minutos.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Mostra o intervalo do anúncio Flood em horas.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Mostra a palavra-passe de convidado configurada.';

  @override
  String get repeater_cliHelpGetLat => 'Mostra a latitude configurada.';

  @override
  String get repeater_cliHelpGetLon => 'Mostra a longitude configurada.';

  @override
  String get repeater_cliHelpGetRxDelay => 'Mostra o valor base de rxdelay.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Mostra o fator de txdelay do modo Flood.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Mostra o fator de txdelay do modo direto.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Mostra o número máximo de hops Flood.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Mostra a cadeia de contacto do proprietário.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Mostra o modo de tamanho do ID do nó usado nos anúncios (0 = 1 byte, 1 = 2 bytes, 2 = 3 bytes).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Mostra a sensibilidade da deteção de ciclos.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Só série) Lista as entradas de controlo de acesso de um repetidor.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Mostra se a bridge está ativada.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Mostra o atraso da bridge em ms.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Mostra se a bridge regista pacotes RX ou TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(só bridge RS232) Mostra o baud rate da bridge.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(só bridge ESPNow) Mostra o canal WiFi da bridge.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(só bridge ESPNow) Mostra o segredo partilhado da bridge.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(só NRF52) Mostra a versão do bootloader.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Mostra o multiplicador do ADC (escala da tensão da bateria).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Indica se a placa tem suporte de gestão de energia.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Mostra a fonte de energia atual: externa ou bateria.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Mostra os motivos do reset e do encerramento mais recentes.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Mostra a tensão da bateria no arranque em mV.';

  @override
  String get repeater_cliHelpSensorGet =>
      'Lê uma definição de sensor personalizada pela chave.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Escreve uma definição de sensor personalizada.';

  @override
  String get repeater_cliHelpSensorList =>
      'Lista todas as definições de sensor personalizadas, paginadas a partir de um índice inicial opcional.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Mostra o âmbito de região predefinido atual.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Define o âmbito de região predefinido. Use \"<null>\" para limpar.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Lista as regiões que permitem tráfego Flood.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Lista as regiões que negam tráfego Flood.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Só série) Mostra estatísticas ao nível dos pacotes.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Só série) Mostra estatísticas do rádio.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Só série) Mostra estatísticas do núcleo do firmware.';

  @override
  String get telemetry_receivedData => 'Dados de telemetria recebidos';

  @override
  String get telemetry_requestTimeout => 'O pedido de telemetria expirou.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Erro ao carregar telemetria: $error';
  }

  @override
  String get telemetry_noData => 'Sem dados de telemetria disponíveis.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Bateria';

  @override
  String get telemetry_voltageLabel => 'Tensão';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura da MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Corrente';

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
  String get telemetry_gyrometerLabel => 'Giroscópio';

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
  String get telemetry_autoFetchQuantity => 'Quantidade de pedidos';

  @override
  String get telemetry_error => 'Não foi possível obter os dados';

  @override
  String get neighbors_receivedData => 'Dados de vizinhos recebidos';

  @override
  String get neighbors_requestTimedOut => 'O pedido de vizinhos expirou.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Erro ao carregar vizinhos: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Vizinhos do repetidor';

  @override
  String get neighbors_noData => 'Sem dados de vizinhos disponíveis.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Desconhecido $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Ouvido: há $time';
  }

  @override
  String get channelPath_title => 'Caminho do pacote';

  @override
  String get channelPath_viewMap => 'Ver mapa';

  @override
  String get channelPath_otherObservedPaths => 'Outros caminhos observados';

  @override
  String get channelPath_repeaterHops => 'Hops de repetidores';

  @override
  String get channelPath_noHopDetails =>
      'Os detalhes dos hops não são fornecidos para este pacote.';

  @override
  String get channelPath_messageDetails => 'Detalhes da mensagem';

  @override
  String get channelPath_senderLabel => 'Remetente';

  @override
  String get channelPath_timeLabel => 'Hora';

  @override
  String get channelPath_repeatsLabel => 'Repetições';

  @override
  String channelPath_pathLabel(int index) {
    return 'Caminho $index';
  }

  @override
  String get channelPath_observedLabel => 'Observado';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Caminho observado $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Sem dados de localização';

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
  String get channelPath_floodPath => 'Flood';

  @override
  String get channelPath_directPath => 'Direto';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 de $total hops';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed de $total hops';
  }

  @override
  String get channelPath_mapTitle => 'Mapa do caminho';

  @override
  String get channelPath_noRepeaterLocations =>
      'Sem localizações de repetidores disponíveis para este caminho.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Caminho $index (principal)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Caminho';

  @override
  String get channelPath_observedPathHeader => 'Caminho observado';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Sem detalhes de hops disponíveis para este pacote.';

  @override
  String get channelPath_unknownRepeater => 'Repetidor desconhecido';

  @override
  String get community_title => 'Comunidade';

  @override
  String get community_create => 'Criar comunidade';

  @override
  String get community_createDesc =>
      'Crie uma nova comunidade e partilhe-a por código QR.';

  @override
  String get community_join => 'Entrar';

  @override
  String get community_joinTitle => 'Entrar na comunidade';

  @override
  String community_joinConfirmation(String name) {
    return 'Quer entrar na comunidade \"$name\"?';
  }

  @override
  String get community_scanQr => 'Ler QR da comunidade';

  @override
  String get community_scanInstructions =>
      'Aponte a câmara a um código QR de comunidade';

  @override
  String get community_showQr => 'Mostrar código QR';

  @override
  String get community_publicChannel => 'Público da comunidade';

  @override
  String get community_hashtagChannel => 'Hashtag da comunidade';

  @override
  String get community_name => 'Nome da comunidade';

  @override
  String get community_enterName => 'Introduza o nome da comunidade';

  @override
  String community_created(String name) {
    return 'Comunidade \"$name\" criada';
  }

  @override
  String community_joined(String name) {
    return 'Entrou na comunidade \"$name\"';
  }

  @override
  String get community_qrTitle => 'Partilhar comunidade';

  @override
  String community_qrInstructions(String name) {
    return 'Leia este código QR para entrar em \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Os canais de hashtag da comunidade só estão acessíveis aos membros da comunidade';

  @override
  String get community_invalidQrCode => 'Código QR de comunidade inválido';

  @override
  String get community_alreadyMember => 'Já é membro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Já é membro de \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Adicionar canal público da comunidade';

  @override
  String get community_addPublicChannelHint =>
      'Adicionar automaticamente o canal público desta comunidade';

  @override
  String get community_noCommunities =>
      'Ainda não entrou em nenhuma comunidade';

  @override
  String get community_scanOrCreate =>
      'Leia um código QR ou crie uma comunidade para começar';

  @override
  String get community_manageCommunities => 'Gerir comunidades';

  @override
  String get community_delete => 'Sair da comunidade';

  @override
  String community_deleteConfirm(String name) {
    return 'Sair de \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Isto também elimina $count canal(ais) e as respetivas mensagens.';
  }

  @override
  String community_deleted(String name) {
    return 'Saiu da comunidade \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerar segredo';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerar a chave secreta de \"$name\"? Todos os membros terão de ler o novo código QR para continuar a comunicar.';
  }

  @override
  String get community_regenerate => 'Regenerar';

  @override
  String community_secretRegenerated(String name) {
    return 'Segredo regenerado para \"$name\"';
  }

  @override
  String get community_updateSecret => 'Atualizar segredo';

  @override
  String community_secretUpdated(String name) {
    return 'Segredo atualizado para \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Leia o novo código QR para atualizar o segredo de \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Adicionar hashtag da comunidade';

  @override
  String get community_addHashtagChannelDesc =>
      'Adicionar um canal de hashtag para esta comunidade';

  @override
  String get community_selectCommunity => 'Selecionar comunidade';

  @override
  String get community_regularHashtag => 'Hashtag normal';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag público (qualquer pessoa pode entrar)';

  @override
  String get community_communityHashtag => 'Hashtag da comunidade';

  @override
  String get community_communityHashtagDesc =>
      'Privado para membros da comunidade';

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
  String get listFilter_heardRecently => 'Ouvidos recentemente';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtros';

  @override
  String get listFilter_all => 'Todos';

  @override
  String get listFilter_favorites => 'Favoritos';

  @override
  String get listFilter_addToFavorites => 'Adicionar aos favoritos';

  @override
  String get listFilter_removeFromFavorites => 'Remover dos favoritos';

  @override
  String get listFilter_users => 'Utilizadores';

  @override
  String get listFilter_repeaters => 'Repetidores';

  @override
  String get listFilter_roomServers => 'Servidores de sala';

  @override
  String get listFilter_unreadOnly => 'Só não lidas';

  @override
  String get listFilter_newGroup => 'Novo grupo';

  @override
  String get pathTrace_you => 'Eu';

  @override
  String get pathTrace_failed => 'O trace do caminho falhou.';

  @override
  String get pathTrace_notAvailable => 'Trace do caminho indisponível.';

  @override
  String get pathTrace_refreshTooltip => 'Atualizar trace do caminho.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Falta a localização num ou mais hops!';

  @override
  String get pathTrace_clearTooltip => 'Limpar caminho.';

  @override
  String get losSelectStartEnd =>
      'Selecione os nós inicial e final para o LOS.';

  @override
  String losRunFailed(String error) {
    return 'A verificação de linha de vista falhou: $error';
  }

  @override
  String get losClearAllPoints => 'Limpar todos os pontos';

  @override
  String get losRunToViewElevationProfile =>
      'Execute o LOS para ver o perfil de elevação';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Toque nos nós ou prima longamente o mapa para pontos personalizados';

  @override
  String get losShowDisplayNodes => 'Mostrar nós de visualização';

  @override
  String get losCustomPoints => 'Pontos personalizados';

  @override
  String losCustomPointLabel(int index) {
    return 'Personalizado $index';
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
    return '$distance $distanceUnit, LOS livre, folga mín. $clearance $heightUnit';
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
  String get losStatusChecking => 'LOS: a verificar...';

  @override
  String get losStatusNoData => 'LOS: sem dados';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total livres, $blocked bloqueados, $unknown desconhecidos';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Dados de elevação indisponíveis para uma ou mais amostras.';

  @override
  String get losErrorInvalidInput =>
      'Pontos/dados de elevação inválidos para o cálculo do LOS.';

  @override
  String get losRenameCustomPoint => 'Mudar o nome do ponto personalizado';

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
  String get losLegendRadioHorizon => 'Horizonte rádio';

  @override
  String get losLegendLosBeam => 'Feixe LOS';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losBlockedSpotsTitle => 'Pontos bloqueados';

  @override
  String get losBlockedSpotsHint =>
      'Toque num ponto bloqueado para o destacar no mapa.';

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
    return 'Bloqueado por $obstruction $heightUnit, a $distanceFromA de A e a $distanceFromB de B ($distanceUnit).';
  }

  @override
  String get losFrequencyLabel => 'Frequência';

  @override
  String get losFrequencyInfoTooltip => 'Ver detalhes do cálculo';

  @override
  String get losFrequencyDialogTitle => 'Cálculo do horizonte rádio';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'A partir de k=$baselineK a $baselineFreq MHz, o cálculo ajusta o fator k para a banda atual de $frequencyMHz MHz, que define o limite do horizonte rádio curvo.';
  }

  @override
  String get contacts_pathTrace => 'Trace do caminho';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Trace do caminho até ao repetidor';

  @override
  String get contacts_repeaterPing => 'Ping ao repetidor';

  @override
  String get contacts_roomPathTrace => 'Trace do caminho até ao room server';

  @override
  String get contacts_roomPing => 'Ping ao room server';

  @override
  String get contacts_chatTraceRoute => 'Rota do trace do caminho';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Trace da rota para $name';
  }

  @override
  String get contacts_clipboardEmpty => 'A área de transferência está vazia.';

  @override
  String get contacts_invalidAdvertFormat => 'Dados de contacto inválidos';

  @override
  String get contacts_contactImported => 'O contacto foi importado.';

  @override
  String get contacts_contactImportFailed => 'Falha ao importar o contacto.';

  @override
  String get discoveredContacts_export => 'Exportar contactos descobertos';

  @override
  String get discoveredContacts_import => 'Importar contactos descobertos';

  @override
  String discoveredContacts_exported(String path) {
    return 'Contactos descobertos exportados para $path.';
  }

  @override
  String discoveredContacts_exportFailed(String error) {
    return 'Falha ao exportar contactos descobertos: $error';
  }

  @override
  String discoveredContacts_imported(int count) {
    return 'Importados $count contactos descobertos.';
  }

  @override
  String get discoveredContacts_importNoContacts =>
      'Nenhum contacto encontrado no ficheiro de importação.';

  @override
  String discoveredContacts_importSummary(
    int imported,
    int skipped,
    int invalid,
  ) {
    return 'Importados $imported contactos descobertos. Ignorados $skipped já conhecidos e $invalid entradas ilegíveis.';
  }

  @override
  String get discoveredContacts_importInvalidFile =>
      'O ficheiro não é uma exportação de contactos descobertos.';

  @override
  String discoveredContacts_importTooLarge(int maxMb) {
    return 'O ficheiro de importação é demasiado grande (máximo $maxMb MB).';
  }

  @override
  String discoveredContacts_importFailed(String error) {
    return 'Falha ao importar contactos descobertos: $error';
  }

  @override
  String get contacts_zeroHopAdvert => 'Anúncio Zero Hop';

  @override
  String get contacts_floodAdvert => 'Anúncio Flood';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Copiar anúncio para a área de transferência';

  @override
  String get contacts_addContactFromClipboard =>
      'Adicionar contacto da área de transferência';

  @override
  String get contacts_scanQrCode => 'Ler código QR';

  @override
  String get contacts_scanQrInstructions =>
      'Aponte a câmara a um código QR de contacto MeshCore';

  @override
  String get contacts_qrFromGallery => 'Ler QR da galeria';

  @override
  String get contacts_noQrCodeFound =>
      'Nenhum código QR encontrado na imagem selecionada.';

  @override
  String get contacts_qrGalleryFailed => 'Não foi possível abrir a galeria.';

  @override
  String get contacts_ShareContact =>
      'Copiar contacto para a área de transferência';

  @override
  String get contacts_ShareContactZeroHop => 'Partilhar contacto por anúncio';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Contacto enviado por anúncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Falha ao enviar o contacto.';

  @override
  String get contacts_contactAdvertCopied =>
      'Anúncio copiado para a área de transferência.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Falha ao copiar o anúncio para a área de transferência.';

  @override
  String get notification_activityTitle => 'Atividade MeshCore';

  @override
  String get notification_lowBatteryTitle => 'Bateria fraca';

  @override
  String notification_lowBatteryBody(String deviceName, int percent) {
    return 'A bateria de $deviceName está em $percent%';
  }

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
  String get notification_sharedLocation => 'Partilhou uma localização';

  @override
  String notification_sharedLocationNamed(String label) {
    return 'Partilhou uma localização: $label';
  }

  @override
  String notification_reacted(String emoji) {
    return 'Reagiu $emoji';
  }

  @override
  String get notification_sentGif => 'Enviou um GIF';

  @override
  String get notification_sentImage => 'Enviou uma imagem';

  @override
  String get notification_actionReply => 'Responder';

  @override
  String get notification_actionMarkRead => 'Marcar como lida';

  @override
  String get notification_actionMuteChannel => 'Silenciar canal';

  @override
  String get notification_replyHint => 'Mensagem';

  @override
  String get notification_you => 'Eu';

  @override
  String get notification_replyFailedTitle => 'Resposta não enviada';

  @override
  String get notification_replyNotConnected =>
      'Sem ligação a um rádio. Volte a ligar no MeshCore Open e envie novamente a resposta.';

  @override
  String get notification_replyTooLong =>
      'A resposta é demasiado longa para ser enviada a partir de uma notificação. Envie-a a partir do MeshCore Open.';

  @override
  String get notification_replyUnavailable =>
      'Esta conversa já não está no rádio ligado.';

  @override
  String get notification_replySendFailed =>
      'A resposta pode não ter sido enviada. Verifique no MeshCore Open e tente novamente.';

  @override
  String get notification_replyAppNotRunning =>
      'O MeshCore Open não está em execução. Abra-o e envie novamente a resposta.';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportar repetidores / room servers para GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporta para ficheiro GPX os repetidores / room servers com localização.';

  @override
  String get settings_gpxExportContacts => 'Exportar companions para GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporta para ficheiro GPX os companions com localização.';

  @override
  String get settings_gpxExportAll => 'Exportar todos os contactos para GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporta para ficheiro GPX todos os contactos com localização.';

  @override
  String get settings_gpxExportSuccess => 'Ficheiro GPX exportado com sucesso.';

  @override
  String get settings_gpxExportNoContacts => 'Sem contactos para exportar.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Não suportado no seu dispositivo/SO';

  @override
  String get settings_gpxExportError => 'Ocorreu um erro ao exportar.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Localizações de repetidores e room servers';

  @override
  String get settings_gpxExportChat => 'Localizações de companions';

  @override
  String get settings_gpxExportAllContacts =>
      'Localizações de todos os contactos';

  @override
  String get settings_gpxExportShareText =>
      'Dados do mapa exportados do meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'Exportação de dados do mapa GPX do meshcore-open';

  @override
  String get snrIndicator_nearByRepeaters => 'Repetidores próximos';

  @override
  String get snrIndicator_lastSeen => 'Visto pela última vez';

  @override
  String get snrIndicator_nearByRepeatersDescription =>
      'Repetidores que o seu rádio ouviu diretamente, do mais recente para o mais antigo.';

  @override
  String get snrIndicator_unknownRepeater => 'Repetidor desconhecido';

  @override
  String get snrIndicator_unknownRepeaterHint =>
      'Este repetidor ainda não está nos seus contactos. O nome, a localização e as opções aparecem quando o seu rádio receber o respetivo anúncio.';

  @override
  String get contactsSettings_title => 'Definições de contactos';

  @override
  String get contactsSettings_autoAddTitle => 'Descoberta automática';

  @override
  String get contactsSettings_otherTitle => 'Outras definições de contactos';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Adicionar utilizadores automaticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Permite que o companion adicione automaticamente os utilizadores descobertos.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Adicionar repetidores automaticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Permite que o companion adicione automaticamente os repetidores descobertos.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Adicionar room servers automaticamente';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Permite que o companion adicione automaticamente os room servers descobertos.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Adicionar sensores automaticamente';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Permite que o companion adicione automaticamente os sensores descobertos.';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Substituir o mais antigo';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Quando a lista de contactos estiver cheia, o contacto mais antigo que não seja favorito será substituído.';

  @override
  String get contactsSettings_evictDiscoveredContactsTitle =>
      'Remover contactos descobertos';

  @override
  String contactsSettings_evictDiscoveredContactsSubtitle(int limit) {
    return 'Quando ativado, a app remove os contactos descobertos mais antigos assim que a lista de descoberta atingir o limite de $limit entradas.';
  }

  @override
  String get discoveredContacts_Title => 'Contactos descobertos';

  @override
  String get discoveredContacts_noMatching => 'Sem contactos correspondentes';

  @override
  String get discoveredContacts_searchHint => 'Pesquisar contactos descobertos';

  @override
  String get discoveredContacts_contactAdded => 'Contacto adicionado';

  @override
  String get discoveredContacts_addContact => 'Adicionar contacto';

  @override
  String get discoveredContacts_copyContact =>
      'Copiar contacto para a área de transferência';

  @override
  String get discoveredContacts_deleteContact => 'Eliminar contacto descoberto';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Eliminar todos os contactos descobertos';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Tem a certeza de que quer eliminar todos os contactos descobertos?';

  @override
  String get discoveredContacts_scan => 'Procurar nós próximos';

  @override
  String get discoveredContacts_scanTitle => 'Nós próximos';

  @override
  String get discoveredContacts_scanExplanation =>
      'Pede aos nós ao alcance direto do rádio que se identifiquem. Repetidores e sensores respondem. Room servers e companions normalmente não.';

  @override
  String get discoveredContacts_scanning => 'A procurar…';

  @override
  String discoveredContacts_scanFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nós encontrados',
      one: '1 nó encontrado',
    );
    return '$_temp0';
  }

  @override
  String get discoveredContacts_scanNoResults =>
      'Nenhum nó respondeu. Os repetidores limitam a frequência das respostas, por isso tente novamente dentro de um minuto.';

  @override
  String get discoveredContacts_scanAgain => 'Procurar novamente';

  @override
  String get discoveredContacts_scanFailed =>
      'Não foi possível enviar o pedido de procura.';

  @override
  String discoveredContacts_scanSignal(String snr, String remoteSnr) {
    return 'Sinal $snr dB · ouviram-nos a $remoteSnr dB';
  }

  @override
  String get discoveredContacts_scanInContacts => 'Já está nos contactos';

  @override
  String get discoveredContacts_scanNameLater =>
      'O nome aparece após o próximo anúncio';

  @override
  String get chat_sendCooldown =>
      'Aguarde um momento antes de enviar novamente.';

  @override
  String get appSettings_jumpToOldestUnread => 'Ir para a mais antiga não lida';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Ao abrir uma conversa com mensagens não lidas, desloca para a primeira não lida em vez da mais recente.';

  @override
  String get appSettings_autoFetchRepeaterSettings =>
      'Obter definições do repetidor automaticamente';

  @override
  String get appSettings_autoFetchRepeaterSettingsSubtitle =>
      'Pede todas as definições ao abrir as definições de um repetidor. Cada uma é um pedido separado por LoRa, por isso é lento e consome airtime. Quando desativado, toque em Atualizar tudo ou atualize secções individuais.';

  @override
  String get appSettings_languageHu => 'Húngaro';

  @override
  String get appSettings_languageJa => 'Japonês';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_tooltip => 'Estatísticas do rádio e da mesh';

  @override
  String get radioStats_screenTitle => 'Estatísticas do rádio';

  @override
  String get radioStats_sectionSignal => 'Sinal';

  @override
  String get radioStats_sectionAirtime => 'Airtime';

  @override
  String get radioStats_notConnected =>
      'Ligue a um dispositivo para ver as estatísticas do rádio.';

  @override
  String get radioStats_firmwareTooOld =>
      'As estatísticas do rádio requerem firmware companion v8 ou superior.';

  @override
  String get radioStats_waiting => 'A aguardar dados…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Ruído de fundo: $noiseDbm dBm';
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
    return 'Airtime TX (total): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Airtime RX (total): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Ruído de fundo (dBm) nas amostras recentes.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Ruído de fundo: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'A obter estatísticas do rádio…';

  @override
  String get radioStats_settingsTile => 'Estatísticas do rádio';

  @override
  String get radioStats_settingsSubtitle =>
      'Ruído de fundo, RSSI, SNR e airtime';

  @override
  String get translation_title => 'Tradução';

  @override
  String get imageMessages_enableTitle => 'Ativar mensagens de imagem';

  @override
  String get imageMessages_enableSubtitle =>
      'Envie imagens pela mesh. Requer a transferência única de um modelo de imagem.';

  @override
  String get imageMessages_modelSectionTitle => 'Modelo de imagem';

  @override
  String get imageMessages_downloadModel => 'Transferir';

  @override
  String get imageMessages_cancelDownload => 'Cancelar';

  @override
  String get imageMessages_removeModel => 'Remover modelo';

  @override
  String get imageMessages_modelReady => 'Pronto';

  @override
  String get imageMessages_modelNotPublished =>
      'Ainda não publicado — esta versão não o consegue transferir.';

  @override
  String get imageMessages_downloadFailed =>
      'Não foi possível transferir o modelo de imagem.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Processar imagens automaticamente';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Reconstrói cada imagem assim que chega. Usa cerca de 2 GB de memória durante um segundo de cada vez; deixe desativado para reconstruir com um toque.';

  @override
  String get translation_enableTitle => 'Ativar tradução';

  @override
  String get translation_enableSubtitle =>
      'Traduz as mensagens recebidas e permite a tradução antes de enviar.';

  @override
  String get translation_composerTitle => 'Traduzir antes de enviar';

  @override
  String get translation_composerSubtitle =>
      'Controla o estado predefinido do ícone de tradução do compositor.';

  @override
  String get translation_autoIncomingTitle =>
      'Traduzir mensagens recebidas automaticamente';

  @override
  String get translation_autoIncomingSubtitle =>
      'Traduz automaticamente as mensagens nas notificações e nas conversas ou canais.';

  @override
  String get translation_translateMessage => 'Traduzir mensagem';

  @override
  String get translation_targetLanguage => 'Idioma de destino';

  @override
  String get translation_useAppLanguage => 'Usar o idioma da app';

  @override
  String get translation_downloadedModelLabel => 'Modelo transferido';

  @override
  String get translation_presetModelLabel => 'Modelo Hugging Face predefinido';

  @override
  String get translation_manualUrlLabel => 'URL do modelo manual';

  @override
  String get translation_downloadModel => 'Transferir modelo';

  @override
  String get translation_downloading => 'A transferir...';

  @override
  String get translation_working => 'A processar...';

  @override
  String get translation_stop => 'Parar';

  @override
  String get translation_mergingChunks =>
      'A juntar as partes transferidas no ficheiro final...';

  @override
  String get translation_downloadedModels => 'Modelos transferidos';

  @override
  String get translation_deleteModel => 'Eliminar modelo';

  @override
  String get translation_modelDownloaded => 'Modelo de tradução transferido.';

  @override
  String get translation_downloadStopped => 'Transferência parada.';

  @override
  String translation_downloadFailed(String error) {
    return 'Falha na transferência: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Introduza primeiro o URL de um modelo.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostrar PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Ocultar PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN de emparelhamento Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Introduza o PIN de $deviceName (deixe em branco se não tiver).';
  }

  @override
  String get translation_messageTranslation => 'Tradução de mensagens';

  @override
  String get translation_translateBeforeSending => 'Traduzir antes de enviar';

  @override
  String get translation_composerEnabledHint =>
      'As mensagens serão traduzidas antes de serem enviadas.';

  @override
  String get translation_composerDisabledHint =>
      'Enviar mensagens no idioma original escrito.';

  @override
  String translation_translateTo(String language) {
    return 'Traduzir para $language';
  }

  @override
  String get translation_translationOptions => 'Opções de tradução';

  @override
  String get translation_systemLanguage => 'Idioma do sistema';

  @override
  String get background_serviceTitle => 'MeshCore em execução';

  @override
  String get background_serviceText => 'A manter o BLE ligado';

  @override
  String appSettings_translationModelDeleted(String name) {
    return '$name eliminado';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Falha ao eliminar: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Falha ao atualizar o canal: $error';
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
  String get contact_typeUnknown => 'Desconhecido';

  @override
  String get map_zoomIn => 'Aumentar zoom';

  @override
  String get map_zoomOut => 'Diminuir zoom';

  @override
  String get map_centerMap => 'Centrar mapa';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'O Web Bluetooth requer um navegador Chromium';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS confirmado';

  @override
  String get pathTrace_legendInferred => 'Posição inferida';

  @override
  String get pathMap_viewSingle => 'Individual';

  @override
  String get pathMap_viewCombined => 'Combinado';

  @override
  String get pathMap_play => 'Reproduzir';

  @override
  String get pathMap_pause => 'Pausar';

  @override
  String get pathMap_replay => 'Repetir';

  @override
  String get pathMap_stepBack => 'Hop anterior';

  @override
  String get pathMap_stepForward => 'Hop seguinte';

  @override
  String get pathMap_animationOn => 'Mostrar animação do pacote';

  @override
  String get pathMap_animationOff => 'Ocultar animação do pacote';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Hop $current de $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Caminhos observados: $count';
  }

  @override
  String get pathMap_primary => 'Principal';

  @override
  String pathMap_alternate(int index) {
    return 'Alt. $index';
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
  String get pathMap_legendShared => 'Segmento partilhado';

  @override
  String get pathMap_legendEstimated => 'Segmento estimado';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Usado por $count caminhos';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hops sem localização — o caminho mostrado é parcial',
      one: '1 hop sem localização — o caminho mostrado é parcial',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Mostrar todos';

  @override
  String get pathMap_hidePath => 'Ocultar caminho';

  @override
  String get pathMap_showPath => 'Mostrar caminho';

  @override
  String get pathMap_collapsePanel => 'Recolher painel';

  @override
  String get pathMap_expandPanel => 'Expandir painel';

  @override
  String get pathMap_expandHopList => 'Expandir lista de hops';

  @override
  String get pathMap_showMap => 'Mostrar mapa';

  @override
  String get pathMap_noLocation => 'Sem localização';

  @override
  String get pathMap_followPacket => 'Fixar vista no pacote';

  @override
  String get pathMap_unfollowPacket => 'Libertar vista do pacote';

  @override
  String get imageSend_title => 'Enviar imagem';

  @override
  String get imageSend_cropNote =>
      'Redimensionada para 512 × 512 · proporção não mantida';

  @override
  String imageSend_lossyNote(int bytes) {
    return 'Comprimida para cerca de $bytes bytes. O modelo do recetor reconstrói-a, por isso os detalhes serão diferentes.';
  }

  @override
  String get imageSend_viewOriginal => 'Original';

  @override
  String get imageSend_viewReconstruction => 'O que os destinatários veem';

  @override
  String get imageSend_reconstructionUnavailable =>
      'Este dispositivo não consegue pré-visualizar a reconstrução.';

  @override
  String get imageSend_modelNotDownloaded =>
      'O modelo de imagem ainda não foi transferido. Transfira-o nas Definições para enviar imagens.';

  @override
  String get imageSend_originalSize => 'Original';

  @override
  String get imageSend_onAirSize => 'No ar';

  @override
  String get imageSend_quality => 'Qualidade';

  @override
  String get imageSend_qualityStandard => 'Normal';

  @override
  String get imageSend_qualityHigh => 'Alta';

  @override
  String get imageSend_packetsLabel => 'Pacotes';

  @override
  String get imageSend_airtimeLabel => 'Tempo no ar';

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
  String get imageSend_radioUnknownTitle => 'Definições do rádio desconhecidas';

  @override
  String get imageSend_radioUnknownBody =>
      'Ligue a um dispositivo para calcular o tempo no ar.';

  @override
  String get imageSend_longSendTitle => 'Transmissão longa';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Isto vai ocupar o canal durante cerca de $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Encaminhamento Flood: todos os repetidores ao alcance retransmitem cada pacote, por isso o canal fica ocupado mais tempo do que isto.';

  @override
  String get imageSend_parityTitle => 'Adicionar pacote de recuperação';

  @override
  String get imageSend_paritySubtitle =>
      'Um pacote extra. As mensagens de grupo não têm confirmação, por isso isto permite ao recetor reconstruir a imagem se se perder um único pacote.';

  @override
  String get imageSend_send => 'Enviar';

  @override
  String get imageSend_cancel => 'Cancelar';

  @override
  String get imageSend_encodeFailed =>
      'Não foi possível codificar esta imagem.';

  @override
  String get imageSend_codecDownloading =>
      'O modelo de imagem ainda está a ser transferido.';

  @override
  String get imageSend_codecUnavailable =>
      'O envio de imagens não está disponível neste dispositivo.';

  @override
  String get imageSend_codecDisabled =>
      'As mensagens de imagem estão desativadas nas definições.';

  @override
  String get imageSend_deviceUnsupported =>
      'Este rádio não consegue enviar pacotes de imagem. Ligue um dispositivo com firmware companion 13 ou superior.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'As imagens viajam como dados de grupo, por isso só podem ser enviadas para um canal — não numa mensagem direta.';

  @override
  String get imageSend_tooLarge =>
      'Essa imagem foi codificada em mais pacotes do que o formato da mesh permite.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pacotes',
      one: 'pacote',
    );
    return 'Imagem enviada em $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'Não foi possível enviar a imagem: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'A enviar imagem — pacote $sent de $total';
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
  String get receivedImage_queued => 'A aguardar descodificação';

  @override
  String get receivedImage_tapToDecode => 'Toque para descodificar';

  @override
  String get receivedImage_decoding => 'A reconstruir… cerca de 1 s';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Imagem incompleta — chegaram $received de $total pacotes';
  }

  @override
  String get receivedImage_corrupt => 'Não foi possível reconstruir a imagem';

  @override
  String get receivedImage_decoderMissing =>
      'Imagem recebida — a descodificação de imagens está desativada';

  @override
  String get receivedImage_evicted => 'Imagem já não guardada';

  @override
  String get receivedImage_retry => 'Tentar novamente';

  @override
  String get receivedImage_decodeAgain => 'Descodificar novamente';

  @override
  String get receivedImage_openSettings => 'Configurar';

  @override
  String get receivedImage_tapToProcess => 'Toque para processar';

  @override
  String get receivedImage_save => 'Guardar imagem';

  @override
  String receivedImage_shareCaption(int bytes) {
    return 'Reconstruída por IA a partir de $bytes bytes; os detalhes finos são gerados, não transmitidos.';
  }

  @override
  String get receivedImage_syntheticBadge => 'Reconstruída por IA';

  @override
  String get receivedImage_packetInfo => 'Info do pacote';

  @override
  String get receivedImage_parityRecovered =>
      'Um pacote foi reconstruído a partir do pacote de recuperação.';

  @override
  String receivedImage_decodeTime(int ms) {
    return 'Reconstruída em $ms ms';
  }

  @override
  String get receivedImage_saveFailed => 'Não foi possível guardar a imagem';

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
    return '$seconds s';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes m $seconds s';
  }

  @override
  String chat_longMessageRetryNote(int count) {
    return 'Mais de 158 bytes: enviada no máximo $count vezes';
  }

  @override
  String get reviewMode_dialogTitle => 'Entrar no modo de revisão?';

  @override
  String get reviewMode_dialogBody =>
      'O modo de revisão liga a um rádio simulado com contactos, canais e mensagens de exemplo. Não é necessário um rádio real.';

  @override
  String get reviewMode_confirm => 'Entrar';

  @override
  String get reviewMode_cancel => 'Cancelar';

  @override
  String get reviewMode_banner => 'Modo de revisão — dados simulados';

  @override
  String get reviewMode_sendTest => 'Enviar mensagem de teste';

  @override
  String get reviewMode_testSent => 'Uma mensagem de teste chegará em breve.';

  @override
  String get reviewMode_exit => 'Sair';

  @override
  String reviewMode_connectFailed(String error) {
    return 'Não foi possível iniciar o modo de revisão: $error';
  }

  @override
  String get channels_waitForSync =>
      'Os canais ainda estão a ser carregados do rádio. Tente novamente quando a sincronização terminar.';

  @override
  String channels_nameTooLong(int maxBytes) {
    return 'O nome é demasiado longo (máx. $maxBytes bytes).';
  }

  @override
  String repeater_valueRequired(String field) {
    return '$field: introduza um valor';
  }

  @override
  String get repeater_floodMaxAdvert => 'Máx. hops de flood de anúncios';

  @override
  String get repeater_floodMaxAdvertHelper =>
      'Máximo de hops que um anúncio em flood pode percorrer (0-64, predefinição 8)';

  @override
  String get repeater_floodMaxUnscoped => 'Máx. hops de flood sem âmbito';

  @override
  String get repeater_floodMaxUnscopedHelper =>
      'Máximo de hops para floods sem âmbito de região (0-64, predefinição 64). Um valor baixo, como 3, mantém o tráfego sem âmbito local.';

  @override
  String get repeater_floodMaxUnscopedUnset => 'Igual ao máx. de flood';

  @override
  String get repeater_rxDelay => 'Atraso de receção';

  @override
  String get repeater_rxDelayHelper =>
      'Retém pacotes flood ouvidos com sinal fraco antes de os reencaminhar, para que os caminhos de sinal forte passem primeiro e se enviem menos duplicados (0-20, 0 desativa).';

  @override
  String get repeater_cad => 'Deteção de atividade no canal';

  @override
  String get repeater_cadHelper =>
      'Escuta atividade antes de transmitir e aguarda enquanto o canal estiver ocupado. Funciona em conjunto com o limiar de interferência.';

  @override
  String get repeater_adcMultiplier => 'Calibração da tensão da bateria';

  @override
  String get repeater_adcMultiplierHelper =>
      'Multiplicador da leitura da tensão da bateria (0-10). 0 usa o valor predefinido da placa.';

  @override
  String get repeater_boardSupportNote =>
      'Nem todas as placas suportam isto. As placas sem suporte rejeitam a alteração.';

  @override
  String get repeater_extraSf => 'Spreading factors extra';

  @override
  String get repeater_extraSfHelper =>
      'Até 3 spreading factors adicionais para escutar em simultâneo, separados por vírgulas (por exemplo 9,10). Deixe vazio para desativar.';

  @override
  String get repeater_lr2021Only =>
      'Apenas para repetidores com rádio LR2021. Os outros repetidores não têm esta definição e rejeitam-na.';

  @override
  String get losMapDetailTooltip => 'Detalhe do mapa';

  @override
  String get losUnitsTooltip => 'Unidades';

  @override
  String get losDistance => 'Distância';

  @override
  String get losClearance => 'Folga';

  @override
  String get losBlockedBy => 'Bloqueado por';

  @override
  String get losObstruction => 'Obstrução';

  @override
  String losDistanceFromA(String distance) {
    return '$distance de A';
  }

  @override
  String get losWorstBadge => 'PIOR';

  @override
  String losBlockedAmount(String amount) {
    return 'Bloqueado $amount';
  }

  @override
  String get losFromA => 'De A';

  @override
  String get losFromB => 'De B';

  @override
  String get losElevation => 'Elevação';

  @override
  String get losCenterOnMap => 'Centrar no mapa';

  @override
  String get losStatusClear => 'Livre';

  @override
  String get losStatusMarginal => 'Marginal';

  @override
  String get losStatusBlocked => 'Bloqueado';

  @override
  String get losStatusCheckingShort => 'A verificar';

  @override
  String get losStatusNoResult => 'Sem resultado';

  @override
  String get losSelectedPill => 'Selecionado';

  @override
  String get gif_tapToLoad => 'Toque para carregar o GIF';

  @override
  String get gif_loadFailedRetry =>
      'Não foi possível carregar o GIF\nToque para tentar novamente';

  @override
  String get qr_cameraPermissionDenied =>
      'Permissão da câmara negada.\nAtive o acesso à câmara nas definições.';

  @override
  String get qr_cameraUnsupported => 'Câmara não suportada neste dispositivo.';

  @override
  String qr_cameraStartFailed(String details) {
    return 'Falha ao iniciar a câmara.\n$details';
  }

  @override
  String imageMessages_downloadFailedWithError(String error) {
    return 'Não foi possível transferir o modelo de imagem: $error';
  }

  @override
  String get map_nodeId => 'ID';

  @override
  String get map_markerHideHint => 'Ocultar: oculto até sair do mapa.';

  @override
  String get map_markerRemoveHint =>
      'Remover: fica oculto até o restaurar no menu de filtros.';

  @override
  String get map_markerRemoved => 'Marcador removido';

  @override
  String get map_restoreRemovedMarkers => 'Restaurar marcadores removidos';

  @override
  String map_restoreRemovedMarkersSubtitle(int count) {
    return '$count removidos';
  }

  @override
  String map_markersRestored(int count) {
    return '$count marcadores restaurados';
  }

  @override
  String get map_setLocationConfirmTitle => 'Definir como a sua localização?';

  @override
  String map_setLocationConfirmBody(String lat, String lon) {
    return 'O seu nó vai anunciar esta posição:\n$lat, $lon';
  }

  @override
  String get map_setLocationAction => 'Definir localização';

  @override
  String get map_locationSetSuccess => 'Localização do nó atualizada';

  @override
  String get map_locationSetFailed =>
      'O dispositivo não confirmou a nova localização. Tente novamente.';

  @override
  String map_poiClusterTitle(int count) {
    return '$count marcadores aqui';
  }

  @override
  String map_poiClusterSemantics(int count) {
    return '$count marcadores partilhados. Toque para os listar.';
  }

  @override
  String map_youWithMarkers(int count) {
    return 'Eu e $count marcadores';
  }

  @override
  String map_sharedMarkerSemantics(String label) {
    return 'Marcador partilhado: $label';
  }

  @override
  String map_nodeMarkerSemantics(String name, String type, String status) {
    return '$name, $type, $status';
  }

  @override
  String get map_requestLocation => 'Atualizar localização';

  @override
  String get map_locationUpdated => 'Localização atualizada';

  @override
  String map_locationNotShared(String name) {
    return '$name respondeu sem localização';
  }

  @override
  String map_locationRequestFailed(String name) {
    return 'Sem resposta de $name';
  }

  @override
  String mapCache_zoomLevel(int zoom) {
    return 'Zoom $zoom';
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
    return 'Transferência cancelada. $count tiles em cache.';
  }

  @override
  String get mapCache_tooManyTilesTitle => 'Área demasiado grande';

  @override
  String mapCache_tooManyTiles(int count, int max) {
    return 'Esta área precisa de $count tiles, mais do que o limite de $max. Escolha uma área mais pequena ou reduza o zoom máximo.';
  }

  @override
  String get chat_clearChatConfirm =>
      'Isto apaga todas as mensagens desta conversa deste dispositivo. Não pode ser anulado.';

  @override
  String get channels_clearChatConfirm =>
      'Isto apaga todas as mensagens deste canal deste dispositivo, incluindo as imagens recebidas. Não pode ser anulado.';

  @override
  String get channels_timeNow => 'agora';

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
    return 'CH $index';
  }

  @override
  String get reaction_unknownSender => 'Desconhecido';

  @override
  String get pathMap_noSelfGpsFix => 'O nó local não tem sinal GPS';

  @override
  String pathTrace_sendFailed(String error) {
    return 'Não foi possível enviar o trace do caminho: $error';
  }

  @override
  String get losErrorNoInternet =>
      'Os dados de elevação precisam de ligação à internet';

  @override
  String get losResultStale => 'Desatualizado: a altura da antena mudou';

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
  String get telemetry_loading => 'A carregar telemetria…';

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
      'Sem ligação a um rádio. Ligue e tente novamente.';

  @override
  String get settings_requiresConnection => 'Ligue a um rádio para usar isto';

  @override
  String settings_txPowerInvalidRange(int min, int max) {
    return 'Potência TX inválida ($min a $max dBm)';
  }

  @override
  String get settings_contactSettingsSaved =>
      'Definições do contacto guardadas';

  @override
  String get settings_batteryToggleHint =>
      'Toque para alternar entre percentagem e tensão';

  @override
  String get settings_publicKeyCopyHint => 'Copiar chave pública';

  @override
  String get settings_locationClearHelper =>
      'Deixe ambos os campos vazios para remover a sua localização.';

  @override
  String get settings_locationCleared => 'Localização removida';

  @override
  String get settings_regionFetchDiscovering =>
      'A procurar repetidores próximos…';

  @override
  String settings_regionFetchProgress(int current, int total) {
    return 'A consultar o repetidor $current de $total…';
  }

  @override
  String get settings_regionFetchNoRepeaters =>
      'Ainda não há repetidores conhecidos. Adicione um repetidor como contacto ou aguarde que um envie um anúncio e tente novamente.';

  @override
  String get settings_regionFetchNoneResponded =>
      'Nenhum repetidor próximo respondeu. Aproxime-se de um repetidor e tente novamente.';

  @override
  String appSettings_sourceSummary(String label, String description) {
    return '$label - $description';
  }

  @override
  String get appSettings_routingSection => 'Encaminhamento';

  @override
  String get appSettings_resetRoutingToDefault =>
      'Repor algoritmo de encaminhamento';

  @override
  String get appSettings_resetRoutingToDefaultSubtitle =>
      'Repõe as definições do algoritmo de encaminhamento para os valores de fábrica';

  @override
  String get appSettings_routingResetToDefault =>
      'Definições do algoritmo de encaminhamento repostas';

  @override
  String get appSettings_imageMessagesSection => 'Mensagens de imagem';

  @override
  String get appSettings_showApiKey => 'Mostrar chave API';

  @override
  String get appSettings_hideApiKey => 'Ocultar chave API';

  @override
  String get translation_defaultModelName => 'Modelo';

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
  String get repeater_radioDisconnected => 'Rádio desligado';

  @override
  String get repeater_radioDisconnectedHint =>
      'Volte a ligar ao rádio para enviar comandos, atualizar ou guardar alterações.';

  @override
  String get repeater_cliSend => 'Enviar comando';

  @override
  String get repeater_cliCopyTranscript => 'Copiar registo';

  @override
  String get repeater_cliShareTranscript => 'Partilhar registo';

  @override
  String get repeater_cliTranscriptCopied => 'Registo copiado';

  @override
  String get repeater_cliClearHistoryConfirm =>
      'Limpar o histórico de comandos? Não pode ser anulado.';

  @override
  String get repeater_cliSearchCommands => 'Pesquisar comandos';

  @override
  String get repeater_cliNoMatchingCommands => 'Sem comandos correspondentes';

  @override
  String get debugLog_clearConfirm =>
      'Limpar todas as entradas do registo? Não pode ser anulado.';

  @override
  String get repeater_unsavedChangesTitle => 'Alterações por guardar';

  @override
  String get repeater_unsavedChangesMessage =>
      'Tem alterações que não foram guardadas no repetidor.';

  @override
  String get repeater_discardChanges => 'Descartar';

  @override
  String repeater_actionSentNoReply(String action) {
    return '$action: comando enviado. O repetidor não responde a este comando.';
  }

  @override
  String repeater_invalidSettingValue(String setting, String value) {
    return '$setting: $value não é válido';
  }

  @override
  String repeater_prvKeyLengthError(int length) {
    return 'A chave privada deve ter exatamente $length carateres hexadecimais';
  }

  @override
  String get contacts_advertFailed => 'Não foi possível enviar o anúncio';

  @override
  String get contacts_manageGroups => 'Gerir grupos';

  @override
  String contacts_keyPrefixSemantics(String prefix) {
    return 'Prefixo da chave $prefix';
  }

  @override
  String community_shortId(String id) {
    return 'ID: $id…';
  }

  @override
  String get tcpSectionTitle => 'TCP / IP';

  @override
  String get tcpConnectedToHeader => 'Ligado a';

  @override
  String get usbChooseSerialPort => 'Escolher porta série';

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
  String get networkMap_settingsSection => 'Mapa da rede';

  @override
  String get networkMap_uploadTitle => 'Partilhar o que o meu rádio ouve';

  @override
  String get networkMap_uploadExplanation =>
      'Quando ativado e com o rádio ligado, a app envia um breve resumo dos pacotes que o seu rádio ouve para o mapa da rede MeshCore Open, para que todos possam ver que repetidores existem e como se ligam entre si. Envia o tipo, a rota, os hops, a intensidade do sinal e o tamanho de cada pacote, bem como os nomes e localizações aproximadas dos repetidores a partir dos seus próprios anúncios. Nunca envia o texto das mensagens, quem fala com quem, nomes de canais, os seus contactos ou a sua posição exata: as localizações são arredondadas para cerca de 2 km e a sua app recebe um novo ID aleatório todos os dias.';

  @override
  String get networkMap_whatWeCollect => 'O que recolhemos';

  @override
  String get networkMap_promptTitle => 'Ajudar a construir o mapa da rede?';

  @override
  String get networkMap_promptBody =>
      'O MeshCore Open pode partilhar o que o seu rádio ouve com o mapa público da rede em map.meshcoreopen.org, para que todos possam ver que repetidores existem e como se ligam entre si.\n\nNunca envia o texto das mensagens, quem fala com quem, nomes de canais, os seus contactos ou a sua posição exata. As localizações são arredondadas para cerca de 2 km.';

  @override
  String get networkMap_promptSettingsHint =>
      'Pode alterar isto a qualquer momento em Definições → Definições da app → Mapa da rede.';

  @override
  String get networkMap_promptAccept => 'Partilhar';

  @override
  String get networkMap_promptDecline => 'Não, obrigado';

  @override
  String get networkMap_statusOff => 'Desativado. Nada é enviado.';

  @override
  String get networkMap_statusWaiting =>
      'Ativado. A aguardar ligação a um rádio.';

  @override
  String get networkMap_statusNothingSent => 'Ativado. Ainda nada enviado.';

  @override
  String networkMap_statusLastSent(String time, int count) {
    return 'Último envio $time. $count pacotes hoje.';
  }

  @override
  String get networkMap_sourceLocal => 'Local';

  @override
  String get networkMap_sourceOnline => 'Online';

  @override
  String get networkMap_sourceBoth => 'Ambos';

  @override
  String get networkMap_sourceLocalHint => 'Nós que o seu rádio ouviu';

  @override
  String get networkMap_sourceOnlineHint =>
      'Repetidores do mapa da rede online';

  @override
  String get networkMap_sourceBothHint =>
      'Os nós do seu rádio mais o mapa da rede online';

  @override
  String get networkMap_zoomInHint =>
      'Aumente o zoom para ver o mapa da rede online';

  @override
  String get networkMap_loadFailed =>
      'Não foi possível carregar o mapa da rede online';

  @override
  String get networkMap_inYourContacts => 'Nos seus contactos';

  @override
  String get networkMap_status => 'Estado';

  @override
  String get networkMap_statusActive => 'Ativo na última hora';

  @override
  String get networkMap_statusRecent => 'Ouvido no último dia';

  @override
  String get networkMap_statusStale => 'Não ouvido recentemente';

  @override
  String get networkMap_confirmed => 'Confirmado';

  @override
  String get networkMap_singleSource => 'Fonte única, ainda não confirmado';

  @override
  String get networkMap_reports => 'Relatórios';

  @override
  String get networkMap_locationEstimated =>
      'Localização aproximada, estimada por quem o ouviu';

  @override
  String get networkMap_locationAdvertised =>
      'Localização aproximada, do seu próprio anúncio';

  @override
  String get networkMap_heardByRadio => 'Ouvido pelo seu rádio';

  @override
  String get networkMap_inYourArea => 'Na sua zona';

  @override
  String get networkMap_farAway => 'Longe. A gestão não o alcançará.';

  @override
  String get networkMap_addToContacts => 'Adicionar aos contactos';

  @override
  String get networkMap_manage => 'Gerir';

  @override
  String get networkMap_addedToContacts => 'Adicionado aos contactos';

  @override
  String get networkMap_addFailed => 'Não foi possível adicionar aos contactos';

  @override
  String get networkMap_unnamed => 'Repetidor sem nome';

  @override
  String get holidayGreeting_halloween =>
      'Feliz Halloween|Happy Halloween|Bom Halloween';

  @override
  String get holidayGreeting_thanksgiving =>
      'Feliz Dia de Ação de Graças|Happy Thanksgiving';

  @override
  String get holidayGreeting_christmas =>
      'Feliz Natal|Boas Festas|Merry Christmas';

  @override
  String get holidayGreeting_newYear =>
      'Feliz Ano Novo|Bom Ano Novo|Happy New Year';

  @override
  String get chat_loadOlderMessages => 'Carregar mensagens mais antigas';

  @override
  String get messageFilter_title => 'Filtro de mensagens';

  @override
  String get messageFilter_settingsSubtitle =>
      'Ocultar spam e mensagens repetidas';

  @override
  String get messageFilter_enabled => 'Filtrar mensagens';

  @override
  String get messageFilter_enabledSubtitle =>
      'Aplica-se às mensagens dos canais';

  @override
  String get messageFilter_displayTitle => 'Mensagens filtradas';

  @override
  String get messageFilter_displayPlaceholder => 'Mostrar um marcador pequeno';

  @override
  String get messageFilter_displayHide => 'Ocultar totalmente';

  @override
  String get messageFilter_displayHideHelp =>
      'As mensagens ocultas permanecem na lista de mensagens filtradas.';

  @override
  String get messageFilter_rulesSection => 'As suas regras';

  @override
  String get messageFilter_rulesEmpty =>
      'Ainda sem regras. Adicione uma palavra, frase ou nome de remetente para ocultar as mensagens correspondentes.';

  @override
  String get messageFilter_addRule => 'Adicionar regra';

  @override
  String get messageFilter_editRule => 'Editar regra';

  @override
  String get messageFilter_rulePattern => 'Palavra, frase ou nome';

  @override
  String get messageFilter_rulePatternHint => 'ex.: meshos';

  @override
  String get messageFilter_ruleWhere => 'Procurar em';

  @override
  String get messageFilter_ruleFieldText => 'Texto da mensagem';

  @override
  String get messageFilter_ruleFieldSender => 'Nome do remetente';

  @override
  String get messageFilter_ruleFieldBoth => 'Ambos';

  @override
  String get messageFilter_ruleMatch => 'Correspondência';

  @override
  String get messageFilter_ruleMatchContains => 'Contém';

  @override
  String get messageFilter_ruleMatchWholeWord => 'Palavra inteira';

  @override
  String get messageFilter_ruleMatchExact => 'Exata';

  @override
  String get messageFilter_ruleDeleted => 'Regra eliminada';

  @override
  String get messageFilter_ruleSaved => 'Regra guardada';

  @override
  String get messageFilter_automaticSection => 'Automático';

  @override
  String get messageFilter_duplicates => 'Mensagens repetidas';

  @override
  String get messageFilter_duplicatesSubtitle =>
      'A mesma mensagem enviada novamente, ou por vários remetentes';

  @override
  String get messageFilter_repeatSends => 'Envios para contar como repetição';

  @override
  String messageFilter_repeatSendsSubtitle(int count) {
    return 'Oculta uma mensagem quando o mesmo remetente a envia $count vezes em 10 minutos';
  }

  @override
  String get messageFilter_repeatedCharacters => 'Carateres repetidos';

  @override
  String get messageFilter_repeatedCharactersSubtitle =>
      'Sequências longas do mesmo carater, como \"aaaaaaaaaaaaaaaaaaaa\"';

  @override
  String get messageFilter_learning => 'Aprender com os toques em Spam';

  @override
  String messageFilter_learningSubtitle(int spam, int notSpam) {
    return '$spam exemplos de spam e $notSpam de não spam';
  }

  @override
  String get messageFilter_resetLearning => 'Repor aprendizagem';

  @override
  String get messageFilter_resetLearningConfirm =>
      'Esquecer tudo o que foi aprendido com os seus toques em Spam e Não é spam? As suas regras são mantidas.';

  @override
  String messageFilter_filteredMessages(int count) {
    return 'Mensagens filtradas ($count)';
  }

  @override
  String get messageFilter_filteredMessagesEmpty => 'Nada foi filtrado.';

  @override
  String get messageFilter_ghostSingle => 'Mensagem oculta · Toque para ver';

  @override
  String messageFilter_ghostMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens ocultas · Toque para ver',
      one: '$count mensagem oculta · Toque para ver',
    );
    return '$_temp0';
  }

  @override
  String get messageFilter_ghostSingleExpanded =>
      'A mostrar mensagem oculta · Toque para ocultar';

  @override
  String messageFilter_ghostManyExpanded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A mostrar $count mensagens ocultas · Toque para ocultar',
      one: 'A mostrar 1 mensagem oculta · Toque para ocultar',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_reasonTextRule(String pattern) {
    return 'Filtrada: corresponde a \"$pattern\"';
  }

  @override
  String messageFilter_reasonSenderRule(String pattern) {
    return 'Filtrada: remetente \"$pattern\"';
  }

  @override
  String get messageFilter_reasonRepeatedCharacters =>
      'Filtrada: carateres repetidos';

  @override
  String get messageFilter_reasonDuplicate => 'Filtrada: mensagem repetida';

  @override
  String get messageFilter_reasonCrossSenderDuplicate =>
      'Filtrada: mesma mensagem de vários remetentes';

  @override
  String get messageFilter_reasonLearned =>
      'Filtrada: parece-se com mensagens que marcou como spam';

  @override
  String get messageFilter_reasonManual => 'Filtrada: marcou-a como spam';

  @override
  String get messageFilter_notSpam => 'Não é spam';

  @override
  String get messageFilter_hideAgain => 'Ocultar';

  @override
  String get messageFilter_markSpam => 'Marcar como spam';

  @override
  String get messageFilter_markedSpam => 'Marcada como spam';

  @override
  String get messageFilter_markedNotSpam => 'Marcada como não spam';

  @override
  String get messageFilter_filterSender => 'Filtrar este remetente';

  @override
  String messageFilter_filterSenderConfirm(String name) {
    return 'Ocultar todas as mensagens de \"$name\"?';
  }

  @override
  String get messageFilter_filterLikeThis => 'Filtrar mensagens como esta…';

  @override
  String get messageFilter_channelToggle => 'Filtrar mensagens neste canal';

  @override
  String get messageFilter_ghostIconTooltip =>
      'Oculta pelo seu filtro de mensagens';

  @override
  String appBar_offlineSubtitle(String name) {
    return 'Offline · $name';
  }

  @override
  String get appBar_offline => 'Offline';

  @override
  String get appBar_reconnecting => 'A religar…';

  @override
  String get connectSheet_title => 'Ligar um rádio';

  @override
  String connectSheet_reconnect(String name) {
    return 'Religar a $name';
  }

  @override
  String get connectSheet_chooseRadio => 'Escolher um rádio';

  @override
  String get connectSheet_chooseRadioSubtitle => 'Bluetooth, USB ou TCP';

  @override
  String get connectSheet_stopReconnecting => 'Parar de religar';

  @override
  String connectSheet_reconnectFailed(String name) {
    return 'Não foi possível contactar $name. Verifique se está ligado e por perto.';
  }

  @override
  String get chat_composerOffline =>
      'Ligue-se a um rádio para enviar mensagens';
}
