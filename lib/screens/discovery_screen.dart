import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../utils/contact_search.dart';
import '../utils/platform_info.dart';
import '../widgets/app_bar.dart';
import '../widgets/list_filter_widget.dart';
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

  @override
  void dispose() {
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  unawaited(_exportDiscoveredContacts(context, connector));
                  break;
                case 'import':
                  unawaited(_importDiscoveredContacts(context, connector));
                  break;
                case 'delete_all':
                  _deleteContacts(context, connector);
                  break;
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 8),
                    Text(l10n.discoveredContacts_export),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text(l10n.discoveredContacts_import),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(context.l10n.discoveredContacts_deleteContactAll),
                  ],
                ),
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
                      final tile = ListTile(
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
                        // Clamp text scaling in trailing section to prevent overflow while
                        // maintaining accessibility. Primary content (title/subtitle) scales normally.
                        trailing: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(
                              MediaQuery.textScalerOf(
                                context,
                              ).scale(1.0).clamp(1.0, 1.3),
                            ),
                          ),
                          child: SizedBox(
                            width: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatLastSeen(
                                    context,
                                    _resolveLastSeen(contact),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (contact.hasLocation)
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                    if (contact.rawPacket != null)
                                      const SizedBox(width: 2),
                                    if (contact.rawPacket != null)
                                      Icon(
                                        Icons.cell_tower,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          connector.importDiscoveredContact(contact);
                        },
                        onLongPress: () =>
                            _showContactContextMenu(contact, connector),
                      );
                      if (PlatformInfo.isDesktop) {
                        return GestureDetector(
                          onSecondaryTapUp: (_) =>
                              _showContactContextMenu(contact, connector),
                          child: tile,
                        );
                      }
                      return tile;
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

  Future<void> _exportDiscoveredContacts(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final json = connector.exportDiscoveredContactsJson();

    try {
      const filename = 'meshcore_discovered_contacts.json';
      final bytes = Uint8List.fromList(utf8.encode(json));

      if (PlatformInfo.isDesktop) {
        final location = await getSaveLocation(
          suggestedName: filename,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'JSON', extensions: ['json']),
          ],
        );
        if (!mounted) return;
        if (location == null) return;
        final exportFile = XFile.fromData(
          bytes,
          mimeType: 'application/json',
          name: filename,
        );
        await exportFile.saveTo(location.path);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.discoveredContacts_exported(location.path)),
          ),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final exportPath = '${tempDir.path}/$filename';
      final exportFile = File(exportPath);
      await exportFile.writeAsBytes(bytes, flush: true);

      try {
        final result = await SharePlus.instance.share(
          ShareParams(subject: filename, files: [XFile(exportPath)]),
        );

        if (!mounted) return;
        if (result.status == ShareResultStatus.success) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.discoveredContacts_exported(filename))),
          );
        }
      } finally {
        if (await exportFile.exists()) {
          await exportFile.delete();
        }
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.discoveredContacts_exportFailed(e.toString())),
        ),
      );
    }
  }

  Future<void> _importDiscoveredContacts(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await _resolveImportJson(context);
      if (json == null) {
        // User cancelled the file picker — nothing to do.
        return;
      }
      final foundCount = _countContactsInImportJson(json);
      if (foundCount == 0) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.discoveredContacts_importNoContacts)),
        );
        return;
      }

      final importedCount = await connector.importDiscoveredContactsJson(json);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.discoveredContacts_imported(importedCount)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.discoveredContacts_importFailed(e.toString())),
        ),
      );
    }
  }

  Future<String?> _resolveImportJson(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) return '';

    // Try UTF-8 first (handles BOM automatically)
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      // Remove BOM if present
      return text.startsWith('\ufeff') ? text.substring(1) : text;
    } catch (_) {
      return '';
    }
  }

  int _countContactsInImportJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
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
