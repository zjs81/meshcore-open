import 'package:flutter/material.dart';

/// App bar title that honors the system font size. Long titles are
/// ellipsized instead of being shrunk to fit.
class AdaptiveAppBarTitle extends StatelessWidget {
  final String text;

  const AdaptiveAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
