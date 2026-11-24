import 'web_motion_stub.dart'
    if (dart.library.js_interop) 'web_motion_web.dart';

class WebMotionHelper {
  /// iPhone Safari / Web ブラウザのモーションセンサー権限をリクエストする
  static Future<String> requestPermission() => requestMotionPermissionImpl();

  /// Webモーションセンサーで検知した累計歩数を取得する
  static int getStepCount() => getWebMotionStepCountImpl();
}
