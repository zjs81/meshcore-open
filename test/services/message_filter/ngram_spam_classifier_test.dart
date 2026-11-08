import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/services/message_filter/ngram_spam_classifier.dart';

FilterExample _ex(String sender, String text) =>
    FilterExample(sender: sender, text: text, addedAtMs: 0);

final _spam = [
  _ex(
    'PromoBot',
    'Download MeshOS now! Free firmware upgrade at meshos.example',
  ),
  _ex(
    'MeshDeals',
    'FREE upgrade!!! Get MeshOS firmware today, visit meshos.example',
  ),
  _ex(
    'PromoBot',
    'Best firmware ever: MeshOS. Download free at meshos.example now',
  ),
  _ex('Promo2', 'Limited offer: MeshOS firmware download free, meshos.example'),
  _ex(
    'MeshDeals',
    'Upgrade your node with MeshOS! Free download at meshos.example',
  ),
  _ex('Promo3', 'Get the free MeshOS firmware now - meshos.example download'),
];

final _ham = [
  _ex('Alice', 'Good morning everyone'),
  _ex('Bob', 'Anyone hearing the repeater on the hill today?'),
  _ex('Carol', 'I just got back from the hike, signal was great'),
  _ex('Dave', 'Testing from the north side of town'),
  _ex('Alice', 'Thanks for the advert, I can see you now'),
  _ex('Eve', 'How many hops is your path to the city?'),
  _ex('Bob', 'Weather looks rough tonight, stay safe'),
  _ex('Frank', 'My battery is at 40 percent after two days'),
  _ex('Carol', 'Who is running the new solar node?'),
  _ex('Dave', 'Copy that, heard you loud and clear'),
  _ex('Grace', 'Is the meetup still on for Saturday?'),
  _ex('Heidi', 'Yes, 10am at the library parking lot'),
  _ex('Ivan', 'I moved my antenna higher, let me know if it helps'),
  _ex('Judy', 'Reception improved a lot, thanks'),
  _ex('Alice', 'Lunch break, back in an hour'),
  _ex('Bob', 'Does anyone have a spare LoRa board to lend?'),
  _ex('Frank', 'Ping from the coffee shop downtown'),
  _ex('Grace', 'See you all tomorrow'),
  _ex('Eve', 'The traffic on the highway is terrible right now'),
  _ex('Heidi', 'Happy birthday Carol!'),
  _ex('Ivan', 'Can someone check if my messages are getting through?'),
  _ex('Judy', 'Got it, three hops via the hill repeater'),
  _ex('Carol', 'Thank you all, great community here'),
  _ex('Dave', 'Power is out in my area, running on battery'),
  _ex('Alice', 'Nice sunset from the ridge'),
  _ex('Bob', 'Updating my node settings, brb'),
  _ex('Eve', 'Good night folks'),
  _ex('Frank', 'Anyone near the river trail?'),
  _ex('Grace', 'The new channel works well for our group'),
  _ex('Heidi', 'Is there a map of the repeaters somewhere?'),
];

void main() {
  test('untrained classifier returns 0', () {
    final classifier = NgramSpamClassifier();
    expect(classifier.isTrained, isFalse);
    expect(classifier.probability('x', 'anything'), 0.0);
  });

  test('needs both classes to train', () {
    final classifier = NgramSpamClassifier()..train(_spam, const []);
    expect(classifier.isTrained, isFalse);
  });

  test('FNV-1a 32 matches reference vectors', () {
    expect(NgramSpamClassifier.fnv1a32(''), 0x811C9DC5);
    expect(NgramSpamClassifier.fnv1a32('a'), 0xE40C292C);
    expect(NgramSpamClassifier.fnv1a32('foobar'), 0xBF9CF968);
  });

  test('feature strings include char n-grams, words, bigrams, sender', () {
    final features = NgramSpamClassifier.featureStrings('Bob', 'Hi there');
    expect(features, contains('c: hi '));
    expect(features, contains('c: th'));
    expect(features, contains('c:there'));
    expect(features, contains('w:there'));
    expect(features, contains('b:hi there'));
    expect(features, contains('s:bob'));
  });

  test('scores held-out promo high and ordinary chat low', () {
    final classifier = NgramSpamClassifier()..train(_spam, _ham);
    expect(classifier.isTrained, isTrue);

    final promo = classifier.probability(
      'NewPromo',
      'Free MeshOS firmware download now at meshos.example!',
    );
    expect(promo, greaterThanOrEqualTo(0.8));

    for (final text in [
      'Anyone on the hill repeater tonight?',
      'Good morning, heading out for a hike',
      'My node battery lasted three days',
      'See you at the meetup on Saturday',
    ]) {
      expect(classifier.probability('Zoe', text), lessThan(0.5), reason: text);
    }
  });

  test('look-alike characters do not dodge the classifier', () {
    final classifier = NgramSpamClassifier()..train(_spam, _ham);
    // Cyrillic "е"/"о" and a zero-width space.
    final p = classifier.probability(
      'NewPromo',
      'Frеe MeshОS firm​ware download now at meshos.example',
    );
    expect(p, greaterThanOrEqualTo(0.8));
  });

  test('training is deterministic', () {
    final a = NgramSpamClassifier()..train(_spam, _ham);
    final b = NgramSpamClassifier()..train(_spam, _ham);
    const text = 'free firmware download';
    expect(a.probability('x', text), b.probability('x', text));
  });

  test('trains 500 documents quickly', () {
    final spam = <FilterExample>[];
    final ham = <FilterExample>[];
    for (var i = 0; i < 200; i++) {
      final s = _spam[i % _spam.length];
      spam.add(_ex('${s.sender}$i', '${s.text} code $i'));
    }
    for (var i = 0; i < 300; i++) {
      final h = _ham[i % _ham.length];
      ham.add(_ex('${h.sender}$i', '${h.text} number $i'));
    }
    final classifier = NgramSpamClassifier();
    // Warm up the JIT once, then measure.
    classifier.train(spam.take(20).toList(), ham.take(20).toList());
    final stopwatch = Stopwatch()..start();
    classifier.train(spam, ham);
    stopwatch.stop();
    expect(classifier.isTrained, isTrue);
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
    // ignore: avoid_print
    print('Trained 500 docs in ${stopwatch.elapsedMilliseconds} ms');
  });
}
