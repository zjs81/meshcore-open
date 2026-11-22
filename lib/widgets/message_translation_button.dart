import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/translation_support.dart';
import 'mesh_ui.dart';

class MessageTranslationButton extends StatelessWidget {
  final bool enabled;
  final String? languageCode;
  final VoidCallback onPressed;

  const MessageTranslationButton({
    super.key,
    required this.enabled,
    required this.languageCode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = _languageLabel(
      languageCode,
      context.l10n.translation_systemLanguage,
    );
    return IconButton(
      icon: Icon(enabled ? Icons.translate : Icons.translate_outlined),
      onPressed: onPressed,
      tooltip: enabled
          ? context.l10n.translation_translateTo(label)
          : context.l10n.translation_translationOptions,
    );
  }
}

Future<void> showMessageTranslationSheet({
  required BuildContext context,
  required bool enabled,
  required String? selectedLanguageCode,
  required ValueChanged<bool> onEnabledChanged,
  required ValueChanged<String?> onLanguageSelected,
}) {
  final callerMedia = MediaQuery.of(context);
  final navMedia =
      MediaQuery.maybeOf(Navigator.of(context).context) ?? callerMedia;
  final callerBottom = math.max(
    callerMedia.viewInsets.bottom,
    math.max(callerMedia.viewPadding.bottom, callerMedia.padding.bottom),
  );
  final navBottom = math.max(
    navMedia.viewInsets.bottom,
    math.max(navMedia.viewPadding.bottom, navMedia.padding.bottom),
  );
  final extraBottom = math.max(0.0, callerBottom - navBottom);
  final safeTop = math.max(
    math.max(callerMedia.viewPadding.top, callerMedia.padding.top),
    math.max(navMedia.viewPadding.top, navMedia.padding.top),
  );
  final bottomSafeInset = math.max(
    math.max(callerMedia.viewPadding.bottom, callerMedia.padding.bottom),
    math.max(navMedia.viewPadding.bottom, navMedia.padding.bottom),
  );

  return showMeshSheet<void>(
    context,
    builder: (sheetContext) {
      final sheetMedia = MediaQuery.of(sheetContext);
      final screenHeight = math.min(
        callerMedia.size.height,
        sheetMedia.size.height,
      );
      final maxSheetHeight = math.max(
        0.0,
        math.min(
          screenHeight * 0.82 - bottomSafeInset,
          screenHeight - safeTop - math.max(callerBottom, navBottom),
        ),
      );
      return MediaQuery(
        data: sheetMedia.copyWith(textScaler: callerMedia.textScaler),
        child: Padding(
          padding: EdgeInsets.only(bottom: extraBottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: _MessageTranslationSheet(
              enabled: enabled,
              selectedLanguageCode: selectedLanguageCode,
              onEnabledChanged: onEnabledChanged,
              onLanguageSelected: onLanguageSelected,
            ),
          ),
        ),
      );
    },
  );
}

class _MessageTranslationSheet extends StatefulWidget {
  final bool enabled;
  final String? selectedLanguageCode;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String?> onLanguageSelected;

  const _MessageTranslationSheet({
    required this.enabled,
    required this.selectedLanguageCode,
    required this.onEnabledChanged,
    required this.onLanguageSelected,
  });

  @override
  State<_MessageTranslationSheet> createState() =>
      _MessageTranslationSheetState();
}

class _MessageTranslationSheetState extends State<_MessageTranslationSheet> {
  final GlobalKey _switchKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  late final TextEditingController _searchController;
  late bool _localEnabled;
  late String? _localSelectedLanguageCode;
  List<TranslationLanguageOption> _filtered = supportedTranslationLanguages;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _localEnabled = widget.enabled;
    _localSelectedLanguageCode = widget.selectedLanguageCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filtered = supportedTranslationLanguages.where((option) {
        return option.label.toLowerCase().contains(normalized) ||
            option.code.toLowerCase().contains(normalized);
      }).toList();
    });
  }

  Widget _buildSwitchTile(BuildContext context) {
    return KeyedSubtree(
      key: _switchKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.translation_translateBeforeSending),
          subtitle: Text(
            _localEnabled
                ? context.l10n.translation_composerEnabledHint
                : context.l10n.translation_composerDisabledHint,
          ),
          value: _localEnabled,
          onChanged: (value) {
            setState(() => _localEnabled = value);
            widget.onEnabledChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return KeyedSubtree(
      key: _searchKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: TextField(
          controller: _searchController,
          onChanged: _updateFilter,
          decoration: InputDecoration(
            labelText: context.l10n.translation_targetLanguage,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, int index) {
    if (index == 0) {
      final selected = _localSelectedLanguageCode == null;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        ),
        title: Text(context.l10n.translation_useAppLanguage),
        onTap: () {
          setState(() => _localSelectedLanguageCode = null);
          widget.onLanguageSelected(null);
          Navigator.pop(context);
        },
      );
    }
    final option = _filtered[index - 1];
    final selected = option.code == _localSelectedLanguageCode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(option.label),
      subtitle: Text(option.code.toUpperCase()),
      onTap: () {
        setState(() => _localSelectedLanguageCode = option.code);
        widget.onLanguageSelected(option.code);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = BottomSheetHeader(
      title: context.l10n.translation_messageTranslation,
    );
    final switchTile = _buildSwitchTile(context);
    final searchField = _buildSearchField(context);
    final itemCount = _filtered.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final narrow = constraints.maxWidth < 360;
        final minPinnedHeight = scaler.scale(narrow ? 360 : 300);

        if (constraints.maxHeight < scaler.scale(150)) {
          return CustomScrollView(
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: header),
              SliverToBoxAdapter(child: switchTile),
              SliverToBoxAdapter(child: searchField),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 12),
                sliver: SliverList.list(
                  children: [
                    for (var i = 0; i < itemCount; i++)
                      _buildLanguageTile(context, i),
                  ],
                ),
              ),
            ],
          );
        }

        if (constraints.maxHeight < minPinnedHeight) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Flexible(
                child: CustomScrollView(
                  shrinkWrap: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(child: switchTile),
                    SliverToBoxAdapter(child: searchField),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 12),
                      sliver: SliverList.list(
                        children: [
                          for (var i = 0; i < itemCount; i++)
                            _buildLanguageTile(context, i),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            switchTile,
            searchField,
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: itemCount,
                itemBuilder: _buildLanguageTile,
              ),
            ),
          ],
        );
      },
    );
  }
}

String _languageLabel(String? languageCode, String systemLanguageFallback) {
  if (languageCode == null) {
    return systemLanguageFallback;
  }
  for (final option in supportedTranslationLanguages) {
    if (option.code == languageCode) {
      return option.label;
    }
  }
  return languageCode.toUpperCase();
}
