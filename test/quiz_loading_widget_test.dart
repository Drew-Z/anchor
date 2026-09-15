import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_library_error_state.dart';
import 'package:anchor_learning/features/learning/quiz_screen.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('failed question read can retry and retains verified filtering',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    harness.repository.reads.single
        .completeError(StateError('Synthetic read failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(KnowledgeLibraryErrorState), findsOneWidget);
    await tester.tap(find.text('重试读取题目'));
    await tester.pump();
    expect(harness.repository.deckIds, ['quiz-deck', 'quiz-deck']);
    expect(find.byType(KnowledgeLibraryErrorState), findsNothing);
    harness.repository.reads.last.complete([
      _question('pending', SourceStatus.pending),
      _question('verified', SourceStatus.verified),
      _question('no-source', SourceStatus.noSource),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Question verified'), findsOneWidget);
    expect(find.text('Question pending'), findsNothing);
    expect(find.text('Question no-source'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets(
        'question read ${fails ? 'failure' : 'success'} after exit is ignored',
        (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      Navigator.of(tester.element(find.byType(QuizScreen))).pop();
      await tester.pumpAndSettle();
      if (fails) {
        harness.repository.reads.single
            .completeError(StateError('Synthetic late failure'));
      } else {
        harness.repository.reads.single
            .complete([_question('late', SourceStatus.verified)]);
      }
      await tester.pumpAndSettle();
      expect(find.text('Open quiz'), findsOneWidget);
      expect(find.byType(QuizScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('synchronous repository failure is recoverable', (tester) async {
    final harness = _Harness();
    harness.repository.throwSynchronously = true;
    await harness.pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('重试读取题目'), findsOneWidget);
    harness.repository.throwSynchronously = false;
    await tester.tap(find.text('重试读取题目'));
    await tester.pump();
    harness.repository.reads.single.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('暂无已核验题目，请先在知识库完成来源核验'), findsOneWidget);
    expect(find.byType(KnowledgeLibraryErrorState), findsNothing);
  });

  testWidgets(
      'repeated retry starts one read and a later failure stays retryable',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    harness.repository.reads.single
        .completeError(StateError('Synthetic first failure'));
    await tester.pumpAndSettle();
    final retry = tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '重试读取题目'))
        .onPressed!;
    retry();
    retry();
    await tester.pump();
    expect(harness.repository.reads, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    harness.repository.reads.last
        .completeError(StateError('Synthetic retry failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Synthetic retry failure'), findsOneWidget);
    await tester.tap(find.text('重试读取题目'));
    await tester.pump();
    expect(harness.repository.reads, hasLength(3));
    harness.repository.reads.last
        .complete([_question('recovered', SourceStatus.verified)]);
    await tester.pumpAndSettle();
    expect(find.text('Question recovered'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading has a visible back action before the read completes',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    harness.repository.reads.single.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Open quiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prefetched practice filters questions without reading a deck',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester, questions: [
      _question('pending', SourceStatus.pending),
      _question('prefetched', SourceStatus.verified),
    ]);
    expect(harness.repository.reads, isEmpty);
    expect(find.text('Question prefetched'), findsOneWidget);
    expect(find.text('Question pending'), findsNothing);
  });

  testWidgets('practice with no input stays empty without reading a deck',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester, deckId: null);
    expect(harness.repository.reads, isEmpty);
    expect(find.text('暂无已核验题目，请先在知识库完成来源核验'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('large-text loading error keeps recovery controls reachable',
      (tester) async {
    final harness = _Harness();
    await harness.pump(tester, size: const Size(320, 400), textScale: 2);
    harness.repository.reads.single.completeError(
        StateError(List.filled(20, 'Synthetic read failure').join(' ')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('复制诊断'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('复制诊断')).bottom, lessThanOrEqualTo(400));
    await tester.ensureVisible(find.text('重试读取题目'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('重试读取题目')).right, lessThanOrEqualTo(320));
    await tester.tap(find.text('重试读取题目'));
    await tester.pump();
    expect(harness.repository.reads, hasLength(2));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    harness.repository.reads.last
        .completeError(StateError('Synthetic abandoned retry'));
    await tester.pumpAndSettle();
    expect(find.text('Open quiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Question _question(String id, SourceStatus status) => Question(
      id: id,
      deckId: 'quiz-deck',
      type: QuestionType.multipleChoice,
      content: 'Question $id',
      options: const ['First answer', 'Second answer'],
      answer: 'First answer',
      sourceStatus: status,
      citationIds: const ['quiz-chunk'],
    );

class _Harness {
  final repository = _Questions();

  Future<void> pump(
    WidgetTester tester, {
    String? deckId = 'quiz-deck',
    List<Question>? questions,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        questionRepositoryProvider.overrideWithValue(repository),
        gamificationServiceProvider.overrideWithValue(_Game()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
            builder: (context) => Scaffold(
                  body: Center(
                      child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) =>
                          QuizScreen(deckId: deckId, questions: questions),
                    )),
                    child: const Text('Open quiz'),
                  )),
                )),
      ),
    ));
    await tester.tap(find.text('Open quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

class _Questions extends Fake implements QuestionRepository {
  final reads = <Completer<List<Question>>>[];
  final deckIds = <String>[];
  bool throwSynchronously = false;

  @override
  Future<List<Question>> getQuestionsByDeck(String deckId) {
    deckIds.add(deckId);
    if (throwSynchronously) throw StateError('Synthetic synchronous failure');
    final read = Completer<List<Question>>();
    reads.add(read);
    return read.future;
  }
}

class _Game extends Fake implements GamificationService {
  @override
  Future<UserStats> getStats() async =>
      UserStats(xp: 10000, lastStudyDate: DateTime(2026, 9, 8));
}
