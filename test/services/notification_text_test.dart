import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/gif_helper.dart';
import 'package:meshcore_open/helpers/reaction_helper.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/notification_service.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/widgets/marker_label_dialog.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String format(String text) =>
      NotificationService.formatNotificationText(text, l10n);

  test('shared locations show a summary instead of coordinates', () {
    expect(
      format(formatMarkerText(45.5, -122.6, 'Camp', 'poi')),
      'Shared a location: Camp',
    );
    expect(
      format(formatMarkerText(45.5, -122.6, '', 'poi')),
      'Shared a location',
    );
  });

  test('reactions, GIFs and images are summarized', () {
    expect(
      format(ReactionHelper.encodeReaction('ab12', '00')),
      startsWith('Reacted '),
    );
    expect(format('👍\nabcd2345'), 'Reacted 👍');
    expect(format(GifHelper.encodeGif('xT9IgG50Fb7Mi0prBC')), 'Sent a GIF');
    expect(
      format('https://media.giphy.com/media/xT9IgG50Fb7Mi0prBC/giphy.gif'),
      'Sent a GIF',
    );
    expect(format(ReceivedImageRef.encode('0a1b2c3d4e5f60')), 'Sent an image');
  });

  test('plain text is unchanged', () {
    expect(format('see you at m:ain street'), 'see you at m:ain street');
    expect(format('hello'), 'hello');
  });
}
