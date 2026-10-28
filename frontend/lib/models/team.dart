// lib/models/team.dart

class UserProfile {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String district;
  final String ageGroup;
  final String? teamId;
  final int totalSteps;
  final double totalDistanceKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.district,
    required this.ageGroup,
    this.teamId,
    required this.totalSteps,
    required this.totalDistanceKm,
    required this.createdAt,
    required this.updatedAt,
  });
}

class Team {
  final String teamId;
  final String name;
  final String district;
  final String description;
  final String managerUserId;
  final int memberCount;
  final int totalSteps;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.teamId,
    required this.name,
    required this.district,
    required this.description,
    required this.managerUserId,
    required this.memberCount,
    required this.totalSteps,
    required this.createdAt,
    required this.updatedAt,
  });
}