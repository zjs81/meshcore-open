import 'package:flutter/material.dart';

/// Shows or hides [child] by animating its height.
///
/// Use this wherever turning something on reveals more controls, and for any
/// other block that grows or collapses in place. Hidden controls are not in
/// the tree, so they are not announced. The duration and curve are fixed so
/// every reveal moves the same way. See documentation/design.md.
class RevealOnEnable extends StatelessWidget {
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeInOut;

  final bool visible;
  final Widget child;
  final AlignmentGeometry alignment;

  const RevealOnEnable({
    super.key,
    required this.visible,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: visible
          ? child
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

/// Nested controls under a settings switch: the shared reveal animation on a
/// tinted, indented panel.
class SettingsReveal extends StatelessWidget {
  final bool visible;
  final List<Widget> children;

  const SettingsReveal({
    super.key,
    required this.visible,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return RevealOnEnable(
      visible: visible,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A settings slider whose selected value stays visible in the title.
///
/// The drag bubble repeats the same number. Pass a [title] that already
/// includes [value], the way the channel-hop titles do, and an [icon] so the
/// row aligns with neighbouring [SwitchListTile] and [MeshNavTile] rows.
class SettingsValueSlider extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const SettingsValueSlider({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 24),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) Text(subtitle!),
          Slider(
            value: clamped.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max > min ? max - min : null,
            label: '$clamped',
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      ),
    );
  }
}
