import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../l10n/contact_localization.dart';
import '../models/contact.dart';
import '../theme/mesh_theme.dart';
import '../utils/contact_search.dart';
import '../utils/platform_info.dart';
import '../widgets/app_bar.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/mesh_ui.dart';
import '../helpers/snack_bar_builder.dart';

enum DiscoverySortOption { lastSeen, name, type }

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  ContactSortOption sortOption = ContactSortOption.lastSeen;
  bool showUnreadOnly = false;
  ContactTypeFilter typeFilter = ContactTypeFilter.all;
  DiscoverySortOption discoverySortOption = DiscoverySortOption.lastSeen;
  Timer? _searchDebounce;
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _messenger?.hideCurrentSnackBar();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  DateTime _resolveLastSeen(Contact contact) {
    if (contact.type != advTypeChat) return contact.lastSeen;
    return contact.lastMessageAt.isAfter(contact.lastSeen)
        ? contact.lastMessageAt
        : contact.lastSeen;
  }

  /// Node-type avatar color per design language.
  Color _avatarColor(int type) {
    switch (type) {
      case advTypeRepeater:
        return MeshPalette.warn;
      case advTypeRoom:
        return MeshPalette.magenta;
      case advTypeSensor:
        return const Color(0xFF4ACCC4); // teal
      default:
        return MeshPalette.blue;
    }
  }

  /// Node-type avatar icon; null = show initials for chat nodes.
  IconData? _avatarIcon(int type) {
    switch (type) {
      case advTypeRepeater:
        return Icons.cell_tower;
      case advTypeRoom:
        return Icons.meeting_room;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();

    final discoveredContacts = connector.discoveredContacts;
    final filteredAndSorted = _filterAndSortContacts(
      discoveredContacts,
      connector,
    );

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          l10n.discoveredContacts_Title,
          indicators: false,
          subtitle: false,
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(context.l10n.discoveredContacts_deleteContactAll),
                  ],
                ),
                onTap: () {
                  _deleteContacts(context, connector);
                },
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(filteredAndSorted, connector),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: discoveredContacts.isEmpty
                  ? Center(
                      key: const ValueKey('empty_all'),
                      child: Text(l10n.contacts_noContacts),
                    )
                  : filteredAndSorted.isEmpty
                  ? Center(
                      key: const ValueKey('empty_filtered'),
                      child: Text(l10n.discoveredContacts_noMatching),
                    )
                  : ListView.builder(
                      key: const ValueKey('list'),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filteredAndSorted.length,
                      itemBuilder: (context, index) {
                        final contact = filteredAndSorted[index];
                        final tile = _buildDiscoveryTile(
                          context,
                          contact,
                          connector,
                          index,
                        );
                        return tile;
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryTile(
    BuildContext context,
    Contact contact,
    MeshCoreConnector connector,
    int index,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isChat = contact.type == advTypeChat;

    return ListEntrance(
      index: index,
      child: MeshCard(
        onTap: () => _addContact(context, contact, connector),
        onLongPress: () => _showContactContextMenu(contact, connector),
        onSecondaryTap: PlatformInfo.isDesktop
            ? () => _showContactContextMenu(contact, connector)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AvatarCircle(
              name: contact.name,
              size: 42,
              color: isChat ? null : _avatarColor(contact.type),
              icon: _avatarIcon(contact.type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + type chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusChip(
                        label: contact.typeLabel(context.l10n).toUpperCase(),
                        color: _avatarColor(contact.type),
                        icon: _avatarIcon(contact.type),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Short pub key
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.shortPubKeyHex,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MeshTheme.mono(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (contact.hasLocation) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.location_on,
                          size: 13,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ],
                      if (contact.rawPacket != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.cell_tower,
                          size: 13,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Last seen time
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.3),
                ),
              ),
              child: Text(
                _formatLastSeen(context, _resolveLastSeen(contact)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: MeshTheme.mono(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.discoveredContacts_addContact,
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _addContact(context, contact, connector),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addContact(
    BuildContext context,
    Contact contact,
    MeshCoreConnector connector,
  ) async {
    try {
      final imported = await connector.importDiscoveredContact(contact);
      if (!context.mounted) return;
      if (!imported) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactImportFailed),
        );
        return;
      }
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.discoveredContacts_contactAdded),
        action: SnackBarAction(
          label: context.l10n.common_undo,
          onPressed: () => connector.removeContact(contact),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_contactImportFailed),
      );
    }
  }

  Future<void> _showContactContextMenu(
    Contact contact,
    MeshCoreConnector connector,
  ) async {
    final action = await showMeshSheet<String>(
      context,
      builder: (sheetContext) {
        final l10n = context.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                title: contact.name,
                subtitle: contact.typeLabel(l10n),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.discoveredContacts_copyContact),
                onTap: () => Navigator.of(sheetContext).pop('copy_contact'),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(l10n.discoveredContacts_deleteContact),
                onTap: () => Navigator.of(sheetContext).pop('delete_contact'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'copy_contact':
        if (contact.rawPacket == null) return;
        final hexString = pubKeyToHex(contact.rawPacket!);
        Clipboard.setData(ClipboardData(text: "meshcore://$hexString"));
        if (!mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactAdvertCopied),
        );
        break;
      case 'delete_contact':
        connector.removeDiscoveredContact(contact);
        break;
    }
  }

  void _deleteContacts(BuildContext context, MeshCoreConnector connector) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.common_deleteAll),
        content: Text(l10n.discoveredContacts_deleteContactAllContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              connector.removeAllDiscoveredContacts();
            },
            child: Text(l10n.common_deleteAll),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    List<Contact> filteredAndSorted,
    MeshCoreConnector connector,
  ) {
    String hintText = "";
    switch (typeFilter) {
      case ContactTypeFilter.all:
        hintText = context.l10n.contacts_searchContacts(
          filteredAndSorted.length,
          showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.users:
        hintText = context.l10n.contacts_searchUsers(
          filteredAndSorted.length,
          showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.repeaters:
        hintText = context.l10n.contacts_searchRepeaters(
          filteredAndSorted.length,
          showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.rooms:
        hintText = context.l10n.contacts_searchRoomServers(
          filteredAndSorted.length,
          showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.favorites:
        hintText = context.l10n.contacts_searchFavorites(
          filteredAndSorted.length,
          showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: context.l10n.common_clearSearch,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    ),
                  _buildFilterButton(context, connector),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context, MeshCoreConnector connector) {
    return DiscoveryContactsFilterMenu(
      sortOption: sortOption,
      typeFilter: typeFilter,
      onSortChanged: (value) {
        setState(() {
          sortOption = value;
        });
      },
      onTypeFilterChanged: (value) {
        setState(() {
          typeFilter = value;
        });
      },
    );
  }

  List<Contact> _filterAndSortContacts(
    List<Contact> contacts,
    MeshCoreConnector connector,
  ) {
    var filtered = contacts.where((contact) {
      if (searchQuery.isEmpty) return true;
      return matchesDiscoveryContactQuery(contact, searchQuery);
    }).toList();

    filtered = filtered.where((contact) {
      return !connector.knownContactKeys.contains(contact.publicKeyHex);
    }).toList();

    // Filter out own node from the list
    if (connector.selfPublicKey != null) {
      final selfPubKeyHex = pubKeyToHex(connector.selfPublicKey!);
      filtered = filtered.where((contact) {
        return contact.publicKeyHex != selfPubKeyHex;
      }).toList();
    }

    if (typeFilter != ContactTypeFilter.all) {
      filtered = filtered.where(_matchesTypeFilter).toList();
    }

    switch (sortOption) {
      case ContactSortOption.lastSeen:
        filtered.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        break;
      case ContactSortOption.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      default:
        break;
    }

    return filtered;
  }

  bool _matchesTypeFilter(Contact contact) {
    switch (typeFilter) {
      case ContactTypeFilter.all:
        return true;
      case ContactTypeFilter.users:
        return contact.type == advTypeChat;
      case ContactTypeFilter.repeaters:
        return contact.type == advTypeRepeater;
      case ContactTypeFilter.rooms:
        return contact.type == advTypeRoom;
      default:
        return false;
    }
  }

  String _formatLastSeen(BuildContext context, DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.isNegative || diff.inMinutes < 5) {
      return context.l10n.contacts_lastSeenNow;
    }
    if (diff.inMinutes < 60) {
      return context.l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1
          ? context.l10n.contacts_lastSeenHourAgo
          : context.l10n.contacts_lastSeenHoursAgo(hours);
    }
    final days = diff.inDays;
    return days == 1
        ? context.l10n.contacts_lastSeenDayAgo
        : context.l10n.contacts_lastSeenDaysAgo(days);
  }
}
