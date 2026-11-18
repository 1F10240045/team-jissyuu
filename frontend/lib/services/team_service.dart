import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/dummy_data.dart';
import '../models/team.dart';

class TeamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teamsRef =>
      _db.collection('teams');

  Future<List<Team>> fetchTeams() async {
    final snapshot = await _teamsRef.orderBy('createdAt', descending: true).get();

    if (snapshot.docs.isEmpty) {
      return List<Team>.from(initialTeams);
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Team(
        teamId: doc.id,
        name: data['name'] ?? '',
        district: data['district'] ?? '',
        description: data['description'] ?? '',
        managerUserId: data['managerUserId'] ?? dummyUserId,
        memberCount: data['memberCount'] ?? 0,
        totalSteps: data['totalSteps'] ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> createTeam({
    required String name,
    required String district,
    required String description,
  }) async {
    final teamId = 'team_${DateTime.now().millisecondsSinceEpoch}';

    await _teamsRef.doc(teamId).set({
      'teamId': teamId,
      'name': name,
      'district': district,
      'description': description,
      'managerUserId': dummyUserId,
      'memberCount': 1,
      'totalSteps': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinTeam({
    required String teamId,
    required String userId,
  }) async {
    final teamRef = _teamsRef.doc(teamId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(teamRef);
      if (!snapshot.exists) {
        throw Exception('チームが存在しません');
      }

      final data = snapshot.data()!;
      final currentCount = (data['memberCount'] ?? 0) as int;

      transaction.update(teamRef, {
        'memberCount': currentCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userRef = _db.collection('users').doc(userId);
      final userSnapshot = await transaction.get(userRef);

      if (userSnapshot.exists) {
        transaction.update(userRef, {
          'teamId': teamId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(userRef, {
          'userId': userId,
          'teamId': teamId,
          'displayName': 'テストユーザー',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}