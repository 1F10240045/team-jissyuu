import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class WalkLogService {
  // 歩数ストリームの取得
  Stream<StepCount> get stepCountStream => Pedometer.stepCountStream;

  // 権限リクエスト
  Future<bool> requestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    
    // iOSの場合は sensors も確認
    if (status.isDenied) {
      status = await Permission.sensors.request();
    }

    return status.isGranted;
  }
}