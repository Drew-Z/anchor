import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/deck.dart';
import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/interview_turn.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_prerequisite.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/programming_review_action.dart';
import 'package:dlg_q/data/models/product_event.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/models/tutor_turn.dart';
import 'package:dlg_q/services/agent/learning_agent_checkpoint.dart';
import 'package:dlg_q/services/agent/learning_agent_checkpoint_store.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/agent/learning_agent_runtime.dart';
import 'package:dlg_q/services/agent/learning_agent_state.dart';
import 'package:dlg_q/services/agent/learning_agent_tool_registry.dart';
import 'package:dlg_q/services/agent/learning_agent_trace.dart';
import 'package:dlg_q/services/agent/learning_agent_user_decision.dart';

void main() {
  sqfliteFfiInit();

  group('DatabaseHelper schema v23', () {
    test('creates the current schema with Agent and source provenance columns',
        () async {
      final helper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
      );
      addTearDown(helper.close);

      final database = await helper.database;
      expect(await database.getVersion(), 23);

      final stateColumns = await database.rawQuery(
        'PRAGMA table_info(learning_agent_states)',
      );
      expect(
        stateColumns.map((column) => column['name']),
        containsAll([
          'active_tool_operation_id',
          'active_tool_input_snapshot',
          'checkpoint_revision',
        ]),
      );

      final sourceColumns = await database.rawQuery(
        'PRAGMA table_info(sources)',
      );
      expect(
        sourceColumns.map((column) => column['name']),
        containsAll([
          'revision',
          'publisher',
          'license_expression',
          'retrieved_at',
          'content_hash',
        ]),
      );
      final chunkColumns = await database.rawQuery(
        'PRAGMA table_info(source_chunks)',
      );
      expect(
        chunkColumns.map((column) => column['name']),
        containsAll(['relative_path', 'start_line', 'end_line']),
      );
      final knowledgePointColumns = await database.rawQuery(
        'PRAGMA table_info(knowledge_points)',
      );
      expect(
        knowledgePointColumns.map((column) => column['name']),
        contains('kind'),
      );
      final prerequisiteColumns = await database.rawQuery(
        'PRAGMA table_info(knowledge_point_prerequisites)',
      );
      expect(
        prerequisiteColumns.map((column) => column['name']),
        containsAll([
          'knowledge_point_id',
          'prerequisite_knowledge_point_id',
          'rationale',
          'citation_ids',
          'created_at',
        ]),
      );
      final interviewTurnColumns = await database.rawQuery(
        'PRAGMA table_info(interview_turns)',
      );
      final tutorTurnColumns = await database.rawQuery(
        'PRAGMA table_info(tutor_turns)',
      );
      expect(
        tutorTurnColumns.map((column) => column['name']),
        containsAll([
          'knowledge_point_id',
          'question_text',
          'user_answer',
          'ai_feedback',
          'misconception',
          'next_question',
          'citation_ids',
          'prerequisite_knowledge_point_ids',
          'evidence_sufficient',
          'accuracy_score',
          'grounded_claims_json',
          'grounding_disposition',
        ]),
      );
      expect(
        interviewTurnColumns.map((column) => column['name']),
        containsAll([
          'knowledge_point_id',
          'knowledge_point_kind',
          'weak_dimensions',
          'review_question_ids',
          'review_due_at',
          'next_interview_question',
          'grounded_claims_json',
          'grounding_disposition',
        ]),
      );
      final exerciseColumns = await database.rawQuery(
        'PRAGMA table_info(programming_exercises)',
      );
      expect(
        exerciseColumns.map((column) => column['name']),
        containsAll([
          'knowledge_point_id',
          'kind',
          'reference_answer',
          'rubric_concept_accuracy',
          'rubric_reasoning_process',
          'rubric_evidence_use',
          'rubric_clarity',
          'source_status',
          'citation_ids',
          'is_retest',
          'parent_attempt_id',
        ]),
      );
      final attemptColumns = await database.rawQuery(
        'PRAGMA table_info(programming_exercise_attempts)',
      );
      expect(
        attemptColumns.map((column) => column['name']),
        containsAll([
          'exercise_id',
          'knowledge_point_id',
          'concept_accuracy_score',
          'reasoning_process_score',
          'evidence_use_score',
          'clarity_score',
          'misconception_code',
          'misconception_label',
          'repair_explanation',
          'evidence_sufficient',
          'formal_mastery_applied',
          'retest_exercise_id',
          'grounded_claims_json',
          'grounding_disposition',
        ]),
      );
      final reviewActionColumns = await database.rawQuery(
        'PRAGMA table_info(programming_review_actions)',
      );
      expect(
        reviewActionColumns.map((column) => column['name']),
        containsAll([
          'knowledge_point_id',
          'trigger_type',
          'trigger_id',
          'weak_dimensions',
          'prerequisite_knowledge_point_ids',
          'citation_ids',
          'review_question_ids',
          'review_exercise_ids',
          'due_at',
          'created_at',
          'completed_at',
        ]),
      );
      final reviewActionIndexes = await database.rawQuery(
        'PRAGMA index_list(programming_review_actions)',
      );
      expect(
        reviewActionIndexes.map((index) => index['name']),
        contains('idx_programming_review_actions_open_due'),
      );
      final productEventColumns = await database.rawQuery(
        'PRAGMA table_info(product_events)',
      );
      expect(
        productEventColumns.map((column) => column['name']),
        containsAll([
          'id',
          'event_name',
          'schema_version',
          'occurred_at',
          'anonymous_install_id',
          'app_version',
          'platform',
          'flow_id',
          'goal',
          'target_id',
          'session_id',
          'properties_json',
          'dedupe_key',
        ]),
      );
      expect((await helper.getUserStats()).hearts, 5);
    });

    test('upgrades v22 with an empty immutable product event store', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v22_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 16, 10);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertSource(
        Source(
          id: 'v22-source',
          title: 'Preserved source',
          type: SourceType.project,
          trustLevel: SourceTrustLevel.sourceCode,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute('DROP TABLE product_events');
      await legacyDatabase.setVersion(22);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      final upgradedDatabase = await upgradedHelper.database;
      expect(await upgradedDatabase.getVersion(), 23);
      expect((await upgradedHelper.getAllSources()).single.id, 'v22-source');

      final inserted = await upgradedHelper.insertProductEvent(
        ProductEvent(
          id: 'event-v23',
          name: ProductEventName.onboardingStarted,
          occurredAt: now,
          anonymousInstallId: 'install-v23',
          appVersion: '1.0.0+1',
          platform: 'test',
          flowId: 'migration_test',
          goal: 'unknown',
          properties: const {'entry_point': 'migration'},
          dedupeKey: 'migration:event',
        ),
      );
      expect(inserted, isTrue);
      expect(await upgradedHelper.countProductEvents(), 1);
    });

    test('upgrades v11 without losing learning data or active operation state',
        () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v11_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final seededAt = DateTime(2026, 7, 14, 9);

      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertDeck(
        Deck(
          id: 'deck-v11',
          title: 'V11 project deck',
          createdAt: seededAt,
          updatedAt: seededAt,
        ),
      );
      await seedHelper.insertQuestion(
        Question(
          id: 'question-v11',
          deckId: 'deck-v11',
          type: QuestionType.multipleChoice,
          content: 'Which checkpoint identity survives retry?',
          options: const ['operationId', 'attemptId'],
          answer: 'operationId',
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute(
        'ALTER TABLE learning_agent_states '
        'DROP COLUMN active_tool_input_snapshot',
      );

      const sessionId = 'session-v11';
      const toolId = 'open_interview_session';
      const operationId = 'operation-v11';
      const attemptId = 'attempt-v11';
      final decision = LearningAgentUserDecisionRequest.toolOutcomeUnknown(
        sessionId: sessionId,
        toolTitle: '启动面试模式',
        toolId: toolId,
        operationId: operationId,
        attemptId: attemptId,
        requestedAt: seededAt,
      );
      await legacyDatabase.insert('learning_agent_states', {
        'session_id': sessionId,
        'goal': LearningAgentGoal.projectWalkthrough.value,
        'phase': LearningAgentPhase.act.value,
        'target_id': 'project-v11',
        'focus_point_id': 'knowledge-v11',
        'available_tool_ids': toolId,
        'selected_tool_id': toolId,
        'active_tool_operation_id': operationId,
        'evidence_chunk_ids': 'chunk-b\x00chunk-a',
        'pending_user_decision': decision.toStorageValue(),
        'policy_warnings': null,
        'trace_event_ids': attemptId,
        'plan_snapshot': null,
        'checkpoint_revision': 3,
        'created_at': seededAt.millisecondsSinceEpoch,
        'updated_at': seededAt.millisecondsSinceEpoch,
      });
      final attempt = LearningAgentTraceEvent(
        id: attemptId,
        sessionId: sessionId,
        goal: LearningAgentGoal.projectWalkthrough,
        type: LearningAgentTraceEventType.toolStarted,
        occurredAt: seededAt,
        phase: LearningAgentPhase.act,
        targetId: 'project-v11',
        toolId: toolId,
        summary: 'V11 tool attempt started',
      ).toMap();
      attempt['sequence_index'] = 0;
      await legacyDatabase.insert('learning_agent_trace_events', attempt);
      await legacyDatabase.setVersion(11);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      final upgradedDatabase = await upgradedHelper.database;

      expect(await upgradedDatabase.getVersion(), 23);
      expect((await upgradedHelper.getAllDecks()).single.id, 'deck-v11');
      expect(
        (await upgradedHelper.getAllQuestions()).single.id,
        'question-v11',
      );

      final store = SqliteLearningAgentCheckpointStore(upgradedHelper);
      final migratedCheckpoint = await store.load(sessionId);
      expect(migratedCheckpoint, isNotNull);
      expect(migratedCheckpoint!.revision, 3);
      expect(migratedCheckpoint.state.activeToolOperationId, operationId);
      expect(
        migratedCheckpoint.state.activeToolInputSnapshot?.toolId,
        toolId,
      );
      expect(
        migratedCheckpoint.state.activeToolInputSnapshot?.evidenceChunkIds,
        ['chunk-a', 'chunk-b'],
      );
      expect(
          migratedCheckpoint.state.pendingUserDecision?.attemptId, attemptId);
      expect(migratedCheckpoint.traceEvents.single.id, attemptId);

      final resavedCheckpoint = await store.save(migratedCheckpoint);
      expect(resavedCheckpoint.revision, 4);
      final persistedState =
          await upgradedHelper.getLearningAgentStateMap(sessionId);
      expect(persistedState?['active_tool_input_snapshot'], isNotNull);
    });

    test('persists structured project source provenance', () async {
      final helper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
      );
      addTearDown(helper.close);
      final now = DateTime(2026, 7, 14, 18);
      const sourceId = 'source-v13';

      await helper.insertSource(
        Source(
          id: sourceId,
          title: 'Duoduo source',
          type: SourceType.project,
          uri: 'D:/workspace/duoduo',
          revision: 'git:abc;snapshot:def',
          trustLevel: SourceTrustLevel.sourceCode,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await helper.insertSourceChunk(
        SourceChunk(
          id: 'chunk-v13',
          sourceId: sourceId,
          chunkIndex: 0,
          content: 'class App {}',
          locator: 'lib/app.dart:1-1',
          relativePath: 'lib/app.dart',
          startLine: 1,
          endLine: 1,
          contentHash: 'sha256',
          createdAt: now,
        ),
      );

      final source = await helper.getSource(sourceId);
      final chunks = await helper.getSourceChunks(sourceId);
      expect(source?.revision, 'git:abc;snapshot:def');
      expect(chunks.single.relativePath, 'lib/app.dart');
      expect(chunks.single.startLine, 1);
      expect(chunks.single.endLine, 1);
    });

    test('upgrades v13 knowledge points with a concept kind', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v13_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 14, 20);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertKnowledgePoint(
        KnowledgePoint(
          id: 'legacy-point',
          title: 'Legacy concept',
          summary: 'Created before project understanding kinds.',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute(
        'ALTER TABLE knowledge_points DROP COLUMN kind',
      );
      await legacyDatabase.setVersion(13);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      final point = await upgradedHelper.getKnowledgePoint('legacy-point');
      expect(point?.kind, KnowledgePointKind.concept);
    });

    test('upgrades v14 interview turns with auditable project provenance',
        () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v14_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 9);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertLearningSession(
        LearningSession(
          id: 'session-v14',
          mode: LearningSessionMode.interview,
          startedAt: now,
        ),
      );
      await seedHelper.insertInterviewTurn(
        InterviewTurn(
          id: 'turn-v14',
          sessionId: 'session-v14',
          questionText: 'How does the project flow work?',
          userAnswer: 'Through the persisted source pipeline.',
          aiFeedback: 'Add implementation detail.',
          referenceAnswer: 'Explain the source-backed pipeline.',
          knowledgePointId: 'point-architecture',
          knowledgePointKind: KnowledgePointKind.architecture,
          citationIds: const ['chunk-v14'],
          createdAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute(
        'ALTER TABLE interview_turns DROP COLUMN knowledge_point_id',
      );
      await legacyDatabase.execute(
        'ALTER TABLE interview_turns DROP COLUMN knowledge_point_kind',
      );
      await legacyDatabase.setVersion(14);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      final turn =
          (await upgradedHelper.getInterviewTurns('session-v14')).single;
      expect(turn.id, 'turn-v14');
      expect(turn.knowledgePointId, isNull);
      expect(turn.knowledgePointKind, KnowledgePointKind.concept);
      expect(turn.citationIds, ['chunk-v14']);
    });

    test('upgrades v15 turns with empty review actions', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v15_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 10);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertLearningSession(
        LearningSession(
          id: 'session-v15',
          mode: LearningSessionMode.interview,
          startedAt: now,
        ),
      );
      await seedHelper.insertInterviewTurn(
        InterviewTurn(
          id: 'turn-v15',
          sessionId: 'session-v15',
          questionText: 'Where is the boundary?',
          userAnswer: 'At the repository.',
          aiFeedback: 'Add evidence.',
          referenceAnswer: 'Cite the repository implementation.',
          knowledgePointId: 'point-boundary',
          knowledgePointKind: KnowledgePointKind.boundary,
          citationIds: const ['chunk-v15'],
          weakDimensions: const [InterviewScoreDimension.projectDetail],
          reviewQuestionIds: const ['question-v15'],
          reviewDueAt: now,
          nextInterviewQuestion: 'Explain the boundary with evidence.',
          createdAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      for (final column in [
        'weak_dimensions',
        'review_question_ids',
        'review_due_at',
        'next_interview_question',
      ]) {
        await legacyDatabase.execute(
          'ALTER TABLE interview_turns DROP COLUMN $column',
        );
      }
      await legacyDatabase.setVersion(15);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      final turn =
          (await upgradedHelper.getInterviewTurns('session-v15')).single;
      expect(turn.knowledgePointId, 'point-boundary');
      expect(turn.knowledgePointKind, KnowledgePointKind.boundary);
      expect(turn.weakDimensions, isEmpty);
      expect(turn.reviewQuestionIds, isEmpty);
      expect(turn.reviewDueAt, isNull);
      expect(turn.nextInterviewQuestion, isEmpty);
    });

    test('upgrades v16 sources with empty programming provenance', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v16_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 12);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertSource(
        Source(
          id: 'source-v16',
          title: 'Legacy official docs',
          type: SourceType.officialDoc,
          uri: 'https://example.com/docs',
          revision: '1.0',
          trustLevel: SourceTrustLevel.officialDoc,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      for (final column in [
        'publisher',
        'license_expression',
        'retrieved_at',
        'content_hash',
      ]) {
        await legacyDatabase.execute('ALTER TABLE sources DROP COLUMN $column');
      }
      await legacyDatabase.setVersion(16);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      final source = await upgradedHelper.getSource('source-v16');
      expect(source?.title, 'Legacy official docs');
      expect(source?.uri, 'https://example.com/docs');
      expect(source?.revision, '1.0');
      expect(source?.publisher, isNull);
      expect(source?.licenseExpression, isNull);
      expect(source?.retrievedAt, isNull);
      expect(source?.contentHash, isEmpty);
    });

    test('upgrades v17 with an empty prerequisite graph', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v17_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 14);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      for (final point in [
        KnowledgePoint(
          id: 'concept-a',
          title: 'Concept A',
          summary: 'First concept.',
          createdAt: now,
          updatedAt: now,
        ),
        KnowledgePoint(
          id: 'concept-b',
          title: 'Concept B',
          summary: 'Second concept.',
          createdAt: now,
          updatedAt: now,
        ),
      ]) {
        await seedHelper.insertKnowledgePoint(point);
      }
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute('DROP TABLE knowledge_point_prerequisites');
      await legacyDatabase.setVersion(17);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      expect(await upgradedHelper.getKnowledgePointPrerequisites(), isEmpty);

      await upgradedHelper.replaceKnowledgePointPrerequisites(
        scopeKnowledgePointIds: const ['concept-a', 'concept-b'],
        relations: [
          KnowledgePointPrerequisite(
            knowledgePointId: 'concept-b',
            prerequisiteKnowledgePointId: 'concept-a',
            rationale: 'A is required before B.',
            citationIds: const ['chunk-a'],
            createdAt: now,
          ),
        ],
      );
      final relation =
          (await upgradedHelper.getKnowledgePointPrerequisites()).single;
      expect(relation.prerequisiteKnowledgePointId, 'concept-a');
      expect(relation.knowledgePointId, 'concept-b');
      expect(relation.citationIds, ['chunk-a']);
    });

    test('upgrades v18 with an empty tutor loop and persists a turn', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v18_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 16);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertKnowledgePoint(
        KnowledgePoint(
          id: 'tutor-point',
          title: 'Tutor point',
          summary: 'Source-backed concept.',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.insertLearningSession(
        LearningSession(
          id: 'tutor-session-v18',
          mode: LearningSessionMode.tutor,
          targetId: 'tutor-point',
          startedAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute('DROP TABLE tutor_turns');
      await legacyDatabase.setVersion(18);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      expect(await upgradedHelper.getTutorTurns('tutor-session-v18'), isEmpty);

      await upgradedHelper.insertTutorTurn(
        TutorTurn(
          id: 'turn-1',
          sessionId: 'tutor-session-v18',
          knowledgePointId: 'tutor-point',
          questionText: 'What changes?',
          userAnswer: 'The state changes.',
          aiFeedback: 'Name the rebuild boundary.',
          misconception: 'State mutation alone redraws the UI.',
          nextQuestion: 'What schedules the rebuild?',
          citationIds: const ['chunk-state'],
          prerequisiteKnowledgePointIds: const ['widget-basics'],
          accuracyScore: 60,
          createdAt: now,
        ),
      );
      final turn =
          (await upgradedHelper.getTutorTurns('tutor-session-v18')).single;
      expect(turn.misconception, contains('mutation'));
      expect(turn.nextQuestion, 'What schedules the rebuild?');
      expect(turn.citationIds, ['chunk-state']);
      expect(turn.prerequisiteKnowledgePointIds, ['widget-basics']);
      expect(turn.evidenceSufficient, isTrue);
      expect(turn.accuracyScore, 60);
    });

    test('upgrades v19 and persists grounded exercises and attempts', () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v19_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 18);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertKnowledgePoint(
        KnowledgePoint(
          id: 'exercise-point',
          title: 'Exercise point',
          summary: 'A source-backed programming concept.',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute('PRAGMA foreign_keys = OFF');
      await legacyDatabase.execute('DROP TABLE programming_exercise_attempts');
      await legacyDatabase.execute('DROP TABLE programming_exercises');
      await legacyDatabase.setVersion(19);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      expect(
        await upgradedHelper.getProgrammingExercisesForKnowledgePoint(
          'exercise-point',
        ),
        isEmpty,
      );

      final exercise = ProgrammingExercise(
        id: 'exercise-1',
        knowledgePointId: 'exercise-point',
        kind: ProgrammingExerciseKind.codeReading,
        prompt: 'Explain what the cited code returns.',
        referenceAnswer: 'It returns the persisted value.',
        conceptAccuracyCriterion: 'Identify the returned value.',
        reasoningProcessCriterion: 'Trace the return path.',
        evidenceUseCriterion: 'Cite the provided code.',
        clarityCriterion: 'State the result directly.',
        sourceStatus: SourceStatus.verified,
        citationIds: const ['chunk-code'],
        createdAt: now,
        updatedAt: now,
      );
      await upgradedHelper.insertProgrammingExercise(exercise);
      var attempt = ProgrammingExerciseAttempt(
        id: 'attempt-1',
        exerciseId: exercise.id,
        knowledgePointId: exercise.knowledgePointId,
        userAnswer: 'It returns a new value without persistence.',
        feedback: 'The answer missed the persisted return path.',
        conceptAccuracyScore: 45,
        reasoningProcessScore: 50,
        evidenceUseScore: 30,
        clarityScore: 75,
        misconceptionCode: 'return_path_confusion',
        misconceptionLabel: '把临时值误认为持久化返回值',
        repairExplanation: 'Follow the cited return statement.',
        citationIds: const ['chunk-code'],
        createdAt: now,
      );
      await upgradedHelper.insertProgrammingExerciseAttempt(attempt);
      final retest = exercise.copyWith(
        id: 'retest-1',
        prompt: 'Trace the return path again.',
        isRetest: true,
        parentAttemptId: attempt.id,
        sourceStatus: SourceStatus.pending,
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
      );
      await upgradedHelper.insertProgrammingExercise(retest);
      attempt = attempt.copyWith(retestExerciseId: retest.id);
      await upgradedHelper.updateProgrammingExerciseAttempt(attempt);

      final exercises = await upgradedHelper
          .getProgrammingExercisesForKnowledgePoint('exercise-point');
      final attempts =
          await upgradedHelper.getProgrammingExerciseAttempts(exercise.id);
      expect(exercises, hasLength(2));
      expect(exercises.last.isRetest, isTrue);
      expect(exercises.last.parentAttemptId, attempt.id);
      expect(attempts.single.averageScore, 50);
      expect(attempts.single.misconceptionCode, 'return_path_confusion');
      expect(attempts.single.retestExerciseId, retest.id);
      expect(attempts.single.formalMasteryApplied, isFalse);
    });

    test('upgrades v20 and persists unique open programming review actions',
        () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v20_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 19);
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertKnowledgePoint(
        KnowledgePoint(
          id: 'review-point',
          title: 'Programming review point',
          summary: 'A weak source-grounded programming concept.',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      await legacyDatabase.execute('DROP TABLE programming_review_actions');
      await legacyDatabase.setVersion(20);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      final upgradedDatabase = await upgradedHelper.database;
      expect(await upgradedDatabase.getVersion(), 23);
      expect(await upgradedHelper.getOpenProgrammingReviewActions(), isEmpty);

      final original = ProgrammingReviewAction(
        id: 'review-action-original',
        knowledgePointId: 'review-point',
        triggerType: ProgrammingReviewTriggerType.tutorTurn,
        triggerId: 'tutor-turn-1',
        weakDimensions: const [
          ProgrammingWeakDimension.conceptAccuracy,
        ],
        prerequisiteKnowledgePointIds: const ['prerequisite-1'],
        citationIds: const ['chunk-1', 'chunk-2'],
        reviewQuestionIds: const ['question-1'],
        reviewExerciseIds: const ['exercise-1'],
        dueAt: now,
        createdAt: now,
      );
      await upgradedHelper.upsertProgrammingReviewAction(original);
      expect(
        (await upgradedHelper.getProgrammingReviewAction(original.id))
            ?.reviewExerciseIds,
        ['exercise-1'],
      );

      final replacement = original.copyWith(
        id: 'review-action-replacement',
        weakDimensions: const [
          ProgrammingWeakDimension.conceptAccuracy,
          ProgrammingWeakDimension.evidenceUse,
        ],
        reviewQuestionIds: const ['question-2'],
      );
      await upgradedHelper.upsertProgrammingReviewAction(replacement);
      expect(
        await upgradedHelper.getProgrammingReviewAction(original.id),
        isNull,
      );
      expect(
        (await upgradedHelper.getOpenProgrammingReviewActions()).single.id,
        replacement.id,
      );

      await upgradedHelper.updateProgrammingReviewAction(
        replacement.copyWith(completedAt: now.add(const Duration(minutes: 5))),
      );
      expect(await upgradedHelper.getOpenProgrammingReviewActions(), isEmpty);

      final reviewActionIndexes = await upgradedDatabase.rawQuery(
        'PRAGMA index_list(programming_review_actions)',
      );
      expect(
        reviewActionIndexes.map((index) => index['name']),
        contains('idx_programming_review_actions_open_due'),
      );
    });

    test('upgrades v21 grounding history as legacy and round-trips new claims',
        () async {
      final temporaryDirectory =
          await Directory.systemTemp.createTemp('duoduo_v21_migration_');
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final databasePath = path.join(temporaryDirectory.path, 'duoduo.db');
      final now = DateTime(2026, 7, 15, 20);
      const claim = GroundedClaim(
        section: 'feedback',
        text: 'The cited repository persists the attempt.',
        evidence: [
          GroundedClaimEvidence(
            citationId: 'chunk-grounding',
            quote: 'persists the attempt',
          ),
        ],
      );
      final seedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      await seedHelper.insertKnowledgePoint(
        KnowledgePoint(
          id: 'grounding-point',
          title: 'Grounding point',
          summary: 'A point used to verify claim persistence.',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seedHelper.insertLearningSession(
        LearningSession(
          id: 'grounding-session',
          mode: LearningSessionMode.tutor,
          targetId: 'grounding-point',
          startedAt: now,
        ),
      );
      final exercise = ProgrammingExercise(
        id: 'grounding-exercise',
        knowledgePointId: 'grounding-point',
        kind: ProgrammingExerciseKind.explanation,
        prompt: 'Explain the persistence path.',
        referenceAnswer: 'The repository persists the attempt.',
        conceptAccuracyCriterion: 'Name the persistence behavior.',
        reasoningProcessCriterion: 'Trace the repository call.',
        evidenceUseCriterion: 'Use the cited chunk.',
        clarityCriterion: 'State the behavior directly.',
        sourceStatus: SourceStatus.verified,
        citationIds: const ['chunk-grounding'],
        createdAt: now,
        updatedAt: now,
      );
      await seedHelper.insertProgrammingExercise(exercise);
      await seedHelper.insertInterviewTurn(
        InterviewTurn(
          id: 'legacy-interview-turn',
          sessionId: 'grounding-session',
          questionText: 'What is persisted?',
          userAnswer: 'The attempt.',
          aiFeedback: claim.text,
          referenceAnswer: claim.text,
          knowledgePointId: 'grounding-point',
          citationIds: const ['chunk-grounding'],
          groundedClaims: const [claim],
          createdAt: now,
        ),
      );
      await seedHelper.insertTutorTurn(
        TutorTurn(
          id: 'legacy-tutor-turn',
          sessionId: 'grounding-session',
          knowledgePointId: 'grounding-point',
          questionText: 'What is persisted?',
          userAnswer: 'The attempt.',
          aiFeedback: claim.text,
          citationIds: const ['chunk-grounding'],
          groundedClaims: const [claim],
          createdAt: now,
        ),
      );
      await seedHelper.insertProgrammingExerciseAttempt(
        ProgrammingExerciseAttempt(
          id: 'legacy-attempt',
          exerciseId: exercise.id,
          knowledgePointId: exercise.knowledgePointId,
          userAnswer: 'The repository persists the attempt.',
          feedback: claim.text,
          citationIds: const ['chunk-grounding'],
          groundedClaims: const [claim],
          createdAt: now,
        ),
      );
      await seedHelper.close();

      final legacyDatabase =
          await databaseFactoryFfi.openDatabase(databasePath);
      for (final table in [
        'interview_turns',
        'tutor_turns',
        'programming_exercise_attempts',
      ]) {
        await legacyDatabase.execute(
          'ALTER TABLE $table DROP COLUMN grounded_claims_json',
        );
        await legacyDatabase.execute(
          'ALTER TABLE $table DROP COLUMN grounding_disposition',
        );
      }
      await legacyDatabase.setVersion(21);
      await legacyDatabase.close();

      final upgradedHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(upgradedHelper.close);
      expect(await (await upgradedHelper.database).getVersion(), 23);
      final legacyInterview =
          (await upgradedHelper.getInterviewTurns('grounding-session')).single;
      final legacyTutor =
          (await upgradedHelper.getTutorTurns('grounding-session')).single;
      final legacyAttempt =
          (await upgradedHelper.getProgrammingExerciseAttempts(exercise.id))
              .single;
      for (final disposition in [
        legacyInterview.groundingDisposition,
        legacyTutor.groundingDisposition,
        legacyAttempt.groundingDisposition,
      ]) {
        expect(disposition, GroundingDisposition.legacy);
      }
      expect(legacyInterview.groundedClaims, isEmpty);
      expect(legacyTutor.groundedClaims, isEmpty);
      expect(legacyAttempt.groundedClaims, isEmpty);

      await upgradedHelper.insertTutorTurn(
        TutorTurn(
          id: 'grounded-tutor-turn',
          sessionId: 'grounding-session',
          knowledgePointId: 'grounding-point',
          questionText: 'What is persisted now?',
          userAnswer: 'The attempt.',
          aiFeedback: claim.text,
          citationIds: const ['chunk-grounding'],
          groundedClaims: const [claim],
          groundingDisposition: GroundingDisposition.grounded,
          createdAt: now.add(const Duration(minutes: 1)),
        ),
      );
      final groundedTutor =
          (await upgradedHelper.getTutorTurns('grounding-session'))
              .singleWhere((turn) => turn.id == 'grounded-tutor-turn');
      expect(groundedTutor.groundingDisposition, GroundingDisposition.grounded);
      expect(groundedTutor.groundedClaims.single.text, claim.text);
      expect(
        groundedTutor.groundedClaims.single.evidence.single.quote,
        'persists the attempt',
      );
    });
  });

  test('SQLite checkpoint store durably resolves a user decision', () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final store = SqliteLearningAgentCheckpointStore(helper);
    final runtime = LearningAgentRuntime(checkpointStore: store);
    final now = DateTime(2026, 7, 14, 10);
    final decision = LearningAgentUserDecisionRequest.toolInterrupted(
      sessionId: 'decision-session',
      toolTitle: '导入来源',
      toolId: LearningAgentToolId.importSources.value,
      requestedAt: now,
    );
    final state = LearningAgentState(
      sessionId: 'decision-session',
      goal: LearningAgentGoal.projectWalkthrough,
      phase: LearningAgentPhase.act,
      targetId: 'import_sources',
      availableToolIds: [LearningAgentToolId.importSources.value],
      selectedToolId: LearningAgentToolId.importSources.value,
      pendingUserDecision: decision,
      createdAt: now,
      updatedAt: now,
    );
    final trace = LearningAgentTraceEvent(
      id: 'decision-plan-created',
      sessionId: state.sessionId,
      goal: state.goal,
      type: LearningAgentTraceEventType.planCreated,
      occurredAt: now,
      phase: LearningAgentPhase.plan,
      targetId: state.targetId,
      toolId: state.selectedToolId,
      summary: 'Created decision test plan',
    );
    final initialCheckpoint = LearningAgentCheckpoint(
      state: state,
      traceEvents: [trace],
      plan: _importSourcesPlan(),
    );

    final savedCheckpoint = await store.save(initialCheckpoint);
    expect(savedCheckpoint.revision, 1);
    final loadedCheckpoint = await store.load(state.sessionId);
    expect(loadedCheckpoint?.state.pendingUserDecision?.id, decision.id);

    final result = await runtime.resolveUserDecision(
      loadedCheckpoint!,
      action: LearningAgentUserDecisionAction.cancelSession,
      resolvedAt: DateTime(2026, 7, 14, 10, 5),
    );
    expect(result.checkpoint.revision, 2);
    expect(result.checkpoint.state.phase, LearningAgentPhase.canceled);
    expect(result.checkpoint.state.pendingUserDecision, isNull);

    final reloadedCheckpoint = await store.load(state.sessionId);
    expect(reloadedCheckpoint?.revision, 2);
    expect(reloadedCheckpoint?.state.phase, LearningAgentPhase.canceled);
    expect(
      reloadedCheckpoint?.traceEvents.last.type,
      LearningAgentTraceEventType.userDecisionResolved,
    );
  });
}

LearningAgentPlan _importSourcesPlan() {
  const step = LearningAgentPlanStep(
    type: LearningAgentStepType.importSources,
    title: 'Import sources',
    description: 'Import project evidence',
    enabled: true,
    targetCount: 1,
  );
  return LearningAgentPlan(
    goal: LearningAgentGoal.projectWalkthrough,
    readiness: const LearningAgentReadiness(
      evidenceBackedPointCount: 0,
      practiceablePointCount: 0,
      verifiedQuestionCount: 0,
      pendingQuestionCount: 0,
    ),
    memory: const LearningAgentMemoryState(
      goalSessionCount: 0,
      goalOpenFollowUpCount: 0,
    ),
    steps: const [step],
    sessionSummary: const LearningAgentSessionSummary(
      goal: LearningAgentGoal.projectWalkthrough,
      nextStep: step,
      focusPoint: null,
      title: 'Import sources',
      objective: 'Import project evidence',
      targetLabel: '来源库',
      evidenceConstraint: 'Source required',
      memoryReminder: null,
      successCriteria: ['Import one source'],
      reflectionPrompts: ['What changed?'],
    ),
  );
}
