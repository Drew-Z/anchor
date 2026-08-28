import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/knowledge_answer_context_service.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/search_query_term_service.dart';
import 'package:anchor_learning/services/evaluation/correctness_evaluation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mixed-language query expansion preserves plain English terms', () {
    const service = SearchQueryTermService();

    expect(service.terms('JSON schema guarantee'), [
      'json',
      'schema',
      'guarantee',
    ]);
    expect(
      service.terms('JSON模式是否保证schema一致性'),
      containsAll([
        'json',
        'schema',
        'mode',
        '模式',
        'guarantee',
        '保证',
        'conformance',
        '一致性',
      ]),
    );
  });

  test('stress corpus keeps grounded evidence first and explainable', () {
    final fixture = _loadFixture();
    final corpus = _buildCorpus(fixture);
    const searchService = KnowledgeSearchService();
    const contextService = KnowledgeAnswerContextService();
    final evaluationCases = <RetrievalEvaluationCase>[];

    for (final evaluationCase in _mapList(fixture['retrieval_cases'])) {
      final results = searchService.search(
        query: evaluationCase['query'] as String,
        corpus: corpus,
      );
      final chunkResults = results
          .where(
            (result) => result.type == KnowledgeSearchResultType.sourceChunk,
          )
          .toList();
      final rankedIds = chunkResults
          .map((result) => result.sourceChunkId)
          .whereType<String>()
          .toList();
      final expectedFirst =
          evaluationCase['expected_first_evidence_id'] as String;

      expect(rankedIds.first, expectedFirst, reason: evaluationCase['id']);
      final firstResult = chunkResults.first;
      expect(firstResult.scoreBreakdown.reasonLabels, isNotEmpty);
      expect(
        firstResult.scoreBreakdown.reasonLabels,
        contains(startsWith('来源可信度')),
      );

      final selection = contextService.select(
        results: results,
        sourceChunks: corpus.sourceChunks,
        limit: 1,
      );
      expect(selection.chunks.single.id, expectedFirst);
      expect(selection.chunks.single.locator, isNotEmpty);
      expect(
        selection.chunks.single.content,
        contains(evaluationCase['expected_quote'] as String),
      );

      evaluationCases.add(
        RetrievalEvaluationCase(
          id: evaluationCase['id'] as String,
          relevantEvidenceIds:
              _stringList(evaluationCase['relevant_evidence_ids']),
          rankedEvidenceIds: rankedIds,
        ),
      );
    }

    final report = const CorrectnessEvaluationService().evaluate(
      retrievalCases: evaluationCases,
      generationCases: const [],
      topK: fixture['top_k'] as int,
    );
    expect(report.retrievalCaseCount, 3);
    expect(report.recallAtK, 1);
    expect(report.meanReciprocalRank, 1);
  });
}

KnowledgeSearchCorpus _buildCorpus(Map<String, dynamic> fixture) {
  final now = DateTime.utc(2026, 7, 17);
  final sources = _mapList(fixture['sources']).map((item) {
    return Source(
      id: item['id'] as String,
      title: item['title'] as String,
      type: SourceType.fromString(item['type'] as String),
      trustLevel: SourceTrustLevel.fromString(item['trust_level'] as String),
      createdAt: now,
      updatedAt: now,
    );
  }).toList();
  final chunks = _mapList(fixture['chunks']).asMap().entries.map((entry) {
    final item = entry.value;
    return SourceChunk(
      id: item['id'] as String,
      sourceId: item['source_id'] as String,
      chunkIndex: entry.key,
      content: item['content'] as String,
      locator: item['locator'] as String?,
      createdAt: now,
    );
  }).toList();
  final generated = _map(fixture['generated_distractors']);
  final count = generated['count'] as int;
  for (var index = 0; index < count; index++) {
    final marker = index.isEven ? 'atomic transaction' : 'transaction rollback';
    chunks.add(
      SourceChunk(
        id: '${generated['id_prefix']}$index',
        sourceId: generated['source_id'] as String,
        chunkIndex: chunks.length,
        content: '${generated['content_prefix']} $index mentions $marker '
            'without defining the complete commit and rollback boundary.',
        locator: '${generated['locator_prefix']} $index',
        createdAt: now,
      ),
    );
  }
  return KnowledgeSearchCorpus(
    sources: sources,
    sourceChunks: chunks,
    knowledgePoints: const [],
    questions: const [],
  );
}

Map<String, dynamic> _loadFixture() {
  return _map(
    jsonDecode(
      File(
        'test/fixtures/evaluation/correctness_retrieval_stress_v1.json',
      ).readAsStringSync(),
    ),
  );
}

Map<String, dynamic> _map(Object? value) {
  return Map<String, dynamic>.from(value! as Map);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value! as List<dynamic>).map(_map).toList();
}

List<String> _stringList(Object? value) {
  return (value! as List<dynamic>).map((item) => item.toString()).toList();
}
