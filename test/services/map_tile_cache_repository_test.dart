import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/map_tile_cache_repository_io.dart';
import 'package:meshcore_open/services/map_tile_cache_repository_stub.dart'
    as web;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late SqliteMapTileCacheRepository repository;
  final factory = databaseFactoryFfiNoIsolate;

  SqliteMapTileCacheRepository createRepository() =>
      SqliteMapTileCacheRepository(
        databaseName: 'map_tile_cache',
        directory: () async => directory,
        factory: factory,
      );

  CacheObject tile(String key, {int daysOld = 0, int? id}) => CacheObject(
    'https://tile.openstreetmap.org/$key.png',
    key: key,
    id: id,
    relativePath: '$key.png',
    validTill: DateTime(2030),
    touched: DateTime.now().subtract(Duration(days: daysOld)),
    length: 123,
    eTag: 'etag-$key',
  );

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('meshcore-map-metadata-');
    repository = createRepository();
  });
  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('desktop selects SQLite and web keeps its platform default', () {
    expect(
      createMapTileCacheRepository('map_tile_cache'),
      Platform.isLinux || Platform.isWindows
          ? isA<SqliteMapTileCacheRepository>()
          : isNot(isA<SqliteMapTileCacheRepository>()),
    );
    expect(
      web.createMapTileCacheRepository('map_tile_cache'),
      isA<NonStoringObjectProvider>(),
    );
  });

  test('metadata survives reopen and supports updates and deletes', () async {
    await repository.open();
    final inserted = await repository.insert(tile('a'));
    expect(inserted.id, isNotNull);
    expect(inserted.touched, isNotNull);
    await repository.update(inserted.copyWith(length: 456));
    expect((await repository.get('a'))!.length, 456);
    await repository.close();

    repository = createRepository();
    await repository.open();
    final restored = (await repository.get('a'))!;
    expect(restored.relativePath, 'a.png');
    expect(restored.eTag, 'etag-a');
    expect(restored.length, 456);
    expect(await repository.deleteAll([]), 0);
    expect(await repository.deleteAll([restored.id!, restored.id!]), 1);
    expect(await repository.get('a'), isNull);
  });

  test('age and capacity queries select oldest metadata in SQLite', () async {
    await repository.open();
    for (var days = 2; days <= 5; days++) {
      await repository.insert(
        tile('tile-$days', daysOld: days),
        setTouchedToNow: false,
      );
    }
    expect(
      (await repository.getObjectsOverCapacity(2)).map((entry) => entry.key),
      ['tile-4', 'tile-5'],
    );
    expect(
      (await repository.getOldObjects(
        const Duration(days: 3),
      )).map((entry) => entry.key),
      ['tile-5', 'tile-4', 'tile-3'],
    );
  });

  test('legacy JSON migrates without altering downloaded tile files', () async {
    final legacy = File('${directory.path}/map_tile_cache.json');
    final oldTile = tile('10/1/2', daysOld: 2, id: 88);
    final downloaded = File('${directory.path}/tile-bytes.png');
    await downloaded.writeAsBytes([1, 2, 3]);
    await legacy.writeAsString(
      jsonEncode([oldTile.toMap(setTouchedToNow: false)]),
    );

    await repository.open();
    final imported = (await repository.get(oldTile.key))!;
    expect(imported.url, oldTile.url);
    expect(imported.relativePath, oldTile.relativePath);
    expect(
      imported.touched!.millisecondsSinceEpoch,
      oldTile.touched!.millisecondsSinceEpoch,
    );
    expect(imported.length, oldTile.length);
    expect(imported.eTag, oldTile.eTag);
    expect(await downloaded.readAsBytes(), [1, 2, 3]);
    expect(await legacy.exists(), isFalse);
    await repository.close();

    // A crash after commit but before cleanup must not replay stale metadata.
    await legacy.writeAsString(
      jsonEncode([tile('stale', id: 99).toMap(setTouchedToNow: false)]),
    );
    repository = createRepository();
    await repository.open();
    expect(await repository.get('stale'), isNull);
    expect((await repository.getAllObjects()).length, 1);
    expect(await legacy.exists(), isFalse);
  });

  test(
    'malformed migration imports readable records and sets the file aside',
    () async {
      final legacy = File('${directory.path}/map_tile_cache.json');
      final aside = File('${legacy.path}.unreadable');
      final content = jsonEncode([
        {'invalid': true},
        tile('readable', id: 1).toMap(setTouchedToNow: false),
      ]);
      await legacy.writeAsString(content);
      await repository.open();
      expect((await repository.getAllObjects()).single.key, 'readable');
      expect(await legacy.exists(), isFalse);
      expect(await aside.readAsString(), content);
      await repository.close();

      // The file that was set aside is not imported again.
      repository = createRepository();
      await repository.open();
      expect((await repository.getAllObjects()).length, 1);
      await repository.close();
      await repository.deleteDataFile();
      expect(await aside.exists(), isFalse);
    },
  );

  test('a legacy file that is not JSON does not block opening', () async {
    final legacy = File('${directory.path}/map_tile_cache.json');
    await legacy.writeAsString('{broken');
    await repository.open();
    expect(await repository.getAllObjects(), isEmpty);
    expect(await legacy.exists(), isFalse);
    expect(await File('${legacy.path}.unreadable').readAsString(), '{broken');
  });

  test(
    'failed SQL import rolls back rows and preserves original JSON',
    () async {
      await repository.open();
      await repository.close();
      final db = await factory.openDatabase(
        '${directory.path}/map_tile_cache.db',
      );
      await db.delete('cacheMigration');
      await db.execute('''
      CREATE TRIGGER fail_import BEFORE INSERT ON cacheObject
      WHEN NEW.key = 'bad' BEGIN SELECT RAISE(ABORT, 'test failure'); END
    ''');
      await db.close();
      final legacy = File('${directory.path}/map_tile_cache.json');
      await legacy.writeAsString(
        jsonEncode([
          tile('good', id: 1).toMap(setTouchedToNow: false),
          tile('bad', id: 2).toMap(setTouchedToNow: false),
        ]),
      );
      await expectLater(repository.open(), throwsA(isA<DatabaseException>()));
      expect(await legacy.exists(), isTrue);

      final failed = await factory.openDatabase(
        '${directory.path}/map_tile_cache.db',
      );
      expect(await failed.query('cacheObject'), isEmpty);
      expect(await failed.query('cacheMigration'), isEmpty);
      await failed.execute('DROP TRIGGER fail_import');
      await failed.close();
      await repository.open();
      expect((await repository.getAllObjects()).length, 2);
      expect(await legacy.exists(), isFalse);
    },
  );

  test(
    'newer database versions are rejected without deleting legacy data',
    () async {
      final db = await factory.openDatabase(
        '${directory.path}/map_tile_cache.db',
        options: OpenDatabaseOptions(
          version: SqliteMapTileCacheRepository.schemaVersion + 1,
        ),
      );
      await db.close();
      final legacy = File('${directory.path}/map_tile_cache.json');
      await legacy.writeAsString('[]');
      await expectLater(repository.open(), throwsA(isA<DatabaseException>()));
      expect(await legacy.exists(), isTrue);
    },
  );

  test('newer import markers are not overwritten or replayed', () async {
    await repository.open();
    await repository.insert(tile('current'));
    await repository.close();
    final db = await factory.openDatabase(
      '${directory.path}/map_tile_cache.db',
    );
    await db.update('cacheMigration', {
      'version': SqliteMapTileCacheRepository.legacyImportVersion + 1,
    });
    await db.close();
    final legacy = File('${directory.path}/map_tile_cache.json');
    await legacy.writeAsString(
      jsonEncode([tile('legacy', id: 1).toMap(setTouchedToNow: false)]),
    );
    await repository.open();
    expect((await repository.getAllObjects()).map((entry) => entry.key), [
      'current',
    ]);
    expect(await legacy.exists(), isTrue);
    await repository.close();
    final reopened = await factory.openDatabase(
      '${directory.path}/map_tile_cache.db',
    );
    expect(
      (await reopened.query('cacheMigration')).single['version'],
      SqliteMapTileCacheRepository.legacyImportVersion + 1,
    );
    await reopened.close();
  });

  test(
    'inventory connections do not close the cache-manager connection',
    () async {
      await repository.open();
      await repository.open();
      expect(await repository.close(), isFalse);
      final inserted = await repository.insert(tile('a'));
      expect((await repository.get('a'))!.id, inserted.id);
      expect(await repository.close(), isTrue);
      await repository.deleteDataFile();
      expect(await repository.exists(), isFalse);
    },
  );
}
