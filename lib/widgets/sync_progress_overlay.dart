import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';

/// The thin progress bar at the top of a screen or list: 4px, in the theme's
/// progress colour and track. Fills when [value] is known, moves when it is
/// null. While inactive it keeps its height, so the content doesn't jump.
class MeshProgressBar extends StatelessWidget {
  static const double height = 4;

  final bool active;
  final double? value;

  const MeshProgressBar({super.key, this.active = true, this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: active
          ? LinearProgressIndicator(value: value, minHeight: height)
          : null,
    );
  }
}

/// [MeshProgressBar] as an app bar's `bottom`, for a screen's own task.
class MeshProgressAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  final bool active;
  final double? value;

  const MeshProgressAppBarBottom({super.key, this.active = true, this.value});

  @override
  Size get preferredSize => const Size.fromHeight(MeshProgressBar.height);

  @override
  Widget build(BuildContext context) =>
      MeshProgressBar(active: active, value: value);
}

/// [MeshProgressBar] as an app bar's `bottom` for the app-wide syncs:
/// contacts, channels and queued messages, one at a time.
class SyncProgressAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  const SyncProgressAppBarBottom({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(MeshProgressBar.height);

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final state = _SyncProgressState.fromConnector(connector);
        return MeshProgressBar(active: state != null, value: state?.value);
      },
    );
  }
}

class _SyncProgressState {
  /// Null while the progress is unknown.
  final double? value;

  const _SyncProgressState({required this.value});

  static _SyncProgressState? fromConnector(MeshCoreConnector connector) {
    if (connector.isLoadingContacts) {
      return _SyncProgressState(value: connector.contactSyncProgress);
    }
    if (connector.isSyncingChannels) {
      return _SyncProgressState(value: connector.channelSyncProgress / 100);
    }
    if (connector.isShowingQueuedMessageSyncProgress) {
      return const _SyncProgressState(value: null);
    }
    return null;
  }
}
