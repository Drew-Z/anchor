import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_base_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

final _bulkButton = find.byKey(const ValueKey('bulk_verify_pending_questions'));
final _confirmButton = find.widgetWithText(ElevatedButton, '确认批量核验');

void main() {
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

  for (final failWrite in [false, true]) {
    testWidgets('started bulk write settles after exit: failure=$failWrite',
        (tester) async {
      final harness = _Harness();
      final gate = Completer<void>();
      harness.onWrite = (_) => gate.future;
      await _pumpLibrary(tester, harness);
      await _confirm(tester);
      expect(harness.batches, hasLength(1));
      harness.navigator.currentState!.pop();
      await tester.pumpAndSettle();

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
        home: const Scaffold(body: Text('Neutral route')),
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
  final navigator = GlobalKey<NavigatorState>();
  final database = _BlockedDatabase();
  final loads = <String>[];
  final batches = <List<Question>>[];
  final listReads = [0, 0, 0, 0];
  int completedWrites = 0;
  Future<SourceChunk?> Function(String)? onRead;
  Future<void> Function(List<Question>)? onWrite;
  List<Question> questions = [
    Question(
      id: 'eligible',
      deckId: 'bulk-deck',
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
        Future.value(id == 'first' ? _chunk : null);
  }
}

class _Questions extends Fake implements QuestionRepository {
  final _Harness harness;
  _Questions(this.harness);

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
