import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'chat_background_image_store_base.dart';

ChatBackgroundImageStore createChatBackgroundImageStore() =>
    _FileChatBackgroundImageStore();

/// One JPEG XL file per picture under `<app support>/chat_backgrounds/`.
class _FileChatBackgroundImageStore implements ChatBackgroundImageStore {
  Directory? _dir;

  Future<Directory> _directory() async {
    final existing = _dir;
    if (existing != null) return existing;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/chat_backgrounds');
    await dir.create(recursive: true);
    return _dir = dir;
  }

  Future<File> _file(String id) async =>
      File('${(await _directory()).path}/$id.jxl');

  @override
  Future<void> write(String id, Uint8List bytes) async {
    final file = await _file(id);
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<Uint8List?> read(String id) async {
    final file = await _file(id);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String id) async {
    final file = await _file(id);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<Set<String>> listIds() async {
    final dir = await _directory();
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.jxl'))
        .map((name) => name.substring(0, name.length - 4))
        .toSet();
  }
}
