import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/deck.dart';
import '../models/interview_turn.dart';
import '../models/knowledge_point.dart';
import '../models/knowledge_point_prerequisite.dart';
import '../models/knowledge_point_source.dart';
import '../models/learning_session.dart';
import '../models/programming_exercise.dart';
import '../models/programming_exercise_attempt.dart';
import '../models/programming_review_action.dart';
import '../models/product_event.dart';
import '../models/question.dart';
import '../models/source.dart';
import '../models/source_chunk.dart';
import '../models/study_record.dart';
import '../models/tutor_turn.dart';
import '../models/user_stats.dart';

class LearningAgentCheckpointRevisionConflict implements Exception {
  final String sessionId;
  final int expectedRevision;
  final int actualRevision;

  const LearningAgentCheckpointRevisionConflict({
    required this.sessionId,
    required this.expectedRevision,
    required this.actualRevision,
  });
}

/// SQLite 数据库帮助类
class DatabaseHelper {
  static const String databaseName = 'anchor_learning.db';
  static const int schemaVersion = 23;

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal()
      : _databaseFactory = null,
        _databasePath = null;

  DatabaseHelper.forTesting({
    required DatabaseFactory databaseFactory,
    String databasePath = inMemoryDatabasePath,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;

  Database? _database;

  DatabaseFactory get effectiveDatabaseFactory =>
      _databaseFactory ?? databaseFactory;

  Future<String> get resolvedDatabasePath async =>
      _databasePath ??
      join(await effectiveDatabaseFactory.getDatabasesPath(), databaseName);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final factory = effectiveDatabaseFactory;
    final path = await resolvedDatabasePath;
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSourceTables(db);
    await _createSourceChunkTables(db);
    await _createKnowledgePointTables(db);
    await _createLearningSessionTables(db);
    await _createLearningAgentRuntimeTables(db);
    await _createProgrammingExerciseTables(db);
    await _createProgrammingReviewActionTables(db);
    await _createProductEventTables(db);

    // 题包表
    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_text TEXT,
        source_image TEXT,
        question_count INTEGER DEFAULT 0,
        mastery_level INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 题目表
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        knowledge_point_id TEXT,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        options TEXT,
        answer TEXT NOT NULL,
        explanation TEXT,
        difficulty INTEGER DEFAULT 1,
        source_status TEXT NOT NULL DEFAULT 'no_source',
        citation_ids TEXT,
        last_reviewed_at INTEGER,
        next_review_at INTEGER,
        ease REAL DEFAULT 1.0,
        lapse_count INTEGER DEFAULT 0,
        match_left TEXT,
        match_right TEXT,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE,
        FOREIGN KEY (knowledge_point_id)
          REFERENCES knowledge_points(id) ON DELETE SET NULL
      )
    ''');

    // 学习记录表
    await db.execute('''
      CREATE TABLE study_records (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        correct_count INTEGER DEFAULT 0,
        total_count INTEGER DEFAULT 0,
        last_studied_at INTEGER NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    // 用户统计表(单行)
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY DEFAULT 1,
        xp INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        hearts INTEGER DEFAULT 5,
        max_hearts INTEGER DEFAULT 5,
        last_study_date INTEGER NOT NULL,
        daily_goal INTEGER DEFAULT 50,
        today_xp INTEGER DEFAULT 0
      )
    ''');

    // 初始化用户统计
    await db.insert('user_stats', {
      'id': 1,
      'xp': 0,
      'streak': 0,
      'hearts': 5,
      'max_hearts': 5,
      'last_study_date': DateTime.now().millisecondsSinceEpoch,
      'daily_goal': 50,
      'today_xp': 0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSourceTables(db);
    }
    if (oldVersion < 3) {
      await _createSourceChunkTables(db);
    }
    if (oldVersion < 4) {
      await _createKnowledgePointTables(db);
    }
    if (oldVersion < 5) {
      await _upgradeQuestionsToV5(db);
    }
    if (oldVersion < 6) {
      await _createLearningSessionTables(db);
    }
    if (oldVersion < 7) {
      await _createLearningAgentRuntimeTables(db);
    } else {
      if (oldVersion < 8) {
        await _upgradeLearningAgentTraceEventsToV8(db);
      }
      if (oldVersion < 9) {
        await _upgradeLearningAgentStatesToV9(db);
      }
      if (oldVersion < 10) {
        await _upgradeLearningAgentStatesToV10(db);
      }
      if (oldVersion < 11) {
        await _upgradeLearningAgentStatesToV11(db);
      }
      if (oldVersion < 12) {
        await _upgradeLearningAgentStatesToV12(db);
      }
    }
    if (oldVersion < 13) {
      await _upgradeSourceProvenanceToV13(db);
    }
    if (oldVersion < 14) {
      await _upgradeKnowledgePointKindToV14(db);
    }
    if (oldVersion < 15) {
      await _upgradeInterviewTurnProvenanceToV15(db);
    }
    if (oldVersion < 16) {
      await _upgradeInterviewReviewActionsToV16(db);
    }
    if (oldVersion < 17) {
      await _upgradeProgrammingSourceProvenanceToV17(db);
    }
    if (oldVersion < 18) {
      await _createKnowledgePointPrerequisiteTables(db);
    }
    if (oldVersion < 19) {
      await _createTutorTurnTables(db);
    }
    if (oldVersion < 20) {
      await _createProgrammingExerciseTables(db);
    }
    if (oldVersion < 21) {
      await _createProgrammingReviewActionTables(db);
    }
    if (oldVersion < 22) {
      await _upgradeGroundedClaimsToV22(db);
    }
    if (oldVersion < 23) {
      await _createProductEventTables(db);
    }
    // Add future migrations in ascending order.
  }

  Future<void> _createProductEventTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_events (
        id TEXT PRIMARY KEY,
        event_name TEXT NOT NULL,
        schema_version INTEGER NOT NULL,
        occurred_at INTEGER NOT NULL,
        anonymous_install_id TEXT NOT NULL,
        app_version TEXT NOT NULL,
        platform TEXT NOT NULL,
        flow_id TEXT NOT NULL,
        goal TEXT NOT NULL,
        target_id TEXT,
        session_id TEXT,
        properties_json TEXT NOT NULL,
        dedupe_key TEXT UNIQUE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_product_events_occurred_at
      ON product_events(occurred_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_product_events_name_time
      ON product_events(event_name, occurred_at DESC)
    ''');
  }

  Future<void> _createSourceTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sources (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        uri TEXT,
        revision TEXT,
        publisher TEXT,
        license_expression TEXT,
        retrieved_at INTEGER,
        content_hash TEXT NOT NULL DEFAULT '',
        trust_level TEXT NOT NULL DEFAULT 'unknown',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createSourceChunkTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS source_chunks (
        id TEXT PRIMARY KEY,
        source_id TEXT NOT NULL,
        chunk_index INTEGER NOT NULL,
        content TEXT NOT NULL,
        locator TEXT,
        relative_path TEXT,
        start_line INTEGER,
        end_line INTEGER,
        content_hash TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createKnowledgePointTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_points (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'concept',
        tags TEXT,
        difficulty INTEGER DEFAULT 1,
        interview_relevance INTEGER DEFAULT 0,
        mastery_level INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_point_sources (
        knowledge_point_id TEXT NOT NULL,
        source_chunk_id TEXT NOT NULL,
        relation TEXT NOT NULL DEFAULT 'explains',
        PRIMARY KEY (knowledge_point_id, source_chunk_id, relation),
        FOREIGN KEY (knowledge_point_id)
          REFERENCES knowledge_points(id) ON DELETE CASCADE,
        FOREIGN KEY (source_chunk_id)
          REFERENCES source_chunks(id) ON DELETE CASCADE
      )
    ''');

    await _createKnowledgePointPrerequisiteTables(db);
  }

  Future<void> _createKnowledgePointPrerequisiteTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_point_prerequisites (
        knowledge_point_id TEXT NOT NULL,
        prerequisite_knowledge_point_id TEXT NOT NULL,
        rationale TEXT NOT NULL DEFAULT '',
        citation_ids TEXT,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (knowledge_point_id, prerequisite_knowledge_point_id),
        CHECK (knowledge_point_id != prerequisite_knowledge_point_id),
        FOREIGN KEY (knowledge_point_id)
          REFERENCES knowledge_points(id) ON DELETE CASCADE,
        FOREIGN KEY (prerequisite_knowledge_point_id)
          REFERENCES knowledge_points(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeQuestionsToV5(Database db) async {
    await db
        .execute('ALTER TABLE questions ADD COLUMN knowledge_point_id TEXT');
    await db.execute(
        'ALTER TABLE questions ADD COLUMN difficulty INTEGER DEFAULT 1');
    await db.execute(
      "ALTER TABLE questions ADD COLUMN source_status TEXT NOT NULL DEFAULT 'no_source'",
    );
    await db.execute('ALTER TABLE questions ADD COLUMN citation_ids TEXT');
    await db
        .execute('ALTER TABLE questions ADD COLUMN last_reviewed_at INTEGER');
    await db.execute('ALTER TABLE questions ADD COLUMN next_review_at INTEGER');
    await db.execute('ALTER TABLE questions ADD COLUMN ease REAL DEFAULT 1.0');
    await db.execute(
        'ALTER TABLE questions ADD COLUMN lapse_count INTEGER DEFAULT 0');
  }

  Future<void> _upgradeSourceProvenanceToV13(Database db) async {
    await _addColumnIfMissing(db, 'sources', 'revision', 'TEXT');
    await _addColumnIfMissing(
      db,
      'source_chunks',
      'relative_path',
      'TEXT',
    );
    await _addColumnIfMissing(db, 'source_chunks', 'start_line', 'INTEGER');
    await _addColumnIfMissing(db, 'source_chunks', 'end_line', 'INTEGER');
  }

  Future<void> _upgradeProgrammingSourceProvenanceToV17(Database db) async {
    await _addColumnIfMissing(db, 'sources', 'publisher', 'TEXT');
    await _addColumnIfMissing(db, 'sources', 'license_expression', 'TEXT');
    await _addColumnIfMissing(db, 'sources', 'retrieved_at', 'INTEGER');
    await _addColumnIfMissing(
      db,
      'sources',
      'content_hash',
      "TEXT NOT NULL DEFAULT ''",
    );
  }

  Future<void> _upgradeKnowledgePointKindToV14(Database db) async {
    await _addColumnIfMissing(
      db,
      'knowledge_points',
      'kind',
      "TEXT NOT NULL DEFAULT 'concept'",
    );
  }

  Future<void> _upgradeInterviewTurnProvenanceToV15(Database db) async {
    await _addColumnIfMissing(
      db,
      'interview_turns',
      'knowledge_point_id',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'interview_turns',
      'knowledge_point_kind',
      "TEXT NOT NULL DEFAULT 'concept'",
    );
  }

  Future<void> _upgradeInterviewReviewActionsToV16(Database db) async {
    await _addColumnIfMissing(
      db,
      'interview_turns',
      'weak_dimensions',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'interview_turns',
      'review_question_ids',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'interview_turns',
      'review_due_at',
      'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      'interview_turns',
      'next_interview_question',
      "TEXT NOT NULL DEFAULT ''",
    );
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((entry) => entry['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _upgradeGroundedClaimsToV22(Database db) async {
    for (final table in [
      'interview_turns',
      'tutor_turns',
      'programming_exercise_attempts',
    ]) {
      await _addColumnIfMissing(
        db,
        table,
        'grounded_claims_json',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _addColumnIfMissing(
        db,
        table,
        'grounding_disposition',
        "TEXT NOT NULL DEFAULT 'legacy'",
      );
    }
  }

  Future<void> _createLearningSessionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS learning_sessions (
        id TEXT PRIMARY KEY,
        mode TEXT NOT NULL,
        target_id TEXT,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        xp_gained INTEGER DEFAULT 0,
        summary TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS interview_turns (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        question_text TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        ai_feedback TEXT NOT NULL,
        reference_answer TEXT NOT NULL,
        knowledge_point_id TEXT,
        knowledge_point_kind TEXT NOT NULL DEFAULT 'concept',
        citation_ids TEXT,
        accuracy_score INTEGER DEFAULT 0,
        project_detail_score INTEGER DEFAULT 0,
        engineering_score INTEGER DEFAULT 0,
        clarity_score INTEGER DEFAULT 0,
        weak_knowledge_point_ids TEXT,
        weak_dimensions TEXT,
        review_question_ids TEXT,
        review_due_at INTEGER,
        next_interview_question TEXT NOT NULL DEFAULT '',
        grounded_claims_json TEXT NOT NULL DEFAULT '[]',
        grounding_disposition TEXT NOT NULL DEFAULT 'legacy',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES learning_sessions(id)
          ON DELETE CASCADE
      )
    ''');

    await _createTutorTurnTables(db);
  }

  Future<void> _createTutorTurnTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tutor_turns (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        knowledge_point_id TEXT NOT NULL,
        question_text TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        ai_feedback TEXT NOT NULL,
        reference_answer TEXT NOT NULL DEFAULT '',
        misconception TEXT NOT NULL DEFAULT '',
        next_question TEXT NOT NULL DEFAULT '',
        citation_ids TEXT,
        prerequisite_knowledge_point_ids TEXT,
        evidence_sufficient INTEGER NOT NULL DEFAULT 1,
        accuracy_score INTEGER NOT NULL DEFAULT 0,
        grounded_claims_json TEXT NOT NULL DEFAULT '[]',
        grounding_disposition TEXT NOT NULL DEFAULT 'legacy',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES learning_sessions(id)
          ON DELETE CASCADE,
        FOREIGN KEY (knowledge_point_id) REFERENCES knowledge_points(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tutor_turns_session_created
      ON tutor_turns(session_id, created_at)
    ''');
  }

  Future<void> _createProgrammingExerciseTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS programming_exercises (
        id TEXT PRIMARY KEY,
        knowledge_point_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        prompt TEXT NOT NULL,
        reference_answer TEXT NOT NULL,
        rubric_concept_accuracy TEXT NOT NULL,
        rubric_reasoning_process TEXT NOT NULL,
        rubric_evidence_use TEXT NOT NULL,
        rubric_clarity TEXT NOT NULL,
        source_status TEXT NOT NULL DEFAULT 'pending',
        citation_ids TEXT,
        is_retest INTEGER NOT NULL DEFAULT 0,
        parent_attempt_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (knowledge_point_id) REFERENCES knowledge_points(id)
          ON DELETE CASCADE,
        FOREIGN KEY (parent_attempt_id)
          REFERENCES programming_exercise_attempts(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS programming_exercise_attempts (
        id TEXT PRIMARY KEY,
        exercise_id TEXT NOT NULL,
        knowledge_point_id TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        feedback TEXT NOT NULL,
        concept_accuracy_score INTEGER NOT NULL DEFAULT 0,
        reasoning_process_score INTEGER NOT NULL DEFAULT 0,
        evidence_use_score INTEGER NOT NULL DEFAULT 0,
        clarity_score INTEGER NOT NULL DEFAULT 0,
        misconception_code TEXT NOT NULL DEFAULT '',
        misconception_label TEXT NOT NULL DEFAULT '',
        repair_explanation TEXT NOT NULL DEFAULT '',
        citation_ids TEXT,
        evidence_sufficient INTEGER NOT NULL DEFAULT 1,
        formal_mastery_applied INTEGER NOT NULL DEFAULT 0,
        retest_exercise_id TEXT,
        grounded_claims_json TEXT NOT NULL DEFAULT '[]',
        grounding_disposition TEXT NOT NULL DEFAULT 'legacy',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES programming_exercises(id)
          ON DELETE CASCADE,
        FOREIGN KEY (knowledge_point_id) REFERENCES knowledge_points(id)
          ON DELETE CASCADE,
        FOREIGN KEY (retest_exercise_id) REFERENCES programming_exercises(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_programming_exercises_point_created
      ON programming_exercises(knowledge_point_id, created_at)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_programming_attempts_exercise_created
      ON programming_exercise_attempts(exercise_id, created_at)
    ''');
  }

  Future<void> _createProgrammingReviewActionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS programming_review_actions (
        id TEXT PRIMARY KEY,
        knowledge_point_id TEXT NOT NULL,
        trigger_type TEXT NOT NULL,
        trigger_id TEXT NOT NULL,
        weak_dimensions TEXT NOT NULL,
        prerequisite_knowledge_point_ids TEXT,
        citation_ids TEXT,
        review_question_ids TEXT,
        review_exercise_ids TEXT,
        due_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        UNIQUE (trigger_type, trigger_id),
        FOREIGN KEY (knowledge_point_id) REFERENCES knowledge_points(id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_programming_review_actions_open_due
      ON programming_review_actions(completed_at, due_at)
    ''');
  }

  Future<void> _createLearningAgentRuntimeTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS learning_agent_states (
        session_id TEXT PRIMARY KEY,
        goal TEXT NOT NULL,
        phase TEXT NOT NULL,
        target_id TEXT,
        focus_point_id TEXT,
        available_tool_ids TEXT,
        selected_tool_id TEXT,
        active_tool_operation_id TEXT,
        active_tool_input_snapshot TEXT,
        evidence_chunk_ids TEXT,
        pending_user_decision TEXT,
        policy_warnings TEXT,
        trace_event_ids TEXT,
        plan_snapshot TEXT,
        checkpoint_revision INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learning_agent_trace_events (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        goal TEXT NOT NULL,
        type TEXT NOT NULL,
        level TEXT NOT NULL,
        occurred_at INTEGER NOT NULL,
        phase TEXT,
        target_id TEXT,
        target_label TEXT,
        tool_id TEXT,
        summary TEXT NOT NULL,
        detail TEXT,
        evidence_chunk_ids TEXT,
        policy_issue_codes TEXT,
        sequence_index INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES learning_agent_states(session_id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learning_agent_trace_session_sequence
      ON learning_agent_trace_events(session_id, sequence_index)
    ''');
  }

  Future<void> _upgradeLearningAgentTraceEventsToV8(Database db) async {
    await db.execute(
      'ALTER TABLE learning_agent_trace_events '
      'ADD COLUMN sequence_index INTEGER NOT NULL DEFAULT 0',
    );

    final events = await db.query(
      'learning_agent_trace_events',
      columns: ['id', 'session_id'],
      orderBy: 'session_id ASC, occurred_at ASC, id ASC',
    );
    String? currentSessionId;
    var sequenceIndex = 0;
    for (final event in events) {
      final sessionId = event['session_id'] as String;
      if (sessionId != currentSessionId) {
        currentSessionId = sessionId;
        sequenceIndex = 0;
      }
      await db.update(
        'learning_agent_trace_events',
        {'sequence_index': sequenceIndex},
        where: 'id = ?',
        whereArgs: [event['id']],
      );
      sequenceIndex++;
    }

    await db.execute(
      'DROP INDEX IF EXISTS idx_learning_agent_trace_session_time',
    );
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learning_agent_trace_session_sequence
      ON learning_agent_trace_events(session_id, sequence_index)
    ''');
  }

  Future<void> _upgradeLearningAgentStatesToV9(Database db) async {
    await db.execute(
      'ALTER TABLE learning_agent_states ADD COLUMN plan_snapshot TEXT',
    );
  }

  Future<void> _upgradeLearningAgentStatesToV10(Database db) async {
    await db.execute(
      'ALTER TABLE learning_agent_states '
      'ADD COLUMN checkpoint_revision INTEGER NOT NULL DEFAULT 1',
    );
  }

  Future<void> _upgradeLearningAgentStatesToV11(Database db) async {
    await db.execute(
      'ALTER TABLE learning_agent_states '
      'ADD COLUMN active_tool_operation_id TEXT',
    );
  }

  Future<void> _upgradeLearningAgentStatesToV12(Database db) async {
    await db.execute(
      'ALTER TABLE learning_agent_states '
      'ADD COLUMN active_tool_input_snapshot TEXT',
    );
  }

  // ============ Source 操作 ============

  Future<String> insertSource(Source source) async {
    final db = await database;
    await db.insert('sources', source.toMap());
    return source.id;
  }

  Future<List<Source>> getAllSources() async {
    final db = await database;
    final maps = await db.query('sources', orderBy: 'created_at DESC');
    return maps.map(Source.fromMap).toList();
  }

  Future<Source?> getSource(String id) async {
    final db = await database;
    final maps = await db.query('sources', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Source.fromMap(maps.first);
  }

  Future<void> updateSource(Source source) async {
    final db = await database;
    await db.update(
      'sources',
      source.toMap(),
      where: 'id = ?',
      whereArgs: [source.id],
    );
  }

  Future<void> deleteSource(String id) async {
    final db = await database;
    await db.delete(
      'knowledge_point_sources',
      where: 'source_chunk_id IN '
          '(SELECT id FROM source_chunks WHERE source_id = ?)',
      whereArgs: [id],
    );
    await db.delete('source_chunks', where: 'source_id = ?', whereArgs: [id]);
    await db.delete('sources', where: 'id = ?', whereArgs: [id]);
  }

  // ============ SourceChunk 操作 ============

  Future<String> insertSourceChunk(SourceChunk chunk) async {
    final db = await database;
    await db.insert('source_chunks', chunk.toMap());
    return chunk.id;
  }

  Future<List<SourceChunk>> getSourceChunks(String sourceId) async {
    final db = await database;
    final maps = await db.query(
      'source_chunks',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'chunk_index ASC',
    );
    return maps.map(SourceChunk.fromMap).toList();
  }

  Future<SourceChunk?> getSourceChunk(String id) async {
    final db = await database;
    final maps = await db.query(
      'source_chunks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SourceChunk.fromMap(maps.first);
  }

  Future<void> updateSourceChunk(SourceChunk chunk) async {
    final db = await database;
    await db.update(
      'source_chunks',
      chunk.toMap(),
      where: 'id = ?',
      whereArgs: [chunk.id],
    );
  }

  Future<void> deleteSourceChunk(String id) async {
    final db = await database;
    await db.delete(
      'knowledge_point_sources',
      where: 'source_chunk_id = ?',
      whereArgs: [id],
    );
    await db.delete('source_chunks', where: 'id = ?', whereArgs: [id]);
  }

  // ============ KnowledgePoint 操作 ============

  Future<String> insertKnowledgePoint(KnowledgePoint point) async {
    final db = await database;
    await db.insert('knowledge_points', point.toMap());
    return point.id;
  }

  Future<List<KnowledgePoint>> getAllKnowledgePoints() async {
    final db = await database;
    final maps = await db.query('knowledge_points', orderBy: 'created_at DESC');
    return maps.map(KnowledgePoint.fromMap).toList();
  }

  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    final db = await database;
    final maps = await db.query(
      'knowledge_points',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return KnowledgePoint.fromMap(maps.first);
  }

  Future<void> updateKnowledgePoint(KnowledgePoint point) async {
    final db = await database;
    await db.update(
      'knowledge_points',
      point.toMap(),
      where: 'id = ?',
      whereArgs: [point.id],
    );
  }

  Future<void> deleteKnowledgePoint(String id) async {
    final db = await database;
    await db.delete(
      'knowledge_point_sources',
      where: 'knowledge_point_id = ?',
      whereArgs: [id],
    );
    await db.delete('knowledge_points', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addKnowledgePointSource(KnowledgePointSource source) async {
    final db = await database;
    await db.insert(
      'knowledge_point_sources',
      source.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<KnowledgePointSource>> getKnowledgePointSources(
    String knowledgePointId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'knowledge_point_sources',
      where: 'knowledge_point_id = ?',
      whereArgs: [knowledgePointId],
    );
    return maps.map(KnowledgePointSource.fromMap).toList();
  }

  Future<List<KnowledgePointSource>> getAllKnowledgePointSources() async {
    final db = await database;
    final maps = await db.query(
      'knowledge_point_sources',
      orderBy: 'knowledge_point_id ASC, source_chunk_id ASC',
    );
    return maps.map(KnowledgePointSource.fromMap).toList();
  }

  Future<List<KnowledgePointPrerequisite>>
      getKnowledgePointPrerequisites() async {
    final db = await database;
    final maps = await db.query(
      'knowledge_point_prerequisites',
      orderBy: 'created_at ASC, prerequisite_knowledge_point_id ASC, '
          'knowledge_point_id ASC',
    );
    return maps.map(KnowledgePointPrerequisite.fromMap).toList();
  }

  Future<void> replaceKnowledgePointPrerequisites({
    required List<String> scopeKnowledgePointIds,
    required List<KnowledgePointPrerequisite> relations,
  }) async {
    final scopeIds = scopeKnowledgePointIds.toSet().toList()..sort();
    if (scopeIds.isEmpty) return;
    final placeholders = List.filled(scopeIds.length, '?').join(', ');
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'knowledge_point_prerequisites',
        where: 'knowledge_point_id IN ($placeholders) AND '
            'prerequisite_knowledge_point_id IN ($placeholders)',
        whereArgs: [...scopeIds, ...scopeIds],
      );
      for (final relation in relations) {
        if (!scopeIds.contains(relation.knowledgePointId) ||
            !scopeIds.contains(relation.prerequisiteKnowledgePointId)) {
          continue;
        }
        await transaction.insert(
          'knowledge_point_prerequisites',
          relation.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ============ LearningSession 操作 ============

  Future<String> insertLearningSession(LearningSession session) async {
    final db = await database;
    await db.insert('learning_sessions', session.toMap());
    return session.id;
  }

  Future<void> updateLearningSession(LearningSession session) async {
    final db = await database;
    await db.update(
      'learning_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<LearningSession>> getLearningSessions() async {
    final db = await database;
    final maps = await db.query(
      'learning_sessions',
      orderBy: 'started_at DESC',
    );
    return maps.map(LearningSession.fromMap).toList();
  }

  Future<LearningSession?> getLearningSession(String id) async {
    final db = await database;
    final maps = await db.query(
      'learning_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return LearningSession.fromMap(maps.first);
  }

  Future<String> insertInterviewTurn(InterviewTurn turn) async {
    final db = await database;
    await db.insert('interview_turns', turn.toMap());
    return turn.id;
  }

  Future<void> insertInterviewTurnWithQuestionUpdates({
    required InterviewTurn turn,
    required List<Question> questions,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      for (final question in questions) {
        await transaction.update(
          'questions',
          question.toMap(),
          where: 'id = ?',
          whereArgs: [question.id],
        );
      }
      await transaction.insert('interview_turns', turn.toMap());
    });
  }

  Future<List<InterviewTurn>> getInterviewTurns(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'interview_turns',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return maps.map(InterviewTurn.fromMap).toList();
  }

  Future<List<InterviewTurn>> getAllInterviewTurns() async {
    final db = await database;
    final maps = await db.query(
      'interview_turns',
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(InterviewTurn.fromMap).toList();
  }

  Future<String> insertTutorTurn(TutorTurn turn) async {
    final db = await database;
    await db.insert('tutor_turns', turn.toMap());
    return turn.id;
  }

  Future<List<TutorTurn>> getTutorTurns(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'tutor_turns',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return maps.map(TutorTurn.fromMap).toList();
  }

  Future<List<TutorTurn>> getAllTutorTurns() async {
    final db = await database;
    final maps = await db.query(
      'tutor_turns',
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(TutorTurn.fromMap).toList();
  }

  // ============ Programming exercise operations ============

  Future<String> insertProgrammingExercise(
    ProgrammingExercise exercise,
  ) async {
    final db = await database;
    await db.insert('programming_exercises', exercise.toMap());
    return exercise.id;
  }

  Future<void> updateProgrammingExercise(
    ProgrammingExercise exercise,
  ) async {
    final db = await database;
    await db.update(
      'programming_exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<ProgrammingExercise?> getProgrammingExercise(String id) async {
    final db = await database;
    final maps = await db.query(
      'programming_exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : ProgrammingExercise.fromMap(maps.first);
  }

  Future<List<ProgrammingExercise>> getProgrammingExercisesForKnowledgePoint(
    String knowledgePointId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'programming_exercises',
      where: 'knowledge_point_id = ?',
      whereArgs: [knowledgePointId],
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(ProgrammingExercise.fromMap).toList();
  }

  Future<List<ProgrammingExercise>> getAllProgrammingExercises() async {
    final db = await database;
    final maps = await db.query(
      'programming_exercises',
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(ProgrammingExercise.fromMap).toList();
  }

  Future<String> insertProgrammingExerciseAttempt(
    ProgrammingExerciseAttempt attempt,
  ) async {
    final db = await database;
    await db.insert('programming_exercise_attempts', attempt.toMap());
    return attempt.id;
  }

  Future<void> updateProgrammingExerciseAttempt(
    ProgrammingExerciseAttempt attempt,
  ) async {
    final db = await database;
    await db.update(
      'programming_exercise_attempts',
      attempt.toMap(),
      where: 'id = ?',
      whereArgs: [attempt.id],
    );
  }

  Future<ProgrammingExerciseAttempt?> getProgrammingExerciseAttempt(
    String id,
  ) async {
    final db = await database;
    final maps = await db.query(
      'programming_exercise_attempts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : ProgrammingExerciseAttempt.fromMap(maps.first);
  }

  Future<List<ProgrammingExerciseAttempt>> getProgrammingExerciseAttempts(
    String exerciseId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'programming_exercise_attempts',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(ProgrammingExerciseAttempt.fromMap).toList();
  }

  Future<List<ProgrammingExerciseAttempt>>
      getAllProgrammingExerciseAttempts() async {
    final db = await database;
    final maps = await db.query(
      'programming_exercise_attempts',
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(ProgrammingExerciseAttempt.fromMap).toList();
  }

  // ============ Programming review action operations ============

  Future<void> upsertProgrammingReviewAction(
    ProgrammingReviewAction action,
  ) async {
    final db = await database;
    await db.insert(
      'programming_review_actions',
      action.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProgrammingReviewAction(
    ProgrammingReviewAction action,
  ) async {
    final db = await database;
    await db.update(
      'programming_review_actions',
      action.toMap(),
      where: 'id = ?',
      whereArgs: [action.id],
    );
  }

  Future<ProgrammingReviewAction?> getProgrammingReviewAction(
    String id,
  ) async {
    final db = await database;
    final maps = await db.query(
      'programming_review_actions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : ProgrammingReviewAction.fromMap(maps.first);
  }

  Future<List<ProgrammingReviewAction>>
      getOpenProgrammingReviewActions() async {
    final db = await database;
    final maps = await db.query(
      'programming_review_actions',
      where: 'completed_at IS NULL',
      orderBy: 'due_at ASC, created_at ASC, id ASC',
    );
    return maps.map(ProgrammingReviewAction.fromMap).toList();
  }

  Future<List<ProgrammingReviewAction>> getAllProgrammingReviewActions() async {
    final db = await database;
    final maps = await db.query(
      'programming_review_actions',
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(ProgrammingReviewAction.fromMap).toList();
  }

  Future<void> insertTutorTurnWithProgrammingReviewAction({
    required TutorTurn turn,
    ProgrammingReviewAction? action,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.insert('tutor_turns', turn.toMap());
      if (action != null) {
        await transaction.insert(
          'programming_review_actions',
          action.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ============ LearningAgent checkpoint operations ============

  Future<int> saveLearningAgentCheckpoint({
    required Map<String, Object?> state,
    required List<Map<String, Object?>> traceEvents,
    required int expectedRevision,
  }) async {
    final sessionId = state['session_id'];
    if (sessionId is! String || sessionId.trim().isEmpty) {
      throw ArgumentError.value(
        sessionId,
        'state.session_id',
        'A checkpoint requires a non-empty session id.',
      );
    }
    if (expectedRevision < 0) {
      throw ArgumentError.value(
        expectedRevision,
        'expectedRevision',
        'A checkpoint revision cannot be negative.',
      );
    }

    final db = await database;
    return db.transaction<int>((transaction) async {
      final currentRows = await transaction.query(
        'learning_agent_states',
        columns: ['checkpoint_revision'],
        where: 'session_id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      final actualRevision = currentRows.isEmpty
          ? 0
          : (currentRows.first['checkpoint_revision'] as int? ?? 1);
      if (actualRevision != expectedRevision) {
        throw LearningAgentCheckpointRevisionConflict(
          sessionId: sessionId,
          expectedRevision: expectedRevision,
          actualRevision: actualRevision,
        );
      }

      final nextRevision = actualRevision + 1;
      final nextState = Map<String, Object?>.from(state);
      nextState['checkpoint_revision'] = nextRevision;
      if (actualRevision == 0) {
        await transaction.insert(
          'learning_agent_states',
          nextState,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      } else {
        final updated = await transaction.update(
          'learning_agent_states',
          nextState,
          where: 'session_id = ? AND checkpoint_revision = ?',
          whereArgs: [sessionId, expectedRevision],
        );
        if (updated != 1) {
          throw LearningAgentCheckpointRevisionConflict(
            sessionId: sessionId,
            expectedRevision: expectedRevision,
            actualRevision: actualRevision,
          );
        }
      }
      await transaction.delete(
        'learning_agent_trace_events',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      final batch = transaction.batch();
      for (var index = 0; index < traceEvents.length; index++) {
        final event = Map<String, Object?>.from(traceEvents[index]);
        event['sequence_index'] = index;
        batch.insert(
          'learning_agent_trace_events',
          event,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      await batch.commit(noResult: true);
      return nextRevision;
    });
  }

  Future<Map<String, Object?>?> getLearningAgentStateMap(
    String sessionId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'learning_agent_states',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return maps.isEmpty ? null : maps.first;
  }

  Future<List<Map<String, Object?>>> getActiveLearningAgentStateMaps({
    int limit = 20,
  }) async {
    final db = await database;
    return db.query(
      'learning_agent_states',
      where: 'phase NOT IN (?, ?, ?)',
      whereArgs: ['complete', 'canceled', 'blocked'],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, Object?>>> getLearningAgentTraceEventMaps(
    String sessionId,
  ) async {
    final db = await database;
    return db.query(
      'learning_agent_trace_events',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sequence_index ASC',
    );
  }

  Future<void> deleteLearningAgentCheckpoint(String sessionId) async {
    final db = await database;
    await db.delete(
      'learning_agent_states',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // ============ Deck 操作 ============

  Future<String> insertDeck(Deck deck) async {
    final db = await database;
    await db.insert('decks', deck.toMap());
    return deck.id;
  }

  Future<List<Deck>> getAllDecks() async {
    final db = await database;
    final maps = await db.query('decks', orderBy: 'created_at DESC');
    return maps.map(Deck.fromMap).toList();
  }

  Future<Deck?> getDeck(String id) async {
    final db = await database;
    final maps = await db.query('decks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Deck.fromMap(maps.first);
  }

  Future<void> updateDeck(Deck deck) async {
    final db = await database;
    await db
        .update('decks', deck.toMap(), where: 'id = ?', whereArgs: [deck.id]);
  }

  Future<void> deleteDeck(String id) async {
    final db = await database;
    await db.delete('questions', where: 'deck_id = ?', whereArgs: [id]);
    await db.delete('study_records', where: 'deck_id = ?', whereArgs: [id]);
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Product event operations ============

  Future<bool> insertProductEvent(ProductEvent event) async {
    final db = await database;
    final inserted = await db.insert(
      'product_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return inserted != 0;
  }

  Future<List<ProductEvent>> getProductEvents({int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'product_events',
      orderBy: 'occurred_at DESC, id DESC',
      limit: limit,
    );
    return maps.map(ProductEvent.fromMap).toList(growable: false);
  }

  Future<int> countProductEvents() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS event_count FROM product_events',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteAllProductEvents() async {
    final db = await database;
    return db.delete('product_events');
  }

  // ============ Question 操作 ============

  Future<String> insertQuestion(Question question) async {
    final db = await database;
    final id = question.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : question.id;
    final q = Question(
      id: id,
      deckId: question.deckId,
      knowledgePointId: question.knowledgePointId,
      type: question.type,
      content: question.content,
      options: question.options,
      answer: question.answer,
      explanation: question.explanation,
      difficulty: question.difficulty,
      sourceStatus: question.sourceStatus,
      citationIds: question.citationIds,
      lastReviewedAt: question.lastReviewedAt,
      nextReviewAt: question.nextReviewAt,
      ease: question.ease,
      lapseCount: question.lapseCount,
      matchLeft: question.matchLeft,
      matchRight: question.matchRight,
    );
    await db.insert('questions', q.toMap());
    return id;
  }

  Future<List<Question>> getQuestionsByDeck(String deckId) async {
    final db = await database;
    final maps =
        await db.query('questions', where: 'deck_id = ?', whereArgs: [deckId]);
    return maps.map(Question.fromMap).toList();
  }

  Future<void> updateQuestion(Question question) async {
    final db = await database;
    await db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<void> updateQuestions(List<Question> questions) async {
    if (questions.isEmpty) return;
    final db = await database;
    await db.transaction((transaction) async {
      for (final question in questions) {
        final updated = await transaction.update(
          'questions',
          question.toMap(),
          where: 'id = ?',
          whereArgs: [question.id],
        );
        if (updated != 1) {
          throw StateError(
            'Question not found during bulk update: ${question.id}',
          );
        }
      }
    });
  }

  // ============ 随机抽题 ============

  /// 获取所有题目（跨题包）
  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final maps = await db.query('questions');
    return maps.map(Question.fromMap).toList();
  }

  /// 随机抽取指定数量的题目
  Future<List<Question>> getRandomQuestions(int count) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM questions ORDER BY RANDOM() LIMIT ?',
      [count],
    );
    return maps.map(Question.fromMap).toList();
  }

  // ============ StudyRecord 操作 ============

  Future<void> upsertStudyRecord(StudyRecord record) async {
    final db = await database;
    await db.insert('study_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<StudyRecord?> getStudyRecord(String deckId) async {
    final db = await database;
    final maps = await db
        .query('study_records', where: 'deck_id = ?', whereArgs: [deckId]);
    if (maps.isEmpty) return null;
    return StudyRecord.fromMap(maps.first);
  }

  // ============ UserStats 操作 ============

  Future<UserStats> getUserStats() async {
    final db = await database;
    final maps = await db.query('user_stats', where: 'id = 1');
    if (maps.isEmpty) {
      return UserStats(lastStudyDate: DateTime.now());
    }
    return UserStats.fromMap(maps.first);
  }

  Future<void> updateUserStats(UserStats stats) async {
    final db = await database;
    await db.update('user_stats', stats.toMap(), where: 'id = 1');
  }
}
