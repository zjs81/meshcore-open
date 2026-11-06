/// Data types for the on-device channel message filter.
///
/// Everything here is plain data with JSON round-tripping; the matching logic
/// lives in `lib/services/message_filter/`.
library;

/// Which part of a message a [FilterRule] looks at.
enum FilterRuleField { text, sender, both }

/// How a [FilterRule] pattern is compared against the (normalized) target.
enum FilterRuleMatch { contains, wholeWord, exact }

/// How filtered messages are presented in the channel transcript.
enum FilterDisplayMode { placeholder, hide }

/// Why a message was filtered.
enum FilterReason {
  senderRule,
  textRule,
  repeatedCharacters,
  duplicate,
  crossSenderDuplicate,
  learned,
  manual,
}

String filterReasonToJson(FilterReason reason) => reason.name;

FilterReason? filterReasonFromJson(String? value) {
  if (value == null) return null;
  for (final reason in FilterReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

T _enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class FilterRule {
  final String id;
  final String pattern;
  final FilterRuleField field;
  final FilterRuleMatch match;
  final bool enabled;

  const FilterRule({
    required this.id,
    required this.pattern,
    this.field = FilterRuleField.text,
    this.match = FilterRuleMatch.contains,
    this.enabled = true,
  });

  FilterRule copyWith({
    String? id,
    String? pattern,
    FilterRuleField? field,
    FilterRuleMatch? match,
    bool? enabled,
  }) {
    return FilterRule(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      field: field ?? this.field,
      match: match ?? this.match,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pattern': pattern,
    'field': field.name,
    'match': match.name,
    'enabled': enabled,
  };

  factory FilterRule.fromJson(Map<String, dynamic> json) {
    return FilterRule(
      id: json['id'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      field: _enumFromName(
        FilterRuleField.values,
        json['field'],
        FilterRuleField.text,
      ),
      match: _enumFromName(
        FilterRuleMatch.values,
        json['match'],
        FilterRuleMatch.contains,
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FilterRule &&
      other.id == id &&
      other.pattern == pattern &&
      other.field == field &&
      other.match == match &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, pattern, field, match, enabled);
}

/// A labelled training example for the learned classifier.
class FilterExample {
  final String sender;
  final String text;
  final int addedAtMs;

  const FilterExample({
    required this.sender,
    required this.text,
    required this.addedAtMs,
  });

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'text': text,
    'addedAtMs': addedAtMs,
  };

  factory FilterExample.fromJson(Map<String, dynamic> json) {
    return FilterExample(
      sender: json['sender'] as String? ?? '',
      text: json['text'] as String? ?? '',
      addedAtMs: (json['addedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class MessageFilterSettings {
  final bool enabled;
  final FilterDisplayMode displayMode;
  final bool duplicates;
  final bool repeatedCharacters;
  final bool learning;
  final Set<String> excludedChannelIds;

  const MessageFilterSettings({
    this.enabled = true,
    this.displayMode = FilterDisplayMode.placeholder,
    this.duplicates = true,
    this.repeatedCharacters = true,
    this.learning = true,
    this.excludedChannelIds = const <String>{},
  });

  static const MessageFilterSettings defaults = MessageFilterSettings();

  MessageFilterSettings copyWith({
    bool? enabled,
    FilterDisplayMode? displayMode,
    bool? duplicates,
    bool? repeatedCharacters,
    bool? learning,
    Set<String>? excludedChannelIds,
  }) {
    return MessageFilterSettings(
      enabled: enabled ?? this.enabled,
      displayMode: displayMode ?? this.displayMode,
      duplicates: duplicates ?? this.duplicates,
      repeatedCharacters: repeatedCharacters ?? this.repeatedCharacters,
      learning: learning ?? this.learning,
      excludedChannelIds: excludedChannelIds ?? this.excludedChannelIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'displayMode': displayMode.name,
    'duplicates': duplicates,
    'repeatedCharacters': repeatedCharacters,
    'learning': learning,
    'excludedChannelIds': excludedChannelIds.toList()..sort(),
  };

  factory MessageFilterSettings.fromJson(Map<String, dynamic> json) {
    final excluded = json['excludedChannelIds'];
    return MessageFilterSettings(
      enabled: json['enabled'] as bool? ?? true,
      displayMode: _enumFromName(
        FilterDisplayMode.values,
        json['displayMode'],
        FilterDisplayMode.placeholder,
      ),
      duplicates: json['duplicates'] as bool? ?? true,
      repeatedCharacters: json['repeatedCharacters'] as bool? ?? true,
      learning: json['learning'] as bool? ?? true,
      excludedChannelIds: excluded is List
          ? excluded.whereType<String>().toSet()
          : const <String>{},
    );
  }
}

/// The outcome of evaluating a message that should be filtered.
class FilterVerdict {
  final FilterReason reason;
  final String? detail;

  const FilterVerdict({required this.reason, this.detail});

  @override
  bool operator ==(Object other) =>
      other is FilterVerdict &&
      other.reason == reason &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(reason, detail);

  @override
  String toString() => 'FilterVerdict($reason, $detail)';
}
