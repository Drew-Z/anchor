import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/ai/tasks/concept_prerequisite_task.dart';
import 'package:dlg_q/services/openai_service.dart';

void main() {
  test('keeps only cited prerequisite candidates over known concepts',
      () async {
    final openai = _FakeOpenAIService({
      'relations': [
        {
          'knowledge_point_id': 'future',
          'prerequisite_knowledge_point_id': 'async',
          'rationale': 'Uses an unrelated citation.',
          'citation_ids': ['chunk-unrelated'],
        },
        {
          'knowledge_point_id': 'future',
          'prerequisite_knowledge_point_id': 'async',
          'rationale': 'The source defines Future before async return values.',
          'citation_ids': ['chunk-async', 'invented'],
        },
        {
          'knowledge_point_id': 'async',
          'prerequisite_knowledge_point_id': 'future',
          'rationale': 'Reverse duplicate.',
          'citation_ids': ['chunk-future'],
        },
        {
          'knowledge_point_id': 'missing',
          'prerequisite_knowledge_point_id': 'async',
          'rationale': 'Unknown point.',
          'citation_ids': ['chunk-async'],
        },
        {
          'knowledge_point_id': 'future',
          'prerequisite_knowledge_point_id': 'future',
          'rationale': 'Self loop.',
          'citation_ids': ['chunk-future'],
        },
      ],
    });
    final task = ConceptPrerequisiteTask(openai);

    final result = await task.run(
      knowledgePoints: [
        _point('async', 'async'),
        _point('future', 'Future'),
        _point('unrelated', 'Unrelated'),
      ],
      sourceChunksByKnowledgePointId: {
        'async': [_chunk('chunk-async')],
        'future': [_chunk('chunk-future')],
        'unrelated': [_chunk('chunk-unrelated')],
      },
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.relations, hasLength(1));
    final relation = result.requireData.relations.single;
    expect(relation.prerequisiteKnowledgePointId, 'async');
    expect(relation.knowledgePointId, 'future');
    expect(relation.citationIds, ['chunk-async']);
    expect(openai.systemPrompt, contains('没有充分依据时返回空 relations'));
    expect(openai.userContent, contains('id: chunk-future'));
    expect(openai.temperature, 0.1);
  });

  test('requires two source-backed concepts', () async {
    final task = ConceptPrerequisiteTask(_FakeOpenAIService({}));
    final result = await task.run(
      knowledgePoints: [_point('async', 'async')],
      sourceChunksByKnowledgePointId: {
        'async': [_chunk('chunk-async')],
      },
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('至少需要两个'));
  });
}

KnowledgePoint _point(String id, String title) {
  return KnowledgePoint(
    id: id,
    title: title,
    summary: '$title summary',
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  );
}

SourceChunk _chunk(String id) {
  return SourceChunk(
    id: id,
    sourceId: 'source',
    chunkIndex: 0,
    content: 'Official documentation content for $id.',
    locator: 'snapshot:L1-L1',
    contentHash: 'hash-$id',
    createdAt: DateTime(2026, 7, 15),
  );
}

class _FakeOpenAIService extends OpenAIService {
  final Object response;
  String systemPrompt = '';
  String userContent = '';
  double? temperature;

  _FakeOpenAIService(this.response);

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    this.systemPrompt = systemPrompt;
    this.userContent = userContent;
    this.temperature = temperature;
    return jsonEncode(response);
  }
}
