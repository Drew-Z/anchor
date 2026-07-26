import 'dart:convert';
import 'dart:io';

import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/deck.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/models/tutor_turn.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/programming_exercise_repository.dart';
import 'package:dlg_q/data/repositories/programming_review_action_repository.dart';
import 'package:dlg_q/data/repositories/question_repository.dart';
import 'package:dlg_q/services/ai/tasks/concept_prerequisite_task.dart';
import 'package:dlg_q/services/ai/tasks/programming_exercise_evaluation_task.dart';
import 'package:dlg_q/services/ai/tasks/programming_exercise_generation_task.dart';
import 'package:dlg_q/services/ai/tasks/tutor_explanation_task.dart';
import 'package:dlg_q/services/ai/tasks/tutor_socratic_task.dart';
import 'package:dlg_q/services/ingestion/programming_source_import_service.dart';
import 'package:dlg_q/services/openai_service.dart';
import 'package:dlg_q/services/scheduling/concept_learning_path_service.dart';
import 'package:dlg_q/services/scheduling/mastery_service.dart';
import 'package:dlg_q/services/scheduling/programming_review_closure_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test(
    'official docs and source code close the programming learning loop',
    () async {
      final fixture = await _loadFixture();
      final clock = _asMap(fixture['clock']);
      final expected = _asMap(fixture['expected']);
      final retrievedAt = DateTime.parse(clock['retrieved_at'] as String);
      final tutorAt = DateTime.parse(clock['tutor_at'] as String);
      final exerciseAt = DateTime.parse(clock['exercise_at'] as String);
      final reviewAt = DateTime.parse(clock['review_at'] as String);
      final databaseHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
      );
      addTearDown(databaseHelper.close);
      final knowledgePointRepository = KnowledgePointRepository(databaseHelper);
      final questionRepository = QuestionRepository(databaseHelper);
      final exerciseRepository = ProgrammingExerciseRepository(databaseHelper);
      final actionRepository =
          ProgrammingReviewActionRepository(databaseHelper);
      final closureService = ProgrammingReviewClosureService(
        knowledgePointRepository: knowledgePointRepository,
        questionRepository: questionRepository,
        exerciseRepository: exerciseRepository,
        actionRepository: actionRepository,
        databaseHelper: databaseHelper,
      );
      final openAI = _FixtureOpenAIService.fromFixture(
        _asMapList(fixture['ai_responses']),
      );

      const importService = ProgrammingSourceImportService();
      final chunksBySourceId = <String, List<SourceChunk>>{};
      for (final sourceData in _asMapList(fixture['sources'])) {
        final snapshot = importService.buildSnapshot(
          draft: ProgrammingSourceImportDraft(
            title: sourceData['title'] as String,
            content: sourceData['content'] as String,
            trustLevel: SourceTrustLevel.fromString(
              sourceData['trust_level'] as String,
            ),
            uri: sourceData['uri'] as String,
            publisher: sourceData['publisher'] as String,
            revision: sourceData['revision'] as String,
            licenseExpression: sourceData['license_expression'] as String,
          ),
          sourceId: sourceData['id'] as String,
          retrievedAt: retrievedAt,
        );
        await databaseHelper.insertSource(snapshot.source);
        for (final chunk in snapshot.chunks) {
          await databaseHelper.insertSourceChunk(chunk);
        }
        chunksBySourceId[snapshot.source.id] = snapshot.chunks;
      }
      final persistedSources = await databaseHelper.getAllSources();
      expect(
        persistedSources.map((source) => source.trustLevel).toSet(),
        {
          SourceTrustLevel.officialDoc,
          SourceTrustLevel.sourceCode,
        },
      );
      expect(
        persistedSources.every((source) => source.contentHash.length == 64),
        isTrue,
      );

      final points = <KnowledgePoint>[];
      final chunksByPointId = <String, List<SourceChunk>>{};
      for (final pointData in _asMapList(fixture['knowledge_points'])) {
        final point = KnowledgePoint(
          id: pointData['id'] as String,
          title: pointData['title'] as String,
          summary: pointData['summary'] as String,
          kind: KnowledgePointKind.concept,
          masteryLevel: pointData['mastery_level'] as int,
          difficulty: pointData['difficulty'] as int,
          createdAt: retrievedAt,
          updatedAt: retrievedAt,
        );
        final sourceId = pointData['source_id'] as String;
        final chunks = chunksBySourceId[sourceId]!;
        await knowledgePointRepository.insertKnowledgePoint(point);
        for (final chunk in chunks) {
          await knowledgePointRepository.addKnowledgePointSource(
            KnowledgePointSource(
              knowledgePointId: point.id,
              sourceChunkId: chunk.id,
            ),
          );
        }
        points.add(point);
        chunksByPointId[point.id] = chunks;
      }
      final pointsById = {for (final point in points) point.id: point};
      final target = pointsById['persisted-return-path']!;
      final prerequisite = pointsById['state-ownership']!;

      final prerequisiteResult = await ConceptPrerequisiteTask(openAI).run(
        knowledgePoints: points,
        sourceChunksByKnowledgePointId: chunksByPointId,
      );
      expect(
        prerequisiteResult.isSuccess,
        isTrue,
        reason: prerequisiteResult.errorMessage,
      );
      const pathService = ConceptLearningPathService();
      final sanitized = pathService.sanitize(
        drafts: prerequisiteResult.requireData.relations,
        knowledgePoints: points,
        sourceBackedKnowledgePointIds: pointsById.keys.toSet(),
        citationIdsByKnowledgePointId: {
          for (final entry in chunksByPointId.entries)
            entry.key: entry.value.map((chunk) => chunk.id).toSet(),
        },
      );
      expect(sanitized.accepted, hasLength(1));
      await knowledgePointRepository.replaceKnowledgePointPrerequisites(
        scopeKnowledgePointIds: pointsById.keys.toList(),
        relations: sanitized.accepted
            .map((draft) => draft.toRelation(retrievedAt))
            .toList(),
      );
      final path = pathService.buildPath(
        knowledgePoints: points,
        relations: sanitized.accepted,
      );
      expect(
        path.steps.map((step) => step.knowledgePoint.id),
        List<String>.from(expected['path_order'] as List),
      );
      expect(path.steps.last.prerequisitesMastered, isFalse);

      await databaseHelper.insertDeck(
        Deck(
          id: 'programming-learning-deck',
          title: 'Programming learning closure',
          createdAt: retrievedAt,
          updatedAt: retrievedAt,
        ),
      );
      for (final questionData in _asMapList(fixture['questions'])) {
        final sourceId = questionData['source_id'] as String;
        final chunkId = chunksBySourceId[sourceId]!.single.id;
        await questionRepository.insertQuestion(
          Question(
            id: questionData['id'] as String,
            deckId: 'programming-learning-deck',
            knowledgePointId: questionData['knowledge_point_id'] as String,
            type: QuestionType.fillBlank,
            content: questionData['content'] as String,
            answer: questionData['answer'] as String,
            sourceStatus: SourceStatus.fromString(
              questionData['source_status'] as String,
            ),
            citationIds: [chunkId],
          ),
        );
      }

      final targetChunks = chunksByPointId[target.id]!;
      final prerequisiteChunks = chunksByPointId[prerequisite.id]!;
      final explanation = await TutorExplanationTask(openAI).run(
        knowledgePoint: target,
        sourceChunks: targetChunks,
        prerequisiteKnowledgePoints: [prerequisite],
        prerequisiteChunksByKnowledgePointId: {
          prerequisite.id: prerequisiteChunks,
        },
      );
      expect(explanation.isSuccess, isTrue, reason: explanation.errorMessage);
      expect(explanation.requireData.openingQuestion, isNotEmpty);
      expect(explanation.requireData.citationIds, hasLength(2));

      final sessionData = _asMap(fixture['session']);
      final session = LearningSession(
        id: sessionData['id'] as String,
        mode: LearningSessionMode.tutor,
        targetId: target.id,
        startedAt: tutorAt,
      );
      await databaseHelper.insertLearningSession(session);
      final socratic = await TutorSocraticTask(openAI).run(
        knowledgePoint: target,
        question: explanation.requireData.openingQuestion,
        userAnswer: sessionData['user_answer'] as String,
        sourceChunks: targetChunks,
        prerequisiteKnowledgePoints: [prerequisite],
        prerequisiteChunksByKnowledgePointId: {
          prerequisite.id: prerequisiteChunks,
        },
      );
      expect(socratic.isSuccess, isTrue, reason: socratic.errorMessage);
      final tutorFeedback = socratic.requireData;
      final tutorTurn = TutorTurn(
        id: 'tutor-turn-persisted-return-path',
        sessionId: session.id,
        knowledgePointId: target.id,
        questionText: explanation.requireData.openingQuestion,
        userAnswer: sessionData['user_answer'] as String,
        aiFeedback: tutorFeedback.feedback,
        referenceAnswer: tutorFeedback.referenceAnswer,
        misconception: tutorFeedback.misconception,
        nextQuestion: tutorFeedback.nextQuestion,
        citationIds: tutorFeedback.citationIds,
        prerequisiteKnowledgePointIds: [prerequisite.id],
        evidenceSufficient: tutorFeedback.evidenceSufficient,
        accuracyScore: tutorFeedback.accuracyScore,
        groundedClaims: tutorFeedback.claims,
        groundingDisposition: tutorFeedback.groundingDisposition,
        createdAt: tutorAt,
      );
      final tutorAction = await closureService.closeTutorTurn(
        turn: tutorTurn,
        now: tutorAt,
      );
      expect(tutorAction, isNotNull);
      expect(
        tutorAction!.prerequisiteKnowledgePointIds,
        [prerequisite.id],
      );

      final exerciseData = _asMap(fixture['exercise']);
      final generation = await ProgrammingExerciseGenerationTask(openAI).run(
        knowledgePoint: target,
        sourceChunks: targetChunks,
      );
      expect(generation.isSuccess, isTrue, reason: generation.errorMessage);
      var exercise = generation.requireData.single.toExercise(
        id: exerciseData['id'] as String,
        knowledgePointId: target.id,
        createdAt: exerciseAt,
      );
      await exerciseRepository.insertExercise(exercise);
      exercise = exercise.copyWith(
        sourceStatus: SourceStatus.verified,
        updatedAt: exerciseAt.add(const Duration(minutes: 1)),
      );
      await exerciseRepository.updateExercise(exercise);

      final evaluation = await ProgrammingExerciseEvaluationTask(openAI).run(
        knowledgePoint: target,
        exercise: exercise,
        userAnswer: exerciseData['user_answer'] as String,
        sourceChunks: targetChunks,
      );
      expect(evaluation.isSuccess, isTrue, reason: evaluation.errorMessage);
      final evaluationData = evaluation.requireData;
      expect(
        evaluationData.misconceptionCode,
        expected['misconception_code'],
      );
      var attempt = ProgrammingExerciseAttempt(
        id: exerciseData['attempt_id'] as String,
        exerciseId: exercise.id,
        knowledgePointId: target.id,
        userAnswer: exerciseData['user_answer'] as String,
        feedback: evaluationData.feedback,
        conceptAccuracyScore: evaluationData.conceptAccuracyScore,
        reasoningProcessScore: evaluationData.reasoningProcessScore,
        evidenceUseScore: evaluationData.evidenceUseScore,
        clarityScore: evaluationData.clarityScore,
        misconceptionCode: evaluationData.misconceptionCode,
        misconceptionLabel: evaluationData.misconceptionLabel,
        repairExplanation: evaluationData.repairExplanation,
        citationIds: evaluationData.citationIds,
        evidenceSufficient: evaluationData.evidenceSufficient,
        groundedClaims: evaluationData.claims,
        groundingDisposition: evaluationData.groundingDisposition,
        createdAt: exerciseAt.add(const Duration(minutes: 2)),
      );
      await exerciseRepository.insertAttempt(attempt);
      var retest = evaluationData.retestExercise!.toExercise(
        id: exerciseData['retest_id'] as String,
        knowledgePointId: target.id,
        createdAt: exerciseAt.add(const Duration(minutes: 3)),
        isRetest: true,
        parentAttemptId: attempt.id,
      );
      await exerciseRepository.insertExercise(retest);
      attempt = attempt.copyWith(retestExerciseId: retest.id);
      await exerciseRepository.updateAttempt(attempt);
      final masteryApplied = await MasteryService(knowledgePointRepository)
          .updateFromProgrammingExerciseAttempt(
        exercise: exercise,
        attempt: attempt,
      );
      expect(masteryApplied, isTrue);
      attempt = attempt.copyWith(formalMasteryApplied: true);
      await exerciseRepository.updateAttempt(attempt);
      final exerciseAction = await closureService.closeExerciseAttempt(
        exercise: exercise,
        attempt: attempt,
        now: exerciseAt.add(const Duration(minutes: 4)),
      );
      expect(exerciseAction, isNotNull);

      final queueBeforeVerification = await closureService.getOpenQueue();
      expect(
        queueBeforeVerification.expand((item) => item.exercises),
        isEmpty,
      );
      expect(
        queueBeforeVerification.expand((item) => item.questions).every(
            (question) =>
                question.sourceStatus == SourceStatus.verified &&
                question.citationIds.isNotEmpty),
        isTrue,
      );

      retest = retest.copyWith(
        sourceStatus: SourceStatus.verified,
        updatedAt: reviewAt,
      );
      await exerciseRepository.updateExercise(retest);
      final reviewQueue = await closureService.getOpenQueue();
      expect(
        reviewQueue,
        hasLength(expected['open_review_action_count'] as int),
      );
      for (final item in reviewQueue) {
        expect(item.prerequisiteKnowledgePoints.single.id, prerequisite.id);
        expect(
          item.questions.map((question) => question.id),
          [expected['verified_review_question_id']],
        );
        expect(
          item.exercises.map((exercise) => exercise.id),
          [expected['verified_retest_id']],
        );
        expect(
          item.exercises.every((exercise) =>
              exercise.isRetest &&
              exercise.sourceStatus == SourceStatus.verified &&
              exercise.citationIds.isNotEmpty),
          isTrue,
        );
      }
      expect(openAI.remainingResponseCount, 0);
      expect(openAI.calledTasks, expected['ai_task_order']);
    },
  );
}

Future<Map<String, dynamic>> _loadFixture() async {
  final json = await File(
    'test/fixtures/golden_path/programming_learning_closure_fixture.json',
  ).readAsString();
  return _asMap(jsonDecode(json));
}

Map<String, dynamic> _asMap(Object? value) {
  return Map<String, dynamic>.from(value! as Map);
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  return (value! as List<dynamic>).map(_asMap).toList();
}

class _FixtureOpenAIService extends OpenAIService {
  static const _promptMarkers = {
    'concept_prerequisite': '严谨的编程概念先修关系分析器',
    'tutor_explanation': '严谨的编程学习导师',
    'tutor_socratic': '证据约束的苏格拉底编程导师',
    'programming_exercise_generation': '证据约束的编程练习设计器',
    'programming_exercise_evaluation': '证据约束的编程练习评价器',
  };

  final List<Map<String, dynamic>> _responses;
  final List<String> calledTasks = [];

  _FixtureOpenAIService(this._responses);

  factory _FixtureOpenAIService.fromFixture(
    List<Map<String, dynamic>> responses,
  ) {
    return _FixtureOpenAIService([...responses]);
  }

  int get remainingResponseCount => _responses.length;

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    if (_responses.isEmpty) {
      throw StateError('Programming golden-path response queue is empty.');
    }
    final response = _responses.removeAt(0);
    final task = response['task'] as String;
    final marker = _promptMarkers[task];
    if (marker == null || !systemPrompt.contains(marker)) {
      throw StateError('Unexpected prompt for fixture task $task.');
    }
    calledTasks.add(task);
    return jsonEncode(response['body']);
  }
}
