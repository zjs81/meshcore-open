import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/utils/app_logger.dart';
import 'package:meshcore_open/widgets/app_bar.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../storage/contact_group_store.dart';
import '../utils/contact_search.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/emoji_utils.dart';
import '../utils/route_transitions.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/repeater_login_dialog.dart';
import '../widgets/room_login_dialog.dart';
import '../widgets/unread_badge.dart';
import '../services/room_sync_service.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'discovery_screen.dart';
import 'map_screen.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';

enum RoomLoginDestination { chat, management }

enum ContactOperationType { import, export, zeroHopShare }

class ContactsScreen extends StatefulWidget {
  final bool hideBackButton;

  const ContactsScreen({super.key, this.hideBackButton = false});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with DisconnectNavigationMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ContactSortOption _sortOption = ContactSortOption.lastSeen;
  bool _showUnreadOnly = false;
  ContactTypeFilter _typeFilter = ContactTypeFilter.all;
  final ContactGroupStore _groupStore = ContactGroupStore();
  List<ContactGroup> _groups = [];
  Timer? _searchDebounce;

  final Set<ContactOperationType> _pendingOperations = {};

  StreamSubscription<Uint8List>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _setupFrameListener();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _frameSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groups = await _groupStore.loadGroups();
    if (!mounted) return;
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _saveGroups() async {
    await _groupStore.saveGroups(_groups);
  }

  void _setupFrameListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final frameBuffer = BufferReader(frame);
      try {
        final code = frameBuffer.readUInt8();

        if (code == respCodeExportContact) {
          final advertPacket = frameBuffer.readRemainingBytes();
          // Validate packet has expected minimum size (98+ bytes per protocol)
          if (advertPacket.length < 98) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.contacts_invalidAdvertFormat),
                ),
              );
            }
            _pendingOperations.remove(ContactOperationType.export);
            return;
          }
          final hexString = pubKeyToHex(advertPacket);
          Clipboard.setData(ClipboardData(text: "meshcore://$hexString"));
        }

        if (code == respCodeOk) {
          // Show a snackbar indicating success
          if (!mounted) return;

          if (_pendingOperations.contains(ContactOperationType.import)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.contacts_contactImported)),
            );
          }

          if (_pendingOperations.contains(ContactOperationType.zeroHopShare)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.contacts_zeroHopContactAdvertSent),
              ),
            );
          }

          if (_pendingOperations.contains(ContactOperationType.export)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.contacts_contactAdvertCopied),
              ),
            );
          }

          _pendingOperations.clear();
        }

        if (code == respCodeErr) {
          // Show a snackbar indicating failure
          if (!mounted) return;

          if (_pendingOperations.contains(ContactOperationType.import)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.contacts_contactImportFailed),
              ),
            );
          }

          if (_pendingOperations.contains(ContactOperationType.zeroHopShare)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.contacts_zeroHopContactAdvertFailed),
              ),
            );
          }
          if (_pendingOperations.contains(ContactOperationType.export)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.contacts_contactAdvertCopyFailed),
              ),
            );
          }

          _pendingOperations.clear();
        }
      } catch (e) {
        appLogger.error(
          'Error processing received frame: $e',
          tag: 'ContactsScreen',
        );
      }
    });
  }

  Future<void> _contactExport(Uint8List pubKey) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final exportContactFrame = buildExportContactFrame(pubKey);
    _pendingOperations.add(ContactOperationType.export);
    await connector.sendFrame(exportContactFrame, expectsGenericAck: true);
  }

  Future<void> _contactZeroHop(Uint8List pubKey) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final exportContactZeroHopFrame = buildZeroHopContact(pubKey);
    _pendingOperations.add(ContactOperationType.zeroHopShare);
    await connector.sendFrame(
      exportContactZeroHopFrame,
      expectsGenericAck: true,
    );
  }

  Future<void> _contactImport() async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contacts_clipboardEmpty)),
        );
      }
      return;
    }
    final text = clipboardData.text!.trim();
    if (!text.startsWith('meshcore://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contacts_invalidAdvertFormat)),
        );
      }
      return;
    }
    final hexString = text.substring('meshcore://'.length);
    try {
      final bytes = hex2Uint8List(hexString);
      final importContactFrame = buildImportContactFrame(bytes);
      _pendingOperations.add(ContactOperationType.import);
      connector.importContact(importContactFrame);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contacts_invalidAdvertFormat)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();

    // Auto-navigate back to scanner if disconnected
    if (!checkConnectionAndNavigate(connector)) {
      return const SizedBox.shrink();
    }

    final allowBack = !connector.isConnected;
    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(context.l10n.contacts_title),
          automaticallyImplyLeading: false,
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.connect_without_contact),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_zeroHopAdvert),
                    ],
                  ),
                  onTap: () => {
                    connector.sendSelfAdvert(flood: false),
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.settings_advertisementSent),
                      ),
                    ),
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.cell_tower),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_floodAdvert),
                    ],
                  ),
                  onTap: () => {
                    connector.sendSelfAdvert(flood: true),
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.settings_advertisementSent),
                      ),
                    ),
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.copy),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_copyAdvertToClipboard),
                    ],
                  ),
                  onTap: () => _contactExport(Uint8List.fromList([])),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.paste),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_addContactFromClipboard),
                    ],
                  ),
                  onTap: () => _contactImport(),
                ),
              ],
              icon: const Icon(Icons.connect_without_contact),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(context.l10n.common_disconnect),
                    ],
                  ),
                  onTap: () => _disconnect(context, connector),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_rounded),
                      const SizedBox(width: 8),
                      Text("Discovered Contacts"),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiscoveryScreen(),
                    ),
                  ),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 8),
                      Text(context.l10n.settings_title),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: _buildContactsBody(context, connector),
        bottomNavigationBar: SafeArea(
          top: false,
          child: QuickSwitchBar(
            selectedIndex: 0,
            onDestinationSelected: (index) =>
                _handleQuickSwitch(index, context),
          ),
        ),
      ),
    );
  }

  Future<void> _disconnect(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    await showDisconnectDialog(context, connector);
  }

  Widget _buildFilterButton(BuildContext context, MeshCoreConnector connector) {
    return ContactsFilterMenu(
      sortOption: _sortOption,
      typeFilter: _typeFilter,
      showUnreadOnly: _showUnreadOnly,
      onSortChanged: (value) {
        setState(() {
          _sortOption = value;
        });
      },
      onTypeFilterChanged: (value) {
        setState(() {
          _typeFilter = value;
        });
      },
      onUnreadOnlyChanged: (value) {
        setState(() {
          _showUnreadOnly = value;
        });
      },
      onNewGroup: () => _showGroupEditor(context, connector.contacts),
    );
  }

  Widget _buildContactsBody(BuildContext context, MeshCoreConnector connector) {
    final contacts = connector.contacts;
    final shouldShowStartupSpinner =
        contacts.isEmpty &&
        _groups.isEmpty &&
        connector.isConnected &&
        (connector.isLoadingContacts ||
            connector.isLoadingChannels ||
            connector.selfPublicKey == null);

    if (shouldShowStartupSpinner) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty && _groups.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: context.l10n.contacts_noContacts,
        subtitle: context.l10n.contacts_contactsWillAppear,
      );
    }

    final filteredAndSorted = _filterAndSortContacts(contacts, connector);
    final filteredGroups = _showUnreadOnly
        ? const <ContactGroup>[]
        : _filterAndSortGroups(_groups, contacts);

    String hintText = "";

    switch (_typeFilter) {
      case ContactTypeFilter.all:
        hintText = context.l10n.contacts_searchContacts(
          filteredAndSorted.length,
          _showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.users:
        hintText = context.l10n.contacts_searchUsers(
          filteredAndSorted.length,
          _showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.repeaters:
        hintText = context.l10n.contacts_searchRepeaters(
          filteredAndSorted.length,
          _showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.rooms:
        hintText = context.l10n.contacts_searchRoomServers(
          filteredAndSorted.length,
          _showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
        );
        break;
      case ContactTypeFilter.favorites:
        hintText = context.l10n.contacts_searchFavorites(
          filteredAndSorted.length,
          _showUnreadOnly ? " ${context.l10n.contacts_unread}" : "",
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
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
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
                  _searchQuery = value.toLowerCase();
                });
              });
            },
          ),
        ),
        Expanded(
          child: filteredAndSorted.isEmpty && filteredGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _showUnreadOnly
                            ? context.l10n.contacts_noUnreadContacts
                            : context.l10n.contacts_noContactsFound,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => connector.getContacts(),
                  child: ListView.builder(
                    itemCount: filteredGroups.length + filteredAndSorted.length,
                    itemBuilder: (context, index) {
                      if (index < filteredGroups.length) {
                        final group = filteredGroups[index];
                        return _buildGroupTile(context, group, contacts);
                      }
                      final contact =
                          filteredAndSorted[index - filteredGroups.length];
                      final unreadCount = connector.getUnreadCountForContact(
                        contact,
                      );
                      return _ContactTile(
                        contact: contact,
                        lastSeen: _resolveLastSeen(contact),
                        unreadCount: unreadCount,
                        isFavorite: contact.isFavorite,
                        onTap: () => _openChat(context, contact),
                        onLongPress: () =>
                            _showContactOptions(context, connector, contact),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<ContactGroup> _filterAndSortGroups(
    List<ContactGroup> groups,
    List<Contact> contacts,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final contactsByKey = <String, Contact>{};
    for (final contact in contacts) {
      contactsByKey[contact.publicKeyHex] = contact;
    }

    final filtered = groups
        .where((group) {
          if (query.isEmpty) return true;
          if (group.name.toLowerCase().contains(query)) return true;
          for (final key in group.memberKeys) {
            final contact = contactsByKey[key];
            if (contact != null && matchesContactQuery(contact, query)) {
              return true;
            }
          }
          return false;
        })
        .where((group) {
          if (_typeFilter == ContactTypeFilter.all) return true;
          // Groups don't have a favorite flag, so hide them under favorites filter
          if (_typeFilter == ContactTypeFilter.favorites) return false;
          for (final key in group.memberKeys) {
            final contact = contactsByKey[key];
            if (contact != null && _matchesTypeFilter(contact)) return true;
          }
          return false;
        })
        .toList();

    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  List<Contact> _filterAndSortContacts(
    List<Contact> contacts,
    MeshCoreConnector connector,
  ) {
    var filtered = contacts.where((contact) {
      if (_searchQuery.isEmpty) return true;
      return matchesContactQuery(contact, _searchQuery);
    }).toList();

    // Filter out own node from the list
    if (connector.selfPublicKey != null) {
      final selfPubKeyHex = pubKeyToHex(connector.selfPublicKey!);
      filtered = filtered.where((contact) {
        return contact.publicKeyHex != selfPubKeyHex;
      }).toList();
    }

    if (_typeFilter != ContactTypeFilter.all) {
      filtered = filtered.where(_matchesTypeFilter).toList();
    }

    if (_showUnreadOnly) {
      filtered = filtered.where((contact) {
        return connector.getUnreadCountForContact(contact) > 0;
      }).toList();
    }

    switch (_sortOption) {
      case ContactSortOption.lastSeen:
        filtered.sort(
          (a, b) => _resolveLastSeen(b).compareTo(_resolveLastSeen(a)),
        );
        break;
      case ContactSortOption.recentMessages:
        filtered.sort((a, b) {
          final aMessages = connector.getMessages(a);
          final bMessages = connector.getMessages(b);
          final aLastMsg = aMessages.isEmpty
              ? DateTime(1970)
              : aMessages.last.timestamp;
          final bLastMsg = bMessages.isEmpty
              ? DateTime(1970)
              : bMessages.last.timestamp;
          return bLastMsg.compareTo(aLastMsg);
        });
        break;
      case ContactSortOption.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return filtered;
  }

  bool _matchesTypeFilter(Contact contact) {
    switch (_typeFilter) {
      case ContactTypeFilter.all:
        return true;
      case ContactTypeFilter.favorites:
        return contact.isFavorite;
      case ContactTypeFilter.users:
        return contact.type == advTypeChat;
      case ContactTypeFilter.repeaters:
        return contact.type == advTypeRepeater;
      case ContactTypeFilter.rooms:
        return contact.type == advTypeRoom;
    }
  }

  DateTime _resolveLastSeen(Contact contact) {
    if (contact.type != advTypeChat) return contact.lastSeen;
    return contact.lastMessageAt.isAfter(contact.lastSeen)
        ? contact.lastMessageAt
        : contact.lastSeen;
  }

  Widget _buildGroupTile(
    BuildContext context,
    ContactGroup group,
    List<Contact> contacts,
  ) {
    final memberContacts = _resolveGroupContacts(group, contacts);
    final subtitle = _formatGroupMembers(context, memberContacts);
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.teal,
        child: Icon(Icons.group, color: Colors.white, size: 20),
      ),
      title: Text(group.name),
      subtitle: Text(subtitle),
      trailing: Text(
        memberContacts.length.toString(),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: () => _showGroupOptions(context, group, contacts),
      onLongPress: () => _showGroupOptions(context, group, contacts),
    );
  }

  List<Contact> _resolveGroupContacts(
    ContactGroup group,
    List<Contact> contacts,
  ) {
    final byKey = <String, Contact>{};
    for (final contact in contacts) {
      byKey[contact.publicKeyHex] = contact;
    }
    final resolved = <Contact>[];
    for (final key in group.memberKeys) {
      final contact = byKey[key];
      if (contact != null) {
        resolved.add(contact);
      }
    }
    resolved.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return resolved;
  }

  String _formatGroupMembers(BuildContext context, List<Contact> members) {
    if (members.isEmpty) return context.l10n.contacts_noMembers;
    final names = members.map((c) => c.name).toList();
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
  }

  void _openChat(BuildContext context, Contact contact) {
    // Check if this is a repeater
    if (contact.type == advTypeRepeater) {
      _showRepeaterLogin(context, contact);
    } else if (contact.type == advTypeRoom) {
      context.read<MeshCoreConnector>().markContactRead(contact.publicKeyHex);
      _showRoomLogin(context, contact, RoomLoginDestination.chat);
    } else {
      context.read<MeshCoreConnector>().markContactRead(contact.publicKeyHex);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(contact: contact)),
      );
    }
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 0) return;
    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ChannelsScreen(hideBackButton: true)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const MapScreen(hideBackButton: true)),
        );
        break;
    }
  }

  void _showRepeaterLogin(BuildContext context, Contact repeater) {
    showDialog(
      context: context,
      builder: (context) => RepeaterLoginDialog(
        repeater: repeater,
        onLogin: (password) {
          // Navigate to repeater hub screen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RepeaterHubScreen(repeater: repeater, password: password),
            ),
          );
        },
      ),
    );
  }

  void _showRoomLogin(
    BuildContext context,
    Contact room,
    RoomLoginDestination destination,
  ) {
    // For chat, skip the login dialog if the room already has an active session.
    // Management always needs the dialog to obtain the password for admin commands.
    if (destination == RoomLoginDestination.chat) {
      final roomSync = context.read<RoomSyncService>();
      if (roomSync.isRoomSessionActive(room.publicKeyHex)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(contact: room)),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (context) => RoomLoginDialog(
        room: room,
        onLogin: (password) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  destination == RoomLoginDestination.management
                  ? RepeaterHubScreen(repeater: room, password: password)
                  : ChatScreen(contact: room),
            ),
          );
        },
      ),
    );
  }

  void _showGroupOptions(
    BuildContext context,
    ContactGroup group,
    List<Contact> contacts,
  ) {
    final members = _resolveGroupContacts(group, contacts);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(context.l10n.contacts_editGroup),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showGroupEditor(context, contacts, group: group);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  context.l10n.contacts_deleteGroup,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteGroup(context, group);
                },
              ),
              if (members.isNotEmpty) const Divider(),
              ...members.map((member) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member.name),
                  subtitle: Text(member.typeLabel),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openChat(context, member);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, ContactGroup group) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.contacts_deleteGroup),
        content: Text(context.l10n.contacts_deleteGroupConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                _groups.removeWhere((g) => g.name == group.name);
              });
              await _saveGroups();
            },
            child: Text(
              context.l10n.common_delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupEditor(
    BuildContext context,
    List<Contact> contacts, {
    ContactGroup? group,
  }) {
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final selectedKeys = <String>{...group?.memberKeys ?? []};
    String filterQuery = '';
    final sortedContacts = List<Contact>.from(contacts)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          final filteredContacts = filterQuery.isEmpty
              ? sortedContacts
              : sortedContacts
                    .where(
                      (contact) => matchesContactQuery(contact, filterQuery),
                    )
                    .toList();
          return AlertDialog(
            title: Text(
              isEditing
                  ? context.l10n.contacts_editGroup
                  : context.l10n.contacts_newGroup,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.contacts_groupName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: context.l10n.contacts_filterContacts,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        filterQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: filteredContacts.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.contacts_noContactsMatchFilter,
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              final isSelected = selectedKeys.contains(
                                contact.publicKeyHex,
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(contact.name),
                                subtitle: Text(contact.typeLabel),
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedKeys.add(contact.publicKeyHex);
                                    } else {
                                      selectedKeys.remove(contact.publicKeyHex);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.common_cancel),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.contacts_groupNameRequired),
                      ),
                    );
                    return;
                  }
                  final exists = _groups.any((g) {
                    if (isEditing && g.name == group.name) return false;
                    return g.name.toLowerCase() == name.toLowerCase();
                  });
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.contacts_groupAlreadyExists(name),
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    if (isEditing) {
                      final index = _groups.indexWhere(
                        (g) => g.name == group.name,
                      );
                      if (index != -1) {
                        _groups[index] = ContactGroup(
                          name: name,
                          memberKeys: selectedKeys.toList(),
                        );
                      }
                    } else {
                      _groups.add(
                        ContactGroup(
                          name: name,
                          memberKeys: selectedKeys.toList(),
                        ),
                      );
                    }
                  });
                  await _saveGroups();
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  isEditing
                      ? context.l10n.common_save
                      : context.l10n.common_create,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContactOptions(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
  ) {
    final isRepeater = contact.type == advTypeRepeater;
    final isRoom = contact.type == advTypeRoom;
    final roomSyncService = context.read<RoomSyncService>();
    final isFavorite = contact.isFavorite;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRepeater) ...[
              ListTile(
                leading: const Icon(Icons.radar, color: Colors.green),
                title: contact.pathLength > 0
                    ? Text(context.l10n.contacts_pathTrace)
                    : Text(context.l10n.contacts_ping),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PathTraceMapScreen(
                        title: contact.pathLength > 0
                            ? context.l10n.contacts_repeaterPathTrace
                            : context.l10n.contacts_repeaterPing,
                        path: contact.traceRouteBytes ?? Uint8List(0),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cell_tower, color: Colors.orange),
                title: Text(context.l10n.contacts_manageRepeater),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRepeaterLogin(context, contact);
                },
              ),
            ] else if (isRoom) ...[
              ListTile(
                leading: const Icon(Icons.radar, color: Colors.green),
                title: contact.pathLength > 0
                    ? Text(context.l10n.contacts_pathTrace)
                    : Text(context.l10n.contacts_ping),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PathTraceMapScreen(
                        title: contact.pathLength > 0
                            ? context.l10n.contacts_roomPathTrace
                            : context.l10n.contacts_roomPing,
                        path: contact.traceRouteBytes ?? Uint8List(0),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.room, color: Colors.blue),
                title: Text(context.l10n.contacts_roomLogin),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomLogin(context, contact, RoomLoginDestination.chat);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.sync),
                title: const Text('Auto-sync this room'),
                subtitle: const Text(
                  'Enable automatic login and background catch-up sync for this room.',
                ),
                value: roomSyncService.isRoomAutoSyncEnabled(
                  contact.publicKeyHex,
                ),
                onChanged: (enabled) async {
                  await roomSyncService.setRoomAutoSyncEnabled(
                    contact.publicKeyHex,
                    enabled,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.room_preferences,
                  color: Colors.orange,
                ),
                title: Text(context.l10n.room_management),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomLogin(
                    context,
                    contact,
                    RoomLoginDestination.management,
                  );
                },
              ),
            ] else ...[
              if (contact.pathLength > 0)
                ListTile(
                  leading: const Icon(Icons.radar, color: Colors.green),
                  title: Text(context.l10n.contacts_chatTraceRoute),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PathTraceMapScreen(
                          title: context.l10n.contacts_pathTraceTo(
                            contact.name,
                          ),
                          path: contact.traceRouteBytes ?? Uint8List(0),
                          targetContact: contact,
                        ),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(context.l10n.contacts_openChat),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openChat(context, contact);
                },
              ),
            ],
            ListTile(
              leading: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: Colors.amber[700],
              ),
              title: Text(
                isFavorite
                    ? context.l10n.listFilter_removeFromFavorites
                    : context.l10n.listFilter_addToFavorites,
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await connector.setContactFavorite(contact, !isFavorite);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.contacts_ShareContact),
              onTap: () {
                Navigator.pop(sheetContext);
                _contactExport(contact.publicKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.connect_without_contact),
              title: Text(context.l10n.contacts_ShareContactZeroHop),
              onTap: () {
                Navigator.pop(sheetContext);
                _contactZeroHop(contact.publicKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                context.l10n.contacts_deleteContact,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, connector, contact);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.contacts_deleteContact),
        content: Text(context.l10n.contacts_removeConfirm(contact.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              connector.removeContact(contact);
            },
            child: Text(
              context.l10n.common_delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final DateTime lastSeen;
  final int unreadCount;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ContactTile({
    required this.contact,
    required this.lastSeen,
    required this.unreadCount,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final roomSync = context.watch<RoomSyncService>();
    final roomStatus = contact.type == advTypeRoom
        ? roomSync.roomStatusLabel(contact.publicKeyHex)
        : null;
    final roomStatusColor = contact.type != advTypeRoom
        ? Colors.grey[600]
        : switch (roomSync.roomStatusKind(contact.publicKeyHex)) {
            RoomSyncStatusKind.connectedSynced => Colors.green[700]!,
            RoomSyncStatusKind.syncing => Colors.blue[700]!,
            RoomSyncStatusKind.connectedWaitingSync ||
            RoomSyncStatusKind.connectedStale => Colors.orange[700]!,
            RoomSyncStatusKind.syncDisabled ||
            RoomSyncStatusKind.notLoggedIn ||
            RoomSyncStatusKind.syncOff => Colors.grey[700]!,
          };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(contact.type),
        child: _buildContactAvatar(contact),
      ),
      title: Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contact.pathLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (roomStatus != null)
            Text(
              roomStatus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: roomStatusColor),
            ),
          Text(
            contact.shortPubKeyHex,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      // Clamp text scaling in trailing section to prevent overflow while
      // maintaining accessibility. Primary content (title/subtitle) scales normally.
      trailing: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.3),
          ),
        ),
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (unreadCount > 0) ...[
                UnreadBadge(count: unreadCount),
                const SizedBox(height: 4),
              ],
              Text(
                _formatLastSeen(context, lastSeen),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFavorite)
                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                  if (isFavorite && contact.hasLocation)
                    const SizedBox(width: 2),
                  if (contact.hasLocation)
                    Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildContactAvatar(Contact contact) {
    final emoji = firstEmoji(contact.name);
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 18));
    }
    return Icon(_getTypeIcon(contact.type), color: Colors.white, size: 20);
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
