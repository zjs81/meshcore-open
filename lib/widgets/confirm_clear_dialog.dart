import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Asks the user to confirm a destructive action (Clear by default). Resolves
/// to true only when the user taps the confirm button. [warning] uses the
/// amber warning colour instead of red.
Future<bool> showConfirmClearDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool warning = false,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: warning ? scheme.tertiary : scheme.error,
              foregroundColor: warning ? scheme.onTertiary : scheme.onError,
            ),
            child: Text(confirmLabel ?? l10n.common_clear),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
