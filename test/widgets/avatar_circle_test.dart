import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

void main() {
  Future<void> pumpAvatar(WidgetTester tester, String name) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AvatarCircle(name: name, size: 40)),
      ),
    );
  }

  testWidgets('shows the emoji alone when the name has one', (tester) async {
    await pumpAvatar(tester, '\u{1F431}Node');
    expect(find.text('\u{1F431}'), findsOneWidget);
  });

  testWidgets('shows the first three characters otherwise', (tester) async {
    await pumpAvatar(tester, 'vk2');
    expect(find.text('VK2'), findsOneWidget);
  });

  testWidgets('multi-word names use the first three characters', (
    tester,
  ) async {
    await pumpAvatar(tester, 'Zed Alpha');
    expect(find.text('ZED'), findsOneWidget);
  });

  testWidgets('empty names fall back to a question mark', (tester) async {
    await pumpAvatar(tester, '   ');
    expect(find.text('?'), findsOneWidget);
  });
}
