/// 非Web環境（Android/iOSネイティブアプリ・デスクトップ）用のスタブ
Future<String> requestMotionPermissionImpl() async => 'unsupported';

int getWebMotionStepCountImpl() => 0;
