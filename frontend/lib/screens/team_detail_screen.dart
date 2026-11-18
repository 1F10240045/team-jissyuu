// lib/screens/team_detail_screen.dart
import 'package:flutter/material.dart';

import '../models/team.dart';

class TeamDetailScreen extends StatelessWidget {
  final Team team;
  final String currentUserId;

  const TeamDetailScreen({
    Key? key,
    required this.team,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isManager = team.managerUserId == currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('チーム詳細')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isManager)
                      const Chip(
                        label: Text(
                          '管理者',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '地域: ${team.district}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                const Text(
                  '説明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(team.description),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'メンバー数',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '${team.memberCount} 名',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'チーム合計歩数',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '${team.totalSteps} 歩',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
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
}
