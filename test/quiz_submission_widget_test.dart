import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/features/learning/quiz_screen.dart';
import 'package:anchor_learning/features/learning/widgets/question_widgets.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:anchor_learning/services/scheduling/mastery_service.dart';
import 'package:anchor_learning/services/scheduling/review_scheduler_service.dart';
import 'package:anchor_learning/shared/widgets/anchor_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('repeated check awards and schedules a local answer once',
      (tester) async {
    final harness = _Harness();
    harness.game.checkInGate = Completer<void>();
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    final check = _action(tester, '检查');
    check();
    check();
    await tester.pump();
    harness.game.checkInGate!.complete();
    await tester.pumpAndSettle();

    expect(harness.game.checkIns, 1);
    expect(harness.game.correct, 1);
    expect(harness.game.totalCorrect, 1);
    expect(harness.reviews.answers, [('q1', true)]);
    expect(harness.mastery.answers, [('q1', true)]);
    expect(find.text('答对了！'), findsOneWidget);
    check();
    await tester.pumpAndSettle();
    expect(harness.game.correct, 1);
  });

  testWidgets('submitted selection stays fixed while review is being saved',
      (tester) async {
    final harness = _Harness();
    harness.reviews.gate = Completer<void>();
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pump();
    await tester.tap(find.text('Second answer'), warnIfMissed: false);
    await tester.pump();
    final selected = tester
        .widget<QuestionWidget>(find.byType(QuestionWidget))
        .selectedAnswer;
    harness.reviews.gate!.complete();
    await tester.pumpAndSettle();

    expect(selected, 'First answer');
    expect(harness.reviews.answers, [('q1', true)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated finish applies the completion and study record once',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    harness.game.completionGate = Completer<void>();
    final finish = _action(tester, '完成');
    finish();
    finish();
    await tester.pump();
    harness.game.completionGate!.complete();
    await tester.pumpAndSettle();

    expect(harness.game.completions, 1);
    expect(harness.game.perfects, 1);
    expect(harness.game.perfectCount, 1);
    expect(harness.decks.records, [('quiz-deck', 1, 1)]);
    expect(find.text('答对 1 / 1 题'), findsOneWidget);
    finish();
    await tester.pumpAndSettle();
    expect(harness.game.completions, 1);
  });

  testWidgets('a stale continue callback cannot skip the next question',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester, questions: [_question('q1'), _question('q2')]);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    final next = _action(tester, '继续');
    next();
    next();
    await tester.pumpAndSettle();

    expect(find.text('Question q2'), findsOneWidget);
    expect(harness.game.completions, 0);
    expect(harness.decks.records, isEmpty);
    final optionSurfaces = tester.widgetList<AnimatedContainer>(find.descendant(
      of: find.byType(MultipleChoiceWidget),
      matching: find.byType(AnimatedContainer),
    ));
    expect(optionSurfaces, hasLength(2));
    expect(
        optionSurfaces
            .map((option) => (option.decoration! as BoxDecoration).color),
        everyElement(Colors.white));
    expect(
      tester
          .widget<AnchorButton>(find.widgetWithText(AnchorButton, '检查'))
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Second answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    expect(harness.reviews.answers, [('q1', true), ('q2', false)]);
  });

  testWidgets('AI judging retains one submitted answer through all awaits',
      (tester) async {
    final harness = _Harness();
    harness.ai.keyGate = Completer<bool>();
    await harness.pump(tester, questions: [_question('q1', fillBlank: true)]);
    await tester.enterText(find.byType(TextField), 'submitted equivalent');
    await tester.pump();
    final check = _action(tester, '检查');
    check();
    check();
    await tester.pump();
    tester
        .widget<QuestionWidget>(find.byType(QuestionWidget))
        .onAnswerSelected('later edit');
    harness.ai.keyGate!.complete(true);
    await tester.pumpAndSettle();

    expect(harness.ai.answers, ['submitted equivalent']);
    expect(harness.game.correct, 1);
    expect(harness.reviews.answers, [('q1', true)]);
  });
  testWidgets('repeated wrong answer deducts one heart', (tester) async {
    final harness = _Harness();
    harness.game.checkInGate = Completer<void>();
    await harness.pump(tester);
    await tester.tap(find.text('Second answer'));
    await tester.pump();
    final check = _action(tester, '检查');
    check();
    check();
    await tester.pump();
    harness.game.checkInGate!.complete();
    await tester.pumpAndSettle();
    expect(harness.game.wrong, 1);
    expect(harness.game.stats.hearts, 4);
    expect(harness.reviews.answers, [('q1', false)]);
    expect(harness.mastery.answers, [('q1', false)]);
  });

  for (final duringJudge in [false, true]) {
    testWidgets(
        'leaving during AI ${duringJudge ? 'judging' : 'setup'} skips writes',
        (tester) async {
      final harness = _Harness();
      if (duringJudge) {
        harness.ai.judgeGate = Completer<bool>();
      } else {
        harness.ai.keyGate = Completer<bool>();
      }
      await harness.pump(tester, questions: [_question('q1', fillBlank: true)]);
      await tester.enterText(find.byType(TextField), 'submitted equivalent');
      await tester.pump();
      _action(tester, '检查')();
      await tester.pump();
      harness.showQuiz.value = false;
      await tester.pump();
      (duringJudge ? harness.ai.judgeGate : harness.ai.keyGate)!.complete(true);
      await tester.pumpAndSettle();
      expect(harness.ai.answers, hasLength(duringJudge ? 1 : 0));
      expect(harness.game.checkIns, 0);
      expect(harness.reviews.answers, isEmpty);
      expect(harness.mastery.answers, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'leaving during answer persistence finishes only its local writes',
      (tester) async {
    final harness = _Harness();
    harness.reviews.gate = Completer<void>();
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pump();
    harness.showQuiz.value = false;
    await tester.pump();
    harness.reviews.gate!.complete();
    await tester.pumpAndSettle();
    expect(harness.game.correct, 1);
    expect(harness.reviews.answers, [('q1', true)]);
    expect(harness.mastery.answers, [('q1', true)]);
    expect(harness.decks.records, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during completion does not abandon the accepted record',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    harness.game.completionGate = Completer<void>();
    _action(tester, '完成')();
    await tester.pump();
    harness.showQuiz.value = false;
    await tester.pump();
    harness.game.completionGate!.complete();
    await tester.pumpAndSettle();
    expect(harness.game.completions, 1);
    expect(harness.game.perfectCount, 1);
    expect(harness.decks.records, [('quiz-deck', 1, 1)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delayed out-of-hearts transition ignores a disposed screen',
      (tester) async {
    final harness = _Harness();
    harness.game.stats = harness.game.stats.copyWith(hearts: 1);
    await harness.pump(tester);
    await tester.tap(find.text('Second answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pump();
    harness.showQuiz.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(harness.game.wrong, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('random practice completes without a deck record',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester, deckId: null);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    _action(tester, '完成')();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(harness.game.completions, 1);
    expect(harness.decks.records, isEmpty);
    expect(find.text('答对 1 / 1 题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final finishing in [false, true]) {
    testWidgets(
        'large text keeps the pending ${finishing ? 'completion' : 'answer'} visible',
        (tester) async {
      final harness = _Harness();
      if (!finishing) harness.game.checkInGate = Completer<void>();
      await harness.pump(tester, size: const Size(320, 740), textScale: 2);
      await tester.tap(find.text('First answer'));
      await tester.pump();
      _action(tester, '检查')();
      await tester.pump();
      if (finishing) {
        await tester.pumpAndSettle();
        harness.game.completionGate = Completer<void>();
        _action(tester, '完成')();
        await tester.pump();
      }
      final label = find.text(finishing ? '正在保存结果...' : '正在保存答案...');
      expect(label, findsOneWidget);
      expect(tester.getRect(label).bottom, lessThanOrEqualTo(740));
      expect(tester.takeException(), isNull);
      harness.showQuiz.value = false;
      await tester.pump();
      (finishing ? harness.game.completionGate : harness.game.checkInGate)!
          .complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large-text completion keeps rewards and return reachable',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester, size: const Size(320, 740), textScale: 2);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    _action(tester, '完成')();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('答对 1 / 1 题'), findsOneWidget);
    await tester.ensureVisible(find.text('完美通关，恢复1颗心！'));
    await tester.pumpAndSettle();
    expect(
        tester.getRect(find.text('完美通关，恢复1颗心！')).right, lessThanOrEqualTo(320));
    await tester.ensureVisible(find.text('返回'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('返回')).bottom, lessThanOrEqualTo(740));
    expect(harness.decks.records, [('quiz-deck', 1, 1)]);
    expect(harness.game.completions, 1);
    expect(tester.takeException(), isNull);
  });
}

VoidCallback _action(WidgetTester tester, String label) => tester
    .widget<AnchorButton>(find.widgetWithText(AnchorButton, label))
    .onPressed!;

Question _question(String id, {bool fillBlank = false}) => Question(
      id: id,
      deckId: 'quiz-deck',
      knowledgePointId: 'quiz-point',
      type: fillBlank ? QuestionType.fillBlank : QuestionType.multipleChoice,
      content: fillBlank ? 'An answer is ___.' : 'Question $id',
      options: const ['First answer', 'Second answer'],
      answer: 'First answer',
      sourceStatus: SourceStatus.verified,
      citationIds: const ['quiz-chunk'],
    );

class _Harness {
  final game = _Game();
  final reviews = _Reviews();
  final mastery = _Mastery();
  final decks = _Decks();
  final ai = _AI();
  final showQuiz = ValueNotifier(true);

  Future<void> pump(
    WidgetTester tester, {
    List<Question>? questions,
    String? deckId = 'quiz-deck',
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        gamificationServiceProvider.overrideWithValue(game),
        reviewSchedulerServiceProvider.overrideWithValue(reviews),
        masteryServiceProvider.overrideWithValue(mastery),
        deckOperationsProvider.overrideWithValue(decks),
        openaiServiceProvider.overrideWithValue(ai),
        questionCitationChunksProvider.overrideWith((ref, id) async => []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ValueListenableBuilder(
          valueListenable: showQuiz,
          builder: (context, visible, child) => visible
              ? QuizScreen(
                  deckId: deckId, questions: questions ?? [_question('q1')])
              : const Scaffold(body: Text('Quiz closed')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }
}

class _Game extends Fake implements GamificationService {
  UserStats stats = UserStats(xp: 10000, lastStudyDate: DateTime(2026, 9, 8));
  Completer<void>? checkInGate;
  Completer<void>? completionGate;
  int checkIns = 0;
  int correct = 0;
  int wrong = 0;
  int totalCorrect = 0;
  int completions = 0;
  int perfects = 0;
  int perfectCount = 0;

  @override
  Future<UserStats> getStats() async => stats;

  @override
  Future<void> recordCheckIn() async {
    checkIns++;
    await checkInGate?.future;
  }

  @override
  Future<UserStats> onCorrectAnswer() async {
    correct++;
    return stats = stats.copyWith(xp: stats.xp + 10);
  }

  @override
  Future<UserStats> onWrongAnswer() async {
    wrong++;
    return stats = stats.copyWith(hearts: stats.hearts - 1);
  }

  @override
  Future<int> incrementTotalCorrect() async => ++totalCorrect;

  @override
  Future<UserStats> onDeckComplete({required bool allCorrect}) async {
    completions++;
    await completionGate?.future;
    return stats = stats.copyWith(xp: stats.xp + (allCorrect ? 100 : 50));
  }

  @override
  Future<UserStats> onPerfectQuiz() async {
    perfects++;
    return stats;
  }

  @override
  Future<int> incrementPerfectCount() async => ++perfectCount;
}

class _Reviews extends Fake implements ReviewSchedulerService {
  final answers = <(String, bool)>[];
  Completer<void>? gate;

  @override
  Future<Question> recordQuestionReview({
    required Question question,
    required bool isCorrect,
    DateTime? now,
  }) async {
    answers.add((question.id, isCorrect));
    await gate?.future;
    return question.copyWith(lastReviewedAt: DateTime(2026, 9, 8));
  }
}

class _Mastery extends Fake implements MasteryService {
  final answers = <(String, bool)>[];

  @override
  Future<void> updateFromQuestionAttempt({
    required Question question,
    required bool isCorrect,
  }) async =>
      answers.add((question.id, isCorrect));
}

class _Decks extends Fake implements DeckOperations {
  final records = <(String, int, int)>[];

  @override
  Future<void> saveStudyRecord(String deckId, int correct, int total) async {
    records.add((deckId, correct, total));
  }
}

class _AI extends Fake implements OpenAIService {
  Completer<bool>? keyGate;
  Completer<bool>? judgeGate;
  final answers = <String>[];

  @override
  Future<bool> hasApiKey({String? providerId}) async =>
      keyGate == null ? true : await keyGate!.future;

  @override
  Future<bool> judgeFillBlankAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
  }) async {
    answers.add(userAnswer);
    return judgeGate == null ? true : await judgeGate!.future;
  }
}
