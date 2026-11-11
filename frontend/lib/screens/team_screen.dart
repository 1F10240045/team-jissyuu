import 'package:flutter/material.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チーム一覧'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTeamCard(
              teamName: '渋谷ウォーカーズ',
              description: '渋谷周辺で毎日ウォーキングを楽しむチームです！',
              members: 'メンバー: 5名',
              steps: '累計歩数: 230000 歩',
            ),
            const SizedBox(height: 16),
            _buildTeamCard(
              teamName: '新宿ランニングクラブ',
              description: '週末朝に御苑周辺を歩いています。',
              members: 'メンバー: 12名',
              steps: '累計歩数: 580000 歩',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard({
    required String teamName,
    required String description,
    required String members,
    required String steps,
  }) {
    return Card(
      color: const Color(0xFFF4F6EE),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(members, style: const TextStyle(color: Colors.grey)),
                Text(
                  steps,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}