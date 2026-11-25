import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/walk_log_service.dart';
import '../theme/app_theme.dart';

class TeamListScreen extends StatelessWidget {
  final List<Team> teams;
  final Function(Team) onSelectTeam;
  final VoidCallback onCreateNew;

  const TeamListScreen({
    super.key,
    required this.teams,
    required this.onSelectTeam,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ご近所チーム一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onCreateNew,
            tooltip: '新規作成',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          final isJoined = WalkLogService.currentTeamId == team.teamId;

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            color: isJoined ? Colors.green.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isJoined
                  ? const BorderSide(color: AppTheme.primaryColor, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isJoined) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '参加中',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Chip(
                        label: Text(
                          team.district,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    team.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'メンバー: ${team.memberCount}名',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '累計歩数: ${team.totalSteps} 歩',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => onSelectTeam(team),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateNew,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add),
        label: const Text(
          '新しいチームを作る',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
