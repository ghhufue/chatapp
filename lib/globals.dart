import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'dart:io';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Logger logger = Logger(); // 全局日志工具
late String serverUrl; // 全局服务器地址
late String wsUrl;
const maxMessageNum = 10;
void setServerUrl() {
  if (kIsWeb) {
    serverUrl = "http://localhost:3000";
    wsUrl = "ws://localhost:3000";
  } else if (Platform.isAndroid) {
    serverUrl = 'http://chatappdb.yht20050302.top:80';
    wsUrl = "ws://chatappdb.yht20050302.top:80";
  }
}
