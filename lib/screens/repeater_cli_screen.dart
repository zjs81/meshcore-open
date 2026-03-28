import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../widgets/debug_frame_viewer.dart';
import '../services/repeater_command_service.dart';
import '../widgets/path_management_dialog.dart';

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

  // Common commands for quick access
  late final List<Map<String, String>> _quickCommands = [
    {'labelKey': 'getName', 'command': 'get name'},
    {'labelKey': 'getRadio', 'command': 'get radio'},
    {'labelKey': 'getTx', 'command': 'get tx'},
    {'labelKey': 'neighbors', 'command': 'neighbors'},
    {'labelKey': 'version', 'command': 'ver'},
    {'labelKey': 'advertise', 'command': 'advert'},
    {'labelKey': 'clock', 'command': 'clock'},
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

    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      // Check if it's a text message response
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

    // Notify command service of response (for retry handling)
    _commandService?.handleResponse(widget.repeater, parsed.text);

    // Note: The command service will handle the response via the Future
    // We don't need to add it to history here anymore as _sendCommand will do it
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
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    setState(() {
      _commandHistory.add({
        'type': 'command',
        'text': command,
        'timestamp': DateTime.now().toString(),
      });
    });

    // Show debug info if requested
    if (showDebug && mounted) {
      final frame = buildSendCliCommandFrame(
        widget.repeater.publicKey,
        command,
      );
      DebugFrameViewer.showFrameDebug(
        context,
        frame,
        context.l10n.repeater_cliCommandFrameTitle,
      );
    }

    // Send CLI command to repeater with retry
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

    _commandController.clear();
    _historyIndex = -1;
    _commandFocusNode.requestFocus();

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.repeater_cliTitle),
            Text(
              repeater.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(isFloodMode ? Icons.waves : Icons.route),
            tooltip: l10n.repeater_routingMode,
            onSelected: (mode) async {
              if (mode == 'flood') {
                await connector.setPathOverride(repeater, pathLen: -1);
              } else {
                await connector.setPathOverride(repeater, pathLen: null);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'auto',
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_mode,
                      size: 20,
                      color: !isFloodMode
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_autoUseSavedPath,
                      style: TextStyle(
                        fontWeight: !isFloodMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'flood',
                child: Row(
                  children: [
                    Icon(
                      Icons.waves,
                      size: 20,
                      color: isFloodMode
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_forceFloodMode,
                      style: TextStyle(
                        fontWeight: isFloodMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: l10n.repeater_pathManagement,
            onPressed: () =>
                PathManagementDialog.show(context, contact: repeater),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: l10n.repeater_debugNextCommand,
            onPressed: () {
              // Set a flag or just send next command with debug
              if (_commandController.text.trim().isNotEmpty) {
                _sendCommand(showDebug: true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.repeater_enterCommandFirst)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.repeater_commandHelp,
            onPressed: () => _showCommandHelp(context),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.repeater_clearHistory,
            onPressed: _commandHistory.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickCommandsBar(),
          const Divider(height: 1),
          Expanded(
            child: _commandHistory.isEmpty
                ? _buildEmptyState()
                : _buildCommandHistory(),
          ),
          const Divider(height: 1),
          _buildCommandInput(),
        ],
      ),
    );
  }

  Widget _buildQuickCommandsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickCommands.map((cmd) {
            final label = _quickCommandLabel(cmd['labelKey']!);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(label),
                onPressed: () => _useQuickCommand(cmd['command']!),
                avatar: const Icon(Icons.play_arrow, size: 16),
              ),
            );
          }).toList(),
        ),
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
      default:
        return key;
    }
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.repeater_noCommandsSent,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.repeater_typeCommandOrUseQuick,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandHistory() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _commandHistory.length,
      itemBuilder: (context, index) {
        final entry = _commandHistory[index];
        final isCommand = entry['type'] == 'command';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCommand
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isCommand ? Icons.chevron_right : Icons.arrow_back,
                  size: 16,
                  color: isCommand
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      entry['text']!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isCommand
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandInput() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 20),
              tooltip: l10n.repeater_previousCommand,
              onPressed: () => _navigateHistory(true),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 20),
              tooltip: l10n.repeater_nextCommand,
              onPressed: () => _navigateHistory(false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _commandController,
                focusNode: _commandFocusNode,
                decoration: InputDecoration(
                  hintText: l10n.repeater_enterCommandHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixText: '> ',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendCommand(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: _sendCommand,
            ),
          ],
        ),
      ),
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
    ];

    final bridgeCommands = [
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.repeater_commandsListTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.repeater_commandsListNote,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                l10n.repeater_general,
                generalCommands,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                l10n.repeater_settingsCategory,
                settingsCommands,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(context, l10n.repeater_bridge, bridgeCommands),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                l10n.repeater_logging,
                loggingCommands,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                l10n.repeater_neighborsRepeaterOnly,
                neighborCommands,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                l10n.repeater_regionManagementRepeaterOnly,
                regionCommands,
                note: l10n.repeater_regionNote,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                l10n.repeater_gpsManagement,
                gpsCommands,
                note: l10n.repeater_gpsNote,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context,
    String title,
    List<_CommandHelpEntry> commands, {
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(fontSize: 12)),
        ],
        const SizedBox(height: 8),
        ...commands.map((entry) => _buildHelpCommandCard(context, entry)),
      ],
    );
  }

  Widget _buildHelpCommandCard(BuildContext context, _CommandHelpEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _applyHelpCommand(entry.command),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.command,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.description,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
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
