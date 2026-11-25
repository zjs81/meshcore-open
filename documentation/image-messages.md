# Image Messages

MeshCore Open can send a highly compressed image as channel GRP_DATA packets. Unlike a GIF reference or URL preview, the compressed image bytes travel over the mesh. A compatible recipient reconstructs them locally using the image model.

## Requirements and setup

- Companion firmware version code **11 or later** (identified in the connector as v1.15.0) for the current channel-data layout.
- A native runtime with a working ONNX backend. The web build has no image codec backend.
- The image model bundle installed through App Settings → Image model, and Enable image messages turned on.
- Enough storage for the roughly 1 GB bundle and enough available memory for reconstruction, which can peak above 2 GB. Actual latency and memory usage depend on hardware.

Downloads use the configured Hugging Face model bundle, support resume, and verify file checksums. Download the model while internet is available. Once installed, encoding and reconstruction run locally; photos are not uploaded for inference. Compatible recipients need the same supported codec/model format.

## Send an image

1. Open channel chat and tap the image button beside the composer.
2. Pick a photo from your gallery.
3. Wait for the preview. The sheet shows **What recipients see**: the photo encoded and then decoded on your device, which is the picture recipients reconstruct. Switch to **Original** to compare.
4. If the reconstruction got something wrong, tap **Try another version**. Each version encodes the whole photo with a tiny, invisible change of framing, and the model reconstructs each one a little differently. Tap the version you want to send; the packet count and time on air follow your choice. Up to six versions can be made, one at a time.
5. Review transmitted bytes, packet count, and estimated send duration. Estimates use the current radio settings and are unavailable if those settings are unknown.
6. Choose whether to include a recovery packet, then send. The chat shows per-packet progress, and your own copy of the image shows the version you chose.

After sending, your image shows how many times repeaters were heard passing it on, like a channel message (Packet info lists each packet). If repeaters passed on some packets but not others, the missing ones are sent once more automatically.

On a device that cannot decode, the sheet shows the original photo with a note instead, and versions are not offered. Each new version costs one encode and one decode, so it can take a few seconds on older phones.

The current build ships one quality/model setting: **ft32**, with a 512×512 codec reconstruction and metadata used to restore a supported aspect ratio. Reserved rate/resolution codes are not additional selectable quality options.

The result is a lossy, AI-reconstructed image and can differ materially from the original. It is labeled accordingly. Send confirmation describes companion acceptance of packets, not end-to-end proof that every recipient reconstructed the image.

## Receive, reconstruct, and save

Chunks are reassembled into an image entry in channel chat. A partially received stream is retained for up to 60 seconds before expiry. An optional XOR parity packet can recover **one missing data chunk**, provided the parity and other required chunks arrive; it does not guarantee delivery.

With Process images automatically enabled, complete images are queued for local reconstruction. Automatic decoding runs only while the app is in the foreground, one image at a time, with at most 3 images queued; when more arrive, the newest 3 are kept and the rest wait for a tap. Otherwise, tap an image entry to process it. Download/enable the model if prompted. A failed reconstruction can be retried; missing chunks and inference errors are different failures.

Tap a reconstructed image to inspect it. Long-press or right-click its chat bubble for Packet info, Delete, and Save (available once decoded). Deletion is local. Encoded streams and reconstructed images are persisted in application storage, capped at 200 images, 64 MB, and 30 days, plus a limit of 400 image entries (including ones waiting to be decoded and your own sent images once their data has expired). When the cap is reached, the oldest reconstructed images are evicted first and show "Image no longer stored"; they can be decoded again while their small encoded stream remains. Past 30 days the stream is removed too.

## Other image features

[GIFs and URL image previews](additional-features.md#url-image-previews) transmit references and fetch image content over the internet. They do not use this mesh image transport.

## Implementation reference

[image_chunk_transport.dart](../lib/services/image_chunk_transport.dart) defines the wire layout, capacities, metadata, and recovery algorithm. The current transport uses command 62, response 27, and data type `0xAE1C`. See the [protocol reference](ble-protocol.md#regions-and-image-data) and [fixture regeneration guide](../tools/aeic/README.md).
