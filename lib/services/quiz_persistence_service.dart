import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/database_helper.dart';
import '../data/models/knowledge_point.dart';
import '../data/models/question.dart';
import '../data/models/study_record.dart';
import '../data/models/user_stats.dart';
import 'gamification_service.dart';
import 'scheduling/mastery_service.dart';
import 'scheduling/review_scheduler_service.dart';

class QuizAnswerSaveResult {
  final Question question;
  final bool isCorrect;
  final UserStats stats;

  const QuizAnswerSaveResult({
    required this.question,
    required this.isCorrect,
    required this.stats,
  });

  int get xpGained => isCorrect ? GamificationService.xpPerCorrect : 0;

  Map<String, Object?> get reviewFields => {
        'last_reviewed_at': question.lastReviewedAt?.millisecondsSinceEpoch,
        'next_review_at': question.nextReviewAt?.millisecondsSinceEpoch,
        'ease': question.ease,
        'lapse_count': question.lapseCount,
      };

  Map<String, Object?> toMap() => {
        'review': reviewFields,
        'is_correct': isCorrect,
        'stats': stats.toMap(),
      };

  factory QuizAnswerSaveResult.fromMap(
      Map<String, dynamic> map, Question question) {
    final review = Map<String, dynamic>.from(map['review'] as Map);
    return QuizAnswerSaveResult(
      question: question.copyWith(
        lastReviewedAt: DateTime.fromMillisecondsSinceEpoch(
            review['last_reviewed_at'] as int),
        nextReviewAt: DateTime.fromMillisecondsSinceEpoch(
            review['next_review_at'] as int),
        ease: (review['ease'] as num).toDouble(),
        lapseCount: review['lapse_count'] as int,
      ),
      isCorrect: map['is_correct'] as bool,
      stats: UserStats.fromMap(Map<String, dynamic>.from(map['stats'] as Map)),
    );
  }
}

class QuizCompletionSaveResult {
  final UserStats statsBefore;
  final UserStats statsAfter;
  final int xpGained;
  final bool allCorrect;

  const QuizCompletionSaveResult({
    required this.statsBefore,
    required this.statsAfter,
    required this.xpGained,
    required this.allCorrect,
  });

  Map<String, Object?> toMap() => {
        'stats_before': statsBefore.toMap(),
        'stats_after': statsAfter.toMap(),
        'xp_gained': xpGained,
        'all_correct': allCorrect,
      };

  factory QuizCompletionSaveResult.fromMap(Map<String, dynamic> map) =>
      QuizCompletionSaveResult(
        statsBefore: UserStats.fromMap(
            Map<String, dynamic>.from(map['stats_before'] as Map)),
        statsAfter: UserStats.fromMap(
            Map<String, dynamic>.from(map['stats_after'] as Map)),
        xpGained: map['xp_gained'] as int,
        allCorrect: map['all_correct'] as bool,
      );
}

/// Each receipt commits with all its learning effects. Replaying its ID returns
/// the original result, including after reopening the database. The caller owns
/// the ID and retains its judged input until the save has been acknowledged.
class QuizPersistenceService {
  final DatabaseHelper _databaseHelper;
  final GamificationService _gamificationService;
  final ReviewSchedulerService _reviewScheduler;
  final DateTime Function() _clock;

  QuizPersistenceService({
    required DatabaseHelper databaseHelper,
    required GamificationService gamificationService,
    required ReviewSchedulerService reviewScheduler,
    DateTime Function()? clock,
  })  : _databaseHelper = databaseHelper,
        _gamificationService = gamificationService,
        _reviewScheduler = reviewScheduler,
        _clock = clock ?? DateTime.now;

  Future<QuizAnswerSaveResult> saveAnswer({
    required String operationId,
    required Question question,
    required bool isCorrect,
  }) async {
    final inputHash = _answerHash(question, isCorrect);
    final saved = await _databaseHelper.runInTransaction((transaction) async {
      final receipt =
          await _receipt(transaction, operationId, 'answer', inputHash);
      if (receipt != null) {
        return (
          result: QuizAnswerSaveResult.fromMap(receipt, question),
          fresh: false
        );
      }

      final rows = await transaction.query(
        'questions',
        where: 'id = ?',
        whereArgs: [question.id],
      );
      if (rows.isEmpty) {
        throw StateError('The question is no longer available.');
      }
      final current = Question.fromMap(rows.single);
      if (current.sourceStatus != SourceStatus.verified ||
          _answerHash(current, isCorrect) != inputHash) {
        throw StateError(
            'The question changed. Reopen the quiz before answering.');
      }
      final now = _clock();
      final game = _gamificationService.inTransaction(transaction, now: now);
      await game.recordCheckIn();
      final stats =
          isCorrect ? await game.onCorrectAnswer() : await game.onWrongAnswer();
      if (isCorrect) await game.incrementTotalCorrect();

      final updated = ReviewSchedulerService.reviewedQuestion(
        current,
        isCorrect,
        now: now,
      );
      final result = QuizAnswerSaveResult(
        question: updated,
        isCorrect: isCorrect,
        stats: stats,
      );
      await transaction.update(
        'questions',
        result.reviewFields,
        where: 'id = ?',
        whereArgs: [current.id],
      );
      final pointId = current.knowledgePointId;
      if (pointId != null && pointId.isNotEmpty) {
        final points = await transaction.query(
          'knowledge_points',
          where: 'id = ?',
          whereArgs: [pointId],
        );
        if (points.isNotEmpty) {
          final point = MasteryService.questionAttemptResult(
            KnowledgePoint.fromMap(points.single),
            isCorrect,
            now: now,
          );
          await transaction.update(
            'knowledge_points',
            {
              'mastery_level': point.masteryLevel,
              'updated_at': now.millisecondsSinceEpoch
            },
            where: 'id = ?',
            whereArgs: [pointId],
          );
        }
      }
      await _saveReceipt(
        transaction,
        operationId,
        'answer',
        inputHash,
        result.toMap(),
        now,
      );
      return (result: result, fresh: true);
    });

    if (saved.fresh) {
      try {
        await _reviewScheduler.recordReviewEvents(
          question: question,
          updated: saved.result.question,
          now: saved.result.question.lastReviewedAt!,
          operationId: 'quiz_answer_$operationId',
        );
      } catch (_) {
        // Optional telemetry cannot turn an accepted save into a save failure.
      }
    }
    return saved.result;
  }

  Future<QuizCompletionSaveResult> saveCompletion({
    required String operationId,
    required String? deckId,
    required int correctCount,
    required int totalCount,
  }) async {
    if (totalCount <= 0 || correctCount < 0 || correctCount > totalCount) {
      throw ArgumentError('Invalid quiz completion counts.');
    }
    final inputHash = _hash(['completion', deckId, correctCount, totalCount]);
    return _databaseHelper.runInTransaction((transaction) async {
      final receipt =
          await _receipt(transaction, operationId, 'completion', inputHash);
      if (receipt != null) return QuizCompletionSaveResult.fromMap(receipt);
      final now = _clock();
      final game = _gamificationService.inTransaction(transaction, now: now);
      final before = await game.getStats();
      final allCorrect = correctCount == totalCount;
      var after = await game.onDeckComplete(allCorrect: allCorrect);
      if (allCorrect) {
        after = await game.onPerfectQuiz();
        await game.incrementPerfectCount();
      }

      if (deckId != null) {
        final record = StudyRecord(
          id: '${deckId}_record',
          deckId: deckId,
          correctCount: correctCount,
          totalCount: totalCount,
          lastStudiedAt: now,
        );
        await transaction.insert(
          'study_records',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        final updated = await transaction.update(
          'decks',
          {
            'mastery_level':
                game.calculateMasteryLevel(correctCount, totalCount),
            'updated_at': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [deckId],
        );
        if (updated != 1) throw StateError('The deck is no longer available.');
      }

      final result = QuizCompletionSaveResult(
        statsBefore: before,
        statsAfter: after,
        xpGained: after.xp - before.xp,
        allCorrect: allCorrect,
      );
      await _saveReceipt(
        transaction,
        operationId,
        'completion',
        inputHash,
        result.toMap(),
        now,
      );
      return result;
    });
  }

  Future<Map<String, dynamic>?> _receipt(
    DatabaseExecutor executor,
    String operationId,
    String kind,
    String inputHash,
  ) async {
    if (operationId.trim().isEmpty) {
      throw ArgumentError('An operation ID is required.');
    }
    final rows = await executor.query(
      'quiz_save_operations',
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    if (row['operation_kind'] != kind || row['input_hash'] != inputHash) {
      throw StateError(
          'The save operation ID was reused with different input.');
    }
    return Map<String, dynamic>.from(
        jsonDecode(row['result_json'] as String) as Map);
  }

  Future<void> _saveReceipt(
    DatabaseExecutor executor,
    String operationId,
    String kind,
    String inputHash,
    Map<String, Object?> result,
    DateTime now,
  ) async {
    await executor.insert('quiz_save_operations', {
      'operation_id': operationId,
      'operation_kind': kind,
      'input_hash': inputHash,
      'result_json': jsonEncode(result),
      'created_at': now.millisecondsSinceEpoch,
    });
  }

  String _answerHash(Question question, bool isCorrect) {
    // Review metadata can legitimately change between display and save; source
    // content and the judged question must still match. Only the hash is stored.
    final input = question.toMap()
      ..remove('last_reviewed_at')
      ..remove('next_review_at')
      ..remove('ease')
      ..remove('lapse_count');
    return _hash(['answer', input, isCorrect]);
  }

  String _hash(Object value) =>
      sha256.convert(utf8.encode(jsonEncode(value))).toString();
}
