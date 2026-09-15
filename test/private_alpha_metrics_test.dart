import 'package:anchor_learning/services/privacy/private_alpha_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports the fixed ten-user alpha targets without redefining them', () {
    final exports = List.generate(10, _participantExport);
    exports.add(_participantExport(0));

    final report = const PrivateAlphaMetricsAggregator().aggregate(
      exports,
      invitedUsers: 10,
    );

    expect(report.observedUsers, 10);
    expect(report.importStartedUsers, 10);
    expect(report.coverageReviewUsers, 10);
    expect(report.activatedUsers, 6);
    expect(report.activationConversion, 0.6);
    expect(report.medianActivationMinutes, 10);
    expect(report.groundedClosureUsers, 6);
    expect(report.secondClosureWithinSevenDaysUsers, 3);
    expect(report.secondClosureRate, 0.5);
    expect(report.weekTwoReturningUsers, 3);
    expect(report.weekTwoReturnRate, 0.3);
    expect(report.formalGroundedTurns, 9);
    expect(report.evidenceCompliantTurns, 9);
    expect(report.feedbackCount, 1);
    expect(report.feedbackByCategory, {'feature_request': 1});
    expect(report.activationConversionStatus, PrivateAlphaTargetStatus.met);
    expect(report.activationTimeStatus, PrivateAlphaTargetStatus.met);
    expect(report.secondClosureStatus, PrivateAlphaTargetStatus.met);
    expect(report.weekTwoReturnStatus, PrivateAlphaTargetStatus.met);
    expect(report.evidenceComplianceStatus, PrivateAlphaTargetStatus.met);
    expect(report.toMarkdown(), contains('Import-to-activation >= 60% | met'));
  });

  test('keeps target status insufficient before the formal cohort matures', () {
    final report = const PrivateAlphaMetricsAggregator().aggregate(
      [_participantExport(0), _participantExport(1)],
      invitedUsers: 10,
    );

    expect(report.observedUsers, 2);
    expect(
      report.activationConversionStatus,
      PrivateAlphaTargetStatus.insufficientData,
    );
    expect(
      report.weekTwoReturnStatus,
      PrivateAlphaTargetStatus.insufficientData,
    );
  });

  test('marks uncited grounded turns as an evidence target miss', () {
    final exports = List.generate(10, (index) {
      final export = _participantExport(index);
      if (index == 0) {
        final events = export['events']! as List<Map<String, Object?>>;
        final grounded = events.firstWhere(
          (event) => event['event_name'] == 'grounded_turn_completed',
        );
        grounded['properties'] = {
          'surface': 'interview',
          'disposition': 'grounded',
          'citation_count': 0,
          'duration_bucket': '5_to_15s',
        };
      }
      return export;
    });

    final report = const PrivateAlphaMetricsAggregator().aggregate(
      exports,
      invitedUsers: 10,
    );

    expect(report.evidenceComplianceRate, lessThan(1));
    expect(report.evidenceComplianceStatus, PrivateAlphaTargetStatus.missed);
  });
}

Map<String, Object?> _participantExport(int index) {
  final participantId = 'participant_$index';
  final startedAt = DateTime.utc(2026, 7, 1, 9).add(Duration(minutes: index));
  final events = <Map<String, Object?>>[
    _event(participantId, index, 0, 'project_import_started', startedAt, {
      'import_type': 'directory',
    }),
    _event(
      participantId,
      index,
      1,
      'coverage_review_completed',
      startedAt.add(const Duration(minutes: 5)),
      {
        'included_count': 8,
        'excluded_count': 2,
        'locator_coverage': 'complete',
      },
    ),
  ];
  if (index < 6) {
    events.addAll([
      _event(
        participantId,
        index,
        2,
        'grounded_turn_completed',
        startedAt.add(const Duration(minutes: 10)),
        {
          'surface': 'interview',
          'disposition': 'grounded',
          'citation_count': 1,
          'duration_bucket': '5_to_15s',
        },
      ),
      _event(
        participantId,
        index,
        3,
        'review_scheduled',
        startedAt.add(const Duration(minutes: 11)),
        {'target_type': 'knowledge_point', 'due_bucket': 'within_7d'},
      ),
    ]);
  }
  if (index < 3) {
    events.addAll([
      _event(
        participantId,
        index,
        4,
        'grounded_turn_completed',
        startedAt.add(const Duration(days: 3)),
        {
          'surface': 'practice',
          'disposition': 'partial',
          'citation_count': 0,
          'duration_bucket': '15_to_60s',
        },
      ),
      _event(
        participantId,
        index,
        5,
        'follow_up_completed',
        startedAt.add(const Duration(days: 3, minutes: 1)),
        {'action_type': 'question_review', 'target_type': 'question'},
      ),
      _event(
        participantId,
        index,
        6,
        'agent_workspace_viewed',
        startedAt.add(const Duration(days: 8)),
        {
          'scope': 'mixed',
          'next_action_type': 'due_review',
          'blocker_code': 'none',
        },
      ),
    ]);
  }
  if (index == 0) {
    events.add(
      _event(
        participantId,
        index,
        7,
        'feedback_submitted',
        startedAt.add(const Duration(days: 8, minutes: 2)),
        {
          'category': 'feature_request',
          'severity': 'medium',
          'diagnostic_consent': false,
        },
      ),
    );
  }
  return {
    'schema_version': 1,
    'generated_at': DateTime.utc(2026, 7, 15).toIso8601String(),
    'event_count': events.length,
    'events': events,
  };
}

Map<String, Object?> _event(
  String participantId,
  int participantIndex,
  int eventIndex,
  String name,
  DateTime occurredAt,
  Map<String, Object?> properties,
) {
  return {
    'event_id': 'event_${participantIndex}_$eventIndex',
    'event_name': name,
    'schema_version': 1,
    'occurred_at': occurredAt.toIso8601String(),
    'anonymous_install_id': participantId,
    'app_version': '1.0.0+1',
    'platform': 'android',
    'flow_id': 'private_alpha',
    'goal': 'ai_interview_prep',
    'target_id': null,
    'session_id': null,
    'properties': properties,
  };
}
