import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

import '../models/walk_log.dart';
import '../services/walk_log_service.dart';
import '../services/web_motion_helper.dart';
import '../theme/app_theme.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final WalkLogService _walkLogService = WalkLogService();
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _autoSaveDebounce;
  Timer? _webMotionPollTimer;

  int _steps = WalkLogService.currentTodaySteps;
  int? _initialSensorSteps;
  int _lastWebRawSteps = 0;
  bool _webSensorActive = false;
  String _status = '歩数センサー初期化中...';
  bool _isSaving = false;
  String _syncStatus = '自動保存モード：有効';

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _autoSaveDebounce?.cancel();
    _webMotionPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPedometer() async {
    if (kIsWeb) {
      setState(() {
        _status = 'iPhone/スマホの方は下の「スマホセンサーで計測開始」を押してください';
      });
      return;
    }

    bool granted = await _walkLogService.requestPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _status = 'センサー未許可 / エミュレータ環境（下のボタンで歩数加算＆自動保存）';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _status = 'スマホ歩数センサーで自動計測・自動保存中';
    });

    _stepSubscription = _walkLogService.stepCountStream.listen(
      (StepCount event) {
        if (!mounted) return;
        setState(() {
          _initialSensorSteps ??= event.steps - _steps;
          final calculated = event.steps - _initialSensorSteps!;
          _steps = calculated >= 0 ? calculated : event.steps;
          WalkLogService.currentTodaySteps = _steps;
        });
        _scheduleAutoSave();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _status = 'センサー非対応環境（テストボタンで動作確認可）';
        });
      },
    );
  }

  /// iPhone (Safari / LINE) 等の Web モーションセンサーを有効化して歩行カウントを開始
  Future<void> _enableWebMotionSensor() async {
    final result = await WebMotionHelper.requestPermission();
    if (!mounted) return;

    if (result == 'granted') {
      _lastWebRawSteps = WebMotionHelper.getStepCount();
      setState(() {
        _webSensorActive = true;
        _status = '🟢 iPhoneモーションセンサー計測中！（スマホを持って歩いてください）';
      });

      _webMotionPollTimer?.cancel();
      _webMotionPollTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) {
          if (!mounted) return;
          final currentRaw = WebMotionHelper.getStepCount();
          final gpsMeters = WebMotionHelper.getGpsDistanceMeters();
          final diff = currentRaw - _lastWebRawSteps;
          final gpsChanged =
              (gpsMeters - WalkLogService.currentGpsDistanceMeters).abs() >= 1.0;

          if (diff > 0 || gpsChanged) {
            _lastWebRawSteps = currentRaw;
            setState(() {
              if (diff > 0) _steps += diff;
              WalkLogService.currentTodaySteps = _steps;
              WalkLogService.currentGpsDistanceMeters = gpsMeters;
            });
            WalkLogService.persistToLocalStorage();
            _scheduleAutoSave();
          }
        },
      );
    } else if (result == 'denied') {
      setState(() {
        _status = '⚠️ モーションセンサーが拒否されました（Safariの再読み込みで再試行可）';
      });
    } else {
      setState(() {
        _status = '⚠️ モーションセンサーはHTTPS接続時（公開URL）のiPhoneで動作します';
      });
    }
  }

  /// 歩数が連続で増えた際に通信が集中しないよう、1.5秒後に自動でFirestoreへ保存する
  void _scheduleAutoSave() {
    setState(() {
      _syncStatus = '🔄 歩数の変化を検知：自動保存を準備中...';
    });
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 1500), () {
      _saveToFirestore(isAuto: true);
    });
  }

  void _addTestSteps(int amount) {
    setState(() {
      _steps += amount;
      WalkLogService.currentTodaySteps = _steps;
      _status = 'テストデータ（+$amount歩）適用中';
    });
    WalkLogService.persistToLocalStorage();
    _scheduleAutoSave();
  }

  Future<void> _saveToFirestore({bool isAuto = false}) async {
    if (!mounted) return;
    setState(() {
      _isSaving = true;
      _syncStatus = '☁️ Firestoreへ自動同期中...';
    });

    try {
      final savedLog = await _walkLogService
          .saveWalkLog(steps: _steps)
          .timeout(const Duration(milliseconds: 1200));

      if (!mounted) return;
      final now = TimeOfDay.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _isSaving = false;
        _syncStatus =
            '✅ 自動保存済み ($timeStr 時点: ${savedLog.steps}歩)';
      });

      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('最新の歩数データを保存しました！'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final distKm = WalkLog.calculateDistanceKm(_steps);
      setState(() {
        _isSaving = false;
        _syncStatus = '✅ 自動保存完了（$_steps歩 / ${distKm}km）';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetSteps = WalkLogService.currentTargetSteps;
    final distanceKm = WalkLog.calculateDistanceKm(_steps);
    final caloriesKcal = WalkLog.calculateCalories(_steps);
    final durationMin = WalkLog.calculateEstimatedMinutes(_steps);
    final strideCm = (WalkLog.calculateStrideMeters() * 100).round();
    final heightInfo = WalkLogService.currentUserHeightCm != null
        ? '${WalkLogService.currentUserAgeGroup}・身長${WalkLogService.currentUserHeightCm!.toInt()}cm'
        : '${WalkLogService.currentUserAgeGroup}平均';

    return Scaffold(
      appBar: AppBar(title: const Text('運動・歩数計測')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. 自動保存ステータスバー
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  else
                    const Icon(
                      Icons.cloud_done,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _syncStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ★ iPhone / スマホWeb 用：モーションセンサー起動ボタン
            if (kIsWeb) ...[
              ElevatedButton.icon(
                icon: Icon(
                  _webSensorActive
                      ? Icons.sensors
                      : Icons.phone_iphone,
                  size: 24,
                ),
                label: Text(
                  _webSensorActive
                      ? '🟢 iPhoneセンサー計測中！（歩いてみましょう）'
                      : '📱 iPhoneの歩数センサーで計測開始',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _webSensorActive
                      ? Colors.teal.shade700
                      : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _enableWebMotionSensor,
              ),
              const SizedBox(height: 14),
            ],

            // 1. メインの歩数表示カード
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      '本日の歩数（自動計測）',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_steps',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '歩',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _steps >= targetSteps
                          ? '🎉 本日の目標（$targetSteps歩）を達成しました！'
                          : '目標 $targetSteps歩 まで あと ${targetSteps - _steps} 歩',
                      style: TextStyle(
                        fontSize: 16,
                        color: _steps >= targetSteps
                            ? AppTheme.primaryColor
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_steps / targetSteps).clamp(0.0, 1.0),
                        minHeight: 14,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. 距離・カロリー・歩行速度（ロコモ予防指標）の3指標カード
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.place,
                    label: '歩行距離',
                    value: '$distanceKm',
                    unit: 'km',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    label: '消費カロリー',
                    value: '$caloriesKcal',
                    unit: 'kcal',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timer,
                    label: '歩いた時間',
                    value: '$durationMin',
                    unit: '分',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 歩幅＆歩行中限定GPSハイブリッド距離算出の説明バッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.straighten, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '距離算出: 1歩 約${strideCm}cm（$heightInfo）＋歩行・ランニングGPSハイブリッド（時速18km超の電車・車は自動除外）',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // センサー状態表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'センサー状態: $_status',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. エミュレータ・デモ検証用の歩数加算ボタン
            const Text(
              '🛠 デモ・動作確認用ツール（押すと自動保存されます）',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('+100歩', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _addTestSteps(100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions_run),
                    label:
                        const Text('+1,000歩', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _addTestSteps(1000),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. 手動で即時同期したい場合の補助ボタン
            ElevatedButton.icon(
              icon: const Icon(Icons.sync, size: 22),
              label: const Text(
                '今すぐ手動で同期する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed:
                  _isSaving ? null : () => _saveToFirestore(isAuto: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
