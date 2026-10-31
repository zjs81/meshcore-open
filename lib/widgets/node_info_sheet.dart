import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../l10n/contact_localization.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../screens/chat_screen.dart';
import '../screens/repeater_hub_screen.dart';
import '../theme/mesh_theme.dart';
import 'mesh_ui.dart';
import 'repeater_login_dialog.dart';
import 'room_login_dialog.dart';
import '../theme/theme_icons.dart';

/// Map accent colour for a node type.
Color mapNodeTypeColor(int type) {
  switch (type) {
    case advTypeChat:
      return MapPalette.selected;
    case advTypeRepeater:
      return MapPalette.repeater;
    case advTypeRoom:
      return MapPalette.router;
    case advTypeSensor:
      return MapPalette.sensor;
    default:
      return MapPalette.offline;
  }
}

/// Map icon for a node type.
IconData mapNodeTypeIcon(int type) {
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

String formatNodeLastSeen(AppLocalizations l10n, DateTime lastSeen) {
  final difference = DateTime.now().difference(lastSeen);
  if (difference.inSeconds < 60) {
    return l10n.time_justNow;
  } else if (difference.inMinutes < 60) {
    return l10n.time_minutesAgo(difference.inMinutes);
  } else if (difference.inHours < 24) {
    return l10n.time_hoursAgo(difference.inHours);
  } else {
    return l10n.time_daysAgo(difference.inDays);
  }
}

/// Label above a selectable mono value, as used in node detail sheets.
class NodeInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const NodeInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: MeshTheme.mono(fontSize: 13, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Repeater login, then the repeater hub on success.
void showRepeaterLoginDialog(BuildContext context, Contact repeater) {
  showDialog(
    context: context,
    builder: (context) => RepeaterLoginDialog(
      repeater: repeater,
      onLogin: (password, isAdmin) {
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

/// Room login, then the room chat (or the hub when [manage] is set).
void showRoomLoginDialog(
  BuildContext context,
  Contact room, {
  bool manage = false,
}) {
  showDialog(
    context: context,
    builder: (context) => RoomLoginDialog(
      room: room,
      onLogin: (password, isAdmin) {
        final connector = context.read<MeshCoreConnector>();
        final unread = connector.getUnreadCountForContactKey(room.publicKeyHex);
        connector.markContactRead(room.publicKeyHex);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => manage
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

/// Node details sheet (path, location, last seen, key) with the actions for
/// its type: open chat, manage repeater, or join/manage room.
void showNodeInfoSheet(
  BuildContext context,
  Contact contact, {
  LatLng? guessedPosition,
}) {
  final connector = context.read<MeshCoreConnector>();
  showMeshSheet(
    context,
    builder: (sheetContext) {
      final l10n = context.l10n;
      void importIfNeeded() {
        if (!contact.isActive) {
          connector.importDiscoveredContact(contact);
        }
      }

      final actions = <Widget>[];
      if (contact.type == advTypeChat) {
        actions.add(
          FilledButton(
            onPressed: () {
              importIfNeeded();
              final unread = connector.getUnreadCountForContactKey(
                contact.publicKeyHex,
              );
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(contact: contact, initialUnreadCount: unread),
                ),
              );
            },
            child: Text(l10n.contacts_openChat),
          ),
        );
      }
      if (contact.type == advTypeRepeater) {
        actions.add(
          FilledButton(
            onPressed: () {
              importIfNeeded();
              Navigator.pop(sheetContext);
              showRepeaterLoginDialog(context, contact);
            },
            child: Text(l10n.map_manageRepeater),
          ),
        );
      }
      if (contact.type == advTypeRoom) {
        actions.add(
          FilledButton(
            onPressed: () {
              importIfNeeded();
              Navigator.pop(sheetContext);
              showRoomLoginDialog(context, contact);
            },
            child: Text(l10n.map_joinRoom),
          ),
        );
        actions.add(
          FilledButton(
            onPressed: () {
              importIfNeeded();
              Navigator.pop(sheetContext);
              showRoomLoginDialog(context, contact, manage: true);
            },
            child: Text(l10n.map_manageServer),
          ),
        );
      }
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BottomSheetHeader(
                title: contact.name,
                subtitle: contact.typeLabel(l10n),
                trailing: mapMarkerSlotForNodeType(contact.type) == null
                    ? Icon(
                        mapNodeTypeIcon(contact.type),
                        color: mapNodeTypeColor(contact.type),
                        size: 20,
                      )
                    : ThemedIcon(
                        mapMarkerSlotForNodeType(contact.type)!,
                        color: mapNodeTypeColor(contact.type),
                        size: 20,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NodeInfoRow(
                      label: l10n.map_path,
                      value: contact.pathLabel(
                        l10n,
                        pathHashByteWidth: connector.pathHashByteWidth,
                      ),
                    ),
                    if (contact.hasLocation)
                      NodeInfoRow(
                        label: l10n.map_location,
                        value:
                            '${contact.latitude!.toStringAsFixed(6)}, ${contact.longitude!.toStringAsFixed(6)}',
                      )
                    else if (guessedPosition != null)
                      NodeInfoRow(
                        label: l10n.map_estLocation,
                        value:
                            '~${guessedPosition.latitude.toStringAsFixed(6)}, ${guessedPosition.longitude.toStringAsFixed(6)}',
                      ),
                    NodeInfoRow(
                      label: l10n.map_lastSeen,
                      value: formatNodeLastSeen(l10n, contact.lastHeard),
                    ),
                    NodeInfoRow(
                      label: l10n.map_publicKey,
                      value: contact.publicKeyHex,
                    ),
                    const SizedBox(height: 16),
                    ...actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
