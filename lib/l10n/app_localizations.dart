import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sk'),
    Locale('sl'),
    Locale('sv'),
    Locale('uk'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MeshCore Open'**
  String get appTitle;

  /// No description provided for @nav_contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get nav_contacts;

  /// No description provided for @nav_channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get nav_channels;

  /// No description provided for @nav_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get nav_map;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get common_connect;

  /// No description provided for @common_unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get common_unknownDevice;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get common_deleteAll;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get common_disconnect;

  /// No description provided for @common_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get common_connected;

  /// No description provided for @common_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get common_disconnected;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get common_share;

  /// No description provided for @common_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get common_copy;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get common_hide;

  /// No description provided for @common_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// No description provided for @common_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get common_enable;

  /// No description provided for @common_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get common_disable;

  /// No description provided for @common_reboot.
  ///
  /// In en, this message translates to:
  /// **'Reboot'**
  String get common_reboot;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_notAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get common_notAvailable;

  /// No description provided for @common_voltageValue.
  ///
  /// In en, this message translates to:
  /// **'{volts} V'**
  String common_voltageValue(String volts);

  /// No description provided for @common_percentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String common_percentValue(int percent);

  /// No description provided for @scanner_title.
  ///
  /// In en, this message translates to:
  /// **'MeshCore Open'**
  String get scanner_title;

  /// No description provided for @connectionChoiceUsbLabel.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get connectionChoiceUsbLabel;

  /// No description provided for @connectionChoiceBluetoothLabel.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get connectionChoiceBluetoothLabel;

  /// No description provided for @usbScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect over USB'**
  String get usbScreenTitle;

  /// No description provided for @usbScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a detected serial device and connect directly to your MeshCore node.'**
  String get usbScreenSubtitle;

  /// No description provided for @usbScreenStatus.
  ///
  /// In en, this message translates to:
  /// **'Select a USB device'**
  String get usbScreenStatus;

  /// No description provided for @usbScreenNote.
  ///
  /// In en, this message translates to:
  /// **'USB serial is active on supported Android devices and desktop platforms.'**
  String get usbScreenNote;

  /// No description provided for @usbScreenEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No USB devices found. Plug one in and refresh.'**
  String get usbScreenEmptyState;

  /// No description provided for @usbErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'USB permission was denied.'**
  String get usbErrorPermissionDenied;

  /// No description provided for @usbErrorDeviceMissing.
  ///
  /// In en, this message translates to:
  /// **'The selected USB device is no longer available.'**
  String get usbErrorDeviceMissing;

  /// No description provided for @usbErrorInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Select a valid USB device.'**
  String get usbErrorInvalidPort;

  /// No description provided for @usbErrorBusy.
  ///
  /// In en, this message translates to:
  /// **'Another USB connection request is already in progress.'**
  String get usbErrorBusy;

  /// No description provided for @usbErrorNotConnected.
  ///
  /// In en, this message translates to:
  /// **'No USB device is connected.'**
  String get usbErrorNotConnected;

  /// No description provided for @usbErrorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open the selected USB device.'**
  String get usbErrorOpenFailed;

  /// No description provided for @usbErrorConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the selected USB device.'**
  String get usbErrorConnectFailed;

  /// No description provided for @usbErrorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'USB serial is not supported on this platform.'**
  String get usbErrorUnsupported;

  /// No description provided for @usbErrorAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'A USB connection is already active.'**
  String get usbErrorAlreadyActive;

  /// No description provided for @usbErrorNoDeviceSelected.
  ///
  /// In en, this message translates to:
  /// **'No USB device was selected.'**
  String get usbErrorNoDeviceSelected;

  /// No description provided for @usbErrorPortClosed.
  ///
  /// In en, this message translates to:
  /// **'The USB connection is not open.'**
  String get usbErrorPortClosed;

  /// No description provided for @usbErrorConnectTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Make sure the device has USB Companion firmware.'**
  String get usbErrorConnectTimedOut;

  /// No description provided for @usbFallbackDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Web Serial Device'**
  String get usbFallbackDeviceName;

  /// No description provided for @usbStatus_notConnected.
  ///
  /// In en, this message translates to:
  /// **'Select a USB device'**
  String get usbStatus_notConnected;

  /// No description provided for @usbStatus_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to USB device...'**
  String get usbStatus_connecting;

  /// No description provided for @usbStatus_searching.
  ///
  /// In en, this message translates to:
  /// **'Searching for USB devices...'**
  String get usbStatus_searching;

  /// No description provided for @usbConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'USB connection failed: {error}'**
  String usbConnectionFailed(String error);

  /// No description provided for @scanner_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices...'**
  String get scanner_scanning;

  /// No description provided for @scanner_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get scanner_connecting;

  /// No description provided for @scanner_disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting...'**
  String get scanner_disconnecting;

  /// No description provided for @scanner_notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get scanner_notConnected;

  /// No description provided for @scanner_connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {deviceName}'**
  String scanner_connectedTo(String deviceName);

  /// No description provided for @scanner_searchingDevices.
  ///
  /// In en, this message translates to:
  /// **'Searching for MeshCore devices...'**
  String get scanner_searchingDevices;

  /// No description provided for @scanner_tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan to find MeshCore devices'**
  String get scanner_tapToScan;

  /// No description provided for @scanner_connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String scanner_connectionFailed(String error);

  /// No description provided for @scanner_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get scanner_stop;

  /// No description provided for @scanner_scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanner_scan;

  /// No description provided for @scanner_bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get scanner_bluetoothOff;

  /// No description provided for @scanner_bluetoothOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Please turn on Bluetooth to scan for devices'**
  String get scanner_bluetoothOffMessage;

  /// No description provided for @scanner_chromeRequired.
  ///
  /// In en, this message translates to:
  /// **'Chrome Browser Required'**
  String get scanner_chromeRequired;

  /// No description provided for @scanner_chromeRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This web application requires Google Chrome or a Chromium-based browser for Bluetooth support.'**
  String get scanner_chromeRequiredMessage;

  /// No description provided for @scanner_enableBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth'**
  String get scanner_enableBluetooth;

  /// No description provided for @device_quickSwitch.
  ///
  /// In en, this message translates to:
  /// **'Quick switch'**
  String get device_quickSwitch;

  /// No description provided for @device_meshcore.
  ///
  /// In en, this message translates to:
  /// **'MeshCore'**
  String get device_meshcore;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get settings_deviceInfo;

  /// No description provided for @settings_appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settings_appSettings;

  /// No description provided for @settings_appSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications, messaging, and map preferences'**
  String get settings_appSettingsSubtitle;

  /// No description provided for @settings_nodeSettings.
  ///
  /// In en, this message translates to:
  /// **'Node Settings'**
  String get settings_nodeSettings;

  /// No description provided for @settings_nodeName.
  ///
  /// In en, this message translates to:
  /// **'Node Name'**
  String get settings_nodeName;

  /// No description provided for @settings_nodeNameNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settings_nodeNameNotSet;

  /// No description provided for @settings_nodeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter node name'**
  String get settings_nodeNameHint;

  /// No description provided for @settings_nodeNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get settings_nodeNameUpdated;

  /// No description provided for @settings_radioSettings.
  ///
  /// In en, this message translates to:
  /// **'Radio Settings'**
  String get settings_radioSettings;

  /// No description provided for @settings_radioSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequency, power, spreading factor'**
  String get settings_radioSettingsSubtitle;

  /// No description provided for @settings_radioSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Radio settings updated'**
  String get settings_radioSettingsUpdated;

  /// No description provided for @settings_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settings_location;

  /// No description provided for @settings_locationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GPS coordinates'**
  String get settings_locationSubtitle;

  /// No description provided for @settings_locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location and GPS settings updated'**
  String get settings_locationUpdated;

  /// No description provided for @settings_locationBothRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter both latitude and longitude.'**
  String get settings_locationBothRequired;

  /// No description provided for @settings_locationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude or longitude.'**
  String get settings_locationInvalid;

  /// No description provided for @settings_locationGPSEnable.
  ///
  /// In en, this message translates to:
  /// **'GPS Enable'**
  String get settings_locationGPSEnable;

  /// No description provided for @settings_locationGPSEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enables GPS to automatically update location.'**
  String get settings_locationGPSEnableSubtitle;

  /// No description provided for @settings_locationIntervalSec.
  ///
  /// In en, this message translates to:
  /// **'Interval for GPS (Seconds)'**
  String get settings_locationIntervalSec;

  /// No description provided for @settings_locationIntervalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Interval must be at least 60 seconds, and less than 86400 seconds.'**
  String get settings_locationIntervalInvalid;

  /// No description provided for @settings_latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get settings_latitude;

  /// No description provided for @settings_longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get settings_longitude;

  /// No description provided for @settings_contactSettings.
  ///
  /// In en, this message translates to:
  /// **'Contact Settings'**
  String get settings_contactSettings;

  /// No description provided for @settings_contactSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings for how contacts are added.'**
  String get settings_contactSettingsSubtitle;

  /// No description provided for @settings_privacyMode.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode'**
  String get settings_privacyMode;

  /// No description provided for @settings_privacyModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide name/location in advertisements'**
  String get settings_privacyModeSubtitle;

  /// No description provided for @settings_privacyModeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle privacy mode to hide your name and location in advertisements.'**
  String get settings_privacyModeToggle;

  /// No description provided for @settings_privacyModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Privacy mode enabled'**
  String get settings_privacyModeEnabled;

  /// No description provided for @settings_privacyModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Privacy mode disabled'**
  String get settings_privacyModeDisabled;

  /// No description provided for @settings_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get settings_actions;

  /// No description provided for @settings_sendAdvertisement.
  ///
  /// In en, this message translates to:
  /// **'Send Advertisement'**
  String get settings_sendAdvertisement;

  /// No description provided for @settings_sendAdvertisementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast presence now'**
  String get settings_sendAdvertisementSubtitle;

  /// No description provided for @settings_advertisementSent.
  ///
  /// In en, this message translates to:
  /// **'Advertisement sent'**
  String get settings_advertisementSent;

  /// No description provided for @settings_syncTime.
  ///
  /// In en, this message translates to:
  /// **'Sync Time'**
  String get settings_syncTime;

  /// No description provided for @settings_syncTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set device clock to phone time'**
  String get settings_syncTimeSubtitle;

  /// No description provided for @settings_timeSynchronized.
  ///
  /// In en, this message translates to:
  /// **'Time synchronized'**
  String get settings_timeSynchronized;

  /// No description provided for @settings_refreshContacts.
  ///
  /// In en, this message translates to:
  /// **'Refresh Contacts'**
  String get settings_refreshContacts;

  /// No description provided for @settings_refreshContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reload contact list from device'**
  String get settings_refreshContactsSubtitle;

  /// No description provided for @settings_rebootDevice.
  ///
  /// In en, this message translates to:
  /// **'Reboot Device'**
  String get settings_rebootDevice;

  /// No description provided for @settings_rebootDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restart the MeshCore device'**
  String get settings_rebootDeviceSubtitle;

  /// No description provided for @settings_rebootDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reboot the device? You will be disconnected.'**
  String get settings_rebootDeviceConfirm;

  /// No description provided for @settings_debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settings_debug;

  /// No description provided for @settings_bleDebugLog.
  ///
  /// In en, this message translates to:
  /// **'BLE Debug Log'**
  String get settings_bleDebugLog;

  /// No description provided for @settings_bleDebugLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'BLE commands, responses, and raw data'**
  String get settings_bleDebugLogSubtitle;

  /// No description provided for @settings_appDebugLog.
  ///
  /// In en, this message translates to:
  /// **'App Debug Log'**
  String get settings_appDebugLog;

  /// No description provided for @settings_appDebugLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Application debug messages'**
  String get settings_appDebugLogSubtitle;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'MeshCore Open v{version}'**
  String settings_aboutVersion(String version);

  /// No description provided for @settings_aboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'2026 MeshCore Open Source Project'**
  String get settings_aboutLegalese;

  /// No description provided for @settings_aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'An open-source Flutter client for MeshCore LoRa mesh networking devices.'**
  String get settings_aboutDescription;

  /// No description provided for @settings_aboutOpenMeteoAttribution.
  ///
  /// In en, this message translates to:
  /// **'LOS elevation data: Open-Meteo (CC BY 4.0)'**
  String get settings_aboutOpenMeteoAttribution;

  /// No description provided for @settings_infoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settings_infoName;

  /// No description provided for @settings_infoId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get settings_infoId;

  /// No description provided for @settings_infoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settings_infoStatus;

  /// No description provided for @settings_infoBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get settings_infoBattery;

  /// No description provided for @settings_infoPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get settings_infoPublicKey;

  /// No description provided for @settings_infoContactsCount.
  ///
  /// In en, this message translates to:
  /// **'Contacts Count'**
  String get settings_infoContactsCount;

  /// No description provided for @settings_infoChannelCount.
  ///
  /// In en, this message translates to:
  /// **'Channel Count'**
  String get settings_infoChannelCount;

  /// No description provided for @settings_presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get settings_presets;

  /// No description provided for @settings_frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency (MHz)'**
  String get settings_frequency;

  /// No description provided for @settings_frequencyHelper.
  ///
  /// In en, this message translates to:
  /// **'300.0 - 2500.0'**
  String get settings_frequencyHelper;

  /// No description provided for @settings_frequencyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid frequency (300-2500 MHz)'**
  String get settings_frequencyInvalid;

  /// No description provided for @settings_bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get settings_bandwidth;

  /// No description provided for @settings_spreadingFactor.
  ///
  /// In en, this message translates to:
  /// **'Spreading Factor'**
  String get settings_spreadingFactor;

  /// No description provided for @settings_codingRate.
  ///
  /// In en, this message translates to:
  /// **'Coding Rate'**
  String get settings_codingRate;

  /// No description provided for @settings_txPower.
  ///
  /// In en, this message translates to:
  /// **'TX Power (dBm)'**
  String get settings_txPower;

  /// No description provided for @settings_txPowerHelper.
  ///
  /// In en, this message translates to:
  /// **'0 - 22'**
  String get settings_txPowerHelper;

  /// No description provided for @settings_txPowerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid TX power (0-22 dBm)'**
  String get settings_txPowerInvalid;

  /// No description provided for @settings_clientRepeat.
  ///
  /// In en, this message translates to:
  /// **'Off-Grid Repeat'**
  String get settings_clientRepeat;

  /// No description provided for @settings_clientRepeatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow this device to repeat mesh packets for others'**
  String get settings_clientRepeatSubtitle;

  /// No description provided for @settings_clientRepeatFreqWarning.
  ///
  /// In en, this message translates to:
  /// **'Off-grid repeat requires 433, 869, or 918 MHz frequency'**
  String get settings_clientRepeatFreqWarning;

  /// No description provided for @settings_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String settings_error(String message);

  /// No description provided for @appSettings_title.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings_title;

  /// No description provided for @appSettings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appSettings_appearance;

  /// No description provided for @appSettings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appSettings_theme;

  /// No description provided for @appSettings_themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appSettings_themeSystem;

  /// No description provided for @appSettings_themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appSettings_themeLight;

  /// No description provided for @appSettings_themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appSettings_themeDark;

  /// No description provided for @appSettings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appSettings_language;

  /// No description provided for @appSettings_languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appSettings_languageSystem;

  /// No description provided for @appSettings_languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get appSettings_languageEn;

  /// No description provided for @appSettings_languageFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get appSettings_languageFr;

  /// No description provided for @appSettings_languageEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get appSettings_languageEs;

  /// No description provided for @appSettings_languageDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get appSettings_languageDe;

  /// No description provided for @appSettings_languagePl.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get appSettings_languagePl;

  /// No description provided for @appSettings_languageSl.
  ///
  /// In en, this message translates to:
  /// **'Slovenščina'**
  String get appSettings_languageSl;

  /// No description provided for @appSettings_languagePt.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get appSettings_languagePt;

  /// No description provided for @appSettings_languageIt.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get appSettings_languageIt;

  /// No description provided for @appSettings_languageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get appSettings_languageZh;

  /// No description provided for @appSettings_languageSv.
  ///
  /// In en, this message translates to:
  /// **'Svenska'**
  String get appSettings_languageSv;

  /// No description provided for @appSettings_languageNl.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get appSettings_languageNl;

  /// No description provided for @appSettings_languageSk.
  ///
  /// In en, this message translates to:
  /// **'Slovenčina'**
  String get appSettings_languageSk;

  /// No description provided for @appSettings_languageBg.
  ///
  /// In en, this message translates to:
  /// **'Български'**
  String get appSettings_languageBg;

  /// No description provided for @appSettings_languageRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get appSettings_languageRu;

  /// No description provided for @appSettings_languageUk.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get appSettings_languageUk;

  /// No description provided for @appSettings_enableMessageTracing.
  ///
  /// In en, this message translates to:
  /// **'Enable Message Tracing'**
  String get appSettings_enableMessageTracing;

  /// No description provided for @appSettings_enableMessageTracingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show detailed routing and timing metadata for messages'**
  String get appSettings_enableMessageTracingSubtitle;

  /// No description provided for @appSettings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get appSettings_notifications;

  /// No description provided for @appSettings_enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get appSettings_enableNotifications;

  /// No description provided for @appSettings_enableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for messages and adverts'**
  String get appSettings_enableNotificationsSubtitle;

  /// No description provided for @appSettings_notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get appSettings_notificationPermissionDenied;

  /// No description provided for @appSettings_notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get appSettings_notificationsEnabled;

  /// No description provided for @appSettings_notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get appSettings_notificationsDisabled;

  /// No description provided for @appSettings_messageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Message Notifications'**
  String get appSettings_messageNotifications;

  /// No description provided for @appSettings_messageNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show notification when receiving new messages'**
  String get appSettings_messageNotificationsSubtitle;

  /// No description provided for @appSettings_channelMessageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Channel Message Notifications'**
  String get appSettings_channelMessageNotifications;

  /// No description provided for @appSettings_channelMessageNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show notification when receiving channel messages'**
  String get appSettings_channelMessageNotificationsSubtitle;

  /// No description provided for @appSettings_advertisementNotifications.
  ///
  /// In en, this message translates to:
  /// **'Advertisement Notifications'**
  String get appSettings_advertisementNotifications;

  /// No description provided for @appSettings_advertisementNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show notification when new nodes are discovered'**
  String get appSettings_advertisementNotificationsSubtitle;

  /// No description provided for @appSettings_messaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get appSettings_messaging;

  /// No description provided for @appSettings_clearPathOnMaxRetry.
  ///
  /// In en, this message translates to:
  /// **'Clear Path on Max Retry'**
  String get appSettings_clearPathOnMaxRetry;

  /// No description provided for @appSettings_clearPathOnMaxRetrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset contact path after 5 failed send attempts'**
  String get appSettings_clearPathOnMaxRetrySubtitle;

  /// No description provided for @appSettings_pathsWillBeCleared.
  ///
  /// In en, this message translates to:
  /// **'Paths will be cleared after 5 failed retries'**
  String get appSettings_pathsWillBeCleared;

  /// No description provided for @appSettings_pathsWillNotBeCleared.
  ///
  /// In en, this message translates to:
  /// **'Paths will not be auto-cleared'**
  String get appSettings_pathsWillNotBeCleared;

  /// No description provided for @appSettings_autoRouteRotation.
  ///
  /// In en, this message translates to:
  /// **'Auto Route Rotation'**
  String get appSettings_autoRouteRotation;

  /// No description provided for @appSettings_autoRouteRotationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle between best paths and flood mode'**
  String get appSettings_autoRouteRotationSubtitle;

  /// No description provided for @appSettings_autoRouteRotationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto route rotation enabled'**
  String get appSettings_autoRouteRotationEnabled;

  /// No description provided for @appSettings_autoRouteRotationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto route rotation disabled'**
  String get appSettings_autoRouteRotationDisabled;

  /// No description provided for @appSettings_battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get appSettings_battery;

  /// No description provided for @appSettings_batteryChemistry.
  ///
  /// In en, this message translates to:
  /// **'Battery Chemistry'**
  String get appSettings_batteryChemistry;

  /// No description provided for @appSettings_batteryChemistryPerDevice.
  ///
  /// In en, this message translates to:
  /// **'Set per device ({deviceName})'**
  String appSettings_batteryChemistryPerDevice(String deviceName);

  /// No description provided for @appSettings_batteryChemistryConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device to choose'**
  String get appSettings_batteryChemistryConnectFirst;

  /// No description provided for @appSettings_batteryNmc.
  ///
  /// In en, this message translates to:
  /// **'18650 NMC (3.0-4.2V)'**
  String get appSettings_batteryNmc;

  /// No description provided for @appSettings_batteryLifepo4.
  ///
  /// In en, this message translates to:
  /// **'LiFePO4 (2.6-3.65V)'**
  String get appSettings_batteryLifepo4;

  /// No description provided for @appSettings_batteryLipo.
  ///
  /// In en, this message translates to:
  /// **'LiPo (3.0-4.2V)'**
  String get appSettings_batteryLipo;

  /// No description provided for @appSettings_mapDisplay.
  ///
  /// In en, this message translates to:
  /// **'Map Display'**
  String get appSettings_mapDisplay;

  /// No description provided for @appSettings_showRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Show Repeaters'**
  String get appSettings_showRepeaters;

  /// No description provided for @appSettings_showRepeatersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display repeater nodes on the map'**
  String get appSettings_showRepeatersSubtitle;

  /// No description provided for @appSettings_showChatNodes.
  ///
  /// In en, this message translates to:
  /// **'Show Chat Nodes'**
  String get appSettings_showChatNodes;

  /// No description provided for @appSettings_showChatNodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display chat nodes on the map'**
  String get appSettings_showChatNodesSubtitle;

  /// No description provided for @appSettings_showOtherNodes.
  ///
  /// In en, this message translates to:
  /// **'Show Other Nodes'**
  String get appSettings_showOtherNodes;

  /// No description provided for @appSettings_showOtherNodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display other node types on the map'**
  String get appSettings_showOtherNodesSubtitle;

  /// No description provided for @appSettings_timeFilter.
  ///
  /// In en, this message translates to:
  /// **'Time Filter'**
  String get appSettings_timeFilter;

  /// No description provided for @appSettings_timeFilterShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all nodes'**
  String get appSettings_timeFilterShowAll;

  /// No description provided for @appSettings_timeFilterShowLast.
  ///
  /// In en, this message translates to:
  /// **'Show nodes from last {hours} hours'**
  String appSettings_timeFilterShowLast(int hours);

  /// No description provided for @appSettings_mapTimeFilter.
  ///
  /// In en, this message translates to:
  /// **'Map Time Filter'**
  String get appSettings_mapTimeFilter;

  /// No description provided for @appSettings_showNodesDiscoveredWithin.
  ///
  /// In en, this message translates to:
  /// **'Show nodes discovered within:'**
  String get appSettings_showNodesDiscoveredWithin;

  /// No description provided for @appSettings_allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get appSettings_allTime;

  /// No description provided for @appSettings_lastHour.
  ///
  /// In en, this message translates to:
  /// **'Last hour'**
  String get appSettings_lastHour;

  /// No description provided for @appSettings_last6Hours.
  ///
  /// In en, this message translates to:
  /// **'Last 6 hours'**
  String get appSettings_last6Hours;

  /// No description provided for @appSettings_last24Hours.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get appSettings_last24Hours;

  /// No description provided for @appSettings_lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get appSettings_lastWeek;

  /// No description provided for @appSettings_offlineMapCache.
  ///
  /// In en, this message translates to:
  /// **'Offline Map Cache'**
  String get appSettings_offlineMapCache;

  /// No description provided for @appSettings_unitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get appSettings_unitsTitle;

  /// No description provided for @appSettings_unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (m / km)'**
  String get appSettings_unitsMetric;

  /// No description provided for @appSettings_unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (ft / mi)'**
  String get appSettings_unitsImperial;

  /// No description provided for @appSettings_noAreaSelected.
  ///
  /// In en, this message translates to:
  /// **'No area selected'**
  String get appSettings_noAreaSelected;

  /// No description provided for @appSettings_areaSelectedZoom.
  ///
  /// In en, this message translates to:
  /// **'Area selected (zoom {minZoom}-{maxZoom})'**
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom);

  /// No description provided for @appSettings_debugCard.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get appSettings_debugCard;

  /// No description provided for @appSettings_appDebugLogging.
  ///
  /// In en, this message translates to:
  /// **'App Debug Logging'**
  String get appSettings_appDebugLogging;

  /// No description provided for @appSettings_appDebugLoggingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log app debug messages for troubleshooting'**
  String get appSettings_appDebugLoggingSubtitle;

  /// No description provided for @appSettings_appDebugLoggingEnabled.
  ///
  /// In en, this message translates to:
  /// **'App debug logging enabled'**
  String get appSettings_appDebugLoggingEnabled;

  /// No description provided for @appSettings_appDebugLoggingDisabled.
  ///
  /// In en, this message translates to:
  /// **'App debug logging disabled'**
  String get appSettings_appDebugLoggingDisabled;

  /// No description provided for @contacts_title.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts_title;

  /// No description provided for @contacts_noContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contacts_noContacts;

  /// No description provided for @contacts_contactsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Contacts will appear when devices advertise'**
  String get contacts_contactsWillAppear;

  /// No description provided for @contacts_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get contacts_unread;

  /// No description provided for @contacts_searchContactsNoNumber.
  ///
  /// In en, this message translates to:
  /// **'Search Contacts...'**
  String get contacts_searchContactsNoNumber;

  /// No description provided for @contacts_searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search {number}{str} Contacts...'**
  String contacts_searchContacts(int number, String str);

  /// No description provided for @contacts_searchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Search {number}{str} Favorites...'**
  String contacts_searchFavorites(int number, String str);

  /// No description provided for @contacts_searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search {number}{str} Users...'**
  String contacts_searchUsers(int number, String str);

  /// No description provided for @contacts_searchRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Search {number}{str} Repeaters...'**
  String contacts_searchRepeaters(int number, String str);

  /// No description provided for @contacts_searchRoomServers.
  ///
  /// In en, this message translates to:
  /// **'Search {number}{str} Room servers...'**
  String contacts_searchRoomServers(int number, String str);

  /// No description provided for @contacts_noUnreadContacts.
  ///
  /// In en, this message translates to:
  /// **'No unread contacts'**
  String get contacts_noUnreadContacts;

  /// No description provided for @contacts_noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts or groups found'**
  String get contacts_noContactsFound;

  /// No description provided for @contacts_deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get contacts_deleteContact;

  /// No description provided for @contacts_removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {contactName} from contacts?'**
  String contacts_removeConfirm(String contactName);

  /// No description provided for @contacts_manageRepeater.
  ///
  /// In en, this message translates to:
  /// **'Manage Repeater'**
  String get contacts_manageRepeater;

  /// No description provided for @contacts_manageRoom.
  ///
  /// In en, this message translates to:
  /// **'Manage Room Server'**
  String get contacts_manageRoom;

  /// No description provided for @contacts_roomLogin.
  ///
  /// In en, this message translates to:
  /// **'Room Server Login'**
  String get contacts_roomLogin;

  /// No description provided for @contacts_openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get contacts_openChat;

  /// No description provided for @contacts_editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get contacts_editGroup;

  /// No description provided for @contacts_deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get contacts_deleteGroup;

  /// No description provided for @contacts_deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{groupName}\"?'**
  String contacts_deleteGroupConfirm(String groupName);

  /// No description provided for @contacts_newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get contacts_newGroup;

  /// No description provided for @contacts_groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get contacts_groupName;

  /// No description provided for @contacts_groupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get contacts_groupNameRequired;

  /// No description provided for @contacts_groupAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Group \"{name}\" already exists'**
  String contacts_groupAlreadyExists(String name);

  /// No description provided for @contacts_filterContacts.
  ///
  /// In en, this message translates to:
  /// **'Filter contacts...'**
  String get contacts_filterContacts;

  /// No description provided for @contacts_noContactsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No contacts match your filter'**
  String get contacts_noContactsMatchFilter;

  /// No description provided for @contacts_noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get contacts_noMembers;

  /// No description provided for @contacts_lastSeenNow.
  ///
  /// In en, this message translates to:
  /// **'recently'**
  String get contacts_lastSeenNow;

  /// No description provided for @contacts_lastSeenMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'~ {minutes} min.'**
  String contacts_lastSeenMinsAgo(int minutes);

  /// No description provided for @contacts_lastSeenHourAgo.
  ///
  /// In en, this message translates to:
  /// **'~ 1 hour'**
  String get contacts_lastSeenHourAgo;

  /// No description provided for @contacts_lastSeenHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'~ {hours} hours'**
  String contacts_lastSeenHoursAgo(int hours);

  /// No description provided for @contacts_lastSeenDayAgo.
  ///
  /// In en, this message translates to:
  /// **'~ 1 day'**
  String get contacts_lastSeenDayAgo;

  /// No description provided for @contacts_lastSeenDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'~ {days} days'**
  String contacts_lastSeenDaysAgo(int days);

  /// No description provided for @channels_title.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels_title;

  /// No description provided for @channels_noChannelsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No channels configured'**
  String get channels_noChannelsConfigured;

  /// No description provided for @channels_addPublicChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Public Channel'**
  String get channels_addPublicChannel;

  /// No description provided for @channels_searchChannels.
  ///
  /// In en, this message translates to:
  /// **'Search channels...'**
  String get channels_searchChannels;

  /// No description provided for @channels_noChannelsFound.
  ///
  /// In en, this message translates to:
  /// **'No channels found'**
  String get channels_noChannelsFound;

  /// No description provided for @channels_channelIndex.
  ///
  /// In en, this message translates to:
  /// **'Channel {index}'**
  String channels_channelIndex(int index);

  /// No description provided for @channels_hashtagChannel.
  ///
  /// In en, this message translates to:
  /// **'Hashtag channel'**
  String get channels_hashtagChannel;

  /// No description provided for @channels_public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get channels_public;

  /// No description provided for @channels_private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get channels_private;

  /// No description provided for @channels_publicChannel.
  ///
  /// In en, this message translates to:
  /// **'Public channel'**
  String get channels_publicChannel;

  /// No description provided for @channels_privateChannel.
  ///
  /// In en, this message translates to:
  /// **'Private channel'**
  String get channels_privateChannel;

  /// No description provided for @channels_editChannel.
  ///
  /// In en, this message translates to:
  /// **'Edit channel'**
  String get channels_editChannel;

  /// No description provided for @channels_muteChannel.
  ///
  /// In en, this message translates to:
  /// **'Mute channel'**
  String get channels_muteChannel;

  /// No description provided for @channels_unmuteChannel.
  ///
  /// In en, this message translates to:
  /// **'Unmute channel'**
  String get channels_unmuteChannel;

  /// No description provided for @channels_deleteChannel.
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get channels_deleteChannel;

  /// No description provided for @channels_deleteChannelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String channels_deleteChannelConfirm(String name);

  /// No description provided for @channels_channelDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete channel \"{name}\"'**
  String channels_channelDeleteFailed(String name);

  /// No description provided for @channels_channelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\" deleted'**
  String channels_channelDeleted(String name);

  /// No description provided for @channels_addChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Channel'**
  String get channels_addChannel;

  /// No description provided for @channels_channelIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel Index'**
  String get channels_channelIndexLabel;

  /// No description provided for @channels_channelName.
  ///
  /// In en, this message translates to:
  /// **'Channel Name'**
  String get channels_channelName;

  /// No description provided for @channels_usePublicChannel.
  ///
  /// In en, this message translates to:
  /// **'Use Public Channel'**
  String get channels_usePublicChannel;

  /// No description provided for @channels_standardPublicPsk.
  ///
  /// In en, this message translates to:
  /// **'Standard public PSK'**
  String get channels_standardPublicPsk;

  /// No description provided for @channels_pskHex.
  ///
  /// In en, this message translates to:
  /// **'PSK (Hex)'**
  String get channels_pskHex;

  /// No description provided for @channels_generateRandomPsk.
  ///
  /// In en, this message translates to:
  /// **'Generate random PSK'**
  String get channels_generateRandomPsk;

  /// No description provided for @channels_enterChannelName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a channel name'**
  String get channels_enterChannelName;

  /// No description provided for @channels_pskMustBe32Hex.
  ///
  /// In en, this message translates to:
  /// **'PSK must be 32 hex characters'**
  String get channels_pskMustBe32Hex;

  /// No description provided for @channels_channelAdded.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\" added'**
  String channels_channelAdded(String name);

  /// No description provided for @channels_editChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Channel {index}'**
  String channels_editChannelTitle(int index);

  /// No description provided for @channels_smazCompression.
  ///
  /// In en, this message translates to:
  /// **'SMAZ compression'**
  String get channels_smazCompression;

  /// No description provided for @channels_channelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\" updated'**
  String channels_channelUpdated(String name);

  /// No description provided for @channels_publicChannelAdded.
  ///
  /// In en, this message translates to:
  /// **'Public channel added'**
  String get channels_publicChannelAdded;

  /// No description provided for @channels_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get channels_sortBy;

  /// No description provided for @channels_sortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get channels_sortManual;

  /// No description provided for @channels_sortAZ.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get channels_sortAZ;

  /// No description provided for @channels_sortLatestMessages.
  ///
  /// In en, this message translates to:
  /// **'Latest messages'**
  String get channels_sortLatestMessages;

  /// No description provided for @channels_sortUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get channels_sortUnread;

  /// No description provided for @channels_createPrivateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create a Private Channel'**
  String get channels_createPrivateChannel;

  /// No description provided for @channels_createPrivateChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Secured with a secret key.'**
  String get channels_createPrivateChannelDesc;

  /// No description provided for @channels_joinPrivateChannel.
  ///
  /// In en, this message translates to:
  /// **'Join a Private Channel'**
  String get channels_joinPrivateChannel;

  /// No description provided for @channels_joinPrivateChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Manually enter a secret key.'**
  String get channels_joinPrivateChannelDesc;

  /// No description provided for @channels_joinPublicChannel.
  ///
  /// In en, this message translates to:
  /// **'Join the Public Channel'**
  String get channels_joinPublicChannel;

  /// No description provided for @channels_joinPublicChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Anyone can join this channel.'**
  String get channels_joinPublicChannelDesc;

  /// No description provided for @channels_joinHashtagChannel.
  ///
  /// In en, this message translates to:
  /// **'Join a Hashtag Channel'**
  String get channels_joinHashtagChannel;

  /// No description provided for @channels_joinHashtagChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Anyone can join hashtag channels.'**
  String get channels_joinHashtagChannelDesc;

  /// No description provided for @channels_scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR Code'**
  String get channels_scanQrCode;

  /// No description provided for @channels_scanQrCodeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get channels_scanQrCodeComingSoon;

  /// No description provided for @channels_enterHashtag.
  ///
  /// In en, this message translates to:
  /// **'Enter hashtag'**
  String get channels_enterHashtag;

  /// No description provided for @channels_hashtagHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. #team'**
  String get channels_hashtagHint;

  /// No description provided for @chat_noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chat_noMessages;

  /// No description provided for @chat_sendMessageToStart.
  ///
  /// In en, this message translates to:
  /// **'Send a message to get started'**
  String get chat_sendMessageToStart;

  /// No description provided for @chat_originalMessageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Original message not found'**
  String get chat_originalMessageNotFound;

  /// No description provided for @chat_replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chat_replyingTo(String name);

  /// No description provided for @chat_replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String chat_replyTo(String name);

  /// No description provided for @chat_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chat_location;

  /// No description provided for @chat_sendMessageTo.
  ///
  /// In en, this message translates to:
  /// **'Send a message to {contactName}'**
  String chat_sendMessageTo(String contactName);

  /// No description provided for @chat_typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chat_typeMessage;

  /// No description provided for @chat_messageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message too long (max {maxBytes} bytes).'**
  String chat_messageTooLong(int maxBytes);

  /// No description provided for @chat_messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get chat_messageCopied;

  /// No description provided for @chat_messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chat_messageDeleted;

  /// No description provided for @chat_retryingMessage.
  ///
  /// In en, this message translates to:
  /// **'Retrying message'**
  String get chat_retryingMessage;

  /// No description provided for @chat_retryCount.
  ///
  /// In en, this message translates to:
  /// **'Retry {current}/{max}'**
  String chat_retryCount(int current, int max);

  /// No description provided for @chat_sendGif.
  ///
  /// In en, this message translates to:
  /// **'Send GIF'**
  String get chat_sendGif;

  /// No description provided for @chat_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chat_reply;

  /// No description provided for @chat_addReaction.
  ///
  /// In en, this message translates to:
  /// **'Add Reaction'**
  String get chat_addReaction;

  /// No description provided for @chat_me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get chat_me;

  /// No description provided for @emojiCategorySmileys.
  ///
  /// In en, this message translates to:
  /// **'Smileys'**
  String get emojiCategorySmileys;

  /// No description provided for @emojiCategoryGestures.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get emojiCategoryGestures;

  /// No description provided for @emojiCategoryHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get emojiCategoryHearts;

  /// No description provided for @emojiCategoryObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get emojiCategoryObjects;

  /// No description provided for @gifPicker_title.
  ///
  /// In en, this message translates to:
  /// **'Choose a GIF'**
  String get gifPicker_title;

  /// No description provided for @gifPicker_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GIFs...'**
  String get gifPicker_searchHint;

  /// No description provided for @gifPicker_poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by GIPHY'**
  String get gifPicker_poweredBy;

  /// No description provided for @gifPicker_noGifsFound.
  ///
  /// In en, this message translates to:
  /// **'No GIFs found'**
  String get gifPicker_noGifsFound;

  /// No description provided for @gifPicker_failedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load GIFs'**
  String get gifPicker_failedLoad;

  /// No description provided for @gifPicker_failedSearch.
  ///
  /// In en, this message translates to:
  /// **'Failed to search GIFs'**
  String get gifPicker_failedSearch;

  /// No description provided for @gifPicker_noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get gifPicker_noInternet;

  /// No description provided for @debugLog_appTitle.
  ///
  /// In en, this message translates to:
  /// **'App Debug Log'**
  String get debugLog_appTitle;

  /// No description provided for @debugLog_bleTitle.
  ///
  /// In en, this message translates to:
  /// **'BLE Debug Log'**
  String get debugLog_bleTitle;

  /// No description provided for @debugLog_copyLog.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get debugLog_copyLog;

  /// No description provided for @debugLog_clearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get debugLog_clearLog;

  /// No description provided for @debugLog_copied.
  ///
  /// In en, this message translates to:
  /// **'Debug log copied'**
  String get debugLog_copied;

  /// No description provided for @debugLog_bleCopied.
  ///
  /// In en, this message translates to:
  /// **'BLE log copied'**
  String get debugLog_bleCopied;

  /// No description provided for @debugLog_noEntries.
  ///
  /// In en, this message translates to:
  /// **'No debug logs yet'**
  String get debugLog_noEntries;

  /// No description provided for @debugLog_enableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable app debug logging in settings'**
  String get debugLog_enableInSettings;

  /// No description provided for @debugLog_frames.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get debugLog_frames;

  /// No description provided for @debugLog_rawLogRx.
  ///
  /// In en, this message translates to:
  /// **'Raw Log-RX'**
  String get debugLog_rawLogRx;

  /// No description provided for @debugLog_noBleActivity.
  ///
  /// In en, this message translates to:
  /// **'No BLE activity yet'**
  String get debugLog_noBleActivity;

  /// No description provided for @debugFrame_length.
  ///
  /// In en, this message translates to:
  /// **'Frame Length: {count} bytes'**
  String debugFrame_length(int count);

  /// No description provided for @debugFrame_command.
  ///
  /// In en, this message translates to:
  /// **'Command: 0x{value}'**
  String debugFrame_command(String value);

  /// No description provided for @debugFrame_textMessageHeader.
  ///
  /// In en, this message translates to:
  /// **'Text Message Frame:'**
  String get debugFrame_textMessageHeader;

  /// No description provided for @debugFrame_destinationPubKey.
  ///
  /// In en, this message translates to:
  /// **'- Destination PubKey: {pubKey}'**
  String debugFrame_destinationPubKey(String pubKey);

  /// No description provided for @debugFrame_timestamp.
  ///
  /// In en, this message translates to:
  /// **'- Timestamp: {timestamp}'**
  String debugFrame_timestamp(int timestamp);

  /// No description provided for @debugFrame_flags.
  ///
  /// In en, this message translates to:
  /// **'- Flags: 0x{value}'**
  String debugFrame_flags(String value);

  /// No description provided for @debugFrame_textType.
  ///
  /// In en, this message translates to:
  /// **'- Text Type: {type} ({label})'**
  String debugFrame_textType(int type, String label);

  /// No description provided for @debugFrame_textTypeCli.
  ///
  /// In en, this message translates to:
  /// **'CLI'**
  String get debugFrame_textTypeCli;

  /// No description provided for @debugFrame_textTypePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get debugFrame_textTypePlain;

  /// No description provided for @debugFrame_text.
  ///
  /// In en, this message translates to:
  /// **'- Text: \"{text}\"'**
  String debugFrame_text(String text);

  /// No description provided for @debugFrame_hexDump.
  ///
  /// In en, this message translates to:
  /// **'Hex Dump:'**
  String get debugFrame_hexDump;

  /// No description provided for @chat_pathManagement.
  ///
  /// In en, this message translates to:
  /// **'Path Management'**
  String get chat_pathManagement;

  /// No description provided for @chat_ShowAllPaths.
  ///
  /// In en, this message translates to:
  /// **'Show all paths'**
  String get chat_ShowAllPaths;

  /// No description provided for @chat_routingMode.
  ///
  /// In en, this message translates to:
  /// **'Routing mode'**
  String get chat_routingMode;

  /// No description provided for @chat_autoUseSavedPath.
  ///
  /// In en, this message translates to:
  /// **'Auto (use saved path)'**
  String get chat_autoUseSavedPath;

  /// No description provided for @chat_forceFloodMode.
  ///
  /// In en, this message translates to:
  /// **'Force Flood Mode'**
  String get chat_forceFloodMode;

  /// No description provided for @chat_recentAckPaths.
  ///
  /// In en, this message translates to:
  /// **'Recent ACK Paths (tap to use):'**
  String get chat_recentAckPaths;

  /// No description provided for @chat_pathHistoryFull.
  ///
  /// In en, this message translates to:
  /// **'Path history is full. Remove entries to add new ones.'**
  String get chat_pathHistoryFull;

  /// No description provided for @chat_hopSingular.
  ///
  /// In en, this message translates to:
  /// **'hop'**
  String get chat_hopSingular;

  /// No description provided for @chat_hopPlural.
  ///
  /// In en, this message translates to:
  /// **'hops'**
  String get chat_hopPlural;

  /// No description provided for @chat_hopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{hop} other{hops}}'**
  String chat_hopsCount(int count);

  /// No description provided for @chat_successes.
  ///
  /// In en, this message translates to:
  /// **'successes'**
  String get chat_successes;

  /// No description provided for @chat_removePath.
  ///
  /// In en, this message translates to:
  /// **'Remove path'**
  String get chat_removePath;

  /// No description provided for @chat_noPathHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No path history yet.\nSend a message to discover paths.'**
  String get chat_noPathHistoryYet;

  /// No description provided for @chat_pathActions.
  ///
  /// In en, this message translates to:
  /// **'Path Actions:'**
  String get chat_pathActions;

  /// No description provided for @chat_setCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Path'**
  String get chat_setCustomPath;

  /// No description provided for @chat_setCustomPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually specify routing path'**
  String get chat_setCustomPathSubtitle;

  /// No description provided for @chat_clearPath.
  ///
  /// In en, this message translates to:
  /// **'Clear Path'**
  String get chat_clearPath;

  /// No description provided for @chat_clearPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Force rediscovery on next send'**
  String get chat_clearPathSubtitle;

  /// No description provided for @chat_pathCleared.
  ///
  /// In en, this message translates to:
  /// **'Path cleared. Next message will rediscover route.'**
  String get chat_pathCleared;

  /// No description provided for @chat_floodModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use routing toggle in app bar'**
  String get chat_floodModeSubtitle;

  /// No description provided for @chat_floodModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Flood mode enabled. Toggle back via routing icon in app bar.'**
  String get chat_floodModeEnabled;

  /// No description provided for @chat_fullPath.
  ///
  /// In en, this message translates to:
  /// **'Full Path'**
  String get chat_fullPath;

  /// No description provided for @chat_pathDetailsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Path details not available yet. Try sending a message to refresh.'**
  String get chat_pathDetailsNotAvailable;

  /// No description provided for @chat_pathSetHops.
  ///
  /// In en, this message translates to:
  /// **'Path set: {hopCount} {hopCount, plural, =1{hop} other{hops}} - {status}'**
  String chat_pathSetHops(int hopCount, String status);

  /// No description provided for @chat_pathSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Connect to sync.'**
  String get chat_pathSavedLocally;

  /// No description provided for @chat_pathDeviceConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Device confirmed.'**
  String get chat_pathDeviceConfirmed;

  /// No description provided for @chat_pathDeviceNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Device not confirmed yet.'**
  String get chat_pathDeviceNotConfirmed;

  /// No description provided for @chat_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get chat_type;

  /// No description provided for @chat_path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get chat_path;

  /// No description provided for @chat_publicKey.
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get chat_publicKey;

  /// No description provided for @chat_compressOutgoingMessages.
  ///
  /// In en, this message translates to:
  /// **'Compress outgoing messages'**
  String get chat_compressOutgoingMessages;

  /// No description provided for @chat_floodForced.
  ///
  /// In en, this message translates to:
  /// **'Flood (forced)'**
  String get chat_floodForced;

  /// No description provided for @chat_directForced.
  ///
  /// In en, this message translates to:
  /// **'Direct (forced)'**
  String get chat_directForced;

  /// No description provided for @chat_hopsForced.
  ///
  /// In en, this message translates to:
  /// **'{count} hops (forced)'**
  String chat_hopsForced(int count);

  /// No description provided for @chat_floodAuto.
  ///
  /// In en, this message translates to:
  /// **'Flood (auto)'**
  String get chat_floodAuto;

  /// No description provided for @chat_direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get chat_direct;

  /// No description provided for @chat_poiShared.
  ///
  /// In en, this message translates to:
  /// **'POI Shared'**
  String get chat_poiShared;

  /// No description provided for @chat_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread: {count}'**
  String chat_unread(int count);

  /// No description provided for @chat_openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link?'**
  String get chat_openLink;

  /// No description provided for @chat_openLinkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to open this link in your browser?'**
  String get chat_openLinkConfirmation;

  /// No description provided for @chat_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get chat_open;

  /// No description provided for @chat_couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link: {url}'**
  String chat_couldNotOpenLink(String url);

  /// No description provided for @chat_invalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid link format'**
  String get chat_invalidLink;

  /// No description provided for @map_title.
  ///
  /// In en, this message translates to:
  /// **'Node Map'**
  String get map_title;

  /// No description provided for @map_lineOfSight.
  ///
  /// In en, this message translates to:
  /// **'Line of Sight'**
  String get map_lineOfSight;

  /// No description provided for @map_losScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Line of Sight'**
  String get map_losScreenTitle;

  /// No description provided for @map_noNodesWithLocation.
  ///
  /// In en, this message translates to:
  /// **'No nodes with location data'**
  String get map_noNodesWithLocation;

  /// No description provided for @map_nodesNeedGps.
  ///
  /// In en, this message translates to:
  /// **'Nodes need to share their GPS coordinates\nto appear on the map'**
  String get map_nodesNeedGps;

  /// No description provided for @map_nodesCount.
  ///
  /// In en, this message translates to:
  /// **'Nodes: {count}'**
  String map_nodesCount(int count);

  /// No description provided for @map_pinsCount.
  ///
  /// In en, this message translates to:
  /// **'Pins: {count}'**
  String map_pinsCount(int count);

  /// No description provided for @map_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get map_chat;

  /// No description provided for @map_repeater.
  ///
  /// In en, this message translates to:
  /// **'Repeater'**
  String get map_repeater;

  /// No description provided for @map_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get map_room;

  /// No description provided for @map_sensor.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get map_sensor;

  /// No description provided for @map_pinDm.
  ///
  /// In en, this message translates to:
  /// **'Pin (DM)'**
  String get map_pinDm;

  /// No description provided for @map_pinPrivate.
  ///
  /// In en, this message translates to:
  /// **'Pin (Private)'**
  String get map_pinPrivate;

  /// No description provided for @map_pinPublic.
  ///
  /// In en, this message translates to:
  /// **'Pin (Public)'**
  String get map_pinPublic;

  /// No description provided for @map_lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get map_lastSeen;

  /// No description provided for @map_disconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect from this device?'**
  String get map_disconnectConfirm;

  /// No description provided for @map_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get map_from;

  /// No description provided for @map_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get map_source;

  /// No description provided for @map_flags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get map_flags;

  /// No description provided for @map_shareMarkerHere.
  ///
  /// In en, this message translates to:
  /// **'Share marker here'**
  String get map_shareMarkerHere;

  /// No description provided for @map_pinLabel.
  ///
  /// In en, this message translates to:
  /// **'Pin label'**
  String get map_pinLabel;

  /// No description provided for @map_label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get map_label;

  /// No description provided for @map_pointOfInterest.
  ///
  /// In en, this message translates to:
  /// **'Point of interest'**
  String get map_pointOfInterest;

  /// No description provided for @map_sendToContact.
  ///
  /// In en, this message translates to:
  /// **'Send to contact'**
  String get map_sendToContact;

  /// No description provided for @map_sendToChannel.
  ///
  /// In en, this message translates to:
  /// **'Send to channel'**
  String get map_sendToChannel;

  /// No description provided for @map_noChannelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No channels available'**
  String get map_noChannelsAvailable;

  /// No description provided for @map_publicLocationShare.
  ///
  /// In en, this message translates to:
  /// **'Public location share'**
  String get map_publicLocationShare;

  /// No description provided for @map_publicLocationShareConfirm.
  ///
  /// In en, this message translates to:
  /// **'You are about to share a location in {channelLabel}. This channel is public and anyone with the PSK can see it.'**
  String map_publicLocationShareConfirm(String channelLabel);

  /// No description provided for @map_connectToShareMarkers.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device to share markers'**
  String get map_connectToShareMarkers;

  /// No description provided for @map_filterNodes.
  ///
  /// In en, this message translates to:
  /// **'Filter Nodes'**
  String get map_filterNodes;

  /// No description provided for @map_nodeTypes.
  ///
  /// In en, this message translates to:
  /// **'Node Types'**
  String get map_nodeTypes;

  /// No description provided for @map_chatNodes.
  ///
  /// In en, this message translates to:
  /// **'Chat Nodes'**
  String get map_chatNodes;

  /// No description provided for @map_repeaters.
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get map_repeaters;

  /// No description provided for @map_otherNodes.
  ///
  /// In en, this message translates to:
  /// **'Other Nodes'**
  String get map_otherNodes;

  /// No description provided for @map_keyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Key Prefix'**
  String get map_keyPrefix;

  /// No description provided for @map_filterByKeyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Filter by key prefix'**
  String get map_filterByKeyPrefix;

  /// No description provided for @map_publicKeyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Public key prefix'**
  String get map_publicKeyPrefix;

  /// No description provided for @map_markers.
  ///
  /// In en, this message translates to:
  /// **'Markers'**
  String get map_markers;

  /// No description provided for @map_showSharedMarkers.
  ///
  /// In en, this message translates to:
  /// **'Show shared markers'**
  String get map_showSharedMarkers;

  /// No description provided for @map_showGuessedLocations.
  ///
  /// In en, this message translates to:
  /// **'Show guessed node locations'**
  String get map_showGuessedLocations;

  /// No description provided for @map_showDiscoveryContacts.
  ///
  /// In en, this message translates to:
  /// **'Show Discovery Contacts'**
  String get map_showDiscoveryContacts;

  /// No description provided for @map_guessedLocation.
  ///
  /// In en, this message translates to:
  /// **'Guessed location'**
  String get map_guessedLocation;

  /// No description provided for @map_lastSeenTime.
  ///
  /// In en, this message translates to:
  /// **'Last Seen Time'**
  String get map_lastSeenTime;

  /// No description provided for @map_sharedPin.
  ///
  /// In en, this message translates to:
  /// **'Shared pin'**
  String get map_sharedPin;

  /// No description provided for @map_joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get map_joinRoom;

  /// No description provided for @map_manageRepeater.
  ///
  /// In en, this message translates to:
  /// **'Manage Repeater'**
  String get map_manageRepeater;

  /// No description provided for @map_tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap on nodes to add them to the path.'**
  String get map_tapToAdd;

  /// No description provided for @map_runTrace.
  ///
  /// In en, this message translates to:
  /// **'Run Path Trace'**
  String get map_runTrace;

  /// No description provided for @map_removeLast.
  ///
  /// In en, this message translates to:
  /// **'Remove Last'**
  String get map_removeLast;

  /// No description provided for @map_pathTraceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Path trace cancelled.'**
  String get map_pathTraceCancelled;

  /// No description provided for @mapCache_title.
  ///
  /// In en, this message translates to:
  /// **'Offline Map Cache'**
  String get mapCache_title;

  /// No description provided for @mapCache_selectAreaFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an area to cache first'**
  String get mapCache_selectAreaFirst;

  /// No description provided for @mapCache_noTilesToDownload.
  ///
  /// In en, this message translates to:
  /// **'No tiles to download for this area'**
  String get mapCache_noTilesToDownload;

  /// No description provided for @mapCache_downloadTilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Download tiles'**
  String get mapCache_downloadTilesTitle;

  /// No description provided for @mapCache_downloadTilesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Download {count} tiles for offline use?'**
  String mapCache_downloadTilesPrompt(int count);

  /// No description provided for @mapCache_downloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get mapCache_downloadAction;

  /// No description provided for @mapCache_cachedTiles.
  ///
  /// In en, this message translates to:
  /// **'Cached {count} tiles'**
  String mapCache_cachedTiles(int count);

  /// No description provided for @mapCache_cachedTilesWithFailed.
  ///
  /// In en, this message translates to:
  /// **'Cached {downloaded} tiles ({failed} failed)'**
  String mapCache_cachedTilesWithFailed(int downloaded, int failed);

  /// No description provided for @mapCache_clearOfflineCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear offline cache'**
  String get mapCache_clearOfflineCacheTitle;

  /// No description provided for @mapCache_clearOfflineCachePrompt.
  ///
  /// In en, this message translates to:
  /// **'Remove all cached map tiles?'**
  String get mapCache_clearOfflineCachePrompt;

  /// No description provided for @mapCache_offlineCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Offline cache cleared'**
  String get mapCache_offlineCacheCleared;

  /// No description provided for @mapCache_noAreaSelected.
  ///
  /// In en, this message translates to:
  /// **'No area selected'**
  String get mapCache_noAreaSelected;

  /// No description provided for @mapCache_cacheArea.
  ///
  /// In en, this message translates to:
  /// **'Cache Area'**
  String get mapCache_cacheArea;

  /// No description provided for @mapCache_useCurrentView.
  ///
  /// In en, this message translates to:
  /// **'Use Current View'**
  String get mapCache_useCurrentView;

  /// No description provided for @mapCache_zoomRange.
  ///
  /// In en, this message translates to:
  /// **'Zoom Range'**
  String get mapCache_zoomRange;

  /// No description provided for @mapCache_estimatedTiles.
  ///
  /// In en, this message translates to:
  /// **'Estimated tiles: {count}'**
  String mapCache_estimatedTiles(int count);

  /// No description provided for @mapCache_downloadedTiles.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {completed} / {total}'**
  String mapCache_downloadedTiles(int completed, int total);

  /// No description provided for @mapCache_downloadTilesButton.
  ///
  /// In en, this message translates to:
  /// **'Download Tiles'**
  String get mapCache_downloadTilesButton;

  /// No description provided for @mapCache_clearCacheButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get mapCache_clearCacheButton;

  /// No description provided for @mapCache_failedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed downloads: {count}'**
  String mapCache_failedDownloads(int count);

  /// No description provided for @mapCache_boundsLabel.
  ///
  /// In en, this message translates to:
  /// **'N {north}, S {south}, E {east}, W {west}'**
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  );

  /// No description provided for @time_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get time_justNow;

  /// No description provided for @time_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String time_minutesAgo(int minutes);

  /// No description provided for @time_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String time_hoursAgo(int hours);

  /// No description provided for @time_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String time_daysAgo(int days);

  /// No description provided for @time_hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get time_hour;

  /// No description provided for @time_hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get time_hours;

  /// No description provided for @time_day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get time_day;

  /// No description provided for @time_days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get time_days;

  /// No description provided for @time_week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get time_week;

  /// No description provided for @time_weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get time_weeks;

  /// No description provided for @time_month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get time_month;

  /// No description provided for @time_months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get time_months;

  /// No description provided for @time_minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get time_minutes;

  /// No description provided for @time_allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get time_allTime;

  /// No description provided for @dialog_disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get dialog_disconnect;

  /// No description provided for @dialog_disconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect from this device?'**
  String get dialog_disconnectConfirm;

  /// No description provided for @login_repeaterLogin.
  ///
  /// In en, this message translates to:
  /// **'Repeater Login'**
  String get login_repeaterLogin;

  /// No description provided for @login_roomLogin.
  ///
  /// In en, this message translates to:
  /// **'Room Server Login'**
  String get login_roomLogin;

  /// No description provided for @login_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password;

  /// No description provided for @login_enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get login_enterPassword;

  /// No description provided for @login_savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get login_savePassword;

  /// No description provided for @login_savePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Password will be stored securely on this device'**
  String get login_savePasswordSubtitle;

  /// No description provided for @login_repeaterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the repeater password to access settings and status.'**
  String get login_repeaterDescription;

  /// No description provided for @login_roomDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the room password to access settings and status.'**
  String get login_roomDescription;

  /// No description provided for @login_routing.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get login_routing;

  /// No description provided for @login_routingMode.
  ///
  /// In en, this message translates to:
  /// **'Routing mode'**
  String get login_routingMode;

  /// No description provided for @login_autoUseSavedPath.
  ///
  /// In en, this message translates to:
  /// **'Auto (use saved path)'**
  String get login_autoUseSavedPath;

  /// No description provided for @login_forceFloodMode.
  ///
  /// In en, this message translates to:
  /// **'Force Flood Mode'**
  String get login_forceFloodMode;

  /// No description provided for @login_managePaths.
  ///
  /// In en, this message translates to:
  /// **'Manage Paths'**
  String get login_managePaths;

  /// No description provided for @login_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_login;

  /// No description provided for @login_attempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {current}/{max}'**
  String login_attempt(int current, int max);

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String login_failed(String error);

  /// No description provided for @login_failedMessage.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Either the password is incorrect or the repeater is unreachable.'**
  String get login_failedMessage;

  /// No description provided for @common_reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get common_reload;

  /// No description provided for @common_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear;

  /// No description provided for @path_currentPath.
  ///
  /// In en, this message translates to:
  /// **'Current path: {path}'**
  String path_currentPath(String path);

  /// No description provided for @path_usingHopsPath.
  ///
  /// In en, this message translates to:
  /// **'Using {count} {count, plural, =1{hop} other{hops}} path'**
  String path_usingHopsPath(int count);

  /// No description provided for @path_enterCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Enter Custom Path'**
  String get path_enterCustomPath;

  /// No description provided for @path_currentPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Current path'**
  String get path_currentPathLabel;

  /// No description provided for @path_hexPrefixInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter 2-character hex prefixes for each hop, separated by commas.'**
  String get path_hexPrefixInstructions;

  /// No description provided for @path_hexPrefixExample.
  ///
  /// In en, this message translates to:
  /// **'Example: A1,F2,3C (each node uses first byte of its public key)'**
  String get path_hexPrefixExample;

  /// No description provided for @path_labelHexPrefixes.
  ///
  /// In en, this message translates to:
  /// **'Path (hex prefixes)'**
  String get path_labelHexPrefixes;

  /// No description provided for @path_helperMaxHops.
  ///
  /// In en, this message translates to:
  /// **'Max 64 hops. Each prefix is 2 hex characters (1 byte)'**
  String get path_helperMaxHops;

  /// No description provided for @path_selectFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Or select from contacts:'**
  String get path_selectFromContacts;

  /// No description provided for @path_noRepeatersFound.
  ///
  /// In en, this message translates to:
  /// **'No repeaters or room servers found.'**
  String get path_noRepeatersFound;

  /// No description provided for @path_customPathsRequire.
  ///
  /// In en, this message translates to:
  /// **'Custom paths require intermediate hops that can relay messages.'**
  String get path_customPathsRequire;

  /// No description provided for @path_invalidHexPrefixes.
  ///
  /// In en, this message translates to:
  /// **'Invalid hex prefixes: {prefixes}'**
  String path_invalidHexPrefixes(String prefixes);

  /// No description provided for @path_tooLong.
  ///
  /// In en, this message translates to:
  /// **'Path too long. Maximum 64 hops allowed.'**
  String get path_tooLong;

  /// No description provided for @path_setPath.
  ///
  /// In en, this message translates to:
  /// **'Set Path'**
  String get path_setPath;

  /// No description provided for @repeater_management.
  ///
  /// In en, this message translates to:
  /// **'Repeater Management'**
  String get repeater_management;

  /// No description provided for @room_management.
  ///
  /// In en, this message translates to:
  /// **'Room Server Management'**
  String get room_management;

  /// No description provided for @repeater_managementTools.
  ///
  /// In en, this message translates to:
  /// **'Management Tools'**
  String get repeater_managementTools;

  /// No description provided for @repeater_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get repeater_status;

  /// No description provided for @repeater_statusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View repeater status, stats, and neighbors'**
  String get repeater_statusSubtitle;

  /// No description provided for @repeater_telemetry.
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get repeater_telemetry;

  /// No description provided for @repeater_telemetrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View telemetry of sensors and system stats'**
  String get repeater_telemetrySubtitle;

  /// No description provided for @repeater_cli.
  ///
  /// In en, this message translates to:
  /// **'CLI'**
  String get repeater_cli;

  /// No description provided for @repeater_cliSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send commands to the repeater'**
  String get repeater_cliSubtitle;

  /// No description provided for @repeater_neighbors.
  ///
  /// In en, this message translates to:
  /// **'Neighbors'**
  String get repeater_neighbors;

  /// No description provided for @repeater_neighborsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View zero hop neighbors.'**
  String get repeater_neighborsSubtitle;

  /// No description provided for @repeater_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get repeater_settings;

  /// No description provided for @repeater_settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure repeater parameters'**
  String get repeater_settingsSubtitle;

  /// No description provided for @repeater_statusTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeater Status'**
  String get repeater_statusTitle;

  /// No description provided for @repeater_routingMode.
  ///
  /// In en, this message translates to:
  /// **'Routing mode'**
  String get repeater_routingMode;

  /// No description provided for @repeater_autoUseSavedPath.
  ///
  /// In en, this message translates to:
  /// **'Auto (use saved path)'**
  String get repeater_autoUseSavedPath;

  /// No description provided for @repeater_forceFloodMode.
  ///
  /// In en, this message translates to:
  /// **'Force Flood Mode'**
  String get repeater_forceFloodMode;

  /// No description provided for @repeater_pathManagement.
  ///
  /// In en, this message translates to:
  /// **'Path management'**
  String get repeater_pathManagement;

  /// No description provided for @repeater_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get repeater_refresh;

  /// No description provided for @repeater_statusRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Status request timed out.'**
  String get repeater_statusRequestTimeout;

  /// No description provided for @repeater_errorLoadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error loading status: {error}'**
  String repeater_errorLoadingStatus(String error);

  /// No description provided for @repeater_systemInformation.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get repeater_systemInformation;

  /// No description provided for @repeater_battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get repeater_battery;

  /// No description provided for @repeater_clockAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Clock (at login)'**
  String get repeater_clockAtLogin;

  /// No description provided for @repeater_uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get repeater_uptime;

  /// No description provided for @repeater_queueLength.
  ///
  /// In en, this message translates to:
  /// **'Queue Length'**
  String get repeater_queueLength;

  /// No description provided for @repeater_debugFlags.
  ///
  /// In en, this message translates to:
  /// **'Debug Flags'**
  String get repeater_debugFlags;

  /// No description provided for @repeater_radioStatistics.
  ///
  /// In en, this message translates to:
  /// **'Radio Statistics'**
  String get repeater_radioStatistics;

  /// No description provided for @repeater_lastRssi.
  ///
  /// In en, this message translates to:
  /// **'Last RSSI'**
  String get repeater_lastRssi;

  /// No description provided for @repeater_lastSnr.
  ///
  /// In en, this message translates to:
  /// **'Last SNR'**
  String get repeater_lastSnr;

  /// No description provided for @repeater_noiseFloor.
  ///
  /// In en, this message translates to:
  /// **'Noise Floor'**
  String get repeater_noiseFloor;

  /// No description provided for @repeater_txAirtime.
  ///
  /// In en, this message translates to:
  /// **'TX Airtime'**
  String get repeater_txAirtime;

  /// No description provided for @repeater_rxAirtime.
  ///
  /// In en, this message translates to:
  /// **'RX Airtime'**
  String get repeater_rxAirtime;

  /// No description provided for @repeater_packetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Packet Statistics'**
  String get repeater_packetStatistics;

  /// No description provided for @repeater_sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get repeater_sent;

  /// No description provided for @repeater_received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get repeater_received;

  /// No description provided for @repeater_duplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get repeater_duplicates;

  /// No description provided for @repeater_daysHoursMinsSecs.
  ///
  /// In en, this message translates to:
  /// **'{days} days {hours}h {minutes}m {seconds}s'**
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  );

  /// No description provided for @repeater_packetTxTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}, Flood: {flood}, Direct: {direct}'**
  String repeater_packetTxTotal(int total, String flood, String direct);

  /// No description provided for @repeater_packetRxTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}, Flood: {flood}, Direct: {direct}'**
  String repeater_packetRxTotal(int total, String flood, String direct);

  /// No description provided for @repeater_duplicatesFloodDirect.
  ///
  /// In en, this message translates to:
  /// **'Flood: {flood}, Direct: {direct}'**
  String repeater_duplicatesFloodDirect(String flood, String direct);

  /// No description provided for @repeater_duplicatesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String repeater_duplicatesTotal(int total);

  /// No description provided for @repeater_settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeater Settings'**
  String get repeater_settingsTitle;

  /// No description provided for @repeater_basicSettings.
  ///
  /// In en, this message translates to:
  /// **'Basic Settings'**
  String get repeater_basicSettings;

  /// No description provided for @repeater_repeaterName.
  ///
  /// In en, this message translates to:
  /// **'Repeater Name'**
  String get repeater_repeaterName;

  /// No description provided for @repeater_repeaterNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Display name for this repeater'**
  String get repeater_repeaterNameHelper;

  /// No description provided for @repeater_adminPassword.
  ///
  /// In en, this message translates to:
  /// **'Admin Password'**
  String get repeater_adminPassword;

  /// No description provided for @repeater_adminPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Full access password'**
  String get repeater_adminPasswordHelper;

  /// No description provided for @repeater_guestPassword.
  ///
  /// In en, this message translates to:
  /// **'Guest Password'**
  String get repeater_guestPassword;

  /// No description provided for @repeater_guestPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Read-only access password'**
  String get repeater_guestPasswordHelper;

  /// No description provided for @repeater_radioSettings.
  ///
  /// In en, this message translates to:
  /// **'Radio Settings'**
  String get repeater_radioSettings;

  /// No description provided for @repeater_frequencyMhz.
  ///
  /// In en, this message translates to:
  /// **'Frequency (MHz)'**
  String get repeater_frequencyMhz;

  /// No description provided for @repeater_frequencyHelper.
  ///
  /// In en, this message translates to:
  /// **'300-2500 MHz'**
  String get repeater_frequencyHelper;

  /// No description provided for @repeater_txPower.
  ///
  /// In en, this message translates to:
  /// **'TX Power'**
  String get repeater_txPower;

  /// No description provided for @repeater_txPowerHelper.
  ///
  /// In en, this message translates to:
  /// **'1-30 dBm'**
  String get repeater_txPowerHelper;

  /// No description provided for @repeater_bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get repeater_bandwidth;

  /// No description provided for @repeater_spreadingFactor.
  ///
  /// In en, this message translates to:
  /// **'Spreading Factor'**
  String get repeater_spreadingFactor;

  /// No description provided for @repeater_codingRate.
  ///
  /// In en, this message translates to:
  /// **'Coding Rate'**
  String get repeater_codingRate;

  /// No description provided for @repeater_locationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get repeater_locationSettings;

  /// No description provided for @repeater_latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get repeater_latitude;

  /// No description provided for @repeater_latitudeHelper.
  ///
  /// In en, this message translates to:
  /// **'Decimal degrees (e.g., 37.7749)'**
  String get repeater_latitudeHelper;

  /// No description provided for @repeater_longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get repeater_longitude;

  /// No description provided for @repeater_longitudeHelper.
  ///
  /// In en, this message translates to:
  /// **'Decimal degrees (e.g., -122.4194)'**
  String get repeater_longitudeHelper;

  /// No description provided for @repeater_features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get repeater_features;

  /// No description provided for @repeater_packetForwarding.
  ///
  /// In en, this message translates to:
  /// **'Packet Forwarding'**
  String get repeater_packetForwarding;

  /// No description provided for @repeater_packetForwardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable repeater to forward packets'**
  String get repeater_packetForwardingSubtitle;

  /// No description provided for @repeater_guestAccess.
  ///
  /// In en, this message translates to:
  /// **'Guest Access'**
  String get repeater_guestAccess;

  /// No description provided for @repeater_guestAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow read-only guest access'**
  String get repeater_guestAccessSubtitle;

  /// No description provided for @repeater_privacyMode.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode'**
  String get repeater_privacyMode;

  /// No description provided for @repeater_privacyModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide name/location in advertisements'**
  String get repeater_privacyModeSubtitle;

  /// No description provided for @repeater_advertisementSettings.
  ///
  /// In en, this message translates to:
  /// **'Advertisement Settings'**
  String get repeater_advertisementSettings;

  /// No description provided for @repeater_localAdvertInterval.
  ///
  /// In en, this message translates to:
  /// **'Local Advertisement Interval'**
  String get repeater_localAdvertInterval;

  /// No description provided for @repeater_localAdvertIntervalMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String repeater_localAdvertIntervalMinutes(int minutes);

  /// No description provided for @repeater_floodAdvertInterval.
  ///
  /// In en, this message translates to:
  /// **'Flood Advertisement Interval'**
  String get repeater_floodAdvertInterval;

  /// No description provided for @repeater_floodAdvertIntervalHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String repeater_floodAdvertIntervalHours(int hours);

  /// No description provided for @repeater_encryptedAdvertInterval.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Advertisement Interval'**
  String get repeater_encryptedAdvertInterval;

  /// No description provided for @repeater_dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get repeater_dangerZone;

  /// No description provided for @repeater_rebootRepeater.
  ///
  /// In en, this message translates to:
  /// **'Reboot Repeater'**
  String get repeater_rebootRepeater;

  /// No description provided for @repeater_rebootRepeaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restart the repeater device'**
  String get repeater_rebootRepeaterSubtitle;

  /// No description provided for @repeater_rebootRepeaterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reboot this repeater?'**
  String get repeater_rebootRepeaterConfirm;

  /// No description provided for @repeater_regenerateIdentityKey.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Identity Key'**
  String get repeater_regenerateIdentityKey;

  /// No description provided for @repeater_regenerateIdentityKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate new public/private key pair'**
  String get repeater_regenerateIdentityKeySubtitle;

  /// No description provided for @repeater_regenerateIdentityKeyConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will generate a new identity for the repeater. Continue?'**
  String get repeater_regenerateIdentityKeyConfirm;

  /// No description provided for @repeater_eraseFileSystem.
  ///
  /// In en, this message translates to:
  /// **'Erase File System'**
  String get repeater_eraseFileSystem;

  /// No description provided for @repeater_eraseFileSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Format the repeater file system'**
  String get repeater_eraseFileSystemSubtitle;

  /// No description provided for @repeater_eraseFileSystemConfirm.
  ///
  /// In en, this message translates to:
  /// **'WARNING: This will erase all data on the repeater. This cannot be undone!'**
  String get repeater_eraseFileSystemConfirm;

  /// No description provided for @repeater_eraseSerialOnly.
  ///
  /// In en, this message translates to:
  /// **'Erase is only available over serial console.'**
  String get repeater_eraseSerialOnly;

  /// No description provided for @repeater_commandSent.
  ///
  /// In en, this message translates to:
  /// **'Command sent: {command}'**
  String repeater_commandSent(String command);

  /// No description provided for @repeater_errorSendingCommand.
  ///
  /// In en, this message translates to:
  /// **'Error sending command: {error}'**
  String repeater_errorSendingCommand(String error);

  /// No description provided for @repeater_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get repeater_confirm;

  /// No description provided for @repeater_settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get repeater_settingsSaved;

  /// No description provided for @repeater_errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String repeater_errorSavingSettings(String error);

  /// No description provided for @repeater_refreshBasicSettings.
  ///
  /// In en, this message translates to:
  /// **'Refresh Basic Settings'**
  String get repeater_refreshBasicSettings;

  /// No description provided for @repeater_refreshRadioSettings.
  ///
  /// In en, this message translates to:
  /// **'Refresh Radio Settings'**
  String get repeater_refreshRadioSettings;

  /// No description provided for @repeater_refreshTxPower.
  ///
  /// In en, this message translates to:
  /// **'Refresh TX power'**
  String get repeater_refreshTxPower;

  /// No description provided for @repeater_refreshLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Refresh Location Settings'**
  String get repeater_refreshLocationSettings;

  /// No description provided for @repeater_refreshPacketForwarding.
  ///
  /// In en, this message translates to:
  /// **'Refresh Packet Forwarding'**
  String get repeater_refreshPacketForwarding;

  /// No description provided for @repeater_refreshGuestAccess.
  ///
  /// In en, this message translates to:
  /// **'Refresh Guest Access'**
  String get repeater_refreshGuestAccess;

  /// No description provided for @repeater_refreshPrivacyMode.
  ///
  /// In en, this message translates to:
  /// **'Refresh Privacy Mode'**
  String get repeater_refreshPrivacyMode;

  /// No description provided for @repeater_refreshAdvertisementSettings.
  ///
  /// In en, this message translates to:
  /// **'Refresh Advertisement Settings'**
  String get repeater_refreshAdvertisementSettings;

  /// No description provided for @repeater_refreshed.
  ///
  /// In en, this message translates to:
  /// **'{label} refreshed'**
  String repeater_refreshed(String label);

  /// No description provided for @repeater_errorRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing {label}'**
  String repeater_errorRefreshing(String label);

  /// No description provided for @repeater_cliTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeater CLI'**
  String get repeater_cliTitle;

  /// No description provided for @repeater_debugNextCommand.
  ///
  /// In en, this message translates to:
  /// **'Debug Next Command'**
  String get repeater_debugNextCommand;

  /// No description provided for @repeater_commandHelp.
  ///
  /// In en, this message translates to:
  /// **'Command Help'**
  String get repeater_commandHelp;

  /// No description provided for @repeater_clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get repeater_clearHistory;

  /// No description provided for @repeater_noCommandsSent.
  ///
  /// In en, this message translates to:
  /// **'No commands sent yet'**
  String get repeater_noCommandsSent;

  /// No description provided for @repeater_typeCommandOrUseQuick.
  ///
  /// In en, this message translates to:
  /// **'Type a command below or use quick commands'**
  String get repeater_typeCommandOrUseQuick;

  /// No description provided for @repeater_enterCommandHint.
  ///
  /// In en, this message translates to:
  /// **'Enter command...'**
  String get repeater_enterCommandHint;

  /// No description provided for @repeater_previousCommand.
  ///
  /// In en, this message translates to:
  /// **'Previous command'**
  String get repeater_previousCommand;

  /// No description provided for @repeater_nextCommand.
  ///
  /// In en, this message translates to:
  /// **'Next command'**
  String get repeater_nextCommand;

  /// No description provided for @repeater_enterCommandFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter a command first'**
  String get repeater_enterCommandFirst;

  /// No description provided for @repeater_cliCommandFrameTitle.
  ///
  /// In en, this message translates to:
  /// **'CLI Command Frame'**
  String get repeater_cliCommandFrameTitle;

  /// No description provided for @repeater_cliCommandError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String repeater_cliCommandError(String error);

  /// No description provided for @repeater_cliQuickGetName.
  ///
  /// In en, this message translates to:
  /// **'Get Name'**
  String get repeater_cliQuickGetName;

  /// No description provided for @repeater_cliQuickGetRadio.
  ///
  /// In en, this message translates to:
  /// **'Get Radio'**
  String get repeater_cliQuickGetRadio;

  /// No description provided for @repeater_cliQuickGetTx.
  ///
  /// In en, this message translates to:
  /// **'Get TX'**
  String get repeater_cliQuickGetTx;

  /// No description provided for @repeater_cliQuickNeighbors.
  ///
  /// In en, this message translates to:
  /// **'Neighbors'**
  String get repeater_cliQuickNeighbors;

  /// No description provided for @repeater_cliQuickVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get repeater_cliQuickVersion;

  /// No description provided for @repeater_cliQuickAdvertise.
  ///
  /// In en, this message translates to:
  /// **'Advertise'**
  String get repeater_cliQuickAdvertise;

  /// No description provided for @repeater_cliQuickClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get repeater_cliQuickClock;

  /// No description provided for @repeater_cliHelpAdvert.
  ///
  /// In en, this message translates to:
  /// **'Sends an advertisement packet'**
  String get repeater_cliHelpAdvert;

  /// No description provided for @repeater_cliHelpReboot.
  ///
  /// In en, this message translates to:
  /// **'Reboots the device. (note, you\'ll prob get \'Timeout\' which is normal)'**
  String get repeater_cliHelpReboot;

  /// No description provided for @repeater_cliHelpClock.
  ///
  /// In en, this message translates to:
  /// **'Displays current time per device\'s clock.'**
  String get repeater_cliHelpClock;

  /// No description provided for @repeater_cliHelpPassword.
  ///
  /// In en, this message translates to:
  /// **'Sets a new admin password for the device.'**
  String get repeater_cliHelpPassword;

  /// No description provided for @repeater_cliHelpVersion.
  ///
  /// In en, this message translates to:
  /// **'Shows the device version and firmware build date.'**
  String get repeater_cliHelpVersion;

  /// No description provided for @repeater_cliHelpClearStats.
  ///
  /// In en, this message translates to:
  /// **'Resets various stats counters to zero.'**
  String get repeater_cliHelpClearStats;

  /// No description provided for @repeater_cliHelpSetAf.
  ///
  /// In en, this message translates to:
  /// **'Sets the air-time-factor.'**
  String get repeater_cliHelpSetAf;

  /// No description provided for @repeater_cliHelpSetTx.
  ///
  /// In en, this message translates to:
  /// **'Sets LoRa transmit power in dBm. (reboot to apply)'**
  String get repeater_cliHelpSetTx;

  /// No description provided for @repeater_cliHelpSetRepeat.
  ///
  /// In en, this message translates to:
  /// **'Enables or disables the repeater role for this node.'**
  String get repeater_cliHelpSetRepeat;

  /// No description provided for @repeater_cliHelpSetAllowReadOnly.
  ///
  /// In en, this message translates to:
  /// **'(Room server) If \'on\', then login in blank password will be allowed, but cannot Post to room. (just read only)'**
  String get repeater_cliHelpSetAllowReadOnly;

  /// No description provided for @repeater_cliHelpSetFloodMax.
  ///
  /// In en, this message translates to:
  /// **'Sets the maximum number of hops of inbound flood packet (if >= max, packet is not forwarded)'**
  String get repeater_cliHelpSetFloodMax;

  /// No description provided for @repeater_cliHelpSetIntThresh.
  ///
  /// In en, this message translates to:
  /// **'Sets the Interference Threshold (in DB). Default is 14. Set to 0 to disable channel interference detection.'**
  String get repeater_cliHelpSetIntThresh;

  /// No description provided for @repeater_cliHelpSetAgcResetInterval.
  ///
  /// In en, this message translates to:
  /// **'Sets the interval to reset the Auto Gain Controller. Set to 0 to disable.'**
  String get repeater_cliHelpSetAgcResetInterval;

  /// No description provided for @repeater_cliHelpSetMultiAcks.
  ///
  /// In en, this message translates to:
  /// **'Enables or disables the \'double ACKs\' feature.'**
  String get repeater_cliHelpSetMultiAcks;

  /// No description provided for @repeater_cliHelpSetAdvertInterval.
  ///
  /// In en, this message translates to:
  /// **'Sets the timer interval in minutes to send a local (zero-hop) advertisement packet. Set to 0 to disable.'**
  String get repeater_cliHelpSetAdvertInterval;

  /// No description provided for @repeater_cliHelpSetFloodAdvertInterval.
  ///
  /// In en, this message translates to:
  /// **'Sets the timer interval in hours to send a flood advertisement packet. Set to 0 to disable.'**
  String get repeater_cliHelpSetFloodAdvertInterval;

  /// No description provided for @repeater_cliHelpSetGuestPassword.
  ///
  /// In en, this message translates to:
  /// **'Sets/updates the guest password. (for repeaters, guest logins can send the \"Get Stats\" request)'**
  String get repeater_cliHelpSetGuestPassword;

  /// No description provided for @repeater_cliHelpSetName.
  ///
  /// In en, this message translates to:
  /// **'Sets the advertisement name.'**
  String get repeater_cliHelpSetName;

  /// No description provided for @repeater_cliHelpSetLat.
  ///
  /// In en, this message translates to:
  /// **'Sets the advertisement map latitude. (decimal degrees)'**
  String get repeater_cliHelpSetLat;

  /// No description provided for @repeater_cliHelpSetLon.
  ///
  /// In en, this message translates to:
  /// **'Sets the advertisement map longitude. (decimal degrees)'**
  String get repeater_cliHelpSetLon;

  /// No description provided for @repeater_cliHelpSetRadio.
  ///
  /// In en, this message translates to:
  /// **'Sets completely new radio params, and saves to preferences. Requires a \"reboot\" command to apply.'**
  String get repeater_cliHelpSetRadio;

  /// No description provided for @repeater_cliHelpSetRxDelay.
  ///
  /// In en, this message translates to:
  /// **'Sets (experimental) base (must be > 1 for effect) for applying slight delay to received packets, based on signal strength/score. Set to 0 to disable.'**
  String get repeater_cliHelpSetRxDelay;

  /// No description provided for @repeater_cliHelpSetTxDelay.
  ///
  /// In en, this message translates to:
  /// **'Sets a factor multiplied with time-on-air for a flood-mode packet and with a randomized slot system, to delay its forwarding. (to decrease likelihood of collisions)'**
  String get repeater_cliHelpSetTxDelay;

  /// No description provided for @repeater_cliHelpSetDirectTxDelay.
  ///
  /// In en, this message translates to:
  /// **'Same as txdelay, but for applying a random delay to the forwarding of direct-mode packets.'**
  String get repeater_cliHelpSetDirectTxDelay;

  /// No description provided for @repeater_cliHelpSetBridgeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable/Disable bridge.'**
  String get repeater_cliHelpSetBridgeEnabled;

  /// No description provided for @repeater_cliHelpSetBridgeDelay.
  ///
  /// In en, this message translates to:
  /// **'Set delay before retransmitting packets.'**
  String get repeater_cliHelpSetBridgeDelay;

  /// No description provided for @repeater_cliHelpSetBridgeSource.
  ///
  /// In en, this message translates to:
  /// **'Choose wether the bridge will retransmit received packets or transmitted packets.'**
  String get repeater_cliHelpSetBridgeSource;

  /// No description provided for @repeater_cliHelpSetBridgeBaud.
  ///
  /// In en, this message translates to:
  /// **'Set serial link baudrate for rs232 bridges.'**
  String get repeater_cliHelpSetBridgeBaud;

  /// No description provided for @repeater_cliHelpSetBridgeSecret.
  ///
  /// In en, this message translates to:
  /// **'Set bridge secret for espnow bridges.'**
  String get repeater_cliHelpSetBridgeSecret;

  /// No description provided for @repeater_cliHelpSetAdcMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Sets custom factor to adjust reported battery voltage (only supported on select boards).'**
  String get repeater_cliHelpSetAdcMultiplier;

  /// No description provided for @repeater_cliHelpTempRadio.
  ///
  /// In en, this message translates to:
  /// **'Sets temporary radio params for the given number of minutes, reverting to original radio params afterward. (does NOT save to preferences).'**
  String get repeater_cliHelpTempRadio;

  /// No description provided for @repeater_cliHelpSetPerm.
  ///
  /// In en, this message translates to:
  /// **'Modifies the ACL. Removes matching entry (by pubkey prefix) if \"permissions\" is zero. Adds new entry if pubkey-hex is full length and is not currently in ACL. Updates entry by matching pubkey prefix. Permission bits vary per firmware role, but low 2 bits are: 0 (Guest), 1 (Read only), 2 (Read write), 3 (Admin)'**
  String get repeater_cliHelpSetPerm;

  /// No description provided for @repeater_cliHelpGetBridgeType.
  ///
  /// In en, this message translates to:
  /// **'Gets bridge type none, rs232, espnow'**
  String get repeater_cliHelpGetBridgeType;

  /// No description provided for @repeater_cliHelpLogStart.
  ///
  /// In en, this message translates to:
  /// **'Starts packet logging to file system.'**
  String get repeater_cliHelpLogStart;

  /// No description provided for @repeater_cliHelpLogStop.
  ///
  /// In en, this message translates to:
  /// **'Stops packet logging to file system.'**
  String get repeater_cliHelpLogStop;

  /// No description provided for @repeater_cliHelpLogErase.
  ///
  /// In en, this message translates to:
  /// **'Erases the packet logs from file system.'**
  String get repeater_cliHelpLogErase;

  /// No description provided for @repeater_cliHelpNeighbors.
  ///
  /// In en, this message translates to:
  /// **'Shows a list of other repeater nodes heard via zero-hop adverts. Each line is id-prefix-hex:timestamp:snr-times-4'**
  String get repeater_cliHelpNeighbors;

  /// No description provided for @repeater_cliHelpNeighborRemove.
  ///
  /// In en, this message translates to:
  /// **'Removes first matching entry (by pubkey prefix (hex)), from neighbors list.'**
  String get repeater_cliHelpNeighborRemove;

  /// No description provided for @repeater_cliHelpRegion.
  ///
  /// In en, this message translates to:
  /// **'(serial only) Lists all defined regions and current flood permissions.'**
  String get repeater_cliHelpRegion;

  /// No description provided for @repeater_cliHelpRegionLoad.
  ///
  /// In en, this message translates to:
  /// **'NOTE: this is a special multi-command invocation. Each subsequent command is a region name (indented with spaces to indicate parent hierarchy, with one space at minimum). Terminated by sending a blank line/command.'**
  String get repeater_cliHelpRegionLoad;

  /// No description provided for @repeater_cliHelpRegionGet.
  ///
  /// In en, this message translates to:
  /// **'Searches for region with given name prefix (or \"*\" for the global scope). Replies with \"-> region-name (parent-name) \'F\'\"'**
  String get repeater_cliHelpRegionGet;

  /// No description provided for @repeater_cliHelpRegionPut.
  ///
  /// In en, this message translates to:
  /// **'Adds or updates a region definition with given name.'**
  String get repeater_cliHelpRegionPut;

  /// No description provided for @repeater_cliHelpRegionRemove.
  ///
  /// In en, this message translates to:
  /// **'Removes a region definition with given name. (must match exactly, and have no child regions)'**
  String get repeater_cliHelpRegionRemove;

  /// No description provided for @repeater_cliHelpRegionAllowf.
  ///
  /// In en, this message translates to:
  /// **'Sets the \'F\'lood permission for the given region. (\'*\' for the global/legacy scope)'**
  String get repeater_cliHelpRegionAllowf;

  /// No description provided for @repeater_cliHelpRegionDenyf.
  ///
  /// In en, this message translates to:
  /// **'Removes the \'F\'lood permission for the given region. (NOTE: at this stage NOT advised to use this on the global/legacy scope!!)'**
  String get repeater_cliHelpRegionDenyf;

  /// No description provided for @repeater_cliHelpRegionHome.
  ///
  /// In en, this message translates to:
  /// **'Replies with the current \'home\' region. (Note applied anywhere yet, reserved for future)'**
  String get repeater_cliHelpRegionHome;

  /// No description provided for @repeater_cliHelpRegionHomeSet.
  ///
  /// In en, this message translates to:
  /// **'Sets the \'home\' region.'**
  String get repeater_cliHelpRegionHomeSet;

  /// No description provided for @repeater_cliHelpRegionSave.
  ///
  /// In en, this message translates to:
  /// **'Persists the region list/map to storage.'**
  String get repeater_cliHelpRegionSave;

  /// No description provided for @repeater_cliHelpGps.
  ///
  /// In en, this message translates to:
  /// **'Gives status of gps. When gps is off, it replies only off, if on it replies with on, status, fix, sat count'**
  String get repeater_cliHelpGps;

  /// No description provided for @repeater_cliHelpGpsOnOff.
  ///
  /// In en, this message translates to:
  /// **'Toggles gps power state.'**
  String get repeater_cliHelpGpsOnOff;

  /// No description provided for @repeater_cliHelpGpsSync.
  ///
  /// In en, this message translates to:
  /// **'Syncs node time with gps clock.'**
  String get repeater_cliHelpGpsSync;

  /// No description provided for @repeater_cliHelpGpsSetLoc.
  ///
  /// In en, this message translates to:
  /// **'Sets node\'s position to gps coordinates and save preferences.'**
  String get repeater_cliHelpGpsSetLoc;

  /// No description provided for @repeater_cliHelpGpsAdvert.
  ///
  /// In en, this message translates to:
  /// **'Gives location advert configuration of the node:\n- none: don\'t include location in adverts\n- share: share gps location (from SensorManager)\n- prefs: advert the location stored in preferences'**
  String get repeater_cliHelpGpsAdvert;

  /// No description provided for @repeater_cliHelpGpsAdvertSet.
  ///
  /// In en, this message translates to:
  /// **'Sets location advert configuration.'**
  String get repeater_cliHelpGpsAdvertSet;

  /// No description provided for @repeater_commandsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Commands List'**
  String get repeater_commandsListTitle;

  /// No description provided for @repeater_commandsListNote.
  ///
  /// In en, this message translates to:
  /// **'NOTE: for the various \"set ...\" commands, there is also a \"get ...\" command.'**
  String get repeater_commandsListNote;

  /// No description provided for @repeater_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get repeater_general;

  /// No description provided for @repeater_settingsCategory.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get repeater_settingsCategory;

  /// No description provided for @repeater_bridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get repeater_bridge;

  /// No description provided for @repeater_logging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get repeater_logging;

  /// No description provided for @repeater_neighborsRepeaterOnly.
  ///
  /// In en, this message translates to:
  /// **'Neighbors (Repeater only)'**
  String get repeater_neighborsRepeaterOnly;

  /// No description provided for @repeater_regionManagementRepeaterOnly.
  ///
  /// In en, this message translates to:
  /// **'Region Management (Repeater only)'**
  String get repeater_regionManagementRepeaterOnly;

  /// No description provided for @repeater_regionNote.
  ///
  /// In en, this message translates to:
  /// **'Region commands have been introduced to manage region definitions and permissions.'**
  String get repeater_regionNote;

  /// No description provided for @repeater_gpsManagement.
  ///
  /// In en, this message translates to:
  /// **'GPS Management'**
  String get repeater_gpsManagement;

  /// No description provided for @repeater_gpsNote.
  ///
  /// In en, this message translates to:
  /// **'gps command has been introduced to manage location related topics.'**
  String get repeater_gpsNote;

  /// No description provided for @telemetry_receivedData.
  ///
  /// In en, this message translates to:
  /// **'Received Telemetry Data'**
  String get telemetry_receivedData;

  /// No description provided for @telemetry_requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Telemetry request timed out.'**
  String get telemetry_requestTimeout;

  /// No description provided for @telemetry_errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading telemetry: {error}'**
  String telemetry_errorLoading(String error);

  /// No description provided for @telemetry_noData.
  ///
  /// In en, this message translates to:
  /// **'No telemetry data available.'**
  String get telemetry_noData;

  /// No description provided for @telemetry_channelTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel {channel}'**
  String telemetry_channelTitle(int channel);

  /// No description provided for @telemetry_batteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get telemetry_batteryLabel;

  /// No description provided for @telemetry_voltageLabel.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get telemetry_voltageLabel;

  /// No description provided for @telemetry_mcuTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'MCU Temperature'**
  String get telemetry_mcuTemperatureLabel;

  /// No description provided for @telemetry_temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get telemetry_temperatureLabel;

  /// No description provided for @telemetry_currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get telemetry_currentLabel;

  /// No description provided for @telemetry_batteryValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% / {volts}V'**
  String telemetry_batteryValue(int percent, String volts);

  /// No description provided for @telemetry_voltageValue.
  ///
  /// In en, this message translates to:
  /// **'{volts}V'**
  String telemetry_voltageValue(String volts);

  /// No description provided for @telemetry_currentValue.
  ///
  /// In en, this message translates to:
  /// **'{amps}A'**
  String telemetry_currentValue(String amps);

  /// No description provided for @telemetry_temperatureValue.
  ///
  /// In en, this message translates to:
  /// **'{celsius}°C / {fahrenheit}°F'**
  String telemetry_temperatureValue(String celsius, String fahrenheit);

  /// No description provided for @neighbors_receivedData.
  ///
  /// In en, this message translates to:
  /// **'Received Neighbors Data'**
  String get neighbors_receivedData;

  /// No description provided for @neighbors_requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Neighbors request timed out.'**
  String get neighbors_requestTimedOut;

  /// No description provided for @neighbors_errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading neighbors: {error}'**
  String neighbors_errorLoading(String error);

  /// No description provided for @neighbors_repeatersNeighbors.
  ///
  /// In en, this message translates to:
  /// **'Repeaters Neighbors'**
  String get neighbors_repeatersNeighbors;

  /// No description provided for @neighbors_noData.
  ///
  /// In en, this message translates to:
  /// **'No neighbors data available.'**
  String get neighbors_noData;

  /// No description provided for @neighbors_unknownContact.
  ///
  /// In en, this message translates to:
  /// **'Unknown {pubkey}'**
  String neighbors_unknownContact(String pubkey);

  /// No description provided for @neighbors_heardAgo.
  ///
  /// In en, this message translates to:
  /// **'Heard: {time} ago'**
  String neighbors_heardAgo(String time);

  /// No description provided for @channelPath_title.
  ///
  /// In en, this message translates to:
  /// **'Packet Path'**
  String get channelPath_title;

  /// No description provided for @channelPath_viewMap.
  ///
  /// In en, this message translates to:
  /// **'View map'**
  String get channelPath_viewMap;

  /// No description provided for @channelPath_otherObservedPaths.
  ///
  /// In en, this message translates to:
  /// **'Other Observed Paths'**
  String get channelPath_otherObservedPaths;

  /// No description provided for @channelPath_repeaterHops.
  ///
  /// In en, this message translates to:
  /// **'Repeater Hops'**
  String get channelPath_repeaterHops;

  /// No description provided for @channelPath_noHopDetails.
  ///
  /// In en, this message translates to:
  /// **'Hop details are not provided for this packet.'**
  String get channelPath_noHopDetails;

  /// No description provided for @channelPath_messageDetails.
  ///
  /// In en, this message translates to:
  /// **'Message Details'**
  String get channelPath_messageDetails;

  /// No description provided for @channelPath_senderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get channelPath_senderLabel;

  /// No description provided for @channelPath_timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get channelPath_timeLabel;

  /// No description provided for @channelPath_repeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get channelPath_repeatsLabel;

  /// No description provided for @channelPath_pathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path {index}'**
  String channelPath_pathLabel(int index);

  /// No description provided for @channelPath_observedLabel.
  ///
  /// In en, this message translates to:
  /// **'Observed'**
  String get channelPath_observedLabel;

  /// No description provided for @channelPath_observedPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Observed path {index} • {hops}'**
  String channelPath_observedPathTitle(int index, String hops);

  /// No description provided for @channelPath_noLocationData.
  ///
  /// In en, this message translates to:
  /// **'No location data'**
  String get channelPath_noLocationData;

  /// No description provided for @channelPath_timeWithDate.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month} {time}'**
  String channelPath_timeWithDate(int day, int month, String time);

  /// No description provided for @channelPath_timeOnly.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String channelPath_timeOnly(String time);

  /// No description provided for @channelPath_unknownPath.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get channelPath_unknownPath;

  /// No description provided for @channelPath_floodPath.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get channelPath_floodPath;

  /// No description provided for @channelPath_directPath.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get channelPath_directPath;

  /// No description provided for @channelPath_observedZeroOf.
  ///
  /// In en, this message translates to:
  /// **'0 of {total} hops'**
  String channelPath_observedZeroOf(int total);

  /// No description provided for @channelPath_observedSomeOf.
  ///
  /// In en, this message translates to:
  /// **'{observed} of {total} hops'**
  String channelPath_observedSomeOf(int observed, int total);

  /// No description provided for @channelPath_mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Path Map'**
  String get channelPath_mapTitle;

  /// No description provided for @channelPath_noRepeaterLocations.
  ///
  /// In en, this message translates to:
  /// **'No repeater locations available for this path.'**
  String get channelPath_noRepeaterLocations;

  /// No description provided for @channelPath_primaryPath.
  ///
  /// In en, this message translates to:
  /// **'Path {index} (Primary)'**
  String channelPath_primaryPath(int index);

  /// No description provided for @channelPath_pathLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get channelPath_pathLabelTitle;

  /// No description provided for @channelPath_observedPathHeader.
  ///
  /// In en, this message translates to:
  /// **'Observed Path'**
  String get channelPath_observedPathHeader;

  /// No description provided for @channelPath_selectedPathLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} • {prefixes}'**
  String channelPath_selectedPathLabel(String label, String prefixes);

  /// No description provided for @channelPath_noHopDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hop details available for this packet.'**
  String get channelPath_noHopDetailsAvailable;

  /// No description provided for @channelPath_unknownRepeater.
  ///
  /// In en, this message translates to:
  /// **'Unknown Repeater'**
  String get channelPath_unknownRepeater;

  /// No description provided for @community_title.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community_title;

  /// No description provided for @community_create.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get community_create;

  /// No description provided for @community_createDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new community and share via QR code.'**
  String get community_createDesc;

  /// No description provided for @community_join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get community_join;

  /// No description provided for @community_joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get community_joinTitle;

  /// No description provided for @community_joinConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to join the community \"{name}\"?'**
  String community_joinConfirmation(String name);

  /// No description provided for @community_scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Community QR'**
  String get community_scanQr;

  /// No description provided for @community_scanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a community QR code'**
  String get community_scanInstructions;

  /// No description provided for @community_showQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get community_showQr;

  /// No description provided for @community_publicChannel.
  ///
  /// In en, this message translates to:
  /// **'Community Public'**
  String get community_publicChannel;

  /// No description provided for @community_hashtagChannel.
  ///
  /// In en, this message translates to:
  /// **'Community Hashtag'**
  String get community_hashtagChannel;

  /// No description provided for @community_name.
  ///
  /// In en, this message translates to:
  /// **'Community Name'**
  String get community_name;

  /// No description provided for @community_enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter community name'**
  String get community_enterName;

  /// No description provided for @community_created.
  ///
  /// In en, this message translates to:
  /// **'Community \"{name}\" created'**
  String community_created(String name);

  /// No description provided for @community_joined.
  ///
  /// In en, this message translates to:
  /// **'Joined community \"{name}\"'**
  String community_joined(String name);

  /// No description provided for @community_qrTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Community'**
  String get community_qrTitle;

  /// No description provided for @community_qrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to join \"{name}\"'**
  String community_qrInstructions(String name);

  /// No description provided for @community_hashtagPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Community hashtag channels are only joinable by members of the community'**
  String get community_hashtagPrivacyHint;

  /// No description provided for @community_invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid community QR code'**
  String get community_invalidQrCode;

  /// No description provided for @community_alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a Member'**
  String get community_alreadyMember;

  /// No description provided for @community_alreadyMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'You are already a member of \"{name}\".'**
  String community_alreadyMemberMessage(String name);

  /// No description provided for @community_addPublicChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Community Public Channel'**
  String get community_addPublicChannel;

  /// No description provided for @community_addPublicChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Automatically add the public channel for this community'**
  String get community_addPublicChannelHint;

  /// No description provided for @community_noCommunities.
  ///
  /// In en, this message translates to:
  /// **'No communities joined yet'**
  String get community_noCommunities;

  /// No description provided for @community_scanOrCreate.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or create a community to get started'**
  String get community_scanOrCreate;

  /// No description provided for @community_manageCommunities.
  ///
  /// In en, this message translates to:
  /// **'Manage Communities'**
  String get community_manageCommunities;

  /// No description provided for @community_delete.
  ///
  /// In en, this message translates to:
  /// **'Leave Community'**
  String get community_delete;

  /// No description provided for @community_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave \"{name}\"?'**
  String community_deleteConfirm(String name);

  /// No description provided for @community_deleteChannelsWarning.
  ///
  /// In en, this message translates to:
  /// **'This will also delete {count} channel(s) and their messages.'**
  String community_deleteChannelsWarning(int count);

  /// No description provided for @community_deleted.
  ///
  /// In en, this message translates to:
  /// **'Left community \"{name}\"'**
  String community_deleted(String name);

  /// No description provided for @community_regenerateSecret.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Secret'**
  String get community_regenerateSecret;

  /// No description provided for @community_regenerateSecretConfirm.
  ///
  /// In en, this message translates to:
  /// **'Regenerate the secret key for \"{name}\"? All members will need to scan the new QR code to continue communicating.'**
  String community_regenerateSecretConfirm(String name);

  /// No description provided for @community_regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get community_regenerate;

  /// No description provided for @community_secretRegenerated.
  ///
  /// In en, this message translates to:
  /// **'Secret regenerated for \"{name}\"'**
  String community_secretRegenerated(String name);

  /// No description provided for @community_updateSecret.
  ///
  /// In en, this message translates to:
  /// **'Update Secret'**
  String get community_updateSecret;

  /// No description provided for @community_secretUpdated.
  ///
  /// In en, this message translates to:
  /// **'Secret updated for \"{name}\"'**
  String community_secretUpdated(String name);

  /// No description provided for @community_scanToUpdateSecret.
  ///
  /// In en, this message translates to:
  /// **'Scan the new QR code to update the secret for \"{name}\"'**
  String community_scanToUpdateSecret(String name);

  /// No description provided for @community_addHashtagChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Community Hashtag'**
  String get community_addHashtagChannel;

  /// No description provided for @community_addHashtagChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a hashtag channel for this community'**
  String get community_addHashtagChannelDesc;

  /// No description provided for @community_selectCommunity.
  ///
  /// In en, this message translates to:
  /// **'Select Community'**
  String get community_selectCommunity;

  /// No description provided for @community_regularHashtag.
  ///
  /// In en, this message translates to:
  /// **'Regular Hashtag'**
  String get community_regularHashtag;

  /// No description provided for @community_regularHashtagDesc.
  ///
  /// In en, this message translates to:
  /// **'Public hashtag (anyone can join)'**
  String get community_regularHashtagDesc;

  /// No description provided for @community_communityHashtag.
  ///
  /// In en, this message translates to:
  /// **'Community Hashtag'**
  String get community_communityHashtag;

  /// No description provided for @community_communityHashtagDesc.
  ///
  /// In en, this message translates to:
  /// **'Private to community members'**
  String get community_communityHashtagDesc;

  /// No description provided for @community_forCommunity.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String community_forCommunity(String name);

  /// No description provided for @listFilter_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter and sort'**
  String get listFilter_tooltip;

  /// No description provided for @listFilter_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get listFilter_sortBy;

  /// No description provided for @listFilter_latestMessages.
  ///
  /// In en, this message translates to:
  /// **'Latest messages'**
  String get listFilter_latestMessages;

  /// No description provided for @listFilter_heardRecently.
  ///
  /// In en, this message translates to:
  /// **'Heard recently'**
  String get listFilter_heardRecently;

  /// No description provided for @listFilter_az.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get listFilter_az;

  /// No description provided for @listFilter_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get listFilter_filters;

  /// No description provided for @listFilter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get listFilter_all;

  /// No description provided for @listFilter_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get listFilter_favorites;

  /// No description provided for @listFilter_addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get listFilter_addToFavorites;

  /// No description provided for @listFilter_removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get listFilter_removeFromFavorites;

  /// No description provided for @listFilter_users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get listFilter_users;

  /// No description provided for @listFilter_repeaters.
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get listFilter_repeaters;

  /// No description provided for @listFilter_roomServers.
  ///
  /// In en, this message translates to:
  /// **'Room servers'**
  String get listFilter_roomServers;

  /// No description provided for @listFilter_unreadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unread only'**
  String get listFilter_unreadOnly;

  /// No description provided for @listFilter_newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get listFilter_newGroup;

  /// No description provided for @pathTrace_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get pathTrace_you;

  /// No description provided for @pathTrace_failed.
  ///
  /// In en, this message translates to:
  /// **'Path trace failed.'**
  String get pathTrace_failed;

  /// No description provided for @pathTrace_notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Path trace not available.'**
  String get pathTrace_notAvailable;

  /// No description provided for @pathTrace_refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Path Trace.'**
  String get pathTrace_refreshTooltip;

  /// No description provided for @pathTrace_someHopsNoLocation.
  ///
  /// In en, this message translates to:
  /// **'One or more of the hops is missing a location!'**
  String get pathTrace_someHopsNoLocation;

  /// No description provided for @pathTrace_clearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear path.'**
  String get pathTrace_clearTooltip;

  /// No description provided for @losSelectStartEnd.
  ///
  /// In en, this message translates to:
  /// **'Select start and end nodes for LOS.'**
  String get losSelectStartEnd;

  /// No description provided for @losRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Line-of-sight check failed: {error}'**
  String losRunFailed(String error);

  /// No description provided for @losClearAllPoints.
  ///
  /// In en, this message translates to:
  /// **'Clear all points'**
  String get losClearAllPoints;

  /// No description provided for @losRunToViewElevationProfile.
  ///
  /// In en, this message translates to:
  /// **'Run LOS to view elevation profile'**
  String get losRunToViewElevationProfile;

  /// No description provided for @losMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'LOS Menu'**
  String get losMenuTitle;

  /// No description provided for @losMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap nodes or long-press map for custom points'**
  String get losMenuSubtitle;

  /// No description provided for @losShowDisplayNodes.
  ///
  /// In en, this message translates to:
  /// **'Show display nodes'**
  String get losShowDisplayNodes;

  /// No description provided for @losCustomPoints.
  ///
  /// In en, this message translates to:
  /// **'Custom points'**
  String get losCustomPoints;

  /// No description provided for @losCustomPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom {index}'**
  String losCustomPointLabel(int index);

  /// No description provided for @losPointA.
  ///
  /// In en, this message translates to:
  /// **'Point A'**
  String get losPointA;

  /// No description provided for @losPointB.
  ///
  /// In en, this message translates to:
  /// **'Point B'**
  String get losPointB;

  /// No description provided for @losAntennaA.
  ///
  /// In en, this message translates to:
  /// **'Antenna A: {value} {unit}'**
  String losAntennaA(String value, String unit);

  /// No description provided for @losAntennaB.
  ///
  /// In en, this message translates to:
  /// **'Antenna B: {value} {unit}'**
  String losAntennaB(String value, String unit);

  /// No description provided for @losRun.
  ///
  /// In en, this message translates to:
  /// **'Run LOS'**
  String get losRun;

  /// No description provided for @losNoElevationData.
  ///
  /// In en, this message translates to:
  /// **'No elevation data'**
  String get losNoElevationData;

  /// No description provided for @losProfileClear.
  ///
  /// In en, this message translates to:
  /// **'{distance} {distanceUnit}, clear LOS, min clearance {clearance} {heightUnit}'**
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  );

  /// No description provided for @losProfileBlocked.
  ///
  /// In en, this message translates to:
  /// **'{distance} {distanceUnit}, blocked by {obstruction} {heightUnit}'**
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  );

  /// No description provided for @losStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'LOS: checking...'**
  String get losStatusChecking;

  /// No description provided for @losStatusNoData.
  ///
  /// In en, this message translates to:
  /// **'LOS: no data'**
  String get losStatusNoData;

  /// No description provided for @losStatusSummary.
  ///
  /// In en, this message translates to:
  /// **'LOS: {clear}/{total} clear, {blocked} blocked, {unknown} unknown'**
  String losStatusSummary(int clear, int total, int blocked, int unknown);

  /// No description provided for @losErrorElevationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Elevation data unavailable for one or more samples.'**
  String get losErrorElevationUnavailable;

  /// No description provided for @losErrorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid points/elevation data for LOS calculation.'**
  String get losErrorInvalidInput;

  /// No description provided for @losRenameCustomPoint.
  ///
  /// In en, this message translates to:
  /// **'Rename custom point'**
  String get losRenameCustomPoint;

  /// No description provided for @losPointName.
  ///
  /// In en, this message translates to:
  /// **'Point name'**
  String get losPointName;

  /// No description provided for @losShowPanelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show LOS panel'**
  String get losShowPanelTooltip;

  /// No description provided for @losHidePanelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide LOS panel'**
  String get losHidePanelTooltip;

  /// No description provided for @losElevationAttribution.
  ///
  /// In en, this message translates to:
  /// **'Elevation data: Open-Meteo (CC BY 4.0)'**
  String get losElevationAttribution;

  /// No description provided for @losLegendRadioHorizon.
  ///
  /// In en, this message translates to:
  /// **'Radio horizon'**
  String get losLegendRadioHorizon;

  /// No description provided for @losLegendLosBeam.
  ///
  /// In en, this message translates to:
  /// **'LOS beam'**
  String get losLegendLosBeam;

  /// No description provided for @losLegendTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get losLegendTerrain;

  /// No description provided for @losFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get losFrequencyLabel;

  /// No description provided for @losFrequencyInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'View calculation details'**
  String get losFrequencyInfoTooltip;

  /// No description provided for @losFrequencyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio horizon calculation'**
  String get losFrequencyDialogTitle;

  /// Explain how the calculation uses the baseline frequency and derived k-factor.
  ///
  /// In en, this message translates to:
  /// **'Starting from k={baselineK} at {baselineFreq} MHz, the calculation adjusts the k-factor for the current {frequencyMHz} MHz band, which defines the curved radio horizon cap.'**
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  );

  /// No description provided for @contacts_pathTrace.
  ///
  /// In en, this message translates to:
  /// **'Path Trace'**
  String get contacts_pathTrace;

  /// No description provided for @contacts_ping.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get contacts_ping;

  /// No description provided for @contacts_repeaterPathTrace.
  ///
  /// In en, this message translates to:
  /// **'Path trace to repeater'**
  String get contacts_repeaterPathTrace;

  /// No description provided for @contacts_repeaterPing.
  ///
  /// In en, this message translates to:
  /// **'Ping repeater'**
  String get contacts_repeaterPing;

  /// No description provided for @contacts_roomPathTrace.
  ///
  /// In en, this message translates to:
  /// **'Path trace to room server'**
  String get contacts_roomPathTrace;

  /// No description provided for @contacts_roomPing.
  ///
  /// In en, this message translates to:
  /// **'Ping room server'**
  String get contacts_roomPing;

  /// No description provided for @contacts_chatTraceRoute.
  ///
  /// In en, this message translates to:
  /// **'Path trace route'**
  String get contacts_chatTraceRoute;

  /// No description provided for @contacts_pathTraceTo.
  ///
  /// In en, this message translates to:
  /// **'Trace route to {name}'**
  String contacts_pathTraceTo(String name);

  /// No description provided for @contacts_clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty.'**
  String get contacts_clipboardEmpty;

  /// No description provided for @contacts_invalidAdvertFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid contact data'**
  String get contacts_invalidAdvertFormat;

  /// No description provided for @contacts_contactImported.
  ///
  /// In en, this message translates to:
  /// **'Contact has been imported.'**
  String get contacts_contactImported;

  /// No description provided for @contacts_contactImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import contact.'**
  String get contacts_contactImportFailed;

  /// No description provided for @contacts_zeroHopAdvert.
  ///
  /// In en, this message translates to:
  /// **'Zero Hop Advert'**
  String get contacts_zeroHopAdvert;

  /// No description provided for @contacts_floodAdvert.
  ///
  /// In en, this message translates to:
  /// **'Flood Advert'**
  String get contacts_floodAdvert;

  /// No description provided for @contacts_copyAdvertToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy Advert to Clipboard'**
  String get contacts_copyAdvertToClipboard;

  /// No description provided for @contacts_addContactFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Add Contact from Clipboard'**
  String get contacts_addContactFromClipboard;

  /// No description provided for @contacts_ShareContact.
  ///
  /// In en, this message translates to:
  /// **'Copy contact to Clipboard'**
  String get contacts_ShareContact;

  /// No description provided for @contacts_ShareContactZeroHop.
  ///
  /// In en, this message translates to:
  /// **'Share contact by advert'**
  String get contacts_ShareContactZeroHop;

  /// No description provided for @contacts_zeroHopContactAdvertSent.
  ///
  /// In en, this message translates to:
  /// **'Sent contact by advert.'**
  String get contacts_zeroHopContactAdvertSent;

  /// No description provided for @contacts_zeroHopContactAdvertFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send contact.'**
  String get contacts_zeroHopContactAdvertFailed;

  /// No description provided for @contacts_contactAdvertCopied.
  ///
  /// In en, this message translates to:
  /// **'Advert copied to Clipboard.'**
  String get contacts_contactAdvertCopied;

  /// No description provided for @contacts_contactAdvertCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copying advert to Clipboard failed.'**
  String get contacts_contactAdvertCopyFailed;

  /// No description provided for @notification_activityTitle.
  ///
  /// In en, this message translates to:
  /// **'MeshCore Activity'**
  String get notification_activityTitle;

  /// No description provided for @notification_messagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{message} other{messages}}'**
  String notification_messagesCount(int count);

  /// No description provided for @notification_channelMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{channel message} other{channel messages}}'**
  String notification_channelMessagesCount(int count);

  /// No description provided for @notification_newNodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{new node} other{new nodes}}'**
  String notification_newNodesCount(int count);

  /// No description provided for @notification_newTypeDiscovered.
  ///
  /// In en, this message translates to:
  /// **'New {contactType} discovered'**
  String notification_newTypeDiscovered(String contactType);

  /// No description provided for @notification_receivedNewMessage.
  ///
  /// In en, this message translates to:
  /// **'Received new message'**
  String get notification_receivedNewMessage;

  /// No description provided for @settings_gpxExportRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Export repeaters / room server to GPX'**
  String get settings_gpxExportRepeaters;

  /// No description provided for @settings_gpxExportRepeatersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exports repeaters / roomserver with a location to GPX file.'**
  String get settings_gpxExportRepeatersSubtitle;

  /// No description provided for @settings_gpxExportContacts.
  ///
  /// In en, this message translates to:
  /// **'Export companions to GPX'**
  String get settings_gpxExportContacts;

  /// No description provided for @settings_gpxExportContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exports companions with a location to GPX file.'**
  String get settings_gpxExportContactsSubtitle;

  /// No description provided for @settings_gpxExportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all contacts to GPX'**
  String get settings_gpxExportAll;

  /// No description provided for @settings_gpxExportAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exports all contacts with a location to GPX file.'**
  String get settings_gpxExportAllSubtitle;

  /// No description provided for @settings_gpxExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully exported GPX file.'**
  String get settings_gpxExportSuccess;

  /// No description provided for @settings_gpxExportNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts to export.'**
  String get settings_gpxExportNoContacts;

  /// No description provided for @settings_gpxExportNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not supported on your device/OS'**
  String get settings_gpxExportNotAvailable;

  /// No description provided for @settings_gpxExportError.
  ///
  /// In en, this message translates to:
  /// **'There was an error when exporting.'**
  String get settings_gpxExportError;

  /// No description provided for @settings_gpxExportRepeatersRoom.
  ///
  /// In en, this message translates to:
  /// **'Repeater & room server locations'**
  String get settings_gpxExportRepeatersRoom;

  /// No description provided for @settings_gpxExportChat.
  ///
  /// In en, this message translates to:
  /// **'Companion locations'**
  String get settings_gpxExportChat;

  /// No description provided for @settings_gpxExportAllContacts.
  ///
  /// In en, this message translates to:
  /// **'All contacts locations'**
  String get settings_gpxExportAllContacts;

  /// No description provided for @settings_gpxExportShareText.
  ///
  /// In en, this message translates to:
  /// **'Map data exported from meshcore-open'**
  String get settings_gpxExportShareText;

  /// No description provided for @settings_gpxExportShareSubject.
  ///
  /// In en, this message translates to:
  /// **'meshcore-open GPX map data export'**
  String get settings_gpxExportShareSubject;

  /// No description provided for @snrIndicator_nearByRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Nearby Repeaters'**
  String get snrIndicator_nearByRepeaters;

  /// No description provided for @snrIndicator_lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get snrIndicator_lastSeen;

  /// No description provided for @contactsSettings_title.
  ///
  /// In en, this message translates to:
  /// **'Contacts settings'**
  String get contactsSettings_title;

  /// No description provided for @contactsSettings_autoAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Discovery'**
  String get contactsSettings_autoAddTitle;

  /// No description provided for @contactsSettings_otherTitle.
  ///
  /// In en, this message translates to:
  /// **'Other contact related settings'**
  String get contactsSettings_otherTitle;

  /// No description provided for @contactsSettings_autoAddUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-add users'**
  String get contactsSettings_autoAddUsersTitle;

  /// No description provided for @contactsSettings_autoAddUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the companion to automatically add discovered users.'**
  String get contactsSettings_autoAddUsersSubtitle;

  /// No description provided for @contactsSettings_autoAddRepeatersTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-add repeaters'**
  String get contactsSettings_autoAddRepeatersTitle;

  /// No description provided for @contactsSettings_autoAddRepeatersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the companion to automatically add discovered repeaters.'**
  String get contactsSettings_autoAddRepeatersSubtitle;

  /// No description provided for @contactsSettings_autoAddRoomServersTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-add room servers'**
  String get contactsSettings_autoAddRoomServersTitle;

  /// No description provided for @contactsSettings_autoAddRoomServersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the companion to automatically add discovered room servers.'**
  String get contactsSettings_autoAddRoomServersSubtitle;

  /// No description provided for @contactsSettings_autoAddSensorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-add sensors'**
  String get contactsSettings_autoAddSensorsTitle;

  /// No description provided for @contactsSettings_autoAddSensorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the companion to automatically add discovered sensors.'**
  String get contactsSettings_autoAddSensorsSubtitle;

  /// No description provided for @contactsSettings_overwriteOldestTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Oldest'**
  String get contactsSettings_overwriteOldestTitle;

  /// No description provided for @contactsSettings_overwriteOldestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When the contact list is full, the oldest non-favorited contact will be replaced.'**
  String get contactsSettings_overwriteOldestSubtitle;

  /// No description provided for @discoveredContacts_Title.
  ///
  /// In en, this message translates to:
  /// **'Discovered Contacts'**
  String get discoveredContacts_Title;

  /// No description provided for @discoveredContacts_noMatching.
  ///
  /// In en, this message translates to:
  /// **'No matching contacts'**
  String get discoveredContacts_noMatching;

  /// No description provided for @discoveredContacts_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search discovered contacts'**
  String get discoveredContacts_searchHint;

  /// No description provided for @discoveredContacts_contactAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact added'**
  String get discoveredContacts_contactAdded;

  /// No description provided for @discoveredContacts_addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get discoveredContacts_addContact;

  /// No description provided for @discoveredContacts_copyContact.
  ///
  /// In en, this message translates to:
  /// **'Copy Contact to clipboard'**
  String get discoveredContacts_copyContact;

  /// No description provided for @discoveredContacts_deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete Discovered Contact'**
  String get discoveredContacts_deleteContact;

  /// No description provided for @discoveredContacts_deleteContactAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All Discovered Contacts'**
  String get discoveredContacts_deleteContactAll;

  /// No description provided for @discoveredContacts_deleteContactAllContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all discovered contacts?'**
  String get discoveredContacts_deleteContactAllContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bg',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pl',
    'pt',
    'ru',
    'sk',
    'sl',
    'sv',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sv':
      return AppLocalizationsSv();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
