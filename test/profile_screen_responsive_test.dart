import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/models/deck.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/features/profile/profile_screen.dart';
import 'package:anchor_learning/features/settings/about_screen.dart';
import 'package:anchor_learning/features/settings/settings_screen.dart';
import 'package:anchor_learning/services/ai/ai_api_protocol.dart';
import 'package:anchor_learning/services/ai/ai_model_acceptance.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _achievementTitles = [
  '连续3天',
  '连续7天',
  '连续30天',
  '连续100天',
  '初心者',
  '积少成多',
  '知识富翁',
  '勤学者',
  '学霸',
  '答题新手',
  '答题达人',
  '答题大师',
  '初次学习',
  '收集达人',
  '题库大师',
  '满分通关',
  '完美主义者',
  '月度全勤',
  '满月达人',
  '持之以恒',
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(320, 740), 2.0),
    (const Size(320, 600), 2.0),
  ]) {
    for (final complete in [false, true]) {
      testWidgets('complete profile labels at $size/$scale, goal=$complete',
          (tester) async {
        await _pumpProfile(tester, size, scale, complete: complete);
        expect(tester.takeException(), isNull);

        final amount = '${complete ? 75 : 10} / 50 XP';
        for (final text in [
          '每日目标',
          amount,
          if (complete) '今日目标已达成！',
          '月度打卡',
          '2 / 20 天',
          '成就',
          ..._achievementTitles,
        ]) {
          await _expectVisibleText(tester, text, size);
          expect(tester.takeException(), isNull, reason: text);
        }
        expect(
          tester.getRect(find.text('每日目标')).overlaps(
                tester.getRect(find.text(amount)),
              ),
          isFalse,
        );
        expect(find.text('6 / 20'), findsOneWidget);
      });
    }

    testWidgets('locked and unlocked descriptions fit at $size/$scale',
        (tester) async {
      await _pumpProfile(tester, size, scale);
      for (final (title, description, status) in [
        ('初次学习', '完成第一个题包', '已解锁'),
        ('连续100天', '坚持学习100天', '未解锁'),
      ]) {
        await tester.ensureVisible(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        final message = '$title - $description';
        for (final text in [message, status]) {
          _expectTextBounds(tester, find.text(text), size);
        }
        expect(
          tester.getRect(find.text(message)).overlaps(
                tester.getRect(find.text(status)),
              ),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }
    });
  }

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(320, 600), 2.0),
  ]) {
    testWidgets('profile menu remains reachable at $size/$scale',
        (tester) async {
      await _pumpProfile(tester, size, scale);
      for (final (title, screenType) in [
        ('设置', SettingsScreen),
        ('关于', AboutScreen),
      ]) {
        await _expectVisibleText(tester, title, size);
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.byType(screenType), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(screenType), findsNothing);
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}

Future<void> _expectVisibleText(
  WidgetTester tester,
  String text,
  Size size,
) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  _expectTextBounds(tester, finder, size);
}

void _expectTextBounds(WidgetTester tester, Finder finder, Size size) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse,
      reason: 'The complete label must be rendered: '
          '${paragraph.text.toPlainText()}');
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
  expect(rect.bottom, lessThanOrEqualTo(size.height));
}

Future<void> _pumpProfile(
  WidgetTester tester,
  Size size,
  double scale, {
  bool complete = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var databaseReads = 0;
  addTearDown(() => expect(databaseReads, 0));
  final now = DateTime.now();
  final stats = UserStats(
    xp: 120,
    streak: 3,
    hearts: 4,
    todayXp: complete ? 75 : 10,
    lastStudyDate: now,
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWith((ref) {
        databaseReads++;
        throw StateError('Profile fixture must not access a real database');
      }),
      gamificationServiceProvider.overrideWithValue(_MemoryGamification(stats)),
      deckListProvider.overrideWith((ref) async => [
            Deck(
              id: 'profile-deck',
              title: 'Synthetic profile deck',
              createdAt: now,
              updatedAt: now,
            ),
          ]),
      openaiServiceProvider.overrideWithValue(_ModelSettings()),
      aiModelAcceptanceStoreProvider.overrideWithValue(_AcceptanceStore()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const ProfileScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

class _MemoryGamification extends Fake implements GamificationService {
  final UserStats stats;

  _MemoryGamification(this.stats);

  @override
  Future<UserStats> getStats() async => stats;

  @override
  Future<List<String>> getMonthlyCheckInDates(int year, int month) async => [
        '$year-${month.toString().padLeft(2, '0')}-01',
        '$year-${month.toString().padLeft(2, '0')}-02',
      ];

  @override
  Future<List<({int year, int month})>> getEarnedMedals() async =>
      [(year: 2026, month: 8)];

  @override
  Future<int> getTotalCorrect() async => 120;

  @override
  Future<int> getPerfectCount() async => 3;
}

class _ModelSettings extends Fake implements OpenAIService {
  @override
  Future<String> getProviderId() async => 'openai';

  @override
  Future<String> getModelForProvider(String providerId) async => 'gpt-4o-mini';

  @override
  Future<String> getBaseUrlForProvider(String providerId) async =>
      'https://example.invalid/v1';

  @override
  Future<AiApiProtocol> getApiProtocolForProvider(String providerId) async =>
      AiApiProtocol.chatCompletions;

  @override
  Future<bool> hasApiKey({String? providerId}) async => false;
}

class _AcceptanceStore extends Fake implements AiModelAcceptanceStore {
  @override
  Future<AiModelAcceptanceReport?> latestFor(
    AiModelConfiguration configuration,
  ) async =>
      null;
}
