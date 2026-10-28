import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ランキング')),
      body: const Center(child: Text('ランキング画面（準備中）', style: TextStyle(fontSize: 18))),
    );
  }
}