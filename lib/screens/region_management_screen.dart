import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
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
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 88),
        itemCount: _regions.length,
        itemBuilder: (context, index) {
          final region = _regions[index];
          return _buildRegionTile(context, region);
        },
      ),
    );
  }

  void _showAddRegionDialog(BuildContext context) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_regionName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _handleAddRegion(controller.text, context),
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
          TextButton(
            onPressed: () => _handleAddRegion(controller.text, context),
            child: Text(l10n.common_add),
          ),
        ],
      ),
    );
  }

  Future<void> _showFetchRegionsDialog() async {
    if (_isFetchingRegions) return;

    setState(() {
      _isFetchingRegions = true;
    });

    Set<Region> fetchedRegions = {};
    try {
      fetchedRegions = await _fetchRegionsFromRepeaters();
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRegions = false;
        });
      }
    }

    if (!mounted) return;
    final l10n = context.l10n;
    final sortedRegions = fetchedRegions.toList()..sort();
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
                                    _showDialogSnackBar(
                                      context,
                                      l10n.settings_regionFetchRegionsAlreadyExists,
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

  void _showDialogSnackBar(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 32,
        child: SafeArea(
          child: Material(
            color: theme.colorScheme.inverseSurface,
            elevation: 6,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Timer(const Duration(seconds: 3), entry.remove);
  }

  Future<Set<Region>> _fetchRegionsFromRepeaters() async {
    final connector = context.read<MeshCoreConnector>();
    final repeaters = await _discoverNearbyRepeaters(connector);
    final regions = <Region>{};

    for (final repeater in repeaters) {
      if (!mounted || !connector.isConnected) break;
      regions.addAll(await _requestRegionsFromRepeater(connector, repeater));
    }

    return regions;
  }

  Future<List<Contact>> _discoverNearbyRepeaters(
    MeshCoreConnector connector,
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

    try {
      final payload = buildDiscoveryRequestPayload(tag, prefixOnly: true);
      await connector.sendFrame(buildSendControlDataFrame(payload));
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
      final regions = await completer.future;
      if (pathChangedForRequest && connector.isConnected) {
        await _restoreRepeaterPath(
          connector,
          repeater,
          originalPathLength,
          originalPath,
        );
      }
      return regions;
    } catch (_) {
      timeout?.cancel();
      subscription?.cancel();
      if (pathChangedForRequest && connector.isConnected) {
        await _restoreRepeaterPath(
          connector,
          repeater,
          originalPathLength,
          originalPath,
        );
      }
      return <Region>{};
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
    await connector.setContactPath(repeater, originalPath, originalPathLength);
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

  void _handleAddRegion(Region region, BuildContext context) {
    Navigator.pop(context);
    _regionStore.addRegion(region);
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
