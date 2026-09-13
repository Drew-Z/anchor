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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

Finder _status(SourceStatus status) =>
    find.widgetWithText(OutlinedButton, status.label);

void main() {
  for (final shortLarge in [false, true]) {
    for (final fail in [false, true]) {
      testWidgets('single save after back: short=$shortLarge failure=$fail',
          (tester) async {
        final harness = _Harness();
        final gate = Completer<void>();
        harness.onWrite = (_) => gate.future;
        await _pumpLibrary(tester, harness, shortLarge: shortLarge);
        await _openQuestion(tester, harness);
        await _save(tester, SourceStatus.verified);
        expect(harness.writes, hasLength(1));
        expect(harness.question.sourceStatus, SourceStatus.pending);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(QuestionEvidenceScreen), findsNothing);
        expect(find.widgetWithText(FilterChip, '待核验 1'), findsOneWidget);
        if (fail) {
          gate.completeError(StateError('synthetic late save failure'));
        } else {
          gate.complete();
        }
        await tester.pumpAndSettle();
        expect(harness.completedWrites, fail ? 0 : 1);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.widgetWithText(FilterChip, fail ? '待核验 1' : '已核验 1'),
            findsOneWidget);
        expect(
            harness.container
                .read(allQuestionsProvider)
                .requireValue
                .single
                .sourceStatus,
            fail ? SourceStatus.pending : SourceStatus.verified);
        expect(harness.container.read(pendingQuestionListProvider).requireValue,
            fail ? hasLength(1) : isEmpty);
        await _openQuestion(tester, harness);
        expect(find.text(fail ? '判断题 · 待核验' : '判断题 · 已核验'), findsOneWidget);
        expect(harness.writes, hasLength(1));
        expect(harness.database.opens, 0);
        expect(tester.takeException(), isNull);
      });
    }
    for (final status in SourceStatus.values) {
      testWidgets('single mounted save normalizes $status: short=$shortLarge',
          (tester) async {
        final harness = _Harness(
            initialStatus: status == SourceStatus.pending
                ? SourceStatus.verified
                : SourceStatus.pending);
        await _pumpLibrary(tester, harness, shortLarge: shortLarge);
        await _openQuestion(tester, harness);
        await _save(tester, status);
        await tester.pumpAndSettle();
        expect(harness.completedWrites, 1);
        expect(harness.writes.single.sourceStatus, status);
        expect(harness.writes.single.citationIds,
            status == SourceStatus.noSource ? isEmpty : ['first']);
        expect(find.text('已标记为${status.label}'), findsOneWidget);
        expect(
            harness.container
                .read(allQuestionsProvider)
                .requireValue
                .single
                .sourceStatus,
            status);
        await _reveal(tester, _status(status));
        expect(tester.widget<OutlinedButton>(_status(status)).onPressed,
            isNotNull);
        if (status == SourceStatus.noSource) {
          expect(
              tester
                  .widget<OutlinedButton>(_status(SourceStatus.verified))
                  .onPressed,
              isNull);
        }
        expect(harness.database.opens, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final fail in [false, true]) {
    testWidgets(
        'single started save settles after scope disposal: failure=$fail',
        (tester) async {
      final harness = _Harness();
      final gate = Completer<void>();
      harness.onWrite = (_) => gate.future;
      await _pumpLibrary(tester, harness);
      await _openQuestion(tester, harness);
      await _save(tester, SourceStatus.verified);
      final readsBeforeExit = harness.questionReads;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      if (fail) {
        gate.completeError(StateError('synthetic disposed-scope failure'));
      } else {
        gate.complete();
      }
      await tester.pumpAndSettle();
      expect(harness.writes, hasLength(1));
      expect(harness.completedWrites, fail ? 0 : 1);
      expect(harness.questionReads, readsBeforeExit);
      expect(find.byType(SnackBar), findsNothing);
      expect(harness.database.opens, 0);
      expect(tester.takeException(), isNull);
    });
  }
  for (final leaveDetail in [false, true]) {
    testWidgets('single save refreshes existing read models: back=$leaveDetail',
        (tester) async {
      final harness = _Harness();
      final gate = Completer<void>();
      harness.onWrite = (_) => gate.future;
      await _pumpLibrary(tester, harness);
      await _openQuestion(tester, harness);
      final container = harness.container;
      final oldKey = harness.question.citationIds.join('\x00');
      expect(await container.read(verifiedQuestionsProvider.future), isEmpty);
      await container.read(deckQuestionsProvider('single-deck').future);
      expect(
          await container
              .read(verifiedDeckQuestionsProvider('single-deck').future),
          isEmpty);
      await container.read(knowledgePointQuestionsProvider('point').future);
      await container.read(knowledgeSearchCorpusProvider.future);
      expect(
          await container.read(practiceableKnowledgePointListProvider.future),
          isEmpty);
      await container.read(todayReviewQueueProvider.future);
      await container.read(questionCitationChunksProvider('first').future);
      await container.read(questionCitationChunksProvider('unrelated').future);
      await container.read(deckQuestionsProvider('unrelated').future);
      await _save(tester, SourceStatus.verified);
      if (leaveDetail) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      harness.chunkContent = 'Fresh evidence after the saved update';
      gate.complete();
      await tester.pumpAndSettle();
      expect((await container.read(verifiedQuestionsProvider.future)).single.id,
          'single-question');
      expect(
          (await container.read(deckQuestionsProvider('single-deck').future))
              .single
              .sourceStatus,
          SourceStatus.verified);
      expect(
          (await container
                  .read(verifiedDeckQuestionsProvider('single-deck').future))
              .single
              .id,
          'single-question');
      expect(
          (await container
                  .read(knowledgePointQuestionsProvider('point').future))
              .single
              .sourceStatus,
          SourceStatus.verified);
      final corpus = await container.read(knowledgeSearchCorpusProvider.future);
      expect(corpus.questions.single.sourceStatus, SourceStatus.verified);
      expect(corpus.questions.single.citationIds, ['first']);
      expect(
          (await container.read(practiceableKnowledgePointListProvider.future))
              .single
              .id,
          'point');
      await container.read(todayReviewQueueProvider.future);
      expect(harness.reviewReads, 2);
      for (final key in [oldKey, 'first']) {
        expect(
            (await container.read(questionCitationChunksProvider(key).future))
                .map((chunk) => chunk.content),
            everyElement(harness.chunkContent));
      }
      await container.read(questionCitationChunksProvider('unrelated').future);
      await container.read(deckQuestionsProvider('unrelated').future);
      expect(harness.loads.where((id) => id == 'unrelated'), hasLength(1));
      expect(harness.deckReads['unrelated'], 1);
      expect(harness.completedWrites, 1);
      expect(harness.database.opens, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('single mounted save failure retries and blocks duplicate writes',
      (tester) async {
    final harness = _Harness();
    final gate = Completer<void>();
    harness.onWrite = (_) => gate.future;
    await _pumpLibrary(tester, harness);
    await _openQuestion(tester, harness);
    final action = _status(SourceStatus.verified);
    await _reveal(tester, action);
    await tester.tap(action);
    await tester.tap(action);
    await tester.pump();
    expect(harness.writes, hasLength(1));
    for (final status in SourceStatus.values) {
      expect(tester.widget<OutlinedButton>(_status(status)).onPressed, isNull);
    }
    final readsBeforeFailure = harness.questionReads;
    gate.completeError(StateError('synthetic save failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('保存失败:'), findsOneWidget);
    expect(harness.completedWrites, 0);
    expect(harness.questionReads, readsBeforeFailure);
    expect(harness.question.sourceStatus, SourceStatus.pending);
    expect(tester.widget<OutlinedButton>(action).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    harness.onWrite = null;
    await _save(tester, SourceStatus.verified);
    await tester.pumpAndSettle();
    expect(harness.writes, hasLength(2));
    expect(harness.completedWrites, 1);
    expect(harness.writes.last.citationIds, harness.writes.first.citationIds);
    expect(find.text('已标记为已核验'), findsOneWidget);
    expect(harness.database.opens, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'unreadable citations cannot verify and pending becomes no-source',
      (tester) async {
    final harness = _Harness(citationIds: const ['missing']);
    await _pumpLibrary(tester, harness);
    await _openQuestion(tester, harness);
    await _reveal(tester, _status(SourceStatus.verified));
    expect(
        tester.widget<OutlinedButton>(_status(SourceStatus.verified)).onPressed,
        isNull);
    expect(harness.writes, isEmpty);
    await _save(tester, SourceStatus.pending);
    await tester.pumpAndSettle();
    expect(harness.writes.single.sourceStatus, SourceStatus.noSource);
    expect(harness.writes.single.citationIds, isEmpty);
    expect(find.text('已标记为无来源'), findsOneWidget);
    expect(harness.database.opens, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final surface = find.byType(QuestionEvidenceScreen).evaluate().isNotEmpty
      ? find.byType(QuestionEvidenceScreen)
      : find.byType(KnowledgeBaseScreen);
  for (var i = 0; i < 35 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(surface, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _openQuestion(WidgetTester tester, _Harness harness) async {
  final row = find.text(harness.question.content);
  await _reveal(tester, row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.byType(QuestionEvidenceScreen), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _save(WidgetTester tester, SourceStatus status) async {
  final action = _status(status);
  await _reveal(tester, action);
  expect(tester.widget<OutlinedButton>(action).onPressed, isNotNull);
  await tester.tap(action);
  await tester.pump();
}

Future<void> _pumpLibrary(WidgetTester tester, _Harness harness,
    {bool shortLarge = false}) async {
  tester.view.physicalSize =
      shortLarge ? const Size(320, 420) : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(
            DatabaseHelper.forTesting(databaseFactory: harness.database)),
        questionRepositoryProvider.overrideWithValue(_Questions(harness)),
        sourceChunkRepositoryProvider.overrideWithValue(_Chunks(harness)),
        knowledgePointRepositoryProvider.overrideWithValue(_Points()),
        sourceListProvider.overrideWith((ref) async => const []),
        sourceProvider.overrideWith((ref, id) async => null),
        knowledgePointListProvider.overrideWith((ref) async => [_point]),
        knowledgePointProvider.overrideWith((ref, id) async => _point),
        allProgrammingExercisesProvider.overrideWith((ref) async => const []),
        knowledgeAnswerSessionListProvider
            .overrideWith((ref) async => const []),
        todayReviewQueueProvider.overrideWith((ref) async {
          harness.reviewReads++;
          return const [];
        }),
        openaiServiceProvider.overrideWith((ref) {
          throw StateError(
              'Model access is blocked in the single-save fixture');
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(shortLarge ? 2 : 1)),
            child: child!),
        home: const KnowledgeBaseScreen(initialTabIndex: 3),
      )));
  await tester.pumpAndSettle();
  harness.container = ProviderScope.containerOf(
      tester.element(find.byType(KnowledgeBaseScreen)));
  expect(harness.database.opens, 0);
  expect(tester.takeException(), isNull);
}

class _Harness {
  final database = _BlockedDatabase();
  final writes = <Question>[];
  final loads = <String>[];
  final deckReads = <String, int>{};
  late final ProviderContainer container;
  late Question question;
  int questionReads = 0;
  int reviewReads = 0;
  int completedWrites = 0;
  String chunkContent = 'Synthetic readable evidence';
  Future<void> Function(Question)? onWrite;
  _Harness(
      {SourceStatus initialStatus = SourceStatus.pending,
      List<String> citationIds = const ['first', 'missing', 'first']}) {
    question = Question(
        id: 'single-question',
        deckId: 'single-deck',
        knowledgePointId: 'point',
        type: QuestionType.trueFalse,
        content: '单题核验例题',
        answer: '对',
        sourceStatus: initialStatus,
        citationIds: citationIds);
  }
}

final _point = KnowledgePoint(
    id: 'point',
    title: '示例知识点',
    summary: '合成验收数据',
    createdAt: DateTime(2026, 9, 13),
    updatedAt: DateTime(2026, 9, 13));

class _Questions extends Fake implements QuestionRepository {
  final _Harness harness;
  _Questions(this.harness);
  @override
  Future<List<Question>> getAllQuestions() async {
    harness.questionReads++;
    return [harness.question];
  }

  @override
  Future<List<Question>> getQuestionsByDeck(String deckId) async {
    harness.deckReads.update(deckId, (count) => count + 1, ifAbsent: () => 1);
    harness.questionReads++;
    return deckId == harness.question.deckId ? [harness.question] : [];
  }

  @override
  Future<void> updateQuestion(Question question) async {
    harness.writes.add(question);
    await harness.onWrite?.call(question);
    harness.question = question;
    harness.completedWrites++;
  }
}

class _Chunks extends Fake implements SourceChunkRepository {
  final _Harness harness;
  _Chunks(this.harness);
  @override
  Future<SourceChunk?> getSourceChunk(String id) async {
    harness.loads.add(id);
    return id == 'first'
        ? SourceChunk(
            id: id,
            sourceId: 'single-source',
            chunkIndex: 0,
            content: harness.chunkContent,
            locator: 'fixture:1',
            contentHash: 'fixture-hash',
            createdAt: DateTime(2026, 9, 13))
        : null;
  }
}

class _Points extends Fake implements KnowledgePointRepository {
  @override
  Future<List<KnowledgePoint>> getAllKnowledgePoints() async => [_point];
}

class _BlockedDatabase extends Fake implements DatabaseFactory {
  int opens = 0;
  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions? options}) async {
    opens++;
    throw StateError('Database access is blocked in the single-save fixture');
  }
}
