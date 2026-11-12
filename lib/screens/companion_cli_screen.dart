import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/helpers/snack_bar_builder.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/confirm_clear_dialog.dart';
import 'package:meshcore_open/widgets/radio_disconnected_banner.dart';
import 'package:provider/provider.dart';

Future<void> pushCompanionCliScreen(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (context) => const CompanionCliScreen()),
  );
}

/// Local CLI console for the connected companion radio (CMD_RUN_CLI_COMMAND,
/// firmware v1.18+). Commands run on the radio itself; nothing is sent over
/// the mesh.
class CompanionCliScreen extends StatefulWidget {
  const CompanionCliScreen({super.key});

  @override
  State<CompanionCliScreen> createState() => _CompanionCliScreenState();
}

class _CompanionCliScreenState extends State<CompanionCliScreen> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _commandHistory = [];
  int _historyIndex = -1;
  bool _sending = false;

  static const List<String> _quickCommands = [
    'ver',
    'board',
    'get radio',
    'get tx',
    'get radio.rxgain',
    'get freq',
  ];

  @override
  void dispose() {
    _commandController.dispose();
    _commandFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendCommand([String? command]) async {
    final text = (command ?? _commandController.text).trim();
    if (text.isEmpty || _sending) return;
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    setState(() {
      _commandHistory.add({'type': 'command', 'text': text});
      _sending = true;
    });
    _commandController.clear();
    _historyIndex = -1;
    _commandFocusNode.requestFocus();

    String response;
    try {
      response = await connector.runCliCommand(text);
    } on TimeoutException catch (_) {
      response = l10n.companionCli_noReply;
    } catch (e) {
      response = l10n.repeater_cliCommandError(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _commandHistory.add({'type': 'response', 'text': response});
    });
    _scrollToBottom();
  }

  void _navigateHistory(bool up) {
    final commands = _commandHistory
        .where((entry) => entry['type'] == 'command')
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    if (commands.isEmpty) return;

    if (up) {
      if (_historyIndex < commands.length - 1) {
        _historyIndex++;
      }
    } else {
      if (_historyIndex > 0) {
        _historyIndex--;
      } else {
        _historyIndex = -1;
        _commandController.clear();
        return;
      }
    }

    if (_historyIndex >= 0 && _historyIndex < commands.length) {
      _commandController.text = commands[_historyIndex]['text'] ?? '';
      _commandController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commandController.text.length),
      );
    }
  }

  void _clearHistory() {
    setState(() {
      _commandHistory.clear();
      _historyIndex = -1;
    });
  }

  Future<void> _confirmClearHistory() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmClearDialog(
      context,
      title: l10n.repeater_clearHistory,
      message: l10n.repeater_cliClearHistoryConfirm,
    );
    if (confirmed && mounted) _clearHistory();
  }

  String _transcriptText() {
    return _commandHistory
        .map(
          (entry) => entry['type'] == 'command'
              ? '> ${entry['text']}'
              : (entry['text'] ?? ''),
        )
        .join('\n');
  }

  Future<void> _copyTranscript() async {
    if (_commandHistory.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _transcriptText()));
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.repeater_cliTranscriptCopied),
    );
  }

  void _scrollToBottom() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final connector = context.watch<MeshCoreConnector>();
    final connected = connector.isConnected && connector.supportsCompanionCli;
    final accent = scheme.primary;
    final hasHistory = _commandHistory.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        title: Text(l10n.companionCli_title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: l10n.repeater_cliTranscriptCopied,
            onPressed: hasHistory ? _copyTranscript : null,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.repeater_clearHistory,
            onPressed: hasHistory ? _confirmClearHistory : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: scheme.surfaceContainer,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickCommands.map((command) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        command,
                        style: MeshTheme.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      backgroundColor: accent.withValues(alpha: 0.12),
                      side: BorderSide(color: accent.withValues(alpha: 0.5)),
                      onPressed: _sending || !connected
                          ? null
                          : () => _sendCommand(command),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight / 2,
                    ),
                    child: const SingleChildScrollView(
                      child: RadioDisconnectedBanner(),
                    ),
                  ),
                  Expanded(
                    child: _commandHistory.isEmpty
                        ? _buildEmptyState()
                        : _buildCommandHistory(),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Container(
            color: scheme.surfaceContainer,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_upward,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip: l10n.repeater_previousCommand,
                    onPressed: () => _navigateHistory(true),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_downward,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip: l10n.repeater_nextCommand,
                    onPressed: () => _navigateHistory(false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      focusNode: _commandFocusNode,
                      style: MeshTheme.mono(
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.repeater_enterCommandHint,
                        hintStyle: MeshTheme.mono(
                          fontSize: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        prefixText: '> ',
                        prefixStyle: MeshTheme.mono(
                          fontSize: 15,
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MeshRadii.pill),
                          borderSide: BorderSide(color: scheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MeshRadii.pill),
                          borderSide: BorderSide(color: scheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MeshRadii.pill),
                          borderSide: BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (connected && !_sending) _sendCommand();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: _sending
                        ? Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: accent,
                              ),
                            ),
                          )
                        : IconButton.filledTonal(
                            tooltip: l10n.repeater_cliSend,
                            icon: const Icon(Icons.send, size: 24),
                            onPressed: connected
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _sendCommand();
                                  }
                                : null,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              l10n.repeater_noCommandsSent,
              textAlign: TextAlign.center,
              style: MeshTheme.mono(fontSize: 15, color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.repeater_typeCommandOrUseQuick,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandHistory() {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _commandHistory.length,
      itemBuilder: (context, index) {
        final entry = _commandHistory[index];
        final isCommand = entry['type'] == 'command';

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  isCommand ? '>' : ' ',
                  style: MeshTheme.mono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCommand ? accent : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  entry['text']!,
                  style: MeshTheme.mono(
                    fontSize: 14,
                    color: isCommand ? accent : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
