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

  /// スライド4枚目「④ 損失回避と利他性をトリガーとする適応型ナッジ」メッセージ生成
  /// スマホ画面幅で単語の途中で汚く折り返されないよう改行位置と文言を最適化
  Map<String, dynamic> _getCurrentNudge() {
    final remaining = (_targetSteps - _todaySteps).clamp(0, _targetSteps);
    final nudges = <Map<String, dynamic>>[
      {
        'tag': '損失回避ナッジ',
        'icon': Icons.trending_up,
        'color': Colors.deepOrange,
        'bgColor': Colors.orange.shade50,
        'text': _todaySteps >= _targetSteps
            ? '🔥 $_userDistrictの達成率が急上昇中！\nもう500歩でさらに上位に迫れます！'
            : '⚠️ 目標まであと $remaining 歩！\n他の区に順位を抜かれないよう歩きましょう！',
      },
      {
        'tag': '利他性・連帯ナッジ',
        'icon': Icons.volunteer_activism,
        'color': Colors.teal.shade700,
        'bgColor': Colors.teal.shade50,
        'text': '🤝 同じ$_userDistrictの仲間も歩いています！\nあなたの1歩が地域の順位アップに繋がります！',
      },
      {
        'tag': '同年代比較ナッジ',
        'icon': Icons.emoji_emotions,
        'color': Colors.blue.shade700,
        'bgColor': Colors.blue.shade50,
        'text':
            '👏 同年代（${WalkLogService.currentUserAgeGroup}）の仲間と一緒に、\n無理のないペースで健康寿命を延ばしましょう！',
      },
    ];
    return nudges[_nudgeIndex % nudges.length];
  }

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
    } catch (_) {
      // エミュレータ未接続時はローカルキャッシュ値をそのまま利用
    }

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
            padding: const EdgeInsets.all(14.0),
            child: Column(
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
                              size: 44,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
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
                    // ★ シニア向け：文字サイズワンタップ切り替えボタン
                    InkWell(
                      onTap: () {
                        setState(() {
                          MyApp.cycleFontScale();
                        });
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(18),
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
                              size: 18,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '文字:${MyApp.fontScaleLabel}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 所属区バッジ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _userDistrict,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 1.5 行動経済学ナッジ応援バナー（タップで切替・中途半端な改行を防止）
                Builder(
                  builder: (context) {
                    final nudge = _getCurrentNudge();
                    final Color accent = nudge['color'] as Color;
                    final Color bg = nudge['bgColor'] as Color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _nudgeIndex = (_nudgeIndex + 1) % 3;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  nudge['icon'] as IconData,
                                  color: accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '本日の応援（${nudge['tag']}）',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '切替 ↻',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              nudge['text'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 2. 中央のエリア（チームボタン + 23区対抗表彰台 トップ3）
                // 固定高さを廃止し、文字サイズを特大にしても絶対にOverflowしない構造
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
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
                            vertical: 16,
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

                      const SizedBox(width: 10),

                      // 表彰台（上位3区）
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _navigateAndRefresh(const RankingScreen()),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  const Flexible(
                                    child: Text(
                                      '23区対抗 トップ3',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
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
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_topWards.length > 1)
                                    Expanded(
                                      child: _buildPodiumBlock(
                                        _topWards[1].district,
                                        _topWards[1].rank,
                                        _topWards[1].achievementRate,
                                        62,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  if (_topWards.isNotEmpty)
                                    Expanded(
                                      child: _buildPodiumBlock(
                                        _topWards[0].district,
                                        _topWards[0].rank,
                                        _topWards[0].achievementRate,
                                        84,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  if (_topWards.length > 2)
                                    Expanded(
                                      child: _buildPodiumBlock(
                                        _topWards[2].district,
                                        _topWards[2].rank,
                                        _topWards[2].achievementRate,
                                        48,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. 本日の歩数・目標達成リアルタイムゲージカード（1行に綺麗に収まる文言）
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
                            Flexible(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.directions_walk,
                                    color: AppTheme.primaryColor,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '今日の歩数: $_todaySteps 歩',
                                      style: const TextStyle(
                                        fontSize: 19,
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
                                fontSize: 15,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _todaySteps >= _targetSteps
                                    ? '🎉 本日の目標（$_targetSteps歩）を達成！'
                                    : '目標 $_targetSteps歩 まであと ${_targetSteps - _todaySteps} 歩',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _todaySteps >= _targetSteps
                                      ? AppTheme.primaryColor
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '計測画面へ ＞',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 4. 2x2 メニューボタン（文字が大きく見やすいデザイン）
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.1,
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
      mainAxisSize: MainAxisSize.min,
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 28, color: AppTheme.primaryColor),
        ],
      ),
    );
  }
}
