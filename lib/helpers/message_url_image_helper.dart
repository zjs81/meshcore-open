import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

/// Finds and renders image URLs embedded in ordinary text messages.
///
/// This is deliberately separate from MeshCore's transmitted channel-image
/// protocol, which is handled by [ReceivedImageStore].
class MessageUrlImageHelper {
  static final Map<String, Future<bool>> _verifiedImageCache =
      <String, Future<bool>>{};
  static const int _maxMessageImageCacheEntries = 200;
  static final LinkedHashMap<String, Future<String?>> _messageImageCache =
      LinkedHashMap<String, Future<String?>>();

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

  static final RegExp _ibbSharePattern = RegExp(
    r'''https?://(?:www\.)?ibb\.co/[^\s<>'"`/?#]+(?:[/?#][^\s<>'"`]*)?''',
    caseSensitive: false,
  );

  static final RegExp _imagePattern = RegExp(
    r'''https?://[^\s<>'"`]+?\.(?:png|jpe?g|webp)(?:\?[^\s<>'"`]+)?(?:#[^\s<>'"`]+)?''',
    caseSensitive: false,
  );

  /// Checks locally whether [text] contains a URL format this helper supports.
  /// This deliberately does not resolve sharing pages or fetch image data.
  static bool hasPotentialImageUrl(String text) {
    return _pyxPattern.hasMatch(text) ||
        _ipfsUrlPattern.hasMatch(text) ||
        _ipfsCidPattern.hasMatch(text) ||
        _ibbSharePattern.hasMatch(text) ||
        _imagePattern.hasMatch(text);
  }

  static Future<String?> parse(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final pyxMatch = _pyxPattern.firstMatch(trimmed);
    if (pyxMatch != null) {
      return _extractFromUrl(
        _trimBoundary(pyxMatch.group(0)!),
        RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false),
      );
    }

    final ipfsUrlMatch = _ipfsUrlPattern.firstMatch(trimmed);
    if (ipfsUrlMatch != null) {
      return _trimBoundary(ipfsUrlMatch.group(0)!);
    }

    final ipfsCidMatch = _ipfsCidPattern.firstMatch(trimmed);
    if (ipfsCidMatch != null) {
      final cid = _trimBoundary(ipfsCidMatch.group(1)!);
      return 'https://ipfs.io/ipfs/$cid';
    }

    final ibbMatch = _ibbSharePattern.firstMatch(trimmed);
    if (ibbMatch != null) {
      return _extractFromUrl(
        _trimBoundary(ibbMatch.group(0)!),
        RegExp(
          r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
          caseSensitive: false,
        ),
      );
    }

    final imageMatch = _imagePattern.firstMatch(trimmed);
    if (imageMatch != null) {
      return _trimBoundary(imageMatch.group(0)!);
    }

    return null;
  }

  static Future<String?> parseVerified(String text) async {
    final imageUrl = await parse(text);
    if (imageUrl == null) return null;

    final verified = await _verifyImageUrl(imageUrl);
    return verified ? imageUrl : null;
  }

  /// Caches successful URL-image parsing by stable message identity.
  ///
  /// Null results are evicted so temporary connectivity or host failures can
  /// be retried when a message is shown again.
  static Future<String?> parseVerifiedForMessage(
    String messageId,
    String text,
  ) {
    final cached = _messageImageCache.remove(messageId);
    if (cached != null) {
      _messageImageCache[messageId] = cached;
      return cached;
    }

    final parsing = parseVerified(text);
    _messageImageCache[messageId] = parsing;
    parsing.then((imageUrl) {
      if (imageUrl == null &&
          identical(_messageImageCache[messageId], parsing)) {
        _messageImageCache.remove(messageId);
      } else if (imageUrl != null) {
        while (_messageImageCache.length > _maxMessageImageCacheEntries) {
          _messageImageCache.remove(_messageImageCache.keys.first);
        }
      }
    });
    return parsing;
  }

  static Future<String?> _extractFromUrl(String pageUrl, RegExp pattern) async {
    try {
      final response = await http
          .get(Uri.parse(pageUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final value = pattern.firstMatch(response.body)?.group(1);
      if (value == null || value.isEmpty) return null;

      final imageUrl = Uri.parse(
        pageUrl,
      ).resolve(value.replaceAll('&amp;', '&'));
      return imageUrl.scheme == 'http' || imageUrl.scheme == 'https'
          ? imageUrl.toString()
          : null;
    } catch (_) {
      return null;
    }
  }

  static String _trimBoundary(String value) {
    return value.trim().replaceAll(RegExp(r"[.,;:!?]+$"), '');
  }

  static Future<bool> _verifyImageUrl(String imageUrl) {
    final cached = _verifiedImageCache[imageUrl];
    if (cached != null) return cached;

    final verification = _tryLoadImage(imageUrl);
    _verifiedImageCache[imageUrl] = verification;
    verification.then((verified) {
      if (!verified && identical(_verifiedImageCache[imageUrl], verification)) {
        _verifiedImageCache.remove(imageUrl);
      }
    });
    return verification;
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

class MessageUrlImageFutureBuilder extends StatefulWidget {
  const MessageUrlImageFutureBuilder({
    super.key,
    required this.messageId,
    required this.text,
    required this.builder,
  });

  final String messageId;
  final String text;
  final AsyncWidgetBuilder<String?> builder;

  @override
  State<MessageUrlImageFutureBuilder> createState() =>
      _MessageUrlImageFutureBuilderState();
}

class _MessageUrlImageFutureBuilderState
    extends State<MessageUrlImageFutureBuilder> {
  late Future<String?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = MessageUrlImageHelper.parseVerifiedForMessage(
      widget.messageId,
      widget.text,
    );
  }

  @override
  void didUpdateWidget(covariant MessageUrlImageFutureBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId) {
      _imageFuture = MessageUrlImageHelper.parseVerifiedForMessage(
        widget.messageId,
        widget.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageFuture,
      builder: widget.builder,
    );
  }
}

class MessageUrlImagePreview extends StatelessWidget {
  const MessageUrlImagePreview({super.key, required this.imageUrl});

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
        child: SizedBox(
          width: 240,
          height: 240,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => ColoredBox(
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
