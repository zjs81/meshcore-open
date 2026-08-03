// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => '연락처';

  @override
  String get nav_channels => '채널';

  @override
  String get nav_map => '지도';

  @override
  String get common_cancel => '취소';

  @override
  String get common_ok => '확인';

  @override
  String get common_connect => '연결하기';

  @override
  String get common_unknownDevice => '알 수 없는 장치';

  @override
  String get common_save => '저장';

  @override
  String get common_delete => '삭제';

  @override
  String get common_deleteAll => '모두 삭제';

  @override
  String get common_close => '닫기';

  @override
  String get common_done => '완료';

  @override
  String get common_edit => '수정';

  @override
  String get common_add => '추가';

  @override
  String get common_settings => '설정';

  @override
  String get common_disconnect => '연결 해제';

  @override
  String get common_connected => '연결됨';

  @override
  String get common_disconnected => '연결 해제됨';

  @override
  String get common_create => '만들기';

  @override
  String get common_continue => '계속';

  @override
  String get common_share => '공유';

  @override
  String get common_copy => '복사';

  @override
  String get common_retry => '다시 시도';

  @override
  String get common_hide => '숨기기';

  @override
  String get common_remove => '제거';

  @override
  String get common_enable => '사용';

  @override
  String get common_disable => '사용 안 함';

  @override
  String get common_undo => '되돌리기';

  @override
  String get messageStatus_sent => '전송됨';

  @override
  String get messageStatus_delivered => '전달됨';

  @override
  String get messageStatus_pending => '전송 중';

  @override
  String get messageStatus_failed => '전송 실패';

  @override
  String get messageStatus_repeated => '반복 수신됨';

  @override
  String get common_reboot => '재부팅';

  @override
  String get common_loading => '불러오는 중...';

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
  String get common_autoRefresh => '자동 새로고침';

  @override
  String get common_interval => '간격';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => '블루투스';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP를 통해 연결';

  @override
  String get tcpHostLabel => 'IP 주소';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => '포트';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => '엔드포인트를 입력한 뒤 연결하세요.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return '$endpoint에 연결 중...';
  }

  @override
  String get tcpErrorHostRequired => 'IP 주소가 필요합니다.';

  @override
  String get tcpErrorPortInvalid => '포트 번호는 1에서 65535 사이여야 합니다.';

  @override
  String get tcpErrorUnsupported => '이 플랫폼에서는 TCP 트랜스포트를 지원하지 않습니다.';

  @override
  String get tcpErrorTimedOut => 'TCP 연결이 시간 초과되었습니다.';

  @override
  String tcpConnectionFailed(String error) {
    return 'TCP 연결 실패: $error';
  }

  @override
  String get usbScreenTitle => 'USB를 통해 연결';

  @override
  String get usbScreenSubtitle => '감지된 시리얼 장치를 선택하고 MeshCore 노드에 직접 연결하십시오.';

  @override
  String get usbScreenStatus => 'USB 장치를 선택하세요.';

  @override
  String get usbScreenNote =>
      'USB 직렬 통신은 지원되는 Android 기기 및 데스크톱 플랫폼에서 사용할 수 있습니다.';

  @override
  String get usbScreenEmptyState => 'USB 장치가 없습니다. 하나 연결한 뒤 새로고침하세요.';

  @override
  String get usbErrorPermissionDenied => 'USB 접근 권한이 거부되었습니다.';

  @override
  String get usbErrorDeviceMissing => '선택한 USB 장치를 더 이상 사용할 수 없습니다.';

  @override
  String get usbErrorInvalidPort => '유효한 USB 장치를 선택하세요.';

  @override
  String get usbErrorBusy => '다른 USB 연결 요청이 이미 진행 중입니다.';

  @override
  String get usbErrorNotConnected => 'USB 장치가 연결되지 않았습니다.';

  @override
  String get usbErrorOpenFailed => '선택한 USB 장치를 열 수 없습니다.';

  @override
  String get usbErrorConnectFailed => '선택한 USB 장치에 연결하지 못했습니다.';

  @override
  String get usbErrorUnsupported => '이 플랫폼에서는 USB 직렬 통신을 지원하지 않습니다.';

  @override
  String get usbErrorAlreadyActive => 'USB 연결이 이미 활성 상태입니다.';

  @override
  String get usbErrorNoDeviceSelected => 'USB 장치가 선택되지 않았습니다.';

  @override
  String get usbErrorPortClosed => 'USB 연결이 열려 있지 않습니다.';

  @override
  String get usbErrorConnectTimedOut =>
      '연결 시간이 초과되었습니다. 장치에 USB Companion 펌웨어가 있는지 확인하세요.';

  @override
  String get usbFallbackDeviceName => '웹 시리얼 장치';

  @override
  String get usbStatus_notConnected => 'USB 장치를 선택합니다.';

  @override
  String get usbStatus_connecting => 'USB 장치에 연결 중...';

  @override
  String get usbStatus_searching => 'USB 장치 검색 중...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB 연결 실패: $error';
  }

  @override
  String get scanner_scanning => '장치 검색 중...';

  @override
  String get scanner_connecting => '연결 중...';

  @override
  String get scanner_disconnecting => '연결 해제 중...';

  @override
  String get scanner_notConnected => '연결되지 않음';

  @override
  String scanner_connectedTo(String deviceName) {
    return '$deviceName에 연결됨';
  }

  @override
  String get scanner_searchingDevices => 'MeshCore 장치를 검색 중...';

  @override
  String get scanner_tapToScan => 'MeshCore 장치를 찾기 위해 스캔 버튼을 누르세요.';

  @override
  String scanner_connectionFailed(String error) {
    return '연결 실패: $error';
  }

  @override
  String get scanner_stop => '멈춰';

  @override
  String get scanner_scan => '스캔';

  @override
  String get scanner_bluetoothOff => '블루투스가 꺼져 있습니다.';

  @override
  String get scanner_bluetoothOffMessage => '기기를 검색하려면 블루투스를 켜세요.';

  @override
  String get scanner_chromeRequired => 'Chrome 브라우저 필요';

  @override
  String get scanner_chromeRequiredMessage =>
      '이 웹 앱은 블루투스 지원을 위해 Google Chrome 또는 Chromium 기반 브라우저가 필요합니다.';

  @override
  String get scanner_enableBluetooth => '블루투스 켜기';

  @override
  String get scanner_bluetoothWebUnsupported =>
      '브라우저에서는 블루투스를 사용할 수 없습니다. 대신 USB로 연결하세요.';

  @override
  String get device_quickSwitch => '빠른 전환';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => '설정';

  @override
  String get settings_deviceInfo => '장치 정보';

  @override
  String get settings_appSettings => '앱 설정';

  @override
  String get settings_appSettingsSubtitle => '알림, 메시징, 지도 설정';

  @override
  String get settings_nodeSettings => '노드 설정';

  @override
  String get settings_nodeName => '노드 이름';

  @override
  String get settings_nodeNameNotSet => '설정되지 않음';

  @override
  String get settings_nodeNameHint => '노드 이름을 입력하세요';

  @override
  String get settings_nodeNameUpdated => '이름 변경';

  @override
  String get settings_radioSettings => '라디오 설정';

  @override
  String get settings_radioSettingsSubtitle => '주파수, 전력, 확산 계수';

  @override
  String get settings_radioSettingsUpdated => '라디오 설정이 업데이트되었습니다.';

  @override
  String get settings_regionSettings => 'Regions';

  @override
  String get settings_regionSettingsSubtitle => 'Manage stored regions';

  @override
  String get settings_regionManagement_screenTitle => 'Region Management';

  @override
  String get settings_regionNameHint => 'Enter region name';

  @override
  String get settings_regionAddRegion => 'Add region';

  @override
  String get settings_regionFetchRegions => 'Fetch regions from repeaters';

  @override
  String get settings_regionFetchRegionsFail => 'No regions were found';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'This region has already been added';

  @override
  String get settings_regionName => 'Region Name';

  @override
  String get settings_regionDeleted => 'Region deleted';

  @override
  String get settings_deleteRegion => 'Delete Region';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Remove \"$region\" from region list?';
  }

  @override
  String get settings_location => '위치';

  @override
  String get settings_locationSubtitle => 'GPS 좌표';

  @override
  String get settings_locationUpdated => '위치 및 GPS 설정이 업데이트되었습니다.';

  @override
  String get settings_locationBothRequired => '위도와 경도를 모두 입력하세요.';

  @override
  String get settings_locationInvalid => '유효하지 않은 위도 또는 경도.';

  @override
  String get settings_locationGPSEnable => 'GPS 활성화';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'GPS를 사용하여 위치 정보를 자동으로 업데이트할 수 있도록 합니다.';

  @override
  String get settings_locationIntervalSec => 'GPS 간격 (초)';

  @override
  String get settings_locationIntervalInvalid =>
      '간격은 최소 60초 이상, 86400초 미만이어야 합니다.';

  @override
  String get settings_latitude => '위도';

  @override
  String get settings_longitude => '경도';

  @override
  String get settings_contactSettings => '연락처 설정';

  @override
  String get settings_contactSettingsSubtitle => '연락처 추가 방식 설정';

  @override
  String get settings_privacyMode => '개인 정보 보호 모드';

  @override
  String get settings_privacyModeSubtitle => '광고에 이름/위치 정보 숨기기';

  @override
  String get settings_privacyModeToggle =>
      '광고에 자신의 이름과 위치를 숨기기 위해 개인 정보 보호 모드를 켜거나 끄십시오.';

  @override
  String get settings_privacyModeEnabled => '개인 정보 보호 모드 활성화';

  @override
  String get settings_privacyModeDisabled => '개인 정보 보호 모드 비활성화';

  @override
  String get settings_privacy => '개인 정보 설정';

  @override
  String get settings_privacySubtitle => '어떤 정보를 공유할지 통제하세요.';

  @override
  String get settings_privacySettingsDescription =>
      '어떤 정보를 기기가 다른 사람들과 공유할지 선택하세요.';

  @override
  String get settings_denyAll => '모든 것을 부정';

  @override
  String get settings_allowByContact => '연락처 표시 기능 활성화';

  @override
  String get settings_allowAll => '모든 것을 허용';

  @override
  String get settings_telemetryBaseMode => '원격 모니터링 기본 설정';

  @override
  String get settings_telemetryLocationMode => '텔레메트리 위치 모드';

  @override
  String get settings_telemetryEnvironmentMode => '텔레메트리 환경 모드';

  @override
  String get settings_advertLocation => '광고 위치';

  @override
  String get settings_advertLocationSubtitle => '광고에 위치 정보를 포함하세요.';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'GPS 업데이트 시 제로 홉 광고 자동 전송';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'GPS 위치가 변경되면 제로 홉 광고를 전송합니다(광고에 위치 포함 필요).';

  @override
  String get settings_multiAck => '다중 ACK';

  @override
  String get settings_telemetryModeUpdated => '텔레메트리 모드 업데이트 완료';

  @override
  String get settings_actions => '행동';

  @override
  String get settings_deleteAllPaths => '모든 경로 삭제';

  @override
  String get settings_deleteAllPathsSubtitle => '연락처의 모든 경로 데이터를 지웁니다.';

  @override
  String get settings_sendAdvertisement => '광고 전송';

  @override
  String get settings_sendAdvertisementSubtitle => '현재 존재를 방송합니다.';

  @override
  String get settings_advertisementSent => '광고가 전송되었습니다.';

  @override
  String get settings_syncTime => '시간 동기화';

  @override
  String get settings_syncTimeSubtitle => '장치 시계를 휴대폰 시간으로 설정';

  @override
  String get settings_timeSynchronized => '시간이 동기화되었습니다.';

  @override
  String get settings_refreshContacts => '연락처 새로고침';

  @override
  String get settings_refreshContactsSubtitle => '장치에서 연락처 목록을 다시 불러오기';

  @override
  String get settings_rebootDevice => '장치 재부팅';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore 장치를 재부팅합니다.';

  @override
  String get settings_rebootDeviceConfirm => '정말 장치를 재부팅하시겠습니까? 연결이 끊어집니다.';

  @override
  String get settings_debug => '디버그';

  @override
  String get settings_companionDebugLog => '동반 디버깅 로그';

  @override
  String get settings_companionDebugLogSubtitle =>
      'BLE/TCP/USB 명령어, 응답 및 원시 데이터';

  @override
  String get settings_appDebugLog => '앱 디버그 로그';

  @override
  String get settings_appDebugLogSubtitle => '애플리케이션 디버그 메시지';

  @override
  String get settings_about => '정보';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore 오픈 소스 프로젝트';

  @override
  String get settings_aboutDescription =>
      'MeshCore LoRa 메시 네트워크 장치를 위한 오픈소스 Flutter 클라이언트.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS 고도 데이터: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => '이름';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => '상태';

  @override
  String get settings_infoBattery => '배터리';

  @override
  String get settings_infoPublicKey => '공개 키';

  @override
  String get settings_infoContactsCount => '연락처 수';

  @override
  String get settings_infoChannelCount => '채널 수';

  @override
  String get settings_presets => '프리셋';

  @override
  String get settings_frequency => '주파수 (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => '유효하지 않은 주파수 (300-2500 MHz)';

  @override
  String get settings_bandwidth => '대역폭';

  @override
  String get settings_spreadingFactor => '분산 계수';

  @override
  String get settings_codingRate => '코딩 속도';

  @override
  String get settings_txPower => '송신 전력 (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => '유효하지 않은 송신 전력 (0-22 dBm)';

  @override
  String get settings_clientRepeat => '오프그리드 반복';

  @override
  String get settings_clientRepeatSubtitle =>
      '이 장치가 다른 장치의 메시 패킷을 반복하도록 허용합니다.';

  @override
  String get settings_clientRepeatFreqWarning =>
      '오프그리드 반복에는 433MHz, 869MHz 또는 918MHz 주파수가 필요합니다.';

  @override
  String settings_error(String message) {
    return '오류: $message';
  }

  @override
  String get appSettings_title => '앱 설정';

  @override
  String get appSettings_appearance => '모양';

  @override
  String get appSettings_theme => '테마';

  @override
  String get appSettings_themeSystem => '시스템 기본값';

  @override
  String get appSettings_themeLight => '밝음';

  @override
  String get appSettings_themeDark => '어두움';

  @override
  String get appSettings_language => '언어';

  @override
  String get appSettings_languageSystem => '기본 설정';

  @override
  String get appSettings_languageEn => '영어';

  @override
  String get appSettings_languageFr => '프랑스어';

  @override
  String get appSettings_languageEs => '스페인어';

  @override
  String get appSettings_languageDe => '독일어';

  @override
  String get appSettings_languagePl => '폴란드어';

  @override
  String get appSettings_languageSl => '슬로베니아어';

  @override
  String get appSettings_languagePt => '포르투갈어';

  @override
  String get appSettings_languageIt => '이탈리아어';

  @override
  String get appSettings_languageZh => '중국어';

  @override
  String get appSettings_languageSv => '스웨덴어';

  @override
  String get appSettings_languageNl => '네덜란드어';

  @override
  String get appSettings_languageSk => '슬로바키아어';

  @override
  String get appSettings_languageBg => '불가리아어';

  @override
  String get appSettings_languageRu => '러시아어';

  @override
  String get appSettings_languageUk => '우크라이나어';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 byte';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 bytes';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 bytes';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 bytes';

  @override
  String get appSettings_enableMessageTracing => '메시지 추적 기능 활성화';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      '메시지에 대한 상세한 경로 및 시간 정보를 표시';

  @override
  String get appSettings_notifications => '알림';

  @override
  String get appSettings_enableNotifications => '알림 활성화';

  @override
  String get appSettings_enableNotificationsSubtitle => '메시지와 광고에 대한 알림을 받으세요.';

  @override
  String get appSettings_notificationPermissionDenied => '알림 권한 거부';

  @override
  String get appSettings_notificationsEnabled => '알림 사용';

  @override
  String get appSettings_notificationsDisabled => '알림 사용 안 함';

  @override
  String get appSettings_messageNotifications => '메시지 알림';

  @override
  String get appSettings_messageNotificationsSubtitle => '새로운 메시지를 받을 때 알림 표시';

  @override
  String get appSettings_channelMessageNotifications => '채널 메시지 알림';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      '채널 메시지를 수신할 때 알림 표시';

  @override
  String get appSettings_advertisementNotifications => '광고 알림';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      '새 노드가 발견되었을 때 알림 표시';

  @override
  String get appSettings_messaging => '메시징';

  @override
  String get appSettings_clearPathOnMaxRetry => '최대 재시도 시 경로 지우기';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      '전송 시도가 5번 실패하면 연락 경로를 재설정합니다.';

  @override
  String get appSettings_pathsWillBeCleared => '5번 실패하면 해당 경로를 지웁니다.';

  @override
  String get appSettings_pathsWillNotBeCleared => '경로를 자동으로 지우지 않습니다.';

  @override
  String get appSettings_autoRouteRotation => '자동 경로 순환';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      '최적 경로와 플러드 모드 사이를 전환합니다.';

  @override
  String get appSettings_autoRouteRotationEnabled => '자동 경로 순환 기능 활성화';

  @override
  String get appSettings_autoRouteRotationDisabled => '자동 경로 순환 기능 비활성화';

  @override
  String get appSettings_maxRouteWeight => '최대 경로 가중치';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      '한 경로가 성공적인 전송을 통해 누적할 수 있는 최대 가중치';

  @override
  String get appSettings_initialRouteWeight => '초기 경로 가중치';

  @override
  String get appSettings_initialRouteWeightSubtitle => '새로 발견된 경로의 초기 가중치';

  @override
  String get appSettings_routeWeightSuccessIncrement => '성공 시 증가';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      '성공적으로 전송된 경로에 추가되는 가중치';

  @override
  String get appSettings_routeWeightFailureDecrement => '실패 시 감소';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      '전송 실패 후 경로에서 제거되는 가중치';

  @override
  String get appSettings_maxMessageRetries => '최대 메시지 재시도 횟수';

  @override
  String get appSettings_maxMessageRetriesSubtitle => '메시지를 실패로 처리하기 전 시도 횟수';

  @override
  String get appSettings_battery => '배터리';

  @override
  String get appSettings_batteryChemistry => '배터리 종류';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '$deviceName별';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      '배터리 종류를 선택하려면 먼저 장치를 연결하세요.';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => '리튬 폴리머 (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => '지도 표시';

  @override
  String get appSettings_showRepeaters => '리피터 표시';

  @override
  String get appSettings_showRepeatersSubtitle => '지도에 리피터 노드를 표시';

  @override
  String get appSettings_showChatNodes => '채팅 노드 표시';

  @override
  String get appSettings_showChatNodesSubtitle => '지도에 채팅 노드를 표시';

  @override
  String get appSettings_showOtherNodes => '다른 노드 표시';

  @override
  String get appSettings_showOtherNodesSubtitle => '지도에 다른 노드 유형을 표시';

  @override
  String get appSettings_timeFilter => '시간 필터';

  @override
  String get appSettings_timeFilterShowAll => '모든 노드 표시';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '최근 $hours시간 동안의 노드 표시';
  }

  @override
  String get appSettings_mapTimeFilter => '지도 시간 필터';

  @override
  String get appSettings_showNodesDiscoveredWithin => '다음 기간 내에 발견된 노드 표시:';

  @override
  String get appSettings_allTime => '전체 기간';

  @override
  String get appSettings_lastHour => '지난 1시간';

  @override
  String get appSettings_last6Hours => '지난 6시간';

  @override
  String get appSettings_last24Hours => '지난 24시간';

  @override
  String get appSettings_lastWeek => '지난 주';

  @override
  String get appSettings_rasterTileSource => '래스터 타일 소스';

  @override
  String get appSettings_stadiaEndpoint => 'Stadia 엔드포인트';

  @override
  String get appSettings_stadiaApiKey => 'Stadia API 키';

  @override
  String get appSettings_stadiaApiKeyRequired => 'Stadia Maps를 사용하려면 필요합니다';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return '설정됨: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Stadia Maps API 키를 입력하세요. 이 앱은 래스터 타일 요청에 이 키를 사용합니다.';

  @override
  String get appSettings_offlineMapCache => '오프라인 지도 캐시';

  @override
  String get appSettings_unitsTitle => '단위';

  @override
  String get appSettings_unitsMetric => '미터법 (m / km)';

  @override
  String get appSettings_unitsImperial => '영국식 (ft / mi)';

  @override
  String get appSettings_noAreaSelected => '선택된 영역 없음';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return '선택된 영역 (줌 레벨: $minZoom - $maxZoom)';
  }

  @override
  String get appSettings_debugCard => '디버그';

  @override
  String get appSettings_appDebugLogging => '앱 디버그 로깅';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      '문제 해결을 위한 앱 디버그 메시지를 기록합니다.';

  @override
  String get appSettings_appDebugLoggingEnabled => '앱 디버깅 로깅 활성화';

  @override
  String get appSettings_appDebugLoggingDisabled => '앱 디버깅 로깅 비활성화';

  @override
  String get contacts_title => '연락처';

  @override
  String get contacts_noContacts => '아직 연락처는 없습니다.';

  @override
  String get contacts_contactsWillAppear => '장치가 광고를 할 때, 연락처 정보가 표시됩니다.';

  @override
  String get contacts_unread => '읽지 않음';

  @override
  String get contacts_searchContactsNoNumber => '연락처 검색...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '$number $str 연락처 검색...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return '$number $str 검색 결과 보기...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return '$number $str 사용자 검색...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return '$number $str 검색 결과 반복기 검색';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return '$number $str 방 서버 검색';
  }

  @override
  String get contacts_noUnreadContacts => '읽지 않은 연락처가 없습니다.';

  @override
  String get contacts_noContactsFound => '연락처 또는 그룹이 검색되지 않았습니다.';

  @override
  String get contacts_deleteContact => '연락처 삭제';

  @override
  String contacts_removeConfirm(String contactName) {
    return '$contactName를 연락처 목록에서 제거하시겠습니까?';
  }

  @override
  String get contacts_manageRepeater => '리피터 관리';

  @override
  String get contacts_manageRoom => '방 서버 관리';

  @override
  String get contacts_roomLogin => '방 서버 로그인';

  @override
  String get contacts_openChat => '자유로운 대화';

  @override
  String get contacts_editGroup => '편집 그룹';

  @override
  String get contacts_deleteGroup => '그룹 삭제';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '$groupName 삭제?';
  }

  @override
  String get contacts_newGroup => '새로운 그룹';

  @override
  String get contacts_moreOptions => '더 많은 옵션';

  @override
  String get contacts_searchOpen => '연락처 검색';

  @override
  String get contacts_searchClose => '검색 닫기';

  @override
  String get contacts_groupName => '그룹 이름';

  @override
  String get contacts_groupNameRequired => '그룹 이름이 필요합니다';

  @override
  String get contacts_groupNameReserved => '이 그룹 이름은 이미 사용 중입니다.';

  @override
  String contacts_groupAlreadyExists(String name) {
    return '그룹 \"$name\"은 이미 존재합니다.';
  }

  @override
  String get contacts_filterContacts => '연락처 필터링...';

  @override
  String get contacts_noContactsMatchFilter => '입력하신 검색 조건과 일치하는 연락처가 없습니다.';

  @override
  String get contacts_noMembers => '회원 없음';

  @override
  String get contacts_lastSeenNow => '최근';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes분';
  }

  @override
  String get contacts_lastSeenHourAgo => '약 1시간';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours시간';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1일';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days일';
  }

  @override
  String get contact_info => '연락처';

  @override
  String get contact_settings => '연락처 설정';

  @override
  String get contact_telemetry => '텔레메트리';

  @override
  String get contact_lastSeen => '마지막으로 목격';

  @override
  String get contact_clearChat => '명확한 대화';

  @override
  String get contact_teleBase => '텔레메트리 기반';

  @override
  String get contact_teleBaseSubtitle => '배터리 잔량 및 기본적인 통신 데이터를 공유할 수 있도록 허용';

  @override
  String get contact_teleLoc => '텔레메트리 위치';

  @override
  String get contact_teleLocSubtitle => '위치 정보 공유 허용';

  @override
  String get contact_teleEnv => '텔레메트리 환경';

  @override
  String get contact_teleEnvSubtitle => '환경 센서 데이터를 공유하도록 허용';

  @override
  String get channels_title => '채널';

  @override
  String get channels_noChannelsConfigured => '구성된 채널이 없습니다.';

  @override
  String get channels_addPublicChannel => '공개 채널 추가';

  @override
  String get channels_searchChannels => '검색 채널...';

  @override
  String get channels_noChannelsFound => '채널을 찾을 수 없습니다.';

  @override
  String channels_channelIndex(int index) {
    return '채널 $index';
  }

  @override
  String get channels_public => '대중의';

  @override
  String channels_via(String path) {
    return '$path 경유';
  }

  @override
  String get channels_private => '사립';

  @override
  String get channels_editChannel => '채널 편집';

  @override
  String get channels_muteChannel => '음소거 채널';

  @override
  String get channels_unmuteChannel => '채널 음소거 해제';

  @override
  String get channels_deleteChannel => '채널 삭제';

  @override
  String channels_deleteChannelConfirm(String name) {
    return '$name 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return '채널 \"$name\" 삭제에 실패했습니다.';
  }

  @override
  String channels_channelDeleted(String name) {
    return '채널 \"$name\" 삭제';
  }

  @override
  String get channels_addChannel => '채널 추가';

  @override
  String get channels_channelIndexLabel => '채널 인덱스';

  @override
  String get channels_channelName => '채널 이름';

  @override
  String get channels_usePublicChannel => '공개 채널 사용';

  @override
  String get channels_standardPublicPsk => '표준 공공 PSK';

  @override
  String get channels_pskHex => 'PSK (헥스)';

  @override
  String get channels_generateRandomPsk => '임의의 PSK 생성';

  @override
  String get channels_enterChannelName => '채널 이름을 입력해 주세요.';

  @override
  String get channels_pskMustBe32Hex => 'PSK(개인식별키)는 32자리 16진수 문자여야 합니다.';

  @override
  String channels_channelAdded(String name) {
    return '채널 \"$name\" 추가';
  }

  @override
  String channels_editChannelTitle(int index) {
    return '채널 $index 편집';
  }

  @override
  String get channels_smazCompression => 'SMAZ 압축';

  @override
  String get channels_cyr2latCompression => 'Cyr2Lat 압축';

  @override
  String get channels_cyr2latCompressionDscr => '보낼 때 일부 키릴 문자를 라틴 문자로 바꿉니다.';

  @override
  String get channels_cyr2latSettingsHeading => 'Cyr2Lat 설정';

  @override
  String get channels_cyr2latSettingsSubheading => '변환 목록';

  @override
  String get channels_cyr2latSettingsDscr => '문자 변환 JSON 구성 편집';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON 변환 맵';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return '잘못된 JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return '채널 \"$name\"이 업데이트되었습니다.';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Cyr2Lat 프로필 추가';

  @override
  String get settings_cyr2latProfileName => '프로필 이름';

  @override
  String get settings_cyr2latProfileNameEmpty => '프로필 이름은 비워둘 수 없습니다';

  @override
  String get settings_cyr2latProfileAdded => '프로필이 성공적으로 추가되었습니다';

  @override
  String get settings_cyr2latProfileUpdated => '프로필이 성공적으로 업데이트되었습니다';

  @override
  String get settings_cyr2latProfileEdit => 'Cyr2Lat 프로필 편집';

  @override
  String get settings_cyr2latProfileDelete => 'Cyr2Lat 프로필 삭제';

  @override
  String get settings_cyr2latProfileDeleted => '프로필이 성공적으로 삭제되었습니다';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return '\"$name\" 프로필을 삭제하시겠습니까?';
  }

  @override
  String get channels_publicChannelAdded => '공개 채널 추가';

  @override
  String get channels_sortBy => '정렬 기준 선택';

  @override
  String get channels_sortManual => '사용 설명서';

  @override
  String get channels_sortAZ => 'A부터 Z까지';

  @override
  String get channels_sortLatestMessages => '최신 메시지';

  @override
  String get channels_sortUnread => '읽지 않음';

  @override
  String get channels_createPrivateChannel => '개인 채널 만들기';

  @override
  String get channels_createPrivateChannelDesc => '비밀 키로 암호화되어 있습니다.';

  @override
  String get channels_joinPrivateChannel => '개인 채널에 참여하기';

  @override
  String get channels_joinPrivateChannelDesc => '비밀 키를 수동으로 입력합니다.';

  @override
  String get channels_joinPublicChannel => '공개 채널에 참여하세요';

  @override
  String get channels_joinPublicChannelDesc => '누구나 이 채널에 참여할 수 있습니다.';

  @override
  String get channels_joinHashtagChannel => '해시태그 채널에 참여하세요';

  @override
  String get channels_joinHashtagChannelDesc => '누구나 해시태그 채널에 참여할 수 있습니다.';

  @override
  String get channels_scanQrCode => 'QR 코드를 스캔';

  @override
  String get channels_scanQrCodeComingSoon => '곧 출시';

  @override
  String get channels_enterHashtag => '해시태그 입력';

  @override
  String get channels_hashtagHint => '예: #팀';

  @override
  String channels_regionSetTo(String region) {
    return 'Region: $region';
  }

  @override
  String get channels_regionNotSet => 'Region: none';

  @override
  String get channels_regionSelect_Title => 'Select a region';

  @override
  String get channels_clearRegion => 'Clear region';

  @override
  String get chat_noMessages => '아직 메시지가 없습니다.';

  @override
  String get chat_sendMessage => '메시지를 보내기';

  @override
  String chat_sendMessageTo(String contactName) {
    return '$contactName에게 메시지를 보내';
  }

  @override
  String get chat_sendMessageToStart => '시작하려면 메시지를 보내세요.';

  @override
  String get chat_originalMessageNotFound => '원래 메시지를 찾을 수 없음';

  @override
  String chat_replyingTo(String name) {
    return '$name에게 답변';
  }

  @override
  String chat_replyTo(String name) {
    return '$name님께 회신';
  }

  @override
  String get chat_location => '위치';

  @override
  String get chat_typeMessage => '메시지를 입력하세요...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return '메시지가 너무 길어서 (최대 $maxBytes 바이트).';
  }

  @override
  String get chat_messageCopied => '메시지가 복사되었습니다';

  @override
  String get chat_messageDeleted => '메시지가 삭제되었습니다.';

  @override
  String get chat_retryingMessage => '재시도 메시지';

  @override
  String chat_retryCount(int current, int max) {
    return '$current/$max 시도';
  }

  @override
  String get chat_sendGif => 'GIF 보내기';

  @override
  String get chat_receivedGif => 'Received a GIF';

  @override
  String get chat_reply => '답변';

  @override
  String get chat_addReaction => '댓글 추가';

  @override
  String get chat_me => '나';

  @override
  String get emojiCategorySmileys => '이모티콘';

  @override
  String get emojiCategoryGestures => '제스처';

  @override
  String get emojiCategoryHearts => '심장';

  @override
  String get emojiCategoryObjects => '대상';

  @override
  String get gifPicker_title => 'GIF 선택';

  @override
  String get gifPicker_searchHint => 'GIF 검색...';

  @override
  String get gifPicker_poweredBy => 'GIPHY에서 제공';

  @override
  String get gifPicker_noGifsFound => 'GIF 파일이 없습니다.';

  @override
  String get gifPicker_failedLoad => 'GIF 파일 로딩 실패';

  @override
  String get gifPicker_failedSearch => 'GIF 검색에 실패했습니다.';

  @override
  String get gifPicker_noInternet => '인터넷 연결 없음';

  @override
  String get debugLog_appTitle => '앱 디버깅 로그';

  @override
  String get debugLog_bleTitle => 'BLE 디버그 로그';

  @override
  String get debugLog_copyLog => '로그 기록';

  @override
  String get debugLog_clearLog => '명확한 로그';

  @override
  String get debugLog_copied => '디버깅 로그 복사';

  @override
  String get debugLog_bleCopied => 'BLE 로그 복사';

  @override
  String get debugLog_noEntries => '현재 디버깅 로그는 생성되지 않았습니다.';

  @override
  String get debugLog_enableInSettings => '설정에서 앱 디버깅 로깅을 활성화합니다.';

  @override
  String get debugLog_frames => '프레임';

  @override
  String get debugLog_rawLogRx => '원시 로그-RX';

  @override
  String get debugLog_noBleActivity => '현재 BLE 관련 활동은 없습니다.';

  @override
  String debugFrame_length(int count) {
    return '프레임 길이: $count 바이트';
  }

  @override
  String debugFrame_command(String value) {
    return '명령: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => '텍스트 메시지 프레임:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- 목적지 공개 키: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- 시간: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- 플래그: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- 텍스트 유형: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => '명령줄 인터페이스 (CLI)';

  @override
  String get debugFrame_textTypePlain => '일반 텍스트';

  @override
  String debugFrame_text(String text) {
    return '- 텍스트: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => '헥스 덤프:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '홉',
      one: '홉',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => '경로 제거';

  @override
  String get chat_noPathHistoryYet => '아직 경로 기록이 없습니다.\n경로를 찾기 위해 메시지를 보내세요.';

  @override
  String get chat_pathCleared => '경로가 확보되었습니다. 다음 메시지는 경로를 다시 찾을 것입니다.';

  @override
  String get chat_fullPath => '전체 경로';

  @override
  String get routing_title => '라우팅';

  @override
  String get routing_modeAuto => '자동';

  @override
  String get routing_modeFlood => '플러드';

  @override
  String get routing_modeManual => '수동';

  @override
  String get routing_modeAutoHint =>
      '가장 잘 알려진 경로를 자동으로 선택하고, 경로가 없으면 플러드로 전환합니다.';

  @override
  String get routing_modeFloodHint =>
      '모든 중계기를 통해 방송합니다. 가장 안정적이지만 송신 시간을 더 많이 사용합니다.';

  @override
  String get routing_modeManualHint => '항상 지정한 정확한 경로를 따릅니다.';

  @override
  String get routing_currentRoute => '현재 경로';

  @override
  String get routing_directNoHops => '직접 연결 - 중계 없음';

  @override
  String get routing_noPathYet => '아직 경로가 없습니다. 다음 메시지가 도착할 때까지 계속 탐색합니다.';

  @override
  String get routing_floodBroadcast => '모든 중계기를 통해 방송';

  @override
  String get routing_editPath => '경로 편집';

  @override
  String get routing_forgetPath => '경로 지우기';

  @override
  String get routing_knownPaths => '알려진 경로';

  @override
  String get routing_knownPathsHint => '전환할 경로를 선택하세요.';

  @override
  String get routing_inUse => '사용 중';

  @override
  String get routing_qualityStrong => '매우 좋음';

  @override
  String get routing_qualityGood => '좋음';

  @override
  String get routing_qualityFair => '보통';

  @override
  String get routing_qualityWorked => '작동함';

  @override
  String get routing_qualityFlood => '플러드로 수신됨';

  @override
  String get routing_qualityUntested => '미검증';

  @override
  String routing_lastWorked(String when) {
    return '$when에 작동';
  }

  @override
  String get routing_neverWorked => '아직 작동한 적 없음';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes건 성공, $failures건 실패';
  }

  @override
  String get routing_floodDelivery => '플러드 전송';

  @override
  String get pathEditor_title => '경로 만들기';

  @override
  String pathEditor_hopCounter(int count) {
    return '64개 중 $count 홉';
  }

  @override
  String get pathEditor_noHops =>
      '아직 홉이 추가되지 않았습니다. 아래 탭을 사용해 순서대로 추가하거나, 홉 없이 바로 보내려면 \"홉 없음\"으로 저장하세요.';

  @override
  String get pathEditor_addHops => '홉을 순서대로 추가하세요.';

  @override
  String get pathEditor_searchRepeaters => '리피터 검색';

  @override
  String get pathEditor_advancedHex => '고급: 원시 HEX 경로';

  @override
  String get pathEditor_hexLabel => 'HEX 접두사';

  @override
  String get pathEditor_hexHelper => '각 홉마다 2개의 16진수 바이트, 쉼표로 구분';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return '유효하지 않음: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => '최대 64개의 홉';

  @override
  String get pathEditor_usePath => '이 경로 사용';

  @override
  String get pathEditor_removeHop => '홉 제거';

  @override
  String get pathEditor_unknownHop => '알 수 없는 중계기';

  @override
  String get chat_pathSavedLocally => '로컬에 저장되었습니다. 동기화할 장치에 연결하세요.';

  @override
  String get chat_pathDeviceConfirmed => '장치가 확인되었습니다.';

  @override
  String get chat_pathDeviceNotConfirmed => '기기가 아직 확인되지 않았습니다.';

  @override
  String get chat_type => '유형';

  @override
  String get chat_path => '경로';

  @override
  String get chat_publicKey => '공개 키';

  @override
  String get chat_compressOutgoingMessages => '전송되는 메시지 압축';

  @override
  String get chat_floodForced => '플러드 (강제)';

  @override
  String get chat_directForced => '직접 (강제)';

  @override
  String chat_hopsForced(int count) {
    return '$count홉 (강제)';
  }

  @override
  String get chat_floodAuto => '플러드 (자동)';

  @override
  String get chat_direct => '직접';

  @override
  String get chat_poiShared => '공유된 POI';

  @override
  String chat_unread(int count) {
    return '읽지 않음: $count';
  }

  @override
  String get chat_markAsUnread => '미리 읽지 않음으로 표시';

  @override
  String get chat_newMessages => '새로운 메시지';

  @override
  String get chat_openLink => '링크를 열기?';

  @override
  String get chat_openLinkConfirmation => '이 링크를 브라우저에서 열고 싶으신가요?';

  @override
  String get chat_open => '열기';

  @override
  String chat_couldNotOpenLink(String url) {
    return '링크를 열 수 없습니다: $url';
  }

  @override
  String get chat_invalidLink => '유효하지 않은 링크 형식';

  @override
  String get map_title => '노드 매핑';

  @override
  String get map_searchHint => '노드 이름 또는 ID 검색';

  @override
  String get map_activity => '활동';

  @override
  String get map_online => '온라인';

  @override
  String get map_recent => '최근';

  @override
  String get map_stale => '오래됨';

  @override
  String get map_visible => '보임';

  @override
  String get map_hidden => '숨김';

  @override
  String get map_centerOnNode => '노드 중심으로 보기';

  @override
  String get map_details => '세부 정보';

  @override
  String get map_noGps => 'GPS 없음';

  @override
  String get map_noResults => '일치하는 노드가 없습니다.';

  @override
  String get map_lineOfSight => '시야';

  @override
  String get map_losScreenTitle => '시야';

  @override
  String get map_noNodesWithLocation => '위치 정보가 있는 노드가 없습니다.';

  @override
  String get map_nodesNeedGps => '노드는 지도에 표시되려면 GPS 좌표를 공유해야 합니다.';

  @override
  String map_nodesCount(int count) {
    return '노드: $count';
  }

  @override
  String map_pinsCount(int count) {
    return '핀: $count';
  }

  @override
  String get map_chat => '채팅';

  @override
  String get map_repeater => '반복기';

  @override
  String get map_room => '방';

  @override
  String get map_sensor => '센서';

  @override
  String get map_pinDm => '핀 (DM)';

  @override
  String get map_pinPrivate => '개인 계정';

  @override
  String get map_pinPublic => '공개 (일반 공개)';

  @override
  String get map_lastSeen => '마지막으로 목격';

  @override
  String get map_disconnectConfirm => '이 장치와의 연결을 해제하시겠습니까?';

  @override
  String get map_from => '~부터';

  @override
  String get map_source => '출처';

  @override
  String get map_flags => '깃발';

  @override
  String get map_type => '유형';

  @override
  String get map_path => '경로';

  @override
  String get map_location => '위치';

  @override
  String get map_estLocation => '추정 위치';

  @override
  String get map_publicKey => '공개 키';

  @override
  String get map_publicKeyPrefixHint => '예: ab12';

  @override
  String get map_shareMarkerHere => '여기에서 마커 공유';

  @override
  String get map_setAsMyLocation => '내 위치로 설정';

  @override
  String get map_pinLabel => '핀 라벨';

  @override
  String get map_label => '레이블';

  @override
  String get map_pointOfInterest => '관심 지점';

  @override
  String get map_sendToContact => '연락처로 보내기';

  @override
  String get map_sendToChannel => '채널로 전송';

  @override
  String get map_noChannelsAvailable => '사용 가능한 채널이 없습니다.';

  @override
  String get map_publicLocationShare => '공개 장소 공유';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '현재 $channelLabel 채널에서 위치 정보를 공유하려고 합니다. 이 채널은 공개되어 있으며, PSK를 가진 모든 사용자가 이 위치 정보를 볼 수 있습니다.';
  }

  @override
  String get map_connectToShareMarkers => '장치를 연결하여 마커를 공유';

  @override
  String get map_filterNodes => '필터 노드';

  @override
  String get map_nodeTypes => '노드 유형';

  @override
  String get map_chatNodes => '채팅 노드';

  @override
  String get map_repeaters => '다시 보내는 장치';

  @override
  String get map_otherNodes => '다른 노드';

  @override
  String get map_showOverlaps => '반복 키 중복';

  @override
  String get map_keyPrefix => '핵심 접두사';

  @override
  String get map_filterByKeyPrefix => '주요 접두사 기준으로 필터링';

  @override
  String get map_publicKeyPrefix => '공개 키 접두사';

  @override
  String get map_markers => '마커';

  @override
  String get map_showSharedMarkers => '공통 마커 표시';

  @override
  String get map_showGuessedLocations => '추정된 노드 위치 표시';

  @override
  String get map_showDiscoveryContacts => '디스커버리 담당자 연락처 보기';

  @override
  String get map_guessedLocation => '추측된 위치';

  @override
  String get map_lastSeenTime => '마지막으로 확인된 시간';

  @override
  String get map_sharedPin => '공유 비밀번호';

  @override
  String get map_sharedAt => '공유됨';

  @override
  String get map_joinRoom => '방에 참여';

  @override
  String get map_manageRepeater => '리피터 관리';

  @override
  String get map_tapToAdd => '노드에 클릭하여 경로에 추가합니다.';

  @override
  String get map_runTrace => '경로 추적';

  @override
  String get map_runTraceWithReturnPath => '원래 경로로 돌아가세요.';

  @override
  String get map_removeLast => '마지막 항목 삭제';

  @override
  String get map_pathTraceCancelled => '경로 추적 기능이 취소되었습니다.';

  @override
  String get mapCache_title => '오프라인 지도 캐시';

  @override
  String get mapCache_selectAreaFirst => '캐시할 영역을 먼저 선택하세요';

  @override
  String get mapCache_noTilesToDownload => '이 지역에 다운로드할 타일이 없습니다.';

  @override
  String get mapCache_downloadTilesTitle => '타일 다운로드';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return '$count개의 타일을 오프라인 사용을 위해 다운로드하시겠습니까?';
  }

  @override
  String get mapCache_downloadAction => '다운로드';

  @override
  String mapCache_cachedTiles(int count) {
    return '$count 개의 타일 캐시';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return '캐시된 타일 $downloaded개 ($failed개 실패)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => '오프라인 캐시 삭제';

  @override
  String get mapCache_clearOfflineCachePrompt => '모든 캐시된 지도 템플릿을 삭제하시겠습니까?';

  @override
  String get mapCache_offlineCacheCleared => '오프라인 캐시 삭제';

  @override
  String get mapCache_noAreaSelected => '선택된 영역 없음';

  @override
  String get mapCache_cacheArea => '캐시 영역';

  @override
  String get mapCache_useCurrentView => '현재 보기 유지';

  @override
  String get mapCache_zoomRange => '줌 기능 범위';

  @override
  String mapCache_estimatedTiles(int count) {
    return '예상되는 타일 개수: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return '다운로드됨 $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => '타일 다운로드';

  @override
  String get mapCache_clearCacheButton => '캐시 삭제';

  @override
  String mapCache_failedDownloads(int count) {
    return '실패한 다운로드: $count';
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
  String get time_justNow => '방금';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String time_daysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get time_hour => '시간';

  @override
  String get time_hours => '시간';

  @override
  String get time_day => '하루';

  @override
  String get time_days => '일';

  @override
  String get time_week => '주';

  @override
  String get time_weeks => '몇 주';

  @override
  String get time_month => '달';

  @override
  String get time_months => '개월';

  @override
  String get time_minutes => '분';

  @override
  String get time_allTime => '모든 시간';

  @override
  String get dialog_disconnect => '연결 해제';

  @override
  String get dialog_disconnectConfirm => '이 장치와의 연결을 해제하시겠습니까?';

  @override
  String get login_repeaterLogin => '다시 로그인';

  @override
  String get login_roomLogin => '방 서버 로그인';

  @override
  String get login_password => '비밀번호';

  @override
  String get login_enterPassword => '비밀번호를 입력하세요';

  @override
  String get login_savePassword => '비밀번호 저장';

  @override
  String get login_savePasswordSubtitle => '비밀번호는 이 장치에 안전하게 저장됩니다.';

  @override
  String get login_repeaterDescription => '반복기 비밀번호를 입력하여 설정 및 상태를 확인하십시오.';

  @override
  String get login_roomDescription => '설정 및 상태에 액세스하려면 방 비밀번호를 입력하세요.';

  @override
  String get login_routing => '라우팅';

  @override
  String get login_routingMode => '라우팅 모드';

  @override
  String get login_autoUseSavedPath => '자동 (저장된 경로 사용)';

  @override
  String get login_forceFloodMode => '강수 모드 활성화';

  @override
  String get login_managePaths => '경로 관리';

  @override
  String get login_login => '로그인';

  @override
  String login_attempt(int current, int max) {
    return '시도 $current/$max';
  }

  @override
  String login_failed(String error) {
    return '로그인 실패: $error';
  }

  @override
  String get login_failedMessage =>
      '로그인에 실패했습니다. 비밀번호가 잘못되었거나, 연결이 되지 않는 것 같습니다.';

  @override
  String get common_reload => '다시 불러오기';

  @override
  String get common_clear => '지우기';

  @override
  String get path_currentPathLabel => '현재 경로';

  @override
  String get path_noRepeatersFound => '반복 장치 또는 서버는 찾을 수 없습니다.';

  @override
  String get repeater_management => '리피터 관리';

  @override
  String get room_management => '방 서버 관리';

  @override
  String get repeater_guest => '반복 장비 정보';

  @override
  String get room_guest => '서버 정보';

  @override
  String get repeater_managementTools => '관리 도구';

  @override
  String get repeater_guestTools => '손님용 도구';

  @override
  String get repeater_status => '상태';

  @override
  String get repeater_statusSubtitle => '반복 장비의 상태, 통계, 및 이웃 장비 목록 보기';

  @override
  String get repeater_telemetry => '텔레메트리';

  @override
  String get repeater_telemetrySubtitle => '센서 및 시스템 상태에 대한 통신 데이터를 확인';

  @override
  String get repeater_cli => '명령줄 인터페이스 (CLI)';

  @override
  String get repeater_cliSubtitle => '리피터에 명령을 전송';

  @override
  String get repeater_neighbors => '이웃';

  @override
  String get repeater_neighborsSubtitle => '0홉 이웃 노드를 확인합니다.';

  @override
  String get repeater_settings => '설정';

  @override
  String get repeater_settingsSubtitle => '리피터 파라미터 설정';

  @override
  String get repeater_clockSyncAfterLogin => '로그인 후 시계 동기화';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      '성공적인 로그인 후, 자동으로 \"시간 동기화\"를 전송합니다.';

  @override
  String get repeater_statusTitle => '반복 장치 상태';

  @override
  String get repeater_routingMode => '라우팅 방식';

  @override
  String get repeater_refresh => '새롭게';

  @override
  String get repeater_statusRequestTimeout => '상태 확인 요청이 시간 초과되었습니다.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return '상태 로딩 오류: $error';
  }

  @override
  String get repeater_systemInformation => '시스템 정보';

  @override
  String get repeater_battery => '배터리';

  @override
  String get repeater_clockAtLogin => '로그인 시 시간 표시';

  @override
  String get repeater_uptime => '가동 시간';

  @override
  String get repeater_queueLength => '대기 줄의 길이';

  @override
  String get repeater_debugFlags => '디버깅 플래그';

  @override
  String get repeater_radioStatistics => '라디오 통계';

  @override
  String get repeater_lastRssi => '마지막 RSSI 값';

  @override
  String get repeater_lastSnr => '마지막 SNR';

  @override
  String get repeater_noiseFloor => '잡음 수준';

  @override
  String get repeater_txAirtime => 'TX 에어타임';

  @override
  String get repeater_rxAirtime => 'RX 에어타임';

  @override
  String get repeater_chanUtil => '채널 활용도';

  @override
  String get repeater_packetStatistics => '패킷 통계';

  @override
  String get repeater_sent => '발송';

  @override
  String get repeater_received => '수신';

  @override
  String get repeater_duplicates => '중복';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days일 $hours시간 $minutes분 $seconds초';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return '총: $total, 홍수: $flood, 직접: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '총: $total, 홍수: $flood, 직접: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return '홍수: $flood, 직접: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return '총: $total';
  }

  @override
  String get repeater_settingsTitle => '리피터 설정';

  @override
  String get repeater_basicSettings => '기본 설정';

  @override
  String get repeater_repeaterName => '반복 장비 이름';

  @override
  String get repeater_repeaterNameHelper => '이 반복기용 표시 이름';

  @override
  String get repeater_adminPassword => '관리자 비밀번호';

  @override
  String get repeater_adminPasswordHelper => '전체 접근 권한 비밀번호';

  @override
  String get repeater_guestPassword => '게스트 비밀번호';

  @override
  String get repeater_guestPasswordHelper => '읽기 전용 접근 비밀번호';

  @override
  String get repeater_radioSettings => '라디오 설정';

  @override
  String get repeater_frequencyMhz => '주파수 (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX 파워';

  @override
  String get repeater_txPowerHelper => '1~30 dBm';

  @override
  String get repeater_bandwidth => '대역폭';

  @override
  String get repeater_spreadingFactor => '분산 계수';

  @override
  String get repeater_codingRate => '코딩 속도';

  @override
  String get repeater_locationSettings => '위치 설정';

  @override
  String get repeater_latitude => '위도';

  @override
  String get repeater_latitudeHelper => '십진법 위도 (예: 37.7749)';

  @override
  String get repeater_longitude => '경도';

  @override
  String get repeater_longitudeHelper => '십진법 위도 (예: -122.4194)';

  @override
  String get repeater_features => '특징';

  @override
  String get repeater_packetForwarding => '패킷 전송';

  @override
  String get repeater_packetForwardingSubtitle => '리피터가 패킷을 전달하도록 설정';

  @override
  String get repeater_guestAccess => '게스트 접근';

  @override
  String get repeater_guestAccessSubtitle => '게스트의 읽기 전용 접근 권한 허용';

  @override
  String get repeater_privacyMode => '개인 정보 보호 모드';

  @override
  String get repeater_privacyModeSubtitle => '광고에 이름/위치 정보 숨기기';

  @override
  String get repeater_advertisementSettings => '광고 설정';

  @override
  String get repeater_localAdvertInterval => '지역 광고 시간 간격';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes 분';
  }

  @override
  String get repeater_floodAdvertInterval => '홍수 광고 간격';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 시간';
  }

  @override
  String get repeater_encryptedAdvertInterval => '암호화된 광고 간격';

  @override
  String get repeater_dangerZone => '위험 구역';

  @override
  String get repeater_rebootRepeater => '리부트 반복';

  @override
  String get repeater_rebootRepeaterSubtitle => '리피터 장치를 재시작하세요.';

  @override
  String get repeater_rebootRepeaterConfirm => '반복기를 재부팅하시려는 것이 맞으신가요?';

  @override
  String get repeater_regenerateIdentityKey => '아이디 키 재 생성';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '새로운 공개/개인 키 쌍 생성';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      '이를 통해 리피터에 새로운 식별자를 할당합니다. 계속 진행하시겠습니까?';

  @override
  String get repeater_eraseFileSystem => '파일 시스템 삭제';

  @override
  String get repeater_eraseFileSystemSubtitle => '리피터 파일 시스템을 포맷합니다.';

  @override
  String get repeater_eraseFileSystemConfirm =>
      '경고: 이 작업은 리피터에 있는 모든 데이터를 삭제합니다. 이 작업을 되돌릴 수 없습니다!';

  @override
  String get repeater_eraseSerialOnly =>
      '\'Erase\' 기능은 시리얼 콘솔을 통해서만 사용할 수 있습니다.';

  @override
  String repeater_commandSent(String command) {
    return '명령 전송: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return '명령 전송 오류: $error';
  }

  @override
  String get repeater_confirm => '확인';

  @override
  String get repeater_settingsSaved => '설정이 성공적으로 저장되었습니다.';

  @override
  String get repeater_rxGain => '향상된 RX 성능';

  @override
  String get repeater_rxGainHelper =>
      '더 높은 감도, 더 많은 전류 소모 (SX1262/SX1268에만 해당)';

  @override
  String get repeater_refreshRxGain => 'RX 성능 향상 효과 재확인';

  @override
  String get repeater_multiAcks => '다중 ACK';

  @override
  String get repeater_multiAcksSubtitle => '다양한 경로를 통해 메시지를 확인하여 전달 효율성을 높입니다.';

  @override
  String get repeater_refreshMultiAcks => '다중 ACK 재확인';

  @override
  String get repeater_networkHealth => '네트워크 상태';

  @override
  String get repeater_loopDetect => '루프 감지';

  @override
  String get repeater_loopDetectHelper => '라우팅 루프처럼 보이는 과도한 데이터 패킷을 전송';

  @override
  String get repeater_loopDetectOff => '거기';

  @override
  String get repeater_loopDetectMinimal => '최소';

  @override
  String get repeater_loopDetectModerate => '적당한';

  @override
  String get repeater_loopDetectStrict => '엄격한';

  @override
  String get repeater_dutyCycle => '작동 주기';

  @override
  String get repeater_dutyCycleHelper => '허용되는 최대 방송 시간 비율';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => '운영자 정보';

  @override
  String get repeater_ownerInfoHelper => '이 리피터에 대한 공개 메타데이터';

  @override
  String get repeater_refreshOwnerInfo => '운영자 정보 업데이트';

  @override
  String get repeater_floodMax => '최대 홉 수';

  @override
  String get repeater_floodMaxHelper => '최대 패킷이 이동할 수 있는 홉 수 (0-64)';

  @override
  String get repeater_advancedSettings => '고급';

  @override
  String get repeater_advancedSettingsSubtitle => '숙련된 운영자를 위한 조절 노브';

  @override
  String get repeater_pathHashMode => '패스 해시 모드';

  @override
  String get repeater_pathHashModeHelper =>
      '이 리피터의 ID를 플러드 경로/루프 감지 태그에 인코딩하는 데 사용되는 바이트 수입니다. 0=1바이트(256개 ID, 최대 64홉), 1=2바이트(65,000개 ID, 최대 32홉), 2=3바이트(1,600만 개 ID, 최대 21홉). v1.14 이전 펌웨어는 항상 1바이트 경로를 사용했으며, v1.14 이상은 2바이트 또는 3바이트 경로로 설정할 수 있습니다.';

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
  String get repeater_txDelay => '플러드 TX 지연';

  @override
  String get repeater_txDelayHelper =>
      '홍수 시 교통량에 맞춰 재전송 간격을 설정합니다. 이는 패킷의 전송 시간을 곱한 값 (0-2, 기본값 0.5)으로 설정합니다. 값이 클수록 충돌이 줄어들지만 전송 속도가 느려집니다.';

  @override
  String get repeater_directTxDelay => '직접적인 TX 지연';

  @override
  String get repeater_directTxDelayHelper =>
      '직접 (대량 전송이 아닌) 트래픽에 대한 재전송 간격을, 패킷의 전송 시간을 곱하여 설정 (0-2, 기본값 0.3).';

  @override
  String get repeater_intThresh => '간섭 허용치';

  @override
  String get repeater_intThreshHelper =>
      '신호의 잡음 수준을 기준으로 작동하며, 이 수준 이상의 간섭은 차단합니다. 0은 비활성화 상태를 의미하며, 잡음이 심한 대역에서 RX 오류가 발생할 경우에만 활성화해야 합니다.';

  @override
  String get repeater_agcResetInterval => 'AGC 재설정 간격';

  @override
  String get repeater_agcResetIntervalHelper =>
      '자동 게인 제어를 재설정하여 신호가 불안정해졌을 때 원래 상태로 복구하는 빈도를 설정하는 방법은 다음과 같습니다. 4의 배수 단위로 설정하면 주기적인 재설정이 수행됩니다. 0을 설정하면 주기적인 재설정이 수행되지 않습니다.';

  @override
  String get repeater_actionsTitle => '행동';

  @override
  String get repeater_sendAdvert => '홍수 관련 광고 전송';

  @override
  String get repeater_sendAdvertSubtitle => '네트워크를 통해 홍수 광고를 방송';

  @override
  String get repeater_sendAdvertZeroHop => '제로 홉 광고 전송';

  @override
  String get repeater_sendAdvertZeroHopSubtitle => '단일 중계 (중계 없이) 광고를 송출';

  @override
  String get repeater_clockSync => '현재 시계 동기화';

  @override
  String get repeater_clockSyncSubtitle => '스마트폰의 시간을 리피터로 설정';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action이 성공적으로 완료되었습니다.';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action 실패: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      '설정이 저장되었습니다. 다시 시작하여 설정을 적용하세요.';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return '다음 설정에 실패했습니다: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return '설정 저장 오류: $error';
  }

  @override
  String get repeater_refreshBasicSettings => '기본 설정 초기화';

  @override
  String get repeater_refreshRadioSettings => '라디오 설정 초기화';

  @override
  String get repeater_refreshTxPower => 'TX 전원 재설정';

  @override
  String get repeater_refreshPacketForwarding => '패킷 전송 재시작';

  @override
  String get repeater_refreshGuestAccess => '게스트 접근 권한 갱신';

  @override
  String get repeater_refreshPrivacyMode => '개인 정보 보호 모드 재설정';

  @override
  String repeater_refreshed(String label) {
    return '$label가 갱신됨';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '$label를 새로 고침 중 오류 발생';
  }

  @override
  String get repeater_cliTitle => '리피터 CLI';

  @override
  String get repeater_debugNextCommand => '다음 명령 디버깅';

  @override
  String get repeater_commandHelp => '명령 도움';

  @override
  String get repeater_clearHistory => '명확한 역사';

  @override
  String get repeater_noCommandsSent => '아직 명령이 전송되지 않았습니다.';

  @override
  String get repeater_typeCommandOrUseQuick => '아래에 명령어를 입력하거나, 빠른 명령어를 사용하세요.';

  @override
  String get repeater_enterCommandHint => '명령어를 입력하세요...';

  @override
  String get repeater_previousCommand => '이전 명령어';

  @override
  String get repeater_nextCommand => '다음 명령어';

  @override
  String get repeater_enterCommandFirst => '먼저 명령어를 입력하세요';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI 명령어 프레임';

  @override
  String repeater_cliCommandError(String error) {
    return '오류: $error';
  }

  @override
  String get repeater_cliQuickGetName => '이름을 알려주세요';

  @override
  String get repeater_cliQuickGetRadio => '라디오 듣기';

  @override
  String get repeater_cliQuickGetTx => 'TX 획득';

  @override
  String get repeater_cliQuickNeighbors => '이웃';

  @override
  String get repeater_cliQuickVersion => '버전';

  @override
  String get repeater_cliQuickAdvertise => '광고';

  @override
  String get repeater_cliQuickClock => '시계';

  @override
  String get repeater_cliQuickClockSync => '시계 동기화';

  @override
  String get repeater_cliQuickDiscovery => '이웃 발견하기';

  @override
  String get repeater_cliHelpAdvert => '광고 패킷을 발송';

  @override
  String get repeater_cliHelpReboot =>
      '장치를 재부팅합니다. (참고: \'시간 초과\' 오류가 발생할 수 있으며, 이는 정상적인 현상입니다)';

  @override
  String get repeater_cliHelpClock => '각 기기의 시계에 표시되는 현재 시간';

  @override
  String get repeater_cliHelpPassword => '장치에 새로운 관리자 비밀번호를 설정합니다.';

  @override
  String get repeater_cliHelpVersion => '장치 버전 및 펌웨어 빌드 날짜를 표시합니다.';

  @override
  String get repeater_cliHelpClearStats => '다양한 통계 지표를 0으로 초기화합니다.';

  @override
  String get repeater_cliHelpSetAf => '에어 타임 요소를 설정합니다.';

  @override
  String get repeater_cliHelpSetTx =>
      'LoRa 전송 전력을 dBm 단위로 설정합니다. (설정을 적용하려면 재부팅 필요)';

  @override
  String get repeater_cliHelpSetRepeat => '이 노드에 대한 리피터 역할을 활성화하거나 비활성화합니다.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(방 서버) \'켜짐\' 상태인 경우, 빈 비밀번호로 로그인할 수 있지만, 방에 게시할 수는 없습니다 (단, 읽기만 가능).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      '들어오는 플러드 패킷의 최대 홉 수를 설정합니다 (최대 홉 수보다 크거나 같으면 패킷은 전달되지 않습니다).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      '간섭 임계값을 설정합니다 (dB 단위). 기본값은 14입니다. 0으로 설정하면 채널 간섭 감지 기능을 비활성화합니다.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      '자동 게인 제어기를 재설정하는 간격을 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      '\'더블 ACK\' 기능을 활성화하거나 비활성화할 수 있습니다.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      '로컬 (제로 홉) 광고 패킷을 전송하는 간격 (분 단위)을 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      '시간 단위로 광고 패킷을 전송하는 간격을 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      '게스트 비밀번호를 설정하거나 업데이트합니다. (반복 사용자, 게스트 로그인 시 \"통계 가져오기\" 요청을 보낼 수 있음)';

  @override
  String get repeater_cliHelpSetName => '광고 이름을 설정합니다.';

  @override
  String get repeater_cliHelpSetLat => '광고 지도의 위도를 설정합니다. (십진법 단위)';

  @override
  String get repeater_cliHelpSetLon => '광고 지도의 경도를 설정합니다. (십진도)';

  @override
  String get repeater_cliHelpSetRadio =>
      '완전히 새로운 라디오 파라미터를 설정하고, 선호 사항에 저장합니다. 적용하려면 \"재부팅\" 명령이 필요합니다.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      '(실험용) 기본 설정 (최소 1이어야 함)으로, 수신된 패킷에 약간의 지연을 적용하며, 신호 강도/점수를 기준으로 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      '공통 패킷의 전송 지연 시간을 설정하며, 시간-공기 시간과 무작위 슬롯 시스템을 곱하여 충돌 가능성을 줄입니다.';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'txdelay와 동일하게, 하지만 직접 모드 패킷 전송 시 무작위 지연을 적용하는 경우';

  @override
  String get repeater_cliHelpSetBridgeEnabled => '브리지 활성화/비활성화';

  @override
  String get repeater_cliHelpSetBridgeDelay => '패킷 재전송 전에 지연 시간을 설정합니다.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      '브리지가 수신된 패킷을 다시 전송할지, 아니면 전송된 패킷을 다시 전송할지 선택하십시오.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'rs232 브리지에 대한 직렬 통신 속도(baud rate)를 설정합니다.';

  @override
  String get repeater_cliHelpSetBridgeSecret => 'ESPNow 브리지에 대한 비밀 설정';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      '특정 보드에서만 지원되는 방식으로, 보고되는 배터리 전압을 조정하기 위한 사용자 정의 요소를 설정할 수 있습니다.';

  @override
  String get repeater_cliHelpTempRadio =>
      '주어진 시간(분) 동안 임시 라디오 파라미터를 설정하고, 이후 원래 라디오 파라미터로 되돌립니다. (설정을 저장하지 않습니다).';

  @override
  String get repeater_cliHelpSetPerm =>
      'ACL을 수정합니다. \"permissions\" 값이 0인 경우, 일치하는 항목(pubkey 접두사)을 제거합니다. pubkey-hex 길이가 완전하고 현재 ACL에 없는 경우 새로운 항목을 추가합니다. pubkey 접두사를 기준으로 항목을 업데이트합니다. 권한 비트는 펌웨어 역할에 따라 다르지만, 하위 2비트는 다음과 같습니다: 0 (게스트), 1 (읽기 전용), 2 (읽기/쓰기), 3 (관리자)';

  @override
  String get repeater_cliHelpGetBridgeType => '브리지형, RS232, ESPNOW 지원';

  @override
  String get repeater_cliHelpLogStart => '패킷 로깅을 파일 시스템으로 시작합니다.';

  @override
  String get repeater_cliHelpLogStop => '패킷 로깅을 파일 시스템으로 저장하는 것을 중단합니다.';

  @override
  String get repeater_cliHelpLogErase => '파일 시스템에서 패킷 로그를 삭제합니다.';

  @override
  String get repeater_cliHelpNeighbors =>
      '제로 홉 광고를 통해 수신된 다른 리피터 노드 목록을 보여줍니다. 각 줄은 ID-프리픽스-16진수:타임스탬프:SNR-횟수-4 형식입니다.';

  @override
  String get repeater_cliHelpNeighborRemove =>
      '이 함수는 지정된 pubkey 접두사(16진수)와 일치하는 첫 번째 항목을 이웃 목록에서 제거합니다.';

  @override
  String get repeater_cliHelpRegion =>
      '(단일 시리즈) 정의된 모든 지역과 현재 홍수 허가 정보를 나열합니다.';

  @override
  String get repeater_cliHelpRegionLoad =>
      '참고: 이는 여러 명령을 한 번에 실행하는 특별한 방식입니다. 각 후속 명령은 영역 이름이며 (부모 계층 구조를 나타내기 위해 공백으로 들여쓰기하며, 최소 1개의 공백을 사용) 공백으로 끝나는 줄 또는 명령을 보내어 종료합니다.';

  @override
  String get repeater_cliHelpRegionGet =>
      '주어진 이름 접두사(또는 전역 검색을 위한 \"\\*\" 사용)를 사용하여 특정 지역을 검색합니다. 결과를 \"-> 지역 이름 (상위 지역 이름) \'F\'\" 형태로 반환합니다.';

  @override
  String get repeater_cliHelpRegionPut => '주어진 이름으로 지역 정의를 추가하거나 업데이트합니다.';

  @override
  String get repeater_cliHelpRegionRemove =>
      '지정된 이름으로 특정 영역 정의를 제거합니다. (정확히 일치해야 하며, 하위 영역은 존재하지 않아야 합니다)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      '지정된 영역에 대한 \'물\' 접근 권한을 설정합니다. (\'*\'는 전역/기존 범위에 해당)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      '지정된 영역에 대해 \'Flood\' 권한을 제거합니다. (참고: 현재 단계에서는 전역/기존 범위에서 이 기능을 사용하지 않는 것이 좋습니다!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      '현재 \'홈\' 지역으로 응답합니다. (아직 적용되지 않았으며, 향후 사용을 위해 예약됨)';

  @override
  String get repeater_cliHelpRegionHomeSet => '\'홈\' 지역을 설정합니다.';

  @override
  String get repeater_cliHelpRegionSave => '지역 목록/지도를 저장에 유지합니다.';

  @override
  String get repeater_cliHelpGps =>
      'GPS 상태를 표시합니다. GPS가 꺼져 있으면 \"꺼짐\"이라고 표시하고, 켜져 있으면 \"켜짐\", 상태, 위치 정보, 위성 수 등을 표시합니다.';

  @override
  String get repeater_cliHelpGpsOnOff => 'GPS 전원 상태를 켜고 끄는 기능.';

  @override
  String get repeater_cliHelpGpsSync => '노드 시간을 GPS 시계와 동기화합니다.';

  @override
  String get repeater_cliHelpGpsSetLoc => '노드의 위치를 GPS 좌표로 설정하고, 설정을 저장합니다.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      '노드의 위치 광고 설정:\n- none: 광고에 위치 정보를 포함하지 않음\n- share: GPS 위치 정보를 공유 (SensorManager에서 가져옴)\n- prefs: 설정에 저장된 위치를 광고';

  @override
  String get repeater_cliHelpGpsAdvertSet => '위치 기반 광고 설정 구성';

  @override
  String get repeater_commandsListTitle => '명령 목록';

  @override
  String get repeater_commandsListNote =>
      '참고: 다양한 \"set...\" 명령과 함께 \"get...\" 명령도 존재합니다.';

  @override
  String get repeater_general => '일반';

  @override
  String get repeater_settingsCategory => '설정';

  @override
  String get repeater_bridge => '다리';

  @override
  String get repeater_logging => '로깅';

  @override
  String get repeater_neighborsRepeaterOnly => '이웃 (단방향 통신만 지원)';

  @override
  String get repeater_regionManagementRepeaterOnly => '지역 관리 (단, 중계 기능만 사용)';

  @override
  String get repeater_regionNote =>
      '지역별 관리 기능을 도입하여 지역 정의 및 권한 관리를 수행할 수 있습니다.';

  @override
  String get repeater_gpsManagement => 'GPS 관리';

  @override
  String get repeater_gpsNote => 'GPS 명령이 위치 관련 주제를 관리하기 위해 도입되었습니다.';

  @override
  String get repeater_getCategory => '가치 얻기';

  @override
  String get repeater_powerMgmt => '전력 관리';

  @override
  String get repeater_sensors => '센서';

  @override
  String get repeater_cliHelpPowerOff => '장치를 끄는 기능 (응답이 없을 것으로 예상)';

  @override
  String get repeater_cliHelpClkReboot => '시계를 알려진 시점으로 재설정하고 장치를 재부팅합니다.';

  @override
  String get repeater_cliHelpAdvertZeroHop => '직접적인 연결 없이 이웃에게만 광고를 전송합니다.';

  @override
  String get repeater_cliHelpStartOta => '지원되는 보드에서 무선으로 펌웨어 업데이트를 시작합니다.';

  @override
  String get repeater_cliHelpTime =>
      '장치를 주어진 유닉스 에포크 초부터 시간으로 설정합니다. 시간은 이전으로 이동할 수 없습니다.';

  @override
  String get repeater_cliHelpBoard => '제조사/하드웨어 식별 정보를 표시합니다.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      '인접한 노드에 대한 탐색 요청을 보냅니다. (리피터만 해당)';

  @override
  String get repeater_cliHelpPowersaving => '절전 모드가 켜져 있는지 확인하는 표시';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      '절전 모드를 활성화하거나 비활성화할 수 있습니다 (지원되는 경우).';

  @override
  String get repeater_cliHelpErase =>
      '(단일 사용) 장치 파일 시스템을 포맷합니다. 모든 설정 및 연락처를 삭제합니다.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      '최대 허용 전송 주기(백분율)를 설정합니다(1~100%). 내부적으로 통신 시간을 조정합니다.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(시리얼 키만 해당) 장치 식별용 개인 키를 대체합니다. 적용하려면 재부팅이 필요합니다. 새로운 공개 키를 생성합니다.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(SX126x 전용) 더 높은 전류를 사용할 때 더 나은 감도를 위해 증폭된 RX 감쇠 기능을 전환합니다.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      '광고에 포함된 소유자 연락처 정보를 지정합니다. 줄 바꿈을 위해 \'|\' 문자를 사용합니다.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      '경로 해시 모드를 설정합니다. 0 = 고전 방식, 1 = 표준 방식, 2 = 엄격한 방식. 경로 매칭 방식에 영향을 미칩니다.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      '라우팅 루프 감지 감도 설정: 끄기, 최소, 중간, 또는 엄격';

  @override
  String get repeater_cliHelpSetFreq =>
      '(단일 기능) 특정 주파수만 빠르게 설정합니다. 재부팅이 필요합니다. 전체 라디오 파라미터 설정에는 \"라디오 설정\" 기능을 사용하는 것이 좋습니다.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(ESPNow 브리지만 해당) 브리지에서 사용되는 WiFi 채널(1~14)을 설정합니다.';

  @override
  String get repeater_cliHelpGetName => '구성된 노드의 이름을 표시합니다.';

  @override
  String get repeater_cliHelpGetRole => '펌웨어 역할(리피터, 룸 서버 등)을 보여줍니다.';

  @override
  String get repeater_cliHelpGetPublicKey => '장치의 공개 키를 표시합니다.';

  @override
  String get repeater_cliHelpGetPrvKey => '(전용) 장치의 개인 키를 표시합니다. 비밀 정보로 취급합니다.';

  @override
  String get repeater_cliHelpGetRepeat => '패킷 전달(리피터 기능)이 활성화되어 있는지 여부를 표시합니다.';

  @override
  String get repeater_cliHelpGetTx => '현재 TX 전력(dBm)을 표시합니다.';

  @override
  String get repeater_cliHelpGetFreq => '구성된 무선 주파수를 MHz 단위로 표시합니다.';

  @override
  String get repeater_cliHelpGetRadio =>
      '전체 무선 파라미터 표시: 주파수, 대역폭, 스프레딩 계수, 인코딩 속도';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(SX126x 전용) RX의 증폭 이득 상태를 표시합니다.';

  @override
  String get repeater_cliHelpGetAf => '현재 공기 시간 요소를 보여줍니다.';

  @override
  String get repeater_cliHelpGetDutyCycle => '현재 허용되는 작업 주기를 백분율로 표시합니다.';

  @override
  String get repeater_cliHelpGetIntThresh => '채널 간섭 임계값을 dB 단위로 표시합니다.';

  @override
  String get repeater_cliHelpGetAgcResetInterval => 'AGC 재설정 간격을 초 단위로 표시합니다.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      '더블 ACK 모드가 활성화되어 있는지 (1) 또는 비활성화되어 있는지 (0)를 표시합니다.';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      '게스트의 읽기 전용 액세스가 허용되는지 여부를 표시합니다.';

  @override
  String get repeater_cliHelpGetAdvertInterval => '지역 광고 시간 간격을 분 단위로 표시합니다.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      '홍수 광고 시간 간격을 시간 단위로 표시합니다.';

  @override
  String get repeater_cliHelpGetGuestPassword => '구성된 게스트 비밀번호를 표시합니다.';

  @override
  String get repeater_cliHelpGetLat => '설정된 위도를 보여줍니다.';

  @override
  String get repeater_cliHelpGetLon => '설정된 경도를 보여줍니다.';

  @override
  String get repeater_cliHelpGetRxDelay => 'Rxdelay 기본 값을 표시합니다.';

  @override
  String get repeater_cliHelpGetTxDelay => '홍수 모드에서의 전송 지연 계수를 보여줍니다.';

  @override
  String get repeater_cliHelpGetDirectTxDelay => '직렬 모드에서의 딜레이 계수를 보여줍니다.';

  @override
  String get repeater_cliHelpGetFloodMax => '최대 홍수 발생 횟수를 보여줍니다.';

  @override
  String get repeater_cliHelpGetOwnerInfo => '소유주 연락처 정보를 표시합니다.';

  @override
  String get repeater_cliHelpGetPathHashMode => '경로 해시 모드 (0/1/2)를 표시합니다.';

  @override
  String get repeater_cliHelpGetLoopDetect => '루프 탐지 감도를 보여줍니다.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(단순히 목록만 표시) 리피터에 설정된 접근 제어 항목 목록을 보여줍니다.';

  @override
  String get repeater_cliHelpGetBridgeEnabled => '다리 기능이 활성화되어 있는지 여부를 표시합니다.';

  @override
  String get repeater_cliHelpGetBridgeDelay => '다리 통과 시간(밀리초)을 표시합니다.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      '브리지 로그가 RX 또는 TX 패킷을 기록하는지 여부를 보여줍니다.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(RS232 브리지 기능만) 브리지의 보드 속도를 표시합니다.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(ESPNow 브리지만 해당) 브리지의 Wi-Fi 채널을 표시합니다.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(ESPNow 브리지만 해당) 브리지에서 공유된 비밀을 표시합니다.';

  @override
  String get repeater_cliHelpGetBootloaderVer => '(NRF52만 해당) 부팅 로더 버전을 표시합니다.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      '배터리 전압을 스케일링하는 ADC 멀티플라이어를 보여줍니다.';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      '이 보드가 전력 관리 기능을 지원하는지 여부를 나타냅니다.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      '현재 전원 공급 장치 (외부 전원 또는 배터리)를 표시합니다.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason => '가장 최근 재설정 및 종료 이유를 보여줍니다.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv => '부팅 시 배터리 전압을 mV 단위로 표시합니다.';

  @override
  String get repeater_cliHelpSensorGet => '키를 사용하여 사용자 정의 센서 설정을 읽습니다.';

  @override
  String get repeater_cliHelpSensorSet => '사용자 정의 센서 설정을 작성합니다.';

  @override
  String get repeater_cliHelpSensorList =>
      '사용자 정의 센서 설정 목록을, 선택적으로 지정된 시작 인덱스부터 페이지 나누어 표시합니다.';

  @override
  String get repeater_cliHelpRegionDefault => '현재 기본 지역 범위를 보여줍니다.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      '기본 지역 범위를 설정합니다. \"<null>\"을 사용하여 초기화합니다.';

  @override
  String get repeater_cliHelpRegionListAllowed => '홍수 피해 차량 통행이 가능한 지역 목록';

  @override
  String get repeater_cliHelpRegionListDenied => '홍수 발생 시 통행 금지 지역 목록';

  @override
  String get repeater_cliHelpStatsPackets => '(전송 속도만 표시) 패킷 수준의 통계 정보를 보여줍니다.';

  @override
  String get repeater_cliHelpStatsRadio => '(특정 시리즈만 해당) 라디오 통계 정보를 표시합니다.';

  @override
  String get repeater_cliHelpStatsCore => '(시리얼 번호만 표시) 핵심 펌웨어 통계 정보를 보여줍니다.';

  @override
  String get telemetry_receivedData => '수신된 통신 데이터';

  @override
  String get telemetry_requestTimeout => '원격 모니터링 요청이 시간 초과되었습니다.';

  @override
  String telemetry_errorLoading(String error) {
    return '$error 오류로 인해 통신 데이터를 로드하지 못했습니다.';
  }

  @override
  String get telemetry_noData => '텔레메트리 데이터는 제공되지 않습니다.';

  @override
  String telemetry_channelTitle(int channel) {
    return '채널 $channel';
  }

  @override
  String get telemetry_batteryLabel => '배터리';

  @override
  String get telemetry_voltageLabel => '전압';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU의 온도';

  @override
  String get telemetry_temperatureLabel => '온도';

  @override
  String get telemetry_currentLabel => '현재';

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
  String get telemetry_digitalInputLabel => '디지털 입력';

  @override
  String get telemetry_digitalOutputLabel => '디지털 출력';

  @override
  String get telemetry_analogInputLabel => '아날로그 입력';

  @override
  String get telemetry_analogOutputLabel => '아날로그 출력';

  @override
  String get telemetry_genericLabel => '일반 센서';

  @override
  String get telemetry_luminosityLabel => '조도';

  @override
  String get telemetry_presenceLabel => '존재 감지';

  @override
  String get telemetry_humidityLabel => '습도';

  @override
  String get telemetry_accelerometerLabel => '가속도계';

  @override
  String get telemetry_pressureLabel => '압력';

  @override
  String get telemetry_altitudeLabel => '고도';

  @override
  String get telemetry_frequencyLabel => '주파수';

  @override
  String get telemetry_percentageLabel => '백분율';

  @override
  String get telemetry_concentrationLabel => '농도';

  @override
  String get telemetry_powerLabel => '전력';

  @override
  String get telemetry_distanceLabel => '거리';

  @override
  String get telemetry_energyLabel => '에너지';

  @override
  String get telemetry_directionLabel => '방향';

  @override
  String get telemetry_timeLabel => '시간';

  @override
  String get telemetry_gyrometerLabel => '자이로미터';

  @override
  String get telemetry_colourLabel => '색상';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => '스위치';

  @override
  String get telemetry_polylineLabel => '폴리라인';

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
  String get telemetry_autoFetchQuantity => '요청 수';

  @override
  String get telemetry_error => '데이터를 가져올 수 없습니다';

  @override
  String get neighbors_receivedData => '이웃 정보 수집';

  @override
  String get neighbors_requestTimedOut => '이웃들이 시간 제한을 요청하고 있습니다.';

  @override
  String neighbors_errorLoading(String error) {
    return '이웃 정보 로딩 중 오류: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => '반복기, 이웃';

  @override
  String get neighbors_noData => '이웃 정보는 없습니다.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '알 수 없는 $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return '수신: $time 전';
  }

  @override
  String get channelPath_title => '패킷 경로';

  @override
  String get channelPath_viewMap => '지도 보기';

  @override
  String get channelPath_otherObservedPaths => '관찰된 다른 경로';

  @override
  String get channelPath_repeaterHops => '반복 홉';

  @override
  String get channelPath_noHopDetails => '이 패키지에 대한 자세한 정보는 제공되지 않습니다.';

  @override
  String get channelPath_messageDetails => '메시지 세부 정보';

  @override
  String get channelPath_senderLabel => '발신자';

  @override
  String get channelPath_timeLabel => '시간';

  @override
  String get channelPath_repeatsLabel => '반복';

  @override
  String channelPath_pathLabel(int index) {
    return '경로 $index';
  }

  @override
  String get channelPath_observedLabel => '관찰';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return '관찰된 경로 $index • $hops';
  }

  @override
  String get channelPath_noLocationData => '위치 정보 없음';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => '알 수 없음';

  @override
  String get channelPath_floodPath => '홍수';

  @override
  String get channelPath_directPath => '직접';

  @override
  String channelPath_observedZeroOf(int total) {
    return '$total 중 0개';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed/$total 홉 관찰됨';
  }

  @override
  String get channelPath_mapTitle => '경로 지도';

  @override
  String get channelPath_noRepeaterLocations => '이 경로에 대한 중계기 설치 위치는 없습니다.';

  @override
  String channelPath_primaryPath(int index) {
    return '경로 $index (주 경로)';
  }

  @override
  String get channelPath_pathLabelTitle => '경로';

  @override
  String get channelPath_observedPathHeader => '관찰된 경로';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable => '이 패킷에 대한 이동 정보는 제공되지 않습니다.';

  @override
  String get channelPath_unknownRepeater => '알 수 없는 중계기';

  @override
  String get community_title => '지역 사회';

  @override
  String get community_create => '커뮤니티 만들기';

  @override
  String get community_createDesc => '새로운 커뮤니티를 만들고 QR 코드를 통해 공유하세요.';

  @override
  String get community_join => '참여하기';

  @override
  String get community_joinTitle => '커뮤니티에 참여하기';

  @override
  String community_joinConfirmation(String name) {
    return '$name님, 커뮤니티에 참여하고 싶으신가요?';
  }

  @override
  String get community_scanQr => '커뮤니티 QR 스캔';

  @override
  String get community_scanInstructions => '카메라를 커뮤니티 QR 코드 방향으로 향하게 하세요.';

  @override
  String get community_showQr => 'QR 코드 표시';

  @override
  String get community_publicChannel => '지역 사회 대상';

  @override
  String get community_hashtagChannel => '커뮤니티 해시태그';

  @override
  String get community_name => '지역 이름';

  @override
  String get community_enterName => '커뮤니티 이름을 입력하세요';

  @override
  String community_created(String name) {
    return '커뮤니티 \"$name\"이 생성되었습니다.';
  }

  @override
  String community_joined(String name) {
    return '\"$name\" 커뮤니티에 가입';
  }

  @override
  String get community_qrTitle => '커뮤니티 공유';

  @override
  String community_qrInstructions(String name) {
    return '이 QR 코드를 스캔하여 \"$name\"에 가입하세요.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      '커뮤니티 해시태그 채널은 커뮤니티 구성원만 가입할 수 있습니다.';

  @override
  String get community_invalidQrCode => '유효하지 않은 커뮤니티 QR 코드';

  @override
  String get community_alreadyMember => '이미 회원인 경우';

  @override
  String community_alreadyMemberMessage(String name) {
    return '이미 $name의 회원입니다.';
  }

  @override
  String get community_addPublicChannel => '커뮤니티 공개 채널 추가';

  @override
  String get community_addPublicChannelHint => '이 커뮤니티에 공개 채널을 자동으로 추가합니다.';

  @override
  String get community_noCommunities => '아직 어느 커뮤니티도 가입하지 않았습니다.';

  @override
  String get community_scanOrCreate => 'QR 코드를 스캔하거나 커뮤니티를 만들어 시작하세요.';

  @override
  String get community_manageCommunities => '커뮤니티 관리';

  @override
  String get community_delete => '커뮤니티 떠나기';

  @override
  String community_deleteConfirm(String name) {
    return '$name을 묻어두나요?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return '또한, 이 기능은 $count개의 채널과 그에 해당하는 메시지를 삭제합니다.';
  }

  @override
  String community_deleted(String name) {
    return '지역 커뮤니티 \"$name\"';
  }

  @override
  String get community_regenerateSecret => '비밀 복원';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '$name의 비밀 키를 재생성하시겠습니까? 모든 회원은 계속 통신을 위해 새로운 QR 코드를 스캔해야 합니다.';
  }

  @override
  String get community_regenerate => '재생';

  @override
  String community_secretRegenerated(String name) {
    return '$name을 위한 비밀 정보가 복원되었습니다.';
  }

  @override
  String get community_updateSecret => '비밀 업데이트';

  @override
  String community_secretUpdated(String name) {
    return '$name을 위한 비밀 정보 업데이트';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '새로운 QR 코드를 스캔하여 $name의 비밀번호를 업데이트하세요.';
  }

  @override
  String get community_addHashtagChannel => '커뮤니티 해시태그 추가';

  @override
  String get community_addHashtagChannelDesc => '이 커뮤니티를 위한 해시태그 채널을 추가하세요.';

  @override
  String get community_selectCommunity => '커뮤니티 선택';

  @override
  String get community_regularHashtag => '일반 해시태그';

  @override
  String get community_regularHashtagDesc => '공개 해시태그 (누구나 참여 가능)';

  @override
  String get community_communityHashtag => '커뮤니티 해시태그';

  @override
  String get community_communityHashtagDesc => '지역 주민을 위한';

  @override
  String community_forCommunity(String name) {
    return '$name 님께';
  }

  @override
  String get listFilter_tooltip => '필터링 및 정렬';

  @override
  String get listFilter_sortBy => '정렬 기준 선택';

  @override
  String get listFilter_latestMessages => '최신 메시지';

  @override
  String get listFilter_heardRecently => '최근에 들었습니다';

  @override
  String get listFilter_az => 'A부터 Z까지';

  @override
  String get listFilter_filters => '필터';

  @override
  String get listFilter_all => '모든';

  @override
  String get listFilter_favorites => '관심 목록';

  @override
  String get listFilter_addToFavorites => '즐겨찾으로 추가';

  @override
  String get listFilter_removeFromFavorites => '즐겨찾에서 제거';

  @override
  String get listFilter_users => '사용자';

  @override
  String get listFilter_repeaters => '다시 보내는 장치';

  @override
  String get listFilter_roomServers => '방 내 서버';

  @override
  String get listFilter_unreadOnly => '읽지 않은 항목만';

  @override
  String get listFilter_newGroup => '새로운 그룹';

  @override
  String get pathTrace_you => '당신';

  @override
  String get pathTrace_failed => '경로 추적 실패.';

  @override
  String get pathTrace_notAvailable => '경로 추적 기능은 제공되지 않습니다.';

  @override
  String get pathTrace_refreshTooltip => '경로 추적 재시작';

  @override
  String get pathTrace_someHopsNoLocation => '홉 중 하나 또는 여러 개에 위치 정보가 누락되었습니다!';

  @override
  String get pathTrace_clearTooltip => '명확한 경로.';

  @override
  String get losSelectStartEnd => 'LOS(최소 거리 경로)의 시작 및 종료 노드를 선택합니다.';

  @override
  String losRunFailed(String error) {
    return '시야 확인 실패: $error';
  }

  @override
  String get losClearAllPoints => '모든 사항을 명확히 합니다.';

  @override
  String get losRunToViewElevationProfile =>
      'LOS(Line of Sight)를 사용하여 고도 프로필을 확인합니다.';

  @override
  String get losMenuTitle => 'LOS 메뉴';

  @override
  String get losMenuSubtitle => '사용자 지정 지점을 추가하려면, 노드를 탭하거나 맵을 길게 눌러 주세요.';

  @override
  String get losShowDisplayNodes => '노드 표시';

  @override
  String get losCustomPoints => '사용자 지정 포인트';

  @override
  String losCustomPointLabel(int index) {
    return '맞춤형 $index';
  }

  @override
  String get losPointA => 'A 지점';

  @override
  String get losPointB => '점 B';

  @override
  String losAntennaA(String value, String unit) {
    return '안테나 A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return '안테나 B: $value $unit';
  }

  @override
  String get losRun => 'LOS (Loss of Signal) 상태로 전환';

  @override
  String get losNoElevationData => '고도 정보 없음';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, LOS 확보, 최소 여유 $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, $obstruction $heightUnit에 의해 차단됨';
  }

  @override
  String get losStatusChecking => 'LOS: 확인 중...';

  @override
  String get losStatusNoData => 'LOS: 데이터 없음';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total 개, $blocked 개, $unknown 개';
  }

  @override
  String get losErrorElevationUnavailable => '샘플 중 하나 이상에 대한 고도 데이터가 없습니다.';

  @override
  String get losErrorInvalidInput => 'LOS 계산에 사용되는 부정확한 지점/고도 데이터.';

  @override
  String get losRenameCustomPoint => '사용자 지정된 지점의 이름을 변경';

  @override
  String get losPointName => '항목 이름';

  @override
  String get losShowPanelTooltip => 'LOS 패널 표시';

  @override
  String get losHidePanelTooltip => 'LOS 패널 숨기기';

  @override
  String get losElevationAttribution => '고도 데이터: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => '라디오 호라이즌';

  @override
  String get losLegendLosBeam => 'LOS 빔';

  @override
  String get losLegendTerrain => '지형';

  @override
  String get losBlockedSpotsTitle => '차단된 공간';

  @override
  String get losBlockedSpotsHint => '지도에서 특정 위치를 강조하려면 해당 위치를 클릭하세요.';

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
  String get losSelectedObstructionTitle => '선택된 장애물';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return '$obstruction $heightUnit에 의해 차단됨, A에서 $distanceFromA, B에서 $distanceFromB ($distanceUnit)';
  }

  @override
  String get losFrequencyLabel => '빈도';

  @override
  String get losFrequencyInfoTooltip => '계산 내역 보기';

  @override
  String get losFrequencyDialogTitle => '라디오 수신 가능 범위 계산';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return '$baselineK에서 시작하여 $baselineFreq MHz의 주파수에서 계산을 시작하면, 현재 $frequencyMHz MHz 대역에 대한 k-값을 조정하여, 이는 곡선형 라디오 지평선 상한선을 정의합니다.';
  }

  @override
  String get contacts_pathTrace => '경로 추적';

  @override
  String get contacts_ping => '핑';

  @override
  String get contacts_repeaterPathTrace => '리피터로 가는 경로';

  @override
  String get contacts_repeaterPing => '핑 반복';

  @override
  String get contacts_roomPathTrace => '방 서버로의 경로 추적';

  @override
  String get contacts_roomPing => '피нг 룸 서버';

  @override
  String get contacts_chatTraceRoute => '경로 추적 경로';

  @override
  String contacts_pathTraceTo(String name) {
    return '$name까지의 경로 추적';
  }

  @override
  String get contacts_clipboardEmpty => '클립보드가 비어 있습니다.';

  @override
  String get contacts_invalidAdvertFormat => '유효하지 않은 연락 정보';

  @override
  String get contacts_contactImported => '연락이 수신되었습니다.';

  @override
  String get contacts_contactImportFailed => '연락처를 가져오지 못했습니다.';

  @override
  String get contacts_zeroHopAdvert => '제로 홉 광고';

  @override
  String get contacts_floodAdvert => '홍수 광고';

  @override
  String get contacts_copyAdvertToClipboard => '광고 텍스트를 클립보드에 복사';

  @override
  String get contacts_addContactFromClipboard => '복사본에서 연락처 추가';

  @override
  String get contacts_ShareContact => '연락처를 복사';

  @override
  String get contacts_ShareContactZeroHop => '광고를 통해 연락처 공유';

  @override
  String get contacts_zeroHopContactAdvertSent => '광고를 통해 연락처를 받았습니다.';

  @override
  String get contacts_zeroHopContactAdvertFailed => '연락처 전송에 실패했습니다.';

  @override
  String get contacts_contactAdvertCopied => '광고 내용이 복사되었습니다.';

  @override
  String get contacts_contactAdvertCopyFailed => '광고를 클립보드에 복사하는 데 실패했습니다.';

  @override
  String get notification_activityTitle => '메쉬코어 활동';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메시지들',
      one: '메시지',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '채널 메시지',
      one: '채널 메시지',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새 노드들',
      one: '새 노드',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return '새로운 $contactType 발견';
  }

  @override
  String get notification_receivedNewMessage => '새로운 메시지를 받았습니다';

  @override
  String get settings_gpxExportRepeaters => 'GPX로 전송/방 관리 서버';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'GPX 파일에 위치 정보를 포함하여 반복자/룸 서버를 내보냅니다.';

  @override
  String get settings_gpxExportContacts => 'GPX 형식으로 내보내기';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'GPX 파일에 위치 정보를 포함하여 동행하는 기능을 내보냅니다.';

  @override
  String get settings_gpxExportAll => '모든 연락처를 GPX 형식으로 내보내기';

  @override
  String get settings_gpxExportAllSubtitle =>
      '위치 정보가 있는 모든 연락처를 GPX 파일로 내보냅니다.';

  @override
  String get settings_gpxExportSuccess => 'GPX 파일이 성공적으로 내보내졌습니다.';

  @override
  String get settings_gpxExportNoContacts => '수출할 연락처가 없습니다.';

  @override
  String get settings_gpxExportNotAvailable => '귀하의 장치/운영체제에서는 지원되지 않습니다.';

  @override
  String get settings_gpxExportError => '데이터 내보내기 과정에서 오류가 발생했습니다.';

  @override
  String get settings_gpxExportRepeatersRoom => '중계 장치 및 서버 위치';

  @override
  String get settings_gpxExportChat => '함께 방문할 장소';

  @override
  String get settings_gpxExportAllContacts => '모든 연락처 위치';

  @override
  String get settings_gpxExportShareText => 'meshcore-open에서 추출한 지도 데이터';

  @override
  String get settings_gpxExportShareSubject => 'meshcore-open GPX 지도 데이터 내보내기';

  @override
  String get snrIndicator_nearByRepeaters => '주변의 중계기';

  @override
  String get snrIndicator_lastSeen => '마지막으로 목격';

  @override
  String get contactsSettings_title => '연락처 설정';

  @override
  String get contactsSettings_autoAddTitle => '자동 검색';

  @override
  String get contactsSettings_otherTitle => '다른 연락 관련 설정';

  @override
  String get contactsSettings_autoAddUsersTitle => '자동으로 사용자 추가';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      '동반자가 자동으로 발견한 사용자를 추가할 수 있도록 합니다.';

  @override
  String get contactsSettings_autoAddRepeatersTitle => '자동으로 중계기 추가';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      '애완동물이 발견한 무선 라디오를 자동으로 추가할 수 있도록 설정합니다.';

  @override
  String get contactsSettings_autoAddRoomServersTitle => '자동으로 방 서버 추가';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      '애완동물이 발견한 방 서버를 자동으로 추가할 수 있도록 설정합니다.';

  @override
  String get contactsSettings_autoAddSensorsTitle => '자동으로 센서 추가';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      '애완동물이 발견한 센서를 자동으로 추가할 수 있도록 설정합니다.';

  @override
  String get contactsSettings_overwriteOldestTitle => '가장 오래된 것을 덮어쓰기';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      '연락처 목록이 가득 차면, 가장 오래된 (선호하지 않은) 연락처가 대체됩니다.';

  @override
  String get contactsSettings_evictDiscoveredContactsTitle =>
      'Evict discovered contacts';

  @override
  String get contactsSettings_evictDiscoveredContactsSubtitle =>
      'When enabled, the app removes the oldest discovered contacts once the discovery list reaches its limit of 500 entries.';

  @override
  String get discoveredContacts_Title => '연락처 찾기';

  @override
  String get discoveredContacts_noMatching => '일치하는 연락처가 없습니다.';

  @override
  String get discoveredContacts_searchHint => '발견된 연락처 검색';

  @override
  String get discoveredContacts_contactAdded => '연락처 추가';

  @override
  String get discoveredContacts_addContact => '연락처 추가';

  @override
  String get discoveredContacts_copyContact => '복사';

  @override
  String get discoveredContacts_deleteContact => '발견된 연락처 삭제';

  @override
  String get discoveredContacts_deleteContactAll => '발견된 모든 연락처 삭제';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      '정말로 모든 검색된 연락처를 삭제하시겠습니까?';

  @override
  String get chat_sendCooldown => '다시 보내기 전에 잠시 기다려 주시기 바랍니다.';

  @override
  String get appSettings_jumpToOldestUnread => '가장 오래된, 아직 읽지 않은 항목으로 이동';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      '새로운 메시지가 없는 채팅을 열 때, 최신 메시지가 아닌 첫 번째 읽지 않은 메시지로 스크롤하세요.';

  @override
  String get appSettings_languageHu => '헝가리';

  @override
  String get appSettings_languageJa => '일본어';

  @override
  String get appSettings_languageKo => '한국어';

  @override
  String get radioStats_tooltip => '라디오 및 메시 통계';

  @override
  String get radioStats_screenTitle => '라디오 통계';

  @override
  String get radioStats_notConnected => '라디오 통계를 확인하기 위해 장치에 연결합니다.';

  @override
  String get radioStats_firmwareTooOld =>
      '무선 통계 기능을 사용하려면 v8 또는 그 이상의 호환 펌웨어가 필요합니다.';

  @override
  String get radioStats_waiting => '데이터를 기다리는 중…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return '잡음 수준: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return '마지막 RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return '마지막 SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX 방송 시간 (총): $seconds 초';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX 사용 시간 (총): $seconds 초';
  }

  @override
  String get radioStats_chartCaption => '최근 샘플의 잡음 수준 (dBm)';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return '잡음 수준: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => '라디오 통계 가져오기…';

  @override
  String get radioStats_settingsTile => '라디오 통계';

  @override
  String get radioStats_settingsSubtitle => '잡음 수준, RSSI, 신호 대 잡음비, 통신 시간';

  @override
  String get translation_title => '번역';

  @override
  String get translation_enableTitle => '번역 기능 활성화';

  @override
  String get translation_enableSubtitle => '입력 메시지를 번역하고, 미리 번역 기능을 제공합니다.';

  @override
  String get translation_composerTitle => '보내기 전에 번역';

  @override
  String get translation_composerSubtitle => '컴포저 번역 아이콘의 기본 상태를 제어합니다.';

  @override
  String get translation_autoIncomingTitle => '메시지 자동 번역';

  @override
  String get translation_autoIncomingSubtitle =>
      '알림과 채팅 또는 채널의 메시지를 자동으로 번역합니다.';

  @override
  String get translation_translateMessage => '메시지 번역';

  @override
  String get translation_targetLanguage => '목표 언어';

  @override
  String get translation_useAppLanguage => '앱 언어 사용';

  @override
  String get translation_downloadedModelLabel => '다운로드한 모델';

  @override
  String get translation_presetModelLabel => '사전에 설정된 Hugging Face 모델';

  @override
  String get translation_manualUrlLabel => '수동 모델 URL';

  @override
  String get translation_downloadModel => '모델 다운로드';

  @override
  String get translation_downloading => '다운로드 중...';

  @override
  String get translation_working => '업무 중...';

  @override
  String get translation_stop => '멈춰';

  @override
  String get translation_mergingChunks => '다운로드한 파일 조각들을 최종 파일로 병합 중...';

  @override
  String get translation_downloadedModels => '다운로드한 모델';

  @override
  String get translation_deleteModel => '모델 삭제';

  @override
  String get translation_modelDownloaded => '번역 모델이 다운로드되었습니다.';

  @override
  String get translation_downloadStopped => '다운로드 중단됨.';

  @override
  String translation_downloadFailed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get translation_enterUrlFirst => '먼저 모델 URL을 입력하세요.';

  @override
  String get scanner_linuxPairingShowPin => 'PIN 보기';

  @override
  String get scanner_linuxPairingHidePin => 'PIN 숨기기';

  @override
  String get scanner_linuxPairingPinTitle => '블루투스 페어링 PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return '$deviceName의 PIN을 입력하세요 (해당하는 경우에만 입력).';
  }

  @override
  String get translation_messageTranslation => '메시지 번역';

  @override
  String get translation_translateBeforeSending => '보내기 전에 번역';

  @override
  String get translation_composerEnabledHint => '메시지는 전송하기 전에 번역될 것입니다.';

  @override
  String get translation_composerDisabledHint => '원래 작성된 언어로 메시지를 보내세요.';

  @override
  String translation_translateTo(String language) {
    return '$language 번역';
  }

  @override
  String get translation_translationOptions => '번역 옵션';

  @override
  String get translation_systemLanguage => '시스템 언어';

  @override
  String get background_serviceTitle => 'MeshCore 실행 중';

  @override
  String get background_serviceText => 'BLE 연결 유지 중';

  @override
  String appSettings_translationModelDeleted(String name) {
    return '$name 삭제됨';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return '채널 업데이트 실패: $error';
  }

  @override
  String get contact_typeChat => '채팅';

  @override
  String get contact_typeRepeater => '리피터';

  @override
  String get contact_typeRoom => '룸';

  @override
  String get contact_typeSensor => '센서';

  @override
  String get contact_typeUnknown => '알 수 없음';

  @override
  String get map_zoomIn => '확대';

  @override
  String get map_zoomOut => '축소';

  @override
  String get map_centerMap => '지도 중앙 맞추기';

  @override
  String get chrome_bluetoothRequiresChromium =>
      '웹 블루투스는 Chromium 기반 브라우저가 필요합니다.';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS로 확인됨';

  @override
  String get pathTrace_legendInferred => '추정된 위치';

  @override
  String get pathMap_viewSingle => '단일';

  @override
  String get pathMap_viewCombined => '결합';

  @override
  String get pathMap_play => '재생';

  @override
  String get pathMap_pause => '일시 정지';

  @override
  String get pathMap_replay => '다시 재생';

  @override
  String get pathMap_stepBack => '이전 홉';

  @override
  String get pathMap_stepForward => '다음 홉';

  @override
  String get pathMap_animationOn => '패킷 애니메이션 표시';

  @override
  String get pathMap_animationOff => '패킷 애니메이션 숨기기';

  @override
  String pathMap_hopOf(int current, int total) {
    return '$current/$total 홉';
  }

  @override
  String pathMap_observedPaths(int count) {
    return '관찰된 경로: $count';
  }

  @override
  String get pathMap_primary => '주 경로';

  @override
  String pathMap_alternate(int index) {
    return '대체 $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 홉',
      one: '1 홉',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => '공유 구간';

  @override
  String get pathMap_legendEstimated => '추정 구간';

  @override
  String pathMap_sharedNodeCount(int count) {
    return '$count개의 경로에서 사용됨';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 홉은 위치가 없어 표시된 경로가 일부입니다',
      one: '1 홉은 위치가 없어 표시된 경로가 일부입니다',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => '모두 보기';

  @override
  String get pathMap_hidePath => '경로 숨기기';

  @override
  String get pathMap_showPath => '경로 표시';

  @override
  String get pathMap_collapsePanel => '패널 접기';

  @override
  String get pathMap_expandPanel => '패널 펼치기';

  @override
  String get pathMap_noLocation => '위치 없음';

  @override
  String get pathMap_followPacket => '패킷 고정';

  @override
  String get pathMap_unfollowPacket => '패킷 고정 해제';
}
