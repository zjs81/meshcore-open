import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
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
        child:
            Consumer3<
              AppSettingsService,
              MeshCoreConnector,
              TranslationService
            >(
              builder:
                  (
                    context,
                    settingsService,
                    connector,
                    translationService,
                    child,
                  ) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildAppearanceCard(context, settingsService),
                        const SizedBox(height: 16),
                        _buildNotificationsCard(context, settingsService),
                        const SizedBox(height: 16),
                        _buildMessagingCard(context, settingsService),
                        const SizedBox(height: 16),
                        if (!kIsWeb) ...[
                          _buildTranslationCard(
                            context,
                            settingsService,
                            translationService,
                          ),
                          const SizedBox(height: 16),
                        ],
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
            secondary: const Icon(Icons.vertical_align_top),
            title: Text(context.l10n.appSettings_jumpToOldestUnread),
            subtitle: Text(context.l10n.appSettings_jumpToOldestUnreadSubtitle),
            value: settingsService.settings.jumpToOldestUnread,
            onChanged: settingsService.setJumpToOldestUnread,
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
          if (settingsService.settings.autoRouteRotationEnabled) ...[
            const Divider(height: 1),
            ListTile(
              title: Text(context.l10n.appSettings_maxRouteWeight),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.appSettings_maxRouteWeightSubtitle),
                  Slider(
                    value: settingsService.settings.maxRouteWeight,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: settingsService.settings.maxRouteWeight
                        .round()
                        .toString(),
                    onChanged: (value) =>
                        settingsService.setMaxRouteWeight(value),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(context.l10n.appSettings_initialRouteWeight),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.appSettings_initialRouteWeightSubtitle),
                  Slider(
                    value: settingsService.settings.initialRouteWeight,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: settingsService.settings.initialRouteWeight
                        .toStringAsFixed(1),
                    onChanged: (value) =>
                        settingsService.setInitialRouteWeight(value),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(context.l10n.appSettings_routeWeightSuccessIncrement),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context
                        .l10n
                        .appSettings_routeWeightSuccessIncrementSubtitle,
                  ),
                  Slider(
                    value: settingsService.settings.routeWeightSuccessIncrement,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    label: settingsService.settings.routeWeightSuccessIncrement
                        .toStringAsFixed(1),
                    onChanged: (value) =>
                        settingsService.setRouteWeightSuccessIncrement(value),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(context.l10n.appSettings_routeWeightFailureDecrement),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context
                        .l10n
                        .appSettings_routeWeightFailureDecrementSubtitle,
                  ),
                  Slider(
                    value: settingsService.settings.routeWeightFailureDecrement,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    label: settingsService.settings.routeWeightFailureDecrement
                        .toStringAsFixed(1),
                    onChanged: (value) =>
                        settingsService.setRouteWeightFailureDecrement(value),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(context.l10n.appSettings_maxMessageRetries),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.appSettings_maxMessageRetriesSubtitle),
                  Slider(
                    value: settingsService.settings.maxMessageRetries
                        .toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    label: settingsService.settings.maxMessageRetries
                        .toString(),
                    onChanged: (value) =>
                        settingsService.setMaxMessageRetries(value.toInt()),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildTranslationCard(
    BuildContext context,
    AppSettingsService settingsService,
    TranslationService translationService,
  ) {
    final settings = settingsService.settings;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.l10n.translation_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.translate),
            title: Text(context.l10n.translation_enableTitle),
            subtitle: Text(context.l10n.translation_enableSubtitle),
            value: settings.translationEnabled,
            onChanged: settingsService.setTranslationEnabled,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.outgoing_mail),
            title: Text(context.l10n.translation_composerTitle),
            subtitle: Text(context.l10n.translation_composerSubtitle),
            value: settings.composerTranslationEnabled,
            onChanged: settingsService.setComposerTranslationEnabled,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.l10n.translation_targetLanguage),
            subtitle: Text(
              _translationLanguageLabel(
                context,
                settings.translationTargetLanguageCode,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showTranslationLanguageDialog(context, settingsService),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String>(
              initialValue: settings.translationSelectedModelId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.translation_downloadedModelLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final model in settings.translationDownloadedModels)
                  DropdownMenuItem(
                    value: model.id,
                    child: Text(translationModelFriendlyName(model)),
                  ),
              ],
              onChanged: settings.translationDownloadedModels.isEmpty
                  ? null
                  : (value) {
                      settingsService.setTranslationSelectedModelId(value);
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String>(
              initialValue: null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.translation_presetModelLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final preset in translationPresetModels)
                  DropdownMenuItem(
                    value: preset.sourceUrl,
                    child: Text(translationModelFriendlyName(preset)),
                  ),
              ],
              onChanged: translationService.isBusy
                  ? null
                  : (value) async {
                      if (value == null) return;
                      final preset = translationPresetModels.firstWhere(
                        (entry) => entry.sourceUrl == value,
                      );
                      await _downloadTranslationModel(
                        context,
                        translationService,
                        settingsService,
                        sourceUrl: preset.sourceUrl,
                        fileName: preset.name,
                        id: preset.id,
                      );
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _TranslationUrlField(
                  initialValue: settings.translationModelSourceUrl ?? '',
                  onChanged: settingsService.setTranslationModelSourceUrl,
                  onDownload: translationService.isBusy
                      ? null
                      : (url) => _downloadTranslationModel(
                          context,
                          translationService,
                          settingsService,
                          sourceUrl: url,
                        ),
                  downloadLabel: translationService.isDownloading
                      ? context.l10n.translation_downloading
                      : translationService.isBusy
                      ? context.l10n.translation_working
                      : context.l10n.translation_downloadModel,
                  isDownloading: translationService.isDownloading,
                  onCancel: translationService.cancelDownload,
                  labelText: context.l10n.translation_manualUrlLabel,
                  stopLabel: context.l10n.translation_stop,
                ),
                if (translationService.isDownloading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        translationService.downloadFileName ==
                            'Merging chunks...'
                        ? null
                        : translationService.downloadProgress,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _downloadProgressLabel(context, translationService),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                if (settings.translationDownloadedModels.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.translation_downloadedModels,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final model in settings.translationDownloadedModels)
                    Card.outlined(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Icon(
                          model.id == settings.translationSelectedModelId
                              ? Icons.check_circle
                              : Icons.memory_outlined,
                        ),
                        title: Text(translationModelFriendlyName(model)),
                        subtitle: Text(_downloadedModelLabel(model)),
                        trailing: IconButton(
                          tooltip: context.l10n.translation_deleteModel,
                          onPressed: translationService.isBusy
                              ? null
                              : () => _deleteTranslationModel(
                                  context,
                                  translationService,
                                  model,
                                ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap: () => settingsService
                            .setTranslationSelectedModelId(model.id),
                      ),
                    ),
                ],
                if (translationService.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    translationService.lastError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
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
      case 'hu':
        return context.l10n.appSettings_languageHu;
      case 'ja':
        return context.l10n.appSettings_languageJa;
      case 'ko':
        return context.l10n.appSettings_languageKo;
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
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageHu),
                  value: 'hu',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageJa),
                  value: 'ja',
                ),
                RadioListTile<String?>(
                  title: Text(context.l10n.appSettings_languageKo),
                  value: 'ko',
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

  void _showTranslationLanguageDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TranslationLanguageDialogContent(
        currentLanguageCode:
            settingsService.settings.translationTargetLanguageCode,
        onLanguageSelected: (value) {
          settingsService.setTranslationTargetLanguageCode(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _downloadTranslationModel(
    BuildContext context,
    TranslationService translationService,
    AppSettingsService settingsService, {
    required String sourceUrl,
    String? fileName,
    String? id,
  }) async {
    if (sourceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translation_enterUrlFirst)),
      );
      return;
    }
    try {
      await translationService.downloadModel(
        sourceUrl: sourceUrl,
        fileName: fileName,
        id: id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translation_modelDownloaded)),
      );
      await settingsService.setTranslationEnabled(true);
    } on TranslationDownloadCancelled {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translation_downloadStopped)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.translation_downloadFailed(error.toString()),
          ),
        ),
      );
    }
  }

  String _translationLanguageLabel(BuildContext context, String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return context.l10n.translation_useAppLanguage;
    }
    for (final option in supportedTranslationLanguages) {
      if (option.code == languageCode) {
        return option.label;
      }
    }
    return languageCode.toUpperCase();
  }

  String _downloadProgressLabel(
    BuildContext context,
    TranslationService translationService,
  ) {
    final fileName = translationService.downloadFileName ?? 'Model';
    if (fileName == 'Merging chunks...') {
      return context.l10n.translation_mergingChunks;
    }
    final currentMb = translationService.downloadedBytes / (1024 * 1024);
    final totalBytes = translationService.downloadTotalBytes;
    if (totalBytes == null || totalBytes <= 0) {
      return '$fileName: ${currentMb.toStringAsFixed(1)} MB';
    }
    final totalMb = totalBytes / (1024 * 1024);
    final percent = ((translationService.downloadProgress ?? 0) * 100)
        .toStringAsFixed(0);
    return '$fileName: ${currentMb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB ($percent%)';
  }

  Future<void> _deleteTranslationModel(
    BuildContext context,
    TranslationService translationService,
    TranslationModelRecord model,
  ) async {
    try {
      await translationService.removeModel(model);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // TODO: l10n
          content: Text('Deleted ${translationModelFriendlyName(model)}.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      ); // TODO: l10n
    }
  }

  String _downloadedModelLabel(TranslationModelRecord model) {
    final sizeMb = model.fileSizeBytes / (1024 * 1024);
    final source = model.sourceUrl.isEmpty ? model.name : model.sourceUrl;
    return '${sizeMb.toStringAsFixed(1)} MB • $source';
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

/// Owns the [TextEditingController] for the manual model URL field so it
/// survives rebuilds of the parent [Consumer3].
class _TranslationUrlField extends StatefulWidget {
  const _TranslationUrlField({
    required this.initialValue,
    required this.onChanged,
    required this.onDownload,
    required this.downloadLabel,
    required this.isDownloading,
    required this.onCancel,
    required this.labelText,
    required this.stopLabel,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final void Function(String url)? onDownload;
  final String downloadLabel;
  final bool isDownloading;
  final VoidCallback onCancel;
  final String labelText;
  final String stopLabel;

  @override
  State<_TranslationUrlField> createState() => _TranslationUrlFieldState();
}

class _TranslationUrlFieldState extends State<_TranslationUrlField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onDownload == null
                    ? null
                    : () => widget.onDownload!(_controller.text.trim()),
                icon: const Icon(Icons.download),
                label: Text(widget.downloadLabel),
              ),
            ),
            if (widget.isDownloading) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(widget.stopLabel),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Dialog content for choosing the translation target language.
/// Owns the search [TextEditingController] so it is properly disposed.
class _TranslationLanguageDialogContent extends StatefulWidget {
  const _TranslationLanguageDialogContent({
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  });

  final String? currentLanguageCode;
  final ValueChanged<String?> onLanguageSelected;

  @override
  State<_TranslationLanguageDialogContent> createState() =>
      _TranslationLanguageDialogContentState();
}

class _TranslationLanguageDialogContentState
    extends State<_TranslationLanguageDialogContent> {
  late final TextEditingController _searchController;
  List<TranslationLanguageOption> _filtered = supportedTranslationLanguages;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.translation_targetLanguage),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final normalized = value.trim().toLowerCase();
                setState(() {
                  _filtered = supportedTranslationLanguages.where((option) {
                    return option.label.toLowerCase().contains(normalized) ||
                        option.code.toLowerCase().contains(normalized);
                  }).toList();
                });
              },
            ),
            const SizedBox(height: 12),
            Flexible(
              child: RadioGroup<String?>(
                groupValue: widget.currentLanguageCode,
                onChanged: (value) {
                  widget.onLanguageSelected(value);
                },
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    RadioListTile<String?>(
                      value: null,
                      title: Text(context.l10n.translation_useAppLanguage),
                    ),
                    for (final option in _filtered)
                      RadioListTile<String?>(
                        value: option.code,
                        title: Text(option.label),
                        subtitle: Text(option.code.toUpperCase()),
                      ),
                  ],
                ),
              ),
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
    );
  }
}
