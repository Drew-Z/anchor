import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/ai/tasks/knowledge_answer_task.dart';
import 'package:anchor_learning/services/openai_service.dart';

void main() {
  test('keeps only answer claims with verifiable evidence quotes', () async {
    final task = KnowledgeAnswerTask(
      _FakeOpenAIService({
        'answer': 'A supported fact. An invented fact.',
        'key_points': ['Unsafe aggregate key point.'],
        'follow_up_questions': ['What should be verified next?'],
        'source_gaps': <String>[],
        'citation_ids': ['chunk-json'],
        'claims': [
          {
            'section': 'answer',
            'text': 'JSON mode returns valid JSON.',
            'evidence': [
              {
                'citation_id': 'chunk-json',
                'quote': 'returns valid JSON',
              },
            ],
          },
          {
            'section': 'answer',
            'text': 'JSON mode guarantees every schema.',
            'evidence': [
              {
                'citation_id': 'chunk-json',
                'quote': 'guarantees every schema',
              },
            ],
          },
        ],
      }),
    );

    final result = await task.run(
      question: 'What does JSON mode guarantee?',
      sourceChunks: [_chunk()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.answer, 'JSON mode returns valid JSON.');
    expect(result.requireData.keyPoints, isEmpty);
    expect(
      result.requireData.groundingDisposition,
      GroundingDisposition.partial,
    );
    expect(result.requireData.uncoveredClaims, hasLength(1));
    expect(result.requireData.sourceGaps, isNotEmpty);
    expect(result.requireData.citationIds, ['chunk-json']);
  });

  test('refuses an answer when no claim has a valid evidence quote', () async {
    final task = KnowledgeAnswerTask(
      _FakeOpenAIService({
        'answer': 'An unsupported answer.',
        'key_points': <String>[],
        'follow_up_questions': <String>[],
        'source_gaps': <String>[],
        'citation_ids': ['chunk-json'],
        'claims': [
          {
            'section': 'answer',
            'text': 'An unsupported answer.',
            'evidence': [
              {'citation_id': 'invented', 'quote': 'invented'},
            ],
          },
        ],
      }),
    );

    final result = await task.run(
      question: 'What is unsupported?',
      sourceChunks: [_chunk()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.answer, isEmpty);
    expect(
      result.requireData.groundingDisposition,
      GroundingDisposition.refused,
    );
    expect(result.requireData.sourceGaps, isNotEmpty);
    expect(result.requireData.citationIds, isEmpty);
  });

  test('builds a fully grounded answer and key points from claims', () async {
    final task = KnowledgeAnswerTask(
      _FakeOpenAIService({
        'answer': 'Ignored aggregate answer.',
        'key_points': ['Ignored aggregate key point.'],
        'follow_up_questions': ['How is schema validation added?'],
        'source_gaps': <String>[],
        'citation_ids': ['chunk-json'],
        'claims': [
          {
            'section': 'answer',
            'text': 'JSON mode returns valid JSON.',
            'evidence': [
              {
                'citation_id': 'chunk-json',
                'quote': 'returns valid JSON',
              },
            ],
          },
          {
            'section': 'key_point',
            'text': 'Schema conformance is not guaranteed.',
            'evidence': [
              {
                'citation_id': 'chunk-json',
                'quote': 'does not guarantee schema conformance',
              },
            ],
          },
        ],
      }),
    );

    final result = await task.run(
      question: 'What does JSON mode guarantee?',
      sourceChunks: [_chunk()],
    );

    expect(result.isSuccess, isTrue);
    expect(
      result.requireData.groundingDisposition,
      GroundingDisposition.grounded,
    );
    expect(result.requireData.keyPoints, [
      'Schema conformance is not guaranteed.',
    ]);
    expect(result.requireData.claims, hasLength(2));
  });
}

SourceChunk _chunk() {
  return SourceChunk(
    id: 'chunk-json',
    sourceId: 'source-json',
    chunkIndex: 0,
    content:
        'JSON mode returns valid JSON but does not guarantee schema conformance.',
    createdAt: DateTime.utc(2026, 7, 15),
  );
}

class _FakeOpenAIService extends OpenAIService {
  final Object response;

  _FakeOpenAIService(this.response);

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    return jsonEncode(response);
  }
}
