import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../widgets/connect_sheet.dart';

/// The single rule for offline (read-only) mode: anything that talks to the
/// radio or changes stored history is unavailable unless a radio is
/// connected. Connecting and a pending auto-reconnect count as offline.
bool isRadioReadOnly(MeshCoreConnector connector) => !connector.isConnected;

extension RadioReadOnlyContext on BuildContext {
  /// [isRadioReadOnly] for the connector in scope; rebuilds the caller when it
  /// changes. Use in `build`; in callbacks use [ensureRadioConnected].
  bool get radioReadOnly =>
      select<MeshCoreConnector, bool>((c) => isRadioReadOnly(c));
}

/// Safety net for radio actions that could not be disabled in the UI (for
/// example a dialog that was already open when the link dropped). Returns
/// true when connected; otherwise explains why and offers to connect.
bool ensureRadioConnected(BuildContext context) {
  if (!isRadioReadOnly(context.read<MeshCoreConnector>())) return true;
  final l10n = context.l10n;
  showDismissibleSnackBar(
    context,
    content: Text(l10n.settings_notConnectedError),
    action: SnackBarAction(
      label: l10n.common_connect,
      onPressed: () {
        if (context.mounted) showConnectSheet(context);
      },
    ),
  );
  return false;
}
