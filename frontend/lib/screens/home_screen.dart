import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/dummy_data.dart';
import '../models/walk_log.dart';
import '../services/ranking_service.dart';
import '../services/walk_log_service.dart';
import '../theme/app_theme.dart';
import 'exercise_screen.dart';
import 'friend_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';
import 'record_screen.dart';
import 'team_main_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalkLogService _walkLogService = WalkLogService();
  final RankingService _rankingService = RankingService();

  int _todaySteps = WalkLogService.currentTodaySteps;
  int _targetSteps = WalkLogService.currentTargetSteps;
  String _userDistrict = WalkLogService.currentUserDistrict;
  String _userName = WalkLogService.currentUserName;
  late List<WardRanking> _topWards;
  bool _isLoadingRanking = false;

  @override
  void initState() {
    super.initState();
    _topWards = _buildFallbackTopWards();
    _refreshHomeData();
  }

  /// `dummy_data.dart` の初期ランキングから上位3区のフォールバックデータを生成
  List<WardRanking> _buildFallbackTopWards() {
    final list = <WardRanking>[];
    for (var i = 0; i < initialDistrictRankings.length && i < 3; i++) {
      final item = initialDistrictRankings[i] as Map<String, dynamic>;
      list.add(
        WardRanking(
          rank: i + 1,
          district: item['district'] as String,
          achievementRate: (item['achievementRate'] as num).toDouble(),
          totalSteps: (item['totalSteps'] as num).toInt(),
          totalDistanceKm: (item['totalDistanceKm'] as num).toDouble(),
          participantCount: 10,
        ),
      );
    }
    return list;
  }

  /// 本日の歩数・ユーザープロフィール・上位3区ランキングをリアルタイムに取得・更新
  Future<void> _refreshHomeData() async {
    setState(() {
      _todaySteps = WalkLogService.currentTodaySteps;
      _targetSteps = WalkLogService.currentTargetSteps;
      _userDistrict = WalkLogService.currentUserDistrict;
      _userName = WalkLogService.currentUserName;
      _isLoadingRanking = true;
    });

    // 1. プロフィール情報（所属区・目標歩数・名前）と本日の歩数をFirestoreから取得
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? _walkLogService.currentUserId;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 2));

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = (data['name'] ?? data['displayName']) as String?;
        final district = data['district'] as String?;
        final target = (data['targetSteps'] as num?)?.toInt();
        final todayStepsInUser = (data['todaySteps'] as num?)?.toInt();

        if (mounted) {
          setState(() {
            if (name != null && name.isNotEmpty) _userName = name;
            if (district != null && district.isNotEmpty) _userDistrict = district;
            if (target != null && target > 0) _targetSteps = target;
            if (todayStepsInUser != null && todayStepsInUser > _todaySteps) {
              _todaySteps = todayStepsInUser;
              WalkLogService.currentTodaySteps = todayStepsInUser;
            }
          });
        }
      }

      final todayStr = _walkLogService.getTodayDateString();
      final logDoc = await FirebaseFirestore.instance
          .collection('walkLogs')
          .doc('${uid}_$todayStr')
          .get()
          .timeout(const Duration(seconds: 2));

      if (logDoc.exists && logDoc.data() != null) {
        final steps = (logDoc.data()!['steps'] as num?)?.toInt() ?? 0;
        if (mounted && steps > _todaySteps) {
          setState(() {
            _todaySteps = steps;
            WalkLogService.currentTodaySteps = steps;
          });
        }
      }
    } catch (_) {
      // エミュレータ未接続時はローカルキャッシュ値をそのまま利用
    }

    // 2. 23区ランキング上位3区を取得（データが空または未接続時は初期シードデータを表示）
    try {
      final now = DateTime.now();
      final rankings = await _rankingService
          .getWardRankings(startDate: now, endDate: now)
          .timeout(const Duration(seconds: 2));

      final hasRealSteps = rankings.any((r) => r.totalSteps > 0);
      if (mounted) {
        setState(() {
          _topWards = hasRealSteps
              ? rankings.take(3).toList()
              : _buildFallbackTopWards();
          _isLoadingRanking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _topWards = _buildFallbackTopWards();
          _isLoadingRanking = false;
        });
      }
    }
  }

  /// 各画面へ遷移し、戻ってきたときにホーム画面の表示を最新状態に更新する
  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (!mounted) return;
    _refreshHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = WalkLog.calculateDistanceKm(_todaySteps);
    final progress = (_todaySteps / _targetSteps).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. 上部ヘッダー（プロフボタン ＋ 所属区バッジ）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateAndRefresh(const ProfileScreen()),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'プロフ設定',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _userName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '所属: $_userDistrict',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. 中央のエリア（チームボタン + 23区対抗表彰台 トップ3）
                Container(
                  width: double.infinity,
                  height: 175,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // チームボタン
                      InkWell(
                        onTap: () =>
                            _navigateAndRefresh(const TeamMainNavigation()),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 1.5),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups, size: 34, color: Colors.green),
                              SizedBox(height: 4),
                              Text(
                                'チーム',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 表彰台（上位3区）
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _navigateAndRefresh(const RankingScreen()),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '23区対抗 トップ3',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (_isLoadingRanking) ...[
                                    const SizedBox(width: 6),
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (_topWards.length > 1)
                                      _buildPodiumBlock(
                                        _topWards[1].district,
                                        _topWards[1].rank,
                                        _topWards[1].achievementRate,
                                        68,
                                      ),
                                    if (_topWards.isNotEmpty)
                                      _buildPodiumBlock(
                                        _topWards[0].district,
                                        _topWards[0].rank,
                                        _topWards[0].achievementRate,
                                        94,
                                      ),
                                    if (_topWards.length > 2)
                                      _buildPodiumBlock(
                                        _topWards[2].district,
                                        _topWards[2].rank,
                                        _topWards[2].achievementRate,
                                        52,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. 本日の歩数・目標達成リアルタイムゲージカード（Issue #23）
                GestureDetector(
                  onTap: () => _navigateAndRefresh(const ExerciseScreen()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  color: AppTheme.primaryColor,
                                  size: 26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '今日の歩数: $_todaySteps 歩',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$distanceKm km ($progressPercent%)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 14,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _todaySteps >= _targetSteps
                              ? '🎉 本日の目標（$_targetSteps歩）を達成！$_userDistrictに貢献中です！'
                              : '目標 $_targetSteps歩 まであと ${_targetSteps - _todaySteps} 歩（タップして歩数計測へ）',
                          style: TextStyle(
                            fontSize: 14,
                            color: _todaySteps >= _targetSteps
                                ? AppTheme.primaryColor
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. 2x2 メニューボタン
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: [
                    _buildMenuButton(
                      context,
                      label: '運動',
                      icon: Icons.directions_run,
                      onTap: () => _navigateAndRefresh(const ExerciseScreen()),
                    ),
                    _buildMenuButton(
                      context,
                      label: '記録',
                      icon: Icons.edit_note,
                      onTap: () => _navigateAndRefresh(const RecordScreen()),
                    ),
                    _buildMenuButton(
                      context,
                      label: 'ランキング',
                      icon: Icons.emoji_events,
                      onTap: () => _navigateAndRefresh(const RankingScreen()),
                    ),
                    _buildMenuButton(
                      context,
                      label: 'フレンド',
                      icon: Icons.people,
                      onTap: () => _navigateAndRefresh(const FriendScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumBlock(
    String district,
    int rank,
    double achievementRate,
    double height,
  ) {
    final color = rank == 1
        ? Colors.amber.shade300
        : rank == 2
        ? Colors.grey.shade300
        : Colors.brown.shade200;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          district,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          '${achievementRate.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 56,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '$rank位',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Icon(icon, size: 28),
        ],
      ),
    );
  }
}
