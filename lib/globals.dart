import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Logger logger = Logger(); // 全局日志工具
String serverUrl = "http://localhost:3000"; // 全局服务器地址
String wsUrl = "ws://localhost:3000";
const maxMessageNum = 10;
