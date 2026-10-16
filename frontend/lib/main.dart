import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      title: 'LINE Mini App Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LINE Mini App - Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // テスト用：Firestore にデータを書き込んでみる
            try {
              await FirebaseFirestore.instance.collection('test').add({
                'message': 'Hello Firebase Emulator!',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('エミュレータにデータを送信しました！')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラーが発生しました: $e')),
                );
              }
            }
          },
          child: const Text('エミュレータにテストデータを送信'),
        ),
      ),
    );
  }
}