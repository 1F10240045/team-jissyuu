import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('運動')),
      body: const Center(child: Text('運動画面（準備中）', style: TextStyle(fontSize: 18))),
    );
  }
}
