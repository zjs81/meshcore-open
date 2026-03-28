import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/companion_radio_stats.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:provider/provider.dart';

class CompanionRadioStatsScreen extends StatefulWidget {
  const CompanionRadioStatsScreen({super.key});

  @override
  State<CompanionRadioStatsScreen> createState() =>
      _CompanionRadioStatsScreenState();
}

class _CompanionRadioStatsScreenState extends State<CompanionRadioStatsScreen> {
  final List<double> _noiseHistory = [];
  static const int _maxSamples = 120;
  MeshCoreConnector? _connector;
  DateTime? _lastChartSampleAt;

  @override
  void initState() {
    super.initState();
    final c = context.read<MeshCoreConnector>();
    _connector = c;
    c.acquireRadioStatsPolling();
    c.radioStatsNotifier.addListener(_onStatsUpdate);
  }

  void _onStatsUpdate() {
    final s = _connector?.radioStatsNotifier.value;
    if (s == null || !mounted) return;
    if (_lastChartSampleAt == s.receivedAt) return;
    _lastChartSampleAt = s.receivedAt;
    setState(() {
      _noiseHistory.add(s.noiseFloorDbm.toDouble());
      while (_noiseHistory.length > _maxSamples) {
        _noiseHistory.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _connector?.radioStatsNotifier.removeListener(_onStatsUpdate);
    _connector?.releaseRadioStatsPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.radioStats_screenTitle),
        centerTitle: true,
      ),
      body: Selector<MeshCoreConnector, ({bool connected, bool supported})>(
        selector: (_, c) => (
          connected: c.isConnected,
          supported: c.supportsCompanionRadioStats,
        ),
        builder: (context, state, _) {
          if (!state.connected) {
            return Center(child: Text(l10n.radioStats_notConnected));
          }
          if (!state.supported) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.radioStats_firmwareTooOld,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final connector = context.read<MeshCoreConnector>();
          final scheme = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;

          return ValueListenableBuilder<CompanionRadioStats?>(
            valueListenable: connector.radioStatsNotifier,
            builder: (context, stats, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (stats != null) ...[
                    Text(
                      l10n.radioStats_noiseFloor(stats.noiseFloorDbm),
                      style: tt.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.radioStats_lastRssi(stats.lastRssiDbm)),
                    Text(
                      l10n.radioStats_lastSnr(
                        stats.lastSnrDb.toStringAsFixed(1),
                      ),
                    ),
                    Text(l10n.radioStats_txAir(stats.txAirSecs)),
                    Text(l10n.radioStats_rxAir(stats.rxAirSecs)),
                    const SizedBox(height: 16),
                  ] else
                    Text(l10n.radioStats_waiting),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      painter: _NoiseChartPainter(
                        samples: List<double>.from(_noiseHistory),
                        colorScheme: scheme,
                        textTheme: tt,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.radioStats_chartCaption,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NoiseChartPainter extends CustomPainter {
  final List<double> samples;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  _NoiseChartPainter({
    required this.samples,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = colorScheme.surfaceContainerHighest;
    final border = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final grid = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      border,
    );

    const padL = 40.0;
    const padR = 8.0;
    const padT = 8.0;
    const padB = 24.0;
    final chart = Rect.fromLTRB(
      padL,
      padT,
      size.width - padR,
      size.height - padB,
    );

    for (var i = 0; i <= 4; i++) {
      final y = chart.top + (chart.height * i / 4);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    if (samples.length < 2) {
      final tp = TextPainter(
        text: TextSpan(
          text: '—',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(chart.left + 4, chart.top + chart.height / 2 - tp.height / 2),
      );
      return;
    }

    double minV = samples.reduce((a, b) => a < b ? a : b);
    double maxV = samples.reduce((a, b) => a > b ? a : b);
    if ((maxV - minV).abs() < 1) {
      minV -= 2;
      maxV += 2;
    }
    final span = maxV - minV;

    for (var i = 0; i <= 2; i++) {
      final v = maxV - span * i / 2;
      final tp = _yAxisLabel(v);
      final y = chart.top + (chart.height * i / 2) - tp.height / 2;
      tp.paint(canvas, Offset(4, y));
    }

    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = chart.left + (chart.width * i / (samples.length - 1));
      final t = (samples[i] - minV) / span;
      final y = chart.bottom - t * chart.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _NoiseChartPainter oldDelegate) {
    return oldDelegate.samples.length != samples.length ||
        oldDelegate.colorScheme != colorScheme;
  }

  TextPainter _yAxisLabel(double v) {
    final tp = TextPainter(
      text: TextSpan(
        text: v.round().toString(),
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }
}
