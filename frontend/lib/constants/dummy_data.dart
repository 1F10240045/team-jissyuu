// lib/constants/dummy_data.dart
import '../models/team.dart';

const String dummyUserId = "dummy_user_id";

final UserProfile dummyUserProfile = UserProfile(
  userId: dummyUserId,
  displayName: 'テストユーザー',
  avatarUrl: 'https://via.placeholder.com/150',
  district: '渋谷区',
  ageGroup: '30s',
  teamId: 'team_001',
  targetSteps: 8000,
  totalSteps: 45000,
  totalDistanceKm: 31.5,
  createdAt: DateTime.parse('2026-10-01T00:00:00Z'),
  updatedAt: DateTime.parse('2026-10-28T00:00:00Z'),
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

// 1. 東京都23区の初期ランキングデータ（デモで1位逆転しやすい数値バランスに設定）
final List initialDistrictRankings = [
  {'district': '世田谷区', 'totalSteps': 1250000, 'totalDistanceKm': 875.0, 'achievementRate': 88.5},
  {'district': '練馬区',   'totalSteps': 1245000, 'totalDistanceKm': 871.5, 'achievementRate': 87.2},
  {'district': '大田区',   'totalSteps': 1180000, 'totalDistanceKm': 826.0, 'achievementRate': 84.0},
  {'district': '足立区',   'totalSteps': 1120000, 'totalDistanceKm': 784.0, 'achievementRate': 81.5},
  {'district': '江戸川区', 'totalSteps': 1090000, 'totalDistanceKm': 763.0, 'achievementRate': 80.1},
  {'district': '杉並区',   'totalSteps': 1050000, 'totalDistanceKm': 735.0, 'achievementRate': 79.0},
  {'district': '板橋区',   'totalSteps': 980000,  'totalDistanceKm': 686.0, 'achievementRate': 76.8},
  {'district': '江東区',   'totalSteps': 950000,  'totalDistanceKm': 665.0, 'achievementRate': 75.4},
  {'district': '葛飾区',   'totalSteps': 910000,  'totalDistanceKm': 637.0, 'achievementRate': 74.0},
  {'district': '品川区',   'totalSteps': 880000,  'totalDistanceKm': 616.0, 'achievementRate': 73.2},
  {'district': '北区',     'totalSteps': 850000,  'totalDistanceKm': 595.0, 'achievementRate': 71.9},
  {'district': '新宿区',   'totalSteps': 820000,  'totalDistanceKm': 574.0, 'achievementRate': 70.5},
  {'district': '中野区',   'totalSteps': 790000,  'totalDistanceKm': 553.0, 'achievementRate': 69.8},
  {'district': '豊島区',   'totalSteps': 760000,  'totalDistanceKm': 532.0, 'achievementRate': 68.4},
  {'district': '目黒区',   'totalSteps': 730000,  'totalDistanceKm': 511.0, 'achievementRate': 67.1},
  {'district': '墨田区',   'totalSteps': 700000,  'totalDistanceKm': 490.0, 'achievementRate': 66.0},
  {'district': '港区',     'totalSteps': 680000,  'totalDistanceKm': 476.0, 'achievementRate': 65.2},
  {'district': '文京区',   'totalSteps': 650000,  'totalDistanceKm': 455.0, 'achievementRate': 64.5},
  {'district': '渋谷区',   'totalSteps': 620000,  'totalDistanceKm': 434.0, 'achievementRate': 63.0},
  {'district': '台東区',   'totalSteps': 590000,  'totalDistanceKm': 413.0, 'achievementRate': 61.8},
  {'district': '荒川区',   'totalSteps': 560000,  'totalDistanceKm': 392.0, 'achievementRate': 60.4},
  {'district': '中央区',   'totalSteps': 530000,  'totalDistanceKm': 371.0, 'achievementRate': 59.1},
  {'district': '千代田区', 'totalSteps': 490000,  'totalDistanceKm': 343.0, 'achievementRate': 57.5},
];

// 2. 年代別の平均歩数データ
final Map<String, int> averageStepsByAgeGroup = {
  '50代': 7500,
  '60代': 6800,
  '70代': 5600,
  '80代': 4200,
  '90代+': 3000,
};

// 3. サンプルシニアユーザー（フレンド）データ
final List sampleSeniorUsers = [
  {
    'userId': 'sample_user_01',
    'name': '佐藤 健一',
    'district': '世田谷区',
    'ageGroup': '70代',
    'targetSteps': 6000,
    'todaySteps': 6420,
  },
  {
    'userId': 'sample_user_02',
    'name': '鈴木 節子',
    'district': '練馬区',
    'ageGroup': '60代',
    'targetSteps': 8000,
    'todaySteps': 8150,
  },
  {
    'userId': 'sample_user_03',
    'name': '高橋 義男',
    'district': '北区',
    'ageGroup': '80代',
    'targetSteps': 4000,
    'todaySteps': 4300,
  },
  {
    'userId': 'sample_user_04',
    'name': '田中 和子',
    'district': '新宿区',
    'ageGroup': '70代',
    'targetSteps': 6000,
    'todaySteps': 5200,
  },
  {
    'userId': 'sample_user_05',
    'name': '伊藤 茂',
    'district': '大田区',
    'ageGroup': '60代',
    'targetSteps': 8000,
    'todaySteps': 7890,
  },
];
