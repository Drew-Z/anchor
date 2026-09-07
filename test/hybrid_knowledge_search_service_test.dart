import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/hybrid_knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/search_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final corpus = _corpus();

  test('keeps the original lexical branch when no provider is configured',
      () async {
    final report = await const HybridKnowledgeSearchService().search(
      query: 'checkpoint failure recovery',
      corpus: corpus,
    );

    expect(report.status, HybridKnowledgeSearchStatus.lexicalOnly);
    expect(report.variants.single.source, SearchQueryVariantSource.original);
    expect(report.results.first.result.sourceChunkId, 'checkpoint');
    expect(
      report.results.first.reasonLabels,
      contains(startsWith('原始查询排名')),
    );
  });

  test('fuses an independent bilingual rewrite without dropping provenance',
      () async {
    final report = await const HybridKnowledgeSearchService().search(
      query: '流式任务为什么需要定期保存检查点',
      corpus: corpus,
      variantProvider: const _FixedVariantProvider([
        SearchQueryVariant(
          query: 'checkpoint consistent state failure recovery',
          source: SearchQueryVariantSource.modelRewrite,
          reason: '只改写用户查询，不发送知识库正文',
        ),
      ]),
    );

    expect(report.status, HybridKnowledgeSearchStatus.augmented);
    expect(report.variants.first.source, SearchQueryVariantSource.original);
    expect(report.results.first.result.sourceChunkId, 'checkpoint');
    expect(
      report.results.first.branchRanks,
      contains(SearchQueryVariantSource.modelRewrite),
    );
    expect(
      report.results.first.reasonLabels,
      contains(startsWith('模型改写排名')),
    );
  });

  test('falls back deterministically when augmentation fails', () async {
    const service = HybridKnowledgeSearchService();
    final lexical = await service.search(
      query: 'observability traces metrics logs',
      corpus: corpus,
    );
    final fallback = await service.search(
      query: 'observability traces metrics logs',
      corpus: corpus,
      variantProvider: const _ThrowingVariantProvider(),
    );

    expect(fallback.status, HybridKnowledgeSearchStatus.fallback);
    expect(fallback.fallbackReason, 'StateError');
    expect(
      fallback.results.map((item) => item.result.sourceChunkId),
      lexical.results.map((item) => item.result.sourceChunkId),
    );
  });

  test('deduplicates, bounds, and never accepts a replacement original',
      () async {
    final report = await const HybridKnowledgeSearchService(
      maximumAugmentedVariants: 2,
    ).search(
      query: 'checkpoint',
      corpus: corpus,
      variantProvider: const _FixedVariantProvider([
        SearchQueryVariant(
          query: 'replacement',
          source: SearchQueryVariantSource.original,
          reason: 'invalid replacement',
        ),
        SearchQueryVariant(
          query: ' checkpoint ',
          source: SearchQueryVariantSource.modelRewrite,
          reason: 'duplicate',
        ),
        SearchQueryVariant(
          query: 'state recovery',
          source: SearchQueryVariantSource.localSemantic,
          reason: 'semantic candidate',
        ),
        SearchQueryVariant(
          query: 'failure resume',
          source: SearchQueryVariantSource.modelRewrite,
          reason: 'second candidate',
        ),
        SearchQueryVariant(
          query: 'ignored extra',
          source: SearchQueryVariantSource.modelRewrite,
          reason: 'over limit',
        ),
      ]),
    );

    expect(report.variants.map((variant) => variant.query), [
      'checkpoint',
      'state recovery',
      'failure resume',
    ]);
  });

  group('answer evidence follows the displayed search branch', () {
    const query = '流式任务为什么需要定期保存检查点';
    const rewrite = SearchQueryVariant(
      query: 'checkpoint consistent state recovery',
      source: SearchQueryVariantSource.modelRewrite,
      reason: 'synthetic bilingual query',
    );

    test('uses rewrite-only hits and retains their local provenance', () async {
      final container = await _searchContainer(
        enabled: true,
        variantProvider: const _FixedVariantProvider([rewrite]),
      );
      final lexical =
          await container.read(knowledgeSearchResultsProvider(query).future);
      final report = await container
          .read(knowledgeHybridSearchReportProvider(query).future);
      final context = await container
          .read(knowledgeAnswerGroundedContextProvider(query).future);

      expect(lexical, isEmpty);
      expect(report.status, HybridKnowledgeSearchStatus.augmented);
      expect(report.results.single.result.sourceChunkId, 'checkpoint');
      expect(context.chunkIds, ['checkpoint']);
      expect(context.isExecutable, isTrue);
      expect(context.targetId, query);
      expect(context.items.single.source.id, 'docs');
      expect(context.items.single.trustLevel, SourceTrustLevel.officialDoc);
      expect(context.items.single.locator, 'Checkpointing');
      expect(context.items.single.quoteBoundary.exactText,
          _corpus().sourceChunks.first.content);
    });

    test('default-off search makes no rewrite request and requires a local hit',
        () async {
      final variants = _PendingVariantProvider();
      final container = await _searchContainer(variantProvider: variants);
      container.listen(
          knowledgeAnswerGroundedContextProvider(query), (_, __) {});
      container.listen(
          knowledgeAnswerGroundedContextProvider('checkpoint'), (_, __) {});

      final emptyContext = await container
          .read(knowledgeAnswerGroundedContextProvider(query).future)
          .timeout(const Duration(seconds: 5));
      final localContext = await container
          .read(knowledgeAnswerGroundedContextProvider('checkpoint').future);

      expect(emptyContext.isExecutable, isFalse);
      expect(emptyContext.chunks, isEmpty);
      expect(localContext.chunkIds, ['checkpoint']);
      expect(variants.queries, isEmpty);
    });

    test('failed augmentation preserves the original local answer evidence',
        () async {
      const localQuery = 'observability traces metrics logs';
      final container = await _searchContainer(
        enabled: true,
        variantProvider: const _ThrowingVariantProvider(),
      );
      final report = await container
          .read(knowledgeHybridSearchReportProvider(localQuery).future);
      final context = await container
          .read(knowledgeAnswerGroundedContextProvider(localQuery).future);

      expect(report.status, HybridKnowledgeSearchStatus.fallback);
      expect(context.chunkIds, ['observability']);
      expect(context.isExecutable, isTrue);
    });

    test(
        'keeps local evidence while pending and follows completion and opt-out',
        () async {
      const localQuery = 'observability';
      final variants = _PendingVariantProvider();
      final container = await _searchContainer(
        enabled: true,
        variantProvider: variants,
      );
      final reportProvider = knowledgeHybridSearchReportProvider(localQuery);
      final contextProvider =
          knowledgeAnswerGroundedContextProvider(localQuery);
      container.listen(reportProvider, (_, __) {});
      container.listen(contextProvider, (_, __) {});

      final pendingContext = await container
          .read(contextProvider.future)
          .timeout(const Duration(seconds: 5));
      expect(variants.queries, [localQuery]);
      expect(variants.response.isCompleted, isFalse);
      expect(pendingContext.chunkIds, ['observability']);
      expect(pendingContext.isExecutable, isTrue);

      variants.response.complete([rewrite]);
      final report = await container.read(reportProvider.future);
      final augmentedContext = await container.read(contextProvider.future);
      expect(report.status, HybridKnowledgeSearchStatus.augmented);
      expect(augmentedContext.chunkIds, ['observability', 'checkpoint']);
      expect(variants.queries, [localQuery]);

      await container
          .read(searchPreferencesProvider.notifier)
          .setModelAssistedSearchEnabled(false);
      final disabledReport = await container.read(reportProvider.future);
      final disabledContext = await container.read(contextProvider.future);
      expect(disabledReport.status, HybridKnowledgeSearchStatus.lexicalOnly);
      expect(disabledContext.chunkIds, ['observability']);
      expect(variants.queries, [localQuery]);

      await container
          .read(searchPreferencesProvider.notifier)
          .setModelAssistedSearchEnabled(true);
      await container.read(reportProvider.future);
      final enabledContext = await container.read(contextProvider.future);
      expect(enabledContext.chunkIds, ['observability', 'checkpoint']);
      expect(variants.queries, [localQuery, localQuery]);
    });
  });
}

Future<ProviderContainer> _searchContainer({
  bool enabled = false,
  required SearchQueryVariantProvider variantProvider,
}) async {
  final container = ProviderContainer(overrides: [
    knowledgeSearchCorpusProvider.overrideWith((ref) async => _corpus()),
    searchPreferencesStoreProvider.overrideWithValue(
      _MemorySearchPreferencesStore(
        SearchPreferences(modelAssistedSearchEnabled: enabled),
      ),
    ),
    modelSearchQueryVariantProvider.overrideWithValue(variantProvider),
  ]);
  addTearDown(container.dispose);
  await container.read(searchPreferencesProvider.notifier).load();
  return container;
}

class _MemorySearchPreferencesStore implements SearchPreferencesStore {
  SearchPreferences value;

  _MemorySearchPreferencesStore(this.value);

  @override
  Future<SearchPreferences> read() async => value;

  @override
  Future<void> write(SearchPreferences preferences) async =>
      value = preferences;
}

class _PendingVariantProvider implements SearchQueryVariantProvider {
  final queries = <String>[];
  final response = Completer<List<SearchQueryVariant>>();

  @override
  Future<List<SearchQueryVariant>> variants(String originalQuery) {
    queries.add(originalQuery);
    return response.future;
  }
}

class _FixedVariantProvider implements SearchQueryVariantProvider {
  final List<SearchQueryVariant> values;

  const _FixedVariantProvider(this.values);

  @override
  Future<List<SearchQueryVariant>> variants(String originalQuery) async {
    return values;
  }
}

class _ThrowingVariantProvider implements SearchQueryVariantProvider {
  const _ThrowingVariantProvider();

  @override
  Future<List<SearchQueryVariant>> variants(String originalQuery) {
    throw StateError('offline');
  }
}

KnowledgeSearchCorpus _corpus() {
  final now = DateTime.utc(2026, 7, 17);
  return KnowledgeSearchCorpus(
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
        content: 'A checkpoint captures consistent application state so '
            'processing can recover after failure.',
        locator: 'Checkpointing',
        createdAt: now,
      ),
      SourceChunk(
        id: 'observability',
        sourceId: 'docs',
        chunkIndex: 1,
        content: 'Observability correlates traces, metrics, and logs to '
            'diagnose failures.',
        locator: 'Observability primer',
        createdAt: now,
      ),
    ],
    knowledgePoints: const [],
    questions: const [],
  );
}
