import 'package:flutter/material.dart';

import '../constants/dummy_data.dart';
import '../models/team.dart';
import '../services/team_service.dart';
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
  List<Team> _teams = List.from(initialTeams);

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final fetched = await _teamService
          .fetchTeams()
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        _teams = fetched;
      });
    } catch (_) {
      // エミュレータ未接続時は初期ダミーデータを維持
    }
  }

  Future<void> _addTeam(
    String name,
    String district,
    String description,
  ) async {
    final now = DateTime.now();

    final newTeam = Team(
      teamId: 'team_${now.millisecondsSinceEpoch}',
      name: name,
      district: district,
      description: description,
      managerUserId: dummyUserId,
      memberCount: 1,
      totalSteps: 0,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _teams.insert(0, newTeam);
    });

    try {
      await _teamService
          .createTeam(
            name: name,
            district: district,
            description: description,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // エミュレータ未接続時も画面上のリストには追加済み
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeamListScreen(
      teams: _teams,
      onSelectTeam: (team) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(
              team: team,
              currentUserId: dummyUserId,
            ),
          ),
        );
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
