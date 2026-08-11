import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class ImageSendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final String? tooltip;

  const ImageSendButton({
    super.key,
    required this.enabled,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(enabled ? Icons.image : Icons.image_outlined),
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip ?? context.l10n.chat_sendImage,
    );
  }
}
