import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/ingestion/knowledge_review_screen.dart';
import 'package:dlg_q/services/ingestion/source_grounded_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a typed project unit with its source evidence',
      (tester) async {
    final now = DateTime(2026, 7, 14);
    final point = KnowledgePoint(
      id: 'point-1',
      title: 'Provider orchestration',
      summary: 'Providers connect AI tasks to repositories.',
      kind: KnowledgePointKind.architecture,
      createdAt: now,
      updatedAt: now,
    );
    final chunk = SourceChunk(
      id: 'chunk-1',
      sourceId: 'source-1',
      chunkIndex: 0,
      content: 'final provider = Provider((ref) => Repository());',
      locator: 'lib/app.dart:1-2',
      relativePath: 'lib/app.dart',
      startLine: 1,
      endLine: 2,
      contentHash: 'hash',
      createdAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeReviewScreen(
          title: 'Project review',
          sourceChunks: [chunk],
          knowledgePoints: [point],
          sourceChunkIdsByKnowledgePointId: const {
            'point-1': ['chunk-1'],
          },
        ),
      ),
    );

    expect(find.text('架构'), findsOneWidget);
    expect(find.text('源码依据'), findsOneWidget);
    expect(find.text('lib/app.dart:1-2'), findsOneWidget);
    expect(
      find.text('final provider = Provider((ref) => Repository());'),
      findsOneWidget,
    );
  });

  testWidgets('deleting a unit also deletes its associated question decision',
      (tester) async {
    final now = DateTime(2026, 7, 14);
    final architecturePoint = _point(
      id: 'point-architecture',
      kind: KnowledgePointKind.architecture,
      now: now,
    );
    final boundaryPoint = _point(
      id: 'point-boundary',
      kind: KnowledgePointKind.boundary,
      now: now,
    );
    final architectureChunk = _chunk(
      id: 'chunk-architecture',
      locator: 'lib/app.dart:1-20',
      now: now,
    );
    final boundaryChunk = _chunk(
      id: 'chunk-boundary',
      locator: 'lib/storage.dart:1-12',
      now: now,
    );
    final architectureQuestion = _question(
      id: 'question-architecture',
      pointId: architecturePoint.id,
      chunkId: architectureChunk.id,
    );
    final boundaryQuestion = _question(
      id: 'question-boundary',
      pointId: boundaryPoint.id,
      chunkId: boundaryChunk.id,
    );
    List<SourceGroundedKnowledgePointDecision>? pointDecisions;
    List<SourceGroundedQuestionDecision>? questionDecisions;

    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeReviewScreen(
          title: 'Project review',
          sourceChunks: [architectureChunk, boundaryChunk],
          knowledgePoints: [architecturePoint, boundaryPoint],
          sourceChunkIdsByKnowledgePointId: {
            architecturePoint.id: [architectureChunk.id],
            boundaryPoint.id: [boundaryChunk.id],
          },
          questions: [architectureQuestion, boundaryQuestion],
          onSave: (points, questions) async {
            pointDecisions = points;
            questionDecisions = questions;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(
      const ValueKey('approve_all_knowledge_points'),
    ));
    await tester.pump();
    final deleteBoundaryButton = find.byKey(
      const ValueKey('delete_knowledge_point-boundary'),
    );
    await tester.scrollUntilVisible(
      deleteBoundaryButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(deleteBoundaryButton);
    await tester.pump();

    expect(find.text('question for point-boundary'), findsNothing);

    await tester.tap(find.text('保存已核验内容'));
    await tester.pump();

    expect(pointDecisions, isNotNull);
    expect(questionDecisions, isNotNull);
    expect(
      pointDecisions!
          .singleWhere(
            (decision) => decision.knowledgePoint.id == architecturePoint.id,
          )
          .approved,
      isTrue,
    );
    final deletedPoint = pointDecisions!.singleWhere(
      (decision) => decision.knowledgePoint.id == boundaryPoint.id,
    );
    expect(deletedPoint.approved, isFalse);
    expect(deletedPoint.deleted, isTrue);
    expect(
      questionDecisions!
          .singleWhere(
            (decision) => decision.question.id == architectureQuestion.id,
          )
          .deleted,
      isFalse,
    );
    expect(
      questionDecisions!
          .singleWhere(
            (decision) => decision.question.id == boundaryQuestion.id,
          )
          .deleted,
      isTrue,
    );
  });

  testWidgets('bulk verifies only questions with readable citations',
      (tester) async {
    final now = DateTime(2026, 7, 17);
    final chunk = _chunk(
      id: 'chunk-readable',
      locator: 'lib/app.dart:1-10',
      now: now,
    );
    final validQuestion = _question(
      id: 'question-valid',
      pointId: null,
      chunkId: chunk.id,
      sourceStatus: SourceStatus.pending,
    );
    final missingQuestion = _question(
      id: 'question-missing',
      pointId: null,
      chunkId: 'chunk-missing',
      sourceStatus: SourceStatus.pending,
    );
    List<SourceGroundedQuestionDecision>? decisions;

    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeReviewScreen(
          title: 'Question review',
          sourceChunks: [chunk],
          questions: [validQuestion, missingQuestion],
          onSave: (_, questions) async => decisions = questions,
        ),
      ),
    );

    await tester.tap(find.byKey(
      const ValueKey('verify_all_cited_questions'),
    ));
    await tester.pump();
    await tester.tap(find.text('保存已核验内容'));
    await tester.pump();

    expect(decisions, isNotNull);
    expect(
      decisions!
          .singleWhere(
            (decision) => decision.question.id == validQuestion.id,
          )
          .sourceStatus,
      SourceStatus.verified,
    );
    expect(
      decisions!
          .singleWhere(
            (decision) => decision.question.id == validQuestion.id,
          )
          .deleted,
      isFalse,
    );
    expect(
      decisions!
          .singleWhere(
            (decision) => decision.question.id == missingQuestion.id,
          )
          .sourceStatus,
      SourceStatus.pending,
    );
  });

  testWidgets('bulk verify respects a manual no-source draft status',
      (tester) async {
    final now = DateTime(2026, 7, 17);
    final chunk = _chunk(
      id: 'chunk-readable',
      locator: 'lib/app.dart:1-10',
      now: now,
    );
    final question = _question(
      id: 'question-manual-status',
      pointId: null,
      chunkId: chunk.id,
      sourceStatus: SourceStatus.pending,
    );
    List<SourceGroundedQuestionDecision>? decisions;

    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeReviewScreen(
          title: 'Question review',
          sourceChunks: [chunk],
          questions: [question],
          onSave: (_, questions) async => decisions = questions,
        ),
      ),
    );

    await tester.tap(find.text('无来源'));
    await tester.pump();
    await tester.tap(find.byKey(
      const ValueKey('verify_all_cited_questions'),
    ));
    await tester.pump();
    await tester.tap(find.text('保存已核验内容'));
    await tester.pump();

    expect(decisions, isNotNull);
    expect(decisions!.single.sourceStatus, SourceStatus.noSource);
  });
}

KnowledgePoint _point({
  required String id,
  required KnowledgePointKind kind,
  required DateTime now,
}) {
  return KnowledgePoint(
    id: id,
    title: id,
    summary: 'summary for $id',
    kind: kind,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk({
  required String id,
  required String locator,
  required DateTime now,
}) {
  return SourceChunk(
    id: id,
    sourceId: 'source-1',
    chunkIndex: id == 'chunk-architecture' ? 0 : 1,
    content: 'source for $id',
    locator: locator,
    contentHash: 'hash-$id',
    createdAt: now,
  );
}

Question _question({
  required String id,
  required String? pointId,
  required String chunkId,
  SourceStatus sourceStatus = SourceStatus.verified,
}) {
  return Question(
    id: id,
    deckId: 'deck-1',
    knowledgePointId: pointId,
    type: QuestionType.fillBlank,
    content: 'question for $pointId',
    answer: 'answer',
    sourceStatus: sourceStatus,
    citationIds: [chunkId],
  );
}
