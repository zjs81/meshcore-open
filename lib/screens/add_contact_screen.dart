import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/contact_clipboard.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/utf8_length_limiter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import '../utils/app_logger.dart';
import '../utils/contact_qr.dart';
import '../utils/radio_guard.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import 'contact_qr_scanner_screen.dart';
import 'discovery_screen.dart';

/// Unified page for adding a contact manually by public key, from clipboard,
/// from discovered contacts, or by scanning a QR code.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicKeyFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameController = TextEditingController();
  final _publicKeyController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _publicKeyFocusNode = FocusNode();

  int _selectedType = advTypeChat;
  bool _isSaving = false;
  bool _isImporting = false;

  bool get _isBusy => _isSaving || _isImporting;

  static const List<int> _contactTypes = [
    advTypeChat,
    advTypeRepeater,
    advTypeRoom,
    advTypeSensor,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _publicKeyController.dispose();
    _nameFocusNode.dispose();
    _publicKeyFocusNode.dispose();
    super.dispose();
  }

  String _typeLabel(AppLocalizations l10n, int type) {
    switch (type) {
      case advTypeChat:
        return l10n.contact_typeChat;
      case advTypeRepeater:
        return l10n.contact_typeRepeater;
      case advTypeRoom:
        return l10n.contact_typeRoom;
      case advTypeSensor:
        return l10n.contact_typeSensor;
      default:
        return l10n.contact_typeUnknown;
    }
  }

  Future<void> _pickContactType() async {
    final chosen = await showMeshSheet<int>(
      context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BottomSheetHeader(title: l10n.addContact_contactType),
                for (final type in _contactTypes)
                  MeshSheetOption(
                    label: _typeLabel(l10n, type),
                    selected: type == _selectedType,
                    onTap: () => Navigator.pop(sheetContext, type),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || chosen == null) return;
    setState(() => _selectedType = chosen);
  }

  Future<void> _saveContact() async {
    if (_isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!ensureRadioConnected(context)) return;

    final keyHex = normalizeContactPublicKeyHex(_publicKeyController.text);
    final publicKeyBytes = decodeContactPublicKeyHex(_publicKeyController.text);
    if (keyHex == null || publicKeyBytes == null) return;

    final connector = context.read<MeshCoreConnector>();
    if (connector.selfPublicKeyHex.isNotEmpty &&
        keyHex == connector.selfPublicKeyHex.toLowerCase()) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contactShare_isYou),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await connector.addContactFromCard(
        ScannedContact(
          publicKey: publicKeyBytes,
          name: _nameController.text.trim(),
          type: _selectedType,
        ),
      );
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.discoveredContacts_contactAdded),
      );
      Navigator.pop(context, true);
    } catch (e) {
      appLogger.warn('Manual contact add failed: $e', tag: 'AddContactScreen');
      if (!mounted) return;
      setState(() => _isSaving = false);
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.addContact_saveFailed),
      );
    }
  }

  Future<void> _importFromClipboard() async {
    if (_isBusy) return;
    final clipboardData = await Clipboard.getData('text/plain');
    if (!mounted) return;

    final parsed = parseContactClipboard(clipboardData?.text);
    switch (parsed.kind) {
      case ContactClipboardKind.empty:
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_clipboardEmpty),
        );
        return;
      case ContactClipboardKind.invalid:
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
        return;
      case ContactClipboardKind.publicKey:
        _publicKeyController.text = parsed.publicKeyHex!;
        if (_publicKeyFieldKey.currentState?.hasError == true) {
          _publicKeyFieldKey.currentState?.validate();
        }
        _nameFocusNode.requestFocus();
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.addContact_clipboardKeyLoaded),
        );
        return;
      case ContactClipboardKind.contact:
        if (!ensureRadioConnected(context)) return;
        final scanned = parsed.contact!;
        final connector = context.read<MeshCoreConnector>();
        if (scanned.publicKey != null &&
            connector.selfPublicKeyHex.isNotEmpty &&
            pubKeyToHex(scanned.publicKey!).toLowerCase() ==
                connector.selfPublicKeyHex.toLowerCase()) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.contactShare_isYou),
          );
          return;
        }
        setState(() => _isImporting = true);
        try {
          await connector.addContactFromCard(scanned);
          if (!mounted) return;
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.contacts_contactImported),
          );
          Navigator.pop(context, true);
        } catch (e) {
          appLogger.warn(
            'Clipboard contact import failed: $e',
            tag: 'AddContactScreen',
          );
          if (!mounted) return;
          setState(() => _isImporting = false);
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.contacts_contactImportFailed),
          );
        }
        return;
    }
  }

  void _openDiscoveredContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
    );
  }

  Future<void> _scanQrCode() async {
    if (!ensureRadioConnected(context)) return;
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ContactQrScannerScreen()),
    );
    if (imported == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.addContact_title),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.common_save,
            onPressed: _isBusy ? null : _saveContact,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              MeshCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 24,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.addContact_infoBanner,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              MeshCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildContactTypeRow(context),
                    const Divider(height: 1, indent: 16),
                    _buildNameRow(context),
                    const Divider(height: 1, indent: 16),
                    _buildPublicKeyRow(context),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              MeshCard(
                padding: EdgeInsets.zero,
                child: MeshNavTile(
                  icon: Icons.content_paste,
                  title: l10n.contacts_addContactFromClipboard,
                  onTap: _isBusy ? null : _importFromClipboard,
                ),
              ),
              MeshCard(
                padding: EdgeInsets.zero,
                child: MeshNavTile(
                  icon: Icons.person_add_rounded,
                  title: l10n.addContact_fromDiscovered,
                  onTap: _isBusy ? null : _openDiscoveredContacts,
                ),
              ),
              MeshCard(
                padding: EdgeInsets.zero,
                child: MeshNavTile(
                  icon: Icons.qr_code_scanner,
                  title: l10n.contacts_scanQrCode,
                  onTap: _isBusy ? null : _scanQrCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTypeRow(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = _typeLabel(l10n, _selectedType);

    return Semantics(
      button: true,
      enabled: !_isBusy,
      label: '${l10n.addContact_contactType}: $label',
      child: InkWell(
        onTap: _isBusy ? null : _pickContactType,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 24,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.addContact_contactType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(label, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  size: 24,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 24, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              enabled: !_isBusy,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _publicKeyFocusNode.requestFocus(),
              inputFormatters: [
                Utf8LengthLimitingTextInputFormatter(maxRadioNameBytes),
              ],
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: l10n.addContact_name,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                errorMaxLines: 4,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.addContact_nameRequired;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicKeyRow(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 24,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              key: _publicKeyFieldKey,
              controller: _publicKeyController,
              focusNode: _publicKeyFocusNode,
              enabled: !_isBusy,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveContact(),
              minLines: 1,
              maxLines: 3,
              style: MeshTheme.mono(fontSize: 15, color: scheme.onSurface),
              decoration: InputDecoration(
                labelText: l10n.addContact_publicKeyHex,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                errorMaxLines: 4,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.addContact_publicKeyRequired;
                }
                if (decodeContactPublicKeyHex(value) == null) {
                  return l10n.addContact_publicKeyInvalid;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
