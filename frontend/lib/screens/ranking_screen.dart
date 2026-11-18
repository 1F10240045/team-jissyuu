import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ranking_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final RankingService _rankingService = RankingService();

  late Future<List<WardRanking>> _wardRankingFuture;
  late Future<List<MemberRanking>> _memberRankingFuture;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  void _loadRankings() {
    final today = DateTime.now();

    setState(() {
      _wardRankingFuture = _rankingService.getWardRankings(
        startDate: today,
        endDate: today,
      );

      _memberRankingFuture = _rankingService.getMemberRankings(
        startDate: today,
        endDate: today,
        teamId: 'team_001',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
            FutureBuilder<List<WardRanking>>(
              future: _wardRankingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '23区ランキングの取得に失敗しました',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadRankings,
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final wardRanking = snapshot.data ?? const [];
                return _buildWardRankingTab(wardRanking);
              },
            ),
            FutureBuilder<List<MemberRanking>>(
              future: _memberRankingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('メンバーランキングの取得に失敗しました'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadRankings,
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  );
                }

                final memberRanking = snapshot.data ?? const [];
                return _buildMemberRankingTab(memberRanking);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardRankingTab(List<WardRanking> wardList) {
    if (wardList.isEmpty) {
      return const Center(child: Text('ランキングデータがありません'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPodiumHeader(wardList),
        const SizedBox(height: 20),
        const Text(
          '全区順位一覧',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...wardList.map((ward) => _buildWardTile(ward)),
      ],
    );
  }

  Widget _buildPodiumHeader(List<WardRanking> wardList) {
    if (wardList.length < 3) {
      return const SizedBox();
    }

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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodiumItem(second.district, '2位', Colors.grey.shade400, 90),
              _buildPodiumItem(first.district, '1位', Colors.amber, 120),
              _buildPodiumItem(third.district, '3位', Colors.brown.shade300, 75),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    String name,
    String rankText,
    Color color,
    double height,
  ) {
    return Column(
      children: [
        Icon(Icons.emoji_events, color: color, size: height > 100 ? 36 : 28),
        const SizedBox(height: 4),
        SizedBox(
          width: 95,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Text(
            rankText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWardTile(WardRanking ward) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '${ward.rank}位',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ward.district,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '参加人数 ${ward.participantCount}人',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '達成率 ${ward.achievementRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                Text(
                  '累計 ${ward.totalSteps}歩',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '${ward.totalDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRankingTab(List<MemberRanking> memberList) {
    if (memberList.isEmpty) {
      return const Center(child: Text('メンバーが登録されていません'));
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memberList.length,
      itemBuilder: (context, index) {
        final member = memberList[index];
        final isMe =
            member.userId == currentUserId ||
            (currentUserId == null && member.userId == 'dummy_user_id');

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isMe ? Colors.lightBlue.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isMe
                ? BorderSide(color: Colors.blue.shade400, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${member.rank}位',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: isMe
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: isMe ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        member.district,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${member.steps}歩',
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
    );
  }
}
