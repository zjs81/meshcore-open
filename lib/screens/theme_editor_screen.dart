import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/custom_theme.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';
import '../theme/theme_icons.dart';
import '../models/chat_background.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/chat_background.dart';
import '../widgets/message_bubble_frame.dart';
import '../widgets/mesh_ui.dart';

/// Background choices offered as one-tap swatches: dark first, then light.
const List<Color> kThemeBackgroundSwatches = [
  Color(0xFF0B1220),
  Color(0xFF000000),
  Color(0xFF161616),
  Color(0xFF0E1A13),
  Color(0xFF071A2B),
  Color(0xFF1C1210),
  Color(0xFF17112A),
  Color(0xFF2A1520),
  Color(0xFFFFFFFF),
  Color(0xFFF4F6F8),
  Color(0xFFFAF7F0),
  Color(0xFFEFFAF4),
  Color(0xFFF0F6FC),
  Color(0xFFFBF0F5),
  Color(0xFFF5F3FF),
  Color(0xFFFFF8E1),
];

/// Accent choices offered as one-tap swatches.
const List<Color> kThemeAccentSwatches = [
  Color(0xFF0EA5E9),
  Color(0xFF3B82F6),
  Color(0xFF1D4ED8),
  Color(0xFF6366F1),
  Color(0xFFA855F7),
  Color(0xFFEC4899),
  Color(0xFFEF4444),
  Color(0xFF9A3412),
  Color(0xFFF97316),
  Color(0xFFF59E0B),
  Color(0xFFFACC15),
  Color(0xFF84CC16),
  Color(0xFF22C55E),
  Color(0xFF047857),
  Color(0xFF14B8A6),
  Color(0xFF06B6D4),
];

/// Creates or edits a [CustomTheme]: a name, a background and an accent,
/// with a live preview of the result.
class ThemeEditorScreen extends StatefulWidget {
  /// The saved theme being edited; null creates a new one.
  final CustomTheme? existing;

  /// Colors to start a new theme from (e.g. a preset being customized).
  final CustomTheme? startFrom;
  final String? initialName;

  const ThemeEditorScreen({
    super.key,
    this.existing,
    this.startFrom,
    this.initialName,
  });

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode();
  final _scrollController = ScrollController();
  late Color _background;
  late Color _accent;
  late Map<String, ThemeIconOverride> _icons;
  ChatBackground? _chatBackground;
  bool _chatBackgroundEverywhere = false;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    final source = widget.existing ?? widget.startFrom;
    _background = source?.background ?? kThemeBackgroundSwatches.first;
    _accent = source?.accent ?? kThemeAccentSwatches.first;
    _icons = Map.of(source?.icons ?? const {});
    _chatBackground = source?.chatBackground;
    _chatBackgroundEverywhere = source?.chatBackgroundEverywhere ?? false;
    _nameController = TextEditingController(
      text: widget.existing?.name ?? widget.initialName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CustomTheme get _draft => CustomTheme(
    id: widget.existing?.id ?? '',
    name: _nameController.text.trim(),
    background: _background,
    accent: _accent,
    icons: Map.unmodifiable(_icons),
    chatBackground: _chatBackground,
    chatBackgroundEverywhere: _chatBackgroundEverywhere,
  );

  Widget _iconTile(ThemeIconSlot slot) {
    return ListTile(
      leading: SizedBox.square(
        dimension: 48,
        child: Center(
          // Shows the shared icon when only the partner slot (list avatar
          // or map marker for the same node type) is set, as the app does.
          child: ThemedIcon.preview(
            slot,
            _icons[slot.key] ?? _icons[slot.partner?.key],
            size: 28,
          ),
        ),
      ),
      title: Text(
        themeIconSlotLabel(context, slot),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: _icons.containsKey(slot.key)
          ? Text(context.l10n.themes_iconChanged)
          : null,
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _pickIcon(slot),
    );
  }

  Future<void> _pickIcon(ThemeIconSlot slot) async {
    final choice = await showModalBottomSheet<_IconChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _IconPickerSheet(
        slot: slot,
        current: _icons[slot.key],
        label: themeIconSlotLabel(context, slot),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice.pickPicture) {
      await _pickPicture(slot);
      return;
    }
    setState(() {
      final value = choice.value;
      if (value == null) {
        _icons.remove(slot.key);
      } else {
        _icons[slot.key] = value;
      }
    });
  }

  Future<void> _pickPicture(ThemeIconSlot slot) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      if (mounted) _showPictureError();
      return;
    }
    if (file == null) return;
    final shrunk = await shrinkThemeIconImage(await file.readAsBytes());
    if (!mounted) return;
    if (shrunk == null) {
      _showPictureError();
      return;
    }
    setState(() => _icons[slot.key] = ThemeIconOverride.image(shrunk));
  }

  void _showPictureError() {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.themes_iconPictureFailed),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      // The name field sits at the top; bring it back into view so the
      // error is seen rather than a button that seems to do nothing.
      setState(() => _showNameError = true);
      _nameFocus.requestFocus();
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    final settingsService = context.read<AppSettingsService>();
    final theme = _draft.copyWith(
      id: widget.existing?.id ?? settingsService.newCustomThemeId(),
      name: name,
    );
    await settingsService.saveCustomTheme(theme, apply: true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final lowContrast = _contrastRatio(_accent, _background) < 3;

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(
          widget.existing == null
              ? l10n.themes_newTitle
              : l10n.themes_editTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                maxLength: 32,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: l10n.themes_name,
                  errorText: _showNameError ? l10n.themes_nameRequired : null,
                ),
                onChanged: (_) {
                  if (_showNameError) setState(() => _showNameError = false);
                },
              ),
            ),
            SectionHeader(l10n.themes_preview),
            _ThemePreview(theme: _draft),
            if (lowContrast)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.themes_lowContrast,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            SectionHeader(l10n.themes_background),
            _ColorPicker(
              help: l10n.themes_backgroundHelp,
              swatches: kThemeBackgroundSwatches,
              value: _background,
              onChanged: (c) => setState(() => _background = c),
            ),
            SectionHeader(l10n.themes_accent),
            _ColorPicker(
              help: l10n.themes_accentHelp,
              swatches: kThemeAccentSwatches,
              value: _accent,
              onChanged: (c) => setState(() => _accent = c),
            ),
            SectionHeader(l10n.themes_chatBackground),
            MeshCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.themes_chatBackgroundHelp,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ChatBackgroundPicker(
                    value: _chatBackground,
                    onChanged: (value) =>
                        setState(() => _chatBackground = value),
                  ),
                  if (_chatBackground != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.themes_chatBackgroundEverywhere),
                      subtitle: Text(l10n.themes_chatBackgroundEverywhereHelp),
                      value: _chatBackgroundEverywhere,
                      onChanged: (value) =>
                          setState(() => _chatBackgroundEverywhere = value),
                    ),
                ],
              ),
            ),
            SectionHeader(l10n.themes_icons),
            MeshCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Text(
                      l10n.themes_iconsHelp,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final slot in ThemeIconSlot.values)
                    if (!slot.isMapMarker) _iconTile(slot),
                ],
              ),
            ),
            SectionHeader(l10n.themes_mapMarkers),
            MeshCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Text(
                      l10n.themes_mapMarkersHelp,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final slot in ThemeIconSlot.values)
                    if (slot.isMapMarker) _iconTile(slot),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(l10n.themes_saveAndUse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WCAG contrast ratio between two colors (1–21).
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

class _ColorPicker extends StatefulWidget {
  final String help;
  final List<Color> swatches;
  final Color value;
  final ValueChanged<Color> onChanged;

  const _ColorPicker({
    required this.help,
    required this.swatches,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: colorToHex(widget.value));
  }

  @override
  void didUpdateWidget(covariant _ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the text in step with swatch taps, but don't fight the user while
    // they are mid-way through typing a hex value.
    if (oldWidget.value != widget.value &&
        parseHexColor(_hexController.text) != widget.value) {
      _hexController.text = colorToHex(widget.value);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MeshCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.help,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in widget.swatches)
                _SwatchButton(
                  color: color,
                  selected: color == widget.value,
                  onTap: () => widget.onChanged(color),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _hexController,
            style: MeshTheme.mono(fontSize: 16),
            decoration: InputDecoration(
              labelText: context.l10n.themes_hexColor,
              hintText: '#RRGGBB',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.value,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline),
                  ),
                ),
              ),
            ),
            onChanged: (text) {
              final color = parseHexColor(text);
              if (color != null) widget.onChanged(color);
            },
          ),
        ],
      ),
    );
  }
}

class _SwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: colorToHex(color),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  color: isDarkColor(color) ? Colors.white : Colors.black,
                )
              : null,
        ),
      ),
    );
  }
}

/// A miniature screen rendered with the draft theme.
class _ThemePreview extends StatelessWidget {
  final CustomTheme theme;

  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = MeshTheme.fromCustom(theme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Theme(
        data: data,
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(MeshRadii.md),
                border: Border.all(color: scheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: Text(
                      theme.name.isEmpty ? l10n.themes_newTitle : theme.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _PreviewChatArea(
                    background: theme.chatBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _bubble(context, l10n.themes_previewIncoming, false),
                          const SizedBox(height: 8),
                          _bubble(context, l10n.themes_previewOutgoing, true),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.themes_previewSwitch,
                                  style: textTheme.bodyLarge,
                                ),
                              ),
                              Switch(value: true, onChanged: (_) {}),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () {},
                              child: Text(l10n.common_save),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bubble(BuildContext context, String text, bool isOutgoing) {
    final colors = MessageBubbleColors.of(context, isOutgoing: isOutgoing);
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: messageBubbleRadius(isOutgoing: isOutgoing),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.text),
        ),
      ),
    );
  }
}

/// Readable name for an icon slot in the editor.
String themeIconSlotLabel(BuildContext context, ThemeIconSlot slot) {
  final l10n = context.l10n;
  switch (slot) {
    case ThemeIconSlot.contacts:
      return l10n.nav_contacts;
    case ThemeIconSlot.channels:
      return l10n.nav_channels;
    case ThemeIconSlot.map:
      return l10n.nav_map;
    case ThemeIconSlot.send:
      return l10n.themes_iconSend;
    case ThemeIconSlot.settings:
      return l10n.settings_title;
    case ThemeIconSlot.repeater:
      return l10n.themes_iconRepeater;
    case ThemeIconSlot.room:
      return l10n.themes_iconRoom;
    case ThemeIconSlot.sensor:
      return l10n.themes_iconSensor;
    case ThemeIconSlot.mapChat:
      return l10n.map_chat;
    case ThemeIconSlot.mapRepeater:
      return l10n.map_repeater;
    case ThemeIconSlot.mapRoom:
      return l10n.map_room;
    case ThemeIconSlot.mapSensor:
      return l10n.map_sensor;
    case ThemeIconSlot.mapSelf:
      return l10n.pathTrace_you;
  }
}

/// Result of the icon picker: a new value (null = default) or a request to
/// pick a picture from the gallery.
class _IconChoice {
  final ThemeIconOverride? value;
  final bool pickPicture;

  const _IconChoice(this.value) : pickPicture = false;
  const _IconChoice.picture() : value = null, pickPicture = true;
}

class _IconPickerSheet extends StatelessWidget {
  final ThemeIconSlot slot;
  final ThemeIconOverride? current;
  final String label;

  const _IconPickerSheet({
    required this.slot,
    required this.current,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pop(context, const _IconChoice.picture()),
            icon: const Icon(Icons.image_outlined),
            label: Text(l10n.themes_iconUsePicture),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: current == null
                ? null
                : () => Navigator.pop(context, const _IconChoice(null)),
            icon: Icon(slot.icon),
            label: Text(l10n.themes_iconReset),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final entry in kThemeIconCatalog.entries)
                Semantics(
                  button: true,
                  selected: current?.icon == entry.key,
                  label: entry.key.replaceAll('_', ' '),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MeshRadii.sm),
                    onTap: () => Navigator.pop(
                      context,
                      _IconChoice(ThemeIconOverride.icon(entry.key)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(MeshRadii.sm),
                        color: current?.icon == entry.key
                            ? scheme.primary.withValues(alpha: 0.16)
                            : scheme.surfaceContainerHigh,
                        border: Border.all(
                          color: current?.icon == entry.key
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Icon(entry.value, size: 30),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The preview's message area, drawn over the draft chat background.
class _PreviewChatArea extends StatelessWidget {
  final ChatBackground? background;
  final Widget child;

  const _PreviewChatArea({required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = background;
    if (bg == null) return child;
    return Stack(
      children: [
        Positioned.fill(child: ChatBackgroundLayer(background: bg)),
        child,
      ],
    );
  }
}
