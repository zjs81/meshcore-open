// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Contacts';

  @override
  String get nav_channels => 'Channels';

  @override
  String get nav_map => 'Map';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Connect';

  @override
  String get common_unknownDevice => 'Unknown Device';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_deleteAll => 'Delete All';

  @override
  String get common_close => 'Close';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_add => 'Add';

  @override
  String get common_settings => 'Settings';

  @override
  String get common_disconnect => 'Disconnect';

  @override
  String get common_connected => 'Connected';

  @override
  String get common_disconnected => 'Disconnected';

  @override
  String get common_create => 'Create';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_share => 'Share';

  @override
  String get common_copy => 'Copy';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_hide => 'Hide';

  @override
  String get common_remove => 'Remove';

  @override
  String get common_enable => 'Enable';

  @override
  String get common_disable => 'Disable';

  @override
  String get common_reboot => 'Reboot';

  @override
  String get common_loading => 'Loading...';

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
  String get usbScreenTitle => 'Connect over USB';

  @override
  String get usbScreenSubtitle =>
      'Choose a detected serial device and connect directly to your MeshCore node.';

  @override
  String get usbScreenStatus => 'Select a USB device';

  @override
  String get usbScreenNote =>
      'USB serial is active on supported Android devices and desktop platforms.';

  @override
  String get usbScreenEmptyState =>
      'No USB devices found. Plug one in and refresh.';

  @override
  String get usbErrorPermissionDenied => 'USB permission was denied.';

  @override
  String get usbErrorDeviceMissing =>
      'The selected USB device is no longer available.';

  @override
  String get usbErrorInvalidPort => 'Select a valid USB device.';

  @override
  String get usbErrorBusy =>
      'Another USB connection request is already in progress.';

  @override
  String get usbErrorNotConnected => 'No USB device is connected.';

  @override
  String get usbErrorOpenFailed => 'Failed to open the selected USB device.';

  @override
  String get usbErrorConnectFailed =>
      'Failed to connect to the selected USB device.';

  @override
  String get usbErrorUnsupported =>
      'USB serial is not supported on this platform.';

  @override
  String get usbErrorAlreadyActive => 'A USB connection is already active.';

  @override
  String get usbErrorNoDeviceSelected => 'No USB device was selected.';

  @override
  String get usbErrorPortClosed => 'The USB connection is not open.';

  @override
  String get usbErrorConnectTimedOut =>
      'Connection timed out. Make sure the device has USB Companion firmware.';

  @override
  String get usbFallbackDeviceName => 'Web Serial Device';

  @override
  String get usbStatus_notConnected => 'Select a USB device';

  @override
  String get usbStatus_connecting => 'Connecting to USB device...';

  @override
  String get usbStatus_searching => 'Searching for USB devices...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB connection failed: $error';
  }

  @override
  String get scanner_scanning => 'Scanning for devices...';

  @override
  String get scanner_connecting => 'Connecting...';

  @override
  String get scanner_disconnecting => 'Disconnecting...';

  @override
  String get scanner_notConnected => 'Not connected';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Connected to $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Searching for MeshCore devices...';

  @override
  String get scanner_tapToScan => 'Tap Scan to find MeshCore devices';

  @override
  String scanner_connectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get scanner_stop => 'Stop';

  @override
  String get scanner_scan => 'Scan';

  @override
  String get scanner_bluetoothOff => 'Bluetooth is off';

  @override
  String get scanner_bluetoothOffMessage =>
      'Please turn on Bluetooth to scan for devices';

  @override
  String get scanner_chromeRequired => 'Chrome Browser Required';

  @override
  String get scanner_chromeRequiredMessage =>
      'This web application requires Google Chrome or a Chromium-based browser for Bluetooth support.';

  @override
  String get scanner_enableBluetooth => 'Enable Bluetooth';

  @override
  String get device_quickSwitch => 'Quick switch';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_deviceInfo => 'Device Info';

  @override
  String get settings_appSettings => 'App Settings';

  @override
  String get settings_appSettingsSubtitle =>
      'Notifications, messaging, and map preferences';

  @override
  String get settings_nodeSettings => 'Node Settings';

  @override
  String get settings_nodeName => 'Node Name';

  @override
  String get settings_nodeNameNotSet => 'Not set';

  @override
  String get settings_nodeNameHint => 'Enter node name';

  @override
  String get settings_nodeNameUpdated => 'Name updated';

  @override
  String get settings_radioSettings => 'Radio Settings';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequency, power, spreading factor';

  @override
  String get settings_radioSettingsUpdated => 'Radio settings updated';

  @override
  String get settings_location => 'Location';

  @override
  String get settings_locationSubtitle => 'GPS coordinates';

  @override
  String get settings_locationUpdated => 'Location and GPS settings updated';

  @override
  String get settings_locationBothRequired =>
      'Enter both latitude and longitude.';

  @override
  String get settings_locationInvalid => 'Invalid latitude or longitude.';

  @override
  String get settings_locationGPSEnable => 'GPS Enable';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Enables GPS to automatically update location.';

  @override
  String get settings_locationIntervalSec => 'Interval for GPS (Seconds)';

  @override
  String get settings_locationIntervalInvalid =>
      'Interval must be at least 60 seconds, and less than 86400 seconds.';

  @override
  String get settings_latitude => 'Latitude';

  @override
  String get settings_longitude => 'Longitude';

  @override
  String get settings_contactSettings => 'Contact Settings';

  @override
  String get settings_contactSettingsSubtitle =>
      'Settings for how contacts are added.';

  @override
  String get settings_privacyMode => 'Privacy Mode';

  @override
  String get settings_privacyModeSubtitle =>
      'Hide name/location in advertisements';

  @override
  String get settings_privacyModeToggle =>
      'Toggle privacy mode to hide your name and location in advertisements.';

  @override
  String get settings_privacyModeEnabled => 'Privacy mode enabled';

  @override
  String get settings_privacyModeDisabled => 'Privacy mode disabled';

  @override
  String get settings_actions => 'Actions';

  @override
  String get settings_sendAdvertisement => 'Send Advertisement';

  @override
  String get settings_sendAdvertisementSubtitle => 'Broadcast presence now';

  @override
  String get settings_advertisementSent => 'Advertisement sent';

  @override
  String get settings_syncTime => 'Sync Time';

  @override
  String get settings_syncTimeSubtitle => 'Set device clock to phone time';

  @override
  String get settings_timeSynchronized => 'Time synchronized';

  @override
  String get settings_refreshContacts => 'Refresh Contacts';

  @override
  String get settings_refreshContactsSubtitle =>
      'Reload contact list from device';

  @override
  String get settings_rebootDevice => 'Reboot Device';

  @override
  String get settings_rebootDeviceSubtitle => 'Restart the MeshCore device';

  @override
  String get settings_rebootDeviceConfirm =>
      'Are you sure you want to reboot the device? You will be disconnected.';

  @override
  String get settings_debug => 'Debug';

  @override
  String get settings_bleDebugLog => 'BLE Debug Log';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE commands, responses, and raw data';

  @override
  String get settings_appDebugLog => 'App Debug Log';

  @override
  String get settings_appDebugLogSubtitle => 'Application debug messages';

  @override
  String get settings_about => 'About';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore Open Source Project';

  @override
  String get settings_aboutDescription =>
      'An open-source Flutter client for MeshCore LoRa mesh networking devices.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS elevation data: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Name';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Battery';

  @override
  String get settings_infoPublicKey => 'Public Key';

  @override
  String get settings_infoContactsCount => 'Contacts Count';

  @override
  String get settings_infoChannelCount => 'Channel Count';

  @override
  String get settings_presets => 'Presets';

  @override
  String get settings_frequency => 'Frequency (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Invalid frequency (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bandwidth';

  @override
  String get settings_spreadingFactor => 'Spreading Factor';

  @override
  String get settings_codingRate => 'Coding Rate';

  @override
  String get settings_txPower => 'TX Power (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Invalid TX power (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Off-Grid Repeat';

  @override
  String get settings_clientRepeatSubtitle =>
      'Allow this device to repeat mesh packets for others';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Off-grid repeat requires 433, 869, or 918 MHz frequency';

  @override
  String settings_error(String message) {
    return 'Error: $message';
  }

  @override
  String get appSettings_title => 'App Settings';

  @override
  String get appSettings_appearance => 'Appearance';

  @override
  String get appSettings_theme => 'Theme';

  @override
  String get appSettings_themeSystem => 'System default';

  @override
  String get appSettings_themeLight => 'Light';

  @override
  String get appSettings_themeDark => 'Dark';

  @override
  String get appSettings_language => 'Language';

  @override
  String get appSettings_languageSystem => 'System default';

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
  String get appSettings_languageRu => 'Русский';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get appSettings_enableMessageTracing => 'Enable Message Tracing';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Show detailed routing and timing metadata for messages';

  @override
  String get appSettings_notifications => 'Notifications';

  @override
  String get appSettings_enableNotifications => 'Enable Notifications';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Receive notifications for messages and adverts';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Notification permission denied';

  @override
  String get appSettings_notificationsEnabled => 'Notifications enabled';

  @override
  String get appSettings_notificationsDisabled => 'Notifications disabled';

  @override
  String get appSettings_messageNotifications => 'Message Notifications';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Show notification when receiving new messages';

  @override
  String get appSettings_channelMessageNotifications =>
      'Channel Message Notifications';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Show notification when receiving channel messages';

  @override
  String get appSettings_advertisementNotifications =>
      'Advertisement Notifications';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Show notification when new nodes are discovered';

  @override
  String get appSettings_messaging => 'Messaging';

  @override
  String get appSettings_clearPathOnMaxRetry => 'Clear Path on Max Retry';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Reset contact path after 5 failed send attempts';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Paths will be cleared after 5 failed retries';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Paths will not be auto-cleared';

  @override
  String get appSettings_autoRouteRotation => 'Auto Route Rotation';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Cycle between best paths and flood mode';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Auto route rotation enabled';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Auto route rotation disabled';

  @override
  String get appSettings_battery => 'Battery';

  @override
  String get appSettings_batteryChemistry => 'Battery Chemistry';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Set per device ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Connect to a device to choose';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => 'Map Display';

  @override
  String get appSettings_showRepeaters => 'Show Repeaters';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Display repeater nodes on the map';

  @override
  String get appSettings_showChatNodes => 'Show Chat Nodes';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Display chat nodes on the map';

  @override
  String get appSettings_showOtherNodes => 'Show Other Nodes';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Display other node types on the map';

  @override
  String get appSettings_timeFilter => 'Time Filter';

  @override
  String get appSettings_timeFilterShowAll => 'Show all nodes';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Show nodes from last $hours hours';
  }

  @override
  String get appSettings_mapTimeFilter => 'Map Time Filter';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Show nodes discovered within:';

  @override
  String get appSettings_allTime => 'All time';

  @override
  String get appSettings_lastHour => 'Last hour';

  @override
  String get appSettings_last6Hours => 'Last 6 hours';

  @override
  String get appSettings_last24Hours => 'Last 24 hours';

  @override
  String get appSettings_lastWeek => 'Last week';

  @override
  String get appSettings_offlineMapCache => 'Offline Map Cache';

  @override
  String get appSettings_unitsTitle => 'Units';

  @override
  String get appSettings_unitsMetric => 'Metric (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'No area selected';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Area selected (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Debug';

  @override
  String get appSettings_appDebugLogging => 'App Debug Logging';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Log app debug messages for troubleshooting';

  @override
  String get appSettings_appDebugLoggingEnabled => 'App debug logging enabled';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'App debug logging disabled';

  @override
  String get contacts_title => 'Contacts';

  @override
  String get contacts_noContacts => 'No contacts yet';

  @override
  String get contacts_contactsWillAppear =>
      'Contacts will appear when devices advertise';

  @override
  String get contacts_unread => 'Unread';

  @override
  String get contacts_searchContactsNoNumber => 'Search Contacts...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Search $number$str Contacts...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Search $number$str Favorites...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Search $number$str Users...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Search $number$str Repeaters...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Search $number$str Room servers...';
  }

  @override
  String get contacts_noUnreadContacts => 'No unread contacts';

  @override
  String get contacts_noContactsFound => 'No contacts or groups found';

  @override
  String get contacts_deleteContact => 'Delete Contact';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Remove $contactName from contacts?';
  }

  @override
  String get contacts_manageRepeater => 'Manage Repeater';

  @override
  String get contacts_manageRoom => 'Manage Room Server';

  @override
  String get contacts_roomLogin => 'Room Server Login';

  @override
  String get contacts_openChat => 'Open Chat';

  @override
  String get contacts_editGroup => 'Edit Group';

  @override
  String get contacts_deleteGroup => 'Delete Group';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Remove \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'New Group';

  @override
  String get contacts_groupName => 'Group name';

  @override
  String get contacts_groupNameRequired => 'Group name is required';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Group \"$name\" already exists';
  }

  @override
  String get contacts_filterContacts => 'Filter contacts...';

  @override
  String get contacts_noContactsMatchFilter => 'No contacts match your filter';

  @override
  String get contacts_noMembers => 'No members';

  @override
  String get contacts_lastSeenNow => 'recently';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 hour';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours hours';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 day';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days days';
  }

  @override
  String get channels_title => 'Channels';

  @override
  String get channels_noChannelsConfigured => 'No channels configured';

  @override
  String get channels_addPublicChannel => 'Add Public Channel';

  @override
  String get channels_searchChannels => 'Search channels...';

  @override
  String get channels_noChannelsFound => 'No channels found';

  @override
  String channels_channelIndex(int index) {
    return 'Channel $index';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag channel';

  @override
  String get channels_public => 'Public';

  @override
  String get channels_private => 'Private';

  @override
  String get channels_publicChannel => 'Public channel';

  @override
  String get channels_privateChannel => 'Private channel';

  @override
  String get channels_editChannel => 'Edit channel';

  @override
  String get channels_muteChannel => 'Mute channel';

  @override
  String get channels_unmuteChannel => 'Unmute channel';

  @override
  String get channels_deleteChannel => 'Delete channel';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Failed to delete channel \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Channel \"$name\" deleted';
  }

  @override
  String get channels_addChannel => 'Add Channel';

  @override
  String get channels_channelIndexLabel => 'Channel Index';

  @override
  String get channels_channelName => 'Channel Name';

  @override
  String get channels_usePublicChannel => 'Use Public Channel';

  @override
  String get channels_standardPublicPsk => 'Standard public PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Generate random PSK';

  @override
  String get channels_enterChannelName => 'Please enter a channel name';

  @override
  String get channels_pskMustBe32Hex => 'PSK must be 32 hex characters';

  @override
  String channels_channelAdded(String name) {
    return 'Channel \"$name\" added';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Edit Channel $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ compression';

  @override
  String channels_channelUpdated(String name) {
    return 'Channel \"$name\" updated';
  }

  @override
  String get channels_publicChannelAdded => 'Public channel added';

  @override
  String get channels_sortBy => 'Sort by';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Latest messages';

  @override
  String get channels_sortUnread => 'Unread';

  @override
  String get channels_createPrivateChannel => 'Create a Private Channel';

  @override
  String get channels_createPrivateChannelDesc => 'Secured with a secret key.';

  @override
  String get channels_joinPrivateChannel => 'Join a Private Channel';

  @override
  String get channels_joinPrivateChannelDesc => 'Manually enter a secret key.';

  @override
  String get channels_joinPublicChannel => 'Join the Public Channel';

  @override
  String get channels_joinPublicChannelDesc => 'Anyone can join this channel.';

  @override
  String get channels_joinHashtagChannel => 'Join a Hashtag Channel';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Anyone can join hashtag channels.';

  @override
  String get channels_scanQrCode => 'Scan a QR Code';

  @override
  String get channels_scanQrCodeComingSoon => 'Coming soon';

  @override
  String get channels_enterHashtag => 'Enter hashtag';

  @override
  String get channels_hashtagHint => 'e.g. #team';

  @override
  String get chat_noMessages => 'No messages yet';

  @override
  String get chat_sendMessageToStart => 'Send a message to get started';

  @override
  String get chat_originalMessageNotFound => 'Original message not found';

  @override
  String chat_replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get chat_location => 'Location';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Send a message to $contactName';
  }

  @override
  String get chat_typeMessage => 'Type a message...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Message too long (max $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Message copied';

  @override
  String get chat_messageDeleted => 'Message deleted';

  @override
  String get chat_retryingMessage => 'Retrying message';

  @override
  String chat_retryCount(int current, int max) {
    return 'Retry $current/$max';
  }

  @override
  String get chat_sendGif => 'Send GIF';

  @override
  String get chat_reply => 'Reply';

  @override
  String get chat_addReaction => 'Add Reaction';

  @override
  String get chat_me => 'Me';

  @override
  String get emojiCategorySmileys => 'Smileys';

  @override
  String get emojiCategoryGestures => 'Gestures';

  @override
  String get emojiCategoryHearts => 'Hearts';

  @override
  String get emojiCategoryObjects => 'Objects';

  @override
  String get gifPicker_title => 'Choose a GIF';

  @override
  String get gifPicker_searchHint => 'Search GIFs...';

  @override
  String get gifPicker_poweredBy => 'Powered by GIPHY';

  @override
  String get gifPicker_noGifsFound => 'No GIFs found';

  @override
  String get gifPicker_failedLoad => 'Failed to load GIFs';

  @override
  String get gifPicker_failedSearch => 'Failed to search GIFs';

  @override
  String get gifPicker_noInternet => 'No internet connection';

  @override
  String get debugLog_appTitle => 'App Debug Log';

  @override
  String get debugLog_bleTitle => 'BLE Debug Log';

  @override
  String get debugLog_copyLog => 'Copy log';

  @override
  String get debugLog_clearLog => 'Clear log';

  @override
  String get debugLog_copied => 'Debug log copied';

  @override
  String get debugLog_bleCopied => 'BLE log copied';

  @override
  String get debugLog_noEntries => 'No debug logs yet';

  @override
  String get debugLog_enableInSettings =>
      'Enable app debug logging in settings';

  @override
  String get debugLog_frames => 'Frames';

  @override
  String get debugLog_rawLogRx => 'Raw Log-RX';

  @override
  String get debugLog_noBleActivity => 'No BLE activity yet';

  @override
  String debugFrame_length(int count) {
    return 'Frame Length: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Command: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Text Message Frame:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destination PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Timestamp: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flags: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Text Type: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Plain';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex Dump:';

  @override
  String get chat_pathManagement => 'Path Management';

  @override
  String get chat_ShowAllPaths => 'Show all paths';

  @override
  String get chat_routingMode => 'Routing mode';

  @override
  String get chat_autoUseSavedPath => 'Auto (use saved path)';

  @override
  String get chat_forceFloodMode => 'Force Flood Mode';

  @override
  String get chat_recentAckPaths => 'Recent ACK Paths (tap to use):';

  @override
  String get chat_pathHistoryFull =>
      'Path history is full. Remove entries to add new ones.';

  @override
  String get chat_hopSingular => 'hop';

  @override
  String get chat_hopPlural => 'hops';

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
  String get chat_successes => 'successes';

  @override
  String get chat_removePath => 'Remove path';

  @override
  String get chat_noPathHistoryYet =>
      'No path history yet.\nSend a message to discover paths.';

  @override
  String get chat_pathActions => 'Path Actions:';

  @override
  String get chat_setCustomPath => 'Set Custom Path';

  @override
  String get chat_setCustomPathSubtitle => 'Manually specify routing path';

  @override
  String get chat_clearPath => 'Clear Path';

  @override
  String get chat_clearPathSubtitle => 'Force rediscovery on next send';

  @override
  String get chat_pathCleared =>
      'Path cleared. Next message will rediscover route.';

  @override
  String get chat_floodModeSubtitle => 'Use routing toggle in app bar';

  @override
  String get chat_floodModeEnabled =>
      'Flood mode enabled. Toggle back via routing icon in app bar.';

  @override
  String get chat_fullPath => 'Full Path';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Path details not available yet. Try sending a message to refresh.';

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
  String get chat_pathSavedLocally => 'Saved locally. Connect to sync.';

  @override
  String get chat_pathDeviceConfirmed => 'Device confirmed.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Device not confirmed yet.';

  @override
  String get chat_type => 'Type';

  @override
  String get chat_path => 'Path';

  @override
  String get chat_publicKey => 'Public Key';

  @override
  String get chat_compressOutgoingMessages => 'Compress outgoing messages';

  @override
  String get chat_floodForced => 'Flood (forced)';

  @override
  String get chat_directForced => 'Direct (forced)';

  @override
  String chat_hopsForced(int count) {
    return '$count hops (forced)';
  }

  @override
  String get chat_floodAuto => 'Flood (auto)';

  @override
  String get chat_direct => 'Direct';

  @override
  String get chat_poiShared => 'POI Shared';

  @override
  String chat_unread(int count) {
    return 'Unread: $count';
  }

  @override
  String get chat_openLink => 'Open Link?';

  @override
  String get chat_openLinkConfirmation =>
      'Do you want to open this link in your browser?';

  @override
  String get chat_open => 'Open';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Could not open link: $url';
  }

  @override
  String get chat_invalidLink => 'Invalid link format';

  @override
  String get map_title => 'Node Map';

  @override
  String get map_lineOfSight => 'Line of Sight';

  @override
  String get map_losScreenTitle => 'Line of Sight';

  @override
  String get map_noNodesWithLocation => 'No nodes with location data';

  @override
  String get map_nodesNeedGps =>
      'Nodes need to share their GPS coordinates\nto appear on the map';

  @override
  String map_nodesCount(int count) {
    return 'Nodes: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pins: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repeater';

  @override
  String get map_room => 'Room';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Pin (Private)';

  @override
  String get map_pinPublic => 'Pin (Public)';

  @override
  String get map_lastSeen => 'Last Seen';

  @override
  String get map_disconnectConfirm =>
      'Are you sure you want to disconnect from this device?';

  @override
  String get map_from => 'From';

  @override
  String get map_source => 'Source';

  @override
  String get map_flags => 'Flags';

  @override
  String get map_shareMarkerHere => 'Share marker here';

  @override
  String get map_pinLabel => 'Pin label';

  @override
  String get map_label => 'Label';

  @override
  String get map_pointOfInterest => 'Point of interest';

  @override
  String get map_sendToContact => 'Send to contact';

  @override
  String get map_sendToChannel => 'Send to channel';

  @override
  String get map_noChannelsAvailable => 'No channels available';

  @override
  String get map_publicLocationShare => 'Public location share';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'You are about to share a location in $channelLabel. This channel is public and anyone with the PSK can see it.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Connect to a device to share markers';

  @override
  String get map_filterNodes => 'Filter Nodes';

  @override
  String get map_nodeTypes => 'Node Types';

  @override
  String get map_chatNodes => 'Chat Nodes';

  @override
  String get map_repeaters => 'Repeaters';

  @override
  String get map_otherNodes => 'Other Nodes';

  @override
  String get map_keyPrefix => 'Key Prefix';

  @override
  String get map_filterByKeyPrefix => 'Filter by key prefix';

  @override
  String get map_publicKeyPrefix => 'Public key prefix';

  @override
  String get map_markers => 'Markers';

  @override
  String get map_showSharedMarkers => 'Show shared markers';

  @override
  String get map_showGuessedLocations => 'Show guessed node locations';

  @override
  String get map_showDiscoveryContacts => 'Show Discovery Contacts';

  @override
  String get map_guessedLocation => 'Guessed location';

  @override
  String get map_lastSeenTime => 'Last Seen Time';

  @override
  String get map_sharedPin => 'Shared pin';

  @override
  String get map_joinRoom => 'Join Room';

  @override
  String get map_manageRepeater => 'Manage Repeater';

  @override
  String get map_tapToAdd => 'Tap on nodes to add them to the path.';

  @override
  String get map_runTrace => 'Run Path Trace';

  @override
  String get map_removeLast => 'Remove Last';

  @override
  String get map_pathTraceCancelled => 'Path trace cancelled.';

  @override
  String get mapCache_title => 'Offline Map Cache';

  @override
  String get mapCache_selectAreaFirst => 'Select an area to cache first';

  @override
  String get mapCache_noTilesToDownload => 'No tiles to download for this area';

  @override
  String get mapCache_downloadTilesTitle => 'Download tiles';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Download $count tiles for offline use?';
  }

  @override
  String get mapCache_downloadAction => 'Download';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Cached $count tiles';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Cached $downloaded tiles ($failed failed)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Clear offline cache';

  @override
  String get mapCache_clearOfflineCachePrompt => 'Remove all cached map tiles?';

  @override
  String get mapCache_offlineCacheCleared => 'Offline cache cleared';

  @override
  String get mapCache_noAreaSelected => 'No area selected';

  @override
  String get mapCache_cacheArea => 'Cache Area';

  @override
  String get mapCache_useCurrentView => 'Use Current View';

  @override
  String get mapCache_zoomRange => 'Zoom Range';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Estimated tiles: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Downloaded $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Download Tiles';

  @override
  String get mapCache_clearCacheButton => 'Clear Cache';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Failed downloads: $count';
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
  String get time_justNow => 'Just now';

  @override
  String time_minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String time_daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get time_hour => 'hour';

  @override
  String get time_hours => 'hours';

  @override
  String get time_day => 'day';

  @override
  String get time_days => 'days';

  @override
  String get time_week => 'week';

  @override
  String get time_weeks => 'weeks';

  @override
  String get time_month => 'month';

  @override
  String get time_months => 'months';

  @override
  String get time_minutes => 'minutes';

  @override
  String get time_allTime => 'All Time';

  @override
  String get dialog_disconnect => 'Disconnect';

  @override
  String get dialog_disconnectConfirm =>
      'Are you sure you want to disconnect from this device?';

  @override
  String get login_repeaterLogin => 'Repeater Login';

  @override
  String get login_roomLogin => 'Room Server Login';

  @override
  String get login_password => 'Password';

  @override
  String get login_enterPassword => 'Enter password';

  @override
  String get login_savePassword => 'Save password';

  @override
  String get login_savePasswordSubtitle =>
      'Password will be stored securely on this device';

  @override
  String get login_repeaterDescription =>
      'Enter the repeater password to access settings and status.';

  @override
  String get login_roomDescription =>
      'Enter the room password to access settings and status.';

  @override
  String get login_routing => 'Routing';

  @override
  String get login_routingMode => 'Routing mode';

  @override
  String get login_autoUseSavedPath => 'Auto (use saved path)';

  @override
  String get login_forceFloodMode => 'Force Flood Mode';

  @override
  String get login_managePaths => 'Manage Paths';

  @override
  String get login_login => 'Login';

  @override
  String login_attempt(int current, int max) {
    return 'Attempt $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get login_failedMessage =>
      'Login failed. Either the password is incorrect or the repeater is unreachable.';

  @override
  String get common_reload => 'Reload';

  @override
  String get common_clear => 'Clear';

  @override
  String path_currentPath(String path) {
    return 'Current path: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Using $count $_temp0 path';
  }

  @override
  String get path_enterCustomPath => 'Enter Custom Path';

  @override
  String get path_currentPathLabel => 'Current path';

  @override
  String get path_hexPrefixInstructions =>
      'Enter 2-character hex prefixes for each hop, separated by commas.';

  @override
  String get path_hexPrefixExample =>
      'Example: A1,F2,3C (each node uses first byte of its public key)';

  @override
  String get path_labelHexPrefixes => 'Path (hex prefixes)';

  @override
  String get path_helperMaxHops =>
      'Max 64 hops. Each prefix is 2 hex characters (1 byte)';

  @override
  String get path_selectFromContacts => 'Or select from contacts:';

  @override
  String get path_noRepeatersFound => 'No repeaters or room servers found.';

  @override
  String get path_customPathsRequire =>
      'Custom paths require intermediate hops that can relay messages.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Invalid hex prefixes: $prefixes';
  }

  @override
  String get path_tooLong => 'Path too long. Maximum 64 hops allowed.';

  @override
  String get path_setPath => 'Set Path';

  @override
  String get repeater_management => 'Repeater Management';

  @override
  String get room_management => 'Room Server Management';

  @override
  String get repeater_managementTools => 'Management Tools';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'View repeater status, stats, and neighbors';

  @override
  String get repeater_telemetry => 'Telemetry';

  @override
  String get repeater_telemetrySubtitle =>
      'View telemetry of sensors and system stats';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Send commands to the repeater';

  @override
  String get repeater_neighbors => 'Neighbors';

  @override
  String get repeater_neighborsSubtitle => 'View zero hop neighbors.';

  @override
  String get repeater_settings => 'Settings';

  @override
  String get repeater_settingsSubtitle => 'Configure repeater parameters';

  @override
  String get repeater_statusTitle => 'Repeater Status';

  @override
  String get repeater_routingMode => 'Routing mode';

  @override
  String get repeater_autoUseSavedPath => 'Auto (use saved path)';

  @override
  String get repeater_forceFloodMode => 'Force Flood Mode';

  @override
  String get repeater_pathManagement => 'Path management';

  @override
  String get repeater_refresh => 'Refresh';

  @override
  String get repeater_statusRequestTimeout => 'Status request timed out.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Error loading status: $error';
  }

  @override
  String get repeater_systemInformation => 'System Information';

  @override
  String get repeater_battery => 'Battery';

  @override
  String get repeater_clockAtLogin => 'Clock (at login)';

  @override
  String get repeater_uptime => 'Uptime';

  @override
  String get repeater_queueLength => 'Queue Length';

  @override
  String get repeater_debugFlags => 'Debug Flags';

  @override
  String get repeater_radioStatistics => 'Radio Statistics';

  @override
  String get repeater_lastRssi => 'Last RSSI';

  @override
  String get repeater_lastSnr => 'Last SNR';

  @override
  String get repeater_noiseFloor => 'Noise Floor';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Packet Statistics';

  @override
  String get repeater_sent => 'Sent';

  @override
  String get repeater_received => 'Received';

  @override
  String get repeater_duplicates => 'Duplicates';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days days ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get repeater_settingsTitle => 'Repeater Settings';

  @override
  String get repeater_basicSettings => 'Basic Settings';

  @override
  String get repeater_repeaterName => 'Repeater Name';

  @override
  String get repeater_repeaterNameHelper => 'Display name for this repeater';

  @override
  String get repeater_adminPassword => 'Admin Password';

  @override
  String get repeater_adminPasswordHelper => 'Full access password';

  @override
  String get repeater_guestPassword => 'Guest Password';

  @override
  String get repeater_guestPasswordHelper => 'Read-only access password';

  @override
  String get repeater_radioSettings => 'Radio Settings';

  @override
  String get repeater_frequencyMhz => 'Frequency (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Bandwidth';

  @override
  String get repeater_spreadingFactor => 'Spreading Factor';

  @override
  String get repeater_codingRate => 'Coding Rate';

  @override
  String get repeater_locationSettings => 'Location Settings';

  @override
  String get repeater_latitude => 'Latitude';

  @override
  String get repeater_latitudeHelper => 'Decimal degrees (e.g., 37.7749)';

  @override
  String get repeater_longitude => 'Longitude';

  @override
  String get repeater_longitudeHelper => 'Decimal degrees (e.g., -122.4194)';

  @override
  String get repeater_features => 'Features';

  @override
  String get repeater_packetForwarding => 'Packet Forwarding';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Enable repeater to forward packets';

  @override
  String get repeater_guestAccess => 'Guest Access';

  @override
  String get repeater_guestAccessSubtitle => 'Allow read-only guest access';

  @override
  String get repeater_privacyMode => 'Privacy Mode';

  @override
  String get repeater_privacyModeSubtitle =>
      'Hide name/location in advertisements';

  @override
  String get repeater_advertisementSettings => 'Advertisement Settings';

  @override
  String get repeater_localAdvertInterval => 'Local Advertisement Interval';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get repeater_floodAdvertInterval => 'Flood Advertisement Interval';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours hours';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Encrypted Advertisement Interval';

  @override
  String get repeater_dangerZone => 'Danger Zone';

  @override
  String get repeater_rebootRepeater => 'Reboot Repeater';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Restart the repeater device';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Are you sure you want to reboot this repeater?';

  @override
  String get repeater_regenerateIdentityKey => 'Regenerate Identity Key';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generate new public/private key pair';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'This will generate a new identity for the repeater. Continue?';

  @override
  String get repeater_eraseFileSystem => 'Erase File System';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Format the repeater file system';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'WARNING: This will erase all data on the repeater. This cannot be undone!';

  @override
  String get repeater_eraseSerialOnly =>
      'Erase is only available over serial console.';

  @override
  String repeater_commandSent(String command) {
    return 'Command sent: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Error sending command: $error';
  }

  @override
  String get repeater_confirm => 'Confirm';

  @override
  String get repeater_settingsSaved => 'Settings saved successfully';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Error saving settings: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Refresh Basic Settings';

  @override
  String get repeater_refreshRadioSettings => 'Refresh Radio Settings';

  @override
  String get repeater_refreshTxPower => 'Refresh TX power';

  @override
  String get repeater_refreshLocationSettings => 'Refresh Location Settings';

  @override
  String get repeater_refreshPacketForwarding => 'Refresh Packet Forwarding';

  @override
  String get repeater_refreshGuestAccess => 'Refresh Guest Access';

  @override
  String get repeater_refreshPrivacyMode => 'Refresh Privacy Mode';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Refresh Advertisement Settings';

  @override
  String repeater_refreshed(String label) {
    return '$label refreshed';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Error refreshing $label';
  }

  @override
  String get repeater_cliTitle => 'Repeater CLI';

  @override
  String get repeater_debugNextCommand => 'Debug Next Command';

  @override
  String get repeater_commandHelp => 'Command Help';

  @override
  String get repeater_clearHistory => 'Clear History';

  @override
  String get repeater_noCommandsSent => 'No commands sent yet';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Type a command below or use quick commands';

  @override
  String get repeater_enterCommandHint => 'Enter command...';

  @override
  String get repeater_previousCommand => 'Previous command';

  @override
  String get repeater_nextCommand => 'Next command';

  @override
  String get repeater_enterCommandFirst => 'Enter a command first';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI Command Frame';

  @override
  String repeater_cliCommandError(String error) {
    return 'Error: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Get Name';

  @override
  String get repeater_cliQuickGetRadio => 'Get Radio';

  @override
  String get repeater_cliQuickGetTx => 'Get TX';

  @override
  String get repeater_cliQuickNeighbors => 'Neighbors';

  @override
  String get repeater_cliQuickVersion => 'Version';

  @override
  String get repeater_cliQuickAdvertise => 'Advertise';

  @override
  String get repeater_cliQuickClock => 'Clock';

  @override
  String get repeater_cliHelpAdvert => 'Sends an advertisement packet';

  @override
  String get repeater_cliHelpReboot =>
      'Reboots the device. (note, you\'ll prob get \'Timeout\' which is normal)';

  @override
  String get repeater_cliHelpClock =>
      'Displays current time per device\'s clock.';

  @override
  String get repeater_cliHelpPassword =>
      'Sets a new admin password for the device.';

  @override
  String get repeater_cliHelpVersion =>
      'Shows the device version and firmware build date.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resets various stats counters to zero.';

  @override
  String get repeater_cliHelpSetAf => 'Sets the air-time-factor.';

  @override
  String get repeater_cliHelpSetTx =>
      'Sets LoRa transmit power in dBm. (reboot to apply)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Enables or disables the repeater role for this node.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Room server) If \'on\', then login in blank password will be allowed, but cannot Post to room. (just read only)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Sets the maximum number of hops of inbound flood packet (if >= max, packet is not forwarded)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Sets the Interference Threshold (in DB). Default is 14. Set to 0 to disable channel interference detection.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Sets the interval to reset the Auto Gain Controller. Set to 0 to disable.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Enables or disables the \'double ACKs\' feature.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Sets the timer interval in minutes to send a local (zero-hop) advertisement packet. Set to 0 to disable.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Sets the timer interval in hours to send a flood advertisement packet. Set to 0 to disable.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Sets/updates the guest password. (for repeaters, guest logins can send the \"Get Stats\" request)';

  @override
  String get repeater_cliHelpSetName => 'Sets the advertisement name.';

  @override
  String get repeater_cliHelpSetLat =>
      'Sets the advertisement map latitude. (decimal degrees)';

  @override
  String get repeater_cliHelpSetLon =>
      'Sets the advertisement map longitude. (decimal degrees)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Sets completely new radio params, and saves to preferences. Requires a \"reboot\" command to apply.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Sets (experimental) base (must be > 1 for effect) for applying slight delay to received packets, based on signal strength/score. Set to 0 to disable.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Sets a factor multiplied with time-on-air for a flood-mode packet and with a randomized slot system, to delay its forwarding. (to decrease likelihood of collisions)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Same as txdelay, but for applying a random delay to the forwarding of direct-mode packets.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Enable/Disable bridge.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Set delay before retransmitting packets.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Choose wether the bridge will retransmit received packets or transmitted packets.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Set serial link baudrate for rs232 bridges.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Set bridge secret for espnow bridges.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Sets custom factor to adjust reported battery voltage (only supported on select boards).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Sets temporary radio params for the given number of minutes, reverting to original radio params afterward. (does NOT save to preferences).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifies the ACL. Removes matching entry (by pubkey prefix) if \"permissions\" is zero. Adds new entry if pubkey-hex is full length and is not currently in ACL. Updates entry by matching pubkey prefix. Permission bits vary per firmware role, but low 2 bits are: 0 (Guest), 1 (Read only), 2 (Read write), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Gets bridge type none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Starts packet logging to file system.';

  @override
  String get repeater_cliHelpLogStop => 'Stops packet logging to file system.';

  @override
  String get repeater_cliHelpLogErase =>
      'Erases the packet logs from file system.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Shows a list of other repeater nodes heard via zero-hop adverts. Each line is id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Removes first matching entry (by pubkey prefix (hex)), from neighbors list.';

  @override
  String get repeater_cliHelpRegion =>
      '(serial only) Lists all defined regions and current flood permissions.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTE: this is a special multi-command invocation. Each subsequent command is a region name (indented with spaces to indicate parent hierarchy, with one space at minimum). Terminated by sending a blank line/command.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Searches for region with given name prefix (or \"*\" for the global scope). Replies with \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Adds or updates a region definition with given name.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Removes a region definition with given name. (must match exactly, and have no child regions)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Sets the \'F\'lood permission for the given region. (\'*\' for the global/legacy scope)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Removes the \'F\'lood permission for the given region. (NOTE: at this stage NOT advised to use this on the global/legacy scope!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Replies with the current \'home\' region. (Note applied anywhere yet, reserved for future)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Sets the \'home\' region.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persists the region list/map to storage.';

  @override
  String get repeater_cliHelpGps =>
      'Gives status of gps. When gps is off, it replies only off, if on it replies with on, status, fix, sat count';

  @override
  String get repeater_cliHelpGpsOnOff => 'Toggles gps power state.';

  @override
  String get repeater_cliHelpGpsSync => 'Syncs node time with gps clock.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Sets node\'s position to gps coordinates and save preferences.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Gives location advert configuration of the node:\n- none: don\'t include location in adverts\n- share: share gps location (from SensorManager)\n- prefs: advert the location stored in preferences';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Sets location advert configuration.';

  @override
  String get repeater_commandsListTitle => 'Commands List';

  @override
  String get repeater_commandsListNote =>
      'NOTE: for the various \"set ...\" commands, there is also a \"get ...\" command.';

  @override
  String get repeater_general => 'General';

  @override
  String get repeater_settingsCategory => 'Settings';

  @override
  String get repeater_bridge => 'Bridge';

  @override
  String get repeater_logging => 'Logging';

  @override
  String get repeater_neighborsRepeaterOnly => 'Neighbors (Repeater only)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Region Management (Repeater only)';

  @override
  String get repeater_regionNote =>
      'Region commands have been introduced to manage region definitions and permissions.';

  @override
  String get repeater_gpsManagement => 'GPS Management';

  @override
  String get repeater_gpsNote =>
      'gps command has been introduced to manage location related topics.';

  @override
  String get telemetry_receivedData => 'Received Telemetry Data';

  @override
  String get telemetry_requestTimeout => 'Telemetry request timed out.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Error loading telemetry: $error';
  }

  @override
  String get telemetry_noData => 'No telemetry data available.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Channel $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Battery';

  @override
  String get telemetry_voltageLabel => 'Voltage';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU Temperature';

  @override
  String get telemetry_temperatureLabel => 'Temperature';

  @override
  String get telemetry_currentLabel => 'Current';

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
  String get neighbors_receivedData => 'Received Neighbors Data';

  @override
  String get neighbors_requestTimedOut => 'Neighbors request timed out.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Error loading neighbors: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Repeaters Neighbors';

  @override
  String get neighbors_noData => 'No neighbors data available.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Unknown $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Heard: $time ago';
  }

  @override
  String get channelPath_title => 'Packet Path';

  @override
  String get channelPath_viewMap => 'View map';

  @override
  String get channelPath_otherObservedPaths => 'Other Observed Paths';

  @override
  String get channelPath_repeaterHops => 'Repeater Hops';

  @override
  String get channelPath_noHopDetails =>
      'Hop details are not provided for this packet.';

  @override
  String get channelPath_messageDetails => 'Message Details';

  @override
  String get channelPath_senderLabel => 'Sender';

  @override
  String get channelPath_timeLabel => 'Time';

  @override
  String get channelPath_repeatsLabel => 'Repeats';

  @override
  String channelPath_pathLabel(int index) {
    return 'Path $index';
  }

  @override
  String get channelPath_observedLabel => 'Observed';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Observed path $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'No location data';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Unknown';

  @override
  String get channelPath_floodPath => 'Flood';

  @override
  String get channelPath_directPath => 'Direct';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 of $total hops';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed of $total hops';
  }

  @override
  String get channelPath_mapTitle => 'Path Map';

  @override
  String get channelPath_noRepeaterLocations =>
      'No repeater locations available for this path.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Path $index (Primary)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Path';

  @override
  String get channelPath_observedPathHeader => 'Observed Path';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'No hop details available for this packet.';

  @override
  String get channelPath_unknownRepeater => 'Unknown Repeater';

  @override
  String get community_title => 'Community';

  @override
  String get community_create => 'Create Community';

  @override
  String get community_createDesc =>
      'Create a new community and share via QR code.';

  @override
  String get community_join => 'Join';

  @override
  String get community_joinTitle => 'Join Community';

  @override
  String community_joinConfirmation(String name) {
    return 'Do you want to join the community \"$name\"?';
  }

  @override
  String get community_scanQr => 'Scan Community QR';

  @override
  String get community_scanInstructions =>
      'Point the camera at a community QR code';

  @override
  String get community_showQr => 'Show QR Code';

  @override
  String get community_publicChannel => 'Community Public';

  @override
  String get community_hashtagChannel => 'Community Hashtag';

  @override
  String get community_name => 'Community Name';

  @override
  String get community_enterName => 'Enter community name';

  @override
  String community_created(String name) {
    return 'Community \"$name\" created';
  }

  @override
  String community_joined(String name) {
    return 'Joined community \"$name\"';
  }

  @override
  String get community_qrTitle => 'Share Community';

  @override
  String community_qrInstructions(String name) {
    return 'Scan this QR code to join \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Community hashtag channels are only joinable by members of the community';

  @override
  String get community_invalidQrCode => 'Invalid community QR code';

  @override
  String get community_alreadyMember => 'Already a Member';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'You are already a member of \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Add Community Public Channel';

  @override
  String get community_addPublicChannelHint =>
      'Automatically add the public channel for this community';

  @override
  String get community_noCommunities => 'No communities joined yet';

  @override
  String get community_scanOrCreate =>
      'Scan a QR code or create a community to get started';

  @override
  String get community_manageCommunities => 'Manage Communities';

  @override
  String get community_delete => 'Leave Community';

  @override
  String community_deleteConfirm(String name) {
    return 'Leave \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'This will also delete $count channel(s) and their messages.';
  }

  @override
  String community_deleted(String name) {
    return 'Left community \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerate Secret';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerate the secret key for \"$name\"? All members will need to scan the new QR code to continue communicating.';
  }

  @override
  String get community_regenerate => 'Regenerate';

  @override
  String community_secretRegenerated(String name) {
    return 'Secret regenerated for \"$name\"';
  }

  @override
  String get community_updateSecret => 'Update Secret';

  @override
  String community_secretUpdated(String name) {
    return 'Secret updated for \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scan the new QR code to update the secret for \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Add Community Hashtag';

  @override
  String get community_addHashtagChannelDesc =>
      'Add a hashtag channel for this community';

  @override
  String get community_selectCommunity => 'Select Community';

  @override
  String get community_regularHashtag => 'Regular Hashtag';

  @override
  String get community_regularHashtagDesc => 'Public hashtag (anyone can join)';

  @override
  String get community_communityHashtag => 'Community Hashtag';

  @override
  String get community_communityHashtagDesc => 'Private to community members';

  @override
  String community_forCommunity(String name) {
    return 'For $name';
  }

  @override
  String get listFilter_tooltip => 'Filter and sort';

  @override
  String get listFilter_sortBy => 'Sort by';

  @override
  String get listFilter_latestMessages => 'Latest messages';

  @override
  String get listFilter_heardRecently => 'Heard recently';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filters';

  @override
  String get listFilter_all => 'All';

  @override
  String get listFilter_favorites => 'Favorites';

  @override
  String get listFilter_addToFavorites => 'Add to favorites';

  @override
  String get listFilter_removeFromFavorites => 'Remove from favorites';

  @override
  String get listFilter_users => 'Users';

  @override
  String get listFilter_repeaters => 'Repeaters';

  @override
  String get listFilter_roomServers => 'Room servers';

  @override
  String get listFilter_unreadOnly => 'Unread only';

  @override
  String get listFilter_newGroup => 'New group';

  @override
  String get pathTrace_you => 'You';

  @override
  String get pathTrace_failed => 'Path trace failed.';

  @override
  String get pathTrace_notAvailable => 'Path trace not available.';

  @override
  String get pathTrace_refreshTooltip => 'Refresh Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'One or more of the hops is missing a location!';

  @override
  String get pathTrace_clearTooltip => 'Clear path.';

  @override
  String get losSelectStartEnd => 'Select start and end nodes for LOS.';

  @override
  String losRunFailed(String error) {
    return 'Line-of-sight check failed: $error';
  }

  @override
  String get losClearAllPoints => 'Clear all points';

  @override
  String get losRunToViewElevationProfile =>
      'Run LOS to view elevation profile';

  @override
  String get losMenuTitle => 'LOS Menu';

  @override
  String get losMenuSubtitle => 'Tap nodes or long-press map for custom points';

  @override
  String get losShowDisplayNodes => 'Show display nodes';

  @override
  String get losCustomPoints => 'Custom points';

  @override
  String losCustomPointLabel(int index) {
    return 'Custom $index';
  }

  @override
  String get losPointA => 'Point A';

  @override
  String get losPointB => 'Point B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenna A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenna B: $value $unit';
  }

  @override
  String get losRun => 'Run LOS';

  @override
  String get losNoElevationData => 'No elevation data';

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
  String get losStatusChecking => 'LOS: checking...';

  @override
  String get losStatusNoData => 'LOS: no data';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total clear, $blocked blocked, $unknown unknown';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Elevation data unavailable for one or more samples.';

  @override
  String get losErrorInvalidInput =>
      'Invalid points/elevation data for LOS calculation.';

  @override
  String get losRenameCustomPoint => 'Rename custom point';

  @override
  String get losPointName => 'Point name';

  @override
  String get losShowPanelTooltip => 'Show LOS panel';

  @override
  String get losHidePanelTooltip => 'Hide LOS panel';

  @override
  String get losElevationAttribution =>
      'Elevation data: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radio horizon';

  @override
  String get losLegendLosBeam => 'LOS beam';

  @override
  String get losLegendTerrain => 'Terrain';

  @override
  String get losFrequencyLabel => 'Frequency';

  @override
  String get losFrequencyInfoTooltip => 'View calculation details';

  @override
  String get losFrequencyDialogTitle => 'Radio horizon calculation';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Starting from k=$baselineK at $baselineFreq MHz, the calculation adjusts the k-factor for the current $frequencyMHz MHz band, which defines the curved radio horizon cap.';
  }

  @override
  String get contacts_pathTrace => 'Path Trace';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Path trace to repeater';

  @override
  String get contacts_repeaterPing => 'Ping repeater';

  @override
  String get contacts_roomPathTrace => 'Path trace to room server';

  @override
  String get contacts_roomPing => 'Ping room server';

  @override
  String get contacts_chatTraceRoute => 'Path trace route';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Trace route to $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Clipboard is empty.';

  @override
  String get contacts_invalidAdvertFormat => 'Invalid contact data';

  @override
  String get contacts_contactImported => 'Contact has been imported.';

  @override
  String get contacts_contactImportFailed => 'Failed to import contact.';

  @override
  String get contacts_zeroHopAdvert => 'Zero Hop Advert';

  @override
  String get contacts_floodAdvert => 'Flood Advert';

  @override
  String get contacts_copyAdvertToClipboard => 'Copy Advert to Clipboard';

  @override
  String get contacts_addContactFromClipboard => 'Add Contact from Clipboard';

  @override
  String get contacts_ShareContact => 'Copy contact to Clipboard';

  @override
  String get contacts_ShareContactZeroHop => 'Share contact by advert';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Sent contact by advert.';

  @override
  String get contacts_zeroHopContactAdvertFailed => 'Failed to send contact.';

  @override
  String get contacts_contactAdvertCopied => 'Advert copied to Clipboard.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Copying advert to Clipboard failed.';

  @override
  String get notification_activityTitle => 'MeshCore Activity';

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
      other: 'channel messages',
      one: 'channel message',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'new nodes',
      one: 'new node',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'New $contactType discovered';
  }

  @override
  String get notification_receivedNewMessage => 'Received new message';

  @override
  String get settings_gpxExportRepeaters =>
      'Export repeaters / room server to GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exports repeaters / roomserver with a location to GPX file.';

  @override
  String get settings_gpxExportContacts => 'Export companions to GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exports companions with a location to GPX file.';

  @override
  String get settings_gpxExportAll => 'Export all contacts to GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exports all contacts with a location to GPX file.';

  @override
  String get settings_gpxExportSuccess => 'Successfully exported GPX file.';

  @override
  String get settings_gpxExportNoContacts => 'No contacts to export.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Not supported on your device/OS';

  @override
  String get settings_gpxExportError => 'There was an error when exporting.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Repeater & room server locations';

  @override
  String get settings_gpxExportChat => 'Companion locations';

  @override
  String get settings_gpxExportAllContacts => 'All contacts locations';

  @override
  String get settings_gpxExportShareText =>
      'Map data exported from meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open GPX map data export';

  @override
  String get snrIndicator_nearByRepeaters => 'Nearby Repeaters';

  @override
  String get snrIndicator_lastSeen => 'Last seen';

  @override
  String get contactsSettings_title => 'Contacts settings';

  @override
  String get contactsSettings_autoAddTitle => 'Automatic Discovery';

  @override
  String get contactsSettings_otherTitle => 'Other contact related settings';

  @override
  String get contactsSettings_autoAddUsersTitle => 'Auto-add users';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Allow the companion to automatically add discovered users.';

  @override
  String get contactsSettings_autoAddRepeatersTitle => 'Auto-add repeaters';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Allow the companion to automatically add discovered repeaters.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Auto-add room servers';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Allow the companion to automatically add discovered room servers.';

  @override
  String get contactsSettings_autoAddSensorsTitle => 'Auto-add sensors';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Allow the companion to automatically add discovered sensors.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Overwrite Oldest';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'When the contact list is full, the oldest non-favorited contact will be replaced.';

  @override
  String get discoveredContacts_Title => 'Discovered Contacts';

  @override
  String get discoveredContacts_noMatching => 'No matching contacts';

  @override
  String get discoveredContacts_searchHint => 'Search discovered contacts';

  @override
  String get discoveredContacts_contactAdded => 'Contact added';

  @override
  String get discoveredContacts_addContact => 'Add Contact';

  @override
  String get discoveredContacts_copyContact => 'Copy Contact to clipboard';

  @override
  String get discoveredContacts_deleteContact => 'Delete Discovered Contact';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Delete All Discovered Contacts';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Are you sure you want to delete all discovered contacts?';
}
