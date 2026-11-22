import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/coordinate_parser.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../screens/coordinate_map_screen.dart';
import '../theme/mesh_theme.dart';
import '../utils/platform_info.dart';
import '../widgets/mesh_ui.dart';

class LinkHandler {
  static TextStyle defaultLinkStyle(BuildContext context, TextStyle base) {
    final brightness = Theme.of(context).brightness;
    final orange = brightness == Brightness.dark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFE65100);
    return base.copyWith(color: orange, decoration: TextDecoration.underline);
  }

  static Color _inferBackground(BuildContext context, TextStyle base) {
    final textColor = base.color;
    if (textColor != null) {
      return textColor.computeLuminance() > 0.5
          ? MeshPalette.bg2
          : Colors.white;
    }
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  static TextStyle defaultCoordinateStyle(
    BuildContext context,
    TextStyle base, {
    Color? backgroundColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveBg = backgroundColor ?? _inferBackground(context, base);
    final accent = readableAccent(
      scheme.primary,
      effectiveBg,
      minContrast: 4.5,
    );
    return base.copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent,
      fontWeight: FontWeight.w600,
    );
  }

  /// Returns an interactive rich-text widget (selectable on desktop) with URL,
  /// email, and GPS coordinate detection.
  static Widget buildLinkifyText({
    required BuildContext context,
    required String text,
    required TextStyle style,
    TextStyle? linkStyle,
    TextStyle? coordinateStyle,
    Color? backgroundColor,
    VoidCallback? onSecondaryTap,
  }) {
    return _InteractiveMessageText(
      text: text,
      style: style,
      linkStyle: linkStyle,
      coordinateStyle: coordinateStyle,
      backgroundColor: backgroundColor,
      onSecondaryTap: onSecondaryTap,
    );
  }

  static void openCoordinateMap(
    BuildContext context,
    CoordinateElement coordinate,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoordinateMapScreen(
          latitude: coordinate.latitude,
          longitude: coordinate.longitude,
          label: coordinate.text,
        ),
      ),
    );
  }

  static Future<void> copyCoordinateLocation(
    BuildContext context,
    String text,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.coordinate_copied),
    );
  }

  static Future<void> openCoordinateInExternalMaps(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final uri = buildExternalMapUri(latitude, longitude);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.chat_couldNotOpenLink(uri.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_couldNotOpenLink(uri.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  static Future<void> showCoordinateActionSheet(
    BuildContext context,
    CoordinateElement coordinate,
  ) {
    return showMeshSheet<void>(
      context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BottomSheetHeader(
                  title: coordinate.text,
                  subtitle: l10n.chat_location,
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(l10n.coordinate_copyLocation),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    copyCoordinateLocation(context, coordinate.text);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(l10n.coordinate_openInMaps),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openCoordinateInExternalMaps(
                      context,
                      coordinate.latitude,
                      coordinate.longitude,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> handleLinkTap(BuildContext context, String url) async {
    // Show confirmation dialog
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.chat_openLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_openLinkConfirmation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.chat_open),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return;

    // Launch URL
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.chat_couldNotOpenLink(url)),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_invalidLink),
          backgroundColor: Colors.red,
        );
      }
    }
  }
}

/// Extends [TapGestureRecognizer] so Flutter's paragraph/editable semantics
/// recognize it as a tappable link while also forwarding pointers to an owned
/// [LongPressGestureRecognizer] in the same gesture arena.
class _CoordinateGestureRecognizer extends TapGestureRecognizer {
  final LongPressGestureRecognizer _longPress;

  _CoordinateGestureRecognizer({
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) : _longPress = LongPressGestureRecognizer()..onLongPress = onLongPress {
    this.onTap = onTap;
  }

  @override
  void addPointer(PointerDownEvent event) {
    super.addPointer(event);
    _longPress.addPointer(event);
  }

  @override
  void dispose() {
    _longPress.dispose();
    super.dispose();
  }
}

class _InteractiveMessageText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final TextStyle? coordinateStyle;
  final Color? backgroundColor;
  final VoidCallback? onSecondaryTap;

  const _InteractiveMessageText({
    required this.text,
    required this.style,
    this.linkStyle,
    this.coordinateStyle,
    this.backgroundColor,
    this.onSecondaryTap,
  });

  @override
  State<_InteractiveMessageText> createState() =>
      _InteractiveMessageTextState();
}

class _InteractiveMessageTextState extends State<_InteractiveMessageText> {
  late List<({LinkifyElement element, GestureRecognizer? recognizer})> _items;

  @override
  void initState() {
    super.initState();
    _rebuildItems();
  }

  @override
  void didUpdateWidget(covariant _InteractiveMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _rebuildItems();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final item in _items) {
      item.recognizer?.dispose();
    }
    _items = const [];
  }

  void _rebuildItems() {
    final elements = CoordinateParser.linkifyWithCoordinates(widget.text);
    _items = [
      for (final element in elements)
        (element: element, recognizer: _createRecognizer(element)),
    ];
  }

  GestureRecognizer? _createRecognizer(LinkifyElement element) {
    if (element is CoordinateElement) {
      return _CoordinateGestureRecognizer(
        onTap: () {
          if (!mounted) return;
          LinkHandler.openCoordinateMap(context, element);
        },
        onLongPress: () {
          if (!mounted) return;
          LinkHandler.showCoordinateActionSheet(context, element);
        },
      );
    }
    if (element is LinkableElement) {
      return TapGestureRecognizer()
        ..onTap = () {
          if (!mounted) return;
          LinkHandler.handleLinkTap(context, element.url);
        };
    }
    return null;
  }

  InlineSpan _buildElementSpan(
    ({LinkifyElement element, GestureRecognizer? recognizer}) item,
    TextStyle effectiveLinkStyle,
    TextStyle effectiveCoordinateStyle,
  ) {
    final element = item.element;
    if (element is CoordinateElement) {
      return TextSpan(
        text: element.text,
        style: effectiveCoordinateStyle,
        recognizer: item.recognizer,
        mouseCursor: SystemMouseCursors.click,
      );
    }
    if (element is LinkableElement) {
      return TextSpan(
        text: element.text,
        style: effectiveLinkStyle,
        recognizer: item.recognizer,
        mouseCursor: SystemMouseCursors.click,
      );
    }
    return TextSpan(text: element.text, style: widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLinkStyle =
        widget.linkStyle ?? LinkHandler.defaultLinkStyle(context, widget.style);
    final effectiveCoordinateStyle =
        widget.coordinateStyle ??
        LinkHandler.defaultCoordinateStyle(
          context,
          widget.style,
          backgroundColor: widget.backgroundColor,
        );
    final span = TextSpan(
      style: widget.style,
      children: [
        for (final item in _items)
          _buildElementSpan(item, effectiveLinkStyle, effectiveCoordinateStyle),
      ],
    );

    if (PlatformInfo.isDesktop) {
      final selectable = SelectableText.rich(span);
      if (widget.onSecondaryTap == null) return selectable;
      return Listener(
        onPointerDown: (event) {
          if (event.buttons & kSecondaryMouseButton != 0) {
            widget.onSecondaryTap!();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: selectable,
      );
    }

    return Text.rich(span);
  }
}
