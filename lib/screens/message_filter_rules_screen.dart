import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/message_filter.dart';
import '../services/message_filter/message_filter_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_rule_dialog.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';

/// Message Filter → Rules: the user's own rules, with add, edit, turn
/// off and delete, search and bulk selection.
class MessageFilterRulesScreen extends StatefulWidget {
  const MessageFilterRulesScreen({super.key});

  @override
  State<MessageFilterRulesScreen> createState() =>
      _MessageFilterRulesScreenState();
}

class _MessageFilterRulesScreenState extends State<MessageFilterRulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;
  String _query = '';

  /// Bulk selection: when on, taps toggle rows and the app bar holds the
  /// bulk actions.
  bool _selectMode = false;
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Focus only on opening, so leaving selection mid-search keeps the
  // keyboard closed.
  void _openSearch() {
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      _selectMode = true;
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _exitSelectMode() => setState(() {
    _selectMode = false;
    _selected.clear();
  });

  void _showUndo(String text, VoidCallback onUndo) {
    showDismissibleSnackBar(
      context,
      content: Text(text),
      action: SnackBarAction(
        label: context.l10n.common_undo,
        onPressed: onUndo,
      ),
    );
  }

  Future<void> _addRule(MessageFilterService service) async {
    final rule = await showFilterRuleDialog(context);
    if (rule == null) return;
    await service.addRule(rule);
    if (!mounted) return;
    _showUndo(
      context.l10n.messageFilter_ruleSaved,
      () => service.removeRule(rule.id),
    );
  }

  Future<void> _editRule(
    MessageFilterService service,
    FilterRule existing,
  ) async {
    final rule = await showFilterRuleDialog(context, existing: existing);
    if (rule == null) return;
    await service.updateRule(rule);
    if (!mounted) return;
    _showUndo(
      context.l10n.messageFilter_ruleSaved,
      // Keeps the on/off state, which the switch may have changed since.
      () => service.updateRule(
        existing.copyWith(
          enabled: service.rules
              .firstWhere((r) => r.id == existing.id, orElse: () => existing)
              .enabled,
        ),
      ),
    );
  }

  Future<void> _deleteRule(
    MessageFilterService service,
    FilterRule rule,
  ) async {
    final index = service.rules.indexWhere((r) => r.id == rule.id);
    await service.removeRule(rule.id);
    if (!mounted) return;
    _showUndo(
      context.l10n.messageFilter_ruleDeleted,
      () => service.addRule(rule, index: index < 0 ? null : index),
    );
  }

  Future<void> _deleteSelected(
    MessageFilterService service,
    List<FilterRule> selected,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmClearDialog(
      context,
      title: l10n.messageFilter_deleteRulesTitle,
      message: l10n.messageFilter_deleteRulesConfirm(selected.length),
      confirmLabel: l10n.common_delete,
    );
    if (!confirmed || !mounted) return;
    final ids = {for (final r in selected) r.id};
    final before = service.rules;
    final removed = [
      for (var i = 0; i < before.length; i++)
        if (ids.contains(before[i].id)) (i, before[i]),
    ];
    _exitSelectMode();
    await service.setRules([
      for (final r in before)
        if (!ids.contains(r.id)) r,
    ]);
    if (!mounted) return;
    _showUndo(l10n.messageFilter_rulesDeleted(removed.length), () {
      // Lowest index first, so each rule lands back in its old place.
      final rules = List.of(service.rules);
      for (final (index, rule) in removed) {
        rules.insert(index.clamp(0, rules.length), rule);
      }
      service.setRules(rules);
    });
  }

  Future<void> _setSelectedEnabled(
    MessageFilterService service,
    List<FilterRule> selected,
    bool enabled,
  ) async {
    final ids = {
      for (final r in selected)
        if (r.enabled != enabled) r.id,
    };
    List<FilterRule> withEnabled(bool on) => [
      for (final r in service.rules)
        ids.contains(r.id) ? r.copyWith(enabled: on) : r,
    ];
    _exitSelectMode();
    await service.setRules(withEnabled(enabled));
    if (!mounted) return;
    final l10n = context.l10n;
    _showUndo(
      enabled
          ? l10n.messageFilter_rulesTurnedOn(ids.length)
          : l10n.messageFilter_rulesTurnedOff(ids.length),
      () => service.setRules(withEnabled(!enabled)),
    );
  }

  Widget _buildSearchField() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
      },
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: context.l10n.messageFilter_searchRules,
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = context.watch<MessageFilterService>();
    final rules = service.rules;
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? rules
        : [
            for (final r in rules)
              if (r.pattern.toLowerCase().contains(query)) r,
          ];
    final selected = [
      for (final r in rules)
        if (_selected.contains(r.id)) r,
    ];

    return PopScope(
      canPop: !_searching && !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectMode) {
          _exitSelectMode();
        } else if (_searching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: _selectMode
            ? AppBar(
                leading: IconButton(
                  tooltip: l10n.chat_clearSelection,
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectMode,
                ),
                title: Text(l10n.chat_selectedCount(selected.length)),
                actions: [
                  IconButton(
                    tooltip: l10n.chat_selectAll,
                    icon: const Icon(Icons.select_all),
                    onPressed: () => setState(() {
                      _selected.addAll(visible.map((r) => r.id));
                    }),
                  ),
                  IconButton(
                    tooltip: l10n.common_delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: selected.isEmpty
                        ? null
                        : () => _deleteSelected(service, selected),
                  ),
                  PopupMenuButton<void>(
                    tooltip: l10n.contacts_moreOptions,
                    icon: const Icon(Icons.more_vert),
                    enabled: selected.isNotEmpty,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: selected.any((r) => !r.enabled),
                        onTap: () =>
                            _setSelectedEnabled(service, selected, true),
                        child: MeshMenuItemRow(
                          icon: Icons.toggle_on_outlined,
                          label: l10n.messageFilter_turnOn,
                        ),
                      ),
                      PopupMenuItem(
                        enabled: selected.any((r) => r.enabled),
                        onTap: () =>
                            _setSelectedEnabled(service, selected, false),
                        child: MeshMenuItemRow(
                          icon: Icons.toggle_off_outlined,
                          label: l10n.messageFilter_turnOff,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : AppBar(
                leading: _searching
                    ? IconButton(
                        tooltip: l10n.chatSearch_close,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _closeSearch,
                      )
                    : null,
                title: _searching
                    ? _buildSearchField()
                    : AdaptiveAppBarTitle(l10n.messageFilter_rulesTitle),
                centerTitle: !_searching,
                actions: _searching || rules.isEmpty
                    ? null
                    : [
                        IconButton(
                          tooltip: l10n.messageFilter_searchRules,
                          icon: const Icon(Icons.search),
                          onPressed: _openSearch,
                        ),
                        IconButton(
                          tooltip: l10n.messageFilter_selectRules,
                          icon: const Icon(Icons.checklist),
                          onPressed: () => setState(() => _selectMode = true),
                        ),
                      ],
              ),
        floatingActionButton: _searching || _selectMode
            ? null
            : FloatingActionButton.extended(
                key: const ValueKey('messageFilter_addRuleButton'),
                onPressed: () => _addRule(service),
                icon: const Icon(Icons.add),
                label: Text(l10n.messageFilter_addRule),
              ),
        body: SafeArea(
          top: false,
          child: rules.isEmpty
              ? EmptyState(
                  icon: Icons.rule,
                  title: l10n.messageFilter_rulesEmptyTitle,
                  subtitle: l10n.messageFilter_rulesEmpty,
                )
              : visible.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: l10n.messageFilter_rulesNoResults,
                  subtitle: l10n.chatSearch_noResultsHint,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
                  children: [
                    MeshCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < visible.length; i++) ...[
                            if (i > 0) const Divider(height: 1, indent: 16),
                            _RuleTile(
                              key: ValueKey(
                                'messageFilter_rule_${visible[i].id}',
                              ),
                              rule: visible[i],
                              selectMode: _selectMode,
                              selected: _selected.contains(visible[i].id),
                              onTap: _selectMode
                                  ? () => _toggleSelected(visible[i].id)
                                  : () => _editRule(service, visible[i]),
                              onLongPress: () => _toggleSelected(visible[i].id),
                              onEnabledChanged: (value) => service.updateRule(
                                visible[i].copyWith(enabled: value),
                              ),
                              onDelete: () => _deleteRule(service, visible[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final FilterRule rule;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  const _RuleTile({
    super.key,
    required this.rule,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
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

    final tile = InkWell(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.selectionClick();
        onLongPress();
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
        child: Row(
          children: [
            if (selectMode)
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 28,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              )
            else
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
                      style: meshTileTitleStyle(theme),
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
            // The rule's text names the switch and the delete button.
            Semantics(
              label: rule.pattern,
              child: Switch(
                value: rule.enabled,
                onChanged: selectMode ? null : onEnabledChanged,
              ),
            ),
            MergeSemantics(
              child: Semantics(
                label: rule.pattern,
                child: IconButton(
                  tooltip: l10n.common_delete,
                  icon: const Icon(Icons.delete_outline, size: 24),
                  color: scheme.onSurfaceVariant,
                  onPressed: selectMode ? null : onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!selectMode) return tile;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        child: tile,
      ),
    );
  }
}
