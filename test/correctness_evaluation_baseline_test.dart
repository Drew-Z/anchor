import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/ai/grounded_claim_gate.dart';
import 'package:anchor_learning/services/evaluation/correctness_evaluation_service.dart';

void main() {
  test('fixed correctness corpus records the current Branch 19 baseline', () {
    final fixture = _loadFixture();
    final retrievalCases = fixture.retrievalCases.map((item) {
      return RetrievalEvaluationCase(
        id: item.id,
        relevantEvidenceIds: item.relevantEvidenceIds,
        rankedEvidenceIds: item.baselineRankedEvidenceIds,
      );
    }).toList();

    final report = const CorrectnessEvaluationService().evaluate(
      retrievalCases: retrievalCases,
      generationCases: fixture.generationCases,
      topK: fixture.topK,
    );

    expect(
      fixture.generationCases.map((item) => item.surface).toSet(),
      CorrectnessEvaluationSurface.values.toSet(),
    );
    expect(report.retrievalCaseCount, fixture.expected.retrievalCaseCount);
    expect(report.generationCaseCount, fixture.expected.generationCaseCount);
    expect(report.recallAtK, closeTo(fixture.expected.recallAtK, 0.000001));
    expect(
      report.meanReciprocalRank,
      closeTo(fixture.expected.meanReciprocalRank, 0.000001),
    );
    expect(
      report.citationCoverage,
      closeTo(fixture.expected.citationCoverage, 0.000001),
    );
    expect(
      report.unsupportedClaimRate,
      closeTo(fixture.expected.unsupportedClaimRate, 0.000001),
    );
    expect(
      report.refusalAccuracy,
      closeTo(fixture.expected.refusalAccuracy, 0.000001),
    );
  });

  test('current retrieval ranking improves without rewriting the baseline', () {
    final fixture = _loadFixture();
    final corpus = _buildSearchCorpus(fixture.searchCorpus);
    const searchService = KnowledgeSearchService();
    const evaluationService = CorrectnessEvaluationService();

    final currentCases = fixture.retrievalCases.map((item) {
      final results = searchService.search(query: item.query, corpus: corpus);
      return RetrievalEvaluationCase(
        id: item.id,
        relevantEvidenceIds: item.relevantEvidenceIds,
        rankedEvidenceIds: _rankedEvidenceIds(results, corpus),
      );
    }).toList();
    final report = evaluationService.evaluate(
      retrievalCases: currentCases,
      generationCases: const [],
      topK: fixture.topK,
    );

    expect(report.recallAtK, greaterThanOrEqualTo(fixture.expected.recallAtK));
    expect(
      report.meanReciprocalRank,
      greaterThanOrEqualTo(fixture.expected.meanReciprocalRank),
    );
    expect(report.recallAtK, 1);
    expect(report.meanReciprocalRank, 1);
  });

  test('claim gate improves generation metrics without rewriting the baseline',
      () {
    final fixture = _loadFixture();
    final corpus = _buildSearchCorpus(fixture.searchCorpus);
    final currentCases = fixture.generationCases
        .map((item) => _applyClaimGate(item, corpus.sourceChunks))
        .toList();
    final report = const CorrectnessEvaluationService().evaluate(
      retrievalCases: const [],
      generationCases: currentCases,
      topK: fixture.topK,
    );

    expect(
      report.citationCoverage,
      greaterThan(fixture.expected.citationCoverage),
    );
    expect(
      report.unsupportedClaimRate,
      lessThan(fixture.expected.unsupportedClaimRate),
    );
    expect(
      report.refusalAccuracy,
      greaterThanOrEqualTo(fixture.expected.refusalAccuracy),
    );
    expect(report.citationCoverage, 1);
    expect(report.unsupportedClaimRate, 0);
    expect(
      report.refusalAccuracy,
      closeTo(fixture.expected.refusalAccuracy, 0.000001),
    );
  });

  test('metric contract deduplicates ranking and handles empty dimensions', () {
    final report = const CorrectnessEvaluationService().evaluate(
      retrievalCases: const [
        RetrievalEvaluationCase(
          id: 'deduplicated-ranking',
          relevantEvidenceIds: ['relevant'],
          rankedEvidenceIds: ['other', 'other', 'relevant'],
        ),
        RetrievalEvaluationCase(
          id: 'no-relevance-judgment',
          relevantEvidenceIds: [],
          rankedEvidenceIds: ['other'],
        ),
      ],
      generationCases: const [],
      topK: 1,
    );

    expect(report.retrievalCaseCount, 1);
    expect(report.recallAtK, 0);
    expect(report.meanReciprocalRank, 0.5);
    expect(report.citationCoverage, 0);
    expect(report.unsupportedClaimRate, 0);
    expect(report.refusalAccuracy, 0);
  });

  test('topK must be positive', () {
    expect(
      () => const CorrectnessEvaluationService().evaluate(
        retrievalCases: const [],
        generationCases: const [],
        topK: 0,
      ),
      throwsArgumentError,
    );
  });
}

GenerationEvaluationCase _applyClaimGate(
  GenerationEvaluationCase evaluationCase,
  List<SourceChunk> sourceChunks,
) {
  final chunksById = {for (final chunk in sourceChunks) chunk.id: chunk};
  final gateResult = const GroundedClaimGate().evaluate(
    claims: evaluationCase.claims.map((claim) {
      final supportingIds = claim.supportingEvidenceIds.toSet();
      return GroundedClaim(
        section: 'answer',
        text: claim.id,
        evidence: claim.citationIds.map((citationId) {
          final chunk = chunksById[citationId];
          final isSupporting = claim.supported &&
              supportingIds.contains(citationId) &&
              chunk != null;
          return GroundedClaimEvidence(
            citationId: citationId,
            quote: isSupporting ? chunk.content : 'unsupported evidence',
          );
        }).toList(),
      );
    }).toList(),
    sourceChunks: sourceChunks,
  );
  return GenerationEvaluationCase(
    id: evaluationCase.id,
    surface: evaluationCase.surface,
    expectedRefusal: evaluationCase.expectedRefusal,
    actualRefusal: evaluationCase.actualRefusal ||
        gateResult.disposition == GroundingDisposition.refused,
    claims: gateResult.groundedClaims.map((claim) {
      return ClaimEvaluation(
        id: claim.text,
        supported: true,
        supportingEvidenceIds: claim.citationIds,
        citationIds: claim.citationIds,
      );
    }).toList(),
  );
}

List<String> _rankedEvidenceIds(
  List<KnowledgeSearchResult> results,
  KnowledgeSearchCorpus corpus,
) {
  final chunksBySourceId = <String, List<SourceChunk>>{};
  for (final chunk in corpus.sourceChunks) {
    chunksBySourceId.putIfAbsent(chunk.sourceId, () => []).add(chunk);
  }

  final evidenceIds = <String>[];
  final seenIds = <String>{};

  void add(String? id) {
    if (id == null || id.isEmpty || !seenIds.add(id)) return;
    evidenceIds.add(id);
  }

  for (final result in results) {
    add(result.sourceChunkId);
    for (final citationId in result.citationIds) {
      add(citationId);
    }
    if (result.type == KnowledgeSearchResultType.source) {
      for (final chunk in chunksBySourceId[result.sourceId] ?? const []) {
        add(chunk.id);
      }
    }
  }
  return evidenceIds;
}

KnowledgeSearchCorpus _buildSearchCorpus(_SearchCorpusFixture fixture) {
  final now = DateTime.utc(2026, 7, 15);
  return KnowledgeSearchCorpus(
    sources: fixture.sources.map((item) {
      return Source(
        id: item.id,
        title: item.title,
        type: SourceType.fromString(item.type),
        uri: item.uri,
        trustLevel: SourceTrustLevel.fromString(item.trustLevel),
        createdAt: now,
        updatedAt: now,
      );
    }).toList(),
    sourceChunks: fixture.chunks.map((item) {
      return SourceChunk(
        id: item.id,
        sourceId: item.sourceId,
        chunkIndex: fixture.chunks.indexOf(item),
        content: item.content,
        locator: item.locator,
        createdAt: now,
      );
    }).toList(),
    knowledgePoints: const [],
    questions: const [],
  );
}

_CorrectnessFixture _loadFixture() {
  final json = jsonDecode(
    File(
      'test/fixtures/evaluation/correctness_baseline_v1.json',
    ).readAsStringSync(),
  ) as Map<String, dynamic>;
  return _CorrectnessFixture.fromJson(json);
}

class _CorrectnessFixture {
  final int topK;
  final _SearchCorpusFixture searchCorpus;
  final List<_RetrievalFixture> retrievalCases;
  final List<GenerationEvaluationCase> generationCases;
  final _ExpectedBaseline expected;

  const _CorrectnessFixture({
    required this.topK,
    required this.searchCorpus,
    required this.retrievalCases,
    required this.generationCases,
    required this.expected,
  });

  factory _CorrectnessFixture.fromJson(Map<String, dynamic> json) {
    return _CorrectnessFixture(
      topK: json['top_k'] as int,
      searchCorpus: _SearchCorpusFixture.fromJson(
        Map<String, dynamic>.from(json['search_corpus'] as Map),
      ),
      retrievalCases: (json['retrieval_cases'] as List<dynamic>)
          .map(
            (item) => _RetrievalFixture.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      generationCases: (json['generation_cases'] as List<dynamic>)
          .map(
            (item) => _generationCaseFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      expected: _ExpectedBaseline.fromJson(
        Map<String, dynamic>.from(json['expected_baseline'] as Map),
      ),
    );
  }
}

class _SearchCorpusFixture {
  final List<_SourceFixture> sources;
  final List<_ChunkFixture> chunks;

  const _SearchCorpusFixture({
    required this.sources,
    required this.chunks,
  });

  factory _SearchCorpusFixture.fromJson(Map<String, dynamic> json) {
    return _SearchCorpusFixture(
      sources: (json['sources'] as List<dynamic>)
          .map(
            (item) => _SourceFixture.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      chunks: (json['chunks'] as List<dynamic>)
          .map(
            (item) => _ChunkFixture.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class _SourceFixture {
  final String id;
  final String title;
  final String type;
  final String trustLevel;
  final String? uri;

  const _SourceFixture({
    required this.id,
    required this.title,
    required this.type,
    required this.trustLevel,
    this.uri,
  });

  factory _SourceFixture.fromJson(Map<String, dynamic> json) {
    return _SourceFixture(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      trustLevel: json['trust_level'] as String,
      uri: json['uri'] as String?,
    );
  }
}

class _ChunkFixture {
  final String id;
  final String sourceId;
  final String content;
  final String? locator;

  const _ChunkFixture({
    required this.id,
    required this.sourceId,
    required this.content,
    this.locator,
  });

  factory _ChunkFixture.fromJson(Map<String, dynamic> json) {
    return _ChunkFixture(
      id: json['id'] as String,
      sourceId: json['source_id'] as String,
      content: json['content'] as String,
      locator: json['locator'] as String?,
    );
  }
}

class _RetrievalFixture {
  final String id;
  final String query;
  final List<String> relevantEvidenceIds;
  final List<String> baselineRankedEvidenceIds;

  const _RetrievalFixture({
    required this.id,
    required this.query,
    required this.relevantEvidenceIds,
    required this.baselineRankedEvidenceIds,
  });

  factory _RetrievalFixture.fromJson(Map<String, dynamic> json) {
    return _RetrievalFixture(
      id: json['id'] as String,
      query: json['query'] as String,
      relevantEvidenceIds: _stringList(json['relevant_evidence_ids']),
      baselineRankedEvidenceIds:
          _stringList(json['baseline_ranked_evidence_ids']),
    );
  }
}

class _ExpectedBaseline {
  final int retrievalCaseCount;
  final int generationCaseCount;
  final double recallAtK;
  final double meanReciprocalRank;
  final double citationCoverage;
  final double unsupportedClaimRate;
  final double refusalAccuracy;

  const _ExpectedBaseline({
    required this.retrievalCaseCount,
    required this.generationCaseCount,
    required this.recallAtK,
    required this.meanReciprocalRank,
    required this.citationCoverage,
    required this.unsupportedClaimRate,
    required this.refusalAccuracy,
  });

  factory _ExpectedBaseline.fromJson(Map<String, dynamic> json) {
    return _ExpectedBaseline(
      retrievalCaseCount: json['retrieval_case_count'] as int,
      generationCaseCount: json['generation_case_count'] as int,
      recallAtK: (json['recall_at_k'] as num).toDouble(),
      meanReciprocalRank: (json['mean_reciprocal_rank'] as num).toDouble(),
      citationCoverage: (json['citation_coverage'] as num).toDouble(),
      unsupportedClaimRate: (json['unsupported_claim_rate'] as num).toDouble(),
      refusalAccuracy: (json['refusal_accuracy'] as num).toDouble(),
    );
  }
}

GenerationEvaluationCase _generationCaseFromJson(Map<String, dynamic> json) {
  return GenerationEvaluationCase(
    id: json['id'] as String,
    surface: CorrectnessEvaluationSurface.fromString(json['surface'] as String),
    expectedRefusal: json['expected_refusal'] as bool,
    actualRefusal: json['actual_refusal'] as bool,
    claims: (json['claims'] as List<dynamic>)
        .map(
          (item) => _claimFromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
  );
}

ClaimEvaluation _claimFromJson(Map<String, dynamic> json) {
  return ClaimEvaluation(
    id: json['id'] as String,
    supported: json['supported'] as bool,
    supportingEvidenceIds: _stringList(json['supporting_evidence_ids']),
    citationIds: _stringList(json['citation_ids']),
  );
}

List<String> _stringList(dynamic value) {
  return (value as List<dynamic>)
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}
