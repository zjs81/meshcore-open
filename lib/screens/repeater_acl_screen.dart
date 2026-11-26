import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/contact_localization.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/repeater_command_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/app_logger.dart';
import '../utils/contact_search.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/radio_disconnected_banner.dart';

/// One entry of a repeater's access control list. The device reports only a
/// 6-byte public-key prefix per entry, so [names] joins every contact whose
/// key starts with it (empty when nothing resolves).
class AclEntry {
  final Uint8List prefix;
  final int permissions;
  final List<String> names;

  const AclEntry({
    required this.prefix,
    required this.permissions,
    this.names = const [],
  });

  String get prefixHex => prefix
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();

  String displayName(AppLocalizations l10n) =>
      names.isEmpty ? l10n.repeater_aclUnknownNode : names.join(' | ');
}

/// Parse a PUSH_CODE_BINARY_RESPONSE payload for `get acl` (REQ_TYPE
/// GET_ACCESS_LIST): repeated `[6-byte pub_key prefix][permissions byte]`
/// records (simple_repeater/MyMesh.cpp handleRequest). Trailing bytes that
/// don't form a whole record are ignored.
List<AclEntry> parseAclPayload(Uint8List payload, List<Contact> contacts) {
  final entries = <AclEntry>[];
  for (var i = 0; i + 7 <= payload.length; i += 7) {
    final prefix = Uint8List.sublistView(payload, i, i + 6);
    final permissions = payload[i + 6];
    final names = contacts
        .where(
          (c) =>
              c.publicKey.length >= 6 &&
              listEquals(c.publicKey.sublist(0, 6), prefix),
        )
        .map((c) => c.name)
        .toSet()
        .toList();
    entries.add(
      AclEntry(prefix: prefix, permissions: permissions, names: names),
    );
  }
  return entries;
}

/// Screen listing the repeater's ACL with delete and add controls.
///
/// Fetching uses the admin-only binary request (REQ_TYPE_GET_ACCESS_LIST);
/// adding and removing go through the `setperm` CLI command. `get acl` itself
/// is serial-console-only on the repeater firmware.
class RepeaterAclScreen extends StatefulWidget {
  final Contact repeater;

  const RepeaterAclScreen({super.key, required this.repeater});

  static Future<void> push(BuildContext context, {required Contact repeater}) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => RepeaterAclScreen(repeater: repeater),
      ),
    );
  }

  @override
  State<RepeaterAclScreen> createState() => _RepeaterAclScreenState();
}

class _RepeaterAclScreenState extends State<RepeaterAclScreen> {
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  Timer? _timeout;
  bool _awaitingSent = false;
  Uint8List? _tag;

  bool _isLoading = false;
  bool _busy = false;
  List<AclEntry>? _entries;

  int _resolveRepeaterIndex = -1;

  Contact _resolveRepeater(MeshCoreConnector connector) {
    if (_resolveRepeaterIndex >= 0 &&
        _resolveRepeaterIndex < connector.contacts.length &&
        connector.contacts[_resolveRepeaterIndex].publicKeyHex ==
            widget.repeater.publicKeyHex) {
      return connector.contacts[_resolveRepeaterIndex];
    }
    _resolveRepeaterIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
    );
    if (_resolveRepeaterIndex == -1) {
      return widget.repeater;
    }
    return connector.contacts[_resolveRepeaterIndex];
  }

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _frameSubscription = connector.receivedFrames.listen(_onFrame);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _frameSubscription?.cancel();
    _commandService?.dispose();
    super.dispose();
  }

  void _onFrame(Uint8List frame) {
    if (frame.isEmpty) return;

    if (frame[0] == respCodeSent && _awaitingSent && frame.length >= 10) {
      _awaitingSent = false;
      _tag = frame.sublist(2, 6);
      final est = BufferReader(frame.sublist(6)).readUInt32LE();
      _startTimeout(Duration(milliseconds: est > 0 ? est + 2000 : 10000));
      return;
    }

    if (frame[0] == pushCodeBinaryResponse &&
        _tag != null &&
        frame.length >= 6 &&
        listEquals(frame.sublist(2, 6), _tag)) {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      final entries = parseAclPayload(
        frame.sublist(6),
        connector.allContactsUnfiltered,
      );
      _timeout?.cancel();
      setState(() {
        _entries = entries;
        _isLoading = false;
        _tag = null;
      });
      return;
    }

    if (frame[0] == respCodeContactMsgRecv ||
        frame[0] == respCodeContactMsgRecvV3) {
      final parsed = parseContactMessageText(frame);
      if (parsed == null) return;
      if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;
      _commandService?.handleResponse(widget.repeater, parsed.text);
    }
  }

  void _startTimeout(Duration duration) {
    _timeout?.cancel();
    _timeout = Timer(duration, _onTimeout);
  }

  void _onTimeout() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _awaitingSent = false;
      _tag = null;
    });
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.repeater_aclLoadFailed('timeout')),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  Future<void> _load() async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    if (!connector.isConnected) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.repeater_radioDisconnected),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repeater = _resolveRepeater(connector);
      final selection = await connector.preparePathForContactSend(repeater);
      final frame = buildSendBinaryReq(
        repeater.publicKey,
        payload: Uint8List.fromList([reqTypeGetAccessList, 0, 0]),
      );
      _awaitingSent = true;
      await connector.sendFrame(frame);
      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
      final timeoutMs = connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: frame.length,
      );
      _startTimeout(Duration(milliseconds: timeoutMs));
    } catch (e) {
      appLogger.error('Error requesting ACL: $e', tag: 'RepeaterAclScreen');
      if (!mounted) return;
      setState(() => _isLoading = false);
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.repeater_aclLoadFailed(e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Send a `setperm` command and report the firmware reply. Success replies
  /// start with "OK" (or are parenthesized like "(OK)"); anything else is a
  /// failure (see CommonCLI replies).
  Future<bool> _runSetperm(String command, {required String action}) async {
    if (_commandService == null) return false;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    if (!connector.isConnected) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.repeater_radioDisconnected),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    }
    final repeater = _resolveRepeater(connector);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final response = await _commandService!.sendCommand(
        repeater,
        command,
        retries: 1,
      );
      if (!mounted) return false;
      final trimmed = response.trim();
      final lower = trimmed.toLowerCase();
      final isError =
          !(lower.startsWith('ok') || lower.startsWith('(ok')) ||
          trimmed.isEmpty;
      showDismissibleSnackBar(
        context,
        content: Text(
          isError
              ? l10n.repeater_actionFailed(action, trimmed)
              : l10n.repeater_actionSucceeded(action),
        ),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      );
      return !isError;
    } catch (e) {
      if (!mounted) return false;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.repeater_actionFailed(action, e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemove(AclEntry entry) async {
    final l10n = context.l10n;
    final name = entry.displayName(l10n);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.repeater_aclRemoveConfirmTitle),
        content: Text(l10n.repeater_aclRemoveConfirmMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.repeater_confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = await _runSetperm(
      'setperm ${entry.prefixHex} 0',
      action: l10n.repeater_aclRemoveAction(name),
    );
    if (removed && mounted) await _load();
  }

  Future<void> _openAddSheet() async {
    final l10n = context.l10n;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final selection = await showModalBottomSheet<_AclAddResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _AclAddSheet(
        candidates: connector.allContactsUnfiltered.where(
          (c) =>
              c.publicKey.length == pubKeySize &&
              c.publicKeyHex != widget.repeater.publicKeyHex,
        ),
      ),
    );
    if (selection == null || !mounted) return;
    final added = await _runSetperm(
      'setperm ${selection.pubKeyHex} ${selection.permissions}',
      action: l10n.repeater_aclAddAction,
    );
    if (added && mounted) await _load();
  }

  Color _roleColor(int permissions) => switch (permissions) {
    3 => MeshPalette.magenta,
    2 => MeshPalette.signal,
    1 => MeshPalette.blue,
    _ => MeshPalette.warn,
  };

  String _roleLabel(int permissions) => switch (permissions) {
    3 => context.l10n.repeater_aclRoleAdmin,
    2 => context.l10n.repeater_aclRoleReadWrite,
    1 => context.l10n.repeater_aclRoleReadOnly,
    _ => context.l10n.repeater_aclRoleGuest,
  };

  Widget _entryTile(AclEntry entry) {
    final l10n = context.l10n;
    return MeshCard(
      key: ValueKey(entry.prefixHex),
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        children: [
          AvatarCircle(
            name: entry.names.isEmpty ? entry.prefixHex : entry.names.first,
            size: 36,
            icon: entry.names.isEmpty ? Icons.help_outline : Icons.person,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  entry.prefixHex,
                  style: MeshTheme.mono(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: _roleLabel(entry.permissions),
            color: _roleColor(entry.permissions),
          ),
          IconButton(
            tooltip: l10n.repeater_aclRemoveTooltip,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: _busy ? null : () => _confirmRemove(entry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connected = context.watch<MeshCoreConnector>().isConnected;
    final entries = _entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.repeater_aclScreenTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: l10n.repeater_aclRefresh,
            onPressed: _isLoading || _busy || !connected ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || _isLoading || !connected ? null : _openAddSheet,
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.repeater_aclAdd),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const RadioDisconnectedBanner(),
            Expanded(
              child: _isLoading && entries == null
                  ? const Center(child: CircularProgressIndicator())
                  : entries == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.repeater_aclLoadHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.repeater_aclEmpty,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        for (final entry in entries) _entryTile(entry),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AclAddResult {
  final String pubKeyHex;
  final int permissions;

  const _AclAddResult(this.pubKeyHex, this.permissions);
}

/// Add companion sheet: role picker + name/hex search over known companions,
/// plus a manual public-key hex field.
class _AclAddSheet extends StatefulWidget {
  final Iterable<Contact> candidates;

  const _AclAddSheet({required this.candidates});

  @override
  State<_AclAddSheet> createState() => _AclAddSheetState();
}

class _AclAddSheetState extends State<_AclAddSheet> {
  final _searchController = TextEditingController();
  final _hexController = TextEditingController();
  int _permissions = 2;
  String? _hexError;

  @override
  void dispose() {
    _searchController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  List<Contact> get _matches {
    final query = _searchController.text;
    final matches = widget.candidates
        .where((c) => matchesContactQuery(c, query))
        .toList();
    matches.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return matches;
  }

  /// Accepts a full 32-byte public key as hex, tolerating the `<A1B2...>`
  /// short form brackets, an `0x` prefix and spaces.
  String? _normalizeManualHex(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('<')) {
      cleaned = cleaned.substring(1).replaceAll('>', '');
    }
    if (cleaned.toLowerCase().startsWith('0x')) {
      cleaned = cleaned.substring(2);
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '').toLowerCase();
    if (cleaned.length != pubKeySize * 2) return null;
    if (!RegExp(r'^[0-9a-f]+$').hasMatch(cleaned)) return null;
    return cleaned;
  }

  void _addManual() {
    final hex = _normalizeManualHex(_hexController.text);
    if (hex == null) {
      setState(() => _hexError = context.l10n.repeater_aclInvalidPubkey);
      return;
    }
    Navigator.pop(context, _AclAddResult(hex, _permissions));
  }

  Widget _candidateTile(Contact contact) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AvatarCircle(name: contact.name, size: 36),
      title: Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${contact.typeLabel(context.l10n)} • ${contact.shortPubKeyHex}',
      ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () => Navigator.pop(
        context,
        _AclAddResult(contact.publicKeyHex, _permissions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final matches = _matches;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.repeater_aclAdd,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          l10n.repeater_aclTileSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _permissions,
                      decoration: InputDecoration(
                        labelText: l10n.repeater_aclRole,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final perms in [1, 2, 3])
                          DropdownMenuItem(
                            value: perms,
                            child: Text(switch (perms) {
                              3 => l10n.repeater_aclRoleAdmin,
                              2 => l10n.repeater_aclRoleReadWrite,
                              _ => l10n.repeater_aclRoleReadOnly,
                            }),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _permissions = v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.repeater_aclSearch,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.repeater_aclNoCompanionsFound,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...matches.map(_candidateTile),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hexController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) {
                      if (_hexError != null) setState(() => _hexError = null);
                    },
                    decoration: InputDecoration(
                      labelText: l10n.repeater_aclManualEntry,
                      helperText: l10n.repeater_aclManualEntryHelper,
                      errorText: _hexError,
                      prefixIcon: const Icon(Icons.key),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _addManual,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.repeater_aclManualAdd),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
