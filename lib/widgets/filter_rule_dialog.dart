import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/message_filter.dart';
import '../services/message_filter/message_filter_service.dart';

/// Opens the add / edit dialog for a message filter rule.
///
/// Returns the rule to save, or null when the user cancels. The caller
/// persists it (`MessageFilterService.addRule` / `updateRule`). When
/// [existing] is given its id and enabled state are kept; otherwise a new id
/// is generated. [initialPattern] and [initialField] prefill a new rule, for
/// example "Filter messages like this…" from a chat message.
Future<FilterRule?> showFilterRuleDialog(
  BuildContext context, {
  FilterRule? existing,
  String? initialPattern,
  FilterRuleField? initialField,
}) {
  return showDialog<FilterRule>(
    context: context,
    builder: (_) => _FilterRuleDialog(
      existing: existing,
      initialPattern: initialPattern,
      initialField: initialField,
    ),
  );
}

class _FilterRuleDialog extends StatefulWidget {
  final FilterRule? existing;
  final String? initialPattern;
  final FilterRuleField? initialField;

  const _FilterRuleDialog({
    this.existing,
    this.initialPattern,
    this.initialField,
  });

  @override
  State<_FilterRuleDialog> createState() => _FilterRuleDialogState();
}

class _FilterRuleDialogState extends State<_FilterRuleDialog> {
  late final TextEditingController _controller;
  late FilterRuleField _field;
  late FilterRuleMatch _match;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final pattern = (existing?.pattern ?? widget.initialPattern ?? '').trim();
    _controller = TextEditingController(text: pattern)
      ..selection = TextSelection.collapsed(offset: pattern.length);
    _field = existing?.field ?? widget.initialField ?? FilterRuleField.text;
    _match = existing?.match ?? FilterRuleMatch.contains;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave => _controller.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    final existing = widget.existing;
    final pattern = _controller.text.trim();
    final rule = existing != null
        ? existing.copyWith(pattern: pattern, field: _field, match: _match)
        : FilterRule(
            id: MessageFilterService.newRuleId(),
            pattern: pattern,
            field: _field,
            match: _match,
          );
    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? l10n.messageFilter_addRule
            : l10n.messageFilter_editRule,
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          // The outlined field's floating label is painted above the field's
          // box, outside the scroll content bounds. Without top padding the
          // viewport clips it (worst when the focused field is scrolled flush
          // to the top while the keyboard is open).
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                // Keep room above the field when it is scrolled into view, so
                // the floating label (drawn above the box) is not clipped.
                scrollPadding: EdgeInsets.fromLTRB(
                  20,
                  16 + MediaQuery.textScalerOf(context).scale(16),
                  20,
                  20,
                ),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: l10n.messageFilter_rulePattern,
                  hintText: l10n.messageFilter_rulePatternHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              Text(l10n.messageFilter_ruleWhere, style: labelStyle),
              RadioGroup<FilterRuleField>(
                groupValue: _field,
                onChanged: (value) {
                  if (value != null) setState(() => _field = value);
                },
                child: Column(
                  children: [
                    for (final field in FilterRuleField.values)
                      RadioListTile<FilterRuleField>(
                        key: ValueKey('filterRuleField_${field.name}'),
                        value: field,
                        contentPadding: EdgeInsets.zero,
                        title: Text(filterRuleFieldLabel(context, field)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.messageFilter_ruleMatch, style: labelStyle),
              RadioGroup<FilterRuleMatch>(
                groupValue: _match,
                onChanged: (value) {
                  if (value != null) setState(() => _match = value);
                },
                child: Column(
                  children: [
                    for (final match in FilterRuleMatch.values)
                      RadioListTile<FilterRuleMatch>(
                        key: ValueKey('filterRuleMatch_${match.name}'),
                        value: match,
                        contentPadding: EdgeInsets.zero,
                        title: Text(filterRuleMatchLabel(context, match)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: Text(l10n.common_save),
        ),
      ],
    );
  }
}

/// User-facing name for where a rule looks ("Message text", "Sender name",
/// "Both").
String filterRuleFieldLabel(BuildContext context, FilterRuleField field) {
  final l10n = context.l10n;
  return switch (field) {
    FilterRuleField.text => l10n.messageFilter_ruleFieldText,
    FilterRuleField.sender => l10n.messageFilter_ruleFieldSender,
    FilterRuleField.both => l10n.messageFilter_ruleFieldBoth,
  };
}

/// User-facing name for how a rule matches ("Contains", "Whole word",
/// "Exact").
String filterRuleMatchLabel(BuildContext context, FilterRuleMatch match) {
  final l10n = context.l10n;
  return switch (match) {
    FilterRuleMatch.contains => l10n.messageFilter_ruleMatchContains,
    FilterRuleMatch.wholeWord => l10n.messageFilter_ruleMatchWholeWord,
    FilterRuleMatch.exact => l10n.messageFilter_ruleMatchExact,
  };
}
