import 'dart:convert';

enum ProductEventName {
  onboardingStarted('onboarding_started'),
  goalSelected('goal_selected'),
  modelReadinessViewed('model_readiness_viewed'),
  modelAcceptanceCompleted('model_acceptance_completed'),
  projectImportStarted('project_import_started'),
  projectScanCompleted('project_scan_completed'),
  projectImportFailed('project_import_failed'),
  coverageReviewCompleted('coverage_review_completed'),
  verifiedContentSaved('verified_content_saved'),
  agentWorkspaceViewed('agent_workspace_viewed'),
  groundedTurnCompleted('grounded_turn_completed'),
  followUpCompleted('follow_up_completed'),
  reviewScheduled('review_scheduled'),
  outcomeViewed('outcome_viewed'),
  outcomeExported('outcome_exported'),
  feedbackSubmitted('feedback_submitted'),
  supportBundleExported('support_bundle_exported'),
  dataDeleted('data_deleted');

  final String value;

  const ProductEventName(this.value);

  static ProductEventName fromString(String value) {
    return ProductEventName.values.firstWhere(
      (name) => name.value == value,
      orElse: () => throw FormatException('Unknown product event: $value'),
    );
  }
}

class ProductEvent {
  static const int currentSchemaVersion = 1;

  final String id;
  final ProductEventName name;
  final int schemaVersion;
  final DateTime occurredAt;
  final String anonymousInstallId;
  final String appVersion;
  final String platform;
  final String flowId;
  final String goal;
  final String? targetId;
  final String? sessionId;
  final Map<String, Object?> properties;
  final String? dedupeKey;

  const ProductEvent({
    required this.id,
    required this.name,
    required this.occurredAt,
    required this.anonymousInstallId,
    required this.appVersion,
    required this.platform,
    required this.flowId,
    required this.goal,
    required this.properties,
    this.schemaVersion = currentSchemaVersion,
    this.targetId,
    this.sessionId,
    this.dedupeKey,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'event_name': name.value,
      'schema_version': schemaVersion,
      'occurred_at': occurredAt.millisecondsSinceEpoch,
      'anonymous_install_id': anonymousInstallId,
      'app_version': appVersion,
      'platform': platform,
      'flow_id': flowId,
      'goal': goal,
      'target_id': targetId,
      'session_id': sessionId,
      'properties_json': jsonEncode(properties),
      'dedupe_key': dedupeKey,
    };
  }

  Map<String, Object?> toExportJson() {
    return {
      'event_id': id,
      'event_name': name.value,
      'schema_version': schemaVersion,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'anonymous_install_id': anonymousInstallId,
      'app_version': appVersion,
      'platform': platform,
      'flow_id': flowId,
      'goal': goal,
      'target_id': targetId,
      'session_id': sessionId,
      'properties': properties,
    };
  }

  factory ProductEvent.fromMap(Map<String, Object?> map) {
    final rawProperties = map['properties_json']?.toString() ?? '{}';
    final decoded = jsonDecode(rawProperties);
    if (decoded is! Map) {
      throw const FormatException(
          'Product event properties must be an object.');
    }
    return ProductEvent(
      id: map['id']?.toString() ?? '',
      name: ProductEventName.fromString(map['event_name']?.toString() ?? ''),
      schemaVersion: int.tryParse(map['schema_version']?.toString() ?? '') ?? 1,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['occurred_at']?.toString() ?? '') ?? 0,
      ),
      anonymousInstallId: map['anonymous_install_id']?.toString() ?? '',
      appVersion: map['app_version']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      flowId: map['flow_id']?.toString() ?? '',
      goal: map['goal']?.toString() ?? 'unknown',
      targetId: _nullableString(map['target_id']),
      sessionId: _nullableString(map['session_id']),
      properties: Map<String, Object?>.from(decoded),
      dedupeKey: _nullableString(map['dedupe_key']),
    );
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
