import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageImageHelper {
  static final Map<String, Future<bool>> _verifiedImageCache =
      <String, Future<bool>>{};

  static final RegExp _pyxPattern = RegExp(
    r'''https?://pyx\.li/\?i=([^\s<>'"`]+)''',
    caseSensitive: false,
  );

  static final RegExp _ipfsUrlPattern = RegExp(
    r'''https?://[^\s<>'"`]+/(?:ipfs|ipns)/[^\s<>'"`]+''',
    caseSensitive: false,
  );

  static final RegExp _ipfsCidPattern = RegExp(
    r'''ipfs://([^\s<>'"`]+)''',
    caseSensitive: false,
  );

  static final RegExp _imagePattern = RegExp(
    r'''https?://[^\s<>'"`]+?\.(?:png|jpe?g|webp)(?:\?[^\s<>'"`]+)?(?:#[^\s<>'"`]+)?''',
    caseSensitive: false,
  );

  static String? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    String? imageUrl;

    final pyxMatch = _pyxPattern.firstMatch(trimmed);
    if (pyxMatch != null) {
      final id = _trimBoundary(pyxMatch.group(1)!);
      imageUrl = 'https://pyx.li/i/$id.jpg';
    }

    final ipfsUrlMatch = _ipfsUrlPattern.firstMatch(trimmed);
    if (ipfsUrlMatch != null) {
      imageUrl = _trimBoundary(ipfsUrlMatch.group(0)!);
    }

    final ipfsCidMatch = _ipfsCidPattern.firstMatch(trimmed);
    if (ipfsCidMatch != null) {
      final cid = _trimBoundary(ipfsCidMatch.group(1)!);
      imageUrl = 'https://ipfs.io/ipfs/$cid';
    }

    final imageMatch = _imagePattern.firstMatch(trimmed);
    if (imageMatch != null) {
      imageUrl = _trimBoundary(imageMatch.group(0)!);
    }

    return imageUrl;
  }

  static Future<String?> parseVerified(String text) async {
    final imageUrl = parse(text);
    if (imageUrl == null) return null;

    final verified = await _verifyImageUrl(imageUrl);
    return verified ? imageUrl : null;
  }

  static String _trimBoundary(String value) {
    return value.trim().replaceAll(RegExp(r"[.,;:!?]+$"), '');
  }

  static Future<bool> _verifyImageUrl(String imageUrl) {
    return _verifiedImageCache.putIfAbsent(
      imageUrl,
      () => _tryLoadImage(imageUrl),
    );
  }

  static Future<bool> _tryLoadImage(String imageUrl) async {
    final completer = Completer<bool>();
    final stream = CachedNetworkImageProvider(
      imageUrl,
    ).resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!completer.isCompleted) completer.complete(true);
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!completer.isCompleted) completer.complete(false);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        stream.removeListener(listener);
        return false;
      },
    );
  }
}

class MessageImagePreview extends StatelessWidget {
  const MessageImagePreview({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.black,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(80),
                      minScale: 1.0,
                      maxScale: 3.0,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              width: 200,
              height: 140,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                'Unable to load image',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
