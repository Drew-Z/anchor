import 'knowledge_search_service.dart';

enum SearchQueryVariantSource { original, modelRewrite, localSemantic }

class SearchQueryVariant {
  final String query;
  final SearchQueryVariantSource source;
  final String reason;

  const SearchQueryVariant({
    required this.query,
    required this.source,
    required this.reason,
  });
}

abstract class SearchQueryVariantProvider {
  Future<List<SearchQueryVariant>> variants(String originalQuery);
}

enum HybridKnowledgeSearchStatus { lexicalOnly, augmented, fallback }

class HybridKnowledgeSearchResult {
  final KnowledgeSearchResult result;
  final double fusedScore;
  final Map<SearchQueryVariantSource, int> branchRanks;

  const HybridKnowledgeSearchResult({
    required this.result,
    required this.fusedScore,
    required this.branchRanks,
  });

  List<String> get reasonLabels => [
        ...result.scoreBreakdown.reasonLabels,
        if (branchRanks.containsKey(SearchQueryVariantSource.original))
          '原始查询排名 #${branchRanks[SearchQueryVariantSource.original]}',
        if (branchRanks.containsKey(SearchQueryVariantSource.modelRewrite))
          '模型改写排名 #${branchRanks[SearchQueryVariantSource.modelRewrite]}',
        if (branchRanks.containsKey(SearchQueryVariantSource.localSemantic))
          '本地语义排名 #${branchRanks[SearchQueryVariantSource.localSemantic]}',
        'RRF 融合 ${fusedScore.toStringAsFixed(4)}',
      ];
}

class HybridKnowledgeSearchReport {
  final String originalQuery;
  final List<SearchQueryVariant> variants;
  final List<HybridKnowledgeSearchResult> results;
  final HybridKnowledgeSearchStatus status;
  final String? fallbackReason;

  const HybridKnowledgeSearchReport({
    required this.originalQuery,
    required this.variants,
    required this.results,
    required this.status,
    this.fallbackReason,
  });
}

class HybridKnowledgeSearchService {
  final KnowledgeSearchService lexicalSearch;
  final int rrfConstant;
  final int maximumAugmentedVariants;

  const HybridKnowledgeSearchService({
    this.lexicalSearch = const KnowledgeSearchService(),
    this.rrfConstant = 60,
    this.maximumAugmentedVariants = 3,
  });

  Future<HybridKnowledgeSearchReport> search({
    required String query,
    required KnowledgeSearchCorpus corpus,
    SearchQueryVariantProvider? variantProvider,
    int limit = 20,
  }) async {
    final original = SearchQueryVariant(
      query: query.trim(),
      source: SearchQueryVariantSource.original,
      reason: '用户原始查询',
    );
    if (original.query.isEmpty || limit <= 0) {
      return HybridKnowledgeSearchReport(
        originalQuery: query,
        variants: [original],
        results: const [],
        status: HybridKnowledgeSearchStatus.lexicalOnly,
      );
    }

    var variants = <SearchQueryVariant>[original];
    String? fallbackReason;
    if (variantProvider != null) {
      try {
        variants = _normalizedVariants(
          original,
          await variantProvider.variants(original.query),
        );
      } catch (error) {
        fallbackReason = error.runtimeType.toString();
      }
    }

    final merged = <String, _MutableFusedResult>{};
    final branchLimit = limit * 3 < 20 ? 20 : limit * 3;
    for (final variant in variants) {
      final branch = lexicalSearch.search(
        query: variant.query,
        corpus: corpus,
        limit: branchLimit,
      );
      for (var index = 0; index < branch.length; index++) {
        final result = branch[index];
        final key = _resultKey(result);
        final fused = merged.putIfAbsent(
          key,
          () => _MutableFusedResult(result),
        );
        final rank = index + 1;
        final weight =
            variant.source == SearchQueryVariantSource.original ? 1.25 : 1.0;
        fused
          ..fusedScore += weight / (rrfConstant + rank)
          ..branchRanks[variant.source] = rank;
        if (result.score > fused.result.score) fused.result = result;
      }
    }

    final results = merged.entries.map((entry) {
      final value = entry.value;
      return _RankedHybridResult(
        stableKey: entry.key,
        value: HybridKnowledgeSearchResult(
          result: value.result,
          fusedScore: value.fusedScore,
          branchRanks: Map.unmodifiable(value.branchRanks),
        ),
      );
    }).toList()
      ..sort(_compare);

    return HybridKnowledgeSearchReport(
      originalQuery: original.query,
      variants: List.unmodifiable(variants),
      results: results.take(limit).map((item) => item.value).toList(),
      status: fallbackReason != null
          ? HybridKnowledgeSearchStatus.fallback
          : variants.length == 1
              ? HybridKnowledgeSearchStatus.lexicalOnly
              : HybridKnowledgeSearchStatus.augmented,
      fallbackReason: fallbackReason,
    );
  }

  List<SearchQueryVariant> _normalizedVariants(
    SearchQueryVariant original,
    List<SearchQueryVariant> candidates,
  ) {
    final variants = <SearchQueryVariant>[original];
    final seen = <String>{original.query.toLowerCase()};
    for (final candidate in candidates) {
      final normalized = candidate.query.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (candidate.source == SearchQueryVariantSource.original ||
          normalized.isEmpty ||
          normalized.length > 240 ||
          !seen.add(normalized.toLowerCase())) {
        continue;
      }
      variants.add(
        SearchQueryVariant(
          query: normalized,
          source: candidate.source,
          reason: candidate.reason.trim().isEmpty
              ? '未提供改写原因'
              : candidate.reason.trim(),
        ),
      );
      if (variants.length > maximumAugmentedVariants) break;
    }
    return variants;
  }

  static int _compare(_RankedHybridResult left, _RankedHybridResult right) {
    var comparison = right.value.fusedScore.compareTo(left.value.fusedScore);
    if (comparison != 0) return comparison;
    final leftOriginal =
        left.value.branchRanks[SearchQueryVariantSource.original] ?? 1 << 20;
    final rightOriginal =
        right.value.branchRanks[SearchQueryVariantSource.original] ?? 1 << 20;
    comparison = leftOriginal.compareTo(rightOriginal);
    if (comparison != 0) return comparison;
    comparison = right.value.result.score.compareTo(left.value.result.score);
    if (comparison != 0) return comparison;
    return left.stableKey.compareTo(right.stableKey);
  }

  static String _resultKey(KnowledgeSearchResult result) {
    return [
      result.type.name,
      result.sourceChunkId,
      result.sourceId,
      result.knowledgePointId,
      result.questionId,
      result.title,
    ].join('|');
  }
}

class _MutableFusedResult {
  KnowledgeSearchResult result;
  double fusedScore = 0;
  final Map<SearchQueryVariantSource, int> branchRanks = {};

  _MutableFusedResult(this.result);
}

class _RankedHybridResult {
  final String stableKey;
  final HybridKnowledgeSearchResult value;

  const _RankedHybridResult({required this.stableKey, required this.value});
}
