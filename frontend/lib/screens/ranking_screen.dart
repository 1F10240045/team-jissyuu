import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ランキングのダミーデータ（歩数の多い順）
    final rankingList = [
      {'rank': 1, 'name': 'たなか さとる', 'steps': 8200, 'isMe': false},
      {'rank': 2, 'name': 'すずき はなこ', 'steps': 7400, 'isMe': false},
      {'rank': 3, 'name': 'さとう けんじ', 'steps': 6800, 'isMe': false},
      {'rank': 4, 'name': 'あなた', 'steps': 5200, 'isMe': true},
      {'rank': 5, 'name': 'やまだ いちろう', 'steps': 4900, 'isMe': false},
      {'rank': 6, 'name': 'わたなべ けいこ', 'steps': 4100, 'isMe': false},
      {'rank': 7, 'name': 'いとう ひろし', 'steps': 3500, 'isMe': false},
    ];

    // 自分のデータ（下部固定用）
    final myData = rankingList.firstWhere(
      (element) => element['isMe'] == true,
      orElse: () => {'rank': 4, 'name': 'あなた', 'steps': 5200, 'isMe': true},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '歩数ランキング',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          // 1. 全体ランキングリスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: rankingList.length,
              itemBuilder: (context, index) {
                final user = rankingList[index];
                return _buildRankingTile(user);
              },
            ),
          ),

          // 2. 画面下部に固定表示する「自分の現在順位」
          _buildMyRankingBottomBar(myData),
        ],
      ),
    );
  }

  // リストの各ユーザー行 UI
  Widget _buildRankingTile(Map<String, dynamic> user) {
    final int rank = user['rank'] as int;
    final bool isMe = user['isMe'] as bool;

    // 上位3位の色とアイコン設定
    Color rankColor = Colors.grey.shade100;
    Color textColor = Colors.black87;
    Widget? rankBadge;

    if (rank == 1) {
      rankColor = const Color(0xFFFFF8E1); // 金系背景
      rankBadge = const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
    } else if (rank == 2) {
      rankColor = const Color(0xFFF5F5F5); // 銀系背景
      rankBadge = Icon(Icons.emoji_events, color: Colors.grey.shade500, size: 28);
    } else if (rank == 3) {
      rankColor = const Color(0xFFEFEBE9); // 銅系背景
      rankBadge = Icon(Icons.emoji_events, color: Colors.brown.shade400, size: 26);
    }

    return Card(
      elevation: isMe ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 10),
      color: isMe ? Colors.lightBlue.shade50 : rankColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 順位バッジ / アイコン
            SizedBox(
              width: 44,
              child: rankBadge ??
                  Text(
                    '$rank位',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
            ),
            const SizedBox(width: 8),

            // ユーザーアイコン
            CircleAvatar(
              backgroundColor: isMe ? Colors.blue.shade300 : Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: isMe ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),

            // ユーザー名
            Expanded(
              child: Text(
                user['name'].toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  color: isMe ? Colors.blue.shade900 : Colors.black87,
                ),
              ),
            ),

            // 歩数
            Text(
              '${user['steps']} 歩',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.blue.shade800 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 画面下に固定される自分の順位バー
  Widget _buildMyRankingBottomBar(Map<String, dynamic> myData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  'あなたの順位: ${myData['rank']}位',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              '${myData['steps']} 歩',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}