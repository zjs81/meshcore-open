import 'received_image_store.dart';

/// Web fallback: images live only for the lifetime of the tab.
///
/// The codec cannot run on web anyway (`ImageCodecService.availability` is
/// `unavailable` there), so nothing is lost that could have been rendered.
ReceivedImageBlobStore createReceivedImageBlobStore() =>
    InMemoryReceivedImageBlobStore();
