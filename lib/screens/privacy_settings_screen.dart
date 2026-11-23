import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/settings_reveal.dart';
import '../widgets/unsaved_changes_guard.dart';

typedef _PrivacyForm = ({
  bool advertLocation,
  bool autoZeroHopAdvert,
  int multiAcks,
  int telemetryBase,
  int telemetryLocation,
  int telemetryEnvironment,
});

/// Location sharing, ACKs and telemetry permissions. Sent on Save.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late bool _advertLocation;
  late bool _autoZeroHopAdvert;
  // Raw value: firmware also accepts 2, kept unless the switch is changed.
  late int _multiAcks;
  late int _telemetryBase;
  late int _telemetryLocation;
  late int _telemetryEnvironment;
  late _PrivacyForm _savedForm;

  @override
  void initState() {
    super.initState();
    final connector = context.read<MeshCoreConnector>();
    _advertLocation = connector.advertLocationPolicy != 0;
    _autoZeroHopAdvert = context
        .read<AppSettingsService>()
        .settings
        .autoSendZeroHopAdvertOnGpsUpdate;
    _multiAcks = connector.multiAcks;
    _telemetryBase = connector.telemetryModeBase;
    _telemetryLocation = connector.telemetryModeLoc;
    _telemetryEnvironment = connector.telemetryModeEnv;
    _savedForm = _form;
  }

  _PrivacyForm get _form => (
    advertLocation: _advertLocation,
    autoZeroHopAdvert: _autoZeroHopAdvert,
    multiAcks: _multiAcks,
    telemetryBase: _telemetryBase,
    telemetryLocation: _telemetryLocation,
    telemetryEnvironment: _telemetryEnvironment,
  );

  Future<bool> _save() async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    final settingsService = context.read<AppSettingsService>();
    final form = _form;
    await connector.setTelemetryModeBase(
      form.telemetryBase,
      form.telemetryLocation,
      form.telemetryEnvironment,
      form.advertLocation ? 1 : 0,
      form.multiAcks,
    );
    await settingsService.setAutoSendZeroHopAdvertOnGpsUpdate(
      form.autoZeroHopAdvert,
    );
    await connector.refreshDeviceInfo();
    if (!mounted) return true;
    setState(() => _savedForm = form);
    showDismissibleSnackBar(
      context,
      content: Text(l10n.settings_telemetryModeUpdated),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const switchPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
    return SaveToRadioPage(
      title: l10n.settings_privacy,
      hasChanges: _form != _savedForm,
      onSave: _save,
      children: [
        const SizedBox(height: 8),
        MeshInfoCard(l10n.settings_privacySettingsDescription),
        SectionHeader(l10n.settings_location),
        MeshCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: switchPadding,
                // Same icon as the Location row in Settings.
                secondary: const Icon(Icons.location_on_outlined, size: 24),
                title: Text(l10n.settings_advertLocation),
                subtitle: Text(l10n.settings_advertLocationSubtitle),
                value: _advertLocation,
                onChanged: (value) => setState(() => _advertLocation = value),
              ),
              SettingsReveal(
                visible: _advertLocation,
                children: [
                  SwitchListTile(
                    contentPadding: switchPadding,
                    // Same icon as the zero-hop advert action in Contacts.
                    secondary: const Icon(
                      Icons.connect_without_contact,
                      size: 24,
                    ),
                    title: Text(l10n.settings_autoZeroHopAdvertOnGpsUpdate),
                    subtitle: Text(
                      l10n.settings_autoZeroHopAdvertOnGpsUpdateSubtitle,
                    ),
                    value: _autoZeroHopAdvert,
                    onChanged: (value) =>
                        setState(() => _autoZeroHopAdvert = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(l10n.appSettings_messaging),
        MeshCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            contentPadding: switchPadding,
            // Double form of the delivered tick used in chats.
            secondary: const Icon(Icons.done_all, size: 24),
            title: Text(l10n.settings_multiAck),
            subtitle: Text(l10n.settings_multiAckSubtitle),
            value: _multiAcks == 1,
            onChanged: (value) => setState(() => _multiAcks = value ? 1 : 0),
          ),
        ),
        SectionHeader(l10n.contact_telemetry),
        MeshInfoCard(l10n.settings_telemetryPerContactHint),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _telemetryField(
                label: l10n.settings_telemetryBaseMode,
                value: _telemetryBase,
                onChanged: (value) => _telemetryBase = value,
              ),
              const SizedBox(height: 16),
              _telemetryField(
                label: l10n.settings_telemetryLocationMode,
                value: _telemetryLocation,
                onChanged: (value) => _telemetryLocation = value,
              ),
              const SizedBox(height: 16),
              _telemetryField(
                label: l10n.settings_telemetryEnvironmentMode,
                value: _telemetryEnvironment,
                onChanged: (value) => _telemetryEnvironment = value,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _telemetryField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final l10n = context.l10n;
    DropdownMenuItem<int> item(int mode, String text) => DropdownMenuItem(
      value: mode,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        item(teleModeDeny, l10n.settings_denyAll),
        item(teleModeAllowFlags, l10n.settings_allowByContact),
        item(teleModeAllowAll, l10n.settings_allowAll),
      ],
      onChanged: (mode) {
        if (mode != null) setState(() => onChanged(mode));
      },
    );
  }
}
