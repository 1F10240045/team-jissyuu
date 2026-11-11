import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 23区対抗ランキングデータ
    final wardRanking = [
      {'rank': 1, 'name': '千代田区', 'achievement': '128%', 'distance': '1,420km'},
      {'rank': 2, 'name': '港区', 'achievement': '115%', 'distance': '1,310km'},
      {'rank': 3, 'name': '新宿区', 'achievement': '108%', 'distance': '1,250km'},
      {'rank': 4, 'name': '北区（あなたの区）', 'achievement': '98%', 'distance': '1,100km', 'isMyWard': true},
      {'rank': 5, 'name': '中央区', 'achievement': '95%', 'distance': '1,050km'},
      {'rank': 6, 'name': '文京区', 'achievement': '91%', 'distance': '980km'},
      {'rank': 7, 'name': '品川区', 'achievement': '88%', 'distance': '920km'},
    ];

    // 2. 個人/フレンド内ランキングデータ
    final memberRanking = [
      {'rank': 1, 'name': 'たなか さとる', 'ward': '千代田区', 'steps': 8200, 'isMe': false},
      {'rank': 2, 'name': 'すずき はなこ', 'ward': '港区', 'steps': 7400, 'isMe': false},
      {'rank': 3, 'name': 'さとう けんじ', 'ward': '北区', 'steps': 6800, 'isMe': false},
      {'rank': 4, 'name': 'あなた', 'ward': '北区', 'steps': 5200, 'isMe': true},
      {'rank': 5, 'name': 'やまだ いちろう', 'ward': '新宿区', 'steps': 4900, 'isMe': false},
      {'rank': 6, 'name': 'わたなべ けいこ', 'ward': '北区', 'steps': 4100, 'isMe': false},
    ];

    // 自分のデータ（下部固定用）
    final myData = memberRanking.firstWhere(
      (element) => element['isMe'] == true,
      orElse: () => {'rank': 4, 'name': 'あなた', 'ward': '北区', 'steps': 5200, 'isMe': true},
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ランキング',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: '23区対抗'),
              Tab(text: 'フレンド・メンバー'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF4F6F9),
        body: TabBarView(
          children: [
            // タブ1: 23区対抗ランキング
            _buildWardRankingTab(wardRanking),

            // タブ2: フレンド・メンバーランキング
            _buildMemberRankingTab(memberRanking, myData),
          ],
        ),
      ),
    );
  }

  // --- タブ1: 23区対抗ランキング ---
  Widget _buildWardRankingTab(List<dynamic> wardList) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPodiumHeader(wardList),
        const SizedBox(height: 20),
        const Text(
          '全区順位一覧',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        ...wardList.skip(3).map((ward) => _buildWardTile(ward)),
      ],
    );
  }

  // 1〜3位の表彰台UI
  Widget _buildPodiumHeader(List<dynamic> wardList) {
    if (wardList.length < 3) return const SizedBox();
    final first = wardList[0];
    final second = wardList[1];
    final third = wardList[2];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          const Text(
            '🏆 23区 トップ3 🏆',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodiumItem(second['name'].toString(), '2位', Colors.grey.shade400, 90),
              _buildPodiumItem(first['name'].toString(), '1位', Colors.amber, 120),
              _buildPodiumItem(third['name'].toString(), '3位', Colors.brown.shade300, 75),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(String name, String rankText, Color color, double height) {
    return Column(
      children: [
        Icon(Icons.emoji_events, color: color, size: height > 100 ? 36 : 28),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              rankText,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ],
    );
  }

  // 区のリスト行
  Widget _buildWardTile(dynamic ward) {
    final bool isMyWard = ward['isMyWard'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isMyWard ? Colors.orange.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMyWard ? BorderSide(color: Colors.orange.shade400, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '${ward['rank']}位',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                ward['name'].toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isMyWard ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '達成率 ${ward['achievement']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                Text(
                  '累計 ${ward['distance']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- タブ2: フレンド・メンバーランキング ---
  Widget _buildMemberRankingTab(List<dynamic> memberList, dynamic myData) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: memberList.length,
            itemBuilder: (context, index) {
              final user = memberList[index];
              final bool isMe = user['isMe'] == true;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isMe ? Colors.lightBlue.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isMe ? BorderSide(color: Colors.blue.shade400, width: 2) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${user['rank']}位',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: isMe ? Colors.blue.shade300 : Colors.grey.shade300,
                        child: Icon(Icons.person, color: isMe ? Colors.white : Colors.grey.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'].toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              user['ward'].toString(),
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
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
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.blue.shade800,
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'あなたの順位: ${myData['rank']}位 (${myData['ward']})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${myData['steps']} 歩',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}