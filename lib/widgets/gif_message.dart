import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class GifMessage extends StatefulWidget {
  final String url;
  final Color backgroundColor;
  final Color fallbackTextColor;
  final double maxSize;

  const GifMessage({
    super.key,
    required this.url,
    required this.backgroundColor,
    required this.fallbackTextColor,
    this.maxSize = 200,
  });

  @override
  State<GifMessage> createState() => _GifMessageState();
}

class _GifMessageState extends State<GifMessage> {
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  Object? _error;
  bool _isLoading = true;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant GifMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _unsubscribe();
      _image = null;
      _error = null;
      _isLoading = true;
      _isPaused = false;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _resolveImage() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final provider = NetworkImage(widget.url);
    final stream = provider.resolve(ImageConfiguration.empty);
    _imageStream = stream;
    _listener = ImageStreamListener(
      (imageInfo, _) {
        if (_isPaused) {
          return;
        }
        setState(() {
          _image = imageInfo.image;
          _isLoading = false;
        });
      },
      onError: (error, _) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
    stream.addListener(_listener!);
  }

  void _retryLoad() {
    _unsubscribe();
    _image = null;
    _isPaused = false;
    _resolveImage();
  }

  void _unsubscribe() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
  }

  void _togglePause() {
    if (_error != null) {
      _retryLoad();
      return;
    }
    if (_image == null) {
      if (!_isLoading) {
        _retryLoad();
      }
      return;
    }
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_listener == null || _imageStream == null) {
      return;
    }
    if (_isPaused) {
      _imageStream!.removeListener(_listener!);
    } else {
      _imageStream!.addListener(_listener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate display size based on image aspect ratio
    // Use 4:3 placeholder aspect ratio during loading to minimize layout shifts
    double displayWidth = widget.maxSize;
    double displayHeight = widget.maxSize * 0.75;

    if (_image != null) {
      final imageWidth = _image!.width.toDouble();
      final imageHeight = _image!.height.toDouble();
      final aspectRatio = imageWidth / imageHeight;

      // Fit within maxSize, calculating dimensions from aspect ratio
      if (aspectRatio >= 1) {
        // Wider than tall: constrain by width
        displayWidth = widget.maxSize;
        displayHeight = displayWidth / aspectRatio;
      } else {
        // Taller than wide: constrain by height
        displayHeight = widget.maxSize;
        displayWidth = displayHeight * aspectRatio;
      }
    }

    Widget content;

    if (_error != null) {
      content = Center(
        child: Text(
          context.l10n.gif_loadFailedRetry,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: widget.fallbackTextColor),
        ),
      );
    } else if (_isLoading && _image == null) {
      content = const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_image == null) {
      content = Center(
        child: Text(
          context.l10n.gif_tapToLoad,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: widget.fallbackTextColor),
        ),
      );
    } else {
      content = RawImage(
        image: _image,
        fit: BoxFit.contain,
        width: displayWidth,
        height: displayHeight,
      );
    }

    return GestureDetector(
      onTap: _togglePause,
      child: Container(
        color: widget.backgroundColor,
        width: displayWidth,
        height: displayHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (_isPaused && _image != null)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(Icons.pause, color: Colors.white70, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
