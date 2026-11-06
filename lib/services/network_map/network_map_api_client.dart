import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const String networkMapBaseUrl = 'https://map.meshcoreopen.org';

/// Largest bbox span the read endpoints accept, in degrees.
const double networkMapMaxBboxSpan = 20.0;

class NetworkMapBbox {
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  const NetworkMapBbox({
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });

  bool get isWithinLimit =>
      maxLon - minLon <= networkMapMaxBboxSpan &&
      maxLat - minLat <= networkMapMaxBboxSpan;

  /// Valid request boxes for a visible area, or null when it is larger than
  /// [networkMapMaxBboxSpan]. [west] and [east] may be unwrapped (beyond
  /// ±180) or wrapped across the antimeridian (west > east); an area that
  /// crosses ±180 is split into two boxes, one on each side.
  static List<NetworkMapBbox>? forVisibleArea({
    required double west,
    required double south,
    required double east,
    required double north,
  }) {
    final minLat = south.clamp(-90.0, 90.0);
    final maxLat = north.clamp(-90.0, 90.0);
    var span = east - west;
    if (span < 0) span += 360;
    if (span > networkMapMaxBboxSpan ||
        maxLat - minLat > networkMapMaxBboxSpan) {
      return null;
    }
    final w = (west + 180) % 360 - 180; // Dart % is non-negative here.
    final e = w + span;
    NetworkMapBbox box(double a, double b) =>
        NetworkMapBbox(minLon: a, minLat: minLat, maxLon: b, maxLat: maxLat);
    if (e <= 180) return [box(w, e)];
    return [box(w, 180), box(-180, e - 360)];
  }

  String get query => [
    minLon,
    minLat,
    maxLon,
    maxLat,
  ].map((v) => v.toStringAsFixed(5)).join(',');
}

/// An H3 cell as the server describes it. [boundary] is the open polygon
/// (usually six points), so clients need no H3 library.
class NetworkMapCell {
  final String cell;
  final LatLng center;
  final List<LatLng> boundary;

  const NetworkMapCell({
    required this.cell,
    required this.center,
    required this.boundary,
  });

  factory NetworkMapCell.fromJson(Map<String, dynamic> json) {
    return NetworkMapCell(
      cell: json['cell'] as String,
      center: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lon'] as num).toDouble(),
      ),
      boundary: [
        for (final point in (json['boundary'] as List? ?? const []))
          LatLng(
            ((point as List)[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ),
      ],
    );
  }
}

enum NetworkMapRepeaterStatus { active, recent, stale }

class NetworkMapRepeater {
  final String key;
  final String? name;
  final int type;
  final NetworkMapCell cell;
  final String locationSource;
  final double confidence;
  final NetworkMapRepeaterStatus status;
  final bool confirmed;
  final int sightings;
  final DateTime? firstSeen;
  final DateTime? lastSeen;

  // Only present on the single-repeater endpoint.
  final int? links;
  final int? coverageCells;
  final String? reachableArea;

  const NetworkMapRepeater({
    required this.key,
    required this.name,
    required this.type,
    required this.cell,
    required this.locationSource,
    required this.confidence,
    required this.status,
    required this.confirmed,
    required this.sightings,
    required this.firstSeen,
    required this.lastSeen,
    this.links,
    this.coverageCells,
    this.reachableArea,
  });

  bool get isEstimated => locationSource == 'estimated';

  factory NetworkMapRepeater.fromJson(Map<String, dynamic> json) {
    return NetworkMapRepeater(
      key: (json['key'] as String).toLowerCase(),
      name: json['name'] as String?,
      type: (json['type'] as num?)?.toInt() ?? 2,
      cell: NetworkMapCell.fromJson(json['cell'] as Map<String, dynamic>),
      locationSource: json['locationSource'] as String? ?? 'advert',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      status: NetworkMapRepeaterStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NetworkMapRepeaterStatus.stale,
      ),
      confirmed: json['confirmed'] as bool? ?? false,
      sightings: (json['sightings'] as num?)?.toInt() ?? 0,
      firstSeen: _parseTime(json['firstSeen']),
      lastSeen: _parseTime(json['lastSeen']),
      links: (json['links'] as num?)?.toInt(),
      coverageCells: (json['coverageCells'] as num?)?.toInt(),
      reachableArea: json['reachableArea'] as String?,
    );
  }
}

class NetworkMapLink {
  final String a;
  final String b;
  final NetworkMapCell aCell;
  final NetworkMapCell bCell;
  final int packets;
  final double? snr;
  final bool confirmed;

  const NetworkMapLink({
    required this.a,
    required this.b,
    required this.aCell,
    required this.bCell,
    required this.packets,
    required this.snr,
    required this.confirmed,
  });

  factory NetworkMapLink.fromJson(Map<String, dynamic> json) {
    return NetworkMapLink(
      a: (json['a'] as String).toLowerCase(),
      b: (json['b'] as String).toLowerCase(),
      aCell: NetworkMapCell.fromJson(json['aCell'] as Map<String, dynamic>),
      bCell: NetworkMapCell.fromJson(json['bCell'] as Map<String, dynamic>),
      packets: (json['packets'] as num?)?.toInt() ?? 0,
      snr: (json['snr'] as num?)?.toDouble(),
      confirmed: json['confirmed'] as bool? ?? false,
    );
  }
}

DateTime? _parseTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

class NetworkMapApiException implements Exception {
  final int statusCode;

  const NetworkMapApiException(this.statusCode);

  @override
  String toString() => 'NetworkMapApiException($statusCode)';
}

/// Read-only client for the network map. Viewing never requires the upload
/// opt-in and sends nothing about the radio.
class NetworkMapApiClient {
  final http.Client _client;
  final String baseUrl;

  NetworkMapApiClient({http.Client? client, this.baseUrl = networkMapBaseUrl})
    : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 20);

  Future<List<NetworkMapRepeater>> fetchRepeaters(NetworkMapBbox bbox) async {
    final json = await _get('/v1/repeaters', {
      'bbox': bbox.query,
      'includeUnconfirmed': 'true',
    });
    return [
      for (final item in (json['repeaters'] as List? ?? const []))
        NetworkMapRepeater.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Null when the repeater is unknown or hidden (404).
  Future<NetworkMapRepeater?> fetchRepeater(String key) async {
    try {
      return NetworkMapRepeater.fromJson(
        await _get('/v1/repeaters/${key.toLowerCase()}', const {}),
      );
    } on NetworkMapApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<NetworkMapLink>> fetchLinks(
    NetworkMapBbox bbox, {
    String window = '7d',
  }) async {
    final json = await _get('/v1/links', {
      'bbox': bbox.query,
      'window': window,
    });
    return [
      for (final item in (json['links'] as List? ?? const []))
        NetworkMapLink.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw NetworkMapApiException(response.statusCode);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  void close() => _client.close();
}
