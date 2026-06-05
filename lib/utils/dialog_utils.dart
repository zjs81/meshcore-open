import 'package:flutter/material.dart';
import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import 'app_logger.dart';

/// Shows a confirmation dialog before disconnecting from the device.
/// Returns true if user confirmed and disconnect completed, false otherwise.
Future<bool> showDisconnectDialog(
  BuildContext context,
  MeshCoreConnector connector,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.dialog_disconnect),
      content: Text(l10n.dialog_disconnectConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.common_disconnect),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    appLogger.info('Disconnect confirmed from popup', tag: 'Connection');
    await connector.disconnect();
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.dialog_disconnectedTitle),
          content: Text(context.l10n.dialog_disconnectedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.common_ok),
            ),
          ],
        ),
      );
    }
    return true;
  }
  return false;
}
