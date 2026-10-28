// lib/constants/dummy_data.dart
import '../models/team.dart';

const String dummyUserId = "dummy_user_id";

final UserProfile dummyUserProfile = UserProfile(
  userId: dummyUserId,
  displayName: "テストユーザー",
  avatarUrl: "https://via.placeholder.com/150",
  district: "渋谷区",
  ageGroup: "30s",
  teamId: "team_001",
  totalSteps: 45000,
  totalDistanceKm: 31.5,
  createdAt: DateTime.parse("2026-10-01T00:00:00Z"),
  updatedAt: DateTime.parse("2026-10-28T00:00:00Z"),
);

final List<Team> initialTeams = [
  Team(
    teamId: "team_001",
    name: "渋谷ウォーカーズ",
    district: "渋谷区",
    description: "渋谷周辺で毎日ウォーキングを楽しむチームです！",
    managerUserId: dummyUserId,
    memberCount: 5,
    totalSteps: 230000,
    createdAt: DateTime.parse("2026-10-01T00:00:00Z"),
    updatedAt: DateTime.parse("2026-10-01T00:00:00Z"),
  ),
  Team(
    teamId: "team_002",
    name: "新宿ランニングクラブ",
    district: "新宿区",
    description: "週末朝に御苑周辺を歩いています。",
    managerUserId: "user_002",
    memberCount: 12,
    totalSteps: 580000,
    createdAt: DateTime.parse("2026-10-10T00:00:00Z"),
    updatedAt: DateTime.parse("2026-10-10T00:00:00Z"),
  ),
];