import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/image_codec_support.dart';
import '../services/app_settings_service.dart';
import '../services/background_service.dart';
import '../services/image_codec_service.dart';
import '../services/map_tile_cache_service.dart';
import '../services/notification_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/platform_info.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/cyr2lat_profile_dialog.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/mesh_nav_tile.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/network_map_settings_section.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/translation_settings_section.dart';
import '../helpers/snack_bar_builder.dart';
import 'map_cache_screen.dart';

class AppSettingsScreen extends StatelessWidget {
  /// Scrolls the image-message settings into view once, on first build.
  ///
  /// This is how the received-image placeholder's "no model installed" tap
  /// lands somewhere useful: the image block sits below appearance,
  /// notifications, messaging, battery, map and translation, so pushing the
  /// plain settings screen would drop the user at the top with no hint that
  /// the thing they tapped for is several screens down.
  final bool focusImageMessages;

  const AppSettingsScreen({super.key, this.focusImageMessages = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.appSettings_title),
        centerTitle: true,
        bottom: const SyncProgressAppBarBottom(),
      ),
      body: SafeArea(
        top: false,
        // Each card subscribes to only what it shows, so connector traffic
        // and translation download ticks do not rebuild the whole list.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            // APPEARANCE
            SectionHeader(context.l10n.appSettings_appearance),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildAppearanceContent),
            ),

            // NOTIFICATIONS
            SectionHeader(context.l10n.appSettings_notifications),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildNotificationsContent),
            ),

            // MESSAGING
            SectionHeader(context.l10n.appSettings_messaging),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildMessagingContent),
            ),

            // ROUTING
            SectionHeader(context.l10n.appSettings_routingSection),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildRoutingContent),
            ),

            // IMAGE MESSAGES
            SectionHeader(context.l10n.appSettings_imageMessagesSection),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildImageMessagesContent),
            ),

            // BATTERY
            SectionHeader(context.l10n.appSettings_battery),
            MeshCard(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _settingsCard(_buildBatteryContent),
            ),

            // MAP
            SectionHeader(context.l10n.appSettings_mapDisplay),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildMapContent),
            ),

            // NETWORK MAP
            SectionHeader(context.l10n.networkMap_settingsSection),
            const MeshCard(
              padding: EdgeInsets.zero,
              child: NetworkMapSettingsSection(),
            ),

            // TRANSLATION (non-web only)
            if (!kIsWeb) ...[
              SectionHeader(context.l10n.translation_title),
              const MeshCard(
                padding: EdgeInsets.zero,
                child: TranslationSettingsSection(),
              ),
            ],

            // CYR2LAT
            SectionHeader(context.l10n.channels_cyr2latSettingsHeading),
            MeshCard(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _settingsCard(_buildCyr2LatContent),
            ),

            // DEBUG
            SectionHeader(context.l10n.appSettings_debugCard),
            MeshCard(
              padding: EdgeInsets.zero,
              child: _settingsCard(_buildDebugContent),
            ),
          ],
        ),
      ),
    );
  }

  /// A card that rebuilds only on [AppSettingsService] changes.
  Widget _settingsCard(
    Widget Function(BuildContext context, AppSettingsService settingsService)
    builder,
  ) {
    return Consumer<AppSettingsService>(
      builder: (context, settingsService, _) =>
          builder(context, settingsService),
    );
  }

  Widget _buildAppearanceContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.brightness_6_outlined,
                    size: 24,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    context.l10n.appSettings_theme,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'system',
                    label: Text(context.l10n.appSettings_themeSystem),
                  ),
                  ButtonSegment(
                    value: 'light',
                    label: Text(context.l10n.appSettings_themeLight),
                  ),
                  ButtonSegment(
                    value: 'dark',
                    label: Text(context.l10n.appSettings_themeDark),
                  ),
                ],
                selected: {settingsService.settings.themeMode},
                onSelectionChanged: (selection) {
                  settingsService.setThemeMode(selection.first);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.language_outlined,
          title: context.l10n.appSettings_language,
          subtitle: appLanguageLabel(
            context,
            settingsService.settings.languageOverride,
          ),
          onTap: () => showLanguagePickerSheet(context, settingsService),
        ),
      ],
    );
  }

  Widget _buildNotificationsContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final notifEnabled = settingsService.settings.notificationsEnabled;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.notifications_outlined, size: 24),
          title: Text(context.l10n.appSettings_enableNotifications),
          subtitle: Text(context.l10n.appSettings_enableNotificationsSubtitle),
          value: settingsService.settings.notificationsEnabled,
          onChanged: (value) async {
            if (value) {
              final granted = await NotificationService().requestPermissions();
              if (!granted) {
                if (context.mounted) {
                  showDismissibleSnackBar(
                    context,
                    content: Text(
                      context.l10n.appSettings_notificationPermissionDenied,
                    ),
                    duration: const Duration(seconds: 2),
                  );
                }
                return;
              }
            }
            await settingsService.setNotificationsEnabled(value);
            if (context.mounted) {
              showDismissibleSnackBar(
                context,
                content: Text(
                  value
                      ? context.l10n.appSettings_notificationsEnabled
                      : context.l10n.appSettings_notificationsDisabled,
                ),
                duration: const Duration(seconds: 2),
              );
            }
          },
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: Icon(
            Icons.message_outlined,
            size: 24,
            color: notifEnabled ? null : Theme.of(context).disabledColor,
          ),
          title: Text(
            context.l10n.appSettings_messageNotifications,
            style: TextStyle(
              color: notifEnabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: Text(
            context.l10n.appSettings_messageNotificationsSubtitle,
            style: TextStyle(
              color: notifEnabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          value: settingsService.settings.notifyOnNewMessage,
          onChanged: notifEnabled
              ? (value) => settingsService.setNotifyOnNewMessage(value)
              : null,
        ),
        if (PlatformInfo.isAndroid) ...[
          const Divider(height: 1, indent: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: const Icon(Icons.battery_saver_outlined, size: 24),
            title: Text(context.l10n.appSettings_batteryOptimization),
            subtitle: Text(
              context.l10n.appSettings_batteryOptimizationSubtitle,
            ),
            trailing: const Icon(Icons.open_in_new, size: 24),
            onTap: BackgroundService.openBatteryOptimizationSettings,
          ),
        ],
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: Icon(
            Icons.forum_outlined,
            size: 24,
            color: notifEnabled ? null : Theme.of(context).disabledColor,
          ),
          title: Text(
            context.l10n.appSettings_channelMessageNotifications,
            style: TextStyle(
              color: notifEnabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: Text(
            context.l10n.appSettings_channelMessageNotificationsSubtitle,
            style: TextStyle(
              color: notifEnabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          value: settingsService.settings.notifyOnNewChannelMessage,
          onChanged: notifEnabled
              ? (value) => settingsService.setNotifyOnNewChannelMessage(value)
              : null,
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: Icon(
            Icons.cell_tower,
            size: 24,
            color: notifEnabled ? null : Theme.of(context).disabledColor,
          ),
          title: Text(
            context.l10n.appSettings_advertisementNotifications,
            style: TextStyle(
              color: notifEnabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: Text(
            context.l10n.appSettings_advertisementNotificationsSubtitle,
            style: TextStyle(
              color: notifEnabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          value: settingsService.settings.notifyOnNewAdvert,
          onChanged: notifEnabled
              ? (value) => settingsService.setNotifyOnNewAdvert(value)
              : null,
        ),
      ],
    );
  }

  Widget _buildMessagingContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.refresh_outlined, size: 24),
          title: Text(context.l10n.appSettings_clearPathOnMaxRetry),
          subtitle: Text(context.l10n.appSettings_clearPathOnMaxRetrySubtitle),
          value: settingsService.settings.clearPathOnMaxRetry,
          onChanged: (value) {
            settingsService.setClearPathOnMaxRetry(value);
            showDismissibleSnackBar(
              context,
              content: Text(
                value
                    ? context.l10n.appSettings_pathsWillBeCleared
                    : context.l10n.appSettings_pathsWillNotBeCleared,
              ),
              duration: const Duration(seconds: 2),
            );
          },
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.vertical_align_top, size: 24),
          title: Text(context.l10n.appSettings_jumpToOldestUnread),
          subtitle: Text(context.l10n.appSettings_jumpToOldestUnreadSubtitle),
          value: settingsService.settings.jumpToOldestUnread,
          onChanged: settingsService.setJumpToOldestUnread,
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.settings_remote_outlined, size: 24),
          title: Text(context.l10n.appSettings_autoFetchRepeaterSettings),
          subtitle: Text(
            context.l10n.appSettings_autoFetchRepeaterSettingsSubtitle,
          ),
          value: settingsService.settings.autoFetchRepeaterSettings,
          onChanged: settingsService.setAutoFetchRepeaterSettings,
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.location_searching, size: 24),
          title: Text(context.l10n.appSettings_enableMessageTracing),
          subtitle: Text(context.l10n.appSettings_enableMessageTracingSubtitle),
          value: settingsService.settings.enableMessageTracing,
          onChanged: (value) {
            settingsService.setEnableMessageTracing(value);
          },
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.short_text, size: 24),
          title: Text(context.l10n.appSettings_regionOnHopsLine),
          subtitle: Text(context.l10n.appSettings_regionOnHopsLineSubtitle),
          value: settingsService.settings.regionOnHopsLine,
          onChanged: settingsService.setRegionOnHopsLine,
        ),
      ],
    );
  }

  Widget _buildRoutingContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final autoRouteEnabled = settingsService.settings.autoRouteRotationEnabled;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.alt_route, size: 24),
          title: Text(context.l10n.appSettings_autoRouteRotation),
          subtitle: Text(context.l10n.appSettings_autoRouteRotationSubtitle),
          value: autoRouteEnabled,
          onChanged: (value) {
            settingsService.setAutoRouteRotationEnabled(value);
            showDismissibleSnackBar(
              context,
              content: Text(
                value
                    ? context.l10n.appSettings_autoRouteRotationEnabled
                    : context.l10n.appSettings_autoRouteRotationDisabled,
              ),
              duration: const Duration(seconds: 2),
            );
          },
        ),
        // AnimatedSize sub-options for auto-route rotation
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: autoRouteEnabled
              ? Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      ListTile(
                        title: Text(context.l10n.appSettings_maxRouteWeight),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.appSettings_maxRouteWeightSubtitle,
                            ),
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
                        title: Text(
                          context.l10n.appSettings_initialRouteWeight,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .l10n
                                  .appSettings_initialRouteWeightSubtitle,
                            ),
                            Slider(
                              value:
                                  settingsService.settings.initialRouteWeight,
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
                        title: Text(
                          context.l10n.appSettings_routeWeightSuccessIncrement,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .l10n
                                  .appSettings_routeWeightSuccessIncrementSubtitle,
                            ),
                            Slider(
                              value: settingsService
                                  .settings
                                  .routeWeightSuccessIncrement,
                              min: 0.1,
                              max: 2.0,
                              divisions: 19,
                              label: settingsService
                                  .settings
                                  .routeWeightSuccessIncrement
                                  .toStringAsFixed(1),
                              onChanged: (value) => settingsService
                                  .setRouteWeightSuccessIncrement(value),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          context.l10n.appSettings_routeWeightFailureDecrement,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .l10n
                                  .appSettings_routeWeightFailureDecrementSubtitle,
                            ),
                            Slider(
                              value: settingsService
                                  .settings
                                  .routeWeightFailureDecrement,
                              min: 0.1,
                              max: 2.0,
                              divisions: 19,
                              label: settingsService
                                  .settings
                                  .routeWeightFailureDecrement
                                  .toStringAsFixed(1),
                              onChanged: (value) => settingsService
                                  .setRouteWeightFailureDecrement(value),
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
                            Text(
                              context
                                  .l10n
                                  .appSettings_maxMessageRetriesSubtitle,
                            ),
                            Slider(
                              value: settingsService.settings.maxMessageRetries
                                  .toDouble(),
                              min: 2,
                              max: 10,
                              divisions: 8,
                              label: settingsService.settings.maxMessageRetries
                                  .toString(),
                              onChanged: (value) => settingsService
                                  .setMaxMessageRetries(value.toInt()),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const Icon(Icons.restart_alt, size: 24),
                        title: Text(
                          context.l10n.appSettings_resetRoutingToDefault,
                        ),
                        subtitle: Text(
                          context
                              .l10n
                              .appSettings_resetRoutingToDefaultSubtitle,
                        ),
                        trailing: const Icon(
                          Icons.keyboard_arrow_right,
                          size: 18,
                        ),
                        onTap: () async {
                          await settingsService.resetRoutingSettingsToDefault();
                          if (context.mounted) {
                            showDismissibleSnackBar(
                              context,
                              content: Text(
                                context.l10n.appSettings_routingResetToDefault,
                              ),
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.cell_tower, size: 24),
          title: Text(context.l10n.appSettings_channelMinHops),
          subtitle: Text(context.l10n.appSettings_channelMinHopsSubtitle),
          value: settingsService.settings.channelMinHopsEnabled,
          onChanged: settingsService.setChannelMinHopsEnabled,
        ),
        if (settingsService.settings.channelMinHopsEnabled) ...[
          ListTile(
            title: Text(
              context.l10n.appSettings_channelMinHopsCount(
                settingsService.settings.channelMinHops,
              ),
            ),
            subtitle: Slider(
              value: settingsService.settings.channelMinHops.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              label: settingsService.settings.channelMinHops.toString(),
              onChanged: (value) =>
                  settingsService.setChannelMinHops(value.toInt()),
            ),
          ),
          ListTile(
            title: Text(
              context.l10n.appSettings_channelMinHopsRetries(
                settingsService.settings.channelMinHopsRetries,
              ),
            ),
            subtitle: Slider(
              value: settingsService.settings.channelMinHopsRetries.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: settingsService.settings.channelMinHopsRetries.toString(),
              onChanged: (value) =>
                  settingsService.setChannelMinHopsRetries(value.toInt()),
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            secondary: const Icon(Icons.hub_outlined, size: 24),
            title: Text(context.l10n.appSettings_channelMinHopsCountRepeaters),
            subtitle: Text(
              context.l10n.appSettings_channelMinHopsCountRepeatersSubtitle(
                settingsService.settings.channelMinHops,
              ),
            ),
            value: settingsService.settings.channelMinHopsCountRepeaters,
            onChanged: settingsService.setChannelMinHopsCountRepeaters,
          ),
        ],
      ],
    );
  }

  Widget _buildImageMessagesContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.image_search_outlined, size: 24),
          title: Text(context.l10n.appSettings_loadLinkImages),
          subtitle: Text(context.l10n.appSettings_loadLinkImagesSubtitle),
          value: settingsService.settings.loadLinkImages,
          onChanged: settingsService.setLoadLinkImages,
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: const Icon(Icons.collections_outlined, size: 24),
          title: Text(context.l10n.appSettings_showLinkImagesByDefault),
          subtitle: Text(
            context.l10n.appSettings_showLinkImagesByDefaultSubtitle,
          ),
          value: settingsService.settings.showLinkImagesByDefault,
          onChanged: settingsService.settings.loadLinkImages
              ? settingsService.setShowLinkImagesByDefault
              : null,
        ),
        const Divider(height: 1, indent: 16),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: const Icon(Icons.link_outlined, size: 20),
          title: Text(context.l10n.appSettings_ipfsImageLinks),
          subtitle: Text(context.l10n.appSettings_ipfsImageLinksSubtitle),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _showIpfsImageLinksDialog(context, settingsService),
        ),
        const Divider(height: 1, indent: 16),
        _ScrollIntoViewOnce(
          enabled: focusImageMessages,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            secondary: const Icon(Icons.image_outlined, size: 24),
            title: Text(context.l10n.imageMessages_enableTitle),
            subtitle: Text(context.l10n.imageMessages_enableSubtitle),
            value: settingsService.settings.imageMessagesEnabled,
            onChanged: (value) async {
              // ImageCodecService.availability requires BOTH the app-level
              // toggle and its own `enabled` preference; one switch drives both
              // so the user is never left with a silently half-on feature.
              final codec = _imageCodecService(context);
              await settingsService.setImageMessagesEnabled(value);
              await codec?.setEnabled(value);
            },
          ),
        ),
        if (settingsService.settings.imageMessagesEnabled) ...[
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            secondary: const Icon(Icons.auto_awesome_outlined, size: 24),
            title: Text(context.l10n.imageMessages_autoProcessTitle),
            subtitle: Text(context.l10n.imageMessages_autoProcessSubtitle),
            value: settingsService.settings.imageProcessAutomatically,
            onChanged: (value) =>
                settingsService.setImageProcessAutomatically(value),
          ),
          _buildImageCodecModels(context),
        ],
      ],
    );
  }

  /// The image codec, or null when it is not registered (screen tests).
  ImageCodecService? _imageCodecService(BuildContext context) {
    try {
      return Provider.of<ImageCodecService>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  void _showIpfsImageLinksDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (_) => _IpfsImageLinksDialog(settingsService: settingsService),
    );
  }

  /// Model registry for image messages: the download entry point, the
  /// downloaded weights, and — when the build simply cannot run the codec —
  /// [ImageCodecService.unavailableReason] instead of a dead download button.
  Widget _buildImageCodecModels(BuildContext context) {
    final ImageCodecService codec;
    try {
      codec = context.watch<ImageCodecService>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reason = codec.unavailableReason;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.imageMessages_modelSectionTitle,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (reason != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(MeshRadii.md),
              ),
              child: Text(
                reason,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final spec in imageCodecPresetModels)
            _buildImageCodecPreset(context, codec, spec),
          for (final model in codec.availableModels)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.check_circle_outline, size: 24),
              title: Text(model.name.isEmpty ? model.id : model.name),
              subtitle: Text(_formatModelBytes(context, model.fileSizeBytes)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 24),
                tooltip: context.l10n.imageMessages_removeModel,
                onPressed: codec.isBusy || codec.isDownloading
                    ? null
                    : () => codec.removeModel(model),
              ),
            ),
          if (codec.lastError != null) ...[
            const SizedBox(height: 6),
            Text(
              codec.lastError!,
              style: textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCodecPreset(
    BuildContext context,
    ImageCodecService codec,
    ImageCodecModelSpec spec,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final alreadyHave = codec.availableModels.any((m) => m.id == spec.id);
    // downloadPresetModel throws StateError on a placeholder URL, deliberately,
    // so the button must not be offerable until the weights are published.
    final blocked = spec.urlsArePlaceholders;
    final busy = codec.isDownloading;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.download_outlined, size: 24),
            title: Text(spec.label),
            subtitle: Text(
              blocked
                  ? context.l10n.imageMessages_modelNotPublished
                  : _formatModelBytes(context, spec.totalSizeBytes),
            ),
            trailing: alreadyHave
                ? Text(
                    context.l10n.imageMessages_modelReady,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : busy
                ? TextButton(
                    onPressed: codec.cancelDownload,
                    child: Text(context.l10n.imageMessages_cancelDownload),
                  )
                : TextButton(
                    onPressed: blocked
                        ? null
                        : () => _downloadImageCodecModel(context, codec, spec),
                    child: Text(context.l10n.imageMessages_downloadModel),
                  ),
          ),
          if (busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(value: codec.downloadProgress),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadImageCodecModel(
    BuildContext context,
    ImageCodecService codec,
    ImageCodecModelSpec spec,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await codec.downloadPresetModel(spec);
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.imageMessages_downloadFailedWithError('$error')),
        ),
      );
    }
  }

  String _formatModelBytes(BuildContext context, int bytes) {
    final l10n = context.l10n;
    if (bytes >= 1024 * 1024 * 1024) {
      return l10n.mapCache_sizeGigabytes(
        (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2),
      );
    }
    if (bytes >= 1024 * 1024) {
      return l10n.mapCache_sizeMegabytes(
        (bytes / (1024 * 1024)).toStringAsFixed(0),
      );
    }
    if (bytes >= 1024) {
      return l10n.mapCache_sizeKilobytes((bytes / 1024).toStringAsFixed(0));
    }
    return l10n.mapCache_sizeBytes('$bytes');
  }

  Widget _buildBatteryContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    // Only the three connector fields this card shows trigger a rebuild.
    final (deviceId, connected, deviceName) = context
        .select<MeshCoreConnector, (String?, bool, String)>(
          (c) => (c.batteryDeviceKey, c.isConnected, c.deviceDisplayName),
        );
    final isConnected = connected && deviceId != null;
    final selection = isConnected
        ? settingsService.batteryChemistryForDevice(deviceId)
        : 'nmc';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.battery_full,
                size: 24,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.appSettings_batteryChemistry,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? context.l10n.appSettings_batteryChemistryPerDevice(
                              deviceName,
                            )
                          : context
                                .l10n
                                .appSettings_batteryChemistryConnectFirst,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
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
            DropdownMenuItem(
              value: 'lipo_hv',
              child: Text(context.l10n.appSettings_batteryLipoHv),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final settings = settingsService.settings;
    const tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: tilePadding,
          secondary: const Icon(Icons.router_outlined, size: 24),
          title: Text(context.l10n.appSettings_showRepeaters),
          subtitle: Text(context.l10n.appSettings_showRepeatersSubtitle),
          value: settings.mapShowRepeaters,
          onChanged: (value) => settingsService.setMapShowRepeaters(value),
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: tilePadding,
          secondary: const Icon(Icons.chat_outlined, size: 24),
          title: Text(context.l10n.appSettings_showChatNodes),
          subtitle: Text(context.l10n.appSettings_showChatNodesSubtitle),
          value: settings.mapShowChatNodes,
          onChanged: (value) => settingsService.setMapShowChatNodes(value),
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          contentPadding: tilePadding,
          secondary: const Icon(Icons.people_outline, size: 24),
          title: Text(context.l10n.appSettings_showOtherNodes),
          subtitle: Text(context.l10n.appSettings_showOtherNodesSubtitle),
          value: settings.mapShowOtherNodes,
          onChanged: (value) => settingsService.setMapShowOtherNodes(value),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.timer_outlined,
          title: context.l10n.appSettings_timeFilter,
          subtitle: settings.mapTimeFilterHours == 0
              ? context.l10n.appSettings_timeFilterShowAll
              : context.l10n.appSettings_timeFilterShowLast(
                  settings.mapTimeFilterHours.toInt(),
                ),
          onTap: () => _showTimeFilterSheet(context, settingsService),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.straighten,
          title: context.l10n.appSettings_unitsTitle,
          subtitle: settings.unitSystem == UnitSystem.imperial
              ? context.l10n.appSettings_unitsImperial
              : context.l10n.appSettings_unitsMetric,
          onTap: () => _showUnitsSheet(context, settingsService),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.download_outlined,
          title: context.l10n.appSettings_offlineMapCache,
          subtitle: settings.mapCacheBounds == null
              ? context.l10n.appSettings_noAreaSelected
              : context.l10n.appSettings_areaSelectedZoom(
                  settings.mapCacheMinZoom,
                  settings.mapCacheMaxZoom,
                ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapCacheScreen()),
          ),
        ),
        const Divider(height: 1, indent: 16),
        MeshNavTile(
          icon: Icons.layers_outlined,
          title: context.l10n.appSettings_rasterTileSource,
          subtitle: _mapRasterSourceSummary(context, settings),
          subtitleMaxLines: 2,
          onTap: () => _showMapRasterSourceDialog(context, settingsService),
        ),
        if (_isStadiaSource(settings)) ...[
          const Divider(height: 1, indent: 16),
          MeshNavTile(
            icon: Icons.public_outlined,
            title: context.l10n.appSettings_stadiaEndpoint,
            subtitle: _mapRasterEndpointSummary(context, settings),
            onTap: () => _showMapRasterEndpointDialog(context, settingsService),
          ),
          const Divider(height: 1, indent: 16),
          MeshNavTile(
            icon: Icons.key_outlined,
            title: context.l10n.appSettings_stadiaApiKey,
            subtitle: _mapApiKeySummary(context, settings),
            onTap: () => _showMapApiKeyDialog(context, settingsService),
          ),
        ],
      ],
    );
  }

  String _mapRasterSourceSummary(BuildContext context, AppSettings settings) {
    final source = MapRasterSourceCatalog.fromSettings(settings);
    return context.l10n.appSettings_sourceSummary(
      source.label,
      source.description,
    );
  }

  bool _isStadiaSource(AppSettings settings) {
    return MapRasterSourceCatalog.fromSettings(settings).isStadia;
  }

  String _mapRasterEndpointSummary(BuildContext context, AppSettings settings) {
    final endpoint = MapRasterEndpointCatalog.fromSettings(settings);
    return context.l10n.appSettings_sourceSummary(
      endpoint.label,
      endpoint.description,
    );
  }

  String _mapApiKeySummary(BuildContext context, AppSettings settings) {
    return context.l10n.appSettings_stadiaApiKeyConfigured(
      _maskApiKey(settings.effectiveMapTileApiKey),
    );
  }

  String _maskApiKey(String value) {
    if (value.length <= 8) return '********';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  void _showMapRasterSourceDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    String selectedId = settingsService.settings.mapRasterSourceId;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(context.l10n.appSettings_rasterTileSource),
          content: SizedBox(
            width: 360,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: selectedId,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedId = value;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final preset in MapRasterSourcePreset.values)
                        Builder(
                          builder: (context) {
                            final option = MapRasterSourceCatalog.fromPreset(
                              preset,
                            );
                            return RadioListTile<String>(
                              value: preset.id,
                              title: Text(option.label),
                              subtitle: Text(option.description),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.common_cancel),
            ),
            TextButton(
              onPressed: () async {
                await settingsService.setMapRasterSourceId(selectedId);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(context.l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapRasterEndpointDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    String selectedId = settingsService.settings.mapTileEndpointId;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(context.l10n.appSettings_stadiaEndpoint),
          content: SizedBox(
            width: 360,
            child: RadioGroup<String>(
              groupValue: selectedId,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedId = value;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in MapRasterEndpointCatalog.presets)
                    RadioListTile<String>(
                      value: option.id,
                      title: Text(option.label),
                      subtitle: Text(option.description),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.common_cancel),
            ),
            TextButton(
              onPressed: () async {
                await settingsService.setMapTileEndpointId(selectedId);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(context.l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapApiKeyDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final currentApiKey = settingsService.settings.mapTileApiKey?.trim() ?? '';
    showDialog<void>(
      context: context,
      builder: (_) => _MapApiKeyDialog(
        settingsService: settingsService,
        currentApiKey: currentApiKey,
        maskedApiKey: _maskApiKey(
          currentApiKey.isEmpty ? AppSettings.stadiaDemo : currentApiKey,
        ),
      ),
    );
  }

  Widget _buildCyr2LatContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    final selectedProfile = settingsService.getSelectedCyr2LatProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: settingsService.settings.selectedCyr2latProfileId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.channels_cyr2latSettingsSubheading,
            border: const OutlineInputBorder(),
          ),
          items: settingsService.settings.cyr2latProfiles.map((profile) {
            return DropdownMenuItem(
              value: profile.id,
              child: Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              settingsService.setSelectedCyr2LatProfile(value);
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      Cyr2LatProfileDialog(settingsService: settingsService),
                ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.common_add),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Cyr2LatProfileDialog(
                    settingsService: settingsService,
                    profile: selectedProfile,
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: Text(context.l10n.common_edit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: settingsService.settings.cyr2latProfiles.length > 1
                    ? () => _showDeleteCyr2LatProfileDialog(
                        context,
                        settingsService,
                        selectedProfile,
                      )
                    : null,
                icon: const Icon(Icons.delete),
                label: Text(context.l10n.common_delete),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDebugContent(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: const Icon(Icons.bug_report_outlined, size: 24),
      title: Text(context.l10n.appSettings_appDebugLogging),
      subtitle: Text(context.l10n.appSettings_appDebugLoggingSubtitle),
      value: settingsService.settings.appDebugLogEnabled,
      onChanged: (value) async {
        await settingsService.setAppDebugLogEnabled(value);
        if (!context.mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(
            value
                ? context.l10n.appSettings_appDebugLoggingEnabled
                : context.l10n.appSettings_appDebugLoggingDisabled,
          ),
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  void _showTimeFilterSheet(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showMeshSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(title: context.l10n.appSettings_mapTimeFilter),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(context.l10n.appSettings_showNodesDiscoveredWithin),
            ),
            MeshSheetOption(
              label: context.l10n.appSettings_allTime,
              selected: settingsService.settings.mapTimeFilterHours == 0,
              onTap: () {
                settingsService.setMapTimeFilterHours(0);
                Navigator.pop(ctx);
              },
            ),
            MeshSheetOption(
              label: context.l10n.appSettings_lastHour,
              selected: settingsService.settings.mapTimeFilterHours == 1,
              onTap: () {
                settingsService.setMapTimeFilterHours(1);
                Navigator.pop(ctx);
              },
            ),
            MeshSheetOption(
              label: context.l10n.appSettings_last6Hours,
              selected: settingsService.settings.mapTimeFilterHours == 6,
              onTap: () {
                settingsService.setMapTimeFilterHours(6);
                Navigator.pop(ctx);
              },
            ),
            MeshSheetOption(
              label: context.l10n.appSettings_last24Hours,
              selected: settingsService.settings.mapTimeFilterHours == 24,
              onTap: () {
                settingsService.setMapTimeFilterHours(24);
                Navigator.pop(ctx);
              },
            ),
            MeshSheetOption(
              label: context.l10n.appSettings_lastWeek,
              selected: settingsService.settings.mapTimeFilterHours == 168,
              onTap: () {
                settingsService.setMapTimeFilterHours(168);
                Navigator.pop(ctx);
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showUnitsSheet(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showMeshSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(title: context.l10n.appSettings_unitsTitle),
            MeshSheetOption(
              label: context.l10n.appSettings_unitsMetric,
              selected:
                  settingsService.settings.unitSystem == UnitSystem.metric,
              onTap: () {
                settingsService.setUnitSystem(UnitSystem.metric);
                Navigator.pop(ctx);
              },
            ),
            MeshSheetOption(
              label: context.l10n.appSettings_unitsImperial,
              selected:
                  settingsService.settings.unitSystem == UnitSystem.imperial,
              onTap: () {
                settingsService.setUnitSystem(UnitSystem.imperial);
                Navigator.pop(ctx);
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteCyr2LatProfileDialog(
    BuildContext context,
    AppSettingsService settingsService,
    Cyr2LatProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settings_cyr2latProfileDelete),
        content: Text(
          context.l10n.settings_cyr2latProfileDeleteDscr(profile.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              await settingsService.removeCyr2LatProfile(profile.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              showDismissibleSnackBar(
                context,
                content: Text(context.l10n.settings_cyr2latProfileDeleted),
              );
            },
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );
  }
}

class _IpfsImageLinksDialog extends StatefulWidget {
  const _IpfsImageLinksDialog({required this.settingsService});

  final AppSettingsService settingsService;

  @override
  State<_IpfsImageLinksDialog> createState() => _IpfsImageLinksDialogState();
}

class _IpfsImageLinksDialogState extends State<_IpfsImageLinksDialog> {
  late final TextEditingController _publicController;
  late final TextEditingController _uploadGatewayController;
  late final TextEditingController _endpointController;
  late final TextEditingController _apiKeyController;
  final FocusNode _apiKeyFocus = FocusNode();
  late final String _currentApiKey;
  late final String _maskedApiKey;
  late String _selectedGateway;
  late String _selectedUploadProvider;
  bool _apiKeyChanged = false;
  bool _apiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    final settings = widget.settingsService.settings;
    _publicController = TextEditingController(
      text: normalizeIpfsGateway(settings.publicIpfsGateway),
    );
    _uploadGatewayController = TextEditingController(
      text: normalizeIpfsGateway(settings.uploadIpfsGateway),
    );
    _endpointController = TextEditingController(
      text: settings.uploadIpfsEndpoint,
    );
    _currentApiKey = settings.uploadIpfsApiKey.trim();
    _maskedApiKey = _currentApiKey.isEmpty ? '' : _maskApiKey(_currentApiKey);
    _apiKeyController = TextEditingController(text: _maskedApiKey);
    _apiKeyFocus.addListener(_onApiKeyFocusChanged);
    _selectedGateway = _gatewayPreset(_publicController.text);
    _selectedUploadProvider = _uploadProvider(
      _uploadGatewayController.text,
      _endpointController.text,
      _currentApiKey,
    );
  }

  @override
  void dispose() {
    _publicController.dispose();
    _uploadGatewayController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _apiKeyFocus.dispose();
    super.dispose();
  }

  /// Swaps the masked key out while the field has focus (by tap, Tab or
  /// keyboard) so typing never appends to the mask, and puts it back if the
  /// user leaves without editing.
  void _onApiKeyFocusChanged() {
    if (_apiKeyChanged) return;
    _apiKeyController.text = _apiKeyFocus.hasFocus ? '' : _maskedApiKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.appSettings_ipfsImageLinks),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appSettings_ipfsImageLinksDescription),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedGateway,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.appSettings_publicIpfsGateway,
              ),
              items: [
                DropdownMenuItem(
                  value: 'deactivated',
                  child: Text(l10n.appSettings_ipfsGatewayDeactivated),
                ),
                DropdownMenuItem(
                  value: 'ipfsio',
                  child: Text(l10n.appSettings_ipfsGatewayIpfsIo),
                ),
                DropdownMenuItem(
                  value: 'pinata',
                  child: Text(l10n.appSettings_ipfsGatewayPinata),
                ),
                DropdownMenuItem(
                  value: 'filebase',
                  child: Text(l10n.appSettings_ipfsGatewayFilebase),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text(l10n.appSettings_ipfsGatewayCustom),
                ),
              ],
              onChanged: _selectGateway,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _publicController,
              decoration: InputDecoration(
                labelText: l10n.appSettings_publicIpfsGateway,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (_) {
                if (_selectedGateway != 'custom') {
                  setState(() => _selectedGateway = 'custom');
                }
              },
            ),
            const Divider(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedUploadProvider,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.appSettings_uploadIpfsProvider,
              ),
              items: [
                DropdownMenuItem(
                  value: 'pinata',
                  child: Text(l10n.appSettings_ipfsGatewayPinata),
                ),
                DropdownMenuItem(
                  value: 'filebase',
                  child: Text(l10n.appSettings_ipfsGatewayFilebase),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text(l10n.appSettings_ipfsGatewayCustom),
                ),
                DropdownMenuItem(
                  value: 'deactivated',
                  child: Text(l10n.appSettings_ipfsGatewayDeactivated),
                ),
              ],
              onChanged: _selectUploadProvider,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _uploadGatewayController,
              decoration: InputDecoration(
                labelText: l10n.appSettings_uploadIpfsGateway,
                helperText: l10n.appSettings_uploadIpfsGatewaySubtitle,
                helperMaxLines: 3,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (_) => _markCustomUploadProvider(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _endpointController,
              decoration: InputDecoration(
                labelText: l10n.appSettings_uploadIpfsEndpoint,
                helperText: l10n.appSettings_uploadIpfsEndpointSubtitle,
                helperMaxLines: 3,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (_) => _markCustomUploadProvider(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyController,
              focusNode: _apiKeyFocus,
              decoration: InputDecoration(
                labelText: l10n.appSettings_uploadIpfsApiKey,
                suffixIcon: IconButton(
                  tooltip: _apiKeyObscured
                      ? l10n.appSettings_showApiKey
                      : l10n.appSettings_hideApiKey,
                  icon: Icon(
                    _apiKeyObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _apiKeyObscured = !_apiKeyObscured),
                ),
              ),
              autocorrect: false,
              enableSuggestions: false,
              obscureText: _apiKeyObscured,
              onChanged: (_) {
                _apiKeyChanged = true;
                _markCustomUploadProvider();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.common_save)),
      ],
    );
  }

  void _selectGateway(String? value) {
    if (value == null) return;
    setState(() {
      _selectedGateway = value;
      final preset = _gatewayValue(value);
      if (preset != null) _publicController.text = preset;
    });
  }

  void _selectUploadProvider(String? value) {
    if (value == null) return;
    setState(() {
      _selectedUploadProvider = value;
      final preset = _uploadPreset(value);
      if (preset != null) {
        _uploadGatewayController.text = preset.gateway;
        _endpointController.text = preset.endpoint;
        if (value == 'deactivated') _apiKeyController.clear();
      }
    });
  }

  void _markCustomUploadProvider() {
    if (_selectedUploadProvider != 'custom') {
      setState(() => _selectedUploadProvider = 'custom');
    }
  }

  Future<void> _save() async {
    final deactivated = _selectedUploadProvider == 'deactivated';
    final apiKey = _apiKeyController.text.trim();
    await widget.settingsService.setIpfsImageSettings(
      publicGateway: _publicController.text,
      uploadGateway: deactivated ? '' : _uploadGatewayController.text,
      uploadEndpoint: deactivated ? '' : _endpointController.text,
      uploadApiKey: deactivated
          ? ''
          : _apiKeyChanged && apiKey != _maskedApiKey
          ? apiKey
          : _currentApiKey,
    );
    if (mounted) Navigator.pop(context);
  }

  String _gatewayPreset(String value) {
    if (value.isEmpty) return 'deactivated';
    if (value == AppSettings.defaultPublicIpfsGateway ||
        value == 'https://ipfs.io/ipfs') {
      return 'ipfsio';
    }
    if (value == 'https://gateway.pinata.cloud/ipfs/' ||
        value == 'https://gateway.pinata.cloud/ipfs') {
      return 'pinata';
    }
    if (value == 'https://ipfs.filebase.io/ipfs/' ||
        value == 'https://ipfs.filebase.io/ipfs') {
      return 'filebase';
    }
    return 'custom';
  }

  String? _gatewayValue(String preset) {
    switch (preset) {
      case 'deactivated':
        return '';
      case 'ipfsio':
        return AppSettings.defaultPublicIpfsGateway;
      case 'pinata':
        return 'https://gateway.pinata.cloud/ipfs/';
      case 'filebase':
        return 'https://ipfs.filebase.io/ipfs/';
      case 'custom':
        return 'http://127.0.0.1:8080/ipfs/';
      default:
        return null;
    }
  }

  String _uploadProvider(String gateway, String endpoint, String apiKey) {
    if (gateway.isEmpty && endpoint.isEmpty && apiKey.isEmpty) {
      return 'deactivated';
    }
    if (gateway == 'https://gateway.pinata.cloud/ipfs/' &&
        endpoint == 'https://api.pinata.cloud/pinning/pinFileToIPFS') {
      return 'pinata';
    }
    if (gateway == 'https://ipfs.filebase.io/ipfs/' &&
        endpoint == 'https://rpc.filebase.io/api/v0/add') {
      return 'filebase';
    }
    return 'custom';
  }

  ({String gateway, String endpoint})? _uploadPreset(String preset) {
    switch (preset) {
      case 'pinata':
        return (
          gateway: 'https://gateway.pinata.cloud/ipfs/',
          endpoint: 'https://api.pinata.cloud/pinning/pinFileToIPFS',
        );
      case 'filebase':
        return (
          gateway: 'https://ipfs.filebase.io/ipfs/',
          endpoint: 'https://rpc.filebase.io/api/v0/add',
        );
      case 'custom':
        return (
          gateway: 'http://127.0.0.1:8080/ipfs/',
          endpoint: 'http://127.0.0.1:5001/api/v0/add',
        );
      case 'deactivated':
        return (gateway: '', endpoint: '');
      default:
        return null;
    }
  }

  String _maskApiKey(String value) {
    if (value.length <= 8) return '********';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}

/// Stadia API key editor. Owns (and disposes) its controller; the key is
/// obscured by default with a visibility toggle. The field starts with the
/// masked current key, and saving it unchanged keeps the current key.
class _MapApiKeyDialog extends StatefulWidget {
  final AppSettingsService settingsService;
  final String currentApiKey;
  final String maskedApiKey;

  const _MapApiKeyDialog({
    required this.settingsService,
    required this.currentApiKey,
    required this.maskedApiKey,
  });

  @override
  State<_MapApiKeyDialog> createState() => _MapApiKeyDialogState();
}

class _MapApiKeyDialogState extends State<_MapApiKeyDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.maskedApiKey,
  );
  bool _obscured = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final apiKey = _controller.text.trim();
    await widget.settingsService.setMapTileApiKey(
      apiKey == widget.maskedApiKey ? widget.currentApiKey : apiKey,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.appSettings_stadiaApiKey),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appSettings_stadiaApiKeyDialogDescription),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: _obscured,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '4e1bf343-3d91-4d9c-a8e1-1234567890ab',
                suffixIcon: IconButton(
                  tooltip: _obscured
                      ? l10n.appSettings_showApiKey
                      : l10n.appSettings_hideApiKey,
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.common_save)),
      ],
    );
  }
}

/// Scrolls [child] into view exactly once, after the first frame.
///
/// A `StatefulWidget` rather than a post-frame callback in `build` because the
/// settings screen rebuilds on every `AppSettingsService` notification: a
/// callback in `build` would yank the list back to the image block every time
/// the user touched an unrelated switch.
///
/// Silently does nothing when there is no enclosing [Scrollable] (screen tests
/// that render a section in isolation) or when the element is gone by the time
/// the frame lands.
class _ScrollIntoViewOnce extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _ScrollIntoViewOnce({required this.enabled, required this.child});

  @override
  State<_ScrollIntoViewOnce> createState() => _ScrollIntoViewOnceState();
}

class _ScrollIntoViewOnceState extends State<_ScrollIntoViewOnce> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
