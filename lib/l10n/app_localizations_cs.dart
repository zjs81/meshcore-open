// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'MeshCore Open';

  @override
  String get nav_contacts => 'Kontakty';

  @override
  String get nav_channels => 'Kanály';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Zrušit';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Připojit';

  @override
  String get common_unknownDevice => 'Neznámé zařízení';

  @override
  String get common_save => 'Uložit';

  @override
  String get common_delete => 'Smazat';

  @override
  String get common_deleteAll => 'Smazat vše';

  @override
  String get common_close => 'Zavřít';

  @override
  String get common_done => 'Hotovo';

  @override
  String get common_edit => 'Upravit';

  @override
  String get common_add => 'Přidat';

  @override
  String get common_settings => 'Nastavení';

  @override
  String get common_disconnect => 'Odpojit';

  @override
  String get common_connected => 'Připojeno';

  @override
  String get common_disconnected => 'Odpojeno';

  @override
  String get common_create => 'Vytvořit';

  @override
  String get common_continue => 'Pokračovat';

  @override
  String get common_share => 'Sdílet';

  @override
  String get common_copy => 'Kopírovat';

  @override
  String get common_retry => 'Zkusit znovu';

  @override
  String get common_hide => 'Skrýt';

  @override
  String get common_remove => 'Odebrat';

  @override
  String get common_enable => 'Povolit';

  @override
  String get common_disable => 'Zakázat';

  @override
  String get common_undo => 'Zpět';

  @override
  String get messageStatus_sent => 'Odesláno';

  @override
  String get messageStatus_delivered =>
      'Doručeno. Kontakt potvrdil, že zprávu obdržel.';

  @override
  String get messageStatus_pending => 'Odesílání';

  @override
  String get messageStatus_failed => 'Odeslání se nezdařilo';

  @override
  String get messageStatus_repeated => 'Slyšeno opakování';

  @override
  String get messageStatus_failedChannel =>
      'Vaše vysílačka tuto zprávu nemohla odeslat.';

  @override
  String messageStatus_resending(int resends, int maxResends) {
    return 'Zatím neslyšena přes dostatek opakovačů. Odesláno znovu $resends z ${maxResends}krát.';
  }

  @override
  String messageStatus_hopsNotReached(int hops, int required) {
    return 'Odesláno, ale zpět slyšeno jen přes $hops z $required opakovačů. Mohla dojít dál, než Vaše vysílačka slyší.';
  }

  @override
  String get messageStatus_sentChannel =>
      'Odesláno. Kanály nepotvrzují doručení, takže to znamená jen to, že ji Vaše vysílačka odeslala.';

  @override
  String get messageStatus_sentDirect =>
      'Odesláno. Čeká se na potvrzení od kontaktu.';

  @override
  String messageStatus_heardRepeatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}krát',
      many: '${count}krát',
      few: '${count}krát',
      one: 'jednou',
    );
    return 'Slyšeno opakování $_temp0. Opakovače v okolí ji předaly dál.';
  }

  @override
  String get urlImage_enable => 'Povolit obrázky z URL';

  @override
  String get urlImage_possible =>
      'Možný obrázek z URL; povolte jej v Nastavení.';

  @override
  String get urlImage_disabledInAppSettings => 'Vypnuto v nastavení aplikace';

  @override
  String get common_reboot => 'Restartovat';

  @override
  String get common_loading => 'Načítání...';

  @override
  String get common_notAvailable => '—';

  @override
  String common_voltageValue(String volts) {
    return '$volts V';
  }

  @override
  String common_percentValue(int percent) {
    return '$percent %';
  }

  @override
  String get common_autoRefresh => 'Automatické obnovení';

  @override
  String get common_interval => 'Interval';

  @override
  String get scanner_title => 'MeshCore Open';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Připojení přes TCP';

  @override
  String get tcpHostLabel => 'Koncový bod';

  @override
  String get tcpHostHint => '192.168.40.10 / example.com';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Zadejte koncový bod a připojte se';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Připojování k $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Hostitel je povinný.';

  @override
  String get tcpErrorPortInvalid => 'Port musí být mezi 1 a 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Přenos přes TCP není na této platformě podporován.';

  @override
  String get tcpErrorTimedOut => 'Časový limit připojení TCP vypršel.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Připojení TCP se nezdařilo: $error';
  }

  @override
  String get usbScreenTitle => 'Připojení přes USB';

  @override
  String get usbScreenSubtitle =>
      'Vyberte rozpoznané sériové zařízení a připojte se přímo ke svému uzlu MeshCore.';

  @override
  String get usbScreenStatus => 'Vyberte zařízení USB';

  @override
  String get usbScreenNote =>
      'Sériové USB funguje na podporovaných zařízeních Android a na desktopových platformách.';

  @override
  String get usbScreenEmptyState =>
      'Nebyla nalezena žádná zařízení USB. Připojte nějaké a obnovte.';

  @override
  String get usbErrorPermissionDenied => 'Oprávnění k USB bylo odepřeno.';

  @override
  String get usbErrorDeviceMissing => 'Vybrané zařízení USB už není dostupné.';

  @override
  String get usbErrorInvalidPort => 'Vyberte platné zařízení USB.';

  @override
  String get usbErrorBusy => 'Jiný požadavek na připojení USB již probíhá.';

  @override
  String get usbErrorNotConnected => 'Není připojeno žádné zařízení USB.';

  @override
  String get usbErrorOpenFailed =>
      'Vybrané zařízení USB se nepodařilo otevřít.';

  @override
  String get usbErrorConnectFailed =>
      'Připojení k vybranému zařízení USB se nezdařilo.';

  @override
  String get usbErrorUnsupported =>
      'Sériové USB není na této platformě podporováno.';

  @override
  String get usbErrorAlreadyActive => 'Připojení USB je již aktivní.';

  @override
  String get usbErrorNoDeviceSelected => 'Nebylo vybráno žádné zařízení USB.';

  @override
  String get usbErrorPortClosed => 'Připojení USB není otevřené.';

  @override
  String get usbErrorConnectTimedOut =>
      'Časový limit připojení vypršel. Ujistěte se, že zařízení má firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Zařízení Web Serial';

  @override
  String get usbStatus_notConnected => 'Vyberte zařízení USB';

  @override
  String get usbStatus_connecting => 'Připojování k zařízení USB...';

  @override
  String get usbStatus_searching => 'Hledání zařízení USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Připojení USB se nezdařilo: $error';
  }

  @override
  String get scanner_scanning => 'Hledání zařízení...';

  @override
  String get scanner_connecting => 'Připojování...';

  @override
  String get scanner_disconnecting => 'Odpojování...';

  @override
  String get scanner_notConnected => 'Nepřipojeno';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Připojeno k $deviceName';
  }

  @override
  String get scanner_searchingDevices => 'Hledání zařízení MeshCore...';

  @override
  String get scanner_tapToScan =>
      'Klepnutím na Skenovat najdete zařízení MeshCore';

  @override
  String scanner_connectionFailed(String error) {
    return 'Připojení se nezdařilo: $error';
  }

  @override
  String get scanner_stop => 'Zastavit';

  @override
  String get scanner_scan => 'Skenovat';

  @override
  String get scanner_bluetoothOff => 'Bluetooth je vypnutý';

  @override
  String get scanner_bluetoothOffMessage =>
      'Pro hledání zařízení zapněte Bluetooth';

  @override
  String get scanner_chromeRequired => 'Vyžadován prohlížeč Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Tato webová aplikace vyžaduje pro podporu Bluetooth Google Chrome nebo prohlížeč založený na Chromiu.';

  @override
  String get scanner_enableBluetooth => 'Zapnout Bluetooth';

  @override
  String get scanner_getNodeTitle => 'Potřebujete nový uzel?';

  @override
  String get scanner_getNodeBody =>
      'Velikost peněženky, běží na MeshCore, dvoupásmové GPS, vodotěsný, baterie na 5 dní.';

  @override
  String get scanner_getNodeAction => 'Pořídit zde';

  @override
  String get scanner_getNodeDisclosure =>
      'Affiliate odkaz: každý nákup podporuje MeshCore Open.';

  @override
  String get scanner_bluetoothWebUnsupported =>
      'Bluetooth není v prohlížeči dostupný. Připojte se místo toho přes USB.';

  @override
  String get device_quickSwitch => 'Rychlé přepnutí';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Nastavení';

  @override
  String get settings_deviceInfo => 'Informace o zařízení';

  @override
  String get settings_appSettings => 'Nastavení aplikace';

  @override
  String get settings_appSettingsSubtitle =>
      'Oznámení, zprávy a předvolby mapy';

  @override
  String get settings_export => 'Exportovat';

  @override
  String get settings_exportSubtitle =>
      'Exportovat kontakty a opakovače jako GPX';

  @override
  String get backupRestore_title => 'Záloha a obnovení';

  @override
  String get backupRestore_subtitle =>
      'Uložte nebo obnovte data aplikace a nastavení rádia';

  @override
  String get backupRestore_import => 'Importovat';

  @override
  String get backupRestore_selectImportFile => 'Importovat soubor';

  @override
  String get backupRestore_password => 'Heslo (volitelné)';

  @override
  String get backupRestore_passwordHelp =>
      'Heslo soubor zašifruje. Prázdné heslo uloží prostý text, který může obsahovat soukromé klíče a klíče kanálů, historii a přihlašovací údaje.';

  @override
  String get backupRestore_importUnavailable =>
      'Zkontrolujte heslo nebo vyberte podporovaný soubor zálohy.';

  @override
  String get backupRestore_items => 'Položky zálohy a obnovení';

  @override
  String get backupRestore_nodeSettings => 'Nastavení uzlu';

  @override
  String get backupRestore_nodeSettingsDescription =>
      'Název zařízení, soukromý a veřejný klíč, nastavení rádia a regiony';

  @override
  String get backupRestore_deviceName => 'Název zařízení';

  @override
  String get backupRestore_privateKey => 'Soukromý klíč (citlivé)';

  @override
  String get backupRestore_publicKey => 'Veřejný klíč';

  @override
  String get backupRestore_radioSettings => 'Nastavení rádia';

  @override
  String get backupRestore_regions => 'Regiony';

  @override
  String get backupRestore_location => 'Poloha';

  @override
  String get backupRestore_contactSettings => 'Nastavení kontaktů';

  @override
  String get backupRestore_privacySettings => 'Nastavení soukromí';

  @override
  String get backupRestore_contactsData => 'Kontakty';

  @override
  String get backupRestore_perContactSettings => 'Nastavení a filtry kontaktů';

  @override
  String get backupRestore_contactGroups => 'Skupiny kontaktů';

  @override
  String get backupRestore_contactHistory => 'Historie kontaktů';

  @override
  String get backupRestore_channelsData => 'Kanály';

  @override
  String get backupRestore_channelFilters => 'Nastavení filtru zpráv';

  @override
  String get backupRestore_channelSettings => 'Nastavení kanálů';

  @override
  String get backupRestore_communities => 'Komunity';

  @override
  String get backupRestore_channelHistory => 'Historie kanálů';

  @override
  String get backupRestore_locationSettings => 'Nastavení polohy';

  @override
  String get backupRestore_locationSettingsDescription =>
      'Poloha, nastavení kontaktů a soukromí';

  @override
  String get backupRestore_appSettings => 'Nastavení aplikace';

  @override
  String get backupRestore_appSettingsDescription =>
      'Předvolby aplikace a nastavení vzhledu';

  @override
  String get backupRestore_ipfsKey => 'Klíč API IPFS (citlivé)';

  @override
  String get backupRestore_stadiaMapKey => 'Klíč API Stadia Maps (citlivé)';

  @override
  String get backupRestore_contacts => 'Kontakty';

  @override
  String get backupRestore_contactsDescription =>
      'Kontakty, filtry a nastavení jednotlivých kontaktů, skupiny a historie zpráv';

  @override
  String get backupRestore_discoveredContacts => 'Objevené kontakty';

  @override
  String get backupRestore_discoveredContactsDescription =>
      'Objevené kontakty a jejich uložené údaje';

  @override
  String get backupRestore_channels => 'Kanály';

  @override
  String get backupRestore_channelsDescription =>
      'Kanály, filtry kanálů, komunity a historie zpráv';

  @override
  String get backupRestore_backup => 'Vytvořit zálohu';

  @override
  String get backupRestore_restore => 'Obnovit vybrané';

  @override
  String get backupRestore_backupComplete => 'Soubor zálohy byl vytvořen.';

  @override
  String get backupRestore_restoreComplete =>
      'Obnovení dokončeno. Pokud jste obnovili identitu rádia, připojte se znovu.';

  @override
  String get backupRestore_missingModelsTitle => 'Modely nejsou stažené';

  @override
  String backupRestore_missingModelsMessage(String models) {
    return 'Obnovené nastavení vybírá modely, které nejsou v tomto zařízení k dispozici:\n$models\n\nStáhnout je nyní?';
  }

  @override
  String get backupRestore_downloadModels => 'Stáhnout modely';

  @override
  String get backupRestore_downloading => 'Stahování…';

  @override
  String get backupRestore_cancelDownload => 'Zrušit stahování';

  @override
  String backupRestore_failed(String error) {
    return 'Operace zálohy selhala: $error';
  }

  @override
  String get backupRestore_fileTooLarge =>
      'Soubor zálohy je větší než limit 100 MB.';

  @override
  String get backupRestore_selectAtLeastOne => 'Vyberte alespoň jednu položku.';

  @override
  String get backupRestore_replaceIdentityTitle => 'Nahradit identitu rádia?';

  @override
  String get backupRestore_replaceIdentityMessage =>
      'Obnovení nastavení uzlu nahradí soukromý klíč připojeného rádia a změní jeho identitu. Pokračujte, jen pokud je to záměr.';

  @override
  String get settings_nodeSettings => 'Nastavení uzlu';

  @override
  String get settings_nodeName => 'Název uzlu';

  @override
  String get settings_nodeNameNotSet => 'Nenastaveno';

  @override
  String get settings_nodeNameHint => 'Zadejte název uzlu';

  @override
  String get settings_nodeNameUpdated => 'Název aktualizován';

  @override
  String get settings_radioSettings => 'Nastavení rádia';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvence, výkon, spreading factor';

  @override
  String get settings_radioSettingsUpdated => 'Nastavení rádia aktualizováno';

  @override
  String get settings_radioSettingsNotApplied =>
      'Rádio tato nastavení nepoužilo';

  @override
  String get settings_pathHashModeNotApplied =>
      'Nastavení rádia bylo použito, ale rádio nepotvrdilo novou velikost hashe cesty';

  @override
  String get settings_regionSettings => 'Regiony';

  @override
  String get settings_regionSettingsSubtitle => 'Omezit flood kanálů na oblast';

  @override
  String get settings_regionEmptyExplanation =>
      'Regiony omezují flood zprávy na opakovače v dané oblasti. Načtěte je z opakovačů v okolí nebo přidejte jeden podle názvu.';

  @override
  String get settings_regionFetchFromRepeaters => 'Načíst z opakovačů';

  @override
  String get settings_regionDefault => 'Výchozí region';

  @override
  String get settings_regionDefaultSubtitle =>
      'Používá se u kanálů bez vlastního regionu';

  @override
  String get settings_regionDefaultNone => 'Žádný';

  @override
  String settings_regionUseRadioDefault(String region) {
    return 'Výchozí rádia ($region)';
  }

  @override
  String get settings_regionNoRegion => 'Bez regionu (neomezeno)';

  @override
  String get settings_regionRadioDefault => 'Výchozí region rádia';

  @override
  String get settings_regionRadioDefaultSubtitle =>
      'Uloženo v rádiu. Používá se pro flood odeslané bez regionu, z této aplikace i z jakékoli jiné aplikace připojené k rádiu.';

  @override
  String get settings_regionRadioDefaultUpdated =>
      'Výchozí region rádia aktualizován';

  @override
  String get settings_regionRadioDefaultFailed =>
      'Výchozí region rádia se nepodařilo aktualizovat';

  @override
  String get settings_regionManagement_screenTitle => 'Správa regionů';

  @override
  String get settings_regionNameHint => 'Zadejte název regionu';

  @override
  String get settings_regionAddRegion => 'Přidat region';

  @override
  String get settings_regionFetchRegions => 'Načíst regiony z opakovačů';

  @override
  String get settings_regionFetchRegionsFail => 'Nebyly nalezeny žádné regiony';

  @override
  String get settings_regionFetchRegionsAlreadyExists =>
      'Tento region již byl přidán';

  @override
  String get settings_regionName => 'Název regionu';

  @override
  String get settings_regionDeleted => 'Region smazán';

  @override
  String get settings_deleteRegion => 'Smazat region';

  @override
  String settings_deleteRegionConfirm(String region) {
    return 'Odebrat „$region“ ze seznamu regionů?';
  }

  @override
  String get settings_location => 'Poloha';

  @override
  String get settings_locationSubtitle => 'Souřadnice GPS';

  @override
  String get settings_locationUpdated => 'Poloha a nastavení GPS aktualizovány';

  @override
  String get settings_locationBothRequired =>
      'Zadejte zeměpisnou šířku i délku.';

  @override
  String get settings_locationInvalid => 'Neplatná zeměpisná šířka nebo délka.';

  @override
  String get settings_locationGPSEnable => 'Povolit GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Povolí GPS pro automatickou aktualizaci polohy.';

  @override
  String get settings_locationIntervalSec => 'Interval GPS (sekundy)';

  @override
  String get settings_locationIntervalInvalid =>
      'Interval musí být alespoň 60 sekund a méně než 86400 sekund.';

  @override
  String get settings_latitude => 'Zeměpisná šířka';

  @override
  String get settings_longitude => 'Zeměpisná délka';

  @override
  String get settings_contactSettings => 'Nastavení kontaktů';

  @override
  String get settings_contactSettingsSubtitle =>
      'Nastavení způsobu přidávání kontaktů.';

  @override
  String get settings_privacyMode => 'Režim soukromí';

  @override
  String get settings_privacyModeSubtitle => 'Skrýt jméno/polohu v inzerátech';

  @override
  String get settings_privacyModeToggle =>
      'Přepněte režim soukromí a skryjte své jméno a polohu v inzerátech.';

  @override
  String get settings_privacyModeEnabled => 'Režim soukromí zapnut';

  @override
  String get settings_privacyModeDisabled => 'Režim soukromí vypnut';

  @override
  String get settings_privacy => 'Nastavení soukromí';

  @override
  String get settings_privacySubtitle => 'Určete, jaké informace se sdílejí.';

  @override
  String get settings_privacySettingsDescription =>
      'Vyberte, jaké informace vaše zařízení sdílí s ostatními.';

  @override
  String get settings_denyAll => 'Zakázat všem';

  @override
  String get settings_allowByContact => 'Jen kontaktům, které povolím';

  @override
  String get settings_allowAll => 'Povolit všem';

  @override
  String get settings_telemetryBaseMode => 'Kdo se může ptát na baterii a stav';

  @override
  String get settings_telemetryLocationMode => 'Kdo se může ptát na mou polohu';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Kdo se může ptát na data senzorů';

  @override
  String get settings_telemetryPerContactHint =>
      'Chcete-li kontakt povolit, otevřete jeho chat a v nabídce zvolte Nastavení kontaktu.';

  @override
  String get settings_advertLocation => 'Poloha v advertu';

  @override
  String get settings_advertLocationSubtitle => 'Zahrnout polohu do advertu.';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdate =>
      'Automatický advert s nulovým skokem při aktualizaci GPS';

  @override
  String get settings_autoZeroHopAdvertOnGpsUpdateSubtitle =>
      'Nastavení aplikace: při změně polohy GPS automaticky oznámí novou polohu pouze uzlům v okolí (vyžaduje Polohu v advertu).';

  @override
  String get settings_multiAck => 'Multi-ACK';

  @override
  String get settings_multiAckSubtitle =>
      'Odesílá další ACK pro lepší doručení; spotřebuje více vysílacího času';

  @override
  String get settings_telemetryModeUpdated => 'Režim telemetrie aktualizován';

  @override
  String get settings_actions => 'Akce';

  @override
  String get settings_deleteAllPaths => 'Smazat všechny cesty';

  @override
  String get settings_deleteAllPathsSubtitle =>
      'Vymazat všechna data cest z kontaktů.';

  @override
  String get settings_sendAdvertisement => 'Odeslat advert';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Ihned oznámit svou přítomnost';

  @override
  String get settings_advertisementSent => 'Advert odeslán';

  @override
  String get settings_syncTime => 'Synchronizovat čas';

  @override
  String get settings_syncTimeSubtitle =>
      'Nastavit hodiny zařízení podle času telefonu';

  @override
  String get settings_timeSynchronized => 'Čas synchronizován';

  @override
  String get settings_refreshContacts => 'Obnovit kontakty';

  @override
  String get settings_refreshContactsSubtitle =>
      'Znovu načíst seznam kontaktů ze zařízení';

  @override
  String get settings_rebootDevice => 'Restartovat zařízení';

  @override
  String get settings_rebootDeviceSubtitle => 'Restartovat zařízení MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Opravdu chcete zařízení restartovat? Budete odpojeni.';

  @override
  String get settings_debug => 'Ladění';

  @override
  String get settings_companionDebugLog => 'Ladicí log Companion';

  @override
  String get settings_companionDebugLogSubtitle =>
      'Příkazy, odpovědi a surová data BLE/TCP/USB';

  @override
  String get settings_appDebugLog => 'Ladicí log aplikace';

  @override
  String get settings_appDebugLogSubtitle => 'Ladicí zprávy aplikace';

  @override
  String get settings_about => 'O aplikaci';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshCore Open v$version';
  }

  @override
  String get settings_aboutLegalese => 'Projekt MeshCore Open Source 2026';

  @override
  String get settings_aboutDescription =>
      'Open-source klient Flutter pro zařízení MeshCore s mesh sítí LoRa.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Výšková data LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Název';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Stav';

  @override
  String get settings_infoBattery => 'Baterie';

  @override
  String get settings_infoPublicKey => 'Veřejný klíč';

  @override
  String get settings_publicKeyCopied => 'Veřejný klíč zkopírován';

  @override
  String get settings_infoContactsCount => 'Počet kontaktů';

  @override
  String get settings_infoChannelCount => 'Počet kanálů';

  @override
  String get settings_infoHardware => 'Hardware';

  @override
  String get settings_infoFirmware => 'Firmware';

  @override
  String get settings_presets => 'Předvolby';

  @override
  String get settings_presetCustom => 'Vlastní';

  @override
  String get settings_radioMatchWarning =>
      'Všechny uzly, se kterými komunikujete, musí používat stejnou frekvenci, šířku pásma a SF. Kódovací poměr (CR) se může lišit.';

  @override
  String get settings_frequency => 'Frekvence (MHz)';

  @override
  String get settings_frequencyHelper => '150.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Neplatná frekvence (150-2500 MHz)';

  @override
  String get settings_bandwidth => 'Šířka pásma';

  @override
  String get settings_spreadingFactor => 'Rozptylový faktor';

  @override
  String get settings_codingRate => 'Kódovací poměr';

  @override
  String get settings_txPower => 'Výkon TX (dBm)';

  @override
  String settings_txPowerRangeHelper(int min, int max) {
    return '$min až $max dBm';
  }

  @override
  String get settings_txPowerInvalid => 'Neplatný výkon TX';

  @override
  String get settings_clientRepeat => 'Off-grid opakování';

  @override
  String settings_clientRepeatFrequencyNote(String freq) {
    return 'Frekvence nastavena na $freq MHz pro off-grid opakování';
  }

  @override
  String get settings_clientRepeatSubtitle =>
      'Povolit tomuto zařízení opakovat pakety sítě mesh pro ostatní';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Off-grid opakování vyžaduje frekvenci 433, 869.495 nebo 918 MHz';

  @override
  String settings_error(String message) {
    return 'Chyba: $message';
  }

  @override
  String get appSettings_title => 'Nastavení aplikace';

  @override
  String get appSettings_appearance => 'Vzhled';

  @override
  String get appSettings_theme => 'Motiv';

  @override
  String get appSettings_themeSystem => 'Podle systému';

  @override
  String get appSettings_themeLight => 'Světlý';

  @override
  String get appSettings_themeDark => 'Tmavý';

  @override
  String get appSettings_colorTheme => 'Barevný motiv';

  @override
  String get appSettings_holidayAnimations => 'Animace svátečních zpráv';

  @override
  String get appSettings_holidayAnimationsSubtitle =>
      'Netopýři, krocan, Santa nebo ohňostroj, když někdo pošle sváteční přání';

  @override
  String get themes_title => 'Motivy';

  @override
  String get themes_default => 'MeshCore';

  @override
  String get themes_defaultSubtitle =>
      'Standardní barvy, řídí se nastavením Světlý / Tmavý';

  @override
  String get themes_builtIn => 'Vestavěné';

  @override
  String get themes_holidays => 'Svátky';

  @override
  String get themes_holidayAutoSwitch => 'Přepínat automaticky';

  @override
  String get themes_holidayAutoSwitchSubtitle =>
      'Použije motiv každého svátku od 17 dnů předem až do samotného dne';

  @override
  String themes_holidayAutoApplied(String holiday) {
    return 'Motiv $holiday je zapnut automaticky. Váš vlastní motiv se vrátí po svátku.';
  }

  @override
  String get themes_holidayAutoAppliedTag => 'Zapnuto automaticky';

  @override
  String get themes_myThemes => 'Mé motivy';

  @override
  String get themes_myThemesEmpty =>
      'Vytvořte si vlastní motiv výběrem pozadí a zvýrazňovací barvy.';

  @override
  String get themes_create => 'Vytvořit motiv';

  @override
  String get themes_import => 'Importovat motiv';

  @override
  String get themes_importHint => 'Vložte kód motivu';

  @override
  String get themes_importInvalid => 'Toto není platný kód motivu';

  @override
  String themes_imported(String name) {
    return 'Motiv „$name“ přidán';
  }

  @override
  String get themes_customize => 'Upravit kopii';

  @override
  String get themes_copyCode => 'Kopírovat kód motivu';

  @override
  String get themes_codeCopied => 'Kód motivu zkopírován';

  @override
  String themes_deleteConfirm(String name) {
    return 'Smazat motiv „$name“?';
  }

  @override
  String themes_copyName(String name) {
    return '$name – kopie';
  }

  @override
  String get themes_newTitle => 'Nový motiv';

  @override
  String get themes_editTitle => 'Upravit motiv';

  @override
  String get themes_name => 'Název';

  @override
  String get themes_nameRequired => 'Pojmenujte svůj motiv';

  @override
  String get themes_background => 'Pozadí';

  @override
  String get themes_backgroundHelp => 'Tmavé pozadí vytvoří tmavý motiv';

  @override
  String get themes_accent => 'Zvýraznění';

  @override
  String get themes_accentHelp => 'Tlačítka, zvýraznění a vaše bubliny v chatu';

  @override
  String get themes_hexColor => 'Barva hex';

  @override
  String get themes_preview => 'Náhled';

  @override
  String get themes_previewIncoming => 'Je dnes večer někdo na mesh?';

  @override
  String get themes_previewOutgoing => 'Slyším vás dobře!';

  @override
  String get themes_previewSwitch => 'Oznámení';

  @override
  String get themes_lowContrast => 'Zvýraznění je na tomto pozadí špatně vidět';

  @override
  String get themes_saveAndUse => 'Uložit a použít';

  @override
  String get themes_icons => 'Ikony';

  @override
  String get themes_iconsHelp =>
      'Klepnutím na ikonu ji vyměníte za jinou ikonu nebo vlastní obrázek';

  @override
  String get themes_iconChanged => 'Změněno';

  @override
  String get themes_iconSend => 'Tlačítko odeslání';

  @override
  String get themes_iconRepeater => 'Opakovače';

  @override
  String get themes_iconRoom => 'Místnosti';

  @override
  String get themes_iconSensor => 'Senzory';

  @override
  String get themes_mapMarkers => 'Značky na mapě';

  @override
  String get themes_mapMarkersHelp =>
      'Vyměňte značky uzlů a své značky na mapě';

  @override
  String get themes_iconUsePicture => 'Použít obrázek';

  @override
  String get themes_iconReset => 'Použít výchozí ikonu';

  @override
  String get themes_iconPictureFailed => 'Tento obrázek nelze použít';

  @override
  String get themes_exportFile => 'Exportovat do souboru';

  @override
  String get themes_exportAll => 'Exportovat mé motivy';

  @override
  String get themes_importFile => 'Importovat ze souboru';

  @override
  String get themes_pasteCode => 'Vložit kód motivu';

  @override
  String get themes_exportFailed => 'Motivy se nepodařilo exportovat';

  @override
  String themes_importFileResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importováno $count motivů',
      many: 'Importováno $count motivů',
      few: 'Importovány $count motivy',
      one: 'Importován 1 motiv',
    );
    return '$_temp0';
  }

  @override
  String get themes_importFileNone =>
      'V tomto souboru nebyly nalezeny žádné motivy';

  @override
  String get chatBackground_title => 'Pozadí chatu';

  @override
  String get chatBackground_thisChatOnly => 'Jen pro tento chat';

  @override
  String chatBackground_themeOverrides(String name) {
    return 'Váš motiv „$name“ nastavuje pozadí ve všech chatech. Chcete-li použít toto, vypněte to v motivu.';
  }

  @override
  String get chatBackground_none => 'Žádné';

  @override
  String get chatBackground_picture => 'Obrázek';

  @override
  String get chatBackground_choosePicture => 'Vybrat obrázek';

  @override
  String get chatBackground_pictureFailed => 'Tento obrázek nelze použít';

  @override
  String get chatBackground_fade => 'Průhlednost';

  @override
  String get themes_chatBackground => 'Pozadí chatu';

  @override
  String get themes_chatBackgroundHelp =>
      'Zobrazuje se v chatech, které nemají vlastní pozadí';

  @override
  String get themes_chatBackgroundEverywhere => 'Použít ve všech chatech';

  @override
  String get themes_chatBackgroundEverywhereHelp =>
      'Nahradí také pozadí nastavená u jednotlivých chatů';

  @override
  String get appSettings_language => 'Jazyk';

  @override
  String get appSettings_languageSystem => 'Podle systému';

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
  String get appSettings_languagePt => 'Português (Brasil)';

  @override
  String get appSettings_languagePtPt => 'Português (Portugal)';

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
  String get appSettings_languageCs => 'Čeština';

  @override
  String get repeater_pathHashModeOption0 => '1 bajt';

  @override
  String get repeater_pathHashModeOption1 => '2 bajty';

  @override
  String get repeater_pathHashModeOption2 => '3 bajty';

  @override
  String get repeater_pathHashModeOption3 => '4 bajty';

  @override
  String get settings_pathHashModeHelper =>
      'Velikost ID každého uzlu zaznamenaného v cestě flood paketů odesílaných tímto rádiem: 1 bajt (256 ID, až 64 skoků), 2 bajty (65 tis. ID, až 32 skoků), 3 bajty (16 mil. ID, až 21 skoků). Větší ID snižují kolize, ale opakovače s firmwarem starším než v1.14 zahazují pakety s 2- nebo 3bajtovými ID.';

  @override
  String settings_requiresFirmware(String version) {
    return 'Vyžaduje firmware $version nebo novější';
  }

  @override
  String get appSettings_channelMinHops =>
      'Znovu odesílat zprávy kanálu, dokud nedojdou dostatečně daleko';

  @override
  String get appSettings_channelMinHopsSubtitle =>
      'Pokud Vaši zprávu neslyšíte zpět přes dostatek opakovačů, odešle se znovu. Spotřebuje více vysílacího času.';

  @override
  String appSettings_channelMinHopsCount(int count) {
    return 'Požadovaný počet skoků: $count';
  }

  @override
  String appSettings_channelMinHopsRetries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}krát',
      many: '${count}krát',
      few: '${count}krát',
      one: '1krát',
    );
    return 'Znovu odeslat nejvýše $_temp0';
  }

  @override
  String get appSettings_channelMinHopsCountRepeaters =>
      'Počítat i různé opakovače v okolí';

  @override
  String appSettings_channelMinHopsCountRepeatersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count různých opakovačů v okolí',
      many: '$count různého opakovače v okolí',
      few: '$count různé opakovače v okolí',
      one: '1 opakovač v okolí',
    );
    return 'Považovat zprávu za odeslanou, když ji zopakuje $_temp0, i když neslyšíte, že by šla dál.';
  }

  @override
  String get appSettings_enableMessageTracing =>
      'Zobrazovat v zprávách celou cestu přes opakovače';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Zobrazí také počty opakování a doby přenosu. Dlouze stiskněte zprávu a zvolte Cesta pro úplné podrobnosti.';

  @override
  String get appSettings_regionOnHopsLine => 'Region vedle počtu skoků';

  @override
  String get appSettings_regionOnHopsLineSubtitle =>
      'Zobrazit region zprávy kanálu na stejném řádku jako počet skoků místo pod ním.';

  @override
  String get appSettings_notifications => 'Oznámení';

  @override
  String get appSettings_enableNotifications => 'Povolit oznámení';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Přijímat oznámení o zprávách a advertech';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Oprávnění k oznámením bylo odepřeno';

  @override
  String get appSettings_notificationsEnabled => 'Oznámení povolena';

  @override
  String get appSettings_notificationsDisabled => 'Oznámení zakázána';

  @override
  String get appSettings_messageNotifications => 'Oznámení o zprávách';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Zobrazit oznámení při příchozí nové zprávě';

  @override
  String get appSettings_batteryOptimization => 'Aktivita na pozadí';

  @override
  String get appSettings_batteryOptimizationSubtitle =>
      'V nastavení baterie nastavte MeshCore Open na „Neoptimalizovat“, aby zprávy chodily i na pozadí';

  @override
  String get appSettings_channelMessageNotifications =>
      'Oznámení o zprávách kanálů';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Zobrazit oznámení při příchozích zprávách kanálu';

  @override
  String get appSettings_advertisementNotifications => 'Oznámení o advertech';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Zobrazit oznámení při objevení nových uzlů';

  @override
  String get appSettings_messaging => 'Zprávy';

  @override
  String get appSettings_clearPathOnMaxRetry =>
      'Vymazat cestu po maximu pokusů';

  @override
  String get appSettings_clearPathOnMaxRetrySubtitle =>
      'Resetovat cestu kontaktu po 5 neúspěšných pokusech o odeslání';

  @override
  String get appSettings_pathsWillBeCleared =>
      'Cesty budou vymazány po 5 neúspěšných pokusech';

  @override
  String get appSettings_pathsWillNotBeCleared =>
      'Cesty nebudou automaticky mazány';

  @override
  String get appSettings_autoRouteRotation => 'Automatické střídání tras';

  @override
  String get appSettings_autoRouteRotationSubtitle =>
      'Střídat nejlepší cesty a režim flood';

  @override
  String get appSettings_autoRouteRotationEnabled =>
      'Automatické střídání tras zapnuto';

  @override
  String get appSettings_autoRouteRotationDisabled =>
      'Automatické střídání tras vypnuto';

  @override
  String get appSettings_maxMessageRetries => 'Maximum opakování zprávy';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Počet opakovaných pokusů, než se zpráva označí jako neodeslaná';

  @override
  String get appSettings_ipfsImageLinks => 'Konfigurace poskytovatele IPFS';

  @override
  String get appSettings_ipfsImageLinksSubtitle =>
      'Nahrávání obrázků (nebo souborů) z URL přes poskytovatele IPFS a výchozí brána pro příjem';

  @override
  String get appSettings_loadLinkImages => 'Načítat obrázky z odkazů';

  @override
  String get appSettings_loadLinkImagesSubtitle =>
      'Zobrazit obrázky z odkazů ve zprávách. Načtení obrázku sdílí vaši IP adresu se stránkou, která jej hostuje.';

  @override
  String get appSettings_showLinkImagesByDefault =>
      'Ve výchozím stavu zobrazovat obrázky z odkazů ve všech chatech';

  @override
  String get appSettings_showLinkImagesByDefaultSubtitle =>
      'Načítat obrázky z odkazů v každém chatu, pokud jste je tam nevypnuli. Sdílí to vaši IP adresu s hostiteli obrázků v každém chatu.';

  @override
  String get appSettings_publicIpfsGateway => 'Veřejná brána';

  @override
  String get appSettings_ipfsGatewayDeactivated => 'Deaktivováno';

  @override
  String get appSettings_ipfsGatewayCustom => 'Vlastní (Kubo)';

  @override
  String get appSettings_uploadIpfsProvider => 'Poskytovatel nahrávání';

  @override
  String get appSettings_uploadIpfsGateway => 'Brána pro nahrávání';

  @override
  String get appSettings_uploadIpfsGatewaySubtitle =>
      'Brána pro sdílení obrázku nebo souboru jako odkazu URL. Nechte prázdné pro formát ipfs:, který jiní klienti nemusí umět otevřít.';

  @override
  String get appSettings_uploadIpfsEndpoint => 'Koncový bod nahrávání';

  @override
  String get appSettings_uploadIpfsEndpointSubtitle =>
      'Koncový bod API používaný k nahrávání souborů';

  @override
  String get appSettings_uploadIpfsApiKey => 'Klíč API pro nahrávání';

  @override
  String get appSettings_ipfsImageLinksDescription =>
      'Veřejná brána stahuje obrázky ve formátu ipfs:. Brána pro nahrávání slouží k vytváření odkazů ke sdílení nahraných obrázků nebo souborů z URL.';

  @override
  String get appSettings_battery => 'Baterie';

  @override
  String get appSettings_batteryChemistry => 'Typ baterie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Nastaveno pro každé zařízení ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Pro výběr se připojte k zařízení';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_batteryLipoHv => 'LiPo HV (3.0-4.35V)';

  @override
  String get appSettings_mapDisplay => 'Zobrazení mapy';

  @override
  String get appSettings_showRepeaters => 'Zobrazit opakovače';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Zobrazit uzly opakovačů na mapě';

  @override
  String get appSettings_showChatNodes => 'Zobrazit chatovací uzly';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Zobrazit chatovací uzly na mapě';

  @override
  String get appSettings_showOtherNodes => 'Zobrazit ostatní uzly';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Zobrazit ostatní typy uzlů na mapě';

  @override
  String get appSettings_showOnlineLinks => 'Zobrazit spojení z online mapy';

  @override
  String get appSettings_showOnlineLinksSubtitle =>
      'Zobrazit spojnice mezi uzly z online mapy';

  @override
  String get appSettings_timeFilter => 'Časový filtr';

  @override
  String get appSettings_timeFilterShowAll => 'Zobrazit všechny uzly';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Zobrazit uzly za posledních $hours hodin';
  }

  @override
  String get appSettings_mapTimeFilter => 'Časový filtr mapy';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Zobrazit uzly objevené během:';

  @override
  String get appSettings_allTime => 'Celé období';

  @override
  String get appSettings_lastHour => 'Poslední hodina';

  @override
  String get appSettings_last6Hours => 'Posledních 6 hodin';

  @override
  String get appSettings_last24Hours => 'Posledních 24 hodin';

  @override
  String get appSettings_lastWeek => 'Poslední týden';

  @override
  String get appSettings_rasterTileSource => 'Zdroj rastrových dlaždic';

  @override
  String get appSettings_stadiaEndpoint => 'Koncový bod Stadia';

  @override
  String get appSettings_stadiaApiKey => 'Klíč API Stadia';

  @override
  String get appSettings_stadiaApiKeyRequired =>
      'Vyžadováno pro použití Stadia Maps';

  @override
  String appSettings_stadiaApiKeyConfigured(String maskedKey) {
    return 'Nakonfigurováno: $maskedKey';
  }

  @override
  String get appSettings_stadiaApiKeyDialogDescription =>
      'Zadejte svůj klíč API Stadia Maps. Aplikace jej používá pro požadavky na rastrové dlaždice.';

  @override
  String get appSettings_offlineMapCache => 'Offline mezipaměť mapy';

  @override
  String get appSettings_unitsTitle => 'Jednotky';

  @override
  String get appSettings_unitsMetric => 'Metrické (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiální (ft / mi)';

  @override
  String get appSettings_noAreaSelected => 'Není vybrána žádná oblast';

  @override
  String appSettings_areaSelectedZoom(int minZoom, int maxZoom) {
    return 'Oblast vybrána (zoom $minZoom-$maxZoom)';
  }

  @override
  String get appSettings_debugCard => 'Ladění';

  @override
  String get appSettings_appDebugLogging => 'Ladicí logování aplikace';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Zaznamenávat ladicí zprávy aplikace pro řešení potíží';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Ladicí logování aplikace zapnuto';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Ladicí logování aplikace vypnuto';

  @override
  String get contacts_title => 'Kontakty';

  @override
  String get contacts_noContacts => 'Zatím žádné kontakty';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakty se objeví, když zařízení vyšlou advert';

  @override
  String get contacts_unread => 'Nepřečtené';

  @override
  String get contacts_searchContactsNoNumber => 'Hledat kontakty...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Hledat $number$str kontaktů...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Hledat $number$str oblíbených...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Hledat $number$str uživatelů...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Hledat $number$str opakovačů...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Hledat $number$str room serverů...';
  }

  @override
  String get contacts_noUnreadContacts => 'Žádné nepřečtené kontakty';

  @override
  String get contacts_noContactsFound =>
      'Nebyly nalezeny žádné kontakty ani skupiny';

  @override
  String get contacts_storageFull =>
      'Úložiště kontaktů v uzlu je plné. Nové uzly nelze přidat, dokud nebudou kontakty odebrány.';

  @override
  String get contacts_deleteContact => 'Smazat kontakt';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Odebrat $contactName z kontaktů?';
  }

  @override
  String get contacts_removeFromContacts => 'Odebrat z kontaktů';

  @override
  String contacts_removeFromContactsConfirm(String contactName) {
    return '$contactName se přesune mezi objevené kontakty. Historie chatu bude smazána.';
  }

  @override
  String get contacts_keepChatHistory => 'Zachovat historii chatu';

  @override
  String get contacts_remove => 'Odebrat';

  @override
  String get contacts_removeAutoAddNote =>
      'Vaše rádio tento typ kontaktu přidává automaticky, takže se vrátí při příštím advertu. Chcete-li jej ponechat odebraný, vypněte automatické přidávání v nastavení Kontaktů.';

  @override
  String get contacts_removeFailed =>
      'Rádio odebrání nepotvrdilo. Kontakt nebyl odebrán.';

  @override
  String contacts_discoveredNearby(int count) {
    return 'Objeveno v okolí ($count)';
  }

  @override
  String get contacts_noContactsDiscoveredHint =>
      'Uzly, které vaše rádio slyší, ale ještě nepřidalo, jsou uvedeny mezi objevenými kontakty';

  @override
  String get contacts_manageRepeater => 'Spravovat opakovač';

  @override
  String get contacts_manageRoom => 'Spravovat room server';

  @override
  String get contacts_roomLogin => 'Přihlášení k room serveru';

  @override
  String get contacts_openChat => 'Otevřít chat';

  @override
  String get contacts_editGroup => 'Upravit skupinu';

  @override
  String get contacts_deleteGroup => 'Smazat skupinu';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Odebrat „$groupName“?';
  }

  @override
  String get contacts_newGroup => 'Nová skupina';

  @override
  String get contacts_moreOptions => 'Další možnosti';

  @override
  String get contacts_searchOpen => 'Hledat kontakty';

  @override
  String get contacts_searchClose => 'Zavřít hledání';

  @override
  String get contacts_groupName => 'Název skupiny';

  @override
  String get contacts_groupNameRequired => 'Název skupiny je povinný';

  @override
  String get contacts_groupNameReserved => 'Tento název skupiny je rezervován';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Skupina „$name“ již existuje';
  }

  @override
  String get contacts_filterContacts => 'Filtrovat kontakty...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Žádné kontakty neodpovídají filtru';

  @override
  String get contacts_noMembers => 'Žádní členové';

  @override
  String get contacts_lastSeenNow => 'nedávno';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 hod.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours hod.';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 den';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days dn.';
  }

  @override
  String get contact_info => 'Informace o kontaktu';

  @override
  String get contact_settings => 'Nastavení kontaktu';

  @override
  String get contact_telemetry => 'Telemetrie';

  @override
  String get contact_lastSeen => 'Naposledy viděn';

  @override
  String get contact_clearChat => 'Vymazat chat';

  @override
  String get contact_teleBase => 'Základní telemetrie';

  @override
  String get contact_teleBaseSubtitle =>
      'Povolit sdílení stavu baterie a základní telemetrie';

  @override
  String get contact_teleLoc => 'Telemetrie polohy';

  @override
  String get contact_teleLocSubtitle => 'Povolit sdílení údajů o poloze';

  @override
  String get contact_teleEnv => 'Telemetrie prostředí';

  @override
  String get contact_teleEnvSubtitle =>
      'Povolit sdílení dat z environmentálních senzorů';

  @override
  String get channels_title => 'Kanály';

  @override
  String get channels_noChannelsConfigured => 'Žádné nakonfigurované kanály';

  @override
  String get channels_addPublicChannel => 'Přidat veřejný kanál';

  @override
  String get channels_searchChannels => 'Hledat kanály...';

  @override
  String get channels_noChannelsFound => 'Žádné kanály nenalezeny';

  @override
  String channels_channelIndex(int index) {
    return 'Kanál $index';
  }

  @override
  String get channels_public => 'Veřejný';

  @override
  String channels_via(String path) {
    return 'přes $path';
  }

  @override
  String get channels_private => 'Soukromý';

  @override
  String get channels_hashtag => 'Hashtag';

  @override
  String get channels_addSectionJoin => 'Připojit se k existujícímu';

  @override
  String get channels_addSectionCreate => 'Vytvořit nový';

  @override
  String get channels_dragToReorder => 'Přetažením změníte pořadí';

  @override
  String get channels_editChannel => 'Upravit kanál';

  @override
  String get channels_notificationSettings => 'Nastavení oznámení';

  @override
  String get channels_notifyAll => 'Všechny zprávy';

  @override
  String get channels_notifyMentionsOnly => 'Pouze zmínky';

  @override
  String get channels_notifyNone => 'Ztlumeno';

  @override
  String channels_notificationModeTooltip(String mode) {
    return 'Oznámení: $mode';
  }

  @override
  String get channels_muteChannel => 'Ztlumit kanál';

  @override
  String get channels_unmuteChannel => 'Zrušit ztlumení kanálu';

  @override
  String get channels_deleteChannel => 'Smazat kanál';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Smazat „$name“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanál „$name“ se nepodařilo smazat';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanál „$name“ byl smazán';
  }

  @override
  String get channels_addChannel => 'Přidat kanál';

  @override
  String get channels_channelIndexLabel => 'Index kanálu';

  @override
  String get channels_channelName => 'Název kanálu';

  @override
  String get channels_usePublicChannel => 'Použít veřejný kanál';

  @override
  String get channels_standardPublicPsk => 'Standardní veřejné PSK';

  @override
  String get channels_pskHex => 'PSK (hex)';

  @override
  String get channels_generateRandomPsk => 'Vygenerovat náhodné PSK';

  @override
  String get channels_enterChannelName => 'Zadejte název kanálu';

  @override
  String get channels_pskMustBe32Hex => 'PSK musí mít 32 hex znaků';

  @override
  String channels_channelAdded(String name) {
    return 'Kanál „$name“ byl přidán';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Upravit kanál $index';
  }

  @override
  String get channels_smazCompression => 'Komprese SMAZ';

  @override
  String get channels_cyr2latCompression => 'Komprese Cyr2Lat';

  @override
  String get channels_cyr2latCompressionDscr =>
      'Při odesílání nahradí některé znaky cyrilice latinkou.';

  @override
  String get channels_cyr2latSettingsHeading => 'Nastavení Cyr2Lat';

  @override
  String get channels_cyr2latSettingsSubheading => 'Seznam náhrad';

  @override
  String get channels_cyr2latSettingsDscr =>
      'Upravit JSON konfiguraci nahrazování znaků';

  @override
  String get channels_cyr2latSettingsDialogHint => 'JSON mapa náhrad';

  @override
  String channels_cyr2latSettingsDialogWrongJSON(Object error) {
    return 'Neplatný JSON: $error';
  }

  @override
  String channels_channelUpdated(String name) {
    return 'Kanál „$name“ byl aktualizován';
  }

  @override
  String get settings_cyr2latProfileAdd => 'Přidat profil Cyr2Lat';

  @override
  String get settings_cyr2latProfileName => 'Název profilu';

  @override
  String get settings_cyr2latProfileNameEmpty =>
      'Název profilu nesmí být prázdný';

  @override
  String get settings_cyr2latProfileAdded => 'Profil byl úspěšně přidán';

  @override
  String get settings_cyr2latProfileUpdated =>
      'Profil byl úspěšně aktualizován';

  @override
  String get settings_cyr2latProfileEdit => 'Upravit profil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDelete => 'Smazat profil Cyr2Lat';

  @override
  String get settings_cyr2latProfileDeleted => 'Profil byl úspěšně smazán';

  @override
  String settings_cyr2latProfileDeleteDscr(String name) {
    return 'Opravdu chcete smazat profil „$name“?';
  }

  @override
  String get channels_publicChannelAdded => 'Veřejný kanál byl přidán';

  @override
  String get channels_noFreeSlots => 'Všechny sloty kanálů jsou obsazené';

  @override
  String get channels_sortBy => 'Řadit podle';

  @override
  String get channels_sortManual => 'Ručně';

  @override
  String get channels_sortAZ => 'A–Z';

  @override
  String get channels_sortLatestMessages => 'Nejnovější zprávy';

  @override
  String get channels_sortUnread => 'Nepřečtené';

  @override
  String get channels_createPrivateChannel => 'Vytvořit soukromý kanál';

  @override
  String get channels_createPrivateChannelDesc => 'Zabezpečený tajným klíčem.';

  @override
  String get channels_joinPrivateChannel => 'Připojit se k soukromému kanálu';

  @override
  String get channels_joinPrivateChannelDesc => 'Zadejte tajný klíč ručně.';

  @override
  String get channels_joinPublicChannel => 'Připojit se k veřejnému kanálu';

  @override
  String get channels_joinPublicChannelDesc => 'Připojit se může kdokoli.';

  @override
  String get channels_joinHashtagChannel => 'Připojit se ke kanálu s hashtagem';

  @override
  String get channels_joinHashtagChannelDesc =>
      'K hashtagovým kanálům se může připojit kdokoli.';

  @override
  String get channels_scanQrCode => 'Skenovat QR kód';

  @override
  String get channels_scanQrCodeComingSoon => 'Již brzy';

  @override
  String get channels_scanQrCodeDesc =>
      'Připojte se ke kanálu nebo komunitě pomocí QR kódu.';

  @override
  String get channels_scanQrInstructions =>
      'Namiřte fotoaparát na QR kód kanálu nebo komunity';

  @override
  String get channels_invalidQrCode =>
      'Toto není QR kód kanálu ani komunity MeshCore';

  @override
  String get channels_joinChannelTitle => 'Připojit se ke kanálu';

  @override
  String channels_joinChannelConfirm(String name) {
    return 'Přidat „$name“ do vašeho rádia?';
  }

  @override
  String channels_alreadyOnRadio(String name) {
    return '„$name“ už ve vašem rádiu je';
  }

  @override
  String get channels_enterHashtag => 'Zadejte hashtag';

  @override
  String get channels_hashtagHint => 'např. #tym';

  @override
  String channels_regionSetTo(String region) {
    return 'Region: $region';
  }

  @override
  String get channels_regionNotSet => 'Region: žádný';

  @override
  String get channels_regionSelect_Title => 'Vyberte region';

  @override
  String get channels_clearRegion => 'Zrušit region';

  @override
  String get channels_regionDefaultSuffix => '(výchozí)';

  @override
  String get channels_regionRadioDefaultSuffix => '(výchozí pro rádio)';

  @override
  String channels_regionRadioDefaultApplies(String region) {
    return 'Toto rádio odesílá flood zprávy bez regionu ve svém výchozím regionu: $region.';
  }

  @override
  String get channels_regionSelectExplanation =>
      'Flood zprávy na tomto kanálu budou předávat pouze opakovače ve vybraném regionu.';

  @override
  String get channels_regionEmpty => 'Zatím žádné regiony.';

  @override
  String get channels_manageRegions => 'Spravovat regiony';

  @override
  String get chat_noMessages => 'Zatím žádné zprávy';

  @override
  String get chatSearch_tooltip => 'Hledat zprávy';

  @override
  String get chatSearch_hint => 'Hledat zprávy';

  @override
  String get chatSearch_close => 'Zavřít hledání';

  @override
  String chatSearch_resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count výsledků',
      many: '$count výsledku',
      few: '$count výsledky',
      one: '1 výsledek',
    );
    return '$_temp0';
  }

  @override
  String get chatSearch_noResults => 'Žádné odpovídající zprávy';

  @override
  String get chatSearch_noResultsHint =>
      'Zkuste jiné slovo nebo zkontrolujte překlepy';

  @override
  String get chatSearch_jumpFailed => 'Tuto zprávu se v chatu nepodařilo najít';

  @override
  String get chat_sendMessage => 'Odeslat zprávu';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Odeslat zprávu kontaktu $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Odešlete zprávu a začněte';

  @override
  String get chat_originalMessageNotFound => 'Původní zpráva nebyla nalezena';

  @override
  String chat_replyingTo(String name) {
    return 'Odpověď uživateli $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Odpovědět uživateli $name';
  }

  @override
  String get chat_location => 'Poloha';

  @override
  String get chat_typeMessage => 'Napište zprávu...';

  @override
  String get chat_futureTimestampWarning =>
      'Čas této zprávy je v budoucnosti, takže hodiny odesílatele mohou být špatně. Zpráva je zobrazena v pořadí, v jakém dorazila.';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Zpráva je příliš dlouhá (max. $maxBytes bajtů).';
  }

  @override
  String get chat_messageCopied => 'Zpráva zkopírována';

  @override
  String get chat_messageDeleted => 'Zpráva smazána';

  @override
  String get chat_selectMessages => 'Vybrat zprávy';

  @override
  String chat_selectedCount(int count) {
    return 'Vybráno: $count';
  }

  @override
  String get chat_selectAll => 'Vybrat vše';

  @override
  String get chat_clearSelection => 'Zrušit výběr';

  @override
  String get chat_deleteSelectedTitle => 'Smazat zprávy?';

  @override
  String chat_deleteSelectedConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Smazat $count zpráv z tohoto zařízení?',
      many: 'Smazat $count zprávy z tohoto zařízení?',
      few: 'Smazat $count zprávy z tohoto zařízení?',
      one: 'Smazat 1 zprávu z tohoto zařízení?',
    );
    return '$_temp0';
  }

  @override
  String chat_messagesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Smazáno $count zpráv',
      many: 'Smazáno $count zprávy',
      few: 'Smazány $count zprávy',
      one: 'Smazána 1 zpráva',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_markedSpamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zpráv označeno jako spam',
      many: '$count zprávy označeno jako spam',
      few: '$count zprávy označeny jako spam',
      one: '1 zpráva označena jako spam',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_markedNotSpamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zpráv označeno jako ne-spam',
      many: '$count zprávy označeno jako ne-spam',
      few: '$count zprávy označeny jako ne-spam',
      one: '1 zpráva označena jako ne-spam',
    );
    return '$_temp0';
  }

  @override
  String get chat_retryingMessage => 'Opakované odesílání zprávy';

  @override
  String chat_retryCount(int current, int max) {
    return 'Pokus $current/$max';
  }

  @override
  String get chat_selectSendAction => 'Vyberte způsob odeslání';

  @override
  String get chat_sendGif => 'Odeslat GIF';

  @override
  String get chat_shareMyLocation => 'Sdílet mou polohu';

  @override
  String get chat_noRadioLocation => 'Vaše rádio nemá nastavenou polohu';

  @override
  String get chat_removeGif => 'Odebrat GIF';

  @override
  String get chat_cancelReply => 'Zrušit odpověď';

  @override
  String get chat_sendImageLora =>
      'Odeslat obrázek v nízkém rozlišení přes rádio';

  @override
  String get chat_sendImageIpfs => 'Odeslat obrázek nebo soubor přes IPFS';

  @override
  String chat_ipfsUploadFailed(String error) {
    return 'Nahrání na IPFS selhalo: $error';
  }

  @override
  String get chat_ipfsUploadNotConfigured =>
      'Nejprve nastavte poskytovatele nahrávání IPFS v nastavení aplikace.';

  @override
  String get chat_ipfsSelectedFileEmpty => 'Vybraný soubor je prázdný.';

  @override
  String get chat_ipfsEndpointInvalid =>
      'Koncový bod nahrávání IPFS musí být úplná adresa http:// nebo https://. Zkontrolujte ji v nastavení aplikace.';

  @override
  String get chat_ipfsPinataTokenMissing =>
      'Pinata vyžaduje API klíč nebo JWT. Přidejte jej v nastavení aplikace.';

  @override
  String get chat_ipfsFilebaseTokenMissing =>
      'Filebase vyžaduje API token. Přidejte jej v nastavení aplikace.';

  @override
  String get chat_ipfsKuboPathInvalid =>
      'Koncový bod nahrávání Kubo musí končit na /api/v0/add. Zkontrolujte ho v nastavení aplikace.';

  @override
  String get chat_ipfsLinkNoRoom =>
      'Pro odkaz na obrázek není dost místa. Zkraťte zprávu a zkuste to znovu.';

  @override
  String get chat_ipfsLinkOverLimit =>
      'Odkaz na obrázek byl přidán, ale zpráva je nyní příliš dlouhá. Před odesláním ji zkraťte.';

  @override
  String get chat_imagePickFailed => 'Obrázek se nepodařilo otevřít';

  @override
  String get chat_receivedGif => 'Přijat GIF';

  @override
  String get chat_reply => 'Odpovědět';

  @override
  String get chat_addReaction => 'Přidat reakci';

  @override
  String get chat_me => 'Já';

  @override
  String get reaction_report => 'Emoji reakce';

  @override
  String get emojiCategorySmileys => 'Smajlíci';

  @override
  String get emojiCategoryGestures => 'Gesta';

  @override
  String get emojiCategoryHearts => 'Srdce';

  @override
  String get emojiCategoryObjects => 'Předměty';

  @override
  String get gifPicker_title => 'Vyberte GIF';

  @override
  String get gifPicker_searchHint => 'Hledat GIFy...';

  @override
  String get gifPicker_poweredBy => 'Poskytuje GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Žádné GIFy nenalezeny';

  @override
  String get gifPicker_failedLoad => 'GIFy se nepodařilo načíst';

  @override
  String get gifPicker_failedSearch => 'Vyhledávání GIFů selhalo';

  @override
  String get gifPicker_noInternet => 'Žádné připojení k internetu';

  @override
  String get debugLog_appTitle => 'Ladicí log aplikace';

  @override
  String get debugLog_bleTitle => 'Ladicí log BLE';

  @override
  String get debugLog_copyLog => 'Kopírovat log';

  @override
  String get debugLog_clearLog => 'Vymazat log';

  @override
  String get debugLog_copied => 'Ladicí log zkopírován';

  @override
  String get debugLog_bleCopied => 'Log BLE zkopírován';

  @override
  String get debugLog_noEntries => 'Zatím žádné ladicí logy';

  @override
  String get debugLog_enableInSettings =>
      'Zapněte ladicí logování aplikace v nastavení';

  @override
  String get debugLog_frames => 'Rámce';

  @override
  String get debugLog_rawLogRx => 'Surový log-RX';

  @override
  String get debugLog_noBleActivity => 'Zatím žádná aktivita BLE';

  @override
  String debugFrame_length(int count) {
    return 'Délka rámce: $count bajtů';
  }

  @override
  String debugFrame_command(String value) {
    return 'Příkaz: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Rámec textové zprávy:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Veřejný klíč příjemce: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Časová značka: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Příznaky: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Typ textu: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypePlain => 'Prostý';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex výpis:';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skoků',
      many: 'skoku',
      few: 'skoky',
      one: 'skok',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_removePath => 'Odebrat cestu';

  @override
  String get chat_noPathHistoryYet =>
      'Zatím žádná historie cest.\nOdešlete zprávu a cesty se objeví.';

  @override
  String get chat_pathCleared =>
      'Cesta vymazána. Další zpráva znovu vyhledá trasu.';

  @override
  String get chat_fullPath => 'Celá cesta';

  @override
  String get routing_title => 'Směrování';

  @override
  String get routing_modeAuto => 'Auto';

  @override
  String get routing_modeFlood => 'Flood';

  @override
  String get routing_modeManual => 'Ručně';

  @override
  String get routing_modeDirect => 'Přímo';

  @override
  String get routing_modeAutoHint =>
      'Automaticky vybere nejlepší známou cestu a pokud žádnou nezná, použije flood.';

  @override
  String get routing_modeFloodHint =>
      'Vysílá přes všechny opakovače. Nejspolehlivější, ale zabírá více vysílacího času.';

  @override
  String get routing_modeManualHint =>
      'Vždy odesílá přesně po cestě, kterou nastavíte.';

  @override
  String get routing_modeDirectHint =>
      'Vždy odešle zprávu přímo tomuto kontaktu, bez skoků přes opakovače. Použijte, když je v dosahu rádia.';

  @override
  String get routing_currentRoute => 'Aktuální trasa';

  @override
  String get routing_directNoHops => 'Přímo — bez skoků přes opakovače';

  @override
  String get routing_noPathYet =>
      'Zatím žádná cesta. Další zpráva se bude šířit flood, dokud se nenajde trasa.';

  @override
  String get routing_floodBroadcast => 'Vysílání přes všechny opakovače';

  @override
  String get routing_editPath => 'Upravit cestu';

  @override
  String get routing_forgetPath => 'Zapomenout cestu';

  @override
  String get routing_knownPaths => 'Známé cesty';

  @override
  String get routing_knownPathsHint => 'Klepnutím na cestu se na ni přepnete.';

  @override
  String get routing_inUse => 'Používá se';

  @override
  String get routing_qualityStrong => 'Silný první skok';

  @override
  String get routing_qualityGood => 'Dobrý první skok';

  @override
  String get routing_qualityFair => 'Průměrný první skok';

  @override
  String get routing_qualityWorked => 'Již doručovala';

  @override
  String get routing_qualityFlood => 'Zachyceno přes flood';

  @override
  String get routing_qualityUntested => 'Nevyzkoušeno';

  @override
  String routing_lastWorked(String when) {
    return 'fungovala $when';
  }

  @override
  String get routing_neverWorked => 'nikdy nepotvrzena';

  @override
  String routing_deliveryCounts(int successes, int failures) {
    return '$successes doručeno, $failures selhalo';
  }

  @override
  String get routing_floodDelivery => 'Doručení flood';

  @override
  String get pathEditor_title => 'Sestavit cestu';

  @override
  String pathEditor_hopCounter(int count) {
    return '$count z 64 skoků';
  }

  @override
  String get pathEditor_noHops =>
      'Zatím žádné skoky. Klepnutím na opakovače níže je přidáte v pořadí, nebo uložte bez skoků pro přímé odeslání.';

  @override
  String get pathEditor_addHops => 'Přidejte skoky v pořadí';

  @override
  String get pathEditor_searchRepeaters => 'Hledat opakovače';

  @override
  String get pathEditor_advancedHex => 'Pokročilé: surová hex cesta';

  @override
  String get pathEditor_hexLabel => 'Hex prefixy';

  @override
  String get pathEditor_hexHelper => 'Dva hex znaky na skok, oddělené čárkami';

  @override
  String pathEditor_invalidTokens(String tokens) {
    return 'Neplatné: $tokens';
  }

  @override
  String get pathEditor_tooManyHops => 'Maximálně 64 skoků';

  @override
  String get pathEditor_usePath => 'Použít tuto cestu';

  @override
  String get pathEditor_removeHop => 'Odebrat skok';

  @override
  String get pathEditor_unknownHop => 'Neznámý opakovač';

  @override
  String get chat_pathSavedLocally =>
      'Uloženo lokálně. Pro synchronizaci se připojte.';

  @override
  String get chat_pathDeviceConfirmed => 'Zařízení potvrdilo.';

  @override
  String get chat_pathDeviceNotConfirmed => 'Zařízení zatím nepotvrdilo.';

  @override
  String get chat_type => 'Typ';

  @override
  String get chat_path => 'Cesta';

  @override
  String get chat_viewPathOnMap => 'Zobrazit cestu na mapě';

  @override
  String get chat_publicKey => 'Veřejný klíč';

  @override
  String get chat_compressOutgoingMessages => 'Komprimovat odchozí zprávy';

  @override
  String get chat_floodForced => 'Flood (vynuceno)';

  @override
  String get chat_directForced => 'Přímo (vynuceno)';

  @override
  String chat_hopsForced(int count) {
    return '$count skoků (vynuceno)';
  }

  @override
  String get chat_floodAuto => 'Flood (automaticky)';

  @override
  String get chat_direct => 'Přímo';

  @override
  String get chat_poiShared => 'Sdílen bod zájmu';

  @override
  String get contactShare_headerOutgoing => 'Sdíleli jste kontakt';

  @override
  String get contactShare_headerIncoming => 'Sdílel(a) kontakt';

  @override
  String get contactShare_add => 'Přidat kontakt';

  @override
  String get contactShare_adding => 'Přidávání kontaktu...';

  @override
  String get contactShare_saved => 'Uloženo';

  @override
  String get contactShare_addAgain => 'Přidat znovu';

  @override
  String get contactShare_isYou => 'To jste vy';

  @override
  String get contactShare_shareAction => 'Sdílet kontakt';

  @override
  String get contactShare_pickerTitle => 'Sdílet kontakt';

  @override
  String get contactShare_myContact => 'Můj kontakt';

  @override
  String get contactShare_searchHint => 'Hledat kontakty';

  @override
  String get contactShare_noContacts => 'Nenalezeny žádné kontakty';

  @override
  String contactShare_preview(String name) {
    return 'Sdílený kontakt: $name';
  }

  @override
  String contactShare_notification(String name) {
    return 'Sdílel(a) kontakt: $name';
  }

  @override
  String chat_unread(int count) {
    return 'Nepřečtené: $count';
  }

  @override
  String get chat_markAsUnread => 'Označit jako nepřečtené';

  @override
  String get chat_newMessages => 'Nové zprávy';

  @override
  String get chat_today => 'Dnes';

  @override
  String get chat_yesterday => 'Včera';

  @override
  String get chat_openLink => 'Otevřít odkaz?';

  @override
  String get chat_openLinkConfirmation =>
      'Chcete tento odkaz otevřít v prohlížeči?';

  @override
  String get chat_open => 'Otevřít';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Odkaz se nepodařilo otevřít: $url';
  }

  @override
  String get chat_invalidLink => 'Neplatný formát odkazu';

  @override
  String get map_title => 'Mapa uzlů';

  @override
  String get map_searchHint => 'Hledat název nebo ID uzlu';

  @override
  String get map_activity => 'Aktivita';

  @override
  String get map_online => 'Online';

  @override
  String get map_recent => 'Nedávné';

  @override
  String get map_stale => 'Neaktuální';

  @override
  String get map_visible => 'Viditelné';

  @override
  String get map_hidden => 'Skryté';

  @override
  String get map_centerOnNode => 'Vycentrovat na uzel';

  @override
  String get map_centerOnMe => 'Vycentrovat na mou polohu';

  @override
  String get map_details => 'Podrobnosti';

  @override
  String get map_noGps => 'Bez GPS';

  @override
  String get map_noResults => 'Žádné odpovídající uzly';

  @override
  String get map_lineOfSight => 'Přímá viditelnost';

  @override
  String get map_losScreenTitle => 'Přímá viditelnost';

  @override
  String get map_noNodesWithLocation => 'Žádné uzly s údaji o poloze';

  @override
  String get map_noNodesLocationHint =>
      'Žádné uzly s nedávnou polohou. Rozšiřte časový filtr nebo nastavte vlastní polohu v Nastavení.';

  @override
  String get map_nodesNeedGps =>
      'Uzly musí sdílet své GPS souřadnice,\naby se zobrazily na mapě';

  @override
  String map_nodesCount(int count) {
    return 'Uzly: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Špendlíky: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Opakovač';

  @override
  String get map_room => 'Místnost';

  @override
  String get map_sensor => 'Senzor';

  @override
  String get map_pinDm => 'Špendlík (DM)';

  @override
  String get map_pinPrivate => 'Špendlík (soukromý)';

  @override
  String get map_pinPublic => 'Špendlík (veřejný)';

  @override
  String get map_lastSeen => 'Naposledy viděn';

  @override
  String get map_from => 'Od';

  @override
  String get map_source => 'Zdroj';

  @override
  String get map_flags => 'Příznaky';

  @override
  String get map_type => 'Typ';

  @override
  String get map_path => 'Cesta';

  @override
  String get map_location => 'Poloha';

  @override
  String get map_estLocation => 'Odhad. poloha';

  @override
  String get map_publicKey => 'Veřejný klíč';

  @override
  String get map_publicKeyPrefixHint => 'např. ab12';

  @override
  String get map_shareMarkerHere => 'Sdílet zde značku';

  @override
  String get map_setAsMyLocation => 'Nastavit jako mou polohu';

  @override
  String get map_pinLabel => 'Popisek špendlíku';

  @override
  String get map_label => 'Popisek';

  @override
  String get map_labelUpdateHint =>
      'Použití stejného popisku jako dříve aktualizuje značku u příjemců s MeshCore Open.';

  @override
  String get map_pointOfInterest => 'Bod zájmu';

  @override
  String get map_sendToContact => 'Odeslat kontaktu';

  @override
  String get map_sendToChannel => 'Odeslat do kanálu';

  @override
  String get map_noChannelsAvailable => 'Žádné dostupné kanály';

  @override
  String get map_publicLocationShare => 'Veřejné sdílení polohy';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Chystáte se sdílet polohu v $channelLabel. Tento kanál je veřejný a kdokoli s PSK ji uvidí.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Pro sdílení značek se připojte k zařízení';

  @override
  String get map_filterNodes => 'Filtrovat uzly';

  @override
  String get map_nodeTypes => 'Typy uzlů';

  @override
  String get map_chatNodes => 'Chatovací uzly';

  @override
  String get map_repeaters => 'Opakovače';

  @override
  String get map_otherNodes => 'Ostatní uzly';

  @override
  String get map_showOnlineLinks => 'Zobrazit online spojení na mapě';

  @override
  String get map_showOverlaps => 'Překryvy klíčů opakovačů';

  @override
  String get map_keyPrefix => 'Prefix klíče';

  @override
  String get map_filterByKeyPrefix => 'Filtrovat podle prefixu klíče';

  @override
  String get map_publicKeyPrefix => 'Prefix veřejného klíče';

  @override
  String get map_markers => 'Značky';

  @override
  String get map_showSharedMarkers => 'Zobrazit sdílené značky';

  @override
  String get map_showGuessedLocations => 'Zobrazit odhadnuté polohy uzlů';

  @override
  String get map_clusterNodes => 'Seskupit blízké uzly';

  @override
  String get map_groupChip => 'Skupina';

  @override
  String get map_clusterNodesSubtitle =>
      'Při oddálení zobrazit blízké uzly jako jeden očíslovaný kruh';

  @override
  String get map_showDiscoveryContacts => 'Zobrazit objevené kontakty';

  @override
  String get map_guessedLocation => 'Odhadnutá poloha';

  @override
  String get map_lastSeenTime => 'Čas posledního spatření';

  @override
  String get map_sharedPin => 'Sdílený špendlík';

  @override
  String get map_sharedAt => 'Sdíleno';

  @override
  String get map_joinRoom => 'Připojit se k room';

  @override
  String get map_manageRepeater => 'Spravovat opakovač';

  @override
  String get map_manageServer => 'Spravovat server';

  @override
  String get map_tapToAdd => 'Klepnutím na uzly je přidáte do cesty.';

  @override
  String get map_runTrace => 'Spustit trasování cesty';

  @override
  String get map_runTraceWithReturnPath => 'Zpět po stejné cestě.';

  @override
  String get map_removeLast => 'Odebrat poslední';

  @override
  String get map_pathTraceCancelled => 'Trasování cesty zrušeno.';

  @override
  String get map_pathTraceAddMoreHint =>
      'Klepnutím na další uzly přidáte skoky, vyberte, jak se trasování vrací, a klepněte na Spustit trasování cesty.';

  @override
  String get map_pathTraceModeRoundTrip => 'Tam a zpět';

  @override
  String get map_pathTraceModeRoundTripHint =>
      'Trasování jde přes tyto skoky a vrací se stejnou cestou.';

  @override
  String get map_pathTraceModeAsEntered => 'Dle zadání';

  @override
  String get map_pathTraceModeAsEnteredHint =>
      'Trasování následuje přesně tyto skoky. Skoky zpět k sobě si přidejte sami.';

  @override
  String get map_pathTraceViewLast => 'Zobrazit poslední výsledek';

  @override
  String get manualTrace_menuItem => 'Trasování cesty podle hashů';

  @override
  String get manualTrace_inputLabel => 'Hashe opakovačů';

  @override
  String manualTrace_helper(String example) {
    return 'Příklad: $example. Oddělte čárkami nebo mezerami.';
  }

  @override
  String manualTrace_previewTitle(int count) {
    return 'Skoky ($count)';
  }

  @override
  String get manualTrace_unknownNode => 'Neznámý uzel';

  @override
  String get manualTrace_enterHashes => 'Zadejte hashe';

  @override
  String get manualTrace_run => 'Spustit trasování cesty';

  @override
  String get manualTrace_notConnected =>
      'Pro spuštění trasování se připojte k rádiu';

  @override
  String get manualTrace_errorInvalidHex =>
      'Povoleny jsou pouze hexadecimální znaky (0-9, A-F)';

  @override
  String get manualTrace_errorOddLength =>
      'Každý hash potřebuje sudý počet hexadecimálních znaků odpovídající velikosti skoku';

  @override
  String get manualTrace_errorMixedWidths =>
      'Všechny hashe musí mít stejnou délku';

  @override
  String get manualTrace_errorUnsupportedWidth =>
      'Hashe musí mít 1, 2 nebo 3 bajty (2, 4 nebo 6 hexadecimálních znaků)';

  @override
  String manualTrace_errorTooManyHops(int max) {
    return 'Cesta je příliš dlouhá (maximum $max bajtů)';
  }

  @override
  String get manualTrace_errorTraceTooLong =>
      'Příliš mnoho skoků pro trasování v jednom požadavku. Odeberte některé skoky nebo zvolte „Dle zadání“.';

  @override
  String get mapCache_title => 'Offline mezipaměť map';

  @override
  String get mapCache_selectAreaFirst => 'Nejprve vyberte oblast k uložení';

  @override
  String get mapCache_noTilesToDownload =>
      'Pro tuto oblast nejsou k stažení žádné dlaždice';

  @override
  String get mapCache_downloadTilesTitle => 'Stáhnout dlaždice';

  @override
  String mapCache_downloadTilesPrompt(int count) {
    return 'Stáhnout $count dlaždic pro offline použití?';
  }

  @override
  String get mapCache_downloadAction => 'Stáhnout';

  @override
  String mapCache_cachedTiles(int count) {
    return 'Uloženo $count dlaždic';
  }

  @override
  String mapCache_cachedTilesWithFailed(int downloaded, int failed) {
    return 'Uloženo $downloaded dlaždic ($failed selhalo)';
  }

  @override
  String get mapCache_clearOfflineCacheTitle => 'Vymazat offline mezipaměť';

  @override
  String get mapCache_clearOfflineCachePrompt =>
      'Odstranit všechny uložené mapové dlaždice?';

  @override
  String get mapCache_offlineCacheCleared => 'Offline mezipaměť vymazána';

  @override
  String get mapCache_noAreaSelected => 'Není vybrána žádná oblast';

  @override
  String get mapCache_cacheArea => 'Oblast k uložení';

  @override
  String get mapCache_useCurrentView => 'Použít aktuální zobrazení';

  @override
  String get mapCache_zoomRange => 'Rozsah přiblížení';

  @override
  String mapCache_estimatedTiles(int count) {
    return 'Odhadovaný počet dlaždic: $count';
  }

  @override
  String mapCache_downloadedTiles(int completed, int total) {
    return 'Staženo $completed / $total';
  }

  @override
  String get mapCache_downloadTilesButton => 'Stáhnout dlaždice';

  @override
  String get mapCache_clearCacheButton => 'Vymazat mezipaměť';

  @override
  String mapCache_failedDownloads(int count) {
    return 'Neúspěšná stažení: $count';
  }

  @override
  String get mapCache_cachedTilesLabel => 'Uložené dlaždice';

  @override
  String get mapCache_cachedTileSummaryLabel => 'Přehled uložených dlaždic';

  @override
  String mapCache_bulkDownloadDisabledForSource(String source) {
    return 'Hromadné offline stahování je pro $source zakázáno.';
  }

  @override
  String mapCache_bulkDownloadDisabledInConfig(String source) {
    return 'Hromadné offline stahování je pro $source v této konfiguraci aplikace zakázáno.';
  }

  @override
  String mapCache_summarySource(String source) {
    return 'Zdroj: $source';
  }

  @override
  String mapCache_summaryCachedTilesForSource(int count) {
    return 'Uložené dlaždice pro zdroj: $count';
  }

  @override
  String mapCache_summaryCachedInSelection(int count) {
    return 'Uloženo ve vybrané oblasti/přiblížení: $count';
  }

  @override
  String mapCache_summaryApproxCacheSize(String size) {
    return 'Přibližná velikost mezipaměti: $size';
  }

  @override
  String mapCache_boundsLabel(
    String north,
    String south,
    String east,
    String west,
  ) {
    return 'S $north, J $south, V $east, Z $west';
  }

  @override
  String get time_justNow => 'Právě teď';

  @override
  String time_minutesAgo(int minutes) {
    return 'před $minutes min';
  }

  @override
  String time_hoursAgo(int hours) {
    return 'před $hours h';
  }

  @override
  String time_daysAgo(int days) {
    return 'před $days d';
  }

  @override
  String get time_hour => 'hodina';

  @override
  String get time_hours => 'hodin';

  @override
  String get time_day => 'den';

  @override
  String get time_days => 'dní';

  @override
  String get time_week => 'týden';

  @override
  String get time_weeks => 'týdnů';

  @override
  String get time_month => 'měsíc';

  @override
  String get time_months => 'měsíců';

  @override
  String get time_minutes => 'minut';

  @override
  String get time_allTime => 'Vše';

  @override
  String get dialog_disconnect => 'Odpojit';

  @override
  String get dialog_disconnectConfirm =>
      'Opravdu se chcete od tohoto zařízení odpojit?';

  @override
  String get login_repeaterLogin => 'Přihlášení k opakovači';

  @override
  String get login_roomLogin => 'Přihlášení k room serveru';

  @override
  String get login_password => 'Heslo';

  @override
  String get login_enterPassword => 'Zadejte heslo';

  @override
  String get login_showPassword => 'Zobrazit heslo';

  @override
  String get login_hidePassword => 'Skrýt heslo';

  @override
  String get login_savePassword => 'Uložit heslo';

  @override
  String get login_savePasswordSubtitle =>
      'Heslo bude bezpečně uloženo v tomto zařízení';

  @override
  String get login_repeaterDescription =>
      'Heslo správce odemkne nastavení a CLI. Heslo hosta (nebo prázdné) zobrazí pouze stav.';

  @override
  String get login_roomDescription =>
      'Zadejte heslo k room pro přístup hosta nebo správce.';

  @override
  String get login_advanced => 'Pokročilé';

  @override
  String get login_routing => 'Směrování';

  @override
  String get login_routingMode => 'Režim směrování';

  @override
  String get login_autoUseSavedPath => 'Auto (použít uloženou cestu)';

  @override
  String get login_forceFloodMode => 'Vynutit režim flood';

  @override
  String get login_managePaths => 'Spravovat cesty';

  @override
  String get login_login => 'Přihlásit';

  @override
  String login_attempt(int current, int max) {
    return 'Pokus $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Přihlášení selhalo: $error';
  }

  @override
  String get login_failedMessage =>
      'Přihlášení selhalo. Heslo je buď nesprávné, nebo je opakovač nedostupný.';

  @override
  String get common_reload => 'Znovu načíst';

  @override
  String get common_clear => 'Vymazat';

  @override
  String get common_clearSearch => 'Vymazat hledání';

  @override
  String get path_currentPathLabel => 'Aktuální cesta';

  @override
  String get path_noRepeatersFound =>
      'Nenalezeny žádné opakovače ani room servery.';

  @override
  String get repeater_management => 'Správa opakovače';

  @override
  String get room_management => 'Správa room serveru';

  @override
  String get repeater_guest => 'Informace o opakovači';

  @override
  String get room_guest => 'Informace o room serveru';

  @override
  String get repeater_managementTools => 'Nástroje správy';

  @override
  String get repeater_guestTools => 'Nástroje pro hosta';

  @override
  String get repeater_roleAdmin => 'SPRÁVCE';

  @override
  String get repeater_roleGuest => 'HOST';

  @override
  String get repeater_status => 'Stav';

  @override
  String get repeater_statusSubtitle =>
      'Zobrazit stav opakovače, statistiky a sousedy';

  @override
  String get repeater_telemetry => 'Telemetrie';

  @override
  String get repeater_telemetrySubtitle =>
      'Zobrazit telemetrii senzorů a systémové statistiky';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Odesílat příkazy opakovači';

  @override
  String get repeater_neighbors => 'Sousedé';

  @override
  String get repeater_neighborsSubtitle => 'Zobrazit sousedy na nulový skok.';

  @override
  String get repeater_settings => 'Nastavení';

  @override
  String get repeater_settingsSubtitle => 'Konfigurace parametrů opakovače';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Synchronizace hodin po přihlášení';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automaticky odeslat „clock sync“ po úspěšném přihlášení';

  @override
  String get repeater_statusTitle => 'Stav opakovače';

  @override
  String get repeater_routingMode => 'Režim směrování';

  @override
  String get repeater_refresh => 'Obnovit';

  @override
  String get repeater_statusRequestTimeout => 'Požadavek na stav vypršel.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Chyba při načítání stavu: $error';
  }

  @override
  String get repeater_systemInformation => 'Informace o systému';

  @override
  String get repeater_battery => 'Baterie';

  @override
  String get repeater_clockAtLogin => 'Hodiny (při přihlášení)';

  @override
  String get repeater_uptime => 'Doba provozu';

  @override
  String get repeater_queueLength => 'Délka fronty';

  @override
  String get repeater_debugFlags => 'Ladicí příznaky';

  @override
  String get repeater_radioStatistics => 'Statistiky rádia';

  @override
  String get repeater_lastRssi => 'Poslední RSSI';

  @override
  String get repeater_lastSnr => 'Poslední SNR';

  @override
  String get repeater_noiseFloor => 'Úroveň šumu';

  @override
  String get repeater_txAirtime => 'Vysílací čas TX';

  @override
  String get repeater_rxAirtime => 'Vysílací čas RX';

  @override
  String get repeater_chanUtil => 'Využití kanálu';

  @override
  String get repeater_packetStatistics => 'Statistiky paketů';

  @override
  String get repeater_sent => 'Odesláno';

  @override
  String get repeater_received => 'Přijato';

  @override
  String get repeater_duplicates => 'Duplicity';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dní $hours h $minutes m $seconds s';
  }

  @override
  String repeater_hoursMinsSecs(int hours, int minutes, int seconds) {
    return '$hours h $minutes m $seconds s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Celkem: $total, Flood: $flood, Přímé: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Celkem: $total, Flood: $flood, Přímé: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Přímé: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Celkem: $total';
  }

  @override
  String get repeater_settingsTitle => 'Nastavení opakovače';

  @override
  String get repeater_basicSettings => 'Základní nastavení';

  @override
  String get repeater_repeaterName => 'Název opakovače';

  @override
  String get repeater_repeaterNameHelper =>
      'Zobrazovaný název tohoto opakovače';

  @override
  String get repeater_adminPassword => 'Heslo správce';

  @override
  String get repeater_adminPasswordHelper => 'Heslo s plným přístupem';

  @override
  String get repeater_guestPassword => 'Heslo hosta';

  @override
  String get repeater_guestPasswordHelper =>
      'Heslo s přístupem pouze pro čtení';

  @override
  String get repeater_radioSettings => 'Nastavení rádia';

  @override
  String get repeater_frequencyMhz => 'Frekvence (MHz)';

  @override
  String get repeater_frequencyHelper => '300–2500 MHz';

  @override
  String get repeater_txPower => 'Výkon TX';

  @override
  String get repeater_txPowerHelper => '1–30 dBm';

  @override
  String get repeater_bandwidth => 'Šířka pásma';

  @override
  String get repeater_spreadingFactor => 'Rozptylový faktor';

  @override
  String get repeater_codingRate => 'Kódovací poměr';

  @override
  String get repeater_locationSettings => 'Nastavení polohy';

  @override
  String get repeater_latitude => 'Zeměpisná šířka';

  @override
  String get repeater_latitudeHelper => 'Desetinné stupně (např. 37.7749)';

  @override
  String get repeater_longitude => 'Zeměpisná délka';

  @override
  String get repeater_longitudeHelper => 'Desetinné stupně (např. -122.4194)';

  @override
  String get repeater_features => 'Funkce';

  @override
  String get repeater_packetForwarding => 'Předávání paketů';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Povolit opakovači předávat pakety';

  @override
  String get repeater_guestAccess => 'Přístup hosta';

  @override
  String get repeater_guestAccessSubtitle =>
      'Povolit přístup hosta pouze pro čtení';

  @override
  String get repeater_privacyMode => 'Režim soukromí';

  @override
  String get repeater_privacyModeSubtitle => 'Skrýt název/polohu v inzerátech';

  @override
  String get repeater_advertisementSettings => 'Nastavení inzerátů';

  @override
  String get repeater_localAdvertInterval => 'Interval lokálního inzerátu';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minut';
  }

  @override
  String get repeater_floodAdvertInterval => 'Interval flood inzerátu';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours hodin';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Interval šifrovaného inzerátu';

  @override
  String get repeater_dangerZone => 'Nebezpečná zóna';

  @override
  String get repeater_rebootRepeater => 'Restartovat opakovač';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Restartovat zařízení opakovače';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Opravdu chcete tento opakovač restartovat?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Znovu vygenerovat identitní klíč';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Vygenerovat nový pár veřejného a soukromého klíče';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Tím se pro opakovač vygeneruje nová identita. Pokračovat?';

  @override
  String get repeater_eraseFileSystem => 'Vymazat souborový systém';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Naformátovat souborový systém opakovače';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'VAROVÁNÍ: Tím se smažou všechna data v opakovači. Tuto akci nelze vrátit zpět!';

  @override
  String get repeater_eraseSerialOnly =>
      'Vymazání je dostupné pouze přes sériovou konzoli.';

  @override
  String repeater_commandSent(String command) {
    return 'Příkaz odeslán: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Chyba při odesílání příkazu: $error';
  }

  @override
  String get repeater_confirm => 'Potvrdit';

  @override
  String get repeater_settingsSaved => 'Nastavení bylo úspěšně uloženo';

  @override
  String get repeater_rxGain => 'Zesílený zisk RX';

  @override
  String get repeater_rxGainHelper =>
      'Vyšší citlivost, vyšší odběr proudu (pouze SX1262/SX1268)';

  @override
  String get repeater_multiAcks => 'Vícenásobné ACK';

  @override
  String get repeater_multiAcksSubtitle =>
      'Potvrzovat zprávy po více cestách pro lepší doručení';

  @override
  String get repeater_networkHealth => 'Stav sítě';

  @override
  String get repeater_loopDetect => 'Detekce smyček';

  @override
  String get repeater_loopDetectHelper =>
      'Zahazovat flood pakety, které vypadají jako směrovací smyčky';

  @override
  String get repeater_loopDetectOff => 'Vypnuto';

  @override
  String get repeater_loopDetectMinimal => 'Minimální';

  @override
  String get repeater_loopDetectModerate => 'Střední';

  @override
  String get repeater_loopDetectStrict => 'Přísná';

  @override
  String get repeater_dutyCycle => 'Duty cycle';

  @override
  String get repeater_dutyCycleHelper => 'Maximální procento vysílacího času';

  @override
  String repeater_dutyCyclePercent(int percent) {
    return '$percent%';
  }

  @override
  String get repeater_ownerInfo => 'Informace o provozovateli';

  @override
  String get repeater_ownerInfoHelper => 'Veřejná metadata tohoto opakovače';

  @override
  String get repeater_floodMax => 'Maximum skoků flood';

  @override
  String get repeater_floodMaxHelper =>
      'Maximální počet skoků, které flood paket může urazit (0–64)';

  @override
  String get repeater_advancedSettings => 'Pokročilé';

  @override
  String get repeater_advancedSettingsSubtitle =>
      'Jemné ladění pro zkušené provozovatele';

  @override
  String get repeater_pathHashMode => 'Velikost ID uzlu v cestách';

  @override
  String get repeater_pathHashModeHelper =>
      'Velikost ID tohoto opakovače v cestách jím odesílaných advertů: 1 bajt (256 ID, až 64 skoků), 2 bajty (65 tis. ID, až 32 skoků), 3 bajty (16 mil. ID, až 21 skoků). Nemá vliv na přeposílání; opakovače v1.14+ přeposílají všechny velikosti, ale starší firmware zahazuje pakety s 2- nebo 3bajtovými ID.';

  @override
  String get repeater_keySettings => 'Změnit identitní klíče';

  @override
  String get repeater_keySettingsSubtitle =>
      'Změnit veřejný/soukromý pár klíčů';

  @override
  String get repeater_prvKey => 'Soukromý klíč';

  @override
  String get repeater_prvKeyHelper =>
      'Nový soukromý klíč opakovače, hex řetězec o 128 znacích.';

  @override
  String get repeater_generatePrvKey => 'Vygenerovat náhodný pár klíčů';

  @override
  String get repeater_stopGeneratingPrvKey => 'Přerušit hledání páru klíčů';

  @override
  String get repeater_pubKey => 'Veřejný klíč';

  @override
  String get repeater_pubKeyHelper =>
      'Toto je veřejný klíč patřící k vygenerovanému soukromému klíči. Nelze jej nastavit přímo.';

  @override
  String get repeater_pubKeyPrefix => 'Požadovaná předpona';

  @override
  String repeater_pubKeyPrefixHelper(int tries) {
    return 'Najít veřejný klíč začínající těmito hex číslicemi. Očekávaný počet pokusů: $tries.';
  }

  @override
  String get repeater_txDelay => 'Zpoždění TX pro flood';

  @override
  String get repeater_txDelayHelper =>
      'Rozestup opakovaného vysílání flood provozu jako násobek doby vysílání paketu (0–2, výchozí 0,5). Vyšší = méně kolizí, ale pomalejší doručení.';

  @override
  String get repeater_directTxDelay => 'Zpoždění TX pro direct';

  @override
  String get repeater_directTxDelayHelper =>
      'Rozestup opakovaného vysílání direct (ne flood) provozu jako násobek doby vysílání paketu (0–2, výchozí 0,3).';

  @override
  String get repeater_intThresh => 'Práh rušení';

  @override
  String get repeater_intThreshHelper =>
      'Práh předaný kalibraci šumového pozadí rádia, aby odmítalo rušení nad touto úrovní. 0 = vypnuto — zvyšujte jen při chybách RX v zarušeném pásmu.';

  @override
  String get repeater_agcResetInterval => 'Interval resetu AGC';

  @override
  String get repeater_agcResetIntervalHelper =>
      'Jak často resetovat automatické řízení zisku rádia, aby se zotavilo ze zaseknutého stavu zisku. V sekundách, zaokrouhleno dolů na násobek 4. 0 vypne pravidelné resety.';

  @override
  String get repeater_actionsTitle => 'Akce';

  @override
  String get repeater_sendAdvert => 'Odeslat flood advert';

  @override
  String get repeater_sendAdvertSubtitle => 'Rozeslat flood advert po síti';

  @override
  String get repeater_sendAdvertZeroHop => 'Odeslat zero-hop advert';

  @override
  String get repeater_sendAdvertZeroHopSubtitle =>
      'Rozeslat advert na jeden skok (bez přeposílání)';

  @override
  String get repeater_clockSync => 'Synchronizovat hodiny';

  @override
  String get repeater_clockSyncSubtitle =>
      'Odeslat čas z telefonu do opakovače';

  @override
  String repeater_actionSucceeded(String action) {
    return '$action proběhlo úspěšně';
  }

  @override
  String repeater_actionFailed(String action, String error) {
    return '$action selhalo: $error';
  }

  @override
  String get repeater_settingsSavedRebootNeeded =>
      'Nastavení uloženo — pro použití restartujte opakovač';

  @override
  String repeater_settingsPartialFailure(String failures) {
    return 'Některá nastavení selhala: $failures';
  }

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Chyba při ukládání nastavení: $error';
  }

  @override
  String get repeater_refreshRadioSettings => 'Obnovit nastavení rádia';

  @override
  String get repeater_refreshPrivacyMode => 'Obnovit režim soukromí';

  @override
  String get repeater_refreshAll => 'Obnovit vše';

  @override
  String get repeater_settingsNotLoaded =>
      'Nastavení z tohoto opakovače zatím nebyla načtena.';

  @override
  String get repeater_settingsLoadIncomplete =>
      'Některá nastavení se nepodařilo načíst. Zkuste to znovu tlačítky obnovení.';

  @override
  String repeater_refreshed(String label) {
    return '$label obnoveno';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Chyba při obnovování: $label';
  }

  @override
  String get repeater_cliTitle => 'CLI opakovače';

  @override
  String get repeater_debugNextCommand => 'Ladit další příkaz';

  @override
  String get repeater_commandHelp => 'Nápověda k příkazům';

  @override
  String get repeater_clearHistory => 'Vymazat historii';

  @override
  String get repeater_noCommandsSent => 'Zatím nebyly odeslány žádné příkazy';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Zadejte příkaz níže nebo použijte rychlé příkazy';

  @override
  String get repeater_enterCommandHint => 'Zadejte příkaz...';

  @override
  String get repeater_previousCommand => 'Předchozí příkaz';

  @override
  String get repeater_nextCommand => 'Další příkaz';

  @override
  String get repeater_enterCommandFirst => 'Nejprve zadejte příkaz';

  @override
  String get repeater_cliCommandFrameTitle => 'Rámec příkazu CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Zjistit název';

  @override
  String get repeater_cliQuickGetRadio => 'Zjistit rádio';

  @override
  String get repeater_cliQuickGetTx => 'Zjistit TX';

  @override
  String get repeater_cliQuickNeighbors => 'Sousedé';

  @override
  String get repeater_cliQuickVersion => 'Verze';

  @override
  String get repeater_cliQuickAdvertise => 'Advert';

  @override
  String get repeater_cliQuickClock => 'Hodiny';

  @override
  String get repeater_cliQuickClockSync => 'Synchronizace hodin';

  @override
  String get repeater_cliQuickDiscovery => 'Vyhledat sousedy';

  @override
  String get repeater_cliHelpAdvert => 'Odešle paket advert';

  @override
  String get repeater_cliHelpReboot =>
      'Restartuje zařízení. (pozor, pravděpodobně dostanete „Timeout“, což je normální)';

  @override
  String get repeater_cliHelpClock =>
      'Zobrazí aktuální čas podle hodin zařízení.';

  @override
  String get repeater_cliHelpPassword =>
      'Nastaví nové administrátorské heslo zařízení.';

  @override
  String get repeater_cliHelpVersion =>
      'Zobrazí verzi zařízení a datum sestavení firmwaru.';

  @override
  String get repeater_cliHelpClearStats => 'Vynuluje různé čítače statistik.';

  @override
  String get repeater_cliHelpSetAf => 'Nastaví air-time-factor.';

  @override
  String get repeater_cliHelpSetTx =>
      'Nastaví vysílací výkon LoRa v dBm. (pro použití restartujte)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Zapne nebo vypne roli opakovače pro tento uzel.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Room server) Pokud je „on“, je povoleno přihlášení s prázdným heslem, ale nelze přispívat do místnosti. (pouze čtení)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Nastaví maximální počet skoků příchozího flood paketu (pokud je >= maximum, paket se nepřeposílá)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Nastaví práh rušení (v DB). Výchozí je 14. Hodnota 0 vypne detekci rušení kanálu.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Nastaví interval resetu automatického řízení zisku (AGC). Hodnota 0 jej vypne.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Zapne nebo vypne funkci „dvojitých ACK“.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Nastaví interval časovače v minutách pro odesílání lokálního (zero-hop) advert paketu. Hodnota 0 jej vypne.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Nastaví interval časovače v hodinách pro odesílání flood advert paketu. Hodnota 0 jej vypne.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Nastaví/aktualizuje heslo hosta. (u opakovačů mohou hosté odeslat požadavek „Get Stats“)';

  @override
  String get repeater_cliHelpSetName => 'Nastaví název v advertu.';

  @override
  String get repeater_cliHelpSetLat =>
      'Nastaví zeměpisnou šířku v advertu. (desetinné stupně)';

  @override
  String get repeater_cliHelpSetLon =>
      'Nastaví zeměpisnou délku v advertu. (desetinné stupně)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Nastaví zcela nové parametry rádia a uloží je do předvoleb. K použití vyžaduje příkaz „reboot“.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Nastaví (experimentální) základ (pro efekt musí být > 1) pro mírné zpoždění přijatých paketů podle síly signálu/skóre. Hodnota 0 jej vypne.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Nastaví koeficient, který se násobí dobou vysílání flood paketu a náhodným slotovým systémem, aby se zpozdilo jeho přeposlání. (ke snížení pravděpodobnosti kolizí)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Totéž co txdelay, ale pro náhodné zpoždění přeposílání paketů v režimu direct.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Zapnout/vypnout bridge.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Nastaví zpoždění před opakovaným vysíláním paketů.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Vyberte, zda bridge bude opakovat přijaté, nebo vysílané pakety.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Nastaví přenosovou rychlost sériové linky pro bridge rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Nastaví tajný klíč bridge pro bridge espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Nastaví vlastní koeficient pro úpravu hlášeného napětí baterie (podporováno jen na vybraných deskách).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Nastaví dočasné parametry rádia na zadaný počet minut, poté se vrátí k původním. (NEukládá se do předvoleb).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Upravuje ACL. Pokud jsou „permissions“ nula, odebere odpovídající záznam (podle předpony pubkey). Pokud je pubkey-hex v plné délce a není v ACL, přidá nový záznam. Záznam aktualizuje podle shodné předpony pubkey. Bity oprávnění se liší podle role firmwaru, ale nejnižší 2 bity jsou: 0 (Host), 1 (Pouze čtení), 2 (Čtení a zápis), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Zjistí typ bridge: none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Spustí logování paketů do souborového systému.';

  @override
  String get repeater_cliHelpLogStop =>
      'Zastaví logování paketů do souborového systému.';

  @override
  String get repeater_cliHelpLogErase =>
      'Smaže logy paketů ze souborového systému.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Zobrazí seznam dalších uzlů opakovačů slyšených přes zero-hop adverty. Každý řádek je id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Odebere ze seznamu sousedů první odpovídající záznam (podle předpony pubkey (hex)).';

  @override
  String get repeater_cliHelpRegion =>
      '(pouze sériově) Vypíše všechny definované regiony a aktuální oprávnění flood.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'POZNÁMKA: jde o speciální vícepříkazové volání. Každý další příkaz je název regionu (odsazený mezerami pro vyjádření nadřazené hierarchie, minimálně jednou mezerou). Ukončí se odesláním prázdného řádku/příkazu.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Vyhledá region podle předpony názvu (nebo „*“ pro globální rozsah). Odpoví „-> region-name (parent-name) \'F\'“';

  @override
  String get repeater_cliHelpRegionPut =>
      'Přidá nebo aktualizuje definici regionu se zadaným názvem.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Odebere definici regionu se zadaným názvem. (musí přesně sedět a nesmí mít podřízené regiony)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Nastaví oprávnění \'F\'lood pro zadaný region. (\'*\' pro globální/legacy rozsah)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Odebere oprávnění \'F\'lood pro zadaný region. (POZOR: v této fázi se NEDOPORUČUJE používat u globálního/legacy rozsahu!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odpoví aktuálním „home“ regionem. (Zatím se nikde nepoužívá, vyhrazeno pro budoucnost)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Nastaví „home“ region.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Uloží seznam/mapu regionů do úložiště.';

  @override
  String get repeater_cliHelpGps =>
      'Vrátí stav GPS. Když je GPS vypnuté, odpoví jen off, když je zapnuté, odpoví on, stav, fix, počet satelitů';

  @override
  String get repeater_cliHelpGpsOnOff => 'Přepne napájení GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronizuje čas uzlu s hodinami GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Nastaví polohu uzlu na souřadnice GPS a uloží předvolby.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Vrátí konfiguraci polohy v advertu uzlu:\n- none: nezahrnovat polohu do advertů\n- share: sdílet polohu GPS (ze SensorManager)\n- prefs: inzerovat polohu uloženou v předvolbách';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Nastaví konfiguraci polohy v advertu.';

  @override
  String get repeater_commandsListTitle => 'Seznam příkazů';

  @override
  String get repeater_commandsListNote =>
      'POZNÁMKA: k různým příkazům „set ...“ existuje také příkaz „get ...“.';

  @override
  String get repeater_frequencyRangeHelper => '150–2500 MHz';

  @override
  String get repeater_frequencyInvalid => 'Neplatná frekvence (150–2500 MHz)';

  @override
  String get repeater_txPowerRangeHelper => '−9 až 30 dBm';

  @override
  String get repeater_recvErrors => 'Chyby příjmu';

  @override
  String get room_postsStored => 'Příspěvky';

  @override
  String get room_postsPushed => 'Odeslané příspěvky';

  @override
  String get repeater_cliRegionLoadActive =>
      'Režim načtení regionů: odesílejte jeden název regionu na řádek, odsazený mezerami pod nadřazeným regionem (pro povolení flood přidejte za název F). Řádky nedostanou odpověď. Dokončete odesláním prázdného řádku, poté výsledek uložte příkazem „region save“.';

  @override
  String get repeater_cliRegionLoadHint =>
      'Řádek regionu, nebo prázdný pro dokončení';

  @override
  String get repeater_cliRegionLoadEnd => '(konec načítání regionů)';

  @override
  String get repeater_cliHelpRegionDef =>
      'Definuje řetězec regionů jedním příkazem: každý název se přidá pod předchozí; „name,parent“ přidá název a pokračuje pod zadaným nadřazeným. Odpoví seznamem regionů.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Nastaví maximální počet skoků pro přeposílání flood paketů bez regionového rozsahu (0–64).';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Nastaví maximální počet skoků pro přeposílání flood advertů (0–64).';

  @override
  String get repeater_cliHelpGetFloodMaxUnscoped =>
      'Zobrazí maximální počet skoků pro flood pakety bez rozsahu.';

  @override
  String get repeater_cliHelpGetFloodMaxAdvert =>
      'Zobrazí maximální počet skoků pro flood adverty.';

  @override
  String get repeater_cliHelpSetRadioFemRxGain =>
      'Přepne zisk RX (LNA) front-end modulu LoRa. Desky bez něj odpoví „Error: unsupported“.';

  @override
  String get repeater_cliHelpSetRadioFemTxGain =>
      'Přepne zisk TX (PA) front-end modulu LoRa. Desky bez něj odpoví „Error: unsupported“.';

  @override
  String get repeater_cliHelpGetRadioFemRxGain =>
      'Zobrazí, zda je zapnut zisk RX front-end modulu LoRa.';

  @override
  String get repeater_cliHelpGetRadioFemTxGain =>
      'Zobrazí, zda je zapnut zisk TX front-end modulu LoRa.';

  @override
  String get repeater_bridgeNote =>
      'K dispozici pouze ve firmwaru sestaveném s bridge (RS232 nebo ESP-NOW).';

  @override
  String get repeater_general => 'Obecné';

  @override
  String get repeater_settingsCategory => 'Nastavení';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Logování';

  @override
  String get repeater_neighborsRepeaterOnly => 'Sousedé (pouze opakovač)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Správa regionů (pouze opakovač)';

  @override
  String get repeater_regionNote =>
      'Příkazy region byly zavedeny pro správu definic a oprávnění regionů.';

  @override
  String get repeater_gpsManagement => 'Správa GPS';

  @override
  String get repeater_gpsNote =>
      'Příkaz gps byl zaveden pro správu témat souvisejících s polohou.';

  @override
  String get repeater_getCategory => 'Zjistit hodnoty';

  @override
  String get repeater_powerMgmt => 'Správa napájení';

  @override
  String get repeater_sensors => 'Senzory';

  @override
  String get repeater_cliHelpPowerOff =>
      'Vypne zařízení. (neočekává se odpověď)';

  @override
  String get repeater_cliHelpClkReboot =>
      'Resetuje hodiny na známou epochu a restartuje zařízení.';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Odešle zero-hop advert (pouze nejbližším sousedům).';

  @override
  String get repeater_cliHelpStartOta =>
      'Spustí bezdrátovou aktualizaci firmwaru (OTA) na podporovaných deskách.';

  @override
  String get repeater_cliHelpTime =>
      'Nastaví hodiny zařízení na zadané sekundy Unix epochy. Hodiny nelze posunout zpět.';

  @override
  String get repeater_cliHelpBoard =>
      'Zobrazí výrobce desky / hardwarový identifikátor.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Odešle požadavek na vyhledání uzlů okolním sousedům. (pouze opakovač)';

  @override
  String get repeater_cliHelpPowersaving =>
      'Zobrazí, zda je režim úspory energie zapnut nebo vypnut.';

  @override
  String get repeater_cliHelpPowersavingOnOff =>
      'Zapne nebo vypne režim úspory energie (kde je podporován).';

  @override
  String get repeater_cliHelpErase =>
      '(pouze sériově) Zformátuje souborový systém zařízení. Vymaže všechna nastavení a kontakty.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Nastaví maximální povolený vysílací duty cycle v procentech (1–100). Interně upraví airtime factor.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'Nahradí soukromý klíč identity zařízení. K použití je nutný restart. Vygeneruje nový veřejný klíč.';

  @override
  String get repeater_cliHelpSetRadioRxGain =>
      '(pouze SX126x) Přepne zesílený zisk RX pro lepší citlivost za cenu vyššího odběru proudu.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Nastaví řetězec s kontaktními údaji vlastníka obsažený v advertech. Pro nové řádky použijte „|“.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Nastaví velikost ID uzlu používanou v advertech tohoto opakovače: 0 = 1 bajt (až 64 skoků), 1 = 2 bajty (až 32 skoků), 2 = 3 bajty (až 21 skoků). 3 je vyhrazeno. Neovlivňuje, které velikosti se přeposílají. Vyžaduje firmware v1.14+.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Nastaví citlivost detekce směrovacích smyček: off, minimal, moderate nebo strict.';

  @override
  String get repeater_cliHelpSetFreq =>
      '(pouze sériově) Rychle nastaví pouze frekvenci. Nutný restart. Pro kompletní parametry rádia raději použijte „set radio“.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      '(pouze bridge ESPNow) Nastaví kanál WiFi (1–14) používaný bridge.';

  @override
  String get repeater_cliHelpGetName => 'Zobrazí nastavený název uzlu.';

  @override
  String get repeater_cliHelpGetRole =>
      'Zobrazí roli firmwaru (Repeater, Room Server atd.).';

  @override
  String get repeater_cliHelpGetPublicKey => 'Zobrazí veřejný klíč zařízení.';

  @override
  String get repeater_cliHelpGetPrvKey =>
      '(pouze sériově) Zobrazí soukromý klíč zařízení. Považujte jej za tajný.';

  @override
  String get repeater_cliHelpGetRepeat =>
      'Zobrazí, zda je přeposílání paketů (role opakovače) zapnuto nebo vypnuto.';

  @override
  String get repeater_cliHelpGetTx => 'Zobrazí aktuální výkon TX v dBm.';

  @override
  String get repeater_cliHelpGetFreq =>
      'Zobrazí nastavenou frekvenci rádia v MHz.';

  @override
  String get repeater_cliHelpGetRadio =>
      'Zobrazí kompletní parametry rádia: frekvence, šířka pásma, spreading factor, coding rate.';

  @override
  String get repeater_cliHelpGetRadioRxGain =>
      '(pouze SX126x) Zobrazí stav zesíleného zisku RX.';

  @override
  String get repeater_cliHelpGetAf => 'Zobrazí aktuální airtime factor.';

  @override
  String get repeater_cliHelpGetDutyCycle =>
      'Zobrazí aktuální povolený duty cycle v procentech.';

  @override
  String get repeater_cliHelpGetIntThresh => 'Zobrazí práh rušení kanálu v dB.';

  @override
  String get repeater_cliHelpGetAgcResetInterval =>
      'Zobrazí interval resetu AGC v sekundách.';

  @override
  String get repeater_cliHelpGetMultiAcks =>
      'Zobrazí, zda je režim dvojitých ACK zapnut (1) nebo vypnut (0).';

  @override
  String get repeater_cliHelpGetAllowReadOnly =>
      'Zobrazí, zda je povolen přístup hosta pouze pro čtení.';

  @override
  String get repeater_cliHelpGetAdvertInterval =>
      'Zobrazí interval lokálního advertu v minutách.';

  @override
  String get repeater_cliHelpGetFloodAdvertInterval =>
      'Zobrazí interval flood advertu v hodinách.';

  @override
  String get repeater_cliHelpGetGuestPassword =>
      'Zobrazí nastavené heslo hosta.';

  @override
  String get repeater_cliHelpGetLat => 'Zobrazí nastavenou zeměpisnou šířku.';

  @override
  String get repeater_cliHelpGetLon => 'Zobrazí nastavenou zeměpisnou délku.';

  @override
  String get repeater_cliHelpGetRxDelay => 'Zobrazí základní hodnotu rxdelay.';

  @override
  String get repeater_cliHelpGetTxDelay =>
      'Zobrazí koeficient txdelay pro režim flood.';

  @override
  String get repeater_cliHelpGetDirectTxDelay =>
      'Zobrazí koeficient txdelay pro režim direct.';

  @override
  String get repeater_cliHelpGetFloodMax =>
      'Zobrazí maximální počet skoků flood.';

  @override
  String get repeater_cliHelpGetOwnerInfo =>
      'Zobrazí řetězec s kontaktními údaji vlastníka.';

  @override
  String get repeater_cliHelpGetPathHashMode =>
      'Zobrazí režim velikosti ID uzlu používaný v advertech (0 = 1 bajt, 1 = 2 bajty, 2 = 3 bajty).';

  @override
  String get repeater_cliHelpGetLoopDetect =>
      'Zobrazí citlivost detekce smyček.';

  @override
  String get repeater_cliHelpGetAcl =>
      '(pouze sériově) Vypíše záznamy řízení přístupu na opakovači.';

  @override
  String get repeater_cliHelpGetBridgeEnabled =>
      'Zobrazí, zda je bridge zapnut.';

  @override
  String get repeater_cliHelpGetBridgeDelay => 'Zobrazí zpoždění bridge v ms.';

  @override
  String get repeater_cliHelpGetBridgeSource =>
      'Zobrazí, zda bridge loguje pakety RX, nebo TX.';

  @override
  String get repeater_cliHelpGetBridgeBaud =>
      '(pouze bridge RS232) Zobrazí přenosovou rychlost bridge.';

  @override
  String get repeater_cliHelpGetBridgeChannel =>
      '(pouze bridge ESPNow) Zobrazí kanál WiFi bridge.';

  @override
  String get repeater_cliHelpGetBridgeSecret =>
      '(pouze bridge ESPNow) Zobrazí sdílený tajný klíč bridge.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      '(pouze NRF52) Zobrazí verzi bootloaderu.';

  @override
  String get repeater_cliHelpGetAdcMultiplier =>
      'Zobrazí násobitel ADC (škálování napětí baterie).';

  @override
  String get repeater_cliHelpGetPwrMgtSupport =>
      'Oznámí, zda deska podporuje správu napájení.';

  @override
  String get repeater_cliHelpGetPwrMgtSource =>
      'Zobrazí aktuální zdroj napájení: externí, nebo baterie.';

  @override
  String get repeater_cliHelpGetPwrMgtBootReason =>
      'Zobrazí nejnovější důvody resetu a vypnutí.';

  @override
  String get repeater_cliHelpGetPwrMgtBootMv =>
      'Zobrazí napětí baterie při startu v mV.';

  @override
  String get repeater_cliHelpSensorGet =>
      'Přečte vlastní nastavení senzoru podle klíče.';

  @override
  String get repeater_cliHelpSensorSet => 'Zapíše vlastní nastavení senzoru.';

  @override
  String get repeater_cliHelpSensorList =>
      'Vypíše všechna vlastní nastavení senzorů, stránkovaně od volitelného počátečního indexu.';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Zobrazí aktuální výchozí rozsah regionu.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Nastaví výchozí rozsah regionu. Pro vymazání použijte „<null>“.';

  @override
  String get repeater_cliHelpRegionListAllowed =>
      'Vypíše regiony, které povolují flood provoz.';

  @override
  String get repeater_cliHelpRegionListDenied =>
      'Vypíše regiony, které flood provoz zakazují.';

  @override
  String get repeater_cliHelpStatsPackets =>
      '(pouze sériově) Zobrazí statistiky na úrovni paketů.';

  @override
  String get repeater_cliHelpStatsRadio =>
      '(pouze sériově) Zobrazí statistiky rádia.';

  @override
  String get repeater_cliHelpStatsCore =>
      '(pouze sériově) Zobrazí statistiky jádra firmwaru.';

  @override
  String get telemetry_receivedData => 'Přijatá telemetrická data';

  @override
  String get telemetry_requestTimeout => 'Požadavek na telemetrii vypršel.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Chyba při načítání telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Žádná telemetrická data nejsou k dispozici.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanál $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Baterie';

  @override
  String get telemetry_voltageLabel => 'Napětí';

  @override
  String get telemetry_mcuTemperatureLabel => 'Teplota MCU';

  @override
  String get telemetry_temperatureLabel => 'Teplota';

  @override
  String get telemetry_currentLabel => 'Proud';

  @override
  String telemetry_batteryValue(int percent, String volts) {
    return '$percent% / $volts V';
  }

  @override
  String telemetry_voltageValue(String volts) {
    return '$volts V';
  }

  @override
  String telemetry_currentValue(String amps) {
    return '$amps A';
  }

  @override
  String telemetry_temperatureValue(String celsius, String fahrenheit) {
    return '$celsius °C / $fahrenheit °F';
  }

  @override
  String get telemetry_digitalInputLabel => 'Digitální vstup';

  @override
  String get telemetry_digitalOutputLabel => 'Digitální výstup';

  @override
  String get telemetry_analogInputLabel => 'Analogový vstup';

  @override
  String get telemetry_analogOutputLabel => 'Analogový výstup';

  @override
  String get telemetry_genericLabel => 'Obecný senzor';

  @override
  String get telemetry_luminosityLabel => 'Osvětlení';

  @override
  String get telemetry_presenceLabel => 'Přítomnost';

  @override
  String get telemetry_humidityLabel => 'Vlhkost';

  @override
  String get telemetry_accelerometerLabel => 'Akcelerometr';

  @override
  String get telemetry_pressureLabel => 'Tlak';

  @override
  String get telemetry_altitudeLabel => 'Nadmořská výška';

  @override
  String get telemetry_frequencyLabel => 'Frekvence';

  @override
  String get telemetry_percentageLabel => 'Procento';

  @override
  String get telemetry_concentrationLabel => 'Koncentrace';

  @override
  String get telemetry_powerLabel => 'Výkon';

  @override
  String get telemetry_distanceLabel => 'Vzdálenost';

  @override
  String get telemetry_energyLabel => 'Energie';

  @override
  String get telemetry_directionLabel => 'Směr';

  @override
  String get telemetry_timeLabel => 'Čas';

  @override
  String get telemetry_gyrometerLabel => 'Gyroskop';

  @override
  String get telemetry_colourLabel => 'Barva';

  @override
  String get telemetry_gpsLabel => 'GPS';

  @override
  String get telemetry_switchLabel => 'Spínač';

  @override
  String get telemetry_polylineLabel => 'Lomená čára';

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
  String get telemetry_autoFetchQuantity => 'Počet požadavků';

  @override
  String get telemetry_error => 'Data se nepodařilo načíst';

  @override
  String get neighbors_receivedData => 'Přijatá data o sousedech';

  @override
  String get neighbors_requestTimedOut => 'Požadavek na sousedy vypršel.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Chyba při načítání sousedů: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Sousedé opakovače';

  @override
  String get neighbors_noData => 'Data o sousedech nejsou k dispozici.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Neznámý $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Slyšen před: $time';
  }

  @override
  String get channelPath_title => 'Cesta paketu';

  @override
  String get channelPath_viewMap => 'Zobrazit mapu';

  @override
  String get channelPath_otherObservedPaths => 'Další pozorované cesty';

  @override
  String get channelPath_repeaterHops => 'Skoky přes opakovače';

  @override
  String get channelPath_noHopDetails =>
      'Podrobnosti o skocích nejsou pro tento paket k dispozici.';

  @override
  String get channelPath_messageDetails => 'Podrobnosti zprávy';

  @override
  String get channelPath_senderLabel => 'Odesílatel';

  @override
  String get channelPath_timeLabel => 'Čas';

  @override
  String get channelPath_repeatsLabel => 'Opakování';

  @override
  String channelPath_pathLabel(int index) {
    return 'Cesta $index';
  }

  @override
  String get channelPath_observedLabel => 'Pozorováno';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Pozorovaná cesta $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Žádná data o poloze';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day. $month. $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Neznámá';

  @override
  String get channelPath_floodPath => 'Flood';

  @override
  String get channelPath_directPath => 'Přímo';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 z $total skoků';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed z $total skoků';
  }

  @override
  String get channelPath_mapTitle => 'Mapa cesty';

  @override
  String get channelPath_noRepeaterLocations =>
      'Pro tuto cestu nejsou k dispozici polohy opakovačů.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Cesta $index (primární)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Cesta';

  @override
  String get channelPath_observedPathHeader => 'Pozorovaná cesta';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Pro tento paket nejsou k dispozici podrobnosti o skocích.';

  @override
  String get channelPath_unknownRepeater => 'Neznámý opakovač';

  @override
  String get community_title => 'Komunita';

  @override
  String get community_create => 'Vytvořit komunitu';

  @override
  String get community_createDesc =>
      'Vytvořte novou komunitu a sdílejte ji pomocí QR kódu.';

  @override
  String get community_join => 'Připojit se';

  @override
  String get community_joinTitle => 'Připojit se ke komunitě';

  @override
  String community_joinConfirmation(String name) {
    return 'Chcete se připojit ke komunitě „$name“?';
  }

  @override
  String get community_scanQr => 'Skenovat QR komunity';

  @override
  String get community_scanInstructions => 'Namiřte kameru na QR kód komunity';

  @override
  String get community_showQr => 'Zobrazit QR kód';

  @override
  String get community_publicChannel => 'Veřejný kanál komunity';

  @override
  String get community_hashtagChannel => 'Hashtag komunity';

  @override
  String get community_name => 'Název komunity';

  @override
  String get community_enterName => 'Zadejte název komunity';

  @override
  String community_created(String name) {
    return 'Komunita „$name“ byla vytvořena';
  }

  @override
  String community_joined(String name) {
    return 'Připojeno ke komunitě „$name“';
  }

  @override
  String get community_qrTitle => 'Sdílet komunitu';

  @override
  String community_qrInstructions(String name) {
    return 'Naskenujte tento QR kód a připojte se k „$name“';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'K hashtag kanálům komunity se mohou připojit pouze členové komunity';

  @override
  String get community_invalidQrCode => 'Neplatný QR kód komunity';

  @override
  String get community_alreadyMember => 'Již jste členem';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Již jste členem komunity „$name“.';
  }

  @override
  String get community_addPublicChannel => 'Přidat veřejný kanál komunity';

  @override
  String get community_addPublicChannelHint =>
      'Automaticky přidat veřejný kanál této komunity';

  @override
  String get community_noCommunities => 'Zatím nejste v žádné komunitě';

  @override
  String get community_scanOrCreate =>
      'Začněte naskenováním QR kódu nebo vytvořením komunity';

  @override
  String get community_manageCommunities => 'Spravovat komunity';

  @override
  String get community_delete => 'Opustit komunitu';

  @override
  String community_deleteConfirm(String name) {
    return 'Opustit „$name“?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Tím se také odstraní kanály ($count) a jejich zprávy.';
  }

  @override
  String community_deleted(String name) {
    return 'Opustili jste komunitu „$name“';
  }

  @override
  String get community_regenerateSecret => 'Vygenerovat nový tajný klíč';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Vygenerovat nový tajný klíč pro „$name“? Všichni členové budou muset naskenovat nový QR kód, aby mohli dál komunikovat.';
  }

  @override
  String get community_regenerate => 'Vygenerovat znovu';

  @override
  String community_secretRegenerated(String name) {
    return 'Nový tajný klíč pro „$name“ byl vygenerován';
  }

  @override
  String get community_updateSecret => 'Aktualizovat tajný klíč';

  @override
  String community_secretUpdated(String name) {
    return 'Tajný klíč pro „$name“ byl aktualizován';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Naskenujte nový QR kód pro aktualizaci tajného klíče pro „$name“';
  }

  @override
  String get community_addHashtagChannel => 'Přidat hashtag komunity';

  @override
  String get community_addHashtagChannelDesc =>
      'Přidat hashtag kanál pro tuto komunitu';

  @override
  String get community_selectCommunity => 'Vybrat komunitu';

  @override
  String get community_regularHashtag => 'Běžný hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Veřejný hashtag (připojit se může kdokoli)';

  @override
  String get community_communityHashtag => 'Hashtag komunity';

  @override
  String get community_communityHashtagDesc => 'Soukromý pro členy komunity';

  @override
  String community_forCommunity(String name) {
    return 'Pro $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrovat a řadit';

  @override
  String get listFilter_sortBy => 'Řadit podle';

  @override
  String get listFilter_latestMessages => 'Nejnovější zprávy';

  @override
  String get listFilter_heardRecently => 'Nedávno slyšené';

  @override
  String get listFilter_az => 'A–Z';

  @override
  String get listFilter_filters => 'Filtry';

  @override
  String get listFilter_all => 'Vše';

  @override
  String get listFilter_favorites => 'Oblíbené';

  @override
  String get listFilter_addToFavorites => 'Přidat do oblíbených';

  @override
  String get listFilter_removeFromFavorites => 'Odebrat z oblíbených';

  @override
  String get listFilter_users => 'Uživatelé';

  @override
  String get listFilter_repeaters => 'Opakovače';

  @override
  String get listFilter_roomServers => 'Room servery';

  @override
  String get listFilter_unreadOnly => 'Pouze nepřečtené';

  @override
  String get listFilter_newGroup => 'Nová skupina';

  @override
  String get pathTrace_you => 'Vy';

  @override
  String get pathTrace_failed => 'Trasování cesty selhalo.';

  @override
  String get pathTrace_notAvailable => 'Trasování cesty není k dispozici.';

  @override
  String get pathTrace_refreshTooltip => 'Obnovit trasování cesty.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Jednomu nebo více skokům chybí poloha!';

  @override
  String get pathTrace_clearTooltip => 'Vymazat cestu.';

  @override
  String get losSelectStartEnd => 'Vyberte počáteční a koncový uzel pro LOS.';

  @override
  String losRunFailed(String error) {
    return 'Kontrola přímé viditelnosti selhala: $error';
  }

  @override
  String get losClearAllPoints => 'Vymazat všechny body';

  @override
  String get losRunToViewElevationProfile =>
      'Spusťte LOS pro zobrazení výškového profilu';

  @override
  String get losMenuTitle => 'Nabídka LOS';

  @override
  String get losMenuSubtitle =>
      'Klepněte na uzly nebo dlouze stiskněte mapu pro vlastní body';

  @override
  String get losShowDisplayNodes => 'Zobrazit uzly na displeji';

  @override
  String get losCustomPoints => 'Vlastní body';

  @override
  String losCustomPointLabel(int index) {
    return 'Vlastní $index';
  }

  @override
  String get losPointA => 'Bod A';

  @override
  String get losPointB => 'Bod B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Anténa A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Anténa B: $value $unit';
  }

  @override
  String get losRun => 'Spustit LOS';

  @override
  String get losNoElevationData => 'Žádná výšková data';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, LOS volná, min. odstup $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blokováno o $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: kontroluji...';

  @override
  String get losStatusNoData => 'LOS: žádná data';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total volných, $blocked blokovaných, $unknown neznámých';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Výšková data nejsou k dispozici pro jeden nebo více vzorků.';

  @override
  String get losErrorInvalidInput =>
      'Neplatné body/výšková data pro výpočet LOS.';

  @override
  String get losRenameCustomPoint => 'Přejmenovat vlastní bod';

  @override
  String get losPointName => 'Název bodu';

  @override
  String get losShowPanelTooltip => 'Zobrazit panel LOS';

  @override
  String get losHidePanelTooltip => 'Skrýt panel LOS';

  @override
  String get losElevationAttribution => 'Výšková data: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Rádiový horizont';

  @override
  String get losLegendLosBeam => 'Paprsek LOS';

  @override
  String get losLegendTerrain => 'Terén';

  @override
  String get losBlockedSpotsTitle => 'Blokovaná místa';

  @override
  String get losBlockedSpotsHint =>
      'Klepnutím na blokované místo jej zvýrazníte na mapě.';

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
  String get losSelectedObstructionTitle => 'Vybraná překážka';

  @override
  String losSelectedObstructionDetails(
    String obstruction,
    String heightUnit,
    String distanceFromA,
    String distanceUnit,
    String distanceFromB,
  ) {
    return 'Blokováno o $obstruction $heightUnit, $distanceFromA od A a $distanceFromB od B ($distanceUnit).';
  }

  @override
  String get losFrequencyLabel => 'Frekvence';

  @override
  String get losFrequencyInfoTooltip => 'Zobrazit podrobnosti výpočtu';

  @override
  String get losFrequencyDialogTitle => 'Výpočet rádiového horizontu';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Počínaje k=$baselineK na $baselineFreq MHz výpočet upraví k-faktor pro aktuální pásmo $frequencyMHz MHz, který určuje zakřivený strop rádiového horizontu.';
  }

  @override
  String get contacts_pathTrace => 'Trasování cesty';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Trasování cesty k opakovači';

  @override
  String get contacts_repeaterPing => 'Ping opakovače';

  @override
  String get contacts_roomPathTrace => 'Trasování cesty k room serveru';

  @override
  String get contacts_roomPing => 'Ping room serveru';

  @override
  String get contacts_chatTraceRoute => 'Trasa trasování cesty';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Trasovat cestu k $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Schránka je prázdná.';

  @override
  String get contacts_invalidAdvertFormat => 'Neplatná data kontaktu';

  @override
  String get contacts_contactImported => 'Kontakt byl importován.';

  @override
  String get contacts_contactImportFailed =>
      'Kontakt se nepodařilo importovat.';

  @override
  String get discoveredContacts_export => 'Exportovat objevené kontakty';

  @override
  String get discoveredContacts_import => 'Importovat objevené kontakty';

  @override
  String discoveredContacts_exported(String path) {
    return 'Objevené kontakty exportovány do $path.';
  }

  @override
  String discoveredContacts_exportFailed(String error) {
    return 'Export objevených kontaktů selhal: $error';
  }

  @override
  String discoveredContacts_imported(int count) {
    return 'Importováno objevených kontaktů: $count.';
  }

  @override
  String get discoveredContacts_importNoContacts =>
      'V importovaném souboru nebyly nalezeny žádné kontakty.';

  @override
  String discoveredContacts_importSummary(
    int imported,
    int skipped,
    int invalid,
  ) {
    return 'Importováno objevených kontaktů: $imported. Přeskočeno již známých: $skipped a nečitelných záznamů: $invalid.';
  }

  @override
  String get discoveredContacts_importInvalidFile =>
      'Soubor není exportem objevených kontaktů.';

  @override
  String discoveredContacts_importTooLarge(int maxMb) {
    return 'Importovaný soubor je příliš velký (maximum $maxMb MB).';
  }

  @override
  String discoveredContacts_importFailed(String error) {
    return 'Import objevených kontaktů selhal: $error';
  }

  @override
  String get contacts_zeroHopAdvert => 'Zero-hop advert';

  @override
  String get contacts_floodAdvert => 'Flood advert';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopírovat advert do schránky';

  @override
  String get contacts_addContactFromClipboard => 'Přidat kontakt ze schránky';

  @override
  String get contacts_scanQrCode => 'Skenovat QR kód';

  @override
  String get contacts_scanQrInstructions =>
      'Namiřte kameru na QR kód kontaktu MeshCore';

  @override
  String get contacts_qrFromGallery => 'Skenovat QR z galerie';

  @override
  String get contacts_noQrCodeFound =>
      'Ve vybraném obrázku nebyl nalezen žádný QR kód.';

  @override
  String get contacts_qrGalleryFailed => 'Galerii se nepodařilo otevřít.';

  @override
  String get contacts_ShareContact => 'Kopírovat kontakt do schránky';

  @override
  String get contacts_ShareContactZeroHop => 'Sdílet kontakt přes advert';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Kontakt odeslán přes advert.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Kontakt se nepodařilo odeslat.';

  @override
  String get contacts_contactAdvertCopied => 'Advert zkopírován do schránky.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopírování advertu do schránky selhalo.';

  @override
  String get notification_activityTitle => 'Aktivita MeshCore';

  @override
  String get notification_lowBatteryTitle => 'Slabá baterie';

  @override
  String notification_lowBatteryBody(String deviceName, int percent) {
    return 'Baterie zařízení $deviceName je na $percent%';
  }

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zpráv',
      many: 'zprávy',
      few: 'zprávy',
      one: 'zpráva',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zpráv v kanálech',
      many: 'zprávy v kanálech',
      few: 'zprávy v kanálech',
      one: 'zpráva v kanálu',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nových uzlů',
      many: 'nového uzlu',
      few: 'nové uzly',
      one: 'nový uzel',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Objeveno: $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Přijata nová zpráva';

  @override
  String get notification_sharedLocation => 'Sdílel(a) polohu';

  @override
  String notification_sharedLocationNamed(String label) {
    return 'Sdílel(a) polohu: $label';
  }

  @override
  String notification_reacted(String emoji) {
    return 'Reakce $emoji';
  }

  @override
  String get notification_sentGif => 'Odeslal(a) GIF';

  @override
  String get notification_sentImage => 'Odeslal(a) obrázek';

  @override
  String get notification_actionReply => 'Odpovědět';

  @override
  String get notification_actionMarkRead => 'Označit jako přečtené';

  @override
  String get notification_actionMuteChannel => 'Ztlumit kanál';

  @override
  String get notification_replyHint => 'Zpráva';

  @override
  String get notification_you => 'Vy';

  @override
  String get notification_replyFailedTitle => 'Odpověď nebyla odeslána';

  @override
  String get notification_replyNotConnected =>
      'Nejste připojeni k rádiu. Připojte se znovu v MeshCore Open a odešlete odpověď znovu.';

  @override
  String get notification_replyTooLong =>
      'Vaše odpověď je příliš dlouhá na odeslání z oznámení. Odešlete ji raději z MeshCore Open.';

  @override
  String get notification_replyUnavailable =>
      'Tato konverzace již není na připojeném rádiu.';

  @override
  String get notification_replySendFailed =>
      'Vaše odpověď možná nebyla odeslána. Zkontrolujte to v MeshCore Open a zkuste to znovu.';

  @override
  String get notification_replyAppNotRunning =>
      'MeshCore Open neběží. Otevřete ji a odešlete odpověď znovu.';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportovat opakovače / room servery do GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportuje opakovače / room servery s polohou do souboru GPX.';

  @override
  String get settings_gpxExportContacts => 'Exportovat companiony do GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exportuje companiony s polohou do souboru GPX.';

  @override
  String get settings_gpxExportAll => 'Exportovat všechny kontakty do GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exportuje všechny kontakty s polohou do souboru GPX.';

  @override
  String get settings_gpxExportSuccess => 'Soubor GPX byl úspěšně exportován.';

  @override
  String get settings_gpxExportNoContacts => 'Žádné kontakty k exportu.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Na vašem zařízení/OS není podporováno';

  @override
  String get settings_gpxExportError => 'Při exportu došlo k chybě.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Polohy opakovačů a room serverů';

  @override
  String get settings_gpxExportChat => 'Polohy companionů';

  @override
  String get settings_gpxExportAllContacts => 'Polohy všech kontaktů';

  @override
  String get settings_gpxExportShareText =>
      'Mapová data exportovaná z meshcore-open';

  @override
  String get settings_gpxExportShareSubject =>
      'Export mapových dat GPX z meshcore-open';

  @override
  String get snrIndicator_nearByRepeaters => 'Opakovače v okolí';

  @override
  String get snrIndicator_lastSeen => 'Naposledy zaznamenán';

  @override
  String get snrIndicator_nearByRepeatersDescription =>
      'Opakovače, které vaše rádio slyšelo přímo, nejnověji slyšené první.';

  @override
  String get snrIndicator_unknownRepeater => 'Neznámý opakovač';

  @override
  String get snrIndicator_unknownRepeaterHint =>
      'Tento opakovač zatím není ve vašich kontaktech. Jeho název, poloha a možnosti se zobrazí, až vaše rádio přijme jeho advert.';

  @override
  String get contactsSettings_title => 'Nastavení kontaktů';

  @override
  String get contactsSettings_autoAddTitle => 'Automatické vyhledávání';

  @override
  String get contactsSettings_otherTitle => 'Další nastavení kontaktů';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automaticky přidávat uživatele';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Povolit companionu automaticky přidávat objevené uživatele.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automaticky přidávat opakovače';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Povolit companionu automaticky přidávat objevené opakovače.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automaticky přidávat room servery';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Povolit companionu automaticky přidávat objevené room servery.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automaticky přidávat senzory';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Povolit companionu automaticky přidávat objevené senzory.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Přepsat nejstarší';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Když je seznam kontaktů plný, nejstarší kontakt, který není oblíbený, bude nahrazen.';

  @override
  String get contactsSettings_evictDiscoveredContactsTitle =>
      'Odstraňovat objevené kontakty';

  @override
  String contactsSettings_evictDiscoveredContactsSubtitle(int limit) {
    return 'Když je zapnuto, aplikace odstraní nejstarší objevené kontakty, jakmile seznam objevených dosáhne limitu $limit položek.';
  }

  @override
  String get discoveredContacts_Title => 'Objevené kontakty';

  @override
  String get discoveredContacts_noMatching => 'Žádné odpovídající kontakty';

  @override
  String get discoveredContacts_searchHint => 'Hledat objevené kontakty';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt přidán';

  @override
  String get discoveredContacts_addContact => 'Přidat kontakt';

  @override
  String get discoveredContacts_copyContact => 'Zkopírovat kontakt do schránky';

  @override
  String get discoveredContacts_deleteContact => 'Smazat objevený kontakt';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Smazat všechny objevené kontakty';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Opravdu chcete smazat všechny objevené kontakty?';

  @override
  String get discoveredContacts_scan => 'Hledat uzly v okolí';

  @override
  String get discoveredContacts_scanTitle => 'Uzly v okolí';

  @override
  String get discoveredContacts_scanExplanation =>
      'Vyzve uzly v přímém dosahu rádia, aby se identifikovaly. Opakovače a senzory odpoví. Room servery a companiony obvykle ne.';

  @override
  String get discoveredContacts_scanning => 'Hledání…';

  @override
  String discoveredContacts_scanFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nalezeno $count uzlů',
      many: 'Nalezeno $count uzlu',
      few: 'Nalezeny $count uzly',
      one: 'Nalezen 1 uzel',
    );
    return '$_temp0';
  }

  @override
  String get discoveredContacts_scanNoResults =>
      'Žádný uzel neodpověděl. Opakovače omezují, jak často odpovídají, zkuste to znovu za minutu.';

  @override
  String get discoveredContacts_scanAgain => 'Hledat znovu';

  @override
  String get discoveredContacts_scanFailed =>
      'Požadavek na vyhledání se nepodařilo odeslat.';

  @override
  String discoveredContacts_scanSignal(String snr, String remoteSnr) {
    return 'Signál $snr dB · slyšeli nás na $remoteSnr dB';
  }

  @override
  String get discoveredContacts_scanInContacts => 'Již v kontaktech';

  @override
  String get discoveredContacts_scanNameLater =>
      'Název se zobrazí po jejich příštím advertu';

  @override
  String get chat_sendCooldown => 'Před dalším odesláním chvíli počkejte.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Přejít na nejstarší nepřečtenou';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Při otevření chatu s nepřečtenými zprávami se posunout na první nepřečtenou místo na nejnovější.';

  @override
  String get appSettings_autoFetchRepeaterSettings =>
      'Automaticky načítat nastavení opakovače';

  @override
  String get appSettings_autoFetchRepeaterSettingsSubtitle =>
      'Při otevření nastavení opakovače vyžádat každé nastavení. Každé je samostatný požadavek přes LoRa, takže je to pomalé a spotřebovává airtime. Když je vypnuto, klepněte na Obnovit vše nebo obnovte jednotlivé sekce.';

  @override
  String get appSettings_languageHu => 'Maďarština';

  @override
  String get appSettings_languageJa => 'Japonština';

  @override
  String get appSettings_languageKo => 'Korejština';

  @override
  String get radioStats_tooltip => 'Statistiky rádia a mesh';

  @override
  String get radioStats_screenTitle => 'Statistiky rádia';

  @override
  String get radioStats_sectionSignal => 'Signál';

  @override
  String get radioStats_sectionAirtime => 'Airtime';

  @override
  String get radioStats_notConnected =>
      'Pro zobrazení statistik rádia se připojte k zařízení.';

  @override
  String get radioStats_firmwareTooOld =>
      'Statistiky rádia vyžadují firmware companionu verze 8 nebo novější.';

  @override
  String get radioStats_waiting => 'Čekání na data…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Úroveň šumu: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Poslední RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Poslední SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Airtime TX (celkem): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Airtime RX (celkem): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Úroveň šumu (dBm) v posledních vzorcích.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Úroveň šumu: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Načítání statistik rádia…';

  @override
  String get radioStats_settingsTile => 'Statistiky rádia';

  @override
  String get radioStats_settingsSubtitle => 'Úroveň šumu, RSSI, SNR a airtime';

  @override
  String get translation_title => 'Překlad';

  @override
  String get imageMessages_enableTitle => 'Povolit obrázkové zprávy';

  @override
  String get imageMessages_enableSubtitle =>
      'Odesílejte obrázky přes mesh. Vyžaduje jednorázové stažení modelu obrázků.';

  @override
  String get imageMessages_modelSectionTitle => 'Model obrázků';

  @override
  String get imageMessages_downloadModel => 'Stáhnout';

  @override
  String get imageMessages_cancelDownload => 'Zrušit';

  @override
  String get imageMessages_removeModel => 'Odebrat model';

  @override
  String get imageMessages_modelReady => 'Připraveno';

  @override
  String get imageMessages_modelNotPublished =>
      'Zatím nezveřejněno — tato verze jej nemůže stáhnout.';

  @override
  String get imageMessages_downloadFailed =>
      'Model obrázků se nepodařilo stáhnout.';

  @override
  String get imageMessages_autoProcessTitle =>
      'Zpracovávat obrázky automaticky';

  @override
  String get imageMessages_autoProcessSubtitle =>
      'Rekonstruovat každý obrázek ihned po příchodu. Pokaždé na sekundu využije asi 2 GB paměti; ponechte vypnuté a rekonstruujte klepnutím.';

  @override
  String get translation_enableTitle => 'Povolit překlad';

  @override
  String get translation_enableSubtitle =>
      'Překládat příchozí zprávy a povolit překlad před odesláním.';

  @override
  String get translation_composerTitle => 'Překládat před odesláním';

  @override
  String get translation_composerSubtitle =>
      'Určuje výchozí stav ikony překladu v poli pro psaní.';

  @override
  String get translation_autoIncomingTitle =>
      'Automaticky překládat příchozí zprávy';

  @override
  String get translation_autoIncomingSubtitle =>
      'Automaticky překládá zprávy pro oznámení a pro chat nebo kanál.';

  @override
  String get translation_translateMessage => 'Přeložit zprávu';

  @override
  String get translation_targetLanguage => 'Cílový jazyk';

  @override
  String get translation_useAppLanguage => 'Použít jazyk aplikace';

  @override
  String get translation_downloadedModelLabel => 'Stažený model';

  @override
  String get translation_presetModelLabel => 'Přednastavený model Hugging Face';

  @override
  String get translation_manualUrlLabel => 'Ruční URL modelu';

  @override
  String get translation_downloadModel => 'Stáhnout model';

  @override
  String get translation_downloading => 'Stahování...';

  @override
  String get translation_working => 'Pracuji...';

  @override
  String get translation_stop => 'Zastavit';

  @override
  String get translation_mergingChunks =>
      'Slučování stažených částí do výsledného souboru...';

  @override
  String get translation_downloadedModels => 'Stažené modely';

  @override
  String get translation_deleteModel => 'Smazat model';

  @override
  String get translation_modelDownloaded => 'Překladový model byl stažen.';

  @override
  String get translation_downloadStopped => 'Stahování zastaveno.';

  @override
  String translation_downloadFailed(String error) {
    return 'Stahování selhalo: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Nejprve zadejte URL modelu.';

  @override
  String get scanner_linuxPairingShowPin => 'Zobrazit PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Skrýt PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN pro párování Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Zadejte PIN pro $deviceName (pokud žádný není, nechte prázdné).';
  }

  @override
  String get translation_messageTranslation => 'Překlad zpráv';

  @override
  String get translation_translateBeforeSending => 'Překládat před odesláním';

  @override
  String get translation_composerEnabledHint =>
      'Zprávy budou před odesláním přeloženy.';

  @override
  String get translation_composerDisabledHint =>
      'Odesílat zprávy v původním jazyce, v jakém byly napsány.';

  @override
  String translation_translateTo(String language) {
    return 'Přeložit do jazyka: $language';
  }

  @override
  String get translation_translationOptions => 'Možnosti překladu';

  @override
  String get translation_systemLanguage => 'Jazyk systému';

  @override
  String get background_serviceTitle => 'MeshCore běží';

  @override
  String get background_serviceText => 'Udržuje připojení BLE';

  @override
  String appSettings_translationModelDeleted(String name) {
    return 'Smazáno: $name';
  }

  @override
  String appSettings_translationModelDeleteFailed(String error) {
    return 'Smazání se nezdařilo: $error';
  }

  @override
  String channels_channelUpdateFailed(String error) {
    return 'Aktualizace kanálu se nezdařila: $error';
  }

  @override
  String get contact_typeChat => 'Chat';

  @override
  String get contact_typeRepeater => 'Opakovač';

  @override
  String get contact_typeRoom => 'Room';

  @override
  String get contact_typeSensor => 'Senzor';

  @override
  String get contact_typeUnknown => 'Neznámý';

  @override
  String get map_zoomIn => 'Přiblížit';

  @override
  String get map_zoomOut => 'Oddálit';

  @override
  String get map_centerMap => 'Vycentrovat mapu';

  @override
  String get chrome_bluetoothRequiresChromium =>
      'Web Bluetooth vyžaduje prohlížeč Chromium';

  @override
  String channels_communityShortId(String id) {
    return 'ID: $id...';
  }

  @override
  String get pathTrace_legendGpsConfirmed => 'Potvrzeno GPS';

  @override
  String get pathTrace_legendInferred => 'Odvozená poloha';

  @override
  String get pathMap_viewSingle => 'Jednotlivě';

  @override
  String get pathMap_viewCombined => 'Sloučeně';

  @override
  String get pathMap_play => 'Přehrát';

  @override
  String get pathMap_pause => 'Pozastavit';

  @override
  String get pathMap_replay => 'Přehrát znovu';

  @override
  String get pathMap_stepBack => 'Předchozí skok';

  @override
  String get pathMap_stepForward => 'Další skok';

  @override
  String get pathMap_animationOn => 'Zobrazit animaci paketu';

  @override
  String get pathMap_animationOff => 'Skrýt animaci paketu';

  @override
  String pathMap_hopOf(int current, int total) {
    return 'Skok $current z $total';
  }

  @override
  String pathMap_observedPaths(int count) {
    return 'Pozorované cesty: $count';
  }

  @override
  String get pathMap_primary => 'Hlavní';

  @override
  String pathMap_alternate(int index) {
    return 'Alt $index';
  }

  @override
  String pathMap_hopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skoků',
      many: '$count skoku',
      few: '$count skoky',
      one: '1 skok',
    );
    return '$_temp0';
  }

  @override
  String pathMap_gpsCount(int confirmed, int total) {
    return '$confirmed/$total GPS';
  }

  @override
  String get pathMap_legendShared => 'Sdílený úsek';

  @override
  String get pathMap_legendEstimated => 'Odhadovaný úsek';

  @override
  String pathMap_sharedNodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Používá $count cest',
      many: 'Používá $count cesty',
      few: 'Používají $count cesty',
      one: 'Používá 1 cesta',
    );
    return '$_temp0';
  }

  @override
  String pathMap_partialAnimation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skoků nemá polohu — zobrazená cesta je částečná',
      many: '$count skoku nemá polohu — zobrazená cesta je částečná',
      few: '$count skoky nemají polohu — zobrazená cesta je částečná',
      one: '1 skok nemá polohu — zobrazená cesta je částečná',
    );
    return '$_temp0';
  }

  @override
  String get pathMap_showAllPaths => 'Zobrazit vše';

  @override
  String get pathMap_hidePath => 'Skrýt cestu';

  @override
  String get pathMap_showPath => 'Zobrazit cestu';

  @override
  String get pathMap_collapsePanel => 'Sbalit panel';

  @override
  String get pathMap_expandPanel => 'Rozbalit panel';

  @override
  String get pathMap_expandHopList => 'Rozbalit seznam skoků';

  @override
  String get pathMap_showMap => 'Zobrazit mapu';

  @override
  String get pathMap_noLocation => 'Bez polohy';

  @override
  String get pathMap_followPacket => 'Zamknout pohled na paket';

  @override
  String get pathMap_unfollowPacket => 'Odemknout pohled od paketu';

  @override
  String get imageSend_title => 'Odeslat obrázek';

  @override
  String get imageSend_cropNote =>
      'Změněna velikost na 512 × 512 · poměr stran nezachován';

  @override
  String imageSend_lossyNote(int bytes) {
    return 'Komprimováno na asi $bytes bajtů. Model příjemce jej rekonstruuje, takže detaily se budou lišit.';
  }

  @override
  String get imageSend_viewOriginal => 'Originál';

  @override
  String get imageSend_viewReconstruction => 'Co uvidí příjemci';

  @override
  String get imageSend_reconstructionUnavailable =>
      'Toto zařízení nemůže zobrazit náhled rekonstrukce.';

  @override
  String get imageSend_modelNotDownloaded =>
      'Model obrázků ještě není stažen. Pro odesílání obrázků jej stáhněte v Nastavení.';

  @override
  String get imageSend_originalSize => 'Originál';

  @override
  String get imageSend_onAirSize => 'Přes rádio';

  @override
  String get imageSend_quality => 'Kvalita';

  @override
  String get imageSend_qualityStandard => 'Standardní';

  @override
  String get imageSend_qualityHigh => 'Vysoká';

  @override
  String get imageSend_packetsLabel => 'Pakety';

  @override
  String get imageSend_airtimeLabel => 'Čas ve vzduchu';

  @override
  String get imageSend_sizeLabel => 'Data';

  @override
  String imageSend_packetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paketů',
      many: 'paketu',
      few: 'pakety',
      one: 'paket',
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
  String get imageSend_radioUnknownTitle => 'Nastavení rádia neznámé';

  @override
  String get imageSend_radioUnknownBody =>
      'Připojte se k zařízení, aby bylo možné vypočítat čas ve vzduchu.';

  @override
  String get imageSend_longSendTitle => 'Dlouhý přenos';

  @override
  String imageSend_longSendBody(String duration) {
    return 'Kanál bude obsazen asi $duration.';
  }

  @override
  String get imageSend_floodNote =>
      'Směrování flood: každý opakovač v dosahu každý paket znovu vysílá, takže kanál zůstane obsazen déle, než je uvedeno.';

  @override
  String get imageSend_parityTitle => 'Přidat záchranný paket';

  @override
  String get imageSend_paritySubtitle =>
      'Jeden paket navíc. Skupinové zprávy nejsou potvrzovány, takže příjemce může obrázek obnovit, pokud se ztratí jediný paket.';

  @override
  String get imageSend_send => 'Odeslat';

  @override
  String get imageSend_cancel => 'Zrušit';

  @override
  String get imageSend_encodeFailed => 'Tento obrázek se nepodařilo zakódovat.';

  @override
  String get imageSend_codecDownloading => 'Model obrázků se stále stahuje.';

  @override
  String get imageSend_codecUnavailable =>
      'Odesílání obrázků na tomto zařízení není k dispozici.';

  @override
  String get imageSend_codecDisabled =>
      'Obrázkové zprávy jsou vypnuty v nastavení.';

  @override
  String get imageSend_deviceUnsupported =>
      'Toto rádio neumí odesílat obrazové pakety. Připojte zařízení s firmwarem companionu 13 nebo novějším.';

  @override
  String get imageSend_directMessagesUnsupported =>
      'Obrázky se přenášejí jako skupinová data, takže je lze odeslat jen do kanálu — ne v přímé zprávě.';

  @override
  String get imageSend_tooLarge =>
      'Tento obrázek se zakódoval do více paketů, než formát meshe umožňuje.';

  @override
  String imageSend_sentConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paketech',
      many: 'paketech',
      few: 'paketech',
      one: 'paketu',
    );
    return 'Obrázek odeslán v $count $_temp0.';
  }

  @override
  String imageSend_sendFailed(String error) {
    return 'Obrázek se nepodařilo odeslat: $error';
  }

  @override
  String imageSend_sendingProgress(int sent, int total) {
    return 'Odesílání obrázku — paket $sent z $total';
  }

  @override
  String receivedImage_senderPrefix(String prefix) {
    return 'Uzel $prefix';
  }

  @override
  String receivedImage_incoming(int received, int total) {
    return '$received z $total paketů';
  }

  @override
  String get receivedImage_queued => 'Čeká na dekódování';

  @override
  String get receivedImage_tapToDecode => 'Klepnutím dekódovat';

  @override
  String get receivedImage_decoding => 'Rekonstrukce… asi 1 s';

  @override
  String receivedImage_incomplete(int received, int total) {
    return 'Obrázek neúplný — dorazilo $received z $total paketů';
  }

  @override
  String get receivedImage_corrupt => 'Obrázek se nepodařilo zrekonstruovat';

  @override
  String get receivedImage_decoderMissing =>
      'Obrázek přijat — dekódování obrázků je vypnuto';

  @override
  String get receivedImage_evicted => 'Obrázek již není uložen';

  @override
  String get receivedImage_retry => 'Zkusit znovu';

  @override
  String get receivedImage_decodeAgain => 'Dekódovat znovu';

  @override
  String get receivedImage_openSettings => 'Nastavit';

  @override
  String get receivedImage_tapToProcess => 'Klepnutím zpracovat';

  @override
  String get receivedImage_save => 'Uložit obrázek';

  @override
  String receivedImage_shareCaption(int bytes) {
    return 'Rekonstruováno AI z $bytes bajtů; jemné detaily jsou vygenerovány, nikoli přeneseny.';
  }

  @override
  String get receivedImage_syntheticBadge => 'Rekonstruováno AI';

  @override
  String get receivedImage_packetInfo => 'Informace o paketech';

  @override
  String get receivedImage_parityRecovered =>
      'Jeden paket byl obnoven ze záchranného paketu.';

  @override
  String receivedImage_decodeTime(int ms) {
    return 'Zrekonstruováno za $ms ms';
  }

  @override
  String get receivedImage_saveFailed => 'Obrázek se nepodařilo uložit';

  @override
  String receivedImage_awaiting(int bytes, int packets) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: 'paketů',
      many: 'paketu',
      few: 'pakety',
      one: 'paket',
    );
    return '$bytes bajtů · $packets $_temp0';
  }

  @override
  String imageSend_secondsValue(String seconds) {
    return '$seconds s';
  }

  @override
  String imageSend_minutesSecondsValue(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String chat_longMessageRetryNote(int count) {
    return 'Nad 158 bajtů: odesláno nejvýše $count×';
  }

  @override
  String get reviewMode_dialogTitle => 'Vstoupit do režimu kontroly?';

  @override
  String get reviewMode_dialogBody =>
      'Režim kontroly se připojí k simulovanému rádiu s ukázkovými kontakty, kanály a zprávami. Skutečné rádio není potřeba.';

  @override
  String get reviewMode_confirm => 'Vstoupit';

  @override
  String get reviewMode_cancel => 'Zrušit';

  @override
  String get reviewMode_banner => 'Režim kontroly — simulovaná data';

  @override
  String get reviewMode_sendTest => 'Odeslat zkušební zprávu';

  @override
  String get reviewMode_testSent => 'Zkušební zpráva brzy dorazí.';

  @override
  String get reviewMode_exit => 'Ukončit';

  @override
  String reviewMode_connectFailed(String error) {
    return 'Režim kontroly se nepodařilo spustit: $error';
  }

  @override
  String get channels_waitForSync =>
      'Kanály se stále načítají z rádia. Zkuste to znovu po dokončení synchronizace.';

  @override
  String channels_nameTooLong(int maxBytes) {
    return 'Název je příliš dlouhý (max. $maxBytes bajtů).';
  }

  @override
  String repeater_valueRequired(String field) {
    return '$field: zadejte hodnotu';
  }

  @override
  String get repeater_floodMaxAdvert => 'Max. skoků flood adventu';

  @override
  String get repeater_floodMaxAdvertHelper =>
      'Maximální počet skoků, které může flood advert urazit (0–64, výchozí 8)';

  @override
  String get repeater_floodMaxUnscoped => 'Max. skoků flood bez oblasti';

  @override
  String get repeater_floodMaxUnscopedHelper =>
      'Maximální počet skoků pro flood bez omezení na oblast (0–64, výchozí 64). Nízká hodnota, například 3, udrží provoz bez oblasti lokální.';

  @override
  String get repeater_floodMaxUnscopedUnset => 'Stejné jako max. flood';

  @override
  String get repeater_rxDelay => 'Zpoždění příjmu';

  @override
  String get repeater_rxDelayHelper =>
      'Zadrží flood pakety slyšené se slabým signálem před přeposláním, takže cesty se silným signálem jdou první a odešle se méně duplikátů (0–20, 0 to vypne).';

  @override
  String get repeater_cad => 'Detekce aktivity kanálu';

  @override
  String get repeater_cadHelper =>
      'Před vysíláním poslouchat aktivitu a čekat, dokud je kanál obsazen. Funguje spolu s prahem rušení.';

  @override
  String get repeater_adcMultiplier => 'Kalibrace napětí baterie';

  @override
  String get repeater_adcMultiplierHelper =>
      'Násobitel pro čtení napětí baterie (0–10). 0 použije výchozí hodnotu desky.';

  @override
  String get repeater_boardSupportNote =>
      'Ne každá deska to podporuje. Nepodporované desky změnu odmítnou.';

  @override
  String get repeater_extraSf => 'Další spreading faktory';

  @override
  String get repeater_extraSfHelper =>
      'Až 3 další spreading faktory, na kterých se současně poslouchá, oddělené čárkami (například 9,10). Prázdné pole to vypne.';

  @override
  String get repeater_lr2021Only =>
      'Pouze pro opakovače s rádiem LR2021. Ostatní opakovače toto nastavení nemají a odmítnou je.';

  @override
  String get losMapDetailTooltip => 'Detail mapy';

  @override
  String get losUnitsTooltip => 'Jednotky';

  @override
  String get losDistance => 'Vzdálenost';

  @override
  String get losClearance => 'Volný prostor';

  @override
  String get losBlockedBy => 'Blokováno';

  @override
  String get losObstruction => 'Překážka';

  @override
  String losDistanceFromA(String distance) {
    return '$distance od A';
  }

  @override
  String get losWorstBadge => 'NEJHORŠÍ';

  @override
  String losBlockedAmount(String amount) {
    return 'Blokováno $amount';
  }

  @override
  String get losFromA => 'Od A';

  @override
  String get losFromB => 'Od B';

  @override
  String get losElevation => 'Nadmořská výška';

  @override
  String get losCenterOnMap => 'Vycentrovat na mapě';

  @override
  String get losStatusClear => 'Volno';

  @override
  String get losStatusMarginal => 'Hraniční';

  @override
  String get losStatusBlocked => 'Blokováno';

  @override
  String get losStatusCheckingShort => 'Kontrola';

  @override
  String get losStatusNoResult => 'Bez výsledku';

  @override
  String get losSelectedPill => 'Vybráno';

  @override
  String get gif_tapToLoad => 'Klepnutím načíst GIF';

  @override
  String get gif_loadFailedRetry =>
      'GIF nelze načíst\nKlepnutím to zkusit znovu';

  @override
  String get qr_cameraPermissionDenied =>
      'Přístup ke kameře byl zamítnut.\nPovolte přístup ke kameře v nastavení.';

  @override
  String get qr_cameraUnsupported =>
      'Kamera není na tomto zařízení podporována.';

  @override
  String qr_cameraStartFailed(String details) {
    return 'Kameru se nepodařilo spustit.\n$details';
  }

  @override
  String imageMessages_downloadFailedWithError(String error) {
    return 'Model obrázků se nepodařilo stáhnout: $error';
  }

  @override
  String get map_nodeId => 'ID';

  @override
  String get map_markerHideHint => 'Skrýt: skryto, dokud neopustíte mapu.';

  @override
  String get map_markerRemoveHint =>
      'Odebrat: zůstane skryto, dokud jej neobnovíte z nabídky filtru.';

  @override
  String get map_markerRemoved => 'Značka odebrána';

  @override
  String get map_restoreRemovedMarkers => 'Obnovit odebrané značky';

  @override
  String map_restoreRemovedMarkersSubtitle(int count) {
    return 'Odebráno: $count';
  }

  @override
  String map_markersRestored(int count) {
    return 'Obnoveno značek: $count';
  }

  @override
  String get map_setLocationConfirmTitle => 'Nastavit jako vaši polohu?';

  @override
  String map_setLocationConfirmBody(String lat, String lon) {
    return 'Váš uzel bude vysílat tuto pozici:\n$lat, $lon';
  }

  @override
  String get map_setLocationAction => 'Nastavit polohu';

  @override
  String get map_locationSetSuccess => 'Poloha uzlu aktualizována';

  @override
  String get map_locationSetFailed =>
      'Zařízení nepotvrdilo novou polohu. Zkuste to znovu.';

  @override
  String map_poiClusterTitle(int count) {
    return 'Značky zde: $count';
  }

  @override
  String map_poiClusterSemantics(int count) {
    return 'Sdílených značek: $count. Klepnutím je zobrazíte.';
  }

  @override
  String map_youWithMarkers(int count) {
    return 'Vy a značky: $count';
  }

  @override
  String map_sharedMarkerSemantics(String label) {
    return 'Sdílená značka: $label';
  }

  @override
  String map_nodeMarkerSemantics(String name, String type, String status) {
    return '$name, $type, $status';
  }

  @override
  String get map_requestLocation => 'Aktualizovat polohu';

  @override
  String get map_locationUpdated => 'Poloha aktualizována';

  @override
  String map_locationNotShared(String name) {
    return '$name odpověděl bez polohy';
  }

  @override
  String map_locationRequestFailed(String name) {
    return 'Žádná odpověď od $name';
  }

  @override
  String mapCache_zoomLevel(int zoom) {
    return 'Zoom $zoom';
  }

  @override
  String mapCache_sizeBytes(String size) {
    return '$size B';
  }

  @override
  String mapCache_sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String mapCache_sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String mapCache_sizeGigabytes(String size) {
    return '$size GB';
  }

  @override
  String mapCache_downloadCancelled(int count) {
    return 'Stahování zrušeno. Uloženo do mezipaměti dlaždic: $count.';
  }

  @override
  String get mapCache_tooManyTilesTitle => 'Oblast je příliš velká';

  @override
  String mapCache_tooManyTiles(int count, int max) {
    return 'Tato oblast vyžaduje $count dlaždic, což je více než limit $max. Vyberte menší oblast nebo snižte maximální zoom.';
  }

  @override
  String get chat_clearChatConfirm =>
      'Tím se z tohoto zařízení vymažou všechny zprávy v této konverzaci. Nelze vrátit zpět.';

  @override
  String get channels_clearChatConfirm =>
      'Tím se z tohoto zařízení vymažou všechny zprávy v tomto kanálu včetně přijatých obrázků. Nelze vrátit zpět.';

  @override
  String get channels_timeNow => 'nyní';

  @override
  String channels_timeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String channels_timeHours(int hours) {
    return '$hours h';
  }

  @override
  String channels_timeDays(int days) {
    return '$days d';
  }

  @override
  String channels_indexChip(int index) {
    return 'CH $index';
  }

  @override
  String get reaction_unknownSender => 'Neznámý';

  @override
  String get pathMap_noSelfGpsFix => 'Místní uzel nemá GPS fix';

  @override
  String pathTrace_sendFailed(String error) {
    return 'Trasování cesty se nepodařilo odeslat: $error';
  }

  @override
  String get losErrorNoInternet =>
      'Data o nadmořské výšce vyžadují připojení k internetu';

  @override
  String get losResultStale => 'Zastaralé: výška antény se změnila';

  @override
  String losSnrValue(String snr) {
    return '$snr dB';
  }

  @override
  String losFrequencyValue(String frequency) {
    return '$frequency MHz';
  }

  @override
  String losKFactorValue(String kFactor) {
    return 'k=$kFactor';
  }

  @override
  String get losEndpointA => 'A';

  @override
  String get losEndpointB => 'B';

  @override
  String get units_km => 'km';

  @override
  String get units_mi => 'mi';

  @override
  String get units_m => 'm';

  @override
  String get units_ft => 'ft';

  @override
  String get telemetry_loading => 'Načítání telemetrie…';

  @override
  String telemetry_axisValue(String x, String y, String z) {
    return 'X: $x, Y: $y, Z: $z';
  }

  @override
  String telemetry_colourValue(String red, String green, String blue) {
    return 'R: $red, G: $green, B: $blue';
  }

  @override
  String telemetry_altitudeValueFeet(String feet) {
    return '$feet ft';
  }

  @override
  String telemetry_distanceValueFeet(String feet) {
    return '$feet ft';
  }

  @override
  String get settings_notConnectedError =>
      'Nepřipojeno k rádiu. Připojte se a zkuste to znovu.';

  @override
  String get settings_requiresConnection => 'Pro použití se připojte k rádiu';

  @override
  String settings_txPowerInvalidRange(int min, int max) {
    return 'Neplatný výkon TX ($min až $max dBm)';
  }

  @override
  String get settings_contactSettingsSaved => 'Nastavení kontaktu uloženo';

  @override
  String get settings_batteryToggleHint =>
      'Klepnutím přepnete mezi procenty a napětím';

  @override
  String get settings_publicKeyCopyHint => 'Zkopírovat veřejný klíč';

  @override
  String get settings_locationClearHelper =>
      'Chcete-li polohu odstranit, nechte obě pole prázdná.';

  @override
  String get settings_locationCleared => 'Poloha odstraněna';

  @override
  String get settings_regionFetchDiscovering => 'Hledání opakovačů v okolí…';

  @override
  String settings_regionFetchProgress(int current, int total) {
    return 'Dotaz na opakovač $current z $total…';
  }

  @override
  String get settings_regionFetchNoRepeaters =>
      'Zatím nejsou známy žádné opakovače. Přidejte opakovač jako kontakt nebo počkejte, až nějaký vyšle advert, a zkuste to znovu.';

  @override
  String get settings_regionFetchNoneResponded =>
      'Žádný opakovač v okolí neodpověděl. Přibližte se k opakovači a zkuste to znovu.';

  @override
  String appSettings_sourceSummary(String label, String description) {
    return '$label - $description';
  }

  @override
  String get appSettings_routingSection => 'Směrování';

  @override
  String get appSettings_resetRoutingToDefault =>
      'Obnovit výchozí směrovací algoritmus';

  @override
  String get appSettings_resetRoutingToDefaultSubtitle =>
      'Obnovit nastavení směrovacího algoritmu na tovární hodnoty';

  @override
  String get appSettings_routingResetToDefault =>
      'Nastavení směrovacího algoritmu obnoveno na výchozí';

  @override
  String get appSettings_imageMessagesSection => 'Obrázkové zprávy';

  @override
  String get appSettings_showApiKey => 'Zobrazit klíč API';

  @override
  String get appSettings_hideApiKey => 'Skrýt klíč API';

  @override
  String get translation_defaultModelName => 'Model';

  @override
  String translation_downloadProgressBytes(String fileName, String current) {
    return '$fileName: $current MB';
  }

  @override
  String translation_downloadProgressTotal(
    String fileName,
    String current,
    String total,
    String percent,
  ) {
    return '$fileName: $current / $total MB ($percent %)';
  }

  @override
  String translation_downloadedModelDetails(String size, String source) {
    return '$size MB • $source';
  }

  @override
  String get repeater_radioDisconnected => 'Rádio odpojeno';

  @override
  String get repeater_radioDisconnectedHint =>
      'Pro odesílání příkazů, obnovení nebo uložení změn se znovu připojte k rádiu.';

  @override
  String get repeater_cliSend => 'Odeslat příkaz';

  @override
  String get repeater_cliCopyTranscript => 'Kopírovat přepis';

  @override
  String get repeater_cliShareTranscript => 'Sdílet přepis';

  @override
  String get repeater_cliTranscriptCopied => 'Přepis zkopírován';

  @override
  String get repeater_cliClearHistoryConfirm =>
      'Vymazat historii příkazů? Nelze vrátit zpět.';

  @override
  String get repeater_cliSearchCommands => 'Hledat příkazy';

  @override
  String get repeater_cliNoMatchingCommands => 'Žádné odpovídající příkazy';

  @override
  String get debugLog_clearConfirm =>
      'Vymazat všechny záznamy protokolu? Nelze vrátit zpět.';

  @override
  String get repeater_unsavedChangesTitle => 'Neuložené změny';

  @override
  String get repeater_unsavedChangesMessage =>
      'Máte změny, které nebyly uloženy do opakovače.';

  @override
  String get repeater_discardChanges => 'Zahodit';

  @override
  String repeater_actionSentNoReply(String action) {
    return '$action: příkaz odeslán. Opakovač na tento příkaz neodpovídá.';
  }

  @override
  String repeater_invalidSettingValue(String setting, String value) {
    return '$setting: $value není platné';
  }

  @override
  String repeater_prvKeyLengthError(int length) {
    return 'Soukromý klíč musí mít přesně $length hex znaků';
  }

  @override
  String get contacts_advertFailed => 'Advert se nepodařilo odeslat';

  @override
  String get contacts_manageGroups => 'Spravovat skupiny';

  @override
  String contacts_keyPrefixSemantics(String prefix) {
    return 'Prefix klíče $prefix';
  }

  @override
  String community_shortId(String id) {
    return 'ID: $id…';
  }

  @override
  String get tcpSectionTitle => 'TCP / IP';

  @override
  String get tcpConnectedToHeader => 'Připojeno k';

  @override
  String get usbChooseSerialPort => 'Vyberte sériový port';

  @override
  String neighbors_durationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String neighbors_durationMinutes(int minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String neighbors_durationHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get networkMap_settingsSection => 'Síťová mapa';

  @override
  String get networkMap_uploadTitle => 'Sdílet, co moje rádio slyší';

  @override
  String get networkMap_uploadExplanation =>
      'Když je to zapnuto a vaše rádio je připojeno, aplikace odesílá na síťovou mapu MeshCore Open stručný souhrn paketů, které vaše rádio slyší, aby všichni viděli, jaké opakovače existují a jak jsou propojeny. Odesílá typ každého paketu, trasu, skoky, sílu signálu a velikost, plus názvy opakovačů a přibližné polohy z jejich vlastních advertů. Nikdy neodesílá text zpráv, kdo s kým komunikuje, názvy kanálů, vaše kontakty ani vaši přesnou polohu: polohy jsou zaokrouhleny na asi 2 km a vaše aplikace dostává každý den nové náhodné ID.';

  @override
  String get networkMap_whatWeCollect => 'Co shromažďujeme';

  @override
  String get networkMap_promptTitle => 'Pomoci vytvářet síťovou mapu?';

  @override
  String get networkMap_promptBody =>
      'MeshCore Open může sdílet, co vaše rádio slyší, s veřejnou síťovou mapou na map.meshcoreopen.org, aby všichni viděli, jaké opakovače existují a jak jsou propojeny.\n\nNikdy neodesílá text zpráv, kdo s kým komunikuje, názvy kanálů, vaše kontakty ani vaši přesnou polohu. Polohy jsou zaokrouhleny na asi 2 km.';

  @override
  String get networkMap_promptSettingsHint =>
      'Můžete to kdykoli změnit v Nastavení → Nastavení aplikace → Síťová mapa.';

  @override
  String get networkMap_promptAccept => 'Sdílet';

  @override
  String get networkMap_promptDecline => 'Ne, děkuji';

  @override
  String get networkMap_statusOff => 'Vypnuto. Nic se neodesílá.';

  @override
  String get networkMap_statusWaiting => 'Zapnuto. Čekání na připojení rádia.';

  @override
  String get networkMap_statusNothingSent => 'Zapnuto. Zatím nic neodesláno.';

  @override
  String networkMap_statusLastSent(String time, int count) {
    return 'Naposledy odesláno $time. Dnes paketů: $count.';
  }

  @override
  String get networkMap_sourceLocal => 'Místní';

  @override
  String get networkMap_sourceOnline => 'Online';

  @override
  String get networkMap_sourceBoth => 'Obojí';

  @override
  String get networkMap_sourceLocalHint => 'Uzly, které vaše rádio slyšelo';

  @override
  String get networkMap_sourceOnlineHint => 'Opakovače z online síťové mapy';

  @override
  String get networkMap_sourceBothHint =>
      'Uzly vašeho rádia plus online síťová mapa';

  @override
  String get networkMap_zoomInHint =>
      'Přibližte pro zobrazení online síťové mapy';

  @override
  String get networkMap_loadFailed =>
      'Online síťovou mapu se nepodařilo načíst';

  @override
  String get networkMap_inYourContacts => 'Ve vašich kontaktech';

  @override
  String get networkMap_status => 'Stav';

  @override
  String get networkMap_statusActive => 'Aktivní za poslední hodinu';

  @override
  String get networkMap_statusRecent => 'Slyšen za poslední den';

  @override
  String get networkMap_statusStale => 'Nedávno neslyšen';

  @override
  String get networkMap_confirmed => 'Potvrzeno';

  @override
  String get networkMap_singleSource => 'Jediný zdroj, zatím nepotvrzeno';

  @override
  String get networkMap_reports => 'Hlášení';

  @override
  String get networkMap_locationEstimated =>
      'Přibližná poloha, odhadnutá podle toho, kdo jej slyšel';

  @override
  String get networkMap_locationAdvertised =>
      'Přibližná poloha, z jeho vlastního advertu';

  @override
  String get networkMap_heardByRadio => 'Slyšen vaším rádiem';

  @override
  String get networkMap_inYourArea => 'Ve vašem okolí';

  @override
  String get networkMap_farAway => 'Daleko. Správa na něj nedosáhne.';

  @override
  String get networkMap_addToContacts => 'Přidat do kontaktů';

  @override
  String get networkMap_manage => 'Spravovat';

  @override
  String get networkMap_addedToContacts => 'Přidáno do kontaktů';

  @override
  String get networkMap_addFailed => 'Přidání do kontaktů se nezdařilo';

  @override
  String get networkMap_unnamed => 'Nepojmenovaný opakovač';

  @override
  String get holidayGreeting_halloween => 'Veselé Halloween';

  @override
  String get holidayGreeting_thanksgiving => 'Šťastný Den díkůvzdání';

  @override
  String get holidayGreeting_christmas =>
      'Veselé Vánoce|Šťastné Vánoce|Krásné Vánoce';

  @override
  String get holidayGreeting_newYear =>
      'Šťastný nový rok|Hodně štěstí do nového roku';

  @override
  String get chat_loadOlderMessages => 'Načíst starší zprávy';

  @override
  String get messageFilter_title => 'Filtr zpráv';

  @override
  String get messageFilter_settingsSubtitle => 'Skrýt spam a opakované zprávy';

  @override
  String get messageFilter_enabled => 'Filtrovat zprávy';

  @override
  String get messageFilter_enabledSubtitle => 'Platí pro zprávy v kanálech';

  @override
  String get messageFilter_displayTitle => 'Filtrované zprávy';

  @override
  String get messageFilter_displayPlaceholder => 'Zobrazit malého zástupce';

  @override
  String get messageFilter_displayHide => 'Skrýt úplně';

  @override
  String get messageFilter_displayHideHelp =>
      'Skryté zprávy zůstanou v seznamu Filtrované zprávy.';

  @override
  String get messageFilter_rulesSection => 'Vaše pravidla';

  @override
  String get messageFilter_rulesEmpty =>
      'Zatím žádná pravidla. Přidejte slovo, frázi nebo jméno odesílatele a odpovídající zprávy budou skryty.';

  @override
  String get messageFilter_addRule => 'Přidat pravidlo';

  @override
  String get messageFilter_editRule => 'Upravit pravidlo';

  @override
  String get messageFilter_rulePattern => 'Slovo, fráze nebo jméno';

  @override
  String get messageFilter_rulePatternHint => 'např. meshos';

  @override
  String get messageFilter_ruleWhere => 'Hledat v';

  @override
  String get messageFilter_ruleFieldText => 'Text zprávy';

  @override
  String get messageFilter_ruleFieldSender => 'Jméno odesílatele';

  @override
  String get messageFilter_ruleFieldBoth => 'Obojí';

  @override
  String get messageFilter_ruleMatch => 'Shoda';

  @override
  String get messageFilter_ruleMatchContains => 'Obsahuje';

  @override
  String get messageFilter_ruleMatchWholeWord => 'Celé slovo';

  @override
  String get messageFilter_ruleMatchExact => 'Přesná shoda';

  @override
  String get messageFilter_ruleDeleted => 'Pravidlo smazáno';

  @override
  String get messageFilter_ruleSaved => 'Pravidlo uloženo';

  @override
  String get messageFilter_automaticSection => 'Automatické';

  @override
  String get messageFilter_duplicates => 'Opakované zprávy';

  @override
  String get messageFilter_duplicatesSubtitle =>
      'Stejná zpráva odeslaná znovu nebo více odesílateli';

  @override
  String get messageFilter_repeatSends => 'Počet odeslání pro opakování';

  @override
  String messageFilter_repeatSendsSubtitle(int count) {
    return 'Skrýt zprávu, když ji stejný odesílatel odešle $count× během 10 minut';
  }

  @override
  String get messageFilter_repeatedCharacters => 'Opakované znaky';

  @override
  String get messageFilter_repeatedCharactersSubtitle =>
      'Dlouhé řady jednoho znaku, například \"aaaaaaaaaaaaaaaaaaaa\"';

  @override
  String get messageFilter_learning => 'Učit se z klepnutí na Spam';

  @override
  String messageFilter_learningSubtitle(int spam, int notSpam) {
    return 'Příkladů spamu: $spam, příkladů ne-spamu: $notSpam';
  }

  @override
  String get messageFilter_resetLearning => 'Obnovit učení';

  @override
  String get messageFilter_resetLearningConfirm =>
      'Zapomenout vše, co se naučilo z vašich klepnutí na Spam a Není spam? Vaše pravidla zůstanou zachována.';

  @override
  String messageFilter_filteredMessages(int count) {
    return 'Filtrované zprávy ($count)';
  }

  @override
  String get messageFilter_filteredMessagesEmpty => 'Nic nebylo odfiltrováno.';

  @override
  String get messageFilter_ghostSingle => 'Skrytá zpráva · Klepnutím zobrazit';

  @override
  String messageFilter_ghostMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skrytých zpráv · Klepnutím zobrazit',
      many: '$count skryté zprávy · Klepnutím zobrazit',
      few: '$count skryté zprávy · Klepnutím zobrazit',
      one: '$count skrytá zpráva · Klepnutím zobrazit',
    );
    return '$_temp0';
  }

  @override
  String get messageFilter_ghostSingleExpanded =>
      'Zobrazena skrytá zpráva · Klepnutím skrýt';

  @override
  String messageFilter_ghostManyExpanded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobrazeno $count skrytých zpráv · Klepnutím skrýt',
      many: 'Zobrazeno $count skryté zprávy · Klepnutím skrýt',
      few: 'Zobrazeny $count skryté zprávy · Klepnutím skrýt',
      one: 'Zobrazena 1 skrytá zpráva · Klepnutím skrýt',
    );
    return '$_temp0';
  }

  @override
  String messageFilter_reasonTextRule(String pattern) {
    return 'Odfiltrováno: odpovídá \"$pattern\"';
  }

  @override
  String messageFilter_reasonSenderRule(String pattern) {
    return 'Odfiltrováno: odesílatel \"$pattern\"';
  }

  @override
  String get messageFilter_reasonRepeatedCharacters =>
      'Odfiltrováno: opakované znaky';

  @override
  String get messageFilter_reasonDuplicate => 'Odfiltrováno: opakovaná zpráva';

  @override
  String get messageFilter_reasonCrossSenderDuplicate =>
      'Odfiltrováno: stejná zpráva od více odesílatelů';

  @override
  String get messageFilter_reasonLearned =>
      'Odfiltrováno: vypadá jako zprávy, které jste označili jako spam';

  @override
  String get messageFilter_reasonManual =>
      'Odfiltrováno: označili jste to jako spam';

  @override
  String get messageFilter_notSpam => 'Není spam';

  @override
  String get messageFilter_hideAgain => 'Skrýt';

  @override
  String get messageFilter_markSpam => 'Označit jako spam';

  @override
  String get messageFilter_markedSpam => 'Označeno jako spam';

  @override
  String get messageFilter_markedNotSpam => 'Označeno jako ne-spam';

  @override
  String get messageFilter_filterSender => 'Filtrovat tohoto odesílatele';

  @override
  String messageFilter_filterSenderConfirm(String name) {
    return 'Skrýt všechny zprávy od \"$name\"?';
  }

  @override
  String get messageFilter_filterLikeThis => 'Filtrovat podobné zprávy…';

  @override
  String get messageFilter_channelToggle => 'Filtrovat zprávy v tomto kanálu';

  @override
  String get messageFilter_ghostIconTooltip => 'Skryto vaším filtrem zpráv';

  @override
  String appBar_offlineSubtitle(String name) {
    return 'Offline · $name';
  }

  @override
  String get appBar_offline => 'Offline';

  @override
  String get appBar_reconnecting => 'Připojování…';

  @override
  String get connectSheet_title => 'Připojit rádio';

  @override
  String connectSheet_reconnect(String name) {
    return 'Znovu se připojit k $name';
  }

  @override
  String get connectSheet_chooseRadio => 'Vybrat rádio';

  @override
  String get connectSheet_chooseRadioSubtitle => 'Bluetooth, USB nebo TCP';

  @override
  String get connectSheet_stopReconnecting => 'Zastavit připojování';

  @override
  String connectSheet_reconnectFailed(String name) {
    return 'Nelze se spojit s $name. Ujistěte se, že je zapnuté a nablízku.';
  }

  @override
  String get chat_composerOffline => 'Pro odesílání zpráv se připojte k rádiu';
}
