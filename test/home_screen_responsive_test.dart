import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/features/home/home_screen.dart';
import 'package:anchor_learning/services/gamification_service.dart';
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
  group('HomeScreen responsive layout', () {
    testWidgets('renders without overflow at 320px width and 2.0 text scale',
        (tester) async {
      // Set up narrow width (320 logical px) and large text scale (2.0)
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 540 / 200.0; // 320 logical px width
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
            userStatsProvider.overrideWith(
                (ref) => _FakeUserStatsNotifier(testStats)),
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
      expect(tester.takeException(), isNull,
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
            userStatsProvider.overrideWith(
                (ref) => _FakeUserStatsNotifier(testStats)),
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
