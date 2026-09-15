import 'package:anchor_learning/services/agent/search_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults model-assisted search to off and persists explicit opt-in',
      () async {
    final store = SharedPreferencesSearchPreferencesStore();

    expect((await store.read()).modelAssistedSearchEnabled, isFalse);
    await store.write(
      const SearchPreferences(modelAssistedSearchEnabled: true),
    );
    expect((await store.read()).modelAssistedSearchEnabled, isTrue);
  });

  test('notifier updates state only after the preference is stored', () async {
    final store = SharedPreferencesSearchPreferencesStore();
    final notifier = SearchPreferencesNotifier(store: store);
    await notifier.load();

    await notifier.setModelAssistedSearchEnabled(true);

    expect((await store.read()).modelAssistedSearchEnabled, isTrue);
    notifier.dispose();
  });
}
