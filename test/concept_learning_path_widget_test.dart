import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_prerequisite.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/source_chunk_repository.dart';
import 'package:dlg_q/features/knowledge_base/concept_learning_path_screen.dart';

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
