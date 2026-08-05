import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/companion_radio_stats.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/telemetry_screen.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
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
    c.setPollingInterval(1);
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
    _connector?.setPollingInterval(30);
    super.dispose();
  }

  Widget _tile(String text, IconData icon, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: MeshTheme.mono(fontSize: 13, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.radioStats_screenTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.thermostat),
            tooltip: l10n.contact_telemetry,
            onPressed: () {
              final connector = Provider.of<MeshCoreConnector>(
                context,
                listen: false,
              );
              final selfKey = connector.selfPublicKey;
              if (selfKey == null || selfKey.isEmpty) return;
              final selfContact = Contact(
                publicKey: selfKey,
                name: connector.selfName ?? '',
                type: advTypeChat,
                pathLength: 0,
                path: Uint8List(0),
                lastSeen: DateTime.now(),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TelemetryScreen(contact: selfContact, isSelf: true),
                ),
              );
            },
          ),
        ],
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (stats != null) ...[
                    const SectionHeader(
                      'Signal',
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    ),
                    MeshCard(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tile(
                            l10n.radioStats_noiseFloor(stats.noiseFloorDbm),
                            Icons.noise_aware,
                            scheme.onSurfaceVariant,
                          ),
                          const Divider(height: 1),
                          _tile(
                            l10n.radioStats_lastRssi(stats.lastRssiDbm),
                            Icons.wifi_tethering,
                            scheme.onSurfaceVariant,
                          ),
                          const Divider(height: 1),
                          _tile(
                            l10n.radioStats_lastSnr(
                              stats.lastSnrDb.toStringAsFixed(1),
                            ),
                            Icons.signal_cellular_alt,
                            MeshTheme.snrColor(stats.lastSnrDb, blocked: false),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(
                      'Airtime',
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    ),
                    MeshCard(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tile(
                            l10n.radioStats_txAir(stats.txAirSecs),
                            Icons.upload,
                            MeshPalette.blue,
                          ),
                          const Divider(height: 1),
                          _tile(
                            l10n.radioStats_rxAir(stats.rxAirSecs),
                            Icons.download,
                            MeshPalette.blue,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 80),
                    Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        l10n.radioStats_waiting,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                  SectionHeader(
                    l10n.radioStats_chartCaption,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
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
                  ),
                  const SizedBox(height: 8),
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

    for (var i = 0; i <= 4; i++) {
      final v = maxV - span * i / 4;
      final tp = _yAxisLabel(v);
      final y = chart.top + (chart.height * i / 4) - tp.height / 2;
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
