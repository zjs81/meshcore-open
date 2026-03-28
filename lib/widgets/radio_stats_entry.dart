import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/companion_radio_stats.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:meshcore_open/screens/companion_radio_stats_screen.dart';
import 'package:provider/provider.dart';

void pushCompanionRadioStatsScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => const CompanionRadioStatsScreen(),
    ),
  );
}

class RadioStatsIconButton extends StatefulWidget {
  final bool compact;

  const RadioStatsIconButton({super.key, this.compact = false});

  @override
  State<RadioStatsIconButton> createState() => _RadioStatsIconButtonState();
}

class _RadioStatsIconButtonState extends State<RadioStatsIconButton> {
  MeshCoreConnector? _connector;

  @override
  void initState() {
    super.initState();
    final c = context.read<MeshCoreConnector>();
    _connector = c;
    c.acquireRadioStatsPolling();
  }

  @override
  void dispose() {
    _connector?.releaseRadioStatsPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MeshCoreConnector, ({bool connected, bool supported})>(
      selector: (_, c) =>
          (connected: c.isConnected, supported: c.supportsCompanionRadioStats),
      builder: (context, state, _) {
        if (!state.connected || !state.supported) {
          return const SizedBox.shrink();
        }
        final connector = context.read<MeshCoreConnector>();
        return ValueListenableBuilder<CompanionRadioStats?>(
          valueListenable: connector.radioStatsNotifier,
          builder: (context, _, child) {
            final dot = AirActivityDot(
              active: connector.radioStatsAirActivityPulse,
            );
            if (widget.compact) {
              return GestureDetector(
                onTap: () => pushCompanionRadioStatsScreen(context),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: dot,
                ),
              );
            }
            return Tooltip(
              message: context.l10n.radioStats_tooltip,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => pushCompanionRadioStatsScreen(context),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: dot),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AirActivityDot extends StatefulWidget {
  final bool active;

  const AirActivityDot({super.key, required this.active});

  @override
  State<AirActivityDot> createState() => AirActivityDotState();
}

class AirActivityDotState extends State<AirActivityDot> {
  Timer? _timer;
  bool _blink = true;

  @override
  void initState() {
    super.initState();
    if (widget.active) _startTimer();
  }

  @override
  void didUpdateWidget(covariant AirActivityDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startTimer();
    } else if (!widget.active && oldWidget.active) {
      _stopTimer();
      _blink = true;
    }
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() => _blink = !_blink);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = widget.active && _blink;
    return Icon(
      Icons.circle,
      size: 12,
      color: on ? scheme.primary : scheme.outline,
    );
  }
}
