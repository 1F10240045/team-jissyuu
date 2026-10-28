import 'package:flutter/material.dart';

class FriendScreen extends StatelessWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('フレンド')),
      body: const Center(child: Text('フレンド画面（準備中）', style: TextStyle(fontSize: 18))),
    );
  }
}