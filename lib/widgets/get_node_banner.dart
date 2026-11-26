import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/node_banner_service.dart';
import '../theme/mesh_theme.dart';
import 'settings_reveal.dart';

/// Bottom banner on the connect screen pointing new users at a node to buy.
/// Its link (and optionally its text) comes from the `_banner` DNS TXT
/// record; it stays hidden until that loads, and when the lookup fails or the
/// record turns it off. Close hides it until the screen closes.
class GetNodeBanner extends StatefulWidget {
  final Future<NodeBannerConfig?> Function()? loadConfig;

  const GetNodeBanner({super.key, this.loadConfig});

  @override
  State<GetNodeBanner> createState() => _GetNodeBannerState();
}

class _GetNodeBannerState extends State<GetNodeBanner> {
  NodeBannerConfig? _config;
  bool _closed = false;

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
    // A landscape phone has no room for it next to the screen's content.
    final roomy = MediaQuery.sizeOf(context).height >= 480;
    // The bottom inset stays reserved while hidden, so the screen's content
    // keeps clear of the system bar.
    return SafeArea(
      top: false,
      child: RevealOnEnable(
        visible: config != null && !_closed && roomy,
        child: config == null
            ? const SizedBox.shrink()
            : _buildBanner(context, config),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, NodeBannerConfig config) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ink = scheme.onPrimaryContainer;
    void open() => launchUrl(config.url, mode: LaunchMode.externalApplication);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.4,
        ),
        child: Material(
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeshRadii.md),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 2, 2, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.router_outlined, size: 24, color: ink),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          config.title ?? l10n.scanner_getNodeTitle,
                          style: textTheme.titleMedium?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ink),
                        tooltip: l10n.common_close,
                        onPressed: () => setState(() => _closed = true),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          config.body ?? l10n.scanner_getNodeBody,
                          style: textTheme.bodyMedium?.copyWith(
                            color: ink,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: open,
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: Text(
                            config.action ?? l10n.scanner_getNodeAction,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.scanner_getNodeDisclosure,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: ink.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
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
