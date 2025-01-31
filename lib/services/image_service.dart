import 'dart:convert';
import 'dart:typed_data';
import 'package:http/browser_client.dart';
import 'package:crypto/crypto.dart';
import 'package:mime_type/mime_type.dart' as mime;

class BOSUploader {
  static final BrowserClient _client = BrowserClient();

  /// 上传文件到百度云BOS
  ///
  /// [accessKey] 百度云访问密钥
  /// [secretKey] 百度云安全密钥
  /// [bucketName] 存储桶名称
  /// [region] 存储桶区域代码（如 "bj"）
  /// [objectKey] 目标文件路径（如 "uploads/image.jpg"）
  /// [fileBytes] 文件二进制数据
  /// [contentType] 文件MIME类型（可选，默认根据扩展名自动判断）
  ///
  /// 返回：成功时返回true，失败时抛出异常
  static Future<void> upload({
    required String accessKey,
    required String secretKey,
    required String bucketName,
    required String region,
    required String objectKey,
    required Uint8List fileBytes,
  }) async {
    final contentType = mime.mime(objectKey)!;
    final timestamp = _generateTimestamp();
    final encodedObjectKey =
        Uri.encodeComponent(objectKey).replaceAll('%2F', '/');

    // 构造请求头
    final headers = {
      'Host': '$bucketName.$region.bcebos.com',
      'Content-Type': contentType,
      'x-bce-date': timestamp,
    };

    // 生成签名
    final signature = _generateSignature(
        signingKey: Hmac(sha256, utf8.encode(secretKey))
            .convert(utf8.encode('bce-auth-v1/$accessKey/$timestamp/3600'))
            .toString(),
        method: 'PUT',
        resource: '/$encodedObjectKey',
        headers: headers);

    headers['Authorization'] =
        'bce-auth-v1/$accessKey/$timestamp/3600/content-type;host;x-bce-date/$signature';

    // 发送请求
    final url =
        Uri.parse('https://$bucketName.$region.bcebos.com/$encodedObjectKey');
    final response = await _client.put(url, headers: headers, body: fileBytes);
    if (response.statusCode != 200) {
      throw "Upload failed (${response.statusCode}): ${response.body}";
    }
  }

  static String _generateTimestamp() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}Z';
  }

  /*
  // 获取MIME类型
  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return const {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'webp': 'image/webp',
          'bmp': 'image/bmp',
          'svg': 'image/svg',
          'tiff': 'image/tiff',
          'gif': 'image/gif',
        }[ext] ??
        'application/octet-stream';
  }
  */

  // 生成签名
  static String _generateSignature(
      {required String signingKey,
      required String method,
      required String resource,
      required Map<String, String> headers}) {
    final encodedHeaders = headers.map((key, value) {
      // Key 处理：转小写并去除空格
      final encodedKey = key.trim().toLowerCase();

      // Value 处理：去除首尾空格 + URI 编码
      final encodedValue =
          Uri.encodeComponent(value.trim()).replaceAll('+', '%20');

      return MapEntry(encodedKey, encodedValue);
    });

    // 2. 按字典序排序 Header
    final sortedHeaders = encodedHeaders.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // 3. 构建规范化头字符串
    final canonicalHeaders =
        sortedHeaders.map((entry) => '${entry.key}:${entry.value}').join('\n');

    final stringToSign = [method, resource, '', canonicalHeaders].join('\n');

    return Hmac(sha256, utf8.encode(signingKey))
        .convert(utf8.encode(stringToSign))
        .toString();
  }
}
