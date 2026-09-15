import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/evaluation/correctness_evaluation_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixturePath = 'test/fixtures/evaluation/correctness_blind_proxy_v1.json';
const _baselinePath =
    'test/fixtures/evaluation/correctness_blind_proxy_baseline_v1.json';
const _frozenSha256 =
    'ec321abf442232fb01a682b5597994cdfff120628907f0867c08effdca14cee7';

void main() {
  test('frozen blind proxy records its first untuned retrieval baseline', () {
    final file = File(_fixturePath);
    expect(sha256.convert(file.readAsBytesSync()).toString(), _frozenSha256);
    final fixture = _map(jsonDecode(file.readAsStringSync()));
    final baseline = _map(jsonDecode(File(_baselinePath).readAsStringSync()));
    expect(baseline['fixture_sha256'], _frozenSha256);
    final baselineMetrics = _map(baseline['metrics']);
    final corpus = _buildCorpus(fixture);
    final casesByVariant = <String, List<RetrievalEvaluationCase>>{};
    const search = KnowledgeSearchService();

    for (final item in _mapList(fixture['cases'])) {
      final results = search.search(
        query: item['query'] as String,
        corpus: corpus,
      );
      final rankedIds = results
          .where(
            (result) => result.type == KnowledgeSearchResultType.sourceChunk,
          )
          .map((result) => result.sourceChunkId)
          .whereType<String>()
          .toList();
      casesByVariant.putIfAbsent(item['variant'] as String, () => []).add(
            RetrievalEvaluationCase(
              id: item['id'] as String,
              relevantEvidenceIds: _stringList(item['relevant_evidence_ids']),
              rankedEvidenceIds: rankedIds,
            ),
          );
    }

    expect(casesByVariant.keys, {'canonical', 'zh_natural', 'en_natural'});
    for (final entry in casesByVariant.entries) {
      final report = const CorrectnessEvaluationService().evaluate(
        retrievalCases: entry.value,
        generationCases: const [],
        topK: 1,
      );
      final floor = _map(baselineMetrics[entry.key]);
      expect(report.retrievalCaseCount, floor['case_count']);
      expect(report.recallAtK, greaterThanOrEqualTo(floor['recall_at_1']));
      expect(
        report.meanReciprocalRank,
        greaterThanOrEqualTo(floor['mrr']),
      );
    }
  });
}

KnowledgeSearchCorpus _buildCorpus(Map<String, dynamic> fixture) {
  final now = DateTime.utc(2026, 7, 17);
  return KnowledgeSearchCorpus(
    sources: _mapList(fixture['sources']).map((item) {
      return Source(
        id: item['id'] as String,
        title: item['title'] as String,
        uri: item['uri'] as String,
        type: SourceType.fromString(item['type'] as String),
        trustLevel: SourceTrustLevel.fromString(
          item['trust_level'] as String,
        ),
        createdAt: now,
        updatedAt: now,
      );
    }).toList(),
    sourceChunks: _mapList(fixture['chunks']).asMap().entries.map((entry) {
      final item = entry.value;
      return SourceChunk(
        id: item['id'] as String,
        sourceId: item['source_id'] as String,
        chunkIndex: entry.key,
        content: item['content'] as String,
        locator: item['locator'] as String,
        createdAt: now,
      );
    }).toList(),
    knowledgePoints: const [],
    questions: const [],
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
