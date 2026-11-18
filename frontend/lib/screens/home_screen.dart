import 'package:flutter/material.dart';

import 'exercise_screen.dart';
import 'record_screen.dart';
import 'ranking_screen.dart';
import 'friend_screen.dart';
import 'profile_screen.dart';
import 'team_main_navigation.dart';
import '../services/ranking_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F8),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        Icon(
                          Icons.account_circle,
                          size: 48,
                          color: Colors.grey,
                        ),
                        Text(
                          'プロフ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. 中央のエリア（チームボタン + 表彰台）
                Container(
                  width: double.infinity,
                  height: 160,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // チームボタン
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeamMainNavigation(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups, size: 32, color: Colors.green),
                              SizedBox(height: 4),
                              Text(
                                'チーム',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // 表彰台
                      FutureBuilder<List<WardRanking>>(
                        future: RankingService().getWardRankings(
                          startDate: DateTime.now(),
                          endDate: DateTime.now(),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 160,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Text('取得失敗');
                          }

                          final ranking = snapshot.data ?? const [];

                          if (ranking.isEmpty) {
                            return const Text('データなし');
                          }

                          final top = ranking.take(3).toList();

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (top.length > 1)
                                _buildPodiumBlock(
                                  top[1].district,
                                  top[1].rank,
                                  70,
                                ),
                              if (top.isNotEmpty)
                                _buildPodiumBlock(
                                  top[0].district,
                                  top[0].rank,
                                  100,
                                ),
                              if (top.length > 2)
                                _buildPodiumBlock(
                                  top[2].district,
                                  top[2].rank,
                                  50,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumBlock(String district, int rank, double height) {
    final color = rank == 1
        ? Colors.amber.shade300
        : rank == 2
        ? Colors.grey.shade300
        : Colors.brown.shade200;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            district,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 45,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '$rank位',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
