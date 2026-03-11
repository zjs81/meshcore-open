// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Контакти';

  @override
  String get nav_channels => 'Канали';

  @override
  String get nav_map => 'Карта';

  @override
  String get common_cancel => 'Отказ';

  @override
  String get common_ok => 'Добре';

  @override
  String get common_connect => 'Свържи се';

  @override
  String get common_unknownDevice => 'Неизвестно устройство';

  @override
  String get common_save => 'Запази';

  @override
  String get common_delete => 'Изтрий';

  @override
  String get common_deleteAll => 'Изтрий всичко';

  @override
  String get common_close => 'Затвори';

  @override
  String get common_edit => 'Редактирай';

  @override
  String get common_add => 'Добави';

  @override
  String get common_settings => 'Настройки';

  @override
  String get common_disconnect => 'Прекъсни';

  @override
  String get common_connected => 'Свързано';

  @override
  String get common_disconnected => 'Откъснато';

  @override
  String get common_create => 'Създай';

  @override
  String get common_continue => 'Продължи';

  @override
  String get common_share => 'Сподели';

  @override
  String get common_copy => 'Копирай';

  @override
  String get common_retry => 'Опитай отново';

  @override
  String get common_hide => 'Скриване';

  @override
  String get common_remove => 'Изтрий';

  @override
  String get common_enable => 'Активирай';

  @override
  String get common_disable => 'Деактивирай';

  @override
  String get common_reboot => 'Рестартирай';

  @override
  String get common_loading => 'Зареждане...';

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
  String get usbScreenTitle => 'Свържете се чрез USB';

  @override
  String get usbScreenSubtitle =>
      'Изберете открития сериен уред и свържете директно към вашия MeshCore възел.';

  @override
  String get usbScreenStatus => 'Изберете USB устройство';

  @override
  String get usbScreenNote =>
      'USB серийната връзка е активна на поддържаните Android устройства и настолни платформи.';

  @override
  String get usbScreenEmptyState =>
      'Няма открити USB устройства. Включете едно и опитайте отново.';

  @override
  String get usbErrorPermissionDenied => 'Не беше разрешено достъпът през USB.';

  @override
  String get usbErrorDeviceMissing =>
      'Избраното USB устройство вече не е налично.';

  @override
  String get usbErrorInvalidPort => 'Изберете валитно USB устройство.';

  @override
  String get usbErrorBusy =>
      'Друг мол за свързване през USB вече е в процес на изпълнение.';

  @override
  String get usbErrorNotConnected => 'Няма свързано USB устройство.';

  @override
  String get usbErrorOpenFailed =>
      'Не успях да отворя избраното USB устройство.';

  @override
  String get usbErrorConnectFailed =>
      'Не успях да се свържа с избраното USB устройство.';

  @override
  String get usbErrorUnsupported =>
      'USB серийната комуникация не се поддържа на тази платформа.';

  @override
  String get usbErrorAlreadyActive => 'USB връзката вече е активирана.';

  @override
  String get usbErrorNoDeviceSelected => 'Няма избран USB устройство.';

  @override
  String get usbErrorPortClosed => 'USB връзката не е активна.';

  @override
  String get usbErrorConnectTimedOut =>
      'Връзката прекъсна. Уверете се, че устройството има софтуер за USB връзка.';

  @override
  String get usbFallbackDeviceName =>
      'Устройство за четене на уеб серийни данни';

  @override
  String get usbStatus_notConnected => 'Изберете USB устройство';

  @override
  String get usbStatus_connecting => 'Свързване към USB устройство...';

  @override
  String get usbStatus_searching => 'Търсене на USB устройства...';

  @override
  String usbConnectionFailed(String error) {
    return 'Неуспешно свързване през USB: $error';
  }

  @override
  String get scanner_scanning => 'Сканиране за устройства...';

  @override
  String get scanner_connecting => 'Свързвам се...';

  @override
  String get scanner_disconnecting => 'Изключване...';

  @override
  String get scanner_notConnected => 'Не е свързан';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Свързано с $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Търсене на устройства MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Натиснете Сканиране, за да намерите устройства MeshCore.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Връзката не успя: $error';
  }

  @override
  String get scanner_stop => 'Спрете';

  @override
  String get scanner_scan => 'Сканирай';

  @override
  String get scanner_bluetoothOff => 'Bluetooth е изключен.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Моля, активирайте Bluetooth, за да сканирате за устройства.';

  @override
  String get scanner_chromeRequired => 'Изисква се браузър Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Това уеб приложение изисква Google Chrome или браузър, базиран на Chromium, за поддръжка на Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Активирайте Bluetooth';

  @override
  String get device_quickSwitch => 'Бързо превключване';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_deviceInfo => 'Информация за устройството';

  @override
  String get settings_appSettings => 'Настройки на приложението';

  @override
  String get settings_appSettingsSubtitle =>
      'Уведомления, съобщения и предпочитания за карта';

  @override
  String get settings_nodeSettings => 'Настройки на възела';

  @override
  String get settings_nodeName => 'Име на възела';

  @override
  String get settings_nodeNameNotSet => 'Не е зададено';

  @override
  String get settings_nodeNameHint => 'Въведете име на възел';

  @override
  String get settings_nodeNameUpdated => 'Името е актуализирано';

  @override
  String get settings_radioSettings => 'Настройки на радиопредавателя';

  @override
  String get settings_radioSettingsSubtitle =>
      'Честота, мощност, разпространяващ фактор';

  @override
  String get settings_radioSettingsUpdated =>
      'Радио настройките са актуализирани';

  @override
  String get settings_location => 'Местоположение';

  @override
  String get settings_locationSubtitle => 'Координати на GPS';

  @override
  String get settings_locationUpdated => 'Местоположението е актуализирано';

  @override
  String get settings_locationBothRequired =>
      'Въведете както географска ширина, така и географска дължина.';

  @override
  String get settings_locationInvalid => 'Невалидна ширина или дължина.';

  @override
  String get settings_locationGPSEnable => 'Активиране на GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Активирайте автоматичното актуализиране на местоположението чрез GPS.';

  @override
  String get settings_locationIntervalSec => 'Интервал за GPS (Секунди)';

  @override
  String get settings_locationIntervalInvalid =>
      'Интервалът трябва да бъде поне 60 секунди и по-малко от 86400 секунди.';

  @override
  String get settings_latitude => 'Широчина';

  @override
  String get settings_longitude => 'Дължина';

  @override
  String get settings_contactSettings => 'Настройки за контакти';

  @override
  String get settings_contactSettingsSubtitle =>
      'Настройки за добавяне на контакти.';

  @override
  String get settings_privacyMode => 'Режим на поверителност';

  @override
  String get settings_privacyModeSubtitle =>
      'Скриване на име/местоположение в рекламите';

  @override
  String get settings_privacyModeToggle =>
      'Активирайте режим на поверителност, за да скриете името и местоположението си в рекламите.';

  @override
  String get settings_privacyModeEnabled =>
      'Режим на поверителност е активиран';

  @override
  String get settings_privacyModeDisabled =>
      'Режим на поверителност е деактивиран';

  @override
  String get settings_actions => 'Действия';

  @override
  String get settings_sendAdvertisement => 'Изпрати Реклама';

  @override
  String get settings_sendAdvertisementSubtitle => 'Сега присъствие в ефир';

  @override
  String get settings_advertisementSent => 'Реклама изпратена';

  @override
  String get settings_syncTime => 'Време за синхронизация';

  @override
  String get settings_syncTimeSubtitle =>
      'Задайте часовника на устройството да отговаря на времето на телефона.';

  @override
  String get settings_timeSynchronized => 'Синхронизирано във времето';

  @override
  String get settings_refreshContacts => 'Презареди контакти';

  @override
  String get settings_refreshContactsSubtitle =>
      'Презареди списъка с контакти от устройството';

  @override
  String get settings_rebootDevice => 'Рестартирайте устройството';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Рестартирайте устройството MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Сигурни ли сте, че искате да рестартирате устройството? Ще бъдете откъснати.';

  @override
  String get settings_debug => 'Отстрани';

  @override
  String get settings_bleDebugLog => 'Лог за отстраняване на грешки на BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Команди, отговори и сурови данни BLE';

  @override
  String get settings_appDebugLog =>
      'Лог на отстраняване на грешки на приложението';

  @override
  String get settings_appDebugLogSubtitle =>
      'Съобщения за отстраняване на грешки на приложението';

  @override
  String get settings_about => 'За нас';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => 'Проект MeshCore с отворен код 2024 г.';

  @override
  String get settings_aboutDescription =>
      'Отворен софтуер за Flutter клиент за MeshCore LoRa мрежови устройства.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Данни за надморска височина на LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Име';

  @override
  String get settings_infoId => 'ИД';

  @override
  String get settings_infoStatus => 'Статус';

  @override
  String get settings_infoBattery => 'Батерия';

  @override
  String get settings_infoPublicKey => 'Общ публичен ключ';

  @override
  String get settings_infoContactsCount => 'Брой контакти';

  @override
  String get settings_infoChannelCount => 'Брой канали';

  @override
  String get settings_presets => 'Предварителни настройки';

  @override
  String get settings_frequency => 'Честота (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Невалидна честота (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Ширина на честотния спектър';

  @override
  String get settings_spreadingFactor => 'Фактор на разпространение';

  @override
  String get settings_codingRate => 'Такса за кодиране';

  @override
  String get settings_txPower => 'TX Мощност (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Невалидна мощност на TX (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Без електричество – повторение';

  @override
  String get settings_clientRepeatSubtitle =>
      'Позволете на това устройство да предава пакети към мрежата за други устройства.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'За повторение извън мрежата са необходими честоти от 433, 869 или 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Грешка: $message';
  }

  @override
  String get appSettings_title => 'Настройки на приложението';

  @override
  String get appSettings_appearance => 'Външен вид';

  @override
  String get appSettings_theme => 'Тема';

  @override
  String get appSettings_themeSystem => 'Система по подразбиране';

  @override
  String get appSettings_themeLight => 'Ярка';

  @override
  String get appSettings_themeDark => 'Тъмно';

  @override
  String get appSettings_language => 'Език';

  @override
  String get appSettings_languageSystem => 'Система по подразбиране';

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
  String get appSettings_languageRu => 'Руски';

  @override
  String get appSettings_languageUk => 'Украински';

  @override
  String get appSettings_enableMessageTracing =>
      'Разрешаване на проследяване на съобщения';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показване на подробни метаданни за маршрутизация и синхронизация за съобщения';

  @override
  String get appSettings_notifications => 'Уведомления';

  @override
  String get appSettings_enableNotifications => 'Активирай Известия';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Получете известия за съобщения и реклами';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Отказвано е разрешение за известия';

  @override
  String get appSettings_notificationsEnabled => 'Уведомителни са активирани';

  @override
  String get appSettings_notificationsDisabled => 'Известия са изключени';

  @override
  String get appSettings_messageNotifications => 'Уведомления';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Покажи известие при получаване на нови съобщения';

  @override
  String get appSettings_channelMessageNotifications =>
      'Уведомления за съобщения от канал';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Покажи известие при получаване на съобщения от канали';

  @override
  String get appSettings_advertisementNotifications => 'Уведомления за реклами';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Покажи известие, когато бъдат открити нови възли.';

  @override
  String get appSettings_messaging => 'Съобщения';

  @override
  String get appSettings_clearPathOnMaxRetry => 'Изчисти Път на Макс Опит';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Възстанови контактния път след 5 неуспешни опита за изпращане';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Пътищата ще бъдат почистени след 5 неуспешни опита.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Пътищата няма да бъдат автоматично изчистени.';

  @override
  String get appSettings_autoRouteRotation =>
      'Автоматично маршрутизиране на завъртания';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Превключете между най-добрите пътища и режим на наводняване';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Автоматично маршрутизиране вкл.';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Автоматично маршрутизирането е деактивирано';

  @override
  String get appSettings_battery => 'Батерия';

  @override
  String get appSettings_batteryChemistry => 'Химия на батерията';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Зададено за устройство ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Свържете се с устройство, за да изберете.';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'Литиево желязо фосфат (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'Литиев полимер (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => 'Карта за показване';

  @override
  String get appSettings_showRepeaters => 'Показване на повторители';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Показване на възпроизвеждащи се възли на картата';

  @override
  String get appSettings_showChatNodes => 'Покажи Възли на Чат';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Показване на чат възли на картата';

  @override
  String get appSettings_showOtherNodes => 'Покажи други възли';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Покажи други типове възли на картата';

  @override
  String get appSettings_timeFilter => 'Филтриране по време';

  @override
  String get appSettings_timeFilterShowAll => 'Покажи всички възли';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Покажи възли от последните $hours часа';
  }

  @override
  String get appSettings_mapTimeFilter => 'Филтри за време на картата';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Покажи възлите, открити в:';

  @override
  String get appSettings_allTime => 'Всичко време';

  @override
  String get appSettings_lastHour => 'Последната минута';

  @override
  String get appSettings_last6Hours => 'Последни 6 часа';

  @override
  String get appSettings_last24Hours => 'Последно 24 часа';

  @override
  String get appSettings_lastWeek => 'Миналата седмица';

  @override
  String get appSettings_offlineMapCache => 'Кеш на офлайн карти';

  @override
  String get appSettings_unitsTitle => 'единици';

  @override
  String get appSettings_unitsMetric => 'Метрика (m / km)';

  @override
  String get appSettings_unitsImperial => 'Имперска (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Няма избрана област';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Избрана е област (мащаб $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Отстрани';

  @override
  String get appSettings_appDebugLogging =>
      'Логване за отстраняване на грешки на приложението';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записване на съобщения за отстраняване на грешки от приложението за отстраняване на грешки.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Режимът за отстраняване на грешки в приложението е активиран.';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Логването за отстраняване на грешки в приложението е изключено.';

  @override
  String get contacts_title => 'Контакти';

  @override
  String get contacts_noContacts => 'Няма контакти към момента.';

  @override
  String get contacts_contactsWillAppear =>
      'Контактите ще се появят, когато устройствата рекламират.';

  @override
  String get contacts_unread => 'Непрочетено';

  @override
  String get contacts_searchContactsNoNumber => 'Търси контакти...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Търсене на контакти...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Търсене на $number$str любими...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Търсене на $number$str потребители...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Търсене на $number$str повтарящи се...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Търсене на $number$str сървъри в стаята...';
  }

  @override
  String get contacts_noUnreadContacts => 'Няма непрочетени контакти';

  @override
  String get contacts_noContactsFound => 'Няма намерени контакти или групи.';

  @override
  String get contacts_deleteContact => 'Изтрий Контакт';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Изтрий $contactName от контактите?';
  }

  @override
  String get contacts_manageRepeater => 'Управление на Повтарящ се Елемент';

  @override
  String get contacts_manageRoom => 'Управление на сървър за стая';

  @override
  String get contacts_roomLogin => 'Вход в стаята';

  @override
  String get contacts_openChat => 'Отвори чат';

  @override
  String get contacts_editGroup => 'Редактирай Група';

  @override
  String get contacts_deleteGroup => 'Изтрий група';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Премахнете \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Нова група';

  @override
  String get contacts_groupName => 'Група';

  @override
  String get contacts_groupNameRequired => 'Името на групата е задължително.';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Групата \"$name\" вече съществува.';
  }

  @override
  String get contacts_filterContacts => 'Филтрирайте контактите...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Няма съвпадения с вашия филтър.';

  @override
  String get contacts_noMembers => 'Няма членове';

  @override
  String get contacts_lastSeenNow => 'Последно видяно сега';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Последна активност $minutes минути преди';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Последно видяно преди час';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Последно видян $hours часа преди.';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Последно видяно преди 1 ден';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Последно видян $days дни преди.';
  }

  @override
  String get channels_title => 'Канали';

  @override
  String get channels_noChannelsConfigured => 'Няма конфигурирани канали';

  @override
  String get channels_addPublicChannel => 'Добави публичен канал';

  @override
  String get channels_searchChannels => 'Търсене на канали...';

  @override
  String get channels_noChannelsFound => 'Няма намерени канали';

  @override
  String channels_channelIndex(int index) {
    return 'Канал $index';
  }

  @override
  String get channels_hashtagChannel => 'Канал с хаштаг';

  @override
  String get channels_public => 'Публично';

  @override
  String get channels_private => 'Личен';

  @override
  String get channels_publicChannel => 'Публичен канал';

  @override
  String get channels_privateChannel => 'Частен канал';

  @override
  String get channels_editChannel => 'Редактирай канал';

  @override
  String get channels_muteChannel => 'Заглуши канала';

  @override
  String get channels_unmuteChannel => 'Включи известията на канала';

  @override
  String get channels_deleteChannel => 'Изтрий канала';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Изтрий \"$name\"? Това не може да бъде отменено.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Неуспешно изтриване на канала \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Каналът \"$name\" е изтрит';
  }

  @override
  String get channels_addChannel => 'Добави Канал';

  @override
  String get channels_channelIndexLabel => 'Индекс на канал';

  @override
  String get channels_channelName => 'Име на канала';

  @override
  String get channels_usePublicChannel => 'Използвайте публичен канал';

  @override
  String get channels_standardPublicPsk => 'Стандартен публичен PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Генерирай случайна PSK';

  @override
  String get channels_enterChannelName => 'Моля, въведете име на канал.';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK трябва да бъде 32 шестнаредни знака.';

  @override
  String channels_channelAdded(String name) {
    return 'Каналът \"$name\" е добавен';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Редактирай Канал $index';
  }

  @override
  String get channels_smazCompression => 'Компресия SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Каналът \"$name\" е актуализиран';
  }

  @override
  String get channels_publicChannelAdded => 'Публичен канал добавен';

  @override
  String get channels_sortBy => 'Сортирай по';

  @override
  String get channels_sortManual => 'Ръчно';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Последни съобщения';

  @override
  String get channels_sortUnread => 'Непрочетено';

  @override
  String get channels_createPrivateChannel => 'Създай Частен Канал';

  @override
  String get channels_createPrivateChannelDesc => 'Защитено с таен ключ.';

  @override
  String get channels_joinPrivateChannel => 'Присъедини се към Частен Канал';

  @override
  String get channels_joinPrivateChannelDesc => 'Ръчно въведете таен ключ.';

  @override
  String get channels_joinPublicChannel =>
      'Присъединете се към Публичния канал';

  @override
  String get channels_joinPublicChannelDesc =>
      'Всеки може да се присъедини към този канал.';

  @override
  String get channels_joinHashtagChannel => 'Присъедини се към Хаштаг Канал';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Всеки може да се присъедини към хаштаговите канали.';

  @override
  String get channels_scanQrCode => 'Сканирайте QR код';

  @override
  String get channels_scanQrCodeComingSoon => 'Ще излезе скоро';

  @override
  String get channels_enterHashtag => 'Въведете хаштаг';

  @override
  String get channels_hashtagHint => 'напр. #отбор';

  @override
  String get chat_noMessages => 'Няма съобщения.';

  @override
  String get chat_sendMessageToStart => 'Изпрати съобщение, за да започнеш.';

  @override
  String get chat_originalMessageNotFound => 'Съобщението не е намерено';

  @override
  String chat_replyingTo(String name) {
    return 'Отговарям на $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Отговори на $name';
  }

  @override
  String get chat_location => 'Местоположение';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Изпрати съобщение на $contactName';
  }

  @override
  String get chat_typeMessage => 'Въведете съобщение...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Съобщението е твърде дълго (макс $maxBytes байта).';
  }

  @override
  String get chat_messageCopied => 'Съобщението е копирано';

  @override
  String get chat_messageDeleted => 'Съобщението е изтрито';

  @override
  String get chat_retryingMessage => 'Опитваме се отново.';

  @override
  String chat_retryCount(int current, int max) {
    return 'Опитай отново $current/$max';
  }

  @override
  String get chat_sendGif => 'Изпрати GIF';

  @override
  String get chat_reply => 'Отговори';

  @override
  String get chat_addReaction => 'Добави Реакция';

  @override
  String get chat_me => 'Аз';

  @override
  String get emojiCategorySmileys => 'Емотикони';

  @override
  String get emojiCategoryGestures => 'Жестове';

  @override
  String get emojiCategoryHearts => 'Сърца';

  @override
  String get emojiCategoryObjects => 'Обекти';

  @override
  String get gifPicker_title => 'Изберете GIF';

  @override
  String get gifPicker_searchHint => 'Търсене на GIF-ове...';

  @override
  String get gifPicker_poweredBy => 'Задвижвано от GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Няма намерени GIF файлове.';

  @override
  String get gifPicker_failedLoad => 'Не можа да се заредят GIF файловете';

  @override
  String get gifPicker_failedSearch => 'Неуспешно търсене на GIF-ове';

  @override
  String get gifPicker_noInternet => 'Няма интернет връзка';

  @override
  String get debugLog_appTitle =>
      'Лог на отстраняване на грешки на приложението';

  @override
  String get debugLog_bleTitle => 'Лог за отстраняване на грешки на BLE';

  @override
  String get debugLog_copyLog => 'Копирай лог';

  @override
  String get debugLog_clearLog => 'Изчисти логовете';

  @override
  String get debugLog_copied => 'Копирано лого за отстраняване на грешки';

  @override
  String get debugLog_bleCopied => 'Копиран лог от BLE';

  @override
  String get debugLog_noEntries => 'Все още няма дебъг логове.';

  @override
  String get debugLog_enableInSettings =>
      'Активирайте отстраняване на грешки в настройките на приложението';

  @override
  String get debugLog_frames => 'Рамки';

  @override
  String get debugLog_rawLogRx => 'Raw Log-RX';

  @override
  String get debugLog_noBleActivity => 'Няма BLE активност към момента.';

  @override
  String debugFrame_length(int count) {
    return 'Дължина на кадъра: $count байта';
  }

  @override
  String debugFrame_command(String value) {
    return 'Команда: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Съобщение:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Дестинация Публичен Ключ: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Време: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Флагове: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Тип текст: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Просто';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Хексадесетичен Dump:';

  @override
  String get chat_pathManagement => 'Управление на пътища';

  @override
  String get chat_ShowAllPaths => 'Покажи всички пътища';

  @override
  String get chat_routingMode => 'Режим на маршрутизиране';

  @override
  String get chat_autoUseSavedPath => 'Автоматично (използвай запазения път)';

  @override
  String get chat_forceFloodMode => 'Принуди режим на наводняване';

  @override
  String get chat_recentAckPaths =>
      'Неотдавни ACK пътища (докоснете, за да използвате):';

  @override
  String get chat_pathHistoryFull =>
      'Историята на пътя е пълна. Премахнете записи, за да добавите нови.';

  @override
  String get chat_hopSingular => 'скочи';

  @override
  String get chat_hopPlural => 'скоци';

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
  String get chat_successes => 'Успехи';

  @override
  String get chat_removePath => 'Премахни пътя';

  @override
  String get chat_noPathHistoryYet =>
      'Няма история на пътищата още.\nИзпратете съобщение, за да откриете пътища.';

  @override
  String get chat_pathActions => 'Действия по пътя:';

  @override
  String get chat_setCustomPath => 'Задайте персонализиран път';

  @override
  String get chat_setCustomPathSubtitle => 'Ръчно укажете маршрутен път';

  @override
  String get chat_clearPath => 'Почисти Път';

  @override
  String get chat_clearPathSubtitle =>
      'Принуди преоткриване при следващо изпращане';

  @override
  String get chat_pathCleared =>
      'Пътят е почистен. Следващото съобщение ще открие маршрута отново.';

  @override
  String get chat_floodModeSubtitle =>
      'Използвайте превключвателя за маршрутизиране в лентата на приложението.';

  @override
  String get chat_floodModeEnabled =>
      'Режим на наводнение е активиран. Включете го отново чрез иконката за маршрутизиране в лентата на приложението.';

  @override
  String get chat_fullPath => 'Пълен път';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Детайлите за пътя все още не са налични. Опитайте да изпратите съобщение, за да освежите.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Пътят е зададен: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Запазено локално. Свържете се за синхронизиране.';

  @override
  String get chat_pathDeviceConfirmed => 'Устройство потвърдено.';

  @override
  String get chat_pathDeviceNotConfirmed =>
      'Устройството все още не е потвърдено.';

  @override
  String get chat_type => 'Въведете';

  @override
  String get chat_path => 'Пътекино';

  @override
  String get chat_publicKey => 'Публичен ключ';

  @override
  String get chat_compressOutgoingMessages =>
      'Компресиране на изходящи съобщения';

  @override
  String get chat_floodForced => 'Потоп (принуден)';

  @override
  String get chat_directForced => 'Директно (принудително)';

  @override
  String chat_hopsForced(int count) {
    return '$count скока (принудително)';
  }

  @override
  String get chat_floodAuto => 'Потоп (автоматично)';

  @override
  String get chat_direct => 'Директно';

  @override
  String get chat_poiShared => 'Споделено място от интерес';

  @override
  String chat_unread(int count) {
    return 'Непрочетени: $count';
  }

  @override
  String get chat_openLink => 'Отваряне на връзката?';

  @override
  String get chat_openLinkConfirmation =>
      'Искате ли да отворите тази връзка в браузъра си?';

  @override
  String get chat_open => 'Отвори';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Не можа да се отвори връзката: $url';
  }

  @override
  String get chat_invalidLink => 'Невалиден формат на връзката';

  @override
  String get map_title => 'Карта на възлите';

  @override
  String get map_lineOfSight => 'Линия на видимост';

  @override
  String get map_losScreenTitle => 'Линия на видимост';

  @override
  String get map_noNodesWithLocation => 'Няма възли с данни за местоположение.';

  @override
  String get map_nodesNeedGps =>
      'Възлагат се възлозите да споделят техните GPS координати,\nза да се появят на картата.';

  @override
  String map_nodesCount(int count) {
    return 'Нодове: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Ключове: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Повтарящ се';

  @override
  String get map_room => 'Стая';

  @override
  String get map_sensor => 'Датчик';

  @override
  String get map_pinDm => 'Задържане (DM)';

  @override
  String get map_pinPrivate => 'Задържане (Приватно)';

  @override
  String get map_pinPublic => 'Публичен ключ';

  @override
  String get map_lastSeen => 'Последна видяна';

  @override
  String get map_disconnectConfirm =>
      'Сигурни ли сте, че искате да се откъснете от това устройство?';

  @override
  String get map_from => 'От';

  @override
  String get map_source => 'Източник';

  @override
  String get map_flags => 'Флаг';

  @override
  String get map_shareMarkerHere => 'Споделете маркер тук';

  @override
  String get map_pinLabel => 'Етикетиране на пин';

  @override
  String get map_label => 'Етикет';

  @override
  String get map_pointOfInterest => 'Точка на интерес';

  @override
  String get map_sendToContact => 'Изпрати на контакт';

  @override
  String get map_sendToChannel => 'Изпрати в канала';

  @override
  String get map_noChannelsAvailable => 'Няма налични канали';

  @override
  String get map_publicLocationShare => 'Споделяне на публично място';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Ще споделите местоположение в $channelLabel. Този канал е публичен и всеки с PSK може да го види.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Свържете се с устройство, за да споделите маркери.';

  @override
  String get map_filterNodes => 'Филтрирайте възли';

  @override
  String get map_nodeTypes => 'Типове възли';

  @override
  String get map_chatNodes => 'Възли на чата';

  @override
  String get map_repeaters => 'Повторители';

  @override
  String get map_otherNodes => 'Други възли';

  @override
  String get map_keyPrefix => 'Префикс на ключа';

  @override
  String get map_filterByKeyPrefix => 'Филтрирайте по префикс на ключ';

  @override
  String get map_publicKeyPrefix => 'Префикс на публичен ключ';

  @override
  String get map_markers => 'Маркери';

  @override
  String get map_showSharedMarkers => 'Покажи споделени маркери';

  @override
  String get map_showGuessedLocations =>
      'Покажете местоположенията на предположените възли.';

  @override
  String get map_showDiscoveryContacts => 'Покажи контакти за откриване';

  @override
  String get map_guessedLocation => 'Предполагано местоположение';

  @override
  String get map_lastSeenTime => 'Последна видяна дата';

  @override
  String get map_sharedPin => 'Споделено копие';

  @override
  String get map_joinRoom => 'Присъедини се към стаята';

  @override
  String get map_manageRepeater => 'Управление на Повтарящ се Елемент';

  @override
  String get map_tapToAdd =>
      'Натиснете върху възлите, за да ги добавите към пътя.';

  @override
  String get map_runTrace => 'Изпълни Път на Следване';

  @override
  String get map_removeLast => 'Премахни Последно';

  @override
  String get map_pathTraceCancelled => 'Отменен е следването на пътя.';

  @override
  String get mapCache_title => 'Кеш на офлайн карти';

  @override
  String get mapCache_selectAreaFirst => 'Изберете област за кеширане първа';

  @override
  String get mapCache_noTilesToDownload =>
      'Няма плочки за изтегляне за тази област.';

  @override
  String get mapCache_downloadTilesTitle => 'Изтегли плочки';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Изтегли $count плочки за офлайн употреба?';
  }

  @override
  String get mapCache_downloadAction => 'Изтегли';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Кеширани $count плочки';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Запазени $downloaded плочки ($failed неуспешни)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Изчисти офлайн кеша';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Премахнете всички кеширани плочки на картата?';

  @override
  String get mapCache_offlineCacheCleared =>
      'Кешът на устройството е изчистен.';

  @override
  String get mapCache_noAreaSelected => 'Няма избрана област';

  @override
  String get mapCache_cacheArea => 'Област с кеш';

  @override
  String get mapCache_useCurrentView => 'Използвайте текущия изглед';

  @override
  String get mapCache_zoomRange => 'Обхват на увеличението';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Очаквани плочки: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Изтеглено $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Изтегли Плочки';

  @override
  String get mapCache_clearCacheButton => 'Изчисти кеша';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Неуспешни изтегляния: $count';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'Север $north, Юг $south, Изток $east, Запад $west';
  }

  @override
  String get time_justNow => 'Сега';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes минути преди';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours часа преди';
  }

  @override
  String time_daysAgo(int days) {
    return '$days дни преди';
  }

  @override
  String get time_hour => 'час';

  @override
  String get time_hours => 'часове';

  @override
  String get time_day => 'ден';

  @override
  String get time_days => 'дни';

  @override
  String get time_week => 'седмица';

  @override
  String get time_weeks => 'секти';

  @override
  String get time_month => 'месец';

  @override
  String get time_months => 'месеци';

  @override
  String get time_minutes => 'минути';

  @override
  String get time_allTime => 'Всичко време';

  @override
  String get dialog_disconnect => 'Прекъсни';

  @override
  String get dialog_disconnectConfirm =>
      'Сигурни ли сте, че искате да се откъснете от това устройство?';

  @override
  String get login_repeaterLogin => 'Повторител Вход';

  @override
  String get login_roomLogin => 'Вход в стаята';

  @override
  String get login_password => 'Парола';

  @override
  String get login_enterPassword => 'Въведете парола';

  @override
  String get login_savePassword => 'Запази парола';

  @override
  String get login_savePasswordSubtitle =>
      'Паролата ще бъде съхранена сигурно на това устройство.';

  @override
  String get login_repeaterDescription =>
      'Въведете паролата на репитера, за да получите достъп до настройките и статуса.';

  @override
  String get login_roomDescription =>
      'Въведете паролата на стаята, за да получите достъп до настройките и статуса.';

  @override
  String get login_routing => 'Маршрутизиране';

  @override
  String get login_routingMode => 'Режим на маршрутизиране';

  @override
  String get login_autoUseSavedPath => 'Автоматично (използвай запазения път)';

  @override
  String get login_forceFloodMode => 'Принуди режим на наводняване';

  @override
  String get login_managePaths => 'Управление на пътища';

  @override
  String get login_login => 'Вход';

  @override
  String login_attempt(int current, int max) {
    return 'Опитвате $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Входът не беше успешен: $error';
  }

  @override
  String get login_failedMessage =>
      'Входът не беше успешен. Или паролата е грешна, или повторителят е недостъпен.';

  @override
  String get common_reload => 'Презареди';

  @override
  String get common_clear => 'Изчисти';

  @override
  String path_currentPath(String path) {
    return 'Текущ път: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'Използване на $count $_temp0 път';
  }

  @override
  String get path_enterCustomPath => 'Въведете персонализиран път';

  @override
  String get path_currentPathLabel => 'Текущ път';

  @override
  String get path_hexPrefixInstructions =>
      'Въведете 2-символни шестнадесетични префикси за всеки хоп, разделени с кама.';

  @override
  String get path_hexPrefixExample =>
      'A1,F2,3C (всяка нода използва първия байт от публичния си ключ)';

  @override
  String get path_labelHexPrefixes => 'Пътеки (шестнадесетични префикси)';

  @override
  String get path_helperMaxHops =>
      'Максимум 64 скока. Всеки префикс е 2 шестнадесетични знака (1 байт).';

  @override
  String get path_selectFromContacts => 'Изберете от контакти:';

  @override
  String get path_noRepeatersFound =>
      'Няма намерени репетитори или сървъри на стаи.';

  @override
  String get path_customPathsRequire =>
      'Персонализираните пътища изискват междинни скокове, които могат да препращат съобщения.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Невалидни шестнадесетични префикси: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Пътят е твърде дълъг. Максимум 64 скока са разрешени.';

  @override
  String get path_setPath => 'Задайте път';

  @override
  String get repeater_management => 'Управление на повторители';

  @override
  String get room_management => 'Управление на сървъра за стая';

  @override
  String get repeater_managementTools => 'Инструменти за управление';

  @override
  String get repeater_status => 'Статус';

  @override
  String get repeater_statusSubtitle =>
      'Прегледайте статуса, статистиката и съседните устройства.';

  @override
  String get repeater_telemetry => 'Телеметрия';

  @override
  String get repeater_telemetrySubtitle =>
      'Прегледайте телеметрията на сензорите и системните статистики';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Изпрати команди към ретранслатора';

  @override
  String get repeater_neighbors => 'Съседи';

  @override
  String get repeater_neighborsSubtitle =>
      'Преглед на съседни възли с нулев скок.';

  @override
  String get repeater_settings => 'Настройки';

  @override
  String get repeater_settingsSubtitle =>
      'Конфигурирайте параметрите на репитера';

  @override
  String get repeater_statusTitle => 'Статус на повтарянето';

  @override
  String get repeater_routingMode => 'Режим на маршрутизиране';

  @override
  String get repeater_autoUseSavedPath =>
      'Автоматично (използвай запазения път)';

  @override
  String get repeater_forceFloodMode => 'Принуди режим на наводняване';

  @override
  String get repeater_pathManagement => 'Управление на пътища';

  @override
  String get repeater_refresh => 'Презареди';

  @override
  String get repeater_statusRequestTimeout =>
      'Заявката за статус премина прекалено дълго.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Грешка при зареждане на статуса: $error';
  }

  @override
  String get repeater_systemInformation => 'Информация за системата';

  @override
  String get repeater_battery => 'Батерия';

  @override
  String get repeater_clockAtLogin => 'Часовник (при влизане)';

  @override
  String get repeater_uptime => 'Наличност';

  @override
  String get repeater_queueLength => 'Дължина на опашката';

  @override
  String get repeater_debugFlags => 'Контролни точки за отстраняване на грешки';

  @override
  String get repeater_radioStatistics => 'Статистика на радиостанциите';

  @override
  String get repeater_lastRssi => 'Последна RSSI';

  @override
  String get repeater_lastSnr => 'Последна SNR';

  @override
  String get repeater_noiseFloor => 'Ниво на шум';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Статистика на пакетите';

  @override
  String get repeater_sent => 'Изпратено';

  @override
  String get repeater_received => 'Получено';

  @override
  String get repeater_duplicates => 'Дубликати';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days дни $hoursч $minutesм $secondsс';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Общо: $total, Наводнение: $flood, Директно: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Общо: $total, Наводнение: $flood, Директно: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Поливане: $flood, Директен: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Общо: $total';
  }

  @override
  String get repeater_settingsTitle => 'Настройки на повтарящия се елемент';

  @override
  String get repeater_basicSettings => 'Основни настройки';

  @override
  String get repeater_repeaterName => 'Име на повтарящ се елемент';

  @override
  String get repeater_repeaterNameHelper =>
      'Показване на името на този репитер';

  @override
  String get repeater_adminPassword => 'Парола на администратора';

  @override
  String get repeater_adminPasswordHelper => 'Пълен достъпен парола';

  @override
  String get repeater_guestPassword => 'Парола на гост';

  @override
  String get repeater_guestPasswordHelper => 'Достъп с ограничен достъп';

  @override
  String get repeater_radioSettings => 'Настройки на радиостанцията';

  @override
  String get repeater_frequencyMhz => 'Честота (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Ширина на честотния спектър';

  @override
  String get repeater_spreadingFactor => 'Фактор на разпространение';

  @override
  String get repeater_codingRate => 'Такса за кодиране';

  @override
  String get repeater_locationSettings => 'Настройки на местоположението';

  @override
  String get repeater_latitude => 'Широчина';

  @override
  String get repeater_latitudeHelper => 'Десетични градуси (напр. 37.7749)';

  @override
  String get repeater_longitude => 'Дължина';

  @override
  String get repeater_longitudeHelper =>
      'Градуси с десетични знаци (напр. -122.4194)';

  @override
  String get repeater_features => 'Характеристики';

  @override
  String get repeater_packetForwarding => 'Пренасочване на пакети';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Активирайте репитера, за да препращате пакети.';

  @override
  String get repeater_guestAccess => 'Достъп за Гост';

  @override
  String get repeater_guestAccessSubtitle => 'Разрешете самочетене за гости';

  @override
  String get repeater_privacyMode => 'Режим на поверителност';

  @override
  String get repeater_privacyModeSubtitle =>
      'Скриване на име/местоположение в рекламите';

  @override
  String get repeater_advertisementSettings => 'Настройки на рекламите';

  @override
  String get repeater_localAdvertInterval => 'Местен Рекламен Интервал';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes минути';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Интервал на рекламата за наводнения';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours часа';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Криптиран Рекламен Интервал';

  @override
  String get repeater_dangerZone =>
      'Опасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно';

  @override
  String get repeater_rebootRepeater => 'БеРестартирай Репитер';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Рестартирайте ретранслатора.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Сигурни ли сте, че искате да рестартирате този репитер?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Генериране на Ключ за Идентичност';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Генериране на нова двойка публичен/частен ключ';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'БеТова ще генерира нова идентичност за репитера. Продължете?';

  @override
  String get repeater_eraseFileSystem => 'Изтрий Файлова Система';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Форматирайте файла на репитера';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ВНИМАНИЕ: Това ще изтрие всички данни от репетитора. Това не може да бъде отменено!';

  @override
  String get repeater_eraseSerialOnly =>
      'Изтриването е достъпно само през серийния терминал.';

  @override
  String repeater_commandSent(String command) {
    return 'Командата е изпратена: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Грешка при изпращане на командата: $error';
  }

  @override
  String get repeater_confirm => 'БеПотвърди';

  @override
  String get repeater_settingsSaved => 'Настройките са запазени успешно.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Грешка при запазване на настройките: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Обнови Основни Настройки';

  @override
  String get repeater_refreshRadioSettings =>
      'Обнови настройките на радиопредавателите';

  @override
  String get repeater_refreshTxPower => 'Обнови TX захранване';

  @override
  String get repeater_refreshLocationSettings =>
      'Обнови настройките на местоположението';

  @override
  String get repeater_refreshPacketForwarding => 'Обнови пакетно пренасочване';

  @override
  String get repeater_refreshGuestAccess => 'Обнови достъп за гости';

  @override
  String get repeater_refreshPrivacyMode => 'Обнови Режим на поверителност';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Обнови Настройки на Рекламата';

  @override
  String repeater_refreshed(String label) {
    return '$label е обновено';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Грешка при обновяване на $label';
  }

  @override
  String get repeater_cliTitle => 'Повторител CLI';

  @override
  String get repeater_debugNextCommand => 'Поправи Следваща Команда';

  @override
  String get repeater_commandHelp => 'Помощ';

  @override
  String get repeater_clearHistory => 'Изчисти История';

  @override
  String get repeater_noCommandsSent => 'Няма изпратени команди засега.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Въведете команда по-долу или използвайте бързи команди';

  @override
  String get repeater_enterCommandHint => 'Въведете команда...';

  @override
  String get repeater_previousCommand => 'Предходна команда';

  @override
  String get repeater_nextCommand => 'Следваща команда';

  @override
  String get repeater_enterCommandFirst => 'Въведете първо команда.';

  @override
  String get repeater_cliCommandFrameTitle => 'Рамка за команда CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Грешка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Получи име';

  @override
  String get repeater_cliQuickGetRadio => 'Получи радио';

  @override
  String get repeater_cliQuickGetTx => 'Получи TX';

  @override
  String get repeater_cliQuickNeighbors => 'Съседи';

  @override
  String get repeater_cliQuickVersion => 'Версия';

  @override
  String get repeater_cliQuickAdvertise => 'Рекламирай';

  @override
  String get repeater_cliQuickClock => 'Часовник';

  @override
  String get repeater_cliHelpAdvert => 'Изпраща рекламен пакет';

  @override
  String get repeater_cliHelpReboot =>
      'Рестартира устройството. (Забележка, може да получите \'Timeout\', което е нормално)';

  @override
  String get repeater_cliHelpClock =>
      'Показва текущото време според часовника на всяко устройство.';

  @override
  String get repeater_cliHelpPassword =>
      'Задава се нова администраторска парола за устройството.';

  @override
  String get repeater_cliHelpVersion =>
      'Показва версията на устройството и датата на компилация на фърмуера.';

  @override
  String get repeater_cliHelpClearStats =>
      'Рестартира различни статистики броячи до нула.';

  @override
  String get repeater_cliHelpSetAf => 'Задава времето на фактора.';

  @override
  String get repeater_cliHelpSetTx =>
      'Задава се мощността на предаване на LoRa в dBm (отчитане спрямо референтно ниво).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Активира или деактивира ролята на репитера за този възел.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Сървър на стаята) Ако е \"включено\", тогава влизането с празен парола ще бъде разрешено, но не може да публикува в стаята (само четене).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Задава максималния брой хопове на входящ пакет за заливване (ако >= max, пакетът не се предава).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Задава праг на интерференцията (в dB). По подразбиране е 14. Задайте на 0, за да деактивирате откриването на интерференция на каналите.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Задава интервала за рестартиране на Автоматичния контролер за усилване. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Активира или деактивира функцията \'двойни ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Задава интервала на таймера в минути за изпращане на локален (безпроблемен) рекламен пакет. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Задава интервала на таймера в часове за изпращане на пакет с реклама за наводнение. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Задава/обновява паролата на гост. (за повторители, гостите могат да изпращат заявката \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Задава име на обявата.';

  @override
  String get repeater_cliHelpSetLat =>
      'Задава географска ширина на картата с реклами (в десетими градуси).';

  @override
  String get repeater_cliHelpSetLon =>
      'Задава обхвата на дължина на картата на рекламата. (десетими градуса)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Задава напълно нови радио параметри и ги запазва в предпочитанията. Изисква команда \"рестарт\", за да бъдат приложени.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Зададени (експериментални) основи (трябва да е > 1 за ефект) за прилагане на леко забавяне на получените пакети, базирано на силата на сигнала/резултата. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Задава фактор, умножен по времето на въздух за пакет в режим на наводнение и с рандомизирана система за слотове, за да забави предаването му (за да намали вероятността от сблъсъци).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Същото като txdelay, но за прилагане на случайна забавяне при препращането на пакети в директен режим.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Активиране/Деактивиране на мост.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Задайте забавяне преди преизпращане на пакети.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Изберете дали мостът ще предава препратени пакети или получени пакети.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Задайте скоростта на предаване за RS232 мостовете.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Задайте тайна за мостовете на EspNow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Задава персонализиран коефициент за коригиране на отчетеното напрежение на батерията (поддържа се само на избрани дъски).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Задава временни радио параметри за посочения брой минути, връщайки се към оригиналните радио параметри след това. (не се запазва в предпочитанията).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Променя ACL. Премахва съответстващия запис (по префикс на pubkey), ако \"permissions\" е нула. Добавя нов запис, ако pubkey-hex е с пълна дължина и не е в ACL. Актуализира запис, съответстващ на префикса на pubkey. Битовете за разрешения варират според ролята на firmware, но долните 2 бита са: 0 (Гост), 1 (Само четене), 2 (Четене и писане), 3 (Администратор).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Получава тип мост none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Започва записване на пакети във файловата система.';

  @override
  String get repeater_cliHelpLogStop =>
      'Спира записването на пакети във файловата система.';

  @override
  String get repeater_cliHelpLogErase =>
      'Изтрива логовете от пакета от файловата система.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Показва списък с други възли на репитер, чути чрез нулев хоп реклами. Всяка линия е id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Премахва първия съвпадащ запис (по префикси на pubkey (hex)) от списъка с съседи.';

  @override
  String get repeater_cliHelpRegion =>
      '(сериен режим) Изброява всички дефинирани региони и текущите разрешения за наводнения.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Забележка: това е специално многокомандно извикване. Всяка следваща команда е име на регион (отстъпен с интервали, за да се покаже йерархията, с минимум един интервал). Завършва се чрез изпращане на празен ред/команда.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Търси регион с даден префикс на име (или \"\" за глобалния обхват). Отговаря с \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Добавя или актуализира дефиниция на регион с дадено име.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Премахва дефиниция на регион с дадено име. (трябва да съвпада точно и да няма подрегиони)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Задава \'Потоп\' разрешение за посочената област. (\'\' за глобалния/стария обхват)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Премахва разрешението \"F\"лоуд за посочената област. (ЗАБЕЛЕЖКА: в момента не се препоръчва да се използва на глобалното/старото ниво!! )';

  @override
  String get repeater_cliHelpRegionHome =>
      'Отговаря с текущия \'home\' регион. (Забележка: не е приложена никъде, запазена за бъдещи нужди).';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Задава \'домашно\' региона.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Запазва списъка/картата с региони в съхранение.';

  @override
  String get repeater_cliHelpGps =>
      'Показва статуса на GPS. Когато GPS е изключен, отговаря само с \"off\", ако е включен отговаря с \"on\", статус, fix, брой на сателити.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Включва/Изключва GPS захранването.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Синхронизира времето на възела с GPS часовника.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Задава координатите на нодата по GPS и запазва предпочитанията.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Предоставя конфигурацията на рекламата за местоположението на възела:\n- none: не включвайте местоположението в рекламите\n- share: споделяйте gps местоположението (от SensorManager)\n- prefs: рекламирайте местоположението, съхранено в предпочитанията';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Задава конфигурация на обявите за местоположение.';

  @override
  String get repeater_commandsListTitle => 'Списък с команди';

  @override
  String get repeater_commandsListNote =>
      'ЗАБЕЛЕЖКА: за различните команди \"set ...\", също така съществува команда \"get ...\".';

  @override
  String get repeater_general => 'Общо';

  @override
  String get repeater_settingsCategory => 'Настройки';

  @override
  String get repeater_bridge => 'Мост';

  @override
  String get repeater_logging => 'Логване';

  @override
  String get repeater_neighborsRepeaterOnly => 'Съседи (Само за повтаряне)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Управление на региони (Само за повтарящ се канал)';

  @override
  String get repeater_regionNote =>
      'Регионните команди са въведени, за да управляват дефинициите и разрешенията на регионите.';

  @override
  String get repeater_gpsManagement => 'Управление на GPS';

  @override
  String get repeater_gpsNote =>
      'GPS командата е въведена, за да управлява теми, свързани с местоположението.';

  @override
  String get telemetry_receivedData => 'Получени телеметрични данни';

  @override
  String get telemetry_requestTimeout => 'Заявката за телеметрия е прекъсната.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Грешка при зареждане на телеметрията: $error';
  }

  @override
  String get telemetry_noData => 'Няма налични данни за телеметрията.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Канал $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Батерия';

  @override
  String get telemetry_voltageLabel => 'Напрежение';

  @override
  String get telemetry_mcuTemperatureLabel => 'Температура на MCU';

  @override
  String get telemetry_temperatureLabel => 'Температура';

  @override
  String get telemetry_currentLabel => 'Текущо';

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
  String get neighbors_receivedData => 'Получени данни за съседи';

  @override
  String get neighbors_requestTimedOut => 'Съседите поискат изтичане на време.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Грешка при зареждане на съседи: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Повторители Съседи';

  @override
  String get neighbors_noData => 'Няма налични данни за съседи.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Неизвестна $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Слушано преди $time.';
  }

  @override
  String get channelPath_title => 'Пътеки пъзел';

  @override
  String get channelPath_viewMap => 'Преглед на картата';

  @override
  String get channelPath_otherObservedPaths => 'Други Наблюдавани Пътища';

  @override
  String get channelPath_repeaterHops => 'Повтарящи се скокове';

  @override
  String get channelPath_noHopDetails =>
      'Детайлите за пакета не са предоставени.';

  @override
  String get channelPath_messageDetails => 'Подробности на съобщението';

  @override
  String get channelPath_senderLabel => 'Изпращач';

  @override
  String get channelPath_timeLabel => 'Време';

  @override
  String get channelPath_repeatsLabel => 'Повтаря';

  @override
  String channelPath_pathLabel(int index) {
    return 'Път $index';
  }

  @override
  String get channelPath_observedLabel => 'Наблюдавано';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Наблюдаван път $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Няма данни за местоположение.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Неизвестно';

  @override
  String get channelPath_floodPath => 'Поливане';

  @override
  String get channelPath_directPath => 'Директно';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 от $total скокове';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed от $total скокове';
  }

  @override
  String get channelPath_mapTitle => 'Карта на пътя';

  @override
  String get channelPath_noRepeaterLocations =>
      'Няма налични местоположения на повторителите за този път.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Път $index (Основен)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Пътекино';

  @override
  String get channelPath_observedPathHeader => 'Наблюдаван път';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Няма налични детайли за този пакет.';

  @override
  String get channelPath_unknownRepeater => 'Неизвестен повторител';

  @override
  String get community_title => 'Общност';

  @override
  String get community_create => 'Създай общност';

  @override
  String get community_createDesc =>
      'Създайте нова общност и я споделете чрез QR код.';

  @override
  String get community_join => 'Присъедини се';

  @override
  String get community_joinTitle => 'Присъедини се към общността';

  @override
  String community_joinConfirmation(String name) {
    return 'Искате ли да се присъедините към общността \"$name\"?';
  }

  @override
  String get community_scanQr => 'Сканирайте QR кода на общността';

  @override
  String get community_scanInstructions =>
      'Насочете камерата към QR код на общността';

  @override
  String get community_showQr => 'Покажи QR код';

  @override
  String get community_publicChannel => 'Обществено общност';

  @override
  String get community_hashtagChannel => 'Хаштаг на общността';

  @override
  String get community_name => 'Име на общността';

  @override
  String get community_enterName => 'Въведете име на общността';

  @override
  String community_created(String name) {
    return 'Общността \"$name\" е създадена';
  }

  @override
  String community_joined(String name) {
    return 'Присъединено общност \"$name\"';
  }

  @override
  String get community_qrTitle => 'Споделяне в общността';

  @override
  String community_qrInstructions(String name) {
    return 'Сканирайте този QR код, за да се присъедините към $name.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Хаштаг каналите на общността са достъпни само за членове на общността';

  @override
  String get community_invalidQrCode => 'Невалиден QR код на общността';

  @override
  String get community_alreadyMember => 'Вече съм член';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Вие вече сте член на \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Добави публичен общностен канал';

  @override
  String get community_addPublicChannelHint =>
      'Автоматично добавете публичния канал за тази общност.';

  @override
  String get community_noCommunities => 'Няма присъединени общности още.';

  @override
  String get community_scanOrCreate =>
      'Сканирайте QR код или създайте общност, за да започнете.';

  @override
  String get community_manageCommunities => 'Управление на общности';

  @override
  String get community_delete => 'Напусни общността';

  @override
  String community_deleteConfirm(String name) {
    return 'Напускате \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Това ще изтрие също $count канал(а) и техните съобщения.';
  }

  @override
  String community_deleted(String name) {
    return 'Остави общността \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Регенерейрай секрет';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Регенерация на секретния ключ за \"$name\"? Всички членове ще трябва да сканират новия QR код, за да продължат комуникацията.';
  }

  @override
  String get community_regenerate => 'Регенерация';

  @override
  String community_secretRegenerated(String name) {
    return 'Секретно презареждане за \"$name\"';
  }

  @override
  String get community_updateSecret => 'Актуализирай тайна';

  @override
  String community_secretUpdated(String name) {
    return 'Секретно обновено за \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Сканьорвайте новия QR код, за да актуализирате секрета за \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Добави общностен хаштаг';

  @override
  String get community_addHashtagChannelDesc =>
      'Добавете хаштаг канал за тази общност';

  @override
  String get community_selectCommunity => 'Изберете общност';

  @override
  String get community_regularHashtag => 'Обикновен хаштаг';

  @override
  String get community_regularHashtagDesc =>
      'Общ хаштаг (всеки може да се присъедини)';

  @override
  String get community_communityHashtag => 'Общностен хаштаг';

  @override
  String get community_communityHashtagDesc => 'Само за членове на общността';

  @override
  String community_forCommunity(String name) {
    return 'За $name';
  }

  @override
  String get listFilter_tooltip => 'Филтрирайте и сортирайте';

  @override
  String get listFilter_sortBy => 'Сортирай по';

  @override
  String get listFilter_latestMessages => 'Последни съобщения';

  @override
  String get listFilter_heardRecently => 'Слушано е наскоро';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Филтри';

  @override
  String get listFilter_all => 'Всички';

  @override
  String get listFilter_favorites => 'Любими';

  @override
  String get listFilter_addToFavorites => 'Добави към любими';

  @override
  String get listFilter_removeFromFavorites => 'Премахване от списъка с любими';

  @override
  String get listFilter_users => 'Потребители';

  @override
  String get listFilter_repeaters => 'Повторители';

  @override
  String get listFilter_roomServers => 'Сървъри на стая';

  @override
  String get listFilter_unreadOnly => 'Само непрочетените';

  @override
  String get listFilter_newGroup => 'Нова група';

  @override
  String get pathTrace_you => 'Вие';

  @override
  String get pathTrace_failed => 'Пътят за проследяване не успя.';

  @override
  String get pathTrace_notAvailable => 'Пътека за проследяване не е достъпна.';

  @override
  String get pathTrace_refreshTooltip => 'Обнови Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Един или повече от хмелите липсва местоположение!';

  @override
  String get pathTrace_clearTooltip => 'Изчисти пътя';

  @override
  String get losSelectStartEnd => 'Изберете начални и крайни възли за LOS.';

  @override
  String losRunFailed(String error) {
    return 'Проверката на пряката видимост е неуспешна: $error';
  }

  @override
  String get losClearAllPoints => 'Изчистете всички точки';

  @override
  String get losRunToViewElevationProfile =>
      'Стартирайте LOS, за да видите профила на надморската височина';

  @override
  String get losMenuTitle => 'LOS меню';

  @override
  String get losMenuSubtitle =>
      'Докоснете възли или натиснете продължително карта за персонализирани точки';

  @override
  String get losShowDisplayNodes => 'Показване на възли на дисплея';

  @override
  String get losCustomPoints => 'Персонализирани точки';

  @override
  String losCustomPointLabel(int index) {
    return 'Персонализирано $index';
  }

  @override
  String get losPointA => 'Точка А';

  @override
  String get losPointB => 'Точка Б';

  @override
  String losAntennaA(String value, String unit) {
    return 'Антена A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Антена B: $value $unit';
  }

  @override
  String get losRun => 'Стартирайте LOS';

  @override
  String get losNoElevationData => 'Няма данни за надморска височина';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, чист LOS, минимално разстояние $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, блокиран от $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: проверка...';

  @override
  String get losStatusNoData => 'LOS: няма данни';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total ясно, $blocked блокирано, $unknown неизвестно';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Няма налични данни за надморска височина за една или повече проби.';

  @override
  String get losErrorInvalidInput =>
      'Невалидни данни за точки/надморска височина за изчисляване на LOS.';

  @override
  String get losRenameCustomPoint => 'Преименувайте персонализирана точка';

  @override
  String get losPointName => 'Име на точката';

  @override
  String get losShowPanelTooltip => 'Показване на LOS панел';

  @override
  String get losHidePanelTooltip => 'Скриване на LOS панела';

  @override
  String get losElevationAttribution =>
      'Данни за надморска височина: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Радиохоризонт';

  @override
  String get losLegendLosBeam => 'Линия на видимост';

  @override
  String get losLegendTerrain => 'Терен';

  @override
  String get losFrequencyLabel => 'Честота';

  @override
  String get losFrequencyInfoTooltip => 'Преглед на детайли за изчислението';

  @override
  String get losFrequencyDialogTitle => 'Изчисляване на радиохоризонта';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Започвайки от k=$baselineK при $baselineFreq MHz, изчислението коригира k-фактора за текущата $frequencyMHz MHz лента, която определя границата на извития радиохоризонт.';
  }

  @override
  String get contacts_pathTrace => 'Пътен проследяване';

  @override
  String get contacts_ping => 'Пинг';

  @override
  String get contacts_repeaterPathTrace => 'Трасировка до повторител';

  @override
  String get contacts_repeaterPing => 'Пингване на повторителя';

  @override
  String get contacts_roomPathTrace => 'Трасиране на път до съ';

  @override
  String get contacts_roomPing => 'Ping на сървъра на стаята';

  @override
  String get contacts_chatTraceRoute => 'Трасиране на път';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Проследи маршрут към $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Клипборда е празна.';

  @override
  String get contacts_invalidAdvertFormat => 'Невалидни данни за контакт';

  @override
  String get contacts_contactImported => 'Контактът е импортиран.';

  @override
  String get contacts_contactImportFailed =>
      'Контактът не е успешно импортиран.';

  @override
  String get contacts_zeroHopAdvert => 'Реклама без скок';

  @override
  String get contacts_floodAdvert => 'Потопна реклама';

  @override
  String get contacts_copyAdvertToClipboard => 'Копирай обявата в клипборда';

  @override
  String get contacts_addContactFromClipboard => 'Добави контакт от клипборда';

  @override
  String get contacts_ShareContact => 'Копирай контакт в клипборда';

  @override
  String get contacts_ShareContactZeroHop => 'Сподели контакт чрез обява';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Изпратен контакт по обява.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Неуспешно изпращане на контакт.';

  @override
  String get contacts_contactAdvertCopied =>
      'Рекламата е копирана в клипборда.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копирането на обявата в клипборда не успя.';

  @override
  String get notification_activityTitle => 'Активност на MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'съобщения',
      one: 'съобщение',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'съобщения в канали',
      one: 'съобщение в канал',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'нови възли',
      one: 'нов възел',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Открит нов $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Получено ново съобщение';

  @override
  String get settings_gpxExportRepeaters =>
      'Експортиране на повтарящи се устройства / сървър на стаята до GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Изпраща повторители / roomserver с местоположение в GPX файл.';

  @override
  String get settings_gpxExportContacts => 'Експортирай спътници към GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Експортира спътници с местоположение в GPX файл.';

  @override
  String get settings_gpxExportAll => 'Експортирай всички контакти в GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Експортира всички контакти с местоположение в файл GPX.';

  @override
  String get settings_gpxExportSuccess => 'Успешно изlexport на файл GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Няма контакти за изlexport.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Не е поддържан на вашето устройство/ОС';

  @override
  String get settings_gpxExportError => 'Възникна грешка при изнасяне.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Местоположения на повторител и сървър на стаята';

  @override
  String get settings_gpxExportChat => 'Местоположения на спътници';

  @override
  String get settings_gpxExportAllContacts =>
      'Местоположения на всички контакти';

  @override
  String get settings_gpxExportShareText =>
      'Картинни данни изнесени от meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open износ на данни за карта в формат GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Близки повтарящи се устройства';

  @override
  String get snrIndicator_lastSeen => 'Последно видян';

  @override
  String get contactsSettings_title => 'Настройки на контактите';

  @override
  String get contactsSettings_autoAddTitle => 'Автоматично откриване';

  @override
  String get contactsSettings_otherTitle =>
      'Други настройки свързани с контакти';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Автоматично добавяне на потребители';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Позволи на спътника да добавя автоматично откритите потребители.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Автоматично добавяне на повтарящи се елементи';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Позволи на спътника да добавя автоматично откритите повтарящи се устройства.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Автоматично добавяне на сървъри на стаите';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Позволи на спътника да добавя автоматично откритите сървъри на стаите.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Автоматично добавяне на датчици';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Позволи на спътника да добавя автоматично откритите датчици.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Премахни най-старото';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Когато списъкът с контакти е пълен, най-старият неключов контакт ще бъде заменен.';

  @override
  String get discoveredContacts_Title => 'Открити контакти';

  @override
  String get discoveredContacts_noMatching => 'Няма съвпадащи контакти';

  @override
  String get discoveredContacts_searchHint => 'Търсене на открити контакти';

  @override
  String get discoveredContacts_contactAdded => 'Контакт добавен';

  @override
  String get discoveredContacts_addContact => 'Добави контакт';

  @override
  String get discoveredContacts_copyContact => 'Копирай контакт в клипборда';

  @override
  String get discoveredContacts_deleteContact => 'Изтрий контакт';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Изтриване на Всички Открити Контакти';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Сигурни ли сте, че искате да изтриете всички открити контакти?';
}
