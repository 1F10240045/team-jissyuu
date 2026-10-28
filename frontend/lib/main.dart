import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // 作成したHomeScreenをインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'チーム実習アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      // 初期画面に HomeScreen を指定
      home: const HomeScreen(),
    );
  }
}