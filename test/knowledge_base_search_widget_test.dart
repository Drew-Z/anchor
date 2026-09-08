import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/grounded_learning_context.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_base_screen.dart';
import 'package:anchor_learning/services/agent/hybrid_knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/knowledge_answer_session_summary.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/search_preferences.dart';
import 'package:anchor_learning/services/ai/ai_task_result.dart';
import 'package:anchor_learning/services/ai/tasks/knowledge_answer_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debounces input and commits only the latest query',
      (tester) async {
    await _pumpSearch(tester);

    final input = find.byKey(const ValueKey('knowledge-search-input'));
    await tester.enterText(input, 'old');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(input, 'new');
    await tester.pump(const Duration(milliseconds: 99));

    expect(
      find.byKey(const ValueKey('knowledge-search-debounce-progress')),
      findsOneWidget,
    );
    expect(find.text('Old result'), findsNothing);
    expect(find.text('New result'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
    expect(
      find.byKey(const ValueKey('knowledge-search-debounce-progress')),
      findsNothing,
    );
  });

  testWidgets('a slower old query cannot replace the current query results',
      (tester) async {
    final oldResults = Completer<List<KnowledgeSearchResult>>();
    await _pumpSearch(tester, oldResults: oldResults);
    final input = find.byKey(const ValueKey('knowledge-search-input'));

    await tester.enterText(input, 'old');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.enterText(input, 'new');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('New result'), findsOneWidget);
    oldResults.complete([_result('Old result')]);
    await tester.pump();
    await tester.pump();

    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
  });

  testWidgets('clearing search returns to history without a delayed commit',
      (tester) async {
    await _pumpSearch(tester);
    final input = find.byKey(const ValueKey('knowledge-search-input'));

    await tester.enterText(input, 'new');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('New result'), findsOneWidget);

    await tester.tap(find.byTooltip('清空'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('New result'), findsNothing);
    expect(find.text('输入关键词检索知识库'), findsOneWidget);
  });

  testWidgets('shows augmented and fallback search status', (tester) async {
    await _pumpSearch(
      tester,
      initialQuery: 'augmented',
    );
    expect(
      find.byKey(const ValueKey('knowledge-search-augmented-chip')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('knowledge-search-input')),
      'fallback',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('knowledge-search-fallback-chip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('knowledge-search-augmented-chip')),
      findsNothing,
    );
  });

  testWidgets('rewrite-only source hits enable the grounded answer action',
      (tester) async {
    final now = DateTime.utc(2026, 9, 8);
    final corpus = KnowledgeSearchCorpus(
      sources: [
        Source(
          id: 'docs',
          title: 'Engineering references',
          type: SourceType.officialDoc,
          trustLevel: SourceTrustLevel.officialDoc,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sourceChunks: [
        SourceChunk(
          id: 'checkpoint',
          sourceId: 'docs',
          chunkIndex: 0,
          content: 'A checkpoint captures consistent application state.',
          locator: 'Checkpointing',
          createdAt: now,
        ),
      ],
      knowledgePoints: const [],
      questions: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sourceListProvider.overrideWith((ref) async => corpus.sources),
          knowledgePointListProvider.overrideWith((ref) async => []),
          allQuestionsProvider.overrideWith((ref) async => []),
          pendingQuestionListProvider.overrideWith((ref) async => []),
          knowledgeAnswerSessionListProvider.overrideWith((ref) async => []),
          knowledgeSearchCorpusProvider.overrideWith((ref) async => corpus),
          searchPreferencesStoreProvider
              .overrideWithValue(_EnabledSearchPreferencesStore()),
          modelSearchQueryVariantProvider
              .overrideWithValue(_CheckpointVariantProvider()),
        ],
        child: const MaterialApp(
          home: KnowledgeBaseScreen(
            initialSearchQuery: '流式任务为什么需要定期保存检查点',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('A checkpoint captures'), findsOneWidget);
    expect(find.byKey(const ValueKey('knowledge-search-augmented-chip')),
        findsOneWidget);
    final answer = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '基于来源回答'),
    );
    expect(answer.onPressed, isNotNull);
    expect(find.text('1 条可引用片段'), findsOneWidget);
    expect(find.text('暂无可引用片段'), findsNothing);
  });

  for (final completeBeforeDebounce in [true, false]) {
    testWidgets(
        'an old answer completing ${completeBeforeDebounce ? 'before' : 'after'} '
        'debounce is neither displayed nor recorded', (tester) async {
      final harness = await _pumpAnswerSearch(tester);
      await _startAnswer(tester);
      await tester.enterText(_searchInput, 'new');
      if (!completeBeforeDebounce) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      harness.task.requests.single.succeed('Obsolete answer');
      await tester.pump();
      await tester.pump();
      final obsoleteWrites = harness.repository.saves.length;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(obsoleteWrites, 0);
      expect(find.text('Obsolete answer'), findsNothing);
      expect(find.text('来源约束回答'), findsNothing);
      expect(find.text('New result'), findsOneWidget);
      expect(find.textContaining(knowledgeAnswerSavedRecordStatusText),
          findsNothing);

      await _startAnswer(tester);
      expect(harness.task.requests.last.question, 'new');
      harness.task.requests.last.succeed('Current answer');
      await tester.pumpAndSettle();

      expect(find.text('Current answer'), findsOneWidget);
      final record = KnowledgeAnswerSessionSummaryRecord.fromSession(
        harness.repository.sessions.single,
      );
      expect(record.question, 'new');
      expect(record.answer, 'Current answer');
      expect(record.citationIds, ['synthetic-chunk']);
      expect(find.textContaining(knowledgeAnswerSavedRecordStatusText),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('answer action waits for the edited query to commit',
      (tester) async {
    final harness = await _pumpAnswerSearch(tester);
    await tester.enterText(_searchInput, 'new');
    await tester.pump();
    final pendingAction = tester.widget<ElevatedButton>(_answerAction);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(pendingAction.onPressed, isNull);
    expect(tester.widget<ElevatedButton>(_answerAction).onPressed, isNotNull);
    expect(harness.task.requests, isEmpty);
  });

  testWidgets('returning to the same query does not revive its older answer',
      (tester) async {
    final harness = await _pumpAnswerSearch(tester);
    await _startAnswer(tester);
    await tester.enterText(_searchInput, 'new');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(_searchInput, 'old');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await _startAnswer(tester);
    expect(harness.task.requests.map((request) => request.question),
        ['old', 'old']);

    harness.task.requests.first.succeed('Obsolete answer');
    await tester.pump();
    await tester.pump();

    expect(find.text('Obsolete answer'), findsNothing);
    expect(find.text('回答中'), findsOneWidget);
    expect(harness.repository.saves, isEmpty);

    harness.task.requests.last.succeed('Replacement answer');
    await tester.pumpAndSettle();
    expect(find.text('Replacement answer'), findsOneWidget);
    expect(harness.repository.sessions, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an old failure during debounce cannot become the new error',
      (tester) async {
    final harness = await _pumpAnswerSearch(tester);
    await _startAnswer(tester);
    await tester.enterText(_searchInput, 'new');
    harness.task.requests.single.fail('Obsolete failure');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Obsolete failure'), findsNothing);
    expect(find.byTooltip('重新生成回答'), findsNothing);
    expect(harness.repository.saves, isEmpty);
    expect(tester.widget<ElevatedButton>(_answerAction).onPressed, isNotNull);
  });

  testWidgets('the current answer can retry with its original evidence',
      (tester) async {
    final harness = await _pumpAnswerSearch(tester);
    await _startAnswer(tester);
    harness.task.requests.single.fail('Current failure');
    await tester.pumpAndSettle();
    expect(find.text('Current failure'), findsOneWidget);

    await tester.tap(find.byTooltip('重新生成回答'));
    await tester.pump();
    expect(harness.task.requests, hasLength(2));
    expect(harness.task.requests.last.question, 'old');
    expect(harness.task.requests.last.context,
        same(harness.task.requests.first.context));
    harness.task.requests.last.succeed('Retried answer');
    await tester.pumpAndSettle();

    expect(find.text('Retried answer'), findsOneWidget);
    expect(find.text('第 2 次生成成功'), findsOneWidget);
    expect(harness.repository.sessions, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final oldSaveSucceeds in [true, false]) {
    testWidgets(
        'an older save ${oldSaveSucceeds ? 'success' : 'failure'} cannot change '
        'a newer answer for the same query', (tester) async {
      final harness = await _pumpAnswerSearch(tester, deferSaves: true);
      await _startAnswer(tester);
      harness.task.requests.single.succeed('First answer');
      await tester.pumpAndSettle();
      expect(harness.repository.saves, hasLength(1));

      await _startAnswer(tester);
      harness.task.requests.last.succeed('Second answer');
      await tester.pumpAndSettle();
      expect(harness.repository.saves, hasLength(2));
      if (oldSaveSucceeds) {
        harness.repository.saves.first.completion.complete();
      } else {
        harness.repository.saves.first.completion.completeError(
          StateError('Obsolete save failure'),
        );
      }
      await tester.pumpAndSettle();

      expect(find.text('Second answer'), findsOneWidget);
      expect(find.text(knowledgeAnswerSavingRecordStatusText), findsOneWidget);
      expect(find.textContaining(knowledgeAnswerSavedRecordStatusText),
          findsNothing);
      expect(find.textContaining('Obsolete save failure'), findsNothing);
      expect(find.byTooltip('重试保存到学习记录'), findsNothing);

      harness.repository.saves.last.completion.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining(knowledgeAnswerSavedRecordStatusText),
          findsOneWidget);
      expect(harness.repository.sessions, hasLength(oldSaveSucceeds ? 2 : 1));
      final current = KnowledgeAnswerSessionSummaryRecord.fromSession(
        harness.repository.sessions.last,
      );
      expect(current.question, 'old');
      expect(current.answer, 'Second answer');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a current record failure retries without generating again',
      (tester) async {
    final harness = await _pumpAnswerSearch(tester, deferSaves: true);
    await _startAnswer(tester);
    harness.task.requests.single.succeed('Current answer');
    await tester.pumpAndSettle();
    harness.repository.saves.single.completion.completeError(
      StateError('Current save failure'),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('重试保存到学习记录'), findsOneWidget);

    await tester.tap(find.byTooltip('重试保存到学习记录'));
    await tester.pump();
    harness.repository.saves.last.completion.complete();
    await tester.pumpAndSettle();

    expect(harness.task.requests, hasLength(1));
    expect(harness.repository.saves, hasLength(2));
    expect(harness.repository.sessions, hasLength(1));
    expect(find.text('第 2 次保存尝试成功'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dispose in [false, true]) {
    testWidgets(
        '${dispose ? 'disposing' : 'clearing'} search discards a pending answer',
        (tester) async {
      final harness = await _pumpAnswerSearch(tester);
      await _startAnswer(tester);
      if (dispose) {
        await tester.pumpWidget(const SizedBox.shrink());
      } else {
        await tester.tap(find.byTooltip('清空'));
        await tester.pump();
      }
      harness.task.requests.single.succeed('Obsolete answer');
      await tester.pumpAndSettle();

      expect(harness.repository.saves, isEmpty);
      expect(find.text('Obsolete answer'), findsNothing);
      if (!dispose) {
        expect(find.text('输入关键词检索知识库'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Finder get _searchInput => find.byKey(const ValueKey('knowledge-search-input'));
Finder get _answerAction => find.widgetWithText(ElevatedButton, '基于来源回答');

Future<void> _startAnswer(WidgetTester tester) async {
  await tester.tap(_answerAction);
  await tester.pump();
}

Future<
        ({
          _ControlledKnowledgeAnswerTask task,
          _ControlledLearningSessionRepository repository,
        })>
    _pumpAnswerSearch(WidgetTester tester, {bool deferSaves = false}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final task = _ControlledKnowledgeAnswerTask();
  final repository =
      _ControlledLearningSessionRepository(deferSaves: deferSaves);
  await _pumpSearch(
    tester,
    initialQuery: 'old',
    answerTask: task,
    sessionRepository: repository,
  );
  return (task: task, repository: repository);
}

class _ControlledKnowledgeAnswerTask implements KnowledgeAnswerTask {
  final requests = <_PendingAnswer>[];

  @override
  Future<AiTaskResult<KnowledgeAnswerResult>> run({
    required String question,
    required List<SourceChunk> sourceChunks,
    GroundedLearningContext? groundedContext,
  }) {
    expect(sourceChunks.map((chunk) => chunk.id), ['synthetic-chunk']);
    expect(groundedContext?.isExecutable, isTrue);
    final request = _PendingAnswer(question, groundedContext!);
    requests.add(request);
    return request.completion.future;
  }
}

class _PendingAnswer {
  final String question;
  final GroundedLearningContext context;
  final completion = Completer<AiTaskResult<KnowledgeAnswerResult>>();

  _PendingAnswer(this.question, this.context);

  void succeed(String answer) => completion.complete(AiTaskResult.success(
        KnowledgeAnswerResult(
          answer: answer,
          citationIds: const ['synthetic-chunk'],
        ),
      ));

  void fail(String message) => completion.complete(AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: message,
      ));
}

class _ControlledLearningSessionRepository extends LearningSessionRepository {
  final bool deferSaves;
  final saves = <_PendingRecord>[];
  final sessions = <LearningSession>[];

  _ControlledLearningSessionRepository({required this.deferSaves})
      : super(DatabaseHelper());

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    final save = _PendingRecord();
    saves.add(save);
    if (deferSaves) await save.completion.future;
    sessions.add(session);
    return session.id;
  }
}

class _PendingRecord {
  final completion = Completer<void>();
}

GroundedLearningContext _answerContext(String query) {
  final source = _syntheticSource();
  final chunk = SourceChunk(
    id: 'synthetic-chunk',
    sourceId: source.id,
    chunkIndex: 0,
    content: 'Synthetic evidence for the controlled answer task.',
    locator: 'Synthetic section',
    createdAt: source.createdAt,
  );
  return GroundedLearningContext(
    targetId: query,
    surface: GroundedLearningSurface.knowledgeAnswer,
    items: [
      GroundedLearningContextItem(
        chunk: chunk,
        source: source,
        selectionReasons: const [GroundedLearningContextReason.knowledgeSearch],
        quoteBoundary: GroundedLearningQuoteBoundary(
          sourceChunkId: chunk.id,
          startOffset: 0,
          endOffset: chunk.content.length,
          exactText: chunk.content,
        ),
      ),
    ],
  );
}

Source _syntheticSource() => Source(
      id: 'synthetic-source',
      title: 'Synthetic reference',
      type: SourceType.officialDoc,
      trustLevel: SourceTrustLevel.officialDoc,
      createdAt: DateTime.utc(2026, 9, 8),
      updatedAt: DateTime.utc(2026, 9, 8),
    );

class _EnabledSearchPreferencesStore implements SearchPreferencesStore {
  @override
  Future<SearchPreferences> read() async =>
      const SearchPreferences(modelAssistedSearchEnabled: true);

  @override
  Future<void> write(SearchPreferences preferences) async {}
}

class _CheckpointVariantProvider implements SearchQueryVariantProvider {
  @override
  Future<List<SearchQueryVariant>> variants(String originalQuery) async =>
      const [
        SearchQueryVariant(
          query: 'checkpoint',
          source: SearchQueryVariantSource.modelRewrite,
          reason: 'synthetic bilingual query',
        ),
      ];
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  Completer<List<KnowledgeSearchResult>>? oldResults,
  String? initialQuery,
  _ControlledKnowledgeAnswerTask? answerTask,
  _ControlledLearningSessionRepository? sessionRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sourceListProvider.overrideWith((ref) async => []),
        knowledgePointListProvider.overrideWith((ref) async => []),
        allQuestionsProvider.overrideWith((ref) async => []),
        pendingQuestionListProvider.overrideWith((ref) async => []),
        knowledgeAnswerSessionListProvider.overrideWith(
          (ref) async => sessionRepository?.sessions ?? [],
        ),
        if (answerTask != null)
          knowledgeAnswerTaskProvider.overrideWithValue(answerTask),
        if (sessionRepository != null)
          learningSessionRepositoryProvider
              .overrideWithValue(sessionRepository),
        sourceProvider('synthetic-source').overrideWith(
          (ref) async => _syntheticSource(),
        ),
        knowledgeSearchResultsProvider('old').overrideWith(
          (ref) => oldResults?.future ?? Future.value([_result('Old result')]),
        ),
        knowledgeSearchResultsProvider('new').overrideWith(
          (ref) async => [_result('New result')],
        ),
        knowledgeSearchResultsProvider('augmented').overrideWith(
          (ref) async => [_result('Lexical result')],
        ),
        knowledgeSearchResultsProvider('fallback').overrideWith(
          (ref) async => [_result('Fallback result')],
        ),
        for (final query in ['old', 'new', 'augmented', 'fallback'])
          knowledgeAnswerGroundedContextProvider(query).overrideWith(
            (ref) async => answerTask != null
                ? _answerContext(query)
                : GroundedLearningContext(
                    targetId: query,
                    surface: GroundedLearningSurface.knowledgeAnswer,
                    items: const [],
                  ),
          ),
        knowledgeHybridSearchReportProvider('old').overrideWith(
          (ref) async => _report('old'),
        ),
        knowledgeHybridSearchReportProvider('new').overrideWith(
          (ref) async => _report('new'),
        ),
        knowledgeHybridSearchReportProvider('augmented').overrideWith(
          (ref) async => _report(
            'augmented',
            status: HybridKnowledgeSearchStatus.augmented,
          ),
        ),
        knowledgeHybridSearchReportProvider('fallback').overrideWith(
          (ref) async => _report(
            'fallback',
            status: HybridKnowledgeSearchStatus.fallback,
          ),
        ),
      ],
      child: MaterialApp(
        home: KnowledgeBaseScreen(
          initialSearchQuery: initialQuery,
          searchDebounceDelay: const Duration(milliseconds: 100),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

KnowledgeSearchResult _result(String title) => KnowledgeSearchResult(
      type: KnowledgeSearchResultType.knowledgePoint,
      title: title,
      snippet: '$title snippet',
      score: 1,
    );

HybridKnowledgeSearchReport _report(
  String query, {
  HybridKnowledgeSearchStatus status = HybridKnowledgeSearchStatus.lexicalOnly,
}) =>
    HybridKnowledgeSearchReport(
      originalQuery: query,
      variants: [
        SearchQueryVariant(
          query: query,
          source: SearchQueryVariantSource.original,
          reason: 'test',
        ),
      ],
      results: status == HybridKnowledgeSearchStatus.augmented
          ? [
              HybridKnowledgeSearchResult(
                result: _result('Augmented result'),
                fusedScore: 1,
                branchRanks: const {SearchQueryVariantSource.original: 1},
              ),
            ]
          : const [],
      status: status,
    );
