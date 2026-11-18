// lib/models/team.dart

class UserProfile {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String district;
  final String ageGroup;
  final String? teamId;
  final int targetSteps;
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
    this.targetSteps = 8000,
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

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      teamId: map['teamId'] ?? '',
      name: map['name'] ?? '',
      district: map['district'] ?? '',
      description: map['description'] ?? '',
      managerUserId: map['managerUserId'] ?? '',
      memberCount: (map['memberCount'] ?? 0) as int,
      totalSteps: (map['totalSteps'] ?? 0) as int,
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'name': name,
      'district': district,
      'description': description,
      'managerUserId': managerUserId,
      'memberCount': memberCount,
      'totalSteps': totalSteps,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
