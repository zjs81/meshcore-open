/// Platform-appropriate [ReceivedImageBlobStore], chosen at compile time.
///
/// `received_image_blob_store_io.dart` imports `dart:io` and
/// `package:path_provider`, so `main.dart` cannot import it directly without
/// breaking the web build. Same conditional-export shape as
/// `image_codec_file_store.dart`.
library;

export 'received_image_blob_store_factory_stub.dart'
    if (dart.library.io) 'received_image_blob_store_factory_io.dart';
