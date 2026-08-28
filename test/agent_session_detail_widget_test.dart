import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/features/agent/agent_session_detail_screen.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 24, 12);
  final point = KnowledgePoint(
    id: 'point-detail',
    title: 'Checkpoint routing',
    summary: 'The checkpoint preserves the selected tool and evidence.',
    kind: KnowledgePointKind.architecture,
    createdAt: now,
    updatedAt: now,
  );
  final session = LearningSession(
    id: 'session-detail',
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

  testWidgets('shows the knowledge point loading state', (tester) async {
    final completer = Completer<KnowledgePoint?>();
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        pointOverride: (ref) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.text('正在读取关联知识点...'), findsOneWidget);

    completer.complete(point);
    await tester.pumpAndSettle();
    expect(find.text('Checkpoint routing'), findsWidgets);
  });

  testWidgets('retries a failed knowledge point load', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        pointOverride: (ref) async {
          attempts += 1;
          if (attempts == 1) throw StateError('knowledge store unavailable');
          return point;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('关联知识点读取失败'), findsOneWidget);
    expect(find.text('重试读取知识点'), findsOneWidget);

    await tester.tap(find.text('重试读取知识点'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Checkpoint routing'), findsWidgets);
    expect(find.text('关联知识点读取失败'), findsNothing);
  });

  testWidgets('opens the linked knowledge point detail', (tester) async {
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('掌握度 0%'));
    await tester.pumpAndSettle();

    expect(find.text('知识点详情'), findsOneWidget);
    expect(find.text('Checkpoint routing'), findsWidgets);
  });

  testWidgets('renders confirmed criteria, trace, and review note',
      (tester) async {
    final richSession = LearningSession(
      id: 'session-rich',
      mode: LearningSessionMode.agentSession,
      targetId: point.id,
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 8)),
      summary: [
        'AI 应用开发面试 · Rich checkpoint',
        '目标: Checkpoint routing',
        '成功标准: 说明恢复状态',
        '已确认: 已说明 checkpoint 和 evidence 的关系',
        '本轮追问: 为什么需要保留 evidence ids？',
        '下次追问: 恢复失败时如何诊断？',
        'Agent Trace',
        '读取知识点',
        '生成追问',
        '复盘: 需要补充失败恢复演练。',
      ].join('\n'),
    );
    await tester.pumpWidget(
      _app(
        session: richSession,
        memory: AgentSessionMemoryIndex([richSession]),
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('已确认标准'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('已确认标准'), findsOneWidget);
    expect(find.text('已说明 checkpoint 和 evidence 的关系'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('本轮追问'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('本轮追问'), findsOneWidget);
    expect(find.text('为什么需要保留 evidence ids？'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Agent Trace'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Agent Trace'), findsOneWidget);
    expect(find.text('读取知识点'), findsOneWidget);
    expect(find.text('生成追问'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('需要补充失败恢复演练。'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('需要补充失败恢复演练。'), findsOneWidget);
  });

  testWidgets('uses goal-level follow-up history when target is absent',
      (tester) async {
    final noTargetSession = LearningSession(
      id: 'session-no-target',
      mode: session.mode,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      summary: [
        'AI 应用开发面试 · No target checkpoint',
        '目标: No target checkpoint',
        '成功标准: 说明目标级历史追问',
        '下次追问: 目标没有 target id 时如何恢复？',
      ].join('\n'),
    );
    await tester.pumpWidget(
      _app(
        session: noTargetSession,
        memory: AgentSessionMemoryIndex([noTargetSession]),
        pointOverride: (ref) async => null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('查看 1 条未处理追问'), findsOneWidget);
    await tester.tap(find.text('查看 1 条未处理追问'));
    await tester.pumpAndSettle();

    expect(find.text('Agent Session 历史'), findsOneWidget);
    expect(find.text('AI 应用开发面试 1/1'), findsOneWidget);
  });

  testWidgets('opens goal, target, and follow-up history filters',
      (tester) async {
    final memory = AgentSessionMemoryIndex([session]);
    await tester.pumpWidget(
      _app(
        session: session,
        memory: memory,
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('查看同目标历史'));
    await tester.pumpAndSettle();
    expect(find.text('Agent Session 历史'), findsOneWidget);
    expect(find.text('AI 应用开发面试 1/1'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('查看本目标 1 条记录'));
    await tester.pumpAndSettle();
    expect(find.text('Agent Session 历史'), findsOneWidget);
    expect(find.textContaining('目标: Checkpoint routing'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('查看 1 条未处理追问'));
    await tester.pumpAndSettle();
    expect(find.text('Agent Session 历史'), findsOneWidget);
    expect(find.textContaining('1 条未处理追问'), findsOneWidget);
    expect(find.textContaining('目标: Checkpoint routing'), findsOneWidget);
  });

  testWidgets('keeps a follow-up open when no tutor session is completed',
      (tester) async {
    final repository = _TestLearningSessionRepository([session]);
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        repository: repository,
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('导师追问'));
    await tester.pumpAndSettle();
    expect(find.text('导师模式'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      find.text('还没有检测到完成的导师追问，追问仍保持未处理。'),
      findsOneWidget,
    );
    expect(repository.inserted, isEmpty);
  });

  testWidgets('keeps a follow-up open when no interview is completed',
      (tester) async {
    final repository = _TestLearningSessionRepository([session]);
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        repository: repository,
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('面试追问'));
    await tester.pumpAndSettle();
    expect(find.text('面试官模式'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      find.text('还没有检测到完成的面试追问，追问仍保持未处理。'),
      findsOneWidget,
    );
    expect(repository.inserted, isEmpty);
  });

  testWidgets('records a handled follow-up after a completed tutor session',
      (tester) async {
    final repository = _TestLearningSessionRepository([session]);
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        repository: repository,
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('导师追问'));
    await tester.pumpAndSettle();
    repository.values.add(_completedTutorSession(point, session));
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('已记录为已处理追问。'), findsOneWidget);
    expect(repository.inserted, hasLength(1));
    expect(repository.inserted.single.mode, LearningSessionMode.agentSession);
    expect(repository.inserted.single.summary, contains('导师追问'));
  });

  testWidgets('shows a save error when handled follow-up recording fails',
      (tester) async {
    final repository = _TestLearningSessionRepository(
      [session],
      failNextInsert: true,
    );
    await tester.pumpWidget(
      _app(
        session: session,
        memory: AgentSessionMemoryIndex([session]),
        repository: repository,
        pointOverride: (ref) async => point,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('导师追问'));
    await tester.pumpAndSettle();
    repository.values.add(_completedTutorSession(point, session));
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('追问处理记录保存失败'), findsOneWidget);
    expect(repository.inserted, isEmpty);
  });
}

Widget _app({
  required LearningSession session,
  required AgentSessionMemoryIndex memory,
  Future<KnowledgePoint?> Function(Ref ref)? pointOverride,
  LearningSessionRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      agentSessionMemoryIndexProvider.overrideWith((ref) async => memory),
      if (session.targetId != null && pointOverride != null)
        knowledgePointProvider(session.targetId!).overrideWith(pointOverride),
      if (repository != null)
        learningSessionRepositoryProvider.overrideWithValue(repository),
      openaiServiceProvider.overrideWithValue(_TestOpenAIService()),
    ],
    child: MaterialApp(
      home: AgentSessionDetailScreen(session: session),
    ),
  );
}

LearningSession _completedTutorSession(
  KnowledgePoint point,
  LearningSession source,
) {
  const question = '恢复时为什么必须保留 evidence ids？';
  final startedAt = source.startedAt.add(const Duration(hours: 1));
  return LearningSession(
    id: 'completed-tutor',
    mode: LearningSessionMode.tutor,
    targetId: point.id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 2)),
    summary: 'Tutor Session\n本轮追问: $question',
  );
}

class _TestOpenAIService extends OpenAIService {
  @override
  Future<bool> hasApiKey({String? providerId}) async => false;
}

class _TestLearningSessionRepository extends LearningSessionRepository {
  final List<LearningSession> values;
  final List<LearningSession> inserted = [];
  bool failNextInsert;

  _TestLearningSessionRepository(
    this.values, {
    this.failNextInsert = false,
  }) : super(DatabaseHelper());

  @override
  Future<List<LearningSession>> getLearningSessions() async => values;

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    if (failNextInsert) {
      failNextInsert = false;
      throw StateError('follow-up record unavailable');
    }
    inserted.add(session);
    return session.id;
  }
}
