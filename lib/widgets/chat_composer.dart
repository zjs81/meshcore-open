import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../helpers/gif_helper.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/radio_guard.dart';
import 'byte_count_input.dart';
import 'chat_background.dart';
import 'connect_sheet.dart';
import 'gif_message.dart';
import 'gif_picker.dart';
import 'mesh_ui.dart';
import 'message_bubble_frame.dart';
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

/// Corner radius of the compose bubble and the offline bar.
const double kComposerBubbleRadius = 20;

/// Lines the compose field grows to before it scrolls.
const int kComposerMaxLines = 5;

/// Fill of the compose bubble: the incoming-bubble colour over a chat
/// background so it stays readable, otherwise a raised surface.
Color composerBubbleColor(BuildContext context) {
  return ChatBackdrop.hasBackgroundOf(context)
      ? MessageBubbleColors.of(context, isOutgoing: false).background
      : Theme.of(context).colorScheme.surfaceContainerHigh;
}

/// The bottom panel holding the compose bubble: transparent over a chat
/// background, solid surface otherwise. 12dp side and 8dp vertical margins
/// (8dp on the trailing side, where the round button's touch target adds 2).
class _ComposerPanel extends StatelessWidget {
  final List<Widget> header;
  final Widget child;

  const _ComposerPanel({this.header = const [], required this.child});

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...header,
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
            child: child,
          ),
        ],
      ),
    );
    if (ChatBackdrop.hasBackgroundOf(context)) return content;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: content,
    );
  }
}

/// The message composer shared by the direct and channel chat screens.
///
/// A rounded compose bubble (optional [replyPreview], then the byte-counted
/// text field or a GIF preview, with the translation toggle on its right)
/// and one round button beside it: "+" (the [actionsBuilder] menu) while the
/// field is empty, Send once there is text. [header] widgets (e.g. image
/// send progress) are stacked full-width above the bubble.
class ChatComposer extends StatelessWidget {
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

  /// Shown inside the top of the bubble, usually a [ChatComposerQuote].
  final Widget? replyPreview;

  /// Marks the compose bubble (and the offline bar's bubble).
  static const bubbleKey = ValueKey('chat-composer-bubble');

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
    this.replyPreview,
  });

  Future<void> _openActionMenu(BuildContext buttonContext) async {
    final actions = actionsBuilder();
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
    onAction(selected);
  }

  @override
  Widget build(BuildContext context) {
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
    final scheme = Theme.of(context).colorScheme;
    final replyPreview = this.replyPreview;
    final bubble = DecoratedBox(
      key: ChatComposer.bubbleKey,
      decoration: BoxDecoration(
        color: composerBubbleColor(context),
        borderRadius: BorderRadius.circular(kComposerBubbleRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyPreview != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: replyPreview,
            ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final gifId = GifHelper.parseGif(value.text);
              if (gifId != null) {
                return _buildGifPreview(context, gifId, scheme);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => _buildTextField(
                        context,
                        scheme,
                        constraints.maxHeight,
                      ),
                    ),
                  ),
                  if (translation.$1)
                    MessageTranslationButton(
                      enabled: translation.$2,
                      languageCode: translation.$3,
                      onPressed: () => showComposerTranslationOptions(context),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    return _ComposerPanel(
      header: header,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: bubble),
          const SizedBox(width: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => _ComposerRoundButton(
              hasText: value.text.trim().isNotEmpty,
              sendTooltip: sendTooltip,
              actionsTooltip: context.l10n.chat_selectSendAction,
              onSend: () {
                HapticFeedback.lightImpact();
                onSend();
              },
              onOpenActions: _openActionMenu,
            ),
          ),
        ],
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
          onSend();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 0, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(MeshRadii.md),
                  child: GifMessage(
                    url: 'https://media.giphy.com/media/$gifId/giphy.gif',
                    backgroundColor: scheme.surfaceContainerHighest,
                    fallbackTextColor: scheme.onSurfaceVariant,
                    maxSize: 160,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: context.l10n.chat_removeGif,
              onPressed: () {
                controller.clear();
                focusNode.requestFocus();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// [maxHeight] is the room the chat leaves the composer: above the
  /// keyboard, since the screen's body resizes for it.
  Widget _buildTextField(
    BuildContext context,
    ColorScheme scheme,
    double maxHeight,
  ) {
    // Five lines, or fewer when large text and a short window leave little
    // room, so the field takes no more than about a quarter of the chat.
    // Never one line: that stops wrapping and the keyboard's newline key.
    final room = maxHeight.isFinite
        ? maxHeight
        : MediaQuery.sizeOf(context).height;
    final lineHeight = MediaQuery.textScalerOf(context).scale(16) * 1.5;
    final maxLines = (room / 4 / lineHeight).floor().clamp(
      2,
      kComposerMaxLines,
    );
    return ByteCountedTextField(
      maxBytes: maxBytes,
      softLimitBytes: softLimitBytes,
      softLimitNote: softLimitNote,
      controller: controller,
      focusNode: focusNode,
      hintText: context.l10n.chat_typeMessage,
      onSubmitted: (_) => onSend(),
      encoder: encoder,
      maxLines: maxLines,
      counterOnlyNearLimit: true,
      decoration: InputDecoration(
        hintText: context.l10n.chat_typeMessage,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        // A 24dp line plus 12 above and below: 48dp on one line, level with
        // the round button beside the bubble.
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
      ),
    );
  }
}

/// The round button beside the compose bubble: "+" while the field is
/// empty, Send once there is text. Drawn at 44dp in a 48dp touch target.
class _ComposerRoundButton extends StatelessWidget {
  final bool hasText;
  final String sendTooltip;
  final String actionsTooltip;
  final VoidCallback onSend;
  final ValueChanged<BuildContext> onOpenActions;

  const _ComposerRoundButton({
    required this.hasText,
    required this.sendTooltip,
    required this.actionsTooltip,
    required this.onSend,
    required this.onOpenActions,
  });

  static const _visualSize = Size(44, 44);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ButtonStyle style(Color background, Color foreground) =>
        IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          fixedSize: _visualSize,
          minimumSize: _visualSize,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const CircleBorder(),
        );
    final Widget button = hasText
        ? IconButton.filled(
            key: const ValueKey('composer-send'),
            icon: const ThemedIcon(ThemeIconSlot.send, size: 22),
            tooltip: sendTooltip,
            style: style(scheme.primary, scheme.onPrimary),
            onPressed: onSend,
          )
        : Builder(
            key: const ValueKey('composer-actions'),
            builder: (buttonContext) => IconButton.filled(
              icon: const Icon(Icons.add, size: 28),
              tooltip: actionsTooltip,
              style: style(composerBubbleColor(context), scheme.onSurface),
              onPressed: () => onOpenActions(buttonContext),
            ),
          );
    return SizedBox.square(
      dimension: kMinInteractiveDimension,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: button,
      ),
    );
  }
}

/// A quoted message inside the top of the compose bubble ("Replying to
/// Bob"): a coloured bar on the leading edge, [title], [content], optional
/// [trailing] controls and a dismiss button.
class ChatComposerQuote extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? trailing;
  final VoidCallback onDismiss;
  final String dismissTooltip;

  const ChatComposerQuote({
    super.key,
    required this.title,
    required this.content,
    required this.onDismiss,
    required this.dismissTooltip,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = scheme.surfaceContainerHighest;
    final accent = readableAccent(scheme.primary, background);
    final trailing = this.trailing;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MeshRadii.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: BorderDirectional(start: BorderSide(color: accent, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 0, 6),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      content,
                    ],
                  ),
                ),
                // The quote shares its row with Send, so a long trailing
                // control (a region chip) must not squeeze out the message
                // or the dismiss button.
                if (trailing != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.4,
                    ),
                    child: trailing,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: dismissTooltip,
                  color: scheme.onSurfaceVariant,
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stands in for the composer while no radio is connected, in the same
/// bubble and margins so the chat doesn't jump on connect or disconnect.
class OfflineComposerBar extends StatelessWidget {
  const OfflineComposerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: DecoratedBox(
        key: ChatComposer.bubbleKey,
        decoration: BoxDecoration(
          color: composerBubbleColor(context),
          borderRadius: BorderRadius.circular(kComposerBubbleRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: scheme.onSurfaceVariant, size: 24),
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
          ),
        ),
      ),
    );
    return _ComposerPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Side by side when there is room; otherwise the button goes
          // under the message so large text never squeezes it.
          final roomy =
              constraints.maxWidth /
                  MediaQuery.textScalerOf(context).scale(1) >=
              420;
          if (roomy) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: message),
                const SizedBox(width: 4),
                const ConnectButton(),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              message,
              const SizedBox(height: 8),
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConnectButton(),
              ),
            ],
          );
        },
      ),
    );
  }
}
