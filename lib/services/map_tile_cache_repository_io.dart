import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

CacheInfoRepository createMapTileCacheRepository(String cacheKey) {
  if (!Platform.isLinux && !Platform.isWindows) {
    return CacheObjectProvider(databaseName: cacheKey);
  }
  sqfliteFfiInit();
  return SqliteMapTileCacheRepository(databaseName: cacheKey);
}

/// Tile metadata stays in SQLite; only queried rows become Dart objects.
class SqliteMapTileCacheRepository implements CacheInfoRepository {
  SqliteMapTileCacheRepository({
    required this.databaseName,
    Future<Directory> Function()? directory,
    DatabaseFactory? factory,
  }) : _directory = directory ?? getApplicationSupportDirectory,
       _factory = factory ?? databaseFactoryFfi;

  static const int schemaVersion = 1;
  static const int legacyImportVersion = 1;
  static const String _table = 'cacheObject';
  static const String _migrationTable = 'cacheMigration';
  static const String _legacyMigration = 'legacyJson';
  static const String _unreadableSuffix = '.unreadable';

  final String databaseName;
  final Future<Directory> Function() _directory;
  final DatabaseFactory _factory;
  Future<Directory>? _resolvedDirectory;
  Future<Database>? _opening;
  int _connections = 0;

  Future<Directory> _baseDirectory() => _resolvedDirectory ??= _directory();

  Future<String> _databasePath() async =>
      '${(await _baseDirectory()).path}${Platform.pathSeparator}$databaseName.db';

  Future<File> _legacyFile() async => File(
    '${(await _baseDirectory()).path}${Platform.pathSeparator}$databaseName.json',
  );

  Future<Database> _database() async {
    final pending = _opening;
    if (pending != null) return pending;
    final started = _openDatabase();
    _opening = started;
    try {
      return await started;
    } catch (_) {
      if (identical(_opening, started)) _opening = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final path = await _databasePath();
    await File(path).parent.create(recursive: true);
    final db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              _id INTEGER PRIMARY KEY,
              url TEXT NOT NULL,
              key TEXT NOT NULL UNIQUE,
              relativePath TEXT NOT NULL,
              eTag TEXT,
              validTill INTEGER NOT NULL,
              touched INTEGER NOT NULL,
              length INTEGER
            )
          ''');
          await db.execute('CREATE INDEX cacheTouched ON $_table (touched)');
          await db.execute('''
            CREATE TABLE $_migrationTable (
              name TEXT PRIMARY KEY,
              version INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    try {
      await _importLegacyJson(db);
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<void> _importLegacyJson(Database db) async {
    final versions = await db.query(
      _migrationTable,
      where: 'name = ?',
      whereArgs: [_legacyMigration],
    );
    final version = versions.isEmpty ? 0 : versions.single['version'] as int;
    if (version > legacyImportVersion) return;
    final legacy = await _legacyFile();
    var unreadable = false;
    if (version < legacyImportVersion) {
      final List<Map<String, Object?>> records;
      (records, unreadable) = await compute(_readLegacyRecords, legacy.path);
      await db.transaction((transaction) async {
        final batch = transaction.batch();
        for (final record in records) {
          batch.insert(
            _table,
            record,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        batch.insert(_migrationTable, {
          'name': _legacyMigration,
          'version': legacyImportVersion,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await batch.commit(noResult: true);
      });
    }
    // A committed version marker makes a crash before cleanup safe to retry.
    try {
      if (unreadable && await legacy.exists()) {
        // Kept for inspection rather than deleted; it is never imported again.
        debugPrint('Map metadata migration skipped unreadable records');
        await legacy.rename('${legacy.path}$_unreadableSuffix');
      }
      for (final file in [legacy, File('${legacy.path}.tmp')]) {
        if (await file.exists()) await file.delete();
      }
    } on FileSystemException catch (error) {
      debugPrint('Map metadata migration cleanup: $error');
    }
  }

  @override
  Future<bool> open() async {
    _connections++;
    try {
      await _database();
      return true;
    } catch (_) {
      _connections--;
      rethrow;
    }
  }

  @override
  Future<bool> close() async {
    if (_connections == 0 || --_connections > 0) return false;
    final pending = _opening;
    _opening = null;
    if (pending != null) await (await pending).close();
    return true;
  }

  @override
  Future<bool> exists() async => File(await _databasePath()).exists();

  @override
  Future<void> deleteDataFile() async {
    if (_connections != 0) {
      throw StateError('Close map metadata connections before deleting it.');
    }
    await _factory.deleteDatabase(await _databasePath());
    final legacy = await _legacyFile();
    for (final file in [
      legacy,
      File('${legacy.path}.tmp'),
      File('${legacy.path}$_unreadableSuffix'),
    ]) {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<CacheObject?> get(String key) async {
    final rows = await (await _database()).query(
      _table,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : CacheObject.fromMap(rows.single);
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    if (cacheObject.id != null) {
      throw ArgumentError('Inserted cache objects must not have an ID.');
    }
    final map = cacheObject.toMap(setTouchedToNow: setTouchedToNow);
    final id = await (await _database()).insert(_table, map);
    return CacheObject.fromMap({...map, CacheObject.columnId: id});
  }

  @override
  Future<int> update(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    if (cacheObject.id == null) {
      throw ArgumentError('Updated cache objects must have an ID.');
    }
    return (await _database()).update(
      _table,
      cacheObject.toMap(setTouchedToNow: setTouchedToNow),
      where: '_id = ?',
      whereArgs: [cacheObject.id],
    );
  }

  @override
  Future<dynamic> updateOrInsert(CacheObject cacheObject) =>
      cacheObject.id == null ? insert(cacheObject) : update(cacheObject);

  @override
  Future<int> delete(int id) async =>
      (await _database()).delete(_table, where: '_id = ?', whereArgs: [id]);

  @override
  Future<int> deleteAll(Iterable<int> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return 0;
    final db = await _database();
    return db.transaction((transaction) async {
      var deleted = 0;
      for (var start = 0; start < unique.length; start += 500) {
        final chunk = unique.skip(start).take(500).toList();
        deleted += await transaction.delete(
          _table,
          where: '_id IN (${List.filled(chunk.length, '?').join(',')})',
          whereArgs: chunk,
        );
      }
      return deleted;
    });
  }

  @override
  Future<List<CacheObject>> getAllObjects() async =>
      CacheObject.fromMapList(await (await _database()).query(_table));

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async =>
      CacheObject.fromMapList(
        await (await _database()).query(
          _table,
          where: 'touched < ?',
          whereArgs: [
            DateTime.now()
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch,
          ],
          orderBy: 'touched DESC, _id DESC',
          offset: capacity,
          limit: 100,
        ),
      );

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async =>
      CacheObject.fromMapList(
        await (await _database()).query(
          _table,
          where: 'touched < ?',
          whereArgs: [DateTime.now().subtract(maxAge).millisecondsSinceEpoch],
          orderBy: 'touched ASC, _id ASC',
          limit: 100,
        ),
      );
}

/// Returns the importable records and whether any part of the file was
/// unreadable. A broken file must not keep the tile cache from opening.
(List<Map<String, Object?>>, bool) _readLegacyRecords(String path) {
  final file = File(path);
  if (!file.existsSync()) return ([], false);
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on Exception {
    return ([], true);
  }
  if (decoded is! List) return ([], true);
  final records = <Map<String, Object?>>[];
  var unreadable = false;
  for (final value in decoded) {
    try {
      records.add(
        CacheObject.fromMap(
          (value as Map).cast<String, dynamic>(),
        ).toMap(setTouchedToNow: false)..remove(CacheObject.columnId),
      );
    } catch (_) {
      unreadable = true;
    }
  }
  return (records, unreadable);
}
