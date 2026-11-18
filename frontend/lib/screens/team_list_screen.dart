// lib/screens/team_list_screen.dart
import 'package:flutter/material.dart';

import '../models/team.dart';

class TeamListScreen extends StatelessWidget {
  final List<Team> teams;
  final Function(Team) onSelectTeam;
  final VoidCallback onCreateNew;

  const TeamListScreen({
    Key? key,
    required this.teams,
    required this.onSelectTeam,
    required this.onCreateNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チーム一覧'),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Chip(
                    label: Text(
                      team.district,
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
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
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '累計歩数: ${team.totalSteps} 歩',
                        style: const TextStyle(fontSize: 12),
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
    );
  }
}
