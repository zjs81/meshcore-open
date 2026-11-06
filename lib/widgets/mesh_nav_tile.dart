import 'package:flutter/material.dart';

/// Settings-style navigation row: leading icon, bold title, secondary
/// subtitle and an optional trailing chevron.
///
/// Sized for readability (24px icons, `bodyLarge` titles, `bodyMedium`
/// subtitles). When [onTap] is null the row is rendered dimmed and reported
/// as disabled to accessibility services, so a tile that cannot be used never
/// looks identical to one that can.
class MeshNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showChevron;
  final Widget? trailing;
  final int? subtitleMaxLines;
  final EdgeInsetsGeometry padding;

  const MeshNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.showChevron = true,
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
        Icon(icon, size: 24, color: effectiveIconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
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
        if (showChevron && trailing == null)
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 24),
      ],
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: InkWell(
          onTap: onTap,
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
class MeshSheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MeshSheetOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 24,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
