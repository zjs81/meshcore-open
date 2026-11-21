import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations_en.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/widgets/contact_visuals.dart';

Contact _contact(int seed, {required DateTime lastSeen, DateTime? message}) =>
    Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: 'c$seed',
      type: 1,
      pathLength: -1,
      path: Uint8List(0),
      lastSeen: lastSeen,
      lastMessageAt: message,
    );

void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final now = DateTime.now();

  test('added time orders a contact the radio has no advert time for', () {
    final added = now.subtract(const Duration(minutes: 1));
    final fromCard = _contact(1, lastSeen: epoch);
    final heardHourAgo = _contact(
      2,
      lastSeen: now.subtract(const Duration(hours: 1)),
    );
    final addedAt = {fromCard: added};
    final sorted = [heardHourAgo, fromCard]
      ..sort(
        (a, b) => resolveContactLastSeen(
          b,
          addedAt: addedAt[b],
        ).compareTo(resolveContactLastSeen(a, addedAt: addedAt[a])),
      );

    expect(resolveContactLastSeen(fromCard, addedAt: added), added);
    expect(sorted.first, fromCard);
  });

  test('a real advert time is never replaced by the added time', () {
    final advert = now.subtract(const Duration(days: 30));
    final contact = _contact(3, lastSeen: advert);

    expect(resolveContactLastSeen(contact, addedAt: now), advert);
  });

  test('a newer message still wins over the added time', () {
    final message = now;
    final contact = _contact(4, lastSeen: epoch, message: message);

    expect(
      resolveContactLastSeen(
        contact,
        addedAt: now.subtract(const Duration(hours: 1)),
      ),
      message,
    );
  });

  test('a contact never heard shows "not heard yet", not decades ago', () {
    final l10n = AppLocalizationsEn();

    expect(formatContactLastSeen(l10n, epoch), l10n.contacts_lastSeenNever);
    expect(
      resolveContactLastSeen(_contact(5, lastSeen: epoch)),
      epoch,
      reason: 'display label is driven by the advert/message time only',
    );
  });
}
