import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/grounded_learning_context.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/agent/grounded_learning_context_service.dart';
import 'package:dlg_q/services/ai/grounded_claim_gate.dart';
import 'package:dlg_q/services/ai/tasks/answer_evaluation_task.dart';
import 'package:dlg_q/services/ai/tasks/knowledge_answer_task.dart';
import 'package:dlg_q/services/ai/tasks/programming_exercise_evaluation_task.dart';
import 'package:dlg_q/services/ai/tasks/tutor_socratic_task.dart';
import 'package:dlg_q/services/openai_service.dart';

void main() {
  const service = GroundedLearningContextService();

  test('selects the same legal evidence contract for all four surfaces', () {
    final point = _point();
    final chunks = [
      _chunk(
        'chunk-official',
        'source-official',
        content: 'Responses return typed output items.',
        relativePath: 'docs/responses.md',
        startLine: 10,
        endLine: 12,
      ),
      _chunk(
        'chunk-code',
        'source-code',
        content: 'return persistedValue;',
        locator: 'lib/store.dart:21-21',
      ),
    ];
    final sources = [
      _source(
        'source-official',
        SourceTrustLevel.officialDoc,
        SourceType.officialDoc,
      ),
      _source(
        'source-code',
        SourceTrustLevel.sourceCode,
        SourceType.codeFile,
      ),
    ];
    final candidates = [
      GroundedLearningContextCandidate(
        chunk: chunks[0],
        reasons: const [GroundedLearningContextReason.targetRelation],
      ),
      GroundedLearningContextCandidate(
        chunk: chunks[1],
        reasons: const [
          GroundedLearningContextReason.prerequisiteRelation,
        ],
      ),
    ];

    final contexts = GroundedLearningSurface.values
        .map(
          (surface) => service.select(
            targetId: point.id,
            knowledgePoint: point,
            surface: surface,
            candidates: candidates,
            sources: sources,
          ),
        )
        .toList(growable: false);

    for (final context in contexts) {
      expect(context.isExecutable, isTrue);
      expect(context.chunkIds, ['chunk-official', 'chunk-code']);
      expect(context.items[0].trustLevel, SourceTrustLevel.officialDoc);
      expect(context.items[0].locator, 'docs/responses.md:10-12');
      expect(context.items[0].quoteBoundary.startOffset, 0);
      expect(
        context.items[0].quoteBoundary.endOffset,
        chunks[0].content.length,
      );
      expect(context.items[0].quoteBoundary.exactText, chunks[0].content);
      expect(
        context.items[0].selectionReasons,
        [GroundedLearningContextReason.targetRelation],
      );
      expect(
        context.diagnosticLines.join('\n'),
        contains('selection_reason=target_relation'),
      );
      expect(
        context.diagnosticLines.join('\n'),
        contains('trust=official_doc'),
      );
    }
  });

  test('rejects invalid candidates consistently on every surface', () {
    final validSource = _source(
      'source-valid',
      SourceTrustLevel.bookCourse,
      SourceType.text,
    );
    final candidates = [
      GroundedLearningContextCandidate(
        chunk: _chunk('valid', validSource.id, content: 'Valid evidence.'),
        reasons: const [GroundedLearningContextReason.targetRelation],
      ),
      GroundedLearningContextCandidate(
        chunk: _chunk('missing-source', 'source-missing'),
        reasons: const [GroundedLearningContextReason.targetRelation],
      ),
      GroundedLearningContextCandidate(
        chunk: _chunk('empty', validSource.id, content: '   '),
        reasons: const [GroundedLearningContextReason.targetRelation],
      ),
      GroundedLearningContextCandidate(
        chunk: _chunk('reasonless', validSource.id),
        reasons: const [],
      ),
    ];

    List<GroundedLearningContextRejectionCode>? expectedCodes;
    for (final surface in GroundedLearningSurface.values) {
      final context = service.select(
        targetId: 'target',
        surface: surface,
        candidates: candidates,
        sources: [validSource],
      );
      final codes = context.rejections
          .map((rejection) => rejection.code)
          .toList(growable: false);
      expectedCodes ??= codes;
      expect(codes, expectedCodes);
      expect(context.chunkIds, ['valid']);
      expect(context.isExecutable, isTrue);
      expect(codes, [
        GroundedLearningContextRejectionCode.missingSource,
        GroundedLearningContextRejectionCode.emptyChunk,
        GroundedLearningContextRejectionCode.missingSelectionReason,
      ]);
    }
  });

  test('citation subset blocks execution when any required id is outside', () {
    final parent = _contextFor(
      GroundedLearningSurface.interview,
      chunkIds: const ['chunk-a', 'chunk-b'],
    );

    final subset = service.selectCitationSubset(
      parent: parent,
      targetId: 'interview-turn-1',
      surface: GroundedLearningSurface.interview,
      citationIds: const ['chunk-a', 'outside-context'],
      reason: GroundedLearningContextReason.questionCitation,
    );

    expect(subset.chunkIds, ['chunk-a']);
    expect(subset.isExecutable, isFalse);
    expect(
      subset.rejections.map((rejection) => rejection.code),
      contains(GroundedLearningContextRejectionCode.missingRequiredCitation),
    );
    final diagnostics = subset.diagnosticLines.join('\n');
    expect(diagnostics, contains(subset.contextId));
    expect(diagnostics, contains('selection_reason=question_citation'));
    expect(diagnostics, contains('missing_required_citation'));
  });

  test('quote boundary rejects wrong quotes and outside citations uniformly',
      () {
    final claims = [
      const GroundedClaim(
        section: 'answer',
        text: 'Supported claim.',
        evidence: [
          GroundedClaimEvidence(
            citationId: 'chunk-a',
            quote: 'Evidence for chunk-a',
          ),
        ],
      ),
      const GroundedClaim(
        section: 'answer',
        text: 'Wrong quote.',
        evidence: [
          GroundedClaimEvidence(
            citationId: 'chunk-a',
            quote: 'This text is outside the quote boundary.',
          ),
        ],
      ),
      const GroundedClaim(
        section: 'answer',
        text: 'Outside citation.',
        evidence: [
          GroundedClaimEvidence(
            citationId: 'outside-context',
            quote: 'Evidence for chunk-a',
          ),
        ],
      ),
    ];

    for (final surface in GroundedLearningSurface.values) {
      final audit = const GroundedClaimGate().evaluateContext(
        claims: claims,
        context: _contextFor(surface),
      );
      expect(audit.groundedClaims, hasLength(1));
      expect(audit.uncoveredClaims, hasLength(2));
      expect(audit.invalidEvidenceCount, 2);
      expect(audit.citationIds, ['chunk-a']);
      expect(audit.disposition, GroundingDisposition.partial);
    }
  });

  test('all four task surfaces reject a non-executable context before AI',
      () async {
    final openAI = _CountingOpenAIService();
    final point = _point();
    final invalidContexts = {
      for (final surface in GroundedLearningSurface.values)
        surface: service.selectCitationSubset(
          parent: _contextFor(surface),
          targetId: '${surface.value}-target',
          surface: surface,
          citationIds: const ['chunk-a', 'outside-context'],
          reason: GroundedLearningContextReason.questionCitation,
        ),
    };

    final answer = await KnowledgeAnswerTask(openAI).run(
      question: 'What is supported?',
      sourceChunks:
          invalidContexts[GroundedLearningSurface.knowledgeAnswer]!.chunks,
      groundedContext: invalidContexts[GroundedLearningSurface.knowledgeAnswer],
    );
    final tutor = await TutorSocraticTask(openAI).run(
      knowledgePoint: point,
      question: 'What is supported?',
      userAnswer: 'A tentative answer.',
      sourceChunks: invalidContexts[GroundedLearningSurface.tutor]!.chunks,
      groundedContext: invalidContexts[GroundedLearningSurface.tutor],
    );
    final interview = await AnswerEvaluationTask(openAI).run(
      question: 'What is supported?',
      userAnswer: 'A tentative answer.',
      knowledgePointIds: [point.id],
      citedChunks: invalidContexts[GroundedLearningSurface.interview]!.chunks,
      groundedContext: invalidContexts[GroundedLearningSurface.interview],
    );
    final programming = await ProgrammingExerciseEvaluationTask(openAI).run(
      knowledgePoint: point,
      exercise: _exercise(point.id),
      userAnswer: 'A tentative implementation answer.',
      sourceChunks: invalidContexts[
              GroundedLearningSurface.programmingExerciseEvaluation]!
          .chunks,
      groundedContext: invalidContexts[
          GroundedLearningSurface.programmingExerciseEvaluation],
    );

    expect(answer.isSuccess, isFalse);
    expect(tutor.isSuccess, isFalse);
    expect(interview.isSuccess, isFalse);
    expect(programming.isSuccess, isFalse);
    expect(openAI.callCount, 0);
  });

  test('all four tasks ignore raw chunks outside their grounded context',
      () async {
    final point = _point();
    final outsideChunk = _chunk(
      'outside-context',
      'source-outside',
      content: 'Outside evidence must never enter the grounded prompt.',
    );

    final answerAI = _StaticOpenAIService({
      'answer': 'Outside claim.',
      'key_points': <String>[],
      'follow_up_questions': <String>[],
      'source_gaps': <String>[],
      'citation_ids': ['outside-context'],
      'claims': [_outsideClaim('answer')],
    });
    final answerContext = _contextFor(GroundedLearningSurface.knowledgeAnswer);
    final answer = await KnowledgeAnswerTask(answerAI).run(
      question: 'What is supported?',
      sourceChunks: [...answerContext.chunks, outsideChunk],
      groundedContext: answerContext,
    );

    final tutorAI = _StaticOpenAIService({
      'feedback': 'Outside feedback.',
      'reference_answer': 'Outside reference.',
      'misconception': '',
      'next_question': 'Continue outside?',
      'citation_ids': ['outside-context'],
      'evidence_sufficient': true,
      'accuracy_score': 100,
      'claims': [
        _outsideClaim('feedback'),
        _outsideClaim('reference_answer'),
      ],
    });
    final tutorContext = _contextFor(GroundedLearningSurface.tutor);
    final tutor = await TutorSocraticTask(tutorAI).run(
      knowledgePoint: point,
      question: 'What is supported?',
      userAnswer: 'A tentative answer.',
      sourceChunks: [...tutorContext.chunks, outsideChunk],
      groundedContext: tutorContext,
    );

    final interviewAI = _StaticOpenAIService({
      'accuracy_score': 5,
      'project_detail_score': 5,
      'engineering_score': 5,
      'clarity_score': 5,
      'feedback': 'Outside feedback.',
      'reference_answer': 'Outside reference.',
      'weak_knowledge_point_ids': [point.id],
      'citation_ids': ['outside-context'],
      'claims': [
        _outsideClaim('feedback'),
        _outsideClaim('reference_answer'),
      ],
    });
    final interviewContext = _contextFor(GroundedLearningSurface.interview);
    final interview = await AnswerEvaluationTask(interviewAI).run(
      question: 'What is supported?',
      userAnswer: 'A tentative answer.',
      knowledgePointIds: [point.id],
      citedChunks: [...interviewContext.chunks, outsideChunk],
      groundedContext: interviewContext,
    );

    final programmingAI = _StaticOpenAIService({
      'feedback': 'Outside feedback.',
      'concept_accuracy_score': 100,
      'reasoning_process_score': 100,
      'evidence_use_score': 100,
      'clarity_score': 100,
      'misconception_code': '',
      'misconception_label': '',
      'repair_explanation': '',
      'citation_ids': ['outside-context'],
      'evidence_sufficient': true,
      'retest_exercise': null,
      'claims': [_outsideClaim('feedback')],
    });
    final programmingContext = _contextFor(
      GroundedLearningSurface.programmingExerciseEvaluation,
    );
    final programming = await ProgrammingExerciseEvaluationTask(
      programmingAI,
    ).run(
      knowledgePoint: point,
      exercise: _exercise(point.id),
      userAnswer: 'A tentative implementation answer.',
      sourceChunks: [...programmingContext.chunks, outsideChunk],
      groundedContext: programmingContext,
    );

    expect(
        answer.requireData.groundingDisposition, GroundingDisposition.refused);
    expect(
        tutor.requireData.groundingDisposition, GroundingDisposition.refused);
    expect(interview.requireData.groundingDisposition,
        GroundingDisposition.refused);
    expect(programming.requireData.groundingDisposition,
        GroundingDisposition.refused);
    expect(interview.requireData.accuracyScore, 0);
    expect(programming.requireData.averageScore, 0);
    for (final ai in [answerAI, tutorAI, interviewAI, programmingAI]) {
      expect(ai.userContent, isNot(contains('Outside evidence must never')));
    }
  });
}

Map<String, Object> _outsideClaim(String section) {
  return {
    'section': section,
    'text': 'Outside claim for $section.',
    'evidence': [
      {
        'citation_id': 'outside-context',
        'quote': 'Outside evidence must never enter the grounded prompt.',
      },
    ],
  };
}

GroundedLearningContext _contextFor(
  GroundedLearningSurface surface, {
  List<String> chunkIds = const ['chunk-a'],
}) {
  const service = GroundedLearningContextService();
  final source = _source(
    'source-shared',
    SourceTrustLevel.officialDoc,
    SourceType.officialDoc,
  );
  return service.select(
    targetId: 'shared-target',
    knowledgePoint: _point(),
    surface: surface,
    candidates: chunkIds
        .map(
          (id) => GroundedLearningContextCandidate(
            chunk: _chunk(
              id,
              source.id,
              content: 'Evidence for $id is exact and reviewable.',
            ),
            reasons: const [GroundedLearningContextReason.targetRelation],
          ),
        )
        .toList(growable: false),
    sources: [source],
  );
}

KnowledgePoint _point() {
  final now = DateTime.utc(2026, 7, 15);
  return KnowledgePoint(
    id: 'shared-target',
    title: 'Shared target',
    summary: 'A source-backed learning target.',
    createdAt: now,
    updatedAt: now,
  );
}

ProgrammingExercise _exercise(String knowledgePointId) {
  final now = DateTime.utc(2026, 7, 15);
  return ProgrammingExercise(
    id: 'exercise-shared',
    knowledgePointId: knowledgePointId,
    kind: ProgrammingExerciseKind.implementation,
    prompt: 'Implement the source-backed behavior.',
    referenceAnswer: 'Use the cited behavior.',
    conceptAccuracyCriterion: 'Name the behavior accurately.',
    reasoningProcessCriterion: 'Explain the implementation steps.',
    evidenceUseCriterion: 'Use the cited source.',
    clarityCriterion: 'Answer clearly.',
    sourceStatus: SourceStatus.verified,
    citationIds: const ['chunk-a'],
    createdAt: now,
    updatedAt: now,
  );
}

Source _source(
  String id,
  SourceTrustLevel trustLevel,
  SourceType type,
) {
  final now = DateTime.utc(2026, 7, 15);
  return Source(
    id: id,
    title: id,
    type: type,
    trustLevel: trustLevel,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(
  String id,
  String sourceId, {
  String content = 'Evidence content.',
  String? locator,
  String? relativePath,
  int? startLine,
  int? endLine,
}) {
  return SourceChunk(
    id: id,
    sourceId: sourceId,
    chunkIndex: 0,
    content: content,
    locator: locator,
    relativePath: relativePath,
    startLine: startLine,
    endLine: endLine,
    createdAt: DateTime.utc(2026, 7, 15),
  );
}

class _CountingOpenAIService extends OpenAIService {
  int callCount = 0;

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    callCount += 1;
    return '{}';
  }
}

class _StaticOpenAIService extends OpenAIService {
  final Object response;
  String userContent = '';

  _StaticOpenAIService(this.response);

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    this.userContent = userContent;
    return jsonEncode(response);
  }
}
