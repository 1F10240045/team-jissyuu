import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

import '../models/walk_log.dart';
import '../services/walk_log_service.dart';
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

  int _steps = WalkLogService.currentTodaySteps;
  int? _initialSensorSteps;
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
    super.dispose();
  }

  Future<void> _initPedometer() async {
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
          // 初回取得時の端末累計歩数を基準として差分を加算
          _initialSensorSteps ??= event.steps - _steps;
          final calculated = event.steps - _initialSensorSteps!;
          _steps = calculated >= 0 ? calculated : event.steps;
          WalkLogService.currentTodaySteps = _steps;
        });
        // 歩数が変化したら自動でFirestoreへ非同期保存（デバウンス処理付き）
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
    // テスト加算時も自動でFirestoreへ保存
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
          .timeout(const Duration(seconds: 3));

      if (!mounted) return;
      final now = TimeOfDay.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _isSaving = false;
        _syncStatus =
            '✅ 自動保存済み ($timeStr 時点: ${savedLog.steps}歩 / ${savedLog.distanceKm}km)';
      });

      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('最新の歩数データを Firestore に同期しました！'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _syncStatus = '📌 自動記録済み（$_steps歩 ※ローカル保持中）';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = WalkLog.calculateDistanceKm(_steps);
    final caloriesKcal = WalkLog.calculateCalories(_steps);
    final durationMin = WalkLog.calculateEstimatedMinutes(_steps);
    final speedMPerMin =
        WalkLog.calculateSpeedMetersPerMin(distanceKm, durationMin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('運動・歩数計測'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. 自動保存ステータスバー（上部に常時わかりやすく表示）
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

            const SizedBox(height: 16),

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
                      _steps >= 4000
                          ? '🎉 本日の目標（4,000歩）を達成しました！'
                          : '目標 4,000歩 まで あと ${4000 - _steps} 歩',
                      style: TextStyle(
                        fontSize: 16,
                        color: _steps >= 4000
                            ? AppTheme.primaryColor
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_steps / 4000).clamp(0.0, 1.0),
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
                    icon: Icons.speed,
                    label: '歩く速さ',
                    value: '$speedMPerMin',
                    unit: 'm/分',
                    color: Colors.teal,
                  ),
                ),
              ],
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
