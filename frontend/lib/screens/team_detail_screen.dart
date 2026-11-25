import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/walk_log_service.dart';
import '../theme/app_theme.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;
  final String currentUserId;
  final VoidCallback? onTeamUpdated;

  const TeamDetailScreen({
    super.key,
    required this.team,
    required this.currentUserId,
    this.onTeamUpdated,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late Team _currentTeam;

  @override
  void initState() {
    super.initState();
    _currentTeam = widget.team;
  }

  void _toggleJoinTeam() {
    final isJoined = WalkLogService.currentTeamId == _currentTeam.teamId;
    final mySteps = WalkLogService.currentTodaySteps;

    if (isJoined) {
      // 参加中のチームから退会する
      final updated = Team(
        teamId: _currentTeam.teamId,
        name: _currentTeam.name,
        district: _currentTeam.district,
        description: _currentTeam.description,
        managerUserId: _currentTeam.managerUserId,
        memberCount: (_currentTeam.memberCount - 1).clamp(1, 9999),
        totalSteps: (_currentTeam.totalSteps - mySteps).clamp(0, 999999999),
        createdAt: _currentTeam.createdAt,
        updatedAt: DateTime.now(),
      );

      setState(() {
        _currentTeam = updated;
        WalkLogService.currentTeamId = '';
      });
      _updateSharedList(updated);
      WalkLogService.persistToLocalStorage();
      widget.onTeamUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${_currentTeam.name}」から退会しました'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    } else {
      // 別のチームに参加していた場合は前のチームの人数を-1してから新チームに参加
      final prevTeamId = WalkLogService.currentTeamId;
      if (prevTeamId.isNotEmpty && prevTeamId != _currentTeam.teamId) {
        final prevIdx = WalkLogService.sharedTeamsList.indexWhere(
          (t) => t.teamId == prevTeamId,
        );
        if (prevIdx >= 0) {
          final prev = WalkLogService.sharedTeamsList[prevIdx];
          WalkLogService.sharedTeamsList[prevIdx] = Team(
            teamId: prev.teamId,
            name: prev.name,
            district: prev.district,
            description: prev.description,
            managerUserId: prev.managerUserId,
            memberCount: (prev.memberCount - 1).clamp(1, 9999),
            totalSteps: (prev.totalSteps - mySteps).clamp(0, 999999999),
            createdAt: prev.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      }

      final updated = Team(
        teamId: _currentTeam.teamId,
        name: _currentTeam.name,
        district: _currentTeam.district,
        description: _currentTeam.description,
        managerUserId: _currentTeam.managerUserId,
        memberCount: _currentTeam.memberCount + 1,
        totalSteps: _currentTeam.totalSteps + mySteps,
        createdAt: _currentTeam.createdAt,
        updatedAt: DateTime.now(),
      );

      setState(() {
        _currentTeam = updated;
        WalkLogService.currentTeamId = _currentTeam.teamId;
      });
      _updateSharedList(updated);
      WalkLogService.persistToLocalStorage();
      widget.onTeamUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 「${_currentTeam.name}」に参加しました！'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  void _updateSharedList(Team updated) {
    final idx = WalkLogService.sharedTeamsList.indexWhere(
      (t) => t.teamId == updated.teamId,
    );
    if (idx >= 0) {
      WalkLogService.sharedTeamsList[idx] = updated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _currentTeam.managerUserId == widget.currentUserId;
    final isJoined = WalkLogService.currentTeamId == _currentTeam.teamId;

    return Scaffold(
      appBar: AppBar(title: const Text('チーム詳細')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _currentTeam.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isJoined)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '参加中',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isManager)
                      const Chip(
                        label: Text(
                          '作成者',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '活動地域: ${_currentTeam.district}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'チーム紹介',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentTeam.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'メンバー数',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            '${_currentTeam.memberCount} 名',
                            style: const TextStyle(
                              fontSize: 20,
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
                            'チーム累計歩数',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            '${_currentTeam.totalSteps} 歩',
                            style: const TextStyle(
                              fontSize: 20,
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
                  child: isJoined
                      ? OutlinedButton.icon(
                          onPressed: _toggleJoinTeam,
                          icon: const Icon(Icons.check_circle),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          label: const Text(
                            '現在このチームに参加中（退会する）',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _toggleJoinTeam,
                          icon: const Icon(Icons.group_add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          label: const Text(
                            'このチームに参加する',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
