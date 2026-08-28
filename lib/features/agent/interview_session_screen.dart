import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/agent/grounded_learning_context_service.dart';
import '../../services/ai/ai_task_result.dart';
import '../../services/ai/tasks/answer_evaluation_task.dart';
import '../../services/ai/tasks/interview_question_task.dart';
import '../../services/agent/project_interview_flow_service.dart';
import '../../shared/widgets/anchor_button.dart';
import '../../shared/widgets/source_citation_block.dart';
import 'review_agent_screen.dart';

/// 对话式面试会话屏幕
///
/// **功能**: AI 作为面试官,逐个询问知识点,用户作答后 AI 评估并追问
///
/// **面试流程**:
/// 1. 从知识库中筛选有来源依据的知识点
/// 2. AI 生成面试问题(基于知识点和原文片段)
/// 3. 用户作答
/// 4. AI 评估答案(正确性/完整度/理解深度)
/// 5. 根据评估结果:
///    - 答得好 → 进入下一个知识点
///    - 有遗漏 → AI 追问(follow-up question)
/// 6. 完成后生成面试报告
///
/// **技术特点**:
/// - 使用 GroundedLearningContext 确保问题基于真实原文
/// - 追踪已问过的基础问题(_askedBasePointIds)和追问(_followedUpPointIds)
/// - 支持从指定知识点开始(initialPoint)或直接追问(initialFollowUpQuestion)
/// - 所有对话轮次保存到 InterviewTurn 供后续回顾
///
/// **数据流向**:
/// KnowledgePoint + SourceChunk → InterviewQuestionTask → 用户作答 → AnswerEvaluationTask → 下一题/追问
class InterviewSessionScreen extends ConsumerStatefulWidget {
  final KnowledgePoint? initialPoint;
  final String? initialFollowUpQuestion;
  final LearningSession? resumeSession;

  const InterviewSessionScreen({
    super.key,
    this.initialPoint,
    this.initialFollowUpQuestion,
    this.resumeSession,
  });

  @override
  ConsumerState<InterviewSessionScreen> createState() =>
      _InterviewSessionScreenState();
}

class _InterviewSessionScreenState
    extends ConsumerState<InterviewSessionScreen> {
  static const _interviewFlow = ProjectInterviewFlowService();

  final _answerController = TextEditingController();

  LearningSession? _session;
  List<KnowledgePoint> _knowledgePoints = [];
  List<SourceChunk> _sourceChunks = [];
  Map<String, GroundedLearningContext> _groundedContextsByKnowledgePointId = {};
  List<InterviewQuestionDraft> _questions = [];
  final List<InterviewTurn> _turns = [];
  final Set<String> _askedBasePointIds = {};
  final Set<String> _followedUpPointIds = {};
  AnswerEvaluationResult? _evaluation;
  InterviewTurn? _currentTurn;
  InterviewQuestionDraft? _pendingFollowUp;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isEvaluating = false;
  bool _isPreparingNext = false;
  bool _isComplete = false;
  bool _isEnding = false;
  int _displayRound = 1;
  String _statusText = '正在准备面试题...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startSession);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    try {
      final resumeSession = widget.resumeSession;
      if (resumeSession != null &&
          (resumeSession.mode != LearningSessionMode.interview ||
              resumeSession.endedAt != null)) {
        _fail('这次面试已结束，不能继续。');
        return;
      }
      final hasKey = await ref.read(openaiServiceProvider).hasApiKey();
      if (!hasKey) {
        _fail('请先在设置中配置 AI API Key');
        return;
      }

      final allPoints = await ref
          .read(knowledgePointRepositoryProvider)
          .getAllKnowledgePoints();
      final scopedPoints = resumeSession == null
          ? allPoints
          : _resumeInterviewPoints(allPoints, resumeSession);
      final evidenceBackedPoints = await _evidenceBackedPoints(scopedPoints);
      final candidatePoints = resumeSession == null
          ? _selectInterviewPoints(evidenceBackedPoints)
          : evidenceBackedPoints;
      if (candidatePoints.isEmpty) {
        _fail('知识库里还没有带来源依据的面试知识点');
        return;
      }

      _setStatus('正在读取来源依据...');
      final candidateChunksByPoint = await _loadEvidenceChunks(candidatePoints);
      final contextsByPoint = await _buildInterviewContexts(
        candidatePoints,
        candidateChunksByPoint,
      );
      final selectedPoints = candidatePoints
          .where((point) => contextsByPoint[point.id]?.isExecutable == true)
          .toList(growable: false);
      final chunksByPoint = <String, List<SourceChunk>>{
        for (final point in selectedPoints)
          point.id: contextsByPoint[point.id]!.chunks,
      };
      final chunks = {
        for (final chunk in chunksByPoint.values.expand((chunks) => chunks))
          chunk.id: chunk,
      }.values.toList();
      if (chunks.isEmpty) {
        _fail('这些知识点还没有来源片段，暂时不能进行来源约束面试');
        return;
      }

      final sessionRepository = ref.read(learningSessionRepositoryProvider);
      final persistedTurns = resumeSession == null
          ? const <InterviewTurn>[]
          : await sessionRepository.getInterviewTurns(resumeSession.id);
      _askedBasePointIds.addAll(
        persistedTurns
            .map((turn) => turn.knowledgePointId)
            .whereType<String>()
            .where((id) => selectedPoints.any((point) => point.id == id)),
      );
      final restoredFollowUp = resumeSession == null
          ? null
          : _interviewFlow.restorePendingFollowUp(
              turns: persistedTurns,
              availablePointIds:
                  selectedPoints.map((point) => point.id).toSet(),
              availableCitationIds: chunks.map((chunk) => chunk.id).toSet(),
            );
      if (restoredFollowUp != null) {
        final pointId = restoredFollowUp.knowledgePointIds.first;
        _followedUpPointIds.add(pointId);
        if (!mounted) return;
        setState(() {
          _session = resumeSession;
          _knowledgePoints = selectedPoints;
          _sourceChunks = chunks;
          _groundedContextsByKnowledgePointId = contextsByPoint;
          _questions = [restoredFollowUp];
          _turns.addAll(persistedTurns);
          _displayRound = persistedTurns.length + 1;
          _isLoading = false;
          _statusText = '';
        });
        return;
      }
      final nextPoint = _interviewFlow.nextUnaskedPoint(
        orderedPoints: selectedPoints,
        askedPointIds: _askedBasePointIds,
      );
      if (nextPoint == null) {
        if (resumeSession == null) {
          _fail('没有可继续的来源约束面试题');
          return;
        }
        if (!mounted) return;
        setState(() {
          _session = resumeSession;
          _knowledgePoints = selectedPoints;
          _sourceChunks = chunks;
          _groundedContextsByKnowledgePointId = contextsByPoint;
          _turns.addAll(persistedTurns);
          _isLoading = false;
          _statusText = '';
        });
        await _finishSession();
        return;
      }

      _setStatus(
          resumeSession == null ? 'AI 正在生成第一道面试问题...' : 'AI 正在恢复未完成的面试...');
      final firstQuestion = await _generateQuestionForPoint(
        point: nextPoint,
        groundedContext: contextsByPoint[nextPoint.id]!,
        followUpQuestion:
            resumeSession == null ? _followUpQuestionFor(selectedPoints) : null,
      );
      final session = resumeSession ??
          LearningSession(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            mode: LearningSessionMode.interview,
            targetId: selectedPoints.map((point) => point.id).join('\x00'),
            startedAt: DateTime.now(),
          );
      if (resumeSession == null) {
        await sessionRepository.insertLearningSession(session);
      }

      if (!mounted) return;
      _askedBasePointIds.add(nextPoint.id);
      setState(() {
        _session = session;
        _knowledgePoints = selectedPoints;
        _sourceChunks = chunks;
        _groundedContextsByKnowledgePointId = contextsByPoint;
        _questions = [firstQuestion];
        _turns.addAll(persistedTurns);
        _displayRound = persistedTurns.length + 1;
        _isLoading = false;
        _statusText = '';
      });
    } catch (e) {
      _fail('启动面试失败: $e');
    }
  }

  List<KnowledgePoint> _selectInterviewPoints(List<KnowledgePoint> points) {
    return _interviewFlow
        .orderKnowledgePoints(
          points,
          focusedPointId: widget.initialPoint?.id,
        )
        .take(8)
        .toList();
  }

  List<KnowledgePoint> _resumeInterviewPoints(
    List<KnowledgePoint> allPoints,
    LearningSession session,
  ) {
    final targetIds = session.targetId
            ?.split('\x00')
            .where((id) => id.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final byId = {for (final point in allPoints) point.id: point};
    return targetIds.map((id) => byId[id]).whereType<KnowledgePoint>().toList();
  }

  Future<List<KnowledgePoint>> _evidenceBackedPoints(
    List<KnowledgePoint> points,
  ) async {
    final backed = <KnowledgePoint>[];
    for (final point in points) {
      final relations = await ref
          .read(knowledgePointRepositoryProvider)
          .getKnowledgePointSources(point.id);
      if (relations.isEmpty) continue;

      var hasChunk = false;
      for (final relation in relations) {
        final chunk = await ref
            .read(sourceChunkRepositoryProvider)
            .getSourceChunk(relation.sourceChunkId);
        if (chunk != null) {
          hasChunk = true;
          break;
        }
      }
      if (hasChunk) backed.add(point);
    }
    return backed;
  }

  Future<Map<String, List<SourceChunk>>> _loadEvidenceChunks(
    List<KnowledgePoint> points,
  ) async {
    final chunksByPointId = <String, List<SourceChunk>>{};
    for (final point in points) {
      final chunks = <String, SourceChunk>{};
      final relations = await ref
          .read(knowledgePointRepositoryProvider)
          .getKnowledgePointSources(point.id);
      for (final relation in relations) {
        final chunk = await ref
            .read(sourceChunkRepositoryProvider)
            .getSourceChunk(relation.sourceChunkId);
        if (chunk != null) chunks[chunk.id] = chunk;
      }
      if (chunks.isNotEmpty) chunksByPointId[point.id] = chunks.values.toList();
    }
    return chunksByPointId;
  }

  Future<Map<String, GroundedLearningContext>> _buildInterviewContexts(
    List<KnowledgePoint> points,
    Map<String, List<SourceChunk>> chunksByPointId,
  ) async {
    final sources = <String, Source>{};
    for (final sourceId in chunksByPointId.values
        .expand((chunks) => chunks)
        .map((chunk) => chunk.sourceId)
        .toSet()) {
      final source = await ref.read(sourceProvider(sourceId).future);
      if (source != null) sources[source.id] = source;
    }
    final service = ref.read(groundedLearningContextServiceProvider);
    return {
      for (final point in points)
        point.id: service.select(
          targetId: point.id,
          knowledgePoint: point,
          surface: GroundedLearningSurface.interview,
          candidates: (chunksByPointId[point.id] ?? const [])
              .map(
                (chunk) => GroundedLearningContextCandidate(
                  chunk: chunk,
                  reasons: const [
                    GroundedLearningContextReason.targetRelation,
                  ],
                ),
              )
              .toList(growable: false),
          sources: sources.values.toList(growable: false),
        ),
    };
  }

  Future<InterviewQuestionDraft> _generateQuestionForPoint({
    required KnowledgePoint point,
    required GroundedLearningContext groundedContext,
    String? followUpQuestion,
  }) async {
    if (!groundedContext.isExecutable) {
      throw StateError('${point.title} 缺少可读来源片段');
    }
    final result = await ref.read(interviewerServiceProvider).generateQuestions(
      knowledgePoints: [point],
      sourceChunks: groundedContext.chunks,
      questionCount: 1,
      followUpQuestion: followUpQuestion,
      groundedContext: groundedContext,
    );
    if (!result.isSuccess) {
      throw StateError(result.errorMessage ?? '面试问题生成失败');
    }
    return result.requireData.questions.first;
  }

  Future<void> _evaluateCurrentAnswer() async {
    final session = _session;
    if (session == null || _questions.isEmpty) return;

    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() => _errorMessage = '请先输入你的回答');
      return;
    }

    setState(() {
      _isEvaluating = true;
      _errorMessage = null;
    });

    try {
      final question = _questions[_currentIndex];
      final parentContext = _groundedContextForQuestion(question);
      final evaluationContext = parentContext == null
          ? null
          : ref
              .read(groundedLearningContextServiceProvider)
              .selectCitationSubset(
                parent: parentContext,
                targetId: '${session.id}:turn:$_currentIndex',
                surface: GroundedLearningSurface.interview,
                citationIds: question.citationIds,
                reason: GroundedLearningContextReason.questionCitation,
              );
      final citedChunks = evaluationContext?.chunks ?? const <SourceChunk>[];
      if (evaluationContext == null || !evaluationContext.isExecutable) {
        if (!mounted) return;
        setState(() {
          _isEvaluating = false;
          _errorMessage = evaluationContext == null
              ? '这道题缺少目标级 grounded context，暂时不能评估'
              : evaluationContext.diagnosticLines.join('\n');
        });
        return;
      }
      final result = await ref.read(interviewerServiceProvider).evaluateAnswer(
            question: question,
            userAnswer: answer,
            citedChunks: citedChunks,
            groundedContext: evaluationContext,
          );
      if (!result.isSuccess) {
        if (!mounted) return;
        setState(() {
          _isEvaluating = false;
          _errorMessage = _evaluationFailureMessage(result);
        });
        return;
      }

      final evaluation = result.requireData;
      final now = DateTime.now();
      final knowledgePoint = _pointForQuestion(question);
      final citedChunkIds = citedChunks.map((chunk) => chunk.id).toSet();
      final fallbackCitationIds = evaluation.citationIds.isEmpty
          ? question.citationIds
          : evaluation.citationIds;
      final turnCitationIds =
          fallbackCitationIds.where(citedChunkIds.contains).toSet().toList();
      final draftTurn = InterviewTurn(
        id: now.microsecondsSinceEpoch.toString(),
        sessionId: session.id,
        questionText: question.question,
        userAnswer: answer,
        aiFeedback: evaluation.feedback,
        referenceAnswer: evaluation.referenceAnswer,
        knowledgePointId: knowledgePoint?.id,
        knowledgePointKind: knowledgePoint?.kind ?? KnowledgePointKind.concept,
        citationIds: turnCitationIds,
        accuracyScore: evaluation.accuracyScore,
        projectDetailScore: evaluation.projectDetailScore,
        engineeringScore: evaluation.engineeringScore,
        clarityScore: evaluation.clarityScore,
        weakKnowledgePointIds: evaluation.weakKnowledgePointIds,
        groundedClaims: evaluation.claims,
        groundingDisposition: evaluation.groundingDisposition,
        createdAt: now,
      );
      final turn = await ref
          .read(interviewReviewClosureServiceProvider)
          .closeAndPersistTurn(turn: draftTurn, now: now);
      await ref.read(masteryServiceProvider).updateFromInterviewTurn(
            turn: turn,
            knowledgePointIds: question.knowledgePointIds,
          );
      ref.invalidate(knowledgePointListProvider);
      ref.invalidate(evidenceBackedKnowledgePointListProvider);
      ref.invalidate(practiceableKnowledgePointListProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(verifiedQuestionsProvider);
      ref.invalidate(todayReviewQueueProvider);
      for (final id in {
        ...question.knowledgePointIds,
        ...turn.weakKnowledgePointIds,
      }) {
        ref.invalidate(knowledgePointProvider(id));
        ref.invalidate(knowledgePointQuestionsProvider(id));
      }

      final followUp = _interviewFlow.buildGroundedFollowUp(
        currentQuestion: question,
        evaluation: evaluation,
        knowledgePoints: _knowledgePoints,
        citedChunks: citedChunks,
        followedUpPointIds: _followedUpPointIds,
      );

      if (!mounted) return;
      setState(() {
        _turns.add(turn);
        _currentTurn = turn;
        _evaluation = evaluation;
        _pendingFollowUp = followUp;
        _isEvaluating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEvaluating = false;
        _errorMessage = '评估失败: $e';
      });
    }
  }

  List<SourceChunk> _chunksForQuestion(InterviewQuestionDraft question) {
    final byId = {for (final chunk in _sourceChunks) chunk.id: chunk};
    final direct = question.citationIds
        .map((id) => byId[id])
        .whereType<SourceChunk>()
        .toList();
    return direct;
  }

  GroundedLearningContext? _groundedContextForQuestion(
    InterviewQuestionDraft question,
  ) {
    for (final pointId in question.knowledgePointIds) {
      final context = _groundedContextsByKnowledgePointId[pointId];
      if (context != null) return context;
    }
    return null;
  }

  KnowledgePoint? _pointForQuestion(InterviewQuestionDraft question) {
    for (final pointId in question.knowledgePointIds) {
      for (final point in _knowledgePoints) {
        if (point.id == pointId) return point;
      }
    }
    return null;
  }

  String _evaluationFailureMessage(
      AiTaskResult<AnswerEvaluationResult> result) {
    if (result.errorType == AiTaskErrorType.request) {
      final message = result.errorMessage?.trim() ?? '';
      if (message.isNotEmpty) return message;
      return '暂时无法完成 AI 评估，请保留回答后重试。';
    }
    if (result.errorType == AiTaskErrorType.parse) {
      return 'AI 返回的评估格式无效，请保留回答后重试。';
    }
    return result.errorMessage?.trim().isNotEmpty == true
        ? result.errorMessage!.trim()
        : '回答评估失败，请保留回答后重试。';
  }

  Future<void> _nextQuestion() async {
    if (_isPreparingNext) return;

    final followUp = _pendingFollowUp;
    if (followUp != null) {
      final pointId = followUp.knowledgePointIds.first;
      setState(() {
        _questions.add(followUp);
        _currentIndex++;
        _displayRound++;
        _followedUpPointIds.add(pointId);
        _pendingFollowUp = null;
        _answerController.clear();
        _evaluation = null;
        _currentTurn = null;
        _errorMessage = null;
      });
      return;
    }

    final nextPoint = _nextBasePoint();
    if (nextPoint == null) {
      await _finishSession();
      return;
    }

    setState(() {
      _isPreparingNext = true;
      _errorMessage = null;
    });

    try {
      final question = await _generateQuestionForPoint(
        point: nextPoint,
        groundedContext: _groundedContextsByKnowledgePointId[nextPoint.id]!,
      );
      if (!mounted) return;
      setState(() {
        _askedBasePointIds.add(nextPoint.id);
        _questions.add(question);
        _currentIndex++;
        _displayRound++;
        _answerController.clear();
        _evaluation = null;
        _currentTurn = null;
        _isPreparingNext = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreparingNext = false;
        _errorMessage = '下一题生成失败: $e';
      });
    }
  }

  KnowledgePoint? _nextBasePoint() {
    return _interviewFlow.nextUnaskedPoint(
      orderedPoints: _knowledgePoints,
      askedPointIds: _askedBasePointIds,
    );
  }

  bool get _hasNextQuestion {
    return _pendingFollowUp != null || _nextBasePoint() != null;
  }

  Future<void> _finishSession() async {
    final session = _session;
    if (session != null) {
      final completedSession = session.copyWith(
        endedAt: DateTime.now(),
        xpGained: _turns.length * 15,
        summary: _interviewSessionSummary(),
      );
      await ref
          .read(learningSessionRepositoryProvider)
          .updateLearningSession(completedSession);
      invalidateAgentLearningRecordProviders(ref);
      if (mounted) {
        setState(() => _session = completedSession);
      }
    }
    if (!mounted) return;
    setState(() => _isComplete = true);
  }

  Future<bool> _confirmExit() async {
    final session = _session;
    if (session == null || session.endedAt != null || _isComplete) return true;
    if (_isEvaluating || _isPreparingNext || _isEnding) {
      if (mounted) {
        setState(() => _errorMessage = '当前操作尚未完成，请稍候再结束面试。');
      }
      return false;
    }
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束本次面试？'),
        content: Text(
          '已保存 ${_turns.length} 轮评分。未提交的回答不会保存，之后可从面试复盘继续未完成会话。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续面试'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('结束面试'),
          ),
        ],
      ),
    );
    if (shouldEnd != true) return false;

    if (mounted) setState(() => _isEnding = true);
    final interruptedSession = session.copyWith(
      endedAt: DateTime.now(),
      xpGained: _turns.length * 15,
      summary: '中断面试，已保存 ${_turns.length} 轮评分。',
    );
    await ref
        .read(learningSessionRepositoryProvider)
        .updateLearningSession(interruptedSession);
    invalidateAgentLearningRecordProviders(ref);
    if (mounted) {
      setState(() {
        _session = interruptedSession;
        _isEnding = false;
      });
    }
    return true;
  }

  Future<void> _handlePopRequest() async {
    if (!await _confirmExit() || !mounted) return;
    Navigator.of(context).pop();
  }

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() => _statusText = status);
  }

  String _interviewSessionSummary() {
    final followUpQuestion = _followUpQuestionFor(_knowledgePoints);
    final lines = [
      '完成 ${_turns.length} 轮项目面试训练',
      if (followUpQuestion != null && followUpQuestion.isNotEmpty)
        '本轮追问: $followUpQuestion',
    ];
    return lines.join('\n');
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
      _statusText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('面试官模式')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.green),
                const SizedBox(height: 18),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null && _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('面试官模式')),
        body: _ErrorView(message: _errorMessage!),
      );
    }

    if (_isComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('面试完成')),
        body: InterviewCompletionView(
          turns: _turns,
          knowledgePoints: _knowledgePoints,
          sourceChunks: _sourceChunks,
        ),
      );
    }

    final question = _questions[_currentIndex];
    final evaluation = _evaluation;
    final knowledgePoint = _pointForQuestion(question);
    final questionChunks = _chunksForQuestion(question);

    return PopScope<Object?>(
      canPop: _session == null || _session!.endedAt != null || _isComplete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePopRequest();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('面试官模式'),
          actions: [
            if (_session?.endedAt == null && !_isComplete)
              IconButton(
                tooltip: '结束面试',
                onPressed: _isEvaluating || _isPreparingNext || _isEnding
                    ? null
                    : _handlePopRequest,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(
                current: _displayRound,
                knowledgePoint: knowledgePoint,
                followUpQuestion: _followUpQuestionFor(_knowledgePoints),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _QuestionCard(
                      question: question,
                      knowledgePoint: knowledgePoint,
                      citedChunks: questionChunks,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _answerController,
                      enabled: evaluation == null && !_isEvaluating,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: '像真实面试一样回答：讲清楚事实、项目细节、取舍和限制',
                        hintStyle: const TextStyle(color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (evaluation != null && _currentTurn != null) ...[
                      const SizedBox(height: 16),
                      _EvaluationCard(
                        turn: _currentTurn!,
                        citedChunks: _chunksForTurn(_currentTurn!),
                      ),
                    ],
                  ],
                ),
              ),
              _BottomActionBar(
                hasEvaluation: evaluation != null,
                isEvaluating: _isEvaluating,
                isPreparingNext: _isPreparingNext,
                hasNext: _hasNextQuestion,
                onEvaluate: () => _evaluateCurrentAnswer(),
                onNext: () => _nextQuestion(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SourceChunk> _chunksForTurn(InterviewTurn turn) {
    final byId = {for (final chunk in _sourceChunks) chunk.id: chunk};
    return turn.citationIds
        .map((id) => byId[id])
        .whereType<SourceChunk>()
        .toList();
  }

  String? _followUpQuestionFor(List<KnowledgePoint> points) {
    final question = widget.initialFollowUpQuestion?.trim();
    if (question == null || question.isEmpty || widget.initialPoint == null) {
      return null;
    }
    final hasInitialPoint = points.any(
      (point) => point.id == widget.initialPoint!.id,
    );
    return hasInitialPoint ? question : null;
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final KnowledgePoint? knowledgePoint;
  final String? followUpQuestion;

  const _ProgressHeader({
    required this.current,
    required this.knowledgePoint,
    required this.followUpQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final point = knowledgePoint;
    final title =
        point == null ? '项目知识点' : '${point.kind.label} · ${point.title}';
    final question = followUpQuestion;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.greenLight,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 $current 轮',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (question != null && question.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.question_answer_outlined,
                  color: AppColors.greenDark,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '本轮优先追问：$question',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final InterviewQuestionDraft question;
  final KnowledgePoint? knowledgePoint;
  final List<SourceChunk> citedChunks;

  const _QuestionCard({
    required this.question,
    required this.knowledgePoint,
    required this.citedChunks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (question.isFollowUp) const _MetaChip(label: '证据追问'),
              if (knowledgePoint != null)
                _MetaChip(label: knowledgePoint!.kind.label),
              _MetaChip(label: '难度 ${question.difficulty}'),
              _MetaChip(label: '依据 ${question.citationIds.length} 条'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (knowledgePoint != null) ...[
            const SizedBox(height: 8),
            Text(
              knowledgePoint!.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (citedChunks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                '题目依据',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              children: citedChunks
                  .map(
                    (chunk) => SourceCitationBlock(
                      chunk: chunk,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final InterviewTurn turn;
  final List<SourceChunk> citedChunks;

  const _EvaluationCard({
    required this.turn,
    required this.citedChunks,
  });

  @override
  Widget build(BuildContext context) {
    final totalScore = turn.accuracyScore +
        turn.projectDetailScore +
        turn.engineeringScore +
        turn.clarityScore;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '评分 $totalScore / 20',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.blueDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: turn.knowledgePointKind.label),
              _MetaChip(label: '事实 ${turn.accuracyScore}/5'),
              _MetaChip(label: '项目 ${turn.projectDetailScore}/5'),
              _MetaChip(label: '工程 ${turn.engineeringScore}/5'),
              _MetaChip(label: '表达 ${turn.clarityScore}/5'),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: '反馈'),
          const SizedBox(height: 6),
          Text(
            turn.aiFeedback,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: '参考回答'),
          const SizedBox(height: 6),
          Text(
            turn.referenceAnswer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          if (citedChunks.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _SectionTitle(title: '依据片段'),
            const SizedBox(height: 8),
            ...citedChunks.map(
              (chunk) => SourceCitationBlock(
                chunk: chunk,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool hasEvaluation;
  final bool isEvaluating;
  final bool isPreparingNext;
  final bool hasNext;
  final VoidCallback onEvaluate;
  final VoidCallback onNext;

  const _BottomActionBar({
    required this.hasEvaluation,
    required this.isEvaluating,
    required this.isPreparingNext,
    required this.hasNext,
    required this.onEvaluate,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: SafeArea(
        child: AnchorButton(
          label: hasEvaluation
              ? (isPreparingNext ? '正在生成下一题...' : (hasNext ? '继续下一题' : '完成面试'))
              : (isEvaluating ? '评估中...' : '提交回答'),
          color: hasEvaluation ? AppColors.blue : AppColors.green,
          width: double.infinity,
          height: 56,
          icon: hasEvaluation ? Icons.arrow_forward : Icons.check,
          enabled: !isEvaluating && !isPreparingNext,
          onPressed: hasEvaluation ? onNext : onEvaluate,
        ),
      ),
    );
  }
}

class InterviewCompletionView extends StatelessWidget {
  final List<InterviewTurn> turns;
  final List<KnowledgePoint> knowledgePoints;
  final List<SourceChunk> sourceChunks;

  const InterviewCompletionView({
    super.key,
    required this.turns,
    required this.knowledgePoints,
    required this.sourceChunks,
  });

  @override
  Widget build(BuildContext context) {
    final averageScore = turns.isEmpty
        ? 0
        : turns
                .map((turn) =>
                    turn.accuracyScore +
                    turn.projectDetailScore +
                    turn.engineeringScore +
                    turn.clarityScore)
                .reduce((a, b) => a + b) /
            turns.length;
    final reviewActions = turns.where((turn) => turn.hasReviewAction).toList();
    final pointsById = {
      for (final point in knowledgePoints) point.id: point,
    };
    final chunksById = {
      for (final chunk in sourceChunks) chunk.id: chunk,
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.record_voice_over,
            size: 64,
            color: AppColors.green,
          ),
          const SizedBox(height: 18),
          const Text(
            '面试训练完成',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成 ${turns.length} 轮，平均 ${averageScore.round()} / 20',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (reviewActions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '薄弱点与下一步',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...reviewActions.map((turn) {
              final point = pointsById[turn.knowledgePointId];
              final chunks = turn.citationIds
                  .map((id) => chunksById[id])
                  .whereType<SourceChunk>()
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InterviewReviewActionCard(
                  turn: turn,
                  knowledgePoint: point,
                  citedChunks: chunks,
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          AnchorButton(
            label: '返回 Agent',
            color: AppColors.blue,
            width: double.infinity,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _InterviewReviewActionCard extends StatelessWidget {
  final InterviewTurn turn;
  final KnowledgePoint? knowledgePoint;
  final List<SourceChunk> citedChunks;

  const _InterviewReviewActionCard({
    required this.turn,
    required this.knowledgePoint,
    required this.citedChunks,
  });

  @override
  Widget build(BuildContext context) {
    final point = knowledgePoint;
    final weakLabels =
        turn.weakDimensions.map((dimension) => dimension.label).join('、');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: turn.knowledgePointKind.label),
              _MetaChip(label: weakLabels),
              _MetaChip(label: '${turn.reviewQuestionIds.length} 道复习题'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            point?.title ?? turn.knowledgePointId ?? '项目知识单元',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            turn.aiFeedback,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (citedChunks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...citedChunks.map(
              (chunk) => SourceCitationBlock(
                chunk: chunk,
                margin: const EdgeInsets.only(bottom: 8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: point == null || turn.reviewQuestionIds.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReviewAgentScreen(
                              initialPoint: point,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.event_repeat),
                label: const Text('开始复习'),
              ),
              ElevatedButton.icon(
                onPressed: point == null
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => InterviewSessionScreen(
                              initialPoint: point,
                              initialFollowUpQuestion:
                                  turn.nextInterviewQuestion,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.record_voice_over),
                label: const Text('再次面试'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
