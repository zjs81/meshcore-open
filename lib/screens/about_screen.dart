import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';

const String _sourceCodeHost = 'github.com/zjs81/meshcore-open';
final Uri _sourceCodeUrl = Uri.https('github.com', '/zjs81/meshcore-open');
final Uri _licenseUrl = Uri.https(
  'github.com',
  '/zjs81/meshcore-open/blob/HEAD/LICENSE',
);
final Uri _contributorsUrl = Uri.https(
  'github.com',
  '/zjs81/meshcore-open/graphs/contributors',
);

/// Version label for Settings and About.
Future<String> loadAppVersionLabel() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} BETA';
}

/// App name, version, description, source code, licenses and credits.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    loadAppVersionLabel().then((version) {
      if (mounted) setState(() => _version = version);
    });
  }

  Future<void> _open(Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_couldNotOpenLink(url.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final version = _version ?? l10n.common_loading;
    // The current year, so the notice doesn't go stale between releases.
    final legalese = l10n.settings_aboutLegalese('${DateTime.now().year}');
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.settings_about),
        centerTitle: true,
      ),
      body: MeshSettingsTileTheme(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              MeshCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(MeshRadii.sm),
                      child: Image.asset(
                        'assets/images/mesh-icon.png',
                        width: 56,
                        height: 56,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            version,
                            style: MeshTheme.mono(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.settings_aboutDescription,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(l10n.about_project),
              MeshCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    MeshNavTile(
                      icon: Icons.code,
                      title: l10n.about_sourceCode,
                      subtitle: _sourceCodeHost,
                      trailing: Icon(
                        Icons.open_in_new,
                        size: 24,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: () => _open(_sourceCodeUrl),
                    ),
                    const Divider(height: 1, indent: 16),
                    MeshNavTile(
                      icon: Icons.gavel_outlined,
                      title: l10n.about_license,
                      trailing: Icon(
                        Icons.open_in_new,
                        size: 24,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: () => _open(_licenseUrl),
                    ),
                    const Divider(height: 1, indent: 16),
                    MeshNavTile(
                      icon: Icons.description_outlined,
                      title: l10n.about_openSourceLicenses,
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: l10n.appTitle,
                        applicationVersion: version,
                        applicationLegalese: legalese,
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(l10n.about_credits),
              MeshCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    MeshNavTile(
                      icon: Icons.people_outline,
                      title: l10n.about_contributors,
                      trailing: Icon(
                        Icons.open_in_new,
                        size: 24,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: () => _open(_contributorsUrl),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.terrain_outlined, size: 24),
                      title: Text(l10n.settings_aboutOpenMeteoAttribution),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  legalese,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
