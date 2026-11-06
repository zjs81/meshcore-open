import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

void main() {
  // Amber on its own pale tint in the light theme was about 2:1.
  final lightTint = Color.alphaBlend(
    MeshPalette.warn.withValues(alpha: 0.12),
    MeshPalette.lightBg1,
  );
  final darkTint = Color.alphaBlend(
    MeshPalette.warn.withValues(alpha: 0.12),
    MeshPalette.bg1,
  );

  test('darkens an accent on a light background until it is readable', () {
    expect(meshContrastRatio(MeshPalette.warn, lightTint), lessThan(3));
    final text = readableAccent(MeshPalette.warn, lightTint);
    expect(meshContrastRatio(text, lightTint), greaterThanOrEqualTo(4.5));
    final icon = readableAccent(MeshPalette.warn, lightTint, minContrast: 3);
    expect(meshContrastRatio(icon, lightTint), greaterThanOrEqualTo(3));
  });

  test('keeps an accent that is already readable', () {
    expect(readableAccent(MeshPalette.warn, darkTint), MeshPalette.warn);
  });
}
