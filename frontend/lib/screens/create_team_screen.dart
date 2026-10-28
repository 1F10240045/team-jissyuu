// lib/screens/create_team_screen.dart
import 'package:flutter/material.dart';

class CreateTeamScreen extends StatefulWidget {
  final Function(String name, String district, String description) onSubmit;

  const CreateTeamScreen({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _districtController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameController.text,
        _districtController.text,
        _descriptionController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チーム作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'チーム名 *',
                  hintText: '例: 渋谷ウォーカーズ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'チーム名を入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: '地区・地域名 *',
                  hintText: '例: 渋谷区',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? '地区・地域名を入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '説明',
                  hintText: 'チームの活動内容や雰囲気を入力',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('作成する', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}