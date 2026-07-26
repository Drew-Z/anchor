import 'learning_agent_checkpoint.dart';
import 'learning_agent_checkpoint_store.dart';
import 'learning_agent_planner_service.dart';
import 'learning_agent_resume_trace_contract.dart';
import 'learning_agent_resume_policy.dart';
import 'learning_agent_state.dart';
import 'learning_agent_state_transition_policy.dart';
import 'learning_agent_tool_registry.dart';
import 'learning_agent_trace.dart';
import 'learning_agent_user_decision.dart';

class LearningAgentRuntimeSession {
  final String sessionId;
  final DateTime startedAt;
  final LearningAgentPlan plan;
  final LearningAgentState state;
  final LearningAgentToolDefinition? selectedTool;
  final List<LearningAgentTraceEvent> traceEvents;
  final int checkpointRevision;

  const LearningAgentRuntimeSession({
    required this.sessionId,
    required this.startedAt,
    required this.plan,
    required this.state,
    required this.selectedTool,
    this.traceEvents = const [],
    this.checkpointRevision = 0,
  });

  String? get selectedToolId => selectedTool?.toolId;
  bool get hasSelectedTool => selectedTool != null;
}

class LearningAgentRuntimeResumeResult {
  final LearningAgentResumeReadiness readiness;
  final LearningAgentRuntimeSession? session;

  const LearningAgentRuntimeResumeResult({
    required this.readiness,
    this.session,
  });

  bool get canResume => session != null;
}

class LearningAgentRuntimeUserDecisionResult {
  final LearningAgentUserDecisionAction action;
  final LearningAgentCheckpoint checkpoint;
  final LearningAgentResumeReadiness readiness;
  final LearningAgentRuntimeSession? session;

  const LearningAgentRuntimeUserDecisionResult({
    required this.action,
    required this.checkpoint,
    required this.readiness,
    this.session,
  });

  bool get didResume => session != null;
}

class LearningAgentRuntime {
  final LearningAgentCheckpointStore checkpointStore;
  final LearningAgentToolRegistry toolRegistry;
  final LearningAgentResumeTraceContract resumeTraceContract;
  final LearningAgentStateTransitionPolicy stateTransitionPolicy;

  const LearningAgentRuntime({
    required this.checkpointStore,
    this.toolRegistry = const LearningAgentToolRegistry(),
    this.resumeTraceContract = const LearningAgentResumeTraceContract(),
    this.stateTransitionPolicy = const LearningAgentStateTransitionPolicy(),
  });

  LearningAgentRuntimeSession prepareSession({
    required LearningAgentPlan plan,
    DateTime? startedAt,
  }) {
    final nextAction = plan.nextAction;
    if (nextAction != null && !nextAction.executable) {
      throw StateError(
        'Cannot prepare Agent session: '
        '${nextAction.blockerMessage ?? 'next action is blocked'}.',
      );
    }
    if (nextAction?.resumesCheckpoint == true) {
      throw StateError(
        'Cannot prepare a new Agent session for a checkpoint resume action.',
      );
    }
    final started = startedAt ?? DateTime.now();
    final sessionId = started.microsecondsSinceEpoch.toString();
    final availableTools = toolRegistry.toolsForPlan(plan);
    final selectedTool = _selectedTool(plan);
    final targetId = _sessionTargetId(plan.sessionSummary);
    final state = LearningAgentState.initial(
      sessionId: sessionId,
      goal: plan.goal,
      targetId: targetId,
      focusPointId: plan.sessionSummary.focusPoint?.id,
      availableToolIds: availableTools.map((tool) => tool.toolId).toList(),
    ).transitionTo(
      LearningAgentPhase.plan,
      selectedToolId: selectedTool?.toolId,
    );
    final trace = LearningAgentTraceEvent(
      id: '${started.microsecondsSinceEpoch}_plan_created',
      sessionId: sessionId,
      goal: plan.goal,
      type: LearningAgentTraceEventType.planCreated,
      occurredAt: started,
      phase: LearningAgentPhase.plan,
      targetId: targetId,
      targetLabel: plan.sessionSummary.targetLabel,
      toolId: selectedTool?.toolId,
      summary: '生成 Agent Session 运行状态',
      detail: _planDetail(plan, selectedTool),
    );
    final tracedState = state.copyWith(traceEventIds: [trace.id]);

    return LearningAgentRuntimeSession(
      sessionId: sessionId,
      startedAt: started,
      plan: plan,
      state: tracedState,
      selectedTool: selectedTool,
      traceEvents: [trace],
    );
  }

  Future<LearningAgentCheckpoint> persistCheckpoint({
    required LearningAgentState state,
    required List<LearningAgentTraceEvent> traceEvents,
    required LearningAgentPlan plan,
    int checkpointRevision = 0,
  }) async {
    final incompatibility = _resumePlanIncompatibility(
      state: state,
      plan: plan,
      selectedTool: _toolForState(state),
    );
    if (incompatibility != null) {
      throw StateError('Cannot persist Agent checkpoint: $incompatibility');
    }
    final checkpoint = LearningAgentCheckpoint(
      state: state,
      traceEvents: traceEvents,
      plan: plan,
      revision: checkpointRevision,
    );
    return checkpointStore.save(checkpoint);
  }

  Future<LearningAgentCheckpoint> persistReflectionCheckpoint({
    required LearningAgentState state,
    required List<LearningAgentTraceEvent> traceEvents,
    required LearningAgentPlan plan,
    String? targetLabel,
    String? detail,
    DateTime? savedAt,
    int checkpointRevision = 0,
  }) {
    final completedAt = savedAt ?? DateTime.now();
    final completionTraceEvents = [
      ...traceEvents.where(
        (event) => event.type != LearningAgentTraceEventType.reflectionSaved,
      ),
      LearningAgentTraceEvent(
        id: '${completedAt.microsecondsSinceEpoch}_reflection_saved',
        sessionId: state.sessionId,
        goal: state.goal,
        type: LearningAgentTraceEventType.reflectionSaved,
        level: LearningAgentTraceLevel.info,
        occurredAt: completedAt,
        phase: stateTransitionPolicy.afterReflectionSaved(),
        targetId: state.targetId,
        targetLabel: targetLabel,
        toolId: 'save_agent_reflection',
        summary: '保存 Agent Session 复盘',
        detail: detail,
      ),
    ];
    final completionState = state.transitionTo(
      stateTransitionPolicy.afterReflectionSaved(),
      clearActiveToolOperation: true,
      traceEventIds: completionTraceEvents
          .map((event) => event.id)
          .toList(growable: false),
      updatedAt: completedAt,
    );
    return persistCheckpoint(
      state: completionState,
      traceEvents: completionTraceEvents,
      plan: plan,
      checkpointRevision: checkpointRevision,
    );
  }

  Future<LearningAgentRuntimeResumeResult> resumeCheckpoint(
    LearningAgentCheckpoint checkpoint, {
    String? reason,
    DateTime? resumedAt,
  }) async {
    final readiness = evaluateResumeCheckpoint(checkpoint);
    if (!readiness.canResume || readiness.requiresUserDecision) {
      return LearningAgentRuntimeResumeResult(readiness: readiness);
    }

    final state = checkpoint.state;
    final plan = checkpoint.plan!;
    final selectedTool = _toolForState(state);
    final draft = draftResumeTrace(
      state: state,
      selectedTool: selectedTool,
      reason: reason,
      resumedAt: resumedAt,
    );
    if (!draft.canRecord) {
      return LearningAgentRuntimeResumeResult(readiness: readiness);
    }

    final resumeEvent = draft.event!.copyWith(
      targetLabel: plan.sessionSummary.targetLabel,
    );
    final traceEvents = [...checkpoint.traceEvents, resumeEvent];
    final resumedState = state.transitionTo(
      state.phase,
      traceEventIds:
          traceEvents.map((event) => event.id).toList(growable: false),
      updatedAt: resumeEvent.occurredAt,
    );
    final resumedCheckpoint = await persistCheckpoint(
      state: resumedState,
      traceEvents: traceEvents,
      plan: plan,
      checkpointRevision: checkpoint.revision,
    );
    return LearningAgentRuntimeResumeResult(
      readiness: readiness,
      session: LearningAgentRuntimeSession(
        sessionId: state.sessionId,
        startedAt: state.createdAt,
        plan: plan,
        state: resumedCheckpoint.state,
        selectedTool: selectedTool,
        traceEvents: resumedCheckpoint.traceEvents,
        checkpointRevision: resumedCheckpoint.revision,
      ),
    );
  }

  Future<LearningAgentRuntimeUserDecisionResult> resolveUserDecision(
    LearningAgentCheckpoint checkpoint, {
    required LearningAgentUserDecisionAction action,
    String? note,
    DateTime? resolvedAt,
  }) async {
    final readiness = evaluateResumeCheckpoint(checkpoint);
    final request = checkpoint.state.pendingUserDecision;
    if (readiness.status != LearningAgentResumeStatus.waitingForUser ||
        request == null) {
      throw StateError(
        'Cannot resolve Agent user decision: ${readiness.message}',
      );
    }

    final plan = checkpoint.plan!;
    final decidedAt = resolvedAt ?? DateTime.now();
    final trimmedNote = note?.trim();
    if (action == LearningAgentUserDecisionAction.confirmToolCompleted &&
        request.reason != LearningAgentUserDecisionReason.toolOutcomeUnknown) {
      throw StateError(
        'Only an unknown tool outcome can be confirmed as completed.',
      );
    }
    final nextPhase = stateTransitionPolicy.afterUserDecision(
      checkpoint.state.phase,
      action,
    );
    final resolutionEvent = LearningAgentTraceEvent(
      id: '${decidedAt.microsecondsSinceEpoch}_user_decision_resolved',
      sessionId: checkpoint.sessionId,
      goal: checkpoint.state.goal,
      type: LearningAgentTraceEventType.userDecisionResolved,
      level: LearningAgentTraceLevel.info,
      occurredAt: decidedAt,
      phase: nextPhase,
      targetId: checkpoint.state.targetId,
      targetLabel: plan.sessionSummary.targetLabel,
      toolId: checkpoint.state.selectedToolId,
      summary: '用户决策：${action.label}',
      detail: [
        '决策 ID: ${request.id}',
        '请求原因: ${request.reason.label}',
        if (request.operationId != null) '工具 operation: ${request.operationId}',
        if (request.attemptId != null) '工具 attempt: ${request.attemptId}',
        '选择: ${action.label}',
        if (trimmedNote != null && trimmedNote.isNotEmpty) '备注: $trimmedNote',
      ].join('\n'),
      evidenceChunkIds: checkpoint.state.evidenceChunkIds,
      policyIssueCodes: checkpoint.state.policyWarnings,
    );
    final resolvedTraceEvents = [
      ...checkpoint.traceEvents,
      resolutionEvent,
    ];
    final resolvedState = checkpoint.state.transitionTo(
      nextPhase,
      clearActiveToolOperation:
          action != LearningAgentUserDecisionAction.continueSession,
      clearPendingUserDecision: true,
      traceEventIds:
          resolvedTraceEvents.map((event) => event.id).toList(growable: false),
      updatedAt: decidedAt,
    );
    final resolvedCheckpoint = await persistCheckpoint(
      state: resolvedState,
      traceEvents: resolvedTraceEvents,
      plan: plan,
      checkpointRevision: checkpoint.revision,
    );

    if (action == LearningAgentUserDecisionAction.cancelSession) {
      return LearningAgentRuntimeUserDecisionResult(
        action: action,
        checkpoint: resolvedCheckpoint,
        readiness: evaluateResumeCheckpoint(resolvedCheckpoint),
      );
    }

    final noteSuffix =
        trimmedNote == null || trimmedNote.isEmpty ? '' : '：$trimmedNote';
    final resumeReason =
        action == LearningAgentUserDecisionAction.confirmToolCompleted
            ? '用户确认工具已完成，进入复盘$noteSuffix'
            : '用户决定重新执行工具$noteSuffix';
    final resumeResult = await resumeCheckpoint(
      resolvedCheckpoint,
      reason: resumeReason,
      resumedAt: decidedAt,
    );
    final resumedSession = resumeResult.session;
    if (resumedSession == null) {
      throw StateError(
        'Agent user decision was saved but resume failed: '
        '${resumeResult.readiness.message}',
      );
    }
    return LearningAgentRuntimeUserDecisionResult(
      action: action,
      checkpoint: LearningAgentCheckpoint(
        state: resumedSession.state,
        traceEvents: resumedSession.traceEvents,
        plan: resumedSession.plan,
        revision: resumedSession.checkpointRevision,
      ),
      readiness: resumeResult.readiness,
      session: resumedSession,
    );
  }

  LearningAgentResumeReadiness evaluateResumeCheckpoint(
    LearningAgentCheckpoint checkpoint,
  ) {
    final state = checkpoint.state;
    final plan = checkpoint.plan;
    if (plan == null) {
      return const LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.missingPlan,
        canResume: false,
        title: '缺少计划快照',
        message: '这个旧 checkpoint 没有保存原学习计划，不能安全恢复。',
      );
    }

    final selectedTool = _toolForState(state);
    final policyReadiness = resumeTraceContract.resumePolicy.evaluate(
      state,
      selectedTool: selectedTool,
    );
    if (!policyReadiness.canResume) return policyReadiness;

    final incompatibility = _resumePlanIncompatibility(
      state: state,
      plan: plan,
      selectedTool: selectedTool,
    );
    if (incompatibility != null) {
      return LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.incompatiblePlan,
        canResume: false,
        title: '计划快照不兼容',
        message: incompatibility,
      );
    }
    return policyReadiness;
  }

  LearningAgentResumeTraceDraft draftResumeTrace({
    required LearningAgentState? state,
    LearningAgentToolDefinition? selectedTool,
    String? reason,
    DateTime? resumedAt,
  }) {
    return resumeTraceContract.draftResumeEvent(
      state: state,
      selectedTool: selectedTool,
      reason: reason,
      resumedAt: resumedAt,
    );
  }

  LearningAgentToolDefinition? _selectedTool(LearningAgentPlan plan) {
    final nextStep = plan.sessionSummary.nextStep;
    if (nextStep == null) return null;
    final actionToolId = plan.nextAction?.toolId;
    final tool = actionToolId == null
        ? toolRegistry.toolForStep(nextStep.type)
        : toolRegistry.toolForIdValue(actionToolId);
    if (tool == null || !tool.supportsGoal(plan.goal)) return null;
    if (!tool.supportsStep(nextStep.type)) return null;
    return tool;
  }

  LearningAgentToolDefinition? _toolForState(LearningAgentState state) {
    final toolId = state.selectedToolId;
    return toolId == null ? null : toolRegistry.toolForIdValue(toolId);
  }

  String? _resumePlanIncompatibility({
    required LearningAgentState state,
    required LearningAgentPlan plan,
    required LearningAgentToolDefinition? selectedTool,
  }) {
    if (plan.goal != state.goal || plan.sessionSummary.goal != state.goal) {
      return 'checkpoint state 与 plan snapshot 的学习目标不一致。';
    }
    final step = plan.sessionSummary.nextStep;
    final planTool = step == null ? null : toolRegistry.toolForStep(step.type);
    if (selectedTool == null || planTool?.toolId != selectedTool.toolId) {
      return 'checkpoint 记录的工具与 plan snapshot 下一步不一致。';
    }
    final nextActionToolId = plan.nextAction?.toolId;
    if (nextActionToolId != null && nextActionToolId != selectedTool.toolId) {
      return 'checkpoint 记录的工具与 next action snapshot 不一致。';
    }
    final decisionToolId = state.pendingUserDecision?.toolId;
    if (decisionToolId != null && decisionToolId != selectedTool.toolId) {
      return 'checkpoint 待用户决策的工具与当前选中工具不一致。';
    }
    if (_sessionTargetId(plan.sessionSummary) != state.targetId) {
      return 'checkpoint 记录的目标与 plan snapshot 不一致。';
    }
    if (plan.sessionSummary.focusPoint?.id != state.focusPointId) {
      return 'checkpoint 记录的焦点知识点与 plan snapshot 不一致。';
    }
    return null;
  }

  String _planDetail(
    LearningAgentPlan plan,
    LearningAgentToolDefinition? selectedTool,
  ) {
    final summary = plan.sessionSummary;
    return [
      '学习目标: ${summary.goal.label}',
      '下一步: ${summary.nextStep?.title ?? '无'}',
      '目标: ${summary.targetLabel}',
      '工具: ${selectedTool?.title ?? '未匹配工具'}',
      ...?plan.nextAction?.diagnosticLines(),
      '证据约束: ${summary.evidenceConstraint}',
      '路线步骤: ${plan.steps.length}',
      '推荐焦点: ${plan.focusPoints.length}',
    ].join('\n');
  }

  String? _sessionTargetId(LearningAgentSessionSummary summary) {
    return summary.practiceTarget?.routingId ??
        summary.focusPoint?.id ??
        _stepTypeId(summary.nextStep);
  }

  String? _stepTypeId(LearningAgentPlanStep? step) {
    if (step == null) return null;
    switch (step.type) {
      case LearningAgentStepType.importSources:
        return 'import_sources';
      case LearningAgentStepType.verifyQuestions:
        return 'verify_questions';
      case LearningAgentStepType.handleFollowUps:
        return 'handle_followups';
      case LearningAgentStepType.tutor:
        return 'tutor';
      case LearningAgentStepType.interview:
        return 'interview';
      case LearningAgentStepType.practice:
        return 'practice';
      case LearningAgentStepType.review:
        return 'review';
    }
  }
}
