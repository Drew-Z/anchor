import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/question.dart';
import '../../services/agent/agent_session_memory_index.dart';
import '../../services/agent/learning_agent_runtime_contracts.dart';
import '../../shared/widgets/source_citation_block.dart';
import '../knowledge_base/knowledge_base_screen.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'agent_session_detail_screen.dart';
import 'agent_session_history_screen.dart';

class AgentSessionLaunchScreen extends ConsumerStatefulWidget {
  final LearningAgentPlan plan;
  final LearningAgentRuntimeSession? initialRuntimeSession;

  const AgentSessionLaunchScreen({
    super.key,
    required this.plan,
    this.initialRuntimeSession,
  });

  @override
  ConsumerState<AgentSessionLaunchScreen> createState() =>
      _AgentSessionLaunchScreenState();
}

class _AgentSessionLaunchScreenState
    extends ConsumerState<AgentSessionLaunchScreen> {
  bool _isStarting = false;
  bool _hasCompletedStep = false;
  bool _isSavingCompletion = false;
  LearningAgentExecutionResult? _executionBlockResult;
  LearningAgentExecutionResult? _executionFailureResult;
  Object? _completionSaveError;
  DateTime? _completionSaveFailedAt;
  Object? _checkpointSaveError;
  DateTime? _checkpointSaveFailedAt;
  String _checkpointSaveStage = '未开始';
  bool _checkpointRetryStartsSession = false;
  bool _isRetryingCheckpoint = false;
  LearningAgentRuntimeSession? _pendingResumeSession;
  bool _wasResumed = false;
  DateTime? _lastStartedAt;
  String? _activeSessionId;
  int _activeCheckpointRevision = 0;
  LearningAgentState? _activeAgentState;
  String? _activeFollowUpQuestion;
  List<LearningAgentTraceEvent> _agentTraceEvents =
      const <LearningAgentTraceEvent>[];
  final Set<int> _checkedCriteria = <int>{};
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _nextQuestionController = TextEditingController();

  LearningAgentPlan get plan => widget.plan;
  bool get _hasCheckpointConflict =>
      _checkpointSaveError is LearningAgentCheckpointConflictException;
  bool get _hasCompletionCheckpointConflict =>
      _completionSaveError is LearningAgentCheckpointConflictException;

  @override
  void initState() {
    super.initState();
    final resumedSession = widget.initialRuntimeSession;
    if (resumedSession == null) return;
    _pendingResumeSession = resumedSession;
    _wasResumed = true;
    _lastStartedAt = resumedSession.startedAt;
    _activeSessionId = resumedSession.sessionId;
    _activeCheckpointRevision = resumedSession.checkpointRevision;
    _activeAgentState = resumedSession.state;
    _agentTraceEvents = resumedSession.traceEvents;
    _hasCompletedStep =
        resumedSession.state.phase == LearningAgentPhase.reflect;
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _nextQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = plan.sessionSummary;
    final nextStep = summary.nextStep;
    final blockReason = plan.startBlockReason;
    final agentMemoryAsync = ref.watch(agentSessionMemoryIndexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Session')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SessionHero(summary: summary),
            if (_wasResumed) ...[
              const SizedBox(height: 10),
              _ResumedSessionStatus(
                state: _activeAgentState,
                traceCount: _agentTraceEvents.length,
                checkpointRevision: _activeCheckpointRevision,
              ),
            ],
            const SizedBox(height: 14),
            agentMemoryAsync.when(
              data: (memory) {
                final latestSession = memory.latestSessionForGoal(summary.goal);
                if (latestSession == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    _LatestGoalReviewPanel(
                      session: latestSession,
                      onOpen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AgentSessionDetailScreen(
                              session: latestSession,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Column(
                children: [
                  KnowledgeLibraryErrorState(
                    title: '历史上下文读取失败',
                    retryLabel: '重试读取历史',
                    diagnosticTitle: 'Agent Session 准备页历史上下文读取失败',
                    diagnosticSuccessMessage: '已复制准备页历史读取诊断',
                    diagnosticLines: [
                      '入口: Agent Session 准备页',
                      '学习目标: ${summary.goal.label}',
                      '目标: ${summary.targetLabel}',
                    ],
                    error: error,
                    onRetry: () {
                      ref.invalidate(agentSessionListProvider);
                      ref.invalidate(agentSessionMemoryIndexProvider);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            if (summary.focusPoint != null) ...[
              _FocusPointPanel(
                point: summary.focusPoint!,
                onTap: () => _openFocusPoint(summary.focusPoint!),
              ),
              const SizedBox(height: 14),
              _EvidencePreviewPanel(knowledgePointId: summary.focusPoint!.id),
              const SizedBox(height: 14),
              if (summary.practiceTarget != null)
                _SelectedPracticeTargetPanel(
                  target: summary.practiceTarget!,
                )
              else
                _VerifiedQuestionPreviewPanel(
                  knowledgePointId: summary.focusPoint!.id,
                ),
              const SizedBox(height: 14),
            ],
            _RulePanel(summary: summary),
            const SizedBox(height: 14),
            _RuntimeInterviewCard(
              card: learningAgentRuntimeInterviewCard(
                plan: plan,
                state: _activeAgentState,
                traceEvents: _agentTraceEvents,
              ),
            ),
            const SizedBox(height: 14),
            agentMemoryAsync.when(
              data: (memory) {
                final targetId = _sessionTargetId(summary);
                final followUp =
                    memory.latestOpenFollowUpQuestionForTarget(targetId);
                if (followUp == null) return const SizedBox.shrink();
                final followUpCount =
                    memory.openFollowUpCountForTarget(targetId);
                return Column(
                  children: [
                    _PreviousFollowUpPanel(
                      question: followUp,
                      openCount: followUpCount,
                      onOpenBacklog: targetId == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AgentSessionHistoryScreen(
                                    initialGoal: summary.goal,
                                    initialOnlyWithFollowUp: true,
                                    initialTargetId: targetId,
                                    initialTargetLabel: summary.targetLabel,
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            _SuccessCriteriaPanel(
              criteria: summary.successCriteria,
              checkedIndexes: _checkedCriteria,
              enabled: _hasCompletedStep,
              onChanged: _setCriteriaChecked,
            ),
            const SizedBox(height: 14),
            _ReflectionPromptPanel(prompts: summary.reflectionPrompts),
            const SizedBox(height: 14),
            if (plan.blockers.isNotEmpty) ...[
              _BlockerPanel(blockers: plan.blockers),
              const SizedBox(height: 14),
            ],
            _RoutePanel(plan: plan),
            const SizedBox(height: 18),
            if (_hasCompletedStep) ...[
              _CompletionReviewPanel(
                summary: summary,
                checkedCount: _checkedCriteria.length,
                traceEvents: _agentTraceEvents,
                reflectionController: _reflectionController,
                nextQuestionController: _nextQuestionController,
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: plan.canStartSession &&
                        !_isStarting &&
                        _checkpointSaveError == null
                    ? () => _startSession(context)
                    : null,
                icon: _isStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _startButtonLabel(nextStep),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.textLight,
                  disabledBackgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (blockReason != null) ...[
              const SizedBox(height: 10),
              Text(
                blockReason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ],
            if (_executionBlockResult != null) ...[
              const SizedBox(height: 10),
              KnowledgeLibraryErrorState(
                title: '执行前检查未通过',
                retryLabel: _checkpointSaveError == null
                    ? '重新检查并启动'
                    : _hasCheckpointConflict
                        ? '返回查看最新会话'
                        : '先重试保存运行状态',
                diagnosticTitle: _executionBlockResult!.diagnosticTitle ??
                    'Agent Session 执行前策略阻断',
                diagnosticSuccessMessage: '已复制策略阻断诊断',
                diagnosticLines: _executionBlockResult!.diagnosticLines,
                error: _executionBlockResult!.message ?? '策略阻断',
                onRetry: _checkpointSaveError == null
                    ? () => _startSession(context)
                    : _hasCheckpointConflict
                        ? _returnToLatestCheckpoint
                        : _retryActiveCheckpointSave,
              ),
            ],
            if (_executionFailureResult != null) ...[
              const SizedBox(height: 10),
              KnowledgeLibraryErrorState(
                title: '启动失败',
                retryLabel: _checkpointSaveError == null
                    ? '重新启动'
                    : _hasCheckpointConflict
                        ? '返回查看最新会话'
                        : '先重试保存运行状态',
                diagnosticTitle: _executionFailureResult!.diagnosticTitle ??
                    'Agent Session 启动失败',
                diagnosticSuccessMessage: '已复制启动失败诊断',
                diagnosticLines: _executionFailureDiagnosticLines(
                  _executionFailureResult!,
                ),
                error: _executionFailureResult!.message ?? '启动失败',
                onRetry: _checkpointSaveError == null
                    ? () => _startSession(context)
                    : _hasCheckpointConflict
                        ? _returnToLatestCheckpoint
                        : _retryActiveCheckpointSave,
              ),
            ],
            if (_checkpointSaveError != null) ...[
              const SizedBox(height: 10),
              KnowledgeLibraryErrorState(
                title: 'Agent 运行状态保存失败',
                retryLabel: _isRetryingCheckpoint
                    ? '正在保存运行状态'
                    : _hasCheckpointConflict
                        ? '返回查看最新会话'
                        : _checkpointRetryStartsSession
                            ? _activeCheckpointRevision > 0
                                ? '从已保存状态继续'
                                : '重试创建并启动'
                            : '重试保存运行状态',
                diagnosticTitle: 'Agent runtime checkpoint 保存失败',
                diagnosticSuccessMessage: '已复制 checkpoint 保存诊断',
                diagnosticLines: _checkpointSaveDiagnosticLines(),
                error: _checkpointSaveError!,
                onRetry: _hasCheckpointConflict
                    ? _returnToLatestCheckpoint
                    : _checkpointRetryStartsSession
                        ? () => _startSession(context)
                        : _retryActiveCheckpointSave,
              ),
            ],
            if (_hasCompletedStep) ...[
              const SizedBox(height: 10),
              if (_completionSaveError != null) ...[
                KnowledgeLibraryErrorState(
                  title: '复盘保存失败',
                  retryLabel:
                      _hasCompletionCheckpointConflict ? '返回查看最新会话' : '重新保存复盘',
                  diagnosticTitle: 'Agent Session 复盘保存失败',
                  diagnosticSuccessMessage: '已复制复盘保存失败诊断',
                  diagnosticLines: _completionSaveDiagnosticLines(),
                  error: _completionSaveError!,
                  onRetry: _hasCompletionCheckpointConflict
                      ? _returnToLatestCheckpoint
                      : _finishAndReturn,
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSavingCompletion || _checkpointSaveError != null
                      ? null
                      : () => _finishAndReturn(),
                  icon: _isSavingCompletion
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.green,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSavingCompletion ? '正在保存复盘' : '完成并返回 Agent',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.greenDark,
                    side: const BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    final step = plan.sessionSummary.nextStep;
    if (step == null) return;

    final blockReason = plan.startBlockReason;
    if (blockReason != null) {
      _showMessage(blockReason);
      return;
    }

    final runtime = ref.read(learningAgentRuntimeProvider);
    final runtimeSession =
        _pendingResumeSession ?? runtime.prepareSession(plan: plan);
    var checkpointRevision = runtimeSession.checkpointRevision;
    var executionState = runtimeSession.state;
    var executionTraceEvents = runtimeSession.traceEvents;
    setState(() {
      _isStarting = true;
      _hasCompletedStep = false;
      _executionBlockResult = null;
      _executionFailureResult = null;
      _completionSaveError = null;
      _completionSaveFailedAt = null;
      _checkpointSaveError = null;
      _checkpointSaveFailedAt = null;
      _checkpointSaveStage = '会话准备';
      _checkpointRetryStartsSession = false;
      _isRetryingCheckpoint = false;
      _pendingResumeSession = runtimeSession;
      _lastStartedAt = runtimeSession.startedAt;
      _activeSessionId = runtimeSession.sessionId;
      _activeCheckpointRevision = checkpointRevision;
      _activeAgentState = runtimeSession.state;
      _activeFollowUpQuestion = null;
      _agentTraceEvents = runtimeSession.traceEvents;
      _checkedCriteria.clear();
      _reflectionController.clear();
      _nextQuestionController.clear();
    });
    try {
      try {
        final planCheckpoint = await runtime.persistCheckpoint(
          state: runtimeSession.state,
          traceEvents: runtimeSession.traceEvents,
          plan: plan,
          checkpointRevision: checkpointRevision,
        );
        checkpointRevision = planCheckpoint.revision;
        executionState = planCheckpoint.state;
        executionTraceEvents = planCheckpoint.traceEvents;
        _activeCheckpointRevision = checkpointRevision;
        _checkpointSaveStage = '工具调用前';
        _pendingResumeSession = _sessionFromCheckpoint(
          runtimeSession,
          planCheckpoint,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isStarting = false;
          _checkpointSaveError = error;
          _checkpointSaveFailedAt = DateTime.now();
          _checkpointRetryStartsSession = true;
        });
        _showMessage('运行状态保存失败，尚未启动学习工具。');
        return;
      }

      if (!mounted) return;
      final executor = ref.read(learningAgentExecutorProvider);
      final result = await executor.execute(
        LearningAgentExecutionContext(
          buildContext: context,
          ref: ref,
          plan: plan,
          sessionId: runtimeSession.sessionId,
          initialState: executionState,
          initialTraceEvents: executionTraceEvents,
          persistToolStartCheckpoint: (state, traceEvents) async {
            final checkpoint = await runtime.persistCheckpoint(
              state: state,
              traceEvents: traceEvents,
              plan: plan,
              checkpointRevision: checkpointRevision,
            );
            checkpointRevision = checkpoint.revision;
            executionState = checkpoint.state;
            executionTraceEvents = checkpoint.traceEvents;
            if (!mounted) return;
            setState(() {
              _activeAgentState = checkpoint.state;
              _agentTraceEvents = checkpoint.traceEvents;
              _activeCheckpointRevision = checkpoint.revision;
              _checkpointSaveStage = '工具执行结果';
              _pendingResumeSession = _sessionFromCheckpoint(
                runtimeSession,
                checkpoint,
              );
            });
          },
        ),
      );

      final resultState = result.state ?? executionState;
      final resultTraceEvents = result.traceEvents.isEmpty
          ? executionTraceEvents
          : result.traceEvents;
      LearningAgentCheckpoint? savedCheckpoint;
      Object? checkpointSaveError;
      try {
        savedCheckpoint = await runtime.persistCheckpoint(
          state: resultState,
          traceEvents: resultTraceEvents,
          plan: plan,
          checkpointRevision: checkpointRevision,
        );
      } catch (error) {
        checkpointSaveError = error;
      }

      if (!mounted) return;
      _pendingResumeSession = null;
      final activeState = savedCheckpoint?.state ?? resultState;
      final activeTraceEvents =
          savedCheckpoint?.traceEvents ?? resultTraceEvents;
      final activeCheckpointRevision =
          savedCheckpoint?.revision ?? checkpointRevision;
      setState(() {
        _checkpointSaveError = checkpointSaveError;
        _checkpointSaveFailedAt =
            checkpointSaveError == null ? null : DateTime.now();
        _checkpointRetryStartsSession = false;
        _activeCheckpointRevision = activeCheckpointRevision;
      });
      if (result.shouldRefreshInputs) {
        _invalidateAgentInputs();
      }
      if (result.isFailed) {
        setState(() {
          _isStarting = false;
          _executionFailureResult = result;
          _activeAgentState = activeState;
          _agentTraceEvents = activeTraceEvents;
        });
        _showMessage(result.message ?? '启动失败');
        return;
      }
      if (result.isBlocked) {
        setState(() {
          _isStarting = false;
          _executionBlockResult = result;
          _activeAgentState = activeState;
          _agentTraceEvents = activeTraceEvents;
        });
        _showMessage('执行前检查未通过，请先处理阻断原因。');
        return;
      }
      if (result.isCanceled) {
        setState(() {
          _isStarting = false;
          _activeAgentState = activeState;
          _agentTraceEvents = activeTraceEvents;
        });
        if (result.message != null) _showMessage(result.message!);
        return;
      }

      _activeFollowUpQuestion = result.completedFollowUpQuestion;
      _showFollowUpCompletionMessage(
        result.attemptedFollowUpQuestion,
        result.completedFollowUpQuestion,
      );
      setState(() {
        _isStarting = false;
        _executionBlockResult = null;
        _executionFailureResult = null;
        _activeAgentState = activeState;
        _agentTraceEvents = activeTraceEvents;
        _hasCompletedStep = result.shouldShowCompletionReview;
      });
    } catch (e) {
      if (!mounted) return;
      final checkpointError =
          e is LearningAgentToolStartCheckpointException ? e.cause : null;
      setState(() {
        _isStarting = false;
        if (checkpointError != null) {
          _checkpointSaveError = checkpointError;
          _checkpointSaveFailedAt = DateTime.now();
          _checkpointRetryStartsSession = true;
        }
      });
      _showMessage(
        checkpointError == null ? '启动失败: $e' : '工具调用前状态保存失败，工具尚未启动。',
      );
    }
  }

  LearningAgentRuntimeSession _sessionFromCheckpoint(
    LearningAgentRuntimeSession base,
    LearningAgentCheckpoint checkpoint,
  ) {
    return LearningAgentRuntimeSession(
      sessionId: base.sessionId,
      startedAt: base.startedAt,
      plan: base.plan,
      state: checkpoint.state,
      selectedTool: base.selectedTool,
      traceEvents: checkpoint.traceEvents,
      checkpointRevision: checkpoint.revision,
    );
  }

  void _setCriteriaChecked(int index, bool isChecked) {
    setState(() {
      if (isChecked) {
        _checkedCriteria.add(index);
      } else {
        _checkedCriteria.remove(index);
      }
    });
  }

  Future<void> _finishAndReturn() async {
    if (_isSavingCompletion) return;
    setState(() {
      _isSavingCompletion = true;
      _completionSaveError = null;
      _completionSaveFailedAt = null;
    });

    try {
      await _saveAgentSessionRecord();
      if (!mounted) return;
      _invalidateLearningRecordIndexes();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingCompletion = false;
        _completionSaveError = e;
        _completionSaveFailedAt = DateTime.now();
      });
      _showMessage('复盘保存失败: $e');
    }
  }

  Future<void> _saveAgentSessionRecord() async {
    final now = DateTime.now();
    final summary = plan.sessionSummary;
    final activeState = _activeAgentState;
    if (activeState == null) {
      throw StateError(
          'Agent runtime state is missing before reflection save.');
    }
    final sessionId = activeState.sessionId;
    if (_activeSessionId != null && _activeSessionId != sessionId) {
      throw StateError(
          'Agent runtime session id changed before reflection save.');
    }
    final runtime = ref.read(learningAgentRuntimeProvider);
    final sessionRepository = ref.read(learningSessionRepositoryProvider);
    final checkpoint = await runtime.persistReflectionCheckpoint(
      state: activeState,
      traceEvents: _agentTraceEvents,
      plan: plan,
      targetLabel: summary.targetLabel,
      detail:
          '成功标准 ${_checkedCriteria.length}/${summary.successCriteria.length}',
      savedAt: now,
      checkpointRevision: _activeCheckpointRevision,
    );
    _activeAgentState = checkpoint.state;
    _agentTraceEvents = checkpoint.traceEvents;
    _activeCheckpointRevision = checkpoint.revision;
    final session = LearningSession(
      id: sessionId,
      mode: LearningSessionMode.agentSession,
      targetId: _sessionTargetId(summary),
      startedAt: _lastStartedAt ?? now,
      endedAt: now,
      summary: _completionSummary(traceEvents: checkpoint.traceEvents),
    );
    await sessionRepository.insertLearningSession(session);
  }

  String _completionSummary({
    required List<LearningAgentTraceEvent> traceEvents,
  }) {
    final summary = plan.sessionSummary;
    final note = _reflectionController.text.trim();
    final activeFollowUp = _activeFollowUpQuestion?.trim();
    final nextQuestion = _nextQuestionController.text.trim();
    final traceLines = learningAgentTraceSummaryLines(traceEvents);
    final checkedCriteria = _checkedCriteria.toList()..sort();
    final checkedLabels = checkedCriteria
        .where((index) => index >= 0 && index < summary.successCriteria.length)
        .map((index) => summary.successCriteria[index])
        .toList();
    final lines = [
      '${summary.goal.label} · ${summary.title}',
      '目标: ${summary.targetLabel}',
      '成功标准: ${_checkedCriteria.length}/${summary.successCriteria.length}',
      if (checkedLabels.isNotEmpty) '已确认: ${checkedLabels.join('；')}',
      if (activeFollowUp != null && activeFollowUp.isNotEmpty)
        '本轮追问: $activeFollowUp',
      if (nextQuestion.isNotEmpty) '下次追问: $nextQuestion',
      if (traceLines.isNotEmpty) ...traceLines,
      if (note.isNotEmpty) '复盘: $note',
    ];
    return lines.join('\n');
  }

  List<String> _completionSaveDiagnosticLines() {
    final summary = plan.sessionSummary;
    final note = _reflectionController.text.trim();
    final nextQuestion = _nextQuestionController.text.trim();
    final failedAt = _completionSaveFailedAt;
    return [
      '入口: Agent Session 准备页',
      '学习目标: ${summary.goal.label}',
      'checkpoint revision: $_activeCheckpointRevision',
      ..._checkpointConflictDiagnosticLines(_completionSaveError),
      ...learningAgentStateDiagnosticLines(_activeAgentState),
      ...learningAgentResumeReadinessDiagnosticLines(_activeAgentState),
      ...learningAgentRuntimeContractChecklistLines(
        plan: plan,
        state: _activeAgentState,
        traceEvents: _agentTraceEvents,
      ),
      '目标: ${summary.targetLabel}',
      '执行步骤: ${summary.nextStep?.title ?? '未记录步骤'}',
      '成功标准: ${_checkedCriteria.length}/${summary.successCriteria.length}',
      '本轮追问: ${_activeFollowUpQuestion ?? '无'}',
      '下次追问: ${nextQuestion.isEmpty ? '无' : nextQuestion}',
      '复盘笔记: ${note.isEmpty ? '无' : note}',
      '失败时间: ${failedAt == null ? '未记录' : _dateTimeText(failedAt)}',
      ...learningAgentTraceSummaryLines(_agentTraceEvents),
    ];
  }

  List<String> _checkpointSaveDiagnosticLines() {
    final failedAt = _checkpointSaveFailedAt;
    return [
      '入口: Agent Session 准备页',
      'checkpoint 阶段: $_checkpointSaveStage',
      'checkpoint session: ${_activeSessionId ?? '未记录'}',
      'checkpoint revision: $_activeCheckpointRevision',
      ..._checkpointConflictDiagnosticLines(_checkpointSaveError),
      ...learningAgentStateDiagnosticLines(_activeAgentState),
      'checkpoint trace 数量: ${_agentTraceEvents.length}',
      '失败时间: ${failedAt == null ? '未记录' : _dateTimeText(failedAt)}',
      ...learningAgentTraceSummaryLines(_agentTraceEvents),
    ];
  }

  Future<void> _retryActiveCheckpointSave() async {
    if (_isRetryingCheckpoint) return;
    final state = _activeAgentState;
    if (state == null) {
      _showMessage('当前没有可保存的 Agent runtime state。');
      return;
    }

    setState(() => _isRetryingCheckpoint = true);
    try {
      final checkpoint =
          await ref.read(learningAgentRuntimeProvider).persistCheckpoint(
                state: state,
                traceEvents: _agentTraceEvents,
                plan: plan,
                checkpointRevision: _activeCheckpointRevision,
              );
      if (!mounted) return;
      setState(() {
        _activeAgentState = checkpoint.state;
        _agentTraceEvents = checkpoint.traceEvents;
        _activeCheckpointRevision = checkpoint.revision;
        _checkpointSaveError = null;
        _checkpointSaveFailedAt = null;
        _checkpointRetryStartsSession = false;
        _isRetryingCheckpoint = false;
      });
      _showMessage('Agent 运行状态已保存。');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checkpointSaveError = error;
        _checkpointSaveFailedAt = DateTime.now();
        _isRetryingCheckpoint = false;
      });
    }
  }

  List<String> _checkpointConflictDiagnosticLines(Object? error) {
    if (error is! LearningAgentCheckpointConflictException) return const [];
    return [
      'checkpoint 冲突: 是',
      '本地 revision: ${error.expectedRevision}',
      '最新 revision: ${error.actualRevision}',
      '恢复动作: 返回 Agent 首页读取最新 checkpoint，不覆盖新状态',
    ];
  }

  void _returnToLatestCheckpoint() {
    ref.invalidate(learningAgentActiveCheckpointListProvider);
    Navigator.of(context).pop();
  }

  List<String> _executionFailureDiagnosticLines(
    LearningAgentExecutionResult result,
  ) {
    final stateLines = result.diagnosticLines.any(
      isLearningAgentStateDiagnosticLine,
    )
        ? const <String>[]
        : learningAgentStateDiagnosticLines(
            result.state ?? _activeAgentState,
            selectedTool: result.tool,
          );
    final resumeLines = result.diagnosticLines.any(
      isLearningAgentResumeReadinessDiagnosticLine,
    )
        ? const <String>[]
        : learningAgentResumeReadinessDiagnosticLines(
            result.state ?? _activeAgentState,
            selectedTool: result.tool,
          );
    final contractLines = result.diagnosticLines.any(
      isLearningAgentRuntimeContractChecklistLine,
    )
        ? const <String>[]
        : learningAgentRuntimeContractChecklistLines(
            plan: plan,
            state: result.state ?? _activeAgentState,
            selectedTool: result.tool,
            traceEvents: result.traceEvents,
          );
    return [
      '入口: Agent Session 准备页',
      '学习目标: ${plan.sessionSummary.goal.label}',
      ...stateLines,
      ...resumeLines,
      ...contractLines,
      '目标: ${plan.sessionSummary.targetLabel}',
      '执行步骤: ${result.step?.title ?? plan.sessionSummary.nextStep?.title ?? '未记录步骤'}',
      '工具: ${result.tool?.title ?? '未匹配工具'}',
      ...result.diagnosticLines,
      if (result.diagnosticLines.isEmpty)
        ...learningAgentTraceSummaryLines(result.traceEvents),
    ];
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

  String _startButtonLabel(LearningAgentPlanStep? nextStep) {
    if (_pendingResumeSession != null) {
      return nextStep == null ? '继续未完成会话' : '继续：${nextStep.title}';
    }
    if (_hasCompletedStep) {
      return nextStep == null ? '再次执行' : '再次执行：${nextStep.title}';
    }
    return nextStep == null ? '暂无可执行步骤' : '开始：${nextStep.title}';
  }

  Future<void> _openFocusPoint(LearningAgentFocusPoint focusPoint) async {
    final point = await ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePoint(focusPoint.id);
    if (!mounted) return;

    if (point == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const KnowledgeBaseScreen(initialTabIndex: 2),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KnowledgePointDetailScreen(point: point),
      ),
    );
  }

  void _invalidateAgentInputs() {
    final goal = ref.read(learningAgentGoalProvider);
    _invalidateLearningRecordIndexes();
    invalidateLearningAgentPlanInputProviders(ref, goal);
  }

  void _invalidateLearningRecordIndexes() {
    invalidateAgentLearningRecordProviders(ref);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showFollowUpCompletionMessage(
    String? attemptedQuestion,
    String? completedQuestion,
  ) {
    final attempted = attemptedQuestion?.trim();
    if (attempted == null || attempted.isEmpty) return;
    final completed = completedQuestion?.trim();
    _showMessage(
      completed == null || completed.isEmpty
          ? '未检测到完成的追问处理，本轮复盘不会把它标记为已处理。'
          : '已检测到完成的追问处理，本轮复盘会记录这条本轮追问。',
    );
  }
}

class _SessionHero extends StatelessWidget {
  final LearningAgentSessionSummary summary;

  const _SessionHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.greenDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.objective,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.track_changes,
            text: '目标：${summary.targetLabel}',
          ),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.school_outlined,
            text: '路线：${summary.goal.label}',
          ),
          if (summary.memoryReminder != null) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.memory_outlined,
              text: '学习记忆：${summary.memoryReminder}',
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumedSessionStatus extends StatelessWidget {
  final LearningAgentState? state;
  final int traceCount;
  final int checkpointRevision;

  const _ResumedSessionStatus({
    required this.state,
    required this.traceCount,
    required this.checkpointRevision,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore, color: AppColors.blueDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '已恢复本地会话 · revision $checkpointRevision · '
              '${state?.phase.label ?? '未知阶段'} · $traceCount 条轨迹',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusPointPanel extends StatelessWidget {
  final LearningAgentFocusPoint point;
  final VoidCallback onTap;

  const _FocusPointPanel({
    required this.point,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '优先关注',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      point.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${point.reason} · 掌握 ${point.masteryLevel}% · 面试 ${point.interviewRelevance}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MiniPill(
                    icon: Icons.article_outlined,
                    label: '证据 ${point.evidenceChunkCount}',
                  ),
                  _MiniPill(
                    icon: Icons.fact_check_outlined,
                    label: '可练习 ${point.verifiedPracticeTargetCount}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedPracticeTargetPanel extends StatelessWidget {
  final LearningAgentPracticeTarget target;

  const _SelectedPracticeTargetPanel({required this.target});

  @override
  Widget build(BuildContext context) {
    final isProgramming =
        target.type == LearningAgentPracticeTargetType.programmingExercise;
    return Container(
      key: const ValueKey('selected-practice-target'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.purple, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isProgramming ? Icons.code : Icons.quiz_outlined,
            color: AppColors.purpleDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本轮${target.type.label}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purpleDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  target.title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '已核验 · ${target.citationIds.length} 条来源引用',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulePanel extends StatelessWidget {
  final LearningAgentSessionSummary summary;

  const _RulePanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: _InfoLine(
        icon: Icons.policy_outlined,
        text: summary.evidenceConstraint,
      ),
    );
  }
}

enum _RuntimeInterviewCopyAction {
  fullNotes,
  questionAnswerPack,
  blindDrill,
  challengeDrill,
  experienceDrill,
  mockInterviewDrill,
  mockInterviewScoreSheet,
  mockInterviewRepairDrill,
  debugDrill,
}

class _RuntimeInterviewCard extends StatelessWidget {
  final LearningAgentRuntimeInterviewCard card;

  const _RuntimeInterviewCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_outlined,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<_RuntimeInterviewCopyAction>(
                tooltip: '复制面试材料',
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: AppColors.purple,
                ),
                onSelected: (action) {
                  switch (action) {
                    case _RuntimeInterviewCopyAction.fullNotes:
                      _copyInterviewCard(context);
                      break;
                    case _RuntimeInterviewCopyAction.questionAnswerPack:
                      _copyQuestionAnswerPack(context);
                      break;
                    case _RuntimeInterviewCopyAction.blindDrill:
                      _copyBlindDrill(context);
                      break;
                    case _RuntimeInterviewCopyAction.challengeDrill:
                      _copyChallengeDrill(context);
                      break;
                    case _RuntimeInterviewCopyAction.experienceDrill:
                      _copyExperienceDrill(context);
                      break;
                    case _RuntimeInterviewCopyAction.mockInterviewDrill:
                      _copyMockInterviewDrill(context);
                      break;
                    case _RuntimeInterviewCopyAction.mockInterviewScoreSheet:
                      _copyMockInterviewScoreSheet(context);
                      break;
                    case _RuntimeInterviewCopyAction.mockInterviewRepairDrill:
                      _copyMockInterviewRepairDrill(context);
                      break;
                    case _RuntimeInterviewCopyAction.debugDrill:
                      _copyDebugDrill(context);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.fullNotes,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.copy_all,
                      label: '复制完整讲法',
                      color: AppColors.purple,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.questionAnswerPack,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.question_answer_outlined,
                      label: '复制 Q&A 包',
                      color: AppColors.greenDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.blindDrill,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.edit_outlined,
                      label: '复制盲练稿',
                      color: AppColors.blueDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.challengeDrill,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.forum_outlined,
                      label: '复制追问练习',
                      color: AppColors.goldDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.experienceDrill,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.work_outline,
                      label: '复制项目经历练习',
                      color: AppColors.goldDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.mockInterviewDrill,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.record_voice_over_outlined,
                      label: '复制模拟面试练习',
                      color: AppColors.purpleDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.mockInterviewScoreSheet,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.grade_outlined,
                      label: '复制模拟评分表',
                      color: AppColors.goldDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.mockInterviewRepairDrill,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.build_circle_outlined,
                      label: '复制模拟修复练习',
                      color: AppColors.blueDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: _RuntimeInterviewCopyAction.debugDrill,
                    child: _RuntimeCopyMenuItem(
                      icon: Icons.bug_report_outlined,
                      label: '复制调试练习',
                      color: AppColors.redDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.summary,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.verified_outlined,
            text: '证据覆盖：${learningAgentRuntimeEvidenceCoverageSummary(card)}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '60 秒讲法',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '复制 60 秒讲法',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
                onPressed: () => _copyAnswerScript(context),
                icon: const Icon(Icons.copy, size: 15),
                color: AppColors.greenDark,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _RuntimeAnswerScriptLine(text: card.answerScript),
          const SizedBox(height: 8),
          _RuntimeCompactSection(
            icon: Icons.route_outlined,
            title: '练习流程',
            meta: '${card.practiceSteps.length} 步',
            summary: card.practiceSteps.isEmpty
                ? null
                : card.practiceSteps.first.action,
            children: [
              ...card.practiceSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimePracticeStepLine(step: step),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.fact_check_outlined,
            title: '回答检查',
            meta: '${card.answerRubric.length} 条',
            summary: '达标信号和失分点',
            initiallyExpanded: true,
            children: [
              ...card.answerRubric.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeAnswerRubricLine(item: item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: card.badges
                .map(
                  (badge) => _MiniPill(
                    icon: Icons.label_important_outline,
                    label: badge,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          _RuntimeCompactSection(
            icon: Icons.menu_book_outlined,
            title: '术语速记',
            meta: '${card.glossaryTerms.length} 个',
            summary: card.glossaryTerms.map((term) => term.term).join(' / '),
            children: [
              ...card.glossaryTerms.map(
                (term) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeGlossaryTermLine(term: term),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.record_voice_over_outlined,
            title: '讲法要点',
            meta: '${card.talkingPoints.length} 条',
            summary:
                card.talkingPoints.isEmpty ? null : card.talkingPoints.first,
            children: [
              ...card.talkingPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _InfoLine(
                    icon: Icons.record_voice_over_outlined,
                    text: point,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.view_list_outlined,
            title: '回答框架',
            meta: '${card.answerFrames.length} 个',
            summary: '按问题类型组织开场、证据、边界和收束',
            children: [
              ...card.answerFrames.map(
                (frame) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeAnswerFrameLine(frame: frame),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.forum_outlined,
            title: '追问应对',
            meta: '${card.challengeResponses.length} 个',
            summary: '被质疑时先短答、举证、说边界，再拉回主线',
            children: [
              ...card.challengeResponses.map(
                (response) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeChallengeResponseLine(response: response),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.work_outline,
            title: '项目经历',
            meta: '${card.experienceStories.length} 个',
            summary: '把背景、行动、取舍、证据和结果讲成项目故事',
            children: [
              ...card.experienceStories.map(
                (story) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeExperienceStoryLine(story: story),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.record_voice_over_outlined,
            title: '模拟面试轮次',
            meta: '${card.mockInterviewRounds.length} 轮',
            summary: '按面试官问题、压力追问、证据和通过信号练习',
            children: [
              ...card.mockInterviewRounds.map(
                (round) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeMockInterviewRoundLine(round: round),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.grade_outlined,
            title: '模拟面试评分',
            meta: '${card.mockInterviewScoreRules.length} 条',
            summary: '按结构、证据、边界、调试和表达压缩自评',
            children: [
              ...card.mockInterviewScoreRules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeMockInterviewScoreRuleLine(rule: rule),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.build_circle_outlined,
            title: '模拟面试修复路线',
            meta: '${card.mockInterviewRepairDrills.length} 条',
            summary: '按失分症状回看材料、重练并复测',
            children: [
              ...card.mockInterviewRepairDrills.map(
                (drill) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeMockInterviewRepairDrillLine(drill: drill),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.account_tree_outlined,
            title: '框架映射',
            meta: '${card.frameworkMappings.length} 个框架',
            summary: card.frameworkMappings
                .map((mapping) => mapping.framework)
                .join(' / '),
            children: [
              ...card.frameworkMappings.map(
                (mapping) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _FrameworkMappingLine(mapping: mapping),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.compare_arrows,
            title: '框架选型',
            meta: '${card.frameworkSelections.length} 项',
            summary: '比较哪些框架适合当前 agent 演进',
            children: [
              ...card.frameworkSelections.map(
                (selection) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeFrameworkSelectionLine(selection: selection),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.fact_check_outlined,
            title: '架构决策',
            meta: '${card.decisionRecords.length} 条',
            summary: '解释为什么先做 Flutter 本地 runtime',
            children: [
              ...card.decisionRecords.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeDecisionRecordLine(record: record),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.info_outline,
            title: '当前边界',
            meta: '${card.boundaryNotes.length} 条',
            summary: '区分已实现 contract 和未来能力',
            children: [
              ...card.boundaryNotes.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeBoundaryLine(note: note),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.stacked_line_chart,
            title: '成熟度阶梯',
            meta: '${card.maturityLevels.length} 层',
            summary: '定位当前 agent runtime 还处在哪个成熟度',
            children: [
              ...card.maturityLevels.map(
                (level) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeMaturityLevelLine(level: level),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.report_problem_outlined,
            title: '避坑清单',
            meta: '${card.pitfalls.length} 条',
            summary: '避免把架构借鉴夸成已完成能力',
            children: [
              ...card.pitfalls.map(
                (pitfall) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimePitfallLine(pitfall: pitfall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.alt_route_outlined,
            title: '演进路线',
            meta: '${card.evolutionSteps.length} 步',
            summary: '从本地 runtime 平滑迁移到标准 agent 架构',
            children: [
              ...card.evolutionSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeEvolutionStepLine(step: step),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.outlined_flag,
            title: '迁移触发条件',
            meta: '${card.migrationTriggers.length} 个',
            summary: '判断什么时候值得升级到重 agent 框架',
            children: [
              ...card.migrationTriggers.map(
                (trigger) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeMigrationTriggerLine(trigger: trigger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.route_outlined,
            title: '代码走读路线',
            meta: '${card.codeWalkthroughSteps.length} 步',
            summary: '按文件顺序讲清 agent runtime 落地路径',
            children: [
              ...card.codeWalkthroughSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeCodeWalkthroughStepLine(step: step),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.bug_report_outlined,
            title: '调试场景',
            meta: '${card.debugScenarios.length} 个',
            summary: '把常见 runtime 故障转成排查路径和面试讲法',
            children: [
              ...card.debugScenarios.map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeDebugScenarioLine(scenario: scenario),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.play_circle_outline,
            title: '演示脚本',
            meta: '${card.demoSteps.length} 步',
            summary: '按现场展示顺序讲清 agent runtime 的证据链',
            children: [
              ...card.demoSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeDemoStepLine(step: step),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.verified_outlined,
            title: '来源核验清单',
            meta: '${card.sourceGroundingChecks.length} 项',
            summary: '检查知识是否真的有来源、有引用、可追溯',
            children: [
              ...card.sourceGroundingChecks.map(
                (check) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeSourceGroundingCheckLine(check: check),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.code,
            title: '代码依据',
            meta: '${card.evidenceAnchors.length} 处',
            summary: '把架构说法对应到本地文件',
            children: [
              ...card.evidenceAnchors.map(
                (anchor) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeEvidenceAnchorLine(anchor: anchor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.link,
            title: '外部来源',
            meta: '${card.frameworkSourceReferences.length} 条',
            summary: card.frameworkSourceReferences
                .map((reference) => reference.sourceType)
                .join(' / '),
            children: [
              ...card.frameworkSourceReferences.map(
                (reference) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RuntimeSourceReferenceLine(reference: reference),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RuntimeCompactSection(
            icon: Icons.help_outline,
            title: '自测追问',
            meta: '${card.prompts.length} 题',
            summary: card.prompts.isEmpty ? null : card.prompts.first.question,
            children: [
              ...card.prompts.map(
                (prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _InterviewPromptLine(
                    prompt: prompt,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ...card.sourceNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyInterviewCard(BuildContext context) async {
    final text = learningAgentRuntimeInterviewCardCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制 Agent runtime 面试讲法')),
      );
  }

  Future<void> _copyAnswerScript(BuildContext context) async {
    final text = learningAgentRuntimeAnswerScriptCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制 60 秒讲法和回答检查')),
      );
  }

  Future<void> _copyQuestionAnswerPack(BuildContext context) async {
    final text = learningAgentRuntimeQuestionAnswerPackCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制面试 Q&A 练习包')),
      );
  }

  Future<void> _copyBlindDrill(BuildContext context) async {
    final text = learningAgentRuntimeBlindDrillCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制面试盲练稿')),
      );
  }

  Future<void> _copyChallengeDrill(BuildContext context) async {
    final text = learningAgentRuntimeChallengeDrillCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制面试追问练习')),
      );
  }

  Future<void> _copyExperienceDrill(BuildContext context) async {
    final text = learningAgentRuntimeExperienceDrillCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制项目经历练习')),
      );
  }

  Future<void> _copyMockInterviewDrill(BuildContext context) async {
    final text = learningAgentRuntimeMockInterviewDrillCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制模拟面试练习')),
      );
  }

  Future<void> _copyMockInterviewScoreSheet(BuildContext context) async {
    final text = learningAgentRuntimeMockInterviewScoreSheetCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制模拟面试评分复盘表')),
      );
  }

  Future<void> _copyMockInterviewRepairDrill(BuildContext context) async {
    final text = learningAgentRuntimeMockInterviewRepairDrillCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制模拟面试修复练习')),
      );
  }

  Future<void> _copyDebugDrill(BuildContext context) async {
    final text = learningAgentRuntimeDebugDrillCopyText(card);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制 runtime 调试练习')),
      );
  }
}

class _RuntimeCopyMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RuntimeCopyMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RuntimeCompactSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String meta;
  final String? summary;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _RuntimeCompactSection({
    required this.icon,
    required this.title,
    required this.meta,
    required this.children,
    this.summary,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final summaryText = summary?.trim();

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 2),
        iconColor: AppColors.purple,
        collapsedIconColor: AppColors.textLight,
        leading: Icon(icon, size: 17, color: AppColors.purpleDark),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _RuntimeSectionMetaPill(label: meta),
          ],
        ),
        subtitle: summaryText == null || summaryText.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  summaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
              ),
        children: children,
      ),
    );
  }
}

class _RuntimeSectionMetaPill extends StatelessWidget {
  final String label;

  const _RuntimeSectionMetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RuntimePracticeStepLine extends StatelessWidget {
  final LearningAgentRuntimePracticeStep step;

  const _RuntimePracticeStepLine({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.route_outlined,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.action,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '达标：${step.successSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeGlossaryTermLine extends StatelessWidget {
  final LearningAgentRuntimeGlossaryTerm term;

  const _RuntimeGlossaryTermLine({required this.term});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.menu_book_outlined,
          size: 15,
          color: AppColors.purpleDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                term.term,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                term.definition,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '面试用法：${term.interviewUse}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeAnswerFrameLine extends StatelessWidget {
  final LearningAgentRuntimeAnswerFrame frame;

  const _RuntimeAnswerFrameLine({required this.frame});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.view_list_outlined,
          size: 15,
          color: AppColors.purpleDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                frame.questionType,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '开场：${frame.openingClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '证据：${frame.evidenceToMention}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '边界：${frame.boundaryToState}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '收束：${frame.closingMove}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeChallengeResponseLine extends StatelessWidget {
  final LearningAgentRuntimeChallengeResponse response;

  const _RuntimeChallengeResponseLine({required this.response});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.forum_outlined,
          size: 15,
          color: AppColors.blueDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                response.challenge,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '短答：${response.conciseResponse}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '证据：${response.evidenceToShow}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '边界：${response.boundary}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '拉回主线：${response.bridgeBack}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeExperienceStoryLine extends StatelessWidget {
  final LearningAgentRuntimeExperienceStory story;

  const _RuntimeExperienceStoryLine({required this.story});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.work_outline,
          size: 15,
          color: AppColors.goldDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.prompt,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '背景：${story.situation}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '行动：${story.action}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '取舍：${story.technicalChoice}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '证据：${story.proof}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '结果：${story.outcome}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeMockInterviewRoundLine extends StatelessWidget {
  final LearningAgentRuntimeMockInterviewRound round;

  const _RuntimeMockInterviewRoundLine({required this.round});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.record_voice_over_outlined,
          size: 15,
          color: AppColors.purpleDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                round.round,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '问题：${round.interviewerPrompt}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '追问：${round.pressureFollowUp}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '证据：${round.expectedEvidence}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '通过信号：${round.passSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeMockInterviewScoreRuleLine extends StatelessWidget {
  final LearningAgentRuntimeMockInterviewScoreRule rule;

  const _RuntimeMockInterviewScoreRuleLine({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.grade_outlined,
          size: 15,
          color: AppColors.goldDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule.criterion,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '满分：${rule.fullCreditSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '失分：${rule.weakSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '修复：${rule.repairAction}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeMockInterviewRepairDrillLine extends StatelessWidget {
  final LearningAgentRuntimeMockInterviewRepairDrill drill;

  const _RuntimeMockInterviewRepairDrillLine({required this.drill});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.build_circle_outlined,
          size: 15,
          color: AppColors.blueDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drill.weakness,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '回看：${drill.reviewTarget}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '练习：${drill.practiceAction}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '复测：${drill.retryPrompt}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '完成：${drill.doneSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimePitfallLine extends StatelessWidget {
  final LearningAgentRuntimePitfall pitfall;

  const _RuntimePitfallLine({required this.pitfall});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.report_problem_outlined,
          size: 15,
          color: AppColors.goldDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '避免：${pitfall.riskyClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '改说：${pitfall.saferClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '原因：${pitfall.reason}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeEvolutionStepLine extends StatelessWidget {
  final LearningAgentRuntimeEvolutionStep step;

  const _RuntimeEvolutionStepLine({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.alt_route_outlined,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.milestone,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '当前基础：${step.currentFoundation}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '下一步：${step.nextUpgrade}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${step.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeDecisionRecordLine extends StatelessWidget {
  final LearningAgentRuntimeDecisionRecord record;

  const _RuntimeDecisionRecordLine({required this.record});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.fact_check_outlined,
          size: 15,
          color: AppColors.blueDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.decision,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '原因：${record.rationale}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '代价：${record.tradeoff}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${record.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeMigrationTriggerLine extends StatelessWidget {
  final LearningAgentRuntimeMigrationTrigger trigger;

  const _RuntimeMigrationTriggerLine({required this.trigger});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.outlined_flag,
          size: 15,
          color: AppColors.goldDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trigger.trigger,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '当前信号：${trigger.currentSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '升级动作：${trigger.upgradeAction}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${trigger.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeMaturityLevelLine extends StatelessWidget {
  final LearningAgentRuntimeMaturityLevel level;

  const _RuntimeMaturityLevelLine({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.stacked_line_chart,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.level,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '已有：${level.implementedSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '缺口：${level.missingCapability}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '下一层：${level.nextMilestone}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${level.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeFrameworkSelectionLine extends StatelessWidget {
  final LearningAgentRuntimeFrameworkSelection selection;

  const _RuntimeFrameworkSelectionLine({required this.selection});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.compare_arrows,
          size: 15,
          color: AppColors.purpleDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selection.framework,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '适合：${selection.bestFit}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '暂不采用：${selection.whyNotNow}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '接入路径：${selection.adoptionPath}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${selection.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeCodeWalkthroughStepLine extends StatelessWidget {
  final LearningAgentRuntimeCodeWalkthroughStep step;

  const _RuntimeCodeWalkthroughStepLine({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.route_outlined,
          size: 15,
          color: AppColors.blueDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.step,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.fileReference,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '看点：${step.whatToShow}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${step.interviewNarration}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeDebugScenarioLine extends StatelessWidget {
  final LearningAgentRuntimeDebugScenario scenario;

  const _RuntimeDebugScenarioLine({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.bug_report_outlined,
          size: 15,
          color: AppColors.redDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scenario.scenario,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '可能原因：${scenario.likelyCause}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '排查：${scenario.inspectionPath}',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '修复：${scenario.fixStrategy}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${scenario.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeDemoStepLine extends StatelessWidget {
  final LearningAgentRuntimeDemoStep step;

  const _RuntimeDemoStepLine({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.play_circle_outline,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.moment,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '操作：${step.appAction}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${step.narration}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '证据点：${step.proofPoint}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeSourceGroundingCheckLine extends StatelessWidget {
  final LearningAgentRuntimeSourceGroundingCheck check;

  const _RuntimeSourceGroundingCheckLine({required this.check});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.verified_outlined,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                check.check,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '核验：${check.verificationPath}',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '通过：${check.passSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '失败处理：${check.failureResponse}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${check.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeSourceReferenceLine extends StatelessWidget {
  final LearningAgentRuntimeSourceReference reference;

  const _RuntimeSourceReferenceLine({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.link,
          size: 15,
          color: AppColors.purpleDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${reference.title} · ${reference.sourceType}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reference.supports,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '可信度：${reference.trustNote}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '核验：${reference.verifiedAt} · ${reference.evidenceNote}',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reference.reference,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeAnswerRubricLine extends StatelessWidget {
  final LearningAgentRuntimeAnswerRubricItem item;

  const _RuntimeAnswerRubricLine({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.fact_check_outlined,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.criterion,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '达标：${item.passSignal}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '避免：${item.watchOut}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeAnswerScriptLine extends StatelessWidget {
  final String text;

  const _RuntimeAnswerScriptLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.article_outlined,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuntimeEvidenceAnchorLine extends StatelessWidget {
  final LearningAgentRuntimeEvidenceAnchor anchor;

  const _RuntimeEvidenceAnchorLine({required this.anchor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.code,
          size: 15,
          color: AppColors.blueDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                anchor.claim,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                anchor.codeReference,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                anchor.support,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuntimeBoundaryLine extends StatelessWidget {
  final LearningAgentRuntimeBoundaryNote note;

  const _RuntimeBoundaryLine({required this.note});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 15,
          color: AppColors.goldDark,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${note.topic}：${note.currentBoundary}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '讲法：${note.interviewClaim}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FrameworkMappingLine extends StatelessWidget {
  final LearningAgentFrameworkMapping mapping;

  const _FrameworkMappingLine({required this.mapping});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.account_tree_outlined,
          size: 15,
          color: AppColors.purple,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '${mapping.framework}：',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: '${mapping.borrowedPattern} -> '),
                TextSpan(
                  text: mapping.localComponent,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InterviewPromptLine extends StatelessWidget {
  final LearningAgentInterviewPrompt prompt;

  const _InterviewPromptLine({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.help_outline,
          size: 15,
          color: AppColors.textLight,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt.question,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '提纲：${prompt.outline}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '参考答法：${prompt.sampleAnswer}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '自评：${prompt.selfCheck}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '证据：${prompt.evidenceHint}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviousFollowUpPanel extends StatelessWidget {
  final String question;
  final int openCount;
  final VoidCallback? onOpenBacklog;

  const _PreviousFollowUpPanel({
    required this.question,
    required this.openCount,
    required this.onOpenBacklog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.question_answer_outlined,
            color: AppColors.blueDark,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '上次留下的问题',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (openCount > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    '同一目标还有 ${openCount - 1} 条未处理追问，可在历史页继续处理。',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blueDark,
                    ),
                  ),
                  if (onOpenBacklog != null) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: onOpenBacklog,
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text(
                        '查看这组追问',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.blueDark,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestGoalReviewPanel extends StatelessWidget {
  final LearningSession session;
  final VoidCallback onOpen;

  const _LatestGoalReviewPanel({
    required this.session,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final record = AgentSessionSummaryRecord.fromSession(session);
    final target = record.target?.trim();
    final subtitle = [
      if (target != null && target.isNotEmpty) '目标: $target',
      '开始于 ${_dateTimeText(session.startedAt)}',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history_toggle_off,
              color: AppColors.greenDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '最近一次同目标复盘',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(
                    '回看复盘',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.greenDark,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCriteriaPanel extends StatelessWidget {
  final List<String> criteria;
  final Set<int> checkedIndexes;
  final bool enabled;
  final void Function(int index, bool isChecked) onChanged;

  const _SuccessCriteriaPanel({
    required this.criteria,
    required this.checkedIndexes,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (criteria.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt, color: AppColors.green, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '本次成功标准',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!enabled) ...[
            const Text(
              '学习动作返回后，可以逐条确认本轮是否达标。',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (var index = 0; index < criteria.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: checkedIndexes.contains(index),
                      onChanged: enabled
                          ? (value) => onChanged(index, value ?? false)
                          : null,
                      activeColor: AppColors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      criteria[index],
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: checkedIndexes.contains(index)
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReflectionPromptPanel extends StatelessWidget {
  final List<String> prompts;

  const _ReflectionPromptPanel({required this.prompts});

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.blue, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '完成后复盘',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...prompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '?',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionReviewPanel extends StatelessWidget {
  final LearningAgentSessionSummary summary;
  final int checkedCount;
  final List<LearningAgentTraceEvent> traceEvents;
  final TextEditingController reflectionController;
  final TextEditingController nextQuestionController;

  const _CompletionReviewPanel({
    required this.summary,
    required this.checkedCount,
    required this.traceEvents,
    required this.reflectionController,
    required this.nextQuestionController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.celebration_outlined, color: AppColors.greenDark),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '本轮学习已返回',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '先按成功标准和复盘问题检查一遍，再回到 Agent 首页刷新下一步。',
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.task_alt,
            text: '已确认 $checkedCount/${summary.successCriteria.length} 条成功标准',
          ),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.edit_note,
            text: '复盘问题：${summary.reflectionPrompts.take(1).join()}',
          ),
          if (traceEvents.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AgentTracePreview(events: traceEvents),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: nextQuestionController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '下次最想让 Agent 追问什么',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.green),
              ),
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reflectionController,
            minLines: 2,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '写下本轮学到了什么、哪里还卡、下次要追问什么',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.green),
              ),
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentTracePreview extends StatelessWidget {
  final List<LearningAgentTraceEvent> events;

  const _AgentTracePreview({required this.events});

  @override
  Widget build(BuildContext context) {
    final previewEvents = events.take(5).toList();
    final remainingCount = events.length - previewEvents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 16,
              color: AppColors.greenDark,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                '执行轨迹',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.greenDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...previewEvents.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _AgentTraceRow(event: event),
          ),
        ),
        if (remainingCount > 0)
          Text(
            '还有 $remainingCount 条轨迹会随复盘保存。',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _AgentTraceRow extends StatelessWidget {
  final LearningAgentTraceEvent event;

  const _AgentTraceRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final meta = [
      _dateTimeText(event.occurredAt),
      if (event.evidenceChunkIds.isNotEmpty)
        '证据 ${event.evidenceChunkIds.length}',
      if (event.policyIssueCodes.isNotEmpty)
        '策略问题 ${event.policyIssueCodes.length}',
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _traceIcon(event),
          size: 14,
          color: _traceColor(event),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${event.type.label} · ${event.summary}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: _traceColor(event),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _traceIcon(LearningAgentTraceEvent event) {
    if (event.isFailure) return Icons.error_outline;
    switch (event.type) {
      case LearningAgentTraceEventType.planCreated:
        return Icons.route_outlined;
      case LearningAgentTraceEventType.policyChecked:
        return Icons.verified_user_outlined;
      case LearningAgentTraceEventType.toolSelected:
        return Icons.touch_app_outlined;
      case LearningAgentTraceEventType.toolInputRejected:
        return Icons.compare_arrows;
      case LearningAgentTraceEventType.toolStarted:
        return Icons.play_circle_outline;
      case LearningAgentTraceEventType.toolCompleted:
        return Icons.check_circle_outline;
      case LearningAgentTraceEventType.toolFailed:
        return Icons.error_outline;
      case LearningAgentTraceEventType.evidenceAttached:
        return Icons.link;
      case LearningAgentTraceEventType.userInterrupted:
        return Icons.pause_circle_outline;
      case LearningAgentTraceEventType.userDecisionRequested:
        return Icons.help_outline;
      case LearningAgentTraceEventType.userDecisionResolved:
        return Icons.rule;
      case LearningAgentTraceEventType.sessionResumed:
        return Icons.restore;
      case LearningAgentTraceEventType.reflectionSaved:
        return Icons.save_outlined;
    }
  }

  Color _traceColor(LearningAgentTraceEvent event) {
    switch (event.level) {
      case LearningAgentTraceLevel.info:
        return AppColors.textSecondary;
      case LearningAgentTraceLevel.warning:
        return AppColors.goldDark;
      case LearningAgentTraceLevel.error:
        return AppColors.red;
    }
  }
}

class _BlockerPanel extends StatelessWidget {
  final List<String> blockers;

  const _BlockerPanel({required this.blockers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.goldDark, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '仍需注意',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...blockers.take(3).map(
                (blocker) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          blocker,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (blockers.length > 3)
            Text(
              '还有 ${blockers.length - 3} 个缺口，可回到 Agent 首页继续查看。',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _EvidencePreviewPanel extends ConsumerWidget {
  final String knowledgePointId;

  const _EvidencePreviewPanel({required this.knowledgePointId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chunksAsync =
        ref.watch(knowledgePointEvidenceChunksProvider(knowledgePointId));

    return chunksAsync.when(
      data: (chunks) {
        if (chunks.isEmpty) {
          return const _EvidenceStatePanel(
            icon: Icons.article_outlined,
            title: '暂无可预览证据',
            subtitle: '这个推荐点还没有可读取的来源片段。',
          );
        }

        final previewChunks = chunks.take(2).toList();
        final remainingCount = chunks.length - previewChunks.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '证据预览',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...previewChunks.map(
              (chunk) => SourceCitationBlock(
                chunk: chunk,
                backgroundColor: AppColors.surface,
                border: Border.all(color: AppColors.border),
                maxContentLines: 3,
              ),
            ),
            if (remainingCount > 0)
              Text(
                '还有 $remainingCount 个证据片段，可打开知识点详情查看。',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        );
      },
      loading: () => const _EvidenceStatePanel(
        icon: Icons.hourglass_empty,
        title: '正在读取证据',
        subtitle: '准备页会优先展示推荐知识点的真实来源片段。',
      ),
      error: (error, _) => _EvidenceStatePanel(
        icon: Icons.error_outline,
        title: '证据读取失败',
        subtitle: '当前推荐点的来源片段暂时无法读取。',
        isError: true,
        recovery: KnowledgeLibraryErrorState(
          title: '证据读取失败',
          retryLabel: '重试读取证据',
          diagnosticTitle: 'Agent Session 准备页证据读取失败',
          diagnosticSuccessMessage: '已复制准备页证据读取诊断',
          diagnosticLines: [
            '入口: Agent Session 准备页',
            '知识点 ID: $knowledgePointId',
          ],
          error: error,
          onRetry: () => ref.invalidate(
            knowledgePointEvidenceChunksProvider(knowledgePointId),
          ),
        ),
      ),
    );
  }
}

class _EvidenceStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;
  final Widget? recovery;

  const _EvidenceStatePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
    this.recovery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isError ? AppColors.red : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isError ? AppColors.red : AppColors.textLight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isError ? AppColors.red : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recovery != null) ...[
            const SizedBox(height: 10),
            recovery!,
          ],
        ],
      ),
    );
  }
}

class _VerifiedQuestionPreviewPanel extends ConsumerWidget {
  final String knowledgePointId;

  const _VerifiedQuestionPreviewPanel({required this.knowledgePointId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync =
        ref.watch(knowledgePointQuestionsProvider(knowledgePointId));

    return questionsAsync.when(
      data: (questions) {
        final verifiedQuestions = questions
            .where((question) => question.sourceStatus == SourceStatus.verified)
            .toList();
        if (verifiedQuestions.isEmpty) {
          return const _EvidenceStatePanel(
            icon: Icons.quiz_outlined,
            title: '暂无已核验题预览',
            subtitle: '这个推荐点还没有可进入正式练习的题目。',
          );
        }

        final previewQuestions = verifiedQuestions.take(2).toList();
        final remainingCount =
            verifiedQuestions.length - previewQuestions.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '已核验题预览',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...previewQuestions.map(
              (question) => _VerifiedQuestionPreviewTile(
                question: question,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuestionEvidenceScreen(
                        question: question,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (remainingCount > 0)
              Text(
                '还有 $remainingCount 道已核验题，可在知识点详情或练习中继续查看。',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        );
      },
      loading: () => const _EvidenceStatePanel(
        icon: Icons.hourglass_empty,
        title: '正在读取题目',
        subtitle: '准备页只预览已核验题目。',
      ),
      error: (error, _) => _EvidenceStatePanel(
        icon: Icons.error_outline,
        title: '题目读取失败',
        subtitle: '当前推荐点的已核验题暂时无法读取。',
        isError: true,
        recovery: KnowledgeLibraryErrorState(
          title: '题目读取失败',
          retryLabel: '重试读取题目',
          diagnosticTitle: 'Agent Session 准备页题目读取失败',
          diagnosticSuccessMessage: '已复制准备页题目读取诊断',
          diagnosticLines: [
            '入口: Agent Session 准备页',
            '知识点 ID: $knowledgePointId',
          ],
          error: error,
          onRetry: () => ref.invalidate(
            knowledgePointQuestionsProvider(knowledgePointId),
          ),
        ),
      ),
    );
  }
}

class _VerifiedQuestionPreviewTile extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;

  const _VerifiedQuestionPreviewTile({
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniPill(
                      icon: Icons.quiz_outlined,
                      label: question.type.label,
                    ),
                    _MiniPill(
                      icon: Icons.verified_outlined,
                      label: question.sourceStatus.label,
                    ),
                    _MiniPill(
                      icon: Icons.link,
                      label: '${question.citationIds.length} 条引用',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutePanel extends StatelessWidget {
  final LearningAgentPlan plan;

  const _RoutePanel({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '执行路线',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...plan.steps.map((step) {
          final isNext = step.type == plan.sessionSummary.nextStep?.type;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RouteStepRow(step: step, isNext: isNext),
          );
        }),
      ],
    );
  }
}

class _RouteStepRow extends StatelessWidget {
  final LearningAgentPlanStep step;
  final bool isNext;

  const _RouteStepRow({
    required this.step,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isNext ? AppColors.greenLight : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNext ? AppColors.green : AppColors.border,
          width: isNext ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            step.enabled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: step.enabled ? AppColors.green : AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isNext ? AppColors.greenDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.enabled
                      ? step.description
                      : step.disabledReason ?? step.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isNext)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.play_arrow, color: AppColors.greenDark),
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppColors.greenDark),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

String _dateTimeText(DateTime value) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
