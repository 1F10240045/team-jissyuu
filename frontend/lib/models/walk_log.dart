import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/walk_log_service.dart';

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

  /// 年代と身長（任意入力）から1歩あたりの歩幅（メートル）を算出
  /// - 身長が入力されている場合: 身長(m) × 0.45 × 年代別歩幅維持係数
  /// - 身長が未入力(null)の場合: 年代ごとの標準歩幅（50代:72cm, 60代:68cm, 70代:62cm, 80代:55cm, 90代+:48cm）
  static double calculateStrideMeters({String? ageGroup, double? heightCm}) {
    final age = ageGroup ?? WalkLogService.currentUserAgeGroup;
    final height = heightCm ?? WalkLogService.currentUserHeightCm;

    // 年代別の歩幅維持係数（若年・50代を1.0とした場合のシニア年代別係数）
    final Map<String, double> ageFactorMap = {
      '50代': 1.00,
      '60代': 0.94,
      '70代': 0.86,
      '80代': 0.76,
      '90代+': 0.67,
    };

    // 身長未入力時の年代別デフォルト歩幅（メートル）
    final Map<String, double> defaultStrideByAge = {
      '50代': 0.72,
      '60代': 0.68,
      '70代': 0.62,
      '80代': 0.55,
      '90代+': 0.48,
    };

    if (height != null && height >= 100 && height <= 220) {
      final baseStride = (height / 100.0) * 0.45;
      final factor = ageFactorMap[age] ?? 0.86;
      return double.parse((baseStride * factor).toStringAsFixed(3));
    }

    return defaultStrideByAge[age] ?? 0.62;
  }

  /// 歩数＋年代・身長別歩幅＋歩行中GPS実測のハイブリッド距離(km)を計算
  static double calculateDistanceKm(
    int steps, {
    String? ageGroup,
    double? heightCm,
    double? gpsMeters,
  }) {
    final strideM = calculateStrideMeters(
      ageGroup: ageGroup,
      heightCm: heightCm,
    );
    final strideBasedMeters = steps * strideM;
    final activeGpsMeters =
        gpsMeters ?? WalkLogService.currentGpsDistanceMeters;

    // 歩行中にGPS実測距離が計測されており、かつ妥当な範囲（歩幅換算の0.5倍〜1.6倍以内）ならGPS実測を優先し、
    // 室内歩行やテスト加算分の歩数は歩幅換算でハイブリッド合算する
    double totalMeters = strideBasedMeters;
    if (activeGpsMeters >= 5.0 && steps > 0) {
      // GPSで実測された歩数分と、室内/テスト分の差分を滑らかに統合
      if (activeGpsMeters <= strideBasedMeters * 1.6) {
        totalMeters = activeGpsMeters > strideBasedMeters
            ? activeGpsMeters
            : strideBasedMeters;
      }
    }

    return double.parse((totalMeters / 1000.0).toStringAsFixed(2));
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
