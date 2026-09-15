import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_store.dart';
import 'package:anchor_learning/services/agent/project_interview_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 16, 9);

  test('builds the fixed four-state project interview matrix', () {
    final source = _source('source-code', SourceTrustLevel.sourceCode, now);
    final points = [
      _point('ready', KnowledgePointKind.architecture, now),
      _point('practice', KnowledgePointKind.dataFlow, now),
      _point('gap', KnowledgePointKind.implementation, now),
      _point('unassessed', KnowledgePointKind.boundary, now),
    ];
    final chunks = [
      _chunk('chunk-ready', source.id, 'Router selects a grounded tool.', now),
      _chunk(
          'chunk-practice', source.id, 'State flows through one store.', now),
      _chunk('chunk-gap', source.id, 'The executor validates citations.', now),
      _chunk('chunk-unassessed', source.id, 'The boundary rejects raw output.',
          now),
    ];
    final relations = [
      for (var index = 0; index < points.length; index += 1)
        KnowledgePointSource(
          knowledgePointId: points[index].id,
          sourceChunkId: chunks[index].id,
          relation: KnowledgePointSourceRelation.implementation,
        ),
    ];
    final turns = [
      _turn(
        id: 'turn-ready',
        point: points[0],
        chunk: chunks[0],
        answer: '我让路由只选择有来源的工具。',
        scores: const [4, 4, 5, 4],
        now: now,
      ),
      _turn(
        id: 'turn-practice',
        point: points[1],
        chunk: chunks[1],
        answer: '状态经过 store。',
        scores: const [3, 3, 2, 4],
        now: now.add(const Duration(minutes: 1)),
      ),
      _turn(
        id: 'turn-gap',
        point: points[2],
        chunk: chunks[2],
        answer: '执行器会校验引用。',
        scores: const [4, 4, 4, 4],
        quote: 'This quote is not saved.',
        now: now.add(const Duration(minutes: 2)),
      ),
      _turn(
        id: 'turn-model-only',
        point: points[3],
        chunk: chunks[3],
        answer: '',
        referenceAnswer: '一段看起来很完整的模型答案。',
        scores: const [5, 5, 5, 5],
        now: now.add(const Duration(minutes: 3)),
      ),
    ];

    final outcome = _build(
      now: now,
      points: points,
      sources: [source],
      chunks: chunks,
      relations: relations,
      turns: turns,
    );
    final byId = {for (final unit in outcome.units) unit.point.id: unit};

    expect(byId['ready']!.status, ProjectInterviewOutcomeStatus.ready);
    expect(
      byId['practice']!.status,
      ProjectInterviewOutcomeStatus.needsPractice,
    );
    expect(byId['gap']!.status, ProjectInterviewOutcomeStatus.evidenceGap);
    expect(
      byId['unassessed']!.status,
      ProjectInterviewOutcomeStatus.notAssessed,
    );
    expect(outcome.readyCount, 1);
    expect(outcome.needsPracticeCount, 1);
    expect(outcome.evidenceGapCount, 1);
    expect(outcome.notAssessedCount, 1);
  });

  test('polished model text without a real answer never becomes ready', () {
    final source = _source('source', SourceTrustLevel.sourceCode, now);
    final point = _point('point', KnowledgePointKind.architecture, now);
    final chunk = _chunk('chunk', source.id, 'Saved project fact.', now);
    final outcome = _build(
      now: now,
      points: [point],
      sources: [source],
      chunks: [chunk],
      relations: [
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: chunk.id,
        ),
      ],
      turns: [
        _turn(
          id: 'model-only',
          point: point,
          chunk: chunk,
          answer: '',
          referenceAnswer: '完美、完整、流畅的参考答案。',
          scores: const [5, 5, 5, 5],
          now: now,
        ),
      ],
    );

    expect(
      outcome.units.single.status,
      ProjectInterviewOutcomeStatus.notAssessed,
    );
    expect(outcome.units.single.latestAnswer, isNull);
  });

  test('mastery without participation never becomes ready', () {
    final source = _source('source', SourceTrustLevel.sourceCode, now);
    final point = _point(
      'point',
      KnowledgePointKind.architecture,
      now,
      masteryLevel: 100,
    );
    final chunk = _chunk('chunk', source.id, 'Saved project fact.', now);
    final outcome = _build(
      now: now,
      points: [point],
      sources: [source],
      chunks: [chunk],
      relations: [
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: chunk.id,
        ),
      ],
    );

    expect(
      outcome.units.single.status,
      ProjectInterviewOutcomeStatus.notAssessed,
    );
  });

  test('verified practice needs a real review and mastery threshold', () {
    final source = _source('source', SourceTrustLevel.sourceCode, now);
    final chunk = _chunk('chunk', source.id, 'Saved project fact.', now);
    ProjectInterviewOutcome buildFor(int masteryLevel) {
      final point = _point(
        'point',
        KnowledgePointKind.architecture,
        now,
        masteryLevel: masteryLevel,
      );
      return _build(
        now: now.add(const Duration(hours: 1)),
        points: [point],
        sources: [source],
        chunks: [chunk],
        relations: [
          KnowledgePointSource(
            knowledgePointId: point.id,
            sourceChunkId: chunk.id,
          ),
        ],
        questions: [
          Question(
            id: 'question',
            deckId: 'deck',
            knowledgePointId: point.id,
            type: QuestionType.trueFalse,
            content: '项目事实是否正确？',
            answer: 'true',
            sourceStatus: SourceStatus.verified,
            citationIds: [chunk.id],
            lastReviewedAt: now,
          ),
        ],
      );
    }

    expect(
      buildFor(79).units.single.status,
      ProjectInterviewOutcomeStatus.needsPractice,
    );
    expect(
      buildFor(80).units.single.status,
      ProjectInterviewOutcomeStatus.ready,
    );
  });

  test('rejects out-of-scope citations and wrong quotes from formal claims',
      () {
    final source = _source('source', SourceTrustLevel.sourceCode, now);
    final point = _point('point', KnowledgePointKind.tradeOff, now);
    final chunk =
        _chunk('chunk', source.id, 'Retry is bounded to one attempt.', now);
    final outside = _chunk('outside', source.id, 'Unrelated material.', now);
    final turn = InterviewTurn(
      id: 'turn',
      sessionId: 'session',
      questionText: '为什么限制重试？',
      userAnswer: '避免不可控重复执行。',
      aiFeedback: 'feedback',
      referenceAnswer: 'unsupported polished answer',
      knowledgePointId: point.id,
      knowledgePointKind: point.kind,
      citationIds: [chunk.id, outside.id],
      accuracyScore: 4,
      projectDetailScore: 4,
      engineeringScore: 4,
      clarityScore: 4,
      groundedClaims: [
        GroundedClaim(
          section: 'reference_answer',
          text: '重试被限制为一次。',
          evidence: [
            GroundedClaimEvidence(
              citationId: chunk.id,
              quote: 'not an exact saved quote',
            ),
          ],
        ),
      ],
      groundingDisposition: GroundingDisposition.grounded,
      createdAt: now,
    );
    final outcome = _build(
      now: now,
      points: [point],
      sources: [source],
      chunks: [chunk, outside],
      relations: [
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: chunk.id,
        ),
      ],
      turns: [turn],
    );
    final unit = outcome.units.single;

    expect(unit.status, ProjectInterviewOutcomeStatus.evidenceGap);
    expect(unit.referenceOutline, isEmpty);
    expect(
      unit.reasons,
      containsAll([
        ProjectInterviewOutcomeReasonCode.invalidEvaluationCitation,
        ProjectInterviewOutcomeReasonCode.invalidClaimQuote,
      ]),
    );
  });

  test('keeps grounded feedback out of the reference answer outline', () {
    final source = _source('source', SourceTrustLevel.sourceCode, now);
    final point = _point('point', KnowledgePointKind.architecture, now);
    final chunk = _chunk('chunk', source.id, 'Saved project fact.', now);
    final baseTurn = _turn(
      id: 'turn',
      point: point,
      chunk: chunk,
      answer: '我说明了这个项目事实。',
      scores: const [4, 4, 4, 4],
      now: now,
    );
    final turn = baseTurn.copyWith(
      groundedClaims: [
        GroundedClaim(
          section: 'feedback',
          text: '这条反馈有来源，但不是参考回答。',
          evidence: [
            GroundedClaimEvidence(
              citationId: chunk.id,
              quote: chunk.content,
            ),
          ],
        ),
        ...baseTurn.groundedClaims,
      ],
    );
    final outcome = _build(
      now: now,
      points: [point],
      sources: [source],
      chunks: [chunk],
      relations: [
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: chunk.id,
        ),
      ],
      turns: [turn],
    );

    expect(outcome.units.single.referenceOutline, hasLength(1));
    expect(
      outcome.units.single.referenceOutline.single.section,
      'reference_answer',
    );
  });

  test('strongest evidence selection is stable across input order', () {
    final code = _source('code', SourceTrustLevel.sourceCode, now);
    final docs = _source('docs', SourceTrustLevel.officialDoc, now);
    final point = _point('point', KnowledgePointKind.implementation, now);
    final codeChunk =
        _chunk('code-chunk', code.id, 'Implementation fact.', now);
    final docsChunk = _chunk('docs-chunk', docs.id, 'Documented fact.', now);
    final relations = [
      KnowledgePointSource(
        knowledgePointId: point.id,
        sourceChunkId: docsChunk.id,
        relation: KnowledgePointSourceRelation.defines,
      ),
      KnowledgePointSource(
        knowledgePointId: point.id,
        sourceChunkId: codeChunk.id,
        relation: KnowledgePointSourceRelation.implementation,
      ),
    ];

    final forward = _build(
      now: now,
      points: [point],
      sources: [docs, code],
      chunks: [docsChunk, codeChunk],
      relations: relations,
    );
    final reversed = _build(
      now: now,
      points: [point],
      sources: [code, docs],
      chunks: [codeChunk, docsChunk],
      relations: relations.reversed.toList(),
    );

    expect(forward.units.single.strongestEvidence!.chunk.id, 'code-chunk');
    expect(reversed.units.single.strongestEvidence!.chunk.id, 'code-chunk');
  });

  test('Markdown and plain text export every formal claim with a locator', () {
    final source = _source('source', SourceTrustLevel.sourceCode, now);
    final point = _point('point', KnowledgePointKind.architecture, now);
    final chunk = _chunk(
      'chunk',
      source.id,
      'The planner saves one immutable plan snapshot.',
      now,
    );
    final outcome = _build(
      now: now,
      points: [point],
      sources: [source],
      chunks: [chunk],
      relations: [
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: chunk.id,
          relation: KnowledgePointSourceRelation.implementation,
        ),
      ],
      turns: [
        _turn(
          id: 'turn',
          point: point,
          chunk: chunk,
          answer: '我保存不可变计划快照。',
          referenceAnswer: 'UNSUPPORTED_RAW_REFERENCE',
          scores: const [4, 4, 4, 4],
          now: now,
        ),
      ],
    );
    final exporter = ProjectInterviewOutcomeExporter(
      clock: () => DateTime.utc(2026, 7, 16, 10),
    );
    final markdown = exporter.build(
      outcome,
      ProjectInterviewOutcomeExportFormat.markdown,
    );
    final plain = exporter.build(
      outcome,
      ProjectInterviewOutcomeExportFormat.plainText,
    );

    for (final artifact in [markdown, plain]) {
      expect(artifact.content, contains('2026-07-16T10:00:00.000Z'));
      expect(artifact.content, contains('[S1]'));
      expect(artifact.content, contains('lib/example.dart:10-12'));
      expect(artifact.content, isNot(contains('UNSUPPORTED_RAW_REFERENCE')));
      expect(artifact.includedCitationCount, 1);
    }
    for (final line in markdown.content.split('\n').where(
          (line) =>
              line.startsWith('- 已核验摘要:') ||
              line.startsWith('- 最强证据:') ||
              line.startsWith('- 最近面试评分:') ||
              line.startsWith('- The planner saves'),
        )) {
      expect(line, contains('[S1]'), reason: line);
    }
    for (final line in plain.content.split('\n').where(
          (line) =>
              line.startsWith('已核验摘要:') ||
              line.startsWith('最强证据:') ||
              line.startsWith('最近面试评分:') ||
              line.startsWith('  - The planner saves'),
        )) {
      expect(line, contains('[S1]'), reason: line);
    }
  });
}

ProjectInterviewOutcome _build({
  required DateTime now,
  List<KnowledgePoint> points = const [],
  List<Source> sources = const [],
  List<SourceChunk> chunks = const [],
  List<KnowledgePointSource> relations = const [],
  List<InterviewTurn> turns = const [],
  List<Question> questions = const [],
}) {
  return const ProjectInterviewOutcomeService().build(
    knowledgePoints: points,
    knowledgePointSources: relations,
    sources: sources,
    sourceChunks: chunks,
    interviewTurns: turns,
    tutorTurns: const [],
    questions: questions,
    programmingAttempts: const [],
    reviewActions: const [],
    memoryStore: LearningAgentMemoryStore(
      AgentSessionMemoryIndex(const []),
    ),
    now: now,
  );
}

Source _source(String id, SourceTrustLevel trust, DateTime now) {
  return Source(
    id: id,
    title: 'Demo project',
    type: SourceType.codeFile,
    trustLevel: trust,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(
  String id,
  String sourceId,
  String content,
  DateTime now,
) {
  return SourceChunk(
    id: id,
    sourceId: sourceId,
    chunkIndex: 0,
    content: content,
    relativePath: 'lib/example.dart',
    startLine: 10,
    endLine: 12,
    createdAt: now,
  );
}

KnowledgePoint _point(
  String id,
  KnowledgePointKind kind,
  DateTime now, {
  int masteryLevel = 80,
}) {
  return KnowledgePoint(
    id: id,
    title: '$id unit',
    summary: '$id grounded summary',
    kind: kind,
    masteryLevel: masteryLevel,
    interviewRelevance: 5,
    createdAt: now,
    updatedAt: now,
  );
}

InterviewTurn _turn({
  required String id,
  required KnowledgePoint point,
  required SourceChunk chunk,
  required String answer,
  required List<int> scores,
  required DateTime now,
  String? quote,
  String referenceAnswer = 'reference',
}) {
  return InterviewTurn(
    id: id,
    sessionId: 'session-$id',
    questionText: '请解释 ${point.title}',
    userAnswer: answer,
    aiFeedback: 'feedback',
    referenceAnswer: referenceAnswer,
    knowledgePointId: point.id,
    knowledgePointKind: point.kind,
    citationIds: [chunk.id],
    accuracyScore: scores[0],
    projectDetailScore: scores[1],
    engineeringScore: scores[2],
    clarityScore: scores[3],
    groundedClaims: [
      GroundedClaim(
        section: 'reference_answer',
        text: chunk.content,
        evidence: [
          GroundedClaimEvidence(
            citationId: chunk.id,
            quote: quote ?? chunk.content,
          ),
        ],
      ),
    ],
    groundingDisposition: GroundingDisposition.grounded,
    createdAt: now,
  );
}
