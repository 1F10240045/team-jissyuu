import 'package:flutter/material.dart'; // ※ package: にしてください（0が入らないようご注意）

import 'exercise_screen.dart';
import 'record_screen.dart';
import 'ranking_screen.dart';
import 'friend_screen.dart';
import 'profile_screen.dart'; // プロフィール画面をインポート

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. プロフボタン（左上）
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: const Column(
                    children: [
                      Icon(Icons.account_circle, size: 48, color: Colors.grey),
                      Text(
                        'プロフ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. 中央の表彰台エリア
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildPodiumBlock('2', 80, Colors.grey.shade300),
                        const SizedBox(width: 8),
                        _buildPodiumBlock('1', 110, Colors.amber.shade300),
                        const SizedBox(width: 8),
                        _buildPodiumBlock('3', 60, Colors.brown.shade200),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. 2x2 メニューボタン
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _buildMenuButton(
                    context,
                    label: '運動',
                    icon: Icons.directions_run,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExerciseScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    label: '記録',
                    icon: Icons.edit_note,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    label: 'ランキング',
                    icon: Icons.emoji_events,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    label: 'フレンド',
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumBlock(String rank, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '($rank)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Icon(icon, size: 28),
        ],
      ),
    );
  }
}