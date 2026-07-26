import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/models/interview_turn.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/agent/interview_session_detail_screen.dart';
import 'package:dlg_q/features/agent/interview_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('interview history exposes cited review and retry actions',
      (tester) async {
    final now = DateTime(2026, 7, 15, 12);
    final chunk = SourceChunk(
      id: 'chunk-1',
      sourceId: 'source-1',
      chunkIndex: 0,
      content: 'final provider = Provider((ref) => Repository());',
      locator: 'lib/app.dart:1-1',
      contentHash: 'hash',
      createdAt: now,
    );
    final point = KnowledgePoint(
      id: 'point-1',
      title: 'Provider orchestration',
      summary: 'Providers connect tasks and repositories.',
      kind: KnowledgePointKind.architecture,
      createdAt: now,
      updatedAt: now,
    );
    final session = LearningSession(
      id: 'session-1',
      mode: LearningSessionMode.interview,
      targetId: point.id,
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 10)),
    );
    final turn = InterviewTurn(
      id: 'turn-1',
      sessionId: session.id,
      questionText: 'How does provider orchestration work?',
      userAnswer: 'Providers call repositories.',
      aiFeedback: 'Add the concrete source-backed data path.',
      referenceAnswer: 'The provider delegates to the repository.',
      knowledgePointId: point.id,
      knowledgePointKind: point.kind,
      citationIds: [chunk.id],
      accuracyScore: 2,
      projectDetailScore: 1,
      engineeringScore: 3,
      clarityScore: 4,
      weakKnowledgePointIds: [point.id],
      weakDimensions: const [
        InterviewScoreDimension.accuracy,
        InterviewScoreDimension.projectDetail,
      ],
      reviewQuestionIds: const ['question-1'],
      reviewDueAt: now,
      nextInterviewQuestion: '请重新回答这个问题，重点补充事实准确、项目细节。',
      createdAt: now,
    );

    final citationKey = turn.citationIds.join('\x00');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          interviewTurnsProvider(session.id).overrideWith(
            (ref) => Future.value([turn]),
          ),
          questionCitationChunksProvider(citationKey).overrideWith(
            (ref) => Future.value([chunk]),
          ),
        ],
        child: MaterialApp(
          home: InterviewSessionDetailScreen(session: session),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('下一步'), findsOneWidget);
    expect(find.text('事实准确'), findsOneWidget);
    expect(find.text('项目细节'), findsOneWidget);
    expect(find.text('开始复习'), findsOneWidget);
    expect(find.text('再次面试'), findsOneWidget);
    expect(find.text('lib/app.dart:1-1'), findsOneWidget);
    expect(find.text(turn.nextInterviewQuestion), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('interview completion shows weak evidence and next actions',
      (tester) async {
    final now = DateTime(2026, 7, 15, 12);
    final point = KnowledgePoint(
      id: 'point-completion',
      title: 'Checkpoint routing contract',
      summary: 'The input snapshot must match the active routing state.',
      kind: KnowledgePointKind.architecture,
      createdAt: now,
      updatedAt: now,
    );
    final chunk = SourceChunk(
      id: 'chunk-completion',
      sourceId: 'source-completion',
      chunkIndex: 0,
      content: 'if (activeToolInput.toolId != state.selectedToolId) { ... }',
      locator: 'lib/checkpoint.dart:10-12',
      contentHash: 'hash-completion',
      createdAt: now,
    );
    final turn = InterviewTurn(
      id: 'turn-completion',
      sessionId: 'session-completion',
      questionText: 'Which routing fields are checked?',
      userAnswer: 'The tool id is checked.',
      aiFeedback: 'The answer omitted target, focus point, and evidence ids.',
      referenceAnswer: 'The checkpoint compares every routing field.',
      knowledgePointId: point.id,
      knowledgePointKind: point.kind,
      citationIds: [chunk.id],
      accuracyScore: 2,
      projectDetailScore: 1,
      engineeringScore: 2,
      clarityScore: 4,
      weakKnowledgePointIds: [point.id],
      weakDimensions: const [
        InterviewScoreDimension.accuracy,
        InterviewScoreDimension.projectDetail,
        InterviewScoreDimension.engineering,
      ],
      reviewQuestionIds: const ['question-completion'],
      reviewDueAt: now,
      nextInterviewQuestion: '请重新回答并补充所有路由字段。',
      createdAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sourceProvider(chunk.sourceId).overrideWith(
            (ref) => Future.value(null),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: InterviewCompletionView(
              turns: [turn],
              knowledgePoints: [point],
              sourceChunks: [chunk],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('薄弱点与下一步'), findsOneWidget);
    expect(find.text(point.title), findsOneWidget);
    expect(find.text(turn.aiFeedback), findsOneWidget);
    expect(find.text('lib/checkpoint.dart:10-12'), findsOneWidget);
    expect(find.text('开始复习'), findsOneWidget);
    expect(find.text('再次面试'), findsOneWidget);
  });
}
