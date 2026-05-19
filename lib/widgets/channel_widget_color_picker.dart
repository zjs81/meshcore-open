import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class ChannelWidgetColorSelection {
  const ChannelWidgetColorSelection({
    required this.backgroundColorValue,
    required this.textColorValue,
  });

  final int? backgroundColorValue;
  final int? textColorValue;
}

class ChannelWidgetColorValue extends StatelessWidget {
  const ChannelWidgetColorValue({super.key, required this.colorValue});

  final int? colorValue;

  @override
  Widget build(BuildContext context) {
    final value = colorValue;
    if (value == null) {
      return Text(context.l10n.appSettings_themeSystem);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Color(value),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
    );
  }
}

Future<ChannelWidgetColorSelection?> showChannelWidgetColorPicker(
  BuildContext context, {
  required int? selectedBackgroundColorValue,
  required int? selectedTextColorValue,
}) {
  int? draftBackgroundColorValue = selectedBackgroundColorValue;
  int? draftTextColorValue = selectedTextColorValue;

  return showDialog<ChannelWidgetColorSelection>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(dialogContext.l10n.channels_changeWidgetColor),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChannelWidgetColorSection(
                  title: dialogContext.l10n.channels_changeWidgetColor,
                  selectedColorValue: draftBackgroundColorValue,
                  onDefaultTap: () {
                    setState(() {
                      draftBackgroundColorValue = null;
                    });
                  },
                  onColorChanged: (colorValue) {
                    setState(() {
                      draftBackgroundColorValue = colorValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _ChannelWidgetColorSection(
                  title: dialogContext.l10n.channels_changeWidgetTextColor,
                  selectedColorValue: draftTextColorValue,
                  onDefaultTap: () {
                    setState(() {
                      draftTextColorValue = null;
                    });
                  },
                  onColorChanged: (colorValue) {
                    setState(() {
                      draftTextColorValue = colorValue;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              ChannelWidgetColorSelection(
                backgroundColorValue: draftBackgroundColorValue,
                textColorValue: draftTextColorValue,
              ),
            ),
            child: Text(dialogContext.l10n.common_save),
          ),
        ],
      ),
    ),
  );
}

class _ChannelWidgetColorSection extends StatelessWidget {
  const _ChannelWidgetColorSection({
    required this.title,
    required this.selectedColorValue,
    required this.onDefaultTap,
    required this.onColorChanged,
  });

  final String title;
  final int? selectedColorValue;
  final VoidCallback onDefaultTap;
  final ValueChanged<int> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final hsv = selectedColorValue == null
        ? const HSVColor.fromAHSV(1, 0, 1, 1)
        : HSVColor.fromColor(Color(selectedColorValue!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            ChannelWidgetColorValue(colorValue: selectedColorValue),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.appSettings_themeSystem),
          trailing: selectedColorValue == null ? const Icon(Icons.check) : null,
          onTap: onDefaultTap,
        ),
        const SizedBox(height: 8),
        _SaturationValuePicker(
          hsv: hsv,
          onChanged: (nextHsv) =>
              onColorChanged(_colorToArgb(nextHsv.toColor())),
        ),
        const SizedBox(height: 12),
        _HueSlider(
          hue: hsv.hue,
          onChanged: (nextHue) {
            onColorChanged(_colorToArgb(hsv.withHue(nextHue).toColor()));
          },
        ),
      ],
    );
  }
}

class _SaturationValuePicker extends StatelessWidget {
  const _SaturationValuePicker({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 220.0);
        final knobLeft = hsv.saturation * size;
        final knobTop = (1 - hsv.value) * size;

        void updateFromOffset(Offset localOffset) {
          final saturation = (localOffset.dx / size).clamp(0.0, 1.0);
          final value = (1 - (localOffset.dy / size)).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(saturation).withValue(value));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => updateFromOffset(details.localPosition),
          onPanUpdate: (details) => updateFromOffset(details.localPosition),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                  ),
                ),
                // Layer white and black gradients to produce the full SV field.
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                    ),
                  ),
                ),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
                Positioned(
                  left: knobLeft - 10,
                  top: knobTop - 10,
                  child: IgnorePointer(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const sliderHeight = 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final knobLeft = (hue / 360) * width;

        void updateFromOffset(Offset localOffset) {
          final normalized = (localOffset.dx / width).clamp(0.0, 1.0);
          onChanged(normalized * 360);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => updateFromOffset(details.localPosition),
          onPanUpdate: (details) => updateFromOffset(details.localPosition),
          child: SizedBox(
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: sliderHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: knobLeft - 8,
                  top: -2,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

int _colorToArgb(Color color) {
  final alpha = (color.a * 255).round();
  final red = (color.r * 255).round();
  final green = (color.g * 255).round();
  final blue = (color.b * 255).round();
  return alpha << 24 | red << 16 | green << 8 | blue;
}
