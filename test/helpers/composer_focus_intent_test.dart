import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/composer_focus_intent.dart';

void _setLifecycle(WidgetTester tester, List<AppLifecycleState> states) {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

const _away = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];
const _back = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

void main() {
  testWidgets('focus gained while in the foreground is user focus', (
    tester,
  ) async {
    final intent = ComposerFocusIntent();
    addTearDown(intent.dispose);

    expect(intent.isUserFocusGain(true), isTrue);
    expect(intent.isUserFocusGain(false), isFalse);
    expect(intent.isUserFocusGain(true), isTrue);
  });

  testWidgets('focus lost while away and given back on resume is not', (
    tester,
  ) async {
    final intent = ComposerFocusIntent();
    addTearDown(intent.dispose);

    expect(intent.isUserFocusGain(true), isTrue);
    _setLifecycle(tester, _away.sublist(0, 1));
    expect(intent.isUserFocusGain(false), isFalse);
    _setLifecycle(tester, [..._away.sublist(1), ..._back]);
    // The restore lands before the resume microtask clears the flag.
    expect(intent.isUserFocusGain(true), isFalse);
    // The next tap counts again.
    expect(intent.isUserFocusGain(false), isFalse);
    expect(intent.isUserFocusGain(true), isTrue);
  });

  testWidgets('focus not restored on resume does not swallow the next tap', (
    tester,
  ) async {
    final intent = ComposerFocusIntent();
    addTearDown(intent.dispose);

    _setLifecycle(tester, _away.sublist(0, 1));
    expect(intent.isUserFocusGain(false), isFalse);
    _setLifecycle(tester, [..._away.sublist(1), ..._back]);
    await tester.pump(); // Resume microtasks run; nothing restored focus.

    expect(intent.isUserFocusGain(true), isTrue);
  });

  testWidgets('focus given back when a sheet or dialog closes is not', (
    tester,
  ) async {
    final intent = ComposerFocusIntent();
    addTearDown(intent.dispose);

    expect(intent.isUserFocusGain(true), isTrue);
    expect(intent.isUserFocusGain(false, coveredByRoute: true), isFalse);
    expect(intent.isUserFocusGain(true), isFalse);
    // Losing focus with nothing on top, then tapping, counts again.
    expect(intent.isUserFocusGain(false), isFalse);
    expect(intent.isUserFocusGain(true), isTrue);
  });
}
