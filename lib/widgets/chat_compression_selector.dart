import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/chat_compression_mode.dart';
import '../theme/mesh_theme.dart';
import 'mesh_nav_tile.dart';
import 'mesh_ui.dart';

export '../models/chat_compression_mode.dart';

/// Always-visible "Compression: Off / SMAZ / Cyr2Lat" strip for the top of a
/// DM or channel chat. Tapping it opens one sheet with the three choices,
/// what each does, and the Cyr2Lat profile picker.
///
/// The parent supplies the saved state and persists changes through the
/// callbacks; this widget only shows a new mode once the parent rebuilds it
/// with that mode. A callback that throws leaves the saved mode in place and
/// shows an error in the sheet.
class ChatCompressionSelector extends StatefulWidget {
  final ChatCompressionMode mode;

  /// False disables the strip and the sheet; [disabledReason] says why.
  final bool enabled;
  final String? disabledReason;

  final List<Cyr2LatProfile> profiles;

  /// The Cyr2Lat profile saved for this chat, if any.
  final String? profileId;

  /// The app-wide profile, which sending uses when [profileId] is unset or
  /// no longer exists.
  final String? defaultProfileId;

  final Future<void> Function(ChatCompressionMode mode) onModeChanged;
  final Future<void> Function(String profileId) onProfileChanged;

  const ChatCompressionSelector({
    super.key,
    required this.mode,
    required this.enabled,
    this.disabledReason,
    required this.profiles,
    required this.profileId,
    this.defaultProfileId,
    required this.onModeChanged,
    required this.onProfileChanged,
  });

  /// The profile sending actually uses, matching the connector's fallback.
  String? get effectiveProfileId {
    bool known(String? id) => profiles.any((p) => p.id == id);
    if (known(profileId)) return profileId;
    if (known(defaultProfileId)) return defaultProfileId;
    return profiles.isEmpty ? null : profiles.first.id;
  }

  @override
  State<ChatCompressionSelector> createState() =>
      _ChatCompressionSelectorState();
}

String chatCompressionModeLabel(BuildContext context, ChatCompressionMode m) {
  final l10n = context.l10n;
  return switch (m) {
    ChatCompressionMode.off => l10n.chatCompression_off,
    ChatCompressionMode.smaz => l10n.chatCompression_smaz,
    ChatCompressionMode.cyr2lat => l10n.chatCompression_cyr2lat,
  };
}

/// What the open sheet renders. The sheet is a separate route, so it listens
/// to this instead of rebuilding with the strip.
class _SelectorView {
  final ChatCompressionMode mode;
  final bool enabled;
  final List<Cyr2LatProfile> profiles;
  final String? profileId;
  final bool busy;
  final bool failed;

  /// Counts failed saves, so the profile picker drops an unsaved choice.
  final int failures;

  const _SelectorView({
    required this.mode,
    required this.enabled,
    required this.profiles,
    required this.profileId,
    required this.busy,
    required this.failed,
    required this.failures,
  });
}

class _ChatCompressionSelectorState extends State<ChatCompressionSelector> {
  late final ValueNotifier<_SelectorView> _view = ValueNotifier(_snapshot());
  bool _busy = false;
  bool _failed = false;
  int _failures = 0;

  _SelectorView _snapshot() => _SelectorView(
    mode: widget.mode,
    enabled: widget.enabled,
    profiles: widget.profiles,
    profileId: widget.effectiveProfileId,
    busy: _busy,
    failed: _failed,
    failures: _failures,
  );

  @override
  void didUpdateWidget(covariant ChatCompressionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The sheet route is not below this widget, so it can't be marked dirty
    // during this build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _view.value = _snapshot();
    });
  }

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  void _setBusy(bool busy, {required bool failed}) {
    setState(() {
      _busy = busy;
      _failed = failed;
      if (failed) _failures++;
    });
    _view.value = _snapshot();
  }

  /// Runs one save; returns whether it succeeded.
  Future<bool> _save(Future<void> Function() write) async {
    if (_busy || !widget.enabled) return false;
    _setBusy(true, failed: false);
    var ok = false;
    try {
      await write();
      ok = true;
    } catch (e) {
      debugPrint('[ChatCompressionSelector] save failed: $e');
    }
    if (mounted) _setBusy(false, failed: !ok);
    return ok;
  }

  Future<void> _openSheet() async {
    if (_failed) _setBusy(false, failed: false);
    await showMeshSheet<void>(
      context,
      builder: (sheetContext) => ValueListenableBuilder<_SelectorView>(
        valueListenable: _view,
        builder: (sheetContext, view, _) => _buildSheet(sheetContext, view),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, _SelectorView view) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canChange = view.enabled && !view.busy;

    MeshSheetOption option(ChatCompressionMode mode, String description) {
      return MeshSheetOption(
        label: chatCompressionModeLabel(context, mode),
        subtitle: description,
        selected: view.mode == mode,
        onTap: canChange
            ? () async {
                final ok = await _save(() => widget.onModeChanged(mode));
                // Cyr2Lat stays open so its profile can be picked.
                if (ok && mode != ChatCompressionMode.cyr2lat) {
                  if (context.mounted) Navigator.of(context).maybePop();
                }
              }
            : null,
      );
    }

    final profileValue = view.profileId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(
          title: l10n.chatCompression_title,
          subtitle: l10n.chatCompression_sheetSubtitle,
          trailing: view.busy
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (view.failed)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(MeshRadii.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.chatCompression_saveFailed,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!view.enabled && widget.disabledReason != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      widget.disabledReason!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                option(
                  ChatCompressionMode.off,
                  l10n.chatCompression_offDescription,
                ),
                option(
                  ChatCompressionMode.smaz,
                  l10n.chatCompression_smazDescription,
                ),
                option(
                  ChatCompressionMode.cyr2lat,
                  l10n.chatCompression_cyr2latDescription,
                ),
                if (view.mode == ChatCompressionMode.cyr2lat &&
                    view.profiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: DropdownButtonFormField<String>(
                      // The field keeps a picked value internally, so rebuild
                      // it with the saved value after a change or a failure.
                      key: ValueKey('$profileValue#${view.failures}'),
                      isExpanded: true,
                      initialValue: profileValue,
                      decoration: InputDecoration(
                        labelText: l10n.chatCompression_profile,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final profile in view.profiles)
                          DropdownMenuItem(
                            value: profile.id,
                            child: Text(
                              profile.name,
                              overflow: TextOverflow.ellipsis,
                            ),
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
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final label = l10n.chatCompression_label(
      chatCompressionModeLabel(context, widget.mode),
    );
    final reason = widget.enabled ? null : widget.disabledReason;

    // One short row: the chat already leaves little room for messages at
    // large text sizes, so a disabled strip explains itself in the sheet.
    return Material(
      color: scheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: MergeSemantics(
          child: Semantics(
            button: true,
            enabled: !_busy,
            label: reason == null ? label : '$label. $reason',
            hint: l10n.chatCompression_changeHint,
            child: InkWell(
              onTap: _busy ? null : _openSheet,
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (_busy)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            widget.enabled
                                ? Icons.arrow_drop_down
                                : Icons.lock_outline,
                            color: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
