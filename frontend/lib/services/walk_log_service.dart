import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/dummy_data.dart';
import '../models/walk_log.dart';
import 'web_motion_helper.dart';

class WalkLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // アプリ内で共有する本日の最新歩数とプロフィール情報（localStorageに自動保存・自動復元）
  static String currentAccountId = 'walk-1024';
  static int currentTodaySteps = 0;
  static String currentUserName = dummyUserProfile.displayName;
  static String currentUserDistrict = dummyUserProfile.district;
  static String currentUserAgeGroup = '70代';
  static int currentTargetSteps = dummyUserProfile.targetSteps;
  static double? currentUserHeightCm;
  static double currentGpsDistanceMeters = 0.0;
  static bool _initializedFromStorage = false;

  /// アプリ起動時にスマホ本体（ブラウザのlocalStorage）から前回の状態を自動復元
  /// 初回起動時はそのスマホ専用のフレンドID（walk-XXXX）を自動発行して記憶する
  static void initFromLocalStorage() {
    if (_initializedFromStorage) return;
    _initializedFromStorage = true;

    String savedId = WebMotionHelper.loadLocalData('accountId');
    if (savedId.isEmpty) {
      final randCode = 1000 + Random().nextInt(9000);
      savedId = 'walk-$randCode';
      WebMotionHelper.saveLocalData('accountId', savedId);
    }
    currentAccountId = savedId;

    final savedName = WebMotionHelper.loadLocalData('userName');
    if (savedName.isNotEmpty) currentUserName = savedName;

    final savedDistrict = WebMotionHelper.loadLocalData('userDistrict');
    if (savedDistrict.isNotEmpty) currentUserDistrict = savedDistrict;

    final savedAge = WebMotionHelper.loadLocalData('userAgeGroup');
    if (savedAge.isNotEmpty) currentUserAgeGroup = savedAge;

    final savedTarget = int.tryParse(
      WebMotionHelper.loadLocalData('targetSteps'),
    );
    if (savedTarget != null && savedTarget > 0) {
      currentTargetSteps = savedTarget;
    }

    final savedHeight = double.tryParse(
      WebMotionHelper.loadLocalData('heightCm'),
    );
    if (savedHeight != null && savedHeight >= 100 && savedHeight <= 220) {
      currentUserHeightCm = savedHeight;
    }

    final savedSteps = int.tryParse(
      WebMotionHelper.loadLocalData('todaySteps'),
    );
    if (savedSteps != null && savedSteps >= 0) {
      currentTodaySteps = savedSteps;
    }

    final savedGps = double.tryParse(
      WebMotionHelper.loadLocalData('gpsMeters'),
    );
    if (savedGps != null && savedGps >= 0) {
      currentGpsDistanceMeters = savedGps;
    }

    upsertRegisteredAccount({
      'accountId': currentAccountId,
      'name': currentUserName,
      'district': currentUserDistrict,
      'ageGroup': currentUserAgeGroup,
      'targetSteps': currentTargetSteps,
      'heightCm': currentUserHeightCm,
      'steps': currentTodaySteps,
    });
  }

  /// 現在のプロフィール・歩数状態をスマホ本体（localStorage）へ即座に自動保存
  static void persistToLocalStorage() {
    WebMotionHelper.saveLocalData('accountId', currentAccountId);
    WebMotionHelper.saveLocalData('userName', currentUserName);
    WebMotionHelper.saveLocalData('userDistrict', currentUserDistrict);
    WebMotionHelper.saveLocalData('userAgeGroup', currentUserAgeGroup);
    WebMotionHelper.saveLocalData('targetSteps', currentTargetSteps.toString());
    WebMotionHelper.saveLocalData(
      'heightCm',
      currentUserHeightCm != null ? currentUserHeightCm.toString() : '',
    );
    WebMotionHelper.saveLocalData('todaySteps', currentTodaySteps.toString());
    WebMotionHelper.saveLocalData(
      'gpsMeters',
      currentGpsDistanceMeters.toString(),
    );

    upsertRegisteredAccount({
      'accountId': currentAccountId,
      'name': currentUserName,
      'district': currentUserDistrict,
      'ageGroup': currentUserAgeGroup,
      'targetSteps': currentTargetSteps,
      'heightCm': currentUserHeightCm,
      'steps': currentTodaySteps,
    });
  }

  /// システムに登録されている実在ユーザーアカウント台帳
  static final List<Map<String, dynamic>> registeredAccounts = [
    {
      'accountId': 'sato-0001',
      'name': '佐藤 健一',
      'district': '世田谷区',
      'ageGroup': '70代',
      'targetSteps': 6000,
      'heightCm': 165.0,
      'steps': 6420,
    },
    {
      'accountId': 'suzuki-02',
      'name': '鈴木 節子',
      'district': '練馬区',
      'ageGroup': '60代',
      'targetSteps': 8000,
      'heightCm': 154.0,
      'steps': 8150,
    },
    {
      'accountId': 'takahashi3',
      'name': '高橋 義男',
      'district': '北区',
      'ageGroup': '80代',
      'targetSteps': 4000,
      'heightCm': 160.0,
      'steps': 4300,
    },
    {
      'accountId': 'tanaka-04',
      'name': '田中 和子',
      'district': '新宿区',
      'ageGroup': '70代',
      'targetSteps': 6000,
      'heightCm': 152.0,
      'steps': 5200,
    },
    {
      'accountId': 'ito-0005',
      'name': '伊藤 茂',
      'district': '大田区',
      'ageGroup': '60代',
      'targetSteps': 8000,
      'heightCm': 168.0,
      'steps': 7890,
    },
    {
      'accountId': 'hanako-11',
      'name': 'すずき はなこ',
      'district': '世田谷区',
      'ageGroup': '70代',
      'targetSteps': 6000,
      'heightCm': 153.0,
      'steps': 7400,
    },
    {
      'accountId': 'satoru-12',
      'name': 'たなか さとる',
      'district': '練馬区',
      'ageGroup': '70代',
      'targetSteps': 8000,
      'heightCm': 166.0,
      'steps': 8200,
    },
    {
      'accountId': 'ichiro-13',
      'name': 'やまだ いちろう',
      'district': '大田区',
      'ageGroup': '80代',
      'targetSteps': 4000,
      'heightCm': 162.0,
      'steps': 4900,
    },
  ];

  /// アカウントIDまたは名前で実在する登録済みアカウントを検索（存在しない場合は null）
  static Future<Map<String, dynamic>?> findRegisteredAccount(
    String query,
  ) async {
    final normalized = query.trim().replaceAll('　', ' ');
    if (normalized.isEmpty) return null;
    final noSpaceQuery = normalized.replaceAll(' ', '').toLowerCase();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(milliseconds: 1000));
      for (final doc in snap.docs) {
        final data = doc.data();
        final id = (data['accountId'] ?? doc.id).toString();
        final name = (data['name'] ?? data['displayName'] ?? '').toString();
        if (id.toLowerCase() == noSpaceQuery ||
            name.replaceAll(' ', '').replaceAll('　', '').toLowerCase() ==
                noSpaceQuery) {
          final found = <String, dynamic>{
            'accountId': id,
            'name': name.isEmpty ? id : name,
            'district': (data['district'] ?? '渋谷区').toString(),
            'ageGroup': (data['ageGroup'] ?? '70代').toString(),
            'targetSteps': (data['targetSteps'] as num?)?.toInt() ?? 8000,
            'heightCm': (data['heightCm'] as num?)?.toDouble(),
            'steps': (data['todaySteps'] as num?)?.toInt() ?? 5000,
          };
          upsertRegisteredAccount(found);
          return found;
        }
      }
    } catch (_) {}

    for (final acc in registeredAccounts) {
      final id = (acc['accountId'] ?? '').toString().toLowerCase();
      final name = (acc['name'] ?? '')
          .toString()
          .replaceAll(' ', '')
          .replaceAll('　', '')
          .toLowerCase();
      if (id == noSpaceQuery || name == noSpaceQuery) {
        return acc;
      }
    }

    return null;
  }

  static void upsertRegisteredAccount(Map<String, dynamic> account) {
    final id = account['accountId'].toString();
    final idx = registeredAccounts.indexWhere(
      (a) => a['accountId'].toString().toLowerCase() == id.toLowerCase(),
    );
    if (idx >= 0) {
      registeredAccounts[idx] = {...registeredAccounts[idx], ...account};
    } else {
      registeredAccounts.insert(0, account);
    }
  }

  // 歩数ストリームの取得
  Stream<StepCount> get stepCountStream => Pedometer.stepCountStream;

  // 権限リクエスト
  Future<bool> requestPermission() async {
    try {
      PermissionStatus status = await Permission.activityRecognition.request();

      if (status.isDenied) {
        status = await Permission.sensors.request();
      }

      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  String get currentUserId => currentAccountId;

  String getTodayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 歩数ログをスマホ本体（localStorage）と Firestore の両方へ自動保存
  Future<WalkLog> saveWalkLog({
    required int steps,
    int? actualSeconds,
    String? district,
  }) async {
    currentTodaySteps = steps;
    persistToLocalStorage();

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

    final userDistrict = district ?? currentUserDistrict;

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

    await _firestore
        .collection('walkLogs')
        .doc(docId)
        .set(walkLog.toMap(), SetOptions(merge: true));

    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'accountId': currentAccountId,
      'name': currentUserName,
      'displayName': currentUserName,
      'district': userDistrict,
      'ageGroup': currentUserAgeGroup,
      'targetSteps': currentTargetSteps,
      'heightCm': currentUserHeightCm,
      'teamId': dummyUserProfile.teamId,
      'todaySteps': steps,
      'totalSteps': dummyUserProfile.totalSteps + steps,
      'totalDistanceKm': double.parse(
        (dummyUserProfile.totalDistanceKm + distanceKm).toStringAsFixed(2),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return walkLog;
  }
}
