import 'package:anchor_learning/features/knowledge_base/learning_target_memory_timeline.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a compact cross-surface target timeline',
      (tester) async {
    final now = DateTime.utc(2026, 7, 15, 9, 30);
    final records = LearningAgentMemoryRecordType.values
        .map(
          (type) => LearningAgentMemoryRecord(
            id: type.value,
            type: type,
            sourceId: type.value,
            targetId: 'point-1',
            targetLabel: '事件循环',
            targetResolution:
                type == LearningAgentMemoryRecordType.knowledgeAnswer
                    ? LearningAgentMemoryTargetResolution.sourceCitation
                    : LearningAgentMemoryTargetResolution.direct,
            occurredAt: now.subtract(Duration(hours: type.index)),
            title: '${type.label}记录',
            summary: '这是一条用于知识点连续学习历史的摘要。',
            citationIds: type == LearningAgentMemoryRecordType.agentReflection
                ? const []
                : const ['chunk-1'],
            reviewDueAt: type == LearningAgentMemoryRecordType.reviewAction
                ? now.add(const Duration(days: 1))
                : null,
            evidenceSufficient:
                type != LearningAgentMemoryRecordType.knowledgeAnswer,
          ),
        )
        .toList();
    final snapshot = LearningAgentMemorySnapshot(
      records: records,
      recentRecords: records,
      openFollowUps: [
        LearningAgentOpenFollowUp(
          id: 'follow-up-1',
          recordId: LearningAgentMemoryRecordType.tutor.value,
          recordType: LearningAgentMemoryRecordType.tutor,
          targetId: 'point-1',
          question: '继续解释微任务队列',
          createdAt: now,
        ),
      ],
      stableMisconceptions: [
        LearningAgentStableMisconception(
          key: 'future-thread',
          label: '把 Future 当成线程',
          occurrenceCount: 2,
          latestAt: now,
        ),
      ],
      weakDimensions: [
        LearningAgentWeakDimensionSummary(
          key: 'accuracy',
          label: '准确性',
          occurrenceCount: 3,
          latestAt: now,
        ),
      ],
      nextReviewAt: now.add(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LearningTargetMemoryTimeline(snapshot: snapshot),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('连续学习历史'), findsOneWidget);
    expect(find.text('6 条'), findsOneWidget);
    expect(find.textContaining('稳定误区：把 Future 当成线程 ×2'), findsOneWidget);
    expect(find.textContaining('薄弱维度：准确性 ×3'), findsOneWidget);
    expect(find.text('历史归属'), findsOneWidget);
    expect(find.text('证据待核查'), findsOneWidget);
    for (final type in LearningAgentMemoryRecordType.values) {
      expect(find.text(type.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an explicit empty target history state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: LearningTargetMemoryTimeline(
              snapshot: LearningAgentMemorySnapshot(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('连续学习历史'), findsOneWidget);
    expect(find.text('还没有与这个知识点关联的学习记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
