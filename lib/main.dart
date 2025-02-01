import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chathomepage.dart';
import 'services/auth_service.dart';

//import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService.init();
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   sqfliteFfiInit();
  //   databaseFactory = databaseFactoryFfi;
  // }
  await dotenv.load(fileName: '../bos_keys.env'); // 从文件中加载百度云BOS密钥

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login & Register',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/chat': (context) => FriendListPage(),
      },
    );
  }
}
