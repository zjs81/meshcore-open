import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('outgoing translation skips contact-share tokens', () async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.setComposerTranslationEnabled(true);
    final translation = TranslationService(settings);
    const token =
        '<50ba28f599799142622d188469a63f3890d495cdcedd24239052abd364c0283d:1:CC>';

    expect(
      translation.shouldTranslateOutgoing(
        text: token,
        targetLanguageCode: 'de',
      ),
      isFalse,
    );
    expect(
      translation.shouldTranslateOutgoing(
        text: 'hello there',
        targetLanguageCode: 'de',
      ),
      isTrue,
    );
  });
}
