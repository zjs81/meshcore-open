import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/services/message_filter/message_filter_text.dart';

FilterRule _rule(
  String pattern, {
  FilterRuleField field = FilterRuleField.text,
  FilterRuleMatch match = FilterRuleMatch.contains,
}) => FilterRule(id: 'r', pattern: pattern, field: field, match: match);

void main() {
  group('normalize', () {
    test('lower-cases, collapses whitespace and trims', () {
      expect(
        MessageFilterText.normalize('  Hello \n\t  WORLD  '),
        'hello world',
      );
    });

    test('strips accents', () {
      expect(MessageFilterText.normalize('Ça vá Ñoño Öl'), 'ca va nono ol');
      // Decomposed form (combining marks).
      expect(MessageFilterText.normalize('Café'), 'cafe');
    });

    test('maps Cyrillic and Greek look-alikes to Latin', () {
      // Cyrillic М е о and Greek Ο.
      expect(MessageFilterText.normalize('Мeshоs'), 'meshos');
      expect(MessageFilterText.normalize('MeshΟS'), 'meshos');
    });

    test('removes zero-width and soft hyphen characters', () {
      expect(MessageFilterText.normalize('me​sh‌‍o⁠s﻿­'), 'meshos');
    });

    test('folds fullwidth and styled letters', () {
      expect(MessageFilterText.normalize('ＭＥＳＨ'), 'mesh');
      expect(MessageFilterText.normalize('\u{1D400}\u{1D41B}'), 'ab');
    });
  });

  group('normalizeForDuplicates', () {
    test('drops mentions, punctuation and emoji', () {
      expect(
        MessageFilterText.normalizeForDuplicates('@[Bob] Hello, world!!! 😀'),
        'hello world',
      );
      expect(
        MessageFilterText.normalizeForDuplicates('Hello world'),
        MessageFilterText.normalizeForDuplicates('hello... WORLD?'),
      );
    });
  });

  group('matchesRule', () {
    test('contains', () {
      final rule = _rule('MeshOS');
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'try meshos!'),
        isTrue,
      );
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'mesh os'),
        isFalse,
      );
    });

    test('whole word uses unicode boundaries', () {
      final rule = _rule('cat', match: FilterRuleMatch.wholeWord);
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'my cat!'),
        isTrue,
      );
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'Cat'),
        isTrue,
      );
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'category'),
        isFalse,
      );
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'catß'),
        isFalse,
      );
      final phrase = _rule('free (offer)', match: FilterRuleMatch.wholeWord);
      expect(
        MessageFilterText.matchesRule(
          phrase,
          sender: 'a',
          text: 'a FREE (offer) now',
        ),
        isTrue,
      );
    });

    test('exact', () {
      final rule = _rule('hello', match: FilterRuleMatch.exact);
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: '  HELLO '),
        isTrue,
      );
      expect(
        MessageFilterText.matchesRule(rule, sender: 'a', text: 'hello there'),
        isFalse,
      );
    });

    test('respects the field', () {
      final sender = _rule('spammer', field: FilterRuleField.sender);
      expect(
        MessageFilterText.matchesRule(sender, sender: 'Spammer', text: 'hi'),
        isTrue,
      );
      expect(
        MessageFilterText.matchesRule(sender, sender: 'bob', text: 'spammer'),
        isFalse,
      );
      final both = _rule('spammer', field: FilterRuleField.both);
      expect(
        MessageFilterText.matchesRule(both, sender: 'bob', text: 'spammer'),
        isTrue,
      );
      expect(
        MessageFilterText.matchesRule(both, sender: 'SPAMMER', text: 'hi'),
        isTrue,
      );
    });

    test('empty pattern never matches', () {
      expect(
        MessageFilterText.matchesRule(_rule('  '), sender: 'a', text: 'b'),
        isFalse,
      );
    });
  });

  test('repeated characters', () {
    expect(MessageFilterText.hasRepeatedCharacters('a' * 20), isTrue);
    expect(MessageFilterText.hasRepeatedCharacters('wow${'!' * 20}'), isTrue);
    expect(
      MessageFilterText.hasRepeatedCharacters('AAAAAAAAAA${'a' * 10}'),
      isTrue,
    );
    expect(MessageFilterText.hasRepeatedCharacters('😀' * 20), isTrue);
    expect(MessageFilterText.hasRepeatedCharacters('a' * 19), isFalse);
    // Ordinary chat that the old 8-character threshold caught.
    expect(MessageFilterText.hasRepeatedCharacters('Noooooooo!'), isFalse);
    expect(MessageFilterText.hasRepeatedCharacters('-' * 12), isFalse);
    expect(MessageFilterText.hasRepeatedCharacters('!!!!!!!!'), isFalse);
    expect(MessageFilterText.hasRepeatedCharacters('😀' * 8), isFalse);
    // Digit runs never count (frequencies, coordinates, ids).
    expect(MessageFilterText.hasRepeatedCharacters('0' * 30), isFalse);
    expect(
      MessageFilterText.hasRepeatedCharacters('hello        there'),
      isFalse,
    );
  });

  test('structured payloads', () {
    expect(MessageFilterText.isStructuredPayload('g:abc'), isTrue);
    expect(MessageFilterText.isStructuredPayload('  m:xyz'), isTrue);
    expect(MessageFilterText.isStructuredPayload('good morning'), isFalse);
  });
}
