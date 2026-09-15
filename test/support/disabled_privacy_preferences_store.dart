import 'package:anchor_learning/services/privacy/privacy_preferences.dart';

class DisabledPrivacyPreferencesStore implements PrivacyPreferencesStore {
  const DisabledPrivacyPreferencesStore();

  @override
  Future<PrivacyPreferences> read() async {
    return const PrivacyPreferences(localProductEventsEnabled: false);
  }

  @override
  Future<String> readOrCreateAnonymousInstallId() async => 'disabled';

  @override
  Future<void> resetAnonymousInstallId() async {}

  @override
  Future<void> write(PrivacyPreferences preferences) async {}
}
