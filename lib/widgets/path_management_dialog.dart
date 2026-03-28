import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/widgets/elements_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../helpers/path_helper.dart';
import '../services/path_history_service.dart';
import 'path_selection_dialog.dart';

class PathManagementDialog {
  static Future<void> show(BuildContext context, {required Contact contact}) {
    return showDialog<void>(
      context: context,
      builder: (context) => _PathManagementDialog(contact: contact),
    );
  }
}

class _PathManagementDialog extends StatefulWidget {
  final Contact contact;

  const _PathManagementDialog({required this.contact});

  @override
  State<_PathManagementDialog> createState() => _PathManagementDialogState();
}

class _PathManagementDialogState extends State<_PathManagementDialog> {
  bool _showAllPaths = false;

  int _resolveContactIndex = -1;

  Contact _resolveContact(MeshCoreConnector connector) {
    if (_resolveContactIndex >= 0 &&
        _resolveContactIndex < connector.contacts.length &&
        connector.contacts[_resolveContactIndex].publicKeyHex ==
            widget.contact.publicKeyHex) {
      return connector.contacts[_resolveContactIndex];
    }
    _resolveContactIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
    );
    if (_resolveContactIndex == -1) {
      return widget.contact;
    }
    return connector.contacts[_resolveContactIndex];
  }

  String _formatRelativeTime(BuildContext context, DateTime? time) {
    if (time == null) return '—';
    final l10n = context.l10n;
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return l10n.time_justNow;
    if (diff.inMinutes < 60) return l10n.time_minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.time_hoursAgo(diff.inHours);
    return l10n.time_daysAgo(diff.inDays);
  }

  void _showFullPathDialog(BuildContext context, List<int> pathBytes) {
    final l10n = context.l10n;
    if (pathBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chat_pathDetailsNotAvailable),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final connector = context.read<MeshCoreConnector>();
    final allContacts = connector.allContacts;

    final formattedPath = PathHelper.formatPathHex(pathBytes);
    final resolvedNames = PathHelper.resolvePathNames(pathBytes, allContacts);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chat_fullPath),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(formattedPath),
            const SizedBox(height: 8),
            SelectableText(
              resolvedNames,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PathTraceMapScreen(
                  title: context.l10n.contacts_repeaterPathTrace,
                  path: Uint8List.fromList(pathBytes),
                  flipPathAround: true,
                  targetContact: widget.contact,
                  pathHashByteWidth: connector.pathHashByteWidth,
                ),
              ),
            ),
            child: Text(context.l10n.contacts_pathTrace),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _setCustomPath(
    BuildContext context,
    MeshCoreConnector connector,
    Contact currentContact,
  ) async {
    final l10n = context.l10n;
    if (currentContact.pathLength > 0 &&
        currentContact.path.isEmpty &&
        connector.isConnected) {
      connector.getContacts();
    }

    final pathForInput = currentContact.pathFormattedIdList(
      connector.pathHashByteWidth,
    );
    final availableContacts = connector.allContacts
        .where((c) => c.publicKeyHex != currentContact.publicKeyHex)
        .toList();

    final result = await PathSelectionDialog.show(
      context,
      availableContacts: availableContacts,
      initialPath: pathForInput.isEmpty ? null : pathForInput,
      currentPathLabel: currentContact.pathLabel,
      onRefresh: connector.isConnected ? connector.getContacts : null,
    );

    if (result != null && context.mounted) {
      await connector.setPathOverride(
        currentContact,
        pathLen: result.length,
        pathBytes: result,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chat_hopsCount(result.length)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer2<MeshCoreConnector, PathHistoryService>(
      builder: (context, connector, pathService, _) {
        final currentContact = _resolveContact(connector);
        final paths = pathService.getRecentPaths(currentContact.publicKeyHex);

        final repeatersList = List.of(connector.directRepeaters)
          ..sort((a, b) => b.ranking.compareTo(a.ranking));

        if (repeatersList.isEmpty) {
          _showAllPaths = true;
        }

        final directRepeater = repeatersList.isEmpty
            ? null
            : repeatersList.first;
        final secondDirectRepeater = repeatersList.length < 2
            ? null
            : repeatersList.elementAt(1);
        final thirdDirectRepeater = repeatersList.length < 3
            ? null
            : repeatersList.elementAt(2);

        List<MapEntry<int, MapEntry<Color, PathRecord>>> pathsWithRepeaters =
            paths.map((path) {
              final isDirectRepeater =
                  directRepeater != null &&
                  path.pathBytes.isNotEmpty &&
                  directRepeater.pubkeyFirstByte == path.pathBytes.first;
              final isSecondDirectRepeater =
                  secondDirectRepeater != null &&
                  path.pathBytes.isNotEmpty &&
                  secondDirectRepeater.pubkeyFirstByte == path.pathBytes.first;
              final isThirdDirectRepeater =
                  thirdDirectRepeater != null &&
                  path.pathBytes.isNotEmpty &&
                  thirdDirectRepeater.pubkeyFirstByte == path.pathBytes.first;

              int ranking = -1;
              Color color = Colors.grey;
              if (isDirectRepeater) {
                color = Colors.green;
                ranking = 3;
              } else if (isSecondDirectRepeater) {
                color = Colors.yellow;
                ranking = 2;
              } else if (isThirdDirectRepeater) {
                color = Colors.red;
                ranking = 1;
              } else if (path.wasFloodDiscovery) {
                color = Colors.blue;
                ranking = 0;
              }

              return MapEntry(ranking, MapEntry(color, path));
            }).toList();

        pathsWithRepeaters.sort((a, b) => b.key.compareTo(a.key));

        return AlertDialog(
          title: Text(l10n.chat_pathManagement),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.path_currentPath(currentContact.pathLabel),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (paths.isNotEmpty) ...[
                  if (repeatersList.isNotEmpty)
                    FeatureToggleRow(
                      title: l10n.chat_ShowAllPaths,
                      subtitle: "",
                      value: _showAllPaths,
                      onChanged: (val) {
                        setState(() {
                          _showAllPaths = val;
                        });
                      },
                    ),
                  Text(
                    l10n.chat_recentAckPaths,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (pathsWithRepeaters.length >= 100) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.chat_pathHistoryFull,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...pathsWithRepeaters.map((entry) {
                    final path = entry.value.value;
                    final color = entry.value.key;

                    if (!_showAllPaths && entry.key < 1) {
                      return const SizedBox.shrink();
                    } else {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: color,
                            child: Text(
                              path.routeWeight.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          title: Text(
                            l10n.chat_hopsCount(path.hopCount),
                            style: const TextStyle(fontSize: 14),
                          ),
                          isThreeLine: true,
                          subtitle: Text(
                            '${(path.tripTimeMs / 1000).toStringAsFixed(2)}s • ${_formatRelativeTime(context, path.timestamp)}\n${path.successCount} ${l10n.chat_successes} • Score: ${path.routeWeight.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                tooltip: l10n.chat_removePath,
                                onPressed: () async {
                                  await pathService.removePathRecord(
                                    currentContact.publicKeyHex,
                                    path.pathBytes,
                                  );
                                },
                              ),
                              path.wasFloodDiscovery
                                  ? const Icon(
                                      Icons.waves,
                                      size: 16,
                                      color: Colors.grey,
                                    )
                                  : const Icon(
                                      Icons.route,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                            ],
                          ),
                          onLongPress: () =>
                              _showFullPathDialog(context, path.pathBytes),
                          onTap: () async {
                            if (path.pathBytes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.chat_pathDetailsNotAvailable,
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final pathBytes = Uint8List.fromList(
                              path.pathBytes,
                            );
                            final pathLength = path.pathBytes.length;

                            await connector.setPathOverride(
                              currentContact,
                              pathLen: pathLength,
                              pathBytes: pathBytes,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.path_usingHopsPath(path.hopCount),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  }),
                  const Divider(),
                ] else ...[
                  Text(l10n.chat_noPathHistoryYet),
                  const Divider(),
                ],
                // Flood delivery stats
                Builder(
                  builder: (context) {
                    final floodStats = pathService.getFloodStats(
                      currentContact.publicKeyHex,
                    );
                    if (floodStats == null ||
                        (floodStats.successCount == 0 &&
                            floodStats.failureCount == 0)) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.waves, size: 16),
                        ),
                        title: const Text(
                          'Flood Mode',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${floodStats.successCount} ${l10n.chat_successes} / ${floodStats.failureCount} failures'
                          '${floodStats.lastTripTimeMs > 0 ? ' • ${(floodStats.lastTripTimeMs / 1000).toStringAsFixed(2)}s' : ''}'
                          '${floodStats.lastUsed != null ? ' • ${_formatRelativeTime(context, floodStats.lastUsed!)}' : ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.chat_pathActions,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.edit_road, size: 16),
                  ),
                  title: Text(
                    l10n.chat_setCustomPath,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.chat_setCustomPathSubtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await _setCustomPath(context, connector, currentContact);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.clear_all, size: 16),
                  ),
                  title: Text(
                    l10n.chat_clearPath,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.chat_clearPathSubtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await connector.clearContactPath(currentContact);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.chat_pathCleared),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.waves, size: 16),
                  ),
                  title: Text(
                    l10n.chat_forceFloodMode,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.chat_floodModeSubtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await connector.setPathOverride(
                      currentContact,
                      pathLen: -1,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.chat_floodModeEnabled),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_close),
            ),
          ],
        );
      },
    );
  }
}
