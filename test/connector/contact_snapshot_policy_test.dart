import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  group('shouldReplaceContactsSnapshot', () {
    test('does not clear contacts before the device starts a snapshot', () {
      expect(
        shouldReplaceContactsSnapshot(
          preserveExisting: false,
          snapshotStarted: false,
        ),
        isFalse,
      );
    });

    test('clears contacts on snapshot start when not preserving existing', () {
      expect(
        shouldReplaceContactsSnapshot(
          preserveExisting: false,
          snapshotStarted: true,
        ),
        isTrue,
      );
    });

    test('preserves contacts on incremental refresh snapshots', () {
      expect(
        shouldReplaceContactsSnapshot(
          preserveExisting: true,
          snapshotStarted: true,
        ),
        isFalse,
      );
    });
  });
}
