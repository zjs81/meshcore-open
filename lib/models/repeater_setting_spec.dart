import '../l10n/app_localizations.dart';

typedef L10nText = String Function(AppLocalizations l10n);

/// Card a setting is drawn in on the repeater settings screen.
enum RepeaterSettingSection {
  basic,
  radio,
  location,
  features,
  networkHealth,
  advertisement,
  ownerInfo,
  advanced,
}

/// The control that edits a setting, which also fixes its value type:
/// toggle -> bool, slider -> num, choice -> String, number/text -> the text
/// of a field.
enum RepeaterSettingInput { toggle, slider, number, choice, text }

class RepeaterSettingChoice {
  final String value;
  final L10nText label;

  const RepeaterSettingChoice(this.value, this.label);
}

/// One repeater CLI setting, read with `get <key>` and written with
/// `set <key> <value>` (see MeshCore CommonCLI.cpp / CommonRadioPrefs.cpp).
///
/// The repeater settings screen builds its controls, refresh buttons and save
/// commands from [repeaterSettingSpecs]; adding a setting there is enough for
/// it to show up, load and save.
class RepeaterSettingSpec {
  final String key;
  final RepeaterSettingSection section;
  final RepeaterSettingInput input;
  final L10nText label;
  final L10nText? helper;

  /// Availability caveat (hardware or build specific), shown under the
  /// control.
  final L10nText? note;

  // toggle: the words the firmware takes for on and off.
  final String onValue;
  final String offValue;

  // slider and number: accepted range, and the slider's step.
  final num? min;
  final num? max;
  final num step;

  /// number: accept a decimal point.
  final bool decimal;

  /// slider: value that means "disabled". Adds an on/off switch; turning it
  /// on starts at [min].
  final num? offAt;

  /// slider: how a value is shown, e.g. "120 minutes".
  final String Function(AppLocalizations l10n, num value)? valueLabel;

  /// slider: firmware values with a meaning of their own, outside the range.
  final Map<num, L10nText> specialValues;

  // choice
  final List<RepeaterSettingChoice> choices;

  // text
  final int? maxBytes;
  final bool multiline;

  /// text: an empty value is rejected instead of sent.
  final bool required;

  /// text: maps the edited text to the firmware form and back.
  final String Function(String text)? encode;
  final String Function(String value)? decode;

  /// text: extra check before sending.
  final bool Function(String text)? validate;

  /// Turns the full `get` reply into a value, for replies without the usual
  /// "> " prefix. Returns null when the reply is not a value.
  final String? Function(String reply)? parseRawReply;

  const RepeaterSettingSpec({
    required this.key,
    required this.section,
    required this.input,
    required this.label,
    this.helper,
    this.note,
    this.onValue = 'on',
    this.offValue = 'off',
    this.min,
    this.max,
    this.step = 1,
    this.decimal = false,
    this.offAt,
    this.valueLabel,
    this.specialValues = const {},
    this.choices = const [],
    this.maxBytes,
    this.multiline = false,
    this.required = false,
    this.encode,
    this.decode,
    this.validate,
    this.parseRawReply,
  });

  bool get isInteger => !decimal && step is int;

  /// Whether [value] is a number inside [min]..[max].
  bool inRange(num value) =>
      (min == null || value >= min!) && (max == null || value <= max!);
}

/// `get extra.sf` answers "8,9" without the "> " prefix, or
/// "No extra SF configured".
String? _parseExtraSfReply(String reply) {
  final text = reply.trim();
  if (text.startsWith('No extra SF')) return '';
  return RegExp(r'^\d+(,\d+)*$').hasMatch(text) ? text : null;
}

/// Up to 3 comma-separated spreading factors (5-12); empty clears them.
bool _isValidExtraSf(String text) {
  final trimmed = text.replaceAll(' ', '');
  if (trimmed.isEmpty) return true;
  final parts = trimmed.split(',');
  if (parts.length > 3) return false;
  return parts.every((p) {
    final sf = int.tryParse(p);
    return sf != null && sf >= 5 && sf <= 12;
  });
}

String _hops(AppLocalizations l10n, num v) => '$v';

/// Every repeater setting the screen edits through the generic controls, in
/// display order within each section. The radio parameters (one bundled
/// `set radio` command), passwords and private key stay hand-built.
final List<RepeaterSettingSpec> repeaterSettingSpecs = [
  // Basic
  RepeaterSettingSpec(
    key: 'name',
    section: RepeaterSettingSection.basic,
    input: RepeaterSettingInput.text,
    label: (l) => l.repeater_repeaterName,
    helper: (l) => l.repeater_repeaterNameHelper,
    maxBytes: 31, // node_name[32]
    required: true,
  ),

  // Radio
  RepeaterSettingSpec(
    key: 'tx',
    section: RepeaterSettingSection.radio,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_txPower,
    helper: (l) => l.repeater_txPowerRangeHelper,
    min: -9,
    max: 30,
  ),
  RepeaterSettingSpec(
    key: 'radio.rxgain',
    section: RepeaterSettingSection.radio,
    input: RepeaterSettingInput.toggle,
    label: (l) => l.repeater_rxGain,
    helper: (l) => l.repeater_rxGainHelper,
  ),

  // Location
  RepeaterSettingSpec(
    key: 'lat',
    section: RepeaterSettingSection.location,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_latitude,
    helper: (l) => l.repeater_latitudeHelper,
    min: -90,
    max: 90,
    decimal: true,
  ),
  RepeaterSettingSpec(
    key: 'lon',
    section: RepeaterSettingSection.location,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_longitude,
    helper: (l) => l.repeater_longitudeHelper,
    min: -180,
    max: 180,
    decimal: true,
  ),

  // Features
  RepeaterSettingSpec(
    key: 'repeat',
    section: RepeaterSettingSection.features,
    input: RepeaterSettingInput.toggle,
    label: (l) => l.repeater_packetForwarding,
    helper: (l) => l.repeater_packetForwardingSubtitle,
  ),
  RepeaterSettingSpec(
    key: 'allow.read.only',
    section: RepeaterSettingSection.features,
    input: RepeaterSettingInput.toggle,
    label: (l) => l.repeater_guestAccess,
    helper: (l) => l.repeater_guestAccessSubtitle,
  ),
  RepeaterSettingSpec(
    key: 'multi.acks',
    section: RepeaterSettingSection.features,
    input: RepeaterSettingInput.toggle,
    label: (l) => l.repeater_multiAcks,
    helper: (l) => l.repeater_multiAcksSubtitle,
    onValue: '1',
    offValue: '0',
  ),

  // Network health
  RepeaterSettingSpec(
    key: 'loop.detect',
    section: RepeaterSettingSection.networkHealth,
    input: RepeaterSettingInput.choice,
    label: (l) => l.repeater_loopDetect,
    helper: (l) => l.repeater_loopDetectHelper,
    choices: [
      RepeaterSettingChoice('off', (l) => l.repeater_loopDetectOff),
      RepeaterSettingChoice('minimal', (l) => l.repeater_loopDetectMinimal),
      RepeaterSettingChoice('moderate', (l) => l.repeater_loopDetectModerate),
      RepeaterSettingChoice('strict', (l) => l.repeater_loopDetectStrict),
    ],
  ),
  RepeaterSettingSpec(
    key: 'dutycycle',
    section: RepeaterSettingSection.networkHealth,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_dutyCycle,
    helper: (l) => l.repeater_dutyCycleHelper,
    min: 1,
    max: 100,
    valueLabel: (l, v) => l.repeater_dutyCyclePercent(v.toInt()),
  ),
  RepeaterSettingSpec(
    key: 'rxdelay',
    section: RepeaterSettingSection.networkHealth,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_rxDelay,
    helper: (l) => l.repeater_rxDelayHelper,
    min: 0,
    max: 20,
    decimal: true,
  ),

  // Advertisement
  RepeaterSettingSpec(
    key: 'advert.interval',
    section: RepeaterSettingSection.advertisement,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_localAdvertInterval,
    min: 60, // MIN_LOCAL_ADVERT_INTERVAL
    max: 240,
    step: 10,
    offAt: 0,
    valueLabel: (l, v) => l.repeater_localAdvertIntervalMinutes(v.toInt()),
  ),
  RepeaterSettingSpec(
    key: 'flood.advert.interval',
    section: RepeaterSettingSection.advertisement,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_floodAdvertInterval,
    min: 3,
    max: 168,
    offAt: 0,
    valueLabel: (l, v) => l.repeater_floodAdvertIntervalHours(v.toInt()),
  ),
  RepeaterSettingSpec(
    key: 'flood.max',
    section: RepeaterSettingSection.advertisement,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_floodMax,
    helper: (l) => l.repeater_floodMaxHelper,
    min: 0,
    max: 64,
    valueLabel: _hops,
  ),
  RepeaterSettingSpec(
    key: 'flood.max.advert',
    section: RepeaterSettingSection.advertisement,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_floodMaxAdvert,
    helper: (l) => l.repeater_floodMaxAdvertHelper,
    min: 0,
    max: 64,
    valueLabel: _hops,
  ),
  RepeaterSettingSpec(
    key: 'flood.max.unscoped',
    section: RepeaterSettingSection.advertisement,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_floodMaxUnscoped,
    helper: (l) => l.repeater_floodMaxUnscopedHelper,
    min: 0,
    max: 64,
    valueLabel: _hops,
    // 0xFF: never set, so it follows flood.max.
    specialValues: {255: (l) => l.repeater_floodMaxUnscopedUnset},
  ),

  // Operator info
  RepeaterSettingSpec(
    key: 'owner.info',
    section: RepeaterSettingSection.ownerInfo,
    input: RepeaterSettingInput.text,
    label: (l) => l.repeater_ownerInfo,
    helper: (l) => l.repeater_ownerInfoHelper,
    maxBytes: 119, // owner_info[120]
    multiline: true,
    // Firmware stores '|' as a newline and sends newlines back as '|'.
    encode: (text) => text.replaceAll('\n', '|'),
    decode: (value) => value.replaceAll('|', '\n'),
  ),

  // Advanced
  RepeaterSettingSpec(
    key: 'path.hash.mode',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.choice,
    label: (l) => l.repeater_pathHashMode,
    helper: (l) => l.repeater_pathHashModeHelper,
    choices: [
      RepeaterSettingChoice('0', (l) => l.repeater_pathHashModeOption0),
      RepeaterSettingChoice('1', (l) => l.repeater_pathHashModeOption1),
      RepeaterSettingChoice('2', (l) => l.repeater_pathHashModeOption2),
    ],
  ),
  RepeaterSettingSpec(
    key: 'txdelay',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_txDelay,
    helper: (l) => l.repeater_txDelayHelper,
    min: 0,
    max: 2,
    decimal: true,
  ),
  RepeaterSettingSpec(
    key: 'direct.txdelay',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_directTxDelay,
    helper: (l) => l.repeater_directTxDelayHelper,
    min: 0,
    max: 2,
    decimal: true,
  ),
  RepeaterSettingSpec(
    key: 'int.thresh',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_intThresh,
    helper: (l) => l.repeater_intThreshHelper,
    min: 0,
    max: 255,
  ),
  RepeaterSettingSpec(
    key: 'cad',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.toggle,
    label: (l) => l.repeater_cad,
    helper: (l) => l.repeater_cadHelper,
  ),
  RepeaterSettingSpec(
    key: 'agc.reset.interval',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.slider,
    label: (l) => l.repeater_agcResetInterval,
    helper: (l) => l.repeater_agcResetIntervalHelper,
    min: 0,
    max: 255 * 4,
    step: 4, // firmware rounds down to a multiple of 4
    valueLabel: (l, v) => '${v}s',
  ),
  RepeaterSettingSpec(
    key: 'adc.multiplier',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.number,
    label: (l) => l.repeater_adcMultiplier,
    helper: (l) => l.repeater_adcMultiplierHelper,
    note: (l) => l.repeater_boardSupportNote,
    min: 0,
    max: 10,
    decimal: true,
  ),
  RepeaterSettingSpec(
    key: 'extra.sf',
    section: RepeaterSettingSection.advanced,
    input: RepeaterSettingInput.text,
    label: (l) => l.repeater_extraSf,
    helper: (l) => l.repeater_extraSfHelper,
    note: (l) => l.repeater_lr2021Only,
    encode: (text) => text.replaceAll(' ', ''),
    validate: _isValidExtraSf,
    parseRawReply: _parseExtraSfReply,
  ),
];

final Map<String, RepeaterSettingSpec> repeaterSettingSpecsByKey = {
  for (final spec in repeaterSettingSpecs) spec.key: spec,
};
