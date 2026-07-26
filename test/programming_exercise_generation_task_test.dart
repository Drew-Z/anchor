import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/ai/tasks/programming_exercise_generation_task.dart';
import 'package:dlg_q/services/openai_service.dart';

void main() {
  test('keeps one complete source-grounded exercise per kind', () async {
    final openai = _FakeOpenAIService({
      'exercises': [
        _draftJson(
          kind: 'explanation',
          prompt: 'Explain the state transition.',
          citations: ['chunk-state', 'invented'],
        ),
        _draftJson(
          kind: 'explanation',
          prompt: 'Duplicate explanation.',
          citations: ['chunk-state'],
        ),
        _draftJson(
          kind: 'code_reading',
          prompt: 'Trace the cited function.',
          citations: ['chunk-code'],
        ),
        _draftJson(
          kind: 'implementation',
          prompt: 'Implement an unsupported API.',
          citations: ['invented'],
        ),
      ],
    });

    final result = await ProgrammingExerciseGenerationTask(openai).run(
      knowledgePoint: _point(),
      sourceChunks: [
        _chunk('chunk-state', 'The state moves from idle to complete.'),
        _chunk('chunk-code', 'return persistedValue;'),
      ],
    );

    expect(result.isSuccess, isTrue);
    expect(result.requireData, hasLength(2));
    expect(
      result.requireData.map((draft) => draft.kind),
      [
        ProgrammingExerciseKind.explanation,
        ProgrammingExerciseKind.codeReading,
      ],
    );
    expect(result.requireData.first.citationIds, ['chunk-state']);
    expect(openai.systemPrompt, contains('每种类型最多一道'));
    expect(openai.userContent, contains('id: chunk-code'));
  });

  test('rejects generation without source chunks before calling AI', () async {
    final openai = _FakeOpenAIService({});
    final result = await ProgrammingExerciseGenerationTask(openai).run(
      knowledgePoint: _point(),
      sourceChunks: const [],
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('来源片段'));
    expect(openai.callCount, 0);
  });
}

Map<String, Object> _draftJson({
  required String kind,
  required String prompt,
  required List<String> citations,
}) {
  return {
    'kind': kind,
    'prompt': prompt,
    'reference_answer': 'A source-backed reference answer.',
    'concept_accuracy_criterion': 'Use the correct concept.',
    'reasoning_process_criterion': 'Show the causal steps.',
    'evidence_use_criterion': 'Use the cited code or documentation.',
    'clarity_criterion': 'State the answer clearly.',
    'citation_ids': citations,
  };
}

KnowledgePoint _point() {
  return KnowledgePoint(
    id: 'state-machine',
    title: 'State machine',
    summary: 'A documented state transition.',
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  );
}

SourceChunk _chunk(String id, String content) {
  return SourceChunk(
    id: id,
    sourceId: 'source',
    chunkIndex: 0,
    content: content,
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
