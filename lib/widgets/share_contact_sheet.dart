import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/contact_share_message.dart';
import '../l10n/contact_localization.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../theme/mesh_theme.dart';
import 'mesh_ui.dart';

/// Lets the user pick a saved contact (or themself) and appends the encoded
/// share token to [controller] so they can review and press send.
Future<void> showShareContactSheet(
  BuildContext context,
  TextEditingController controller, {
  FocusNode? focusNode,
}) async {
  final connector = context.read<MeshCoreConnector>();
  final token = await showMeshSheet<String>(
    context,
    builder: (_) => _ShareContactSheet(connector: connector),
  );
  if (token == null) return;
  controller.value = TextEditingValue(
    text: token,
    selection: TextSelection.collapsed(offset: token.length),
  );
  focusNode?.requestFocus();
}

class _ShareContactSheet extends StatefulWidget {
  final MeshCoreConnector connector;

  const _ShareContactSheet({required this.connector});

  @override
  State<_ShareContactSheet> createState() => _ShareContactSheetState();
}

class _ShareContactSheetState extends State<_ShareContactSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = widget.connector;
    final selfKey = connector.selfPublicKey;
    final needle = _query.trim().toLowerCase();
    final contacts =
        connector.contacts
            .where(
              (c) =>
                  c.publicKey.length == 32 &&
                  (needle.isEmpty || c.name.toLowerCase().contains(needle)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final selfName = connector.selfName ?? '';
    final showSelf =
        selfKey != null &&
        selfKey.length == 32 &&
        (needle.isEmpty ||
            selfName.toLowerCase().contains(needle) ||
            l10n.contactShare_myContact.toLowerCase().contains(needle));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(title: l10n.contactShare_pickerTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.contactShare_searchHint,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (showSelf)
                    _tile(
                      context,
                      name: selfName.isEmpty
                          ? l10n.contactShare_myContact
                          : selfName,
                      subtitle: l10n.contactShare_myContact,
                      token: encodeContactShare(
                        publicKey: selfKey,
                        type: 1,
                        name: selfName,
                      ),
                    ),
                  for (final c in contacts) _contactTile(context, c),
                  if (!showSelf && contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.contactShare_noContacts,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(BuildContext context, Contact c) {
    return _tile(
      context,
      name: c.name,
      subtitle: c.typeLabel(context.l10n),
      token: encodeContactShare(
        publicKey: c.publicKey,
        type: c.type >= 1 && c.type <= 4 ? c.type : 1,
        name: c.name,
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String name,
    required String subtitle,
    required String token,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 56,
      leading: AvatarCircle(name: name, size: 40),
      title: Text(name, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        subtitle,
        style: MeshTheme.mono(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      onTap: () => Navigator.of(context).pop(token),
    );
  }
}
