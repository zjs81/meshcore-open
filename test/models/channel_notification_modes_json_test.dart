import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/app_settings.dart';

void main() {
  test('channel notification modes round-trip by name', () {
    final settings = AppSettings(
      channelNotificationModes: {
        'a': ChannelNotificationMode.mentionsOnly,
        'b': ChannelNotificationMode.muted,
      },
    );
    final json = settings.toJson();
    expect(json['channel_notification_modes'], {
      'a': 'mentionsOnly',
      'b': 'muted',
    });
    expect(json['muted_channels'], ['b']);
    expect(
      AppSettings.fromJson(json).channelNotificationModes,
      settings.channelNotificationModes,
    );
  });

  test('invalid channel notification mode entries are skipped', () {
    final settings = AppSettings.fromJson({
      'channel_notification_modes': {
        'ok': 'muted',
        'unknown': 'loud',
        'int': 2,
        'null': null,
      },
    });
    expect(settings.channelNotificationModes, {
      'ok': ChannelNotificationMode.muted,
    });
  });
}
