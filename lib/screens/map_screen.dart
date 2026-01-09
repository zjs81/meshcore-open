import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/map_marker_service.dart';
import '../services/map_tile_cache_service.dart';
import '../utils/contact_search.dart';
import '../utils/route_transitions.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/quick_switch_bar.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
//import 'repeater_hub_screen.dart';
import '../widgets/repeater_login_dialog.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  final LatLng? highlightPosition;
  final String? highlightLabel;
  final double highlightZoom;
  final bool hideBackButton;

  const MapScreen({
    super.key,
    this.highlightPosition,
    this.highlightLabel,
    this.highlightZoom = 15.0,
    this.hideBackButton = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final MapMarkerService _markerService = MapMarkerService();
  final Set<String> _hiddenMarkerIds = {};
  Set<String> _removedMarkerIds = {};
  bool _isSelectingPoi = false;

  @override
  void initState() {
    super.initState();
    _loadRemovedMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeshCoreConnector>().getChannels();
        if (widget.highlightPosition != null) {
          _mapController.move(widget.highlightPosition!, widget.highlightZoom);
        }
      }
    });
  }

  Future<void> _loadRemovedMarkers() async {
    final ids = await _markerService.loadRemovedIds();
    if (!mounted) return;
    setState(() {
      _removedMarkerIds = ids;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MeshCoreConnector, AppSettingsService>(
      builder: (context, connector, settingsService, child) {
        final tileCache = context.read<MapTileCacheService>();
        final settings = settingsService.settings;
        final contacts = connector.contacts;
        final highlightPosition = widget.highlightPosition;
        final sharedMarkers = settings.mapShowMarkers
            ? _collectSharedMarkers(connector)
                .where((marker) =>
                    !_hiddenMarkerIds.contains(marker.id) &&
                    !_removedMarkerIds.contains(marker.id))
                .toList()
            : <_SharedMarker>[];

        // Filter by time
        final now = DateTime.now();
        final filteredByTime = settings.mapTimeFilterHours == 0
            ? contacts
            : contacts.where((c) {
                final hoursSinceLastSeen =
                    now.difference(c.lastSeen).inHours;
                return hoursSinceLastSeen <= settings.mapTimeFilterHours;
              }).toList();

        // Filter by key prefix
        final keyPrefix = settings.mapKeyPrefix.trim();
        final filteredByKeyPrefix = (settings.mapKeyPrefixEnabled && keyPrefix.isNotEmpty)
            ? filteredByTime.where((c) {
                return c.publicKeyHex.toLowerCase().startsWith(keyPrefix.toLowerCase());
              }).toList()
            : filteredByTime;

        // Filter by location
        final contactsWithLocation = filteredByKeyPrefix
            .where((c) => c.hasLocation)
            .toList();

        // Calculate center of all nodes, or default to (0, 0)
        LatLng center = const LatLng(0, 0);
        final hasMapContent = contactsWithLocation.isNotEmpty ||
            sharedMarkers.isNotEmpty ||
            _isSelectingPoi ||
            highlightPosition != null;
        if (contactsWithLocation.isNotEmpty || sharedMarkers.isNotEmpty) {
          double avgLat = contactsWithLocation
              .map((c) => c.latitude!)
              .fold<double>(0, (sum, lat) => sum + lat);
          double avgLon = contactsWithLocation
              .map((c) => c.longitude!)
              .fold<double>(0, (sum, lon) => sum + lon);
          for (final marker in sharedMarkers) {
            avgLat += marker.position.latitude;
            avgLon += marker.position.longitude;
          }
          final total = contactsWithLocation.length + sharedMarkers.length;
          if (total > 0) {
            center = LatLng(avgLat / total, avgLon / total);
          }
        }
        if (highlightPosition != null) {
          center = highlightPosition;
        }

        final allowBack = !connector.isConnected;

        return PopScope(
          canPop: allowBack,
          child: Scaffold(
            appBar: AppBar(
              leading: BatteryIndicator(connector: connector),
              title: const Text('Node Map'),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bluetooth_disabled),
                  tooltip: 'Disconnect',
                  onPressed: () => _disconnect(context, connector),
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            body: !hasMapContent
                ? _buildEmptyState()
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 13.0,
                          minZoom: 2.0,
                          maxZoom: 18.0,
                          onTap: (_, latLng) {
                            if (_isSelectingPoi) {
                              setState(() {
                                _isSelectingPoi = false;
                              });
                              _shareMarker(
                                context: context,
                                connector: connector,
                                position: latLng,
                                defaultLabel: 'Point of interest',
                                flags: 'poi',
                              );
                            }
                          },
                          onLongPress: (_, latLng) {
                            if (_isSelectingPoi) {
                              setState(() {
                                _isSelectingPoi = false;
                              });
                              _shareMarker(
                                context: context,
                                connector: connector,
                                position: latLng,
                                defaultLabel: 'Point of interest',
                                flags: 'poi',
                              );
                              return;
                            }
                            _showShareMarkerAtPositionSheet(
                              context: context,
                              connector: connector,
                              position: latLng,
                            );
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: kMapTileUrlTemplate,
                            tileProvider: tileCache.tileProvider,
                            userAgentPackageName:
                                MapTileCacheService.userAgentPackageName,
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              if (highlightPosition != null)
                                Marker(
                                  point: highlightPosition,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.red[600],
                                    size: 34,
                                  ),
                                ),
                              ..._buildMarkers(contactsWithLocation, settings),
                              ...sharedMarkers.map(_buildSharedMarker),
                            ],
                          ),
                        ],
                      ),
                      _buildLegend(contactsWithLocation.length, sharedMarkers.length),
                    ],
                  ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: QuickSwitchBar(
                selectedIndex: 2,
                onDestinationSelected: (index) => _handleQuickSwitch(index, context),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showFilterDialog(context, settingsService),
              child: const Icon(Icons.filter_list),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No nodes with location data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nodes need to share their GPS coordinates\nto appear on the map',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(List<Contact> contacts, settings) {
    final markers = <Marker>[];

    for (final contact in contacts) {
      if (!contact.hasLocation) continue;

      // Apply node type filters
      if (contact.type == advTypeRepeater && !settings.mapShowRepeaters) continue;
      if (contact.type == advTypeChat && !settings.mapShowChatNodes) continue;
      if (contact.type != advTypeChat &&
          contact.type != advTypeRepeater &&
          !settings.mapShowOtherNodes) {
        continue;
      }

      final marker = Marker(
        point: LatLng(contact.latitude!, contact.longitude!),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showNodeInfo(context, contact),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNodeColor(contact.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getNodeIcon(contact.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );

      markers.add(marker);
    }

    return markers;
  }

  Color _getNodeColor(int type) {
    switch (type) {
      case advTypeChat:
        return Colors.blue;
      case advTypeRepeater:
        return Colors.green;
      case advTypeRoom:
        return Colors.purple;
      case advTypeSensor:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(int type) {
    switch (type) {
      case advTypeChat:
        return Icons.person;
      case advTypeRepeater:
        return Icons.router;
      case advTypeRoom:
        return Icons.meeting_room;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  Widget _buildLegend(int nodeCount, int markerCount) {
    return Positioned(
      top: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nodes: $nodeCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Pins: $markerCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _buildLegendItem(Icons.person, 'Chat', Colors.blue),
              _buildLegendItem(Icons.router, 'Repeater', Colors.green),
              _buildLegendItem(Icons.meeting_room, 'Room', Colors.purple),
              _buildLegendItem(Icons.sensors, 'Sensor', Colors.orange),
              _buildLegendItem(Icons.flag, 'Pin (DM)', Colors.blue),
              _buildLegendItem(Icons.flag, 'Pin (Private)', Colors.purple),
              _buildLegendItem(Icons.flag, 'Pin (Public)', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<_SharedMarker> _collectSharedMarkers(MeshCoreConnector connector) {
    final markers = <_SharedMarker>[];
    final selfName = connector.selfName ?? 'Me';

    for (final contact in connector.contacts) {
      final messages = connector.getMessages(contact);
      for (final message in messages) {
        final payload = _parseMarkerText(message.text);
        if (payload == null) continue;
        final fromName = message.isOutgoing ? selfName : contact.name;
        final id = _buildMarkerId(
          sourceId: contact.publicKeyHex,
          timestamp: message.timestamp,
          text: message.text,
        );
        markers.add(
          _SharedMarker(
            id: id,
            position: payload.position,
            label: payload.label,
            flags: payload.flags,
            fromName: fromName,
            sourceLabel: contact.name,
            isChannel: false,
            isPublicChannel: false,
          ),
        );
      }
    }

    for (final channel in connector.channels.where((c) => !c.isEmpty)) {
      final isPublic = _isPublicChannel(channel);
      final messages = connector.getChannelMessages(channel);
      for (final message in messages) {
        final payload = _parseMarkerText(message.text);
        if (payload == null) continue;
        final id = _buildMarkerId(
          sourceId: 'channel:${channel.index}',
          timestamp: message.timestamp,
          text: message.text,
        );
        markers.add(
          _SharedMarker(
            id: id,
            position: payload.position,
            label: payload.label,
            flags: payload.flags,
            fromName: message.senderName,
            sourceLabel: channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name,
            isChannel: true,
            isPublicChannel: isPublic,
          ),
        );
      }
    }

    return markers;
  }

  _MarkerPayload? _parseMarkerText(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('m:')) return null;

    final parts = trimmed.substring(2).split('|');
    if (parts.isEmpty) return null;
    final coords = parts[0].split(',');
    if (coords.length != 2) return null;
    final lat = double.tryParse(coords[0].trim());
    final lon = double.tryParse(coords[1].trim());
    if (lat == null || lon == null) return null;

    final label = parts.length > 1 ? parts[1].trim() : '';
    final flags = parts.length > 2 ? parts[2].trim() : '';
    return _MarkerPayload(
      position: LatLng(lat, lon),
      label: label.isEmpty ? 'Shared pin' : label,
      flags: flags,
    );
  }

  String _buildMarkerId({
    required String sourceId,
    required DateTime timestamp,
    required String text,
  }) {
    return '$sourceId|${timestamp.millisecondsSinceEpoch}|$text';
  }

  Marker _buildSharedMarker(_SharedMarker marker) {
    final markerColor = marker.isChannel
        ? (marker.isPublicChannel ? Colors.orange : Colors.purple)
        : Colors.blue;
    return Marker(
      point: marker.position,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => _showMarkerInfo(marker),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flag,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
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
              builder: (context) => RepeaterHubScreen(
                repeater: repeater,
                password: password,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNodeInfo(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNodeIcon(contact.type),
              color: _getNodeColor(contact.type),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(contact.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', contact.typeLabel),
            _buildInfoRow('Path', contact.pathLabel),
            _buildInfoRow('Location',
              '${contact.latitude!.toStringAsFixed(6)}, ${contact.longitude!.toStringAsFixed(6)}'),
            _buildInfoRow('Last Seen', _formatLastSeen(contact.lastSeen)),
            _buildInfoRow('Public Key', contact.publicKeyHex),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (contact.type == advTypeChat) // Only show chat button for chat nodes
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(contact: contact),
                  ),
                );
              },
              child: const Text('Open Chat'),
            ),
            if(contact.type == advTypeRepeater)
            TextButton(
              onPressed: () {
                _showRepeaterLogin(context, contact);
              },
              child: const Text('Manage Repeater'),
            ),
        ],
      ),
    );
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 2) return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(
            const ContactsScreen(hideBackButton: true),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(
            const ChannelsScreen(hideBackButton: true),
          ),
        );
        break;
    }
  }

  Future<void> _disconnect(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Are you sure you want to disconnect from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await connector.disconnect();
    }
  }

  void _showMarkerInfo(_SharedMarker marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(marker.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('From', marker.fromName),
            _buildInfoRow('Source', marker.sourceLabel),
            _buildInfoRow(
              'Location',
              '${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}',
            ),
            if (marker.flags.isNotEmpty) _buildInfoRow('Flags', marker.flags),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hiddenMarkerIds.add(marker.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Hide'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _hiddenMarkerIds.add(marker.id);
                _removedMarkerIds.add(marker.id);
              });
              await _markerService.saveRemovedIds(_removedMarkerIds);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showShareMarkerAtPositionSheet({
    required BuildContext context,
    required MeshCoreConnector connector,
    required LatLng position,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('Share marker here'),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareMarker(
                  context: context,
                  connector: connector,
                  position: position,
                  defaultLabel: 'Point of interest',
                  flags: 'poi',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareMarker({
    required BuildContext context,
    required MeshCoreConnector connector,
    required LatLng position,
    required String defaultLabel,
    required String flags,
  }) async {
    if (!connector.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to a device to share markers')),
      );
      return;
    }

    final label = await _promptForLabel(context, defaultLabel);
    if (label == null || !mounted) return;

    final markerText = _formatMarkerMessage(position, label, flags);
    if (!mounted) return;

    await _showRecipientSheet(
      // ignore: use_build_context_synchronously
      context: context,
      connector: connector,
      markerText: markerText,
    );
  }

  Future<String?> _promptForLabel(BuildContext context, String defaultLabel) async {
    final controller = TextEditingController(text: defaultLabel);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pin label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Label',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final label = controller.text.trim().replaceAll('|', '/');
              Navigator.pop(dialogContext, label.isEmpty ? defaultLabel : label);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String _formatMarkerMessage(LatLng position, String label, String flags) {
    final lat = position.latitude.toStringAsFixed(6);
    final lon = position.longitude.toStringAsFixed(6);
    return 'm:$lat,$lon|$label|$flags';
  }

  Future<void> _showRecipientSheet({
    required BuildContext context,
    required MeshCoreConnector connector,
    required String markerText,
  }) async {
    if (!connector.isLoadingChannels && connector.channels.isEmpty) {
      connector.getChannels();
    }
    String query = '';

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Consumer<MeshCoreConnector>(
            builder: (context, liveConnector, child) {
              final allContacts = liveConnector.contacts
                  .where((contact) =>
                      contact.type != advTypeRepeater && contact.type != advTypeRoom)
                  .toList();
              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text('Send to contact', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search contacts...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              query = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      ...allContacts
                          .where((contact) =>
                              query.isEmpty || matchesContactQuery(contact, query))
                          .map((contact) {
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(contact.name),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            liveConnector.sendMessage(contact, markerText);
                          },
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text('Send to channel', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (liveConnector.isLoadingChannels)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: LinearProgressIndicator(),
                        )
                      else if (liveConnector.channels.where((c) => !c.isEmpty).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('No channels available'),
                        )
                      else
                        ...liveConnector.channels.where((c) => !c.isEmpty).map((channel) {
                          final isPublic = _isPublicChannel(channel);
                          final label = channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name;
                          return ListTile(
                            leading: Icon(
                              isPublic ? Icons.public : Icons.tag,
                              color: isPublic ? Colors.orange : Colors.blue,
                            ),
                            title: Text(label),
                            subtitle: isPublic ? const Text('Public channel') : null,
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              final canSend = isPublic
                                  ? await _confirmPublicShare(context, label)
                                  : true;
                              if (canSend) {
                                liveConnector.sendChannelMessage(channel, markerText);
                              }
                            },
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isPublicChannel(Channel channel) {
    return channel.isPublicChannel;
  }

  Future<bool> _confirmPublicShare(BuildContext context, String channelLabel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Public location share'),
        content: Text(
          'You are about to share a location in $channelLabel. '
          'This channel is public and anyone with the PSK can see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showFilterDialog(BuildContext context, AppSettingsService settingsService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filter Nodes'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: Consumer<AppSettingsService>(
            builder: (context, service, child) {
              final settings = service.settings;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Node Types',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Chat Nodes'),
                    value: settings.mapShowChatNodes,
                    onChanged: (value) {
                      service.setMapShowChatNodes(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Repeaters'),
                    value: settings.mapShowRepeaters,
                    onChanged: (value) {
                      service.setMapShowRepeaters(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Other Nodes'),
                    value: settings.mapShowOtherNodes,
                    onChanged: (value) {
                      service.setMapShowOtherNodes(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Key Prefix',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Filter by key prefix'),
                    value: settings.mapKeyPrefixEnabled,
                    onChanged: (value) {
                      service.setMapKeyPrefixEnabled(value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    initialValue: settings.mapKeyPrefix,
                    enabled: settings.mapKeyPrefixEnabled,
                    decoration: const InputDecoration(
                      labelText: 'Public key prefix',
                      hintText: 'e.g. ab12',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      service.setMapKeyPrefix(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Markers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Show shared markers'),
                    value: settings.mapShowMarkers,
                    onChanged: (value) {
                      service.setMapShowMarkers(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Last Seen Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeFilterLabel(settings.mapTimeFilterHours),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Slider(
                    value: _hoursToSliderValue(settings.mapTimeFilterHours),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      final hours = _sliderValueToHours(value);
                      service.setMapTimeFilterHours(hours);
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Convert hours to slider value (0-100) with exponential scaling
  double _hoursToSliderValue(double hours) {
    if (hours == 0) return 100; // All time

    // Map hours exponentially
    // 0-24h: 0-40
    // 24h-7d: 40-60
    // 7d-30d: 60-80
    // 30d-6mo: 80-99
    // All time: 100

    if (hours <= 24) {
      return (hours / 24) * 40;
    } else if (hours <= 168) { // 7 days
      return 40 + ((hours - 24) / (168 - 24)) * 20;
    } else if (hours <= 720) { // 30 days
      return 60 + ((hours - 168) / (720 - 168)) * 20;
    } else if (hours <= 4380) { // 6 months
      return 80 + ((hours - 720) / (4380 - 720)) * 19;
    } else {
      return 100;
    }
  }

  // Convert slider value (0-100) to hours with exponential scaling
  double _sliderValueToHours(double value) {
    if (value >= 99.5) return 0; // All time

    if (value <= 40) {
      return (value / 40) * 24; // 0-24 hours
    } else if (value <= 60) {
      return 24 + ((value - 40) / 20) * (168 - 24); // 1-7 days
    } else if (value <= 80) {
      return 168 + ((value - 60) / 20) * (720 - 168); // 7-30 days
    } else {
      return 720 + ((value - 80) / 19) * (4380 - 720); // 30 days - 6 months
    }
  }

  String _getTimeFilterLabel(double hours) {
    if (hours == 0) return 'All Time';

    if (hours < 1) {
      return '${(hours * 60).round()} minutes';
    } else if (hours < 24) {
      return '${hours.round()} ${hours.round() == 1 ? 'hour' : 'hours'}';
    } else if (hours < 168) {
      final days = (hours / 24).round();
      return '$days ${days == 1 ? 'day' : 'days'}';
    } else if (hours < 720) {
      final weeks = (hours / 168).round();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else if (hours < 4380) {
      final months = (hours / 730).round();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      return 'All Time';
    }
  }
}

class _MarkerPayload {
  final LatLng position;
  final String label;
  final String flags;

  _MarkerPayload({
    required this.position,
    required this.label,
    required this.flags,
  });
}

class _SharedMarker {
  final String id;
  final LatLng position;
  final String label;
  final String flags;
  final String fromName;
  final String sourceLabel;
  final bool isChannel;
  final bool isPublicChannel;

  _SharedMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.flags,
    required this.fromName,
    required this.sourceLabel,
    required this.isChannel,
    required this.isPublicChannel,
  });
}
