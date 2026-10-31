import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';

/// Strip shown on top of main screens while the simulated radio is active.
class ReviewModeBanner extends StatelessWidget {
  const ReviewModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();
    if (!connector.isReviewMode) return const SizedBox.shrink();

    final l10n = context.l10n;
    const textStyle = TextStyle(
      color: MeshPalette.ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: MeshPalette.warn,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      minimumSize: const Size(48, 48),
    );

    // A status strip on every main screen: capped so that at the largest
    // text sizes it can't take over a small phone's screen.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: MeshPalette.bg3,
          border: Border(bottom: BorderSide(color: MeshPalette.warnLine)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: MeshPalette.warn, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.reviewMode_banner, style: textStyle)),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  style: buttonStyle,
                  onPressed: () {
                    connector.sendReviewTestMessage();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.reviewMode_testSent)),
                    );
                  },
                  child: Text(l10n.reviewMode_sendTest),
                ),
                TextButton(
                  style: buttonStyle,
                  // The screens hosting the banner return to the Connect screen
                  // themselves once disconnected.
                  onPressed: () => connector.disconnect(manual: true),
                  child: Text(l10n.reviewMode_exit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
