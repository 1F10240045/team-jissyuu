import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

import '../services/walk_log_service.dart';

class WalkTestScreen extends StatefulWidget {
  const WalkTestScreen({super.key});

  @override
  State<WalkTestScreen> createState() => _WalkTestScreenState();
}

class _WalkTestScreenState extends State<WalkTestScreen> {
  final WalkLogService _walkLogService = WalkLogService();
  String _steps = '0';
  String _status = '初期化中...';

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  Future<void> _initPedometer() async {
    bool granted = await _walkLogService.requestPermission();
    if (!granted) {
      setState(() {
        _status = '歩数アクセスの権限が拒否されました';
      });
      return;
    }

    setState(() {
      _status = '計測中（またはテスト実行中）...';
    });

    _walkLogService.stepCountStream.listen(
      (StepCount event) {
        setState(() {
          _steps = event.steps.toString();
        });
      },
      onError: (error) {
        // エミュレータ等でセンサーが無い場合もエラーで止めず状態を表示
        setState(() {
          _status = 'センサー非対応（テストボタンで動作確認可）';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歩数計測テスト')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('現在の端末累計歩数:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              _steps,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ステータス: $_status',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // ★ PCエミュレータ検証用のダミーボタン
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text(
                '【テスト用】100歩進める',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                setState(() {
                  int currentSteps = int.tryParse(_steps) ?? 0;
                  _steps = (currentSteps + 100).toString();
                  _status = 'テストデータ（+100歩）適用中';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
