import 'dart:convert';

import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/project_interview_flow_service.dart';
import 'package:anchor_learning/services/ai/ai_task_result.dart';
import 'package:anchor_learning/services/ai/tasks/answer_evaluation_task.dart';
import 'package:anchor_learning/services/ai/tasks/interview_question_task.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectInterviewFlowService', () {
    const service = ProjectInterviewFlowService();

    test('orders project units by walkthrough stage', () {
      final now = DateTime(2026, 7, 15);
      final points = [
        _point('trade', KnowledgePointKind.tradeOff, now),
        _point('implementation', KnowledgePointKind.implementation, now),
        _point('architecture', KnowledgePointKind.architecture, now),
        _point('boundary', KnowledgePointKind.boundary, now),
        _point('data', KnowledgePointKind.dataFlow, now),
      ];

      final ordered = service.orderKnowledgePoints(points);

      expect(
        ordered.map((point) => point.kind),
        [
          KnowledgePointKind.architecture,
          KnowledgePointKind.dataFlow,
          KnowledgePointKind.implementation,
          KnowledgePointKind.boundary,
          KnowledgePointKind.tradeOff,
        ],
      );
    });

    test('keeps an explicit focus first then advances to the next stage', () {
      final now = DateTime(2026, 7, 15);
      final architecture =
          _point('architecture', KnowledgePointKind.architecture, now);
      final implementation =
          _point('implementation', KnowledgePointKind.implementation, now);
      final boundary = _point('boundary', KnowledgePointKind.boundary, now);
      final ordered = service.orderKnowledgePoints(
        [boundary, architecture, implementation],
        focusedPointId: implementation.id,
      );

      expect(ordered.map((point) => point.id), [
        implementation.id,
        architecture.id,
        boundary.id,
      ]);
      expect(
        service.nextUnaskedPoint(
          orderedPoints: ordered,
          askedPointIds: {implementation.id, architecture.id},
        )?.id,
        boundary.id,
      );
    });

    test('builds at most one follow-up from the current point and evidence',
        () {
      final now = DateTime(2026, 7, 15);
      final point = _point(
        'implementation',
        KnowledgePointKind.implementation,
        now,
      );
      final chunk = _chunk('chunk-implementation', now);
      final question = InterviewQuestionDraft(
        question: 'How is this implemented?',
        knowledgePointIds: [point.id],
        citationIds: [chunk.id],
        difficulty: 3,
      );
      final evaluation = AnswerEvaluationResult(
        accuracyScore: 3,
        projectDetailScore: 2,
        engineeringScore: 2,
        clarityScore: 4,
        feedback: 'The answer skipped the repository boundary.',
        referenceAnswer: 'The provider delegates persistence to a repository.',
        followUpQuestion: 'Where is the repository boundary enforced?',
        followUpKnowledgePointId: point.id,
        followUpCitationIds: [chunk.id],
      );

      final followUp = service.buildGroundedFollowUp(
        currentQuestion: question,
        evaluation: evaluation,
        knowledgePoints: [point],
        citedChunks: [chunk],
        followedUpPointIds: const {},
      );

      expect(followUp, isNotNull);
      expect(followUp!.isFollowUp, isTrue);
      expect(followUp.knowledgePointIds, [point.id]);
      expect(followUp.citationIds, [chunk.id]);
      expect(followUp.difficulty, 4);
      expect(
        service.buildGroundedFollowUp(
          currentQuestion: question,
          evaluation: evaluation,
          knowledgePoints: [point],
          citedChunks: [chunk],
          followedUpPointIds: {point.id},
        ),
        isNull,
      );
    });

    test('restores a saved follow-up only once for its knowledge point', () {
      final now = DateTime(2026, 7, 15);
      final turn = InterviewTurn(
        id: 'turn-1',
        sessionId: 'session-1',
        questionText: '基础问题',
        userAnswer: '基础回答',
        aiFeedback: '需要补充边界。',
        referenceAnswer: '参考回答',
        knowledgePointId: 'point-1',
        citationIds: const ['chunk-1'],
        nextInterviewQuestion: '请补充这个知识点的边界。',
        createdAt: now,
      );

      final restored = service.restorePendingFollowUp(
        turns: [turn],
        availablePointIds: const {'point-1'},
        availableCitationIds: const {'chunk-1'},
      );

      expect(restored, isNotNull);
      expect(restored!.isFollowUp, isTrue);
      expect(restored.question, turn.nextInterviewQuestion);
      expect(
        service.restorePendingFollowUp(
          turns: [turn, turn.copyWith(nextInterviewQuestion: '')],
          availablePointIds: const {'point-1'},
          availableCitationIds: const {'chunk-1'},
        ),
        isNull,
      );
    });
  });

  test('answer evaluation removes an unsupported follow-up', () async {
    final now = DateTime(2026, 7, 15);
    final chunk = _chunk('chunk-architecture', now);
    final task = AnswerEvaluationTask(
      _StaticOpenAIService({
        'accuracy_score': 3,
        'project_detail_score': 2,
        'engineering_score': 2,
        'clarity_score': 4,
        'feedback': 'The answer needs a clearer data-flow explanation.',
        'reference_answer': 'The provider passes source-backed data onward.',
        'follow_up_question': 'Explain an unrelated deployment system.',
        'follow_up_knowledge_point_id': 'unknown-point',
        'follow_up_citation_ids': ['unknown-chunk'],
        'weak_knowledge_point_ids': ['point-architecture'],
        'citation_ids': [chunk.id],
        'claims': [
          {
            'section': 'feedback',
            'text': 'The answer needs a clearer data-flow explanation.',
            'evidence': [
              {
                'citation_id': chunk.id,
                'quote': 'source for chunk-architecture',
              },
            ],
          },
          {
            'section': 'reference_answer',
            'text': 'The provider passes source-backed data onward.',
            'evidence': [
              {
                'citation_id': chunk.id,
                'quote': 'source for chunk-architecture',
              },
            ],
          },
        ],
      }),
    );

    final result = await task.run(
      question: 'How does the project data flow work?',
      userAnswer: 'The provider passes data to the repository.',
      knowledgePointIds: const ['point-architecture'],
      citedChunks: [chunk],
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(result.requireData.followUpQuestion, isEmpty);
    expect(result.requireData.followUpKnowledgePointId, isEmpty);
    expect(result.requireData.followUpCitationIds, isEmpty);
    expect(result.requireData.citationIds, [chunk.id]);
  });

  test('answer evaluation turns a provider timeout into a retry-safe message',
      () async {
    final now = DateTime(2026, 7, 15);
    final result = await AnswerEvaluationTask(_TimeoutOpenAIService()).run(
      question: 'How does the project data flow work?',
      userAnswer: 'The provider passes data to the repository.',
      knowledgePointIds: const ['point-architecture'],
      citedChunks: [_chunk('chunk-architecture', now)],
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorType, AiTaskErrorType.request);
    expect(result.errorMessage, 'AI 评估响应超时，请保留回答后重试。');
  });
}

KnowledgePoint _point(
  String id,
  KnowledgePointKind kind,
  DateTime now,
) {
  return KnowledgePoint(
    id: id,
    title: id,
    summary: 'summary for $id',
    kind: kind,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(String id, DateTime now) {
  return SourceChunk(
    id: id,
    sourceId: 'source-1',
    chunkIndex: 0,
    content: 'source for $id',
    locator: 'lib/app.dart:1-10',
    contentHash: 'hash-$id',
    createdAt: now,
  );
}

class _StaticOpenAIService extends OpenAIService {
  final Object response;

  _StaticOpenAIService(this.response);

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

class _TimeoutOpenAIService extends OpenAIService {
  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) {
    throw const AiProviderException(
      code: 'timeout',
      message: 'The request took longer than two minutes.',
    );
  }
}
