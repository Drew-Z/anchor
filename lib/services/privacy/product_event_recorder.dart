import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_metadata.dart';
import '../../data/models/product_event.dart';
import '../../data/repositories/product_event_repository.dart';
import 'privacy_preferences.dart';

class ProductEventRecorder {
  static const String appVersion = AppMetadata.version;

  final ProductEventRepository _repository;
  final PrivacyPreferencesStore _preferencesStore;
  final DateTime Function() _clock;
  final Random _random;
  final String _platform;
  final String _appVersion;

  ProductEventRecorder({
    required ProductEventRepository repository,
    required PrivacyPreferencesStore preferencesStore,
    DateTime Function()? clock,
    Random? random,
    String? platform,
    String? appVersionOverride,
  })  : _repository = repository,
        _preferencesStore = preferencesStore,
        _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure(),
        _platform = platform ?? defaultTargetPlatform.name,
        _appVersion = appVersionOverride ?? appVersion;

  Future<bool> record(
    ProductEventName name, {
    String flowId = 'app',
    String goal = 'unknown',
    String? targetId,
    String? sessionId,
    Map<String, Object?> properties = const {},
    String? dedupeKey,
  }) async {
    final preferences = await _preferencesStore.read();
    if (!preferences.localProductEventsEnabled) return false;

    final normalizedProperties = _validateProperties(name, properties);
    final occurredAt = _clock();
    final event = ProductEvent(
      id: _newEventId(occurredAt),
      name: name,
      occurredAt: occurredAt,
      anonymousInstallId:
          await _preferencesStore.readOrCreateAnonymousInstallId(),
      appVersion: _appVersion,
      platform: _stableValue(_platform, field: 'platform'),
      flowId: _stableValue(flowId, field: 'flow_id'),
      goal: _stableValue(goal, field: 'goal'),
      targetId: _optionalStableValue(targetId, field: 'target_id'),
      sessionId: _optionalStableValue(sessionId, field: 'session_id'),
      properties: normalizedProperties,
      dedupeKey: _optionalStableValue(dedupeKey, field: 'dedupe_key'),
    );
    return _repository.insert(event);
  }

  Future<bool> recordBestEffort(
    ProductEventName name, {
    String flowId = 'app',
    String goal = 'unknown',
    String? targetId,
    String? sessionId,
    Map<String, Object?> properties = const {},
    String? dedupeKey,
  }) async {
    try {
      return await record(
        name,
        flowId: flowId,
        goal: goal,
        targetId: targetId,
        sessionId: sessionId,
        properties: properties,
        dedupeKey: dedupeKey,
      );
    } catch (error) {
      debugPrint('Product event was not persisted: $error');
      return false;
    }
  }

  static String durationBucket(Duration duration) {
    if (duration < const Duration(seconds: 1)) return 'lt_1s';
    if (duration < const Duration(seconds: 5)) return '1_to_5s';
    if (duration < const Duration(seconds: 15)) return '5_to_15s';
    if (duration < const Duration(minutes: 1)) return '15_to_60s';
    return 'gte_60s';
  }

  static String byteCountBucket(int bytes) {
    if (bytes <= 0) return 'empty';
    if (bytes <= 64 * 1024) return 'lte_64kb';
    if (bytes <= 256 * 1024) return '64_to_256kb';
    if (bytes <= 1024 * 1024) return '256kb_to_1mb';
    return 'gt_1mb';
  }

  static String dueBucket(DateTime dueAt, {DateTime? now}) {
    final delta = dueAt.difference(now ?? DateTime.now());
    if (delta <= Duration.zero) return 'due_now';
    if (delta <= const Duration(days: 1)) return 'within_1d';
    if (delta <= const Duration(days: 7)) return 'within_7d';
    return 'after_7d';
  }

  Map<String, Object?> _validateProperties(
    ProductEventName name,
    Map<String, Object?> properties,
  ) {
    final allowed = _allowedProperties[name] ?? const <String>{};
    final required = _requiredProperties[name] ?? const <String>{};
    final unknown = properties.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        '${name.value} contains non-allowlisted properties: ${unknown.join(', ')}',
      );
    }
    final missing = required.where(
      (key) => !properties.containsKey(key) || properties[key] == null,
    );
    if (missing.isNotEmpty) {
      throw ArgumentError(
        '${name.value} is missing required properties: ${missing.join(', ')}',
      );
    }
    return {
      for (final entry in properties.entries)
        entry.key: _normalizePropertyValue(entry.key, entry.value),
    };
  }

  Object? _normalizePropertyValue(String key, Object? value) {
    if (value == null || value is bool || value is int || value is double) {
      return value;
    }
    if (value is String) return _stableValue(value, field: key);
    if (value is List) {
      if (value.length > 20 || value.any((item) => item is! String)) {
        throw ArgumentError('$key must be a short list of stable strings.');
      }
      return value
          .cast<String>()
          .map((item) => _stableValue(item, field: key))
          .toList(growable: false);
    }
    throw ArgumentError('$key has an unsupported property type.');
  }

  String _stableValue(String value, {required String field}) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 120) {
      throw ArgumentError('$field must be between 1 and 120 characters.');
    }
    if (_forbiddenValue.hasMatch(normalized)) {
      throw ArgumentError('$field contains private or unbounded content.');
    }
    return normalized;
  }

  String? _optionalStableValue(String? value, {required String field}) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return _stableValue(normalized, field: field);
  }

  String _newEventId(DateTime occurredAt) {
    final suffix = List<int>.generate(8, (_) => _random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'evt_${occurredAt.toUtc().microsecondsSinceEpoch}_$suffix';
  }
}

final RegExp _forbiddenValue = RegExp(
  r'(?:https?://\S*\?|\bsk-[A-Za-z0-9_-]{6,}\b|\bAIza[A-Za-z0-9_-]{12,}\b|[A-Za-z]:[\\/]|(?:^|\s)/(?:Users|home|data|storage|sdcard|var|tmp)/|[\r\n])',
  caseSensitive: false,
);

const Map<ProductEventName, Set<String>> _allowedProperties = {
  ProductEventName.onboardingStarted: {'entry_point'},
  ProductEventName.goalSelected: {'goal'},
  ProductEventName.modelReadinessViewed: {
    'provider_configured',
    'protocol_configured',
  },
  ProductEventName.modelAcceptanceCompleted: {
    'passed',
    'failure_category',
    'case_count',
    'latency_bucket',
  },
  ProductEventName.projectImportStarted: {'import_type'},
  ProductEventName.projectScanCompleted: {
    'selected_count',
    'excluded_count',
    'total_bytes_bucket',
    'duration_bucket',
  },
  ProductEventName.projectImportFailed: {'failure_code', 'phase'},
  ProductEventName.coverageReviewCompleted: {
    'included_count',
    'excluded_count',
    'locator_coverage',
  },
  ProductEventName.verifiedContentSaved: {
    'source_count',
    'point_count',
    'question_count',
    'exercise_count',
  },
  ProductEventName.agentWorkspaceViewed: {
    'scope',
    'next_action_type',
    'blocker_code',
  },
  ProductEventName.groundedTurnCompleted: {
    'surface',
    'disposition',
    'citation_count',
    'duration_bucket',
  },
  ProductEventName.followUpCompleted: {'action_type', 'target_type'},
  ProductEventName.reviewScheduled: {'target_type', 'due_bucket'},
  ProductEventName.outcomeViewed: {
    'ready_count',
    'weak_count',
    'gap_count',
    'unassessed_count',
  },
  ProductEventName.outcomeExported: {
    'format',
    'included_citation_count',
  },
  ProductEventName.feedbackSubmitted: {
    'category',
    'severity',
    'diagnostic_consent',
  },
  ProductEventName.supportBundleExported: {
    'included_sections',
    'redaction_version',
  },
  ProductEventName.dataDeleted: {'data_scopes', 'result'},
};

const Map<ProductEventName, Set<String>> _requiredProperties =
    _allowedProperties;
