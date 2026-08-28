import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../data/models/tutor_turn.dart';
import '../../services/agent/grounded_learning_context_service.dart';
import '../../services/ai/tasks/tutor_explanation_task.dart';
import '../../shared/widgets/anchor_button.dart';
import '../../shared/widgets/source_citation_block.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'programming_exercise_screen.dart';

/// 知识点问答(Tutor)会话屏幕
///
/// **功能**: 用户选择知识点提问,AI 基于知识库中的原文和前置知识点进行讲解
///
/// **工作流程**:
/// 1. 用户选择知识点或提出问题
/// 2. 系统加载该知识点的:
///    - 来源片段(SourceChunk): 支撑该知识点的原文
///    - 前置知识点(Prerequisite): 需要先理解的基础概念
/// 3. AI 基于这些上下文生成讲解(TutorExplanationTask)
/// 4. 用户可以继续追问,形成多轮对话
/// 5. 所有对话轮次保存到 TutorTurn 供后续回顾
///
/// **与 InterviewSession 的区别**:
/// - InterviewSession: AI 主动提问,评估用户答案(面试模式)
/// - TutorSession: 用户主动提问,AI 讲解(答疑模式)
///
/// **技术特点**:
/// - 使用 GroundedLearningContext 确保讲解有原文依据
/// - 自动加载前置知识点,帮助用户理解概念依赖
/// - 支持从指定知识点开始(initialPoint)或直接追问(initialFollowUpQuestion)
/// - 引用溯源:每次讲解都标注引用的原文片段(SourceCitationBlock)
class TutorSessionScreen extends ConsumerStatefulWidget {
  final KnowledgePoint? initialPoint;
  final String? initialFollowUpQuestion;

  const TutorSessionScreen({
    super.key,
    this.initialPoint,
    this.initialFollowUpQuestion,
  });

  @override
  ConsumerState<TutorSessionScreen> createState() => _TutorSessionScreenState();
}

class _TutorSessionScreenState extends ConsumerState<TutorSessionScreen> {
  final TextEditingController _answerController = TextEditingController();

  KnowledgePoint? _selectedPoint;
  List<SourceChunk> _evidenceChunks = [];
  List<KnowledgePoint> _prerequisitePoints = [];
  Map<String, List<SourceChunk>> _prerequisiteChunksByPointId = const {};
  GroundedLearningContext? _groundedContext;
  TutorExplanationResult? _explanation;
  List<TutorTurn> _turns = [];
  String? _sessionId;
  String? _currentQuestion;
  bool _isGenerating = false;
  bool _isSubmittingAnswer = false;
  String? _errorMessage;
  String? _turnErrorMessage;
  bool _didStartInitialPoint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didStartInitialPoint || widget.initialPoint == null) {
        return;
      }
      _didStartInitialPoint = true;
      _explain(widget.initialPoint!);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _explain(KnowledgePoint point) async {
    final hasKey = await ref.read(openaiServiceProvider).hasApiKey();
    if (!hasKey) {
      if (!mounted) return;
      setState(() {
        _selectedPoint = point;
        _errorMessage = '请先在设置中配置 AI API Key';
      });
      return;
    }

    setState(() {
      _selectedPoint = point;
      _evidenceChunks = [];
      _prerequisitePoints = [];
      _prerequisiteChunksByPointId = const {};
      _groundedContext = null;
      _explanation = null;
      _turns = [];
      _sessionId = null;
      _currentQuestion = null;
      _answerController.clear();
      _isGenerating = true;
      _isSubmittingAnswer = false;
      _errorMessage = null;
      _turnErrorMessage = null;
    });

    try {
      final evidence = await _loadTutorEvidence(point);
      if (evidence.currentChunks.isEmpty) {
        throw StateError('这个知识点还没有来源片段，无法进行有依据的讲解');
      }
      if (!evidence.groundedContext.isExecutable) {
        throw StateError(evidence.groundedContext.diagnosticLines.join('\n'));
      }
      if (!mounted) return;
      setState(() {
        _evidenceChunks = evidence.currentChunks;
        _prerequisitePoints = evidence.prerequisitePoints;
        _prerequisiteChunksByPointId = evidence.prerequisiteChunksByPointId;
        _groundedContext = evidence.groundedContext;
      });

      final result = await ref.read(tutorExplanationTaskProvider).run(
            knowledgePoint: point,
            sourceChunks: evidence.currentChunks,
            prerequisiteKnowledgePoints: evidence.prerequisitePoints,
            prerequisiteChunksByKnowledgePointId:
                evidence.prerequisiteChunksByPointId,
            groundedContext: evidence.groundedContext,
          );
      if (!result.isSuccess) {
        throw StateError(result.errorMessage ?? '导师讲解生成失败');
      }

      final explanation = result.requireData;
      final sessionId = await _recordTutorSession(
        point,
        openingQuestion:
            _initialQuestionFor(point) ?? explanation.openingQuestion,
      );

      if (!mounted) return;
      setState(() {
        _explanation = explanation;
        _sessionId = sessionId;
        _currentQuestion = explanation.evidenceSufficient
            ? (_initialQuestionFor(point) ?? explanation.openingQuestion)
            : null;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = '生成失败: $e';
      });
    }
  }

  Future<_TutorEvidence> _loadTutorEvidence(KnowledgePoint point) async {
    final repository = ref.read(knowledgePointRepositoryProvider);
    final currentChunks = await _loadEvidenceChunks(point.id);
    final relations = await repository.getKnowledgePointPrerequisites();
    final prerequisiteIds = relations
        .where((relation) => relation.knowledgePointId == point.id)
        .map((relation) => relation.prerequisiteKnowledgePointId)
        .toSet()
        .toList()
      ..sort();

    final prerequisitePoints = <KnowledgePoint>[];
    final prerequisiteChunksByPointId = <String, List<SourceChunk>>{};
    for (final prerequisiteId in prerequisiteIds) {
      final prerequisite = await repository.getKnowledgePoint(prerequisiteId);
      if (prerequisite == null ||
          prerequisite.kind != KnowledgePointKind.concept) {
        continue;
      }
      final chunks = await _loadEvidenceChunks(prerequisite.id);
      if (chunks.isEmpty) continue;
      prerequisitePoints.add(prerequisite);
      prerequisiteChunksByPointId[prerequisite.id] = chunks;
    }
    prerequisitePoints.sort((a, b) => a.title.compareTo(b.title));

    final candidates = <GroundedLearningContextCandidate>[
      for (final chunk in currentChunks)
        GroundedLearningContextCandidate(
          chunk: chunk,
          reasons: const [GroundedLearningContextReason.targetRelation],
        ),
      for (final chunk
          in prerequisiteChunksByPointId.values.expand((items) => items))
        GroundedLearningContextCandidate(
          chunk: chunk,
          reasons: const [
            GroundedLearningContextReason.prerequisiteRelation,
          ],
        ),
    ];
    final sources = await _loadSources(
      candidates.map((candidate) => candidate.chunk),
    );
    final groundedContext =
        ref.read(groundedLearningContextServiceProvider).select(
              targetId: point.id,
              knowledgePoint: point,
              surface: GroundedLearningSurface.tutor,
              candidates: candidates,
              sources: sources,
              limit: candidates.length,
            );
    final allowedChunkIds = groundedContext.chunkIdSet;
    final filteredCurrentChunks = currentChunks
        .where((chunk) => allowedChunkIds.contains(chunk.id))
        .toList(growable: false);
    final filteredPrerequisiteChunks = <String, List<SourceChunk>>{
      for (final entry in prerequisiteChunksByPointId.entries)
        entry.key: entry.value
            .where((chunk) => allowedChunkIds.contains(chunk.id))
            .toList(growable: false),
    }..removeWhere((_, chunks) => chunks.isEmpty);
    final filteredPrerequisitePoints = prerequisitePoints
        .where(
          (prerequisite) =>
              filteredPrerequisiteChunks.containsKey(prerequisite.id),
        )
        .toList(growable: false);

    return _TutorEvidence(
      currentChunks: filteredCurrentChunks,
      prerequisitePoints: filteredPrerequisitePoints,
      prerequisiteChunksByPointId: filteredPrerequisiteChunks,
      groundedContext: groundedContext,
    );
  }

  Future<List<Source>> _loadSources(Iterable<SourceChunk> chunks) async {
    final sources = <String, Source>{};
    for (final sourceId in chunks.map((chunk) => chunk.sourceId).toSet()) {
      final source = await ref.read(sourceProvider(sourceId).future);
      if (source != null) sources[source.id] = source;
    }
    return sources.values.toList(growable: false);
  }

  Future<List<SourceChunk>> _loadEvidenceChunks(
    String knowledgePointId,
  ) async {
    final relations = await ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePointSources(knowledgePointId);
    final chunks = <SourceChunk>[];
    for (final relation in relations) {
      final chunk = await ref
          .read(sourceChunkRepositoryProvider)
          .getSourceChunk(relation.sourceChunkId);
      if (chunk != null) chunks.add(chunk);
    }
    chunks.sort((a, b) {
      final sourceOrder = a.sourceId.compareTo(b.sourceId);
      if (sourceOrder != 0) return sourceOrder;
      return a.chunkIndex.compareTo(b.chunkIndex);
    });
    return chunks;
  }

  Future<String> _recordTutorSession(
    KnowledgePoint point, {
    required String openingQuestion,
  }) async {
    final now = DateTime.now();
    final sessionId = 'tutor-${now.microsecondsSinceEpoch}';
    await ref.read(learningSessionRepositoryProvider).insertLearningSession(
          LearningSession(
            id: sessionId,
            mode: LearningSessionMode.tutor,
            targetId: point.id,
            startedAt: now,
            endedAt: now,
            xpGained: 5,
            summary: _tutorSessionSummary(
              point,
              openingQuestion: openingQuestion,
              turnCount: 0,
            ),
          ),
        );
    invalidateAgentLearningRecordProviders(ref);
    return sessionId;
  }

  Future<void> _submitAnswer() async {
    final point = _selectedPoint;
    final question = _currentQuestion?.trim();
    final answer = _answerController.text.trim();
    final sessionId = _sessionId;
    if (point == null ||
        question == null ||
        question.isEmpty ||
        sessionId == null ||
        _isSubmittingAnswer) {
      return;
    }
    if (answer.isEmpty) {
      setState(() => _turnErrorMessage = '请先回答当前问题');
      return;
    }

    setState(() {
      _isSubmittingAnswer = true;
      _turnErrorMessage = null;
    });

    try {
      final result = await ref.read(tutorSocraticTaskProvider).run(
            knowledgePoint: point,
            question: question,
            userAnswer: answer,
            sourceChunks: _evidenceChunks,
            prerequisiteKnowledgePoints: _prerequisitePoints,
            prerequisiteChunksByKnowledgePointId: _prerequisiteChunksByPointId,
            previousTurns: _turns,
            groundedContext: _groundedContext,
          );
      if (!result.isSuccess) {
        throw StateError(result.errorMessage ?? '导师反馈生成失败');
      }

      final feedback = result.requireData;
      final now = DateTime.now();
      final turn = TutorTurn(
        id: 'tutor-turn-${now.microsecondsSinceEpoch}',
        sessionId: sessionId,
        knowledgePointId: point.id,
        questionText: question,
        userAnswer: answer,
        aiFeedback: feedback.feedback,
        referenceAnswer: feedback.referenceAnswer,
        misconception: feedback.misconception,
        nextQuestion: feedback.nextQuestion,
        citationIds: feedback.citationIds,
        prerequisiteKnowledgePointIds:
            _prerequisitePoints.map((item) => item.id).toList(),
        evidenceSufficient: feedback.evidenceSufficient,
        accuracyScore: feedback.accuracyScore,
        groundedClaims: feedback.claims,
        groundingDisposition: feedback.groundingDisposition,
        createdAt: now,
      );
      await ref
          .read(programmingReviewClosureServiceProvider)
          .closeTutorTurn(turn: turn);
      await _updateTutorSessionSummary(point, sessionId, [..._turns, turn]);

      if (!mounted) return;
      setState(() {
        _turns = [..._turns, turn];
        _currentQuestion = feedback.evidenceSufficient &&
                feedback.nextQuestion.trim().isNotEmpty
            ? feedback.nextQuestion.trim()
            : null;
        _answerController.clear();
        _isSubmittingAnswer = false;
      });
      ref.invalidate(tutorTurnsProvider(sessionId));
      ref.invalidate(programmingReviewQueueProvider);
      invalidateAgentLearningRecordProviders(ref);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmittingAnswer = false;
        _turnErrorMessage = '反馈生成失败: $e';
      });
    }
  }

  Future<void> _updateTutorSessionSummary(
    KnowledgePoint point,
    String sessionId,
    List<TutorTurn> turns,
  ) async {
    final repository = ref.read(learningSessionRepositoryProvider);
    final session = await repository.getLearningSession(sessionId);
    if (session == null) return;
    await repository.updateLearningSession(
      session.copyWith(
        endedAt: DateTime.now(),
        xpGained: 5 + turns.length * 2,
        summary: _tutorSessionSummary(
          point,
          openingQuestion: turns.first.questionText,
          turnCount: turns.length,
        ),
      ),
    );
  }

  String _tutorSessionSummary(
    KnowledgePoint point, {
    required String openingQuestion,
    required int turnCount,
  }) {
    return [
      '导师讲解：${point.title}',
      if (openingQuestion.trim().isNotEmpty) '首问: ${openingQuestion.trim()}',
      '已完成轮次: $turnCount',
    ].join('\n');
  }

  String? _initialQuestionFor(KnowledgePoint point) {
    final question = widget.initialFollowUpQuestion?.trim();
    if (question == null || question.isEmpty) return null;
    if (widget.initialPoint?.id != point.id) return null;
    return question;
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(evidenceBackedKnowledgePointListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('导师模式')),
      body: SafeArea(
        child: pointsAsync.when(
          data: (points) {
            final sortedPoints = _sortPoints(points);
            if (sortedPoints.isEmpty) return const _EmptyTutorState();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _TutorHeader(),
                if (_initialQuestionFor(
                        widget.initialPoint ?? sortedPoints.first) !=
                    null) ...[
                  const SizedBox(height: 12),
                  _FollowUpQuestionBanner(
                    question: widget.initialFollowUpQuestion!.trim(),
                  ),
                ],
                const SizedBox(height: 14),
                const _SectionTitle(title: '选择知识点'),
                const SizedBox(height: 10),
                ...sortedPoints.take(8).map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _KnowledgePointTutorCard(
                          point: point,
                          selected: _selectedPoint?.id == point.id,
                          onTap: _isGenerating || _isSubmittingAnswer
                              ? null
                              : () => _explain(point),
                        ),
                      ),
                    ),
                if (_isGenerating) ...[
                  const SizedBox(height: 12),
                  const _GeneratingBlock(label: '正在生成分层讲解...'),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  KnowledgeLibraryErrorState(
                    title: '导师讲解生成失败',
                    retryLabel: '重试讲解',
                    diagnosticTitle: '导师模式讲解生成失败',
                    diagnosticSuccessMessage: '已复制导师讲解失败诊断',
                    diagnosticLines: _tutorDiagnosticLines(),
                    error: _errorMessage!,
                    onRetry: () {
                      final point = _selectedPoint;
                      if (point != null) _explain(point);
                    },
                  ),
                ],
                if (_selectedPoint != null && _explanation != null) ...[
                  const SizedBox(height: 14),
                  _ExplanationView(
                    point: _selectedPoint!,
                    explanation: _explanation!,
                    evidenceChunks: _allEvidenceChunks,
                    onRegenerate: _isGenerating || _isSubmittingAnswer
                        ? null
                        : () => _explain(_selectedPoint!),
                  ),
                  const SizedBox(height: 14),
                  _SocraticLoopView(
                    turns: _turns,
                    currentQuestion: _currentQuestion,
                    answerController: _answerController,
                    evidenceChunks: _allEvidenceChunks,
                    isSubmitting: _isSubmittingAnswer,
                    errorMessage: _turnErrorMessage,
                    onSubmit: _submitAnswer,
                  ),
                ],
                if (_selectedPoint != null) ...[
                  const SizedBox(height: 14),
                  AnchorButton(
                    key: const ValueKey('open-programming-exercises'),
                    label: '进入编程练习',
                    color: AppColors.purple,
                    width: double.infinity,
                    icon: Icons.code,
                    onPressed: _isGenerating || _isSubmittingAnswer
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProgrammingExerciseScreen(
                                  knowledgePoint: _selectedPoint!,
                                ),
                              ),
                            ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
          error: (error, _) => KnowledgeLibraryErrorState(
            title: '导师知识点读取失败',
            retryLabel: '重试读取知识点',
            diagnosticTitle: '导师模式知识点读取失败',
            diagnosticSuccessMessage: '已复制导师知识点读取诊断',
            diagnosticLines: _tutorDiagnosticLines(),
            error: error,
            onRetry: () => ref.invalidate(
              evidenceBackedKnowledgePointListProvider,
            ),
          ),
        ),
      ),
    );
  }

  List<SourceChunk> get _allEvidenceChunks {
    final chunks = <SourceChunk>[
      ..._evidenceChunks,
      ..._prerequisiteChunksByPointId.values.expand((items) => items),
    ];
    final byId = {for (final chunk in chunks) chunk.id: chunk};
    return byId.values.toList();
  }

  List<KnowledgePoint> _sortPoints(List<KnowledgePoint> points) {
    final sorted = [...points];
    sorted.sort((a, b) {
      final mastery = a.masteryLevel.compareTo(b.masteryLevel);
      if (mastery != 0) return mastery;
      final relevance = b.interviewRelevance.compareTo(a.interviewRelevance);
      if (relevance != 0) return relevance;
      return b.difficulty.compareTo(a.difficulty);
    });
    return sorted;
  }

  List<String> _tutorDiagnosticLines() {
    return [
      '入口: 导师模式',
      '知识点: ${_selectedPoint?.title ?? widget.initialPoint?.title ?? '未选择'}',
      '知识点 ID: ${_selectedPoint?.id ?? widget.initialPoint?.id ?? '无'}',
      '当前问题: ${_currentQuestion ?? widget.initialFollowUpQuestion ?? '无'}',
      '当前来源片段数: ${_evidenceChunks.length}',
      '确认先修概念数: ${_prerequisitePoints.length}',
      '已完成导师轮次: ${_turns.length}',
      ...?_groundedContext?.diagnosticLines,
    ];
  }
}

class _TutorEvidence {
  final List<SourceChunk> currentChunks;
  final List<KnowledgePoint> prerequisitePoints;
  final Map<String, List<SourceChunk>> prerequisiteChunksByPointId;
  final GroundedLearningContext groundedContext;

  const _TutorEvidence({
    required this.currentChunks,
    required this.prerequisitePoints,
    required this.prerequisiteChunksByPointId,
    required this.groundedContext,
  });
}

class _TutorHeader extends StatelessWidget {
  const _TutorHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.school, color: AppColors.blue, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '基于来源分层讲解，再通过一次一问的连续反馈检查理解。',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgePointTutorCard extends StatelessWidget {
  final KnowledgePoint point;
  final bool selected;
  final VoidCallback? onTap;

  const _KnowledgePointTutorCard({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.greenLight : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '掌握度 ${point.masteryLevel}% · 难度 ${point.difficulty} · 面试相关 ${point.interviewRelevance}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
}

class _FollowUpQuestionBanner extends StatelessWidget {
  final String question;

  const _FollowUpQuestionBanner({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.question_answer_outlined, color: AppColors.blueDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '本次从这个问题开始：$question',
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
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

class _ExplanationView extends StatelessWidget {
  final KnowledgePoint point;
  final TutorExplanationResult explanation;
  final List<SourceChunk> evidenceChunks;
  final VoidCallback? onRegenerate;

  const _ExplanationView({
    required this.point,
    required this.explanation,
    required this.evidenceChunks,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final chunksById = {for (final chunk in evidenceChunks) chunk.id: chunk};
    final citedChunks = explanation.citationIds
        .map((id) => chunksById[id])
        .whereType<SourceChunk>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '分层讲解'),
        const SizedBox(height: 8),
        _ExplanationSection(
          title: '${point.title} · 定义与直觉',
          text: explanation.definitionAndIntuition,
          color: AppColors.green,
        ),
        _ExplanationSection(
          title: '工作机制',
          text: explanation.mechanism,
          color: AppColors.blue,
        ),
        _ExplanationSection(
          title: '代码或文档例子',
          text: explanation.codeOrDocExample,
          color: AppColors.purple,
        ),
        _ExplanationSection(
          title: '边界与前提',
          text: explanation.boundaries,
          color: AppColors.gold,
        ),
        if (explanation.misconceptions.isNotEmpty)
          _BulletSection(
            title: '常见误区',
            items: explanation.misconceptions,
            color: AppColors.red,
          ),
        _ExplanationSection(
          title: '面试表达',
          text: explanation.interviewExpression,
          color: AppColors.blueDark,
        ),
        if (!explanation.evidenceSufficient ||
            explanation.unsupportedLayers.isNotEmpty)
          _EvidenceWarning(
            unsupportedLayers: explanation.unsupportedLayers,
          ),
        const SizedBox(height: 4),
        const _SectionTitle(title: '讲解依据'),
        const SizedBox(height: 8),
        if (citedChunks.isEmpty)
          const _EvidenceWarning(unsupportedLayers: ['核心讲解'])
        else
          ...citedChunks.map(
            (chunk) => SourceCitationBlock(
              chunk: chunk,
              backgroundColor: AppColors.blueLight,
              contentLineHeight: 1.45,
            ),
          ),
        const SizedBox(height: 12),
        AnchorButton(
          label: '重新讲解',
          color: AppColors.blue,
          width: double.infinity,
          icon: Icons.refresh,
          onPressed: onRegenerate,
        ),
      ],
    );
  }
}

class _SocraticLoopView extends StatelessWidget {
  final List<TutorTurn> turns;
  final String? currentQuestion;
  final TextEditingController answerController;
  final List<SourceChunk> evidenceChunks;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _SocraticLoopView({
    required this.turns,
    required this.currentQuestion,
    required this.answerController,
    required this.evidenceChunks,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '苏格拉底练习'),
        const SizedBox(height: 8),
        ...turns.map(
          (turn) => _TutorTurnCard(
            turn: turn,
            evidenceChunks: evidenceChunks,
          ),
        ),
        if (currentQuestion != null && currentQuestion!.trim().isNotEmpty)
          _CurrentQuestionCard(
            question: currentQuestion!,
            answerController: answerController,
            isSubmitting: isSubmitting,
            errorMessage: errorMessage,
            onSubmit: onSubmit,
          )
        else
          const _LoopStoppedCard(),
      ],
    );
  }
}

class _CurrentQuestionCard extends StatelessWidget {
  final String question;
  final TextEditingController answerController;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _CurrentQuestionCard({
    required this.question,
    required this.answerController,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前问题',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            key: const ValueKey('tutor-current-question'),
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('tutor-answer-input'),
            controller: answerController,
            enabled: !isSubmitting,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '写下你的回答',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isSubmitting)
            const _GeneratingBlock(label: '正在核对回答与来源...')
          else
            AnchorButton(
              key: const ValueKey('tutor-submit-answer'),
              label: '提交回答',
              color: AppColors.green,
              width: double.infinity,
              icon: Icons.send,
              onPressed: onSubmit,
            ),
        ],
      ),
    );
  }
}

class _TutorTurnCard extends StatelessWidget {
  final TutorTurn turn;
  final List<SourceChunk> evidenceChunks;

  const _TutorTurnCard({
    required this.turn,
    required this.evidenceChunks,
  });

  @override
  Widget build(BuildContext context) {
    final chunksById = {for (final chunk in evidenceChunks) chunk.id: chunk};
    final citedChunks = turn.citationIds
        .map((id) => chunksById[id])
        .whereType<SourceChunk>()
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TurnLine(label: '问题', text: turn.questionText),
          _TurnLine(label: '你的回答', text: turn.userAnswer),
          _TurnLine(label: '导师反馈', text: turn.aiFeedback),
          if (turn.referenceAnswer.isNotEmpty)
            _TurnLine(label: '关键答案', text: turn.referenceAnswer),
          if (turn.misconception.isNotEmpty)
            _TurnLine(label: '识别到的误区', text: turn.misconception),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: '准确度 ${turn.accuracyScore}%',
                color: AppColors.blue,
              ),
              _StatusChip(
                label: turn.evidenceSufficient ? '证据充分' : '来源不足',
                color:
                    turn.evidenceSufficient ? AppColors.green : AppColors.red,
              ),
            ],
          ),
          if (citedChunks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '反馈依据',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...citedChunks.map(
              (chunk) => SourceCitationBlock(
                chunk: chunk,
                backgroundColor: AppColors.blueLight,
                contentLineHeight: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TurnLine extends StatelessWidget {
  final String label;
  final String text;

  const _TurnLine({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _LoopStoppedCard extends StatelessWidget {
  const _LoopStoppedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pause_circle_outline, color: AppColors.goldDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '导师已停止扩展下一问。请先补充能够支撑当前概念或先修关系的来源。',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceWarning extends StatelessWidget {
  final List<String> unsupportedLayers;

  const _EvidenceWarning({required this.unsupportedLayers});

  @override
  Widget build(BuildContext context) {
    final detail = unsupportedLayers.isEmpty
        ? '现有来源不足以继续。'
        : '来源不足：${unsupportedLayers.join('、')}。';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Text(
        '$detail 未支持部分不会继续生成事实或追问。',
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  final String title;
  final String text;
  final Color color;

  const _ExplanationSection({
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _BulletSection({
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•', style: TextStyle(color: color, fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textPrimary,
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

class _GeneratingBlock extends StatelessWidget {
  final String label;

  const _GeneratingBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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

class _EmptyTutorState extends StatelessWidget {
  const _EmptyTutorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '知识库还没有带来源依据的知识点。先导入项目材料或编程资料，并在审核后保留来源片段。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
