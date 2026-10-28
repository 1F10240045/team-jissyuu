import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'models/team.dart';
import 'constants/dummy_data.dart';
import 'screens/team_list_screen.dart';
import 'screens/create_team_screen.dart';
import 'screens/team_detail_screen.dart';

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

// チーム機能画面のナビゲーション管理クラス（HomeScreen等から呼び出して使用可能）
class TeamMainNavigation extends StatefulWidget {
  const TeamMainNavigation({super.key});

  @override
  State<TeamMainNavigation> createState() => _TeamMainNavigationState();
}

class _TeamMainNavigationState extends State<TeamMainNavigation> {
  final List<Team> _teams = List.from(initialTeams);

  void _addTeam(String name, String district, String description) {
    final newTeam = Team(
      teamId: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      district: district,
      description: description,
      managerUserId: dummyUserId,
      memberCount: 1,
      totalSteps: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    setState(() {
      _teams.insert(0, newTeam);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TeamListScreen(
      teams: _teams,
      onSelectTeam: (team) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(
              team: team,
              currentUserId: dummyUserId,
            ),
          ),
        );
      },
      onCreateNew: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateTeamScreen(
              onSubmit: (name, district, description) {
                _addTeam(name, district, description);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}