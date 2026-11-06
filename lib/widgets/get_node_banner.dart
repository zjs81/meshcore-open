import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/node_banner_service.dart';
import '../theme/mesh_theme.dart';

/// Bottom banner on the connect screen pointing new users at a node to buy.
/// Its link (and optionally its text) comes from the `_banner` DNS TXT
/// record; it stays hidden until that loads, and when the lookup fails or the
/// record turns it off.
class GetNodeBanner extends StatefulWidget {
  final Future<NodeBannerConfig?> Function()? loadConfig;

  const GetNodeBanner({super.key, this.loadConfig});

  @override
  State<GetNodeBanner> createState() => _GetNodeBannerState();
}

class _GetNodeBannerState extends State<GetNodeBanner> {
  NodeBannerConfig? _config;

  @override
  void initState() {
    super.initState();
    (widget.loadConfig ?? NodeBannerService().load)().then((config) {
      if (mounted && config != null) setState(() => _config = config);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    void open() => launchUrl(config.url, mode: LaunchMode.externalApplication);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Material(
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeshRadii.md),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.router_outlined,
                        size: 28,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          config.title ?? l10n.scanner_getNodeTitle,
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    config.body ?? l10n.scanner_getNodeBody,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: open,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                      label: Text(config.action ?? l10n.scanner_getNodeAction),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      l10n.scanner_getNodeDisclosure,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
