import 'dart:ui';

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import '../theme/theme_icons.dart';

class QuickSwitchBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int contactsUnreadCount;
  final int channelsUnreadCount;
  final bool highContrast;

  const QuickSwitchBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.contactsUnreadCount = 0,
    this.channelsUnreadCount = 0,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium ?? const TextStyle();
    // Custom themes style the bar on map screens like everywhere else; only
    // the stock theme uses the fixed high-contrast map palette.
    final highContrast =
        this.highContrast && !MeshMapTheme.of(context).followsTheme;
    final background = highContrast ? MapPalette.panelDark : Colors.transparent;
    // The selected icon sits on the primary indicator pill, so it uses
    // onPrimary. The label sits below on the bar background, so it must use a
    // foreground color that contrasts with the surface (not onPrimary, which
    // is white-on-white in the light theme).
    final selectedIconColor = highContrast
        ? MapPalette.textPrimary
        : colorScheme.onPrimary;
    final selectedLabelColor = highContrast
        ? MapPalette.textPrimary
        : colorScheme.onSurface;
    final unselectedColor = highContrast
        ? MapPalette.textSecondary
        : colorScheme.onSurfaceVariant;
    final indicator = highContrast ? MapPalette.selected : colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                color: highContrast
                    ? MapPalette.border
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                indicatorColor: indicator,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return labelStyle.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? selectedLabelColor : unselectedColor,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: isSelected ? selectedIconColor : unselectedColor,
                  );
                }),
              ),
              child: NavigationBar(
                // Picture icons are drawn larger than plain ones; give them
                // room above the labels.
                height:
                    MeshIconTheme.of(context).hasPictureFor(const [
                      ThemeIconSlot.contacts,
                      ThemeIconSlot.channels,
                      ThemeIconSlot.map,
                    ])
                    ? 76
                    : 60,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  NavigationDestination(
                    icon: _buildIconWithBadge(
                      context,
                      const ThemedIcon(ThemeIconSlot.contacts),
                      contactsUnreadCount,
                    ),
                    selectedIcon: _buildIconWithBadge(
                      context,
                      const ThemedIcon(ThemeIconSlot.contacts, selected: true),
                      contactsUnreadCount,
                    ),
                    label: context.l10n.nav_contacts,
                  ),
                  NavigationDestination(
                    icon: _buildIconWithBadge(
                      context,
                      const ThemedIcon(ThemeIconSlot.channels),
                      channelsUnreadCount,
                    ),
                    selectedIcon: _buildIconWithBadge(
                      context,
                      const ThemedIcon(ThemeIconSlot.channels, selected: true),
                      channelsUnreadCount,
                    ),
                    label: context.l10n.nav_channels,
                  ),
                  NavigationDestination(
                    icon: const ThemedIcon(ThemeIconSlot.map),
                    selectedIcon: const ThemedIcon(
                      ThemeIconSlot.map,
                      selected: true,
                    ),
                    label: context.l10n.nav_map,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(BuildContext context, Widget icon, int count) {
    if (count <= 0) return icon;
    final label = count > 99 ? '99+' : '$count';
    return Badge(label: Text(label), child: icon);
  }
}
