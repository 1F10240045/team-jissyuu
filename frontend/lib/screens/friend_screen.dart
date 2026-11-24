import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/walk_log_service.dart';
import 'team_main_navigation.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  // 画面を閉じて開き直しても追加したフレンドや応援状態が保持されるように static キャッシュ化
  static final List<Map<String, dynamic>> _sharedFriendsList = [
    {
      'id': 'user_001',
      'name': 'すずき はなこ',
      'district': '世田谷区',
      'steps': 7400,
      'isOnline': true,
      'cheered': false,
      'lastMessage': '',
    },
    {
      'id': 'user_002',
      'name': 'たなか さとる',
      'district': '練馬区',
      'steps': 8200,
      'isOnline': false,
      'cheered': false,
      'lastMessage': '',
    },
    {
      'id': 'user_003',
      'name': 'やまだ いちろう',
      'district': '大田区',
      'steps': 4900,
      'isOnline': true,
      'cheered': false,
      'lastMessage': '',
    },
  ];

  // フレンド追加ダイアログ
  void _showAddFriendDialog() {
    final TextEditingController searchController = TextEditingController();
    String selectedDistrict = WalkLogService.currentUserDistrict;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'フレンドを追加する',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'お友達の名前またはユーザーIDを入力してください。',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'お名前 / ユーザーID',
                  hintText: '例: さとう けんいち',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_search),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final query = searchController.text.trim();
                Navigator.pop(dialogContext);
                if (query.isEmpty) return;

                final newFriend = <String, dynamic>{
                  'id': 'friend_${DateTime.now().millisecondsSinceEpoch}',
                  'name': query,
                  'district': selectedDistrict,
                  'steps': 5400,
                  'isOnline': true,
                  'cheered': false,
                  'lastMessage': '',
                };

                setState(() {
                  _sharedFriendsList.insert(0, newFriend);
                });

                // Firestore への保存も非同期で試みる（エミュレータ未起動時も画面には即時反映）
                try {
                  await FirebaseFirestore.instance
                      .collection('friends')
                      .doc(newFriend['id'] as String)
                      .set({
                        ...newFriend,
                        'createdAt': FieldValue.serverTimestamp(),
                      })
                      .timeout(const Duration(seconds: 2));
                } catch (_) {}

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '「$query」さんをフレンドリストに追加しました！',
                        style: const TextStyle(fontSize: 16),
                      ),
                      backgroundColor: Colors.teal.shade800,
                    ),
                  );
                }
              },
              child: const Text('追加する', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  // 応援スタンプ・メッセージ送信ダイアログ（スライド10枚目のメッセージ機能）
  void _showCheerMessageDialog(int index) {
    final friend = _sharedFriendsList[index];
    final friendName = friend['name'].toString();
    final TextEditingController customMsgController = TextEditingController();

    final presetMessages = [
      '👏 今日もいいペースですね！ナイスファイト！',
      '🚶 一緒に目標達成して地域を盛り上げましょう！',
      '🍵 無理せず水分補給しながら歩きましょうね！',
    ];

    void sendCheer(String message) {
      setState(() {
        _sharedFriendsList[index]['cheered'] = true;
        _sharedFriendsList[index]['lastMessage'] = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$friendNameさんに「$message」と送りました！',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.teal.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '$friendNameさんへ応援・メッセージ',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ワンタップで送れる応援メッセージ：',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ...presetMessages.map(
                  (msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        alignment: Alignment.centerLeft,
                        side: BorderSide(color: Colors.teal.shade400),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        sendCheer(msg);
                      },
                      child: Text(
                        msg,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 20),
                TextField(
                  controller: customMsgController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: '自由メッセージを入力',
                    hintText: '例: 明日は公園を歩きましょう！',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('閉じる', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('送信', style: TextStyle(fontSize: 16)),
              onPressed: () {
                final text = customMsgController.text.trim().isEmpty
                    ? presetMessages[0]
                    : customMsgController.text.trim();
                Navigator.pop(dialogContext);
                sendCheer(text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'フレンド一覧',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.groups, size: 28),
            tooltip: 'チーム一覧を見る',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TeamMainNavigation(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add, size: 28),
            tooltip: 'フレンド追加',
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt, color: Colors.teal.shade800, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'お友達とお互いの歩数を応援し合いましょう！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.groups),
                  label: const Text(
                    '地域のチーム一覧・作成はこちら',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade800,
                    side: BorderSide(color: Colors.teal.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TeamMainNavigation(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _sharedFriendsList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _sharedFriendsList.length,
                      itemBuilder: (context, index) {
                        return _buildFriendCard(index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add, size: 28),
        label: const Text(
          '友達を追加',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFriendCard(int index) {
    final friend = _sharedFriendsList[index];
    final bool cheered = friend['cheered'] == true;
    final String lastMessage = (friend['lastMessage'] ?? '').toString();
    final String district = (friend['district'] ?? '世田谷区').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              friend['name'].toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              district,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 18,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '本日 ${friend['steps']} 歩',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // スライド10枚目の「メッセージ💬 / 応援」ボタン
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cheered
                        ? Colors.orange.shade600
                        : Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(
                    cheered ? Icons.check_circle : Icons.chat_bubble_outline,
                    size: 18,
                  ),
                  label: Text(
                    cheered ? '応援済' : 'メッセージ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _showCheerMessageDialog(index),
                ),
              ],
            ),
            if (lastMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  '送信済み: 「$lastMessage」',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'まだフレンドが登録されていません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
