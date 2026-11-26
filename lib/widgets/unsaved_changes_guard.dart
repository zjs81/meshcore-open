import 'package:flutter/material.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../utils/radio_guard.dart';
import 'adaptive_app_bar_title.dart';
import 'mesh_nav_tile.dart';
import 'radio_disconnected_banner.dart';
import 'sync_progress_overlay.dart';

/// Asks before leaving with unsaved edits: Cancel, Discard or Save. A
/// successful save closes the page.
class UnsavedChangesGuard extends StatelessWidget {
  final bool hasChanges;

  /// Whether the dialog offers Save.
  final bool canSave;

  /// Returns whether the save succeeded.
  final Future<bool> Function() onSave;

  /// Dialog body.
  final String message;

  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    required this.canSave,
    required this.onSave,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave(context);
      },
      child: child,
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final l10n = context.l10n;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.repeater_unsavedChangesTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.repeater_discardChanges),
          ),
          FilledButton(
            onPressed: canSave
                ? () => Navigator.pop(dialogContext, true)
                : null,
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
    if (save == null || !context.mounted) return;
    if (save && !await onSave()) return;
    if (!context.mounted) return;
    // Navigator.pop skips the PopScope check.
    Navigator.of(context).pop();
  }
}

/// App bar Save button: hidden without changes, disabled when [onPressed] is
/// null (also while saving; the top bar shows the wait).
class SaveChangesAction extends StatelessWidget {
  final bool visible;
  final VoidCallback? onPressed;

  const SaveChangesAction({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: Text(context.l10n.common_save),
    );
  }
}

/// Page for settings saved to the radio: app bar Save, disconnected banner
/// and [UnsavedChangesGuard]. Errors thrown by [onSave] go to a snackbar.
class SaveToRadioPage extends StatefulWidget {
  final String title;
  final bool hasChanges;

  /// False while a field is invalid.
  final bool canSave;

  /// Sends the edits. Returns false if nothing was sent (failed validation).
  final Future<bool> Function() onSave;

  final List<Widget> children;

  const SaveToRadioPage({
    super.key,
    required this.title,
    required this.hasChanges,
    this.canSave = true,
    required this.onSave,
    required this.children,
  });

  @override
  State<SaveToRadioPage> createState() => SaveToRadioPageState();
}

class SaveToRadioPageState extends State<SaveToRadioPage> {
  bool _saving = false;

  /// Saves valid, unsaved edits; returns whether it did.
  Future<bool> save() async {
    if (_saving || !widget.hasChanges || !widget.canSave) return false;
    if (!ensureRadioConnected(context)) return false;
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      return await widget.onSave();
    } catch (e) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_error(e.toString())),
        );
      }
      return false;
    } finally {
      // However fast the save, let a frame draw the bar first.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = widget.canSave && !context.radioReadOnly && !_saving;
    return UnsavedChangesGuard(
      hasChanges: widget.hasChanges,
      canSave: canSave,
      message: context.l10n.settings_unsavedChangesMessage,
      onSave: save,
      child: Scaffold(
        appBar: AppBar(
          title: AdaptiveAppBarTitle(widget.title),
          centerTitle: true,
          actions: [
            SaveChangesAction(
              visible: widget.hasChanges,
              onPressed: canSave ? save : null,
            ),
          ],
          // Moves while the save waits for the radio.
          bottom: MeshProgressAppBarBottom(active: _saving),
        ),
        body: MeshSettingsTileTheme(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [const RadioDisconnectedBanner(), ...widget.children],
            ),
          ),
        ),
      ),
    );
  }
}
