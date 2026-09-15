import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/deck.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:anchor_learning/services/quiz_persistence_service.dart';
import 'package:anchor_learning/services/scheduling/review_scheduler_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final now = DateTime(2026, 9, 20, 12);
  late Directory directory;
  late DatabaseHelper helper;
  late GamificationService game;
  late QuizPersistenceService service;
  late Question question;

  void connect() {
    helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      databasePath: path.join(directory.path, 'quiz.db'),
    );
    game = GamificationService(helper, clock: () => now);
    service = QuizPersistenceService(
      databaseHelper: helper,
      gamificationService: game,
      reviewScheduler: ReviewSchedulerService(
        questionRepository: QuestionRepository(helper),
        knowledgePointRepository: KnowledgePointRepository(helper),
      ),
      clock: () => now,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'total_correct': 41,
      'perfect_count': 3,
      'checkin_2026_9': ['2026-09-01'],
    });
    directory =
        await Directory.systemTemp.createTemp('anchor_quiz_persistence_');
    connect();
    final database = await helper.database;
    await database.insert(
        'decks',
        Deck(
          id: 'deck',
          title: 'Synthetic deck',
          createdAt: now,
          updatedAt: now,
        ).toMap());
    await database.insert(
        'knowledge_points',
        KnowledgePoint(
          id: 'point',
          title: 'Synthetic point',
          summary: 'Synthetic summary',
          masteryLevel: 40,
          createdAt: now,
          updatedAt: now,
        ).toMap());
    question = Question(
      id: 'question',
      deckId: 'deck',
      knowledgePointId: 'point',
      type: QuestionType.multipleChoice,
      content: 'Synthetic question text',
      answer: 'Synthetic reference answer',
      options: const ['Synthetic reference answer', 'Other answer'],
      sourceStatus: SourceStatus.verified,
      citationIds: const ['synthetic-chunk'],
    );
    await database.insert('questions', question.toMap());
    await helper.updateUserStats(UserStats(
      xp: 100,
      hearts: 3,
      streak: 2,
      todayXp: 20,
      lastStudyDate: now,
    ));
  });

  tearDown(() async {
    await helper.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<String> snapshot() async {
    final database = await helper.database;
    final tables = <String, Object>{};
    for (final table in [
      'user_stats',
      'questions',
      'knowledge_points',
      'decks',
      'study_records',
      'gamification_state',
      'quiz_save_operations',
      'product_events',
    ]) {
      tables[table] = await database.query(table, orderBy: 'rowid');
    }
    return jsonEncode(tables);
  }

  Future<void> failAfter(String table, String event) async {
    await (await helper.database).execute('''
      CREATE TRIGGER fail_quiz_save AFTER $event ON $table
      BEGIN SELECT RAISE(ABORT, 'synthetic quiz save failure'); END
    ''');
  }

  Future<QuizAnswerSaveResult> answer(String id, {bool correct = true}) =>
      service.saveAnswer(
          operationId: id, question: question, isCorrect: correct);

  Future<QuizCompletionSaveResult> complete(String id,
          {bool perfect = true, String? deckId = 'deck'}) =>
      service.saveCompletion(
        operationId: id,
        deckId: deckId,
        correctCount: perfect ? 2 : 1,
        totalCount: 2,
      );

  for (final correct in [true, false]) {
    for (final failure in [
      (table: 'questions', event: 'UPDATE'),
      (table: 'knowledge_points', event: 'UPDATE'),
      (table: 'quiz_save_operations', event: 'INSERT'),
    ]) {
      test('$correct answer rolls back after ${failure.table} and retries once',
          () async {
        final before = await snapshot();
        await failAfter(failure.table, failure.event);
        for (var attempt = 0; attempt < 2; attempt++) {
          await expectLater(answer('answer-op', correct: correct),
              throwsA(isA<DatabaseException>()));
          expect(await snapshot(), before);
        }
        await (await helper.database).execute('DROP TRIGGER fail_quiz_save');
        final result = await answer('answer-op', correct: correct);
        final replay = await Future.wait(List.generate(
          3,
          (_) => answer('answer-op', correct: correct),
        ));
        expect(
            replay.map((item) => item.toMap()), everyElement(result.toMap()));
        expect((await game.getStats()).xp, correct ? 110 : 100);
        expect((await game.getStats()).hearts, correct ? 3 : 2);
        expect(await game.getTotalCorrect(), correct ? 42 : 41);
        expect(await game.getMonthlyCheckInDates(2026, 9),
            ['2026-09-01', '2026-09-20']);
        final stored = (await helper.getAllQuestions()).single;
        expect(stored.ease, closeTo(correct ? 1.12 : 0.8, 0.00001));
        expect(stored.lapseCount, correct ? 0 : 1);
        expect((await helper.getKnowledgePoint('point'))!.masteryLevel,
            correct ? 50 : 37);
        expect(await (await helper.database).query('quiz_save_operations'),
            hasLength(1));
      });
    }
  }

  for (final perfect in [true, false]) {
    for (final failure in [
      (table: 'study_records', event: 'INSERT'),
      (table: 'decks', event: 'UPDATE'),
      (table: 'quiz_save_operations', event: 'INSERT'),
    ]) {
      test(
          '$perfect completion rolls back after ${failure.table} and retries once',
          () async {
        final before = await snapshot();
        await failAfter(failure.table, failure.event);
        for (var attempt = 0; attempt < 2; attempt++) {
          await expectLater(complete('completion-op', perfect: perfect),
              throwsA(isA<DatabaseException>()));
          expect(await snapshot(), before);
        }
        await (await helper.database).execute('DROP TRIGGER fail_quiz_save');
        final result = await complete('completion-op', perfect: perfect);
        final replay = await Future.wait(List.generate(
          3,
          (_) => complete('completion-op', perfect: perfect),
        ));
        expect(
            replay.map((item) => item.toMap()), everyElement(result.toMap()));
        expect((await game.getStats()).xp, perfect ? 210 : 160);
        expect((await game.getStats()).hearts, perfect ? 4 : 3);
        expect(await game.getPerfectCount(), perfect ? 4 : 3);
        expect((await helper.getStudyRecord('deck'))!.correctCount,
            perfect ? 2 : 1);
        expect((await helper.getAllDecks()).single.masteryLevel,
            perfect ? 100 : 50);
        expect(
            await (await helper.database).query('study_records'), hasLength(1));
      });
    }
  }

  test(
      'concurrent distinct attempts use current review state and preserve rewards',
      () async {
    await Future.wait([answer('first'), answer('second'), game.getStats()]);
    expect((await game.getStats()).xp, 120);
    expect(await game.getTotalCorrect(), 43);
    expect(
        (await helper.getAllQuestions()).single.ease, closeTo(1.24, 0.00001));
    expect((await helper.getKnowledgePoint('point'))!.masteryLevel, 58);
  });

  test('same-ID concurrent first submissions commit one answer and completion',
      () async {
    await Future.wait(List.generate(5, (_) => answer('answer-op')));
    await Future.wait(List.generate(5, (_) => complete('completion-op')));
    expect((await game.getStats()).xp, 220);
    expect(await game.getTotalCorrect(), 42);
    expect(await game.getPerfectCount(), 4);
    expect(await (await helper.database).query('quiz_save_operations'),
        hasLength(2));
  });

  test('receipts replay after database reopen without rewriting newer progress',
      () async {
    final savedAnswer = await answer('answer-op');
    final savedCompletion = await complete('completion-op');
    await answer('new-answer', correct: false);
    final before = await snapshot();
    await helper.close();
    connect();
    expect((await answer('answer-op')).toMap(), savedAnswer.toMap());
    expect((await complete('completion-op')).toMap(), savedCompletion.toMap());
    expect(await snapshot(), before);
  });

  test('receipt rejects changed input and operation kind without any writes',
      () async {
    await answer('same-id');
    final before = await snapshot();
    await expectLater(answer('same-id', correct: false), throwsStateError);
    await expectLater(complete('same-id'), throwsStateError);
    expect(await snapshot(), before);
  });

  test('changed or removed question cannot receive a stale judged result',
      () async {
    final database = await helper.database;
    await database.update('questions', {'answer': 'Changed reference'},
        where: 'id = ?', whereArgs: ['question']);
    final before = await snapshot();
    await expectLater(answer('stale-answer'), throwsStateError);
    expect(await snapshot(), before);
    await database.delete('questions');
    final removed = await snapshot();
    await expectLater(answer('removed-answer'), throwsStateError);
    expect(await snapshot(), removed);
  });

  test('completion without a deck still awards exactly once', () async {
    final result = await complete('random-op', deckId: null);
    await complete('random-op', deckId: null);
    expect(result.xpGained, 110);
    expect((await game.getStats()).xp, 210);
    expect(await (await helper.database).query('study_records'), isEmpty);
  });

  test('missing deck rolls back completion rewards', () async {
    final before = await snapshot();
    await expectLater(complete('missing-deck', deckId: 'missing'),
        throwsA(isA<DatabaseException>()));
    expect(await snapshot(), before);
  });

  test('failure at SQLite commit rolls back effects and receipt together',
      () async {
    final database = await helper.database;
    await database
        .execute('CREATE TABLE commit_parent (id INTEGER PRIMARY KEY)');
    await database.execute('''
      CREATE TABLE commit_guard (
        parent_id INTEGER REFERENCES commit_parent(id) DEFERRABLE INITIALLY DEFERRED
      )
    ''');
    await database.execute('''
      CREATE TRIGGER fail_at_commit AFTER INSERT ON quiz_save_operations
      BEGIN INSERT INTO commit_guard (parent_id) VALUES (1); END
    ''');
    final before = await snapshot();
    await expectLater(answer('commit-op'), throwsA(isA<DatabaseException>()));
    expect(await snapshot(), before);
    await (await helper.database).execute('DROP TRIGGER fail_at_commit');
    await answer('commit-op');
    expect((await game.getStats()).xp, 110);
  });

  test('legacy preferences import once and are included in medal/counter reads',
      () async {
    SharedPreferences.setMockInitialValues({
      'total_correct': 75,
      'perfect_count': 6,
      'checkin_2026_9': List.generate(
          19, (i) => '2026-09-${(i + 1).toString().padLeft(2, '0')}'),
      'medal_2026_8': true,
      'unrelated_preference': 'keep',
    });
    expect(await game.getTotalCorrect(), 75);
    await game.recordCheckIn();
    await game.recordCheckIn();
    expect(await game.getMonthlyCheckInCount(2026, 9), 20);
    expect(await game.hasMonthlyMedal(2026, 9), isTrue);
    expect(await game.getEarnedMedals(),
        [(year: 2026, month: 9), (year: 2026, month: 8)]);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('total_correct', 999);
    await game.migrateLegacyStatistics();
    expect(await game.getTotalCorrect(), 75);
    expect(await game.getPerfectCount(), 6);
    expect(preferences.getString('unrelated_preference'), 'keep');
  });

  test('failed legacy import leaves no marker or partial counter values',
      () async {
    await failAfter('gamification_state', 'INSERT');
    final before = await snapshot();
    await expectLater(
        game.migrateLegacyStatistics(), throwsA(isA<DatabaseException>()));
    expect(await snapshot(), before);
    await (await helper.database).execute('DROP TRIGGER fail_quiz_save');
    await Future.wait(List.generate(10, (_) => game.incrementTotalCorrect()));
    expect(await game.getTotalCorrect(), 51);
  });

  test('receipts contain no question or reference-answer text', () async {
    await answer('answer-op');
    await complete('completion-op');
    final receiptText =
        jsonEncode(await (await helper.database).query('quiz_save_operations'));
    expect(receiptText, isNot(contains(question.content)));
    expect(receiptText, isNot(contains(question.answer)));
    expect(receiptText, isNot(contains('Synthetic summary')));
  });

  test('post-commit telemetry failure does not fail or replay the saved answer',
      () async {
    final scheduler = _FailingEventScheduler();
    service = QuizPersistenceService(
      databaseHelper: helper,
      gamificationService: game,
      reviewScheduler: scheduler,
      clock: () => now,
    );
    await answer('telemetry-op');
    await answer('telemetry-op');
    expect(scheduler.calls, 1);
    expect((await game.getStats()).xp, 110);
    expect(await game.getTotalCorrect(), 42);
  });
}

class _FailingEventScheduler extends Fake implements ReviewSchedulerService {
  int calls = 0;

  @override
  Future<void> recordReviewEvents({
    required Question question,
    required Question updated,
    required DateTime now,
    String? operationId,
  }) async {
    calls++;
    throw StateError('Synthetic telemetry failure');
  }
}
