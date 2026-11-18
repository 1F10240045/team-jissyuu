import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/dummy_data.dart';

class SeedService {
  static Future<void> seedInitialData() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. 東京都23区のランキングデータを 'district_rankings' コレクションへ一括セット
    for (final rawItem in initialDistrictRankings) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final docRef = firestore.collection('district_rankings').doc(item['district'].toString());
      batch.set(docRef, {
        ...item,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. 年代別平均歩数データを 'age_group_stats' コレクションへ一括セット
    averageStepsByAgeGroup.forEach((ageGroup, avgSteps) {
      final docRef = firestore.collection('age_group_stats').doc(ageGroup);
      batch.set(docRef, {
        'ageGroup': ageGroup,
        'averageSteps': avgSteps,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // 3. サンプルシニアユーザーを 'users' コレクションへ一括セット
    for (final rawUser in sampleSeniorUsers) {
      final user = Map<String, dynamic>.from(rawUser as Map);
      final docRef = firestore.collection('users').doc(user['userId'].toString());
      batch.set(docRef, {
        'name': user['name'],
        'district': user['district'],
        'ageGroup': user['ageGroup'],
        'targetSteps': user['targetSteps'],
        'todaySteps': user['todaySteps'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // バッチ処理を一括コミット
    await batch.commit();
  }
}