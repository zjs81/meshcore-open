import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Asks the user to confirm clearing a log or history. Resolves to true only
/// when the user taps Clear.
Future<bool> showConfirmClearDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          child: Text(l10n.common_clear),
        ),
      ],
    ),
  );
  return confirmed == true;
}
