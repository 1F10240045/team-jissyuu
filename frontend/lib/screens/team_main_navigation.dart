import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/team_service.dart';
import '../services/walk_log_service.dart';
import '../theme/app_theme.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';
import 'team_list_screen.dart';

class TeamMainNavigation extends StatefulWidget {
  const TeamMainNavigation({super.key});

  @override
  State<TeamMainNavigation> createState() => _TeamMainNavigationState();
}

class _TeamMainNavigationState extends State<TeamMainNavigation> {
  final TeamService _teamService = TeamService();

  Future<void> _addTeam(
    String name,
    String district,
    String description,
  ) async {
    final now = DateTime.now();
    final newTeamId = 'team_${now.millisecondsSinceEpoch}';

    // 自分が以前参加していたチームがあれば人数を-1調整
    final prevTeamId = WalkLogService.currentTeamId;
    final mySteps = WalkLogService.currentTodaySteps;
    if (prevTeamId.isNotEmpty) {
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
          updatedAt: now,
        );
      }
    }

    final newTeam = Team(
      teamId: newTeamId,
      name: name,
      district: district,
      description: description,
      managerUserId: WalkLogService.currentAccountId,
      memberCount: 1,
      totalSteps: mySteps,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      WalkLogService.sharedTeamsList.insert(0, newTeam);
      WalkLogService.currentTeamId = newTeamId;
    });
    WalkLogService.persistToLocalStorage();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ チーム「$name（$district）」を作成して参加しました！'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }

    try {
      await _teamService
          .createTeam(
            name: name,
            district: district,
            description: description,
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return TeamListScreen(
      teams: WalkLogService.sharedTeamsList,
      onSelectTeam: (team) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(
              team: team,
              currentUserId: WalkLogService.currentAccountId,
              onTeamUpdated: () {
                if (mounted) setState(() {});
              },
            ),
          ),
        );
        if (mounted) setState(() {});
      },
      onCreateNew: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateTeamScreen(
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
