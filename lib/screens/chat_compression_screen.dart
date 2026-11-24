import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/chat_compression_mode.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';

export '../models/chat_compression_mode.dart';

String chatCompressionModeLabel(BuildContext context, ChatCompressionMode m) {
  final l10n = context.l10n;
  return switch (m) {
    ChatCompressionMode.off => l10n.chatCompression_off,
    ChatCompressionMode.smaz => l10n.chatCompression_smaz,
    ChatCompressionMode.cyr2lat => l10n.chatCompression_cyr2lat,
  };
}

/// What the page shows for one chat, read fresh each time [listenable] fires.
class ChatCompressionState {
  final ChatCompressionMode mode;

  /// False locks the choices; [disabledReason] says why.
  final bool enabled;
  final String? disabledReason;

  final List<Cyr2LatProfile> profiles;

  /// The Cyr2Lat profile saved for this chat, if any.
  final String? profileId;

  /// The app-wide profile, which sending uses when [profileId] is unset or
  /// no longer exists.
  final String? defaultProfileId;

  const ChatCompressionState({
    required this.mode,
    required this.enabled,
    this.disabledReason,
    required this.profiles,
    required this.profileId,
    this.defaultProfileId,
  });

  /// The profile sending actually uses, matching the connector's fallback.
  String? get effectiveProfileId {
    bool known(String? id) => profiles.any((p) => p.id == id);
    if (known(profileId)) return profileId;
    if (known(defaultProfileId)) return defaultProfileId;
    return profiles.isEmpty ? null : profiles.first.id;
  }
}

/// The page behind the chat menu's "Compression: ..." item. Shows the three
/// choices with a short note each, plus the Cyr2Lat profile picker.
///
/// The caller supplies the saved state through [read] (re-read whenever
/// [listenable] notifies) and persists changes through the callbacks. A new
/// choice shows only once the saved state changes; a callback that throws
/// leaves the saved choice in place and shows an error.
class ChatCompressionScreen extends StatefulWidget {
  final Listenable listenable;
  final ChatCompressionState Function() read;
  final Future<void> Function(ChatCompressionMode mode) onModeChanged;
  final Future<void> Function(String profileId) onProfileChanged;

  const ChatCompressionScreen({
    super.key,
    required this.listenable,
    required this.read,
    required this.onModeChanged,
    required this.onProfileChanged,
  });

  @override
  State<ChatCompressionScreen> createState() => _ChatCompressionScreenState();
}

class _ChatCompressionScreenState extends State<ChatCompressionScreen> {
  bool _busy = false;
  bool _failed = false;

  /// Counts failed saves, so the profile picker drops an unsaved choice.
  int _failures = 0;

  /// Runs one save; a failure keeps the saved state and shows an error.
  Future<void> _save(Future<void> Function() write) async {
    if (_busy || !widget.read().enabled) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    var ok = false;
    try {
      await write();
      ok = true;
    } catch (e) {
      debugPrint('[ChatCompressionScreen] save failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
      if (!ok) _failures++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.chatCompression_title),
        centerTitle: true,
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.listenable,
          builder: (context, _) => _buildBody(context, widget.read()),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatCompressionState view) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canChange = view.enabled && !_busy;

    Widget option(ChatCompressionMode mode, String description) {
      return MeshSheetOption(
        label: chatCompressionModeLabel(context, mode),
        subtitle: description,
        selected: view.mode == mode,
        onTap: canChange ? () => _save(() => widget.onModeChanged(mode)) : null,
      );
    }

    final profileValue = view.effectiveProfileId;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_failed)
          MeshCard(
            color: scheme.errorContainer,
            borderColor: scheme.errorContainer,
            child: Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.chatCompression_saveFailed,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!view.enabled && view.disabledReason != null)
          MeshInfoCard(view.disabledReason!),
        SectionHeader(
          l10n.chatCompression_title,
          description: l10n.chatCompression_sheetSubtitle,
        ),
        MeshCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              option(
                ChatCompressionMode.off,
                l10n.chatCompression_offDescription,
              ),
              const Divider(height: 1, indent: 16),
              option(
                ChatCompressionMode.smaz,
                l10n.chatCompression_smazDescription,
              ),
              const Divider(height: 1, indent: 16),
              option(
                ChatCompressionMode.cyr2lat,
                l10n.chatCompression_cyr2latDescription,
              ),
            ],
          ),
        ),
        if (view.mode == ChatCompressionMode.cyr2lat &&
            view.profiles.isNotEmpty) ...[
          SectionHeader(l10n.chatCompression_profile),
          MeshCard(
            child: DropdownButtonFormField<String>(
              // The field keeps a picked value internally, so rebuild it
              // with the saved value after a change or a failure.
              key: ValueKey('$profileValue#$_failures'),
              isExpanded: true,
              initialValue: profileValue,
              decoration: InputDecoration(
                labelText: l10n.chatCompression_profile,
              ),
              items: [
                for (final profile in view.profiles)
                  DropdownMenuItem(
                    value: profile.id,
                    child: Text(profile.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: canChange
                  ? (id) {
                      if (id == null || id == profileValue) return;
                      _save(() => widget.onProfileChanged(id));
                    }
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}
