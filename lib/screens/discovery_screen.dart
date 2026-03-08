import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../utils/contact_search.dart';
import '../widgets/app_bar.dart';
import '../widgets/list_filter_widget.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
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
                    const Icon(Icons.delete, color: Colors.red),
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
            child: discoveredContacts.isEmpty
                ? Center(child: Text(l10n.contacts_noContacts))
                : filteredAndSorted.isEmpty
                ? Center(child: Text(l10n.discoveredContacts_noMatching))
                : ListView.builder(
                    itemCount: filteredAndSorted.length,
                    itemBuilder: (context, index) {
                      final contact = filteredAndSorted[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(contact.type),
                          child: Icon(
                            _getTypeIcon(contact.type),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          contact.shortPubKeyHex,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatLastSeen(context, contact.lastSeen),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          connector.importDiscoveredContact(contact);
                        },
                        onLongPress: () =>
                            _showContactContextMenu(contact, connector),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContactContextMenu(
    Contact contact,
    MeshCoreConnector connector,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = context.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_reaction_sharp),
                title: Text(l10n.discoveredContacts_addContact),
                onTap: () => Navigator.of(sheetContext).pop('import_contact'),
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
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'import_contact':
        connector.importDiscoveredContact(contact);
        break;
      case 'copy_contact':
        if (contact.rawPacket == null) return;
        final hexString = pubKeyToHex(contact.rawPacket!);
        Clipboard.setData(ClipboardData(text: "meshcore://$hexString"));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contacts_contactAdvertCopied)),
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

  IconData _getTypeIcon(int type) {
    switch (type) {
      case advTypeChat:
        return Icons.chat;
      case advTypeRepeater:
        return Icons.cell_tower;
      case advTypeRoom:
        return Icons.group;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case advTypeChat:
        return Colors.blue;
      case advTypeRepeater:
        return Colors.orange;
      case advTypeRoom:
        return Colors.purple;
      case advTypeSensor:
        return Colors.green;
      default:
        return Colors.grey;
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
