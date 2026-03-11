import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/notification_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import 'map_cache_screen.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.appSettings_title),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<AppSettingsService, MeshCoreConnector>(
          builder: (context, settingsService, connector, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAppearanceCard(context, settingsService),
                const SizedBox(height: 16),
                _buildNotificationsCard(context, settingsService),
                const SizedBox(height: 16),
                _buildMessagingCard(context, settingsService),
                const SizedBox(height: 16),
                _buildRoomSyncCard(context, settingsService),
                const SizedBox(height: 16),
                _buildBatteryCard(context, settingsService, connector),
                const SizedBox(height: 16),
                _buildMapSettingsCard(context, settingsService),
                const SizedBox(height: 16),
                _buildDebugCard(context, settingsService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.appSettings_appearance,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(context.l10n.appSettings_theme),
            subtitle: Text(
              _themeModeLabel(context, settingsService.settings.themeMode),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModeDialog(context, settingsService),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(context.l10n.appSettings_language),
            subtitle: Text(
              _languageLabel(
                context,
                settingsService.settings.languageOverride,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, settingsService),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.location_searching),
            title: Text(context.l10n.appSettings_enableMessageTracing),
            subtitle: Text(
              context.l10n.appSettings_enableMessageTracingSubtitle,
            ),
            value: settingsService.settings.enableMessageTracing,
            onChanged: (value) {
              settingsService.setEnableMessageTracing(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.appSettings_notifications,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(context.l10n.appSettings_enableNotifications),
            subtitle: Text(
              context.l10n.appSettings_enableNotificationsSubtitle,
            ),
            value: settingsService.settings.notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Request permission when enabling
                final granted = await NotificationService()
                    .requestPermissions();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.appSettings_notificationPermissionDenied,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  return;
                }
              }

              await settingsService.setNotificationsEnabled(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? context.l10n.appSettings_notificationsEnabled
                          : context.l10n.appSettings_notificationsDisabled,
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.message_outlined,
              color: settingsService.settings.notificationsEnabled
                  ? null
                  : Colors.grey,
            ),
            title: Text(
              context.l10n.appSettings_messageNotifications,
              style: TextStyle(
                color: settingsService.settings.notificationsEnabled
                    ? null
                    : Colors.grey,
              ),
            ),
            subtitle: Text(
              context.l10n.appSettings_messageNotificationsSubtitle,
              style: TextStyle(
                color: settingsService.settings.notificationsEnabled
                    ? null
                    : Colors.grey,
              ),
            ),
            value: settingsService.settings.notifyOnNewMessage,
            onChanged: settingsService.settings.notificationsEnabled
                ? (value) {
                    settingsService.setNotifyOnNewMessage(value);
                  }
                : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.forum_outlined,
              color: settingsService.settings.notificationsEnabled
                  ? null
                  : Colors.grey,
            ),
            title: Text(
              context.l10n.appSettings_channelMessageNotifications,
              style: TextStyle(
                color: settingsService.settings.notificationsEnabled
                    ? null
                    : Colors.grey,
              ),
            ),
            subtitle: Text(
              context.l10n.appSettings_channelMessageNotificationsSubtitle,
              style: TextStyle(
                color: settingsService.settings.notificationsEnabled
                    ? null
                    : Colors.grey,
              ),
            ),
            value: settingsService.settings.notifyOnNewChannelMessage,
            onChanged: settingsService.settings.notificationsEnabled
                ? (value) {
                    settingsService.setNotifyOnNewChannelMessage(value);
                  }
                : null,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.cell_tower,
              color: settingsService.settings.notificationsEnabled
                  ? null
                  : Colors.grey,
            ),
            title: Text(
              context.l10n.appSettings_advertisementNotifications,
              style: TextStyle(
                color: settingsService.settings.notificationsEnabled
                    ? null
                    : Colors.grey,
              ),
            ),
            subtitle: Text(
              context.l10n.appSettings_advertisementNotificationsSubtitle,
              style: TextStyle(
                color: settingsService.settings.notificationsEnabled
                    ? null
                    : Colors.grey,
              ),
            ),
            value: settingsService.settings.notifyOnNewAdvert,
            onChanged: settingsService.settings.notificationsEnabled
                ? (value) {
                    settingsService.setNotifyOnNewAdvert(value);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingCard(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.appSettings_messaging,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.refresh_outlined),
            title: Text(context.l10n.appSettings_clearPathOnMaxRetry),
            subtitle: Text(
              context.l10n.appSettings_clearPathOnMaxRetrySubtitle,
            ),
            value: settingsService.settings.clearPathOnMaxRetry,
            onChanged: (value) {
              settingsService.setClearPathOnMaxRetry(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? context.l10n.appSettings_pathsWillBeCleared
                        : context.l10n.appSettings_pathsWillNotBeCleared,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.alt_route),
            title: Text(context.l10n.appSettings_autoRouteRotation),
            subtitle: Text(context.l10n.appSettings_autoRouteRotationSubtitle),
            value: settingsService.settings.autoRouteRotationEnabled,
            onChanged: (value) {
              settingsService.setAutoRouteRotationEnabled(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? context.l10n.appSettings_autoRouteRotationEnabled
                        : context.l10n.appSettings_autoRouteRotationDisabled,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapSettingsCard(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.appSettings_mapDisplay,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.router_outlined),
            title: Text(context.l10n.appSettings_showRepeaters),
            subtitle: Text(context.l10n.appSettings_showRepeatersSubtitle),
            value: settingsService.settings.mapShowRepeaters,
            onChanged: (value) {
              settingsService.setMapShowRepeaters(value);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.chat_outlined),
            title: Text(context.l10n.appSettings_showChatNodes),
            subtitle: Text(context.l10n.appSettings_showChatNodesSubtitle),
            value: settingsService.settings.mapShowChatNodes,
            onChanged: (value) {
              settingsService.setMapShowChatNodes(value);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.people_outline),
            title: Text(context.l10n.appSettings_showOtherNodes),
            subtitle: Text(context.l10n.appSettings_showOtherNodesSubtitle),
            value: settingsService.settings.mapShowOtherNodes,
            onChanged: (value) {
              settingsService.setMapShowOtherNodes(value);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(context.l10n.appSettings_timeFilter),
            subtitle: Text(
              settingsService.settings.mapTimeFilterHours == 0
                  ? context.l10n.appSettings_timeFilterShowAll
                  : context.l10n.appSettings_timeFilterShowLast(
                      settingsService.settings.mapTimeFilterHours.toInt(),
                    ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimeFilterDialog(context, settingsService),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text(context.l10n.appSettings_unitsTitle),
            subtitle: Text(
              settingsService.settings.unitSystem == UnitSystem.imperial
                  ? context.l10n.appSettings_unitsImperial
                  : context.l10n.appSettings_unitsMetric,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUnitsDialog(context, settingsService),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(context.l10n.appSettings_offlineMapCache),
            subtitle: Text(
              settingsService.settings.mapCacheBounds == null
                  ? context.l10n.appSettings_noAreaSelected
                  : context.l10n.appSettings_areaSelectedZoom(
                      settingsService.settings.mapCacheMinZoom,
                      settingsService.settings.mapCacheMaxZoom,
                    ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapCacheScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSyncCard(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final settings = settingsService.settings;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Room Sync',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('Enable room auto-sync'),
            subtitle: const Text(
              'Automatically keep room-server backlog synced while connected.',
            ),
            value: settings.roomSyncEnabled,
            onChanged: (value) => settingsService.setRoomSyncEnabled(value),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.login),
            title: const Text('Auto-login saved room sessions'),
            subtitle: const Text(
              'On reconnect, login to room servers with saved passwords.',
            ),
            value: settings.roomSyncAutoLoginEnabled,
            onChanged: settings.roomSyncEnabled
                ? (value) => settingsService.setRoomSyncAutoLoginEnabled(value)
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Base sync interval'),
            subtitle: Text('${settings.roomSyncIntervalSeconds}s'),
            trailing: const Icon(Icons.chevron_right),
            enabled: settings.roomSyncEnabled,
            onTap: settings.roomSyncEnabled
                ? () => _editIntegerSetting(
                    context: context,
                    title: 'Base sync interval (seconds)',
                    initialValue: settings.roomSyncIntervalSeconds,
                    min: 15,
                    max: 3600,
                    onSave: settingsService.setRoomSyncIntervalSeconds,
                  )
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Max backoff interval'),
            subtitle: Text('${settings.roomSyncMaxIntervalSeconds}s'),
            trailing: const Icon(Icons.chevron_right),
            enabled: settings.roomSyncEnabled,
            onTap: settings.roomSyncEnabled
                ? () => _editIntegerSetting(
                    context: context,
                    title: 'Max backoff interval (seconds)',
                    initialValue: settings.roomSyncMaxIntervalSeconds,
                    min: 30,
                    max: 7200,
                    onSave: settingsService.setRoomSyncMaxIntervalSeconds,
                  )
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.hourglass_bottom),
            title: const Text('Sync timeout'),
            subtitle: Text('${settings.roomSyncTimeoutSeconds}s'),
            trailing: const Icon(Icons.chevron_right),
            enabled: settings.roomSyncEnabled,
            onTap: settings.roomSyncEnabled
                ? () => _editIntegerSetting(
                    context: context,
                    title: 'Sync timeout (seconds)',
                    initialValue: settings.roomSyncTimeoutSeconds,
                    min: 5,
                    max: 120,
                    onSave: settingsService.setRoomSyncTimeoutSeconds,
                  )
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Mark room stale after'),
            subtitle: Text('${settings.roomSyncStaleMinutes} min'),
            trailing: const Icon(Icons.chevron_right),
            enabled: settings.roomSyncEnabled,
            onTap: settings.roomSyncEnabled
                ? () => _editIntegerSetting(
                    context: context,
                    title: 'Stale threshold (minutes)',
                    initialValue: settings.roomSyncStaleMinutes,
                    min: 1,
                    max: 240,
                    onSave: settingsService.setRoomSyncStaleMinutes,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // Fixed rendering issues
  Widget _buildBatteryCard(
    BuildContext context,
    AppSettingsService settingsService,
    MeshCoreConnector connector,
  ) {
    final deviceId = connector.deviceId;
    final isConnected = connector.isConnected && deviceId != null;
    final selection = isConnected
        ? settingsService.batteryChemistryForDevice(deviceId)
        : 'nmc';

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.appSettings_battery,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Main tile (icon + text only)
          ListTile(
            leading: const Icon(Icons.battery_full),
            title: Text(context.l10n.appSettings_batteryChemistry),
            subtitle: Text(
              isConnected
                  ? context.l10n.appSettings_batteryChemistryPerDevice(
                      connector.deviceDisplayName,
                    )
                  : context.l10n.appSettings_batteryChemistryConnectFirst,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Dropdown (separate full-width row)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DropdownButtonFormField<String>(
              initialValue: selection,
              isExpanded: true,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                isDense: true,
              ),
              onChanged: isConnected
                  ? (value) {
                      if (value != null) {
                        settingsService.setBatteryChemistryForDevice(
                          deviceId,
                          value,
                        );
                      }
                    }
                  : null,
              items: [
                DropdownMenuItem(
                  value: 'nmc',
                  child: Text(context.l10n.appSettings_batteryNmc),
                ),
                DropdownMenuItem(
                  value: 'lifepo4',
                  child: Text(context.l10n.appSettings_batteryLifepo4),
                ),
                DropdownMenuItem(
                  value: 'lipo',
                  child: Text(context.l10n.appSettings_batteryLipo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.appSettings_theme),
        content: RadioGroup<String>(
          groupValue: settingsService.settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              settingsService.setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(context.l10n.appSettings_themeSystem),
                value: 'system',
              ),
              RadioListTile<String>(
                title: Text(context.l10n.appSettings_themeLight),
                value: 'light',
              ),
              RadioListTile<String>(
                title: Text(context.l10n.appSettings_themeDark),
                value: 'dark',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(BuildContext context, String value) {
    switch (value) {
      case 'light':
        return context.l10n.appSettings_themeLight;
      case 'dark':
        return context.l10n.appSettings_themeDark;
      default:
        return context.l10n.appSettings_themeSystem;
    }
  }

  String _languageLabel(BuildContext context, String? languageCode) {
    switch (languageCode) {
      case 'en':
        return context.l10n.appSettings_languageEn;
      case 'fr':
        return context.l10n.appSettings_languageFr;
      case 'es':
        return context.l10n.appSettings_languageEs;
      case 'de':
        return context.l10n.appSettings_languageDe;
      case 'pl':
        return context.l10n.appSettings_languagePl;
      case 'sl':
        return context.l10n.appSettings_languageSl;
      case 'pt':
        return context.l10n.appSettings_languagePt;
      case 'it':
        return context.l10n.appSettings_languageIt;
      case 'zh':
        return context.l10n.appSettings_languageZh;
      case 'sv':
        return context.l10n.appSettings_languageSv;
      case 'nl':
        return context.l10n.appSettings_languageNl;
      case 'sk':
        return context.l10n.appSettings_languageSk;
      case 'bg':
        return context.l10n.appSettings_languageBg;
      case 'ru':
        return context.l10n.appSettings_languageRu;
      case 'uk':
        return context.l10n.appSettings_languageUk;
      default:
        return context.l10n.appSettings_languageSystem;
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.appSettings_language),
        content: SingleChildScrollView(
          child: RadioGroup<String?>(
            groupValue: settingsService.settings.languageOverride,
            onChanged: (value) {
              settingsService.setLanguageOverride(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageSystem),
                  value: null,
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageEn),
                  value: 'en',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageFr),
                  value: 'fr',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageEs),
                  value: 'es',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageDe),
                  value: 'de',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languagePl),
                  value: 'pl',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageSl),
                  value: 'sl',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languagePt),
                  value: 'pt',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageIt),
                  value: 'it',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageZh),
                  value: 'zh',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageSv),
                  value: 'sv',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageNl),
                  value: 'nl',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageSk),
                  value: 'sk',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageBg),
                  value: 'bg',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageRu),
                  value: 'ru',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageUk),
                  value: 'uk',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  void _showTimeFilterDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.appSettings_mapTimeFilter),
        content: RadioGroup<double>(
          groupValue: settingsService.settings.mapTimeFilterHours,
          onChanged: (value) {
            if (value != null) {
              settingsService.setMapTimeFilterHours(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.appSettings_showNodesDiscoveredWithin),
              const SizedBox(height: 16),
              ListTile(
                title: Text(context.l10n.appSettings_allTime),
                leading: Radio<double>(value: 0),
              ),
              ListTile(
                title: Text(context.l10n.appSettings_lastHour),
                leading: Radio<double>(value: 1),
              ),
              ListTile(
                title: Text(context.l10n.appSettings_last6Hours),
                leading: Radio<double>(value: 6),
              ),
              ListTile(
                title: Text(context.l10n.appSettings_last24Hours),
                leading: Radio<double>(value: 24),
              ),
              ListTile(
                title: Text(context.l10n.appSettings_lastWeek),
                leading: Radio<double>(value: 168),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  void _editIntegerSetting({
    required BuildContext context,
    required String title,
    required int initialValue,
    required int min,
    required int max,
    required Future<void> Function(int) onSave,
  }) {
    final controller = TextEditingController(text: initialValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText: 'Allowed range: $min - $max',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < min || parsed > max) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Value must be between $min and $max'),
                  ),
                );
                return;
              }
              await onSave(parsed);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: Text(context.l10n.common_save),
          ),
        ],
      ),
    );
  }

  void _showUnitsDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.appSettings_unitsTitle),
        content: RadioGroup<UnitSystem>(
          groupValue: settingsService.settings.unitSystem,
          onChanged: (value) {
            if (value != null) {
              settingsService.setUnitSystem(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.l10n.appSettings_unitsMetric),
                leading: const Radio<UnitSystem>(value: UnitSystem.metric),
              ),
              ListTile(
                title: Text(context.l10n.appSettings_unitsImperial),
                leading: const Radio<UnitSystem>(value: UnitSystem.imperial),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.appSettings_debugCard,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bug_report_outlined),
            title: Text(context.l10n.appSettings_appDebugLogging),
            subtitle: Text(context.l10n.appSettings_appDebugLoggingSubtitle),
            value: settingsService.settings.appDebugLogEnabled,
            onChanged: (value) async {
              await settingsService.setAppDebugLogEnabled(value);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? context.l10n.appSettings_appDebugLoggingEnabled
                        : context.l10n.appSettings_appDebugLoggingDisabled,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
