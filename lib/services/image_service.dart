import 'dart:convert';
import 'dart:typed_data';
import 'package:http/browser_client.dart';
import 'package:crypto/crypto.dart';

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
  static Future<bool> upload({
    required String accessKey,
    required String secretKey,
    required String bucketName,
    required String region,
    required String objectKey,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    try {
      // 1. 准备请求参数
      final timestamp = _generateTimestamp();
      final encodedObjectKey = Uri.encodeComponent(objectKey);
      final mimeType = contentType ?? _getMimeType(objectKey);

      // 2. 构造请求头
      final headers = {
        'Host': '$bucketName.$region.bcebos.com',
        'Content-Type': mimeType,
        'x-bce-date': timestamp,
      };

      // 3. 生成签名
      final signature = _generateSignature(
        secretKey: secretKey,
        method: 'PUT',
        resource: '/$encodedObjectKey',
        headers: headers,
        timestamp: timestamp,
        accessKey: accessKey,
      );

      // 4. 设置认证头
      headers['Authorization'] =
          'bce-auth-v1/$accessKey/$timestamp/1800/host;x-bce-date/$signature';

      // 5. 发送请求
      final url = Uri.parse('https://${headers['Host']}/$encodedObjectKey');
      final response =
          await _client.put(url, headers: headers, body: fileBytes);

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(
          'Upload error (${response.statusCode}): ${response.body}');
    } finally {
      _client.close();
    }
  }

  // 生成时间戳
  static String _generateTimestamp() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}Z';
  }

  // 获取MIME类型
  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return const {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'gif': 'image/gif',
          'txt': 'text/plain',
          'pdf': 'application/pdf',
          'zip': 'application/zip',
        }[ext] ??
        'application/octet-stream';
  }

  // 生成签名
  static String _generateSignature({
    required String secretKey,
    required String method,
    required String resource,
    required Map<String, String> headers,
    required String timestamp,
    required String accessKey,
  }) {
    // 规范化请求头
    final encodedHeaders = headers.map((key, value) {
      final encodedKey = key.trim().toLowerCase();
      final encodedValue =
          Uri.encodeComponent(value.trim()).replaceAll('+', '%20');
      return MapEntry(encodedKey, encodedValue);
    });

    // 排序并构建规范头
    final sortedHeaders = encodedHeaders.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final canonicalHeaders =
        sortedHeaders.map((e) => '${e.key}:${e.value}').join('\n');

    // 构建待签名字符串
    final stringToSign = [
      method.toUpperCase(),
      resource,
      '',
      canonicalHeaders,
    ].join('\n');

    // 生成签名
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    return hmac.convert(utf8.encode(stringToSign)).toString();
  }
}
