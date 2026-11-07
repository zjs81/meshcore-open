import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('snackbar action text is readable in light and dark themes', () {
    for (final theme in [MeshTheme.light(), MeshTheme.dark()]) {
      final sb = theme.snackBarTheme;
      expect(sb.actionTextColor, isNotNull);
      expect(
        _contrast(sb.actionTextColor!, sb.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('snackbar with action and persist:false auto-dismisses', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('Rule deleted'),
        duration: const Duration(seconds: 6),
        persist: false,
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Rule deleted'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Rule deleted'), findsNothing);
  });
}
