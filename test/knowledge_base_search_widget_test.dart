import 'dart:async';

import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/models/grounded_learning_context.dart';
import 'package:dlg_q/features/knowledge_base/knowledge_base_screen.dart';
import 'package:dlg_q/services/agent/hybrid_knowledge_search_service.dart';
import 'package:dlg_q/services/agent/knowledge_search_service.dart';
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
