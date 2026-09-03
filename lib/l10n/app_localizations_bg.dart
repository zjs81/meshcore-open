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
  String get common_done => 'Готово';

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
  String get common_disconnected => 'Прекъснато';

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
  String get common_hide => 'Скрий';

  @override
  String get common_remove => 'Изтрий';

  @override
  String get common_enable => 'Активирай';

  @override
  String get common_disable => 'Деактивирай';

  @override
  String get common_undo => 'Отмени';

  @override
  String get messageStatus_sent => 'Изпратено';

  @override
  String get messageStatus_delivered => 'Доставено';

  @override
  String get messageStatus_pending => 'Изпраща се';

  @override
  String get messageStatus_failed => 'Неуспешно изпращане';

  @override
  String get messageStatus_repeated => 'Повторно чуто';

  @override
  String get urlImage_enable => 'Enable URL images';

  @override
  String get urlImage_possible => 'Possible URL image; enable it in Settings.';

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
  String get common_autoRefresh => 'Автоматично обновяване';

  @override
  String get common_interval => 'Интервал';

  @override
  String get scanner_title => 'MeshCore – Отворена версия';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Свържете се чрез TCP';

  @override
  String get tcpHostLabel => 'IP адрес';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Пристанище';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Въведете крайната точка и свържете се.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Свързване към $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Необходим е IP адрес.';

  @override
  String get tcpErrorPortInvalid => 'Портът трябва да бъде между 1 и 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Транспортът чрез TCP не се поддържа на тази платформа.';

  @override
  String get tcpErrorTimedOut => 'Връзката TCP изтекла.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Неуспешно е установено TCP връзката: $error';
  }

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
      'Докоснете „Сканирай“, за да намерите устройства MeshCore.';

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
  String get scanner_bluetoothWebUnsupported =>
      'Функцията Bluetooth не е налична в браузъра. Моля, свържете се чрез USB вместо това.';

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
  String get settings_regionSettings => 'Региони';

  @override
  String get settings_regionSettingsSubtitle =>
      'Управляне на хранилищни региони';

  @override
  String get settings_regionManagement_screenTitle => 'Регионално управление';

  @override
  String get settings_regionNameHint => 'Възразна название на региона';

  @override
  String get settings_regionAddRegion => 'Добавете регион';

  @override
  String get settings_regionFetchRegions => 'Извън рептерите от региони';

  @override
  String get settings_regionFetchRegionsFail =>
      'Не бъде открити никако региони';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Тата регион е уже добавена';

  @override
  String get settings_regionName => 'Регионноименоване';

  @override
  String get settings_regionDeleted => 'Регион отстранен';

  @override
  String get settings_deleteRegion => 'Удаляне на регион';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Състрясна: отпиште \"$region\" от списка региони?';
  }

  @override
  String get settings_location => 'Местоположение';

  @override
  String get settings_locationSubtitle => 'GPS координати';

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
  String get settings_privacy => 'Настройки на поверителността';

  @override
  String get settings_privacySubtitle =>
      'Контролирайте каква информация се споделя.';

  @override
  String get settings_privacySettingsDescription =>
      'Изберете каква информация устройството ви споделя с другите.';

  @override
  String get settings_denyAll => 'Откажи всичко';

  @override
  String get settings_allowByContact => 'Позволи по флагове за контакт';

  @override
  String get settings_allowAll => 'Позволи всичко';

  @override
  String get settings_telemetryBaseMode => 'Базов режим на телеметрия';

  @override
  String get settings_telemetryLocationMode =>
      'Режим на местоположение на телеметрията';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Режим на средата на телеметрията';

  @override
  String get settings_advertLocation => 'Място на обявата';

  @override
  String get settings_advertLocationSubtitle =>
      'Включи местоположение в обявата';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Автоматична zero-hop обява при GPS обновяване';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Когато GPS местоположението се промени, изпрати zero-hop обява (изисква местоположение в обявата).';

  @override
  String get settings_multiAck => 'Множество ACK';

  @override
  String get settings_telemetryModeUpdated => 'Режим на телеметрията е обновен';

  @override
  String get settings_actions => 'Действия';

  @override
  String get settings_deleteAllPaths => 'Изтрий всички пътища';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Изчисти всички данни за пътищата от контактите.';

  @override
  String get settings_sendAdvertisement => 'Изпрати реклама';

  @override
  String get settings_sendAdvertisementSubtitle => 'Излъчи присъствието сега';

  @override
  String get settings_advertisementSent => 'Рекламата е изпратена';

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
  String get settings_rebootDevice => 'Рестартирай устройството';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Рестартирай устройството MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Сигурни ли сте, че искате да рестартирате устройството? Ще бъдете прекъснати.';

  @override
  String get settings_debug => 'Отстрани';

  @override
  String get settings_companionDebugLog =>
      'Дневник за отстраняване на грешки на придружаващото приложение';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Команди, отговори и сурови данни за протоколите BLE/TCP/USB';

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
    return 'MeshCore Open, версия $version';
  }

  @override
  String get settings_aboutLegalese => 'Проект MeshCore с отворен код 2024 г.';

  @override
  String get settings_aboutDescription =>
      'Отворен Flutter клиент за MeshCore LoRa мрежови устройства.';

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
  String get settings_infoPublicKey => 'Публичен ключ';

  @override
  String get settings_infoContactsCount => 'Брой контакти';

  @override
  String get settings_infoChannelCount => 'Брой канали';

  @override
  String get settings_infoHardware => 'Оборудование';

  @override
  String get settings_infoFirmware =>
      'Програмно-оборонни системни программи (фirmware)';

  @override
  String get settings_presets => 'Предварителни настройки';

  @override
  String get settings_frequency => 'Честота (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 – 2500,0';

  @override
  String get settings_frequencyInvalid => 'Невалидна честота (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Ширина на честотната лента';

  @override
  String get settings_spreadingFactor => 'Фактор на разпространение';

  @override
  String get settings_codingRate => 'Скорост на кодиране';

  @override
  String get settings_txPower => 'TX мощност (dBm)';

  @override
  String get settings_txPowerHelper => '0 - 22';

  @override
  String get settings_txPowerInvalid => 'Невалидна мощност на TX (0-22 dBm)';

  @override
  String get settings_clientRepeat => 'Клиентско повторение';

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
  String get appSettings_themeLight => 'Светла';

  @override
  String get appSettings_themeDark => 'Тъмна';

  @override
  String get appSettings_language => 'Език';

  @override
  String get appSettings_languageSystem => 'Система по подразбиране';

  @override
  String get appSettings_languageEn => 'Английски';

  @override
  String get appSettings_languageFr => 'Френски';

  @override
  String get appSettings_languageEs => 'Испански';

  @override
  String get appSettings_languageDe => 'Немски';

  @override
  String get appSettings_languagePl => 'Полски';

  @override
  String get appSettings_languageSl => 'Словенски';

  @override
  String get appSettings_languagePt => 'Португалски';

  @override
  String get appSettings_languageIt => 'Италиански';

  @override
  String get appSettings_languageZh => 'Китайски';

  @override
  String get appSettings_languageSv => 'Шведски';

  @override
  String get appSettings_languageNl => 'Нидерландски';

  @override
  String get appSettings_languageSk => 'Словашки';

  @override
  String get appSettings_languageBg => 'Български';

  @override
  String get appSettings_languageRu => 'Руски';

  @override
  String get appSettings_languageUk => 'Украински';

  @override
  String get repeater_pathHashModeOption0 => '0 - 1 байт';

  @override
  String get repeater_pathHashModeOption1 => '1 - 2 байта';

  @override
  String get repeater_pathHashModeOption2 => '2 - 3 байта';

  @override
  String get repeater_pathHashModeOption3 => '3 - 4 байта';

  @override
  String get appSettings_enableMessageTracing =>
      'Разрешаване на проследяване на съобщения';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показване на подробни метаданни за маршрутизация и синхронизация за съобщения';

  @override
  String get appSettings_notifications => 'Уведомления';

  @override
  String get appSettings_enableNotifications => 'Включи известията';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Получавайте известия за съобщения и реклами';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Отказвано е разрешение за известия';

  @override
  String get appSettings_notificationsEnabled => 'Известията са включени';

  @override
  String get appSettings_notificationsDisabled => 'Известията са изключени';

  @override
  String get appSettings_messageNotifications => 'Известия за съобщения';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Показвай известие при получаване на нови съобщения';

  @override
  String get appSettings_channelMessageNotifications =>
      'Известия за канални съобщения';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Показвай известие при получаване на съобщения от канали';

  @override
  String get appSettings_advertisementNotifications => 'Уведомления за реклами';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Покажи известие, когато бъдат открити нови възли.';

  @override
  String get appSettings_messaging => 'Съобщения';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Изчисти пътя при максимален брой опити';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Възстанови пътя към контакта след 5 неуспешни опита за изпращане';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Пътищата ще бъдат почистени след 5 неуспешни опита.';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Пътищата няма да бъдат автоматично изчистени.';

  @override
  String get appSettings_autoRouteRotation =>
      'Автоматична ротация на маршрутите';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Превключвайте между най-добрите пътища и режим на наводняване';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Автоматичната ротация на маршрутите е включена';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Автоматичната ротация на маршрутите е изключена';

  @override
  String get appSettings_maxRouteWeight =>
      'Максимално допустимо тегло на маршрута';

  @override
  String get appSettings_maxRouteWeightSubtitle =>
      'Максималното тегло, което един маршрут може да събере от успешни доставки.';

  @override
  String get appSettings_initialRouteWeight =>
      'Първоначална тежест на маршрута';

  @override
  String get appSettings_initialRouteWeightSubtitle =>
      'Начално тегло за новооткрити маршрути';

  @override
  String get appSettings_routeWeightSuccessIncrement =>
      'Увеличение на теглото за успех';

  @override
  String get appSettings_routeWeightSuccessIncrementSubtitle =>
      'Тегло, добавено към път след успешно доставяне.';

  @override
  String get appSettings_routeWeightFailureDecrement =>
      'Намаляване на теглото, свързано с неуспех';

  @override
  String get appSettings_routeWeightFailureDecrementSubtitle =>
      'Тегло, което е било премахнато от пътя след неуспешен опит за доставка.';

  @override
  String get appSettings_maxMessageRetries =>
      'Максимален брой опити за изпращане на съобщение';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Брой опити за повторно изпращане, преди съобщението да бъде маркирано като неуспешно.';

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
  String get appSettings_batteryLipoHv => 'LiPo ВЗГ (3,0-4,35 В)';

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
  String get appSettings_rasterTileSource => 'Източник на растерни плочки';

  @override
  String get appSettings_stadiaEndpoint => 'Крайна точка на Stadia';

  @override
  String get appSettings_stadiaApiKey => 'API ключ за Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Задължително за използване на Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Конфигурирано: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Въведете своя API ключ за Stadia Maps. Приложението го използва за заявки за растерни плочки.';

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
      'Дневник за отстраняване на грешки на приложението';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записвай съобщенията за отстраняване на грешки на приложението.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Дневникът за отстраняване на грешки на приложението е включен.';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Дневникът за отстраняване на грешки на приложението е изключен.';

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
  String get contacts_manageRepeater => 'Управление на повторителя';

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
  String get contacts_moreOptions => 'Повече възможности';

  @override
  String get contacts_searchOpen => 'Търсене на контакти';

  @override
  String get contacts_searchClose => 'Затвори търсене';

  @override
  String get contacts_groupName => 'Име на групата';

  @override
  String get contacts_groupNameRequired => 'Името на групата е задължително.';

  @override
  String get contacts_groupNameReserved => 'Това име на група е запазено';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Групата \"$name\" вече съществува.';
  }

  @override
  String get contacts_filterContacts => 'Филтрирай контактите...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Няма съвпадения с вашия филтър.';

  @override
  String get contacts_noMembers => 'Няма членове';

  @override
  String get contacts_lastSeenNow => 'Видян току-що';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Преди $minutes минути';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Преди час';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Преди $hours часа';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Преди 1 ден';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Преди $days дни';
  }

  @override
  String get contact_info => 'Контактна информация';

  @override
  String get contact_settings => 'Настройки за контакти';

  @override
  String get contact_telemetry => 'Телеметрия';

  @override
  String get contact_lastSeen => 'Последно видян';

  @override
  String get contact_clearChat => 'Изчисти чата';

  @override
  String get contact_teleBase => 'Базата данни за телеметрия';

  @override
  String get contact_teleBaseSubtitle =>
      'Позволи споделяне на ниво на батерията и основна телеметрия';

  @override
  String get contact_teleLoc => 'Местоположение на телеметрията';

  @override
  String get contact_teleLocSubtitle =>
      'Позволи споделяне на данни за местоположение';

  @override
  String get contact_teleEnv => 'Среда на телеметрия';

  @override
  String get contact_teleEnvSubtitle =>
      'Позволи споделяне на данни от средносферните датчици';

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
  String get channels_public => 'Публично';

  @override
  String channels_via(String path) {
    return 'чрез $path';
  }

  @override
  String get channels_private => 'Частен';

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
  String get channels_usePublicChannel => 'Използвай публичен канал';

  @override
  String get channels_standardPublicPsk => 'Стандартен публичен PSK';

  @override
  String get channels_pskHex => 'PSK (шестнадесетичен код)';

  @override
  String get channels_generateRandomPsk => 'Генерирай случайна PSK';

  @override
  String get channels_enterChannelName => 'Моля, въведете име на канал.';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK трябва да бъде 32 шестнадесетични знака.';

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
  String get channels_cyr2latCompression => 'Компресия Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Заменя някои кирилични символи с латиница при изпращане.';

  @override
  String get channels_cyr2latSettingsHeading => 'Настройки на Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Списък със замествания';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Редактиране на JSON конфигурацията за заместване на символи';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON карта за замествания';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'Неправилен JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Каналът \"$name\" е актуализиран';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Добавяне на профил Cyr2Lat';

  @override
  String get settings_cyr2latProfileName => 'Име на профила';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'Името на профила не може да бъде празно';

  @override
  String get settings_cyr2latProfileAdded => 'Профилът е добавен успешно';

  @override
  String get settings_cyr2latProfileUpdated =>
      'Профилът е актуализиран успешно';

  @override
  String get settings_cyr2latProfileEdit => 'Редактиране на Cyr2Lat профил';

  @override
  String get settings_cyr2latProfileDelete => 'Изтриване на профил Cyr2Lat';

  @override
  String get settings_cyr2latProfileDeleted => 'Профилът беше изтрит успешно';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Сигурен ли сте, че искате да изтриете профила \"$name\"?';
  }

  @override
  String get channels_publicChannelAdded => 'Публичен канал добавен';

  @override
  String get channels_sortBy => 'Сортирай по';

  @override
  String get channels_sortManual => 'Ръчно';

  @override
  String get channels_sortAZ => 'От А до Я';

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
  String channels_regionSetTo(String region) {
    return 'Регион: $region';
  }

  @override
  String get channels_regionNotSet => 'Регион: ние';

  @override
  String get channels_regionSelect_Title => 'Выберете регион';

  @override
  String get channels_clearRegion => 'Чиста зона';

  @override
  String get chat_noMessages => 'Няма съобщения.';

  @override
  String get chat_sendMessage => 'Изпратете съобщение';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Изпрати съобщение на $contactName';
  }

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
  String get chat_selectSendAction => 'Изберете действие за изпращане';

  @override
  String get chat_sendGif => 'Изпрати GIF';

  @override
  String get chat_sendImageLora => 'Изпращане на изображение чрез MeshCore';

  @override
  String get chat_imagePickFailed => 'Не мог да откривам та изображин';

  @override
  String get chat_receivedGif => 'Получил GIF';

  @override
  String get chat_reply => 'Отговори';

  @override
  String get chat_addReaction => 'Добави Реакция';

  @override
  String get chat_me => 'Аз';

  @override
  String get reaction_report => 'Emoji Reactions';

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
  String get debugLog_rawLogRx => 'Необработен лог-RX';

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
  String get debugFrame_textTypeCli => 'Команден ред (CLI)';

  @override
  String get debugFrame_textTypePlain => 'Просто';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Хексадесетичен Dump:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'скока',
      one: 'скок',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Премахни пътя';

  @override
  String get chat_noPathHistoryYet =>
      'Няма история на пътищата още.\nИзпратете съобщение, за да откриете пътища.';

  @override
  String get chat_pathCleared =>
      'Пътят е почистен. Следващото съобщение ще открие маршрута отново.';

  @override
  String get chat_fullPath => 'Пълен път';

  @override
  String get routing_title => 'Маршрутизиране';

  @override
  String get routing_modeAuto => 'Автоматично';

  @override
  String get routing_modeFlood => 'Наводняване';

  @override
  String get routing_modeManual => 'Ръчно';

  @override
  String get routing_modeAutoHint =>
      'Автоматично избира най-добрия известен път, а при липса на информация използва стратегия за наводняване.';

  @override
  String get routing_modeFloodHint =>
      'Излъчва през всички повторители. Най-надеждният начин, но изисква повече време в ефира.';

  @override
  String get routing_modeManualHint =>
      'Винаги следва точно пътя, който сте определили.';

  @override
  String get routing_currentRoute => 'Текущ маршрут';

  @override
  String get routing_directNoHops => 'Директно - без скокове';

  @override
  String get routing_noPathYet =>
      'Все още няма път. Съобщението продължава да се изпраща, докато не бъде открит маршрут.';

  @override
  String get routing_floodBroadcast => 'Предаване през всички повторители';

  @override
  String get routing_editPath => 'Редактирай пътя';

  @override
  String get routing_forgetPath => 'Забрави пътя';

  @override
  String get routing_knownPaths => 'Известни пътища';

  @override
  String get routing_knownPathsHint =>
      'Докоснете бутона, за да превключите към него.';

  @override
  String get routing_inUse => 'В употреба';

  @override
  String get routing_qualityStrong => 'Силен първи скок';

  @override
  String get routing_qualityGood => 'Добър първи опит';

  @override
  String get routing_qualityFair => 'Приемлив първи скок';

  @override
  String get routing_qualityWorked => 'Работил';

  @override
  String get routing_qualityFlood => 'Получено чрез наводняване';

  @override
  String get routing_qualityUntested => 'Нетестирано';

  @override
  String routing_lastWorked(String when) {
    return 'последно работил $when';
  }

  @override
  String get routing_neverWorked => 'Никога не е потвърдено';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes доставени, $failures неуспешни';
  }

  @override
  String get routing_floodDelivery => 'Доставка при наводняване';

  @override
  String get pathEditor_title => 'Създаване на път';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count от 64 скока';
  }

  @override
  String get pathEditor_noHops =>
      'Все още няма добавени скокове. Можете да използвате бутоните по-долу, за да ги добавите по ред, или да запазите пътя без скокове, за да го изпратите директно.';

  @override
  String get pathEditor_addHops => 'Добавете скоковете в посочения ред.';

  @override
  String get pathEditor_searchRepeaters => 'Търсене на повторители';

  @override
  String get pathEditor_advancedHex => 'Разширено: суров шестнадесетичен път';

  @override
  String get pathEditor_hexLabel => 'Шестнадесетични префикси';

  @override
  String get pathEditor_hexHelper =>
      'Два шестнадесетични идентификатора на скок, разделени със запетаи';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Невалидни: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Максимум 64 скока';

  @override
  String get pathEditor_usePath => 'Използвай този маршрут.';

  @override
  String get pathEditor_removeHop => 'Премахни скока';

  @override
  String get pathEditor_unknownHop => 'Неизвестен повторител';

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
  String get chat_path => 'Път';

  @override
  String get chat_publicKey => 'Публичен ключ';

  @override
  String get chat_compressOutgoingMessages =>
      'Компресиране на изходящи съобщения';

  @override
  String get chat_floodForced => 'Наводняване (принудително)';

  @override
  String get chat_directForced => 'Директно (принудително)';

  @override
  String chat_hopsForced(int count) {
    return '$count скока (принудително)';
  }

  @override
  String get chat_floodAuto => 'Наводняване (автоматично)';

  @override
  String get chat_direct => 'Директно';

  @override
  String get chat_poiShared => 'Споделена точка на интерес';

  @override
  String chat_unread(int count) {
    return 'Непрочетени: $count';
  }

  @override
  String get chat_markAsUnread => 'Отбелязване като непрочетено';

  @override
  String get chat_newMessages => 'Нови съобщения';

  @override
  String get chat_openLink => 'Отворете връзката?';

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
  String get map_searchHint => 'Търсене по име или идентификатор на възел';

  @override
  String get map_activity => 'Дейност';

  @override
  String get map_online => 'Онлайн';

  @override
  String get map_recent => 'Скорошни';

  @override
  String get map_stale => 'Остарял';

  @override
  String get map_visible => 'Видими';

  @override
  String get map_hidden => 'Скрит';

  @override
  String get map_centerOnNode => 'Центрирай върху възела';

  @override
  String get map_details => 'Подробности';

  @override
  String get map_noGps => 'Без GPS';

  @override
  String get map_noResults => 'Няма съвпадащи възли';

  @override
  String get map_lineOfSight => 'Линия на видимост';

  @override
  String get map_losScreenTitle => 'Линия на видимост';

  @override
  String get map_noNodesWithLocation => 'Няма възли с данни за местоположение.';

  @override
  String get map_nodesNeedGps =>
      'Възлите трябва да споделят GPS координатите си,\nза да се появят на картата.';

  @override
  String map_nodesCount(int count) {
    return 'Възли: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Пинове: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Повторител';

  @override
  String get map_room => 'Стая';

  @override
  String get map_sensor => 'Сензор';

  @override
  String get map_pinDm => 'Пин (DM)';

  @override
  String get map_pinPrivate => 'Пин (личен)';

  @override
  String get map_pinPublic => 'Публичен пин';

  @override
  String get map_lastSeen => 'Последно видян';

  @override
  String get map_disconnectConfirm =>
      'Сигурни ли сте, че искате да прекъснете връзката с това устройство?';

  @override
  String get map_from => 'От';

  @override
  String get map_source => 'Източник';

  @override
  String get map_flags => 'Флагове';

  @override
  String get map_type => 'Тип';

  @override
  String get map_path => 'Път';

  @override
  String get map_location => 'Местоположение';

  @override
  String get map_estLocation => 'Прибл. местоположение';

  @override
  String get map_publicKey => 'Публичен ключ';

  @override
  String get map_publicKeyPrefixHint => 'напр. ab12';

  @override
  String get map_shareMarkerHere => 'Споделете маркер тук';

  @override
  String get map_setAsMyLocation => 'Задайте като моя местоположение';

  @override
  String get map_pinLabel => 'Етикет на пина';

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
  String get map_publicLocationShare => 'Споделяне на публично местоположение';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Ще споделите местоположение в $channelLabel. Този канал е публичен и всеки с PSK може да го види.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Свържете се с устройство, за да споделяте маркери.';

  @override
  String get map_filterNodes => 'Филтрирай възлите';

  @override
  String get map_nodeTypes => 'Типове възли';

  @override
  String get map_chatNodes => 'Възли на чата';

  @override
  String get map_repeaters => 'Повторители';

  @override
  String get map_otherNodes => 'Други възли';

  @override
  String get map_showOverlaps => 'Покриване на ключа на повтаряча';

  @override
  String get map_keyPrefix => 'Префикс на ключа';

  @override
  String get map_filterByKeyPrefix => 'Филтрирайте по префикс на ключ';

  @override
  String get map_publicKeyPrefix => 'Префикс на публичния ключ';

  @override
  String get map_markers => 'Маркери';

  @override
  String get map_showSharedMarkers => 'Показвай споделените маркери';

  @override
  String get map_showGuessedLocations =>
      'Покажете местоположенията на предположените възли.';

  @override
  String get map_showDiscoveryContacts => 'Покажи контакти за откриване';

  @override
  String get map_guessedLocation => 'Предполагано местоположение';

  @override
  String get map_lastSeenTime => 'Последно видян';

  @override
  String get map_sharedPin => 'Споделен пин';

  @override
  String get map_sharedAt => 'Споделено';

  @override
  String get map_joinRoom => 'Присъедини се към стаята';

  @override
  String get map_manageRepeater => 'Управление на повторителя';

  @override
  String get map_tapToAdd => 'Докоснете възлите, за да ги добавите към пътя.';

  @override
  String get map_runTrace => 'Стартирай проследяването на пътя';

  @override
  String get map_runTraceWithReturnPath => 'Върни се по същия път.';

  @override
  String get map_removeLast => 'Премахни последното';

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
  String get mapCache_downloadTilesButton => 'Изтегли плочките';

  @override
  String get mapCache_clearCacheButton => 'Изчисти кеша';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Неуспешни изтегляния: $count';
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
    return 'Север $north, Юг $south, Изток $east, Запад $west';
  }

  @override
  String get time_justNow => 'Току-що';

  @override
  String time_minutesAgo(int minutes) {
    return 'Преди $minutes минути';
  }

  @override
  String time_hoursAgo(int hours) {
    return 'Преди $hours часа';
  }

  @override
  String time_daysAgo(int days) {
    return 'Преди $days дни';
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
  String get time_weeks => 'седмици';

  @override
  String get time_month => 'месец';

  @override
  String get time_months => 'месеци';

  @override
  String get time_minutes => 'минути';

  @override
  String get time_allTime => 'За цялото време';

  @override
  String get dialog_disconnect => 'Прекъсни';

  @override
  String get dialog_disconnectConfirm =>
      'Сигурни ли сте, че искате да прекъснете връзката с това устройство?';

  @override
  String get login_repeaterLogin => 'Вход за повторител';

  @override
  String get login_roomLogin => 'Вход в стаята';

  @override
  String get login_password => 'Парола';

  @override
  String get login_enterPassword => 'Въведете парола';

  @override
  String get login_savePassword => 'Запази паролата';

  @override
  String get login_savePasswordSubtitle =>
      'Паролата ще бъде съхранена сигурно на това устройство.';

  @override
  String get login_repeaterDescription =>
      'Въведете паролата на повторителя, за да получите достъп до настройките и статуса.';

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
  String get login_managePaths => 'Управление на пътищата';

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
  String get path_currentPathLabel => 'Текущ път';

  @override
  String get path_noRepeatersFound =>
      'Няма намерени репетитори или сървъри на стаи.';

  @override
  String get repeater_management => 'Управление на повторители';

  @override
  String get room_management => 'Управление на сървъра за стая';

  @override
  String get repeater_guest => 'Информация за ретранслаторите';

  @override
  String get room_guest => 'Информация за сървъра на стаята';

  @override
  String get repeater_managementTools => 'Инструменти за управление';

  @override
  String get repeater_guestTools => 'Инструменти за гости';

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
  String get repeater_cli => 'Команден ред (CLI)';

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
      'Конфигурирайте параметрите на повторителя';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Синхронизиране на часовника след влизане';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Автоматично изпращайте съобщение \"синхронизиране на часовника\" след успешно влизане.';

  @override
  String get repeater_statusTitle => 'Статус на повтарянето';

  @override
  String get repeater_routingMode => 'Режим на маршрутизиране';

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
  String get repeater_txAirtime => 'TX време в ефир';

  @override
  String get repeater_rxAirtime => 'RX време в ефир';

  @override
  String get repeater_chanUtil => 'Използване на канала';

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
      'Показване на името на този повторител';

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
  String get repeater_txPower => 'TX мощност';

  @override
  String get repeater_txPowerHelper => '1-30 dBm';

  @override
  String get repeater_bandwidth => 'Ширина на честотния спектър';

  @override
  String get repeater_spreadingFactor => 'Фактор на разпространение';

  @override
  String get repeater_codingRate => 'Скорост на кодиране';

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
      'Активирайте повторителя, за да препраща пакети.';

  @override
  String get repeater_guestAccess => 'Достъп за гости';

  @override
  String get repeater_guestAccessSubtitle => 'Разрешете само четене за гости';

  @override
  String get repeater_privacyMode => 'Режим на поверителност';

  @override
  String get repeater_privacyModeSubtitle =>
      'Скриване на име/местоположение в рекламите';

  @override
  String get repeater_advertisementSettings => 'Настройки на рекламите';

  @override
  String get repeater_localAdvertInterval => 'Интервал на местната реклама';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes минути';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Интервал на рекламата за наводняване';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours часа';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Криптиран интервал на рекламата';

  @override
  String get repeater_dangerZone => 'Опасна зона';

  @override
  String get repeater_rebootRepeater => 'Рестартирай повторителя';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Рестартира повторителя.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Сигурни ли сте, че искате да рестартирате този повторител?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Генерирай нов идентификационен ключ';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Генерирай нова двойка публичен/частен ключ';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Това ще генерира нова идентичност за повторителя. Продължете?';

  @override
  String get repeater_eraseFileSystem => 'Изтрий файловата система';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Форматирай файловата система на повторителя';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ВНИМАНИЕ: Това ще изтрие всички данни от повторителя. Това не може да бъде отменено!';

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
  String get repeater_confirm => 'Потвърди';

  @override
  String get repeater_settingsSaved => 'Настройките са запазени успешно.';

  @override
  String get repeater_rxGain => 'RX усилване';

  @override
  String get repeater_rxGainHelper =>
      'По-висока чувствителност, по-голям ток (само за SX1262/SX1268)';

  @override
  String get repeater_refreshRxGain => 'Обнови RX усилването';

  @override
  String get repeater_multiAcks => 'Множество потвърждения';

  @override
  String get repeater_multiAcksSubtitle =>
      'Потвърждавай съобщенията по множество канали за по-добро доставяне.';

  @override
  String get repeater_refreshMultiAcks => 'Обнови множествените ACK';

  @override
  String get repeater_networkHealth => 'Състояние на мрежата';

  @override
  String get repeater_loopDetect => 'Откриване на цикли';

  @override
  String get repeater_loopDetectHelper =>
      'Изпратете пакети, които изглеждат като цикли в маршрутизацията.';

  @override
  String get repeater_loopDetectOff => 'Изключено';

  @override
  String get repeater_loopDetectMinimal => 'Минимален';

  @override
  String get repeater_loopDetectModerate => 'Умерен';

  @override
  String get repeater_loopDetectStrict => 'Строг';

  @override
  String get repeater_dutyCycle => 'Работен цикъл';

  @override
  String get repeater_dutyCycleHelper =>
      'Максимален процент на използване на времето в ефир';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Информация за оператора';

  @override
  String get repeater_ownerInfoHelper =>
      'Публични метаданни за този повторител';

  @override
  String get repeater_refreshOwnerInfo => 'Обновете информацията за оператора';

  @override
  String get repeater_floodMax => 'Максимален брой хопове при наводняване';

  @override
  String get repeater_floodMaxHelper =>
      'Максималният брой хопове, които един пакет може да премине (0-64)';

  @override
  String get repeater_advancedSettings => 'Разширени настройки';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Експериментални настройки за опитни оператори';

  @override
  String get repeater_pathHashMode => 'Режим за хеширане на пътища';

  @override
  String get repeater_pathHashModeHelper =>
      'Байтовете, използвани за кодиране на идентификатора на този повторител в таговете за откриване на потоци/цикли, са: 0=1 байт (256 идентификатора, до 64 скока), 1=2 байта (65 000 идентификатора, до 32 скока), 2=3 байта (16 милиона идентификатора, до 21 скока). Версиите 1.13 и по-старите фърмуери използват многобайтови пътища - само след като мрежата е актуализирана до версия 1.14 или по-нова.';

  @override
  String get repeater_keySettings => 'Изменяне на идентичности ключа';

  @override
  String get repeater_keySettingsSubtitle =>
      'Замени ключовият пар от публични/частни';

  @override
  String get repeater_prvKey => 'Частни ключ';

  @override
  String get repeater_prvKeyHelper =>
      'Нова приватна ключ на повторчето, 128-символовна шестнадатерична строка.';

  @override
  String get repeater_generatePrvKey => 'Генериране на случайна ключи';

  @override
  String get repeater_stopGeneratingPrvKey =>
      'Прервана поискна на ключова парта';

  @override
  String get repeater_pubKey => 'Публична ключ';

  @override
  String get repeater_pubKeyHelper =>
      'Та е публичната ключ, която се свързува с генериранта приватна ключ. Трябва да не настройте тоа напрямо.';

  @override
  String get repeater_pubKeyPrefix => 'Желата префикс';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Наискате публична ключ, който почева с този шестнадатницил. Ожидавани проби: $tries.';
  }

  @override
  String get repeater_txDelay => 'Забавяне на Flood TX';

  @override
  String get repeater_txDelayHelper =>
      'Разстоянието между пакетите при наводняване като множител на времето за пренос на пакета (0-2, по подразбиране 0.5). По-висока стойност означава по-малко сблъсъци, но по-бавно предаване.';

  @override
  String get repeater_directTxDelay => 'Забавяне на директното предаване';

  @override
  String get repeater_directTxDelayHelper =>
      'Интервал за директен (не-масов) трафик, като множител на времето за пренос на пакета (0-2, по подразбиране 0.3).';

  @override
  String get repeater_intThresh => 'Праг на смущенията';

  @override
  String get repeater_intThreshHelper =>
      'Прагът е зададен на нивото на шума на радиото, така че да отхвърля смущения, които са над този праг. 0 – изключва; активирайте само, ако забележите грешки в шумна честотна лента.';

  @override
  String get repeater_agcResetInterval => 'Интервал за нулиране на AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Колко често да се рестартира автоматичната настройка на усилването, за да се възстанови от състояние, в което усилването е блокирано. Времето за рестартиране е няколко секунди, като се определя като кратна на 4. 0 деактивира периодичното рестартиране.';

  @override
  String get repeater_actionsTitle => 'Действия';

  @override
  String get repeater_sendAdvert => 'Изпрати реклама за наводняване';

  @override
  String get repeater_sendAdvertSubtitle =>
      'Публикувай реклама за наводняване в мрежата.';

  @override
  String get repeater_sendAdvertZeroHop => 'Изпрати реклама без хопове';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Публикувай реклама, която достига до целевата аудитория само чрез директно разпространение.';

  @override
  String get repeater_clockSync => 'Синхронизирай часовника сега';

  @override
  String get repeater_clockSyncSubtitle =>
      'Настройте времето на телефона си да съвпада с времето на повторителя.';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action успешно';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action не успя: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Настройките са запазени - рестартирайте повторителя, за да ги приложите.';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Някои настройки не успяха: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Грешка при запазване на настройките: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Обнови основните настройки';

  @override
  String get repeater_refreshRadioSettings => 'Обнови настройките на радиото';

  @override
  String get repeater_refreshTxPower => 'Обнови TX мощността';

  @override
  String get repeater_refreshPacketForwarding =>
      'Обнови препращането на пакети';

  @override
  String get repeater_refreshGuestAccess => 'Обнови достъпа за гости';

  @override
  String get repeater_refreshPrivacyMode => 'Обнови режима на поверителност';

  @override
  String repeater_refreshed(String label) {
    return '$label е обновено';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Грешка при обновяване на $label';
  }

  @override
  String get repeater_cliTitle => 'CLI на повторителя';

  @override
  String get repeater_debugNextCommand => 'Отстрани следващата команда';

  @override
  String get repeater_commandHelp => 'Помощ';

  @override
  String get repeater_clearHistory => 'Изчисти историята';

  @override
  String get repeater_noCommandsSent => 'Няма изпратени команди засега.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Въведете команда по-долу или използвайте бързи команди';

  @override
  String get repeater_enterCommandHint => 'Въведете команда...';

  @override
  String get repeater_previousCommand => 'Предишна команда';

  @override
  String get repeater_nextCommand => 'Следваща команда';

  @override
  String get repeater_enterCommandFirst => 'Въведете първо команда.';

  @override
  String get repeater_cliCommandFrameTitle => 'Рамка на CLI команда';

  @override
  String repeater_cliCommandError(String error) {
    return 'Грешка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Вземи име';

  @override
  String get repeater_cliQuickGetRadio => 'Вземи радио';

  @override
  String get repeater_cliQuickGetTx => 'Вземи TX';

  @override
  String get repeater_cliQuickNeighbors => 'Съседи';

  @override
  String get repeater_cliQuickVersion => 'Версия';

  @override
  String get repeater_cliQuickAdvertise => 'Рекламирай';

  @override
  String get repeater_cliQuickClock => 'Часовник';

  @override
  String get repeater_cliQuickClockSync => 'Синхронизация на часовника';

  @override
  String get repeater_cliQuickDiscovery => 'Открий Съседи';

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
      'Получава типа на моста: none, rs232, espnow';

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
      'Задава разрешение \'Flood\' за посочената област. (\'\' за глобалния/стария обхват)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Премахва разрешението \"F\" за посочената област. (ЗАБЕЛЕЖКА: в момента не се препоръчва да се използва на глобално/старо ниво!!)';

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
  String get repeater_getCategory => 'Получете стойности';

  @override
  String get repeater_powerMgmt => 'Управление на енергията';

  @override
  String get repeater_sensors => 'Датчици';

  @override
  String get repeater_cliHelpPowerOff =>
      'Изключва устройството. (не се очаква отговор)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Възстановява часовника до известна историческа дата и рестартира устройството.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Изпраща реклама, която достига само до съседни устройства (само до съседни мрежи).';

  @override
  String get repeater_cliHelpStartOta =>
      'Стартира актуализация на фърмуера чрез въздушното, на всички поддържани платки.';

  @override
  String get repeater_cliHelpTime =>
      'Задава времето на устройството към зададените секунди от началото на Unix ерата. Времето не може да се върне назад.';

  @override
  String get repeater_cliHelpBoard =>
      'Показва производителя на платката / идентификатора на хардуера.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Изпраща заявка за откриване на съседни възли. (Само за устройства тип репитер)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Показва дали режимът за пестене на енергия е активиран или деактивиран.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Активира или деактивира режима за пестене на енергия (ако е поддържан).';

  @override
  String get repeater_cliHelpErase =>
      '(Само за серийни устройства) Форматира файловата система на устройството. Изтрива всички настройки и контакти.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Задава максимално допустимия процент на използване на времето за предаване (от 1 до 100 процента). Вътрешно коригира фактора за времето на предаване.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      '(Само за серийни номера) Заменя личната част от ключа за идентификация на устройството. Необходимо е да се рестартира устройството, за да се приложи. Генерира нов публичен ключ.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(Само за SX126x) Превключва усиления на приемния сигнал (RX gain) за подобрена чувствителност при по-високо потребление на ток.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Задава низовете с информация за контакт на собственика, които са включени в рекламите. Използвайте \'|\' за нови редове.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Задава режима за хеширане на пътищата. 0 = за стари системи, 1 = за стандартни системи, 2 = за строги системи. Влияе върху начина, по който се съпоставят маршрутите.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Задава чувствителността за откриване на цикли в маршрутизацията: изключена, минимална, умерена или строга.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(Само за серийно управление) Бързо задава само честотата. Необходимо е рестартиране. Препоръчително е да се използват настройките за \"радио\", за да се зададат всички параметри.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(Само за моста ESPNow) Определя WiFi канала (от 1 до 14), използван от моста.';

  @override
  String get repeater_cliHelpGetName => 'Показва зададеното име на възела.';

  @override
  String get repeater_cliHelpGetRole =>
      'Показва ролята на фърмуера (например повторител, сървър на стая и т.н.).';

  @override
  String get repeater_cliHelpGetPublicKey =>
      'Показва публичния ключ на устройството.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(Само за серийния номер) Показва личната ключа на устройството. Трябва да се третира като тайна.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Показва дали функцията за пренасочване на пакети (ролята на повторителя) е активирана или деактивирана.';

  @override
  String get repeater_cliHelpGetTx => 'Показва текущата мощност на TX в dBm.';

  @override
  String get repeater_cliHelpGetFreq => 'Показва зададената честота в MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Показва пълните радио параметри: честота, ширина на честотния обхват, фактор на разпространение, скорост на кодиране.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(Само за SX126x) Показва състоянието на усиления сигнал на RX.';

  @override
  String get repeater_cliHelpGetAf =>
      'Показва текущия коефициент на въздействие върху въздуха.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Показва текущия допустим цикъл на работа като процент.';

  @override
  String get repeater_cliHelpGetIntThresh =>
      'Показва прага на интерференцията на канала в децибели (dB).';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Показва интервала за рестартиране на AGC в секунди.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Показва дали режимът \"двоен ACK\" е активиран (1) или деактивиран (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Показва дали е разрешено само четене за гостите.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Показва времето на рекламата в минути.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Показва интервала на рекламата за навод в часове.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Показва зададения парол за гост.';

  @override
  String get repeater_cliHelpGetLat => 'Показва зададената географска ширина.';

  @override
  String get repeater_cliHelpGetLon => 'Показва зададената дължина.';

  @override
  String get repeater_cliHelpGetRxDelay =>
      'Показва основната стойност на забавянето на сигнала.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Показва коефициента за забавяне при режим на наводняване.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Показва коефициента за забавяне при директен режим.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Показва максималния брой на повторни наводнения.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Показва информацията за контакт на собственика.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Показва режима на хеширане на пътя (0/1/2).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Показва чувствителността към откриване на цикли.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(Само за серийни устройства) Изброява настройките за контрол на достъпа в повторителя.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Показва дали мостът е активиран.';

  @override
  String get repeater_cliHelpGetBridgeDelay =>
      'Показва забавянето на моста в милисекунди.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Показва дали мостът изпраща или получава пакети RX или TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(Само за мост RS232) Показва скоростта на предаване на данните на моста.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(Само за моста ESPNow) Показва канала на WiFi на моста.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(Само за моста ESPNow) Показва споделения секрет на моста.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(Само за NRF52) Показва версията на зареждащия софтуер.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Показва множителя на аналоговия-цифров преобразувател (мащабиране на напрежението от батерията).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Описва дали борда на директорите има поддръжка за управление на захранването.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Показва текущия източник на захранване: външен или батерия.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Показва най-скорошните причини за рестартиране и изключване.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Показва напрежението на батерията при стартиране, измерено в миливолта (mV).';

  @override
  String get repeater_cliHelpSensorGet =>
      'Чете персонализирана настройка на сензор чрез клавиш.';

  @override
  String get repeater_cliHelpSensorSet =>
      'Създава персонализирана настройка за сензор.';

  @override
  String get repeater_cliHelpSensorList =>
      'Показва всички настройки на потребителските сензори, разделени на страници, започвайки от опционален индекс.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Показва текущия обхват на региона по подразбиране.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Задава обхвата на региона по подразбиране. Използвайте \"<null>\", за да го изчистите.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Списва регионите, които позволяват преминаване на превозни средства при наводнение.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Списва региони, които забраняват движението по пътищата при наводнения.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(Само за серия) Показва статистически данни на ниво пакет.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(Само за конкретен сериал) Показва радиостатистика.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(Само за серийния номер) Показва основните статистически данни за фърмуера.';

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
  String get telemetry_digitalInputLabel => 'Цифров вход';

  @override
  String get telemetry_digitalOutputLabel => 'Цифров изход';

  @override
  String get telemetry_analogInputLabel => 'Аналогов вход';

  @override
  String get telemetry_analogOutputLabel => 'Аналогов изход';

  @override
  String get telemetry_genericLabel => 'Общ сензор';

  @override
  String get telemetry_luminosityLabel => 'Осветеност';

  @override
  String get telemetry_presenceLabel => 'Присъствие';

  @override
  String get telemetry_humidityLabel => 'Влажност';

  @override
  String get telemetry_accelerometerLabel => 'Акселерометър';

  @override
  String get telemetry_pressureLabel => 'Налягане';

  @override
  String get telemetry_altitudeLabel => 'Надморска височина';

  @override
  String get telemetry_frequencyLabel => 'Честота';

  @override
  String get telemetry_percentageLabel => 'Процент';

  @override
  String get telemetry_concentrationLabel => 'Концентрация';

  @override
  String get telemetry_powerLabel => 'Мощност';

  @override
  String get telemetry_distanceLabel => 'Разстояние';

  @override
  String get telemetry_energyLabel => 'Енергия';

  @override
  String get telemetry_directionLabel => 'Посока';

  @override
  String get telemetry_timeLabel => 'Време';

  @override
  String get telemetry_gyrometerLabel => 'Жироскоп';

  @override
  String get telemetry_colourLabel => 'Цвят';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Превключвател';

  @override
  String get telemetry_polylineLabel => 'Полилиния';

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
  String get telemetry_autoFetchQuantity => 'Брой заявки';

  @override
  String get telemetry_error => 'Неуспешно получаване на данни';

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
  String get channelPath_pathLabelTitle => 'Пътеки';

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
  String get listFilter_az => 'А-Я';

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
  String get pathTrace_refreshTooltip => 'Обнови проследяването на пътя.';

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
  String get losBlockedSpotsTitle => 'Ограничени места';

  @override
  String get losBlockedSpotsHint =>
      'Кликнете върху блокираната точка, за да я отбележите на картата.';

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
  String get losSelectedObstructionTitle => 'Избрано препятствие';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Блокирано от $obstruction $heightUnit, $distanceFromA от A и $distanceFromB от B ($distanceUnit).';
  }

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
  String get contacts_floodAdvert => 'Реклама за наводняване';

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
  String get snrIndicator_nearByRepeaters => 'Близки повторители';

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

  @override
  String get chat_sendCooldown =>
      'Моля, изчакайте малко, преди да изпратите отново.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Преминете към най-старата непочетена статия';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Когато отворите чат с непрочетени съобщения, плъзнете надолу, за да видите първото непрочетено съобщение, вместо най-новото.';

  @override
  String get appSettings_languageHu => 'Унгарски';

  @override
  String get appSettings_languageJa => 'Японски';

  @override
  String get appSettings_languageKo => 'Корейски';

  @override
  String get radioStats_tooltip => 'Статистика за радио и мрежа';

  @override
  String get radioStats_screenTitle =>
      'Статистически данни за радиопредаванията';

  @override
  String get radioStats_notConnected =>
      'Свържете се с устройство, за да видите статистически данни за радиопредаване.';

  @override
  String get radioStats_firmwareTooOld =>
      'Статистиката на радиостанцията изисква съвместимо софтуерно решение версия 8 или по-нова.';

  @override
  String get radioStats_waiting => 'Изчакване на данни…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Ниво на шума: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Последен RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Последна стойност на SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Време на въздух (общо): $seconds секунди';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Общо време на използване на RX (в секунди): $seconds с';
  }

  @override
  String get radioStats_chartCaption =>
      'Ниво на шума (dBm) за последните измервания.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Ниво на шума: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Извличане на данни за радиото…';

  @override
  String get radioStats_settingsTile => 'Статистически данни за радиостанции';

  @override
  String get radioStats_settingsSubtitle =>
      'Ниво на шума, RSSI, SNR и време на пренос';

  @override
  String get translation_title => 'Превод';

  @override
  String get imageMessages_enableTitle => 'Абilitiraм изображените сообщения';

  @override
  String get imageMessages_enableSubtitle =>
      'Изправате изображения чрез сетката. Треба е одноразовна загрузка модел на изображение.';

  @override
  String get imageMessages_modelSectionTitle => 'Изображени модель';

  @override
  String get imageMessages_downloadModel => 'Скачане';

  @override
  String get imageMessages_cancelDownload => 'Отмена';

  @override
  String get imageMessages_removeModel => 'Удалете модель';

  @override
  String get imageMessages_modelReady => 'Готов';

  @override
  String get imageMessages_modelNotPublished =>
      'Еще не опубликовано — тази версия не може да скане.';

  @override
  String get imageMessages_downloadFailed =>
      'Модел за изображение не може да бъде скачан.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Автоматически обрабатвате изображения';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Катализиране на всята изображение сразу по пришествие. Използване на около 2 ГБ на втора пъти; откажете от реконструкцията чаке при натискане.';

  @override
  String get translation_enableTitle => 'Активирайте превода';

  @override
  String get translation_enableSubtitle =>
      'Превеждайте входящите съобщения и позволявайте предварително превеждане преди изпращане.';

  @override
  String get translation_composerTitle => 'Преведете преди да изпратите';

  @override
  String get translation_composerSubtitle =>
      'Контролира началния статус на иконата за превод, създадена от композитора.';

  @override
  String get translation_autoIncomingTitle => 'Автоматичен превод на съобщения';

  @override
  String get translation_autoIncomingSubtitle =>
      'Превежда автоматично съобщенията за известия, както и за чатове или канали.';

  @override
  String get translation_translateMessage => 'Преведи съобщението';

  @override
  String get translation_targetLanguage => 'Целеви език';

  @override
  String get translation_useAppLanguage => 'Използвайте езика на приложението';

  @override
  String get translation_downloadedModelLabel => 'Изтегнат модел';

  @override
  String get translation_presetModelLabel =>
      'Предварително конфигуриран модел от Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL на ръководството';

  @override
  String get translation_downloadModel => 'Изтеглете модела';

  @override
  String get translation_downloading => 'Изтегляне...';

  @override
  String get translation_working => 'Работа...';

  @override
  String get translation_stop => 'Спрете';

  @override
  String get translation_mergingChunks =>
      'Съединяване на изтеглените части в един файл...';

  @override
  String get translation_downloadedModels => 'Изтеглени модели';

  @override
  String get translation_deleteModel => 'Изтриване на модела';

  @override
  String get translation_modelDownloaded => 'Моделът за превод е изтеглен.';

  @override
  String get translation_downloadStopped => 'Изтеглянето беше прекъснато.';

  @override
  String translation_downloadFailed(String error) {
    return 'Не успях да изтегля: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Въведете първо URL адрес на модела.';

  @override
  String get scanner_linuxPairingShowPin => 'Покажи PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Скриване на PIN кода';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN за съвпадение чрез Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Въведете PIN кода за $deviceName (оставете празно, ако няма такъв).';
  }

  @override
  String get translation_messageTranslation => 'Превод на съобщението';

  @override
  String get translation_translateBeforeSending =>
      'Преведете преди да изпратите';

  @override
  String get translation_composerEnabledHint =>
      'Съобщенията ще бъдат преведени, преди да бъдат изпратени.';

  @override
  String get translation_composerDisabledHint =>
      'Изпращайте съобщения на оригиналния въведен език.';

  @override
  String translation_translateTo(String language) {
    return 'Превеждане на $language';
  }

  @override
  String get translation_translationOptions => 'Опции за превод';

  @override
  String get translation_systemLanguage => 'Език на системата';

  @override
  String get background_serviceTitle => 'MeshCore работи';

  @override
  String get background_serviceText => 'Поддържа BLE връзката активна';

  @override
  String appSettings_translationModelDeleted(String name) {
    return 'Изтрит $name';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Неуспешно изтриване: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Неуспешно обновяване на канала: $error';
  }

  @override
  String get contact_typeChat => 'Чат';

  @override
  String get contact_typeRepeater => 'Повторител';

  @override
  String get contact_typeRoom => 'Стая';

  @override
  String get contact_typeSensor => 'Сензор';

  @override
  String get contact_typeUnknown => 'Неизвестен';

  @override
  String get map_zoomIn => 'Увеличи';

  @override
  String get map_zoomOut => 'Намали мащаба';

  @override
  String get map_centerMap => 'Центрирай картата';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth изисква браузър, базиран на Chromium.';

  @override
  String channels_communityShortId(String id) {
    return 'Идентификационен номер: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'GPS потвърдено';

  @override
  String get pathTrace_legendInferred => 'Извлечена позиция';

  @override
  String get pathMap_viewSingle => 'Самостоятелен';

  @override
  String get pathMap_viewCombined => 'Комбиниран';

  @override
  String get pathMap_play => 'Пусни';

  @override
  String get pathMap_pause => 'Пауза';

  @override
  String get pathMap_replay => 'Повторение';

  @override
  String get pathMap_stepBack => 'Предишна стъпка';

  @override
  String get pathMap_stepForward => 'Следваща стъпка';

  @override
  String get pathMap_animationOn => 'Показвай анимацията на пакета';

  @override
  String get pathMap_animationOff => 'Скрий анимацията на пакета';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Стъпка $current от $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Наблюдавани пътища: $count';
  }

  @override
  String get pathMap_primary => 'Основен';

  @override
  String pathMap_alternate(int index) {
    return 'Алтернативен $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count скока',
      one: '1 скок',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Споделена секция';

  @override
  String get pathMap_legendEstimated => 'Очаквана стойност на сегмента';

  @override
  String pathMap_sharedNodeCount(int count) {
    return 'Използвани от $count пътища';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count скока нямат определено местоположение — показаният път е непълен',
      one: '1 скок няма определено местоположение — показаният път е непълен',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Покажи всички пътища';

  @override
  String get pathMap_hidePath => 'Скрий пътя';

  @override
  String get pathMap_showPath => 'Покажи пътя';

  @override
  String get pathMap_collapsePanel => 'Сгъни панела';

  @override
  String get pathMap_expandPanel => 'Разгъни панела';

  @override
  String get pathMap_noLocation => 'Без посочено местоположение';

  @override
  String get pathMap_followPacket => 'Проследи пакета';

  @override
  String get pathMap_unfollowPacket => 'Спри проследяването на пакета';

  @override
  String get imageSend_title => 'Изпрати изображение';

  @override
  String get imageSend_cropNote =>
      'Масштабиран до 512 × 512 · соотношение сторон не съхранясе';

  @override
  String get imageSend_originalSize => 'Късно на използване на език:';

  @override
  String get imageSend_onAirSize => 'В ефир';

  @override
  String get imageSend_quality => 'Качество';

  @override
  String get imageSend_qualityStandard => 'Стандарт';

  @override
  String get imageSend_qualityHigh => 'Высок';

  @override
  String get imageSend_packetsLabel => 'Пакети';

  @override
  String get imageSend_airtimeLabel => 'Времето на изкъсване';

  @override
  String get imageSend_sizeLabel => 'Баланса';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'пакета',
      one: 'пакет',
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
  String get imageSend_radioUnknownTitle => 'Настройки на радио неизвестни';

  @override
  String get imageSend_radioUnknownBody =>
      'Усредете се с устройство, за да се отработа часът на изстъпане.';

  @override
  String get imageSend_longSendTitle => 'Долга пресилка';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Тази буде поддержива открит отряд на около $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Руйжинг на превъште: всички ретранслятори в диапазонта превратят всички пакети, тъйа каналят оставря дълше, от този час.';

  @override
  String get imageSend_parityTitle => 'Возобновителен пакет';

  @override
  String get imageSend_paritySubtitle =>
      'Едно дополително пакет. Групни извещания не принимаются, след това разбирателят едно пакетто, какщо е пропущен един пакет.';

  @override
  String get imageSend_send => 'Отправляй';

  @override
  String get imageSend_cancel => 'Отмена';

  @override
  String get imageSend_encodeFailed =>
      'Тази изображение не може да бъде кодирано.';

  @override
  String get imageSend_codecDownloading =>
      'Модел на изображение еще разгрузира.';

  @override
  String get imageSend_codecUnavailable =>
      'Изглед отправа не е доступен на този устройство.';

  @override
  String get imageSend_codecDisabled =>
      'Изображенията на извещенията е отключена в настройките.';

  @override
  String get imageSend_deviceUnsupported =>
      'Та радиота не може да пресылава изображени пакети. Подключите устройство, който работи с компанионски прошивка 13 или новия.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'Изображенията се превозводя се как групова информация, следато да се отправят единствено на канал — не в лична вестка.';

  @override
  String get imageSend_tooLarge =>
      'Таата изображение е кодирано в по-числа пакети, отгоре както формат на сетта разрешава.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'пакета',
      one: 'пакет',
    );
    return 'Изображението е изпратено като $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'Изображение не може да бъде отправено: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Отправка наизображение — пакет $sent от $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Узъдето $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$received от $total пакета';
  }

  @override
  String get receivedImage_queued => 'Ожидането за декодиране';

  @override
  String get receivedImage_tapToDecode => 'Натискнете за декодиране';

  @override
  String get receivedImage_decoding => 'Повторно… за приблизително 1 секунда';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Изображение неполно — $received от $total пакети отправили';
  }

  @override
  String get receivedImage_corrupt => 'Изображение не може да бъде воссоздано';

  @override
  String get receivedImage_decoderMissing =>
      'Получена изображение — разгадка на изображение е вреjan';

  @override
  String get receivedImage_evicted => 'Изображение не е хранитено';

  @override
  String get receivedImage_retry => 'Повтори';

  @override
  String get receivedImage_decodeAgain => 'Правилейте заново';

  @override
  String get receivedImage_openSettings => 'Настройте';

  @override
  String get receivedImage_tapToProcess => 'Натискнете за обработка';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'пакета',
      one: 'пакет',
    );
    return '$bytes байта · $packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds секунди';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes мин $seconds сек';
  }
}
