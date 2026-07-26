import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPreferences {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final bool localProductEventsEnabled;
  final bool includeAgentRuntimeSummary;

  const PrivacyPreferences({
    this.schemaVersion = currentSchemaVersion,
    this.localProductEventsEnabled = true,
    this.includeAgentRuntimeSummary = false,
  });

  PrivacyPreferences copyWith({
    bool? localProductEventsEnabled,
    bool? includeAgentRuntimeSummary,
  }) {
    return PrivacyPreferences(
      localProductEventsEnabled:
          localProductEventsEnabled ?? this.localProductEventsEnabled,
      includeAgentRuntimeSummary:
          includeAgentRuntimeSummary ?? this.includeAgentRuntimeSummary,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schema_version': schemaVersion,
      'local_product_events_enabled': localProductEventsEnabled,
      'include_agent_runtime_summary': includeAgentRuntimeSummary,
    };
  }

  factory PrivacyPreferences.fromJson(Map<String, Object?> json) {
    return PrivacyPreferences(
      schemaVersion:
          int.tryParse(json['schema_version']?.toString() ?? '') ?? 1,
      localProductEventsEnabled: json['local_product_events_enabled'] != false,
      includeAgentRuntimeSummary: json['include_agent_runtime_summary'] == true,
    );
  }
}

abstract class PrivacyPreferencesStore {
  Future<PrivacyPreferences> read();

  Future<void> write(PrivacyPreferences preferences);

  Future<String> readOrCreateAnonymousInstallId();

  Future<void> resetAnonymousInstallId();
}

class SharedPreferencesPrivacyPreferencesStore
    implements PrivacyPreferencesStore {
  static const String storageKey = 'privacy_preferences_v1';
  static const String anonymousInstallIdKey = 'anonymous_install_id_v1';

  final Future<SharedPreferences> Function() _preferencesLoader;
  final Random _random;

  SharedPreferencesPrivacyPreferencesStore({
    Future<SharedPreferences> Function()? preferencesLoader,
    Random? random,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _random = random ?? Random.secure();

  @override
  Future<PrivacyPreferences> read() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const PrivacyPreferences();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const PrivacyPreferences();
      return PrivacyPreferences.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return const PrivacyPreferences();
    }
  }

  @override
  Future<void> write(PrivacyPreferences preferences) async {
    final sharedPreferences = await _preferencesLoader();
    await sharedPreferences.setString(
      storageKey,
      jsonEncode(preferences.toJson()),
    );
  }

  @override
  Future<String> readOrCreateAnonymousInstallId() async {
    final preferences = await _preferencesLoader();
    final existing = preferences.getString(anonymousInstallIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final value =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await preferences.setString(anonymousInstallIdKey, value);
    return value;
  }

  @override
  Future<void> resetAnonymousInstallId() async {
    final preferences = await _preferencesLoader();
    await preferences.remove(anonymousInstallIdKey);
  }
}

class PrivacyPreferencesNotifier
    extends StateNotifier<AsyncValue<PrivacyPreferences>> {
  final PrivacyPreferencesStore _store;

  PrivacyPreferencesNotifier({
    required PrivacyPreferencesStore store,
    bool autoLoad = true,
  })  : _store = store,
        super(const AsyncValue.loading()) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_store.read);
  }

  Future<void> setLocalProductEventsEnabled(bool value) {
    return _update(
      (current) => current.copyWith(localProductEventsEnabled: value),
    );
  }

  Future<void> setIncludeAgentRuntimeSummary(bool value) {
    return _update(
      (current) => current.copyWith(includeAgentRuntimeSummary: value),
    );
  }

  Future<void> _update(
    PrivacyPreferences Function(PrivacyPreferences current) transform,
  ) async {
    final current = state.valueOrNull ?? await _store.read();
    final updated = transform(current);
    try {
      await _store.write(updated);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
