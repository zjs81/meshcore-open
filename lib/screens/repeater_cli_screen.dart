import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../theme/mesh_theme.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../widgets/debug_frame_viewer.dart';
import '../widgets/radio_disconnected_banner.dart';
import '../services/repeater_command_service.dart';
import '../widgets/routing_sheet.dart';
import '../helpers/snack_bar_builder.dart';

class RepeaterCliScreen extends StatefulWidget {
  final Contact repeater;
  final String password;

  const RepeaterCliScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  State<RepeaterCliScreen> createState() => _RepeaterCliScreenState();
}

class _RepeaterCliScreenState extends State<RepeaterCliScreen> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _commandHistory = [];
  int _historyIndex = -1;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  bool _regionLoadActive = false;
  static final RegExp _regionLoadPattern = RegExp(r'^region +load( |$)');

  late final List<Map<String, String>> _quickCommands = [
    {'labelKey': 'advertise', 'command': 'advert'},
    {'labelKey': 'getName', 'command': 'get name'},
    {'labelKey': 'getRadio', 'command': 'get radio'},
    {'labelKey': 'getTx', 'command': 'get tx'},
    {'labelKey': 'discovery', 'command': 'discover.neighbors'},
    {'labelKey': 'neighbors', 'command': 'neighbors'},
    {'labelKey': 'version', 'command': 'ver'},
    {'labelKey': 'clock', 'command': 'clock'},
    {'labelKey': 'clock sync', 'command': 'clock sync'},
  ];

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _commandService?.dispose();
    _commandController.dispose();
    _commandFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupMessageListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] == respCodeContactMsgRecv ||
          frame[0] == respCodeContactMsgRecvV3) {
        _handleTextMessageResponse(frame);
      }
    });
  }

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

  void _handleTextMessageResponse(Uint8List frame) {
    final parsed = parseContactMessageText(frame);
    if (parsed == null) return;
    if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;
    _commandService?.handleResponse(widget.repeater, parsed.text);
  }

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  void _sendCommand({bool showDebug = false}) async {
    if (_regionLoadActive) {
      _sendRegionLoadLine();
      return;
    }
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    final startsRegionLoad = _regionLoadPattern.hasMatch(command.toLowerCase());

    setState(() {
      _commandHistory.add({
        'type': 'command',
        'text': command,
        'timestamp': DateTime.now().toString(),
      });
      // The repeater enters load mode as soon as it receives the command, and
      // its reply may take a full timeout (or be lost). Switch modes now so
      // lines typed meanwhile go out verbatim instead of as `XX|` commands; a
      // blank line always ends it safely.
      if (startsRegionLoad) {
        _regionLoadActive = true;
        _commandHistory.add({
          'type': 'response',
          'text': context.l10n.repeater_cliRegionLoadActive,
          'timestamp': DateTime.now().toString(),
        });
      }
    });
    _commandController.clear();
    _historyIndex = -1;
    _commandFocusNode.requestFocus();

    if (showDebug && mounted && _commandService != null) {
      // Preview the exact framed text the service sends (`XX|` prefix and
      // clock-sync rewrite), not the bare command.
      final frame = buildSendCliCommandFrame(
        widget.repeater.publicKey,
        _commandService!.previewFramedCommand(command),
      );
      DebugFrameViewer.showFrameDebug(
        context,
        frame,
        context.l10n.repeater_cliCommandFrameTitle,
      );
    }

    try {
      if (_commandService != null) {
        final connector = Provider.of<MeshCoreConnector>(
          context,
          listen: false,
        );
        final repeater = _resolveRepeater(connector);
        final response = await _commandService!.sendCommand(
          repeater,
          command,
          retries: 1,
        );
        if (mounted) {
          setState(() {
            _commandHistory.add({
              'type': 'response',
              'text': response,
              'timestamp': DateTime.now().toString(),
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commandHistory.add({
            'type': 'response',
            'text': context.l10n.repeater_cliCommandError(e.toString()),
            'timestamp': DateTime.now().toString(),
          });
        });
      }
    }

    _scrollToBottom();
  }

  /// In `region load` mode lines go out verbatim: no `XX|` prefix and no
  /// trimming, since indentation encodes the parent. Region lines get no
  /// reply; a blank line commits the load and is answered with
  /// "OK - loaded N regions".
  Future<void> _sendRegionLoadLine() async {
    final line = _commandController.text;
    final isTerminator = line.trim().isEmpty;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    setState(() {
      _commandHistory.add({
        'type': 'command',
        'text': isTerminator ? context.l10n.repeater_cliRegionLoadEnd : line,
        'timestamp': DateTime.now().toString(),
      });
    });
    _commandController.clear();
    _historyIndex = -1;
    _commandFocusNode.requestFocus();

    String? response;
    var ended = false;
    try {
      if (isTerminator) {
        response = await _commandService!.sendCommand(
          repeater,
          '',
          retries: 1,
          raw: true,
        );
        ended = true;
      } else {
        await _commandService!.sendUnansweredLine(repeater, line);
      }
    } catch (e) {
      if (mounted) {
        response = context.l10n.repeater_cliCommandError(e.toString());
      }
    }
    if (!mounted) return;
    setState(() {
      if (ended) _regionLoadActive = false;
      if (response != null) {
        _commandHistory.add({
          'type': 'response',
          'text': response,
          'timestamp': DateTime.now().toString(),
        });
      }
    });
    _scrollToBottom();
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

  void _useQuickCommand(String command) {
    _commandController.text = command;
    _sendCommand();
  }

  void _navigateHistory(bool up) {
    final commands = _commandHistory
        .where((entry) => entry['type'] == 'command')
        .toList()
        .reversed
        .toList();

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

  Future<void> _shareTranscript() async {
    if (_commandHistory.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _transcriptText(),
        subject: '${context.l10n.repeater_cliTitle} - ${widget.repeater.name}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  String _quickCommandLabel(String key) {
    final l10n = context.l10n;
    switch (key) {
      case 'getName':
        return l10n.repeater_cliQuickGetName;
      case 'getRadio':
        return l10n.repeater_cliQuickGetRadio;
      case 'getTx':
        return l10n.repeater_cliQuickGetTx;
      case 'neighbors':
        return l10n.repeater_cliQuickNeighbors;
      case 'version':
        return l10n.repeater_cliQuickVersion;
      case 'advertise':
        return l10n.repeater_cliQuickAdvertise;
      case 'clock':
        return l10n.repeater_cliQuickClock;
      case 'clock sync':
        return l10n.repeater_cliQuickClockSync;
      case 'discovery':
        return l10n.repeater_cliQuickDiscovery;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;
    final connected = connector.isConnected;
    final accent = scheme.primary;
    final hasHistory = _commandHistory.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        title: Text(l10n.repeater_cliTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isFloodMode ? Icons.waves : Icons.route),
            tooltip: l10n.repeater_routingMode,
            onPressed: () =>
                ContactRoutingSheet.show(context, contact: repeater),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.repeater_commandHelp,
            onPressed: () => _showCommandHelp(context),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.repeater_clearHistory,
            onPressed: hasHistory ? _confirmClearHistory : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'debug':
                  if (_commandController.text.trim().isNotEmpty) {
                    _sendCommand(showDebug: true);
                  } else {
                    showDismissibleSnackBar(
                      context,
                      content: Text(l10n.repeater_enterCommandFirst),
                    );
                  }
                case 'copy':
                  _copyTranscript();
                case 'share':
                  _shareTranscript();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy',
                enabled: hasHistory,
                child: Row(
                  children: [
                    const Icon(Icons.copy),
                    const SizedBox(width: 8),
                    Text(l10n.repeater_cliCopyTranscript),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                enabled: hasHistory,
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text(l10n.repeater_cliShareTranscript),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'debug',
                enabled: connected,
                child: Row(
                  children: [
                    const Icon(Icons.bug_report),
                    const SizedBox(width: 8),
                    Text(l10n.repeater_debugNextCommand),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick commands bar
          Container(
            color: scheme.surfaceContainer,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickCommands.map((cmd) {
                  final label = _quickCommandLabel(cmd['labelKey']!);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        label,
                        style: MeshTheme.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      backgroundColor: accent.withValues(alpha: 0.12),
                      side: BorderSide(color: accent.withValues(alpha: 0.5)),
                      onPressed: _regionLoadActive || !connected
                          ? null
                          : () => _useQuickCommand(cmd['command']!),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),

          // Output area
          // The disconnected banner lives in the output area and is capped at
          // half of it, so large text or an open keyboard can't push the
          // command input off screen.
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

          // Command input
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
                        hintText: _regionLoadActive
                            ? context.l10n.repeater_cliRegionLoadHint
                            : context.l10n.repeater_enterCommandHint,
                        hintStyle: MeshTheme.mono(
                          fontSize: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        prefixText: _regionLoadActive ? '' : '> ',
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
                        if (connected) _sendCommand();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filledTonal(
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
              // Gutter prefix
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

  void _applyHelpCommand(String command) {
    _commandController.text = command;
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: command.length),
    );
    Navigator.pop(context);
    Future.microtask(() {
      if (mounted) {
        _commandFocusNode.requestFocus();
      }
    });
  }

  void _showCommandHelp(BuildContext context) {
    final l10n = context.l10n;
    final generalCommands = [
      _CommandHelpEntry(
        command: 'advert',
        description: l10n.repeater_cliHelpAdvert,
      ),
      _CommandHelpEntry(
        command: 'reboot',
        description: l10n.repeater_cliHelpReboot,
      ),
      _CommandHelpEntry(
        command: 'clock',
        description: l10n.repeater_cliHelpClock,
      ),
      _CommandHelpEntry(
        command: 'password {new-password}',
        description: l10n.repeater_cliHelpPassword,
      ),
      _CommandHelpEntry(
        command: 'ver',
        description: l10n.repeater_cliHelpVersion,
      ),
      _CommandHelpEntry(
        command: 'clear stats',
        description: l10n.repeater_cliHelpClearStats,
      ),
      _CommandHelpEntry(
        command: 'poweroff',
        description: l10n.repeater_cliHelpPowerOff,
      ),
      _CommandHelpEntry(
        command: 'shutdown',
        description: l10n.repeater_cliHelpPowerOff,
      ),
      _CommandHelpEntry(
        command: 'clkreboot',
        description: l10n.repeater_cliHelpClkReboot,
      ),
      _CommandHelpEntry(
        command: 'advert.zerohop',
        description: l10n.repeater_cliHelpAdvertZeroHop,
      ),
      _CommandHelpEntry(
        command: 'start ota',
        description: l10n.repeater_cliHelpStartOta,
      ),
      _CommandHelpEntry(
        command: 'time {epoch-seconds}',
        description: l10n.repeater_cliHelpTime,
      ),
      _CommandHelpEntry(
        command: 'board',
        description: l10n.repeater_cliHelpBoard,
      ),
      _CommandHelpEntry(
        command: 'discover.neighbors',
        description: l10n.repeater_cliHelpDiscoverNeighbors,
      ),
      _CommandHelpEntry(
        command: 'powersaving',
        description: l10n.repeater_cliHelpPowersaving,
      ),
      _CommandHelpEntry(
        command: 'powersaving {on|off}',
        description: l10n.repeater_cliHelpPowersavingOnOff,
      ),
    ];

    final settingsCommands = [
      _CommandHelpEntry(
        command: 'set af {air-time-factor}',
        description: l10n.repeater_cliHelpSetAf,
      ),
      _CommandHelpEntry(
        command: 'set tx {tx-power-dbm}',
        description: l10n.repeater_cliHelpSetTx,
      ),
      _CommandHelpEntry(
        command: 'set repeat {on|off}',
        description: l10n.repeater_cliHelpSetRepeat,
      ),
      _CommandHelpEntry(
        command: 'set allow.read.only {on|off}',
        description: l10n.repeater_cliHelpSetAllowReadOnly,
      ),
      _CommandHelpEntry(
        command: 'set flood.max {max-hops}',
        description: l10n.repeater_cliHelpSetFloodMax,
      ),
      _CommandHelpEntry(
        command: 'set flood.max.unscoped {0-64}',
        description: l10n.repeater_cliHelpSetFloodMaxUnscoped,
      ),
      _CommandHelpEntry(
        command: 'set flood.max.advert {0-64}',
        description: l10n.repeater_cliHelpSetFloodMaxAdvert,
      ),
      _CommandHelpEntry(
        command: 'set int.thresh {db}',
        description: l10n.repeater_cliHelpSetIntThresh,
      ),
      _CommandHelpEntry(
        command: 'set agc.reset.interval {seconds}',
        description: l10n.repeater_cliHelpSetAgcResetInterval,
      ),
      _CommandHelpEntry(
        command: 'set multi.acks {0|1}',
        description: l10n.repeater_cliHelpSetMultiAcks,
      ),
      _CommandHelpEntry(
        command: 'set advert.interval {minutes}',
        description: l10n.repeater_cliHelpSetAdvertInterval,
      ),
      _CommandHelpEntry(
        command: 'set flood.advert.interval {hours}',
        description: l10n.repeater_cliHelpSetFloodAdvertInterval,
      ),
      _CommandHelpEntry(
        command: 'set guest.password {guess-password}',
        description: l10n.repeater_cliHelpSetGuestPassword,
      ),
      _CommandHelpEntry(
        command: 'set name {name}',
        description: l10n.repeater_cliHelpSetName,
      ),
      _CommandHelpEntry(
        command: 'set lat {latitude}',
        description: l10n.repeater_cliHelpSetLat,
      ),
      _CommandHelpEntry(
        command: 'set lon {longitude}',
        description: l10n.repeater_cliHelpSetLon,
      ),
      _CommandHelpEntry(
        command: 'set radio {freq},{bw},{sf},{cr}',
        description: l10n.repeater_cliHelpSetRadio,
      ),
      _CommandHelpEntry(
        command: 'set rxdelay {base}',
        description: l10n.repeater_cliHelpSetRxDelay,
      ),
      _CommandHelpEntry(
        command: 'set txdelay {factor}',
        description: l10n.repeater_cliHelpSetTxDelay,
      ),
      _CommandHelpEntry(
        command: 'set direct.txdelay {factor}',
        description: l10n.repeater_cliHelpSetDirectTxDelay,
      ),
      _CommandHelpEntry(
        command: 'set adc.multiplier {factor}',
        description: l10n.repeater_cliHelpSetAdcMultiplier,
      ),
      _CommandHelpEntry(
        command: 'tempradio {freq},{bw},{sf},{cr},{minutes}',
        description: l10n.repeater_cliHelpTempRadio,
      ),
      _CommandHelpEntry(
        command: 'setperm {pubkey-hex} {permissions}',
        description: l10n.repeater_cliHelpSetPerm,
      ),
      _CommandHelpEntry(
        command: 'set dutycycle {1-100}',
        description: l10n.repeater_cliHelpSetDutyCycle,
      ),
      _CommandHelpEntry(
        command: 'set prv.key {hex}',
        description: l10n.repeater_cliHelpSetPrvKey,
      ),
      _CommandHelpEntry(
        command: 'set radio.rxgain {on|off}',
        description: l10n.repeater_cliHelpSetRadioRxGain,
      ),
      _CommandHelpEntry(
        command: 'set radio.fem.rxgain {on|off}',
        description: l10n.repeater_cliHelpSetRadioFemRxGain,
      ),
      _CommandHelpEntry(
        command: 'set radio.fem.txgain {on|off}',
        description: l10n.repeater_cliHelpSetRadioFemTxGain,
      ),
      _CommandHelpEntry(
        command: 'set owner.info {text}',
        description: l10n.repeater_cliHelpSetOwnerInfo,
      ),
      _CommandHelpEntry(
        command: 'set path.hash.mode {0|1|2}',
        description: l10n.repeater_cliHelpSetPathHashMode,
      ),
      _CommandHelpEntry(
        command: 'set loop.detect {off|minimal|moderate|strict}',
        description: l10n.repeater_cliHelpSetLoopDetect,
      ),
    ];

    final bridgeCommands = [
      _CommandHelpEntry(
        command: 'set bridge.enabled {on|off}',
        description: l10n.repeater_cliHelpSetBridgeEnabled,
      ),
      _CommandHelpEntry(
        command: 'set bridge.delay {0-10000}',
        description: l10n.repeater_cliHelpSetBridgeDelay,
      ),
      _CommandHelpEntry(
        command: 'set bridge.source {rx|tx}',
        description: l10n.repeater_cliHelpSetBridgeSource,
      ),
      _CommandHelpEntry(
        command: 'set bridge.baud {speed}',
        description: l10n.repeater_cliHelpSetBridgeBaud,
      ),
      _CommandHelpEntry(
        command: 'set bridge.secret {shared-secret}',
        description: l10n.repeater_cliHelpSetBridgeSecret,
      ),
      _CommandHelpEntry(
        command: 'set bridge.channel {1-14}',
        description: l10n.repeater_cliHelpSetBridgeChannel,
      ),
      _CommandHelpEntry(
        command: 'get bridge.enabled',
        description: l10n.repeater_cliHelpGetBridgeEnabled,
      ),
      _CommandHelpEntry(
        command: 'get bridge.delay',
        description: l10n.repeater_cliHelpGetBridgeDelay,
      ),
      _CommandHelpEntry(
        command: 'get bridge.source',
        description: l10n.repeater_cliHelpGetBridgeSource,
      ),
      _CommandHelpEntry(
        command: 'get bridge.baud',
        description: l10n.repeater_cliHelpGetBridgeBaud,
      ),
      _CommandHelpEntry(
        command: 'get bridge.channel',
        description: l10n.repeater_cliHelpGetBridgeChannel,
      ),
      _CommandHelpEntry(
        command: 'get bridge.secret',
        description: l10n.repeater_cliHelpGetBridgeSecret,
      ),
      _CommandHelpEntry(
        command: 'get bridge.type',
        description: l10n.repeater_cliHelpGetBridgeType,
      ),
    ];

    final loggingCommands = [
      _CommandHelpEntry(
        command: 'log start',
        description: l10n.repeater_cliHelpLogStart,
      ),
      _CommandHelpEntry(
        command: 'log stop',
        description: l10n.repeater_cliHelpLogStop,
      ),
      _CommandHelpEntry(
        command: 'log erase',
        description: l10n.repeater_cliHelpLogErase,
      ),
    ];

    final neighborCommands = [
      _CommandHelpEntry(
        command: 'neighbors',
        description: l10n.repeater_cliHelpNeighbors,
      ),
      _CommandHelpEntry(
        command: 'neighbor.remove {pubkey-prefix}',
        description: l10n.repeater_cliHelpNeighborRemove,
      ),
    ];

    final regionCommands = [
      _CommandHelpEntry(
        command: 'region',
        description: l10n.repeater_cliHelpRegion,
      ),
      _CommandHelpEntry(
        command: 'region load',
        description: l10n.repeater_cliHelpRegionLoad,
      ),
      _CommandHelpEntry(
        command: 'region def {name}[,{jump-prefix}] ...',
        description: l10n.repeater_cliHelpRegionDef,
      ),
      _CommandHelpEntry(
        command: 'region get {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionGet,
      ),
      _CommandHelpEntry(
        command: 'region put {name} {* | parent-name-prefix}',
        description: l10n.repeater_cliHelpRegionPut,
      ),
      _CommandHelpEntry(
        command: 'region remove {name}',
        description: l10n.repeater_cliHelpRegionRemove,
      ),
      _CommandHelpEntry(
        command: 'region allowf {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionAllowf,
      ),
      _CommandHelpEntry(
        command: 'region denyf {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionDenyf,
      ),
      _CommandHelpEntry(
        command: 'region home',
        description: l10n.repeater_cliHelpRegionHome,
      ),
      _CommandHelpEntry(
        command: 'region home {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionHomeSet,
      ),
      _CommandHelpEntry(
        command: 'region save',
        description: l10n.repeater_cliHelpRegionSave,
      ),
      _CommandHelpEntry(
        command: 'region default',
        description: l10n.repeater_cliHelpRegionDefault,
      ),
      _CommandHelpEntry(
        command: 'region default {* | name-prefix | <null>}',
        description: l10n.repeater_cliHelpRegionDefaultSet,
      ),
      _CommandHelpEntry(
        command: 'region list allowed',
        description: l10n.repeater_cliHelpRegionListAllowed,
      ),
      _CommandHelpEntry(
        command: 'region list denied',
        description: l10n.repeater_cliHelpRegionListDenied,
      ),
    ];

    final getCommands = [
      _CommandHelpEntry(
        command: 'get name',
        description: l10n.repeater_cliHelpGetName,
      ),
      _CommandHelpEntry(
        command: 'get role',
        description: l10n.repeater_cliHelpGetRole,
      ),
      _CommandHelpEntry(
        command: 'get public.key',
        description: l10n.repeater_cliHelpGetPublicKey,
      ),
      _CommandHelpEntry(
        command: 'get repeat',
        description: l10n.repeater_cliHelpGetRepeat,
      ),
      _CommandHelpEntry(
        command: 'get tx',
        description: l10n.repeater_cliHelpGetTx,
      ),
      _CommandHelpEntry(
        command: 'get freq',
        description: l10n.repeater_cliHelpGetFreq,
      ),
      _CommandHelpEntry(
        command: 'get radio',
        description: l10n.repeater_cliHelpGetRadio,
      ),
      _CommandHelpEntry(
        command: 'get radio.rxgain',
        description: l10n.repeater_cliHelpGetRadioRxGain,
      ),
      _CommandHelpEntry(
        command: 'get radio.fem.rxgain',
        description: l10n.repeater_cliHelpGetRadioFemRxGain,
      ),
      _CommandHelpEntry(
        command: 'get radio.fem.txgain',
        description: l10n.repeater_cliHelpGetRadioFemTxGain,
      ),
      _CommandHelpEntry(
        command: 'get af',
        description: l10n.repeater_cliHelpGetAf,
      ),
      _CommandHelpEntry(
        command: 'get dutycycle',
        description: l10n.repeater_cliHelpGetDutyCycle,
      ),
      _CommandHelpEntry(
        command: 'get int.thresh',
        description: l10n.repeater_cliHelpGetIntThresh,
      ),
      _CommandHelpEntry(
        command: 'get agc.reset.interval',
        description: l10n.repeater_cliHelpGetAgcResetInterval,
      ),
      _CommandHelpEntry(
        command: 'get multi.acks',
        description: l10n.repeater_cliHelpGetMultiAcks,
      ),
      _CommandHelpEntry(
        command: 'get allow.read.only',
        description: l10n.repeater_cliHelpGetAllowReadOnly,
      ),
      _CommandHelpEntry(
        command: 'get advert.interval',
        description: l10n.repeater_cliHelpGetAdvertInterval,
      ),
      _CommandHelpEntry(
        command: 'get flood.advert.interval',
        description: l10n.repeater_cliHelpGetFloodAdvertInterval,
      ),
      _CommandHelpEntry(
        command: 'get guest.password',
        description: l10n.repeater_cliHelpGetGuestPassword,
      ),
      _CommandHelpEntry(
        command: 'get lat',
        description: l10n.repeater_cliHelpGetLat,
      ),
      _CommandHelpEntry(
        command: 'get lon',
        description: l10n.repeater_cliHelpGetLon,
      ),
      _CommandHelpEntry(
        command: 'get rxdelay',
        description: l10n.repeater_cliHelpGetRxDelay,
      ),
      _CommandHelpEntry(
        command: 'get txdelay',
        description: l10n.repeater_cliHelpGetTxDelay,
      ),
      _CommandHelpEntry(
        command: 'get direct.txdelay',
        description: l10n.repeater_cliHelpGetDirectTxDelay,
      ),
      _CommandHelpEntry(
        command: 'get flood.max',
        description: l10n.repeater_cliHelpGetFloodMax,
      ),
      _CommandHelpEntry(
        command: 'get flood.max.unscoped',
        description: l10n.repeater_cliHelpGetFloodMaxUnscoped,
      ),
      _CommandHelpEntry(
        command: 'get flood.max.advert',
        description: l10n.repeater_cliHelpGetFloodMaxAdvert,
      ),
      _CommandHelpEntry(
        command: 'get owner.info',
        description: l10n.repeater_cliHelpGetOwnerInfo,
      ),
      _CommandHelpEntry(
        command: 'get path.hash.mode',
        description: l10n.repeater_cliHelpGetPathHashMode,
      ),
      _CommandHelpEntry(
        command: 'get loop.detect',
        description: l10n.repeater_cliHelpGetLoopDetect,
      ),
      _CommandHelpEntry(
        command: 'get bootloader.ver',
        description: l10n.repeater_cliHelpGetBootloaderVer,
      ),
      _CommandHelpEntry(
        command: 'get adc.multiplier',
        description: l10n.repeater_cliHelpGetAdcMultiplier,
      ),
    ];

    final powerMgmtCommands = [
      _CommandHelpEntry(
        command: 'get pwrmgt.support',
        description: l10n.repeater_cliHelpGetPwrMgtSupport,
      ),
      _CommandHelpEntry(
        command: 'get pwrmgt.source',
        description: l10n.repeater_cliHelpGetPwrMgtSource,
      ),
      _CommandHelpEntry(
        command: 'get pwrmgt.bootreason',
        description: l10n.repeater_cliHelpGetPwrMgtBootReason,
      ),
      _CommandHelpEntry(
        command: 'get pwrmgt.bootmv',
        description: l10n.repeater_cliHelpGetPwrMgtBootMv,
      ),
    ];

    final sensorCommands = [
      _CommandHelpEntry(
        command: 'sensor get {key}',
        description: l10n.repeater_cliHelpSensorGet,
      ),
      _CommandHelpEntry(
        command: 'sensor set {key} {value}',
        description: l10n.repeater_cliHelpSensorSet,
      ),
      _CommandHelpEntry(
        command: 'sensor list [start]',
        description: l10n.repeater_cliHelpSensorList,
      ),
    ];

    final gpsCommands = [
      _CommandHelpEntry(command: 'gps', description: l10n.repeater_cliHelpGps),
      _CommandHelpEntry(
        command: 'gps {on|off}',
        description: l10n.repeater_cliHelpGpsOnOff,
      ),
      _CommandHelpEntry(
        command: 'gps sync',
        description: l10n.repeater_cliHelpGpsSync,
      ),
      _CommandHelpEntry(
        command: 'gps setloc',
        description: l10n.repeater_cliHelpGpsSetLoc,
      ),
      _CommandHelpEntry(
        command: 'gps advert',
        description: l10n.repeater_cliHelpGpsAdvert,
      ),
      _CommandHelpEntry(
        command: 'gps advert {none|share|prefs}',
        description: l10n.repeater_cliHelpGpsAdvertSet,
      ),
    ];

    final sections = <_CommandHelpSection>[
      _CommandHelpSection(l10n.repeater_general, generalCommands),
      _CommandHelpSection(l10n.repeater_getCategory, getCommands),
      _CommandHelpSection(l10n.repeater_settingsCategory, settingsCommands),
      _CommandHelpSection(l10n.repeater_powerMgmt, powerMgmtCommands),
      _CommandHelpSection(l10n.repeater_sensors, sensorCommands),
      _CommandHelpSection(
        l10n.repeater_bridge,
        bridgeCommands,
        note: l10n.repeater_bridgeNote,
      ),
      _CommandHelpSection(l10n.repeater_logging, loggingCommands),
      _CommandHelpSection(
        l10n.repeater_neighborsRepeaterOnly,
        neighborCommands,
      ),
      _CommandHelpSection(
        l10n.repeater_regionManagementRepeaterOnly,
        regionCommands,
        note: l10n.repeater_regionNote,
      ),
      _CommandHelpSection(
        l10n.repeater_gpsManagement,
        gpsCommands,
        note: l10n.repeater_gpsNote,
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _CommandHelpSheet(sections: sections, onSelect: _applyHelpCommand),
    );
  }
}

class _CommandHelpSection {
  final String title;
  final List<_CommandHelpEntry> commands;
  final String? note;
  const _CommandHelpSection(this.title, this.commands, {this.note});
}

/// Searchable, lazily built list of CLI commands.
class _CommandHelpSheet extends StatefulWidget {
  final List<_CommandHelpSection> sections;
  final ValueChanged<String> onSelect;

  const _CommandHelpSheet({required this.sections, required this.onSelect});

  @override
  State<_CommandHelpSheet> createState() => _CommandHelpSheetState();
}

class _CommandHelpSheetState extends State<_CommandHelpSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Section headers ([_CommandHelpSection]) interleaved with their matching
  /// [_CommandHelpEntry] rows.
  List<Object> _rows() {
    final q = _query.trim().toLowerCase();
    final rows = <Object>[];
    for (final section in widget.sections) {
      final matches = q.isEmpty
          ? section.commands
          : section.commands
                .where(
                  (e) =>
                      e.command.toLowerCase().contains(q) ||
                      e.description.toLowerCase().contains(q),
                )
                .toList();
      if (matches.isEmpty) continue;
      rows.add(section);
      rows.addAll(matches);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rows = _rows();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 1,
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.repeater_commandsListTitle,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.repeater_commandsListNote,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l10n.repeater_cliSearchCommands,
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: l10n.common_clearSearch,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        l10n.repeater_cliNoMatchingCommands,
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        if (row is _CommandHelpSection) {
                          return _buildHeader(row, isFirst: index == 0);
                        }
                        return _buildCommandCard(row as _CommandHelpEntry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_CommandHelpSection section, {required bool isFirst}) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (section.note != null) ...[
            const SizedBox(height: 4),
            Text(
              section.note!,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommandCard(_CommandHelpEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeshRadii.sm),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(MeshRadii.sm),
        onTap: () => widget.onSelect(entry.command),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.command,
                style: MeshTheme.mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandHelpEntry {
  final String command;
  final String description;
  const _CommandHelpEntry({required this.command, required this.description});
}
