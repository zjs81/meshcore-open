import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  bool mentions(String text, String? name) =>
      MeshCoreConnector.textMentionsName(text, name);

  test('matches bracketed and plain mentions case-insensitively', () {
    expect(mentions('@[Bob] hello', 'Bob'), isTrue);
    expect(mentions('hey @[bob]', 'Bob'), isTrue);
    expect(mentions('hey @bob, look', 'Bob'), isTrue);
    expect(mentions('@BOB', 'Bob'), isTrue);
    expect(mentions('ping @Иван!', 'иван'), isTrue);
  });

  test('requires a word boundary for plain mentions', () {
    expect(mentions('hey @bobby', 'Bob'), isFalse);
    expect(mentions('mail x@bob.com', 'Bob'), isFalse);
    expect(mentions('hey bob', 'Bob'), isFalse);
  });

  test('names with spaces or regex characters must match in full', () {
    expect(mentions('hi @Bob Smith', 'Bob Smith'), isTrue);
    expect(mentions('hi @Bob', 'Bob Smith'), isFalse);
    expect(mentions('@[Node (1)] ok', 'Node (1)'), isTrue);
    expect(mentions('@[Node 1] ok', 'Node (1)'), isFalse);
  });

  test('no self name never matches', () {
    expect(mentions('@[Bob] hi', null), isFalse);
    expect(mentions('@ hi', ''), isFalse);
  });
}
