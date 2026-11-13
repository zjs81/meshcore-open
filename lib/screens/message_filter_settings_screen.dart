import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/message_filter.dart';
import '../services/message_filter/message_filter_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/filter_rule_dialog.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import 'filtered_messages_screen.dart';

/// Settings → Message filter: master switch, how filtered messages are shown,
/// the user's own rules and the automatic checks.
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
                    _DisplayModeOptions(service: service),
                    const Divider(height: 1, indent: 16),
                    const _FilteredMessagesTile(),
                  ],
                ),
              ),

              SectionHeader(l10n.messageFilter_rulesSection),
              MeshCard(
                padding: EdgeInsets.zero,
                child: _RulesList(service: service),
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

class _DisplayModeOptions extends StatelessWidget {
  final MessageFilterService service;

  const _DisplayModeOptions({required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = service.settings;
    return RadioGroup<FilterDisplayMode>(
      groupValue: settings.displayMode,
      onChanged: (mode) {
        if (mode == null || mode == settings.displayMode) return;
        service.updateSettings(service.settings.copyWith(displayMode: mode));
      },
      child: Column(
        children: [
          RadioListTile<FilterDisplayMode>(
            key: const ValueKey('messageFilter_displayPlaceholder'),
            contentPadding: MessageFilterSettingsScreen._tilePadding,
            value: FilterDisplayMode.placeholder,
            title: Text(l10n.messageFilter_displayPlaceholder),
          ),
          RadioListTile<FilterDisplayMode>(
            key: const ValueKey('messageFilter_displayHide'),
            contentPadding: MessageFilterSettingsScreen._tilePadding,
            value: FilterDisplayMode.hide,
            title: Text(l10n.messageFilter_displayHide),
            subtitle: Text(l10n.messageFilter_displayHideHelp),
          ),
        ],
      ),
    );
  }
}

/// "Filtered messages (N)" row. Rebuilds only when the count changes.
class _FilteredMessagesTile extends StatelessWidget {
  const _FilteredMessagesTile();

  @override
  Widget build(BuildContext context) {
    final count = context.select<MeshCoreConnector, int>(
      (c) => c.recentFilteredChannelMessages().length,
    );
    return MeshNavTile(
      icon: Icons.visibility_off_outlined,
      title: context.l10n.messageFilter_filteredMessages(count),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FilteredMessagesScreen()),
      ),
    );
  }
}

class _RulesList extends StatelessWidget {
  final MessageFilterService service;

  const _RulesList({required this.service});

  Future<void> _addRule(BuildContext context) async {
    final rule = await showFilterRuleDialog(context);
    if (rule == null) return;
    await service.addRule(rule);
    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.messageFilter_ruleSaved),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _editRule(BuildContext context, FilterRule existing) async {
    final rule = await showFilterRuleDialog(context, existing: existing);
    if (rule == null) return;
    await service.updateRule(rule);
    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.messageFilter_ruleSaved),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _deleteRule(BuildContext context, FilterRule rule) async {
    final l10n = context.l10n;
    // Capture before the await: the row (and its context) goes away with the
    // rule, but the undo action must still be able to put it back.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final index = service.rules.indexWhere((r) => r.id == rule.id);
    await service.removeRule(rule.id);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.messageFilter_ruleDeleted),
        duration: const Duration(seconds: 6),
        // Newer Flutter persists snackbars with an action unless told not to.
        persist: false,
        action: SnackBarAction(
          label: l10n.common_undo,
          onPressed: () =>
              service.addRule(rule, index: index < 0 ? null : index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rules = service.rules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rules.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.messageFilter_rulesEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (var i = 0; i < rules.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 16),
          _RuleTile(
            key: ValueKey('messageFilter_rule_${rules[i].id}'),
            rule: rules[i],
            onTap: () => _editRule(context, rules[i]),
            onEnabledChanged: (value) =>
                service.updateRule(rules[i].copyWith(enabled: value)),
            onDelete: () => _deleteRule(context, rules[i]),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: const ValueKey('messageFilter_addRuleButton'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _addRule(context),
              icon: const Icon(Icons.add, size: 24),
              label: Text(l10n.messageFilter_addRule),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  final FilterRule rule;
  final VoidCallback onTap;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  const _RuleTile({
    super.key,
    required this.rule,
    required this.onTap,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details =
        '${filterRuleFieldLabel(context, rule.field)} · '
        '${filterRuleMatchLabel(context, rule.match)}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(
              rule.field == FilterRuleField.sender
                  ? Icons.person_outline
                  : Icons.text_fields,
              size: 24,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Opacity(
                opacity: rule.enabled ? 1 : 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.pattern,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Switch(value: rule.enabled, onChanged: onEnabledChanged),
            IconButton(
              tooltip: l10n.common_delete,
              icon: const Icon(Icons.delete_outline, size: 24),
              color: scheme.onSurfaceVariant,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomaticOptions extends StatelessWidget {
  final MessageFilterService service;

  const _AutomaticOptions({required this.service});

  Future<void> _confirmResetLearning(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.messageFilter_resetLearning),
        content: Text(l10n.messageFilter_resetLearningConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.messageFilter_resetLearning),
          ),
        ],
      ),
    );
    if (confirmed == true) await service.resetLearning();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = service.settings;
    final spam = service.spamExampleCount;
    final notSpam = service.notSpamExampleCount;
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
        ListTile(
          key: const ValueKey('messageFilter_repeatSends'),
          contentPadding: padding,
          enabled: settings.duplicates,
          leading: const Icon(Icons.repeat, size: 24),
          title: Text(l10n.messageFilter_repeatSends),
          subtitle: Text(
            l10n.messageFilter_repeatSendsSubtitle(settings.repeatSends),
          ),
          trailing: DropdownButton<int>(
            key: const ValueKey('messageFilter_repeatSendsDropdown'),
            value: settings.repeatSends,
            onChanged: settings.duplicates
                ? (value) {
                    if (value == null) return;
                    service.updateSettings(
                      service.settings.copyWith(repeatSends: value),
                    );
                  }
                : null,
            items: [
              for (
                var n = MessageFilterSettings.minRepeatSends;
                n <= MessageFilterSettings.maxRepeatSends;
                n++
              )
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          key: const ValueKey('messageFilter_repeatedCharactersSwitch'),
          contentPadding: padding,
          secondary: const Icon(Icons.more_horiz, size: 24),
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
          icon: Icons.restart_alt,
          title: l10n.messageFilter_resetLearning,
          showChevron: false,
          onTap: spam + notSpam == 0
              ? null
              : () => _confirmResetLearning(context),
        ),
      ],
    );
  }
}
