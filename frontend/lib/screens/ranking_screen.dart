import 'package:flutter/material.dart';

import '../constants/dummy_data.dart';
import '../models/walk_log.dart';
import '../services/ranking_service.dart';
import '../services/walk_log_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final RankingService _rankingService = RankingService();

  bool _isLoading = true;
  List<WardRanking> _wardRankings = [];
  List<MemberRanking> _memberRankings = [];

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  /// Firestoreまたは初期シードデータ＋現在のユーザーの歩数を統合してランキングを算出
  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
    });

    final mySteps = WalkLogService.currentTodaySteps;
    final myDistrict = WalkLogService.currentUserDistrict;
    final myName = WalkLogService.currentUserName;
    final today = DateTime.now();

    List<WardRanking> resolvedWards = [];
    List<MemberRanking> resolvedMembers = [];

    // 1. Firestoreから取得を試みる（1.2秒でタイムアウトしてグルグル防止）
    try {
      final firestoreWards = await _rankingService
          .getWardRankings(startDate: today, endDate: today)
          .timeout(const Duration(milliseconds: 1200));

      if (firestoreWards.any((w) => w.totalSteps > 0)) {
        resolvedWards = firestoreWards;
      }

      final firestoreMembers = await _rankingService
          .getMemberRankings(
            startDate: today,
            endDate: today,
            teamId: 'team_001',
          )
          .timeout(const Duration(milliseconds: 1200));

      if (firestoreMembers.isNotEmpty) {
        resolvedMembers = firestoreMembers;
      }
    } catch (_) {
      // エミュレータ未接続時はシードデータ＋本日の自分の歩数を統合
    }

    // 2. 23区ランキングの構築（シードデータに自分の本日の歩数・達成度を加算して再ソート）
    if (resolvedWards.isEmpty) {
      final rawList = <WardRanking>[];
      for (final raw in initialDistrictRankings) {
        final item = raw as Map<String, dynamic>;
        final district = item['district'] as String;
        final isMyWard = district == myDistrict;

        final baseSteps = (item['totalSteps'] as num).toInt();
        final baseDist = (item['totalDistanceKm'] as num).toDouble();
        final baseRate = (item['achievementRate'] as num).toDouble();

        final addedSteps = isMyWard ? mySteps : 0;
        final addedDist = isMyWard ? WalkLog.calculateDistanceKm(mySteps) : 0.0;
        // 自分が歩くと自分の区の達成率も少しずつ上昇する連動演出
        final addedRate = isMyWard
            ? (mySteps / WalkLogService.currentTargetSteps) * 2.5
            : 0.0;

        rawList.add(
          WardRanking(
            rank: 0,
            district: district,
            achievementRate: (baseRate + addedRate).clamp(0.0, 100.0),
            totalSteps: baseSteps + addedSteps,
            totalDistanceKm: baseDist + addedDist,
            participantCount: isMyWard ? 25 : 20,
          ),
        );
      }

      rawList.sort((a, b) {
        final cmp = b.achievementRate.compareTo(a.achievementRate);
        if (cmp != 0) return cmp;
        return b.totalSteps.compareTo(a.totalSteps);
      });

      resolvedWards = [
        for (var i = 0; i < rawList.length; i++)
          WardRanking(
            rank: i + 1,
            district: rawList[i].district,
            achievementRate: rawList[i].achievementRate,
            totalSteps: rawList[i].totalSteps,
            totalDistanceKm: rawList[i].totalDistanceKm,
            participantCount: rawList[i].participantCount,
          ),
      ];
    }

    // 3. フレンド・メンバーランキングの構築（自分の最新歩数を入れてリアルタイム順位ソート）
    if (resolvedMembers.isEmpty) {
      final tempMembers = <MemberRanking>[
        for (final raw in sampleSeniorUsers)
          MemberRanking(
            rank: 0,
            userId: (raw as Map<String, dynamic>)['userId'] as String,
            name: raw['name'] as String,
            district: raw['district'] as String,
            steps: (raw['todaySteps'] as num).toInt(),
          ),
        MemberRanking(
          rank: 0,
          userId: 'current_user',
          name: '$myName（あなた）',
          district: myDistrict,
          steps: mySteps,
        ),
      ];

      tempMembers.sort((a, b) => b.steps.compareTo(a.steps));

      resolvedMembers = [
        for (var i = 0; i < tempMembers.length; i++)
          MemberRanking(
            rank: i + 1,
            userId: tempMembers[i].userId,
            name: tempMembers[i].name,
            district: tempMembers[i].district,
            steps: tempMembers[i].steps,
          ),
      ];
    }

    if (!mounted) return;
    setState(() {
      _wardRankings = resolvedWards;
      _memberRankings = resolvedMembers;
      _isLoading = false;
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
            labelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: '23区対抗'),
              Tab(text: 'フレンド・メンバー'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF4F6F9),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildWardRankingTab(_wardRankings),
                  _buildMemberRankingTab(_memberRankings),
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
          '全23区 順位一覧',
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
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
    final bool isMyWard = ward.district == WalkLogService.currentUserDistrict;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isMyWard ? Colors.amber.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMyWard
            ? BorderSide(color: Colors.amber.shade700, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '${ward.rank}位',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isMyWard ? Colors.amber.shade900 : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMyWard ? '${ward.district}（あなたの区）' : ward.district,
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

    final myEntry = memberList.firstWhere(
      (m) => m.userId == 'current_user',
      orElse: () => MemberRanking(
        rank: memberList.length,
        userId: 'current_user',
        name: WalkLogService.currentUserName,
        district: WalkLogService.currentUserDistrict,
        steps: WalkLogService.currentTodaySteps,
      ),
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memberList.length,
            itemBuilder: (context, index) {
              final member = memberList[index];
              final isMe = member.userId == 'current_user';

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
                        width: 48,
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
                        '${member.steps} 歩',
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
        // 下部固定バー：自分の現在の順位と歩数
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.blue.shade800,
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'あなたの現在順位: ${myEntry.rank}位 (${myEntry.district})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${myEntry.steps} 歩',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
