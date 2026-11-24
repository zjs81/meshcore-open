import 'package:flutter/material.dart';

import '../theme/theme_icons.dart';

/// Title style of settings rows: [MeshNavTile] and, through
/// [MeshSettingsTileTheme], stock [ListTile]s and [SwitchListTile]s.
TextStyle? meshTileTitleStyle(ThemeData theme) =>
    theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);

/// Gives the [ListTile]s, [SwitchListTile]s and [CheckboxListTile]s below it
/// the same semibold title as [MeshNavTile], so settings rows built from
/// either read alike. Subtitles already match (`bodyMedium`,
/// `onSurfaceVariant`). Wrap a settings screen's body in it.
class MeshSettingsTileTheme extends StatelessWidget {
  final Widget child;

  const MeshSettingsTileTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListTileTheme.merge(
      titleTextStyle: meshTileTitleStyle(Theme.of(context)),
      child: child,
    );
  }
}

/// Settings-style navigation row: leading icon, bold title, secondary
/// subtitle and an optional trailing chevron.
///
/// Sized for readability (24px icons, `bodyLarge` titles, `bodyMedium`
/// subtitles). When [onTap] is null the row is rendered dimmed and reported
/// as disabled to accessibility services, so a tile that cannot be used never
/// looks identical to one that can.
class MeshNavTile extends StatelessWidget {
  final IconData icon;

  /// Theme icon to show instead of [icon], so the row follows the user's
  /// theme like the contact list does.
  final ThemeIconSlot? iconSlot;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showChevron;

  /// Shows the 18px spinner in place of the chevron and ignores taps while
  /// the row's action runs (e.g. a radio command). The row isn't dimmed.
  final bool busy;
  final Widget? trailing;
  final int? subtitleMaxLines;
  final EdgeInsetsGeometry padding;

  const MeshNavTile({
    super.key,
    required this.icon,
    this.iconSlot,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.showChevron = true,
    this.busy = false,
    this.trailing,
    this.subtitleMaxLines,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final enabled = onTap != null;
    final effectiveIconColor = iconColor ?? scheme.onSurfaceVariant;

    final row = Row(
      children: [
        iconSlot == null
            ? Icon(icon, size: 24, color: effectiveIconColor)
            : ThemedIcon(iconSlot!, size: 24, color: effectiveIconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: meshTileTitleStyle(theme)?.copyWith(color: titleColor),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: subtitleMaxLines,
                  overflow: subtitleMaxLines == null
                      ? null
                      : TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: titleColor != null
                        ? titleColor!.withValues(alpha: 0.8)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
        if (busy && trailing == null)
          const SizedBox.square(
            dimension: 24,
            child: Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (showChevron && trailing == null)
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 24),
      ],
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled && !busy,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: padding,
            // Dimmed rather than recoloured so warn/alert tints still read as
            // such while clearly unavailable.
            child: Opacity(opacity: enabled ? 1 : 0.5, child: row),
          ),
        ),
      ),
    );
  }
}

/// One radio-style option row inside a bottom sheet picker.
/// The selected row shows a filled radio icon and a bold title, so the
/// choice never depends on colour alone. A null [onTap] disables the row.
class MeshSheetOption extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const MeshSheetOption({
    super.key,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 24,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: selected ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
