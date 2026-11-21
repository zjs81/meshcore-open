import 'package:flutter/material.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/contact_localization.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../theme/mesh_theme.dart';
import '../utils/contact_search.dart';

/// Create/edit dialog for a phone-side contact group. Current members are
/// listed first with a remove button each; the searchable "Add contacts"
/// list below shows only contacts that are not members yet.
///
/// Membership changes stay in the dialog until Save, which calls [onSave].
/// Nothing here touches the contacts stored on the radio.
class ContactGroupEditorDialog extends StatefulWidget {
  const ContactGroupEditorDialog({
    super.key,
    required this.contacts,
    required this.validateName,
    required this.onSave,
    this.group,
  });

  final List<Contact> contacts;
  final ContactGroup? group;

  /// Returns an error message for an invalid trimmed name, or null.
  final String? Function(String name) validateName;
  final Future<void> Function(ContactGroup group) onSave;

  @override
  State<ContactGroupEditorDialog> createState() =>
      _ContactGroupEditorDialogState();
}

class _ContactGroupEditorDialogState extends State<ContactGroupEditorDialog> {
  late final TextEditingController _nameController;
  // Insertion-ordered; keeps keys of contacts no longer on the radio.
  late final Set<String> _memberKeys;
  late final List<Contact> _sortedContacts;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _memberKeys = <String>{...?widget.group?.memberKeys};
    _sortedContacts = List<Contact>.from(widget.contacts)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final error = widget.validateName(name);
    if (error != null) {
      showDismissibleSnackBar(context, content: Text(error));
      return;
    }
    await widget.onSave(
      ContactGroup(name: name, memberKeys: _memberKeys.toList()),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final members = _sortedContacts
        .where((c) => _memberKeys.contains(c.publicKeyHex))
        .toList();
    final candidates = _sortedContacts
        .where(
          (c) =>
              !_memberKeys.contains(c.publicKeyHex) &&
              matchesContactQuery(c, _query),
        )
        .toList();
    if (_query.trim().isNotEmpty) {
      candidates.sort((a, b) => compareContactQueryRank(a, b, _query));
    }

    Widget sectionLabel(String text) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Text(
          text.toUpperCase(),
          style: MeshTheme.accentLabel(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ),
    );

    Widget contactTile(Contact contact, {required bool isMember}) {
      return ListTile(
        key: ValueKey(
          'group-${isMember ? 'member' : 'candidate'}-'
          '${contact.publicKeyHex}',
        ),
        contentPadding: const EdgeInsetsDirectional.only(start: 4),
        title: Text(
          contact.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(contact.typeLabel(l10n)),
        onTap: isMember
            ? null
            : () => setState(() => _memberKeys.add(contact.publicKeyHex)),
        trailing: isMember
            ? IconButton(
                tooltip: l10n.contacts_groupRemoveMember(contact.name),
                icon: Icon(Icons.remove_circle_outline, color: scheme.error),
                onPressed: () =>
                    setState(() => _memberKeys.remove(contact.publicKeyHex)),
              )
            : IconButton(
                tooltip: l10n.contacts_groupAddMember(contact.name),
                icon: Icon(Icons.add_circle_outline, color: scheme.primary),
                onPressed: () =>
                    setState(() => _memberKeys.add(contact.publicKeyHex)),
              ),
      );
    }

    Widget emptyText(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
      ),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      title: Text(
        widget.group != null ? l10n.contacts_editGroup : l10n.contacts_newGroup,
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.contacts_groupName,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: sectionLabel(
                l10n.contacts_groupCurrentMembers(members.length),
              ),
            ),
            if (members.isEmpty)
              SliverToBoxAdapter(child: emptyText(l10n.contacts_noMembers))
            else
              SliverList.builder(
                itemCount: members.length,
                itemBuilder: (context, index) =>
                    contactTile(members[index], isMember: true),
              ),
            SliverToBoxAdapter(
              child: sectionLabel(l10n.contacts_groupAddContacts),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.contacts_filterContacts,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ),
            if (candidates.isEmpty)
              SliverToBoxAdapter(
                child: emptyText(l10n.contacts_noContactsMatchFilter),
              )
            else
              SliverList.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) =>
                    contactTile(candidates[index], isMember: false),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: _save,
          child: Text(
            widget.group != null ? l10n.common_save : l10n.common_create,
          ),
        ),
      ],
    );
  }
}
