const Object _channelGroupUnset = Object();

class ChannelGroup {
  final String name;
  final List<int> channelIndexes;
  final int sortOrder;
  final int? widgetColor;
  final int? widgetTextColor;
  final bool allowOrderingInGroup;

  const ChannelGroup({
    required this.name,
    required this.channelIndexes,
    this.sortOrder = 0,
    this.widgetColor,
    this.widgetTextColor,
    this.allowOrderingInGroup = false,
  });

  ChannelGroup copyWith({
    String? name,
    List<int>? channelIndexes,
    int? sortOrder,
    Object? widgetColor = _channelGroupUnset,
    Object? widgetTextColor = _channelGroupUnset,
    bool? allowOrderingInGroup,
  }) {
    return ChannelGroup(
      name: name ?? this.name,
      channelIndexes: channelIndexes ?? List<int>.from(this.channelIndexes),
      sortOrder: sortOrder ?? this.sortOrder,
      widgetColor: widgetColor == _channelGroupUnset
          ? this.widgetColor
          : widgetColor as int?,
      widgetTextColor: widgetTextColor == _channelGroupUnset
          ? this.widgetTextColor
          : widgetTextColor as int?,
      allowOrderingInGroup: allowOrderingInGroup ?? this.allowOrderingInGroup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'channels': channelIndexes,
      'sort_order': sortOrder,
      'widget_color': widgetColor,
      'widget_text_color': widgetTextColor,
      'allow_ordering_in_group': allowOrderingInGroup,
    };
  }

  factory ChannelGroup.fromJson(Map<String, dynamic> json) {
    final channels =
        (json['channels'] as List?)
            ?.map((value) => int.tryParse(value.toString()))
            .whereType<int>()
            .toList() ??
        <int>[];
    return ChannelGroup(
      name: json['name'] as String? ?? '',
      channelIndexes: channels,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? -1,
      widgetColor: int.tryParse(json['widget_color']?.toString() ?? ''),
      widgetTextColor: int.tryParse(
        json['widget_text_color']?.toString() ?? '',
      ),
      allowOrderingInGroup:
          json['allow_ordering_in_group'] == true ||
          json['allow_ordering_in_group']?.toString() == 'true',
    );
  }
}
