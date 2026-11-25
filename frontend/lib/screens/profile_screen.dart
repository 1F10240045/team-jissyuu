import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _accountId = WalkLogService.currentAccountId;
  String? _selectedDistrict;
  String? _selectedAgeGroup;
  int _selectedTargetSteps = 8000;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _syncFieldsFromActiveAccount();
    _initializeAndLoadData();
  }

  void _syncFieldsFromActiveAccount() {
    _accountId = WalkLogService.currentAccountId;
    _nameController.text = WalkLogService.currentUserName;
    if (WalkLogService.currentUserHeightCm != null) {
      _heightController.text =
          WalkLogService.currentUserHeightCm!.toStringAsFixed(0);
    } else {
      _heightController.clear();
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
  }

  Future<void> _initializeAndLoadData() async {
    try {
      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(milliseconds: 1000));
    } catch (_) {}

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_accountId)
          .get()
          .timeout(const Duration(milliseconds: 1000));

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
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double? _parseOptionalHeight() {
    final text = _heightController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 100 || parsed > 220) return null;
    return parsed;
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim().isEmpty
        ? 'テストユーザー'
        : _nameController.text.trim();
    final newDistrict = _selectedDistrict ?? '渋谷区';
    final newAge = _selectedAgeGroup ?? '70代';
    final newTarget = _selectedTargetSteps;
    final newHeight = _parseOptionalHeight();

    WalkLogService.currentAccountId = _accountId;
    WalkLogService.currentUserName = newName;
    WalkLogService.currentUserDistrict = newDistrict;
    WalkLogService.currentUserAgeGroup = newAge;
    WalkLogService.currentTargetSteps = newTarget;
    WalkLogService.currentUserHeightCm = newHeight;

    // 実在アカウント台帳にも登録・更新（フレンド検索で見つかるようにする）
    WalkLogService.upsertRegisteredAccount({
      'accountId': _accountId,
      'name': newName,
      'district': newDistrict,
      'ageGroup': newAge,
      'targetSteps': newTarget,
      'heightCm': newHeight,
      'steps': WalkLogService.currentTodaySteps,
    });

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_accountId)
          .set({
            'userId': _accountId,
            'accountId': _accountId,
            'name': newName,
            'displayName': newName,
            'district': newDistrict,
            'ageGroup': newAge,
            'targetSteps': newTarget,
            'heightCm': newHeight,
            'todaySteps': WalkLogService.currentTodaySteps,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('アカウント（ID: $_accountId / $newName）を保存しました！'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 別アカウントへのログイン切替 または 新規アカウント発行ダイアログ
  void _showAccountSwitchOrCreateDialog() {
    final TextEditingController loginIdController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'ログイン / 新規アカウント作成',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '① 既存のアカウントでログイン',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: loginIdController,
                      decoration: InputDecoration(
                        labelText: 'アカウントID または 登録名',
                        hintText: '例: sato-0001 または 佐藤 健一',
                        border: const OutlineInputBorder(),
                        errorText: errorText,
                        prefixIcon: const Icon(Icons.login),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'このアカウントでログイン',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final q = loginIdController.text.trim();
                        if (q.isEmpty) {
                          setDialogState(() {
                            errorText = 'アカウントIDまたは名前を入力してください';
                          });
                          return;
                        }
                        final found =
                            await WalkLogService.findRegisteredAccount(q);
                        if (found == null) {
                          setDialogState(() {
                            errorText =
                                '❌ 該当する登録済みアカウントが見つかりません';
                          });
                          return;
                        }

                        WalkLogService.switchActiveAccount(found);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        setState(() {
                          _syncFieldsFromActiveAccount();
                        });
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '「${found['name']}（ID: ${found['accountId']}）」でログインしました！',
                            ),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 28),
                    const Text(
                      '② 新しいアカウントを作成する',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '新しい専用アカウントIDを自動発行して初期状態から始めます。',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text(
                        '新規アカウントIDを発行する',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final randCode = 1000 + Random().nextInt(9000);
                        final newId = 'walk-$randCode';
                        final newAcc = <String, dynamic>{
                          'accountId': newId,
                          'name': '新規ユーザー($randCode)',
                          'district': '渋谷区',
                          'ageGroup': '70代',
                          'targetSteps': 8000,
                          'heightCm': null,
                          'steps': 0,
                        };
                        WalkLogService.upsertRegisteredAccount(newAcc);
                        WalkLogService.switchActiveAccount(newAcc);
                        Navigator.pop(dialogContext);
                        setState(() {
                          _syncFieldsFromActiveAccount();
                        });
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '新規アカウント（ID: $newId）を作成しました！名前や所属区を設定して保存してください。',
                            ),
                            backgroundColor: Colors.blue.shade700,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
      },
    );
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
      appBar: AppBar(title: const Text('プロフィール・アカウント設定')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ★ 0. アカウントIDカード（フレンド追加用ID表示 ＆ ログイン切替ボタン）
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primaryColor,
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
                            const Text(
                              '🪪 あなたのフレンドID（お友達追加用）',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: _accountId),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'フレンドID「$_accountId」をコピーしました',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'IDをコピー',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _accountId,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showAccountSwitchOrCreateDialog,
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text(
                                'ログイン切替 / 新規作成',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  // 身長（任意入力・空欄でもOK）
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
                          : const Text(
                              'この内容でアカウント情報を保存する',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
