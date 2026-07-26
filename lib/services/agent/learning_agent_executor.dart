import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../features/agent/agent_session_history_screen.dart';
import '../../features/agent/interview_session_screen.dart';
import '../../features/agent/programming_exercise_screen.dart';
import '../../features/agent/review_agent_screen.dart';
import '../../features/agent/tutor_session_screen.dart';
import '../../features/ingestion/ingestion_screen.dart';
import '../../features/knowledge_base/knowledge_base_screen.dart';
import '../../features/learning/quiz_screen.dart';
import 'agent_session_memory_index.dart';
import 'grounded_learning_context_service.dart';
import 'learning_agent_policy.dart';
import 'learning_agent_practice_target.dart';
import 'learning_agent_planner_service.dart';
import 'learning_agent_resume_policy.dart';
import 'learning_agent_runtime_contract_diagnostics.dart';
import 'learning_agent_state_diagnostics.dart';
import 'learning_agent_state.dart';
import 'learning_agent_state_transition_policy.dart';
import 'learning_agent_tool_input_snapshot.dart';
import 'learning_agent_tool_registry.dart';
import 'learning_agent_trace.dart';
import 'learning_agent_user_decision.dart';

typedef LearningAgentToolStartCheckpointWriter = Future<void> Function(
  LearningAgentState state,
  List<LearningAgentTraceEvent> traceEvents,
);

class LearningAgentToolStartCheckpointException implements Exception {
  final Object cause;

  const LearningAgentToolStartCheckpointException(this.cause);

  @override
  String toString() {
    return 'Agent tool-start checkpoint 保存失败，工具尚未调用: $cause';
  }
}

enum LearningAgentExecutionStatus {
  completed,
  canceled,
  blocked,
  failed;
}

class LearningAgentExecutionContext {
  final BuildContext buildContext;
  final WidgetRef ref;
  final LearningAgentPlan plan;
  final String sessionId;
  final LearningAgentState initialState;
  final List<LearningAgentTraceEvent> initialTraceEvents;
  final LearningAgentToolStartCheckpointWriter persistToolStartCheckpoint;

  const LearningAgentExecutionContext({
    required this.buildContext,
    required this.ref,
    required this.plan,
    required this.sessionId,
    required this.initialState,
    this.initialTraceEvents = const [],
    required this.persistToolStartCheckpoint,
  });
}

class LearningAgentExecutionResult {
  final LearningAgentExecutionStatus status;
  final LearningAgentPlanStep? step;
  final LearningAgentToolDefinition? tool;
  final String? message;
  final String? attemptedFollowUpQuestion;
  final String? completedFollowUpQuestion;
  final LearningAgentPolicyResult? policyResult;
  final String? diagnosticTitle;
  final List<String> diagnosticLines;
  final List<LearningAgentTraceEvent> traceEvents;
  final LearningAgentState? state;
  final bool shouldRefreshInputs;
  final bool shouldShowCompletionReview;
  final Object? error;

  const LearningAgentExecutionResult({
    required this.status,
    this.step,
    this.tool,
    this.message,
    this.attemptedFollowUpQuestion,
    this.completedFollowUpQuestion,
    this.policyResult,
    this.diagnosticTitle,
    this.diagnosticLines = const [],
    this.traceEvents = const [],
    this.state,
    this.shouldRefreshInputs = false,
    this.shouldShowCompletionReview = false,
    this.error,
  });

  bool get isCompleted => status == LearningAgentExecutionStatus.completed;
  bool get isCanceled => status == LearningAgentExecutionStatus.canceled;
  bool get isBlocked => status == LearningAgentExecutionStatus.blocked;
  bool get isFailed => status == LearningAgentExecutionStatus.failed;

  factory LearningAgentExecutionResult.completed({
    required LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
    String? attemptedFollowUpQuestion,
    String? completedFollowUpQuestion,
    List<LearningAgentTraceEvent> traceEvents = const [],
    LearningAgentState? state,
    bool shouldRefreshInputs = true,
    bool shouldShowCompletionReview = true,
  }) {
    return LearningAgentExecutionResult(
      status: LearningAgentExecutionStatus.completed,
      step: step,
      tool: tool,
      attemptedFollowUpQuestion: attemptedFollowUpQuestion,
      completedFollowUpQuestion: completedFollowUpQuestion,
      traceEvents: traceEvents,
      state: state,
      shouldRefreshInputs: shouldRefreshInputs,
      shouldShowCompletionReview: shouldShowCompletionReview,
    );
  }

  factory LearningAgentExecutionResult.canceled({
    LearningAgentPlanStep? step,
    LearningAgentToolDefinition? tool,
    String? message,
    List<LearningAgentTraceEvent> traceEvents = const [],
    LearningAgentState? state,
    bool shouldRefreshInputs = false,
  }) {
    return LearningAgentExecutionResult(
      status: LearningAgentExecutionStatus.canceled,
      step: step,
      tool: tool,
      message: message,
      traceEvents: traceEvents,
      state: state,
      shouldRefreshInputs: shouldRefreshInputs,
    );
  }

  factory LearningAgentExecutionResult.failed({
    LearningAgentPlanStep? step,
    LearningAgentToolDefinition? tool,
    required String message,
    String? diagnosticTitle,
    List<String> diagnosticLines = const [],
    List<LearningAgentTraceEvent> traceEvents = const [],
    LearningAgentState? state,
    Object? error,
  }) {
    return LearningAgentExecutionResult(
      status: LearningAgentExecutionStatus.failed,
      step: step,
      tool: tool,
      message: message,
      diagnosticTitle: diagnosticTitle,
      diagnosticLines: diagnosticLines,
      traceEvents: traceEvents,
      state: state,
      error: error,
    );
  }

  factory LearningAgentExecutionResult.blocked({
    required LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
    required LearningAgentPolicyResult policyResult,
    required List<String> diagnosticLines,
    List<LearningAgentTraceEvent> traceEvents = const [],
    LearningAgentState? state,
  }) {
    final blockingIssues = policyResult.blockingIssues;
    final message = blockingIssues.isEmpty
        ? '执行前检查未通过。'
        : policyResult.blockingMessages.join('\n');
    return LearningAgentExecutionResult(
      status: LearningAgentExecutionStatus.blocked,
      step: step,
      tool: tool,
      message: message,
      policyResult: policyResult,
      diagnosticTitle: 'Agent Session 执行前策略阻断',
      diagnosticLines: diagnosticLines,
      traceEvents: traceEvents,
      state: state,
    );
  }

  LearningAgentExecutionResult withTraceEvents(
    List<LearningAgentTraceEvent> traceEvents, {
    LearningAgentState? state,
  }) {
    return LearningAgentExecutionResult(
      status: status,
      step: step,
      tool: tool,
      message: message,
      attemptedFollowUpQuestion: attemptedFollowUpQuestion,
      completedFollowUpQuestion: completedFollowUpQuestion,
      policyResult: policyResult,
      diagnosticTitle: diagnosticTitle,
      diagnosticLines: diagnosticLines,
      traceEvents: traceEvents,
      state: state ?? this.state,
      shouldRefreshInputs: shouldRefreshInputs,
      shouldShowCompletionReview: shouldShowCompletionReview,
      error: error,
    );
  }
}

abstract class LearningAgentExecutor {
  Future<LearningAgentExecutionResult> execute(
    LearningAgentExecutionContext context,
  );
}

class DefaultLearningAgentExecutor implements LearningAgentExecutor {
  final LearningAgentToolRegistry toolRegistry;
  final LearningAgentPolicy policy;
  final LearningAgentStateTransitionPolicy stateTransitionPolicy;

  const DefaultLearningAgentExecutor({
    this.toolRegistry = const LearningAgentToolRegistry(),
    this.policy = const LearningAgentPolicy(),
    this.stateTransitionPolicy = const LearningAgentStateTransitionPolicy(),
  });

  @override
  Future<LearningAgentExecutionResult> execute(
    LearningAgentExecutionContext context,
  ) async {
    final step = context.plan.sessionSummary.nextStep;
    if (step == null) {
      return LearningAgentExecutionResult.canceled(
        message: '当前没有可执行的 Agent Session',
      );
    }

    final tool = toolRegistry.toolForStep(step.type);
    final traceRecorder = LearningAgentTraceRecorder(
      initialEvents: context.initialTraceEvents,
      initialState: context.initialState,
    );
    traceRecorder.record(
      _traceEvent(
        context,
        tool,
        LearningAgentTraceEventType.toolSelected,
        '选择执行工具：${tool?.title ?? step.title}',
        detail: _toolDetail(tool),
      ),
    );
    try {
      final policyCheck = await _checkPolicyBeforeExecution(context, step);
      traceRecorder.record(
        _traceEvent(
          context,
          tool,
          LearningAgentTraceEventType.policyChecked,
          policyCheck.result.isAllowed ? '执行前策略检查通过' : '执行前策略检查未通过',
          level: policyCheck.result.isAllowed
              ? LearningAgentTraceLevel.info
              : LearningAgentTraceLevel.error,
          phase: LearningAgentPhase.verify,
          detail: _policyDetail(
            policyCheck.result,
            groundedContext: policyCheck.groundedContext,
          ),
          evidenceChunkIds: policyCheck.evidenceChunkIds,
          policyIssueCodes: policyCheck.policyIssueCodes,
        ),
        phase: stateTransitionPolicy.afterPolicyCheck(policyCheck.result),
        evidenceChunkIds: policyCheck.evidenceChunkIds,
        clearActiveToolOperation: !policyCheck.result.isAllowed,
        clearPendingUserDecision: !policyCheck.result.isAllowed,
        policyWarnings: policyCheck.policyIssueCodes,
      );

      if (!policyCheck.result.isAllowed) {
        final traceEvents = traceRecorder.events;
        return LearningAgentExecutionResult.blocked(
          step: step,
          tool: tool,
          policyResult: policyCheck.result,
          diagnosticLines: [
            ..._policyDiagnosticLines(
              context,
              step,
              tool,
              policyCheck.result,
              state: traceRecorder.state,
            ),
            ...?policyCheck.groundedContext?.diagnosticLines,
            ...learningAgentTraceSummaryLines(traceEvents),
          ],
          traceEvents: traceEvents,
          state: traceRecorder.state,
        );
      }

      final toolTitle = tool?.title ?? step.title;
      final toolId =
          tool?.toolId ?? context.initialState.selectedToolId ?? step.type.name;
      final currentToolInput = LearningAgentToolInputSnapshot(
        toolId: toolId,
        targetId: context.initialState.targetId,
        focusPointId: context.initialState.focusPointId,
        evidenceChunkIds: policyCheck.evidenceChunkIds,
      );
      final existingOperationId =
          context.initialState.activeToolOperationId?.trim();
      final existingToolInput = context.initialState.activeToolInputSnapshot ??
          (existingOperationId == null || existingOperationId.isEmpty
              ? null
              : LearningAgentToolInputSnapshot(
                  toolId: toolId,
                  targetId: context.initialState.targetId,
                  focusPointId: context.initialState.focusPointId,
                  evidenceChunkIds: context.initialState.evidenceChunkIds,
                ));
      if (existingToolInput != null &&
          !existingToolInput.hasSameRoutingInput(currentToolInput)) {
        final mismatchLines = existingToolInput.mismatchLines(currentToolInput);
        traceRecorder.record(
          _traceEvent(
            context,
            tool,
            LearningAgentTraceEventType.toolInputRejected,
            '拒绝使用不同输入重试工具：$toolTitle',
            level: LearningAgentTraceLevel.error,
            phase: LearningAgentPhase.blocked,
            detail: [
              '工具 operation: $existingOperationId',
              ...mismatchLines,
            ].join('\n'),
            evidenceChunkIds: policyCheck.evidenceChunkIds,
          ),
          phase: LearningAgentPhase.blocked,
          clearPendingUserDecision: true,
          clearActiveToolOperation: true,
        );
        final traceEvents = traceRecorder.events;
        return LearningAgentExecutionResult.failed(
          step: step,
          tool: tool,
          message: '同一工具 operation 的重试输入发生变化，请创建新的会话操作。',
          diagnosticTitle: 'Agent 工具重试输入不一致',
          diagnosticLines: [
            ...mismatchLines.map((line) => '输入差异: $line'),
            ...learningAgentStateDiagnosticLines(
              traceRecorder.state,
              selectedTool: tool,
              toolRegistry: toolRegistry,
            ),
            ...learningAgentTraceSummaryLines(traceEvents),
          ],
          traceEvents: traceEvents,
          state: traceRecorder.state,
        );
      }
      final startedEvent = _traceEvent(
        context,
        tool,
        LearningAgentTraceEventType.toolStarted,
        '开始执行工具：$toolTitle',
        phase: LearningAgentPhase.act,
        detail: [
          '证据要求: ${tool?.evidenceRequirement.label ?? '未记录'}',
          if (policyCheck.groundedContext != null)
            'Grounded context ID: ${policyCheck.groundedContext!.contextId}',
        ].join('\n'),
        evidenceChunkIds: policyCheck.evidenceChunkIds,
      );
      final operationId =
          existingOperationId == null || existingOperationId.isEmpty
              ? '${context.sessionId}_'
                  '${startedEvent.id}_operation'
              : existingOperationId;
      final operationInput = existingToolInput ?? currentToolInput;
      final toolStartedEvent = startedEvent.copyWith(
        detail: [
          startedEvent.detail,
          '工具 operation: $operationId',
          '工具输入: ${operationInput.toStorageValue()}',
        ].whereType<String>().join('\n'),
      );
      final unknownOutcomeRequest =
          LearningAgentUserDecisionRequest.toolOutcomeUnknown(
        sessionId: context.sessionId,
        toolTitle: toolTitle,
        toolId: tool?.toolId,
        operationId: operationId,
        attemptId: toolStartedEvent.id,
        requestedAt: toolStartedEvent.occurredAt,
      );
      traceRecorder.record(
        toolStartedEvent,
        phase: stateTransitionPolicy.afterToolStarted(),
        evidenceChunkIds: policyCheck.evidenceChunkIds,
        activeToolOperationId: operationId,
        activeToolInputSnapshot: operationInput,
        pendingUserDecision: unknownOutcomeRequest,
      );
      try {
        await context.persistToolStartCheckpoint(
          traceRecorder.state!,
          traceRecorder.events,
        );
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          LearningAgentToolStartCheckpointException(error),
          stackTrace,
        );
      }

      late final LearningAgentExecutionResult result;
      switch (step.type) {
        case LearningAgentStepType.importSources:
          result = await _openImportSources(context, step, tool);
          break;
        case LearningAgentStepType.verifyQuestions:
          result = await _openQuestionVerification(context, step, tool);
          break;
        case LearningAgentStepType.handleFollowUps:
          result = await _openFollowUpHistory(context, step, tool);
          break;
        case LearningAgentStepType.tutor:
          result = await _openTutorSession(context, step, tool);
          break;
        case LearningAgentStepType.interview:
          result = await _openInterviewSession(context, step, tool);
          break;
        case LearningAgentStepType.practice:
          result = await _openVerifiedPractice(
            context,
            step,
            tool,
            policyCheck.practiceTarget,
          );
          break;
        case LearningAgentStepType.review:
          result = await _openReviewSession(context, step, tool);
          break;
      }

      if (result.isCanceled) {
        traceRecorder.record(
          _traceEvent(
            context,
            tool,
            LearningAgentTraceEventType.userInterrupted,
            '工具执行被中断：$toolTitle',
            phase: LearningAgentPhase.act,
            detail: result.message,
            evidenceChunkIds: policyCheck.evidenceChunkIds,
          ),
          phase: stateTransitionPolicy.afterToolResult(
            isCanceled: true,
            shouldShowCompletionReview: false,
          ),
          evidenceChunkIds: policyCheck.evidenceChunkIds,
        );
        final decisionRequest =
            LearningAgentUserDecisionRequest.toolInterrupted(
          sessionId: context.sessionId,
          toolTitle: toolTitle,
          toolId: tool?.toolId,
          operationId: operationId,
        );
        traceRecorder.record(
          _traceEvent(
            context,
            tool,
            LearningAgentTraceEventType.userDecisionRequested,
            '请求用户决定是否继续执行：$toolTitle',
            level: LearningAgentTraceLevel.warning,
            phase: LearningAgentPhase.act,
            detail: [
              '决策 ID: ${decisionRequest.id}',
              '原因: ${decisionRequest.reason.label}',
              '工具 operation: $operationId',
              decisionRequest.prompt,
            ].join('\n'),
            evidenceChunkIds: policyCheck.evidenceChunkIds,
          ),
          phase: LearningAgentPhase.act,
          evidenceChunkIds: policyCheck.evidenceChunkIds,
          pendingUserDecision: decisionRequest,
        );
      } else {
        traceRecorder.record(
          _traceEvent(
            context,
            tool,
            LearningAgentTraceEventType.toolCompleted,
            '工具执行完成：${tool?.title ?? step.title}',
            phase: LearningAgentPhase.act,
            detail: result.message,
            evidenceChunkIds: policyCheck.evidenceChunkIds,
          ),
          phase: stateTransitionPolicy.afterToolResult(
            isCanceled: false,
            shouldShowCompletionReview: result.shouldShowCompletionReview,
          ),
          evidenceChunkIds: policyCheck.evidenceChunkIds,
          clearPendingUserDecision: true,
          clearActiveToolOperation: true,
        );
      }
      return result.withTraceEvents(
        traceRecorder.events,
        state: traceRecorder.state,
      );
    } on LearningAgentToolStartCheckpointException {
      rethrow;
    } catch (error) {
      final title = tool?.failureDiagnosticTitle ?? 'Agent Session 启动失败';
      traceRecorder.record(
        _traceEvent(
          context,
          tool,
          LearningAgentTraceEventType.toolFailed,
          title,
          level: LearningAgentTraceLevel.error,
          phase: LearningAgentPhase.act,
          detail: error.toString(),
        ),
        phase: stateTransitionPolicy.afterToolFailure(),
        clearPendingUserDecision: true,
        clearActiveToolOperation: true,
      );
      final traceEvents = traceRecorder.events;
      return LearningAgentExecutionResult.failed(
        step: step,
        tool: tool,
        message: '$title: $error',
        diagnosticTitle: title,
        diagnosticLines: [
          ...learningAgentStateDiagnosticLines(
            traceRecorder.state,
            selectedTool: tool,
            toolRegistry: toolRegistry,
          ),
          ...learningAgentResumeReadinessDiagnosticLines(
            traceRecorder.state,
            selectedTool: tool,
          ),
          ...learningAgentRuntimeContractChecklistLines(
            plan: context.plan,
            state: traceRecorder.state,
            selectedTool: tool,
            traceEvents: traceEvents,
          ),
          ...learningAgentTraceSummaryLines(traceEvents),
        ],
        traceEvents: traceEvents,
        state: traceRecorder.state,
        error: error,
      );
    }
  }

  Future<LearningAgentExecutionResult> _openImportSources(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
  ) async {
    await Navigator.of(context.buildContext).push(
      MaterialPageRoute(builder: (_) => const IngestionScreen()),
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }
    return LearningAgentExecutionResult.completed(step: step, tool: tool);
  }

  Future<LearningAgentExecutionResult> _openQuestionVerification(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
  ) async {
    final targetId = context.plan.nextAction?.targetId;
    final programmingPrefix =
        '${LearningAgentPracticeTargetType.programmingExercise.value}:';
    if (targetId != null && targetId.startsWith(programmingPrefix)) {
      final exerciseId = targetId.substring(programmingPrefix.length);
      final exercise = await context.ref
          .read(programmingExerciseRepositoryProvider)
          .getExercise(exerciseId);
      final point = exercise == null
          ? null
          : await context.ref
              .read(knowledgePointRepositoryProvider)
              .getKnowledgePoint(exercise.knowledgePointId);
      if (exercise == null || point == null) {
        throw StateError('待核验编程练习已不可用');
      }
      if (!context.buildContext.mounted) {
        return LearningAgentExecutionResult.canceled(step: step, tool: tool);
      }
      await Navigator.of(context.buildContext).push(
        MaterialPageRoute(
          builder: (_) => ProgrammingExerciseScreen(
            knowledgePoint: point,
            initialExerciseId: exercise.id,
          ),
        ),
      );
      if (!context.buildContext.mounted) {
        return LearningAgentExecutionResult.canceled(step: step, tool: tool);
      }
      return LearningAgentExecutionResult.completed(step: step, tool: tool);
    }

    await Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (_) => const KnowledgeBaseScreen(initialTabIndex: 4),
      ),
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }
    return LearningAgentExecutionResult.completed(step: step, tool: tool);
  }

  Future<LearningAgentExecutionResult> _openFollowUpHistory(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
  ) async {
    await Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (_) => AgentSessionHistoryScreen(
          initialGoal: context.plan.goal,
          initialOnlyWithFollowUp: true,
        ),
      ),
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(
        step: step,
        tool: tool,
        shouldRefreshInputs: true,
      );
    }
    return LearningAgentExecutionResult.completed(
      step: step,
      tool: tool,
      shouldRefreshInputs: true,
      shouldShowCompletionReview: false,
    );
  }

  Future<LearningAgentExecutionResult> _openTutorSession(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
  ) async {
    final initialPoint = await _loadTopFocusPoint(context);
    final followUpQuestion = await _loadLatestFollowUpQuestion(
      context,
      _sessionTargetId(context.plan.sessionSummary),
    );
    final beforeCount = await _completedSessionCount(
      context,
      LearningSessionMode.tutor,
      initialPoint?.id,
      followUpQuestion,
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }

    await Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (_) => TutorSessionScreen(
          initialPoint: initialPoint,
          initialFollowUpQuestion: followUpQuestion,
        ),
      ),
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }

    final completedFollowUpQuestion = await _completedFollowUpQuestion(
      context,
      mode: LearningSessionMode.tutor,
      pointId: initialPoint?.id,
      question: followUpQuestion,
      beforeCount: beforeCount,
    );
    return LearningAgentExecutionResult.completed(
      step: step,
      tool: tool,
      attemptedFollowUpQuestion: followUpQuestion,
      completedFollowUpQuestion: completedFollowUpQuestion,
    );
  }

  Future<LearningAgentExecutionResult> _openInterviewSession(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
  ) async {
    final initialPoint = await _loadTopFocusPoint(context);
    final followUpQuestion = await _loadLatestFollowUpQuestion(
      context,
      _sessionTargetId(context.plan.sessionSummary),
    );
    final beforeCount = await _completedSessionCount(
      context,
      LearningSessionMode.interview,
      initialPoint?.id,
      followUpQuestion,
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }

    await Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (_) => InterviewSessionScreen(
          initialPoint: initialPoint,
          initialFollowUpQuestion: followUpQuestion,
        ),
      ),
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }

    final completedFollowUpQuestion = await _completedFollowUpQuestion(
      context,
      mode: LearningSessionMode.interview,
      pointId: initialPoint?.id,
      question: followUpQuestion,
      beforeCount: beforeCount,
    );
    return LearningAgentExecutionResult.completed(
      step: step,
      tool: tool,
      attemptedFollowUpQuestion: followUpQuestion,
      completedFollowUpQuestion: completedFollowUpQuestion,
    );
  }

  Future<LearningAgentExecutionResult> _openVerifiedPractice(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
    _ResolvedPracticeTarget? selection,
  ) async {
    final target = selection?.actualTarget;
    if (target == null) {
      throw StateError('已核验练习目标不可用');
    }
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }

    switch (target.type) {
      case LearningAgentPracticeTargetType.question:
        final question = selection?.question;
        if (question == null) {
          throw StateError('已核验普通题不可用');
        }
        await Navigator.of(context.buildContext).push(
          MaterialPageRoute(
            builder: (_) => QuizScreen(questions: [question]),
          ),
        );
        break;
      case LearningAgentPracticeTargetType.programmingExercise:
        final point = selection?.knowledgePoint;
        final exercise = selection?.programmingExercise;
        if (point == null || exercise == null) {
          throw StateError('已核验编程练习不可用');
        }
        await Navigator.of(context.buildContext).push(
          MaterialPageRoute(
            builder: (_) => ProgrammingExerciseScreen(
              knowledgePoint: point,
              initialExerciseId: exercise.id,
            ),
          ),
        );
        break;
    }
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }
    return LearningAgentExecutionResult.completed(step: step, tool: tool);
  }

  Future<LearningAgentExecutionResult> _openReviewSession(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
  ) async {
    final initialPoint = await _loadTopFocusPoint(context);
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }
    await Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (_) => ReviewAgentScreen(initialPoint: initialPoint),
      ),
    );
    if (!context.buildContext.mounted) {
      return LearningAgentExecutionResult.canceled(step: step, tool: tool);
    }
    return LearningAgentExecutionResult.completed(step: step, tool: tool);
  }

  Future<KnowledgePoint?> _loadTopFocusPoint(
    LearningAgentExecutionContext context,
  ) async {
    final focusPointId = _focusPointId(context.plan);
    if (focusPointId == null) return null;
    return context.ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePoint(focusPointId);
  }

  Future<_PolicyCheckSnapshot> _checkPolicyBeforeExecution(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
  ) async {
    switch (step.type) {
      case LearningAgentStepType.importSources:
      case LearningAgentStepType.handleFollowUps:
        return _PolicyCheckSnapshot(
          result: policy.checkStep(
            stepType: step.type,
            targetId: _sessionTargetId(context.plan.sessionSummary),
            targetLabel: context.plan.sessionSummary.targetLabel,
          ),
        );
      case LearningAgentStepType.verifyQuestions:
        return _checkVerificationTarget(context, step);
      case LearningAgentStepType.tutor:
      case LearningAgentStepType.interview:
        final focusPointId = _focusPointId(context.plan);
        final groundedContext = await _groundedContextForPoint(
          context,
          focusPointId,
          step.type == LearningAgentStepType.tutor
              ? GroundedLearningSurface.tutor
              : GroundedLearningSurface.interview,
        );
        final result = policy
            .checkStep(
              stepType: step.type,
              targetId: focusPointId,
              targetLabel: context.plan.sessionSummary.targetLabel,
              evidenceChunks: groundedContext.chunks,
            )
            .merge(policy.checkGroundedContext(groundedContext));
        return _PolicyCheckSnapshot(
          result: result,
          evidenceChunkIds: groundedContext.chunkIds,
          groundedContext: groundedContext,
        );
      case LearningAgentStepType.practice:
      case LearningAgentStepType.review:
        final practiceTarget = await _resolvePracticeTarget(context);
        if (practiceTarget == null &&
            context.plan.sessionSummary.practiceTarget == null) {
          final questions = await _practiceQuestionsForPlan(context);
          return _PolicyCheckSnapshot(
            result: policy.checkStep(
              stepType: step.type,
              targetId: _focusPointId(context.plan),
              targetLabel: context.plan.sessionSummary.targetLabel,
              questions: questions,
            ),
            evidenceChunkIds: _uniqueStrings(
              questions.expand((question) => question.citationIds),
            ),
          );
        }
        final groundedContext = practiceTarget?.actualTarget?.type ==
                LearningAgentPracticeTargetType.programmingExercise
            ? await _groundedContextForPracticeTarget(
                context,
                practiceTarget!,
              )
            : null;
        var result = policy.checkStep(
          stepType: step.type,
          targetId: _focusPointId(context.plan),
          targetLabel: context.plan.sessionSummary.targetLabel,
          plannedPracticeTarget: context.plan.sessionSummary.practiceTarget ??
              practiceTarget?.plannedTarget,
          actualPracticeTarget: practiceTarget?.actualTarget,
        );
        if (groundedContext != null) {
          result = result.merge(policy.checkGroundedContext(groundedContext));
        }
        return _PolicyCheckSnapshot(
          result: result,
          evidenceChunkIds: _uniqueStrings(
            groundedContext?.chunkIds ??
                practiceTarget?.actualTarget?.citationIds ??
                const [],
          ),
          practiceTarget: practiceTarget,
          groundedContext: groundedContext,
        );
    }
  }

  Future<_PolicyCheckSnapshot> _checkVerificationTarget(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
  ) async {
    final targetId = context.plan.nextAction?.targetId;
    if (targetId == null || !targetId.contains(':')) {
      return _PolicyCheckSnapshot(
        result: policy.checkStep(
          stepType: step.type,
          targetId: targetId,
          targetLabel: context.plan.sessionSummary.targetLabel,
        ),
      );
    }
    final separator = targetId.indexOf(':');
    final type = targetId.substring(0, separator);
    final id = targetId.substring(separator + 1);
    if (id.isEmpty) {
      return _verificationTargetBlock(
        code: 'verification_target_missing_id',
        message: '待核验动作没有保存目标 ID。',
      );
    }

    if (type == LearningAgentPracticeTargetType.question.value) {
      final questions =
          await context.ref.read(questionRepositoryProvider).getAllQuestions();
      Question? question;
      for (final candidate in questions) {
        if (candidate.id == id) {
          question = candidate;
          break;
        }
      }
      if (question == null) {
        return _verificationTargetBlock(
          code: 'verification_question_missing',
          message: '计划中的待核验题目已不存在。',
        );
      }
      if (question.sourceStatus != SourceStatus.pending) {
        return _verificationTargetBlock(
          code: 'verification_question_state_changed',
          message: '计划中的题目已不再处于待核验状态，请重新规划。',
        );
      }
      return const _PolicyCheckSnapshot(
        result: LearningAgentPolicyResult(),
      );
    }

    if (type == LearningAgentPracticeTargetType.programmingExercise.value) {
      final exercise = await context.ref
          .read(programmingExerciseRepositoryProvider)
          .getExercise(id);
      if (exercise == null) {
        return _verificationTargetBlock(
          code: 'verification_exercise_missing',
          message: '计划中的待核验编程练习已不存在。',
        );
      }
      if (exercise.sourceStatus != SourceStatus.pending) {
        return _verificationTargetBlock(
          code: 'verification_exercise_state_changed',
          message: '计划中的编程练习已不再处于待核验状态，请重新规划。',
        );
      }
      final point = await context.ref
          .read(knowledgePointRepositoryProvider)
          .getKnowledgePoint(exercise.knowledgePointId);
      if (point == null) {
        return _verificationTargetBlock(
          code: 'verification_exercise_point_missing',
          message: '待核验编程练习绑定的知识点已不存在。',
        );
      }
      return const _PolicyCheckSnapshot(
        result: LearningAgentPolicyResult(),
      );
    }

    return _verificationTargetBlock(
      code: 'verification_target_type_unknown',
      message: '待核验动作包含未知目标类型 $type。',
    );
  }

  _PolicyCheckSnapshot _verificationTargetBlock({
    required String code,
    required String message,
  }) {
    return _PolicyCheckSnapshot(
      result: LearningAgentPolicyResult(
        issues: [
          LearningAgentPolicyIssue(
            code: code,
            title: '待核验目标不可执行',
            message: message,
            severity: LearningAgentPolicySeverity.blocker,
            suggestedAction: LearningAgentPolicyAction.verifyQuestions,
          ),
        ],
      ),
    );
  }

  Future<GroundedLearningContext> _groundedContextForPoint(
    LearningAgentExecutionContext context,
    String? pointId,
    GroundedLearningSurface surface,
  ) async {
    final normalizedPointId = pointId?.trim() ?? '';
    final point = normalizedPointId.isEmpty
        ? null
        : await context.ref
            .read(knowledgePointRepositoryProvider)
            .getKnowledgePoint(normalizedPointId);
    final chunks = await _evidenceChunksForPoint(context, normalizedPointId);
    final sources = await _sourcesForChunks(context, chunks);
    return context.ref.read(groundedLearningContextServiceProvider).select(
          targetId: normalizedPointId,
          knowledgePoint: point,
          surface: surface,
          candidates: chunks
              .map(
                (chunk) => GroundedLearningContextCandidate(
                  chunk: chunk,
                  reasons: const [
                    GroundedLearningContextReason.targetRelation,
                  ],
                ),
              )
              .toList(growable: false),
          sources: sources,
        );
  }

  Future<GroundedLearningContext> _groundedContextForPracticeTarget(
    LearningAgentExecutionContext context,
    _ResolvedPracticeTarget selection,
  ) async {
    final target = selection.actualTarget!;
    final chunks = <SourceChunk>[];
    for (final citationId in target.citationIds) {
      final chunk = await context.ref
          .read(sourceChunkRepositoryProvider)
          .getSourceChunk(citationId);
      if (chunk != null) chunks.add(chunk);
    }
    final sources = await _sourcesForChunks(context, chunks);
    return context.ref.read(groundedLearningContextServiceProvider).select(
          targetId: target.id,
          knowledgePoint: selection.knowledgePoint,
          surface: GroundedLearningSurface.programmingExerciseEvaluation,
          candidates: chunks
              .map(
                (chunk) => GroundedLearningContextCandidate(
                  chunk: chunk,
                  reasons: const [
                    GroundedLearningContextReason.practiceCitation,
                  ],
                ),
              )
              .toList(growable: false),
          sources: sources,
          requiredCitationIds: target.citationIds.toSet(),
          limit: target.citationIds.length,
        );
  }

  Future<List<Source>> _sourcesForChunks(
    LearningAgentExecutionContext context,
    Iterable<SourceChunk> chunks,
  ) async {
    final sources = <String, Source>{};
    for (final sourceId in chunks.map((chunk) => chunk.sourceId).toSet()) {
      final source = await context.ref.read(sourceProvider(sourceId).future);
      if (source != null) sources[source.id] = source;
    }
    return sources.values.toList(growable: false);
  }

  Future<List<SourceChunk>> _evidenceChunksForPoint(
    LearningAgentExecutionContext context,
    String? pointId,
  ) async {
    if (pointId == null || pointId.trim().isEmpty) return const [];

    final relations = await context.ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePointSources(pointId);
    final chunks = <SourceChunk>[];
    for (final relation in relations) {
      final chunk = await context.ref
          .read(sourceChunkRepositoryProvider)
          .getSourceChunk(relation.sourceChunkId);
      if (chunk != null) chunks.add(chunk);
    }
    return chunks;
  }

  Future<_ResolvedPracticeTarget?> _resolvePracticeTarget(
    LearningAgentExecutionContext context,
  ) async {
    var plannedTarget = context.plan.sessionSummary.practiceTarget;
    if (plannedTarget == null) {
      final targets =
          await context.ref.read(verifiedPracticeTargetsProvider.future);
      plannedTarget = _fallbackPracticeTarget(
        targets,
        _focusPointId(context.plan),
      );
    }
    if (plannedTarget == null) return null;

    switch (plannedTarget.type) {
      case LearningAgentPracticeTargetType.question:
        final questions = await context.ref
            .read(questionRepositoryProvider)
            .getAllQuestions();
        Question? question;
        for (final candidate in questions) {
          if (candidate.id == plannedTarget.id) {
            question = candidate;
            break;
          }
        }
        if (question == null) {
          return _ResolvedPracticeTarget(plannedTarget: plannedTarget);
        }
        final actualTarget = LearningAgentPracticeTarget.fromQuestion(question);
        final point = await context.ref
            .read(knowledgePointRepositoryProvider)
            .getKnowledgePoint(actualTarget.knowledgePointId);
        return _ResolvedPracticeTarget(
          plannedTarget: plannedTarget,
          actualTarget: point == null ? null : actualTarget,
          question: question,
          knowledgePoint: point,
        );
      case LearningAgentPracticeTargetType.programmingExercise:
        final exercise = await context.ref
            .read(programmingExerciseRepositoryProvider)
            .getExercise(plannedTarget.id);
        if (exercise == null) {
          return _ResolvedPracticeTarget(plannedTarget: plannedTarget);
        }
        final actualTarget =
            LearningAgentPracticeTarget.fromProgrammingExercise(exercise);
        final point = await context.ref
            .read(knowledgePointRepositoryProvider)
            .getKnowledgePoint(actualTarget.knowledgePointId);
        return _ResolvedPracticeTarget(
          plannedTarget: plannedTarget,
          actualTarget: point == null ? null : actualTarget,
          programmingExercise: exercise,
          knowledgePoint: point,
        );
    }
  }

  LearningAgentPracticeTarget? _fallbackPracticeTarget(
    List<LearningAgentPracticeTarget> targets,
    String? focusPointId,
  ) {
    final executable = targets.where((target) => target.isExecutable).toList();
    executable.sort((a, b) {
      final aType =
          a.type == LearningAgentPracticeTargetType.programmingExercise ? 0 : 1;
      final bType =
          b.type == LearningAgentPracticeTargetType.programmingExercise ? 0 : 1;
      final typeOrder = aType.compareTo(bType);
      if (typeOrder != 0) return typeOrder;
      return a.routingId.compareTo(b.routingId);
    });
    if (focusPointId != null) {
      for (final target in executable) {
        if (target.knowledgePointId == focusPointId) return target;
      }
    }
    return executable.isEmpty ? null : executable.first;
  }

  Future<List<Question>> _practiceQuestionsForPlan(
    LearningAgentExecutionContext context,
  ) async {
    final questions = await context.ref.read(verifiedQuestionsProvider.future);
    final focusPointId = _focusPointId(context.plan);
    final focusQuestions = focusPointId == null
        ? questions
        : questions
            .where((question) => question.knowledgePointId == focusPointId)
            .toList();
    return focusQuestions.isEmpty ? questions : focusQuestions;
  }

  Future<String?> _completedFollowUpQuestion(
    LearningAgentExecutionContext context, {
    required LearningSessionMode mode,
    required String? pointId,
    required String? question,
    required int beforeCount,
  }) async {
    final trimmed = question?.trim();
    if (trimmed == null || trimmed.isEmpty || pointId == null) {
      return null;
    }
    final afterCount = await _completedSessionCount(
      context,
      mode,
      pointId,
      trimmed,
    );
    return afterCount > beforeCount ? trimmed : null;
  }

  Future<int> _completedSessionCount(
    LearningAgentExecutionContext context,
    LearningSessionMode mode,
    String? pointId,
    String? question,
  ) async {
    final trimmed = question?.trim();
    if (pointId == null || trimmed == null || trimmed.isEmpty) return 0;

    final sessions = await context.ref
        .read(learningSessionRepositoryProvider)
        .getLearningSessions();
    return sessions
        .where(
          (session) => AgentSessionCompletionMatcher.matchesCompletedPoint(
            session: session,
            mode: mode,
            pointId: pointId,
            followUpQuestion: trimmed,
          ),
        )
        .length;
  }

  Future<String?> _loadLatestFollowUpQuestion(
    LearningAgentExecutionContext context,
    String? targetId,
  ) async {
    if (targetId == null) return null;
    final memory =
        await context.ref.read(learningAgentMemoryStoreProvider.future);
    return memory.memoryForTarget(targetId).latestOpenFollowUpQuestion;
  }

  List<String> _policyDiagnosticLines(
    LearningAgentExecutionContext context,
    LearningAgentPlanStep step,
    LearningAgentToolDefinition? tool,
    LearningAgentPolicyResult policyResult, {
    LearningAgentState? state,
  }) {
    final summary = context.plan.sessionSummary;
    return [
      '入口: Agent Session 准备页',
      '学习目标: ${summary.goal.label}',
      '目标: ${summary.targetLabel}',
      '执行步骤: ${step.title}',
      '工具: ${tool?.title ?? '未匹配工具'}',
      ...?context.plan.nextAction?.diagnosticLines(),
      ...learningAgentStateDiagnosticLines(
        state,
        selectedTool: tool,
        toolRegistry: toolRegistry,
      ),
      ...learningAgentResumeReadinessDiagnosticLines(
        state,
        selectedTool: tool,
      ),
      ...learningAgentRuntimeContractChecklistLines(
        plan: context.plan,
        state: state,
        selectedTool: tool,
      ),
      '证据要求: ${tool?.evidenceRequirement.label ?? '未记录'}',
      '建议动作: ${policyResult.nextAction.label}',
      ...policyResult.blockingIssues.map(
        (issue) => '阻断: ${issue.title} / ${issue.message}',
      ),
      ...policyResult.warningMessages.map((message) => '警告: $message'),
    ];
  }

  LearningAgentTraceEvent _traceEvent(
    LearningAgentExecutionContext context,
    LearningAgentToolDefinition? tool,
    LearningAgentTraceEventType type,
    String summary, {
    LearningAgentTraceLevel level = LearningAgentTraceLevel.info,
    LearningAgentPhase? phase,
    String? detail,
    List<String> evidenceChunkIds = const [],
    List<String> policyIssueCodes = const [],
  }) {
    final sessionSummary = context.plan.sessionSummary;
    return LearningAgentTraceEvent.now(
      sessionId: context.sessionId,
      goal: context.plan.goal,
      type: type,
      level: level,
      phase: phase ?? context.initialState.phase,
      targetId:
          context.initialState.targetId ?? _sessionTargetId(sessionSummary),
      targetLabel: sessionSummary.targetLabel,
      toolId: tool?.toolId,
      summary: summary,
      detail: detail,
      evidenceChunkIds: evidenceChunkIds,
      policyIssueCodes: policyIssueCodes,
    );
  }

  String? _toolDetail(LearningAgentToolDefinition? tool) {
    if (tool == null) return null;
    final capabilities = tool.requiredCapabilities
        .map((capability) => capability.label)
        .join('、');
    return [
      '证据要求: ${tool.evidenceRequirement.label}',
      if (capabilities.isNotEmpty) '能力: $capabilities',
      '失败诊断: ${tool.failureDiagnosticTitle}',
    ].join('\n');
  }

  String _policyDetail(
    LearningAgentPolicyResult result, {
    GroundedLearningContext? groundedContext,
  }) {
    return [
      if (result.issues.isEmpty)
        '无策略问题。'
      else
        ...result.issues.map(
          (issue) =>
              '${issue.severity.label} · ${issue.title}: ${issue.message}',
        ),
      ...?groundedContext?.diagnosticLines,
    ].join('\n');
  }

  String? _sessionTargetId(LearningAgentSessionSummary summary) {
    return summary.practiceTarget?.routingId ??
        summary.focusPoint?.id ??
        _stepTypeId(summary.nextStep);
  }

  String? _focusPointId(LearningAgentPlan plan) {
    return plan.sessionSummary.focusPoint?.id ??
        (plan.focusPoints.isEmpty ? null : plan.focusPoints.first.id);
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

class _PolicyCheckSnapshot {
  final LearningAgentPolicyResult result;
  final List<String> evidenceChunkIds;
  final _ResolvedPracticeTarget? practiceTarget;
  final GroundedLearningContext? groundedContext;

  const _PolicyCheckSnapshot({
    required this.result,
    this.evidenceChunkIds = const [],
    this.practiceTarget,
    this.groundedContext,
  });

  List<String> get policyIssueCodes {
    return result.issues.map((issue) => issue.code).toList();
  }
}

class _ResolvedPracticeTarget {
  final LearningAgentPracticeTarget plannedTarget;
  final LearningAgentPracticeTarget? actualTarget;
  final Question? question;
  final ProgrammingExercise? programmingExercise;
  final KnowledgePoint? knowledgePoint;

  const _ResolvedPracticeTarget({
    required this.plannedTarget,
    this.actualTarget,
    this.question,
    this.programmingExercise,
    this.knowledgePoint,
  });
}

List<String> _uniqueStrings(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) continue;
    seen.add(trimmed);
    result.add(trimmed);
  }
  return result;
}
