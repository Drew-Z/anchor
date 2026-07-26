import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_prerequisite.dart';
import 'package:dlg_q/services/scheduling/concept_learning_path_service.dart';

void main() {
  const service = ConceptLearningPathService();

  test('rejects a cycle, self loop, and unsupported relation', () {
    final points = [
      _point('a', 'A'),
      _point('b', 'B'),
      _point('c', 'C'),
      _point('d', 'D'),
    ];
    final result = service.sanitize(
      drafts: [
        _draft(target: 'b', prerequisite: 'a', citation: 'chunk-a'),
        _draft(target: 'c', prerequisite: 'b', citation: 'chunk-b'),
        _draft(target: 'a', prerequisite: 'c', citation: 'chunk-c'),
        _draft(target: 'a', prerequisite: 'a', citation: 'chunk-a'),
        _draft(target: 'c', prerequisite: 'a', citation: 'chunk-d'),
      ],
      knowledgePoints: points,
      sourceBackedKnowledgePointIds: {'a', 'b', 'c', 'd'},
      citationIdsByKnowledgePointId: {
        'a': {'chunk-a'},
        'b': {'chunk-b'},
        'c': {'chunk-c'},
        'd': {'chunk-d'},
      },
    );

    expect(result.accepted.map((relation) => relation.key), ['a->b', 'b->c']);
    expect(result.rejected.map((item) => item.reason), contains('该关系会形成环路'));
    expect(result.rejected.map((item) => item.reason), contains('先修关系不能指向自身'));
    expect(
      result.rejected.map((item) => item.reason),
      contains('先修关系必须有理由和有效引用'),
    );
  });

  test('builds a stable topological path and readiness signal', () {
    final points = [
      _point('c', 'C', difficulty: 1),
      _point('b', 'B', mastery: 80, difficulty: 5),
      _point('a', 'A', mastery: 90, difficulty: 3),
    ];
    final path = service.buildPath(
      knowledgePoints: points,
      relations: [
        _draft(target: 'b', prerequisite: 'a', citation: 'chunk-a'),
        _draft(target: 'c', prerequisite: 'b', citation: 'chunk-b'),
      ],
    );

    expect(path.hasCycle, isFalse);
    expect(
      path.steps.map((step) => step.knowledgePoint.id),
      ['a', 'b', 'c'],
    );
    expect(path.steps[1].prerequisiteKnowledgePointIds, ['a']);
    expect(path.steps[1].prerequisitesMastered, isTrue);
    expect(path.steps[2].prerequisitesMastered, isTrue);
  });
}

KnowledgePoint _point(
  String id,
  String title, {
  int mastery = 0,
  int difficulty = 1,
}) {
  return KnowledgePoint(
    id: id,
    title: title,
    summary: '$title summary',
    masteryLevel: mastery,
    difficulty: difficulty,
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  );
}

KnowledgePointPrerequisiteDraft _draft({
  required String target,
  required String prerequisite,
  required String citation,
}) {
  return KnowledgePointPrerequisiteDraft(
    knowledgePointId: target,
    prerequisiteKnowledgePointId: prerequisite,
    rationale: '$prerequisite is needed before $target.',
    citationIds: [citation],
  );
}
