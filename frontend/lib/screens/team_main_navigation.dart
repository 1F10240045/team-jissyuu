import 'package:flutter/material.dart';

import '../constants/dummy_data.dart';
import '../models/team.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';
import 'team_list_screen.dart';

class TeamMainNavigation extends StatefulWidget {
  const TeamMainNavigation({super.key});

  @override
  State<TeamMainNavigation> createState() => _TeamMainNavigationState();
}

class _TeamMainNavigationState extends State<TeamMainNavigation> {
  final List<Team> _teams = List.from(initialTeams);

  void _addTeam(String name, String district, String description) {
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