import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/ai/tasks/programming_exercise_evaluation_task.dart';
import 'package:dlg_q/services/openai_service.dart';

void main() {
  test('requires a readable misconception, repair and grounded retest on error',
      () async {
    final openai = _FakeOpenAIService({
      'feedback': 'The answer skipped the persisted return path.',
      'concept_accuracy_score': 45,
      'reasoning_process_score': 55,
      'evidence_use_score': -10,
      'clarity_score': 120,
      'misconception_code': 'return_path_confusion',
      'misconception_label': '把临时值误认为持久化返回值',
      'repair_explanation': 'Follow the cited return statement.',
      'citation_ids': ['chunk-code', 'invented'],
      'evidence_sufficient': true,
      'claims': [
        _claim('feedback', 'The answer skipped the persisted return path.'),
        _claim(
          'repair_explanation',
          'Follow the cited return statement.',
        ),
      ],
      'retest_exercise': {
        'kind': 'code_reading',
        'prompt': 'Trace the return statement in a different order.',
        'reference_answer': 'The persisted value is returned.',
        'concept_accuracy_criterion': 'Identify the persisted value.',
        'reasoning_process_criterion': 'Trace the statements in order.',
        'evidence_use_criterion': 'Point to the cited return statement.',
        'clarity_criterion': 'Name the value directly.',
        'citation_ids': ['chunk-code', 'invented'],
      },
    });

    final result = await ProgrammingExerciseEvaluationTask(openai).run(
      knowledgePoint: _point(),
      exercise: _exercise(),
      userAnswer: 'It returns a temporary value.',
      sourceChunks: [_chunk()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.evidenceUseScore, 0);
    expect(result.requireData.clarityScore, 100);
    expect(result.requireData.citationIds, ['chunk-code']);
    expect(
      result.requireData.retestExercise?.citationIds,
      ['chunk-code'],
    );
    expect(result.requireData.misconceptionCode, 'return_path_confusion');
    expect(openai.userContent, contains('user_answer'));
    expect(openai.systemPrompt, contains('平均分低于 80'));
  });

  test('rejects a low score without repair and retest', () async {
    final result = await ProgrammingExerciseEvaluationTask(
      _FakeOpenAIService({
        'feedback': 'The answer is incomplete.',
        'concept_accuracy_score': 50,
        'reasoning_process_score': 50,
        'evidence_use_score': 50,
        'clarity_score': 50,
        'misconception_code': '',
        'misconception_label': '',
        'repair_explanation': '',
        'citation_ids': ['chunk-code'],
        'evidence_sufficient': true,
        'claims': [
          _claim('feedback', 'The answer is incomplete.'),
        ],
        'retest_exercise': null,
      }),
    ).run(
      knowledgePoint: _point(),
      exercise: _exercise(),
      userAnswer: 'Incomplete answer.',
      sourceChunks: [_chunk()],
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('误区'));
  });

  test('clears a retest when evidence is insufficient', () async {
    final result = await ProgrammingExerciseEvaluationTask(
      _FakeOpenAIService({
        'feedback': '来源不足，无法评价运行时行为。',
        'concept_accuracy_score': 0,
        'reasoning_process_score': 0,
        'evidence_use_score': 0,
        'clarity_score': 0,
        'misconception_code': '',
        'misconception_label': '',
        'repair_explanation': '',
        'citation_ids': ['invented'],
        'evidence_sufficient': false,
        'claims': <Object>[],
        'retest_exercise': {
          'kind': 'implementation',
          'prompt': 'Unsupported retest.',
          'reference_answer': 'Unsupported answer.',
          'concept_accuracy_criterion': 'Unsupported.',
          'reasoning_process_criterion': 'Unsupported.',
          'evidence_use_criterion': 'Unsupported.',
          'clarity_criterion': 'Unsupported.',
          'citation_ids': ['invented'],
        },
      }),
    ).run(
      knowledgePoint: _point(),
      exercise: _exercise(),
      userAnswer: 'The runtime probably does this.',
      sourceChunks: [_chunk()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData.evidenceSufficient, isFalse);
    expect(result.requireData.citationIds, isEmpty);
    expect(result.requireData.retestExercise, isNull);
  });
}

Map<String, Object> _claim(String section, String text) {
  return {
    'section': section,
    'text': text,
    'evidence': [
      {
        'citation_id': 'chunk-code',
        'quote': 'return persistedValue;',
      },
    ],
  };
}

KnowledgePoint _point() {
  return KnowledgePoint(
    id: 'return-path',
    title: 'Return path',
    summary: 'A code-backed return path.',
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  );
}

ProgrammingExercise _exercise() {
  final now = DateTime(2026, 7, 15);
  return ProgrammingExercise(
    id: 'exercise',
    knowledgePointId: 'return-path',
    kind: ProgrammingExerciseKind.codeReading,
    prompt: 'What does the function return?',
    referenceAnswer: 'It returns the persisted value.',
    conceptAccuracyCriterion: 'Identify the value.',
    reasoningProcessCriterion: 'Trace the return path.',
    evidenceUseCriterion: 'Use the cited statement.',
    clarityCriterion: 'Answer directly.',
    sourceStatus: SourceStatus.verified,
    citationIds: const ['chunk-code'],
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk() {
  return SourceChunk(
    id: 'chunk-code',
    sourceId: 'source',
    chunkIndex: 0,
    content: 'return persistedValue;',
    locator: 'lib/store.dart:10-10',
    contentHash: 'hash',
    createdAt: DateTime(2026, 7, 15),
  );
}

class _FakeOpenAIService extends OpenAIService {
  final Object response;
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
    this.systemPrompt = systemPrompt;
    this.userContent = userContent;
    return jsonEncode(response);
  }
}
