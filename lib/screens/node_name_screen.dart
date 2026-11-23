import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/utf8_length_limiter.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/unsaved_changes_guard.dart';

/// Node name editor showing the bytes left for messages.
class NodeNameScreen extends StatefulWidget {
  const NodeNameScreen({super.key});

  @override
  State<NodeNameScreen> createState() => _NodeNameScreenState();
}

class _NodeNameScreenState extends State<NodeNameScreen> {
  final _page = GlobalKey<SaveToRadioPageState>();
  late final TextEditingController _controller;
  late String _savedName;

  @override
  void initState() {
    super.initState();
    final name = context.read<MeshCoreConnector>().selfName ?? '';
    // Compared trimmed, like the field.
    _savedName = name.trim();
    _controller = TextEditingController(text: name)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  Future<bool> _save() async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    final name = _name;
    await connector.setNodeName(name);
    await connector.refreshDeviceInfo();
    if (!mounted) return true;
    setState(() => _savedName = name);
    showDismissibleSnackBar(
      context,
      content: Text(l10n.settings_nodeNameUpdated),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bytes = utf8ByteLength(_name);
    final over = bytes - maxRadioNameBytes;
    return SaveToRadioPage(
      key: _page,
      title: l10n.settings_nodeName,
      hasChanges: _name != _savedName,
      canSave: _name.isNotEmpty && over <= 0,
      onSave: _save,
      children: [
        SectionHeader(l10n.settings_nodeName),
        MeshCard(
          child: TextField(
            controller: _controller,
            autofocus: _savedName.isEmpty,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _page.currentState?.save(),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            // No length limit: an over-long name shows how far over it is
            // instead of silently refusing input.
            decoration: InputDecoration(
              labelText: l10n.settings_infoName,
              hintText: l10n.settings_nodeNameHint,
              errorText: over > 0 ? l10n.nodeName_bytesOver(over) : null,
              suffixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
                child: Text(
                  '$bytes / $maxRadioNameBytes',
                  style: TextStyle(
                    fontSize: 12,
                    color: over > 0 ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(),
            ),
          ),
        ),
        SectionHeader(
          l10n.nodeName_messageLength,
          description: l10n.nodeName_info,
        ),
        _buildMessageLimits(context),
      ],
    );
  }

  Widget _buildMessageLimits(BuildContext context) {
    final l10n = context.l10n;
    final name = _name;
    // Empty or over-long names can't be saved.
    final channelValue =
        name.isEmpty || utf8ByteLength(name) > maxRadioNameBytes
        ? l10n.common_notAvailable
        : l10n.nodeName_bytesAvailable(maxChannelMessageBytes(name));
    return MeshCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _LimitRow(
            icon: Icons.forum_outlined,
            title: l10n.nodeName_channelMessages,
            value: channelValue,
            subtitle: l10n.nodeName_channelMessagesSubtitle,
          ),
          const Divider(height: 1, indent: 16),
          _LimitRow(
            icon: Icons.chat_bubble_outline,
            title: l10n.nodeName_directMessages,
            value: l10n.nodeName_bytesAvailable(maxContactMessageBytes()),
            subtitle: l10n.nodeName_directMessagesSubtitle,
          ),
        ],
      ),
    );
  }
}

/// Settings row with a read-only value: icon, title, the value in mono 15
/// (like the Settings device info values) and a subtitle.
class _LimitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _LimitRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: meshTileTitleStyle(theme)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: MeshTheme.mono(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
