import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/agent/hybrid_knowledge_search_service.dart';
import 'package:dlg_q/services/agent/knowledge_search_service.dart';
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
