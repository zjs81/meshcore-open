import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../screens/channels_screen.dart';

export 'review_mode_banner.dart';
export 'review_mode_entry.dart';

/// Asks for confirmation, connects to the simulated radio and opens the app.
Future<void> enterReviewMode(BuildContext context) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final connector = context.read<MeshCoreConnector>();
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.reviewMode_dialogTitle),
      content: Text(dialogContext.l10n.reviewMode_dialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.reviewMode_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(dialogContext.l10n.reviewMode_confirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !navigator.mounted) return;

  // Progress dialog on the root navigator while connecting.
  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  Object? error;
  try {
    await connector.connectReview();
  } catch (e) {
    error = e;
  }

  if (!navigator.mounted) return;
  navigator.pop(); // progress dialog

  if (error != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.reviewMode_connectFailed(error.toString()))),
    );
    return;
  }
  // The connect may have been ignored (another connection was in progress)
  // or cancelled by a disconnect while it was running.
  if (!connector.isReviewMode || !connector.isConnected) return;

  navigator.push(MaterialPageRoute(builder: (_) => const ChannelsScreen()));
}
