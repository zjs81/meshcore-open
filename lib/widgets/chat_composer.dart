import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../helpers/gif_helper.dart';
import '../helpers/mention_search.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/radio_guard.dart';
import 'byte_count_input.dart';
import 'connect_sheet.dart';
import 'gif_message.dart';
import 'gif_picker.dart';
import 'mesh_ui.dart';
import 'message_translation_button.dart';
import '../theme/theme_icons.dart';

/// One entry of the composer's "+" menu.
@immutable
class ChatComposerAction {
  final String id;
  final IconData icon;
  final String label;

  const ChatComposerAction({
    required this.id,
    required this.icon,
    required this.label,
  });
}

/// Opens the GIF picker and puts the chosen GIF into [controller].
void showChatGifPicker(BuildContext context, TextEditingController controller) {
  showMeshSheet<void>(
    context,
    builder: (context) => GifPicker(
      onGifSelected: (gifId) {
        controller.text = GifHelper.encodeGif(gifId);
      },
    ),
  );
}

/// Opens the outgoing-translation options sheet.
Future<void> showComposerTranslationOptions(BuildContext context) async {
  final settingsService = context.read<AppSettingsService>();
  final settings = settingsService.settings;
  await showMessageTranslationSheet(
    context: context,
    enabled: settings.composerTranslationEnabled,
    selectedLanguageCode: settings.translationTargetLanguageCode,
    onEnabledChanged: settingsService.setComposerTranslationEnabled,
    onLanguageSelected: settingsService.setTranslationTargetLanguageCode,
  );
}

/// The message composer shared by the direct and channel chat screens:
/// "+" action menu, optional translation toggle, byte-counted text field (or
/// GIF preview) and send button. [header] widgets (reply banner, progress)
/// are stacked above the row.
///
/// When [mentionSearch] is provided, typing `@` opens a suggestion list above
/// the text field; picking an entry replaces the `@query` token at the cursor
/// with the MeshCore `@[name] ` mention format.
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxBytes;
  final int? softLimitBytes;
  final String? softLimitNote;
  final String Function(String)? encoder;
  final VoidCallback onSend;
  final String sendTooltip;

  /// Builds the "+" menu entries when it is opened, so they reflect the
  /// current state (e.g. whether the radio has a position).
  final List<ChatComposerAction> Function() actionsBuilder;
  final ValueChanged<String> onAction;
  final List<Widget> header;

  /// Returns mention candidates for the text typed after `@` (empty for a
  /// bare `@`), most recent first. Null disables the mention picker.
  final List<MentionCandidate> Function(String query)? mentionSearch;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.maxBytes,
    required this.onSend,
    required this.sendTooltip,
    required this.actionsBuilder,
    required this.onAction,
    this.softLimitBytes,
    this.softLimitNote,
    this.encoder,
    this.header = const [],
    this.mentionSearch,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  static const int _maxMentions = 12;
  static final RegExp _mentionBreak = RegExp(r'[\s\])#]');

  /// Index of the `@` that started the active mention, null when inactive.
  int? _mentionStart;
  List<MentionCandidate> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncMention);
    widget.focusNode.addListener(_onFocusChanged);
    _syncMention();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncMention);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) return;
    // Delay so a tap on a suggestion (which unfocuses the field first) can
    // apply the mention before the panel disappears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.focusNode.hasFocus) return;
      _clearMention();
    });
  }

  void _syncMention() {
    if (widget.mentionSearch == null) return;
    final value = widget.controller.value;
    var start = _activeMentionStart(value);
    var suggestions = const <MentionCandidate>[];
    if (start != null) {
      final query = value.text.substring(start + 1, value.selection.start);
      suggestions = widget.mentionSearch!(query).take(_maxMentions).toList();
      if (suggestions.isEmpty) start = null;
    }
    if (start == null) {
      _clearMention();
      return;
    }
    setState(() {
      _mentionStart = start;
      _suggestions = suggestions;
    });
  }

  /// Start index of the `@query` token the cursor sits at, or null when the
  /// cursor is not in one. The `@` must start the text or follow whitespace,
  /// and nothing between it and the cursor may be whitespace or a bracket.
  int? _activeMentionStart(TextEditingValue value) {
    if (!value.selection.isValid || !value.selection.isCollapsed) return null;
    final before = value.text.substring(0, value.selection.start);
    final at = before.lastIndexOf('@');
    if (at == -1) return null;
    if (_mentionBreak.hasMatch(before.substring(at + 1))) return null;
    if (at > 0 && !_mentionBreak.hasMatch(before[at - 1])) return null;
    return at;
  }

  void _clearMention() {
    if (_mentionStart == null) return;
    setState(() {
      _mentionStart = null;
      _suggestions = const [];
    });
  }

  void _applyMention(MentionCandidate candidate) {
    final start = _mentionStart;
    if (start == null) return;
    final value = widget.controller.value;
    final end = value.selection.isValid
        ? value.selection.end
        : value.text.length;
    final inserted = '@[${candidate.name}] ';
    final text = value.text.replaceRange(start, end, inserted);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
    _clearMention();
    widget.focusNode.requestFocus();
  }

  Widget _buildMentionPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Material(
          type: MaterialType.card,
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeshRadii.md),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final candidate in _suggestions)
                  GestureDetector(
                    // Apply on pointer-down: tapping the row unfocuses the
                    // text field, which would otherwise drop the panel and
                    // cancel the tap before it lands.
                    onTapDown: (_) => _applyMention(candidate),
                    behavior: HitTestBehavior.opaque,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.alternate_email),
                      title: Text(candidate.name),
                      onTap: () => _applyMention(candidate),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openActionMenu(BuildContext buttonContext) async {
    final actions = widget.actionsBuilder();
    if (actions.isEmpty) return;
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final buttonOffset = button.localToGlobal(Offset.zero, ancestor: overlay);
    final menuHeight = actions.length * kMinInteractiveDimension + 16;
    final menuTop = (buttonOffset.dy - menuHeight).clamp(
      8.0,
      overlay.size.height,
    );
    final position = RelativeRect.fromLTRB(
      buttonOffset.dx,
      menuTop,
      overlay.size.width - buttonOffset.dx - button.size.width,
      overlay.size.height - buttonOffset.dy,
    );
    final selected = await showMenu<String>(
      context: buttonContext,
      position: position,
      // Keep focus on the text field: if the menu route took focus, the
      // keyboard would close, the composer would drop down and the menu would
      // be left floating where the keyboard used to be.
      requestFocus: false,
      items: [
        for (final action in actions)
          PopupMenuItem(
            value: action.id,
            child: MeshMenuItemRow(icon: action.icon, label: action.label),
          ),
      ],
    );
    if (selected == null || !buttonContext.mounted) return;
    widget.onAction(selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Offline the chat is read-only. The draft stays in [controller] (owned
    // by the screen) and is back when the radio reconnects.
    if (context.radioReadOnly) return const OfflineComposerBar();
    final translation = context
        .select<AppSettingsService, (bool, bool, String?)>(
          (s) => (
            s.settings.translationEnabled,
            s.settings.composerTranslationEnabled,
            s.settings.translationTargetLanguageCode,
          ),
        );
    final showMentionPanel = _mentionStart != null && _suggestions.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.header,
            if (showMentionPanel) _buildMentionPanel(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (buttonContext) => IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: context.l10n.chat_selectSendAction,
                      onPressed: () => _openActionMenu(buttonContext),
                    ),
                  ),
                  if (translation.$1)
                    MessageTranslationButton(
                      enabled: translation.$2,
                      languageCode: translation.$3,
                      onPressed: () => showComposerTranslationOptions(context),
                    ),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, _) {
                        final gifId = GifHelper.parseGif(value.text);
                        if (gifId != null) {
                          return _buildGifPreview(context, gifId, scheme);
                        }
                        return _buildTextField(context, scheme);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return IconButton.filled(
                        icon: const ThemedIcon(ThemeIconSlot.send, size: 20),
                        tooltip: widget.sendTooltip,
                        style: IconButton.styleFrom(
                          backgroundColor: hasText
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          foregroundColor: hasText
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          minimumSize: const Size(40, 40),
                          shape: const CircleBorder(),
                        ),
                        onPressed: hasText
                            ? () {
                                HapticFeedback.lightImpact();
                                widget.onSend();
                              }
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifPreview(
    BuildContext context,
    String gifId,
    ColorScheme scheme,
  ) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          widget.onSend();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GifMessage(
                url: 'https://media.giphy.com/media/$gifId/giphy.gif',
                backgroundColor: scheme.surfaceContainerHighest,
                fallbackTextColor: scheme.onSurface.withValues(alpha: 0.6),
                maxSize: 160,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: context.l10n.chat_removeGif,
            onPressed: () {
              widget.controller.clear();
              widget.focusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, ColorScheme scheme) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          borderSide: BorderSide(color: color, width: width),
        );
    return ByteCountedTextField(
      maxBytes: widget.maxBytes,
      softLimitBytes: widget.softLimitBytes,
      softLimitNote: widget.softLimitNote,
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: context.l10n.chat_typeMessage,
      onSubmitted: (_) => widget.onSend(),
      encoder: widget.encoder,
      decoration: InputDecoration(
        hintText: context.l10n.chat_typeMessage,
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 1.5),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Stands in for the composer while no radio is connected.
class OfflineComposerBar extends StatelessWidget {
  const OfflineComposerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final message = Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: scheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.chat_composerOffline,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              );
              // Side by side when there is room; otherwise the button goes
              // under the message so large text never squeezes it.
              final roomy =
                  constraints.maxWidth /
                      MediaQuery.textScalerOf(context).scale(1) >=
                  420;
              if (roomy) {
                return Row(
                  children: [
                    Expanded(child: message),
                    const SizedBox(width: 8),
                    const ConnectButton(),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  message,
                  const SizedBox(height: 8),
                  const ConnectButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
