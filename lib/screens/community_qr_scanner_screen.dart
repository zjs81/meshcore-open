import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/utf8_length_limiter.dart';
import '../l10n/l10n.dart';
import '../models/community.dart';
import '../storage/community_store.dart';
import '../theme/mesh_theme.dart';
import '../utils/channel_qr.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/qr_scanner_widget.dart';

/// Screen for scanning community and channel QR codes.
///
/// After scanning a community QR code, the user can:
/// 1. Join the community (saves to local storage)
/// 2. Optionally add the Community Public Channel to the device
///
/// After scanning an official channel QR code
/// (`meshcore://channel/add?name=…&secret=…`), the user can add that
/// channel to a free slot on the device.
class CommunityQrScannerScreen extends StatefulWidget {
  const CommunityQrScannerScreen({super.key});

  @override
  State<CommunityQrScannerScreen> createState() =>
      _CommunityQrScannerScreenState();
}

class _CommunityQrScannerScreenState extends State<CommunityQrScannerScreen> {
  final CommunityStore _communityStore = CommunityStore();
  bool _isProcessing = false;

  /// QR data whose join prompt was just cancelled. Ignored for a short
  /// cooldown so a code still in view doesn't immediately re-prompt.
  String? _cancelledData;
  DateTime? _cancelledAt;
  static const Duration _cancelCooldown = Duration(seconds: 3);

  void _markCancelled(String data) {
    _cancelledData = data;
    _cancelledAt = DateTime.now();
  }

  bool _isRecentlyCancelled(String data) {
    final at = _cancelledAt;
    return data == _cancelledData &&
        at != null &&
        DateTime.now().difference(at) < _cancelCooldown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.channels_scanQrCode),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const QrScannerProcessingBody()
          : QrScannerWidget(
              onScanned: (data) => _handleScannedData(context, data),
              validator: (data) =>
                  (Community.isValidQrData(data) ||
                      parseChannelQr(data) != null) &&
                  !_isRecentlyCancelled(data),
              onValidationFailed: (data) {
                if (_isRecentlyCancelled(data)) return;
                _showInvalidQrError(context);
              },
              instructions: context.l10n.channels_scanQrInstructions,
              themed: true,
            ),
    );
  }

  Future<void> _handleScannedData(BuildContext context, String data) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final connector = context.read<MeshCoreConnector>();
    _communityStore.setPublicKeyHex = connector.selfPublicKeyHex;
    // Set when this screen is about to pop: keep the spinner up so the camera
    // doesn't restart on a closing route and detect the code again.
    var leaving = false;

    try {
      final channel = parseChannelQr(data);
      if (channel != null) {
        if (context.mounted) {
          leaving = await _showJoinChannelDialog(context, channel, data);
        }
        return;
      }

      // Parse the community data
      final community = Community.fromQrData(const Uuid().v4(), data);

      // Check if this community already exists
      final existing = await _communityStore.findByCommunityId(
        community.communityId,
      );

      if (existing != null) {
        if (context.mounted) {
          leaving = await _showAlreadyMemberDialog(context, existing);
          if (!leaving) _markCancelled(data);
        }
        return;
      }

      // Show confirmation dialog
      if (context.mounted) {
        leaving = await _showJoinConfirmationDialog(context, community, data);
      }
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.channels_invalidQrCode),
          backgroundColor: MeshPalette.alert,
        );
      }
    } finally {
      if (mounted && !leaving) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showInvalidQrError(BuildContext context) {
    showInvalidQrSnackBar(context, context.l10n.channels_invalidQrCode);
  }

  /// Returns true when the channel was added and the screen popped.
  Future<bool> _showJoinChannelDialog(
    BuildContext context,
    ScannedChannel channel,
    String data,
  ) async {
    final connector = context.read<MeshCoreConnector>();
    final name = truncateUtf8(channel.name, maxRadioNameBytes);
    final alreadyOnRadio = connector.channels.any(
      (c) => listEquals(c.psk, channel.psk),
    );
    if (alreadyOnRadio) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.channels_alreadyOnRadio(name)),
      );
      _markCancelled(data);
      return false;
    }

    final confirmed = await showMeshSheet<bool>(
      context,
      builder: (sheetContext) {
        final sheetScheme = Theme.of(sheetContext).colorScheme;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BottomSheetHeader(title: context.l10n.channels_joinChannelTitle),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  context.l10n.channels_joinChannelConfirm(name),
                  style: TextStyle(color: sheetScheme.onSurfaceVariant),
                ),
              ),
              MeshCard(
                child: Row(
                  children: [
                    AvatarCircle(
                      name: name,
                      icon: Icons.lock,
                      color: MeshPalette.blue,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(context.l10n.common_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(context.l10n.common_add),
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
    if (confirmed != true || !context.mounted) {
      _markCancelled(data);
      return false;
    }

    // Only trust free slots after a complete channel sync; mid-sync, unfetched
    // slots look empty and writing one would overwrite an existing channel.
    final slotsKnown =
        connector.hasLoadedChannels && !connector.isSyncingChannels;
    final nextIndex = slotsKnown
        ? _findNextAvailableChannelIndex(connector)
        : null;
    if (nextIndex == null) {
      showDismissibleSnackBar(
        context,
        content: Text(
          slotsKnown
              ? context.l10n.channels_noFreeSlots
              : context.l10n.channels_waitForSync,
        ),
      );
      _markCancelled(data);
      return false;
    }

    await connector.setChannel(nextIndex, name, channel.psk);
    if (!context.mounted) return false;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.channels_channelAdded(name)),
      backgroundColor: MeshPalette.signal,
    );
    Navigator.pop(context);
    return true;
  }

  /// Returns true when the screen popped itself (OK pressed).
  Future<bool> _showAlreadyMemberDialog(
    BuildContext context,
    Community community,
  ) async {
    final ok = await showMeshSheet<bool>(
      context,
      builder: (sheetContext) {
        final sheetScheme = Theme.of(sheetContext).colorScheme;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BottomSheetHeader(title: context.l10n.community_alreadyMember),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  context.l10n.community_alreadyMemberMessage(community.name),
                  style: TextStyle(color: sheetScheme.onSurfaceVariant),
                ),
              ),
              MeshCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups,
                      color: MeshPalette.magenta,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            context.l10n.community_shortId(
                              community.shortCommunityId,
                            ),
                            style: MeshTheme.mono(
                              fontSize: 13,
                              color: sheetScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(context.l10n.common_ok),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || !context.mounted) return false;
    Navigator.pop(context);
    return true;
  }

  /// Returns true when the community was joined and the screen popped.
  Future<bool> _showJoinConfirmationDialog(
    BuildContext context,
    Community community,
    String data,
  ) async {
    bool addPublicChannel = true;
    final completer = Completer<bool>();

    await showMeshSheet<void>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final joinScheme = Theme.of(sheetContext).colorScheme;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BottomSheetHeader(title: context.l10n.community_joinTitle),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    context.l10n.community_joinConfirmation(community.name),
                    style: TextStyle(color: joinScheme.onSurfaceVariant),
                  ),
                ),
                MeshCard(
                  child: Row(
                    children: [
                      AvatarCircle(
                        name: community.name,
                        icon: Icons.groups,
                        color: MeshPalette.magenta,
                        size: 44,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              context.l10n.community_shortId(
                                community.shortCommunityId,
                              ),
                              style: MeshTheme.mono(
                                fontSize: 13,
                                color: joinScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  value: addPublicChannel,
                  onChanged: (value) {
                    setSheetState(() {
                      addPublicChannel = value ?? true;
                    });
                  },
                  title: Text(context.l10n.community_addPublicChannel),
                  subtitle: Text(context.l10n.community_addPublicChannelHint),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            completer.complete(false);
                            Navigator.pop(sheetContext);
                          },
                          child: Text(context.l10n.common_cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            completer.complete(true);
                            Navigator.pop(sheetContext);
                          },
                          child: Text(context.l10n.community_join),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // If sheet was dismissed without a button press, treat as cancel
    if (!completer.isCompleted) {
      completer.complete(false);
    }

    final result = await completer.future;

    if (result && context.mounted) {
      return _joinCommunity(context, community, addPublicChannel);
    }
    // User cancelled: stay on the scanner and resume scanning, ignoring this
    // code briefly so it doesn't re-prompt while still in view.
    _markCancelled(data);
    return false;
  }

  /// Returns true when the screen popped itself.
  Future<bool> _joinCommunity(
    BuildContext context,
    Community community,
    bool addPublicChannel,
  ) async {
    // Save community to local storage
    final connector = context.read<MeshCoreConnector>();
    _communityStore.setPublicKeyHex = connector.selfPublicKeyHex;
    await _communityStore.addCommunity(community);

    // Optionally add the community public channel to the device. Only trust
    // free slots after a complete channel sync; mid-sync, unfetched slots
    // look empty and writing one would overwrite an existing channel.
    if (addPublicChannel && context.mounted) {
      final connector = context.read<MeshCoreConnector>();
      final slotsKnown =
          connector.hasLoadedChannels && !connector.isSyncingChannels;
      final nextIndex = slotsKnown
          ? _findNextAvailableChannelIndex(connector)
          : null;

      if (nextIndex != null) {
        final psk = community.deriveCommunityPublicPsk();
        final channelName = fitRadioName(
          community.name,
          context.l10n.channels_public,
        );
        connector.setChannel(nextIndex, channelName, psk);
      } else {
        showDismissibleSnackBar(
          context,
          content: Text(
            slotsKnown
                ? context.l10n.channels_noFreeSlots
                : context.l10n.channels_waitForSync,
          ),
        );
      }
    }

    if (context.mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.community_joined(community.name)),
        backgroundColor: MeshPalette.signal,
      );

      // Return to previous screen
      Navigator.pop(context, community);
      return true;
    }
    return false;
  }

  int? _findNextAvailableChannelIndex(MeshCoreConnector connector) {
    final usedIndices = {
      ...connector.channels.map((c) => c.index),
      ...connector.unconfirmedChannelSlots,
    };
    for (int i = 0; i < connector.maxChannels; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return null;
  }
}
