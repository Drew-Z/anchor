abstract final class AppMetadata {
  static const String productName = 'Anchor Learning';
  static const String localizedProductName = '锚学';
  static const String releaseChannel = 'Private Alpha';
  static const String version = String.fromEnvironment(
    'ANCHOR_LEARNING_APP_VERSION',
    defaultValue: '1.0.0+2005',
  );
}
