import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<String> getOrSignInUserId() async {
    try {
      // エミュレータまたは実環境のFirebase Authで匿名ログイン
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      return userCredential.user?.uid ?? 'fallback_user_id';
    } catch (e) {
      // エミュレータが未起動の場合や接続エラー時はフォールバックIDを使用
      print('Firebase Auth接続エラー（フォールバックIDを使用）: $e');
      return 'fallback_user_id';
    }
  }
}
