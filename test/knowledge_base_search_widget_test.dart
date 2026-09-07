import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/models/grounded_learning_context.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_base_screen.dart';
import 'package:anchor_learning/services/agent/hybrid_knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/search_preferences.dart';
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
}

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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sourceListProvider.overrideWith((ref) async => []),
        knowledgePointListProvider.overrideWith((ref) async => []),
        allQuestionsProvider.overrideWith((ref) async => []),
        pendingQuestionListProvider.overrideWith((ref) async => []),
        knowledgeAnswerSessionListProvider.overrideWith((ref) async => []),
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
            (ref) async => GroundedLearningContext(
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
