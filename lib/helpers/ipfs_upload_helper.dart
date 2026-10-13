import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_settings.dart';

class IpfsUploadHelper {
  static http.Client? httpClient;

  static String mimeTypeForFileName(String fileName) {
    switch (fileName.toLowerCase().split('.').last) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<String> uploadImageWithSettings({
    required AppSettings settings,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return uploadImage(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      uploadEndpoint: settings.uploadIpfsEndpoint,
      uploadApiKey: settings.uploadIpfsApiKey,
      uploadGateway: settings.uploadIpfsGateway,
    );
  }

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String uploadEndpoint,
    required String uploadApiKey,
    String uploadGateway = '',
  }) async {
    final endpoint = uploadEndpoint.trim();
    if (endpoint.isEmpty) {
      throw ArgumentError('Configure an IPFS upload endpoint first.');
    }

    final token = uploadApiKey.trim();
    final endpointUri = Uri.parse(endpoint);
    final endpointHost = endpointUri.host.toLowerCase();
    final isPinata =
        endpointHost.contains('pinata') ||
        endpoint.toLowerCase().contains('pinfiletoipfs');
    final isFilebase = endpointHost.contains('filebase');
    final isKubo = !isPinata && !isFilebase;
    final safeFileName = _sanitizeUploadFileName(fileName);
    if (isFilebase && token.isEmpty) {
      throw ArgumentError('Filebase RPC requires an API token.');
    }

    final Uri uploadUri;
    final request = http.MultipartRequest('POST', endpointUri)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: safeFileName),
      );

    if (isPinata) {
      if (token.isEmpty) {
        throw ArgumentError('Pinata requires an API key or JWT.');
      }
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['pinataOptions'] = jsonEncode({'cidVersion': 1});
      request.fields['pinataMetadata'] = jsonEncode({'name': safeFileName});
      uploadUri = endpointUri;
    } else {
      final parameters = <String, String>{'cid-version': '1'};
      if (isKubo) parameters['pin'] = 'true';
      uploadUri = endpointUri.replace(
        queryParameters: {...endpointUri.queryParameters, ...parameters},
      );
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final finalRequest = request.url == uploadUri
        ? request
        : (http.MultipartRequest('POST', uploadUri)
            ..headers.addAll(request.headers)
            ..fields.addAll(request.fields)
            ..files.addAll(request.files));
    final client = httpClient;
    final response = await (client == null
        ? finalRequest.send()
        : client.send(finalRequest));
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('IPFS upload failed (${response.statusCode}): $body');
    }

    final cid = _extractUploadCid(body, isPinata: isPinata);
    if (cid == null || cid.isEmpty) {
      throw Exception('IPFS upload did not return a CID.');
    }

    if (isKubo) {
      await _copyKuboFileToMfs(
        endpoint: endpoint,
        cid: cid,
        fileName: safeFileName,
        authorization: token.isEmpty ? null : 'Bearer $token',
      );
    }

    final gateway = normalizeIpfsGateway(uploadGateway);
    return gateway.isEmpty ? 'ipfs://$cid' : '$gateway$cid';
  }

  static Future<void> _copyKuboFileToMfs({
    required String endpoint,
    required String cid,
    required String fileName,
    required String? authorization,
  }) async {
    final uploadUri = Uri.parse(endpoint);
    final copyPath = uploadUri.path.replaceFirst(
      RegExp(r'/add/?$'),
      '/files/cp',
    );
    if (copyPath == uploadUri.path) {
      throw ArgumentError('Kubo upload endpoint must end with /add.');
    }

    final mfsPath = '/meshcore_uploads/$cid-$fileName';
    final copyUri = uploadUri.replace(
      path: copyPath,
      query:
          'arg=${Uri.encodeQueryComponent('/ipfs/$cid')}'
          '&arg=${Uri.encodeQueryComponent(mfsPath)}&parents=true',
    );
    final headers = authorization == null
        ? <String, String>{}
        : {'Authorization': authorization};
    final client = httpClient;
    final response = await (client == null
        ? http.post(copyUri, headers: headers)
        : client.post(copyUri, headers: headers));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Kubo MFS import failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  static String _sanitizeUploadFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return cleaned.isEmpty ? 'shared-image' : cleaned;
  }

  static String? _extractUploadCid(String body, {required bool isPinata}) {
    final lines = const LineSplitter()
        .convert(body)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    for (final line in lines.reversed) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is! Map<String, dynamic>) continue;
        final value = isPinata ? decoded['IpfsHash'] : decoded['Hash'];
        if (value is String && value.isNotEmpty) return value;
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
