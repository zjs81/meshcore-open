import 'dart:async';

import 'package:flutter/foundation.dart';

import '../storage/prefs_manager.dart';
import '../utils/contact_search.dart';

const String contactsAllGroupsValue = '__all__';

enum ChannelSortOption { manual, name, latestMessages, unread }

class UiViewStateService extends ChangeNotifier {
  static const _keyContactsSelectedGroupName = 'ui_contacts_selected_group';
  static const _keyContactsSortOption = 'ui_contacts_sort_option';
  static const _keyContactsShowUnreadOnly = 'ui_contacts_show_unread_only';
  static const _keyContactsTypeFilter = 'ui_contacts_type_filter';
  static const _keyChannelsSortOption = 'ui_channels_sort_option';
  static const _keyChannelsSortIndexLegacy = 'ui_channels_sort_index';

  String _contactsSelectedGroupName = contactsAllGroupsValue;
  String _contactsSearchText = '';
  bool _contactsSearchExpanded = false;
  ContactSortOption _contactsSortOption = ContactSortOption.lastSeen;
  bool _contactsShowUnreadOnly = false;
  ContactTypeFilter _contactsTypeFilter = ContactTypeFilter.all;

  String _channelsSearchText = '';
  ChannelSortOption _channelsSortOption = ChannelSortOption.manual;

  String get contactsSelectedGroupName => _contactsSelectedGroupName;
  String get contactsSearchText => _contactsSearchText;
  bool get contactsSearchExpanded => _contactsSearchExpanded;
  ContactSortOption get contactsSortOption => _contactsSortOption;
  bool get contactsShowUnreadOnly => _contactsShowUnreadOnly;
  ContactTypeFilter get contactsTypeFilter => _contactsTypeFilter;
  String get channelsSearchText => _channelsSearchText;
  ChannelSortOption get channelsSortOption => _channelsSortOption;

  Future<void> initialize() async {
    final prefs = PrefsManager.instance;

    final selectedGroupName = prefs.getString(_keyContactsSelectedGroupName);
    if (selectedGroupName != null && selectedGroupName.isNotEmpty) {
      _contactsSelectedGroupName = selectedGroupName;
    }

    final sortStr = prefs.getString(_keyContactsSortOption);
    if (sortStr != null) {
      _contactsSortOption = ContactSortOption.values.firstWhere(
        (e) => e.name == sortStr,
        orElse: () => ContactSortOption.lastSeen,
      );
    }

    _contactsShowUnreadOnly =
        prefs.getBool(_keyContactsShowUnreadOnly) ?? false;

    final typeStr = prefs.getString(_keyContactsTypeFilter);
    if (typeStr != null) {
      _contactsTypeFilter = ContactTypeFilter.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ContactTypeFilter.all,
      );
    }

    final channelSortStr = prefs.getString(_keyChannelsSortOption);
    if (channelSortStr != null) {
      _channelsSortOption = ChannelSortOption.values.firstWhere(
        (e) => e.name == channelSortStr,
        orElse: () => ChannelSortOption.manual,
      );
      return;
    }

    // Backward compatibility for old persisted index format.
    switch (prefs.getInt(_keyChannelsSortIndexLegacy) ?? 0) {
      case 0:
        _channelsSortOption = ChannelSortOption.manual;
        break;
      case 1:
        _channelsSortOption = ChannelSortOption.name;
        break;
      case 2:
        _channelsSortOption = ChannelSortOption.latestMessages;
        break;
      case 3:
        _channelsSortOption = ChannelSortOption.unread;
        break;
      default:
        _channelsSortOption = ChannelSortOption.manual;
    }
  }

  void setContactsSelectedGroupName(String value) {
    if (_contactsSelectedGroupName == value) return;
    _contactsSelectedGroupName = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyContactsSelectedGroupName, value),
    );
  }

  void setContactsSearchText(String value) {
    if (_contactsSearchText == value) return;
    _contactsSearchText = value;
    notifyListeners();
  }

  void setContactsSearchExpanded(bool value) {
    if (_contactsSearchExpanded == value) return;
    _contactsSearchExpanded = value;
    notifyListeners();
  }

  void setContactsSortOption(ContactSortOption value) {
    if (_contactsSortOption == value) return;
    _contactsSortOption = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyContactsSortOption, value.name),
    );
  }

  void setContactsShowUnreadOnly(bool value) {
    if (_contactsShowUnreadOnly == value) return;
    _contactsShowUnreadOnly = value;
    notifyListeners();
    unawaited(PrefsManager.instance.setBool(_keyContactsShowUnreadOnly, value));
  }

  void setContactsTypeFilter(ContactTypeFilter value) {
    if (_contactsTypeFilter == value) return;
    _contactsTypeFilter = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyContactsTypeFilter, value.name),
    );
  }

  void setChannelsSearchText(String value) {
    if (_channelsSearchText == value) return;
    _channelsSearchText = value;
    notifyListeners();
  }

  void setChannelsSortOption(ChannelSortOption value) {
    if (_channelsSortOption == value) return;
    _channelsSortOption = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyChannelsSortOption, value.name),
    );
  }
}
