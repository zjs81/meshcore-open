import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/login_error_formatter.dart';

void main() {
  group('formatLoginError', () {
    test('preserves format errors for local validation failures', () {
      expect(
        formatLoginError(
          const FormatException('invalid frame'),
          fallbackMessage: 'Login failed',
        ),
        contains('invalid frame'),
      );
    });

    test('strips exception prefix for user-facing remote failures', () {
      expect(
        formatLoginError(
          Exception('Wrong password or node is unreachable'),
          fallbackMessage: 'Login failed',
        ),
        'Wrong password or node is unreachable',
      );
    });

    test('falls back to generic message for opaque errors', () {
      expect(
        formatLoginError(
          StateError(''),
          fallbackMessage: 'Login failed',
        ),
        'Login failed',
      );
    });
  });
}
