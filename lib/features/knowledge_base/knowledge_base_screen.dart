import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/agent/hybrid_knowledge_search_service.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';
import '../../services/agent/knowledge_search_service.dart';
import '../../services/agent/search_query_debouncer.dart';
import '../../services/ingestion/question_bulk_verification_service.dart';
import '../../services/privacy/privacy_redactor.dart';
import '../../services/ai/tasks/knowledge_answer_task.dart';
import '../agent/tutor_session_screen.dart';
import '../ingestion/ingestion_screen.dart';
import '../learning/quiz_screen.dart';
import 'knowledge_answer_evidence_quality_badges.dart';
import 'knowledge_answer_quality_notice.dart';
import 'knowledge_answer_repair_action_button.dart';
import 'knowledge_answer_review_copy_button.dart';
import 'knowledge_answer_history_screen.dart';
import 'knowledge_answer_session_detail_screen.dart';
import 'concept_learning_path_screen.dart';
import 'learning_target_memory_timeline.dart';
import 'knowledge_library_error_state.dart';
import 'knowledge_search_ranking_reasons.dart';

class KnowledgeBaseScreen extends ConsumerWidget {
  final int initialTabIndex;
  final String? initialSearchQuery;
  final Duration searchDebounceDelay;

  const KnowledgeBaseScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearchQuery,
    this.searchDebounceDelay = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(sourceListProvider);
    final pointsAsync = ref.watch(knowledgePointListProvider);
    final questionsAsync = ref.watch(allQuestionsProvider);
    final pendingAsync = ref.watch(pendingQuestionListProvider);

    final sourceCount = _countOf(sourcesAsync);
    final pointCount = _countOf(pointsAsync);
    final questionCount = _countOf(questionsAsync);
    final pendingCount = _countOf(pendingAsync);

    return DefaultTabController(
      length: 5,
      initialIndex: _initialIndex,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '知识库',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '编程学习路径',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ConceptLearningPathScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.route_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MetricTile(
                          icon: Icons.source,
                          color: AppColors.blue,
                          label: '来源',
                          value: sourceCount.toString(),
                        ),
                        const SizedBox(width: 8),
                        _MetricTile(
                          icon: Icons.psychology,
                          color: AppColors.green,
                          label: '知识点',
                          value: pointCount.toString(),
                        ),
                        const SizedBox(width: 8),
                        _MetricTile(
                          icon: Icons.quiz,
                          color: AppColors.gold,
                          label: '题目',
                          value: questionCount.toString(),
                        ),
                        const SizedBox(width: 8),
                        _MetricTile(
                          icon: Icons.fact_check,
                          color: pendingCount > 0
                              ? AppColors.streakOrange
                              : AppColors.textLight,
                          label: '待核验',
                          value: pendingCount.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const TabBar(
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.green,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: '检索'),
                  Tab(text: '来源'),
                  Tab(text: '知识点'),
                  Tab(text: '题目'),
                  Tab(text: '待核验'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _KnowledgeSearchTab(
                      initialQuery: initialSearchQuery,
                      debounceDelay: searchDebounceDelay,
                    ),
                    _SourcesTab(sourcesAsync: sourcesAsync),
                    _KnowledgePointsTab(pointsAsync: pointsAsync),
                    _QuestionsTab(questionsAsync: questionsAsync),
                    _PendingQuestionsTab(questionsAsync: pendingAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countOf<T>(AsyncValue<List<T>> value) {
    return value.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
  }

  int get _initialIndex {
    final query = initialSearchQuery?.trim();
    if (query != null && query.isNotEmpty) return 0;
    return initialTabIndex.clamp(0, 4).toInt();
  }
}

class _KnowledgeSearchTab extends ConsumerStatefulWidget {
  final String? initialQuery;
  final Duration debounceDelay;

  const _KnowledgeSearchTab({
    this.initialQuery,
    required this.debounceDelay,
  });

  @override
  ConsumerState<_KnowledgeSearchTab> createState() =>
      _KnowledgeSearchTabState();
}

class _KnowledgeSearchTabState extends ConsumerState<_KnowledgeSearchTab> {
  final _controller = TextEditingController();
  late final SearchQueryDebouncer _queryDebouncer;
  String _draftQuery = '';
  String _query = '';
  bool _isAnswering = false;
  KnowledgeAnswerResult? _answer;
  String? _answerError;
  DateTime? _answerCompletedAt;
  DateTime? _answerFailedAt;
  int _answerAttemptCount = 0;
  bool _answerSaved = false;
  DateTime? _answerSavedAt;
  bool _isRecordingAnswer = false;
  String? _answerRecordError;
  DateTime? _answerRecordFailedAt;
  int _answerRecordAttemptCount = 0;
  List<SourceChunk> _answerChunks = const [];
  GroundedLearningContext? _answerContext;

  @override
  void initState() {
    super.initState();
    _queryDebouncer = SearchQueryDebouncer(delay: widget.debounceDelay);
    final initialQuery = widget.initialQuery?.trim();
    if (initialQuery == null || initialQuery.isEmpty) return;
    _controller.text = initialQuery;
    _controller.selection = TextSelection.collapsed(
      offset: initialQuery.length,
    );
    _draftQuery = initialQuery;
    _query = initialQuery;
  }

  @override
  void dispose() {
    _queryDebouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftQuery = _draftQuery.trim();
    final query = _query.trim();
    final resultsAsync =
        query.isEmpty ? null : ref.watch(knowledgeSearchResultsProvider(query));
    final hybridAsync = query.isEmpty
        ? null
        : ref.watch(knowledgeHybridSearchReportProvider(query));
    final answerContextAsync = query.isEmpty
        ? null
        : ref.watch(knowledgeAnswerGroundedContextProvider(query));
    final answerSessionsAsync = ref.watch(knowledgeAnswerSessionListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            key: const ValueKey('knowledge-search-input'),
            controller: _controller,
            onChanged: _setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索来源、知识点、题目',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: draftQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        _setQuery('');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.green, width: 2),
              ),
            ),
          ),
        ),
        if (draftQuery.isNotEmpty && draftQuery != query)
          const LinearProgressIndicator(
            key: ValueKey('knowledge-search-debounce-progress'),
            minHeight: 2,
            color: AppColors.green,
          ),
        if (query.isNotEmpty &&
            hybridAsync?.valueOrNull?.status ==
                HybridKnowledgeSearchStatus.augmented)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                key: ValueKey('knowledge-search-augmented-chip'),
                avatar: Icon(Icons.auto_awesome, size: 16),
                label: Text('模型改写已融合'),
              ),
            ),
          ),
        if (query.isNotEmpty &&
            hybridAsync?.valueOrNull?.status ==
                HybridKnowledgeSearchStatus.fallback)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                key: ValueKey('knowledge-search-fallback-chip'),
                avatar: Icon(Icons.offline_bolt_outlined, size: 16),
                label: Text('已回退本地检索'),
              ),
            ),
          ),
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: answerContextAsync!.when(
              data: (groundedContext) => _KnowledgeAnswerActionBar(
                query: query,
                contextChunkCount: groundedContext.items.length,
                isAnswering: _isAnswering,
                onRefreshContext: () => ref.invalidate(
                  knowledgeAnswerGroundedContextProvider(query),
                ),
                onAnswer: !groundedContext.isExecutable || _isAnswering
                    ? null
                    : () => _answerQuestion(query, groundedContext),
              ),
              loading: () => const LinearProgressIndicator(
                color: AppColors.green,
              ),
              error: (error, _) => _KnowledgeAnswerContextErrorBar(
                query: query,
                error: error,
                onRetry: () => ref.invalidate(
                  knowledgeAnswerGroundedContextProvider(query),
                ),
              ),
            ),
          ),
        if (_answer != null || _answerError != null)
          _KnowledgeAnswerPanel(
            question: query,
            answer: _answer,
            error: _answerError,
            answerCompletedAt: _answerCompletedAt,
            answerFailedAt: _answerFailedAt,
            answerAttemptCount: _answerAttemptCount,
            recordSaved: _answerSaved,
            recordSavedAt: _answerSavedAt,
            isRecording: _isRecordingAnswer,
            recordError: _answerRecordError,
            recordFailedAt: _answerRecordFailedAt,
            recordAttemptCount: _answerRecordAttemptCount,
            sourceChunks: _answerChunks,
            onRetryAnswer: _retryKnowledgeAnswer,
            onRetryRecord: _retryRecordKnowledgeAnswer,
            onSourceGapSelected: _useKnowledgeAnswerQuery,
            onFollowUpSelected: _useKnowledgeAnswerQuery,
          ),
        Expanded(
          child: query.isEmpty
              ? _KnowledgeAnswerHistoryEmptyState(
                  sessionsAsync: answerSessionsAsync,
                  onSessionSelected: _openKnowledgeAnswerDetail,
                  onRepairSearch: _useKnowledgeAnswerQuery,
                  onOpenHistory: _openKnowledgeAnswerHistory,
                  onOpenQualityIssues: () => _openKnowledgeAnswerHistory(
                    initialOnlyQualityIssues: true,
                  ),
                  onOpenMissingCitations: () => _openKnowledgeAnswerHistory(
                    initialOnlyWithoutCitations: true,
                  ),
                  onOpenSourceGaps: () => _openKnowledgeAnswerHistory(
                    initialOnlyWithSourceGaps: true,
                  ),
                  onOpenRepairable: () => _openKnowledgeAnswerHistory(
                    initialOnlyRepairable: true,
                  ),
                  onOpenNeedsReview: () => _openKnowledgeAnswerHistory(
                    initialOnlyNeedsReview: true,
                  ),
                  onOpenCleanEvidence: () => _openKnowledgeAnswerHistory(
                    initialOnlyCleanEvidence: true,
                  ),
                  onRetryRecentAnswers: () => ref.invalidate(
                    knowledgeAnswerSessionListProvider,
                  ),
                )
              : resultsAsync!.when(
                  data: (results) {
                    final hybridReport = hybridAsync?.valueOrNull;
                    final displayResults = hybridReport?.status ==
                            HybridKnowledgeSearchStatus.augmented
                        ? hybridReport!.results
                            .map((item) => item.result)
                            .toList(growable: false)
                        : results;
                    if (displayResults.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.search_off,
                        title: '没有匹配结果',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final result = displayResults[index];
                        return _KnowledgeSearchResultRow(
                          result: result,
                          onTap: () => _openResult(context, result),
                        );
                      },
                    );
                  },
                  loading: () => const _LoadingState(),
                  error: (error, _) => KnowledgeLibraryErrorState(
                    title: '检索结果读取失败',
                    retryLabel: '重试检索',
                    diagnosticTitle: '知识库检索结果读取失败',
                    diagnosticSuccessMessage: '已复制检索失败诊断',
                    diagnosticLines: ['查询: $query'],
                    error: error,
                    onRetry: () {
                      ref.invalidate(knowledgeSearchCorpusProvider);
                      ref.invalidate(knowledgeSearchResultsProvider(query));
                      ref.invalidate(
                          knowledgeHybridSearchReportProvider(query));
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _setQuery(String value) {
    _queryDebouncer.cancel();
    setState(() {
      _draftQuery = value;
      if (value.trim().isEmpty) _query = '';
      _isAnswering = false;
      _answer = null;
      _answerError = null;
      _answerCompletedAt = null;
      _answerFailedAt = null;
      _answerAttemptCount = 0;
      _answerSaved = false;
      _answerSavedAt = null;
      _isRecordingAnswer = false;
      _answerRecordError = null;
      _answerRecordFailedAt = null;
      _answerRecordAttemptCount = 0;
      _answerChunks = const [];
      _answerContext = null;
    });
    _queryDebouncer.schedule(value, (committedQuery) {
      if (!mounted || _draftQuery != committedQuery) return;
      setState(() => _query = committedQuery);
    });
  }

  Future<void> _answerQuestion(
    String query,
    GroundedLearningContext groundedContext, {
    bool resetAttemptCount = true,
  }) async {
    final sourceChunks = groundedContext.chunks;
    setState(() {
      _isAnswering = true;
      _answer = null;
      _answerError = null;
      _answerCompletedAt = null;
      _answerFailedAt = null;
      _answerAttemptCount = resetAttemptCount ? 1 : _answerAttemptCount + 1;
      _answerSaved = false;
      _answerSavedAt = null;
      _isRecordingAnswer = false;
      _answerRecordError = null;
      _answerRecordFailedAt = null;
      _answerRecordAttemptCount = 0;
      _answerChunks = sourceChunks;
      _answerContext = groundedContext;
    });

    final result = await ref.read(knowledgeAnswerTaskProvider).run(
          question: query,
          sourceChunks: sourceChunks,
          groundedContext: groundedContext,
        );
    if (!mounted || _query.trim() != query) return;

    setState(() {
      _isAnswering = false;
      if (result.isSuccess) {
        _answer = result.requireData;
        _answerCompletedAt = DateTime.now();
        _answerFailedAt = null;
      } else {
        _answerError = result.errorMessage ?? '知识库回答生成失败';
        _answerCompletedAt = null;
        _answerFailedAt = DateTime.now();
      }
    });

    if (result.isSuccess) {
      await _recordKnowledgeAnswer(
        query,
        result.requireData,
        groundedContext,
      );
    }
  }

  void _useKnowledgeAnswerQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _setQuery(query);
  }

  Future<void> _openKnowledgeAnswerDetail(LearningSession session) async {
    final question = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => KnowledgeAnswerSessionDetailScreen(
          session: session,
          onOpenSourceChunk: _openKnowledgeAnswerSourceChunk,
        ),
      ),
    );
    if (!mounted || question == null || question.trim().isEmpty) return;
    _useKnowledgeAnswerQuery(question);
  }

  Future<void> _openKnowledgeAnswerHistory({
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
    if (!mounted || question == null || question.trim().isEmpty) return;
    _useKnowledgeAnswerQuery(question);
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

  Future<void> _recordKnowledgeAnswer(
    String query,
    KnowledgeAnswerResult answer,
    GroundedLearningContext? groundedContext,
  ) async {
    setState(() {
      _isRecordingAnswer = true;
      _answerRecordError = null;
      _answerRecordFailedAt = null;
      _answerRecordAttemptCount += 1;
    });
    try {
      final now = DateTime.now();
      await ref.read(learningSessionRepositoryProvider).insertLearningSession(
            LearningSession(
              id: now.microsecondsSinceEpoch.toString(),
              mode: LearningSessionMode.knowledgeAnswer,
              targetId: groundedContext?.knowledgePoint?.id ??
                  (answer.citationIds.isEmpty
                      ? null
                      : answer.citationIds.first),
              startedAt: now,
              endedAt: now,
              xpGained: 5,
              summary: buildKnowledgeAnswerSessionSummary(
                knowledgePointId: groundedContext?.knowledgePoint?.id,
                groundedContextId: groundedContext?.contextId,
                question: query,
                answer: answer.answer,
                keyPoints: answer.keyPoints,
                sourceGaps: answer.sourceGaps,
                followUpQuestions: answer.followUpQuestions,
                citationIds: answer.citationIds,
                groundedClaims: answer.claims,
                groundingDisposition: answer.groundingDisposition,
              ),
            ),
          );
      invalidateAgentLearningRecordProviders(ref);
      if (!mounted || _query.trim() != query) return;
      setState(() {
        _answerSaved = true;
        _answerSavedAt = now;
        _isRecordingAnswer = false;
        _answerRecordError = null;
        _answerRecordFailedAt = null;
      });
    } catch (e) {
      if (!mounted || _query.trim() != query) return;
      final failedAt = DateTime.now();
      setState(() {
        _answerSaved = false;
        _answerSavedAt = null;
        _isRecordingAnswer = false;
        _answerRecordError = '回答已生成，但学习记录保存失败: $e';
        _answerRecordFailedAt = failedAt;
      });
    }
  }

  Future<void> _retryRecordKnowledgeAnswer() async {
    final query = _query.trim();
    final answer = _answer;
    if (query.isEmpty ||
        answer == null ||
        _isRecordingAnswer ||
        _answerSaved ||
        _answerRecordError == null) {
      return;
    }
    await _recordKnowledgeAnswer(query, answer, _answerContext);
  }

  Future<void> _retryKnowledgeAnswer() async {
    final query = _query.trim();
    final groundedContext = _answerContext;
    if (query.isEmpty ||
        _isAnswering ||
        groundedContext == null ||
        !groundedContext.isExecutable) {
      return;
    }
    await _answerQuestion(
      query,
      groundedContext,
      resetAttemptCount: false,
    );
  }

  Future<void> _openResult(
    BuildContext context,
    KnowledgeSearchResult result,
  ) async {
    switch (result.type) {
      case KnowledgeSearchResultType.source:
      case KnowledgeSearchResultType.sourceChunk:
        final sourceId = result.sourceId;
        if (sourceId == null) return;
        final source =
            await ref.read(sourceRepositoryProvider).getSource(sourceId);
        if (!context.mounted || source == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SourceDetailScreen(
              source: source,
              highlightedChunkId: result.sourceChunkId,
            ),
          ),
        );
        break;
      case KnowledgeSearchResultType.knowledgePoint:
        final pointId = result.knowledgePointId;
        if (pointId == null) return;
        final point = await ref
            .read(knowledgePointRepositoryProvider)
            .getKnowledgePoint(pointId);
        if (!context.mounted || point == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KnowledgePointDetailScreen(point: point),
          ),
        );
        break;
      case KnowledgeSearchResultType.question:
        final questionId = result.questionId;
        if (questionId == null) return;
        final questions =
            await ref.read(questionRepositoryProvider).getAllQuestions();
        final question = _questionById(questions, questionId);
        if (!context.mounted || question == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionEvidenceScreen(question: question),
          ),
        );
        break;
    }

    if (!context.mounted) return;
    ref.invalidate(knowledgeSearchCorpusProvider);
    final query = _query.trim();
    if (query.isNotEmpty) {
      ref.invalidate(knowledgeSearchResultsProvider(query));
    }
  }

  Question? _questionById(List<Question> questions, String id) {
    for (final question in questions) {
      if (question.id == id) return question;
    }
    return null;
  }
}

class _KnowledgeAnswerHistoryEmptyState extends StatelessWidget {
  final AsyncValue<List<LearningSession>> sessionsAsync;
  final ValueChanged<LearningSession> onSessionSelected;
  final ValueChanged<String> onRepairSearch;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenQualityIssues;
  final VoidCallback onOpenMissingCitations;
  final VoidCallback onOpenSourceGaps;
  final VoidCallback onOpenRepairable;
  final VoidCallback onOpenNeedsReview;
  final VoidCallback onOpenCleanEvidence;
  final VoidCallback onRetryRecentAnswers;

  const _KnowledgeAnswerHistoryEmptyState({
    required this.sessionsAsync,
    required this.onSessionSelected,
    required this.onRepairSearch,
    required this.onOpenHistory,
    required this.onOpenQualityIssues,
    required this.onOpenMissingCitations,
    required this.onOpenSourceGaps,
    required this.onOpenRepairable,
    required this.onOpenNeedsReview,
    required this.onOpenCleanEvidence,
    required this.onRetryRecentAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      data: (sessions) {
        final recentSessions = sessions.take(5).toList();
        final stats = KnowledgeAnswerSessionStats.fromSessions(sessions);
        if (recentSessions.isEmpty) {
          return const _EmptyState(
            icon: Icons.search,
            title: '输入关键词检索知识库',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _EmptyState(
              icon: Icons.search,
              title: '输入关键词检索知识库',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: _SectionTitle(title: '最近知识库问答'),
                ),
                TextButton.icon(
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history, size: 18),
                  label: Text('查看全部 ${sessions.length}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (stats.hasQualityIssues) ...[
              KnowledgeAnswerQualityNotice(
                stats: stats,
                onOpenQualityIssues: onOpenQualityIssues,
                onOpenMissingCitations: onOpenMissingCitations,
                onOpenSourceGaps: onOpenSourceGaps,
                onOpenRepairable: onOpenRepairable,
                onOpenNeedsReview: onOpenNeedsReview,
                onOpenCleanEvidence: onOpenCleanEvidence,
              ),
              const SizedBox(height: 10),
            ],
            for (final session in recentSessions) ...[
              _KnowledgeAnswerHistoryRow(
                session: session,
                onTap: () => onSessionSelected(session),
                onRepairSearch: onRepairSearch,
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => KnowledgeLibraryErrorState(
        title: '最近问答读取失败',
        retryLabel: '重试读取最近问答',
        diagnosticTitle: '知识库最近问答读取失败',
        diagnosticSuccessMessage: '已复制最近问答读取诊断',
        error: error,
        onRetry: onRetryRecentAnswers,
      ),
    );
  }
}

class _KnowledgeAnswerHistoryRow extends StatelessWidget {
  final LearningSession session;
  final VoidCallback onTap;
  final ValueChanged<String> onRepairSearch;

  const _KnowledgeAnswerHistoryRow({
    required this.session,
    required this.onTap,
    required this.onRepairSearch,
  });

  @override
  Widget build(BuildContext context) {
    final summary = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
    final question = summary.question ?? '知识库问答';
    final answer = summary.answer;
    final completedText = _dateText(session.endedAt ?? session.startedAt);
    final subtitleParts = [
      '完成于 $completedText',
      ...summary.traceLabels,
      if (answer != null) answer,
    ];

    return _LibraryRow(
      icon: Icons.auto_awesome,
      color: AppColors.green,
      title: question,
      subtitle: subtitleParts.join(' · '),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KnowledgeAnswerEvidenceQualityBadges(record: summary),
          if (summary.hasRepairableQualityIssue) ...[
            const SizedBox(height: 6),
            KnowledgeAnswerRepairActionButton(
              record: summary,
              onSelected: onRepairSearch,
            ),
          ],
        ],
      ),
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _KnowledgeAnswerActionBar extends StatelessWidget {
  final String query;
  final int contextChunkCount;
  final bool isAnswering;
  final VoidCallback onRefreshContext;
  final VoidCallback? onAnswer;

  const _KnowledgeAnswerActionBar({
    required this.query,
    required this.contextChunkCount,
    required this.isAnswering,
    required this.onRefreshContext,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            contextChunkCount == 0 ? '暂无可引用片段' : '$contextChunkCount 条可引用片段',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (contextChunkCount == 0) ...[
          IconButton(
            tooltip: '查看来源',
            icon: const Icon(Icons.source, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: 30,
              height: 30,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => DefaultTabController.of(context).animateTo(1),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '重新匹配来源片段',
            icon: const Icon(Icons.refresh, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: 30,
              height: 30,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onRefreshContext,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '复制无引用诊断',
            icon: const Icon(Icons.copy, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: 30,
              height: 30,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => _copyAnswerNoContextDiagnostic(
              context,
              query: query,
            ),
          ),
          const SizedBox(width: 6),
        ],
        ElevatedButton.icon(
          onPressed: onAnswer,
          icon: isAnswering
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(isAnswering ? '回答中' : '基于来源回答'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _KnowledgeAnswerContextErrorBar extends StatelessWidget {
  final String query;
  final Object error;
  final VoidCallback onRetry;

  const _KnowledgeAnswerContextErrorBar({
    required this.query,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorText = '回答上下文读取失败: $error';
    return Row(
      children: [
        Expanded(
          child: Text(
            errorText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: '重试读取回答上下文',
          icon: const Icon(Icons.refresh, size: 18),
          color: AppColors.red,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: 30,
            height: 30,
          ),
          visualDensity: VisualDensity.compact,
          onPressed: onRetry,
        ),
        IconButton(
          tooltip: '复制上下文读取诊断',
          icon: const Icon(Icons.copy, size: 18),
          color: AppColors.textSecondary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: 30,
            height: 30,
          ),
          visualDensity: VisualDensity.compact,
          onPressed: () => _copyAnswerContextErrorDiagnostic(
            context,
            query: query,
            error: error,
          ),
        ),
      ],
    );
  }
}

class _KnowledgeAnswerPanel extends StatelessWidget {
  final String question;
  final KnowledgeAnswerResult? answer;
  final String? error;
  final DateTime? answerCompletedAt;
  final DateTime? answerFailedAt;
  final int answerAttemptCount;
  final bool recordSaved;
  final DateTime? recordSavedAt;
  final bool isRecording;
  final String? recordError;
  final DateTime? recordFailedAt;
  final int recordAttemptCount;
  final List<SourceChunk> sourceChunks;
  final VoidCallback onRetryAnswer;
  final VoidCallback onRetryRecord;
  final ValueChanged<String> onSourceGapSelected;
  final ValueChanged<String> onFollowUpSelected;

  const _KnowledgeAnswerPanel({
    required this.question,
    required this.answer,
    required this.error,
    required this.answerCompletedAt,
    required this.answerFailedAt,
    required this.answerAttemptCount,
    required this.recordSaved,
    required this.recordSavedAt,
    required this.isRecording,
    required this.recordError,
    required this.recordFailedAt,
    required this.recordAttemptCount,
    required this.sourceChunks,
    required this.onRetryAnswer,
    required this.onRetryRecord,
    required this.onSourceGapSelected,
    required this.onFollowUpSelected,
  });

  @override
  Widget build(BuildContext context) {
    final answer = this.answer;
    final answerAttemptStatusText = _answerGenerationAttemptStatusText(
      answerAttemptCount,
      hasAnswer: answer != null,
      hasError: error != null,
    );
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '重新生成回答',
                  icon: const Icon(Icons.refresh, size: 18),
                  color: AppColors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: sourceChunks.isEmpty ? null : onRetryAnswer,
                ),
                IconButton(
                  tooltip: '复制失败诊断',
                  icon: const Icon(Icons.copy, size: 18),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copyAnswerGenerationErrorDiagnostic(
                    context,
                    question: question,
                    error: error!,
                    failedAt: answerFailedAt,
                    attemptCount: answerAttemptCount,
                    sourceChunks: sourceChunks,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (answerFailedAt != null) ...[
              _AnswerRecordStatus(
                icon: Icons.schedule,
                color: AppColors.textSecondary,
                text: '生成失败于 ${_dateTimeText(answerFailedAt!)}',
              ),
              const SizedBox(height: 4),
            ],
            if (answerAttemptStatusText != null) ...[
              _AnswerRecordStatus(
                icon: Icons.history,
                color: AppColors.textSecondary,
                text: answerAttemptStatusText,
              ),
              const SizedBox(height: 4),
            ],
            _AnswerRecordStatus(
              icon: Icons.link,
              color: AppColors.textSecondary,
              text: _answerGenerationRetryContextText(sourceChunks.length),
            ),
          ],
        ),
      );
    }
    if (answer == null) return const SizedBox.shrink();

    final citedChunks = sourceChunks
        .where((chunk) => answer.citationIds.contains(chunk.id))
        .toList();
    final recordFailureStatusText = recordError == null
        ? null
        : _answerRecordFailureStatusText(recordError!, recordFailedAt);
    final recordAttemptStatusText = _answerRecordAttemptStatusText(
      recordAttemptCount,
      recordSaved: recordSaved,
      isRecording: isRecording,
      hasError: recordError != null,
    );
    final evidenceRecord = KnowledgeAnswerSessionSummaryRecord.fromFields(
      question: question,
      answer: answer.answer,
      keyPoints: answer.keyPoints,
      sourceGaps: answer.sourceGaps,
      followUpQuestions: answer.followUpQuestions,
      citationIds: answer.citationIds,
      groundedClaims: answer.claims,
      groundingDisposition: answer.groundingDisposition,
    );
    final reviewRecordStatus = _withAnswerGenerationAttemptStatus(
      recordSaved
          ? _withAnswerRecordAttemptStatus(
              knowledgeAnswerSavedRecordStatusText,
              recordAttemptCount,
              success: true,
            )
          : isRecording
              ? _withAnswerRecordAttemptStatus(
                  knowledgeAnswerSavingRecordStatusText,
                  recordAttemptCount,
                  inProgress: true,
                )
              : recordFailureStatusText == null
                  ? knowledgeAnswerUnconfirmedRecordStatusText
                  : _withAnswerRecordAttemptStatus(
                      recordFailureStatusText,
                      recordAttemptCount,
                    ),
      answerAttemptStatusText,
    );
    final reviewCompletedAt = recordSaved && recordSavedAt != null
        ? recordSavedAt
        : answerCompletedAt;
    final reviewCompletedText =
        reviewCompletedAt == null ? '' : _dateTimeText(reviewCompletedAt);
    final answerCompletedText = answerCompletedAt == null
        ? null
        : '生成于 ${_dateTimeText(answerCompletedAt!)}';
    final citationSaveText = _citationSaveStatusText(answer.citationIds.length);
    final retryCitationSaveText = _citationSaveStatusText(
      answer.citationIds.length,
      isRetry: true,
    );
    final citationContextLines = _reviewCitationContextLines(citedChunks);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionTitle(title: '来源约束回答'),
                  ),
                  KnowledgeAnswerReviewCopyButton(
                    record: evidenceRecord,
                    completedText: reviewCompletedText,
                    recordStatusText: reviewRecordStatus,
                    citationContextLines: citationContextLines,
                    tooltip: '复制即时回答复盘',
                    successMessage: '已复制即时回答复盘，包含证据状态',
                    iconSize: 18,
                    color: AppColors.textLight,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recordSaved) ...[
                _AnswerRecordStatus(
                  icon: Icons.check_circle,
                  color: AppColors.green,
                  text: recordSavedAt == null
                      ? knowledgeAnswerSavedRecordStatusText
                      : '$knowledgeAnswerSavedRecordStatusText · '
                          '${_dateTimeText(recordSavedAt!)}',
                ),
                if (recordAttemptStatusText != null) ...[
                  const SizedBox(height: 4),
                  _AnswerRecordStatus(
                    icon: Icons.history,
                    color: AppColors.textSecondary,
                    text: recordAttemptStatusText,
                  ),
                ],
                const SizedBox(height: 8),
              ] else if (isRecording) ...[
                const _AnswerRecordStatus(
                  icon: Icons.sync,
                  color: AppColors.blueDark,
                  text: knowledgeAnswerSavingRecordStatusText,
                ),
                if (recordAttemptStatusText != null) ...[
                  const SizedBox(height: 4),
                  _AnswerRecordStatus(
                    icon: Icons.history,
                    color: AppColors.textSecondary,
                    text: recordAttemptStatusText,
                  ),
                ],
                const SizedBox(height: 4),
                _AnswerRecordStatus(
                  icon: Icons.link,
                  color: AppColors.textSecondary,
                  text: citationSaveText,
                ),
                const SizedBox(height: 8),
              ] else if (recordError != null) ...[
                _AnswerRecordStatus(
                  icon: Icons.error_outline,
                  color: AppColors.red,
                  text: recordError!,
                  actionIcon: Icons.refresh,
                  actionTooltip: '重试保存到学习记录',
                  onAction: onRetryRecord,
                  secondaryActionIcon: Icons.copy,
                  secondaryActionTooltip: '复制保存失败诊断',
                  onSecondaryAction: () => _copyAnswerRecordErrorDiagnostic(
                    context,
                    question: question,
                    error: recordError!,
                    failedAt: recordFailedAt,
                    recordAttemptCount: recordAttemptCount,
                    answerAttemptStatusText: answerAttemptStatusText,
                    citationIds: answer.citationIds,
                    citedChunks: citedChunks,
                  ),
                ),
                if (recordFailedAt != null) ...[
                  const SizedBox(height: 4),
                  _AnswerRecordStatus(
                    icon: Icons.schedule,
                    color: AppColors.textSecondary,
                    text: '保存失败于 ${_dateTimeText(recordFailedAt!)}',
                  ),
                ],
                if (recordAttemptStatusText != null) ...[
                  const SizedBox(height: 4),
                  _AnswerRecordStatus(
                    icon: Icons.history,
                    color: AppColors.textSecondary,
                    text: recordAttemptStatusText,
                  ),
                ],
                const SizedBox(height: 4),
                _AnswerRecordStatus(
                  icon: Icons.link,
                  color: AppColors.textSecondary,
                  text: retryCitationSaveText,
                ),
                const SizedBox(height: 8),
              ],
              if (answerAttemptStatusText != null) ...[
                _AnswerRecordStatus(
                  icon: Icons.history,
                  color: AppColors.textSecondary,
                  text: answerAttemptStatusText,
                ),
                const SizedBox(height: 8),
              ],
              if (!recordSaved && answerCompletedText != null) ...[
                _AnswerRecordStatus(
                  icon: Icons.schedule,
                  color: AppColors.blueDark,
                  text: answerCompletedText,
                ),
                const SizedBox(height: 8),
              ],
              KnowledgeAnswerEvidenceQualityBadges(record: evidenceRecord),
              const SizedBox(height: 6),
              Text(
                knowledgeAnswerEvidenceQualityGuidance(evidenceRecord),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              if (answer.answer.trim().isNotEmpty)
                Text(
                  answer.answer,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (answer.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 10),
                _CompactList(title: '要点', items: answer.keyPoints),
              ],
              if (answer.sourceGaps.isNotEmpty) ...[
                const SizedBox(height: 10),
                _CompactList(
                  title: '来源缺口',
                  items: answer.sourceGaps,
                  onItemTap: onSourceGapSelected,
                  interactiveColor: AppColors.goldDark,
                ),
              ],
              if (answer.followUpQuestions.isNotEmpty) ...[
                const SizedBox(height: 10),
                _CompactList(
                  title: '继续追问',
                  items: answer.followUpQuestions,
                  onItemTap: onFollowUpSelected,
                ),
              ],
              if (citedChunks.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _SectionTitle(title: '引用依据'),
                const SizedBox(height: 8),
                _ChunkList(chunks: citedChunks),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerRecordStatus extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionTooltip;
  final VoidCallback? onSecondaryAction;

  const _AnswerRecordStatus({
    required this.icon,
    required this.color,
    required this.text,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
    this.secondaryActionIcon,
    this.secondaryActionTooltip,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        if (onAction != null && actionIcon != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: actionTooltip,
            icon: Icon(actionIcon, size: 18),
            color: color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: 30,
              height: 30,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onAction,
          ),
        ],
        if (onSecondaryAction != null && secondaryActionIcon != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: secondaryActionTooltip,
            icon: Icon(secondaryActionIcon, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: 30,
              height: 30,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onSecondaryAction,
          ),
        ],
      ],
    );
  }
}

class _CompactList extends StatelessWidget {
  final String title;
  final List<String> items;
  final ValueChanged<String>? onItemTap;
  final Color interactiveColor;

  const _CompactList({
    required this.title,
    required this.items,
    this.onItemTap,
    this.interactiveColor = AppColors.blueDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _CompactListItem(
              item: item,
              onTap: onItemTap == null ? null : () => onItemTap!(item),
              actionIcon: Icons.search,
              actionColor: interactiveColor,
            ),
          ),
      ],
    );
  }
}

class _CompactListItem extends StatelessWidget {
  final String item;
  final VoidCallback? onTap;
  final IconData actionIcon;
  final Color actionColor;

  const _CompactListItem({
    required this.item,
    this.onTap,
    required this.actionIcon,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '- $item',
      style: TextStyle(
        fontSize: 13,
        height: 1.35,
        fontWeight: onTap == null ? FontWeight.w400 : FontWeight.w700,
        color: onTap == null ? AppColors.textPrimary : actionColor,
      ),
    );
    if (onTap == null) return text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 6),
            Icon(
              actionIcon,
              size: 15,
              color: actionColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeSearchResultRow extends StatelessWidget {
  final KnowledgeSearchResult result;
  final VoidCallback onTap;

  const _KnowledgeSearchResultRow({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _LibraryRow(
      icon: _icon,
      color: _color,
      title: result.title,
      subtitle: _subtitle,
      footer: KnowledgeSearchRankingReasons(
        reasons: result.scoreBreakdown.reasonLabels,
      ),
      trailing: Icons.chevron_right,
      onTap: onTap,
    );
  }

  IconData get _icon {
    switch (result.type) {
      case KnowledgeSearchResultType.source:
        return Icons.source;
      case KnowledgeSearchResultType.sourceChunk:
        return Icons.notes;
      case KnowledgeSearchResultType.knowledgePoint:
        return Icons.psychology;
      case KnowledgeSearchResultType.question:
        return Icons.quiz;
    }
  }

  Color get _color {
    switch (result.type) {
      case KnowledgeSearchResultType.source:
        return AppColors.blue;
      case KnowledgeSearchResultType.sourceChunk:
        return AppColors.blueDark;
      case KnowledgeSearchResultType.knowledgePoint:
        return AppColors.green;
      case KnowledgeSearchResultType.question:
        return result.sourceStatus == null
            ? AppColors.gold
            : _sourceStatusColor(result.sourceStatus!);
    }
  }

  String get _subtitle {
    final parts = [
      result.type.label,
      if (result.trustLevel != null) result.trustLevel!.label,
      if (result.sourceStatus != null) result.sourceStatus!.label,
      if (result.snippet.isNotEmpty) result.snippet,
    ];
    return parts.join(' · ');
  }
}

class _SourcesTab extends ConsumerWidget {
  final AsyncValue<List<Source>> sourcesAsync;

  const _SourcesTab({required this.sourcesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return sourcesAsync.when(
      data: (sources) {
        if (sources.isEmpty) {
          return const _SourcesEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sources.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _LibraryRow(
                icon: Icons.add,
                color: AppColors.green,
                title: '导入新来源',
                subtitle: '补充官方文档、源码、课程或个人笔记',
                trailing: Icons.chevron_right,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const IngestionScreen(),
                    ),
                  );
                },
              );
            }
            final source = sources[index - 1];
            return _LibraryRow(
              icon: Icons.description,
              color: AppColors.blue,
              title: source.title,
              subtitle:
                  '${source.type.label} · ${source.trustLevel.label} · ${_dateText(source.createdAt)}',
              trailing:
                  source.uri == null || source.uri!.isEmpty ? null : Icons.link,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SourceDetailScreen(source: source),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => KnowledgeLibraryErrorState(
        title: '来源读取失败',
        retryLabel: '重试读取来源',
        diagnosticTitle: '知识库来源列表读取失败',
        diagnosticSuccessMessage: '已复制来源读取诊断',
        error: error,
        onRetry: () => ref.invalidate(sourceListProvider),
      ),
    );
  }
}

class _SourcesEmptyState extends StatelessWidget {
  const _SourcesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.source_outlined,
            color: AppColors.textLight,
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            '暂无来源',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IngestionScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('导入来源'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgePointsTab extends ConsumerWidget {
  final AsyncValue<List<KnowledgePoint>> pointsAsync;

  const _KnowledgePointsTab({required this.pointsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return pointsAsync.when(
      data: (points) {
        if (points.isEmpty) {
          return const _EmptyState(
            icon: Icons.psychology_outlined,
            title: '暂无知识点',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: points.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final point = points[index];
            return _KnowledgePointRow(
              point: point,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KnowledgePointDetailScreen(point: point),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => KnowledgeLibraryErrorState(
        title: '知识点读取失败',
        retryLabel: '重试读取知识点',
        diagnosticTitle: '知识库知识点列表读取失败',
        diagnosticSuccessMessage: '已复制知识点读取诊断',
        error: error,
        onRetry: () => ref.invalidate(knowledgePointListProvider),
      ),
    );
  }
}

class _QuestionsTab extends ConsumerStatefulWidget {
  final AsyncValue<List<Question>> questionsAsync;

  const _QuestionsTab({required this.questionsAsync});

  @override
  ConsumerState<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends ConsumerState<_QuestionsTab> {
  SourceStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return widget.questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const _EmptyState(
            icon: Icons.quiz_outlined,
            title: '暂无题目',
          );
        }

        final filteredQuestions = _selectedStatus == null
            ? questions
            : questions
                .where((question) => question.sourceStatus == _selectedStatus)
                .toList();

        return Column(
          children: [
            _QuestionStatusFilters(
              questions: questions,
              selectedStatus: _selectedStatus,
              onSelected: (status) {
                setState(() => _selectedStatus = status);
              },
            ),
            Expanded(
              child: filteredQuestions.isEmpty
                  ? _EmptyState(
                      icon: Icons.filter_alt_off,
                      title: '暂无${_selectedStatus?.label ?? ''}题目',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredQuestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final question = filteredQuestions[index];
                        return _LibraryRow(
                          icon: Icons.help_outline,
                          color: _sourceStatusColor(question.sourceStatus),
                          title: question.content,
                          subtitle:
                              '${question.type.label} · ${question.sourceStatus.label} · ${question.citationIds.length} 条引用',
                          trailing: Icons.chevron_right,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    QuestionEvidenceScreen(question: question),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => KnowledgeLibraryErrorState(
        title: '题目读取失败',
        retryLabel: '重试读取题目',
        diagnosticTitle: '知识库题目列表读取失败',
        diagnosticSuccessMessage: '已复制题目读取诊断',
        error: error,
        onRetry: () => ref.invalidate(allQuestionsProvider),
      ),
    );
  }
}

class _QuestionStatusFilters extends StatelessWidget {
  final List<Question> questions;
  final SourceStatus? selectedStatus;
  final ValueChanged<SourceStatus?> onSelected;

  const _QuestionStatusFilters({
    required this.questions,
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final status in SourceStatus.values)
        status: questions
            .where((question) => question.sourceStatus == status)
            .length,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuestionStatusChip(
              label: '全部',
              count: questions.length,
              color: AppColors.blue,
              selected: selectedStatus == null,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: 8),
            ...SourceStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _QuestionStatusChip(
                  label: status.label,
                  count: counts[status] ?? 0,
                  color: _sourceStatusColor(status),
                  selected: selectedStatus == status,
                  onTap: () => onSelected(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionStatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _QuestionStatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text('$label $count'),
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.14),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? color : AppColors.border, width: 1.5),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PendingQuestionsTab extends ConsumerStatefulWidget {
  final AsyncValue<List<Question>> questionsAsync;

  const _PendingQuestionsTab({required this.questionsAsync});

  @override
  ConsumerState<_PendingQuestionsTab> createState() =>
      _PendingQuestionsTabState();
}

class _PendingQuestionsTabState extends ConsumerState<_PendingQuestionsTab> {
  bool _isVerifying = false;

  Future<void> _verifyAll(List<Question> questions) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      final sourceChunkRepository = ref.read(sourceChunkRepositoryProvider);
      final plan =
          await const QuestionBulkVerificationService().buildPlanFromLoader(
        questions: questions,
        citationExists: (citationId) async =>
            await sourceChunkRepository.getSourceChunk(citationId) != null,
      );
      if (!mounted) return;
      if (!plan.hasUpdates) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('没有引用片段仍可读取的待核验题目'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('批量确认来源核验？'),
          content: Text(
            '将 ${plan.updates.length} 道引用片段仍可读取的题目标记为已核验。'
            '请确认你已经抽查题干、答案和解释；没有有效引用的题目会保持待核验。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('确认批量核验'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await ref
          .read(questionRepositoryProvider)
          .updateQuestions(plan.updatedQuestions);
      ref.invalidate(pendingQuestionListProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(verifiedQuestionsProvider);
      ref.invalidate(knowledgeSearchCorpusProvider);
      ref.invalidate(practiceableKnowledgePointListProvider);
      ref.invalidate(todayReviewQueueProvider);
      ref.invalidate(learningAgentPlanProvider);
      for (final update in plan.updates) {
        final previousQuestion = questions[update.index];
        ref.invalidate(
          questionCitationChunksProvider(
            previousQuestion.citationIds.join('\x00'),
          ),
        );
        ref.invalidate(
          questionCitationChunksProvider(
            update.question.citationIds.join('\x00'),
          ),
        );
        ref.invalidate(deckQuestionsProvider(update.question.deckId));
        ref.invalidate(verifiedDeckQuestionsProvider(update.question.deckId));
        final pointId = update.question.knowledgePointId;
        if (pointId != null) {
          ref.invalidate(knowledgePointQuestionsProvider(pointId));
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan.skippedPendingCount == 0
                ? '已批量核验 ${plan.updates.length} 道题'
                : '已批量核验 ${plan.updates.length} 道题，'
                    '${plan.skippedPendingCount} 道仍需单独处理',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('批量核验失败: $error'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const _EmptyState(
            icon: Icons.verified_outlined,
            title: '暂无待核验内容',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: questions.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return OutlinedButton.icon(
                key: const ValueKey('bulk_verify_pending_questions'),
                onPressed: _isVerifying ? null : () => _verifyAll(questions),
                icon: _isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: Text(
                  _isVerifying ? '正在检查引用...' : '批量核验有效引用',
                ),
              );
            }
            final question = questions[index - 1];
            return _LibraryRow(
              icon: Icons.help_outline,
              color: AppColors.streakOrange,
              title: question.content,
              subtitle:
                  '${question.type.label} · ${question.citationIds.length} 条引用',
              trailing: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuestionEvidenceScreen(question: question),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => KnowledgeLibraryErrorState(
        title: '待核验内容读取失败',
        retryLabel: '重试读取待核验',
        diagnosticTitle: '知识库待核验列表读取失败',
        diagnosticSuccessMessage: '已复制待核验读取诊断',
        error: error,
        onRetry: () => ref.invalidate(pendingQuestionListProvider),
      ),
    );
  }
}

Color _sourceStatusColor(SourceStatus status) {
  switch (status) {
    case SourceStatus.verified:
      return AppColors.green;
    case SourceStatus.pending:
      return AppColors.streakOrange;
    case SourceStatus.noSource:
      return AppColors.red;
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
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
          ],
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? footer;
  final IconData? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  const _LibraryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.footer,
    this.trailing,
    this.trailingWidget,
    this.onTap,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: footer!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget!,
              ] else if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: AppColors.textLight, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgePointRow extends StatelessWidget {
  final KnowledgePoint point;
  final VoidCallback onTap;

  const _KnowledgePointRow({
    required this.point,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = point.masteryLevel.clamp(0, 100) / 100;
    final tagText = [
      point.kind.label,
      ...point.tags.take(2),
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const SizedBox(width: 8),
                  Text(
                    '${point.masteryLevel}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                point.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress.toDouble(),
                  color: AppColors.green,
                  backgroundColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$tagText · 难度 ${point.difficulty} · 面试相关 ${point.interviewRelevance}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceDetailScreen extends ConsumerWidget {
  final Source source;
  final String? highlightedChunkId;
  final String highlightedChunkLabel;
  final IconData highlightedChunkIcon;

  const SourceDetailScreen({
    super.key,
    required this.source,
    this.highlightedChunkId,
    this.highlightedChunkLabel = '检索命中片段',
    this.highlightedChunkIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chunksAsync = ref.watch(sourceChunksProvider(source.id));
    final pointsAsync = ref.watch(sourceKnowledgePointsProvider(source.id));

    return Scaffold(
      appBar: AppBar(title: const Text('来源详情')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetailHeader(
              icon: Icons.source,
              color: AppColors.blue,
              title: source.title,
              subtitle:
                  '${source.type.label} · ${source.trustLevel.label} · ${_dateText(source.createdAt)}',
            ),
            if (source.uri != null && source.uri!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SourceUriBlock(uri: source.uri!),
            ],
            if (_hasSourceProvenance(source)) ...[
              const SizedBox(height: 10),
              _SourceProvenanceBlock(source: source),
            ],
            const SizedBox(height: 14),
            chunksAsync.when(
              data: (chunks) => _ChunkList(
                chunks: chunks,
                showSourceLink: false,
                highlightedChunkId: highlightedChunkId,
                highlightedChunkLabel: highlightedChunkLabel,
                highlightedChunkIcon: highlightedChunkIcon,
              ),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '来源片段读取失败',
                retryLabel: '重试读取片段',
                diagnosticTitle: '来源详情片段读取失败',
                diagnosticSuccessMessage: '已复制来源片段读取诊断',
                diagnosticLines: [
                  '来源: ${source.title}',
                  '来源 ID: ${source.id}',
                ],
                error: error,
                onRetry: () => ref.invalidate(sourceChunksProvider(source.id)),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: '关联知识点'),
            const SizedBox(height: 10),
            pointsAsync.when(
              data: (points) => _SourceKnowledgePointList(points: points),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '关联知识点读取失败',
                retryLabel: '重试读取关联知识点',
                diagnosticTitle: '来源详情关联知识点读取失败',
                diagnosticSuccessMessage: '已复制关联知识点读取诊断',
                diagnosticLines: [
                  '来源: ${source.title}',
                  '来源 ID: ${source.id}',
                ],
                error: error,
                onRetry: () => ref.invalidate(
                  sourceKnowledgePointsProvider(source.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceKnowledgePointList extends StatelessWidget {
  final List<KnowledgePoint> points;

  const _SourceKnowledgePointList({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyState(
        icon: Icons.psychology_outlined,
        title: '暂无关联知识点',
      );
    }

    return Column(
      children: points.map((point) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _KnowledgePointRow(
            point: point,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KnowledgePointDetailScreen(point: point),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _SourceUriBlock extends StatelessWidget {
  final String uri;

  const _SourceUriBlock({required this.uri});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.link, color: AppColors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              uri,
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
    );
  }
}

bool _hasSourceProvenance(Source source) {
  return (source.publisher != null && source.publisher!.isNotEmpty) ||
      (source.revision != null && source.revision!.isNotEmpty) ||
      (source.licenseExpression != null &&
          source.licenseExpression!.isNotEmpty) ||
      source.retrievedAt != null ||
      source.contentHash.isNotEmpty;
}

class _SourceProvenanceBlock extends StatelessWidget {
  final Source source;

  const _SourceProvenanceBlock({required this.source});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (source.publisher != null && source.publisher!.isNotEmpty)
        ('发布者', source.publisher!),
      if (source.revision != null && source.revision!.isNotEmpty)
        ('版本 / revision', source.revision!),
      (
        '许可',
        source.licenseExpression == null || source.licenseExpression!.isEmpty
            ? '未知'
            : source.licenseExpression!,
      ),
      if (source.retrievedAt != null)
        ('获取时间', source.retrievedAt!.toIso8601String()),
      if (source.contentHash.isNotEmpty) ('SHA-256', source.contentHash),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  color: AppColors.greenDark, size: 18),
              SizedBox(width: 8),
              Text(
                '来源档案',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
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

class KnowledgePointDetailScreen extends ConsumerWidget {
  final KnowledgePoint point;

  const KnowledgePointDetailScreen({
    super.key,
    required this.point,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chunksAsync =
        ref.watch(knowledgePointEvidenceChunksProvider(point.id));
    final questionsAsync = ref.watch(knowledgePointQuestionsProvider(point.id));
    final memoryAsync = ref.watch(learningTargetMemoryProvider(point.id));
    final pointDiagnosticLines = [
      '知识点: ${point.title}',
      '知识点 ID: ${point.id}',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('知识点详情')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetailHeader(
              icon: Icons.psychology,
              color: AppColors.green,
              title: point.title,
              subtitle:
                  '${point.kind.label} · 掌握度 ${point.masteryLevel}% · 难度 ${point.difficulty} · 面试相关 ${point.interviewRelevance}',
            ),
            const SizedBox(height: 12),
            Text(
              point.summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            chunksAsync.when(
              data: (chunks) => questionsAsync.when(
                data: (questions) => _KnowledgePointLearningActions(
                  point: point,
                  questions: questions,
                  evidenceChunks: chunks,
                ),
                loading: () => const _LoadingBlock(),
                error: (error, _) => KnowledgeLibraryErrorState(
                  title: '学习动作题目读取失败',
                  retryLabel: '重试读取相关题目',
                  diagnosticTitle: '知识点学习动作题目读取失败',
                  diagnosticSuccessMessage: '已复制学习动作读取诊断',
                  diagnosticLines: pointDiagnosticLines,
                  error: error,
                  onRetry: () => ref.invalidate(
                    knowledgePointQuestionsProvider(point.id),
                  ),
                ),
              ),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '学习动作证据读取失败',
                retryLabel: '重试读取证据',
                diagnosticTitle: '知识点学习动作证据读取失败',
                diagnosticSuccessMessage: '已复制学习动作读取诊断',
                diagnosticLines: pointDiagnosticLines,
                error: error,
                onRetry: () => ref.invalidate(
                  knowledgePointEvidenceChunksProvider(point.id),
                ),
              ),
            ),
            const SizedBox(height: 18),
            memoryAsync.when(
              data: (memory) => LearningTargetMemoryTimeline(snapshot: memory),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '连续学习历史读取失败',
                retryLabel: '重试读取学习历史',
                diagnosticTitle: '知识点连续学习历史读取失败',
                diagnosticSuccessMessage: '已复制连续学习历史诊断',
                diagnosticLines: pointDiagnosticLines,
                error: error,
                onRetry: () => ref.invalidate(
                  learningTargetMemoryProvider(point.id),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: '证据片段'),
            const SizedBox(height: 10),
            chunksAsync.when(
              data: (chunks) => _ChunkList(chunks: chunks),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '证据片段读取失败',
                retryLabel: '重试读取证据片段',
                diagnosticTitle: '知识点证据片段读取失败',
                diagnosticSuccessMessage: '已复制证据片段读取诊断',
                diagnosticLines: pointDiagnosticLines,
                error: error,
                onRetry: () => ref.invalidate(
                  knowledgePointEvidenceChunksProvider(point.id),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: '相关题目'),
            const SizedBox(height: 10),
            questionsAsync.when(
              data: (questions) => _RelatedQuestionList(questions: questions),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '相关题目读取失败',
                retryLabel: '重试读取相关题目',
                diagnosticTitle: '知识点相关题目读取失败',
                diagnosticSuccessMessage: '已复制相关题目读取诊断',
                diagnosticLines: pointDiagnosticLines,
                error: error,
                onRetry: () => ref.invalidate(
                  knowledgePointQuestionsProvider(point.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgePointLearningActions extends ConsumerWidget {
  final KnowledgePoint point;
  final List<Question> questions;
  final List<SourceChunk> evidenceChunks;

  const _KnowledgePointLearningActions({
    required this.point,
    required this.questions,
    required this.evidenceChunks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifiedQuestions = questions
        .where((question) => question.sourceStatus == SourceStatus.verified)
        .toList();
    final canExplain = evidenceChunks.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '学习动作'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canExplain
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TutorSessionScreen(
                                initialPoint: point,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.school),
                  label: Text(
                    canExplain ? '导师讲解' : '无来源讲解',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textLight,
                    disabledBackgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: verifiedQuestions.isEmpty
                      ? null
                      : () => _startPractice(
                            context,
                            ref,
                            verifiedQuestions,
                          ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    verifiedQuestions.isEmpty
                        ? '无已核验题'
                        : '练习 ${verifiedQuestions.length}',
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startPractice(
    BuildContext context,
    WidgetRef ref,
    List<Question> verifiedQuestions,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(questions: verifiedQuestions),
      ),
    );
    if (!context.mounted) return;
    ref.invalidate(todayReviewQueueProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    ref.invalidate(knowledgePointListProvider);
    ref.invalidate(evidenceBackedKnowledgePointListProvider);
    ref.invalidate(practiceableKnowledgePointListProvider);
    ref.invalidate(knowledgePointProvider(point.id));
    ref.invalidate(knowledgePointQuestionsProvider(point.id));
  }
}

class _RelatedQuestionList extends StatelessWidget {
  final List<Question> questions;

  const _RelatedQuestionList({required this.questions});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const _EmptyState(
        icon: Icons.quiz_outlined,
        title: '暂无相关题目',
      );
    }

    return Column(
      children: questions.map((question) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LibraryRow(
            icon: Icons.help_outline,
            color: _sourceStatusColor(question.sourceStatus),
            title: question.content,
            subtitle:
                '${question.type.label} · ${question.sourceStatus.label} · ${question.citationIds.length} 条引用',
            trailing: Icons.chevron_right,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestionEvidenceScreen(question: question),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class QuestionEvidenceScreen extends ConsumerStatefulWidget {
  final Question question;

  const QuestionEvidenceScreen({
    super.key,
    required this.question,
  });

  @override
  ConsumerState<QuestionEvidenceScreen> createState() =>
      _QuestionEvidenceScreenState();
}

class _QuestionEvidenceScreenState
    extends ConsumerState<QuestionEvidenceScreen> {
  late Question _question;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _question = widget.question;
  }

  Future<void> _setStatus(
    SourceStatus status,
    List<SourceChunk> citationChunks,
  ) async {
    if (_isSaving) return;
    if (status == SourceStatus.verified && citationChunks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有引用片段，不能标记为已核验'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final previousCitationKey = _question.citationIds.join('\x00');
      final validCitationIds = status == SourceStatus.noSource
          ? <String>[]
          : citationChunks.map((chunk) => chunk.id).toSet().toList();
      final updated = _question.copyWith(
        sourceStatus: validCitationIds.isEmpty ? SourceStatus.noSource : status,
        citationIds: validCitationIds,
      );
      await ref.read(questionRepositoryProvider).updateQuestion(updated);
      ref.invalidate(pendingQuestionListProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(verifiedQuestionsProvider);
      ref.invalidate(knowledgeSearchCorpusProvider);
      ref.invalidate(practiceableKnowledgePointListProvider);
      ref.invalidate(todayReviewQueueProvider);
      ref.invalidate(questionCitationChunksProvider(previousCitationKey));
      ref.invalidate(
        questionCitationChunksProvider(updated.citationIds.join('\x00')),
      );
      ref.invalidate(deckQuestionsProvider(updated.deckId));
      ref.invalidate(verifiedDeckQuestionsProvider(updated.deckId));
      if (updated.knowledgePointId != null) {
        ref.invalidate(
            knowledgePointQuestionsProvider(updated.knowledgePointId!));
      }

      if (!mounted) return;
      setState(() {
        _question = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已标记为${updated.sourceStatus.label}'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final citationKey = _question.citationIds.join('\x00');
    final chunksAsync = ref.watch(questionCitationChunksProvider(citationKey));
    final pointId = _question.knowledgePointId;
    final pointAsync =
        pointId == null ? null : ref.watch(knowledgePointProvider(pointId));
    final citationIdText =
        _question.citationIds.isEmpty ? '无' : _question.citationIds.join(', ');
    final questionDiagnosticLines = [
      '题目: ${_question.content}',
      '题目 ID: ${_question.id}',
      '题包 ID: ${_question.deckId}',
      '引用数量: ${_question.citationIds.length}',
      '引用 ID: $citationIdText',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('题目证据')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetailHeader(
              icon: Icons.help_outline,
              color: AppColors.streakOrange,
              title: _question.content,
              subtitle:
                  '${_question.type.label} · ${_question.sourceStatus.label}',
            ),
            if (pointId != null && pointAsync != null) ...[
              const SizedBox(height: 12),
              pointAsync.when(
                data: (point) => _QuestionKnowledgePointBlock(point: point),
                loading: () => const _LoadingBlock(),
                error: (error, _) => KnowledgeLibraryErrorState(
                  title: '关联知识点读取失败',
                  retryLabel: '重试读取关联知识点',
                  diagnosticTitle: '题目证据关联知识点读取失败',
                  diagnosticSuccessMessage: '已复制题目知识点读取诊断',
                  diagnosticLines: [
                    ...questionDiagnosticLines,
                    '知识点 ID: $pointId',
                  ],
                  error: error,
                  onRetry: () =>
                      ref.invalidate(knowledgePointProvider(pointId)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _AnswerBlock(question: _question),
            const SizedBox(height: 18),
            const _SectionTitle(title: '引用片段'),
            const SizedBox(height: 10),
            chunksAsync.when(
              data: (chunks) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChunkList(chunks: chunks),
                  const SizedBox(height: 14),
                  _VerificationActions(
                    question: _question,
                    citationChunks: chunks,
                    isSaving: _isSaving,
                    onStatusSelected: (status) => _setStatus(status, chunks),
                  ),
                ],
              ),
              loading: () => const _LoadingBlock(),
              error: (error, _) => KnowledgeLibraryErrorState(
                title: '引用片段读取失败',
                retryLabel: '重试读取引用片段',
                diagnosticTitle: '题目证据引用片段读取失败',
                diagnosticSuccessMessage: '已复制题目引用读取诊断',
                diagnosticLines: questionDiagnosticLines,
                error: error,
                onRetry: () => ref.invalidate(
                  questionCitationChunksProvider(citationKey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionKnowledgePointBlock extends StatelessWidget {
  final KnowledgePoint? point;

  const _QuestionKnowledgePointBlock({required this.point});

  @override
  Widget build(BuildContext context) {
    final point = this.point;
    if (point == null) {
      return const _EmptyBlock(
        icon: Icons.psychology_outlined,
        title: '关联知识点已缺失',
      );
    }

    return _LibraryRow(
      icon: Icons.psychology,
      color: AppColors.green,
      title: point.title,
      subtitle:
          '掌握度 ${point.masteryLevel}% · 难度 ${point.difficulty} · 面试相关 ${point.interviewRelevance}',
      trailing: Icons.chevron_right,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KnowledgePointDetailScreen(point: point),
          ),
        );
      },
    );
  }
}

class _VerificationActions extends StatelessWidget {
  final Question question;
  final List<SourceChunk> citationChunks;
  final bool isSaving;
  final ValueChanged<SourceStatus> onStatusSelected;

  const _VerificationActions({
    required this.question,
    required this.citationChunks,
    required this.isSaving,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '核验状态'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: '已核验',
                  icon: Icons.verified,
                  color: AppColors.green,
                  selected: question.sourceStatus == SourceStatus.verified,
                  enabled: !isSaving && citationChunks.isNotEmpty,
                  onTap: () => onStatusSelected(SourceStatus.verified),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: '待核验',
                  icon: Icons.pending_actions,
                  color: AppColors.blue,
                  selected: question.sourceStatus == SourceStatus.pending,
                  enabled: !isSaving,
                  onTap: () => onStatusSelected(SourceStatus.pending),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _StatusButton(
              label: '无来源',
              icon: Icons.link_off,
              color: AppColors.red,
              selected: question.sourceStatus == SourceStatus.noSource,
              enabled: !isSaving,
              onTap: () => onStatusSelected(SourceStatus.noSource),
            ),
          ),
          if (citationChunks.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '没有引用片段时不能标记为已核验。',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: selected ? color.withValues(alpha: 0.1) : Colors.white,
        side:
            BorderSide(color: selected ? color : AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _DetailHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _ChunkList extends StatelessWidget {
  final List<SourceChunk> chunks;
  final bool showSourceLink;
  final String? highlightedChunkId;
  final String highlightedChunkLabel;
  final IconData highlightedChunkIcon;

  const _ChunkList({
    required this.chunks,
    this.showSourceLink = true,
    this.highlightedChunkId,
    this.highlightedChunkLabel = '检索命中片段',
    this.highlightedChunkIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    if (chunks.isEmpty) {
      return const _EmptyBlock(
        icon: Icons.article_outlined,
        title: '暂无片段',
      );
    }

    final visibleChunks = _highlightedFirst(chunks);

    return Column(
      children: [
        for (var i = 0; i < visibleChunks.length; i++) ...[
          _ChunkCard(
            chunk: visibleChunks[i],
            showSourceLink: showSourceLink,
            isHighlighted: visibleChunks[i].id == highlightedChunkId,
            highlightedLabel: highlightedChunkLabel,
            highlightedIcon: highlightedChunkIcon,
          ),
          if (i < visibleChunks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<SourceChunk> _highlightedFirst(List<SourceChunk> chunks) {
    final highlightedId = highlightedChunkId;
    if (highlightedId == null || highlightedId.isEmpty) return chunks;

    final highlighted = <SourceChunk>[];
    final rest = <SourceChunk>[];
    for (final chunk in chunks) {
      if (chunk.id == highlightedId) {
        highlighted.add(chunk);
      } else {
        rest.add(chunk);
      }
    }
    return highlighted.isEmpty ? chunks : [...highlighted, ...rest];
  }
}

class _ChunkCard extends ConsumerWidget {
  final SourceChunk chunk;
  final bool showSourceLink;
  final bool isHighlighted;
  final String highlightedLabel;
  final IconData highlightedIcon;

  const _ChunkCard({
    required this.chunk,
    required this.showSourceLink,
    this.isHighlighted = false,
    this.highlightedLabel = '检索命中片段',
    this.highlightedIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locator = chunk.locator == null || chunk.locator!.isEmpty
        ? '片段 ${chunk.chunkIndex + 1}'
        : chunk.locator!;
    final sourceAsync =
        showSourceLink ? ref.watch(sourceProvider(chunk.sourceId)) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.gold.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? AppColors.gold : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted) ...[
            _HighlightedChunkLabel(
              icon: highlightedIcon,
              text: highlightedLabel,
            ),
            const SizedBox(height: 8),
          ],
          if (sourceAsync != null) ...[
            sourceAsync.when(
              data: (source) => source == null
                  ? _ChunkSourceLine(
                      label: '来源已缺失',
                      icon: Icons.link_off,
                      color: AppColors.red,
                      trailingActions: [
                        IconButton(
                          tooltip: '重试读取来源',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.refresh, size: 16),
                          color: AppColors.red,
                          onPressed: () => ref.invalidate(
                            sourceProvider(chunk.sourceId),
                          ),
                        ),
                        IconButton(
                          tooltip: '复制缺失来源诊断',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.copy, size: 16),
                          color: AppColors.red,
                          onPressed: () => _copyMissingChunkSourceDiagnostic(
                            context,
                            chunk: chunk,
                            locator: locator,
                          ),
                        ),
                      ],
                    )
                  : _ChunkSourceLine(
                      label: source.title,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SourceDetailScreen(
                              source: source,
                              highlightedChunkId: chunk.id,
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const _ChunkSourceLine(label: '正在读取来源...'),
              error: (error, _) => _ChunkSourceLine(
                label: '来源读取失败',
                icon: Icons.error_outline,
                color: AppColors.red,
                trailingActions: [
                  IconButton(
                    tooltip: '重试读取来源',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.refresh, size: 16),
                    color: AppColors.red,
                    onPressed: () => ref.invalidate(
                      sourceProvider(chunk.sourceId),
                    ),
                  ),
                  IconButton(
                    tooltip: '复制来源读取诊断',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.copy, size: 16),
                    color: AppColors.red,
                    onPressed: () => _copyChunkSourceErrorDiagnostic(
                      context,
                      chunk: chunk,
                      locator: locator,
                      error: error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(Icons.place, size: 16, color: AppColors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locator,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            chunk.content,
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

class _HighlightedChunkLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightedChunkLabel({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.goldDark),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.goldDark,
          ),
        ),
      ],
    );
  }
}

class _ChunkSourceLine extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final List<Widget> trailingActions;

  const _ChunkSourceLine({
    required this.label,
    this.onTap,
    this.icon = Icons.source,
    this.color = AppColors.green,
    this.trailingActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ).copyWith(color: color),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: color),
          ],
          ...trailingActions,
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  final Question question;

  const _AnswerBlock({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '答案'),
          const SizedBox(height: 8),
          Text(
            question.answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionTitle(title: '解析'),
            const SizedBox(height: 8),
            Text(
              question.explanation!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyBlock({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textLight, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.green),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textLight, size: 48),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _dateText(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _dateTimeText(DateTime value) {
  return '${_dateText(value)} ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _answerRecordFailureStatusText(String error, DateTime? failedAt) {
  if (failedAt == null) return error;
  return '$error · 保存失败于 ${_dateTimeText(failedAt)}';
}

String? _answerGenerationAttemptStatusText(
  int attemptCount, {
  required bool hasAnswer,
  required bool hasError,
}) {
  if (attemptCount <= 1) return null;
  if (hasAnswer) return '第 $attemptCount 次生成成功';
  if (hasError) return '已尝试生成 $attemptCount 次';
  return null;
}

String? _answerRecordAttemptStatusText(
  int attemptCount, {
  required bool recordSaved,
  required bool isRecording,
  required bool hasError,
}) {
  if (attemptCount <= 1) return null;
  if (recordSaved) return '第 $attemptCount 次保存尝试成功';
  if (isRecording) return '第 $attemptCount 次保存尝试中';
  if (hasError) return '已尝试保存 $attemptCount 次';
  return null;
}

String _withAnswerRecordAttemptStatus(
  String statusText,
  int attemptCount, {
  bool success = false,
  bool inProgress = false,
}) {
  if (attemptCount <= 1) return statusText;
  if (success) return '$statusText · 第 $attemptCount 次保存尝试成功';
  if (inProgress) return '$statusText · 第 $attemptCount 次保存尝试';
  return '$statusText · 已尝试保存 $attemptCount 次';
}

String _withAnswerGenerationAttemptStatus(
  String statusText,
  String? attemptStatusText,
) {
  if (attemptStatusText == null) return statusText;
  return '$statusText · $attemptStatusText';
}

String _answerGenerationRetryContextText(int sourceChunkCount) {
  if (sourceChunkCount == 0) return '没有可用于重试的来源片段';
  return '重试会复用 $sourceChunkCount 条来源片段';
}

Future<void> _copyAnswerGenerationErrorDiagnostic(
  BuildContext context, {
  required String question,
  required String error,
  required DateTime? failedAt,
  required int attemptCount,
  required List<SourceChunk> sourceChunks,
}) async {
  final questionText = question.trim().isEmpty ? '未记录问题' : question.trim();
  final errorText = error.trim().isEmpty ? '未记录错误' : error.trim();
  final failedText = failedAt == null ? '未记录失败时间' : _dateTimeText(failedAt);
  final attemptText = attemptCount <= 0 ? '未记录尝试次数' : '$attemptCount 次';
  final sourceContextLines = _reviewCitationContextLines(sourceChunks);
  final text = [
    '# 知识库即时回答生成失败',
    '',
    '问题: $questionText',
    '错误: $errorText',
    '失败时间: $failedText',
    '生成尝试: $attemptText',
    '来源片段: ${sourceChunks.length} 条',
    '来源片段摘要:',
    if (sourceContextLines.isEmpty)
      '- 未缓存来源片段'
    else
      for (final line in sourceContextLines) '- $line',
  ].join('\n');
  await Clipboard.setData(
    ClipboardData(text: const PrivacyRedactor().redactDiagnostic(text)),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制生成失败诊断')),
  );
}

Future<void> _copyAnswerContextErrorDiagnostic(
  BuildContext context, {
  required String query,
  required Object error,
}) async {
  final queryText = query.trim().isEmpty ? '未记录查询' : query.trim();
  final errorText =
      error.toString().trim().isEmpty ? '未记录错误' : error.toString().trim();
  final copiedAtText = _dateTimeText(DateTime.now());
  final text = [
    '# 知识库回答上下文读取失败',
    '',
    '查询: $queryText',
    '错误: $errorText',
    '复制时间: $copiedAtText',
  ].join('\n');
  await Clipboard.setData(
    ClipboardData(text: const PrivacyRedactor().redactDiagnostic(text)),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制上下文读取诊断')),
  );
}

Future<void> _copyAnswerNoContextDiagnostic(
  BuildContext context, {
  required String query,
}) async {
  final queryText = query.trim().isEmpty ? '未记录查询' : query.trim();
  final copiedAtText = _dateTimeText(DateTime.now());
  final text = [
    '# 知识库回答无可引用片段',
    '',
    '查询: $queryText',
    '状态: 已成功读取回答上下文，但没有命中可引用来源片段',
    '可引用片段: 0 条',
    '复制时间: $copiedAtText',
  ].join('\n');
  await Clipboard.setData(
    ClipboardData(text: const PrivacyRedactor().redactDiagnostic(text)),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制无引用诊断')),
  );
}

Future<void> _copyChunkSourceErrorDiagnostic(
  BuildContext context, {
  required SourceChunk chunk,
  required String locator,
  required Object error,
}) async {
  final errorText =
      error.toString().trim().isEmpty ? '未记录错误' : error.toString().trim();
  final copiedAtText = _dateTimeText(DateTime.now());
  final text = [
    '# 来源片段来源读取失败',
    '',
    '来源 ID: ${chunk.sourceId}',
    '片段 ID: ${chunk.id}',
    '片段位置: $locator',
    '错误: $errorText',
    '复制时间: $copiedAtText',
  ].join('\n');
  await Clipboard.setData(
    ClipboardData(text: const PrivacyRedactor().redactDiagnostic(text)),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制来源读取诊断')),
  );
}

Future<void> _copyMissingChunkSourceDiagnostic(
  BuildContext context, {
  required SourceChunk chunk,
  required String locator,
}) async {
  final copiedAtText = _dateTimeText(DateTime.now());
  final text = [
    '# 来源片段缺失来源记录',
    '',
    '来源 ID: ${chunk.sourceId}',
    '片段 ID: ${chunk.id}',
    '片段位置: $locator',
    '状态: 已读取片段，但没有找到对应来源记录',
    '复制时间: $copiedAtText',
  ].join('\n');
  await Clipboard.setData(
    ClipboardData(text: const PrivacyRedactor().redactDiagnostic(text)),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制缺失来源诊断')),
  );
}

Future<void> _copyAnswerRecordErrorDiagnostic(
  BuildContext context, {
  required String question,
  required String error,
  required DateTime? failedAt,
  required int recordAttemptCount,
  required String? answerAttemptStatusText,
  required List<String> citationIds,
  required List<SourceChunk> citedChunks,
}) async {
  final questionText = question.trim().isEmpty ? '未记录问题' : question.trim();
  final errorText = error.trim().isEmpty ? '未记录错误' : error.trim();
  final failedText = failedAt == null ? '未记录失败时间' : _dateTimeText(failedAt);
  final recordAttemptText =
      recordAttemptCount <= 0 ? '未记录保存尝试次数' : '$recordAttemptCount 次';
  final answerAttemptText = answerAttemptStatusText ?? '首次生成成功';
  final citationContextLines = _reviewCitationContextLines(citedChunks);
  final text = [
    '# 知识库即时回答保存失败',
    '',
    '问题: $questionText',
    '错误: $errorText',
    '失败时间: $failedText',
    '保存尝试: $recordAttemptText',
    '生成状态: $answerAttemptText',
    '引用 id:',
    if (citationIds.isEmpty)
      '- 未保存引用 id'
    else
      for (final citationId in citationIds) '- $citationId',
    '引用片段摘要:',
    if (citationContextLines.isEmpty)
      '- 未缓存引用片段摘要'
    else
      for (final line in citationContextLines) '- $line',
  ].join('\n');
  await Clipboard.setData(
    ClipboardData(text: const PrivacyRedactor().redactDiagnostic(text)),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制保存失败诊断')),
  );
}

String _citationSaveStatusText(int citationIdCount, {bool isRetry = false}) {
  if (citationIdCount == 0) {
    return isRetry ? '重试会保存回答，但没有可保存引用 id' : '本次回答没有可保存引用 id';
  }
  return isRetry
      ? '重试会保存 $citationIdCount 条引用 id'
      : '将保存 $citationIdCount 条引用 id';
}

List<String> _reviewCitationContextLines(List<SourceChunk> chunks) {
  final extraCount = chunks.length - 5;
  return [
    for (final chunk in chunks.take(5))
      buildKnowledgeAnswerCitationContextLine(
        chunkId: chunk.id,
        sourceText: 'source ${chunk.sourceId}',
        locatorText: knowledgeAnswerCitationLocatorText(
          chunkIndex: chunk.chunkIndex,
          locator: chunk.locator,
        ),
        content: chunk.content,
      ),
    if (extraCount > 0) knowledgeAnswerCitationOverflowLine(extraCount),
  ];
}
