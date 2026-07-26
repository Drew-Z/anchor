import '../../data/models/knowledge_point.dart';
import '../../data/models/source_chunk.dart';

class ProjectCodeWalkthroughStep {
  final int sequence;
  final KnowledgePoint knowledgePoint;
  final List<SourceChunk> evidenceChunks;

  const ProjectCodeWalkthroughStep({
    required this.sequence,
    required this.knowledgePoint,
    required this.evidenceChunks,
  });

  String get locatorLabel {
    final locators = evidenceChunks
        .map((chunk) => chunk.locator)
        .whereType<String>()
        .where((locator) => locator.isNotEmpty)
        .toList();
    return locators.isEmpty ? '暂无文件行号' : locators.join(' · ');
  }
}

class ProjectCodeWalkthroughService {
  const ProjectCodeWalkthroughService();

  List<ProjectCodeWalkthroughStep> build({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    required Map<String, List<String>> sourceChunkIdsByKnowledgePointId,
  }) {
    final chunksById = {for (final chunk in sourceChunks) chunk.id: chunk};
    final orderedPoints = knowledgePoints
        .where((point) => point.kind.isProjectUnderstanding)
        .toList()
      ..sort(_comparePoints);

    return orderedPoints.asMap().entries.map((entry) {
      final point = entry.value;
      final evidenceChunks =
          (sourceChunkIdsByKnowledgePointId[point.id] ?? const <String>[])
              .map((id) => chunksById[id])
              .whereType<SourceChunk>()
              .toList();
      return ProjectCodeWalkthroughStep(
        sequence: entry.key + 1,
        knowledgePoint: point,
        evidenceChunks: evidenceChunks,
      );
    }).toList();
  }

  int _comparePoints(KnowledgePoint left, KnowledgePoint right) {
    final kindOrder = _kindRank(left.kind).compareTo(_kindRank(right.kind));
    if (kindOrder != 0) return kindOrder;
    final relevanceOrder =
        right.interviewRelevance.compareTo(left.interviewRelevance);
    if (relevanceOrder != 0) return relevanceOrder;
    return left.title.compareTo(right.title);
  }

  int _kindRank(KnowledgePointKind kind) {
    return switch (kind) {
      KnowledgePointKind.architecture => 0,
      KnowledgePointKind.dataFlow => 1,
      KnowledgePointKind.implementation => 2,
      KnowledgePointKind.boundary => 3,
      KnowledgePointKind.tradeOff => 4,
      KnowledgePointKind.concept => 5,
    };
  }
}
