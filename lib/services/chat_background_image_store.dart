/// Platform-appropriate [ChatBackgroundImageStore], chosen at compile time
/// (`dart:io` files natively, preferences on web).
library;

export 'chat_background_image_store_base.dart';
export 'chat_background_image_store_stub.dart'
    if (dart.library.io) 'chat_background_image_store_io.dart';
