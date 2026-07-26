import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/ingestion/project_code_walkthrough_screen.dart';
import 'package:dlg_q/services/ingestion/project_code_walkthrough_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orders project walkthrough from architecture to trade-off', () {
    final now = DateTime(2026, 7, 14);
    final points = [
      _point('trade', KnowledgePointKind.tradeOff, now),
      _point('implementation', KnowledgePointKind.implementation, now),
      _point('architecture', KnowledgePointKind.architecture, now),
      _point('concept', KnowledgePointKind.concept, now),
      _point('data', KnowledgePointKind.dataFlow, now),
      _point('boundary', KnowledgePointKind.boundary, now),
    ];
    final chunks = [
      _chunk('chunk-architecture', 'lib/app.dart:1-10', now),
      _chunk('chunk-data', 'lib/data.dart:3-20', now),
    ];

    final steps = const ProjectCodeWalkthroughService().build(
      knowledgePoints: points,
      sourceChunks: chunks,
      sourceChunkIdsByKnowledgePointId: const {
        'architecture': ['chunk-architecture'],
        'data': ['chunk-data'],
      },
    );

    expect(
      steps.map((step) => step.knowledgePoint.kind),
      [
        KnowledgePointKind.architecture,
        KnowledgePointKind.dataFlow,
        KnowledgePointKind.implementation,
        KnowledgePointKind.boundary,
        KnowledgePointKind.tradeOff,
      ],
    );
    expect(steps.map((step) => step.sequence), [1, 2, 3, 4, 5]);
    expect(steps.first.locatorLabel, 'lib/app.dart:1-10');
    expect(steps[1].evidenceChunks.single.id, 'chunk-data');
  });

  testWidgets('opens a walkthrough step and shows its source locator',
      (tester) async {
    final now = DateTime(2026, 7, 14);
    final point = _point(
      'architecture',
      KnowledgePointKind.architecture,
      now,
    );
    final chunk = _chunk('chunk-architecture', 'lib/app.dart:1-10', now);

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectCodeWalkthroughScreen(
          knowledgePoints: [point],
          sourceChunks: [chunk],
          sourceChunkIdsByKnowledgePointId: const {
            'architecture': ['chunk-architecture'],
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('walkthrough_step_1')));
    await tester.pumpAndSettle();

    expect(find.text('第 1 步'), findsOneWidget);
    expect(find.text('lib/app.dart:1-10'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });
}

KnowledgePoint _point(
  String id,
  KnowledgePointKind kind,
  DateTime now,
) {
  return KnowledgePoint(
    id: id,
    title: id,
    summary: 'summary',
    kind: kind,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(String id, String locator, DateTime now) {
  return SourceChunk(
    id: id,
    sourceId: 'source-1',
    chunkIndex: 0,
    content: 'content',
    locator: locator,
    contentHash: 'hash',
    createdAt: now,
  );
}
