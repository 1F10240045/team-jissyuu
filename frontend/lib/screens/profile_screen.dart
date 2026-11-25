import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/walk_log.dart';
import '../services/seed_service.dart';
import '../services/walk_log_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // 東京都23区リスト
  final List<String> _districts = [
    '千代田区',
    '中央区',
    '港区',
    '新宿区',
    '文京区',
    '台東区',
    '墨田区',
    '江東区',
    '品川区',
    '目黒区',
    '大田区',
    '世田谷区',
    '渋谷区',
    '中野区',
    '杉並区',
    '豊島区',
    '北区',
    '荒川区',
    '板橋区',
    '練馬区',
    '足立区',
    '葛飾区',
    '江戸川区',
  ];

  // 年代リスト
  final List<String> _ageGroups = ['50代', '60代', '70代', '80代', '90代+'];

  // 目標歩数リスト
  final List<int> _stepGoals = [4000, 6000, 8000, 10000];

  String? _selectedDistrict;
  String? _selectedAgeGroup;
  int _selectedTargetSteps = 8000;

  String? _userId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = WalkLogService.currentUserName;
    if (WalkLogService.currentUserHeightCm != null) {
      _heightController.text =
          WalkLogService.currentUserHeightCm!.toStringAsFixed(0);
    }
    _selectedDistrict = _districts.contains(WalkLogService.currentUserDistrict)
        ? WalkLogService.currentUserDistrict
        : '渋谷区';
    _selectedAgeGroup = _ageGroups.contains(WalkLogService.currentUserAgeGroup)
        ? WalkLogService.currentUserAgeGroup
        : '70代';
    _selectedTargetSteps = _stepGoals.contains(WalkLogService.currentTargetSteps)
        ? WalkLogService.currentTargetSteps
        : 8000;

    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(milliseconds: 1200));
      _userId = userCredential.user?.uid;
    } catch (e) {
      debugPrint('Authエラー（フォールバックIDを使用）: $e');
      _userId = 'fallback_user_id';
    }

    if (_userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get()
            .timeout(const Duration(milliseconds: 1200));

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final name = (data['name'] ?? data['displayName'] ?? '').toString();
          final district = data['district'] as String?;
          final ageGroup = data['ageGroup'] as String?;
          final targetSteps = (data['targetSteps'] as num?)?.toInt();
          final heightCm = (data['heightCm'] as num?)?.toDouble();

          if (mounted) {
            setState(() {
              if (name.isNotEmpty) {
                _nameController.text = name;
                WalkLogService.currentUserName = name;
              }
              if (district != null && _districts.contains(district)) {
                _selectedDistrict = district;
                WalkLogService.currentUserDistrict = district;
              }
              if (ageGroup != null && _ageGroups.contains(ageGroup)) {
                _selectedAgeGroup = ageGroup;
                WalkLogService.currentUserAgeGroup = ageGroup;
              }
              if (targetSteps != null && _stepGoals.contains(targetSteps)) {
                _selectedTargetSteps = targetSteps;
                WalkLogService.currentTargetSteps = targetSteps;
              }
              if (heightCm != null && heightCm >= 100 && heightCm <= 220) {
                _heightController.text = heightCm.toStringAsFixed(0);
                WalkLogService.currentUserHeightCm = heightCm;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Firestore読み込みタイムアウト/エラー（ローカル設定を使用）: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 現在入力中の身長（空欄や範囲外の場合は null）
  double? _parseOptionalHeight() {
    final text = _heightController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 100 || parsed > 220) return null;
    return parsed;
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;

    final newName = _nameController.text.trim().isEmpty
        ? 'テストユーザー'
        : _nameController.text.trim();
    final newDistrict = _selectedDistrict ?? '渋谷区';
    final newAge = _selectedAgeGroup ?? '70代';
    final newTarget = _selectedTargetSteps;
    final newHeight = _parseOptionalHeight();

    // アプリ内の共通キャッシュを即座に更新（空欄の場合は null で年代別標準歩幅を使用）
    WalkLogService.currentUserName = newName;
    WalkLogService.currentUserDistrict = newDistrict;
    WalkLogService.currentUserAgeGroup = newAge;
    WalkLogService.currentTargetSteps = newTarget;
    WalkLogService.currentUserHeightCm = newHeight;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .set({
            'name': newName,
            'displayName': newName,
            'district': newDistrict,
            'ageGroup': newAge,
            'targetSteps': newTarget,
            'heightCm': newHeight,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを保存しました！'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore保存タイムアウト/ローカル保持: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを設定しました！（歩幅・目標をアプリ内に反映済み）'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = _parseOptionalHeight();
    final previewStrideCm = (WalkLog.calculateStrideMeters(
              ageGroup: _selectedAgeGroup ?? '70代',
              heightCm: previewHeight,
            ) *
            100)
        .round();

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール設定')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名前入力欄
                  const Text(
                    '名前（ニックネーム）',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '例: たろう',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 所属区選択 (Dropdown)
                  const Text(
                    '所属する区',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    hint: const Text('選択してください'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _districts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 年代選択 (ChoiceChip)
                  const Text(
                    '年代',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _ageGroups.map((age) {
                      final isSelected = _selectedAgeGroup == age;
                      return ChoiceChip(
                        label: Text(age),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedAgeGroup = selected ? age : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ★ 身長（任意入力・空欄でもOK）
                  const Text(
                    '身長（任意・空欄でもOK）',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '未入力時は年代平均から歩幅を自動計算（例: 160）',
                      suffixText: 'cm',
                      border: const OutlineInputBorder(),
                      suffixIcon: _heightController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: '空欄に戻す',
                              onPressed: () {
                                setState(() {
                                  _heightController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            previewHeight != null
                                ? 'あなたの推定歩幅: 約 $previewStrideCm cm（${_selectedAgeGroup ?? '70代'} × 身長${previewHeight.toInt()}cm）'
                                : 'あなたの推定歩幅: 約 $previewStrideCm cm（${_selectedAgeGroup ?? '70代'}の標準歩幅を自動適用）',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1日の目標歩数 (ChoiceChip)
                  const Text(
                    '1日の目標歩数',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _stepGoals.map((steps) {
                      final isSelected = _selectedTargetSteps == steps;
                      return ChoiceChip(
                        label: Text('$steps 歩'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTargetSteps = steps;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('保存する', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              try {
                                await SeedService.seedInitialData().timeout(
                                  const Duration(seconds: 3),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('初期データを投入しました'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '初期データを準備しました（エミュレータ未起動時は内蔵シードデータを使用）',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('初期データ投入（デモ用）'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
