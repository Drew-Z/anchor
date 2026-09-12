import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/grounded_learning_context.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_answer_evidence_quality_badges.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_base_screen.dart';
import 'package:anchor_learning/services/agent/knowledge_answer_session_summary.dart';
import 'package:anchor_learning/services/agent/hybrid_knowledge_search_service.dart';
import 'package:anchor_learning/services/agent/knowledge_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final layout in [
    (name: 'ordinary', size: const Size(390, 844), scale: 1.0),
    (name: 'short large text', size: const Size(320, 420), scale: 2.0),
  ]) {
    for (final tab in [
      (index: 1, label: '来源', empty: '暂无来源'),
      (index: 2, label: '知识点', empty: '暂无知识点'),
      (index: 3, label: '题目', empty: '暂无题目'),
      (index: 4, label: '待核验', empty: '暂无待核验内容'),
    ]) {
      testWidgets('${tab.label} empty state is reachable at ${layout.name}',
          (tester) async {
        await _pumpLibrary(
          tester,
          tabIndex: tab.index,
          size: layout.size,
          textScale: layout.scale,
        );
        expect(tester.takeException(), isNull);

        if (layout.scale > 1) {
          await tester.drag(
            find.byType(KnowledgeBaseScreen),
            const Offset(0, -280),
          );
          await tester.pumpAndSettle();
        }

        final empty = find.text(tab.empty);
        expect(empty.hitTestable(), findsOneWidget);
        final safeViewport = Rect.fromLTWH(
          0,
          24,
          layout.size.width,
          layout.size.height - 48,
        );
        final textBounds = tester.getRect(empty);
        expect(safeViewport.contains(textBounds.topLeft), isTrue);
        expect(safeViewport.contains(textBounds.bottomRight), isTrue);
        final currentTab = find.widgetWithText(Tab, tab.label);
        expect(currentTab.hitTestable(), findsOneWidget);
        expect(
          DefaultTabController.of(tester.element(currentTab)).index,
          tab.index,
        );
        if (tab.index == 1) {
          expect(find.text('导入来源').hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('short library keeps tabs usable after the header scrolls',
      (tester) async {
    await _pumpLibrary(
      tester,
      tabIndex: 2,
      size: const Size(320, 420),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(KnowledgeBaseScreen),
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();
    final finalTab = find.widgetWithText(Tab, '待核验');
    await tester.ensureVisible(finalTab);
    await tester.pumpAndSettle();
    await tester.tap(finalTab);
    await tester.pumpAndSettle();

    expect(DefaultTabController.of(tester.element(finalTab)).index, 4);
    expect(find.text('暂无待核验内容').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final initialTab in [0, 2]) {
    testWidgets(
        'short search is reachable with an expanded header from tab $initialTab',
        (tester) async {
      await _pumpLibrary(
        tester,
        tabIndex: initialTab,
        size: const Size(320, 420),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);

      if (initialTab != 0) {
        await tester.drag(find.byType(TabBar), const Offset(280, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(Tab, '检索'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.drag(
        find.byType(KnowledgeBaseScreen),
        const Offset(0, -280),
      );
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('knowledge-search-input'));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      expect(input.hitTestable(), findsOneWidget);
      final empty = find.text('输入关键词检索知识库');
      await tester.ensureVisible(empty);
      await tester.pumpAndSettle();
      expect(empty.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('short search keeps failure retry and clear controls reachable',
      (tester) async {
    var reads = 0;
    await _pumpLibrary(
      tester,
      tabIndex: 0,
      size: const Size(320, 420),
      textScale: 2,
      searchQuery: 'synthetic',
      searchResults: () async {
        if (++reads == 1) throw StateError('synthetic_search_failure');
        return const [];
      },
    );
    expect(tester.takeException(), isNull);

    final retry = find.text('重试检索');
    expect(reads, 1);
    await tester.dragUntilVisible(
      retry,
      find.byType(KnowledgeBaseScreen),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();
    expect(retry.hitTestable(), findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.text('没有匹配结果'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final clear = find.byTooltip('清空');
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    expect(clear.hitTestable(), findsOneWidget);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('输入关键词检索知识库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final layout in [
    (name: 'ordinary', size: const Size(390, 844), scale: 1.0),
    (name: 'short large text', size: const Size(320, 420), scale: 2.0),
  ]) {
    testWidgets('empty tab transitions keep scrolling at ${layout.name}',
        (tester) async {
      await _pumpLibrary(
        tester,
        tabIndex: 2,
        size: layout.size,
        textScale: layout.scale,
      );

      for (final tab in ['来源', '题目', '待核验', '知识点']) {
        final tabFinder = find.widgetWithText(Tab, tab);
        await tester.ensureVisible(tabFinder);
        await tester.pumpAndSettle();
        await tester.tap(tabFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final gesture = await tester.startGesture(
          Offset(layout.size.width * 0.65, layout.size.height * 0.78),
        );
        for (var frame = 0; frame < 12; frame++) {
          await gesture.moveBy(Offset(0, -layout.size.height * 0.04));
          await tester.pump(const Duration(milliseconds: 33));
        }
        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(tab == '待核验' ? '暂无待核验内容' : '暂无$tab').hitTestable(),
            findsOneWidget);
      }

      await tester.fling(
        find.byType(TabBarView),
        Offset(-layout.size.width * 0.8, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect(
        DefaultTabController.of(tester.element(find.byType(TabBarView))).index,
        3,
      );
      await tester.drag(find.byType(TabBarView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.text('暂无题目').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final textScale in [1.0, 2.0]) {
    for (final quality in [
      (disposition: GroundingDisposition.legacy, label: '历史记录未审计'),
      (disposition: GroundingDisposition.partial, label: '部分主张未支持'),
      (disposition: GroundingDisposition.refused, label: '证据不足已拒答'),
    ]) {
      testWidgets('quality badges wrap ${quality.label} at ${textScale}x',
          (tester) async {
        final record = KnowledgeAnswerSessionSummaryRecord.fromFields(
          question: 'Synthetic question',
          groundingDisposition: quality.disposition,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 140,
                  child: KnowledgeAnswerEvidenceQualityBadges(record: record),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final badgeBounds = tester.getRect(
          find.byType(KnowledgeAnswerEvidenceQualityBadges),
        );
        for (final label in knowledgeAnswerEvidenceQualityLabels(record)) {
          final text = find.text(label);
          expect(text.hitTestable(), findsOneWidget);
          final textBounds = tester.getRect(text);
          expect(badgeBounds.contains(textBounds.topLeft), isTrue);
          expect(badgeBounds.contains(textBounds.bottomRight), isTrue);
        }
        if (textScale > 1) {
          expect(
            tester.getSize(find.text(quality.label)).height,
            greaterThan(22),
          );
        }
      });
    }
  }
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  required int tabIndex,
  required Size size,
  required double textScale,
  String? searchQuery,
  Future<List<KnowledgeSearchResult>> Function()? searchResults,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sourceListProvider.overrideWith((ref) async => const []),
        knowledgePointListProvider.overrideWith((ref) async => const []),
        allQuestionsProvider.overrideWith((ref) async => const []),
        pendingQuestionListProvider.overrideWith((ref) async => const []),
        knowledgeAnswerSessionListProvider
            .overrideWith((ref) async => const []),
        if (searchQuery != null) ...[
          knowledgeSearchResultsProvider(searchQuery).overrideWith(
            (ref) => searchResults!(),
          ),
          knowledgeHybridSearchReportProvider(searchQuery).overrideWith(
            (ref) async => HybridKnowledgeSearchReport(
              originalQuery: searchQuery,
              variants: const [],
              results: const [],
              status: HybridKnowledgeSearchStatus.fallback,
            ),
          ),
          knowledgeAnswerGroundedContextProvider(searchQuery).overrideWith(
            (ref) async => GroundedLearningContext(
              targetId: searchQuery,
              surface: GroundedLearningSurface.knowledgeAnswer,
              items: const [],
            ),
          ),
        ],
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.symmetric(vertical: 24),
            viewPadding: const EdgeInsets.symmetric(vertical: 24),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: KnowledgeBaseScreen(
          initialTabIndex: tabIndex,
          initialSearchQuery: searchQuery,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
