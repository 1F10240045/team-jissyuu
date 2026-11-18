import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/dummy_data.dart';
import '../models/walk_log.dart';

class WalkLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // アプリ内で共有する本日の最新歩数（画面遷移しても保持されるようにキャッシュ）
  static int currentTodaySteps = 0;

  // 歩数ストリームの取得
  Stream<StepCount> get stepCountStream => Pedometer.stepCountStream;

  // 権限リクエスト
  Future<bool> requestPermission() async {
    try {
      PermissionStatus status = await Permission.activityRecognition.request();

      // iOSの場合は sensors も確認
      if (status.isDenied) {
        status = await Permission.sensors.request();
      }

      return status.isGranted;
    } catch (_) {
      // Web環境やデスクトップ環境でpermission_handlerが非対応の場合もエラーで止めない
      return false;
    }
  }

  /// 現在ログイン中のユーザーID（未ログイン時はダミーユーザーIDにフォールバック）
  String get currentUserId => _auth.currentUser?.uid ?? dummyUserId;

  /// 今日の日付文字列（YYYY-MM-DD）を取得
  String getTodayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 歩数ログを Firestore の `walkLogs` コレクションおよび `users` ドキュメントへ直接保存
  Future<WalkLog> saveWalkLog({
    required int steps,
    int? actualSeconds,
    String? district,
  }) async {
    currentTodaySteps = steps;

    final userId = currentUserId;
    final dateStr = getTodayDateString();
    final docId = '${userId}_$dateStr';

    final distanceKm = WalkLog.calculateDistanceKm(steps);
    final caloriesKcal = WalkLog.calculateCalories(steps);
    final durationMinutes = WalkLog.calculateEstimatedMinutes(
      steps,
      actualSeconds: actualSeconds,
    );
    final speedMetersPerMin = WalkLog.calculateSpeedMetersPerMin(
      distanceKm,
      durationMinutes,
    );

    final userDistrict = district ?? dummyUserProfile.district;

    final walkLog = WalkLog(
      walkLogId: docId,
      userId: userId,
      teamId: dummyUserProfile.teamId,
      district: userDistrict,
      date: dateStr,
      steps: steps,
      distanceKm: distanceKm,
      caloriesKcal: caloriesKcal,
      durationMinutes: durationMinutes,
      speedMetersPerMin: speedMetersPerMin,
      createdAt: DateTime.now(),
    );

    // 1. walkLogs コレクションへ保存（同日のデータは上書き更新）
    await _firestore
        .collection('walkLogs')
        .doc(docId)
        .set(walkLog.toMap(), SetOptions(merge: true));

    // 2. users コレクションのユーザー統計も合わせて更新
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'displayName': dummyUserProfile.displayName,
      'district': userDistrict,
      'ageGroup': dummyUserProfile.ageGroup,
      'teamId': dummyUserProfile.teamId,
      'targetSteps': 8000,
      'todaySteps': steps,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return walkLog;
  }
}
