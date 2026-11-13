import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/message_search.dart';

ChatSearchEntry _e(
  String id,
  String text, {
  String sender = 'Alice',
  String? translated,
  bool matchSender = false,
  int minute = 0,
}) => ChatSearchEntry(
  id: id,
  sender: sender,
  text: text,
  translatedText: translated,
  time: DateTime(2025, 1, 1, 12, minute),
  matchSender: matchSender,
);

void main() {
  test('matches case-insensitively', () {
    final r = searchEntries([_e('1', 'Hello World')], 'wORLD');
    expect(r.map((e) => e.id), ['1']);
  });

  test('matches translated text', () {
    final r = searchEntries([
      _e('1', 'hola', translated: 'hello there'),
    ], 'THERE');
    expect(r, hasLength(1));
  });

  test('sender matches only when matchSender is set', () {
    final entries = [
      _e('1', 'x', sender: 'Bobby', matchSender: true),
      _e('2', 'y', sender: 'Bobby'),
    ];
    expect(searchEntries(entries, 'bob').map((e) => e.id), ['1']);
  });

  test('results are newest first', () {
    final entries = [
      _e('1', 'ping', minute: 1),
      _e('2', 'nope', minute: 2),
      _e('3', 'ping', minute: 3),
    ];
    expect(searchEntries(entries, 'ping').map((e) => e.id), ['3', '1']);
  });

  test('empty or whitespace query yields no results', () {
    final entries = [_e('1', 'anything')];
    expect(searchEntries(entries, ''), isEmpty);
    expect(searchEntries(entries, '   '), isEmpty);
  });

  test('query is trimmed', () {
    expect(searchEntries([_e('1', 'abc def')], '  def '), hasLength(1));
  });
}
