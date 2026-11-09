import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/services/message_filter/message_filter_service.dart';
import 'package:meshcore_open/storage/message_filter_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = 'chan1';

const _chat = [
  'Good morning everyone',
  'Anyone hearing the repeater on the hill today?',
  'I just got back from the hike, signal was great',
  'Testing from the north side of town',
  'Thanks for the advert, I can see you now',
  'How many hops is your path to the city?',
  'Weather looks rough tonight, stay safe',
  'My battery is at 40 percent after two days',
  'Who is running the new solar node?',
  'Copy that, heard you loud and clear',
  'Is the meetup still on for Saturday?',
  'Yes, 10am at the library parking lot',
  'I moved my antenna higher, let me know if it helps',
  'Reception improved a lot, thanks',
  'Lunch break, back in an hour',
  'Does anyone have a spare LoRa board to lend?',
  'Ping from the coffee shop downtown',
  'See you all tomorrow',
  'Happy birthday Carol!',
  'Can someone check if my messages are getting through?',
];

void main() {
  late DateTime now;
  late MessageFilterService service;

  Future<MessageFilterService> create() async {
    final s = MessageFilterService(
      store: MessageFilterStore(),
      clock: () => now,
    );
    await s.load();
    return s;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    now = DateTime(2026, 1, 1, 12);
    service = await create();
  });

  FilterVerdict? eval(
    String sender,
    String text, {
    String channel = _channel,
  }) => service.evaluate(channelId: channel, sender: sender, text: text);

  test('defaults: enabled, nothing filtered for normal chat', () {
    expect(service.settings.enabled, isTrue);
    expect(service.settings.displayMode, FilterDisplayMode.placeholder);
    expect(service.isChannelFiltered(_channel), isTrue);
    expect(eval('Bob', 'hello there'), isNull);
  });

  test('no implicit clean examples from excluded channels', () async {
    await service.setChannelExcluded('ads', true);
    final before = service.recentCleanCount;
    service.recordClean(
      channelId: 'ads',
      sender: 'Bot',
      text: 'Buy cheap radios today at the store',
    );
    expect(service.recentCleanCount, before);
    service.recordClean(
      channelId: _channel,
      sender: 'Sam',
      text: 'Anyone on the hill repeater tonight?',
    );
    expect(service.recentCleanCount, before + 1);
  });

  test('ruleVerdict matches rules without recording duplicates', () async {
    await service.addRule(const FilterRule(id: 'r', pattern: 'meshos'));
    expect(
      service
          .ruleVerdict(channelId: _channel, sender: 'a', text: 'get meshos')
          ?.reason,
      FilterReason.textRule,
    );
    expect(
      service.ruleVerdict(channelId: _channel, sender: 'a', text: 'hello'),
      isNull,
    );
    await service.setChannelExcluded('off', true);
    expect(
      service.ruleVerdict(channelId: 'off', sender: 'a', text: 'get meshos'),
      isNull,
    );
    // Nothing was recorded: the first real arrival is not a repeat.
    const text = 'meet at the old fire tower at noon';
    for (var i = 0; i < 3; i++) {
      service.ruleVerdict(channelId: _channel, sender: 'a', text: text);
    }
    expect(eval('a', text), isNull);
  });

  test('skips outgoing, reactions, payloads, disabled and excluded', () async {
    await service.addRule(
      FilterRule(id: MessageFilterService.newRuleId(), pattern: 'bad'),
    );
    expect(
      service.evaluate(
        channelId: _channel,
        sender: 'me',
        text: 'bad',
        isOutgoing: true,
      ),
      isNull,
    );
    expect(
      service.evaluate(
        channelId: _channel,
        sender: 'a',
        text: 'bad',
        isReaction: true,
      ),
      isNull,
    );
    expect(eval('a', 'g:bad-gif'), isNull);
    expect(eval('a', 'm:bad'), isNull);

    await service.setChannelExcluded(_channel, true);
    expect(service.isChannelFiltered(_channel), isFalse);
    expect(eval('a', 'bad'), isNull);
    expect(eval('a', 'bad', channel: 'other')?.reason, FilterReason.textRule);

    await service.setChannelExcluded(_channel, false);
    await service.updateSettings(service.settings.copyWith(enabled: false));
    expect(eval('a', 'bad'), isNull);
  });

  test(
    'sender rules win over text rules; disabled rules are ignored',
    () async {
      await service.addRule(
        const FilterRule(
          id: 't',
          pattern: 'promo',
          field: FilterRuleField.text,
        ),
      );
      await service.addRule(
        const FilterRule(
          id: 's',
          pattern: 'Spammer',
          field: FilterRuleField.sender,
          match: FilterRuleMatch.exact,
        ),
      );
      expect(
        eval('spammer', 'promo time'),
        const FilterVerdict(reason: FilterReason.senderRule, detail: 'Spammer'),
      );
      expect(
        eval('Bob', 'big PROMO'),
        const FilterVerdict(reason: FilterReason.textRule, detail: 'promo'),
      );
      await service.updateRule(
        const FilterRule(id: 't', pattern: 'promo', enabled: false),
      );
      expect(eval('Bob', 'another promo'), isNull);
      await service.removeRule('s');
      expect(service.rules.map((r) => r.id), ['t']);
    },
  );

  test('repeated characters, togglable', () async {
    expect(eval('a', 'n${'o' * 20}')?.reason, FilterReason.repeatedCharacters);
    expect(eval('a', 'nooooooooo'), isNull);
    await service.updateSettings(
      service.settings.copyWith(repeatedCharacters: false),
    );
    expect(eval('b', 'ye${'s' * 20}'), isNull);
  });

  test('duplicates: same sender and cross sender', () {
    expect(eval('a', 'meet at the park'), isNull);
    now = now.add(const Duration(minutes: 2));
    expect(
      eval('a', 'Meet at the park!'),
      const FilterVerdict(reason: FilterReason.duplicate),
    );
    const campaign = 'the meshcore trademark grab is theft, boycott him';
    expect(eval('b', campaign), isNull);
    expect(eval('d', campaign), isNull);
    expect(eval('c', campaign)?.reason, FilterReason.crossSenderDuplicate);
    // Short greetings from several senders are left alone.
    expect(eval('e', 'Happy New Year!'), isNull);
    expect(eval('f', 'Happy New Year!'), isNull);
    expect(eval('g', 'Happy New Year!'), isNull);
  });

  test('duplicates setting off still records but does not filter', () async {
    await service.updateSettings(service.settings.copyWith(duplicates: false));
    for (var i = 0; i < 3; i++) {
      expect(eval('a', 'meet at the park'), isNull);
      now = now.add(const Duration(minutes: 1));
    }
    await service.updateSettings(service.settings.copyWith(duplicates: true));
    expect(eval('a', 'meet at the park')?.reason, FilterReason.duplicate);
  });

  test('rule-filtered texts are still recorded for duplicates', () async {
    await service.addRule(const FilterRule(id: 'x', pattern: 'buy'));
    expect(
      eval('a', 'buy cheap radios here now')?.reason,
      FilterReason.textRule,
    );
    now = now.add(const Duration(minutes: 1));
    expect(
      eval('a', 'buy cheap radios here now')?.reason,
      FilterReason.textRule,
    );
    await service.removeRule('x');
    now = now.add(const Duration(minutes: 1));
    expect(
      eval('a', 'buy cheap radios here now')?.reason,
      FilterReason.duplicate,
    );
  });

  test('repeatSends setting picks which send is flagged', () async {
    await service.updateSettings(service.settings.copyWith(repeatSends: 3));
    expect(eval('a', 'meet at the park'), isNull);
    now = now.add(const Duration(minutes: 1));
    expect(eval('a', 'meet at the park'), isNull);
    now = now.add(const Duration(minutes: 1));
    expect(eval('a', 'meet at the park')?.reason, FilterReason.duplicate);
  });

  test('repeatSends is saved and clamped', () {
    const settings = MessageFilterSettings(repeatSends: 4);
    expect(MessageFilterSettings.fromJson(settings.toJson()).repeatSends, 4);
    expect(MessageFilterSettings.fromJson({}).repeatSends, 2);
    expect(MessageFilterSettings.fromJson({'repeatSends': 99}).repeatSends, 5);
    expect(MessageFilterSettings.fromJson({'repeatSends': 0}).repeatSends, 2);
  });

  test('messages that mention someone are exempt from duplicates', () {
    for (var i = 0; i < 4; i++) {
      // Asking several people the same thing.
      expect(eval('a', '@[Person$i] are you home yet'), isNull);
      expect(
        service.evaluate(
          channelId: _channel,
          sender: 'b',
          text: 'did you get my message',
          isReply: true,
        ),
        isNull,
      );
      now = now.add(const Duration(minutes: 1));
    }
    // Mentions were not recorded, so the plain text starts fresh.
    expect(eval('a', 'are you home yet'), isNull);
  });

  test('not spam exempts duplicates in that channel', () async {
    eval('a', 'meet at the park');
    await service.markNotSpam(
      channelId: _channel,
      sender: 'a',
      text: 'meet at the park',
    );
    expect(eval('a', 'meet at the park'), isNull);
    expect(service.notSpamExampleCount, 1);
  });

  test('learning needs two spam taps, then catches similar promos', () async {
    for (var i = 0; i < _chat.length; i++) {
      service.recordClean(channelId: 'chat', sender: 'User$i', text: _chat[i]);
    }
    await service.markSpam(
      sender: 'PromoBot',
      text: 'Download MeshOS now! Free firmware at meshos.example',
    );
    expect(service.spamExampleCount, 1);
    expect(
      eval('X', 'Free MeshOS firmware download at meshos.example'),
      isNull,
    );

    await service.markSpam(
      sender: 'Deals',
      text: 'Free MeshOS firmware upgrade, download at meshos.example now',
    );
    expect(service.spamExampleCount, 2);
    expect(
      eval('Y', 'Get free MeshOS firmware download now meshos.example')?.reason,
      FilterReason.learned,
    );
    expect(eval('Z', 'Anyone on the hill repeater tonight?'), isNull);

    await service.updateSettings(service.settings.copyWith(learning: false));
    expect(
      eval('W', 'Get the MeshOS firmware download free meshos.example'),
      isNull,
    );
  });

  test('marking spam twice for the same text keeps one example', () async {
    await service.markSpam(sender: 'a', text: 'Buy now');
    await service.markSpam(sender: 'a', text: 'buy  NOW');
    expect(service.spamExampleCount, 1);
    await service.markNotSpam(
      channelId: _channel,
      sender: 'a',
      text: 'buy now',
    );
    expect(service.spamExampleCount, 0);
    expect(service.notSpamExampleCount, 1);
  });

  test('bulk spam and not-spam store every example and persist', () async {
    await service.markSpamMany([
      (sender: 'a', text: 'Buy now'),
      (sender: 'b', text: 'Free crypto'),
      (sender: 'c', text: '   '),
    ]);
    expect(service.spamExampleCount, 2);

    await service.markNotSpamMany([
      (channelId: _channel, sender: 'a', text: 'buy now'),
      (channelId: _channel, sender: 'd', text: 'Hello all'),
    ]);
    expect(service.spamExampleCount, 1);
    expect(service.notSpamExampleCount, 2);

    final reloaded = await create();
    expect(reloaded.spamExampleCount, 1);
    expect(reloaded.notSpamExampleCount, 2);
  });

  test('state persists across instances and reset keeps rules', () async {
    await service.addRule(const FilterRule(id: 'r1', pattern: 'promo'));
    await service.updateSettings(
      service.settings.copyWith(displayMode: FilterDisplayMode.hide),
    );
    await service.markSpam(sender: 'a', text: 'spam one');
    await service.markNotSpam(channelId: _channel, sender: 'b', text: 'hi');

    final reloaded = await create();
    expect(reloaded.rules.single.pattern, 'promo');
    expect(reloaded.settings.displayMode, FilterDisplayMode.hide);
    expect(reloaded.spamExampleCount, 1);
    expect(reloaded.notSpamExampleCount, 1);

    await reloaded.resetLearning();
    expect(reloaded.spamExampleCount, 0);
    expect(reloaded.notSpamExampleCount, 0);
    expect(reloaded.rules, hasLength(1));
    final again = await create();
    expect(again.spamExampleCount, 0);
    expect(again.rules, hasLength(1));
  });

  test('notifies listeners on changes', () async {
    var count = 0;
    service.addListener(() => count++);
    await service.addRule(const FilterRule(id: 'n', pattern: 'x'));
    await service.markSpam(sender: 'a', text: 'b');
    await service.setChannelExcluded('c', true);
    // addRule, markSpam (plus once more when its background training lands)
    // and setChannelExcluded.
    expect(count, 4);
  });

  test('addRule with index restores a deleted rule in place', () async {
    for (final id in ['a', 'b', 'c']) {
      await service.addRule(FilterRule(id: id, pattern: id));
    }
    final b = service.rules[1];
    await service.removeRule('b');
    await service.addRule(b, index: 1);
    expect(service.rules.map((r) => r.id), ['a', 'b', 'c']);
    await service.addRule(const FilterRule(id: 'z', pattern: 'z'), index: 99);
    expect(service.rules.last.id, 'z');
  });

  test('newRuleId is unique', () {
    final ids = List.generate(100, (_) => MessageFilterService.newRuleId());
    expect(ids.toSet(), hasLength(100));
  });

  test(
    'learning activates once clean examples arrive after spam taps',
    () async {
      // The first two messages received are the ones marked spam, so training
      // has no clean examples yet and the classifier stays inactive.
      await service.markSpam(
        sender: 'PromoBot',
        text: 'Download MeshOS now! Free firmware at meshos.example',
      );
      await service.markSpam(
        sender: 'Deals',
        text: 'Free MeshOS firmware upgrade, download at meshos.example now',
      );
      const probe = 'Get free MeshOS firmware download now meshos.example';
      expect(eval('A', probe), isNull);

      // Ordinary chat then arrives; no further taps.
      for (var i = 0; i < _chat.length; i++) {
        service.recordClean(
          channelId: 'chat',
          sender: 'User$i',
          text: _chat[i],
        );
      }
      await Future<void>.delayed(Duration.zero); // let the queued retrain start
      await service.trainingSettled;
      expect(eval('B', probe)?.reason, FilterReason.learned);
      expect(eval('C', 'Anyone on the hill repeater tonight?'), isNull);
    },
  );
}
