import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/dummy_data.dart';
import '../main.dart';
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
  int _nudgeIndex = 0;

  /// 1行にスリムに収まる応援ナッジメッセージ（タップで切替）
  String _getSlimNudgeText() {
    final remaining = (_targetSteps - _todaySteps).clamp(0, _targetSteps);
    final list = [
      _todaySteps >= _targetSteps
          ? '🔥 $_userDistrictの達成率が上昇中！さらに上位へ！'
          : '⚠️ 目標まであと$remaining歩！他区に抜かれないよう歩こう',
      '🤝 同じ$_userDistrictの仲間も歩行中！あなたの1歩が地域の力に',
      '👏 同年代（${WalkLogService.currentUserAgeGroup}）の仲間と無理なく健康寿命を延ばそう',
    ];
    return list[_nudgeIndex % list.length];
  }

  @override
  void initState() {
    super.initState();
    _topWards = _buildFallbackTopWards();
    _refreshHomeData();
  }

  List<WardRanking> _buildFallbackTopWards() {
    return WalkLogService.computeRealtimeWardRankings().take(3).toList();
  }

  Future<void> _refreshHomeData() async {
    setState(() {
      _todaySteps = WalkLogService.currentTodaySteps;
      _targetSteps = WalkLogService.currentTargetSteps;
      _userDistrict = WalkLogService.currentUserDistrict;
      _userName = WalkLogService.currentUserName;
      _topWards = _buildFallbackTopWards();
      _isLoadingRanking = true;
    });

    try {
      final uid =
          FirebaseAuth.instance.currentUser?.uid ?? _walkLogService.currentUserId;
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
            if (district != null && district.isNotEmpty) {
              _userDistrict = district;
            }
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
    } catch (_) {}

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 上部ヘッダー（プロフ設定 ＋ 文字サイズ切替ボタン ＋ 所属区バッジ）
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateAndRefresh(const ProfileScreen()),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'プロフ設定',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        MyApp.cycleFontScale();
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.shade700,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.text_fields,
                            size: 16,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '文字:${MyApp.fontScaleLabel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _userDistrict,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 2. 中央のエリア（チームボタン + 23区対抗表彰台 トップ3）
              // Expanded で残り高さに自動フィットするため絶対に画面からはみ出ない
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // チームボタン
                      InkWell(
                        onTap: () =>
                            _navigateAndRefresh(const TeamMainNavigation()),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
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
                              Icon(Icons.groups, size: 30, color: Colors.green),
                              SizedBox(height: 4),
                              Text(
                                'チーム',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 表彰台（上位3区）
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _navigateAndRefresh(const RankingScreen()),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availH = (constraints.maxHeight - 28).clamp(
                                60.0,
                                150.0,
                              );
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      const Flexible(
                                        child: Text(
                                          '23区対抗 トップ3',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (_isLoadingRanking) ...[
                                        const SizedBox(width: 6),
                                        const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (_topWards.length > 1)
                                          Expanded(
                                            child: _buildPodiumBlock(
                                              _topWards[1].district,
                                              _topWards[1].rank,
                                              _topWards[1].achievementRate,
                                              (availH * 0.44).clamp(28.0, 68.0),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        if (_topWards.isNotEmpty)
                                          Expanded(
                                            child: _buildPodiumBlock(
                                              _topWards[0].district,
                                              _topWards[0].rank,
                                              _topWards[0].achievementRate,
                                              (availH * 0.58).clamp(36.0, 88.0),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        if (_topWards.length > 2)
                                          Expanded(
                                            child: _buildPodiumBlock(
                                              _topWards[2].district,
                                              _topWards[2].rank,
                                              _topWards[2].achievementRate,
                                              (availH * 0.34).clamp(24.0, 52.0),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. 本日の歩数・目標達成ゲージ ＋ 1行スリム応援ナッジ（合体カード）
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateAndRefresh(const ExerciseScreen()),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_walk,
                                      color: AppTheme.primaryColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '今日の歩数: $_todaySteps 歩',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$distanceKm km ($progressPercent%)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 1行スリム応援ナッジ（タップでメッセージ切替）
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _nudgeIndex = (_nudgeIndex + 1) % 3;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getSlimNudgeText(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.autorenew,
                              size: 14,
                              color: Colors.orange.shade800,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 4. 2x2 メニューボタン（スクロールなしで1画面に4つすべて収まる）
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.35,
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
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          district,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '$rank位',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 26, color: AppTheme.primaryColor),
        ],
      ),
    );
  }
}
