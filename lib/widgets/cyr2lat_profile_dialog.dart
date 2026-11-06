import 'dart:convert';

import 'package:flutter/material.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';

/// Add or edit a Cyrillic-to-Latin transliteration profile.
///
/// Pass [profile] to edit it; leave it null to create a new profile seeded
/// with the default character map. Owns (and disposes) its controllers.
class Cyr2LatProfileDialog extends StatefulWidget {
  final AppSettingsService settingsService;
  final Cyr2LatProfile? profile;

  const Cyr2LatProfileDialog({
    super.key,
    required this.settingsService,
    this.profile,
  });

  @override
  State<Cyr2LatProfileDialog> createState() => _Cyr2LatProfileDialogState();
}

class _Cyr2LatProfileDialogState extends State<Cyr2LatProfileDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile?.name ?? '',
  );
  late final TextEditingController _jsonController = TextEditingController(
    text: const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.profile?.charMap ?? defaultCyr2LatCharMap),
  );
  bool _saving = false;

  bool get _isEdit => widget.profile != null;

  @override
  void dispose() {
    _nameController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text;
    if (name.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_cyr2latProfileNameEmpty),
      );
      return;
    }
    final Map<String, String> map;
    try {
      final json = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      map = json.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.channels_cyr2latSettingsDialogWrongJSON('$e')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.profile;
      if (existing != null) {
        await widget.settingsService.updateCyr2LatProfile(
          existing.copyWith(name: name, charMap: map),
        );
      } else {
        await widget.settingsService.addCyr2LatProfile(
          Cyr2LatProfile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            charMap: map,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      showDismissibleSnackBar(
        context,
        content: Text(
          _isEdit
              ? l10n.settings_cyr2latProfileUpdated
              : l10n.settings_cyr2latProfileAdded,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_error('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        _isEdit
            ? l10n.settings_cyr2latProfileEdit
            : l10n.settings_cyr2latProfileAdd,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.settings_cyr2latProfileName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jsonController,
              maxLines: 15,
              decoration: InputDecoration(
                labelText: l10n.channels_cyr2latSettingsDialogHint,
                border: const OutlineInputBorder(),
                hintText: l10n.channels_cyr2latSettingsDscr,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.common_save),
        ),
      ],
    );
  }
}
