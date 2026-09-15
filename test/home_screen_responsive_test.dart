import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/features/home/home_screen.dart';
import 'package:anchor_learning/features/learning/quiz_screen.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:anchor_learning/services/scheduling/review_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeGamificationService extends GamificationService {
  final UserStats _stats;

  _FakeGamificationService(this._stats)
      : super(DatabaseHelper.forTesting(
          databaseFactory: databaseFactoryFfi,
        ));

  @override
  Future<UserStats> getStats() async => _stats;
}

class _FakeUserStatsNotifier extends UserStatsNotifier {
  _FakeUserStatsNotifier(UserStats stats)
      : super(_FakeGamificationService(stats)) {
    state = AsyncValue.data(stats);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Today Review summary', () {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(320, 740), 2.0),
      (const Size(320, 600), 2.0),
    ]) {
      testWidgets('full counts and review navigation at $size / $scale',
          (tester) async {
        final reviews = _FakeReviewScheduler();
        await _pumpReviewHome(tester,
            size: size, scale: scale, reviews: reviews);
        final heading = find.text('今日复习 · 3 个知识点 · 12 题');
        final paragraph = tester.renderObject<RenderParagraph>(heading);
        expect(paragraph.didExceedMaxLines, isFalse,
            reason: 'The complete heading and both counts must be visible');
        final reviewButton = find.widgetWithText(ElevatedButton, '复习');
        final buttonRect = tester.getRect(reviewButton);
        final headingRect = tester.getRect(heading);
        for (final rect in [headingRect, buttonRect]) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        expect(headingRect.overlaps(buttonRect), isFalse);
        expect(tester.takeException(), isNull);

        await tester.tap(reviewButton);
        await tester.pumpAndSettle();
        expect(reviews.requestedLimits, [10]);
        expect(find.byType(QuizScreen), findsOneWidget);
        expect(find.text('Review fixture question 0'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(QuizScreen), findsNothing);
        expect(heading, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final state in ['empty', 'loading', 'error']) {
      testWidgets('hides review banner for $state queue', (tester) async {
        final pending = Completer<List<ReviewQueueItem>>();
        await _pumpReviewHome(tester, queue: () async {
          if (state == 'error') throw StateError('Synthetic queue failure');
          if (state == 'loading') return pending.future;
          return [];
        });
        expect(find.textContaining('今日复习'), findsNothing);
        expect(find.widgetWithText(ElevatedButton, '复习'), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        if (state == 'loading') pending.complete([]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('HomeScreen responsive layout', () {
    testWidgets('renders without overflow at 320px width and 2.0 text scale',
        (tester) async {
      // Set up narrow width (320 logical px) and large text scale (2.0)
      tester.view.physicalSize = const Size(640, 1600);
      tester.view.devicePixelRatio = 2.0; // 320 x 800 logical px
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testStats = UserStats(
        streak: 7,
        xp: 1250,
        hearts: 3,
        maxHearts: 5,
        todayXp: 50,
        dailyGoal: 100,
        lastStudyDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsProvider
                .overrideWith((ref) => _FakeUserStatsNotifier(testStats)),
            learningModeProvider.overrideWith((ref) => LearningModeNotifier()),
            verifiedQuestionsProvider.overrideWith((ref) async => []),
            deckListProvider.overrideWith((ref) async => []),
            todayReviewQueueProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2.0),
                ),
                child: child!,
              );
            },
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors were thrown
      final layoutException = tester.takeException();
      if (layoutException != null) {
        debugDumpRenderTree();
      }
      expect(layoutException, isNull,
          reason: 'Should not throw overflow exception at 320px/2.0x text');

      // Verify the "添加内容" button is present and reachable
      final addButton = find.widgetWithText(ElevatedButton, '添加内容');
      expect(addButton, findsOneWidget,
          reason: 'Add content button must be present');

      // Verify button is visible and within viewport
      final buttonRect = tester.getRect(addButton);
      final screenSize =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(buttonRect.left, greaterThanOrEqualTo(0));
      expect(buttonRect.right, lessThanOrEqualTo(screenSize.width));
      expect(buttonRect.top, greaterThanOrEqualTo(0));
      expect(buttonRect.bottom, lessThanOrEqualTo(screenSize.height));

      // At the constrained size, stats intentionally move below the mode
      // selector instead of competing for horizontal space.
      final modeSelectorRect = tester.getRect(find.text('随机'));
      final streakIconRect = tester.getRect(
        find.byIcon(Icons.local_fire_department),
      );
      expect(streakIconRect.top, greaterThan(modeSelectorRect.bottom));
    });

    testWidgets('maintains left-right hierarchy at normal width',
        (tester) async {
      // Normal width (540 logical px)
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0; // 540 logical px width
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testStats = UserStats(
        streak: 7,
        xp: 1250,
        hearts: 3,
        maxHearts: 5,
        todayXp: 50,
        dailyGoal: 100,
        lastStudyDate: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsProvider
                .overrideWith((ref) => _FakeUserStatsNotifier(testStats)),
            learningModeProvider.overrideWith((ref) => LearningModeNotifier()),
            verifiedQuestionsProvider.overrideWith((ref) async => []),
            deckListProvider.overrideWith((ref) async => []),
            todayReviewQueueProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find mode selector and stats
      final modeSelector = find.text('随机模式');
      final streakIcon = find.byIcon(Icons.local_fire_department);

      expect(modeSelector, findsOneWidget);
      expect(streakIcon, findsOneWidget);

      // Get their positions
      final modeSelectorRect = tester.getRect(modeSelector);
      final streakIconRect = tester.getRect(streakIcon);

      // At normal width, stats should be substantially to the right of mode selector
      expect(streakIconRect.left, greaterThan(modeSelectorRect.right + 50),
          reason:
              'Stats should be right-aligned with significant spacing from mode selector at normal width');
    });
  });
}

List<ReviewQueueItem> _reviewItems() => List.generate(3, (point) {
      final now = DateTime(2026, 9, 9);
      return ReviewQueueItem(
        knowledgePoint: KnowledgePoint(
          id: 'review-point-$point',
          title: '检查点恢复与工具执行结果核验 $point',
          summary: 'Synthetic review topic',
          createdAt: now,
          updatedAt: now,
        ),
        questions: List.generate(4, (index) {
          final number = point * 4 + index;
          return Question(
            id: 'review-question-$number',
            deckId: 'review-deck',
            knowledgePointId: 'review-point-$point',
            type: QuestionType.multipleChoice,
            content: 'Review fixture question $number',
            options: const ['First answer', 'Second answer'],
            answer: 'First answer',
            sourceStatus: SourceStatus.verified,
          );
        }),
        overdueCount: 0,
        priority: 1,
      );
    });

class _FakeReviewScheduler extends Fake implements ReviewSchedulerService {
  final requestedLimits = <int>[];

  @override
  Future<List<Question>> getTodayReviewQuestions(
      {DateTime? now, int limit = 10}) async {
    requestedLimits.add(limit);
    return _reviewItems().expand((item) => item.questions).take(limit).toList();
  }
}

Future<void> _pumpReviewHome(
  WidgetTester tester, {
  Size size = const Size(320, 740),
  double scale = 2.0,
  _FakeReviewScheduler? reviews,
  Future<List<ReviewQueueItem>> Function()? queue,
}) async {
  SharedPreferences.setMockInitialValues({'learning_mode': 1});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userStatsProvider.overrideWith((ref) => _FakeUserStatsNotifier(UserStats(
            xp: 10000,
            todayXp: 10,
            lastStudyDate: DateTime(2026, 9, 9),
          ))),
      verifiedQuestionsProvider.overrideWith((ref) async => []),
      deckListProvider.overrideWith((ref) async => []),
      todayReviewQueueProvider
          .overrideWith((ref) => queue?.call() ?? Future.value(_reviewItems())),
      reviewSchedulerServiceProvider
          .overrideWithValue(reviews ?? _FakeReviewScheduler()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const HomeScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}
