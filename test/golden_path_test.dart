import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/data/repositories/source_repository.dart';
import 'package:anchor_learning/services/agent/interviewer_service.dart';
import 'package:anchor_learning/services/ai/tasks/answer_evaluation_task.dart';
import 'package:anchor_learning/services/ai/tasks/citation_verification_task.dart';
import 'package:anchor_learning/services/ai/tasks/interview_question_task.dart';
import 'package:anchor_learning/services/ai/tasks/project_understanding_task.dart';
import 'package:anchor_learning/services/ai/tasks/question_generation_task.dart';
import 'package:anchor_learning/services/ingestion/project_source_import_service.dart';
import 'package:anchor_learning/services/ingestion/source_grounded_ingestion_service.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:anchor_learning/services/scheduling/mastery_service.dart';
import 'package:anchor_learning/services/scheduling/interview_review_closure_service.dart';
import 'package:anchor_learning/services/scheduling/review_scheduler_service.dart';

void main() {
  sqfliteFfiInit();

  test(
    'project evidence reaches verified review through the interview weak-point loop',
    () async {
      final fixture = await _loadFixture();
      final clock = _asMap(fixture['clock']);
      final expected = _asMap(fixture['expected']);
      final sourceData = _asMap(fixture['source']);
      final sourceCreatedAt = DateTime.parse(
        clock['source_created_at'] as String,
      );
      final selectedPaths = (fixture['selected_paths'] as List<dynamic>)
          .map((path) => path.toString())
          .toSet();
      const importService = ProjectSourceImportService();
      final snapshot = await importService.scanDirectory('.');
      expect(
        snapshot.files.map((file) => file.relativePath),
        containsAll(selectedPaths),
      );
      final source = Source(
        id: sourceData['id'] as String,
        title: sourceData['title'] as String,
        type: SourceType.fromString(sourceData['type'] as String),
        uri: snapshot.sourceUri,
        revision: snapshot.revision,
        trustLevel: SourceTrustLevel.fromString(
          sourceData['trust_level'] as String,
        ),
        createdAt: sourceCreatedAt,
        updatedAt: sourceCreatedAt,
      );
      final chunks = importService.buildSourceChunks(
        snapshot: snapshot,
        selectedPaths: selectedPaths,
        sourceId: source.id,
        createdAt: sourceCreatedAt,
        maxLinesPerChunk: 1000,
      );
      expect(chunks, hasLength(selectedPaths.length));

      final databaseHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
      );
      addTearDown(databaseHelper.close);
      final sourceRepository = SourceRepository(databaseHelper);
      final chunkRepository = SourceChunkRepository(databaseHelper);
      final knowledgePointRepository = KnowledgePointRepository(
        databaseHelper,
      );
      final questionRepository = QuestionRepository(databaseHelper);
      final sessionRepository = LearningSessionRepository(databaseHelper);
      final openAI = _QueuedOpenAIService.fromFixture(
        _asMapList(fixture['ai_responses']),
      );
      final understandingTask = ProjectUnderstandingTask(openAI);
      final questionTask = QuestionGenerationTask(openAI);
      final citationTask = CitationVerificationTask(openAI);
      final ingestionService = SourceGroundedIngestionService(
        databaseHelper: databaseHelper,
        citationVerificationTask: citationTask,
      );

      final understanding = await understandingTask.run(sourceChunks: chunks);
      expect(
        understanding.isSuccess,
        isTrue,
        reason: understanding.errorMessage,
      );
      final pointDrafts = ingestionService.buildProjectUnderstandingDrafts(
        sourceId: source.id,
        now: sourceCreatedAt,
        units: understanding.requireData.units,
      );
      expect(pointDrafts.knowledgePoints, hasLength(1));
      final knowledgePoint = pointDrafts.knowledgePoints.single;
      expect(knowledgePoint.id, expected['knowledge_point_id']);
      expect(knowledgePoint.kind, KnowledgePointKind.architecture);
      expect(
        pointDrafts.sourceChunkIdsByKnowledgePointId[knowledgePoint.id],
        containsAll(chunks.map((chunk) => chunk.id)),
      );

      final questionGeneration = await questionTask.run(
        knowledgePoints: pointDrafts.knowledgePoints,
        sourceChunks: chunks,
        questionCount: 1,
      );
      expect(
        questionGeneration.isSuccess,
        isTrue,
        reason: questionGeneration.errorMessage,
      );
      final generatedQuestion = questionGeneration.requireData.questions.single
          .toQuestion(deckId: _asMap(fixture['deck'])['id'] as String)
          .copyWith(id: fixture['question_id'] as String);
      final precheckedQuestions = await ingestionService.precheckQuestions(
        questions: [generatedQuestion],
        chunks: chunks,
      );
      expect(precheckedQuestions.single.sourceStatus, SourceStatus.pending);
      expect(
        precheckedQuestions.single.citationIds,
        containsAll(chunks.map((chunk) => chunk.id)),
      );

      final deck = _asMap(fixture['deck']);
      final saveResult = await ingestionService.saveReviewedContent(
        SourceGroundedSaveRequest(
          source: source,
          chunks: chunks,
          knowledgePointDecisions: pointDrafts.knowledgePoints
              .map(
                (point) => SourceGroundedKnowledgePointDecision(
                  knowledgePoint: point,
                  approved: true,
                  deleted: false,
                ),
              )
              .toList(),
          sourceChunkIdsByKnowledgePointId:
              pointDrafts.sourceChunkIdsByKnowledgePointId,
          deckId: deck['id'] as String,
          deckTitle: deck['title'] as String,
          deckSourceText: deck['source_text'] as String,
          questionDecisions: [
            SourceGroundedQuestionDecision(
              question: precheckedQuestions.single,
              sourceStatus: SourceStatus.verified,
              deleted: false,
            ),
          ],
        ),
      );
      expect(saveResult.savedQuestionCount, expected['saved_question_count']);

      final persistedSource = await sourceRepository.getSource(source.id);
      final persistedChunks = await chunkRepository.getSourceChunks(source.id);
      final persistedRelations = await knowledgePointRepository
          .getKnowledgePointSources(knowledgePoint.id);
      final persistedQuestions = await questionRepository.getQuestionsByDeck(
        deck['id'] as String,
      );
      expect(persistedSource?.trustLevel, SourceTrustLevel.sourceCode);
      expect(
        persistedChunks,
        hasLength(expected['source_chunk_count'] as int),
      );
      expect(
        persistedRelations.map((relation) => relation.sourceChunkId),
        containsAll(chunks.map((chunk) => chunk.id)),
      );
      expect(persistedQuestions, hasLength(1));
      expect(persistedQuestions.single.sourceStatus, SourceStatus.verified);
      expect(
        persistedQuestions.single.citationIds,
        containsAll(chunks.map((chunk) => chunk.id)),
      );

      final sessionData = _asMap(fixture['session']);
      final startedAt = DateTime.parse(clock['session_started_at'] as String);
      final endedAt = DateTime.parse(clock['session_ended_at'] as String);
      final session = LearningSession(
        id: sessionData['id'] as String,
        mode: LearningSessionMode.interview,
        targetId: sessionData['target_id'] as String,
        startedAt: startedAt,
      );
      await sessionRepository.insertLearningSession(session);

      final interviewer = InterviewerService(
        questionTask: InterviewQuestionTask(openAI),
        evaluationTask: AnswerEvaluationTask(openAI),
      );
      final interviewQuestions = await interviewer.generateQuestions(
        knowledgePoints: [knowledgePoint],
        sourceChunks: persistedChunks,
        questionCount: 1,
      );
      expect(
        interviewQuestions.isSuccess,
        isTrue,
        reason: interviewQuestions.errorMessage,
      );
      final interviewQuestion = interviewQuestions.requireData.questions.single;
      expect(interviewQuestion.knowledgePointIds, [knowledgePoint.id]);
      expect(
        interviewQuestion.citationIds,
        containsAll(chunks.map((chunk) => chunk.id)),
      );

      final evaluation = await interviewer.evaluateAnswer(
        question: interviewQuestion,
        userAnswer: sessionData['user_answer'] as String,
        citedChunks: persistedChunks
            .where(
              (chunk) => interviewQuestion.citationIds.contains(chunk.id),
            )
            .toList(),
      );
      expect(evaluation.isSuccess, isTrue, reason: evaluation.errorMessage);
      final feedback = evaluation.requireData;
      expect(feedback.weakKnowledgePointIds, [knowledgePoint.id]);
      expect(
        feedback.citationIds,
        containsAll(chunks.map((chunk) => chunk.id)),
      );

      final draftTurn = InterviewTurn(
        id: '${session.id}_turn_0',
        sessionId: session.id,
        questionText: interviewQuestion.question,
        userAnswer: sessionData['user_answer'] as String,
        aiFeedback: feedback.feedback,
        referenceAnswer: feedback.referenceAnswer,
        knowledgePointId: knowledgePoint.id,
        knowledgePointKind: knowledgePoint.kind,
        citationIds: feedback.citationIds,
        accuracyScore: feedback.accuracyScore,
        projectDetailScore: feedback.projectDetailScore,
        engineeringScore: feedback.engineeringScore,
        clarityScore: feedback.clarityScore,
        weakKnowledgePointIds: feedback.weakKnowledgePointIds,
        groundedClaims: feedback.claims,
        groundingDisposition: feedback.groundingDisposition,
        createdAt: endedAt,
      );
      final turn = await InterviewReviewClosureService(
        knowledgePointRepository: knowledgePointRepository,
        questionRepository: questionRepository,
        databaseHelper: databaseHelper,
      ).closeAndPersistTurn(turn: draftTurn, now: endedAt);
      await MasteryService(knowledgePointRepository).updateFromInterviewTurn(
        turn: turn,
        knowledgePointIds: interviewQuestion.knowledgePointIds,
      );
      await sessionRepository.updateLearningSession(
        session.copyWith(
          endedAt: endedAt,
          summary: feedback.feedback,
        ),
      );

      final persistedTurns = await sessionRepository.getInterviewTurns(
        session.id,
      );
      final updatedPoint = await knowledgePointRepository.getKnowledgePoint(
        knowledgePoint.id,
      );
      expect(persistedTurns.single.weakKnowledgePointIds, [knowledgePoint.id]);
      expect(persistedTurns.single.weakDimensions, isNotEmpty);
      expect(
        persistedTurns.single.reviewQuestionIds,
        [generatedQuestion.id],
      );
      expect(persistedTurns.single.nextInterviewQuestion, isNotEmpty);
      expect(persistedTurns.single.knowledgePointId, knowledgePoint.id);
      expect(
        persistedTurns.single.knowledgePointKind,
        knowledgePoint.kind,
      );
      expect(updatedPoint, isNotNull);
      expect(
        updatedPoint!.masteryLevel,
        lessThanOrEqualTo(expected['max_weak_mastery'] as int),
      );

      final reviewQueue = await ReviewSchedulerService(
        questionRepository: questionRepository,
        knowledgePointRepository: knowledgePointRepository,
      ).getTodayReviewQueue(
        now: DateTime.parse(clock['review_at'] as String),
      );
      expect(reviewQueue, hasLength(1));
      expect(reviewQueue.single.knowledgePoint.id, knowledgePoint.id);
      expect(
        reviewQueue.single.questions.map((question) => question.id),
        contains(fixture['question_id']),
      );
      expect(
        reviewQueue.single.questions.every(
          (question) => question.sourceStatus == SourceStatus.verified,
        ),
        isTrue,
      );
      expect(openAI.remainingResponseCount, 0);
      expect(openAI.calledTasks, expected['ai_task_order']);
    },
  );
}

Future<Map<String, dynamic>> _loadFixture() async {
  final json = await File(
    'test/fixtures/golden_path/anchor_learning_checkpoint_fixture.json',
  ).readAsString();
  return _asMap(jsonDecode(json));
}

Map<String, dynamic> _asMap(Object? value) {
  return Map<String, dynamic>.from(value! as Map);
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  return (value! as List<dynamic>).map(_asMap).toList();
}

class _QueuedOpenAIService extends OpenAIService {
  final List<_QueuedAiResponse> _responses;
  final List<String> calledTasks = [];

  _QueuedOpenAIService(this._responses);

  factory _QueuedOpenAIService.fromFixture(
    List<Map<String, dynamic>> responses,
  ) {
    return _QueuedOpenAIService(
      responses.map(_QueuedAiResponse.fromMap).toList(),
    );
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
      throw StateError('Golden-path AI response queue is empty.');
    }
    final queued = _responses.removeAt(0);
    if (!systemPrompt.contains(queued.promptMarker)) {
      throw StateError(
        'Expected ${queued.task} prompt marker "${queued.promptMarker}".',
      );
    }
    calledTasks.add(queued.task);
    return jsonEncode(queued.body);
  }
}

class _QueuedAiResponse {
  final String task;
  final String promptMarker;
  final Object body;

  const _QueuedAiResponse({
    required this.task,
    required this.promptMarker,
    required this.body,
  });

  factory _QueuedAiResponse.fromMap(Map<String, dynamic> map) {
    return _QueuedAiResponse(
      task: map['task'] as String,
      promptMarker: map['prompt_marker'] as String,
      body: map['body']!,
    );
  }
}
