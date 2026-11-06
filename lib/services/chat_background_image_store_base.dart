import 'dart:typed_data';

/// Stores chat background pictures by content ID.
abstract class ChatBackgroundImageStore {
  Future<void> write(String id, Uint8List bytes);
  Future<Uint8List?> read(String id);
  Future<void> delete(String id);
  Future<Set<String>> listIds();
}

/// For tests.
class InMemoryChatBackgroundImageStore implements ChatBackgroundImageStore {
  final Map<String, Uint8List> images = {};

  @override
  Future<void> write(String id, Uint8List bytes) async => images[id] = bytes;

  @override
  Future<Uint8List?> read(String id) async => images[id];

  @override
  Future<void> delete(String id) async => images.remove(id);

  @override
  Future<Set<String>> listIds() async => images.keys.toSet();
}
