import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/storage/message_filter_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _init(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  PrefsManager.reset();
  await PrefsManager.initialize();
}

void main() {
  test('empty prefs load defaults', () async {
    await _init({});
    final store = MessageFilterStore();
    final settings = store.loadSettings();
    expect(settings.enabled, isTrue);
    expect(settings.displayMode, FilterDisplayMode.placeholder);
    expect(settings.duplicates, isTrue);
    expect(settings.repeatedCharacters, isTrue);
    expect(settings.learning, isTrue);
    expect(settings.excludedChannelIds, isEmpty);
    expect(store.loadRules(), isEmpty);
    expect(store.loadSpamExamples(), isEmpty);
    expect(store.loadHamExamples(), isEmpty);
    expect(store.loadRecentClean(), isEmpty);
  });

  test('round-trips settings, rules and examples', () async {
    await _init({});
    final store = MessageFilterStore();
    await store.saveSettings(
      const MessageFilterSettings(
        enabled: false,
        displayMode: FilterDisplayMode.hide,
        duplicates: false,
        repeatedCharacters: false,
        learning: false,
        excludedChannelIds: {'a', 'slot:3'},
      ),
    );
    await store.saveRules(const [
      FilterRule(
        id: '1',
        pattern: 'MeshOS',
        field: FilterRuleField.both,
        match: FilterRuleMatch.wholeWord,
        enabled: false,
      ),
    ]);
    const example = FilterExample(sender: 's', text: 't', addedAtMs: 42);
    await store.saveSpamExamples(const [example]);
    await store.saveHamExamples(const [example, example]);
    await store.saveRecentClean(const [example]);

    final settings = store.loadSettings();
    expect(settings.enabled, isFalse);
    expect(settings.displayMode, FilterDisplayMode.hide);
    expect(settings.duplicates, isFalse);
    expect(settings.repeatedCharacters, isFalse);
    expect(settings.learning, isFalse);
    expect(settings.excludedChannelIds, {'a', 'slot:3'});
    expect(store.loadRules(), const [
      FilterRule(
        id: '1',
        pattern: 'MeshOS',
        field: FilterRuleField.both,
        match: FilterRuleMatch.wholeWord,
        enabled: false,
      ),
    ]);
    final spam = store.loadSpamExamples().single;
    expect((spam.sender, spam.text, spam.addedAtMs), ('s', 't', 42));
    expect(store.loadHamExamples(), hasLength(2));
    expect(store.loadRecentClean(), hasLength(1));
  });

  test('tolerates malformed data', () async {
    await _init({
      MessageFilterStore.settingsKey: '{not json',
      MessageFilterStore.rulesKey:
          '[{"id":"1","pattern":"ok","field":"weird","match":"nope"}, 5, '
          '{"id":"","pattern":"x"}]',
      MessageFilterStore.spamExamplesKey: '{"a":1}',
    });
    final store = MessageFilterStore();
    expect(store.loadSettings().enabled, isTrue);
    final rule = store.loadRules().single;
    expect(rule.pattern, 'ok');
    expect(rule.field, FilterRuleField.text);
    expect(rule.match, FilterRuleMatch.contains);
    expect(rule.enabled, isTrue);
    expect(store.loadSpamExamples(), isEmpty);
  });

  test('filter reason json helpers', () {
    for (final reason in FilterReason.values) {
      expect(filterReasonFromJson(filterReasonToJson(reason)), reason);
    }
    expect(filterReasonFromJson(null), isNull);
    expect(filterReasonFromJson('unknown'), isNull);
  });
}
