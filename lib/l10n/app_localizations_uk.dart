// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Контакти';

  @override
  String get nav_channels => 'Канали';

  @override
  String get nav_map => 'Карта';

  @override
  String get common_cancel => 'Скасувати';

  @override
  String get common_ok => 'ОК';

  @override
  String get common_connect => 'Підключити';

  @override
  String get common_unknownDevice => 'Невідомий пристрій';

  @override
  String get common_save => 'Зберегти';

  @override
  String get common_delete => 'Видалити';

  @override
  String get common_deleteAll => 'Видалити все';

  @override
  String get common_close => 'Закрити';

  @override
  String get common_edit => 'Редагувати';

  @override
  String get common_add => 'Додати';

  @override
  String get common_settings => 'Налаштування';

  @override
  String get common_disconnect => 'Відключити';

  @override
  String get common_connected => 'Підключено';

  @override
  String get common_disconnected => 'Відключено';

  @override
  String get common_create => 'Створити';

  @override
  String get common_continue => 'Продовжити';

  @override
  String get common_share => 'Поділитися';

  @override
  String get common_copy => 'Копіювати';

  @override
  String get common_retry => 'Повторити';

  @override
  String get common_hide => 'Приховати';

  @override
  String get common_remove => 'Прибрати';

  @override
  String get common_enable => 'Увімкнути';

  @override
  String get common_disable => 'Вимкнути';

  @override
  String get common_reboot => 'Перезавантажити';

  @override
  String get common_loading => 'Завантаження...';

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
  String get usbScreenTitle => 'Підключити через USB';

  @override
  String get usbScreenSubtitle =>
      'Виберіть виявлене серійне пристрій і підключіть його безпосередньо до вашого вузла MeshCore.';

  @override
  String get usbScreenStatus => 'Виберіть пристрій USB';

  @override
  String get usbScreenNote =>
      'USB-серіальний інтерфейс активний на підтримуваних пристроях на базі Android та на десктопних платформах.';

  @override
  String get usbScreenEmptyState =>
      'Не знайдено жодних пристроїв USB. Підключіть один і перезавантажте.';

  @override
  String get usbErrorPermissionDenied =>
      'Було відмовлено у наданні дозволу на використання USB.';

  @override
  String get usbErrorDeviceMissing => 'Вибране USB-пристрій більше недоступне.';

  @override
  String get usbErrorInvalidPort => 'Виберіть дійсний USB-пристрій.';

  @override
  String get usbErrorBusy =>
      'Ще один запит на підключення через USB вже обробляється.';

  @override
  String get usbErrorNotConnected => 'Немає підключених пристроїв USB.';

  @override
  String get usbErrorOpenFailed => 'Не вдалося відкрити вибране USB-пристрій.';

  @override
  String get usbErrorConnectFailed =>
      'Не вдалося підключитися до вибраного USB-пристрою.';

  @override
  String get usbErrorUnsupported =>
      'Підтримка USB-серіального інтерфейсу не реалізована на цій платформі.';

  @override
  String get usbErrorAlreadyActive => 'USB-з\'єднання вже встановлено.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Не було вибрано жодного пристрою USB.';

  @override
  String get usbErrorPortClosed => 'З\'єднання USB не встановлено.';

  @override
  String get usbErrorConnectTimedOut =>
      'З\'єднання не вдалося встановити. Переконайтеся, що пристрій має встановлене програмне забезпечення USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Пристрій для передачі даних по веб-серіалах';

  @override
  String get usbStatus_notConnected => 'Виберіть пристрій USB';

  @override
  String get usbStatus_connecting => 'Підключення до USB-пристрою...';

  @override
  String get usbStatus_searching => 'Пошук пристроїв USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Не вдалося встановити з\'єднання через USB: $error';
  }

  @override
  String get scanner_scanning => 'Пошук пристроїв...';

  @override
  String get scanner_connecting => 'Підключення...';

  @override
  String get scanner_disconnecting => 'Відключення...';

  @override
  String get scanner_notConnected => 'Не підключено';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Підключено до $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Пошук пристроїв MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Натисніть «Сканувати», щоб знайти пристрої MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Помилка підключення: $error';
  }

  @override
  String get scanner_stop => 'Стоп';

  @override
  String get scanner_scan => 'Сканувати';

  @override
  String get scanner_bluetoothOff => 'Bluetooth вимкнено';

  @override
  String get scanner_bluetoothOffMessage =>
      'Будь ласка, увімкніть Bluetooth, щоб сканувати пристрої.';

  @override
  String get scanner_chromeRequired => 'Потрібен браузер Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Для підтримки Bluetooth у цьому веб-додатку потрібен Google Chrome або браузер на базі Chromium.';

  @override
  String get scanner_enableBluetooth => 'Увімкніть Bluetooth';

  @override
  String get device_quickSwitch => 'Швидке перемикання';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Налаштування';

  @override
  String get settings_deviceInfo => 'Інформація про пристрій';

  @override
  String get settings_appSettings => 'Налаштування програми';

  @override
  String get settings_appSettingsSubtitle =>
      'Сповіщення, повідомлення та налаштування карти';

  @override
  String get settings_nodeSettings => 'Налаштування вузла';

  @override
  String get settings_nodeName => 'Ім\'я вузла';

  @override
  String get settings_nodeNameNotSet => 'Не встановлено';

  @override
  String get settings_nodeNameHint => 'Введіть ім\'я вузла';

  @override
  String get settings_nodeNameUpdated => 'Ім\'я оновлено';

  @override
  String get settings_radioSettings => 'Налаштування радіо';

  @override
  String get settings_radioSettingsSubtitle =>
      'Частота, потужність, коефіцієнт розширення';

  @override
  String get settings_radioSettingsUpdated => 'Налаштування радіо оновлено';

  @override
  String get settings_location => 'Розташування';

  @override
  String get settings_locationSubtitle => 'GPS координати';

  @override
  String get settings_locationUpdated => 'Розташування оновлено';

  @override
  String get settings_locationBothRequired => 'Введіть широту та довготу.';

  @override
  String get settings_locationInvalid => 'Некоректна широта або довгота.';

  @override
  String get settings_locationGPSEnable => 'Увімкнути GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Вмикає автоматичне оновлення місцезнаходження через GPS.';

  @override
  String get settings_locationIntervalSec => 'Інтервал для GPS (Секунди)';

  @override
  String get settings_locationIntervalInvalid =>
      'Інтервал має бути не менше 60 секунд і менше 86400 секунд.';

  @override
  String get settings_latitude => 'Широта';

  @override
  String get settings_longitude => 'Довгота';

  @override
  String get settings_contactSettings => 'Налаштування контактів';

  @override
  String get settings_contactSettingsSubtitle =>
      'Налаштування для додавання контактів';

  @override
  String get settings_privacyMode => 'Режим приватності';

  @override
  String get settings_privacyModeSubtitle =>
      'Приховати ім\'я/розташування в оголошеннях';

  @override
  String get settings_privacyModeToggle =>
      'Увімкніть режим приватності, щоб приховати своє ім\'я та місцезнаходження в оголошеннях.';

  @override
  String get settings_privacyModeEnabled => 'Режим приватності увімкнено';

  @override
  String get settings_privacyModeDisabled => 'Режим приватності вимкнено';

  @override
  String get settings_actions => 'Дії';

  @override
  String get settings_sendAdvertisement => 'Оголосити себе';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Транслювати присутність зараз';

  @override
  String get settings_advertisementSent => 'Оголошення надіслано';

  @override
  String get settings_syncTime => 'Синхронізація часу';

  @override
  String get settings_syncTimeSubtitle =>
      'Встановити час пристрою відповідно до часу телефону.';

  @override
  String get settings_timeSynchronized => 'Час синхронізовано';

  @override
  String get settings_refreshContacts => 'Оновити контакти';

  @override
  String get settings_refreshContactsSubtitle =>
      'Перезавантажити список контактів з пристрою';

  @override
  String get settings_rebootDevice => 'Перезавантажити пристрій';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Перезавантажити пристрій MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ви впевнені, що хочете перезавантажити пристрій? Вас буде відключено.';

  @override
  String get settings_debug => 'Налагодження';

  @override
  String get settings_bleDebugLog => 'Журнал налагодження BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Команди BLE, відповіді та необроблені дані';

  @override
  String get settings_appDebugLog => 'Журнал налагодження програми';

  @override
  String get settings_appDebugLogSubtitle =>
      'Повідомлення налагодження програми';

  @override
  String get settings_about => 'Про програму';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => 'Проєкт MeshCore Open Source 2026';

  @override
  String get settings_aboutDescription =>
      'Клієнт Flutter з відкритим вихідним кодом для пристроїв мережі MeshCore LoRa.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Дані про висоту LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Ім\'я';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Статус';

  @override
  String get settings_infoBattery => 'Батарея';

  @override
  String get settings_infoPublicKey => 'Відкритий ключ';

  @override
  String get settings_infoContactsCount => 'Кількість контактів';

  @override
  String get settings_infoChannelCount => 'Кількість каналів';

  @override
  String get settings_presets => 'Попередні налаштування';

  @override
  String get settings_frequency => 'Частота (МГц)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Некоректна частота (300-2500 МГц)';

  @override
  String get settings_bandwidth => 'Смуга пропускання';

  @override
  String get settings_spreadingFactor => 'Коефіцієнт розширення';

  @override
  String get settings_codingRate => 'Швидкість кодування';

  @override
  String get settings_txPower => 'Потужність TX (дБм)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Некоректна потужність TX (0-22 дБм)';

  @override
  String get settings_clientRepeat => 'Автономна система';

  @override
  String get settings_clientRepeatSubtitle =>
      'Дозвольте цьому пристрою повторювати пакети даних для інших пристроїв.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Повтор без підключення до мережі вимагає частоти 433, 869 або 918 МГц.';

  @override
  String settings_error(String message) {
    return 'Помилка: $message';
  }

  @override
  String get appSettings_title => 'Налаштування програми';

  @override
  String get appSettings_appearance => 'Вигляд';

  @override
  String get appSettings_theme => 'Тема';

  @override
  String get appSettings_themeSystem => 'Системна';

  @override
  String get appSettings_themeLight => 'Світла';

  @override
  String get appSettings_themeDark => 'Темна';

  @override
  String get appSettings_language => 'Мова';

  @override
  String get appSettings_languageSystem => 'Як у системі';

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
  String get appSettings_languageRu => 'Російська';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get appSettings_enableMessageTracing =>
      'Увімкнути відстеження повідомлень';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показувати детальні метадані про маршрутизацію та час для повідомлень';

  @override
  String get appSettings_notifications => 'Сповіщення';

  @override
  String get appSettings_enableNotifications => 'Увімкнути сповіщення';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Отримувати сповіщення про повідомлення та оголошення';

  @override
  String get appSettings_notificationPermissionDenied =>
      'У доступі до сповіщень відмовлено';

  @override
  String get appSettings_notificationsEnabled => 'Сповіщення увімкнено';

  @override
  String get appSettings_notificationsDisabled => 'Сповіщення вимкнено';

  @override
  String get appSettings_messageNotifications => 'Сповіщення про повідомлення';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Показувати сповіщення при отриманні нових повідомлень';

  @override
  String get appSettings_channelMessageNotifications => 'Сповіщення каналів';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Показувати сповіщення при отриманні повідомлень каналу';

  @override
  String get appSettings_advertisementNotifications =>
      'Сповіщення про оголошення';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Показувати сповіщення при виявленні нових вузлів';

  @override
  String get appSettings_messaging => 'Обмін повідомленнями';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Очищати шлях після макс. спроб';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Скидати шлях до контакту після 5 невдалих спроб надсилання';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Шляхи будуть очищені після 5 невдалих спроб.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Шляхи не будуть очищатися автоматично.';

  @override
  String get appSettings_autoRouteRotation => 'Авторотація маршруту';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Чергувати найкращі шляхи та режим «на всю мережу» (flood)';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Авторотація маршрутизації увімкнена';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Авторотація маршрутизації вимкнена';

  @override
  String get appSettings_battery => 'Батарея';

  @override
  String get appSettings_batteryChemistry => 'Хімія батареї';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Встановити для пристрою ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Підключіть пристрій, щоб вибрати';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2В)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65В)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2В)';

  @override
  String get appSettings_mapDisplay => 'Відображення карти';

  @override
  String get appSettings_showRepeaters => 'Показувати ретранслятори';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Відображати вузли-ретранслятори на карті';

  @override
  String get appSettings_showChatNodes => 'Показувати вузли чату';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Відображати вузли чату на карті';

  @override
  String get appSettings_showOtherNodes => 'Показувати інші вузли';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Відображати інші типи вузлів на карті';

  @override
  String get appSettings_timeFilter => 'Фільтр часу';

  @override
  String get appSettings_timeFilterShowAll => 'Показати всі вузли';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Показати вузли за останні $hours год';
  }

  @override
  String get appSettings_mapTimeFilter => 'Фільтр часу карти';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Показувати вузли, виявлені за:';

  @override
  String get appSettings_allTime => 'Весь час';

  @override
  String get appSettings_lastHour => 'Останню годину';

  @override
  String get appSettings_last6Hours => 'Останні 6 годин';

  @override
  String get appSettings_last24Hours => 'Останні 24 години';

  @override
  String get appSettings_lastWeek => 'Минулий тиждень';

  @override
  String get appSettings_offlineMapCache => 'Офлайн-кеш карти';

  @override
  String get appSettings_unitsTitle => 'одиниці';

  @override
  String get appSettings_unitsMetric => 'Метричний (м / км)';

  @override
  String get appSettings_unitsImperial => 'Імперська (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Область не вибрано';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Вибрана область (зум $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Налагодження';

  @override
  String get appSettings_appDebugLogging => 'Логування налагодження програми';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записувати повідомлення налагодження програми в лог для усунення несправностей.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Логування налагодження програми увімкнено';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Налагодження програми вимкнено.';

  @override
  String get contacts_title => 'Контакти';

  @override
  String get contacts_noContacts => 'Контактів не знайдено.';

  @override
  String get contacts_contactsWillAppear =>
      'Контакти з\'являться, коли пристрої надішлють оголошення.';

  @override
  String get contacts_unread => 'Непрочитане';

  @override
  String get contacts_searchContactsNoNumber => 'Пошук контактів...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Пошук контактів...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Пошук $number$str улюблених...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Пошук $number$str користувачів...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Пошук $number$str ретрансляторів...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Пошук $number$str серверів кімнат...';
  }

  @override
  String get contacts_noUnreadContacts => 'Немає непрочитаних контактів';

  @override
  String get contacts_noContactsFound => 'Контактів або груп не знайдено.';

  @override
  String get contacts_deleteContact => 'Видалити контакт';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Видалити $contactName з контактів?';
  }

  @override
  String get contacts_manageRepeater => 'Керувати ретранслятором';

  @override
  String get contacts_manageRoom => 'Керувати сервером кімнати';

  @override
  String get contacts_roomLogin => 'Вхід у кімнату';

  @override
  String get contacts_openChat => 'Відкрити чат';

  @override
  String get contacts_editGroup => 'Редагувати групу';

  @override
  String get contacts_deleteGroup => 'Видалити групу';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Видалити $groupName?';
  }

  @override
  String get contacts_newGroup => 'Нова група';

  @override
  String get contacts_groupName => 'Назва групи';

  @override
  String get contacts_groupNameRequired => 'Назва групи обов\'язкова.';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Група «$name» вже існує.';
  }

  @override
  String get contacts_filterContacts => 'Фільтрувати контакти...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Жоден контакт не відповідає фільтру.';

  @override
  String get contacts_noMembers => 'Немає учасників';

  @override
  String get contacts_lastSeenNow => 'В мережі';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'В мережі $minutes хв. тому';
  }

  @override
  String get contacts_lastSeenHourAgo => 'В мережі 1 годину тому';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'В мережі $hours год. тому';
  }

  @override
  String get contacts_lastSeenDayAgo => 'В мережі 1 день тому';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'В мережі $days дн. тому';
  }

  @override
  String get channels_title => 'Канали';

  @override
  String get channels_noChannelsConfigured => 'Канали не налаштовані';

  @override
  String get channels_addPublicChannel => 'Додати публічний канал';

  @override
  String get channels_searchChannels => 'Пошук каналів...';

  @override
  String get channels_noChannelsFound => 'Каналів не знайдено';

  @override
  String channels_channelIndex(int index) {
    return 'Канал $index';
  }

  @override
  String get channels_hashtagChannel => 'Канал з хештегом';

  @override
  String get channels_public => 'Публічний';

  @override
  String get channels_private => 'Приватний';

  @override
  String get channels_publicChannel => 'Публічний канал';

  @override
  String get channels_privateChannel => 'Приватний канал';

  @override
  String get channels_editChannel => 'Редагувати канал';

  @override
  String get channels_muteChannel => 'Вимкнути сповіщення каналу';

  @override
  String get channels_unmuteChannel => 'Увімкнути сповіщення каналу';

  @override
  String get channels_deleteChannel => 'Видалити канал';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Видалити $name? Це не можна скасувати.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Не вдалося видалити канал \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Канал «$name» видалено';
  }

  @override
  String get channels_addChannel => 'Додати канал';

  @override
  String get channels_channelIndexLabel => 'Індекс каналу';

  @override
  String get channels_channelName => 'Назва каналу';

  @override
  String get channels_usePublicChannel => 'Використовувати публічний канал';

  @override
  String get channels_standardPublicPsk => 'Стандартний публічний PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Згенерувати випадковий ключ PSK';

  @override
  String get channels_enterChannelName => 'Будь ласка, введіть назву каналу';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK має складатися з 32 шістнадцяткових символів.';

  @override
  String channels_channelAdded(String name) {
    return 'Канал «$name» додано';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Редагувати канал $index';
  }

  @override
  String get channels_smazCompression => 'Стиснення SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Канал «$name» оновлено';
  }

  @override
  String get channels_publicChannelAdded => 'Публічний канал додано';

  @override
  String get channels_sortBy => 'Сортувати за';

  @override
  String get channels_sortManual => 'Вручну';

  @override
  String get channels_sortAZ => 'А-Я';

  @override
  String get channels_sortLatestMessages => 'Останні повідомлення';

  @override
  String get channels_sortUnread => 'Непрочитані';

  @override
  String get channels_createPrivateChannel => 'Створити приватний канал';

  @override
  String get channels_createPrivateChannelDesc => 'Захищено секретним ключем.';

  @override
  String get channels_joinPrivateChannel => 'Приєднатися до приватного каналу';

  @override
  String get channels_joinPrivateChannelDesc => 'Ввести секретний ключ вручну.';

  @override
  String get channels_joinPublicChannel => 'Приєднатися до публічного каналу';

  @override
  String get channels_joinPublicChannelDesc =>
      'Будь-хто може приєднатися до цього каналу.';

  @override
  String get channels_joinHashtagChannel => 'Приєднатися до каналу з хештегом';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Будь-хто може приєднатися до каналів #hashtag.';

  @override
  String get channels_scanQrCode => 'Сканувати QR-код';

  @override
  String get channels_scanQrCodeComingSoon => 'Скоро буде';

  @override
  String get channels_enterHashtag => 'Введіть хештег';

  @override
  String get channels_hashtagHint => 'напр. #команда';

  @override
  String get chat_noMessages => 'Поки немає повідомлень.';

  @override
  String get chat_sendMessageToStart => 'Надішліть повідомлення, щоб почати';

  @override
  String get chat_originalMessageNotFound =>
      'Оригінальне повідомлення не знайдено';

  @override
  String chat_replyingTo(String name) {
    return 'Відповідь $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Відповісти $name';
  }

  @override
  String get chat_location => 'Розташування';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Надіслати повідомлення $contactName';
  }

  @override
  String get chat_typeMessage => 'Введіть повідомлення...';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Повідомлення занадто довге (макс. $maxBytes байт).';
  }

  @override
  String get chat_messageCopied => 'Повідомлення скопійовано';

  @override
  String get chat_messageDeleted => 'Повідомлення видалено';

  @override
  String get chat_retryingMessage => 'Спроба відновлення.';

  @override
  String chat_retryCount(int current, int max) {
    return 'Повторна спроба $current/$max';
  }

  @override
  String get chat_sendGif => 'Надіслати GIF';

  @override
  String get chat_reply => 'Відповісти';

  @override
  String get chat_addReaction => 'Додати реакцію';

  @override
  String get chat_me => 'Я';

  @override
  String get emojiCategorySmileys => 'Емодзі';

  @override
  String get emojiCategoryGestures => 'Жести';

  @override
  String get emojiCategoryHearts => 'Серця';

  @override
  String get emojiCategoryObjects => 'Об\'єкти';

  @override
  String get gifPicker_title => 'Вибрати GIF';

  @override
  String get gifPicker_searchHint => 'Пошук GIF...';

  @override
  String get gifPicker_poweredBy => 'На базі GIPHY';

  @override
  String get gifPicker_noGifsFound => 'GIF не знайдено';

  @override
  String get gifPicker_failedLoad => 'Не вдалося завантажити GIF-файли';

  @override
  String get gifPicker_failedSearch => 'Пошук GIF не вдався';

  @override
  String get gifPicker_noInternet => 'Немає інтернет-з\'єднання';

  @override
  String get debugLog_appTitle => 'Журнал налагодження програми';

  @override
  String get debugLog_bleTitle => 'Журнал налагодження BLE';

  @override
  String get debugLog_copyLog => 'Копіювати журнал';

  @override
  String get debugLog_clearLog => 'Очистити журнал';

  @override
  String get debugLog_copied => 'Журнал налагодження скопійовано';

  @override
  String get debugLog_bleCopied => 'Журнал BLE скопійовано';

  @override
  String get debugLog_noEntries =>
      'Поки що немає записів журналу налагодження.';

  @override
  String get debugLog_enableInSettings =>
      'Увімкніть налагодження програми в налаштуваннях';

  @override
  String get debugLog_frames => 'Кадри';

  @override
  String get debugLog_rawLogRx => 'Необроблений лог - RX';

  @override
  String get debugLog_noBleActivity => 'Поки що немає активності BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Довжина кадру: $count байт';
  }

  @override
  String debugFrame_command(String value) {
    return 'Команда: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Повідомлення:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- PubKey призначення: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Мітка часу: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Прапорці: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Тип тексту: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Звичайний';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Дамп Hex:';

  @override
  String get chat_pathManagement => 'Керування шляхами';

  @override
  String get chat_ShowAllPaths => 'Показати всі шляхи';

  @override
  String get chat_routingMode => 'Режим маршрутизації';

  @override
  String get chat_autoUseSavedPath => 'Авто (використовувати збережений шлях)';

  @override
  String get chat_forceFloodMode => 'Примусово на всю мережу';

  @override
  String get chat_recentAckPaths =>
      'Недавні шляхи ACK (натисніть, щоб використати):';

  @override
  String get chat_pathHistoryFull =>
      'Історія шляхів заповнена. Видаліть записи, щоб додати нові.';

  @override
  String get chat_hopSingular => 'Стрибок';

  @override
  String get chat_hopPlural => 'стрибків';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стрибків',
      many: 'стрибків',
      few: 'стрибки',
      one: 'стрибок',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_successes => 'Успішно';

  @override
  String get chat_removePath => 'Видалити шлях';

  @override
  String get chat_noPathHistoryYet =>
      'Історія шляхів недоступна.\nНадішліть повідомлення, щоб виявити шляхи.';

  @override
  String get chat_pathActions => 'Дії зі шляхом:';

  @override
  String get chat_setCustomPath => 'Встановити власний шлях';

  @override
  String get chat_setCustomPathSubtitle => 'Вказати шлях маршрутизації вручну';

  @override
  String get chat_clearPath => 'Очистити шлях';

  @override
  String get chat_clearPathSubtitle =>
      'Примусово повторити пошук при наступному надсиланні';

  @override
  String get chat_pathCleared =>
      'Шлях очищено. Наступне повідомлення оновить маршрут.';

  @override
  String get chat_floodModeSubtitle =>
      'Використовувати перемикач маршрутизації в панелі програми';

  @override
  String get chat_floodModeEnabled =>
      'Увімкнено режим «на всю мережу». Перемикайте через іконку маршрутизації на панелі інструментів.';

  @override
  String get chat_fullPath => 'Повний шлях';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Деталі шляху ще недоступні. Спробуйте надіслати повідомлення для оновлення.';

  @override
  String chat_pathSetHops(int hopCount, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      hopCount,
      locale: localeName,
      other: 'стрибків',
      many: 'стрибків',
      few: 'стрибки',
      one: 'стрибок',
    );
    return 'Шлях встановлено: $hopCount $_temp0 - $status';
  }

  @override
  String get chat_pathSavedLocally =>
      'Збережено локально. Підключіться для синхронізації.';

  @override
  String get chat_pathDeviceConfirmed => 'Пристрій підтверджено.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Пристрій ще не підтверджено.';

  @override
  String get chat_type => 'Ввід';

  @override
  String get chat_path => 'Шлях';

  @override
  String get chat_publicKey => 'Відкритий ключ';

  @override
  String get chat_compressOutgoingMessages => 'Стискати вихідні повідомлення';

  @override
  String get chat_floodForced => 'На всю мережу (примусово)';

  @override
  String get chat_directForced => 'Прямий (примусово)';

  @override
  String chat_hopsForced(int count) {
    return '$count стрибків (примусово)';
  }

  @override
  String get chat_floodAuto => 'На всю мережу (авто)';

  @override
  String get chat_direct => 'Прямий';

  @override
  String get chat_poiShared => 'Точкою інтересу поділилися';

  @override
  String chat_unread(int count) {
    return 'Непрочитано: $count';
  }

  @override
  String get chat_openLink => 'Відкрити посилання?';

  @override
  String get chat_openLinkConfirmation =>
      'Ви хочете відкрити це посилання у браузері?';

  @override
  String get chat_open => 'Відкрити';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Не вдалося відкрити посилання: $url';
  }

  @override
  String get chat_invalidLink => 'Невірний формат посилання';

  @override
  String get map_title => 'Карта вузлів';

  @override
  String get map_lineOfSight => 'Пряма видимість';

  @override
  String get map_losScreenTitle => 'Пряма видимість';

  @override
  String get map_noNodesWithLocation =>
      'Немає вузлів з даними про розташування';

  @override
  String get map_nodesNeedGps =>
      'Вузли повинні надавати свої GPS координати,\nщоб з\'явитися на карті.';

  @override
  String map_nodesCount(int count) {
    return 'Вузли: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Мітки: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Ретранслятор';

  @override
  String get map_room => 'Кімната';

  @override
  String get map_sensor => 'Сенсор';

  @override
  String get map_pinDm => 'Ключ (DM)';

  @override
  String get map_pinPrivate => 'Замок (Приватний)';

  @override
  String get map_pinPublic => 'Ключ (Публічний)';

  @override
  String get map_lastSeen => 'Останній раз бачили';

  @override
  String get map_disconnectConfirm =>
      'Ви впевнені, що хочете відключитися від цього пристрою?';

  @override
  String get map_from => 'Від';

  @override
  String get map_source => 'Джерело';

  @override
  String get map_flags => 'Прапорці';

  @override
  String get map_shareMarkerHere => 'Поділитися маркером тут';

  @override
  String get map_pinLabel => 'Мітка піна';

  @override
  String get map_label => 'Мітка';

  @override
  String get map_pointOfInterest => 'Точка інтересу';

  @override
  String get map_sendToContact => 'Надіслати контакту';

  @override
  String get map_sendToChannel => 'Надіслати в канал';

  @override
  String get map_noChannelsAvailable => 'Немає доступних каналів';

  @override
  String get map_publicLocationShare => 'Поділитися в публічному місці';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Ви збираєтеся поділитися розташуванням у $channelLabel. Цей канал публічний, і кожен, хто має ключ PSK, може це побачити.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Підключіться до пристрою, щоб поділитися маркерами';

  @override
  String get map_filterNodes => 'Фільтрувати вузли';

  @override
  String get map_nodeTypes => 'Типи вузлів';

  @override
  String get map_chatNodes => 'Вузли чату';

  @override
  String get map_repeaters => 'Ретранслятори';

  @override
  String get map_otherNodes => 'Інші вузли';

  @override
  String get map_keyPrefix => 'Префікс ключа';

  @override
  String get map_filterByKeyPrefix => 'Фільтрувати за префіксом ключа';

  @override
  String get map_publicKeyPrefix => 'Префікс відкритого ключа';

  @override
  String get map_markers => 'Маркери';

  @override
  String get map_showSharedMarkers => 'Показувати спільні маркери';

  @override
  String get map_showGuessedLocations =>
      'Показати місцезнаходження передбачених вузлів';

  @override
  String get map_showDiscoveryContacts => 'Показати контакти Відкриття';

  @override
  String get map_guessedLocation => 'Визначено місцезнаходження';

  @override
  String get map_lastSeenTime => 'Час останньої активності';

  @override
  String get map_sharedPin => 'Спільний пін';

  @override
  String get map_joinRoom => 'Приєднатися до кімнати';

  @override
  String get map_manageRepeater => 'Керувати ретранслятором';

  @override
  String get map_tapToAdd => 'Натисніть на вузли, щоб додати їх до шляху';

  @override
  String get map_runTrace => 'Виконати трасування шляху';

  @override
  String get map_removeLast => 'Видалити останній';

  @override
  String get map_pathTraceCancelled => 'Відмінується трасування шляху';

  @override
  String get mapCache_title => 'Офлайн-кеш карти';

  @override
  String get mapCache_selectAreaFirst =>
      'Спершу виберіть область для кешування';

  @override
  String get mapCache_noTilesToDownload =>
      'Немає плиток для завантаження в цій області.';

  @override
  String get mapCache_downloadTilesTitle => 'Завантажити плитки';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Завантажити $count плиток для використання офлайн?';
  }

  @override
  String get mapCache_downloadAction => 'Завантажити';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Закешовано $count плиток';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Плитки в кеші ($downloaded) ($failed помилок)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Очистити офлайн-кеш';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Видалити всі закешовані плитки карти?';

  @override
  String get mapCache_offlineCacheCleared => 'Офлайн-кеш очищено.';

  @override
  String get mapCache_noAreaSelected => 'Область не вибрано';

  @override
  String get mapCache_cacheArea => 'Область кешування';

  @override
  String get mapCache_useCurrentView => 'Використати поточний вигляд';

  @override
  String get mapCache_zoomRange => 'Діапазон масштабування';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Оцінка плиток: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Завантажено $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Завантажити плитки';

  @override
  String get mapCache_clearCacheButton => 'Очистити кеш';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Невдалі завантаження: $count';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'Пн $north, Пд $south, Сх $east, Зх $west';
  }

  @override
  String get time_justNow => 'Тільки що';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes хв. тому';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours год. тому';
  }

  @override
  String time_daysAgo(int days) {
    return '$days дн. тому';
  }

  @override
  String get time_hour => 'година';

  @override
  String get time_hours => 'годин';

  @override
  String get time_day => 'день';

  @override
  String get time_days => 'днів';

  @override
  String get time_week => 'тиждень';

  @override
  String get time_weeks => 'тижнів';

  @override
  String get time_month => 'місяць';

  @override
  String get time_months => 'місяців';

  @override
  String get time_minutes => 'хвилин';

  @override
  String get time_allTime => 'Весь час';

  @override
  String get dialog_disconnect => 'Відключити';

  @override
  String get dialog_disconnectConfirm =>
      'Ви впевнені, що хочете відключитися від цього пристрою?';

  @override
  String get login_repeaterLogin => 'Вхід у ретранслятор';

  @override
  String get login_roomLogin => 'Вхід у кімнату';

  @override
  String get login_password => 'Пароль';

  @override
  String get login_enterPassword => 'Введіть пароль';

  @override
  String get login_savePassword => 'Зберегти пароль';

  @override
  String get login_savePasswordSubtitle =>
      'Пароль буде надійно збережено на цьому пристрої.';

  @override
  String get login_repeaterDescription =>
      'Введіть пароль ретранслятора для доступу до налаштувань та статусу.';

  @override
  String get login_roomDescription =>
      'Введіть пароль кімнати для доступу до налаштувань та статусу.';

  @override
  String get login_routing => 'Маршрутизація';

  @override
  String get login_routingMode => 'Режим маршрутизації';

  @override
  String get login_autoUseSavedPath => 'Авто (використовувати збережений шлях)';

  @override
  String get login_forceFloodMode => 'Примусово на всю мережу';

  @override
  String get login_managePaths => 'Керувати шляхами';

  @override
  String get login_login => 'Вхід';

  @override
  String login_attempt(int current, int max) {
    return 'Спроба $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Вхід не вдався: $error';
  }

  @override
  String get login_failedMessage =>
      'Вхід не вдався. Або пароль неправильний, або ретранслятор недосяжний.';

  @override
  String get common_reload => 'Перезавантажити';

  @override
  String get common_clear => 'Очистити';

  @override
  String path_currentPath(String path) {
    return 'Поточний шлях: $path';
  }

  @override
  String path_usingHopsPath(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стрибками',
      many: 'стрибками',
      few: 'стрибками',
      one: 'стрибком',
    );
    return 'Використання шляху з $count $_temp0';
  }

  @override
  String get path_enterCustomPath => 'Ввести власний шлях';

  @override
  String get path_currentPathLabel => 'Поточний шлях';

  @override
  String get path_hexPrefixInstructions =>
      'Введіть 2-символьні hex-префікси для кожного стрибка, розділені комами.';

  @override
  String get path_hexPrefixExample =>
      'Приклад: A1,F2,3C (кожен вузол використовує перший байт свого відкритого ключа).';

  @override
  String get path_labelHexPrefixes => 'Hex-префікси';

  @override
  String get path_helperMaxHops =>
      'Макс. 64 стрибки. Кожен префікс - 2 шістнадцяткові символи (1 байт)';

  @override
  String get path_selectFromContacts => 'Вибрати з контактів:';

  @override
  String get path_noRepeatersFound =>
      'Ретрансляторів або серверів кімнат не знайдено.';

  @override
  String get path_customPathsRequire =>
      'Власні шляхи вимагають проміжних вузлів, які можуть передавати повідомлення.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Некоректні hex-префікси: $prefixes';
  }

  @override
  String get path_tooLong => 'Шлях занадто довгий. Максимум 64 стрибки.';

  @override
  String get path_setPath => 'Встановити шлях';

  @override
  String get repeater_management => 'Керування ретранслятором';

  @override
  String get room_management => 'Адміністрування сервера кімнати';

  @override
  String get repeater_managementTools => 'Інструменти керування';

  @override
  String get repeater_status => 'Статус';

  @override
  String get repeater_statusSubtitle =>
      'Показати статус, статистику та сусідів ретранслятора';

  @override
  String get repeater_telemetry => 'Телеметрія';

  @override
  String get repeater_telemetrySubtitle =>
      'Показати телеметрію сенсорів та статистику системи';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Надіслати команди ретранслятору';

  @override
  String get repeater_neighbors => 'Сусіди';

  @override
  String get repeater_neighborsSubtitle =>
      'Показати сусідів нульового стрибка.';

  @override
  String get repeater_settings => 'Налаштування';

  @override
  String get repeater_settingsSubtitle => 'Налаштувати параметри ретранслятора';

  @override
  String get repeater_statusTitle => 'Статус ретранслятора';

  @override
  String get repeater_routingMode => 'Режим маршрутизації';

  @override
  String get repeater_autoUseSavedPath =>
      'Авто (використовувати збережений шлях)';

  @override
  String get repeater_forceFloodMode => 'Примусово на всю мережу';

  @override
  String get repeater_pathManagement => 'Керування шляхами';

  @override
  String get repeater_refresh => 'Оновити';

  @override
  String get repeater_statusRequestTimeout =>
      'Час очікування запиту статусу вичерпано.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Помилка завантаження статусу: $error';
  }

  @override
  String get repeater_systemInformation => 'Системна інформація';

  @override
  String get repeater_battery => 'Батарея';

  @override
  String get repeater_clockAtLogin => 'Годинник (при вході)';

  @override
  String get repeater_uptime => 'Час роботи';

  @override
  String get repeater_queueLength => 'Довжина черги';

  @override
  String get repeater_debugFlags => 'Прапорці налагодження';

  @override
  String get repeater_radioStatistics => 'Статистика радіо';

  @override
  String get repeater_lastRssi => 'Останній RSSI';

  @override
  String get repeater_lastSnr => 'Останній SNR';

  @override
  String get repeater_noiseFloor => 'Рівень шуму';

  @override
  String get repeater_txAirtime => 'Ефірний час TX';

  @override
  String get repeater_rxAirtime => 'Ефірний час RX';

  @override
  String get repeater_packetStatistics => 'Статистика пакетів';

  @override
  String get repeater_sent => 'Надіслано';

  @override
  String get repeater_received => 'Отримано';

  @override
  String get repeater_duplicates => 'Дублікати';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days дн. $hours год $minutes хв $seconds с';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Всього: $total, На всю мережу: $flood, Прямі: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Всього: $total, На всю мережу: $flood, Прямі: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'На всю мережу: $flood, Прямі: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Всього: $total';
  }

  @override
  String get repeater_settingsTitle => 'Налаштування ретранслятора';

  @override
  String get repeater_basicSettings => 'Основні налаштування';

  @override
  String get repeater_repeaterName => 'Ім\'я ретранслятора';

  @override
  String get repeater_repeaterNameHelper =>
      'Показати ім\'я цього ретранслятора';

  @override
  String get repeater_adminPassword => 'Пароль адміністратора';

  @override
  String get repeater_adminPasswordHelper => 'Пароль повного доступу';

  @override
  String get repeater_guestPassword => 'Гостьовий пароль';

  @override
  String get repeater_guestPasswordHelper =>
      'Доступ лише для читання з паролем';

  @override
  String get repeater_radioSettings => 'Налаштування радіо';

  @override
  String get repeater_frequencyMhz => 'Частота (МГц)';

  @override
  String get repeater_frequencyHelper => '300-2500 МГц';

  @override
  String get repeater_txPower => 'Потужність TX';

  @override
  String get repeater_txPowerHelper => '1-30 дБм';

  @override
  String get repeater_bandwidth => 'Смуга пропускання';

  @override
  String get repeater_spreadingFactor => 'Коефіцієнт розширення';

  @override
  String get repeater_codingRate => 'Швидкість кодування';

  @override
  String get repeater_locationSettings => 'Налаштування розташування';

  @override
  String get repeater_latitude => 'Широта';

  @override
  String get repeater_latitudeHelper =>
      'Десяткові градуси (наприклад, 37.7749)';

  @override
  String get repeater_longitude => 'Довгота';

  @override
  String get repeater_longitudeHelper =>
      'Десяткові градуси (наприклад, -122.4194)';

  @override
  String get repeater_features => 'Функції';

  @override
  String get repeater_packetForwarding => 'Пересилання пакетів';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Дозволити ретранслятору пересилати пакети';

  @override
  String get repeater_guestAccess => 'Гостьовий доступ';

  @override
  String get repeater_guestAccessSubtitle =>
      'Дозволити гостьовий доступ лише для читання';

  @override
  String get repeater_privacyMode => 'Режим приватності';

  @override
  String get repeater_privacyModeSubtitle =>
      'Приховати ім\'я/розташування в оголошеннях';

  @override
  String get repeater_advertisementSettings => 'Налаштування оголошень';

  @override
  String get repeater_localAdvertInterval =>
      'Інтервал локальних оголошень (0 стрибків)';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes хвилин';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Інтервал оголошень на всю мережу (flood)';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours годин';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Інтервал зашифрованих оголошень';

  @override
  String get repeater_dangerZone => 'Небезпечна зона';

  @override
  String get repeater_rebootRepeater => 'Перезавантажити ретранслятор';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Скинути пристрій ретранслятора';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ви впевнені, що хочете перезавантажити цей ретранслятор?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Перегенерувати ключ ідентичності';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Згенерувати нову пару ключів (публічний/приватний)';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Це створить нову ідентичність для ретранслятора. Продовжити?';

  @override
  String get repeater_eraseFileSystem => 'Очистити файлову систему';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Відформатувати файлову систему ретранслятора';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'УВАГА: Це видалить всі дані з ретранслятора. Це не можна скасувати!';

  @override
  String get repeater_eraseSerialOnly =>
      'Очищення доступне лише через послідовну консоль.';

  @override
  String repeater_commandSent(String command) {
    return 'Команда надіслана: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Помилка надсилання команди: $error';
  }

  @override
  String get repeater_confirm => 'Підтвердити';

  @override
  String get repeater_settingsSaved => 'Налаштування успішно збережено.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Помилка збереження налаштувань: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Оновити основні налаштування';

  @override
  String get repeater_refreshRadioSettings => 'Оновити налаштування радіо';

  @override
  String get repeater_refreshTxPower => 'Оновити потужність TX';

  @override
  String get repeater_refreshLocationSettings =>
      'Оновити налаштування розташування';

  @override
  String get repeater_refreshPacketForwarding => 'Оновити пересилання пакетів';

  @override
  String get repeater_refreshGuestAccess => 'Оновити гостьовий доступ';

  @override
  String get repeater_refreshPrivacyMode => 'Оновити режим приватності';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Оновити налаштування оголошень';

  @override
  String repeater_refreshed(String label) {
    return '$label оновлено';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Помилка оновлення $label';
  }

  @override
  String get repeater_cliTitle => 'Ретранслятор CLI';

  @override
  String get repeater_debugNextCommand => 'Налагодити наступну команду';

  @override
  String get repeater_commandHelp => 'Довідка';

  @override
  String get repeater_clearHistory => 'Очистити історію';

  @override
  String get repeater_noCommandsSent => 'Команди ще не надсилалися.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Введіть команду нижче або використовуйте швидкі команди';

  @override
  String get repeater_enterCommandHint => 'Введіть команду...';

  @override
  String get repeater_previousCommand => 'Попередня команда';

  @override
  String get repeater_nextCommand => 'Наступна команда';

  @override
  String get repeater_enterCommandFirst => 'Спершу введіть команду';

  @override
  String get repeater_cliCommandFrameTitle => 'Фрейм команди CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Помилка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Отримати ім\'я';

  @override
  String get repeater_cliQuickGetRadio => 'Отримати Радіо';

  @override
  String get repeater_cliQuickGetTx => 'Отримати TX';

  @override
  String get repeater_cliQuickNeighbors => 'Сусіди';

  @override
  String get repeater_cliQuickVersion => 'Версія';

  @override
  String get repeater_cliQuickAdvertise => 'Оголосити';

  @override
  String get repeater_cliQuickClock => 'Годинник';

  @override
  String get repeater_cliHelpAdvert => 'Надсилає пакет оголошення';

  @override
  String get repeater_cliHelpReboot =>
      'Перезавантажує пристрій. (Зверніть увагу, ви можете отримати «Тайм-аут», що є нормальним)';

  @override
  String get repeater_cliHelpClock =>
      'Відображає поточний час за годинником кожного пристрою.';

  @override
  String get repeater_cliHelpPassword =>
      'Встановлює новий пароль адміністратора для пристрою.';

  @override
  String get repeater_cliHelpVersion =>
      'Відображає версію пристрою та дату збірки прошивки.';

  @override
  String get repeater_cliHelpClearStats =>
      'Скидає різні лічильники статистики до нуля.';

  @override
  String get repeater_cliHelpSetAf => 'Встановлює коефіцієнт ефірного часу.';

  @override
  String get repeater_cliHelpSetTx =>
      'Встановлює потужність передачі LoRa в дБм (для застосування потрібне перезавантаження).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Вмикає або вимикає роль ретранслятора для цього вузла.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Сервер кімнати) Якщо «увімкнено», порожній пароль дозволить вхід, але не дозволить публікувати в кімнаті. (тільки читання)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Встановлює максимальну кількість стрибків для вхідних пакетів flood (якщо >= max, пакет не пересилається).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Встановлює поріг інтерференції (в дБ). Значення за замовчуванням — 14. Встановлення на 0 вимикає виявлення інтерференції каналу.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Встановлює інтервал скидання автоматичного контролера посилення (AGC). Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Вмикає або вимикає функціональність подвійних ACK.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Встановлює інтервал таймера для надсилання локального пакету оголошення (без ретрансляції). Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Встановлює інтервал таймера в годинах для надсилання пакету оголошення на всю мережу. Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Встановлює/оновлює гостьовий пароль. (для ретрансляторів гостьові підключення можуть надсилати запит «Get Stats»)';

  @override
  String get repeater_cliHelpSetName => 'Встановлює ім\'я для оголошення.';

  @override
  String get repeater_cliHelpSetLat =>
      'Встановлює широту для карти оголошень. (десяткові градуси)';

  @override
  String get repeater_cliHelpSetLon =>
      'Встановлює довготу для карти оголошень. (десяткові градуси)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Повністю встановлює нові параметри радіо та зберігає їх у налаштуваннях. Потребує команди «перезавантаження» для застосування.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Базові (експериментальні) параметри для застосування невеликої затримки до отриманих пакетів залежно від сили сигналу/оцінки. Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Встановлює множник для часу роботи в режимі «на всю мережу» (flood) для пакету та системи випадкових слотів, щоб затримати його відправку (для зменшення ймовірності колізій).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Те саме, що й txdelay, але для застосування випадкової затримки при пересиланні пакетів у прямому режимі.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Увімкнути/Вимкнути міст.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Встановити затримку перед пересиланням пакетів.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Виберіть, чи буде міст ретранслювати отримані пакети або передані пакети.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Встановити швидкість послідовного зв\'язку для мостів Rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Встановити секрет мосту для мостів espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Встановлює власний множник для коригування повідомлюваної напруги батареї (підтримується лише на деяких платах).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Встановлює тимчасові параметри радіо на задану кількість хвилин, потім повертається до початкових налаштувань. (не зберігає в налаштуваннях).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Змінює ACL (список контролю доступу). Видаляє відповідний запис (за префіксом публічного ключа), якщо «permissions» дорівнює нулю. Додає новий запис, якщо hex публічного ключа повний і його немає в ACL. Оновлює запис на основі префікса публічного ключа. Біти дозволів залежать від ролі прошивки, але нижні 2 біти: 0 (Гість), 1 (Тільки читання), 2 (Читання/Запис), 3 (Адміністратор).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Отримати тип мосту: немає, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Починає запис пакетів у файлову систему.';

  @override
  String get repeater_cliHelpLogStop =>
      'Зупиняє запис пакетів у файлову систему.';

  @override
  String get repeater_cliHelpLogErase =>
      'Видаляє журнали пакетів з файлової системи.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Показує список інших вузлів-ретрансляторів, почутих через оголошення без ретрансляції. Кожен рядок — id-hex-префікс:timestamp:snr-помножено-на-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Видаляє перший відповідний запис (за префіксом публічного ключа (hex)) зі списку сусідів.';

  @override
  String get repeater_cliHelpRegion =>
      '(тільки серійний) Перелічує всі визначені регіони та поточні дозволи на оголошення «на всю мережу» (flood).';

  @override
  String get repeater_cliHelpRegionLoad =>
      'ПРИМІТКА: це спеціальний виклик кількох команд. Кожна наступна команда — це назва регіону (з відступом пробілами для позначення ієрархії батьків, мінімум один пробіл). Завершується надсиланням порожнього рядка/команди.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Шукає регіон із заданим префіксом назви (або «» для глобальної області). Відповідає: «-> ім\'я-регіону (ім\'я-батька) \'F\'»';

  @override
  String get repeater_cliHelpRegionPut =>
      'Додає або оновлює визначення регіону з заданою назвою.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Видаляє визначення регіону з заданою назвою.';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Встановлює дозвіл «Flood» для заданого регіону. (\'\' для глобальної/успадкованої області)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Видаляє дозвіл «Flood» для заданого регіону. (ПРИМІТКА: на даному етапі не рекомендується використовувати для глобальної/успадкованої області!! )';

  @override
  String get repeater_cliHelpRegionHome =>
      'Відповідає поточним «домашнім» регіоном. (Примітка: поки ніде не застосовується, зарезервовано для майбутнього використання)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Встановлює «домашній» регіон.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Зберігає список/карту регіонів у сховищі.';

  @override
  String get repeater_cliHelpGps =>
      'Показує статус GPS. Коли GPS вимкнено, відповідає лише «вимкнено», якщо увімкнено — відповідає «увімкнено», статус, корекція, кількість супутників.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Увімкнути/вимкнути GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Синхронізує час вузла з годинником GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Встановлює позицію вузла за координатами GPS і зберігає в налаштуваннях.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Надає конфігурацію оголошення розташування вузла:\n- none : не включати розташування в оголошення\n- share : ділитися розташуванням GPS (з SensorManager)\n- prefs : оголошувати розташування, збережене в налаштуваннях';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Встановлює конфігурацію оголошення розташування.';

  @override
  String get repeater_commandsListTitle => 'Список команд';

  @override
  String get repeater_commandsListNote =>
      'ПРИМІТКА: для різних команд «set»... також існує команда «get»...';

  @override
  String get repeater_general => 'Загальні';

  @override
  String get repeater_settingsCategory => 'Налаштування';

  @override
  String get repeater_bridge => 'Міст';

  @override
  String get repeater_logging => 'Логування';

  @override
  String get repeater_neighborsRepeaterOnly => 'Сусіди (Тільки ретранслятор)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Керування регіонами (Тільки ретранслятор)';

  @override
  String get repeater_regionNote =>
      'Команди регіонів були введені для керування визначеннями та дозволами регіонів.';

  @override
  String get repeater_gpsManagement => 'Керування GPS';

  @override
  String get repeater_gpsNote =>
      'Команда GPS була введена для керування питаннями, пов\'язаними з локацією.';

  @override
  String get telemetry_receivedData => 'Дані телеметрії отримано';

  @override
  String get telemetry_requestTimeout => 'Час запиту телеметрії вичерпано.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Помилка завантаження телеметрії: $error';
  }

  @override
  String get telemetry_noData => 'Дані телеметрії недоступні.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Канал $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Батарея';

  @override
  String get telemetry_voltageLabel => 'Напруга';

  @override
  String get telemetry_mcuTemperatureLabel => 'Температура MCU';

  @override
  String get telemetry_temperatureLabel => 'Температура';

  @override
  String get telemetry_currentLabel => 'Поточний струм';

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
  String get neighbors_receivedData => 'Дані сусідів отримано';

  @override
  String get neighbors_requestTimedOut => 'Час запиту сусідів вичерпано.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Помилка завантаження сусідів: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ретранслятори-сусіди';

  @override
  String get neighbors_noData => 'Дані про сусідів недоступні.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Невідомий відкритий ключ $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Почуто: $time тому';
  }

  @override
  String get channelPath_title => 'Шлях пакету';

  @override
  String get channelPath_viewMap => 'Показати карту';

  @override
  String get channelPath_otherObservedPaths => 'Інші спостережувані шляхи';

  @override
  String get channelPath_repeaterHops => 'Стрибки ретранслятора';

  @override
  String get channelPath_noHopDetails =>
      'Деталі відправки не надані для цього пакету.';

  @override
  String get channelPath_messageDetails => 'Деталі повідомлення';

  @override
  String get channelPath_senderLabel => 'Відправник';

  @override
  String get channelPath_timeLabel => 'Час';

  @override
  String get channelPath_repeatsLabel => 'Повторення';

  @override
  String channelPath_pathLabel(int index) {
    return 'Шлях $index';
  }

  @override
  String get channelPath_observedLabel => 'Спостережено';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Спостережуваний шлях $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Немає даних про розташування';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Невідомий';

  @override
  String get channelPath_floodPath => 'На всю мережу';

  @override
  String get channelPath_directPath => 'Прямий';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 з $total стрибків';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed з $total стрибків';
  }

  @override
  String get channelPath_mapTitle => 'Карта шляху';

  @override
  String get channelPath_noRepeaterLocations =>
      'Позиції ретрансляторів недоступні для цього шляху.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Шлях $index (Основний)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Шлях';

  @override
  String get channelPath_observedPathHeader => 'Спостережуваний шлях';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Деталі стрибків недоступні для цього пакету.';

  @override
  String get channelPath_unknownRepeater => 'Невідомий ретранслятор';

  @override
  String get community_title => 'Спільнота';

  @override
  String get community_create => 'Створити спільноту';

  @override
  String get community_createDesc =>
      'Створити нову спільноту та поділитися через QR-код.';

  @override
  String get community_join => 'Приєднатися';

  @override
  String get community_joinTitle => 'Приєднатися до спільноти';

  @override
  String community_joinConfirmation(String name) {
    return 'Ви бажаєте приєднатися до спільноти «$name»?';
  }

  @override
  String get community_scanQr => 'Сканувати QR спільноти';

  @override
  String get community_scanInstructions =>
      'Наведіть камеру на QR-код спільноти.';

  @override
  String get community_showQr => 'Показати QR-код';

  @override
  String get community_publicChannel => 'Публічна спільнота';

  @override
  String get community_hashtagChannel => 'Хештег спільноти';

  @override
  String get community_name => 'Назва спільноти';

  @override
  String get community_enterName => 'Введіть назву спільноти';

  @override
  String community_created(String name) {
    return 'Спільноту «$name» створено';
  }

  @override
  String community_joined(String name) {
    return 'Приєднався до спільноти «$name»';
  }

  @override
  String get community_qrTitle => 'Поділитися спільнотою';

  @override
  String community_qrInstructions(String name) {
    return 'Відскануйте цей QR-код, щоб приєднатися до $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Канали хештегів спільноти доступні лише членам спільноти';

  @override
  String get community_invalidQrCode => 'Недійсний QR-код спільноти';

  @override
  String get community_alreadyMember => 'Вже учасник';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Ви вже є учасником «$name».';
  }

  @override
  String get community_addPublicChannel => 'Додати публічний канал спільноти';

  @override
  String get community_addPublicChannelHint =>
      'Автоматично додати публічний канал для цієї спільноти';

  @override
  String get community_noCommunities => 'Поки не приєднано до жодної групи.';

  @override
  String get community_scanOrCreate =>
      'Відскануйте QR-код або створіть спільноту, щоб почати';

  @override
  String get community_manageCommunities => 'Керувати спільнотами';

  @override
  String get community_delete => 'Покинути спільноту';

  @override
  String community_deleteConfirm(String name) {
    return 'Покинути «$name»?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'каналів',
      many: 'каналів',
      few: 'канали',
      one: 'канал',
    );
    return 'Це також видалить $count $_temp0 та їх повідомлення.';
  }

  @override
  String community_deleted(String name) {
    return 'Спільноту «$name» покинуто';
  }

  @override
  String get community_regenerateSecret => 'Перегенерувати секрет';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Перегенерувати секретний ключ для «$name»? Всі учасники повинні будуть відсканувати новий QR-код, щоб продовжити спілкування.';
  }

  @override
  String get community_regenerate => 'Перегенерувати';

  @override
  String community_secretRegenerated(String name) {
    return 'Секретний пароль для «$name» перегенеровано';
  }

  @override
  String get community_updateSecret => 'Оновити секрет';

  @override
  String community_secretUpdated(String name) {
    return 'Зміну секрету для «$name» оновлено';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Відскануйте новий QR-код, щоб оновити пароль для «$name»';
  }

  @override
  String get community_addHashtagChannel => 'Додати хештег спільноти';

  @override
  String get community_addHashtagChannelDesc =>
      'Додати канал хештегу для цієї спільноти';

  @override
  String get community_selectCommunity => 'Вибрати спільноту';

  @override
  String get community_regularHashtag => 'Звичайний хештег';

  @override
  String get community_regularHashtagDesc =>
      'Публічний хештег (будь-хто може приєднатися)';

  @override
  String get community_communityHashtag => 'Хештег спільноти';

  @override
  String get community_communityHashtagDesc =>
      'Ексклюзивно для членів спільноти';

  @override
  String community_forCommunity(String name) {
    return 'Для $name';
  }

  @override
  String get listFilter_tooltip => 'Фільтр та сортування';

  @override
  String get listFilter_sortBy => 'Сортувати за';

  @override
  String get listFilter_latestMessages => 'Останні повідомлення';

  @override
  String get listFilter_heardRecently => 'Нещодавно чули';

  @override
  String get listFilter_az => 'А-Я';

  @override
  String get listFilter_filters => 'Фільтри';

  @override
  String get listFilter_all => 'Все';

  @override
  String get listFilter_favorites => 'Улюблені';

  @override
  String get listFilter_addToFavorites => 'Додати до улюблених';

  @override
  String get listFilter_removeFromFavorites => 'Видалити зі списку улюблених';

  @override
  String get listFilter_users => 'Користувачі';

  @override
  String get listFilter_repeaters => 'Ретранслятори';

  @override
  String get listFilter_roomServers => 'Сервери кімнат';

  @override
  String get listFilter_unreadOnly => 'Тільки непрочитані повідомлення';

  @override
  String get listFilter_newGroup => 'Нова група';

  @override
  String get pathTrace_you => 'Ви';

  @override
  String get pathTrace_failed => 'Відстеження шляху не вдалося.';

  @override
  String get pathTrace_notAvailable => 'Трасування шляху недоступне.';

  @override
  String get pathTrace_refreshTooltip => 'Оновити Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Одне або більше хмелів відсутнє місце розташування!';

  @override
  String get pathTrace_clearTooltip => 'Очистити шлях';

  @override
  String get losSelectStartEnd =>
      'Виберіть початковий і кінцевий вузли для LOS.';

  @override
  String losRunFailed(String error) {
    return 'Помилка перевірки прямої видимості: $error';
  }

  @override
  String get losClearAllPoints => 'Очистити всі пункти';

  @override
  String get losRunToViewElevationProfile =>
      'Запустіть LOS, щоб переглянути профіль висоти';

  @override
  String get losMenuTitle => 'Меню LOS';

  @override
  String get losMenuSubtitle =>
      'Торкніться вузлів або утримуйте карту, щоб отримати власні точки';

  @override
  String get losShowDisplayNodes => 'Показати вузли відображення';

  @override
  String get losCustomPoints => 'Користувальницькі точки';

  @override
  String losCustomPointLabel(int index) {
    return 'Спеціальний $index';
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
  String get losRun => 'Запустіть LOS';

  @override
  String get losNoElevationData => 'Немає даних про висоту';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, чистий LOS, мінімальний зазор $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, заблоковано $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: перевірка...';

  @override
  String get losStatusNoData => 'LOS: немає даних';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total очищено, $blocked заблоковано, $unknown невідомо';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Дані про висоту недоступні для одного чи кількох зразків.';

  @override
  String get losErrorInvalidInput =>
      'Недійсні дані про точки/висоту для розрахунку LOS.';

  @override
  String get losRenameCustomPoint => 'Перейменуйте спеціальну точку';

  @override
  String get losPointName => 'Назва точки';

  @override
  String get losShowPanelTooltip => 'Показати панель LOS';

  @override
  String get losHidePanelTooltip => 'Приховати панель LOS';

  @override
  String get losElevationAttribution =>
      'Дані про висоту: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Радіогоризонт';

  @override
  String get losLegendLosBeam => 'Лінія прямої видимості';

  @override
  String get losLegendTerrain => 'Рельєф';

  @override
  String get losFrequencyLabel => 'Частота';

  @override
  String get losFrequencyInfoTooltip => 'Переглянути деталі розрахунку';

  @override
  String get losFrequencyDialogTitle => 'Розрахунок радіогоризонту';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Починаючи з k=$baselineK на $baselineFreq МГц, обчислення коригує k-фактор для поточного діапазону $frequencyMHz МГц, який визначає викривлену межу радіогоризонту.';
  }

  @override
  String get contacts_pathTrace => 'Трасування шляхів';

  @override
  String get contacts_ping => 'Пінгувати';

  @override
  String get contacts_repeaterPathTrace => 'Трасування шляху до повторювача';

  @override
  String get contacts_repeaterPing => 'Пінгувати повторювач';

  @override
  String get contacts_roomPathTrace => 'Трасування шляху до серверу кімнати';

  @override
  String get contacts_roomPing => 'Пінг сервера кімнати';

  @override
  String get contacts_chatTraceRoute => 'Трасування шляху';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Відстежити маршрут до $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Буфер обміну порожній';

  @override
  String get contacts_invalidAdvertFormat => 'Недійсні контактні дані';

  @override
  String get contacts_contactImported => 'Контакт було імпортовано.';

  @override
  String get contacts_contactImportFailed => 'Контакт не вдалося імпортувати';

  @override
  String get contacts_zeroHopAdvert => 'Реклама без перехоплення';

  @override
  String get contacts_floodAdvert => 'Залив реклами';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Копіювати оголошення в буфер обміну';

  @override
  String get contacts_addContactFromClipboard =>
      'Додати контакт з буфера обміну';

  @override
  String get contacts_ShareContact => 'Копіювати контакт у буфер обміну';

  @override
  String get contacts_ShareContactZeroHop =>
      'Поділитися контактом за оголошенням';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Відправлено контакт за оголошенням';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Не вдалося надіслати контакт.';

  @override
  String get contacts_contactAdvertCopied =>
      'Рекламу скопійовано до буфера обміну.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копіювання оголошення в буфер обміну завершилося невдало';

  @override
  String get notification_activityTitle => 'Активність MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'повідомлень',
      many: 'повідомлень',
      few: 'повідомлення',
      one: 'повідомлення',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'повідомлень каналу',
      many: 'повідомлень каналу',
      few: 'повідомлення каналу',
      one: 'повідомлення каналу',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'нових вузлів',
      many: 'нових вузлів',
      few: 'нових вузли',
      one: 'новий вузол',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Виявлено новий $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Отримано нове повідомлення';

  @override
  String get settings_gpxExportRepeaters =>
      'Експортувати ретранслятори / сервер кімнати до GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Експортує ретранслятори / сервер кімнати з місцезнаходженням у файл GPX.';

  @override
  String get settings_gpxExportContacts => 'Експортувати супутників до GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Експортує супутників з місцезнаходженням у файл GPX.';

  @override
  String get settings_gpxExportAll => 'Експортувати всі контакти до GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Експортує всі контакти з місцем розташування у файл GPX.';

  @override
  String get settings_gpxExportSuccess => 'Успішно експортовано файл GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Немає контактів для експорту.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Не підтримується на вашому пристрої/операційній системі';

  @override
  String get settings_gpxExportError => 'Сталася помилка під час експорту.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Місцезнаходження повторювача та сервера кімнати';

  @override
  String get settings_gpxExportChat => 'Місця супутників';

  @override
  String get settings_gpxExportAllContacts => 'Усі місця контактів';

  @override
  String get settings_gpxExportShareText =>
      'Дані карти експортовані з meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'експорт даних карти meshcore-open у форматі GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Ближні ретранслятори';

  @override
  String get snrIndicator_lastSeen => 'Останній раз бачили';

  @override
  String get contactsSettings_title => 'Налаштування контактів';

  @override
  String get contactsSettings_autoAddTitle => 'Автоматичне виявлення';

  @override
  String get contactsSettings_otherTitle =>
      'Інші налаштування, пов\'язані з контактами';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Автоматично додавати користувачів';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Дозволити супутникові автоматично додавати виявлених користувачів';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Автоматично додавати повторювачі';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Дозволити супутнику автоматично додавати виявлені ретранслятори';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Автоматично додавати сервери кімнат';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Дозволити супровіднику автоматично додавати виявлені сервери кімнат.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Автоматично додавати датчики';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Дозволити супровіднику автоматично додавати виявлені сенсори';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Перезаписати найстаріше';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Коли список контактів заповнений, найстарший контакт без позначки улюбленого буде замінений.';

  @override
  String get discoveredContacts_Title => 'Виявлені контакти';

  @override
  String get discoveredContacts_noMatching =>
      'Відповідних контактів не знайдено';

  @override
  String get discoveredContacts_searchHint => 'Знайти виявлені контакти';

  @override
  String get discoveredContacts_contactAdded => 'Контакт додано';

  @override
  String get discoveredContacts_addContact => 'Додати контакт';

  @override
  String get discoveredContacts_copyContact =>
      'Копіювати контакт у буфер обміну';

  @override
  String get discoveredContacts_deleteContact => 'Видалити контакт';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Видалити всі виявлені контакти';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Ви впевнені, що хочете видалити всі виявлені контакти?';
}
