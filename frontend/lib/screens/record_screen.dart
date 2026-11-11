import 'package:flutter/material.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int todaySteps = 5200;
    final int peerAverageSteps = 4500;

    // 型指定をシンプルにしてエラーを回避
    final dummyLogs = [
      {
        'date': '2026/11/11',
        'steps': 5200,
        'distance': 3.6,
        'calories': 180,
        'duration': 45,
      },
      {
        'date': '2026/11/10',
        'steps': 4800,
        'distance': 3.3,
        'calories': 165,
        'duration': 40,
      },
      {
        'date': '2026/11/09',
        'steps': 3900,
        'distance': 2.7,
        'calories': 135,
        'duration': 35,
      },
      {
        'date': '2026/11/08',
        'steps': 6100,
        'distance': 4.2,
        'calories': 210,
        'duration': 55,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '歩行記録',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeerBenchmarkCard(
                todaySteps: todaySteps,
                peerAverageSteps: peerAverageSteps,
              ),
              const SizedBox(height: 24),
              const Text(
                '過去の歩行履歴',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              dummyLogs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dummyLogs.length,
                      itemBuilder: (context, index) {
                        final log = dummyLogs[index];
                        return _buildRecordCard(log);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeerBenchmarkCard({
    required int todaySteps,
    required int peerAverageSteps,
  }) {
    const int maxTarget = 8000;
    final double todayProgress = (todaySteps / maxTarget).clamp(0.0, 1.0);
    final double peerProgress = (peerAverageSteps / maxTarget).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blueAccent, size: 28),
                SizedBox(width: 8),
                Text(
                  '同年代との歩数比較',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'あなた（今日）',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$todaySteps 歩',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: todayProgress,
                    minHeight: 16,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '同年代（70代）平均',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$peerAverageSteps 歩',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: peerProgress,
                    minHeight: 16,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.orange.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      todaySteps >= peerAverageSteps
                          ? '平均を超えています！素晴らしいペースです👏'
                          : '平均まであと ${peerAverageSteps - todaySteps} 歩です！無理せず伸ばしていきましょう😊',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log['date'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${log['steps']} 歩',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  icon: Icons.directions_walk,
                  label: '距離',
                  value: '${log['distance']} km',
                ),
                _buildMetricItem(
                  icon: Icons.timer,
                  label: '時間',
                  value: '${log['duration']} 分',
                ),
                _buildMetricItem(
                  icon: Icons.local_fire_department,
                  label: 'カロリー',
                  value: '${log['calories']} kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Text(
        'まだ記録がありません',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}