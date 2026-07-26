import 'dart:convert';

import 'learning_agent_next_action.dart';
import 'learning_agent_practice_target.dart';
import 'learning_agent_planner_service.dart';

class LearningAgentPlanCodec {
  static const int currentVersion = 1;

  const LearningAgentPlanCodec();

  String encode(LearningAgentPlan plan) {
    return jsonEncode({
      'version': currentVersion,
      'goal': plan.goal.value,
      'readiness': _readinessToMap(plan.readiness),
      'memory': _memoryToMap(plan.memory),
      'steps': plan.steps.map(_stepToMap).toList(growable: false),
      'focus_points':
          plan.focusPoints.map(_focusPointToMap).toList(growable: false),
      'blockers': plan.blockers,
      'next_action': plan.nextAction?.toMap(),
      'session_summary': _sessionSummaryToMap(plan.sessionSummary),
    });
  }

  LearningAgentPlan decode(String value) {
    final map = Map<String, dynamic>.from(jsonDecode(value) as Map);
    final version = map['version'] as int?;
    if (version != currentVersion) {
      throw FormatException(
          'Unsupported learning agent plan version: $version');
    }

    return LearningAgentPlan(
      goal: LearningAgentGoal.fromString(map['goal'] as String),
      readiness: _readinessFromMap(_map(map['readiness'])),
      memory: _memoryFromMap(_map(map['memory'])),
      steps: _list(map['steps']).map((item) {
        return _stepFromMap(_map(item));
      }).toList(growable: false),
      focusPoints: _list(map['focus_points']).map((item) {
        return _focusPointFromMap(_map(item));
      }).toList(growable: false),
      blockers: _stringList(map['blockers']),
      nextAction: map['next_action'] == null
          ? null
          : LearningAgentNextAction.fromMap(_map(map['next_action'])),
      sessionSummary: _sessionSummaryFromMap(_map(map['session_summary'])),
    );
  }
}

Map<String, dynamic> _readinessToMap(LearningAgentReadiness readiness) {
  return {
    'evidence_backed_point_count': readiness.evidenceBackedPointCount,
    'evidence_gap_point_count': readiness.evidenceGapPointCount,
    'practiceable_point_count': readiness.practiceablePointCount,
    'verified_question_count': readiness.verifiedQuestionCount,
    'verified_programming_exercise_count':
        readiness.verifiedProgrammingExerciseCount,
    'pending_question_count': readiness.pendingQuestionCount,
    'pending_programming_exercise_count':
        readiness.pendingProgrammingExerciseCount,
  };
}

LearningAgentReadiness _readinessFromMap(Map<String, dynamic> map) {
  return LearningAgentReadiness(
    evidenceBackedPointCount: map['evidence_backed_point_count'] as int,
    evidenceGapPointCount: map['evidence_gap_point_count'] as int? ?? 0,
    practiceablePointCount: map['practiceable_point_count'] as int,
    verifiedQuestionCount: map['verified_question_count'] as int,
    verifiedProgrammingExerciseCount:
        map['verified_programming_exercise_count'] as int? ?? 0,
    pendingQuestionCount: map['pending_question_count'] as int,
    pendingProgrammingExerciseCount:
        map['pending_programming_exercise_count'] as int? ?? 0,
  );
}

Map<String, dynamic> _memoryToMap(LearningAgentMemoryState memory) {
  return {
    'goal_session_count': memory.goalSessionCount,
    'goal_open_follow_up_count': memory.goalOpenFollowUpCount,
    'latest_goal_session_title': memory.latestGoalSessionTitle,
    'latest_goal_session_target': memory.latestGoalSessionTarget,
    'latest_goal_session_started_at':
        memory.latestGoalSessionStartedAt?.millisecondsSinceEpoch,
  };
}

LearningAgentMemoryState _memoryFromMap(Map<String, dynamic> map) {
  final startedAt = map['latest_goal_session_started_at'] as int?;
  return LearningAgentMemoryState(
    goalSessionCount: map['goal_session_count'] as int,
    goalOpenFollowUpCount: map['goal_open_follow_up_count'] as int,
    latestGoalSessionTitle: map['latest_goal_session_title'] as String?,
    latestGoalSessionTarget: map['latest_goal_session_target'] as String?,
    latestGoalSessionStartedAt: startedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(startedAt),
  );
}

Map<String, dynamic> _stepToMap(LearningAgentPlanStep step) {
  return {
    'type': step.type.name,
    'title': step.title,
    'description': step.description,
    'enabled': step.enabled,
    'target_count': step.targetCount,
    'disabled_reason': step.disabledReason,
  };
}

LearningAgentPlanStep _stepFromMap(Map<String, dynamic> map) {
  return LearningAgentPlanStep(
    type: _stepTypeFromName(map['type'] as String),
    title: map['title'] as String,
    description: map['description'] as String,
    enabled: map['enabled'] as bool,
    targetCount: map['target_count'] as int? ?? 0,
    disabledReason: map['disabled_reason'] as String?,
  );
}

Map<String, dynamic> _focusPointToMap(LearningAgentFocusPoint point) {
  return {
    'id': point.id,
    'title': point.title,
    'reason': point.reason,
    'mastery_level': point.masteryLevel,
    'difficulty': point.difficulty,
    'interview_relevance': point.interviewRelevance,
    'evidence_chunk_count': point.evidenceChunkCount,
    'verified_question_count': point.verifiedQuestionCount,
    'verified_programming_exercise_count':
        point.verifiedProgrammingExerciseCount,
  };
}

LearningAgentFocusPoint _focusPointFromMap(Map<String, dynamic> map) {
  return LearningAgentFocusPoint(
    id: map['id'] as String,
    title: map['title'] as String,
    reason: map['reason'] as String,
    masteryLevel: map['mastery_level'] as int,
    difficulty: map['difficulty'] as int,
    interviewRelevance: map['interview_relevance'] as int,
    evidenceChunkCount: map['evidence_chunk_count'] as int,
    verifiedQuestionCount: map['verified_question_count'] as int,
    verifiedProgrammingExerciseCount:
        map['verified_programming_exercise_count'] as int? ?? 0,
  );
}

Map<String, dynamic> _sessionSummaryToMap(
  LearningAgentSessionSummary summary,
) {
  return {
    'goal': summary.goal.value,
    'next_step':
        summary.nextStep == null ? null : _stepToMap(summary.nextStep!),
    'focus_point': summary.focusPoint == null
        ? null
        : _focusPointToMap(summary.focusPoint!),
    'practice_target': summary.practiceTarget?.toMap(),
    'title': summary.title,
    'objective': summary.objective,
    'target_label': summary.targetLabel,
    'evidence_constraint': summary.evidenceConstraint,
    'memory_reminder': summary.memoryReminder,
    'success_criteria': summary.successCriteria,
    'reflection_prompts': summary.reflectionPrompts,
  };
}

LearningAgentSessionSummary _sessionSummaryFromMap(
  Map<String, dynamic> map,
) {
  final nextStep = map['next_step'];
  final focusPoint = map['focus_point'];
  final practiceTarget = map['practice_target'];
  return LearningAgentSessionSummary(
    goal: LearningAgentGoal.fromString(map['goal'] as String),
    nextStep: nextStep == null ? null : _stepFromMap(_map(nextStep)),
    focusPoint:
        focusPoint == null ? null : _focusPointFromMap(_map(focusPoint)),
    practiceTarget: practiceTarget == null
        ? null
        : LearningAgentPracticeTarget.fromMap(_map(practiceTarget)),
    title: map['title'] as String,
    objective: map['objective'] as String,
    targetLabel: map['target_label'] as String,
    evidenceConstraint: map['evidence_constraint'] as String,
    memoryReminder: map['memory_reminder'] as String?,
    successCriteria: _stringList(map['success_criteria']),
    reflectionPrompts: _stringList(map['reflection_prompts']),
  );
}

LearningAgentStepType _stepTypeFromName(String value) {
  for (final type in LearningAgentStepType.values) {
    if (type.name == value) return type;
  }
  throw FormatException('Unknown learning agent step type: $value');
}

Map<String, dynamic> _map(Object? value) {
  return Map<String, dynamic>.from(value as Map);
}

List<dynamic> _list(Object? value) {
  return List<dynamic>.from(value as List? ?? const []);
}

List<String> _stringList(Object? value) {
  return _list(value).map((item) => item as String).toList(growable: false);
}
