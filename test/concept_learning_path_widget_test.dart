import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_prerequisite.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/features/knowledge_base/concept_learning_path_screen.dart';
import 'package:anchor_learning/services/ai/ai_task_result.dart';
import 'package:anchor_learning/services/ai/tasks/concept_prerequisite_task.dart';
import 'package:anchor_learning/services/openai_service.dart';

void main() {
  testWidgets('reviews, reverses, and saves a cited prerequisite relation',
      (tester) async {
    final now = DateTime(2026, 7, 15);
    final basic = KnowledgePoint(
      id: 'basic',
      title: 'Basics',
      summary: 'Basic concept.',
      createdAt: now,
      updatedAt: now,
    );
    final advanced = KnowledgePoint(
      id: 'advanced',
      title: 'Advanced',
      summary: 'Advanced concept.',
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeKnowledgePointRepository(
      points: [basic, advanced],
      sourcesByPointId: {
        'basic': [
          KnowledgePointSource(
            knowledgePointId: 'basic',
            sourceChunkId: 'chunk-basic',
          ),
        ],
        'advanced': [
          KnowledgePointSource(
            knowledgePointId: 'advanced',
            sourceChunkId: 'chunk-advanced',
          ),
        ],
      },
      relations: [
        KnowledgePointPrerequisite(
          knowledgePointId: 'advanced',
          prerequisiteKnowledgePointId: 'basic',
          rationale: 'The source introduces Basics first.',
          citationIds: const ['chunk-basic'],
          createdAt: now,
        ),
      ],
    );
    final chunkRepository = _FakeSourceChunkRepository({
      'chunk-basic': _chunk('chunk-basic'),
      'chunk-advanced': _chunk('chunk-advanced'),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          knowledgePointRepositoryProvider.overrideWithValue(repository),
          sourceChunkRepositoryProvider.overrideWithValue(chunkRepository),
          knowledgePointQuestionsProvider.overrideWith(
            (ref, knowledgePointId) async => const [],
          ),
        ],
        child: const MaterialApp(home: ConceptLearningPathScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basics → Advanced'), findsOneWidget);
    expect(find.text('1 个来源片段'), findsOneWidget);

    await tester.tap(find.byTooltip('反向先修关系'));
    await tester.pumpAndSettle();
    expect(find.text('Advanced → Basics'), findsOneWidget);

    await tester.tap(find.byTooltip('保存学习路径'));
    await tester.pumpAndSettle();

    expect(repository.savedRelations, hasLength(1));
    expect(repository.savedRelations.single.knowledgePointId, 'basic');
    expect(
      repository.savedRelations.single.prerequisiteKnowledgePointId,
      'advanced',
    );
  });

  testWidgets('pending generation owns the analyze action', (tester) async {
    final openai = _ControlledOpenAIService.pendingKey();
    final task = _ControlledConceptPrerequisiteTask.pending();
    await _pumpPathScreen(tester, openai: openai, task: task);

    final analyze = find.text('分析先修关系');
    await tester.tap(analyze);
    await tester.tap(analyze);
    await tester.pump();

    openai.pendingKey!.complete(true);
    await tester.pump();

    expect(openai.hasApiKeyCalls, 1);
    expect(task.runCalls, 1);
  });

  testWidgets('late API-key result after route exit does not update UI',
      (tester) async {
    final openai = _ControlledOpenAIService.pendingKey();
    await _pumpPathScreen(
      tester,
      openai: openai,
      task: _ControlledConceptPrerequisiteTask.pending(),
    );

    await tester.tap(find.text('分析先修关系'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    openai.pendingKey!.complete(true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('late prerequisite result after route exit does not update UI',
      (tester) async {
    final task = _ControlledConceptPrerequisiteTask.pending();
    await _pumpPathScreen(
      tester,
      openai: _ControlledOpenAIService.immediateKey(),
      task: task,
    );

    await tester.tap(find.text('分析先修关系'));
    await tester.pump();
    expect(task.runCalls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    task.pendingResult!.complete(
      AiTaskResult.success(ConceptPrerequisiteResult(relations: const [])),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('mounted generation failure remains retryable', (tester) async {
    final task = _ControlledConceptPrerequisiteTask.failure(
      'controlled prerequisite failure',
    );
    await _pumpPathScreen(
      tester,
      openai: _ControlledOpenAIService.immediateKey(),
      task: task,
    );

    await tester.tap(find.text('分析先修关系'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('controlled prerequisite failure'),
      findsOneWidget,
    );
    expect(find.text('重新分析'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPathScreen(
  WidgetTester tester, {
  required OpenAIService openai,
  required ConceptPrerequisiteTask task,
}) async {
  final now = DateTime(2026, 7, 15);
  final basic = KnowledgePoint(
    id: 'basic',
    title: 'Basics',
    summary: 'Basic concept.',
    createdAt: now,
    updatedAt: now,
  );
  final advanced = KnowledgePoint(
    id: 'advanced',
    title: 'Advanced',
    summary: 'Advanced concept.',
    createdAt: now,
    updatedAt: now,
  );
  final repository = _FakeKnowledgePointRepository(
    points: [basic, advanced],
    sourcesByPointId: {
      'basic': [
        KnowledgePointSource(
          knowledgePointId: 'basic',
          sourceChunkId: 'chunk-basic',
        ),
      ],
      'advanced': [
        KnowledgePointSource(
          knowledgePointId: 'advanced',
          sourceChunkId: 'chunk-advanced',
        ),
      ],
    },
    relations: const [],
  );
  final chunkRepository = _FakeSourceChunkRepository({
    'chunk-basic': _chunk('chunk-basic'),
    'chunk-advanced': _chunk('chunk-advanced'),
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        knowledgePointRepositoryProvider.overrideWithValue(repository),
        sourceChunkRepositoryProvider.overrideWithValue(chunkRepository),
        knowledgePointQuestionsProvider.overrideWith(
          (ref, knowledgePointId) async => const [],
        ),
        openaiServiceProvider.overrideWithValue(openai),
        conceptPrerequisiteTaskProvider.overrideWithValue(task),
      ],
      child: const MaterialApp(home: ConceptLearningPathScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

SourceChunk _chunk(String id) {
  return SourceChunk(
    id: id,
    sourceId: 'source',
    chunkIndex: 0,
    content: 'Evidence for $id.',
    locator: 'snapshot:L1-L1',
    contentHash: 'hash-$id',
    createdAt: DateTime(2026, 7, 15),
  );
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  final List<KnowledgePoint> points;
  final Map<String, List<KnowledgePointSource>> sourcesByPointId;
  final List<KnowledgePointPrerequisite> relations;
  List<KnowledgePointPrerequisite> savedRelations = const [];

  _FakeKnowledgePointRepository({
    required this.points,
    required this.sourcesByPointId,
    required this.relations,
  }) : super(DatabaseHelper());

  @override
  Future<List<KnowledgePoint>> getAllKnowledgePoints() async => points;

  @override
  Future<List<KnowledgePointSource>> getKnowledgePointSources(
    String knowledgePointId,
  ) async {
    return sourcesByPointId[knowledgePointId] ?? const [];
  }

  @override
  Future<List<KnowledgePointPrerequisite>>
      getKnowledgePointPrerequisites() async {
    return relations;
  }

  @override
  Future<void> replaceKnowledgePointPrerequisites({
    required List<String> scopeKnowledgePointIds,
    required List<KnowledgePointPrerequisite> relations,
  }) async {
    savedRelations = relations;
  }
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final Map<String, SourceChunk> chunks;

  _FakeSourceChunkRepository(this.chunks) : super(DatabaseHelper());

  @override
  Future<SourceChunk?> getSourceChunk(String id) async => chunks[id];
}

class _ControlledOpenAIService extends OpenAIService {
  final Completer<bool>? pendingKey;
  final bool immediateKey;
  int hasApiKeyCalls = 0;

  _ControlledOpenAIService._({this.pendingKey, this.immediateKey = false});

  factory _ControlledOpenAIService.pendingKey() =>
      _ControlledOpenAIService._(pendingKey: Completer<bool>());

  factory _ControlledOpenAIService.immediateKey() =>
      _ControlledOpenAIService._(immediateKey: true);

  @override
  Future<bool> hasApiKey({String? providerId}) {
    hasApiKeyCalls++;
    final pending = pendingKey;
    if (pending != null) return pending.future;
    return Future.value(immediateKey);
  }
}

class _ControlledConceptPrerequisiteTask extends ConceptPrerequisiteTask {
  final Completer<AiTaskResult<ConceptPrerequisiteResult>>? pendingResult;
  final String? failureMessage;
  int runCalls = 0;

  _ControlledConceptPrerequisiteTask._({
    this.pendingResult,
    this.failureMessage,
  }) : super(_ControlledOpenAIService.immediateKey());

  factory _ControlledConceptPrerequisiteTask.pending() =>
      _ControlledConceptPrerequisiteTask._(
        pendingResult: Completer<AiTaskResult<ConceptPrerequisiteResult>>(),
      );

  factory _ControlledConceptPrerequisiteTask.failure(String message) =>
      _ControlledConceptPrerequisiteTask._(failureMessage: message);

  @override
  Future<AiTaskResult<ConceptPrerequisiteResult>> run({
    required List<KnowledgePoint> knowledgePoints,
    required Map<String, List<SourceChunk>> sourceChunksByKnowledgePointId,
  }) {
    runCalls++;
    final pending = pendingResult;
    if (pending != null) return pending.future;
    return Future.value(
      AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: failureMessage!,
      ),
    );
  }
}
