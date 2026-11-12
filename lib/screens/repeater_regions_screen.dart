import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/repeater_command_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/app_logger.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/radio_disconnected_banner.dart';

/// One region defined on a repeater. `*` is the wildcard (unscoped) region,
/// which can toggle flooding but cannot be removed.
class RepeaterRegionEntry {
  final String name;
  final bool floodAllowed;

  const RepeaterRegionEntry({required this.name, required this.floodAllowed});

  bool get isWildcard => name == '*';

  String displayName(AppLocalizations l10n) =>
      isWildcard ? l10n.repeater_regionsWildcard : name;
}

/// Parses a `region list allowed` / `region list denied` reply: comma-separated
/// names, `-none-` when empty. A leading `#` (hashtag region) is stripped so
/// names round-trip into `region put`.
List<String> parseRepeaterRegionNames(String reply) {
  final trimmed = reply.trim();
  if (trimmed.isEmpty || trimmed == '-none-') return const [];
  return trimmed
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty && name != '-none-')
      .map((name) => name.startsWith('#') ? name.substring(1) : name)
      .toList();
}

/// Parses `region home` / `region home <name>` replies ("home is eu",
/// "home is now eu"). `*` means no home region and parses as null.
String? parseRepeaterRegionHome(String reply) {
  final match = RegExp(r'home is (?:now )?(.+)$').firstMatch(reply.trim());
  final name = match?.group(1)?.trim();
  if (name == null || name.isEmpty || name == '*') return null;
  return name;
}

/// Parses `region default` / `region default <name>` replies ("default scope
/// is eu", "default scope is now eu"). `<null>` parses as null.
String? parseRepeaterRegionDefault(String reply) {
  final match = RegExp(
    r'default scope is (?:now )?(.+)$',
  ).firstMatch(reply.trim());
  final name = match?.group(1)?.trim();
  if (name == null || name.isEmpty || name == '<null>') return null;
  return name;
}

/// Firmware region failures are `Err - ...`; anything else that is empty is
/// treated as a failure too.
bool isRepeaterRegionError(String reply) {
  final lower = reply.trim().toLowerCase();
  return lower.isEmpty || lower.startsWith('err');
}

/// Screen to manage a repeater's regions: list, add, remove, flood
/// permission, home region and default scope.
///
/// Everything goes through the repeater CLI (`region list/home/default/put/
/// remove/allowf/denyf/save`); edits are persisted with `region save` so they
/// survive a reboot. Requires admin access to the repeater and firmware 1.12
/// or later (where `region list` exists).
class RepeaterRegionsScreen extends StatefulWidget {
  final Contact repeater;

  const RepeaterRegionsScreen({super.key, required this.repeater});

  static Future<void> push(BuildContext context, {required Contact repeater}) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => RepeaterRegionsScreen(repeater: repeater),
      ),
    );
  }

  @override
  State<RepeaterRegionsScreen> createState() => _RepeaterRegionsScreenState();
}

class _RepeaterRegionsScreenState extends State<RepeaterRegionsScreen> {
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;

  bool _isLoading = false;
  bool _busy = false;
  List<RepeaterRegionEntry>? _entries;
  String? _homeRegion;
  String? _defaultRegion;

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
    _frameSubscription?.cancel();
    _commandService?.dispose();
    super.dispose();
  }

  void _onFrame(Uint8List frame) {
    if (frame.isEmpty) return;
    if (frame[0] == respCodeContactMsgRecv ||
        frame[0] == respCodeContactMsgRecvV3) {
      final parsed = parseContactMessageText(frame);
      if (parsed == null) return;
      if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;
      _commandService?.handleResponse(widget.repeater, parsed.text);
    }
  }

  bool _ensureConnected() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    if (connector.isConnected) return true;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.repeater_radioDisconnected),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
    return false;
  }

  Future<String> _send(String command) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    return _commandService!.sendCommand(repeater, command, retries: 1);
  }

  Future<void> _load() async {
    if (_commandService == null) return;
    if (!_ensureConnected()) return;
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    try {
      final allowed = await _send('region list allowed');
      final denied = await _send('region list denied');
      if (!mounted) return;
      final allowedOk = !isRepeaterRegionError(allowed);
      final deniedOk = !isRepeaterRegionError(denied);
      if (!allowedOk && !deniedOk) {
        setState(() => _isLoading = false);
        showDismissibleSnackBar(
          context,
          content: Text(
            l10n.repeater_regionsLoadFailed(
              denied.trim().isEmpty ? 'unknown' : denied.trim(),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
        return;
      }
      final entries = <RepeaterRegionEntry>[
        for (final name in parseRepeaterRegionNames(allowedOk ? allowed : ''))
          RepeaterRegionEntry(name: name, floodAllowed: true),
        for (final name in parseRepeaterRegionNames(deniedOk ? denied : ''))
          RepeaterRegionEntry(name: name, floodAllowed: false),
      ];
      entries.sort((a, b) {
        if (a.isWildcard != b.isWildcard) return a.isWildcard ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      String? home;
      String? defaultRegion;
      try {
        home = parseRepeaterRegionHome(await _send('region home'));
      } catch (e) {
        appLogger.error(
          'Error loading home region: $e',
          tag: 'RepeaterRegionsScreen',
        );
      }
      try {
        defaultRegion = parseRepeaterRegionDefault(
          await _send('region default'),
        );
      } catch (e) {
        appLogger.error(
          'Error loading default region: $e',
          tag: 'RepeaterRegionsScreen',
        );
      }
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _homeRegion = home;
        _defaultRegion = defaultRegion;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showDismissibleSnackBar(
        context,
        content: Text(l10n.repeater_regionsLoadFailed(e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Runs a region edit, persists it with `region save` unless [persist] is
  /// false (the firmware saves `region default` itself), and reports the
  /// outcome through a snackbar.
  Future<bool> _runRegionCommand(
    String command,
    String action, {
    bool persist = true,
  }) async {
    if (_commandService == null) return false;
    if (!_ensureConnected()) return false;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final response = await _send(command);
      var ok = !isRepeaterRegionError(response);
      if (ok && persist) {
        final saved = await _send('region save');
        ok = !isRepeaterRegionError(saved);
      }
      if (!mounted) return false;
      showDismissibleSnackBar(
        context,
        content: Text(
          ok
              ? l10n.repeater_actionSucceeded(action)
              : l10n.repeater_actionFailed(action, response.trim()),
        ),
        backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
      );
      return ok;
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

  Future<void> _toggleFlood(RepeaterRegionEntry entry) async {
    final l10n = context.l10n;
    final command =
        '${entry.floodAllowed ? 'denyf' : 'allowf'} ${entry.isWildcard ? '*' : entry.name}';
    final action = entry.floodAllowed
        ? l10n.repeater_regionsFloodDenyTooltip
        : l10n.repeater_regionsFloodAllowTooltip;
    final done = await _runRegionCommand(command, action);
    if (done && mounted) await _load();
  }

  Future<void> _confirmRemove(RepeaterRegionEntry entry) async {
    final l10n = context.l10n;
    final name = entry.displayName(l10n);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.repeater_regionsRemoveConfirmTitle),
        content: Text(l10n.repeater_regionsRemoveConfirmMessage(name)),
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
    final removed = await _runRegionCommand(
      'region remove ${entry.name}',
      l10n.repeater_regionsRemoveAction(name),
    );
    if (removed && mounted) await _load();
  }

  Future<void> _showAddDialog() async {
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddRegionDialog(),
    );
    if (name == null || !mounted) return;
    final added = await _runRegionCommand(
      'region put $name',
      l10n.repeater_regionsAddAction,
    );
    if (added && mounted) await _load();
  }

  Future<void> _setHomeRegion(String? name) async {
    if (name == _homeRegion) return;
    final l10n = context.l10n;
    final command = 'region home ${name ?? '*'}';
    final done = await _runRegionCommand(command, l10n.repeater_regionsHome);
    if (done && mounted) await _load();
  }

  Future<void> _setDefaultRegion(String? name) async {
    if (name == _defaultRegion) return;
    final l10n = context.l10n;
    // The firmware persists default scope changes itself.
    final command = 'region default ${name ?? '<null>'}';
    final done = await _runRegionCommand(
      command,
      l10n.repeater_regionsDefault,
      persist: false,
    );
    if (done && mounted) await _load();
  }

  Widget _buildScopeSelector({
    required String label,
    required String helper,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final l10n = context.l10n;
    final choices = <String>{...options, ?value}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label:$value'),
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(
              l10n.repeater_regionsDefaultNone,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final option in choices)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _busy || _isLoading ? null : onChanged,
      ),
    );
  }

  Widget _buildScopeCard(List<RepeaterRegionEntry> entries) {
    final l10n = context.l10n;
    final options = entries
        .where((entry) => !entry.isWildcard)
        .map((entry) => entry.name)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScopeSelector(
          label: l10n.repeater_regionsHome,
          helper: l10n.repeater_regionsHomeHelper,
          value: _homeRegion,
          options: options,
          onChanged: _setHomeRegion,
        ),
        _buildScopeSelector(
          label: l10n.repeater_regionsDefault,
          helper: l10n.repeater_regionsDefaultHelper,
          value: _defaultRegion,
          options: options,
          onChanged: _setDefaultRegion,
        ),
      ],
    );
  }

  Widget _buildRegionTile(RepeaterRegionEntry entry) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return MeshCard(
      key: ValueKey(entry.name),
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        children: [
          Icon(
            Icons.landscape,
            color: entry.isWildcard
                ? scheme.onSurfaceVariant
                : MeshPalette.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName(l10n),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusChip(
            label: entry.floodAllowed
                ? l10n.repeater_regionsFloodAllowed
                : l10n.repeater_regionsFloodDenied,
            color: entry.floodAllowed ? MeshPalette.signal : MeshPalette.warn,
          ),
          IconButton(
            tooltip: entry.floodAllowed
                ? l10n.repeater_regionsFloodDenyTooltip
                : l10n.repeater_regionsFloodAllowTooltip,
            icon: Icon(
              entry.floodAllowed ? Icons.block : Icons.check_circle_outline,
              color: entry.floodAllowed ? scheme.error : MeshPalette.signal,
            ),
            onPressed: _busy ? null : () => _toggleFlood(entry),
          ),
          if (!entry.isWildcard)
            IconButton(
              tooltip: l10n.repeater_regionsRemoveTooltip,
              icon: Icon(Icons.delete_outline, color: scheme.error),
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
        title: Text(l10n.repeater_regionsScreenTitle),
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
            tooltip: l10n.repeater_regionsRefresh,
            onPressed: _isLoading || _busy || !connected ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || _isLoading || !connected ? null : _showAddDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.repeater_regionsAdd),
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
                          l10n.repeater_regionsLoadHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        MeshCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildScopeCard(entries),
                        ),
                        if (entries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.repeater_regionsEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          for (final entry in entries) _buildRegionTile(entry),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Region-name entry, restricted to the characters the firmware accepts
/// (lowercase letters, digits and hyphens, up to 30 characters).
class _AddRegionDialog extends StatefulWidget {
  const _AddRegionDialog();

  @override
  State<_AddRegionDialog> createState() => _AddRegionDialogState();
}

class _AddRegionDialogState extends State<_AddRegionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.settings_regionName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: l10n.settings_regionNameHint,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp("[a-z0-9-]")),
        ],
        maxLength: 30,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => TextButton(
            onPressed: _controller.text.trim().isEmpty ? null : _submit,
            child: Text(l10n.common_add),
          ),
        ),
      ],
    );
  }
}
