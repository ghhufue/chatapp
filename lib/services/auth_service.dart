import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:chatapp/globals.dart';

class AuthService {
  static late final String baseUrl; // 替换为你的服务器地址
  static void init() {
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/api';
      logger.i("Run on Web");
    } else if (Platform.isAndroid) {
      baseUrl = 'http://chatappdb.yht20050302.top:80/api';
      logger.t("Run on Android");
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String password, String phoneNumber) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'phone_number': phoneNumber
        }),
      );

      logger.i('Response status: ${response.statusCode}');
      logger.i('Response body: ${response.body}');
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'error': json.decode(response.body)['error']};
      }
    } catch (err) {
      logger.e(err);
      return {'error': 'Failed to connect'};
    }
  }

  // 登录方法
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      logger.i('Response body: ${response.body}');
    } else {
      logger.e('Response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'error': json.decode(response.body)['error']};
    }
  }

  static Future<bool> testconnection() async {
    final url = Uri.parse('$baseUrl/test');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
