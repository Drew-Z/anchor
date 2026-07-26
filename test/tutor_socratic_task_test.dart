import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/models/tutor_turn.dart';
import 'package:dlg_q/services/ai/tasks/tutor_socratic_task.dart';
import 'package:dlg_q/services/openai_service.dart';

void main() {
  test(
      'grounds feedback and one next question in current and prerequisite evidence',
      () async {
    final openai = _FakeOpenAIService({
      'feedback': 'You identified completion but omitted the returned value.',
      'reference_answer': 'Completion makes the value available.',
      'misconception': 'Completion and construction were treated as identical.',
      'next_question': 'How does async use the completed value?',
      'citation_ids': ['chunk-future', 'chunk-async', 'invented'],
      'evidence_sufficient': true,
      'accuracy_score': 120,
      'claims': [
        _claim(
          'feedback',
          'You identified completion but omitted the returned value.',
          'chunk-future',
        ),
        _claim(
          'reference_answer',
          'Completion makes the value available.',
          'chunk-future',
        ),
        _claim(
          'misconception',
          'Completion and construction were treated as identical.',
          'chunk-async',
        ),
      ],
    });
    final task = TutorSocraticTask(openai);
    final previousTurn = TutorTurn(
      id: 'turn-0',
      sessionId: 'session',
      knowledgePointId: 'future',
      questionText: 'What is a Future?',
      userAnswer: 'A later result.',
      aiFeedback: 'Name completion.',
      createdAt: DateTime(2026, 7, 15),
    );

    final result = await task.run(
      knowledgePoint: _point('future', 'Future'),
      question: 'What becomes available on completion?',
      userAnswer: 'The Future finishes.',
      sourceChunks: [_chunk('chunk-future')],
      prerequisiteKnowledgePoints: [_point('async', 'async')],
      prerequisiteChunksByKnowledgePointId: {
        'async': [_chunk('chunk-async')],
        'unconfirmed': [_chunk('chunk-unconfirmed')],
      },
      previousTurns: [previousTurn],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.citationIds, ['chunk-future', 'chunk-async']);
    expect(result.requireData.accuracyScore, 100);
    expect(result.requireData.nextQuestion, contains('async'));
    expect(openai.systemPrompt, contains('每轮只处理一个问题和一个用户回答'));
    expect(openai.userContent, contains('feedback: Name completion.'));
    expect(openai.userContent, contains('id: chunk-async'));
    expect(openai.userContent, isNot(contains('chunk-unconfirmed')));
  });

  test('clears the next question when source evidence is insufficient',
      () async {
    final task = TutorSocraticTask(
      _FakeOpenAIService({
        'feedback': '来源不足，无法判断这个运行时细节。',
        'reference_answer': '',
        'misconception': '',
        'next_question': 'This must not continue?',
        'citation_ids': ['invented'],
        'evidence_sufficient': false,
        'accuracy_score': 40,
        'claims': <Object>[],
      }),
    );

    final result = await task.run(
      knowledgePoint: _point('future', 'Future'),
      question: 'Which queue runs this callback?',
      userAnswer: 'The source does not say.',
      sourceChunks: [_chunk('chunk-future')],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.evidenceSufficient, isFalse);
    expect(result.requireData.nextQuestion, isEmpty);
    expect(result.requireData.citationIds, isEmpty);
  });

  test('requires a user answer before calling AI', () async {
    final openai = _FakeOpenAIService({});
    final result = await TutorSocraticTask(openai).run(
      knowledgePoint: _point('future', 'Future'),
      question: 'What completes?',
      userAnswer: '   ',
      sourceChunks: [_chunk('chunk-future')],
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('先回答'));
    expect(openai.callCount, 0);
  });
}

Map<String, Object> _claim(
  String section,
  String text,
  String citationId,
) {
  return {
    'section': section,
    'text': text,
    'evidence': [
      {
        'citation_id': citationId,
        'quote': 'Official documentation content for $citationId.',
      },
    ],
  };
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
  int callCount = 0;
  String systemPrompt = '';
  String userContent = '';

  _FakeOpenAIService(this.response);

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    callCount += 1;
    this.systemPrompt = systemPrompt;
    this.userContent = userContent;
    return jsonEncode(response);
  }
}
