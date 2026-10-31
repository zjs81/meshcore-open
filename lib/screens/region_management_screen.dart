import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/snack_bar_builder.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/storage/region_store.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:provider/provider.dart';

Future<void> pushRegionManagementScreen(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => const RegionManagementScreen(),
    ),
  );
}

class RegionManagementScreen extends StatefulWidget {
  const RegionManagementScreen({super.key});

  @override
  State<RegionManagementScreen> createState() => _RegionManagementScreenState();
}

class _RegionManagementScreenState extends State<RegionManagementScreen> {
  static final RegExp _validFetchedRegion = RegExp(r'^[a-z0-9-]{1,30}$');

  final RegionStore _regionStore = RegionStore();
  List<Region> _regions = [];
  bool _isFetchingRegions = false;

  /// Completed when the user cancels an in-progress fetch; pending discovery
  /// and region requests resolve immediately with no results.
  Completer<void>? _fetchCancel;

  /// Drives the fetch progress dialog: null while discovering, otherwise
  /// (current repeater, total repeaters).
  final ValueNotifier<(int, int)?> _fetchProgress = ValueNotifier(null);

  @override
  void dispose() {
    final cancel = _fetchCancel;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
    _fetchProgress.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final connector = context.read<MeshCoreConnector>();
    _regionStore.setPublicKeyHex = connector.selfPublicKeyHex;
    _loadRegions();
  }

  void _loadRegions() {
    final regions = _regionStore.loadRegions();
    if (mounted) {
      setState(() {
        _regions = regions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_regionManagement_screenTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.settings_regionAddRegion,
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRegionDialog(context),
          ),
          IconButton(
            tooltip: l10n.settings_regionFetchRegions,
            icon: _isFetchingRegions
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.travel_explore),
            onPressed: _isFetchingRegions ? null : _showFetchRegionsDialog,
          ),
        ],
      ),
      body: _regions.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 88,
              ),
              itemCount: _regions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDefaultRegionTile(context),
                      _buildRadioDefaultRegionTile(context),
                    ],
                  );
                }
                return _buildRegionTile(context, _regions[index - 1]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keep the app default visible so "No region (unscoped)" can be
            // chosen before any region is added.
            _buildDefaultRegionTile(context),
            // The radio may hold a default region set by firmware or another
            // client even when this app's list is empty; keep it clearable.
            _buildRadioDefaultRegionTile(context),
            const SizedBox(height: 16),
            const Icon(Icons.landscape, size: 48, color: MeshPalette.blue),
            const SizedBox(height: 16),
            Text(
              l10n.settings_regionEmptyExplanation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.travel_explore),
              label: Text(l10n.settings_regionFetchFromRepeaters),
              onPressed: _isFetchingRegions ? null : _showFetchRegionsDialog,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.settings_regionAddRegion),
              onPressed: () => _showAddRegionDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultRegionTile(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final canForceUnscoped = connector.supportsExplicitUnscopedFlood;
    final appDefault = connector.defaultRegion;
    final current =
        _regions.contains(appDefault) ||
            (appDefault == kUnscopedRegion && canForceUnscoped)
        ? appDefault
        : '';
    final radioDefault = connector.supportsDefaultFloodScope
        ? connector.defaultFloodScopeName
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<Region>(
        key: ValueKey(current),
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.settings_regionDefault,
          helperText: l10n.settings_regionDefaultSubtitle,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(
              radioDefault == null
                  ? l10n.settings_regionDefaultNone
                  : l10n.settings_regionUseRadioDefault(radioDefault),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canForceUnscoped)
            DropdownMenuItem(
              value: kUnscopedRegion,
              child: Text(
                l10n.settings_regionNoRegion,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          for (final region in _regions)
            DropdownMenuItem(
              value: region,
              child: Text(region, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => connector.setDefaultRegion(value ?? ''),
      ),
    );
  }

  /// The radio's own default flood scope (firmware ver 11+). Hidden on older
  /// firmware, which has no such setting.
  Widget _buildRadioDefaultRegionTile(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    if (!connector.supportsDefaultFloodScope) return const SizedBox.shrink();
    final radioDefault = connector.defaultFloodScopeName ?? '';
    final options = <Region>[
      ..._regions,
      if (radioDefault.isNotEmpty && !_regions.contains(radioDefault))
        radioDefault,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: DropdownButtonFormField<Region>(
        isExpanded: true,
        key: ValueKey('radio-default-$radioDefault'),
        initialValue: radioDefault,
        decoration: InputDecoration(
          labelText: l10n.settings_regionRadioDefault,
          helperText: l10n.settings_regionRadioDefaultSubtitle,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(
              l10n.settings_regionDefaultNone,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final region in options)
            DropdownMenuItem(
              value: region,
              child: Text(region, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => _setRadioDefaultRegion(connector, value ?? ''),
      ),
    );
  }

  Future<void> _setRadioDefaultRegion(
    MeshCoreConnector connector,
    Region region,
  ) async {
    final l10n = context.l10n;
    try {
      await connector.setDefaultFloodScope(region);
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_regionRadioDefaultUpdated),
      );
    } catch (_) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_regionRadioDefaultFailed),
      );
    }
  }

  Future<void> _showAddRegionDialog(BuildContext context) async {
    final region = await showDialog<Region>(
      context: context,
      builder: (_) => const _AddRegionDialog(),
    );
    if (region == null || !mounted) return;
    _handleAddRegion(region);
  }

  Future<void> _showFetchRegionsDialog() async {
    if (_isFetchingRegions) return;
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();

    if (!connector.isConnected) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_notConnectedError),
      );
      return;
    }
    final knownRepeaters = connector.contacts
        .where((contact) => contact.type == advTypeRepeater)
        .toList();
    if (knownRepeaters.isEmpty) {
      await _showFetchMessage(l10n.settings_regionFetchNoRepeaters);
      return;
    }

    setState(() {
      _isFetchingRegions = true;
    });
    final cancel = Completer<void>();
    _fetchCancel = cancel;
    _fetchProgress.value = null;

    BuildContext? progressContext;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          progressContext = dialogContext;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(l10n.settings_regionFetchRegions),
              content: ValueListenableBuilder<(int, int)?>(
                valueListenable: _fetchProgress,
                builder: (context, progress, _) => Row(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        progress == null
                            ? l10n.settings_regionFetchDiscovering
                            : l10n.settings_regionFetchProgress(
                                progress.$1,
                                progress.$2,
                              ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!cancel.isCompleted) cancel.complete();
                    progressContext = null;
                    Navigator.pop(dialogContext);
                  },
                  child: Text(l10n.common_cancel),
                ),
              ],
            ),
          );
        },
      ),
    );

    _RegionFetchResult result;
    try {
      result = await _fetchRegionsFromRepeaters(connector, cancel);
    } finally {
      if (_fetchCancel == cancel) _fetchCancel = null;
      // A fetch that fails instantly can finish before the progress dialog
      // has built; let it build so it can be closed.
      if (progressContext == null && !cancel.isCompleted) {
        await WidgetsBinding.instance.endOfFrame;
      }
      final dialog = progressContext;
      if (dialog != null && dialog.mounted) Navigator.pop(dialog);
      if (mounted) {
        setState(() {
          _isFetchingRegions = false;
        });
      }
    }

    if (!mounted) return;
    if (cancel.isCompleted && result.regions.isEmpty) return;
    if (!cancel.isCompleted && result.askedRepeaters == 0) {
      await _showFetchMessage(l10n.settings_regionFetchNoneResponded);
      return;
    }
    final sortedRegions = result.regions.toList()..sort();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settings_regionFetchRegions),
        content: sortedRegions.isEmpty
            ? Text(l10n.settings_regionFetchRegionsFail)
            : StatefulBuilder(
                builder: (context, setDialogState) {
                  return SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: sortedRegions.length,
                      itemBuilder: (context, index) {
                        final fetchedRegion = sortedRegions[index];
                        final alreadyExists = _regions.contains(fetchedRegion);
                        return MeshCard(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.only(left: 14, right: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.landscape,
                                color: MeshPalette.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fetchedRegion,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                style: alreadyExists
                                    ? TextButton.styleFrom(
                                        foregroundColor: Theme.of(
                                          context,
                                        ).disabledColor,
                                      )
                                    : null,
                                onPressed: () {
                                  if (alreadyExists) {
                                    // Screen context: the root
                                    // ScaffoldMessenger, not the dialog's.
                                    showDismissibleSnackBar(
                                      this.context,
                                      content: Text(
                                        l10n.settings_regionFetchRegionsAlreadyExists,
                                      ),
                                    );
                                    return;
                                  }

                                  _regionStore.addRegion(fetchedRegion);
                                  _loadRegions();
                                  setDialogState(() {});
                                },
                                child: Text(l10n.common_add),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _showFetchMessage(String message) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settings_regionFetchRegions),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<_RegionFetchResult> _fetchRegionsFromRepeaters(
    MeshCoreConnector connector,
    Completer<void> cancel,
  ) async {
    final repeaters = await _discoverNearbyRepeaters(connector, cancel);
    final regions = <Region>{};
    var asked = 0;

    for (final repeater in repeaters) {
      if (!mounted || !connector.isConnected || cancel.isCompleted) break;
      asked++;
      _fetchProgress.value = (asked, repeaters.length);
      regions.addAll(
        await _requestRegionsFromRepeater(connector, repeater, cancel),
      );
    }

    return _RegionFetchResult(regions: regions, askedRepeaters: asked);
  }

  Future<List<Contact>> _discoverNearbyRepeaters(
    MeshCoreConnector connector,
    Completer<void> cancel,
  ) async {
    final repeaters = connector.contacts
        .where((contact) => contact.type == advTypeRepeater)
        .toList();
    if (repeaters.isEmpty || !connector.isConnected) return <Contact>[];

    StreamSubscription<Uint8List>? subscription;
    Timer? timeout;
    final completer = Completer<Set<String>>();
    final respondingPrefixes = <String>{};
    final tag = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;

    void complete() {
      if (completer.isCompleted) return;
      timeout?.cancel();
      subscription?.cancel();
      completer.complete(respondingPrefixes);
    }

    subscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty || completer.isCompleted) return;

      final reader = BufferReader(frame);
      try {
        if (reader.readByte() != pushCodeControlData) return;
        if (reader.remaining < 9) return;
        reader.skipBytes(3); // SNR, RSSI, path_len from companion firmware.

        final payloadType = reader.readByte();
        if (((payloadType >> 4) & 0x0F) != controlSubtypeDiscoverResp ||
            (payloadType & 0x0F) != advTypeRepeater) {
          return;
        }

        reader.skipBytes(1); // Inbound SNR reported by the responding repeater.
        if (reader.readUInt32LE() != tag) return;

        final publicKeyPrefix = reader.readRemainingBytes();
        if (publicKeyPrefix.isEmpty) return;
        respondingPrefixes.add(pubKeyToHex(publicKeyPrefix));
      } catch (_) {
        // Ignore malformed discovery frames; another response may still arrive.
      }
    });

    unawaited(cancel.future.then((_) => complete()));

    try {
      final payload = buildDiscoveryRequestPayload(tag, prefixOnly: true);
      await connector.sendFrame(buildSendControlDataFrame(payload));
      if (completer.isCompleted) return <Contact>[];
      timeout = Timer(const Duration(seconds: 10), complete);
      final prefixes = await completer.future;
      return repeaters.where((contact) {
        final contactKey = contact.publicKeyHex.toLowerCase();
        return prefixes.any((prefix) => contactKey.startsWith(prefix));
      }).toList();
    } catch (_) {
      timeout?.cancel();
      await subscription.cancel();
      return <Contact>[];
    }
  }

  Future<Set<Region>> _requestRegionsFromRepeater(
    MeshCoreConnector connector,
    Contact repeater,
    Completer<void> cancel,
  ) async {
    StreamSubscription<Uint8List>? subscription;
    Timer? timeout;
    final completer = Completer<Set<Region>>();
    int? expectedTag;
    final originalPath = Uint8List.fromList(repeater.path);
    final originalPathLength = repeater.pathLength;
    var pathChangedForRequest = false;

    void complete(Set<Region> regions) {
      if (completer.isCompleted) return;
      timeout?.cancel();
      subscription?.cancel();
      completer.complete(regions);
    }

    void restartTimeout(Duration duration) {
      timeout?.cancel();
      timeout = Timer(duration, () => complete(<Region>{}));
    }

    unawaited(cancel.future.then((_) => complete(<Region>{})));

    try {
      final replyPath = Uint8List(0);
      const replyHopCount = 0;
      await connector.setContactPath(repeater, replyPath, replyHopCount);
      pathChangedForRequest = true;

      subscription = connector.receivedFrames.listen((frame) {
        if (frame.isEmpty || completer.isCompleted) return;

        final reader = BufferReader(frame);
        try {
          final cmd = reader.readByte();
          if (cmd == respCodeSent) {
            reader.skipBytes(1);
            expectedTag = reader.readUInt32LE();
            final estimatedTimeoutMs = reader.readUInt32LE();
            restartTimeout(
              Duration(
                milliseconds: estimatedTimeoutMs > 0
                    ? estimatedTimeoutMs + 2000
                    : 10000,
              ),
            );
            return;
          }

          if (cmd == respCodeErr) {
            complete(<Region>{});
            return;
          }

          if (cmd != pushCodeBinaryResponse || expectedTag == null) return;

          reader.skipBytes(1);
          final tag = reader.readUInt32LE();
          if (tag != expectedTag) return;

          complete(_parseRegionsResponse(reader.readRemainingBytes()));
        } catch (_) {
          complete(<Region>{});
        }
      });

      restartTimeout(const Duration(seconds: 10));
      final frame = buildSendAnonReqFrame(
        repeater.publicKey,
        requestType: anonReqTypeRegions,
        replyPath: replyPath,
        replyHopCount: replyHopCount,
        pathHashWidth: connector.pathHashByteWidth,
      );
      await connector.sendFrame(frame);
      return await completer.future;
    } catch (_) {
      return <Region>{};
    } finally {
      timeout?.cancel();
      await subscription?.cancel();
      // Always put the user's route back, whatever happened above. (The
      // connector ignores path writes while disconnected, so nothing can be
      // restored if the link dropped mid-request.)
      if (pathChangedForRequest) {
        try {
          await _restoreRepeaterPath(
            connector,
            repeater,
            originalPathLength,
            originalPath,
          );
        } catch (_) {
          // Best effort; the original path is still in the contact store.
        }
      }
    }
  }

  Future<void> _restoreRepeaterPath(
    MeshCoreConnector connector,
    Contact repeater,
    int originalPathLength,
    Uint8List originalPath,
  ) async {
    if (originalPathLength < 0) {
      await connector.clearContactPath(repeater);
      return;
    }
    await connector.setContactPath(
      repeater,
      originalPath,
      originalPathLength,
      pathHashWidth: repeater.pathHashWidth,
    );
  }

  Set<Region> _parseRegionsResponse(Uint8List frame) {
    if (frame.length <= 4) return <Region>{};
    final names = utf8
        .decode(frame.sublist(4), allowMalformed: true)
        .replaceAll('\x00', '')
        .split(',');
    return names
        .map((name) => name.trim())
        .where((name) => _validFetchedRegion.hasMatch(name))
        .toSet();
  }

  void _handleAddRegion(Region region) {
    // An empty name would collide with the '' "none" dropdown entry.
    final trimmed = region.trim();
    if (trimmed.isEmpty) return;
    _regionStore.addRegion(trimmed);
    _loadRegions();
  }

  Widget _buildRegionTile(BuildContext context, Region region) {
    final scheme = Theme.of(context).colorScheme;
    return MeshCard(
      key: ValueKey(region),
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        children: [
          const Icon(Icons.landscape, color: MeshPalette.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              region,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.l10n.settings_deleteRegion,
            icon: Icon(Icons.delete_outline, color: scheme.error),
            onPressed: () => _confirmDelete(context, region),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Region region) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.settings_deleteRegion),
        content: Text(context.l10n.settings_deleteRegionConfirm(region)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              final connector = context.read<MeshCoreConnector>();
              Navigator.pop(dialogContext);
              await _regionStore.removeRegion(region);
              // Deleting a region clears it from any channels that used it;
              // refresh the connector's in-memory channel regions to match.
              await connector.loadChannelSettings();
              _loadRegions();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.settings_regionDeleted)),
              );
            },
            child: Text(
              context.l10n.common_delete,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionFetchResult {
  final Set<Region> regions;
  final int askedRepeaters;

  const _RegionFetchResult({
    required this.regions,
    required this.askedRepeaters,
  });
}

/// Region-name entry. Owns (and disposes) its controller and only enables
/// Add once the trimmed name is non-empty; pops with that name.
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
