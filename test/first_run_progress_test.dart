import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/deck.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/repositories/deck_repository.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/learning_session_repository.dart';
import 'package:dlg_q/data/repositories/question_repository.dart';
import 'package:dlg_q/data/repositories/source_chunk_repository.dart';
import 'package:dlg_q/data/repositories/source_repository.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/onboarding/first_run_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final startedAt = DateTime.utc(2026, 7, 16, 8);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first-run progress round-trips versioned orchestration metadata', () {
    final progress = FirstRunProgress(
      step: FirstRunStep.outcomePreview,
      selectedGoal: LearningAgentGoal.projectWalkthrough,
      sourceId: 'source-1',
      sessionId: 'session-1',
      startedAt: startedAt,
      updatedAt: startedAt.add(const Duration(minutes: 5)),
    );

    final decoded = FirstRunProgress.fromJson(progress.toJson());

    expect(decoded, progress);
    expect(decoded.schemaVersion, FirstRunProgress.currentSchemaVersion);
    expect(decoded.toJson().containsKey('api_key'), isFalse);
  });

  test('clean install persists every durable first-run boundary', () async {
    final store = _MemoryFirstRunProgressStore();
    await store.write(FirstRunProgress.initial(now: startedAt));
    final notifier = FirstRunProgressNotifier(
      store: store,
      bootstrapService: _bootstrap(),
      clock: () => startedAt,
      autoLoad: false,
    );

    await notifier.load();
    expect(notifier.state.value!.step, FirstRunStep.goal);

    await notifier.confirmGoal(LearningAgentGoal.projectWalkthrough);
    expect(notifier.state.value!.step, FirstRunStep.modelReadiness);

    await notifier.continueToProjectImport();
    expect(notifier.state.value!.step, FirstRunStep.projectImport);

    await notifier.recordImportedSource('source-1');
    expect(notifier.state.value!.step, FirstRunStep.coverageReview);
    expect(notifier.state.value!.sourceId, 'source-1');

    await notifier.recordCoverageReviewed();
    expect(notifier.state.value!.step, FirstRunStep.firstSession);

    await notifier.recordCompletedSession('session-1');
    expect(notifier.state.value!.step, FirstRunStep.outcomePreview);
    expect(notifier.state.value!.sessionId, 'session-1');

    await notifier.complete();
    expect(notifier.state.value!.step, FirstRunStep.completed);
    expect(store.value?.completedAt, isNotNull);
    expect(store.writeCount, 7);
  });

  test('clean install seeds demo data and completes first run', () async {
    final store = _MemoryFirstRunProgressStore();
    var seedCount = 0;
    final notifier = FirstRunProgressNotifier(
      store: store,
      bootstrapService: _bootstrap(
        demoDataSeeder: () async {
          seedCount++;
        },
      ),
      clock: () => startedAt,
      autoLoad: false,
    );

    await notifier.load();

    final progress = notifier.state.value!;
    expect(seedCount, 1);
    expect(progress.step, FirstRunStep.completed);
    expect(progress.selectedGoal, LearningAgentGoal.programmingFoundations);
    expect(progress.legacyUser, isFalse);
    expect(progress.completedAt, startedAt);
    expect(store.value, progress);
  });

  test('existing local data bootstraps as a non-destructive legacy user',
      () async {
    final source = _source(startedAt);
    final store = _MemoryFirstRunProgressStore();
    final notifier = FirstRunProgressNotifier(
      store: store,
      bootstrapService: _bootstrap(sources: [source]),
      clock: () => startedAt,
      autoLoad: false,
    );

    await notifier.load();

    final progress = notifier.state.value!;
    expect(progress.step, FirstRunStep.completed);
    expect(progress.legacyUser, isTrue);
    expect(progress.completedAt, startedAt);
  });

  test('clean SQLite database is recognized as a new installation', () async {
    final databaseHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(databaseHelper.close);
    final bootstrap = FirstRunBootstrapService(
      sourceRepository: SourceRepository(databaseHelper),
      sourceChunkRepository: SourceChunkRepository(databaseHelper),
      knowledgePointRepository: KnowledgePointRepository(databaseHelper),
      deckRepository: DeckRepository(databaseHelper),
      questionRepository: QuestionRepository(databaseHelper),
      learningSessionRepository: LearningSessionRepository(databaseHelper),
      databaseHelper: databaseHelper,
    );

    expect(
      await bootstrap.hasExistingUserData().timeout(const Duration(seconds: 5)),
      isFalse,
    );
  });

  test('resume derives coverage, verified content and completed session',
      () async {
    final source = _source(startedAt);
    final chunk = _chunk(source.id, startedAt);
    final relation = KnowledgePointSource(
      knowledgePointId: 'point-1',
      sourceChunkId: chunk.id,
    );
    final session = LearningSession(
      id: 'session-1',
      mode: LearningSessionMode.agentSession,
      startedAt: startedAt.add(const Duration(minutes: 10)),
      endedAt: startedAt.add(const Duration(minutes: 20)),
    );
    final bootstrap = _bootstrap(
      sources: [source],
      chunks: [chunk],
      relations: [relation],
      sessions: [session],
    );
    final imported = FirstRunProgress(
      step: FirstRunStep.projectImport,
      selectedGoal: LearningAgentGoal.aiInterviewPrep,
      sourceId: source.id,
      startedAt: startedAt,
      updatedAt: startedAt,
    );

    final reconciled = await bootstrap.reconcile(imported, now: startedAt);

    expect(reconciled.step, FirstRunStep.outcomePreview);
    expect(reconciled.sourceId, source.id);
    expect(reconciled.sessionId, session.id);
  });

  test('resume keeps material-only import at coverage review', () async {
    final source = _source(startedAt);
    final chunk = _chunk(source.id, startedAt);
    final bootstrap = _bootstrap(sources: [source], chunks: [chunk]);
    final imported = FirstRunProgress(
      step: FirstRunStep.projectImport,
      selectedGoal: LearningAgentGoal.aiInterviewPrep,
      sourceId: source.id,
      startedAt: startedAt,
      updatedAt: startedAt,
    );

    final reconciled = await bootstrap.reconcile(imported, now: startedAt);

    expect(reconciled.step, FirstRunStep.coverageReview);
    expect(reconciled.sessionId, isNull);
  });

  test('deleted imported source returns to project import without data writes',
      () async {
    final progress = FirstRunProgress(
      step: FirstRunStep.firstSession,
      selectedGoal: LearningAgentGoal.aiInterviewPrep,
      sourceId: 'missing-source',
      sessionId: 'stale-session',
      startedAt: startedAt,
      updatedAt: startedAt,
    );

    final reconciled = await _bootstrap().reconcile(progress, now: startedAt);

    expect(reconciled.step, FirstRunStep.projectImport);
    expect(reconciled.sourceId, isNull);
    expect(reconciled.sessionId, isNull);
  });
}

FirstRunBootstrapService _bootstrap({
  List<Source> sources = const [],
  List<SourceChunk> chunks = const [],
  List<KnowledgePointSource> relations = const [],
  List<Deck> decks = const [],
  List<Question> questions = const [],
  List<LearningSession> sessions = const [],
  Future<void> Function()? demoDataSeeder,
}) {
  return FirstRunBootstrapService(
    sourceRepository: _FakeSourceRepository(sources),
    sourceChunkRepository: _FakeSourceChunkRepository(chunks),
    knowledgePointRepository: _FakeKnowledgePointRepository(relations),
    deckRepository: _FakeDeckRepository(decks),
    questionRepository: _FakeQuestionRepository(questions),
    learningSessionRepository: _FakeLearningSessionRepository(sessions),
    demoDataSeeder: demoDataSeeder ?? () async {},
  );
}

Source _source(DateTime now) {
  return Source(
    id: 'source-1',
    title: 'Project',
    type: SourceType.project,
    trustLevel: SourceTrustLevel.sourceCode,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(String sourceId, DateTime now) {
  return SourceChunk(
    id: 'chunk-1',
    sourceId: sourceId,
    chunkIndex: 0,
    content: 'class App {}',
    contentHash: 'hash-1',
    createdAt: now,
  );
}

class _MemoryFirstRunProgressStore implements FirstRunProgressStore {
  FirstRunProgress? value;
  int writeCount = 0;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<FirstRunProgress?> read() async => value;

  @override
  Future<void> write(FirstRunProgress progress) async {
    value = progress;
    writeCount++;
  }
}

class _FakeSourceRepository extends SourceRepository {
  final List<Source> values;

  _FakeSourceRepository(this.values) : super(DatabaseHelper());

  @override
  Future<List<Source>> getAllSources() async => values;

  @override
  Future<Source?> getSource(String id) async {
    for (final source in values) {
      if (source.id == id) return source;
    }
    return null;
  }
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final List<SourceChunk> values;

  _FakeSourceChunkRepository(this.values) : super(DatabaseHelper());

  @override
  Future<List<SourceChunk>> getSourceChunks(String sourceId) async {
    return values.where((chunk) => chunk.sourceId == sourceId).toList();
  }
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  final List<KnowledgePointSource> relations;

  _FakeKnowledgePointRepository(this.relations) : super(DatabaseHelper());

  @override
  Future<List<KnowledgePointSource>> getAllKnowledgePointSources() async {
    return relations;
  }
}

class _FakeDeckRepository extends DeckRepository {
  final List<Deck> values;

  _FakeDeckRepository(this.values) : super(DatabaseHelper());

  @override
  Future<List<Deck>> getAllDecks() async => values;
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> values;

  _FakeQuestionRepository(this.values) : super(DatabaseHelper());

  @override
  Future<List<Question>> getAllQuestions() async => values;
}

class _FakeLearningSessionRepository extends LearningSessionRepository {
  final List<LearningSession> values;

  _FakeLearningSessionRepository(this.values) : super(DatabaseHelper());

  @override
  Future<List<LearningSession>> getLearningSessions() async => values;
}
