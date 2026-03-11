// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => '联系人';

  @override
  String get nav_channels => '频道';

  @override
  String get nav_map => '地图';

  @override
  String get common_cancel => '取消';

  @override
  String get common_ok => '确定';

  @override
  String get common_connect => '连接';

  @override
  String get common_unknownDevice => '未知设备';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_deleteAll => '删除全部';

  @override
  String get common_close => '关闭';

  @override
  String get common_edit => '编辑';

  @override
  String get common_add => '添加';

  @override
  String get common_settings => '设置';

  @override
  String get common_disconnect => '断开';

  @override
  String get common_connected => '已连接';

  @override
  String get common_disconnected => '已断开';

  @override
  String get common_create => '创建';

  @override
  String get common_continue => '继续';

  @override
  String get common_share => '分享';

  @override
  String get common_copy => '复制';

  @override
  String get common_retry => '重试';

  @override
  String get common_hide => '隐藏';

  @override
  String get common_remove => '移除';

  @override
  String get common_enable => '启用';

  @override
  String get common_disable => '禁用';

  @override
  String get common_reboot => '重启';

  @override
  String get common_loading => '正在加载...';

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
  String get scanner_title => '连接设备';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => '蓝牙';

  @override
  String get usbScreenTitle => '通过USB连接';

  @override
  String get usbScreenSubtitle => '选择已检测到的串行设备，并直接连接到您的 MeshCore 节点。';

  @override
  String get usbScreenStatus => '选择一个 USB 设备';

  @override
  String get usbScreenNote => 'USB 串行接口在支持的 Android 设备和桌面平台上处于活动状态。';

  @override
  String get usbScreenEmptyState => '未找到任何 USB 设备。请插入一个，然后刷新。';

  @override
  String get usbErrorPermissionDenied => '拒绝了USB权限。';

  @override
  String get usbErrorDeviceMissing => '所选的USB设备已不再可用。';

  @override
  String get usbErrorInvalidPort => '选择一个有效的USB设备。';

  @override
  String get usbErrorBusy => '还有一个 USB 连接请求正在进行中。';

  @override
  String get usbErrorNotConnected => '没有连接任何USB设备。';

  @override
  String get usbErrorOpenFailed => '未能打开所选的USB设备。';

  @override
  String get usbErrorConnectFailed => '未能连接到所选的USB设备。';

  @override
  String get usbErrorUnsupported => '此平台不支持USB串行通信。';

  @override
  String get usbErrorAlreadyActive => 'USB 连接已建立。';

  @override
  String get usbErrorNoDeviceSelected => '未选择任何 USB 设备。';

  @override
  String get usbErrorPortClosed => 'USB 连接未建立。';

  @override
  String get usbErrorConnectTimedOut => '连接超时。请确保设备已安装 USB 伴侣固件。';

  @override
  String get usbFallbackDeviceName => 'Web 串流设备';

  @override
  String get usbStatus_notConnected => '选择一个 USB 设备';

  @override
  String get usbStatus_connecting => '连接USB设备...';

  @override
  String get usbStatus_searching => '正在搜索 USB 设备...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB 连接失败：$error';
  }

  @override
  String get scanner_scanning => '正在搜索设备...';

  @override
  String get scanner_connecting => '正在连接...';

  @override
  String get scanner_disconnecting => '断开连接...';

  @override
  String get scanner_notConnected => '未连接';

  @override
  String scanner_connectedTo(String deviceName) {
    return '已连接到 $deviceName';
  }

  @override
  String get scanner_searchingDevices => '正在搜索 MeshCore 设备...';

  @override
  String get scanner_tapToScan => '点击“扫描”按钮以查找 MeshCore 设备。';

  @override
  String scanner_connectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get scanner_stop => '停止';

  @override
  String get scanner_scan => '扫描';

  @override
  String get scanner_bluetoothOff => '蓝牙已关闭';

  @override
  String get scanner_bluetoothOffMessage => '请开启蓝牙以搜索设备';

  @override
  String get scanner_chromeRequired => '需要 Chrome 浏览器';

  @override
  String get scanner_chromeRequiredMessage =>
      '此 Web 应用程序需要 Google Chrome 或基于 Chromium 的浏览器以支持蓝牙。';

  @override
  String get scanner_enableBluetooth => '启用蓝牙';

  @override
  String get device_quickSwitch => '快速切换';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => '设置';

  @override
  String get settings_deviceInfo => '设备信息';

  @override
  String get settings_appSettings => '应用设置';

  @override
  String get settings_appSettingsSubtitle => '通知、消息和地图偏好';

  @override
  String get settings_nodeSettings => '节点设置';

  @override
  String get settings_nodeName => '节点名称';

  @override
  String get settings_nodeNameNotSet => '未设置';

  @override
  String get settings_nodeNameHint => '请输入节点名称';

  @override
  String get settings_nodeNameUpdated => '节点名称已更新';

  @override
  String get settings_radioSettings => '无线电设置';

  @override
  String get settings_radioSettingsSubtitle => '频率、功率、扩频因子';

  @override
  String get settings_radioSettingsUpdated => '无线电设置已更新';

  @override
  String get settings_location => '位置';

  @override
  String get settings_locationSubtitle => 'GPS 坐标';

  @override
  String get settings_locationUpdated => '位置和 GPS 设置已更新';

  @override
  String get settings_locationBothRequired => '请输入经度和纬度';

  @override
  String get settings_locationInvalid => '无效的经度和纬度';

  @override
  String get settings_locationGPSEnable => '启用 GPS';

  @override
  String get settings_locationGPSEnableSubtitle => '启用 GPS 以自动更新位置。';

  @override
  String get settings_locationIntervalSec => 'GPS 间隔（秒）';

  @override
  String get settings_locationIntervalInvalid => '间隔时间必须至少为 60 秒，但不超过 86400 秒。';

  @override
  String get settings_latitude => '纬度';

  @override
  String get settings_longitude => '经度';

  @override
  String get settings_contactSettings => '联系人设置';

  @override
  String get settings_contactSettingsSubtitle => '添加联系人的设置';

  @override
  String get settings_privacyMode => '隐私模式';

  @override
  String get settings_privacyModeSubtitle => '在广告中隐藏姓名/位置';

  @override
  String get settings_privacyModeToggle => '切换隐私模式以在广告中隐藏姓名和位置，保护个人信息。';

  @override
  String get settings_privacyModeEnabled => '隐私模式已启用';

  @override
  String get settings_privacyModeDisabled => '隐私模式已关闭';

  @override
  String get settings_actions => '操作';

  @override
  String get settings_sendAdvertisement => '发送广播';

  @override
  String get settings_sendAdvertisementSubtitle => '立即发送广播';

  @override
  String get settings_advertisementSent => '已发送广播';

  @override
  String get settings_syncTime => '同步时间';

  @override
  String get settings_syncTimeSubtitle => '将设备时钟设置为与手机时间一致';

  @override
  String get settings_timeSynchronized => '时间已同步';

  @override
  String get settings_refreshContacts => '刷新联系人';

  @override
  String get settings_refreshContactsSubtitle => '从设备重新加载联系人列表';

  @override
  String get settings_rebootDevice => '重启设备';

  @override
  String get settings_rebootDeviceSubtitle => '重启 MeshCore 设备';

  @override
  String get settings_rebootDeviceConfirm => '确定要重启设备吗？这将断开与设备的连接。';

  @override
  String get settings_debug => '调试';

  @override
  String get settings_bleDebugLog => 'BLE 调试日志';

  @override
  String get settings_bleDebugLogSubtitle => 'BLE 命令、响应和原始数据';

  @override
  String get settings_appDebugLog => '应用调试日志';

  @override
  String get settings_appDebugLogSubtitle => '应用调试消息';

  @override
  String get settings_about => '关于';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore 开源项目';

  @override
  String get settings_aboutDescription =>
      '一个开源的 Flutter 客户端，用于 MeshCore LoRa 无线网络设备。';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS 高程数据:Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => '名称';

  @override
  String get settings_infoId => 'MAC ID';

  @override
  String get settings_infoStatus => '状态';

  @override
  String get settings_infoBattery => '电池';

  @override
  String get settings_infoPublicKey => '公钥';

  @override
  String get settings_infoContactsCount => '联系人数量';

  @override
  String get settings_infoChannelCount => '频道数量';

  @override
  String get settings_presets => '预设';

  @override
  String get settings_frequency => '频率 (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => '无效频率范围（300-2500 MHz）';

  @override
  String get settings_bandwidth => '带宽';

  @override
  String get settings_spreadingFactor => '扩频因子';

  @override
  String get settings_codingRate => '编码速率';

  @override
  String get settings_txPower => 'TX 功率 (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => '无效的发射功率（0-22 dBm）';

  @override
  String get settings_clientRepeat => '离网重复';

  @override
  String get settings_clientRepeatSubtitle => '允许此设备重复发送网状数据包给其他设备';

  @override
  String get settings_clientRepeatFreqWarning =>
      '离网重复通信需要使用 433、869 或 918 兆赫兹的频率。';

  @override
  String settings_error(String message) {
    return '错误：$message';
  }

  @override
  String get appSettings_title => '应用设置';

  @override
  String get appSettings_appearance => '外观';

  @override
  String get appSettings_theme => '主题';

  @override
  String get appSettings_themeSystem => '跟随系统';

  @override
  String get appSettings_themeLight => '浅色';

  @override
  String get appSettings_themeDark => '深色';

  @override
  String get appSettings_language => '语言';

  @override
  String get appSettings_languageSystem => '跟随系统';

  @override
  String get appSettings_languageEn => '英语';

  @override
  String get appSettings_languageFr => '法语';

  @override
  String get appSettings_languageEs => '西班牙语';

  @override
  String get appSettings_languageDe => '德语';

  @override
  String get appSettings_languagePl => '波兰语';

  @override
  String get appSettings_languageSl => '斯洛文尼亚语';

  @override
  String get appSettings_languagePt => '葡萄牙语';

  @override
  String get appSettings_languageIt => '意大利语';

  @override
  String get appSettings_languageZh => '中文';

  @override
  String get appSettings_languageSv => '瑞典语';

  @override
  String get appSettings_languageNl => '荷兰语';

  @override
  String get appSettings_languageSk => '斯洛伐克语';

  @override
  String get appSettings_languageBg => '保加利亚语';

  @override
  String get appSettings_languageRu => '俄语';

  @override
  String get appSettings_languageUk => '乌克兰语';

  @override
  String get appSettings_enableMessageTracing => '启用消息追踪';

  @override
  String get appSettings_enableMessageTracingSubtitle => '显示消息的详细路由和时间元数据';

  @override
  String get appSettings_notifications => '通知';

  @override
  String get appSettings_enableNotifications => '启用通知';

  @override
  String get appSettings_enableNotificationsSubtitle => '接收消息和广播的通知';

  @override
  String get appSettings_notificationPermissionDenied => '权限被拒绝';

  @override
  String get appSettings_notificationsEnabled => '通知已启用';

  @override
  String get appSettings_notificationsDisabled => '通知已关闭';

  @override
  String get appSettings_messageNotifications => '消息通知';

  @override
  String get appSettings_messageNotificationsSubtitle => '收到新消息时显示通知';

  @override
  String get appSettings_channelMessageNotifications => '频道消息通知';

  @override
  String get appSettings_channelMessageNotificationsSubtitle => '收到频道消息时显示通知';

  @override
  String get appSettings_advertisementNotifications => '广播通知';

  @override
  String get appSettings_advertisementNotificationsSubtitle => '发现新节点时显示通知';

  @override
  String get appSettings_messaging => '消息';

  @override
  String get appSettings_clearPathOnMaxRetry => '达到最大重试次数时清除路径';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle => '在5次发送失败后重置联系路径。';

  @override
  String get appSettings_pathsWillBeCleared => '5次失败后将重新路由';

  @override
  String get appSettings_pathsWillNotBeCleared => '路径不会自动清除';

  @override
  String get appSettings_autoRouteRotation => '自动路径轮换';

  @override
  String get appSettings_autoRouteRotationSubtitle => '在最佳路径和泛洪模式之间切换';

  @override
  String get appSettings_autoRouteRotationEnabled => '自动路径轮换已启用';

  @override
  String get appSettings_autoRouteRotationDisabled => '自动路径轮换已禁用';

  @override
  String get appSettings_battery => '电池';

  @override
  String get appSettings_batteryChemistry => '电池类型';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '为每个设备设置 ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst => '请先连接设备';

  @override
  String get appSettings_batteryNmc => '18650 NMC 电池 (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => '磷酸铁锂 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => '锂聚合物电池 (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => '地图显示';

  @override
  String get appSettings_showRepeaters => '显示转发节点';

  @override
  String get appSettings_showRepeatersSubtitle => '在地图上显示转发节点';

  @override
  String get appSettings_showChatNodes => '显示聊天节点';

  @override
  String get appSettings_showChatNodesSubtitle => '在地图上显示聊天节点';

  @override
  String get appSettings_showOtherNodes => '显示其他节点';

  @override
  String get appSettings_showOtherNodesSubtitle => '在地图上显示其他节点类型';

  @override
  String get appSettings_timeFilter => '时间过滤器';

  @override
  String get appSettings_timeFilterShowAll => '显示所有节点';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '显示过去 $hours 小时内的节点';
  }

  @override
  String get appSettings_mapTimeFilter => '地图时间筛选';

  @override
  String get appSettings_showNodesDiscoveredWithin => '显示在此时间段内发现的节点：';

  @override
  String get appSettings_allTime => '所有时间';

  @override
  String get appSettings_lastHour => '过去一小时';

  @override
  String get appSettings_last6Hours => '过去6小时';

  @override
  String get appSettings_last24Hours => '过去24小时';

  @override
  String get appSettings_lastWeek => '上周';

  @override
  String get appSettings_offlineMapCache => '离线地图缓存';

  @override
  String get appSettings_unitsTitle => '单位';

  @override
  String get appSettings_unitsMetric => '公制（米/公里）';

  @override
  String get appSettings_unitsImperial => '英制 (ft / mi)';

  @override
  String get appSettings_noAreaSelected => '未选择任何区域';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return '已选择区域（缩放 $minZoom - $maxZoom）';
  }

  @override
  String get appSettings_debugCard => '调试';

  @override
  String get appSettings_appDebugLogging => '应用调试日志';

  @override
  String get appSettings_appDebugLoggingSubtitle => '记录应用调试消息以进行故障排除。';

  @override
  String get appSettings_appDebugLoggingEnabled => '调试日志已启用';

  @override
  String get appSettings_appDebugLoggingDisabled => '应用调试日志已禁用';

  @override
  String get contacts_title => '联系人';

  @override
  String get contacts_noContacts => '暂无联系人';

  @override
  String get contacts_contactsWillAppear => '当设备发送广播时，联系人将显示。';

  @override
  String get contacts_unread => '未读';

  @override
  String get contacts_searchContactsNoNumber => '搜索联系人...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '搜索联系人...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return '搜索 $number$str 收藏...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return '搜索 $number$str 位用户...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return '搜索 $number$str 重复器...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return '搜索 $number$str 房间服务器...';
  }

  @override
  String get contacts_noUnreadContacts => '没有未读内容';

  @override
  String get contacts_noContactsFound => '未找到任何联系人或群聊';

  @override
  String get contacts_deleteContact => '删除联系人';

  @override
  String contacts_removeConfirm(String contactName) {
    return '从联系人中移除 $contactName？';
  }

  @override
  String get contacts_manageRepeater => '管理转发节点';

  @override
  String get contacts_manageRoom => '管理房间服务器';

  @override
  String get contacts_roomLogin => '服务器登录';

  @override
  String get contacts_openChat => '打开聊天';

  @override
  String get contacts_editGroup => '编辑群聊';

  @override
  String get contacts_deleteGroup => '删除群聊';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '删除群聊 \"$groupName\"？';
  }

  @override
  String get contacts_newGroup => '新建群聊';

  @override
  String get contacts_groupName => '群聊名称';

  @override
  String get contacts_groupNameRequired => '请输入群聊名称';

  @override
  String contacts_groupAlreadyExists(String name) {
    return '名为 \"$name\" 的群聊已存在';
  }

  @override
  String get contacts_filterContacts => '筛选联系人...';

  @override
  String get contacts_noContactsMatchFilter => '没有符合条件的联系人';

  @override
  String get contacts_noMembers => '暂无成员';

  @override
  String get contacts_lastSeenNow => '刚刚';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '最后在线 $minutes 分钟前';
  }

  @override
  String get contacts_lastSeenHourAgo => '最后在线 1小时前';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '最后在线 $hours 小时前';
  }

  @override
  String get contacts_lastSeenDayAgo => '最后在线 1天前';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '最后在线 $days 天前';
  }

  @override
  String get channels_title => '频道';

  @override
  String get channels_noChannelsConfigured => '未配置任何频道';

  @override
  String get channels_addPublicChannel => '添加公共频道';

  @override
  String get channels_searchChannels => '搜索频道...';

  @override
  String get channels_noChannelsFound => '未找到任何频道';

  @override
  String channels_channelIndex(int index) {
    return '频道 $index';
  }

  @override
  String get channels_hashtagChannel => '标签频道';

  @override
  String get channels_public => '公共';

  @override
  String get channels_private => '私有';

  @override
  String get channels_publicChannel => '公共频道';

  @override
  String get channels_privateChannel => '私有频道';

  @override
  String get channels_editChannel => '编辑频道';

  @override
  String get channels_muteChannel => '静音频道';

  @override
  String get channels_unmuteChannel => '取消静音频道';

  @override
  String get channels_deleteChannel => '删除频道';

  @override
  String channels_deleteChannelConfirm(String name) {
    return '删除频道 \"$name\"？此操作不可撤销。';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return '无法删除频道 \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return '已删除频道 \"$name\"';
  }

  @override
  String get channels_addChannel => '添加频道';

  @override
  String get channels_channelIndexLabel => '频道索引';

  @override
  String get channels_channelName => '频道名称';

  @override
  String get channels_usePublicChannel => '使用公共频道';

  @override
  String get channels_standardPublicPsk => '标准公共 PSK';

  @override
  String get channels_pskHex => 'PSK (十六进制)';

  @override
  String get channels_generateRandomPsk => '生成随机 PSK';

  @override
  String get channels_enterChannelName => '请输入频道名称';

  @override
  String get channels_pskMustBe32Hex => 'PSK 必须为 32 个十六进制字符';

  @override
  String channels_channelAdded(String name) {
    return '已添加频道 \"$name\"';
  }

  @override
  String channels_editChannelTitle(int index) {
    return '编辑频道 $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ 压缩';

  @override
  String channels_channelUpdated(String name) {
    return '频道 \"$name\" 已更新';
  }

  @override
  String get channels_publicChannelAdded => '已添加公共频道';

  @override
  String get channels_sortBy => '排序方式';

  @override
  String get channels_sortManual => '手动';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => '最新消息';

  @override
  String get channels_sortUnread => '未读';

  @override
  String get channels_createPrivateChannel => '创建私有频道';

  @override
  String get channels_createPrivateChannelDesc => '使用密钥保护。';

  @override
  String get channels_joinPrivateChannel => '加入私有频道';

  @override
  String get channels_joinPrivateChannelDesc => '手动输入密钥。';

  @override
  String get channels_joinPublicChannel => '加入公共频道';

  @override
  String get channels_joinPublicChannelDesc => '任何人都可以加入。';

  @override
  String get channels_joinHashtagChannel => '加入标签频道';

  @override
  String get channels_joinHashtagChannelDesc => '任何人都可以加入标签频道。';

  @override
  String get channels_scanQrCode => '扫描二维码';

  @override
  String get channels_scanQrCodeComingSoon => '即将推出';

  @override
  String get channels_enterHashtag => '输入标签';

  @override
  String get channels_hashtagHint => '例如：#团队';

  @override
  String get chat_noMessages => '暂无消息';

  @override
  String get chat_sendMessageToStart => '发送消息开始对话';

  @override
  String get chat_originalMessageNotFound => '找不到原始消息';

  @override
  String chat_replyingTo(String name) {
    return '正在回复 $name';
  }

  @override
  String chat_replyTo(String name) {
    return '回复 $name';
  }

  @override
  String get chat_location => '位置';

  @override
  String chat_sendMessageTo(String contactName) {
    return '发送消息给 $contactName';
  }

  @override
  String get chat_typeMessage => '输入消息...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return '消息过长（最多 $maxBytes 字节）';
  }

  @override
  String get chat_messageCopied => '消息已复制';

  @override
  String get chat_messageDeleted => '消息已删除';

  @override
  String get chat_retryingMessage => '正在重试消息';

  @override
  String chat_retryCount(int current, int max) {
    return '重试 $current/$max';
  }

  @override
  String get chat_sendGif => '发送 GIF';

  @override
  String get chat_reply => '回复';

  @override
  String get chat_addReaction => '添加表情';

  @override
  String get chat_me => '我';

  @override
  String get emojiCategorySmileys => '表情';

  @override
  String get emojiCategoryGestures => '手势';

  @override
  String get emojiCategoryHearts => '爱心';

  @override
  String get emojiCategoryObjects => '物品';

  @override
  String get gifPicker_title => '选择 GIF';

  @override
  String get gifPicker_searchHint => '搜索 GIF...';

  @override
  String get gifPicker_poweredBy => '由 GIPHY 提供';

  @override
  String get gifPicker_noGifsFound => '未找到 GIF';

  @override
  String get gifPicker_failedLoad => '加载 GIF 失败';

  @override
  String get gifPicker_failedSearch => '搜索 GIF 失败';

  @override
  String get gifPicker_noInternet => '无网络连接';

  @override
  String get debugLog_appTitle => '应用调试日志';

  @override
  String get debugLog_bleTitle => 'BLE 调试日志';

  @override
  String get debugLog_copyLog => '复制日志';

  @override
  String get debugLog_clearLog => '清除日志';

  @override
  String get debugLog_copied => '调试日志已复制';

  @override
  String get debugLog_bleCopied => 'BLE 日志已复制';

  @override
  String get debugLog_noEntries => '暂无调试日志';

  @override
  String get debugLog_enableInSettings => '请在设置中启用应用调试日志。';

  @override
  String get debugLog_frames => '帧';

  @override
  String get debugLog_rawLogRx => '原始日志 RX';

  @override
  String get debugLog_noBleActivity => '暂无 BLE 活动';

  @override
  String debugFrame_length(int count) {
    return '帧长度：$count 字节';
  }

  @override
  String debugFrame_command(String value) {
    return '命令：0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => '文本消息：';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- 目标公钥：$pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- 时间戳：$timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- 标志：0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- 文本类型：$type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => '命令行';

  @override
  String get debugFrame_textTypePlain => '纯文本';

  @override
  String debugFrame_text(String text) {
    return '- 文本：“$text”';
  }

  @override
  String get debugFrame_hexDump => '十六进制数据：';

  @override
  String get chat_pathManagement => '路径管理';

  @override
  String get chat_ShowAllPaths => '显示所有路径';

  @override
  String get chat_routingMode => '路由模式';

  @override
  String get chat_autoUseSavedPath => '自动（使用保存的路径）';

  @override
  String get chat_forceFloodMode => '强制泛洪模式';

  @override
  String get chat_recentAckPaths => '最近使用的 ACK 路径（点击使用）：';

  @override
  String get chat_pathHistoryFull => '路径历史已满，请删除后再添加。';

  @override
  String get chat_hopSingular => '跳';

  @override
  String get chat_hopPlural => '跳';

  @override
  String chat_hopsCount(int count) {
    return '$count 跳';
  }

  @override
  String get chat_successes => '成功';

  @override
  String get chat_removePath => '移除路径';

  @override
  String get chat_noPathHistoryYet => '暂无路径历史。\n发送消息以探索路径。';

  @override
  String get chat_pathActions => '路径操作：';

  @override
  String get chat_setCustomPath => '设置自定义路径';

  @override
  String get chat_setCustomPathSubtitle => '手动指定路由路径';

  @override
  String get chat_clearPath => '清除路径';

  @override
  String get chat_clearPathSubtitle => '清除当前路径，下次发送将重新尝试。';

  @override
  String get chat_pathCleared => '路径已清除。下一条消息将重新路由。';

  @override
  String get chat_floodModeSubtitle => '在应用栏中切换路由模式。';

  @override
  String get chat_floodModeEnabled => '泛洪模式已启用。可通过应用栏的路由图标切换。';

  @override
  String get chat_fullPath => '完整路径';

  @override
  String get chat_pathDetailsNotAvailable => '路径信息暂不可用，请尝试发送消息刷新。';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    return '路径设置：$hopCount 跳 - $status';
  }

  @override
  String get chat_pathSavedLocally => '已本地保存，连接设备后可同步。';

  @override
  String get chat_pathDeviceConfirmed => '设备已确认。';

  @override
  String get chat_pathDeviceNotConfirmed => '设备尚未确认。';

  @override
  String get chat_type => '类型';

  @override
  String get chat_path => '路径';

  @override
  String get chat_publicKey => '公钥';

  @override
  String get chat_compressOutgoingMessages => '压缩发送的消息';

  @override
  String get chat_floodForced => '泛洪（强制）';

  @override
  String get chat_directForced => '直连（强制）';

  @override
  String chat_hopsForced(int count) {
    return '$count 跳（强制）';
  }

  @override
  String get chat_floodAuto => '自动泛洪';

  @override
  String get chat_direct => '直连';

  @override
  String get chat_poiShared => '共享位置';

  @override
  String chat_unread(int count) {
    return '未读：$count';
  }

  @override
  String get chat_openLink => '打开链接？';

  @override
  String get chat_openLinkConfirmation => '是否使用浏览器打开此链接？';

  @override
  String get chat_open => '打开';

  @override
  String chat_couldNotOpenLink(String url) {
    return '无法打开链接：$url';
  }

  @override
  String get chat_invalidLink => '无效的链接格式';

  @override
  String get map_title => '节点地图';

  @override
  String get map_lineOfSight => '视线';

  @override
  String get map_losScreenTitle => '视线';

  @override
  String get map_noNodesWithLocation => '没有包含位置信息的节点';

  @override
  String get map_nodesNeedGps => '节点需要共享 GPS 坐标才能在地图上显示';

  @override
  String map_nodesCount(int count) {
    return '节点：$count';
  }

  @override
  String map_pinsCount(int count) {
    return '标记：$count';
  }

  @override
  String get map_chat => '聊天';

  @override
  String get map_repeater => '转发节点';

  @override
  String get map_room => '房间';

  @override
  String get map_sensor => '传感器';

  @override
  String get map_pinDm => '标记（私信）';

  @override
  String get map_pinPrivate => '私有';

  @override
  String get map_pinPublic => '公共';

  @override
  String get map_lastSeen => '最后在线';

  @override
  String get map_disconnectConfirm => '确定要断开与此设备的连接吗？';

  @override
  String get map_from => '来自';

  @override
  String get map_source => '来源';

  @override
  String get map_flags => '标志';

  @override
  String get map_shareMarkerHere => '在此分享标记';

  @override
  String get map_pinLabel => '标签';

  @override
  String get map_label => '标签';

  @override
  String get map_pointOfInterest => '兴趣点';

  @override
  String get map_sendToContact => '发送给联系人';

  @override
  String get map_sendToChannel => '发送到频道';

  @override
  String get map_noChannelsAvailable => '没有可用的频道';

  @override
  String get map_publicLocationShare => '公共位置共享';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '您即将在 $channelLabel 上分享一个位置。此频道是公开的，任何拥有 PSK 的人都可以看到。';
  }

  @override
  String get map_connectToShareMarkers => '连接设备以共享标记';

  @override
  String get map_filterNodes => '过滤节点';

  @override
  String get map_nodeTypes => '节点类型';

  @override
  String get map_chatNodes => '聊天节点';

  @override
  String get map_repeaters => '转发节点';

  @override
  String get map_otherNodes => '其他节点';

  @override
  String get map_keyPrefix => '关键字前缀';

  @override
  String get map_filterByKeyPrefix => '按关键字前缀筛选';

  @override
  String get map_publicKeyPrefix => '关键字前缀';

  @override
  String get map_markers => '标记';

  @override
  String get map_showSharedMarkers => '显示共享标记';

  @override
  String get map_showGuessedLocations => '显示猜测的节点位置';

  @override
  String get map_showDiscoveryContacts => '显示发现联系人';

  @override
  String get map_guessedLocation => '猜测的位置';

  @override
  String get map_lastSeenTime => '最后在线时间';

  @override
  String get map_sharedPin => '共享标记';

  @override
  String get map_joinRoom => '加入房间';

  @override
  String get map_manageRepeater => '管理转发节点';

  @override
  String get map_tapToAdd => '点击节点以添加到路径';

  @override
  String get map_runTrace => '运行路径追踪';

  @override
  String get map_removeLast => '移除最后一个';

  @override
  String get map_pathTraceCancelled => '路径追踪已取消';

  @override
  String get mapCache_title => '离线地图缓存';

  @override
  String get mapCache_selectAreaFirst => '请先选择要缓存的区域';

  @override
  String get mapCache_noTilesToDownload => '此区域没有可下载的瓦片';

  @override
  String get mapCache_downloadTilesTitle => '下载瓦片';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return '这需要下载 $count 个瓦片';
  }

  @override
  String get mapCache_downloadAction => '下载';

  @override
  String mapCache_cachedTiles(int count) {
    return '已缓存 $count 个瓦片';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return '已缓存 $downloaded 个瓦片（$failed 个失败）';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => '清除离线缓存';

  @override
  String get mapCache_clearOfflineCachePrompt => '清除所有缓存的地图瓦片';

  @override
  String get mapCache_offlineCacheCleared => '离线缓存已清除';

  @override
  String get mapCache_noAreaSelected => '未选择区域';

  @override
  String get mapCache_cacheArea => '缓存区域';

  @override
  String get mapCache_useCurrentView => '使用当前视图';

  @override
  String get mapCache_zoomRange => '缩放范围';

  @override
  String mapCache_estimatedTiles(int count) {
    return '估计瓦片数：$count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return '已下载 $completed/$total';
  }

  @override
  String get mapCache_downloadTilesButton => '下载瓦片';

  @override
  String get mapCache_clearCacheButton => '清除缓存';

  @override
  String mapCache_failedDownloads(int count) {
    return '下载失败：$count';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return '北 $north, 南 $south, 东 $east, 西 $west';
  }

  @override
  String get time_justNow => '刚才';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String time_daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get time_hour => '小时';

  @override
  String get time_hours => '小时';

  @override
  String get time_day => '天';

  @override
  String get time_days => '天';

  @override
  String get time_week => '周';

  @override
  String get time_weeks => '周';

  @override
  String get time_month => '月';

  @override
  String get time_months => '月';

  @override
  String get time_minutes => '分钟';

  @override
  String get time_allTime => '所有时间';

  @override
  String get dialog_disconnect => '断开';

  @override
  String get dialog_disconnectConfirm => '确定要断开与此设备的连接吗？';

  @override
  String get login_repeaterLogin => '转发节点登录';

  @override
  String get login_roomLogin => '房间服务器登录';

  @override
  String get login_password => '密码';

  @override
  String get login_enterPassword => '请输入密码';

  @override
  String get login_savePassword => '保存密码';

  @override
  String get login_savePasswordSubtitle => '密码将安全地存储在此设备上';

  @override
  String get login_repeaterDescription => '输入转发节点密码以访问设置和状态。';

  @override
  String get login_roomDescription => '输入房间服务器密码以访问设置和状态。';

  @override
  String get login_routing => '路由';

  @override
  String get login_routingMode => '路由模式';

  @override
  String get login_autoUseSavedPath => '自动（使用保存的路径）';

  @override
  String get login_forceFloodMode => '强制泛洪模式';

  @override
  String get login_managePaths => '管理路径';

  @override
  String get login_login => '登录';

  @override
  String login_attempt(int current, int max) {
    return '尝试 $current/$max';
  }

  @override
  String login_failed(String error) {
    return '登录失败：$error';
  }

  @override
  String get login_failedMessage => '登录失败。可能是密码错误或无法连接到服务器。';

  @override
  String get common_reload => '重新加载';

  @override
  String get common_clear => '清除';

  @override
  String path_currentPath(String path) {
    return '当前路径：$path';
  }

  @override
  String path_usingHopsPath(int count) {
    return '使用 $count 跳路径';
  }

  @override
  String get path_enterCustomPath => '输入自定义路径';

  @override
  String get path_currentPathLabel => '当前路径';

  @override
  String get path_hexPrefixInstructions => '请输入每个中继节点的2字符十六进制前缀，用逗号分隔。';

  @override
  String get path_hexPrefixExample => '例如：A1, F2, 3C（每个节点使用其公钥的第一字节）';

  @override
  String get path_labelHexPrefixes => '路径（十六进制前缀）';

  @override
  String get path_helperMaxHops => '最多 64 跳。每个前缀由 2 个十六进制字符（1 字节）组成。';

  @override
  String get path_selectFromContacts => '或从联系人列表中选择：';

  @override
  String get path_noRepeatersFound => '未找到任何转发节点或房间服务器。';

  @override
  String get path_customPathsRequire => '自定义路径需要中间节点转发消息。';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return '无效的十六进制前缀：$prefixes';
  }

  @override
  String get path_tooLong => '路径过长，最多允许 64 跳。';

  @override
  String get path_setPath => '设置路径';

  @override
  String get repeater_management => '转发节点管理';

  @override
  String get room_management => '房间服务器管理';

  @override
  String get repeater_managementTools => '管理工具';

  @override
  String get repeater_status => '状态';

  @override
  String get repeater_statusSubtitle => '查看转发节点状态、统计和邻居';

  @override
  String get repeater_telemetry => '遥测';

  @override
  String get repeater_telemetrySubtitle => '查看传感器和系统状态数据';

  @override
  String get repeater_cli => '命令行';

  @override
  String get repeater_cliSubtitle => '向转发节点发送命令';

  @override
  String get repeater_neighbors => '邻居';

  @override
  String get repeater_neighborsSubtitle => '查看邻居节点（零跳）';

  @override
  String get repeater_settings => '设置';

  @override
  String get repeater_settingsSubtitle => '配置转发节点参数';

  @override
  String get repeater_statusTitle => '转发节点状态';

  @override
  String get repeater_routingMode => '路由模式';

  @override
  String get repeater_autoUseSavedPath => '自动（使用保存的路径）';

  @override
  String get repeater_forceFloodMode => '强制泛洪模式';

  @override
  String get repeater_pathManagement => '路径管理';

  @override
  String get repeater_refresh => '刷新';

  @override
  String get repeater_statusRequestTimeout => '状态请求超时';

  @override
  String repeater_errorLoadingStatus(String error) {
    return '加载状态时出错：$error';
  }

  @override
  String get repeater_systemInformation => '系统信息';

  @override
  String get repeater_battery => '电池';

  @override
  String get repeater_clockAtLogin => '登录时的时钟';

  @override
  String get repeater_uptime => '运行时间';

  @override
  String get repeater_queueLength => '队列长度';

  @override
  String get repeater_debugFlags => '调试标志';

  @override
  String get repeater_radioStatistics => '无线电统计';

  @override
  String get repeater_lastRssi => '上次 RSSI';

  @override
  String get repeater_lastSnr => '上次 SNR';

  @override
  String get repeater_noiseFloor => '底噪';

  @override
  String get repeater_txAirtime => '发送空中时间';

  @override
  String get repeater_rxAirtime => '接收空中时间';

  @override
  String get repeater_packetStatistics => '数据包统计';

  @override
  String get repeater_sent => '发送';

  @override
  String get repeater_received => '接收';

  @override
  String get repeater_duplicates => '重复';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days天 $hours小时 $minutes分 $seconds秒';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return '总计：$total，泛洪：$flood，直连：$direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '总计：$total，泛洪：$flood，直连：$direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return '泛洪：$flood，直连：$direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return '总计：$total';
  }

  @override
  String get repeater_settingsTitle => '转发节点设置';

  @override
  String get repeater_basicSettings => '基本设置';

  @override
  String get repeater_repeaterName => '转发节点名称';

  @override
  String get repeater_repeaterNameHelper => '此转发节点的显示名称';

  @override
  String get repeater_adminPassword => '管理员密码';

  @override
  String get repeater_adminPasswordHelper => '完整访问密码';

  @override
  String get repeater_guestPassword => '访客密码';

  @override
  String get repeater_guestPasswordHelper => '只读访问密码';

  @override
  String get repeater_radioSettings => '无线电设置';

  @override
  String get repeater_frequencyMhz => '频率 (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX 功率';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => '带宽';

  @override
  String get repeater_spreadingFactor => '扩频因子';

  @override
  String get repeater_codingRate => '编码速率';

  @override
  String get repeater_locationSettings => '位置设置';

  @override
  String get repeater_latitude => '纬度';

  @override
  String get repeater_latitudeHelper => '十进制，例如 37.7749';

  @override
  String get repeater_longitude => '经度';

  @override
  String get repeater_longitudeHelper => '十进制，例如 -122.4194';

  @override
  String get repeater_features => '功能';

  @override
  String get repeater_packetForwarding => '数据包转发';

  @override
  String get repeater_packetForwardingSubtitle => '启用转发节点转发数据包';

  @override
  String get repeater_guestAccess => '访客访问';

  @override
  String get repeater_guestAccessSubtitle => '允许访客只读权限';

  @override
  String get repeater_privacyMode => '隐私模式';

  @override
  String get repeater_privacyModeSubtitle => '在广播中隐藏姓名/位置';

  @override
  String get repeater_advertisementSettings => '广播设置';

  @override
  String get repeater_localAdvertInterval => '本地广播间隔';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get repeater_floodAdvertInterval => '泛洪广播间隔';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 小时';
  }

  @override
  String get repeater_encryptedAdvertInterval => '加密广播间隔';

  @override
  String get repeater_dangerZone => '危险设置';

  @override
  String get repeater_rebootRepeater => '重启转发节点';

  @override
  String get repeater_rebootRepeaterSubtitle => '重启转发节点设备';

  @override
  String get repeater_rebootRepeaterConfirm => '确定要重启此转发节点吗？';

  @override
  String get repeater_regenerateIdentityKey => '重新生成身份密钥';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '生成新的公钥/私钥对';

  @override
  String get repeater_regenerateIdentityKeyConfirm => '这将为转发节点生成新身份，继续吗？';

  @override
  String get repeater_eraseFileSystem => '擦除文件系统';

  @override
  String get repeater_eraseFileSystemSubtitle => '格式化转发节点文件系统';

  @override
  String get repeater_eraseFileSystemConfirm => '警告：此操作将清除转发节点上的所有数据，且无法恢复！';

  @override
  String get repeater_eraseSerialOnly => '擦除功能仅可通过串行控制台使用。';

  @override
  String repeater_commandSent(String command) {
    return '命令已发送：$command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return '发送命令时出错：$error';
  }

  @override
  String get repeater_confirm => '确认';

  @override
  String get repeater_settingsSaved => '设置保存成功';

  @override
  String repeater_errorSavingSettings(String error) {
    return '保存设置时出错：$error';
  }

  @override
  String get repeater_refreshBasicSettings => '刷新基本设置';

  @override
  String get repeater_refreshRadioSettings => '刷新无线电设置';

  @override
  String get repeater_refreshTxPower => '刷新 TX 功率';

  @override
  String get repeater_refreshLocationSettings => '刷新位置设置';

  @override
  String get repeater_refreshPacketForwarding => '刷新包转发';

  @override
  String get repeater_refreshGuestAccess => '刷新访客权限';

  @override
  String get repeater_refreshPrivacyMode => '刷新隐私模式';

  @override
  String get repeater_refreshAdvertisementSettings => '刷新广播设置';

  @override
  String repeater_refreshed(String label) {
    return '$label 已刷新';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '刷新 $label 时出错';
  }

  @override
  String get repeater_cliTitle => '转发节点命令行';

  @override
  String get repeater_debugNextCommand => '调试下一条命令';

  @override
  String get repeater_commandHelp => '帮助';

  @override
  String get repeater_clearHistory => '清除历史';

  @override
  String get repeater_noCommandsSent => '尚未发送命令';

  @override
  String get repeater_typeCommandOrUseQuick => '输入命令或使用快捷命令';

  @override
  String get repeater_enterCommandHint => '输入命令...';

  @override
  String get repeater_previousCommand => '上一条命令';

  @override
  String get repeater_nextCommand => '下一条命令';

  @override
  String get repeater_enterCommandFirst => '请先输入命令';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI 命令帧';

  @override
  String repeater_cliCommandError(String error) {
    return '错误：$error';
  }

  @override
  String get repeater_cliQuickGetName => '获取名称';

  @override
  String get repeater_cliQuickGetRadio => '获取无线电设置';

  @override
  String get repeater_cliQuickGetTx => '获取 TX';

  @override
  String get repeater_cliQuickNeighbors => '邻居';

  @override
  String get repeater_cliQuickVersion => '版本';

  @override
  String get repeater_cliQuickAdvertise => '发送广播';

  @override
  String get repeater_cliQuickClock => '时钟';

  @override
  String get repeater_cliHelpAdvert => '发送广播包';

  @override
  String get repeater_cliHelpReboot => '重启设备。（注意：可能会收到超时错误，属于正常现象）';

  @override
  String get repeater_cliHelpClock => '显示设备当前时间';

  @override
  String get repeater_cliHelpPassword => '设置新的管理员密码';

  @override
  String get repeater_cliHelpVersion => '显示设备版本和固件构建日期';

  @override
  String get repeater_cliHelpClearStats => '重置各种统计数据';

  @override
  String get repeater_cliHelpSetAf => '设置时间因子';

  @override
  String get repeater_cliHelpSetTx => '设置 LoRa 发射功率 (dBm)（重启生效）';

  @override
  String get repeater_cliHelpSetRepeat => '启用或禁用此节点的转发功能';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '（房间服务器）设为“开”则允许空密码登录，但只能读（不能发送）';

  @override
  String get repeater_cliHelpSetFloodMax => '设置最大传入数据包跳数（≥该值则不转发）';

  @override
  String get repeater_cliHelpSetIntThresh => '设置干扰阈值 (dB)，默认14，设为0禁用';

  @override
  String get repeater_cliHelpSetAgcResetInterval => '设置 AGC 重置间隔（秒），设为0禁用';

  @override
  String get repeater_cliHelpSetMultiAcks => '启用或禁用“多重确认”功能';

  @override
  String get repeater_cliHelpSetAdvertInterval => '设置本地广播间隔（分钟），设为0禁用';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval => '设置泛洪广播间隔（小时），设为0禁用';

  @override
  String get repeater_cliHelpSetGuestPassword => '设置/更新访客密码';

  @override
  String get repeater_cliHelpSetName => '设置广播名称';

  @override
  String get repeater_cliHelpSetLat => '设置广播纬度（十进制）';

  @override
  String get repeater_cliHelpSetLon => '设置广播经度（十进制）';

  @override
  String get repeater_cliHelpSetRadio => '完全重设无线电参数并保存，需重启生效';

  @override
  String get repeater_cliHelpSetRxDelay => '（实验性）设置接收延迟基数，设为0禁用';

  @override
  String get repeater_cliHelpSetTxDelay => '通过因子和随机时隙延迟泛洪数据包转发，降低冲突';

  @override
  String get repeater_cliHelpSetDirectTxDelay => '同 txdelay，用于直连模式数据包';

  @override
  String get repeater_cliHelpSetBridgeEnabled => '启用/禁用桥接';

  @override
  String get repeater_cliHelpSetBridgeDelay => '设置桥接转发延迟';

  @override
  String get repeater_cliHelpSetBridgeSource => '选择桥接器转发接收或发送的数据包';

  @override
  String get repeater_cliHelpSetBridgeBaud => '设置 RS232 桥接串口波特率';

  @override
  String get repeater_cliHelpSetBridgeSecret => '设置 ESPNOW 桥接密钥';

  @override
  String get repeater_cliHelpSetAdcMultiplier => '设置电池电压校正系数（特定板支持）';

  @override
  String get repeater_cliHelpTempRadio => '临时设置无线电参数指定分钟，之后恢复（不保存）';

  @override
  String get repeater_cliHelpSetPerm => '修改 ACL，权限位：0访客、1只读、2读写、3管理员';

  @override
  String get repeater_cliHelpGetBridgeType => '支持桥接模式：RS232、ESPNOW';

  @override
  String get repeater_cliHelpLogStart => '开始记录数据包到文件系统';

  @override
  String get repeater_cliHelpLogStop => '停止记录数据包';

  @override
  String get repeater_cliHelpLogErase => '删除所有记录的数据包';

  @override
  String get repeater_cliHelpNeighbors => '显示零跳广播收到的其他转发节点列表';

  @override
  String get repeater_cliHelpNeighborRemove => '从邻居列表删除第一个匹配项（通过公钥前缀）';

  @override
  String get repeater_cliHelpRegion => '（仅串口）列出所有定义区域及当前泛洪权限';

  @override
  String get repeater_cliHelpRegionLoad => '特殊多命令调用，以空行结束';

  @override
  String get repeater_cliHelpRegionGet => '搜索指定前缀的区域';

  @override
  String get repeater_cliHelpRegionPut => '添加或更新区域定义';

  @override
  String get repeater_cliHelpRegionRemove => '删除指定区域定义';

  @override
  String get repeater_cliHelpRegionAllowf => '为区域设置“泛洪”权限';

  @override
  String get repeater_cliHelpRegionDenyf => '移除区域的“泛洪”权限';

  @override
  String get repeater_cliHelpRegionHome => '返回当前“主区域”（预留）';

  @override
  String get repeater_cliHelpRegionHomeSet => '设置“主”区域';

  @override
  String get repeater_cliHelpRegionSave => '保存区域列表到存储';

  @override
  String get repeater_cliHelpGps => '显示 GPS 状态';

  @override
  String get repeater_cliHelpGpsOnOff => '切换 GPS 电源';

  @override
  String get repeater_cliHelpGpsSync => '将节点时间与 GPS 同步';

  @override
  String get repeater_cliHelpGpsSetLoc => '将节点坐标设为 GPS 坐标并保存';

  @override
  String get repeater_cliHelpGpsAdvert => '设置位置广播配置：none/share/prefs';

  @override
  String get repeater_cliHelpGpsAdvertSet => '设置广播位置配置';

  @override
  String get repeater_commandsListTitle => '命令列表';

  @override
  String get repeater_commandsListNote => '注意：多数 set 命令也有对应的 get 命令';

  @override
  String get repeater_general => '通用';

  @override
  String get repeater_settingsCategory => '设置';

  @override
  String get repeater_bridge => '桥接';

  @override
  String get repeater_logging => '日志';

  @override
  String get repeater_neighborsRepeaterOnly => '邻居（仅转发节点）';

  @override
  String get repeater_regionManagementRepeaterOnly => '区域管理（仅转发节点）';

  @override
  String get repeater_regionNote => '区域命令用于管理区域定义和权限';

  @override
  String get repeater_gpsManagement => 'GPS 管理';

  @override
  String get repeater_gpsNote => 'GPS 命令用于位置相关任务';

  @override
  String get telemetry_receivedData => '接收到的遥测数据';

  @override
  String get telemetry_requestTimeout => '遥测请求超时';

  @override
  String telemetry_errorLoading(String error) {
    return '加载遥测数据时出错：$error';
  }

  @override
  String get telemetry_noData => '暂无遥测数据';

  @override
  String telemetry_channelTitle(int channel) {
    return '频道 $channel';
  }

  @override
  String get telemetry_batteryLabel => '电池';

  @override
  String get telemetry_voltageLabel => '电压';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU 温度';

  @override
  String get telemetry_temperatureLabel => '温度';

  @override
  String get telemetry_currentLabel => '电流';

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
  String get neighbors_receivedData => '已接收邻居信息';

  @override
  String get neighbors_requestTimedOut => '邻居请求超时';

  @override
  String neighbors_errorLoading(String error) {
    return '加载邻居时出错：$error';
  }

  @override
  String get neighbors_repeatersNeighbors => '转发节点的邻居';

  @override
  String get neighbors_noData => '暂无邻居信息';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '未知 $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return '听到：$time前';
  }

  @override
  String get channelPath_title => '数据包路径';

  @override
  String get channelPath_viewMap => '查看地图';

  @override
  String get channelPath_otherObservedPaths => '其他观察到的路径';

  @override
  String get channelPath_repeaterHops => '转发节点跳数';

  @override
  String get channelPath_noHopDetails => '此数据包未提供详细信息';

  @override
  String get channelPath_messageDetails => '消息详情';

  @override
  String get channelPath_senderLabel => '发送者';

  @override
  String get channelPath_timeLabel => '时间';

  @override
  String get channelPath_repeatsLabel => '重复';

  @override
  String channelPath_pathLabel(int index) {
    return '路径 $index';
  }

  @override
  String get channelPath_observedLabel => '观察到的';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return '观察到的路径 $index • $hops';
  }

  @override
  String get channelPath_noLocationData => '无位置信息';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => '未知';

  @override
  String get channelPath_floodPath => '泛洪';

  @override
  String get channelPath_directPath => '直连';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 / $total 跳';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed / $total 跳';
  }

  @override
  String get channelPath_mapTitle => '路径地图';

  @override
  String get channelPath_noRepeaterLocations => '此路径上没有可用的转发节点位置信息';

  @override
  String channelPath_primaryPath(int index) {
    return '路径 $index（主要）';
  }

  @override
  String get channelPath_pathLabelTitle => '路径';

  @override
  String get channelPath_observedPathHeader => '观察到的路径';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable => '此数据包暂无详细信息';

  @override
  String get channelPath_unknownRepeater => '未知转发节点';

  @override
  String get community_title => '社区';

  @override
  String get community_create => '创建社区';

  @override
  String get community_createDesc => '创建新社区并通过二维码分享。';

  @override
  String get community_join => '加入';

  @override
  String get community_joinTitle => '加入社区';

  @override
  String community_joinConfirmation(String name) {
    return '是否加入社区 \"$name\"？';
  }

  @override
  String get community_scanQr => '扫描社区二维码';

  @override
  String get community_scanInstructions => '将摄像头对准社区的二维码';

  @override
  String get community_showQr => '显示二维码';

  @override
  String get community_publicChannel => '社区公共频道';

  @override
  String get community_hashtagChannel => '社区标签频道';

  @override
  String get community_name => '社区名称';

  @override
  String get community_enterName => '请输入社区名称';

  @override
  String community_created(String name) {
    return '社区 \"$name\" 已创建';
  }

  @override
  String community_joined(String name) {
    return '已加入社区 \"$name\"';
  }

  @override
  String get community_qrTitle => '分享社区';

  @override
  String community_qrInstructions(String name) {
    return '扫描此二维码加入 \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint => '仅社区成员可加入社区标签频道。';

  @override
  String get community_invalidQrCode => '无效的社区二维码';

  @override
  String get community_alreadyMember => '已是成员';

  @override
  String community_alreadyMemberMessage(String name) {
    return '您已是 \"$name\" 的成员。';
  }

  @override
  String get community_addPublicChannel => '添加公共频道';

  @override
  String get community_addPublicChannelHint => '自动添加此社区的公共频道';

  @override
  String get community_noCommunities => '尚未加入任何社区。';

  @override
  String get community_scanOrCreate => '扫描二维码或创建社区以开始。';

  @override
  String get community_manageCommunities => '管理社区';

  @override
  String get community_delete => '退出社区';

  @override
  String community_deleteConfirm(String name) {
    return '是否退出 \"$name\"？';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return '这将同时删除 $count 个频道及其所有消息。';
  }

  @override
  String community_deleted(String name) {
    return '已退出社区 \"$name\"';
  }

  @override
  String get community_regenerateSecret => '重新生成密钥';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '是否为 \"$name\" 重新生成密钥？所有成员需扫描新的二维码才能继续通信。';
  }

  @override
  String get community_regenerate => '重新生成';

  @override
  String community_secretRegenerated(String name) {
    return '已为 \"$name\" 重新生成密钥';
  }

  @override
  String get community_updateSecret => '更新密钥';

  @override
  String community_secretUpdated(String name) {
    return '“$name”的密钥已更新';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '扫描新二维码以更新 \"$name\" 的密钥';
  }

  @override
  String get community_addHashtagChannel => '添加标签频道';

  @override
  String get community_addHashtagChannelDesc => '为此社区创建标签频道';

  @override
  String get community_selectCommunity => '选择社区';

  @override
  String get community_regularHashtag => '普通标签';

  @override
  String get community_regularHashtagDesc => '公共标签频道（任何人都可参与）';

  @override
  String get community_communityHashtag => '社区标签';

  @override
  String get community_communityHashtagDesc => '仅限社区成员';

  @override
  String community_forCommunity(String name) {
    return '为 $name';
  }

  @override
  String get listFilter_tooltip => '筛选与排序';

  @override
  String get listFilter_sortBy => '排序方式';

  @override
  String get listFilter_latestMessages => '最新消息';

  @override
  String get listFilter_heardRecently => '最近听到';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => '筛选';

  @override
  String get listFilter_all => '全部';

  @override
  String get listFilter_favorites => '收藏';

  @override
  String get listFilter_addToFavorites => '添加到收藏';

  @override
  String get listFilter_removeFromFavorites => '从收藏中移除';

  @override
  String get listFilter_users => '用户';

  @override
  String get listFilter_repeaters => '转发节点';

  @override
  String get listFilter_roomServers => '房间服务器';

  @override
  String get listFilter_unreadOnly => '仅显示未读';

  @override
  String get listFilter_newGroup => '新建群聊';

  @override
  String get pathTrace_you => '我自己';

  @override
  String get pathTrace_failed => '路径追踪失败。';

  @override
  String get pathTrace_notAvailable => '无法获取路径信息。';

  @override
  String get pathTrace_refreshTooltip => '刷新路径追踪';

  @override
  String get pathTrace_someHopsNoLocation => '某些跳缺少位置信息！';

  @override
  String get pathTrace_clearTooltip => '清除路径';

  @override
  String get losSelectStartEnd => '选择 LOS 的起始节点和结束节点。';

  @override
  String losRunFailed(String error) {
    return '视线检查失败：$error';
  }

  @override
  String get losClearAllPoints => '清除所有点';

  @override
  String get losRunToViewElevationProfile => '运行 LOS 查看高程剖面';

  @override
  String get losMenuTitle => '服务水平菜单';

  @override
  String get losMenuSubtitle => '点击节点或长按地图以获取自定义点';

  @override
  String get losShowDisplayNodes => '显示显示节点';

  @override
  String get losCustomPoints => '自定义积分';

  @override
  String losCustomPointLabel(int index) {
    return '自定义 $index';
  }

  @override
  String get losPointA => 'A点';

  @override
  String get losPointB => 'B点';

  @override
  String losAntennaA(String value, String unit) {
    return '天线 A： $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return '天线 B：$value $unit';
  }

  @override
  String get losRun => '运行视距';

  @override
  String get losNoElevationData => '无海拔数据';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit，清除 LOS，最小间隙 $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit，被 $obstruction $heightUnit 阻止';
  }

  @override
  String get losStatusChecking => '洛斯：正在检查...';

  @override
  String get losStatusNoData => 'LOS：无数据';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS：$clear/$total 清除，$blocked 阻塞，$unknown 未知';
  }

  @override
  String get losErrorElevationUnavailable => '一个或多个样本的海拔数据不可用。';

  @override
  String get losErrorInvalidInput => '用于 LOS 计算的点/高程数据无效。';

  @override
  String get losRenameCustomPoint => '重命名自定义点';

  @override
  String get losPointName => '点名称';

  @override
  String get losShowPanelTooltip => '显示 LOS 面板';

  @override
  String get losHidePanelTooltip => '隐藏 LOS 面板';

  @override
  String get losElevationAttribution => '高程数据：Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => '无线电地平线';

  @override
  String get losLegendLosBeam => '视距波束';

  @override
  String get losLegendTerrain => '地形';

  @override
  String get losFrequencyLabel => '频率';

  @override
  String get losFrequencyInfoTooltip => '查看计算详情';

  @override
  String get losFrequencyDialogTitle => '无线电地平线计算';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return '从 $baselineFreq MHz 处的 k=$baselineK 开始，计算调整当前 $frequencyMHz MHz 频段的 k 因子，该因子定义了弯曲的无线电范围上限。';
  }

  @override
  String get contacts_pathTrace => '路径追踪';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Trace 转发节点';

  @override
  String get contacts_repeaterPing => 'Ping 转发节点';

  @override
  String get contacts_roomPathTrace => 'Trace 房间服务器';

  @override
  String get contacts_roomPing => 'Ping 房间服务器';

  @override
  String get contacts_chatTraceRoute => '路由追踪';

  @override
  String contacts_pathTraceTo(String name) {
    return '追踪至 $name 的路径';
  }

  @override
  String get contacts_clipboardEmpty => '剪贴板为空';

  @override
  String get contacts_invalidAdvertFormat => '无效的联系人信息格式';

  @override
  String get contacts_contactImported => '联系人已导入';

  @override
  String get contacts_contactImportFailed => '导入联系人失败。';

  @override
  String get contacts_zeroHopAdvert => '发送零跳广播';

  @override
  String get contacts_floodAdvert => '发送泛洪广播';

  @override
  String get contacts_copyAdvertToClipboard => '复制广播到剪贴板';

  @override
  String get contacts_addContactFromClipboard => '从剪贴板添加联系人';

  @override
  String get contacts_ShareContact => '复制联系人信息到剪贴板';

  @override
  String get contacts_ShareContactZeroHop => '通过广播分享联系人';

  @override
  String get contacts_zeroHopContactAdvertSent => '零跳广播已发送';

  @override
  String get contacts_zeroHopContactAdvertFailed => '发送联系人广播失败。';

  @override
  String get contacts_contactAdvertCopied => '广播已复制到剪贴板。';

  @override
  String get contacts_contactAdvertCopyFailed => '复制广播到剪贴板失败。';

  @override
  String get notification_activityTitle => 'MeshCore 活动';

  @override
  String notification_messagesCount(int count) {
    return '$count 条消息';
  }

  @override
  String notification_channelMessagesCount(int count) {
    return '$count 条频道消息';
  }

  @override
  String notification_newNodesCount(int count) {
    return '$count 个新节点';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return '发现新 $contactType';
  }

  @override
  String get notification_receivedNewMessage => '收到新消息';

  @override
  String get settings_gpxExportRepeaters => '导出转发节点/房间服务器到 GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle => '导出带位置的转发节点/房间服务器到 GPX 文件';

  @override
  String get settings_gpxExportContacts => '导出伙伴到 GPX';

  @override
  String get settings_gpxExportContactsSubtitle => '导出带位置的伙伴到 GPX 文件';

  @override
  String get settings_gpxExportAll => '导出所有联系人到 GPX';

  @override
  String get settings_gpxExportAllSubtitle => '导出所有带位置的联系人到 GPX 文件';

  @override
  String get settings_gpxExportSuccess => 'GPX 文件导出成功';

  @override
  String get settings_gpxExportNoContacts => '没有可导出的联系人';

  @override
  String get settings_gpxExportNotAvailable => '您的设备/操作系统不支持';

  @override
  String get settings_gpxExportError => '导出时出错';

  @override
  String get settings_gpxExportRepeatersRoom => '转发节点与房间服务器位置';

  @override
  String get settings_gpxExportChat => '伙伴位置';

  @override
  String get settings_gpxExportAllContacts => '所有联系人位置';

  @override
  String get settings_gpxExportShareText => '来自 MeshCore Open 的地图数据导出';

  @override
  String get settings_gpxExportShareSubject => 'MeshCore Open GPX 地图数据导出';

  @override
  String get snrIndicator_nearByRepeaters => '附近的重复器';

  @override
  String get snrIndicator_lastSeen => '最近访问';

  @override
  String get contactsSettings_title => '联系人设置';

  @override
  String get contactsSettings_autoAddTitle => '自动发现';

  @override
  String get contactsSettings_otherTitle => '其他联系人相关设置';

  @override
  String get contactsSettings_autoAddUsersTitle => '自动添加用户';

  @override
  String get contactsSettings_autoAddUsersSubtitle => '允许伴侣自动添加发现的用户';

  @override
  String get contactsSettings_autoAddRepeatersTitle => '自动添加重复器';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle => '允许伴侣自动添加发现的重复器';

  @override
  String get contactsSettings_autoAddRoomServersTitle => '自动添加房间服务器';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle => '允许伴侣自动添加发现的房间服务器';

  @override
  String get contactsSettings_autoAddSensorsTitle => '自动添加传感器';

  @override
  String get contactsSettings_autoAddSensorsSubtitle => '允许伴侣自动添加发现的传感器';

  @override
  String get contactsSettings_overwriteOldestTitle => '覆盖最旧的';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      '当联系人列表已满时，将替换最老的非收藏联系人。';

  @override
  String get discoveredContacts_Title => '已发现的联系人';

  @override
  String get discoveredContacts_noMatching => '没有匹配的联系人';

  @override
  String get discoveredContacts_searchHint => '搜索已发现的联系人';

  @override
  String get discoveredContacts_contactAdded => '联系人已添加';

  @override
  String get discoveredContacts_addContact => '添加联系人';

  @override
  String get discoveredContacts_copyContact => '复制联系人到剪贴板';

  @override
  String get discoveredContacts_deleteContact => '删除联系人';

  @override
  String get discoveredContacts_deleteContactAll => '删除所有发现的联系人';

  @override
  String get discoveredContacts_deleteContactAllContent => '您确定要删除所有发现的联系人吗？';
}
