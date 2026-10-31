import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_settings_service.dart'
    show AppSettingsService, ChannelNotificationMode;
import 'mesh_ui.dart';

/// Localized label for a channel notification [mode].
String channelNotificationModeLabel(
  BuildContext context,
  ChannelNotificationMode mode,
) => switch (mode) {
  ChannelNotificationMode.all => context.l10n.channels_notifyAll,
  ChannelNotificationMode.mentionsOnly =>
    context.l10n.channels_notifyMentionsOnly,
  ChannelNotificationMode.muted => context.l10n.channels_notifyNone,
};

/// Icon for a channel notification [mode].
IconData channelNotificationModeIcon(ChannelNotificationMode mode) =>
    switch (mode) {
      ChannelNotificationMode.all => Icons.notifications,
      ChannelNotificationMode.mentionsOnly => Icons.notification_important,
      ChannelNotificationMode.muted => Icons.notifications_off,
    };

/// Shows the per-channel notification mode picker (all / mentions only /
/// muted) for the channel identified by [muteKey].
void showChannelNotificationModeSheet(BuildContext context, String muteKey) {
  final settingsService = context.read<AppSettingsService>();
  final currentMode = settingsService.getChannelNotificationMode(muteKey);

  showMeshSheet(
    context,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ChannelNotificationMode.values)
                ListTile(
                  leading: Icon(
                    channelNotificationModeIcon(mode),
                    color: mode == currentMode
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  title: Text(channelNotificationModeLabel(sheetContext, mode)),
                  trailing: mode == currentMode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await settingsService.setChannelNotificationMode(
                      muteKey,
                      mode,
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
