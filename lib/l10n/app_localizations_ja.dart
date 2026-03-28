// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => '連絡先';

  @override
  String get nav_channels => 'チャンネル';

  @override
  String get nav_map => '地図';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get common_ok => '了解';

  @override
  String get common_connect => '接続する';

  @override
  String get common_unknownDevice => '不明なデバイス';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '削除';

  @override
  String get common_deleteAll => 'すべて削除';

  @override
  String get common_close => '閉じる';

  @override
  String get common_edit => '編集';

  @override
  String get common_add => '追加';

  @override
  String get common_settings => '設定';

  @override
  String get common_disconnect => '切断する';

  @override
  String get common_connected => '接続されている';

  @override
  String get common_disconnected => '切断';

  @override
  String get common_create => '作成する';

  @override
  String get common_continue => '続き';

  @override
  String get common_share => '共有する';

  @override
  String get common_copy => 'コピー';

  @override
  String get common_retry => '再試';

  @override
  String get common_hide => '隠す';

  @override
  String get common_remove => '削除';

  @override
  String get common_enable => '有効化する';

  @override
  String get common_disable => '無効化する';

  @override
  String get common_reboot => '再起動';

  @override
  String get common_loading => '読み込み中...';

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
  String get scanner_title => 'MeshCore オープン';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'ブルートゥース';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP を使用して接続';

  @override
  String get tcpHostLabel => 'IPアドレス';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => '港';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'エンドポイントを入力し、接続する';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return '$endpoint への接続中...';
  }

  @override
  String get tcpErrorHostRequired => 'IPアドレスが必要です。';

  @override
  String get tcpErrorPortInvalid => 'ポート番号は1から65535の範囲で指定してください。';

  @override
  String get tcpErrorUnsupported => 'このプラットフォームでは、TCP 転送はサポートされていません。';

  @override
  String get tcpErrorTimedOut => 'TCP 接続がタイムアウトしました。';

  @override
  String tcpConnectionFailed(String error) {
    return 'TCP接続に失敗しました：$error';
  }

  @override
  String get usbScreenTitle => 'USB経由で接続';

  @override
  String get usbScreenSubtitle => '検出されたシリアルデバイスを選択し、MeshCoreノードに直接接続してください。';

  @override
  String get usbScreenStatus => 'USBデバイスを選択する';

  @override
  String get usbScreenNote =>
      'USBシリアルポートは、サポートされているAndroidデバイスおよびデスクトッププラットフォームで利用可能です。';

  @override
  String get usbScreenEmptyState =>
      'USBデバイスが見つかりませんでした。「別のUSBデバイスを接続して、再度確認してください。」';

  @override
  String get usbErrorPermissionDenied => 'USBへのアクセス許可が拒否されました。';

  @override
  String get usbErrorDeviceMissing => '選択されたUSBデバイスは、もう利用できません。';

  @override
  String get usbErrorInvalidPort => '有効なUSBデバイスを選択してください。';

  @override
  String get usbErrorBusy => '別のUSB接続の要求がすでに処理中です。';

  @override
  String get usbErrorNotConnected => 'USBデバイスは接続されていません。';

  @override
  String get usbErrorOpenFailed => '選択したUSBデバイスを開くことができません。';

  @override
  String get usbErrorConnectFailed => '選択したUSBデバイスへの接続に失敗しました。';

  @override
  String get usbErrorUnsupported => 'このプラットフォームでは、USBシリアル通信はサポートされていません。';

  @override
  String get usbErrorAlreadyActive => 'USB接続はすでに確立されています。';

  @override
  String get usbErrorNoDeviceSelected => 'USBデバイスは選択されていません。';

  @override
  String get usbErrorPortClosed => 'USB接続は確立されていません。';

  @override
  String get usbErrorConnectTimedOut =>
      '接続がタイムアウトしました。デバイスにUSBコンパニオンファームウェアがインストールされていることを確認してください。';

  @override
  String get usbFallbackDeviceName => 'ウェブシリアルデバイス';

  @override
  String get usbStatus_notConnected => 'USBデバイスを選択する';

  @override
  String get usbStatus_connecting => 'USBデバイスへの接続中...';

  @override
  String get usbStatus_searching => 'USBデバイスを検索中...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB接続に失敗しました：$error';
  }

  @override
  String get scanner_scanning => 'デバイスをスキャン中...';

  @override
  String get scanner_connecting => '接続中...';

  @override
  String get scanner_disconnecting => '切断...';

  @override
  String get scanner_notConnected => '接続されていない';

  @override
  String scanner_connectedTo(String deviceName) {
    return '$deviceName に接続';
  }

  @override
  String get scanner_searchingDevices => 'MeshCoreデバイスの検索';

  @override
  String get scanner_tapToScan => 'MeshCore デバイスを検索するには、「スキャン」ボタンをタップしてください。';

  @override
  String scanner_connectionFailed(String error) {
    return '接続に失敗しました：$error';
  }

  @override
  String get scanner_stop => '停止';

  @override
  String get scanner_scan => 'スキャン';

  @override
  String get scanner_bluetoothOff => 'Bluetooth はオフになっています';

  @override
  String get scanner_bluetoothOffMessage => 'Bluetoothを有効にして、デバイスを検索してください。';

  @override
  String get scanner_chromeRequired => 'Chrome ブラウザが必須です';

  @override
  String get scanner_chromeRequiredMessage =>
      'このWebアプリケーションは、Bluetooth機能を利用するために、Google ChromeまたはChromiumベースのブラウザが必要です。';

  @override
  String get scanner_enableBluetooth => 'Bluetoothを有効にする';

  @override
  String get device_quickSwitch => '素早い切り替え';

  @override
  String get device_meshcore => 'メッシュコア';

  @override
  String get settings_title => '設定';

  @override
  String get settings_deviceInfo => 'デバイス情報';

  @override
  String get settings_appSettings => 'アプリ設定';

  @override
  String get settings_appSettingsSubtitle => '通知、メッセージング、および地図の表示設定';

  @override
  String get settings_nodeSettings => 'ノード設定';

  @override
  String get settings_nodeName => 'ノード名';

  @override
  String get settings_nodeNameNotSet => '設定されていない';

  @override
  String get settings_nodeNameHint => 'ノード名を入力してください';

  @override
  String get settings_nodeNameUpdated => '氏名変更';

  @override
  String get settings_radioSettings => 'ラジオ設定';

  @override
  String get settings_radioSettingsSubtitle => '周波数、電力、スプレッドファクター';

  @override
  String get settings_radioSettingsUpdated => 'ラジオの設定が更新されました';

  @override
  String get settings_location => '場所';

  @override
  String get settings_locationSubtitle => 'GPS 座標';

  @override
  String get settings_locationUpdated => '場所とGPS設定が更新されました';

  @override
  String get settings_locationBothRequired => '緯度と経度をそれぞれ入力してください。';

  @override
  String get settings_locationInvalid => '無効な緯度または経度。';

  @override
  String get settings_locationGPSEnable => 'GPS機能有効';

  @override
  String get settings_locationGPSEnableSubtitle => 'GPSが自動的に位置情報を更新できるようにする。';

  @override
  String get settings_locationIntervalSec => 'GPS データの取得間隔（秒）';

  @override
  String get settings_locationIntervalInvalid =>
      '間隔は少なくとも60秒で、86400秒未満でなければなりません。';

  @override
  String get settings_latitude => '緯度';

  @override
  String get settings_longitude => '経度';

  @override
  String get settings_contactSettings => '連絡設定';

  @override
  String get settings_contactSettingsSubtitle => '連絡先を追加する設定';

  @override
  String get settings_privacyMode => 'プライバシーモード';

  @override
  String get settings_privacyModeSubtitle => '広告に名前/場所を記載しない';

  @override
  String get settings_privacyModeToggle =>
      'プライバシーモードをオンにして、広告に表示される名前や場所を非表示にします。';

  @override
  String get settings_privacyModeEnabled => 'プライバシーモードが有効になっています';

  @override
  String get settings_privacyModeDisabled => 'プライバシーモードは無効化されています';

  @override
  String get settings_privacy => 'プライバシー設定';

  @override
  String get settings_privacySubtitle => '共有する情報の内容を管理する。';

  @override
  String get settings_privacySettingsDescription =>
      '自分のデバイスが他の人に共有する情報を選択してください。';

  @override
  String get settings_denyAll => 'すべてを否定';

  @override
  String get settings_allowByContact => '連絡先を明示するオプション';

  @override
  String get settings_allowAll => 'すべて許可';

  @override
  String get settings_telemetryBaseMode => 'テレメトリ基本モード';

  @override
  String get settings_telemetryLocationMode => 'テレメトリ位置特定モード';

  @override
  String get settings_telemetryEnvironmentMode => 'テレメトリ環境モード';

  @override
  String get settings_advertLocation => '広告掲載場所';

  @override
  String get settings_advertLocationSubtitle => '広告に場所を記載してください。';

  @override
  String settings_multiAck(String value) {
    return '複数のACK：$value';
  }

  @override
  String get settings_telemetryModeUpdated => 'テレメトリモードが更新されました';

  @override
  String get settings_actions => '行動';

  @override
  String get settings_sendAdvertisement => '広告を送信する';

  @override
  String get settings_sendAdvertisementSubtitle => '現在、放送での活動';

  @override
  String get settings_advertisementSent => '広告が送信されました';

  @override
  String get settings_syncTime => '同期時間';

  @override
  String get settings_syncTimeSubtitle => 'デバイスの時刻を、携帯電話の時刻に合わせる';

  @override
  String get settings_timeSynchronized => '時間同期';

  @override
  String get settings_refreshContacts => '連絡先を更新する';

  @override
  String get settings_refreshContactsSubtitle => 'デバイスから連絡先リストを再読み込みする';

  @override
  String get settings_rebootDevice => 'デバイスを再起動する';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore デバイスを再起動する';

  @override
  String get settings_rebootDeviceConfirm =>
      '本当にデバイスを再起動したいですか？ その場合、接続が切断されます。';

  @override
  String get settings_debug => 'デバッグ';

  @override
  String get settings_bleDebugLog => 'BLE デバッグログ';

  @override
  String get settings_bleDebugLogSubtitle => 'BLEコマンド、応答、および生のデータ';

  @override
  String get settings_appDebugLog => 'アプリケーションのデバッグログ';

  @override
  String get settings_appDebugLogSubtitle => 'アプリケーションのデバッグメッセージ';

  @override
  String get settings_about => '概要';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open $version版';
  }

  @override
  String get settings_aboutLegalese => '2026年のMeshCoreオープンソースプロジェクト';

  @override
  String get settings_aboutDescription =>
      'MeshCore LoRaメッシュネットワークデバイス用の、オープンソースのFlutterクライアント。';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS 標高データ：Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => '名前';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'ステータス';

  @override
  String get settings_infoBattery => 'バッテリー';

  @override
  String get settings_infoPublicKey => '公開鍵';

  @override
  String get settings_infoContactsCount => '連絡先数';

  @override
  String get settings_infoChannelCount => 'チャンネル数';

  @override
  String get settings_presets => 'プリセット';

  @override
  String get settings_frequency => '周波数 (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => '無効な周波数 (300-2500 MHz)';

  @override
  String get settings_bandwidth => '帯域幅';

  @override
  String get settings_spreadingFactor => '伝播係数';

  @override
  String get settings_codingRate => 'コーディング速度';

  @override
  String get settings_txPower => 'TX 信号電力 (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => '無効な送信電力 (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'オフグリッド（電力網から孤立した状態）の繰り返し';

  @override
  String get settings_clientRepeatSubtitle =>
      'このデバイスが、他のデバイスに対してメッシュパケットを繰り返し送信できるようにする。';

  @override
  String get settings_clientRepeatFreqWarning =>
      'オフグリッドでの再送には、433MHz、869MHz、または918MHzの周波数が必要です。';

  @override
  String settings_error(String message) {
    return 'エラー：$message';
  }

  @override
  String get appSettings_title => 'アプリ設定';

  @override
  String get appSettings_appearance => '外観';

  @override
  String get appSettings_theme => 'テーマ';

  @override
  String get appSettings_themeSystem => 'システムデフォルト';

  @override
  String get appSettings_themeLight => '光';

  @override
  String get appSettings_themeDark => '暗い';

  @override
  String get appSettings_language => '言語';

  @override
  String get appSettings_languageSystem => 'システムデフォルト';

  @override
  String get appSettings_languageEn => '英語';

  @override
  String get appSettings_languageFr => 'フランス語';

  @override
  String get appSettings_languageEs => 'スペイン語';

  @override
  String get appSettings_languageDe => 'ドイツ語';

  @override
  String get appSettings_languagePl => 'ポーランド語';

  @override
  String get appSettings_languageSl => 'スロベニア語';

  @override
  String get appSettings_languagePt => 'ポルトガル語';

  @override
  String get appSettings_languageIt => 'イタリア語';

  @override
  String get appSettings_languageZh => '中国語';

  @override
  String get appSettings_languageSv => 'スウェーデン語';

  @override
  String get appSettings_languageNl => 'オランダ語';

  @override
  String get appSettings_languageSk => 'スロベニア語';

  @override
  String get appSettings_languageBg => 'ブルガリア語';

  @override
  String get appSettings_languageRu => 'ロシア語';

  @override
  String get appSettings_languageUk => 'ウクライナ語';

  @override
  String get appSettings_enableMessageTracing => 'メッセージ追跡機能を有効にする';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'メッセージに関する詳細な経路およびタイミングに関するメタデータを表示する';

  @override
  String get appSettings_notifications => '通知';

  @override
  String get appSettings_enableNotifications => '通知を有効にする';

  @override
  String get appSettings_enableNotificationsSubtitle => 'メッセージや広告に関する通知を受け取る';

  @override
  String get appSettings_notificationPermissionDenied => '通知の許可が拒否されました';

  @override
  String get appSettings_notificationsEnabled => '通知機能が有効になっています';

  @override
  String get appSettings_notificationsDisabled => '通知が無効化されています';

  @override
  String get appSettings_messageNotifications => 'メッセージ通知';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      '新しいメッセージを受信した際に、通知を表示する';

  @override
  String get appSettings_channelMessageNotifications => 'チャネルメッセージの通知';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'チャンネルからのメッセージを受信した際に、通知を表示する';

  @override
  String get appSettings_advertisementNotifications => '広告通知';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      '新しいノードが発見された場合に通知を表示する';

  @override
  String get appSettings_messaging => 'メッセージング';

  @override
  String get appSettings_clearPathOnMaxRetry => 'マックスリトライでの明確な手順';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      '5回送信に失敗した場合、連絡経路をリセットする';

  @override
  String get appSettings_pathsWillBeCleared => '5回失敗した後、経路が再開されます。';

  @override
  String get appSettings_pathsWillNotBeCleared => 'パスは自動で削除されません。';

  @override
  String get appSettings_autoRouteRotation => '自動ルートの切り替え';

  @override
  String get appSettings_autoRouteRotationSubtitle => '最適なルートと、洪水モードを切り替える';

  @override
  String get appSettings_autoRouteRotationEnabled => '自動ルートの切り替え機能が有効になっています';

  @override
  String get appSettings_autoRouteRotationDisabled => '自動ルートの変更機能が無効になっています。';

  @override
  String get appSettings_maxRouteWeight => '最大ルート重量';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'ある経路が、成功裏に配送された場合に、積み上げられる最大重量';

  @override
  String get appSettings_initialRouteWeight => '初期ルートの重み';

  @override
  String get appSettings_initialRouteWeightSubtitle => '新たに発見された経路の初期重量';

  @override
  String get appSettings_routeWeightSuccessIncrement => '成功時の重み増加';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      '配送が成功した場合に、経路に追加される重量';

  @override
  String get appSettings_routeWeightFailureDecrement => '失敗時の重み減少';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      '配送に失敗した際に、経路から取り除かれた重量';

  @override
  String get appSettings_maxMessageRetries => '最大メッセージ再試行回数';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'メッセージを「失敗」とマークするまでの、再試行回数';

  @override
  String path_routeWeight(String weight, String max) {
    return '$weight/$max';
  }

  @override
  String get appSettings_battery => 'バッテリー';

  @override
  String get appSettings_batteryChemistry => '電池の化学';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '$deviceName 単位';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst => 'デバイスを選択するために接続する';

  @override
  String get appSettings_batteryNmc => '18650型 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => '地図の表示';

  @override
  String get appSettings_showRepeaters => '繰り返し再生機能';

  @override
  String get appSettings_showRepeatersSubtitle => '地図上にリピーターノードを表示する';

  @override
  String get appSettings_showChatNodes => 'チャットノードの表示';

  @override
  String get appSettings_showChatNodesSubtitle => '地図上にチャットノードを表示する';

  @override
  String get appSettings_showOtherNodes => '他のノードを表示する';

  @override
  String get appSettings_showOtherNodesSubtitle => '地図上に、他のノードの種類を表示する';

  @override
  String get appSettings_timeFilter => '時間フィルター';

  @override
  String get appSettings_timeFilterShowAll => 'すべてのノードを表示する';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '過去 $hours 時間のノードを表示する';
  }

  @override
  String get appSettings_mapTimeFilter => '地図の表示期間を絞り込む';

  @override
  String get appSettings_showNodesDiscoveredWithin => '以下の範囲内で発見されたノードを表示する：';

  @override
  String get appSettings_allTime => 'すべての期間';

  @override
  String get appSettings_lastHour => '直前の';

  @override
  String get appSettings_last6Hours => '過去6時間';

  @override
  String get appSettings_last24Hours => '過去24時間';

  @override
  String get appSettings_lastWeek => '先週';

  @override
  String get appSettings_offlineMapCache => 'オフライン用地図キャッシュ';

  @override
  String get appSettings_unitsTitle => '単位';

  @override
  String get appSettings_unitsMetric => 'メートル (m) / キロメートル (km)';

  @override
  String get appSettings_unitsImperial => '帝国 (フィート / マイル)';

  @override
  String get appSettings_noAreaSelected => '選択されたエリアはありません';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return '選択された範囲（ズームレベル：$minZoom～$maxZoom）';
  }

  @override
  String get appSettings_debugCard => 'デバッグ';

  @override
  String get appSettings_appDebugLogging => 'アプリケーションのデバッグ用ログ';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'ログアプリのデバッグメッセージ（トラブルシューティング用）';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'アプリケーションのデバッグ用ログ機能が有効になっています。';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'アプリケーションのデバッグログが無効化されています。';

  @override
  String get contacts_title => '連絡先';

  @override
  String get contacts_noContacts => '現時点では、連絡先はまだありません。';

  @override
  String get contacts_contactsWillAppear => 'デバイスが広告を行う際に、連絡先が表示されます。';

  @override
  String get contacts_unread => '未読';

  @override
  String get contacts_searchContactsNoNumber => '連絡先を検索...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '$number件の$strに関する連絡先を検索...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return '$number件の$strを検索...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return '$number件の$strに関するユーザーを検索する...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return '$number $str までの検索...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return '$number $str 部屋のサーバーを検索する...';
  }

  @override
  String get contacts_noUnreadContacts => '未読の連絡先はありません';

  @override
  String get contacts_noContactsFound => '連絡先またはグループは見つかりませんでした。';

  @override
  String get contacts_deleteContact => '連絡先を削除';

  @override
  String contacts_removeConfirm(String contactName) {
    return '$contactName を連絡先から削除しますか？';
  }

  @override
  String get contacts_manageRepeater => 'リピーターの管理';

  @override
  String get contacts_manageRoom => 'ルームサーバーの管理';

  @override
  String get contacts_roomLogin => 'ルームサーバーへのログイン';

  @override
  String get contacts_openChat => '自由な会話';

  @override
  String get contacts_editGroup => '編集グループ';

  @override
  String get contacts_deleteGroup => 'グループを削除';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '$groupName を削除しますか？';
  }

  @override
  String get contacts_newGroup => '新しいグループ';

  @override
  String get contacts_groupName => 'グループ名';

  @override
  String get contacts_groupNameRequired => 'グループ名が必須です';

  @override
  String get contacts_groupNameReserved => 'このグループ名はすでに使用されています。';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'グループ「$name」はすでに存在しています';
  }

  @override
  String get contacts_filterContacts => '連絡先をフィルタリングする…';

  @override
  String get contacts_noContactsMatchFilter => '指定された条件に合致する連絡先は見つかりませんでした。';

  @override
  String get contacts_noMembers => 'メンバーはいない';

  @override
  String get contacts_lastSeenNow => '最近';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '～$minutes 分';
  }

  @override
  String get contacts_lastSeenHourAgo => '約1時間';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '～ $hours 時間';
  }

  @override
  String get contacts_lastSeenDayAgo => '～1日';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '～$days日間';
  }

  @override
  String get contact_info => '連絡先';

  @override
  String get contact_settings => '連絡設定';

  @override
  String get contact_telemetry => 'テレメトリー';

  @override
  String get contact_lastSeen => '最後に確認された場所';

  @override
  String get contact_clearChat => 'チャットのクリア';

  @override
  String get contact_teleBase => 'テレメトリ基地';

  @override
  String get contact_teleBaseSubtitle => 'バッテリー残量と基本的なテレメトリーの共有を許可する';

  @override
  String get contact_teleLoc => 'テレメトリの場所';

  @override
  String get contact_teleLocSubtitle => '位置情報共有を許可する';

  @override
  String get contact_teleEnv => 'テレメトリ環境';

  @override
  String get contact_teleEnvSubtitle => '環境センサーのデータを共有することを許可する';

  @override
  String get channels_title => 'チャンネル';

  @override
  String get channels_noChannelsConfigured => '設定されたチャンネルがありません';

  @override
  String get channels_addPublicChannel => 'パブリックチャンネルを追加する';

  @override
  String get channels_searchChannels => '検索オプション...';

  @override
  String get channels_noChannelsFound => 'チャンネルが見つかりませんでした';

  @override
  String channels_channelIndex(int index) {
    return 'チャンネル $index';
  }

  @override
  String get channels_hashtagChannel => 'ハッシュタグチャンネル';

  @override
  String get channels_public => '一般の人々';

  @override
  String get channels_private => '個人の';

  @override
  String get channels_publicChannel => '一般チャンネル';

  @override
  String get channels_privateChannel => 'プライベートチャンネル';

  @override
  String get channels_editChannel => 'チャンネルを編集する';

  @override
  String get channels_muteChannel => 'ミュート機能';

  @override
  String get channels_unmuteChannel => 'ミュートを解除する';

  @override
  String get channels_deleteChannel => 'チャンネルを削除する';

  @override
  String channels_deleteChannelConfirm(String name) {
    return '$name を削除しますか？ これは取り消すことができません。';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'チャンネル「$name」の削除に失敗しました。';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'チャンネル「$name」が削除されました';
  }

  @override
  String get channels_addChannel => 'チャンネルを追加';

  @override
  String get channels_channelIndexLabel => 'チャンネルインデックス';

  @override
  String get channels_channelName => 'チャンネル名';

  @override
  String get channels_usePublicChannel => 'パブリックチャンネルを使用する';

  @override
  String get channels_standardPublicPsk => '標準的な公用 PSK';

  @override
  String get channels_pskHex => 'PSK (ヘックス)';

  @override
  String get channels_generateRandomPsk => 'ランダムなPSK（正交符号分割変調）を生成する';

  @override
  String get channels_enterChannelName => 'チャンネル名を入力してください';

  @override
  String get channels_pskMustBe32Hex => 'PSKは32桁の16進数で構成されている必要があります。';

  @override
  String channels_channelAdded(String name) {
    return 'チャンネル「$name」を追加';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'チャンネル $index の編集';
  }

  @override
  String get channels_smazCompression => 'SMAZ 圧縮';

  @override
  String channels_channelUpdated(String name) {
    return 'チャンネル「$name」が更新されました';
  }

  @override
  String get channels_publicChannelAdded => 'パブリックチャンネルが追加されました';

  @override
  String get channels_sortBy => '並び替え';

  @override
  String get channels_sortManual => 'マニュアル';

  @override
  String get channels_sortAZ => 'AからZ';

  @override
  String get channels_sortLatestMessages => '最新のメッセージ';

  @override
  String get channels_sortUnread => '未読';

  @override
  String get channels_createPrivateChannel => 'プライベートチャンネルを作成する';

  @override
  String get channels_createPrivateChannelDesc => '秘密鍵を使用して保護されています。';

  @override
  String get channels_joinPrivateChannel => 'プライベートチャンネルに参加する';

  @override
  String get channels_joinPrivateChannelDesc => '手動で秘密のキーを入力する。';

  @override
  String get channels_joinPublicChannel => '公開チャンネルに参加する';

  @override
  String get channels_joinPublicChannelDesc => 'このチャンネルには、誰でも参加できます。';

  @override
  String get channels_joinHashtagChannel => 'ハッシュタグチャンネルに参加する';

  @override
  String get channels_joinHashtagChannelDesc => '誰でもハッシュタグチャンネルに参加できます。';

  @override
  String get channels_scanQrCode => 'QRコードをスキャンする';

  @override
  String get channels_scanQrCodeComingSoon => '近日公開';

  @override
  String get channels_enterHashtag => 'ハッシュタグを入力してください';

  @override
  String get channels_hashtagHint => '例：#チーム';

  @override
  String get chat_noMessages => 'まだメッセージは届いていません';

  @override
  String get chat_sendMessageToStart => '開始するためにメッセージを送信してください';

  @override
  String get chat_originalMessageNotFound => '元のメッセージが見つかりませんでした';

  @override
  String chat_replyingTo(String name) {
    return '$name への返信';
  }

  @override
  String chat_replyTo(String name) {
    return '$nameへの返信';
  }

  @override
  String get chat_location => '場所';

  @override
  String chat_sendMessageTo(String contactName) {
    return '$contactName へのメッセージを送信する';
  }

  @override
  String get chat_typeMessage => 'メッセージを入力してください…';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'メッセージが長すぎる（$maxBytes バイトを超える）。';
  }

  @override
  String get chat_messageCopied => 'メッセージがコピーされました';

  @override
  String get chat_messageDeleted => 'メッセージは削除されました';

  @override
  String get chat_retryingMessage => '再試行メッセージ';

  @override
  String chat_retryCount(int current, int max) {
    return '$current / $max 回目';
  }

  @override
  String get chat_sendGif => 'GIFを送信する';

  @override
  String get chat_reply => '返信';

  @override
  String get chat_addReaction => '反応を追加';

  @override
  String get chat_me => '私';

  @override
  String get emojiCategorySmileys => '笑顔の絵文字';

  @override
  String get emojiCategoryGestures => '身振り、動作';

  @override
  String get emojiCategoryHearts => '心';

  @override
  String get emojiCategoryObjects => '対象物';

  @override
  String get gifPicker_title => 'GIF を選択してください';

  @override
  String get gifPicker_searchHint => 'GIFの検索...';

  @override
  String get gifPicker_poweredBy => 'GIPHYによる提供';

  @override
  String get gifPicker_noGifsFound => 'GIF形式のファイルは見つかりませんでした';

  @override
  String get gifPicker_failedLoad => 'GIFファイルの読み込みに失敗しました';

  @override
  String get gifPicker_failedSearch => 'GIFファイルの検索に失敗しました';

  @override
  String get gifPicker_noInternet => 'インターネット接続なし';

  @override
  String get debugLog_appTitle => 'アプリケーションのデバッグログ';

  @override
  String get debugLog_bleTitle => 'BLE デバッグログ';

  @override
  String get debugLog_copyLog => '記録';

  @override
  String get debugLog_clearLog => '詳細なログ';

  @override
  String get debugLog_copied => 'デバッグログをコピー';

  @override
  String get debugLog_bleCopied => 'BLEログのコピー';

  @override
  String get debugLog_noEntries => 'デバッグログはまだ生成されていません';

  @override
  String get debugLog_enableInSettings => 'アプリのデバッグログを有効にするには、設定から操作してください。';

  @override
  String get debugLog_frames => 'フレーム';

  @override
  String get debugLog_rawLogRx => '生のログ-RX';

  @override
  String get debugLog_noBleActivity => '現時点では、BLE関連の活動は行われていません。';

  @override
  String debugFrame_length(int count) {
    return 'フレーム長: $count バイト';
  }

  @override
  String debugFrame_command(String value) {
    return 'コマンド: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'テキストメッセージ用フレーム：';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- 宛先公開鍵: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- タイムスタンプ: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- フラグ: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- テキストの種類: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI（コマンドラインインターフェース）';

  @override
  String get debugFrame_textTypePlain => 'シンプルな';

  @override
  String debugFrame_text(String text) {
    return '- テキスト：「$text」';
  }

  @override
  String get debugFrame_hexDump => 'ヘックスダンプ：';

  @override
  String get chat_pathManagement => '経路管理';

  @override
  String get chat_ShowAllPaths => 'すべての経路を表示';

  @override
  String get chat_routingMode => 'ルーティングモード';

  @override
  String get chat_autoUseSavedPath => '自動 (保存されたパスを使用)';

  @override
  String get chat_forceFloodMode => '強制的に洪水モードを起動';

  @override
  String get chat_recentAckPaths => '最近使用したACKパス（タップして使用）：';

  @override
  String get chat_pathHistoryFull => 'パスの履歴は完全です。エントリを削除して、新しいものを追加できます。';

  @override
  String get chat_hopSingular => 'ジャンプ';

  @override
  String get chat_hopPlural => 'ホップ';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ホップ',
      one: 'ホップ',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_successes => '成功事例';

  @override
  String get chat_removePath => 'パスを削除する';

  @override
  String get chat_noPathHistoryYet => 'まだ履歴はありません。\nパスを特定するためにメッセージを送信してください。';

  @override
  String get chat_pathActions => 'パスの操作：';

  @override
  String get chat_setCustomPath => 'カスタムパスを設定';

  @override
  String get chat_setCustomPathSubtitle => '手動で経路を指定する';

  @override
  String get chat_clearPath => '明確な道';

  @override
  String get chat_clearPathSubtitle => '次回送信時に、以前の情報を再取得する';

  @override
  String get chat_pathCleared => '経路が確保されました。次のメッセージでルートを再確認します。';

  @override
  String get chat_floodModeSubtitle => 'アプリのバーにあるルーティング切り替え機能を使用する';

  @override
  String get chat_floodModeEnabled =>
      '洪水モードが有効になっています。アプリのメニューバーにあるルートアイコンを使用して、モードを切り替えることができます。';

  @override
  String get chat_fullPath => 'フルパス';

  @override
  String get chat_pathDetailsNotAvailable =>
      '経路の詳細については、まだ情報がありません。「リフレッシュ」ボタンを押して、再度お試しください。';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Path set: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally => 'ローカルで保存。同期のために接続する。';

  @override
  String get chat_pathDeviceConfirmed => 'デバイスの確認済み。';

  @override
  String get chat_pathDeviceNotConfirmed => 'デバイスの確認はまだできていません。';

  @override
  String get chat_type => '種類';

  @override
  String get chat_path => '道';

  @override
  String get chat_publicKey => '公開鍵';

  @override
  String get chat_compressOutgoingMessages => '送信されるメッセージを圧縮する';

  @override
  String get chat_floodForced => '洪水（強制的な）';

  @override
  String get chat_directForced => '直接的な（強制的な）';

  @override
  String chat_hopsForced(int count) {
    return '$count 本のホップ（強制的に採取）';
  }

  @override
  String get chat_floodAuto => '洪水 (自動)';

  @override
  String get chat_direct => '直接';

  @override
  String get chat_poiShared => '共有されたPOI';

  @override
  String chat_unread(int count) {
    return '未読: $count';
  }

  @override
  String get chat_openLink => 'リンクを開く？';

  @override
  String get chat_openLinkConfirmation => 'このリンクをブラウザで開くことはご希望ですか？';

  @override
  String get chat_open => '開く';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'リンクを開けられませんでした: $url';
  }

  @override
  String get chat_invalidLink => '無効なリンク形式';

  @override
  String get map_title => 'ノードマップ';

  @override
  String get map_lineOfSight => '視界';

  @override
  String get map_losScreenTitle => '視界';

  @override
  String get map_noNodesWithLocation => '位置情報データを持つノードは存在しません';

  @override
  String get map_nodesNeedGps => 'ノードは、地図上に表示されるために、GPS座標を共有する必要があります。';

  @override
  String map_nodesCount(int count) {
    return 'ノード：$count';
  }

  @override
  String map_pinsCount(int count) {
    return 'ピン：$count個';
  }

  @override
  String get map_chat => 'チャット';

  @override
  String get map_repeater => '繰り返し送信装置';

  @override
  String get map_room => '部屋';

  @override
  String get map_sensor => 'センサー';

  @override
  String get map_pinDm => 'ピン（DM）';

  @override
  String get map_pinPrivate => 'プライベート（非公開）';

  @override
  String get map_pinPublic => '公開 (一般公開)';

  @override
  String get map_lastSeen => '最後に確認された場所';

  @override
  String get map_disconnectConfirm => '本当にこのデバイスとの接続を解除したいですか？';

  @override
  String get map_from => '～から';

  @override
  String get map_source => '出典';

  @override
  String get map_flags => '旗';

  @override
  String get map_shareMarkerHere => 'この場所でシェア';

  @override
  String get map_setAsMyLocation => '現在地として設定';

  @override
  String get map_pinLabel => 'ピンラベル';

  @override
  String get map_label => 'ラベル';

  @override
  String get map_pointOfInterest => '注目すべき点';

  @override
  String get map_sendToContact => '連絡先へ送信';

  @override
  String get map_sendToChannel => '特定のチャンネルに送信する';

  @override
  String get map_noChannelsAvailable => '利用可能なチャンネルはありません';

  @override
  String get map_publicLocationShare => '公共スペースの共有';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '現在、$channelLabel で位置情報を共有する準備をしています。このチャンネルは公開されており、PSK を持つ誰でも閲覧できます。';
  }

  @override
  String get map_connectToShareMarkers => '他のデバイスと接続して、マーカーを共有する';

  @override
  String get map_filterNodes => 'フィルタノード';

  @override
  String get map_nodeTypes => 'ノードの種類';

  @override
  String get map_chatNodes => 'チャットノード';

  @override
  String get map_repeaters => '繰り返し送信装置';

  @override
  String get map_otherNodes => 'その他のノード';

  @override
  String get map_showOverlaps => 'リピーターキーの重複';

  @override
  String get map_keyPrefix => '主要なプレフィックス';

  @override
  String get map_filterByKeyPrefix => '主要なプレフィックスでフィルタリングする';

  @override
  String get map_publicKeyPrefix => '公開鍵のプレフィックス';

  @override
  String get map_markers => 'マーカー';

  @override
  String get map_showSharedMarkers => '共有のマーカーを表示する';

  @override
  String get map_showGuessedLocations => '推測されたノードの位置を表示する';

  @override
  String get map_showDiscoveryContacts => 'Discovery社の連絡先を表示する';

  @override
  String get map_guessedLocation => '推測された場所';

  @override
  String get map_lastSeenTime => '最後に確認された時間';

  @override
  String get map_sharedPin => '共有パスワード';

  @override
  String get map_joinRoom => '部屋に参加する';

  @override
  String get map_manageRepeater => 'リピーターの管理';

  @override
  String get map_tapToAdd => 'ノードをクリックして、パスに追加します。';

  @override
  String get map_runTrace => 'パスの追跡を実行';

  @override
  String get map_runTraceWithReturnPath => '元の経路に戻る。';

  @override
  String get map_removeLast => '最後のものを削除';

  @override
  String get map_pathTraceCancelled => 'パスの追跡は中止。';

  @override
  String get mapCache_title => 'オフライン用地図キャッシュ';

  @override
  String get mapCache_selectAreaFirst => '最初にキャッシュする領域を選択してください';

  @override
  String get mapCache_noTilesToDownload => 'この地域にはダウンロードできるタイルは存在しません。';

  @override
  String get mapCache_downloadTilesTitle => 'タイルをダウンロードする';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'オフラインでの使用のために、$count個のタイルをダウンロードしますか？';
  }

  @override
  String get mapCache_downloadAction => 'ダウンロード';

  @override
  String mapCache_cachedTiles(int count) {
    return '$count 個のタイルをキャッシュ';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Cached $downloaded tiles ($failed failed)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'オフラインキャッシュをクリアする';

  @override
  String get mapCache_clearOfflineCachePrompt => 'キャッシュされた地図のタイルをすべて削除しますか？';

  @override
  String get mapCache_offlineCacheCleared => 'オフラインキャッシュをクリア';

  @override
  String get mapCache_noAreaSelected => '選択されたエリアはありません';

  @override
  String get mapCache_cacheArea => 'キャッシュエリア';

  @override
  String get mapCache_useCurrentView => '現在表示されている内容を保持する';

  @override
  String get mapCache_zoomRange => 'ズーム範囲';

  @override
  String mapCache_estimatedTiles(int count) {
    return '推定されるタイル数: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Downloaded $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'タイルをダウンロードする';

  @override
  String get mapCache_clearCacheButton => 'キャッシュをクリアする';

  @override
  String mapCache_failedDownloads(int count) {
    return '失敗したダウンロード: $count';
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
  String get time_justNow => 'まさに今';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String time_daysAgo(int days) {
    return '$days日前';
  }

  @override
  String get time_hour => '1時間';

  @override
  String get time_hours => '時間';

  @override
  String get time_day => '一日';

  @override
  String get time_days => '日';

  @override
  String get time_week => '1週間';

  @override
  String get time_weeks => '週';

  @override
  String get time_month => '月';

  @override
  String get time_months => '月';

  @override
  String get time_minutes => '分';

  @override
  String get time_allTime => '全期間';

  @override
  String get dialog_disconnect => '切断する';

  @override
  String get dialog_disconnectConfirm => '本当にこのデバイスとの接続を解除したいですか？';

  @override
  String get login_repeaterLogin => '再ログイン';

  @override
  String get login_roomLogin => 'ルームサーバーへのログイン';

  @override
  String get login_password => 'パスワード';

  @override
  String get login_enterPassword => 'パスワードを入力してください';

  @override
  String get login_savePassword => 'パスワードを保存する';

  @override
  String get login_savePasswordSubtitle => 'パスワードは、このデバイスに安全に保存されます。';

  @override
  String get login_repeaterDescription =>
      '設定やステータスにアクセスするために、リピーターのパスワードを入力してください。';

  @override
  String get login_roomDescription => '設定やステータスへのアクセスには、部屋のパスワードを入力してください。';

  @override
  String get login_routing => '経路設定';

  @override
  String get login_routingMode => 'ルーティングモード';

  @override
  String get login_autoUseSavedPath => '自動 (保存されたパスを使用)';

  @override
  String get login_forceFloodMode => '強制的に洪水モードを起動';

  @override
  String get login_managePaths => 'パスの管理';

  @override
  String get login_login => 'ログイン';

  @override
  String login_attempt(int current, int max) {
    return '試行回数：$current/$max';
  }

  @override
  String login_failed(String error) {
    return 'ログインに失敗しました：$error';
  }

  @override
  String get login_failedMessage =>
      'ログインに失敗しました。パスワードが間違っているか、または接続が確立されていません。';

  @override
  String get common_reload => '再読み込み';

  @override
  String get common_clear => '明確';

  @override
  String path_currentPath(String path) {
    return '現在のパス: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ホップ',
      one: 'ホップ',
    );
    return '$count $_temp0のパスを使用';
  }

  @override
  String get path_enterCustomPath => 'カスタムパスを入力';

  @override
  String get path_currentPathLabel => '現在の経路';

  @override
  String get path_hexPrefixInstructions =>
      '各ホップに対して、2文字の16進数プレフィックスをカンマで区切って入力してください。';

  @override
  String get path_hexPrefixExample => '例：A1, F2, 3C (各ノードは、自身の公開鍵の最初のバイトを使用)';

  @override
  String get path_labelHexPrefixes => 'パス (ヘックスプレフィックス)';

  @override
  String get path_helperMaxHops =>
      '最大64個のホップ。各プレフィックスは2つの16進数文字（1バイト）で構成されています。';

  @override
  String get path_selectFromContacts => 'または、連絡先リストから選択してください：';

  @override
  String get path_noRepeatersFound => '繰り返し機能やルームサーバーは見つかりませんでした。';

  @override
  String get path_customPathsRequire => 'カスタムパスには、メッセージを中継できる中間地点が必要です。';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return '無効な16進数プレフィックス: $prefixes';
  }

  @override
  String get path_tooLong => '経路が長すぎる。最大64回のジャンプのみ許可。';

  @override
  String get path_setPath => 'パスを設定';

  @override
  String get repeater_management => 'リピーター管理';

  @override
  String get room_management => 'ルームサーバーの管理';

  @override
  String get repeater_managementTools => '管理ツール';

  @override
  String get repeater_status => 'ステータス';

  @override
  String get repeater_statusSubtitle => 'リピーターの状態、統計情報、および隣接するネットワークの情報を表示する';

  @override
  String get repeater_telemetry => 'テレメトリー';

  @override
  String get repeater_telemetrySubtitle => 'センサーおよびシステムの状態に関するテレメトリの表示';

  @override
  String get repeater_cli => 'CLI（コマンドラインインターフェース）';

  @override
  String get repeater_cliSubtitle => 'リピーターへのコマンドを送信する';

  @override
  String get repeater_neighbors => '近隣住民';

  @override
  String get repeater_neighborsSubtitle => 'ゼロホップの隣接ノードを表示する。';

  @override
  String get repeater_settings => '設定';

  @override
  String get repeater_settingsSubtitle => 'リピーターのパラメータを設定する';

  @override
  String get repeater_statusTitle => '再送ステータス';

  @override
  String get repeater_routingMode => 'ルーティングモード';

  @override
  String get repeater_autoUseSavedPath => '自動 (保存されたパスを使用)';

  @override
  String get repeater_forceFloodMode => '強制的に洪水モードを起動';

  @override
  String get repeater_pathManagement => '経路管理';

  @override
  String get repeater_refresh => 'リフレッシュ';

  @override
  String get repeater_statusRequestTimeout => 'ステータス情報の取得に失敗しました。';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'ステータス読み込みエラー: $error';
  }

  @override
  String get repeater_systemInformation => 'システム情報';

  @override
  String get repeater_battery => 'バッテリー';

  @override
  String get repeater_clockAtLogin => 'ログイン時の時刻表示';

  @override
  String get repeater_uptime => '稼働率';

  @override
  String get repeater_queueLength => '待ち行列の長さ';

  @override
  String get repeater_debugFlags => 'デバッグフラグ';

  @override
  String get repeater_radioStatistics => 'ラジオに関する統計';

  @override
  String get repeater_lastRssi => '最後のRSSI';

  @override
  String get repeater_lastSnr => '最後のSNR';

  @override
  String get repeater_noiseFloor => 'ノイズレベル';

  @override
  String get repeater_txAirtime => 'TXの放送時間';

  @override
  String get repeater_rxAirtime => 'RX 空き時間';

  @override
  String get repeater_packetStatistics => 'パケット統計';

  @override
  String get repeater_sent => '送信';

  @override
  String get repeater_received => '受領';

  @override
  String get repeater_duplicates => '重複';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days日 $hours時間 $minutes分 $seconds秒';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return '合計: $total, 洪水: $flood, 直接: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '合計: $total, 洪水: $flood, 直接: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return '$flood: $flood, 直接: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return '合計: $total';
  }

  @override
  String get repeater_settingsTitle => 'リピーター設定';

  @override
  String get repeater_basicSettings => '基本設定';

  @override
  String get repeater_repeaterName => '送信装置名';

  @override
  String get repeater_repeaterNameHelper => 'このリピーターの名前';

  @override
  String get repeater_adminPassword => '管理者パスワード';

  @override
  String get repeater_adminPasswordHelper => '完全アクセス権のパスワード';

  @override
  String get repeater_guestPassword => 'ゲスト用のパスワード';

  @override
  String get repeater_guestPasswordHelper => '読み取り専用アクセス用のパスワード';

  @override
  String get repeater_radioSettings => 'ラジオ設定';

  @override
  String get repeater_frequencyMhz => '周波数 (MHz)';

  @override
  String get repeater_frequencyHelper => '300～2500 MHz';

  @override
  String get repeater_txPower => 'TXパワー';

  @override
  String get repeater_txPowerHelper => '-30～-10 dBm';

  @override
  String get repeater_bandwidth => '帯域幅';

  @override
  String get repeater_spreadingFactor => '伝播係数';

  @override
  String get repeater_codingRate => 'コーディング速度';

  @override
  String get repeater_locationSettings => '場所設定';

  @override
  String get repeater_latitude => '緯度';

  @override
  String get repeater_latitudeHelper => '度分表記（例：37.7749）';

  @override
  String get repeater_longitude => '経度';

  @override
  String get repeater_longitudeHelper => '度分表記（例：-122.4194）';

  @override
  String get repeater_features => '特徴';

  @override
  String get repeater_packetForwarding => 'パケット転送';

  @override
  String get repeater_packetForwardingSubtitle => 'リピーターがパケットを転送できるように設定する';

  @override
  String get repeater_guestAccess => 'ゲストへのアクセス';

  @override
  String get repeater_guestAccessSubtitle => 'ゲストへの読み取り専用アクセスを許可する';

  @override
  String get repeater_privacyMode => 'プライバシーモード';

  @override
  String get repeater_privacyModeSubtitle => '広告に名前/場所を記載しない';

  @override
  String get repeater_advertisementSettings => '広告設定';

  @override
  String get repeater_localAdvertInterval => '地域広告掲載期間';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String get repeater_floodAdvertInterval => '洪水に関する広告の表示間隔';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 時間';
  }

  @override
  String get repeater_encryptedAdvertInterval => '暗号化された広告表示間';

  @override
  String get repeater_dangerZone => '危険区域';

  @override
  String get repeater_rebootRepeater => 'リピーターを再起動する';

  @override
  String get repeater_rebootRepeaterSubtitle => 'リピーターデバイスを再起動する';

  @override
  String get repeater_rebootRepeaterConfirm => '本当にこのリピーターを再起動したいですか？';

  @override
  String get repeater_regenerateIdentityKey => 'IDキーの再生成';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '新しい公開鍵/秘密鍵のペアを生成する';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'これにより、リピーターには新しい識別情報が割り当てられます。続行しますか？';

  @override
  String get repeater_eraseFileSystem => 'ファイルシステムを削除する';

  @override
  String get repeater_eraseFileSystemSubtitle => 'リピーターファイルシステムをフォーマットする';

  @override
  String get repeater_eraseFileSystemConfirm =>
      '警告：この操作により、リピーター内のすべてのデータが消去されます。この操作は元に戻すことができません！';

  @override
  String get repeater_eraseSerialOnly => 'Erase機能は、シリアルコンソール経由でのみ利用可能です。';

  @override
  String repeater_commandSent(String command) {
    return '送信されたコマンド: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'コマンド送信エラー：$error';
  }

  @override
  String get repeater_confirm => '確認';

  @override
  String get repeater_settingsSaved => '設定が正常に保存されました';

  @override
  String repeater_errorSavingSettings(String error) {
    return '設定の保存に失敗しました：$error';
  }

  @override
  String get repeater_refreshBasicSettings => '基本設定をリセットする';

  @override
  String get repeater_refreshRadioSettings => 'ラジオ設定をリセットする';

  @override
  String get repeater_refreshTxPower => 'TX の電力レベルをリセットする';

  @override
  String get repeater_refreshLocationSettings => '場所設定をリセットする';

  @override
  String get repeater_refreshPacketForwarding => 'パケット転送の刷新';

  @override
  String get repeater_refreshGuestAccess => 'ゲストへのアクセスをリフレッシュする';

  @override
  String get repeater_refreshPrivacyMode => 'プライバシーモードをリセットする';

  @override
  String get repeater_refreshAdvertisementSettings => '広告設定のリセット';

  @override
  String repeater_refreshed(String label) {
    return '$label が更新されました';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '$label の更新に失敗しました';
  }

  @override
  String get repeater_cliTitle => 'リピーターのコマンドラインインターフェース';

  @override
  String get repeater_debugNextCommand => '次のコマンドのデバッグ';

  @override
  String get repeater_commandHelp => 'コマンドヘルプ';

  @override
  String get repeater_clearHistory => '明確な歴史';

  @override
  String get repeater_noCommandsSent => 'まだコマンドは送信されていません';

  @override
  String get repeater_typeCommandOrUseQuick =>
      '以下のコマンドを入力するか、クイックコマンドを使用してください。';

  @override
  String get repeater_enterCommandHint => 'コマンドを入力してください...';

  @override
  String get repeater_previousCommand => '直前の指示';

  @override
  String get repeater_nextCommand => '次の指示';

  @override
  String get repeater_enterCommandFirst => 'まず、コマンドを入力してください。';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI コマンドフレーム';

  @override
  String repeater_cliCommandError(String error) {
    return 'エラー：$error';
  }

  @override
  String get repeater_cliQuickGetName => '名前を取得する';

  @override
  String get repeater_cliQuickGetRadio => 'ラジオを聴く';

  @override
  String get repeater_cliQuickGetTx => 'TXを入手する';

  @override
  String get repeater_cliQuickNeighbors => '近隣住民';

  @override
  String get repeater_cliQuickVersion => 'バージョン';

  @override
  String get repeater_cliQuickAdvertise => '広告';

  @override
  String get repeater_cliQuickClock => '時計';

  @override
  String get repeater_cliHelpAdvert => '広告用資料を送る';

  @override
  String get repeater_cliHelpReboot =>
      'デバイスを再起動します。(注：通常は「タイムアウト」が表示されますが、これは正常です)';

  @override
  String get repeater_cliHelpClock => '各デバイスの時計で現在の時刻を表示します。';

  @override
  String get repeater_cliHelpPassword => 'デバイス用の新しい管理者パスワードを設定します。';

  @override
  String get repeater_cliHelpVersion => 'デバイスのバージョンとファームウェアのビルド日を表示します。';

  @override
  String get repeater_cliHelpClearStats => 'さまざまな統計カウンターをゼロにリセットする。';

  @override
  String get repeater_cliHelpSetAf => '空き時間係数を設定します。';

  @override
  String get repeater_cliHelpSetTx => 'LoRaの送信電力をdBmで設定します。（設定変更後、再起動が必要です）';

  @override
  String get repeater_cliHelpSetRepeat => 'このノードに対するリピーターの役割を有効化または無効化します。';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '（ルームサーバー設定）「オン」に設定した場合、空白のパスワードでのログインは可能ですが、ルームへの投稿はできません。（閲覧のみ）';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'インバウンドフラッパケットの最大ホップ数を設定します（最大値を超えた場合、パケットは転送されません）。';

  @override
  String get repeater_cliHelpSetIntThresh =>
      '干渉閾値を設定します（dB単位）。デフォルト値は14です。0に設定すると、チャンネル間の干渉を検出する機能を無効にします。';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'オートゲインコントローラーのリセット間隔を設定します。 0 に設定すると無効化されます。';

  @override
  String get repeater_cliHelpSetMultiAcks => '「ダブルACK」機能の有効化または無効化を可能にします。';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'ローカル（ホップなし）の広告パケットを送信する間隔を分単位で設定します。 0 に設定すると、機能を無効にします。';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      '洪水広告の送信間隔を時間単位で設定します。0に設定すると、送信を停止します。';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'ゲストのパスワードを設定/更新します。（繰り返し利用の場合、ゲストのログインは「統計情報を取得」のリクエストを送信できます）';

  @override
  String get repeater_cliHelpSetName => '広告の名前を設定します。';

  @override
  String get repeater_cliHelpSetLat => '広告表示の地図の緯度を設定します。（度分秒表記）';

  @override
  String get repeater_cliHelpSetLon => '広告表示の地図の経度を設定します。（度数、分）';

  @override
  String get repeater_cliHelpSetRadio =>
      '完全に新しいラジオパラメータを設定し、設定として保存します。適用するには、「再起動」コマンドが必要です。';

  @override
  String get repeater_cliHelpSetRxDelay =>
      '（実験用）遅延時間を設定するためのベース（1以上の値に設定する必要）\n受信パケットに対して、信号強度/スコアに基づいてわずかな遅延を適用します。 0に設定すると無効化されます。';

  @override
  String get repeater_cliHelpSetTxDelay =>
      '時間経過に応じた「フラッシュモード」パケットの送信遅延を設定します。この遅延は、ランダムなスロットシステムと組み合わせて使用され、パケットの衝突を減らすことを目的としています。';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'txdelayと同様ですが、ダイレクトモードのパケット転送にランダムな遅延を適用する場合に使用します。';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'ブリッジを有効化/無効化';

  @override
  String get repeater_cliHelpSetBridgeDelay => 'パケットを再送信する前に、遅延を設定する。';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      '橋が受信したパケットを再送信するか、送信したパケットを再送信するかどうかを選択してください。';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'RS232 橋渡しに使用するシリアルリンクのボーレートを設定する。';

  @override
  String get repeater_cliHelpSetBridgeSecret => 'ESPNow 橋の秘密設定';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      '特定のボードでのみサポートされている、報告されるバッテリー電圧を調整するためのカスタムファクタを設定できます。';

  @override
  String get repeater_cliHelpTempRadio =>
      '指定された時間（分単位）に対して、一時的にラジオパラメータを設定し、その後元のラジオパラメータに戻します。（設定を保存しません）。';

  @override
  String get repeater_cliHelpSetPerm =>
      'ACL を変更します。「permissions」が 0 の場合、対応するエントリ（pubkey のプレフィックスで識別）を削除します。pubkey-hex が有効な長さで、かつ ACL に現在存在しない場合に、新しいエントリを追加します。pubkey のプレフィックスと一致するエントリを更新します。権限ビットはファームウェアの役割によって異なり、下位 2 ビットは以下のとおりです：0 (ゲスト)、1 (読み取り専用)、2 (読み書き)、3 (管理者)';

  @override
  String get repeater_cliHelpGetBridgeType => 'ブリッジ機能なし、RS232、ESPNow';

  @override
  String get repeater_cliHelpLogStart => 'パケットのログ記録を開始し、ファイルシステムに保存する。';

  @override
  String get repeater_cliHelpLogStop => 'ファイルシステムへのパケットログの記録を停止する。';

  @override
  String get repeater_cliHelpLogErase => 'ファイルシステムからパケットログを削除する。';

  @override
  String get repeater_cliHelpNeighbors =>
      'ゼロホップ広告を通じて受信した他のリピーターノードの一覧を表示します。各行は、IDプレフィックス（16進数）、タイムスタンプ、SNR（シグナル強度）の情報を4つ含みます。';

  @override
  String get repeater_cliHelpNeighborRemove =>
      '隣接リストから、最初に一致するエントリ（pubkeyプレフィックス（16進数）で特定）を削除します。';

  @override
  String get repeater_cliHelpRegion =>
      '（特定のシリーズのみ）定義されたすべての地域と、現在の洪水許可状況を一覧表示します。';

  @override
  String get repeater_cliHelpRegionLoad =>
      '注：これは特殊な複数コマンドの呼び出しです。その後の各コマンドは、地域名であり（スペースを使用して親階層を示し、少なくとも1つのスペースが必要です）、空行/コマンドで終了します。';

  @override
  String get repeater_cliHelpRegionGet =>
      '指定された名前のプレフィックスを持つ地域を検索します（または、グローバルな範囲の場合は「*」）。結果として、「region-name (parent-name) \'F\'」と返答します。';

  @override
  String get repeater_cliHelpRegionPut => '指定された名前で、領域の定義を追加または更新します。';

  @override
  String get repeater_cliHelpRegionRemove =>
      '指定された名前を持つ領域の定義を削除します。(正確に一致している必要があり、子領域は存在してはなりません)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      '指定された領域に対して、「洪水」アクセス許可を設定します。 (グローバル/従来のスコープには「*」を使用)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      '指定された領域における「FLOOD」権限を削除します。（注：現時点では、グローバル/従来の範囲での使用は推奨されません！）';

  @override
  String get repeater_cliHelpRegionHome =>
      '現在の「ホーム」地域に返信します。（まだ適用されていない、将来利用を予定）';

  @override
  String get repeater_cliHelpRegionHomeSet => '「ホーム」地域を設定します。';

  @override
  String get repeater_cliHelpRegionSave => '領域リスト/マップをストレージに保存する。';

  @override
  String get repeater_cliHelpGps =>
      'GPSの状態を表示します。GPSがオフの場合、「オフ」と表示します。オンの場合、「オン」、「ステータス」、「位置情報」、「衛星数」と表示します。';

  @override
  String get repeater_cliHelpGpsOnOff => 'GPS の電源状態を切り替えます。';

  @override
  String get repeater_cliHelpGpsSync => 'ノードの時刻をGPSクロックと同期する。';

  @override
  String get repeater_cliHelpGpsSetLoc => 'ノードの位置をGPS座標に設定し、設定を保存する。';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'ノードの広告設定における場所情報の指定:\n- none: 広告に場所情報を含まない\n- share: GPS位置情報を共有 (SensorManagerから取得)\n- prefs: プリファレンスに保存された場所情報を広告';

  @override
  String get repeater_cliHelpGpsAdvertSet => '場所に関する広告設定を行います。';

  @override
  String get repeater_commandsListTitle => 'コマンド一覧';

  @override
  String get repeater_commandsListNote =>
      '注：さまざまな「set ...」コマンドには、「get ...」コマンドも存在します。';

  @override
  String get repeater_general => '一般的な';

  @override
  String get repeater_settingsCategory => '設定';

  @override
  String get repeater_bridge => '橋';

  @override
  String get repeater_logging => 'ログ記録';

  @override
  String get repeater_neighborsRepeaterOnly => '近隣住民（リピーターのみ）';

  @override
  String get repeater_regionManagementRepeaterOnly => '地域管理（ブロードキャスト用のみ）';

  @override
  String get repeater_regionNote => '地域レベルでの管理のため、地域定義と権限の管理を行うための機能が導入されました。';

  @override
  String get repeater_gpsManagement => 'GPS管理';

  @override
  String get repeater_gpsNote => 'GPSコマンドは、位置情報に関連するタスクを管理するために導入されました。';

  @override
  String get telemetry_receivedData => '受信したテレメトリーデータ';

  @override
  String get telemetry_requestTimeout => 'テレメトリの要求タイムアウトしました。';

  @override
  String telemetry_errorLoading(String error) {
    return 'テレメトリの読み込みに失敗しました: $error';
  }

  @override
  String get telemetry_noData => 'テレメトリデータは利用できません。';

  @override
  String telemetry_channelTitle(int channel) {
    return 'チャンネル $channel';
  }

  @override
  String get telemetry_batteryLabel => 'バッテリー';

  @override
  String get telemetry_voltageLabel => '電圧';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU の温度';

  @override
  String get telemetry_temperatureLabel => '温度';

  @override
  String get telemetry_currentLabel => '現在';

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
    return '$celsius℃ / $fahrenheit°F';
  }

  @override
  String get neighbors_receivedData => '近隣住民のデータを受信';

  @override
  String get neighbors_requestTimedOut => '近隣住民からの要望：時間制限を設けてください。';

  @override
  String neighbors_errorLoading(String error) {
    return '近隣情報の読み込みに失敗: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => '繰り返し送信する、近隣';

  @override
  String get neighbors_noData => '近隣のデータは利用できません。';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '不明な $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return '聞いたのは、$time くらい前です';
  }

  @override
  String get channelPath_title => 'パケットパス';

  @override
  String get channelPath_viewMap => '地図を表示する';

  @override
  String get channelPath_otherObservedPaths => '観察されたその他の経路';

  @override
  String get channelPath_repeaterHops => 'ホップの繰り返し';

  @override
  String get channelPath_noHopDetails => 'このパッケージに関する詳細な情報は提供されていません。';

  @override
  String get channelPath_messageDetails => 'メッセージの詳細';

  @override
  String get channelPath_senderLabel => '送信者';

  @override
  String get channelPath_timeLabel => '時間';

  @override
  String get channelPath_repeatsLabel => '繰り返し';

  @override
  String channelPath_pathLabel(int index) {
    return '$index 番目の経路';
  }

  @override
  String get channelPath_observedLabel => '観察';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return '観察された経路 $index • $hops';
  }

  @override
  String get channelPath_noLocationData => '場所に関するデータはありません';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => '不明';

  @override
  String get channelPath_floodPath => '洪水';

  @override
  String get channelPath_directPath => '直接';

  @override
  String channelPath_observedZeroOf(int total) {
    return '$total個のホップ';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed of $total hops';
  }

  @override
  String get channelPath_mapTitle => '経路図';

  @override
  String get channelPath_noRepeaterLocations => 'この経路には、中継装置の設置場所がありません。';

  @override
  String channelPath_primaryPath(int index) {
    return '$index番目の経路（主要経路）';
  }

  @override
  String get channelPath_pathLabelTitle => '道';

  @override
  String get channelPath_observedPathHeader => '観察された経路';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable => 'このパッケージに関する詳細な配送情報は利用できません。';

  @override
  String get channelPath_unknownRepeater => '不明な増幅機';

  @override
  String get community_title => '地域';

  @override
  String get community_create => 'コミュニティを構築する';

  @override
  String get community_createDesc => '新しいコミュニティを作成し、QRコードで共有する。';

  @override
  String get community_join => '参加する';

  @override
  String get community_joinTitle => 'コミュニティに参加する';

  @override
  String community_joinConfirmation(String name) {
    return '$nameさんのようなコミュニティに参加したいですか？';
  }

  @override
  String get community_scanQr => 'コミュニティのQRコードをスキャン';

  @override
  String get community_scanInstructions => 'カメラを、地域のQRコードを向けて';

  @override
  String get community_showQr => 'QRコードを表示する';

  @override
  String get community_publicChannel => '地域住民向け';

  @override
  String get community_hashtagChannel => 'コミュニティ用ハッシュタグ';

  @override
  String get community_name => 'コミュニティ名';

  @override
  String get community_enterName => 'コミュニティ名を入力してください';

  @override
  String community_created(String name) {
    return 'コミュニティ「$name」が作成されました';
  }

  @override
  String community_joined(String name) {
    return '$name のコミュニティに参加';
  }

  @override
  String get community_qrTitle => 'コミュニティ共有';

  @override
  String community_qrInstructions(String name) {
    return 'このQRコードをスキャンして、$nameに参加してください。';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'コミュニティハッシュタグのチャンネルは、コミュニティのメンバーのみが参加できます。';

  @override
  String get community_invalidQrCode => '無効なコミュニティQRコード';

  @override
  String get community_alreadyMember => 'すでに会員である';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'あなたはすでに $name の会員です。';
  }

  @override
  String get community_addPublicChannel => 'コミュニティ用の公開チャンネルを追加';

  @override
  String get community_addPublicChannelHint => 'このコミュニティの公開チャンネルを自動的に追加する';

  @override
  String get community_noCommunities => 'まだコミュニティは形成されていません。';

  @override
  String get community_scanOrCreate => 'QRコードをスキャンするか、コミュニティを作成して開始してください。';

  @override
  String get community_manageCommunities => 'コミュニティの管理';

  @override
  String get community_delete => 'コミュニティからの離脱';

  @override
  String community_deleteConfirm(String name) {
    return '$nameを辞める？';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'これにより、$count のチャンネルとそのメッセージも削除されます。';
  }

  @override
  String community_deleted(String name) {
    return 'コミュニティ「$name」を離れる';
  }

  @override
  String get community_regenerateSecret => '秘密の復元';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '$name の秘密鍵を再生成しますか？ 継続的に通信するため、すべてのメンバーは新しいQRコードをスキャンする必要があります。';
  }

  @override
  String get community_regenerate => '再生';

  @override
  String community_secretRegenerated(String name) {
    return '$name への秘密が再設定されました';
  }

  @override
  String get community_updateSecret => '秘密情報の更新';

  @override
  String community_secretUpdated(String name) {
    return '$name 向けの秘密設定を更新';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '新しいQRコードをスキャンして、$nameの秘密情報を更新してください。';
  }

  @override
  String get community_addHashtagChannel => 'コミュニティのハッシュタグを追加';

  @override
  String get community_addHashtagChannelDesc => 'このコミュニティ用のハッシュタグチャンネルを追加する';

  @override
  String get community_selectCommunity => 'コミュニティを選択';

  @override
  String get community_regularHashtag => '定期的なハッシュタグ';

  @override
  String get community_regularHashtagDesc => '一般のハッシュタグ（誰でも参加可能）';

  @override
  String get community_communityHashtag => 'コミュニティ用ハッシュタグ';

  @override
  String get community_communityHashtagDesc => 'コミュニティメンバーのみへの限定';

  @override
  String community_forCommunity(String name) {
    return '$name 様';
  }

  @override
  String get listFilter_tooltip => 'フィルタリングと並べ替え';

  @override
  String get listFilter_sortBy => '並び替え';

  @override
  String get listFilter_latestMessages => '最新のメッセージ';

  @override
  String get listFilter_heardRecently => '最近、聞いた';

  @override
  String get listFilter_az => 'AからZ';

  @override
  String get listFilter_filters => 'フィルター';

  @override
  String get listFilter_all => 'すべて';

  @override
  String get listFilter_favorites => 'お気に入り';

  @override
  String get listFilter_addToFavorites => 'お気に入りに追加';

  @override
  String get listFilter_removeFromFavorites => 'お気に入りから削除';

  @override
  String get listFilter_users => '利用者';

  @override
  String get listFilter_repeaters => '繰り返し送信装置';

  @override
  String get listFilter_roomServers => 'ルーム用サーバー';

  @override
  String get listFilter_unreadOnly => '未読のみ';

  @override
  String get listFilter_newGroup => '新しいグループ';

  @override
  String get pathTrace_you => 'あなた';

  @override
  String get pathTrace_failed => 'パスの追跡に失敗しました。';

  @override
  String get pathTrace_notAvailable => 'パスの追跡機能は利用できません。';

  @override
  String get pathTrace_refreshTooltip => 'パスの追跡をリフレッシュする。';

  @override
  String get pathTrace_someHopsNoLocation => 'ホップの1つまたは複数について、場所が特定されていません。';

  @override
  String get pathTrace_clearTooltip => '明確な道筋。';

  @override
  String get losSelectStartEnd => 'LOS の開始ノードと終了ノードを選択してください。';

  @override
  String losRunFailed(String error) {
    return '視界確認に失敗: $error';
  }

  @override
  String get losClearAllPoints => 'すべての項目をクリア';

  @override
  String get losRunToViewElevationProfile => 'LOS（レーザー測距）を使用して、標高プロファイルを表示する';

  @override
  String get losMenuTitle => 'LOS メニュー';

  @override
  String get losMenuSubtitle => '特定の場所をタップするか、地図を長押ししてカスタムポイントを作成する。';

  @override
  String get losShowDisplayNodes => '表示ノードを表示する';

  @override
  String get losCustomPoints => 'カスタマイズ可能なポイント';

  @override
  String losCustomPointLabel(int index) {
    return 'カスタマイズ $index';
  }

  @override
  String get losPointA => 'ポイントA';

  @override
  String get losPointB => 'ポイントB';

  @override
  String losAntennaA(String value, String unit) {
    return 'アンテナ A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'アンテナ B: $value $unit';
  }

  @override
  String get losRun => 'LOS（レーティングシステム）を使用する';

  @override
  String get losNoElevationData => '標高データは含まれていません';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, clear LOS, min clearance $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blocked by $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS：確認中…';

  @override
  String get losStatusNoData => 'LOS: データの欠如';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total clear, $blocked blocked, $unknown unknown';
  }

  @override
  String get losErrorElevationUnavailable =>
      'あるサンプルまたは複数のサンプルについて、標高データが利用できません。';

  @override
  String get losErrorInvalidInput => 'LOS（レーダー）計算に必要な、無効な点/標高データ。';

  @override
  String get losRenameCustomPoint => 'カスタムポイントの名前を変更する';

  @override
  String get losPointName => '項目名';

  @override
  String get losShowPanelTooltip => 'LOSパネルを表示する';

  @override
  String get losHidePanelTooltip => 'LOSパネルを隠す';

  @override
  String get losElevationAttribution => '標高データ：Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'ラジオ・ホライゾン';

  @override
  String get losLegendLosBeam => 'LOS ビーミング';

  @override
  String get losLegendTerrain => '地形';

  @override
  String get losFrequencyLabel => '周波数';

  @override
  String get losFrequencyInfoTooltip => '計算の詳細を見る';

  @override
  String get losFrequencyDialogTitle => 'ラジオによる水平線計算';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'k=$baselineK ( $baselineFreq MHz) から開始し、現在の $frequencyMHz MHz の帯域に対して k の値を調整します。これにより、曲面状の無線通信範囲の限界が定義されます。';
  }

  @override
  String get contacts_pathTrace => '経路追跡';

  @override
  String get contacts_ping => 'パング';

  @override
  String get contacts_repeaterPathTrace => 'リピーターまでの経路を追跡する';

  @override
  String get contacts_repeaterPing => 'PING 繰り返し';

  @override
  String get contacts_roomPathTrace => '部屋のサーバーへの経路を追跡する';

  @override
  String get contacts_roomPing => 'ピンルーム用サーバー';

  @override
  String get contacts_chatTraceRoute => '経路の追跡ルート';

  @override
  String contacts_pathTraceTo(String name) {
    return '$name への経路を追跡する';
  }

  @override
  String get contacts_clipboardEmpty => 'クリップボードは空です。';

  @override
  String get contacts_invalidAdvertFormat => '無効な連絡先情報';

  @override
  String get contacts_contactImported => '連絡先が登録されました。';

  @override
  String get contacts_contactImportFailed => '連絡先のインポートに失敗しました。';

  @override
  String get contacts_zeroHopAdvert => 'ゼロホップ広告';

  @override
  String get contacts_floodAdvert => '洪水に関する広告';

  @override
  String get contacts_copyAdvertToClipboard => '広告をクリップボードにコピー';

  @override
  String get contacts_addContactFromClipboard => 'クリップボードから連絡先を追加する';

  @override
  String get contacts_ShareContact => '連絡先をクリップボードにコピー';

  @override
  String get contacts_ShareContactZeroHop => '広告を通じて連絡先を共有する';

  @override
  String get contacts_zeroHopContactAdvertSent => '広告を通じて連絡先を得た。';

  @override
  String get contacts_zeroHopContactAdvertFailed => '連絡を送信できませんでした。';

  @override
  String get contacts_contactAdvertCopied => '広告がクリップボードにコピーされました。';

  @override
  String get contacts_contactAdvertCopyFailed => '広告のコピーがクリップボードにコピーできませんでした。';

  @override
  String get notification_activityTitle => 'メッシュコアの活動';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messages',
      one: 'message',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'チャンネルメッセージ',
      one: 'チャンネルメッセージ',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいノード',
      one: '新しいノード',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return '新たに $contactType が発見されました';
  }

  @override
  String get notification_receivedNewMessage => '新しいメッセージを受信';

  @override
  String get settings_gpxExportRepeaters => 'GPX へのエクスポート用リピーター/ルームサーバー';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'GPXファイルに場所情報を付加した、レピーター/ルームサーバーのエクスポート';

  @override
  String get settings_gpxExportContacts => 'GPX 形式へのエクスポート';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'GPXファイルに位置情報を保存して、他の人と共有する。';

  @override
  String get settings_gpxExportAll => 'すべての連絡先をGPX形式でエクスポートする';

  @override
  String get settings_gpxExportAllSubtitle =>
      'すべての連絡先を、場所情報付きのGPXファイルにエクスポートする。';

  @override
  String get settings_gpxExportSuccess => 'GPXファイルの正常なエクスポートが完了しました。';

  @override
  String get settings_gpxExportNoContacts => 'エクスポートする連絡先は存在しません。';

  @override
  String get settings_gpxExportNotAvailable => 'このデバイス/OSではサポートされていません';

  @override
  String get settings_gpxExportError => 'エクスポート時にエラーが発生しました。';

  @override
  String get settings_gpxExportRepeatersRoom => '中継装置およびルームサーバーの設置場所';

  @override
  String get settings_gpxExportChat => '関連施設';

  @override
  String get settings_gpxExportAllContacts => 'すべての連絡先場所';

  @override
  String get settings_gpxExportShareText => 'meshcore-openからエクスポートされた地図データ';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open GPX形式の地図データのエクスポート';

  @override
  String get snrIndicator_nearByRepeaters => '近くの電波中継局';

  @override
  String get snrIndicator_lastSeen => '最後に確認された場所';

  @override
  String get contactsSettings_title => '連絡先設定';

  @override
  String get contactsSettings_autoAddTitle => '自動検出';

  @override
  String get contactsSettings_otherTitle => 'その他の連絡に関する設定';

  @override
  String get contactsSettings_autoAddUsersTitle => '自動でユーザーを追加する';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      '利用者が自動的に発見したユーザーを追加できるようにする。';

  @override
  String get contactsSettings_autoAddRepeatersTitle => '自動で繰り返し設定';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      '発見した中継局を、自動的に追加できるようにする。';

  @override
  String get contactsSettings_autoAddRoomServersTitle => '自動でルームサーバーを追加';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      '利用者が、発見した部屋のサーバーを自動的に追加できるようにする。';

  @override
  String get contactsSettings_autoAddSensorsTitle => '自動でセンサーを追加';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      '利用者が、発見したセンサーを自動的に追加できるようにする。';

  @override
  String get contactsSettings_overwriteOldestTitle => '最も古いものを上書きする';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      '連絡先リストが満杯になった場合、最も古いかつ「お気に入り」ではない連絡先が削除されます。';

  @override
  String get discoveredContacts_Title => '連絡先が見つかった';

  @override
  String get discoveredContacts_noMatching => '一致する連絡先が見つかりませんでした';

  @override
  String get discoveredContacts_searchHint => '発見された連絡先を検索する';

  @override
  String get discoveredContacts_contactAdded => '連絡先を追加';

  @override
  String get discoveredContacts_addContact => '連絡先を追加';

  @override
  String get discoveredContacts_copyContact => '連絡先をクリップボードにコピー';

  @override
  String get discoveredContacts_deleteContact => '発見された連絡先を削除';

  @override
  String get discoveredContacts_deleteContactAll => '発見されたすべての連絡先を削除';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      '本当に、見つけたすべての連絡先を削除してもよろしいですか？';

  @override
  String get chat_sendCooldown => '再度送信する前に、しばらくお待ちください。';

  @override
  String get appSettings_jumpToOldestUnread => '最も古い未読のメッセージへ移動';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      '未読メッセージがあるチャットを開く際、「最新のメッセージ」ではなく、最初に未読のメッセージまでスクロールしてください。';

  @override
  String get appSettings_languageHu => 'ハンガリー語';

  @override
  String get appSettings_languageJa => '日本語';

  @override
  String get appSettings_languageKo => '韓国語';

  @override
  String get radioStats_tooltip => 'ラジオおよびメッシュに関する統計';

  @override
  String get radioStats_screenTitle => 'ラジオの統計';

  @override
  String get radioStats_notConnected => 'ラジオの統計情報を表示するために、デバイスに接続してください。';

  @override
  String get radioStats_firmwareTooOld =>
      'ラジオの統計機能を使用するには、v8またはそれ以降のファームウェアが必要です。';

  @override
  String get radioStats_waiting => 'データ待ち…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'ノイズレベル: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return '最後のRSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return '最終SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX 放送時間（合計）：$seconds 秒';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX 放送時間（合計）：$seconds 秒';
  }

  @override
  String get radioStats_chartCaption => '最近のサンプルのノイズレベル（dBm）。';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'ノイズレベル: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'ラジオの統計情報を取得中…';

  @override
  String get radioStats_settingsTile => 'ラジオの統計';

  @override
  String get radioStats_settingsSubtitle => 'ノイズレベル、RSSI、SNR、および通信時間';

  @override
  String get scanner_linuxPairingShowPin => 'PINを表示';

  @override
  String get scanner_linuxPairingHidePin => 'PINを非表示';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth ペアリング PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return '$deviceNameのPINを入力してください（なしの場合は空欄のまま）。';
  }
}
