import 'dart:async';
import 'dart:convert';

import '../utils/app_logger.dart';
import 'history_store.dart';

typedef HistoryPage<T> = ({List<T> messages, int start, int end, int total});

/// Archive bookkeeping, ordered writes and paging shared by the direct and
/// channel message stores. Entries are JSON-encoded messages; the stored
/// prefix older than the in-memory window stays in the [HistoryStore].
class HistoryArchive {
  HistoryArchive({required this.mergeKey, required this.maxEntries});

  /// Identifies a stored entry so an unreconciled save can drop overlaps.
  final String Function(Map<String, dynamic> json) mergeKey;
  final int maxEntries;

  final Expando<Map<String, _ArchiveState>> _archives = Expando();
  final Expando<Map<String, Future<void>>> _writes = Expando();

  _ArchiveState _stateFor(HistoryStore store, String key) =>
      (_archives[store] ??= {}).putIfAbsent(key, () => _ArchiveState());

  Future<void> _serialize(
    HistoryStore store,
    String key,
    Future<void> Function() operation,
  ) {
    final writes = _writes[store] ??= {};
    final previous = writes[key] ?? Future<void>.value();
    final result = previous.then((_) => operation());
    final completion = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    writes[key] = completion;
    unawaited(
      completion.whenComplete(() {
        if (identical(writes[key], completion)) writes.remove(key);
      }),
    );
    return result;
  }

  /// Saves the [visible] window after the archived prefix. [readStored]
  /// supplies the stored JSON when the prefix is not reconciled yet; it
  /// defaults to the value under [key].
  Future<void> save(
    String key,
    List<String> visible, {
    Future<String?> Function(HistoryStore store)? readStored,
  }) {
    final store = HistoryStore.instance;
    final state = _stateFor(store, key);
    final pendingBefore = state.nextId;
    return _serialize(store, key, () async {
      final pending = state.pending
          .where((entry) => entry.$1 < pendingBefore)
          .toList();
      final tail = [...pending.map((entry) => entry.$2), ...visible];
      final room = (maxEntries - visible.length).clamp(0, maxEntries);
      var preserved = state.persistedCount;
      if (preserved == null) {
        final raw = await (readStored?.call(store) ?? store.getString(key));
        final prefix = _unreconciledPrefix(key, raw, tail);
        await store.replaceTail(key, 0, [
          ...prefix,
          ...tail,
        ], maxEntries: maxEntries);
        preserved = (prefix.length + pending.length).clamp(0, room);
      } else {
        final remaining = await store.replaceTail(
          key,
          preserved,
          tail,
          maxEntries: maxEntries,
        );
        preserved = remaining + pending.length.clamp(0, room);
      }
      state.persistedCount = preserved;
      state.pending.removeWhere((entry) => entry.$1 < pendingBefore);
    });
  }

  /// Stored entries not repeated in [tail]. Unreadable stored history counts
  /// as empty, so it cannot block every later save.
  List<String> _unreconciledPrefix(String key, String? raw, List<String> tail) {
    if (raw == null || raw.isEmpty) return [];
    final Object? stored;
    try {
      stored = jsonDecode(raw);
    } on FormatException catch (error) {
      appLogger.warn('Saving over unreadable history $key: $error');
      return [];
    }
    if (stored is! List) {
      appLogger.warn('Saving over history $key that is not a list');
      return [];
    }
    final overlaps = <String, int>{};
    for (final entry in tail) {
      final id = mergeKey(jsonDecode(entry) as Map<String, dynamic>);
      overlaps[id] = (overlaps[id] ?? 0) + 1;
    }
    final kept = <String>[];
    for (final entry in stored.reversed) {
      final id = entry is Map<String, dynamic> ? mergeKey(entry) : null;
      final remaining = id == null ? 0 : overlaps[id] ?? 0;
      if (remaining > 0) {
        overlaps[id!] = remaining - 1;
      } else {
        kept.add(jsonEncode(entry));
      }
    }
    return kept.reversed.toList();
  }

  void setArchivedCount(String key, int count) {
    RangeError.checkNotNegative(count, 'count');
    (_archives[HistoryStore.instance] ??= {})[key] = _ArchiveState(count);
  }

  /// Only entries trimmed since the last successful save need buffering.
  void archive(String key, Iterable<String> entries) {
    final state = _stateFor(HistoryStore.instance, key);
    for (final entry in entries) {
      state.pending.add((state.nextId++, entry));
    }
  }

  int? archivedCount(String key) {
    final state = _archives[HistoryStore.instance]?[key];
    final count = state?.persistedCount;
    return count == null ? null : count + state!.pending.length;
  }

  void forget([String? key]) {
    final states = _archives[HistoryStore.instance];
    if (key == null) {
      states?.clear();
    } else {
      states?.remove(key);
    }
  }

  Future<void> clear(HistoryStore store, String key) {
    final state = _ArchiveState(0);
    (_archives[store] ??= {})[key] = state;
    return _serialize(store, key, () async {
      if (!await store.remove(key)) {
        state.persistedCount = null;
        throw StateError('Could not clear message history');
      }
    });
  }

  /// Reads a page backwards using physical stored-row offsets, so entries
  /// [decode] skips do not make earlier valid history unreachable.
  Future<HistoryPage<T>> readPage<T>(
    String key,
    int total,
    List<T> Function(List<String> entries) decode, {
    int? before,
    required int limit,
  }) async {
    final store = HistoryStore.instance;
    final end = (before ?? total).clamp(0, total);
    var start = end;
    var messages = <T>[];
    while (start > 0 && messages.length < limit) {
      final batchSize = (limit - messages.length).clamp(0, start);
      final next = start - batchSize;
      final entries = await store.readEntries(
        key,
        offset: next,
        limit: batchSize,
      );
      messages = [...decode(entries), ...messages];
      start = next;
    }
    return (messages: messages, start: start, end: end, total: total);
  }
}

class _ArchiveState {
  _ArchiveState([this.persistedCount]);

  int? persistedCount;
  int nextId = 0;
  final List<(int, String)> pending = [];
}
