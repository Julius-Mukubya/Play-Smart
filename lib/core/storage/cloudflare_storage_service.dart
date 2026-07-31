import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minio/minio.dart';

/// Service to handle media uploads to Cloudflare R2 using the S3-compatible API.
class CloudflareStorageService {
  static Minio? _minioClient;

  static Minio get _client {
    if (_minioClient == null) {
      final accountId = dotenv.get('CLOUDFLARE_ACCOUNT_ID', fallback: '').trim();
      final accessKey = dotenv.get('CLOUDFLARE_ACCESS_KEY_ID', fallback: '').trim();
      final secretKey = dotenv.get('CLOUDFLARE_SECRET_ACCESS_KEY', fallback: '').trim();

      if (accountId.isEmpty || accessKey.isEmpty || secretKey.isEmpty) {
        throw Exception('Cloudflare R2 storage credentials are not configured in your .env file.');
      }

      _minioClient = Minio(
        endPoint: '$accountId.r2.cloudflarestorage.com',
        accessKey: accessKey,
        secretKey: secretKey,
        useSSL: true,
        region: 'auto',
      );
    }
    return _minioClient!;
  }

  /// Uploads raw file bytes to R2 and returns the public URL.
  static Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final bucket = dotenv.get('CLOUDFLARE_R2_BUCKET');
      final publicUrl = dotenv.get('CLOUDFLARE_R2_PUBLIC_URL');

      await _client.putObject(
        bucket,
        path,
        Stream.value(bytes),
        size: bytes.length,
        metadata: {'content-type': contentType},
      );

      // Clean path slashes if needed
      final cleanPublicUrl = publicUrl.endsWith('/') ? publicUrl.substring(0, publicUrl.length - 1) : publicUrl;
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;

      return '$cleanPublicUrl/$cleanPath';
    } catch (e) {
      throw Exception('Cloudflare R2 upload failed: $e');
    }
  }
}
