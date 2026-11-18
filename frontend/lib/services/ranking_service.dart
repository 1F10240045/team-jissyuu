import 'package:cloud_firestore/cloud_firestore.dart';

const tokyo23Wards = <String>[
  '千代田区',
  '中央区',
  '港区',
  '新宿区',
  '文京区',
  '台東区',
  '墨田区',
  '江東区',
  '品川区',
  '目黒区',
  '大田区',
  '世田谷区',
  '渋谷区',
  '中野区',
  '杉並区',
  '豊島区',
  '北区',
  '荒川区',
  '板橋区',
  '練馬区',
  '足立区',
  '葛飾区',
  '江戸川区',
];

class WardRanking {
  const WardRanking({
    required this.rank,
    required this.district,
    required this.achievementRate,
    required this.totalSteps,
    required this.totalDistanceKm,
    required this.participantCount,
  });

  final int rank;
  final String district;
  final double achievementRate;
  final int totalSteps;
  final double totalDistanceKm;
  final int participantCount;
}

class MemberRanking {
  const MemberRanking({
    required this.rank,
    required this.userId,
    required this.name,
    required this.district,
    required this.steps,
  });

  final int rank;
  final String userId;
  final String name;
  final String district;
  final int steps;
}

class RankingService {
  RankingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int defaultTargetSteps = 8000;

  /// 指定期間の23区ランキングを取得する。
  /// 達成基準: 期間中の合計歩数 >= ユーザーの目標歩数 × 期間日数
  Future<List<WardRanking>> getWardRankings({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = _dateString(startDate);
    final end = _dateString(endDate);

    final periodStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final periodEnd = DateTime(endDate.year, endDate.month, endDate.day);

    final periodDays = periodEnd.difference(periodStart).inDays + 1;
    if (periodDays <= 0) {
      throw ArgumentError('終了日は開始日以降を指定してください');
    }

    final usersSnapshot = await _firestore.collection('users').get();
    final logsSnapshot = await _firestore
        .collection('walkLogs')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    final wardUserIds = <String, List<String>>{
      for (final ward in tokyo23Wards) ward: [],
    };

    final targetStepsByUser = <String, int>{};

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final district = data['district'] as String?;

      if (district == null || !wardUserIds.containsKey(district)) {
        continue;
      }

      wardUserIds[district]!.add(doc.id);

      targetStepsByUser[doc.id] =
          (data['targetSteps'] as num?)?.toInt() ?? defaultTargetSteps;
    }

    final stepsByUser = <String, int>{};
    final distanceByUser = <String, double>{};

    for (final doc in logsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;

      if (userId == null || !targetStepsByUser.containsKey(userId)) {
        continue;
      }

      final steps = (data['steps'] as num?)?.toInt() ?? 0;
      final distance =
          (data['distanceKm'] as num?)?.toDouble() ?? steps * 0.0007;

      stepsByUser[userId] = (stepsByUser[userId] ?? 0) + steps;
      distanceByUser[userId] = (distanceByUser[userId] ?? 0.0) + distance;
    }

    final rankings = tokyo23Wards.map((ward) {
      final userIds = wardUserIds[ward]!;

      var achievedCount = 0;
      var totalSteps = 0;
      var totalDistance = 0.0;

      for (final userId in userIds) {
        final steps = stepsByUser[userId] ?? 0;
        final target = targetStepsByUser[userId]! * periodDays;

        totalSteps += steps;
        totalDistance += distanceByUser[userId] ?? 0.0;

        if (steps >= target) {
          achievedCount++;
        }
      }

      final participantCount = userIds.length;
      final achievementRate = participantCount == 0
          ? 0.0
          : achievedCount / participantCount * 100;

      return WardRanking(
        rank: 0,
        district: ward,
        achievementRate: achievementRate,
        totalSteps: totalSteps,
        totalDistanceKm: totalDistance,
        participantCount: participantCount,
      );
    }).toList();

    rankings.sort((a, b) {
      final achievement = b.achievementRate.compareTo(a.achievementRate);
      if (achievement != 0) {
        return achievement;
      }

      final steps = b.totalSteps.compareTo(a.totalSteps);
      if (steps != 0) {
        return steps;
      }

      return a.district.compareTo(b.district);
    });

    return [
      for (var i = 0; i < rankings.length; i++)
        WardRanking(
          rank: i + 1,
          district: rankings[i].district,
          achievementRate: rankings[i].achievementRate,
          totalSteps: rankings[i].totalSteps,
          totalDistanceKm: rankings[i].totalDistanceKm,
          participantCount: rankings[i].participantCount,
        ),
    ];
  }

  /// 区ランキングまたはチームランキングのメンバー順位を取得する。
  Future<List<MemberRanking>> getMemberRankings({
    required DateTime startDate,
    required DateTime endDate,
    String? district,
    String? teamId,
  }) async {
    if ((district == null) == (teamId == null)) {
      throw ArgumentError('district または teamId のどちらか一方だけを指定してください');
    }

    final start = _dateString(startDate);
    final end = _dateString(endDate);

    final usersSnapshot = await _firestore.collection('users').get();
    final logsSnapshot = await _firestore
        .collection('walkLogs')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    final selectedUsers = <String, Map<String, dynamic>>{};

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();

      final matches = district != null
          ? data['district'] == district
          : data['teamId'] == teamId;

      if (matches) {
        selectedUsers[doc.id] = data;
      }
    }

    final stepsByUser = <String, int>{};

    for (final doc in logsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;

      if (userId == null || !selectedUsers.containsKey(userId)) {
        continue;
      }

      final steps = (data['steps'] as num?)?.toInt() ?? 0;
      stepsByUser[userId] = (stepsByUser[userId] ?? 0) + steps;
    }

    final members = selectedUsers.entries.map((entry) {
      final data = entry.value;

      return MemberRanking(
        rank: 0,
        userId: entry.key,
        name: (data['name'] ?? data['displayName'] ?? '名前未設定').toString(),
        district: (data['district'] ?? '').toString(),
        steps: stepsByUser[entry.key] ?? 0,
      );
    }).toList();

    members.sort((a, b) {
      final steps = b.steps.compareTo(a.steps);
      if (steps != 0) {
        return steps;
      }
      return a.name.compareTo(b.name);
    });

    return [
      for (var i = 0; i < members.length; i++)
        MemberRanking(
          rank: i + 1,
          userId: members[i].userId,
          name: members[i].name,
          district: members[i].district,
          steps: members[i].steps,
        ),
    ];
  }

  String _dateString(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
