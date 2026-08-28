import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/features/agent/agent_session_detail_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_history_screen.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 21, 12);
  final point = KnowledgePoint(
    id: 'point-history',
    title: 'Checkpoint routing',
    summary: 'The checkpoint preserves the selected tool and evidence.',
    kind: KnowledgePointKind.architecture,
    createdAt: now,
    updatedAt: now,
  );
  final session = LearningSession(
    id: 'session-history',
    mode: LearningSessionMode.agentSession,
    targetId: point.id,
    startedAt: now,
    endedAt: now.add(const Duration(minutes: 5)),
    summary: [
      'AI 应用开发面试 · Checkpoint routing',
      '目标: Checkpoint routing',
      '成功标准: 说明 checkpoint 如何恢复路由状态',
      '下次追问: 恢复时为什么必须保留 evidence ids？',
    ].join('\n'),
  );
  final memory = AgentSessionMemoryIndex([session]);

  testWidgets('history filters sessions and exposes open follow-up',
      (tester) async {
    await tester.pumpWidget(
      _withProviders(
        memory: memory,
        child: const AgentSessionHistoryScreen(
          initialGoal: LearningAgentGoal.aiInterviewPrep,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI 应用开发面试 1/1'), findsOneWidget);
    expect(find.text('AI 应用开发面试 · Checkpoint routing'), findsOneWidget);
    expect(find.text('继续追问'), findsOneWidget);
    expect(find.text('当前目标有 1 条未处理追问'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'does-not-exist');
    await tester.pump();
    expect(find.text('当前搜索没有匹配的 Agent Session 记录'), findsOneWidget);
    expect(find.text('清除筛选'), findsNWidgets(2));

    await tester.tap(find.text('清除筛选').first);
    await tester.pump();
    expect(find.text('AI 应用开发面试 · Checkpoint routing'), findsOneWidget);
  });

  testWidgets('detail shows target knowledge point and history action',
      (tester) async {
    await tester.pumpWidget(
      _withProviders(
        memory: memory,
        point: point,
        child: MaterialApp(
          home: AgentSessionDetailScreen(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agent Session 复盘'), findsOneWidget);
    expect(find.text('Checkpoint routing'), findsWidgets);
    expect(find.text('查看同目标历史'), findsOneWidget);
    expect(find.text('查看 1 条未处理追问'), findsOneWidget);
    expect(find.text('恢复时为什么必须保留 evidence ids？'), findsOneWidget);
  });

  testWidgets('history error retries and recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentSessionMemoryIndexProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) {
              throw StateError('history database unavailable');
            }
            return memory;
          }),
        ],
        child: const MaterialApp(
          home: AgentSessionHistoryScreen(
            initialGoal: LearningAgentGoal.aiInterviewPrep,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Agent Session 历史读取失败'), findsOneWidget);
    expect(find.text('重试读取历史'), findsOneWidget);
    await tester.tap(find.text('重试读取历史'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('AI 应用开发面试 1/1'), findsOneWidget);
    expect(find.textContaining('历史读取失败'), findsNothing);
  });

  testWidgets('target filter shows empty state and can be cleared',
      (tester) async {
    await tester.pumpWidget(
      _withProviders(
        memory: memory,
        child: const AgentSessionHistoryScreen(
          initialTargetId: 'missing-target',
          initialTargetLabel: '不存在的目标',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目标筛选: 不存在的目标'), findsOneWidget);
    expect(find.text('当前目标还没有 Agent Session 记录'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('目标筛选: 不存在的目标'), findsNothing);
    expect(find.text('全部记录 1/1'), findsOneWidget);
    expect(
        find.textContaining('AI 应用开发面试 · Checkpoint routing'), findsOneWidget);
  });
}

Widget _withProviders({
  required AgentSessionMemoryIndex memory,
  required Widget child,
  KnowledgePoint? point,
}) {
  return ProviderScope(
    overrides: [
      agentSessionMemoryIndexProvider.overrideWith((ref) async => memory),
      if (point != null)
        knowledgePointProvider(point.id).overrideWith((ref) async => point),
    ],
    child: child is MaterialApp ? child : MaterialApp(home: child),
  );
}
