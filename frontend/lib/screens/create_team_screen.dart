import 'package:flutter/material.dart';

import '../services/ranking_service.dart';
import '../services/walk_log_service.dart';
import '../theme/app_theme.dart';

class CreateTeamScreen extends StatefulWidget {
  final Function(String name, String district, String description) onSubmit;

  const CreateTeamScreen({super.key, required this.onSubmit});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedDistrict;

  @override
  void initState() {
    super.initState();
    // 初期値は現在自分の所属している区（必ず東京都23区内になるように制御）
    _selectedDistrict =
        tokyo23Wards.contains(WalkLogService.currentUserDistrict)
        ? WalkLogService.currentUserDistrict
        : '渋谷区';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final cleanName = _nameController.text.trim();
      final cleanDesc = _descriptionController.text.trim().isEmpty
          ? '$_selectedDistrictを中心にみんなで楽しく歩くチームです！'
          : _descriptionController.text.trim();

      widget.onSubmit(cleanName, _selectedDistrict, cleanDesc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新しいチームを作成')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'チーム名 *（20文字以内）',
                  hintText: '例: 渋谷シニアウォーカーズ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) {
                    return 'チーム名を入力してください';
                  }
                  if (v.length < 2) {
                    return 'チーム名は2文字以上で入力してください';
                  }
                  final duplicate = WalkLogService.sharedTeamsList.any(
                    (t) => t.name.trim().toLowerCase() == v.toLowerCase(),
                  );
                  if (duplicate) {
                    return '⚠️ 同じ名前のチームがすでに存在します';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // ★ 自由入力で存在しない地域が入らないよう東京都23区のドロップダウンに限定
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                  labelText: '活動する区（東京都23区） *',
                  border: OutlineInputBorder(),
                ),
                items: tokyo23Wards.map((ward) {
                  return DropdownMenuItem(value: ward, child: Text(ward));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'チームの紹介・説明（任意）',
                  hintText: '例: 毎朝公園の周りを楽しく歩いています！どなたでも歓迎です。',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.group_add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: const Text(
                  'チームを作成して参加する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
