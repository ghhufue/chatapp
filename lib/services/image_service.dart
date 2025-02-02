import 'dart:convert';
import 'dart:typed_data';
import 'package:http/browser_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:mime_type/mime_type.dart' as mime;
import 'package:chatapp/globals.dart';

class BOSHelper {
  static final bucketName = "aichatapp-image";
  static final region = "su";
  static final expires = 3600;

  static late WebSocketChannel _channel;

  static Future<void> upload({
    required String accessKey,
    required String secretKey,
    required String objectKey,
    required Uint8List fileBytes,
  }) async {
    final BrowserClient client = BrowserClient();

    // 发送请求
    final uri = url(objectKey: objectKey);
    final response = await client.put(uri,
        headers: generateHeaderWithAuthorization(
            accessKey: accessKey,
            secretKey: secretKey,
            objectKey: objectKey,
            method: 'PUT'),
        body: fileBytes);

    client.close();
    if (response.statusCode != 200) {
      throw "Upload '$objectKey' failed (${response.statusCode}): ${response.body}";
    }
  }

  static Future<void> uploadImage(
      {required String objectKey, required Uint8List fileBytes}) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/putImage'),
      headers: {
        'Content-Type': mime.mime(objectKey).toString(),
        'Object-Key': objectKey,
      },
      body: fileBytes,
    );

    if (response.statusCode != 200) {
      logger.e(response.body);
      throw Exception('Failed to upload image');
    }
  }

  static Future<Uint8List> downloadImage({required String objectKey}) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/fetchImage'),
      headers: {
        'Object-Key': objectKey,
      },
      body: null,
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      logger.e(response.body);
      throw Exception('Failed to fetch image');
    }
  }

  static Future<Uint8List> download({
    required String accessKey,
    required String secretKey,
    required String objectKey,
  }) async {
    final BrowserClient client = BrowserClient();

    // 发送请求
    final uri = url(objectKey: objectKey);
    final response = await client.put(uri,
        headers: generateHeaderWithAuthorization(
            accessKey: accessKey,
            secretKey: secretKey,
            objectKey: objectKey,
            method: 'GET'),
        body: '');

    client.close();
    if (response.statusCode != 200) {
      throw "Download '$objectKey' failed (${response.statusCode}): ${response.body}";
    }
    return response.bodyBytes;
  }

  static Map<String, String>? generateHeaderWithAuthorization({
    required String accessKey,
    required String secretKey,
    required String objectKey,
    required String method,
  }) {
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
            .convert(utf8.encode('bce-auth-v1/$accessKey/$timestamp/$expires'))
            .toString(),
        method: method,
        resource: '/$encodedObjectKey',
        headers: headers);

    headers['Authorization'] =
        'bce-auth-v1/$accessKey/$timestamp/$expires/content-type;host;x-bce-date/$signature';

    return headers;
  }

  static Uri url({required String objectKey}) => Uri.parse(
      'https://$bucketName.$region.bcebos.com/${Uri.encodeComponent(objectKey).replaceAll('%2F', '/')}');

  static Uri generateVisitableUrl(
      {required String accessKey,
      required String secretKey,
      required String objectKey}) {
    final timestamp = _generateTimestamp();
    final encodedObjectKey =
        Uri.encodeComponent(objectKey).replaceAll('%2F', '/');

    final signature = _generateSignature(
        signingKey: Hmac(sha256, utf8.encode(secretKey))
            .convert(utf8.encode('bce-auth-v1/$accessKey/$timestamp/$expires'))
            .toString(),
        method: 'GET',
        resource: '/$encodedObjectKey',
        headers: {
          'Host': '$bucketName.$region.bcebos.com',
          'x-bce-date': timestamp,
        });

    return Uri.parse(
        'https://$bucketName.$region.bcebos.com/$objectKey?authorization=bce-auth-v1/$accessKey/$timestamp/$expires/host;x-bce-date/$signature');
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
