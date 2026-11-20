import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/helpers/link_handler.dart';

void main() {
  const options = LinkifyOptions(humanize: false, defaultToHttps: false);

  List<LinkifyElement> parse(String text) {
    var elements = <LinkifyElement>[TextElement(text)];
    for (final linkifier in const [UrlLinkifier(), HashtagLinkifier()]) {
      elements = linkifier.parse(elements, options);
    }
    return elements;
  }

  List<String> hashtags(String text) =>
      parse(text).whereType<HashtagElement>().map((e) => e.text).toList();

  test('extracts the word after the hash until the space', () {
    expect(hashtags('#ops joins here'), ['ops']);
    expect(hashtags('join #ops now'), ['ops']);
    expect(hashtags('end on #tag'), ['tag']);
    expect(hashtags('two #one #two'), ['one', 'two']);
  });

  test('keeps surrounding text as plain elements', () {
    final elements = parse('join #ops now');
    expect(elements.length, 3);
    expect((elements[0] as TextElement).text, 'join ');
    expect((elements[1] as HashtagElement).text, 'ops');
    expect((elements[2] as TextElement).text, ' now');
  });

  test('numbers and word-joined hashes stay plain', () {
    expect(hashtags('#123'), isEmpty);
    expect(hashtags('abc#def'), isEmpty);
  });

  test('unicode letters are allowed', () {
    expect(hashtags('#túra #andä'), ['túra', 'andä']);
  });

  test('hashtag inside a URL fragment is not split out', () {
    final elements = parse('https://example.com/#frag');
    expect(elements.whereType<HashtagElement>(), isEmpty);
  });

  test('text without hashtags passes through untouched', () {
    final elements = parse('plain text');
    expect(elements.length, 1);
    expect((elements.single as TextElement).text, 'plain text');
  });
}
