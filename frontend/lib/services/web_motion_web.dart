import 'dart:js_interop';

@JS('requestWebMotionPermission')
external JSPromise<JSString> _requestWebMotionPermission();

@JS('getWebStepCount')
external JSNumber _getWebStepCount();

@JS('getWebGpsDistanceMeters')
external JSNumber _getWebGpsDistanceMeters();

/// Web環境（iPhone Safari / LINE内ブラウザ / Android Chrome）用の実装
Future<String> requestMotionPermissionImpl() async {
  try {
    final result = await _requestWebMotionPermission().toDart;
    return result.toDart;
  } catch (e) {
    return 'error:$e';
  }
}

int getWebMotionStepCountImpl() {
  try {
    return _getWebStepCount().toDartInt;
  } catch (_) {
    return 0;
  }
}

double getWebGpsDistanceMetersImpl() {
  try {
    return _getWebGpsDistanceMeters().toDartDouble;
  } catch (_) {
    return 0.0;
  }
}
