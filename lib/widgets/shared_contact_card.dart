import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/contact_share_message.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import 'mesh_ui.dart';

String contactShareTypeLabel(AppLocalizations l10n, int type) {
  switch (type) {
    case 2:
      return l10n.contact_typeRepeater;
    case 3:
      return l10n.contact_typeRoom;
    case 4:
      return l10n.contact_typeSensor;
    default:
      return l10n.contact_typeChat;
  }
}

/// Card shown in chat bubbles for a `<PUBKEY:TYPE:NAME>` contact share, with a
/// one-tap "Add contact" action for incoming shares not yet on the radio.
class SharedContactCard extends StatefulWidget {
  final ContactShare share;
  final bool isOutgoing;
  final double textScale;
  final Color textColor;
  final Color metaColor;

  const SharedContactCard({
    super.key,
    required this.share,
    required this.isOutgoing,
    required this.textScale,
    required this.textColor,
    required this.metaColor,
  });

  @override
  State<SharedContactCard> createState() => _SharedContactCardState();
}

class _SharedContactCardState extends State<SharedContactCard> {
  bool _adding = false;

  Future<void> _add(MeshCoreConnector connector) async {
    if (_adding) return;
    setState(() => _adding = true);
    var ok = true;
    try {
      await connector.addContactFromCard(widget.share.toScannedContact());
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _adding = false);
    final l10n = context.l10n;
    showDismissibleSnackBar(
      context,
      content: Text(
        ok ? l10n.contacts_contactImported : l10n.contacts_contactImportFailed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final share = widget.share;
    final scale = widget.textScale;
    final connector = context.watch<MeshCoreConnector>();
    final isSelf = connector.selfPublicKeyHex == share.publicKeyHex;
    final isSaved = connector.getContactByPubKeyHex(share.publicKeyHex) != null;
    final displayName = share.name.isEmpty ? share.shortKey : share.name;

    Widget? action;
    if (!widget.isOutgoing) {
      if (isSelf) {
        action = _status(Icons.person_outline, l10n.contactShare_isYou);
      } else if (isSaved) {
        // Still offer a re-add: the app's list can lag the radio (e.g. the
        // contact was dropped on the radio or by another client), and adding
        // again just refreshes an existing entry.
        action = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            _status(Icons.check_circle_outline, l10n.contactShare_saved),
            TextButton(
              onPressed: connector.isConnected && !_adding
                  ? () => _add(connector)
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: widget.textColor,
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                _adding ? l10n.contactShare_adding : l10n.contactShare_addAgain,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: widget.textColor,
                ),
              ),
            ),
          ],
        );
      } else {
        action = SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: connector.isConnected && !_adding
                ? () => _add(connector)
                : null,
            icon: _adding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt),
            label: Text(
              _adding ? l10n.contactShare_adding : l10n.contactShare_add,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.isOutgoing
              ? l10n.contactShare_headerOutgoing
              : l10n.contactShare_headerIncoming,
          style: TextStyle(
            color: widget.metaColor,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AvatarCircle(name: displayName, size: 44),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    contactShareTypeLabel(l10n, share.type),
                    style: TextStyle(
                      color: widget.metaColor,
                      fontSize: 13 * scale,
                    ),
                  ),
                  Text(
                    '<${share.shortKey}>',
                    style: MeshTheme.mono(
                      fontSize: 12 * scale,
                      color: widget.metaColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (action != null) ...[const SizedBox(height: 10), action],
      ],
    );
  }

  Widget _status(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20 * widget.textScale, color: widget.textColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: widget.textColor,
            fontSize: 14 * widget.textScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
