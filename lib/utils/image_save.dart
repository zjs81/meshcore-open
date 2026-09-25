import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../services/received_image_store.dart';
import 'platform_info.dart';

/// Saves a transcript image: a save dialog on desktop, the share sheet
/// elsewhere. Reconstructed images are named as such so the file never passes
/// for a photograph. Returns false on failure; a cancelled dialog is not one.
Future<bool> saveImagePng(
  Uint8List png,
  ReceivedImageEntry entry, {
  String? shareText,
}) async {
  final name = entry.synthesized
      ? 'meshcore-ai-reconstructed-${entry.streamId}.png'
      : 'meshcore-${entry.streamId}.png';
  final file = XFile.fromData(png, mimeType: 'image/png', name: name);
  try {
    if (PlatformInfo.isDesktop) {
      final location = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PNG', extensions: ['png']),
        ],
      );
      if (location != null) await file.saveTo(location.path);
      return true;
    }
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [name],
        text: entry.synthesized ? shareText : null,
      ),
    );
    return result.status != ShareResultStatus.unavailable;
  } catch (e) {
    debugPrint('image save failed: $e');
    return false;
  }
}
