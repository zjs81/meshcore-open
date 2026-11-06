import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_settings.dart';

/// Why the IPFS upload settings can't be used.
enum IpfsUploadConfigError {
  emptyEndpoint,
  invalidEndpoint,
  pinataTokenMissing,
  filebaseTokenMissing,
  kuboPathInvalid,
}

/// Thrown when the IPFS upload settings can't be used, before or instead of
/// a network failure. The UI maps [reason] to a localized message.
class IpfsUploadConfigException implements Exception {
  const IpfsUploadConfigException(this.reason);

  final IpfsUploadConfigError reason;

  @override
  String toString() => 'IpfsUploadConfigException(${reason.name})';
}

class IpfsUploadHelper {
  @visibleForTesting
  static http.Client? httpClient;

  static final _kuboAddPath = RegExp(r'/api/v0/add/?$');

  /// A CIDv1 (base32, sha2-256) as long as the CID of every upload, used to
  /// size the link before uploading.
  static const sampleCid =
      'bafkreihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku';

  static String linkForCid({
    required String uploadGateway,
    required String cid,
  }) {
    final gateway = normalizeIpfsGateway(uploadGateway);
    return gateway.isEmpty ? 'ipfs://$cid' : '$gateway$cid';
  }

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
      throw const IpfsUploadConfigException(
        IpfsUploadConfigError.emptyEndpoint,
      );
    }

    final endpointUri = Uri.tryParse(endpoint);
    if (endpointUri == null ||
        !(endpointUri.isScheme('http') || endpointUri.isScheme('https')) ||
        endpointUri.host.isEmpty) {
      throw const IpfsUploadConfigException(
        IpfsUploadConfigError.invalidEndpoint,
      );
    }

    final token = uploadApiKey.trim();
    final endpointHost = endpointUri.host.toLowerCase();
    final isPinata =
        endpointHost.contains('pinata') ||
        endpoint.toLowerCase().contains('pinfiletoipfs');
    final isFilebase = endpointHost.contains('filebase');
    final isKubo = !isPinata && !isFilebase;
    final safeFileName = _sanitizeUploadFileName(fileName);
    if (isPinata && token.isEmpty) {
      throw const IpfsUploadConfigException(
        IpfsUploadConfigError.pinataTokenMissing,
      );
    }
    if (isFilebase && token.isEmpty) {
      throw const IpfsUploadConfigException(
        IpfsUploadConfigError.filebaseTokenMissing,
      );
    }
    if (isKubo && !_kuboAddPath.hasMatch(endpointUri.path)) {
      throw const IpfsUploadConfigException(
        IpfsUploadConfigError.kuboPathInvalid,
      );
    }

    final uploadUri = isPinata
        ? endpointUri
        : endpointUri.replace(
            queryParameters: {
              ...endpointUri.queryParameters,
              'cid-version': '1',
              if (isKubo) 'pin': 'true',
            },
          );

    final request = http.MultipartRequest('POST', uploadUri)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: safeFileName),
      );
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (isPinata) {
      request.fields['pinataOptions'] = jsonEncode({'cidVersion': 1});
      request.fields['pinataMetadata'] = jsonEncode({'name': safeFileName});
    }

    final client = httpClient;
    final response = await (client == null
        ? request.send()
        : client.send(request));
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
        addUri: endpointUri,
        cid: cid,
        fileName: safeFileName,
        authorization: token.isEmpty ? null : 'Bearer $token',
      );
    }

    return linkForCid(uploadGateway: uploadGateway, cid: cid);
  }

  static Future<void> _copyKuboFileToMfs({
    required Uri addUri,
    required String cid,
    required String fileName,
    required String? authorization,
  }) async {
    final mfsPath = '/meshcore_uploads/$cid-$fileName';
    final copyUri = addUri.replace(
      path: addUri.path.replaceFirst(_kuboAddPath, '/api/v0/files/cp'),
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
    final alreadyCopied = response.body.contains('already has entry');
    if ((response.statusCode < 200 || response.statusCode >= 300) &&
        !alreadyCopied) {
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
