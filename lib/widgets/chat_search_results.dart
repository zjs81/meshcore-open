import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/message_search.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import 'chat_day_separator.dart';
import 'empty_state.dart';

/// Results list for "search in this chat". Loads the full history through
/// [loadEntries] (once, cached) and re-filters on each debounced [query].
class ChatSearchResults extends StatefulWidget {
  final String query;
  final Future<List<ChatSearchEntry>> Function() loadEntries;
  final double textScale;

  /// Tapping a result: the chat closes search and jumps to the message.
  /// Long-pressing one copies its text.
  final ValueChanged<ChatSearchEntry>? onSelect;

  const ChatSearchResults({
    super.key,
    required this.query,
    required this.loadEntries,
    this.textScale = 1.0,
    this.onSelect,
  });

  @override
  State<ChatSearchResults> createState() => _ChatSearchResultsState();
}

class _ChatSearchResultsState extends State<ChatSearchResults> {
  static const _debounce = Duration(milliseconds: 250);

  Timer? _timer;
  List<ChatSearchEntry>? _all;
  List<ChatSearchEntry> _results = const [];
  String _activeQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run(widget.query);
  }

  @override
  void didUpdateWidget(ChatSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _timer?.cancel();
      _timer = Timer(_debounce, () => _run(widget.query));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(String query) async {
    setState(() => _loading = true);
    List<ChatSearchEntry> all;
    try {
      all = _all ??= await widget.loadEntries();
    } catch (_) {
      all = const [];
    }
    if (!mounted || query != widget.query) return;
    setState(() {
      _results = searchEntries(all, query);
      _activeQuery = query;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = widget.textScale;
    final needle = normalizeSearchQuery(_activeQuery);
    final showEmpty = !_loading && _results.isEmpty;
    return Column(
      children: [
        SizedBox(
          height: 3,
          child: _loading ? const LinearProgressIndicator() : null,
        ),
        if (!_loading && _results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.chatSearch_resultCount(_results.length),
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        Expanded(
          child: showEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: context.l10n.chatSearch_noResults,
                  subtitle: context.l10n.chatSearch_noResultsHint,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) => _ResultRow(
                    entry: _results[index],
                    needle: needle,
                    textScale: scale,
                    onTap: widget.onSelect == null
                        ? null
                        : () => widget.onSelect!(_results[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ChatSearchEntry entry;
  final String needle;
  final double textScale;
  final VoidCallback? onTap;

  const _ResultRow({
    required this.entry,
    required this.needle,
    required this.textScale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = textScale;
    final translated = entry.translatedText;
    final body = translated != null && translated.isNotEmpty
        ? translated
        : entry.text;
    // Show whichever text actually contains the query.
    final shown = body.toLowerCase().contains(needle) ? body : entry.text;
    return InkWell(
      onTap: onTap,
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: shown));
        if (!context.mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_messageCopied),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _highlight(
                    entry.sender,
                    entry.matchSender ? needle : '',
                    TextStyle(
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                    scheme,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatChatDayLabel(context, entry.time)}, '
                  '${formatChatTime(context, entry.time)}',
                  style: TextStyle(
                    fontSize: 12 * s,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _highlight(
              shown,
              needle,
              TextStyle(fontSize: 16 * s, color: scheme.onSurface),
              scheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlight(
    String text,
    String needle,
    TextStyle style,
    ColorScheme scheme,
  ) {
    if (needle.isEmpty) return Text(text, style: style);
    final lower = text.toLowerCase();
    // Case folding can change length for exotic characters; skip highlighting
    // rather than risk misaligned ranges.
    if (lower.length != text.length) return Text(text, style: style);
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final at = lower.indexOf(needle, start);
      if (at < 0) break;
      if (at > start) spans.add(TextSpan(text: text.substring(start, at)));
      spans.add(
        TextSpan(
          text: text.substring(at, at + needle.length),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            backgroundColor: scheme.primaryContainer,
            color: scheme.onPrimaryContainer,
          ),
        ),
      );
      start = at + needle.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
