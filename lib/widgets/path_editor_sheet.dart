import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../connector/meshcore_protocol.dart';
import '../helpers/path_helper.dart';
import '../l10n/contact_localization.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../theme/mesh_theme.dart';
import '../utils/contact_search.dart';
import 'mesh_ui.dart';

class PathEditorSheet extends StatefulWidget {
  final List<Contact> availableContacts;
  final List<int> initialPath;
  final int pathHashByteWidth;

  const PathEditorSheet({
    super.key,
    required this.availableContacts,
    this.initialPath = const [],
    this.pathHashByteWidth = pathHashSize,
  });

  static Future<Uint8List?> show(
    BuildContext context, {
    required List<Contact> availableContacts,
    List<int> initialPath = const [],
    int pathHashByteWidth = pathHashSize,
  }) {
    // Same container as the other sheets: safe area on the top and sides,
    // keyboard inset on the bottom, and the header at the top of the sheet.
    // A fraction inside an expanding align left an empty band above the handle.
    return showMeshSheet<Uint8List>(
      context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            return SizedBox(
              height: height,
              child: PathEditorSheet(
                availableContacts: availableContacts,
                initialPath: initialPath,
                pathHashByteWidth: pathHashByteWidth,
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<PathEditorSheet> createState() => _PathEditorSheetState();
}

class _Hop {
  final int id;
  final Uint8List bytes;

  const _Hop(this.id, this.bytes);
}

class _PathEditorSheetState extends State<PathEditorSheet> {
  static const int _maxHops = 64;

  final List<_Hop> _hops = [];
  final _hexController = TextEditingController();
  final _hexFocus = FocusNode();
  final _searchFocus = FocusNode();
  final _hopScroll = ScrollController();
  String? _hexError;
  bool _syncingHex = false;
  String _search = '';
  int _nextHopId = 0;
  int? _highlightedHopId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    for (final hop in PathHelper.splitPathBytes(
      widget.initialPath,
      widget.pathHashByteWidth,
    )) {
      _hops.add(_Hop(_nextHopId++, hop));
    }
    _syncHexFromHops();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _hopScroll.dispose();
    _hexFocus.dispose();
    _searchFocus.dispose();
    _hexController.dispose();
    super.dispose();
  }

  int get _hashChars {
    final width = widget.pathHashByteWidth.clamp(1, pubKeySize).toInt();
    return width * 2;
  }

  List<Contact> get _repeaters {
    final query = _search.trim();
    return widget.availableContacts
        .where((c) => c.type == advTypeRepeater || c.type == advTypeRoom)
        .where((c) => c.publicKey.isNotEmpty)
        .where((c) => rankContactQuery(c, query) != null)
        .toList()
      ..sort((a, b) => compareContactQueryRank(a, b, query));
  }

  void _syncHexFromHops() {
    _syncingHex = true;
    _hexController.text = _hops
        .map((h) => PathHelper.formatHopHex(h.bytes))
        .join(',');
    _syncingHex = false;
    _hexError = null;
  }

  void _onHexChanged(String text) {
    if (_syncingHex) return;
    final l10n = context.l10n;
    final tokens = text
        .split(RegExp(r'[,\s]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final width = widget.pathHashByteWidth.clamp(1, pubKeySize).toInt();
    final expectedChars = width * 2;
    final invalid = tokens
        .where(
          (t) =>
              t.length != expectedChars || int.tryParse(t, radix: 16) == null,
        )
        .toList();
    setState(() {
      if (invalid.isNotEmpty) {
        _hexError = l10n.pathEditor_invalidTokens(invalid.join(', '));
        return;
      }
      if (tokens.length > _maxHops) {
        _hexError = l10n.pathEditor_tooManyHops;
        return;
      }
      _hexError = null;
      final previous = _hops.length;
      _hops
        ..clear()
        ..addAll(
          tokens.map((t) {
            final bytes = <int>[];
            for (var i = 0; i < t.length; i += 2) {
              bytes.add(int.parse(t.substring(i, i + 2), radix: 16));
            }
            return _Hop(_nextHopId++, Uint8List.fromList(bytes));
          }),
        );
      if (_hops.length > previous && _hops.isNotEmpty) {
        _markHopAdded(_hops.last.id);
      }
    });
  }

  void _addHop(Contact contact) {
    if (_hops.length >= _maxHops) return;
    final width = widget.pathHashByteWidth
        .clamp(1, contact.publicKey.length)
        .toInt();
    HapticFeedback.selectionClick();
    setState(() {
      final hop = _Hop(
        _nextHopId++,
        Uint8List.fromList(contact.publicKey.sublist(0, width)),
      );
      _hops.add(hop);
      _syncHexFromHops();
      _markHopAdded(hop.id);
    });
  }

  void _markHopAdded(int id) {
    _highlightedHopId = id;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        if (_highlightedHopId == id) _highlightedHopId = null;
      });
    });
    _revealLatestHop();
  }

  void _revealLatestHop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hopScroll.hasClients) return;
      _hopScroll.animateTo(
        _hopScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeHop(int index) {
    setState(() {
      _hops.removeAt(index);
      _syncHexFromHops();
    });
  }

  void _reorderHop(int oldIndex, int newIndex) {
    setState(() {
      final hop = _hops.removeAt(oldIndex);
      _hops.insert(newIndex, hop);
      _syncHexFromHops();
    });
  }

  void _save() {
    final bytes = <int>[];
    for (final hop in _hops) {
      bytes.addAll(hop.bytes);
    }
    Navigator.pop(context, Uint8List.fromList(bytes));
  }

  String _contactHopHex(Contact contact) {
    final width = widget.pathHashByteWidth
        .clamp(1, contact.publicKey.length)
        .toInt();
    return PathHelper.formatHopHex(contact.publicKey.sublist(0, width));
  }

  Widget _hopTile(BuildContext context, int index, {required bool singleLine}) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hop = _hops[index];
    final hex = PathHelper.formatHopHex(hop.bytes);
    final matches = widget.availableContacts.where((contact) {
      if (contact.publicKey.length < hop.bytes.length) return false;
      return contact.publicKey
          .sublist(0, hop.bytes.length)
          .asMap()
          .entries
          .every((entry) => entry.value == hop.bytes[entry.key]);
    }).toList();
    final name = matches.isEmpty
        ? null
        : matches.length == 1
        ? matches.first.name
        : matches.map((c) => c.name).join(' | ');
    final highlighted = hop.id == _highlightedHopId;

    final label = name ?? l10n.pathEditor_unknownHop;
    final hash = Text(hex, style: MeshTheme.mono(fontSize: 12));
    return Material(
      key: ValueKey(hop.id),
      color: highlighted ? scheme.primaryContainer : scheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: singleLine
            ? VisualDensity.compact
            : VisualDensity.standard,
        minVerticalPadding: singleLine ? 0 : 4,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primary,
          child: Text(
            '${index + 1}',
            style: TextStyle(fontSize: 12, color: scheme.onPrimary),
          ),
        ),
        title: singleLine
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  hash,
                ],
              )
            : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: singleLine ? null : hash,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.pathEditor_removeHop,
              onPressed: () => _removeHop(index),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _repeaterTile(BuildContext context, Contact contact) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isRepeater = contact.type == advTypeRepeater;
    final full = _hops.length >= _maxHops;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      enabled: !full,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isRepeater
            ? scheme.primaryContainer
            : scheme.secondaryContainer,
        child: Icon(
          isRepeater ? Icons.router : Icons.meeting_room,
          size: 18,
          color: isRepeater
              ? scheme.onPrimaryContainer
              : scheme.onSecondaryContainer,
        ),
      ),
      title: Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${contact.typeLabel(l10n)} • ${_contactHopHex(contact)}',
        style: MeshTheme.mono(fontSize: 12),
      ),
      trailing: Icon(
        Icons.add_circle_outline,
        color: full ? scheme.outline : scheme.primary,
      ),
      onTap: full ? null : () => _addHop(contact),
    );
  }

  /// Heights for the hop list, hex field, and search field inside the
  /// measured band between the title and the action buttons.
  ///
  /// An invalid hex path grows the error text. That growth comes out of the
  /// hop viewport first, keeping one row when it fits. When even one hop row,
  /// the hex field with any active error, and the search field cannot fit,
  /// [scroll] switches the middle band to a single scroll view so nothing is
  /// crushed or overflows and all controls stay reachable.
  ({double hop, double hex, double search, bool scroll}) _middleBudget(
    double space,
    bool compact,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final row = compact
        ? scaler.scale(56).clamp(56.0, 96.0)
        : scaler.scale(76).clamp(72.0, 140.0);
    final minRepeater = compact ? 56.0 : 80.0;
    final searchH = scaler.scale(compact ? 48 : 56) + 20;
    final baseHex = scaler.scale(compact ? 48 : 64) + (compact ? 16 : 44);
    final errorExtra = _hexError == null
        ? 0.0
        : scaler.scale(compact ? 56 : 52);
    final wantedHop = _hops.isEmpty
        ? math.min(scaler.scale(compact ? 64 : 80), 140.0)
        : math.min(_hops.length, compact ? 2 : 3) * row + 4;
    final wantedHex = baseHex + errorExtra;
    final minHop = _hops.isEmpty ? 0.0 : row;
    final scroll = minHop + wantedHex + searchH > space;

    var hopH = wantedHop;
    if (!scroll) {
      final targetMax = math.max(
        minHop + wantedHex + searchH,
        space - minRepeater,
      );
      final used = hopH + wantedHex + searchH;
      if (used > targetMax) {
        hopH -= math.min(used - targetMax, math.max(0.0, hopH - minHop));
      }
    }
    return (hop: hopH, hex: wantedHex, search: searchH, scroll: scroll);
  }

  Widget _hopViewport(bool compact, double height) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: height,
      child: height < 8
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(MeshRadii.md),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: _hops.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.pathEditor_noHops,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        scrollController: _hopScroll,
                        buildDefaultDragHandles: false,
                        padding: EdgeInsets.symmetric(
                          vertical: compact ? 0 : 4,
                        ),
                        itemCount: _hops.length,
                        onReorderItem: _reorderHop,
                        itemBuilder: (context, index) =>
                            _hopTile(context, index, singleLine: compact),
                      ),
              ),
            ),
    );
  }

  Widget _hexViewport(bool compact, double height) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, compact ? 6 : 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) ...[
              Text(
                l10n.pathEditor_advancedHex,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              key: const Key('path-editor-hex-field'),
              controller: _hexController,
              focusNode: _hexFocus,
              onChanged: _onHexChanged,
              textCapitalization: TextCapitalization.characters,
              style: MeshTheme.mono(fontSize: 14),
              scrollPadding: EdgeInsets.zero,
              decoration: InputDecoration(
                labelText: l10n.pathEditor_hexLabel,
                helperText: compact || _hexError != null
                    ? null
                    : l10n.pathEditor_hexHelper(_hashChars),
                helperMaxLines: 3,
                errorText: _hexError,
                errorMaxLines: compact ? 4 : 3,
                border: const OutlineInputBorder(),
                isDense: compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchViewport(bool compact, double height) {
    final l10n = context.l10n;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, compact ? 6 : 12, 16, 0),
        child: TextField(
          key: const Key('path-editor-search-field'),
          focusNode: _searchFocus,
          onChanged: (value) => setState(() => _search = value),
          scrollPadding: EdgeInsets.zero,
          decoration: InputDecoration(
            labelText: l10n.pathEditor_searchRepeaters,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: compact,
          ),
        ),
      ),
    );
  }

  Widget _repeaterViewport(List<Contact> repeaters) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (repeaters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            l10n.path_noRepeatersFound,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('path-editor-repeater-list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: repeaters.length,
      itemBuilder: (context, index) => _repeaterTile(context, repeaters[index]),
    );
  }

  List<Widget> _middleSlivers({
    required bool compact,
    required List<Contact> repeaters,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
      SliverToBoxAdapter(child: _scrollHopBlock(compact)),
      SliverToBoxAdapter(child: _scrollHexBlock(compact)),
      SliverToBoxAdapter(child: _scrollSearchBlock(compact)),
      if (repeaters.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l10n.path_noRepeatersFound,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverList.builder(
            key: const Key('path-editor-repeater-list'),
            itemCount: repeaters.length,
            itemBuilder: (context, index) =>
                _repeaterTile(context, repeaters[index]),
          ),
        ),
    ];
  }

  /// One scrollable for the hop list, hex field, search field, and repeaters.
  ///
  /// The blocks are intrinsic height with no nested scrolling, so a drag
  /// anywhere in the band moves the search field and the repeater list into
  /// view. The pinned layout keeps its own viewports.
  Widget _scrollingMiddle({
    required bool compact,
    required List<Contact> repeaters,
  }) {
    return CustomScrollView(
      key: const Key('path-editor-scroll-fallback'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: _middleSlivers(compact: compact, repeaters: repeaters),
    );
  }

  Widget _scrollHopBlock(bool compact) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MeshRadii.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: _hops.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.pathEditor_noHops,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : ReorderableListView.builder(
                scrollController: _hopScroll,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: EdgeInsets.symmetric(vertical: compact ? 0 : 4),
                itemCount: _hops.length,
                onReorderItem: _reorderHop,
                itemBuilder: (context, index) =>
                    _hopTile(context, index, singleLine: compact),
              ),
      ),
    );
  }

  Widget _scrollHexBlock(bool compact) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 6 : 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Text(
              l10n.pathEditor_advancedHex,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('path-editor-hex-field'),
            controller: _hexController,
            focusNode: _hexFocus,
            onChanged: _onHexChanged,
            textCapitalization: TextCapitalization.characters,
            style: MeshTheme.mono(fontSize: 14),
            scrollPadding: EdgeInsets.zero,
            decoration: InputDecoration(
              labelText: l10n.pathEditor_hexLabel,
              helperText: compact || _hexError != null
                  ? null
                  : l10n.pathEditor_hexHelper(_hashChars),
              helperMaxLines: 3,
              errorText: _hexError,
              errorMaxLines: compact ? 4 : 3,
              border: const OutlineInputBorder(),
              isDense: compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollSearchBlock(bool compact) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 6 : 12, 16, 0),
      child: TextField(
        key: const Key('path-editor-search-field'),
        focusNode: _searchFocus,
        onChanged: (value) => setState(() => _search = value),
        scrollPadding: EdgeInsets.zero,
        decoration: InputDecoration(
          labelText: l10n.pathEditor_searchRepeaters,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: compact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repeaters = _repeaters;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 640.0;
        // Phone sheets and a keyboard-shrunk window use the shorter hop rows
        // so the action buttons stay below the repeater list.
        final compact = maxHeight < 680;
        final scaler = MediaQuery.textScalerOf(context);
        final header = Semantics(
          liveRegion: true,
          child: BottomSheetHeader(
            title: l10n.pathEditor_title,
            subtitle: l10n.pathEditor_hopCounter(_hops.length),
          ),
        );
        final actions = SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              compact ? 4 : 8,
              16,
              compact ? 4 : 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.common_cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _hexError != null ? null : _save,
                    child: Text(l10n.pathEditor_usePath),
                  ),
                ),
              ],
            ),
          ),
        );

        // When scaled header and action buttons leave less than one row for
        // the middle band, scroll the whole sheet so nothing clips or crowds
        // the viewport.
        if (maxHeight < scaler.scale(150) + 28) {
          return CustomScrollView(
            key: const Key('path-editor-scroll-fallback'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: header),
              ..._middleSlivers(compact: compact, repeaters: repeaters),
              SliverToBoxAdapter(child: actions),
            ],
          );
        }

        return Column(
          children: [
            header,
            Expanded(
              child: LayoutBuilder(
                builder: (context, inner) {
                  final budget = _middleBudget(inner.maxHeight, compact);
                  if (budget.scroll) {
                    return _scrollingMiddle(
                      compact: compact,
                      repeaters: repeaters,
                    );
                  }
                  return Column(
                    children: [
                      _hopViewport(compact, budget.hop),
                      _hexViewport(compact, budget.hex),
                      _searchViewport(compact, budget.search),
                      Expanded(child: _repeaterViewport(repeaters)),
                    ],
                  );
                },
              ),
            ),
            actions,
          ],
        );
      },
    );
  }
}
