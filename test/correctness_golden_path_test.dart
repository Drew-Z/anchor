import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/programming_exercise.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/knowledge_answer_context_service.dart';
import 'package:anchor_learning/services/agent/knowledge_answer_session_summary.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:anchor_learning/services/ai/tasks/answer_evaluation_task.dart';
import 'package:anchor_learning/services/ai/tasks/knowledge_answer_task.dart';
import 'package:anchor_learning/services/ai/tasks/programming_exercise_evaluation_task.dart';
import 'package:anchor_learning/services/ai/tasks/tutor_socratic_task.dart';
import 'package:anchor_learning/services/evaluation/correctness_evaluation_service.dart';
import 'package:anchor_learning/services/openai_service.dart';

void main() {
  test(
    'fixed correctness path closes retrieval and all grounded learning surfaces',
    () async {
      final fixture = _loadFixture();
      final now = DateTime.utc(2026, 7, 15);
      final sources = _asMapList(fixture['sources'])
          .map(
            (item) => Source(
              id: item['id'] as String,
              title: item['title'] as String,
              type: SourceType.fromString(item['type'] as String),
              uri: item['uri'] as String?,
              trustLevel: SourceTrustLevel.fromString(
                item['trust_level'] as String,
              ),
              createdAt: now,
              updatedAt: now,
            ),
          )
          .toList();
      final chunks = _asMapList(fixture['chunks'])
          .asMap()
          .entries
          .map(
            (entry) => SourceChunk(
              id: entry.value['id'] as String,
              sourceId: entry.value['source_id'] as String,
              chunkIndex: entry.key,
              content: entry.value['content'] as String,
              locator: entry.value['locator'] as String?,
              createdAt: now,
            ),
          )
          .toList();
      final corpus = KnowledgeSearchCorpus(
        sources: sources,
        sourceChunks: chunks,
        knowledgePoints: const [],
        questions: const [],
      );

      const searchService = KnowledgeSearchService();
      final searchResults = searchService.search(
        query: fixture['query'] as String,
        corpus: corpus,
      );
      final rankedChunkIds = searchResults
          .map((result) => result.sourceChunkId)
          .whereType<String>()
          .toList();
      expect(rankedChunkIds.first, 'chunk-openai-json');

      final selection = const KnowledgeAnswerContextService().select(
        results: searchResults,
        sourceChunks: chunks,
        limit: 1,
      );
      expect(selection.chunks.single.id, 'chunk-openai-json');
      expect(
        selection.candidates.single.rankingReasons,
        contains(startsWith('来源可信度')),
      );
      final evidence = selection.chunks;

      final openAI = _QueuedOpenAIService.fromFixture(
        _asMapList(fixture['ai_responses']),
      );
      final answerTask = KnowledgeAnswerTask(openAI);
      final groundedAnswer = (await answerTask.run(
        question: fixture['question'] as String,
        sourceChunks: evidence,
      ))
          .requireData;
      final partialAnswer = (await answerTask.run(
        question: fixture['question'] as String,
        sourceChunks: evidence,
      ))
          .requireData;
      final refusedAnswer = (await answerTask.run(
        question: fixture['question'] as String,
        sourceChunks: evidence,
      ))
          .requireData;

      expect(
          groundedAnswer.groundingDisposition, GroundingDisposition.grounded);
      expect(partialAnswer.groundingDisposition, GroundingDisposition.partial);
      expect(partialAnswer.answer, 'JSON mode guarantees valid JSON.');
      expect(partialAnswer.uncoveredClaims, hasLength(1));
      expect(refusedAnswer.groundingDisposition, GroundingDisposition.refused);
      expect(refusedAnswer.answer, isEmpty);
      expect(
        knowledgeAnswerEvidenceQualityLabels(
          _answerRecord(partialAnswer, fixture['question'] as String),
        ),
        contains('部分主张未支持'),
      );
      expect(
        knowledgeAnswerEvidenceQualityLabels(
          _answerRecord(refusedAnswer, fixture['question'] as String),
        ),
        contains('证据不足已拒答'),
      );

      final pointData = _asMap(fixture['knowledge_point']);
      final point = KnowledgePoint(
        id: pointData['id'] as String,
        title: pointData['title'] as String,
        summary: pointData['summary'] as String,
        createdAt: now,
        updatedAt: now,
      );
      final tutor = (await TutorSocraticTask(openAI).run(
        knowledgePoint: point,
        question: fixture['question'] as String,
        userAnswer: 'JSON mode guarantees the schema.',
        sourceChunks: evidence,
      ))
          .requireData;
      expect(tutor.groundingDisposition, GroundingDisposition.grounded);
      expect(tutor.nextQuestion, isNotEmpty);

      final interview = (await AnswerEvaluationTask(openAI).run(
        question: fixture['question'] as String,
        userAnswer: 'It returns valid JSON and always matches the schema.',
        knowledgePointIds: [point.id],
        citedChunks: evidence,
      ))
          .requireData;
      expect(interview.groundingDisposition, GroundingDisposition.grounded);
      expect(interview.accuracyScore, 3);
      expect(interview.followUpKnowledgePointId, point.id);

      final exerciseData = _asMap(fixture['exercise']);
      final exercise = ProgrammingExercise(
        id: exerciseData['id'] as String,
        knowledgePointId: point.id,
        kind: ProgrammingExerciseKind.fromString(
          exerciseData['kind'] as String,
        ),
        prompt: exerciseData['prompt'] as String,
        referenceAnswer: exerciseData['reference_answer'] as String,
        conceptAccuracyCriterion:
            exerciseData['concept_accuracy_criterion'] as String,
        reasoningProcessCriterion:
            exerciseData['reasoning_process_criterion'] as String,
        evidenceUseCriterion: exerciseData['evidence_use_criterion'] as String,
        clarityCriterion: exerciseData['clarity_criterion'] as String,
        sourceStatus: SourceStatus.verified,
        citationIds: const ['chunk-openai-json'],
        createdAt: now,
        updatedAt: now,
      );
      final exerciseEvaluation =
          (await ProgrammingExerciseEvaluationTask(openAI).run(
        knowledgePoint: point,
        exercise: exercise,
        userAnswer:
            'No. JSON mode guarantees valid JSON, while Structured Outputs enforce the supplied schema.',
        sourceChunks: evidence,
      ))
              .requireData;
      expect(
        exerciseEvaluation.groundingDisposition,
        GroundingDisposition.grounded,
      );
      expect(exerciseEvaluation.averageScore, 93);

      final generationCases = [
        _generationCase(
          'knowledge-grounded',
          CorrectnessEvaluationSurface.knowledgeAnswer,
          groundedAnswer.groundingDisposition,
          groundedAnswer.claims,
        ),
        _generationCase(
          'knowledge-partial',
          CorrectnessEvaluationSurface.knowledgeAnswer,
          partialAnswer.groundingDisposition,
          partialAnswer.claims,
        ),
        _generationCase(
          'knowledge-refused',
          CorrectnessEvaluationSurface.knowledgeAnswer,
          refusedAnswer.groundingDisposition,
          refusedAnswer.claims,
          expectedRefusal: true,
        ),
        _generationCase(
          'tutor-grounded',
          CorrectnessEvaluationSurface.tutorFeedback,
          tutor.groundingDisposition,
          tutor.claims,
        ),
        _generationCase(
          'interview-grounded',
          CorrectnessEvaluationSurface.interviewEvaluation,
          interview.groundingDisposition,
          interview.claims,
        ),
        _generationCase(
          'exercise-grounded',
          CorrectnessEvaluationSurface.programmingExerciseEvaluation,
          exerciseEvaluation.groundingDisposition,
          exerciseEvaluation.claims,
        ),
      ];
      final report = const CorrectnessEvaluationService().evaluate(
        retrievalCases: [
          RetrievalEvaluationCase(
            id: 'official-over-personal-note',
            relevantEvidenceIds: const ['chunk-openai-json'],
            rankedEvidenceIds: rankedChunkIds,
          ),
        ],
        generationCases: generationCases,
        topK: 1,
      );

      expect(
        generationCases.map((item) => item.surface).toSet(),
        CorrectnessEvaluationSurface.values.toSet(),
      );
      expect(report.recallAtK, 1);
      expect(report.meanReciprocalRank, 1);
      expect(report.citationCoverage, 1);
      expect(report.unsupportedClaimRate, 0);
      expect(report.refusalAccuracy, 1);
      expect(openAI.remainingResponseCount, 0);
      expect(openAI.calledTasks, fixture['expected_task_order']);
    },
  );
}

KnowledgeAnswerSessionSummaryRecord _answerRecord(
  KnowledgeAnswerResult result,
  String question,
) {
  return KnowledgeAnswerSessionSummaryRecord.fromFields(
    question: question,
    answer: result.answer,
    keyPoints: result.keyPoints,
    sourceGaps: result.sourceGaps,
    followUpQuestions: result.followUpQuestions,
    citationIds: result.citationIds,
    groundedClaims: result.claims,
    groundingDisposition: result.groundingDisposition,
  );
}

GenerationEvaluationCase _generationCase(
  String id,
  CorrectnessEvaluationSurface surface,
  GroundingDisposition disposition,
  List<GroundedClaim> claims, {
  bool expectedRefusal = false,
}) {
  return GenerationEvaluationCase(
    id: id,
    surface: surface,
    expectedRefusal: expectedRefusal,
    actualRefusal: disposition == GroundingDisposition.refused,
    claims: claims
        .map(
          (claim) => ClaimEvaluation(
            id: claim.text,
            supported: true,
            supportingEvidenceIds: claim.citationIds,
            citationIds: claim.citationIds,
          ),
        )
        .toList(),
  );
}

Map<String, dynamic> _loadFixture() {
  return _asMap(
    jsonDecode(
      File(
        'test/fixtures/golden_path/correctness_closure_fixture.json',
      ).readAsStringSync(),
    ),
  );
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
      throw StateError('Correctness golden-path response queue is empty.');
    }
    final response = _responses.removeAt(0);
    if (!systemPrompt.contains(response.promptMarker)) {
      throw StateError(
        'Expected ${response.task} prompt marker ${response.promptMarker}.',
      );
    }
    calledTasks.add(response.task);
    return jsonEncode(response.body);
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
