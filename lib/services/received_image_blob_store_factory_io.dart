import 'received_image_blob_store_io.dart';
import 'received_image_store.dart';

/// File-backed store under the application support directory.
///
/// Received images have to survive a restart: the sidecar record is the only
/// evidence that a message *was* an image, so an in-memory store loses the
/// bubble as well as the pixels.
ReceivedImageBlobStore createReceivedImageBlobStore() =>
    FileReceivedImageBlobStore();
