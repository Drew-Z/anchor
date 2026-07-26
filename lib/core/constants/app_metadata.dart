abstract final class AppMetadata {
  static const String productName = '多多学';
  static const String releaseChannel = 'Private Alpha';
  static const String version = String.fromEnvironment(
    'DUODUO_APP_VERSION',
    defaultValue: '1.0.0+1',
  );
}
