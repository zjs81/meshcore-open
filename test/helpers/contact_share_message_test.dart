import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/contact_share_message.dart';

const _hex = '50ba28f599799142622d188469a63f3890d495cdcedd24239052abd364c0283d';

void main() {
  test('parses the official example', () {
    final s = parseContactShare('<$_hex:1:CC>')!;
    expect(s.publicKeyHex, _hex);
    expect(s.type, 1);
    expect(s.name, 'CC');
    expect(s.publicKey.length, 32);
    expect(s.shortKey, '50ba28...c0283d');
    final scanned = s.toScannedContact();
    expect(scanned.publicKey, s.publicKey);
    expect(scanned.type, 1);
    expect(scanned.name, 'CC');
  });

  test('round trip', () {
    final key = Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));
    final text = encodeContactShare(publicKey: key, type: 2, name: ' Hill ');
    final s = parseContactShare(text)!;
    expect(s.publicKey, key);
    expect(s.type, 2);
    expect(s.name, 'Hill');
  });

  test('encode strips angle brackets and newlines', () {
    final text = encodeContactShare(
      publicKey: Uint8List(32),
      type: 1,
      name: '<a>\nb\r',
    );
    expect(parseContactShare(text)!.name, 'ab');
  });

  test('uppercase hex is accepted and lowercased', () {
    final s = parseContactShare('<${_hex.toUpperCase()}:3:Room>')!;
    expect(s.publicKeyHex, _hex);
  });

  test('name may contain colons', () {
    expect(parseContactShare('<$_hex:1:a:b:c>')!.name, 'a:b:c');
  });

  test('surrounding whitespace is ignored', () {
    expect(parseContactShare('  \n<$_hex:4:S>\n ')!.type, 4);
  });

  test('rejects bad length, hex, type', () {
    expect(parseContactShare('<${_hex.substring(2)}:1:x>'), isNull);
    expect(parseContactShare('<${_hex}00:1:x>'), isNull);
    expect(parseContactShare('<${"zz${_hex.substring(2)}"}:1:x>'), isNull);
    expect(parseContactShare('<$_hex:0:x>'), isNull);
    expect(parseContactShare('<$_hex:5:x>'), isNull);
    expect(parseContactShare('<$_hex:12:x>'), isNull);
    expect(parseContactShare('<$_hex:a:x>'), isNull);
  });

  test('token among other words is not a share', () {
    expect(parseContactShare('look <$_hex:1:CC> here'), isNull);
    expect(parseContactShare('<$_hex:1:CC> hi'), isNull);
    expect(parseContactShare('hello'), isNull);
  });

  test('findContactShare locates a token inside copied text', () {
    final s = findContactShare('Alice: <$_hex:2:Hilltop Rpt>')!;
    expect(s.publicKeyHex, _hex);
    expect(s.type, 2);
    expect(s.name, 'Hilltop Rpt');
    expect(findContactShare('look <$_hex:1:CC> here')!.name, 'CC');
    expect(findContactShare('meshcore://abcdef'), isNull);
    expect(findContactShare('<$_hex:9:x>'), isNull);
  });
}
