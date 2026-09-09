import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/study_record.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/study_record_repository.dart';
import 'package:anchor_learning/features/learning/quiz_screen.dart';
import 'package:anchor_learning/features/learning/widgets/question_widgets.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:anchor_learning/services/quiz_persistence_service.dart';
import 'package:anchor_learning/services/scheduling/mastery_service.dart';
import 'package:anchor_learning/services/scheduling/review_scheduler_service.dart';
import 'package:anchor_learning/shared/widgets/anchor_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final correct in [true, false]) {
    testWidgets('late $correct answer refreshes consumers after parent return',
        (tester) async {
      final harness = _Harness();
      harness.game.checkInGate = Completer<void>();
      await harness.pump(tester);
      await tester.tap(find.text(correct ? 'First answer' : 'Second answer'));
      await tester.pump();
      _action(tester, '检查')();
      await tester.pump();
      harness.showQuiz.value = false;
      await tester.pump();
      await harness.refreshParent(tester);
      expect(harness.container.read(userStatsProvider).value!.xp, 10000);
      expect(
          harness.container.read(todayReviewQueueProvider).value, hasLength(1));
      harness.game.checkInGate!.complete();
      await tester.pumpAndSettle();
      final container = harness.container;
      expect({
        'xp': container.read(userStatsProvider).value!.xp,
        'hearts': container.read(userStatsProvider).value!.hearts,
        'due': container.read(todayReviewQueueProvider).value!.length,
        'reviewed':
            container.read(allQuestionsProvider).value!.single.lastReviewedAt !=
                null,
        'mastery': container
            .read(knowledgePointProvider('quiz-point'))
            .value!
            .masteryLevel,
        'correct': container.read(totalCorrectProvider).value,
        'checkin':
            container.read(monthlyCheckInProvider('2026_9')).value!.length,
      }, {
        'xp': correct ? 10010 : 10000,
        'hearts': correct ? 5 : 4,
        'due': 0,
        'reviewed': true,
        'mastery': correct ? 50 : 37,
        'correct': correct ? 1 : 0,
        'checkin': 1,
      });
      expect(find.text('Quiz closed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('late completion refreshes the accepted record and perfect count',
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
    await harness.refreshParent(tester);
    expect(
        harness.container.read(studyRecordProvider('quiz-deck')).value, isNull);
    expect(harness.container.read(perfectCountProvider).value, 0);
    harness.game.completionGate!.complete();
    await tester.pumpAndSettle();
    final container = harness.container;
    expect({
      'xp': container.read(userStatsProvider).value!.xp,
      'perfects': container.read(perfectCountProvider).value,
      'correct':
          container.read(studyRecordProvider('quiz-deck')).value?.correctCount,
    }, {
      'xp': 10110,
      'perfects': 1,
      'correct': 1
    });
    expect(tester.takeException(), isNull);
  });

  for (final finishing in [false, true]) {
    testWidgets(
        'older ${finishing ? 'completion' : 'answer'} result keeps newer stats',
        (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      await tester.tap(find.text('First answer'));
      await tester.pump();
      final gate = Completer<void>();
      if (finishing) {
        _action(tester, '检查')();
        await tester.pumpAndSettle();
        harness.persistence.completionReplyGate = gate;
      } else {
        harness.persistence.answerReplyGate = gate;
      }
      _action(tester, finishing ? '完成' : '检查')();
      await tester.pump();
      harness.game.stats = harness.game.stats.copyWith(xp: 12000, streak: 7);
      await harness.container.read(userStatsProvider.notifier).refresh();
      gate.complete();
      await tester.pumpAndSettle();
      expect(harness.container.read(userStatsProvider).value!.xp, 12000);
      if (finishing) expect(find.text('连续7天奖励'), findsNothing);
      expect(find.textContaining('保存失败'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'scope disposal during ${finishing ? 'completion' : 'answer'} is safe',
        (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      await tester.tap(find.text('First answer'));
      await tester.pump();
      final gate = Completer<void>();
      if (finishing) {
        _action(tester, '检查')();
        await tester.pumpAndSettle();
        harness.game.completionGate = gate;
      } else {
        harness.game.checkInGate = gate;
      }
      _action(tester, finishing ? '完成' : '检查')();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await tester.pumpAndSettle();
      expect(harness.game.correct, 1);
      expect(harness.game.completions, finishing ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final finishing in [false, true]) {
    for (final failedRead in [false, true]) {
      testWidgets(
          '${finishing ? 'completion' : 'answer'} succeeds with a ${failedRead ? 'failed' : 'pending'} stats refresh',
          (tester) async {
        final harness = _Harness();
        await harness.pump(tester);
        await tester.tap(find.text('First answer'));
        await tester.pump();
        if (finishing) {
          _action(tester, '检查')();
          await tester.pumpAndSettle();
        }
        if (failedRead) {
          harness.game.failStatsReads = true;
        } else {
          harness.game.statsReadGate = Completer<UserStats>();
        }
        _action(tester, finishing ? '完成' : '检查')();
        await tester.pumpAndSettle();
        expect(find.text(finishing ? '答对 1 / 1 题' : '答对了！'), findsOneWidget);
        expect(find.textContaining('保存失败'), findsNothing);
        expect(harness.game.correct, 1);
        expect(harness.game.completions, finishing ? 1 : 0);
        harness.game.statsReadGate?.complete(harness.game.stats);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('heart exhaustion uses the saved result when stats refresh fails',
      (tester) async {
    final harness = _Harness();
    harness.game.stats = harness.game.stats.copyWith(hearts: 1);
    await harness.pump(tester);
    harness.game.failStatsReads = true;
    await tester.tap(find.text('Second answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('心数用完了！'), findsOneWidget);
    expect(harness.game.stats.hearts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lost save acknowledgement retries the same committed operations',
      (tester) async {
    final harness = _Harness();
    harness.persistence.loseAnswerAcknowledgement = true;
    harness.persistence.loseCompletionAcknowledgement = true;
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    expect(find.textContaining('答案保存失败'), findsOneWidget);
    _action(tester, '重试保存答案')();
    await tester.pumpAndSettle();
    _action(tester, '完成')();
    await tester.pumpAndSettle();
    expect(find.textContaining('结果保存失败'), findsOneWidget);
    _action(tester, '重试保存结果')();
    await tester.pumpAndSettle();
    expect(harness.game.correct, 1);
    expect(harness.game.completions, 1);
    expect(harness.game.perfectCount, 1);
    expect(harness.decks.records, [('quiz-deck', 1, 1)]);
    expect(find.text('答对 1 / 1 题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final finishing in [false, true]) {
    testWidgets(
        'late ${finishing ? 'completion' : 'answer'} failure after exit is handled',
        (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      await tester.tap(find.text('First answer'));
      await tester.pump();
      if (finishing) {
        _action(tester, '检查')();
        await tester.pumpAndSettle();
        harness.decks.failuresRemaining = 1;
        harness.decks.gate = Completer<void>();
      } else {
        harness.reviews.failuresRemaining = 1;
        harness.reviews.gate = Completer<void>();
      }
      _action(tester, finishing ? '完成' : '检查')();
      await tester.pump();
      harness.showQuiz.value = false;
      await tester.pump();
      (finishing ? harness.decks.gate : harness.reviews.gate)!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Quiz closed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'short large-text ${finishing ? 'completion' : 'answer'} error can retry',
        (tester) async {
      final harness = _Harness();
      await harness.pump(tester, size: const Size(320, 740), textScale: 2);
      await tester.tap(find.text('First answer'));
      await tester.pump();
      if (finishing) {
        _action(tester, '检查')();
        await tester.pumpAndSettle();
        harness.decks.failuresRemaining = 1;
      } else {
        harness.reviews.failuresRemaining = 1;
      }
      _action(tester, finishing ? '完成' : '检查')();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 400);
      await tester.pumpAndSettle();
      final retry = find.text(finishing ? '重试保存结果' : '重试保存答案');
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(tester.getRect(retry).bottom, lessThanOrEqualTo(400));
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(320, 740);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.textContaining('保存失败'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('save diagnostics omit raw SQLite error arguments',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final harness = _Harness();
    harness.reviews.failuresRemaining = 1;
    harness.reviews.errorMessage = 'SQL args include Synthetic private answer';
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    expect(find.textContaining('Synthetic private answer'), findsNothing);
    await tester.tap(find.text('复制诊断'));
    await tester.pumpAndSettle();
    expect(copied, contains('保存阶段: 答案'));
    expect(copied, isNot(contains('Synthetic private answer')));
    expect(copied, isNot(contains('First answer')));
  });

  testWidgets(
      'answer save failure can retry without judging or rewarding twice',
      (tester) async {
    final harness = _Harness();
    harness.reviews.failuresRemaining = 1;
    await harness.pump(tester, questions: [_question('q1', fillBlank: true)]);
    await tester.enterText(find.byType(TextField), 'submitted equivalent');
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('答案保存失败'), findsOneWidget);
    final retry = _action(tester, '重试保存答案');
    retry();
    retry();
    await tester.pumpAndSettle();
    expect(harness.ai.answers, ['submitted equivalent']);
    expect(harness.persistence.answerIds.toSet(), hasLength(1));
    expect(harness.game.correct, 1);
    expect(harness.game.totalCorrect, 1);
    expect(harness.reviews.answers, [('q1', true)]);
    expect(harness.mastery.answers, [('q1', true)]);
    expect(find.text('答对了！'), findsOneWidget);
  });

  testWidgets('repeated wrong-answer save failures deduct only one heart',
      (tester) async {
    final harness = _Harness();
    harness.reviews.failuresRemaining = 2;
    await harness.pump(tester);
    await tester.tap(find.text('Second answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var attempt = 0; attempt < 2; attempt++) {
      _action(tester, '重试保存答案')();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(harness.game.wrong, 1);
    expect(harness.game.stats.hearts, 4);
    expect(harness.reviews.answers, [('q1', false)]);
    expect(find.text('答错了'), findsOneWidget);
  });

  testWidgets('completion save failures can retry without duplicate bonuses',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await tester.tap(find.text('First answer'));
    await tester.pump();
    _action(tester, '检查')();
    await tester.pumpAndSettle();
    harness.decks.failuresRemaining = 2;
    _action(tester, '完成')();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('结果保存失败'), findsOneWidget);
    for (var attempt = 0; attempt < 2; attempt++) {
      _action(tester, '重试保存结果')();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(harness.game.completions, 1);
    expect(harness.game.perfectCount, 1);
    expect(harness.persistence.completionIds.toSet(), hasLength(1));
    expect(harness.decks.records, [('quiz-deck', 1, 1)]);
    expect(find.text('答对 1 / 1 题'), findsOneWidget);
  });

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

VoidCallback _action(WidgetTester tester, String label) {
  final anchor = find.widgetWithText(AnchorButton, label);
  if (anchor.evaluate().isNotEmpty) {
    return tester.widget<AnchorButton>(anchor).onPressed!;
  }
  return tester
      .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, label))
      .onPressed!;
}

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
  late final persistence = _Persistence(game, reviews, mastery, decks);
  final showQuiz = ValueNotifier(true);
  late ProviderContainer container;

  Future<void> refreshParent(WidgetTester tester) async {
    await container.read(userStatsProvider.notifier).refresh();
    container.invalidate(todayReviewQueueProvider);
    container.invalidate(allQuestionsProvider);
    container.invalidate(knowledgePointProvider('quiz-point'));
    container.invalidate(monthlyCheckInProvider('2026_9'));
    container.invalidate(totalCorrectProvider);
    container.invalidate(perfectCountProvider);
    container.invalidate(studyRecordProvider('quiz-deck'));
    void observe<T>(ProviderListenable<T> provider) {
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
    }

    observe(todayReviewQueueProvider);
    observe(allQuestionsProvider);
    observe(knowledgePointProvider('quiz-point'));
    observe(monthlyCheckInProvider('2026_9'));
    observe(totalCorrectProvider);
    observe(perfectCountProvider);
    observe(studyRecordProvider('quiz-deck'));
    await tester.pumpAndSettle();
  }

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
        quizPersistenceServiceProvider.overrideWithValue(persistence),
        questionRepositoryProvider.overrideWithValue(_Questions(reviews)),
        knowledgePointRepositoryProvider.overrideWithValue(_Points(mastery)),
        studyRecordRepositoryProvider.overrideWithValue(_Records(decks)),
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
    container = ProviderScope.containerOf(
      tester.element(find.byType(QuizScreen)),
      listen: false,
    );
  }
}

/// The widget suite controls the persistence boundary; the real transaction,
/// rollback and durable receipts are exercised by quiz_persistence_service_test.
class _Persistence extends Fake implements QuizPersistenceService {
  final _Game game;
  final _Reviews reviews;
  final _Mastery mastery;
  final _Decks decks;
  final answerIds = <String>[];
  final completionIds = <String>[];
  final _answers = <String, QuizAnswerSaveResult>{};
  final _completions = <String, QuizCompletionSaveResult>{};
  bool loseAnswerAcknowledgement = false;
  bool loseCompletionAcknowledgement = false;
  Completer<void>? answerReplyGate;
  Completer<void>? completionReplyGate;

  _Persistence(this.game, this.reviews, this.mastery, this.decks);

  @override
  Future<QuizAnswerSaveResult> saveAnswer({
    required String operationId,
    required Question question,
    required bool isCorrect,
  }) async {
    answerIds.add(operationId);
    if (_answers.containsKey(operationId)) return _answers[operationId]!;
    if (reviews.failuresRemaining > 0) {
      await reviews.recordQuestionReview(
          question: question, isCorrect: isCorrect);
    }
    await game.recordCheckIn();
    if (isCorrect) {
      await game.onCorrectAnswer();
      await game.incrementTotalCorrect();
    } else {
      await game.onWrongAnswer();
    }
    final updated = await reviews.recordQuestionReview(
      question: question,
      isCorrect: isCorrect,
    );
    await mastery.updateFromQuestionAttempt(
        question: question, isCorrect: isCorrect);
    final result = QuizAnswerSaveResult(
        question: updated, isCorrect: isCorrect, stats: game.stats);
    _answers[operationId] = result;
    await answerReplyGate?.future;
    if (loseAnswerAcknowledgement) {
      loseAnswerAcknowledgement = false;
      throw StateError('Synthetic lost answer acknowledgement');
    }
    return result;
  }

  @override
  Future<QuizCompletionSaveResult> saveCompletion({
    required String operationId,
    required String? deckId,
    required int correctCount,
    required int totalCount,
  }) async {
    completionIds.add(operationId);
    if (_completions.containsKey(operationId)) {
      return _completions[operationId]!;
    }
    if (deckId != null && decks.failuresRemaining > 0) {
      await decks.saveStudyRecord(deckId, correctCount, totalCount);
    }
    final before = game.stats;
    final allCorrect = correctCount == totalCount;
    await game.onDeckComplete(allCorrect: allCorrect);
    if (allCorrect) {
      await game.onPerfectQuiz();
      await game.incrementPerfectCount();
    }
    if (deckId != null) {
      await decks.saveStudyRecord(deckId, correctCount, totalCount);
    }
    final result = QuizCompletionSaveResult(
      statsBefore: before,
      statsAfter: game.stats,
      xpGained: game.stats.xp - before.xp,
      allCorrect: allCorrect,
    );
    _completions[operationId] = result;
    await completionReplyGate?.future;
    if (loseCompletionAcknowledgement) {
      loseCompletionAcknowledgement = false;
      throw StateError('Synthetic lost completion acknowledgement');
    }
    return result;
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
  bool failStatsReads = false;
  Completer<UserStats>? statsReadGate;

  @override
  Future<UserStats> getStats() async {
    if (failStatsReads) throw StateError('Synthetic statistics read failure');
    return statsReadGate == null ? stats : await statsReadGate!.future;
  }

  @override
  Future<void> recordCheckIn() async {
    await checkInGate?.future;
    checkIns++;
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

  @override
  Future<int> getTotalCorrect() async => totalCorrect;

  @override
  Future<int> getPerfectCount() async => perfectCount;

  @override
  Future<List<String>> getMonthlyCheckInDates(int year, int month) async =>
      checkIns == 0 ? [] : ['2026-09-08'];
}

class _Reviews extends Fake implements ReviewSchedulerService {
  final answers = <(String, bool)>[];
  Completer<void>? gate;
  int failuresRemaining = 0;
  String errorMessage = 'Synthetic review save failure';

  @override
  Future<List<ReviewQueueItem>> getTodayReviewQueue(
          {DateTime? now, int limit = 12}) async =>
      answers.isEmpty
          ? [
              ReviewQueueItem(
                  knowledgePoint: _point(40),
                  questions: [_question('q1')],
                  overdueCount: 0,
                  priority: 1)
            ]
          : [];

  @override
  Future<Question> recordQuestionReview({
    required Question question,
    required bool isCorrect,
    DateTime? now,
  }) async {
    await gate?.future;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError(errorMessage);
    }
    answers.add((question.id, isCorrect));
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
  int failuresRemaining = 0;
  Completer<void>? gate;

  @override
  Future<void> saveStudyRecord(String deckId, int correct, int total) async {
    await gate?.future;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('Synthetic record save failure');
    }
    records.add((deckId, correct, total));
  }
}

KnowledgePoint _point(int mastery) => KnowledgePoint(
      id: 'quiz-point',
      title: 'Synthetic point',
      summary: 'Synthetic summary',
      masteryLevel: mastery,
      createdAt: DateTime(2026, 9, 8),
      updatedAt: DateTime(2026, 9, 8),
    );

class _Questions extends Fake implements QuestionRepository {
  final _Reviews reviews;
  _Questions(this.reviews);

  @override
  Future<List<Question>> getAllQuestions() async => [
        _question('q1').copyWith(
            lastReviewedAt:
                reviews.answers.isEmpty ? null : DateTime(2026, 9, 8)),
      ];
}

class _Points extends Fake implements KnowledgePointRepository {
  final _Mastery mastery;
  _Points(this.mastery);

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async =>
      _point(mastery.answers.isEmpty
          ? 40
          : mastery.answers.last.$2
              ? 50
              : 37);
}

class _Records extends Fake implements StudyRecordRepository {
  final _Decks decks;
  _Records(this.decks);

  @override
  Future<StudyRecord?> getStudyRecord(String deckId) async {
    if (decks.records.isEmpty) return null;
    final record = decks.records.last;
    return StudyRecord(
        id: '${deckId}_record',
        deckId: deckId,
        correctCount: record.$2,
        totalCount: record.$3,
        lastStudiedAt: DateTime(2026, 9, 8));
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
