import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../utils/contact_search.dart';

class SortFilterMenuOption<T> {
  final T value;
  final String label;
  final bool? checked;

  const SortFilterMenuOption({
    required this.value,
    required this.label,
    this.checked,
  });
}

class SortFilterMenuSection<T> {
  final String title;
  final List<SortFilterMenuOption<T>> options;

  const SortFilterMenuSection({required this.title, required this.options});
}

class SortFilterMenu<T> extends StatelessWidget {
  final List<SortFilterMenuSection<T>> sections;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final Widget icon;

  const SortFilterMenu({
    super.key,
    required this.sections,
    required this.onSelected,
    required this.tooltip,
    this.icon = const Icon(Icons.filter_list_outlined),
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      icon: icon,
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (context) {
        final theme = Theme.of(context);
        final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
        final visibleSections = sections
            .where((section) => section.options.isNotEmpty)
            .toList();
        final entries = <PopupMenuEntry<T>>[];
        for (int i = 0; i < visibleSections.length; i++) {
          final section = visibleSections[i];
          entries.add(
            PopupMenuItem<T>(
              enabled: false,
              child: Text(section.title, style: labelStyle),
            ),
          );
          for (final option in section.options) {
            if (option.checked == null) {
              entries.add(
                PopupMenuItem<T>(
                  value: option.value,
                  child: Text(option.label),
                ),
              );
            } else {
              entries.add(
                CheckedPopupMenuItem<T>(
                  value: option.value,
                  checked: option.checked ?? false,
                  child: Text(option.label),
                ),
              );
            }
          }
          if (i < visibleSections.length - 1) {
            entries.add(const PopupMenuDivider());
          }
        }
        return entries;
      },
    );
  }
}

sealed class _ContactsFilterAction {
  const _ContactsFilterAction();
}

class _SortAction extends _ContactsFilterAction {
  final ContactSortOption option;
  const _SortAction(this.option);
}

class _TypeFilterAction extends _ContactsFilterAction {
  final ContactTypeFilter filter;
  const _TypeFilterAction(this.filter);
}

class _ToggleUnreadAction extends _ContactsFilterAction {
  const _ToggleUnreadAction();
}

class ContactsFilterMenu extends StatelessWidget {
  final ContactSortOption sortOption;
  final ContactTypeFilter typeFilter;
  final bool showUnreadOnly;
  final ValueChanged<ContactSortOption> onSortChanged;
  final ValueChanged<ContactTypeFilter> onTypeFilterChanged;
  final ValueChanged<bool> onUnreadOnlyChanged;

  const ContactsFilterMenu({
    super.key,
    required this.sortOption,
    required this.typeFilter,
    required this.showUnreadOnly,
    required this.onSortChanged,
    required this.onTypeFilterChanged,
    required this.onUnreadOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SortFilterMenu<_ContactsFilterAction>(
      tooltip: l10n.listFilter_tooltip,
      sections: [
        SortFilterMenuSection(
          title: l10n.listFilter_sortBy,
          options: [
            SortFilterMenuOption(
              value: _SortAction(ContactSortOption.recentMessages),
              label: l10n.listFilter_latestMessages,
              checked: sortOption == ContactSortOption.recentMessages,
            ),
            SortFilterMenuOption(
              value: _SortAction(ContactSortOption.lastSeen),
              label: l10n.listFilter_heardRecently,
              checked: sortOption == ContactSortOption.lastSeen,
            ),
            SortFilterMenuOption(
              value: _SortAction(ContactSortOption.name),
              label: l10n.listFilter_az,
              checked: sortOption == ContactSortOption.name,
            ),
          ],
        ),
        SortFilterMenuSection(
          title: l10n.listFilter_filters,
          options: [
            SortFilterMenuOption(
              value: _TypeFilterAction(ContactTypeFilter.all),
              label: l10n.listFilter_all,
              checked: typeFilter == ContactTypeFilter.all,
            ),
            SortFilterMenuOption(
              value: _TypeFilterAction(ContactTypeFilter.favorites),
              label: l10n.listFilter_favorites,
              checked: typeFilter == ContactTypeFilter.favorites,
            ),
            SortFilterMenuOption(
              value: _TypeFilterAction(ContactTypeFilter.users),
              label: l10n.listFilter_users,
              checked: typeFilter == ContactTypeFilter.users,
            ),
            SortFilterMenuOption(
              value: _TypeFilterAction(ContactTypeFilter.repeaters),
              label: l10n.listFilter_repeaters,
              checked: typeFilter == ContactTypeFilter.repeaters,
            ),
            SortFilterMenuOption(
              value: _TypeFilterAction(ContactTypeFilter.rooms),
              label: l10n.listFilter_roomServers,
              checked: typeFilter == ContactTypeFilter.rooms,
            ),
            SortFilterMenuOption(
              value: const _ToggleUnreadAction(),
              label: l10n.listFilter_unreadOnly,
              checked: showUnreadOnly,
            ),
          ],
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _SortAction(:final option):
            onSortChanged(option);
          case _TypeFilterAction(:final filter):
            onTypeFilterChanged(filter);
          case _ToggleUnreadAction():
            onUnreadOnlyChanged(!showUnreadOnly);
        }
      },
    );
  }
}

sealed class _DiscoveryFilterAction {
  const _DiscoveryFilterAction();
}

class _DiscoverySortAction extends _DiscoveryFilterAction {
  final ContactSortOption option;
  const _DiscoverySortAction(this.option);
}

class _DiscoveryTypeFilterAction extends _DiscoveryFilterAction {
  final ContactTypeFilter filter;
  const _DiscoveryTypeFilterAction(this.filter);
}

class DiscoveryContactsFilterMenu extends StatelessWidget {
  final ContactSortOption sortOption;
  final ContactTypeFilter typeFilter;
  final ValueChanged<ContactSortOption> onSortChanged;
  final ValueChanged<ContactTypeFilter> onTypeFilterChanged;

  const DiscoveryContactsFilterMenu({
    super.key,
    required this.sortOption,
    required this.typeFilter,
    required this.onSortChanged,
    required this.onTypeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SortFilterMenu<_DiscoveryFilterAction>(
      tooltip: l10n.listFilter_tooltip,
      sections: [
        SortFilterMenuSection(
          title: l10n.listFilter_sortBy,
          options: [
            SortFilterMenuOption(
              value: _DiscoverySortAction(ContactSortOption.lastSeen),
              label: l10n.listFilter_heardRecently,
              checked: sortOption == ContactSortOption.lastSeen,
            ),
            SortFilterMenuOption(
              value: _DiscoverySortAction(ContactSortOption.name),
              label: l10n.listFilter_az,
              checked: sortOption == ContactSortOption.name,
            ),
          ],
        ),
        SortFilterMenuSection(
          title: l10n.listFilter_filters,
          options: [
            SortFilterMenuOption(
              value: _DiscoveryTypeFilterAction(ContactTypeFilter.all),
              label: l10n.listFilter_all,
              checked: typeFilter == ContactTypeFilter.all,
            ),
            SortFilterMenuOption(
              value: _DiscoveryTypeFilterAction(ContactTypeFilter.users),
              label: l10n.listFilter_users,
              checked: typeFilter == ContactTypeFilter.users,
            ),
            SortFilterMenuOption(
              value: _DiscoveryTypeFilterAction(ContactTypeFilter.repeaters),
              label: l10n.listFilter_repeaters,
              checked: typeFilter == ContactTypeFilter.repeaters,
            ),
            SortFilterMenuOption(
              value: _DiscoveryTypeFilterAction(ContactTypeFilter.rooms),
              label: l10n.listFilter_roomServers,
              checked: typeFilter == ContactTypeFilter.rooms,
            ),
          ],
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _DiscoverySortAction(:final option):
            onSortChanged(option);
          case _DiscoveryTypeFilterAction(:final filter):
            onTypeFilterChanged(filter);
        }
      },
    );
  }
}
