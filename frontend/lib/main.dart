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
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// シニア向け文字サイズ倍率（1.0: 標準, 1.15: 大, 1.3: 特大）
  static final ValueNotifier<double> fontScaleNotifier =
      ValueNotifier<double>(1.15); // デフォルトでシニアに見やすい「大(1.15倍)」に設定

  static String get fontScaleLabel {
    final s = fontScaleNotifier.value;
    if (s >= 1.25) return '特大';
    if (s >= 1.1) return '大';
    return '標準';
  }

  static void cycleFontScale() {
    final s = fontScaleNotifier.value;
    if (s < 1.1) {
      fontScaleNotifier.value = 1.15; // 大
    } else if (s < 1.25) {
      fontScaleNotifier.value = 1.3; // 特大
    } else {
      fontScaleNotifier.value = 1.0; // 標準
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: fontScaleNotifier,
      builder: (context, scale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '23区対抗WALK',
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
