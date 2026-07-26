import 'learning_agent_planner_service.dart';
import 'learning_agent_state.dart';
import 'learning_agent_trace.dart';
import 'learning_agent_user_decision.dart';

class LearningAgentCheckpoint {
  final LearningAgentState state;
  final List<LearningAgentTraceEvent> traceEvents;
  final LearningAgentPlan? plan;
  final int revision;

  LearningAgentCheckpoint._({
    required this.state,
    required this.traceEvents,
    required this.plan,
    required this.revision,
  });

  factory LearningAgentCheckpoint({
    required LearningAgentState state,
    required List<LearningAgentTraceEvent> traceEvents,
    LearningAgentPlan? plan,
    int revision = 0,
  }) {
    if (revision < 0) {
      throw ArgumentError.value(
        revision,
        'revision',
        'A checkpoint revision cannot be negative.',
      );
    }
    final events = List<LearningAgentTraceEvent>.unmodifiable(traceEvents);
    final eventIds = <String>[];
    final seenEventIds = <String>{};

    for (final event in events) {
      if (event.sessionId != state.sessionId) {
        throw ArgumentError(
          'Trace event ${event.id} belongs to ${event.sessionId}, '
          'not checkpoint session ${state.sessionId}.',
        );
      }
      if (!seenEventIds.add(event.id)) {
        throw ArgumentError('Duplicate trace event id: ${event.id}.');
      }
      eventIds.add(event.id);
    }
    if (plan != null &&
        (plan.goal != state.goal || plan.sessionSummary.goal != state.goal)) {
      throw ArgumentError(
        'Checkpoint plan goals (${plan.goal.value}, '
        '${plan.sessionSummary.goal.value}) do not match '
        'state goal ${state.goal.value}.',
      );
    }
    final pendingDecision = state.pendingUserDecision;
    final activeOperationId = state.activeToolOperationId;
    final activeToolInput = state.activeToolInputSnapshot;
    if (activeOperationId != null && activeOperationId.trim().isEmpty) {
      throw ArgumentError(
        'An active tool operation id cannot be empty.',
      );
    }
    if ((activeOperationId == null) != (activeToolInput == null)) {
      throw ArgumentError(
        'An active tool operation and its input snapshot must coexist.',
      );
    }
    if (activeToolInput != null) {
      if (activeToolInput.toolId != state.selectedToolId) {
        throw ArgumentError(
          'Active tool input references ${activeToolInput.toolId}, '
          'not ${state.selectedToolId}.',
        );
      }
      if (activeToolInput.targetId != state.targetId ||
          activeToolInput.focusPointId != state.focusPointId ||
          !_sameStrings(
            activeToolInput.evidenceChunkIds,
            state.evidenceChunkIds,
          )) {
        throw ArgumentError(
          'Active tool input does not match the checkpoint routing state.',
        );
      }
    }
    final decisionOperationId = pendingDecision?.operationId;
    if (decisionOperationId != null) {
      if (decisionOperationId.trim().isEmpty) {
        throw ArgumentError(
          'A tool decision operation id cannot be empty.',
        );
      }
      if (decisionOperationId != state.activeToolOperationId) {
        throw ArgumentError(
          'Tool decision operation $decisionOperationId does not match '
          'active operation ${state.activeToolOperationId}.',
        );
      }
    }
    if (pendingDecision?.reason ==
        LearningAgentUserDecisionReason.toolOutcomeUnknown) {
      if (decisionOperationId == null) {
        throw ArgumentError(
          'Unknown tool outcome must include a tool operation id.',
        );
      }
      if (activeOperationId == null || activeOperationId.trim().isEmpty) {
        throw ArgumentError(
          'Unknown tool outcome must reference an active tool operation.',
        );
      }
      final attemptId = pendingDecision!.attemptId;
      if (attemptId == null || attemptId.trim().isEmpty) {
        throw ArgumentError(
          'Unknown tool outcome must include a tool attempt id.',
        );
      }
      final decisionToolId = pendingDecision.toolId;
      if (decisionToolId == null || decisionToolId.trim().isEmpty) {
        throw ArgumentError(
          'Unknown tool outcome must include a tool id.',
        );
      }
      LearningAgentTraceEvent? attemptEvent;
      for (final event in events) {
        if (event.id == attemptId) {
          attemptEvent = event;
          break;
        }
      }
      if (attemptEvent == null) {
        throw ArgumentError(
          'Unknown tool outcome attempt $attemptId has no matching trace.',
        );
      }
      if (attemptEvent.type != LearningAgentTraceEventType.toolStarted) {
        throw ArgumentError(
          'Unknown tool outcome attempt $attemptId must reference '
          'a tool_started trace.',
        );
      }
      if (attemptEvent.toolId != decisionToolId) {
        throw ArgumentError(
          'Unknown tool outcome attempt $attemptId references '
          '${attemptEvent.toolId}, not $decisionToolId.',
        );
      }
    }

    return LearningAgentCheckpoint._(
      state: state.copyWith(traceEventIds: eventIds),
      traceEvents: events,
      plan: plan,
      revision: revision,
    );
  }

  String get sessionId => state.sessionId;

  LearningAgentCheckpoint withRevision(int revision) {
    return LearningAgentCheckpoint(
      state: state,
      traceEvents: traceEvents,
      plan: plan,
      revision: revision,
    );
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  final normalizedLeft = left.toSet().toList()..sort();
  final normalizedRight = right.toSet().toList()..sort();
  if (normalizedLeft.length != normalizedRight.length) return false;
  for (var index = 0; index < normalizedLeft.length; index++) {
    if (normalizedLeft[index] != normalizedRight[index]) return false;
  }
  return true;
}
