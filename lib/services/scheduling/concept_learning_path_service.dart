import '../../data/models/knowledge_point.dart';
import '../../data/models/knowledge_point_prerequisite.dart';

class RejectedConceptPrerequisite {
  final KnowledgePointPrerequisiteDraft draft;
  final String reason;

  const RejectedConceptPrerequisite({
    required this.draft,
    required this.reason,
  });
}

class ConceptPrerequisiteSanitizationResult {
  final List<KnowledgePointPrerequisiteDraft> accepted;
  final List<RejectedConceptPrerequisite> rejected;

  const ConceptPrerequisiteSanitizationResult({
    required this.accepted,
    required this.rejected,
  });
}

class ConceptLearningPathStep {
  final int order;
  final KnowledgePoint knowledgePoint;
  final List<String> prerequisiteKnowledgePointIds;
  final bool prerequisitesMastered;

  const ConceptLearningPathStep({
    required this.order,
    required this.knowledgePoint,
    required this.prerequisiteKnowledgePointIds,
    required this.prerequisitesMastered,
  });
}

class ConceptLearningPath {
  final List<ConceptLearningPathStep> steps;
  final bool hasCycle;

  const ConceptLearningPath({
    required this.steps,
    required this.hasCycle,
  });
}

class ConceptLearningPathService {
  const ConceptLearningPathService();

  ConceptPrerequisiteSanitizationResult sanitize({
    required List<KnowledgePointPrerequisiteDraft> drafts,
    required List<KnowledgePoint> knowledgePoints,
    required Set<String> sourceBackedKnowledgePointIds,
    required Map<String, Set<String>> citationIdsByKnowledgePointId,
  }) {
    final conceptsById = {
      for (final point in knowledgePoints)
        if (point.kind == KnowledgePointKind.concept) point.id: point,
    };
    final sortedDrafts = [...drafts]..sort((a, b) => a.key.compareTo(b.key));
    final accepted = <KnowledgePointPrerequisiteDraft>[];
    final rejected = <RejectedConceptPrerequisite>[];
    final seen = <String>{};
    final dependentsByPrerequisite = <String, Set<String>>{};

    for (final draft in sortedDrafts) {
      final knowledgePointId = draft.knowledgePointId.trim();
      final prerequisiteId = draft.prerequisiteKnowledgePointId.trim();
      final endpointCitationIds = {
        ...?citationIdsByKnowledgePointId[knowledgePointId],
        ...?citationIdsByKnowledgePointId[prerequisiteId],
      };
      final citationIds = draft.citationIds
          .where(endpointCitationIds.contains)
          .toSet()
          .toList()
        ..sort();
      final normalized = KnowledgePointPrerequisiteDraft(
        knowledgePointId: knowledgePointId,
        prerequisiteKnowledgePointId: prerequisiteId,
        rationale: draft.rationale.trim(),
        citationIds: citationIds,
      );

      String? reason;
      if (!conceptsById.containsKey(knowledgePointId) ||
          !conceptsById.containsKey(prerequisiteId)) {
        reason = '关系引用了不存在或非 concept 的知识点';
      } else if (!sourceBackedKnowledgePointIds.contains(knowledgePointId) ||
          !sourceBackedKnowledgePointIds.contains(prerequisiteId)) {
        reason = '先修关系两端都必须有来源依据';
      } else if (knowledgePointId == prerequisiteId) {
        reason = '先修关系不能指向自身';
      } else if (normalized.rationale.isEmpty || citationIds.isEmpty) {
        reason = '先修关系必须有理由和有效引用';
      } else if (seen.contains(normalized.key)) {
        reason = '重复先修关系';
      } else if (_isReachable(
        start: knowledgePointId,
        target: prerequisiteId,
        dependentsByPrerequisite: dependentsByPrerequisite,
      )) {
        reason = '该关系会形成环路';
      }

      if (reason != null) {
        rejected.add(RejectedConceptPrerequisite(draft: draft, reason: reason));
        continue;
      }

      seen.add(normalized.key);
      dependentsByPrerequisite
          .putIfAbsent(prerequisiteId, () => <String>{})
          .add(knowledgePointId);
      accepted.add(normalized);
    }

    return ConceptPrerequisiteSanitizationResult(
      accepted: accepted,
      rejected: rejected,
    );
  }

  ConceptLearningPath buildPath({
    required List<KnowledgePoint> knowledgePoints,
    required List<KnowledgePointPrerequisiteDraft> relations,
  }) {
    final pointsById = {
      for (final point in knowledgePoints)
        if (point.kind == KnowledgePointKind.concept) point.id: point,
    };
    final indegree = {for (final id in pointsById.keys) id: 0};
    final dependents = <String, Set<String>>{};
    final prerequisites = <String, Set<String>>{};

    for (final relation in relations) {
      final target = relation.knowledgePointId;
      final prerequisite = relation.prerequisiteKnowledgePointId;
      if (!pointsById.containsKey(target) ||
          !pointsById.containsKey(prerequisite) ||
          target == prerequisite) {
        continue;
      }
      final added =
          dependents.putIfAbsent(prerequisite, () => <String>{}).add(target);
      if (!added) continue;
      prerequisites.putIfAbsent(target, () => <String>{}).add(prerequisite);
      indegree[target] = (indegree[target] ?? 0) + 1;
    }

    final ready = indegree.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList();
    _sortPointIds(ready, pointsById);
    final orderedIds = <String>[];

    while (ready.isNotEmpty) {
      final id = ready.removeAt(0);
      orderedIds.add(id);
      final nextIds = (dependents[id] ?? const <String>{}).toList();
      _sortPointIds(nextIds, pointsById);
      for (final nextId in nextIds) {
        indegree[nextId] = (indegree[nextId] ?? 0) - 1;
        if (indegree[nextId] == 0) {
          ready.add(nextId);
          _sortPointIds(ready, pointsById);
        }
      }
    }

    final hasCycle = orderedIds.length != pointsById.length;
    if (hasCycle) {
      final remaining =
          pointsById.keys.where((id) => !orderedIds.contains(id)).toList();
      _sortPointIds(remaining, pointsById);
      orderedIds.addAll(remaining);
    }

    return ConceptLearningPath(
      hasCycle: hasCycle,
      steps: orderedIds.asMap().entries.map((entry) {
        final point = pointsById[entry.value]!;
        final prerequisiteIds =
            (prerequisites[point.id] ?? const <String>{}).toList();
        _sortPointIds(prerequisiteIds, pointsById);
        return ConceptLearningPathStep(
          order: entry.key + 1,
          knowledgePoint: point,
          prerequisiteKnowledgePointIds: prerequisiteIds,
          prerequisitesMastered: prerequisiteIds.every(
            (id) => (pointsById[id]?.masteryLevel ?? 0) >= 80,
          ),
        );
      }).toList(),
    );
  }

  bool _isReachable({
    required String start,
    required String target,
    required Map<String, Set<String>> dependentsByPrerequisite,
  }) {
    final pending = <String>[start];
    final visited = <String>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current)) continue;
      if (current == target) return true;
      pending.addAll(dependentsByPrerequisite[current] ?? const <String>{});
    }
    return false;
  }

  void _sortPointIds(
    List<String> ids,
    Map<String, KnowledgePoint> pointsById,
  ) {
    ids.sort((leftId, rightId) {
      final left = pointsById[leftId]!;
      final right = pointsById[rightId]!;
      final difficulty = left.difficulty.compareTo(right.difficulty);
      if (difficulty != 0) return difficulty;
      final title = left.title.compareTo(right.title);
      if (title != 0) return title;
      return left.id.compareTo(right.id);
    });
  }
}
