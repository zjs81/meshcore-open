import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/utils/contact_search.dart';

Contact _contact(
  String name,
  List<int> key, {
  int type = advTypeRepeater,
  DateTime? lastSeen,
}) {
  return Contact(
    publicKey: Uint8List.fromList(key),
    name: name,
    type: type,
    pathLength: -1,
    path: Uint8List(0),
    lastSeen: lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

List<String> _ranked(List<Contact> contacts, String query) {
  final matches = contacts.where((c) => matchesContactQuery(c, query)).toList()
    ..sort((a, b) => compareContactQueryRank(a, b, query));
  return matches.map((c) => c.name).toList();
}

void main() {
  final contacts = [
    _contact('100 Acre', [0x11, 0x22, 0x33, 0x44]),
    _contact('Acreage North', [0x33, 0x44, 0x55, 0x66]),
    _contact('My Acre Site', [0x55, 0x66, 0x77, 0x88]),
    _contact('2E0HQR-R', [0x2E, 0x0A, 0x1B, 0x2C]),
    _contact('CR1', [0x60, 0x60, 0xAB, 0xCD]),
    _contact('Node 6060', [0x01, 0x02, 0x03, 0x04]),
    _contact('6060 Hub', [0x0A, 0x0B, 0x0C, 0x0D]),
  ];

  test('name prefixes rank before other substring matches', () {
    expect(_ranked(contacts, 'acre'), [
      'Acreage North',
      '100 Acre',
      'My Acre Site',
    ]);
  });

  test('prefix matches stay alphabetical among themselves', () {
    final extra = [
      _contact('Acreage North', [0x01]),
      _contact('Acre Beacon', [0x02]),
    ];
    expect(_ranked(extra, 'acre'), ['Acre Beacon', 'Acreage North']);
  });

  test('a hop hash matches when the name does not', () {
    expect(matchesContactQuery(contacts[4], '6060'), isTrue);
    expect(matchesContactQuery(contacts[4], '60'), isTrue);
    expect(matchesContactQuery(contacts[4], '6060abcd'), isTrue);
    expect(matchesContactQuery(contacts[4], '6061'), isFalse);
    expect(_ranked(contacts, '6060'), ['6060 Hub', 'Node 6060', 'CR1']);
  });

  test('hash search accepts 0x, spaces, and angle brackets', () {
    expect(_ranked(contacts, '0x6060'), ['CR1']);
    expect(_ranked(contacts, '60 60'), ['CR1']);
    expect(_ranked(contacts, '<6060>'), ['CR1']);
  });

  test('a single hex digit does not match every key', () {
    expect(matchesContactQuery(contacts[4], '6'), isFalse);
  });

  test('an empty query matches every contact and keeps the tie-break', () {
    final timed = [
      _contact('B', [0x01], lastSeen: DateTime.utc(2024, 1, 2)),
      _contact('A', [0x02], lastSeen: DateTime.utc(2024, 1, 3)),
    ];
    timed.sort(
      (a, b) => compareContactQueryRank(
        a,
        b,
        '',
        (a, b) => b.lastSeen.compareTo(a.lastSeen),
      ),
    );
    expect(timed.map((c) => c.name), ['A', 'B']);
  });

  test('a labeled key uses the same prefix, substring, then hash order', () {
    expect(
      rankLabeledKeyQuery(
        name: 'Review Radio',
        publicKeyHex: '6060abcd',
        query: 'my',
        aliases: ['My contact'],
      ),
      ContactQueryRank.namePrefix,
    );
    expect(
      rankLabeledKeyQuery(
        name: 'Review Radio',
        publicKeyHex: '6060abcd',
        query: 'radio',
        aliases: ['My contact'],
      ),
      ContactQueryRank.nameContains,
    );
    expect(
      rankLabeledKeyQuery(
        name: 'Review Radio',
        publicKeyHex: '6060abcd',
        query: '6060',
        aliases: ['My contact'],
      ),
      ContactQueryRank.keyPrefix,
    );
    expect(
      rankLabeledKeyQuery(
        name: 'Review Radio',
        publicKeyHex: '6060abcd',
        query: 'zzzz',
        aliases: ['My contact'],
      ),
      isNull,
    );
  });

  test('tie-break applies inside a rank, not across ranks', () {
    final olderPrefix = _contact('Acre Older', [
      0x01,
    ], lastSeen: DateTime.utc(2020));
    final newerSubstring = _contact('My Acre', [
      0x02,
    ], lastSeen: DateTime.utc(2024));
    final ranked = [newerSubstring, olderPrefix]
      ..sort(
        (a, b) => compareContactQueryRank(
          a,
          b,
          'acre',
          (a, b) => b.lastSeen.compareTo(a.lastSeen),
        ),
      );
    expect(ranked.map((c) => c.name), ['Acre Older', 'My Acre']);
  });
}
