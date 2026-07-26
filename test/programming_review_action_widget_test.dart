import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_review_action.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/agent/review_agent_screen.dart';
import 'package:dlg_q/services/scheduling/programming_review_closure_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('programming review exposes weakness, prerequisite and citation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 7, 15, 21);
    final source = Source(
      id: 'source-review',
      title: 'Official return-path reference',
      type: SourceType.officialDoc,
      trustLevel: SourceTrustLevel.officialDoc,
      createdAt: now,
      updatedAt: now,
    );
    final chunk = SourceChunk(
      id: 'chunk-review',
      sourceId: source.id,
      chunkIndex: 0,
      content: 'The final statement returns persistedValue.',
      locator: 'reference.dart:L10-L10',
      contentHash: 'chunk-review-hash',
      createdAt: now,
    );
    final point = KnowledgePoint(
      id: 'point-review',
      title: 'Return path',
      summary: 'Trace the value that reaches the return boundary.',
      masteryLevel: 42,
      createdAt: now,
      updatedAt: now,
    );
    final prerequisite = KnowledgePoint(
      id: 'point-prerequisite',
      title: 'State ownership',
      summary: 'Identify where the persisted value is owned.',
      masteryLevel: 30,
      createdAt: now,
      updatedAt: now,
    );
    final exercise = ProgrammingExercise(
      id: 'exercise-review-retest',
      knowledgePointId: point.id,
      kind: ProgrammingExerciseKind.codeReading,
      prompt: 'Trace the return path again.',
      referenceAnswer: 'The final statement returns persistedValue.',
      conceptAccuracyCriterion: 'Identify persistedValue.',
      reasoningProcessCriterion: 'Trace the final statement.',
      evidenceUseCriterion: 'Use the cited line.',
      clarityCriterion: 'State the value directly.',
      sourceStatus: SourceStatus.verified,
      citationIds: [chunk.id],
      isRetest: true,
      createdAt: now,
      updatedAt: now,
    );
    final action = ProgrammingReviewAction(
      id: 'programming-review-action',
      knowledgePointId: point.id,
      triggerType: ProgrammingReviewTriggerType.exerciseAttempt,
      triggerId: 'attempt-review',
      weakDimensions: const [
        ProgrammingWeakDimension.conceptAccuracy,
        ProgrammingWeakDimension.evidenceUse,
      ],
      prerequisiteKnowledgePointIds: [prerequisite.id],
      citationIds: [chunk.id],
      reviewExerciseIds: [exercise.id],
      dueAt: now,
      createdAt: now,
    );
    final item = ProgrammingReviewQueueItem(
      action: action,
      knowledgePoint: point,
      prerequisiteKnowledgePoints: [prerequisite],
      exercises: [exercise],
    );
    final citationKey = action.citationIds.join('\x00');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programmingReviewQueueProvider.overrideWith(
            (ref) => Future.value([item]),
          ),
          todayReviewQueueProvider.overrideWith(
            (ref) => Future.value(const []),
          ),
          practiceableKnowledgePointListProvider.overrideWith(
            (ref) => Future.value(const []),
          ),
          questionCitationChunksProvider(citationKey).overrideWith(
            (ref) => Future.value([chunk]),
          ),
          sourceProvider(source.id).overrideWith(
            (ref) => Future.value(source),
          ),
        ],
        child: const MaterialApp(home: ReviewAgentScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('编程修复'), findsOneWidget);
    expect(find.text(point.title), findsOneWidget);
    expect(find.text('${point.masteryLevel}%'), findsOneWidget);
    expect(
      find.textContaining(
        '概念准确、代码或文档依据',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(prerequisite.title, findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('完成 1 道已核验复测', findRichText: true),
      findsOneWidget,
    );
    final startButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始复测'),
    );
    expect(startButton.onPressed, isNotNull);

    await tester.tap(find.text('来源依据 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining(source.title), findsOneWidget);
    expect(find.text(chunk.locator!), findsOneWidget);
    expect(find.text(chunk.content), findsOneWidget);
  });
}
