import 'learning_agent_planner_service.dart';
import 'learning_agent_tool_input_snapshot.dart';
import 'learning_agent_user_decision.dart';

const _listSeparator = '\x00';

enum LearningAgentPhase {
  plan('plan', '规划'),
  retrieve('retrieve', '检索证据'),
  act('act', '执行工具'),
  verify('verify', '核验结果'),
  reflect('reflect', '复盘'),
  complete('complete', '完成'),
  canceled('canceled', '已结束'),
  blocked('blocked', '阻断');

  final String value;
  final String label;
  const LearningAgentPhase(this.value, this.label);

  static LearningAgentPhase fromString(String value) {
    return LearningAgentPhase.values.firstWhere(
      (phase) => phase.value == value,
      orElse: () => LearningAgentPhase.plan,
    );
  }
}

class LearningAgentState {
  final String sessionId;
  final LearningAgentGoal goal;
  final LearningAgentPhase phase;
  final String? targetId;
  final String? focusPointId;
  final List<String> availableToolIds;
  final String? selectedToolId;
  final String? activeToolOperationId;
  final LearningAgentToolInputSnapshot? activeToolInputSnapshot;
  final List<String> evidenceChunkIds;
  final LearningAgentUserDecisionRequest? pendingUserDecision;
  final List<String> policyWarnings;
  final List<String> traceEventIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearningAgentState({
    required this.sessionId,
    required this.goal,
    required this.phase,
    this.targetId,
    this.focusPointId,
    this.availableToolIds = const [],
    this.selectedToolId,
    this.activeToolOperationId,
    this.activeToolInputSnapshot,
    this.evidenceChunkIds = const [],
    this.pendingUserDecision,
    this.policyWarnings = const [],
    this.traceEventIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningAgentState.initial({
    required String sessionId,
    required LearningAgentGoal goal,
    String? targetId,
    String? focusPointId,
    List<String> availableToolIds = const [],
  }) {
    final now = DateTime.now();
    return LearningAgentState(
      sessionId: sessionId,
      goal: goal,
      phase: LearningAgentPhase.plan,
      targetId: targetId,
      focusPointId: focusPointId,
      availableToolIds: availableToolIds,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get hasEvidence => evidenceChunkIds.isNotEmpty;
  bool get hasPolicyWarnings => policyWarnings.isNotEmpty;
  bool get isWaitingForUser => pendingUserDecision != null;

  bool get isTerminal {
    return phase == LearningAgentPhase.complete ||
        phase == LearningAgentPhase.canceled ||
        phase == LearningAgentPhase.blocked;
  }

  LearningAgentState copyWith({
    String? sessionId,
    LearningAgentGoal? goal,
    LearningAgentPhase? phase,
    String? targetId,
    String? focusPointId,
    List<String>? availableToolIds,
    String? selectedToolId,
    String? activeToolOperationId,
    LearningAgentToolInputSnapshot? activeToolInputSnapshot,
    bool clearActiveToolOperation = false,
    List<String>? evidenceChunkIds,
    LearningAgentUserDecisionRequest? pendingUserDecision,
    bool clearPendingUserDecision = false,
    List<String>? policyWarnings,
    List<String>? traceEventIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningAgentState(
      sessionId: sessionId ?? this.sessionId,
      goal: goal ?? this.goal,
      phase: phase ?? this.phase,
      targetId: targetId ?? this.targetId,
      focusPointId: focusPointId ?? this.focusPointId,
      availableToolIds: availableToolIds ?? this.availableToolIds,
      selectedToolId: selectedToolId ?? this.selectedToolId,
      activeToolOperationId: clearActiveToolOperation
          ? null
          : activeToolOperationId ?? this.activeToolOperationId,
      activeToolInputSnapshot: clearActiveToolOperation
          ? null
          : activeToolInputSnapshot ?? this.activeToolInputSnapshot,
      evidenceChunkIds: evidenceChunkIds ?? this.evidenceChunkIds,
      pendingUserDecision: clearPendingUserDecision
          ? null
          : pendingUserDecision ?? this.pendingUserDecision,
      policyWarnings: policyWarnings ?? this.policyWarnings,
      traceEventIds: traceEventIds ?? this.traceEventIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  LearningAgentState transitionTo(
    LearningAgentPhase nextPhase, {
    String? selectedToolId,
    String? activeToolOperationId,
    LearningAgentToolInputSnapshot? activeToolInputSnapshot,
    bool clearActiveToolOperation = false,
    List<String>? evidenceChunkIds,
    LearningAgentUserDecisionRequest? pendingUserDecision,
    bool clearPendingUserDecision = false,
    List<String>? policyWarnings,
    List<String>? traceEventIds,
    DateTime? updatedAt,
  }) {
    return copyWith(
      phase: nextPhase,
      selectedToolId: selectedToolId,
      activeToolOperationId: activeToolOperationId,
      activeToolInputSnapshot: activeToolInputSnapshot,
      clearActiveToolOperation: clearActiveToolOperation,
      evidenceChunkIds: evidenceChunkIds,
      pendingUserDecision: pendingUserDecision,
      clearPendingUserDecision: clearPendingUserDecision,
      policyWarnings: policyWarnings,
      traceEventIds: traceEventIds,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'goal': goal.value,
      'phase': phase.value,
      'target_id': targetId,
      'focus_point_id': focusPointId,
      'available_tool_ids': _joinList(availableToolIds),
      'selected_tool_id': selectedToolId,
      'active_tool_operation_id': activeToolOperationId,
      'active_tool_input_snapshot': activeToolInputSnapshot?.toStorageValue(),
      'evidence_chunk_ids': _joinList(evidenceChunkIds),
      'pending_user_decision': pendingUserDecision?.toStorageValue(),
      'policy_warnings': _joinList(policyWarnings),
      'trace_event_ids': _joinList(traceEventIds),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LearningAgentState.fromMap(Map<String, dynamic> map) {
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int);
    final selectedToolId = map['selected_tool_id'] as String?;
    var activeToolOperationId = map['active_tool_operation_id'] as String?;
    var activeToolInputSnapshot =
        LearningAgentToolInputSnapshot.fromStorageValue(
      map['active_tool_input_snapshot'] as String?,
    );
    final decodedPendingUserDecision =
        LearningAgentUserDecisionRequest.fromStorageValue(
      map['pending_user_decision'] as String?,
      fallbackRequestedAt: updatedAt,
      fallbackToolId: selectedToolId,
    );
    var pendingUserDecision = decodedPendingUserDecision;
    if (decodedPendingUserDecision != null &&
        decodedPendingUserDecision.reason ==
            LearningAgentUserDecisionReason.toolOutcomeUnknown &&
        decodedPendingUserDecision.operationId == null) {
      final legacyAttemptId = decodedPendingUserDecision.attemptId?.trim();
      if (activeToolOperationId == null &&
          legacyAttemptId != null &&
          legacyAttemptId.isNotEmpty) {
        activeToolOperationId = 'legacy_operation_$legacyAttemptId';
      }
      if (activeToolOperationId != null) {
        pendingUserDecision = LearningAgentUserDecisionRequest(
          id: decodedPendingUserDecision.id,
          prompt: decodedPendingUserDecision.prompt,
          requestedAt: decodedPendingUserDecision.requestedAt,
          toolId: decodedPendingUserDecision.toolId,
          operationId: activeToolOperationId,
          attemptId: decodedPendingUserDecision.attemptId,
          reason: decodedPendingUserDecision.reason,
        );
      }
    }
    if (activeToolOperationId != null &&
        activeToolInputSnapshot == null &&
        selectedToolId != null &&
        selectedToolId.trim().isNotEmpty) {
      activeToolInputSnapshot = LearningAgentToolInputSnapshot(
        toolId: selectedToolId,
        targetId: map['target_id'] as String?,
        focusPointId: map['focus_point_id'] as String?,
        evidenceChunkIds: _splitList(map['evidence_chunk_ids'] as String?),
      );
    }
    return LearningAgentState(
      sessionId: map['session_id'] as String,
      goal: LearningAgentGoal.fromString(map['goal'] as String),
      phase: LearningAgentPhase.fromString(map['phase'] as String),
      targetId: map['target_id'] as String?,
      focusPointId: map['focus_point_id'] as String?,
      availableToolIds: _splitList(map['available_tool_ids'] as String?),
      selectedToolId: selectedToolId,
      activeToolOperationId: activeToolOperationId,
      activeToolInputSnapshot: activeToolInputSnapshot,
      evidenceChunkIds: _splitList(map['evidence_chunk_ids'] as String?),
      pendingUserDecision: pendingUserDecision,
      policyWarnings: _splitList(map['policy_warnings'] as String?),
      traceEventIds: _splitList(map['trace_event_ids'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: updatedAt,
    );
  }
}

String _joinList(List<String> values) {
  return values.where((value) => value.isNotEmpty).join(_listSeparator);
}

List<String> _splitList(String? value) {
  if (value == null || value.isEmpty) return const [];
  return value.split(_listSeparator).where((item) => item.isNotEmpty).toList();
}
