import 'package:cloud_firestore/cloud_firestore.dart';

/// 歩行ログのデータモデル（Firestore の `walkLogs` コレクションに対応）
class WalkLog {
  final String walkLogId;
  final String userId;
  final String? teamId;
  final String district;
  final String date; // YYYY-MM-DD
  final int steps;
  final double distanceKm;
  final int caloriesKcal;
  final int durationMinutes;
  final double speedMetersPerMin; // 分速 (m/分) - ロコモ予防指標
  final DateTime createdAt;

  WalkLog({
    required this.walkLogId,
    required this.userId,
    this.teamId,
    required this.district,
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.caloriesKcal,
    required this.durationMinutes,
    required this.speedMetersPerMin,
    required this.createdAt,
  });

  /// 歩数から距離(km)を計算（1歩あたり約0.7m想定）
  static double calculateDistanceKm(int steps) {
    return double.parse((steps * 0.0007).toStringAsFixed(2));
  }

  /// 歩数から消費カロリー(kcal)を計算（1歩あたり約0.04kcal想定）
  static int calculateCalories(int steps) {
    return (steps * 0.04).round();
  }

  /// 歩数から推定歩行時間（分）を計算（1分あたり約80歩想定）
  static int calculateEstimatedMinutes(int steps, {int? actualSeconds}) {
    if (actualSeconds != null && actualSeconds >= 60) {
      return (actualSeconds / 60).round();
    }
    if (steps == 0) return 0;
    final estimated = (steps / 80).round();
    return estimated < 1 ? 1 : estimated;
  }

  /// 距離(km)と時間(分)から歩行速度（分速 m/分）を計算
  static double calculateSpeedMetersPerMin(
    double distanceKm,
    int durationMinutes,
  ) {
    if (durationMinutes <= 0) return 0.0;
    final meters = distanceKm * 1000;
    return double.parse((meters / durationMinutes).toStringAsFixed(1));
  }

  Map<String, dynamic> toMap() {
    return {
      'walkLogId': walkLogId,
      'userId': userId,
      'teamId': teamId,
      'district': district,
      'date': date,
      'steps': steps,
      'distanceKm': distanceKm,
      'caloriesKcal': caloriesKcal,
      'durationMinutes': durationMinutes,
      'speedMetersPerMin': speedMetersPerMin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WalkLog.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parsedCreatedAt = DateTime.now();
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    final steps = (map['steps'] as num?)?.toInt() ?? 0;
    final distanceKm =
        (map['distanceKm'] as num?)?.toDouble() ?? calculateDistanceKm(steps);
    final durationMinutes =
        (map['durationMinutes'] as num?)?.toInt() ??
        calculateEstimatedMinutes(steps);

    return WalkLog(
      walkLogId: id ?? (map['walkLogId'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      teamId: map['teamId'] as String?,
      district: map['district'] as String? ?? '渋谷区',
      date: map['date'] as String? ?? '',
      steps: steps,
      distanceKm: distanceKm,
      caloriesKcal:
          (map['caloriesKcal'] as num?)?.toInt() ?? calculateCalories(steps),
      durationMinutes: durationMinutes,
      speedMetersPerMin:
          (map['speedMetersPerMin'] as num?)?.toDouble() ??
          calculateSpeedMetersPerMin(distanceKm, durationMinutes),
      createdAt: parsedCreatedAt,
    );
  }
}
