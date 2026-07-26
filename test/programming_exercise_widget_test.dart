import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/programming_exercise_repository.dart';
import 'package:dlg_q/data/repositories/source_chunk_repository.dart';
import 'package:dlg_q/features/agent/programming_exercise_screen.dart';
import 'package:dlg_q/services/openai_service.dart';

import 'support/fake_programming_review_closure_service.dart';

void main() {
  testWidgets('verifies, evaluates, repairs and creates a pending retest',
      (tester) async {
    final now = DateTime(2026, 7, 15);
    final point = KnowledgePoint(
      id: 'return-path',
      title: 'Return path',
      summary: 'A source-backed return path.',
      masteryLevel: 20,
      createdAt: now,
      updatedAt: now,
    );
    final chunk = SourceChunk(
      id: 'chunk-code',
      sourceId: 'source-code',
      chunkIndex: 0,
      content: 'return persistedValue;',
      locator: 'lib/store.dart:10-10',
      contentHash: 'hash-code',
      createdAt: now,
    );
    final knowledgeRepository = _FakeKnowledgePointRepository(point, chunk.id);
    final chunkRepository = _FakeSourceChunkRepository(chunk);
    final exerciseRepository = _FakeProgrammingExerciseRepository();
    final openai = _SequencedOpenAIService([
      {
        'exercises': [
          {
            'kind': 'code_reading',
            'prompt': 'What value does the cited function return?',
            'reference_answer': 'It returns persistedValue.',
            'concept_accuracy_criterion': 'Identify persistedValue.',
            'reasoning_process_criterion': 'Trace the return statement.',
            'evidence_use_criterion': 'Use the cited line.',
            'clarity_criterion': 'Name the value directly.',
            'citation_ids': ['chunk-code'],
          },
        ],
      },
      {
        'feedback': 'The answer confused a temporary value with the return.',
        'concept_accuracy_score': 45,
        'reasoning_process_score': 55,
        'evidence_use_score': 40,
        'clarity_score': 80,
        'misconception_code': 'return_path_confusion',
        'misconception_label': '把临时值误认为实际返回值',
        'repair_explanation':
            'The cited return statement names persistedValue.',
        'citation_ids': ['chunk-code'],
        'evidence_sufficient': true,
        'claims': [
          {
            'section': 'feedback',
            'text': 'The answer confused a temporary value with the return.',
            'evidence': [
              {
                'citation_id': 'chunk-code',
                'quote': 'return persistedValue;',
              },
            ],
          },
          {
            'section': 'repair_explanation',
            'text': 'The cited return statement names persistedValue.',
            'evidence': [
              {
                'citation_id': 'chunk-code',
                'quote': 'return persistedValue;',
              },
            ],
          },
        ],
        'retest_exercise': {
          'kind': 'code_reading',
          'prompt': 'Trace the same return path from the final statement.',
          'reference_answer': 'The final statement returns persistedValue.',
          'concept_accuracy_criterion': 'Identify persistedValue.',
          'reasoning_process_criterion': 'Trace from the final statement.',
          'evidence_use_criterion': 'Use the cited line.',
          'clarity_criterion': 'State the value directly.',
          'citation_ids': ['chunk-code'],
        },
      },
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openaiServiceProvider.overrideWithValue(openai),
          knowledgePointRepositoryProvider
              .overrideWithValue(knowledgeRepository),
          sourceChunkRepositoryProvider.overrideWithValue(chunkRepository),
          programmingExerciseRepositoryProvider
              .overrideWithValue(exerciseRepository),
          programmingReviewClosureServiceProvider.overrideWithValue(
            FakeProgrammingReviewClosureService(),
          ),
          sourceProvider.overrideWith(
            (ref, sourceId) async => Source(
              id: sourceId,
              title: 'Store source',
              type: SourceType.project,
              trustLevel: SourceTrustLevel.sourceCode,
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ],
        child: MaterialApp(
          home: ProgrammingExerciseScreen(knowledgePoint: point),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('generate-programming-exercises')),
    );
    await tester.pumpAndSettle();
    expect(find.text('What value does the cited function return?'),
        findsOneWidget);

    await tester.tap(find.text('查看依据并核验'));
    await tester.pumpAndSettle();
    expect(find.text('It returns persistedValue.'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('confirm-programming-exercise-verification'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('programming-exercise-answer-input')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('programming-exercise-answer-input')),
      'It returns a temporary value.',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('submit-programming-exercise-answer')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('submit-programming-exercise-answer')),
    );
    await tester.pumpAndSettle();

    expect(find.text('代码阅读 · 复测'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();

    expect(find.textContaining('confused a temporary value'), findsOneWidget);
    expect(find.textContaining('把临时值误认为实际返回值'), findsOneWidget);
    expect(exerciseRepository.exercises, hasLength(2));
    expect(exerciseRepository.exercises.last.sourceStatus.name, 'pending');
    expect(exerciseRepository.attempts.single.formalMasteryApplied, isTrue);
    expect(knowledgeRepository.point.masteryLevel, isNot(20));
  });
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  KnowledgePoint point;
  final String chunkId;

  _FakeKnowledgePointRepository(this.point, this.chunkId)
      : super(DatabaseHelper());

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    return id == point.id ? point : null;
  }

  @override
  Future<void> updateKnowledgePoint(KnowledgePoint point) async {
    this.point = point;
  }

  @override
  Future<List<KnowledgePointSource>> getKnowledgePointSources(String id) async {
    return [
      KnowledgePointSource(
        knowledgePointId: point.id,
        sourceChunkId: chunkId,
      ),
    ];
  }
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final SourceChunk chunk;

  _FakeSourceChunkRepository(this.chunk) : super(DatabaseHelper());

  @override
  Future<SourceChunk?> getSourceChunk(String id) async {
    return id == chunk.id ? chunk : null;
  }
}

class _FakeProgrammingExerciseRepository extends ProgrammingExerciseRepository {
  final List<ProgrammingExercise> exercises = [];
  final List<ProgrammingExerciseAttempt> attempts = [];

  _FakeProgrammingExerciseRepository() : super(DatabaseHelper());

  @override
  Future<List<ProgrammingExercise>> getExercisesForKnowledgePoint(
    String knowledgePointId,
  ) async {
    return exercises
        .where((exercise) => exercise.knowledgePointId == knowledgePointId)
        .toList();
  }

  @override
  Future<String> insertExercise(ProgrammingExercise exercise) async {
    exercises.add(exercise);
    return exercise.id;
  }

  @override
  Future<void> updateExercise(ProgrammingExercise exercise) async {
    final index = exercises.indexWhere((item) => item.id == exercise.id);
    exercises[index] = exercise;
  }

  @override
  Future<List<ProgrammingExerciseAttempt>> getAttemptsForExercise(
    String exerciseId,
  ) async {
    return attempts
        .where((attempt) => attempt.exerciseId == exerciseId)
        .toList();
  }

  @override
  Future<String> insertAttempt(ProgrammingExerciseAttempt attempt) async {
    attempts.add(attempt);
    return attempt.id;
  }

  @override
  Future<void> updateAttempt(ProgrammingExerciseAttempt attempt) async {
    final index = attempts.indexWhere((item) => item.id == attempt.id);
    attempts[index] = attempt;
  }
}

class _SequencedOpenAIService extends OpenAIService {
  final List<Object> responses;
  int _index = 0;

  _SequencedOpenAIService(this.responses);

  @override
  Future<bool> hasApiKey({String? providerId}) async => true;

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    return jsonEncode(responses[_index++]);
  }
}
