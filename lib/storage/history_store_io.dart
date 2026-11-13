import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../utils/app_logger.dart';
import 'history_store.dart';
import 'prefs_manager.dart';

Future<HistoryStore> createHistoryStore() async {
  final directory = await getApplicationSupportDirectory();
  if (Platform.isLinux || Platform.isWindows) ffi.sqfliteFfiInit();
  final store = await SqliteHistoryStore.open(
    '${directory.path}${Platform.pathSeparator}history_v1.db',
    factory: Platform.isLinux || Platform.isWindows
        ? ffi.databaseFactoryFfi
        : sqlite.databaseFactory,
  );
  // The database is usable even when an import step fails: reads fall back
  // to preferences for keys it does not hold, and the step repeats next launch.
  try {
    final prefs = PrefsManager.instance;
    if (prefs.getBool(HistoryStore.fallbackRunKey) == true) {
      await store.adoptFallbackHistories();
      await prefs.remove(HistoryStore.fallbackRunKey);
    }
    await store.migratePreferences();
  } catch (error) {
    // The app logger is not set up this early.
    debugPrint('History import incomplete: $error');
  }
  return store;
}

class SqliteHistoryStore extends HistoryStore {
  SqliteHistoryStore._(this.database);

  static const schemaVersion = 1;
  final sqlite.Database database;

  static Future<SqliteHistoryStore> open(
    String path, {
    required sqlite.DatabaseFactory factory,
  }) async {
    final database = await factory.openDatabase(
      path,
      options: sqlite.OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE history_keys (key TEXT PRIMARY KEY, value TEXT)',
          );
          await db.execute(
            'CREATE TABLE history_entries ('
            'key TEXT NOT NULL REFERENCES history_keys(key) ON DELETE CASCADE, '
            'position INTEGER NOT NULL, value TEXT NOT NULL, '
            'PRIMARY KEY (key, position))',
          );
          await db.execute(
            'CREATE TABLE history_metadata (key TEXT PRIMARY KEY, value INTEGER NOT NULL)',
          );
        },
      ),
    );
    return SqliteHistoryStore._(database);
  }

  Future<void> migratePreferences() async {
    final versions = await database.query(
      'history_metadata',
      where: 'key = ?',
      whereArgs: ['preferences_import_version'],
    );
    final version = versions.isEmpty ? null : versions.first['value'] as int;
    if (version != null && version >= schemaVersion) return;

    final prefs = PrefsManager.instance;
    final imported = <String>{};
    for (final key in prefs.getKeys().where(HistoryStore.isHistoryKey)) {
      final value = prefs.get(key);
      if (value is! String || value.isEmpty) continue;
      try {
        final decoded = jsonDecode(value);
        if (HistoryStore.isSequenceKey(key)
            ? decoded is! List
            : decoded is! Map) {
          continue;
        }
      } on FormatException {
        appLogger.warn('Leaving unreadable history $key in preferences');
        continue;
      }
      // Rows from an interrupted earlier import may have been saved to since.
      if ((await _header(key)).isEmpty) await setString(key, value);
      imported.add(key);
    }
    if (imported.isNotEmpty) {
      final removed = await SharedPreferencesStorePlatform.instance
          .clearWithParameters(
            ClearParameters(
              filter: PreferencesFilter(
                prefix: 'flutter.',
                allowList: imported.map((key) => 'flutter.$key').toSet(),
              ),
            ),
          );
      if (!removed) throw StateError('Could not finish history migration');
      await prefs.reload();
    }
    await database.insert('history_metadata', {
      'key': 'preferences_import_version',
      'value': schemaVersion,
    }, conflictAlgorithm: sqlite.ConflictAlgorithm.replace);
  }

  /// Merges histories that a run without the database saved to preferences.
  /// That run could not see the database rows, so its message lists hold
  /// what it saved itself and are appended; a message it rewrote replaces the
  /// stored copy. Route histories already in the database are kept.
  Future<void> adoptFallbackHistories() async {
    final prefs = PrefsManager.instance;
    final keys = prefs.getKeys().where(HistoryStore.isHistoryKey).toList();
    for (final key in keys) {
      final value = prefs.get(key);
      if (value is! String || value.isEmpty) continue;
      final sequence = HistoryStore.isSequenceKey(key);
      final Object? decoded;
      try {
        decoded = jsonDecode(value);
      } on FormatException {
        continue;
      }
      if (sequence ? decoded is! List : decoded is! Map) continue;
      if ((await _header(key)).isEmpty) {
        await setString(key, value);
      } else if (sequence) {
        final merged = await readEntries(key);
        final positions = {
          for (var i = 0; i < merged.length; i++) _entryId(merged[i]): i,
        };
        for (final entry in (decoded as List).map(jsonEncode)) {
          final id = _entryId(entry);
          final position = positions[id];
          if (position == null) {
            positions[id] = merged.length;
            merged.add(entry);
          } else {
            merged[position] = entry;
          }
        }
        await replaceTail(key, 0, merged);
      }
      if (!await prefs.remove(key)) {
        throw StateError('Could not finish merging fallback histories');
      }
    }
  }

  static String _entryId(String entry) {
    final decoded = jsonDecode(entry);
    final id = decoded is Map ? decoded['messageId'] : null;
    return id is String && id.isNotEmpty ? 'id:$id' : entry;
  }

  Future<List<Map<String, Object?>>> _header(String key) => database.query(
    'history_keys',
    columns: ['value'],
    where: 'key = ?',
    whereArgs: [key],
  );

  @override
  Future<String?> getString(String key) async {
    final header = await _header(key);
    if (header.isEmpty) return PrefsManager.instance.getString(key);
    final scalar = header.first['value'];
    if (scalar is String) return scalar;
    return '[${(await readEntries(key)).join(',')}]';
  }

  @override
  Future<bool> setString(String key, String value) async {
    final entries = HistoryStore.isSequenceKey(key)
        ? (jsonDecode(value) as List).map(jsonEncode).toList()
        : null;
    await database.transaction((txn) async {
      await txn.insert('history_keys', {
        'key': key,
        'value': entries == null ? value : null,
      }, conflictAlgorithm: sqlite.ConflictAlgorithm.replace);
      if (entries != null) {
        final batch = txn.batch();
        for (var index = 0; index < entries.length; index++) {
          batch.insert('history_entries', {
            'key': key,
            'position': index,
            'value': entries[index],
          });
        }
        await batch.commit(noResult: true);
      }
    });
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    await database.delete('history_keys', where: 'key = ?', whereArgs: [key]);
    final prefs = PrefsManager.instance;
    return !prefs.containsKey(key) || await prefs.remove(key);
  }

  @override
  Future<Set<String>> getKeys() async => {
    for (final row in await database.query('history_keys', columns: ['key']))
      row['key'] as String,
    ...PrefsManager.instance.getKeys().where(HistoryStore.isHistoryKey),
  };

  @override
  Future<int> entryCount(String key) async {
    if ((await _header(key)).isEmpty) {
      return PreferencesHistoryStore().entryCount(key);
    }
    return sqlite.Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT COUNT(*) FROM history_entries WHERE key = ?',
            [key],
          ),
        ) ??
        0;
  }

  @override
  Future<List<String>> readEntries(
    String key, {
    int offset = 0,
    int? limit,
  }) async {
    RangeError.checkNotNegative(offset, 'offset');
    if (limit != null) RangeError.checkNotNegative(limit, 'limit');
    if ((await _header(key)).isEmpty) {
      return PreferencesHistoryStore().readEntries(
        key,
        offset: offset,
        limit: limit,
      );
    }
    final rows = await database.rawQuery(
      'SELECT value FROM history_entries WHERE key = ? ORDER BY position '
      'LIMIT ? OFFSET ?',
      [key, limit ?? -1, offset],
    );
    return [for (final row in rows) row['value'] as String];
  }

  @override
  Future<int> replaceTail(
    String key,
    int preservedCount,
    List<String> entries, {
    int maxEntries = 1000,
  }) async {
    RangeError.checkNotNegative(preservedCount, 'preservedCount');
    RangeError.checkNotNegative(maxEntries, 'maxEntries');
    // A readable preference left by the import is adopted first. An
    // unreadable one stays in preferences, where a save never erases it; the
    // database rows written below are what later reads return.
    if ((await _header(key)).isEmpty) {
      final legacy = PrefsManager.instance.getString(key);
      if (legacy != null && legacy.isNotEmpty) {
        if (_isJsonList(legacy)) {
          await setString(key, legacy);
        } else {
          appLogger.warn('Saving $key beside its unreadable preference');
        }
      }
    }
    return database.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO history_keys (key, value) VALUES (?, NULL)',
        [key],
      );
      final prefix = preservedCount == 0
          ? <Map<String, Object?>>[]
          : await txn.rawQuery(
              'SELECT position FROM history_entries WHERE key = ? '
              'ORDER BY position LIMIT 1 OFFSET ?',
              [key, preservedCount - 1],
            );
      final count =
          sqlite.Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM history_entries WHERE key = ?',
              [key],
            ),
          ) ??
          0;
      final preserved = preservedCount.clamp(0, count);
      final lastPosition = prefix.isNotEmpty
          ? prefix.first['position'] as int
          : preserved == 0
          ? -1
          : sqlite.Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT MAX(position) FROM history_entries WHERE key = ?',
                [key],
              ),
            )!;
      await txn.delete(
        'history_entries',
        where: 'key = ? AND position > ?',
        whereArgs: [key, lastPosition],
      );
      final batch = txn.batch();
      for (var index = 0; index < entries.length; index++) {
        batch.insert('history_entries', {
          'key': key,
          'position': lastPosition + index + 1,
          'value': entries[index],
        });
      }
      await batch.commit(noResult: true);
      final overflow = (preserved + entries.length - maxEntries).clamp(
        0,
        preserved + entries.length,
      );
      if (overflow > 0) {
        await txn.rawDelete(
          'DELETE FROM history_entries WHERE key = ? AND position IN '
          '(SELECT position FROM history_entries WHERE key = ? '
          'ORDER BY position LIMIT ?)',
          [key, key, overflow],
        );
      }
      return (preserved - overflow).clamp(0, preserved);
    });
  }

  static bool _isJsonList(String value) {
    try {
      return jsonDecode(value) is List;
    } on FormatException {
      return false;
    }
  }

  @override
  Future<void> close() => database.close();
}
