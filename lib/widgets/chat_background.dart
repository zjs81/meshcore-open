import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';
import 'package:provider/provider.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/chat_background.dart';
import '../services/chat_background_service.dart';
import '../theme/mesh_theme.dart';

/// Colors offered for chat backgrounds. Shown faded toward the theme's
/// background, so they work in light and dark themes alike.
const List<Color> kChatBackgroundColors = [
  Color(0xFF0F766E),
  Color(0xFF1E3A8A),
  Color(0xFF6B21A8),
  Color(0xFF9F1239),
  Color(0xFF166534),
  Color(0xFF78350F),
  Color(0xFF334155),
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFE7D8B8),
  Color(0xFFBAE6FD),
  Color(0xFFFBCFE8),
];

/// Fade new color backgrounds start with: softer than pictures, which need
/// to stay recognizable.
const double kChatBackgroundColorFade = 0.6;

ChatBackgroundService? _maybeService(
  BuildContext context, {
  bool listen = true,
}) {
  try {
    return Provider.of<ChatBackgroundService>(context, listen: listen);
  } on ProviderNotFoundException {
    return null;
  }
}

/// Draws [chatKey]'s background (its own, or the theme's) behind [child].
class ChatBackdrop extends StatelessWidget {
  final String chatKey;
  final Widget child;

  const ChatBackdrop({super.key, required this.chatKey, required this.child});

  @override
  Widget build(BuildContext context) {
    final background = _maybeService(context)?.resolve(chatKey);
    if (background == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: ChatBackgroundLayer(background: background)),
        child,
      ],
    );
  }
}

/// Paints one [ChatBackground], faded toward the theme's surface color.
class ChatBackgroundLayer extends StatelessWidget {
  final ChatBackground background;

  const ChatBackgroundLayer({super.key, required this.background});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final color = background.color;
    if (color != null) {
      return ColoredBox(color: Color.lerp(color, surface, background.fade)!);
    }
    final id = background.imageId;
    final asset = background.asset;
    final bytes =
        background.inlineImage ??
        (id == null ? null : _maybeService(context)?.imageBytes(id));
    if (bytes == null && asset == null) return ColoredBox(color: surface);
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            // The service caches one Uint8List per picture, and the provider
            // keys on that instance, so rebuilds reuse the decoded image.
            image: bytes != null
                ? JxlImageProvider.memory(bytes)
                : JxlImageProvider.asset(asset!),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => ColoredBox(color: surface),
          ),
          ColoredBox(color: surface.withValues(alpha: background.fade)),
        ],
      ),
    );
  }
}

/// Choose none, a color or a picture, and how faded it is.
class ChatBackgroundPicker extends StatefulWidget {
  final ChatBackground? value;
  final ValueChanged<ChatBackground?> onChanged;

  const ChatBackgroundPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ChatBackgroundPicker> createState() => _ChatBackgroundPickerState();
}

class _ChatBackgroundPickerState extends State<ChatBackgroundPicker> {
  bool _busy = false;

  Future<void> _pickPicture() async {
    final service = _maybeService(context, listen: false);
    if (service == null) return;
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 92,
      );
      if (file == null) return;
      final id = await service.addImage(await file.readAsBytes());
      if (!mounted) return;
      if (id == null) {
        _showError();
        return;
      }
      widget.onChanged(ChatBackground.image(id));
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError() {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chatBackground_pictureFailed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Choice(
              selected: value == null,
              label: l10n.chatBackground_none,
              onTap: () => widget.onChanged(null),
              child: Icon(Icons.block, color: scheme.onSurfaceVariant),
            ),
            for (final color in kChatBackgroundColors)
              _Choice(
                selected: value?.color == color,
                label: colorLabel(color),
                onTap: () => widget.onChanged(
                  ChatBackground.color(
                    color,
                    fade: value?.color != null
                        ? value!.fade
                        : kChatBackgroundColorFade,
                  ),
                ),
                child: ChatBackgroundLayer(
                  background: ChatBackground.color(
                    color,
                    fade: kChatBackgroundColorFade,
                  ),
                ),
              ),
            if (value?.isImage ?? false)
              _Choice(
                selected: true,
                label: l10n.chatBackground_picture,
                onTap: _pickPicture,
                child: ChatBackgroundLayer(background: value!),
              ),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickPicture,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.image_outlined),
          label: Text(l10n.chatBackground_choosePicture),
        ),
        if (value != null) ...[
          const SizedBox(height: 14),
          Text(
            l10n.chatBackground_fade,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: value.fade,
            min: ChatBackground.minFade,
            max: ChatBackground.maxFade,
            divisions: 8,
            label: '${(value.fade * 100).round()}%',
            onChanged: (fade) => widget.onChanged(value.withFade(fade)),
          ),
        ],
      ],
    );
  }

  static String colorLabel(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _Choice extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _Choice({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeshRadii.sm),
        child: Container(
          width: 52,
          height: 52,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(MeshRadii.sm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 3 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (selected)
                Center(child: Icon(Icons.check_circle, color: scheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for one chat's own background. Changes apply live, so the
/// chat behind the sheet shows the result.
Future<void> showChatBackgroundSheet(BuildContext context, String chatKey) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Consumer<ChatBackgroundService>(
      builder: (sheetContext, service, _) {
        final l10n = sheetContext.l10n;
        final overriding = service.overridingTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.chatBackground_title,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chatBackground_thisChatOnly,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (overriding != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(sheetContext).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.chatBackground_themeOverrides(overriding.name),
                          style: Theme.of(sheetContext).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                ChatBackgroundPicker(
                  value: service.chatBackground(chatKey),
                  onChanged: (value) =>
                      service.setChatBackground(chatKey, value),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
