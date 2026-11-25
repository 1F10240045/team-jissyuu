import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/walk_log.dart';
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

  final String _accountId = WalkLogService.currentAccountId;
  String? _selectedDistrict;
  String? _selectedAgeGroup;
  int _selectedTargetSteps = 8000;
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
  }

  double? _parseOptionalHeight() {
    final text = _heightController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 100 || parsed > 220) return null;
    return parsed;
  }

  /// 身長の入力エラーメッセージ（空欄または100〜220cmなら null）
  String? _getHeightValidationError() {
    final text = _heightController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return '⚠️ 数字（半角）で入力してください（または空欄）';
    }
    if (parsed < 100 || parsed > 220) {
      return '⚠️ 100〜220 cm の範囲で入力してください（または空欄）';
    }
    return null;
  }

  /// 入力や選択が変わるたびに、ボタン不要でスマホ本体（localStorage）へ即座に自動保存
  void _autoSaveLocal() {
    final newName = _nameController.text.trim().isEmpty
        ? 'ゲスト'
        : _nameController.text.trim();
    WalkLogService.currentUserName = newName;
    WalkLogService.currentUserDistrict = _selectedDistrict ?? '渋谷区';
    WalkLogService.currentUserAgeGroup = _selectedAgeGroup ?? '70代';
    WalkLogService.currentTargetSteps = _selectedTargetSteps;
    WalkLogService.currentUserHeightCm = _parseOptionalHeight();
    WalkLogService.persistToLocalStorage();
  }

  Future<void> _saveProfile({bool showToast = true}) async {
    _autoSaveLocal();

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
            'name': WalkLogService.currentUserName,
            'displayName': WalkLogService.currentUserName,
            'district': WalkLogService.currentUserDistrict,
            'ageGroup': WalkLogService.currentUserAgeGroup,
            'targetSteps': WalkLogService.currentTargetSteps,
            'heightCm': WalkLogService.currentUserHeightCm,
            'todaySteps': WalkLogService.currentTodaySteps,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 1));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ スマホ本体に設定を自動保存しました！'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. このスマホ専用のフレンドID表示（ログイン不要で自動発行・自動記憶）
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
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🪪 このスマホの専用フレンドID（自動保存中）',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _accountId,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _accountId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('フレンドID「$_accountId」をコピーしました'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text(
                      'IDコピー',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 名前入力欄（入力するだけで自動保存・最大12文字制限）
            const Text(
              '名前（ニックネーム・12文字以内）',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: 12,
              onChanged: (_) => _autoSaveLocal(),
              decoration: const InputDecoration(
                hintText: '例: たろう（入力すると自動で保存されます）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),

            // 所属区選択 (選ぶだけで自動保存)
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
                _autoSaveLocal();
              },
            ),
            const SizedBox(height: 18),

            // 年代選択 (選ぶだけで自動保存)
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
                    if (selected) {
                      setState(() {
                        _selectedAgeGroup = age;
                      });
                      _autoSaveLocal();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // 身長（任意入力・空欄でもOK・100〜220cmバリデーション付き）
            const Text(
              '身長（任意・空欄でもOK）',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                setState(() {});
                _autoSaveLocal();
              },
              decoration: InputDecoration(
                hintText: '未入力時は年代平均から歩幅を自動計算（例: 160）',
                suffixText: 'cm',
                counterText: '',
                errorText: _getHeightValidationError(),
                border: const OutlineInputBorder(),
                suffixIcon: _heightController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: '空欄に戻す',
                        onPressed: () {
                          setState(() {
                            _heightController.clear();
                          });
                          _autoSaveLocal();
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
                          ? '推定歩幅: 約 $previewStrideCm cm（${_selectedAgeGroup ?? '70代'} × 身長${previewHeight.toInt()}cm）'
                          : '推定歩幅: 約 $previewStrideCm cm（${_selectedAgeGroup ?? '70代'}の標準歩幅を自動適用）',
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
            const SizedBox(height: 18),

            // 1日の目標歩数 (選ぶだけで自動保存)
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
                      _autoSaveLocal();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        await _saveProfile(showToast: true);
                      },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving ? '保存中...' : '設定を保存する（変更時に自動保存済み）',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}