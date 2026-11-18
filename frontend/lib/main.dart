import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase の初期化（Web/ローカル開発用のダミー設定）
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "demo-api-key",
      appId: "demo-app-id",
      messagingSenderId: "demo-sender-id",
      projectId: "demo-no-project",
    ),
  );

  // デバッグ実行時のみローカルエミュレータに接続
  if (kDebugMode) {
    // Auth エミュレータへの接続 (localhost:9099)
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

    // Firestore エミュレータへの接続 (localhost:8080)
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'チーム実習アプリ',
      theme: AppTheme.lightTheme,
      // アプリの起動画面として HomeScreen を指定
      home: const HomeScreen(),
    );
  }
}
