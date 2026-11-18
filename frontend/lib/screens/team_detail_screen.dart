import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/team_service.dart';

class TeamDetailScreen extends StatelessWidget {
  final Team team;
  final String currentUserId;
  final TeamService _teamService = TeamService();

  TeamDetailScreen({
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _teamService.joinTeam(
                          teamId: team.teamId,
                          userId: currentUserId,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('チームに参加しました'),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('参加に失敗しました: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.group_add),
                    label: const Text('このチームに参加する'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
