import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/translation_support.dart';

class MessageTranslationButton extends StatelessWidget {
  final bool enabled;
  final String? languageCode;
  final VoidCallback onPressed;

  const MessageTranslationButton({
    super.key,
    required this.enabled,
    required this.languageCode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = _languageLabel(
      languageCode,
      context.l10n.translation_systemLanguage,
    );
    return IconButton(
      icon: Icon(enabled ? Icons.translate : Icons.translate_outlined),
      onPressed: onPressed,
      tooltip: enabled
          ? context.l10n.translation_translateTo(label)
          : context.l10n.translation_translationOptions,
    );
  }
}

Future<void> showMessageTranslationSheet({
  required BuildContext context,
  required bool enabled,
  required String? selectedLanguageCode,
  required ValueChanged<bool> onEnabledChanged,
  required ValueChanged<String?> onLanguageSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MessageTranslationSheet(
      enabled: enabled,
      selectedLanguageCode: selectedLanguageCode,
      onEnabledChanged: onEnabledChanged,
      onLanguageSelected: onLanguageSelected,
    ),
  );
}

class _MessageTranslationSheet extends StatefulWidget {
  final bool enabled;
  final String? selectedLanguageCode;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String?> onLanguageSelected;

  const _MessageTranslationSheet({
    required this.enabled,
    required this.selectedLanguageCode,
    required this.onEnabledChanged,
    required this.onLanguageSelected,
  });

  @override
  State<_MessageTranslationSheet> createState() =>
      _MessageTranslationSheetState();
}

class _MessageTranslationSheetState extends State<_MessageTranslationSheet> {
  late final TextEditingController _searchController;
  late bool _localEnabled;
  late String? _localSelectedLanguageCode;
  List<TranslationLanguageOption> _filtered = supportedTranslationLanguages;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _localEnabled = widget.enabled;
    _localSelectedLanguageCode = widget.selectedLanguageCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filtered = supportedTranslationLanguages.where((option) {
        return option.label.toLowerCase().contains(normalized) ||
            option.code.toLowerCase().contains(normalized);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.translation_messageTranslation,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.translation_translateBeforeSending),
              subtitle: Text(
                _localEnabled
                    ? context.l10n.translation_composerEnabledHint
                    : context.l10n.translation_composerDisabledHint,
              ),
              value: _localEnabled,
              onChanged: (value) {
                setState(() => _localEnabled = value);
                widget.onEnabledChanged(value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: _updateFilter,
              decoration: InputDecoration(
                labelText: context.l10n.translation_targetLanguage,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final selected = _localSelectedLanguageCode == null;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(context.l10n.translation_useAppLanguage),
                      onTap: () {
                        setState(() => _localSelectedLanguageCode = null);
                        widget.onLanguageSelected(null);
                        Navigator.pop(context);
                      },
                    );
                  }
                  final option = _filtered[index - 1];
                  final selected = option.code == _localSelectedLanguageCode;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(option.label),
                    subtitle: Text(option.code.toUpperCase()),
                    onTap: () {
                      setState(() => _localSelectedLanguageCode = option.code);
                      widget.onLanguageSelected(option.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _languageLabel(String? languageCode, String systemLanguageFallback) {
  if (languageCode == null) {
    return systemLanguageFallback;
  }
  for (final option in supportedTranslationLanguages) {
    if (option.code == languageCode) {
      return option.label;
    }
  }
  return languageCode.toUpperCase();
}
