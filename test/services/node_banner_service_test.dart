import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_open/services/node_banner_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _record =
    'v=1;on=1;url=https%3A%2F%2Fshop.example.com%2Fnode%3Fref%3Da%26b%3Dc;'
    'title=Need%20a%20node%3F';

String _doh(String data, {int status = 0, int ttl = 300}) => jsonEncode({
  'Status': status,
  'Answer': [
    {'name': '_banner.meshcoreopen.org', 'type': 16, 'TTL': ttl, 'data': data},
  ],
});

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  group('NodeBannerConfig.parse', () {
    test('reads the link and decodes text overrides', () {
      final config = NodeBannerConfig.parse(_record)!;
      expect(config.url.toString(), 'https://shop.example.com/node?ref=a&b=c');
      expect(config.title, 'Need a node?');
      expect(config.body, isNull);
      expect(config.action, isNull);
    });

    test('accepts plain-text values', () {
      final config = NodeBannerConfig.parse(
        'v=1;on=1;url=https://shop.example.com/node?ref=a&b=c;'
        'title=Need a new node?;body=Waterproof, 50% off this week.;'
        'cta=Get one here',
      )!;
      expect(config.url.toString(), 'https://shop.example.com/node?ref=a&b=c');
      expect(config.title, 'Need a new node?');
      expect(config.body, 'Waterproof, 50% off this week.');
      expect(config.action, 'Get one here');
    });

    test('is off for on=0, unknown versions, and non-https links', () {
      expect(
        NodeBannerConfig.parse(_record.replaceAll('on=1', 'on=0')),
        isNull,
      );
      expect(NodeBannerConfig.parse(_record.replaceAll('v=1', 'v=2')), isNull);
      expect(NodeBannerConfig.parse('v=1;on=1;url=http%3A%2F%2Fx.com'), isNull);
      expect(NodeBannerConfig.parse('v=1;on=1'), isNull);
      expect(NodeBannerConfig.parse('v=1;on=1;url=%E0%A4%A'), isNull);
    });
  });

  test('joins split TXT character-strings and unescapes them', () {
    final answer = NodeBannerService.txtFromDohJson(
      _doh(r'"v=1;on=1;url=https%3A%2F%2Fa.com" ";title=Say \"hi\""'),
    )!;
    expect(answer.text, 'v=1;on=1;url=https%3A%2F%2Fa.com;title=Say "hi"');
    expect(answer.ttl, 300);
  });

  test('no record or NXDOMAIN gives no answer', () {
    expect(NodeBannerService.txtFromDohJson(jsonEncode({'Status': 3})), isNull);
    expect(NodeBannerService.txtFromDohJson(jsonEncode({'Status': 0})), isNull);
  });

  test('load queries Cloudflare DoH and caches for the TTL', () async {
    var calls = 0;
    var now = DateTime(2026, 1, 1);
    final client = MockClient((request) async {
      calls++;
      expect(request.url.host, 'cloudflare-dns.com');
      expect(request.url.queryParameters['name'], '_banner.meshcoreopen.org');
      expect(request.url.queryParameters['type'], 'TXT');
      expect(request.headers['accept'], 'application/dns-json');
      return http.Response(_doh('"$_record"'), 200);
    });
    final service = NodeBannerService(client: client, now: () => now);

    expect((await service.load())?.title, 'Need a node?');
    expect((await service.load())?.title, 'Need a node?');
    expect(calls, 1);

    now = now.add(const Duration(minutes: 6));
    await service.load();
    expect(calls, 2);
  });

  test('load returns null when the lookup fails', () async {
    final failing = NodeBannerService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await failing.load(), isNull);

    final serverError = NodeBannerService(
      client: MockClient((_) async => http.Response('', 503)),
    );
    expect(await serverError.load(), isNull);
  });
}
