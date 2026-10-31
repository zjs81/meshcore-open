import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../l10n/contact_localization.dart';
import '../models/contact.dart';
import '../theme/mesh_theme.dart';
import '../utils/contact_search.dart';
import '../utils/platform_info.dart';
import '../utils/share_origin.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_visuals.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/node_scan_sheet.dart';
import '../helpers/snack_bar_builder.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  ContactSortOption sortOption = ContactSortOption.lastSeen;
  ContactTypeFilter typeFilter = ContactTypeFilter.all;
  Timer? _searchDebounce;
  final DerivedListCache<Contact> _filteredCache = DerivedListCache<Contact>();
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
          if (connector.isConnected && connector.supportsNodeDiscover)
            IconButton(
              tooltip: l10n.discoveredContacts_scan,
              icon: const Icon(Icons.radar),
              onPressed: () => showNodeScanSheet(context, connector),
            ),
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
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
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
              color: isChat ? null : contactTypeColor(contact.type),
              iconSlot: contactTypeIconSlot(contact.type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The name gets the full width; a type chip beside it
                  // squeezed it to nothing on narrow screens or large text.
                  // The avatar icon already shows the type.
                  Text(
                    // Nodes can advertise without a name; show the key
                    // prefix rather than a blank title.
                    contact.name.isNotEmpty
                        ? contact.name
                        : contact.publicKeyHex.substring(0, 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Type and short pub key
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${contact.typeLabel(context.l10n)} · '
                          '${contact.shortPubKeyHex}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MeshTheme.mono(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (contact.hasLocation) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                      if (contact.rawPacket != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.cell_tower,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Last seen time. A width cap + wrapping keeps large text scales
            // from overflowing without clamping the user's text size.
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.25,
                ),
                child: Text(
                  formatContactLastSeen(
                    context.l10n,
                    resolveContactLastSeen(contact),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: MeshTheme.mono(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
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
          onPressed: () => unawaited(
            connector.removeContact(contact).catchError((Object _) {
              if (!context.mounted) return;
              showDismissibleSnackBar(
                context,
                content: Text(context.l10n.contacts_removeFailed),
              );
            }),
          ),
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
          child: SingleChildScrollView(
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

  static const int _maxImportBytes = 2 * 1024 * 1024;

  Future<void> _exportDiscoveredContacts(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final shareOrigin = shareOriginOf(context);
    final json = connector.exportDiscoveredContactsJson();

    try {
      const filename = 'meshcore_discovered_contacts.json';
      final exportFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        name: filename,
      );

      if (PlatformInfo.isDesktop) {
        final location = await getSaveLocation(
          suggestedName: filename,
          acceptedTypeGroups: [
            const XTypeGroup(label: 'JSON', extensions: ['json']),
          ],
        );
        if (!mounted) return;
        if (location == null) return;
        await exportFile.saveTo(location.path);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.discoveredContacts_exported(location.path)),
          ),
        );
        return;
      }

      // Mobile shares the in-memory file; web shares it or, without the Web
      // Share API, downloads it (reported as `unavailable`).
      final result = await SharePlus.instance.share(
        ShareParams(
          subject: filename,
          files: [exportFile],
          fileNameOverrides: const [filename],
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (!mounted) return;
      final delivered =
          result.status == ShareResultStatus.success ||
          (PlatformInfo.isWeb &&
              result.status == ShareResultStatus.unavailable);
      if (delivered) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.discoveredContacts_exported(filename))),
        );
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
    void show(String text) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }

    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      // A null file means the picker was cancelled.
      if (file == null) return;
      if (await file.length() > _maxImportBytes) {
        show(
          l10n.discoveredContacts_importTooLarge(
            _maxImportBytes ~/ (1024 * 1024),
          ),
        );
        return;
      }

      final String text;
      try {
        text = utf8.decode(await file.readAsBytes());
      } on FormatException {
        show(
          l10n.discoveredContacts_importFailed(
            l10n.discoveredContacts_importInvalidFile,
          ),
        );
        return;
      }
      // Strip a UTF-8 byte order mark if present.
      final json = text.startsWith('\ufeff') ? text.substring(1) : text;

      final result = await connector.importDiscoveredContactsJson(json);
      if (result.total == 0) {
        show(l10n.discoveredContacts_importNoContacts);
      } else if (result.skipped == 0 && result.invalid == 0) {
        show(l10n.discoveredContacts_imported(result.imported));
      } else {
        show(
          l10n.discoveredContacts_importSummary(
            result.imported,
            result.skipped,
            result.invalid,
          ),
        );
      }
    } on FormatException {
      show(
        l10n.discoveredContacts_importFailed(
          l10n.discoveredContacts_importInvalidFile,
        ),
      );
    } catch (e) {
      show(l10n.discoveredContacts_importFailed(e.toString()));
    }
  }

  Widget _buildFilters(
    List<Contact> filteredAndSorted,
    MeshCoreConnector connector,
  ) {
    final count = filteredAndSorted.length;
    final hintText = switch (typeFilter) {
      ContactTypeFilter.users => context.l10n.contacts_searchUsers(count, ''),
      ContactTypeFilter.repeaters => context.l10n.contacts_searchRepeaters(
        count,
        '',
      ),
      ContactTypeFilter.rooms => context.l10n.contacts_searchRoomServers(
        count,
        '',
      ),
      // Discovery offers no favorites filter; fall back to the generic hint.
      _ => context.l10n.contacts_searchContacts(count, ''),
    };

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
    // knownContactKeys returns a fresh copy; read it once per build.
    final knownKeys = connector.knownContactKeys;
    final selfKey = connector.selfPublicKey;
    final selfPubKeyHex = selfKey == null ? null : pubKeyToHex(selfKey);
    return _filteredCache.get(contacts, [
      searchQuery,
      typeFilter,
      sortOption,
      selfPubKeyHex,
      Object.hashAllUnordered(knownKeys),
    ], () => _computeFilteredContacts(contacts, knownKeys, selfPubKeyHex));
  }

  List<Contact> _computeFilteredContacts(
    List<Contact> contacts,
    Set<String> knownKeys,
    String? selfPubKeyHex,
  ) {
    final filtered = contacts.where((contact) {
      if (searchQuery.isNotEmpty &&
          !matchesDiscoveryContactQuery(contact, searchQuery)) {
        return false;
      }
      if (knownKeys.contains(contact.publicKeyHex)) return false;
      // Filter out own node from the list
      if (contact.publicKeyHex == selfPubKeyHex) return false;
      return _matchesTypeFilter(contact);
    }).toList();

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
      case ContactTypeFilter.favorites:
        // Not offered by the discovery filter menu.
        return true;
    }
  }
}
