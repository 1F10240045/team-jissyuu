import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

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
    _initializeAndLoadData();
  }

  // 1. 匿名ログイン & 既存プロフィールの読み込み
  Future<void> _initializeAndLoadData() async {
    try {
      // 匿名ログインを実行（エラー時はフォールバックIDを使用）
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
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
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = (data['name'] ?? data['displayName'] ?? '')
                .toString();
            _selectedDistrict = _districts.contains(data['district'])
                ? data['district']
                : null;
            _selectedAgeGroup = _ageGroups.contains(data['ageGroup'])
                ? data['ageGroup']
                : null;
            if (data['targetSteps'] != null &&
                _stepGoals.contains(data['targetSteps'])) {
              _selectedTargetSteps = data['targetSteps'];
            }
          });
        }
      } catch (e) {
        debugPrint('Firestore読み込みエラー: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 2. Firestoreへの保存処理
  Future<void> _saveProfile() async {
    if (_userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'name': _nameController.text.trim(),
        'displayName': _nameController.text.trim(),
        'district': _selectedDistrict,
        'ageGroup': _selectedAgeGroup,
        'targetSteps': _selectedTargetSteps,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを保存しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Firestore保存エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 32),

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
                ],
              ),
            ),
    );
  }
}
