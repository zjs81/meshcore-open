import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/message_filter.dart';
import '../services/message_filter/message_filter_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/settings_reveal.dart';
import 'filtered_messages_screen.dart';
import 'message_filter_rules_screen.dart';

/// Settings → Message Filter: master switch, how filtered messages are shown
/// and the list of them, a row to the user's own rules and the automatic
/// checks.
class MessageFilterSettingsScreen extends StatelessWidget {
  const MessageFilterSettingsScreen({super.key});

  static const _tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = context.watch<MessageFilterService>();
    final settings = service.settings;

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.messageFilter_title),
        centerTitle: true,
      ),
      body: MeshSettingsTileTheme(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              MeshInfoCard(l10n.messageFilter_info),
              SectionHeader(l10n.messageFilter_filteringSection),
              MeshCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  key: const ValueKey('messageFilter_enabledSwitch'),
                  contentPadding: _tilePadding,
                  secondary: const Icon(Icons.filter_alt_outlined, size: 24),
                  title: Text(l10n.messageFilter_enabled),
                  subtitle: Text(l10n.messageFilter_enabledSubtitle),
                  value: settings.enabled,
                  onChanged: (value) => service.updateSettings(
                    service.settings.copyWith(enabled: value),
                  ),
                ),
              ),
              SectionHeader(l10n.messageFilter_displayTitle),
              MeshCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const ValueKey('messageFilter_displayHide'),
                      contentPadding: _tilePadding,
                      secondary: const Icon(
                        Icons.visibility_off_outlined,
                        size: 24,
                      ),
                      title: Text(l10n.messageFilter_displayHide),
                      subtitle: Text(l10n.messageFilter_displayHideSubtitle),
                      value: settings.displayMode == FilterDisplayMode.hide,
                      onChanged: (value) => service.updateSettings(
                        service.settings.copyWith(
                          displayMode: value
                              ? FilterDisplayMode.hide
                              : FilterDisplayMode.placeholder,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16),
                    const _FilteredMessagesTile(),
                  ],
                ),
              ),
              SectionHeader(l10n.messageFilter_rulesSection),
              MeshCard(
                padding: EdgeInsets.zero,
                child: MeshNavTile(
                  key: const ValueKey('messageFilter_rulesRow'),
                  icon: Icons.rule,
                  title: l10n.messageFilter_rulesCount(service.rules.length),
                  subtitle: l10n.messageFilter_rulesHint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MessageFilterRulesScreen(),
                    ),
                  ),
                ),
              ),
              SectionHeader(l10n.messageFilter_automaticSection),
              MeshCard(
                padding: EdgeInsets.zero,
                child: _AutomaticOptions(service: service),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Filtered Messages (N)" row. Rebuilds only when the count changes.
class _FilteredMessagesTile extends StatelessWidget {
  const _FilteredMessagesTile();

  @override
  Widget build(BuildContext context) {
    final count = context.select<MeshCoreConnector, int>(
      (c) => c.recentFilteredChannelMessages().length,
    );
    return MeshNavTile(
      icon: Icons.inbox_outlined,
      title: context.l10n.messageFilter_filteredMessages(count),
      subtitle: context.l10n.messageFilter_filteredMessagesSubtitle,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FilteredMessagesScreen()),
      ),
    );
  }
}

class _AutomaticOptions extends StatelessWidget {
  final MessageFilterService service;

  const _AutomaticOptions({required this.service});

  Future<void> _confirmResetLearning(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmClearDialog(
      context,
      title: l10n.messageFilter_resetLearning,
      message: l10n.messageFilter_resetLearningConfirm,
      confirmLabel: l10n.common_reset,
    );
    if (confirmed) await service.resetLearning();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final settings = service.settings;
    final spam = service.spamExampleCount;
    final notSpam = service.notSpamExampleCount;
    final hasExamples = spam + notSpam > 0;
    const padding = MessageFilterSettingsScreen._tilePadding;

    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('messageFilter_duplicatesSwitch'),
          contentPadding: padding,
          secondary: const Icon(Icons.copy_all_outlined, size: 24),
          title: Text(l10n.messageFilter_duplicates),
          subtitle: Text(l10n.messageFilter_duplicatesSubtitle),
          value: settings.duplicates,
          onChanged: (value) => service.updateSettings(
            service.settings.copyWith(duplicates: value),
          ),
        ),
        SettingsReveal(
          visible: settings.duplicates,
          children: [
            SettingsValueSlider(
              key: const ValueKey('messageFilter_repeatSends'),
              icon: Icons.repeat,
              title: l10n.messageFilter_repeatSendsCount(settings.repeatSends),
              subtitle: l10n.messageFilter_repeatSendsHint,
              value: settings.repeatSends,
              min: MessageFilterSettings.minRepeatSends,
              max: MessageFilterSettings.maxRepeatSends,
              onChanged: (value) => service.updateSettings(
                service.settings.copyWith(repeatSends: value),
              ),
            ),
          ],
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          key: const ValueKey('messageFilter_repeatedCharactersSwitch'),
          contentPadding: padding,
          secondary: const Icon(Icons.abc, size: 24),
          title: Text(l10n.messageFilter_repeatedCharacters),
          subtitle: Text(l10n.messageFilter_repeatedCharactersSubtitle),
          value: settings.repeatedCharacters,
          onChanged: (value) => service.updateSettings(
            service.settings.copyWith(repeatedCharacters: value),
          ),
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          key: const ValueKey('messageFilter_learningSwitch'),
          contentPadding: padding,
          secondary: const Icon(Icons.school_outlined, size: 24),
          title: Text(l10n.messageFilter_learning),
          subtitle: Text(l10n.messageFilter_learningSubtitle(spam, notSpam)),
          value: settings.learning,
          onChanged: (value) => service.updateSettings(
            service.settings.copyWith(learning: value),
          ),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          key: const ValueKey('messageFilter_resetLearning'),
          icon: Icons.delete_sweep_outlined,
          title: l10n.messageFilter_resetLearning,
          subtitle: hasExamples
              ? l10n.messageFilter_resetLearningSubtitle
              : l10n.messageFilter_resetLearningNothing,
          titleColor: hasExamples ? scheme.error : null,
          iconColor: hasExamples ? scheme.error : null,
          onTap: hasExamples ? () => _confirmResetLearning(context) : null,
        ),
      ],
    );
  }
}
