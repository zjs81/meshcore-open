import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';

class SignalUi {
  final IconData icon;
  final Color color;

  const SignalUi({required this.icon, required this.color});
}

/// RSSI and SNR shown as separate spans, each coloured by its own quality
/// ramp. Renders nothing when both measurements are absent.
class SignalText extends StatelessWidget {
  final double? snrDb;
  final int? rssiDbm;
  final double? fontSize;

  const SignalText({
    super.key,
    required this.snrDb,
    required this.rssiDbm,
    this.fontSize,
  });

  static bool isEmpty(double? snrDb, int? rssiDbm) =>
      snrDb == null && rssiDbm == null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = MeshTheme.mono(fontSize: fontSize);
    if (snrDb != null && rssiDbm != null) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: l10n.chat_rssiChip(rssiDbm!),
              style: style.copyWith(color: MeshTheme.rssiColor(rssiDbm)),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: l10n.chat_snrChip(snrDb!.toStringAsFixed(1)),
              style: style.copyWith(
                color: MeshTheme.snrColor(snrDb, blocked: false),
              ),
            ),
          ],
        ),
      );
    }
    if (rssiDbm != null) {
      return Text(
        l10n.chat_rssiChip(rssiDbm!),
        style: style.copyWith(color: MeshTheme.rssiColor(rssiDbm)),
      );
    }
    if (snrDb != null) {
      return Text(
        l10n.chat_snrChip(snrDb!.toStringAsFixed(1)),
        style: style.copyWith(color: MeshTheme.snrColor(snrDb, blocked: false)),
      );
    }
    return const SizedBox.shrink();
  }
}

SignalUi signalUiForStrengthTier(int tier) {
  switch (tier) {
    case 0:
      return const SignalUi(
        icon: Icons.signal_cellular_4_bar,
        color: MeshPalette.signal,
      );
    case 1:
      return const SignalUi(
        icon: Icons.signal_cellular_alt,
        color: MeshPalette.signalDim,
      );
    case 2:
      return const SignalUi(
        icon: Icons.signal_cellular_alt_2_bar,
        color: MeshPalette.warn,
      );
    case 3:
      return const SignalUi(
        icon: Icons.signal_cellular_alt_1_bar,
        color: MeshPalette.warnDim,
      );
    default:
      return const SignalUi(
        icon: Icons.signal_cellular_alt_1_bar,
        color: MeshPalette.alert,
      );
  }
}
