import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../models/channel.dart';
import '../models/community.dart';
import '../storage/community_store.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/route_transitions.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/qr_code_display.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/unread_badge.dart';
import 'channel_chat_screen.dart';
import 'community_qr_scanner_screen.dart';
import 'contacts_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

enum ChannelSortOption { manual, name, latestMessages, unread }

class ChannelsScreen extends StatefulWidget {
  final bool hideBackButton;

  const ChannelsScreen({super.key, this.hideBackButton = false});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen>
    with DisconnectNavigationMixin {
  final TextEditingController _searchController = TextEditingController();
  final CommunityStore _communityStore = CommunityStore();
  String _searchQuery = '';
  Timer? _searchDebounce;
  ChannelSortOption _sortOption = ChannelSortOption.manual;
  List<Community> _communities = [];

  // Cache of PSK hex -> Community for quick lookup
  final Map<String, Community> _pskToCommunity = {};

  ChannelMessageStore get _channelMessageStore => ChannelMessageStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeshCoreConnector>().getChannels();
      _loadCommunities();
    });
  }

  Future<void> _loadCommunities() async {
    final connector = context.read<MeshCoreConnector>();
    _communityStore.setPublicKeyHex = connector.selfPublicKeyHex;
    final communities = await _communityStore.loadCommunities();
    if (mounted) {
      setState(() {
        _communities = communities;
        _buildPskCommunityMap();
      });
    }
  }

  void _buildPskCommunityMap() {
    _pskToCommunity.clear();
    for (final community in _communities) {
      // Map the community public channel PSK
      final publicPsk = community.deriveCommunityPublicPsk();
      _pskToCommunity[Channel.formatPskHex(publicPsk)] = community;

      // Map all known hashtag channel PSKs
      for (final hashtag in community.hashtagChannels) {
        final hashtagPsk = community.deriveCommunityHashtagPsk(hashtag);
        _pskToCommunity[Channel.formatPskHex(hashtagPsk)] = community;
      }
    }
  }

  /// Returns the community this channel belongs to, or null if not a community channel
  Community? _getCommunityForChannel(Channel channel) {
    return _pskToCommunity[channel.pskHex];
  }

  /// Returns true if this is the community's public channel
  bool _isCommunityPublicChannel(Channel channel, Community community) {
    final publicPsk = community.deriveCommunityPublicPsk();
    return channel.pskHex == Channel.formatPskHex(publicPsk);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();

    final channelMessageStore = ChannelMessageStore();
    channelMessageStore.setPublicKeyHex = connector.selfPublicKeyHex;

    // Auto-navigate back to scanner if disconnected
    if (!checkConnectionAndNavigate(connector)) {
      return const SizedBox.shrink();
    }

    final allowBack = !connector.isConnected;

    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(context.l10n.channels_title),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
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
                  onTap: () => _disconnect(context),
                ),
                if (_communities.isNotEmpty)
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.groups),
                        const SizedBox(width: 8),
                        Text(context.l10n.community_manageCommunities),
                      ],
                    ),
                    onTap: () => _showManageCommunitiesDialog(context),
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
        body: RefreshIndicator(
          onRefresh: () async {
            await context.read<MeshCoreConnector>().getChannels(force: true);
          },
          child: () {
            if (connector.isLoadingChannels) {
              return const Center(child: CircularProgressIndicator());
            }

            final channels = connector.channels;

            if (channels.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: EmptyState(
                      icon: Icons.tag,
                      title: context.l10n.channels_noChannelsConfigured,
                      action: FilledButton.icon(
                        onPressed: () => _addPublicChannel(context, connector),
                        icon: const Icon(Icons.public),
                        label: Text(context.l10n.channels_addPublicChannel),
                      ),
                    ),
                  ),
                ],
              );
            }

            final filteredChannels = _filterAndSortChannels(
              channels,
              connector,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.l10n.channels_searchChannels,
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
                          _buildFilterButton(),
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
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          if (!mounted) return;
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: filteredChannels.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height - 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.l10n.channels_noChannelsFound,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : (_sortOption == ChannelSortOption.manual &&
                            _searchQuery.isEmpty)
                      ? ReorderableListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 88,
                          ),
                          buildDefaultDragHandles: false,
                          itemCount: filteredChannels.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final reordered = List<Channel>.from(
                              filteredChannels,
                            );
                            final item = reordered.removeAt(oldIndex);
                            reordered.insert(newIndex, item);
                            unawaited(
                              connector.setChannelOrder(
                                reordered.map((c) => c.index).toList(),
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            return _buildChannelTile(
                              context,
                              connector,
                              channelMessageStore,
                              channel,
                              showDragHandle: true,
                              dragIndex: index,
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 88,
                          ),
                          itemCount: filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            return _buildChannelTile(
                              context,
                              connector,
                              channelMessageStore,
                              channel,
                            );
                          },
                        ),
                ),
              ],
            );
          }(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddChannelDialog(context),
          tooltip: context.l10n.channels_addChannel,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: QuickSwitchBar(
            selectedIndex: 1,
            onDestinationSelected: (index) =>
                _handleQuickSwitch(index, context),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelMessageStore channelMessageStore,
    Channel channel, {
    bool showDragHandle = false,
    int? dragIndex,
  }) {
    final unreadCount = connector.getUnreadCountForChannel(channel);
    final community = _getCommunityForChannel(channel);
    final isCommunityChannel = community != null;
    final isCommunityPublic =
        isCommunityChannel && _isCommunityPublicChannel(channel, community);

    // Determine icon and colors based on channel type
    IconData icon;
    Color iconColor;
    Color bgColor;
    String subtitle;

    if (isCommunityChannel) {
      // Community channel styling
      iconColor = Colors.purple;
      bgColor = Colors.purple.withValues(alpha: 0.2);
      if (isCommunityPublic) {
        icon = Icons.groups;
        subtitle =
            '${context.l10n.community_publicChannel} • ${community.name}';
      } else {
        icon = Icons.tag;
        subtitle =
            '${context.l10n.community_hashtagChannel} • ${community.name}';
      }
    } else if (channel.isPublicChannel) {
      icon = Icons.public;
      iconColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.2);
      subtitle = context.l10n.channels_publicChannel;
    } else if (channel.name.startsWith('#')) {
      icon = Icons.tag;
      iconColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.2);
      subtitle = context.l10n.channels_hashtagChannel;
    } else {
      icon = Icons.lock;
      iconColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.2);
      subtitle = context.l10n.channels_privateChannel;
    }

    return Card(
      key: ValueKey('channel_${channel.index}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: const VisualDensity(vertical: -2),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(icon, color: iconColor),
            ),
            if (isCommunityChannel)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.people, size: 8, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          channel.name.isEmpty
              ? context.l10n.channels_channelIndex(channel.index)
              : channel.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0) ...[
              UnreadBadge(count: unreadCount),
              const SizedBox(width: 4),
            ],
            if (showDragHandle && dragIndex != null)
              ReorderableDelayedDragStartListener(
                index: dragIndex,
                child: Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        onTap: () async {
          connector.markChannelRead(channel.index);
          await Future.delayed(const Duration(milliseconds: 50));
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChannelChatScreen(channel: channel),
              ),
            );
          }
        },
        onLongPress: () => _showChannelActions(
          context,
          connector,
          channelMessageStore,
          channel,
        ),
      ),
    );
  }

  void _showChannelActions(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelMessageStore channelMessageStore,
    Channel channel,
  ) {
    final parentContext = context;
    final settingsService = context.read<AppSettingsService>();
    final isMuted = settingsService.isChannelMuted(channel.name);

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.channels_editChannel),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future.delayed(const Duration(milliseconds: 100));
                if (parentContext.mounted) {
                  _showEditChannelDialog(parentContext, connector, channel);
                }
              },
            ),
            ListTile(
              leading: Icon(
                isMuted
                    ? Icons.notifications_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(
                isMuted
                    ? context.l10n.channels_unmuteChannel
                    : context.l10n.channels_muteChannel,
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (isMuted) {
                  await settingsService.unmuteChannel(channel.name);
                } else {
                  await settingsService.muteChannel(channel.name);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                context.l10n.channels_deleteChannel,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future.delayed(const Duration(milliseconds: 100));
                if (parentContext.mounted) {
                  _confirmDeleteChannel(
                    context,
                    connector,
                    channelMessageStore,
                    channel,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 1) return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ContactsScreen(hideBackButton: true)),
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

  Future<void> _disconnect(BuildContext context) async {
    final connector = context.read<MeshCoreConnector>();
    await showDisconnectDialog(context, connector);
  }

  Widget _buildFilterButton() {
    const actionSortManual = 0;
    const actionSortName = 1;
    const actionSortLatest = 2;
    const actionSortUnread = 3;

    return SortFilterMenu(
      tooltip: context.l10n.listFilter_tooltip,
      sections: [
        SortFilterMenuSection(
          title: context.l10n.channels_sortBy,
          options: [
            SortFilterMenuOption(
              value: actionSortManual,
              label: context.l10n.channels_sortManual,
              checked: _sortOption == ChannelSortOption.manual,
            ),
            SortFilterMenuOption(
              value: actionSortName,
              label: context.l10n.channels_sortAZ,
              checked: _sortOption == ChannelSortOption.name,
            ),
            SortFilterMenuOption(
              value: actionSortLatest,
              label: context.l10n.channels_sortLatestMessages,
              checked: _sortOption == ChannelSortOption.latestMessages,
            ),
            SortFilterMenuOption(
              value: actionSortUnread,
              label: context.l10n.channels_sortUnread,
              checked: _sortOption == ChannelSortOption.unread,
            ),
          ],
        ),
      ],
      onSelected: (action) {
        setState(() {
          switch (action) {
            case actionSortManual:
              _sortOption = ChannelSortOption.manual;
              break;
            case actionSortLatest:
              _sortOption = ChannelSortOption.latestMessages;
              break;
            case actionSortUnread:
              _sortOption = ChannelSortOption.unread;
              break;
            case actionSortName:
            default:
              _sortOption = ChannelSortOption.name;
              break;
          }
        });
      },
    );
  }

  List<Channel> _filterAndSortChannels(
    List<Channel> channels,
    MeshCoreConnector connector,
  ) {
    var filtered = channels.where((channel) {
      if (_searchQuery.isEmpty) return true;
      final label = _normalizeChannelName(channel);
      return label.toLowerCase().contains(_searchQuery);
    }).toList();

    int compareByName(Channel a, Channel b) {
      final nameA = _normalizeChannelName(a);
      final nameB = _normalizeChannelName(b);
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    }

    switch (_sortOption) {
      case ChannelSortOption.manual:
        break;
      case ChannelSortOption.latestMessages:
        filtered.sort((a, b) {
          final aMessages = connector.getChannelMessages(a);
          final bMessages = connector.getChannelMessages(b);
          final aLast = aMessages.isEmpty
              ? DateTime(1970)
              : aMessages.last.timestamp;
          final bLast = bMessages.isEmpty
              ? DateTime(1970)
              : bMessages.last.timestamp;
          final timeCompare = bLast.compareTo(aLast);
          if (timeCompare != 0) return timeCompare;
          return compareByName(a, b);
        });
        break;
      case ChannelSortOption.unread:
        filtered.sort((a, b) {
          final aUnread = connector.getUnreadCountForChannel(a);
          final bUnread = connector.getUnreadCountForChannel(b);
          final unreadCompare = bUnread.compareTo(aUnread);
          if (unreadCompare != 0) return unreadCompare;
          return compareByName(a, b);
        });
        break;
      case ChannelSortOption.name:
        filtered.sort(compareByName);
        break;
    }

    return filtered;
  }

  String _normalizeChannelName(Channel channel) {
    if (channel.name.isEmpty) {
      return 'Channel ${channel.index}'; // Fallback for sorting
    }
    final trimmed = channel.name.trim();
    if (trimmed.startsWith('#') && trimmed.length > 1) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  void _showAddChannelDialog(BuildContext context) {
    final connector = context.read<MeshCoreConnector>();
    final nextIndex = _findNextAvailableIndex(
      connector.channels,
      connector.maxChannels,
    );
    final hasPublicChannel = connector.channels.any((c) => c.isPublicChannel);
    int? selectedOption;
    final nameController = TextEditingController();
    final pskController = TextEditingController();
    final hashtagController = TextEditingController();
    bool addPublicChannel = true;
    bool isRegularHashtag = true;
    Community? selectedCommunity;

    _communityStore.setPublicKeyHex = connector.selfPublicKeyHex;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Widget buildOptionTile({
            required int optionIndex,
            required IconData icon,
            required String title,
            required String subtitle,
            bool enabled = true,
          }) {
            final isSelected = selectedOption == optionIndex;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: enabled
                    ? (isSelected
                          ? Theme.of(dialogContext).colorScheme.primaryContainer
                          : null)
                    : Colors.grey.withValues(alpha: 0.2),
                child: Icon(
                  icon,
                  color: enabled
                      ? (isSelected
                            ? Theme.of(dialogContext).colorScheme.primary
                            : null)
                      : Colors.grey,
                ),
              ),
              title: Text(
                title,
                style: TextStyle(color: enabled ? null : Colors.grey),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(color: enabled ? null : Colors.grey),
              ),
              trailing: enabled ? const Icon(Icons.chevron_right) : null,
              selected: isSelected,
              onTap: enabled
                  ? () {
                      setDialogState(() {
                        selectedOption = optionIndex;
                        nameController.clear();
                        pskController.clear();
                        hashtagController.clear();
                      });
                    }
                  : null,
            );
          }

          Widget? buildExpandedContent(
            ChannelMessageStore channelMessageStore,
          ) {
            switch (selectedOption) {
              case 0: // Create Private Channel
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_channelName,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        dialogContext
                                            .l10n
                                            .channels_enterChannelName,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final random = Random.secure();
                                final psk = Uint8List(16);
                                for (int i = 0; i < 16; i++) {
                                  psk[i] = random.nextInt(256);
                                }
                                Navigator.pop(dialogContext);
                                await connector.setChannel(
                                  nextIndex,
                                  name,
                                  psk,
                                );
                                await channelMessageStore.clearChannelMessages(
                                  nextIndex,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.channels_channelAdded(
                                          name,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_create),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case 1: // Join Private Channel
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_channelName,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: pskController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_pskHex,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                final pskHex = pskController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        dialogContext
                                            .l10n
                                            .channels_enterChannelName,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Uint8List psk;
                                try {
                                  psk = Channel.parsePskHex(pskHex);
                                } on FormatException {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        dialogContext
                                            .l10n
                                            .channels_pskMustBe32Hex,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(dialogContext);
                                connector.setChannel(nextIndex, name, psk);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.channels_channelAdded(
                                          name,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_add),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case 2: // Join Public Channel
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final psk = Channel.parsePskHex(
                              Channel.publicChannelPsk,
                            );
                            Navigator.pop(dialogContext);
                            connector.setChannel(nextIndex, 'Public', psk);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.channels_publicChannelAdded,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(dialogContext.l10n.common_add),
                        ),
                      ),
                    ],
                  ),
                );

              case 3: // Join Hashtag Channel
                return Column(
                  children: [
                    // Only show type selection if user has communities
                    if (_communities.isNotEmpty) ...[
                      RadioGroup<bool>(
                        groupValue: isRegularHashtag,
                        onChanged: (v) => setDialogState(() {
                          if (v == null) return;
                          isRegularHashtag = v;
                          if (isRegularHashtag) {
                            selectedCommunity = null;
                          } else if (selectedCommunity == null &&
                              _communities.isNotEmpty) {
                            selectedCommunity = _communities.first;
                          }
                        }),
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              value: true,
                              title: Text(
                                dialogContext.l10n.community_regularHashtag,
                              ),
                              subtitle: Text(
                                dialogContext.l10n.community_regularHashtagDesc,
                              ),
                              dense: true,
                            ),
                            RadioListTile<bool>(
                              value: false,
                              title: Text(
                                dialogContext.l10n.community_communityHashtag,
                              ),
                              subtitle: Text(
                                dialogContext
                                    .l10n
                                    .community_communityHashtagDesc,
                              ),
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Community dropdown (only if community hashtag selected)
                    if (!isRegularHashtag && _communities.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: DropdownButtonFormField<Community>(
                          initialValue: selectedCommunity,
                          items: _communities
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (c) =>
                              setDialogState(() => selectedCommunity = c),
                          decoration: InputDecoration(
                            labelText:
                                dialogContext.l10n.community_selectCommunity,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.groups),
                          ),
                        ),
                      ),
                    // Hashtag name input
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: hashtagController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_enterHashtag,
                          hintText: dialogContext.l10n.channels_hashtagHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    // Privacy hint for community hashtags
                    if (!isRegularHashtag)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          dialogContext.l10n.community_hashtagPrivacyHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                var hashtag = hashtagController.text.trim();
                                if (hashtag.isEmpty) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        dialogContext
                                            .l10n
                                            .channels_enterChannelName,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Normalize hashtag name (remove leading # if present)
                                if (hashtag.startsWith('#')) {
                                  hashtag = hashtag.substring(1);
                                }
                                final String channelName;

                                final Uint8List psk;
                                if (isRegularHashtag) {
                                  channelName = '#$hashtag';
                                  // Regular hashtag - public derivation using SHA256
                                  psk = Channel.derivePskFromHashtag(hashtag);
                                } else {
                                  // Community hashtag - HMAC derivation from community secret
                                  if (selectedCommunity == null) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          dialogContext
                                              .l10n
                                              .community_selectCommunity,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  channelName =
                                      '${selectedCommunity!.name} #$hashtag';
                                  psk = selectedCommunity!
                                      .deriveCommunityHashtagPsk(hashtag);
                                  // Track in community's hashtag list
                                  await _communityStore.addHashtagChannel(
                                    selectedCommunity!.id,
                                    hashtag,
                                  );
                                  _loadCommunities();
                                }

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                connector.setChannel(
                                  nextIndex,
                                  channelName,
                                  psk,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.channels_channelAdded(
                                          channelName,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_add),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case 4: // Scan Community QR
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            if (context.mounted) {
                              final result = await Navigator.push<Community>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CommunityQrScannerScreen(),
                                ),
                              );
                              // Result handled by scanner screen
                              if (result != null && context.mounted) {
                                // Community was joined, refresh might be needed
                              }
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(dialogContext.l10n.community_scanQr),
                        ),
                      ),
                    ],
                  ),
                );

              case 5: // Create Community
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.community_name,
                          hintText: dialogContext.l10n.community_enterName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.groups),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    CheckboxListTile(
                      value: addPublicChannel,
                      onChanged: (value) {
                        setDialogState(() {
                          addPublicChannel = value ?? true;
                        });
                      },
                      title: Text(
                        dialogContext.l10n.community_addPublicChannel,
                      ),
                      subtitle: Text(
                        dialogContext.l10n.community_addPublicChannelHint,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        dialogContext.l10n.community_enterName,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Create community with random secret
                                final community = Community.create(
                                  id: const Uuid().v4(),
                                  name: name,
                                );

                                // Save to store
                                await _communityStore.addCommunity(community);

                                // Optionally add the community public channel to the device
                                if (addPublicChannel) {
                                  final psk = community
                                      .deriveCommunityPublicPsk();
                                  final channelName =
                                      '${community.name} Public';
                                  connector.setChannel(
                                    nextIndex,
                                    channelName,
                                    psk,
                                  );
                                }

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                // Refresh communities list
                                _loadCommunities();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.community_created(name),
                                      ),
                                    ),
                                  );

                                  // Show QR code dialog
                                  await QrCodeShareDialog.show(
                                    context: context,
                                    data: community.toQrJson(),
                                    title: context.l10n.community_qrTitle,
                                    instructions: context.l10n
                                        .community_qrInstructions(name),
                                    embeddedImage: Image.asset(
                                      'assets/images/mesh-icon.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_create),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              default:
                return null;
            }
          }

          return AlertDialog(
            title: Text(dialogContext.l10n.channels_addChannel),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildOptionTile(
                      optionIndex: 0,
                      icon: Icons.add,
                      title: dialogContext.l10n.channels_createPrivateChannel,
                      subtitle:
                          dialogContext.l10n.channels_createPrivateChannelDesc,
                    ),
                    if (selectedOption == 0)
                      buildExpandedContent(_channelMessageStore)!,
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 1,
                      icon: Icons.lock,
                      title: dialogContext.l10n.channels_joinPrivateChannel,
                      subtitle:
                          dialogContext.l10n.channels_joinPrivateChannelDesc,
                    ),
                    if (selectedOption == 1)
                      buildExpandedContent(_channelMessageStore)!,
                    if (!hasPublicChannel) ...[
                      const Divider(height: 1),
                      buildOptionTile(
                        optionIndex: 2,
                        icon: Icons.public,
                        title: dialogContext.l10n.channels_joinPublicChannel,
                        subtitle:
                            dialogContext.l10n.channels_joinPublicChannelDesc,
                      ),
                      if (selectedOption == 2)
                        buildExpandedContent(_channelMessageStore)!,
                    ],
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 3,
                      icon: Icons.tag,
                      title: dialogContext.l10n.channels_joinHashtagChannel,
                      subtitle:
                          dialogContext.l10n.channels_joinHashtagChannelDesc,
                    ),
                    if (selectedOption == 3)
                      buildExpandedContent(_channelMessageStore)!,
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 4,
                      icon: Icons.qr_code_scanner,
                      title: dialogContext.l10n.community_scanQr,
                      subtitle: dialogContext.l10n.community_join,
                    ),
                    if (selectedOption == 4)
                      buildExpandedContent(_channelMessageStore)!,
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 5,
                      icon: Icons.groups,
                      title: dialogContext.l10n.community_create,
                      subtitle: dialogContext.l10n.community_createDesc,
                    ),
                    if (selectedOption == 5)
                      buildExpandedContent(_channelMessageStore)!,
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(dialogContext.l10n.common_close),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditChannelDialog(
    BuildContext context,
    MeshCoreConnector connector,
    Channel channel,
  ) {
    final nameController = TextEditingController(text: channel.name);
    final pskController = TextEditingController(text: channel.pskHex);
    bool smazEnabled = connector.isChannelSmazEnabled(channel.index);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(
            dialogContext.l10n.channels_editChannelTitle(channel.index),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.channels_channelName,
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 31,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pskController,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.channels_pskHex,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.casino),
                      tooltip: dialogContext.l10n.channels_generateRandomPsk,
                      onPressed: () {
                        final random = Random.secure();
                        final bytes = Uint8List(16);
                        for (int i = 0; i < 16; i++) {
                          bytes[i] = random.nextInt(256);
                        }
                        pskController.text = Channel.formatPskHex(bytes);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dialogContext.l10n.channels_smazCompression),
                  value: smazEnabled,
                  onChanged: (value) => setState(() => smazEnabled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final pskHex = pskController.text.trim();

                Uint8List psk;
                try {
                  psk = Channel.parsePskHex(pskHex);
                } on FormatException {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(dialogContext.l10n.channels_pskMustBe32Hex),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await connector.setChannel(channel.index, name, psk);
                  await connector.setChannelSmazEnabled(
                    channel.index,
                    smazEnabled,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.channels_channelUpdated(name)),
                    ),
                  );
                } catch (e, st) {
                  debugPrint(st.toString());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update channel: $e')),
                  );
                }
              },
              child: Text(dialogContext.l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChannel(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelMessageStore channelMessageStore,
    Channel channel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.channels_deleteChannel),
        content: Text(
          dialogContext.l10n.channels_deleteChannelConfirm(channel.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await connector.deleteChannel(channel.index);

                await channelMessageStore.clearChannelMessages(channel.index);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.channels_channelDeleted(channel.name),
                    ),
                  ),
                );
              } catch (e, st) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.channels_channelDeleteFailed(channel.name),
                    ),
                  ),
                );

                // Preserve existing logging (if it was there)
                debugPrint('Failed to delete channel: $e\n$st');
              }
            },
            child: Text(
              dialogContext.l10n.common_delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _addPublicChannel(BuildContext context, MeshCoreConnector connector) {
    final psk = Channel.parsePskHex(Channel.publicChannelPsk);
    connector.setChannel(0, 'Public', psk);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.channels_publicChannelAdded)),
    );
  }

  int _findNextAvailableIndex(List<Channel> channels, int maxChannels) {
    final usedIndices = channels.map((c) => c.index).toSet();
    for (int i = 0; i < maxChannels; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return 0;
  }

  void _showManageCommunitiesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.groups, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.community_manageCommunities,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _communities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.community_noCommunities,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.community_scanOrCreate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _communities.length,
                      itemBuilder: (context, index) {
                        final community = _communities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: Colors.purple,
                            ),
                          ),
                          title: Text(community.name),
                          subtitle: Text(
                            'ID: ${community.shortCommunityId}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              Navigator.pop(sheetContext);
                              if (value == 'share') {
                                _showCommunityQrDialog(context, community);
                              } else if (value == 'leave') {
                                _confirmLeaveCommunity(context, community);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    const Icon(Icons.qr_code),
                                    const SizedBox(width: 12),
                                    Text(context.l10n.community_showQr),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'leave',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.exit_to_app,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      context.l10n.community_delete,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showCommunityQrDialog(context, community);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunityQrDialog(BuildContext context, Community community) {
    QrCodeShareDialog.show(
      context: context,
      data: community.toQrJson(),
      title: context.l10n.community_qrTitle,
      instructions: context.l10n.community_qrInstructions(community.name),
      embeddedImage: Image.asset(
        'assets/images/mesh-icon.png',
        width: 40,
        height: 40,
      ),
    );
  }

  void _confirmLeaveCommunity(BuildContext context, Community community) {
    final connector = context.read<MeshCoreConnector>();

    // Find all channels that belong to this community
    List<Channel> communityChannels = [];
    final publicPskHex = Channel.formatPskHex(
      community.deriveCommunityPublicPsk(),
    );

    for (final channel in connector.channels) {
      // Check if it's the public channel
      if (channel.pskHex == publicPskHex) {
        communityChannels.add(channel);
        continue;
      }
      // Check if it's a hashtag channel
      for (final hashtag in community.hashtagChannels) {
        final hashtagPskHex = Channel.formatPskHex(
          community.deriveCommunityHashtagPsk(hashtag),
        );
        if (channel.pskHex == hashtagPskHex) {
          communityChannels.add(channel);
          break;
        }
      }
    }

    final channelCount = communityChannels.length;
    _communityStore.setPublicKeyHex = connector.selfPublicKeyHex;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.community_delete),
        content: Text(
          channelCount > 0
              ? '${dialogContext.l10n.community_deleteConfirm(community.name)}\n\n${dialogContext.l10n.community_deleteChannelsWarning(channelCount)}'
              : dialogContext.l10n.community_deleteConfirm(community.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Delete all community channels from the device
              for (final channel in communityChannels) {
                await connector.deleteChannel(channel.index);
              }

              // Remove community from store
              await _communityStore.removeCommunity(community.id);
              _loadCommunities();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.community_deleted(community.name),
                    ),
                  ),
                );
              }
            },
            child: Text(
              dialogContext.l10n.community_delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
