import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';

/// The thin progress bar at the top of a screen or list: 4px, in the theme's
/// progress colour and track. Fills when [value] is known, moves when it is
/// null. While inactive it keeps its height, so the content doesn't jump.
///
/// Once shown, it stays for at least [minVisible], then fades out over
/// [fadeOut], so a quick task is still seen.
class MeshProgressBar extends StatefulWidget {
  static const double height = 4;
  static const Duration minVisible = Duration(milliseconds: 500);
  static const Duration fadeOut = Duration(milliseconds: 300);

  final bool active;
  final double? value;

  const MeshProgressBar({super.key, this.active = true, this.value});

  @override
  State<MeshProgressBar> createState() => _MeshProgressBarState();
}

class _MeshProgressBarState extends State<MeshProgressBar> {
  bool _shown = false;
  bool _fading = false;
  // Runs until the bar has been visible for MeshProgressBar.minVisible.
  Timer? _minTimer;
  // The last progress while active, kept while the bar fades.
  double? _value;

  @override
  void initState() {
    super.initState();
    if (widget.active) _show();
  }

  @override
  void didUpdateWidget(MeshProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _value = widget.value;
      if (!_shown || _fading) _show();
    } else {
      _startFadeIfDone();
    }
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _shown = true;
    _fading = false;
    _value = widget.value;
    _minTimer?.cancel();
    _minTimer = Timer(MeshProgressBar.minVisible, () {
      _minTimer = null;
      if (mounted) setState(_startFadeIfDone);
    });
  }

  void _startFadeIfDone() {
    if (widget.active || !_shown || _minTimer != null) return;
    _fading = true;
  }

  void _onFadeEnd() {
    if (!_fading || !mounted) return;
    setState(() {
      _shown = false;
      _fading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MeshProgressBar.height,
      child: _shown
          ? AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: _fading ? MeshProgressBar.fadeOut : Duration.zero,
              onEnd: _onFadeEnd,
              child: LinearProgressIndicator(
                value: _value,
                minHeight: MeshProgressBar.height,
              ),
            )
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
  /// Also shows the bar, moving, while a screen action goes to the radio and
  /// no sync is running.
  final bool busy;

  const SyncProgressAppBarBottom({super.key, this.busy = false});

  @override
  Size get preferredSize => const Size.fromHeight(MeshProgressBar.height);

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final state =
            _SyncProgressState.fromConnector(connector) ??
            (busy && connector.isConnected
                ? const _SyncProgressState(value: null)
                : null);
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
