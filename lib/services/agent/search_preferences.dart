import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPreferences {
  final bool modelAssistedSearchEnabled;

  const SearchPreferences({this.modelAssistedSearchEnabled = false});

  SearchPreferences copyWith({bool? modelAssistedSearchEnabled}) {
    return SearchPreferences(
      modelAssistedSearchEnabled:
          modelAssistedSearchEnabled ?? this.modelAssistedSearchEnabled,
    );
  }

  Map<String, Object?> toJson() => {
        'schema_version': 1,
        'model_assisted_search_enabled': modelAssistedSearchEnabled,
      };

  factory SearchPreferences.fromJson(Map<String, Object?> json) {
    return SearchPreferences(
      modelAssistedSearchEnabled: json['model_assisted_search_enabled'] == true,
    );
  }
}

abstract class SearchPreferencesStore {
  Future<SearchPreferences> read();

  Future<void> write(SearchPreferences preferences);
}

class SharedPreferencesSearchPreferencesStore
    implements SearchPreferencesStore {
  static const storageKey = 'search_preferences_v1';

  final Future<SharedPreferences> Function() _preferencesLoader;

  SharedPreferencesSearchPreferencesStore({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  @override
  Future<SearchPreferences> read() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const SearchPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const SearchPreferences();
      return SearchPreferences.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return const SearchPreferences();
    }
  }

  @override
  Future<void> write(SearchPreferences preferences) async {
    final sharedPreferences = await _preferencesLoader();
    await sharedPreferences.setString(
        storageKey, jsonEncode(preferences.toJson()));
  }
}

class SearchPreferencesNotifier
    extends StateNotifier<AsyncValue<SearchPreferences>> {
  final SearchPreferencesStore _store;

  SearchPreferencesNotifier({required SearchPreferencesStore store})
      : _store = store,
        super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_store.read);
  }

  Future<void> setModelAssistedSearchEnabled(bool value) async {
    final current = state.valueOrNull ?? await _store.read();
    final updated = current.copyWith(modelAssistedSearchEnabled: value);
    try {
      await _store.write(updated);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
