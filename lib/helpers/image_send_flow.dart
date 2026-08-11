import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n.dart';
import '../widgets/image_send_codec_binding.dart';
import '../widgets/image_send_preview_sheet.dart';

/// Shared "attach an image" flow, used by both the direct-message and channel
/// chat screens so the two surfaces cannot drift apart.
///
/// Picks a photo, then shows [ImageSendPreviewSheet] so the user sees the
/// packet count and airtime *before* committing to a send that may occupy the
/// channel for seconds. Returns null if the user backed out at either step.
///
/// The caller owns the actual transmission: this only produces the payload.
Future<ImageSendPreviewResult?> pickAndPreviewImage({
  required BuildContext context,
  required ImageSendCodec codec,
  ImagePicker? picker,
}) async {
  final XFile? picked;
  try {
    picked = await (picker ?? ImagePicker()).pickImage(
      source: ImageSource.gallery,
      // The codec centre-crops to 512x512 anyway, so there is nothing to gain
      // from decoding a 12 MP original -- but stay well above 512 so the crop
      // still has detail to work with.
      maxWidth: 2048,
      maxHeight: 2048,
    );
  } on Exception catch (e) {
    debugPrint('image pick failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chat_imagePickFailed)),
      );
    }
    return null;
  }

  if (picked == null) return null; // user cancelled the picker

  final Uint8List bytes;
  int originalBytes;
  try {
    bytes = await picked.readAsBytes();
    originalBytes = bytes.length;
    if (!kIsWeb) {
      // length() is the on-disk size, which is what we want to show against the
      // transmitted size; fall back to the in-memory length if it fails.
      try {
        originalBytes = await File(picked.path).length();
      } on FileSystemException {
        // keep the in-memory length
      }
    }
  } on Exception catch (e) {
    debugPrint('image read failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chat_imagePickFailed)),
      );
    }
    return null;
  }

  if (!context.mounted) return null;

  return showImageSendPreviewSheet(
    context: context,
    imageBytes: bytes,
    originalFileBytes: originalBytes,
    codec: codec,
  );
}
