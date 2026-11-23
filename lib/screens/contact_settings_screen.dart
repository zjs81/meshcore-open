import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../theme/theme_icons.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/unsaved_changes_guard.dart';

typedef _ContactForm = ({
  bool autoAddUsers,
  bool autoAddRepeaters,
  bool autoAddRoomServers,
  bool autoAddSensors,
  bool overwriteOldest,
  int? maxHops,
  bool evictDiscovered,
});

/// Contact auto-add and overflow options. Sent on Save.
class ContactSettingsScreen extends StatefulWidget {
  const ContactSettingsScreen({super.key});

  @override
  State<ContactSettingsScreen> createState() => _ContactSettingsScreenState();
}

class _ContactSettingsScreenState extends State<ContactSettingsScreen> {
  late bool _autoAddUsers;
  late bool _autoAddRepeaters;
  late bool _autoAddRoomServers;
  late bool _autoAddSensors;
  late bool _overwriteOldest;
  // Null when the firmware doesn't report a hop limit.
  int? _maxHops;
  late bool _evictDiscovered;
  late _ContactForm _savedForm;

  @override
  void initState() {
    super.initState();
    final connector = context.read<MeshCoreConnector>();
    _autoAddUsers = connector.autoAddUsers ?? false;
    _autoAddRepeaters = connector.autoAddRepeaters ?? false;
    _autoAddRoomServers = connector.autoAddRoomServers ?? false;
    _autoAddSensors = connector.autoAddSensors ?? false;
    _overwriteOldest = connector.autoAddOverwriteOldest ?? false;
    _maxHops = connector.autoAddMaxHops;
    _evictDiscovered = context
        .read<AppSettingsService>()
        .settings
        .evictDiscoveredContactsEnabled;
    _savedForm = _form;
  }

  _ContactForm get _form => (
    autoAddUsers: _autoAddUsers,
    autoAddRepeaters: _autoAddRepeaters,
    autoAddRoomServers: _autoAddRoomServers,
    autoAddSensors: _autoAddSensors,
    overwriteOldest: _overwriteOldest,
    maxHops: _maxHops,
    evictDiscovered: _evictDiscovered,
  );

  Future<bool> _save() async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    final settingsService = context.read<AppSettingsService>();
    final form = _form;
    await connector.sendFrame(
      buildSetAutoAddConfigFrame(
        autoAddChat: form.autoAddUsers,
        autoAddRepeater: form.autoAddRepeaters,
        autoAddRoomServer: form.autoAddRoomServers,
        autoAddSensor: form.autoAddSensors,
        overwriteOldest: form.overwriteOldest,
        // Sent only when changed, so the frame is otherwise unchanged.
        maxHops: form.maxHops != _savedForm.maxHops ? form.maxHops : null,
      ),
    );
    await connector.sendFrame(buildGetAutoAddFlagsFrame());
    await settingsService.setEvictDiscoveredContactsEnabled(
      form.evictDiscovered,
    );
    if (form.evictDiscovered) {
      await connector.trimDiscoveredContactsToLimit();
    }
    if (!mounted) return true;
    setState(() => _savedForm = form);
    showDismissibleSnackBar(
      context,
      content: Text(l10n.settings_contactSettingsSaved),
    );
    return true;
  }

  Widget _switch({
    required Widget icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: icon,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: (value) => setState(() => onChanged(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const divider = Divider(height: 1, indent: 16);
    return SaveToRadioPage(
      title: l10n.settings_contactSettings,
      hasChanges: _form != _savedForm,
      onSave: _save,
      children: [
        SectionHeader(
          l10n.contactsSettings_autoAddTitle,
          description: l10n.contactsSettings_autoAddDescription,
        ),
        MeshCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Same icons as the contact list and map.
              _switch(
                icon: const Icon(Icons.person, size: 24),
                title: l10n.contactsSettings_autoAddUsersTitle,
                value: _autoAddUsers,
                onChanged: (v) => _autoAddUsers = v,
              ),
              divider,
              _switch(
                icon: const ThemedIcon(ThemeIconSlot.repeater, size: 24),
                title: l10n.contactsSettings_autoAddRepeatersTitle,
                value: _autoAddRepeaters,
                onChanged: (v) => _autoAddRepeaters = v,
              ),
              divider,
              _switch(
                icon: const ThemedIcon(ThemeIconSlot.room, size: 24),
                title: l10n.contactsSettings_autoAddRoomServersTitle,
                value: _autoAddRoomServers,
                onChanged: (v) => _autoAddRoomServers = v,
              ),
              divider,
              _switch(
                icon: const ThemedIcon(ThemeIconSlot.sensor, size: 24),
                title: l10n.contactsSettings_autoAddSensorsTitle,
                value: _autoAddSensors,
                onChanged: (v) => _autoAddSensors = v,
              ),
            ],
          ),
        ),
        SectionHeader(l10n.contactsSettings_otherTitle),
        MeshCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _switch(
                icon: const ThemedIcon(ThemeIconSlot.contacts, size: 24),
                title: l10n.contactsSettings_overwriteOldestTitle,
                subtitle: l10n.contactsSettings_overwriteOldestSubtitle,
                value: _overwriteOldest,
                onChanged: (v) => _overwriteOldest = v,
              ),
              if (_maxHops != null) ...[
                divider,
                // Same row shape as SettingsValueSlider: icon, title and
                // description, with the dropdown under the description.
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(Icons.linear_scale, size: 24),
                  title: Text(l10n.contactsSettings_hopLimit),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.contactsSettings_hopLimitSubtitle),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _maxHops,
                        isExpanded: true,
                        // Firmware: 0 = no limit, N = under N hops (max 64).
                        items: [
                          for (var hops = 0; hops <= 64; hops++)
                            DropdownMenuItem(
                              value: hops,
                              child: Text(
                                l10n.contactsSettings_hopLimitOption(hops),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _maxHops = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              divider,
              _switch(
                // The Discovered Contacts icon.
                icon: const Icon(Icons.person_add_rounded, size: 24),
                title: l10n.contactsSettings_evictDiscoveredContactsTitle,
                subtitle: l10n.contactsSettings_evictDiscoveredContactsSubtitle(
                  MeshCoreConnector.maxDiscoveredContacts,
                ),
                value: _evictDiscovered,
                onChanged: (v) => _evictDiscovered = v,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
