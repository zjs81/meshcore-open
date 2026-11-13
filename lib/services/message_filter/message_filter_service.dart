import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/message_filter.dart';
import '../../storage/message_filter_store.dart';
import 'duplicate_tracker.dart';
import 'message_filter_text.dart';
import 'ngram_spam_classifier.dart';

/// Trains a spam model from a job (see [MessageFilterService.new]).
typedef SpamTrainer = Future<SpamModel?> Function(SpamTrainingJob job);

/// Decides whether incoming channel messages should be filtered, and owns the
/// filter's settings, user rules and the learned classifier.
///
/// Filtered messages are never deleted; callers only tag them with the
/// returned [FilterVerdict].
class MessageFilterService extends ChangeNotifier {
  MessageFilterService({
    MessageFilterStore? store,
    DateTime Function()? clock,
    DuplicateTracker? duplicateTracker,
    NgramSpamClassifier? classifier,
    SpamTrainer? trainer,
  }) : _trainer = trainer ?? _trainInBackground,
       _store = store ?? MessageFilterStore(),
       _clock = clock ?? DateTime.now,
       _tracker = duplicateTracker ?? DuplicateTracker(),
       _classifier = classifier ?? NgramSpamClassifier();

  /// Minimum classifier probability for a [FilterReason.learned] verdict.
  static const double learnedThreshold = 0.80;

  /// Spam taps needed before the learned classifier is consulted.
  static const int minSpamExamplesForLearning = 2;

  static const int maxSpamExamples = 200;
  static const int maxNotSpamExamples = 200;
  static const int maxRecentClean = 300;

  /// Longest text kept as a training example (longer text is truncated).
  static const int maxExampleTextLength = 500;

  /// Recent-clean entries buffered before they are written to storage.
  static const int _recentCleanSaveEvery = 10;

  /// Runs classifier training; a background isolate by default. Widget tests
  /// pass [trainInline], since an isolate's result is never delivered under
  /// the fake clock `testWidgets` runs on.
  final SpamTrainer _trainer;

  static Future<SpamModel?> _trainInBackground(SpamTrainingJob job) =>
      compute(NgramSpamClassifier.fitInBackground, job);

  /// Trains on the calling isolate. For tests.
  @visibleForTesting
  static Future<SpamModel?> trainInline(SpamTrainingJob job) async =>
      NgramSpamClassifier.fitInBackground(job);

  final MessageFilterStore _store;
  final DateTime Function() _clock;
  final DuplicateTracker _tracker;
  final NgramSpamClassifier _classifier;

  MessageFilterSettings _settings = MessageFilterSettings.defaults;
  List<FilterRule> _rules = <FilterRule>[];
  List<FilterExample> _spamExamples = <FilterExample>[];
  List<FilterExample> _hamExamples = <FilterExample>[];
  List<FilterExample> _recentClean = <FilterExample>[];
  int _unsavedCleanCount = 0;
  bool _disposed = false;

  /// A retrain is queued (see [_scheduleRetrainIfInactive]).
  bool _retrainPending = false;

  /// Bumped on each retrain; a background result for an older generation is
  /// discarded because newer examples have arrived since.
  int _trainGeneration = 0;
  Future<void> _training = Future<void>.value();

  int _rulesRevision = 0;

  static int _idCounter = 0;

  /// Unique-enough rule id: microsecond timestamp plus a process counter.
  static String newRuleId() {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final counter = (_idCounter++).toRadixString(36);
    return 'r$micros$counter';
  }

  MessageFilterSettings get settings => _settings;

  /// Changes whenever rules are added, edited or removed, so listeners can
  /// re-apply rules to messages already stored.
  int get rulesRevision => _rulesRevision;

  /// Completes when the most recently started classifier training has been
  /// applied (or discarded).
  Future<void> get trainingSettled => _training;
  List<FilterRule> get rules => List.unmodifiable(_rules);
  int get spamExampleCount => _spamExamples.length;
  int get notSpamExampleCount => _hamExamples.length;

  /// Implicit "not spam" examples currently remembered (for tests).
  @visibleForTesting
  int get recentCleanCount => _recentClean.length;

  @visibleForTesting
  bool hasRecentCleanExample(String text) {
    final key = MessageFilterText.normalize(text);
    return _recentClean.any(
      (example) => MessageFilterText.normalize(example.text) == key,
    );
  }

  /// Loads persisted state and trains the classifier.
  Future<void> load() async {
    try {
      _settings = _store.loadSettings();
      _rules = _store.loadRules();
      _spamExamples = _store.loadSpamExamples();
      _hamExamples = _store.loadHamExamples();
      _recentClean = _store.loadRecentClean();
    } catch (e) {
      debugPrint('MessageFilterService: load failed: $e');
    }
    _trimToCap(_spamExamples, maxSpamExamples);
    _trimToCap(_hamExamples, maxNotSpamExamples);
    _trimToCap(_recentClean, maxRecentClean);
    _unsavedCleanCount = 0;
    // Training runs in the background so app start-up does not wait for it.
    unawaited(_retrain());
    _notify();
  }

  /// Whether filtering applies to [channelId] (master switch on and the
  /// channel not excluded).
  bool isChannelFiltered(String channelId) =>
      _settings.enabled && !_settings.excludedChannelIds.contains(channelId);

  /// Evaluates an incoming channel message. Returns a verdict when the message
  /// should be filtered, otherwise null. Records the text for duplicate
  /// detection whenever the message is eligible for filtering at all.
  ///
  /// [sentAt] is the message's own timestamp. Duplicate windows are measured
  /// between send times, so history synced in a burst after reconnecting is
  /// not mistaken for a flood; without it the local clock is used.
  ///
  /// Messages addressed to someone ([isReply], or an `@[name]` mention in
  /// [text]) are exempt from duplicate detection and not recorded for it:
  /// asking several people the same thing is conversation, not a repeat.
  FilterVerdict? evaluate({
    required String channelId,
    required String sender,
    required String text,
    DateTime? sentAt,
    bool isOutgoing = false,
    bool isReaction = false,
    bool isReply = false,
  }) {
    if (!isChannelFiltered(channelId)) return null;
    if (isOutgoing || isReaction) return null;
    if (text.trim().isEmpty) return null;
    if (MessageFilterText.isStructuredPayload(text)) return null;

    // Always record (even when a rule matches) so floods keep being caught.
    final mentionsSomeone = isReply || MessageFilterText.hasMention(text);
    final duplicateReason = mentionsSomeone
        ? null
        : _tracker.check(
            channelId: channelId,
            sender: sender,
            text: text,
            at: sentAt ?? _clock(),
            receivedAt: _clock(),
            sameSenderSends: _settings.repeatSends,
          );

    final byRule = _matchRules(sender, text);
    if (byRule != null) return byRule;

    if (_settings.repeatedCharacters &&
        MessageFilterText.hasRepeatedCharacters(text)) {
      return const FilterVerdict(reason: FilterReason.repeatedCharacters);
    }

    if (_settings.duplicates && duplicateReason != null) {
      return FilterVerdict(reason: duplicateReason);
    }

    if (_settings.learning &&
        _spamExamples.length >= minSpamExamplesForLearning &&
        _classifier.isTrained &&
        !_tracker.isAllowed(channelId, text)) {
      final probability = _classifier.probability(sender, text);
      if (probability >= learnedThreshold) {
        return const FilterVerdict(reason: FilterReason.learned);
      }
    }
    return null;
  }

  /// The user-rule verdict for a message already stored, or null when no
  /// enabled rule matches or [channelId] is not filtered. Unlike [evaluate]
  /// it does not record anything, so it can be re-run over stored history
  /// when the rules change.
  FilterVerdict? ruleVerdict({
    required String channelId,
    required String sender,
    required String text,
  }) {
    if (!isChannelFiltered(channelId)) return null;
    if (text.trim().isEmpty || MessageFilterText.isStructuredPayload(text)) {
      return null;
    }
    return _matchRules(sender, text);
  }

  FilterVerdict? _matchRules(String sender, String text) {
    for (final rule in _rules) {
      if (!rule.enabled || rule.field == FilterRuleField.text) continue;
      if (MessageFilterText.matchesSender(rule, sender)) {
        return FilterVerdict(
          reason: FilterReason.senderRule,
          detail: rule.pattern,
        );
      }
    }
    for (final rule in _rules) {
      if (!rule.enabled || rule.field == FilterRuleField.sender) continue;
      if (MessageFilterText.matchesText(rule, text)) {
        return FilterVerdict(
          reason: FilterReason.textRule,
          detail: rule.pattern,
        );
      }
    }
    return null;
  }

  /// Remembers an unfiltered incoming message in [channelId] as an implicit
  /// "not spam" training example (rolling buffer of [maxRecentClean]).
  ///
  /// Channels excluded from filtering are skipped: the user has stopped
  /// judging them, so their unfiltered messages (spam included) say nothing
  /// about what is clean.
  void recordClean({
    required String channelId,
    required String sender,
    required String text,
  }) {
    if (!isChannelFiltered(channelId) || !_settings.learning) return;
    if (text.trim().isEmpty || MessageFilterText.isStructuredPayload(text)) {
      return;
    }
    final example = _example(sender, text);
    if (_recentClean.isNotEmpty) {
      final last = _recentClean.last;
      if (last.sender == example.sender && last.text == example.text) return;
    }
    _recentClean.add(example);
    _trimToCap(_recentClean, maxRecentClean);
    _unsavedCleanCount++;
    if (_unsavedCleanCount >= _recentCleanSaveEvery) {
      _saveRecentClean();
    }
    _scheduleRetrainIfInactive();
  }

  /// The classifier needs both spam and clean examples to train. When the
  /// user has marked enough spam but training had no clean examples yet (for
  /// example the first messages received were the ones marked), it stays
  /// untrained; the first clean example to arrive afterwards activates it.
  /// Runs once, as a microtask, so message intake is not blocked and a burst
  /// of clean messages trains a single time.
  void _scheduleRetrainIfInactive() {
    if (_retrainPending || _classifier.isTrained) return;
    if (_spamExamples.length < minSpamExamplesForLearning) return;
    _retrainPending = true;
    scheduleMicrotask(() {
      if (_disposed || _classifier.isTrained) {
        _retrainPending = false;
        return;
      }
      _retrain().whenComplete(() => _retrainPending = false);
    });
  }

  /// User tapped "Spam": store the example and retrain.
  Future<void> markSpam({required String sender, required String text}) =>
      markSpamMany([(sender: sender, text: text)]);

  /// Marks several messages as spam with one save and one retrain (bulk
  /// selection in a chat).
  Future<void> markSpamMany(
    List<({String sender, String text})> messages,
  ) async {
    var changed = false;
    for (final m in messages) {
      final key = MessageFilterText.normalize(m.text);
      if (key.isEmpty) continue;
      _recentClean.removeWhere(
        (e) => MessageFilterText.normalize(e.text) == key,
      );
      _hamExamples.removeWhere(
        (e) => MessageFilterText.normalize(e.text) == key,
      );
      _addExample(_spamExamples, _example(m.sender, m.text), maxSpamExamples);
      changed = true;
    }
    if (!changed) return;
    final training = _retrain();
    _notify();
    await _guardSave(() async {
      await _store.saveSpamExamples(_spamExamples);
      await _store.saveHamExamples(_hamExamples);
      await _flushRecentClean();
    });
    await training;
  }

  /// User tapped "Not spam": store the example, exempt this text in this
  /// channel from duplicate and learned hits for the session, and retrain.
  Future<void> markNotSpam({
    required String channelId,
    required String sender,
    required String text,
  }) => markNotSpamMany([(channelId: channelId, sender: sender, text: text)]);

  /// Marks several messages as not spam with one save and one retrain.
  Future<void> markNotSpamMany(
    List<({String channelId, String sender, String text})> messages,
  ) async {
    var changed = false;
    for (final m in messages) {
      _tracker.allow(m.channelId, m.text);
      final key = MessageFilterText.normalize(m.text);
      if (key.isEmpty) continue;
      _spamExamples.removeWhere(
        (e) => MessageFilterText.normalize(e.text) == key,
      );
      _addExample(_hamExamples, _example(m.sender, m.text), maxNotSpamExamples);
      changed = true;
    }
    if (!changed) {
      _notify();
      return;
    }
    final training = _retrain();
    _notify();
    await _guardSave(() async {
      await _store.saveSpamExamples(_spamExamples);
      await _store.saveHamExamples(_hamExamples);
    });
    await training;
  }

  Future<void> updateSettings(MessageFilterSettings settings) async {
    final learningTurnedOn = settings.learning && !_settings.learning;
    _settings = settings;
    final training = learningTurnedOn ? _retrain() : null;
    _notify();
    await _guardSave(() => _store.saveSettings(_settings));
    if (training != null) await training;
  }

  Future<void> setChannelExcluded(String channelId, bool excluded) async {
    final current = _settings.excludedChannelIds;
    if (current.contains(channelId) == excluded) return;
    final next = Set<String>.of(current);
    if (excluded) {
      next.add(channelId);
    } else {
      next.remove(channelId);
    }
    await updateSettings(_settings.copyWith(excludedChannelIds: next));
  }

  /// Adds [rule] (replacing any rule with the same id) at the end, or at
  /// [index] (clamped) when given, e.g. to undo a delete in place.
  Future<void> addRule(FilterRule rule, {int? index}) async {
    final others = _rules.where((r) => r.id != rule.id).toList();
    if (index == null) {
      others.add(rule);
    } else {
      others.insert(index.clamp(0, others.length), rule);
    }
    _rules = others;
    _rulesRevision++;
    _notify();
    await _guardSave(() => _store.saveRules(_rules));
  }

  Future<void> updateRule(FilterRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index < 0) {
      await addRule(rule);
      return;
    }
    _rules = List.of(_rules)..[index] = rule;
    _rulesRevision++;
    _notify();
    await _guardSave(() => _store.saveRules(_rules));
  }

  Future<void> removeRule(String id) async {
    final before = _rules.length;
    _rules = _rules.where((r) => r.id != id).toList();
    if (_rules.length == before) return;
    _rulesRevision++;
    _notify();
    await _guardSave(() => _store.saveRules(_rules));
  }

  /// Forgets all Spam / Not spam taps and implicit examples. Rules are kept.
  Future<void> resetLearning() async {
    _spamExamples = <FilterExample>[];
    _hamExamples = <FilterExample>[];
    _recentClean = <FilterExample>[];
    _unsavedCleanCount = 0;
    _trainGeneration++; // drop any training still running
    _classifier.reset();
    _notify();
    await _guardSave(() async {
      await _store.saveSpamExamples(_spamExamples);
      await _store.saveHamExamples(_hamExamples);
      await _store.saveRecentClean(_recentClean);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    if (_unsavedCleanCount > 0) _saveRecentClean();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  FilterExample _example(String sender, String text) {
    final trimmed = text.trim();
    return FilterExample(
      sender: sender,
      text: trimmed.length > maxExampleTextLength
          ? trimmed.substring(0, maxExampleTextLength)
          : trimmed,
      addedAtMs: _clock().millisecondsSinceEpoch,
    );
  }

  /// Adds [example] as the newest entry, replacing an identical one.
  static void _addExample(
    List<FilterExample> list,
    FilterExample example,
    int cap,
  ) {
    final key = MessageFilterText.normalize(example.text);
    final sender = MessageFilterText.normalize(example.sender);
    list.removeWhere(
      (e) =>
          MessageFilterText.normalize(e.text) == key &&
          MessageFilterText.normalize(e.sender) == sender,
    );
    list.add(example);
    _trimToCap(list, cap);
  }

  static void _trimToCap(List<FilterExample> list, int cap) {
    if (list.length > cap) list.removeRange(0, list.length - cap);
  }

  /// Retrains from the current examples in a background isolate (training
  /// is up to ~700 documents x 200 SGD epochs, too slow for the UI thread).
  /// The previous model keeps scoring until the new one is ready. Completes
  /// once the result is applied, or discarded because a newer retrain or a
  /// reset started meanwhile.
  Future<void> _retrain() {
    final generation = ++_trainGeneration;
    if (_spamExamples.isEmpty) {
      _classifier.reset();
      return _training = Future<void>.value();
    }
    final job = _classifier.trainingJob(List.of(_spamExamples), [
      ..._hamExamples,
      ..._recentClean,
    ]);
    final stopwatch = Stopwatch()..start();
    return _training = _trainer(job)
        .then((model) {
          if (_disposed || generation != _trainGeneration) return;
          if (stopwatch.elapsedMilliseconds > 1000) {
            debugPrint(
              'MessageFilterService: classifier training took '
              '${stopwatch.elapsedMilliseconds} ms',
            );
          }
          if (model == null) {
            _classifier.reset();
          } else {
            _classifier.use(model);
          }
          _notify();
        })
        .catchError((Object e) {
          debugPrint('MessageFilterService: training failed: $e');
        });
  }

  Future<void> _flushRecentClean() async {
    _unsavedCleanCount = 0;
    await _store.saveRecentClean(_recentClean);
  }

  void _saveRecentClean() {
    _guardSave(_flushRecentClean);
  }

  Future<void> _guardSave(Future<void> Function() save) async {
    try {
      await save();
    } catch (e) {
      debugPrint('MessageFilterService: save failed: $e');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
