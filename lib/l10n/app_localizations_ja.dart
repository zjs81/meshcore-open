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
  String get common_ok => 'OK';

  @override
  String get common_connect => '接続';

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
  String get common_done => '完了';

  @override
  String get common_edit => '編集';

  @override
  String get common_add => '追加';

  @override
  String get common_settings => '設定';

  @override
  String get common_disconnect => '切断';

  @override
  String get common_connected => '接続済み';

  @override
  String get common_disconnected => '切断済み';

  @override
  String get common_create => '作成';

  @override
  String get common_continue => '続行';

  @override
  String get common_share => '共有';

  @override
  String get common_copy => 'コピー';

  @override
  String get common_retry => '再試行';

  @override
  String get common_hide => '隠す';

  @override
  String get common_remove => '削除';

  @override
  String get common_enable => '有効にする';

  @override
  String get common_disable => '無効にする';

  @override
  String get common_undo => '元に戻す';

  @override
  String get messageStatus_sent => '送信';

  @override
  String get messageStatus_delivered => '配達';

  @override
  String get messageStatus_pending => '送信';

  @override
  String get messageStatus_failed => '送信できませんでした';

  @override
  String get messageStatus_repeated => '何度も聞いた';

  @override
  String get urlImage_enable => 'Enable URL images';

  @override
  String get urlImage_possible => 'Possible URL image; enable it in Settings.';

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
  String get common_autoRefresh => '自動更新';

  @override
  String get common_interval => '間隔';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP で接続';

  @override
  String get tcpHostLabel => '接続先';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => 'ポート';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => '接続先を入力して接続してください';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return '$endpoint への接続中...';
  }

  @override
  String get tcpErrorHostRequired => '接続先は必須です。';

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
  String get usbScreenSubtitle => '検出されたシリアルデバイスを選択して、MeshCore ノードに直接接続します。';

  @override
  String get usbScreenStatus => 'USB デバイスを選択してください';

  @override
  String get usbScreenNote =>
      'USB シリアルは、対応する Android デバイスとデスクトップ プラットフォームで利用できます。';

  @override
  String get usbScreenEmptyState => 'USB デバイスが見つかりません。接続してから再度更新してください。';

  @override
  String get usbErrorPermissionDenied => 'USBへのアクセス許可が拒否されました。';

  @override
  String get usbErrorDeviceMissing => '選択されたUSBデバイスは、もう利用できません。';

  @override
  String get usbErrorInvalidPort => '有効なUSBデバイスを選択してください。';

  @override
  String get usbErrorBusy => '別の USB 接続要求がすでに進行中です。';

  @override
  String get usbErrorNotConnected => 'USBデバイスは接続されていません。';

  @override
  String get usbErrorOpenFailed => '選択したUSBデバイスを開くことができません。';

  @override
  String get usbErrorConnectFailed => '選択したUSBデバイスへの接続に失敗しました。';

  @override
  String get usbErrorUnsupported => 'このプラットフォームでは、USBシリアル通信はサポートされていません。';

  @override
  String get usbErrorAlreadyActive => 'USB 接続はすでにアクティブです。';

  @override
  String get usbErrorNoDeviceSelected => 'USBデバイスは選択されていません。';

  @override
  String get usbErrorPortClosed => 'USB 接続は開かれていません。';

  @override
  String get usbErrorConnectTimedOut =>
      '接続がタイムアウトしました。デバイスにUSBコンパニオンファームウェアがインストールされていることを確認してください。';

  @override
  String get usbFallbackDeviceName => 'ウェブシリアルデバイス';

  @override
  String get usbStatus_notConnected => 'USB デバイスを選択してください';

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
    return '$deviceName に接続済み';
  }

  @override
  String get scanner_searchingDevices => 'MeshCore デバイスを検索中...';

  @override
  String get scanner_tapToScan => 'MeshCore デバイスを見つけるには、「スキャン」をタップしてください。';

  @override
  String scanner_connectionFailed(String error) {
    return '接続に失敗しました：$error';
  }

  @override
  String get scanner_stop => '停止';

  @override
  String get scanner_scan => 'スキャン';

  @override
  String get scanner_bluetoothOff => 'Bluetooth はオフです';

  @override
  String get scanner_bluetoothOffMessage => 'Bluetooth を有効にしてデバイスを検索してください。';

  @override
  String get scanner_chromeRequired => 'Chrome ブラウザが必須です';

  @override
  String get scanner_chromeRequiredMessage =>
      'このWebアプリケーションは、Bluetooth機能を利用するために、Google ChromeまたはChromiumベースのブラウザが必要です。';

  @override
  String get scanner_enableBluetooth => 'Bluetooth を有効にする';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'ブラウザでは Bluetooth は利用できません。代わりに USB で接続してください。';

  @override
  String get device_quickSwitch => 'クイックスイッチ';

  @override
  String get device_meshcore => 'MeshCore';

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
  String get settings_nodeNameUpdated => '名前を更新しました';

  @override
  String get settings_radioSettings => 'ラジオ設定';

  @override
  String get settings_radioSettingsSubtitle => '周波数、電力、スプレッドファクター';

  @override
  String get settings_radioSettingsUpdated => 'ラジオの設定が更新されました';

  @override
  String get settings_regionSettings => '地域';

  @override
  String get settings_regionSettingsSubtitle => '保存された領域の管理';

  @override
  String get settings_regionManagement_screenTitle => '地域管理';

  @override
  String get settings_regionNameHint => '地域名を入力してください';

  @override
  String get settings_regionAddRegion => '地域を追加';

  @override
  String get settings_regionFetchRegions => 'リピーターからのフェッチ地域';

  @override
  String get settings_regionFetchRegionsFail => '地域は見つかりませんでした';

  @override
  String get settings_regionFetchRegionsAlreadyExists => 'この地域はすでに追加されています。';

  @override
  String get settings_regionName => '地域名';

  @override
  String get settings_regionDeleted => '地域が削除されました';

  @override
  String get settings_deleteRegion => '地域を削除';

  @override
  String settings_deleteRegionConfirm(String region) {
    return '$region を地域リストから削除しますか？';
  }

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
  String get settings_locationGPSEnable => 'GPS を有効にする';

  @override
  String get settings_locationGPSEnableSubtitle => 'GPS が自動的に位置情報を更新できるようにします。';

  @override
  String get settings_locationIntervalSec => 'GPS 更新間隔（秒）';

  @override
  String get settings_locationIntervalInvalid =>
      '間隔は少なくとも60秒で、86400秒未満でなければなりません。';

  @override
  String get settings_latitude => '緯度';

  @override
  String get settings_longitude => '経度';

  @override
  String get settings_contactSettings => '連絡先設定';

  @override
  String get settings_contactSettingsSubtitle => '連絡先の追加方法に関する設定';

  @override
  String get settings_privacyMode => 'プライバシーモード';

  @override
  String get settings_privacyModeSubtitle => '広告に名前や位置を表示しない';

  @override
  String get settings_privacyModeToggle =>
      'プライバシーモードを有効にすると、広告に表示される名前と位置を非表示にします。';

  @override
  String get settings_privacyModeEnabled => 'プライバシーモードが有効になっています';

  @override
  String get settings_privacyModeDisabled => 'プライバシーモードは無効です';

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
  String get settings_autoZeroHopAdvertOnGpsUpdate => 'GPS更新時にゼロホップ広告を自動送信';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'GPS位置が変化したときにゼロホップ広告を送信します（広告への位置情報の含有が必要）。';

  @override
  String get settings_multiAck => 'マルチ ACK';

  @override
  String get settings_telemetryModeUpdated => 'テレメトリモードが更新されました';

  @override
  String get settings_actions => '操作';

  @override
  String get settings_deleteAllPaths => 'すべての経路を削除';

  @override
  String get settings_deleteAllPathsSubtitle => '連絡先からすべての経路データを消去します。';

  @override
  String get settings_sendAdvertisement => '広告を送信';

  @override
  String get settings_sendAdvertisementSubtitle => '現在の存在を送信します';

  @override
  String get settings_advertisementSent => '広告を送信しました';

  @override
  String get settings_syncTime => '時刻を同期';

  @override
  String get settings_syncTimeSubtitle => 'デバイスの時刻をスマートフォンに合わせます';

  @override
  String get settings_timeSynchronized => '時刻を同期しました';

  @override
  String get settings_refreshContacts => '連絡先を更新';

  @override
  String get settings_refreshContactsSubtitle => 'デバイスから連絡先リストを再読み込みします';

  @override
  String get settings_rebootDevice => 'デバイスを再起動';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore デバイスを再起動します';

  @override
  String get settings_rebootDeviceConfirm =>
      '本当にデバイスを再起動したいですか？ その場合、接続が切断されます。';

  @override
  String get settings_debug => 'デバッグ';

  @override
  String get settings_companionDebugLog => '同伴デバッグログ';

  @override
  String get settings_companionDebugLogSubtitle =>
      'BLE/TCP/USB 関連のコマンド、応答、および生のデータ';

  @override
  String get settings_appDebugLog => 'アプリのデバッグログ';

  @override
  String get settings_appDebugLogSubtitle => 'アプリケーションのデバッグメッセージ';

  @override
  String get settings_about => '概要';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore オープンソースプロジェクト';

  @override
  String get settings_aboutDescription =>
      'MeshCore LoRa メッシュネットワークデバイス向けのオープンソース Flutter クライアント。';

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
  String get settings_infoHardware => 'ハードウェア';

  @override
  String get settings_infoFirmware => 'ファームウェア';

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
  String get settings_clientRepeat => 'オフグリッド中継';

  @override
  String get settings_clientRepeatSubtitle =>
      'このデバイスが他のデバイス向けにメッシュパケットを中継できるようにします。';

  @override
  String get settings_clientRepeatFreqWarning =>
      'オフグリッド中継には 433、869、または 918 MHz の周波数が必要です。';

  @override
  String settings_error(String message) {
    return 'エラー: $message';
  }

  @override
  String get appSettings_title => 'アプリ設定';

  @override
  String get appSettings_appearance => '外観';

  @override
  String get appSettings_theme => 'テーマ';

  @override
  String get appSettings_themeSystem => 'システム設定';

  @override
  String get appSettings_themeLight => 'ライト';

  @override
  String get appSettings_themeDark => 'ダーク';

  @override
  String get appSettings_language => '言語';

  @override
  String get appSettings_languageSystem => 'システム設定';

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
  String get repeater_pathHashModeOption0 => '0 - 1バイト';

  @override
  String get repeater_pathHashModeOption1 => '1〜2バイト';

  @override
  String get repeater_pathHashModeOption2 => '2〜3バイト';

  @override
  String get repeater_pathHashModeOption3 => '3〜4バイト';

  @override
  String get appSettings_enableMessageTracing => 'メッセージ追跡を有効にする';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'メッセージの詳細な経路とタイミングのメタデータを表示します';

  @override
  String get appSettings_notifications => '通知';

  @override
  String get appSettings_enableNotifications => '通知を有効にする';

  @override
  String get appSettings_enableNotificationsSubtitle => 'メッセージや広告の通知を受け取ります';

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
  String get appSettings_clearPathOnMaxRetry => '最大再試行時に経路を消去';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      '5 回送信に失敗したら連絡先の経路をリセットします';

  @override
  String get appSettings_pathsWillBeCleared => '5 回失敗すると経路を消去します';

  @override
  String get appSettings_pathsWillNotBeCleared => '経路は自動では消去されません';

  @override
  String get appSettings_autoRouteRotation => '自動経路切り替え';

  @override
  String get appSettings_autoRouteRotationSubtitle => '最適な経路とフラッドモードを切り替えます';

  @override
  String get appSettings_autoRouteRotationEnabled => '自動経路切り替えが有効です';

  @override
  String get appSettings_autoRouteRotationDisabled => '自動経路切り替えは無効です';

  @override
  String get appSettings_maxRouteWeight => '最大経路重み';

  @override
  String get appSettings_maxRouteWeightSubtitle => '成功配送によって経路に蓄積できる最大重み';

  @override
  String get appSettings_initialRouteWeight => '初期経路重み';

  @override
  String get appSettings_initialRouteWeightSubtitle => '新しく発見された経路の初期重み';

  @override
  String get appSettings_routeWeightSuccessIncrement => '成功時の重み増加';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      '成功配送後に経路へ加算する重み';

  @override
  String get appSettings_routeWeightFailureDecrement => '失敗時の重み減少';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      '失敗配送後に経路から差し引く重み';

  @override
  String get appSettings_maxMessageRetries => '最大メッセージ再試行回数';

  @override
  String get appSettings_maxMessageRetriesSubtitle => 'メッセージを失敗として扱うまでの再試行回数';

  @override
  String get appSettings_battery => 'バッテリー';

  @override
  String get appSettings_batteryChemistry => 'バッテリー種別';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '$deviceName ごとに設定';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst => '選択するにはデバイスに接続してください';

  @override
  String get appSettings_batteryNmc => '18650型 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_batteryLipoHv => 'リポバッテリー HV（3.0〜4.35V）';

  @override
  String get appSettings_mapDisplay => '地図表示';

  @override
  String get appSettings_showRepeaters => 'リピータを表示';

  @override
  String get appSettings_showRepeatersSubtitle => '地図上にリピータノードを表示する';

  @override
  String get appSettings_showChatNodes => 'チャットノードを表示';

  @override
  String get appSettings_showChatNodesSubtitle => '地図上にチャットノードを表示する';

  @override
  String get appSettings_showOtherNodes => 'その他のノードを表示';

  @override
  String get appSettings_showOtherNodesSubtitle => '地図上に、他のノードの種類を表示する';

  @override
  String get appSettings_timeFilter => '時間フィルター';

  @override
  String get appSettings_timeFilterShowAll => 'すべてのノードを表示';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '過去 $hours 時間以内に発見されたノードを表示';
  }

  @override
  String get appSettings_mapTimeFilter => '地図の時間フィルター';

  @override
  String get appSettings_showNodesDiscoveredWithin => '次の期間内に発見されたノードを表示:';

  @override
  String get appSettings_allTime => '全期間';

  @override
  String get appSettings_lastHour => '過去1時間';

  @override
  String get appSettings_last6Hours => '過去6時間';

  @override
  String get appSettings_last24Hours => '過去24時間';

  @override
  String get appSettings_lastWeek => '過去1週間';

  @override
  String get appSettings_rasterTileSource => 'ラスタタイルのソース';

  @override
  String get appSettings_stadiaEndpoint => 'Stadia エンドポイント';

  @override
  String get appSettings_stadiaApiKey => 'Stadia API キー';

  @override
  String get appSettings_stadiaApiKeyRequired => 'Stadia Maps の利用に必要です';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return '設定済み: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Stadia Maps の API キーを入力してください。このアプリはラスタタイルの取得に使用します。';

  @override
  String get appSettings_offlineMapCache => 'オフライン地図キャッシュ';

  @override
  String get appSettings_unitsTitle => '単位';

  @override
  String get appSettings_unitsMetric => 'メートル法 (m / km)';

  @override
  String get appSettings_unitsImperial => 'ヤード・ポンド法 (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'エリアが選択されていません';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'エリア選択中（ズーム $minZoom-$maxZoom）';
  }

  @override
  String get appSettings_debugCard => 'デバッグ';

  @override
  String get appSettings_appDebugLogging => 'アプリのデバッグログ';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'トラブルシューティング用にアプリのデバッグメッセージを記録します';

  @override
  String get appSettings_appDebugLoggingEnabled => 'アプリのデバッグログは有効です';

  @override
  String get appSettings_appDebugLoggingDisabled => 'アプリのデバッグログは無効です';

  @override
  String get contacts_title => '連絡先';

  @override
  String get contacts_noContacts => 'まだ連絡先はありません';

  @override
  String get contacts_contactsWillAppear => 'デバイスが広告を送信すると連絡先が表示されます';

  @override
  String get contacts_unread => '未読';

  @override
  String get contacts_searchContactsNoNumber => '連絡先を検索...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '連絡先を検索... $number 件の $str';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'お気に入りを検索... $number 件の $str';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'ユーザーを検索... $number 件の $str';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'リピータを検索... $number 件の $str';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'ルームサーバーを検索... $number 件の $str';
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
  String get contacts_manageRepeater => 'リピータの管理';

  @override
  String get contacts_manageRoom => 'ルームサーバーを管理';

  @override
  String get contacts_roomLogin => 'ルームサーバーログイン';

  @override
  String get contacts_openChat => 'チャットを開く';

  @override
  String get contacts_editGroup => 'グループを編集';

  @override
  String get contacts_deleteGroup => 'グループを削除';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '$groupName を削除しますか？';
  }

  @override
  String get contacts_newGroup => '新しいグループ';

  @override
  String get contacts_moreOptions => 'さらに多くの選択肢';

  @override
  String get contacts_searchOpen => '連絡先を検索する';

  @override
  String get contacts_searchClose => '検索を終了';

  @override
  String get contacts_groupName => 'グループ名';

  @override
  String get contacts_groupNameRequired => 'グループ名が必須です';

  @override
  String get contacts_groupNameReserved => 'このグループ名は予約済みです';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'グループ「$name」はすでに存在します';
  }

  @override
  String get contacts_filterContacts => '連絡先をフィルタ...';

  @override
  String get contacts_noContactsMatchFilter => '条件に一致する連絡先はありません';

  @override
  String get contacts_noMembers => 'メンバーなし';

  @override
  String get contacts_lastSeenNow => '最近';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '約 $minutes 分前';
  }

  @override
  String get contacts_lastSeenHourAgo => '約 1 時間前';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '約 $hours 時間前';
  }

  @override
  String get contacts_lastSeenDayAgo => '約 1 日前';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '約 $days 日前';
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
  String get channels_addPublicChannel => '公開チャンネルを追加';

  @override
  String get channels_searchChannels => 'チャンネルを検索...';

  @override
  String get channels_noChannelsFound => 'チャンネルが見つかりませんでした';

  @override
  String channels_channelIndex(int index) {
    return 'チャンネル $index';
  }

  @override
  String get channels_public => '公開';

  @override
  String channels_via(String path) {
    return '経由: $path';
  }

  @override
  String get channels_private => '非公開';

  @override
  String get channels_editChannel => 'チャンネルを編集';

  @override
  String get channels_muteChannel => 'チャンネルをミュート';

  @override
  String get channels_unmuteChannel => 'チャンネルのミュートを解除';

  @override
  String get channels_deleteChannel => 'チャンネルを削除';

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
  String get channels_standardPublicPsk => '公開用の標準 PSK';

  @override
  String get channels_pskHex => 'PSK（16 進数）';

  @override
  String get channels_generateRandomPsk => 'ランダムな PSK を生成';

  @override
  String get channels_enterChannelName => 'チャンネル名を入力してください';

  @override
  String get channels_pskMustBe32Hex => 'PSKは32桁の16進数で構成されている必要があります。';

  @override
  String channels_channelAdded(String name) {
    return 'チャンネル「$name」を追加しました';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'チャンネル $index の編集';
  }

  @override
  String get channels_smazCompression => 'SMAZ 圧縮';

  @override
  String get channels_cyr2latCompression => 'Cyr2Lat 圧縮';

  @override
  String get channels_cyr2latCompressionDscr => '送信時に一部のキリル文字をラテン文字に置き換えます。';

  @override
  String get channels_cyr2latSettingsHeading => 'Cyr2Lat 設定';

  @override
  String get channels_cyr2latSettingsSubheading => '置換リスト';

  @override
  String get channels_cyr2latSettingsDscr => '文字置換の JSON 設定を編集します';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON 置換マップ';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return '無効な JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'チャンネル「$name」が更新されました';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Cyr2Lat プロファイルを追加';

  @override
  String get settings_cyr2latProfileName => 'プロファイル名';

  @override
  String get settings_cyr2latProfileNameEmpty => 'プロファイル名は空にできません';

  @override
  String get settings_cyr2latProfileAdded => 'プロファイルを追加しました';

  @override
  String get settings_cyr2latProfileUpdated => 'プロファイルを更新しました';

  @override
  String get settings_cyr2latProfileEdit => 'Cyr2Lat プロファイルを編集';

  @override
  String get settings_cyr2latProfileDelete => 'Cyr2Lat プロファイルを削除';

  @override
  String get settings_cyr2latProfileDeleted => 'プロファイルを削除しました';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'プロファイル「$name」を削除しますか？';
  }

  @override
  String get channels_publicChannelAdded => '公開チャンネルを追加しました';

  @override
  String get channels_sortBy => '並び替え';

  @override
  String get channels_sortManual => '手動';

  @override
  String get channels_sortAZ => 'AからZ';

  @override
  String get channels_sortLatestMessages => '最新のメッセージ';

  @override
  String get channels_sortUnread => '未読';

  @override
  String get channels_createPrivateChannel => 'プライベートチャンネルを作成する';

  @override
  String get channels_createPrivateChannelDesc => '秘密鍵で保護されます。';

  @override
  String get channels_joinPrivateChannel => 'プライベートチャンネルに参加する';

  @override
  String get channels_joinPrivateChannelDesc => '秘密鍵を手動で入力します。';

  @override
  String get channels_joinPublicChannel => '公開チャンネルに参加する';

  @override
  String get channels_joinPublicChannelDesc => '誰でもこのチャンネルに参加できます。';

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
  String channels_regionSetTo(String region) {
    return '地域：$region';
  }

  @override
  String get channels_regionNotSet => '地域：なし';

  @override
  String get channels_regionSelect_Title => '地域を選択する';

  @override
  String get channels_clearRegion => 'クリアな地域';

  @override
  String get chat_noMessages => 'まだメッセージは届いていません';

  @override
  String get chat_sendMessage => 'メッセージを送信する';

  @override
  String chat_sendMessageTo(String contactName) {
    return '$contactName へのメッセージを送信する';
  }

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
  String get chat_typeMessage => 'メッセージを入力してください…';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'メッセージが長すぎます（$maxBytes バイトを超えています）';
  }

  @override
  String get chat_messageCopied => 'メッセージがコピーされました';

  @override
  String get chat_messageDeleted => 'メッセージは削除されました';

  @override
  String get chat_retryingMessage => 'メッセージを再試行中';

  @override
  String chat_retryCount(int current, int max) {
    return '$current/$max 回目';
  }

  @override
  String get chat_sendGif => 'GIF を送信';

  @override
  String get chat_sendImage => '画像を送信';

  @override
  String get chat_imagePickFailed => 'その画像を開けませんでした';

  @override
  String get chat_receivedGif => 'GIFを受け取りました';

  @override
  String get chat_reply => '返信';

  @override
  String get chat_addReaction => 'リアクションを追加';

  @override
  String get chat_me => '私';

  @override
  String get emojiCategorySmileys => '顔文字';

  @override
  String get emojiCategoryGestures => 'ジェスチャー';

  @override
  String get emojiCategoryHearts => 'ハート';

  @override
  String get emojiCategoryObjects => '物';

  @override
  String get gifPicker_title => 'GIF を選択';

  @override
  String get gifPicker_searchHint => 'GIF を検索...';

  @override
  String get gifPicker_poweredBy => 'GIPHY 提供';

  @override
  String get gifPicker_noGifsFound => 'GIF が見つかりませんでした';

  @override
  String get gifPicker_failedLoad => 'GIF の読み込みに失敗しました';

  @override
  String get gifPicker_failedSearch => 'GIF の検索に失敗しました';

  @override
  String get gifPicker_noInternet => 'インターネット接続がありません';

  @override
  String get debugLog_appTitle => 'アプリのデバッグログ';

  @override
  String get debugLog_bleTitle => 'BLE デバッグログ';

  @override
  String get debugLog_copyLog => 'ログをコピー';

  @override
  String get debugLog_clearLog => 'ログをクリア';

  @override
  String get debugLog_copied => 'デバッグログをコピーしました';

  @override
  String get debugLog_bleCopied => 'BLE ログをコピーしました';

  @override
  String get debugLog_noEntries => 'まだデバッグログはありません';

  @override
  String get debugLog_enableInSettings => '設定でアプリのデバッグログを有効にしてください';

  @override
  String get debugLog_frames => 'フレーム';

  @override
  String get debugLog_rawLogRx => '生の Log-RX';

  @override
  String get debugLog_noBleActivity => 'まだ BLE アクティビティはありません';

  @override
  String debugFrame_length(int count) {
    return 'フレーム長: $count バイト';
  }

  @override
  String debugFrame_command(String value) {
    return 'コマンド: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'テキストメッセージフレーム:';

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
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'プレーン';

  @override
  String debugFrame_text(String text) {
    return '- テキスト: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => '16 進ダンプ:';

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
  String get chat_removePath => '経路を削除';

  @override
  String get chat_noPathHistoryYet => 'まだ経路履歴はありません。\n経路を見つけるにはメッセージを送信してください。';

  @override
  String get chat_pathCleared => '経路をクリアしました。次のメッセージで再探索します。';

  @override
  String get chat_fullPath => '完全な経路';

  @override
  String get routing_title => '経路設定';

  @override
  String get routing_modeAuto => '自動';

  @override
  String get routing_modeFlood => 'フラッド';

  @override
  String get routing_modeManual => '手動';

  @override
  String get routing_modeAutoHint => '既知の最良経路を自動で選び、経路がないときはフラッドします。';

  @override
  String get routing_modeFloodHint =>
      'すべてのリピータを通じてブロードキャストします。最も信頼性は高いですが、空中時間を多く使います。';

  @override
  String get routing_modeManualHint => '常に、設定した正確な経路を使います。';

  @override
  String get routing_currentRoute => '現在の経路';

  @override
  String get routing_directNoHops => '直接 - 中継ホップなし';

  @override
  String get routing_noPathYet => 'まだ経路はありません。次のメッセージは経路が見つかるまでフラッドされます。';

  @override
  String get routing_floodBroadcast => 'すべてのリピータにブロードキャスト';

  @override
  String get routing_editPath => '経路を編集';

  @override
  String get routing_forgetPath => '経路を忘れる';

  @override
  String get routing_knownPaths => '既知の経路';

  @override
  String get routing_knownPathsHint => '経路をタップして切り替えます。';

  @override
  String get routing_inUse => '使用中';

  @override
  String get routing_qualityStrong => '強い最初のホップ';

  @override
  String get routing_qualityGood => '良好な最初のホップ';

  @override
  String get routing_qualityFair => 'まずまずの最初のホップ';

  @override
  String get routing_qualityWorked => '配信済み';

  @override
  String get routing_qualityFlood => 'フラッドで受信';

  @override
  String get routing_qualityUntested => '未検証';

  @override
  String routing_lastWorked(String when) {
    return '$when に確認';
  }

  @override
  String get routing_neverWorked => '未確認';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes 件配信済み、$failures 件失敗';
  }

  @override
  String get routing_floodDelivery => 'フラッド配送';

  @override
  String get pathEditor_title => '経路を作成';

  @override
  String pathEditor_hopCounter(int count) {
    return '64 ホップ中 $count';
  }

  @override
  String get pathEditor_noHops =>
      'まだホップはありません。下のリピータをタップして順番に追加するか、ホップなしで保存して直接送信します。';

  @override
  String get pathEditor_addHops => '順番にホップを追加';

  @override
  String get pathEditor_searchRepeaters => 'リピータを検索';

  @override
  String get pathEditor_advancedHex => '詳細: 生の 16 進経路';

  @override
  String get pathEditor_hexLabel => '16 進接頭辞';

  @override
  String get pathEditor_hexHelper => 'ホップごとに 16 進数 2 文字をカンマ区切りで入力します';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return '無効: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => '最大 64 ホップ';

  @override
  String get pathEditor_usePath => 'この経路を使用';

  @override
  String get pathEditor_removeHop => 'ホップを削除';

  @override
  String get pathEditor_unknownHop => '不明なリピータ';

  @override
  String get chat_pathSavedLocally => 'ローカルに保存しました。同期するには接続してください。';

  @override
  String get chat_pathDeviceConfirmed => 'デバイスで確認済み';

  @override
  String get chat_pathDeviceNotConfirmed => 'デバイスではまだ確認されていません';

  @override
  String get chat_type => '種類';

  @override
  String get chat_path => '道';

  @override
  String get chat_publicKey => '公開鍵';

  @override
  String get chat_compressOutgoingMessages => '送信メッセージを圧縮する';

  @override
  String get chat_floodForced => 'フラッド（強制）';

  @override
  String get chat_directForced => 'ダイレクト（強制）';

  @override
  String chat_hopsForced(int count) {
    return '$count ホップ（強制）';
  }

  @override
  String get chat_floodAuto => 'フラッド (自動)';

  @override
  String get chat_direct => '直接';

  @override
  String get chat_poiShared => '共有された POI';

  @override
  String chat_unread(int count) {
    return '未読: $count';
  }

  @override
  String get chat_markAsUnread => '未読としてマークする';

  @override
  String get chat_newMessages => '新しいメッセージ';

  @override
  String get chat_openLink => 'リンクを開きますか？';

  @override
  String get chat_openLinkConfirmation => 'このリンクをブラウザで開きますか？';

  @override
  String get chat_open => '開く';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'リンクを開けませんでした: $url';
  }

  @override
  String get chat_invalidLink => '無効なリンク形式';

  @override
  String get map_title => 'ノードマップ';

  @override
  String get map_searchHint => 'ノード名またはIDで検索';

  @override
  String get map_activity => 'アクティビティ';

  @override
  String get map_online => 'オンライン';

  @override
  String get map_recent => '最近';

  @override
  String get map_stale => '古い';

  @override
  String get map_visible => '表示中';

  @override
  String get map_hidden => '非表示';

  @override
  String get map_centerOnNode => 'ノードを中央に表示';

  @override
  String get map_details => '詳細';

  @override
  String get map_noGps => 'GPS なし';

  @override
  String get map_noResults => '一致するノードなし';

  @override
  String get map_lineOfSight => '見通し';

  @override
  String get map_losScreenTitle => '見通し';

  @override
  String get map_noNodesWithLocation => '位置情報を持つノードはありません';

  @override
  String get map_nodesNeedGps => 'ノードを地図に表示するには GPS 座標の共有が必要です';

  @override
  String map_nodesCount(int count) {
    return 'ノード: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'ピン: $count';
  }

  @override
  String get map_chat => 'チャット';

  @override
  String get map_repeater => 'リピータ';

  @override
  String get map_room => '部屋';

  @override
  String get map_sensor => 'センサー';

  @override
  String get map_pinDm => 'ピン（DM）';

  @override
  String get map_pinPrivate => 'ピン（非公開）';

  @override
  String get map_pinPublic => 'ピン（公開）';

  @override
  String get map_lastSeen => '最後に確認';

  @override
  String get map_disconnectConfirm => '本当にこのデバイスとの接続を解除したいですか？';

  @override
  String get map_from => '送信元';

  @override
  String get map_source => '出典';

  @override
  String get map_flags => 'フラグ';

  @override
  String get map_type => '種類';

  @override
  String get map_path => '経路';

  @override
  String get map_location => '位置';

  @override
  String get map_estLocation => '推定位置';

  @override
  String get map_publicKey => '公開鍵';

  @override
  String get map_publicKeyPrefixHint => 'e.g. ab12';

  @override
  String get map_shareMarkerHere => 'ここにマーカーを共有';

  @override
  String get map_setAsMyLocation => '現在地として設定';

  @override
  String get map_pinLabel => 'ピンラベル';

  @override
  String get map_label => 'ラベル';

  @override
  String get map_pointOfInterest => '興味地点';

  @override
  String get map_sendToContact => '連絡先へ送信';

  @override
  String get map_sendToChannel => 'チャンネルへ送信';

  @override
  String get map_noChannelsAvailable => '利用可能なチャンネルはありません';

  @override
  String get map_publicLocationShare => '公開位置情報の共有';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '$channelLabel で位置情報を共有しようとしています。このチャンネルは公開されており、PSK を持つ誰でも閲覧できます。';
  }

  @override
  String get map_connectToShareMarkers => 'マーカーを共有するにはデバイスに接続してください';

  @override
  String get map_filterNodes => 'ノードを絞り込む';

  @override
  String get map_nodeTypes => 'ノードの種類';

  @override
  String get map_chatNodes => 'チャットノード';

  @override
  String get map_repeaters => 'リピータ';

  @override
  String get map_otherNodes => 'その他のノード';

  @override
  String get map_showOverlaps => 'リピータキーの重複';

  @override
  String get map_keyPrefix => 'キー接頭辞';

  @override
  String get map_filterByKeyPrefix => 'キー接頭辞で絞り込む';

  @override
  String get map_publicKeyPrefix => '公開鍵のプレフィックス';

  @override
  String get map_markers => 'マーカー';

  @override
  String get map_showSharedMarkers => '共有のマーカーを表示する';

  @override
  String get map_showGuessedLocations => '推測されたノードの位置を表示する';

  @override
  String get map_showDiscoveryContacts => 'Discovery 連絡先を表示';

  @override
  String get map_guessedLocation => '推測された場所';

  @override
  String get map_lastSeenTime => '最後に確認された時間';

  @override
  String get map_sharedPin => '共有ピン';

  @override
  String get map_sharedAt => '共有済み';

  @override
  String get map_joinRoom => '部屋に参加する';

  @override
  String get map_manageRepeater => 'リピータの管理';

  @override
  String get map_tapToAdd => 'ノードをタップして経路に追加します。';

  @override
  String get map_runTrace => '経路トレースを実行';

  @override
  String get map_runTraceWithReturnPath => '元の経路に戻る。';

  @override
  String get map_removeLast => '最後を削除';

  @override
  String get map_pathTraceCancelled => '経路トレースはキャンセルされました';

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
    return '$count 枚のタイルをキャッシュしました';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return '$downloaded 枚をキャッシュ済み（$failed 件失敗）';
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
    return 'ダウンロード済み $completed / $total';
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
      '設定やステータスにアクセスするために、リピータのパスワードを入力してください。';

  @override
  String get login_roomDescription => '設定やステータスへのアクセスには、部屋のパスワードを入力してください。';

  @override
  String get login_routing => '経路設定';

  @override
  String get login_routingMode => 'ルーティングモード';

  @override
  String get login_autoUseSavedPath => '自動 (保存されたパスを使用)';

  @override
  String get login_forceFloodMode => '強制的にフラッドモードを起動';

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
  String get common_clear => 'クリア';

  @override
  String get path_currentPathLabel => '現在の経路';

  @override
  String get path_noRepeatersFound => '繰り返し機能やルームサーバーは見つかりませんでした。';

  @override
  String get repeater_management => 'リピータ管理';

  @override
  String get room_management => 'ルームサーバーの管理';

  @override
  String get repeater_guest => 'リピータに関する情報';

  @override
  String get room_guest => 'ルームサーバーに関する情報';

  @override
  String get repeater_managementTools => '管理ツール';

  @override
  String get repeater_guestTools => 'ゲスト向けツール';

  @override
  String get repeater_status => 'ステータス';

  @override
  String get repeater_statusSubtitle => 'リピータの状態、統計情報、および隣接するネットワークの情報を表示する';

  @override
  String get repeater_telemetry => 'テレメトリー';

  @override
  String get repeater_telemetrySubtitle => 'センサーおよびシステムの状態に関するテレメトリの表示';

  @override
  String get repeater_cli => 'CLI（コマンドラインインターフェース）';

  @override
  String get repeater_cliSubtitle => 'リピータへのコマンドを送信する';

  @override
  String get repeater_neighbors => '近隣住民';

  @override
  String get repeater_neighborsSubtitle => 'ゼロホップの隣接ノードを表示する。';

  @override
  String get repeater_settings => '設定';

  @override
  String get repeater_settingsSubtitle => 'リピータのパラメータを設定する';

  @override
  String get repeater_clockSyncAfterLogin => 'ログイン後に時刻を同期';

  @override
  String get repeater_clockSyncAfterLoginSubtitle => 'ログイン成功時に自動で時刻同期を送信します';

  @override
  String get repeater_statusTitle => '再送ステータス';

  @override
  String get repeater_routingMode => 'ルーティングモード';

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
  String get repeater_uptime => '稼働時間';

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
  String get repeater_txAirtime => 'TX 送信時間';

  @override
  String get repeater_rxAirtime => 'RX 受信時間';

  @override
  String get repeater_chanUtil => 'チャンネルの利用状況';

  @override
  String get repeater_packetStatistics => 'パケット統計';

  @override
  String get repeater_sent => '送信済み';

  @override
  String get repeater_received => '受信済み';

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
    return '合計: $total, フラッド: $flood, 直接: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '合計: $total, フラッド: $flood, 直接: $direct';
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
  String get repeater_settingsTitle => 'リピータ設定';

  @override
  String get repeater_basicSettings => '基本設定';

  @override
  String get repeater_repeaterName => 'リピータ名';

  @override
  String get repeater_repeaterNameHelper => 'このリピータの名前';

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
  String get repeater_packetForwardingSubtitle => 'リピータがパケットを転送できるように設定する';

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
  String get repeater_floodAdvertInterval => 'フラッドに関する広告の表示間隔';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 時間';
  }

  @override
  String get repeater_encryptedAdvertInterval => '暗号化された広告表示間';

  @override
  String get repeater_dangerZone => '危険区域';

  @override
  String get repeater_rebootRepeater => 'リピータを再起動する';

  @override
  String get repeater_rebootRepeaterSubtitle => 'リピータデバイスを再起動する';

  @override
  String get repeater_rebootRepeaterConfirm => '本当にこのリピータを再起動したいですか？';

  @override
  String get repeater_regenerateIdentityKey => 'IDキーの再生成';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '新しい公開鍵/秘密鍵のペアを生成する';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'これにより、リピータには新しい識別情報が割り当てられます。続行しますか？';

  @override
  String get repeater_eraseFileSystem => 'ファイルシステムを削除する';

  @override
  String get repeater_eraseFileSystemSubtitle => 'リピータファイルシステムをフォーマットする';

  @override
  String get repeater_eraseFileSystemConfirm =>
      '警告：この操作により、リピータ内のすべてのデータが消去されます。この操作は元に戻すことができません！';

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
  String get repeater_rxGain => 'RX ゲインの向上';

  @override
  String get repeater_rxGainHelper => 'より高い感度、より大きな電流（SX1262/SX1268のみ）';

  @override
  String get repeater_refreshRxGain => '強化されたRX効果を再確認';

  @override
  String get repeater_multiAcks => '複数のACK（応答）';

  @override
  String get repeater_multiAcksSubtitle => '複数の経路でメッセージを送信することで、より確実な配信を実現する。';

  @override
  String get repeater_refreshMultiAcks => '複数のACKをリフレッシュする';

  @override
  String get repeater_networkHealth => 'ネットワークの状態';

  @override
  String get repeater_loopDetect => 'ループ検出';

  @override
  String get repeater_loopDetectHelper => 'ルーティングループを検知する';

  @override
  String get repeater_loopDetectOff => 'オフ';

  @override
  String get repeater_loopDetectMinimal => '最小限の';

  @override
  String get repeater_loopDetectModerate => '適度な';

  @override
  String get repeater_loopDetectStrict => '厳格な';

  @override
  String get repeater_dutyCycle => '動作サイクル';

  @override
  String get repeater_dutyCycleHelper => '最大の使用時間割合';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => '事業者の情報';

  @override
  String get repeater_ownerInfoHelper => 'このリピータに関する公開メタデータ';

  @override
  String get repeater_refreshOwnerInfo => 'オペレーター情報の更新';

  @override
  String get repeater_floodMax => '最大ホップ数';

  @override
  String get repeater_floodMaxHelper => 'フラッドパケットが移動できる最大ホップ数 (0-64)';

  @override
  String get repeater_advancedSettings => '高度な';

  @override
  String get repeater_advancedSettingsSubtitle => '経験豊富なオペレーター向けの調整ノブ';

  @override
  String get repeater_pathHashMode => 'パスハッシュモード';

  @override
  String get repeater_pathHashModeHelper =>
      'このリピータのIDをフローパス/ループ検出タグにエンコードするために使用されるバイト数。 0=1バイト (256個のID、最大64ホップ)、1=2バイト (65,000個のID、最大32ホップ)、2=3バイト (160万個のID、最大21ホップ)。 v1.13およびそれ以前のファームウェアでは、マルチバイトパスがサポートされていません。 v1.14以降のバージョンでは、一度ネットワークが起動されると、パスが一度だけ検出されます。';

  @override
  String get repeater_keySettings => 'アイデンティティキーの変更';

  @override
  String get repeater_keySettingsSubtitle => '公開鍵/秘密鍵を変更する';

  @override
  String get repeater_prvKey => 'プライベートキー';

  @override
  String get repeater_prvKeyHelper => 'リピーター用の新しいプライベートキー。128文字の16進文字列です。';

  @override
  String get repeater_generatePrvKey => 'ランダムな鍵ペアを生成する';

  @override
  String get repeater_stopGeneratingPrvKey => 'キーペアの検索を中断';

  @override
  String get repeater_pubKey => '公開鍵';

  @override
  String get repeater_pubKeyHelper => 'これは生成された秘密鍵に対応する公開鍵です。直接設定することはできません。';

  @override
  String get repeater_pubKeyPrefix => '希望する接頭辞';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'これらの16進数で始まる公開鍵を見つけてください。予想される試行回数: $tries。';
  }

  @override
  String get repeater_txDelay => 'フロイド・TXでの遅延';

  @override
  String get repeater_txDelayHelper =>
      'フラッド時の交通量に対応するための再送信間隔を、パケットの通信時間を掛けた値（0～2、デフォルト0.5）で設定します。値を大きくすると衝突が減りますが、通信速度が遅くなります。';

  @override
  String get repeater_directTxDelay => '直接的なTX遅延';

  @override
  String get repeater_directTxDelayHelper =>
      '直接（フラッドではない）トラフィックに対する再送信間隔を、パケットの空中時間（0～2、デフォルト0.3）の倍数として設定する。';

  @override
  String get repeater_intThresh => '干渉閾値';

  @override
  String get repeater_intThreshHelper =>
      'ラジオのノイズレベルを基準とする閾値を設定し、このレベルを超えるノイズを抑制します。 0 を設定すると、ノイズの多い帯域で RX エラーが発生した場合のみ、この値を上げることができます。';

  @override
  String get repeater_agcResetInterval => 'AGCのリセット間隔';

  @override
  String get repeater_agcResetIntervalHelper =>
      'ラジオの自動ゲイン制御をリセットする頻度について：ゲインが固定状態になった場合に、回復するために、何度リセットするかを設定します。4の倍数でリセットする場合、0を設定すると、定期的なリセットは停止します。';

  @override
  String get repeater_actionsTitle => '操作';

  @override
  String get repeater_sendAdvert => 'フラッド広告を送信';

  @override
  String get repeater_sendAdvertSubtitle => 'ネットワーク全体にフラッド広告をブロードキャストします';

  @override
  String get repeater_sendAdvertZeroHop => 'ゼロホップ広告を送信';

  @override
  String get repeater_sendAdvertZeroHopSubtitle => '1 ホップ広告を送信します（リピータなし）';

  @override
  String get repeater_clockSync => '時刻を同期';

  @override
  String get repeater_clockSyncSubtitle => 'スマートフォンの時刻をデバイスに設定します';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action が成功しました';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action の実行に失敗しました: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      '設定を保存しました — リピータを再起動して適用してください';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return '設定の一部でエラーが発生しました：$failures';
  }

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
  String get repeater_refreshPacketForwarding => 'パケット転送の刷新';

  @override
  String get repeater_refreshGuestAccess => 'ゲストへのアクセスをリフレッシュする';

  @override
  String get repeater_refreshPrivacyMode => 'プライバシーモードをリセットする';

  @override
  String repeater_refreshed(String label) {
    return '$label が更新されました';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '$label の更新に失敗しました';
  }

  @override
  String get repeater_cliTitle => 'リピータ CLI';

  @override
  String get repeater_debugNextCommand => '次のコマンドのデバッグ';

  @override
  String get repeater_commandHelp => 'コマンドヘルプ';

  @override
  String get repeater_clearHistory => '履歴をクリア';

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
  String get repeater_cliQuickGetTx => 'TX を取得';

  @override
  String get repeater_cliQuickNeighbors => '近隣';

  @override
  String get repeater_cliQuickVersion => 'バージョン';

  @override
  String get repeater_cliQuickAdvertise => '広告送信';

  @override
  String get repeater_cliQuickClock => '時刻';

  @override
  String get repeater_cliQuickClockSync => '時刻同期';

  @override
  String get repeater_cliQuickDiscovery => '近隣を発見する';

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
  String get repeater_cliHelpSetRepeat => 'このノードに対するリピータの役割を有効化または無効化します。';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '（ルームサーバー設定）「オン」に設定した場合、空白のパスワードでのログインは可能ですが、ルームへの投稿はできません。（閲覧のみ）';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'インバウンドフラッドパケットの最大ホップ数を設定します（最大値を超えた場合、パケットは転送されません）。';

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
      'フラッド広告の送信間隔を時間単位で設定します。0に設定すると、送信を停止します。';

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
      'ゼロホップ広告を通じて受信した他のリピータノードの一覧を表示します。各行は、IDプレフィックス（16進数）、タイムスタンプ、SNR（シグナル強度）の情報を4つ含みます。';

  @override
  String get repeater_cliHelpNeighborRemove =>
      '隣接リストから、最初に一致するエントリ（pubkeyプレフィックス（16進数）で特定）を削除します。';

  @override
  String get repeater_cliHelpRegion =>
      '（特定のシリーズのみ）定義されたすべての地域と、現在のフラッド許可状況を一覧表示します。';

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
      '指定された領域に対して、「フラッド」アクセス許可を設定します。 (グローバル/従来のスコープには「*」を使用)';

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
  String get repeater_neighborsRepeaterOnly => '近隣住民（リピータのみ）';

  @override
  String get repeater_regionManagementRepeaterOnly => '地域管理（ブロードキャスト用のみ）';

  @override
  String get repeater_regionNote => '地域レベルでの管理のため、地域定義と権限の管理を行うための機能が導入されました。';

  @override
  String get repeater_gpsManagement => 'GPS管理';

  @override
  String get repeater_gpsNote => 'GPSコマンドは、位置情報に関連するタスクを管理するために導入されました。';

  @override
  String get repeater_getCategory => '価値を取得する';

  @override
  String get repeater_powerMgmt => '電力管理';

  @override
  String get repeater_sensors => 'センサー';

  @override
  String get repeater_cliHelpPowerOff => 'デバイスをシャットダウンします。（応答は期待されていません）';

  @override
  String get repeater_cliHelpClkReboot => '時計を既知の基準時点にリセットし、デバイスを再起動します。';

  @override
  String get repeater_cliHelpAdvertZeroHop => '近隣のデバイスのみに、ゼロホップの広告を送信します。';

  @override
  String get repeater_cliHelpStartOta =>
      'サポートされているボードに対して、無線でファームウェアのアップデートを開始します。';

  @override
  String get repeater_cliHelpTime =>
      'デバイスのクロックを、指定されたUnixエポックの秒数に設定します。クロックは逆方向に進むことはできません。';

  @override
  String get repeater_cliHelpBoard => '製造元の名前/ハードウェア識別子を表示します。';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      '近隣のノードに対して、ノードの探索リクエストを送信します。（リピータ機能のみ）';

  @override
  String get repeater_cliHelpPowersaving => '省電力モードがオンになっているかどうかを表示します。';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      '省電力モード（対応している場合）を有効または無効にします。';

  @override
  String get repeater_cliHelpErase =>
      '（シリアルモードのみ）デバイスのファイルシステムをフォーマットします。すべての設定と連絡先を消去します。';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      '送信可能な最大デューティサイクルをパーセントで設定します（1〜100）。内部で、空き時間の要素を調整します。';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '（シリアル番号のみ）デバイスのプライベートキーを置き換えます。適用には再起動が必要です。新しいパブリックキーを生成します。';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '（SX126xのみ）高電流での使用時に、感度を向上させるために、増幅されたRXのゲインを切り替えることができます。';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      '広告に記載されている所有者連絡先情報を設定します。改行には\'|\'を使用してください。';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'パスハッシュモードを設定します。 0 = 従来のモード、1 = 標準モード、2 = 厳格モード。ルーティングパスのマッチング方法に影響します。';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'ルーティングループ検出の感度を設定します：オフ、最小、中程度、または厳格。';

  @override
  String get repeater_cliHelpSetFreq =>
      '（シリアル設定のみ）特定の周波数のみを素早く設定できます。再起動が必要です。「ラジオ設定」を使用すると、ラジオのすべてのパラメータを設定できます。';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '（ESPNowブリッジのみ）ブリッジで使用するWi-Fiチャンネル（1～14）を設定します。';

  @override
  String get repeater_cliHelpGetName => '設定されたノードの名前を表示します。';

  @override
  String get repeater_cliHelpGetRole => 'ファームウェアの役割（リピータ、ルームサーバーなど）を表示します。';

  @override
  String get repeater_cliHelpGetPublicKey => 'デバイスの公開鍵を表示します。';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '（シリアル番号のみ）デバイスのプライベートキーを表示します。機密情報として扱ってください。';

  @override
  String get repeater_cliHelpGetRepeat => 'パケット転送（リピータ機能）が有効になっているかどうかを表示します。';

  @override
  String get repeater_cliHelpGetTx => '現在のTX（送信）電力のdBm値を表示します。';

  @override
  String get repeater_cliHelpGetFreq => '設定された無線周波数をMHzで表示します。';

  @override
  String get repeater_cliHelpGetRadio =>
      '以下のすべての無線パラメータを表示: 周波数、帯域幅、スプレッドファクター、符号化レート。';

  @override
  String get repeater_cliHelpGetRadioRxGain => '(SX126xのみ) RX の増幅ゲインの状態を表示します。';

  @override
  String get repeater_cliHelpGetAf => '現在の空き時間係数を表示します。';

  @override
  String get repeater_cliHelpGetDutyCycle => '現在の許可されたデューティサイクルをパーセントで表示します。';

  @override
  String get repeater_cliHelpGetIntThresh => 'チャンネル干渉の閾値をdBで表示します。';

  @override
  String get repeater_cliHelpGetAgcResetInterval => 'AGCのリセット間隔を秒単位で表示します。';

  @override
  String get repeater_cliHelpGetMultiAcks => 'ダブルACKモードが有効 (1) か無効 (0) かを示す。';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'ゲストによる読み取り専用アクセスが許可されているかどうかを示す。';

  @override
  String get repeater_cliHelpGetAdvertInterval => 'ローカル広告の時間を分単位で表示します。';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'フラッドに関する広告の放送時間を時間単位で表示します。';

  @override
  String get repeater_cliHelpGetGuestPassword => '設定されたゲストパスワードを表示します。';

  @override
  String get repeater_cliHelpGetLat => '設定された緯度を表示します。';

  @override
  String get repeater_cliHelpGetLon => '設定された経度を表示します。';

  @override
  String get repeater_cliHelpGetRxDelay => 'rxdelay の基本値を表示します。';

  @override
  String get repeater_cliHelpGetTxDelay => 'フラッドモードにおける送信遅延の要因を示します。';

  @override
  String get repeater_cliHelpGetDirectTxDelay => 'ダイレクトモードの遅延要素を示します。';

  @override
  String get repeater_cliHelpGetFloodMax => 'フラッドパケットの最大ホップ数を表示します。';

  @override
  String get repeater_cliHelpGetOwnerInfo => '所有者の連絡先情報を表示します。';

  @override
  String get repeater_cliHelpGetPathHashMode => 'パスハッシュモード（0/1/2）を表示します。';

  @override
  String get repeater_cliHelpGetLoopDetect => 'ループ検出の感度を示す。';

  @override
  String get repeater_cliHelpGetAcl => '（シリアルのみ）リピータ上のアクセス制御設定を一覧表示します。';

  @override
  String get repeater_cliHelpGetBridgeEnabled => '橋が有効になっているかどうかを表示します。';

  @override
  String get repeater_cliHelpGetBridgeDelay => '橋の遅延時間をミリ秒（ms）で表示します。';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'RX または TX パケットを橋渡ししているかどうかを示す。';

  @override
  String get repeater_cliHelpGetBridgeBaud => '（RS232 橋渡し機能のみ）橋渡しのボーレートを表示します。';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '（ESPNowブリッジのみ）ブリッジで使用しているWi-Fiチャンネルを表示します。';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '（ESPNowブリッジのみ）ブリッジで共有されている秘密鍵を表示します。';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '（NRF52のみ）ブートローダーのバージョンを表示します。';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'ADC（アナログ-デジタル変換）のマルチプライヤー（バッテリー電圧のスケーリング）を表示します。';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      '取締役会が電力管理機能をサポートしているかどうかを報告します。';

  @override
  String get repeater_cliHelpGetPwrMgtSource => '現在の電源（外部電源またはバッテリー）を表示します。';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      '最新のリセットおよびシャットダウンの理由を表示します。';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv => '起動時のバッテリー電圧をmVで表示します。';

  @override
  String get repeater_cliHelpSensorGet => 'キーを使用して、カスタムセンサーの設定を読み取る。';

  @override
  String get repeater_cliHelpSensorSet => 'カスタムセンサーの設定を作成する。';

  @override
  String get repeater_cliHelpSensorList =>
      'カスタムセンサーの設定をすべてリスト表示し、オプションで指定できる開始インデックスからページ分割して表示します。';

  @override
  String get repeater_cliHelpRegionDefault => '現在のデフォルトの地域範囲を表示します。';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'デフォルトの地域範囲を設定します。「<null>」を使用すると、設定をリセットできます。';

  @override
  String get repeater_cliHelpRegionListAllowed => 'フラッド時の通行が許可されている地域の一覧';

  @override
  String get repeater_cliHelpRegionListDenied => 'フラッドによる交通を遮断している地域の一覧';

  @override
  String get repeater_cliHelpStatsPackets => '（シリアルのみ）パケットレベルの統計情報を表示します。';

  @override
  String get repeater_cliHelpStatsRadio => '（シリーズのみ）ラジオの統計情報を表示します。';

  @override
  String get repeater_cliHelpStatsCore => '（シリアルのみ）主要なファームウェアの統計情報を表示します。';

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
  String get telemetry_digitalInputLabel => 'デジタル入力';

  @override
  String get telemetry_digitalOutputLabel => 'デジタル出力';

  @override
  String get telemetry_analogInputLabel => 'アナログ入力';

  @override
  String get telemetry_analogOutputLabel => 'アナログ出力';

  @override
  String get telemetry_genericLabel => '汎用センサー';

  @override
  String get telemetry_luminosityLabel => '照度';

  @override
  String get telemetry_presenceLabel => '在室';

  @override
  String get telemetry_humidityLabel => '湿度';

  @override
  String get telemetry_accelerometerLabel => '加速度計';

  @override
  String get telemetry_pressureLabel => '気圧';

  @override
  String get telemetry_altitudeLabel => '高度';

  @override
  String get telemetry_frequencyLabel => '周波数';

  @override
  String get telemetry_percentageLabel => 'パーセント';

  @override
  String get telemetry_concentrationLabel => '濃度';

  @override
  String get telemetry_powerLabel => '電力';

  @override
  String get telemetry_distanceLabel => '距離';

  @override
  String get telemetry_energyLabel => 'エネルギー';

  @override
  String get telemetry_directionLabel => '方向';

  @override
  String get telemetry_timeLabel => '時刻';

  @override
  String get telemetry_gyrometerLabel => 'ジャイロメーター';

  @override
  String get telemetry_colourLabel => '色';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'スイッチ';

  @override
  String get telemetry_polylineLabel => 'ポリライン';

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
  String get telemetry_autoFetchQuantity => 'リクエスト数';

  @override
  String get telemetry_error => 'データを取得できません';

  @override
  String get neighbors_receivedData => '近隣住民のデータを受信';

  @override
  String get neighbors_requestTimedOut => '近隣住民からの要望：時間制限を設けてください。';

  @override
  String neighbors_errorLoading(String error) {
    return '近隣情報の読み込みに失敗: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => '近隣のリピータ';

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
  String get channelPath_repeaterHops => 'リピータホップ';

  @override
  String get channelPath_noHopDetails => 'このパッケージに関する詳細な情報は提供されていません。';

  @override
  String get channelPath_messageDetails => 'メッセージの詳細';

  @override
  String get channelPath_senderLabel => '送信者';

  @override
  String get channelPath_timeLabel => '時間';

  @override
  String get channelPath_repeatsLabel => 'リピータ';

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
  String get channelPath_floodPath => 'フラッド';

  @override
  String get channelPath_directPath => '直接';

  @override
  String channelPath_observedZeroOf(int total) {
    return '$total個のホップ';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed/$total ホップ';
  }

  @override
  String get channelPath_mapTitle => '経路図';

  @override
  String get channelPath_noRepeaterLocations => 'この経路にリピータの位置情報はありません。';

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
  String get community_title => 'コミュニティ';

  @override
  String get community_create => 'コミュニティを作成';

  @override
  String get community_createDesc => '新しいコミュニティを作成して QR コードで共有します。';

  @override
  String get community_join => '参加';

  @override
  String get community_joinTitle => 'コミュニティに参加';

  @override
  String community_joinConfirmation(String name) {
    return '$name のコミュニティに参加しますか？';
  }

  @override
  String get community_scanQr => 'コミュニティの QR コードをスキャン';

  @override
  String get community_scanInstructions => 'カメラをコミュニティの QR コードに向けてください';

  @override
  String get community_showQr => 'QR コードを表示';

  @override
  String get community_publicChannel => '公開チャンネル';

  @override
  String get community_hashtagChannel => 'コミュニティ用ハッシュタグ';

  @override
  String get community_name => 'コミュニティ名';

  @override
  String get community_enterName => 'コミュニティ名を入力してください';

  @override
  String community_created(String name) {
    return 'コミュニティ「$name」を作成しました';
  }

  @override
  String community_joined(String name) {
    return '$name のコミュニティに参加しました';
  }

  @override
  String get community_qrTitle => 'コミュニティ共有';

  @override
  String community_qrInstructions(String name) {
    return 'この QR コードをスキャンして $name に参加してください。';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'コミュニティのハッシュタグチャンネルには、コミュニティのメンバーだけが参加できます。';

  @override
  String get community_invalidQrCode => '無効なコミュニティQRコード';

  @override
  String get community_alreadyMember => 'すでにメンバーです';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'あなたはすでに $name のメンバーです。';
  }

  @override
  String get community_addPublicChannel => '公開チャンネルを追加';

  @override
  String get community_addPublicChannelHint => 'このコミュニティの公開チャンネルを自動で追加します';

  @override
  String get community_noCommunities => 'まだコミュニティはありません';

  @override
  String get community_scanOrCreate => 'QR コードをスキャンするか、コミュニティを作成して始めてください。';

  @override
  String get community_manageCommunities => 'コミュニティを管理';

  @override
  String get community_delete => 'コミュニティを離脱';

  @override
  String community_deleteConfirm(String name) {
    return '$name から離脱しますか？';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'これにより、$count のチャンネルとそのメッセージも削除されます。';
  }

  @override
  String community_deleted(String name) {
    return 'コミュニティ「$name」から離脱しました';
  }

  @override
  String get community_regenerateSecret => '秘密鍵を再生成';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '$name の秘密鍵を再生成しますか？ 継続して通信するには、すべてのメンバーが新しい QR コードをスキャンする必要があります。';
  }

  @override
  String get community_regenerate => '再生成';

  @override
  String community_secretRegenerated(String name) {
    return '$name の秘密鍵を再生成しました';
  }

  @override
  String get community_updateSecret => '秘密鍵を更新';

  @override
  String community_secretUpdated(String name) {
    return '$name の秘密設定を更新しました';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '新しい QR コードをスキャンして $name の秘密設定を更新してください。';
  }

  @override
  String get community_addHashtagChannel => 'ハッシュタグチャンネルを追加';

  @override
  String get community_addHashtagChannelDesc => 'このコミュニティ用のハッシュタグチャンネルを追加します';

  @override
  String get community_selectCommunity => 'コミュニティを選択';

  @override
  String get community_regularHashtag => '通常のハッシュタグ';

  @override
  String get community_regularHashtagDesc => '公開ハッシュタグ（誰でも参加可能）';

  @override
  String get community_communityHashtag => 'コミュニティ用ハッシュタグ';

  @override
  String get community_communityHashtagDesc => 'コミュニティメンバーのみ利用できます';

  @override
  String community_forCommunity(String name) {
    return '$name 向け';
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
  String get listFilter_repeaters => 'リピータ';

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
  String get losBlockedSpotsTitle => '利用できない場所';

  @override
  String get losBlockedSpotsHint => '地図上で、特定された場所を強調するために、該当する場所をタップしてください。';

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
  String get losSelectedObstructionTitle => '選択された障害';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return '$obstruction によって $heightUnit の高さで、A地点から $distanceFromA、B地点から $distanceFromB ($distanceUnit) の距離で塞がれています。';
  }

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
  String get contacts_repeaterPathTrace => 'リピータまでの経路を追跡する';

  @override
  String get contacts_repeaterPing => 'リピータにPING';

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
  String get contacts_floodAdvert => 'フラッドに関する広告';

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
  String get settings_gpxExportRepeaters => 'GPX へのエクスポート用リピータ/ルームサーバー';

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
  String get settings_gpxExportRepeatersRoom => 'リピータ/ルームサーバーの位置情報';

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
  String get snrIndicator_nearByRepeaters => '近くのリピータ';

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
  String get contactsSettings_autoAddRepeatersTitle => 'リピータを自動追加';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      '発見したリピータを、自動的に追加できるようにする。';

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
  String get translation_title => '翻訳';

  @override
  String get imageMessages_enableTitle => '画像メッセージを有効にする';

  @override
  String get imageMessages_enableSubtitle =>
      'メッシュ経由で画像を送信してください。画像モデルを一度限りのダウンロードが必要です。';

  @override
  String get imageMessages_modelSectionTitle => '画像モデル';

  @override
  String get imageMessages_downloadModel => 'ダウンロード';

  @override
  String get imageMessages_cancelDownload => 'キャンセル';

  @override
  String get imageMessages_removeModel => 'モデルを削除';

  @override
  String get imageMessages_modelReady => '準備完了';

  @override
  String get imageMessages_modelNotPublished =>
      'まだ公開されていません — このビルドではダウンロードできません。';

  @override
  String get imageMessages_downloadFailed => '画像モデルがダウンロードできませんでした。';

  @override
  String get imageMessages_autoProcessTitle => '画像を自動的に処理する';

  @override
  String get imageMessages_autoProcessSubtitle =>
      '画像が届き次第、すぐに再構築してください。1回あたり約2GBのメモリを使用します。タップで再構築を解除できます。';

  @override
  String get translation_enableTitle => '翻訳機能を有効にする';

  @override
  String get translation_enableSubtitle => '受信メッセージを翻訳し、送信前に翻訳を適用できるようにする。';

  @override
  String get translation_composerTitle => '送信する前に翻訳する';

  @override
  String get translation_composerSubtitle => '作曲家翻訳アイコンのデフォルト状態を制御する。';

  @override
  String get translation_autoIncomingTitle => 'メッセージを自動翻訳';

  @override
  String get translation_autoIncomingSubtitle =>
      '通知やチャット、チャンネルのメッセージを自動的に翻訳します。';

  @override
  String get translation_translateMessage => 'メッセージを翻訳';

  @override
  String get translation_targetLanguage => '翻訳対象言語';

  @override
  String get translation_useAppLanguage => 'アプリの言語設定';

  @override
  String get translation_downloadedModelLabel => 'ダウンロードしたモデル';

  @override
  String get translation_presetModelLabel => 'あらかじめ設定されたHugging Faceモデル';

  @override
  String get translation_manualUrlLabel => 'マニュアルモデルのURL';

  @override
  String get translation_downloadModel => 'モデルのダウンロード';

  @override
  String get translation_downloading => 'ダウンロード中...';

  @override
  String get translation_working => '業務中…';

  @override
  String get translation_stop => '停止';

  @override
  String get translation_mergingChunks => 'ダウンロードしたファイルを最終ファイルに結合中...';

  @override
  String get translation_downloadedModels => 'ダウンロードされたモデル';

  @override
  String get translation_deleteModel => 'モデルを削除';

  @override
  String get translation_modelDownloaded => '翻訳モデルのダウンロードが完了しました。';

  @override
  String get translation_downloadStopped => 'ダウンロードが中断されました。';

  @override
  String translation_downloadFailed(String error) {
    return 'ダウンロードに失敗しました：$error';
  }

  @override
  String get translation_enterUrlFirst => 'まず、モデルのURLを入力してください。';

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

  @override
  String get translation_messageTranslation => 'メッセージの翻訳';

  @override
  String get translation_translateBeforeSending => '送信する前に翻訳する';

  @override
  String get translation_composerEnabledHint => 'メッセージは送信前に翻訳されます。';

  @override
  String get translation_composerDisabledHint => '元のタイプされた言語でメッセージを送信してください。';

  @override
  String translation_translateTo(String language) {
    return '$language への翻訳';
  }

  @override
  String get translation_translationOptions => '翻訳の選択肢';

  @override
  String get translation_systemLanguage => 'システム言語';

  @override
  String get background_serviceTitle => 'MeshCore 実行中';

  @override
  String get background_serviceText => 'BLE 接続を維持しています';

  @override
  String appSettings_translationModelDeleted(String name) {
    return '$name を削除しました';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'チャンネルの更新に失敗しました: $error';
  }

  @override
  String get contact_typeChat => 'チャット';

  @override
  String get contact_typeRepeater => 'リピータ';

  @override
  String get contact_typeRoom => 'ルーム';

  @override
  String get contact_typeSensor => 'センサー';

  @override
  String get contact_typeUnknown => '不明';

  @override
  String get map_zoomIn => 'ズームイン';

  @override
  String get map_zoomOut => 'ズームアウト';

  @override
  String get map_centerMap => '地図を中央に移動';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth には Chromium ベースのブラウザが必要です。';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id…';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPSによる確認';

  @override
  String get pathTrace_legendInferred => '推測される位置';

  @override
  String get pathMap_viewSingle => '単独表示';

  @override
  String get pathMap_viewCombined => '統合表示';

  @override
  String get pathMap_play => '再生';

  @override
  String get pathMap_pause => '一時停止';

  @override
  String get pathMap_replay => 'リプレイ';

  @override
  String get pathMap_stepBack => '前のホップ';

  @override
  String get pathMap_stepForward => '次のホップ';

  @override
  String get pathMap_animationOn => 'パケットアニメーションを表示';

  @override
  String get pathMap_animationOff => 'パケットアニメーションを非表示';

  @override
  String pathMap_hopOf(int current, int total) {
    return '$current/$total ホップ目';
  }

  @override
  String pathMap_observedPaths(int count) {
    return '観測された経路: $count';
  }

  @override
  String get pathMap_primary => '主要';

  @override
  String pathMap_alternate(int index) {
    return '代替 $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ホップ',
      one: '1 ホップ',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => '共有セグメント';

  @override
  String get pathMap_legendEstimated => '概算のセグメント';

  @override
  String pathMap_sharedNodeCount(int count) {
    return '$count 経路で使用されています';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count つのホップに位置情報がありません - 表示中の経路は一部です',
      one: '1 つのホップに位置情報がありません - 表示中の経路は一部です',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'すべて表示';

  @override
  String get pathMap_hidePath => '経路を非表示';

  @override
  String get pathMap_showPath => '経路を表示';

  @override
  String get pathMap_collapsePanel => 'パネルを折りたたむ';

  @override
  String get pathMap_expandPanel => 'パネルを展開';

  @override
  String get pathMap_noLocation => '位置情報なし';

  @override
  String get pathMap_followPacket => 'パケットを追跡';

  @override
  String get pathMap_unfollowPacket => 'パケットの追跡を解除';

  @override
  String get imageSend_title => '画像を送信';

  @override
  String get imageSend_cropNote => '512 × 512にリサイズされました。アスペクト比は保持されませんでした。';

  @override
  String get imageSend_originalSize =>
      '原文：\nThe early morning light filtered through the curtains, casting a soft glow on the room.\n\n翻訳：\n早朝の光がカーテンをすり抜け、部屋に柔らかな光を投げかけていた。';

  @override
  String get imageSend_onAirSize => '放送中';

  @override
  String get imageSend_quality => '品質';

  @override
  String get imageSend_qualityStandard => '標準';

  @override
  String get imageSend_qualityHigh => 'ハイ';

  @override
  String get imageSend_packetsLabel => 'パケット';

  @override
  String get imageSend_airtimeLabel => '放送時間';

  @override
  String get imageSend_sizeLabel => 'ペイロード';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'パケット',
      one: 'パケット',
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
  String get imageSend_radioUnknownTitle => 'ラジオの設定が不明です';

  @override
  String get imageSend_radioUnknownBody => '放送時間の計算ができるように、デバイスに接続してください。';

  @override
  String get imageSend_longSendTitle => '長距離伝送';

  @override
  String imageSend_longSendBody(String duration) {
    return 'このチャンネルは約 $duration 間保持されます。';
  }

  @override
  String get imageSend_floodNote =>
      '洪水ルーティング：範囲内の各リピーターが各パケットを再送信するため、チャネルはこれよりも長く占有されたままになります。';

  @override
  String get imageSend_parityTitle => '回復パケット';

  @override
  String get imageSend_paritySubtitle =>
      '追加のパケットが1つあります。グループメッセージは確認されないため、1つのパケットが失われても受信者が画像を再構築できます。';

  @override
  String get imageSend_send => '送る';

  @override
  String get imageSend_cancel => 'キャンセル';

  @override
  String get imageSend_encodeFailed => 'この画像はエンコードできませんでした。';

  @override
  String get imageSend_codecDownloading => '画像モデルはまだダウンロード中です。';

  @override
  String get imageSend_codecUnavailable => 'このデバイスでは画像送信が利用できません。';

  @override
  String get imageSend_codecDisabled => '設定で画像メッセージはオフになっています。';

  @override
  String get imageSend_deviceUnsupported =>
      'このラジオは画像パケットを送信できません。コンパニオン ファームウェア 13 以降を実行しているデバイスを接続してください。';

  @override
  String get imageSend_directMessagesUnsupported =>
      '画像はグループデータとして送信されるため、ダイレクトメッセージではなくチャンネルに送ることができます。';

  @override
  String get imageSend_tooLarge => 'その画像は、メッシュ形式が許容するよりも多くのパケットにエンコードされています。';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'パケット',
      one: 'パケット',
    );
    return '$count $_temp0として画像を送信しました。';
  }

  @override
  String imageSend_sendFailed(String error) {
    return '画像を送信できませんでした：$error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return '画像送信 — パケット $sent 件、合計 $total 件';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'ノード $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$total パケット中 $received パケット';
  }

  @override
  String get receivedImage_queued => '復号を待っている';

  @override
  String get receivedImage_tapToDecode => 'デコードするにはタップしてください。';

  @override
  String get receivedImage_decoding => '再構築… 約1秒';

  @override
  String receivedImage_incomplete(int received, int total) {
    return '画像が不完全です — $total パケット中 $received パケットが到着しました';
  }

  @override
  String get receivedImage_corrupt => '画像を再構成することはできませんでした';

  @override
  String get receivedImage_decoderMissing => '画像を受信しました — 画像のデコードが失敗しました';

  @override
  String get receivedImage_evicted => '画像はもう保存されていません';

  @override
  String get receivedImage_retry => 'もう一度試してください';

  @override
  String get receivedImage_decodeAgain => 'もう一度デコードしてください';

  @override
  String get receivedImage_openSettings => '設定する';

  @override
  String get receivedImage_tapToProcess => '処理するにはタップしてください';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'パケット',
      one: 'パケット',
    );
    return '$bytes バイト・$packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds秒';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes分 $seconds秒';
  }
}
