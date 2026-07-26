import 'dart:convert';
import 'dart:io';

import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/agent/knowledge_search_service.dart';
import 'package:dlg_q/services/agent/search_query_term_service.dart';
import 'package:dlg_q/services/evaluation/correctness_evaluation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English phrase aliases preserve canonical retrieval concepts', () {
    const service = SearchQueryTermService();

    expect(
      service.terms('do all changes roll back together'),
      containsAll(['rollback', 'roll back', 'rolls them back']),
    );
  });

  test('labeled set keeps canonical and paraphrased evidence at rank one', () {
    final fixture = _loadFixture();
    final corpus = _buildCorpus(fixture);
    const search = KnowledgeSearchService();
    final casesByVariant = <String, List<RetrievalEvaluationCase>>{};

    for (final group in _mapList(fixture['query_groups'])) {
      final relevant = _stringList(group['relevant_evidence_ids']);
      for (final query in _mapList(group['queries'])) {
        final results = search.search(
          query: query['text'] as String,
          corpus: corpus,
        );
        final chunks = results
            .where(
              (result) => result.type == KnowledgeSearchResultType.sourceChunk,
            )
            .toList();
        final rankedIds = chunks
            .map((result) => result.sourceChunkId)
            .whereType<String>()
            .toList();

        expect(rankedIds, isNotEmpty, reason: query['id'] as String);
        expect(rankedIds.first, relevant.first, reason: query['id'] as String);
        expect(chunks.first.trustLevel, isNot(SourceTrustLevel.userNote));
        expect(chunks.first.scoreBreakdown.reasonLabels, isNotEmpty);

        final variant = query['variant'] as String;
        casesByVariant.putIfAbsent(variant, () => []).add(
              RetrievalEvaluationCase(
                id: query['id'] as String,
                relevantEvidenceIds: relevant,
                rankedEvidenceIds: rankedIds,
              ),
            );
      }
    }

    expect(casesByVariant.keys, {
      'canonical',
      'zh_paraphrase',
      'en_paraphrase',
    });
    for (final entry in casesByVariant.entries) {
      final report = const CorrectnessEvaluationService().evaluate(
        retrievalCases: entry.value,
        generationCases: const [],
        topK: 1,
      );
      expect(report.retrievalCaseCount, 6, reason: entry.key);
      expect(report.recallAtK, 1, reason: entry.key);
      expect(report.meanReciprocalRank, 1, reason: entry.key);
    }
  });

  test('claim annotations separate quote presence from semantic support', () {
    final fixture = _loadFixture();
    final chunks = {
      for (final chunk in _mapList(fixture['chunks']))
        chunk['id'] as String: chunk,
    };
    final annotations = _mapList(fixture['claim_annotations']);

    expect(annotations.map((item) => item['support']).toSet(), {
      'full',
      'partial',
      'none',
    });
    for (final annotation in annotations) {
      final evidence = chunks[annotation['evidence_id']];
      expect(evidence, isNotNull, reason: annotation['id'] as String);
      expect((evidence!['locator'] as String).trim(), isNotEmpty);
      expect((evidence['content'] as String).trim(), isNotEmpty);
      expect((annotation['claim'] as String).trim(), isNotEmpty);
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

Map<String, dynamic> _loadFixture() {
  return _map(
    jsonDecode(
      File(
        'test/fixtures/evaluation/correctness_labeled_set_v1.json',
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
