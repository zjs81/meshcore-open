// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Контакты';

  @override
  String get nav_channels => 'Каналы';

  @override
  String get nav_map => 'Карта';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Коннект';

  @override
  String get common_unknownDevice => 'Неизвестное устройство';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_deleteAll => 'Удалить все';

  @override
  String get common_close => 'Закрыть';

  @override
  String get common_edit => 'Изменить';

  @override
  String get common_add => 'Добавить';

  @override
  String get common_settings => 'Настройки';

  @override
  String get common_disconnect => 'Отключить';

  @override
  String get common_connected => 'Подключено';

  @override
  String get common_disconnected => 'Отключено';

  @override
  String get common_create => 'Создать';

  @override
  String get common_continue => 'Продолжить';

  @override
  String get common_share => 'Поделиться';

  @override
  String get common_copy => 'Копировать';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_hide => 'Скрыть';

  @override
  String get common_remove => 'Убрать';

  @override
  String get common_enable => 'Включить';

  @override
  String get common_disable => 'Выключить';

  @override
  String get common_reboot => 'Перезагрузить';

  @override
  String get common_loading => 'Загрузка...';

  @override
  String get common_notAvailable => '—';

  @override
  String common_voltageValue(String volts) {
    return '$volts В';
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
  String get usbScreenTitle => 'Подключение через USB';

  @override
  String get usbScreenSubtitle =>
      'Выберите обнаруженное устройство с последовательным интерфейсом и подключите его напрямую к вашему узлу MeshCore.';

  @override
  String get usbScreenStatus => 'Выберите USB-устройство';

  @override
  String get usbScreenNote =>
      'USB-серийный порт активен на поддерживаемых устройствах Android и на настольных платформах.';

  @override
  String get usbScreenEmptyState =>
      'Не обнаружено устройств USB. Подключите одно из них и обновите список.';

  @override
  String get usbErrorPermissionDenied =>
      'Запрос на доступ через USB был отклонен.';

  @override
  String get usbErrorDeviceMissing =>
      'Выбранное USB-устройство больше недоступно.';

  @override
  String get usbErrorInvalidPort => 'Выберите действительное USB-устройство.';

  @override
  String get usbErrorBusy =>
      'Еще одно запрошенное соединение через USB уже находится в процессе.';

  @override
  String get usbErrorNotConnected => 'Ни одно USB-устройство не подключено.';

  @override
  String get usbErrorOpenFailed =>
      'Не удалось открыть выбранное USB-устройство.';

  @override
  String get usbErrorConnectFailed =>
      'Не удалось установить соединение с выбранным USB-устройством.';

  @override
  String get usbErrorUnsupported =>
      'Поддержка последовательного USB отсутствует на данной платформе.';

  @override
  String get usbErrorAlreadyActive => 'USB-соединение уже установлено.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Не было выбрано ни одно устройство USB.';

  @override
  String get usbErrorPortClosed => 'USB-соединение не установлено.';

  @override
  String get usbErrorConnectTimedOut =>
      'Соединение не установлено. Убедитесь, что устройство имеет установленное программное обеспечение USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Устройство для последовательного подключения к сети';

  @override
  String get usbStatus_notConnected => 'Выберите USB-устройство';

  @override
  String get usbStatus_connecting => 'Подключение к USB-устройству...';

  @override
  String get usbStatus_searching => 'Поиск USB-устройств...';

  @override
  String usbConnectionFailed(String error) {
    return 'Не удалось установить соединение через USB: $error';
  }

  @override
  String get scanner_scanning => 'Поиск устройств...';

  @override
  String get scanner_connecting => 'Подключение...';

  @override
  String get scanner_disconnecting => 'Отключение...';

  @override
  String get scanner_notConnected => 'Не подключено';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Подключено к $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Поиск устройств MeshCore...';

  @override
  String get scanner_tapToScan => 'Нажмите для поиска MeshCore устройств';

  @override
  String scanner_connectionFailed(String error) {
    return 'Подключение не удалось: $error';
  }

  @override
  String get scanner_stop => 'Стоп';

  @override
  String get scanner_scan => 'Сканирование';

  @override
  String get scanner_bluetoothOff => 'Bluetooth выключен';

  @override
  String get scanner_bluetoothOffMessage =>
      'Пожалуйста, включите Bluetooth, чтобы найти устройства.';

  @override
  String get scanner_chromeRequired => 'Требуется браузер Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Для поддержки Bluetooth в этом веб-приложении требуется Google Chrome или браузер на базе Chromium.';

  @override
  String get scanner_enableBluetooth => 'Включите Bluetooth';

  @override
  String get device_quickSwitch => 'Быстрое переключение';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_deviceInfo => 'Информация об устройстве';

  @override
  String get settings_appSettings => 'Настройки приложения';

  @override
  String get settings_appSettingsSubtitle =>
      'Уведомления, сообщения и настройки карты';

  @override
  String get settings_nodeSettings => 'Настройки ноды';

  @override
  String get settings_nodeName => 'Имя ноды';

  @override
  String get settings_nodeNameNotSet => 'Не установлено';

  @override
  String get settings_nodeNameHint => 'Введите имя ноды';

  @override
  String get settings_nodeNameUpdated => 'Имя обновлено';

  @override
  String get settings_radioSettings => 'Настройки радио';

  @override
  String get settings_radioSettingsSubtitle =>
      'Частота, мощность и коэффициент распространения';

  @override
  String get settings_radioSettingsUpdated => 'Настройки радио обновлены';

  @override
  String get settings_location => 'Позиция';

  @override
  String get settings_locationSubtitle => 'Координаты GPS';

  @override
  String get settings_locationUpdated => 'Позиция и настройки GPS обновлены';

  @override
  String get settings_locationBothRequired => 'Введите широту и долготу.';

  @override
  String get settings_locationInvalid => 'Неверная широта или долгота.';

  @override
  String get settings_locationGPSEnable => 'Включить GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Включение GPS для автоматического обновления позиции.';

  @override
  String get settings_locationIntervalSec =>
      'Интервал для позиционирования GPS (секунды)';

  @override
  String get settings_locationIntervalInvalid =>
      'Интервал должен составлять не менее 60 секунд и не более 86400 секунд.';

  @override
  String get settings_latitude => 'Широта';

  @override
  String get settings_longitude => 'Долгота';

  @override
  String get settings_contactSettings => 'Настройки контактов';

  @override
  String get settings_contactSettingsSubtitle =>
      'Настройки добавления контактов';

  @override
  String get settings_privacyMode => 'Режим конфиденциальности';

  @override
  String get settings_privacyModeSubtitle =>
      'Скрыть имя/позицию в анонсировании';

  @override
  String get settings_privacyModeToggle =>
      'Включите режим конфиденциальности, чтобы скрыть свое имя и местоположение в анонсировании.';

  @override
  String get settings_privacyModeEnabled => 'Режим конфиденциальности включен';

  @override
  String get settings_privacyModeDisabled =>
      'Режим конфиденциальности выключен';

  @override
  String get settings_actions => 'Действия';

  @override
  String get settings_sendAdvertisement => 'Отправить анонсирование';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Отправить анонсирование о присутствии сейчас';

  @override
  String get settings_advertisementSent => 'Анонсирование отправлено';

  @override
  String get settings_syncTime => 'Синхронизация времени';

  @override
  String get settings_syncTimeSubtitle => 'Синхронизировать время с телефоном';

  @override
  String get settings_timeSynchronized => 'Время синхронизировано';

  @override
  String get settings_refreshContacts => 'Обновить контакты';

  @override
  String get settings_refreshContactsSubtitle =>
      'Перезагрузить список контактов с устройства';

  @override
  String get settings_rebootDevice => 'Перезагрузить устройство';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Перезапустить устройство MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Вы уверены, что хотите перезагрузить устройство? Вы будете отключены.';

  @override
  String get settings_debug => 'Отладка';

  @override
  String get settings_bleDebugLog => 'Журнал отладки BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Команды BLE, ответы и сырые данные';

  @override
  String get settings_appDebugLog => 'Журнал отладки приложения';

  @override
  String get settings_appDebugLogSubtitle => 'Сообщения отладки приложения';

  @override
  String get settings_about => 'О программе';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore Open Source Project';

  @override
  String get settings_aboutDescription =>
      'Открытое клиентское приложение на Flutter для устройств MeshCore с LoRa-сетями.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Данные о высоте LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Имя';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Статус';

  @override
  String get settings_infoBattery => 'Батарея';

  @override
  String get settings_infoPublicKey => 'Публичный ключ';

  @override
  String get settings_infoContactsCount => 'Количество контактов';

  @override
  String get settings_infoChannelCount => 'Количество каналов';

  @override
  String get settings_presets => 'Пресеты';

  @override
  String get settings_frequency => 'Частота (МГц)';

  @override
  String get settings_frequencyHelper => '300.0 – 2500.0';

  @override
  String get settings_frequencyInvalid => 'Недопустимая частота (300–2500 МГц)';

  @override
  String get settings_bandwidth => 'Полоса пропускания';

  @override
  String get settings_spreadingFactor => 'Коэффициент расширения';

  @override
  String get settings_codingRate => 'Коэффициент кодирования';

  @override
  String get settings_txPower => 'Мощность передачи (дБм)';

  @override
  String get settings_txPowerHelper => '0 – 22';

  @override
  String get settings_txPowerInvalid =>
      'Недопустимая мощность передачи (0–22 дБм)';

  @override
  String get settings_clientRepeat => 'Повторение \"вне сети\"';

  @override
  String get settings_clientRepeatSubtitle =>
      'Позвольте этому устройству повторять пакеты данных для других устройств.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Для работы в режиме \"без подключения к сети\" требуется частота 433, 869 или 918 МГц.';

  @override
  String settings_error(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get appSettings_title => 'Настройки приложения';

  @override
  String get appSettings_appearance => 'Внешний вид';

  @override
  String get appSettings_theme => 'Тема';

  @override
  String get appSettings_themeSystem => 'Как в системе';

  @override
  String get appSettings_themeLight => 'Светлая';

  @override
  String get appSettings_themeDark => 'Тёмная';

  @override
  String get appSettings_language => 'Язык';

  @override
  String get appSettings_languageSystem => 'Как в системе';

  @override
  String get appSettings_languageEn => 'Английский';

  @override
  String get appSettings_languageFr => 'Французский';

  @override
  String get appSettings_languageEs => 'Испанский';

  @override
  String get appSettings_languageDe => 'Немецкий';

  @override
  String get appSettings_languagePl => 'Польский';

  @override
  String get appSettings_languageSl => 'Словенский';

  @override
  String get appSettings_languagePt => 'Португальский';

  @override
  String get appSettings_languageIt => 'Итальянский';

  @override
  String get appSettings_languageZh => 'Китайский';

  @override
  String get appSettings_languageSv => 'Шведский';

  @override
  String get appSettings_languageNl => 'Нидерландский';

  @override
  String get appSettings_languageSk => 'Словацкий';

  @override
  String get appSettings_languageBg => 'Болгарский';

  @override
  String get appSettings_languageRu => 'Русский';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get appSettings_enableMessageTracing =>
      'Включить трассировку сообщений';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показывать подробные метаданные о маршрутизации и времени для сообщений';

  @override
  String get appSettings_notifications => 'Уведомления';

  @override
  String get appSettings_enableNotifications => 'Включить уведомления';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Получать уведомления о сообщениях и оповещениях';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Разрешение на уведомления отклонено';

  @override
  String get appSettings_notificationsEnabled => 'Уведомления включены';

  @override
  String get appSettings_notificationsDisabled => 'Уведомления отключены';

  @override
  String get appSettings_messageNotifications => 'Уведомления о сообщениях';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Показывать уведомление при получении новых сообщений';

  @override
  String get appSettings_channelMessageNotifications =>
      'Уведомления о сообщениях в каналах';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Показывать уведомление при получении сообщений в каналах';

  @override
  String get appSettings_advertisementNotifications =>
      'Уведомления об анонсированиях';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Показывать уведомление при обнаружении новых нод';

  @override
  String get appSettings_messaging => 'Обмен сообщениями';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Сбросить маршрут после максимального числа попыток';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Сбросить маршрут контакта после 5 неудачных попыток отправки';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Маршруты будут сброшены после 5 неудачных попыток';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Маршруты не будут автоматически сбрасываться';

  @override
  String get appSettings_autoRouteRotation =>
      'Автоматическое переключение маршрутов';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Циклически переключаться между лучшими маршрутами и режимом рассылки';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Автоматическое переключение маршрутов включено';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Автоматическое переключение маршрутов отключено';

  @override
  String get appSettings_battery => 'Батарея';

  @override
  String get appSettings_batteryChemistry => 'Химия батареи';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Установить для устройства ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Подключитесь к устройству, чтобы выбрать';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0–4.2 В)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6–3.65 В)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0–4.2 В)';

  @override
  String get appSettings_mapDisplay => 'Отображение карты';

  @override
  String get appSettings_showRepeaters => 'Показывать репитеры';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Отображать репитеры на карте';

  @override
  String get appSettings_showChatNodes => 'Показывать чат-ноды';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Отображать чат-ноды на карте';

  @override
  String get appSettings_showOtherNodes => 'Показывать другие ноды';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Отображать другие типы нод на карте';

  @override
  String get appSettings_timeFilter => 'Фильтр по времени';

  @override
  String get appSettings_timeFilterShowAll => 'Показывать все ноды';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Показывать ноды за последние $hours ч';
  }

  @override
  String get appSettings_mapTimeFilter => 'Временной фильтр карты';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Показывать ноды, обнаруженные за:';

  @override
  String get appSettings_allTime => 'Всё время';

  @override
  String get appSettings_lastHour => 'Последний час';

  @override
  String get appSettings_last6Hours => 'Последние 6 часов';

  @override
  String get appSettings_last24Hours => 'Последние 24 часа';

  @override
  String get appSettings_lastWeek => 'Последнюю неделю';

  @override
  String get appSettings_offlineMapCache => 'Кэш офлайн-карты';

  @override
  String get appSettings_unitsTitle => 'Единицы';

  @override
  String get appSettings_unitsMetric => 'Метрическая (м/км)';

  @override
  String get appSettings_unitsImperial => 'Имперская (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Область не выбрана';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Область выбрана (масштаб $minZoom–$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Отладка';

  @override
  String get appSettings_appDebugLogging => 'Журнал отладки приложения';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записывать отладочные сообщения приложения для диагностики';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Журнал отладки приложения включён';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Журнал отладки приложения отключён';

  @override
  String get contacts_title => 'Контакты';

  @override
  String get contacts_noContacts => 'Контактов пока нет';

  @override
  String get contacts_contactsWillAppear =>
      'Контакты появятся, когда устройства начнут рассылать оповещения';

  @override
  String get contacts_unread => 'Непрочитанное';

  @override
  String get contacts_searchContactsNoNumber => 'Поиск контактов...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Поиск контактов...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Поиск $number$str избранного...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Поиск $number$str пользователей...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Поиск $number$str ретрансляторов...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Поиск $number$str серверов комнат...';
  }

  @override
  String get contacts_noUnreadContacts => 'Нет непрочитанных контактов';

  @override
  String get contacts_noContactsFound => 'Контакты или группы не найдены';

  @override
  String get contacts_deleteContact => 'Удалить контакт';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Удалить $contactName из контактов?';
  }

  @override
  String get contacts_manageRepeater => 'Управление репитером';

  @override
  String get contacts_manageRoom => 'Управление сервером комнат';

  @override
  String get contacts_roomLogin => 'Вход на сервер комнат';

  @override
  String get contacts_openChat => 'Открыть чат';

  @override
  String get contacts_editGroup => 'Изменить группу';

  @override
  String get contacts_deleteGroup => 'Удалить группу';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Удалить \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Новая группа';

  @override
  String get contacts_groupName => 'Имя группы';

  @override
  String get contacts_groupNameRequired => 'Имя группы обязательно';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Группа \"$name\" уже существует';
  }

  @override
  String get contacts_filterContacts => 'Фильтр контактов...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Нет контактов, соответствующих фильтру';

  @override
  String get contacts_noMembers => 'Нет участников';

  @override
  String get contacts_lastSeenNow => 'Видели только что';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Видели $minutes мин назад';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Видели 1 час назад';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Видели $hours ч назад';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Видели 1 день назад';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Видели $days дн. назад';
  }

  @override
  String get channels_title => 'Каналы';

  @override
  String get channels_noChannelsConfigured => 'Каналы не настроены';

  @override
  String get channels_addPublicChannel => 'Добавить публичный канал';

  @override
  String get channels_searchChannels => 'Поиск каналов...';

  @override
  String get channels_noChannelsFound => 'Каналы не найдены';

  @override
  String channels_channelIndex(int index) {
    return 'Канал $index';
  }

  @override
  String get channels_hashtagChannel => 'Хэштег-канал';

  @override
  String get channels_public => 'Публичный';

  @override
  String get channels_private => 'Приватный';

  @override
  String get channels_publicChannel => 'Публичный канал';

  @override
  String get channels_privateChannel => 'Приватный канал';

  @override
  String get channels_editChannel => 'Изменить канал';

  @override
  String get channels_muteChannel => 'Отключить уведомления канала';

  @override
  String get channels_unmuteChannel => 'Включить уведомления канала';

  @override
  String get channels_deleteChannel => 'Удалить канал';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Удалить \"$name\"? Это действие нельзя отменить.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Не удалось удалить канал $name.';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Канал \"$name\" удалён';
  }

  @override
  String get channels_addChannel => 'Добавить канал';

  @override
  String get channels_channelIndexLabel => 'Индекс канала';

  @override
  String get channels_channelName => 'Имя канала';

  @override
  String get channels_usePublicChannel => 'Использовать публичный канал';

  @override
  String get channels_standardPublicPsk => 'Стандартный публичный PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Сгенерировать случайный PSK';

  @override
  String get channels_enterChannelName => 'Введите имя канала';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK должен содержать 32 шестнадцатеричных символа';

  @override
  String channels_channelAdded(String name) {
    return 'Канал \"$name\" добавлен';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Изменить канал $index';
  }

  @override
  String get channels_smazCompression => 'Сжатие SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Канал \"$name\" обновлён';
  }

  @override
  String get channels_publicChannelAdded => 'Публичный канал добавлен';

  @override
  String get channels_sortBy => 'Сортировка';

  @override
  String get channels_sortManual => 'Вручную';

  @override
  String get channels_sortAZ => 'По алфавиту';

  @override
  String get channels_sortLatestMessages => 'По последним сообщениям';

  @override
  String get channels_sortUnread => 'По непрочитанным';

  @override
  String get channels_createPrivateChannel => 'Создать приватный канал';

  @override
  String get channels_createPrivateChannelDesc => 'Защищён секретным ключом.';

  @override
  String get channels_joinPrivateChannel =>
      'Присоединиться к приватному каналу';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Введите секретный ключ вручную.';

  @override
  String get channels_joinPublicChannel => 'Присоединиться к публичному каналу';

  @override
  String get channels_joinPublicChannelDesc =>
      'К этому каналу может присоединиться любой.';

  @override
  String get channels_joinHashtagChannel => 'Присоединиться к хэштег-каналу';

  @override
  String get channels_joinHashtagChannelDesc =>
      'К хэштег-каналам может присоединиться любой.';

  @override
  String get channels_scanQrCode => 'Сканировать QR-код';

  @override
  String get channels_scanQrCodeComingSoon => 'Скоро будет';

  @override
  String get channels_enterHashtag => 'Введите хэштег';

  @override
  String get channels_hashtagHint => 'например, #команда';

  @override
  String get chat_noMessages => 'Сообщений пока нет';

  @override
  String get chat_sendMessageToStart => 'Отправьте сообщение, чтобы начать';

  @override
  String get chat_originalMessageNotFound => 'Исходное сообщение не найдено';

  @override
  String chat_replyingTo(String name) {
    return 'Ответ для $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Ответить $name';
  }

  @override
  String get chat_location => 'Местоположение';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Отправить сообщение $contactName';
  }

  @override
  String get chat_typeMessage => 'Напишите сообщение...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Сообщение слишком длинное (макс. $maxBytes байт).';
  }

  @override
  String get chat_messageCopied => 'Сообщение скопировано';

  @override
  String get chat_messageDeleted => 'Сообщение удалено';

  @override
  String get chat_retryingMessage => 'Повтор отправки сообщения';

  @override
  String chat_retryCount(int current, int max) {
    return 'Попытка $current/$max';
  }

  @override
  String get chat_sendGif => 'Отправить GIF';

  @override
  String get chat_reply => 'Ответить';

  @override
  String get chat_addReaction => 'Добавить реакцию';

  @override
  String get chat_me => 'Я';

  @override
  String get emojiCategorySmileys => 'Смайлы';

  @override
  String get emojiCategoryGestures => 'Жесты';

  @override
  String get emojiCategoryHearts => 'Сердечки';

  @override
  String get emojiCategoryObjects => 'Предметы';

  @override
  String get gifPicker_title => 'Выберите GIF';

  @override
  String get gifPicker_searchHint => 'Поиск GIF...';

  @override
  String get gifPicker_poweredBy => 'Работает на GIPHY';

  @override
  String get gifPicker_noGifsFound => 'GIF не найдены';

  @override
  String get gifPicker_failedLoad => 'Не удалось загрузить GIF';

  @override
  String get gifPicker_failedSearch => 'Не удалось выполнить поиск GIF';

  @override
  String get gifPicker_noInternet => 'Нет подключения к интернету';

  @override
  String get debugLog_appTitle => 'Журнал отладки приложения';

  @override
  String get debugLog_bleTitle => 'Журнал отладки BLE';

  @override
  String get debugLog_copyLog => 'Копировать журнал';

  @override
  String get debugLog_clearLog => 'Очистить журнал';

  @override
  String get debugLog_copied => 'Журнал отладки скопирован';

  @override
  String get debugLog_bleCopied => 'Журнал BLE скопирован';

  @override
  String get debugLog_noEntries => 'Журнал отладки пока пуст';

  @override
  String get debugLog_enableInSettings =>
      'Включите запись журнала отладки в настройках';

  @override
  String get debugLog_frames => 'Фреймы';

  @override
  String get debugLog_rawLogRx => 'Сырой журнал приёма';

  @override
  String get debugLog_noBleActivity => 'Активность BLE пока отсутствует';

  @override
  String debugFrame_length(int count) {
    return 'Длина фрейма: $count байт';
  }

  @override
  String debugFrame_command(String value) {
    return 'Команда: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Фрейм текстового сообщения:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Публичный ключ получателя: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Временная метка: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Флаги: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Тип текста: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Обычный';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Шестнадцатеричный дамп:';

  @override
  String get chat_pathManagement => 'Управление маршрутами';

  @override
  String get chat_ShowAllPaths => 'Показать все пути';

  @override
  String get chat_routingMode => 'Режим маршрутизации';

  @override
  String get chat_autoUseSavedPath => 'Авто (использовать сохранённый маршрут)';

  @override
  String get chat_forceFloodMode => 'Принудительный режим рассылки';

  @override
  String get chat_recentAckPaths =>
      'Недавние подтверждённые маршруты (нажмите, чтобы использовать):';

  @override
  String get chat_pathHistoryFull =>
      'История маршрутов заполнена. Удалите записи, чтобы добавить новые.';

  @override
  String get chat_hopSingular => 'хоп';

  @override
  String get chat_hopPlural => 'хопов';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'хопов',
      many: 'хопов',
      few: 'хопа',
      one: 'хоп',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_successes => 'успешно';

  @override
  String get chat_removePath => 'Удалить маршрут';

  @override
  String get chat_noPathHistoryYet =>
      'История маршрутов пока пуста.\nОтправьте сообщение, чтобы обнаружить маршруты.';

  @override
  String get chat_pathActions => 'Действия с маршрутом:';

  @override
  String get chat_setCustomPath => 'Указать маршрут вручную';

  @override
  String get chat_setCustomPathSubtitle => 'Вручную задать маршрут передачи';

  @override
  String get chat_clearPath => 'Очистить маршрут';

  @override
  String get chat_clearPathSubtitle =>
      'Принудительно обновить маршрут при следующей отправке';

  @override
  String get chat_pathCleared =>
      'Маршрут очищен. Следующее сообщение обновит маршрут.';

  @override
  String get chat_floodModeSubtitle =>
      'Используйте переключатель маршрутизации в панели приложения';

  @override
  String get chat_floodModeEnabled =>
      'Режим рассылки включён. Отключите через значок маршрутизации в панели приложения.';

  @override
  String get chat_fullPath => 'Полный маршрут';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Детали маршрута ещё недоступны. Попробуйте отправить сообщение для обновления.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'хопов',
      many: 'хопов',
      few: 'хопа',
      one: 'хоп',
    );
    return 'Маршрут установлен: $hopCount $_temp0 — $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Сохранено локально. Подключитесь для синхронизации.';

  @override
  String get chat_pathDeviceConfirmed => 'Подтверждено устройством.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Ещё не подтверждено устройством.';

  @override
  String get chat_type => 'Тип';

  @override
  String get chat_path => 'Маршрут';

  @override
  String get chat_publicKey => 'Публичный ключ';

  @override
  String get chat_compressOutgoingMessages => 'Сжимать исходящие сообщения';

  @override
  String get chat_floodForced => 'Рассылка (принудительно)';

  @override
  String get chat_directForced => 'Прямой (принудительно)';

  @override
  String chat_hopsForced(int count) {
    return '$count хоп(ов) (принудительно)';
  }

  @override
  String get chat_floodAuto => 'Рассылка (авто)';

  @override
  String get chat_direct => 'Прямой';

  @override
  String get chat_poiShared => 'Точка интереса отправлена';

  @override
  String chat_unread(int count) {
    return 'Непрочитанных: $count';
  }

  @override
  String get chat_openLink => 'Открыть ссылку?';

  @override
  String get chat_openLinkConfirmation =>
      'Хотите открыть эту ссылку в вашем браузере?';

  @override
  String get chat_open => 'Открыть';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Не удалось открыть ссылку: $url';
  }

  @override
  String get chat_invalidLink => 'Неправильный формат ссылки';

  @override
  String get map_title => 'Карта нод';

  @override
  String get map_lineOfSight => 'Линия видимости';

  @override
  String get map_losScreenTitle => 'Линия видимости';

  @override
  String get map_noNodesWithLocation => 'Нет нод с данными о местоположении';

  @override
  String get map_nodesNeedGps =>
      'Ноды должны передавать свои GPS-координаты, чтобы отображаться на карте';

  @override
  String map_nodesCount(int count) {
    return 'Нод: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Меток: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Репитер';

  @override
  String get map_room => 'Комната';

  @override
  String get map_sensor => 'Сенсор';

  @override
  String get map_pinDm => 'Метка (ЛС)';

  @override
  String get map_pinPrivate => 'Метка (Приватная)';

  @override
  String get map_pinPublic => 'Метка (Публичная)';

  @override
  String get map_lastSeen => 'Последнее появление';

  @override
  String get map_disconnectConfirm =>
      'Вы уверены, что хотите отключиться от этого устройства?';

  @override
  String get map_from => 'От';

  @override
  String get map_source => 'Источник';

  @override
  String get map_flags => 'Флаги';

  @override
  String get map_shareMarkerHere => 'Поделиться меткой здесь';

  @override
  String get map_pinLabel => 'Метка';

  @override
  String get map_label => 'Подпись';

  @override
  String get map_pointOfInterest => 'Точка интереса';

  @override
  String get map_sendToContact => 'Отправить контакту';

  @override
  String get map_sendToChannel => 'Отправить в канал';

  @override
  String get map_noChannelsAvailable => 'Нет доступных каналов';

  @override
  String get map_publicLocationShare => 'Публичная передача местоположения';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Вы собираетесь поделиться местоположением в $channelLabel. Этот канал публичный, и любой, у кого есть PSK, сможет его увидеть.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Подключитесь к устройству, чтобы делиться метками';

  @override
  String get map_filterNodes => 'Фильтр нод';

  @override
  String get map_nodeTypes => 'Типы нод';

  @override
  String get map_chatNodes => 'Чат-ноды';

  @override
  String get map_repeaters => 'Репитеры';

  @override
  String get map_otherNodes => 'Другие ноды';

  @override
  String get map_keyPrefix => 'Префикс ключа';

  @override
  String get map_filterByKeyPrefix => 'Фильтр по префиксу ключа';

  @override
  String get map_publicKeyPrefix => 'Префикс публичного ключа';

  @override
  String get map_markers => 'Метки';

  @override
  String get map_showSharedMarkers => 'Показывать общие метки';

  @override
  String get map_showGuessedLocations =>
      'Отобразить предполагаемые места расположения узлов';

  @override
  String get map_showDiscoveryContacts => 'Показать контакты Discovery';

  @override
  String get map_guessedLocation => 'Угаданное место';

  @override
  String get map_lastSeenTime => 'Время последнего появления';

  @override
  String get map_sharedPin => 'Общая метка';

  @override
  String get map_joinRoom => 'Присоединиться к комнате';

  @override
  String get map_manageRepeater => 'Управление репитером';

  @override
  String get map_tapToAdd => 'Нажимайте на узлы, чтобы добавить их в путь.';

  @override
  String get map_runTrace => 'Запустить трассировку пути';

  @override
  String get map_removeLast => 'Удалить последний';

  @override
  String get map_pathTraceCancelled => 'Отмена трассировки пути';

  @override
  String get mapCache_title => 'Кэш офлайн-карты';

  @override
  String get mapCache_selectAreaFirst =>
      'Сначала выберите область для кэширования';

  @override
  String get mapCache_noTilesToDownload =>
      'Нет плиток для загрузки в этой области';

  @override
  String get mapCache_downloadTilesTitle => 'Загрузить плитки';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Загрузить $count плиток для офлайн-использования?';
  }

  @override
  String get mapCache_downloadAction => 'Загрузить';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Закэшировано $count плиток';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Закэшировано $downloaded плиток ($failed не загружено)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Очистить офлайн-кэш';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Удалить все закэшированные плитки карты?';

  @override
  String get mapCache_offlineCacheCleared => 'Офлайн-кэш очищен';

  @override
  String get mapCache_noAreaSelected => 'Область не выбрана';

  @override
  String get mapCache_cacheArea => 'Область кэширования';

  @override
  String get mapCache_useCurrentView => 'Использовать текущий вид';

  @override
  String get mapCache_zoomRange => 'Диапазон масштаба';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Оценочное количество плиток: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Загружено $completed из $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Загрузить плитки';

  @override
  String get mapCache_clearCacheButton => 'Очистить кэш';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Неудачных загрузок: $count';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'С $north, Ю $south, В $east, З $west';
  }

  @override
  String get time_justNow => 'Только что';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String time_daysAgo(int days) {
    return '$days дн. назад';
  }

  @override
  String get time_hour => 'час';

  @override
  String get time_hours => 'часов';

  @override
  String get time_day => 'день';

  @override
  String get time_days => 'дней';

  @override
  String get time_week => 'неделя';

  @override
  String get time_weeks => 'недель';

  @override
  String get time_month => 'месяц';

  @override
  String get time_months => 'месяцев';

  @override
  String get time_minutes => 'минут';

  @override
  String get time_allTime => 'Всё время';

  @override
  String get dialog_disconnect => 'Отключиться';

  @override
  String get dialog_disconnectConfirm =>
      'Вы уверены, что хотите отключиться от этого устройства?';

  @override
  String get login_repeaterLogin => 'Вход в репитер';

  @override
  String get login_roomLogin => 'Вход на сервер комнат';

  @override
  String get login_password => 'Пароль';

  @override
  String get login_enterPassword => 'Введите пароль';

  @override
  String get login_savePassword => 'Сохранить пароль';

  @override
  String get login_savePasswordSubtitle =>
      'Пароль будет надёжно сохранён на этом устройстве';

  @override
  String get login_repeaterDescription =>
      'Введите пароль репитера для доступа к настройкам и статусу.';

  @override
  String get login_roomDescription =>
      'Введите пароль комнаты для доступа к настройкам и статусу.';

  @override
  String get login_routing => 'Маршрутизация';

  @override
  String get login_routingMode => 'Режим маршрутизации';

  @override
  String get login_autoUseSavedPath =>
      'Авто (использовать сохранённый маршрут)';

  @override
  String get login_forceFloodMode => 'Принудительный режим рассылки';

  @override
  String get login_managePaths => 'Управление маршрутами';

  @override
  String get login_login => 'Войти';

  @override
  String login_attempt(int current, int max) {
    return 'Попытка $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get login_failedMessage =>
      'Не удалось войти. Либо пароль неверен, либо репитер недоступен.';

  @override
  String get common_reload => 'Обновить';

  @override
  String get common_clear => 'Очистить';

  @override
  String path_currentPath(String path) {
    return 'Текущий маршрут: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'хопов',
      many: 'хопов',
      few: 'хопа',
      one: 'хоп',
    );
    return 'Используется маршрут из $count $_temp0';
  }

  @override
  String get path_enterCustomPath => 'Введите маршрут вручную';

  @override
  String get path_currentPathLabel => 'Текущий маршрут';

  @override
  String get path_hexPrefixInstructions =>
      'Введите 2-символьные шестнадцатеричные префиксы для каждого хопа, разделённые запятыми.';

  @override
  String get path_hexPrefixExample =>
      'Пример: A1,F2,3C (каждый узел использует первый байт своего публичного ключа)';

  @override
  String get path_labelHexPrefixes => 'Маршрут (шестнадцатеричные префиксы)';

  @override
  String get path_helperMaxHops =>
      'Максимум 64 хопа. Каждый префикс — 2 шестнадцатеричных символа (1 байт)';

  @override
  String get path_selectFromContacts => 'Или выберите из контактов:';

  @override
  String get path_noRepeatersFound => 'Репитеры или серверы комнат не найдены.';

  @override
  String get path_customPathsRequire =>
      'Пользовательские маршруты требуют промежуточных узлов, способных ретранслировать сообщения.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Недопустимые шестнадцатеричные префиксы: $prefixes';
  }

  @override
  String get path_tooLong => 'Маршрут слишком длинный. Максимум 64 хопа.';

  @override
  String get path_setPath => 'Установить маршрут';

  @override
  String get repeater_management => 'Управление репитером';

  @override
  String get room_management => 'Управление сервером комнат';

  @override
  String get repeater_managementTools => 'Инструменты управления';

  @override
  String get repeater_status => 'Статус';

  @override
  String get repeater_statusSubtitle =>
      'Просмотр статуса, статистики и соседей репитера';

  @override
  String get repeater_telemetry => 'Телеметрия';

  @override
  String get repeater_telemetrySubtitle =>
      'Просмотр телеметрии датчиков и системной статистики';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Отправка команд репитеру';

  @override
  String get repeater_neighbors => 'Соседи';

  @override
  String get repeater_neighborsSubtitle => 'Просмотр соседей на нулевом хопе.';

  @override
  String get repeater_settings => 'Настройки';

  @override
  String get repeater_settingsSubtitle => 'Настройка параметров репитера';

  @override
  String get repeater_statusTitle => 'Статус репитера';

  @override
  String get repeater_routingMode => 'Режим маршрутизации';

  @override
  String get repeater_autoUseSavedPath =>
      'Авто (использовать сохранённый маршрут)';

  @override
  String get repeater_forceFloodMode => 'Принудительный режим рассылки';

  @override
  String get repeater_pathManagement => 'Управление маршрутами';

  @override
  String get repeater_refresh => 'Обновить';

  @override
  String get repeater_statusRequestTimeout => 'Время ожидания статуса истекло.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Ошибка загрузки статуса: $error';
  }

  @override
  String get repeater_systemInformation => 'Системная информация';

  @override
  String get repeater_battery => 'Батарея';

  @override
  String get repeater_clockAtLogin => 'Время (при входе)';

  @override
  String get repeater_uptime => 'Время работы';

  @override
  String get repeater_queueLength => 'Длина очереди';

  @override
  String get repeater_debugFlags => 'Флаги отладки';

  @override
  String get repeater_radioStatistics => 'Радиостатистика';

  @override
  String get repeater_lastRssi => 'Последний RSSI';

  @override
  String get repeater_lastSnr => 'Последний SNR';

  @override
  String get repeater_noiseFloor => 'Уровень шума';

  @override
  String get repeater_txAirtime => 'Время эфира (передача)';

  @override
  String get repeater_rxAirtime => 'Время эфира (приём)';

  @override
  String get repeater_packetStatistics => 'Статистика пакетов';

  @override
  String get repeater_sent => 'Отправлено';

  @override
  String get repeater_received => 'Получено';

  @override
  String get repeater_duplicates => 'Дубликаты';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days дн. $hoursч $minutesм $secondsс';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Всего: $total, Рассылка: $flood, Прямые: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Всего: $total, Рассылка: $flood, Прямые: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Рассылка: $flood, Прямые: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Всего: $total';
  }

  @override
  String get repeater_settingsTitle => 'Настройки репитера';

  @override
  String get repeater_basicSettings => 'Основные настройки';

  @override
  String get repeater_repeaterName => 'Имя репитера';

  @override
  String get repeater_repeaterNameHelper => 'Отображаемое имя этого репитера';

  @override
  String get repeater_adminPassword => 'Пароль администратора';

  @override
  String get repeater_adminPasswordHelper => 'Пароль с полным доступом';

  @override
  String get repeater_guestPassword => 'Гостевой пароль';

  @override
  String get repeater_guestPasswordHelper =>
      'Пароль для доступа только для чтения';

  @override
  String get repeater_radioSettings => 'Настройки радио';

  @override
  String get repeater_frequencyMhz => 'Частота (МГц)';

  @override
  String get repeater_frequencyHelper => '300–2500 МГц';

  @override
  String get repeater_txPower => 'Мощность передачи';

  @override
  String get repeater_txPowerHelper => '1–30 дБм';

  @override
  String get repeater_bandwidth => 'Полоса пропускания';

  @override
  String get repeater_spreadingFactor => 'Коэффициент расширения';

  @override
  String get repeater_codingRate => 'Коэффициент кодирования';

  @override
  String get repeater_locationSettings => 'Настройки местоположения';

  @override
  String get repeater_latitude => 'Широта';

  @override
  String get repeater_latitudeHelper =>
      'В десятичных градусах (напр., 37.7749)';

  @override
  String get repeater_longitude => 'Долгота';

  @override
  String get repeater_longitudeHelper =>
      'В десятичных градусах (напр., -122.4194)';

  @override
  String get repeater_features => 'Функции';

  @override
  String get repeater_packetForwarding => 'Пересылка пакетов';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Разрешить репитеру пересылать пакеты';

  @override
  String get repeater_guestAccess => 'Гостевой доступ';

  @override
  String get repeater_guestAccessSubtitle =>
      'Разрешить гостевой доступ только для чтения';

  @override
  String get repeater_privacyMode => 'Режим конфиденциальности';

  @override
  String get repeater_privacyModeSubtitle =>
      'Скрывать имя/местоположение в оповещениях';

  @override
  String get repeater_advertisementSettings => 'Настройки анонсирования';

  @override
  String get repeater_localAdvertInterval => 'Интервал локальных анонсирований';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes минут';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Интервал анонсирований рассылкой (flood)';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours часов';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Интервал зашифрованных анонсирований';

  @override
  String get repeater_dangerZone => 'Опасная зона';

  @override
  String get repeater_rebootRepeater => 'Перезагрузить репитер';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Перезапустить устройство репитера';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Вы уверены, что хотите перезагрузить этот репитер?';

  @override
  String get repeater_regenerateIdentityKey => 'Пересоздать ключ идентификации';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Сгенерировать новую пару публичного/приватного ключей';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Это создаст новую идентичность для репитера. Продолжить?';

  @override
  String get repeater_eraseFileSystem => 'Стереть файловую систему';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Отформатировать файловую систему репитера';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ВНИМАНИЕ: это удалит все данные на репитере. Действие нельзя отменить!';

  @override
  String get repeater_eraseSerialOnly =>
      'Очистка доступна только через последовательную консоль.';

  @override
  String repeater_commandSent(String command) {
    return 'Команда отправлена: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Ошибка отправки команды: $error';
  }

  @override
  String get repeater_confirm => 'Подтвердить';

  @override
  String get repeater_settingsSaved => 'Настройки успешно сохранены';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Ошибка сохранения настроек: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Обновить основные настройки';

  @override
  String get repeater_refreshRadioSettings => 'Обновить настройки радио';

  @override
  String get repeater_refreshTxPower => 'Обновить мощность передачи';

  @override
  String get repeater_refreshLocationSettings =>
      'Обновить настройки местоположения';

  @override
  String get repeater_refreshPacketForwarding => 'Обновить пересылку пакетов';

  @override
  String get repeater_refreshGuestAccess => 'Обновить гостевой доступ';

  @override
  String get repeater_refreshPrivacyMode => 'Обновить режим конфиденциальности';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Обновить настройки анонсирований';

  @override
  String repeater_refreshed(String label) {
    return '$label обновлён';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Ошибка обновления $label';
  }

  @override
  String get repeater_cliTitle => 'CLI репитера';

  @override
  String get repeater_debugNextCommand => 'Отладка следующей команды';

  @override
  String get repeater_commandHelp => 'Справка по командам';

  @override
  String get repeater_clearHistory => 'Очистить историю';

  @override
  String get repeater_noCommandsSent => 'Команды ещё не отправлялись';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Введите команду ниже или используйте быстрые команды';

  @override
  String get repeater_enterCommandHint => 'Введите команду...';

  @override
  String get repeater_previousCommand => 'Предыдущая команда';

  @override
  String get repeater_nextCommand => 'Следующая команда';

  @override
  String get repeater_enterCommandFirst => 'Сначала введите команду';

  @override
  String get repeater_cliCommandFrameTitle => 'Фрейм CLI-команды';

  @override
  String repeater_cliCommandError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Получить имя';

  @override
  String get repeater_cliQuickGetRadio => 'Получить радио';

  @override
  String get repeater_cliQuickGetTx => 'Получить TX';

  @override
  String get repeater_cliQuickNeighbors => 'Соседи';

  @override
  String get repeater_cliQuickVersion => 'Версия';

  @override
  String get repeater_cliQuickAdvertise => 'Анонсировать';

  @override
  String get repeater_cliQuickClock => 'Время';

  @override
  String get repeater_cliHelpAdvert => 'Отправляет пакет анонсирования';

  @override
  String get repeater_cliHelpReboot =>
      'Перезагружает устройство. (обычно вы получите «Тайм-аут» — это нормально)';

  @override
  String get repeater_cliHelpClock =>
      'Показывает текущее время по часам устройства.';

  @override
  String get repeater_cliHelpPassword =>
      'Устанавливает новый пароль администратора для устройства.';

  @override
  String get repeater_cliHelpVersion =>
      'Показывает версию устройства и дату сборки прошивки.';

  @override
  String get repeater_cliHelpClearStats =>
      'Сбрасывает различные счётчики статистики в ноль.';

  @override
  String get repeater_cliHelpSetAf =>
      'Устанавливает коэффициент времени в эфире.';

  @override
  String get repeater_cliHelpSetTx =>
      'Устанавливает мощность передачи LoRa в дБм. (требуется перезагрузка)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Включает или отключает роль репитера для этой ноды.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Сервер комнат) Если «on», то вход без пароля разрешён, но публиковать в комнату нельзя (только чтение)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Устанавливает максимальное число хопов для входящих пакетов в режиме рассылки (если >= макс., пакет не пересылается)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Устанавливает порог интерференции (в дБ). По умолчанию 14. Установите 0, чтобы отключить обнаружение помех.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Устанавливает интервал сброса автоматической регулировки усиления. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Включает или отключает функцию «двойных ACK».';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Устанавливает интервал (в минутах) отправки локального (нулевой хоп) анонсирования. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Устанавливает интервал (в часах) отправки анонсирований рассылкой. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Устанавливает/обновляет гостевой пароль. (для репитеров гости могут отправлять запрос «Get Stats»)';

  @override
  String get repeater_cliHelpSetName => 'Устанавливает имя в оповещениях.';

  @override
  String get repeater_cliHelpSetLat =>
      'Устанавливает широту для карты в оповещениях. (десятичные градусы)';

  @override
  String get repeater_cliHelpSetLon =>
      'Устанавливает долготу для карты в оповещениях. (десятичные градусы)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Устанавливает полностью новые параметры радио и сохраняет их в настройки. Требуется команда «reboot» для применения.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Устанавливает (экспериментально) базовую задержку (>1 для эффекта) для принятых пакетов на основе качества сигнала. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Устанавливает множитель времени в эфире для пакета в режиме рассылки и применяет случайную задержку перед пересылкой (чтобы уменьшить коллизии).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'То же, что txdelay, но для случайной задержки пересылки пакетов в прямом режиме.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Включить/выключить мост.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Установить задержку перед ретрансляцией пакетов.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Выбрать, будет ли мост ретранслировать полученные или отправленные пакеты.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Установить скорость последовательного соединения для мостов RS232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Установить секрет моста для мостов ESP-NOW.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Устанавливает пользовательский коэффициент коррекции напряжения батареи (поддерживается только на некоторых платах).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Устанавливает временные параметры радио на заданное число минут, затем возвращает исходные. (НЕ сохраняется в настройки).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Изменяет ACL. Удаляет запись (по префиксу публичного ключа), если «permissions» равен нулю. Добавляет новую запись, если указан полный ключ и он отсутствует в ACL. Обновляет запись по совпадению префикса. Биты прав зависят от роли прошивки, но младшие 2 бита: 0 (Гость), 1 (Только чтение), 2 (Чтение/запись), 3 (Админ)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Получает тип моста: none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Начинает запись пакетов в файловую систему.';

  @override
  String get repeater_cliHelpLogStop =>
      'Останавливает запись пакетов в файловую систему.';

  @override
  String get repeater_cliHelpLogErase =>
      'Удаляет журналы пакетов из файловой системы.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Показывает список других репитеров, услышанных через оповещения нулевого хопа. Каждая строка: префикс-id-в-hex:временная-метка:snr×4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Удаляет первую подходящую запись (по префиксу публичного ключа в hex) из списка соседей.';

  @override
  String get repeater_cliHelpRegion =>
      '(только через последовательный порт) Показывает все определённые регионы и текущие права на рассылку.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'ПРИМЕЧАНИЕ: это специальная многострочная команда. Каждая следующая строка — имя региона (с отступом пробелами для указания иерархии, минимум один пробел). Завершается пустой строкой.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Ищет регион по префиксу имени (или «*» для глобальной области). Отвечает: «-> имя-региона (родитель) \'F\'»';

  @override
  String get repeater_cliHelpRegionPut =>
      'Добавляет или обновляет определение региона с заданным именем.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Удаляет определение региона с заданным именем. (должно точно совпадать и не иметь дочерних регионов)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Разрешает рассылку («F»lood) для заданного региона. («*» для глобальной/устаревшей области)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Запрещает рассылку («F»lood) для заданного региона. (НЕ рекомендуется для глобальной области!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Показывает текущий «домашний» регион. (Пока не используется, зарезервировано на будущее)';

  @override
  String get repeater_cliHelpRegionHomeSet =>
      'Устанавливает «домашний» регион.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Сохраняет список/карту регионов в память.';

  @override
  String get repeater_cliHelpGps =>
      'Показывает статус GPS. Если GPS выключен — отвечает только «off». Если включён — показывает статус, фиксацию, количество спутников.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Переключает состояние питания GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Синхронизирует время ноды с часами GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Устанавливает позицию ноды по координатам GPS и сохраняет в настройки.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Показывает конфигурацию передачи местоположения в анонсированиях:\n- none: не включать местоположение\n- share: передавать GPS-координаты (из SensorManager)\n- prefs: передавать координаты из настроек';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Устанавливает конфигурацию передачи местоположения.';

  @override
  String get repeater_commandsListTitle => 'Список команд';

  @override
  String get repeater_commandsListNote =>
      'ПРИМЕЧАНИЕ: для большинства команд «set ...» существуют соответствующие команды «get ...».';

  @override
  String get repeater_general => 'Общие';

  @override
  String get repeater_settingsCategory => 'Настройки';

  @override
  String get repeater_bridge => 'Мост';

  @override
  String get repeater_logging => 'Журналирование';

  @override
  String get repeater_neighborsRepeaterOnly => 'Соседи (только для репитеров)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Управление регионами (только для репитеров)';

  @override
  String get repeater_regionNote =>
      'Команды регионов введены для управления определениями регионов и правами доступа.';

  @override
  String get repeater_gpsManagement => 'Управление GPS';

  @override
  String get repeater_gpsNote =>
      'Команда gps введена для управления параметрами, связанными с местоположением.';

  @override
  String get telemetry_receivedData => 'Полученные телеметрические данные';

  @override
  String get telemetry_requestTimeout => 'Время ожидания телеметрии истекло.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Ошибка загрузки телеметрии: $error';
  }

  @override
  String get telemetry_noData => 'Данные телеметрии недоступны.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Канал $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Батарея';

  @override
  String get telemetry_voltageLabel => 'Напряжение';

  @override
  String get telemetry_mcuTemperatureLabel => 'Температура МК';

  @override
  String get telemetry_temperatureLabel => 'Температура';

  @override
  String get telemetry_currentLabel => 'Ток';

  @override
  String telemetry_batteryValue(int percent, String volts) {
    return '$percent% / $voltsВ';
  }

  @override
  String telemetry_voltageValue(String volts) {
    return '$voltsВ';
  }

  @override
  String telemetry_currentValue(String amps) {
    return '$ampsА';
  }

  @override
  String telemetry_temperatureValue(String celsius, String fahrenheit) {
    return '$celsius°C / $fahrenheit°F';
  }

  @override
  String get neighbors_receivedData => 'Полученные данные о соседях';

  @override
  String get neighbors_requestTimedOut =>
      'Время ожидания данных о соседях истекло.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Ошибка загрузки соседей: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Соседи репитеров';

  @override
  String get neighbors_noData => 'Данные о соседях недоступны.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Неизвестный $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Слушал(а): $time назад';
  }

  @override
  String get channelPath_title => 'Путь пакета';

  @override
  String get channelPath_viewMap => 'Посмотреть на карте';

  @override
  String get channelPath_otherObservedPaths => 'Другие наблюдаемые пути';

  @override
  String get channelPath_repeaterHops => 'Хопы через репитеры';

  @override
  String get channelPath_noHopDetails =>
      'Детали хопов для этого пакета не предоставлены.';

  @override
  String get channelPath_messageDetails => 'Детали сообщения';

  @override
  String get channelPath_senderLabel => 'Отправитель';

  @override
  String get channelPath_timeLabel => 'Время';

  @override
  String get channelPath_repeatsLabel => 'Повторы';

  @override
  String channelPath_pathLabel(int index) {
    return 'Путь $index';
  }

  @override
  String get channelPath_observedLabel => 'Наблюдаемый';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Наблюдаемый путь $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Нет данных о местоположении';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Неизвестный';

  @override
  String get channelPath_floodPath => 'Рассылка';

  @override
  String get channelPath_directPath => 'Прямой';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 из $total хопов';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed из $total хопов';
  }

  @override
  String get channelPath_mapTitle => 'Карта пути';

  @override
  String get channelPath_noRepeaterLocations =>
      'Нет данных о местоположении репитеров для этого пути.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Путь $index (Основной)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Путь';

  @override
  String get channelPath_observedPathHeader => 'Наблюдаемый путь';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Детали хопов для этого пакета недоступны.';

  @override
  String get channelPath_unknownRepeater => 'Неизвестный репитер';

  @override
  String get community_title => 'Сообщество';

  @override
  String get community_create => 'Создать сообщество';

  @override
  String get community_createDesc =>
      'Создать новое сообщество и поделиться через QR-код.';

  @override
  String get community_join => 'Присоединиться';

  @override
  String get community_joinTitle => 'Присоединиться к сообществу';

  @override
  String community_joinConfirmation(String name) {
    return 'Вы хотите присоединиться к сообществу  \"$name\"?';
  }

  @override
  String get community_scanQr => 'Сканировать QR-код сообщества';

  @override
  String get community_scanInstructions =>
      'Наведите камеру на QR-код сообщества';

  @override
  String get community_showQr => 'Показать QR-код';

  @override
  String get community_publicChannel => 'Публичный канал сообщества';

  @override
  String get community_hashtagChannel => 'Хэштег-канал сообщества';

  @override
  String get community_name => 'Имя сообщества';

  @override
  String get community_enterName => 'Введите имя сообщества';

  @override
  String community_created(String name) {
    return 'Сообщество \"$name\" создано';
  }

  @override
  String community_joined(String name) {
    return 'Присоединились к сообществу \"$name\"';
  }

  @override
  String get community_qrTitle => 'Поделиться сообществом';

  @override
  String community_qrInstructions(String name) {
    return 'Отсканируйте этот QR-код, чтобы присоединиться к \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Хэштег-каналы сообщества доступны только его участникам';

  @override
  String get community_invalidQrCode => 'Недопустимый QR-код сообщества';

  @override
  String get community_alreadyMember => 'Уже участник';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Вы уже участник сообщества \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Добавить публичный канал сообщества';

  @override
  String get community_addPublicChannelHint =>
      'Автоматически добавить публичный канал для этого сообщества';

  @override
  String get community_noCommunities =>
      'Вы ещё не присоединились ни к одному сообществу';

  @override
  String get community_scanOrCreate =>
      'Отсканируйте QR-код или создайте сообщество, чтобы начать';

  @override
  String get community_manageCommunities => 'Управление сообществами';

  @override
  String get community_delete => 'Покинуть сообщество';

  @override
  String community_deleteConfirm(String name) {
    return 'Покинуть \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Это также удалит $count канал(ов) и их сообщения.';
  }

  @override
  String community_deleted(String name) {
    return 'Покинули сообщество \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Пересоздать секрет';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Пересоздать секретный ключ для \"$name\"? Все участники должны будут отсканировать новый QR-код для продолжения общения.';
  }

  @override
  String get community_regenerate => 'Пересоздать';

  @override
  String community_secretRegenerated(String name) {
    return 'Секрет пересоздан для \"$name\"';
  }

  @override
  String get community_updateSecret => 'Обновить секрет';

  @override
  String community_secretUpdated(String name) {
    return 'Секрет обновлён для \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Отсканируйте новый QR-код, чтобы обновить секрет для \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Добавить хэштег-канал сообщества';

  @override
  String get community_addHashtagChannelDesc =>
      'Добавить хэштег-канал для этого сообщества';

  @override
  String get community_selectCommunity => 'Выбрать сообщество';

  @override
  String get community_regularHashtag => 'Обычный хэштег';

  @override
  String get community_regularHashtagDesc =>
      'Публичный хэштег (любой может присоединиться)';

  @override
  String get community_communityHashtag => 'Хэштег сообщества';

  @override
  String get community_communityHashtagDesc =>
      'Доступен только участникам сообщества';

  @override
  String community_forCommunity(String name) {
    return 'Для $name';
  }

  @override
  String get listFilter_tooltip => 'Фильтр и сортировка';

  @override
  String get listFilter_sortBy => 'Сортировка по';

  @override
  String get listFilter_latestMessages => 'Последние сообщения';

  @override
  String get listFilter_heardRecently => 'Слышали недавно';

  @override
  String get listFilter_az => 'По алфавиту';

  @override
  String get listFilter_filters => 'Фильтры';

  @override
  String get listFilter_all => 'Все';

  @override
  String get listFilter_favorites => 'Избранное';

  @override
  String get listFilter_addToFavorites => 'Добавить в избранное';

  @override
  String get listFilter_removeFromFavorites => 'Удалить из избранного';

  @override
  String get listFilter_users => 'Пользователи';

  @override
  String get listFilter_repeaters => 'Репитеры';

  @override
  String get listFilter_roomServers => 'Серверы комнат';

  @override
  String get listFilter_unreadOnly => 'Только непрочитанные';

  @override
  String get listFilter_newGroup => 'Новая группа';

  @override
  String get pathTrace_you => 'Вы';

  @override
  String get pathTrace_failed => 'Путь трассировки не выполнен.';

  @override
  String get pathTrace_notAvailable => 'Трассировка пути недоступна.';

  @override
  String get pathTrace_refreshTooltip => 'Обновить Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Одному или нескольким хмелям не указано местоположение!';

  @override
  String get pathTrace_clearTooltip => 'Очистить путь';

  @override
  String get losSelectStartEnd => 'Выберите начальный и конечный узлы для LOS.';

  @override
  String losRunFailed(String error) {
    return 'Проверка прямой видимости не удалась: $error';
  }

  @override
  String get losClearAllPoints => 'Очистить все точки';

  @override
  String get losRunToViewElevationProfile =>
      'Запустите LOS, чтобы просмотреть профиль высот.';

  @override
  String get losMenuTitle => 'ЛОС Меню';

  @override
  String get losMenuSubtitle =>
      'Коснитесь узлов или нажмите и удерживайте карту для выбора пользовательских точек.';

  @override
  String get losShowDisplayNodes => 'Показать узлы отображения';

  @override
  String get losCustomPoints => 'Пользовательские точки';

  @override
  String losCustomPointLabel(int index) {
    return 'Пользовательский $index';
  }

  @override
  String get losPointA => 'Точка А';

  @override
  String get losPointB => 'Точка Б';

  @override
  String losAntennaA(String value, String unit) {
    return 'Антенна А: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Антенна Б: $value $unit';
  }

  @override
  String get losRun => 'Запустить ЛОС';

  @override
  String get losNoElevationData => 'Нет данных о высоте';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, свободная зона видимости, минимальный зазор $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, заблокирован $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'ЛОС: проверяю...';

  @override
  String get losStatusNoData => 'ЛОС: нет данных';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total очищено, $blocked заблокировано, $unknown неизвестно.';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Данные о высоте недоступны для одного или нескольких образцов.';

  @override
  String get losErrorInvalidInput =>
      'Неверные данные о точках/высоте для расчета LOS.';

  @override
  String get losRenameCustomPoint => 'Переименовать пользовательскую точку';

  @override
  String get losPointName => 'Имя точки';

  @override
  String get losShowPanelTooltip => 'Показать панель LOS';

  @override
  String get losHidePanelTooltip => 'Скрыть панель LOS';

  @override
  String get losElevationAttribution =>
      'Данные о высоте: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Радиогоризонт';

  @override
  String get losLegendLosBeam => 'Линия прямой видимости';

  @override
  String get losLegendTerrain => 'Рельеф';

  @override
  String get losFrequencyLabel => 'Частота';

  @override
  String get losFrequencyInfoTooltip => 'Просмотреть детали расчёта';

  @override
  String get losFrequencyDialogTitle => 'Расчёт радиогоризонта';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Начиная с k=$baselineK на частоте $baselineFreq МГц, расчет корректирует коэффициент k для текущего диапазона $frequencyMHz МГц, который определяет изогнутую границу радиогоризонта.';
  }

  @override
  String get contacts_pathTrace => 'Трассировка пути';

  @override
  String get contacts_ping => 'Пинговать';

  @override
  String get contacts_repeaterPathTrace => 'Отследить путь к ретранслятору';

  @override
  String get contacts_repeaterPing => 'Пинговать повторитель';

  @override
  String get contacts_roomPathTrace => 'Трассировка пути к серверу комнаты';

  @override
  String get contacts_roomPing => 'Пинговать сервер комнаты';

  @override
  String get contacts_chatTraceRoute => 'Трассировка маршрута';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Показать маршрут к $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Буфер обмена пуст.';

  @override
  String get contacts_invalidAdvertFormat =>
      'Недействительные контактные данные';

  @override
  String get contacts_contactImported => 'Контакт был импортирован';

  @override
  String get contacts_contactImportFailed => 'Контакт не удалось импортировать';

  @override
  String get contacts_zeroHopAdvert => 'Реклама Zero Hop';

  @override
  String get contacts_floodAdvert => 'Рекламный поток';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Копировать рекламу в буфер обмена';

  @override
  String get contacts_addContactFromClipboard =>
      'Добавить контакт из буфера обмена';

  @override
  String get contacts_ShareContact => 'Копировать контакт в буфер обмена';

  @override
  String get contacts_ShareContactZeroHop =>
      'Поделиться контактом по объявлению';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Отправлено сообщение по объявлению.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Не удалось отправить контакт.';

  @override
  String get contacts_contactAdvertCopied =>
      'Реклама скопирована в буфер обмена.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копирование рекламы в буфер обмена не удалось.';

  @override
  String get notification_activityTitle => 'Активность MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сообщений',
      many: 'сообщений',
      few: 'сообщения',
      one: 'сообщение',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сообщений канала',
      many: 'сообщений канала',
      few: 'сообщения канала',
      one: 'сообщение канала',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'новых узлов',
      many: 'новых узлов',
      few: 'новых узла',
      one: 'новый узел',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Обнаружен новый $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Получено новое сообщение';

  @override
  String get settings_gpxExportRepeaters =>
      'Экспортировать рипитеры / сервер комнаты в GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Экспортирует ретрансляторы / сервер комнат с местоположением в файл GPX.';

  @override
  String get settings_gpxExportContacts => 'Экспортировать спутников в GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Экспортирует спутников с местоположением в файл GPX.';

  @override
  String get settings_gpxExportAll => 'Экспортировать все контакты в GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Экспортирует все контакты с местоположением в файл GPX.';

  @override
  String get settings_gpxExportSuccess => 'Успешно экспортирован файл GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Нет контактов для экспорта.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Не поддерживается на вашем устройстве/ОС';

  @override
  String get settings_gpxExportError => 'Произошла ошибка при экспорте.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Местоположения повторителей и серверов комнат';

  @override
  String get settings_gpxExportChat => 'Местоположения спутников';

  @override
  String get settings_gpxExportAllContacts => 'Все местоположения контактов';

  @override
  String get settings_gpxExportShareText =>
      'Данные карты экспортированы из meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'meshcore-open экспорт данных карты GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Ближайшие ретрансляторы';

  @override
  String get snrIndicator_lastSeen => 'Последний раз видели';

  @override
  String get contactsSettings_title => 'Настройки контактов';

  @override
  String get contactsSettings_autoAddTitle => 'Автоматическое обнаружение';

  @override
  String get contactsSettings_otherTitle =>
      'Другие настройки, связанные с контактами';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Автоматически добавлять пользователей';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Разрешить компаньону автоматически добавлять обнаруженных пользователей';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Автоматически добавлять ретрансляторы';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Разрешить спутнику автоматически добавлять обнаруженные ретрансляторы';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Автоматически добавлять серверы комнат';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Разрешить компаньону автоматически добавлять обнаруженные сервера комнат.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Автоматически добавлять датчики';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Разрешить компаньону автоматически добавлять обнаруженные датчики';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Перезаписать самое старое';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Когда список контактов заполнен, будет заменен самый старый контакт, который не находится в избранном.';

  @override
  String get discoveredContacts_Title => 'Обнаруженные контакты';

  @override
  String get discoveredContacts_noMatching => 'Нет совпадающих контактов';

  @override
  String get discoveredContacts_searchHint => 'Найденные контакты поиска';

  @override
  String get discoveredContacts_contactAdded => 'Контакт добавлен';

  @override
  String get discoveredContacts_addContact => 'Добавить контакт';

  @override
  String get discoveredContacts_copyContact =>
      'Копировать контакт в буфер обмена';

  @override
  String get discoveredContacts_deleteContact => 'Удалить контакт';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Удалить Все Обнаруженные Контакты';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Вы уверены, что хотите удалить все обнаруженные контакты?';
}
