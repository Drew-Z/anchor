import '../../data/models/grounded_learning_context.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';

class GroundedLearningContextCandidate {
  final SourceChunk chunk;
  final List<GroundedLearningContextReason> reasons;

  const GroundedLearningContextCandidate({
    required this.chunk,
    required this.reasons,
  });
}

class GroundedLearningContextService {
  const GroundedLearningContextService();

  GroundedLearningContext select({
    required String targetId,
    KnowledgePoint? knowledgePoint,
    required GroundedLearningSurface surface,
    required List<GroundedLearningContextCandidate> candidates,
    required List<Source> sources,
    Set<String> requiredCitationIds = const {},
    int limit = 12,
  }) {
    final normalizedTargetId = targetId.trim();
    final normalizedRequiredCitationIds = requiredCitationIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final sourcesById = {for (final source in sources) source.id: source};
    final items = <GroundedLearningContextItem>[];
    final rejections = <GroundedLearningContextRejection>[];
    final seenChunkIds = <String>{};

    if (normalizedTargetId.isEmpty) {
      rejections.add(
        const GroundedLearningContextRejection(
          code: GroundedLearningContextRejectionCode.missingTarget,
          detail: 'surface 必须绑定一个可追踪目标。',
        ),
      );
    }

    for (final candidate in candidates) {
      final chunk = candidate.chunk;
      if (normalizedRequiredCitationIds.isNotEmpty &&
          !normalizedRequiredCitationIds.contains(chunk.id)) {
        continue;
      }
      if (!seenChunkIds.add(chunk.id)) continue;
      if (items.length >= limit) {
        rejections.add(
          GroundedLearningContextRejection(
            code: GroundedLearningContextRejectionCode.contextLimit,
            sourceChunkId: chunk.id,
            detail: '超过 $limit 个片段的确定性上限。',
          ),
        );
        continue;
      }
      if (chunk.content.trim().isEmpty) {
        rejections.add(
          GroundedLearningContextRejection(
            code: GroundedLearningContextRejectionCode.emptyChunk,
            sourceChunkId: chunk.id,
            detail: '片段正文为空。',
          ),
        );
        continue;
      }
      final reasons = candidate.reasons.toSet().toList(growable: false);
      if (reasons.isEmpty) {
        rejections.add(
          GroundedLearningContextRejection(
            code: GroundedLearningContextRejectionCode.missingSelectionReason,
            sourceChunkId: chunk.id,
            detail: '合法 context item 必须说明确定性的选择理由。',
          ),
        );
        continue;
      }
      final source = sourcesById[chunk.sourceId];
      if (source == null) {
        rejections.add(
          GroundedLearningContextRejection(
            code: GroundedLearningContextRejectionCode.missingSource,
            sourceChunkId: chunk.id,
            detail: 'source_id=${chunk.sourceId} 的来源记录不可读取。',
          ),
        );
        continue;
      }
      items.add(
        GroundedLearningContextItem(
          chunk: chunk,
          source: source,
          selectionReasons: reasons,
          quoteBoundary: GroundedLearningQuoteBoundary(
            sourceChunkId: chunk.id,
            startOffset: 0,
            endOffset: chunk.content.length,
            exactText: chunk.content,
          ),
        ),
      );
    }

    final selectedIds = items.map((item) => item.chunk.id).toSet();
    for (final requiredId in normalizedRequiredCitationIds) {
      if (selectedIds.contains(requiredId)) continue;
      rejections.add(
        GroundedLearningContextRejection(
          code: GroundedLearningContextRejectionCode.missingRequiredCitation,
          sourceChunkId: requiredId,
          detail: '指定引用不在合法 context 中。',
        ),
      );
    }

    return GroundedLearningContext(
      targetId: normalizedTargetId,
      knowledgePoint: knowledgePoint,
      surface: surface,
      items: List.unmodifiable(items),
      rejections: List.unmodifiable(rejections),
    );
  }

  GroundedLearningContext selectCitationSubset({
    required GroundedLearningContext parent,
    required String targetId,
    required GroundedLearningSurface surface,
    required Iterable<String> citationIds,
    required GroundedLearningContextReason reason,
  }) {
    final requiredIds =
        citationIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    return select(
      targetId: targetId,
      knowledgePoint: parent.knowledgePoint,
      surface: surface,
      candidates: parent.items
          .map(
            (item) => GroundedLearningContextCandidate(
              chunk: item.chunk,
              reasons: [reason, ...item.selectionReasons],
            ),
          )
          .toList(growable: false),
      sources: parent.sources,
      requiredCitationIds: requiredIds,
      limit: parent.items.length,
    );
  }
}
