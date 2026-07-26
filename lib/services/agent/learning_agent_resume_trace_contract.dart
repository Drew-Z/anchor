import 'learning_agent_resume_policy.dart';
import 'learning_agent_state.dart';
import 'learning_agent_tool_registry.dart';
import 'learning_agent_trace.dart';

class LearningAgentResumeTraceDraft {
  final LearningAgentResumeReadiness readiness;
  final LearningAgentTraceEvent? event;
  final List<String> retainedTraceEventIds;

  const LearningAgentResumeTraceDraft({
    required this.readiness,
    this.event,
    this.retainedTraceEventIds = const [],
  });

  bool get canRecord => event != null;
}

class LearningAgentResumeTraceContract {
  final LearningAgentResumePolicy resumePolicy;

  const LearningAgentResumeTraceContract({
    this.resumePolicy = const LearningAgentResumePolicy(),
  });

  LearningAgentResumeTraceDraft draftResumeEvent({
    required LearningAgentState? state,
    LearningAgentToolDefinition? selectedTool,
    String? reason,
    DateTime? resumedAt,
  }) {
    final readiness = resumePolicy.evaluate(
      state,
      selectedTool: selectedTool,
    );
    if (state == null || !readiness.canResume) {
      return LearningAgentResumeTraceDraft(readiness: readiness);
    }

    final resumed = resumedAt ?? DateTime.now();
    final toolId = selectedTool?.toolId ?? state.selectedToolId;
    final detailLines = [
      '恢复状态: ${readiness.status.label}',
      '恢复原因: ${_reasonText(reason)}',
      '原阶段: ${state.phase.label}',
      '工具: ${selectedTool?.title ?? toolId ?? '未记录'}',
      '原 Trace 数量: ${state.traceEventIds.length}',
      if (state.traceEventIds.isNotEmpty)
        '最近 Trace ID: ${state.traceEventIds.last}',
      if (state.evidenceChunkIds.isNotEmpty)
        '证据片段: ${state.evidenceChunkIds.length}',
      if (state.policyWarnings.isNotEmpty)
        '策略警告: ${state.policyWarnings.join('、')}',
      if (readiness.requiresUserDecision) '需要用户决策: 是',
    ];

    return LearningAgentResumeTraceDraft(
      readiness: readiness,
      retainedTraceEventIds: List.unmodifiable(state.traceEventIds),
      event: LearningAgentTraceEvent(
        id: '${resumed.microsecondsSinceEpoch}_session_resumed',
        sessionId: state.sessionId,
        goal: state.goal,
        type: LearningAgentTraceEventType.sessionResumed,
        level: readiness.requiresUserDecision
            ? LearningAgentTraceLevel.warning
            : LearningAgentTraceLevel.info,
        occurredAt: resumed,
        phase: state.phase,
        targetId: state.targetId,
        toolId: toolId,
        summary: readiness.requiresUserDecision
            ? '恢复 Agent Session，等待用户决策'
            : '恢复 Agent Session',
        detail: detailLines.join('\n'),
        evidenceChunkIds: state.evidenceChunkIds,
        policyIssueCodes: state.policyWarnings,
      ),
    );
  }
}

String _reasonText(String? reason) {
  final trimmed = reason?.trim();
  return trimmed == null || trimmed.isEmpty ? '未记录' : trimmed;
}
