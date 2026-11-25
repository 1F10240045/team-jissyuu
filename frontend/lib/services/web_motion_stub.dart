/// 非Web環境用のスタブ
final Map<String, String> _memoryStorage = {};

Future<String> requestMotionPermissionImpl() async => 'unsupported';

int getWebMotionStepCountImpl() => 0;

double getWebGpsDistanceMetersImpl() => 0.0;

void saveLocalDataImpl(String key, String value) {
  _memoryStorage[key] = value;
}

String loadLocalDataImpl(String key) {
  return _memoryStorage[key] ?? '';
}
