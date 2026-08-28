import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/product_event.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/agent/agent_learning_session_summary.dart';
import '../../services/agent/agent_session_memory_index.dart';
import '../../services/agent/agent_session_target_id.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';
import '../../services/agent/learning_agent_runtime_contracts.dart';
import '../../services/agent/learning_agent_workspace.dart';
import '../../services/agent/project_interview_outcome.dart';
import '../../shared/widgets/alpha_feedback_action.dart';
import '../knowledge_base/knowledge_answer_quality_notice.dart';
import '../knowledge_base/knowledge_answer_evidence_quality_badges.dart';
import '../knowledge_base/knowledge_answer_repair_action_button.dart';
import '../knowledge_base/knowledge_answer_review_copy_button.dart';
import '../knowledge_base/knowledge_answer_history_screen.dart';
import '../knowledge_base/knowledge_answer_session_detail_screen.dart';
import '../knowledge_base/knowledge_base_screen.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'agent_session_detail_screen.dart';
import 'agent_session_history_screen.dart';
import 'agent_session_launch_screen.dart';
import 'interview_session_detail_screen.dart';
import 'project_interview_outcome_screen.dart';

/// Agent 工作台主屏幕
///
/// **核心功能**:
/// - 学习目标选择器(面试准备/项目学习/自由探索)
/// - 项目面试结果入口(代码库分析结果)
/// - 多种 Agent 会话类型入口:
///   - 对话式面试(Interview Session): AI 逐个询问知识点
///   - 知识点问答(Tutor Session): 用户提问,AI 基于知识库回答
///   - 编程练习(Programming Exercise): 代码题实践
/// - Agent 记忆索引(跨会话上下文)
/// - 活跃检查点管理(学习进度追踪)
///
/// **技术特点**:
/// - 使用 Riverpod 管理多种异步数据流
/// - Alpha 功能反馈入口(diagnosticLines 传递诊断信息)
/// - 根据选定学习目标动态加载工作区配置
class AgentHomeScreen extends ConsumerWidget {
  final bool returnAfterSessionCompletion;

  const AgentHomeScreen({
    super.key,
    this.returnAfterSessionCompletion = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(interviewSessionListProvider);
    final tutorSessionsAsync = ref.watch(tutorSessionListProvider);
    final knowledgeAnswerSessionsAsync =
        ref.watch(knowledgeAnswerSessionListProvider);
    final agentMemoryAsync = ref.watch(agentSessionMemoryIndexProvider);
    final selectedGoal = ref.watch(learningAgentGoalProvider);
    final workspaceAsync =
        ref.watch(learningAgentWorkspaceProvider(selectedGoal));
    final activeCheckpointsAsync =
        ref.watch(learningAgentActiveCheckpointListProvider);
    final outcomeAsync = ref.watch(projectInterviewOutcomeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Agent 工作台',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AlphaFeedbackIconButton(
                  screenId: 'agent_workspace',
                  diagnosticLines: ['当前目标: ${selectedGoal.value}'],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LearningAgentGoalSelector(
              selected: selectedGoal,
              onSelected: (goal) {
                ref.read(learningAgentGoalProvider.notifier).setGoal(goal);
              },
            ),
            const SizedBox(height: 12),
            outcomeAsync.when(
              data: (outcome) => _ProjectInterviewOutcomeEntry(
                outcome: outcome,
                onTap: () => _openProjectInterviewOutcome(context, ref),
              ),
              loading: () => const _ProjectInterviewOutcomeEntrySkeleton(),
              error: (_, __) => _ProjectInterviewOutcomeEntryError(
                onRetry: () => ref.invalidate(projectInterviewOutcomeProvider),
              ),
            ),
            const SizedBox(height: 12),
            workspaceAsync.when(
              data: (workspace) {
                return Column(
                  children: [
                    _AgentWorkspaceViewedEvent(
                      key: ValueKey(workspace.goal.value),
                      workspace: workspace,
                    ),
                    _LearningAgentPlanCard(
                      workspace: workspace,
                      onFocusPointTap: (point) {
                        _openFocusPoint(context, ref, point);
                      },
                      onStart: workspace.plan.canExecuteNextAction
                          ? () => _startPlan(context, ref, workspace.plan)
                          : null,
                    ),
                  ],
                );
              },
              loading: () => const _PlanLoadingCard(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: 'Agent 工作台读取失败',
                retryLabel: '重试读取工作台',
                diagnosticTitle: 'Agent 首页工作台读取失败',
                diagnosticSuccessMessage: '已复制工作台读取诊断',
                diagnosticLines: [
                  '入口: Agent 首页',
                  '当前目标: ${selectedGoal.label}',
                ],
                error: error,
                onRetry: () => _refreshPlanInputs(ref),
              ),
            ),
            const SizedBox(height: 12),
            activeCheckpointsAsync.when(
              data: (checkpoints) {
                if (checkpoints.isEmpty) return const SizedBox.shrink();
                final runtime = ref.read(learningAgentRuntimeProvider);
                return Column(
                  children: [
                    ...checkpoints.map((checkpoint) {
                      final readiness =
                          runtime.evaluateResumeCheckpoint(checkpoint);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AgentResumeCheckpointCard(
                          checkpoint: checkpoint,
                          readiness: readiness,
                          onDiscard: () => _discardCheckpoint(
                            context,
                            ref,
                            checkpoint,
                          ),
                          onPrimaryAction: readiness.requiresUserDecision
                              ? () => _resolveCheckpointDecision(
                                    context,
                                    ref,
                                    checkpoint,
                                  )
                              : readiness.canResume
                                  ? () => _resumeCheckpoint(
                                        context,
                                        ref,
                                        checkpoint,
                                      )
                                  : null,
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Column(
                children: [
                  KnowledgeLibraryErrorState(
                    title: '未完成 Agent 会话读取失败',
                    retryLabel: '重试读取会话',
                    diagnosticTitle: 'Agent 首页 checkpoint 读取失败',
                    diagnosticSuccessMessage: '已复制 checkpoint 读取诊断',
                    diagnosticLines: const ['入口: Agent 首页'],
                    error: error,
                    onRetry: () => ref.invalidate(
                      learningAgentActiveCheckpointListProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            agentMemoryAsync.when(
              data: (memory) => _AgentMemorySummaryBar(
                memory: memory,
                selectedGoal: selectedGoal,
                onOpenGoalHistory: () => _openAgentSessionHistory(
                  context,
                  ref,
                  initialGoal: selectedGoal,
                ),
                onOpenGoalFollowUps: () => _openAgentSessionHistory(
                  context,
                  ref,
                  initialGoal: selectedGoal,
                  initialOnlyWithFollowUp: true,
                ),
                onOpenAllFollowUps: () => _openAgentSessionHistory(
                  context,
                  ref,
                  initialOnlyWithFollowUp: true,
                ),
                onOpenSession: (session) => _openAgentSessionDetail(
                  context,
                  ref,
                  session,
                ),
              ),
              loading: () => const _AgentMemorySummarySkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            workspaceAsync.when(
              data: (workspace) => _AgentToolTargetsPanel(
                workspace: workspace,
                onExecuteSelected: workspace.plan.canExecuteNextAction
                    ? () => _startPlan(context, ref, workspace.plan)
                    : null,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            const _SectionTitle(title: '最近 Agent Session'),
            const SizedBox(height: 10),
            agentMemoryAsync.when(
              data: (memory) {
                if (memory.sessions.isEmpty) {
                  return _EmptyAgentSessionHistory(
                    onOpenHistory: () => _openAgentSessionHistory(
                      context,
                      ref,
                    ),
                  );
                }
                return Column(
                  children: [
                    ...memory.sessions.take(3).map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AgentSessionHistoryCard(
                          session: session,
                          hasOpenFollowUp: memory.hasOpenFollowUp(session),
                          onTap: () => _openAgentSessionDetail(
                            context,
                            ref,
                            session,
                          ),
                        ),
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openAgentSessionHistory(context, ref);
                        },
                        icon: const Icon(Icons.history),
                        label: Text(
                          '查看全部 ${memory.totalCount} 条 Agent Session',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.greenDark,
                          side: const BorderSide(color: AppColors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
              ),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '最近 Agent Session 读取失败',
                retryLabel: '重试读取 Agent Session',
                diagnosticTitle: 'Agent 首页最近 Agent Session 读取失败',
                diagnosticSuccessMessage: '已复制 Agent Session 读取诊断',
                diagnosticLines: const ['入口: Agent 首页'],
                error: error,
                onRetry: () => _refreshAgentSessionInputs(ref),
              ),
            ),
            tutorSessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const _SectionTitle(title: '最近导师讲解'),
                    const SizedBox(height: 10),
                    ...sessions.take(3).map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TutorSessionHistoryCard(
                          session: session,
                          onOpenPoint: (point) => _openKnowledgePointDetail(
                            context,
                            ref,
                            point,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '最近导师讲解读取失败',
                retryLabel: '重试读取导师讲解',
                diagnosticTitle: 'Agent 首页最近导师讲解读取失败',
                diagnosticSuccessMessage: '已复制导师讲解读取诊断',
                diagnosticLines: const ['入口: Agent 首页'],
                error: error,
                onRetry: () => _refreshAgentSessionInputs(ref),
              ),
            ),
            knowledgeAnswerSessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) return const SizedBox.shrink();
                final stats = KnowledgeAnswerSessionStats.fromSessions(
                  sessions,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(title: '最近知识库问答'),
                        ),
                        TextButton.icon(
                          onPressed: () => _openKnowledgeAnswerHistory(
                            context,
                            ref,
                          ),
                          icon: const Icon(Icons.history, size: 18),
                          label: Text('查看全部 ${sessions.length}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (stats.hasQualityIssues) ...[
                      KnowledgeAnswerQualityNotice(
                        stats: stats,
                        onOpenQualityIssues: () => _openKnowledgeAnswerHistory(
                          context,
                          ref,
                          initialOnlyQualityIssues: true,
                        ),
                        onOpenMissingCitations: () =>
                            _openKnowledgeAnswerHistory(
                          context,
                          ref,
                          initialOnlyWithoutCitations: true,
                        ),
                        onOpenSourceGaps: () => _openKnowledgeAnswerHistory(
                          context,
                          ref,
                          initialOnlyWithSourceGaps: true,
                        ),
                        onOpenRepairable: () => _openKnowledgeAnswerHistory(
                          context,
                          ref,
                          initialOnlyRepairable: true,
                        ),
                        onOpenNeedsReview: () => _openKnowledgeAnswerHistory(
                          context,
                          ref,
                          initialOnlyNeedsReview: true,
                        ),
                        onOpenCleanEvidence: () => _openKnowledgeAnswerHistory(
                          context,
                          ref,
                          initialOnlyCleanEvidence: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ...sessions.take(3).map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _KnowledgeAnswerHistoryCard(
                          session: session,
                          onOpen: () => _openKnowledgeAnswerDetail(
                            context,
                            ref,
                            session,
                          ),
                          onRepairSearch: (query) {
                            _openKnowledgeAnswerSearch(context, ref, query);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '最近知识库问答读取失败',
                retryLabel: '重试读取问答',
                diagnosticTitle: 'Agent 首页最近知识库问答读取失败',
                diagnosticSuccessMessage: '已复制最近知识库问答读取诊断',
                diagnosticLines: const ['入口: Agent 首页'],
                error: error,
                onRetry: () => ref.invalidate(
                  knowledgeAnswerSessionListProvider,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _SectionTitle(title: '最近面试复盘'),
            const SizedBox(height: 10),
            sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const _EmptyHistory();
                }
                return Column(
                  children: sessions.take(5).map((session) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SessionHistoryCard(
                        session: session,
                        onOpen: () => _openInterviewSessionDetail(
                          context,
                          ref,
                          session,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
              ),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '最近面试复盘读取失败',
                retryLabel: '重试读取面试复盘',
                diagnosticTitle: 'Agent 首页最近面试复盘读取失败',
                diagnosticSuccessMessage: '已复制面试复盘读取诊断',
                diagnosticLines: const ['入口: Agent 首页'],
                error: error,
                onRetry: () => _refreshAgentSessionInputs(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPlan(
    BuildContext context,
    WidgetRef ref,
    LearningAgentPlan plan,
  ) async {
    final nextAction = plan.nextAction;
    if (nextAction != null && !nextAction.executable) {
      _showAgentMessage(
        context,
        nextAction.blockerMessage ?? '下一动作当前不可执行',
      );
      return;
    }
    if (nextAction?.resumesCheckpoint == true) {
      final sessionId = nextAction!.checkpointSessionId!;
      final checkpoint =
          await ref.read(learningAgentCheckpointStoreProvider).load(sessionId);
      if (!context.mounted) return;
      if (checkpoint == null) {
        ref.invalidate(learningAgentActiveCheckpointListProvider);
        _showAgentMessage(context, '未完成会话已不存在，正在重新规划下一动作。');
        return;
      }
      final readiness =
          ref.read(learningAgentRuntimeProvider).evaluateResumeCheckpoint(
                checkpoint,
              );
      if (readiness.requiresUserDecision) {
        await _resolveCheckpointDecision(context, ref, checkpoint);
      } else if (readiness.canResume) {
        await _resumeCheckpoint(context, ref, checkpoint);
      } else {
        _showAgentMessage(context, readiness.message);
        ref.invalidate(learningAgentActiveCheckpointListProvider);
      }
      return;
    }

    final step = plan.nextStep;
    if (step == null) return;

    final blockReason = plan.startBlockReason;
    if (blockReason != null) {
      _showAgentMessage(context, blockReason);
      return;
    }

    if (step.type == LearningAgentStepType.handleFollowUps) {
      _showAgentMessage(context, '打开当前目标未处理追问');
      await _openAgentSessionHistory(
        context,
        ref,
        initialGoal: plan.goal,
        initialOnlyWithFollowUp: true,
      );
      return;
    }

    _showAgentMessage(
      context,
      '准备 ${plan.sessionSummary.title}：${plan.sessionSummary.targetLabel}',
    );

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AgentSessionLaunchScreen(plan: plan),
      ),
    );

    if (!context.mounted) return;
    ref.invalidate(learningAgentActiveCheckpointListProvider);
    if (completed == true) {
      _handleSessionCompleted(context, ref);
    }
  }

  Future<void> _resumeCheckpoint(
    BuildContext context,
    WidgetRef ref,
    LearningAgentCheckpoint checkpoint,
  ) async {
    final goalNotifier = ref.read(learningAgentGoalProvider.notifier);
    final runtime = ref.read(learningAgentRuntimeProvider);
    try {
      await goalNotifier.setGoal(checkpoint.state.goal);
      final result = await runtime.resumeCheckpoint(
        checkpoint,
        reason: '从 Agent 首页继续未完成会话',
      );
      if (!context.mounted) return;
      final session = result.session;
      if (session == null) {
        _showAgentMessage(context, result.readiness.message);
        ref.invalidate(learningAgentActiveCheckpointListProvider);
        return;
      }

      await _openResumedSession(context, ref, session);
    } catch (error) {
      if (!context.mounted) return;
      if (error is LearningAgentCheckpointConflictException) {
        ref.invalidate(learningAgentActiveCheckpointListProvider);
        _showAgentMessage(context, '会话已在其他流程更新，正在读取最新 checkpoint。');
        return;
      }
      _showAgentMessage(context, 'Agent Session 恢复失败: $error');
    }
  }

  Future<void> _resolveCheckpointDecision(
    BuildContext context,
    WidgetRef ref,
    LearningAgentCheckpoint checkpoint,
  ) async {
    final request = checkpoint.state.pendingUserDecision;
    if (request == null) {
      _showAgentMessage(context, '当前会话没有待处理的用户决策。');
      ref.invalidate(learningAgentActiveCheckpointListProvider);
      return;
    }
    final isUnknownOutcome =
        request.reason == LearningAgentUserDecisionReason.toolOutcomeUnknown;

    var decisionNote = '';
    final action = await showDialog<LearningAgentUserDecisionAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isUnknownOutcome ? '确认工具执行结果' : '处理 Agent 决策'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.prompt,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '原因：${request.reason.label}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (request.operationId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Operation：${request.operationId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (checkpoint.state.activeToolInputSnapshot != null) ...[
                const SizedBox(height: 4),
                Text(
                  '输入：${checkpoint.state.activeToolInputSnapshot!.toolId}'
                  ' / target='
                  '${checkpoint.state.activeToolInputSnapshot!.targetId ?? '-'}'
                  ' / evidence='
                  '${checkpoint.state.activeToolInputSnapshot!.evidenceChunkIds.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (request.attemptId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Attempt：${request.attemptId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => decisionNote = value,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '决策备注（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('稍后处理'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(
              LearningAgentUserDecisionAction.cancelSession,
            ),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('结束会话'),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
          ),
          if (isUnknownOutcome)
            TextButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(
                LearningAgentUserDecisionAction.confirmToolCompleted,
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('确认已完成'),
            ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(
              LearningAgentUserDecisionAction.continueSession,
            ),
            icon: Icon(isUnknownOutcome ? Icons.replay : Icons.play_arrow),
            label: Text(isUnknownOutcome ? '重新执行' : '继续执行'),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;

    final runtime = ref.read(learningAgentRuntimeProvider);
    try {
      final result = await runtime.resolveUserDecision(
        checkpoint,
        action: action,
        note: decisionNote,
      );
      if (!context.mounted) return;
      ref.invalidate(learningAgentActiveCheckpointListProvider);
      final session = result.session;
      if (session == null) {
        _showAgentMessage(context, 'Agent Session 已结束，决策与执行轨迹已保存。');
        return;
      }

      await ref
          .read(learningAgentGoalProvider.notifier)
          .setGoal(checkpoint.state.goal);
      if (!context.mounted) return;
      await _openResumedSession(context, ref, session);
    } catch (error) {
      if (!context.mounted) return;
      if (error is LearningAgentCheckpointConflictException) {
        ref.invalidate(learningAgentActiveCheckpointListProvider);
        _showAgentMessage(context, '该决策已被处理，正在读取最新 checkpoint。');
        return;
      }
      _showAgentMessage(context, '用户决策保存失败: $error');
    }
  }

  Future<void> _openResumedSession(
    BuildContext context,
    WidgetRef ref,
    LearningAgentRuntimeSession session,
  ) async {
    _showAgentMessage(
      context,
      '恢复 ${session.plan.sessionSummary.title}：${session.plan.sessionSummary.targetLabel}',
    );
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AgentSessionLaunchScreen(
          plan: session.plan,
          initialRuntimeSession: session,
        ),
      ),
    );
    if (!context.mounted) return;
    ref.invalidate(learningAgentActiveCheckpointListProvider);
    if (completed == true) {
      _handleSessionCompleted(context, ref);
    }
  }

  void _handleSessionCompleted(BuildContext context, WidgetRef ref) {
    _refreshAgentSessionInputs(ref);
    if (returnAfterSessionCompletion && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _discardCheckpoint(
    BuildContext context,
    WidgetRef ref,
    LearningAgentCheckpoint checkpoint,
  ) async {
    final checkpointStore = ref.read(learningAgentCheckpointStoreProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除未完成会话？'),
        content: const Text('本地 checkpoint 和执行轨迹将被删除，已完成的学习记录不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await checkpointStore.delete(checkpoint.sessionId);
      if (!context.mounted) return;
      ref.invalidate(learningAgentActiveCheckpointListProvider);
      _showAgentMessage(context, '未完成 Agent Session 已删除。');
    } catch (error) {
      if (!context.mounted) return;
      _showAgentMessage(context, '删除未完成会话失败: $error');
    }
  }

  Future<void> _openAgentSessionHistory(
    BuildContext context,
    WidgetRef ref, {
    LearningAgentGoal? initialGoal,
    bool initialOnlyWithFollowUp = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgentSessionHistoryScreen(
          initialGoal: initialGoal,
          initialOnlyWithFollowUp: initialOnlyWithFollowUp,
        ),
      ),
    );
    if (!context.mounted) return;
    _refreshAgentSessionInputs(ref);
  }

  Future<void> _openProjectInterviewOutcome(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProjectInterviewOutcomeScreen(),
      ),
    );
    if (!context.mounted) return;
    ref.invalidate(projectInterviewOutcomeProvider);
  }

  Future<void> _openAgentSessionDetail(
    BuildContext context,
    WidgetRef ref,
    LearningSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgentSessionDetailScreen(session: session),
      ),
    );
    if (!context.mounted) return;
    _refreshAgentSessionInputs(ref);
  }

  Future<void> _openInterviewSessionDetail(
    BuildContext context,
    WidgetRef ref,
    LearningSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterviewSessionDetailScreen(session: session),
      ),
    );
    if (!context.mounted) return;
    _refreshAgentSessionInputs(ref);
  }

  Future<void> _openKnowledgePointDetail(
    BuildContext context,
    WidgetRef ref,
    KnowledgePoint point,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KnowledgePointDetailScreen(point: point),
      ),
    );
    if (!context.mounted) return;
    _refreshAgentSessionInputs(ref);
  }

  Future<void> _openKnowledgeAnswerSearch(
    BuildContext context,
    WidgetRef ref,
    String question,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KnowledgeBaseScreen(
          initialSearchQuery: question,
        ),
      ),
    );
    if (!context.mounted) return;
    _refreshAgentSessionInputs(ref);
  }

  Future<void> _openKnowledgeAnswerDetail(
    BuildContext context,
    WidgetRef ref,
    LearningSession session,
  ) async {
    final question = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => KnowledgeAnswerSessionDetailScreen(
          session: session,
          onOpenSourceChunk: _openKnowledgeAnswerSourceChunk,
        ),
      ),
    );
    if (!context.mounted) return;
    if (question == null || question.trim().isEmpty) {
      _refreshAgentSessionInputs(ref);
      return;
    }
    await _openKnowledgeAnswerSearch(context, ref, question);
  }

  Future<void> _openKnowledgeAnswerHistory(
    BuildContext context,
    WidgetRef ref, {
    String? initialSearchQuery,
    bool initialOnlyCleanEvidence = false,
    bool initialOnlyQualityIssues = false,
    bool initialOnlyWithoutCitations = false,
    bool initialOnlyWithSourceGaps = false,
    bool initialOnlyRepairable = false,
    bool initialOnlyNeedsReview = false,
  }) async {
    final question = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => KnowledgeAnswerHistoryScreen(
          onOpenSourceChunk: _openKnowledgeAnswerSourceChunk,
          initialSearchQuery: initialSearchQuery,
          initialOnlyCleanEvidence: initialOnlyCleanEvidence,
          initialOnlyQualityIssues: initialOnlyQualityIssues,
          initialOnlyWithoutCitations: initialOnlyWithoutCitations,
          initialOnlyWithSourceGaps: initialOnlyWithSourceGaps,
          initialOnlyRepairable: initialOnlyRepairable,
          initialOnlyNeedsReview: initialOnlyNeedsReview,
        ),
      ),
    );
    if (!context.mounted) return;
    if (question == null || question.trim().isEmpty) {
      _refreshAgentSessionInputs(ref);
      return;
    }
    await _openKnowledgeAnswerSearch(context, ref, question);
  }

  Future<void> _openKnowledgeAnswerSourceChunk(
    BuildContext context,
    Source source,
    SourceChunk chunk,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SourceDetailScreen(
          source: source,
          highlightedChunkId: chunk.id,
          highlightedChunkLabel: '当前引用片段',
          highlightedChunkIcon: Icons.link,
        ),
      ),
    );
  }

  void _showAgentMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openFocusPoint(
    BuildContext context,
    WidgetRef ref,
    LearningAgentFocusPoint focusPoint,
  ) async {
    final point = await ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePoint(focusPoint.id);
    if (!context.mounted) return;

    if (point == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const KnowledgeBaseScreen(initialTabIndex: 2),
        ),
      );
      if (!context.mounted) return;
      _refreshPlanInputs(ref);
      return;
    }

    await _openKnowledgePointDetail(context, ref, point);
  }

  void _refreshPlanInputs(WidgetRef ref) {
    final goal = ref.read(learningAgentGoalProvider);
    invalidateLearningAgentPlanInputProviders(ref, goal);
    ref.invalidate(learningAgentWorkspaceProvider(goal));
  }

  void _refreshAgentSessionInputs(WidgetRef ref) {
    invalidateAgentLearningRecordProviders(ref);
    ref.invalidate(learningAgentActiveCheckpointListProvider);
    _refreshPlanInputs(ref);
  }
}

class _ProjectInterviewOutcomeEntry extends StatelessWidget {
  final ProjectInterviewOutcome outcome;
  final VoidCallback onTap;

  const _ProjectInterviewOutcomeEntry({
    required this.outcome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '项目面试成果',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outcome.units.isEmpty
                          ? '确认项目学习单元后形成可追溯成果'
                          : '可面试 ${outcome.readyCount} · 需练习 ${outcome.needsPracticeCount} · 证据缺口 ${outcome.evidenceGapCount} · 未评估 ${outcome.notAssessedCount}',
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
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectInterviewOutcomeEntrySkeleton extends StatelessWidget {
  const _ProjectInterviewOutcomeEntrySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      alignment: Alignment.center,
      child: const SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ProjectInterviewOutcomeEntryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProjectInterviewOutcomeEntryError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('重新读取项目面试成果'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _AgentResumeCheckpointCard extends StatelessWidget {
  final LearningAgentCheckpoint checkpoint;
  final LearningAgentResumeReadiness readiness;
  final VoidCallback onDiscard;
  final VoidCallback? onPrimaryAction;

  const _AgentResumeCheckpointCard({
    required this.checkpoint,
    required this.readiness,
    required this.onDiscard,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final state = checkpoint.state;
    final tool = const LearningAgentToolRegistry().toolForIdValue(
      state.selectedToolId ?? '',
    );
    final pendingDecision = state.pendingUserDecision;
    final actionLabel = readiness.requiresUserDecision
        ? pendingDecision?.reason ==
                LearningAgentUserDecisionReason.toolOutcomeUnknown
            ? '确认工具结果'
            : '处理用户决策'
        : readiness.canResume
            ? '继续会话'
            : '暂不可恢复';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restore, color: AppColors.blueDark),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '未完成 Agent Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                state.phase.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDiscard,
                tooltip: '删除未完成会话',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${state.goal.label} · ${tool?.title ?? '未记录工具'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            readiness.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '更新 ${_dateText(state.updatedAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${checkpoint.traceEvents.length} 条轨迹',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'revision ${checkpoint.revision}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPrimaryAction,
              icon: Icon(
                readiness.requiresUserDecision
                    ? Icons.help_outline
                    : Icons.play_arrow,
              ),
              label: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surface,
                disabledForegroundColor: AppColors.textLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentMemorySummaryBar extends StatelessWidget {
  final AgentSessionMemoryIndex memory;
  final LearningAgentGoal selectedGoal;
  final VoidCallback onOpenGoalHistory;
  final VoidCallback onOpenGoalFollowUps;
  final VoidCallback onOpenAllFollowUps;
  final ValueChanged<LearningSession> onOpenSession;

  const _AgentMemorySummaryBar({
    required this.memory,
    required this.selectedGoal,
    required this.onOpenGoalHistory,
    required this.onOpenGoalFollowUps,
    required this.onOpenAllFollowUps,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final goalCount = memory.countForGoal(selectedGoal);
    final followUpCount = memory.openFollowUpCount;
    final goalFollowUpCount = memory.openFollowUpCountForGoal(selectedGoal);
    final latestGoalSession = memory.latestSessionForGoal(selectedGoal);
    final latestGoalRecord = latestGoalSession == null
        ? null
        : AgentSessionSummaryRecord.fromSession(latestGoalSession);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.memory, color: AppColors.blue, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '学习记忆',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MemoryMetric(label: 'Agent Session', value: memory.totalCount),
              _MemoryMetric(label: selectedGoal.label, value: goalCount),
              _MemoryMetric(label: '当前目标追问', value: goalFollowUpCount),
              _MemoryMetric(label: '未处理追问', value: followUpCount),
            ],
          ),
          ..._latestGoalSessionWidgets(
            session: latestGoalSession,
            record: latestGoalRecord,
          ),
          if (goalCount > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenGoalHistory,
                icon: const Icon(Icons.track_changes),
                label: Text(
                  '查看当前目标 $goalCount 条记录',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.greenDark,
                  side: const BorderSide(color: AppColors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (goalFollowUpCount > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenGoalFollowUps,
                icon: const Icon(Icons.question_answer_outlined),
                label: Text(
                  '查看当前目标 $goalFollowUpCount 条追问',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blueDark,
                  side: const BorderSide(color: AppColors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else if (followUpCount > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenAllFollowUps,
                icon: const Icon(Icons.question_answer_outlined),
                label: Text(
                  '查看全部 $followUpCount 条未处理追问',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blueDark,
                  side: const BorderSide(color: AppColors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _latestGoalSessionWidgets({
    required LearningSession? session,
    required AgentSessionSummaryRecord? record,
  }) {
    if (session == null || record == null) return const [];

    return [
      const SizedBox(height: 10),
      _LatestGoalSessionRow(
        session: session,
        record: record,
        onOpen: () => onOpenSession(session),
      ),
    ];
  }
}

class _LatestGoalSessionRow extends StatelessWidget {
  final LearningSession session;
  final AgentSessionSummaryRecord record;
  final VoidCallback onOpen;

  const _LatestGoalSessionRow({
    required this.session,
    required this.record,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final target = record.target?.trim();
    final subtitle = [
      if (target != null && target.isNotEmpty) '目标: $target',
      '开始于 ${_dateText(session.startedAt)}',
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.history_toggle_off, color: AppColors.greenDark),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最近：${record.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text(
            '回看',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.greenDark,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _AgentMemorySummarySkeleton extends StatelessWidget {
  const _AgentMemorySummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: const Text(
        '正在读取学习记忆...',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MemoryMetric extends StatelessWidget {
  final String label;
  final int value;

  const _MemoryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AgentWorkspaceViewedEvent extends ConsumerStatefulWidget {
  final LearningAgentWorkspaceSnapshot workspace;

  const _AgentWorkspaceViewedEvent({
    super.key,
    required this.workspace,
  });

  @override
  ConsumerState<_AgentWorkspaceViewedEvent> createState() =>
      _AgentWorkspaceViewedEventState();
}

class _AgentWorkspaceViewedEventState
    extends ConsumerState<_AgentWorkspaceViewedEvent> {
  late final String _flowId =
      'agent_workspace_${DateTime.now().toUtc().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  Future<void> _record() async {
    final workspace = widget.workspace;
    final nextAction = workspace.plan.nextAction;
    await ref.read(productEventRecorderProvider).recordBestEffort(
          ProductEventName.agentWorkspaceViewed,
          flowId: _flowId,
          goal: workspace.goal.value,
          targetId: nextAction?.targetId,
          sessionId: nextAction?.checkpointSessionId,
          properties: {
            'scope': workspace.knowledgeScope.value,
            'next_action_type': nextAction?.priority.value ?? 'none',
            'blocker_code': nextAction?.blockerCode ?? 'none',
          },
          dedupeKey: '$_flowId:agent_workspace_viewed',
        );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _LearningAgentGoalSelector extends StatelessWidget {
  final LearningAgentGoal selected;
  final ValueChanged<LearningAgentGoal> onSelected;

  const _LearningAgentGoalSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LearningAgentGoal.values.map((goal) {
        final isSelected = goal == selected;
        return ChoiceChip(
          label: Text(goal.label),
          selected: isSelected,
          onSelected: (_) => onSelected(goal),
          selectedColor: AppColors.greenLight,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.green : AppColors.border,
            width: 1.5,
          ),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.greenDark : AppColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }
}

class _LearningAgentPlanCard extends StatelessWidget {
  final LearningAgentWorkspaceSnapshot workspace;
  final VoidCallback? onStart;
  final ValueChanged<LearningAgentFocusPoint> onFocusPointTap;

  const _LearningAgentPlanCard({
    required this.workspace,
    required this.onStart,
    required this.onFocusPointTap,
  });

  @override
  Widget build(BuildContext context) {
    final plan = workspace.plan;
    final nextAction = plan.nextAction;
    final nextStep = plan.nextStep;
    final isFollowUpStep =
        nextAction?.priority == LearningAgentNextActionPriority.openFollowUp;
    final isCheckpointResume = nextAction?.resumesCheckpoint == true;
    final selectedTool = nextAction?.toolId == null
        ? null
        : const LearningAgentToolRegistry().toolForIdValue(
            nextAction!.toolId!,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.greenDark, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${plan.goal.label}路线',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
              _PlanScoreChip(score: plan.readiness.score),
            ],
          ),
          const SizedBox(height: 10),
          _PlanScopeChip(scope: plan.knowledgeScope),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlanMetric(
                label: '有来源',
                value: plan.readiness.evidenceBackedPointCount,
              ),
              _PlanMetric(
                label: '可练习',
                value: plan.readiness.practiceablePointCount,
              ),
              _PlanMetric(
                label: '已核验练习',
                value: plan.readiness.verifiedPracticeTargetCount,
              ),
              _PlanMetric(
                label: '待核验',
                value: plan.readiness.pendingVerificationCount,
              ),
              _PlanMetric(
                label: '历史',
                value: workspace.historyRecordCount,
              ),
              _PlanMetric(
                label: '待复习',
                value: workspace.pendingReviewCount,
              ),
            ],
          ),
          if (workspace.nextReviewAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.event_repeat,
                  size: 16,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '下一复习：${_dateText(workspace.nextReviewAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            nextAction == null
                ? nextStep == null
                    ? '暂无可执行步骤'
                    : '下一步：${nextStep.title}'
                : '${nextAction.priority.label}：${nextAction.title}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (nextAction != null) ...[
            const SizedBox(height: 4),
            Text(
              nextAction.reason,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '对应工具：${selectedTool?.title ?? nextAction.toolId ?? '无'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDark,
              ),
            ),
            if (!nextAction.executable &&
                nextAction.blockerMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                '阻断：${nextAction.blockerMessage}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                ),
              ),
            ],
          ] else if (nextStep != null) ...[
            const SizedBox(height: 4),
            Text(
              nextStep.description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (plan.blockers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '缺口：${plan.blockers.take(2).join(' · ')}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: Icon(
                isCheckpointResume
                    ? Icons.restore
                    : isFollowUpStep
                        ? Icons.question_answer_outlined
                        : Icons.play_arrow,
              ),
              label: Text(
                isCheckpointResume
                    ? '继续未完成会话'
                    : isFollowUpStep
                        ? '查看未处理追问'
                        : '执行下一步',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textLight,
                disabledBackgroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _PlanDetailsDisclosure(
            plan: plan,
            onFocusPointTap: onFocusPointTap,
          ),
        ],
      ),
    );
  }
}

class _PlanDetailsDisclosure extends StatelessWidget {
  final LearningAgentPlan plan;
  final ValueChanged<LearningAgentFocusPoint> onFocusPointTap;

  const _PlanDetailsDisclosure({
    required this.plan,
    required this.onFocusPointTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          iconColor: AppColors.greenDark,
          collapsedIconColor: AppColors.greenDark,
          title: const Text(
            '计划依据',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          children: [
            _AgentSessionSummaryView(summary: plan.sessionSummary),
            if (plan.focusPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '优先关注',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...plan.focusPoints.map(
                (point) => _FocusPointRow(
                  point: point,
                  onTap: () => onFocusPointTap(point),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentToolTargetsPanel extends StatelessWidget {
  final LearningAgentWorkspaceSnapshot workspace;
  final VoidCallback? onExecuteSelected;

  const _AgentToolTargetsPanel({
    required this.workspace,
    required this.onExecuteSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (workspace.toolTargets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hub_outlined, color: AppColors.blue, size: 20),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                '工具目标',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${workspace.toolTargets.length} 项',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...workspace.toolTargets.map(
          (target) => _AgentToolTargetRow(
            target: target,
            onExecute: target.canExecute ? onExecuteSelected : null,
          ),
        ),
      ],
    );
  }
}

class _AgentToolTargetRow extends StatelessWidget {
  final LearningAgentWorkspaceToolTarget target;
  final VoidCallback? onExecute;

  const _AgentToolTargetRow({
    required this.target,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toolStateColor(target.state);
    final targetCount = target.step.targetCount;
    final detail = targetCount > 0
        ? '${target.step.description} · $targetCount 项'
        : target.step.description;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      decoration: BoxDecoration(
        color: target.isNextAction ? AppColors.greenLight : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Icon(_toolIcon(target.tool.id), color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          target.tool.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        target.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (onExecute != null)
            Tooltip(
              message: '执行下一动作',
              child: IconButton(
                onPressed: onExecute,
                icon: const Icon(Icons.play_arrow),
                color: AppColors.greenDark,
              ),
            )
          else
            SizedBox(
              width: 48,
              child: Icon(
                target.state == LearningAgentWorkspaceToolState.blocked
                    ? Icons.block
                    : target.state == LearningAgentWorkspaceToolState.available
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                size: 18,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  static IconData _toolIcon(LearningAgentToolId id) {
    switch (id) {
      case LearningAgentToolId.importSources:
        return Icons.upload_file_outlined;
      case LearningAgentToolId.verifyPendingQuestions:
        return Icons.fact_check_outlined;
      case LearningAgentToolId.handleFollowUps:
        return Icons.question_answer_outlined;
      case LearningAgentToolId.searchKnowledgeBase:
        return Icons.search;
      case LearningAgentToolId.openTutorSession:
        return Icons.school_outlined;
      case LearningAgentToolId.openInterviewSession:
        return Icons.record_voice_over_outlined;
      case LearningAgentToolId.startVerifiedPractice:
        return Icons.code;
      case LearningAgentToolId.startReviewSession:
        return Icons.event_repeat;
      case LearningAgentToolId.saveAgentReflection:
        return Icons.edit_note_outlined;
    }
  }

  static Color _toolStateColor(LearningAgentWorkspaceToolState state) {
    switch (state) {
      case LearningAgentWorkspaceToolState.nextAction:
        return AppColors.greenDark;
      case LearningAgentWorkspaceToolState.available:
        return AppColors.blueDark;
      case LearningAgentWorkspaceToolState.blocked:
        return AppColors.red;
      case LearningAgentWorkspaceToolState.unavailable:
        return AppColors.textLight;
    }
  }
}

class _FocusPointRow extends StatelessWidget {
  final LearningAgentFocusPoint point;
  final VoidCallback onTap;

  const _FocusPointRow({
    required this.point,
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${point.reason} · 掌握 ${point.masteryLevel}% · '
                        '面试 ${point.interviewRelevance}',
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _FocusPointMeta(
                            icon: Icons.article_outlined,
                            label: '证据 ${point.evidenceChunkCount}',
                          ),
                          _FocusPointMeta(
                            icon: Icons.fact_check_outlined,
                            label: '可练习 ${point.verifiedPracticeTargetCount}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentSessionSummaryView extends StatelessWidget {
  final LearningAgentSessionSummary summary;

  const _AgentSessionSummaryView({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前 Agent Session：${summary.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.greenDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          summary.objective,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _AgentSessionRuleRow(
          icon: Icons.flag_outlined,
          text: '目标：${summary.targetLabel}',
        ),
        const SizedBox(height: 4),
        _AgentSessionRuleRow(
          icon: Icons.policy_outlined,
          text: '来源约束：${summary.evidenceConstraint}',
        ),
        if (summary.memoryReminder != null) ...[
          const SizedBox(height: 4),
          _AgentSessionRuleRow(
            icon: Icons.memory_outlined,
            text: '学习记忆：${summary.memoryReminder}',
          ),
        ],
      ],
    );
  }
}

class _AgentSessionRuleRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AgentSessionRuleRow({
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
          child: Icon(icon, size: 14, color: AppColors.greenDark),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
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

class _FocusPointMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FocusPointMeta({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _PlanMetric extends StatelessWidget {
  final String label;
  final int value;

  const _PlanMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PlanScopeChip extends StatelessWidget {
  final LearningAgentKnowledgeScope scope;

  const _PlanScopeChip({required this.scope});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 15,
            color: AppColors.greenDark,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '知识范围：${scope.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanScoreChip extends StatelessWidget {
  final int score;

  const _PlanScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green),
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.greenDark,
        ),
      ),
    );
  }
}

class _PlanLoadingCard extends StatelessWidget {
  const _PlanLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
    );
  }
}

class _SessionHistoryCard extends ConsumerWidget {
  final LearningSession session;
  final VoidCallback onOpen;

  const _SessionHistoryCard({
    required this.session,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnsAsync = ref.watch(interviewTurnsProvider(session.id));

    return turnsAsync.when(
      data: (turns) => _SessionHistoryContent(
        session: session,
        turns: turns,
        onTap: onOpen,
      ),
      loading: () => _SessionHistoryContent(
        session: session,
        turns: const [],
        isLoading: true,
        onTap: () {},
      ),
      error: (_, __) => _SessionHistoryContent(
        session: session,
        turns: const [],
        hasError: true,
        onTap: () {},
      ),
    );
  }
}

class _TutorSessionHistoryCard extends ConsumerWidget {
  final LearningSession session;
  final ValueChanged<KnowledgePoint> onOpenPoint;

  const _TutorSessionHistoryCard({
    required this.session,
    required this.onOpenPoint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpQuestion = followUpQuestionFromLearningSessionSummary(
      session.summary,
    );
    final targetId = normalizeAgentSessionTargetId(session.targetId);
    final pointAsync =
        targetId == null ? null : ref.watch(knowledgePointProvider(targetId));
    final point = pointAsync?.maybeWhen(
      data: (point) => point,
      orElse: () => null,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: point == null ? null : () => onOpenPoint(point),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tutorTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '完成于 ${_dateText(session.endedAt ?? session.startedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (followUpQuestion != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '本轮追问: $followUpQuestion',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (point != null) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _tutorTitle {
    final summary = session.summary?.trim();
    if (summary == null || summary.isEmpty) return '导师讲解';
    return summary.split('\n').first.trim();
  }
}

class _KnowledgeAnswerHistoryCard extends StatelessWidget {
  final LearningSession session;
  final VoidCallback onOpen;
  final ValueChanged<String> onRepairSearch;

  const _KnowledgeAnswerHistoryCard({
    required this.session,
    required this.onOpen,
    required this.onRepairSearch,
  });

  @override
  Widget build(BuildContext context) {
    final summary = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
    final question = summary.question ?? '知识库问答';
    final answer = summary.answer;
    final completedText = _dateText(session.endedAt ?? session.startedAt);
    final detailParts = [
      '完成于 $completedText',
      ...summary.traceLabels,
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    KnowledgeAnswerEvidenceQualityBadges(record: summary),
                    if (answer != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        answer,
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
                    if (summary.hasRepairableQualityIssue) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KnowledgeAnswerRepairActionButton(
                          record: summary,
                          onSelected: onRepairSearch,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              KnowledgeAnswerReviewCopyButton(
                record: summary,
                completedText: completedText,
                recordStatusText: knowledgeAnswerSavedRecordStatusText,
                iconSize: 18,
                color: AppColors.textLight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentSessionHistoryCard extends StatelessWidget {
  final LearningSession session;
  final bool hasOpenFollowUp;
  final VoidCallback onTap;

  const _AgentSessionHistoryCard({
    required this.session,
    required this.hasOpenFollowUp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = AgentSessionSummaryRecord.fromSession(session);
    final detailParts = [
      if (summary.target != null) '目标: ${summary.target}',
      if (summary.criteria != null) '成功标准: ${summary.criteria}',
      '完成于 ${_dateText(session.endedAt ?? session.startedAt)}',
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailParts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (summary.activeQuestion != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '本轮追问: ${summary.activeQuestion}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                    if (summary.nextQuestion != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${hasOpenFollowUp ? '未处理追问' : '已处理追问'}: ${summary.nextQuestion}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: hasOpenFollowUp
                              ? AppColors.blueDark
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionHistoryContent extends StatelessWidget {
  final LearningSession session;
  final List<InterviewTurn> turns;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onTap;

  const _SessionHistoryContent({
    required this.session,
    required this.turns,
    required this.onTap,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final averageScore = turns.isEmpty ? 0 : _averageScore(turns).round();
    final status = session.endedAt == null ? '进行中' : '已完成';
    final followUpQuestion = followUpQuestionFromLearningSessionSummary(
      session.summary,
    );
    final subtitle = hasError
        ? '复盘数据加载失败'
        : isLoading
            ? '正在加载复盘...'
            : '$status · ${turns.length} 轮 · 平均 $averageScore / 20';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading || hasError ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateText(session.startedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (followUpQuestion != null && !hasError) ...[
                      const SizedBox(height: 5),
                      Text(
                        '本轮追问: $followUpQuestion',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  double _averageScore(List<InterviewTurn> turns) {
    final total = turns
        .map((turn) =>
            turn.accuracyScore +
            turn.projectDetailScore +
            turn.engineeringScore +
            turn.clarityScore)
        .reduce((a, b) => a + b);
    return total / turns.length;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: const Text(
        '完成一次面试训练后，这里会出现复盘记录',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyAgentSessionHistory extends StatelessWidget {
  final VoidCallback onOpenHistory;

  const _EmptyAgentSessionHistory({required this.onOpenHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '完成一次 Agent Session 后，这里会出现目标、成功标准和复盘摘要',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(Icons.history),
            label: const Text(
              '查看 Agent Session 历史',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.greenDark,
              side: const BorderSide(color: AppColors.green),
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateText(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
