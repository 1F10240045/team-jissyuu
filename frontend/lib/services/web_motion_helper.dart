import 'web_motion_stub.dart'
    if (dart.library.js_interop) 'web_motion_web.dart';

class WebMotionHelper {
  /// iPhone Safari / Web ブラウザのモーションセンサー権限をリクエスト（同時に歩行中限定GPS監視も開始）
  static Future<String> requestPermission() => requestMotionPermissionImpl();

  /// Webモーションセンサーで検知した累計歩数を取得
  static int getStepCount() => getWebMotionStepCountImpl();

  /// 歩行中のみ加算されたGPS実測移動距離（メートル）を取得
  static double getGpsDistanceMeters() => getWebGpsDistanceMetersImpl();
}
