import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../storage/prefs_manager.dart';

/// DNS name whose TXT record configures the connect screen's "get a node"
/// banner, e.g. `v=1;on=1;url=https%3A%2F%2F...;title=...`.
const String nodeBannerRecordName = '_banner.meshcoreopen.org';

const String _dohEndpoint = 'https://cloudflare-dns.com/dns-query';
const String _cacheRecordKey = 'node_banner_txt';
const String _cacheExpiryKey = 'node_banner_expires_ms';
const int _dnsTypeTxt = 16;

/// Banner content from the TXT record. Null text fields fall back to the
/// app's localized strings.
class NodeBannerConfig {
  final Uri url;
  final String? title;
  final String? body;
  final String? action;

  const NodeBannerConfig({
    required this.url,
    this.title,
    this.body,
    this.action,
  });

  /// Parses `key=value` pairs separated by `;`. Values may be plain text;
  /// percent-encoding is decoded when valid, so `%3B` can carry a `;`.
  /// Returns null when the banner is switched off (`on=0`), the version is
  /// unknown, or the link is missing or not https.
  static NodeBannerConfig? parse(String record) {
    final fields = <String, String>{};
    for (final pair in record.split(';')) {
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      final raw = pair.substring(eq + 1).trim();
      String value;
      try {
        value = Uri.decodeComponent(raw);
      } on ArgumentError {
        value = raw;
      }
      fields[pair.substring(0, eq).trim().toLowerCase()] = value;
    }
    if (fields['v'] != '1' || fields['on'] != '1') return null;
    final url = Uri.tryParse(fields['url'] ?? '');
    if (url == null || url.scheme != 'https' || url.host.isEmpty) return null;
    String? text(String key) {
      final value = fields[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    return NodeBannerConfig(
      url: url,
      title: text('title'),
      body: text('body'),
      action: text('cta'),
    );
  }
}

/// Looks up the banner's TXT record over DNS-over-HTTPS and caches it for
/// the record's TTL. Any failure means no banner.
class NodeBannerService {
  final http.Client _client;
  final DateTime Function() _now;

  NodeBannerService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  Future<NodeBannerConfig?> load() async {
    try {
      final prefs = PrefsManager.instance;
      final expires = prefs.getInt(_cacheExpiryKey) ?? 0;
      final cached = prefs.getString(_cacheRecordKey);
      if (cached != null && _now().millisecondsSinceEpoch < expires) {
        return NodeBannerConfig.parse(cached);
      }

      final response = await _client
          .get(
            Uri.parse(_dohEndpoint).replace(
              queryParameters: {'name': nodeBannerRecordName, 'type': 'TXT'},
            ),
            headers: const {'accept': 'application/dns-json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final answer = txtFromDohJson(response.body);
      if (answer == null) return null;

      final ttl = answer.ttl.clamp(60, 6 * 3600);
      await prefs.setString(_cacheRecordKey, answer.text);
      await prefs.setInt(
        _cacheExpiryKey,
        _now().add(Duration(seconds: ttl)).millisecondsSinceEpoch,
      );
      return NodeBannerConfig.parse(answer.text);
    } catch (e) {
      debugPrint('Node banner lookup failed: $e');
      return null;
    }
  }

  /// The first TXT answer in a DoH JSON response, with its character-strings
  /// joined, or null when the name has no TXT record.
  @visibleForTesting
  static ({String text, int ttl})? txtFromDohJson(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['Status'] != 0) return null;
    for (final answer in (json['Answer'] as List<dynamic>? ?? const [])) {
      final record = answer as Map<String, dynamic>;
      if (record['type'] != _dnsTypeTxt) continue;
      return (
        text: _joinCharacterStrings(record['data'] as String),
        ttl: (record['TTL'] as num?)?.toInt() ?? 300,
      );
    }
    return null;
  }

  /// Joins the quoted character-strings of TXT presentation data
  /// (`"a" "b"` -> `ab`), undoing `\"`, `\\` and `\DDD` escapes.
  static String _joinCharacterStrings(String data) {
    if (!data.contains('"')) return data;
    final out = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < data.length; i++) {
      final c = data[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes) {
        continue;
      } else if (c == r'\' && i + 1 < data.length) {
        final digits = i + 3 < data.length ? data.substring(i + 1, i + 4) : '';
        final code = int.tryParse(digits);
        if (digits.length == 3 && code != null) {
          out.writeCharCode(code);
          i += 3;
        } else {
          out.write(data[++i]);
        }
      } else {
        out.write(c);
      }
    }
    return out.toString();
  }
}
