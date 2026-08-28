import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/ai/tasks/tutor_explanation_task.dart';
import 'package:anchor_learning/services/openai_service.dart';

void main() {
  test('builds cited layers over the current point and confirmed prerequisites',
      () async {
    final openai = _FakeOpenAIService({
      'definition_and_intuition': 'A Future represents a later result.',
      'mechanism': 'Completion makes the result available.',
      'code_or_doc_example': 'The documentation example awaits a Future.',
      'boundaries': 'The source does not describe scheduling internals.',
      'misconceptions': ['A Future is not the result itself.'],
      'interview_expression': 'Define it, then explain completion.',
      'opening_question': 'What becomes available when a Future completes?',
      'citation_ids': ['chunk-future', 'chunk-async', 'invented'],
      'unsupported_layers': [],
      'evidence_sufficient': true,
    });
    final task = TutorExplanationTask(openai);

    final result = await task.run(
      knowledgePoint: _point('future', 'Future'),
      sourceChunks: [_chunk('chunk-future')],
      prerequisiteKnowledgePoints: [_point('async', 'async')],
      prerequisiteChunksByKnowledgePointId: {
        'async': [_chunk('chunk-async')],
        'unconfirmed': [_chunk('chunk-unconfirmed')],
      },
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.citationIds, ['chunk-future', 'chunk-async']);
    expect(result.requireData.openingQuestion, contains('Future'));
    expect(openai.systemPrompt, contains('opening_question：只提出一个问题'));
    expect(openai.userContent, contains('--- confirmed_prerequisites ---'));
    expect(openai.userContent, contains('id: chunk-async'));
    expect(openai.userContent, isNot(contains('chunk-unconfirmed')));
    expect(openai.temperature, 0.1);
  });

  test('stops before an opening question when evidence is insufficient',
      () async {
    final task = TutorExplanationTask(
      _FakeOpenAIService({
        'definition_and_intuition': '来源不足',
        'mechanism': '来源不足',
        'code_or_doc_example': '来源不足',
        'boundaries': '来源不足',
        'misconceptions': [],
        'interview_expression': '',
        'opening_question': 'This must be removed?',
        'citation_ids': ['invented'],
        'unsupported_layers': ['工作机制'],
        'evidence_sufficient': false,
      }),
    );

    final result = await task.run(
      knowledgePoint: _point('future', 'Future'),
      sourceChunks: [_chunk('chunk-future')],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.evidenceSufficient, isFalse);
    expect(result.requireData.openingQuestion, isEmpty);
    expect(result.requireData.citationIds, isEmpty);
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
