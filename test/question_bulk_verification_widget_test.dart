import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_base_screen.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

final _bulkButton = find.byKey(const ValueKey('bulk_verify_pending_questions'));
final _confirmButton = find.widgetWithText(ElevatedButton, '确认批量核验');

void main() {
  for (final shortLarge in [false, true]) {
    for (final failWrite in [false, true]) {
      testWidgets(
          'bulk save refreshes reopened library: short=$shortLarge failure=$failWrite',
          (tester) async {
        final harness = _Harness();
        final gate = Completer<void>();
        harness.onWrite = (_) => gate.future;
        await _pumpLibrary(
          tester,
          harness,
          size: shortLarge ? const Size(320, 420) : const Size(390, 844),
          textScale: shortLarge ? 2 : 1,
        );
        final container = ProviderScope.containerOf(
            tester.element(find.byType(KnowledgeBaseScreen)));
        await _confirm(tester);
        expect(harness.batches, hasLength(1));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Neutral route'), findsOneWidget);
        if (failWrite) {
          gate.completeError(StateError('synthetic late batch failure'));
        } else {
          gate.complete();
        }
        await tester.pumpAndSettle();
        expect(harness.completedWrites, failWrite ? 0 : 1);
        expect(find.byType(SnackBar), findsNothing);
        harness.navigator.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => const KnowledgeBaseScreen(initialTabIndex: 3),
        ));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilterChip, failWrite ? '待核验 2' : '已核验 1'),
            findsOneWidget);
        expect(
            container
                .read(pendingQuestionListProvider)
                .requireValue
                .map((question) => question.id),
            failWrite ? ['eligible', 'missing'] : ['missing']);
        final saved = container
            .read(allQuestionsProvider)
            .requireValue
            .firstWhere((question) => question.id == 'eligible');
        expect(saved.sourceStatus,
            failWrite ? SourceStatus.pending : SourceStatus.verified);
        expect(saved.citationIds,
            failWrite ? ['first', 'missing', 'first'] : ['first']);
        expect(harness.batches, hasLength(1));
        expect(harness.database.opens, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final shortLarge in [false, true]) {
    testWidgets(
        'bulk confirmation remains readable and actionable: short=$shortLarge',
        (tester) async {
      final harness = _Harness();
      await _pumpLibrary(
        tester,
        harness,
        size: shortLarge ? const Size(320, 420) : const Size(390, 844),
        textScale: shortLarge ? 2 : 1,
      );
      await _start(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _readConfirmation(tester);
      expect(harness.loads, ['first', 'missing']);
      expect(harness.batches, isEmpty);
      final cancel = find.widgetWithText(TextButton, '取消');
      expect(cancel.hitTestable(), findsOneWidget);
      expect(_confirmButton.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(harness.batches, isEmpty);
      expect(harness.listReads, [1, 1, 1, 1]);

      await _start(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _readConfirmation(tester);
      await tester.tap(_confirmButton);
      await tester.pumpAndSettle();
      expect(harness.completedWrites, 1);
      expect(harness.batches.single.single.id, 'eligible');
      expect(harness.batches.single.single.citationIds, ['first']);
      expect(harness.questions.first.sourceStatus, SourceStatus.verified);
      expect(harness.questions.last.sourceStatus, SourceStatus.pending);
      expect(harness.listReads, [1, 1, 2, 2]);
      expect(harness.database.opens, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final leaveLibrary in [false, true]) {
    testWidgets('bulk save refreshes existing read models: back=$leaveLibrary',
        (tester) async {
      final harness = _Harness(watchListsOnHome: true);
      final gate = Completer<void>();
      harness.onWrite = (_) => gate.future;
      await _pumpLibrary(tester, harness);
      final container = ProviderScope.containerOf(
          tester.element(find.byType(KnowledgeBaseScreen)));
      final oldKey = harness.questions.first.citationIds.join('\x00');
      expect(await container.read(verifiedQuestionsProvider.future), isEmpty);
      await container.read(deckQuestionsProvider('bulk-deck').future);
      expect(
          await container
              .read(verifiedDeckQuestionsProvider('bulk-deck').future),
          isEmpty);
      await container
          .read(knowledgePointQuestionsProvider('bulk-point').future);
      await container.read(knowledgeSearchCorpusProvider.future);
      expect(
          await container.read(practiceableKnowledgePointListProvider.future),
          isEmpty);
      await container.read(todayReviewQueueProvider.future);
      for (final key in [oldKey, 'first', 'unrelated']) {
        await container.read(questionCitationChunksProvider(key).future);
      }
      await container.read(deckQuestionsProvider('unrelated').future);
      final goals = LearningAgentGoal.values.take(2).toList();
      for (final goal in goals) {
        await container.read(learningAgentPlanProvider(goal).future);
        expect(harness.planReads[goal], 1);
      }
      await _confirm(tester);
      if (leaveLibrary) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Verified 0, pending 2'), findsOneWidget);
      }
      harness.chunkContent = 'Fresh batch evidence';
      gate.complete();
      await tester.pumpAndSettle();
      if (leaveLibrary) {
        expect(find.text('Verified 1, pending 1'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      }
      expect((await container.read(verifiedQuestionsProvider.future)).single.id,
          'eligible');
      expect(
          (await container.read(deckQuestionsProvider('bulk-deck').future))
              .first
              .sourceStatus,
          SourceStatus.verified);
      expect(
          (await container
                  .read(verifiedDeckQuestionsProvider('bulk-deck').future))
              .single
              .id,
          'eligible');
      expect(
          (await container
                  .read(knowledgePointQuestionsProvider('bulk-point').future))
              .single
              .sourceStatus,
          SourceStatus.verified);
      final corpus = await container.read(knowledgeSearchCorpusProvider.future);
      expect(corpus.questions.first.sourceStatus, SourceStatus.verified);
      expect(corpus.questions.first.citationIds, ['first']);
      expect(
          (await container.read(practiceableKnowledgePointListProvider.future))
              .single
              .id,
          'bulk-point');
      await container.read(todayReviewQueueProvider.future);
      expect(harness.reviewReads, 2);
      for (final key in [oldKey, 'first']) {
        expect(
            (await container.read(questionCitationChunksProvider(key).future))
                .map((chunk) => chunk.content),
            everyElement(harness.chunkContent));
      }
      for (final goal in goals) {
        await container.read(learningAgentPlanProvider(goal).future);
        expect(harness.planReads[goal], 2);
      }
      await container.read(questionCitationChunksProvider('unrelated').future);
      await container.read(deckQuestionsProvider('unrelated').future);
      expect(harness.loads.where((id) => id == 'unrelated'), hasLength(1));
      expect(harness.deckReads['unrelated'], 1);
      expect(harness.listReads, [1, 1, 2, 2]);
      expect(harness.completedWrites, 1);
      expect(harness.batches, hasLength(1));
      expect(harness.database.opens, 0);
      expect(harness.modelAccesses, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final disposeScope in [false, true]) {
    for (final failRead in [false, true]) {
      testWidgets(
          'bulk read stops after exit: scope=$disposeScope failure=$failRead',
          (tester) async {
        final harness = _Harness();
        final gate = Completer<SourceChunk?>();
        harness.onRead =
            (id) => id == 'first' ? gate.future : Future.value(null);
        await _pumpLibrary(tester, harness);
        await _start(tester);
        expect(harness.loads, ['first']);
        expect(tester.widget<OutlinedButton>(_bulkButton).onPressed, isNull);

        if (disposeScope) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        } else {
          harness.navigator.currentState!.pop();
          await tester.pumpAndSettle();
        }
        if (failRead) {
          gate.completeError(StateError('synthetic late citation failure'));
        } else {
          gate.complete(_chunk);
        }
        await tester.pumpAndSettle();

        expect(harness.loads, ['first']);
        expect(harness.batches, isEmpty);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(harness.listReads, [1, 1, 1, 1]);
        expect(harness.database.opens, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('bulk read failure retries and cancellation writes nothing',
      (tester) async {
    final harness = _Harness();
    final gate = Completer<SourceChunk?>();
    harness.onRead = (_) => gate.future;
    await _pumpLibrary(tester, harness);
    await _start(tester);
    await tester.tap(_bulkButton);
    await tester.pump();
    expect(harness.loads, ['first']);
    expect(harness.batches, isEmpty);

    gate.completeError(StateError('synthetic citation failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('批量核验失败:'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(_bulkButton).onPressed, isNotNull);

    harness.onRead = null;
    await _start(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('批量确认来源核验？'), findsOneWidget);
    expect(harness.loads, ['first', 'first', 'missing']);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(harness.batches, isEmpty);
    expect(harness.listReads, [1, 1, 1, 1]);
    expect(tester.widget<OutlinedButton>(_bulkButton).onPressed, isNotNull);
    expect(harness.database.opens, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk verification with no readable citations stays pending',
      (tester) async {
    final harness = _Harness()..onRead = (_) async => null;
    await _pumpLibrary(tester, harness);
    await _start(tester);
    await tester.pumpAndSettle();
    expect(find.text('没有引用片段仍可读取的待核验题目'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(harness.loads, ['first', 'missing']);
    expect(harness.batches, isEmpty);
    expect(harness.questions.map((question) => question.sourceStatus),
        everyElement(SourceStatus.pending));
    expect(tester.widget<OutlinedButton>(_bulkButton).onPressed, isNotNull);
    expect(harness.database.opens, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk write failure retries the unchanged plan and refreshes',
      (tester) async {
    final harness = _Harness();
    final gate = Completer<void>();
    harness.onWrite = (_) => gate.future;
    await _pumpLibrary(tester, harness);
    await _confirm(tester);
    expect(harness.batches, hasLength(1));
    final update = harness.batches.single.single;
    expect(update.id, 'eligible');
    expect(update.sourceStatus, SourceStatus.verified);
    expect(update.citationIds, ['first']);
    expect(tester.widget<OutlinedButton>(_bulkButton).onPressed, isNull);
    await tester.tap(_bulkButton);
    await tester.pump();
    expect(harness.batches, hasLength(1));

    gate.completeError(StateError('synthetic write failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('批量核验失败:'), findsOneWidget);
    expect(harness.completedWrites, 0);
    expect(harness.listReads, [1, 1, 1, 1]);
    expect(tester.widget<OutlinedButton>(_bulkButton).onPressed, isNotNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    harness.onWrite = null;
    await _confirm(tester);
    await tester.pumpAndSettle();
    expect(harness.batches, hasLength(2));
    expect(harness.completedWrites, 1);
    expect(harness.batches.last.single.id, update.id);
    expect(harness.batches.last.single.citationIds, update.citationIds);
    expect(harness.questions.first.sourceStatus, SourceStatus.verified);
    expect(harness.questions.last.sourceStatus, SourceStatus.pending);
    expect(harness.listReads, [1, 1, 2, 2]);
    expect(find.text('已批量核验 1 道题，1 道仍需单独处理'), findsOneWidget);
    expect(harness.database.opens, 0);
    expect(tester.takeException(), isNull);
  });

  for (final disposeScope in [false, true]) {
    for (final failWrite in [false, true]) {
      testWidgets(
          'started bulk write settles after exit: scope=$disposeScope failure=$failWrite',
          (tester) async {
        final harness = _Harness();
        final gate = Completer<void>();
        harness.onWrite = (_) => gate.future;
        await _pumpLibrary(tester, harness);
        await _confirm(tester);
        expect(harness.batches, hasLength(1));
        if (disposeScope) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        } else {
          harness.navigator.currentState!.pop();
          await tester.pumpAndSettle();
        }

        if (failWrite) {
          gate.completeError(StateError('synthetic late write failure'));
        } else {
          gate.complete();
        }
        await tester.pumpAndSettle();
        expect(harness.batches, hasLength(1));
        expect(harness.completedWrites, failWrite ? 0 : 1);
        expect(harness.listReads, [1, 1, 1, 1]);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(harness.database.opens, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _start(WidgetTester tester) async {
  if (_bulkButton.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(_bulkButton);
    await tester.pumpAndSettle();
  }
  await tester.tap(_bulkButton);
  await tester.pump();
}

Future<void> _confirm(WidgetTester tester) async {
  await _start(tester);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.tap(_confirmButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _readConfirmation(WidgetTester tester) async {
  final body = find.textContaining('请确认你已经抽查题干、答案和解释');
  expect(body, findsOneWidget);
  final text = tester.widget<Text>(body).data!;
  final paragraph = tester.renderObject<RenderParagraph>(body);

  Rect readingViewport() {
    var visible = tester.getRect(find.byType(AlertDialog)).intersect(
          paragraph.localToGlobal(Offset.zero) & paragraph.size,
        );
    RenderObject? parent = paragraph.parent;
    while (parent != null) {
      if (parent is RenderAbstractViewport && parent is RenderBox) {
        final viewport = parent as RenderBox;
        visible = visible.intersect(
          viewport.localToGlobal(Offset.zero) & viewport.size,
        );
      }
      parent = parent.parent;
    }
    return visible;
  }

  for (final offset in [0, text.length - 1]) {
    Rect glyphBounds() {
      final box = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: offset, extentOffset: offset + 1),
          )
          .single
          .toRect();
      return box.shift(paragraph.localToGlobal(Offset.zero));
    }

    bool readable() {
      final glyph = glyphBounds();
      final viewport = readingViewport();
      return viewport.contains(glyph.topLeft + const Offset(0.5, 0.5)) &&
          viewport.contains(glyph.bottomRight - const Offset(0.5, 0.5)) &&
          tester
              .hitTestOnBinding(glyph.center)
              .path
              .any((entry) => identical(entry.target, paragraph));
    }

    for (var attempt = 0; attempt < 30 && !readable(); attempt++) {
      final viewport = readingViewport();
      if (viewport.isEmpty) break;
      final scrollDown = glyphBounds().bottom > viewport.bottom;
      await tester.timedDragFrom(
        Offset(viewport.center.dx,
            scrollDown ? viewport.bottom - 8 : viewport.top + 8),
        Offset(0, viewport.height * (scrollDown ? -0.6 : 0.6)),
        const Duration(milliseconds: 300),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(readable(), isTrue,
        reason: 'Confirmation text at offset $offset must be readable; '
            'paragraph=${paragraph.size}, viewport=${readingViewport()}, '
            'glyph=${glyphBounds()}');
  }
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  _Harness harness, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(
          DatabaseHelper.forTesting(databaseFactory: harness.database),
        ),
        sourceChunkRepositoryProvider.overrideWithValue(_Chunks(harness)),
        questionRepositoryProvider.overrideWithValue(_Questions(harness)),
        knowledgePointRepositoryProvider.overrideWithValue(_Points()),
        allProgrammingExercisesProvider.overrideWith((ref) async => const []),
        todayReviewQueueProvider.overrideWith((ref) async {
          harness.reviewReads++;
          return const [];
        }),
        learningAgentPlanProvider.overrideWith((ref, goal) async {
          harness.planReads
              .update(goal, (count) => count + 1, ifAbsent: () => 1);
          return const LearningAgentPlannerService().buildPlan(
            goal: goal,
            evidenceBackedPoints: const [],
            practiceablePoints: const [],
            practiceTargets: const [],
            pendingQuestions: const [],
          );
        }),
        openaiServiceProvider.overrideWith((ref) {
          harness.modelAccesses++;
          throw StateError('Model access is blocked in the bulk fixture');
        }),
        sourceListProvider.overrideWith((ref) async {
          harness.listReads[0]++;
          return const [];
        }),
        knowledgePointListProvider.overrideWith((ref) async {
          harness.listReads[1]++;
          return const [];
        }),
        allQuestionsProvider.overrideWith((ref) async {
          harness.listReads[2]++;
          return List.of(harness.questions);
        }),
        pendingQuestionListProvider.overrideWith((ref) async {
          harness.listReads[3]++;
          return harness.questions
              .where(
                  (question) => question.sourceStatus == SourceStatus.pending)
              .toList();
        }),
        knowledgeAnswerSessionListProvider
            .overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        navigatorKey: harness.navigator,
        home: harness.watchListsOnHome
            ? const _ListSnapshot()
            : const Scaffold(body: Text('Neutral route')),
      ),
    ),
  );
  harness.navigator.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => const KnowledgeBaseScreen(initialTabIndex: 4),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _Harness {
  final bool watchListsOnHome;
  _Harness({this.watchListsOnHome = false});

  final navigator = GlobalKey<NavigatorState>();
  final database = _BlockedDatabase();
  final loads = <String>[];
  final batches = <List<Question>>[];
  final listReads = [0, 0, 0, 0];
  final deckReads = <String, int>{};
  final planReads = <LearningAgentGoal, int>{};
  int reviewReads = 0;
  int modelAccesses = 0;
  String chunkContent = 'Synthetic readable evidence';
  int completedWrites = 0;
  Future<SourceChunk?> Function(String)? onRead;
  Future<void> Function(List<Question>)? onWrite;
  List<Question> questions = [
    Question(
      id: 'eligible',
      deckId: 'bulk-deck',
      knowledgePointId: 'bulk-point',
      type: QuestionType.trueFalse,
      content: '待核验例题',
      answer: '对',
      sourceStatus: SourceStatus.pending,
      citationIds: const ['first', 'missing', 'first'],
    ),
    Question(
      id: 'missing',
      deckId: 'bulk-deck',
      type: QuestionType.trueFalse,
      content: '缺失引用例题',
      answer: '对',
      sourceStatus: SourceStatus.pending,
      citationIds: const ['missing'],
    ),
  ];
}

final _chunk = SourceChunk(
  id: 'first',
  sourceId: 'bulk-source',
  chunkIndex: 0,
  content: 'Synthetic readable evidence',
  locator: 'fixture:1',
  contentHash: 'fixture-hash',
  createdAt: DateTime(2026, 9, 13),
);

class _Chunks extends Fake implements SourceChunkRepository {
  final _Harness harness;
  _Chunks(this.harness);

  @override
  Future<SourceChunk?> getSourceChunk(String id) {
    harness.loads.add(id);
    return harness.onRead?.call(id) ??
        Future.value(id == 'first'
            ? _chunk.copyWith(content: harness.chunkContent)
            : null);
  }
}

class _Questions extends Fake implements QuestionRepository {
  final _Harness harness;
  _Questions(this.harness);

  @override
  Future<List<Question>> getAllQuestions() async => List.of(harness.questions);

  @override
  Future<List<Question>> getQuestionsByDeck(String deckId) async {
    harness.deckReads.update(deckId, (count) => count + 1, ifAbsent: () => 1);
    return harness.questions
        .where((question) => question.deckId == deckId)
        .toList();
  }

  @override
  Future<void> updateQuestions(List<Question> questions) async {
    harness.batches.add(List.of(questions));
    await harness.onWrite?.call(questions);
    final updates = {for (final question in questions) question.id: question};
    harness.questions = [
      for (final question in harness.questions)
        updates[question.id] ?? question,
    ];
    harness.completedWrites++;
  }
}

class _BlockedDatabase extends Fake implements DatabaseFactory {
  int opens = 0;

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions? options}) async {
    opens++;
    throw StateError(
        'Database access is blocked in the bulk-verification fixture');
  }
}

final _point = KnowledgePoint(
  id: 'bulk-point',
  title: '批量核验知识点',
  summary: 'Synthetic batch evidence',
  createdAt: DateTime(2026, 9, 14),
  updatedAt: DateTime(2026, 9, 14),
);

class _Points extends Fake implements KnowledgePointRepository {
  @override
  Future<List<KnowledgePoint>> getAllKnowledgePoints() async => [_point];
}

class _ListSnapshot extends ConsumerWidget {
  const _ListSnapshot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(allQuestionsProvider).valueOrNull ?? [];
    final pending = ref.watch(pendingQuestionListProvider).valueOrNull ?? [];
    final verified = questions
        .where((question) => question.sourceStatus == SourceStatus.verified)
        .length;
    return Scaffold(
        body: Text('Verified $verified, pending ${pending.length}'));
  }
}
