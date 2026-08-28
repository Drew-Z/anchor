import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/data/repositories/source_repository.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_store.dart';
import 'package:anchor_learning/services/agent/project_interview_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('real SQLite records build a traceable ready outcome', () async {
    final now = DateTime.utc(2026, 7, 16, 9);
    final database = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(database.close);
    final sourceRepository = SourceRepository(database);
    final chunkRepository = SourceChunkRepository(database);
    final pointRepository = KnowledgePointRepository(database);
    final sessionRepository = LearningSessionRepository(database);
    final questionRepository = QuestionRepository(database);
    final source = Source(
      id: 'source',
      title: 'SQLite project',
      type: SourceType.project,
      trustLevel: SourceTrustLevel.sourceCode,
      createdAt: now,
      updatedAt: now,
    );
    final chunk = SourceChunk(
      id: 'chunk',
      sourceId: source.id,
      chunkIndex: 0,
      content: 'The executor validates every tool input before dispatch.',
      relativePath: 'lib/executor.dart',
      startLine: 40,
      endLine: 44,
      createdAt: now,
    );
    final point = KnowledgePoint(
      id: 'point',
      title: 'Tool input boundary',
      summary: 'The executor validates tool input before dispatch.',
      kind: KnowledgePointKind.boundary,
      masteryLevel: 85,
      interviewRelevance: 5,
      createdAt: now,
      updatedAt: now,
    );
    final session = LearningSession(
      id: 'session',
      mode: LearningSessionMode.interview,
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 4)),
    );
    final turn = InterviewTurn(
      id: 'turn',
      sessionId: session.id,
      questionText: '工具调用前如何防止错误输入？',
      userAnswer: 'executor 在 dispatch 前校验每个工具输入。',
      aiFeedback: 'grounded',
      referenceAnswer: 'reference',
      knowledgePointId: point.id,
      knowledgePointKind: point.kind,
      citationIds: [chunk.id],
      accuracyScore: 4,
      projectDetailScore: 5,
      engineeringScore: 4,
      clarityScore: 4,
      groundedClaims: [
        GroundedClaim(
          section: 'reference_answer',
          text: 'The executor validates every tool input before dispatch.',
          evidence: [
            GroundedClaimEvidence(
              citationId: chunk.id,
              quote: chunk.content,
            ),
          ],
        ),
      ],
      groundingDisposition: GroundingDisposition.grounded,
      createdAt: now.add(const Duration(minutes: 3)),
    );

    await sourceRepository.insertSource(source);
    await chunkRepository.insertSourceChunk(chunk);
    await pointRepository.insertKnowledgePoint(point);
    await pointRepository.addKnowledgePointSource(
      KnowledgePointSource(
        knowledgePointId: point.id,
        sourceChunkId: chunk.id,
        relation: KnowledgePointSourceRelation.implementation,
      ),
    );
    await sessionRepository.insertLearningSession(session);
    await sessionRepository.insertInterviewTurn(turn);

    final sources = await sourceRepository.getAllSources();
    final chunks = <SourceChunk>[];
    for (final savedSource in sources) {
      chunks.addAll(await chunkRepository.getSourceChunks(savedSource.id));
    }
    final savedSessions = await sessionRepository.getLearningSessions();
    final outcome = const ProjectInterviewOutcomeService().build(
      knowledgePoints: await pointRepository.getAllKnowledgePoints(),
      knowledgePointSources:
          await pointRepository.getAllKnowledgePointSources(),
      sources: sources,
      sourceChunks: chunks,
      interviewTurns: await sessionRepository.getAllInterviewTurns(),
      tutorTurns: await sessionRepository.getAllTutorTurns(),
      questions: await questionRepository.getAllQuestions(),
      programmingAttempts: const [],
      reviewActions: const [],
      memoryStore: LearningAgentMemoryStore(
        AgentSessionMemoryIndex(savedSessions),
      ),
      now: now.add(const Duration(hours: 1)),
    );

    expect(outcome.units, hasLength(1));
    expect(
      outcome.units.single.status,
      ProjectInterviewOutcomeStatus.ready,
    );
    expect(outcome.units.single.latestAnswer!.text, contains('dispatch'));
    expect(
      outcome.units.single.referenceOutline.single.text,
      contains('validates every tool input'),
    );
    expect(
      outcome.units.single.strongestEvidence!.locator,
      'lib/executor.dart:40-44',
    );
  });
}
