import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/product_event.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/agent/learning_agent_planner_service.dart';
import '../../services/agent/project_interview_outcome.dart';
import '../../services/ingestion/source_grounded_ingestion_service.dart';
import '../../services/onboarding/first_run_model_readiness.dart';
import '../../services/onboarding/first_run_progress.dart';
import '../../shared/widgets/alpha_feedback_action.dart';
import '../agent/agent_home_screen.dart';
import '../agent/project_interview_outcome_screen.dart';
import '../ingestion/knowledge_review_screen.dart';
import '../ingestion/project_import_screen.dart';
import '../settings/settings_screen.dart';

class FirstRunScreen extends ConsumerStatefulWidget {
  final FirstRunProgress progress;

  const FirstRunScreen({
    super.key,
    required this.progress,
  });

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  late LearningAgentGoal _draftGoal;
  bool _isGenerating = false;
  String _generationStatus = '';
  String? _generationError;

  FirstRunProgress get progress => widget.progress;

  @override
  void initState() {
    super.initState();
    _draftGoal = progress.selectedGoal;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordVisibleStep(progress.step);
    });
  }

  @override
  void didUpdateWidget(covariant FirstRunScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.selectedGoal != progress.selectedGoal &&
        progress.step == FirstRunStep.goal) {
      _draftGoal = progress.selectedGoal;
    }
    if (oldWidget.progress.step != progress.step) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recordVisibleStep(progress.step);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首次学习设置'),
        automaticallyImplyLeading: false,
        actions: [
          AlphaFeedbackIconButton(
            screenId: 'first_run_${progress.step.value}',
            diagnosticLines: [
              '首次运行步骤: ${progress.step.value}',
              '目标: ${progress.selectedGoal.value}',
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FirstRunProgressHeader(step: progress.step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (progress.step) {
      case FirstRunStep.goal:
        return _buildGoalStep();
      case FirstRunStep.modelReadiness:
        return _buildModelReadinessStep();
      case FirstRunStep.projectImport:
        return _buildProjectImportStep();
      case FirstRunStep.coverageReview:
        return _buildCoverageReviewStep();
      case FirstRunStep.firstSession:
        return _buildFirstSessionStep();
      case FirstRunStep.outcomePreview:
        return _buildOutcomePreviewStep();
      case FirstRunStep.completed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: '选择本轮学习目标',
          subtitle: '目标会限定 Agent 的知识范围、下一动作和复盘记录。',
        ),
        const SizedBox(height: 18),
        ...LearningAgentGoal.values.map((goal) {
          final recommended = goal == LearningAgentGoal.aiInterviewPrep;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: _draftGoal == goal
                  ? AppColors.green.withValues(alpha: 0.08)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      _draftGoal == goal ? AppColors.green : AppColors.border,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _draftGoal = goal),
                child: ListTile(
                  leading: Icon(
                    _draftGoal == goal
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _draftGoal == goal
                        ? AppColors.green
                        : AppColors.textLight,
                  ),
                  title: Text(
                    goal.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_goalDescription(goal)),
                  trailing: recommended
                      ? const Tooltip(
                          message: '私测推荐路径',
                          child: Icon(
                            Icons.recommend_outlined,
                            color: AppColors.gold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _runProgressAction(
              () => ref
                  .read(firstRunProgressProvider.notifier)
                  .confirmGoal(_draftGoal),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('确认目标'),
          ),
        ),
      ],
    );
  }

  Widget _buildModelReadinessStep() {
    final readinessAsync = ref.watch(firstRunModelReadinessProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: '模型就绪',
          subtitle: '只有主动执行 AI 任务时，选中的材料才会发送到当前提供商。',
        ),
        const SizedBox(height: 16),
        readinessAsync.when(
          data: _ModelReadinessPanel.new,
          loading: () => const _LoadingPanel(label: '正在读取模型配置...'),
          error: (error, _) => _ErrorPanel(
            message: '模型配置读取失败: $error',
            onRetry: () => ref.invalidate(firstRunModelReadinessProvider),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openModelSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('配置或验收模型'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _runProgressAction(
              () => ref
                  .read(firstRunProgressProvider.notifier)
                  .continueToProjectImport(),
            ),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('继续导入本地项目'),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '模型未通过验收时仍可扫描、保存和检查本地证据；生成学习内容会保持阻断。',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectImportStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: '导入一个本地项目',
          subtitle: '目录或 ZIP 会先在本机扫描；密钥、构建产物和常见敏感文件会被排除。',
        ),
        const SizedBox(height: 18),
        const _StatusPanel(
          icon: Icons.storage_outlined,
          color: AppColors.blue,
          title: '本地材料边界',
          lines: [
            '保存来源、文件定位和内容哈希',
            '此步骤不要求模型，也不会触发 AI 请求',
            '完成后可在重启时继续同一来源',
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openProjectImport,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('选择项目目录或 ZIP'),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageReviewStep() {
    final sourceId = progress.sourceId;
    if (sourceId == null) {
      return _ErrorPanel(
        message: '首次运行记录中没有项目来源。',
        onRetry: () => ref
            .read(firstRunProgressProvider.notifier)
            .refreshDerivedProgress(),
      );
    }
    final sourceAsync = ref.watch(sourceProvider(sourceId));
    final chunksAsync = ref.watch(sourceChunksProvider(sourceId));
    final readinessAsync = ref.watch(firstRunModelReadinessProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: '检查覆盖范围与来源',
          subtitle: '先确认实际保存的文件定位，再生成并人工核验项目学习单元。',
        ),
        const SizedBox(height: 16),
        sourceAsync.when(
          data: (source) => chunksAsync.when(
            data: (chunks) => source == null
                ? _ErrorPanel(
                    message: '本地项目来源已不存在。',
                    onRetry: () => ref
                        .read(firstRunProgressProvider.notifier)
                        .refreshDerivedProgress(),
                  )
                : _CoverageMaterialPanel(source: source, chunks: chunks),
            loading: () => const _LoadingPanel(label: '正在读取证据片段...'),
            error: (error, _) => _ErrorPanel(
              message: '证据片段读取失败: $error',
              onRetry: () => ref.invalidate(sourceChunksProvider(sourceId)),
            ),
          ),
          loading: () => const _LoadingPanel(label: '正在读取项目来源...'),
          error: (error, _) => _ErrorPanel(
            message: '项目来源读取失败: $error',
            onRetry: () => ref.invalidate(sourceProvider(sourceId)),
          ),
        ),
        const SizedBox(height: 16),
        readinessAsync.when(
          data: (readiness) => readiness.isReady
              ? const _StatusPanel(
                  icon: Icons.verified_outlined,
                  color: AppColors.green,
                  title: '模型已通过五任务验收',
                  lines: ['可以生成项目理解、练习题并进入人工核验'],
                )
              : _BlockedModelPanel(onConfigure: _openModelSettings),
          loading: () => const _LoadingPanel(label: '正在确认模型验收状态...'),
          error: (error, _) => _ErrorPanel(
            message: '模型状态读取失败: $error',
            onRetry: () => ref.invalidate(firstRunModelReadinessProvider),
          ),
        ),
        if (_isGenerating) ...[
          const SizedBox(height: 16),
          _LoadingPanel(
            label:
                _generationStatus.isEmpty ? '正在生成学习内容...' : _generationStatus,
          ),
        ],
        if (_generationError != null) ...[
          const SizedBox(height: 16),
          _ErrorPanel(
            message: _generationError!,
            onRetry: _generateAndReviewProject,
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                readinessAsync.valueOrNull?.isReady == true && !_isGenerating
                    ? _generateAndReviewProject
                    : null,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('生成并核验项目学习内容'),
          ),
        ),
      ],
    );
  }

  Widget _buildFirstSessionStep() {
    final planAsync = ref.watch(learningAgentPlanProvider(
      progress.selectedGoal,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: '完成首次来源绑定学习',
          subtitle: '进入统一 Agent 工作区，执行当前计划的一项动作并保存复盘。',
        ),
        const SizedBox(height: 16),
        planAsync.when(
          data: (plan) => _FirstSessionPlanPanel(plan: plan),
          loading: () => const _LoadingPanel(label: '正在生成本地学习计划...'),
          error: (error, _) => _ErrorPanel(
            message: '学习计划读取失败: $error',
            onRetry: () => ref.invalidate(
              learningAgentPlanProvider(progress.selectedGoal),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openAgentWorkspace,
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('打开 Agent 工作区'),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '会话开始后的 plan snapshot、工具轨迹和恢复状态由现有 Agent checkpoint 持久化。',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildOutcomePreviewStep() {
    final sourceId = progress.sourceId;
    if (sourceId == null) {
      return const _ErrorPanel(message: '项目来源缺失，无法生成结果预览。');
    }
    final outcomeAsync = ref.watch(projectInterviewOutcomeProvider);
    final sessionsAsync = ref.watch(agentSessionListProvider);
    final planAsync = ref.watch(learningAgentPlanProvider(
      progress.selectedGoal,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: '首次学习结果',
          subtitle: '这里只展示本地已核验来源和真实完成记录，不把模型生成文本当成掌握证明。',
        ),
        const SizedBox(height: 16),
        outcomeAsync.when(
          data: (outcome) {
            final scoped = outcome.forSource(sourceId);
            if (scoped.units.isEmpty) {
              return const _ErrorPanel(message: '没有找到已核验的项目学习单元。');
            }
            return _OutcomeClaimPanel(unit: scoped.units.first);
          },
          loading: () => const _LoadingPanel(label: '正在读取已核验结论...'),
          error: (error, _) => _ErrorPanel(
            message: '项目结论读取失败: $error',
            onRetry: () => ref.invalidate(projectInterviewOutcomeProvider),
          ),
        ),
        const SizedBox(height: 14),
        sessionsAsync.when(
          data: (sessions) => _OutcomeSessionPanel(
            session: _findCompletedSession(sessions),
          ),
          loading: () => const _LoadingPanel(label: '正在读取首次会话...'),
          error: (error, _) => _ErrorPanel(
            message: '首次会话读取失败: $error',
            onRetry: () => ref.invalidate(agentSessionListProvider),
          ),
        ),
        const SizedBox(height: 14),
        planAsync.when(
          data: (plan) => _NextActionPanel(plan: plan),
          loading: () => const _LoadingPanel(label: '正在计算下一动作...'),
          error: (error, _) => _ErrorPanel(
            message: '下一动作读取失败: $error',
            onRetry: () => ref.invalidate(
              learningAgentPlanProvider(progress.selectedGoal),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectInterviewOutcomeScreen(
                  sourceId: sourceId,
                ),
              ),
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('查看完整项目面试成果'),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _runProgressAction(
              () => ref.read(firstRunProgressProvider.notifier).complete(),
            ),
            icon: const Icon(Icons.check),
            label: const Text('进入 Anchor Learning'),
          ),
        ),
      ],
    );
  }

  Future<void> _openModelSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    ref.invalidate(firstRunModelReadinessProvider);
  }

  Future<void> _openProjectImport() async {
    await Navigator.of(context).push<ProjectImportResult>(
      MaterialPageRoute(
        builder: (_) => ProjectImportScreen(
          localMaterialOnly: true,
          eventFlowId: progress.flowId,
          eventGoal: progress.selectedGoal.value,
          onMaterialPersisted: (result) => ref
              .read(firstRunProgressProvider.notifier)
              .recordImportedSource(result.sourceId),
        ),
      ),
    );
    if (!mounted) return;
    await _runProgressAction(
      () =>
          ref.read(firstRunProgressProvider.notifier).refreshDerivedProgress(),
    );
  }

  Future<void> _generateAndReviewProject() async {
    if (_isGenerating) return;
    final sourceId = progress.sourceId;
    if (sourceId == null) return;
    setState(() {
      _isGenerating = true;
      _generationError = null;
      _generationStatus = '正在读取本地项目材料...';
    });

    try {
      final source =
          await ref.read(sourceRepositoryProvider).getSource(sourceId);
      final chunks = await ref
          .read(sourceChunkRepositoryProvider)
          .getSourceChunks(sourceId);
      if (source == null || chunks.isEmpty) {
        throw StateError('本地项目材料已不存在，请重新导入');
      }
      final draft =
          await ref.read(projectLearningDraftServiceProvider).generate(
                source: source,
                chunks: chunks,
                onStage: (stage) {
                  if (mounted) setState(() => _generationStatus = stage.label);
                },
              );
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generationStatus = '';
      });

      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => KnowledgeReviewScreen(
            title: '${source.title} 的学习内容',
            sources: [source],
            sourceChunks: chunks,
            knowledgePoints: draft.knowledgePoints,
            sourceChunkIdsByKnowledgePointId:
                draft.sourceChunkIdsByKnowledgePointId,
            questions: draft.questions,
            onSave: (knowledgePointDecisions, questionDecisions) async {
              final result = await ref
                  .read(sourceGroundedIngestionServiceProvider)
                  .saveReviewedContent(
                    SourceGroundedSaveRequest(
                      source: source,
                      chunks: chunks,
                      knowledgePointDecisions: knowledgePointDecisions,
                      sourceChunkIdsByKnowledgePointId:
                          draft.sourceChunkIdsByKnowledgePointId,
                      deckId: draft.deckId,
                      deckTitle: '${source.title} 面试题',
                      deckSourceText: 'project:${source.id}',
                      questionDecisions: questionDecisions,
                      sourceMaterialAlreadySaved: true,
                      eventFlowId: progress.flowId,
                      eventGoal: progress.selectedGoal.value,
                    ),
                  );
              if (result.savedKnowledgePointCount == 0 &&
                  result.savedQuestionCount == 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('至少确认一个知识单元或保留一道题目'),
                    backgroundColor: AppColors.red,
                  ),
                );
                return;
              }
              final includedCount =
                  result.savedKnowledgePointCount + result.savedQuestionCount;
              final reviewedCount =
                  knowledgePointDecisions.length + questionDecisions.length;
              await ref.read(productEventRecorderProvider).recordBestEffort(
                    ProductEventName.coverageReviewCompleted,
                    flowId: progress.flowId,
                    goal: progress.selectedGoal.value,
                    properties: {
                      'included_count': includedCount,
                      'excluded_count': reviewedCount - includedCount,
                      'locator_coverage': _locatorCoverage(chunks),
                    },
                    dedupeKey: '${progress.flowId}:coverage_review_completed',
                  );
              _invalidateImportedLearningData(source.id, draft.deckId);
              await ref
                  .read(firstRunProgressProvider.notifier)
                  .recordCoverageReviewed();
              if (!mounted) return;
              Navigator.of(context).pop(true);
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generationStatus = '';
        _generationError = '生成失败: $error';
      });
    }
  }

  Future<void> _openAgentWorkspace() async {
    await ref
        .read(learningAgentGoalProvider.notifier)
        .setGoal(progress.selectedGoal);
    if (!mounted) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AgentHomeScreen(
          returnAfterSessionCompletion: true,
        ),
      ),
    );
    if (!mounted) return;
    ref.invalidate(learningSessionListProvider);
    ref.invalidate(agentSessionListProvider);
    ref.invalidate(agentSessionMemoryIndexProvider);
    ref.invalidate(learningAgentPlanProvider(progress.selectedGoal));

    if (completed == true) {
      final session = await ref
          .read(firstRunBootstrapServiceProvider)
          .latestCompletedAgentSession(progress);
      if (session != null) {
        await _runProgressAction(
          () => ref
              .read(firstRunProgressProvider.notifier)
              .recordCompletedSession(session.id),
        );
        return;
      }
    }
    await _runProgressAction(
      () =>
          ref.read(firstRunProgressProvider.notifier).refreshDerivedProgress(),
    );
  }

  void _invalidateImportedLearningData(String sourceId, String deckId) {
    ref.invalidate(deckListProvider);
    ref.invalidate(sourceListProvider);
    ref.invalidate(sourceProvider(sourceId));
    ref.invalidate(sourceChunksProvider(sourceId));
    ref.invalidate(sourceKnowledgePointsProvider(sourceId));
    ref.invalidate(knowledgePointListProvider);
    ref.invalidate(evidenceBackedKnowledgePointListProvider);
    ref.invalidate(practiceableKnowledgePointListProvider);
    ref.invalidate(pendingQuestionListProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    ref.invalidate(deckQuestionsProvider(deckId));
    ref.invalidate(verifiedDeckQuestionsProvider(deckId));
    ref.invalidate(todayReviewQueueProvider);
    ref.invalidate(learningAgentPlanProvider(progress.selectedGoal));
  }

  LearningSession? _findCompletedSession(List<LearningSession> sessions) {
    final expectedId = progress.sessionId;
    if (expectedId != null) {
      for (final session in sessions) {
        if (session.id == expectedId) return session;
      }
    }
    final candidates = sessions
        .where((session) =>
            session.mode == LearningSessionMode.agentSession &&
            session.endedAt != null &&
            !session.startedAt.isBefore(progress.startedAt))
        .toList()
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<void> _runProgressAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('状态保存失败: $error'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _recordVisibleStep(FirstRunStep step) async {
    if (!mounted || step != FirstRunStep.modelReadiness) return;
    try {
      final readiness =
          await ref.read(firstRunModelReadinessServiceProvider).load();
      await ref.read(productEventRecorderProvider).recordBestEffort(
            ProductEventName.modelReadinessViewed,
            flowId: progress.flowId,
            goal: progress.selectedGoal.value,
            properties: {
              'provider_configured':
                  readiness.configuration.providerId.trim().isNotEmpty &&
                      readiness.configuration.endpoint.trim().isNotEmpty &&
                      readiness.configuration.model.trim().isNotEmpty,
              'protocol_configured':
                  readiness.configuration.protocol.value.trim().isNotEmpty,
            },
            dedupeKey: '${progress.flowId}:model_readiness_viewed',
          );
    } catch (_) {
      // The readiness panel owns user-visible failures; events are best effort.
    }
  }

  String _locatorCoverage(List<SourceChunk> chunks) {
    if (chunks.isEmpty) return 'none';
    final located = chunks.where((chunk) {
      return (chunk.locator?.trim().isNotEmpty ?? false) ||
          (chunk.relativePath?.trim().isNotEmpty ?? false);
    }).length;
    if (located == 0) return 'none';
    if (located == chunks.length) return 'complete';
    return 'partial';
  }

  String _goalDescription(LearningAgentGoal goal) {
    switch (goal) {
      case LearningAgentGoal.aiInterviewPrep:
        return '混合项目理解、面试追问和编程基础，适合作为私测主路径。';
      case LearningAgentGoal.projectWalkthrough:
        return '优先练习架构、数据流、关键实现、边界与取舍。';
      case LearningAgentGoal.programmingFoundations:
        return '围绕有来源的编程概念、练习与复习计划推进。';
    }
  }
}

class _FirstRunProgressHeader extends StatelessWidget {
  static const _labels = [
    '目标',
    '模型',
    '导入',
    '覆盖',
    '会话',
    '结果',
  ];

  final FirstRunStep step;

  const _FirstRunProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final index = step.index.clamp(0, _labels.length - 1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}/${_labels.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _labels[index],
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (index + 1) / _labels.length,
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StepTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ModelReadinessPanel extends StatelessWidget {
  final FirstRunModelReadiness readiness;

  const _ModelReadinessPanel(this.readiness);

  @override
  Widget build(BuildContext context) {
    final configuration = readiness.configuration;
    final ready = readiness.isReady;
    final report = readiness.acceptanceReport;
    return _StatusPanel(
      icon: ready ? Icons.verified_outlined : Icons.block_outlined,
      color: ready ? AppColors.green : AppColors.streakOrange,
      title: ready ? '模型可用于正式学习任务' : '当前模型尚未通过验收',
      lines: [
        '提供商: ${configuration.providerId}',
        '模型: ${configuration.model}',
        '协议: ${configuration.protocol.label}',
        '凭证: ${readiness.hasCredential ? '已安全保存' : '未配置'}',
        if (report != null)
          '验收: ${report.passedCount}/${report.cases.length} 项通过',
      ],
    );
  }
}

class _CoverageMaterialPanel extends StatelessWidget {
  final Source source;
  final List<SourceChunk> chunks;

  const _CoverageMaterialPanel({required this.source, required this.chunks});

  @override
  Widget build(BuildContext context) {
    final totalCharacters = chunks.fold<int>(
      0,
      (total, chunk) => total + chunk.content.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusPanel(
          icon: Icons.source_outlined,
          color: AppColors.blue,
          title: source.title,
          lines: [
            '来源类型: ${source.type.label}',
            '信任级别: ${source.trustLevel.label}',
            '证据片段: ${chunks.length}',
            '本地字符数: $totalCharacters',
            if (source.revision?.trim().isNotEmpty == true)
              '版本: ${source.revision}',
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          '保存的文件定位',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: chunks.take(12).map((chunk) {
              final locator = chunk.relativePath?.trim().isNotEmpty == true
                  ? chunk.relativePath!
                  : chunk.locator?.trim().isNotEmpty == true
                      ? chunk.locator!
                      : 'chunk ${chunk.chunkIndex + 1}';
              return ListTile(
                dense: true,
                leading: const Icon(Icons.description_outlined, size: 20),
                title:
                    Text(locator, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${chunk.content.length} 字符'),
              );
            }).toList(),
          ),
        ),
        if (chunks.length > 12) ...[
          const SizedBox(height: 8),
          Text(
            '另有 ${chunks.length - 12} 个片段已保存',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _BlockedModelPanel extends StatelessWidget {
  final VoidCallback onConfigure;

  const _BlockedModelPanel({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StatusPanel(
          icon: Icons.block_outlined,
          color: AppColors.streakOrange,
          title: 'AI 生成已阻断',
          lines: [
            '本地来源和证据仍然可检查',
            '需要同一提供商、地址、模型和协议通过五任务验收',
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onConfigure,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('配置或重新验收模型'),
        ),
      ],
    );
  }
}

class _FirstSessionPlanPanel extends StatelessWidget {
  final LearningAgentPlan plan;

  const _FirstSessionPlanPanel({required this.plan});

  @override
  Widget build(BuildContext context) {
    final summary = plan.sessionSummary;
    return _StatusPanel(
      icon: plan.canStartSession
          ? Icons.route_outlined
          : Icons.report_problem_outlined,
      color: plan.canStartSession ? AppColors.green : AppColors.streakOrange,
      title: summary.title,
      lines: [
        '目标: ${summary.targetLabel}',
        if (summary.nextStep != null) '动作: ${summary.nextStep!.title}',
        if (plan.startBlockReason != null) '阻断: ${plan.startBlockReason}',
        if (plan.nextAction?.reason.trim().isNotEmpty == true)
          '原因: ${plan.nextAction!.reason}',
      ],
    );
  }
}

class _OutcomeClaimPanel extends StatelessWidget {
  final ProjectInterviewOutcomeUnit unit;

  const _OutcomeClaimPanel({required this.unit});

  @override
  Widget build(BuildContext context) {
    final evidence = unit.strongestEvidence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusPanel(
          icon: _outcomeStatusIcon(unit.status),
          color: _outcomeStatusColor(unit.status),
          title: unit.point.title,
          lines: [
            '${unit.point.kind.label} · ${unit.status.label}',
            unit.point.summary,
            '判断依据: ${unit.reasons.map((reason) => reason.label).join('、')}',
          ],
        ),
        if (unit.interviewScore != null) ...[
          const SizedBox(height: 10),
          _StatusPanel(
            icon: Icons.analytics_outlined,
            color: unit.interviewScore!.meetsReadyThreshold
                ? AppColors.greenDark
                : AppColors.streakOrange,
            title: '最近面试评分 ${unit.interviewScore!.total}/20',
            lines: [
              '事实 ${unit.interviewScore!.accuracy}/5 · 项目细节 ${unit.interviewScore!.projectDetail}/5 · 工程判断 ${unit.interviewScore!.engineering}/5 · 表达 ${unit.interviewScore!.clarity}/5',
            ],
          ),
        ],
        if (unit.latestAnswer != null) ...[
          const SizedBox(height: 10),
          _StatusPanel(
            icon: Icons.record_voice_over_outlined,
            color: AppColors.blueDark,
            title: '你的最近回答',
            lines: [
              unit.latestAnswer!.text,
              '这是用户内容，不作为项目事实依据。',
            ],
          ),
        ],
        const SizedBox(height: 10),
        _StatusPanel(
          icon: Icons.format_list_bulleted,
          color: AppColors.greenDark,
          title: '来源支持的参考提纲',
          lines: unit.referenceOutline.isEmpty
              ? const ['当前没有通过逐字引用校验的正式主张。']
              : unit.referenceOutline
                  .map((claim) => claim.text)
                  .toList(growable: false),
        ),
        const SizedBox(height: 10),
        if (evidence == null)
          const _ErrorPanel(message: '该结论的证据片段已不存在。')
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.blue.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.locator,
                  style: const TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  evidence.excerpt,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Color _outcomeStatusColor(ProjectInterviewOutcomeStatus status) {
  switch (status) {
    case ProjectInterviewOutcomeStatus.ready:
      return AppColors.greenDark;
    case ProjectInterviewOutcomeStatus.needsPractice:
      return AppColors.streakOrange;
    case ProjectInterviewOutcomeStatus.evidenceGap:
      return AppColors.red;
    case ProjectInterviewOutcomeStatus.notAssessed:
      return AppColors.textSecondary;
  }
}

IconData _outcomeStatusIcon(ProjectInterviewOutcomeStatus status) {
  switch (status) {
    case ProjectInterviewOutcomeStatus.ready:
      return Icons.verified_outlined;
    case ProjectInterviewOutcomeStatus.needsPractice:
      return Icons.fitness_center_outlined;
    case ProjectInterviewOutcomeStatus.evidenceGap:
      return Icons.link_off_outlined;
    case ProjectInterviewOutcomeStatus.notAssessed:
      return Icons.pending_actions_outlined;
  }
}

class _OutcomeSessionPanel extends StatelessWidget {
  final LearningSession? session;

  const _OutcomeSessionPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final value = session;
    if (value == null) {
      return const _ErrorPanel(message: '没有找到已完成的首次 Agent Session。');
    }
    final summary = value.summary?.trim();
    return _StatusPanel(
      icon: Icons.task_alt,
      color: AppColors.green,
      title: '首次来源绑定轮次已保存',
      lines: [
        '完成时间: ${_dateTimeText(value.endedAt ?? value.startedAt)}',
        '当前质量: 已完成首轮，仍需更多有评分回答形成稳定判断',
        if (summary != null && summary.isNotEmpty) summary,
      ],
    );
  }
}

class _NextActionPanel extends StatelessWidget {
  final LearningAgentPlan plan;

  const _NextActionPanel({required this.plan});

  @override
  Widget build(BuildContext context) {
    final nextAction = plan.nextAction;
    return _StatusPanel(
      icon: Icons.arrow_circle_right_outlined,
      color: AppColors.gold,
      title: nextAction?.title ?? plan.sessionSummary.title,
      lines: [
        nextAction?.reason ?? '继续按当前本地学习计划推进。',
        if (nextAction?.blockerMessage != null)
          '阻断: ${nextAction!.blockerMessage}',
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  const _StatusPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (lines.isNotEmpty) const SizedBox(height: 8),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
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

class _LoadingPanel extends StatelessWidget {
  final String label;

  const _LoadingPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorPanel({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (onRetry != null)
            IconButton(
              tooltip: '重试',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}

String _dateTimeText(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
