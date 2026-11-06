import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/services/notification_service.dart';
import 'package:meshcore_open/utils/app_logger.dart';
import 'package:meshcore_open/utils/platform_info.dart';
import 'package:meshcore_open/widgets/app_bar.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../l10n/contact_localization.dart';
import '../models/contact_group.dart';
import '../services/ui_view_state_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/contact_search.dart';
import '../storage/contact_group_store.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/emoji_utils.dart';
import '../utils/route_transitions.dart';
import '../widgets/contact_visuals.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/repeater_login_dialog.dart';
import '../widgets/room_login_dialog.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/unread_badge.dart';
import '../helpers/snack_bar_builder.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'contact_qr_scanner_screen.dart';
import 'discovery_screen.dart';
import 'map_screen.dart';
import '../review_mode/review_mode_banner.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';
import '../theme/theme_icons.dart';

enum RoomLoginDestination { chat, management }

enum ContactOperationType { import, export, zeroHopShare }

/// An export/import/share awaiting its generic OK/ERR ack. The timer drops
/// it if no ack arrives, so a stuck op can't consume a later unrelated ack.
class _PendingContactOperation {
  final ContactOperationType type;
  final Timer timeout;

  _PendingContactOperation(this.type, this.timeout);
}

const Duration _contactOperationTimeout = Duration(seconds: 5);

class ContactsScreen extends StatefulWidget {
  final bool hideBackButton;

  const ContactsScreen({super.key, this.hideBackButton = false});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with DisconnectNavigationMixin {
  final TextEditingController _searchController = TextEditingController();
  final ContactGroupStore _groupStore = ContactGroupStore();
  MeshCoreConnector? _scopeSyncConnector;
  List<ContactGroup> _groups = [];
  String _loadedGroupScopeKeyHex = '';
  Timer? _searchDebounce;

  final List<_PendingContactOperation> _pendingOperations = [];
  final DerivedListCache<Contact> _filteredCache = DerivedListCache<Contact>();

  StreamSubscription<Uint8List>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.text = context
        .read<UiViewStateService>()
        .contactsSearchText;
    _loadGroups();
    _setupFrameListener();
    _clearAdvertNotifications();
  }

  void _clearAdvertNotifications() {
    final connector = context.read<MeshCoreConnector>();
    final contactIds = connector.contacts.map((c) => c.publicKeyHex).toList();
    NotificationService().clearAdvertNotifications(contactIds);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final connector = context.read<MeshCoreConnector>();
    if (!identical(_scopeSyncConnector, connector)) {
      _scopeSyncConnector?.removeListener(_handleConnectorScopeChange);
      _scopeSyncConnector = connector;
      _scopeSyncConnector?.addListener(_handleConnectorScopeChange);
    }
    _handleConnectorScopeChange();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _frameSubscription?.cancel();
    for (final op in _pendingOperations) {
      op.timeout.cancel();
    }
    _pendingOperations.clear();
    _scopeSyncConnector?.removeListener(_handleConnectorScopeChange);
    super.dispose();
  }

  void _addPendingOperation(ContactOperationType type) {
    late final _PendingContactOperation op;
    op = _PendingContactOperation(
      type,
      Timer(_contactOperationTimeout, () {
        if (!_pendingOperations.remove(op)) return;
        _showOperationResult(type, success: false);
      }),
    );
    _pendingOperations.add(op);
  }

  /// Removes the oldest pending operation of [type] (or of any type when
  /// null) and returns its type, or null when nothing is pending.
  ContactOperationType? _takePendingOperation([ContactOperationType? type]) {
    final index = type == null
        ? (_pendingOperations.isEmpty ? -1 : 0)
        : _pendingOperations.indexWhere((op) => op.type == type);
    if (index < 0) return null;
    final op = _pendingOperations.removeAt(index);
    op.timeout.cancel();
    return op.type;
  }

  void _showOperationResult(
    ContactOperationType type, {
    required bool success,
  }) {
    if (!mounted) return;
    final l10n = context.l10n;
    final String message;
    switch (type) {
      case ContactOperationType.import:
        message = success
            ? l10n.contacts_contactImported
            : l10n.contacts_contactImportFailed;
      case ContactOperationType.zeroHopShare:
        message = success
            ? l10n.contacts_zeroHopContactAdvertSent
            : l10n.contacts_zeroHopContactAdvertFailed;
      case ContactOperationType.export:
        message = success
            ? l10n.contacts_contactAdvertCopied
            : l10n.contacts_contactAdvertCopyFailed;
    }
    showDismissibleSnackBar(context, content: Text(message));
  }

  Future<void> _sendSelfAdvert(
    MeshCoreConnector connector, {
    required bool flood,
  }) async {
    var sent = false;
    try {
      if (connector.isConnected) {
        await connector.sendSelfAdvert(flood: flood);
        sent = true;
      }
    } catch (e) {
      appLogger.error('Self advert failed: $e', tag: 'ContactsScreen');
    }
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(
        sent
            ? context.l10n.settings_advertisementSent
            : context.l10n.contacts_advertFailed,
      ),
    );
  }

  void _handleConnectorScopeChange() {
    final connector = _scopeSyncConnector;
    if (connector == null) return;
    _syncGroupScopeIfNeeded(connector);
  }

  Future<void> _loadGroups() async {
    final selfPublicKeyHex = context.read<MeshCoreConnector>().selfPublicKeyHex;
    if (selfPublicKeyHex.isEmpty) {
      return;
    }
    _groupStore.setPublicKeyHex = selfPublicKeyHex;
    final groups = await _groupStore.loadGroups();
    if (!mounted) return;
    setState(() {
      _loadedGroupScopeKeyHex = selfPublicKeyHex;
      _groups = groups;
      _ensureValidSelectedGroup();
    });
  }

  Future<void> _saveGroups() async {
    final selfPublicKeyHex = context.read<MeshCoreConnector>().selfPublicKeyHex;
    if (selfPublicKeyHex.isEmpty) {
      return;
    }
    _groupStore.setPublicKeyHex = selfPublicKeyHex;
    await _groupStore.saveGroups(_groups);
  }

  bool _hasGroupStoreScope(MeshCoreConnector connector) {
    return connector.selfPublicKeyHex.isNotEmpty;
  }

  void _syncGroupScopeIfNeeded(MeshCoreConnector connector) {
    final selfPublicKeyHex = connector.selfPublicKeyHex;
    if (selfPublicKeyHex.isEmpty ||
        selfPublicKeyHex == _loadedGroupScopeKeyHex) {
      return;
    }
    _loadGroups();
  }

  void _collapseContactsSearch(UiViewStateService viewState) {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    _searchController.clear();
    viewState.setContactsSearchText('');
    viewState.setContactsSearchExpanded(false);
  }

  void _showGroupsUnavailableMessage(BuildContext context) {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.common_loading),
    );
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
              showDismissibleSnackBar(
                context,
                content: Text(context.l10n.contacts_invalidAdvertFormat),
              );
            }
            _takePendingOperation(ContactOperationType.export);
            return;
          }
          final hexString = pubKeyToHex(advertPacket);
          Clipboard.setData(ClipboardData(text: "meshcore://$hexString"));
          _takePendingOperation(ContactOperationType.export);
          if (mounted) {
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.contacts_contactAdvertCopied),
            );
          }
          return;
        }

        // Generic OK/ERR acks carry no command correlation, so consume only
        // the oldest pending operation per ack instead of clearing all.
        if (code == respCodeOk || code == respCodeErr) {
          if (!mounted) return;
          final op = _takePendingOperation();
          if (op == null) return;
          _showOperationResult(op, success: code == respCodeOk);
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
    _addPendingOperation(ContactOperationType.export);
    try {
      await connector.sendFrame(exportContactFrame, expectsGenericAck: true);
    } catch (e) {
      _takePendingOperation(ContactOperationType.export);
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactAdvertCopyFailed),
        );
      }
    }
  }

  Future<void> _contactZeroHop(Uint8List pubKey) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final exportContactZeroHopFrame = buildZeroHopContact(pubKey);
    _addPendingOperation(ContactOperationType.zeroHopShare);
    try {
      await connector.sendFrame(
        exportContactZeroHopFrame,
        expectsGenericAck: true,
      );
    } catch (e) {
      _takePendingOperation(ContactOperationType.zeroHopShare);
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_zeroHopContactAdvertFailed),
        );
      }
    }
  }

  Future<void> _contactImport() async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text == null) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_clipboardEmpty),
        );
      }
      return;
    }
    final text = clipboardData.text!.trim();
    if (!text.startsWith('meshcore://')) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
      }
      return;
    }
    final hexString = text.substring('meshcore://'.length);
    final Uint8List importContactFrame;
    try {
      final bytes = hex2Uint8List(hexString);
      importContactFrame = buildImportContactFrame(bytes);
    } catch (e) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
      }
      return;
    }
    _addPendingOperation(ContactOperationType.import);
    try {
      await connector.sendFrame(importContactFrame, expectsGenericAck: true);
    } catch (e) {
      _takePendingOperation(ContactOperationType.import);
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactImportFailed),
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
          automaticallyImplyLeading: !widget.hideBackButton,
          bottom: const SyncProgressAppBarBottom(),
          actions: [
            PopupMenuButton(
              tooltip: context.l10n.contacts_moreOptions,
              itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_rounded),
                      const SizedBox(width: 8),
                      Text(context.l10n.discoveredContacts_Title),
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
                      const Icon(Icons.paste),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_addContactFromClipboard),
                    ],
                  ),
                  onTap: () => _contactImport(),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_scanQrCode),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactQrScannerScreen(),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.connect_without_contact),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_zeroHopAdvert),
                    ],
                  ),
                  onTap: () => _sendSelfAdvert(connector, flood: false),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.cell_tower),
                      const SizedBox(width: 8),
                      Text(context.l10n.contacts_floodAdvert),
                    ],
                  ),
                  onTap: () => _sendSelfAdvert(connector, flood: true),
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
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(context.l10n.common_disconnect),
                    ],
                  ),
                  onTap: () => _disconnect(context, connector),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const ThemedIcon(ThemeIconSlot.settings),
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
        body: Column(
          children: [
            const ReviewModeBanner(),
            Expanded(child: _buildContactsBody(context, connector)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddContactSheet(context),
          child: const Icon(Icons.person_add),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: QuickSwitchBar(
            selectedIndex: 0,
            onDestinationSelected: (index) =>
                _handleQuickSwitch(index, context),
            contactsUnreadCount: connector.getTotalContactsUnreadCount(),
            channelsUnreadCount: connector.getTotalChannelsUnreadCount(),
          ),
        ),
      ),
    );
  }

  void _showAddContactSheet(BuildContext context) {
    showMeshSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(title: context.l10n.contacts_title),
              ListTile(
                leading: const Icon(Icons.paste),
                title: Text(context.l10n.contacts_addContactFromClipboard),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _contactImport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(context.l10n.contacts_scanQrCode),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactQrScannerScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_rounded),
                title: Text(context.l10n.discoveredContacts_Title),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiscoveryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
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

  ContactGroup? _selectedGroupForName(String selectedGroupName) {
    if (selectedGroupName == contactsAllGroupsValue) return null;
    for (final group in _groups) {
      if (group.name == selectedGroupName) return group;
    }
    return null;
  }

  void _ensureValidSelectedGroup() {
    final viewState = context.read<UiViewStateService>();
    if (viewState.contactsSelectedGroupName == contactsAllGroupsValue) return;
    final exists = _groups.any(
      (group) => group.name == viewState.contactsSelectedGroupName,
    );
    if (!exists) {
      viewState.setContactsSelectedGroupName(contactsAllGroupsValue);
    }
  }

  /// Dropdown value that opens the group-management sheet instead of
  /// selecting a group. Contains a NUL so it can't collide with a name.
  static const String _manageGroupsValue = '\u0000manage_groups';

  void _showManageGroupsSheet(BuildContext context, List<Contact> contacts) {
    if (!_hasGroupStoreScope(context.read<MeshCoreConnector>())) {
      _showGroupsUnavailableMessage(context);
      return;
    }
    showMeshSheet<void>(
      context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final scheme = Theme.of(sheetContext).colorScheme;
        final groups = [
          ..._groups,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        void closeThen(VoidCallback action) {
          Navigator.pop(sheetContext);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            action();
          });
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BottomSheetHeader(title: l10n.contacts_manageGroups),
              ListTile(
                minTileHeight: 56,
                leading: Icon(Icons.group_add, color: scheme.primary),
                title: Text(
                  l10n.contacts_newGroup,
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () =>
                    closeThen(() => _showGroupEditor(this.context, contacts)),
              ),
              if (groups.isNotEmpty) const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      minTileHeight: 56,
                      leading: const Icon(Icons.group_outlined),
                      title: Text(
                        group.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () => closeThen(
                        () => _showGroupEditor(
                          this.context,
                          contacts,
                          group: group,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.contacts_editGroup,
                            icon: const Icon(Icons.edit),
                            onPressed: () => closeThen(
                              () => _showGroupEditor(
                                this.context,
                                contacts,
                                group: group,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.contacts_deleteGroup,
                            icon: Icon(Icons.delete, color: scheme.error),
                            onPressed: () => closeThen(
                              () => _confirmDeleteGroup(this.context, group),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    UiViewStateService viewState,
  ) {
    return ContactsFilterMenu(
      sortOption: viewState.contactsSortOption,
      typeFilter: viewState.contactsTypeFilter,
      showUnreadOnly: viewState.contactsShowUnreadOnly,
      onSortChanged: (value) {
        viewState.setContactsSortOption(value);
      },
      onTypeFilterChanged: (value) {
        viewState.setContactsTypeFilter(value);
      },
      onUnreadOnlyChanged: (value) {
        viewState.setContactsShowUnreadOnly(value);
      },
    );
  }

  Widget _buildGroupButton(
    BuildContext context,
    MeshCoreConnector connector,
    UiViewStateService viewState,
    List<Contact> contacts,
    List<ContactGroup> sortedGroups,
  ) {
    final selectedGroupName =
        _selectedGroupForName(viewState.contactsSelectedGroupName)?.name ??
        context.l10n.listFilter_all;
    final double menuWidth = (MediaQuery.sizeOf(context).width - 16).clamp(
      0.0,
      double.infinity,
    );

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      constraints: BoxConstraints.tightFor(width: menuWidth),
      onSelected: (String value) {
        if (value == _manageGroupsValue) {
          _showManageGroupsSheet(this.context, contacts);
          return;
        }
        viewState.setContactsSelectedGroupName(value);
      },
      itemBuilder: (menuContext) => [
        PopupMenuItem<String>(
          value: contactsAllGroupsValue,
          child: Text(menuContext.l10n.listFilter_all),
        ),
        ...sortedGroups.map((group) {
          return PopupMenuItem<String>(
            value: group.name,
            child: Text(group.name, overflow: TextOverflow.ellipsis),
          );
        }),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _manageGroupsValue,
          child: Row(
            children: [
              const Icon(Icons.group_add),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  menuContext.l10n.contacts_manageGroups,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox(
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedGroupName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsBody(BuildContext context, MeshCoreConnector connector) {
    final viewState = context.watch<UiViewStateService>();
    final contacts = connector.contacts;
    final waitingForInitialContacts =
        connector.isConnected &&
        !connector.hasLoadedContacts &&
        !connector.isLoadingContacts;
    final waitingForFirstContact =
        connector.isLoadingContacts && contacts.isEmpty;

    if (waitingForInitialContacts || waitingForFirstContact) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty && _groups.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: context.l10n.contacts_noContacts,
        subtitle: context.l10n.contacts_noContactsDiscoveredHint,
        action: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DiscoveryScreen()),
          ),
          icon: const Icon(Icons.person_add_rounded),
          label: Text(context.l10n.discoveredContacts_Title),
        ),
      );
    }

    final filteredAndSorted = _filterAndSortContacts(
      contacts,
      connector,
      viewState,
    );

    String hintText = "";

    switch (viewState.contactsTypeFilter) {
      case ContactTypeFilter.all:
        hintText = context.l10n.contacts_searchContacts(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.users:
        hintText = context.l10n.contacts_searchUsers(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.repeaters:
        hintText = context.l10n.contacts_searchRepeaters(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.rooms:
        hintText = context.l10n.contacts_searchRoomServers(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.favorites:
        hintText = context.l10n.contacts_searchFavorites(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
    }

    final groupsByName = <String, ContactGroup>{};
    for (final group in _groups) {
      groupsByName.putIfAbsent(group.name, () => group);
    }
    final sortedGroups = groupsByName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final screenWidth = MediaQuery.sizeOf(context).width;
    final searchExpandedWidth = (screenWidth * 0.52).clamp(
      97.0,
      double.infinity,
    ); // allow expansion up to 52% of screen width, but not less than the collapsed width
    final searchCollapsedWidth = (screenWidth * 0.22).clamp(
      97.0,
      120.0,
    ); //two 48px icon buttons + 1px divider

    // Scrolls with the list rather than staying pinned above it, so large
    // text or an open keyboard on a short screen can't squeeze the list out.
    final discoveredTile = ListTile(
      dense: true,
      leading: const Icon(Icons.person_add_rounded),
      title: Text(
        context.l10n.contacts_discoveredNearby(
          connector.discoveredContacts.where((c) => !c.isActive).length,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DiscoveryScreen()),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildGroupButton(
                  context,
                  connector,
                  viewState,
                  contacts,
                  sortedGroups,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: viewState.contactsSearchExpanded
                    ? searchExpandedWidth
                    : searchCollapsedWidth,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: viewState.contactsSearchExpanded
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: hintText,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: (value) {
                                  _searchDebounce?.cancel();
                                  _searchDebounce = Timer(
                                    const Duration(milliseconds: 300),
                                    () {
                                      if (!mounted) return;
                                      context
                                          .read<UiViewStateService>()
                                          .setContactsSearchText(value);
                                    },
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          tooltip: viewState.contactsSearchExpanded
                              ? context.l10n.contacts_searchClose
                              : context.l10n.contacts_searchOpen,
                          onPressed: () {
                            if (viewState.contactsSearchExpanded) {
                              _collapseContactsSearch(viewState);
                              return;
                            }
                            viewState.setContactsSearchExpanded(true);
                          },
                          icon: Icon(
                            viewState.contactsSearchExpanded
                                ? Icons.close
                                : Icons.search,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: _buildFilterButton(context, viewState),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (connector.contactsStorageFull)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.contacts_storageFull,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => connector.getContacts(),
            child: filteredAndSorted.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        discoveredTile,
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(
                              0,
                              constraints.maxHeight - kMinInteractiveDimension,
                            ),
                          ),
                          child: EmptyState(
                            icon: Icons.search_off,
                            title: viewState.contactsShowUnreadOnly
                                ? context.l10n.contacts_noUnreadContacts
                                : context.l10n.contacts_noContactsFound,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: filteredAndSorted.length + 1,
                    itemBuilder: (context, row) {
                      if (row == 0) return discoveredTile;
                      final index = row - 1;
                      final contact = filteredAndSorted[index];
                      final unreadCount = connector.getUnreadCountForContact(
                        contact,
                      );
                      return _ContactTileEntrance(
                        index: index,
                        contact: contact,
                        pathHashByteWidth: connector.pathHashByteWidth,
                        lastSeen: resolveContactLastSeen(contact),
                        unreadCount: unreadCount,
                        isFavorite: contact.isFavorite,
                        onTap: () => _openChat(context, contact),
                        onLongPress: () =>
                            _showContactOptions(context, connector, contact),
                        onManage: _manageAction(context, contact),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  List<Contact> _filterAndSortContacts(
    List<Contact> contacts,
    MeshCoreConnector connector,
    UiViewStateService viewState,
  ) {
    final selectedGroup = _selectedGroupForName(
      viewState.contactsSelectedGroupName,
    );
    final selfKey = connector.selfPublicKey;
    // Unread counts and last-message times change without the contact list
    // changing, so they join the cache key only when they affect the result.
    final unreadSignature = viewState.contactsShowUnreadOnly
        ? [for (final c in contacts) connector.getUnreadCountForContact(c)]
        : const <int>[];
    final recentSignature =
        viewState.contactsSortOption == ContactSortOption.recentMessages
        ? [for (final c in contacts) _lastMessageTime(connector, c)]
        : const <DateTime>[];
    return _filteredCache.get(contacts, [
      viewState.contactsSearchText,
      viewState.contactsSelectedGroupName,
      selectedGroup?.memberKeys ?? const <String>[],
      selfKey == null ? null : pubKeyToHex(selfKey),
      viewState.contactsTypeFilter,
      viewState.contactsShowUnreadOnly,
      viewState.contactsSortOption,
      unreadSignature,
      recentSignature,
    ], () => _computeFilteredContacts(contacts, connector, viewState));
  }

  DateTime _lastMessageTime(MeshCoreConnector connector, Contact contact) {
    final messages = connector.getMessages(contact);
    return messages.isEmpty ? DateTime(1970) : messages.last.timestamp;
  }

  List<Contact> _computeFilteredContacts(
    List<Contact> contacts,
    MeshCoreConnector connector,
    UiViewStateService viewState,
  ) {
    var filtered = contacts.where((contact) {
      if (viewState.contactsSearchText.isEmpty) return true;
      return matchesContactQuery(contact, viewState.contactsSearchText);
    }).toList();

    final selectedGroup = _selectedGroupForName(
      viewState.contactsSelectedGroupName,
    );
    if (selectedGroup != null) {
      final memberKeys = selectedGroup.memberKeys.toSet();
      filtered = filtered
          .where((contact) => memberKeys.contains(contact.publicKeyHex))
          .toList();
    }

    // Filter out own node from the list
    if (connector.selfPublicKey != null) {
      final selfPubKeyHex = pubKeyToHex(connector.selfPublicKey!);
      filtered = filtered.where((contact) {
        return contact.publicKeyHex != selfPubKeyHex;
      }).toList();
    }

    if (viewState.contactsTypeFilter != ContactTypeFilter.all) {
      filtered = filtered
          .where(
            (contact) =>
                _matchesTypeFilter(contact, viewState.contactsTypeFilter),
          )
          .toList();
    }

    if (viewState.contactsShowUnreadOnly) {
      filtered = filtered.where((contact) {
        return connector.getUnreadCountForContact(contact) > 0;
      }).toList();
    }

    switch (viewState.contactsSortOption) {
      case ContactSortOption.lastSeen:
        filtered.sort(
          (a, b) =>
              resolveContactLastSeen(b).compareTo(resolveContactLastSeen(a)),
        );
        break;
      case ContactSortOption.recentMessages:
        final lastMessageAt = {
          for (final c in filtered) c: _lastMessageTime(connector, c),
        };
        filtered.sort((a, b) => lastMessageAt[b]!.compareTo(lastMessageAt[a]!));
        break;
      case ContactSortOption.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return filtered;
  }

  bool _matchesTypeFilter(Contact contact, ContactTypeFilter typeFilter) {
    switch (typeFilter) {
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

  void _openChat(BuildContext context, Contact contact) {
    // Check if this is a repeater
    if (contact.type == advTypeRepeater) {
      _showRepeaterLogin(context, contact);
    } else if (contact.type == advTypeRoom) {
      _showRoomLogin(context, contact, RoomLoginDestination.chat);
    } else {
      final connector = context.read<MeshCoreConnector>();
      final unread = connector.getUnreadCountForContactKey(
        contact.publicKeyHex,
      );
      connector.markContactRead(contact.publicKeyHex);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(contact: contact, initialUnreadCount: unread),
        ),
      );
    }
  }

  VoidCallback? _manageAction(BuildContext context, Contact contact) {
    if (contact.type == advTypeRepeater) {
      return () => _showRepeaterLogin(context, contact);
    }
    if (contact.type == advTypeRoom) {
      return () =>
          _showRoomLogin(context, contact, RoomLoginDestination.management);
    }
    return null;
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
        onLogin: (password, isAdmin) {
          // Navigate to repeater hub screen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepeaterHubScreen(
                repeater: repeater,
                password: password,
                isAdmin: isAdmin,
              ),
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
    showDialog(
      context: context,
      builder: (context) => RoomLoginDialog(
        room: room,
        onLogin: (password, isAdmin) {
          final connector = context.read<MeshCoreConnector>();
          final unread = connector.getUnreadCountForContactKey(
            room.publicKeyHex,
          );
          connector.markContactRead(room.publicKeyHex);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  destination == RoomLoginDestination.management
                  ? RepeaterHubScreen(
                      repeater: room,
                      password: password,
                      isAdmin: isAdmin,
                    )
                  : ChatScreen(contact: room, initialUnreadCount: unread),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, ContactGroup group) {
    if (!_hasGroupStoreScope(context.read<MeshCoreConnector>())) {
      _showGroupsUnavailableMessage(context);
      return;
    }
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
                _ensureValidSelectedGroup();
              });
              await _saveGroups();
            },
            child: Text(
              context.l10n.common_delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    if (!_hasGroupStoreScope(context.read<MeshCoreConnector>())) {
      _showGroupsUnavailableMessage(context);
      return;
    }
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final selectedKeys = <String>{...group?.memberKeys ?? []};
    String filterQuery = '';
    final sortedContacts = List<Contact>.from(contacts)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog<void>(
      context: context,
      builder: (dialogContext) => _DisposeControllerOnUnmount(
        controller: nameController,
        child: StatefulBuilder(
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
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
                      Expanded(
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
                                    subtitle: Text(
                                      contact.typeLabel(context.l10n),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selectedKeys.add(
                                            contact.publicKeyHex,
                                          );
                                        } else {
                                          selectedKeys.remove(
                                            contact.publicKeyHex,
                                          );
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
                      showDismissibleSnackBar(
                        context,
                        content: Text(context.l10n.contacts_groupNameRequired),
                      );
                      return;
                    }
                    if (name.toLowerCase() ==
                        contactsAllGroupsValue.toLowerCase()) {
                      showDismissibleSnackBar(
                        context,
                        content: Text(context.l10n.contacts_groupNameReserved),
                      );
                      return;
                    }
                    final exists = _groups.any((g) {
                      if (isEditing && g.name == group.name) return false;
                      return g.name.toLowerCase() == name.toLowerCase();
                    });
                    if (exists) {
                      showDismissibleSnackBar(
                        context,
                        content: Text(
                          context.l10n.contacts_groupAlreadyExists(name),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      final viewState = context.read<UiViewStateService>();
                      if (isEditing) {
                        final index = _groups.indexWhere(
                          (g) => g.name == group.name,
                        );
                        if (index != -1) {
                          final wasSelected =
                              viewState.contactsSelectedGroupName == group.name;
                          _groups[index] = ContactGroup(
                            name: name,
                            memberKeys: selectedKeys.toList(),
                          );
                          if (wasSelected) {
                            viewState.setContactsSelectedGroupName(name);
                          }
                        }
                      } else {
                        _groups.add(
                          ContactGroup(
                            name: name,
                            memberKeys: selectedKeys.toList(),
                          ),
                        );
                        viewState.setContactsSelectedGroupName(name);
                      }
                      _ensureValidSelectedGroup();
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
    final isFavorite = contact.isFavorite;

    showMeshSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                title: contact.name,
                subtitle: contact.typeLabel(context.l10n),
              ),
              if (isRepeater) ...[
                ListTile(
                  leading: Icon(Icons.radar, color: MeshPalette.signal),
                  title: Text(context.l10n.contacts_ping),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final hw = context
                        .read<MeshCoreConnector>()
                        .pathHashByteWidth;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PathTraceMapScreen(
                          title: context.l10n.contacts_repeaterPing,
                          path: contact.pathBytesForDisplay.isNotEmpty
                              ? contact.pathBytesForDisplay
                              : _contactPathPrefix(contact, hw),
                          flipPathAround: true,
                          targetContact: contact,
                          pathHashByteWidth: hw,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cell_tower, color: MeshPalette.warn),
                  title: Text(context.l10n.contacts_manageRepeater),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showRepeaterLogin(context, contact);
                  },
                ),
              ] else if (isRoom) ...[
                ListTile(
                  leading: Icon(Icons.radar, color: MeshPalette.signal),
                  title: Text(context.l10n.contacts_pathTrace),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final hw = context
                        .read<MeshCoreConnector>()
                        .pathHashByteWidth;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PathTraceMapScreen(
                          title: contact.pathBytesForDisplay.isNotEmpty
                              ? context.l10n.contacts_roomPathTrace
                              : context.l10n.contacts_roomPing,
                          path: contact.pathBytesForDisplay.isNotEmpty
                              ? contact.pathBytesForDisplay
                              : _contactPathPrefix(contact, hw),
                          flipPathAround: true,
                          targetContact: contact,
                          pathHashByteWidth: hw,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.meeting_room, color: MeshPalette.blue),
                  title: Text(context.l10n.contacts_roomLogin),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showRoomLogin(context, contact, RoomLoginDestination.chat);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.room_preferences,
                    color: MeshPalette.warn,
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
                    leading: Icon(Icons.radar, color: MeshPalette.signal),
                    title: Text(context.l10n.contacts_chatTraceRoute),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      final hw = context
                          .read<MeshCoreConnector>()
                          .pathHashByteWidth;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PathTraceMapScreen(
                            title: context.l10n.contacts_pathTraceTo(
                              contact.name,
                            ),
                            path: contact.pathBytesForDisplay,
                            flipPathAround: true,
                            targetContact: contact,
                            pathHashByteWidth: hw,
                          ),
                        ),
                      );
                    },
                  ),
              ],
              ListTile(
                leading: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: MeshPalette.warn,
                ),
                title: Text(
                  isFavorite
                      ? context.l10n.listFilter_removeFromFavorites
                      : context.l10n.listFilter_addToFavorites,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await connector.setContactFlags(
                    contact,
                    isFavorite: !isFavorite,
                  );
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
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  context.l10n.contacts_removeFromContacts,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context, connector, contact);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List _contactPathPrefix(Contact contact, int hashByteWidth) {
    if (contact.publicKey.isEmpty) return Uint8List(0);
    final width = hashByteWidth
        .clamp(1, pubKeySize)
        .toInt()
        .clamp(1, contact.publicKey.length)
        .toInt();
    return Uint8List.fromList(contact.publicKey.sublist(0, width));
  }

  void _confirmDelete(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
  ) {
    var keepHistory = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(context.l10n.contacts_removeFromContacts),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.contacts_removeFromContactsConfirm(contact.name),
              ),
              if (connector.autoAddsContactType(contact.type)) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.contacts_removeAutoAddNote,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: keepHistory,
                title: Text(context.l10n.contacts_keepChatHistory),
                onChanged: (value) =>
                    setDialogState(() => keepHistory = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.common_cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await connector.removeContact(
                    contact,
                    keepMessages: keepHistory,
                  );
                } catch (e) {
                  appLogger.warn(
                    'Remove contact failed: $e',
                    tag: 'ContactsScreen',
                  );
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(context.l10n.contacts_removeFailed),
                  );
                }
              },
              child: Text(
                context.l10n.contacts_remove,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final int pathHashByteWidth;
  final DateTime lastSeen;
  final int unreadCount;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onManage;

  const _ContactTile({
    required this.contact,
    required this.pathHashByteWidth,
    required this.lastSeen,
    required this.unreadCount,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = firstEmoji(contact.name);
    final isChat = contact.type == advTypeChat;

    return GestureDetector(
      onSecondaryTapUp: PlatformInfo.isDesktop ? (_) => onLongPress() : null,
      child: MeshCard(
        onTap: onTap,
        onLongPress: onLongPress,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar
            if (emoji != null)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHigh,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              )
            else
              AvatarCircle(
                name: contact.name,
                size: 42,
                color: isChat ? null : contactTypeColor(contact.type),
                iconSlot: contactTypeIconSlot(contact.type),
              ),
            const SizedBox(width: 12),
            // Main content. The name owns the whole first row (wrapping to
            // a second line if needed); last-seen and the route share the row
            // below so long names stay readable on narrow screens and large
            // text scales.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: contact.name,
                      children: [
                        if (isFavorite)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                              ),
                              child: Icon(
                                Icons.star,
                                size: 16,
                                color: MeshPalette.warn,
                              ),
                            ),
                          ),
                        if (contact.hasLocation)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                              ),
                              child: Icon(
                                Icons.location_on,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Key prefix + path + last seen
                  Row(
                    children: [
                      _KeyPrefixBadge(
                        prefix: contact.publicKeyPrefixHex(pathHashByteWidth),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          contact.pathLabel(
                            context.l10n,
                            pathHashByteWidth: pathHashByteWidth,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Fills its share and right-aligns, so the time sits at
                      // the row's end on wide screens too.
                      Expanded(
                        flex: 2,
                        child: Text(
                          formatContactLastSeen(context.l10n, lastSeen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: MeshTheme.mono(
                            fontSize: 12.5,
                            color: unreadCount > 0
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              UnreadBadge(count: unreadCount),
            ],
            if (onManage != null)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: contact.type == advTypeRoom
                    ? context.l10n.room_management
                    : context.l10n.contacts_manageRepeater,
                visualDensity: VisualDensity.compact,
                onPressed: onManage,
              ),
          ],
        ),
      ),
    );
  }
}

/// Mono pill showing the contact's routing hash (public-key prefix), so it can
/// be matched against hops in paths.
class _KeyPrefixBadge extends StatelessWidget {
  final String prefix;

  const _KeyPrefixBadge({required this.prefix});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.contacts_keyPrefixSemantics(
        prefix.split('').join(' '),
      ),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(MeshRadii.xs),
          border: Border.all(color: scheme.outline),
        ),
        child: Text(
          prefix,
          maxLines: 1,
          style: MeshTheme.mono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// Disposes [controller] when the dialog content unmounts, i.e. after the
/// route's exit animation, so the TextField never sees a disposed controller.
class _DisposeControllerOnUnmount extends StatefulWidget {
  final TextEditingController controller;
  final Widget child;

  const _DisposeControllerOnUnmount({
    required this.controller,
    required this.child,
  });

  @override
  State<_DisposeControllerOnUnmount> createState() =>
      _DisposeControllerOnUnmountState();
}

class _DisposeControllerOnUnmountState
    extends State<_DisposeControllerOnUnmount> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Wrap each contact tile with staggered entrance.
class _ContactTileEntrance extends StatelessWidget {
  final int index;
  final Contact contact;
  final int pathHashByteWidth;
  final DateTime lastSeen;
  final int unreadCount;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onManage;

  const _ContactTileEntrance({
    required this.index,
    required this.contact,
    required this.pathHashByteWidth,
    required this.lastSeen,
    required this.unreadCount,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return ListEntrance(
      index: index,
      child: _ContactTile(
        contact: contact,
        pathHashByteWidth: pathHashByteWidth,
        lastSeen: lastSeen,
        unreadCount: unreadCount,
        isFavorite: isFavorite,
        onTap: onTap,
        onLongPress: onLongPress,
        onManage: onManage,
      ),
    );
  }
}
