import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../helpers/snack_bar_builder.dart';

class PathSelectionDialog extends StatefulWidget {
  final List<Contact> availableContacts;
  final String title;
  final String? initialPath;
  final String? currentPathLabel;
  final VoidCallback? onRefresh;

  const PathSelectionDialog({
    super.key,
    required this.availableContacts,
    required this.title,
    this.initialPath,
    this.currentPathLabel,
    this.onRefresh,
  });

  @override
  State<PathSelectionDialog> createState() => _PathSelectionDialogState();

  static Future<Uint8List?> show(
    BuildContext context, {
    required List<Contact> availableContacts,
    String? title,
    String? initialPath,
    String? currentPathLabel,
    VoidCallback? onRefresh,
  }) {
    return showDialog<Uint8List?>(
      context: context,
      builder: (context) => PathSelectionDialog(
        availableContacts: availableContacts,
        title: title ?? context.l10n.path_enterCustomPath,
        initialPath: initialPath,
        currentPathLabel: currentPathLabel,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _PathSelectionDialogState extends State<PathSelectionDialog> {
  late TextEditingController _controller;
  final List<Contact> _selectedContacts = [];
  List<Contact> _validContacts = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPath ?? '');
    _filterValidContacts();
  }

  @override
  void didUpdateWidget(PathSelectionDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availableContacts != oldWidget.availableContacts) {
      _filterValidContacts();
    }
  }

  void _filterValidContacts() {
    _validContacts = widget.availableContacts
        .where((c) => c.type == advTypeRepeater || c.type == advTypeRoom)
        .toList();
  }

  void _updateTextFromContacts() {
    final pathParts = _selectedContacts
        .map((contact) {
          if (contact.publicKeyHex.length >= 2) {
            return contact.publicKeyHex.substring(0, 2);
          }
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();

    _controller.text = pathParts.join(',');
  }

  void _toggleContact(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
      _updateTextFromContacts();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedContacts.clear();
      _controller.clear();
    });
  }

  Future<void> _validateAndSubmit() async {
    final l10n = context.l10n;
    final path = _controller.text.trim().toUpperCase();
    if (path.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Parse comma-separated hex prefixes
    final pathIds = path
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final pathBytesList = <int>[];
    final invalidPrefixes = <String>[];

    for (final id in pathIds) {
      if (id.length < 2) {
        invalidPrefixes.add(id);
        continue;
      }

      final prefix = id.substring(0, 2);
      try {
        final byte = int.parse(prefix, radix: 16);
        pathBytesList.add(byte);
      } catch (e) {
        invalidPrefixes.add(id);
      }
    }

    if (!mounted) return;

    // Show error for invalid prefixes
    if (invalidPrefixes.isNotEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.path_invalidHexPrefixes(invalidPrefixes.join(", "))),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      );
      return;
    }

    // Check max path length (64 hops)
    if (pathBytesList.length > 64) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.path_tooLong),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      );
      return;
    }

    if (pathBytesList.isNotEmpty && mounted) {
      Navigator.pop(context, Uint8List.fromList(pathBytesList));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.currentPathLabel != null) ...[
                Row(
                  children: [
                    Text(
                      l10n.path_currentPathLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onRefresh != null)
                      TextButton.icon(
                        onPressed: widget.onRefresh,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l10n.common_reload),
                      ),
                  ],
                ),
                Text(
                  widget.currentPathLabel!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.path_hexPrefixInstructions,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.path_hexPrefixExample,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.path_labelHexPrefixes,
                  hintText: l10n.path_hexPrefixExample,
                  border: const OutlineInputBorder(),
                  helperText: l10n.path_helperMaxHops,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 191, // 64 hops * 2 chars + 63 commas
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    l10n.path_selectFromContacts,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedContacts.isNotEmpty)
                    TextButton(
                      onPressed: _clearSelection,
                      child: Text(l10n.common_clear),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_validContacts.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.path_noRepeatersFound,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.path_customPathsRequire,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _validContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _validContacts[index];
                      final isSelected = _selectedContacts.contains(contact);

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected
                              ? Colors.green
                              : (contact.type == 2
                                    ? Colors.blue
                                    : Colors.purple),
                          child: Icon(
                            contact.type == 2
                                ? Icons.router
                                : Icons.meeting_room,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          contact.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${contact.typeLabel} • ${contact.publicKeyHex.substring(0, 2)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.add_circle_outline),
                        onTap: () => _toggleContact(contact),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: _validateAndSubmit,
          child: Text(l10n.path_setPath),
        ),
      ],
    );
  }
}
