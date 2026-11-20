import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/widgets/contact_visuals.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

void main() {
  group('avatarInitials', () {
    test('empty and whitespace-only names have no initials', () {
      expect(avatarInitials(''), isNull);
      expect(avatarInitials('   '), isNull);
    });

    test('punctuation-only names have no initials', () {
      expect(avatarInitials('-'), isNull);
      expect(avatarInitials('(--) [ ]'), isNull);
    });

    test('punctuation never becomes an initial', () {
      expect(avatarInitials('(Base) Node'), 'BN');
      expect(avatarInitials('- Relay'), 'RE');
      expect(avatarInitials('[AB12] Hilltop'), 'AH');
      expect(avatarInitials('Node-1'), 'N1');
    });

    test('plain names keep the existing two-letter shape', () {
      expect(avatarInitials('Alice Smith'), 'AS');
      expect(avatarInitials('tower'), 'TO');
      expect(avatarInitials('A1B2C3D4'), 'A1');
    });

    test('Cyrillic names use their letters', () {
      expect(avatarInitials('Иван Петров'), 'ИП');
      expect(avatarInitials('(ретранслятор)'), 'РЕ');
    });

    test('CJK names use their characters', () {
      expect(avatarInitials('東京 中継'), '東中');
      expect(avatarInitials('「大阪」'), '大阪');
    });

    test('emoji is kept whole and skipped when letters exist', () {
      expect(avatarInitials('🔥 Fire Node'), 'FN');
      expect(avatarInitials('Fire🔥Node'), 'FN');
      expect(avatarInitials('🔥'), '🔥');
      expect(avatarInitials('👨‍👩‍👧 -'), '👨‍👩‍👧');
    });

    test('combining accents stay with their letter', () {
      expect(avatarInitials('école'), 'ÉC');
    });
  });

  testWidgets('AvatarCircle shows an icon when the name has no initials', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AvatarCircle(name: '(--)'),
              AvatarCircle(name: '(Base) Node'),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('BN'), findsOneWidget);
    expect(find.textContaining('('), findsNothing);
  });
}
