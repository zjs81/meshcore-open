import 'dart:async';

import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/contact_localization.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../theme/mesh_theme.dart';
import 'contact_visuals.dart';
import 'mesh_ui.dart';

/// Opens the nearby-node scan (#570): a zero-hop DISCOVER_REQ whose answers
/// are listed live and can be added as contacts.
Future<void> showNodeScanSheet(
  BuildContext context,
  MeshCoreConnector connector,
) {
  return showMeshSheet<void>(
    context,
    builder: (_) => NodeScanSheet(connector: connector),
  );
}

class NodeScanSheet extends StatefulWidget {
  const NodeScanSheet({super.key, required this.connector});

  final MeshCoreConnector connector;

  @override
  State<NodeScanSheet> createState() => _NodeScanSheetState();
}

class _NodeScanSheetState extends State<NodeScanSheet> {
  final List<NodeDiscoverResponse> _results = [];
  final Set<String> _adding = {};
  StreamSubscription<NodeDiscoverResponse>? _subscription;
  bool _scanning = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startScan() {
    _subscription?.cancel();
    setState(() {
      _results.clear();
      _scanning = true;
      _failed = false;
    });
    _subscription = widget.connector.discoverNearbyNodes().listen(
      (response) {
        if (!mounted) return;
        setState(() {
          _results
            ..add(response)
            ..sort((a, b) => b.snr.compareTo(a.snr));
        });
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _failed = true);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _scanning = false);
      },
    );
  }

  bool _isContact(NodeDiscoverResponse response) {
    final keyHex = response.publicKeyHex;
    return widget.connector.contacts.any(
      (contact) => contact.publicKeyHex.startsWith(keyHex),
    );
  }

  Future<void> _add(NodeDiscoverResponse response) async {
    final keyHex = response.publicKeyHex;
    setState(() => _adding.add(keyHex));
    final contact = widget.connector.contactForDiscoverResponse(response);
    var imported = false;
    try {
      imported = await widget.connector.importDiscoveredContact(contact);
    } catch (_) {
      imported = false;
    }
    if (!mounted) return;
    setState(() => _adding.remove(keyHex));
    showDismissibleSnackBar(
      context,
      content: Text(
        imported
            ? context.l10n.discoveredContacts_contactAdded
            : context.l10n.contacts_contactImportFailed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = _failed
        ? l10n.discoveredContacts_scanFailed
        : _scanning
        ? l10n.discoveredContacts_scanning
        : l10n.discoveredContacts_scanFound(_results.length);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottomSheetHeader(
            title: l10n.discoveredContacts_scanTitle,
            subtitle: status,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.discoveredContacts_scanExplanation,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ),
          if (_scanning) const LinearProgressIndicator(minHeight: 3),
          Flexible(
            child: _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: _scanning
                        ? const SizedBox.shrink()
                        : Text(
                            l10n.discoveredContacts_scanNoResults,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15),
                          ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) =>
                        _buildResult(context, _results[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: FilledButton.icon(
              onPressed: _scanning ? null : _startScan,
              icon: const Icon(Icons.radar, size: 20),
              label: Text(l10n.discoveredContacts_scanAgain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, NodeDiscoverResponse response) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final contact = widget.connector.contactForDiscoverResponse(response);
    final known = _isKnownNode(contact);
    final inContacts = _isContact(response);
    final adding = _adding.contains(response.publicKeyHex);
    final color = contactTypeColor(response.nodeType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MeshCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AvatarCircle(
              name: contact.name,
              size: 42,
              color: color,
              icon: contactTypeIcon(response.nodeType),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Let the chip shrink too, so it can't squeeze the
                      // name to nothing on narrow screens or large text.
                      Flexible(
                        child: StatusChip(
                          label: contact.typeLabel(l10n).toUpperCase(),
                          color: color,
                          icon: contactTypeIcon(response.nodeType),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SignalBars(snr: response.snr, height: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.discoveredContacts_scanSignal(
                            response.snr.toStringAsFixed(1),
                            response.remoteSnr.toStringAsFixed(1),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inContacts
                        ? l10n.discoveredContacts_scanInContacts
                        : known
                        ? contact.shortPubKeyHex
                        : l10n.discoveredContacts_scanNameLater,
                    style: MeshTheme.mono(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (inContacts)
              Icon(Icons.check_circle, size: 24, color: MeshPalette.signal)
            else if (adding)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: l10n.discoveredContacts_addContact,
                icon: const Icon(Icons.person_add_alt_1),
                onPressed: response.hasFullKey ? () => _add(response) : null,
              ),
          ],
        ),
      ),
    );
  }

  bool _isKnownNode(Contact contact) =>
      contact.isActive ||
      widget.connector.discoveredContacts.any(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );
}
