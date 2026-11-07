import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/local_api/local_api_pairing_dialog.dart';
import 'package:meshcore_open/services/local_api/local_api_service.dart';

void main() {
  late LocalApiService service;

  setUp(() => service = LocalApiService());

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LocalApiPairingHost(child: Scaffold()),
    ),
  );

  Future<bool> ask(String key) => service.pairingBroker.ask(
    name: 'Roadbeacon',
    version: '0.4.0',
    publicKey: key,
    fingerprint: 'AB12 CD34 EF56 7890',
  );

  testWidgets('Allow answers the request', (tester) async {
    await pumpHost(tester);
    final answer = ask('a');
    await tester.pumpAndSettle();
    expect(find.text('AB12 CD34 EF56 7890'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the dialog closes when its request ends', (tester) async {
    await pumpHost(tester);
    final ids = <String>[];
    service.pairingBroker.requests.listen((request) => ids.add(request.id));
    final answer = ask('b');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    service.pairingBroker.cancel(ids.single);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await answer, isFalse);
  });

  testWidgets('a channel request names the channel and adds it', (
    tester,
  ) async {
    await pumpHost(tester);
    final answer = service.pairingBroker.ask(
      name: 'Roadstr',
      version: '',
      publicKey: 'c',
      fingerprint: '',
      channelName: '#roadstr',
    );
    await tester.pumpAndSettle();
    expect(find.text('Add a channel?'), findsOneWidget);
    expect(
      find.text(
        '“Roadstr” wants to add the hashtag channel #roadstr to your radio.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
  });
}
